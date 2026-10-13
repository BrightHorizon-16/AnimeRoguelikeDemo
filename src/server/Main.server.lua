local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local WorldBuilder = require(script.Parent:WaitForChild("WorldBuilder"))

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
			Assigned = character.Assigned,
		})
	end
	local learned = {}
	for ability in pairs(profile.learned) do table.insert(learned, ability) end
	table.sort(learned)
	return { Roster = roster, Learned = learned, LockSeconds = math.max(0, math.ceil((profile.lockUntil or 0) - os.clock())) }
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
	if action == "Recruit" then
		local coins = getStat(player, "Coins")
		if not coins or coins.Value < Config.RecruitCost then notify(player, "Need " .. Config.RecruitCost .. " coins to recruit."); return end
		coins.Value -= Config.RecruitCost
		local options = {}
		for _, candidate in ipairs(Config.Characters) do
			local owned = false
			for _, existing in ipairs(profile.roster) do if existing.Name == candidate.Name then owned = true; break end end
			if not owned then table.insert(options, candidate) end
		end
		if #options == 0 then coins.Value += Config.RecruitCost; notify(player, "You have recruited every being in this demo."); return end
		local pick = options[random:NextInteger(1, #options)]
		local newCharacter = table.clone(pick)
		newCharacter.Assigned = false
		table.insert(profile.roster, newCharacter)
		notify(player, "Recruited " .. newCharacter.Name .. " — " .. newCharacter.Title .. "!")
	elseif action == "Assign" then
		local target = profile.roster[payload]
		if not target then return end
		target.Assigned = not target.Assigned
		notify(player, target.Name .. (target.Assigned and " assigned to the base." or " moved to your reserve."))
	elseif action == "Absorb" then
		local target = profile.roster[payload]
		if not target or target.Assigned then notify(player, "Move that being to your reserve before absorbing it."); return end
		if profile.learned[target.Ability] then notify(player, "You already know " .. target.Ability .. "."); return end
		profile.learned[target.Ability] = true
		local name = target.Name
		table.remove(profile.roster, payload)
		notify(player, name .. " was absorbed. " .. target.Ability .. " is now yours.")
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
			addStat(killer, "Coins", 12)
			addStat(killer, "Shards", 1)
			notify(killer, "+12 coins, +1 shard")
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
	local root = character:WaitForChild("HumanoidRootPart", 10)
	local hum = character:WaitForChild("Humanoid", 10)
	if root then root.CFrame = CFrame.new(0, 5, -12) end
	if hum then
		hum.Died:Connect(function()
			profile.lockUntil = os.clock() + Config.KnockoutLockSeconds
			notify(player, "Knocked out. You are locked at base for 60 seconds.")
		end)
	end
end

local function onPlayer(player)
	local coins = ensureStat(player, "Coins", 100)
	ensureStat(player, "Shards", 0)
	profiles[player] = {
		roster = {
			{ Name = "Kairo", Title = "Cinder Vanguard", Ability = "Cinder Rush", Description = "A flaming dash that damages nearby enemies.", Assigned = true },
			{ Name = "Vexa", Title = "Rift Weaver", Ability = "Gravity Snare", Description = "Pulls nearby enemies together and damages them.", Assigned = false },
		},
		learned = { ["Base Pulse"] = true },
		lockUntil = 0,
	}
	player.CharacterAdded:Connect(function(char) onCharacter(player, char) end)
	if player.Character then task.spawn(onCharacter, player, player.Character) end
	task.spawn(function()
		while player.Parent do
			local p = profiles[player]
			if p then
				local workers = 0
				for _, c in ipairs(p.roster) do if c.Assigned then workers += 1 end end
				addStat(player, "Coins", workers * Config.WorkerIncome)
				if workers > 0 then notify(player, "Base income: +" .. (workers * Config.WorkerIncome) .. " coins") end
			end
			task.wait(Config.IncomeInterval)
		end
	end)
end

WorldBuilder.build(world, Config)
Players.PlayerAdded:Connect(onPlayer)
Players.PlayerRemoving:Connect(function(player) profiles[player] = nil end)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(onPlayer, player) end

for _, position in ipairs(WorldBuilder.EnemySpawns) do
	spawnEnemy(position, "Wildling")
end

RunService.Heartbeat:Connect(function()
	for player, profile in pairs(profiles) do
		if profile.lockUntil and profile.lockUntil > os.clock() then
			local root = getRoot(player.Character)
			if root and root.Position.Z > 52 then
				root.CFrame = CFrame.new(0, 5, -12)
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end
	end
end)
