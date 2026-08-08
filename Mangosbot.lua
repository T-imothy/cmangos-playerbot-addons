local Mangosbot_EventFrame = CreateFrame("Frame")
Mangosbot_EventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_WHISPER")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_ADDON")
Mangosbot_EventFrame:RegisterEvent("CHAT_MSG_SYSTEM")
Mangosbot_EventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
Mangosbot_EventFrame:RegisterEvent("UPDATE")
Mangosbot_EventFrame:RegisterEvent("VARIABLES_LOADED")
Mangosbot_EventFrame:Hide()

function print(s)
    if (s ~= nil) then DEFAULT_CHAT_FRAME:AddMessage(s); else DEFAULT_CHAT_FRAME:AddMessage("nil"); end
end

local ToolBars = {}
local GroupToolBars = {}
local CommandSeparator = "\\\\"
local DropDownMenu_Current = {}
mangosbot_options = {}
local TargetBotOpenRequested = false
local IntegratedBotBar = nil
local AdvancedBotControl = nil
local MangosbotHelpWindow = nil

-- Bot Bar PARTY-message suppression. The command is still sent normally so
-- CMaNGOS PlayerBots receive it; this only hides the local echo in chat.
local MangosbotLastSuppressedPartyText = nil
local MangosbotLastSuppressedPartyTime = 0

local Mangosbot_Original_ChatFrame_OnEvent = ChatFrame_OnEvent
if Mangosbot_Original_ChatFrame_OnEvent then
    ChatFrame_OnEvent = function(event)
        if event == "CHAT_MSG_PARTY" and mangosbot_options and
           mangosbot_options.suppressPartyMessages and
           MangosbotLastSuppressedPartyText and
           arg1 == MangosbotLastSuppressedPartyText and
           arg2 == UnitName("player") and
           (GetTime() - MangosbotLastSuppressedPartyTime) < 3 then
            return
        end
        Mangosbot_Original_ChatFrame_OnEvent(event)
    end
end



local function toggleIcons()
    if (mangosbot_options.nativeIcons == true) then
        mangosbot_options.nativeIcons = false
        DEFAULT_CHAT_FRAME:AddMessage('Mangosbot: Native icons disabled')
    else
        mangosbot_options.nativeIcons = true
        DEFAULT_CHAT_FRAME:AddMessage('Mangosbot: Native icons enabled')
    end
    local isVisible = SelectedBotPanel:IsVisible()
    SelectedBotPanel:Hide()
    SelectedBotPanel = {}
    SelectedBotPanel = CreateSelectedBotPanel();
    if (isVisible) then
        local name = GetUnitName("target")
        local self = GetUnitName("player")
        if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target"))) then
            -- SelectedBotPanel:Hide()
        else
            -- SelectedBotPanel:Show()
            QuerySelectedBot(name)
        end

    end
end

SLASH_BOTICONS1 = "/boticons"
SlashCmdList.BOTICONS = function()
    toggleIcons()
end

function SendBotCommand(text, chat, lang, channel)
    if (chat == "PARTY" and partySize() == 0) then return end
	if (chat == "SAY") then
		SendChatMessage(text, chat, lang, channel) 	
    elseif(chat == "WHISPER") then 
	    --Use \t to SendAddonMessage because in 1.12 it does not have WHISPER channel.
	    SendChatMessage("BOT\t" .. text, chat, lang, channel) 
	else 
	    SendAddonMessage("BOT", text, chat, channel) 
	end
end
function SendBotAddonCommand(text, chat, lang, channel)
    SendBotCommand("#a "..text, chat, lang, channel)
end

function CreateToolBar(frame, y, name, buttons, x, spacing, register)
    if (x == nil) then x = 5 end
    if (spacing == nil) then spacing = 5 end
    if (register == nil) then register = true end

    if (frame.toolbar == nil) then
        frame.toolbar = {}
    end

    local tb = CreateFrame("Frame", "Toolbar" .. name, frame)
    tb:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    tb:SetWidth(frame:GetWidth() - x - 5)
    tb:SetHeight(22)
    tb:SetBackdropColor(0,0,0,1.0)
    tb:SetBackdrop({
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = false, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    tb:SetBackdropBorderColor(0,0,0,1.0)

    tb.buttons = {}
    for key, button in pairs(buttons) do
        local btn = CreateFrame("Button", "Toolbar" .. name .. key, tb)
        btn:SetPoint("TOPLEFT", tb, "TOPLEFT", button["index"] * (22 + spacing), 0)
        btn:SetWidth(20)
        btn:SetHeight(20)
        btn:SetBackdrop({
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = false, tileSize = 16, edgeSize = 2,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
        btn:EnableMouse(true)
        btn:RegisterForClicks("LeftButtonDown")
        btn["tooltip"] = button["tooltip"]
        btn:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(frame, "ANCHOR_TOPLEFT", 0, -frame:GetHeight() - 40)
          GameTooltip:SetText(btn["tooltip"])
          GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        btn["command"] = button["command"]
        btn["emote"] = button["emote"]
        btn["group"] = button["group"]
        btn["handler"] = button["handler"]
        btn["ToolBarButtonOnClick"] = ToolBarButtonOnClick;
        btn:SetScript("OnClick", function()
            btn["ToolBarButtonOnClick"](btn, true)
        end)

        local image = CreateFrame("Frame", "Toolbar" .. name .. key .. "Image", btn)
        image:SetPoint("TOPLEFT", btn, "TOPLEFT", 2, -2)
        image:SetWidth(16)
        image:SetHeight(16)
        image.texture = image:CreateTexture(nil, "BACKGROUND")
        local filename = "classic_temp"
        if (button["icon"] ~= nil) then
            filename = "Interface\\Addons\\Mangosbot\\Images\\" .. button["icon"] .. ".tga"
        end
        if (mangosbot_options.nativeIcons and button["icon_native"] ~= nil) then
            filename = "Interface\\Icons\\" .. button["icon_native"]
        end
        image.texture:SetTexture(filename)
        image.texture:SetAllPoints()
        btn.image = image

        tb.buttons[key] = btn
    end

    frame.toolbar[name] = tb
    if (register) then
        ToolBars[name] = buttons
    end
    return buttons
end

function ClickToolBarButton(toolbar, button)
    local btn = ToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function ClickGroupToolBarButton(toolbar, button)
    local btn = GroupToolBars[toolbar][button];
    ToolBarButtonOnClick(btn, false)
end

function OnKeyBindingDown(button)
    local name = GetUnitName("target")
    local self = GetUnitName("player")
    if (CurrentBot == nil and (name == nil or not UnitExists("target") or UnitIsEnemy("target", "player") or not UnitIsPlayer("target") or name == self)) then
        ClickGroupToolBarButton("group_movement", button)
    else
        ClickToolBarButton("movement", button)
    end
end

function ToolBarButtonOnClick(btn, visual)
    if (btn["handler"] ~= nil) then
        btn["handler"]()
        return
    end

    if (visual) then
      btn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1.0)
    end

    if (btn["emote"] ~= nil) then
        DoEmote(btn["emote"])
    end

    if (btn["group"]) then
        local delay = 0
        local first = true
        local combined = ""
        for key, command in pairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined) SendBotCommand(combined, "PARTY") end, combined)
        if (btn["tooltip"] ~= nil) then
            wait(delay + 1, function(command) SendBotCommand("#a " .. command, "PARTY") end, btn["tooltip"])
        end
    else
        local bot = GetUnitName("target")
        if (bot == nil) then bot = CurrentBot end
        local combined = ""
        for key, command in pairs(btn["command"]) do
            combined = combined..command..CommandSeparator
        end
        combined = string.sub(combined, 1, string.len(combined) - 2)
        wait(0, function(combined, bot) SendBotCommand(combined, "WHISPER", nil, bot) end, combined, bot)
    end
end

function ToggleButton(frame, toolbar, button, toggle, mixed)
    local btn = frame.toolbar[toolbar].buttons[button]
    if (toggle and mixed) then
        btn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1.0)
    elseif (toggle) then
        btn:SetBackdropBorderColor(0.2, 1.0, 0.2, 1.0)
    else
        btn:SetBackdropBorderColor(0, 0, 0, 0.0)
    end
end

function EnablePositionSaving(frame, frameName)
    frame:SetScript("OnMouseDown", function() this:StartMoving() end)
	frame:SetScript("OnMouseUp", function()
            local button = arg1
            local self = frame
            self:StopMovingOrSizing()

            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end

            local opts = frameopts[frameName]
            local from, _, to, x, y = self:GetPoint()

            opts.anchorFrom = from
            opts.anchorTo = to

            if self.is_expanded then
                if opts.anchorFrom == "TOPLEFT" or opts.anchorFrom == "LEFT" or opts.anchorFrom == "BOTTOMLEFT" then
                    opts.offsetx = x
                elseif opts.anchorFrom == "TOP" or opts.anchorFrom == "CENTER" or opts.anchorFrom == "BOTTOM" then
                    opts.offsetx = x - 151/2
                elseif opts.anchorFrom == "TOPRIGHT" or opts.anchorFrom == "RIGHT" or opts.anchorFrom == "BOTTOMRIGHT" then
                    opts.offsetx = x - 151
                end
            else
                opts.offsetx = x
            end
            opts.offsety = y
        end)

	do
		-------------------------------------------------------------------------------
		-- Restore the panel's position on the screen.
		-------------------------------------------------------------------------------
		local function Reset_Position()
            local self = frame
            if (frameopts == nil) then
                frameopts = {}
            end
            if (frameopts[frameName] == nil) then
                frameopts[frameName] = {}
            end
			local opts = frameopts[frameName]
			local FixedOffsetX = opts.offsetx

			self:ClearAllPoints()

			if opts.anchorTo == nil then
                self:SetPoint("CENTER", UIParent, "CENTER")
			else
				self:SetPoint(opts.anchorFrom, UIParent, opts.anchorTo, opts.offsetx, opts.offsety)
			end
		end

		frame:SetScript("OnShow", Reset_Position)
	end	-- do-block
end

function ResizeBotPanel(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame.header:SetWidth(frame:GetWidth())
    frame.header.text:SetWidth(frame.header:GetWidth())
    for toolbarName,toolbar in pairs(ToolBars) do
        frame.toolbar[toolbarName]:SetWidth(frame:GetWidth() - 10)
    end
end


-- ============================================================================
-- CMaNGOS compact /bot interface
-- Reuses the original roster cards, group toolbar frames, buttons, handlers,
-- server state, tooltips, and active green borders.
-- ============================================================================

local CMaNGOSRosterRows = {
    { key = "quickbar", label = "PARTY CONTROLS" },
    { key = "group_movement", label = "MOVEMENT" },
    { key = "group_formation", label = "FORMATION" },
    { key = "group_generic_combat", label = "COMBAT" },
    { key = "group_generic", label = "UTILITY / LOOT" },
    { key = "group_savemana", label = "MANA USE" }
}

function CMaNGOSInitializeBotRoster(frame)
    if frame.mantech ~= nil then return end

    frame.mantech = {}
    frame.mantech.labels = {}

    frame:SetWidth(350)
    frame:SetHeight(300)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left = 8, right = 8, top = 8, bottom = 8 }
    })
    frame:SetBackdropColor(0.04, 0.06, 0.09, 0.96)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -16)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetText("|cffe3b95bCMANGOS BOT MANAGER|r")
    frame.mantech.title = title

    local rosterClose = CreateFrame(
        "Button",
        "CMaNGOSBotRosterCloseButton",
        frame,
        "UIPanelCloseButton"
    )
    rosterClose:SetWidth(32)
    rosterClose:SetHeight(32)
    rosterClose:ClearAllPoints()
    rosterClose:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
    rosterClose:SetFrameLevel(frame:GetFrameLevel() + 20)
    rosterClose:EnableMouse(true)
    rosterClose:Show()
    rosterClose:SetScript("OnClick", function()
        frame:Hide()
    end)
    frame.mantech.close = rosterClose





    local subtitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetFont("Fonts\\FRIZQT__.TTF", 10)
    subtitle:SetText("|cff9ca9bdCommunity Edition  |  Designed by Tim  |  v8.6.2|r")
    frame.mantech.subtitle = subtitle


    local refresh = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    refresh:SetWidth(64)
    refresh:SetHeight(20)
    refresh:SetText("Refresh")
    refresh:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -13)
    refresh:SetScript("OnClick", function()
        UpdateBotList(1)
    end)
    refresh:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Refresh bot roster and current group states")
        GameTooltip:Show()
    end)
    refresh:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.mantech.refresh = refresh

    local botBarNav = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    botBarNav:SetWidth(64)
    botBarNav:SetHeight(22)
    botBarNav:SetHitRectInsets(-5, -5, -4, -4)
    botBarNav:SetText("Bot Bar")
    botBarNav:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -35)
    botBarNav:SetScript("OnClick", function()
        if ToggleIntegratedBotBar then
            ToggleIntegratedBotBar()
        end
    end)
    frame.mantech.botBarNav = botBarNav

    local helpNav = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    helpNav:SetWidth(52)
    helpNav:SetHeight(22)
    helpNav:SetHitRectInsets(-5, -5, -4, -4)
    helpNav:SetText("Help")
    helpNav:SetPoint("RIGHT", botBarNav, "LEFT", -4, 0)
    helpNav:SetScript("OnClick", function()
        if ToggleMangosbotHelp then
            ToggleMangosbotHelp()
        end
    end)
    frame.mantech.helpNav = helpNav

    local advanced = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    advanced:SetWidth(84)
    advanced:SetHeight(22)
    advanced:SetHitRectInsets(-5, -5, -4, -4)
    advanced:SetText("Advanced")
    advanced:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 8)
    advanced:SetScript("OnClick", function()
        if ToggleAdvancedBotControl then
            ToggleAdvancedBotControl()
        end
    end)
    advanced:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText("Advanced Bot Control")
        GameTooltip:AddLine("Expanded party-wide controls for dungeons and raids.", 1, 1, 1)
        GameTooltip:Show()
    end)
    advanced:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame.mantech.advanced = advanced

    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    help:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 13)
    help:SetFont("Fonts\\FRIZQT__.TTF", 9)
    help:SetText("|cff9ca9bdClick bot portrait = details. Green = active.|r")
    frame.mantech.help = help

    local waitingText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    waitingText:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 13)
    waitingText:SetFont("Fonts\\FRIZQT__.TTF", 9)
    waitingText:SetText("")
    frame.mantech.waitingText = waitingText

    for i = 1, 10 do
        local item = frame.items[i]
        item:SetWidth(154)
        item:SetHeight(40)
        item:SetBackdrop({
            bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true,
            tileSize = 16,
            edgeSize = 10,
            insets = { left = 3, right = 3, top = 3, bottom = 3 }
        })
        item:SetBackdropColor(0.025, 0.045, 0.070, 0.92)
        item:SetBackdropBorderColor(0.10, 0.70, 0.75, 0.85)

        item.text:SetWidth(128)
        item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 24, -1)
        item.text:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")

        local tb = item.toolbar["quickbar" .. i]
        tb:SetWidth(120)
        tb:SetHeight(18)
        tb:ClearAllPoints()
        tb:SetPoint("BOTTOMLEFT", item, "BOTTOMLEFT", 23, 2)

        tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 20, 0)
        tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 20, 0)
        tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 40, 0)
        tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 60, 0)
        tb.buttons["menu"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 80, 0)
    end
end

local function CMaNGOSClearRosterLabels(frame)
    if not frame.mantech then return end
    for _, label in ipairs(frame.mantech.labels) do
        label:Hide()
    end
    frame.mantech.labels = {}
end

local function CMaNGOSRosterLabel(frame, text, x, y)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    label:SetFont("Fonts\\FRIZQT__.TTF", 10)
    label:SetText("|cffe3b95b" .. text .. "|r")
    table.insert(frame.mantech.labels, label)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(0.42, 0.34, 0.18, 0.50)
    divider:SetWidth(320)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y - 16)
    table.insert(frame.mantech.labels, divider)

    return label
end

function CMaNGOSApplyBotRosterLayout(frame)
    CMaNGOSInitializeBotRoster(frame)
    CMaNGOSClearRosterLabels(frame)

    local visibleCount = 0
    for i = 1, 10 do
        if frame.items[i]:IsVisible() then
            visibleCount = visibleCount + 1
            local col = mod(visibleCount - 1, 2)
            local row = math.floor((visibleCount - 1) / 2)
            frame.items[i]:ClearAllPoints()
            frame.items[i]:SetPoint(
                "TOPLEFT",
                frame,
                "TOPLEFT",
                16 + (col * 162),
                -58 - (row * 44)
            )
        end
    end

    local rosterRows = math.ceil(visibleCount / 2)
    local controlStartY = -63 - (rosterRows * 44)

    if visibleCount == 0 then
        local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -66)
        empty:SetText("|cff9ca9bdNo bots loaded. Use Refresh after bots are available.|r")
        table.insert(frame.mantech.labels, empty)
        controlStartY = -94
    end

    local shownRows = 0
    for _, rowInfo in ipairs(CMaNGOSRosterRows) do
        local toolbar = frame.toolbar[rowInfo.key]
        if toolbar and toolbar:IsVisible() then
            local y = controlStartY - (shownRows * 34)
            CMaNGOSRosterLabel(frame, rowInfo.label, 18, y)

            toolbar:ClearAllPoints()
            toolbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 116, y + 3)
            toolbar:SetWidth(216)
            toolbar:SetHeight(22)
            toolbar:Show()

            shownRows = shownRows + 1
        end
    end

    local totalHeight = 90 + (rosterRows * 44) + (shownRows * 34)
    if totalHeight < 215 then totalHeight = 215 end
    if totalHeight > 455 then totalHeight = 455 end

    frame:SetWidth(350)
    frame:SetHeight(totalHeight)
end

function ToggleBotManagerWindow()
    if not BotRoster then return end

    if BotRoster:IsVisible() then
        BotRoster:Hide()
    else
        BotRoster.ShowRequest = true
        UpdateBotList(1)
        BotRoster:Show()
        CMaNGOSApplyBotRosterLayout(BotRoster)
    end
end

SLASH_MANGOSBOTQUICK1 = "/mbp"
SLASH_MANGOSBOTQUICK2 = "/botquick"
SlashCmdList["MANGOSBOTQUICK"] = function(msg)
    ToggleBotManagerWindow()
end

function CreateBotRoster()
    local frame = CreateFrame("Frame", "BotRoster", UIParent)
    frame:Hide()
    frame:SetWidth(186)
    frame:SetHeight(175)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0, 0, 0, 1)
    frame:RegisterForDrag("LeftButton")

    EnablePositionSaving(frame, "BotRoster")

    frame.items = {}
    for i = 1,10 do
        local item = CreateFrame("Frame", "BotRoster_Item" .. i, frame)
        item:SetPoint("TOPLEFT", frame, "TOPLEFT", i * 100, 0)
        item:SetWidth(112)
        item:SetHeight(40)
        item:SetBackdropColor(0,0,0,1)
        item:SetBackdrop({
            bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
            edgeFile="Interface/ChatFrame/ChatFrameBackground",
            tile = true, tileSize = 16, edgeSize = 2,
            insets = { left = 2, right = 2, top = 2, bottom = 0 }
        })
        item:SetBackdropBorderColor(0.8,0.8,0.8,1)

        item.text = item:CreateFontString("BotRoster_ItemHeader" .. i)
        item.text:SetPoint("TOPLEFT", item, "TOPLEFT", 20, 1)
        item.text:SetWidth(item:GetWidth())
        item.text:SetHeight(22)
        item.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
        item.text:SetJustifyH("LEFT")
        item.text:SetText("Click!")

        local cls = CreateFrame("Button", "BotRoster_ItemHeader" .. i .. "Image", item)
        cls:SetPoint("TOPLEFT", item, "TOPLEFT", 3, -3)
        cls:SetWidth(16)
        cls:SetHeight(16)
        cls:EnableMouse(true)
        cls:RegisterForClicks("LeftButtonDown")
        cls.texture = cls:CreateTexture(nil, "BACKGROUND")
        cls.texture:SetTexture("Interface\\Addons\\Mangosbot\\Images\\role_dps.tga")
        cls.texture:SetAllPoints()
        cls:SetScript("OnEnter", function(self)
          GameTooltip:SetOwner(item, "ANCHOR_TOPLEFT", 0, -item:GetHeight() - 40)
          GameTooltip:SetText("Bot Control Panel")
          GameTooltip:Show()
        end)
        cls:SetScript("OnLeave", function(self)
          GameTooltip:Hide()
        end)
        item.cls = cls

        CreateToolBar(item, -18, "quickbar"..i, {
            ["login"] = {
                icon = "login",
                command = {[0] = ""},
                strategy = "",
                tooltip = "Bring bot online",
                index = 0
            },
            ["logout"] = {
                icon = "logout",
                command = {[0] = ""},
                tooltip = "Logout bot",
                strategy = "",
                index = 0
            },
            ["invite"] = {
                icon = "invite",
                command = {[0] = ""},
                tooltip = "Invite to your group",
                strategy = "",
                index = 1
            },
            ["leave"] = {
                icon = "leave",
                command = {[0] = ""},
                tooltip = "Remove from group",
                strategy = "",
                index = 1
            },
            ["whisper"] = {
                icon = "whisper",
                command = {[0] = ""},
                tooltip = "Start whisper chat",
                strategy = "",
                index = 2
            },
            ["summon"] = {
                icon = "summon",
                command = {[0] = ""},
                tooltip = "Summon at meeting stone",
                strategy = "",
                index = 3
            },
            ["menu"] = {
                icon = "menu",
                command = {[0] = ""},
                tooltip = "More...",
                strategy = "",
                index = 4
            }   
        }, 20, 0, false)
        local tb = item.toolbar["quickbar"..i]
        tb:SetBackdropBorderColor(0,0,0,0.0)
        tb.buttons["login"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["logout"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 0, 0)
        tb.buttons["invite"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["leave"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 16, 0)
        tb.buttons["whisper"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 48, 0)
        tb.buttons["summon"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 32, 0)
        tb.buttons["menu"]:SetPoint("TOPLEFT", tb, "TOPLEFT", 64, 0)

        item:Hide()
        frame.items[i] = item
        frame.ShowRequest = false
    end

    CreateToolBar(frame, 0, "quickbar", {
        ["login_all"] = {
            icon = "login",
            command = {[0] = ""},
            strategy = "",
            tooltip = "Bring all bots online",
            index = 0
        },
        ["logout_all"] = {
            icon = "logout",
            command = {[0] = ""},
            tooltip = "Logout all bots",
            strategy = "",
            index = 1
        },
        ["invite_all"] = {
            icon = "invite",
            command = {[0] = ""},
            tooltip = "Invite all bots to your group",
            strategy = "",
            index = 2
        },
        ["leave_all"] = {
            icon = "leave",
            command = {[0] = ""},
            tooltip = "Remove all bots from group",
            strategy = "",
            index = 3
        },
        ["summon_all"] = {
            icon = "summon",
            command = {[0] = ""},
            tooltip = "Summon all bots at meeting stone",
            strategy = "",
            index = 4
        }
    }, 5, 0, false)
    frame.toolbar["quickbar"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_movement"] = CreateMovementToolBar(frame, 0, "group_movement", true, 5, 0, false)
    frame.toolbar["group_movement"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_formation"] = CreateFormationToolBar(frame, 0, "group_formation", true, 5, 0, false)
    frame.toolbar["group_formation"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_savemana"] = CreateSaveManaToolBar(frame, 0, "group_savemana", true, 5, 0, false)
    frame.toolbar["group_savemana"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic"] = CreateGenericNonCombatToolBar(frame, 0, "group_generic", true, 5, 0, false)
    frame.toolbar["group_generic"]:SetBackdropBorderColor(0,0,0,0.0)

    GroupToolBars["group_generic_combat"] = CreateGenericCombatToolBar(frame, 0, "group_generic_combat", true, 5, 0, false)
    frame.toolbar["group_generic_combat"]:SetBackdropBorderColor(0,0,0,0.0)

    CMaNGOSInitializeBotRoster(frame)

    return frame
end

function CreateRtiToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "rti_skull",
            command = {[0] = "rti skull"},
            rti = "skull",
            tooltip = "Attack skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "rti_cross",
            command = {[0] = "rti cross"},
            rti = "cross",
            tooltip = "Attack cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "rti_circle",
            command = {[0] = "rti circle"},
            rti = "circle",
            tooltip = "Attack circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "rti_star",
            command = {[0] = "rti star"},
            rti = "star",
            tooltip = "Attack star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "rti_square",
            command = {[0] = "rti square"},
            rti = "square",
            tooltip = "Attack square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "rti_triangle",
            command = {[0] = "rti triangle"},
            rti = "triangle",
            tooltip = "Attack triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "rti_diamond",
            command = {[0] = "rti diamond"},
            rti = "diamond",
            tooltip = "Attack diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "rti_moon",
            command = {[0] = "rti moon"},
            rti = "moon",
            tooltip = "Attack moon mark",
            index = 7,
            group = group
        },
		["rti_none"] = {
            icon = "rti_cross",
            command = {[0] = "rti none"},
            rti = "none",
            tooltip = "Ignore rti marks",
            index = 8,
            group = group
        }
    }, x, spacing, register)
end

function CreateRtiCcToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["rti_skull"] = {
            icon = "cc_skull",
            command = {[0] = "rti cc skull"},
            rti_cc = "skull",
            tooltip = "CC skull mark",
            index = 0,
            group = group
        },
        ["rti_cross"] = {
            icon = "cc_cross",
            command = {[0] = "rti cc cross"},
            rti_cc = "cross",
            tooltip = "CC cross mark",
            index = 1,
            group = group
        },
        ["rti_circle"] = {
            icon = "cc_circle",
            command = {[0] = "rti cc circle"},
            rti_cc = "circle",
            tooltip = "CC circle mark",
            index = 2,
            group = group
        },
        ["rti_star"] = {
            icon = "cc_star",
            command = {[0] = "rti cc star"},
            rti_cc = "star",
            tooltip = "CC star mark",
            index = 3,
            group = group
        },
        ["rti_square"] = {
            icon = "cc_square",
            command = {[0] = "rti cc square"},
            rti_cc = "square",
            tooltip = "CC square mark",
            index = 4,
            group = group
        },
        ["rti_triangle"] = {
            icon = "cc_triangle",
            command = {[0] = "rti cc triangle"},
            rti_cc = "triangle",
            tooltip = "CC triangle mark",
            index = 5,
            group = group
        },
        ["rti_diamond"] = {
            icon = "cc_diamond",
            command = {[0] = "rti cc diamond"},
            rti_cc = "diamond",
            tooltip = "CC diamond mark",
            index = 6,
            group = group
        },
        ["rti_moon"] = {
            icon = "cc_moon",
            command = {[0] = "rti cc moon"},
            rti_cc = "moon",
            tooltip = "CC moon mark",
            index = 7,
            group = group
        },
		["rti_none"] = {
            icon = "cc_cross",
            command = {[0] = "rti cc none"},
            rti_cc = "none",
            tooltip = "Ignore rti marks for CC",
            index = 8,
            group = group
        },
    }, x, spacing, register)
end

function CreateMovementToolBar(frame, y, name, group, x, spacing, register)
    local tb = {
        ["follow_master"] = {
            icon = "follow_master",
            command = {[0] = "#a follow ?"},
            strategy = "follow",
            tooltip = "Follow me",
            index = 0,
            group = group,
            emote = "follow"
        },
        ["stay"] = {
            icon = "stay",
            command = {[0] = "#a stay ?"},
            strategy = "stay",
            tooltip = "Stay in place",
            index = 1,
            group = group,
            emote = "wait"
        },
        ["free"] = {
            icon = "free",
            command = {[0] = "#a free ?"},
            strategy = "free",
            tooltip = "Move around freely",
            index = 2,
            group = group
        }
    }
    local index = 3
    if (not group) then
        tb["runaway"] = {
            icon = "flee",
            command = {[0] = "#a runaway ?"},
            strategy = "runaway",
            tooltip = "Run away from mobs",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["guard"] = {
        icon = "guard",
        command = {[0] = "#a guard ?"},
        strategy = "guard",
        tooltip = "Guard pre-set place",
        index = index,
        group = group
    }
    index = index + 1
		
    if (not group) then		
        tb["grind"] = {
            icon = "grind",
            command = {[0] = "#a nc ~grind, ?"},
            strategy = "grind",
            tooltip = "Aggresive mode (grinding)",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["passive"] = {
        icon = "passive",
        command = {[0] = "#a nc ~passive,?", [1] = "#a co ~passive,?", [2] = "#a reset", [3] = "#a co ?"},
        strategy = "passive",
        tooltip = "Passive mode",
        index = index,
        group = group
    }
    index = index + 1

    tb["flee_passive"] = {
        icon = "flee_passive",
        command = {[0] = "#a flee ?"},
        strategy = "passive",
        tooltip = "Ignore everything and follow master",
        index = index,
        group = group,
        emote = "flee"
    }
    index = index + 1

    if (group) then
        tb["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = index,
            group = group
        }
        index = index + 1
        tb["attack"] = {
            icon = "dps",
            command = {[0] = "#a co -passive,+dps assist", [1] = "#a nc -passive,+dps assist", [2] = "#a @tank co -dps assist,+tank assist", [3] = "#a @tank nc -dps assist,+tank assist", [4] = "#a queue attack"},
            strategy = "",
            tooltip = "Attack my target",
            index = index,
            group = group
        }
        index = index + 1
        tb["tank attack"] = {
            icon = "tank_assist",
            command = {[0] = "#a @dps co -dps assist", [1] = "#a @dps nc -dps assist", [2] = "#a @tank attack"},
            strategy = "",
            tooltip = "tank attack",
            index = index,
            group = group
        }
        index = index + 1
    end

    tb["menu"] = {
            icon = "menu",
            command = {[0] = ""},
            strategy = "",
            tooltip = "More...",
            handler = OpenDropDownMenuForCurrentBot,
            index = index
        }
        index = index + 1

    return CreateToolBar(frame, -y, name, tb, x, spacing, register)
end

function CreateFormationToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "formation_near",
            command = {[0] = "formation near"},
            formation = "near",
            tooltip = "Follow me",
            index = 0,
            group = group
        },
        ["melee"] = {
            icon = "formation_melee",
            command = {[0] = "formation melee"},
            formation = "melee",
            tooltip = "Melee formation",
            index = 1,
            group = group
        },
        ["arrow"] = {
            icon = "formation_arrow",
            command = {[0] = "formation arrow"},
            formation = "arrow",
            tooltip = "Tank first, dps/healer last",
            index = 2,
            group = group
        },
        ["far"] = {
            icon = "formation_far",
            command = {[0] = "formation far"},
            formation = "far",
            tooltip = "Maintain a distance",
            index = 3,
            group = group
        },
        ["chaos"] = {
            icon = "formation_chaos",
            command = {[0] = "formation chaos"},
            formation = "chaos",
            tooltip = "Move freely",
            index = 4,
            group = group
        }
    }, x, spacing, register)
