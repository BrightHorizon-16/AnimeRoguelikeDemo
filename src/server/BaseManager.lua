-- BaseManager: the base builder. Owns plot claiming, building placement, upgrades,
-- demolition, bonus calculation, and (de)serialization for saving.
--
-- Everything the client asks for is validated here; the client only previews placement.
-- Main.server.lua injects the pieces it shares (see BaseManager.init).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local BuildingModels = require(script.Parent:WaitForChild("BuildingModels"))
local Kit = require(script.Parent:WaitForChild("PartKit"))

local GROUND_Y = 0.3 -- top of a plot pad

local BaseManager = {}

local ctx -- { world, Config, profiles, notify, getStat, refresh, onChanged }
local plots = {} -- [index] = { Owner = Player?, Folder = Folder, Sign = Part? }

local BASE_ACTIONS = { Build = true, Upgrade = true, Demolish = true }

-- ---------------------------------------------------------------------------
-- Plots
-- ---------------------------------------------------------------------------

local function setSign(index, owner)
	local plot = plots[index]
	local gui = plot and plot.Sign and plot.Sign:FindFirstChild("Label")
	local subtitle = gui and gui:FindFirstChild("Subtitle")
	if subtitle then subtitle.Text = owner and owner.DisplayName or "Open - unclaimed" end
end

function BaseManager.init(context)
	ctx = context
	local buildingsRoot = ctx.world:WaitForChild("PlayerBuildings")
	local decorRoot = ctx.world:WaitForChild("PlotDecor")
	for index = 1, #Buildings.Plots do
		local decor = decorRoot:FindFirstChild("Plot" .. index)
		plots[index] = {
			Owner = nil,
			Folder = buildingsRoot:FindFirstChild("Plot" .. index),
			Sign = decor and decor:FindFirstChild("Plot Sign"),
		}
		setSign(index, nil)
	end
end

function BaseManager.assignPlot(player, profile)
	for index, plot in ipairs(plots) do
		if not plot.Owner then
			plot.Owner = player
			profile.plot = index
			setSign(index, player)
			return index
		end
	end
	ctx.notify(player, "The base is full. This server has reached its four-player plot limit.")
	return nil
end

function BaseManager.releasePlot(player, profile)
	local index = profile and profile.plot
	local plot = index and plots[index]
	if not plot or plot.Owner ~= player then return end
	plot.Folder:ClearAllChildren()
	plot.Owner = nil
	setSign(index, nil)
	profile.plot = nil
end

function BaseManager.refreshRosterDisplays(player, profile)
	if not profile or not profile.plot then return end
	local plot = plots[profile.plot]
	local root = plot and plot.Folder
	if not root then return end
	local stands = root:FindFirstChild("CharacterStands")
	if stands then stands:Destroy() end
	stands = Instance.new("Folder")
	stands.Name = "CharacterStands"
	stands.Parent = root
	local area = Buildings.Plots[profile.plot]
	local colors = {
		Common = Color3.fromRGB(190, 200, 210), Uncommon = Color3.fromRGB(80, 220, 130),
		Rare = Color3.fromRGB(70, 160, 255), Epic = Color3.fromRGB(190, 90, 255),
	}
	for index, character in ipairs(profile.roster) do
		if index > ctx.Config.MaxRosterSize then break end
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local x = area.MinX + 4 + column * 8
		local standOffset = profile.plot <= 2 and (29 - row * 5) or (3 + row * 5)
		local z = area.MinZ + standOffset
		local model = Instance.new("Model")
		model.Name = "BeingStand_" .. index
		local tint = colors[character.Rarity] or colors.Common
		Kit.disc(model, "Stand Base", x, z, 3.8, 0.7, Color3.fromRGB(65, 73, 92), Enum.Material.Metal, 0.3)
		Kit.box(model, "Stand Column", x - 0.5, x + 0.5, 0.7, 2.3, z - 0.5, z + 0.5, tint, Enum.Material.SmoothPlastic)
		local body = Kit.ball(model, "Being Body", x, 3.1, z, 2.0, tint, Enum.Material.SmoothPlastic)
		Kit.ball(model, "Being Head", x, 4.8, z, 1.45, tint:Lerp(Color3.new(1, 1, 1), 0.2), Enum.Material.SmoothPlastic)
		Kit.label(body, character.Name, (character.Rarity or "Common") .. " • " .. (character.Assigned and "Working" or "Reserve"), 2.8, tint)
		model.Parent = stands
	end
