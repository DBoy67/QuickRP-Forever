local addonName = "QuickRPForever"

-- =========================================================================
-- CHANNELS & VISUAL CONFIGURATION
-- =========================================================================
local CHANNELS = {"EMOTE", "SAY", "YELL", "PARTY", "GUILD", "RAID"}

local CHANNEL_INFO = {
    EMOTE = {
        label = "Emote",
        icon  = "Interface\\Icons\\INV_Misc_Book_09",
        color = { r = 1.00, g = 0.50, b = 0.25, hex = "ffff8040" },
    },
    SAY = {
        label = "Say",
        icon  = "Interface\\Icons\\INV_Misc_Note_01",
        color = { r = 1.00, g = 1.00, b = 1.00, hex = "ffffffff" },
    },
    YELL = {
        label = "Yell",
        icon  = "Interface\\Icons\\Ability_Warrior_WarCry",
        color = { r = 1.00, g = 0.25, b = 0.25, hex = "ffff4040" },
    },
    PARTY = {
        label = "Party",
        icon  = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude",
        color = { r = 0.67, g = 0.67, b = 1.00, hex = "ffaaaaff" },
    },
    GUILD = {
        label = "Guild",
        icon  = "Interface\\Icons\\INV_Shirt_GuildTabard_01",
        color = { r = 0.25, g = 1.00, b = 0.25, hex = "ff40ff40" },
    },
    RAID = {
        label = "Raid",
        icon  = "Interface\\Icons\\INV_BannerPVP_01",
        color = { r = 1.00, g = 0.50, b = 0.00, hex = "ffff7f00" },
    },
}

-- Default template data loaded on clean install
local DefaultData = {
    minimapAngle = 220,
    showMinimap = true,
    selectedId = "grp_greetings",
    items = {
        ["folder_example"] = {
            id = "folder_example",
            name = "Character: Caradon",
            isFolder = true,
            parentId = nil,
            collapsed = false,
            order = 1,
        },
        ["grp_greetings"] = {
            id = "grp_greetings",
            name = "Greetings",
            isFolder = false,
            parentId = "folder_example",
            collapsed = false,
            order = 1,
            mode = "RANDOM",
            lastIndex = 0,
            texts = {
                { text = "waves happily at %tf and says: Hello, %pf is here!", channel = "EMOTE" },
                { text = "Well met, %tf %tl! House %pl greets you.", channel = "SAY" },
                { text = "nods gratefully toward %tf with a warm smile.", channel = "EMOTE" },
            }
        },
        ["grp_combat"] = {
            id = "grp_combat",
            name = "Combat Phrases",
            isFolder = false,
            parentId = "folder_example",
            collapsed = false,
            order = 2,
            mode = "SEQUENCE",
            lastIndex = 0,
            texts = {
                { text = "draws their weapon with a resolute stance.", channel = "EMOTE" },
                { text = "Stand firm! For the glory of the realm!", channel = "YELL" },
            }
        },
        ["grp_emotes"] = {
            id = "grp_emotes",
            name = "General Emotes",
            isFolder = false,
            parentId = nil,
            collapsed = false,
            order = 2,
            mode = "RANDOM",
            lastIndex = 0,
            texts = {
                { text = "sits down on the ground and takes a deep breath.", channel = "EMOTE" },
                { text = "leans back and watches the surroundings carefully.", channel = "EMOTE" },
            }
        }
    }
}

-- =========================================================================
-- BASE64 ENCODING & DECODING (PURE LUA FOR IMPORT / EXPORT)
-- =========================================================================
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function Base64Encode(data)
    local sub = string.sub
    return ((data:gsub(".", function(x)
        local r, b = "", x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end) .. "0000"):gsub("%d%d%d?%d?%d?%d?", function(x)
        if #x < 6 then return "" end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == "1" and 2 ^ (6 - i) or 0) end
        return sub(B64, c + 1, c + 1)
    end) .. ({ "", "==", "=" })[#data % 3 + 1])
end

local function Base64Decode(data)
    data = data:gsub("[^" .. B64 .. "=]", "")
    return (data:gsub(".", function(x)
        if x == "=" then return "" end
        local r, f = "", (B64:find(x) - 1)
        for i = 6, 1, -1 do r = r .. (f % 2 ^ i - f % 2 ^ (i - 1) > 0 and "1" or "0") end
        return r
    end):gsub("%d%d%d%d%d%d%d%d", function(x)
        local c = 0
        for i = 1, 8 do c = c + (x:sub(i, i) == "1" and 2 ^ (8 - i) or 0) end
        return string.char(c)
    end))
end

-- =========================================================================
-- TRP3-INSPIRED BACKDROP AND THEME DEFINITIONS
-- =========================================================================
local BACKDROP_MAIN_WINDOW = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile     = true,
    tileSize = 32,
    edgeSize = 20,
    insets   = { left = 5, right = 5, top = 5, bottom = 5 },
}

local BACKDROP_PANEL_DARK = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

local BACKDROP_CARD = {
    bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile     = true,
    tileSize = 16,
    edgeSize = 12,
    insets   = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function CreateThemedFrame(frameType, name, parent, template)
    local inherits = "BackdropTemplate"
    if template and template ~= "" then
        inherits = inherits .. ", " .. template
    end
    local ok, frame = pcall(CreateFrame, frameType, name, parent, inherits)
    if ok and frame then return frame end
    return CreateFrame(frameType, name, parent, template)
end

local function SetFrameTooltip(frame, title, text, anchor)
    frame:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
        if title then
            GameTooltip:AddLine(title, 1.0, 0.82, 0.0)
        end
        if text then
            GameTooltip:AddLine(text, 0.88, 0.88, 0.88, true)
        end
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- TRP3 Button Styling
local function ApplyTrp3ButtonStyle(btn, isRed, fontObj, justify)
    btn.isRed = isRed

    btn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 10,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 },
    })

    if isRed then
        btn:SetBackdropColor(0.44, 0.08, 0.08, 0.95)
        btn:SetBackdropBorderColor(0.80, 0.50, 0.25, 1)
    else
        btn:SetBackdropColor(0.16, 0.13, 0.11, 0.95)
        btn:SetBackdropBorderColor(0.48, 0.38, 0.26, 0.85)
    end

    local normalFont = fontObj or (isRed and "GameFontHighlight" or "GameFontNormal")
    local fs = btn:GetFontString()
    if not fs then
        fs = btn:CreateFontString(nil, "OVERLAY", normalFont)
        btn:SetFontString(fs)
    end

    fs:ClearAllPoints()
    if justify == "LEFT" then
        fs:SetPoint("LEFT", btn, "LEFT", 8, 0)
        fs:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
        fs:SetJustifyH("LEFT")
    else
        fs:SetPoint("LEFT", btn, "LEFT", 4, 0)
        fs:SetPoint("RIGHT", btn, "RIGHT", -4, 0)
        fs:SetJustifyH("CENTER")
    end
    fs:SetWordWrap(false)

    btn:SetNormalFontObject(normalFont)
    btn:SetHighlightFontObject("GameFontHighlight")
    btn:SetDisabledFontObject("GameFontDisable")

    if not btn.trp3Hooked then
        btn.trp3Hooked = true
        btn:HookScript("OnEnter", function(self)
            if self.isRed then
                self:SetBackdropColor(0.62, 0.12, 0.12, 1)
                self:SetBackdropBorderColor(1.00, 0.75, 0.35, 1)
            else
                self:SetBackdropColor(0.26, 0.20, 0.15, 1)
                self:SetBackdropBorderColor(0.85, 0.70, 0.35, 1)
            end
        end)

        btn:HookScript("OnLeave", function(self)
            if self.isRed then
                self:SetBackdropColor(0.44, 0.08, 0.08, 0.95)
                self:SetBackdropBorderColor(0.80, 0.50, 0.25, 1)
            else
                if not self.isSelectedItem then
                    self:SetBackdropColor(0.16, 0.13, 0.11, 0.95)
                    self:SetBackdropBorderColor(0.48, 0.38, 0.26, 0.85)
                else
                    self:SetBackdropColor(0.26, 0.19, 0.12, 0.98)
                    self:SetBackdropBorderColor(0.95, 0.75, 0.25, 1)
                end
            end
        end)
    end
end

local function CreateTrp3Button(parent, text, isRed, fontObj, justify)
    local btn = CreateThemedFrame("Button", nil, parent)
    ApplyTrp3ButtonStyle(btn, isRed, fontObj, justify)
    if text then
        btn:SetText(text)
    end
    return btn
end

-- =========================================================================
-- NAME PARSER & CHAT TRANSMISSION
-- =========================================================================
local function ParseUnitNames(unit, fallback)
    local rawName = UnitName(unit)
    if not rawName or rawName == "" then return fallback, fallback, fallback end

    local cleanName = rawName:match("^([^%-]+)") or rawName
    cleanName = strtrim(cleanName)

    local first, last = cleanName:match("^([^%s]+)%s+(.+)$")
    if first and last then
        return first, last, cleanName
    else
        return cleanName, cleanName, cleanName
    end
end

local function ReplacePlaceholders(rawText)
    local pFirst, pLast, pFull = ParseUnitNames("player", "")
    local tFirst, tLast, tFull = ParseUnitNames("target", "someone")

    local text = rawText
    text = text:gsub("%%pf", function() return pFirst end)
    text = text:gsub("%%pl", function() return pLast end)
    text = text:gsub("%%tf", function() return tFirst end)
    text = text:gsub("%%tl", function() return tLast end)
    text = text:gsub("%%p", function() return pFull end)
    text = text:gsub("%%t", function() return tFull end)
    return text
end

local function SendLine(entry)
    if not entry or not entry.text or entry.text == "" then return end
    local msg = ReplacePlaceholders(entry.text)
    local ch = entry.channel or "EMOTE"

    if ch == "PARTY" and not IsInGroup() then ch = "SAY" end
    if ch == "RAID" and not IsInRaid() then ch = "SAY" end
    if ch == "GUILD" and not IsInGuild() then ch = "SAY" end

    SendChatMessage(msg, ch)
end

local RefreshMainWindow, RefreshQuickWindow, OpenImpExpWindow

-- Find an item by ID or name (case-insensitive)
local function FindItem(identifier)
    if not QuickRPForeverDB or not QuickRPForeverDB.items then return nil end
    if QuickRPForeverDB.items[identifier] then
        return QuickRPForeverDB.items[identifier]
    end
    local lower = tostring(identifier):lower()
    for _, it in pairs(QuickRPForeverDB.items) do
        if it.name:lower() == lower then
            return it
        end
    end
    return nil
end

