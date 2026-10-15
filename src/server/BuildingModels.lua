-- BuildingModels: builds the 3D model for each building type at a given level.
-- Every model sits on a foundation slab inside its grid footprint (2x2 cells = 8x8 studs,
-- 1x1 cells = 4x4 studs). Higher levels add visible upgrades (extra floors, crystals, orbs...).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local Kit = require(script.Parent:WaitForChild("PartKit"))

local M = Enum.Material

local C = {
	stone = Color3.fromRGB(112, 120, 138),
	darkStone = Color3.fromRGB(58, 64, 82),
	wall = Color3.fromRGB(150, 150, 165),
	wood = Color3.fromRGB(121, 85, 58),
	darkWood = Color3.fromRGB(78, 56, 42),
	blue = Color3.fromRGB(60, 90, 150),
	cyan = Color3.fromRGB(74, 207, 255),
	orange = Color3.fromRGB(255, 140, 60),
	green = Color3.fromRGB(96, 220, 170),
	white = Color3.fromRGB(235, 240, 245),
	gold = Color3.fromRGB(240, 196, 70),
	red = Color3.fromRGB(200, 70, 80),
	leaf = Color3.fromRGB(70, 150, 80),
	leafDark = Color3.fromRGB(52, 118, 64),
	paper = Color3.fromRGB(236, 224, 190),
	lamp = Color3.fromRGB(255, 222, 150),
	metal = Color3.fromRGB(70, 72, 80),
}

-- Each builder receives b = { put, ball, disc, part, model, level }. All coordinates are
-- relative to the building's centre; y = 0 is the top of the plot pad.
local BUILDERS = {}

BUILDERS.StarterHouse = {
	labelY = 10,
	color = C.orange,
	build = function(b)
		b.put(-3.4, 3.4, 0.3, 4.8, -3.2, -2.7, C.wood, M.WoodPlanks, "Back Wall")
		b.put(-3.4, -2.9, 0.3, 4.8, -2.7, 3.2, C.wood, M.WoodPlanks, "Left Wall")
		b.put(2.9, 3.4, 0.3, 4.8, -2.7, 3.2, C.wood, M.WoodPlanks, "Right Wall")
		b.put(-3.4, -1.0, 0.3, 4.8, 2.7, 3.2, C.wood, M.WoodPlanks, "Front Left Wall")
		b.put(1.0, 3.4, 0.3, 4.8, 2.7, 3.2, C.wood, M.WoodPlanks, "Front Right Wall")
		b.put(-1.0, 1.0, 3.2, 4.8, 2.7, 3.2, C.wood, M.WoodPlanks, "Door Header")
		b.put(-3.8, 3.8, 4.8, 5.4, -3.7, 3.7, C.darkWood, M.WoodPlanks, "Cabin Roof")
		b.put(-2.4, -1.3, 2.4, 3.5, 3.21, 3.4, C.cyan, M.Glass, "Window")
		b.put(1.3, 2.4, 2.4, 3.5, 3.21, 3.4, C.cyan, M.Glass, "Window")
		b.put(-4.2, -3.4, 0.3, 2.8, -1.8, -0.8, C.stone, M.Slate, "Chimney")
	end,
}

