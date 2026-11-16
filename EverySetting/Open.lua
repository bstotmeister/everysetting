-- The ways to Every Setting from the game's own UI: key bindings, the entry in the
-- minimap's addon list with a menu on its right click, and an entry under
-- Options > AddOns. (/every is in Core.lua.)

local ADDON, ns = ...
local EverySetting = ns.EverySetting
local L = ns.L
local Print = EverySetting.Print

local TAGLINE = L.TAGLINE

-------------------------------------------------------------------------------
-- Key bindings
-------------------------------------------------------------------------------

-- Bindings.xml has the two bindings. These are their names in the game's
-- Keybindings list, where they're under AddOns. The list shows a header as a
-- gap, so each name says whose it is, and it cuts a name off after about 26
-- letters.
BINDING_HEADER_EVERYSETTING = L.ADDON_NAME
BINDING_NAME_EVERYSETTING_TOGGLE = L.BINDING_TOGGLE
BINDING_NAME_EVERYSETTING_UNDO = L.BINDING_UNDO

-------------------------------------------------------------------------------
-- The minimap's addon list
-------------------------------------------------------------------------------

-- Sets a whole style, as one change for Undo. In combat ApplyPreset says why not.
local function SetStyle(style)
	EverySetting.ApplyPreset(EverySetting.StylePreset(style))
	if not InCombatLockdown() then Print(L.STYLE_SET, style.name) end
end

local function IsProfile(name) return name == EverySetting.GetProfile() end

local function UseProfile(name)
	local used, why = EverySetting.SetProfile(name)
	Print(used and L.NOW_USING:format(used) or why)
end

-- Sets every kept value again, and says how many, as /every apply does.
local function ApplyNow() SlashCmdList.EVERYSETTING("apply") end

local function ResetAll(toDefault)
	local count = EverySetting.ResetAll(toDefault)
	Print(toDefault and L.RESET_TO_DEFAULTS_DONE or L.RESET_DONE, count)
end

-- The menu on the entry's right click: the game's own menu, at the pointer. An
-- entry is a line here, in the menu's order. Picking one closes the menu.
-- Reset all asks what to reset to, as its button in the window does.
local function Menu()
	MenuUtil.CreateContextMenu(UIParent, function(_, root)
		root:CreateTitle(L.STYLES)
		for _, style in ipairs(EverySetting.STYLES) do
			root:CreateButton(style.name, SetStyle, style):SetTitleAndTextTooltip(style.name, style.tip)
		end
		root:CreateTitle(L.PROFILE)
		for _, name in ipairs(EverySetting.GetProfiles()) do
			root:CreateRadio(name, IsProfile, UseProfile, name)
		end
		root:CreateDivider()
		root:CreateButton(L.APPLY_NOW, ApplyNow):SetTitleAndTextTooltip(L.APPLY_NOW, L.MENU_APPLY_NOW_TIP)
		local reset = root:CreateButton(L.RESET_ALL)
		reset:CreateButton(L.TO_BEFORE, ResetAll, false)
		reset:CreateButton(L.TO_DEFAULTS, ResetAll, true)
	end)
end

-- The game calls these three by the names the TOC gives it. A click comes with
-- the mouse button's name.
function EverySetting_OnAddonCompartmentClick(_, button)
	if button == "RightButton" then
		Menu()
	else
		EverySetting_OpenOptions()
	end
end

-- Hovering the entry.
function EverySetting_OnAddonCompartmentEnter(_, button)
	if not button then return end
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:SetText(L.ADDON_NAME, 1, 1, 1)
	GameTooltip:AddLine(TAGLINE, nil, nil, nil, true)
	GameTooltip:AddLine(L.COMPARTMENT_CLICK, 0.56, 0.56, 0.6)
	GameTooltip:AddLine(L.COMPARTMENT_RIGHT_CLICK, 0.56, 0.56, 0.6)
	GameTooltip:Show()
end

function EverySetting_OnAddonCompartmentLeave()
	GameTooltip:Hide()
end

-------------------------------------------------------------------------------
-- Options > AddOns
-------------------------------------------------------------------------------

-- The entry in the game's Options, on its AddOns tab: the logo, the tagline,
-- the version, a button that opens the window, and the Put back option. The window stays its own
-- frame, over the game's Options, which the button leaves open: an addon that
-- closes them taints them, and the game then blocks what they do.
local panel = CreateFrame("Frame", "EverySettingPanel")
panel:Hide() -- the game shows it when the entry is picked
local logo = panel:CreateTexture(nil, "ARTWORK")
logo:SetTexture("Interface\\AddOns\\EverySetting\\Media\\logo")
logo:SetSize(48, 48)
logo:SetPoint("TOPLEFT", 16, -16)
local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
title:SetPoint("TOPLEFT", logo, "TOPRIGHT", 12, -4)
title:SetText(L.ADDON_NAME)
local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 8, 2)
version:SetText("v" .. C_AddOns.GetAddOnMetadata(ADDON, "Version"))
local tagline = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -6)
tagline:SetText(TAGLINE)
panel.open = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
panel.open:SetSize(180, 26)
panel.open:SetPoint("TOPLEFT", logo, "BOTTOMLEFT", 0, -16)
panel.open:SetText(L.OPEN_WINDOW)
panel.open:SetScript("OnClick", function()
	if not (EverySettingOptions and EverySettingOptions:IsShown()) then EverySetting_OpenOptions() end
end)
-- Putting kept settings back by themselves (EverySetting.SetPutBack), and what it does.
panel.putBack = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
panel.putBack:SetPoint("TOPLEFT", panel.open, "BOTTOMLEFT", -4, -16)
panel.putBack:SetScript("OnClick", function(self) EverySetting.SetPutBack(self:GetChecked()) end)
panel:SetScript("OnShow", function() panel.putBack:SetChecked(EverySetting.GetPutBack()) end)
local putBackLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
putBackLabel:SetPoint("LEFT", panel.putBack, "RIGHT", 4, 1)
putBackLabel:SetText(L.PUT_BACK)
local putBackNote = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
putBackNote:SetPoint("TOPLEFT", panel.putBack, "BOTTOMLEFT", 4, -2)
putBackNote:SetWidth(460)
putBackNote:SetJustifyH("LEFT")
putBackNote:SetText(L.PUT_BACK_NOTE)

local category = Settings.RegisterCanvasLayoutCategory(panel, L.ADDON_NAME)
Settings.RegisterAddOnCategory(category)