local function TriggerGroup(identifier)
    local grp = FindItem(identifier)
    if not grp or grp.isFolder or not grp.texts or #grp.texts == 0 then
        print("|cffff0000[QuickRP Forever]|r Group '" .. tostring(identifier) .. "' is empty or does not exist.")
        return
    end

    local index = 1
    if #grp.texts > 1 then
        if grp.mode == "SEQUENCE" then
            index = (grp.lastIndex or 0) + 1
            if index > #grp.texts then index = 1 end
        else
            repeat
                index = math.random(1, #grp.texts)
            until index ~= grp.lastIndex or #grp.texts == 1
        end
    end

    grp.lastIndex = index
    SendLine(grp.texts[index])

    if RefreshMainWindow then RefreshMainWindow() end
end

-- =========================================================================
-- HIERARCHY TREE HELPER (FOLDERS & GROUPS WITH INDENTATION & ORDERING)
-- =========================================================================
local function GetOrderedSidebarTree()
    if not QuickRPForeverDB or not QuickRPForeverDB.items then return {} end

    local roots = {}
    local childrenByParent = {}

    for id, item in pairs(QuickRPForeverDB.items) do
        if not item.parentId or not QuickRPForeverDB.items[item.parentId] then
            table.insert(roots, item)
        else
            childrenByParent[item.parentId] = childrenByParent[item.parentId] or {}
            table.insert(childrenByParent[item.parentId], item)
        end
    end

    local function ItemSort(a, b)
        if a.isFolder ~= b.isFolder then
            return a.isFolder and not b.isFolder
        end
        if (a.order or 1) ~= (b.order or 1) then
            return (a.order or 1) < (b.order or 1)
        end
        return (a.name or "") < (b.name or "")
    end

    table.sort(roots, ItemSort)
    for _, list in pairs(childrenByParent) do
        table.sort(list, ItemSort)
    end

    local tree = {}
    for _, root in ipairs(roots) do
        table.insert(tree, { item = root, depth = 0 })
        if root.isFolder and not root.collapsed then
            local kids = childrenByParent[root.id]
            if kids then
                for _, kid in ipairs(kids) do
                    table.insert(tree, { item = kid, depth = 1 })
                end
            end
        end
    end

    return tree
end

-- =========================================================================
-- DRAG AND DROP VISUAL GHOST FRAME
-- =========================================================================
local draggedItem = nil
local dragGhost = CreateThemedFrame("Frame", nil, UIParent)
dragGhost:SetSize(170, 26)
dragGhost:SetBackdrop(BACKDROP_CARD)
dragGhost:SetBackdropColor(0.24, 0.17, 0.12, 0.95)
dragGhost:SetBackdropBorderColor(1.00, 0.82, 0.00, 1.0)
dragGhost:SetFrameStrata("TOOLTIP")
dragGhost:Hide()

local dragGhostIcon = dragGhost:CreateTexture(nil, "ARTWORK")
dragGhostIcon:SetSize(16, 16)
dragGhostIcon:SetPoint("LEFT", dragGhost, "LEFT", 6, 0)

local dragGhostText = dragGhost:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
dragGhostText:SetPoint("LEFT", dragGhostIcon, "RIGHT", 6, 0)
dragGhostText:SetPoint("RIGHT", dragGhost, "RIGHT", -6, 0)
dragGhostText:SetJustifyH("LEFT")

dragGhost:SetScript("OnUpdate", function(self)
    local cx, cy = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    self:ClearAllPoints()
    self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", cx / scale + 15, cy / scale - 15)
end)

-- =========================================================================
-- COMPACT RP QUICK-WINDOW (FOR IN-GAME RP USE)
-- =========================================================================
local rpWin = CreateThemedFrame("Frame", "QuickRPForeverQuickWindow", UIParent)
rpWin:SetSize(240, 380)
rpWin:SetPoint("RIGHT", UIParent, "RIGHT", -40, 0)
rpWin:SetBackdrop(BACKDROP_MAIN_WINDOW)
rpWin:SetBackdropColor(0.12, 0.09, 0.07, 0.96)
rpWin:SetBackdropBorderColor(0.55, 0.42, 0.28, 1)
rpWin:SetMovable(true)
rpWin:EnableMouse(true)
rpWin:SetClampedToScreen(true)
rpWin:RegisterForDrag("LeftButton")
rpWin:SetScript("OnDragStart", rpWin.StartMoving)
rpWin:SetScript("OnDragStop", rpWin.StopMovingOrSizing)
rpWin:Hide()

tinsert(UISpecialFrames, "QuickRPForeverQuickWindow")

local rpTitle = rpWin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
rpTitle:SetPoint("TOPLEFT", rpWin, "TOPLEFT", 14, -10)
rpTitle:SetText("|cffffd100QuickRP|r |cffffffffForever|r")

local rpSubTitle = rpWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
rpSubTitle:SetPoint("TOPLEFT", rpTitle, "BOTTOMLEFT", 0, -2)
rpSubTitle:SetText("|cffaaaaaaClick to play phrase|r")

local rpCloseBtn = CreateFrame("Button", nil, rpWin, "UIPanelCloseButton")
rpCloseBtn:SetPoint("TOPRIGHT", rpWin, "TOPRIGHT", -4, -4)
SetFrameTooltip(rpCloseBtn, "Close", "Close the Quick RP Window.")

local rpScroll = CreateFrame("ScrollFrame", nil, rpWin, "UIPanelScrollFrameTemplate")
rpScroll:SetPoint("TOPLEFT", rpWin, "TOPLEFT", 10, -42)
rpScroll:SetPoint("BOTTOMRIGHT", rpWin, "BOTTOMRIGHT", -28, 10)

local rpScrollChild = CreateFrame("Frame")
rpScrollChild:SetSize(195, 1)
rpScroll:SetScrollChild(rpScrollChild)

local quickBtnPool = {}

RefreshQuickWindow = function()
    if not QuickRPForeverDB or not QuickRPForeverDB.items then return end
    for _, btn in ipairs(quickBtnPool) do btn:Hide() end

    local tree = GetOrderedSidebarTree()
    local y = -2

    for i, node in ipairs(tree) do
        local item = node.item
        local depth = node.depth
        local btn = quickBtnPool[i]
        if not btn then
            btn = CreateTrp3Button(rpScrollChild, nil, false, "GameFontNormal", "LEFT")
            quickBtnPool[i] = btn
        end

        local btnWidth = (depth == 0) and 190 or 176
        local btnX = (depth == 0) and 2 or 16
        btn:SetSize(btnWidth, 26)
        btn:SetPoint("TOPLEFT", rpScrollChild, "TOPLEFT", btnX, y)

        if item.isFolder then
            local arrowTex = item.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up"
            btn:SetText("|T" .. arrowTex .. ":12:12:0:0|t |TInterface\\Icons\\INV_Misc_Bag_08:14:14:0:0|t " .. item.name)
            btn:SetBackdropColor(0.20, 0.15, 0.10, 0.95)
            btn:SetBackdropBorderColor(0.55, 0.42, 0.28, 0.9)
            btn:SetScript("OnClick", function()
                item.collapsed = not item.collapsed
                RefreshQuickWindow()
            end)
            SetFrameTooltip(btn, "Folder: " .. item.name, "Click to expand or collapse this folder.")
        else
            local count = item.texts and #item.texts or 0
            btn:SetText("|TInterface\\Icons\\INV_Misc_Note_01:14:14:0:0|t |cffffd100" .. item.name .. "|r  |cff888888(" .. count .. ")|r")
            btn:SetBackdropColor(0.14, 0.11, 0.09, 0.85)
            btn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.8)
            btn:SetScript("OnClick", function() TriggerGroup(item.id) end)

            btn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine(item.name, 1, 0.82, 0)
                GameTooltip:AddLine("Mode: " .. (item.mode == "SEQUENCE" and "Sequential" or "Random"), 0.8, 0.8, 0.8)
                GameTooltip:AddLine("Messages: " .. count, 0.8, 0.8, 0.8)
                GameTooltip:AddLine("|cffffffffClick to trigger phrase in chat|r", 0.2, 1, 0.2)
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        end

        btn:Show()
        y = y - 30
    end
    rpScrollChild:SetHeight(math.max(1, -y + 4))
end

-- =========================================================================
-- MAIN EDITOR WINDOW
-- =========================================================================
local mainWin = CreateThemedFrame("Frame", "QuickRPForeverMainWindow", UIParent)
mainWin:SetSize(800, 550)
mainWin:SetPoint("CENTER")
mainWin:SetBackdrop(BACKDROP_MAIN_WINDOW)
mainWin:SetBackdropColor(0.11, 0.08, 0.07, 0.98)
mainWin:SetBackdropBorderColor(0.55, 0.42, 0.28, 1)
mainWin:SetMovable(true)
mainWin:EnableMouse(true)
mainWin:SetClampedToScreen(true)
mainWin:RegisterForDrag("LeftButton")
mainWin:SetScript("OnDragStart", mainWin.StartMoving)
mainWin:SetScript("OnDragStop", mainWin.StopMovingOrSizing)
mainWin:Hide()

tinsert(UISpecialFrames, "QuickRPForeverMainWindow")

-- Top Window Header
local mainTitle = mainWin:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
mainTitle:SetPoint("TOPLEFT", mainWin, "TOPLEFT", 18, -12)
mainTitle:SetText("|cffffd100QuickRP|r |cffffffffForever|r")

local mainSubTitle = mainWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mainSubTitle:SetPoint("LEFT", mainTitle, "RIGHT", 10, -1)
mainSubTitle:SetText("|cffaaaaaaRoleplay Message & Emote Suite|r")

local mainCloseBtn = CreateFrame("Button", nil, mainWin, "UIPanelCloseButton")
mainCloseBtn:SetPoint("TOPRIGHT", mainWin, "TOPRIGHT", -4, -4)
SetFrameTooltip(mainCloseBtn, "Close Editor", "Close this window (or press Escape).")

-- -------------------------------------------------------------------------
-- LEFT SIDEBAR: Hierarchical Navigation (Folders & Groups)
-- -------------------------------------------------------------------------
local leftBg = CreateThemedFrame("Frame", nil, mainWin)
leftBg:SetPoint("TOPLEFT", mainWin, "TOPLEFT", 12, -36)
leftBg:SetPoint("BOTTOMLEFT", mainWin, "BOTTOMLEFT", 12, 12)
leftBg:SetWidth(205)
leftBg:SetBackdrop(BACKDROP_PANEL_DARK)
leftBg:SetBackdropColor(0.07, 0.05, 0.04, 0.92)
leftBg:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.85)

local sidebarWatermark = leftBg:CreateTexture(nil, "BACKGROUND", nil, 1)
sidebarWatermark:SetSize(80, 80)
sidebarWatermark:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 192)
sidebarWatermark:SetTexture("Interface\\AddOns\\QuickRPForever\\qrpf")
sidebarWatermark:SetVertexColor(0.60, 0.48, 0.35, 0.16)

local groupHeader = leftBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
groupHeader:SetPoint("TOPLEFT", leftBg, "TOPLEFT", 10, -8)
groupHeader:SetText("|cffddbb88ROLEPLAY GROUPS & FOLDERS|r")