end

-- ---------------------------------------------------------------------------
-- Buildings
-- ---------------------------------------------------------------------------

local function refreshEffects(profile)
	profile.effects = Buildings.effects(profile.buildings)
end

local function spawnModel(player, profile, entry)
	local plot = plots[profile.plot]
	local def = Buildings.Catalog[entry.Id]
	if entry.Model then entry.Model:Destroy() end
	local cx, cz = Buildings.cellCenter(profile.plot, entry.X, entry.Z, def.W, def.D)
	local yaw = entry.Id == "StarterHouse" and profile.plot >= 3 and math.pi or 0
	local model = BuildingModels.create(entry.Id, entry.Level, cx, cz, GROUND_Y, plot.Folder, player.DisplayName, yaw)
	if model then
		model:SetAttribute("BuildingId", entry.Id)
		model:SetAttribute("Level", entry.Level)
		model:SetAttribute("OwnerUserId", player.UserId)
	end
	entry.Model = model
end

local function pay(player, cost)
	local coins, shards = ctx.getStat(player, "Coins"), ctx.getStat(player, "Shards")
	local wood, stone = ctx.getStat(player, "Wood"), ctx.getStat(player, "Stone")
	if not coins or not shards or not wood or not stone then return false end
	if coins.Value < cost.Coins or shards.Value < cost.Shards or wood.Value < cost.Wood or stone.Value < cost.Stone then
		local need = {}
		if cost.Coins > 0 then table.insert(need, cost.Coins .. " coins") end
		if cost.Wood > 0 then table.insert(need, cost.Wood .. " wood") end
		if cost.Stone > 0 then table.insert(need, cost.Stone .. " stone") end
		if cost.Shards > 0 then table.insert(need, cost.Shards .. " essence") end
		ctx.notify(player, "Not enough resources - you need " .. table.concat(need, " and ") .. ".")
		return false
	end
	coins.Value -= cost.Coins
	wood.Value -= cost.Wood
	stone.Value -= cost.Stone
	shards.Value -= cost.Shards
	return true
end

local function build(player, profile, payload)
	if type(payload) ~= "table" then return end
	if not profile.plot then ctx.notify(player, "You don't have a plot to build on."); return end
	local ok, reason = Buildings.canPlace(profile.buildings, payload.Id, payload.X, payload.Z, profile.plot)
	if not ok then ctx.notify(player, reason); return end
	if not pay(player, Buildings.costFor(payload.Id, 1)) then return end
	local entry = { Id = payload.Id, X = payload.X, Z = payload.Z, Level = 1 }
	table.insert(profile.buildings, entry)
	spawnModel(player, profile, entry)
	refreshEffects(profile)
	ctx.notify(player, "Built " .. Buildings.Catalog[entry.Id].Name .. "!")
end

local function upgrade(player, profile, index)
	local entry = type(index) == "number" and profile.buildings[index]
	if not entry then return end
	if entry.Id == "StarterHouse" then ctx.notify(player, "The starter cabin cannot be upgraded yet."); return end
	local def = Buildings.Catalog[entry.Id]
	if entry.Level >= def.MaxLevel then ctx.notify(player, def.Name .. " is already at max level."); return end
	if not pay(player, Buildings.costFor(entry.Id, entry.Level + 1)) then return end
	entry.Level += 1
	spawnModel(player, profile, entry)
	refreshEffects(profile)
	ctx.notify(player, def.Name .. " upgraded to level " .. entry.Level .. ": " .. Buildings.describe(entry.Id, entry.Level))