end

function CreateStanceToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["near"] = {
            icon = "stance_near",
            command = {[0] = "stance near"},
            stance = "near",
            tooltip = "Default stance",
            index = 0,
            group = group
        },
        ["tank"] = {
            icon = "stance_tank",
            command = {[0] = "stance tank"},
            stance = "tank",
            tooltip = "Off-tank stance",
            index = 1,
            group = group
        },
        ["turnback"] = {
            icon = "stance_turnback",
            command = {[0] = "stance turnback"},
            stance = "turnback",
            tooltip = "Tank the enemy away from party",
            index = 2,
            group = group
        },
        ["behind"] = {
            icon = "stance_behind",
            command = {[0] = "stance behind"},
            stance = "behind",
            tooltip = "Attack from behind (melee)",
            index = 3,
            group = group
        }
    }, x, spacing, register)
end

function CreateGenericNonCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["food"] = {
            icon = "food",
            command = {[0] = "#a nc ~food,?"},
            strategy = "food",
            tooltip = "Use food and drinks",
            index = 0,
            group = group
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "#a nc ~loot,?"},
            strategy = "loot",
            tooltip = "Enable looting",
            index = 1,
            group = group
        },
        ["gather"] = {
            icon = "gather",
            command = {[0] = "#a nc ~gather,?"},
            strategy = "gather",
            tooltip = "Gather herbs, ore, etc.",
            index = 2,
            group = group
        },
        ["reveal"] = {
            icon = "stats",
            command = {[0] = "#a nc ~reveal,?"},
            strategy = "reveal",
            tooltip = "Reveal gathering nodes",
            index = 3
        },
        ["mount"] = {
            icon = "mount",
            command = {[0] = "#a nc ~mount,?"},
            strategy = "mount",
            tooltip = "Mount up when possible",
            index = 4
        },		
        ["travel"] = {
            icon = "travel",
            command = {[0] = "#a nc ~travel,?"},
            strategy = "travel",
            tooltip = "Move to distant locations",
            index = 5
        }
    }, x, spacing, register)
end

function CreateGenericCombatToolBar(frame, y, name, group, x, spacing, register)
    return CreateToolBar(frame, -y, name, {
        ["potions"] = {
            icon = "potions",
            command = {[0] = "#a react ~potions,?"},
            strategy = "potions",
            tooltip = "Use health and mana potions",
            index = 0,
            group = group
        },
        ["cast_time"] = {
            icon = "cast_time",
            command = {[0] = "#a co ~cast time,?"},
            strategy = "cast time",
            tooltip = "Do not cast long spells on almost dead targets",
            index = 1,
            group = group
        },
        ["mark_rti"] = {
            icon = "mark_rti",
            command = {[0] = "#a co ~mark rti,?"},
            strategy = "mark rti",
            tooltip = "Mark current target with raid icon",
            index = 2,
            group = group
        },
        ["ads"] = {
            icon = "ads",
            command = {[0] = "#a co ~ads,?", [1] = "#a nc ~ads,?"},
            strategy = "ads",
            tooltip = "Flee if ads might be pulled",
            index = 3,
            group = group
        },
        ["conserve_mana"] = {
            icon = "conserve_mana",
            command = {[0] = "#a co ~conserve mana,?"},
            strategy = "conserve mana",
            tooltip = "Reduce mana usage at cost of DPS",
            index = 4,
            group = group
        },
        ["cc"] = {
            icon = "cc",
            command = {[0] = "#a co ~cc,?"},
            strategy = "cc",
            tooltip = "Use crowd control abilities",
            index = 5,
            group = group
        }
    }, x, spacing, register)
end

function CreateSaveManaToolBar(frame, y, name, group, x, spacing, register)
    local buttons = {};
    for i = 1, 5 do
        buttons["savemana"..i] = {
            icon = "savemana"..i,
            command = {[0] = "save mana "..i},
            tooltip = "Save mana level: "..(i>1 and "#"..i or "disabled"),
            index = i - 1,
            group = group,
            savemana = i
        }
    end
    return CreateToolBar(frame, -y, name, buttons, x, spacing, register)
end

function StartChat()
    local editBox = getglobal("ChatFrameEditBox")
    editBox:Show()
    editBox:SetFocus()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
    editBox:SetText("/whisper " .. name .. " ")
end


-- ============================================================================
-- CMaNGOS organized interface
-- Reuses the original MangosBot toolbar frames and buttons. This means the
-- existing server queries, green enabled borders, commands, tooltips, and
-- class-specific state remain the source of truth.
-- ============================================================================

local CMaNGOSTabNames = { "QUICK", "COMBAT", "UTILITY", "CLASS" }

local CMaNGOSToolbarLabels = {
    movement = "Movement",
    actions = "Immediate Actions",
    formation = "Formation",
    stance = "Position / Stance",
    attack_type = "Role / Assist",
    generic_combat = "Combat Strategies",
    savemana = "Mana Conservation",
    rti = "Raid Target",
    ["rti cc"] = "Crowd Control Target",
    inventory = "Inventory / Information",
    loot = "Loot Rules",
    rpg = "RPG Behaviors",
    generic = "General Behaviors",
    CLASS_DRUID = "Druid Role and Abilities",
    CLASS_HUNTER = "Hunter Role and Abilities",
    CLASS_MAGE = "Mage Role and Abilities",
    CLASS_PALADIN = "Paladin Role and Abilities",
    CLASS_PRIEST = "Priest Role and Abilities",
    CLASS_ROGUE = "Rogue Role and Abilities",
    CLASS_SHAMAN = "Shaman Role and Abilities",
    CLASS_WARLOCK = "Warlock Role and Abilities",
    CLASS_WARRIOR = "Warrior Role and Abilities",
    CLASS_PALADIN_BLESSING = "Blessings",
    CLASS_PALADIN_AURA = "Auras",
    CLASS_SHAMAN_TOTEM_EARTH = "Earth Totems",
    CLASS_SHAMAN_TOTEM_FIRE = "Fire Totems",
    CLASS_SHAMAN_TOTEM_WATER = "Water Totems",
    CLASS_SHAMAN_TOTEM_AIR = "Air Totems",
    CLASS_ROGUE_POISON_MAIN = "Main-hand Poisons",
    CLASS_ROGUE_POISON_OFF = "Off-hand Poisons",
    CLASS_WARLOCK_CURSES = "Curses",
    CLASS_WARLOCK_PETS = "Pets",
    CLASS_HUNTER_STINGS = "Stings",
    CLASS_HUNTER_ASPECTS = "Aspects"
}

local CMaNGOSTabs = {
    QUICK = { "movement", "actions", "formation", "stance" },
    COMBAT = { "attack_type", "generic_combat", "savemana", "rti", "rti cc" },
    UTILITY = { "inventory", "loot", "rpg", "generic" }
}

local function CMaNGOSCreateTextButton(parent, name, text, width, click)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetWidth(width)
    button:SetHeight(24)
    button:SetText(text)
    button:SetScript("OnClick", click)
    return button
end

local function CMaNGOSFriendlyClass(class)
    if class == nil then return "Class Controls" end
    local first = string.sub(class, 1, 1)
    local rest = string.lower(string.sub(class, 2))
    return first .. rest .. " Controls"
end

function CMaNGOSInitializeSelectedBotPanel(frame)
    if frame.mantech ~= nil then return end

    frame.mantech = {}
    frame.mantech.currentTab = "QUICK"
    frame.mantech.currentClass = nil
    frame.mantech.sectionLabels = {}
    frame.mantech.tabs = {}

    frame:SetWidth(420)
    frame:SetHeight(315)
    frame.header:SetWidth(420)
    frame.header.text:SetWidth(370)
    frame.header.text:SetPoint("TOPLEFT", frame.header, "TOPLEFT", 26, 0)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -31)
    title:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    title:SetText("|cffe3b95bCMANGOS BOT MANAGER|r")
    frame.mantech.title = title

    local closeButton = CreateFrame(
        "Button",
        "CMaNGOSSelectedBotCloseButton",
        frame,
        "UIPanelCloseButton"
    )
    closeButton:SetWidth(32)
    closeButton:SetHeight(32)
    closeButton:ClearAllPoints()
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 4, 4)
    closeButton:SetFrameLevel(frame:GetFrameLevel() + 20)
    closeButton:EnableMouse(true)
    closeButton:Show()

    closeButton:SetScript("OnClick", function()
        CurrentBot = nil
        LastBot = nil
        frame:Hide()
    end)

    closeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        GameTooltip:SetText("Close selected bot controls")
        GameTooltip:AddLine("Clears the pinned bot selection.", 1, 1, 1)
        GameTooltip:Show()
    end)

    closeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    frame.mantech.closeButton = closeButton


    local help = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    help:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 18, 13)
    help:SetFont("Fonts\\FRIZQT__.TTF", 10)
    help:SetText("|cff9ca9bdGreen border = active. Hover icons for details.|r")
    frame.mantech.help = help

    local oldButton = CMaNGOSCreateTextButton(
        frame,
        "CMaNGOSOpenRosterButton",
        "Bot Roster",
        80,
        function()
            if BotRoster and BotRoster:IsVisible() then
                BotRoster:Hide()
            elseif BotRoster then
                BotRoster:Show()
            elseif SlashCmdList and SlashCmdList.MANGOSBOT then
                SlashCmdList.MANGOSBOT("")
            end
        end
    )
    oldButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -30)
    frame.mantech.rosterButton = oldButton

    local x = 14
    for _, tabName in ipairs(CMaNGOSTabNames) do
        local captured = tabName
        local label = tabName
        local button = CMaNGOSCreateTextButton(
            frame,
            "CMaNGOSTab" .. tabName,
            label,
            66,
            function()
                frame.mantech.currentTab = captured
                if mangosbot_options then
                    mangosbot_options.mantechTab = captured
                end
                CMaNGOSApplySelectedBotLayout(frame, frame.mantech.currentClass)
            end
        )
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -53)
        frame.mantech.tabs[tabName] = button
        x = x + 70
    end

    for toolbarName, toolbarFrame in pairs(frame.toolbar) do
        toolbarFrame:Hide()
    end
end

local function CMaNGOSClearSectionLabels(frame)
    for _, label in pairs(frame.mantech.sectionLabels) do
        label:Hide()
    end
    frame.mantech.sectionLabels = {}
end

local function CMaNGOSAddToolbarRow(frame, toolbarName, row, customLabel)
    local toolbar = frame.toolbar[toolbarName]
    if toolbar == nil then return row end

    local y = -82 - (row * 36)

    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, y)
    label:SetWidth(92)
    label:SetHeight(20)
    label:SetJustifyH("LEFT")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10)
    label:SetText("|cffe3b95b" .. (customLabel or CMaNGOSToolbarLabels[toolbarName] or toolbarName) .. "|r")
    table.insert(frame.mantech.sectionLabels, label)

    local divider = frame:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(0.42, 0.34, 0.18, 0.55)
    divider:SetWidth(390)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 15, y - 17)
    table.insert(frame.mantech.sectionLabels, divider)

    toolbar:ClearAllPoints()
    toolbar:SetPoint("TOPLEFT", frame, "TOPLEFT", 108, y + 1)
    toolbar:SetWidth(292)
    toolbar:SetHeight(22)
    toolbar:Show()

    return row + 1
end

function CMaNGOSApplySelectedBotLayout(frame, class)
    CMaNGOSInitializeSelectedBotPanel(frame)

    frame.mantech.currentClass = class or frame.mantech.currentClass
    if mangosbot_options and mangosbot_options.mantechTab then
        frame.mantech.currentTab = mangosbot_options.mantechTab
    end

    for toolbarName, toolbarFrame in pairs(frame.toolbar) do
        toolbarFrame:Hide()
    end
    CMaNGOSClearSectionLabels(frame)

    for tabName, button in pairs(frame.mantech.tabs) do
        button:Enable()
        if tabName == frame.mantech.currentTab then
            button:SetTextColor(1.0, 0.82, 0.25)
            button:GetNormalTexture():SetVertexColor(0.72, 0.12, 0.08)
        else
            button:SetTextColor(0.80, 0.80, 0.80)
            button:GetNormalTexture():SetVertexColor(0.35, 0.35, 0.35)
        end
    end

    local row = 0
    local tab = frame.mantech.currentTab

    if tab == "CLASS" then
        local classToken = frame.mantech.currentClass
        local classHeading = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        classHeading:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -79)
        classHeading:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
        classHeading:SetText("|cffffffff" .. CMaNGOSFriendlyClass(classToken) .. "|r")
        table.insert(frame.mantech.sectionLabels, classHeading)

        row = 1
        if classToken ~= nil then
            for toolbarName, toolbarFrame in pairs(frame.toolbar) do
                if string.find(toolbarName, "CLASS_") == 1 and
                   string.find(string.sub(toolbarName, 7), classToken) == 1 then
                    row = CMaNGOSAddToolbarRow(frame, toolbarName, row)
                end
            end
        end

        if row == 1 then
            local empty = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -116)
            empty:SetText("|cff9ca9bdTarget a bot and wait for its class information.|r")
            table.insert(frame.mantech.sectionLabels, empty)
        end
    else
        local list = CMaNGOSTabs[tab]
        if list then
            for _, toolbarName in ipairs(list) do
                row = CMaNGOSAddToolbarRow(frame, toolbarName, row)
            end
        end
    end

    -- Size the panel to the active tab instead of leaving a large empty area.
    local contentRows = row
    if contentRows < 1 then contentRows = 1 end

    local compactHeight = 118 + (contentRows * 36)
    if compactHeight < 250 then compactHeight = 250 end
    if compactHeight > 430 then compactHeight = 430 end

    frame:SetWidth(420)
    frame:SetHeight(compactHeight)
    frame.header:SetWidth(420)
    frame.header.text:SetWidth(370)
end

