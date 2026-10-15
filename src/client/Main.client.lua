-- Compact starter UI for the shared base demo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("DemoRemotes")
local gameAction = remotes:WaitForChild("GameAction")
local shopSpin = remotes:WaitForChild("ShopSpin")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")

local COLORS = {
	panel = Color3.fromRGB(28, 34, 46),
	panel2 = Color3.fromRGB(41, 50, 66),
	blue = Color3.fromRGB(90, 163, 245),
	green = Color3.fromRGB(90, 205, 130),
	gold = Color3.fromRGB(255, 205, 95),
	white = Color3.fromRGB(245, 248, 255),
	muted = Color3.fromRGB(173, 187, 205),
}

local function corner(instance, radius)
	local value = Instance.new("UICorner")
	value.CornerRadius = UDim.new(0, radius or 10)
	value.Parent = instance
end

local function outline(instance, color, thickness)
	local value = Instance.new("UIStroke")
	value.Color = color or COLORS.blue
	value.Thickness = thickness or 1.5
	value.Transparency = 0.2
	value.Parent = instance
end

local function text(parent, name, value, size, position, fontSize, color, font)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.Text = value
	label.TextColor3 = color or COLORS.white
	label.TextSize = fontSize or 18
	label.Font = font or Enum.Font.GothamMedium
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function button(parent, name, value, size, position, color)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundColor3 = color or COLORS.blue
	item.BorderSizePixel = 0
	item.Text = value
	item.TextColor3 = COLORS.white
	item.TextSize = 17
	item.Font = Enum.Font.GothamBold
	item.AutoButtonColor = true
	item.Parent = parent
	corner(item, 9)
	return item
end

local gui = Instance.new("ScreenGui")
gui.Name = "StarterBaseUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local wallet = Instance.new("Frame")
wallet.Name = "Wallet"
wallet.Size = UDim2.fromOffset(220, 54)
wallet.Position = UDim2.new(0, 18, 0, 18)
wallet.BackgroundColor3 = COLORS.panel
wallet.BackgroundTransparency = 0.04
wallet.BorderSizePixel = 0
wallet.Parent = gui
corner(wallet, 11)
outline(wallet, COLORS.green)
text(wallet, "WalletIcon", "◈", UDim2.fromOffset(30, 50), UDim2.fromOffset(14, 2), 24, COLORS.gold, Enum.Font.GothamBold)
local coinText = text(wallet, "Coins", "Coins: 500", UDim2.new(1, -56, 1, 0), UDim2.fromOffset(52, 0), 19, COLORS.white, Enum.Font.GothamBold)

local inventoryToggle = button(gui, "InventoryToggle", "INVENTORY", UDim2.fromOffset(128, 50), UDim2.new(1, -430, 0, 20), COLORS.green)
local shopToggle = button(gui, "ShopToggle", "SHOP", UDim2.fromOffset(128, 50), UDim2.new(1, -290, 0, 20), COLORS.blue)
local spinToggle = button(gui, "SpinToggle", "SPIN  ·  50", UDim2.fromOffset(132, 50), UDim2.new(1, -148, 0, 20), Color3.fromRGB(164, 107, 236))

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(500, 42)
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -20)
status.BackgroundColor3 = COLORS.panel
status.BackgroundTransparency = 0.08
status.BorderSizePixel = 0
status.TextColor3 = COLORS.white
status.TextSize = 17
status.Font = Enum.Font.GothamMedium
status.Text = "Welcome to your base."
status.Parent = gui
corner(status, 10)
outline(status, Color3.fromRGB(116, 135, 163), 1)