end

local function demolish(player, profile, index)
	local entry = type(index) == "number" and profile.buildings[index]
	if not entry then return end
	if entry.Id == "StarterHouse" then ctx.notify(player, "The starter cabin cannot be sold or moved."); return end
	local def = Buildings.Catalog[entry.Id]
	local refund = Buildings.sellValue(entry.Id, entry.Level, ctx.Config.SellRefund)
	if entry.Model then entry.Model:Destroy() end
	table.remove(profile.buildings, index)
	local coins = ctx.getStat(player, "Coins")
	if coins then coins.Value += refund end
	refreshEffects(profile)
	ctx.notify(player, "Demolished " .. def.Name .. " (+" .. refund .. " coins).")
end

-- Returns true if `action` belongs to the base builder (so Main stops processing it).
function BaseManager.handleAction(player, action, payload)
	if not BASE_ACTIONS[action] then return false end
	local profile = ctx.profiles[player]
	if not profile then return true end

	if action == "Build" then
		build(player, profile, payload)
	elseif action == "Upgrade" then
		upgrade(player, profile, payload)
	elseif action == "Demolish" then
		demolish(player, profile, payload)
	end

	if ctx.onChanged then ctx.onChanged(player) end
	ctx.refresh(player)
	return true
end

-- ---------------------------------------------------------------------------
-- State, saving and loading
-- ---------------------------------------------------------------------------

function BaseManager.stateFor(player)
	local profile = ctx.profiles[player]
	if not profile then return nil end
	local owned = {}
	for index, entry in ipairs(profile.buildings) do
		local def = Buildings.Catalog[entry.Id]
		if entry.Id ~= "StarterHouse" then table.insert(owned, {
			Index = index,
			Id = entry.Id,
			Name = def.Name,
			X = entry.X,
			Z = entry.Z,
			Level = entry.Level,
			MaxLevel = def.MaxLevel,
			Description = Buildings.describe(entry.Id, entry.Level),
			NextCost = entry.Level < def.MaxLevel and Buildings.costFor(entry.Id, entry.Level + 1) or nil,
			SellValue = Buildings.sellValue(entry.Id, entry.Level, ctx.Config.SellRefund),
		}) end
	end
	return { Plot = profile.plot, Buildings = owned, Effects = profile.effects }
end

-- Plain data for the DataStore (no instances).
function BaseManager.serialize(profile)
	local list = {}
	for _, entry in ipairs(profile.buildings) do
		table.insert(list, { Id = entry.Id, X = entry.X, Z = entry.Z, Level = entry.Level })
	end
	return list
end

-- Rebuilds saved buildings for a player who already has a plot. Entries that no longer
-- validate (catalog changed, bad data) are skipped.
function BaseManager.restore(player, profile, saved)
	if not profile.plot then return end
	local plot = plots[profile.plot]
	plot.Folder:ClearAllChildren()
	profile.buildings = { { Id = "StarterHouse", X = 3, Z = 3, Level = 1 } }
	spawnModel(player, profile, profile.buildings[1])
	BaseManager.refreshRosterDisplays(player, profile)
	if type(saved) ~= "table" then refreshEffects(profile); return end
	for _, item in ipairs(saved) do
		if type(item) == "table" then
			local def = type(item.Id) == "string" and Buildings.Catalog[item.Id]
			local level = item.Level
			if def and Buildings.isInt(level) and level >= 1 and level <= def.MaxLevel
				and Buildings.canPlace(profile.buildings, item.Id, item.X, item.Z, profile.plot) then
				local entry = { Id = item.Id, X = item.X, Z = item.Z, Level = level }
				table.insert(profile.buildings, entry)
				spawnModel(player, profile, entry)
			end
		end
	end
	refreshEffects(profile)
end

return BaseManager
