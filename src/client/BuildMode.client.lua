-- BuildMode: the client side of the base builder.
--   B / V      open / close the build panel
--   E / click  place the selected building  |  X stops placement
-- The server validates everything; this script only previews placement and sends requests.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local actionEvent = remotes:WaitForChild("Action")
local baseStateFunction = remotes:WaitForChild("GetBaseState")

local world = workspace:WaitForChild("DemoWorld")
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Include
raycastParams.FilterDescendantsInstances = { world:WaitForChild("Floor"), world:WaitForChild("PlotPads") }

local GROUND_Y = 0.3
local GOOD = Color3.fromRGB(80, 255, 140)
local BAD = Color3.fromRGB(255, 80, 80)

-- ---------------------------------------------------------------------------
-- UI helpers (same look as the main HUD)
-- ---------------------------------------------------------------------------

local gui = Instance.new("ScreenGui")
gui.Name = "BuilderHUD"
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
	make("UICorner", { CornerRadius = UDim.new(0, 10) }, frame)
	make("UIStroke", { Color = Color3.fromRGB(170, 110, 255), Transparency = 0.4, Thickness = 1 }, frame)
end

local function button(parent, text, size, position, callback)
	local b = make("TextButton", {
		Text = text, Size = size, Position = position,
		BackgroundColor3 = Color3.fromRGB(52, 66, 91), TextColor3 = Color3.new(1, 1, 1),
		TextSize = 13, Font = Enum.Font.GothamSemibold, AutoButtonColor = true, TextWrapped = true,
	}, parent)
	make("UICorner", { CornerRadius = UDim.new(0, 7) }, b)
	b.Activated:Connect(callback)
	return b
end

local function disable(b, text)
	b.Text = text
	b.Active = false
	b.AutoButtonColor = false
	b.BackgroundColor3 = Color3.fromRGB(40, 44, 56)
	b.TextColor3 = Color3.fromRGB(140, 146, 160)
end

-- ---------------------------------------------------------------------------
-- State
-- ---------------------------------------------------------------------------

local state = nil -- latest base state from the server
local placing = nil -- building id being placed
local ghost, zone = nil, nil
local ghostCell, ghostOk = { X = 0, Z = 0 }, false
local pointer = nil -- last touch position

local panel, list, summary, placeBar, placeLabel
local rebuildPanel, enterPlacing, exitPlacing

local function resources()
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	local shards = stats and stats:FindFirstChild("Shards")
	local wood = stats and stats:FindFirstChild("Wood")
	local stone = stats and stats:FindFirstChild("Stone")
	return { Coins = coins and coins.Value or 0, Shards = shards and shards.Value or 0, Wood = wood and wood.Value or 0, Stone = stone and stone.Value or 0 }
end

local function canAfford(cost)
	local owned = resources()
	for resource, amount in pairs(cost) do
		if (owned[resource] or 0) < amount then return false end
	end
	return true
end

local function costText(cost)
	local parts = {}
	if cost.Coins > 0 then table.insert(parts, cost.Coins .. " coins") end
	if cost.Wood > 0 then table.insert(parts, cost.Wood .. " wood") end
	if cost.Stone > 0 then table.insert(parts, cost.Stone .. " stone") end
	if cost.Shards > 0 then table.insert(parts, cost.Shards .. " essence") end
	return #parts > 0 and table.concat(parts, " + ") or "free"
end

local function refreshState()
	local ok, result = pcall(function() return baseStateFunction:InvokeServer() end)
	if ok and result then state = result end
	if rebuildPanel then rebuildPanel() end
	return state
end

-- ---------------------------------------------------------------------------
-- Build panel
-- ---------------------------------------------------------------------------

panel = make("Frame", { Name = "BuilderPanel", Size = UDim2.fromOffset(400, 450), Position = UDim2.new(0.5, -200, 0, 92), Visible = false }, gui)
stylePanel(panel)
make("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -60, 0, 24),
	Font = Enum.Font.GothamBold, Text = "MY BASE", TextColor3 = Color3.fromRGB(205, 175, 255),
	TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, panel)
