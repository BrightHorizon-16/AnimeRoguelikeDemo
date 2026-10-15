-- Buildings: shared catalog and pure rules for the base builder.
-- Used by the server (to validate and apply) and the client (to preview placement).
-- Contains no Roblox instances, so the rules are easy to test.

local Buildings = {}

Buildings.CellSize = 4 -- studs per grid cell
Buildings.PlotCells = 6 -- each plot is PlotCells x PlotCells cells (24 x 24 studs)

-- Plots on the Builder Grounds terrace behind the Guild Hall (MinX/MinZ are world studs).
Buildings.Plots = {
	{ MinX = -52, MinZ = -96 },
	{ MinX = -24, MinZ = -96 },
	{ MinX = 4, MinZ = -96 },
	{ MinX = 32, MinZ = -96 },
}

Buildings.Order = { "CrystalMine", "Barracks", "Forge", "Infirmary", "BountyBoard", "Lantern", "Tree", "Statue" }

-- Costs[n] is the price of reaching level n (level 1 = the build cost).
-- Effects[key][n] is the TOTAL bonus at level n (not per-level increments).
Buildings.Catalog = {
	CrystalMine = {
		Name = "Crystal Mine", Description = "Mines crystals for steady coin income.",
		W = 2, D = 2, MaxCount = 3, MaxLevel = 3,
		Costs = { { Coins = 80 }, { Coins = 140, Shards = 2 }, { Coins = 220, Shards = 5 } },
		Effects = { IncomeBonus = { 4, 9, 15 } },
	},
	Barracks = {
		Name = "Barracks", Description = "Houses more workers so more beings can earn coins.",
		W = 2, D = 2, MaxCount = 1, MaxLevel = 3,
		Costs = { { Coins = 100 }, { Coins = 160, Shards = 2 }, { Coins = 240, Shards = 4 } },
		Effects = { WorkerSlots = { 1, 2, 3 } },
	},
	Forge = {
		Name = "Forge", Description = "Sharpens your weapons.",
		W = 2, D = 2, MaxCount = 1, MaxLevel = 3,
		Costs = { { Coins = 90, Shards = 2 }, { Coins = 150, Shards = 4 }, { Coins = 240, Shards = 7 } },
		Effects = { DamageBonus = { 0.10, 0.20, 0.30 } },
	},
	Infirmary = {
		Name = "Infirmary", Description = "Gets you back on your feet faster after a knockout.",
		W = 2, D = 2, MaxCount = 1, MaxLevel = 3,
		Costs = { { Coins = 80, Shards = 1 }, { Coins = 140, Shards = 3 }, { Coins = 220, Shards = 6 } },
		Effects = { LockReduction = { 10, 20, 30 } },
	},
	BountyBoard = {
		Name = "Bounty Board", Description = "Posts bounties on Wildlings for extra coins.",
		W = 2, D = 2, MaxCount = 1, MaxLevel = 3,
		Costs = { { Coins = 70 }, { Coins = 120, Shards = 2 }, { Coins = 200, Shards = 4 } },
		Effects = { KillCoinBonus = { 3, 6, 10 } },
	},
	Lantern = {
		Name = "Lantern", Description = "A warm light for your plot.", Decor = true,
		W = 1, D = 1, MaxCount = 8, MaxLevel = 1, Costs = { { Coins = 10 } },
	},
	Tree = {
		Name = "Garden Tree", Description = "A little greenery.", Decor = true,
		W = 1, D = 1, MaxCount = 8, MaxLevel = 1, Costs = { { Coins = 15 } },
	},
	Statue = {
		Name = "Hero Statue", Description = "Show off your victories.", Decor = true,
		W = 1, D = 1, MaxCount = 4, MaxLevel = 1, Costs = { { Coins = 40 } },
	},
}

local EFFECT_TEXT = {
	WorkerSlots = function(v) return "+" .. v .. (v == 1 and " worker slot" or " worker slots") end,
	IncomeBonus = function(v) return "+" .. v .. " coins per income tick" end,
	DamageBonus = function(v) return "+" .. math.floor(v * 100 + 0.5) .. "% damage" end,
	LockReduction = function(v) return "-" .. v .. "s knockout lock" end,
	KillCoinBonus = function(v) return "+" .. v .. " coins per kill" end,
}