function CreateSelectedBotPanel()
    local frame = CreateFrame("Frame", "SelectedBotPanel", UIParent)
    frame:Hide()
    frame:SetWidth(170)
    frame:SetHeight(155)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Click!")

    frame.header.role = CreateFrame("Frame", "SelectedBotPanelHeaderRole", frame.header)
    frame.header.role:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    frame.header.role:SetWidth(16)
    frame.header.role:SetHeight(16)
    frame.header.role.texture = frame.header.role:CreateTexture(nil, "BACKGROUND")
    frame.header.role.texture:SetTexture("Interface/Addons/Mangosbot/Images/role_dps.tga")
    frame.header.role.texture:SetAllPoints()

    EnablePositionSaving(frame, "SelectedBotPanel")

    local y = 25
    CreateMovementToolBar(frame, y, "movement", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "actions", {
        ["stats"] = {
            icon = "stats",
            command = {[0] = "stats"},
            strategy = "",
            tooltip = "Tell stats (XP, bag space, money, durability)",
            index = 0
        },
        ["whisper"] = {
            icon = "whisper",
            command = {[0] = ""},
            tooltip = "Start whisper chat",
            strategy = "",
            handler = StartChat,
            index = 1
        },
        ["loot"] = {
            icon = "loot",
            command = {[0] = "d add all loot", [1] = "d loot"},
            strategy = "",
            tooltip = "Loot everything",
            index = 2
        },
        ["talk"] = {
            icon = "talk",
            command = {[0] = "talk", [1] = "accept *"},
            strategy = "",
            tooltip = "Talk to nearby NPCs to complete or accept quests",
            index = 3
        },
        ["set_guard"] = {
            icon = "set_guard",
            command = {[0] = "position guard set"},
            strategy = "",
            tooltip = "Set guard position",
            index = 4
        },
        ["release"] = {
            icon = "release",
            command = {[0] = "release"},
            strategy = "",
            tooltip = "Release spirit",
            index = 5
        },
        ["revive"] = {
            icon = "revive",
            command = {[0] = "revive", [1] = "d revive from corpse"},
            strategy = "",
            tooltip = "Revive at Spirit Healer",
            index = 6
        },
        ["sell"] = {
            icon = "sell",
            command = {[0] = "s *"},
            strategy = "",
            tooltip = "Sell grey items",
            index = 7
        },
        ["repair"] = {
            icon = "repair",
            command = {[0] = "repair"},
            strategy = "",
            tooltip = "Repair items",
            index = 8
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "inventory", {
        ["los"] = {
            icon = "los",
            command = {[0] = "los gos"},
            strategy = "",
            tooltip = "Show nearby game objects",
            index = 0
        },
        ["count"] = {
            icon = "count",
            command = {[0] = "c"},
            strategy = "",
            tooltip = "Show inventory",
            index = 1
        },
        ["bank"] = {
            icon = "bank",
            command = {[0] = "bank"},
            strategy = "",
            tooltip = "Show bank",
            index = 2
        },
        ["spells"] = {
            icon = "spells",
            command = {[0] = "spells +"},
            strategy = "",
            tooltip = "Show tradeskill",
            index = 3
        },
        ["equip"] = {
            icon = "equip",
            command = {[0] = "e ?"},
            strategy = "",
            tooltip = "Show equipment",
            index = 4
        },		
        ["mail"] = {
            icon = "mail",
            command = {[0] = "mail ?"},
            strategy = "",
            tooltip = "Show mail",
            index = 4
        },
        ["help"] = {
            icon = "help",
            command = {[0] = "help"},
            strategy = "",
            tooltip = "Help",
            index = 5
        }
    })
	
    y = y + 25
    CreateToolBar(frame, -y, "rpg", {
        ["rpg"] = {
            icon = "rpg",
            command = {[0] = "#a nc ~rpg,?"},
            strategy = "rpg",
            tooltip = "Rpg with nearby npcs",
            index = 0
        },
        ["rpg quest"] = {
            icon = "rpg_quest",
            command = {[0] = "#a nc ~rpg quest,?"},
            strategy = "rpg quest",
            tooltip = "Talk to quest npc's",
            index = 1
        },
        ["rpg vendor"] = {
            icon = "rpg_vendor",
            command = {[0] = "#a nc ~rpg vendor,?"},
            strategy = "rpg vendor",
            tooltip = "Talk to vendors",
            index = 2
        },
        ["rpg explore"] = {
            icon = "rpg_explore",
            command = {[0] = "#a nc ~rpg explore,?"},
            strategy = "rpg explore",
            tooltip = "Talk to inns, flightmasters",
            index = 3
        },
        ["rpg maintenance"] = {
            icon = "rpg_maintenance",
            command = {[0] = "#a nc ~rpg maintenance,?"},
            strategy = "rpg maintenance",
            tooltip = "Talk to armorers, trainers",
            index = 4
        },
        ["rpg player"] = {
            icon = "rpg_player",
            command = {[0] = "#a nc ~rpg player,?"},
            strategy = "rpg player",
            tooltip = "Duel/trade players",
            index = 5
        },
        ["rpg craft"] = {
            icon = "rpg_craft",
            command = {[0] = "#a nc ~rpg craft,?"},
            strategy = "rpg craft",
            tooltip = "Craft items, casts spells",
            index = 6
        },
        ["rpg bg"] = {
            icon = "rpg_bg",
            command = {[0] = "#a nc ~rpg bg,?"},
            strategy = "rpg bg",
            tooltip = "Queue for bg at battlemasters",
            index = 7
        }			
    })	

    y = y + 25
    CreateFormationToolBar(frame, y, "formation", false, 5, 5, true)

    y = y + 25
    CreateStanceToolBar(frame, y, "stance", false, 5, 5, true)

    y = y + 25
    CreateSaveManaToolBar(frame, y, "savemana", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "loot", {
        ["ll_equip"] = {
            icon = "ll_equip",
            command = {[0] = "ll ~equip"},
            loot = "equip",
            tooltip = "Loot equipment upgrades",
            index = 0
        },
        ["ll_qyest"] = {
            icon = "ll_quest",
            command = {[0] = "ll ~quest"},
            loot = "quest",
            tooltip = "Loot quest items",
            index = 1
        },
        ["ll_skill"] = {
            icon = "ll_skill",
            command = {[0] = "ll ~skill"},
            loot = "skill",
            tooltip = "Loot tradeskill items",
            index = 2
        },		
        ["ll_disenchant"] = {
            icon = "ll_disenchant",
            command = {[0] = "ll ~disenchant"},
            loot = "disenchant",
            tooltip = "Loot items for disenchanting",
            index = 3
        },
        ["ll_use"] = {
            icon = "ll_use",
            command = {[0] = "ll ~use"},
            loot = "use",
            tooltip = "Loot consumables/reagents",
            index = 4
        },
        ["ll_vendor"] = {
            icon = "ll_vendor",
            command = {[0] = "ll ~vendor"},
            loot = "vendor",
            tooltip = "Loot items for money",
            index = 5
        },		
        ["ll_trash"] = {
            icon = "ll_trash",
            command = {[0] = "ll ~trash"},
            loot = "trash",
            tooltip = "Loot useless items",
            index = 6
        }
    })

    y = y + 25
    CreateToolBar(frame, -y, "attack_type", {
        ["tank_aoe"] = {
            icon = "tank_assist",
            command = {[0] = "#a nc -dps assist,+tank assist,?", [1] = "#a co -dps assist,+tank assist,?"},
            strategy = "tank assist",
            tooltip = "Grab all aggro or attack Raid Mark",
            index = 0
        },
        ["dps_assist"] = {
            icon = "dps_assist",
            command = {[0] = "#a nc -tank assist,+dps assist,?", [1] = "#a co -tank assist,+dps assist,?"},
            strategy = "dps assist",
            tooltip = "Attack least hp target or Raid Mark",
            index = 1
        },
        ["close"] = {
            icon = "close",
            command = {[0] = "#a co ~close,?"},
            strategy = "close",
            tooltip = "Melee combat",
            index = 2
        },
        ["ranged"] = {
            icon = "ranged",
            command = {[0] = "#a co ~ranged,?"},
            strategy = "ranged",
            tooltip = "Ranged combat",
            index = 3
        },
        ["threat"] = {
            icon = "threat",
            command = {[0] = "#a co ~threat,?"},
            strategy = "threat",
            tooltip = "Keep threat level low",
            index = 4
        },
		["wait_for_attack"] = {
            icon = "wait_for_attack",
            command = {[0] = "#a co ~wait for attack,?"},
            strategy = "wait for attack",
            tooltip = "Wait X seconds before attacking. To change the amount of seconds use 'wait for attack time X'",
            index = 5
        },
		["pull"] = {
            icon = "pull",
            command = {[0] = "#a co ~pull,?"},
            strategy = "pull",
            tooltip = "Set this bot to pull using the 'pull command'. Recommended to only have one bot with pull enabled.",
            index = 6
        },
		["pull back"] = {
            icon = "pull_back",
            command = {[0] = "#a co ~pull back,?"},
            strategy = "pull back",
            tooltip = "Pull back monsters back to the location where the 'pull command' was given.",
            index = 7
        }
    })

    y = y + 25
    CreateRtiToolBar(frame, y, "rti", false, 5, 5, true)

    y = y + 25
    CreateRtiCcToolBar(frame, y, "rti cc", false, 5, 5, true)

    y = y + 25
    CreateGenericNonCombatToolBar(frame, y, "generic", false, 5, 5, true)

    y = y + 25
    CreateGenericCombatToolBar(frame, y, "generic_combat", false, 5, 5, true)

    y = y + 25
    CreateToolBar(frame, -y, "CLASS_DRUID", {
        ["bear"] = {
            icon = "bear",
            icon_native = "ability_racial_bearform",
            command = {[0] = "#a co +tank feral,+close,+pull,+tank assist,-ranged,-stealth,-behind,?", [1] = "#a nc +tank feral,+tank assist,-stealth,?", [2] = "#a de +tank feral,?", [3] = "#a react +tank feral,?"},
            strategy = "tank feral",
            tooltip = "Bear mode (tank)",
            index = 0
        },
        ["cat"] = {
            icon = "cat",
            icon_native = "ability_druid_catform",
            command = {[0] = "#a co +dps feral,+dps assist,+close,+stealth,+behind,-ranged,-pull,?", [1] = "#a nc +dps feral,+dps assist,+stealth,?", [2] = "#a de +dps feral,?", [3] = "#a react +dps feral,?"},
            strategy = "dps feral",
            tooltip = "Cat mode (melee)",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            icon_native = "spell_nature_starfall",
            command = {[0] = "#a co +balance,+dps assist,+ranged,-close,-pull,-stealth,?", [1] = "#a nc +balance,+dps assist,-stealth,?", [2] = "#a de +balance,?", [3] = "#a react +balance,?"},
            strategy = "balance",
            tooltip = "Balance mode (caster)",
            index = 2
        },
        ["heal"] = {
            icon = "heal",
            icon_native = "spell_nature_healingtouch",
            command = {[0] = "#a co +restoration,+dps assist,+ranged,-close,-pull,-stealth,?", [1] = "#a nc +restoration,+dps assist,-stealth,?", [2] = "#a de +restoration,?", [3] = "#a react +restoration,?"},
            strategy = "restoration",
            tooltip = "Restoration mode (healer)",
            index = 3
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 4
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities",
            index = 5
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 6
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (poisons and curses)",
            index = 7
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 8
        },
		["stealth"] = {
            icon = "caster",
            icon_native = "ability_ambush",
            command = {[0] = "#a co ~stealth,?", [1] = "#a nc ~stealth,?"},
            strategy = "stealth",
            tooltip = "Use stealth abilities",
            index = 9
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 10
        }
    })
    CreateToolBar(frame, -y, "CLASS_HUNTER", {
	    ["bm"] = {
            icon = "bear",
            icon_native = "ability_hunter_beasttaming",
            command = {[0] = "#a co +beast mastery,?", [1] = "#a nc +beast mastery,?", [2] = "#a de +beast mastery,?", [3] = "#a react +beast mastery,?"},
            strategy = "beast mastery",
            tooltip = "Beast mastery mode (dps)",
            index = 0
        },
        ["ms"] = {
            icon = "dps",
            icon_native = "ability_marksmanship",
            command = {[0] = "#a co +marksmanship,?", [1] = "#a nc +marksmanship,?", [2] = "#a de +marksmanship,?", [3] = "#a react +marksmanship,?"},
            strategy = "marksmanship",
            tooltip = "Marksmanship mode (dps)",
            index = 1
        },
        ["caster"] = {
            icon = "caster",
            icon_native = "ability_hunter_swiftstrike",
            command = {[0] = "#a co +survival,?", [1] = "#a nc +survival,?", [2] = "#a de +survival,?", [3] = "#a react +survival,?"},
            strategy = "survival",
            tooltip = "Survival mode (dps)",
            index = 2
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
		["stings"] = {
            icon = "dps_debuff",
			icon_native = "trade_brewpoison",
            command = {[0] = "#a co ~sting,?"},
            strategy = "sting",
            tooltip = "Auto pick stings",
            index = 6
        },
		["aspects"] = {
            icon = "arcane",
			icon_native = "spell_nature_ravenform",
            command = {[0] = "#a co ~aspect,?", [1] = "#a nc ~aspect,?"},
            strategy = "aspect",
            tooltip = "Auto pick aspects",
            index = 7
        },
        ["pet"] = {
            icon = "pet",
            icon_native = "ability_hunter_pet_cat",
            command = {[0] = "#a co ~pet,?", [1] = "#a nc ~pet,?"},
            strategy = "pet",
            tooltip = "Use pet",
            index = 8
        }
    })
    CreateToolBar(frame, -y, "CLASS_MAGE", {
        ["arcane"] = {
            icon = "arcane",
            icon_native = "spell_holy_magicalsentry",
            command = {[0] = "#a co +arcane,?", [1] = "#a nc +arcane,?", [2] = "#a de +arcane,?", [3] = "#a react +arcane,?"},
            strategy = "arcane",
            tooltip = "Arcane mode (caster)",
            index = 0
        },
        ["fire"] = {
            icon = "fire",
            icon_native = "spell_fire_flamebolt",
            command = {[0] = "#a co +fire,?", [1] = "#a nc +fire,?", [2] = "#a de +fire,?", [3] = "#a react +fire,?"},
            strategy = "fire",
            tooltip = "Fire mode (caster)",
            index = 1
        },
        ["frost"] = {
            icon = "frost",
            icon_native = "spell_frost_frostbolt02",
            command = {[0] = "#a co +frost,?", [1] = "#a nc +frost,?", [2] = "#a de +frost,?", [3] = "#a react +frost,?"},
            strategy = "frost",
            tooltip = "Frost mode (caster)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 6
        }
    })
    CreateToolBar(frame, -y, "CLASS_PALADIN", {
        ["retribution"] = {
            icon = "dps",
            icon_native = "spell_holy_auraoflight",
            command = {[0] = "#a co +retribution,+dps assist,+close,-ranged,-pull,?", [1] = "#a nc +retribution,+dps assist,?", [2] = "#a de +retribution,?", [3] = "#a react +retribution,?"},
            strategy = "retribution",
            tooltip = "Retribution mode (melee)",
            index = 0
        },
        ["protection"] = {
            icon = "tank",
            icon_native = "spell_holy_devotionaura",
            command = {[0] = "#a co +protection,+close,+pull,+tank assist,-ranged,?", [1] = "#a nc +protection,+tank assist,?", [2] = "#a de +protection,?", [3] = "#a react +protection,?"},
            strategy = "protection",
            tooltip = "Protection mode (tank)",
            index = 1
        },
        ["holy"] = {
            icon = "heal",
            icon_native = "spell_holy_holybolt",
            command = {[0] = "#a co +holy,+ranged,+dps assist,-close,-pull,?", [1] = "#a nc +holy,+dps assist,?", [2] = "#a de +holy,?", [3] = "#a react +holy,?"},
            strategy = "holy",
            tooltip = "Holy mode (healer)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["aura"] = {
            icon = "bmana",
            icon_native = "spell_holy_holyprotection",
            command = {[0] = "#a co ~aura,?", [1] = "#a nc ~aura,?"},
            strategy = "aura",
            tooltip = "Auto pick aura",
            index = 8
        },
		["blessing"] = {
            icon = "bspeed",
            icon_native = "spell_magic_greaterblessingofkings",
            command = {[0] = "#a co ~blessing,?", [1] = "#a nc ~blessing,?"},
            strategy = "blessing",
            tooltip = "Auto pick blessings",
            index = 9
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 10
        }
    })
    CreateToolBar(frame, -y, "CLASS_PRIEST", {
        ["discipline"] = {
            icon = "heal",
            icon_native = "spell_holy_wordfortitude",
            command = {[0] = "#a co +discipline,?", [1] = "#a nc +discipline,?", [2] = "#a de +discipline,?", [3] = "#a react +discipline,?"},
            strategy = "discipline",
            tooltip = "Discipline mode (healer)",
            index = 0
        },
        ["holy"] = {
            icon = "holy",
            icon_native = "spell_holy_holybolt",
            command = {[0] = "#a co +holy,?", [1] = "#a nc +holy,?", [2] = "#a de +holy,?", [3] = "#a react +holy,?"},
            strategy = "holy",
            tooltip = "Holy mode (healer)",
            index = 1
        },
        ["shadow"] = {
            icon = "shadow",
            icon_native = "spell_shadow_shadowwordpain",
            command = {[0] = "#a co +shadow,?", [1] = "#a nc +shadow,?", [2] = "#a de +shadow,?", [3] = "#a react +shadow,?"},
            strategy = "shadow",
            tooltip = "Shadow mode (dps)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (curses)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["offdps"] = {
            icon = "dps",
            command = {[0] = "#a co ~offdps,?", [1] = "#a nc ~offdps,?"},
            strategy = "offdps",
            tooltip = "Use dps abilities to attack enemies while being on healer mode",
            index = 8
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 9
        }
    })
    CreateToolBar(frame, -y, "CLASS_ROGUE", {
        ["combat"] = {
            icon = "dps",
            icon_native = "ability_backstab",
            command = {[0] = "#a co +combat,?", [1] = "#a nc +combat,?", [2] = "#a de +combat,?", [3] = "#a react +combat,?"},
            strategy = "combat",
            tooltip = "Combat mode (melee)",
            index = 0
        },
		["assassination"] = {
            icon = "dps",
            icon_native = "ability_rogue_eviscerate",
            command = {[0] = "#a co +assassination,?", [1] = "#a nc +assassination,?", [2] = "#a de +assassination,?", [3] = "#a react +assassination,?"},
            strategy = "assassination",
            tooltip = "Assassination mode (melee)",
            index = 1
        },
		["subtlety"] = {
            icon = "dps",
            icon_native = "ability_stealth",
            command = {[0] = "#a co +subtlety,?", [1] = "#a nc +subtlety,?", [2] = "#a de +subtlety,?", [3] = "#a react +subtlety,?"},
            strategy = "subtlety",
            tooltip = "Subtlety mode (melee)",
            index = 2
        },
        ["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
		["poisons"] = {
            icon = "caster_aoe",
            icon_native = "trade_brewpoison",
            command = {[0] = "#a co ~poisons,?", [1] = "#a nc ~poisons,?"},
            strategy = "poisons",
            tooltip = "Auto pick poisons",
            index = 6
        },
		["stealth"] = {
            icon = "caster",
            icon_native = "ability_ambush",
            command = {[0] = "#a co ~stealth,?", [1] = "#a nc ~stealth,?"},
            strategy = "stealth",
            tooltip = "Use stealth abilities",
            index = 7
        }
    })
    CreateToolBar(frame, -y, "CLASS_SHAMAN", {
        ["caster"] = {
            icon = "caster",
            icon_native = "spell_nature_lightning",
            command = {[0] = "#a co +elemental,+ranged,-close,?", [1] = "#a nc +elemental,?", [2] = "#a de +elemental,?", [3] = "#a react +elemental,?"},
            strategy = "elemental",
            tooltip = "Elemental mode (caster)",
            index = 0
        },
        ["heal"] = {
            icon = "heal",
            icon_native = "spell_nature_magicimmunity",
            command = {[0] = "#a co +restoration,+threat,+ranged,-close,?", [1] = "#a nc +restoration,?", [2] = "#a de +restoration,?", [3] = "#a react +restoration,?"},
            strategy = "restoration",
            tooltip = "Restoration mode (healer)",
            index = 1
        },
        ["melee"] = {
            icon = "dps",
            icon_native = "spell_nature_lightningshield",
            command = {[0] = "#a co +enhancement,-ranged,+close,?", [1] = "#a nc +enhancement,?", [2] = "#a de +enhancement,?", [3] = "#a react +enhancement,?"},
            strategy = "enhancement",
            tooltip = "Enhancement mode (melee)",
            index = 2
        },
        ["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["cure"] = {
            icon = "cure",
            command = {[0] = "#a co ~cure,?", [1] = "#a nc ~cure,?"},
            strategy = "cure",
            tooltip = "Use cure abilities (poison and disease)",
            index = 6
        },
		["offheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~offheal,?", [1] = "#a nc ~offheal,?"},
            strategy = "offheal",
            tooltip = "Use healing abilities to heal other party members while being in dps mode",
            index = 7
        },
		["totems"] = {
            icon = "totems",
            icon_native = "spell_totem_wardofdraining",
            command = {[0] = "#a co ~totems,?", [1] = "#a nc ~totems,?"},
            strategy = "totems",
            tooltip = "Auto pick totems",
            index = 8
        },
		["preheal"] = {
            icon = "heal",
            command = {[0] = "#a co ~preheal,?"},
            strategy = "preheal",
            tooltip = "Heal the party before receiving melee damage",
            index = 9
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARLOCK", {
        ["affliction"] = {
            icon = "dps",
            icon_native = "spell_shadow_deathcoil",
            command = {[0] = "#a co +affliction,?", [1] = "#a nc +affliction,?", [2] = "#a de +affliction,?", [3] = "#a react +affliction,?"},
            strategy = "affliction",
            tooltip = "Affliction mode (caster)",
            index = 0
        },
        ["demonology"] = {
            icon = "dps",
            icon_native = "spell_shadow_metamorphosis",
            command = {[0] = "#a co +demonology,?", [1] = "#a nc +demonology,?", [2] = "#a de +demonology,?", [3] = "#a react +demonology,?"},
            strategy = "demonology",
            tooltip = "Demonology mode (caster)",
            index = 1
        },
		["destruction"] = {
            icon = "dps",
            icon_native = "spell_shadow_rainoffire",
            command = {[0] = "#a co +destruction,?", [1] = "#a nc +destruction,?", [2] = "#a de +destruction,?", [3] = "#a react +destruction,?"},
            strategy = "destruction",
            tooltip = "Destruction mode (caster)",
            index = 2
        },
		["aoe"] = {
            icon = "aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
        ["dps_debuff"] = {
            icon = "dps_debuff",
			icon_native = "spell_shadow_curseofsargeras",
            command = {[0] = "#a co ~curse,?"},
            strategy = "curse",
            tooltip = "Auto pick curses",
            index = 6
        },
        ["pet"] = {
            icon = "pet",
            icon_native = "spell_shadow_enslavedemon",
            command = {[0] = "#a co ~pet,?", [1] = "#a nc ~pet,?"},
            strategy = "pet",
            tooltip = "Auto pick pets",
            index = 7
        }
    })
    CreateToolBar(frame, -y, "CLASS_WARRIOR", {
        ["arms"] = {
            icon = "dps",
            icon_native = "ability_rogue_eviscerate",
            command = {[0] = "#a co +arms,+dps assist,-pull,?", [1] = "#a nc +arms,+dps assist,?", [2] = "#a de +arms,?", [3] = "#a react +arms,?"},
            strategy = "arms",
            tooltip = "Arms mode (melee)",
            index = 0
        },
        ["fury"] = {
            icon = "grind",
            icon_native = "ability_warrior_innerrage",
            command = {[0] = "#a co +fury,+dps assist,-pull,?", [1] = "#a nc +fury,+dps assist,?", [2] = "#a de +fury,?", [3] = "#a react +fury,?"},
            strategy = "fury",
            tooltip = "Fury mode (melee)",
            index = 1
        },
        ["protection"] = {
            icon = "tank",
            icon_native = "inv_shield_06",
            command = {[0] = "#a co +protection,+tank assist,+pull,?", [1] = "#a nc +protection,+tank assist,?", [2] = "#a de +protection,?", [3] = "#a react +protection,?"},
            strategy = "protection",
            tooltip = "Protection mode (tank)",
            index = 2
        },
		["aoe"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co ~aoe,?", [1] = "#a nc ~aoe,?"},
            strategy = "aoe",
            tooltip = "Use AOE abilities",
            index = 3
        },
        ["bdps"] = {
            icon = "boost",
            command = {[0] = "#a co ~buff,?", [1] = "#a nc ~buff,?"},
            strategy = "buff",
            tooltip = "Use buff abilities (cooldowns, trinkets, buffs)",
            index = 4
        },
		["boost"] = {
            icon = "boost",
            command = {[0] = "#a co ~boost,?", [1] = "#a nc ~boost,?"},
            strategy = "boost",
            tooltip = "Use boost abilities (cooldowns, trinkets)",
            index = 5
        },
    })
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_BLESSING", {
        ["bmana"] = {
            icon = "bmana",
            icon_native = "spell_holy_fistofjustice",
            command = {[0] = "#a co +blessing might,?", [1] = "#a nc +blessing might,?"},
            strategy = "blessing might",
            tooltip = "Blessing of Might",
            index = 0
        },
        ["bhealth"] = {
            icon = "bhealth",
            icon_native = "spell_holy_sealofwisdom",
            command = {[0] = "#a co +blessing wisdom,?", [1] = "#a nc +blessing wisdom,?"},
            strategy = "blessing wisdom",
            tooltip = "Blessing of Wisdom",
            index = 1
        },
        ["bdps"] = {
            icon = "bdps",
            icon_native = "spell_magic_magearmor",
            command = {[0] = "#a co +blessing kings,?", [1] = "#a nc +blessing kings,?"},
            strategy = "blessing kings",
            tooltip = "Blessing of Kings",
            index = 2
        },
        ["barmor"] = {
            icon = "barmor",
            icon_native = "spell_nature_lightningshield",
            command = {[0] = "#a co +blessing sanctuary,?", [1] = "#a nc +blessing sanctuary,?"},
            strategy = "blessing sanctuary",
            tooltip = "Blessing of Sanctuary",
            index = 3
        },
        ["blight"] = {
            icon = "bmana",
            icon_native = "spell_holy_prayerofhealing02",
            command = {[0] = "#a co +blessing light,?", [1] = "#a nc +blessing light,?"},
            strategy = "blessing light",
            tooltip = "Blessing of Light",
            index = 4
        },
        ["bstats"] = {
            icon = "bhealth",
            icon_native = "spell_holy_sealofsalvation",
            command = {[0] = "#a co +blessing salvation,?", [1] = "#a nc +blessing salvation,?"},
            strategy = "blessing salvation",
            tooltip = "Blessing of salvation",
            index = 5
        }
    })
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_EARTH", {
		["stoneclaw"] = {
            icon = "totems",
            icon_native = "spell_nature_stoneclawtotem",
            command = {[0] = "#a co +totem earth stoneclaw,?", [1] = "#a nc +totem earth stoneclaw,?"},
            strategy = "totem earth stoneclaw",
            tooltip = "Stoneclaw totem (earth)",
            index = 0
        },
		["stoneskin"] = {
            icon = "totems",
            icon_native = "spell_nature_stoneskintotem",
            command = {[0] = "#a co +totem earth stoneskin,?", [1] = "#a nc +totem earth stoneskin,?"},
            strategy = "totem earth stoneskin",
            tooltip = "Stoneskin totem (earth)",
            index = 1
        },
		["earthbind"] = {
            icon = "totems",
            icon_native = "spell_nature_strengthofearthtotem02",
            command = {[0] = "#a co +totem earth earthbind,?", [1] = "#a nc +totem earth earthbind,?"},
            strategy = "totem earth earthbind",
            tooltip = "Earthbind totem (earth)",
            index = 2
        },
		["strength"] = {
            icon = "totems",
            icon_native = "spell_nature_earthbindtotem",
            command = {[0] = "#a co +totem earth strength,?", [1] = "#a nc +totem earth strength,?"},
            strategy = "totem earth strength",
            tooltip = "Strength of Earth totem (earth)",
            index = 3
        },
		["tremor"] = {
            icon = "totems",
            icon_native = "spell_nature_tremortotem",
            command = {[0] = "#a co +totem earth tremor,?", [1] = "#a nc +totem earth tremor,?"},
            strategy = "totem earth tremor",
            tooltip = "Tremor totem (earth)",
            index = 4
        }
	})
	CreateToolBar(frame, -y, "CLASS_ROGUE_POISON_MAIN", {
		["deadly"] = {
            icon = "caster_aoe",
            icon_native = "ability_rogue_dualweild",
            command = {[0] = "#a co +poison main deadly,?", [1] = "#a nc +poison main deadly,?"},
            strategy = "poison main deadly",
            tooltip = "Deadly Poison (main hand)",
            index = 0
        },
		["crippling"] = {
            icon = "caster_aoe",
            icon_native = "ability_poisonsting",
            command = {[0] = "#a co +poison main crippling,?", [1] = "#a nc +poison main crippling,?"},
            strategy = "poison main crippling",
            tooltip = "Crippling Poison (main hand)",
            index = 1
        },
		["mind"] = {
            icon = "caster_aoe",
            icon_native = "spell_nature_nullifydisease",
            command = {[0] = "#a co +poison main mind,?", [1] = "#a nc +poison main mind,?"},
            strategy = "poison main mind",
            tooltip = "Mind-Numbing Poison (main hand)",
            index = 2
        },
		["instant"] = {
            icon = "caster_aoe",
            icon_native = "ability_poisons",
            command = {[0] = "#a co +poison main instant,?", [1] = "#a nc +poison main instant,?"},
            strategy = "poison main instant",
            tooltip = "Instant Poison (main hand)",
            index = 3
        },
		["wound"] = {
            icon = "caster_aoe",
            icon_native = "inv_misc_herb_16",
            command = {[0] = "#a co +poison main wound,?", [1] = "#a nc +poison main wound,?"},
            strategy = "poison main wound",
            tooltip = "Wound Poison (main hand)",
            index = 4
        },
		["anesthetic"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison main anesthetic,?", [1] = "#a nc +poison main anesthetic,?"},
            strategy = "poison main anesthetic",
            tooltip = "Anesthetic Poison (main hand)",
            index = 5
        }
	})
	CreateToolBar(frame, -y, "CLASS_WARLOCK_CURSES", {
		["agony"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_curseofsargeras",
            command = {[0] = "#a co +curse agony,?"},
            strategy = "curse agony",
            tooltip = "Curse of Agony",
            index = 0
        },
		["doom"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_auraofdarkness",
            command = {[0] = "#a co +curse doom,?"},
            strategy = "curse doom",
            tooltip = "Curse of Doom",
            index = 1
        },
		["elements"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_chilltouch",
            command = {[0] = "#a co +curse elements,?"},
            strategy = "curse elements",
            tooltip = "Curse of the Elements",
            index = 2
        },
		["recklessness"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_unholystrength",
            command = {[0] = "#a co +curse recklessness,?"},
            strategy = "curse recklessness",
            tooltip = "Curse of Recklessness",
            index = 3
        },
		["weakness"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_curseofmannoroth",
            command = {[0] = "#a co +curse weakness,?"},
            strategy = "curse weakness",
            tooltip = "Curse of Weakness",
            index = 4
        },
		["tongues"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_curseoftounges",
            command = {[0] = "#a co +curse tongues,?"},
            strategy = "curse tongues",
            tooltip = "Curse of Tongues",
            index = 5
        },
		["shadow"] = {
            icon = "caster_aoe",
            icon_native = "spell_shadow_curseofachimonde",
            command = {[0] = "#a co +curse shadow,?"},
            strategy = "curse shadow",
            tooltip = "Curse of Shadow",
            index = 6
        }
	})
	CreateToolBar(frame, -y, "CLASS_HUNTER_STINGS", {
		["serpent"] = {
            icon = "caster_aoe",
            icon_native = "ability_hunter_quickshot",
            command = {[0] = "#a co +sting serpent,?"},
            strategy = "sting serpent",
            tooltip = "Serpent Sting",
            index = 0
        },
		["viper"] = {
            icon = "caster_aoe",
            icon_native = "ability_hunter_aimedshot",
            command = {[0] = "#a co +sting viper,?"},
            strategy = "sting viper",
            tooltip = "Viper Sting",
            index = 1
        },
		["scorpid"] = {
            icon = "caster_aoe",
            icon_native = "ability_hunter_criticalshot",
            command = {[0] = "#a co +sting scorpid,?"},
            strategy = "sting scorpid",
            tooltip = "Scorpid Sting",
            index = 2
        }
	})
    
    y = y + 25
    CreateToolBar(frame, -y, "CLASS_PALADIN_AURA", {
	    ["barmor"] = {
            icon = "barmor",
            icon_native = "spell_holy_devotionaura",
            command = {[0] = "#a co +aura devotion,?", [1] = "#a nc +aura devotion,?"},
            strategy = "aura devotion",
            tooltip = "Devotion aura",
            index = 0
        },
        ["baoe"] = {
            icon = "aoe",
            icon_native = "spell_holy_auraoflight",
            command = {[0] = "#a co +aura retribution,?", [1] = "#a nc +aura retribution,?"},
            strategy = "aura retribution",
            tooltip = "Retribution aura",
            index = 1
        },
		["concentration"] = {
            icon = "bmana",
            icon_native = "spell_holy_mindsooth",
            command = {[0] = "#a co +aura concentration,?", [1] = "#a nc +aura concentration,?"},
            strategy = "aura concentration",
            tooltip = "Concentration aura",
            index = 2
        },
        ["rshadow"] = {
            icon = "rshadow",
            icon_native = "spell_shadow_sealofkings",
            command = {[0] = "#a co +aura shadow,?", [1] = "#a nc +aura shadow,?"},
            strategy = "aura shadow",
            tooltip = "Shadow resistance aura",
            index = 3
        },
        ["rfrost"] = {
            icon = "frost",
            icon_native = "spell_frost_wizardmark",
            command = {[0] = "#a co +aura frost,?", [1] = "#a nc +aura frost,?"},
            strategy = "aura frost",
            tooltip = "Frost resistance aura",
            index = 4
        },
        ["rfire"] = {
            icon = "fire",
            icon_native = "spell_fire_sealoffire",
            command = {[0] = "#a co +aura fire,?", [1] = "#a nc +aura fire,?"},
            strategy = "aura fire",
            tooltip = "Fire resistance aura",
            index = 5
        },
        ["crusader"] = {
            icon = "bspeed",
            icon_native = "spell_holy_crusaderaura",
            command = {[0] = "#a co +aura crusader,?", [1] = "#a nc +aura crusader,?"},
            strategy = "aura crusader",
            tooltip = "Crusader aura",
            index = 6
        },
        ["sanctity"] = {
            icon = "bdps",
            icon_native = "spell_holy_mindvision",
            command = {[0] = "#a co +aura sanctity,?", [1] = "#a nc +aura sanctity,?"},
            strategy = "aura sanctity",
            tooltip = "Sanctity aura",
            index = 7
        }
    })
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_FIRE", {
		["nova"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire nova,?", [1] = "#a nc +totem fire nova,?"},
            strategy = "totem fire nova",
            tooltip = "Fire Nova totem (fire)",
            index = 0
        },
		["flametongue"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire flametongue,?", [1] = "#a nc +totem fire flametongue,?"},
            strategy = "totem fire flametongue",
            tooltip = "Flametongue totem (fire)",
            index = 1
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire resistance,?", [1] = "#a nc +totem fire resistance,?"},
            strategy = "totem fire resistance",
            tooltip = "Frost Resistance totem (fire)",
            index = 2
        },
		["magma"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire magma,?", [1] = "#a nc +totem fire magma,?"},
            strategy = "totem fire magma",
            tooltip = "Magma totem (fire)",
            index = 3
        },
		["searing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem fire searing,?", [1] = "#a nc +totem fire searing,?"},
            strategy = "totem fire searing",
            tooltip = "Searing totem (fire)",
            index = 4
        }
	})
	CreateToolBar(frame, -y, "CLASS_ROGUE_POISON_OFF", {
		["deadly"] = {
            icon = "caster_aoe",
            icon_native = "ability_rogue_dualweild",
            command = {[0] = "#a co +poison off deadly,?", [1] = "#a nc +poison off deadly,?"},
            strategy = "poison off deadly",
            tooltip = "Deadly Poison (off hand)",
            index = 0
        },
		["crippling"] = {
            icon = "caster_aoe",
            icon_native = "ability_poisonsting",
            command = {[0] = "#a co +poison off crippling,?", [1] = "#a nc +poison off crippling,?"},
            strategy = "poison off crippling",
            tooltip = "Crippling Poison (off hand)",
            index = 1
        },
		["mind"] = {
            icon = "caster_aoe",
            icon_native = "spell_nature_nullifydisease",
            command = {[0] = "#a co +poison off mind,?", [1] = "#a nc +poison off mind,?"},
            strategy = "poison off mind",
            tooltip = "Mind-Numbing Poison (off hand)",
            index = 2
        },
		["instant"] = {
            icon = "caster_aoe",
            icon_native = "ability_poisons",
            command = {[0] = "#a co +poison off instant,?", [1] = "#a nc +poison off instant,?"},
            strategy = "poison off instant",
            tooltip = "Instant Poison (off hand)",
            index = 3
        },
		["wound"] = {
            icon = "caster_aoe",
            icon_native = "inv_misc_herb_16",
            command = {[0] = "#a co +poison off wound,?", [1] = "#a nc +poison off wound,?"},
            strategy = "poison off wound",
            tooltip = "Wound Poison (off hand)",
            index = 4
        },
		["anesthetic"] = {
            icon = "caster_aoe",
            command = {[0] = "#a co +poison off anesthetic,?", [1] = "#a nc +poison off anesthetic,?"},
            strategy = "poison off anesthetic",
            tooltip = "Anesthetic Poison (off hand)",
            index = 5
        }
	})
	CreateToolBar(frame, -y, "CLASS_WARLOCK_PETS", {
		["imp"] = {
            icon = "pet",
            icon_native = "spell_shadow_summonimp",
            command = {[0] = "#a co +pet imp,?", [1] = "#a nc +pet imp,?"},
            strategy = "pet imp",
            tooltip = "Use Imp",
            index = 0
        },
		["voidwalker"] = {
            icon = "pet",
            icon_native = "spell_shadow_summonvoidwalker",
            command = {[0] = "#a co +pet voidwalker,?", [1] = "#a nc +pet voidwalker,?"},
            strategy = "pet voidwalker",
            tooltip = "Use Voidwalker",
            index = 1
        },
		["succubus"] = {
            icon = "pet",
            icon_native = "spell_shadow_summonsuccubus",
            command = {[0] = "#a co +pet succubus,?", [1] = "#a nc +pet succubus,?"},
            strategy = "pet succubus",
            tooltip = "Use Succubus",
            index = 2
        },
		["felhunter"] = {
            icon = "pet",
            icon_native = "spell_shadow_summonfelhunter",
            command = {[0] = "#a co +pet felhunter,?", [1] = "#a nc +pet felhunter,?"},
            strategy = "pet felhunter",
            tooltip = "Use Felhunter",
            index = 3
        },
		["felguard"] = {
            icon = "pet",
            icon_native = "spell_shadow_summonfelguard",
            command = {[0] = "#a co +pet felguard,?", [1] = "#a nc +pet felguard,?"},
            strategy = "pet felguard",
            tooltip = "Use Felguard",
            index = 4
        }
	})
		CreateToolBar(frame, -y, "CLASS_HUNTER_ASPECTS", {
		["hawk"] = {
            icon = "totems",
            icon_native = "spell_nature_ravenform",
            command = {[0] = "#a co +aspect hawk,?", [1] = "#a nc +aspect hawk,?"},
            strategy = "aspect hawk",
            tooltip = "Aspect of the Hawk",
            index = 0
        },
		["monkey"] = {
            icon = "totems",
            icon_native = "ability_hunter_aspectofthemonkey",
            command = {[0] = "#a co +aspect monkey,?", [1] = "#a nc +aspect monkey,?"},
            strategy = "aspect monkey",
            tooltip = "Aspect of the Monkey",
            index = 1
        },
		["cheetah"] = {
            icon = "totems",
            icon_native = "ability_mount_jungletiger",
            command = {[0] = "#a co +aspect cheetah,?", [1] = "#a nc +aspect cheetah,?"},
            strategy = "aspect cheetah",
            tooltip = "Aspect of the Cheetah",
            index = 2
        },
		["pack"] = {
            icon = "totems",
            icon_native = "ability_mount_whitetiger",
            command = {[0] = "#a co +aspect pack,?", [1] = "#a nc +aspect pack,?"},
            strategy = "aspect pack",
            tooltip = "Aspect of the Pack",
            index = 3
        },
		["beast"] = {
            icon = "totems",
            icon_native = "ability_mount_pinktiger",
            command = {[0] = "#a co +aspect beast,?", [1] = "#a nc +aspect beast,?"},
            strategy = "aspect beast",
            tooltip = "Aspect of the Beast",
            index = 4
        },
		["wild"] = {
            icon = "totems",
            icon_native = "spell_nature_protectionformnature",
            command = {[0] = "#a co +aspect wild,?", [1] = "#a nc +aspect wild,?"},
            strategy = "aspect wild",
            tooltip = "Aspect of the Wild",
            index = 5
        },
		["viper"] = {
            icon = "totems",
            icon_native = " ability_hunter_aspectoftheviper",
            command = {[0] = "#a co +aspect viper,?", [1] = "#a nc +aspect viper,?"},
            strategy = "aspect viper",
            tooltip = "Aspect of the Viper",
            index = 6
        },
		["dragonhawk"] = {
            icon = "totems",
            icon_native = " ability_hunter_pet_dragonhawk",
            command = {[0] = "#a co +aspect dragonhawk,?", [1] = "#a nc +aspect dragonhawk,?"},
            strategy = "aspect dragonhawk",
            tooltip = "Aspect of the Dragonhawk",
            index = 7
        }
	})
	
	y = y + 25
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_WATER", {
		["cleansing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water cleansing,?", [1] = "#a nc +totem water cleansing,?"},
            strategy = "totem water cleansing",
            tooltip = "Cleansing totem (water)",
            index = 0
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water resistance,?", [1] = "#a nc +totem water resistance,?"},
            strategy = "totem water resistance",
            tooltip = "Fire Resistance totem (water)",
            index = 1
        },
		["healing"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water healing,?", [1] = "#a nc +totem water healing,?"},
            strategy = "totem water healing",
            tooltip = "Healing Stream totem (water)",
            index = 2
        },
		["mana"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water mana,?", [1] = "#a nc +totem water mana,?"},
            strategy = "totem water mana",
            tooltip = "Mana Spring totem (water)",
            index = 3
        },
		["poison"] = {
            icon = "totems",
            command = {[0] = "#a co +totem water poison,?", [1] = "#a nc +totem water poison,?"},
            strategy = "totem water poison",
            tooltip = "Poison Cleansing totem (water)",
            index = 4
        }
	})
	
	y = y + 25
	CreateToolBar(frame, -y, "CLASS_SHAMAN_TOTEM_AIR", {
		["grace"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air grace,?", [1] = "#a nc +totem air grace,?"},
            strategy = "totem air grace",
            tooltip = "Grace of Air totem (air)",
            index = 0
        },
		["grounding"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air grounding,?", [1] = "#a nc +totem air grounding,?"},
            strategy = "totem air grounding",
            tooltip = "Grounding totem (air)",
            index = 1
        },
		["resistance"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air resistance,?", [1] = "#a nc +totem air resistance,?"},
            strategy = "totem air resistance",
            tooltip = "Nature Resistance totem (air)",
            index = 2
        },
		["tranquil"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air tranquil,?", [1] = "#a nc +totem air tranquil,?"},
            strategy = "totem air tranquil",
            tooltip = "Tranquil Air totem (air)",
            index = 3
        },
		["windfury"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air windfury,?", [1] = "#a nc +totem air windfury,?"},
            strategy = "totem air windfury",
            tooltip = "Windfury totem (air)",
            index = 4
        },
		["windwall"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air windwall,?", [1] = "#a nc +totem air windwall,?"},
            strategy = "totem air windwall",
            tooltip = "Windwall totem (air)",
            index = 5
        },
		["wrath"] = {
            icon = "totems",
            command = {[0] = "#a co +totem air wrath,?", [1] = "#a nc +totem air wrath,?"},
            strategy = "totem air wrath",
            tooltip = "Wrath of Air totem (air)",
            index = 6
        }
	})

    frame:SetHeight(y + 25)

    -- Replace the original tall toolbar stack with the organized ManTech
    -- layout. The original toolbar frames and button objects are reused.
    CMaNGOSInitializeSelectedBotPanel(frame)
    CMaNGOSApplySelectedBotLayout(frame, nil)

    return frame
