# Generated Beings — co-op Roblox prototype

This is a small playable systems demo for the concept we discussed. It uses simple generated geometry and original placeholder characters; it does not include licensed media characters or final art.

## Prototype loop

- Spawn at the base checkpoint with 100 coins, Kairo assigned as a worker, and Vexa in reserve.
- Assigned characters generate 5 coins every 10 seconds.
- Recruit another random being for 50 coins. Wildlings drop 12 coins and 1 shard.
- Assign beings to the base for income, or move them to reserve and absorb one to permanently learn its ability. Absorption consumes that character.
- Fight through a short connected wilds region with light attack, heavy attack, dash, learned specials, and an ultimate.
- Spend coins and shards in the **Builder Grounds** (behind the Guild Hall, press V) to build your own base: mines, barracks, a forge, an infirmary, a bounty board, and decorations. Buildings give real bonuses and can be upgraded to level 3.
- Getting knocked out respawns you at base and keeps you there for 60 seconds (an Infirmary shortens this). You can still manage your roster and build while waiting.
- Enemies are shared, so multiple players in the same server can fight together.

## Files

- `default.project.json` — Rojo project mapping
- `src/shared/Config.lua` — recruit and economy settings plus original character catalog
- `src/shared/Buildings.lua` — building catalog (costs, levels, effects), plot layout, and the pure placement/bonus rules used by both server and client
- `src/server/Main.server.lua` — enemies, combat validation, base economy, roster, knockout lock, and saving/loading
- `src/server/BaseManager.lua` — base builder: plot claiming, build/upgrade/demolish with server-side validation, bonuses, save data
- `src/server/BuildingModels.lua` — 3D models for each building type and level
- `src/server/PartKit.lua` — shared part-building helpers
- `src/server/PlayerData.lua` — DataStore wrapper (never overwrites saved data after a failed load)
- `src/server/WorldBuilder.lua` — generates the map at runtime: floors, walled base, gate, path rails, wilds decoration, and a floor self-check
- `src/client/Main.client.lua` — HUD, roster controls, keyboard/mouse controls, and touch-friendly action buttons
- `src/client/BuildMode.client.lua` — build panel, grid placement preview, upgrade and sell controls

## Open in Roblox Studio

The project is mapped for Rojo. Install both the Rojo CLI and the Rojo Studio plugin. In a terminal, run `cd C:\Games\AnimeRoguelikeDemo` followed by `rojo serve`, leave that terminal open, and connect the Studio plugin to `127.0.0.1:34872`.

After connecting, the Explorer should contain `ReplicatedStorage > Shared > Config` and `Buildings`, `ServerScriptService > Main` (with `Main`, `WorldBuilder`, `BaseManager`, `BuildingModels`, `PartKit`, `PlayerData`), and `StarterPlayer > StarterPlayerScripts > Client` (with `Main` and `BuildMode`). The 3D scene is built by the server script when the game starts, so the edit-mode viewport is empty. Press **Play** to generate the base and wilds; use **Test → Start** with multiple players to try co-op. If the scene is still empty during Play, open **View → Output** and check for a red script error.

Controls: click for basic attack, right-click for heavy attack, Shift to dash, C for the movement leap, Q/E for the first two learned abilities, R for ultimate, B to open the base roster, and V to open the builder (X stops placing). The on-screen action bar also works with touch input.

## Base layout

The home island is a walled compound. From the checkpoint plaza (center): the Guild Hall with the roster desk is at the back, five character stations (Kairo, Vexa, Mori, Nyx, Aru) line the east promenade, the Recruitment Shrine and Absorption Altar are on the west side, and the Expedition Gate leads out to the path and wilds. The roster panel (B) works anywhere; the buildings are labelled to show where each action belongs. Invisible rails keep players on the path and inside the wilds. When the map is built, the Output window prints a floor check result.

## Base builder

Walk through the **Builder Gate** in the back wall of the base (it leads onto the Builder Grounds). Each player claims one of four plots automatically when they join; your name appears on the plot sign. Press **V** (or the BUILD button), pick a building, then click a green spot on your plot to place it (on touch screens, tap to aim and press Place). The panel also lets you upgrade, sell (50% of coins spent comes back), and teleport to your plot or back to base.

| Building | Max | Effect per level (1 / 2 / 3) |
| --- | --- | --- |
| Crystal Mine (2x2) | 3 | +4 / +9 / +15 coins per income tick |
| Barracks (2x2) | 1 | +1 / +2 / +3 worker slots (base gives 2) |
| Forge (2x2) | 1 | +10% / +20% / +30% damage |
| Infirmary (2x2) | 1 | knockout lock -10s / -20s / -30s (never below 10s) |
| Bounty Board (2x2) | 1 | +3 / +6 / +10 coins per kill |
| Lantern, Garden Tree, Hero Statue (1x1) | 8 / 8 / 4 | decoration only |

Costs and effects live in `src/shared/Buildings.lua`, so balancing is a data edit. The server re-checks every request (position, limits, cost), so the client preview can't be used to cheat.

## Saving

Coins, shards, the roster, learned abilities, and your buildings save automatically (every minute, when you leave, and when the server shuts down). Saved data is only ever written after a successful load, so a DataStore outage can't wipe a player's progress. In Roblox Studio, saving needs the place to be published and **Game Settings > Security > Enable Studio Access to API Services** turned on; without that the game still runs, it just doesn't save, and the Output window says so.

## Demo limits

This is a first playable blockout, not a production-ready game. There is no boss encounter, polished animation, ability selection UI, or full mobile layout yet. The current combat abilities are small area attacks so the full loop is easy to try. The first starter ability is a simple demonstration skill.
