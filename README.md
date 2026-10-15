# Generated Beings — co-op base-builder prototype

The current prototype focuses on an open, unwalled home area. Each player starts with a small cabin and one randomly generated creature. Roll original, toy-like creatures of six rarities, assign them as workers to earn coins, and build up your plot with coins and materials. Every creature gets a distinct procedural model on a display stand.

## Play in Studio

From PowerShell:

```powershell
cd C:\Games\AnimeRoguelikeDemo
& 'C:\Games\rojo.exe' serve default.project.json --port 34873
```

Keep Rojo running, connect the Studio plugin to `127.0.0.1:34873`, then press **Play**. The map is generated when the server starts. The Studio-only **DEV** button grants 5,000 coins, 500 wood, 500 stone, and 100 essence. It is server-checked and does not appear in live servers.

## Current loop

- Start with a simple cabin, 100 coins, and one random creature assigned to work.
- Roll additional creatures for coins. Higher rarities earn more coins each income tick. Roll cost increases with each creature owned.
- Roll odds: Common 55%, Uncommon 28%, Rare 12%, Epic 4%, Legendary 0.9%, Mythic 0.1%.
- Assign or unassign creatures to control which ones work. Reserve creatures can be absorbed to learn their ability.
- Gather wood, stone, and essence from resource nodes around the home area. Nodes return after 18 seconds. Build and upgrade structures using coins and gathered materials.
- Each server has four personal plots, each with room for up to eight displayed creatures.

## Building and resources

The starter cabin is free, cannot be sold, and occupies the center of the plot. The front area is reserved for eight creature stands. Other structures can be placed behind the stands using the clearly labeled **BUILD BASE** button (B), then upgraded or sold. Placement shows a full-size colored hologram: green is valid, red is invalid, with a reason displayed in the placement bar.

| Building | Effect |
| --- | --- |
| Crystal Mine | +4 / +9 / +15 coins per income tick |
| Barracks | +1 / +2 / +3 worker slots |
| Training Hall | +1 / +2 / +4 coins per worker per tick |
| Recruitment Lodge | -5 / -10 / -15 coins per roll |
| Market | +3 / +6 / +10 coins per income tick |
| Lantern, Garden Tree, Hero Statue | Decorations |

## Controls

Movement uses Roblox defaults (WASD and Space). Hold Left Shift to sprint. Press E near a resource node to gather; during building placement, E selects/places the preview. Open the build catalog with **BUILD BASE** or B (V remains an alias). Open the creature roster with **BEINGS** or N. Click/tap also places buildings, and X cancels placement. A plain-text control list at bottom left can be clicked to hide or reopen.

## Saving

Coins, wood, stone, essence, roster, learned abilities, and buildings save after a successful DataStore load. Studio saving requires a published place and **Game Settings > Security > Enable Studio Access to API Services**. If DataStore loading fails, progress is not saved that session to protect existing data.

See [PROJECT_STATUS.md](PROJECT_STATUS.md) and [Roblox_Game.txt](Roblox_Game.txt) for the current state and author-signed work history.
