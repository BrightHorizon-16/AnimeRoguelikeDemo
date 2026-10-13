local Config = {}

Config.RecruitCost = 50
Config.IncomeInterval = 10
Config.WorkerIncome = 5
Config.KnockoutLockSeconds = 60
Config.EnemyHealth = 100

-- Original placeholder characters. Replace these with your own final designs later.
Config.Characters = {
	{ Name = "Kairo", Title = "Cinder Vanguard", Ability = "Cinder Rush", Description = "A flaming dash that damages nearby enemies." },
	{ Name = "Vexa", Title = "Rift Weaver", Ability = "Gravity Snare", Description = "Pulls nearby enemies together and damages them." },
	{ Name = "Mori", Title = "Grove Warden", Ability = "Verdant Pulse", Description = "Restores a little health and damages nearby enemies." },
	{ Name = "Nyx", Title = "Dusk Stalker", Ability = "Nightfall", Description = "A quick strike against the nearest enemy." },
	{ Name = "Aru", Title = "Storm Caller", Ability = "Storm Ring", Description = "Damages every enemy around you." },
}

return Config
