-- PlayerData: thin DataStore wrapper.
--
-- load() returns (data, ok). ok = true means the store answered (data is nil for a brand-new
-- player), so it is safe to save later. ok = false means loading failed, and the caller must
-- NOT save, otherwise default values would overwrite the player's real data.
--
-- In Roblox Studio this only works if the place is published and "Enable Studio Access to API
-- Services" is on (Game Settings > Security). Otherwise the game still runs, it just doesn't save.

local DataStoreService = game:GetService("DataStoreService")

local STORE_NAME = "GeneratedBeings_PlayerData_v1"

local PlayerData = {}

local store -- nil = not tried yet, false = unavailable
local warned = false

local function getStore()
	if store == nil then
		local ok, result = pcall(function() return DataStoreService:GetDataStore(STORE_NAME) end)
		store = ok and result or false
	end
	return store or nil
end

local function warnOnce(message)
	if warned then return end
	warned = true
	warn("[PlayerData] " .. tostring(message) .. " - progress will not be saved this session. " ..
		"In Studio, publish the place and enable Studio Access to API Services.")
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

function PlayerData.load(player)
	local ds = getStore()
	if not ds then warnOnce("DataStore unavailable"); return nil, false end
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(function() return ds:GetAsync(keyFor(player)) end)
		if ok then return result, true end
		lastError = result
		task.wait(attempt)
	end
	warnOnce(lastError)
	return nil, false
end

function PlayerData.save(player, data)
	local ds = getStore()
	if not ds then return false end
	for attempt = 1, 3 do
		local ok, result = pcall(function() return ds:SetAsync(keyFor(player), data) end)
		if ok then return true end
		if attempt == 3 then warn("[PlayerData] Save failed for " .. player.Name .. ": " .. tostring(result)) end
		task.wait(attempt)
	end
	return false
end

return PlayerData