local groupScroll = CreateFrame("ScrollFrame", nil, leftBg, "UIPanelScrollFrameTemplate")
groupScroll:SetPoint("TOPLEFT", leftBg, "TOPLEFT", 6, -26)
groupScroll:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -26, 188)

local groupChild = CreateFrame("Frame")
groupChild:SetSize(170, 1)
groupScroll:SetScrollChild(groupChild)

-- -------------------------------------------------------------------------
-- ACTION BUTTONS BELOW FOLDER NAMES (Play, Delete, Import/Export)
-- -------------------------------------------------------------------------
local actionsHeader = leftBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
actionsHeader:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 12, 168)
actionsHeader:SetText("|cffddbb88ACTIONS:|r")

local playBtn = CreateTrp3Button(leftBg, "> Play", true, "GameFontNormalSmall")
playBtn:SetSize(89, 22)
playBtn:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 10, 144)
SetFrameTooltip(playBtn, "Play Group", "Triggers the selected phrase group in chat.")

local delItemBtn = CreateTrp3Button(leftBg, "Delete", false, "GameFontNormalSmall")
delItemBtn:SetSize(89, 22)
delItemBtn:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -10, 144)
SetFrameTooltip(delItemBtn, "Delete Item", "Permanently deletes the selected group or folder.")

local impExpBtn = CreateTrp3Button(leftBg, "Import / Export", false, "GameFontNormalSmall")
impExpBtn:SetSize(182, 22)
impExpBtn:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 120)
SetFrameTooltip(impExpBtn, "Import & Export", "Open the Import and Export tool to backup or share roleplay packs.")

-- -------------------------------------------------------------------------
-- CREATE NEW SECTION (Name box, + Group button, + Folder button)
-- -------------------------------------------------------------------------
local createHeader = leftBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
createHeader:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 12, 98)
createHeader:SetText("|cffddbb88CREATE NEW:|r")

local newNameBox = CreateThemedFrame("EditBox", nil, leftBg, "InputBoxTemplate")
newNameBox:SetSize(182, 20)
newNameBox:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 76)
newNameBox:SetAutoFocus(false)
newNameBox:SetFontObject("ChatFontNormal")
newNameBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
SetFrameTooltip(newNameBox, "New Name", "Type a name for your new Group or Folder.\nThen click '+ New Text Group' or '+ New Folder'.")

local addGroupBtn = CreateTrp3Button(leftBg, "+ New Text Group", true, "GameFontNormalSmall")
addGroupBtn:SetSize(182, 22)
addGroupBtn:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 52)
SetFrameTooltip(addGroupBtn, "Create Text Group", "Create a new roleplay message group.\nIf a folder is selected, it will be placed inside that folder!")

local addFolderBtn = CreateTrp3Button(leftBg, "+ New Folder", false, "GameFontNormalSmall")
addFolderBtn:SetSize(182, 22)
addFolderBtn:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 28)
SetFrameTooltip(addFolderBtn, "Create Parent Folder", "Create a parent category/folder to hold multiple groups (e.g. Character names, Situations, Taverns).")

-- Toggle Quick RP Window Button
local toggleRpWinBtn = CreateTrp3Button(leftBg, "Quick RP Window", false)
toggleRpWinBtn:SetSize(182, 22)
toggleRpWinBtn:SetPoint("BOTTOM", leftBg, "BOTTOM", 0, 4)
SetFrameTooltip(toggleRpWinBtn, "Toggle Quick RP Window", "Opens or closes the compact floating roleplay bar.")
toggleRpWinBtn:SetScript("OnClick", function()
    if rpWin:IsShown() then
        rpWin:Hide()
    else
        RefreshQuickWindow()
        rpWin:Show()
    end
end)

-- -------------------------------------------------------------------------
-- RIGHT CONTENT PANEL: Group Messages & Cards OR Folder Management
-- -------------------------------------------------------------------------
local rightBg = CreateThemedFrame("Frame", nil, mainWin)
rightBg:SetPoint("TOPLEFT", leftBg, "TOPRIGHT", 8, 0)
rightBg:SetPoint("BOTTOMRIGHT", mainWin, "BOTTOMRIGHT", -12, 12)
rightBg:SetBackdrop(BACKDROP_PANEL_DARK)
rightBg:SetBackdropColor(0.08, 0.06, 0.05, 0.85)
rightBg:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.85)

-- Content Header
local itemTitle = rightBg:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
itemTitle:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 14, -10)

local itemSubInfo = rightBg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
itemSubInfo:SetPoint("LEFT", itemTitle, "RIGHT", 10, -1)

-- -------------------------------------------------------------------------
-- SEQUENCE BUILDER & PLAYBACK CONTROLS (Row 1 below Title)
-- -------------------------------------------------------------------------
local seqModeBtn = CreateTrp3Button(rightBg, "Mode: Sequential", false)
seqModeBtn:SetSize(142, 24)
seqModeBtn:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 12, -36)
SetFrameTooltip(seqModeBtn, "Sequence / Random Mode", "Click to switch between Sequential (ordered steps) and Random playback.")

local resetSeqBtn = CreateTrp3Button(rightBg, "Reset to Step 1", false, "GameFontNormalSmall")
resetSeqBtn:SetSize(125, 24)
resetSeqBtn:SetPoint("LEFT", seqModeBtn, "RIGHT", 6, 0)
SetFrameTooltip(resetSeqBtn, "Reset Sequence", "Rewind the sequence progress back to Step #1.")

local seqStatusLabel = rightBg:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
seqStatusLabel:SetPoint("LEFT", resetSeqBtn, "RIGHT", 10, 0)

local playNextBtn = CreateTrp3Button(rightBg, "> Play Next Step", true)
playNextBtn:SetSize(142, 24)
playNextBtn:SetPoint("TOPRIGHT", rightBg, "TOPRIGHT", -10, -36)
SetFrameTooltip(playNextBtn, "Play Next Step", "Triggers the next step of this sequence in chat.")

-- -------------------------------------------------------------------------
-- INLINE ADD STEP / LINE BAR (Row 2 below Sequence Bar)
-- -------------------------------------------------------------------------
local addLineChannelBtn = CreateTrp3Button(rightBg, "Emote", false)
addLineChannelBtn:SetSize(74, 24)
addLineChannelBtn:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 12, -66)
addLineChannelBtn.currentChannel = "EMOTE"
SetFrameTooltip(addLineChannelBtn, "Select Channel", "Click to choose which chat channel this new phrase will be sent to.")

local newLineBox = CreateThemedFrame("EditBox", nil, rightBg, "InputBoxTemplate")
newLineBox:SetPoint("LEFT", addLineChannelBtn, "RIGHT", 8, 0)
newLineBox:SetPoint("RIGHT", rightBg, "RIGHT", -98, 0)
newLineBox:SetHeight(24)
newLineBox:SetAutoFocus(false)
newLineBox:SetFontObject("ChatFontNormal")
newLineBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
SetFrameTooltip(newLineBox, "New Phrase / Step", "Type or paste your roleplay message here.\nSupports name tokens (%tf, %pf, etc.). Press Enter to add.\nYou can also paste multi-line text to add several steps at once!")

local addLineBtn = CreateTrp3Button(rightBg, "+ Add Step", true)
addLineBtn:SetSize(88, 24)
addLineBtn:SetPoint("LEFT", newLineBox, "RIGHT", 6, 0)
SetFrameTooltip(addLineBtn, "Add Step", "Adds the text as a new step in this sequence.")

newLineBox:SetScript("OnEnterPressed", function()
    local func = addLineBtn:GetScript("OnClick")
    if func then func(addLineBtn) end
end)

-- Tokens Helper Banner
local tokenBannerFrame = CreateFrame("Frame", nil, rightBg)
tokenBannerFrame:SetPoint("TOPLEFT", addLineChannelBtn, "BOTTOMLEFT", 0, -4)
tokenBannerFrame:SetPoint("RIGHT", rightBg, "RIGHT", -10, 0)
tokenBannerFrame:SetHeight(18)
tokenBannerFrame:EnableMouse(true)

local tokenBanner = tokenBannerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
tokenBanner:SetAllPoints(tokenBannerFrame)
tokenBanner:SetJustifyH("LEFT")
tokenBanner:SetText("|cffddbb88Tokens:|r |cffffffff%pf|r (1st), |cffffffff%pl|r (last), |cffffffff%p|r (full)   |   |cffddbb88Target:|r |cffffffff%tf|r (1st), |cffffffff%tl|r (last), |cffffffff%t|r (full)")

SetFrameTooltip(tokenBannerFrame, "Name Tokens (Placeholders) Guide", [[These placeholders are dynamically replaced with character names when you send a message:

|cffffd100Player Tokens (You):|r
  |cffffffff%pf|r = First Name (e.g. Caradon)
  |cffffffff%pl|r = Last Name (e.g. Majore)
  |cffffffff%p|r  = Full Name (e.g. Caradon Majore)

|cffffd100Target Tokens (Selected Unit):|r
  |cffffffff%tf|r = Target First Name
  |cffffffff%tl|r = Target Last Name
  |cffffffff%t|r  = Target Full Name

|cffaaaaaaIf no target is selected, %t and %tf will say 'someone'.|r]], "ANCHOR_BOTTOMLEFT")

-- Content Scroll Frame
local lineScroll = CreateFrame("ScrollFrame", nil, rightBg, "UIPanelScrollFrameTemplate")
lineScroll:SetPoint("TOPLEFT", tokenBannerFrame, "BOTTOMLEFT", 0, -4)
lineScroll:SetPoint("BOTTOMRIGHT", rightBg, "BOTTOMRIGHT", -26, 8)

local lineChild = CreateFrame("Frame")
lineChild:SetSize(525, 1)
lineScroll:SetScrollChild(lineChild)

