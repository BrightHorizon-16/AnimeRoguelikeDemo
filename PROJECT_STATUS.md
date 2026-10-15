# Generated Beings — project status

**Date:** 2026-10-15  
**Folder:** `C:\Games\AnimeRoguelikeDemo`

## Current state

- One large shared, wall-free starter base with timber frame and entry sign.
- Bright green studded field, red approach path, and spawn plaza.
- A dark belt with 144 thin crosswise steel treads follows rounded corners around the base at 12 studs/second (twice the earlier speed). The player is carried around its loop.
- Scrollable shop and spin panels use text-only placeholder items. Spin costs 50 test coins, cycles through 15 cards, and the server selects and awards one of 12 possible items.
- Players start with 500 coins and earn 10 placeholder coins every 8 seconds. Purchases and spin rewards are counted in `PlaceholderInventory`.
- A backpack button at top-left opens the scrollable inventory with live item counts. The nine-slot hotbar can be selected with 1–9 and filled from inventory.
- Shop and Spin sit on the left; a coin icon and balance appear at top-right without a HUD backing panel. Controls are plain, discreet text at bottom-left.
- Hold Left Shift or Right Shift to sprint. Server sets normal speed to 16 and sprint speed to 24.

## Source map

- `default.project.json` maps `src/server` into ServerScriptService and `src/client` into StarterPlayerScripts.
- `src/server/Main.server.lua` resets old Workspace scenery, builds the map and conveyor, handles sprint, coins, shop validation, and server-picked spin rewards.
- `src/client/Main.client.lua` builds the backpack inventory, nine-slot hotbar, scrollable shop, spin animation, top-right coin counter, discreet controls, Shift input, and conveyor movement.
- `Roblox_Game.txt` and `CHANGELOG.md` keep signed project history.

## Next steps

1. Sync through Rojo on port 34873, stop Play, and press Play again to review the map and UI.
2. Tune the base/conveyor dimensions and UI layout from Studio feedback.
3. Add real placeholder item behavior, then base-building upgrades and the wider co-op loop.

No Blender models are needed for this blockout; the base and UI use Roblox parts and text.
