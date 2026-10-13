# Change log

Every entry must be signed with its author: "Codex" or "Claude". Do not attribute one author's changes to the other.

## 2026-10-13 - Floor fixes and walled base

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