-- =========================================================================
-- CUSTOM TRP3-STYLE CHANNEL POPUP MENU
-- =========================================================================
local channelMenu = CreateThemedFrame("Frame", "QuickRPForeverChannelMenu", UIParent)
channelMenu:SetSize(136, #CHANNELS * 26 + 10)
channelMenu:SetBackdrop(BACKDROP_CARD)
channelMenu:SetBackdropColor(0.10, 0.08, 0.07, 0.98)
channelMenu:SetBackdropBorderColor(0.60, 0.45, 0.28, 1)
channelMenu:SetFrameStrata("FULLSCREEN_DIALOG")
channelMenu:SetClampedToScreen(true)
channelMenu:Hide()

local menuCatcher = CreateFrame("Button", nil, UIParent)
menuCatcher:SetAllPoints(UIParent)
menuCatcher:SetFrameStrata("FULLSCREEN")
menuCatcher:Hide()
menuCatcher:SetScript("OnClick", function()
    channelMenu:Hide()
    menuCatcher:Hide()
end)

channelMenu:SetScript("OnHide", function()
    menuCatcher:Hide()
end)

local channelMenuButtons = {}
local activeChannelCallback = nil

local function OpenChannelMenu(anchorBtn, onSelectCallback, currentSelected)
    activeChannelCallback = onSelectCallback
    channelMenu:ClearAllPoints()

    local btnBottom = anchorBtn:GetBottom() or 400
    if btnBottom < (channelMenu:GetHeight() + 20) then
        channelMenu:SetPoint("BOTTOMLEFT", anchorBtn, "TOPLEFT", 0, 4)
    else
        channelMenu:SetPoint("TOPLEFT", anchorBtn, "BOTTOMLEFT", 0, -4)
    end

    for i, ch in ipairs(CHANNELS) do
        local btn = channelMenuButtons[i]
        local info = CHANNEL_INFO[ch]
        if not btn then
            btn = CreateFrame("Button", nil, channelMenu)
            btn:SetSize(126, 24)
            btn:SetPoint("TOPLEFT", channelMenu, "TOPLEFT", 5, -5 - (i - 1) * 26)

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints(btn)
            hl:SetColorTexture(0.35, 0.25, 0.15, 0.6)

            local icon = btn:CreateTexture(nil, "ARTWORK")
            icon:SetSize(18, 18)
            icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
            btn.icon = icon

            local fs = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            fs:SetPoint("LEFT", icon, "RIGHT", 8, 0)
            fs:SetJustifyH("LEFT")
            btn.label = fs

            local check = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            check:SetPoint("RIGHT", btn, "RIGHT", -6, 0)
            btn.check = check

            channelMenuButtons[i] = btn
        end

        btn.icon:SetTexture(info.icon)
        btn.label:SetText(info.label)
        btn.label:SetTextColor(info.color.r, info.color.g, info.color.b)

        if currentSelected == ch then
            btn.check:SetText("|cffffd100v|r")
        else
            btn.check:SetText("")
        end

        btn:SetScript("OnClick", function()
            channelMenu:Hide()
            menuCatcher:Hide()
            if activeChannelCallback then
                activeChannelCallback(ch)
            end
        end)
    end

    menuCatcher:Show()
    channelMenu:Show()
end

addLineChannelBtn:SetScript("OnClick", function(self)
    OpenChannelMenu(self, function(selectedCh)
        self.currentChannel = selectedCh
        local info = CHANNEL_INFO[selectedCh]
        self:SetText(info.label)
        local fs = self:GetFontString()
        if fs then
            fs:SetTextColor(info.color.r, info.color.g, info.color.b)
        end
    end, self.currentChannel)
end)

-- =========================================================================
-- IMPORT & EXPORT SYSTEM (STRUCTURED TEXT & BASE64 COMPACT CODES)
-- =========================================================================
local impExpWin = CreateThemedFrame("Frame", "QuickRPForeverImpExpWindow", UIParent)
impExpWin:SetSize(620, 480)
impExpWin:SetPoint("CENTER")
impExpWin:SetFrameStrata("DIALOG")
impExpWin:SetBackdrop(BACKDROP_MAIN_WINDOW)
impExpWin:SetBackdropColor(0.12, 0.09, 0.07, 0.98)
impExpWin:SetBackdropBorderColor(0.55, 0.42, 0.28, 1)
impExpWin:SetMovable(true)
impExpWin:EnableMouse(true)
impExpWin:SetClampedToScreen(true)
impExpWin:RegisterForDrag("LeftButton")
impExpWin:SetScript("OnDragStart", impExpWin.StartMoving)
impExpWin:SetScript("OnDragStop", impExpWin.StopMovingOrSizing)
impExpWin:Hide()

tinsert(UISpecialFrames, "QuickRPForeverImpExpWindow")

local impExpTitle = impExpWin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
impExpTitle:SetPoint("TOPLEFT", impExpWin, "TOPLEFT", 18, -12)
impExpTitle:SetText("|cffffd100QuickRP Forever - Import & Export|r")

local impExpCloseBtn = CreateFrame("Button", nil, impExpWin, "UIPanelCloseButton")
impExpCloseBtn:SetPoint("TOPRIGHT", impExpWin, "TOPRIGHT", -4, -4)
SetFrameTooltip(impExpCloseBtn, "Close", "Close import/export dialog.")

local tabExportBtn = CreateTrp3Button(impExpWin, "Export", true)
tabExportBtn:SetSize(100, 24)
tabExportBtn:SetPoint("TOPLEFT", impExpWin, "TOPLEFT", 18, -36)

local tabImportBtn = CreateTrp3Button(impExpWin, "Import", false)
tabImportBtn:SetSize(100, 24)
tabImportBtn:SetPoint("LEFT", tabExportBtn, "RIGHT", 6, 0)

local loadExampleBtn = CreateTrp3Button(impExpWin, "Load Example Format", false, "GameFontNormalSmall")
loadExampleBtn:SetSize(145, 24)
loadExampleBtn:SetPoint("LEFT", tabImportBtn, "RIGHT", 6, 0)
loadExampleBtn:Hide()
SetFrameTooltip(loadExampleBtn, "Load Example Format", "Fills the import box with an example roleplay script demonstrating all chat channels and folder structure.")

local impExpHelp = impExpWin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
impExpHelp:SetPoint("TOPLEFT", tabExportBtn, "BOTTOMLEFT", 0, -8)
impExpHelp:SetPoint("RIGHT", impExpWin, "RIGHT", -18, 0)
impExpHelp:SetJustifyH("LEFT")

local impExpInset = CreateThemedFrame("Frame", nil, impExpWin)
impExpInset:SetPoint("TOPLEFT", impExpHelp, "BOTTOMLEFT", 0, -6)
impExpInset:SetPoint("BOTTOMRIGHT", impExpWin, "BOTTOMRIGHT", -16, 50)
impExpInset:SetBackdrop(BACKDROP_PANEL_DARK)
impExpInset:SetBackdropColor(0.06, 0.05, 0.04, 0.95)
impExpInset:SetBackdropBorderColor(0.35, 0.26, 0.18, 0.8)

local impExpScroll = CreateFrame("ScrollFrame", nil, impExpInset, "UIPanelScrollFrameTemplate")
impExpScroll:SetPoint("TOPLEFT", impExpInset, "TOPLEFT", 6, -6)
impExpScroll:SetPoint("BOTTOMRIGHT", impExpInset, "BOTTOMRIGHT", -26, 6)

local EXAMPLE_IMPORT_TEMPLATE = [[-- EXAMPLE TEXT FORMAT (Paste your text or compact !QRPF:1:... code below):
[Folder: Character - Valen]
  [Group: Tavern Greetings | RANDOM]
    [Emote] smiles warmly at %tf and raises a mug of dwarven ale.
    [Say] Well met, %tf! Care to join our table tonight?
    [Yell] Barkeep! Another round of cider for the house!
    [Party] Let us prepare our gear before heading out into the dark.
    [Guild] Greetings, companions. Ready for tonight's campaign?
    [Raid] Defensive positions at the entrance!

[Group: Solitary Reflections | SEQUENCE]
  [Emote] sits quietly by the fireplace, writing in their journal.
  [Say] It has been a long and winding journey...]]

local impExpPlaceholder = impExpScroll:CreateFontString(nil, "ARTWORK", "ChatFontNormal")
impExpPlaceholder:SetPoint("TOPLEFT", impExpScroll, "TOPLEFT", 4, -4)
impExpPlaceholder:SetPoint("RIGHT", impExpScroll, "RIGHT", -20, 0)
impExpPlaceholder:SetJustifyH("LEFT")
impExpPlaceholder:SetJustifyV("TOP")
impExpPlaceholder:SetTextColor(0.55, 0.45, 0.35, 0.85)
impExpPlaceholder:SetText(EXAMPLE_IMPORT_TEMPLATE)
impExpPlaceholder:Hide()

local impExpEditBox = CreateFrame("EditBox", nil, impExpScroll)
impExpEditBox:SetMultiLine(true)
impExpEditBox:SetFontObject("ChatFontNormal")
impExpEditBox:SetWidth(540)
impExpEditBox:SetAutoFocus(false)
impExpEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
impExpScroll:SetScrollChild(impExpEditBox)

local currentImpExpTab = "EXPORT"

local function UpdatePlaceholder()
    if currentImpExpTab == "IMPORT" and (impExpEditBox:GetText() == "" or impExpEditBox:GetText() == nil) then
        impExpPlaceholder:Show()
    else
        impExpPlaceholder:Hide()
    end
end

impExpEditBox:SetScript("OnTextChanged", function(self)
    UpdatePlaceholder()
end)

loadExampleBtn:SetScript("OnClick", function()
    impExpEditBox:SetText(EXAMPLE_IMPORT_TEMPLATE)
    impExpEditBox:SetFocus()
    UpdatePlaceholder()
end)

impExpInset:SetScript("OnMouseDown", function() impExpEditBox:SetFocus() end)

local impExpActionBtn = CreateTrp3Button(impExpWin, "Execute", true)
impExpActionBtn:SetSize(180, 26)
impExpActionBtn:SetPoint("BOTTOM", impExpWin, "BOTTOM", 0, 14)

local function ExportToText(scope)
    local lines = {"[QuickRP Forever Export v1]"}

    local function ExportGroup(grp, indent)
        local pfx = indent and "  " or ""
        table.insert(lines, pfx .. "[Group: " .. grp.name .. " | " .. (grp.mode or "RANDOM") .. "]")
        if grp.texts then
            for _, t in ipairs(grp.texts) do
                table.insert(lines, pfx .. "  [" .. (t.channel or "EMOTE") .. "] " .. (t.text or ""))
            end
        end
    end

    local function ExportFolder(folder)
        table.insert(lines, "[Folder: " .. folder.name .. "]")
        for _, it in pairs(QuickRPForeverDB.items) do
            if not it.isFolder and it.parentId == folder.id then
                ExportGroup(it, true)
            end
        end
    end

    local currentItem = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]

    if scope == "SELECTED" and currentItem then
        if currentItem.isFolder then
            ExportFolder(currentItem)
        else
            ExportGroup(currentItem, false)
        end
    else
        -- Export all folders and their sub-groups first
        local handled = {}
        for _, it in pairs(QuickRPForeverDB.items) do
            if it.isFolder then
                ExportFolder(it)
                handled[it.id] = true
            end
        end
        -- Export standalone root groups
        for _, it in pairs(QuickRPForeverDB.items) do
            if not it.isFolder and (not it.parentId or not handled[it.parentId]) then
                ExportGroup(it, false)
            end
        end
    end

    return table.concat(lines, "\n")
end

