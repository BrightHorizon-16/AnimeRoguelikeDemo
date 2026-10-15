-- Builds the base-focused prototype map. The outer world is intentionally absent for now.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local Kit = require(script.Parent:WaitForChild("PartKit"))

local WorldBuilder = { EnemySpawns = {} }
local folder, newPart, box, ball, disc, glow, label = Kit.folder, Kit.newPart, Kit.box, Kit.ball, Kit.disc, Kit.glow, Kit.label

local C = {
	grass = Color3.fromRGB(62, 105, 77),
	plot = Color3.fromRGB(73, 126, 88),
	stone = Color3.fromRGB(112, 120, 138),
	darkStone = Color3.fromRGB(58, 64, 82),
	wall = Color3.fromRGB(78, 84, 104),
	wood = Color3.fromRGB(121, 85, 58),
	darkWood = Color3.fromRGB(78, 56, 42),
	cyan = Color3.fromRGB(74, 207, 255),
	violet = Color3.fromRGB(170, 110, 255),
	gate = Color3.fromRGB(48, 49, 75),
	banner = Color3.fromRGB(38, 70, 120),
	lamp = Color3.fromRGB(255, 222, 150),
}

local function lamp(parent, x, z)
	box(parent, "Courtyard Lamp Post", x - 0.35, x + 0.35, 0, 5, z - 0.35, z + 0.35, C.darkStone, Enum.Material.Metal)
	local bulb = ball(parent, "Courtyard Lamp", x, 5.7, z, 1.5, C.lamp, Enum.Material.Neon)
	glow(bulb, C.lamp, 20, 1)
end

local function buildFloor(world)
	local floor = folder(world, "Floor")
	box(floor, "Base Island", -55, 55, -4, 0, -55, 55, C.grass, Enum.Material.Grass)
	return floor
end

local function buildPlaza(base)
	local plaza = folder(base, "Central Plaza")
	disc(plaza, "Outer Plaza", 0, 0, 34, 0.25, C.stone, Enum.Material.Cobblestone, 0)
	disc(plaza, "Cyan Inlay", 0, 0, 28, 0.35, C.cyan, Enum.Material.Neon, 0.25)
	disc(plaza, "Inner Plaza", 0, 0, 25, 0.45, C.darkStone, Enum.Material.Slate, 0.35)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Base Checkpoint"
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.Position = Vector3.new(0, 0.95, 0)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Color = C.cyan
	spawn.Parent = plaza

end

local function buildPaths(base)
	local paths = folder(base, "Walkways")
	local function path(name, x0, x1, z0, z1)
		box(paths, name, x0, x1, -0.2, 0.12, z0, z1, C.stone, Enum.Material.Cobblestone)
	end
	path("North Walk", -4, 4, -36, -15)
	path("Northwest Plot Walk", -35, -31, -17, -12)
	path("Northeast Plot Walk", 31, 35, -17, -12)
	path("Southwest Plot Walk", -35, -31, 12, 17)
	path("Southeast Plot Walk", 31, 35, 12, 17)
	for _, point in ipairs({ { -19, 0 }, { 19, 0 }, { 0, -19 }, { 0, 19 } }) do
		lamp(paths, point[1], point[2])
	end
end

local function addGatherNode(root, name, resource, amount, x, z, style)
	local node = folder(root, name)
	local promptPart
	if style == "Wood" then
		promptPart = box(node, "Trunk", x - 0.7, x + 0.7, 0.3, 4.8, z - 0.7, z + 0.7, C.darkWood, Enum.Material.Wood)
		ball(node, "Canopy", x, 5.2, z, 5.2, Color3.fromRGB(68, 145, 78), Enum.Material.Grass)
		ball(node, "Canopy", x - 1.8, 4.6, z + 0.5, 3.2, Color3.fromRGB(82, 165, 88), Enum.Material.Grass)
	elseif style == "Stone" then
		promptPart = ball(node, "Boulder", x, 1.8, z, 4.2, C.stone, Enum.Material.Slate)
		ball(node, "Boulder Detail", x + 1.2, 2.8, z - 0.6, 2.2, C.darkStone, Enum.Material.Slate)
	else
		promptPart = ball(node, "Essence Crystal", x, 2.0, z, 3.0, C.violet, Enum.Material.Neon)
		glow(promptPart, C.violet, 12, 0.8)
	end
	node:SetAttribute("Resource", resource)
	node:SetAttribute("Amount", amount)
	node:SetAttribute("Available", true)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "GatherPrompt"
	prompt.ActionText = "Gather"
	prompt.ObjectText = resource == "Shards" and "Essence" or resource
	prompt.KeyboardKeyCode = Enum.KeyCode.F
	prompt.HoldDuration = 0.45
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = promptPart
	return node
