# Generated Beings — co-op Roblox prototype

This is a small playable systems demo for the concept we discussed. It uses simple generated geometry and original placeholder characters; it does not include licensed media characters or final art.

## Prototype loop

- Spawn at the base checkpoint with 100 coins, Kairo assigned as a worker, and Vexa in reserve.
- Assigned characters generate 5 coins every 10 seconds.
- Recruit another random being for 50 coins. Wildlings drop 12 coins and 1 shard.
- Assign beings to the base for income, or move them to reserve and absorb one to permanently learn its ability. Absorption consumes that character.
- Fight through a short connected wilds region with light attack, heavy attack, dash, learned specials, and an ultimate.
- Getting knocked out respawns you at base and keeps you there for 60 seconds. You can still manage your roster while waiting.
- Enemies are shared, so multiple players in the same server can fight together.

## Files

- `default.project.json` — Rojo project mapping
- `src/shared/Config.lua` — recruit and economy settings plus original character catalog
- `src/server/Main.server.lua` — enemies, combat validation, base economy, roster, and knockout lock
- `src/server/WorldBuilder.lua` — generates the map at runtime: floors, walled base, gate, path rails, wilds decoration, and a floor self-check
- `src/client/Main.client.lua` — HUD, roster controls, keyboard/mouse controls, and touch-friendly action buttons

## Open in Roblox Studio

The project is mapped for Rojo. Install both the Rojo CLI and the Rojo Studio plugin. In a terminal, run `cd C:\Games\AnimeRoguelikeDemo` followed by `rojo serve`, leave that terminal open, and connect the Studio plugin to `127.0.0.1:34872`.

After connecting, the Explorer should contain `ReplicatedStorage > Shared > Config`, `ServerScriptService > Main > Main`, and `StarterPlayer > StarterPlayerScripts > Client > Main`. The 3D scene is built by the server script when the game starts, so the edit-mode viewport is empty. Press **Play** to generate the base and wilds; use **Test → Start** with multiple players to try co-op. If the scene is still empty during Play, open **View → Output** and check for a red script error.

Controls: click for basic attack, right-click for heavy attack, Shift to dash, C for the movement leap, Q/E for the first two learned abilities, R for ultimate, and B to open the base roster. The on-screen action bar also works with touch input.

## Base layout

The home island is a walled compound. From the checkpoint plaza (center): the Guild Hall with the roster desk is at the back, five character stations (Kairo, Vexa, Mori, Nyx, Aru) line the east promenade, the Recruitment Shrine and Absorption Altar are on the west side, and the Expedition Gate leads out to the path and wilds. The roster panel (B) works anywhere; the buildings are labelled to show where each action belongs. Invisible rails keep players on the path and inside the wilds. When the map is built, the Output window prints a floor check result.

## Demo limits

This is a first playable blockout, not a production-ready game. Player rosters reset when the server closes; there is no DataStore persistence, boss encounter, polished animation, ability selection UI, or full mobile layout yet. The current combat abilities are small area attacks so the full loop is easy to try. The first starter ability is a simple demonstration skill.