local function ImportFromText(rawText)
    if not rawText or strtrim(rawText) == "" then return 0, 0, 0 end

    -- Check if it's compact code
    local compact = rawText:match("^!QRPF:1:(.+)")
    if compact then
        local ok, decoded = pcall(Base64Decode, compact)
        if ok and decoded and decoded ~= "" then
            rawText = decoded
        end
    end

    local importedFolders = 0
    local importedGroups = 0
    local importedMessages = 0

    local currentFolderId = nil
    local currentGroupId = nil

    local sel = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if sel and sel.isFolder then
        currentFolderId = sel.id
    end

    for line in rawText:gmatch("[^\r\n]+") do
        local clean = strtrim(line)
        if clean ~= "" and not clean:match("^%[QuickRP Forever Export") then
            -- 1. Folder Header: [Folder: Name]
            local fName = clean:match("^%[Folder:%s*(.+)%]$")
            if fName then
                fName = strtrim(fName)
                local fId = "folder_" .. tostring(time()) .. "_" .. math.random(1000, 9999)
                QuickRPForeverDB.items[fId] = {
                    id = fId,
                    name = fName,
                    isFolder = true,
                    parentId = nil,
                    collapsed = false,
                    order = 100 + importedFolders,
                }
                currentFolderId = fId
                currentGroupId = nil
                importedFolders = importedFolders + 1

            -- 2. Group Header: [Group: Name | MODE] or [Group: Name]
            elseif clean:match("^%[Group:") then
                local gName, gMode = clean:match("^%[Group:%s*([^%]|]+)%s*|%s*([^%]]+)%]$")
                if not gName then
                    gName = clean:match("^%[Group:%s*([^%]]+)%]$")
                    gMode = "RANDOM"
                end
                gName = strtrim(gName or "Imported Group")
                gMode = strtrim(gMode or "RANDOM"):upper()
                if gMode ~= "SEQUENCE" then gMode = "RANDOM" end

                local gId = "grp_" .. tostring(time()) .. "_" .. math.random(1000, 9999)
                QuickRPForeverDB.items[gId] = {
                    id = gId,
                    name = gName,
                    isFolder = false,
                    parentId = currentFolderId,
                    collapsed = false,
                    order = 100 + importedGroups,
                    mode = gMode,
                    lastIndex = 0,
                    texts = {}
                }
                currentGroupId = gId
                importedGroups = importedGroups + 1

            -- 3. Message Line: [Channel] text
            else
                local chTag, msgText = clean:match("^%[([%a]+)%]%s*(.+)$")
                if not chTag then
                    msgText = clean
                    chTag = "EMOTE"
                end

                local upperCh = chTag:upper()
                if not CHANNEL_INFO[upperCh] then upperCh = "EMOTE" end

                if not currentGroupId then
                    if sel and not sel.isFolder then
                        currentGroupId = sel.id
                    else
                        currentGroupId = "grp_" .. tostring(time()) .. "_" .. math.random(1000, 9999)
                        QuickRPForeverDB.items[currentGroupId] = {
                            id = currentGroupId,
                            name = "Imported Messages",
                            isFolder = false,
                            parentId = currentFolderId,
                            collapsed = false,
                            order = 100,
                            mode = "RANDOM",
                            lastIndex = 0,
                            texts = {}
                        }
                        importedGroups = importedGroups + 1
                    end
                end

                local targetGrp = QuickRPForeverDB.items[currentGroupId]
                if targetGrp and not targetGrp.isFolder then
                    table.insert(targetGrp.texts, { text = strtrim(msgText), channel = upperCh })
                    importedMessages = importedMessages + 1
                end
            end
        end
    end

    return importedFolders, importedGroups, importedMessages
end

local function SwitchImpExpTab(tab)
    currentImpExpTab = tab
    if tab == "EXPORT" then
        ApplyTrp3ButtonStyle(tabExportBtn, true)
        ApplyTrp3ButtonStyle(tabImportBtn, false)
        loadExampleBtn:Hide()
        impExpPlaceholder:Hide()
        impExpHelp:SetText("Copy the exported text below. You can paste it into Discord, a text file, or share it with friends:")
        impExpActionBtn:SetText("Export as Compact Code")
        local text = ExportToText("ALL")
        impExpEditBox:SetText(text)
        impExpEditBox:SetFocus()
        impExpEditBox:HighlightText()
    else
        ApplyTrp3ButtonStyle(tabExportBtn, false)
        ApplyTrp3ButtonStyle(tabImportBtn, true)
        loadExampleBtn:Show()
        impExpHelp:SetText("Paste an exported roleplay pack or raw lines below and click [Import Content Now]:")
        impExpActionBtn:SetText("Import Content Now")
        impExpEditBox:SetText("")
        impExpEditBox:SetFocus()
        UpdatePlaceholder()
    end
end

tabExportBtn:SetScript("OnClick", function() SwitchImpExpTab("EXPORT") end)
tabImportBtn:SetScript("OnClick", function() SwitchImpExpTab("IMPORT") end)

impExpActionBtn:SetScript("OnClick", function()
    if currentImpExpTab == "EXPORT" then
        -- Toggle between readable text and compact encoded string
        local cur = impExpEditBox:GetText()
        if cur:match("^!QRPF:1:") then
            impExpEditBox:SetText(ExportToText("ALL"))
            impExpActionBtn:SetText("Export as Compact Code")
        else
            local code = "!QRPF:1:" .. Base64Encode(cur)
            impExpEditBox:SetText(code)
            impExpActionBtn:SetText("Export as Readable Text")
        end
        impExpEditBox:SetFocus()
        impExpEditBox:HighlightText()
    else
        local text = impExpEditBox:GetText()
        local fCount, gCount, mCount = ImportFromText(text)
        RefreshMainWindow()
        RefreshQuickWindow()
        print("|cff00ff00[QuickRP Forever]|r Successfully imported " .. fCount .. " folder(s), " .. gCount .. " group(s), and " .. mCount .. " message(s)!")
        impExpWin:Hide()
    end
end)

OpenImpExpWindow = function(tab)
    SwitchImpExpTab(tab or "EXPORT")
    impExpWin:Show()
end

impExpBtn:SetScript("OnClick", function()
    OpenImpExpWindow("EXPORT")
end)

-- =========================================================================
-- REFRESH MAIN WINDOW & POOLS (TREE VIEW, FOLDER DASHBOARD & CARDS)
-- =========================================================================
local sidebarBtnPool = {}
local cardPool = {}
local folderRowPool = {}

