local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local actionEvent = remotes:WaitForChild("Action")
local stateFunction = remotes:WaitForChild("GetState")
local notifyEvent = remotes:WaitForChild("Notify")

local gui = Instance.new("ScreenGui")
gui.Name = "GeneratedBeingsHUD"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local function make(className, props, parent)
	local object = Instance.new(className)
	for key, value in pairs(props) do object[key] = value end
	object.Parent = parent
	return object
end

local function stylePanel(frame)
	frame.BackgroundColor3 = Color3.fromRGB(24, 27, 38)
	frame.BackgroundTransparency = 0.12
	make("UICorner", {CornerRadius = UDim.new(0, 10)}, frame)
	make("UIStroke", {Color = Color3.fromRGB(87, 175, 224), Transparency = 0.45, Thickness = 1}, frame)
end

local function button(parent, text, size, position, callback)
	local b = make("TextButton", {
		Text = text, Size = size, Position = position,
		BackgroundColor3 = Color3.fromRGB(52, 66, 91), TextColor3 = Color3.new(1, 1, 1),
		TextSize = 14, Font = Enum.Font.GothamSemibold, AutoButtonColor = true,
		TextWrapped = true,
	}, parent)
	make("UICorner", {CornerRadius = UDim.new(0, 7)}, b)
	b.Activated:Connect(callback)
	return b
end

local top = make("Frame", {Name="TopBar", Size=UDim2.fromOffset(480, 74), Position=UDim2.new(0, 16, 0, 16)}, gui)
stylePanel(top)
make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(14, 5), Size=UDim2.new(1, -28, 0, 28), Font=Enum.Font.GothamBold, Text="GENERATED BEINGS  |  CO-OP PROTOTYPE", TextColor3=Color3.fromRGB(170, 225, 255), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, top)
local stats = make("TextLabel", {Name="Stats", BackgroundTransparency=1, Position=UDim2.fromOffset(14, 36), Size=UDim2.new(1, -28, 0, 24), Font=Enum.Font.GothamMedium, Text="Loading…", TextColor3=Color3.new(1,1,1), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, top)

local rosterPanel = make("Frame", {Name="BaseRoster", Size=UDim2.fromOffset(370, 340), Position=UDim2.new(0, 16, 0, 102), Visible=false}, gui)
stylePanel(rosterPanel)
local rosterHeader = make("TextLabel", {Name="Header", BackgroundTransparency=1, Position=UDim2.fromOffset(14, 8), Size=UDim2.new(1,-28,0,28), Font=Enum.Font.GothamBold, Text="BASE ROSTER  •  Assign workers or absorb abilities", TextColor3=Color3.fromRGB(170,225,255), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, rosterPanel)
button(rosterPanel, "×", UDim2.fromOffset(30, 28), UDim2.new(1,-40,0,7), function() rosterPanel.Visible=false end)
local list = make("ScrollingFrame", {Name="RosterList", BackgroundTransparency=1, BorderSizePixel=0, Position=UDim2.fromOffset(10, 42), Size=UDim2.new(1,-20,1,-100), CanvasSize=UDim2.new(), AutomaticCanvasSize=Enum.AutomaticSize.Y, ScrollBarThickness=5}, rosterPanel)
make("UIListLayout", {Padding=UDim.new(0,6), SortOrder=Enum.SortOrder.LayoutOrder}, list)
local recruitButton = button(rosterPanel, "Roll Being", UDim2.new(1,-20,0,42), UDim2.new(0,10,1,-50), function() actionEvent:FireServer("Recruit") end)
button(gui, "BASE / ROSTER", UDim2.fromOffset(145, 38), UDim2.new(1,-160,0,18), function() rosterPanel.Visible = not rosterPanel.Visible end)

local devPanel = make("Frame", {Name="StudioDevPanel", Size=UDim2.fromOffset(310, 104), Position=UDim2.new(1,-16,0,64), AnchorPoint=Vector2.new(1,0), Visible=false}, gui)
stylePanel(devPanel)
make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(12,6), Size=UDim2.new(1,-24,0,24), Font=Enum.Font.GothamBold, Text="STUDIO DEV MODE", TextColor3=Color3.fromRGB(255,205,120), TextSize=14, TextXAlignment=Enum.TextXAlignment.Left}, devPanel)
button(devPanel, "Grant 5,000 coins + building materials", UDim2.new(1,-20,0,40), UDim2.fromOffset(10,40), function()
	actionEvent:FireServer("DevGrant", "BuildPack")
end)
local devButton = button(gui, "DEV", UDim2.fromOffset(64,38), UDim2.new(1,-480,0,18), function()
	devPanel.Visible = not devPanel.Visible
end)
devButton.Visible = false