end

function SetFrameColor(frame, class)
    local color = RAID_CLASS_COLORS[class]
    if (color == nil) then
        color = {r = 0.5, g = 0.1, b = 0.7};
    end
    frame:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropColor(color.r, color.g, color.b, 1.0)
    frame.header:SetBackdropBorderColor(color.r, color.g, color.b, 1.0)
end

local total = 0
function BotDebugTimer(self, elapsed)
    local elapsed = arg1
    if (elapsed) then
        total = total + elapsed
        if total >= 1 then
            local name = GetUnitName("target")
            if (name) then
                SendBotAddonCommand("debug action", "WHISPER", nil, name)
            end
            total = 0
        end
    end
end

local actionHistory = {}
local MaxDebugLines = 60
function CreateBotDebugPanel()
    local frame = CreateFrame("Frame", "BotDebugPanel", UIParent)
    frame:Hide()
    frame:SetWidth(300)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetBackdropColor(0, 0, 0, 1.0)
    frame:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 2,
        insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    frame:SetBackdropBorderColor(0.5,0.1,0.7,1)
    frame:RegisterForDrag("LeftButton")

    frame.header = CreateFrame("Frame", "SelectedBotPanelHeader", frame)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.header:SetWidth(frame:GetWidth())
    frame.header:SetHeight(22)
    frame.header:SetBackdropColor(0.5,0.1,0.7,1)
    frame.header:SetBackdrop({
        bgFile = "Interface/DialogFrame/UI-DialogBox-Background",
        edgeFile="Interface/ChatFrame/ChatFrameBackground",
        tile = true, tileSize = 16, edgeSize = 0,
        insets = { left = 2, right = 2, top = 2, bottom = 0 }
    })
    frame.header:SetBackdropBorderColor(0.5,0.1,0.7,1)

    frame.header.text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
    frame.header.text:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, 0)
    frame.header.text:SetWidth(frame.header:GetWidth())
    frame.header.text:SetHeight(22)
    frame.header.text:SetFont("Fonts/FRIZQT__.TTF", 11, "OUTLINE")
    frame.header.text:SetJustifyH("LEFT")
    frame.header.text:SetText("Debug Info")

    local lineSize = 12
    for i = 1,MaxDebugLines do
        local text = frame.header:CreateFontString("SelectedBotPanelHeaderText")
        text:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -5 -i * lineSize)
        text:SetWidth(frame:GetWidth())
        text:SetHeight(18)
        text:SetFont("Fonts/FRIZQT__.TTF", 9, "OUTLINE")
        text:SetJustifyH("LEFT")
        text:SetText("Line"..i)
        frame["text"..i] = text

        actionHistory[i] = ""
    end
    frame:SetHeight(MaxDebugLines * lineSize + 30)

    EnablePositionSaving(frame, "BotDebugPanel")

    frame:SetScript("OnUpdate", BotDebugTimer)

    return frame
end

function UpdateBotDebugPanel(message, sender)
    local splitted = splitString2(message, "|")
    local length = tablelength(splitted)
    local filtered = {}
    for i = 1, length do
        local row = splitted[i];
        if (string.find(row, BotDebugFilter)) then
            table.insert(filtered, row)
        end
    end
    
    length = tablelength(filtered)
    BotDebugPanel.header.text:SetText("Debug Info "..length..", Filter: "..BotDebugFilter)
    
    if (length > MaxDebugLines) then length = MaxDebugLines end

    local first = MaxDebugLines - length + 1

    for i = 1, first-1 do
        local line = BotDebugPanel["text"..i]
        local source = BotDebugPanel["text"..(length + i)]
        line:SetText(source:GetText())
    end

    for i = first, MaxDebugLines do
        local idx = i - first + 1
        local name = trim2(filtered[idx])
        local line = BotDebugPanel["text"..i]
        line:SetText(name)
    end
end

function createDropdown(opts)
    local dropdown_name = opts['name'] .. '_dropdown'
    local menu_items = opts['items'] or {}
    local title_text = opts['title'] or ''
    local dropdown_width = 0
    local default_val = opts['defaultVal'] or ''
    local change_func = opts['changeFunc'] or function (dropdown_val) end
    local dropdown = CreateFrame("Frame", dropdown_name, opts['prnt'], "UIDropDownMenuTemplate")

    local dd_title = dropdown:CreateFontString(dropdown, 'OVERLAY', 'GameFontNormal')
    dd_title:SetPoint("TOPLEFT", 20, 10)

    for _, item in pairs(menu_items) do -- Sets the dropdown width to the largest item string width.
        dd_title:SetText(item)
        local text_width = dd_title:GetStringWidth() + 20
        if text_width > dropdown_width then
            dropdown_width = text_width
        end
    end

    dropdown:SetWidth(dropdown_width)
    getglobal(dropdown:GetName().."Text"):SetText(default_val)
    dd_title:SetText(title_text)
    dd_title:Hide()
    dropdown:Hide()

    UIDropDownMenu_Initialize(dropdown, function(self, level, _)
        local info = {}
        for key, val in pairs(menu_items) do
            info.text = val .. "...";
            info.checked = false
            info.menuList= key
            info.hasArrow = false
            info.justifyH = "LEFT"
            info.func = change_func
            UIDropDownMenu_AddButton(info)
        end
    end, "MENU")

    return dropdown
end

local MenuForBot = nil
BotMenuItems_Current = {
    [1] = "Accept quests",
    [2] = "Talk to quest giver",
    [3] = "Choose quest reward [item]",
    [4] = "Show taxi paths",
    [5] = "Bind to innkeeper",
    [6] = "Learn from trainer",
    [7] = "Send me an [item]",
    [8] = "Toggle loot +/-[item]",
    [9] = "Toggle +/-[spell]",
    [10] = "Make me party leader",
}
BotMenuCommands_Current = {
    [1] = "accept *",
    [2] = "d talk to quest giver",
    [3] = "r ",
    [4] = "taxi ?",
    [5] = "home",
    [6] = "trainer learn",
    [7] = "sendmail ",
    [8] = "ll ",
    [9] = "ss ",
    [10] = "give leader",
}
function CreateDropDownMenu(menu_name, menu_title, menu_items, menu_commands, parent)
    local opts = {
        ['name']=menu_name,
        ['prnt']=parent,
        ['title']=menu_title,
        ['items']=menu_items,
        ['defaultVal']='', 
        ['changeFunc']=function()
            local editBox = getglobal("ChatFrameEditBox")
            local id = this:GetID()
            editBox:Show()
            editBox:SetFocus()
            editBox:SetText("/whisper " .. MenuForBot .. " " .. menu_commands[id])
        end
    }
    local menu = createDropdown(opts)
    HideDropDownMenu(1)
    return menu
end

function OpenDropDownMenuForCurrentBot()
    local name = GetUnitName("target")
    if (name == nil) then name = CurrentBot end
    OpenDropDownMenu(DropDownMenu_Current, name)
end

function OpenDropDownMenu(dropDownMenu, bot)
    local scale,x,y=BotRoster:GetEffectiveScale(),GetCursorPosition();
    dropDownMenu:SetPoint("CENTER",nil,"BOTTOMLEFT",x/scale,y/scale);
    MenuForBot = bot
    ToggleDropDownMenu(1, nil, dropDownMenu, 'cursor')
end

botTable = {}
SelectedBotPanel = {}
BotRoster = CreateBotRoster();
BotDebugPanel = CreateBotDebugPanel();
DropDownMenu_Current = CreateDropDownMenu("more", "More", BotMenuItems_Current, BotMenuCommands_Current, BotRoster)
CurrentBot = nil
LastBot = nil
BotDebugFilter = ""

local function fmod(a,b)
    return a - math.floor(a/b)*b
end

-- ---------------------------------------------------------------------------
-- Advanced Bot Command Center
-- Uses the command/strategy vocabulary already present in this Mangosbot build.
-- It does not add new PlayerBot behaviors; it exposes existing ones in a
-- raid/dungeon oriented control surface.
-- ---------------------------------------------------------------------------

local CMaNGOSAdvancedTabs = {
    "TACTICS", "ROLES", "MOVE", "FORM", "TARGET", "BEHAVIOR", "UTILITY", "MANA", "CLASS", "CHARACTER"
}

