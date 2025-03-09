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

function module.options:Load()
    local RequiredMRT = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-RequiredMRT") or "0")
    if RequiredMRT and MRT.V < RequiredMRT then
        module.prettyPrint("ExRT_Reminder requires MRT version "..RequiredMRT.." or higher to work properly. Please update MRT.")
        StaticPopupDialogs["REMINDER_MRT_VERSION_OUTDATED"] = {
            text = LR.MRTOUTDATED:format(GlobalAddonName, RequiredMRT),
            button1 = OKAY,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
            showAlert = true,
        }
        StaticPopup_Show("REMINDER_MRT_VERSION_OUTDATED")
        return
    end
    -- upvalues
    local CreateColor, CreateFrame = CreateColor, CreateFrame
    local GetTime, IsShiftKeyDown, UnitName = GetTime, IsShiftKeyDown, UnitName
    local StaticPopupDialogs, StaticPopup_Show, date, ceil, format = StaticPopupDialogs, StaticPopup_Show, date, ceil, format
    local next, tostring, tonumber = next, tostring, tonumber

    ---@class VMRT
    local VMRT = VMRT

	local LCG = LibStub("LibCustomGlow-1.0",true)
    local glowList = LCG.glowList
    local prettyPrint = module.prettyPrint
    local COLORPICKER_INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)


	self:CreateTilte()

	MLib:CreateModuleHeader(self)

	local encountersList = AddonDB.EJ_DATA.encountersList

    local frameStrataList = {"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG","TOOLTIP"}
    local font_flags = {
        { "",                         LR.OutlinesNone },
        { "OUTLINE",                  LR.OutlinesNormal },
        { "THICKOUTLINE",             LR.OutlinesThick },
        { "MONOCHROME",               LR.OutlinesMono },
        { "MONOCHROME, OUTLINE",      LR.OutlinesMonoNormal },
        { "MONOCHROME, THICKOUTLINE", LR.OutlinesMonoThick },
    }


    local function GetEncounterSortIndex(id,unk)
        for i=1,#encountersList do
            local dung = encountersList[i]
            for j=2,#dung do
                if id == dung[j] then
                    return i * 100 + (#dung - j)
                end
            end
        end
        return unk
    end
    module.GetEncounterSortIndex = GetEncounterSortIndex

    local function GetInstanceSortIndex(instanceID, unk) -- instanceID, unk
        for i=1,#encountersList do
            local dung = encountersList[i]
            if dung[1] == instanceID then
                return i * 100
            end
        end
        return unk
    end
    module.GetInstanceSortIndex = GetInstanceSortIndex

	local decorationLine = ELib:DecorationLine(self,true,"BACKGROUND",-5):Point("TOPLEFT",self,0,-25):Point("BOTTOMRIGHT",self,"TOPRIGHT",0,-45)
	decorationLine:SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	self.chkEnable = ELib:Check(self,LR.Enabled,VMRT.Reminder.enabled):Point("TOPRIGHT",self,"TOPRIGHT",-120,-26):Size(18,18):AddColorState():OnClick(function(self)
		VMRT.Reminder.enabled = self:GetChecked()
		if VMRT.Reminder.enabled then
			module:Enable()
		else
			module:Disable()
		end
	end)

    -- "Changelog", LR["Help"],
	self.tab = MLib:Tabs2(self,0,LR["Main"],LR["Settings"],"Changelog",LR.Versions):Point(0,-45):Size(698,570):SetTo(1)
    self.REMINDERS_MAIN_TAB = self.tab.tabs[1]
    self.SETTINGS_TAB = self.tab.tabs[2]
    self.CHANGELOG_TAB = self.tab.tabs[3]
    self.VERSIONS_TAB = self.tab.tabs[4]

    self.main_tab = MLib:Tabs2(self.REMINDERS_MAIN_TAB,0,LR["Reminders"],LR["Timeline"],LR["Assignments"],LR["Deleted"]):Point(0,-25):Size(698,570)
    self.REMINDERS_SCROLL_LIST = self.main_tab.tabs[1]
    self.TIMELINE_TAB = self.main_tab.tabs[2]
    self.ASSIGNMENTS_TAB = self.main_tab.tabs[3]
	self.DELETED_TAB = self.main_tab.tabs[4]

    ELib:DecorationLine(self.main_tab,true,"BACKGROUND",1):Point("TOPLEFT",self,0,-50):Point("BOTTOMRIGHT",self,"TOPRIGHT",0,-70):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

    function self.tab:buttonAdditionalFunc()
        if self.selected == 1 then
            module.options.main_tab:buttonAdditionalFunc()
        elseif module.options.isWide ~= 760 then
			module.options.isWide = 760
		    MRT.Options.Frame:SetPage(MRT.Options.Frame.CurrentFrame)
        end
	end

    function self.main_tab:buttonAdditionalFunc()
        VMRT.Reminder.OptSavedTabNum = self.selected
        if self.selected == 3 then
            module.options.isWide = VMRT.Reminder.OptAssigWidth or 1000
        elseif self.selected == 2 then
			module.options.isWide = 1000
		else
			module.options.isWide = 760
		end
		MRT.Options.Frame:SetPage(MRT.Options.Frame.CurrentFrame)

        if self.selected == 1 then
            module.options:UpdateData()
        elseif self.selected == 2 then
            if not module.options.timeLine then
                module.options:TimelineInitialize()
            end
            if module.options.timeLine.preload then
                module.options.timeLine:preload()
                module.options.timeLine.preload = nil
            end
			module.options.timeLine:Update()
        elseif self.selected == 3 then
            if not module.options.assign then
                module.options:TimelineInitialize()
            end
            if module.options.assign.preload then
                module.options.assign:preload()
                module.options.assign.preload = nil
            end
			module.options.assign:Update()
		elseif self.selected == 4 then
			if module.options.BinScrollButtonsListInitialize then
				module.options:BinScrollButtonsListInitialize()
			end
			module.options:UpdateBinData()
		end
    end

    function module.options:Update()
        if module.options:IsVisible() then
            if module.options.main_tab.selected == 1 then
                if module.options.UpdateData then
                    module.options:UpdateData()
                end
            elseif module.options.main_tab.selected == 2 then
                if module.options.timeLine and module.options.timeLine.Update then
                    module.options.timeLine:Update()
                end
            elseif module.options.main_tab.selected == 3 then
                if module.options.assign and module.options.assign.Update then
                    module.options.assign:Update()
                end
			elseif module.options.main_tab.selected == 4 then
				if module.options.UpdateBinData then
					module.options:UpdateBinData()
				end
            end
        end
    end

    function module.options:AdditionalOnShow()
        module.options:Update()
    end
    -- Note_ReceivedText
    MRT.F:RegisterCallback("Note_UpdateText", function()
        self.updTimer = self.updTimer or C_Timer.NewTimer(1, function()
            if self.updTimer then
                self.updTimer:Cancel()
            end
            self.updTimer = nil
            module.options:Update()
        end)
    end)

	self.searchEdit = ELib:Edit(self.REMINDERS_MAIN_TAB):AddSearchIcon():Size(180,18):Point("TOPLEFT",self,"TOPLEFT",480,-51):OnChange(function(self,isUser)
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
		module.options.search = text

        if self.scheduledUpdate then
			return
		end
		self.scheduledUpdate = C_Timer.NewTimer(.1,function()
			self.scheduledUpdate = nil
			module.options.scrollList.ScrollBar.slider:SetValue(0)
			if module.options.Update then
                module.options.Update()
            end
		end)
	end)
    self.searchEdit:BackgroundText(LR.search)
    self.searchEdit:SetTextColor(0,1,0,1)
	self.searchEdit:SetFrameLevel(6000)
	self.searchEdit:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
		GameTooltip:AddLine(LR.search)
		GameTooltip:AddLine(LR.searchTip,1,1,1,true)
		GameTooltip:Show()
	end)
	self.searchEdit:SetScript("OnLeave", GameTooltip_Hide)