BUILDERS.CrystalMine = {
	labelY = 8,
	color = C.cyan,
	build = function(b)
		b.put(-3.2, 3.2, 0.3, 3.4, -3.4, 0.6, C.darkWood, M.WoodPlanks, "Hut")
		b.put(-3.6, 3.6, 3.4, 4.1, -3.8, 1.0, C.stone, M.Slate, "Hut Roof")
		b.put(-0.9, 0.9, 0.3, 2.4, 0.5, 0.7, C.darkStone, M.Slate, "Door")
		local spots = { { -2.4, 2.0, 4.5 }, { 0, 2.6, 6 }, { 2.4, 2.0, 4.5 }, { -1.2, 2.9, 3.5 }, { 1.2, 2.9, 3.5 } }
		for i = 1, math.min(#spots, b.level + 1) do
			local spot = spots[i]
			local crystal = b.part(Vector3.new(1.4, spot[3], 1.4), spot[1], 0.3 + spot[3] / 2, spot[2], math.rad(45), math.rad((i % 2 == 0) and 6 or -6), C.cyan, M.Neon, "Crystal")
			if i == 1 then Kit.glow(crystal, C.cyan, 22, 1.5) end
		end
	end,
}

BUILDERS.Barracks = {
	labelY = 14,
	color = C.blue:Lerp(C.white, 0.4),
	build = function(b)
		b.put(-3.4, 3.4, 0.3, 4, -3.4, 3.4, C.wall, M.Brick, "Lower Walls")
		b.put(-3.8, 3.8, 4, 4.8, -3.8, 3.8, C.blue, M.SmoothPlastic, "Lower Roof")
		b.put(-0.8, 0.8, 0.3, 2.6, 3.3, 3.5, C.darkWood, M.Wood, "Door")
		b.put(1.6, 2.8, 2, 3.2, 3.3, 3.5, C.lamp, M.Neon, "Window")
		b.put(-2.8, -1.6, 2, 3.2, 3.3, 3.5, C.lamp, M.Neon, "Window")
		if b.level >= 2 then
			b.put(-2.6, 2.6, 4.8, 7.6, -2.6, 2.6, C.wall, M.Brick, "Upper Walls")
			b.put(-3, 3, 7.6, 8.4, -3, 3, C.blue, M.SmoothPlastic, "Upper Roof")
		end
		if b.level >= 3 then
			b.put(2.6, 3, 8.4, 13, 2.6, 3, C.metal, M.Metal, "Flagpole")
			b.put(0.4, 2.6, 11, 13, 2.7, 2.9, C.red, M.Fabric, "Flag")
		end
	end,
}

BUILDERS.Forge = {
	labelY = 11,
	color = C.orange,
	build = function(b)
		b.put(-3.2, 3.2, 0.3, 3, -3.2, 3.2, C.darkStone, M.Brick, "Body")
		b.put(-3.5, 3.5, 3, 3.5, -3.5, 3.5, C.stone, M.Slate, "Top")
		local fire = b.put(-1.6, 1.6, 0.8, 2.2, 3.1, 3.3, C.orange, M.Neon, "Furnace")
		Kit.glow(fire, C.orange, 24, 2)
		b.put(-1.2, 1.2, 3.5, 4.3, -0.6, 0.6, C.metal, M.Metal, "Anvil")
		b.put(1.4, 2.8, 3.5, 7 + b.level, 1.4, 2.8, C.stone, M.Brick, "Chimney")
		if b.level >= 2 then b.put(-2.8, -1.4, 3.5, 6, 1.4, 2.8, C.stone, M.Brick, "Second Chimney") end
		if b.level >= 3 then b.ball(2.1, 8.6 + b.level, 2.1, 1.6, C.orange, M.Neon, "Ember") end
	end,
}

BUILDERS.Infirmary = {
	labelY = 8,
	color = C.green,
	build = function(b)
		b.disc(0, 0, 7.6, 0.3, 0.9, C.stone, M.Marble, "Pool Rim")
		local water = b.disc(0, 0, 6.2, 0.3, 1.0, C.green, M.Neon, "Pool Water")
		water.Transparency = 0.25
		Kit.glow(water, C.green, 22, 1.2)
		local corners = { { -3, -3 }, { 3, 3 }, { -3, 3 }, { 3, -3 } }
		for i, corner in ipairs(corners) do
			b.put(corner[1] - 0.4, corner[1] + 0.4, 0.3, 3.8, corner[2] - 0.4, corner[2] + 0.4, C.white, M.Marble, "Pillar")
			if i <= b.level + 1 then b.ball(corner[1], 4.5, corner[2], 1.2, C.green, M.Neon, "Healing Orb") end
		end
		if b.level >= 2 then b.ball(0, 2.4, 0, 1.6, C.green, M.Neon, "Heart") end
	end,
}

BUILDERS.BountyBoard = {
	labelY = 9,
	color = C.gold,
	build = function(b)
		b.put(-3, -2.5, 0.3, 6.6, -0.3, 0.3, C.wood, M.Wood, "Post")
		b.put(2.5, 3, 0.3, 6.6, -0.3, 0.3, C.wood, M.Wood, "Post")
		b.put(-3.2, 3.2, 3, 6, -0.2, 0.2, C.darkWood, M.WoodPlanks, "Board")
		b.put(-2.4, -1.0, 3.6, 5.2, 0.2, 0.3, C.paper, M.Fabric, "Note")
		b.put(-0.5, 0.9, 3.8, 5.4, 0.2, 0.3, C.paper, M.Fabric, "Note")
		b.put(1.2, 2.3, 3.5, 5, 0.2, 0.3, C.paper, M.Fabric, "Note")
		for i = 1, b.level + 1 do
			local x0 = -3 + (i - 1) * 1.5
			b.put(x0, x0 + 1.2, 0.3, 0.7 + 0.35 * i, 1.8, 3.0, C.gold, M.Metal, "Coin Stack")
		end
	end,
}

BUILDERS.Lantern = {
	labelY = 0, decor = true,
	build = function(b)
		b.put(-0.2, 0.2, 0.3, 4, -0.2, 0.2, C.metal, M.Metal, "Post")
		local bulb = b.ball(0, 4.6, 0, 1.4, C.lamp, M.Neon, "Bulb")
		Kit.glow(bulb, C.lamp, 20, 1.2)
	end,
}

BUILDERS.Tree = {
	labelY = 0, decor = true,
	build = function(b)
		b.put(-0.4, 0.4, 0.3, 3.2, -0.4, 0.4, C.wood, M.Wood, "Trunk")
		b.ball(0, 4.6, 0, 3.8, C.leaf, M.Grass, "Leaves")
		b.ball(0.9, 3.8, 0.6, 2.4, C.leafDark, M.Grass, "Leaves")
	end,
}

BUILDERS.Statue = {
	labelY = 0, decor = true,
	build = function(b)
		b.put(-1.1, 1.1, 0.3, 1.4, -1.1, 1.1, C.stone, M.Slate, "Plinth")
		b.put(-0.5, 0.5, 1.4, 3.4, -0.4, 0.4, C.white, M.Marble, "Body")
		b.put(-1.0, -0.5, 2.4, 3.0, -0.2, 0.2, C.white, M.Marble, "Arm")
		b.put(0.5, 1.0, 2.4, 3.0, -0.2, 0.2, C.white, M.Marble, "Arm")
		b.ball(0, 3.9, 0, 1.1, C.white, M.Marble, "Head")
	end,
}

local BuildingModels = {}

-- Creates the model for building `id` at world centre (cx, cz), standing on ground height `groundY`.
-- Returns the Model, parented to `parent`.
function BuildingModels.create(id, level, cx, cz, groundY, parent, ownerName, yaw)
	local def = Buildings.Catalog[id]
	local spec = BUILDERS[id]
	if not def or not spec then return nil end

	local model = Instance.new("Model")
	model.Name = def.Name

	yaw = yaw or 0
	local flip = math.abs(yaw) > 0.1
	local b = { model = model, level = level }
	function b.put(x0, x1, y0, y1, z0, z1, color, material, name)
		if flip then x0, x1, z0, z1 = -x1, -x0, -z1, -z0 end
		return Kit.box(model, name or "Part", cx + x0, cx + x1, groundY + y0, groundY + y1, cz + z0, cz + z1, color, material)
	end
	function b.ball(x, y, z, diameter, color, material, name)
		if flip then x, z = -x, -z end
		return Kit.ball(model, name or "Ball", cx + x, groundY + y, cz + z, diameter, color, material)
	end
	function b.disc(x, z, diameter, y0, y1, color, material, name)
		if flip then x, z = -x, -z end
		return Kit.disc(model, name or "Disc", cx + x, cz + z, diameter, groundY + y1, color, material, groundY + y0)
	end
	-- Rotated block: centre (x, y, z), yaw and roll in radians.
	function b.part(size, x, y, z, yaw, roll, color, material, name)
		if flip then x, z = -x, -z end
		local cframe = CFrame.new(cx + x, groundY + y, cz + z) * CFrame.Angles(0, (yaw or 0) + (flip and math.pi or 0), roll)
		return Kit.newPart(model, name or "Part", size, cframe, color, material)
	end

	local halfX = def.W * Buildings.CellSize / 2 - 0.2
	local halfZ = def.D * Buildings.CellSize / 2 - 0.2
	local foundation = b.put(-halfX, halfX, 0, 0.3, -halfZ, halfZ, C.stone, M.Slate, "Foundation")
	model.PrimaryPart = foundation

	spec.build(b)

	if not spec.decor then
		Kit.label(foundation, def.Name .. "  Lv " .. level, ownerName, spec.labelY, spec.color)
	end
	model.Parent = parent
	return model
end

return BuildingModels
