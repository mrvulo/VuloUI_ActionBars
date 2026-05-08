-- ============================================================
--  VuloUI – ActionBars
--  Fade, Hotkeys, OmniCC-style Timer
--  WoW Midnight 12.0.5
-- ============================================================

-- Sicherheits-Check: Core vorhanden?
if not VuloUI then
    print("|cffFF6060VuloUI_ActionBars:|r " ..
          "VuloUI Core nicht gefunden!")
    return
end

local V   = VuloUI
local LSM = LibStub("LibSharedMedia-3.0")

local AB   = {}
AB.bars    = {}
AB.buttons = {}

V:RegisterModule("ActionBars", AB)

-- ============================================================
--  PIXEL-PERFECT
-- ============================================================

local function P(v)
    local s = UIParent:GetEffectiveScale()
    return math.floor(v * s + 0.5) / s
end


local function GetFont()
    return LSM:Fetch("font",
        V:Get("theme","font") or "Friz Quadrata TT")
        or "Interface\\AddOns\\VuloUI\\Media\\font.ttf"
end

-- ============================================================
--  BAR-KONFIGURATION (Defaults)
-- ============================================================
--  Jede Bar hat:
--   id         = 1-6
--   page       = WoW ActionBar-Seite (1-8)
--   numButtons = 1-12
--   size       = Button-Größe in Pixel
--   spacing    = Abstand zwischen Buttons
--   rows       = 1 = horizontal, >1 = Grid
--   point      = Anker-Punkt
--   x, y       = Position
--   fadeOOC    = außerhalb Kampf ausblenden
--   alpha      = normale Transparenz
--   alphaOOC   = OOC Transparenz
--   showHotkey = Tasten anzeigen
--   showCount  = Stack-Zahlen anzeigen
--   showMacro  = Macro-Namen anzeigen

local BAR_DEFAULTS = {
    [1] = {
        id=1, page=1, numButtons=12, size=36, spacing=3,
        rows=1, point="BOTTOM", x=0, y=14,
        fadeOOC=false, alpha=1.0, alphaOOC=0.6,
        showHotkey=true, showCount=true, showMacro=false,
        enabled=true,
    },
    [2] = {
        id=2, page=2, numButtons=12, size=36, spacing=3,
        rows=1, point="BOTTOM", x=0, y=56,
        fadeOOC=true, alpha=1.0, alphaOOC=0.35,
        showHotkey=true, showCount=true, showMacro=false,
        enabled=true,
    },
    [3] = {
        id=3, page=3, numButtons=6, size=36, spacing=3,
        rows=6, point="LEFT", x=14, y=0,
        fadeOOC=true, alpha=1.0, alphaOOC=0.35,
        showHotkey=true, showCount=true, showMacro=false,
        enabled=true,
    },
    [4] = {
        id=4, page=4, numButtons=6, size=36, spacing=3,
        rows=6, point="RIGHT", x=-14, y=0,
        fadeOOC=true, alpha=1.0, alphaOOC=0.35,
        showHotkey=true, showCount=true, showMacro=false,
        enabled=true,
    },
    [5] = {
        id=5, page=5, numButtons=12, size=32, spacing=3,
        rows=1, point="BOTTOM", x=0, y=98,
        fadeOOC=true, alpha=0.9, alphaOOC=0.2,
        showHotkey=false, showCount=true, showMacro=false,
        enabled=false,
    },
    [6] = {
        id=6, page=6, numButtons=12, size=32, spacing=3,
        rows=1, point="BOTTOM", x=0, y=136,
        fadeOOC=true, alpha=0.9, alphaOOC=0.2,
        showHotkey=false, showCount=true, showMacro=false,
        enabled=false,
    },
}

-- Mapping: VuloUI Bar → WoW ActionBar Page
local BAR_PAGE_MAP = {
    [1] = 1,  -- Hauptbar → Page 1
    [2] = 2,  -- 2. Bar   → Page 2 (shift-bar)
    [3] = 5,  -- Links    → Page 5
    [4] = 6,  -- Rechts   → Page 6
    [5] = 3,  -- Extra 1  → Page 3
    [6] = 4,  -- Extra 2  → Page 4
}

-- ============================================================
--  COOLDOWN-TEXT (OmniCC-Style)
-- ============================================================

