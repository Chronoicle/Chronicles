-- Chronicles Shop (#64): the shop window from the micro menu Shop button, /shop and ToggleStoreUI (the premium menu's
-- Buy Premium). It talks to the server's donate_shop_addon script (many_in_one_donate.cpp) through addon messages with
-- the prefix "SHOP"; the server checks and delivers everything, this addon only draws the shop.
-- One record per message, fields separated by spaces, the name last. Protocol v2 adds the fields after '#', so a v1
-- server (no '#' fields) still parses:
--   client -> server: OPEN | LIST <categoryId> | BUY <productId> <shownPrice> <reqId>
--   server -> client: CLOSED | BAL <tokens> | CAT <id> <parentId> <order> #<flags> <name> ... CEND
--                     | ITEM <productId> <type> <param1> <price> <ilvl> <bonuses> #<flags> <display> <name> ... LEND <categoryId> <count>
--                     | OK <reqId> <productId> <tokens> [MAIL] | FAIL <reqId> <code> <tokens> | ERR <text>
--   flags: 1 = KNOWN (ITEM: the character has it already), 2 = NEW (ITEM: added lately; CAT: a new product in it or below)
--   display = creature display ID of a mount or pet for the 3D preview (0 = none); MAIL = the bags were full, sent by mail
local PREFIX = "SHOP"
local ICON = "Interface\\Icons\\"
local COIN = "|T" .. ICON .. "WoW_Token01:16:16:0:0:64:64:5:59:5:59|t"   -- after every price
local STORE_ART = "Interface\\Store\\Store-Main"   -- Blizzard's store art, texcoords from Blizzard_StoreUIPatchwerk.xml
local ROW_HEIGHT = 40
local ROW_WIDTH = 516
local LIST_HEIGHT = 496     -- height of the insets
local PREVIEW_WIDTH = 230   -- the 3D preview on the right; the window stays within 1024 wide at UI scale 1
local TABS_WIDTH = 540
local FLAG_KNOWN, FLAG_NEW = 1, 2
local NEW_TAG = "|cff20ff20NEW|r"   -- after a new product's name
local NEW_MARK = "|cff20ff20!|r"    -- on a category or tab with a new product in it

