-- WorldBuilder: builds the runtime map for the prototype.
--
-- Layout (Z runs from the base toward the wilds, floor top is y = 0):
--   Home Island   z  -55..55    walled base compound
--   Region Path   z 54.5..185.5 24 wide, overlaps each neighbour by 0.5 studs
--   Wilds         z  185..355
--   Builder Terrace z -110..-54.5 behind the Guild Hall: four build plots (see Buildings.Plots)
--
-- Floor rules (these fix the original glitches):
--   * No two floor parts share an overlapping, coplanar top face (that is z-fighting).
--     The path sits 0.2 studs above its neighbours and overlaps them, so there is no
--     flicker and no hairline seam.
--   * Every enemy spawn and decoration is placed over real floor.
--   * Invisible rails keep players from walking or dashing off the path into the void.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))

local WorldBuilder = {}

-- Enemy spawn points. All of them are over floor; build() verifies this and warns if not.
WorldBuilder.EnemySpawns = {
	Vector3.new(-5, 5, 100),
	Vector3.new(6, 5, 140),
	Vector3.new(-35, 5, 210),
	Vector3.new(30, 5, 235),
	Vector3.new(-15, 5, 270),
	Vector3.new(22, 5, 320),
}

local COLORS = {
	grass = Color3.fromRGB(55, 104, 93),
	path = Color3.fromRGB(104, 91, 72),
	wilds = Color3.fromRGB(69, 111, 76),
	stone = Color3.fromRGB(112, 120, 138),
	darkStone = Color3.fromRGB(58, 64, 82),
	wall = Color3.fromRGB(78, 84, 104),
	wood = Color3.fromRGB(121, 85, 58),
	darkWood = Color3.fromRGB(78, 56, 42),
	cyan = Color3.fromRGB(74, 207, 255),
	violet = Color3.fromRGB(170, 110, 255),
	gate = Color3.fromRGB(48, 49, 75),
	crystal = Color3.fromRGB(102, 214, 160),
	banner = Color3.fromRGB(38, 70, 120),
	lamp = Color3.fromRGB(255, 222, 150),
	terrace = Color3.fromRGB(62, 110, 82),
	plot = Color3.fromRGB(86, 140, 100),
}

-- One accent colour per starter being, used for its station. Unknown names get the fallback.
local STATION_COLORS = {
	Kairo = Color3.fromRGB(232, 112, 64),
	Vexa = Color3.fromRGB(158, 108, 232),
	Mori = Color3.fromRGB(96, 196, 118),
	Nyx = Color3.fromRGB(84, 88, 168),
	Aru = Color3.fromRGB(112, 196, 240),
}
local FALLBACK_STATION_COLOR = Color3.fromRGB(150, 160, 175)

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local Kit = require(script.Parent:WaitForChild("PartKit"))
local folder, newPart, box, ball, disc, glow, label = Kit.folder, Kit.newPart, Kit.box, Kit.ball, Kit.disc, Kit.glow, Kit.label

local function lamp(parent, x, z)
	box(parent, "Lamp Post", x - 0.3, x + 0.3, 0, 6, z - 0.3, z + 0.3, COLORS.darkStone, Enum.Material.Metal)
	local bulb = ball(parent, "Lamp Bulb", x, 6.7, z, 1.6, COLORS.lamp, Enum.Material.Neon)
	glow(bulb, COLORS.lamp, 18, 1)
end

-- ---------------------------------------------------------------------------
-- Floors and rails
-- ---------------------------------------------------------------------------

local function buildFloors(world)
	local floor = folder(world, "Floor")
	box(floor, "Home Island", -55, 55, -4, 0, -55, 55, COLORS.grass, Enum.Material.Grass)
	-- Path top is 0.2 above its neighbours and it overlaps each by 0.5 studs.
	box(floor, "Region Path", -12, 12, -3.8, 0.2, 54.5, 185.5, COLORS.path, Enum.Material.Ground)
	box(floor, "Wilds", -75, 75, -4, 0, 185, 355, COLORS.wilds, Enum.Material.Grass)
	-- Builder terrace: top 0.2 above the island and overlapping it by 0.5 studs, like the path.
	box(floor, "Builder Terrace", -60, 60, -3.8, 0.2, -110, -54.5, COLORS.terrace, Enum.Material.Grass)
	return floor