local function FormatCooldown(remain)
    if remain >= 3600 then
        return string.format("%dh", math.ceil(remain / 3600))
    elseif remain >= 60 then
        return string.format("%dm", math.ceil(remain / 60))
    elseif remain >= 10 then
        return string.format("%d",  math.ceil(remain))
    elseif remain >= 3 then
        -- Gelb: 3-10 Sekunden
        return string.format("|cffFFD700%.0f|r", remain)
    else
        -- Rot: < 3 Sekunden
        return string.format("|cffFF4444%.1f|r", remain)
    end
end

-- ============================================================
--  EINZELNER BUTTON
-- ============================================================

local function CreateActionButton(barID, slot, cfg)
    local globalSlot = (BAR_PAGE_MAP[barID] - 1) * 12 + slot

    -- WICHTIG: SecureActionButtonTemplate für In-Combat-Clicks
    local btnName = "VuloUI_Bar" .. barID .. "_Btn" .. slot
    local btn = CreateFrame("CheckButton", btnName, UIParent,
        "SecureActionButtonTemplate, ActionButtonTemplate")

    btn:SetAttribute("type",   "action")
    btn:SetAttribute("action", globalSlot)

    -- Pixel-perfect Größe
    local size = P(cfg.size)
    btn:SetSize(size, size)

    -- Blizzard Standard-Texturen durch eigene ersetzen
    -- Icon
    local icon = btn:GetNormalTexture()
    if icon then
        icon:SetPoint("TOPLEFT",     btn, "TOPLEFT",     P(1), -P(1))
        icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -P(1), P(1))
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    end

    -- Pushed-Textur (gedrückt)
    local pushed = btn:GetPushedTexture()
    if pushed then
        pushed:SetColorTexture(1, 1, 1, 0.3)
        pushed:SetPoint("TOPLEFT",     btn, "TOPLEFT",     P(1), -P(1))
        pushed:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -P(1), P(1))
    end

    -- Highlight (hover)
    local hl = btn:GetHighlightTexture()
    if hl then
        hl:SetColorTexture(1, 1, 1, 0.15)
        hl:SetPoint("TOPLEFT",     btn, "TOPLEFT",     P(1), -P(1))
        hl:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -P(1), P(1))
    end

    -- Checked (aktiver Spell/Toggle)
    btn:GetCheckedTexture():SetColorTexture(
        0.58, 0.44, 0.86, 0.5)

    -- ── HINTERGRUND ──────────────────────────────────────────
    -- Leerer Button: dunkler Hintergrund
    local bg = btn:CreateTexture(nil, "BACKGROUND", nil, -8)
    bg:SetAllPoints()
    bg:SetColorTexture(0.06, 0.06, 0.10, 0.9)
    btn.bg = bg

    -- ── RAHMEN ───────────────────────────────────────────────
    local border = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    border:SetPoint("TOPLEFT",     btn, "TOPLEFT",     -P(1), P(1))
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",  P(1), -P(1))
    border:SetFrameLevel(btn:GetFrameLevel() - 1)
    border:SetBackdrop({
        edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeSize = P(1),
        insets   = {left=P(1),right=P(1),top=P(1),bottom=P(1)},
    })
    border:SetBackdropBorderColor(0.12, 0.08, 0.20, 1)
    btn.border = border

    -- ── COOLDOWN (Blizzard Cooldown Frame) ───────────────────
    local cd = CreateFrame("Cooldown", btnName.."CD", btn,
                           "CooldownFrameTemplate")
    cd:SetAllPoints(btn)
    cd:SetDrawEdge(false)
    cd:SetDrawSwipe(true)
    cd:SetSwipeColor(0, 0, 0, 0.8)
    cd:SetDrawBling(false)
    -- Cooldown-Text (OmniCC-Style)
    cd:SetHideCountdownNumbers(true)  -- Blizzard-Zahlen aus
    btn.cooldown = cd

    -- Eigener Cooldown-Text
    local cdText = btn:CreateFontString(nil, "OVERLAY")
    cdText:SetFont(GetFont(), P(math.max(cfg.size * 0.33, 10)),
                   "OUTLINE")
    cdText:SetPoint("CENTER", btn, "CENTER", 0, 0)
    cdText:SetTextColor(1, 1, 1)
    cdText:SetShadowColor(0, 0, 0, 1)
    cdText:SetShadowOffset(P(1), -P(1))
    cdText:Hide()
    btn.cdText = cdText

    -- ── HOTKEY TEXT ──────────────────────────────────────────
    local hotkey = btn:CreateFontString(nil, "OVERLAY")
    hotkey:SetFont(GetFont(), P(8), "OUTLINE")
    hotkey:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -P(2), -P(2))
    hotkey:SetTextColor(0.7, 0.7, 0.7)
    hotkey:SetShadowColor(0, 0, 0, 1)
    hotkey:SetShadowOffset(P(1), -P(1))
    btn.hotkeyText = hotkey
    if not cfg.showHotkey then hotkey:Hide() end

    -- ── COUNT (Stack-Zahl) ───────────────────────────────────
    local count = btn:CreateFontString(nil, "OVERLAY")
    count:SetFont(GetFont(), P(9), "OUTLINE")
    count:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT",
                   -P(2), P(2))
    count:SetTextColor(1, 1, 1)
    count:SetShadowColor(0, 0, 0, 1)
    count:SetShadowOffset(P(1), -P(1))
    btn.countText = count
    if not cfg.showCount then count:Hide() end

    -- ── MACRO-NAME ───────────────────────────────────────────
    local macroName = btn:CreateFontString(nil, "OVERLAY")
    macroName:SetFont(GetFont(), P(7), "OUTLINE")
    macroName:SetPoint("BOTTOM", btn, "BOTTOM", 0, P(2))
    macroName:SetTextColor(0.9, 0.9, 0.9)
    macroName:SetShadowColor(0, 0, 0, 1)
    macroName:SetShadowOffset(P(1), -P(1))
    btn.macroText = macroName
    if not cfg.showMacro then macroName:Hide() end

    -- ── USABLE-OVERLAY (Ausgegraut wenn nicht nutzbar) ───────
    btn.notUsable = btn:CreateTexture(nil, "OVERLAY")
    btn.notUsable:SetAllPoints()
    btn.notUsable:SetColorTexture(0.3, 0.3, 0.3, 0.6)
    btn.notUsable:Hide()

    -- ── RANGE-OVERLAY (Rot wenn zu weit weg) ─────────────────
    btn.outOfRange = btn:CreateTexture(nil, "OVERLAY")
    btn.outOfRange:SetAllPoints()
    btn.outOfRange:SetColorTexture(0.9, 0.1, 0.1, 0.4)
    btn.outOfRange:Hide()

    -- ── STATE-TRACKING ───────────────────────────────────────
    btn.barID      = barID
    btn.slot       = slot
    btn.globalSlot = globalSlot
    btn.cdStart    = 0
    btn.cdDuration = 0
    btn.cdActive   = false

    -- ── UPDATE FUNKTIONEN ────────────────────────────────────

    function btn:UpdateAction()
        local actionType, id, subType =
            GetActionInfo(self.globalSlot)
        local hasAction = HasAction(self.globalSlot)

        -- Icon
        if hasAction then
            local tex = GetActionTexture(self.globalSlot)
            if tex then
                self:SetNormalTexture(tex)
                self:GetNormalTexture():SetTexCoord(
                    0.08, 0.92, 0.08, 0.92)
                self.bg:SetColorTexture(0, 0, 0, 1)
            end
        else
            self:SetNormalTexture("")
            self.bg:SetColorTexture(0.06, 0.06, 0.10, 0.9)
        end

        -- Macro-Name
        if cfg.showMacro and actionType == "macro" then
            local name = GetMacroInfo(id)
            self.macroText:SetText(name or "")
            self.macroText:Show()
        else
            self.macroText:SetText("")
        end

        self:UpdateHotkey()
        self:UpdateCooldown()
        self:UpdateUsable()
        self:UpdateCount()
    end

    function btn:UpdateHotkey()
        if not cfg.showHotkey then return end
        local key = GetBindingKey("ACTIONBUTTON" .. self.slot)
        if not key and self.barID > 1 then
            -- Multi-Actionbar Bindings
            local bindingPrefix = {
                [2]="MULTIACTIONBAR4BUTTON",
                [3]="MULTIACTIONBAR3BUTTON",
                [4]="MULTIACTIONBAR2BUTTON",
                [5]="MULTIACTIONBAR1BUTTON",
                [6]="MULTIACTIONBAR1BUTTON",
            }
            local prefix = bindingPrefix[self.barID]
            if prefix then
                key = GetBindingKey(prefix .. self.slot)
            end
        end

        if key then
            -- Modifier-Tasten kürzen
            key = key:gsub("SHIFT%-",   "S-")
                     :gsub("CTRL%-",    "C-")
                     :gsub("ALT%-",     "A-")
                     :gsub("NUMPAD",    "N")
                     :gsub("BUTTON",    "M")
                     :gsub("MOUSEWHEELUP",   "WU")
                     :gsub("MOUSEWHEELDOWN", "WD")
            self.hotkeyText:SetText(key)
        else
            self.hotkeyText:SetText("")
        end
    end

    function btn:UpdateCooldown()
        local start, duration, enable =
            GetActionCooldown(self.globalSlot)

        if start > 0 and duration > 1.5 then
            self.cooldown:SetCooldown(start, duration)
            self.cdStart    = start
            self.cdDuration = duration
            self.cdActive   = true
            self.cdText:Show()
        else
            self.cooldown:Clear()
            self.cdActive = false
            self.cdText:Hide()
        end
    end

    function btn:UpdateUsable()
        if not HasAction(self.globalSlot) then
            self.notUsable:Hide()
            self.outOfRange:Hide()
            return
        end

        local usable, oom = IsUsableAction(self.globalSlot)
        local inRange     = IsActionInRange(self.globalSlot)

        -- Außer Reichweite: rotes Overlay
        if inRange == false then
            self.outOfRange:Show()
            self.notUsable:Hide()
        -- Nicht nutzbar (kein Mana, falsche Stance): ausgegraut
        elseif not usable or oom then
            self.notUsable:Show()
            self.outOfRange:Hide()
        else
            self.notUsable:Hide()
            self.outOfRange:Hide()
        end

        -- Checked (Toggle-Spells wie Autoattack)
        self:SetChecked(IsCurrentAction(self.globalSlot) or
                        IsAutoRepeatAction(self.globalSlot))
    end

    function btn:UpdateCount()
        if not cfg.showCount then return end
        local count = GetActionCount(self.globalSlot)
        if count and count > 0 then
            self.countText:SetText(count)
            self.countText:Show()
        else
            self.countText:Hide()
        end
    end

    -- OnUpdate: Cooldown-Text
    btn.cdElapsed = 0
    btn:SetScript("OnUpdate", function(self, elapsed)
        self.cdElapsed = self.cdElapsed + elapsed
        if self.cdElapsed < 0.1 then return end
        self.cdElapsed = 0

        if self.cdActive then
            local remain = self.cdStart + self.cdDuration
                           - GetTime()
            if remain > 0 then
                self.cdText:SetText(FormatCooldown(remain))
                -- Cooldown-Text-Größe dynamisch
                local fontSize = P(math.max(cfg.size * 0.33, 10))
                if remain < 5 then
                    fontSize = P(math.max(cfg.size * 0.44, 13))
                end
                self.cdText:SetFont(GetFont(), fontSize, "OUTLINE")
            else
                self.cdActive = false
                self.cdText:Hide()
                self:UpdateUsable()
            end
        end

        -- Range-Check alle 0.5s
        self:UpdateUsable()
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetAction(self.globalSlot)
        GameTooltip:Show()
        -- Rahmen beim Hover hervorheben
        self.border:SetBackdropBorderColor(
            0.45, 0.28, 0.70, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.border:SetBackdropBorderColor(
            0.12, 0.08, 0.20, 1)
    end)

    return btn
end

-- ============================================================
--  ACTIONBAR (Container für Buttons)
-- ============================================================

local function CreateActionBar(cfg)
    -- Größen berechnen
    local size    = P(cfg.size)
    local spacing = P(cfg.spacing)
    local cols    = math.ceil(cfg.numButtons / cfg.rows)
    local rows    = cfg.rows
    local barW    = cols * size + (cols - 1) * spacing
    local barH    = rows * size + (rows - 1) * spacing

    -- Container-Frame (nicht-secure für Drag)
    local bar = CreateFrame("Frame", "VuloUI_ActionBar"..cfg.id,
                            UIParent)
    bar:SetSize(barW, barH)
    bar:SetPoint(cfg.point, UIParent, cfg.point,
                 P(cfg.x), P(cfg.y))
    bar:SetMovable(true)
    bar.cfg = cfg
    bar.buttons = {}

    -- Buttons erstellen und positionieren
    for i = 1, cfg.numButtons do
        local btn = CreateActionButton(cfg.id, i, cfg)

        -- Grid-Position berechnen
        local col = ((i - 1) % cols)
        local row = math.floor((i - 1) / cols)

        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", bar, "TOPLEFT",
            col * (size + spacing),
           -row * (size + spacing))

        btn:SetParent(bar)
        btn:Show()
        btn:UpdateAction()

        bar.buttons[i] = btn
        if not AB.buttons[cfg.id] then
            AB.buttons[cfg.id] = {}
        end
        AB.buttons[cfg.id][i] = btn
    end

    -- ── FADE-SYSTEM ──────────────────────────────────────────
    bar.targetAlpha = cfg.alpha
    bar.currentAlpha= cfg.alpha
    bar:SetAlpha(cfg.alpha)

    bar.fadeElapsed = 0
    bar:SetScript("OnUpdate", function(self, elapsed)
        self.fadeElapsed = self.fadeElapsed + elapsed
        if self.fadeElapsed < 0.05 then return end
        self.fadeElapsed = 0

        -- Smooth Fade
        local diff = self.targetAlpha - self.currentAlpha
        if math.abs(diff) > 0.01 then
            self.currentAlpha = self.currentAlpha +
                diff * 0.2  -- Fade-Speed
            self:SetAlpha(self.currentAlpha)
        elseif math.abs(diff) > 0 then
            self.currentAlpha = self.targetAlpha
            self:SetAlpha(self.targetAlpha)
        end
    end)

    function bar:SetInCombat(inCombat)
        if self.cfg.fadeOOC then
            self.targetAlpha = inCombat and
                self.cfg.alpha or self.cfg.alphaOOC
        else
            self.targetAlpha = self.cfg.alpha
        end
    end

    -- Mouseover-Fade
    bar:EnableMouse(false)  -- damit Maus durch Container geht

    -- ── VERSCHIEBEN (nur im Config-Modus) ───────────────────
    bar:RegisterForDrag("LeftButton")
    bar:SetScript("OnDragStart", bar.StartMoving)
    bar:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local x, y = self:GetCenter()
        local screenW = GetScreenWidth()
        local screenH = GetScreenHeight()
        -- Als BOTTOM-Anker speichern
        V:Set(x - screenW/2, "actionBars", cfg.id, "x")
        V:Set(y - screenH/2, "actionBars", cfg.id, "y")
    end)

    return bar