local controls = Instance.new("Frame")
controls.Name = "ControlsInstructions"
controls.Size = UDim2.fromOffset(275, 76)
controls.AnchorPoint = Vector2.new(0, 1)
controls.Position = UDim2.new(0, 18, 1, -18)
controls.BackgroundColor3 = COLORS.panel
controls.BackgroundTransparency = 0.08
controls.BorderSizePixel = 0
controls.Parent = gui
corner(controls, 10)
outline(controls, Color3.fromRGB(116, 135, 163), 1)
text(controls, "Heading", "CONTROLS", UDim2.new(1, -20, 0, 24), UDim2.fromOffset(12, 6), 14, COLORS.gold, Enum.Font.GothamBold)
text(controls, "Movement", "WASD  Move     SHIFT  Sprint", UDim2.new(1, -20, 0, 22), UDim2.fromOffset(12, 29), 13, COLORS.white)
text(controls, "Actions", "Use the top buttons for Shop, Spin, Inventory", UDim2.new(1, -20, 0, 20), UDim2.fromOffset(12, 51), 10, COLORS.muted)

local function makePanel(name, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.BackgroundColor3 = COLORS.panel
	panel.BackgroundTransparency = 0.02
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 14)
	outline(panel, COLORS.blue, 2)
	return panel
end

local shopPanel = makePanel("ShopPanel", UDim2.fromOffset(540, 470))
text(shopPanel, "Title", "BASE SHOP", UDim2.new(1, -80, 0, 44), UDim2.fromOffset(22, 16), 25, COLORS.white, Enum.Font.GothamBold)
text(shopPanel, "SubTitle", "Generic placeholder gear • paid with test coins", UDim2.new(1, -44, 0, 26), UDim2.fromOffset(22, 58), 14, COLORS.muted)
local shopClose = button(shopPanel, "Close", "×", UDim2.fromOffset(38, 38), UDim2.new(1, -52, 0, 14), COLORS.panel2)

local shopList = Instance.new("ScrollingFrame")
shopList.Name = "ShopItems"
shopList.Position = UDim2.fromOffset(18, 94)
shopList.Size = UDim2.new(1, -36, 0, 354)
shopList.BackgroundTransparency = 1
shopList.BorderSizePixel = 0
shopList.ScrollBarThickness = 8
shopList.ScrollBarImageColor3 = COLORS.blue
shopList.ScrollingDirection = Enum.ScrollingDirection.Y
shopList.AutomaticCanvasSize = Enum.AutomaticSize.Y
shopList.CanvasSize = UDim2.new(0, 0, 0, 0)
shopList.Parent = shopPanel
local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 6)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopList

local shopItems = {
	{ Name = "Health Potion", Price = 75, Description = "A classic healing item" },
	{ Name = "Speed Coil", Price = 180, Description = "A familiar movement gadget" },
	{ Name = "Lucky Charm", Price = 150, Description = "A shiny luck-themed trinket" },
	{ Name = "Wood Bundle", Price = 100, Description = "Basic building supplies" },
	{ Name = "Gem Pouch", Price = 250, Description = "A pouch of pretend gems" },
	{ Name = "Pet Egg", Price = 300, Description = "A mystery companion egg" },
	{ Name = "Gravity Coil", Price = 220, Description = "A classic jump gadget" },
	{ Name = "Magic Carpet", Price = 350, Description = "A fantasy travel item" },
	{ Name = "Iron Sword", Price = 125, Description = "A basic adventure weapon" },
	{ Name = "Magic Wand", Price = 200, Description = "A simple spell-caster" },
	{ Name = "Rainbow Trail", Price = 275, Description = "A colorful character effect" },
	{ Name = "Mystery Box", Price = 400, Description = "A surprise placeholder item" },
}