local CMaNGOSAdvancedData = {
    TACTICS = {
        {
            label = "GROUP ORDERS",
            buttons = {
                { key="attack", icon="dps", tip="Same immediate PARTY attack command you can type manually",
                  partyChat="attack", commands={} },
                { key="tankattack", icon="tank_assist", tip="Tank attacks while DPS assist is temporarily removed",
                  commands={"#a @dps co -dps assist","#a @dps nc -dps assist","#a @tank attack"} },
                { key="passive", icon="passive", tip="Toggle passive behavior for the group",
                  commands={"#a nc ~passive,?","#a co ~passive,?","#a reset","#a co ?"} },
                { key="flee", icon="flee_passive", tip="Disengage and return to master",
                  commands={"#a flee ?"} },
                { key="reset", native="INV_Misc_PocketWatch_01", tip="Reset bot AI state",
                  commands={"#a reset"} },
            }
        },
        {
            label = "ENGAGEMENT",
            buttons = {
                { key="wait", icon="wait_for_attack", tip="Toggle wait-for-attack strategy",
                  commands={"#a co ~wait for attack,?"} },
                { key="pull", icon="pull", tip="Toggle pull strategy. Existing addon recommends only one pull bot.",
                  commands={"#a co ~pull,?"} },
                { key="pullback", icon="pull_back", tip="Toggle pull-back strategy",
                  commands={"#a co ~pull back,?"} },
                { key="threat", icon="threat", tip="Toggle low-threat behavior",
                  commands={"#a co ~threat,?"} },
                { key="mark", icon="mark_rti", tip="Toggle automatic raid-target marking",
                  commands={"#a co ~mark rti,?"} },
                { key="avoidadds", icon="ads", tip="Toggle avoiding additional pulls",
                  commands={"#a co ~ads,?","#a nc ~ads,?"} },
            }
        }
    },

    ROLES = {
        {
            label = "ASSIST / ROLE BEHAVIOR",
            buttons = {
                { key="tankassist", icon="tank_assist", tip="Tank Assist: grab aggro or attack the assigned Raid Mark",
                  commands={"#a nc -dps assist,+tank assist,?","#a co -dps assist,+tank assist,?"} },
                { key="dpsassist", icon="dps_assist", tip="DPS Assist: attack least-HP target or assigned Raid Mark",
                  commands={"#a nc -tank assist,+dps assist,?","#a co -tank assist,+dps assist,?"} },
                { key="close", icon="close", tip="Toggle melee/close combat positioning",
                  commands={"#a co ~close,?"} },
                { key="ranged", icon="ranged", tip="Toggle ranged combat positioning",
                  commands={"#a co ~ranged,?"} },
                { key="threat", icon="threat", tip="Toggle low-threat behavior",
                  commands={"#a co ~threat,?"} },
            }
        },
        {
            label = "HEAL / SUPPORT",
            buttons = {
                { key="offheal", icon="heal", tip="Allow DPS-mode heal-capable bots to off-heal",
                  commands={"#a co ~offheal,?","#a nc ~offheal,?"} },
                { key="offdps", icon="dps", tip="Allow healer-mode bots to contribute DPS",
                  commands={"#a co ~offdps,?","#a nc ~offdps,?"} },
                { key="preheal", icon="heal", tip="Pre-heal before incoming melee damage",
                  commands={"#a co ~preheal,?"} },
                { key="cure", icon="cure", tip="Use cure/cleanse abilities",
                  commands={"#a co ~cure,?","#a nc ~cure,?"} },
                { key="buff", icon="boost", tip="Use buff abilities",
                  commands={"#a co ~buff,?","#a nc ~buff,?"} },
                { key="boost", icon="boost", tip="Use boost/cooldown abilities",
                  commands={"#a co ~boost,?","#a nc ~boost,?"} },
            }
        }
    },

    MOVE = {
        {
            label = "MOVEMENT",
            buttons = {
                { key="follow", icon="follow_master", tip="Follow master", commands={"#a follow ?"} },
                { key="stay", icon="stay", tip="Stay in place", commands={"#a stay ?"} },
                { key="free", icon="free", tip="Move freely", commands={"#a free ?"} },
                { key="guard", icon="guard", tip="Guard the preset guard position", commands={"#a guard ?"} },
                { key="flee", icon="flee_passive", tip="Ignore combat and return to master", commands={"#a flee ?"} },
            }
        }
    },

    FORM = {
        {
            label = "FORMATION",
            buttons = {
                { key="near", icon="formation_near", tip="Near formation", commands={"#a formation near"} },
                { key="melee", icon="formation_melee", tip="Melee formation", commands={"#a formation melee"} },
                { key="arrow", icon="formation_arrow", tip="Arrow formation: tank first, DPS/healers behind", commands={"#a formation arrow"} },
                { key="far", icon="formation_far", tip="Far formation", commands={"#a formation far"} },
                { key="chaos", icon="formation_chaos", tip="Chaos/free formation", commands={"#a formation chaos"} },
            }
        }
    },

    TARGET = {
        {
            label = "RAID TARGET",
            marker = true,
            buttons = {
                { key="rti_skull", icon="rti_skull", tip="Raid target: Skull", commands={"#a rti skull"} },
                { key="rti_cross", icon="rti_cross", tip="Raid target: Cross", commands={"#a rti cross"} },
                { key="rti_circle", icon="rti_circle", tip="Raid target: Circle", commands={"#a rti circle"} },
                { key="rti_star", icon="rti_star", tip="Raid target: Star", commands={"#a rti star"} },
                { key="rti_square", icon="rti_square", tip="Raid target: Square", commands={"#a rti square"} },
                { key="rti_triangle", icon="rti_triangle", tip="Raid target: Triangle", commands={"#a rti triangle"} },
                { key="rti_diamond", icon="rti_diamond", tip="Raid target: Diamond", commands={"#a rti diamond"} },
                { key="rti_moon", icon="rti_moon", tip="Raid target: Moon", commands={"#a rti moon"} },
                { key="rti_none", icon="mark_rti", tip="Clear raid target assignment", commands={"#a rti none"} },
            }
        },
        {
            label = "CROWD CONTROL TARGET",
            marker = true,
            buttons = {
                { key="cc_skull", icon="rti_skull", tip="CC target: Skull", commands={"#a rti cc skull"} },
                { key="cc_cross", icon="rti_cross", tip="CC target: Cross", commands={"#a rti cc cross"} },
                { key="cc_circle", icon="rti_circle", tip="CC target: Circle", commands={"#a rti cc circle"} },
                { key="cc_star", icon="rti_star", tip="CC target: Star", commands={"#a rti cc star"} },
                { key="cc_square", icon="rti_square", tip="CC target: Square", commands={"#a rti cc square"} },
                { key="cc_triangle", icon="rti_triangle", tip="CC target: Triangle", commands={"#a rti cc triangle"} },
                { key="cc_diamond", icon="rti_diamond", tip="CC target: Diamond", commands={"#a rti cc diamond"} },
                { key="cc_moon", icon="rti_moon", tip="CC target: Moon", commands={"#a rti cc moon"} },
                { key="cc_none", icon="cc", tip="Clear crowd-control target", commands={"#a rti cc none"} },
            }
        }
    },

    BEHAVIOR = {
        {
            label = "COMBAT BEHAVIOR",
            buttons = {
                { key="potions", icon="potions", tip="Use health and mana potions", commands={"#a react ~potions,?"} },
                { key="casttime", icon="cast_time", tip="Avoid long casts on nearly dead targets", commands={"#a co ~cast time,?"} },
                { key="aoe", icon="caster_aoe", tip="Use AOE abilities", commands={"#a co ~aoe,?","#a nc ~aoe,?"} },
                { key="cc", icon="cc", tip="Use crowd-control abilities", commands={"#a co ~cc,?"} },
                { key="conserve", icon="conserve_mana", tip="Reduce mana use at the cost of DPS", commands={"#a co ~conserve mana,?"} },
                { key="avoidadds", icon="ads", tip="Avoid pulling additional enemies", commands={"#a co ~ads,?","#a nc ~ads,?"} },
                { key="mark", icon="mark_rti", tip="Automatically mark current target", commands={"#a co ~mark rti,?"} },
                { key="buff", icon="boost", tip="Use buff abilities", commands={"#a co ~buff,?","#a nc ~buff,?"} },
                { key="boost", icon="boost", tip="Use boost/cooldown abilities", commands={"#a co ~boost,?","#a nc ~boost,?"} },
                { key="cure", icon="cure", tip="Use cure/cleanse abilities", commands={"#a co ~cure,?","#a nc ~cure,?"} },
                { key="offheal", icon="heal", tip="Off-heal while in DPS mode", commands={"#a co ~offheal,?","#a nc ~offheal,?"} },
                { key="offdps", icon="dps", tip="DPS while in healer mode", commands={"#a co ~offdps,?","#a nc ~offdps,?"} },
                { key="preheal", icon="heal", tip="Pre-heal the party", commands={"#a co ~preheal,?"} },
            }
        }
    },

    UTILITY = {
        {
            label = "WORLD / TRAVEL",
            buttons = {
                { key="food", icon="food", tip="Use food and drinks", commands={"#a nc ~food,?"} },
                { key="loot", icon="loot", tip="Enable looting", commands={"#a nc ~loot,?"} },
                { key="gather", icon="gather", tip="Gather herbs, ore, etc.", commands={"#a nc ~gather,?"} },
                { key="reveal", icon="stats", tip="Reveal gathering nodes", commands={"#a nc ~reveal,?"} },
                { key="mount", icon="mount", tip="Mount when possible", commands={"#a nc ~mount,?"} },
                { key="travel", icon="travel", tip="Travel to distant locations", commands={"#a nc ~travel,?"} },
            }
        },
        {
            label = "RPG BEHAVIOR",
            buttons = {
                { key="rpg", icon="rpg", tip="RPG with nearby NPCs", commands={"#a nc ~rpg,?"} },
                { key="quest", icon="rpg_quest", tip="Talk to quest NPCs", commands={"#a nc ~rpg quest,?"} },
                { key="vendor", icon="rpg_vendor", tip="Talk to vendors", commands={"#a nc ~rpg vendor,?"} },
                { key="explore", icon="rpg_explore", tip="Talk to inns and flightmasters", commands={"#a nc ~rpg explore,?"} },
                { key="maintenance", icon="rpg_maintenance", tip="Talk to armorers and trainers", commands={"#a nc ~rpg maintenance,?"} },
                { key="player", icon="rpg_player", tip="Duel/trade players", commands={"#a nc ~rpg player,?"} },
                { key="craft", icon="rpg_craft", tip="Craft items and cast utility spells", commands={"#a nc ~rpg craft,?"} },
                { key="bg", icon="rpg_bg", tip="Queue for battlegrounds at battlemasters", commands={"#a nc ~rpg bg,?"} },
            }
        },
        {
            label = "LOOT RULES",
            buttons = {
                { key="equip", icon="ll_equip", tip="Loot equipment upgrades", commands={"#a ll ~equip"} },
                { key="questloot", icon="ll_quest", tip="Loot quest items", commands={"#a ll ~quest"} },
                { key="skill", icon="ll_skill", tip="Loot tradeskill items", commands={"#a ll ~skill"} },
                { key="disenchant", icon="ll_disenchant", tip="Loot items for disenchanting", commands={"#a ll ~disenchant"} },
                { key="use", icon="ll_use", tip="Loot consumables/reagents", commands={"#a ll ~use"} },
                { key="vendorloot", icon="ll_vendor", tip="Loot items to vendor", commands={"#a ll ~vendor"} },
                { key="trash", icon="ll_trash", tip="Loot low-value/trash items", commands={"#a ll ~trash"} },
            }
        }
    },

    MANA = {
        {
            label = "SAVE MANA LEVEL",
            buttons = {
                { key="mana1", icon="savemana1", tip="Save mana level 1 / disabled", commands={"#a save mana 1"} },
                { key="mana2", icon="savemana2", tip="Save mana level 2", commands={"#a save mana 2"} },
                { key="mana3", icon="savemana3", tip="Save mana level 3", commands={"#a save mana 3"} },
                { key="mana4", icon="savemana4", tip="Save mana level 4", commands={"#a save mana 4"} },
                { key="mana5", icon="savemana5", tip="Save mana level 5", commands={"#a save mana 5"} },
            }
        }
    }
}

local CMaNGOSClassData = {
    DRUID = {
        { label="ROLE / SPEC", buttons={
            {key="druid_tank",icon="tank",tip="Feral tank mode",commands={"#a co +tank feral,+close,+pull,+tank assist,-ranged,-stealth,-behind,?","#a nc +tank feral,+tank assist,-stealth,?","#a de +tank feral,?","#a react +tank feral,?"}},
            {key="druid_feral",icon="dps",tip="Feral DPS mode",commands={"#a co +dps feral,+dps assist,+close,+stealth,+behind,-ranged,-pull,?","#a nc +dps feral,+dps assist,+stealth,?","#a de +dps feral,?","#a react +dps feral,?"}},
            {key="druid_balance",icon="caster",tip="Balance caster mode",commands={"#a co +balance,+dps assist,+ranged,-close,-pull,-stealth,?","#a nc +balance,+dps assist,-stealth,?","#a de +balance,?","#a react +balance,?"}},
            {key="druid_restoration",icon="heal",tip="Restoration healer mode",commands={"#a co +restoration,+dps assist,+ranged,-close,-pull,-stealth,?","#a nc +restoration,+dps assist,-stealth,?","#a de +restoration,?","#a react +restoration,?"}},
        }},
        { label="BEHAVIOR", buttons={
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="cure",icon="cure",tip="Cure",commands={"#a co ~cure,?","#a nc ~cure,?"}},
            {key="offheal",icon="heal",tip="Off-heal",commands={"#a co ~offheal,?","#a nc ~offheal,?"}},
            {key="stealth",icon="caster",tip="Stealth behavior",commands={"#a co ~stealth,?","#a nc ~stealth,?"}},
            {key="preheal",icon="heal",tip="Pre-heal",commands={"#a co ~preheal,?"}},
        }}
    },

    HUNTER = {
        { label="SPEC", buttons={
            {key="beastmastery",icon="dps",tip="Beast Mastery",commands={"#a co +beast mastery,?","#a nc +beast mastery,?","#a de +beast mastery,?","#a react +beast mastery,?"}},
            {key="marksmanship",icon="dps",tip="Marksmanship",commands={"#a co +marksmanship,?","#a nc +marksmanship,?","#a de +marksmanship,?","#a react +marksmanship,?"}},
            {key="survival",icon="dps",tip="Survival",commands={"#a co +survival,?","#a nc +survival,?","#a de +survival,?","#a react +survival,?"}},
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="sting",icon="dps_debuff",tip="Auto-pick stings",commands={"#a co ~sting,?"}},
            {key="aspect",icon="bmana",tip="Auto-pick aspects",commands={"#a co ~aspect,?","#a nc ~aspect,?"}},
            {key="pet",icon="pet",tip="Auto-pick/use pet",commands={"#a co ~pet,?","#a nc ~pet,?"}},
        }}
    },

    MAGE = {
        { label="SPEC / BEHAVIOR", buttons={
            {key="arcane",icon="caster",tip="Arcane mode",commands={"#a co +arcane,?","#a nc +arcane,?","#a de +arcane,?","#a react +arcane,?"}},
            {key="fire",icon="caster",tip="Fire mode",commands={"#a co +fire,?","#a nc +fire,?","#a de +fire,?","#a react +fire,?"}},
            {key="frost",icon="frost",tip="Frost mode",commands={"#a co +frost,?","#a nc +frost,?","#a de +frost,?","#a react +frost,?"}},
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="cure",icon="cure",tip="Cure curses",commands={"#a co ~cure,?","#a nc ~cure,?"}},
        }}
    },

    PALADIN = {
        { label="ROLE / SPEC", buttons={
            {key="retribution",icon="dps",tip="Retribution melee DPS",commands={"#a co +retribution,+dps assist,+close,-ranged,-pull,?","#a nc +retribution,+dps assist,?","#a de +retribution,?","#a react +retribution,?"}},
            {key="protection",icon="tank",tip="Protection tank",commands={"#a co +protection,+close,+pull,+tank assist,-ranged,?","#a nc +protection,+tank assist,?","#a de +protection,?","#a react +protection,?"}},
            {key="holy",icon="heal",tip="Holy healer",commands={"#a co +holy,+ranged,+dps assist,-close,-pull,?","#a nc +holy,+dps assist,?","#a de +holy,?","#a react +holy,?"}},
        }},
        { label="PALADIN BEHAVIOR", buttons={
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="cure",icon="cure",tip="Cure",commands={"#a co ~cure,?","#a nc ~cure,?"}},
            {key="offheal",icon="heal",tip="Off-heal",commands={"#a co ~offheal,?","#a nc ~offheal,?"}},
            {key="aura",icon="bmana",tip="Auto-pick aura",commands={"#a co ~aura,?","#a nc ~aura,?"}},
            {key="blessing",icon="bspeed",tip="Auto-pick blessings",commands={"#a co ~blessing,?","#a nc ~blessing,?"}},
            {key="preheal",icon="heal",tip="Pre-heal",commands={"#a co ~preheal,?"}},
        }},
        { label="BLESSING", buttons={
            {key="might",icon="bdps",tip="Blessing of Might",commands={"#a co +blessing might,?","#a nc +blessing might,?"}},
            {key="wisdom",icon="bmana",tip="Blessing of Wisdom",commands={"#a co +blessing wisdom,?","#a nc +blessing wisdom,?"}},
            {key="kings",icon="bstats",tip="Blessing of Kings",commands={"#a co +blessing kings,?","#a nc +blessing kings,?"}},
            {key="sanctuary",icon="btank",tip="Blessing of Sanctuary",commands={"#a co +blessing sanctuary,?","#a nc +blessing sanctuary,?"}},
            {key="light",icon="bhealth",tip="Blessing of Light",commands={"#a co +blessing light,?","#a nc +blessing light,?"}},
            {key="salvation",icon="bthreat",tip="Blessing of Salvation",commands={"#a co +blessing salvation,?","#a nc +blessing salvation,?"}},
        }},
        { label="AURA", buttons={
            {key="devotion",icon="tank",tip="Devotion Aura",commands={"#a co +aura devotion,?","#a nc +aura devotion,?"}},
            {key="retributionaura",icon="dps",tip="Retribution Aura",commands={"#a co +aura retribution,?","#a nc +aura retribution,?"}},
            {key="concentration",icon="caster",tip="Concentration Aura",commands={"#a co +aura concentration,?","#a nc +aura concentration,?"}},
            {key="shadowaura",icon="shadow",tip="Shadow Resistance Aura",commands={"#a co +aura shadow,?","#a nc +aura shadow,?"}},
            {key="frostaura",icon="frost",tip="Frost Resistance Aura",commands={"#a co +aura frost,?","#a nc +aura frost,?"}},
            {key="fireaura",icon="caster",tip="Fire Resistance Aura",commands={"#a co +aura fire,?","#a nc +aura fire,?"}},
            {key="crusader",icon="mount",tip="Crusader Aura",commands={"#a co +aura crusader,?","#a nc +aura crusader,?"}},
            {key="sanctity",icon="boost",tip="Sanctity Aura",commands={"#a co +aura sanctity,?","#a nc +aura sanctity,?"}},
        }}
    },

    PRIEST = {
        { label="ROLE / SPEC", buttons={
            {key="discipline",icon="heal",tip="Discipline healer",commands={"#a co +discipline,?","#a nc +discipline,?","#a de +discipline,?","#a react +discipline,?"}},
            {key="holy",icon="holy",tip="Holy healer",commands={"#a co +holy,?","#a nc +holy,?","#a de +holy,?","#a react +holy,?"}},
            {key="shadow",icon="shadow",tip="Shadow DPS",commands={"#a co +shadow,?","#a nc +shadow,?","#a de +shadow,?","#a react +shadow,?"}},
        }},
        { label="BEHAVIOR", buttons={
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="cure",icon="cure",tip="Cure",commands={"#a co ~cure,?","#a nc ~cure,?"}},
            {key="offheal",icon="heal",tip="Off-heal",commands={"#a co ~offheal,?","#a nc ~offheal,?"}},
            {key="offdps",icon="dps",tip="Off-DPS while healing",commands={"#a co ~offdps,?","#a nc ~offdps,?"}},
            {key="preheal",icon="heal",tip="Pre-heal",commands={"#a co ~preheal,?"}},
        }}
    },

    ROGUE = {
        { label="SPEC / BEHAVIOR", buttons={
            {key="combat",icon="dps",tip="Combat",commands={"#a co +combat,?","#a nc +combat,?","#a de +combat,?","#a react +combat,?"}},
            {key="assassination",icon="dps",tip="Assassination",commands={"#a co +assassination,?","#a nc +assassination,?","#a de +assassination,?","#a react +assassination,?"}},
            {key="subtlety",icon="dps",tip="Subtlety",commands={"#a co +subtlety,?","#a nc +subtlety,?","#a de +subtlety,?","#a react +subtlety,?"}},
            {key="aoe",icon="aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="poisons",icon="caster_aoe",tip="Auto-pick poisons",commands={"#a co ~poisons,?","#a nc ~poisons,?"}},
            {key="stealth",icon="caster",tip="Stealth behavior",commands={"#a co ~stealth,?","#a nc ~stealth,?"}},
        }}
    },

    SHAMAN = {
        { label="ROLE / SPEC", buttons={
            {key="elemental",icon="caster",tip="Elemental caster",commands={"#a co +elemental,+ranged,-close,?","#a nc +elemental,?","#a de +elemental,?","#a react +elemental,?"}},
            {key="restoration",icon="heal",tip="Restoration healer",commands={"#a co +restoration,+threat,+ranged,-close,?","#a nc +restoration,?","#a de +restoration,?","#a react +restoration,?"}},
            {key="enhancement",icon="dps",tip="Enhancement melee",commands={"#a co +enhancement,-ranged,+close,?","#a nc +enhancement,?","#a de +enhancement,?","#a react +enhancement,?"}},
        }},
        { label="BEHAVIOR", buttons={
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="cure",icon="cure",tip="Cure poison/disease",commands={"#a co ~cure,?","#a nc ~cure,?"}},
            {key="offheal",icon="heal",tip="Off-heal",commands={"#a co ~offheal,?","#a nc ~offheal,?"}},
            {key="totems",icon="totems",tip="Auto-pick totems",commands={"#a co ~totems,?","#a nc ~totems,?"}},
            {key="preheal",icon="heal",tip="Pre-heal",commands={"#a co ~preheal,?"}},
        }}
    },

    WARLOCK = {
        { label="SPEC / BEHAVIOR", buttons={
            {key="affliction",icon="dps",tip="Affliction",commands={"#a co +affliction,?","#a nc +affliction,?","#a de +affliction,?","#a react +affliction,?"}},
            {key="demonology",icon="dps",tip="Demonology",commands={"#a co +demonology,?","#a nc +demonology,?","#a de +demonology,?","#a react +demonology,?"}},
            {key="destruction",icon="dps",tip="Destruction",commands={"#a co +destruction,?","#a nc +destruction,?","#a de +destruction,?","#a react +destruction,?"}},
            {key="aoe",icon="aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
            {key="curse",icon="dps_debuff",tip="Auto-pick curses",commands={"#a co ~curse,?"}},
            {key="pet",icon="pet",tip="Auto-pick pets",commands={"#a co ~pet,?","#a nc ~pet,?"}},
        }}
    },

    WARRIOR = {
        { label="ROLE / SPEC", buttons={
            {key="arms",icon="dps",tip="Arms DPS",commands={"#a co +arms,+dps assist,-pull,?","#a nc +arms,+dps assist,?","#a de +arms,?","#a react +arms,?"}},
            {key="fury",icon="grind",tip="Fury DPS",commands={"#a co +fury,+dps assist,-pull,?","#a nc +fury,+dps assist,?","#a de +fury,?","#a react +fury,?"}},
            {key="protection",icon="tank",tip="Protection tank",commands={"#a co +protection,+tank assist,+pull,?","#a nc +protection,+tank assist,?","#a de +protection,?","#a react +protection,?"}},
            {key="aoe",icon="caster_aoe",tip="AOE",commands={"#a co ~aoe,?","#a nc ~aoe,?"}},
            {key="buff",icon="boost",tip="Buff",commands={"#a co ~buff,?","#a nc ~buff,?"}},
            {key="boost",icon="boost",tip="Boost/cooldowns",commands={"#a co ~boost,?","#a nc ~boost,?"}},
        }}
    }
}

local CMaNGOSCharacterData = {
    {
        label = "GEAR / INITIALIZATION",
        buttons = {
            { key="randomgear", icon="equip", tip="Randomize the selected bot's gear using .bot gear <name>. Uses the server's RandomGearMaxLevel limit.", botCommand=".bot gear %s", danger=true },
            { key="enchants", icon="boost", tip="Apply relevant enchants for the selected bot's class/spec.", botCommand=".bot enchants %s" },
            { key="initbot", icon="reset", tip="Initialize the selected bot: level toward your level, randomize gear, learn spells and prepare items. This is a major character change.", botCommand=".bot init %s", danger=true },
        }
    },
    {
        label = "SPELLS / PREPARATION",
        buttons = {
            { key="learn", icon="spells", tip="Learn all spells and abilities available up to the selected bot's current level.", botCommand=".bot learn %s" },
            { key="train", icon="spells", tip="Train all possible class spells for the selected bot's class and level.", botCommand=".bot train %s" },
            { key="prepare", icon="stats", tip="Prepare ammo, food, potions, reagents and consumables for the selected bot.", botCommand=".bot prepare %s" },
            { key="ammo", icon="inventory", tip="Give relevant ammunition. Mainly useful for hunters.", botCommand=".bot ammo %s" },
            { key="foodchar", icon="food", tip="Give relevant food and drink.", botCommand=".bot food %s" },
            { key="potionschar", icon="potions", tip="Give relevant potions/reagents.", botCommand=".bot potions %s" },
            { key="reagents", icon="inventory", tip="Give relevant class reagents/consumables.", botCommand=".bot reagents %s" },
            { key="consumables", icon="inventory", tip="Give relevant consumables.", botCommand=".bot consumables %s" },
            { key="petinit", icon="pet", tip="Initialize/train the selected bot's hunter or warlock pet.", botCommand=".bot pet %s" },
        }
    }
}