RefreshMainWindow = function()
    if not QuickRPForeverDB or not QuickRPForeverDB.items then return end

    -- 1. Refresh Sidebar Hierarchy
    for _, btn in ipairs(sidebarBtnPool) do btn:Hide() end

    local tree = GetOrderedSidebarTree()

    -- Ensure selectedId is valid
    if not QuickRPForeverDB.selectedId or not QuickRPForeverDB.items[QuickRPForeverDB.selectedId] then
        if #tree > 0 then
            QuickRPForeverDB.selectedId = tree[1].item.id
        else
            QuickRPForeverDB.selectedId = nil
        end
    end

    local sy = -2
    for i, node in ipairs(tree) do
        local item = node.item
        local depth = node.depth
        local btn = sidebarBtnPool[i]
        if not btn then
            btn = CreateTrp3Button(groupChild, nil, false, "GameFontNormal", "LEFT")
            btn:RegisterForDrag("LeftButton")

            btn:SetScript("OnDragStart", function(self)
                draggedItem = self.itemData
                if not draggedItem then return end
                dragGhostText:SetText(draggedItem.name)
                dragGhostIcon:SetTexture(draggedItem.isFolder and "Interface\\Icons\\INV_Misc_Bag_08" or "Interface\\Icons\\INV_Misc_Note_01")
                dragGhost:Show()
            end)

            btn:SetScript("OnDragStop", function(self)
                dragGhost:Hide()
                if not draggedItem then return end

                local targetBtn = nil
                for _, b in ipairs(sidebarBtnPool) do
                    if b:IsShown() and b:IsMouseOver() and b ~= self then
                        targetBtn = b
                        break
                    end
                end

                if targetBtn and targetBtn.itemData then
                    local targetItem = targetBtn.itemData
                    if targetItem.isFolder then
                        if not draggedItem.isFolder and draggedItem.parentId ~= targetItem.id then
                            draggedItem.parentId = targetItem.id
                            targetItem.collapsed = false
                            print("|cff00ff00[QuickRP Forever]|r Moved '" .. draggedItem.name .. "' into folder '" .. targetItem.name .. "'.")
                        end
                    else
                        draggedItem.parentId = targetItem.parentId
                        local oldOrd = draggedItem.order or 1
                        draggedItem.order = (targetItem.order or 1)
                        targetItem.order = oldOrd
                        print("|cff00ff00[QuickRP Forever]|r Reordered '" .. draggedItem.name .. "'.")
                    end
                elseif leftBg:IsMouseOver() then
                    if draggedItem.parentId ~= nil then
                        draggedItem.parentId = nil
                        print("|cff00ff00[QuickRP Forever]|r Moved '" .. draggedItem.name .. "' to root level.")
                    end
                end

                draggedItem = nil
                RefreshMainWindow()
            end)

            sidebarBtnPool[i] = btn
        end

        btn.itemData = item
        local isSelected = (item.id == QuickRPForeverDB.selectedId)
        btn.isSelectedItem = isSelected

        local btnWidth = (depth == 0) and 165 or 150
        local btnX = (depth == 0) and 2 or 16
        btn:SetSize(btnWidth, 26)
        btn:SetPoint("TOPLEFT", groupChild, "TOPLEFT", btnX, sy)

        if item.isFolder then
            local arrowTex = item.collapsed and "Interface\\Buttons\\UI-PlusButton-Up" or "Interface\\Buttons\\UI-MinusButton-Up"
            local folderIcon = "Interface\\Icons\\INV_Misc_Bag_08"
            local folderLabel = "|T" .. arrowTex .. ":12:12:0:0|t |T" .. folderIcon .. ":14:14:0:0|t " .. item.name
            btn:SetText(isSelected and ("|cffffd100" .. folderLabel .. "|r") or folderLabel)

            if isSelected then
                btn:SetBackdropColor(0.28, 0.20, 0.12, 0.98)
                btn:SetBackdropBorderColor(0.95, 0.75, 0.25, 1)
            else
                btn:SetBackdropColor(0.18, 0.13, 0.09, 0.90)
                btn:SetBackdropBorderColor(0.50, 0.38, 0.26, 0.8)
            end

            btn:SetScript("OnClick", function()
                QuickRPForeverDB.selectedId = item.id
                item.collapsed = not item.collapsed
                RefreshMainWindow()
            end)

            SetFrameTooltip(btn, "Folder: " .. item.name, "Parent folder for grouping text categories.\n- Click to expand/collapse and manage.\n- Drag text groups here to move them inside.")
        else
            local count = item.texts and #item.texts or 0
            local noteIcon = "Interface\\Icons\\INV_Misc_Note_01"
            local pfx = (depth == 1) and "  |T" .. noteIcon .. ":14:14:0:0|t " or "|T" .. noteIcon .. ":14:14:0:0|t "
            local grpLabel = pfx .. item.name .. "  |cff888888(" .. count .. ")|r"

            if isSelected then
                btn:SetText("|cffffd100" .. grpLabel .. "|r")
                btn:SetBackdropColor(0.26, 0.19, 0.12, 0.98)
                btn:SetBackdropBorderColor(0.95, 0.75, 0.25, 1)
            else
                btn:SetText(grpLabel)
                btn:SetBackdropColor(0.14, 0.11, 0.09, 0.85)
                btn:SetBackdropBorderColor(0.35, 0.28, 0.20, 0.8)
            end

            btn:SetScript("OnClick", function()
                QuickRPForeverDB.selectedId = item.id
                RefreshMainWindow()
            end)

            SetFrameTooltip(btn, "Group: " .. item.name, "Roleplay phrase group.\n- Click to view and edit phrases.\n- Drag to reorder or move into folders.")
        end

        btn:Show()
        sy = sy - 30
    end
    groupChild:SetHeight(math.max(1, -sy + 6))

    -- 2. Clear Pools
    for _, card in ipairs(cardPool) do card:Hide() end
    for _, row in ipairs(folderRowPool) do row:Hide() end

    local currentItem = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]

    if not currentItem then
        itemTitle:SetText("|cff888888No item selected|r")
        itemSubInfo:SetText("")
        seqModeBtn:Hide()
        resetSeqBtn:Hide()
        playNextBtn:Hide()
        seqStatusLabel:Hide()
        delItemBtn:Hide()
        addLineChannelBtn:Hide()
        newLineBox:Hide()
        addLineBtn:Hide()
        tokenBannerFrame:Hide()
        lineChild:SetHeight(1)
        return
    end

    delItemBtn:Show()

    -- 3A. RENDER FOLDER MANAGEMENT DASHBOARD
    if currentItem.isFolder then
        seqModeBtn:Hide()
        resetSeqBtn:Hide()
        playNextBtn:Hide()
        seqStatusLabel:Hide()
        addLineChannelBtn:Hide()
        newLineBox:Hide()
        addLineBtn:Hide()
        tokenBannerFrame:Hide()

        itemTitle:SetText("|TInterface\\Icons\\INV_Misc_Bag_08:18:18:0:0|t |cffffd100" .. currentItem.name .. "|r")
        delItemBtn:SetText("Delete Folder")
        playBtn:SetText("> Play")
        SetFrameTooltip(delItemBtn, "Delete Folder", "Permanently deletes this parent folder.\nGroups inside will be safely moved to Root level.")
        SetFrameTooltip(playBtn, "Play Folder", "Plays the first group inside this folder.")

        -- Count children
        local kids = {}
        for _, it in pairs(QuickRPForeverDB.items) do
            if not it.isFolder and it.parentId == currentItem.id then
                table.insert(kids, it)
            end
        end
        table.sort(kids, function(a, b) return (a.order or 1) < (b.order or 1) end)

        itemSubInfo:SetText("|cffaaaaaa(Folder contains " .. #kids .. " group" .. (#kids == 1 and "" or "s") .. ")|r")

        -- Folder quick add group row inside lineChild
        local fy = -4
        for idx, child in ipairs(kids) do
            local row = folderRowPool[idx]
            if not row then
                row = CreateThemedFrame("Frame", nil, lineChild)
                row:SetSize(525, 42)
                row:SetBackdrop(BACKDROP_CARD)
                row:SetBackdropColor(0.12, 0.09, 0.08, 0.90)
                row:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.80)

                local icon = row:CreateTexture(nil, "ARTWORK")
                icon:SetSize(24, 24)
                icon:SetPoint("LEFT", row, "LEFT", 10, 0)
                icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
                row.icon = icon

                local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                lbl:SetPoint("LEFT", icon, "RIGHT", 10, 0)
                row.title = lbl

                local openBtn = CreateTrp3Button(row, "Open", true)
                openBtn:SetSize(60, 24)
                openBtn:SetPoint("RIGHT", row, "RIGHT", -10, 0)
                row.openBtn = openBtn

                local unparentBtn = CreateTrp3Button(row, "Move to Root", false)
                unparentBtn:SetSize(90, 24)
                unparentBtn:SetPoint("RIGHT", openBtn, "LEFT", -6, 0)
                row.unparentBtn = unparentBtn

                local upBtn = CreateTrp3Button(row, "^", false, "GameFontNormalLarge")
                upBtn:SetSize(24, 24)
                upBtn:SetPoint("RIGHT", unparentBtn, "LEFT", -4, 0)
                row.upBtn = upBtn

                local downBtn = CreateTrp3Button(row, "v", false, "GameFontNormalLarge")
                downBtn:SetSize(24, 24)
                downBtn:SetPoint("RIGHT", upBtn, "LEFT", -3, 0)
                row.downBtn = downBtn

                folderRowPool[idx] = row
            end

            row:SetPoint("TOPLEFT", lineChild, "TOPLEFT", 0, fy)
            local msgCount = child.texts and #child.texts or 0
            row.title:SetText(child.name .. "  |cffaaaaaa(" .. msgCount .. " messages - " .. (child.mode or "RANDOM") .. ")|r")

            row.openBtn:SetScript("OnClick", function()
                QuickRPForeverDB.selectedId = child.id
                RefreshMainWindow()
            end)

            row.unparentBtn:SetScript("OnClick", function()
                child.parentId = nil
                RefreshMainWindow()
            end)

            row.upBtn:SetScript("OnClick", function()
                if idx > 1 then
                    local prev = kids[idx - 1]
                    local tmp = child.order or 1
                    child.order = prev.order or 1
                    prev.order = tmp
                    RefreshMainWindow()
                end
            end)

            row.downBtn:SetScript("OnClick", function()
                if idx < #kids then
                    local nxt = kids[idx + 1]
                    local tmp = child.order or 1
                    child.order = nxt.order or 1
                    nxt.order = tmp
                    RefreshMainWindow()
                end
            end)

            row:Show()
            fy = fy - 48
        end
        lineChild:SetHeight(math.max(1, -fy + 6))

    -- 3B. RENDER TEXT GROUP MESSAGE CARDS & SEQUENCE BUILDER
    else
        seqModeBtn:Show()
        playNextBtn:Show()
        addLineChannelBtn:Show()
        newLineBox:Show()
        addLineBtn:Show()
        tokenBannerFrame:Show()
        delItemBtn:SetText("Delete Group")
        playBtn:SetText("▶ Play")
        SetFrameTooltip(delItemBtn, "Delete Group", "Permanently deletes this roleplay group and all of its messages.")
        SetFrameTooltip(playBtn, "Play Group", "Triggers the next/random message from this group.")

        local parentFolder = currentItem.parentId and QuickRPForeverDB.items[currentItem.parentId]
        if parentFolder then
            itemTitle:SetText("|TInterface\\Icons\\INV_Misc_Bag_08:14:14:0:0|t |cffaaaaaa" .. parentFolder.name .. " > |r|cffffd100" .. currentItem.name .. "|r")
        else
            itemTitle:SetText("|cffffd100" .. currentItem.name .. "|r")
        end

        local count = currentItem.texts and #currentItem.texts or 0
        local isSeq = (currentItem.mode == "SEQUENCE")
        itemSubInfo:SetText(isSeq and ("|cffaaaaaa(" .. count .. " steps - Sequential)|r") or ("|cffaaaaaa(" .. count .. " messages - Random)|r"))

        seqModeBtn:SetText(isSeq and "Mode: Sequential 🔄" or "Mode: Random 🎲")

        local nextIdx = 1
        if isSeq then
            resetSeqBtn:Show()
            nextIdx = ((currentItem.lastIndex or 0) % math.max(1, count)) + 1
            seqStatusLabel:SetText("|cffddbb88Next Step:|r |cffffd100#" .. nextIdx .. "|r / " .. count)
            seqStatusLabel:Show()
            playNextBtn:SetText("▶ Play Step #" .. nextIdx)
        else
            resetSeqBtn:Hide()
            seqStatusLabel:SetText("|cffaaaaaaRandom Order|r")
            seqStatusLabel:Show()
            playNextBtn:SetText("▶ Play Random Line")
        end

        local cy = -2
        for i, entry in ipairs(currentItem.texts) do
            local card = cardPool[i]
            if not card then
                card = CreateThemedFrame("Frame", nil, lineChild)
                card:SetSize(525, 48)
                card:SetBackdrop(BACKDROP_CARD)
                card:SetBackdropColor(0.12, 0.09, 0.08, 0.90)
                card:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.80)

                local iconFrame = CreateFrame("Button", nil, card)
                iconFrame:SetSize(34, 34)
                iconFrame:SetPoint("LEFT", card, "LEFT", 7, 0)
                local iconTex = iconFrame:CreateTexture(nil, "ARTWORK")
                iconTex:SetAllPoints(iconFrame)
                iconFrame.icon = iconTex

                local iconBorder = CreateThemedFrame("Frame", nil, iconFrame)
                iconBorder:SetAllPoints(iconFrame)
                iconBorder:SetBackdrop({
                    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    edgeSize = 10,
                    insets   = { left = 1, right = 1, top = 1, bottom = 1 }
                })
                iconBorder:SetBackdropBorderColor(0.55, 0.42, 0.28, 0.9)
                card.iconBtn = iconFrame

                local headerLabel = card:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                headerLabel:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 8, 2)
                card.headerLabel = headerLabel

                local delBtn = CreateTrp3Button(card, "x", false, "GameFontNormal")
                delBtn:SetSize(22, 24)
                delBtn:SetPoint("RIGHT", card, "RIGHT", -6, 0)
                SetFrameTooltip(delBtn, "Delete Step", "Removes this message from the group.")
                card.delBtn = delBtn

                local playBtn = CreateTrp3Button(card, ">", true, "GameFontNormalLarge")
                playBtn:SetSize(24, 24)
                playBtn:SetPoint("RIGHT", delBtn, "LEFT", -4, 0)
                SetFrameTooltip(playBtn, "Play This Step", "Immediately triggers this specific phrase in chat.")
                card.playBtn = playBtn

                local downBtn = CreateTrp3Button(card, "v", false, "GameFontNormal")
                downBtn:SetSize(22, 24)
                downBtn:SetPoint("RIGHT", playBtn, "LEFT", -4, 0)
                SetFrameTooltip(downBtn, "Move Down", "Move this step down in the sequence.")
                card.downBtn = downBtn

                local upBtn = CreateTrp3Button(card, "^", false, "GameFontNormal")
                upBtn:SetSize(22, 24)
                upBtn:SetPoint("RIGHT", downBtn, "LEFT", -3, 0)
                SetFrameTooltip(upBtn, "Move Up", "Move this step up in the sequence.")
                card.upBtn = upBtn

                local editBox = CreateThemedFrame("EditBox", nil, card, "InputBoxTemplate")
                editBox:SetPoint("TOPLEFT", headerLabel, "BOTTOMLEFT", 0, -2)
                editBox:SetPoint("RIGHT", upBtn, "LEFT", -6, 0)
                editBox:SetHeight(20)
                editBox:SetAutoFocus(false)
                editBox:SetFontObject("ChatFontNormal")
                SetFrameTooltip(editBox, "Edit Message", "Click to edit this phrase.\nPress Enter or click outside to save.\nPress Escape to cancel.")
                card.editBox = editBox

                cardPool[i] = card
            end

            card:SetPoint("TOPLEFT", lineChild, "TOPLEFT", 0, cy)

            local chKey = entry.channel or "EMOTE"
            local chInfo = CHANNEL_INFO[chKey] or CHANNEL_INFO.EMOTE

            card.iconBtn.icon:SetTexture(chInfo.icon)

            card.iconBtn:SetScript("OnClick", function(self)
                OpenChannelMenu(self, function(newCh)
                    entry.channel = newCh
                    RefreshMainWindow()
                end, entry.channel)
            end)

            card.iconBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:AddLine("Channel: " .. chInfo.label, chInfo.color.r, chInfo.color.g, chInfo.color.b)
                GameTooltip:AddLine("Click to switch channel", 0.8, 0.8, 0.8)
                GameTooltip:Show()
            end)
            card.iconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            -- Style step vs line
            if isSeq and i == nextIdx then
                card:SetBackdropBorderColor(1.00, 0.82, 0.20, 1.0)
                card:SetBackdropColor(0.20, 0.15, 0.09, 0.95)
                card.headerLabel:SetText("|c" .. chInfo.color.hex .. "[" .. chInfo.label .. "]|r  |cffffd100Step #" .. i .. "|r  |cff00ff00[NEXT STEP]|r")
            elseif isSeq then
                card:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.80)
                card:SetBackdropColor(0.12, 0.09, 0.08, 0.90)
                card.headerLabel:SetText("|c" .. chInfo.color.hex .. "[" .. chInfo.label .. "]|r  |cffaaaaaaStep #" .. i .. "|r")
            else
                card:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.80)
                card:SetBackdropColor(0.12, 0.09, 0.08, 0.90)
                card.headerLabel:SetText("|c" .. chInfo.color.hex .. "[" .. chInfo.label .. "]|r  |cff888888Line #" .. i .. "|r")
            end

            card.editBox:SetText(entry.text or "")
            card.editBox:SetCursorPosition(0)

            local function SaveEditedText(self)
                local updated = strtrim(self:GetText())
                if updated ~= "" then
                    entry.text = updated
                else
                    self:SetText(entry.text or "")
                end
            end

            card.editBox:SetScript("OnEnterPressed", function(self)
                SaveEditedText(self)
                self:ClearFocus()
                print("|cff00ff00[QuickRP Forever]|r Saved step #" .. i)
            end)

            card.editBox:SetScript("OnEditFocusLost", function(self)
                SaveEditedText(self)
            end)

            card.editBox:SetScript("OnEscapePressed", function(self)
                self:SetText(entry.text or "")
                self:ClearFocus()
            end)

            -- Reorder Up & Down buttons
            card.upBtn:SetScript("OnClick", function()
                if i > 1 then
                    local tmp = currentItem.texts[i]
                    currentItem.texts[i] = currentItem.texts[i - 1]
                    currentItem.texts[i - 1] = tmp
                    RefreshMainWindow()
                end
            end)

            card.downBtn:SetScript("OnClick", function()
                if i < #currentItem.texts then
                    local tmp = currentItem.texts[i]
                    currentItem.texts[i] = currentItem.texts[i + 1]
                    currentItem.texts[i + 1] = tmp
                    RefreshMainWindow()
                end
            end)

            card.playBtn:SetScript("OnClick", function()
                currentItem.lastIndex = i
                local text = ReplacePlaceholders(entry.text or "")
                SendChatMessageToChannel(text, entry.channel or "EMOTE")
                RefreshMainWindow()
            end)

            card.delBtn:SetScript("OnClick", function()
                table.remove(currentItem.texts, i)
                RefreshMainWindow()
            end)

            card:Show()
            cy = cy - 54
        end
        lineChild:SetHeight(math.max(1, -cy + 6))
    end
                GameTooltip:AddLine("Send to " .. chInfo.label, 1, 0.82, 0)
                GameTooltip:AddLine("Immediately broadcast this line into chat with all name placeholders filled.", 0.8, 0.8, 0.8, true)
                GameTooltip:Show()
            end)
            card.playBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            card.delBtn:SetScript("OnClick", function()
                table.remove(currentItem.texts, i)
                RefreshMainWindow()
            end)

            if currentItem.lastIndex == i then
                card:SetBackdropBorderColor(0.28, 0.78, 0.35, 1)
            else
                card:SetBackdropBorderColor(0.36, 0.28, 0.20, 0.80)
            end

            card:Show()
            cy = cy - 54
        end
        lineChild:SetHeight(math.max(1, -cy + 6))
    end

    RefreshQuickWindow()
