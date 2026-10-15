# Change log

Every entry must be signed with its author: "Codex" or "Claude". Do not attribute one author's changes to the other.

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