for index, item in ipairs(shopItems) do
	local row = Instance.new("Frame")
	row.Name = item.Name:gsub("%s", "") .. "Row"
	row.Size = UDim2.new(1, -10, 0, 52)
	row.LayoutOrder = index
	row.BackgroundColor3 = COLORS.panel2
	row.BorderSizePixel = 0
	row.Parent = shopList
	corner(row, 8)
	text(row, "ItemName", item.Name, UDim2.new(1, -160, 0, 24), UDim2.fromOffset(12, 4), 16, COLORS.white, Enum.Font.GothamBold)
	text(row, "ItemDescription", item.Description, UDim2.new(1, -160, 0, 19), UDim2.fromOffset(12, 28), 12, COLORS.muted)
	local buy = button(row, "Buy", "BUY  " .. item.Price, UDim2.fromOffset(124, 38), UDim2.new(1, -134, 0.5, -19), COLORS.green)
	buy.TextSize = 14
	buy.Activated:Connect(function()
		local ok, purchased, result = pcall(function()
			return shopSpin:InvokeServer("Shop", item.Name)
		end)
		if not ok then
			status.Text = "Shop connection failed. Try again."
		elseif purchased then
			status.Text = result
		else
			status.Text = result or "Purchase failed."
		end
	end)
end

local inventoryPanel = makePanel("InventoryPanel", UDim2.fromOffset(500, 420))
text(inventoryPanel, "Title", "INVENTORY", UDim2.new(1, -80, 0, 44), UDim2.fromOffset(22, 16), 25, COLORS.white, Enum.Font.GothamBold)
text(inventoryPanel, "SubTitle", "Placeholder items you have collected", UDim2.new(1, -44, 0, 26), UDim2.fromOffset(22, 58), 14, COLORS.muted)
local inventoryClose = button(inventoryPanel, "Close", "×", UDim2.fromOffset(38, 38), UDim2.new(1, -52, 0, 14), COLORS.panel2)
local inventoryList = Instance.new("ScrollingFrame")
inventoryList.Name = "InventoryItems"
inventoryList.Position = UDim2.fromOffset(18, 94)
inventoryList.Size = UDim2.new(1, -36, 0, 300)
inventoryList.BackgroundTransparency = 1
inventoryList.BorderSizePixel = 0
inventoryList.ScrollBarThickness = 8
inventoryList.ScrollBarImageColor3 = COLORS.green
inventoryList.ScrollingDirection = Enum.ScrollingDirection.Y
inventoryList.AutomaticCanvasSize = Enum.AutomaticSize.Y
inventoryList.CanvasSize = UDim2.new(0, 0, 0, 0)
inventoryList.Parent = inventoryPanel
local inventoryLayout = Instance.new("UIListLayout")
inventoryLayout.Padding = UDim.new(0, 7)
inventoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
inventoryLayout.Parent = inventoryList

local function refreshInventory()
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then child:Destroy() end
	end
	local folder = player:FindFirstChild("PlaceholderInventory")
	local entries = folder and folder:GetChildren() or {}
	table.sort(entries, function(a, b) return a.Name < b.Name end)
	if #entries == 0 then
		local empty = text(inventoryList, "Empty", "No items yet — try the Shop or Lucky Spin.", UDim2.new(1, -10, 0, 46), UDim2.new(), 15, COLORS.muted)
		empty.BackgroundColor3 = COLORS.panel2
		empty.BackgroundTransparency = 0
		empty.LayoutOrder = 1
		corner(empty, 8)
		return
	end
	for index, entry in ipairs(entries) do
		if entry:IsA("IntValue") then
			local row = Instance.new("Frame")
			row.Name = "InventoryItem"
			row.Size = UDim2.new(1, -10, 0, 48)
			row.BackgroundColor3 = COLORS.panel2
			row.LayoutOrder = index
			row.BorderSizePixel = 0
			corner(row, 8)
			row.Parent = inventoryList
			text(row, "Name", entry.Name, UDim2.new(1, -90, 1, 0), UDim2.fromOffset(14, 0), 16, COLORS.white, Enum.Font.GothamBold)
			local count = text(row, "Count", "× " .. entry.Value, UDim2.fromOffset(72, 48), UDim2.new(1, -84, 0, 0), 16, COLORS.gold, Enum.Font.GothamBold)
			count.TextXAlignment = Enum.TextXAlignment.Right
		end
	end
