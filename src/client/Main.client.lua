-- Compact starter UI for the shared base demo.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("DemoRemotes")
local gameAction = remotes:WaitForChild("GameAction")
local shopSpin = remotes:WaitForChild("ShopSpin")
local inventoryChanged = remotes:WaitForChild("InventoryChanged")

local COLORS = {
	panel = Color3.fromRGB(38, 30, 23),
	panel2 = Color3.fromRGB(73, 51, 33),
	blue = Color3.fromRGB(90, 163, 245),
	green = Color3.fromRGB(84, 216, 72),
	gold = Color3.fromRGB(255, 198, 45),
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
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.55
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
	item.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	item.TextStrokeTransparency = 0.35
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

task.spawn(function()
	while true do
		local ok = pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		if ok then break end
		task.wait(0.25)
	end
end)

local wallet = Instance.new("Frame")
wallet.Name = "Wallet"
wallet.Size = UDim2.fromOffset(170, 42)
wallet.AnchorPoint = Vector2.new(1, 0)
wallet.Position = UDim2.new(1, -12, 0, 6)
wallet.BackgroundTransparency = 1
wallet.BorderSizePixel = 0
wallet.Parent = gui
local coinIcon = Instance.new("Frame")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.fromOffset(30, 30)
coinIcon.Position = UDim2.fromOffset(0, 5)
coinIcon.BackgroundColor3 = Color3.fromRGB(255, 198, 45)
coinIcon.BorderSizePixel = 0
coinIcon.Parent = wallet
corner(coinIcon, 15)
outline(coinIcon, Color3.fromRGB(80, 54, 14), 2)
local coinGlyph = text(coinIcon, "Glyph", "$", UDim2.fromScale(1, 1), UDim2.new(), 19, Color3.fromRGB(89, 57, 9), Enum.Font.GothamBlack)
coinGlyph.TextXAlignment = Enum.TextXAlignment.Center
local coinText = text(wallet, "Coins", "500", UDim2.new(1, -38, 1, 0), UDim2.fromOffset(38, 0), 22, Color3.fromRGB(111, 255, 87), Enum.Font.GothamBlack)
coinText.TextStrokeColor3 = Color3.fromRGB(14, 35, 8)
coinText.TextStrokeTransparency = 0.1
coinText.TextXAlignment = Enum.TextXAlignment.Left

local inventoryToggle = button(gui, "InventoryToggle", "", UDim2.fromOffset(50, 50), UDim2.new(0, 18, 0, 18), COLORS.panel2)
corner(inventoryToggle, 14)
local backpackBody = Instance.new("Frame")
backpackBody.Size = UDim2.fromOffset(24, 25)
backpackBody.Position = UDim2.fromOffset(13, 16)
backpackBody.BackgroundColor3 = Color3.fromRGB(45, 139, 247)
backpackBody.BorderSizePixel = 0
backpackBody.Parent = inventoryToggle
corner(backpackBody, 6)
local backpackTop = Instance.new("Frame")
backpackTop.Size = UDim2.fromOffset(16, 7)
backpackTop.Position = UDim2.fromOffset(17, 11)
backpackTop.BackgroundColor3 = Color3.fromRGB(255, 190, 49)
backpackTop.BorderSizePixel = 0
backpackTop.Parent = inventoryToggle
corner(backpackTop, 4)
local backpackPocket = Instance.new("Frame")
backpackPocket.Size = UDim2.fromOffset(16, 9)
backpackPocket.Position = UDim2.fromOffset(17, 27)
backpackPocket.BackgroundColor3 = Color3.fromRGB(27, 101, 205)
backpackPocket.BorderSizePixel = 0
backpackPocket.Parent = inventoryToggle
corner(backpackPocket, 3)

local shopToggle = button(gui, "ShopToggle", "SHOP", UDim2.fromOffset(112, 46), UDim2.new(0, 18, 0, 82), Color3.fromRGB(59, 155, 62))
local spinToggle = button(gui, "SpinToggle", "SPIN", UDim2.fromOffset(210, 32), UDim2.new(0.5, 0, 1, -68), Color3.fromRGB(255, 255, 255))
spinToggle.AnchorPoint = Vector2.new(0.5, 1)
spinToggle.TextColor3 = Color3.fromRGB(20, 20, 20)
spinToggle.TextStrokeTransparency = 1

local status = Instance.new("TextLabel")
status.Name = "Status"
status.Size = UDim2.fromOffset(500, 42)
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 1, -122)
status.BackgroundTransparency = 1
status.BorderSizePixel = 0
status.TextColor3 = COLORS.white
status.TextSize = 17
status.Font = Enum.Font.GothamMedium
status.Text = "Welcome to your base."
status.Parent = gui
status.TextStrokeColor3 = Color3.fromRGB(24, 24, 24)
status.TextStrokeTransparency = 0.15

