local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPack = game:GetService("StarterPack")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Buildings = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Buildings"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local PlayerData = require(script.Parent:WaitForChild("PlayerData"))

local remotes = Instance.new("Folder")
remotes.Name = "GameRemotes"
remotes.Parent = ReplicatedStorage
local actionEvent = Instance.new("RemoteEvent")
actionEvent.Name = "Action"
actionEvent.Parent = remotes
local stateFunction = Instance.new("RemoteFunction")
stateFunction.Name = "GetState"
stateFunction.Parent = remotes
local notifyEvent = Instance.new("RemoteEvent")
notifyEvent.Name = "Notify"
notifyEvent.Parent = remotes
local baseStateFunction = Instance.new("RemoteFunction")
baseStateFunction.Name = "GetBaseState"
baseStateFunction.Parent = remotes

-- The Studio place has older tutorial scenery and a Lantern tool that Rojo does
-- not map. This prototype builds its own runtime world and has no Tool items.
for _, oldScriptContainer in ipairs(ServerScriptService:GetChildren()) do
	if oldScriptContainer ~= script.Parent then
		oldScriptContainer:Destroy()
	end
end
StarterPack:ClearAllChildren()
local terrain = workspace:FindFirstChildOfClass("Terrain")
if terrain then terrain:Clear() end
for _, oldObject in ipairs(workspace:GetChildren()) do
	if oldObject ~= terrain and not oldObject:IsA("Camera") then
		oldObject:Destroy()
	end
end

local world = Instance.new("Folder")
world.Name = "DemoWorld"
world.Parent = workspace
local enemies = Instance.new("Folder")
enemies.Name = "Enemies"
enemies.Parent = world

local profiles = {}
local cooldowns = {}
local random = Random.new()

local function ensureStat(player, name, initial)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	local stat = Instance.new("IntValue")
	stat.Name = name
	stat.Value = initial
	stat.Parent = leaderstats
	return stat
end