button(panel, "×", UDim2.fromOffset(30, 28), UDim2.new(1, -40, 0, 7), function() panel.Visible = false end)
summary = make("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(14, 34), Size = UDim2.new(1, -28, 0, 34),
	Font = Enum.Font.Gotham, Text = "Loading…", TextColor3 = Color3.fromRGB(180, 230, 255),
	TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, panel)
list = make("ScrollingFrame", {
	BackgroundTransparency = 1, BorderSizePixel = 0, Position = UDim2.fromOffset(10, 76), Size = UDim2.new(1, -20, 1, -86),
	CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 5,
}, panel)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

local function addHeader(text, order)
	make("TextLabel", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -5, 0, 22), LayoutOrder = order,
		Font = Enum.Font.GothamBold, Text = text, TextColor3 = Color3.fromRGB(255, 225, 165),
		TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
	}, list)
end

local function addRow(order, height)
	local row = make("Frame", { Size = UDim2.new(1, -5, 0, height), BackgroundColor3 = Color3.fromRGB(37, 43, 58), LayoutOrder = order }, list)
	make("UICorner", { CornerRadius = UDim.new(0, 7) }, row)
	return row
end

local function addText(row, y, height, text, size, color, font)
	make("TextLabel", {
		BackgroundTransparency = 1, Position = UDim2.fromOffset(9, y), Size = UDim2.new(1, -110, 0, height),
		Font = font or Enum.Font.Gotham, Text = text, TextColor3 = color or Color3.new(1, 1, 1),
		TextSize = size, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
	}, row)
end

local function effectSummary(effects)
	local parts = {}
	if effects.WorkerSlots > 0 then table.insert(parts, "+" .. effects.WorkerSlots .. " worker slots") end
	if effects.IncomeBonus > 0 then table.insert(parts, "+" .. effects.IncomeBonus .. " coins/tick") end
	if effects.WorkerIncomeBonus > 0 then table.insert(parts, "+" .. effects.WorkerIncomeBonus .. " coins/worker/tick") end
	if effects.RecruitDiscount > 0 then table.insert(parts, "-" .. effects.RecruitDiscount .. " coins/recruit") end
	if effects.DamageBonus > 0 then table.insert(parts, "+" .. math.floor(effects.DamageBonus * 100 + 0.5) .. "% damage") end
	if effects.LockReduction > 0 then table.insert(parts, "-" .. effects.LockReduction .. "s knockout lock") end
	if effects.KillCoinBonus > 0 then table.insert(parts, "+" .. effects.KillCoinBonus .. " coins/kill") end
	return #parts > 0 and table.concat(parts, "  •  ") or "none yet"
end