function Buildings.describe(id, level)
	local def = Buildings.Catalog[id]
	if not def then return "" end
	if not def.Effects then return def.Description end
	local parts = {}
	for key, perLevel in pairs(def.Effects) do
		local format = EFFECT_TEXT[key]
		if format and perLevel[level] then table.insert(parts, format(perLevel[level])) end
	end
	table.sort(parts)
	return table.concat(parts, ", ")
end

-- Price of reaching `level` (build = level 1). nil if out of range.
function Buildings.costFor(id, level)
	local def = Buildings.Catalog[id]
	if not def or type(level) ~= "number" or level < 1 or level > def.MaxLevel then return nil end
	local cost = def.Costs[level]
	return { Coins = cost.Coins or 0, Shards = cost.Shards or 0 }
end

-- Coins returned for demolishing: a fraction of all coins spent up to `level`.
function Buildings.sellValue(id, level, refund)
	local def = Buildings.Catalog[id]
	if not def then return 0 end
	local spent = 0
	for n = 1, math.min(level, def.MaxLevel) do spent += def.Costs[n].Coins or 0 end
	return math.floor(spent * (refund or 0.5))
end

function Buildings.countOf(list, id)
	local count = 0
	for _, entry in ipairs(list) do if entry.Id == id then count += 1 end end
	return count
end

-- Sum of all bonuses from a list of { Id, Level } entries.
function Buildings.effects(list)
	local total = { WorkerSlots = 0, IncomeBonus = 0, DamageBonus = 0, LockReduction = 0, KillCoinBonus = 0 }
	for _, entry in ipairs(list) do
		local def = Buildings.Catalog[entry.Id]
		if def and def.Effects then
			for key, perLevel in pairs(def.Effects) do
				total[key] = (total[key] or 0) + (perLevel[entry.Level] or 0)
			end
		end
	end
	return total
end

local function isInt(n)
	return type(n) == "number" and n == n and n ~= math.huge and n ~= -math.huge and n == math.floor(n)
end
Buildings.isInt = isInt

local function overlaps(ax, az, aw, ad, bx, bz, bw, bd)
	return ax < bx + bw and bx < ax + aw and az < bz + bd and bz < az + ad
end

-- Can `id` be placed with its minimum corner at cell (x, z) given the buildings already there?
function Buildings.canPlace(list, id, x, z)
	local def = type(id) == "string" and Buildings.Catalog[id] or nil
	if not def then return false, "Unknown building." end
	if not isInt(x) or not isInt(z) then return false, "Invalid position." end
	local cells = Buildings.PlotCells
	if x < 0 or z < 0 or x + def.W > cells or z + def.D > cells then return false, "That's outside your plot." end
	if Buildings.countOf(list, id) >= def.MaxCount then
		return false, "You can only have " .. def.MaxCount .. " " .. def.Name .. (def.MaxCount == 1 and "" or "s") .. "."
	end
	for _, other in ipairs(list) do
		local otherDef = Buildings.Catalog[other.Id]
		if otherDef and overlaps(x, z, def.W, def.D, other.X, other.Z, otherDef.W, otherDef.D) then
			return false, "Something is already built there."
		end
	end
	return true
end

-- World-space centre (x, z) of a building whose minimum corner is cell (x, z) in the given plot.
function Buildings.cellCenter(plotIndex, x, z, w, d)
	local plot = Buildings.Plots[plotIndex]
	return plot.MinX + (x + w / 2) * Buildings.CellSize, plot.MinZ + (z + d / 2) * Buildings.CellSize
end

-- Minimum-corner cell that centres a w x d building on a world position (for the placement ghost).
function Buildings.worldToCell(plotIndex, wx, wz, w, d)
	local plot = Buildings.Plots[plotIndex]
	local size = Buildings.CellSize
	return math.floor((wx - plot.MinX) / size - w / 2 + 0.5), math.floor((wz - plot.MinZ) / size - d / 2 + 0.5)
end

return Buildings
