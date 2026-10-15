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

-- Original, toy-like creature forms for the collection/roll loop.
Config.NameFirst = { "Wobble", "Mochi", "Pickle", "Bongo", "Noodle", "Toasty", "Bloop", "Zippy", "Mallow", "Bonk" }
Config.BeingForms = { "Slug", "Pup", "Moth", "Toad", "Jelly", "Golem", "Alpaca", "Mimic" }
Config.Abilities = { "Cinder Rush", "Gravity Snare", "Verdant Pulse", "Nightfall", "Storm Ring", "Crystal Bloom", "Wildfire Arc", "Moonstep" }

function Config.rollCharacter(random)
	local rarityRoll = random:NextInteger(1, 10000)
	local rarity, income
	if rarityRoll > 9990 then rarity, income = "Mythic", 40
	elseif rarityRoll > 9900 then rarity, income = "Legendary", 24
	elseif rarityRoll > 9500 then rarity, income = "Epic", 14
	elseif rarityRoll > 8300 then rarity, income = "Rare", 9
	elseif rarityRoll > 5500 then rarity, income = "Uncommon", 6
	else rarity, income = "Common", 4 end
	local form = random:NextInteger(1, #Config.BeingForms)
	return {
		Name = Config.NameFirst[random:NextInteger(1, #Config.NameFirst)] .. " " .. Config.BeingForms[form],
		Title = rarity .. " Creature",
		Ability = Config.Abilities[random:NextInteger(1, #Config.Abilities)],
		Description = "An original " .. string.lower(rarity) .. " creature. Its rarity sets its base income.",
		Rarity = rarity,
		Income = income,
		Form = form,
	}
end

return Config