-- tabs with these names become paper doll slot icons (Blizzard's back slot uses the chest picture too)
local SLOT_ART = "Interface\\PaperDoll\\UI-PaperDoll-Slot-"
local SLOT_ICONS = {
    head = "Head", neck = "Neck", shoulder = "Shoulder", shoulders = "Shoulder", back = "Chest", cloak = "Chest",
    chest = "Chest", shirt = "Shirt", tabard = "Tabard", wrist = "Wrists", wrists = "Wrists", hands = "Hands",
    waist = "Waist", legs = "Legs", feet = "Feet", finger = "Finger", rings = "Finger", trinket = "Trinket",
    trinkets = "Trinket", ["main hand"] = "MainHand", ["off hand"] = "SecondaryHand", relic = "Relic", relics = "Relic",
}

-- DonateProductType in many_in_one_donate.cpp; items get their own icon from the client
local TYPE_ITEM, TYPE_PREMIUM, TYPE_SERVICE = 0, 7, 8
local TYPE_ICONS = {
    [1] = ICON .. "INV_Misc_Coin_17",           -- currency
    [2] = ICON .. "INV_Scroll_03",              -- title
    [3] = ICON .. "Achievement_General",        -- achievement
    [4] = ICON .. "Ability_Mount_RidingHorse",  -- spell (mounts, pets)
    [5] = ICON .. "Achievement_Level_110",      -- level
    [6] = ICON .. "INV_Misc_Coin_01",           -- gold
    [7] = ICON .. "INV_Crown_02",               -- premium days
    [8] = ICON .. "INV_Misc_Note_01",           -- character service (rename, appearance, faction, race)
}
local UNKNOWN_ICON = ICON .. "INV_Misc_QuestionMark"
local LOGOUT_TEXT = "Log out to the character screen to use it."

local FAIL_TEXT = {
    NOFUNDS = "You don't have enough tokens.",
    GONE = "This product is not available any more.",
    PRICE = "The price has changed. Please check it and try again.",
    BAGS = "Your bags are full. Free a bag slot and try again.",
    OWNED = "You already have this.",
    BUSY = "Too many requests. Please wait a moment.",
    CLOSED = "The shop is not open yet.",
    FAILED = "The purchase failed. No tokens were taken.",
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
local requested = {}                -- category -> GetTime() of its last LIST
local selTop, selTab, selSubTab     -- selected category and tabs
local shownCat                      -- category whose products are shown
local listTop = 10                  -- y of the first row in the right inset, below the tabs
local pending                       -- reqId of the BUY waiting for OK/FAIL
local lastReqId = 0
local previewed                     -- product in the preview panel
local Refresh, UpdateRows, ShowConfirm, Preview

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

-- icon, name and colour of a product; item names come from the client's item cache (the server's name until then)
local function Describe(p)
    if p.type == TYPE_ITEM then
        local name, _, quality = GetItemInfo(p.link)
        local color = ITEM_QUALITY_COLORS[quality] or HIGHLIGHT_FONT_COLOR
        return select(5, GetItemInfoInstant(p.param1)) or UNKNOWN_ICON, name or p.name, color.r, color.g, color.b
    end
    return TYPE_ICONS[p.type] or UNKNOWN_ICON, p.name, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b
end

local function Price(tokens)
    return tokens .. " " .. COIN
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

-- your own character wearing the item, or the mount or pet; drag with the left button to turn it
-- ponytail: no zoom or panning, add mouse wheel -> SetCamDistanceScale if players want a closer look
local model = CreateFrame("DressUpModel", nil, preview)
model:SetPoint("TOPLEFT", 4, -56)
model:SetPoint("BOTTOMRIGHT", -4, 4)
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

local right = CreateFrame("Frame", "$parentRightInset", frame, "InsetFrameTemplate")
right:SetPoint("TOPLEFT", 198, -44)
right:SetPoint("BOTTOMRIGHT", preview, "BOTTOMLEFT", -2, 0)

local status = right:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
status:SetPoint("CENTER")

local scroll = CreateFrame("ScrollFrame", "$parentList", right, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 0, -listTop)
scroll:SetPoint("BOTTOMRIGHT", -30, 8)
scroll:SetScript("OnVerticalScroll", function(self, offset)
    FauxScrollFrame_OnVerticalScroll(self, offset, ROW_HEIGHT, UpdateRows)
end)

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
    FauxScrollFrame_SetOffset(scroll, 0)
    scroll.ScrollBar:SetValue(0)
    UpdateRows()
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

-- ---------------------------------------------------------------- product rows
local rows = {}

local function RowOnEnter(self)
    if self.product.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.product.link)
        GameTooltip:Show()
    end
end

local function Row(i)
    local row = rows[i]
    if row then return row end
    row = CreateFrame("Button", nil, right)   -- not in the scroll frame: FauxScrollFrame_Update hides it for short lists
    row:SetSize(ROW_WIDTH, ROW_HEIGHT - 4)
    local bg = row:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.5)
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
    row.known:SetText("Already Known")
    row.known:SetTextColor(0.1, 1, 0.1)
    row.price = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    row.price:SetPoint("RIGHT", row.buy, "LEFT", -12, 0)
    row:SetScript("OnClick", function(self) Preview(self.product) end)
    row:SetScript("OnEnter", RowOnEnter)
    row:SetScript("OnLeave", GameTooltip_Hide)
    rows[i] = row
    return row
end