local CMaNGOSClassNames = {
    "DRUID","HUNTER","MAGE","PALADIN","PRIEST","ROGUE","SHAMAN","WARLOCK","WARRIOR"
}

local function CMaNGOSAdvancedSend(commands, partyChat)
    if partySize() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r You must be in a party with PlayerBots.")
        return
    end

    if partyChat then
        SendChatMessage(partyChat, "PARTY")
        return
    end

    local combined = ""
    local i
    for i = 1, table.getn(commands) do
        if combined ~= "" then combined = combined .. CommandSeparator end
        combined = combined .. commands[i]
    end

    if combined ~= "" then
        SendBotCommand(combined, "PARTY")
    end
end

local function CMaNGOSAdvancedSendToBot(commands, botName)
    if not botName or botName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Select a party bot first.")
        return
    end

    local combined = ""
    local i
    for i = 1, table.getn(commands) do
        if combined ~= "" then combined = combined .. CommandSeparator end
        combined = combined .. commands[i]
    end

    if combined ~= "" then
        -- This matches the existing individual bot manager delivery path:
        -- whisper the existing Mangosbot command bundle to one named bot.
        SendBotCommand(combined, "WHISPER", nil, botName)
    end
end

local function CMaNGOSAdvancedIcon(data)
    if data.native then return "Interface\\Icons\\" .. data.native end
    if data.icon then return "Interface\\AddOns\\Mangosbot\\Images\\" .. data.icon .. ".tga" end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function CMaNGOSAdvancedLabel(data)
    local names = {
        attack="Attack", tankattack="Tank Attack", passive="Passive", flee="Flee", reset="Reset AI",
        wait="Wait", pull="Pull", pullback="Pull Back", threat="Threat", mark="Mark RTI", avoidadds="Avoid Adds",
        tankassist="Tank Assist", dpsassist="DPS Assist", close="Close", ranged="Ranged",
        offheal="Off-Heal", offdps="Off-DPS", preheal="Pre-Heal", cure="Cure", buff="Buff", boost="Boost",
        follow="Follow", stay="Stay", free="Free", guard="Guard",
        near="Near", melee="Melee", arrow="Arrow", far="Far", chaos="Chaos",
        potions="Potions", casttime="Cast Time", aoe="AOE", cc="Crowd Control", conserve="Conserve Mana",
        food="Food/Drink", loot="Loot", gather="Gather", reveal="Reveal Nodes", mount="Mount", travel="Travel",
        rpg="RPG", quest="Quest", vendor="Vendor", explore="Explore", maintenance="Maintenance", player="Player",
        craft="Craft", bg="Battleground", equip="Equip", questloot="Quest Items", skill="Skill Items",
        disenchant="Disenchant", use="Use", vendorloot="Vendor", trash="Trash",
        mana1="Mana 1", mana2="Mana 2", mana3="Mana 3", mana4="Mana 4", mana5="Mana 5",
        druid_tank="Feral Tank", druid_feral="Feral DPS", druid_balance="Balance", druid_restoration="Restoration",
        beastmastery="Beast Mastery", marksmanship="Marksmanship", survival="Survival",
        arcane="Arcane", fire="Fire", frost="Frost",
        retribution="Retribution", protection="Protection", holy="Holy",
        discipline="Discipline", shadow="Shadow",
        combat="Combat", assassination="Assassination", subtlety="Subtlety", poisons="Poisons", stealth="Stealth",
        elemental="Elemental", restoration="Restoration", enhancement="Enhancement", totems="Totems",
        affliction="Affliction", demonology="Demonology", destruction="Destruction", curse="Curses", pet="Pet",
        arms="Arms", fury="Fury",
        aura="Auto Aura", blessing="Auto Blessing",
        might="Might", wisdom="Wisdom", kings="Kings", sanctuary="Sanctuary", light="Light", salvation="Salvation",
        devotion="Devotion", retributionaura="Retribution", concentration="Concentration",
        shadowaura="Shadow Resist", frostaura="Frost Resist", fireaura="Fire Resist", crusader="Crusader", sanctity="Sanctity",
        sting="Stings", aspect="Aspects",
        randomgear="Random Gear", enchants="Enchants", initbot="Init Bot",
        learn="Learn Spells", train="Train", prepare="Prepare", ammo="Ammo", foodchar="Food/Drink",
        potionschar="Potions", reagents="Reagents", consumables="Consumables", petinit="Pet"
    }
    return names[data.key] or data.tip or data.key or "Action"
end

local function CMaNGOSAdvancedIsMarker(data)
    return data and data.key and
        (string.find(data.key, "^rti_") == 1 or string.find(data.key, "^cc_") == 1)
end

local function CMaNGOSAdvancedClear(frame)
    if not frame.contentObjects then frame.contentObjects = {} return end
    local i
    for i=1,table.getn(frame.contentObjects) do
        frame.contentObjects[i]:Hide()
    end
    frame.contentObjects = {}
end

local function CMaNGOSAdvancedTrack(frame, obj)
    table.insert(frame.contentObjects, obj)
    return obj
end

local CMaNGOSAdvancedPartyBots

local function CMaNGOSAdvancedSendBotCommand(data, botName)
    if not botName or botName == "" then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Select a bot from the party/raid list first.")
        return
    end

    local valid = false
    local bots = CMaNGOSAdvancedPartyBots()
    local i
    for i = 1, table.getn(bots) do
        if bots[i].name == botName then
            valid = true
            break
        end
    end

    if not valid then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Mangosbot:|r Character command blocked. Selected name is not a current party/raid member.")
        return
    end

    if botName == UnitName("player") then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff5555Mangosbot:|r Character command blocked. You cannot target yourself.")
        return
    end

    -- CMaNGOS character-maintenance commands are bot WHISPER commands.
    -- This intentionally mirrors the known-working macro pattern:
    --     /w %t .bot gear %t
    -- The selected dropdown name becomes both the whisper recipient and the
    -- <name> argument; do NOT run these as normal SAY/GM commands.
    local command = string.format(data.botCommand, botName)
    SendChatMessage(command, "WHISPER", nil, botName)
end

local function CMaNGOSAdvancedAction(parent, data, x, y)
    local marker = CMaNGOSAdvancedIsMarker(data)

    if marker then
        local b = CreateFrame("Button", nil, parent, "ActionButtonTemplate")
        b:SetWidth(34); b:SetHeight(34)
        b:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
        b.data=data; b.advancedWidth=39

        local icon=b:CreateTexture(nil,"ARTWORK")
        icon:SetPoint("TOPLEFT",b,"TOPLEFT",4,-4)
        icon:SetPoint("BOTTOMRIGHT",b,"BOTTOMRIGHT",-4,4)
        icon:SetTexture(CMaNGOSAdvancedIcon(data))
        icon:SetTexCoord(.07,.93,.07,.93)

        b:SetScript("OnEnter",function()
            GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
            GameTooltip:SetText(this.data.tip or this.data.key,1,.82,0)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave",function() GameTooltip:Hide() end)
        b:SetScript("OnClick",function()
            CMaNGOSAdvancedSend(this.data.commands,this.data.partyChat)
        end)
        return b
    end

    local label=CMaNGOSAdvancedLabel(data)
    local width=100
    if string.len(label)>11 then width=118 end
    if string.len(label)>15 then width=136 end

    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate")
    b:SetWidth(width); b:SetHeight(28)
    b:SetPoint("TOPLEFT",parent,"TOPLEFT",x,y)
    b.data=data; b.advancedWidth=width+5

    local icon=b:CreateTexture(nil,"ARTWORK")
    icon:SetWidth(18); icon:SetHeight(18)
    icon:SetPoint("LEFT",b,"LEFT",7,0)
    icon:SetTexture(CMaNGOSAdvancedIcon(data))
    icon:SetTexCoord(.07,.93,.07,.93)

    local text=b:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    text:SetPoint("LEFT",icon,"RIGHT",4,0)
    text:SetPoint("RIGHT",b,"RIGHT",-5,0)
    text:SetJustifyH("LEFT")
    text:SetText(label)
    text:SetTextColor(.95,.95,.95)

    b:SetScript("OnEnter",function()
        GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
        GameTooltip:SetText(CMaNGOSAdvancedLabel(this.data),1,.82,0)
        GameTooltip:AddLine(this.data.tip or "",1,1,1,1)
        GameTooltip:AddLine("Existing Mangosbot / CMaNGOS command.",.45,.8,1,1)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave",function() GameTooltip:Hide() end)
    b:SetScript("OnClick",function()
        if AdvancedBotControl and AdvancedBotControl.currentTab == "CHARACTER" then
            local botName = AdvancedBotControl.currentBot

            CMaNGOSAdvancedSendBotCommand(this.data, botName)
        elseif AdvancedBotControl and AdvancedBotControl.currentTab == "CLASS" then
            CMaNGOSAdvancedSendToBot(
                this.data.commands,
                AdvancedBotControl.currentBot
            )
        else
            CMaNGOSAdvancedSend(this.data.commands,this.data.partyChat)
        end
    end)
    return b
end

local function CMaNGOSAdvancedSection(frame,section,y)
    local label=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
    label:SetPoint("TOPLEFT",frame,"TOPLEFT",18,y)
    label:SetFont("Fonts\\FRIZQT__.TTF",10,"OUTLINE")
    label:SetText("|cffe3b95b"..section.label.."|r")
    CMaNGOSAdvancedTrack(frame,label)

    local divider=frame:CreateTexture(nil,"ARTWORK")
    divider:SetTexture(.42,.34,.18,.55)
    divider:SetWidth(603); divider:SetHeight(1)
    divider:SetPoint("TOPLEFT",frame,"TOPLEFT",16,y-16)
    CMaNGOSAdvancedTrack(frame,divider)

    local x=18
    local buttonY=y-23
    local usedRows=1
    local i
    for i=1,table.getn(section.buttons) do
        local data=section.buttons[i]
        local desired=105
        if CMaNGOSAdvancedIsMarker(data) then desired=39
        else
            local labelText=CMaNGOSAdvancedLabel(data)
            if string.len(labelText)>11 then desired=123 end
            if string.len(labelText)>15 then desired=141 end
        end

        if x+desired>615 then
            x=18
            buttonY=buttonY-34
            usedRows=usedRows+1
        end

        local b=CMaNGOSAdvancedAction(frame,data,x,buttonY)
        CMaNGOSAdvancedTrack(frame,b)
        x=x+(b.advancedWidth or desired)
    end

    return y-32-(usedRows*34)
end

CMaNGOSAdvancedPartyBots = function()
    local bots = {}
    local seen = {}
    local playerName = UnitName("player")
    local i

    -- Build this list from the LIVE group roster.  botTable is populated by
    -- the asynchronous `.bot list` response and can be empty/stale when the
    -- Advanced window is opened, which used to make this dropdown appear
    -- completely empty even though party/raid members were present.
    local function AddGroupMember(name, unit, rosterClass)
        if not name or name == "" or name == playerName or seen[name] then return end

        local class = nil
        local bot = botTable and botTable[name]
        if bot and bot["class"] then
            class = string.upper(bot["class"])
        end

        if not class and unit then
            local localizedClass, classToken = UnitClass(unit)
            class = classToken or localizedClass
            if class then class = string.upper(class) end
        end

        if not class and rosterClass then
            class = string.upper(rosterClass)
        end

        seen[name] = true
        table.insert(bots, {
            name = name,
            class = class or "BOT"
        })
    end

    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name, rank, subgroup, level, localizedClass, classToken = GetRaidRosterInfo(i)
            AddGroupMember(name, "raid"..i, classToken or localizedClass)
        end
    else
        -- In a five-player Vanilla party, the player is `player` and the
        -- other four members are party1-party4.
        for i = 1, 4 do
            local unit = "party"..i
            AddGroupMember(UnitName(unit), unit, nil)
        end
    end

    return bots
end

local function CMaNGOSAdvancedClassDropDown_Initialize()
    local bots = CMaNGOSAdvancedPartyBots()
    local i

    if table.getn(bots) == 0 then
        UIDropDownMenu_AddButton({
            text = "No party / raid bots found",
            value = "",
            disabled = true
        })
        return
    end

    for i = 1, table.getn(bots) do
        local botInfo = bots[i]
        -- Capture the live roster class in this menu entry.  The dropdown is
        -- intentionally built from the live party/raid roster, so CLASS must
        -- not depend on the asynchronous botTable cache being populated.
        local liveClass = botInfo.class
        UIDropDownMenu_AddButton({
            text = botInfo.name .. " - " .. botInfo.class,
            value = botInfo.name,
            func = function()
                local selected = this.value
                AdvancedBotControl.currentBot = selected

                if liveClass and liveClass ~= "" and liveClass ~= "BOT" then
                    AdvancedBotControl.currentClass = string.upper(liveClass)
                elseif botTable and botTable[selected] and botTable[selected]["class"] then
                    AdvancedBotControl.currentClass =
                        string.upper(botTable[selected]["class"])
                else
                    AdvancedBotControl.currentClass = nil
                end

                if mangosbot_options then
                    mangosbot_options.advancedBot = selected
                end

                UIDropDownMenu_SetSelectedValue(
                    AdvancedBotControl.classDropDown,
                    selected
                )

                CMaNGOSAdvancedRender(AdvancedBotControl)
            end
        })
    end
end

function CMaNGOSAdvancedRender(frame)
    CMaNGOSAdvancedClear(frame)

    local tab=frame.currentTab or "TACTICS"
    local sections=nil
    local y=-104

    if tab=="CLASS" or tab=="CHARACTER" then
        frame.classDropDown:Show()

        -- Refresh bot/class whenever a per-bot tab is opened. Prefer the
        -- live party/raid roster because botTable is asynchronous and may be
        -- empty/stale when the player has already selected a group member.
        if frame.currentBot then
            local liveBots = CMaNGOSAdvancedPartyBots()
            local i
            local liveClass = nil
            for i = 1, table.getn(liveBots) do
                if liveBots[i].name == frame.currentBot then
                    liveClass = liveBots[i].class
                    break
                end
            end

            if liveClass and liveClass ~= "" and liveClass ~= "BOT" then
                frame.currentClass = string.upper(liveClass)
            elseif botTable and botTable[frame.currentBot] and
                   botTable[frame.currentBot]["class"] then
                frame.currentClass = string.upper(
                    botTable[frame.currentBot]["class"]
                )
            end
        end

        if frame.currentBot then
            UIDropDownMenu_SetSelectedValue(
                frame.classDropDown,
                frame.currentBot
            )
        else
            UIDropDownMenu_SetText("Select Party Bot", frame.classDropDown)
        end

        if tab=="CLASS" then
            sections = frame.currentClass and
                       CMaNGOSClassData[frame.currentClass] or {}
        else
            sections = frame.currentBot and CMaNGOSCharacterData or {}
        end

        if not frame.currentBot then
            local empty = frame:CreateFontString(
                nil, "OVERLAY", "GameFontNormal"
            )
            empty:SetPoint("TOPLEFT", frame, "TOPLEFT", 20, -118)
            empty:SetText(
                "|cff9ca9bdSelect a bot from your current party or raid. " ..
                "Only that named bot will receive " .. tab .. " commands.|r"
            )
            CMaNGOSAdvancedTrack(frame, empty)
        end
    else
        frame.classDropDown:Hide()
        sections=CMaNGOSAdvancedData[tab] or {}
        y=-88

        -- Party-message suppression is an addon preference, so keep it in
        -- Advanced > Utility instead of cluttering the always-visible Bot Bar.
        if tab=="UTILITY" then
            local label=frame:CreateFontString(nil,"OVERLAY","GameFontNormal")
            label:SetPoint("TOPLEFT",frame,"TOPLEFT",18,y)
            label:SetText("|cffe3b95bADDON CHAT|r")
            CMaNGOSAdvancedTrack(frame,label)

            local suppress=CreateFrame("Button",nil,frame,"UIPanelButtonTemplate")
            suppress:SetWidth(154); suppress:SetHeight(22)
            suppress:SetPoint("TOPLEFT",frame,"TOPLEFT",18,y-20)
            suppress:SetHitRectInsets(-5,-5,-4,-4)

            local function UpdateSuppressPartyButton()
                if mangosbot_options.suppressPartyMessages then
                    suppress:SetText("Party Messages: HIDDEN")
                else
                    suppress:SetText("Party Messages: SHOWN")
                end
            end

            suppress:SetScript("OnEnter",function()
                GameTooltip:SetOwner(this,"ANCHOR_RIGHT")
                GameTooltip:SetText("Suppress Party Messages",1,.82,0)
                GameTooltip:AddLine("Hides the addon's own PARTY command echo (such as Attack) from your chat window.",1,1,1,1)
                GameTooltip:AddLine("The command is still sent to PARTY so PlayerBots receive it normally.",.45,.8,1,1)
                GameTooltip:Show()
            end)
            suppress:SetScript("OnLeave",function() GameTooltip:Hide() end)
            suppress:SetScript("OnClick",function()
                mangosbot_options.suppressPartyMessages = not mangosbot_options.suppressPartyMessages
                UpdateSuppressPartyButton()
                if mangosbot_options.suppressPartyMessages then
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r PARTY command messages will be hidden locally.")
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r PARTY command messages will be shown normally.")
                end
            end)
            UpdateSuppressPartyButton()
            CMaNGOSAdvancedTrack(frame,suppress)
            y=y-54
        end
    end

    local i
    for i=1,table.getn(sections) do
        y=CMaNGOSAdvancedSection(frame,sections[i],y)
    end

    local height=math.abs(y)+38
    if height<190 then height=190 end
    if height>520 then height=520 end
    frame:SetHeight(height)

    local name,button
    for name,button in pairs(frame.tabs) do
        if name==tab then
            button:SetTextColor(1,.82,.25)
            if button:GetNormalTexture() then button:GetNormalTexture():SetVertexColor(.72,.12,.08) end
        else
            button:SetTextColor(.80,.80,.80)
            if button:GetNormalTexture() then button:GetNormalTexture():SetVertexColor(.35,.35,.35) end
        end
    end
end

function CreateAdvancedBotControl()
    if AdvancedBotControl then return AdvancedBotControl end

    local f=CreateFrame("Frame","MangosbotAdvancedBotControl",UIParent)
    AdvancedBotControl=f
    f:SetWidth(640)
    f:SetHeight(300)
    f:SetPoint("CENTER",UIParent,"CENTER",0,35)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()

    f:SetBackdrop({
        bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border",
        tile=true,tileSize=32,edgeSize=24,
        insets={left=8,right=8,top=8,bottom=8}
    })
    f:SetBackdropColor(.04,.06,.09,.96)

    local title=f:CreateFontString(nil,"OVERLAY","GameFontNormal")
    title:SetPoint("TOPLEFT",f,"TOPLEFT",18,-15)
    title:SetFont("Fonts\\FRIZQT__.TTF",14,"OUTLINE")
    title:SetText("|cffe3b95bADVANCED BOT COMMAND CENTER|r")

    local subtitle=f:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT",title,"BOTTOMLEFT",0,-2)
    subtitle:SetText("|cff9ca9bdGroup controls + per-bot CLASS controls|r")

    local close=CreateFrame("Button",nil,f,"UIPanelCloseButton")
    close:SetWidth(32); close:SetHeight(32)
    close:SetPoint("TOPRIGHT",f,"TOPRIGHT",4,4)
    close:SetScript("OnClick",function() f:Hide() end)

    local managerButton=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    managerButton:SetWidth(94)
    managerButton:SetHeight(22)
    managerButton:SetHitRectInsets(-5, -5, -4, -4)
    managerButton:SetText("Bot Manager")
    managerButton:SetPoint("TOPRIGHT",f,"TOPRIGHT",-36,-12)
    managerButton:SetScript("OnClick",function()
        ToggleBotManagerWindow()
    end)

    local botBarButton=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    botBarButton:SetWidth(70)
    botBarButton:SetHeight(22)
    botBarButton:SetHitRectInsets(-5, -5, -4, -4)
    botBarButton:SetText("Bot Bar")
    botBarButton:SetPoint("RIGHT",managerButton,"LEFT",-4,0)
    botBarButton:SetScript("OnClick",function()
        ToggleIntegratedBotBar()
    end)

    local helpButton=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
    helpButton:SetWidth(56)
    helpButton:SetHeight(22)
    helpButton:SetHitRectInsets(-5, -5, -4, -4)
    helpButton:SetText("Help")
    helpButton:SetPoint("RIGHT",botBarButton,"LEFT",-4,0)
    helpButton:SetScript("OnClick",function()
        if ToggleMangosbotHelp then ToggleMangosbotHelp() end
    end)

    local drag=CreateFrame("Button",nil,f)
    drag:SetPoint("TOPLEFT",f,"TOPLEFT",12,-9)
    drag:SetPoint("TOPRIGHT",f,"TOPRIGHT",-38,-9)
    drag:SetHeight(35)
    drag:EnableMouse(true)
    drag:RegisterForClicks("LeftButtonUp")
    drag:SetScript("OnMouseDown",function()
        if arg1=="LeftButton" then f:StartMoving() end
    end)
    drag:SetScript("OnMouseUp",function()
        if arg1=="LeftButton" then f:StopMovingOrSizing() end
    end)

    f.tabs={}
    f.contentObjects={}
    f.currentTab="TACTICS"
    f.currentBot=nil
    f.currentClass=nil

    -- Two compact tab rows keeps the large command set readable.
    local widths={TACTICS=62,ROLES=54,MOVE=48,FORM=48,TARGET=56,BEHAVIOR=68,UTILITY=56,MANA=46,CLASS=48,CHARACTER=78}
    local x=12
    local rowY=-48
    local i
    for i=1,table.getn(CMaNGOSAdvancedTabs) do
        local tabName=CMaNGOSAdvancedTabs[i]
        local captured=tabName
        local w=widths[tabName]
        if x+w>622 then
            x=12
            rowY=-72
        end
        local b=CreateFrame("Button",nil,f,"UIPanelButtonTemplate")
        b:SetWidth(w); b:SetHeight(22)
        b:SetText(tabName)
        b:SetPoint("TOPLEFT",f,"TOPLEFT",x,rowY)
        b:SetScript("OnClick",function()
            f.currentTab=captured
            if mangosbot_options then mangosbot_options.advancedTab=captured end
            CMaNGOSAdvancedRender(f)
        end)
        f.tabs[tabName]=b
        x=x+w+3
    end

    local dropdown=CreateFrame("Frame","MangosbotAdvancedClassDropDown",f,"UIDropDownMenuTemplate")
    f.classDropDown=dropdown
    dropdown:SetPoint("TOPLEFT",f,"TOPLEFT",-1,-76)
    UIDropDownMenu_Initialize(dropdown,CMaNGOSAdvancedClassDropDown_Initialize)
    UIDropDownMenu_SetWidth(190,dropdown)
    dropdown:Hide()

    if mangosbot_options then
        if mangosbot_options.advancedTab and
           (CMaNGOSAdvancedData[mangosbot_options.advancedTab] or mangosbot_options.advancedTab=="CLASS" or mangosbot_options.advancedTab=="CHARACTER") then
            f.currentTab=mangosbot_options.advancedTab
        end
        if mangosbot_options.advancedBot and
           botTable and botTable[mangosbot_options.advancedBot] and
           botTable[mangosbot_options.advancedBot]["class"] then
            f.currentBot = mangosbot_options.advancedBot
            f.currentClass = string.upper(
                botTable[mangosbot_options.advancedBot]["class"]
            )
        end
    end

    CMaNGOSAdvancedRender(f)
    return f
end

function ToggleAdvancedBotControl()
    local f=CreateAdvancedBotControl()
    if f:IsVisible() then f:Hide()
    else
        CMaNGOSAdvancedRender(f)
        f:Show()
    end
end

SLASH_MANGOSBOTADVANCED1="/botcontrol"
SLASH_MANGOSBOTADVANCED2="/botadvanced"
SlashCmdList.MANGOSBOTADVANCED=function(msg)
    ToggleAdvancedBotControl()
end

-- ---------------------------------------------------------------------------
-- Integrated Vanilla Bot Bar
-- Lightweight party-wide controls based on the community CMaNGOS Bot Bar.
-- ---------------------------------------------------------------------------

local IntegratedBotBarButtons = {
    {
        title = "Attack",
        icon = "Interface\\Icons\\Ability_MeleeDamage",
        tooltip = "Send the same PARTY chat attack order as typing 'attack' manually.",
        requiresTarget = true,
        partyChatCommand = "attack"
    },
    {
        title = "Follow",
        icon = "Interface\\Icons\\Ability_Tracking",
        tooltip = "Orders all party bots to stop waiting and follow you.",
        commands = { "#a follow ?" }
    },
    {
        title = "Stay",
        icon = "Interface\\Icons\\Ability_Defend",
        tooltip = "Orders all party bots to stay at their current positions.",
        commands = { "#a stay ?" }
    },
    {
        title = "Flee",
        icon = "Interface\\Icons\\Ability_Rogue_Sprint",
        tooltip = "Orders all party bots to disengage and return to you.",
        commands = { "#a flee ?" }
    },
    {
        title = "Reset AI",
        icon = "Interface\\Icons\\INV_Misc_PocketWatch_01",
        tooltip = "Clears current AI actions/orders and tells all bots to follow you.",
        commands = { "#a reset", "#a follow ?" }
    }
}

local function SaveIntegratedBotBarPosition()
    if not IntegratedBotBar then return end
    if not mangosbot_options then mangosbot_options = {} end
    if not mangosbot_options.botBar then mangosbot_options.botBar = {} end

    local point, _, relativePoint, x, y = IntegratedBotBar:GetPoint()
    mangosbot_options.botBar.point = point or "CENTER"
    mangosbot_options.botBar.relativePoint = relativePoint or "CENTER"
    mangosbot_options.botBar.x = x or 0
    mangosbot_options.botBar.y = y or -180
end

local function RestoreIntegratedBotBarPosition()
    if not IntegratedBotBar then return end
    if not mangosbot_options.botBar then mangosbot_options.botBar = {} end

    local o = mangosbot_options.botBar
    IntegratedBotBar:ClearAllPoints()
    IntegratedBotBar:SetPoint(
        o.point or "CENTER",
        UIParent,
        o.relativePoint or "CENTER",
        o.x or 0,
        o.y or -180
    )
end

local function SendIntegratedBotBarCommands(data)
    if partySize() == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r You must be in a party with PlayerBots.")
        return
    end

    if data.requiresTarget and
       (not UnitExists("target") or not UnitCanAttack("player", "target")) then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Select an attackable target first.")
        return
    end

    -- Literal PARTY chat fast path. This intentionally uses the exact same
    -- route as typing the command manually, because CMaNGOS appears to process
    -- normal party chat more immediately than BOT addon messages.
    if data.partyChatCommand then
        if mangosbot_options and mangosbot_options.suppressPartyMessages then
            MangosbotLastSuppressedPartyText = data.partyChatCommand
            MangosbotLastSuppressedPartyTime = GetTime()
        end
        SendChatMessage(data.partyChatCommand, "PARTY")
        return
    end

    -- Hidden addon-message fast path remains available for other commands.
    if data.directCommand then
        SendBotCommand(data.directCommand, "PARTY")
        return
    end

    local combined = ""
    local i
    for i = 1, table.getn(data.commands) do
        if combined ~= "" then combined = combined .. CommandSeparator end
        combined = combined .. data.commands[i]
    end

    SendBotCommand(combined, "PARTY")
end

local function CreateIntegratedBotBar()
    if IntegratedBotBar then return end
    if not mangosbot_options then mangosbot_options = {} end
    if not mangosbot_options.botBar then
        mangosbot_options.botBar = {
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -180,
            shown = true,
            locked = false
        }
    end

    if mangosbot_options.suppressPartyMessages == nil then
        mangosbot_options.suppressPartyMessages = false
    end

    local buttonSize = 34
    local gap = 3
    local count = table.getn(IntegratedBotBarButtons)
    local iconWidth = (buttonSize * count) + (gap * (count - 1))
    local width = 270
    local iconStartX = math.floor((width - iconWidth) / 2)

    local f = CreateFrame("Frame", "MangosbotIntegratedBotBar", UIParent)
    IntegratedBotBar = f
    f:SetWidth(width)
    f:SetHeight(108)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetFrameStrata("MEDIUM")

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    f:SetBackdropColor(.03,.04,.06,.94)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -11)
    title:SetText("|cffe3b95bBOT BAR|r")

    local drag = CreateFrame("Button", nil, f)
    drag:SetPoint("TOPLEFT", f, "TOPLEFT", 8, -5)
    drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -5)
    drag:SetHeight(20)
    drag:EnableMouse(true)
    drag:RegisterForClicks("LeftButtonUp")

    drag:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" and not mangosbot_options.botBar.locked then
            IntegratedBotBar:StartMoving()
        end
    end)
    drag:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then
            IntegratedBotBar:StopMovingOrSizing()
            SaveIntegratedBotBarPosition()
        end
    end)

    local i
    for i = 1, count do
        local data = IntegratedBotBarButtons[i]
        local b = CreateFrame("Button", "MangosbotIntegratedBotBarButton"..i, f, "ActionButtonTemplate")
        b:SetWidth(buttonSize)
        b:SetHeight(buttonSize)
        b:SetPoint("TOPLEFT", f, "TOPLEFT", iconStartX + (i-1)*(buttonSize+gap), -38)
        b:RegisterForClicks("LeftButtonUp")
        b:SetHitRectInsets(-3, -3, -3, -3)

        local icon = getglobal("MangosbotIntegratedBotBarButton"..i.."Icon")
        if not icon then
            -- Some 1.12 clients do not expose the ActionButtonTemplate icon
            -- region under the expected global name. Create our own icon so
            -- the integrated bar never appears as empty slots.
            icon = b:CreateTexture(nil, "ARTWORK")
            icon:SetPoint("TOPLEFT", b, "TOPLEFT", 4, -4)
            icon:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -4, 4)
        end
        icon:SetTexture(data.icon)
        icon:SetTexCoord(.07,.93,.07,.93)
        icon:Show()
        b.icon = icon

        local hotkey = getglobal("MangosbotIntegratedBotBarButton"..i.."HotKey")
        local countText = getglobal("MangosbotIntegratedBotBarButton"..i.."Count")
        local nameText = getglobal("MangosbotIntegratedBotBarButton"..i.."Name")
        if hotkey then hotkey:Hide() end
        if countText then countText:Hide() end
        if nameText then nameText:Hide() end

        b.data = data
        b:SetScript("OnEnter", function()
            GameTooltip:SetOwner(this, "ANCHOR_TOP")
            GameTooltip:SetText(this.data.title, 1, .82, 0)
            GameTooltip:AddLine(this.data.tooltip, 1,1,1,1)
            GameTooltip:AddLine("Affects the entire PlayerBot group.", .45,.8,1,1)
            GameTooltip:AddLine("Drag the Bot Bar title to move it.", .65,.65,.65,1)
            GameTooltip:Show()
        end)
        b:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        b:SetScript("OnClick", function()
            SendIntegratedBotBarCommands(this.data)
        end)
    end

    local manager = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    manager:SetWidth(64)
    manager:SetHeight(22)
    manager:SetHitRectInsets(-5, -5, -4, -4)
    manager:SetText("Manager")
    manager:SetPoint("TOPRIGHT", f, "TOPRIGHT", -112, -8)
    manager:SetScript("OnClick", function()
        ToggleBotManagerWindow()
    end)

    local advanced = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    advanced:SetWidth(64)
    advanced:SetHeight(22)
    advanced:SetHitRectInsets(-5, -5, -4, -4)
    advanced:SetText("Advanced")
    advanced:SetPoint("TOPRIGHT", f, "TOPRIGHT", -46, -8)
    advanced:SetScript("OnClick", function()
        ToggleAdvancedBotControl()
    end)

    local help = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    help:SetWidth(40)
    help:SetHeight(22)
    help:SetHitRectInsets(-5, -5, -4, -4)
    help:SetText("Help")
    help:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -8)
    help:SetScript("OnClick", function()
        ToggleMangosbotHelp()
    end)

    RestoreIntegratedBotBarPosition()

    if mangosbot_options.botBar.shown == false then
        f:Hide()
    else
        f:Show()
    end