end

-- =========================================================================
-- BUTTON EVENT HANDLERS
-- =========================================================================
addGroupBtn:SetScript("OnClick", function()
    local name = strtrim(newNameBox:GetText())
    if name == "" then
        name = "New Group"
    end
    local gId = "grp_" .. tostring(time()) .. "_" .. math.random(1000, 9999)
    local curItem = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    local parentFolderId = nil
    if curItem then
        if curItem.isFolder then
            parentFolderId = curItem.id
            curItem.collapsed = false
        else
            parentFolderId = curItem.parentId
        end
    end

    QuickRPForeverDB.items[gId] = {
        id = gId,
        name = name,
        isFolder = false,
        parentId = parentFolderId,
        collapsed = false,
        order = 50,
        mode = "RANDOM",
        lastIndex = 0,
        texts = {}
    }
    QuickRPForeverDB.selectedId = gId
    newNameBox:SetText("")
    newNameBox:ClearFocus()
    RefreshMainWindow()
end)

addFolderBtn:SetScript("OnClick", function()
    local name = strtrim(newNameBox:GetText())
    if name == "" then
        name = "New Folder"
    end
    local fId = "folder_" .. tostring(time()) .. "_" .. math.random(1000, 9999)
    QuickRPForeverDB.items[fId] = {
        id = fId,
        name = name,
        isFolder = true,
        parentId = nil,
        collapsed = false,
        order = 10,
    }
    QuickRPForeverDB.selectedId = fId
    newNameBox:SetText("")
    newNameBox:ClearFocus()
    RefreshMainWindow()
end)

newNameBox:SetScript("OnEnterPressed", function()
    local func = addGroupBtn:GetScript("OnClick")
    if func then func(addGroupBtn) end
end)

delItemBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if cur then
        if cur.isFolder then
            -- Unparent all child groups so they aren't lost
            for _, it in pairs(QuickRPForeverDB.items) do
                if it.parentId == cur.id then
                    it.parentId = nil
                end
            end
            print("|cff00ff00[QuickRP Forever]|r Deleted folder '" .. cur.name .. "'. Contained groups moved to root.")
        else
            print("|cff00ff00[QuickRP Forever]|r Deleted group '" .. cur.name .. "'.")
        end
        QuickRPForeverDB.items[cur.id] = nil
        QuickRPForeverDB.selectedId = nil
        RefreshMainWindow()
    end
end)

playBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if not cur then
        print("|cffff8040[QuickRP Forever]|r Please select a group first.")
        return
    end
    if cur.isFolder then
        local firstChild = nil
        for _, it in pairs(QuickRPForeverDB.items) do
            if not it.isFolder and it.parentId == cur.id then
                firstChild = it
                break
            end
        end
        if firstChild then
            TriggerGroup(firstChild.id)
            RefreshMainWindow()
        else
            print("|cffff8040[QuickRP Forever]|r Folder '" .. cur.name .. "' is empty.")
        end
    else
        TriggerGroup(cur.id)
        RefreshMainWindow()
    end
end)

seqModeBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if cur and not cur.isFolder then
        cur.mode = (cur.mode == "RANDOM") and "SEQUENCE" or "RANDOM"
        if cur.mode == "SEQUENCE" then
            cur.lastIndex = 0
        end
        RefreshMainWindow()
    end
end)

resetSeqBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if cur and not cur.isFolder then
        cur.lastIndex = 0
        RefreshMainWindow()
        print("|cff00ff00[QuickRP Forever]|r Sequence progress reset back to Step #1.")
    end
end)

playNextBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    if cur and not cur.isFolder then
        TriggerGroup(cur.id)
        RefreshMainWindow()
    end
end)

addLineBtn:SetScript("OnClick", function()
    local cur = QuickRPForeverDB.items[QuickRPForeverDB.selectedId]
    local raw = newLineBox:GetText()
    if not cur or cur.isFolder or not raw or strtrim(raw) == "" then return end

    cur.texts = cur.texts or {}
    local ch = addLineChannelBtn.currentChannel or "EMOTE"

    local addedCount = 0
    for line in raw:gmatch("[^\r\n]+") do
        local clean = strtrim(line)
        if clean ~= "" then
            local chTag, msgText = clean:match("^%[([%a]+)%]%s*(.+)$")
            local useCh = ch
            if chTag and CHANNEL_INFO[chTag:upper()] then
                useCh = chTag:upper()
                clean = strtrim(msgText)
            end
            table.insert(cur.texts, { text = clean, channel = useCh })
            addedCount = addedCount + 1
        end
    end

    newLineBox:SetText("")
    newLineBox:ClearFocus()
    RefreshMainWindow()
    if addedCount > 1 then
        print("|cff00ff00[QuickRP Forever]|r Added " .. addedCount .. " sequence steps.")
    end
end)

-- =========================================================================
-- MINIMAP BUTTON
-- =========================================================================
local miniBtn = CreateFrame("Button", "QuickRPForeverMinimapButton", Minimap)
miniBtn:SetSize(31, 31)
miniBtn:SetFrameStrata("MEDIUM")
miniBtn:SetFrameLevel(8)
miniBtn:RegisterForClicks("AnyUp")
miniBtn:RegisterForDrag("LeftButton")
miniBtn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local overlay = miniBtn:CreateTexture(nil, "OVERLAY")
overlay:SetSize(53, 53)
overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
overlay:SetPoint("TOPLEFT")

local icon = miniBtn:CreateTexture(nil, "BACKGROUND")
icon:SetSize(20, 20)
icon:SetTexture("Interface\\AddOns\\QuickRPForever\\qrpf")
icon:SetPoint("CENTER", 0, 1)

local function UpdateMinimapPosition()
    local angle = math.rad((QuickRPForeverDB and QuickRPForeverDB.minimapAngle) or 220)
    local radius = 80
    miniBtn:ClearAllPoints()
    miniBtn:SetPoint("CENTER", Minimap, "CENTER", math.cos(angle) * radius, math.sin(angle) * radius)
end