UpdateRows = function()
    local items = shownCat and lists[shownCat] or {}
    local query = search:GetText():lower()
    if query ~= "" then
        local found = {}
        for _, p in ipairs(items) do
            if select(2, Describe(p)):lower():find(query, 1, true) then
                found[#found + 1] = p
            end
        end
        items = found
    end
    local visible = math.floor((LIST_HEIGHT - listTop - 8) / ROW_HEIGHT)
    FauxScrollFrame_Update(scroll, #items, visible, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(scroll)
    for i = 1, math.max(visible, #rows) do
        local p = i <= visible and items[offset + i]
        if p then
            local row = Row(i)
            local icon, name, r, g, b = Describe(p)
            row.product = p
            row.icon:SetTexture(icon)
            row.name:SetText(p.new and name .. " " .. NEW_TAG or name)
            row.name:SetTextColor(r, g, b)
            row.ilvl:SetText(p.ilvl > 0 and "Item level " .. p.ilvl or "")
            row.price:SetText(Price(p.price))
            row.buy:SetShown(not p.known)
            row.known:SetShown(p.known)
            if previewed and previewed.id == p.id then row:LockHighlight() else row:UnlockHighlight() end
            row:SetPoint("TOPLEFT", 10, -listTop - (i - 1) * ROW_HEIGHT)
            row:Show()
        elseif rows[i] then
            rows[i]:Hide()
        end
    end
    status:SetText(STATUS_TEXT[state] or not shownCat and "There is nothing in the shop for you yet."
        or not lists[shownCat] and STATUS_TEXT.loading or #items == 0 and (query == "" and "Nothing to buy here." or "No results.") or "")
end

-- a click on a row: equipment with a look on your own character (on top of what you wear), a mount or pet with a
-- display ID as its model, anything else as its icon
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
        model:SetFacing(-0.6)
    end
    UpdateRows()
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
local question = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
question:SetPoint("TOP", 0, -80)
question:SetText("Are you sure you want to buy this?")
popup.price = popup:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
popup.price:SetPoint("TOP", question, "BOTTOM", 0, -12)
popup.note = popup:CreateFontString(nil, "ARTWORK", "GameFontNormal")
popup.note:SetPoint("TOP", popup.price, "BOTTOM", 0, -8)
popup.buy = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
popup.buy:SetSize(120, 24)
popup.buy:SetPoint("BOTTOMRIGHT", popup, "BOTTOM", -6, 20)
popup.buy:SetText("Buy Now")
local cancel = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
cancel:SetSize(120, 24)
cancel:SetPoint("BOTTOMLEFT", popup, "BOTTOM", 6, 20)
cancel:SetText("Cancel")
cancel:SetScript("OnClick", function() popup:Hide() end)

local function FillPopup()
    local p = popup.product
    local icon, name, r, g, b = Describe(p)
    popup.icon:SetTexture(icon)
    popup.name:SetText(name)
    popup.name:SetTextColor(r, g, b)
    popup.price:SetText(Price(p.price))
    popup.note:SetText(p.type == TYPE_SERVICE and LOGOUT_TEXT or "")
end

ShowConfirm = function(p)
    popup.product = p
    FillPopup()
    popup.buy:SetEnabled(not pending)
    popup:Show()
end

-- the price is only a staleness check: the server charges its own price and answers OK or FAIL
popup.buy:SetScript("OnClick", function(self)
    local p = popup.product
    lastReqId = lastReqId % 999999 + 1
    local reqId = lastReqId
    pending = reqId
    popup.reqId = reqId     -- a late answer still closes this popup (see Answered)
    self:Disable()
    Send("BUY " .. p.id .. " " .. p.price .. " " .. reqId)
    C_Timer.After(5, function()
        if pending == reqId then   -- no answer yet: the server may still deliver it
            pending = nil
            popup.buy:Enable()
            UIErrorsFrame:AddMessage("The shop has not answered yet. Check your balance before buying again.", 1, 0.3, 0.3)
        end
    end)
end)

local function Answered(reqId)
    if pending == reqId then
        pending = nil
        popup:Hide()
    elseif popup.reqId == reqId then   -- answered after the timeout gave Buy Now back: don't leave it open to buy again
        popup:Hide()
    end
end

-- ---------------------------------------------------------------- categories and tabs
local function ShowList(cat)
    if cat ~= shownCat then
        shownCat = cat
        FauxScrollFrame_SetOffset(scroll, 0)
        scroll.ScrollBar:SetValue(0)
    end
    if cat and not lists[cat] and (GetTime() - (requested[cat] or -10)) > 3 then   -- ask again when a LIST got no answer
        requested[cat] = GetTime()
        Send("LIST " .. cat)
        C_Timer.After(3.5, function()
            if cat == shownCat and not lists[cat] and frame:IsShown() then ShowList(cat) end
        end)
    end
    UpdateRows()
end

-- a purchase can change a list (price, owned, gone): drop the cached lists and ask for the shown one again
local function Reload()
    wipe(lists)
    if frame:IsShown() then
        ShowList(shownCat)
    end
end

local catButtons = {}

-- ponytail: no scrolling in the left column, 12 top-level categories fit
local function CategoryButton(i)
    local b = catButtons[i]
    if b then return b end
    b = CreateFrame("Button", nil, left)
    b:SetSize(176, 38)
    b:SetPoint("TOPLEFT", 8, -15 - (i - 1) * 38)
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
    b.text:SetSize(150, 38)
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
-- ponytail: a category holding both products and subcategories only shows the subcategories; phase 2's
-- item level filter replaces the first row ("985 ilevel")
Refresh = function()
    local tops = children[0] or {}
    if not tContains(tops, selTop) then selTop = tops[1] end
    for i, id in ipairs(tops) do
        local b = CategoryButton(i)
        b.id = id
        b.text:SetText(CatName(id))
        b.selected:SetShown(id == selTop)
        b:Show()
    end
    for i = #tops + 1, #catButtons do
        catButtons[i]:Hide()
    end

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
            tinsert(incoming, p)
        end
    elseif command == "LEND" then
        local cat = tonumber(rest:match("^%d+"))
        if cat then
            lists[cat] = incoming
        end
        incoming = {}
        if cat and cat == shownCat and frame:IsShown() then
            UpdateRows()
        end
    elseif command == "OK" then
        local reqId, id, tokens, mail = rest:match("^(%d+) (%d+) (%d+) ?(%u*)")
        if not reqId then return end
        local p = products[tonumber(id)]
        local name = p and select(2, Describe(p)) or id
        SetBalance(tokens)
        if mail == "MAIL" then
            UIErrorsFrame:AddMessage("Your bags were full: " .. name .. " was sent to your mailbox.", 0.1, 1, 0.1)
        elseif p and p.type == TYPE_SERVICE then
            UIErrorsFrame:AddMessage("Purchased: " .. name .. ". " .. LOGOUT_TEXT, 0.1, 1, 0.1)
        else
            UIErrorsFrame:AddMessage("Purchased: " .. name, 0.1, 1, 0.1)
        end
        if p and p.type == TYPE_PREMIUM then
            SendAddonMessage("PREM", "HELLO", "WHISPER", UnitName("player"))   -- the premium menu shows the new time
        end
        Answered(tonumber(reqId))
        Reload()
    elseif command == "FAIL" then
        local reqId, code, tokens = rest:match("^(%d+) (%u+) (%d+)")
        if not reqId then return end
        SetBalance(tokens)
        UIErrorsFrame:AddMessage(FAIL_TEXT[code] or FAIL_TEXT.FAILED, 1, 0.3, 0.3)
        Answered(tonumber(reqId))
        if code == "PRICE" or code == "GONE" then
            Reload()
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
        UIErrorsFrame:AddMessage(rest, 1, 0.3, 0.3)
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_ADDON")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:SetScript("OnEvent", function(self, event, prefix, msg, channel, sender)
    if event == "GET_ITEM_INFO_RECEIVED" then   -- prefix = the item ID
        if frame:IsShown() then
            UpdateRows()
            if popup:IsShown() then FillPopup() end
            if preview.waiting and preview.waiting == prefix then Preview(previewed) end
        end
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
