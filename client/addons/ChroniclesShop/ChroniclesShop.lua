-- Chronicles Shop (#64): the shop window from the micro menu Shop button, /shop and ToggleStoreUI (the premium menu's
-- Buy Premium). It talks to the server's donate_shop_addon script (many_in_one_donate.cpp) through addon messages with
-- the prefix "SHOP"; the server checks and delivers everything, this addon only draws the shop.
-- One record per message, fields separated by spaces, the name last. Protocol v2 adds the fields after '#', so a v1
-- server (no '#' fields) still parses; v3 (phase 3) only adds optional fields and new commands:
--   client -> server: OPEN | LIST <categoryId> [ilvl] | BUY <productId> <shownPrice> <reqId> [ilvl]
--                     | BUYN <productId> <count> <shownTotal> <reqId> (type 10 only)
--                     | MORPH <productId> <reqId> (use an owned morph) | MORPH 0 <reqId> (remove it)
--                     | PERKS <bag> <slot> (bag 0-4, slot from 1: bag items only)
--                     | PERKADD <bag> <slot> <perkId> <shownPrice> <reqId> <itemEntry>
--                     | PERKDEL <bag> <slot> <perkId> <reqId> <itemEntry> (itemEntry = the one PEND sent)
--   server -> client: CLOSED | BAL <tokens> | CAT <id> <parentId> <order> #<flags> <name> ... CEND
--                     | ITEM <productId> <type> <param1> <price> <ilvl> <bonuses> #<flags> <display> <name> ...
--                       [ILV <categoryId> <current> <ilvl>,<ilvl>,...] LEND <categoryId> <count>
--                     | PERK <perkId> <price> <has 1|0> #<flags> <name> ... PEND <bag> <slot> <itemEntry>
--                     | OK <reqId> <productId|perkId> <tokens> [MAIL] | FAIL <reqId> <code> <tokens> | ERR <text>
--   flags: 1 = KNOWN (ITEM: the character or account has it already), 2 = NEW (ITEM: added lately; CAT: a new product
--   in it or below); PERK flags: 1 = BLOCKED (cannot be added to this item)
--   display = creature display ID of a mount, pet or morph for the 3D preview (0 = none); MAIL = the bags were full,
--   sent by mail; ILV lists the item levels of a category, highest first, current = the one the list is shown at;
--   PEND itemEntry 0 = nothing usable in that bag slot (no PERK lines); an ERR line can come right before a FAIL
--   FAIL codes: NOFUNDS GONE PRICE BAGS OWNED BUSY CLOSED FAILED NOART NOITEM LIMIT
local PREFIX = "SHOP"
local ICON = "Interface\\Icons\\"
local COIN = "|T" .. ICON .. "WoW_Token01:16:16:0:0:64:64:5:59:5:59|t"   -- after every price
local STORE_ART = "Interface\\Store\\Store-Main"   -- Blizzard's store art, texcoords from Blizzard_StoreUIPatchwerk.xml
local ROW_HEIGHT = 40
local ROW_WIDTH = 516
local CARD_WIDTH, CARD_HEIGHT = 254, 64   -- two cards per line
local BANNER_HEIGHT = 156
local LIST_HEIGHT = 496     -- height of the insets
local PREVIEW_WIDTH = 230   -- the 3D preview on the right; the window stays within 1024 wide at UI scale 1
local TABS_WIDTH = 540
local CAT_HEIGHT = 38
local PERKS_CAT = -1        -- the perks editor's own category (the server lists no perks, they come through PERKS)
local VISIBLE_CATS = math.floor((LIST_HEIGHT - 20) / CAT_HEIGHT)
local FLAG_KNOWN, FLAG_NEW = 1, 2
local PERK_BLOCKED = 1
local NEW_TAG = "|cff20ff20NEW|r"   -- after a new product's name
local NEW_MARK = "|cff20ff20!|r"    -- on a category or tab with a new product in it
local GREEN = "|cff20ff20%s|r"