rebuildPanel = function()
	for _, child in ipairs(list:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end
	if not state then return end

	if state.Plot then
		summary.Text = "Your plot: #" .. state.Plot .. "   Bonuses: " .. effectSummary(state.Effects)
	else
		summary.Text = "No free base plot is available."
	end

	addHeader("BUILDINGS", 1)
	for order, id in ipairs(Buildings.Order) do
		local def = Buildings.Catalog[id]
		local count = Buildings.countOf(state.Buildings, id)
		local cost = Buildings.costFor(id, 1)
		local row = addRow(10 + order, 72)
		addText(row, 5, 20, def.Name .. "   " .. count .. "/" .. def.MaxCount, 13, Color3.fromRGB(255, 225, 165), Enum.Font.GothamBold)
		addText(row, 26, 17, def.Description, 12)
		addText(row, 45, 17, (def.Effects and (Buildings.describe(id, 1) .. "  •  ") or "") .. costText(cost), 12, Color3.fromRGB(180, 230, 255))
		local b = button(row, "Build", UDim2.fromOffset(84, 34), UDim2.new(1, -92, 0.5, -17), function() enterPlacing(id) end)
		if not state.Plot then
			disable(b, "No plot")
		elseif count >= def.MaxCount then
			disable(b, "Built")
		elseif not canAfford(cost) then
			b.BackgroundColor3 = Color3.fromRGB(86, 60, 70)
		end
	end

	addHeader("YOUR BASE", 100)
	local starterRow = addRow(101, 48)
	addText(starterRow, 5, 20, "Starter Cabin", 13, Color3.fromRGB(255, 225, 165), Enum.Font.GothamBold)
	addText(starterRow, 26, 17, "Your free home. Fixed in place.", 12, Color3.fromRGB(170, 180, 195))
	for order, owned in ipairs(state.Buildings) do
		local row = addRow(110 + order, 80)
		addText(row, 5, 20, owned.Name .. "   Lv " .. owned.Level .. "/" .. owned.MaxLevel, 13, Color3.fromRGB(255, 225, 165), Enum.Font.GothamBold)
		addText(row, 26, 17, owned.Description, 12)
		local up = button(row, "", UDim2.fromOffset(200, 28), UDim2.new(0, 9, 1, -34), function() actionEvent:FireServer("Upgrade", owned.Index) end)
		if owned.NextCost then
			up.Text = "Upgrade to Lv " .. (owned.Level + 1) .. "  (" .. costText(owned.NextCost) .. ")"
			if not canAfford(owned.NextCost) then up.BackgroundColor3 = Color3.fromRGB(86, 60, 70) end
		else
			disable(up, "Max level")
		end
		button(row, "Sell  +" .. owned.SellValue .. " coins", UDim2.fromOffset(130, 28), UDim2.new(0, 216, 1, -34), function() actionEvent:FireServer("Demolish", owned.Index) end)
	end
end

-- ---------------------------------------------------------------------------
-- Placement
-- ---------------------------------------------------------------------------

placeBar = make("Frame", { Name = "PlaceBar", AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -150), Size = UDim2.fromOffset(470, 64), Visible = false }, gui)
stylePanel(placeBar)
placeLabel = make("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -24, 0, 22),
	Font = Enum.Font.GothamBold, Text = "", TextColor3 = Color3.fromRGB(205, 175, 255), TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left,
}, placeBar)
local placeHint = make("TextLabel", {
	BackgroundTransparency = 1, Position = UDim2.fromOffset(12, 28), Size = UDim2.new(1, -270, 0, 28),
	Font = Enum.Font.Gotham, Text = "", TextColor3 = Color3.new(1, 1, 1),
	TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
}, placeBar)

local function placeNow()
	if not placing then return end
	if ghostOk then
		actionEvent:FireServer("Build", { Id = placing, X = ghostCell.X, Z = ghostCell.Z })
	else
		placeHint.Text = "Move the hologram onto a green space in your plot."
	end
end

button(placeBar, "SELECT / PLACE  [E]", UDim2.fromOffset(142, 32), UDim2.new(1, -246, 1, -42), placeNow)
button(placeBar, "Done", UDim2.fromOffset(86, 32), UDim2.new(1, -96, 1, -42), function() exitPlacing() end)