end

function ToggleIntegratedBotBar()
    CreateIntegratedBotBar()
    if IntegratedBotBar:IsVisible() then
        IntegratedBotBar:Hide()
        mangosbot_options.botBar.shown = false
    else
        IntegratedBotBar:Show()
        mangosbot_options.botBar.shown = true
    end
end

-- ---------------------------------------------------------------------------
-- Mangosbot Interactive Help Guide
-- ---------------------------------------------------------------------------

local CMaNGOSHelpPages = {
    {
        key = "OVERVIEW",
        title = "Overview",
        text =
            "|cffe3b95bMANGOSBOT OVERVIEW|r\n\n" ..
            "Mangosbot is a visual controller for CMaNGOS Classic PlayerBot commands. It does not replace the bot AI; it gives you faster access to commands and strategies already supported by your server.\n\n" ..
            "|cffffcc00The four main interfaces|r\n" ..
            "|cff7fdfffBot Bar|r - Small always-available party controls for normal play.\n" ..
            "|cff7fdfffBot Manager|r - Bot roster, login/invite tools, group movement, formation, combat, utility and mana controls.\n" ..
            "|cff7fdfffIndividual Bot Manager|r - Detailed controls for one selected bot.\n" ..
            "|cff7fdfffAdvanced Command Center|r - Dungeon/raid tactics plus per-bot CLASS and CHARACTER tools.\n\n" ..
            "|cffffcc00Useful slash commands|r\n" ..
            "/bot or /mbp - Bot Manager\n" ..
            "/botbar - Show/hide Bot Bar\n" ..
            "/botcontrol - Advanced Command Center\n" ..
            "/bothelp - This guide\n\n" ..
            "Help is available directly from the Bot Bar, Bot Manager and Advanced windows. Hover buttons throughout the addon for the exact action tooltip."
    },
    {
        key = "BOTBAR",
        title = "Bot Bar",
        text =
            "|cffe3b95bBOT BAR|r\n\n" ..
            "The Bot Bar is the compact control strip intended to stay visible while you play.\n\n" ..
            "|cffffcc00Attack|r - Orders the group to attack your current target using normal PARTY chat for fast response.\n" ..
            "|cffffcc00Help|r - Opens this Help Guide directly from the Bot Bar.\n" ..
            "|cffffcc00Follow|r - All bots follow you.\n" ..
            "|cffffcc00Stay|r - Bots remain at their current position.\n" ..
            "|cffffcc00Flee|r - Bots disengage and return toward you.\n" ..
            "|cffffcc00Reset AI|r - Clears current AI action state and returns bots toward normal follow behavior.\n\n" ..
            "|cffffcc00Position commands|r\n" ..
            "Drag the BOT BAR title to move it. /botbar lock prevents accidental movement, /botbar unlock restores dragging, and /botbar reset restores the default position.\n\n" ..
            "Use Bot Manager or Advanced when you need formations, role strategies, raid marks, loot rules, class controls or character setup."
    },
    {
        key = "MANAGER",
        title = "Bot Manager",
        text =
            "|cffe3b95bBOT MANAGER|r\n\n" ..
            "The Bot Manager is the main roster and everyday group-management window.\n\n" ..
            "|cffffcc00Roster cards|r - Show known bots and quick actions such as Login/Logout, Invite/Leave, Summon, Whisper and More. Click a bot portrait/card to open that bot's detailed Individual Manager.\n" ..
            "|cffffcc00Refresh|r - Refreshes the bot roster and current group strategy states.\n\n" ..
            "|cffffcc00Party Controls|r - Immediate group actions.\n" ..
            "|cffffcc00Movement|r - Follow, Stay, Free, Guard, Flee and related movement behavior.\n" ..
            "|cffffcc00Formation|r - Near, Melee, Arrow, Far and Chaos.\n" ..
            "|cffffcc00Combat|r - Group combat strategies and assist behavior.\n" ..
            "|cffffcc00Utility / Loot|r - Food, looting, gathering, travel and related behaviors.\n" ..
            "|cffffcc00Mana Use|r - Mana-saving/conservation level.\n\n" ..
            "Green borders indicate the addon believes a persistent strategy is active. Hover an icon for its exact meaning."
    },
    {
        key = "INDIVIDUAL",
        title = "Individual",
        text =
            "|cffe3b95bINDIVIDUAL BOT MANAGER|r\n\n" ..
            "Use this window when one bot needs different behavior from the rest of the group.\n\n" ..
            "Normal targeting does not automatically open it. Hold |cffffcc00ALT and left-click a bot|r, or click that bot's portrait/card in Bot Manager.\n\n" ..
            "|cffffcc00QUICK|r - Movement, immediate actions, formation and stance/position.\n" ..
            "|cffffcc00COMBAT|r - Tank/DPS assist, melee/ranged, threat, wait, pull and pull-back behavior.\n" ..
            "|cffffcc00UTILITY|r - Inventory/info, loot rules, RPG/NPC behavior and general non-combat strategies.\n" ..
            "|cffffcc00CLASS|r - Only controls relevant to that bot's class/spec, including applicable AoE, buff, cure, pet, poison, totem, aura/blessing and healing options.\n\n" ..
            "The More menu opens additional manual-style bot actions such as quest/NPC/trainer/item/leader commands."
    },
    {
        key = "ADVANCED",
        title = "Advanced",
        text =
            "|cffe3b95bADVANCED COMMAND CENTER|r\n\n" ..
            "Advanced organizes the larger command set for dungeon and raid play.\n\n" ..
            "|cffffcc00TACTICS|r - Attack, Tank Attack, Passive, Flee, Reset, Wait, Pull, Pull Back, Threat, Mark RTI, Avoid Adds.\n" ..
            "|cffffcc00ROLES|r - Tank/DPS Assist, Close/Ranged, Threat, Off-Heal, Off-DPS, Pre-Heal, Cure, Buff, Boost.\n" ..
            "|cffffcc00MOVE / FORM|r - Group movement plus Near, Melee, Arrow, Far and Chaos formations.\n" ..
            "|cffffcc00TARGET|r - Separate raid-target attack marks and crowd-control marks, including None/clear.\n" ..
            "|cffffcc00BEHAVIOR|r - Potions, cast-time logic, AoE, CC, mana conservation, avoid adds, mark, buffs, cures and healing helpers.\n" ..
            "|cffffcc00UTILITY / MANA|r - Loot/RPG/travel behaviors, loot categories and mana levels 1-5. Advanced > UTILITY also contains the Party Messages SHOWN/HIDDEN addon preference.\n" ..
            "|cffffcc00CLASS / CHARACTER|r - Select a current party/raid member from the dropdown; CLASS sends class strategies to that selected name, while CHARACTER uses explicit .bot setup commands."
    },
    {
        key = "ROLES",
        title = "Roles & Pulling",
        text =
            "|cffe3b95bROLES, ASSIST AND PULLING|r\n\n" ..
            "|cffffcc00Tank Assist|r - Tells tank-role bots to grab aggro or use the assigned raid mark.\n" ..
            "|cffffcc00DPS Assist|r - Tells DPS-role bots to attack the least-HP target or assigned raid mark.\n" ..
            "|cffffcc00Pull|r - Enables the pull strategy. Normally enable this on only one bot.\n" ..
            "|cffffcc00Pull Back|r - Brings pulled monsters toward the location where the pull command was issued.\n" ..
            "|cffffcc00Wait for Attack|r - Delays engagement according to the server's wait-for-attack strategy.\n" ..
            "|cffffcc00Threat|r - Keeps applicable DPS/healer bots from generating unnecessary threat.\n\n" ..
            "|cffffcc00Healing helpers|r\n" ..
            "Off-Heal lets DPS-mode healing classes help heal. Off-DPS lets healer-mode bots contribute damage. Pre-Heal allows healing before expected incoming melee damage.\n\n" ..
            "These are persistent AI strategies, not one-time abilities. If behavior seems wrong, check which strategy buttons are currently active."
    },
    {
        key = "COMBAT",
        title = "Combat Modes",
        text =
            "|cffe3b95bTALENTS VS COMBAT STRATEGIES|r\n\n" ..
            "Talents/spec define the bot's build. Combat strategies control how that build behaves right now. AoE, assist modes, Threat, Wait, Pull, Pull Back, Close and Ranged are strategies; they do not rewrite talents.\n\n" ..
            "|cffffcc00AOE IS A TOGGLE|r\n" ..
            "There is no separate Single Target button. Click AoE to enable the server's AoE strategy; click it again to disable it and return to normal combat behavior.\n\n" ..
            "|cffffcc00GROUP VS ONE BOT|r\n" ..
            "Advanced group tabs affect applicable bots in the party. Advanced > CLASS first asks you to choose one current party/raid member, then whispers only that selected name. The Individual Manager is another way to tune one bot.\n\n" ..
            "Class-specific controls include spec/role choices and, where supported by that class, options such as AoE, buffs, cooldowns, cures, stealth, pets, poisons, stings, aspects, totems, auras and blessings."
    },
    {
        key = "CHARACTER",
        title = "Character / Gear",
        text =
            "|cffe3b95bCHARACTER / GEAR TOOLS|r\n\n" ..
            "Advanced > CHARACTER sends character-maintenance commands by whispering the selected bot, matching the working macro pattern /w %t .bot gear %t. Choose the intended PlayerBot from the current party/raid dropdown first.\n\n" ..
            "|cffffcc00Safety behavior|r\n" ..
            "The selected name must still be in your current party/raid, and your own character is blocked. CHARACTER actions execute immediately with one click. The dropdown is built from the live group roster, so if a human group member appears, do not select them for PlayerBot commands.\n\n" ..
            "|cffffcc00Gear / initialization|r\n" ..
            "Random Gear whispers .bot gear <name>; Enchants applies relevant enchants; Init Bot performs major bot initialization/setup. All CHARACTER commands are whispered directly to the selected bot.\n\n" ..
            "|cffffcc00Spells / preparation|r\n" ..
            "Learn Spells, Train, Prepare, Ammo, Food/Drink, Potions, Reagents, Consumables and Pet setup are available as separate buttons. Prepare is the convenient all-in-one supply action."
    },
    {
        key = "COMMANDS",
        title = "Utility & Loot",
        text =
            "|cffe3b95bUTILITY, LOOT AND INFORMATION|r\n\n" ..
            "|cffffcc00Party Messages|r - In Advanced > UTILITY, SHOWN displays addon PARTY command echoes such as Attack; HIDDEN suppresses only your local copy while still sending the command so PlayerBots receive it.\n\n" ..
            "Mangosbot exposes many non-combat PlayerBot actions in addition to combat controls.\n\n" ..
            "|cffffcc00Inventory / information|r - Stats, inventory, bank, equipment, mail, tradeskills and nearby-object information are available from the Individual Manager where supported.\n" ..
            "|cffffcc00Maintenance|r - Sell grey items, repair, release/revive, guard position and NPC quest interaction are also available.\n\n" ..
            "|cffffcc00Loot strategy|r\n" ..
            "General Loot enables/disables looting behavior. Loot Rules can separately toggle equipment upgrades, quest items, tradeskill items, disenchant items, usable consumables/reagents, vendor-value items and trash/useless items.\n\n" ..
            "|cffffcc00RPG behavior|r\n" ..
            "RPG modes include general NPC interaction plus Quest, Vendor, Explore, Maintenance, Player, Craft and Battleground behavior.\n\n" ..
            "Not every command supported by every PlayerBot fork is represented. Buttons in this build are limited to command paths intentionally wired into this addon."
    },
    {
        key = "TIPS",
        title = "Tips",
        text =
            "|cffe3b95bTIPS & TROUBLESHOOTING|r\n\n" ..
            "|cffffcc00CLASS/CHARACTER dropdown looks empty|r\n" ..
            "The list is rebuilt from your live party/raid roster when the menu opens. Make sure you are actually grouped, then reopen the dropdown.\n\n" ..
            "|cffffcc00A bot keeps returning to another target|r\n" ..
            "Check Tank Assist, DPS Assist, raid marks, crowd-control marks and persistent role strategies.\n\n" ..
            "|cffffcc00Green strategy border|r\n" ..
            "Green means the addon believes that strategy is active. Hover for the exact action; if behavior is unclear, refresh the roster/state and verify the bot response.\n\n" ..
            "|cffffcc00UI gets in the way|r\n" ..
            "Keep Bot Bar visible for normal play, open Bot Manager/Advanced only when needed, and use ALT-click only when intentionally opening an Individual Bot Manager.\n\n" ..
            "Mangosbot can only expose behavior supported by the CMaNGOS PlayerBot core running on your server."
    }
}
local function CMaNGOSHelpFindPage(key)
    local i
    for i=1,table.getn(CMaNGOSHelpPages) do
        if CMaNGOSHelpPages[i].key == key then return CMaNGOSHelpPages[i] end
    end
    return CMaNGOSHelpPages[1]
end

local function CMaNGOSHelpRender(frame, key)
    local page = CMaNGOSHelpFindPage(key)
    frame.currentPage = page.key
    frame.pageTitle:SetText("|cffe3b95b" .. page.title .. "|r")
    frame.body:SetText(page.text)

    local name, button
    for name,button in pairs(frame.pageButtons) do
        if name == page.key then
            button:SetTextColor(1,.82,.25)
        else
            button:SetTextColor(.9,.9,.9)
        end
    end
end

function CreateMangosbotHelpWindow()
    if MangosbotHelpWindow then return MangosbotHelpWindow end

    local f = CreateFrame("Frame", "MangosbotHelpWindow", UIParent)
    MangosbotHelpWindow = f
    f:SetWidth(760)
    f:SetHeight(620)
    f:SetPoint("CENTER", UIParent, "CENTER", 20, 20)
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:Hide()

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 24,
        insets = { left=8, right=8, top=8, bottom=8 }
    })
    f:SetBackdropColor(.03,.05,.08,.97)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -16)
    title:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    title:SetText("|cffe3b95bMANGOSBOT HELP GUIDE|r")

    local subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -3)
    subtitle:SetText("|cff9ca9bdCMaNGOS Classic PlayerBot Manager  |  Designed by Tim|r")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetWidth(34); close:SetHeight(34)
    close:SetHitRectInsets(-4,-4,-4,-4)
    close:SetPoint("TOPRIGHT", f, "TOPRIGHT", 4, 4)
    close:SetScript("OnClick", function() f:Hide() end)

    local drag = CreateFrame("Button", nil, f)
    drag:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -8)
    drag:SetPoint("TOPRIGHT", f, "TOPRIGHT", -38, -8)
    drag:SetHeight(38)
    drag:EnableMouse(true)
    drag:RegisterForClicks("LeftButtonUp")
    drag:SetScript("OnMouseDown", function()
        if arg1 == "LeftButton" then f:StartMoving() end
    end)
    drag:SetScript("OnMouseUp", function()
        if arg1 == "LeftButton" then f:StopMovingOrSizing() end
    end)

    f.pageButtons = {}
    local navX = 16
    local navY = -52
    local i
    for i=1,table.getn(CMaNGOSHelpPages) do
        local p = CMaNGOSHelpPages[i]
        local captured = p.key
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        local w = 78
        if p.key=="INDIVIDUAL" then w=78 end
        if p.key=="ROLES" then w=96 end
        if p.key=="COMBAT" then w=100 end
        if p.key=="COMMANDS" then w=108 end
        if p.key=="CHARACTER" then w=110 end
        b:SetWidth(w)
        b:SetHeight(24)
        b:SetHitRectInsets(-5,-5,-4,-4)

        if navX + w > 740 then
            navX = 16
            navY = navY - 28
        end

        b:SetPoint("TOPLEFT", f, "TOPLEFT", navX, navY)
        b:SetText(p.title)
        b:SetScript("OnClick", function()
            CMaNGOSHelpRender(f, captured)
        end)
        f.pageButtons[p.key] = b
        navX = navX + w + 4
    end

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(.42,.34,.18,.55)
    divider:SetWidth(720)
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -111)

    local pageTitle = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.pageTitle = pageTitle
    pageTitle:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -124)
    pageTitle:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")

    local body = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.body = body
    body:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -148)
    body:SetWidth(716)
    body:SetHeight(402)
    body:SetJustifyH("LEFT")
    body:SetJustifyV("TOP")
    body:SetFont("Fonts\\FRIZQT__.TTF", 12)

    local manager = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    manager:SetWidth(132); manager:SetHeight(28)
    manager:SetHitRectInsets(-6,-6,-5,-5)
    manager:SetText("Open Bot Manager")
    manager:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 30, 20)
    manager:SetScript("OnClick", function() ToggleBotManagerWindow() end)

    local advanced = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    advanced:SetWidth(132); advanced:SetHeight(28)
    advanced:SetHitRectInsets(-6,-6,-5,-5)
    advanced:SetText("Open Advanced")
    advanced:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
    advanced:SetScript("OnClick", function() ToggleAdvancedBotControl() end)

    local bar = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    bar:SetWidth(132); bar:SetHeight(28)
    bar:SetHitRectInsets(-6,-6,-5,-5)
    bar:SetText("Show / Hide Bot Bar")
    bar:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -30, 20)
    bar:SetScript("OnClick", function() ToggleIntegratedBotBar() end)

    CMaNGOSHelpRender(f, "OVERVIEW")
    return f