-- tabs with these names become paper doll slot icons (Blizzard's back slot uses the chest picture too)
local SLOT_ART = "Interface\\PaperDoll\\UI-PaperDoll-Slot-"
local SLOT_ICONS = {
    head = "Head", neck = "Neck", shoulder = "Shoulder", shoulders = "Shoulder", back = "Chest", cloak = "Chest",
    chest = "Chest", shirt = "Shirt", tabard = "Tabard", wrist = "Wrists", wrists = "Wrists", hands = "Hands",
    waist = "Waist", legs = "Legs", feet = "Feet", finger = "Finger", rings = "Finger", trinket = "Trinket",
    trinkets = "Trinket", ["main hand"] = "MainHand", ["off hand"] = "SecondaryHand", relic = "Relic", relics = "Relic",
}

-- DonateProductType in many_in_one_donate.cpp; items get their own icon from the client
local TYPE_ITEM, TYPE_TITLE, TYPE_SPELL, TYPE_PREMIUM, TYPE_SERVICE = 0, 2, 4, 7, 8
local TYPE_MORPH, TYPE_ARTLEVEL, TYPE_BUNDLE, TYPE_QUEST = 9, 10, 11, 12
local TYPE_ICONS = {
    [1] = ICON .. "INV_Misc_Coin_17",           -- currency
    [2] = ICON .. "INV_Scroll_03",              -- title
    [3] = ICON .. "Achievement_General",        -- achievement
    [4] = ICON .. "Ability_Mount_RidingHorse",  -- spell (mounts, pets)
    [5] = ICON .. "Achievement_Level_110",      -- level
    [6] = ICON .. "INV_Misc_Coin_01",           -- gold
    [7] = ICON .. "INV_Crown_02",               -- premium days
    [8] = ICON .. "INV_Misc_Note_01",           -- character service (rename, appearance, faction, race)
    [9] = ICON .. "Ability_Rogue_Disguise",     -- morph
    [10] = ICON .. "Spell_Holy_ChampionsBond",  -- artifact levels
    [11] = ICON .. "INV_Misc_Bag_10",           -- bundle (starter pack)
    [12] = ICON .. "INV_Scroll_11",             -- quest (hidden artifact appearance)
}
local UNKNOWN_ICON = ICON .. "INV_Misc_QuestionMark"
local EMPTY_SLOT = "Interface\\PaperDoll\\UI-Backpack-EmptySlot"
local LOGOUT_TEXT = "Log out to the character screen to use it."
local NOART_TEXT = "You must have an artifact weapon equipped."

-- products shown as cards (with the preview) instead of rows: titles, mounts and pets, morphs, anything with a display
local CARD_TYPES = { [TYPE_TITLE] = true, [TYPE_SPELL] = true, [TYPE_MORPH] = true }

local FAIL_TEXT = {
    NOFUNDS = "You don't have enough tokens.",
    GONE = "This product is not available any more.",
    PRICE = "The price has changed. Please check it and try again.",
    BAGS = "Your bags are full. Free a bag slot and try again.",
    OWNED = "You already have this.",
    BUSY = "Too many requests. Please wait a moment.",
    CLOSED = "The shop is not open yet.",
    FAILED = "The purchase failed. No tokens were taken.",
    NOART = NOART_TEXT,
    NOITEM = "That item is not in its bag slot any more. Drag it in again.",
    LIMIT = "You can't buy that many at once.",
}
local STATUS_TEXT = {
    loading = "Loading...",
    closed = "The shop is not open yet.",
    offline = "The shop is not available right now.",
}

local state = "loading"             -- loading | ready | closed | offline
local cats, newCats = {}, {}        -- categories by id (newCats fills until CEND)
local children = {}                 -- sorted child ids by parent id, 0 = top level
local lists, products = {}, {}      -- product lists by category (dropped on open and after a purchase); products by id
local incoming = {}                 -- ITEMs of the list being received, until LEND
local incomingIlv                   -- the ILV of the list being received
local ilvInfo = {}                  -- category -> { current = ilvl, levels = { ilvl, ... } }
local selIlvl                       -- the item level the player picked (nil = the server's default)
local bundleParts = {}              -- bundle productId -> { line, ... } (optional BPART lines, see UpdateBanner)
local requested = {}                -- category -> GetTime() of its last LIST
local selTop, selTab, selSubTab     -- selected category and tabs
local shownCat                      -- category whose products are shown
local listMode = "rows"             -- rows | cards | bundles | artifact | perks
local listTop = 10                  -- y of the first row in the right inset, below the tabs
local catOffset = 0                 -- first category shown in the left column (scrolled with the mouse wheel)
local pending                       -- reqId of the request waiting for OK/FAIL
local reqs = {}                     -- reqId -> { kind = buy|buyn|morph|perkadd|perkdel, product, perk, count }
local lastReqId = 0
local previewed                     -- product in the preview panel
local perkItem                      -- { bag, slot, entry, link, perks } of the perks editor
local perkNote                      -- text of the empty perks editor
local incomingPerks = {}            -- PERKs being received, until PEND
local Refresh, UpdateRows, ShowConfirm, Preview, UpdatePreviewButtons

RegisterAddonMessagePrefix(PREFIX)

local function Send(msg)
    SendAddonMessage(PREFIX, msg, "WHISPER", UnitName("player"))
end

-- item string with the product's bonus lists, so the tooltip shows the item level that is delivered:
-- item:id:enchant:gem1:gem2:gem3:gem4:suffix:unique:linkLevel:spec:upgradeType:difficulty:numBonusIDs:bonusIDs...
local function ItemLink(itemId, bonuses)
    if not bonuses:find("%d") then
        return "item:" .. itemId
    end
    local count = select(2, bonuses:gsub(",", "")) + 1
    return ("item:%d::::::::%d::::%d:%s"):format(itemId, UnitLevel("player"), count, (bonuses:gsub(",", ":")))
end

-- a title with your own name, like the title list shows it ("Conqueror Chron", "Chron of the Black Harvest").
-- The server sends the plain title; the client's own title list (GetTitleName, by mask ID) knows where the name goes.
-- ponytail: matched by the title's text; a title the list doesn't know is guessed ("of ..."/"the ..." after the name)
local titleFormats
local function TitleText(name)
    if not titleFormats then
        titleFormats = {}
        for i = 1, GetNumTitles() do
            local raw = GetTitleName(i)
            if raw and raw ~= "" then
                titleFormats[(strtrim(raw):gsub("^,%s*", "")):lower()] = raw
            end
        end
    end
    local me = UnitName("player")
    local raw = titleFormats[name:lower()]
    if raw then
        if raw:find("^[%s,]") then
            return me .. raw
        end
        return raw:find("%s$") and raw .. me or raw .. " " .. me
    end
    if name:find("^of ") or name:find("^the ") then
        return me .. " " .. name
    end
    return name .. " " .. me
end

-- icon, name and colour of a product; item names come from the client's item cache (the server's name until then)
local function Describe(p)
    if p.type == TYPE_ITEM then
        local name, _, quality = GetItemInfo(p.link)
        local color = ITEM_QUALITY_COLORS[quality] or HIGHLIGHT_FONT_COLOR
        return select(5, GetItemInfoInstant(p.param1)) or UNKNOWN_ICON, name or p.name, color.r, color.g, color.b
    end
    local name = p.type == TYPE_TITLE and TitleText(p.name) or p.name
    return TYPE_ICONS[p.type] or UNKNOWN_ICON, name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
end

local function Price(tokens)
    return tokens .. " " .. COIN
end

-- "Already Known", or "Owned" for a morph (the account has it: use it from the preview)
local function KnownText(p)
    return GREEN:format(p.type == TYPE_MORPH and "Owned" or "Already Known")
end

local function CatName(id)
    return cats[id].new and cats[id].name .. " " .. NEW_MARK or cats[id].name
end

local function StoreTexture(parent, layer, left, right, top, bottom)
    local tex = parent:CreateTexture(nil, layer)
    tex:SetTexture(STORE_ART)
    tex:SetTexCoord(left, right, top, bottom)
    return tex
end

local function Background(frame, alpha)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, alpha)
    return bg
end

local function Error(text)
    UIErrorsFrame:AddMessage(text, 1, 0.3, 0.3)
end

-- ---------------------------------------------------------------- requests
-- one request at a time; the server answers OK or FAIL with the reqId. No answer in 5 s: the buttons come back
local function Request(info, build)
    lastReqId = lastReqId % 999999 + 1
    local reqId = lastReqId
    reqs[reqId] = info
    pending = reqId
    Send(build(reqId))
    C_Timer.After(5, function()
        if pending == reqId then   -- no answer yet: the server may still deliver it
            pending = nil
            Error("The shop has not answered yet. Check your balance before buying again.")
            UpdateRows()
        end
    end)
    UpdateRows()
    return reqId
end

-- ---------------------------------------------------------------- window
local frame = CreateFrame("Frame", "ChroniclesShopFrame", UIParent, "PortraitFrameTemplate")
frame:SetSize(1000, 544)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetToplevel(true)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:Hide()
tinsert(UISpecialFrames, "ChroniclesShopFrame")   -- Escape closes it
SetPortraitToTexture(frame.portrait, ICON .. "WoW_Store")
frame.TitleText:SetText("Shop")

local balanceText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
balanceText:SetPoint("TOPRIGHT", -16, -27)

local left = CreateFrame("Frame", "$parentLeftInset", frame, "InsetFrameTemplate")
left:SetPoint("TOPLEFT", 4, -44)
left:SetSize(192, LIST_HEIGHT)
local leftArt = StoreTexture(left, "BACKGROUND", 0.00097656, 0.18261719, 0.46289063, 0.93652344)   -- store-category-bg
leftArt:SetPoint("TOPLEFT", 3, -3)
leftArt:SetPoint("BOTTOMRIGHT", -3, 3)

local preview = CreateFrame("Frame", "$parentPreviewInset", frame, "InsetFrameTemplate")
preview:SetPoint("TOPRIGHT", -6, -44)
preview:SetSize(PREVIEW_WIDTH, LIST_HEIGHT)
preview.name = preview:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
preview.name:SetPoint("TOPLEFT", 10, -12)
preview.name:SetPoint("TOPRIGHT", -10, -12)
preview.icon = preview:CreateTexture(nil, "ARTWORK")
preview.icon:SetSize(64, 64)
preview.icon:SetPoint("CENTER")

-- your own character wearing the item, or the mount, pet or morph; drag with the left button to turn it
-- ponytail: no zoom or panning, add mouse wheel -> SetCamDistanceScale if players want a closer look
local model = CreateFrame("DressUpModel", nil, preview)
model:SetPoint("TOPLEFT", 4, -56)
model:SetPoint("BOTTOMRIGHT", -4, 38)
model:EnableMouse(true)
model:Hide()
model:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" then
        self.dragX, self.dragFacing = GetCursorPosition(), self:GetFacing()
    end
end)
model:SetScript("OnMouseUp", function(self) self.dragX = nil end)
model:SetScript("OnHide", function(self) self.dragX = nil end)
model:SetScript("OnUpdate", function(self)
    if self.dragX then
        self:SetFacing(self.dragFacing + (GetCursorPosition() - self.dragX) / 100)
    end
end)

local function PreviewButton(text, width)
    local b = CreateFrame("Button", nil, preview, "UIPanelButtonTemplate")
    b:SetSize(width, 24)
    b:SetText(text)
    b:Hide()
    return b
