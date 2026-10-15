# Generated Beings — project status

**Date:** 2026-10-15
**Folder:** `C:\Games\AnimeRoguelikeDemo`

## Current state

The active prototype is an open, unwalled base area with four personal plots. Each player starts at a small cabin on their own plot with one random being assigned as a worker. Players can roll beings, assign them to earn passive coins, and build/upgrade their plot using coins and materials. Beings appear as generated collectible figures on stands at the front of each plot.

The outer combat route and mob resource drops are not implemented yet. Wood, stone, and essence can be gathered from respawning nodes around the home area. In Roblox Studio, the **DEV** menu also grants test resources. The server exposes and accepts grants only when `RunService:IsStudio()` is true.

## Implemented

- Four plot ownership and player-specific starter cabins.
- Procedurally rolled names, abilities, rarity, and per-being income; roster saves and loads.
- Up to eight displayed beings per plot; assigned beings are marked as working.
- Build, upgrade, and sell using coin, wood, stone, and essence costs.
- Respawning home-area resource nodes award wood, stone, or essence through server-handled prompts.
- Studio-only test resource pack: 5,000 coins, 500 wood, 500 stone, 100 essence.
- Sprint, roster, placement UI, knockout respawn, and DataStore save/load.

## Next steps

1. Open Studio, sync from Rojo, and review cabin spawn points, figure stands, and building placement.
2. Adjust layout based on Studio feedback.
3. Add mob resource drops, then expand co-op combat and the linear overworld.
5. Test multiplayer and saving in a published Studio place with API access enabled.

## Source map

- `src/shared/Config.lua` — being roll pools, rarity, economy, movement.
- `src/shared/Buildings.lua` — costs, effects, plot layout, placement rules.
- `src/server/Main.server.lua` — roster rolls, income, sprint, dev grant validation, combat, saving.
- `src/server/WorldBuilder.lua` — open base map, checkpoint, plot pads, paths.
- `src/server/BaseManager.lua` — plot ownership, stand display models, construction validation.
- `src/server/BuildingModels.lua` and `PartKit.lua` — procedural structure and stand models.
- `src/client/Main.client.lua` — roster, resource HUD, Studio dev menu, sprint, combat controls.
- `src/client/BuildMode.client.lua` — construction panel and placement preview.
- `src/server/PlayerData.lua` — DataStore wrapper.

## Author-signed history

Claude's earlier base, building, and saving work is preserved in `CHANGELOG.md`. The newest work is recorded there as **Codex**. See `Roblox_Game.txt` for the handoff and consolidated history.