end

-- ============================================================
--  BLIZZARD BARS VERSTECKEN
-- ============================================================

local BLIZZARD_BARS = {
    "MainMenuBar",
    "MultiBarRight",
    "MultiBarLeft",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "StanceBar",
    "PossessActionBar",
    "MainMenuBarVehicleLeaveButton",
    "MicroButtonAndBagsBar",
    "MainMenuBarBackpackButton",
    "CharacterMicroButton",
    "SpellbookMicroButton",
    "TalentMicroButton",
    "AchievementMicroButton",
    "QuestLogMicroButton",
    "GuildMicroButton",
    "LFDMicroButton",
    "CollectionsMicroButton",
    "EJMicroButton",
    "StoreMicroButton",
    "MainMenuMicroButton",
    "HelpMicroButton",
}

local function HideBlizzardBars()
    for _, name in ipairs(BLIZZARD_BARS) do
        local f = _G[name]
        if f then
            f:UnregisterAllEvents()
            f:Hide()
            -- SecureHandler damit es in Kämpfen versteckt bleibt
            if f.HidePartyFrame then f:HidePartyFrame() end
        end
    end

    -- MainMenuBar Textur (die Bodenleiste) verstecken
    if MainMenuBar then
        MainMenuBar:SetAlpha(0)
        MainMenuBar:EnableMouse(false)
    end

    -- Exp/Rep-Bar verstecken
    if MainMenuExpBar then
        MainMenuExpBar:UnregisterAllEvents()
        MainMenuExpBar:Hide()
    end

    -- Status-Tracking Bars
    if StatusTrackingBarManager then
        StatusTrackingBarManager:Hide()
    end