end

function ToggleMangosbotHelp()
    local f = CreateMangosbotHelpWindow()
    if f:IsVisible() then f:Hide() else f:Show() end
end

SLASH_MANGOSBOTHELP1 = "/bothelp"
SLASH_MANGOSBOTHELP2 = "/mangosbothelp"
SlashCmdList.MANGOSBOTHELP = function(msg)
    ToggleMangosbotHelp()
end

SLASH_MANGOSBOTBAR1 = "/botbar"
SlashCmdList.MANGOSBOTBAR = function(msg)
    msg = string.lower(trim2(msg or ""))

    if msg == "lock" then
        CreateIntegratedBotBar()
        mangosbot_options.botBar.locked = true
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Bot Bar locked.")
    elseif msg == "unlock" then
        CreateIntegratedBotBar()
        mangosbot_options.botBar.locked = false
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Bot Bar unlocked.")
    elseif msg == "reset" then
        CreateIntegratedBotBar()
        mangosbot_options.botBar.point = "CENTER"
        mangosbot_options.botBar.relativePoint = "CENTER"
        mangosbot_options.botBar.x = 0
        mangosbot_options.botBar.y = -180
        RestoreIntegratedBotBarPosition()
    else
        ToggleIntegratedBotBar()
    end
end

function QueryBotParty()
    wait(0.1, function() SendBotCommand("#a ll ?"..CommandSeparator.."#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?"..CommandSeparator.."#a react ?", "PARTY") end)
end

function QuerySelectedBot(name)
    wait(0.1, function() SendBotCommand("#a formation ?"..CommandSeparator.."#a stance ?"..CommandSeparator.."#a ll ?"..CommandSeparator.."#a co ?"..CommandSeparator.."#a nc ?"..CommandSeparator.."#a save mana ?"..CommandSeparator.."#a rti ?"..CommandSeparator.."#a react ?", "WHISPER", nil, name) end)
end

function UpdateBotList(delay)
    wait(delay, function() SendChatMessage(".bot list", "GUILD") end)
end

Mangosbot_EventFrame:SetScript("OnEvent", function(self)
    if (event == "VARIABLES_LOADED") then
        if (not mangosbot_options) then
            mangosbot_options = {}
        end
        if (not mangosbot_options.nativeIcons) then
            mangosbot_options.nativeIcons = true
        end
        SelectedBotPanel = CreateSelectedBotPanel();
        CreateIntegratedBotBar();
        CreateAdvancedBotControl();
        CreateMangosbotHelpWindow();
    end

    if (event == "PLAYER_TARGET_CHANGED") then
        local name = GetUnitName("target")
        local playerName = GetUnitName("player")
        local validFriendlyPlayer =
            name ~= nil and
            UnitExists("target") and
            not UnitIsEnemy("target", "player") and
            UnitIsPlayer("target") and
            name ~= playerName

        -- Normal targeting must never pop the individual bot manager.
        -- Hold ALT while left-clicking a bot/unit frame or character model
        -- to explicitly request the panel.
        if CurrentBot == nil then
            TargetBotOpenRequested = false

            if not validFriendlyPlayer then
                SelectedBotPanel:Hide()
            elseif IsAltKeyDown and IsAltKeyDown() then
                TargetBotOpenRequested = true
                SelectedBotPanel:Hide()
                QuerySelectedBot(name)
            else
                SelectedBotPanel:Hide()
            end
        else
            -- Roster-selected bots keep their existing explicit behavior.
            if CurrentBot ~= name and validFriendlyPlayer then
                -- Do not clear a roster selection simply because combat targeting changed.
            end
        end

        LastBot = name
    end

    if (event == "CHAT_MSG_SYSTEM" or event == "PARTY_MEMBERS_CHANGED") then
        local message = arg1
        if (OnSystemMessage(message) or (event == "PARTY_MEMBERS_CHANGED" and BotRoster:IsVisible())) then
            if (BotRoster.ShowRequest) then
                BotRoster:Show()
                BotRoster.ShowRequest = false
            end
            for i = 1,10 do
                BotRoster.items[i]:Hide()
            end
            local index = 1
            local x = 5
            local width = 0
            local height = 0
            local y = 5
            local colCount = 2
            local allBots = ""
            local first = true
            local allBotsLoggedIn = true
            local allBotsLoggedOut = true
            local allBotsInParty = true
            local atLeastOneBotInParty = false
            for key,bot in pairs(botTable) do
                if (index > 10) then 
                    index = 1 
                    y = 5
                end
                local item = BotRoster.items[index]
                if (first) then first = false
                else allBots = allBots .. "," end
                allBots = allBots .. key

                item.text:SetText(key)
                item.cls["key"] = key
                item.cls:SetScript("OnClick", function()
                    TargetBotOpenRequested = false
                    if (CurrentBot == item.cls["key"]) then
                        CurrentBot = nil
                        SelectedBotPanel:Hide()
                    else
                        CurrentBot = item.cls["key"]
                        QuerySelectedBot(CurrentBot)
                    end
                end)

				if (bot["class"] ~= nil) then
                local filename = "Interface\\Addons\\Mangosbot\\Images\\cls_" .. string.lower(bot["class"]) ..".tga"
                item.cls.texture:SetTexture(filename)

                local color = RAID_CLASS_COLORS[string.upper(bot["class"])]
                item.text:SetTextColor(color.r, color.g, color.b, 1.0)
				end	

                item:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", x, -y)

                local loginBtn = item.toolbar["quickbar"..index].buttons["login"]
                loginBtn:Hide()
                local logoutBtn = item.toolbar["quickbar"..index].buttons["logout"]
                logoutBtn:Hide()
                local inviteBtn = item.toolbar["quickbar"..index].buttons["invite"]
                inviteBtn:Show()
                local leaveBtn = item.toolbar["quickbar"..index].buttons["leave"]
                leaveBtn:Hide()
                local whisperBtn = item.toolbar["quickbar"..index].buttons["whisper"]
                whisperBtn:Hide()
                local summonBtn = item.toolbar["quickbar"..index].buttons["summon"]
                summonBtn:Hide()
                local menuBtn = item.toolbar["quickbar"..index].buttons["menu"]
                menuBtn:Hide()
                if (bot["online"]) then
                    item:SetBackdropBorderColor(0.6, 0.6, 0.2, 1.0)
                    logoutBtn:Show()
                    whisperBtn:Show()
                    summonBtn:Show()
                    menuBtn:Show()
                    local inParty = false
                    for i = 1,5 do
                        if (partyName(i) == key) then
                            inviteBtn:Hide()
                            leaveBtn:Show()
                            atLeastOneBotInParty = true
                            inParty = true
                            item:SetBackdropBorderColor(0.2, 0.8, 0.8, 1.0)
                        end
                    end
                    if (not inParty) then allBotsInParty = false end
                    allBotsLoggedOut = false
                else
                    item:SetBackdropBorderColor(0.2,0.2,0.2,1)
                    loginBtn:Show()
                    inviteBtn:Hide()
                    allBotsLoggedIn = false
                end
                loginBtn["key"] = key
                loginBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot add " .. loginBtn["key"], "SAY")
                end)
                logoutBtn["key"] = key
                logoutBtn:SetScript("OnClick", function()
                    SendBotCommand(".bot rm " .. logoutBtn["key"], "SAY")
                end)
                inviteBtn["key"] = key
                inviteBtn:SetScript("OnClick", function()
                    InviteByName(inviteBtn["key"])
                end)
                leaveBtn["key"] = key
                leaveBtn:SetScript("OnClick", function()
                    SendBotCommand("leave", "WHISPER", nil, leaveBtn["key"])
                end)
                whisperBtn["key"] = key
                whisperBtn:SetScript("OnClick", function()
                    local editBox = getglobal("ChatFrameEditBox")
                    editBox:Show()
                    editBox:SetFocus()
                    editBox:SetText("/whisper " .. whisperBtn["key"] .. " ")
                end)
                summonBtn["key"] = key
                summonBtn:SetScript("OnClick", function()
                    SendBotCommand("summon", "WHISPER", nil, summonBtn["key"])
                end)
                menuBtn["key"] = key
                menuBtn:SetScript("OnClick", function()
                    OpenDropDownMenu(menuBtn["key"])
                end)

                item:Show()

                index = index + 1
                x = x + (5 + item:GetWidth())
                height = item:GetHeight()
                if (width < x) then width = x end
                if (fmod((index - 1), colCount) == 0) then
                    y = y + (5 + height)
                    x = 5
                end
            end
            if (fmod((index - 1), colCount) ~= 0) then
                y = y + (5 + height)
            end
            
            if (botCount() >= 10) then 
                y = 230
            end
                        
            local tb = BotRoster.toolbar["quickbar"]
            tb:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            local loginAllBtn = tb.buttons["login_all"]
            x = 0
            loginAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedIn) then
                loginAllBtn:Show()
                x = x + 16
            else
                loginAllBtn:Hide()
            end
            loginAllBtn["allBots"] = allBots
            loginAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot add " .. loginAllBtn["allBots"], "SAY")
            end)

            local logoutAllBtn = tb.buttons["logout_all"]
            logoutAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                logoutAllBtn:Show()
                x = x + 16
            else
                logoutAllBtn:Hide()
            end
            logoutAllBtn["allBots"] = allBots
            logoutAllBtn:SetScript("OnClick", function()
                SendBotCommand(".bot rm " .. logoutAllBtn["allBots"], "SAY")
            end)

            local inviteAllBtn = tb.buttons["invite_all"]
            inviteAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsInParty) then
                inviteAllBtn:Show()
                x = x + 16
            else
                inviteAllBtn:Hide()
            end
            inviteAllBtn["key"] = key
            inviteAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key)
                        InviteByName(key)
                    end, key)
                    timeout = timeout + 0.1
                end
                UpdateBotList(1)
            end)

            local leaveAllBtn = tb.buttons["leave_all"]
            leaveAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (atLeastOneBotInParty) then
                leaveAllBtn:Show()
                x = x + 16
            else
                leaveAllBtn:Hide()
            end
            leaveAllBtn["key"] = key
            leaveAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("leave", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
            end)
            
			local summonAllBtn = tb.buttons["summon_all"]
            summonAllBtn:SetPoint("TOPLEFT", tb, "TOPLEFT", x, 0)
            if (not allBotsLoggedOut) then
                summonAllBtn:Show()
                x = x + 16
            else
                summonAllBtn:Hide()
            end
					
            summonAllBtn["key"] = key
            summonAllBtn:SetScript("OnClick", function()
                local timeout = 0.1
                for key,bot in pairs(botTable) do
                    wait(timeout, function(key) SendBotCommand("summon", "WHISPER", nil, key) end, key)
                    timeout = timeout + 0.1
                end
            end)				
            
            local formationToolBar = BotRoster.toolbar["group_formation"]
            if (atLeastOneBotInParty) then
                formationToolBar:Show()
                y = y + 22
                formationToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                formationToolBar:Hide()
            end

            local movementToolBar = BotRoster.toolbar["group_movement"]
            if (atLeastOneBotInParty) then
                movementToolBar:Show()
                y = y + 22
                movementToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                movementToolBar:Hide()
            end

            local savemanaToolBar = BotRoster.toolbar["group_savemana"]
            if (atLeastOneBotInParty) then
                savemanaToolBar:Show()
                y = y + 22
                savemanaToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                savemanaToolBar:Hide()
            end

            local genericToolBar = BotRoster.toolbar["group_generic"]
            if (atLeastOneBotInParty) then
                genericToolBar:Show()
                y = y + 22
                genericToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericToolBar:Hide()
            end

            local genericCombatToolBar = BotRoster.toolbar["group_generic_combat"]
            if (atLeastOneBotInParty) then
                genericCombatToolBar:Show()
                y = y + 22
                genericCombatToolBar:SetPoint("TOPLEFT", BotRoster, "TOPLEFT", 5, -y)
            else
                genericCombatToolBar:Hide()
            end

            UpdateGroupToolBar()

            -- Reuse the original updated buttons and state, but position them
            -- in the compact CMaNGOS quick-control layout.
            CMaNGOSApplyBotRosterLayout(BotRoster)
        end
    end

    if (event == "CHAT_MSG_WHISPER" or event == "CHAT_MSG_ADDON") then
        --print(event.." 1 "..arg1.." 2 "..arg2.." 3 "..arg3.." 4 "..arg4)
        local message = arg1
        local sender = arg2
        if (event == "CHAT_MSG_ADDON") then 
			message = arg2
			sender = arg4 
		end

        OnWhisper(message, sender)
        
        if (BotDebugPanel:IsVisible()) then
            UpdateBotDebugPanel(message, sender)
        end

        if (BotRoster:IsVisible() or SelectedBotPanel:IsVisible()) then
            -- if (string.find(message, "Hello") == 1 or string.find(message, "Goodbye") == 1) then
            --     SendBotCommand(".bot list", "SAY")
            --     QueryBotParty()
            -- end
            if (string.find(message, "Following") == 1 or string.find(message, "Staying") == 1 or string.find(message, "Fleeing") == 1) then
                wait(0.1, function() SendBotAddonCommand("nc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Formation set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("formation ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Stance set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("stance ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "Loot strategy set to ") == 1) then
                wait(0.1, function() SendBotAddonCommand("ll ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "rti cc set to") == 1) then
                wait(0.1, function() SendBotAddonCommand("rti cc ?", "WHISPER", nil, sender) end)
            end
            if (string.find(message, "save mana") == 1) then
                wait(0.1, function() SendBotAddonCommand("save mana ?", "WHISPER", nil, sender) end)
            end
            UpdateGroupToolBar()
        end

        local bot = botTable[sender]
        if (bot == nil or bot["strategy"] == nil or bot["role"] == nil) then
            -- Server responses arrive in several pieces. The original addon
            -- hid the panel during incomplete updates, which caused visible
            -- blinking. Keep the existing panel on screen and wait for the
            -- next complete update instead.
            if SelectedBotPanel.mantech and SelectedBotPanel.mantech.waitingText then
                SelectedBotPanel.mantech.waitingText:SetText("|cff9ca9bdUpdating bot data...|r")
            end
            return
        end
        local selected = GetUnitName("target")
        if (CurrentBot ~= nil) then selected = CurrentBot end
        if (sender == selected and (CurrentBot ~= nil or TargetBotOpenRequested)) then
            if not SelectedBotPanel:IsVisible() then
                SelectedBotPanel:Show()
            end
            if SelectedBotPanel.mantech and SelectedBotPanel.mantech.waitingText then
                SelectedBotPanel.mantech.waitingText:SetText("")
            end

            local tmp, class = "Unknown";
            if (GetUnitName("target") ~= nil) then
                tmp,class = UnitClass("target")
            end
            SetFrameColor(SelectedBotPanel, class)

            local filename = "Interface\\Addons\\Mangosbot\\Images\\role_" .. bot["role"] .. ".tga"
            SelectedBotPanel.header.role.texture:SetTexture(filename)
            SelectedBotPanel.header.text:SetText(sender)

            local width = 0
            local height = 0
            for toolbarName,toolbar in pairs(ToolBars) do
                local panelVisible = true
                if (string.find(toolbarName, "CLASS_") == 1) then
                    panelVisible = (string.find(string.sub(toolbarName, 7), class) == 1)
                end
                local numButtons = 0
                for buttonName,button in pairs(toolbar) do
                    local toggle = false
                    if (button["strategy"] ~= nil) then
                        for key,strategy in pairs(bot["strategy"]["nc"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                        for key,strategy in pairs(bot["strategy"]["co"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
						for key,strategy in pairs(bot["strategy"]["react"]) do
                            if (strategy == button["strategy"]) then
                                toggle = true
                                break
                            end
                        end
                    end
                    if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                        toggle = true
                    end
                    if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                        toggle = true
                    end
                    if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                        toggle = true
                    end
                    if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                        toggle = true
                    end
                    if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                        toggle = true
                    end
                    ToggleButton(SelectedBotPanel, toolbarName, buttonName, toggle)
                    numButtons = numButtons + 1
                end
                if (panelVisible) then
                    height = height + 1
                    if (width < numButtons) then width = numButtons end
                end
            end
            -- Preserve all original state updates, then arrange the same
            -- toolbar buttons in the selected organized tab.
            CMaNGOSApplySelectedBotLayout(SelectedBotPanel, class)
        end
    end
end)

function UpdateGroupToolBar()
    for toolbarName,toolbar in pairs(GroupToolBars) do
        for buttonName,button in pairs(toolbar) do
            local toggleCount = 0
            for botName,bot in pairs(botTable) do
                local toggle = false
                if (button["strategy"] ~= nil and bot["strategy"] ~= nil) then
                    for key,strategy in pairs(bot["strategy"]["nc"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                    for key,strategy in pairs(bot["strategy"]["co"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
					for key,strategy in pairs(bot["strategy"]["react"]) do
                        if (strategy == button["strategy"]) then
                            toggle = true
                            break
                        end
                    end
                end
                if (button["formation"] ~= nil and bot["formation"] ~= nil and string.find(bot["formation"], button["formation"]) ~= nil) then
                    toggle = true
                end
                if (button["stance"] ~= nil and bot["stance"] ~= nil and string.find(bot["stance"], button["stance"]) ~= nil) then
                    toggle = true
                end
                if (button["rti"] ~= nil and bot["rti"] ~= nil and string.find(bot["rti"], button["rti"]) ~= nil) then
                    toggle = true
                end
                if (button["rti_cc"] ~= nil and bot["rti_cc"] ~= nil and string.find(bot["rti_cc"], button["rti_cc"]) ~= nil) then
                    toggle = true
                end
                if (button["loot"] ~= nil and bot["loot"] ~= nil and string.find(bot["loot"], button["loot"]) ~= nil) then
                    toggle = true
                end
                if (button["savemana"] ~= nil and bot["savemana"] ~= nil and string.find(bot["savemana"], button["savemana"]) ~= nil) then
                    toggle = true
                end
                
                if (toggle) then 
                    for i = 1,5 do
                        if (partyName(i) == botName) then
                            toggleCount = toggleCount + 1
                        end
                    end
                end
            end
            ToggleButton(BotRoster, toolbarName, buttonName, toggleCount > 0, toggleCount < partySize())
        end
    end
end

function trim2(s)

    local find = string.find
    local sub = string.sub
    function trim8(s)
      local i1,i2 = find(s,'^%s*')
      if i2 >= i1 then s = sub(s,i2+1) end
      local i1,i2 = find(s,'%s*$')
      if i2 >= i1 then s = sub(s,1,i1-1) end
      return s
    end
    return trim8(s)
end

function splitString2( self, inSplitPattern, outResults )
  if not inSplitPattern then
    return
  end
  if not outResults then
    outResults = { }
  end
  local theStart = 1
  local theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  while theSplitStart do
    table.insert( outResults, string.sub( self, theStart, theSplitStart-1 ) )
    theStart = theSplitEnd + 1
    theSplitStart, theSplitEnd = string.find( self, inSplitPattern, theStart )
  end
  table.insert( outResults, string.sub( self, theStart ) )
  return outResults
end

function OnWhisper(message, sender)
    if (botTable[sender] == nil) then
        botTable[sender] = {}
    end
	
    local type = "co"
	local validStrategy = false
	local bot = botTable[sender]
	local trm = 19
	if(string.find(message, 'Combat Strategies: ') == 1) then
		type = "co"
		validStrategy = true
		trm = 19
	elseif(string.find(message, 'Non Combat Strategies: ') == 1) then
		type = "nc"
		validStrategy = true
		trm = 23
	elseif(string.find(message, 'Reaction Strategies: ') == 1) then
		type = "react"
		validStrategy = true
		trm = 21
	end
	   
    if (validStrategy) then
		local list = {}
		local role = "dps"
        local text = string.sub(message, trm)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local name = trim2(splitted[i])
            table.insert(list, name)
            if (name == "heal") then role = "heal" end
            if (name == "tank" or name == "bear") then role = "tank" end
        end
        if (bot['strategy'] == nil) then
            bot['strategy'] = {nc = {}, co = {}, react = {}}
        end
        if (type == "co") then
            bot["role"] = role
        end
        bot['strategy'][type] = list
    end
    if (string.find(message, 'Formation: ') == 1) then
        bot['formation'] = string.sub(message, 11)
    end
    if (string.find(message, 'Stance: ') == 1) then
        bot['stance'] = string.sub(message, 11)
    end
    if (string.find(message, 'Mana save level set: ') == 1) then
        bot['savemana'] = string.sub(message, 21)
    end
    if (string.find(message, 'Mana save level: ') == 1) then
        bot['savemana'] = string.sub(message, 17)
    end
    if (string.find(message, 'Loot strategy: ') == 1) then
        bot['loot'] = string.sub(message, 15)
    end
    if (string.find(message, 'rti: ') == 1) then
        bot['rti'] = string.sub(message, 5)
    end
    if (string.find(message, 'rti cc: ') == 1) then
        bot['rti_cc'] = string.sub(message, 5)
    end
end

local msgCount = 0

function OnSystemMessage(message)
	if (message == nil) then return false end
    if (string.find(message, 'add: ') == 1) and msgCount == 0 or (string.find(message, 'rm: ') == 1 and msgCount == 0) then
        UpdateBotList(1) 
        msgCount = msgCount + 1
        wait(5, function() msgCount = 0 end)
        return false
        end
    if (string.find(message, 'Bot roster: ') == 1) then
        botTable = {}
        local text = string.sub(message, 13)
        local splitted = splitString2(text, ", ")
        for i = 1, tablelength(splitted) do
            local line = trim2(splitted[i])
            local on = string.sub(line, 1, 1)
            local pos = string.find(line, " ")
            local name = string.sub(line, 2, pos - 1)
            local cls = string.sub(line, pos + 1)

            if (botTable[name] == nil) then
                botTable[name] = {}
            end
            botTable[name]["class"] = cls
            botTable[name]["online"] = (on == "+")
        end
        return true
    end
    return false
end

SLASH_MANGOSBOT1 = '/bot'
function SlashCmdList.MANGOSBOT(msg, editbox) -- 4.
    if (msg == "selected" or msg == "target") then
        local name = GetUnitName("target")
        local playerName = GetUnitName("player")
        if name and UnitExists("target") and UnitIsPlayer("target") and
           not UnitIsEnemy("target","player") and name ~= playerName then
            CurrentBot = nil
            TargetBotOpenRequested = true
            QuerySelectedBot(name)
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99Mangosbot:|r Select a friendly player bot first.")
        end
        return
    end

    if (msg == "" or msg == "roster") then
        if (BotRoster:IsVisible()) then
            BotRoster:Hide()
        else
            BotRoster.ShowRequest = true
            SendBotCommand(".bot list", "SAY")
            QueryBotParty()
        end
    end
    if (string.find(msg, "debug")) then
        local cmd = string.sub(msg, 7)
        if (string.len(cmd) == 0 and BotDebugPanel:IsVisible()) then
            BotDebugPanel:Hide()
        else
            BotDebugPanel:Show()
            BotDebugFilter = cmd;
        end
    end
end

local waitTable = {};
local waitFrame = nil;

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function wait(delay, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
  if(type(delay)~="number" or type(func)~="function") then
    return false;
  end
  if(waitFrame == nil) then
    waitFrame = CreateFrame("Frame","WaitFrame", UIParent);
    waitFrame:SetScript("OnUpdate",function ()
      local elapse = 0.1
      local count = tablelength(waitTable);
      local i = 1;
      while(i<=count) do
        local waitRecord = tremove(waitTable,i);
        local d = tremove(waitRecord,1);
        local f = tremove(waitRecord,1);
        local p = tremove(waitRecord,1);
        if(d>elapse) then
          tinsert(waitTable,i,{d-elapse,f,p});
          i = i + 1;
        else
          count = count - 1;
          f(unpack(p));
        end
      end
    end);
  end
  tinsert(waitTable,{delay,func,{arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9}});
  return true;
end

function partyName(i)
    local p = UnitName("party"..i)
    local r = UnitName("raid"..i)
    if (r == nil) then return p end
    return r
end

function partySize()
    local p = GetNumPartyMembers()
    local r = GetNumRaidMembers()
    if (r == 0) then return p end
    return r
end

function botCount()
  local count = 0
  for _ in pairs(botTable) do count = count + 1 end
  return count
end

print("MangosBOT Addon is loaded");
