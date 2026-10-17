# Generated Beings — project status

**Date:** 2026-10-17
**Folder:** `C:\Games\AnimeRoguelikeDemo`

## Current state

- One large shared, wall-free starter base with timber frame and entry sign.
- Bright green studded field, red approach path, and spawn plaza.
- A dark belt with 144 thin crosswise steel treads follows rounded corners around the base at 24 studs/second. The client moves idle characters along with it each frame.
- The scrollable shop still has generic text-only placeholder goods. Spin costs 50 test coins, cycles through 15 cards, and awards one of five original Blender-made animal fusions: Capy-gator, Hootfin, Giraffrog, Pengtiger, or Snaxolotl. Wins are counted in the player's inventory.
- Blender source, rendered lineup, and centered FBX exports are in `assets/characters`; import the FBX files in Studio and save them as Roblox Models before wiring their meshes into the live inventory display.
- Players start with 500 coins and earn 10 placeholder coins every 8 seconds. Purchases and spin rewards are counted in `PlaceholderInventory`.
- A backpack button at top-left opens the scrollable inventory with live item counts. The nine-slot hotbar can be selected with 1–9 and filled from inventory.
- Shop sits at left. Spin is a wide, thin white button above the smaller nine-slot hotbar. A coin icon and balance appear adjacent at the top-right without a HUD backing panel. Controls are plain, discreet text at bottom-left.
- Hold Left Shift or Right Shift to sprint. Server sets normal speed to 16 and sprint speed to 24.

## Source map

- `default.project.json` maps `src/server` into ServerScriptService and `src/client` into StarterPlayerScripts.
- `src/server/Main.server.lua` resets old Workspace scenery, builds the map and conveyor, handles sprint, coins, shop validation, and server-picked spin rewards.
- `src/client/Main.client.lua` builds the backpack inventory, smaller nine-slot hotbar, scrollable shop, spin animation, top-right coin counter, discreet controls, Shift input, and client-side conveyor carry.
- `assets/blender/build_animal_fusions.py` builds the five character models, and `assets/characters/README.md` documents the model set and Studio import path.
- `Roblox_Game.txt` and `CHANGELOG.md` keep signed project history.

## Next steps

1. Sync through Rojo on port 34873, stop Play, and press Play again to review the map and UI.
2. Tune the base/conveyor dimensions and UI layout from Studio feedback.
3. Add real placeholder item behavior, then base-building upgrades and the wider co-op loop.

No Blender models are needed for this blockout; the base and UI use Roblox parts and text.
