-- Shared starter-base demo: one open base, a moving conveyor loop, soft-currency
-- shop/spins, and server-controlled Shift sprint.

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local StarterPack = game:GetService("StarterPack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Replace any saved prototype scenery with this clean blockout.
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then terrain:Clear() end
for _, oldObject in ipairs(workspace:GetChildren()) do
	if oldObject ~= terrain and not oldObject:IsA("Camera") then oldObject:Destroy() end
end
StarterPack:ClearAllChildren()

local oldRemotes = ReplicatedStorage:FindFirstChild("DemoRemotes")
if oldRemotes then oldRemotes:Destroy() end
local remotes = Instance.new("Folder")
remotes.Name = "DemoRemotes"
remotes.Parent = ReplicatedStorage

local gameAction = Instance.new("RemoteEvent")
gameAction.Name = "GameAction"
gameAction.Parent = remotes
local inventoryChanged = Instance.new("RemoteEvent")
inventoryChanged.Name = "InventoryChanged"
inventoryChanged.Parent = remotes
local shopSpin = Instance.new("RemoteFunction")
shopSpin.Name = "ShopSpin"
shopSpin.Parent = remotes

local map = Instance.new("Folder")
map.Name = "GeneratedBeingsMap"
map.Parent = workspace

local function part(parent, name, size, position, color, material, topSurface)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.Position = position
	item.Anchored = true
	item.TopSurface = topSurface or Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Material = material or Enum.Material.SmoothPlastic
	item.Color = color
	item.Parent = parent
	return item
end

local function labelSign(board, title, subtitle)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "BaseLabel"
	gui.Face = Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(700, 240)
	gui.Parent = board

	local text = Instance.new("TextLabel")
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundColor3 = Color3.fromRGB(111, 68, 42)
	text.BackgroundTransparency = 0.04
	text.TextColor3 = Color3.fromRGB(255, 242, 211)
	text.TextStrokeTransparency = 0.5
	text.Font = Enum.Font.GothamBold
	text.TextScaled = true
	text.TextWrapped = true
	text.Text = title .. "\n" .. subtitle
	text.Parent = gui
end

-- Bright green studded field inspired by the reference image.
local grass = Color3.fromRGB(77, 205, 91)
for x = -7, 6 do
	for z = -6, 5 do
		part(map, "Grass Tile", Vector3.new(16, 2, 16), Vector3.new(x * 16 + 8, -1, z * 16 + 8), grass, Enum.Material.Plastic, Enum.SurfaceType.Studs)
	end
end

-- One large open base: a proper foundation and timber frame, ready for later
-- wall/floor upgrades while remaining easy to walk through in this first pass.
local base = Instance.new("Model")
base.Name = "Shared Starter Base"
base.Parent = map
part(base, "Base Foundation", Vector3.new(64, 1, 50), Vector3.new(0, 0.55, 0), Color3.fromRGB(206, 202, 188), Enum.Material.Concrete)

local wood = Color3.fromRGB(135, 91, 56)
for _, x in ipairs({ -28, 28 }) do
	for _, z in ipairs({ -21, 21 }) do
		part(base, "Frame Post", Vector3.new(1.6, 9, 1.6), Vector3.new(x, 5.5, z), wood, Enum.Material.Wood)
	end
end
part(base, "Front Frame Beam", Vector3.new(58, 1.4, 1.6), Vector3.new(0, 10.2, -21), wood, Enum.Material.Wood)
part(base, "Back Frame Beam", Vector3.new(58, 1.4, 1.6), Vector3.new(0, 10.2, 21), wood, Enum.Material.Wood)
part(base, "Left Frame Beam", Vector3.new(1.6, 1.4, 42), Vector3.new(-28, 10.2, 0), wood, Enum.Material.Wood)
part(base, "Right Frame Beam", Vector3.new(1.6, 1.4, 42), Vector3.new(28, 10.2, 0), wood, Enum.Material.Wood)

part(base, "Base Signpost", Vector3.new(1, 6, 1), Vector3.new(0, 3.5, 27), wood, Enum.Material.Wood)
local sign = part(base, "Base Sign", Vector3.new(20, 5, 0.8), Vector3.new(0, 7.3, 27), Color3.fromRGB(111, 68, 42), Enum.Material.Wood)
labelSign(sign, "YOUR BASE", "Shared starter plot")

-- Four rails define a rectangular conveyor circuit around the base.
local conveyor = Instance.new("Folder")
conveyor.Name = "Looping Conveyor"
conveyor.Parent = map
local rail = Color3.fromRGB(76, 86, 103)
local steel = Enum.Material.Metal
part(conveyor, "Outer Rail North", Vector3.new(90, 1.5, 1), Vector3.new(0, 1.0, -35), rail, steel)
part(conveyor, "Outer Rail South Left", Vector3.new(38, 1.5, 1), Vector3.new(-26, 1.0, 35), rail, steel)
part(conveyor, "Outer Rail South Right", Vector3.new(38, 1.5, 1), Vector3.new(26, 1.0, 35), rail, steel)
part(conveyor, "Outer Rail West", Vector3.new(1, 1.5, 70), Vector3.new(-45, 1.0, 0), rail, steel)
part(conveyor, "Outer Rail East", Vector3.new(1, 1.5, 70), Vector3.new(45, 1.0, 0), rail, steel)

-- Continuous collision decking sits below the moving visual tread tiles.
for _, spec in ipairs({
	{ Vector3.new(84, 0.5, 4.5), Vector3.new(0, 0, -32) },
	{ Vector3.new(4.5, 0.5, 64), Vector3.new(42, 0, 0) },
	{ Vector3.new(84, 0.5, 4.5), Vector3.new(0, 0, 32) },
	{ Vector3.new(4.5, 0.5, 64), Vector3.new(-42, 0, 0) },
}) do
	local deck = part(conveyor, "Conveyor Surface", spec[1], spec[2], rail, steel)
	deck.Transparency = 1
	deck.CanTouch = false
end

local halfX, halfZ = 42, 32
local perimeter = 2 * ((halfX * 2) + (halfZ * 2))
local beltCount = 30
local beltSpacing = perimeter / beltCount
local beltSpeed = 6
local beltSegments = {}

local function pointOnLoop(distance)
	distance %= perimeter
	local northLength = halfX * 2
	local sideLength = halfZ * 2
	local southLength = northLength
	if distance < northLength then
		return Vector3.new(-halfX + distance, 0.35, -halfZ), "X", 1
	end
	distance -= northLength
	if distance < sideLength then
		return Vector3.new(halfX, 0.35, -halfZ + distance), "Z", 1
	end
	distance -= sideLength
	if distance < southLength then
		return Vector3.new(halfX - distance, 0.35, halfZ), "X", -1
	end
	distance -= southLength
	return Vector3.new(-halfX, 0.35, halfZ - distance), "Z", -1
end

for index = 1, beltCount do
	local position, axis, direction = pointOnLoop((index - 1) * beltSpacing)
	local size = axis == "X" and Vector3.new(beltSpacing - 0.35, 0.45, 4) or Vector3.new(4, 0.45, beltSpacing - 0.35)
	local segment = part(conveyor, "Moving Belt", size, position, index % 2 == 0 and Color3.fromRGB(48, 56, 69) or Color3.fromRGB(66, 75, 89), steel)
	segment:SetAttribute("TrackDistance", (index - 1) * beltSpacing)
	segment:SetAttribute("TrackAxis", axis)
	segment:SetAttribute("TrackDirection", direction)
	segment.CanCollide = false
	segment.CanQuery = false
	table.insert(beltSegments, segment)
end

-- The red approach path joins the conveyor loop and the shared spawn.
part(map, "Red Approach Walkway", Vector3.new(12, 0.35, 48), Vector3.new(0, 0.2, 57), Color3.fromRGB(232, 91, 91), Enum.Material.SmoothPlastic)
part(map, "Spawn Plaza", Vector3.new(24, 0.5, 18), Vector3.new(0, 0.25, 82), Color3.fromRGB(235, 232, 218), Enum.Material.Concrete)
local spawn = Instance.new("SpawnLocation")
spawn.Name = "Shared Spawn"
spawn.Size = Vector3.new(8, 1, 8)
spawn.Position = Vector3.new(0, 1, 82)
spawn.Anchored = true
spawn.Neutral = true
spawn.Duration = 0
spawn.Color = Color3.fromRGB(255, 235, 145)
spawn.Material = Enum.Material.Neon
spawn.Parent = map

Lighting.ClockTime = 13.5
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(150, 167, 175)
Lighting.OutdoorAmbient = Color3.fromRGB(180, 195, 200)
Lighting.FogEnd = 1000

local random = Random.new()
local stock = {
	{ Name = "Health Potion", Price = 75 },
	{ Name = "Speed Coil", Price = 180 },
	{ Name = "Lucky Charm", Price = 150 },
	{ Name = "Wood Bundle", Price = 100 },
	{ Name = "Gem Pouch", Price = 250 },
	{ Name = "Pet Egg", Price = 300 },
	{ Name = "Gravity Coil", Price = 220 },
	{ Name = "Magic Carpet", Price = 350 },
	{ Name = "Iron Sword", Price = 125 },
	{ Name = "Magic Wand", Price = 200 },
	{ Name = "Rainbow Trail", Price = 275 },
	{ Name = "Mystery Box", Price = 400 },
}
local prizePool = {
	"Health Potion", "Speed Coil", "Lucky Charm", "Wood Bundle", "Gem Pouch", "Pet Egg",
	"Iron Sword", "Magic Wand", "Shield", "Grapple Hook", "Rainbow Trail", "Mystery Box",
}
local lastSpin = {}

local function inventoryFor(player)
	local inventory = player:FindFirstChild("PlaceholderInventory")
	if not inventory then
		inventory = Instance.new("Folder")
		inventory.Name = "PlaceholderInventory"
		inventory.Parent = player
	end
	return inventory
end

local function addInventoryItem(player, itemName)
	local inventory = inventoryFor(player)
	local count = inventory:FindFirstChild(itemName)
	if not count then
		count = Instance.new("IntValue")
		count.Name = itemName
		count.Value = 0
		count.Parent = inventory
	end
	count.Value += 1
	inventoryChanged:FireClient(player)
	return count.Value
end

local function getCoins(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Coins")
end

shopSpin.OnServerInvoke = function(player, action, itemName)
	local coins = getCoins(player)
	if not coins then return false, "Your wallet is still loading." end
	if action == "Shop" then
		for _, item in ipairs(stock) do
			if item.Name == itemName then
				if coins.Value < item.Price then return false, "Not enough coins." end
				coins.Value -= item.Price
				local count = addInventoryItem(player, item.Name)
				return true, "Bought " .. item.Name .. " • owned " .. count .. ". Placeholder item for now."
			end
		end
		return false, "That item is not in the shop."
	elseif action == "Spin" then
		local now = os.clock()
		if lastSpin[player] and now - lastSpin[player] < 1 then return false, "Wait a moment before spinning again." end
		lastSpin[player] = now
		local price = 50
		if coins.Value < price then return false, "You need 50 coins to spin." end
		coins.Value -= price
		local prize = prizePool[random:NextInteger(1, #prizePool)]
		local count = addInventoryItem(player, prize)
		return true, prize, count
	end
	return false, "Unknown action."
end

local function setSprint(player, enabled)
	if typeof(enabled) ~= "boolean" then return end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.WalkSpeed = enabled and 24 or 16
	end
end

gameAction.OnServerEvent:Connect(function(player, action, value)
	if action == "Sprint" then setSprint(player, value) end
end)

local function onPlayer(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 500
	coins.Parent = leaderstats
	inventoryFor(player)
	task.spawn(function()
		while player.Parent do
			task.wait(8)
			if player.Parent and coins.Parent then coins.Value += 10 end
		end
	end)

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		local root = character:WaitForChild("HumanoidRootPart", 10)
		if humanoid then humanoid.WalkSpeed = 16 end
		if root then root.CFrame = CFrame.new(0, 5, 82) end
	end)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	lastSpin[player] = nil
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

-- Move each conveyor tile continuously around the rectangular circuit.
RunService.Heartbeat:Connect(function(deltaTime)
	for _, segment in ipairs(beltSegments) do
		local distance = (segment:GetAttribute("TrackDistance") + beltSpeed * deltaTime) % perimeter
		segment:SetAttribute("TrackDistance", distance)
		local position, axis = pointOnLoop(distance)
		segment.Position = position
		local width = 4
		segment.Size = axis == "X"
			and Vector3.new(beltSpacing - 0.35, 0.45, width)
			or Vector3.new(width, 0.45, beltSpacing - 0.35)
	end
end)

print("[StarterBase] Built one large base and its moving conveyor loop.")