end

local inventoryFolder = player:WaitForChild("PlaceholderInventory")
inventoryFolder.ChildAdded:Connect(function(item)
	if item:IsA("IntValue") then
		item:GetPropertyChangedSignal("Value"):Connect(refreshInventory)
	end
	refreshInventory()
end)
inventoryFolder.ChildRemoved:Connect(refreshInventory)
inventoryChanged.OnClientEvent:Connect(refreshInventory)
refreshInventory()

local spinPanel = makePanel("SpinPanel", UDim2.fromOffset(590, 330))
text(spinPanel, "Title", "LUCKY SPIN", UDim2.new(1, -80, 0, 42), UDim2.fromOffset(22, 16), 25, COLORS.white, Enum.Font.GothamBold)
text(spinPanel, "SubTitle", "Costs 50 test coins • 12 possible placeholder items", UDim2.new(1, -44, 0, 24), UDim2.fromOffset(22, 56), 14, COLORS.muted)
local spinClose = button(spinPanel, "Close", "×", UDim2.fromOffset(38, 38), UDim2.new(1, -52, 0, 14), COLORS.panel2)

local viewport = Instance.new("Frame")
viewport.Name = "SpinViewport"
viewport.ClipsDescendants = true
viewport.Size = UDim2.new(1, -44, 0, 104)
viewport.Position = UDim2.fromOffset(22, 96)
viewport.BackgroundColor3 = Color3.fromRGB(18, 22, 31)
viewport.BorderSizePixel = 0
viewport.Parent = spinPanel
corner(viewport, 10)

local marker = Instance.new("Frame")
marker.Name = "WinnerMarker"
marker.Size = UDim2.new(0, 5, 1, -8)
marker.Position = UDim2.new(0.5, -2, 0, 4)
marker.BackgroundColor3 = COLORS.gold
marker.BorderSizePixel = 0
marker.ZIndex = 3
marker.Parent = viewport
corner(marker, 3)

local strip = Instance.new("Frame")
strip.Name = "ItemStrip"
strip.Size = UDim2.fromOffset(2000, 84)
strip.Position = UDim2.fromOffset(0, 10)
strip.BackgroundTransparency = 1
strip.Parent = viewport
local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.Padding = UDim.new(0, 8)
layout.Parent = strip

local spinButton = button(spinPanel, "SpinButton", "SPIN  •  50 COINS", UDim2.fromOffset(230, 48), UDim2.new(0.5, -115, 1, -68), Color3.fromRGB(164, 107, 236))
local isSpinning = false
local spinItems = {
	"Health Potion", "Speed Coil", "Lucky Charm", "Wood Bundle", "Gem Pouch", "Pet Egg",
	"Iron Sword", "Magic Wand", "Shield", "Grapple Hook", "Rainbow Trail", "Mystery Box",
}

