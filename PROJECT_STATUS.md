# Generated Beings — project status

**Date:** 2026-10-15  
**Folder:** `C:\Games\AnimeRoguelikeDemo`

## Current state

- One large shared, wall-free starter base with timber frame and entry sign.
- Bright green studded field, red approach path, and spawn plaza.
- Animated conveyor belt segments continuously circulate around the base; the south rail has an opening at the path.
- Scrollable shop and spin panels use text-only placeholder items. Spin costs 50 test coins, cycles through 15 cards, and the server selects and awards one of 12 possible items.
- Players start with 500 coins and earn 10 placeholder coins every 8 seconds. Purchases and spin rewards are counted in `PlaceholderInventory`.
- A scrollable inventory panel shows item names and live counts. A persistent control guide sits at bottom-left.
- The conveyor has a continuous collision deck and carries the local player around the loop, including across the red walkway.
- Hold Left Shift or Right Shift to sprint. Server sets normal speed to 16 and sprint speed to 24.

## Source map

- `default.project.json` maps `src/server` into ServerScriptService and `src/client` into StarterPlayerScripts.
- `src/server/Main.server.lua` resets old Workspace scenery, builds the map and conveyor, handles sprint, coins, shop validation, and server-picked spin rewards.
- `src/client/Main.client.lua` builds the wallet, scrollable shop/inventory, spin animation, bottom-left controls, Shift input, and conveyor movement.
- `Roblox_Game.txt` and `CHANGELOG.md` keep signed project history.

## Next steps

1. Sync through Rojo on port 34873, stop Play, and press Play again to review the map and UI.
2. Tune the base/conveyor dimensions and UI layout from Studio feedback.
3. Add real placeholder item behavior, then base-building upgrades and the wider co-op loop.

No Blender models are needed for this blockout; the base and UI use Roblox parts and text.