local controls = Instance.new("TextLabel")
controls.Name = "ControlsInstructions"
controls.Size = UDim2.fromOffset(250, 38)
controls.AnchorPoint = Vector2.new(0, 1)
controls.Position = UDim2.new(0, 18, 1, -18)
controls.BackgroundTransparency = 1
controls.BorderSizePixel = 0
controls.Text = "WASD  Move     SHIFT  Sprint"
controls.TextColor3 = COLORS.white
controls.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
controls.TextStrokeTransparency = 0.2
controls.TextSize = 13
controls.Font = Enum.Font.GothamMedium
controls.TextXAlignment = Enum.TextXAlignment.Left
controls.TextYAlignment = Enum.TextYAlignment.Bottom
controls.Parent = gui

local function makePanel(name, size)
	local panel = Instance.new("Frame")
	panel.Name = name
	panel.Size = size
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.53)
	panel.BackgroundColor3 = COLORS.panel
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.Parent = gui
	corner(panel, 14)
	outline(panel, COLORS.gold, 1.5)
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
shopList.Active = true
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
inventoryList.Active = true
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

local hotbar = Instance.new("Frame")
hotbar.Name = "Hotbar"
hotbar.Size = UDim2.fromOffset(454, 46)
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 1, -12)
hotbar.BackgroundTransparency = 1
hotbar.Parent = gui
local hotbarNames = table.create(9)
local hotbarButtons = {}
local selectedHotbar = 1

local function redrawHotbar()
	for index, slot in ipairs(hotbarButtons) do
		slot.Text = tostring(index) .. "\n" .. (hotbarNames[index] or "")
		slot.UIStroke.Color = index == selectedHotbar and COLORS.gold or Color3.fromRGB(16, 16, 16)
		slot.UIStroke.Thickness = index == selectedHotbar and 2.5 or 1.5
	end
end

for index = 1, 9 do
	local slot = button(hotbar, "HotbarSlot" .. index, tostring(index), UDim2.fromOffset(46, 46), UDim2.fromOffset((index - 1) * 51, 0), COLORS.panel2)
	slot.BackgroundTransparency = 0.18
	slot.TextSize = 10
	slot.TextWrapped = true
	slot.TextYAlignment = Enum.TextYAlignment.Center
	local stroke = Instance.new("UIStroke")
	stroke.Name = "UIStroke"
	stroke.Color = index == selectedHotbar and COLORS.gold or Color3.fromRGB(16, 16, 16)
	stroke.Thickness = index == selectedHotbar and 2.5 or 1.5
	stroke.Parent = slot
	table.insert(hotbarButtons, slot)
	slot.Activated:Connect(function()
		selectedHotbar = index
		redrawHotbar()
		if hotbarNames[index] then status.Text = "Selected " .. hotbarNames[index] .. " (placeholder item)." end
	end)
end