end

local function rail(parent, name, x0, x1, z0, z1)
	local part = box(parent, name, x0, x1, 0, 14, z0, z1, Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	part.Transparency = 1
	part.CanQuery = false
	part.CanTouch = false
	return part
end

local function buildRails(world)
	local rails = folder(world, "Rails")
	-- Along both sides of the path
	rail(rails, "Path Rail Left", -13, -12, 55, 185)
	rail(rails, "Path Rail Right", 12, 13, 55, 185)
	-- Around the wilds
	rail(rails, "Wilds Rail Left", -76, -75, 185, 355)
	rail(rails, "Wilds Rail Right", 75, 76, 185, 355)
	rail(rails, "Wilds Rail Back", -76, 76, 355, 356)
	-- Around the builder terrace (the front corners stop players stepping off beside the island)
	rail(rails, "Terrace Rail Left", -61, -60, -110, -54.5)
	rail(rails, "Terrace Rail Right", 60, 61, -110, -54.5)
	rail(rails, "Terrace Rail Back", -61, 61, -111, -110)
	rail(rails, "Terrace Front Left", -61, -55, -54.5, -53.5)
	rail(rails, "Terrace Front Right", 55, 61, -54.5, -53.5)
end

local function buildCrystals(world, rng)
	local crystals = folder(world, "Crystals")
	local function crystal(x, z)
		local height = rng:NextInteger(8, 16)
		local tilt = CFrame.Angles(math.rad(rng:NextInteger(-8, 8)), math.rad(rng:NextInteger(0, 90)), math.rad(rng:NextInteger(-8, 8)))
		newPart(crystals, "Wilds Crystal", Vector3.new(3, height, 3), CFrame.new(x, height / 2, z) * tilt, COLORS.crystal, Enum.Material.Neon)
	end
	-- Beside the path (inside its 24-stud width)
	for _, z in ipairs({ 85, 115, 145, 175 }) do
		crystal(-9, z)
		crystal(9, z)
	end
	-- Edges of the wilds (floor spans x = +-75)
	for _, z in ipairs({ 200, 240, 280, 320 }) do
		crystal(-(55 + rng:NextInteger(0, 12)), z)
		crystal(55 + rng:NextInteger(0, 12), z)
	end
end

-- ---------------------------------------------------------------------------
-- Base compound
-- ---------------------------------------------------------------------------

local function buildWallsAndGate(base)
	local walls = folder(base, "Walls")
	-- Corner towers: x = +-49..55, back z -55..-49, front z 47..53
	local towers = { { -55, -49, -55, -48 }, { 47, 53, 46, 53 } }
	for _, sx in ipairs({ -1, 1 }) do
		for _, t in ipairs(towers) do
			box(walls, "Corner Tower", sx * 49, sx * 55, 0, 14, t[1], t[2], COLORS.wall, Enum.Material.Brick)
			box(walls, "Tower Cap", sx * 48, sx * 55, 14, 15, t[3], t[4], COLORS.darkStone, Enum.Material.Slate)
			local orb = ball(walls, "Tower Light", sx * 52, 16.6, (t[1] + t[2]) / 2, 3, COLORS.cyan, Enum.Material.Neon)
			glow(orb, COLORS.cyan, 26, 1.2)
		end
		-- Side walls and the two halves of the front wall (neighbours abut exactly)
		box(walls, "Side Wall", sx * 52, sx * 54, 0, 8, -49, 47, COLORS.wall, Enum.Material.Brick)
		box(walls, "Front Wall", sx * 14, sx * 49, 0, 8, 49, 51, COLORS.wall, Enum.Material.Brick)
	end
	-- Back wall has an opening at x = 28..36 leading to the Builder Grounds
	box(walls, "Back Wall West", -49, 26, 0, 8, -54, -52, COLORS.wall, Enum.Material.Brick)
	box(walls, "Back Wall East", 38, 49, 0, 8, -54, -52, COLORS.wall, Enum.Material.Brick)
	local builderGate = folder(base, "Builder Gate")
	box(builderGate, "Builder Gate Pillar", 26, 28, 0, 12, -54.5, -51.5, COLORS.gate, Enum.Material.Slate)
	box(builderGate, "Builder Gate Pillar", 36, 38, 0, 12, -54.5, -51.5, COLORS.gate, Enum.Material.Slate)
	local builderLintel = box(builderGate, "Builder Gate Lintel", 26, 38, 12, 14.5, -54.5, -51.5, COLORS.gate, Enum.Material.Slate)
	label(builderLintel, "BUILDER GROUNDS", "Claim a plot and build your base (V)", 4, COLORS.violet)

	-- Expedition gate in the front wall (opening is x = -10..10)
	local gate = folder(base, "Expedition Gate")
	for _, sx in ipairs({ -1, 1 }) do
		box(gate, "Gate Pillar", sx * 10, sx * 14, 0, 22, 48, 52, COLORS.gate, Enum.Material.Slate)
		box(gate, "Gate Light Strip", sx * 9.5, sx * 10.5, 1, 19, 49.5, 50.5, COLORS.cyan, Enum.Material.Neon)
	end
	local lintel = box(gate, "Gate Lintel", -16, 16, 22, 25, 48.5, 51.5, COLORS.gate, Enum.Material.Slate)
	label(lintel, "EXPEDITION GATE", "To the Wilds", 4, COLORS.cyan)
end

local function buildPlaza(base)
	-- Tops are 0.3 / 0.4 / 0.5 so no two stacked discs share a face.
	disc(base, "Plaza", 0, -12, 44, 0.3, COLORS.stone, Enum.Material.Cobblestone)
	disc(base, "Plaza Ring", 0, -12, 32, 0.4, COLORS.cyan, Enum.Material.Neon)
	disc(base, "Plaza Inner", 0, -12, 29, 0.5, COLORS.darkStone, Enum.Material.Slate)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Base Checkpoint"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 1, -12) -- sits on the inner disc (top 0.5)
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.TopSurface = Enum.SurfaceType.Smooth
	spawn.BottomSurface = Enum.SurfaceType.Smooth
	spawn.Color = Color3.fromRGB(80, 190, 255)
	spawn.Parent = base

	-- Beacon on a plinth, north of the spawn
	box(base, "Beacon Plinth", -5, 5, 0, 1.2, -33, -23, COLORS.stone, Enum.Material.Cobblestone)
	local beacon = box(base, "Base Beacon", -3, 3, 1.2, 15.2, -31, -25, COLORS.cyan, Enum.Material.Neon)
	glow(beacon, COLORS.cyan, 40, 2)
end

local function buildWalkways(base)
	local paths = folder(base, "Walkways")
	-- Tops at 0.1: below the plaza (0.3) and stall/hall floors (0.4), above the grass (0).
	local function walkway(name, x0, x1, z0, z1)
		box(paths, name, x0, x1, -0.4, 0.1, z0, z1, COLORS.stone, Enum.Material.Cobblestone)
	end
	walkway("Gate Walkway", -5, 5, 9, 50)
	walkway("Hall Walkway", -5, 5, -38, -33)
	walkway("East Connector", 18, 31, -14.5, -9.5)
	walkway("East Promenade", 31, 36, -52, 38)
	walkway("West Connector", -27, -18, -14.5, -9.5)
	walkway("Altar Connector", -31, -5, 19.5, 24.5)

	for _, z in ipairs({ 16, 28, 40 }) do
		lamp(paths, -7, z)
		lamp(paths, 7, z)
	end
end

local function buildHall(base)
	local hall = folder(base, "Guild Hall")
	box(hall, "Hall Floor", -17, 17, -0.2, 0.4, -52, -38, COLORS.darkWood, Enum.Material.WoodPlanks)
	for _, sx in ipairs({ -1, 1 }) do
		box(hall, "Hall Wall", sx * 17, sx * 18.5, 0, 11, -52, -38, COLORS.wall, Enum.Material.Brick)
		box(hall, "Hall Banner", sx * 17.2, sx * 16.6, 3, 10, -47, -43, COLORS.banner, Enum.Material.Fabric)
	end
	box(hall, "Hall Roof", -19.5, 19.5, 11, 12.5, -52.5, -36.5, COLORS.darkWood, Enum.Material.WoodPlanks)
	local sign = box(hall, "Hall Sign", -11, 11, 8, 11, -37.3, -36.7, COLORS.darkStone, Enum.Material.Slate)
	label(sign, "GUILD HALL", "Roster  •  Recruit  •  Absorb  (press B)", 0, COLORS.cyan)

	-- Roster desk
	box(hall, "Roster Desk", -7, 7, 0.4, 4.2, -46.5, -43.5, COLORS.wood, Enum.Material.Wood)
	local top = box(hall, "Roster Desk Top", -7.5, 7.5, 4.2, 4.6, -47, -43, COLORS.darkWood, Enum.Material.WoodPlanks)
	label(top, "Roster Desk", "Assign workers to earn coins", 3, COLORS.lamp)

	-- Hanging lamp
	box(hall, "Lamp Chain", -0.1, 0.1, 10.2, 11, -44.1, -43.9, COLORS.darkStone, Enum.Material.Metal)
	local bulb = ball(hall, "Hall Lamp", 0, 9.6, -44, 1.6, COLORS.lamp, Enum.Material.Neon)
	glow(bulb, COLORS.lamp, 30, 1.5)
end

-- A themed open-air station for one being. Open toward the plaza (-X side).
local function buildStation(parent, character, color, cx, cz)
	local model = folder(parent, character.Name .. " Station")
	local dark = color:Lerp(Color3.new(0, 0, 0), 0.55)
	box(model, "Pad", cx - 6, cx + 6, -0.2, 0.4, cz - 6, cz + 6, dark, Enum.Material.WoodPlanks)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			box(model, "Post", cx + sx * 5, cx + sx * 6, 0.4, 9.4, cz + sz * 5, cz + sz * 6, COLORS.darkWood, Enum.Material.Wood)
		end
	end
	local roof = box(model, "Roof", cx - 7, cx + 7, 9.4, 10.4, cz - 7, cz + 7, color, Enum.Material.SmoothPlastic)
	box(model, "Counter", cx + 1, cx + 4, 0.4, 3, cz - 4, cz + 4, COLORS.wood, Enum.Material.Wood)
	box(model, "Counter Top", cx + 0.8, cx + 4.2, 3, 3.3, cz - 4.2, cz + 4.2, dark, Enum.Material.WoodPlanks)
	local orb = ball(model, "Station Orb", cx + 2.5, 5, cz, 2.2, color, Enum.Material.Neon)
	glow(orb, color, 18, 1.5)
	label(roof, character.Name, character.Title .. "  •  " .. character.Ability, 3.2, color:Lerp(Color3.new(1, 1, 1), 0.35))
end

local function buildStations(base, Config)
	local stations = folder(base, "Stations")
	local zPositions = { -40, -22, -4, 14, 32 } -- room for 5 beings; add more rows if the catalog grows
	for index, character in ipairs(Config.Characters) do
		local z = zPositions[index]
		if not z then
			break
		end
		buildStation(stations, character, STATION_COLORS[character.Name] or FALLBACK_STATION_COLOR, 42, z)
	end
end

local function buildShrine(base, Config)
	local shrine = folder(base, "Recruitment Shrine")
	local cx, cz = -38, -12
	disc(shrine, "Shrine Base", cx, cz, 24, 0.5, COLORS.stone, Enum.Material.Cobblestone)
	disc(shrine, "Shrine Ring", cx, cz, 18, 0.6, COLORS.cyan, Enum.Material.Neon)
	disc(shrine, "Shrine Inner", cx, cz, 16.4, 0.7, COLORS.darkStone, Enum.Material.Slate)
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			box(shrine, "Shrine Pillar", cx + sx * 7, cx + sx * 9, 0.5, 12, cz + sz * 7, cz + sz * 9, COLORS.stone, Enum.Material.Marble)
			local orb = ball(shrine, "Shrine Orb", cx + sx * 8, 13.2, cz + sz * 8, 2.2, COLORS.cyan, Enum.Material.Neon)
			glow(orb, COLORS.cyan, 16, 1)
		end
	end
	local core = ball(shrine, "Summoning Crystal", cx, 6, cz, 4, COLORS.cyan, Enum.Material.Neon)
	glow(core, COLORS.cyan, 30, 2)
	label(core, "RECRUITMENT SHRINE", "Recruit a random being - " .. Config.RecruitCost .. " coins (B)", 4.5, COLORS.cyan)
end

local function buildAltar(base)
	local altar = folder(base, "Absorption Altar")
	local cx, cz = -38, 22
	disc(altar, "Altar Base", cx, cz, 16, 0.5, COLORS.darkStone, Enum.Material.Slate)
	disc(altar, "Altar Ring", cx, cz, 12, 0.6, COLORS.violet, Enum.Material.Neon)
	box(altar, "Altar Block", cx - 3, cx + 3, 0.6, 3.6, cz - 2, cz + 2, COLORS.darkStone, Enum.Material.Marble)
	for _, sz in ipairs({ -1, 1 }) do
		box(altar, "Altar Pillar", cx - 0.8, cx + 0.8, 0.5, 8, cz + sz * 6 - 0.8, cz + sz * 6 + 0.8, COLORS.darkStone, Enum.Material.Marble)
		local orb = ball(altar, "Altar Orb", cx, 8.8, cz + sz * 6, 1.8, COLORS.violet, Enum.Material.Neon)
		glow(orb, COLORS.violet, 14, 1)
	end
	local core = ball(altar, "Absorption Core", cx, 5.4, cz, 2.4, COLORS.violet, Enum.Material.Neon)
	glow(core, COLORS.violet, 26, 2)
	label(core, "ABSORPTION ALTAR", "Absorb a reserve being to learn its ability (B)", 3.5, COLORS.violet)
end

local function buildBase(world, Config)
	local base = folder(world, "Base")
	buildPlaza(base)
	buildWalkways(base)
	buildWallsAndGate(base)
	buildHall(base)
	buildStations(base, Config)
	buildShrine(base, Config)
	buildAltar(base)
end

-- ---------------------------------------------------------------------------
-- Builder Grounds: plot pads, borders and claim signs
-- ---------------------------------------------------------------------------

local function buildPlots(world)
	local pads = folder(world, "PlotPads")
	local decor = folder(world, "PlotDecor")
	local owned = folder(world, "PlayerBuildings") -- BaseManager fills one sub-folder per plot
	local size = Buildings.PlotCells * Buildings.CellSize
	for index, plot in ipairs(Buildings.Plots) do
		local x0, x1, z0, z1 = plot.MinX, plot.MinX + size, plot.MinZ, plot.MinZ + size
		box(pads, "Plot" .. index .. " Pad", x0, x1, -0.1, 0.3, z0, z1, COLORS.plot, Enum.Material.Grass)
		folder(owned, "Plot" .. index)

		local d = folder(decor, "Plot" .. index)
		-- Border strips (they don't overlap each other) and corner posts
		box(d, "Border", x0, x1, 0.3, 0.38, z0, z0 + 0.5, COLORS.cyan, Enum.Material.Neon)
		box(d, "Border", x0, x1, 0.3, 0.38, z1 - 0.5, z1, COLORS.cyan, Enum.Material.Neon)
		box(d, "Border", x0, x0 + 0.5, 0.3, 0.38, z0 + 0.5, z1 - 0.5, COLORS.cyan, Enum.Material.Neon)
		box(d, "Border", x1 - 0.5, x1, 0.3, 0.38, z0 + 0.5, z1 - 0.5, COLORS.cyan, Enum.Material.Neon)
		for _, cx in ipairs({ x0, x1 }) do
			for _, cz in ipairs({ z0, z1 }) do
				box(d, "Corner Post", cx - 0.6, cx + 0.6, 0.3, 3, cz - 0.6, cz + 0.6, COLORS.darkStone, Enum.Material.Slate)
			end
		end
		-- Claim sign on the front edge (toward the gate)
		local mid = (x0 + x1) / 2
		box(d, "Sign Post", mid - 0.3, mid + 0.3, 0, 4, z1 + 1.8, z1 + 2.2, COLORS.darkWood, Enum.Material.Wood)
		local board = box(d, "Plot Sign", mid - 3.5, mid + 3.5, 4, 6.5, z1 + 1.8, z1 + 2.2, COLORS.darkStone, Enum.Material.Slate)
		label(board, "PLOT " .. index, "Open - unclaimed", 0, COLORS.cyan)
	end
	for _, x in ipairs({ -40, -14, 16, 44 }) do
		lamp(decor, x, -62)
	end
end

-- ---------------------------------------------------------------------------
-- Self-check
-- ---------------------------------------------------------------------------

-- Casts straight down at known points and warns if any are over the void, or if the floor
-- height jumps by more than a Humanoid can step. Results appear in the Output window.
local function validate(world)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { world:FindFirstChild("Floor") }

	local problems = 0
	local function check(description, x, z, maxStep)
		local hit = workspace:Raycast(Vector3.new(x, 50, z), Vector3.new(0, -100, 0), params)
		if not hit then
			warn(string.format("[WorldBuilder] No floor at %s (x=%.1f, z=%.1f)", description, x, z))
			problems += 1
			return nil
		end
		if maxStep and (hit.Position.Y < -0.05 or hit.Position.Y > maxStep) then
			warn(string.format("[WorldBuilder] Floor height %.2f at %s (x=%.1f, z=%.1f) is outside the walkable range", hit.Position.Y, description, x, z))
			problems += 1
		end
		return hit
	end

	-- Walk the centre line from the back of the base to the end of the wilds
	for z = -105, 350, 5 do
		check("centre line", 0, z, 0.25)
	end
	for index, plot in ipairs(Buildings.Plots) do
		local size = Buildings.PlotCells * Buildings.CellSize
		check("plot " .. index .. " centre", plot.MinX + size / 2, plot.MinZ + size / 2, 0.25)
	end
	-- Both edges of the path, and the corners of the wilds
	for z = 56, 184, 8 do
		check("path edge", -11.5, z, 0.25)
		check("path edge", 11.5, z, 0.25)
	end
	for _, x in ipairs({ -70, 70 }) do
		for _, z in ipairs({ 190, 350 }) do
			check("wilds corner", x, z, 0.25)
		end
	end
	for index, point in ipairs(WorldBuilder.EnemySpawns) do
		check("enemy spawn " .. index, point.X, point.Z, 0.25)
	end

	if problems == 0 then
		print("[WorldBuilder] Floor check passed: continuous from builder grounds to wilds, all enemy spawns over floor.")
	else
		warn("[WorldBuilder] Floor check found " .. problems .. " problem(s).")
	end
end

-- ---------------------------------------------------------------------------

function WorldBuilder.build(world, Config)
	local rng = Random.new()
	buildFloors(world)
	buildRails(world)
	buildCrystals(world, rng)
	buildBase(world, Config)
	buildPlots(world)
	validate(world)
end

return WorldBuilder