end

-- ============================================================
--  GLOBALE EVENT-HANDLER
-- ============================================================

-- Alle Buttons updaten
local function UpdateAllButtons()
    for barID, buttons in pairs(AB.buttons) do
        for _, btn in pairs(buttons) do
            btn:UpdateAction()
        end
    end
end

-- Einzelnen Slot updaten
local function UpdateSlot(slot)
    for barID, buttons in pairs(AB.buttons) do
        for _, btn in pairs(buttons) do
            if btn.globalSlot == slot then
                btn:UpdateAction()
            end
        end
    end
end

-- Combat-State für Fade
local function SetCombatState(inCombat)
    for _, bar in pairs(AB.bars) do
        bar:SetInCombat(inCombat)
    end
end

V:RegisterEvent("ACTIONBAR_PAGE_CHANGED", function(_, slot)
    if slot == 0 then
        UpdateAllButtons()
    else
        UpdateSlot(slot)
    end
end)

V:RegisterEvent("ACTIONBAR_UPDATE_STATE", function()
    UpdateAllButtons()
end)

V:RegisterEvent("SPELL_UPDATE_COOLDOWN", function()
    for _, buttons in pairs(AB.buttons) do
        for _, btn in pairs(buttons) do
            btn:UpdateCooldown()
        end
    end
end)

V:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", function()
    UpdateAllButtons()
end)

V:RegisterEvent("PLAYER_REGEN_DISABLED", function()
    SetCombatState(true)
end)

V:RegisterEvent("PLAYER_REGEN_ENABLED", function()
    SetCombatState(false)
    UpdateAllButtons()
end)

V:RegisterEvent("UPDATE_BINDINGS", function()
    for _, buttons in pairs(AB.buttons) do
        for _, btn in pairs(buttons) do
            btn:UpdateHotkey()
        end
    end
end)

V:RegisterEvent("PLAYER_ENTERING_WORLD", function()
    UpdateAllButtons()
    SetCombatState(UnitAffectingCombat("player"))
end)

V:RegisterEvent("UPDATE_INVENTORY_ALERTS", function()
    UpdateAllButtons()
end)

V:RegisterEvent("SPELL_UPDATE_USABLE", function()
    for _, buttons in pairs(AB.buttons) do
        for _, btn in pairs(buttons) do
            btn:UpdateUsable()
        end
    end
end)

V:RegisterEvent("SPELL_UPDATE_CHARGES", function()
    UpdateAllButtons()
end)

V:RegisterEvent("BAG_UPDATE", function()
    UpdateAllButtons()
end)

-- ============================================================
--  UNLOCK / LOCK SYSTEM
-- ============================================================