local sprinting = false
local sprintButton
local function setSprintVisual(active)
	sprinting = active
	sprintButton.Text = sprinting and "SPRINT ON" or "SPRINT OFF"
	sprintButton.BackgroundColor3 = sprinting and Color3.fromRGB(46, 132, 103) or Color3.fromRGB(52, 66, 91)
end
sprintButton = button(gui, "SPRINT OFF", UDim2.fromOffset(112, 46), UDim2.new(1,-16,1,-82), function()
	sprinting = not sprinting
	actionEvent:FireServer("Sprint", sprinting)
	setSprintVisual(sprinting)
end)
sprintButton.AnchorPoint = Vector2.new(1, 1)

local actionFrame = make("Frame", {Name="Actions", BackgroundTransparency=1, AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-18), Size=UDim2.new(0.96,0,0,54)}, gui)
make("UIGridLayout", {CellPadding=UDim2.fromOffset(3,0), CellSize=UDim2.new(1/7,-3,1,0), FillDirection=Enum.FillDirection.Horizontal, SortOrder=Enum.SortOrder.LayoutOrder}, actionFrame)
local actionButtons = {
	{"BASIC", "Attack", "Light"}, {"HEAVY", "Attack", "Heavy"}, {"DASH", "Dash"}, {"MOVE", "Movement"},
	{"SPECIAL 1", "Ability", 1}, {"SPECIAL 2", "Ability", 2}, {"ULTIMATE", "Ultimate"},
}
for i, entry in ipairs(actionButtons) do
	local actionButton = button(actionFrame, entry[1], UDim2.new(1,0,1,0), UDim2.new(), function()
		if entry[2] == "Ability" then
			local state = stateFunction:InvokeServer()
			if state and state.Learned[entry[3]] then actionEvent:FireServer("Ability", state.Learned[entry[3]]) end
		else
			actionEvent:FireServer(entry[2], entry[3])
		end
	end)
	actionButton.LayoutOrder = i
end

local toast = make("TextLabel", {Name="Toast", BackgroundColor3=Color3.fromRGB(20,23,32), BackgroundTransparency=0.12, AnchorPoint=Vector2.new(0.5,1), Position=UDim2.new(0.5,0,1,-82), Size=UDim2.fromOffset(440,34), Font=Enum.Font.GothamSemibold, Text="", TextColor3=Color3.new(1,1,1), TextSize=14, Visible=false}, gui)
make("UICorner", {CornerRadius=UDim.new(0,8)}, toast)

