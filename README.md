# CMaNGOS PlayerBot Addon — Wrath of the Lich King

Enhanced PlayerBot / MangosBot addon for **CMaNGOS WotLK (WoW 3.3.5a)**.

This addon provides an in-game interface for managing and controlling CMaNGOS PlayerBots and includes additional UI and quality-of-life improvements.

> **This branch is for Wrath of the Lich King (3.3.5a).**
>
> Use the branch selector above to select the version matching your CMaNGOS server.

## Available Versions

| Branch | Expansion | WoW Client |
|---|---|---|
| `classic` | Vanilla / Classic | 1.12.1 |
| `tbc` | The Burning Crusade | 2.4.3 |
| `wotlk` | Wrath of the Lich King | 3.3.5a |

## Installation

1. Download the addon from the `wotlk` branch.
2. Extract the downloaded files.
3. Place the `Mangosbot` folder into:

   `World of Warcraft\Interface\AddOns\`

4. The final path should look like:

   `World of Warcraft\Interface\AddOns\Mangosbot\`

5. Start WoW and make sure **Mangosbot** is enabled from the AddOns menu.

## Opening the PlayerBot UI

Use:

`/bot`

to open the standard PlayerBot interface.

The addon also includes an enhanced Bot Manager interface for managing your PlayerBots from a centralized window.

## Enhanced Bot Manager

The enhanced Bot Manager provides quick access to commonly used PlayerBot commands without requiring commands to be entered manually.

Features include:

- Centralized management of your PlayerBots
- Individual bot controls
- Party-wide bot controls
- Combat and behavior controls
- Formation controls
- Follow and stay commands
- Role and strategy controls
- Utility actions
- Loot enable / disable controls
- Quick access to commonly used PlayerBot actions
- Improved organization of PlayerBot commands

The original individual PlayerBot interface remains available alongside the enhanced manager.

## Loot Controls

Loot behavior can be controlled from the Bot Manager as well as from individual bot controls.

This allows loot behavior to be quickly enabled or disabled for your bots without manually entering PlayerBot commands.

## Wrath of the Lich King Support

This version is intended specifically for the CMaNGOS WotLK PlayerBot implementation and the **3.3.5a client**.

WotLK-specific classes and PlayerBot functionality, including **Death Knights**, are supported by the underlying CMaNGOS WotLK PlayerBot system.

## Additional Documentation

Additional information about the enhanced controls and modifications is included with the addon:

- `CMANGOS-BOT-ENHANCED-README.txt`
- `CMANGOS-BOT-MANAGER-README.txt`
- `WOTLK-PORT-NOTES.txt`
- `Addon-Changes.txt`

## Compatibility

This branch is intended for:

- **CMaNGOS WotLK**
- **World of Warcraft 3.3.5a**
- **CMaNGOS PlayerBots / MangosBot**

Do not use this branch with the Classic 1.12.1 or TBC 2.4.3 clients. Use the appropriate repository branch instead.

## Credits

The original MangosBot addon and PlayerBot system come from the CMaNGOS / PlayerBots projects and their contributors.

The enhanced Bot Manager UI and modifications included in this version build upon that existing work.

This repository is maintained to provide convenient, organized access to the Classic, TBC, and WotLK versions of the addon.

This is **not an official CMaNGOS repository**.