end
preview.buy = PreviewButton("Purchase", 140)
preview.buy:SetPoint("BOTTOM", 0, 8)
preview.buy:SetScript("OnClick", function() ShowConfirm(previewed) end)
preview.use = PreviewButton("Use", 100)
preview.use:SetPoint("BOTTOMRIGHT", preview, "BOTTOM", -3, 8)
preview.use:SetScript("OnClick", function()
    local p = previewed
    Request({ kind = "morph", product = p }, function(reqId) return "MORPH " .. p.id .. " " .. reqId end)
end)
preview.remove = PreviewButton("Remove", 100)
preview.remove:SetPoint("BOTTOMLEFT", preview, "BOTTOM", 3, 8)
preview.remove:SetScript("OnClick", function()
    Request({ kind = "morph" }, function(reqId) return "MORPH 0 " .. reqId end)
end)

local right = CreateFrame("Frame", "$parentRightInset", frame, "InsetFrameTemplate")
right:SetPoint("TOPLEFT", 198, -44)
right:SetPoint("BOTTOMRIGHT", preview, "BOTTOMLEFT", -2, 0)

local status = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
status:SetPoint("CENTER")

local scroll = CreateFrame("ScrollFrame", "$parentList", right, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -listTop)
scroll:SetPoint("BOTTOMRIGHT", -30, 8)
scroll.lineHeight = ROW_HEIGHT
scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, self.lineHeight, UpdateRows)
end)

local function ResetScroll()
    FauxScrollFrame_SetOffset(scroll, 0)
    scroll.ScrollBar:SetValue(0)
end

-- filters the shown list by name as you type; Escape clears it (a second Escape closes the shop)
-- ponytail: only the shown category's list, a shop-wide search needs a SEARCH command on the server
local search = CreateFrame("EditBox", "$parentSearch", frame, "SearchBoxTemplate")
search:SetSize(180, 20)
search:SetPoint("BOTTOMRIGHT", right, "TOPRIGHT", -4, 1)
search:SetAutoFocus(false)
search:SetScript("OnEscapePressed", function(self)
    self:SetText("")
    self:ClearFocus()
end)
search:SetScript("OnEnterPressed", EditBox_ClearFocus)
search:HookScript("OnTextChanged", function()
    ResetScroll()
    UpdateRows()
end)

-- item level of the shown list (from ILV); a choice is kept for every list until the shop closes
local ilvlDrop = CreateFrame("Frame", "ChroniclesShopItemLevel", frame, "UIDropDownMenuTemplate")
ilvlDrop:SetPoint("RIGHT", search, "LEFT", 4, -3)
UIDropDownMenu_SetWidth(ilvlDrop, 110)
ilvlDrop:Hide()

local function SelectIlvl(_, level)
    selIlvl = level
    wipe(lists)       -- every item-level list changes price and item level
    wipe(requested)
    ResetScroll()
    Refresh()
end

UIDropDownMenu_Initialize(ilvlDrop, function(self, level)
    local info = shownCat and ilvInfo[shownCat]
    if not info then return end
    for _, ilvl in ipairs(info.levels) do
        local button = UIDropDownMenu_CreateInfo()
        button.text = "Item level " .. ilvl
        button.arg1 = ilvl
        button.checked = ilvl == info.current
        button.func = SelectIlvl
        UIDropDownMenu_AddButton(button, level)
    end
end)

-- UpdateMicroButtons disables the Shop button while Blizzard's store is off (Bpay.Enabled = 0): turn it back on
local function UpdateMicroButton()
    StoreMicroButton:Enable()
    if frame:IsShown() then
        StoreMicroButton:SetButtonState("PUSHED", true)
    else
        StoreMicroButton:SetButtonState("NORMAL")
    end
end

-- ---------------------------------------------------------------- product rows, cards and banners
local rows, cards, banners = {}, {}, {}

local function RowOnEnter(self)
    if self.product.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.product.link)
        GameTooltip:Show()
    end
end

local function RowOnClick(self)
    Preview(self.product)
end

local function Row(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, right)   -- not in the scroll frame: FauxScrollFrame_Update hides it for short lists
    row:SetSize(ROW_WIDTH, ROW_HEIGHT - 4)
    Background(row, 0.5)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", 2, 0)
    row.name = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.name:SetWidth(220)
    row.name:SetJustifyH("LEFT")
    row.ilvl = row:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    row.ilvl:SetPoint("LEFT", 270, 0)
    row.buy = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.buy:SetSize(80, 22)
    row.buy:SetPoint("RIGHT", -6, 0)
    row.buy:SetText("Buy")
    row.buy:SetScript("OnClick", function(self) ShowConfirm(self:GetParent().product) end)
    row.known = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")   -- instead of Buy: nothing to buy
    row.known:SetPoint("CENTER", row.buy)
    row.price = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.price:SetPoint("RIGHT", row.buy, "LEFT", -12, 0)
    row:SetScript("OnClick", RowOnClick)
    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[i] = row
    return row
end

local function FillRow(row, p)
    local icon, name, r, g, b = Describe(p)
    row.icon:SetTexture(icon)
    row.name:SetText(p.new and name .. " " .. NEW_TAG or name)
    row.name:SetTextColor(r, g, b)
    row.ilvl:SetText(p.ilvl > 0 and "Item level " .. p.ilvl or "")
    row.price:SetText(Price(p.price))
    row.known:SetText(KnownText(p))
    row.buy:SetShown(not p.known)
    row.known:SetShown(p.known)
end

-- a card: icon, name (two lines), price or Already Known / Owned; a click previews it, Purchase is under the preview
local function Card(i)
    local card = cards[i]
    if card then return card end
    card = CreateFrame("Button", nil, right)
    card:SetSize(CARD_WIDTH, CARD_HEIGHT - 6)
    Background(card, 0.5)
    card:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetSize(40, 40)
    card.icon:SetPoint("LEFT", 6, 0)
    card.name = card:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 8, 2)
    card.name:SetSize(CARD_WIDTH - 62, 28)
    card.name:SetJustifyH("LEFT")
    card.name:SetJustifyV("TOP")
    card.price = card:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    card.price:SetPoint("BOTTOMRIGHT", -8, 5)
    card:SetScript("OnClick", RowOnClick)
    card:SetScript("OnEnter", RowOnEnter)
    card:SetScript("OnLeave", GameTooltip_Hide)
    cards[i] = card
    return card
end

local function FillCard(card, p)
    local icon, name, r, g, b = Describe(p)
    card.icon:SetTexture(icon)
    card.name:SetText(p.new and name .. " " .. NEW_TAG or name)
    card.name:SetTextColor(r, g, b)
    card.price:SetText(p.known and KnownText(p) or Price(p.price))
end

-- a starter pack: name, "You will receive:" and its parts, price, Buy Now.
-- The parts come from optional "BPART <productId> <text>" lines after the pack's ITEM line; without them one line.
local function Banner(i)
    local banner = banners[i]
    if banner then return banner end
    banner = CreateFrame("Frame", nil, right)
    banner:SetSize(ROW_WIDTH, BANNER_HEIGHT - 8)
    Background(banner, 0.6)
    local art = StoreTexture(banner, "BORDER", 0.56542969, 0.73730469, 0.41992188, 0.45703125)   -- store-category
    art:SetPoint("TOPLEFT")
    art:SetPoint("TOPRIGHT")
    art:SetHeight(34)
    banner.icon = banner:CreateTexture(nil, "ARTWORK")
    banner.icon:SetSize(56, 56)
    banner.icon:SetPoint("TOPRIGHT", -14, -44)
    banner.name = banner:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    banner.name:SetPoint("TOPLEFT", 14, -9)
    banner.name:SetPoint("TOPRIGHT", -14, -9)
    banner.name:SetJustifyH("LEFT")
    banner.header = banner:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    banner.header:SetPoint("TOPLEFT", 14, -42)
    banner.header:SetText("You will receive:")
    banner.parts = banner:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    banner.parts:SetPoint("TOPLEFT", banner.header, "BOTTOMLEFT", 4, -4)
    banner.parts:SetSize(ROW_WIDTH - 110, 56)
    banner.parts:SetJustifyH("LEFT")
    banner.parts:SetJustifyV("TOP")
    banner.price = banner:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    banner.price:SetPoint("BOTTOMLEFT", 14, 12)
    banner.buy = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate")
    banner.buy:SetSize(120, 24)
    banner.buy:SetPoint("BOTTOMRIGHT", -14, 10)
    banner.buy:SetText("Buy Now")
    banner.buy:SetScript("OnClick", function(self) ShowConfirm(self:GetParent().product) end)
    banners[i] = banner
    return banner