local function refreshRoster()
	for _, child in ipairs(list:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
	local state = stateFunction:InvokeServer()
	if not state then return end
	if state.RecruitCost then recruitButton.Text = string.format("Roll Being — %d coins", state.RecruitCost) end
	devButton.Visible = state.DevMode == true
	if state.Workers and state.WorkerSlots then rosterHeader.Text = string.format("CHARACTER STANDS  •  %d/%d workers", state.Workers, state.WorkerSlots) end
	for index, character in ipairs(state.Roster) do
		local row = make("Frame", {Size=UDim2.new(1,-5,0,94), BackgroundColor3=Color3.fromRGB(37,43,58), LayoutOrder=index}, list)
		make("UICorner", {CornerRadius=UDim.new(0,7)}, row)
		local status = character.Assigned and "BASE WORKER" or "RESERVE"
		make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(9,5), Size=UDim2.new(1,-18,0,20), Font=Enum.Font.GothamBold, Text=character.Name.."  •  "..character.Title.."  •  "..status, TextColor3=Color3.fromRGB(255,225,165), TextSize=13, TextXAlignment=Enum.TextXAlignment.Left}, row)
		make("TextLabel", {BackgroundTransparency=1, Position=UDim2.fromOffset(9,28), Size=UDim2.new(1,-18,0,17), Font=Enum.Font.Gotham, Text=string.format("%s • %s • +%d coins/tick", character.Rarity or "Common", character.Ability, character.Income or 5), TextColor3=Color3.new(1,1,1), TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, row)
		button(row, character.Assigned and "Unassign" or "Assign", UDim2.fromOffset(92,32), UDim2.new(0,9,1,-38), function() actionEvent:FireServer("Assign", index) end)
		button(row, "Absorb", UDim2.fromOffset(92,32), UDim2.new(0,108,1,-38), function() actionEvent:FireServer("Absorb", index) end)
	end
	local skills = #state.Learned > 0 and table.concat(state.Learned, ", ") or "none"
	local previousSkills = rosterPanel:FindFirstChild("Learned")
	if previousSkills then previousSkills:Destroy() end
	make("TextLabel", {Name="Learned", BackgroundTransparency=1, Position=UDim2.new(0,10,1,-79), Size=UDim2.new(1,-20,0,22), Font=Enum.Font.Gotham, Text="Absorbed abilities: "..skills, TextColor3=Color3.fromRGB(180,230,255), TextSize=12, TextXAlignment=Enum.TextXAlignment.Left}, rosterPanel)
end

local function updateStats()
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	local coins, wood, stone, essence = leaderstats:FindFirstChild("Coins"), leaderstats:FindFirstChild("Wood"), leaderstats:FindFirstChild("Stone"), leaderstats:FindFirstChild("Shards")
	if coins then stats.Text = string.format("Coins: %d   Wood: %d   Stone: %d   Essence: %d", coins.Value, wood and wood.Value or 0, stone and stone.Value or 0, essence and essence.Value or 0) end
end

local toastToken = 0
notifyEvent.OnClientEvent:Connect(function(message)
	toastToken += 1
	local token = toastToken
	toast.Text = message
	toast.Visible = true
	task.delay(3, function() if token == toastToken then toast.Visible=false end end)
	if rosterPanel.Visible then refreshRoster() end
end)
actionEvent.OnClientEvent:Connect(function(message, value)
	if message == "Refresh" then refreshRoster() end
	if message == "SprintState" then
		setSprintVisual(value == true)
	end
end)

player.CharacterAdded:Connect(function()
	setSprintVisual(false)
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then actionEvent:FireServer("Attack", "Light") end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then actionEvent:FireServer("Attack", "Heavy") end
	if input.KeyCode == Enum.KeyCode.LeftShift then actionEvent:FireServer("Dash") end
	if input.KeyCode == Enum.KeyCode.LeftControl then
		sprinting = not sprinting
		actionEvent:FireServer("Sprint", sprinting)
		setSprintVisual(sprinting)
	end
	if input.KeyCode == Enum.KeyCode.C then actionEvent:FireServer("Movement") end
	if input.KeyCode == Enum.KeyCode.R then actionEvent:FireServer("Ultimate") end
	if input.KeyCode == Enum.KeyCode.B then rosterPanel.Visible = not rosterPanel.Visible end
	if input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.E then
		local state = stateFunction:InvokeServer()
		local slot = input.KeyCode == Enum.KeyCode.Q and 1 or 2
		if state and state.Learned[slot] then actionEvent:FireServer("Ability", state.Learned[slot]) end
	end
end)

local function bindStats()
	local leaderstats = player:WaitForChild("leaderstats", 15)
	if not leaderstats then return end
	for _, stat in ipairs(leaderstats:GetChildren()) do stat.Changed:Connect(updateStats) end
	leaderstats.ChildAdded:Connect(function(stat) stat.Changed:Connect(updateStats); updateStats() end)
	updateStats()
end

task.spawn(bindStats)
task.spawn(function()
	while true do
		if rosterPanel.Visible then refreshRoster() end
		task.wait(10)
	end
end)

refreshRoster()
