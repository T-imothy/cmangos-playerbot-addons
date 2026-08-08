MANGOSBOT — MANTECH UI v8.6.7
================================

This package is a redesigned CMaNGOS WotLK PlayerBot controller.
It reuses PlayerBot commands supported by the server and presents them through
organized visual controls.

MAIN INTERFACES
---------------
Bot Bar
  Compact party controls: Attack, Follow, Stay, Flee and Reset AI.
  Commands: /botbar, /botbar lock, /botbar unlock, /botbar reset

Bot Manager
  Two-column bot roster with per-bot Login/Logout, Invite/Leave, Summon,
  Whisper and More actions. Includes party-wide Movement, Formation, Combat,
  Utility/Loot and Mana controls plus Refresh and links to Help/Advanced/Bot Bar.
  Commands: /bot, /mbp, /botquick

Individual Bot Manager
  Controls one bot through four tabs: Quick, Combat, Utility and Class.
  Open by clicking a bot card/portrait or ALT-left-clicking a bot.

Advanced Command Center
  Tabs: Tactics, Roles, Move, Form, Target, Behavior, Utility, Mana, Class,
  Character. CLASS and CHARACTER use a live party/raid dropdown so commands
  can be directed to one selected name.
  Command: /botcontrol

CHARACTER / GEAR TOOLS
----------------------
Advanced > CHARACTER includes explicit per-name PlayerBot maintenance actions:
  Random Gear, Enchants, Init Bot
  Learn Spells, Train, Prepare
  Ammo, Food/Drink, Potions, Reagents, Consumables, Pet setup

CHARACTER actions execute immediately with one click. The selected
name must still be in the current party/raid, and the player's own character is
blocked. The dropdown uses the live group roster, so only select actual PlayerBots
for .bot commands.

LOOT / RPG / UTILITY
--------------------
The addon includes general looting plus separate loot-rule toggles for equipment,
quest items, tradeskill items, disenchant items, usable items, vendor items and
trash. RPG behavior includes Quest, Vendor, Explore, Maintenance, Player, Craft
and Battleground modes. Individual controls also expose inventory/info, bank,
equipment, mail, tradeskill, repair, sell, release/revive and related actions
where supported by the server.

STATE / SAFETY
--------------
- Green strategy borders indicate the addon believes the strategy is active.
- Hover buttons for exact command descriptions.
- Refresh Bot Manager when roster or strategy state looks stale.
- CLASS and CHARACTER dropdowns rebuild from the live party/raid roster.
- Mangosbot cannot provide behavior the installed CMaNGOS PlayerBot core does
  not support.

HELP
----
Open the in-game guide with /bothelp or /mangosbothelp, or use the Help buttons
in Bot Manager and Advanced. v8.6.3 includes a full Help audit covering the
current ManTech UI, Advanced tabs, live dropdown behavior and Character/Gear tools.

INSTALL
-------
1. Back up Interface\AddOns\Mangosbot
2. Replace that folder with this package's Mangosbot folder.
3. Log in or /reload.
4. Open /bothelp to review the current controls.

v8.6.3 UI updates
- Help window enlarged to 760x620 with larger title/page/body fonts.
- Help button added directly to the Bot Bar.
- Advanced > UTILITY includes Party Messages: SHOWN/HIDDEN. HIDDEN suppresses the local echo
  of Bot Bar PARTY commands such as Attack while still sending them normally
  to the party so CMaNGOS PlayerBots can react.

v8.6.10-WotLK.2 HELP / CHARACTER + CLASS NOTES
- CLASS and CHARACTER dropdowns are populated from the current live party/raid roster.
- Selecting a bot in CLASS immediately loads controls for that bot's class.
- CHARACTER actions are immediate one-click actions on the selected bot.
- Confirmed CHARACTER tools include Random Gear, Enchants, Init Bot, Learn Spells, Train, Prepare, Ammo, Food/Drink, Potions, Reagents, Consumables, and Pet.
- Random Gear is the supported gear-generation action on this CMaNGOS WotLK build. Upgrade Gear is not supported and has been removed.


DEATH KNIGHT SUPPORT (WotLK)
- CLASS and Advanced CLASS recognize the DEATHKNIGHT class token from the live party/raid roster.
- Blood, Frost and Unholy strategy controls are available.
- Blood is configured as tank-oriented; Frost and Unholy as melee DPS-oriented.
- DK-specific Frost AOE, Unholy AOE, combat buff (bdps), and pull controls are exposed.
- The upstream CMaNGOS WotLK PlayerBots core defines Blood, Frost, Unholy, Frost AOE, Unholy AOE and bdps strategies.


WOTLK EXPANSION NOTES
- Death Knight CLASS support includes Blood, Frost and Unholy modes plus DK AOE/buff/pull controls.
- WotLK retains Arena and Eye of the Storm behavior from TBC and adds Isle of Conquest support.
- The PlayerBot core includes WotLK glyph-management behavior as a non-combat AI feature.
- Mangosbot does not expose an unverified manual Glyph button; glyph behavior remains core/automatic.
