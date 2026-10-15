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

local FORM_COLORS = {
	Color3.fromRGB(135, 220, 180), Color3.fromRGB(235, 125, 75),
	Color3.fromRGB(180, 135, 255), Color3.fromRGB(90, 205, 130),
	Color3.fromRGB(80, 190, 235), Color3.fromRGB(165, 170, 185),
	Color3.fromRGB(245, 215, 155), Color3.fromRGB(235, 105, 165),
}

local function createCreature(model, form, x, z, bodyColor)
	local function ball(name, px, py, pz, sx, sy, sz, color, material)
		local part = Kit.ball(model, name, px, py, pz, 1, color, material or Enum.Material.SmoothPlastic)
		part.Size = Vector3.new(sx, sy, sz)
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		return part
	end
	local function block(name, px, py, pz, sx, sy, sz, color, yaw)
		local part = Kit.newPart(model, name, Vector3.new(sx, sy, sz), CFrame.new(px, py, pz) * CFrame.Angles(0, yaw or 0, 0), color, Enum.Material.SmoothPlastic)
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		return part
	end
	local function eye(px, py, pz, scale)
		ball("Eye White", px, py, pz, scale, scale, scale * 0.45, Color3.fromRGB(250, 250, 245))
		ball("Pupil", px, py, pz - scale * 0.18, scale * 0.42, scale * 0.42, scale * 0.25, Color3.fromRGB(32, 35, 48))
	end

	local body
	if form == 1 then -- Mochi slug: soft body, shell and curious feelers
		body = ball("Slug Body", x, 3.05, z, 2.3, 1.45, 1.8, bodyColor)
		ball("Shell", x + 0.52, 3.45, z + 0.4, 1.0, 1.0, 1.0, bodyColor:Lerp(Color3.new(1, 1, 1), 0.35))
		for _, side in ipairs({ -1, 1 }) do
			block("Feelers", x + side * 0.48, 4.35, z - 0.25, 0.18, 0.9, 0.18, bodyColor, side * -0.12)
			ball("Feelers", x + side * 0.48, 4.85, z - 0.25, 0.35, 0.35, 0.35, bodyColor)
			eye(x + side * 0.34, 3.75, z - 0.72, 0.38)
		end
	elseif form == 2 then -- Cinder pup: four feet, floppy ears and a curled tail
		body = ball("Pup Body", x, 3.15, z + 0.15, 1.65, 1.35, 2.1, bodyColor)
		ball("Pup Head", x, 4.15, z - 0.55, 1.45, 1.35, 1.25, bodyColor)
		for _, side in ipairs({ -1, 1 }) do
			block("Pup Ear", x + side * 0.46, 4.95, z - 0.52, 0.42, 0.9, 0.42, bodyColor, side * 0.2)
			block("Pup Foot", x + side * 0.55, 2.55, z - 0.5, 0.46, 0.55, 0.48, bodyColor)
			block("Pup Foot", x + side * 0.55, 2.55, z + 0.65, 0.46, 0.55, 0.48, bodyColor)
			eye(x + side * 0.32, 4.28, z - 1.1, 0.34)
		end
		ball("Pup Nose", x, 3.95, z - 1.18, 0.3, 0.24, 0.22, Color3.fromRGB(45, 42, 55))
		ball("Curled Tail", x + 0.96, 3.7, z + 0.85, 0.7, 0.7, 0.7, bodyColor)
	elseif form == 3 then -- Prism moth: broad wings, fuzzy body, antennae
		body = ball("Moth Body", x, 3.4, z, 0.85, 1.8, 0.9, bodyColor)
		ball("Left Wing", x - 0.92, 3.65, z, 1.25, 1.7, 0.42, bodyColor:Lerp(Color3.new(1, 1, 1), 0.28))
		ball("Right Wing", x + 0.92, 3.65, z, 1.25, 1.7, 0.42, bodyColor:Lerp(Color3.new(1, 1, 1), 0.28))
		ball("Moth Head", x, 4.55, z - 0.05, 1.0, 0.9, 0.9, bodyColor)
		for _, side in ipairs({ -1, 1 }) do
			block("Antenna", x + side * 0.23, 5.15, z, 0.12, 0.7, 0.12, bodyColor, side * 0.35)
			eye(x + side * 0.2, 4.6, z - 0.46, 0.27)
		end
	elseif form == 4 then -- Mossback toad: squat body, eye stalks and spots
		body = ball("Toad Body", x, 3.05, z + 0.1, 2.25, 1.3, 1.9, bodyColor)
		ball("Toad Face", x, 3.65, z - 0.52, 1.55, 1.05, 1.25, bodyColor)
		for _, side in ipairs({ -1, 1 }) do
			block("Eye Stalk", x + side * 0.48, 4.3, z - 0.45, 0.2, 0.75, 0.2, bodyColor)
			ball("Eye", x + side * 0.48, 4.7, z - 0.53, 0.62, 0.62, 0.62, bodyColor:Lerp(Color3.new(1, 1, 1), 0.2))
			eye(x + side * 0.48, 4.72, z - 0.81, 0.3)
			ball("Back Spot", x + side * 0.55, 3.35, z + 0.45, 0.42, 0.42, 0.32, bodyColor:Lerp(Color3.new(0, 0, 0), 0.18))
			ball("Toad Foot", x + side * 0.72, 2.55, z - 0.55, 0.7, 0.45, 0.65, bodyColor)
			ball("Toad Foot", x + side * 0.72, 2.55, z + 0.65, 0.7, 0.45, 0.65, bodyColor)
		end
	elseif form == 5 then -- Orbit jelly: floating bell and dangling tentacles
		body = ball("Jelly Bell", x, 4.05, z, 2.0, 1.8, 1.8, bodyColor)
		ball("Jelly Base", x, 3.4, z, 1.65, 0.75, 1.65, bodyColor:Lerp(Color3.new(1, 1, 1), 0.25))
		for _, side in ipairs({ -1, 1 }) do
			for _, front in ipairs({ -1, 1 }) do
				local tentacle = Kit.newPart(model, "Jelly Tentacle", Vector3.new(0.28, 1.35, 0.28), CFrame.new(x + side * 0.48, 2.75, z + front * 0.48), bodyColor, Enum.Material.SmoothPlastic)
				tentacle.Shape = Enum.PartType.Cylinder
				tentacle.CanCollide, tentacle.CanTouch, tentacle.CanQuery = false, false, false
			end
		end
		eye(x - 0.35, 4.05, z - 0.82, 0.35)
		eye(x + 0.35, 4.05, z - 0.82, 0.35)
	elseif form == 6 then -- Pebble golem: stacked stones and chunky arms
		body = block("Golem Body", x, 3.3, z, 1.7, 1.7, 1.5, bodyColor)
		ball("Golem Head", x, 4.55, z - 0.05, 1.35, 1.25, 1.25, bodyColor:Lerp(Color3.new(1, 1, 1), 0.16))
		for _, side in ipairs({ -1, 1 }) do
			block("Golem Arm", x + side * 1.12, 3.35, z, 0.58, 1.2, 0.7, bodyColor, side * 0.2)
			block("Golem Foot", x + side * 0.48, 2.55, z + 0.1, 0.7, 0.55, 0.75, bodyColor)
			eye(x + side * 0.28, 4.62, z - 0.62, 0.31)
		end
	elseif form == 7 then -- Cloud alpaca: long neck and soft woolly body
		body = ball("Alpaca Body", x, 3.15, z + 0.2, 1.8, 1.55, 2.0, bodyColor)
		block("Alpaca Neck", x, 4.0, z - 0.55, 0.88, 1.45, 0.82, bodyColor)
		ball("Alpaca Head", x, 4.95, z - 0.58, 1.1, 1.15, 1.05, bodyColor)
		for _, side in ipairs({ -1, 1 }) do
			block("Alpaca Ear", x + side * 0.42, 5.65, z - 0.56, 0.24, 0.72, 0.25, bodyColor, side * 0.14)
			block("Alpaca Leg", x + side * 0.55, 2.55, z - 0.42, 0.35, 0.7, 0.35, bodyColor)
			block("Alpaca Leg", x + side * 0.55, 2.55, z + 0.66, 0.35, 0.7, 0.35, bodyColor)
		end
		eye(x - 0.2, 5.0, z - 1.03, 0.25)
		eye(x + 0.2, 5.0, z - 1.03, 0.25)
	else -- Soda mimic: little chest creature with a straw
		body = block("Mimic Body", x, 3.35, z, 1.9, 1.75, 1.7, bodyColor)
		block("Mimic Lid", x, 4.35, z, 2.05, 0.35, 1.82, bodyColor:Lerp(Color3.new(1, 1, 1), 0.22))
		block("Mimic Straw", x + 0.42, 5.0, z + 0.05, 0.18, 1.0, 0.18, Color3.fromRGB(255, 245, 220), 0.1)
		eye(x - 0.42, 3.9, z - 0.88, 0.38)
		eye(x + 0.42, 3.9, z - 0.88, 0.38)
		for _, side in ipairs({ -1, 1 }) do
			block("Mimic Foot", x + side * 0.56, 2.55, z + 0.25, 0.45, 0.5, 0.55, bodyColor)
		end
	end
	return body
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
		Legendary = Color3.fromRGB(255, 190, 55), Mythic = Color3.fromRGB(255, 90, 145),
	}
	for index, character in ipairs(profile.roster) do
		if index > ctx.Config.MaxRosterSize then break end
		local column = (index - 1) % 4
		local row = math.floor((index - 1) / 4)
		local x = area.MinX + 4 + column * 8
		local standOffset = profile.plot <= 2 and (29 - row * 5) or (3 + row * 5)
		local z = area.MinZ + standOffset
		local model = Instance.new("Model")
		model.Name = "CreatureStand_" .. index
		local rarityTint = colors[character.Rarity] or colors.Common
		local form = math.clamp(math.floor(tonumber(character.Form) or ((index - 1) % 8 + 1)), 1, 8)
		local tint = FORM_COLORS[form]
		Kit.disc(model, "Stand Base", x, z, 3.8, 0.7, Color3.fromRGB(65, 73, 92), Enum.Material.Metal, 0.3)
		Kit.box(model, "Stand Column", x - 0.5, x + 0.5, 0.7, 2.3, z - 0.5, z + 0.5, rarityTint, Enum.Material.SmoothPlastic)
		local body = createCreature(model, form, x, z, tint)
		local rarityLevel = ({ Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 })[character.Rarity] or 1
		if rarityLevel >= 4 then
			local crown = Kit.ball(model, "Rarity Spark", x, 6.35, z, 0.55, rarityTint, Enum.Material.Neon)
			crown.CanCollide, crown.CanTouch, crown.CanQuery = false, false, false
			Kit.glow(crown, rarityTint, 7, rarityLevel >= 6 and 1.8 or 0.8)
		end
		Kit.label(body, character.Name, string.format("%s • %s • +%d/tick", character.Rarity or "Common", character.Assigned and "Working" or "Reserve", character.Income or 4), 2.6, rarityTint)
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