local function refreshInventory()
	for _, child in ipairs(inventoryList:GetChildren()) do
		if child:IsA("TextLabel") or child:IsA("Frame") then child:Destroy() end
	end
	local folder = player:FindFirstChild("PlaceholderInventory")
	local entries = folder and folder:GetChildren() or {}
	table.sort(entries, function(a, b) return a.Name < b.Name end)
	for _, entry in ipairs(entries) do
		if entry:IsA("IntValue") then
			local alreadyAssigned = false
			for slotIndex = 1, 9 do
				if hotbarNames[slotIndex] == entry.Name then alreadyAssigned = true; break end
			end
			if not alreadyAssigned then
				for slotIndex = 1, 9 do
					if not hotbarNames[slotIndex] then hotbarNames[slotIndex] = entry.Name; break end
				end
			end
		end
	end
	redrawHotbar()
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
			text(row, "Name", entry.Name, UDim2.new(1, -230, 1, 0), UDim2.fromOffset(14, 0), 15, COLORS.white, Enum.Font.GothamBold)
			local count = text(row, "Count", "× " .. entry.Value, UDim2.fromOffset(50, 48), UDim2.new(1, -150, 0, 0), 15, COLORS.gold, Enum.Font.GothamBold)
			count.TextXAlignment = Enum.TextXAlignment.Right
			local equip = button(row, "AddToHotbar", "TO BAR", UDim2.fromOffset(82, 34), UDim2.new(1, -94, 0.5, -17), COLORS.green)
			equip.TextSize = 12
			equip.Activated:Connect(function()
				hotbarNames[selectedHotbar] = entry.Name
				redrawHotbar()
				status.Text = entry.Name .. " assigned to hotbar slot " .. selectedHotbar .. "."
			end)
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
		local function update() coinText.Text = tostring(coins.Value) end
		update()
		coins:GetPropertyChangedSignal("Value"):Connect(update)
	end
end
task.spawn(connectWallet)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		gameAction:FireServer("Sprint", true)
		return
	end
	local numberKeys = {
		Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three,
		Enum.KeyCode.Four, Enum.KeyCode.Five, Enum.KeyCode.Six,
		Enum.KeyCode.Seven, Enum.KeyCode.Eight, Enum.KeyCode.Nine,
	}
	for slotIndex, keyCode in ipairs(numberKeys) do
		if input.KeyCode == keyCode then
			selectedHotbar = slotIndex
			redrawHotbar()
			if hotbarNames[slotIndex] then status.Text = "Selected " .. hotbarNames[slotIndex] .. " (placeholder item)." end
			break
		end
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
local halfX, halfZ = 42, 32
local cornerRadius = 6
local straightX = (halfX - cornerRadius) * 2
local straightZ = (halfZ - cornerRadius) * 2
local arcLength = math.pi * cornerRadius / 2
local perimeter = (straightX + straightZ) * 2 + arcLength * 4
local beltSpeed = conveyor:GetAttribute("BeltSpeed") or 24
local beltCount = conveyor:GetAttribute("TreadCount")
while not beltCount do
	task.wait()
	beltCount = conveyor:GetAttribute("TreadCount")
end
local function collectTreads()
	local found = {}
	for _, child in ipairs(conveyor:GetChildren()) do
		if child.Name == "Moving Belt" and type(child:GetAttribute("TrackIndex")) == "number" then
			table.insert(found, child)
		end
	end
	if #found < beltCount then return nil end
	table.sort(found, function(a, b) return a:GetAttribute("TrackIndex") < b:GetAttribute("TrackIndex") end)
	return found
end
local treads = collectTreads()
while not treads do
	task.wait()
	treads = collectTreads()
end
local conveyorEpoch = conveyor:GetAttribute("ConveyorEpoch") or workspace:GetServerTimeNow()
local beltRayParams = RaycastParams.new()
beltRayParams.FilterType = Enum.RaycastFilterType.Include
beltRayParams.FilterDescendantsInstances = { conveyor }
beltRayParams.IgnoreWater = true