miniBtn:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
        local mx, my = Minimap:GetCenter()
        local px, py = GetCursorPosition()
        local scale = Minimap:GetEffectiveScale()
        px, py = px / scale, py / scale
        QuickRPForeverDB.minimapAngle = math.deg(math.atan2(py - my, px - mx))
        UpdateMinimapPosition()
    end)
end)

miniBtn:SetScript("OnDragStop", function(self)
    self:SetScript("OnUpdate", nil)
end)

miniBtn:SetScript("OnClick", function(_, button)
    if button == "RightButton" then
        if rpWin:IsShown() then
            rpWin:Hide()
        else
            RefreshQuickWindow()
            rpWin:Show()
        end
    else
        if mainWin:IsShown() then
            mainWin:Hide()
        else
            RefreshMainWindow()
            mainWin:Show()
        end
    end
end)

miniBtn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("QuickRP Forever", 1, 0.82, 0)
    GameTooltip:AddLine("|cffffffffLeft-Click|r: Open/Close Editor", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("|cffffffffRight-Click|r: Toggle Quick RP Window", 0.85, 0.85, 0.85)
    GameTooltip:AddLine("|cffffffffDrag|r: Move minimap icon", 0.85, 0.85, 0.85)
    GameTooltip:Show()
end)

miniBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

-- =========================================================================
-- OPTIONS / ADDON SETTINGS PANEL (GAME MENU -> OPTIONS -> ADDONS)
-- =========================================================================
local optionsPanel = CreateThemedFrame("Frame", "QuickRPForeverOptionsPanel")
optionsPanel.name = "QuickRP Forever"
local optionsCategory = nil

local optTitle = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
optTitle:SetPoint("TOPLEFT", optionsPanel, "TOPLEFT", 16, -16)
optTitle:SetText("|cffffd100QuickRP Forever|r")

local optSub = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
optSub:SetPoint("TOPLEFT", optTitle, "BOTTOMLEFT", 0, -4)
optSub:SetText("|cffaaaaaaLightweight Roleplay Emote & Message Suite for WoW: Forever|r")

local optIcon = optionsPanel:CreateTexture(nil, "ARTWORK")
optIcon:SetSize(42, 42)
optIcon:SetPoint("TOPRIGHT", optionsPanel, "TOPRIGHT", -24, -16)
optIcon:SetTexture("Interface\\AddOns\\QuickRPForever\\qrpf")

-- Action Buttons in Options
local optOpenEditorBtn = CreateTrp3Button(optionsPanel, "Open QuickRP Editor", true)
optOpenEditorBtn:SetSize(170, 26)
optOpenEditorBtn:SetPoint("TOPLEFT", optSub, "BOTTOMLEFT", 0, -18)
optOpenEditorBtn:SetScript("OnClick", function()
    if not mainWin:IsShown() then
        RefreshMainWindow()
        mainWin:Show()
    end
end)
SetFrameTooltip(optOpenEditorBtn, "Open Editor", "Opens the main QuickRP Forever editor window.")

local optOpenQuickBtn = CreateTrp3Button(optionsPanel, "Toggle Quick RP Window", false)
optOpenQuickBtn:SetSize(180, 26)
optOpenQuickBtn:SetPoint("LEFT", optOpenEditorBtn, "RIGHT", 10, 0)
optOpenQuickBtn:SetScript("OnClick", function()
    if rpWin:IsShown() then
        rpWin:Hide()
    else
        RefreshQuickWindow()
        rpWin:Show()
    end
end)
SetFrameTooltip(optOpenQuickBtn, "Toggle Quick Window", "Opens or closes the compact on-screen roleplay button window.")

local optImpExpBtn = CreateTrp3Button(optionsPanel, "Import / Export Content", false)
optImpExpBtn:SetSize(180, 26)
optImpExpBtn:SetPoint("LEFT", optOpenQuickBtn, "RIGHT", 10, 0)
optImpExpBtn:SetScript("OnClick", function()
    OpenImpExpWindow("EXPORT")
end)
SetFrameTooltip(optImpExpBtn, "Import & Export", "Backup or share your roleplay packs.")

-- Minimap Checkbox
local minimapCheck = CreateFrame("CheckButton", "QuickRPForeverMinimapCheck", optionsPanel, "UICheckButtonTemplate")
minimapCheck:SetPoint("TOPLEFT", optOpenEditorBtn, "BOTTOMLEFT", 0, -16)
minimapCheck.text = minimapCheck:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
minimapCheck.text:SetPoint("LEFT", minimapCheck, "RIGHT", 6, 0)
minimapCheck.text:SetText("Show Minimap Button")
minimapCheck:SetScript("OnClick", function(self)
    local checked = self:GetChecked()
    QuickRPForeverDB.showMinimap = checked
    if checked then
        miniBtn:Show()
        UpdateMinimapPosition()
    else
        miniBtn:Hide()
    end
end)
SetFrameTooltip(minimapCheck, "Minimap Icon", "Enable or disable the QuickRP Forever icon attached to your minimap.")

-- Reset defaults button
local resetDefaultsBtn = CreateTrp3Button(optionsPanel, "Restore Default Content", false)
resetDefaultsBtn:SetSize(170, 24)
resetDefaultsBtn:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", 0, -14)
resetDefaultsBtn:SetScript("OnClick", function()
    for id, it in pairs(DefaultData.items) do
        if not QuickRPForeverDB.items[id] then
            QuickRPForeverDB.items[id] = it
        end
    end
    RefreshMainWindow()
    RefreshQuickWindow()
    print("|cff00ff00[QuickRP Forever]|r Default roleplay content verified and restored.")
end)
SetFrameTooltip(resetDefaultsBtn, "Restore Defaults", "Restores default character folders and groups if deleted.")

local divider = optionsPanel:CreateTexture(nil, "ARTWORK")
divider:SetHeight(1)
divider:SetPoint("TOPLEFT", resetDefaultsBtn, "BOTTOMLEFT", 0, -18)
divider:SetPoint("RIGHT", optionsPanel, "RIGHT", -24, 0)
divider:SetColorTexture(0.40, 0.30, 0.20, 0.6)

local guideHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
guideHeader:SetPoint("TOPLEFT", divider, "BOTTOMLEFT", 0, -14)
guideHeader:SetText("|cffffd100Quick Reference & Commands|r")

local guideBody = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
guideBody:SetPoint("TOPLEFT", guideHeader, "BOTTOMLEFT", 0, -6)
guideBody:SetPoint("RIGHT", optionsPanel, "RIGHT", -24, 0)
guideBody:SetJustifyH("LEFT")
guideBody:SetText([[|cffffd100Chat Commands:|r
  |cffffffff/qrp|r or |cffffffff/rp|r - Open/close the main editor window
  |cffffffff/qrp win|r - Toggle the compact RP quick-window
  |cffffffff/qrp <group>|r - Send the next/random message from <group>
  |cffffffff/qrp opt|r - Open this settings panel
  |cffffffff/qrp exp|r or |cffffffff/qrp imp|r - Open the Import & Export window

|cffffd100Hierarchy & Drag & Drop:|r
  - Create parent folders with |cffffffff[+ New Folder]|r to organize groups by Character or Situation.
  - Drag text groups onto a folder to nest them inside!
  - Drag items to reorder them in the list.

|cffffd100Dynamic Name Placeholders:|r
  |cffffffff%pf|r = Your first name  |  |cffffffff%pl|r = Your last name  |  |cffffffff%p|r = Your full name
  |cffffffff%tf|r = Target first name  |  |cffffffff%tl|r = Target last name  |  |cffffffff%t|r = Target full name]])

if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
    optionsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, "QuickRP Forever")
    Settings.RegisterAddOnCategory(optionsCategory)
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(optionsPanel)
end

local function OpenSettings()
    if Settings and Settings.OpenToCategory and optionsCategory then
        Settings.OpenToCategory(optionsCategory:GetID())
    elseif InterfaceOptionsFrame_OpenToCategory then
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
        InterfaceOptionsFrame_OpenToCategory(optionsPanel)
    end
end

-- =========================================================================
-- INITIALIZATION & SLASH COMMANDS
-- =========================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddon)
    if loadedAddon == addonName then
        if not QuickRPForeverDB then
            QuickRPForeverDB = {
                minimapAngle = DefaultData.minimapAngle,
                showMinimap = DefaultData.showMinimap,
                selectedId = DefaultData.selectedId,
                items = DefaultData.items
            }
        end

        -- Seamless data migration from legacy flat 'groups' table to hierarchical 'items'
        if not QuickRPForeverDB.items then
            QuickRPForeverDB.items = {}
            local orderIdx = 1
            if QuickRPForeverDB.groups then
                for gName, gData in pairs(QuickRPForeverDB.groups) do
                    local gId = "grp_" .. tostring(gName):gsub("%s+", "_"):lower()
                    QuickRPForeverDB.items[gId] = {
                        id = gId,
                        name = gName,
                        isFolder = false,
                        parentId = nil,
                        collapsed = false,
                        order = orderIdx,
                        mode = gData.mode or "RANDOM",
                        lastIndex = gData.lastIndex or 0,
                        texts = gData.texts or {}
                    }
                    orderIdx = orderIdx + 1
                end
            end
        end

        -- If still empty, restore defaults
        if not next(QuickRPForeverDB.items) then
            for id, it in pairs(DefaultData.items) do
                QuickRPForeverDB.items[id] = it
            end
            QuickRPForeverDB.selectedId = DefaultData.selectedId
        end

        if QuickRPForeverDB.showMinimap == nil then
            QuickRPForeverDB.showMinimap = true
        end

        if QuickRPForeverDB.showMinimap then
            miniBtn:Show()
            UpdateMinimapPosition()
        else
            miniBtn:Hide()
        end

        if minimapCheck then
            minimapCheck:SetChecked(QuickRPForeverDB.showMinimap ~= false)
        end

        RefreshMainWindow()
    end
end)

SLASH_QUICKRPFOREVER1 = "/qrp"
SLASH_QUICKRPFOREVER2 = "/rp"
SlashCmdList["QUICKRPFOREVER"] = function(msg)
    local arg = strtrim(msg or "")
    if arg == "" then
        if mainWin:IsShown() then
            mainWin:Hide()
        else
            RefreshMainWindow()
            mainWin:Show()
        end
    elseif arg:lower() == "win" then
        if rpWin:IsShown() then
            rpWin:Hide()
        else
            RefreshQuickWindow()
            rpWin:Show()
        end
    elseif arg:lower() == "opt" or arg:lower() == "options" or arg:lower() == "config" or arg:lower() == "settings" then
        OpenSettings()
    elseif arg:lower() == "exp" or arg:lower() == "export" then
        OpenImpExpWindow("EXPORT")
    elseif arg:lower() == "imp" or arg:lower() == "import" then
        OpenImpExpWindow("IMPORT")
    else
        TriggerGroup(arg)
    end
end