local function playSpin(winner)
	for _, child in ipairs(strip:GetChildren()) do
		if child:IsA("TextLabel") then child:Destroy() end
	end
	strip.Position = UDim2.fromOffset(0, 10)
	local random = Random.new()
	for index = 1, 15 do
		local itemName = index == 15 and winner or spinItems[random:NextInteger(1, #spinItems)]
		local card = Instance.new("TextLabel")
		card.Name = "SpinItem" .. index
		card.LayoutOrder = index
		card.Size = UDim2.fromOffset(112, 76)
		card.BackgroundColor3 = index == 15 and Color3.fromRGB(93, 73, 45) or COLORS.panel2
		card.BorderSizePixel = 0
		card.Text = itemName
		card.TextWrapped = true
		card.TextColor3 = index == 15 and COLORS.gold or COLORS.white
		card.TextSize = 14
		card.Font = Enum.Font.GothamBold
		card.Parent = strip
		corner(card, 8)
	end
	-- Fifteen text cards pass the center marker; the server-selected prize stops under it.
	local targetX = -(14 * 120 + 56 - viewport.AbsoluteSize.X / 2)
	local tween = TweenService:Create(strip, TweenInfo.new(4.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
		Position = UDim2.fromOffset(targetX, 10),
	})
	tween:Play()
	tween.Completed:Wait()
end

spinButton.Activated:Connect(function()
	if isSpinning then return end
	isSpinning = true
	spinButton.Text = "SPINNING..."
	spinButton.Active = false
	local ok, success, prize, count = pcall(function()
		return shopSpin:InvokeServer("Spin")
	end)
	if not ok then
		status.Text = "Spin connection failed. Try again."
	elseif not success then
		status.Text = prize or "Spin failed."
	else
		playSpin(prize)
		status.Text = "Won " .. prize .. "! Inventory count: " .. tostring(count)
	end
	spinButton.Text = "SPIN  •  50 COINS"
	spinButton.Active = true
	isSpinning = false
end)

local function setOpen(panel, ...)
	local opening = not panel.Visible
	panel.Visible = opening
	for _, other in ipairs({ ... }) do other.Visible = false end
end

shopToggle.Activated:Connect(function() setOpen(shopPanel, spinPanel, inventoryPanel) end)
spinToggle.Activated:Connect(function() setOpen(spinPanel, shopPanel, inventoryPanel) end)
inventoryToggle.Activated:Connect(function() setOpen(inventoryPanel, shopPanel, spinPanel) end)
shopClose.Activated:Connect(function() shopPanel.Visible = false end)
spinClose.Activated:Connect(function() spinPanel.Visible = false end)
inventoryClose.Activated:Connect(function() inventoryPanel.Visible = false end)

local function connectWallet()
	local stats = player:WaitForChild("leaderstats", 15)
	local coins = stats and stats:WaitForChild("Coins", 15)
	if coins then
		local function update() coinText.Text = "Coins: " .. tostring(coins.Value) end
		update()
		coins:GetPropertyChangedSignal("Value"):Connect(update)
	end
end
task.spawn(connectWallet)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		gameAction:FireServer("Sprint", true)
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		gameAction:FireServer("Sprint", false)
	end
end)
UserInputService.WindowFocusReleased:Connect(function()
	gameAction:FireServer("Sprint", false)
end)

-- Conveyor physics is applied locally to the owning character so the moving
-- platform feels immediate; the resulting character motion replicates normally.
local map = workspace:WaitForChild("GeneratedBeingsMap")
local conveyor = map:WaitForChild("Looping Conveyor")
local beltRayParams = RaycastParams.new()
beltRayParams.FilterType = Enum.RaycastFilterType.Include
beltRayParams.FilterDescendantsInstances = { conveyor }
beltRayParams.IgnoreWater = true
local halfX, halfZ = 42, 32
local beltSpeed = 8

RunService.Heartbeat:Connect(function()
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end
	local hit = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -7, 0), beltRayParams)
	if not hit or hit.Instance.Name ~= "Conveyor Surface" then return end

	local x, z = root.Position.X, root.Position.Z
	local edges = {
		{ Distance = math.abs(z + halfZ), Direction = Vector3.new(1, 0, 0) },
		{ Distance = math.abs(x - halfX), Direction = Vector3.new(0, 0, 1) },
		{ Distance = math.abs(z - halfZ), Direction = Vector3.new(-1, 0, 0) },
		{ Distance = math.abs(x + halfX), Direction = Vector3.new(0, 0, -1) },
	}
	local edge = edges[1]
	for _, candidate in ipairs(edges) do
		if candidate.Distance < edge.Distance then edge = candidate end
	end
	local walking = humanoid.MoveDirection * humanoid.WalkSpeed
	local currentY = root.AssemblyLinearVelocity.Y
	root.AssemblyLinearVelocity = Vector3.new(walking.X + edge.Direction.X * beltSpeed, currentY, walking.Z + edge.Direction.Z * beltSpeed)
end)