local function stateFor(player)
	local profile = profiles[player]
	if not profile then return nil end
	local roster = {}
	for _, character in ipairs(profile.roster) do
		table.insert(roster, {
			Name = character.Name,
			Title = character.Title,
			Ability = character.Ability,
			Description = character.Description,
			Rarity = character.Rarity or "Common",
			Income = character.Income or Config.WorkerIncome,
			Form = character.Form,
			Assigned = character.Assigned,
		})
	end
	local learned = {}
	for ability in pairs(profile.learned) do table.insert(learned, ability) end
	table.sort(learned)
	local workers = 0
	for _, character in ipairs(profile.roster) do if character.Assigned then workers += 1 end end
	local bonusSlots = profile.effects and profile.effects.WorkerSlots or 0
	return {
		Roster = roster,
		Learned = learned,
		RecruitCost = math.max(10, Config.RecruitCost + math.max(0, #profile.roster - 1) * 15 - (profile.effects and profile.effects.RecruitDiscount or 0)),
		DevMode = RunService:IsStudio(),
		LockSeconds = math.max(0, math.ceil((profile.lockUntil or 0) - os.clock())),
		Workers = workers,
		WorkerSlots = Config.BaseWorkerSlots + bonusSlots,
	}
end

stateFunction.OnServerInvoke = function(player)
	return stateFor(player)
end

local function notify(player, text)
	notifyEvent:FireClient(player, text)
end

local function getStat(player, name)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild(name)
end

local function addStat(player, name, amount)
	local stat = getStat(player, name)
	if stat then stat.Value += amount end
end

-- Bonuses from the player's buildings (see Buildings.lua and BaseManager.lua)
local function effectsFor(profile)
	return profile.effects or Buildings.effects(profile.buildings or {})
end

local function countWorkers(profile)
	local workers = 0
	for _, character in ipairs(profile.roster) do if character.Assigned then workers += 1 end end
	return workers
end

local function workerSlots(profile)
	return Config.BaseWorkerSlots + effectsFor(profile).WorkerSlots
end

local function lockSeconds(profile)
	return math.max(Config.MinKnockoutLockSeconds, Config.KnockoutLockSeconds - effectsFor(profile).LockReduction)
end

-- Called after buildings change: if slots shrank (e.g. a Barracks was demolished), stand extra workers down.
local function enforceWorkerCap(player)
	local profile = profiles[player]
	if not profile then return end
	local slots = workerSlots(profile)
	local workers = 0
	for _, character in ipairs(profile.roster) do
		if character.Assigned then
			workers += 1
			if workers > slots then
				character.Assigned = false
				notify(player, character.Name .. " moved to reserve - not enough worker slots.")
			end
		end
	end
	actionEvent:FireClient(player, "Refresh")
end

local function getRoot(character)
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function taggedHumanoid(model)
	return model and model:FindFirstChildOfClass("Humanoid")
end

local function enemyTarget(root, radius)
	local best, bestDistance
	for _, model in ipairs(enemies:GetChildren()) do
		local hum = taggedHumanoid(model)
		local targetRoot = getRoot(model)
		if hum and hum.Health > 0 and targetRoot then
			local distance = (targetRoot.Position - root.Position).Magnitude
			if distance <= radius and (not bestDistance or distance < bestDistance) then
				best, bestDistance = model, distance
			end
		end
	end
	return best
end

local function damageEnemy(player, model, amount)
	local hum = taggedHumanoid(model)
	if not hum or hum.Health <= 0 then return end
	local profile = profiles[player]
	if profile then amount = math.max(1, math.floor(amount * (1 + effectsFor(profile).DamageBonus) + 0.5)) end
	local credit = hum:FindFirstChild("LastHitBy") or Instance.new("ObjectValue")
	credit.Name = "LastHitBy"
	credit.Value = player
	credit.Parent = hum
	hum:TakeDamage(amount)
end

local function useAbility(player, abilityName)
	local profile = profiles[player]
	local character = player.Character
	local root = getRoot(character)
	if not profile or not root or not profile.learned[abilityName] then return end
	local key = player.UserId .. ":" .. abilityName
	if cooldowns[key] and os.clock() < cooldowns[key] then return end
	cooldowns[key] = os.clock() + 8
	local radius = 20
	local count = 0
	for _, model in ipairs(enemies:GetChildren()) do
		local targetRoot = getRoot(model)
		local hum = taggedHumanoid(model)
		if targetRoot and hum and hum.Health > 0 and (targetRoot.Position - root.Position).Magnitude <= radius then
			damageEnemy(player, model, 45)
			count += 1
		end
	end
	if abilityName == "Verdant Pulse" then
		local hum = taggedHumanoid(character)
		if hum then hum.Health = math.min(hum.MaxHealth, hum.Health + 35) end
	end
	notify(player, abilityName .. " hit " .. count .. " enemies")
end

local function handleAction(player, action, payload)
	local profile = profiles[player]
	if not profile then return end
	if BaseManager.handleAction(player, action, payload) then return end
	if action == "Recruit" then
		local coins = getStat(player, "Coins")
		local recruitCost = math.max(10, Config.RecruitCost + math.max(0, #profile.roster - 1) * 15 - effectsFor(profile).RecruitDiscount)
		if #profile.roster >= Config.MaxRosterSize then notify(player, "Your creature stands are full."); return end
		if not coins or coins.Value < recruitCost then notify(player, "Need " .. recruitCost .. " coins to recruit."); return end
		coins.Value -= recruitCost
		local newCharacter = Config.rollCharacter(random)
		newCharacter.Assigned = false
		table.insert(profile.roster, newCharacter)
		notify(player, "Rolled " .. newCharacter.Rarity .. " creature: " .. newCharacter.Name .. "!")
	elseif action == "Assign" then
		local target = type(payload) == "number" and profile.roster[payload]
		if not target then return end
		if not target.Assigned and countWorkers(profile) >= workerSlots(profile) then
			notify(player, "No free worker slots - build or upgrade a Barracks on your plot.")
			return
		end
		target.Assigned = not target.Assigned
		notify(player, target.Name .. (target.Assigned and " assigned to the base." or " moved to your reserve."))
	elseif action == "Absorb" then
		local target = profile.roster[payload]
		if not target or target.Assigned then notify(player, "Move that creature to your reserve before absorbing it."); return end
		if profile.learned[target.Ability] then notify(player, "You already know " .. target.Ability .. "."); return end
		profile.learned[target.Ability] = true
		local name = target.Name
		table.remove(profile.roster, payload)
		notify(player, name .. " was absorbed. " .. target.Ability .. " is now yours.")
	elseif action == "Sprint" then
		local hum = taggedHumanoid(player.Character)
		if not hum or hum.Health <= 0 or type(payload) ~= "boolean" then return end
		profile.sprinting = payload
		hum.WalkSpeed = payload and Config.SprintSpeed or Config.WalkSpeed
		actionEvent:FireClient(player, "SprintState", payload)
	elseif action == "DevGrant" then
		if not RunService:IsStudio() or payload ~= "BuildPack" then return end
		addStat(player, "Coins", 5000)
		addStat(player, "Wood", 500)
		addStat(player, "Stone", 500)
		addStat(player, "Shards", 100)
		notify(player, "Studio test pack added: 5,000 coins, 500 wood, 500 stone, 100 essence.")
	elseif action == "Attack" then
		local root = getRoot(player.Character)
		if not root then return end
		local attackType = payload == "Heavy" and "Heavy" or "Light"
		local key = player.UserId .. ":Attack:" .. attackType
		local waitTime = attackType == "Heavy" and 0.9 or 0.35
		if cooldowns[key] and os.clock() < cooldowns[key] then return end
		cooldowns[key] = os.clock() + waitTime
		local target = enemyTarget(root, 14)
		if target then damageEnemy(player, target, attackType == "Heavy" and 35 or 15) end
	elseif action == "Dash" then
		local root = getRoot(player.Character)
		local hum = taggedHumanoid(player.Character)
		local key = player.UserId .. ":Dash"
		if root and hum and (not cooldowns[key] or os.clock() >= cooldowns[key]) then
			cooldowns[key] = os.clock() + 1.25
			local direction = hum.MoveDirection
			if direction.Magnitude > 0 then root.AssemblyLinearVelocity = direction.Unit * 75 + Vector3.new(0, 8, 0) end
		end
	elseif action == "Movement" then
		local root = getRoot(player.Character)
		local hum = taggedHumanoid(player.Character)
		local key = player.UserId .. ":Movement"
		if root and hum and (not cooldowns[key] or os.clock() >= cooldowns[key]) then
			cooldowns[key] = os.clock() + 5
			local direction = hum.MoveDirection
			if direction.Magnitude == 0 then direction = root.CFrame.LookVector end
			root.AssemblyLinearVelocity = direction.Unit * 42 + Vector3.new(0, 52, 0)
		end
	elseif action == "Ability" then
		local ability = profile.learned[payload] and payload
		if ability then useAbility(player, ability) end
	elseif action == "Ultimate" then
		local root = getRoot(player.Character)
		if not root then return end
		local key = player.UserId .. ":Ultimate"
		if cooldowns[key] and os.clock() < cooldowns[key] then return end
		cooldowns[key] = os.clock() + 25
		for _, model in ipairs(enemies:GetChildren()) do
			local targetRoot = getRoot(model)
			if targetRoot and (targetRoot.Position - root.Position).Magnitude <= 30 then damageEnemy(player, model, 100) end
		end
		notify(player, "Ultimate unleashed!")
	end
	if action == "Recruit" or action == "Assign" or action == "Absorb" then
		BaseManager.refreshRosterDisplays(player, profile)
		actionEvent:FireClient(player, "Refresh")
	end
end

actionEvent.OnServerEvent:Connect(handleAction)

local function spawnEnemy(position, kind)
	local model = Instance.new("Model")
	model.Name = kind or "Wildling"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(4, 5, 4)
	root.Position = position
	root.Color = Color3.fromRGB(191, 84, 107)
	root.Material = Enum.Material.Neon
	root.Anchored = false
	root.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(3, 3, 3)
	head.Position = position + Vector3.new(0, 4, 0)
	head.Color = Color3.fromRGB(255, 151, 124)
	head.Anchored = false
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1 = root, head
	weld.Parent = root
	local hum = Instance.new("Humanoid")
	hum.MaxHealth = Config.EnemyHealth
	hum.Health = Config.EnemyHealth
	hum.WalkSpeed = 9
	hum.Parent = model
	model.PrimaryPart = root
	model.Parent = enemies
	local deadConnection
	deadConnection = hum.Died:Connect(function()
		local tag = hum:FindFirstChild("LastHitBy")
		local killer = tag and tag.Value
		if killer and killer:IsA("Player") then
			local killerProfile = profiles[killer]
			local coinsEarned = Config.KillCoins + (killerProfile and effectsFor(killerProfile).KillCoinBonus or 0)
			addStat(killer, "Coins", coinsEarned)
			addStat(killer, "Shards", Config.KillShards)
			notify(killer, "+" .. coinsEarned .. " coins, +" .. Config.KillShards .. " shard")
		end
		task.delay(3, function() if model.Parent then model:Destroy() end end)
		task.delay(12, function() if #enemies:GetChildren() < 10 then spawnEnemy(position, kind) end end)
		if deadConnection then deadConnection:Disconnect() end
	end)
	task.spawn(function()
		while model.Parent and hum.Health > 0 do
			local nearest, nearestDistance
			for _, player in ipairs(Players:GetPlayers()) do
				local charRoot = getRoot(player.Character)
				local p = profiles[player]
				if charRoot and p and (p.lockUntil or 0) <= os.clock() then
					local d = (charRoot.Position - root.Position).Magnitude
					if d < 75 and (not nearestDistance or d < nearestDistance) then nearest, nearestDistance = player.Character, d end
				end
			end
			local targetRoot = getRoot(nearest)
			if targetRoot and nearestDistance then
				hum:MoveTo(targetRoot.Position)
				if nearestDistance < 5 then
					local targetHum = taggedHumanoid(nearest)
					if targetHum then targetHum:TakeDamage(7) end
				end
			end
			task.wait(1)
		end
	end)
	return model
end

local function onCharacter(player, character)
	local profile = profiles[player]
	if not profile then return end
	for _, item in ipairs(character:GetChildren()) do
		if item:IsA("Tool") then item:Destroy() end
	end
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local hum = character:WaitForChild("Humanoid", 10)
	local plot = profile.plot and Buildings.Plots[profile.plot]
	local spawnOffset = profile.plot and profile.plot >= 3 and 8 or 24
	local spawnPosition = plot and Vector3.new(plot.MinX + 16, 5, plot.MinZ + spawnOffset) or Vector3.new(0, 5, 0)
	if root then root.CFrame = CFrame.new(spawnPosition) end
	if hum then
		profile.sprinting = false
		hum.WalkSpeed = Config.WalkSpeed
		actionEvent:FireClient(player, "SprintState", false)
		hum.Died:Connect(function()
			local seconds = lockSeconds(profile)
			profile.lockUntil = os.clock() + seconds
			notify(player, "Knocked out. You are locked at base for " .. seconds .. " seconds.")
		end)
	end
end

local applySaved

local function findCharacter(name)
	for _, character in ipairs(Config.Characters) do
		if character.Name == name then return character end
	end
end

local function serializeProfile(player, profile)
	local roster = {}
	for _, character in ipairs(profile.roster) do
		table.insert(roster, {
			Name = character.Name, Title = character.Title, Ability = character.Ability,
			Description = character.Description, Rarity = character.Rarity, Income = character.Income, Form = character.Form,
			Assigned = character.Assigned == true,
		})
	end
	local learned = {}
	for ability in pairs(profile.learned) do table.insert(learned, ability) end
	table.sort(learned)
	local coins, shards = getStat(player, "Coins"), getStat(player, "Shards")
	return {
		Version = 1,
		Coins = coins and coins.Value or 0,
		Shards = shards and shards.Value or 0,
		Wood = getStat(player, "Wood").Value,
		Stone = getStat(player, "Stone").Value,
		Roster = roster,
		Learned = learned,
		Buildings = BaseManager.serialize(profile),
	}
end

applySaved = function(player, profile, data)
	if type(data) ~= "table" then data = {} end
	local coins, shards = getStat(player, "Coins"), getStat(player, "Shards")
	if coins and type(data.Coins) == "number" then coins.Value = math.max(0, math.floor(data.Coins)) end
	if shards and type(data.Shards) == "number" then shards.Value = math.max(0, math.floor(data.Shards)) end
	for _, resource in ipairs({ "Wood", "Stone" }) do
		local stat = getStat(player, resource)
		if stat and type(data[resource]) == "number" then stat.Value = math.clamp(math.floor(data[resource]), 0, 1000000000) end
	end
	if type(data.Roster) == "table" then
		local roster = {}
		for _, saved in ipairs(data.Roster) do
			if #roster >= Config.MaxRosterSize then break end
			local definition = type(saved) == "table" and findCharacter(saved.Name)
			if type(saved) == "table" and type(saved.Name) == "string" and #saved.Name <= 48 then
				local character = definition and table.clone(definition) or {}
				character.Name = saved.Name
				character.Title = type(saved.Title) == "string" and string.sub(saved.Title, 1, 48) or character.Title or "Generated Being"
				character.Ability = type(saved.Ability) == "string" and string.sub(saved.Ability, 1, 48) or character.Ability or "Base Pulse"
				character.Description = type(saved.Description) == "string" and string.sub(saved.Description, 1, 120) or character.Description or "An original generated creature."
				character.Rarity = ({ Common = true, Uncommon = true, Rare = true, Epic = true, Legendary = true, Mythic = true })[saved.Rarity] and saved.Rarity or character.Rarity or "Common"
				character.Income = type(saved.Income) == "number" and math.clamp(math.floor(saved.Income), 1, 100) or character.Income or Config.WorkerIncome
				character.Form = type(saved.Form) == "number" and math.clamp(math.floor(saved.Form), 1, #Config.BeingForms) or character.Form
				character.Assigned = saved.Assigned == true
				table.insert(roster, character)
			end
		end
		profile.roster = roster
	end
	if type(data.Learned) == "table" then
		profile.learned = { ["Base Pulse"] = true }
		for _, ability in ipairs(data.Learned) do
			if type(ability) == "string" then profile.learned[ability] = true end
		end
	end
	BaseManager.restore(player, profile, data.Buildings)
	BaseManager.refreshRosterDisplays(player, profile)
end

local function saveProfile(player)
	local profile = profiles[player]
	if not profile or not profile.canSave or profile.saving then return end
	profile.saving = true
	PlayerData.save(player, serializeProfile(player, profile))
	profile.saving = false
end

local function onPlayer(player)
	for _, containerName in ipairs({ "Backpack", "StarterGear" }) do
		local container = player:FindFirstChild(containerName)
		if container then
			for _, item in ipairs(container:GetChildren()) do
				if item:IsA("Tool") then item:Destroy() end
			end
		end
	end
	ensureStat(player, "Coins", 100)
	ensureStat(player, "Shards", 0)
	ensureStat(player, "Wood", 0)
	ensureStat(player, "Stone", 0)
	local starterBeing = Config.rollCharacter(random)
	starterBeing.Assigned = true
	profiles[player] = {
		roster = { starterBeing },
		learned = { ["Base Pulse"] = true },
		lockUntil = 0,
		sprinting = false,
		buildings = { { Id = "StarterHouse", X = 3, Z = 3, Level = 1 } },
		effects = Buildings.effects({}),
	}
	local profile = profiles[player]
	BaseManager.assignPlot(player, profile)
	-- Load saved progress in the background; defaults are used until (and unless) it arrives.
	task.spawn(function()
		local data, ok = PlayerData.load(player)
		if profiles[player] ~= profile then return end
		if ok then
			applySaved(player, profile, data)
			profile.canSave = true -- only save if the load succeeded, so defaults never overwrite real data
		else
			BaseManager.restore(player, profile, nil)
			BaseManager.refreshRosterDisplays(player, profile)
		end
		enforceWorkerCap(player)
		actionEvent:FireClient(player, "BaseRefresh")
	end)
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	task.spawn(function()
		while player.Parent do
			local p = profiles[player]
			if p then
				local bonuses = effectsFor(p)
				local income = 0
				for _, being in ipairs(p.roster) do
					if being.Assigned then income += (being.Income or Config.WorkerIncome) + bonuses.WorkerIncomeBonus end
				end
				income += bonuses.IncomeBonus
				addStat(player, "Coins", income)
				if income > 0 then notify(player, "Base income: +" .. income .. " coins") end
			end
			task.wait(Config.IncomeInterval)
		end
	end)
end

WorldBuilder.build(world, Config)
for _, node in ipairs(world:WaitForChild("GatherNodes"):GetChildren()) do
	local prompt = node:FindFirstChild("GatherPrompt", true)
	local resource = node:GetAttribute("Resource")
	local amount = node:GetAttribute("Amount")
	if prompt and (resource == "Wood" or resource == "Stone" or resource == "Shards") then
		local savedParts = {}
		for _, descendant in ipairs(node:GetDescendants()) do
			if descendant:IsA("BasePart") then
				savedParts[descendant] = { Transparency = descendant.Transparency, CanCollide = descendant.CanCollide }
			end
		end
		prompt.Triggered:Connect(function(player)
			local profile = profiles[player]
			local root = getRoot(player.Character)
			if not profile or node:GetAttribute("Available") ~= true or not root then return end
			if (root.Position - prompt.Parent.Position).Magnitude > prompt.MaxActivationDistance + 2 then return end
			local stat = getStat(player, resource)
			if not stat then return end
			node:SetAttribute("Available", false)
			prompt.Enabled = false
			for part in pairs(savedParts) do
				if part.Parent then part.Transparency = 1; part.CanCollide = false end
			end
			stat.Value += amount
			notify(player, string.format("Gathered %d %s.", amount, resource == "Shards" and "essence" or string.lower(resource)))
			task.delay(18, function()
				if not node.Parent then return end
				node:SetAttribute("Available", true)
				for part, appearance in pairs(savedParts) do
					if part.Parent then
						part.Transparency = appearance.Transparency
						part.CanCollide = appearance.CanCollide
					end
				end
				prompt.Enabled = true
			end)
		end)
	end
end
BaseManager.init({
	world = world,
	Config = Config,
	profiles = profiles,
	notify = notify,
	getStat = getStat,
	refresh = function(player) actionEvent:FireClient(player, "BaseRefresh") end,
	onChanged = enforceWorkerCap,
})
baseStateFunction.OnServerInvoke = function(player)
	return BaseManager.stateFor(player)
end

Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player)
	saveProfile(player)
	BaseManager.releasePlot(player, profiles[player])
	profiles[player] = nil
end)

-- Autosave every minute, and save everyone when the server shuts down.
task.spawn(function()
	while true do
		task.wait(60)
		for _, player in ipairs(Players:GetPlayers()) do task.spawn(saveProfile, player) end
	end
end)
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			saveProfile(player)
			pending -= 1
		end)
	end
	local deadline = os.clock() + 20
	while pending > 0 and os.clock() < deadline do task.wait(0.2) end
end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

for _, position in ipairs(WorldBuilder.EnemySpawns) do
	spawnEnemy(position, "Wildling")
end

RunService.Heartbeat:Connect(function()
	for player, profile in pairs(profiles) do
		if profile.lockUntil and profile.lockUntil > os.clock() then
			local root = getRoot(player.Character)
			if root and (math.abs(root.Position.X) > 55 or math.abs(root.Position.Z) > 55) then
				local plot = profile.plot and Buildings.Plots[profile.plot]
				local spawnOffset = profile.plot and profile.plot >= 3 and 8 or 24
				local home = plot and Vector3.new(plot.MinX + 16, 5, plot.MinZ + spawnOffset) or Vector3.new(0, 5, 0)
				root.CFrame = CFrame.new(home)
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end)