local function pointOnLoop(distance)
	distance %= perimeter
	local function arc(centerX, centerZ, startAngle, progress)
		local angle = startAngle + progress / cornerRadius
		local radialX, radialZ = math.cos(angle), math.sin(angle)
		return Vector3.new(centerX + radialX * cornerRadius, 0.36, centerZ + radialZ * cornerRadius), Vector3.new(-radialZ, 0, radialX)
	end
	if distance < straightX then
		return Vector3.new(-halfX + cornerRadius + distance, 0.36, -halfZ), Vector3.new(1, 0, 0)
	end
	distance -= straightX
	if distance < arcLength then return arc(halfX - cornerRadius, -halfZ + cornerRadius, -math.pi / 2, distance) end
	distance -= arcLength
	if distance < straightZ then
		return Vector3.new(halfX, 0.36, -halfZ + cornerRadius + distance), Vector3.new(0, 0, 1)
	end
	distance -= straightZ
	if distance < arcLength then return arc(halfX - cornerRadius, halfZ - cornerRadius, 0, distance) end
	distance -= arcLength
	if distance < straightX then
		return Vector3.new(halfX - cornerRadius - distance, 0.36, halfZ), Vector3.new(-1, 0, 0)
	end
	distance -= straightX
	if distance < arcLength then return arc(-halfX + cornerRadius, halfZ - cornerRadius, math.pi / 2, distance) end
	distance -= arcLength
	if distance < straightZ then
		return Vector3.new(-halfX, 0.36, halfZ - cornerRadius - distance), Vector3.new(0, 0, -1)
	end
	distance -= straightZ
	return arc(-halfX + cornerRadius, -halfZ + cornerRadius, math.pi, distance)
end

local function tangentAt(x, z)
	local radius = cornerRadius
	local centerX, centerZ
	if x > halfX - radius and z < -halfZ + radius then
		centerX, centerZ = halfX - radius, -halfZ + radius
	elseif x > halfX - radius and z > halfZ - radius then
		centerX, centerZ = halfX - radius, halfZ - radius
	elseif x < -halfX + radius and z > halfZ - radius then
		centerX, centerZ = -halfX + radius, halfZ - radius
	elseif x < -halfX + radius and z < -halfZ + radius then
		centerX, centerZ = -halfX + radius, -halfZ + radius
	end
	if centerX then
		local radial = Vector2.new(x - centerX, z - centerZ)
		if radial.Magnitude > 0 then
			local unit = radial.Unit
			return Vector3.new(-unit.Y, 0, unit.X)
		end
	end
	if z < -halfZ + radius then return Vector3.new(1, 0, 0) end
	if x > halfX - radius then return Vector3.new(0, 0, 1) end
	if z > halfZ - radius then return Vector3.new(-1, 0, 0) end
	return Vector3.new(0, 0, -1)
end

RunService.Heartbeat:Connect(function(deltaTime)
	local elapsed = workspace:GetServerTimeNow() - conveyorEpoch
	for index, tread in ipairs(treads) do
		if tread.Parent then
			local distance = ((index - 1) * (perimeter / beltCount) + elapsed * beltSpeed) % perimeter
			local position, direction = pointOnLoop(distance)
			tread.CFrame = CFrame.lookAt(position, position + direction)
		end
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root or humanoid.Health <= 0 then return end
	local hit = workspace:Raycast(root.Position + Vector3.new(0, 1, 0), Vector3.new(0, -7, 0), beltRayParams)
	if not hit or hit.Instance.Name ~= "Conveyor Surface" then return end

	local direction = tangentAt(root.Position.X, root.Position.Z)
	-- Translate the character a small step with each tread update. Setting only
	-- velocity gets cancelled by Roblox's idle humanoid controller, making the
	-- character run in place instead of being carried with the belt.
	local carryStep = direction * beltSpeed * deltaTime
	root.CFrame = root.CFrame + carryStep
end)