end

local function FillBanner(banner, p)
    local icon, name = Describe(p)
    banner.icon:SetTexture(icon)
    banner.name:SetText(p.new and name .. " " .. NEW_TAG or name)
    local parts = bundleParts[p.id]
    banner.parts:SetText(parts and "- " .. table.concat(parts, "\n- ") or "Everything in the pack, delivered at once.")
    banner.price:SetText(Price(p.price))
    banner.buy:SetEnabled(not pending)
end

-- list modes drawn in the scrolling list: widget pool, maker, filler, line height, widgets per line, width
local LIST_MODES = {
    rows = { pool = rows, make = Row, fill = FillRow, height = ROW_HEIGHT, perLine = 1, width = ROW_WIDTH },
    cards = { pool = cards, make = Card, fill = FillCard, height = CARD_HEIGHT, perLine = 2, width = CARD_WIDTH + 8 },
    bundles = { pool = banners, make = Banner, fill = FillBanner, height = BANNER_HEIGHT, perLine = 1, width = ROW_WIDTH },
}

-- ---------------------------------------------------------------- artifact levels (type 10)
local artPanel = CreateFrame("Frame", nil, right)
artPanel:SetPoint("BOTTOMRIGHT", -8, 8)
artPanel:Hide()
Background(artPanel, 0.5)
artPanel.icon = artPanel:CreateTexture(nil, "ARTWORK")
artPanel.icon:SetSize(48, 48)
artPanel.icon:SetPoint("TOPLEFT", 20, -20)
artPanel.name = artPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
artPanel.name:SetPoint("LEFT", artPanel.icon, "RIGHT", 12, 0)
artPanel.warning = artPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
artPanel.warning:SetPoint("TOP", 0, -100)
artPanel.warning:SetTextColor(1, 0.3, 0.3)
artPanel.warning:SetText(NOART_TEXT)
artPanel.label = artPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
artPanel.label:SetPoint("TOPRIGHT", artPanel, "TOP", -10, -160)
artPanel.count = CreateFrame("EditBox", nil, artPanel, "InputBoxTemplate")
artPanel.count:SetSize(60, 20)
artPanel.count:SetPoint("LEFT", artPanel.label, "RIGHT", 14, 0)
artPanel.count:SetAutoFocus(false)
artPanel.count:SetNumeric(true)
artPanel.count:SetMaxLetters(3)
artPanel.count:SetScript("OnEnterPressed", EditBox_ClearFocus)
artPanel.count:SetScript("OnEscapePressed", EditBox_ClearFocus)
artPanel.each = artPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
artPanel.each:SetPoint("TOP", 0, -200)
artPanel.total = artPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
artPanel.total:SetPoint("TOP", artPanel.each, "BOTTOM", 0, -16)
artPanel.buy = CreateFrame("Button", nil, artPanel, "UIPanelButtonTemplate")
artPanel.buy:SetSize(140, 26)
artPanel.buy:SetPoint("TOP", artPanel.total, "BOTTOM", 0, -24)
artPanel.buy:SetText("Buy Now")

-- the number in the field, or nil when it is not 1..max
local function ArtCount()
    local p, count = artPanel.product, artPanel.count:GetNumber()
    if p and count >= 1 and count <= p.param1 then
        return count
    end
end

local function UpdateArtifact()
    local p = artPanel.product
    if not p then return end
    local _, name = Describe(p)
    artPanel.icon:SetTexture(TYPE_ICONS[TYPE_ARTLEVEL])
    artPanel.name:SetText(name)
    artPanel.warning:SetShown(HasArtifactEquipped and not HasArtifactEquipped())
    artPanel.label:SetText(("Levels to buy (1-%d):"):format(p.param1))
    artPanel.each:SetText("Price per level: " .. Price(p.price))
    local count = ArtCount()
    if p.price == 0 then   -- no price set yet: the server refuses it (FAIL PRICE)
        artPanel.total:SetText("Not for sale yet")
    else
        artPanel.total:SetText(count and "Total: " .. Price(count * p.price) or "Total: -")
    end
    artPanel.buy:SetEnabled(count ~= nil and p.price > 0 and not pending)
end

artPanel.count:SetScript("OnTextChanged", UpdateArtifact)
artPanel.buy:SetScript("OnClick", function()
    local p, count = artPanel.product, ArtCount()
    if not p or not count then return end
    local total = count * p.price
    ShowConfirm(p, {
        name = count == 1 and "1 artifact level" or count .. " artifact levels",
        price = Price(total),
        note = "For the artifact weapon you have equipped.",
        info = { kind = "buyn", product = p, count = count },
        send = function(reqId) return ("BUYN %d %d %d %d"):format(p.id, count, total, reqId) end,
    })
end)

-- ---------------------------------------------------------------- perks editor (a category named "Perks")
-- drag an item from the bags onto the slot; the server lists the perks it can get (PERK ... PEND), Add costs tokens,
-- Remove is free. PERKADD/PERKDEL name only the bag slot, so the list is asked for again whenever the bags change.
-- ponytail: drag (or click with the item on the cursor) only, no bag browser
local perksPanel = CreateFrame("Frame", nil, right)
perksPanel:SetPoint("BOTTOMRIGHT", -8, 8)
perksPanel:Hide()
Background(perksPanel, 0.5)
local perkSlot = CreateFrame("Button", nil, perksPanel)
perkSlot:SetSize(44, 44)
perkSlot:SetPoint("TOPLEFT", 16, -16)
perkSlot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
perkSlot.icon = perkSlot:CreateTexture(nil, "ARTWORK")
perkSlot.icon:SetAllPoints()
perksPanel.name = perksPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
perksPanel.name:SetPoint("LEFT", perkSlot, "RIGHT", 12, 0)
perksPanel.name:SetWidth(ROW_WIDTH - 100)
perksPanel.name:SetJustifyH("LEFT")
perksPanel.info = perksPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
perksPanel.info:SetPoint("TOPLEFT", perkSlot, "BOTTOMLEFT", 0, -14)
perksPanel.info:SetWidth(ROW_WIDTH - 40)
perksPanel.info:SetJustifyH("LEFT")
local perkLines = {}

local function AskPerks()
    if perkItem then
        perkItem.perks = nil
        Send(("PERKS %d %d"):format(perkItem.bag, perkItem.slot))
    end
end

local function SetPerkItem(bag, slot)
    perkItem = { bag = bag, slot = slot, entry = GetContainerItemID(bag, slot), link = GetContainerItemLink(bag, slot) }
    perkNote = nil
    AskPerks()
    UpdateRows()
end

local function ClearPerkItem(note)
    perkItem, perkNote = nil, note
    UpdateRows()
end

-- the cursor item gives no bag slot: the picked-up item is the locked one in the bags
local function PerkDrop()
    local kind, itemId = GetCursorInfo()
    if kind ~= "item" then return end
    for bag = 0, NUM_BAG_SLOTS do
        for slot = 1, GetContainerNumSlots(bag) do
            local _, _, locked = GetContainerItemInfo(bag, slot)
            if locked and GetContainerItemID(bag, slot) == itemId then
                ClearCursor()
                SetPerkItem(bag, slot)
                return
            end
        end
    end
    ClearCursor()
    Error("Put the item in your bags first: equipped items can't get perks here.")
