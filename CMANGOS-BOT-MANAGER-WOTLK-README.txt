CMANGOS BOT MANAGER — WOTLK v1.0.2
==================================

WotLK Community Edition
Designed by Tim

DETAIL PANEL FIX
----------------
• The native selected-bot panel is now created before applying the custom UI.
• Custom layout initialization is protected with pcall.
• A layout error can no longer break target-change handling.
• Targeting a friendly player bot immediately opens and queries the panel.
• /botdetail and /botpanel manually open the targeted bot panel.
• Any UI initialization or update error is printed in chat.
• The compact /bot manager remains unchanged.

TEST
----
1. Fully restart the WotLK client.
2. Open /bot and verify the compact manager.
3. Target a friendly party bot.
4. The detailed panel should open immediately.
5. If it does not, type /botdetail while the bot is targeted.
6. Copy any red "CMaNGOS Bot Manager WotLK UI error" message exactly.