local lockOverlays = {}

function AB:Unlock()
    for barID, bar in pairs(self.bars) do
        if not lockOverlays[barID] then
            -- Gelbes Overlay wenn entsperrt
            local ov = CreateFrame("Frame", nil, bar,
                                   "BackdropTemplate")
            ov:SetAllPoints()
            ov:SetBackdrop({
                bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
                edgeSize = P(1),
            })
            ov:SetBackdropColor(1, 0.85, 0.2, 0.08)
            ov:SetBackdropBorderColor(1, 0.85, 0.2, 0.8)
            ov:SetFrameLevel(bar:GetFrameLevel() + 50)

            local label = ov:CreateFontString(nil, "OVERLAY")
            label:SetFont(GetFont(), P(9), "OUTLINE")
            label:SetPoint("CENTER")
            label:SetText("Bar " .. barID)
            label:SetTextColor(1, 0.85, 0.2)

            lockOverlays[barID] = ov
        end
        lockOverlays[barID]:Show()
        bar:EnableMouse(true)
    end
end

function AB:Lock()
    for barID, bar in pairs(self.bars) do
        if lockOverlays[barID] then
            lockOverlays[barID]:Hide()
        end
        bar:EnableMouse(false)
    end
end

-- ============================================================
--  MODUL INIT
-- ============================================================

function AB:OnInitialize()
    -- Config-Defaults sicherstellen
    if not V.db.actionBars then
        V.db.actionBars = {}
    end

    -- Blizzard-Bars verstecken
    -- (muss nach PLAYER_LOGIN passieren für SecureFrames)
    V:RegisterEvent("PLAYER_LOGIN", function()
        HideBlizzardBars()
    end)

    -- Bars erstellen
    for i = 1, 6 do
        local cfg = BAR_DEFAULTS[i]

        -- Gespeicherte Position laden
        local savedCfg = V.db.actionBars[i]
        if savedCfg then
            cfg.x = savedCfg.x or cfg.x
            cfg.y = savedCfg.y or cfg.y
        end

        if cfg.enabled then
            local bar = CreateActionBar(cfg)
            self.bars[i] = bar
        end
    end
end

function AB:OnEnable()
    for _, bar in pairs(self.bars) do
        bar:Show()
    end
    UpdateAllButtons()
end

function AB:OnDisable()
    -- Bars verstecken und Blizzard wiederherstellen
    for _, bar in pairs(self.bars) do
        bar:Hide()
    end
    -- Blizzard-Bars wieder anzeigen
    if MainMenuBar then
        MainMenuBar:SetAlpha(1)
        MainMenuBar:Show()
    end
end