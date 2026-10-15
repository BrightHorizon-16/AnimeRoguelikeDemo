local Config = {}

Config.RecruitCost = 50
Config.MaxRosterSize = 8
Config.IncomeInterval = 10
Config.WorkerIncome = 5
Config.WalkSpeed = 16
Config.SprintSpeed = 24
Config.KnockoutLockSeconds = 60
Config.EnemyHealth = 100
Config.KillCoins = 12
Config.KillShards = 1
Config.BaseWorkerSlots = 2 -- the Barracks adds more worker slots
Config.MinKnockoutLockSeconds = 10 -- Infirmary can't reduce the lock below this
Config.SellRefund = 0.5 -- fraction of coins spent that demolishing returns

-- Legacy definitions remain so existing saved rosters can be migrated.
Config.Characters = {
	{ Name = "Kairo", Title = "Cinder Vanguard", Ability = "Cinder Rush", Description = "A flaming dash that damages nearby enemies." },
	{ Name = "Vexa", Title = "Rift Weaver", Ability = "Gravity Snare", Description = "Pulls nearby enemies together and damages them." },
	{ Name = "Mori", Title = "Grove Warden", Ability = "Verdant Pulse", Description = "Restores a little health and damages nearby enemies." },
	{ Name = "Nyx", Title = "Dusk Stalker", Ability = "Nightfall", Description = "A quick strike against the nearest enemy." },
	{ Name = "Aru", Title = "Storm Caller", Ability = "Storm Ring", Description = "Damages every enemy around you." },
}

-- Modular name/title/skill pools create original placeholder beings for recruit rolls.
Config.NameFirst = { "Ashen", "Moss", "Solar", "Dusk", "Frost", "Amber", "Rift", "Bramble", "Cinder", "Moon" }
Config.NameLast = { "Warden", "Runner", "Seer", "Keeper", "Vanguard", "Weaver", "Scout", "Guardian", "Caller", "Blade" }
Config.Abilities = { "Cinder Rush", "Gravity Snare", "Verdant Pulse", "Nightfall", "Storm Ring", "Crystal Bloom", "Wildfire Arc", "Moonstep" }

function Config.rollCharacter(random)
	local rarityRoll = random:NextInteger(1, 100)
	local rarity, income = "Common", 4
	if rarityRoll > 97 then rarity, income = "Epic", 12
	elseif rarityRoll > 85 then rarity, income = "Rare", 8
	elseif rarityRoll > 60 then rarity, income = "Uncommon", 6 end
	return {
		Name = Config.NameFirst[random:NextInteger(1, #Config.NameFirst)] .. " " .. Config.NameLast[random:NextInteger(1, #Config.NameLast)],
		Title = rarity .. " Being",
		Ability = Config.Abilities[random:NextInteger(1, #Config.Abilities)],
		Description = "An original " .. string.lower(rarity) .. " being.",
		Rarity = rarity,
		Income = income,
	}
end

return Config
