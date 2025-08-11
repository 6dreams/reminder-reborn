local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ReminderModule: MRTmodule
local module = MRT.A.Reminder
if not module then return end

---@class ELib
local ELib, L = MRT.lib, MRT.L
---@class MLib
local MLib = AddonDB.MLib

---@class Locale
local LR = AddonDB.LR

local options = module.options

 -- upvalues
local CreateColor, CreateFrame = CreateColor, CreateFrame
local IsShiftKeyDown, UnitName = IsShiftKeyDown, UnitName
local format = format
local next, tonumber = next, tonumber

local function GetMediaName(mediatype, path)
	if not path then return end
	for name, p in MRT.F.IterateMediaData(mediatype) do
		if p == path then
			return name
		end
	end
end

function options:Load()
	local RequiredMRT = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-RequiredMRT") or "0")
	if RequiredMRT and MRT.V < RequiredMRT then
		module.prettyPrint("ExRT_Reminder requires MRT version "..RequiredMRT.." or higher to work properly. Please update MRT.")
		MLib:DialogPopup({
			id = "REMINDER_MRT_VERSION_OUTDATED",
			title = LR["MRT Version Outdated"],
			text = LR.MRTOUTDATED:format(GlobalAddonName, RequiredMRT),
			buttons = {
				{
					text = OKAY,
				},
			},
			alert = true,
			minWidth = 420,
		})
		return
	end

	local LCG = LibStub("LibCustomGlow-1.0")
	local glowList = LCG.glowList

	local COLORPICKER_INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE) -- todo recheck

	local VisualSettings = VMRT.Reminder.VisualSettings
	local GlowSettings = VisualSettings.Glow

	AddonDB:RegisterCallback("Reminder_VisualProfileChanged", function()
		VisualSettings = VMRT.Reminder.VisualSettings
		GlowSettings = VisualSettings.Glow

		options:UpdateVisualSettings()
	end)

	options:CreateTilte()

	MLib:CreateModuleHeader(options)

	local decorationLine = ELib:DecorationLine(options,true,"BACKGROUND",-5):Point("TOPLEFT",options,0,-25):Point("BOTTOMRIGHT",options,"TOPRIGHT",0,-45)
	decorationLine:SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	options.chkEnable = ELib:Check(options,LR.Enabled,VMRT.Reminder.enabled):Point("TOPRIGHT",options,"TOPRIGHT",-120,-26):Size(18,18):AddColorState():OnClick(function(self)
		VMRT.Reminder.enabled = self:GetChecked()
		if VMRT.Reminder.enabled then
			module:Enable()
		else
			module:Disable()
		end
	end)

	options.tab = MLib:Tabs2(options,0,LR["Main"],LR["Settings"],"Changelog",LR["Help"],LR.Versions):Point(0,-45):Size(698,570):SetTo(1)
	options.REMINDERS_MAIN_TAB = options.tab.tabs[1]
	options.SETTINGS_TAB = options.tab.tabs[2]
	options.CHANGELOG_TAB = options.tab.tabs[3]
	options.HELP_TAB = options.tab.tabs[4]
	options.VERSIONS_TAB = options.tab.tabs[5]

	options.main_tab = MLib:Tabs2(options.REMINDERS_MAIN_TAB,0,LR["Reminders"],LR["Timeline"],LR["Assignments"],LR["Deleted"]):Point(0,-25):Size(698,570)
	options.REMINDERS_SCROLL_LIST = options.main_tab.tabs[1]
	options.TIMELINE_TAB = options.main_tab.tabs[2]
	options.ASSIGNMENTS_TAB = options.main_tab.tabs[3]
	options.DELETED_TAB = options.main_tab.tabs[4]

	ELib:DecorationLine(options.main_tab,true,"BACKGROUND",1):Point("TOPLEFT",options,0,-50):Point("BOTTOMRIGHT",options,"TOPRIGHT",0,-70):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	function options.tab:buttonAdditionalFunc()
		if self.selected == 1 then
			options.main_tab:buttonAdditionalFunc()
		elseif options.isWide ~= 760 then
			options.isWide = 760
			MRT.Options.Frame:SetPage(MRT.Options.Frame.CurrentFrame)
		end
	end

	function options.main_tab:buttonAdditionalFunc()
		VMRT.Reminder.OptSavedTabNum = self.selected
		if self.selected == 3 then
			options.isWide = VMRT.Reminder.OptAssigWidth or 1000
		elseif self.selected == 2 then
			options.isWide = 1000
		else
			options.isWide = 760
		end
		MRT.Options.Frame:SetPage(MRT.Options.Frame.CurrentFrame)

		if self.selected == 1 then
			options:UpdateData()
		elseif self.selected == 2 then
			if not options.timeLine then
				options:TimelineInitialize()
			end
			if options.timeLine.preload then
				options.timeLine:preload()
				options.assign.preload = nil
				options.timeLine.preload = nil
			end
			options.timeLine:Update()
		elseif self.selected == 3 then
			if not options.assign then
				options:TimelineInitialize()
			end
			if options.assign.preload then
				options.assign:preload()
				options.timeLine.preload = nil
				options.assign.preload = nil
			end
			options.assign:Update()
		elseif self.selected == 4 then
			if options.BinScrollButtonsListInitialize then
				options:BinScrollButtonsListInitialize()
			end
			options:UpdateBinData()
		end
	end

	function options:Update()
		if options:IsVisible() then
			if options.main_tab.selected == 1 then
				if options.UpdateData then
					options:UpdateData()
				end
			elseif options.main_tab.selected == 2 then
				if options.timeLine and options.timeLine.Update then
					options.timeLine:Update()
				end
			elseif options.main_tab.selected == 3 then
				if options.assign and options.assign.Update then
					options.assign:Update()
				end
			elseif options.main_tab.selected == 4 then
				if options.UpdateBinData then
					options:UpdateBinData()
				end
			end
		end
	end

	function options:AdditionalOnShow()
		options:Update()
	end

	do
		local function scheduleUpdate()
			options.updTimer = C_Timer.NewTimer(1, function()
				options.updTimer = nil
				options:Update()
			end)
		end
		MRT.F:RegisterCallback("Note_SendText", scheduleUpdate)
		MRT.F:RegisterCallback("Note_ReceivedText", scheduleUpdate)
	end

	-- search field used in 4 tabs that list reminders
	options.searchEdit = ELib:Edit(options.REMINDERS_MAIN_TAB):AddSearchIcon():Size(180,18):Point("TOPLEFT",options,"TOPLEFT",480,-51):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():lower()
		if text == "" then
			text = nil
			self:BackgroundText(LR.search)
		else
			self:BackgroundText("")
		end
		options.search = text

		if self.scheduledUpdate then
			return
		end
		self.scheduledUpdate = C_Timer.NewTimer(.1,function()
			self.scheduledUpdate = nil
			options.scrollList.ScrollBar.slider:SetValue(0)
			if options.Update then
				options.Update()
			end
		end)
	end)
	options.searchEdit:BackgroundText(LR.search)
	options.searchEdit:SetTextColor(0,1,0,1)
	options.searchEdit:SetFrameLevel(6000)
	options.searchEdit:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(LR.search)
		GameTooltip:AddLine(LR.searchTip,1,1,1,true)
		GameTooltip:Show()
	end)
	options.searchEdit:SetScript("OnLeave", GameTooltip_Hide)

	---------------------------------------
	-- Reminders List UI And Functions
	---------------------------------------

	options:MainScrollButtonsListInitialize()
	options:InitializeLastSyncWindow()

	---------------------------------------
	-- Reminder Options(Second Tab). Would prefer some renaming here and probably refactor as well. Was making changes here long ago, so code must be fucked
	---------------------------------------

	options.options_tab = MLib:Tabs2(options.SETTINGS_TAB,0,GENERAL_LABEL,TUTORIAL_TITLE19):Point(0,-25):Size(698,570):SetTo(1)
	options.options_tab.GENERAL_SETTINGS = options.options_tab.tabs[1]
	options.options_tab.ALWAYS_PLAYERS_SETTINGS = options.options_tab.tabs[2]


	ELib:DecorationLine(options.SETTINGS_TAB,true,"BACKGROUND",1):Point("TOPLEFT",options,0,-50):Point("BOTTOMRIGHT",options,"TOPRIGHT",0,-70):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))
	options.chkLock = ELib:Check(options.options_tab.GENERAL_SETTINGS,L.cd2fix,true):Point(10,-10):OnClick(function(self)
		module.frame.unlocked = not self:GetChecked()
		module:UpdateVisual()
	end)

	options.disableSound = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR.DisableSound,VMRT.Reminder.disableSound):Point(10,-35):OnClick(function(self)
		VMRT.Reminder.disableSound = self:GetChecked()
	end)

	options.updatesDebug = ELib:Check(options.options_tab.GENERAL_SETTINGS,"DEBUG UPDATES",VMRT.Reminder.debugUpdates):Point(325,-10):OnClick(function(self)
		VMRT.Reminder.debugUpdates = self:GetChecked()
	end)
	options.disableUpdates = ELib:Check(options.options_tab.GENERAL_SETTINGS,"DISABLE UPDATES",VMRT.Reminder.disableUpdates):Point(325,-35):OnClick(function(self)
		VMRT.Reminder.disableUpdates = self:GetChecked()
	end)
	options.bwDebug = ELib:Check(options.options_tab.GENERAL_SETTINGS,"BIGWIGS DEBUG",VMRT.Reminder.bwDebug):Point(325,-60):OnClick(function(self)
		VMRT.Reminder.bwDebug = self:GetChecked()
	end)
	options.alwaysLoad = ELib:Check(options.options_tab.GENERAL_SETTINGS,"ALWAYS PASS LOAD CONDITIONS",VMRT.Reminder.alwaysLoad):Point(325,-85):OnClick(function(self)
		VMRT.Reminder.alwaysLoad = self:GetChecked()
	end)

	local debugCheckFrame = CreateFrame("Frame",nil,options.options_tab.GENERAL_SETTINGS)
	debugCheckFrame:SetPoint("TOPLEFT")
	debugCheckFrame:SetSize(1,1)
	debugCheckFrame:SetScript("OnShow",function()
		if IsShiftKeyDown() and IsAltKeyDown() then
			options.updatesDebug:Show()
			options.disableUpdates:Show()
			options.bwDebug:Show()
			options.alwaysLoad:Show()
		else
			options.updatesDebug:Hide()
			options.disableUpdates:Hide()
			options.bwDebug:Hide()
			options.alwaysLoad:Hide()
		end
	end)

	options.chkEnableHistory = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR.EnableHistory,VMRT.Reminder.HistoryEnabled):Point(10,-70):OnClick(function(self)
		VMRT.Reminder.HistoryEnabled = self:GetChecked()
	end)

	options.chkSaveHistory = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR["Save history between sessions"],VMRT.Reminder.SaveHistory):Point(10,-95):Tooltip(LR["Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"]):OnClick(function(self)
		VMRT.Reminder.SaveHistory = self:GetChecked()

		if VMRT.Reminder.SaveHistory then
			ReminderLog.history = ReminderLog.history or module.db.history or {}
			module.db.history = ReminderLog.history
		else
			if module.SetupFrame and module.SetupFrame.QuickList then
				module.SetupFrame.QuickList:Reset()
			end
			module.db.history = {}
		end


		if module.SetupFrame and module.SetupFrame.QuickList then
			module.SetupFrame:UpdateHistory()
		end
	end)

	options.chkHistoryTransmission = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR["History transmission"],VMRT.Reminder.HistoryTransmission):Tooltip(LR["Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"]):Point(10,-120):OnClick(function(self)
		VMRT.Reminder.HistoryTransmission = self:GetChecked()
	end)

	options.HistorySlider = ELib:Slider(options.options_tab.GENERAL_SETTINGS,LR["Amount of pulls to save\nper boss and difficulty"]):Size(280):Point(10,-165):Range(2,16):SetTo(VMRT.Reminder.HistoryMaxPulls or 2):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.HistoryMaxPulls = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)

		if module.SetupFrame and module.SetupFrame.QuickList then
			module.SetupFrame:UpdateHistory()
		end
	end)

	---------------------------------------
	-- Data Profiles
	---------------------------------------

	local function GetCurrentDataProfileName()
		local text
		if VMRT.Reminder.ForcedDataProfile then
			text = VMRT.Reminder.ForcedDataProfile
		else
			text = VMRT.Reminder.DataProfileKeys[ MRT.SDB.charKey ] or "Default"
		end
		if text == "Default" then
			text = LR.Default
		end
		return text
	end

	options.DataProfileDropDown = ELib:DropDown(options.options_tab.GENERAL_SETTINGS,250,-1):Point(200,-210):Size(240):SetText(GetCurrentDataProfileName()):AddText("|cffffce00" ..LR["Profile"]..":"):Tooltip(LR["DataProfileTip1"])

	function options.DataProfileDropDown:PreUpdate()
		MLib:DialogPopupHide("EXRT_REMINDER_COPY_PROFILE")
		MLib:DialogPopupHide("EXRT_REMINDER_DELETE_PROFILE")
		MLib:DialogPopupHide("EXRT_REMINDER_ADD_PROFILE")

		local List = self.List
		local removeSubMenu = {}
		local copySubMenu = {}
		wipe(List)
		List[#List+1] = {text = LR["Add new"], colorCode = "|cff00aaff", func = function()
			ELib:DropDownClose()
			MLib:DialogPopup({
				id = "EXRT_REMINDER_ADD_PROFILE",
				title = LR["Create new profile"],
				text = LR["Enter profile name"],
				buttons = {
					{
						text = ACCEPT,
						func = function(self)
							local name = self.editBox:GetText()
							if name and name ~= "" then
								options.DataProfileDropDown:SetDataProfile(name)
							end
						end,
					},
				},
				editBox = {},
			})
		end, sort = "00Add"}
		for profileKey in next, VMRT.Reminder.DataProfiles do
			local text = profileKey == "Default" and LR.Default or profileKey
			List[#List+1] = {
				text = text,
				func = self.SetDataProfile,
				arg1 = profileKey,
				sort = (profileKey == "Default" and "0" or  "1")..profileKey,
			}
			if profileKey ~= VMRT.Reminder.DataProfile then -- dont allow to delete currently selected profile
				if profileKey ~= "Default" then
					removeSubMenu[#removeSubMenu+1] = {
						text = text,
						func = self.DeleteDataProfile,
						arg1 = profileKey,
						sort = "1"..profileKey,
					}
				end
				copySubMenu[#copySubMenu+1] = {
					text = text,
					func = self.CopyDataProfile,
					arg1 = profileKey,
					arg2 = VMRT.Reminder.DataProfile,
					sort = (profileKey == "Default" and "0" or  "1")..profileKey,
				}
			end
		end
		if #removeSubMenu > 0 then
			sort(removeSubMenu,function(a,b)
				return a.sort < b.sort
			end)
			List[#List+1] = {text = LR["Delete"], colorCode = "|cffff0000", subMenu = removeSubMenu, sort = "00Remove"}
		end
		if #copySubMenu > 0 then
			sort(copySubMenu,function(a,b)
				return a.sort < b.sort
			end)
			List[#List+1] = {text = LR["Copy into current profile from"], colorCode = "|cff00ff00", subMenu = copySubMenu, sort = "00Copy"}
		end
		sort(List,function(a,b)
			return a.sort < b.sort
		end)

	end

	function options.DataProfileDropDown:SetDataProfile(profileKey)
		ELib:DropDownClose()
		if VMRT.Reminder.ForcedDataProfile then
			VMRT.Reminder.ForcedDataProfile = profileKey
		end
		VMRT.Reminder.DataProfileKeys[ MRT.SDB.charKey ] = profileKey
		module:LoadDataProfile()
		options.DataProfileDropDown:SetText(GetCurrentDataProfileName())
	end

	function options.DataProfileDropDown:DeleteDataProfile(profileKey)
		ELib:DropDownClose()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_DELETE_PROFILE",
			title = LR["Delete profile"],
			text = LR["Delete profile"].." '"..profileKey.."'?",
			buttons = {
				{
					text = ACCEPT,
					func = function(self)
						VMRT.Reminder.DataProfiles[profileKey] = nil
						if VMRT.Reminder.ForcedDataProfile == profileKey then
							VMRT.Reminder.ForcedDataProfile = "Default"
						end
						for charKey,profileK in next, VMRT.Reminder.DataProfileKeys do
							if profileK == profileKey then
								VMRT.Reminder.DataProfileKeys[charKey] = nil
							end
						end
						module:LoadDataProfile()
						options.DataProfileDropDown:SetText(GetCurrentDataProfileName())
					end,
				},
				{
					text = CANCEL,
				}
			},
			alert = true,
		})
	end

	function options.DataProfileDropDown:CopyDataProfile(profileKey)
		ELib:DropDownClose()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_COPY_PROFILE",
			title = LR["Copy profile"],
			text = LR["Copy into current profile from"].." '"..profileKey.."'?",
			buttons = {
				{
					text = ACCEPT,
					func = function()
						if VMRT.Reminder.DataProfiles[profileKey] then
							local copiedData = CopyTable(VMRT.Reminder.DataProfiles[profileKey])
							VMRT.Reminder.data = copiedData.data
							VMRT.Reminder.removed = copiedData.removed
							VMRT.Reminder.options = copiedData.options
							module:ReloadAll()
							options:Update()
						end
					end,
				},
				{
					text = CANCEL,
				}
			},
			alert = true,
		})
	end

	options.ForcedDataProfileCheck = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR["Use for all characters"],VMRT.Reminder.ForcedDataProfile):Point("LEFT",options.DataProfileDropDown,"RIGHT",5,0):OnClick(function(self)
		if self:GetChecked() then
			VMRT.Reminder.ForcedDataProfile = VMRT.Reminder.DataProfile
		else
			VMRT.Reminder.ForcedDataProfile = false
		end
		module:LoadDataProfile()
		options.DataProfileDropDown:SetText(GetCurrentDataProfileName())
	end)


	---------------------------------------
	-- Visual Profiles
	---------------------------------------

	local function GetCurrentVisualProfileName()
		local text
		if VMRT.Reminder.ForcedVisualProfile then
			text = VMRT.Reminder.ForcedVisualProfile
		else
			text = VMRT.Reminder.VisualProfileKeys[ MRT.SDB.charKey ] or "Default"
		end
		if text == "Default" then
			text = LR.Default
		end
		return text
	end

	options.VisualProfileDropDown = ELib:DropDown(options.options_tab.GENERAL_SETTINGS,250,-1):Point(200,-235):Size(240):SetText(GetCurrentVisualProfileName()):AddText("|cffffce00" ..LR["Visual Profile"]..":"):Tooltip(LR["VisualProfileTip1"])

	function options.VisualProfileDropDown:PreUpdate()
		MLib:DialogPopupHide("EXRT_REMINDER_COPY_VISUAL_PROFILE")
		MLib:DialogPopupHide("EXRT_REMINDER_DELETE_VISUAL_PROFILE")
		MLib:DialogPopupHide("EXRT_REMINDER_ADD_VISUAL_PROFILE")

		local List = self.List
		local removeSubMenu = {}
		local copySubMenu = {}
		wipe(List)
		List[#List+1] = {text = LR["Add new"], colorCode = "|cff00aaff", func = function()
			ELib:DropDownClose()
			MLib:DialogPopup({
				id = "EXRT_REMINDER_ADD_VISUAL_PROFILE",
				title = LR["Create visual profile"],
				text = LR["Enter profile name"],
				buttons = {
					{
						text = ACCEPT,
						func = function(self)
							local name = self.editBox:GetText()
							if name and name ~= "" then
								options.VisualProfileDropDown:SetVisualProfile(name)
							end
								end,
							},
					{
						text = CANCEL,
					}
				},
				editBox = {}
			})
		end, sort = "00Add"}
		for profileKey in next, VMRT.Reminder.VisualProfiles do
			local text = profileKey == "Default" and LR.Default or profileKey
			List[#List+1] = {
				text = text,
				func = self.SetVisualProfile,
				arg1 = profileKey,
				sort = (profileKey == "Default" and "0" or  "1")..profileKey,
			}
			if profileKey ~= VMRT.Reminder.VisualProfile then -- dont allow to delete or currently selected profile
				if profileKey ~= "Default" then
					removeSubMenu[#removeSubMenu+1] = {
						text = text,
						func = self.DeleteVisualProfile,
						arg1 = profileKey,
						sort = "1"..profileKey,
					}
				end
				copySubMenu[#copySubMenu+1] = {
					text = text,
					func = self.CopyVisualProfile,
					arg1 = profileKey,
					arg2 = VMRT.Reminder.VisualProfile,
					sort = (profileKey == "Default" and "0" or  "1")..profileKey,
				}
			end
		end
		if #removeSubMenu > 0 then
			sort(removeSubMenu,function(a,b)
				return a.sort < b.sort
			end)
			List[#List+1] = {text = LR["Delete"], colorCode = "|cffff0000", subMenu = removeSubMenu, sort = "00Remove"}
		end
		if #copySubMenu > 0 then
			sort(copySubMenu,function(a,b)
				return a.sort < b.sort
			end)
			List[#List+1] = {text = LR["Copy into current profile from"], colorCode = "|cff00ff00", subMenu = copySubMenu, sort = "00Copy"}
		end
		sort(List,function(a,b)
			return a.sort < b.sort
		end)

	end

	function options.VisualProfileDropDown:SetVisualProfile(profileKey)
		ELib:DropDownClose()
		if VMRT.Reminder.ForcedVisualProfile then
			VMRT.Reminder.ForcedVisualProfile = profileKey
		end
		VMRT.Reminder.VisualProfileKeys[ MRT.SDB.charKey ] = profileKey
		module:LoadVisualProfile()
		options.VisualProfileDropDown:SetText(GetCurrentVisualProfileName())
	end

	function options.VisualProfileDropDown:DeleteVisualProfile(profileKey)
		ELib:DropDownClose()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_DELETE_VISUAL_PROFILE",
			title = LR["Delete visual profile"],
			text = LR["Delete visual profile"].." '"..profileKey.."'?",
			buttons = {
				{
					text = ACCEPT,
					func = function()
						VMRT.Reminder.VisualProfiles[profileKey] = nil
						if VMRT.Reminder.ForceVisualProfile == profileKey then
							VMRT.Reminder.ForcedVisualProfile = "Default"
						end
						for charKey,profileK in next, VMRT.Reminder.VisualProfileKeys do
							if profileK == profileKey then
								VMRT.Reminder.VisualProfileKeys[charKey] = nil
							end
						end
						module:LoadVisualProfile()
						options.VisualProfileDropDown:SetText(GetCurrentVisualProfileName())
					end,
				},
				{
					text = CANCEL,
				}
			},
			alert = true,
		})
	end

	function options.VisualProfileDropDown:CopyVisualProfile(profileKey)
		ELib:DropDownClose()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_COPY_VISUAL_PROFILE",
			title = LR["Copy visual profile"],
			text = LR["Copy into current profile from"].." '"..profileKey.."'?",
			buttons = {
				{
					text = ACCEPT,
					func = function()
						if VMRT.Reminder.VisualProfiles[profileKey] then
							local copiedData = CopyTable(VMRT.Reminder.VisualProfiles[profileKey])
							VMRT.Reminder.VisualSettings = copiedData.VisualSettings
							module:LoadVisualProfile()
							options:Update()
						end
					end,
				},
				{
					text = CANCEL,
				}
			},
			alert = true,
		})
	end

	options.ForcedVisualProfileCheck = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR["Use for all characters"],VMRT.Reminder.ForcedVisualProfile):Point("LEFT",options.VisualProfileDropDown,"RIGHT",5,0):OnClick(function(self)
		if self:GetChecked() then
			VMRT.Reminder.ForcedVisualProfile = VMRT.Reminder.VisualProfile
		else
			VMRT.Reminder.ForcedVisualProfile = false
		end
		module:LoadVisualProfile()
		options.VisualProfileDropDown:SetText(GetCurrentVisualProfileName())
	end)


	---------------------------------------

	options.forceLocale = ELib:DropDown(options.options_tab.GENERAL_SETTINGS,150,-1):Point(450,-150):Size(220):SetText(VMRT.Reminder.ForceLocale or "-"):AddText("|cffffce00Force locale:"):Shown(MRT.locale ~= "ruRU" and MRT.locale ~= "koKR")
	do
		local function forceLocale_SetValue(_,arg)
			local old = VMRT.Reminder.ForceLocale
			VMRT.Reminder.ForceLocale = arg
			options.forceLocale:SetText(arg or "-")
			ELib:DropDownClose()
			if old ~= arg then
				MLib:DialogPopup({
					id = "EXRT_FORCE_LOCALE_RELOAD_UI",
					title = LR["Reload UI"],
					text = LR["Reload UI to apply changes"],
					buttons = {
						{
							text = ACCEPT,
							func = ReloadUI,
						},
						{
							text = CANCEL,
							func = function()
								VMRT.Reminder.ForceLocale = old
								options.forceLocale:SetText(old or "-")
							end
						}
					},
				})
			end
		end
		local List = options.forceLocale.List
		List[1] = {text = "-", func = forceLocale_SetValue, arg1 = nil}
		for i,locale in ipairs({"ru","kr"}) do
			List[#List+1] = {
				text = locale,
				arg1 = locale,
				func = forceLocale_SetValue,
			}
		end
	end

	options.alternativeColorScheme = ELib:Check(options.options_tab.GENERAL_SETTINGS,LR["Alternative color scheme for reminders list"], VMRT.Reminder.alternativeColorScheme):Point(10,-275):OnClick(function(self)
		VMRT.Reminder.alternativeColorScheme = self:GetChecked()
		options.scrollList:Update(true)
	end)

	options.optionWidgets = MLib:Tabs2(options.options_tab.GENERAL_SETTINGS,0,LR["Text"], LR["Bars"], LR["Text To Speech"], LR["Raid Frame Glow"], LR["Nameplate Glow"]):Point(0,-325):Point("LEFT",options.options_tab.GENERAL_SETTINGS):Size(698,200):SetTo(1)
	options.optionWidgets.TEXT_TAB = options.optionWidgets.tabs[1]
	options.optionWidgets.BARS_TAB = options.optionWidgets.tabs[2]
	options.optionWidgets.TTS_TAB = options.optionWidgets.tabs[3]
	options.optionWidgets.RAID_FRAME_GLOW_TAB = options.optionWidgets.tabs[4]
	options.optionWidgets.NAMEPLATE_GLOW_TAB = options.optionWidgets.tabs[5]

	options.optionWidgets:SetBackdropBorderColor(0,0,0,0)
	options.optionWidgets:SetBackdropColor(0,0,0,0)
	ELib:DecorationLine(options.optionWidgets,true,"BACKGROUND",1):Point("TOP",0,20):Point("LEFT",-1,0):Point("RIGHT",62,0):Size(0,20):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	options.dropDownFont = ELib:DropDown(options.optionWidgets.TEXT_TAB,250,10):Size(280):Point(200,-15):AddText("|cffffce00"..LR.Font)
	do
		function options.dropDownFont.SetValue(_,arg)
			VisualSettings.Text_Font = arg
			options.dropDownFont:Update()
			ELib:DropDownClose()
			module:UpdateVisual()
		end

		for i=1,#MRT.F.fontList do
			options.dropDownFont.List[i] = {
				text = MRT.F.fontList[i]:match("\\([^\\]*)$"):gsub("%....$", ""),
				arg1 = MRT.F.fontList[i],
				func = options.dropDownFont.SetValue,
				font = MRT.F.fontList[i],
			}
		end
		for name,font in MRT.F.IterateMediaData("font") do
			options.dropDownFont.List[#options.dropDownFont.List+1] = {
				text = name,
				arg1 = font,
				func = options.dropDownFont.SetValue,
				font = font,
			}
		end

		function options.dropDownFont:Update() -- finally adopt shared media??? atleast for font names
			local arg = VisualSettings.Text_Font or MRT.F.defFont
			-- matches file name and file extension
			local fileName = GetMediaName("font", arg) or arg:match("\\([^\\]*)$")
			-- remove file extension if it containts 3 characters
			local formattedFontName = fileName and fileName:gsub("%....$", "") or arg
			self:SetText(formattedFontName)
		end
	end


	options.chkShadow = ELib:Check(options.optionWidgets.TEXT_TAB,LR.OutlineChk,VisualSettings.Text_FontShadow):Point("LEFT",options.dropDownFont,"RIGHT",5,0):OnClick(function(self)
		VisualSettings.Text_FontShadow = self:GetChecked()
		module:UpdateVisual()
	end)
	function options.chkShadow:Update()
		self:SetChecked(VisualSettings.Text_FontShadow)
	end

	local font_flags = {
		{ "",                         LR.OutlinesNone },
		{ "OUTLINE",                  LR.OutlinesNormal },
		{ "THICKOUTLINE",             LR.OutlinesThick },
		{ "MONOCHROME",               LR.OutlinesMono },
		{ "MONOCHROME, OUTLINE",      LR.OutlinesMonoNormal },
		{ "MONOCHROME, THICKOUTLINE", LR.OutlinesMonoThick },
	}

	options.dropDownFontFlags = ELib:DropDown(options.optionWidgets.TEXT_TAB,250,6):Size(280):Point(200,-40):AddText("|cffffce00"..LR.Outline)

	do
		function options.dropDownFontFlags.SetValue(_,flag)
			VisualSettings.Text_FontOutlineType = flag
			ELib:DropDownClose()
			module:UpdateVisual()
			options.dropDownFontFlags:Update()
		end

		local List = options.dropDownFontFlags.List
		for i=1,#font_flags do
			List[#List+1] = {
				text = font_flags[i][2],
				arg1 = font_flags[i][1],
				func = options.dropDownFontFlags.SetValue,
			}
		end

		function options.dropDownFontFlags:Update()
			for i=1,#font_flags do
				if font_flags[i][1] == VisualSettings.Text_FontOutlineType then
					self:SetText(font_flags[i][2])
					break
				end
			end
		end
	end


	local frameStrataList = {"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG","TOOLTIP"}

	options.dropDownFontFrameStrata = ELib:DropDown(options.optionWidgets.TEXT_TAB,250,#frameStrataList+1):Point(200,-65):Size(280):AddText("|cffffce00"..LR.Strata)

	do
		function options.dropDownFontFrameStrata.SetVaule(_,arg)
			VisualSettings.Text_FrameStrata = arg
			options.dropDownFontFrameStrata:Update()
			ELib:DropDownClose()
			for i=1,#options.dropDownFontFrameStrata.List do
				options.dropDownFontFrameStrata.List[i].checkState = VisualSettings.Text_FrameStrata == options.dropDownFontFrameStrata.List[i].arg1
			end
			module:UpdateVisual()
		end

		for i=1,#frameStrataList do
			options.dropDownFontFrameStrata.List[i] = {
				text = frameStrataList[i],
				checkState = VisualSettings.Text_FrameStrata == frameStrataList[i],
				radio = true,
				arg1 = frameStrataList[i],
				func = options.dropDownFontFrameStrata.SetVaule,
			}
		end

		function options.dropDownFontFrameStrata:Update()
			self:SetText(VisualSettings.Text_FrameStrata)
		end
	end

	local justifyHList = {
		{ "CENTER", L.cd2ColSetFontPosCenter, 0 },
		{ "LEFT",   L.cd2ColSetFontPosLeft, 1 },
		{ "RIGHT",  L.cd2ColSetFontPosRight, 2 },
	}

	options.dropDownFontAdj = ELib:DropDown(options.optionWidgets.TEXT_TAB,350,-1):Size(280):Point("TOPLEFT",options.dropDownFontFrameStrata,"BOTTOMLEFT",0,-5):AddText("|cffffce00"..LR.Justify)

	do
		function options.dropDownFontAdj.SetValue(_,arg1)
			ELib:DropDownClose()
			VisualSettings.Text_JustifyH = arg1
			options.dropDownFontAdj:Update()
			module:UpdateVisual()
		end

		for i=1,#justifyHList do
			options.dropDownFontAdj.List[i] = {
				text = justifyHList[i][2],
				func = options.dropDownFontAdj.SetValue,
				arg1 = justifyHList[i][3],
				justifyH = justifyHList[i][1],
				radio = true,
			}
		end

		function options.dropDownFontAdj:Update()
			for i=1,#self.List do
				if self.List[i].arg1 == VisualSettings.Text_JustifyH then
					self:SetText(self.List[i].text)
					self.List[i].checkState = true
				else
					self.List[i].checkState = false
				end
			end

		end
	end


	options.optTimerExcluded = ELib:Check(options.optionWidgets.TEXT_TAB,LR.TimerExcluded,VisualSettings.Text_FontTimerExcluded):Tooltip(LR.TimerExcludedTip):Point("LEFT",options.dropDownFontAdj,"RIGHT",5,0):OnClick(function(self)
		VisualSettings.Text_FontTimerExcluded = self:GetChecked()
		module:UpdateVisual()
	end)
	function options.optTimerExcluded:Update()
		self:SetChecked(VisualSettings.Text_FontTimerExcluded)
	end

	options.sliderFontSizeBig = ELib:Slider(options.optionWidgets.TEXT_TAB,LR["Big Font Size"]):Size(280):Point(200,-125):Range(12,120):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.Text_FontSizeBig = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	function options.sliderFontSizeBig:Update()
		self:SetValue(VisualSettings.Text_FontSizeBig)
	end

	options.sliderFontSize = ELib:Slider(options.optionWidgets.TEXT_TAB,LR["Normal Font Size"]):Size(280):Point(200,-150):Range(12,120):SetTo(VisualSettings.Text_FontSize):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.Text_FontSize = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	function options.sliderFontSize:Update()
		self:SetValue(VisualSettings.Text_FontSize)
	end

	options.sliderFontSizeSmall = ELib:Slider(options.optionWidgets.TEXT_TAB,LR["Small Font Size"]):Size(280):Point(200,-175):Range(12,120):SetTo(VisualSettings.Text_FontSizeSmall):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.Text_FontSizeSmall = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	function options.sliderFontSizeSmall:Update()
		self:SetValue(VisualSettings.Text_FontSizeSmall)
	end

	options.CenterXButton = MLib:Button(options.optionWidgets.TEXT_TAB,LR.CenterByX,13):Point(200,-200):Size(139,20):Tooltip(LR.CenterXTip):OnClick(function()
		VisualSettings.Text_PosX = 0
		module:UpdateVisual()
	end)

	options.CenterYButton = MLib:Button(options.optionWidgets.TEXT_TAB,LR.CenterByY,13):Point("LEFT",options.CenterXButton,"RIGHT",3,0):Size(139,20):Tooltip(LR.CenterYTip):OnClick(function()
		VisualSettings.Text_PosY = 0
		module:UpdateVisual()
	end)


	----------------------------------------------------------------

	options.ttsVoiceDropDown = ELib:DropDown(options.optionWidgets.TTS_TAB,300,-1):Point(200,-15):Size(280):AddText("|cffffce00"..LR["Default TTS Voice"])
	do
		function options.ttsVoiceDropDown.SetValue(_,arg1)
			VisualSettings.TTS_Voice = arg1
			options.ttsVoiceDropDown:Update()
			ELib:DropDownClose()

			module:UpdateTTSTransliterateStatus()
			-- module:PlayTTS("This is an example of text to speech")
		end

		function options.ttsVoiceDropDown:PreUpdate()
			local List = self.List
			wipe(List)
			local voices = C_VoiceChat.GetTtsVoices()
			for i=1,#voices do
				List[#List+1] = {
					text = voices[i].name or ("id "..i),
					arg1 = voices[i].voiceID,
					func = self.SetValue,
				}
			end
		end

		function options.ttsVoiceDropDown:Update()
			local voices = C_VoiceChat.GetTtsVoices()
			local voiceID = VisualSettings.TTS_Voice or TextToSpeech_GetSelectedVoice(Enum.TtsVoiceType.Standard).voiceID
			for i=1,#voices do
				if voices[i].voiceID == voiceID then
					self:SetText(voices[i].name)
					return
				end
			end
			self:SetText("Voice ID: "..(voiceID or "unk"))
		end
	end

	options.ttsVoiceTestButton = MLib:Button(options.optionWidgets.TTS_TAB,"TTS TEST",13):Size(80,20):FontSize(12):Point("LEFT",options.ttsVoiceDropDown,"RIGHT",5,0):OnClick(function()
		C_VoiceChat.StopSpeakingText()
		C_Timer.After(0.1,function()
			module:PlayTTS("This is an example of text to speech")
		end)
	end)

	local altTTSSpeechExample = MRT.locale == "koKR" and "이것은 텍스트 음성 변환의 예입니다" or "Это пример работы функции текств в речь"
	options.altTTSVoiceDropDown = ELib:DropDown(options.optionWidgets.TTS_TAB,300,-1):Point(200,-40):Size(280):AddText("|cffffce00"..LR["Alternative TTS Voice"])
	do
		function options.altTTSVoiceDropDown.SetValue(_,arg1)
			VisualSettings.TTS_VoiceAlt = arg1
			options.altTTSVoiceDropDown:Update()
			ELib:DropDownClose()

			module:UpdateTTSTransliterateStatus()
			-- module:PlayTTS(altTTSSpeechExample)
		end

		function options.altTTSVoiceDropDown:PreUpdate()
			local List = self.List
			wipe(List)
			local voices = C_VoiceChat.GetTtsVoices()
			for i=1,#voices do
				List[#List+1] = {
					text = voices[i].name or ("id "..i),
					arg1 = voices[i].voiceID,
					func = self.SetValue,
				}
			end
			List[#List+1] = {
				text = LR["Use default TTS Voice"],
				func = self.SetValue,
			}
		end

		function options.altTTSVoiceDropDown:Update()
			local voiceID = VisualSettings.TTS_VoiceAlt
			if not voiceID then
				self:SetText(LR["Use default TTS Voice"])
				return
			end

			local voices = C_VoiceChat.GetTtsVoices()
			for i=1,#voices do
				if voices[i].voiceID == voiceID then
					self:SetText(voices[i].name)
					return
				end
			end
			self:SetText("Voice ID: "..(voiceID or "unk"))
		end
	end

	options.altTTSVoiceTestButton = MLib:Button(options.altTTSVoiceDropDown,"TTS TEST",13):Size(80,20):FontSize(12):Point("LEFT",options.altTTSVoiceDropDown,"RIGHT",5,0):OnClick(function()
		C_VoiceChat.StopSpeakingText()
		C_Timer.After(0.1,function()
			module:PlayTTS(altTTSSpeechExample)
		end)
	end)

	options.ttsVolumeSlider = ELib:Slider(options.optionWidgets.TTS_TAB,LR["TTS Volume"]):Size(280):Point(200,-85):Range(1,100):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.TTS_VoiceVolume = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	function options.ttsVolumeSlider:Update()
		self:SetValue(VisualSettings.TTS_VoiceVolume or 75)
	end

	options.ttsRateSlider = ELib:Slider(options.optionWidgets.TTS_TAB,LR["TTS Rate"]):Size(280):Point(200,-110):Range(-10,10):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.TTS_VoiceRate = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	function options.ttsRateSlider:Update()
		self:SetValue(VisualSettings.TTS_VoiceRate or 0)
	end

	options.ttsIgnoreFiles = ELib:Check(options.optionWidgets.TTS_TAB,LR["Use TTS files if possible"], not VisualSettings.TTS_IgnoreFiles):Tooltip(
[[|cffffffffWill first try to play sound file from Interface/TTS/
If can't then will try to play sound file from ExRT_Reminder/Media/Sounds/TTS/
If can't then will use ingame tts

For e.g. `freedom` will try to play
|cff80ff00Interface/TTS/freedom.mp3|r ->
|cff80ff00Interface/TTS/freedom.ogg|r ->
|cff80ff00ExRT_Reminder/Media/Sounds/TTS/freedom.mp3|r ->
|cff80ff00ExRT_Reminder/Media/Sounds/TTS/freedom.ogg|r ->
|cff80ff00Ingame TTS|r

Only .mp3 and .ogg files are supported
File names are case insensitive but extra spaces may ruin the file name match]]
	):Point(200,-140):OnClick(function(self)
		VisualSettings.TTS_IgnoreFiles = not self:GetChecked()
	end)
	function options.ttsIgnoreFiles:Update()
		self:SetChecked(not VisualSettings.TTS_IgnoreFiles)
	end


	do
		options.glowFrameColor = ELib:Edit(options.optionWidgets.RAID_FRAME_GLOW_TAB):Size(100,20):Point(200,-40):Run(function(s)
			s:Disable()
			s:SetTextColor(.35,.35,.35)
			s:SetScript("OnMouseDown",function()
				s:Enable()
			end)
		end):OnChange(function(self,isUser)
			if not isUser then
				return
			end
			local text = self:GetText()
			if text == "" then
				GlowSettings.Color = "ffff0000"
				options.glowFrameColor.preview:Update()
			elseif text:find("^%x%x%x%x%x%x%x%x$") then
				GlowSettings.Color = text
				options.glowFrameColor.preview:Update()
				self:Disable()
			end
		end)
		function options.glowFrameColor:Update()
			self:SetText(GlowSettings.Color or "")
			self:GetScript("OnTextChanged")(self,true)
		end

		options.glowFrameColor.preview = ELib:Texture(options.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
		options.glowFrameColor.preview.Update = function(self)
			local t = self:GetParent():GetText()
			local at,rt,gt,bt = t:match("(..)(..)(..)(..)")
			if not bt then
				at,rt,gt,bt = GlowSettings.Color:match("(..)(..)(..)(..)")
			end
			if bt then
				local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
				self:SetColorTexture(r/255,g/255,b/255,a/255)
			end
		end
		local checkers = ELib:Texture(options.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
		options.glowFrameColor.preview.checkers = checkers
		checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
		checkers:SetTexCoord(.25, 0, .5, .25)
		checkers:SetDesaturated(true)
		checkers:SetVertexColor(1, 1, 1, 0.75)
		checkers:SetDrawLayer("BORDER", -7)
		checkers:Show()

		options.glowFrameColor.colorButton = CreateFrame("Button",nil,options.glowFrameColor)
		options.glowFrameColor.colorButton:SetPoint("LEFT", options.glowFrameColor.preview, "RIGHT", 5, 0)
		options.glowFrameColor.colorButton:SetSize(24,24)
		options.glowFrameColor.colorButton:SetScript("OnClick",function()
			local prevValue = GlowSettings.Color

			local colorPalette = GlowSettings.Color or "ffff0000"
			local at,rt,gt,bt = colorPalette:match("(..)(..)(..)(..)")

			local r,g,b,a
			if bt then
				r,g,b,a = tonumber(rt,16)/255,tonumber(gt,16)/255,tonumber(bt,16)/255,tonumber(at,16)/255
			end

			r,g,b,a = r or 1, g or 1, b or 1, a or 1

			if ColorPickerFrame.SetupColorPickerAndShow then
				local info = {
					r = r,
					g = g,
					b = b,
					opacity =  COLORPICKER_INVERTED_ALPHA and 1 - a or a,
					hasOpacity = true,
					swatchFunc = function()
						local newR, newG, newB = ColorPickerFrame:GetColorRGB()
						local newA = ColorPickerFrame:GetColorAlpha()
						newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

						GlowSettings.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

						options.glowFrameColor:SetText(GlowSettings.Color or "")
						options.glowFrameColor:Disable()
						options.glowFrameColor.preview:Update()
					end,
					opacityFunc = function()
						local newR, newG, newB = ColorPickerFrame:GetColorRGB()
						local newA = ColorPickerFrame:GetColorAlpha()
						newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

						GlowSettings.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

						options.glowFrameColor:SetText(GlowSettings.Color or "")
						options.glowFrameColor:Disable()
						options.glowFrameColor.preview:Update()
					end,
					cancelFunc = function()
						GlowSettings.Color = prevValue

						options.glowFrameColor:SetText(GlowSettings.Color or "")
						options.glowFrameColor:Disable()
						options.glowFrameColor.preview:Update()
					end,
				}

				ColorPickerFrame:SetupColorPickerAndShow(info)
			else
				ColorPickerFrame:SetColorRGB(r, g, b)
				ColorPickerFrame.hasOpacity = true
				ColorPickerFrame.opacity = a

				ColorPickerFrame.func = function()
					local newR, newG, newB = ColorPickerFrame:GetColorRGB()
					local newA = OpacitySliderFrame:GetValue()
					newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

					GlowSettings.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					options.glowFrameColor:SetText(GlowSettings.Color or "")
					options.glowFrameColor:Disable()
					options.glowFrameColor.preview:Update()
				end

				ColorPickerFrame.opacityFunc = function()
					local newR, newG, newB = ColorPickerFrame:GetColorRGB()
					local newA = OpacitySliderFrame:GetValue()
					newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

					GlowSettings.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					options.glowFrameColor:SetText(GlowSettings.Color or "")
					options.glowFrameColor:Disable()
					options.glowFrameColor.preview:Update()
				end

				ColorPickerFrame.cancelFunc = function()
					GlowSettings.Color = prevValue

					options.glowFrameColor:SetText(GlowSettings.Color or "")
					options.glowFrameColor:Disable()
					options.glowFrameColor.preview:Update()
				end

				ColorPickerFrame:Show()
			end
		end)
		options.glowFrameColor.colorButton:SetScript("OnEnter",function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(L.ReminderSelectColor)
			GameTooltip:Show()
		end)
		options.glowFrameColor.colorButton:SetScript("OnLeave",function(self)
			GameTooltip_Hide()
		end)
		options.glowFrameColor.colorButton.Texture = options.glowFrameColor.colorButton:CreateTexture(nil,"ARTWORK")
		options.glowFrameColor.colorButton.Texture:SetPoint("CENTER")
		options.glowFrameColor.colorButton.Texture:SetSize(20,20)
		options.glowFrameColor.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])
		options.glowFrameColor.leftText = ELib:Text(options.glowFrameColor,COLOR..":",13):Point("RIGHT",options.glowFrameColor,"LEFT",-5,0):Right():Middle():Shadow()


		options.glowFrameColor:SetText(GlowSettings.Color)
		options.glowFrameColor.preview:Update()

		-------------------------------------------------------------------
		-------------------------PIXEL GLOW--------------------------------
		-------------------------------------------------------------------

		options.pixelGlowFrequencySlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Frequency"):Size(120):Point(200,-85):Range(-20,20):SetTo(GlowSettings.PixelGlow.frequency):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		options.pixelGlowFrequencySlider.High:SetText("5")
		options.pixelGlowFrequencySlider.Low:SetText("-5")
		function options.pixelGlowFrequencySlider:Update()
			self:SetTo(GlowSettings.PixelGlow.frequency*4)
		end

		options.pixelGlowCountSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Count"):Size(120):Point(330,-85):Range(1,20):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.pixelGlowCountSlider:Update()
			self:SetTo(GlowSettings.PixelGlow.count)
		end

		options.pixelGlowLengthSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Length"):Size(120):Point(460,-85):Range(1,50):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.length = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.pixelGlowLengthSlider:Update()
			self:SetTo(GlowSettings.PixelGlow.length)
		end

		options.pixelGlowThicknessSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Thickness"):Size(120):Point(590,-85):Range(1,6):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.thickness = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.pixelGlowThicknessSlider:Update()
			self:SetTo(GlowSettings.PixelGlow.thickness)
		end

		options.pixelGlowXOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"x Offset"):Size(120):Point(200,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.pixelGlowXOffsetSlider:Update()
			self:SetTo(GlowSettings.PixelGlow.xOffset)
		end

		options.pixelGlowYOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"y Offset"):Size(120):Point(330,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.PixelGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.pixelGlowYOffsetSlider:Update()
			self:SetTo(GlowSettings.PixelGlow.yOffset)
		end

		options.chkPixelGlowBorder = ELib:Check(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Border", GlowSettings.PixelGlow.border):Point(460,-115):OnClick(function(self)
			GlowSettings.PixelGlow.border = self:GetChecked()
		end)
		function options.chkPixelGlowBorder:Update()
			self:SetChecked(GlowSettings.PixelGlow.border)
		end

		-------------------------------------------------------------------
		-------------------------AUTO CAST GLOW----------------------------
		-------------------------------------------------------------------

		options.autoCastFrequencySlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Frequency"):Size(120):Point(200,-85):Range(-20,20):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.AutoCastGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		options.autoCastFrequencySlider.High:SetText("5")
		options.autoCastFrequencySlider.Low:SetText("-5")
		function options.autoCastFrequencySlider:Update()
			self:SetTo(GlowSettings.AutoCastGlow.frequency*4)
		end

		options.autoCastCountSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Count"):Size(120):Point(330,-85):Range(1,20):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.AutoCastGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.autoCastCountSlider:Update()
			self:SetTo(GlowSettings.AutoCastGlow.count)
		end

		options.autoCastScaleSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Scale"):Size(120):Point(460,-85):Range(4,20):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.AutoCastGlow.scale = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		options.autoCastScaleSlider.High:SetText("5")
		options.autoCastScaleSlider.Low:SetText("1")
		options.autoCastScaleSlider.tooltipText = GlowSettings.AutoCastGlow.scale*4

		function options.autoCastScaleSlider:Update()
			self:SetTo(GlowSettings.AutoCastGlow.scale*4)
		end

		options.autoCastXOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"x Offset"):Size(120):Point(200,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.AutoCastGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.autoCastXOffsetSlider:Update()
			self:SetTo(GlowSettings.AutoCastGlow.xOffset)
		end

		options.autoCastYOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"y Offset"):Size(120):Point(330,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.AutoCastGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)
		function options.autoCastYOffsetSlider:Update()
			self:SetTo(GlowSettings.AutoCastGlow.yOffset)
		end

		-------------------------------------------------------------------
		-------------------------PROC GLOW---------------------------------
		-------------------------------------------------------------------

		options.procGlowDurationSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Animation duration"):Size(120):Point(200,-85):Range(0,20):OnChange(function(self,event)
			event = event
			GlowSettings.ProcGlow.duration = event/8
			self.tooltipText = event/8
			self:tooltipReload(self)
		end)
		options.procGlowDurationSlider.High:SetText("2.5")
		options.procGlowDurationSlider.Low:SetText("0")
		options.procGlowDurationSlider.tooltipText = GlowSettings.ProcGlow.duration
		-- options.procGlowDurationSlider.tooltipReload(self.procGlowDurationSlider)

		function options.procGlowDurationSlider:Update()
			self:SetTo(GlowSettings.ProcGlow.duration*8)
		end

		options.procGlowXOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"x Offset"):Size(120):Point(200,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.ProcGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		function options.procGlowXOffsetSlider:Update()
			self:SetTo(GlowSettings.ProcGlow.xOffset)
		end

		options.proclGlowYOffsetSlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"y Offset"):Size(120):Point(330,-115):Range(-15,15):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.ProcGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		function options.proclGlowYOffsetSlider:Update()
			self:SetTo(GlowSettings.ProcGlow.yOffset)
		end

		options.chkProcGlowStartAnim = ELib:Check(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Start Animation", GlowSettings.ProcGlow.startAnim):Point(460,-115):OnClick(function(self)
			GlowSettings.ProcGlow.startAnim = self:GetChecked()
		end)

		function options.chkProcGlowStartAnim:Update()
			self:SetChecked(GlowSettings.ProcGlow.startAnim)
		end

		-------------------------------------------------------------------
		-------------------------ACTION BUTTON GLOW------------------------
		-------------------------------------------------------------------

		options.actionButtonFrequencySlider = ELib:Slider(options.optionWidgets.RAID_FRAME_GLOW_TAB,"Glow Frequency"):Size(120):Point(200,-85):Range(-20,20):OnChange(function(self,event)
			event = floor(event + .5)
			GlowSettings.ActionButtonGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		options.actionButtonFrequencySlider.High:SetText("5")
		options.actionButtonFrequencySlider.Low:SetText("-5")

		function options.actionButtonFrequencySlider:Update()
			self:SetTo(GlowSettings.ActionButtonGlow.frequency*4)
		end
		------------------------------------------------------------------
		function options:SetGlowButtons()
			local type = GlowSettings.type

			options.pixelGlowCountSlider:Hide()
			options.pixelGlowFrequencySlider:Hide()
			options.pixelGlowLengthSlider:Hide()
			options.pixelGlowThicknessSlider:Hide()
			options.pixelGlowXOffsetSlider:Hide()
			options.pixelGlowYOffsetSlider:Hide()
			options.chkPixelGlowBorder:Hide()

			options.autoCastCountSlider:Hide()
			options.autoCastFrequencySlider:Hide()
			options.autoCastScaleSlider:Hide()
			options.autoCastXOffsetSlider:Hide()
			options.autoCastYOffsetSlider:Hide()

			options.procGlowDurationSlider:Hide()
			options.procGlowXOffsetSlider:Hide()
			options.proclGlowYOffsetSlider:Hide()
			options.chkProcGlowStartAnim:Hide()

			options.actionButtonFrequencySlider:Hide()

			if type == "Pixel Glow" then
				options.pixelGlowCountSlider:Show()
				options.pixelGlowFrequencySlider:Show()
				options.pixelGlowLengthSlider:Show()
				options.pixelGlowThicknessSlider:Show()
				options.pixelGlowXOffsetSlider:Show()
				options.pixelGlowYOffsetSlider:Show()
				options.chkPixelGlowBorder:Show()
			elseif type == "Autocast Shine" then
				options.autoCastCountSlider:Show()
				options.autoCastFrequencySlider:Show()
				options.autoCastScaleSlider:Show()
				options.autoCastXOffsetSlider:Show()
				options.autoCastYOffsetSlider:Show()
			elseif type == "Proc Glow" then
				options.procGlowDurationSlider:Show()
				options.procGlowXOffsetSlider:Show()
				options.proclGlowYOffsetSlider:Show()
				options.chkProcGlowStartAnim:Show()
			else
				options.actionButtonFrequencySlider:Show()
			end
		end
		options:SetGlowButtons()
		options.glowDropDown = ELib:DropDown(options.optionWidgets.RAID_FRAME_GLOW_TAB,275,#glowList+1):Point(200,-15):Size(280):SetText(LR[GlowSettings.type]):AddText("|cffffce00Glow Type")

		do
			function options.glowDropDown.SetVaule(_,arg)
				GlowSettings.type = arg
				options.glowDropDown:Update()
				options:SetGlowButtons()
				ELib:DropDownClose()
			end

			for i=1,#glowList do
				options.glowDropDown.List[i] = {
					text = LR[glowList[i]],
					arg1 = glowList[i],
					func = options.glowDropDown.SetVaule,
				}
			end
			tinsert(options.glowDropDown.List,{
				text = L.minimapmenuclose,
				func = function()
					ELib:DropDownClose()
				end
			})
			function options.glowDropDown:Update()
				self:SetText(LR[GlowSettings.type])
				for i=1,#self.List-1 do
					self.List[i].checkState = GlowSettings.type == self.List[i].arg1
				end
			end
		end


		options.glowTestButton = MLib:Button(options.optionWidgets.RAID_FRAME_GLOW_TAB,"GLOW TEST",13):Size(80,20):FontSize(12):Point("LEFT",options.glowDropDown,"RIGHT",5, 0):Tooltip("Only in raid group\nGlows player frame in raid groups for 5 sec"):OnClick(function()
			local data = {
				glow = UnitNameUnmodified("player"),
				duration = 5,
				token = 0
			}
			local params = {
				_reminder = {
					data = data
				},
				_data = data
			}
			params._reminder.params = params
			module:ParseGlow(data,params)
		end)
	end
	--end of raidframe glow settings
	----------------------------------------------------------------

	options.NamePlateGlowTypeDropDown = ELib:DropDown(options.optionWidgets.NAMEPLATE_GLOW_TAB,275,4):Point(200,-15):Size(280):AddText("|cffffce00Default Nameplate\nGlow Type")
	do
		function options.NamePlateGlowTypeDropDown.SetVaule(_,arg)
			VisualSettings.NameplateGlow_DefaultType = arg
			ELib:DropDownClose()
			options.NamePlateGlowTypeDropDown:Update()
		end

		local List = options.NamePlateGlowTypeDropDown.List
		for i=2,5 do
			List[#List+1] = {
				text = module.datas.glowTypes[i][2],
				arg1 = module.datas.glowTypes[i][1],
				func = options.NamePlateGlowTypeDropDown.SetVaule,
			}
		end

		function options.NamePlateGlowTypeDropDown:Update()
			for i=1,#module.datas.glowTypes do
				if module.datas.glowTypes[i][1] == VisualSettings.NameplateGlow_DefaultType then
					options.NamePlateGlowTypeDropDown:SetText(module.datas.glowTypes[i][2])
					break
				end
			end
		end
	end

	-- bars options
	options.sliderBarWidth = ELib:Slider(options.optionWidgets.BARS_TAB,""):Size(280):Point(200,-15):Range(50,1000):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.Bar_Width = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(options.optionWidgets.BARS_TAB,LR.barWidth,11):Point("RIGHT",options.sliderBarWidth,"LEFT",-5,0):Color(1,.82,0,1):Right()

	function options.sliderBarWidth:Update()
		self:SetTo(VisualSettings.Bar_Width or 300)
	end

	options.sliderBarHeight = ELib:Slider(options.optionWidgets.BARS_TAB,""):Size(280):Point("TOPLEFT",options.sliderBarWidth,"BOTTOMLEFT",0,-15):Range(16,96):OnChange(function(self,event)
		event = floor(event + .5)
		VisualSettings.Bar_Height = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(options.optionWidgets.BARS_TAB,LR.barHeight,11):Point("RIGHT",options.sliderBarHeight,"LEFT",-5,0):Color(1,.82,0,1):Right()

	function options.sliderBarHeight:Update()
		self:SetTo(VisualSettings.Bar_Height or 30)
	end

	options.dropDownBarTexture = ELib:DropDown(options.optionWidgets.BARS_TAB,350,10):Size(280):Point("TOPLEFT",options.sliderBarHeight,"BOTTOMLEFT",0,-15):AddText("|cffffce00"..LR.barTexture)

	do
		function options.dropDownBarTexture.SetValue(_,arg1)
			ELib:DropDownClose()
			VisualSettings.Bar_Texture = arg1
			options.dropDownBarTexture:Update()
			module:UpdateVisual()
		end

		options.dropDownBarTexture.List[1] = {
			text = "default",
			func = options.dropDownBarTexture.SetValue,
			justifyH = "CENTER" ,
			texture = [[Interface\AddOns\MRT\media\bar34.tga]],
		}
		for i=1,#MRT.F.textureList do
			local info = {}
			options.dropDownBarTexture.List[#options.dropDownBarTexture.List+1] = info
			info.text = MRT.F.textureList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
			info.arg1 = MRT.F.textureList[i]
			info.func = options.dropDownBarTexture.SetValue
			info.texture = MRT.F.textureList[i]
			info.justifyH = "CENTER"
		end
		for key,texture in MRT.F.IterateMediaData("statusbar") do
			local info = {}
			options.dropDownBarTexture.List[#options.dropDownBarTexture.List+1] = info

			info.text = key
			info.arg1 = texture
			info.func = options.dropDownBarTexture.SetValue
			info.texture = texture
			info.justifyH = "CENTER"
		end

		function options.dropDownBarTexture:Update()
			local arg = VisualSettings.Bar_Texture
			local text = GetMediaName("statusbar", arg) or (arg and arg:match("\\([^\\]*)$") or arg or "default"):gsub("%....$", "")
			self:SetText(text)
		end
	end

	options.dropDownBarFont = ELib:DropDown(options.optionWidgets.BARS_TAB,350,10):Size(280):Point("TOPLEFT",options.dropDownBarTexture,"BOTTOMLEFT",0,-5):Tooltip(LR.barFontTip):AddText("|cffffce00"..LR.Font)
	do
		function options.dropDownBarFont.SetValue(_,arg1)
			ELib:DropDownClose()
			VisualSettings.Bar_Font = arg1
			options.dropDownBarFont:Update()
			module:UpdateVisual()
		end

		for i=1,#MRT.F.fontList do
			local info = {}
			options.dropDownBarFont.List[i] = info
			info.text = MRT.F.fontList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
			info.arg1 = MRT.F.fontList[i]
			info.func = options.dropDownBarFont.SetValue
			info.font = MRT.F.fontList[i]
		end
		for key,font in MRT.F.IterateMediaData("font") do
			local info = {}
			options.dropDownBarFont.List[#options.dropDownBarFont.List+1] = info

			info.text = key
			info.arg1 = font
			info.func = options.dropDownBarFont.SetValue
			info.font = font
		end

		function options.dropDownBarFont:Update()
			local arg = VisualSettings.Bar_Font or MRT.F.defFont
			local fileName = GetMediaName("font", arg) or arg:match("\\([^\\]*)$")
			-- remove file extension if it containts 3 characters
			local formattedFontName = fileName and fileName:gsub("%....$", "") or arg
			self:SetText(formattedFontName)
		end
	end

	options.dropDownBarFrameStrata = ELib:DropDown(options.optionWidgets.BARS_TAB,250,#frameStrataList+1):Point("TOPLEFT",options.dropDownBarFont,"BOTTOMLEFT",0,-5):Size(280):AddText("|cffffce00"..LR.Strata)

	do
		function options.dropDownBarFrameStrata.SetVaule(_,arg)
			VisualSettings.Bar_FrameStrata = arg
			options.dropDownBarFrameStrata:Update()
			ELib:DropDownClose()
			for i=1,#options.dropDownBarFrameStrata.List do
				options.dropDownBarFrameStrata.List[i].checkState = VisualSettings.Bar_FrameStrata == options.dropDownBarFrameStrata.List[i].arg1
			end
			module:UpdateVisual()
		end

		for i=1,#frameStrataList do
			options.dropDownBarFrameStrata.List[i] = {
				text = frameStrataList[i],
				checkState = VisualSettings.Bar_FrameStrata == frameStrataList[i],
				radio = true,
				arg1 = frameStrataList[i],
				func = options.dropDownBarFrameStrata.SetVaule,
			}
		end

		function options.dropDownBarFrameStrata:Update()
			self:SetText(VisualSettings.Bar_FrameStrata)
		end
	end

	options.CenterXButtonBar = MLib:Button(options.optionWidgets.BARS_TAB,LR.CenterByX,13):Point("TOPLEFT",options.dropDownBarFrameStrata,"BOTTOMLEFT",0,-5):Size(139,20):Tooltip(LR.CenterXTip):OnClick(function()
		VisualSettings.Bar_PosX = 0
		module:UpdateVisual()
	end)

	options.CenterYButtonBar = MLib:Button(options.optionWidgets.BARS_TAB,LR.CenterByY,13):Point("LEFT",options.CenterXButtonBar,"RIGHT",3,0):Size(139,20):Tooltip(LR.CenterYTip):OnClick(function()
		VisualSettings.Bar_PosY = 0
		module:UpdateVisual()
	end)

	ELib:Text(options.options_tab.ALWAYS_PLAYERS_SETTINGS,LR.OptPlayersTooltip,11,"GameFontNormal"):Point("TOPLEFT",10,-10):Point("RIGHT",-10,0):Color()


	function options:UpdateVisualSettings()
		options.dropDownFont:Update()
		options.chkShadow:Update()
		options.dropDownFontFlags:Update()
		options.dropDownFontFrameStrata:Update()
		options.dropDownFontAdj:Update()
		options.optTimerExcluded:Update()
		options.sliderFontSizeBig:Update()
		options.sliderFontSize:Update()
		options.sliderFontSizeSmall:Update()

		options.ttsVoiceDropDown:Update()
		options.altTTSVoiceDropDown:Update()
		options.ttsVolumeSlider:Update()
		options.ttsRateSlider:Update()
		options.ttsIgnoreFiles:Update()


		options.glowFrameColor:Update()

		options.pixelGlowFrequencySlider:Update()
		options.pixelGlowCountSlider:Update()
		options.pixelGlowLengthSlider:Update()
		options.pixelGlowThicknessSlider:Update()
		options.pixelGlowXOffsetSlider:Update()
		options.pixelGlowYOffsetSlider:Update()
		options.chkPixelGlowBorder:Update()

		options.autoCastFrequencySlider:Update()
		options.autoCastCountSlider:Update()
		options.autoCastScaleSlider:Update()
		options.autoCastXOffsetSlider:Update()
		options.autoCastYOffsetSlider:Update()

		options.procGlowDurationSlider:Update()
		options.procGlowXOffsetSlider:Update()
		options.proclGlowYOffsetSlider:Update()
		options.chkProcGlowStartAnim:Update()

		options.actionButtonFrequencySlider:Update()

		options.glowDropDown:Update()
		options:SetGlowButtons()


		options.NamePlateGlowTypeDropDown:Update()


		options.sliderBarWidth:Update()
		options.sliderBarHeight:Update()
		options.dropDownBarTexture:Update()
		options.dropDownBarFont:Update()
		options.dropDownBarFrameStrata:Update()
	end
	options:UpdateVisualSettings()


	options.updatesPlayersList = ELib:ScrollTableList(options.options_tab.ALWAYS_PLAYERS_SETTINGS,0,150,150,10):Point("TOP",0,-30):Size(678,500):OnShow(function(self)
		local L = self.L

		wipe(L)
		for player,opt in next, VMRT.Reminder.SyncPlayers do
			L[#L+1] = {player,opt == 1 and "|cff00ff00"..ALWAYS.." "..ACCEPT or "|cffff0000"..ALWAYS.." "..DECLINE,REMOVE}
		end
		sort(L,function(a,b) return a[1]<b[1] end)

		self:Update()
	end,true)

	options.updatesPlayersList.additionalLineFunctions = true
	function options.updatesPlayersList:ClickMultitableListValue(index,obj)
		if index == 3 then
			local i = obj:GetParent().index
			if i then
				VMRT.Reminder.SyncPlayers[ options.updatesPlayersList.L[i][1] ] = nil
				tremove(options.updatesPlayersList.L,i)
				options.updatesPlayersList:Update()
			end
		end
	end

	options:InitializeChangelogTab()
	options:InitializeHelpTab()
	options:InitializeVersionsTab()

	options.isWide = 760
	options.main_tab:SetTo(VMRT.Reminder.OptSavedTabNum or 1)
end