---------------------------------------
-- Reminders List UI And Functions
---------------------------------------

    module.options:MainScrollButtonsListInitialize()

    local AddButton = MLib:Button(self.REMINDERS_SCROLL_LIST,LR.Add,13):Point("TOPLEFT",self.scrollList,"BOTTOMLEFT",4,-5):Size(100,20):OnClick(function()
        if not module.SetupFrame then
            module.options:SetupFrameInitialize()
        end

		module.SetupFrame.data = CopyTable(module.datas.newReminderTemplate)

		if module.SetupFrame:IsVisible() then
            module.SetupFrame:Update()
        else
            module.SetupFrame:Show()
        end
	end)

	self.lastUpdate = ELib:Text(self.REMINDERS_SCROLL_LIST,"",11):Point("LEFT",AddButton,"RIGHT",10,0):Color()
	function self.lastUpdate:Update()
		if VMRT.Reminder.LastUpdateName and VMRT.Reminder.LastUpdateTime then
			self:SetText( L.NoteLastUpdate..": "..VMRT.Reminder.LastUpdateName.." ("..date("%H:%M:%S %d.%m.%Y",VMRT.Reminder.LastUpdateTime)..")" )
		end
	end
	self.lastUpdate:Update()

	self.SyncButton = MLib:Button(self.REMINDERS_SCROLL_LIST,LR.SendAll,13):Point("TOPLEFT",AddButton,"BOTTOMLEFT",0,-5):Size(100,20):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_SYNC_ALL_CONFIRMATION"] = {
			text = LR.SyncAllConfirm,
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				module:Sync()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_SYNC_ALL_CONFIRMATION")

	end)

	self.ResetForAllButton = MLib:Button(self.REMINDERS_SCROLL_LIST,LR.DeleteAll,13):Point("TOPRIGHT",self.scrollList,"BOTTOMRIGHT",-5,-30):Size(120,20):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_DELETE_ALL_ALERT"] = {
			text = LR.DeleteAll.."?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
				wipe(VMRT.Reminder.data)
				if module.options.Update then
                    module.options.Update()
                end
				module:ReloadAll()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_DELETE_ALL_ALERT")

	end)

	self.ExportButton = MLib:Button(self.REMINDERS_SCROLL_LIST,LR.ExportAll,13):Point("RIGHT",self.ResetForAllButton,"LEFT",-5,0):Size(120,20):OnClick(function()
		local export = module:Sync(true)
		MRT.F:Export(export)
	end)

	local importWindow
	self.ImportButton = MLib:Button(self.REMINDERS_SCROLL_LIST,LR.Import,13):Point("RIGHT",self.ExportButton,"LEFT",-5,0):Size(80,20):OnClick(function()
		if not importWindow then
			importWindow = ELib:Popup(LR.Import):Size(650,615)
			importWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			importWindow.Edit = ELib:MultiEdit(importWindow):Point("TOP",0,-20):Size(640,570)
			importWindow.Save = MLib:Button(importWindow,LR.Import,13):Tooltip(LR.ImportTip):Point("BOTTOM",0,2):Size(120,20):OnClick(function()
				importWindow:Hide()
				if IsShiftKeyDown() then

					StaticPopupDialogs["EXRT_REMINDER_CLEAR_IMPORT_ALERT"] = {
						text = LR.ClearImport,
						button1 = ACCEPT,
						button2 = CANCEL,
						OnAccept = function()
							wipe(VMRT.Reminder.data)
							module:ProcessTextToData(importWindow.Edit:GetText(),true)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show("EXRT_REMINDER_CLEAR_IMPORT_ALERT")
				else
					module:ProcessTextToData(importWindow.Edit:GetText(),true)
				end
			end)
		end
		importWindow.Edit:SetText("")
		importWindow:NewPoint("CENTER",UIParent,0,0)
		importWindow:Show()
		importWindow.Edit.EditBox:SetScript("OnEscapePressed",function(self)
            importWindow:Hide()
        end)
		importWindow.Edit.EditBox:SetFocus()
	end)

---------------------------------------
-- Initializing LastSyncWindow. Would prefer some renaming and restiling here. Also need to refactor creating LastSync data as it seems unstable.
---------------------------------------

    local VERTICALNAME_COUNT = 30
    local LINE_NAME_WIDTH = 5
    local VERTICALNAME_WIDTH = 24
    local PAGE_HEIGHT = 24
    local TOTAL_HEIGHT = 135

	local LastSyncWindow = ELib:Template("ExRTDialogModernTemplate",UIParent)

	LastSyncWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
	LastSyncWindow:SetSize(LINE_NAME_WIDTH + (VERTICALNAME_COUNT * VERTICALNAME_WIDTH) + 10,TOTAL_HEIGHT)
	LastSyncWindow:Hide()

	LastSyncWindow:SetPoint("CENTER")
	LastSyncWindow:SetFrameStrata("DIALOG")
	LastSyncWindow:SetDontSavePosition(true)

	LastSyncWindow:SetMovable(true)
	LastSyncWindow:EnableMouse(true)

	LastSyncWindow:RegisterForDrag("LeftButton")
	LastSyncWindow:SetScript("OnDragStart", function(self)
		LastSyncWindow:StartMoving()
	end)
	LastSyncWindow:SetScript("OnDragStop", function(self)
		LastSyncWindow:StopMovingOrSizing()
	end)
	ELib:Border(LastSyncWindow,1,.24,.25,.30,1)
    LastSyncWindow.border = MRT.lib.CreateShadow(LastSyncWindow,20)

	local function LineName_Icon_OnEnter(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Show(self,nil,self.HOVER_TEXT)
		end
	end
	local function LineName_Icon_OnLeave(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Hide()
		end
	end

	function LastSyncWindow.SetIcon(self,type) -- 1 = x 2 = v 3 = lock 4 = ...
		if not type or type == 0 then
			self:SetAlpha(0)
		elseif type == 1 then
			self:SetTexCoord(0.5,0.5625,0.5,0.625)
			self:SetVertexColor(.8,0,0,1)
		elseif type == 2 then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(0,.8,0,1)
		elseif type == 3 then
			self:SetTexCoord(0.625,0.6875,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == 4 then
			self:SetTexCoord(0.875,0.9375,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == "OUTDATED" then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		end
	end

	local function RaidNames_OnEnter(self)
		local t = self.t:GetText()
		if t ~= "" then
			ELib.Tooltip.Show(self,"ANCHOR_LEFT",t)
		end
	end

	local raidNames = CreateFrame("Frame",nil,LastSyncWindow)

	for i=1,VERTICALNAME_COUNT do
		raidNames[i] = ELib:Text(raidNames,"RaidName"..i,10):Point("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + VERTICALNAME_WIDTH*(i-1),-(TOTAL_HEIGHT-PAGE_HEIGHT)):Color(1,1,1)

		local f = CreateFrame("Frame",nil,LastSyncWindow)
		f:SetPoint("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + VERTICALNAME_WIDTH*(i-1),-(TOTAL_HEIGHT-PAGE_HEIGHT))
		f:SetSize(VERTICALNAME_WIDTH,TOTAL_HEIGHT-PAGE_HEIGHT)
		f:SetScript("OnEnter",RaidNames_OnEnter)
		f:SetScript("OnLeave",ELib.Tooltip.Hide)
		f.t = raidNames[i]

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self)
            self:GetParent():StartMoving()
        end)
        f:SetScript("OnDragStop", function(self)
            self:GetParent():StopMovingOrSizing()
        end)

		local t = LastSyncWindow:CreateTexture(nil,"BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT",raidNames[i],"BOTTOMLEFT",0,0)
		t:SetDrawLayer("ARTWORK")
		t:SetSize(VERTICALNAME_WIDTH,PAGE_HEIGHT)
		if i%2==1 then
			t:SetColorTexture(.5,.5,1,.05)
			t.Vis = true
		end

		local icon = LastSyncWindow:CreateTexture(nil,"ARTWORK")
		raidNames[i].icon = icon
		icon:SetPoint("CENTER",raidNames[i].t,"CENTER",0,0)
		icon:SetSize(20,20)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		LastSyncWindow.SetIcon(icon,0) -- 1 = x 2 = v 3 = lock 4 = ...

		icon.hoverFrame = CreateFrame("Frame",nil,LastSyncWindow)
		icon.hoverFrame:Hide()
		icon.hoverFrame:SetAllPoints(icon)
		icon.hoverFrame:SetScript("OnEnter",LineName_Icon_OnEnter)
		icon.hoverFrame:SetScript("OnLeave",LineName_Icon_OnLeave)
	end
	local group = raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local function sortByName(a,b)
		if a and b and a.name and b.name then
			return a.name < b.name
		end
	end

	function LastSyncWindow:Update(token)
		local namesList,namesList2 = {},{}
		for _,name,_,class in MRT.F.IterateRoster do
			namesList[#namesList + 1] = {
				name = name,
				class = class,
			}
		end
		sort(namesList,sortByName)

		local raidNamesUsed = 0
		for i=1,#namesList do
			raidNamesUsed = raidNamesUsed + 1
			if not raidNames[raidNamesUsed] then
				break
			end
			local name = MRT.F.delUnitNameServer(namesList[i].name)
			raidNames[raidNamesUsed]:SetText(name)
			raidNames[raidNamesUsed]:SetTextColor(MRT.F.classColorNum(namesList[i].class))
			namesList2[raidNamesUsed] = name
			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
			local data
			for long_name,v in next, module.db.responcesData do -- for name-server, status(time() or string status)
				if long_name:find("^"..name) then
					data = v and v[token] and v[token].date
					break
				end
			end

			if data == "NOLS" then -- no lastSync but reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,3)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "Have reminder but no last sync data provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif data == "NODATA" then -- no reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,1)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No data found"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif tonumber(data) then -- lastSync info
				if VMRT.Reminder.data[token].lastSync <= tonumber(data) then
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,2)
				else
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,"OUTDATED")
				end
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = date("%X %x",data)
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			else
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,4)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No proper response provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			end
		end

		for i=raidNamesUsed+1,#raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
			LastSyncWindow.SetIcon(raidNames[i].icon,0)
			raidNames[i].icon.hoverFrame:Hide()
		end


	end
	LastSyncWindow:Update()

	function module:GetLastSync(token)
		wipe(module.db.responcesData)
		MRT.F.SendExMsg("reminder", "GRV\t"..token)

		LastSyncWindow:Update(token)
		C_Timer.After(1.5,function() LastSyncWindow:Update(token) end)

		LastSyncWindow:Show()
	end


---------------------------------------
-- Reminder Options(Second Tab). Would prefer some renaming here and probably refactor as well. Was making changes here long ago, so code must be fucked
---------------------------------------

    self.options_tab = MLib:Tabs2(self.SETTINGS_TAB,0,GENERAL_LABEL,TUTORIAL_TITLE19,LR["Help"]):Point(0,-25):Size(698,570):SetTo(1)
    self.options_tab.GENERAL_SETTINGS = self.options_tab.tabs[1]
    self.options_tab.ALWAYS_PLAYERS_SETTINGS = self.options_tab.tabs[2]
    self.options_tab.HELP = self.options_tab.tabs[3]


    -- ELib:DecorationLine(self.options_tab,true,"BACKGROUND",-5):Point("TOPLEFT",self.options_tab,0,0):Point("BOTTOMRIGHT",self.options_tab,"TOPRIGHT",0,-20):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))
    ELib:DecorationLine(self.SETTINGS_TAB,true,"BACKGROUND",1):Point("TOPLEFT",self,0,-50):Point("BOTTOMRIGHT",self,"TOPRIGHT",0,-70):SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))
	self.chkLock = ELib:Check(self.options_tab.GENERAL_SETTINGS,L.cd2fix,true):Point(10,-10):OnClick(function(self)
		module.frame.unlocked = not self:GetChecked()
		module:UpdateVisual()
	end)

	self.disableSound = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR.DisableSound,VMRT.Reminder.disableSound):Point(10,-35):OnClick(function(self)
		VMRT.Reminder.disableSound = self:GetChecked()
	end)

	self.updatesDebug = ELib:Check(self.options_tab.GENERAL_SETTINGS,"DEBUG UPDATES",VMRT.Reminder.debugUpdates):Point(325,-10):OnClick(function(self)
		VMRT.Reminder.debugUpdates = self:GetChecked()
	end)
	self.disableUpdates = ELib:Check(self.options_tab.GENERAL_SETTINGS,"DISABLE UPDATES",VMRT.Reminder.disableUpdates):Point(325,-35):OnClick(function(self)
		VMRT.Reminder.disableUpdates = self:GetChecked()
	end)
	self.bwDebug = ELib:Check(self.options_tab.GENERAL_SETTINGS,"BIGWIGS DEBUG",VMRT.Reminder.bwDebug):Point(325,-60):OnClick(function(self)
		VMRT.Reminder.bwDebug = self:GetChecked()
	end)
    self.alwaysLoad = ELib:Check(self.options_tab.GENERAL_SETTINGS,"ALWAYS PASS LOAD CONDITIONS",VMRT.Reminder.alwaysLoad):Point(325,-85):OnClick(function(self)
		VMRT.Reminder.alwaysLoad = self:GetChecked()
	end)

	local debugCheckFrame = CreateFrame("Frame",nil,self.options_tab.GENERAL_SETTINGS)
	debugCheckFrame:SetPoint("TOPLEFT")
	debugCheckFrame:SetSize(1,1)
	debugCheckFrame:SetScript("OnShow",function()
		if IsShiftKeyDown() and IsAltKeyDown() then
			self.updatesDebug:Show()
			self.disableUpdates:Show()
			self.bwDebug:Show()
            self.alwaysLoad:Show()
		else
			self.updatesDebug:Hide()
			self.disableUpdates:Hide()
			self.bwDebug:Hide()
            self.alwaysLoad:Hide()
		end
	end)

	self.optionWidgets = MLib:Tabs2(self.options_tab.GENERAL_SETTINGS,0,"Text","Text To Speech","Raid Frame Glow","Nameplate Glow", "Bars"):Point(0,-325):Point("LEFT",self.options_tab.GENERAL_SETTINGS):Size(698,200):SetTo(1)
	self.optionWidgets:SetBackdropBorderColor(0,0,0,0)
	self.optionWidgets:SetBackdropColor(0,0,0,0)
	local OWDecorationLine = ELib:DecorationLine(self.optionWidgets,true,"BACKGROUND",1):Point("TOP",0,20):Point("LEFT",-1,0):Point("RIGHT",62,0):Size(0,20)
	OWDecorationLine:SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	local function DropDownFont_Click(_,arg)
		VMRT.Reminder.Font = arg
		local FontNameForDropDown = arg:match("\\([^\\]*)$"):gsub("%....$", "")
		self.dropDownFont:SetText(FontNameForDropDown or arg)
		ELib:DropDownClose()
		module:UpdateVisual()
	end

	self.dropDownFont = ELib:DropDown(self.optionWidgets.tabs[1],250,10):Size(280):Point(100,-15):AddText("|cffffce00"..LR.Font)
	for i=1,#MRT.F.fontList do
		local info = {}

		info.text = MRT.F.fontList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = MRT.F.fontList[i]
		info.func = DropDownFont_Click
		info.font = MRT.F.fontList[i]

		self.dropDownFont.List[i] = info
	end
	for name,font in MRT.F.IterateMediaData("font") do
		local info = {}

		info.text = name--font:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = font
		info.func = DropDownFont_Click
		info.font = font

		self.dropDownFont.List[#self.dropDownFont.List+1] = info
	end
	do
		local arg = VMRT.Reminder.Font or MRT.F.defFont
		local FontNameForDropDown = arg:match("\\([^\\]*)$"):gsub("%....$" , "")
		self.dropDownFont:SetText(FontNameForDropDown or arg)
	end

	self.chkShadow = ELib:Check(self.optionWidgets.tabs[1],LR.OutlineChk, VMRT.Reminder.Shadow):Point("LEFT",self.dropDownFont,"RIGHT",5,0):OnClick(function(self)
		VMRT.Reminder.Shadow = self:GetChecked()
		module:UpdateVisual()
	end)

	local function flagListTextUpdate(arg)
		if arg == "update" then
			for i=1,#font_flags do
				if font_flags[i][1] == VMRT.Reminder.OutlineType then
					self.flagList:SetText(font_flags[i][2])
					break
				end
			end
		else
			for i=1,#font_flags do
				if font_flags[i][1] == VMRT.Reminder.OutlineType then
					return font_flags[i][2]
				end
			end
		end
	end

	local function flagList_SetValue(_,flag)
		VMRT.Reminder.OutlineType = flag
		ELib:DropDownClose()
		module:UpdateVisual()
		flagListTextUpdate("update")
	end

	self.flagList = ELib:DropDown(self.optionWidgets.tabs[1],250,6):Size(280):Point(100,-40):SetText(flagListTextUpdate() or LR.OutlinesNormal):AddText("|cffffce00"..LR.Outline)
	do
		local List = self.flagList.List
		for i=1,#font_flags do
			List[#List+1] = {
				text = font_flags[i][2],
				arg1 = font_flags[i][1],
				func = flagList_SetValue,
			}
		end
	end

	self.moreOptionsDropDown = ELib:DropDown(self.optionWidgets.tabs[1],250,#frameStrataList+1):Point(100,-65):Size(280):SetText(VMRT.Reminder.FrameStrata):AddText("|cffffce00"..LR.Strata)

	local function moreOptionsDropDown_SetVaule(_,arg)
		VMRT.Reminder.FrameStrata = arg
		self.moreOptionsDropDown:SetText(VMRT.Reminder.FrameStrata)
		ELib:DropDownClose()
		for i=1,#self.moreOptionsDropDown.List-1 do
			self.moreOptionsDropDown.List[i].checkState = VMRT.Reminder.FrameStrata == self.moreOptionsDropDown.List[i].arg1
		end
		module:UpdateVisual()
	end

	for i=1,#frameStrataList do
		self.moreOptionsDropDown.List[i] = {
			text = frameStrataList[i],
			checkState = VMRT.Reminder.FrameStrata == frameStrataList[i],
			radio = true,
			arg1 = frameStrataList[i],
			func = moreOptionsDropDown_SetVaule,
		}
	end
	tinsert(self.moreOptionsDropDown.List,{text = L.minimapmenuclose, func = function()
			ELib:DropDownClose()
		end})

	local function dropDownFontAdjSetValue(_,arg1)
		ELib:DropDownClose()
		VMRT.Reminder.JustifyH = arg1
		self.dropDownFontAdj:SetText(VMRT.Reminder.JustifyH == 1 and L.cd2ColSetFontPosLeft or VMRT.Reminder.JustifyH == 2 and L.cd2ColSetFontPosRight or L.cd2ColSetFontPosCenter)
		module:UpdateVisual()
        	end
	self.dropDownFontAdj = ELib:DropDown(self.optionWidgets.tabs[1],350,-1):Size(280):Point("TOPLEFT",self.moreOptionsDropDown,"BOTTOMLEFT",0,-5):SetText(VMRT.Reminder.JustifyH == 1 and L.cd2ColSetFontPosLeft or VMRT.Reminder.JustifyH == 2 and L.cd2ColSetFontPosRight or L.cd2ColSetFontPosCenter):AddText("|cffffce00"..LR.Justify)

	self.dropDownFontAdj.List[1] = {text = L.cd2ColSetFontPosCenter, func = dropDownFontAdjSetValue, arg1 = nil, justifyH = "CENTER"}
	self.dropDownFontAdj.List[2] = {text = L.cd2ColSetFontPosLeft, func = dropDownFontAdjSetValue, arg1 = 1, justifyH = "LEFT"}
	self.dropDownFontAdj.List[3] = {text = L.cd2ColSetFontPosRight, func = dropDownFontAdjSetValue, arg1 = 2, justifyH = "RIGHT"}

    self.optTimerExcluded = ELib:Check(self.optionWidgets.tabs[1],LR.TimerExcluded,VMRT.Reminder.FontTimerExcluded):Tooltip(LR.TimerExcludedTip):Point("LEFT",self.dropDownFontAdj,"RIGHT",5,0):OnClick(function(self)
		VMRT.Reminder.FontTimerExcluded = self:GetChecked()
		module:UpdateVisual()
	end)

    self.sliderFontSizeBig = ELib:Slider(self.optionWidgets.tabs[1],LR["Big Font Size"]):Size(280):Point(100,-125):Range(12,120):SetTo(VMRT.Reminder.FontSizeBig):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.FontSizeBig = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.sliderFontSize = ELib:Slider(self.optionWidgets.tabs[1],LR["Normal Font Size"]):Size(280):Point(100,-150):Range(12,120):SetTo(VMRT.Reminder.FontSize):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.FontSize = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

    self.sliderFontSizeSmall = ELib:Slider(self.optionWidgets.tabs[1],LR["Small Font Size"]):Size(280):Point(100,-175):Range(12,120):SetTo(VMRT.Reminder.FontSizeSmall):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.FontSizeSmall = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.CenterXButton = MLib:Button(self.optionWidgets.tabs[1],LR.CenterByX,13):Point(100,-200):Size(139,20):Tooltip(LR.CenterXTip):OnClick(function()
		module.frame:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VMRT.Reminder.Left = module.frame:GetLeft() - 15
        module:UpdateVisual()
	end)

	self.CenterYButton = MLib:Button(self.optionWidgets.tabs[1],LR.CenterByY,13):Point("LEFT",self.CenterXButton,"RIGHT",3,0):Size(139,20):Tooltip(LR.CenterYTip):OnClick(function()
		module.frame:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VMRT.Reminder.Top = module.frame:GetTop() + 15
        module:UpdateVisual()
	end)

	self.chkEnableHistory = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR.EnableHistory,VMRT.Reminder.HistoryEnabled):Point(10,-80):OnClick(function(self)
		VMRT.Reminder.HistoryEnabled = self:GetChecked()
	end)

	self.chkSaveHistory = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR["Save history between sessions"],VMRT.Reminder.SaveHistory):Point(10,-105):Tooltip(LR["Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"]):OnClick(function(self)
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

    self.chkHistoryTransmission = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR["History transmission"],VMRT.Reminder.HistoryTransmission):Tooltip(LR["Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"]):Point(10,-130):OnClick(function(self)
        VMRT.Reminder.HistoryTransmission = self:GetChecked()
    end)

	self.HistorySlider = ELib:Slider(self.options_tab.GENERAL_SETTINGS,LR["Amount of pulls to save\nper boss and difficulty"]):Size(280):Point(10,-175):Range(2,16):SetTo(VMRT.Reminder.HistoryMaxPulls or 2):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.HistoryMaxPulls = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)

        if module.SetupFrame and module.SetupFrame.QuickList then
            module.SetupFrame:UpdateHistory()
        end
	end)

	local function GetCurrentProfileName()
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

    self.DataProfileDropDown = ELib:DropDown(self.options_tab.GENERAL_SETTINGS,250,-1):Point(90,-225):Size(220):SetText(GetCurrentProfileName()):AddText("|cffffce00" ..LR["Profile"]..":")

	function self.DataProfileDropDown:PreUpdate()
		StaticPopup_Hide("EXRT_REMINDER_COPY_PROFILE")
		StaticPopup_Hide("EXRT_REMINDER_DELETE_PROFILE")
		StaticPopup_Hide("EXRT_REMINDER_ADD_PROFILE")

		local List = self.List
		local removeSubMenu = {}
		local copySubMenu = {}
		wipe(List)
		List[#List+1] = {text = LR["Add new"], colorCode = "|cff00aaff", func = function()
			ELib:DropDownClose()
			StaticPopupDialogs["EXRT_REMINDER_ADD_PROFILE"] = {
				text = LR["Enter profile name"],
				button1 = ACCEPT,
				button2 = CANCEL,
				OnAccept = function(self)
					local name = self.editBox:GetText()
					if name and name ~= "" then
						module.options.DataProfileDropDown:SetProfile(name)
					end
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				hasEditBox = true,
			}
			StaticPopup_Show("EXRT_REMINDER_ADD_PROFILE")
		end, sort = "00Add"}
		for profileKey in next, VMRT.Reminder.DataProfiles do
			local text = profileKey == "Default" and LR.Default or profileKey
			List[#List+1] = {
				text = text,
				func = self.SetProfile,
				arg1 = profileKey,
				sort = (profileKey == "Default" and "0" or  "1")..profileKey,
			}
			if profileKey ~= VMRT.Reminder.DataProfile then -- dont allow to delete or currently selected profile
				if profileKey ~= "Default" then
					removeSubMenu[#removeSubMenu+1] = {
						text = text,
						func = self.DeleteProfile,
						arg1 = profileKey,
						sort = "1"..profileKey,
					}
				end
				copySubMenu[#copySubMenu+1] = {
					text = text,
					func = self.CopyProfile,
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

	function self.DataProfileDropDown:SetProfile(profileKey)
		ELib:DropDownClose()
		if VMRT.Reminder.ForcedDataProfile then
			VMRT.Reminder.ForcedDataProfile = profileKey
		end
		VMRT.Reminder.DataProfileKeys[ MRT.SDB.charKey ] = profileKey
		module:LoadProfile()
		module.options.DataProfileDropDown:SetText(GetCurrentProfileName())
	end

	function self.DataProfileDropDown:DeleteProfile(profileKey)
		ELib:DropDownClose()
		StaticPopupDialogs["EXRT_REMINDER_DELETE_PROFILE"] = {
			text = LR["Delete profile"].." '"..profileKey.."'?",
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				VMRT.Reminder.DataProfiles[profileKey] = nil
				if VMRT.Reminder.ForcedDataProfile == profileKey then
					VMRT.Reminder.ForcedDataProfile = "Default"
				end
				for charKey,profileK in next, VMRT.Reminder.DataProfileKeys do
					if profileK == profileKey then
						VMRT.Reminder.DataProfileKeys[charKey] = nil
					end
				end
				module:LoadProfile()
				module.options.DataProfileDropDown:SetText(GetCurrentProfileName())
			end,
			showAlert = 1,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("EXRT_REMINDER_DELETE_PROFILE")
	end

	function self.DataProfileDropDown:CopyProfile(profileKey)
		ELib:DropDownClose()
		StaticPopupDialogs["EXRT_REMINDER_COPY_PROFILE"] = {
			text = LR["Copy into current profile from"].." '"..profileKey.."'?",
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				if VMRT.Reminder.DataProfiles[profileKey] then
					local copiedData = CopyTable(VMRT.Reminder.DataProfiles[profileKey])
					VMRT.Reminder.data = copiedData.data
					VMRT.Reminder.removed = copiedData.removed
					module:ReloadAll()
					module.options:Update()
				end
			end,
			showAlert = 1,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show("EXRT_REMINDER_COPY_PROFILE")
	end

	self.ForcedDataProfileCheck = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR["Use for all characters"],VMRT.Reminder.ForcedDataProfile):Point("LEFT",self.DataProfileDropDown,"RIGHT",5,0):OnClick(function(self)
		if self:GetChecked() then
			VMRT.Reminder.ForcedDataProfile = VMRT.Reminder.DataProfile
		else
			VMRT.Reminder.ForcedDataProfile = false
		end
		module:LoadProfile()
		module.options.DataProfileDropDown:SetText(GetCurrentProfileName())
	end)

    self.forceLocale = ELib:DropDown(self.options_tab.GENERAL_SETTINGS,150,-1):Point(90,-250):Size(220):SetText(VMRT.Reminder.ForceLocale or "-"):AddText("|cffffce00Force locale:"):Shown(MRT.locale ~= "ruRU" and MRT.locale ~= "koKR")
    do
        local function forceLocale_SetValue(_,arg)
            local old = VMRT.Reminder.ForceLocale
            VMRT.Reminder.ForceLocale = arg
            self.forceLocale:SetText(arg or "-")
            ELib:DropDownClose()
            if old ~= arg then
                StaticPopupDialogs["EXRT_FORCE_LOCALE_RELOAD_UI"] = {
                    text = LR["Reload UI to apply changes"],
                    button1 = ACCEPT,
                    button2 = CANCEL,
                    timeout = 0,
                    whileDead = 1,
                    hideOnEscape = 1,
                    OnAccept = ReloadUI,
                    OnCancel = function()
                        VMRT.Reminder.ForceLocale = old
                        self.forceLocale:SetText(old or "-")
                    end
                }
                StaticPopup_Show("EXRT_FORCE_LOCALE_RELOAD_UI")
            end
        end
        local List = self.forceLocale.List
        List[1] = {text = "-", func = forceLocale_SetValue, arg1 = nil}
        for i,locale in ipairs({"ru","kr"}) do
            List[#List+1] = {
                text = locale,
                arg1 = locale,
                func = forceLocale_SetValue,
            }
        end
    end

    self.alternativeColorScheme = ELib:Check(self.options_tab.GENERAL_SETTINGS,LR["Alternative color scheme for reminders list"], VMRT.Reminder.alternativeColorScheme):Point(10,-275):OnClick(function(self)
		VMRT.Reminder.alternativeColorScheme = self:GetChecked()
        module.options.scrollList:Update(true)
	end)
	----------------------------------------------------------------

	self.ttsVoiceDropDown = ELib:DropDown(self.optionWidgets.tabs[2],300,-1):Point(100,-15):Size(280):AddText("|cffffce00TTS Voice")
    function self.ttsVoiceDropDown:Update()
        local voices = C_VoiceChat.GetTtsVoices()
        local voiceID = VMRT.Reminder.ttsVoice or TextToSpeech_GetSelectedVoice(Enum.TtsVoiceType.Standard).voiceID
        for i=1,#voices do
            if voices[i].voiceID == voiceID then
                self:SetText(voices[i].name)
                return
            end
        end
        self:SetText("Voice ID "..(voiceID or "unk"))
    end
    function self.ttsVoiceDropDown.func_SetValue(_,arg1)
        VMRT.Reminder.ttsVoice = arg1
        self.ttsVoiceDropDown:Update()
        ELib:DropDownClose()

        module:PlayTTS("This is an example of text to speech")
    end
    function self.ttsVoiceDropDown:PreUpdate()
        local List = self.List
        wipe(List)
        local voices = C_VoiceChat.GetTtsVoices()
        for i=1,#voices do
            List[#List+1] = {
                text = voices[i].name or ("id "..i),
                arg1 = voices[i].voiceID,
                func = self.func_SetValue,
            }
        end
    end
    self.ttsVoiceDropDown:Update()

	self.ttsVolumeSlider = ELib:Slider(self.optionWidgets.tabs[2],"TTS Volume"):Size(280):Point(100,-55):Range(1,100):SetTo(VMRT.Reminder.ttsVoiceVolume or 100):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.ttsVoiceVolume = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.ttsRateSlider = ELib:Slider(self.optionWidgets.tabs[2],"TTS Rate"):Size(280):Point(100,-85):Range(-10,10):SetTo(VMRT.Reminder.ttsVoiceRate or 100):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.ttsVoiceRate = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.ttsVoiceTestButton = MLib:Button(self.optionWidgets.tabs[2],"TTS TEST",13):Size(80,20):FontSize(12):Point("LEFT",self.ttsVoiceDropDown,"RIGHT",5,0):OnClick(function()
		module:PlayTTS("This is an example of text to speech")
	end)

    self.ttsIgnoreFiles = ELib:Check(self.optionWidgets.tabs[2],LR["Use TTS files if possible"], not VMRT.Reminder.ttsIgnoreFiles):Tooltip(
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
	):Point(100,-115):OnClick(function(self)
        VMRT.Reminder.ttsIgnoreFiles = not self:GetChecked()
    end)

	do
		local Glow = VMRT.Reminder.Glow
		local PixelGlow = Glow.PixelGlow
		local AutoCastGlow = Glow.AutoCastGlow
		local ProcGlow = Glow.ProcGlow
		local ActionButtonGlow = Glow.ActionButtonGlow

        self.glowFrameColor = ELib:Edit(self.optionWidgets.tabs[3]):Size(100,20):Point(100,-40):Run(function(s)
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
                Glow.Color = "ffff0000"
                module.options.glowFrameColor.preview:Update()
            elseif text:find("^%x%x%x%x%x%x%x%x$") then
                Glow.Color = text
                module.options.glowFrameColor.preview:Update()
                self:Disable()
            end
        end)

        self.glowFrameColor.preview = ELib:Texture(self.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
        self.glowFrameColor.preview.Update = function(self)
            local t = self:GetParent():GetText()
            local at,rt,gt,bt = t:match("(..)(..)(..)(..)")
            if not bt then
                at,rt,gt,bt = Glow.Color:match("(..)(..)(..)(..)")
            end
            if bt then
                local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
                self:SetColorTexture(r/255,g/255,b/255,a/255)
            end
        end
        local checkers = ELib:Texture(self.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
        self.glowFrameColor.preview.checkers = checkers
        checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
        checkers:SetTexCoord(.25, 0, .5, .25)
        checkers:SetDesaturated(true)
        checkers:SetVertexColor(1, 1, 1, 0.75)
        checkers:SetDrawLayer("BORDER", -7)
        checkers:Show()

        self.glowFrameColor.colorButton = CreateFrame("Button",nil,self.glowFrameColor)
        self.glowFrameColor.colorButton:SetPoint("LEFT", self.glowFrameColor.preview, "RIGHT", 5, 0)
        self.glowFrameColor.colorButton:SetSize(24,24)
        self.glowFrameColor.colorButton:SetScript("OnClick",function()
            local prevValue = Glow.Color

            local colorPalette = Glow.Color or "ffff0000"
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

                        Glow.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

                        self.glowFrameColor:SetText(Glow.Color or "")
                        self.glowFrameColor:Disable()
                        self.glowFrameColor.preview:Update()
                    end,
                    opacityFunc = function()
                        local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                        local newA = ColorPickerFrame:GetColorAlpha()
                        newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

                        Glow.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

                        self.glowFrameColor:SetText(Glow.Color or "")
                        self.glowFrameColor:Disable()
                        self.glowFrameColor.preview:Update()
                    end,
                    cancelFunc = function()
                        Glow.Color = prevValue

                        self.glowFrameColor:SetText(Glow.Color or "")
                        self.glowFrameColor:Disable()
                        self.glowFrameColor.preview:Update()
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

                    Glow.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

                    self.glowFrameColor:SetText(Glow.Color or "")
                    self.glowFrameColor:Disable()
                    self.glowFrameColor.preview:Update()
                end

                ColorPickerFrame.opacityFunc = function()
                    local newR, newG, newB = ColorPickerFrame:GetColorRGB()
                    local newA = OpacitySliderFrame:GetValue()
                    newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

                    Glow.Color = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

                    self.glowFrameColor:SetText(Glow.Color or "")
                    self.glowFrameColor:Disable()
                    self.glowFrameColor.preview:Update()
                end

                ColorPickerFrame.cancelFunc = function()
                    Glow.Color = prevValue

                    self.glowFrameColor:SetText(Glow.Color or "")
                    self.glowFrameColor:Disable()
                    self.glowFrameColor.preview:Update()
                end

                ColorPickerFrame:Show()
            end
        end)
        self.glowFrameColor.colorButton:SetScript("OnEnter",function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L.ReminderSelectColor)
            GameTooltip:Show()
        end)
        self.glowFrameColor.colorButton:SetScript("OnLeave",function(self)
            GameTooltip_Hide()
        end)
        self.glowFrameColor.colorButton.Texture = self.glowFrameColor.colorButton:CreateTexture(nil,"ARTWORK")
        self.glowFrameColor.colorButton.Texture:SetPoint("CENTER")
        self.glowFrameColor.colorButton.Texture:SetSize(20,20)
        self.glowFrameColor.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])
        self.glowFrameColor.leftText = ELib:Text(self.glowFrameColor,COLOR..":",13):Point("RIGHT",self.glowFrameColor,"LEFT",-5,0):Right():Middle():Shadow()


        self.glowFrameColor:SetText(Glow.Color)
        self.glowFrameColor.preview:Update()

		-------------------------------------------------------------------
		-------------------------PIXEL GLOW--------------------------------
		-------------------------------------------------------------------

		self.pixelGlowFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(PixelGlow.frequency):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.pixelGlowFrequencySlider.High:SetText("5")
		self.pixelGlowFrequencySlider.Low:SetText("-5")

		self.pixelGlowCountSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Count"):Size(120):Point(230,-85):Range(1,20):SetTo(PixelGlow.count):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowLengthSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Length"):Size(120):Point(360,-85):Range(1,50):SetTo(PixelGlow.length):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.length = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowThicknessSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Thickness"):Size(120):Point(490,-85):Range(1,6):SetTo(PixelGlow.thickness):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.thickness = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(PixelGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(PixelGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.chkPixelGlowBorder = ELib:Check(self.optionWidgets.tabs[3],"Glow Border", PixelGlow.border):Point(360,-115):OnClick(function(self)
			PixelGlow.border = self:GetChecked()
		end)

		-------------------------------------------------------------------
		-------------------------AUTO CAST GLOW----------------------------
		-------------------------------------------------------------------

		self.autoCastFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(AutoCastGlow.frequency):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.autoCastFrequencySlider.High:SetText("5")
		self.autoCastFrequencySlider.Low:SetText("-5")

		self.autoCastCountSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Count"):Size(120):Point(230,-85):Range(1,20):SetTo(AutoCastGlow.count):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.autoCastScaleSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Scale"):Size(120):Point(360,-85):Range(4,20):SetTo(AutoCastGlow.scale):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.scale = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.autoCastScaleSlider.High:SetText("5")
		self.autoCastScaleSlider.Low:SetText("1")
		self.autoCastScaleSlider.tooltipText = AutoCastGlow.scale*4

		self.autoCastXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(AutoCastGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.autoCastYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(AutoCastGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		-------------------------------------------------------------------
		-------------------------PROC GLOW---------------------------------
		-------------------------------------------------------------------

		self.procGlowDurationSlider = ELib:Slider(self.optionWidgets.tabs[3],"Animation duration"):Size(120):Point(100,-85):Range(0,20):SetTo(ProcGlow.duration*8):OnChange(function(self,event)
			event = event
			ProcGlow.duration = event/8
			self.tooltipText = event/8
			self:tooltipReload(self)
		end)
		self.procGlowDurationSlider.High:SetText("2.5")
		self.procGlowDurationSlider.Low:SetText("0")
		self.procGlowDurationSlider.tooltipText = ProcGlow.duration
		-- self.procGlowDurationSlider.tooltipReload(self.procGlowDurationSlider)

		self.procGlowXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(ProcGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			ProcGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.proclGlowYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(ProcGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			ProcGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.chkProcGlowStartAnim = ELib:Check(self.optionWidgets.tabs[3],"Start Animation", ProcGlow.startAnim):Point(360,-115):OnClick(function(self)
			ProcGlow.startAnim = self:GetChecked()
		end)

		-------------------------------------------------------------------
		-------------------------ACTION BUTTON GLOW------------------------
		-------------------------------------------------------------------

		self.actionButtonFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(ActionButtonGlow.frequency/4):OnChange(function(self,event)
			event = floor(event + .5)
			ActionButtonGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.actionButtonFrequencySlider.High:SetText("5")
		self.actionButtonFrequencySlider.Low:SetText("-5")
		------------------------------------------------------------------
		local function SetGlowButtons()
			local type = Glow.type

			self.pixelGlowCountSlider:Hide()
			self.pixelGlowFrequencySlider:Hide()
			self.pixelGlowLengthSlider:Hide()
			self.pixelGlowThicknessSlider:Hide()
			self.pixelGlowXOffsetSlider:Hide()
			self.pixelGlowYOffsetSlider:Hide()
			self.chkPixelGlowBorder:Hide()

			self.autoCastCountSlider:Hide()
			self.autoCastFrequencySlider:Hide()
			self.autoCastScaleSlider:Hide()
			self.autoCastXOffsetSlider:Hide()
			self.autoCastYOffsetSlider:Hide()

			self.procGlowDurationSlider:Hide()
			self.procGlowXOffsetSlider:Hide()
			self.proclGlowYOffsetSlider:Hide()
			self.chkProcGlowStartAnim:Hide()

			self.actionButtonFrequencySlider:Hide()

			if type == "Pixel Glow" then
				self.pixelGlowCountSlider:Show()
				self.pixelGlowFrequencySlider:Show()
				self.pixelGlowLengthSlider:Show()
				self.pixelGlowThicknessSlider:Show()
				self.pixelGlowXOffsetSlider:Show()
				self.pixelGlowYOffsetSlider:Show()
				self.chkPixelGlowBorder:Show()
			elseif type == "Autocast Shine" then
				self.autoCastCountSlider:Show()
				self.autoCastFrequencySlider:Show()
				self.autoCastScaleSlider:Show()
				self.autoCastXOffsetSlider:Show()
				self.autoCastYOffsetSlider:Show()
			elseif type == "Proc Glow" then
				self.procGlowDurationSlider:Show()
				self.procGlowXOffsetSlider:Show()
				self.proclGlowYOffsetSlider:Show()
				self.chkProcGlowStartAnim:Show()
			else
				self.actionButtonFrequencySlider:Show()
			end
		end
		SetGlowButtons()
		self.glowDropDown = ELib:DropDown(self.optionWidgets.tabs[3],275,#glowList+1):Point(100,-15):Size(280):SetText(LR[Glow.type]):AddText("|cffffce00Glow Type")

		local function glowDropDown_SetVaule(_,arg)
			Glow.type = arg
			self.glowDropDown:SetText(LR[arg])
			ELib:DropDownClose()
			for i=1,#self.glowDropDown.List-1 do
				self.glowDropDown.List[i].checkState = Glow.type == self.glowDropDown.List[i].arg1
			end
			SetGlowButtons()
		end

		for i=1,#glowList do
			self.glowDropDown.List[i] = {
				text = LR[glowList[i]],
				arg1 = glowList[i],
				func = glowDropDown_SetVaule,
			}
		end
		tinsert(self.glowDropDown.List,{text = L.minimapmenuclose, func = function()
				ELib:DropDownClose()
			end})

		self.glowTestButton = MLib:Button(self.optionWidgets.tabs[3],"GLOW TEST",13):Size(80,20):FontSize(12):Point("LEFT",self.glowDropDown,"RIGHT",5, 0):Tooltip("Only in raid group\nGlows player frame in raid groups for 5 sec"):OnClick(function()
            local data = {
                glow = UnitName("player"),
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

	local NamePlateGlowTypeDropDown = ELib:DropDown(self.optionWidgets.tabs[4],275,4):Point(100,-15):Size(280):AddText("|cffffce00Default\nNameplate\nGlow Type")
	do
		local function NamePlateGlowTypeDropDown_SetVaule(_,arg)
			VMRT.Reminder.NameplateGlowType = arg
			ELib:DropDownClose()
			for i=1,#module.datas.glowTypes do
				if module.datas.glowTypes[i][1] == arg then
					NamePlateGlowTypeDropDown:SetText(module.datas.glowTypes[i][2])
					break
				end
			end
		end

		local List = NamePlateGlowTypeDropDown.List
		for i=2,5 do
			List[#List+1] = {
				text = module.datas.glowTypes[i][2],
				arg1 = module.datas.glowTypes[i][1],
				func = NamePlateGlowTypeDropDown_SetVaule,
			}
		end

		for i=1,#module.datas.glowTypes do
			if module.datas.glowTypes[i][1] == VMRT.Reminder.NameplateGlowType then
				NamePlateGlowTypeDropDown:SetText(module.datas.glowTypes[i][2])
				break
			end
		end
	end

    -- bars options
    self.sliderBarWidth = ELib:Slider(self.optionWidgets.tabs[5],""):Size(280):Point(100,-15):Range(50,1000):SetTo(VMRT.Reminder.BarWidth or 300):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.BarWidth = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(self.optionWidgets.tabs[5],LR.barWidth,11):Point("RIGHT",self.sliderBarWidth,"LEFT",-5,0):Color(1,.82,0,1):Right()

	self.sliderBarHeight = ELib:Slider(self.optionWidgets.tabs[5],""):Size(280):Point("TOPLEFT",self.sliderBarWidth,"BOTTOMLEFT",0,-15):Range(16,96):SetTo(VMRT.Reminder.BarHeight or 30):OnChange(function(self,event)
		event = floor(event + .5)
		VMRT.Reminder.BarHeight = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(self.optionWidgets.tabs[5],LR.barHeight,11):Point("RIGHT",self.sliderBarHeight,"LEFT",-5,0):Color(1,.82,0,1):Right()

	local function dropDownBarTextureSetValue(_,arg1)
		ELib:DropDownClose()
		VMRT.Reminder.BarTexture = arg1
        local text = arg1 and arg1:match("\\([^\\]*)$"):gsub("%....$", "") or "default"
        self.dropDownBarTexture:SetText(text)
		module:UpdateVisual()
	end

	self.dropDownBarTexture = ELib:DropDown(self.optionWidgets.tabs[5],350,10):Size(280):Point("TOPLEFT",self.sliderBarHeight,"BOTTOMLEFT",0,-15):SetText(""):AddText("|cffffce00"..LR.barTexture)
	self.dropDownBarTexture.List[1] = {
		text = "default",
		func = dropDownBarTextureSetValue,
		justifyH = "CENTER" ,
		texture = [[Interface\AddOns\MRT\media\bar34.tga]],
	}
	for i=1,#MRT.F.textureList do
		local info = {}
		self.dropDownBarTexture.List[#self.dropDownBarTexture.List+1] = info
		info.text = MRT.F.textureList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = MRT.F.textureList[i]
		info.func = dropDownBarTextureSetValue
		info.texture = MRT.F.textureList[i]
		info.justifyH = "CENTER"
    end
	for key,texture in MRT.F.IterateMediaData("statusbar") do
		local info = {}
		self.dropDownBarTexture.List[#self.dropDownBarTexture.List+1] = info

		info.text = (texture:match("\\([^\\]*)$") or texture or "unknown"):gsub("%....$", "")
		info.arg1 = texture
		info.func = dropDownBarTextureSetValue
		info.texture = texture
		info.justifyH = "CENTER"
	end

    do
        local arg = VMRT.Reminder.BarTexture
        local text = (arg and arg:match("\\([^\\]*)$") or arg or "default"):gsub("%....$", "")
        self.dropDownBarTexture:SetText(text)
    end

	local function dropDownBarFontSetValue(_,arg1)
		ELib:DropDownClose()
		VMRT.Reminder.BarFont = arg1
		self.dropDownBarFont:SetText(arg1:match("\\([^\\]*)$"):gsub("%....$", ""))
		module:UpdateVisual()
	end

	self.dropDownBarFont = ELib:DropDown(self.optionWidgets.tabs[5],350,10):Size(280):Point("TOPLEFT",self.dropDownBarTexture,"BOTTOMLEFT",0,-5):Tooltip(LR.barFontTip):AddText("|cffffce00"..LR.Font)
	for i=1,#MRT.F.fontList do
		local info = {}
		self.dropDownBarFont.List[i] = info
		info.text = MRT.F.fontList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = MRT.F.fontList[i]
		info.func = dropDownBarFontSetValue
		info.font = MRT.F.fontList[i]
	end
	for key,font in MRT.F.IterateMediaData("font") do
		local info = {}
		self.dropDownBarFont.List[#self.dropDownBarFont.List+1] = info

		info.text = key
		info.arg1 = font
		info.func = dropDownBarFontSetValue
		info.font = font
	end
    do
		local arg = VMRT.Reminder.BarFont or MRT.F.defFont
		local FontNameForDropDown = arg:match("\\([^\\]*)$")
		self.dropDownBarFont:SetText((FontNameForDropDown or arg):gsub("%....$" , ""))
	end

    self.CenterXButtonBar = MLib:Button(self.optionWidgets.tabs[5],LR.CenterByX,13):Point("TOPLEFT",self.dropDownBarFont,"BOTTOMLEFT",0,-5):Size(139,20):Tooltip(LR.CenterXTip):OnClick(function()
		module.frameBars:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VMRT.Reminder.BarsLeft = module.frameBars:GetLeft() - 15
        module:UpdateVisual()
	end)

	self.CenterYButtonBar = MLib:Button(self.optionWidgets.tabs[5],LR.CenterByY,13):Point("LEFT",self.CenterXButtonBar,"RIGHT",3,0):Size(139,20):Tooltip(LR.CenterYTip):OnClick(function()
		module.frameBars:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VMRT.Reminder.BarsTop = module.frameBars:GetTop() + 15
        module:UpdateVisual()
	end)



    ELib:Text(self.options_tab.ALWAYS_PLAYERS_SETTINGS,LR.OptPlayersTooltip,11,"GameFontNormal"):Point("TOPLEFT",10,-10):Point("RIGHT",-10,0):Color()

	self.updatesPlayersList = ELib:ScrollTableList(self.options_tab.ALWAYS_PLAYERS_SETTINGS,0,150,150,10):Point("TOP",0,-30):Size(678,500):OnShow(function(self)
		local L = self.L

		wipe(L)
		for player,opt in next, VMRT.Reminder.SyncPlayers do
			L[#L+1] = {player,opt == 1 and "|cff00ff00"..ALWAYS.." "..ACCEPT or "|cffff0000"..ALWAYS.." "..DECLINE,REMOVE}
		end
		sort(L,function(a,b) return a[1]<b[1] end)

		self:Update()
	end,true)

	self.updatesPlayersList.additionalLineFunctions = true
	function self.updatesPlayersList:ClickMultitableListValue(index,obj)
		if index == 3 then
			local i = obj:GetParent().index
			if i then
				VMRT.Reminder.SyncPlayers[ module.options.updatesPlayersList.L[i][1] ] = nil
				tremove(module.options.updatesPlayersList.L,i)
				module.options.updatesPlayersList:Update()
			end
		end
	end
---------------------------------------
-- Changelog, Help and Version Tabs
---------------------------------------
	local changelogScroll = ELib:ScrollFrame(self.CHANGELOG_TAB):Size(756,589):Point("TOPLEFT",0,0)
	local changelogText = ELib:Text(changelogScroll.C, AddonDB.Changelog):Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5):Color()
	changelogScroll:Height(changelogText:GetStringHeight()+100)

	changelogScroll.C:SetWidth(695 - 16)
	ELib:Border(changelogScroll,0)
	-- ELib:DecorationLine(self):Point("TOP",changelogScroll,"BOTTOM",0,0):Point("LEFT",self):Point("RIGHT",self):Size(0,1)

	local helpScroll = ELib:ScrollFrame(self.options_tab.HELP):Size(756,564):Point("TOPLEFT",0,0)
	local helpText = ELib:Text(helpScroll.C, LR.HelpText):Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5):Color()

	helpScroll:Height(helpText:GetStringHeight()+100)
	helpScroll.C:SetWidth(690 - 16)
	ELib:Border(helpScroll,0)

	local NAME_COL = 1
	local REMINDER_VER_COL = 2
	local MRT_VER_COL = 3
	local BOSSMOD_COL = 4
	local WEAKAURAS_COL = 5
	local RCLC_COL = 6
	local RELEASE_COL = 7



	local VersionCheckReqSent = {}
	local function UpdateVersionCheck()
		self.VersionUpdateButton:Enable()
		local list = self.VersionCheck.L
		wipe(list)

		list[#list + 1] = {
			[NAME_COL] = " |cff9b9b9bName",
			[REMINDER_VER_COL] = "|cff9b9b9bReminder",
            [MRT_VER_COL] = "|cff9b9b9bMRT",
			[BOSSMOD_COL] = "|cff9b9b9bBoss Mod",
            [WEAKAURAS_COL] = "|cff9b9b9bWeakAuras",
			[RCLC_COL] = "|cff9b9b9bRCLC",
            [RELEASE_COL] = "|cff9b9b9bRelease",
			name = "AAAAAAAAAAA",
            ver = 9999,
		}
		for _, name, _, class in MRT.F.IterateRoster do
			list[#list + 1] = {
				"|c"..MRT.F.classColor(class or "?")..name,
                0,
				name = name,
                ver = 0,
			}
		end

        -- for i=1,40 do
        --     list[#list + 1] = {
        --         "Name "..i,
        --         0,
        --         name = "Name "..i,
        --         ver = 0,
        --     }
        -- end

		for i=2,#list do
			local name = list[i].name

			local info = module.db.gettedVersions[name]
			if not info and not name:find("%-") then
				for long_name,v in next, module.db.gettedVersions do
					if long_name:find("^"..name) then
						info = v
						break
					end
				end
			end
            local ver, enabled, bossmod, hash, isPublic, mrt_ver, bm_ver, wa_ver, rclc_ver = strsplit(" ", info or "")
            -- if not mrt_ver then
            --     mrt_ver = MRT.RaidVersions[name]
            --     if not mrt_ver and not name:find("%-") then
            --         for long_name,v in next, MRT.RaidVersions do
            --             if long_name:find("^"..name) then
            --                 mrt_ver = v
            --                 break
            --             end
            --         end
            --     end
            -- end

            wa_ver = wa_ver or ""
            if wa_ver == (WeakAuras and WeakAuras.versionString or "?") then
                wa_ver = "|cff88ff88"..wa_ver
            else
                wa_ver = "|cffffff88"..wa_ver
            end

            mrt_ver = mrt_ver or ""
            if (tonumber(mrt_ver) or 0) >= MRT.V then
                mrt_ver = "|cff88ff88"..mrt_ver
            else
                mrt_ver = "|cffffff88"..mrt_ver
            end

            if bm_ver and bm_ver == (BigWigsLoader and BigWigsLoader:GetVersionString() or DBM and DBM.DisplayVersion:gsub(" ", "")) then
                bm_ver = "|cff88ff88"..bm_ver
            else
                bm_ver = "|cffffff88"..(bm_ver or "")
            end

			if rclc_ver and rclc_ver == (RCLootCouncil and RCLootCouncil.version:gsub(" ", "") or "?") then
				rclc_ver = "|cff88ff88"..rclc_ver
			else
				rclc_ver = "|cffffff88"..(rclc_ver or "")
			end

            if tonumber(ver or "?") then
                list[i].ver = tonumber(ver)
            end
            if ver == "" then
                ver = nil
            end

			if not ver then
				if VersionCheckReqSent[name] then
					if not UnitIsConnected(name) then
						ver = "|cff888888offline"
					else
						ver = "|cffff8888no addon"
					end
				else
					ver = "???"
				end
			elseif not tonumber(ver) then
				ver = "|cffffe7be"..ver
			elseif tonumber(ver) >= module.DATA_VERSION then
				ver = "|cff88ff88"..ver
			else
				ver = "|cffffff88"..ver
			end


			if UnitIsConnected(name) then
				if enabled == "Enabled" then
					enabled = "(|cff88ff88E|r)"
				elseif enabled == "Disabled" then
					enabled = "(|cffff8888D|r)"
				else
					enabled = ""
				end

				if bossmod == module.ActiveBossMod then
					bossmod = "|cff88ff88" .. bossmod
                elseif bossmod then
					bossmod = "|cffffff88" .. bossmod
				end
			else
				bossmod = ""
				enabled = ""
			end
            if hash then
                if hash == AddonDB.VersionHash then
                    hash = "|cff88ff88"..hash
                else
                    hash = "|cffffff88"..hash
                end
            end
            if isPublic then
                local colorPublic = AddonDB.PUBLIC and "88ff88" or "ffff88"
                local colorPrivate = AddonDB.PUBLIC and "ffff88" or "88ff88"
                isPublic = isPublic == "1" and "|cff"..colorPublic.."Public" or "|cff"..colorPrivate.."Private"
            end

			list[i][REMINDER_VER_COL] = ver .. " " ..  (hash or "") .. " " .. (enabled or "")
            list[i][MRT_VER_COL] = mrt_ver
			list[i][BOSSMOD_COL] = (bossmod or "") .. " " .. bm_ver
            list[i][WEAKAURAS_COL] = wa_ver
			list[i][RCLC_COL] = rclc_ver
            list[i][RELEASE_COL] = isPublic

            if not AddonDB.PUBLIC and AddonDB.RGAPI then
                list[i][NAME_COL] = AddonDB.RGAPI:ClassColorName(Ambiguate(list[i].name, "none")) or list[i][NAME_COL]
                list[i].name = AddonDB.RGAPI:UnitName(list[i].name) or list[i].name
            end
            list[i][NAME_COL] = " " .. (list[i][NAME_COL] or "")
		end

		sort(list,function(a,b)
            if a.ver ~= b.ver then
                return a.ver > b.ver
            else
                return a.name < b.name
            end
        end)
		self.VersionCheck:Update()

		self.VersionCheck.List[1].HighlightTexture:SetVertexColor(0,0,0,0)
	end


    local tmr
    function module:UpdateVersionCheck()
        if not module.options:IsVisible() then return end
        if tmr then return end

        tmr = C_Timer.NewTimer(1, function()
            tmr = nil
            UpdateVersionCheck()
        end)
    end

    local verColumns = {
			[NAME_COL] = 0, -- flex
			[REMINDER_VER_COL] = 115,
			[MRT_VER_COL] = 55,
			[BOSSMOD_COL] = 120,
			[WEAKAURAS_COL] = 120,
			[RCLC_COL] = 60,
			[RELEASE_COL] = 70
		}

    local total_size = 755
	if AddonDB.PUBLIC then
		total_size = total_size - verColumns[RELEASE_COL]
		verColumns[RELEASE_COL] = nil
	end

    self.VersionCheck = ELib:ScrollTableList(self.VERSIONS_TAB,unpack(verColumns)):Point(0,-5):Size(total_size,525):HideBorders():OnShow(UpdateVersionCheck,true)
    ELib:DecorationLine(self.VERSIONS_TAB):Point("TOP",self.VersionCheck,"BOTTOM",0,0):Point("LEFT",self):Point("RIGHT",self):Size(0,1)
    self.VersionCheck.LINE_PADDING_LEFT = 7
    self.VersionCheck.LINE_TEXTURE = "Interface\\Addons\\MRT\\media\\White"
    self.VersionCheck.LINE_TEXTURE_IGNOREBLEND = true
    self.VersionCheck.LINE_TEXTURE_COLOR_HL = {1,1,1,.5}
    self.VersionCheck.LINE_TEXTURE_COLOR_P = {1,.82,0,.6}

    self.VersionCheck.Frame.ScrollBar:Size(14,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
    self.VersionCheck.Frame.ScrollBar.thumb:SetHeight(50)

    -- local offset = first_column_size
    -- for i=1,#verColumns-1 do
    --     offset = offset + verColumns[i]
    --     ELib:DecorationLine(self.VersionCheck):Point("TOPLEFT",offset,0):Point("BOTTOMLEFT",offset,0):Size(1,0)
    -- end


	self.VersionUpdateButton = MLib:Button(self.VersionCheck,UPDATE,12):Point("TOPLEFT",self.VersionCheck,"BOTTOMLEFT",5,-5):Size(100,20):Tooltip(L.OptionsUpdateVerTooltip):OnClick(function()
		module.db.getVersion = GetTime()
		wipe(module.db.gettedVersions)
        UpdateVersionCheck()
		module:RequestVersion()

		for _, name in MRT.F.IterateRoster do
			VersionCheckReqSent[name]=true
		end
		local list = self.VersionCheck.L
		for i=2,#list do
			list[i][REMINDER_VER_COL] = "..."
		end
		self.VersionCheck:Update()
		self.VersionUpdateButton:Disable()
	end)
    self.VersionUpdateButton:SetFrameStrata("DIALOG")

	self.isWide = 760
    self.main_tab:SetTo(VMRT.Reminder.OptSavedTabNum or 1)
end