end
perkSlot:SetScript("OnReceiveDrag", PerkDrop)
perkSlot:SetScript("OnClick", PerkDrop)
perkSlot:SetScript("OnEnter", function(self)
    if perkItem then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetBagItem(perkItem.bag, perkItem.slot)
        GameTooltip:Show()
    end
end)
perkSlot:SetScript("OnLeave", GameTooltip_Hide)

local function PerkOnClick(self)
    local perk, item = self:GetParent().perk, perkItem
    if not perk or not item then return end
    local bag, slot, entry = item.bag, item.slot, item.pendEntry
    local icon = GetContainerItemInfo(bag, slot)
    if perk.has then
        ShowConfirm(nil, {
            icon = icon, name = perk.name, question = "Remove this from the item?", price = GREEN:format("Free"),
            note = "The tokens spent on it are not returned.", button = "Remove",
            info = { kind = "perkdel", perk = perk },
            send = function(reqId) return ("PERKDEL %d %d %d %d %d"):format(bag, slot, perk.id, reqId, entry) end,
        })
    else
        ShowConfirm(nil, {
            icon = icon, name = perk.name, question = "Add this to the item?", price = Price(perk.price),
            info = { kind = "perkadd", perk = perk },
            send = function(reqId)
                return ("PERKADD %d %d %d %d %d %d"):format(bag, slot, perk.id, perk.price, reqId, entry)
            end,
        })
    end
end

local function PerkLine(i)
    local line = perkLines[i]
    if line then return line end
    line = CreateFrame("Frame", nil, perksPanel)
    line:SetSize(ROW_WIDTH - 40, 30)
    Background(line, 0.4)
    line.name = line:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    line.name:SetPoint("LEFT", 10, 0)
    line.name:SetWidth(220)
    line.name:SetJustifyH("LEFT")
    line.button = CreateFrame("Button", nil, line, "UIPanelButtonTemplate")
    line.button:SetSize(80, 22)
    line.button:SetPoint("RIGHT", -6, 0)
    line.button:SetScript("OnClick", PerkOnClick)
    line.price = line:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    line.price:SetPoint("RIGHT", line.button, "LEFT", -12, 0)
    perkLines[i] = line
    return line
end

