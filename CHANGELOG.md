# Change log

Every entry must be signed with its author: "Codex" or "Claude". Do not attribute one author's changes to the other.

## 2026-10-15 - Builder access and familiar controls

Changed
- Renamed the top-right builder button to **BUILD BASE [B]** so the construction feature is easy to spot; B opens it and V remains available as an alias.
- Added E as the keyboard select/place action during construction; click/tap and the on-screen placement button remain available.
- Changed the resource gathering prompt from F to E.
- Changed sprint to hold Left Shift. Dash remains available from its on-screen button and is now mapped to Q.
- Renamed the roster button to **BEINGS [N]**; mapped learned abilities to number keys 1 and 2 to avoid conflicts with interaction and dash.
- Kept the active world focused on the player's open base plots. There is no tutorial area in the current world generator.
- Updated controls and project handoff notes.

Verification
- Reviewed the source mappings and controls. Not run in Roblox Studio; verify Rojo sync, builder visibility, interaction prompts, and keyboard controls in Play mode.

Signed: Codex

## 2026-10-15 - Starter cabin, being rolls, materials, and Studio dev grant

Added
- Removed the perimeter walls, towers, gate, and Guild Hall from the active map. Every player gets a free Starter Cabin on their plot and spawns at that cabin.
- Randomized being rolls with generated names, abilities, Common/Uncommon/Rare/Epic rarity, rarity-scaled income, and an eight-being cap.
- Procedural being figures on stands at the front of each plot; figures show Working or Reserve state.
- Wood and Stone currencies and material requirements for buildings/upgrades. Shards are presented as Essence.
- Eight respawning resource nodes around the open home area; server-handled F prompts award wood, stone, or essence.
- Studio-only DEV menu and server-checked Build Pack grant: 5,000 coins, 500 wood, 500 stone, and 100 essence.
- Persistence for generated being fields and materials, with migration from old fixed character saves.

Changed
- Players start with one assigned random being, 100 coins, no materials, and a free cabin.
- Roll costs increase by 15 coins for each additional owned being.
- The front three plot rows are reserved for the collectible stands; building placement is behind them.
- Updated README, status, and handoff notes. Mob resource drops remain planned for the future overworld.

Verification
- Reviewed source and project docs. Not yet run in Roblox Studio; verify cabin/stand layout, spawn, dev panel, and construction placement in Play mode.

Signed: Codex

## 2026-10-15 - Base-only focus and sprint controls

Changed
- Reworked `WorldBuilder.lua` into a compact, walled home base with a central checkpoint, Guild Hall, four 8x8-cell home plots, and connecting paths. Removed the overworld route and left enemy spawns empty so development can focus on the base.
- Moved four plots into the corners of the home island and enlarged them from 6x6 to 8x8 cells. Kept the existing plot ownership, save format, and building placement system.
- Rebalanced/reframed base buildings: Crystal Mine and Market generate income, Barracks add worker slots, Training Hall boosts worker income, and Recruitment Lodge discounts recruiting. Building costs now use coins.
- Removed Builder Grounds teleport buttons and tutorial-style directions from the build panel; renamed it MY BASE and simplified placement feedback.
- Added server-authoritative sprint at 24 WalkSpeed (normal speed 16), with an on-screen toggle and Left Ctrl. Character respawn resets sprint.
- Updated README and project status to describe the active base-only scope; restored `Roblox_Game.txt` with current state and signed work history.

Verification
- Reviewed changed client/server code and project descriptions. Not yet run in Roblox Studio; visual layout and client input need a Play-mode review.

Signed: Codex

## 2026-10-15 - Base builder, Builder Grounds, and saving

Added
- Builder Grounds: a terrace behind the Guild Hall (new Builder Gate in the back wall) with four player plots on a 6x6 grid. Plots are claimed automatically on join and released on leave.
- Base builder (`src/server/BaseManager.lua`, `src/client/BuildMode.client.lua`): build, upgrade, and sell buildings with a grid placement preview. All requests are validated on the server.
- Eight buildings in `src/shared/Buildings.lua`: Crystal Mine, Barracks, Forge, Infirmary, Bounty Board, and three decorations. Buildings have 3 levels with visible model changes (`src/server/BuildingModels.lua`).
- Real effects wired into `Main.server.lua`: Crystal Mines add income, Barracks add worker slots (base is now 2, enforced on Assign), Forge adds damage, Infirmary shortens the knockout lock, Bounty Board adds kill coins.
- Saving (`src/server/PlayerData.lua`): coins, shards, roster, learned abilities, and buildings. Never saves after a failed load.
- `src/server/PartKit.lua` (shared part helpers; `WorldBuilder.lua` now uses it).
- HUD: roster header shows workers used/slots; controls list mentions V.

Changed
- `Config.lua`: added KillCoins, KillShards, BaseWorkerSlots, MinKnockoutLockSeconds, SellRefund.
- Knockout message now shows the actual lock length.
- Floor self-check also covers the terrace and every plot.
- Corrected the date on the previous entry (it was logged as 2026-10-13; the work was done 2026-10-15).

Verification
- Luau syntax check passed for all files. The real server scripts were run against a mocked Roblox environment (players, remotes, DataStore, scheduler): 66 checks passed, covering validation of 12 malformed requests, costs, caps, upgrades, bonuses, worker-slot enforcement, plot isolation, save/restore, DataStore failure, and 0 overlapping faces across 199 blocks.
- The client UI (`BuildMode.client.lua`) was syntax-checked only. NOT yet tested in Roblox Studio.

Signed: Claude

## 2026-10-15 - Floor fixes and walled base

Fixed
- Floor flicker (z-fighting): the path's top face was coplanar with, and overlapped, both the island (z 50..55) and the wilds (z 185..230). The path now sits 0.2 studs above its neighbours and overlaps them by 0.5 studs, so there is no flicker and no seam.
- 3 of 6 enemies spawned over empty space (path is only 24 wide) and fell into the void. All spawns now sit on floor.
- 4 of 8 decorative crystals floated beside the path. Crystals now sit on floor with their bases at floor level.

Added
- `src/server/WorldBuilder.lua`: map generation moved out of `Main.server.lua`. `Main.server.lua` now calls `WorldBuilder.build(world, Config)` and reads `WorldBuilder.EnemySpawns`.
- Walled base compound with corner towers, Guild Hall and roster desk, plaza, five character stations, Recruitment Shrine, Absorption Altar, walkways, lamps, and a larger Expedition Gate.
- Invisible rails along the path and around the wilds so dashing or walking off an edge no longer triggers the 60 second knockout lock.
- Runtime floor self-check: raycasts along the whole route and at every enemy spawn, and prints a pass or a warning in the Output window.

Verification
- Luau syntax check passed. Geometry was checked against a mocked Roblox API: 0 coplanar overlapping faces, floor continuous from base to wilds.
- NOT yet tested in Roblox Studio.

Signed: Claude