local function updateGhost()
	if not placing or not state or not state.Plot or not ghost then return end
	local def = Buildings.Catalog[placing]
	local camera = workspace.CurrentCamera
	if not camera then return end

	local usingTouch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	local screenPoint = usingTouch and (pointer or (camera.ViewportSize / 2)) or UserInputService:GetMouseLocation()
	local ray = camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local hit = workspace:Raycast(ray.Origin, ray.Direction * 600, raycastParams)
	if not hit then
		for _, part in ipairs(ghost:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "GhostRoot" then part.Transparency = 1 end
		end
		ghostOk = false
		placeHint.Text = "Aim at the highlighted plot to position the hologram."
		return
	end

	local cellX, cellZ = Buildings.worldToCell(state.Plot, hit.Position.X, hit.Position.Z, def.W, def.D)
	local ok, reason = Buildings.canPlace(state.Buildings, placing, cellX, cellZ, state.Plot)
	if ok and not canAfford(Buildings.costFor(placing, 1)) then
		ok = false
		reason = "Missing coins or building materials."
	elseif ok then
		reason = "Green = valid • click or press E to place."
	end
	local centerX, centerZ = Buildings.cellCenter(state.Plot, cellX, cellZ, def.W, def.D)
	-- Keep the ghost inside the plot so it never floats somewhere confusing
	local clampedX = math.clamp(cellX, 0, Buildings.PlotCells - def.W)
	local clampedZ = math.clamp(cellZ, 0, Buildings.PlotCells - def.D)
	if clampedX ~= cellX or clampedZ ~= cellZ then
		centerX, centerZ = Buildings.cellCenter(state.Plot, clampedX, clampedZ, def.W, def.D)
		ok = false
		reason = "That would cross your plot border."
	end

	local ghostColor = ok and GOOD or BAD
	for _, part in ipairs(ghost:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "GhostRoot" then
			part.Transparency = 0.48
			part.Color = ghostColor
		end
	end
	ghost:PivotTo(CFrame.new(centerX, GROUND_Y, centerZ))
	ghostCell.X, ghostCell.Z = cellX, cellZ
	ghostOk = ok
	placeHint.Text = reason or "Invalid placement."
end

local function makeGhostModel(id)
	local def = Buildings.Catalog[id]
	local model = Instance.new("Model")
	model.Name = "BuildHologram"
	local root = Instance.new("Part")
	root.Name = "GhostRoot"
	root.Size = Vector3.new(0.1, 0.1, 0.1)
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide, root.CanTouch, root.CanQuery = false, false, false
	root.Parent = model
	model.PrimaryPart = root

	local function piece(name, size, x, y, z, shape)
		local part = Instance.new("Part")
		part.Name = name
		part.Size = size
		part.CFrame = CFrame.new(x, y, z)
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Material = Enum.Material.Neon
		part.Color = GOOD
		part.Transparency = 0.48
		if shape then part.Shape = shape end
		part.Parent = model
		return part
	end

	piece("Footprint", Vector3.new(def.W * Buildings.CellSize - 0.35, 0.25, def.D * Buildings.CellSize - 0.35), 0, 0.14, 0)
	if id == "CrystalMine" then
		piece("Mine Hut", Vector3.new(6.2, 3.0, 4.5), 0, 1.8, 0.5)
		piece("Mine Roof", Vector3.new(7.0, 0.45, 5.3), 0, 3.55, 0.5)
		for _, x in ipairs({ -2.2, 0, 2.2 }) do
			piece("Crystal", Vector3.new(1.0, 2.4, 1.0), x, 1.45, -2.3, Enum.PartType.Ball)
		end
	elseif id == "Barracks" then
		piece("Barracks Walls", Vector3.new(6.7, 3.8, 6.7), 0, 2.2, 0)
		piece("Barracks Roof", Vector3.new(7.4, 0.55, 7.4), 0, 4.4, 0)
		piece("Flag", Vector3.new(0.35, 2.2, 0.35), 2.8, 5.7, 2.8)
	elseif id == "Forge" then
		piece("Forge", Vector3.new(6.3, 3.0, 6.3), 0, 1.8, 0)
		piece("Forge Top", Vector3.new(7.0, 0.5, 7.0), 0, 3.55, 0)
		piece("Chimney", Vector3.new(1.4, 3.3, 1.4), 2.0, 5.4, 2.0)
	elseif id == "Infirmary" then
		piece("Healing Pool", Vector3.new(6.8, 0.55, 6.8), 0, 0.55, 0, Enum.PartType.Cylinder)
		for _, x in ipairs({ -2.8, 2.8 }) do
			for _, z in ipairs({ -2.8, 2.8 }) do
				piece("Pillar", Vector3.new(0.7, 3.4, 0.7), x, 2.2, z)
			end
		end
	elseif id == "BountyBoard" then
		piece("Board Post", Vector3.new(0.45, 5.8, 0.45), -2.5, 3.0, 0)
		piece("Board Post", Vector3.new(0.45, 5.8, 0.45), 2.5, 3.0, 0)
		piece("Market Sign", Vector3.new(6.4, 3.0, 0.4), 0, 4.6, 0)
	elseif id == "Lantern" then
		piece("Lantern Post", Vector3.new(0.35, 3.7, 0.35), 0, 1.95, 0)
		piece("Lantern", Vector3.new(1.1, 1.1, 1.1), 0, 4.2, 0, Enum.PartType.Ball)
	elseif id == "Tree" then
		piece("Tree Trunk", Vector3.new(0.8, 3.1, 0.8), 0, 1.7, 0)
		piece("Tree Canopy", Vector3.new(3.8, 3.8, 3.8), 0, 4.1, 0, Enum.PartType.Ball)
	else
		piece("Statue Plinth", Vector3.new(2.0, 1.0, 2.0), 0, 0.8, 0)
		piece("Statue Body", Vector3.new(1.1, 2.0, 1.0), 0, 2.3, 0)
		piece("Statue Head", Vector3.new(1.25, 1.25, 1.25), 0, 4.0, 0, Enum.PartType.Ball)
	end
	model.Parent = workspace
	return model
end

enterPlacing = function(id)
	if not state or not state.Plot then return end
	local def = Buildings.Catalog[id]
	if placing then exitPlacing() end
	placing = id
	panel.Visible = false

	local size = Buildings.PlotCells * Buildings.CellSize
	local plot = Buildings.Plots[state.Plot]
	local plotPad = world:WaitForChild("PlotPads"):FindFirstChild("Home Plot " .. state.Plot)
	raycastParams.FilterDescendantsInstances = plotPad and { plotPad } or {}
	ghost = makeGhostModel(id)
	zone = make("Part", {
		Name = "BuildZone", Anchored = true, CanCollide = false, CanQuery = false, CanTouch = false,
		Material = Enum.Material.Neon, Color = Color3.fromRGB(74, 207, 255), Transparency = 0.94,
		Size = Vector3.new(size, 0.08, size),
		CFrame = CFrame.new(plot.MinX + size / 2, GROUND_Y + 0.05, plot.MinZ + size / 2),
	}, workspace)

	placeLabel.Text = "Placing: " .. def.Name .. "  (" .. costText(Buildings.costFor(id, 1)) .. ")"
	placeHint.Text = "Green hologram = valid placement. Aim inside your plot."
	placeBar.Visible = true

	ContextActionService:BindActionAtPriority("BuilderPlace", function(_, inputState)
		if inputState == Enum.UserInputState.Begin then placeNow() end
		return Enum.ContextActionResult.Sink -- stops the click also triggering a basic attack
	end, false, Enum.ContextActionPriority.High.Value, Enum.UserInputType.MouseButton1, Enum.KeyCode.E)
	RunService:BindToRenderStep("BuilderGhost", Enum.RenderPriority.Camera.Value + 1, updateGhost)
end

exitPlacing = function()
	placing = nil
	pointer = nil
	ContextActionService:UnbindAction("BuilderPlace")
	pcall(function() RunService:UnbindFromRenderStep("BuilderGhost") end)
	if ghost then ghost:Destroy(); ghost = nil end
	if zone then zone:Destroy(); zone = nil end
	placeBar.Visible = false
end

local function togglePanel()
	if placing then exitPlacing() end
	panel.Visible = not panel.Visible
	if panel.Visible then refreshState() end
end

-- ---------------------------------------------------------------------------
-- Wiring
-- ---------------------------------------------------------------------------

button(gui, "BUILD BASE  [B]", UDim2.fromOffset(145, 38), UDim2.new(1, -318, 0, 18), togglePanel)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.KeyCode == Enum.KeyCode.B or input.KeyCode == Enum.KeyCode.V then togglePanel() end
	if input.KeyCode == Enum.KeyCode.X and placing then exitPlacing() end
end)

UserInputService.TouchTapInWorld:Connect(function(position, processedByUI)
	if placing and not processedByUI then pointer = position end
end)

actionEvent.OnClientEvent:Connect(function(message)
	if message == "BaseRefresh" then refreshState() end
end)

-- Refresh the builder after the player's resources change.
task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 15)
	if not stats then return end
	local pending = false
	local function onChanged()
		if pending then return end
		pending = true
		task.defer(function()
			pending = false
			if panel.Visible then rebuildPanel() end
		end)
	end
	for _, stat in ipairs(stats:GetChildren()) do stat.Changed:Connect(onChanged) end
	stats.ChildAdded:Connect(function(stat) stat.Changed:Connect(onChanged) end)
end)

-- The server creates the profile shortly after joining; keep asking until it answers.
task.spawn(function()
	for _ = 1, 20 do
		if refreshState() then return end
		task.wait(0.5)
	end
end)
