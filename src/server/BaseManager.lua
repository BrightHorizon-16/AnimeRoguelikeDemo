-- BaseManager: the base builder. Owns plot claiming, building placement, upgrades,
-- demolition, bonus calculation, and (de)serialization for saving.
--
-- Everything the client asks for is validated here; the client only previews placement.
-- Main.server.lua injects the pieces it shares (see BaseManager.init).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local BuildingModels = require(script.Parent:WaitForChild("BuildingModels"))

local GROUND_Y = 0.3 -- top of a plot pad

local BaseManager = {}

local ctx -- { world, Config, profiles, notify, getStat, refresh, onChanged }
local plots = {} -- [index] = { Owner = Player?, Folder = Folder, Sign = Part? }

local BASE_ACTIONS = { Build = true, Upgrade = true, Demolish = true, GotoPlot = true, GotoBase = true }

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
	ctx.notify(player, "The Builder Grounds are full. You can keep playing, but you have no plot.")
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
	local model = BuildingModels.create(entry.Id, entry.Level, cx, cz, GROUND_Y, plot.Folder, player.DisplayName)
	if model then
		model:SetAttribute("BuildingId", entry.Id)
		model:SetAttribute("Level", entry.Level)
		model:SetAttribute("OwnerUserId", player.UserId)
	end
	entry.Model = model
end

local function pay(player, cost)
	local coins, shards = ctx.getStat(player, "Coins"), ctx.getStat(player, "Shards")
	if not coins or not shards then return false end
	if coins.Value < cost.Coins or shards.Value < cost.Shards then
		local need = {}
		if cost.Coins > 0 then table.insert(need, cost.Coins .. " coins") end
		if cost.Shards > 0 then table.insert(need, cost.Shards .. " shards") end
		ctx.notify(player, "Not enough resources - you need " .. table.concat(need, " and ") .. ".")
		return false
	end
	coins.Value -= cost.Coins
	shards.Value -= cost.Shards
	return true
end

local function build(player, profile, payload)
	if type(payload) ~= "table" then return end
	if not profile.plot then ctx.notify(player, "You don't have a plot to build on."); return end
	local ok, reason = Buildings.canPlace(profile.buildings, payload.Id, payload.X, payload.Z)
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
	local def = Buildings.Catalog[entry.Id]
	local refund = Buildings.sellValue(entry.Id, entry.Level, ctx.Config.SellRefund)
	if entry.Model then entry.Model:Destroy() end
	table.remove(profile.buildings, index)
	local coins = ctx.getStat(player, "Coins")
	if coins then coins.Value += refund end
	refreshEffects(profile)
	ctx.notify(player, "Demolished " .. def.Name .. " (+" .. refund .. " coins).")
end

local function teleport(player, x, z)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then root.CFrame = CFrame.new(x, 5, z) end
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
	elseif action == "GotoPlot" then
		if profile.plot then
			local plotDef = Buildings.Plots[profile.plot]
			local size = Buildings.PlotCells * Buildings.CellSize
			teleport(player, plotDef.MinX + size / 2, plotDef.MinZ + size + 6)
		else
			ctx.notify(player, "You don't have a plot.")
		end
	elseif action == "GotoBase" then
		teleport(player, 0, -12)
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
		table.insert(owned, {
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
		})
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
	if type(saved) ~= "table" or not profile.plot then return end
	for _, item in ipairs(saved) do
		if type(item) == "table" then
			local def = type(item.Id) == "string" and Buildings.Catalog[item.Id]
			local level = item.Level
			if def and Buildings.isInt(level) and level >= 1 and level <= def.MaxLevel
				and Buildings.canPlace(profile.buildings, item.Id, item.X, item.Z) then
				local entry = { Id = item.Id, X = item.X, Z = item.Z, Level = level }
				table.insert(profile.buildings, entry)
				spawnModel(player, profile, entry)
			end
		end
	end
	refreshEffects(profile)
end

return BaseManager