end

local function buildGatherNodes(world)
	local nodes = folder(world, "GatherNodes")
	addGatherNode(nodes, "North Timber", "Wood", 8, -8, -24, "Wood")
	addGatherNode(nodes, "North Rock", "Stone", 6, 8, -24, "Stone")
	addGatherNode(nodes, "East Timber", "Wood", 8, 24, -8, "Wood")
	addGatherNode(nodes, "East Crystal", "Shards", 2, 24, 8, "Essence")
	addGatherNode(nodes, "South Timber", "Wood", 8, 8, 24, "Wood")
	addGatherNode(nodes, "South Rock", "Stone", 6, -8, 24, "Stone")
	addGatherNode(nodes, "West Rock", "Stone", 6, -24, 8, "Stone")
	addGatherNode(nodes, "West Crystal", "Shards", 2, -24, -8, "Essence")
end

local function buildPlots(world)
	local pads = folder(world, "PlotPads")
	local decor = folder(world, "PlotDecor")
	local owned = folder(world, "PlayerBuildings")
	local size = Buildings.PlotCells * Buildings.CellSize
	for index, plot in ipairs(Buildings.Plots) do
		local x0, x1 = plot.MinX, plot.MinX + size
		local z0, z1 = plot.MinZ, plot.MinZ + size
		box(pads, "Home Plot " .. index, x0, x1, -0.1, 0.3, z0, z1, C.plot, Enum.Material.Grass)
		folder(owned, "Plot" .. index)

		local trim = folder(decor, "Plot" .. index)
		box(trim, "North Border", x0, x1, 0.3, 0.52, z0, z0 + 0.35, C.cyan, Enum.Material.Neon)
		box(trim, "South Border", x0, x1, 0.3, 0.52, z1 - 0.35, z1, C.cyan, Enum.Material.Neon)
		box(trim, "West Border", x0, x0 + 0.35, 0.3, 0.52, z0 + 0.35, z1 - 0.35, C.cyan, Enum.Material.Neon)
		box(trim, "East Border", x1 - 0.35, x1, 0.3, 0.52, z0 + 0.35, z1 - 0.35, C.cyan, Enum.Material.Neon)
		for _, x in ipairs({ x0, x1 }) do
			for _, z in ipairs({ z0, z1 }) do
				box(trim, "Plot Corner", x - 0.65, x + 0.65, 0.3, 2.6, z - 0.65, z + 0.65, C.darkStone, Enum.Material.Slate)
			end
		end

		-- Put the plot sign on the side nearest the shared courtyard.
		local frontEdge = math.abs(z0) < math.abs(z1) and z0 or z1
		local inward = frontEdge < 0 and 1 or -1
		local signZ = frontEdge + inward * 1.8
		local midX = (x0 + x1) / 2
		box(trim, "Plot Sign Post", midX - 0.3, midX + 0.3, 0.3, 4.3, signZ - 0.2, signZ + 0.2, C.darkWood, Enum.Material.Wood)
		local board = box(trim, "Plot Sign", midX - 4, midX + 4, 4.3, 7, signZ - 0.25, signZ + 0.25, C.darkStone, Enum.Material.Slate)
		label(board, "HOME PLOT " .. index, "Available", 0, C.cyan)
	end
end

local function validate(world)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world:FindFirstChild("Floor") }
	local problems = 0
	for z = -50, 50, 10 do
		for x = -50, 50, 10 do
			if not workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), params) then
				problems += 1
				warn(string.format("[WorldBuilder] Missing base floor at x=%.1f, z=%.1f", x, z))
			end
		end
	end
	for index, plot in ipairs(Buildings.Plots) do
		local size = Buildings.PlotCells * Buildings.CellSize
		local x, z = plot.MinX + size / 2, plot.MinZ + size / 2
		if not workspace:Raycast(Vector3.new(x, 30, z), Vector3.new(0, -60, 0), params) then
			problems += 1
			warn("[WorldBuilder] Home plot " .. index .. " is over the void.")
		end
	end
	if problems == 0 then
		print("[WorldBuilder] Base floor check passed: courtyard and all four home plots are supported.")
	else
		warn("[WorldBuilder] Base floor check found " .. problems .. " problem(s).")
	end
end

function WorldBuilder.build(world, Config)
	buildFloor(world)
	local base = folder(world, "Base")
	buildPlaza(base)
	buildPaths(base)
	buildPlots(world)
	buildGatherNodes(world)
	validate(world)
end

return WorldBuilder