local function UpdatePerks()
    local perks = perkItem and perkItem.perks or {}
    if perkItem then
        perkSlot.icon:SetTexture(GetContainerItemInfo(perkItem.bag, perkItem.slot) or UNKNOWN_ICON)
        perksPanel.name:SetText(perkItem.link or "")
        perksPanel.info:SetText(not perkItem.perks and STATUS_TEXT.loading
            or #perks == 0 and "Nothing can be added to this item." or "Add or remove a tertiary stat or socket:")
    else
        perkSlot.icon:SetTexture(EMPTY_SLOT)
        perksPanel.name:SetText("")
        perksPanel.info:SetText(perkNote or "Drag an item from your bags here to add or remove a tertiary stat or socket.")
    end
    for i, perk in ipairs(perks) do
        local line = PerkLine(i)
        line.perk = perk
        line.name:SetText(perk.name)
        if perk.has then
            line.price:SetText(GREEN:format("On the item"))
            line.button:SetText("Remove")
            line.button:SetEnabled(not pending)
        elseif perk.blocked then
            line.price:SetText("|cff808080Not possible on this item|r")
            line.button:SetText("Add")
            line.button:Disable()
        else
            line.price:SetText(Price(perk.price))
            line.button:SetText("Add")
            line.button:SetEnabled(not pending)
        end
        line:SetPoint("TOPLEFT", 16, -104 - (i - 1) * 34)
        line:Show()
    end
    for i = #perks + 1, #perkLines do
        perkLines[i]:Hide()
    end
end

-- ---------------------------------------------------------------- the right inset: list, panel or status
-- how a list is shown: the "Perks" category is the perks editor; artifact levels and bundles get their own panel /
-- banners; titles, mounts, pets, morphs and anything with a 3D display are cards; the rest rows
local function ListMode(cat, items)
    if cat and cats[cat] and cats[cat].name:lower() == "perks" then return "perks" end
    if #items == 0 then return "rows" end
    local art, bundle, card = true, true, true
    for _, p in ipairs(items) do
        art = art and p.type == TYPE_ARTLEVEL
        bundle = bundle and p.type == TYPE_BUNDLE
        card = card and (CARD_TYPES[p.type] or p.display > 0)
    end
    return art and "artifact" or bundle and "bundles" or card and "cards" or "rows"
end

UpdateRows = function()
    local all = shownCat and lists[shownCat] or {}
    listMode = ListMode(shownCat, all)
    local items, query = all, search:GetText():lower()
    local searchable = listMode == "rows" or listMode == "cards"
    if searchable and query ~= "" then
        items = {}
        for _, p in ipairs(all) do
            if select(2, Describe(p)):lower():find(query, 1, true) then
                items[#items + 1] = p
            end
        end
    end
    search:SetShown(searchable)
    local ilv = shownCat and lists[shownCat] and ilvInfo[shownCat]
    ilvlDrop:SetShown(ilv ~= nil)
    if ilv then
        UIDropDownMenu_SetText(ilvlDrop, "Item level " .. ilv.current)
    end

    local mode = LIST_MODES[listMode]
    local used = 0
    if mode then
        local visible = math.floor((LIST_HEIGHT - listTop - 8) / mode.height)
        scroll.lineHeight = mode.height
        FauxScrollFrame_Update(scroll, math.ceil(#items / mode.perLine), visible, mode.height)
        local offset = FauxScrollFrame_GetOffset(scroll)
        for line = 1, visible do
            for col = 1, mode.perLine do
                local p = items[(offset + line - 1) * mode.perLine + col]
                if p then
                    used = used + 1
                    local w = mode.make(used)
                    w.product = p
                    mode.fill(w, p)
                    if w.LockHighlight then
                        if previewed and previewed.id == p.id then w:LockHighlight() else w:UnlockHighlight() end
                    end
                    w:SetPoint("TOPLEFT", 10 + (col - 1) * mode.width, -listTop - (line - 1) * mode.height)
                    w:Show()
                end
            end
        end
    else
        FauxScrollFrame_Update(scroll, 0, 1, ROW_HEIGHT)
    end
    for name, m in pairs(LIST_MODES) do
        for i = (name == listMode and used or 0) + 1, #m.pool do
            m.pool[i]:Hide()
        end
    end

    artPanel:SetShown(listMode == "artifact")
    if listMode == "artifact" then
        artPanel:SetPoint("TOPLEFT", 8, -listTop)
        if artPanel.product ~= all[1] then
            artPanel.product = all[1]
            artPanel.count:SetText("1")
        end
        UpdateArtifact()
    end
    perksPanel:SetShown(listMode == "perks")
    if listMode == "perks" then
        perksPanel:SetPoint("TOPLEFT", 8, -listTop)
        UpdatePerks()
    end
    UpdatePreviewButtons()

    local panel = listMode == "artifact" or listMode == "perks"
    status:SetText(STATUS_TEXT[state] or not shownCat and "There is nothing in the shop for you yet."
        or panel and "" or not lists[shownCat] and STATUS_TEXT.loading
        or #items == 0 and (query == "" and "Nothing to buy here." or "No results.") or "")
end

-- a click on a row or card: equipment with a look on your own character (on top of what you wear), a mount, pet or
-- morph with a display ID as its model, anything else as its icon
-- ponytail: rings, trinkets and necks have no look (IsDressableItem is false), they show the icon
Preview = function(p)
    previewed = p
    local icon, name, r, g, b = UNKNOWN_ICON, "Click a product to preview it.", HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b
    if p then
        icon, name, r, g, b = Describe(p)
    end
    preview.name:SetText(name)
    preview.name:SetTextColor(r, g, b)
    preview.icon:SetTexture(icon)
    local dress = p and p.link and IsDressableItem(p.link)
    local display = p and p.display or 0
    preview.waiting = p and p.link and not GetItemInfo(p.link) and p.param1   -- previewed again when the item arrives
    model:SetShown(dress or display > 0)
    preview.icon:SetShown(p ~= nil and not model:IsShown())
    if dress then
        model:SetUnit("player")
        model:TryOn(p.link)
        model:SetFacing(0)
    elseif display > 0 then
        model:SetDisplayInfo(display)
        model:SetFacing(p.type == TYPE_MORPH and 0 or -0.6)
    end
    UpdateRows()
end

-- Purchase under the preview; an owned morph gets Use / Remove instead (artifact levels are bought in their panel)
UpdatePreviewButtons = function()
    local p = previewed
    local morph = p ~= nil and p.type == TYPE_MORPH and p.known
    preview.buy:SetShown(p ~= nil and not p.known and p.type ~= TYPE_ARTLEVEL)
    preview.use:SetShown(morph)
    preview.remove:SetShown(morph)
    preview.buy:SetEnabled(not pending)
    preview.use:SetEnabled(not pending)
    preview.remove:SetEnabled(not pending)
end

-- ---------------------------------------------------------------- confirmation
local popup = CreateFrame("Frame", nil, frame)
popup:SetSize(360, 200)
popup:SetPoint("CENTER")
popup:SetFrameStrata("FULLSCREEN_DIALOG")
popup:EnableMouse(true)
popup:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
popup:Hide()
popup.icon = popup:CreateTexture(nil, "ARTWORK")
popup.icon:SetSize(40, 40)
popup.icon:SetPoint("TOPLEFT", 24, -24)
popup.name = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
popup.name:SetPoint("LEFT", popup.icon, "RIGHT", 10, 0)
popup.name:SetWidth(270)
popup.name:SetJustifyH("LEFT")
popup.question = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
popup.question:SetPoint("TOP", 0, -80)
popup.price = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
popup.price:SetPoint("TOP", popup.question, "BOTTOM", 0, -12)
popup.note = popup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
popup.note:SetPoint("TOP", popup.price, "BOTTOM", 0, -8)
popup.note:SetWidth(320)
popup.buy = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
popup.buy:SetSize(120, 24)
popup.buy:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -6, 20)
local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
cancel:SetSize(120, 24)
cancel:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 6, 20)
cancel:SetText("Cancel")
cancel:SetScript("OnClick", function() popup:Hide() end)

-- popup.product (described again when its item info arrives) and popup.opts: icon, name, question, price (text),
-- note, button, info (the request record) and send(reqId) -> the message; without opts it is a BUY of the product
local function FillPopup()
    local p, o = popup.product, popup.opts
    local icon, name, r, g, b = UNKNOWN_ICON, "", NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
    if p then
        icon, name, r, g, b = Describe(p)
    end
    popup.icon:SetTexture(o.icon or icon)
    popup.name:SetText(o.name or name)
    popup.name:SetTextColor(r, g, b)
    popup.question:SetText(o.question or "Are you sure you want to buy this?")
    popup.price:SetText(o.price or Price(p.price))
    popup.note:SetText(o.note or p and p.type == TYPE_SERVICE and LOGOUT_TEXT or "")
    popup.buy:SetText(o.button or "Buy Now")
end

ShowConfirm = function(p, opts)
    if not p and not opts then return end
    popup.product, popup.opts = p, opts or {}
    FillPopup()
    popup.buy:SetEnabled(not pending)
    popup:Show()
end

-- the price is only a staleness check: the server charges its own price and answers OK or FAIL
popup.buy:SetScript("OnClick", function(self)
    local p, o = popup.product, popup.opts
    self:Disable()
    popup.reqId = Request(o.info or { kind = "buy", product = p }, o.send or function(reqId)
        return "BUY " .. p.id .. " " .. p.price .. " " .. reqId .. (p.buyIlvl and " " .. p.buyIlvl or "")
    end)
end)

local function Answered(reqId)
    if pending == reqId then
        pending = nil
        popup:Hide()
    elseif popup.reqId == reqId then   -- answered after the timeout gave the button back: don't leave it open
        popup:Hide()
    end
    popup.buy:SetEnabled(not pending)
end

-- ---------------------------------------------------------------- categories and tabs
local function ShowList(cat)
    if cat ~= shownCat then
        shownCat = cat
        ResetScroll()
    end
    if cat and cats[cat] and cats[cat].name:lower() == "perks" then
        lists[cat] = lists[cat] or {}   -- nothing to LIST: the editor asks with PERKS
    end
    if cat and not lists[cat] and (GetTime() - (requested[cat] or -10)) > 3 then   -- ask again when a LIST got no answer
        requested[cat] = GetTime()
        Send("LIST " .. cat .. (selIlvl and " " .. selIlvl or ""))
        C_Timer.After(3.5, function()
            if cat == shownCat and not lists[cat] and frame:IsShown() then ShowList(cat) end
        end)
    end
    UpdateRows()
end

-- a purchase can change a list (price, owned, gone): drop the cached lists and ask for the shown one again
local function Reload()
    wipe(lists)
    wipe(requested)
    if frame:IsShown() then
        ShowList(shownCat)
    end
end

local catButtons = {}

local function CategoryButton(i)
    local b = catButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, left)
    b:SetSize(176, CAT_HEIGHT)
    b:SetPoint("TOPLEFT", 8, -15 - (i - 1) * CAT_HEIGHT)
    StoreTexture(b, "BACKGROUND", 0.56542969, 0.73730469, 0.41992188, 0.45703125):SetAllPoints()   -- store-category
    b.selected = StoreTexture(b, "ARTWORK", 0.73535156, 0.90332031, 0.46289063, 0.49609375)       -- store-category-selected
    b.hover = StoreTexture(b, "ARTWORK", 0.00097656, 0.16894531, 0.93847656, 0.97167969)          -- store-category-hover
    for _, tex in ipairs({ b.selected, b.hover }) do
        tex:SetSize(172, 34)
        tex:SetPoint("CENTER", 0, 2)
        tex:SetBlendMode("ADD")
    end
    b.hover:Hide()
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("LEFT", 16, 4)
    b.text:SetSize(150, CAT_HEIGHT)
    b.text:SetJustifyH("LEFT")
    b:SetScript("OnEnter", function(self) self.hover:Show() end)
    b:SetScript("OnLeave", function(self) self.hover:Hide() end)
    b:SetScript("OnClick", function(self)
        selTop = self.id
        Refresh()
    end)
    catButtons[i] = b
    return b
end

-- the left column scrolls with the mouse wheel and two arrows when there are more categories than fit
local function ScrollCategories(delta)
    local max = math.max(0, #(children[0] or {}) - VISIBLE_CATS)
    catOffset = math.min(math.max(catOffset - delta, 0), max)
    Refresh()
end
left:EnableMouseWheel(true)
left:SetScript("OnMouseWheel", function(_, delta) ScrollCategories(delta) end)
local catUp = CreateFrame("Button", nil, left, "UIPanelScrollUpButtonTemplate")
catUp:SetPoint("TOPRIGHT", -4, -4)
catUp:SetFrameLevel(left:GetFrameLevel() + 5)
catUp:SetScript("OnClick", function() ScrollCategories(1) end)
local catDown = CreateFrame("Button", nil, left, "UIPanelScrollDownButtonTemplate")
catDown:SetPoint("BOTTOMRIGHT", -4, 4)
catDown:SetFrameLevel(left:GetFrameLevel() + 5)
catDown:SetScript("OnClick", function() ScrollCategories(-1) end)

local tabs, slotTabs = {}, {}   -- text tabs, paper doll slot icon tabs

local function TabOnClick(self)
    if self.level == 1 then
        selTab, selSubTab = self.id, nil
    else
        selSubTab = self.id
    end
    Refresh()
end

local function SlotTabOnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
    GameTooltip:SetText(self.name)
    GameTooltip:Show()
end

local function Tab(i)
    local b = tabs[i]
    if b then return b end
    b = CreateFrame("Button", nil, right, "UIPanelButtonTemplate")
    b:SetHeight(22)
    b:SetScript("OnClick", TabOnClick)
    tabs[i] = b
    return b
end

local function SlotTab(i)
    local b = slotTabs[i]
    if b then return b end
    b = CreateFrame("Button", nil, right)
    b:SetSize(32, 32)
    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    b.new = b:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    b.new:SetPoint("TOPRIGHT", 2, 2)
    b.new:SetText(NEW_MARK)
    b:SetScript("OnClick", TabOnClick)
    b:SetScript("OnEnter", SlotTabOnEnter)
    b:SetScript("OnLeave", GameTooltip_Hide)
    slotTabs[i] = b
    return b
end

-- lines = { { ids, selectedId }, ... }, one per tab level; returns the height they take. Slot names (Head, Rings, ...)
-- are icons, the other tabs text buttons (centred in a line that has icons)
local function LayoutTabs(lines)
    local nText, nSlot, x, y, height = 0, 0, 0, 0, 0
    for level, line in ipairs(lines) do
        if level > 1 then
            x, y = 0, y + height + 2
        end
        height = 22
        for _, id in ipairs(line[1]) do
            if SLOT_ICONS[cats[id].name:lower()] then height = 32 end
        end
        for _, id in ipairs(line[1]) do
            local slot, b = SLOT_ICONS[cats[id].name:lower()]
            if slot then
                nSlot = nSlot + 1
                b = SlotTab(nSlot)
                b:SetNormalTexture(SLOT_ART .. slot)
                b.name = cats[id].name
                b.new:SetShown(cats[id].new)
            else
                nText = nText + 1
                b = Tab(nText)
                b:SetText(CatName(id))
                b:SetWidth(b:GetTextWidth() + 24)
            end
            local width = b:GetWidth()
            if x > 0 and x + width > TABS_WIDTH then
                x, y = 0, y + height + 2
            end
            b:SetPoint("TOPLEFT", 12 + x, -10 - y - (height - b:GetHeight()) / 2)
            x = x + width + 4
            b.id, b.level = id, level
            if id == line[2] then b:LockHighlight() else b:UnlockHighlight() end
            b:Show()
        end
    end
    for i = nText + 1, #tabs do
        tabs[i]:Hide()
    end
    for i = nSlot + 1, #slotTabs do
        slotTabs[i]:Hide()
    end
    return nText + nSlot > 0 and y + height + 8 or 0
end

-- all leaf categories under id, in order
local function Leaves(id, out)
    if not children[id] then
        out[#out + 1] = id
    else
        for _, child in ipairs(children[id]) do
            Leaves(child, out)
        end
    end
    return out
end

-- left column = top-level categories, first tab row = their children, second row = the leaves under the selected tab
-- ponytail: a category holding both products and subcategories only shows the subcategories
Refresh = function()
    local tops = children[0] or {}
    if not tContains(tops, selTop) then selTop = tops[1] end
    catOffset = math.min(catOffset, math.max(0, #tops - VISIBLE_CATS))
    local shown = 0
    for i = catOffset + 1, math.min(#tops, catOffset + VISIBLE_CATS) do
        local id = tops[i]
        shown = shown + 1
        local b = CategoryButton(shown)
        b.id = id
        b.text:SetText(CatName(id))
        b.selected:SetShown(id == selTop)
        b:Show()
    end
    for i = shown + 1, #catButtons do
        catButtons[i]:Hide()
    end
    catUp:SetShown(#tops > VISIBLE_CATS)
    catDown:SetShown(#tops > VISIBLE_CATS)
    catUp:SetEnabled(catOffset > 0)
    catDown:SetEnabled(catOffset < #tops - VISIBLE_CATS)

    local lines, cat = {}, selTop
    local kids = selTop and children[selTop]
    if kids then
        if not tContains(kids, selTab) then selTab = kids[1] end
        lines[1] = { kids, selTab }
        cat = selTab
        if children[selTab] then
            local leaves = Leaves(selTab, {})
            if not tContains(leaves, selSubTab) then selSubTab = leaves[1] end
            lines[2] = { leaves, selSubTab }
            cat = selSubTab
        end
    end
    listTop = 10 + LayoutTabs(lines)
    scroll:SetPoint("TOPLEFT", 0, -listTop)
    ShowList(cat)
end

-- every open asks for the balance and the categories again (tokens can be added from outside the game)
frame:SetScript("OnShow", function()
    state = "loading"
    newCats = {}
    wipe(lists)
    wipe(requested)
    wipe(bundleParts)
    selIlvl = nil
    titleFormats = nil   -- titles learned since the last visit
    search:SetText("")   -- a search from the last visit would hide the first list
    Preview(nil)   -- also draws the rows
    UpdateMicroButton()
    Send("OPEN")
    C_Timer.After(5, function()
        if state == "loading" and frame:IsShown() then   -- no answer: the server does not have the shop
            state = "offline"
            UpdateRows()
        end
    end)
end)

frame:SetScript("OnHide", function()
    popup:Hide()
    search:ClearFocus()
    artPanel.count:ClearFocus()
    CloseDropDownMenus()
    UpdateMicroButton()
end)

-- ---------------------------------------------------------------- server messages
local function SetBalance(tokens)
    if tokens then
        balanceText:SetText("Balance: " .. tokens .. " " .. COIN)
    end
end

local function OnMessage(msg)
    local command, rest = msg:match("^(%S+) ?(.*)$")
    if command == "BAL" then
        SetBalance(rest:match("^%d+"))
    elseif command == "CAT" then
        local id, parent, order, name = rest:match("^(%d+) (%d+) (%d+) (.*)$")
        if id then
            local flags, v2name = name:match("^#(%d+) ?(.*)$")   -- v1: no flags
            newCats[tonumber(id)] = { parent = tonumber(parent), order = tonumber(order), name = v2name or name,
                new = bit.band(tonumber(flags) or 0, FLAG_NEW) > 0 }
        end
    elseif command == "CEND" then
        cats, newCats = newCats, {}
        local perksCat
        for _, c in pairs(cats) do
            perksCat = perksCat or c.name:lower() == "perks"
        end
        if not perksCat then   -- last in the left column, unless the catalogue has a "Perks" category of its own
            cats[PERKS_CAT] = { parent = 0, order = 1000000, name = "Perks" }
        end
        wipe(children)
        for id, c in pairs(cats) do
            children[c.parent] = children[c.parent] or {}
            tinsert(children[c.parent], id)
        end
        for _, ids in pairs(children) do
            table.sort(ids, function(a, b)
                if cats[a].order ~= cats[b].order then
                    return cats[a].order < cats[b].order
                end
                return a < b
            end)
        end
        state = "ready"
        if frame:IsShown() then
            Refresh()
        end
    elseif command == "ITEM" then
        local id, ptype, param1, price, ilvl, bonuses, name = rest:match("^(%d+) (%d+) (%d+) (%d+) (%-?%d+) ([%d,%-]+) (.*)$")
        if id then
            local flags, display, v2name = name:match("^#(%d+) (%d+) ?(.*)$")   -- v1: no flags, no display
            flags = tonumber(flags) or 0
            local p = { id = tonumber(id), type = tonumber(ptype), param1 = tonumber(param1), price = tonumber(price), ilvl = tonumber(ilvl),
                name = v2name or name, known = bit.band(flags, FLAG_KNOWN) > 0, new = bit.band(flags, FLAG_NEW) > 0, display = tonumber(display) or 0 }
            if p.type == TYPE_ITEM then
                p.link = ItemLink(p.param1, bonuses)
            end
            products[p.id] = p
            bundleParts[p.id] = nil
            tinsert(incoming, p)
        end
    elseif command == "BPART" then   -- optional: one line of a bundle's "You will receive" list
        local id, text = rest:match("^(%d+) (.+)$")
        if id then
            id = tonumber(id)
            bundleParts[id] = bundleParts[id] or {}
            tinsert(bundleParts[id], text)
        end
    elseif command == "ILV" then
        local cat, current, levels = rest:match("^(%d+) (%d+) ([%d,]+)")
        if cat then
            incomingIlv = { cat = tonumber(cat), current = tonumber(current), levels = {} }
            for ilvl in levels:gmatch("%d+") do
                tinsert(incomingIlv.levels, tonumber(ilvl))
            end
        end
    elseif command == "LEND" then
        local cat = tonumber(rest:match("^%d+"))
        if cat then
            lists[cat] = incoming
            if incomingIlv and incomingIlv.cat == cat then
                ilvInfo[cat] = incomingIlv
                for _, p in ipairs(incoming) do
                    p.buyIlvl = incomingIlv.current   -- BUY names the item level it was shown at
                end
            else
                ilvInfo[cat] = nil
            end
        end
        incoming, incomingIlv = {}, nil
        if cat and cat == shownCat and frame:IsShown() then
            UpdateRows()
        end
    elseif command == "PERK" then
        local id, price, has, flags, name = rest:match("^(%d+) (%d+) ([01]) #(%d+) ?(.*)$")
        if id then
            tinsert(incomingPerks, { id = tonumber(id), price = tonumber(price), has = has == "1",
                blocked = bit.band(tonumber(flags), PERK_BLOCKED) > 0, name = name })
        end
    elseif command == "PEND" then
        local bag, slot, entry = rest:match("^(%d+) (%d+) (%d+)")
        local perks = incomingPerks
        incomingPerks = {}
        if perkItem and tonumber(bag) == perkItem.bag and tonumber(slot) == perkItem.slot then
            if tonumber(entry) == 0 then
                ClearPerkItem("Nothing in that bag slot can get perks. Drag another item in.")
            else
                perkItem.perks, perkItem.pendEntry = perks, tonumber(entry)
                UpdateRows()
            end
        end
    elseif command == "OK" then
        local reqId, id, tokens, mail = rest:match("^(%d+) (%d+) (%d+) ?(%u*)")
        if not reqId then return end
        reqId = tonumber(reqId)
        local r = reqs[reqId] or { kind = "buy", product = products[tonumber(id)] }
        reqs[reqId] = nil
        local p = r.product
        local name = p and select(2, Describe(p)) or id
        SetBalance(tokens)
        if r.kind == "morph" then
            UIErrorsFrame:AddMessage(id == "0" and "Morph removed." or "Morph applied: " .. name, 0.1, 1, 0.1)
        elseif r.kind == "perkadd" or r.kind == "perkdel" then
            UIErrorsFrame:AddMessage((r.kind == "perkadd" and "Added: " or "Removed: ") .. r.perk.name, 0.1, 1, 0.1)
        elseif r.kind == "buyn" then
            UIErrorsFrame:AddMessage(("Purchased: %d artifact level%s."):format(r.count, r.count == 1 and "" or "s"), 0.1, 1, 0.1)
        elseif mail == "MAIL" then
            UIErrorsFrame:AddMessage("Your bags were full: " .. name .. " was sent to your mailbox.", 0.1, 1, 0.1)
        elseif p and p.type == TYPE_SERVICE then
            UIErrorsFrame:AddMessage("Purchased: " .. name .. ". " .. LOGOUT_TEXT, 0.1, 1, 0.1)
        else
            UIErrorsFrame:AddMessage("Purchased: " .. name, 0.1, 1, 0.1)
        end
        if p and p.type == TYPE_PREMIUM then
            SendAddonMessage("PREM", "HELLO", "WHISPER", UnitName("player"))   -- the premium menu shows the new time
        end
        Answered(reqId)
        if r.kind == "perkadd" or r.kind == "perkdel" then
            AskPerks()
            UpdateRows()
        else
            Reload()
        end
    elseif command == "FAIL" then
        local reqId, code, tokens = rest:match("^(%d+) (%u+) (%d+)")
        if not reqId then return end
        reqId = tonumber(reqId)
        reqs[reqId] = nil
        SetBalance(tokens)
        Error(FAIL_TEXT[code] or FAIL_TEXT.FAILED)
        Answered(reqId)
        if code == "PRICE" or code == "GONE" then
            Reload()
        elseif code == "NOITEM" then
            ClearPerkItem(FAIL_TEXT.NOITEM)
        else
            UpdateRows()
        end
    elseif command == "CLOSED" then
        state = "closed"
        cats, newCats = {}, {}
        wipe(children)
        popup:Hide()
        if frame:IsShown() then
            Refresh()
        end
    elseif command == "ERR" then
        Error(rest)
    end
end

-- the perks editor's item: gone or moved -> cleared; still there -> its perks asked for again (a perk changes the
-- item, and PERKADD/PERKDEL only name the bag slot). BAG_UPDATE comes in bursts: one check per 0.3 s
local perkCheckQueued
local function CheckPerkItem()
    perkCheckQueued = nil
    if not perkItem or not perksPanel:IsVisible() then return end
    if GetContainerItemID(perkItem.bag, perkItem.slot) ~= perkItem.entry then
        ClearPerkItem("The item moved. Drag it in again.")
    else
        perkItem.link = GetContainerItemLink(perkItem.bag, perkItem.slot)
        AskPerks()
        UpdateRows()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
events:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if event == "GET_ITEM_INFO_RECEIVED" then   -- prefix = the item ID
        if frame:IsShown() then
            UpdateRows()
            if popup:IsShown() then FillPopup() end
            if preview.waiting and preview.waiting == prefix then Preview(previewed) end
        end
    elseif event == "BAG_UPDATE" then
        if perkItem and frame:IsShown() and not perkCheckQueued then
            perkCheckQueued = true
            C_Timer.After(0.3, CheckPerkItem)
        end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" then   -- the artifact panel's "must have an artifact equipped"
        if frame:IsShown() and listMode == "artifact" then UpdateArtifact() end
    -- only the server can whisper SHOP to us: the core never forwards SHOP addon messages from players
    elseif prefix == PREFIX and channel == "WHISPER" and msg and sender and sender:match("^[^-]*") == UnitName("player") then
        OnMessage(msg)
    end
end)

-- ---------------------------------------------------------------- opening the shop
local function ToggleShop()
    if frame:IsShown() then
        frame:Hide()
    else
        securecall("CloseAllWindows")   -- like Blizzard's store: the Esc menu and the premium menu close
        frame:Show()
    end
end

-- shift+click still opens Blizzard's own store (GM accounts, BattlePay)
local BlizzardToggleStoreUI = ToggleStoreUI
local function ToggleStore()
    if IsShiftKeyDown() and BlizzardToggleStoreUI then
        BlizzardToggleStoreUI()
    else
        ToggleShop()
    end
end
ToggleStoreUI = ToggleStore   -- the premium menu's Buy Premium, the Esc menu Store button and store links call it

StoreMicroButton:SetScript("OnClick", ToggleStore)   -- the XML bound the old ToggleStoreUI at load
hooksecurefunc("UpdateMicroButtons", UpdateMicroButton)
UpdateMicroButton()

SLASH_CHRONICLESSHOP1 = "/shop"
SlashCmdList.CHRONICLESSHOP = ToggleShop
