# Generated Beings — co-op base-builder prototype

The current prototype focuses on an open, unwalled home area. Each player starts with a small cabin and one randomly generated being. Roll more beings, assign them as workers to earn coins, and build up your plot with coins and materials. Beings are shown as collectible figures on stands at the front of the plot.

## Play in Studio

From PowerShell:

```powershell
cd C:\Games\AnimeRoguelikeDemo
& 'C:\Games\rojo.exe' serve default.project.json
```

Keep Rojo running, connect the Studio plugin to `127.0.0.1:34872`, then press **Play**. The map is generated when the server starts. The Studio-only **DEV** button grants 5,000 coins, 500 wood, 500 stone, and 100 essence. It is server-checked and does not appear in live servers.

## Current loop

- Start with a simple cabin, 100 coins, and one random common-to-epic being assigned to work.
- Roll additional beings for coins. Higher rarities earn more coins each income tick. Roll cost increases with each being owned.
- Assign or unassign beings to control which ones work. Reserve beings can be absorbed to learn their ability.
- Gather wood, stone, and essence from resource nodes around the home area. Nodes return after 18 seconds. Build and upgrade structures using coins and gathered materials.
- Each server has four personal plots, each with room for up to eight displayed beings.

## Building and resources

The starter cabin is free, cannot be sold, and occupies the center of the plot. The front area is reserved for eight being stands. Other structures can be placed behind the stands using the **BASE** panel (V), then upgraded or sold.

| Building | Effect |
| --- | --- |
| Crystal Mine | +4 / +9 / +15 coins per income tick |
| Barracks | +1 / +2 / +3 worker slots |
| Training Hall | +1 / +2 / +4 coins per worker per tick |
| Recruitment Lodge | -5 / -10 / -15 coins per roll |
| Market | +3 / +6 / +10 coins per income tick |
| Lantern, Garden Tree, Hero Statue | Decorations |

## Controls

Sprint: on-screen button or Left Ctrl. Gather: F near a resource node. Base and roster: **BASE / ROSTER** or B; building panel: **BASE** or V. Combat actions are still present for future world expansion: click/right-click attacks, Shift dash, C movement, Q/E abilities, R ultimate.

## Saving

Coins, wood, stone, essence, roster, learned abilities, and buildings save after a successful DataStore load. Studio saving requires a published place and **Game Settings > Security > Enable Studio Access to API Services**. If DataStore loading fails, progress is not saved that session to protect existing data.

See [PROJECT_STATUS.md](PROJECT_STATUS.md) and [Roblox_Game.txt](Roblox_Game.txt) for the current state and author-signed work history.
