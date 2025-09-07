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

function module:GenerateToken(customData)
	local cn = 0
	local token
	while true do
		token = (time() + GetTime() % 1) + cn
		if VMRT.Reminder.data[token] or customData and customData[token] then
			cn = cn + math.random(100,999)/1000
		else
			return token
		end
	end
end

function module.options:SetupFrameInitialize()
	-- upvalues
	local tinsert, tremove, sort, tAppendAll, tDeleteItem, next, ipairs = tinsert, tremove, sort, tAppendAll, tDeleteItem, next, ipairs
	local unpack, CopyTable, tContains, wipe, GetInstanceInfo = unpack, CopyTable, tContains, wipe, GetInstanceInfo
	local type, GetTime, UnitName, ScheduleTimer, floor, time, tonumber = type, GetTime, UnitName, MRT.F.ScheduleTimer, floor, time, tonumber
	local PlaySoundFile, pcall, CreateColor, CreateFrame, IsShiftKeyDown = PlaySoundFile, pcall, CreateColor, CreateFrame, IsShiftKeyDown
	local EJ_SelectInstance, EJ_GetEncounterInfo, EJ_GetDifficulty = EJ_SelectInstance, EJ_GetEncounterInfo, EJ_GetDifficulty
	local EJ_IsValidInstanceDifficulty, EJ_SetDifficulty, EJ_GetTierInfo = EJ_IsValidInstanceDifficulty, EJ_SetDifficulty, EJ_GetTierInfo
	local tostring, strsplit, string_sub, string_gmatch, strjoin = tostring, strsplit, string.sub, string.gmatch, strjoin
	local bit_band, bit_bor, bit_bxor = bit.band, bit.bor, bit.bxor

	local GetSpellInfo, GetSpellName = AddonDB.GetSpellInfo, AddonDB.GetSpellName

	local prettyPrint = module.prettyPrint
	local defaultFont = GameFontNormal:GetFont()

	---@class VMRT
	local VMRT = VMRT

	-- From Libs\AceGUI-3.0\widgets\AceGUIWidget-ColorPicker.lua
	-- Unfortunately we have no way to realistically detect if a client uses inverted alpha
	-- as no API will tell you. Wrath uses the old colorpicker, era uses the new one, both are inverted
	local COLORPICKER_INVERTED_ALPHA = (WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE)

	local spamTypes = {
		{nil,"-"},
		{1,LR.spamType1},
		{2,LR.spamType2},
		{3,LR.spamType3},
	}
	local spamChannels = {
		{nil,"-"},
		{1,LR.spamChannel1},
		{2,LR.spamChannel2},
		{3,LR.spamChannel3},
		{4,LR.spamChannel4},
		{5,LR.spamChannel5},
	}
	local rolesList = {
		{"TANK",LR.RolesTanks},
		{"HEALER",LR.RolesHeals},
		{"DAMAGER",LR.RolesDps},
		{"MHEALER",LR.RolesMheals, LR.RolesMhealsTip},
		{"RHEALER",LR.RolesRheals, LR.RolesRhealsTip},
		{"MDD",LR.RolesMdps},
		{"RDD",LR.RolesRdps},
	}
	local classesList = {
		{"WARRIOR","|cffc69b6dWarrior|r"},
		{"PALADIN","|cfff48cbaPaladin|r"},
		{"HUNTER","|cffaad372Hunter|r"},
		{"ROGUE","|cfffff468Rogue|r"},
		{"PRIEST","|cffffffffPriest|r"},
		{"DEATHKNIGHT","|cffc41e3aDK|r"},
		{"SHAMAN","|cff0070ddShaman|r"},
		{"MAGE","|cff3fc7ebMage|r"},
		{"WARLOCK","|cff8788eeWarlock|r"},
		{"MONK","|cff00ff98Monk|r"},
		{"DRUID","|cffff7c0aDruid|r"},
		{"DEMONHUNTER","|cffa330c9DH|r"},
		{"EVOKER","|cff33937fEvoker|r"},
	}

	local soundsList = module.datas.soundsList

	local diffsList
	if not MRT.isClassic then
		local prio = {16,15,14,17,8}
		diffsList = {}

		diffsList[#diffsList + 1] = {nil,LR.Always}

		for i=1,#prio do
			local diff = prio[i]
			local name = LR.diff_name[diff]
			diffsList[#diffsList + 1] = {diff,name}
		end

		for diff,name in next, AddonDB.EJ_DATA.diffName do
			if not tContains(prio,diff) then
				diffsList[#diffsList + 1] = {diff,name}
			end
		end
	else
		-- there is too many difficulties with duplicate names in classic, so show only relevant ones
		local prio = {3,5,4,6}
		diffsList = {}

		diffsList[#diffsList + 1] = {nil,LR.Always}

		for i=1,#prio do
			local diff = prio[i]
			local name = LR.diff_name[diff]
			diffsList[#diffsList + 1] = {diff,name}
		end
	end

	local SetupFrameWidth = 560
	local SetupFrameHeight = 730

	---@class SetupFrame: ELibPopup
	---@field data ReminderData
	local SetupFrame = ELib:Popup(" "):Size(SetupFrameWidth,SetupFrameHeight):OnShow(function(self)
		if not self.data then
			self.data = {}
		end

		if self.Update then
			self:Update(true)
		end
		if self.QuickList and VMRT.Reminder.HistoryCheck then
			self.QuickList:Show()
		end
	end)
	module.SetupFrame = SetupFrame

	SetupFrame:SetClampedToScreen(false)
	SetupFrame.title:SetPoint("TOPLEFT",SetupFrame,"TOPLEFT",10,-5)
	SetupFrame.title:SetPoint("BOTTOMRIGHT",SetupFrame,"TOPRIGHT",-15,-10)
	SetupFrame.title:SetDrawLayer("BACKGROUND",7)
	ELib:Border(SetupFrame,1,.24,.25,.30,1,nil,3)

	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SetupFrame,"TOPRIGHT",0,-45):SetVertexColor(0.13,0.13,0.13,0.3)--title background
	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,-20):Point("TOPRIGHT",SetupFrame,"TOPRIGHT",0,-20)--line between title and scroll frames
	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,-45):Point("TOPRIGHT",SetupFrame,"TOPRIGHT",0,-45)--line between title and scroll frames

	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame,"BOTTOMLEFT",0,32):Point("TOPRIGHT",SetupFrame,"BOTTOMRIGHT",0,32)--line between save button and scroll frames
	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame,"BOTTOMLEFT",0,32):Point("BOTTOMRIGHT",SetupFrame,"BOTTOMRIGHT",0,0):SetVertexColor(0.13,0.13,0.13,0.3)--save button background

	SetupFrame.tab = MLib:Tabs2(SetupFrame,0,LR["GENERAL"],LR["TRIGGERS"],LR["LOAD"],LR["OTHER"],LR["TEST"]):Point(0,-42):Size(SetupFrameWidth,SetupFrameHeight-78):SetTo(1)
	SetupFrame.tab:SetBackdropBorderColor(0,0,0,0)
	SetupFrame.tab:SetBackdropColor(0,0,0,0)

	SetupFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)
	SetupFrame.border:Hide()


	SetupFrame.tab.tabs[1].button.alert = MLib:CreateAlertIcon(SetupFrame.tab.tabs[1].button, nil, LR.Alert)
	SetupFrame.tab.tabs[1].button.alert:SetScale(.8)
	SetupFrame.tab.tabs[1].button.alert:SetPoint("CENTER",SetupFrame.tab.tabs[1].button,"TOPRIGHT",-10,-10)
	SetupFrame.tab.tabs[1].button.alert.Update = function(self)
		-- SetupFrame.GeneralAlerts - table with fileds that are the source of alerts
		local anyAlert = false
		local tooltip1 = {}
		local tooltip2 = {}
		for fieldName,level in next, SetupFrame.GeneralAlerts do
			if level == 2 then
				anyAlert = true
				tooltip2[#tooltip2+1] = " - ".. LR[fieldName]
			elseif level == 1 then
				anyAlert = true
				tooltip1[#tooltip1+1] = " - ".. LR[fieldName]
			end
		end
		if #tooltip1 > 0 then
			tinsert(tooltip1,1,{LR["Required fields must be filled:"],1,0,0,true})
		end
		if #tooltip2 > 0 then
			tinsert(tooltip2,1,{LR["Any of those fields must be filled:"],1,0,0,true})
		end
		tAppendAll(tooltip1,tooltip2)
		self.tooltip = tooltip1
		if anyAlert then
			self:Show()
		else
			self:Hide()
		end
		SetupFrame.SaveButton:Update()
	end
	SetupFrame.tab.tabs[1].button.alert:SetType(1)


	SetupFrame.tab.tabs[2].button.alert = MLib:CreateAlertIcon(SetupFrame.tab.tabs[2].button, nil, LR.Alert)
	SetupFrame.tab.tabs[2].button.alert:SetScale(.8)
	SetupFrame.tab.tabs[2].button.alert:SetPoint("CENTER",SetupFrame.tab.tabs[2].button,"TOPRIGHT",-10,-10)
	SetupFrame.tab.tabs[2].button.alert.Update = function(self)
		local anyAlert = false
		local tooltip = {}
		for i=1,#SetupFrame.data.triggers do
			local alerts = SetupFrame.TriggersAlerts[i]
			if alerts then
				local t1,t2 = {},{}
				for fieldName, alertType in next, alerts do
					if alertType == 1 then
						anyAlert = true
						t1[#t1+1] = " - ".. LR[fieldName]
					elseif alertType == 2 then
						anyAlert = true
						t2[#t2+1] = " - ".. LR[fieldName]
					end
				end
				if #t1 > 0 then
					tinsert(t1,1,{LR["Required fields must be filled:"],1,0,0,true})
				end
				if #t2 > 0 then
					tinsert(t2,1,{LR["Any of those fields must be filled:"],1,0,0,true})
				end
				tAppendAll(t1,t2)
				if #t1 > 0 then
					tooltip[#tooltip+1] = LR.Trigger .. i
					tAppendAll(tooltip,t1)
				end
			end
		end

	   self.tooltip = tooltip

		if anyAlert then
			self:Show()
		else
			self:Hide()
		end
		SetupFrame.SaveButton:Update()
	end
	SetupFrame.tab.tabs[2].button.alert:SetType(1)

	SetupFrame.tab.tabs[3].button.alert = MLib:CreateAlertIcon(SetupFrame.tab.tabs[3].button,LR.LoadAlert2,LR.LoadAlert1)
	SetupFrame.tab.tabs[3].button.alert:SetScale(.8)
	SetupFrame.tab.tabs[3].button.alert:SetPoint("CENTER",SetupFrame.tab.tabs[3].button,"TOPRIGHT",-10,-10)
	SetupFrame.tab.tabs[3].button.alert.Update = function(self)
		if not SetupFrame.data.boss and not SetupFrame.data.zoneID and not SetupFrame.data.diff then
			self:Show()
		else
			self:Hide()
		end
	end
	SetupFrame.tab.tabs[3].button.alert:SetType(2)
	SetupFrame.tab.tabs[3].button.alert.tooltip = LR.LoadAlert2


	local predefinedSnippets = {
		{
			name = "Example Frame Glow",
			data = {
				["glow"] = "{targetName1}",
				["triggers"] = {
					{
						["spellName"] = "Отражение заклинаний",
						["activeTime"] = 5,
						["event"] = 1,
						["eventCLEU"] = "SPELL_AURA_APPLIED",
					}, -- [1]
					{
						["event"] = 13,
						["invert"] = true,
						["spellID"] = 1022,
					}, -- [2]
				},
				["msg"] = "{spell:1022}BoP {targetName1} {timeLeft:0}",
				["duration"] = 0,
				["name"] = "Example Frame Glow",
				["comment"] = "Ремайндер будет подсвечивать цель 1го триггера до тех пор пока активен 1й триггер и способность из 2го триггера не на кд",

			},
		},
		{
			name = "Tindral Seeds Chat Spam",
			data = {
				["disabled"] = false,
				["duration"] = 0,
				["spamType"] = 2,
				["name"] = "SEEDS CHAT SPAM",
				["spamChannel"] = 2,
				["diff"] = 16,
				["boss"] = 2786,
				["spamMsg"] = "{trim:{cond:{status:2:{guid2}}=on}{rt4};{rt7}{/cond}}",
				["triggers"] = {
					{
						["activeTime"] = 6,
						["spellID"] = 423265,
						["event"] = 1,
						["eventCLEU"] = "SPELL_CAST_SUCCESS",
					}, -- [1]
					{
						["spellID"] = 430583,
						["event"] = 10,
						["targetUnit"] = "player",
					}, -- [2]
					{
						["targetUnit"] = "player",
						["andor"] = 3,
						["invert"] = true,
						["event"] = 10,
						["spellID"] = 430583,
					}, -- [3]
				},
				["comment"] = "Спамит крест если игрок еще не взял сид, если игрок взял сид то спамит треугольник"
			},

		},
		{
			name = "Tindral Roots P3 Chat Spam",
			data = {
				["duration"] = 5,
				["spamType"] = 2,
				["spamChannel"] = 2,
				["boss"] = 2786,
				["name"] = "[P3] roots para1",
				["notepat"] = "#para1",
				["spamMsg"] = "{rt1}{rt1}",
				["triggers"] = {
					{
						["eventCLEU"] = "SPELL_CAST_SUCCESS",
						["event"] = 1,
						["spellID"] = 424495,
					}, -- [1]
					{
						["event"] = 2,
						["pattFind"] = "3",
					}, -- [2]
				},
				["comment"] = "Спамит метку во время рутов на 3й фазе, ремайндер загружаеться по заметке #para1 и спамит первую метку(звезда).\n\nДанный ремайндер часть группы ремайндеров из 8ми для каждой метки должны быть такие же с загрузкой по заметке #para2, #para3 и т.д. и спаме в чат {rt2}{rt2}, {rt3}{rt3} и т.д."
			},
		},
		{
			name = "Fyrakk P1 Mythic Soak",
			data = {
				["msg"] = "SOAK LEFT",
				["duration"] = 4,
				["boss"] = 2677,
				["tts"] = "SOAK LEFT",
				["notepat"] = "#soakLeft",
				["diff"] = 16,
				["name"] = "[P1] SOAK LEFT",
				["triggers"] = {
					{
						["counter"] = "<3",
						["spellID"] = 426368,
						["event"] = 1,
						["eventCLEU"] = "SPELL_CAST_SUCCESS",
					}, -- [1]
				},
				["comment"] = "Ассайнит по заметке #soakLeft делить лево на мифик кругах на Фиракке.\n\nДанный ремайндер часть группы ремайндеров из 3х для каждого круга должны быть такие же с загрузкой по заметке #soakMid и #soakRight."
			},
		},
		{
			name = "Fyrakk P1 Push In",
			data = {
				["duration"] = 0,
				["boss"] = 2677,
				["diff"] = 16,
				["msg"] = "{health1} PUSH IN {timeLeft2:1}",
				["name"] = "[P1] PUSH IN",
				["triggers"] = {
					{
						["numberPercent"] = ">70",
						["event"] = 4,
						["targetUnit"] = "boss1",
					}, -- [1]
					{
						["activeTime"] = 15,
						["event"] = 3,
						["delayTime"] = "2:12",
					}, -- [2]
				},
				["comment"] = "Пока у босса больше 70% хп и до момента когда нужно перевести босса остаеться 15 секунд показывает процент хп босса и отсчет до таймера когда его нужно перевести"
			}
		},
		{
			name = "MRT Note Timers(for Viserio's assignments)",
			data = {
				["glow"] = "{glowUnit}",
				["msg"] = "{textNote1}",
				["duration"] = 6,
				["countdown"] = true,
				["copy"] = true,
				["tts"] = "{spellName1}",
				["isPersonal"] = true,
				["name"] = "MRT Note Timers",
				["triggers"] = {
					{
						["event"] = 17,
						["bwtimeleft"] = 6,
					},
				},
				["comment"] = LR["MRTNoteTimersComment"]
			},
		},
	}
	SetupFrame.SnippetsList = ELib:ScrollList(SetupFrame):LineHeight(20):FontSize(12):Size(200,SetupFrameHeight-300):Point("RIGHT","x","LEFT",-5,0):HideBorders()
	SetupFrame.SnippetsList.LINE_PADDING_LEFT = 1
	SetupFrame.SnippetsList.SCROLL_WIDTH = 12

	SetupFrame.SnippetsList.LINE_TEXTURE = "Interface\\Addons\\MRT\\media\\White"
	SetupFrame.SnippetsList.LINE_TEXTURE_IGNOREBLEND = true
	SetupFrame.SnippetsList.LINE_TEXTURE_HEIGHT = 20
	SetupFrame.SnippetsList.LINE_TEXTURE_COLOR_HL = {1,1,1,.5}
	SetupFrame.SnippetsList.LINE_TEXTURE_COLOR_P = {.6,.6,.6,.6}

	SetupFrame.SnippetsList.Frame.ScrollBar:Size(10,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	SetupFrame.SnippetsList.Frame.ScrollBar.thumb:SetHeight(100)
	ELib:Text(SetupFrame.SnippetsList,LR["Snippets"],16):Point("BOTTOM",SetupFrame.SnippetsList,"TOP",0,5):Color():Shadow():Outline()


	local background = CreateFrame("Frame",nil,SetupFrame.SnippetsList, BackdropTemplateMixin and "BackdropTemplate")
	background:SetBackdrop({bgFile="Interface\\Addons\\MRT\\media\\White"})
	background:SetBackdropColor(0.05,0.05,0.07,0.98)

	background:SetAllPoints(SetupFrame.SnippetsList)
	-- background:SetVertexColor(0.09,0.09,0.09,1)
	background:EnableMouse(true)
	background:RegisterForDrag("LeftButton")
	background:SetScript("OnDragStart", function(self)
		SetupFrame:StartMoving()
	end)
	background:SetScript("OnDragStop", function(self)
		SetupFrame:StopMovingOrSizing()
	end)
	ELib:Border(SetupFrame.SnippetsList,1,.24,.25,.30,1,nil,3)

	local function SnippetsListUpdateNames()
		SetupFrame.SnippetsList.L = {}


		for i,sData in ipairs(predefinedSnippets) do
			SetupFrame.SnippetsList.L[i] = sData.name
		end

		SetupFrame.SnippetsList.L[#SetupFrame.SnippetsList.L + 1] = "|cff00aaff"..LR.SaveCurrent

		for i,sData in ipairs(VMRT.Reminder.snippets) do
			tinsert(SetupFrame.SnippetsList.L, sData.name)
		end

		SetupFrame.SnippetsList:Update()
	end
	SetupFrame.SnippetsList.UpdateNames = SnippetsListUpdateNames

	function SetupFrame.SnippetsList:SetListValue(index)
		if index == #predefinedSnippets+1 then --Add
			local data = CopyTable(SetupFrame.data)
			data.token = nil

			tinsert(VMRT.Reminder.snippets, {
				name = data.name or "~no name",
				data = data
			})

			-- SetupFrame.SnippetsList.selected = index
			SnippetsListUpdateNames()
		else --select snippet
			if index > #predefinedSnippets then -- custom snippets
				index = index - #predefinedSnippets - 1
				local data = VMRT.Reminder.snippets[index].data
				SetupFrame.data = MRT.F.table_copy2(data)
				SetupFrame:Update(true)
			else -- predifenied snippets
				local data = predefinedSnippets[index].data
				SetupFrame.data = MRT.F.table_copy2(data)
				SetupFrame:Update(true)
			end
		end
	end
	function SetupFrame.SnippetsList:AdditionalLineClick()
		SetupFrame.SnippetsList.selected = 0
		SetupFrame.SnippetsList:Update()
	end

	local function ButtonIcon_OnEnter(self)
		if not self["tooltip"..(self.status or 1)] then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self["tooltip"..(self.status or 1)])
		GameTooltip:Show()
	end

	local function ButtonIcon_OnLeave(self)
		GameTooltip_Hide()
	end

	local function Button_Create(parent,size)
		if not size then size = 14 end
		local self = ELib:Button(parent,"",1):Size(20,20)
		self.texture = self:CreateTexture(nil,"ARTWORK")
		self.texture:SetPoint("CENTER")
		self.texture:SetSize(size,size)

		self.HighlightTexture = self:CreateTexture(nil,"BACKGROUND")
		self.HighlightTexture:SetColorTexture(1,1,1,.3)
		self.HighlightTexture:SetPoint("TOPLEFT")
		self.HighlightTexture:SetPoint("BOTTOMRIGHT")
		self:SetHighlightTexture(self.HighlightTexture)

		self:SetScript("OnEnter",ButtonIcon_OnEnter)
		self:SetScript("OnLeave",ButtonIcon_OnLeave)

		return self
	end

	local function DeleteSnippet(self)
		local parent = self:GetParent()
		local index = parent.index - #predefinedSnippets - 1
		tremove(VMRT.Reminder.snippets, index)
		SnippetsListUpdateNames()
	end

	function SetupFrame.SnippetsList:UpdateAdditional()
		for i=1,#self.List do
			local line = self.List[i]
			local index = line.index
			if index > #predefinedSnippets + 1 then
				if not line.delete then
					line.delete = Button_Create(line,20):Point("RIGHT",line,"RIGHT",0,0)
					line.delete:SetScript("OnClick",DeleteSnippet)
					line.delete.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")
					line.delete.background = line.delete:CreateTexture(nil,"BACKGROUND")
					line.delete.background:SetColorTexture(0.09,0.09,0.09,0.9)
					line.delete.background:SetPoint("TOPLEFT",line.delete,"TOPLEFT",0,0)
					line.delete.background:SetPoint("BOTTOMRIGHT",line.delete,"BOTTOMRIGHT",0,0)
				else
					line.delete:Show()
				end
			else
				if line.delete then
					line.delete:Hide()
				end
			end
		end
	end

	function SetupFrame.SnippetsList:HoverListValue(isHover,index)
		if not isHover then
			GameTooltip_Hide()
		else
			if index > #predefinedSnippets + 1 then -- custom snippets
				index = index - #predefinedSnippets - 1
				local data = VMRT.Reminder.snippets[index].data
				GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
				GameTooltip:AddLine(data.name)
				if data.comment then
					GameTooltip:AddLine(data.comment,1,1,1,true)
				end
				GameTooltip:Show()
			elseif index == #predefinedSnippets + 1 then -- add
				GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
				GameTooltip:AddLine(L.NoteAdd)
				GameTooltip:Show()
			else -- predefined snippets
				local data = predefinedSnippets[index].data
				GameTooltip:SetOwner(self,"ANCHOR_CURSOR")
				GameTooltip:AddLine(data.name)
				if data.comment then
					GameTooltip:AddLine(data.comment,1,1,1,true)
				end
				GameTooltip:Show()
			end
		end
	end

	if not VMRT.Reminder.showSnippets then
		-- SetupFrame.SnippetsList.HistoryBackground:Hide()
		SetupFrame.SnippetsList:Hide()
	else
		SetupFrame.SnippetsList:Show()
		SetupFrame.SnippetsList:UpdateNames()
	end

---------------------------------------
-- General Scroll
---------------------------------------

	SetupFrame.generalScrollFrame = ELib:ScrollFrame(SetupFrame.tab.tabs[1]):Size(SetupFrameWidth,SetupFrameHeight-78):Height(1000):Point("TOP",0,-4)

	SetupFrame.generalScrollFrame.C:EnableMouse(false)
	SetupFrame.generalScrollFrame:EnableMouse(false)
	SetupFrame.generalScrollFrame.mouseWheelRange = 120

	SetupFrame.generalScrollFrame.C:SetWidth(SetupFrameWidth - 18)
	ELib:Border(SetupFrame.generalScrollFrame,0)

	SetupFrame.generalScrollFrame.ScrollBar.slider:HookScript("OnValueChanged",function(self)
		local top1 = SetupFrame.generalScrollFrame.C:GetTop()
		local top2 = SetupFrame.nameplateGlow and SetupFrame.nameplateGlow:GetBottom()
		if top1 and top2 then
			SetupFrame.generalScrollFrame:Height(top1-top2+330)
		end
	end)

	SetupFrame.name = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(270,70):HideScrollOnNoScroll():Point("TOP",SetupFrame.generalScrollFrame.C,"TOP",30,-10):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.name = text
			SetupFrame.data.autoName = nil
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.title:SetText(SetupFrame.data.name or "")
		if SetupFrame.data.name then
			SetupFrame.name.leftText:Color()
		else
			SetupFrame.name.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.name.leftText = ELib:Text(SetupFrame.name,LR.Name,12):Point("TOPRIGHT",SetupFrame.name,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.msg = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,90,100):FontSize(14):Size(490,90):Point("TOP",SetupFrame.name,"BOTTOM",0,-40):Point("LEFT",SetupFrame,"LEFT",30,0):Point("RIGHT",SetupFrame,"RIGHT",-40,0):HideScrollOnNoScroll():OnChange(function(self,isUser)
		SetupFrame.msgPreview:SetText( module:FormatMsg(self:GetText():gsub("\n.+","..."):gsub("\\n.+","..."):gsub("||n.+","..."), {}) or "" )
		if isUser then
			local text, c = self:GetText():gsub("\n","\\n")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end

			SetupFrame.data.msg = text
			SetupFrame:UpdateAlerts()
		end
		if SetupFrame.data.msg then
			SetupFrame.msg.leftText:Color()
		else
			SetupFrame.msg.leftText:Color(.5,.5,.5)
		end
	end)

	do
		SetupFrame.msg.leftText = ELib:Text(SetupFrame.msg,LR.msg,12):Point("BOTTOMLEFT",SetupFrame.msg,"TOPLEFT",0,5):Right():Middle():Color(.5,.5,.5):Shadow()
	end

	SetupFrame.msgPreview = ELib:Text(SetupFrame.msg,"",20):Point("TOPLEFT",SetupFrame.msg,"BOTTOMLEFT",5,-35):Point("RIGHT",SetupFrame,-30,0):Size(0,30):Color()
	SetupFrame.msgPreview:SetMaxLines(1)

	SetupFrame.msgSize = ELib:DropDown(SetupFrame.generalScrollFrame.C,180,#module.datas.messageSize):Point("BOTTOMRIGHT",SetupFrame.msg,"TOPRIGHT",0,5):Size(170)
	do
		local msgSize_SetValue = function(_,size,ignoreFullUpdate)
			ELib:DropDownClose()
			SetupFrame.data.msgSize = size
			local val = MRT.F.table_find3(module.datas.messageSize,size,1)
			if val then
				SetupFrame.msgSize:SetText(val[2])
			else
				SetupFrame.msgSize:SetText("?")
			end
			if not ignoreFullUpdate then
				SetupFrame:Update()
			end
		end

		local List = SetupFrame.msgSize.List
		for j=1,#module.datas.messageSize do
			List[#List+1] = {
				text = module.datas.messageSize[j][2],
				arg1 = module.datas.messageSize[j][1],
				func = msgSize_SetValue,
			}
		end
		SetupFrame.msgSize.SetValue = msgSize_SetValue
	end
	SetupFrame.msgSize.leftText = ELib:Text(SetupFrame.msgSize,LR.msgSize,12):Point("RIGHT",SetupFrame.msgSize,"LEFT",-5,0):Right():Middle():Color():Shadow()


	local function AddTextToEditBox(self,text,mypos,noremove)
		local addedText = nil
		if not self then
			addedText = text
		else
			addedText = self.iconText
			if IsShiftKeyDown() then
				addedText = self.iconTextShift
			end
		end
		if not noremove then
			SetupFrame.msg:Insert("")
		end
		local txt = SetupFrame.msg:GetText()
		local pos = SetupFrame.msg.EditBox:GetCursorPosition()
		if not self and type(mypos)=='number' then
			pos = mypos
		end
		txt = string_sub (txt, 1 , pos) .. addedText .. string_sub (txt, pos+1)
		SetupFrame.msg:SetText(txt)
		local adjust = 0
		SetupFrame.msg.EditBox:SetCursorPosition(pos+addedText:len()-adjust)

		SetupFrame.data.msg = SetupFrame.msg:GetText()
		SetupFrame:Update()
	end

	-- PreUpdate function is defined later
	SetupFrame.replaceDropDown = ELib:DropDown(SetupFrame.generalScrollFrame.C,240,18):Size(220):Tooltip(LR["replaceDropDownTip"]):Point("TOPRIGHT",SetupFrame.msg,"BOTTOMRIGHT",0,-5):SetText(LR.AddTextReplacers)

	SetupFrame.ColorDropDown = ELib:DropDown(SetupFrame.generalScrollFrame.C,150,10):Point("TOPLEFT",SetupFrame.msg,"BOTTOMLEFT",0,-5):Size(130):SetText(LR["Text color"] )
	SetupFrame.ColorDropDown.list = {
		{L.NoteColorRed,"|cffff0000"},
		{L.NoteColorGreen,"|cff00ff00"},
		{L.NoteColorBlue,"|cff0000ff"},
		{L.NoteColorYellow,"|cffffff00"},
		{L.NoteColorPurple,"|cffff00ff"},
		{L.NoteColorAzure,"|cff00ffff"},
		{L.NoteColorBlack,"|cff000000"},
		{L.NoteColorGrey,"|cff808080"},
		{L.NoteColorRedSoft,"|cffee5555"},
		{L.NoteColorGreenSoft,"|cff55ee55"},
		{L.NoteColorBlueSoft,"|cff5555ee"},
		{"Lime","|cff80ff00"},
		{"Orange","|cffff8000"},
		{"Blue","|cff0080ff"},
	}
	local classNames = MRT.GDB.ClassList
	for i,class in ipairs(classNames) do
		local colorTable = RAID_CLASS_COLORS[class]
		if colorTable and type(colorTable)=="table" then
			SetupFrame.ColorDropDown.list[#SetupFrame.ColorDropDown.list + 1] = {L.classLocalizate[class] or class,"|c"..(colorTable.colorStr or "ffaaaaaa")}
		end
	end
	SetupFrame.ColorDropDown:SetScript("OnEnter",function (self)
		ELib.Tooltip.Show(self,"ANCHOR_LEFT",L.NoteColor,{L.NoteColorTooltip1,1,1,1,true},{L.NoteColorTooltip2,1,1,1,true})
	end)
	SetupFrame.ColorDropDown:SetScript("OnLeave",function ()
		ELib.Tooltip:Hide()
	end)
	function SetupFrame.ColorDropDown:SetValue(colorCode)
		ELib:DropDownClose()

		local selectedStart,selectedEnd = SetupFrame.msg:GetTextHighlight()
		colorCode = string.gsub(colorCode,"|","||")
		if selectedStart == selectedEnd then
			AddTextToEditBox(nil,colorCode.."||r",nil,true)
		else
			AddTextToEditBox(nil,"||r",selectedEnd,true)
			AddTextToEditBox(nil,colorCode,selectedStart,true)
		end
	end
	for i=1,#SetupFrame.ColorDropDown.list do
		local colorData = SetupFrame.ColorDropDown.list[i]
		SetupFrame.ColorDropDown.List[i] = {
			text = colorData[2]..colorData[1],
			func = SetupFrame.ColorDropDown.SetValue,
			justifyH = "CENTER",
			arg1 = colorData[2],
		}
	end
	SetupFrame.ColorDropDown.Lines = #SetupFrame.ColorDropDown.List

	SetupFrame.msg.colorButton = CreateFrame("Button",nil,SetupFrame.ColorDropDown)
	SetupFrame.msg.colorButton:SetPoint("LEFT", SetupFrame.ColorDropDown, "RIGHT", 5, 0)
	SetupFrame.msg.colorButton:SetSize(22,22)
	SetupFrame.msg.colorButton:SetScript("OnClick",function()
		if not ColorPickerFrame.SetupColorPickerAndShow then
			local nilFunc = MRT.NULLfunc
			local function changedCallback(restore)
				local r,g,b = ColorPickerFrame:GetColorRGB()
				local code = format("%02x%02x%02x",r*255,g*255,b*255)
				local hlstart,hlend = SetupFrame.msg:GetTextHighlight()
				if hlstart == hlend then
					SetupFrame.msg:SetText( "||cff"..code..SetupFrame.msg:GetText().."||r" )
				else
					local text = SetupFrame.msg:GetText()
					text = text:sub(1, hlend) .. "||r" .. text:sub(hlend+1)
					text = text:sub(1, hlstart) .. "||cff"..code .. text:sub(hlstart+1)
					SetupFrame.msg:SetText( text )
				end
				SetupFrame.msg.EditBox:GetScript("OnTextChanged")(SetupFrame.msg.EditBox,true)
			end
			ColorPickerFrame.func, ColorPickerFrame.cancelFunc, ColorPickerFrame.opacityFunc = nilFunc, nilFunc, nilFunc
			ColorPickerFrame:SetColorRGB(1,1,1)
			ColorPickerFrame.opacityFunc = changedCallback
			ColorPickerFrame.hasOpacity = false
			ColorPickerFrame:Show()
		else
			local info = {}
			info.r, info.g, info.b = 1,1,1
			info.opacity = 1
			info.hasOpacity = false
			info.swatchFunc = function()
				local btn = ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton or ColorPickerOkayButton
				if not MouseIsOver(btn) or IsMouseButtonDown() then return end
				local r,g,b = ColorPickerFrame:GetColorRGB()
				local code = format("%02x%02x%02x",r*255,g*255,b*255)
				local hlstart,hlend = SetupFrame.msg:GetTextHighlight()
				if hlstart == hlend then
					SetupFrame.msg:SetText( "||cff"..code..SetupFrame.msg:GetText().."||r" )
				else
					local text = SetupFrame.msg:GetText()
					text = text:sub(1, hlend) .. "||r" .. text:sub(hlend+1)
					text = text:sub(1, hlstart) .. "||cff"..code .. text:sub(hlstart+1)
					SetupFrame.msg:SetText( text )
				end
				SetupFrame.msg.EditBox:GetScript("OnTextChanged")(SetupFrame.msg.EditBox,true)
			end
			info.cancelFunc = function()
				local newR, newG, newB, newA = ColorPickerFrame:GetPreviousValues()
			end
			ColorPickerFrame:SetupColorPickerAndShow(info)
		end
	end)
	SetupFrame.msg.colorButton:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(LR["Select color in Color Picker"])
		GameTooltip:Show()
	end)
	SetupFrame.msg.colorButton:SetScript("OnLeave",function(self)
		GameTooltip_Hide()
	end)
	SetupFrame.msg.colorButton.Texture = SetupFrame.msg.colorButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.msg.colorButton.Texture:SetPoint("CENTER")
	SetupFrame.msg.colorButton.Texture:SetSize(20,20)
	SetupFrame.msg.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])

	SetupFrame.duration = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(270,20):Point("TOP",SetupFrame.msg,"BOTTOM",30,-70):Tooltip(LR.durationTip):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.duration = tonumber(self:GetText())
			SetupFrame:UpdateAlerts()
		end

		if SetupFrame.data.duration then
			self.leftText:Color()
		else
			self.leftText:Color(.5,.5,.5)
		end

		self:ExtraText(SetupFrame.data.duration == 0 and LR["Reminder is untimed"] or "")
	end)
	SetupFrame.duration.leftText = ELib:Text(SetupFrame.duration,LR.duration ,12):Point("RIGHT",SetupFrame.duration,"LEFT",-5,0):Right():Shadow():Color(.5,.5,.5)

	SetupFrame.durationReverse = ELib:Check(SetupFrame.generalScrollFrame.C,""):Tooltip(LR.durationReverseTip):Point("TOPLEFT",SetupFrame.duration,"BOTTOMLEFT",0,-5):OnClick(function(self)
		SetupFrame.data.durrev = not SetupFrame.data.durrev or nil
		SetupFrame:Update()
	end)
	SetupFrame.durationReverse.leftText = ELib:Text(SetupFrame.durationReverse,LR.durationReverse..":" ,12):Point("RIGHT",SetupFrame.durationReverse,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()


	SetupFrame.countdownCheck = ELib:Check(SetupFrame.generalScrollFrame.C,""):Tooltip(LR["For untimed reminders use {timeLeft} text replacer"]):Point("TOPLEFT",SetupFrame.durationReverse,"BOTTOMLEFT",0,-20):OnClick(function(self)
		SetupFrame.data.countdown = not SetupFrame.data.countdown
		SetupFrame:Update()
	end)
	SetupFrame.countdownCheck.leftText = ELib:Text(SetupFrame.countdownCheck,LR.countdown ,12):Point("RIGHT",SetupFrame.countdownCheck,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.countdownType = ELib:DropDown(SetupFrame.generalScrollFrame.C,60,#module.datas.countdownType):Size(245):Point("LEFT",SetupFrame.countdownCheck,"RIGHT",5,0)
	do
		local function countdownType_SetValue(_,arg1)
			SetupFrame.data.countdownType = arg1
			ELib:DropDownClose()
			local val = MRT.F.table_find3(module.datas.countdownType,arg1,1)
			if val then
				SetupFrame.countdownType:SetText(LR.CountdownFormat .. " ".. val[2])
			else
				SetupFrame.countdownType:SetText("?")
			end

			if SetupFrame.data.countdown then
				SetupFrame.countdownType.Text:SetTextColor(1,1,1)
				SetupFrame.countdownCheck.leftText:Color()
			else
				SetupFrame.countdownType.Text:SetTextColor(.5,.5,.5)
				SetupFrame.countdownCheck.leftText:Color(.5,.5,.5)
			end
		end

		local List = SetupFrame.countdownType.List
		for i=1,#module.datas.countdownType do
			List[#List+1] = {
				text = module.datas.countdownType[i][2],
				arg1 = module.datas.countdownType[i][1],
				func = countdownType_SetValue,
			}
		end
		SetupFrame.countdownType.SetValue = countdownType_SetValue
	end


	SetupFrame.barTicks = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(270,20):Point("TOPLEFT",SetupFrame.countdownCheck,"BOTTOMLEFT",0,-20):Tooltip(LR.barTicksTip):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.barTicks = self:GetText():trim()
			if SetupFrame.data.barTicks == "" then
				SetupFrame.data.barTicks = nil
			end
			SetupFrame:UpdateAlerts()
		end

		if SetupFrame.data.barTicks then
			self.leftText:Color()
		else
			self.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.barTicks.leftText = ELib:Text(SetupFrame.barTicks,LR.barTicks ,12):Point("RIGHT",SetupFrame.barTicks,"LEFT",-5,0):Right():Shadow():Color(.5,.5,.5)

	SetupFrame.barColor = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(100,20):Point("TOPLEFT",SetupFrame.barTicks,"BOTTOMLEFT",0,-5):Run(function(s)
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
			SetupFrame.data.barColor = nil
			SetupFrame.barColor.preview:Update()
		elseif text:find("^%x%x%x%x%x%x%x%x$") then
			SetupFrame.data.barColor = text
			SetupFrame.barColor.preview:Update()
			self:Disable()
		end
	end)

	SetupFrame.barColor.preview = ELib:Texture(SetupFrame.barColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.barColor.preview.Update = function(self)
		local t = self:GetParent():GetText()
		local at,rt,gt,bt = t:match("(..)(..)(..)(..)")
		if bt then
			local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
			self:SetColorTexture(r/255,g/255,b/255,a/255)
			SetupFrame.barColor.leftText:Color()
		else
			local color = "ffff4d4d"
			at,rt,gt,bt = color:match("(..)(..)(..)(..)")
			if bt then
				local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
				self:SetColorTexture(r/255,g/255,b/255,a/255)
				SetupFrame.barColor.leftText:Color(.5,.5,.5)
			end
		end
	end
	local checkers = ELib:Texture(SetupFrame.barColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.barColor.preview.checkers = checkers
	checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
	checkers:SetTexCoord(.25, 0, .5, .25)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.75)
	checkers:SetDrawLayer("BORDER", -7)
	checkers:Show()

	SetupFrame.barColor.colorButton = CreateFrame("Button",nil,SetupFrame.barColor)
	SetupFrame.barColor.colorButton:SetPoint("LEFT", SetupFrame.barColor.preview, "RIGHT", 5, 0)
	SetupFrame.barColor.colorButton:SetSize(24,24)
	SetupFrame.barColor.colorButton:SetScript("OnClick",function(self)
		local prevValue = SetupFrame.data.barColor

		local colorPalette = SetupFrame.data.barColor or "ffff4d4d"
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

					SetupFrame.data.barColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
					SetupFrame.barColor:Disable()
					SetupFrame.barColor.preview:Update()
				end,
				opacityFunc = function()
					local newR, newG, newB = ColorPickerFrame:GetColorRGB()
					local newA = ColorPickerFrame:GetColorAlpha()
					newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

					SetupFrame.data.barColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
					SetupFrame.barColor:Disable()
					SetupFrame.barColor.preview:Update()
				end,
				cancelFunc = function()
					SetupFrame.data.barColor = prevValue

					SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
					SetupFrame.barColor:Disable()
					SetupFrame.barColor.preview:Update()
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

				SetupFrame.data.barColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
				SetupFrame.barColor:Disable()
				SetupFrame.barColor.preview:Update()
			end

			ColorPickerFrame.opacityFunc = function()
				local newR, newG, newB = ColorPickerFrame:GetColorRGB()
				local newA = OpacitySliderFrame:GetValue()
				newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

				SetupFrame.data.barColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
				SetupFrame.barColor:Disable()
				SetupFrame.barColor.preview:Update()
			end

			ColorPickerFrame.cancelFunc = function()
				 SetupFrame.data.barColor = prevValue

				SetupFrame.barColor:SetText(SetupFrame.data.barColor or "")
				SetupFrame.barColor:Disable()
				SetupFrame.barColor.preview:Update()
			end

			ColorPickerFrame:Show()
		end
	end)
	SetupFrame.barColor.colorButton:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L.ReminderSelectColor)
		GameTooltip:Show()
	end)
	SetupFrame.barColor.colorButton:SetScript("OnLeave",function(self)
		GameTooltip_Hide()
	end)
	SetupFrame.barColor.colorButton.Texture = SetupFrame.barColor.colorButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.barColor.colorButton.Texture:SetPoint("CENTER")
	SetupFrame.barColor.colorButton.Texture:SetSize(20,20)
	SetupFrame.barColor.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])
	SetupFrame.barColor.leftText = ELib:Text(SetupFrame.barColor,LR.barColor,12):Point("RIGHT",SetupFrame.barColor,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()


	SetupFrame.barIcon = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(270,20):Point("TOPLEFT",SetupFrame.barColor,"BOTTOMLEFT",0,-5):Tooltip(LR.barIconTip):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.barIcon = self:GetText():trim()
			if SetupFrame.data.barIcon == "" then
				SetupFrame.data.barIcon = nil
			end
			SetupFrame:UpdateAlerts()
		end

		if SetupFrame.data.barIcon then
			self.leftText:Color()
			local icon = select(3,GetSpellInfo(SetupFrame.data.barIcon)) or 134400
			self.preview:Show()
			self.preview:SetTexture(icon)
		else
			self.leftText:Color(.5,.5,.5)
			self.preview:Hide()
		end
	end)
	SetupFrame.barIcon.leftText = ELib:Text(SetupFrame.barIcon,LR.barIcon ,12):Point("RIGHT",SetupFrame.barIcon,"LEFT",-5,0):Right():Shadow():Color(.5,.5,.5)
	SetupFrame.barIcon.preview = ELib:Texture(SetupFrame.barIcon,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(24,24)

	SetupFrame.voiceCountdown = ELib:DropDown(SetupFrame.generalScrollFrame.C,270,15):Size(270):Tooltip("Doesn't work for untimed reminders"):Point("TOPLEFT",SetupFrame.countdownCheck,"BOTTOMLEFT",0,-20)
	do
		local function voiceCountdown_SetValue(_,arg1)
			ELib:DropDownClose()
			SetupFrame.data.voiceCountdown = arg1
			local val = MRT.F.table_find3(module.datas.vcountdowns,arg1,1)
			if val then
				SetupFrame.voiceCountdown:SetText(val[2])
			else
				SetupFrame.voiceCountdown:SetText("-")
			end
			if SetupFrame.data.voiceCountdown then
				SetupFrame.voiceCountdown.leftText:Color()
			else
				SetupFrame.voiceCountdown.leftText:Color(.5,.5,.5)
			end
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.voiceCountdown.SetValue = voiceCountdown_SetValue
		local countdowns = module.datas.vcountdowns
		local List = SetupFrame.voiceCountdown.List
		for i=1,#countdowns do
			List[#List+1] = {
				text = countdowns[i][2],
				arg1 = countdowns[i][1],
				func = voiceCountdown_SetValue,
			}
		end
		SetupFrame.voiceCountdown.leftText = ELib:Text(SetupFrame.voiceCountdown,LR.voiceCountdown,12):Point("RIGHT",SetupFrame.voiceCountdown,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	end


	SetupFrame.voiceCountdown.testButton = MLib:Button(SetupFrame.voiceCountdown):Size(20,20):Point("LEFT",SetupFrame.voiceCountdown,"RIGHT",5,0):Tooltip("Play Countdown"):OnClick(function()
		if SetupFrame.data.voiceCountdown then
			local soundTemplate = module.datas.vcdsounds[ SetupFrame.data.voiceCountdown ]
			if soundTemplate then
				for i=1,5 do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = ScheduleTimer(PlaySoundFile, 6-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
				end
			end
		end
	end)
	SetupFrame.voiceCountdown.testButton.background = SetupFrame.voiceCountdown.testButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.voiceCountdown.testButton.background:SetPoint("CENTER")
	SetupFrame.voiceCountdown.testButton.background:SetSize(16,16)
	SetupFrame.voiceCountdown.testButton.background:SetAtlas("common-icon-forwardarrow")
	SetupFrame.voiceCountdown.testButton.background:SetDesaturated(true)


	SetupFrame.sound = ELib:DropDown(SetupFrame.generalScrollFrame.C,270,15):Size(220):Point("TOPLEFT",SetupFrame.voiceCountdown,"BOTTOMLEFT",0,-5)
	do
		local function soundList_SetValue(_,arg1)
			SetupFrame.data.sound = arg1
			ELib:DropDownClose()

			SetupFrame.sound:SetText("-")
			if SetupFrame.data.sound then
				local any = false
				local sound = SetupFrame.data.sound
				for i=1,#soundsList do
					local sound2 = soundsList[i][1]
					if type(sound) == "string" and type(sound2) == "string" and sound2:lower() == sound:lower() or sound2 == sound then
						SetupFrame.sound:SetText(soundsList[i][2])
						any = true
						break
					end
				end
				if not any then
					SetupFrame.sound:SetText("..." .. (MRT.F.utf8sub(SetupFrame.data.sound, -40, -5)))
				end
			end

			if SetupFrame.data.sound then
				SetupFrame.sound.leftText:Color()
			else
				SetupFrame.sound.leftText:Color(.5,.5,.5)
			end
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.sound.SetValue = soundList_SetValue

		local List = SetupFrame.sound.List
		for i=1,#soundsList do
			List[#List+1] = {
				text = soundsList[i][2],
				arg1 = soundsList[i][1],
				func = soundList_SetValue,
			}
		end
		SetupFrame.sound.leftText = ELib:Text(SetupFrame.sound,LR.sound,12):Point("RIGHT",SetupFrame.sound,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	end

	SetupFrame.sound_delay = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(45,20):Point("LEFT",SetupFrame.sound,"RIGHT",5,0):Tooltip(LR["sound_delayTip2"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.sound_delay = tonumber(self:GetText())
			-- SetupFrame:UpdateAlerts()
		end
	end)

	SetupFrame.sound.testButton = MLib:Button(SetupFrame.sound):Size(20,20):Point("LEFT",SetupFrame.sound_delay,"RIGHT",5,0):Tooltip("Play Sound"):OnClick(function()
		if SetupFrame.data.sound then
			if VMRT.Reminder.disableSound then
				prettyPrint("Sound is disabled")
			else
				pcall(PlaySoundFile,SetupFrame.data.sound, "Master")
			end
		end
	end)
	SetupFrame.sound.testButton.background = SetupFrame.sound.testButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.sound.testButton.background:SetPoint("CENTER")
	SetupFrame.sound.testButton.background:SetSize(16,16)
	SetupFrame.sound.testButton.background:SetAtlas("common-icon-forwardarrow")
	SetupFrame.sound.testButton.background:SetDesaturated(true)

	SetupFrame.soundOnHide = ELib:DropDown(SetupFrame.generalScrollFrame.C,220,15):Size(220):Point("TOPLEFT",SetupFrame.sound,"BOTTOMLEFT",0,-5)
	do
		local function soundList_SetValue(_,arg1)
			SetupFrame.data.soundOnHide = arg1
			ELib:DropDownClose()

			SetupFrame.soundOnHide:SetText("-")
			if SetupFrame.data.soundOnHide then
				local any = false
				local sound = SetupFrame.data.soundOnHide
				for i=1,#soundsList do
					local sound2 = soundsList[i][1]
					if type(sound) == "string" and type(sound2) == "string" and sound2:lower() == sound:lower() or sound2 == sound then
						SetupFrame.soundOnHide:SetText(soundsList[i][2])
						any = true
						break
					end
				end
				if not any then
					SetupFrame.soundOnHide:SetText("..." .. (MRT.F.utf8sub(SetupFrame.data.soundOnHide, -40, -5)))
				end
			end

			if SetupFrame.data.soundOnHide then
				SetupFrame.soundOnHide.leftText:Color()
			else
				SetupFrame.soundOnHide.leftText:Color(.5,.5,.5)
			end
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.soundOnHide.SetValue = soundList_SetValue

		local List = SetupFrame.soundOnHide.List
		for i=1,#soundsList do
			List[#List+1] = {
				text = soundsList[i][2],
				arg1 = soundsList[i][1],
				func = soundList_SetValue,
			}
		end
		SetupFrame.soundOnHide.leftText = ELib:Text(SetupFrame.soundOnHide,LR.soundOnHide,12):Point("RIGHT",SetupFrame.soundOnHide,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	end

	SetupFrame.soundOnHide_delay = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(45,20):Point("LEFT",SetupFrame.soundOnHide,"RIGHT",5,0):Tooltip(LR["sound_delayTip"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.soundOnHide_delay = tonumber(self:GetText())
			-- SetupFrame:UpdateAlerts()
		end
	end)

	SetupFrame.soundOnHide.testButton = MLib:Button(SetupFrame.soundOnHide):Size(20,20):Point("LEFT",SetupFrame.soundOnHide_delay,"RIGHT",5,0):Tooltip("Play Sound"):OnClick(function()
		if SetupFrame.data.soundOnHide then
			if VMRT.Reminder.disableSound then
				prettyPrint("Sound is disabled")
			else
				pcall(PlaySoundFile,SetupFrame.data.soundOnHide, "Master")
			end
		end
	end)
	SetupFrame.soundOnHide.testButton.background = SetupFrame.soundOnHide.testButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.soundOnHide.testButton.background:SetPoint("CENTER")
	SetupFrame.soundOnHide.testButton.background:SetSize(16,16)
	SetupFrame.soundOnHide.testButton.background:SetAtlas("common-icon-forwardarrow")
	SetupFrame.soundOnHide.testButton.background:SetDesaturated(true)

	SetupFrame.tts = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(220,70):HideScrollOnNoScroll():Tooltip(
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
	):Point("TOPLEFT",SetupFrame.soundOnHide,"BOTTOMLEFT",0,-5):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.tts = text
			SetupFrame:UpdateAlerts()
		end
		if SetupFrame.data.tts then
			SetupFrame.tts.leftText:Color()
		else
			SetupFrame.tts.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.tts.leftText = ELib:Text(SetupFrame.tts,LR.tts,12):Point("TOPRIGHT",SetupFrame.tts,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.tts_delay = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(45,20):Point("LEFT",SetupFrame.tts,"RIGHT",5,0):Tooltip(LR["sound_delayTip2"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.tts_delay = tonumber(self:GetText())
			-- SetupFrame:UpdateAlerts()
		end
	end)

	SetupFrame.tts.testButton = MLib:Button(SetupFrame.tts):Size(20,20):Point("TOPLEFT",SetupFrame.tts_delay,"TOPRIGHT",5,0):Tooltip("Play TTS"):OnClick(function()
		if VMRT.Reminder.disableSound then
			prettyPrint("Sound is disabled")
		elseif SetupFrame.data.tts then
			module:PlayTTS(SetupFrame.data.tts)
		end
	end)
	SetupFrame.tts.testButton.background = SetupFrame.tts.testButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.tts.testButton.background:SetPoint("CENTER")
	SetupFrame.tts.testButton.background:SetSize(16,16)
	SetupFrame.tts.testButton.background:SetAtlas("common-icon-forwardarrow")
	SetupFrame.tts.testButton.background:SetDesaturated(true)


	SetupFrame.ttsOnHide = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(220,70):HideScrollOnNoScroll():Tooltip(
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
	):Point("TOPLEFT",SetupFrame.tts,"BOTTOMLEFT",0,-5):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.ttsOnHide = text
			SetupFrame:UpdateAlerts()
		end
		if SetupFrame.data.ttsOnHide then
			SetupFrame.ttsOnHide.leftText:Color()
		else
			SetupFrame.ttsOnHide.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.ttsOnHide.leftText = ELib:Text(SetupFrame.ttsOnHide,LR.ttsOnHide,12):Point("TOPRIGHT",SetupFrame.ttsOnHide,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.ttsOnHide_delay = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(45,20):Point("LEFT",SetupFrame.ttsOnHide,"RIGHT",5,0):Tooltip(LR["sound_delayTip"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.ttsOnHide_delay = tonumber(self:GetText())
			-- SetupFrame:UpdateAlerts()
		end
	end)

	SetupFrame.ttsOnHide.testButton = MLib:Button(SetupFrame.ttsOnHide):Size(20,20):Point("TOPLEFT",SetupFrame.ttsOnHide_delay,"TOPRIGHT",5,0):Tooltip("Play TTS"):OnClick(function()
		if VMRT.Reminder.disableSound then
			prettyPrint("Sound is disabled")
		elseif SetupFrame.data.ttsOnHide then
			module:PlayTTS(SetupFrame.data.ttsOnHide)
		end
	end)
	SetupFrame.ttsOnHide.testButton.background = SetupFrame.ttsOnHide.testButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.ttsOnHide.testButton.background:SetPoint("CENTER")
	SetupFrame.ttsOnHide.testButton.background:SetSize(16,16)
	SetupFrame.ttsOnHide.testButton.background:SetAtlas("common-icon-forwardarrow")
	SetupFrame.ttsOnHide.testButton.background:SetDesaturated(true)


	SetupFrame.glow = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(270,70):HideScrollOnNoScroll():Point("TOPLEFT",SetupFrame.ttsOnHide,"BOTTOMLEFT",0,-20):Tooltip(LR["Player names to glow\nMay use many separated by\nspace comma or semicolomn"]):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.glow = text
			SetupFrame:UpdateAlerts()
		end

		if SetupFrame.data.glow then
			SetupFrame.glow.leftText:Color()
		else
			SetupFrame.glow.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.glow.leftText = ELib:Text(SetupFrame.glow,LR.glow,12):Point("TOPRIGHT",SetupFrame.glow,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowFrameColor = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(100,20):Point("TOPLEFT",SetupFrame.glow,"BOTTOMLEFT",0,-5):Run(function(s)
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
			SetupFrame.data.glowFrameColor = nil
			SetupFrame.glowFrameColor.preview:Update()
		elseif text:find("^%x%x%x%x%x%x%x%x$") then
			SetupFrame.data.glowFrameColor = text
			SetupFrame.glowFrameColor.preview:Update()
			self:Disable()
		end
	end)

	SetupFrame.glowFrameColor.preview = ELib:Texture(SetupFrame.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.glowFrameColor.preview.Update = function(self)
		local t = self:GetParent():GetText()
		local at,rt,gt,bt = t:match("(..)(..)(..)(..)")
		if bt then
			local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
			self:SetColorTexture(r/255,g/255,b/255,a/255)
			SetupFrame.glowFrameColor.leftText:Color()
		else
			local color = VMRT.Reminder.VisualSettings.Glow.Color
			at,rt,gt,bt = color:match("(..)(..)(..)(..)")
			if bt then
				local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
				self:SetColorTexture(r/255,g/255,b/255,a/255)
				SetupFrame.glowFrameColor.leftText:Color(.5,.5,.5)
			end
		end
	end
	local checkers = ELib:Texture(SetupFrame.glowFrameColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.glowFrameColor.preview.checkers = checkers
	checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
	checkers:SetTexCoord(.25, 0, .5, .25)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.75)
	checkers:SetDrawLayer("BORDER", -7)
	checkers:Show()

	SetupFrame.glowFrameColor.colorButton = CreateFrame("Button",nil,SetupFrame.glowFrameColor)
	SetupFrame.glowFrameColor.colorButton:SetPoint("LEFT", SetupFrame.glowFrameColor.preview, "RIGHT", 5, 0)
	SetupFrame.glowFrameColor.colorButton:SetSize(24,24)
	SetupFrame.glowFrameColor.colorButton:SetScript("OnClick",function(self)
		local prevValue = SetupFrame.data.glowFrameColor

		local colorPalette = SetupFrame.data.glowFrameColor or VMRT.Reminder.VisualSettings.Glow.Color
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

					SetupFrame.data.glowFrameColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
					SetupFrame.glowFrameColor:Disable()
					SetupFrame.glowFrameColor.preview:Update()
				end,
				opacityFunc = function()
					local newR, newG, newB = ColorPickerFrame:GetColorRGB()
					local newA = ColorPickerFrame:GetColorAlpha()
					newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

					SetupFrame.data.glowFrameColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
					SetupFrame.glowFrameColor:Disable()
					SetupFrame.glowFrameColor.preview:Update()
				end,
				cancelFunc = function()
					SetupFrame.data.glowFrameColor = prevValue

					SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
					SetupFrame.glowFrameColor:Disable()
					SetupFrame.glowFrameColor.preview:Update()
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

				SetupFrame.data.glowFrameColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
				SetupFrame.glowFrameColor:Disable()
				SetupFrame.glowFrameColor.preview:Update()
			end

			ColorPickerFrame.opacityFunc = function()
				local newR, newG, newB = ColorPickerFrame:GetColorRGB()
				local newA = OpacitySliderFrame:GetValue()
				newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

				SetupFrame.data.glowFrameColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
				SetupFrame.glowFrameColor:Disable()
				SetupFrame.glowFrameColor.preview:Update()
			end

			ColorPickerFrame.cancelFunc = function()
				 SetupFrame.data.glowFrameColor = prevValue

				SetupFrame.glowFrameColor:SetText(SetupFrame.data.glowFrameColor or "")
				SetupFrame.glowFrameColor:Disable()
				SetupFrame.glowFrameColor.preview:Update()
			end

			ColorPickerFrame:Show()
		end
	end)
	SetupFrame.glowFrameColor.colorButton:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L.ReminderSelectColor)
		GameTooltip:Show()
	end)
	SetupFrame.glowFrameColor.colorButton:SetScript("OnLeave",function(self)
		GameTooltip_Hide()
	end)
	SetupFrame.glowFrameColor.colorButton.Texture = SetupFrame.glowFrameColor.colorButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.glowFrameColor.colorButton.Texture:SetPoint("CENTER")
	SetupFrame.glowFrameColor.colorButton.Texture:SetSize(20,20)
	SetupFrame.glowFrameColor.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])
	SetupFrame.glowFrameColor.leftText = ELib:Text(SetupFrame.glowFrameColor,COLOR..":",12):Point("RIGHT",SetupFrame.glowFrameColor,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.spamType = ELib:DropDown(SetupFrame.generalScrollFrame.C,270,#spamTypes):Size(270):Point("TOPLEFT",SetupFrame.glowFrameColor,"BOTTOMLEFT",0,-20)
	do
		local function spamTypeList_SetValue(_,arg1)
			SetupFrame.data.spamType = arg1
			ELib:DropDownClose()

			SetupFrame.spamType:SetText("|cff808080-|r")
			for i=1,#spamTypes do
				if spamTypes[i][1] == SetupFrame.data.spamType then
					SetupFrame.spamType:SetText(spamTypes[i][2])
					break
				end
			end
			if SetupFrame.data.spamType then
				SetupFrame.spamType.leftText:Color()
			else
				SetupFrame.spamType.leftText:Color(.5,.5,.5)
			end
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.spamType.SetValue = spamTypeList_SetValue

		local List = SetupFrame.spamType.List
		for i=1,#spamTypes do
			List[#List+1] = {
				text = spamTypes[i][2],
				arg1 = spamTypes[i][1],
				func = spamTypeList_SetValue,
			}
		end
	end
	SetupFrame.spamType.leftText = ELib:Text(SetupFrame.spamType,LR.SpamType,12):Point("RIGHT",SetupFrame.spamType,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.spamChannel = ELib:DropDown(SetupFrame.generalScrollFrame.C,150,#spamChannels):Size(270):Point("TOP",SetupFrame.spamType,"BOTTOM",0,-5)
	do
		local function spamTypeList_SetValue(_,arg1)
			SetupFrame.data.spamChannel = arg1
			ELib:DropDownClose()

			SetupFrame.spamChannel:SetText("|cff808080-|r")
			for i=1,#spamChannels do
				if spamChannels[i][1] == SetupFrame.data.spamChannel then
					SetupFrame.spamChannel:SetText(spamChannels[i][2])
					break
				end
			end

			if SetupFrame.data.spamChannel then
				SetupFrame.spamChannel.leftText:Color()
			else
				SetupFrame.spamChannel.leftText:Color(.5,.5,.5)
			end
			SetupFrame:UpdateAlerts()
		end
		SetupFrame.spamChannel.SetValue = spamTypeList_SetValue

		local List = SetupFrame.spamChannel.List
		for i=1,#spamChannels do
			List[#List+1] = {
				text = spamChannels[i][2],
				arg1 = spamChannels[i][1],
				func = spamTypeList_SetValue,
			}
		end
	end
	SetupFrame.spamChannel.leftText = ELib:Text(SetupFrame.spamChannel,LR.SpamChannel,12):Point("RIGHT",SetupFrame.spamChannel,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.spamMsg = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(270,70):HideScrollOnNoScroll():Point("TOP",SetupFrame.spamChannel,"BOTTOM",0,-5):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.spamMsg = text
			SetupFrame:UpdateAlerts()
		end
		if SetupFrame.data.spamMsg then
			SetupFrame.spamMsg.leftText:Color()
		else
			SetupFrame.spamMsg.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.spamMsg.leftText = ELib:Text(SetupFrame.spamMsg,LR.spamMsg,12):Point("TOPRIGHT",SetupFrame.spamMsg,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()


	SetupFrame.WAmsg = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,100):FontSize(14):Size(270,70):Point("TOPLEFT",SetupFrame.spamMsg,"BOTTOMLEFT",0,-20):HideScrollOnNoScroll():OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.WAmsg = text
			SetupFrame:UpdateAlerts()
		end
		if SetupFrame.data.WAmsg then
			SetupFrame.WAmsg.leftText:Color()
		else
			SetupFrame.WAmsg.leftText:Color(.5,.5,.5)
		end
	end):Tooltip(LR.WAmsgTip)
	SetupFrame.WAmsg.leftText = ELib:Text(SetupFrame.WAmsg,LR.WAmsg,12):Point("TOPRIGHT",SetupFrame.WAmsg,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()



	SetupFrame.addOptionsList = ELib:DropDown(SetupFrame.generalScrollFrame.C,250,5):Size(270):Point("TOPLEFT",SetupFrame.WAmsg,"BOTTOMLEFT",0,-20)
	SetupFrame.addOptionsList.leftText = ELib:Text(SetupFrame.addOptionsList,LR["AdditionalOptions"],12):Point("RIGHT",SetupFrame.addOptionsList,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	do
		local function addOptionsList_SetValue(_,arg1)
			SetupFrame.data[arg1] = not SetupFrame.data[arg1]
			SetupFrame.addOptionsList:Update()
			SetupFrame.addOptionsList.Button:Click()
			SetupFrame.addOptionsList.Button:Click()
		end

		function SetupFrame.addOptionsList:Update()
			for i=1,#SetupFrame.addOptionsList.List do
				SetupFrame.addOptionsList.List[i].checkState = SetupFrame.data[SetupFrame.addOptionsList.List[i].arg1]
			end
			SetupFrame.addOptionsList:SetText((SetupFrame.data.copy and "DUPL " or "") .. (SetupFrame.data.norewrite and "NR " or "") .. (SetupFrame.data.dynamicdisable and "ND " or "") .. (SetupFrame.data.isPersonal and "P " or ""))
			if not SetupFrame.data.copy and not SetupFrame.data.isPersonal and not SetupFrame.data.norewrite and not SetupFrame.data.dynamicdisable then
				SetupFrame.addOptionsList.leftText:Color(.5,.5,.5)
			else
				SetupFrame.addOptionsList.leftText:Color()
			end
		end

		local function hoverFunc(self,hoverArg)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT",20)
			GameTooltip:AddLine(self:GetText())
			if hoverArg then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(hoverArg,1,1,1,true)
			end
			GameTooltip:Show()
		end

		local List = SetupFrame.addOptionsList.List
		List[#List+1] = {
			text = LR.copy,
			arg1 = "copy",
			checkable = true,
			checkState = SetupFrame.data.copy,
			func = addOptionsList_SetValue,
			hoverFunc = hoverFunc,
			hoverArg = LR.copyTip,
		}
		List[#List+1] = {
			text = LR.norewrite,
			arg1 = "norewrite",
			checkable = true,
			checkState = SetupFrame.data.norewrite,
			func = addOptionsList_SetValue,
			hoverFunc = hoverFunc,
			hoverArg = LR.norewriteTip,
		}
		List[#List+1] = {
			text = LR.dynamicdisable,
			arg1 = "dynamicdisable",
			checkable = true,
			checkState = SetupFrame.data.dynamicdisable,
			func = addOptionsList_SetValue,
			hoverFunc = hoverFunc,
			hoverArg = LR.dynamicdisableTip,
		}
		List[#List+1] = {
			text = LR.timeLineDisable,
			arg1 = "ignoreTimeline",
			checkable = true,
			checkState = SetupFrame.data.ignoreTimeline,
			hoverFunc = hoverFunc,
			func = addOptionsList_SetValue,
		}
		List[#List+1] = {
			text = LR.isPersonal,
			arg1 = "isPersonal",
			checkable = true,
			checkState = SetupFrame.data.isPersonal,
			func = addOptionsList_SetValue,
			hoverFunc = hoverFunc,
			hoverArg = LR.isPersonalTip,
		}
		tinsert(List,{text = CLOSE, func = function()
			ELib:DropDownClose()
		end})
	end

	SetupFrame.nameplateGlow = ELib:Check(SetupFrame.generalScrollFrame.C,""):Tooltip(LR["nameplateGlowTip"]):Point("TOPLEFT",SetupFrame.addOptionsList,"BOTTOMLEFT",0,-20):OnClick(function(self)
		SetupFrame.data.nameplateGlow = self:GetChecked()
		SetupFrame:Update()
	end)
	SetupFrame.nameplateGlow.leftText = ELib:Text(SetupFrame.nameplateGlow,LR["nameplateGlow"],12):Point("RIGHT",SetupFrame.nameplateGlow,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	function SetupFrame.nameplateGlow:ColorBorder(r,g,b,a)
		if type(r) == 'boolean' then
			if r then
				r,g,b,a = 1,0,0,1
			else
				r,g,b,a = 0.24,0.25,0.30,1
			end
		elseif not r then
			r,g,b,a = 0.24,0.25,0.30,1
		end
		ELib:Border(SetupFrame.nameplateGlow,1,r,g,b,a)
	end

	SetupFrame.glowOnlyText = ELib:Check(SetupFrame.generalScrollFrame.C,""):Tooltip(LR["glowOnlyTextTip"]):Point("TOPLEFT",SetupFrame.nameplateGlow,"BOTTOMLEFT",0,-5):OnClick(function(self)
		SetupFrame.data.glowOnlyText = self:GetChecked()
		SetupFrame:Update()
	end)
	SetupFrame.glowOnlyText.leftText = ELib:Text(SetupFrame.glowOnlyText,LR["glowOnlyText"],12):Point("RIGHT",SetupFrame.glowOnlyText,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()


	local nameplateTextTip = [[|cffffffff|cffffff00%tsize:|cff00ff00s|r|r - s is text size
|cffffff00%tposx:|cff00ff00x|r|r - x is x offset of text
|cffffff00%tposy:|cff00ff00y|r|r - y is y offset of text

|cffffff00%tpos:|cff00ff00a|r|r - a is anchor of text

Anchors:
Default - BOTTOMLEFT, TOPLEFT
2 - BOTTOM, TOP
3 - BOTTOMRIGHT, TOPRIGHT
4 - LEFT, RIGHT
5 - TOPRIGHT, BOTTOMRIGHT
6 - TOP, BOTTOM
7 - TOPLEFT, BOTTOMLEFT
8 - RIGHT, LEFT
9 - CENTER, "CENTER
]]
	SetupFrame.nameplateText = MLib:MultiEdit(SetupFrame.generalScrollFrame.C,20,80):FontSize(14):Size(270,70):HideScrollOnNoScroll():Tooltip(nameplateTextTip):Point("TOPLEFT",SetupFrame.glowOnlyText,"BOTTOMLEFT",0,-5):OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end
			SetupFrame.data.nameplateText = text
		end

		if SetupFrame.data.nameplateText then
			SetupFrame.nameplateText.leftText:Color()
		else
			SetupFrame.nameplateText.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.nameplateText.leftText = ELib:Text(SetupFrame.nameplateText,LR["On-Nameplate Text:"],12):Point("TOPRIGHT",SetupFrame.nameplateText,"TOPLEFT",-5,-5):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowColor = ELib:Edit(SetupFrame.nameplateText):Size(100,20):Point("TOPLEFT",SetupFrame.nameplateText,"BOTTOMLEFT",0,-5):Run(function(s)
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
			SetupFrame.data.glowColor = nil
			SetupFrame.glowColor.preview:Update()
		elseif text:find("^%x%x%x%x%x%x%x%x$") then
			SetupFrame.data.glowColor = text
			SetupFrame.glowColor.preview:Update()
			self:Disable()
		end
	end)

	SetupFrame.glowColor.preview = ELib:Texture(SetupFrame.glowColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.glowColor.preview.Update = function(self)
		local t = self:GetParent():GetText()
		local at,rt,gt,bt = t:match("(..)(..)(..)(..)")
		if bt then
			local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
			self:SetColorTexture(r/255,g/255,b/255,a/255)
			SetupFrame.glowColor.leftText:Color()
		else
			local color = "ffffffff"
			at,rt,gt,bt = color:match("(..)(..)(..)(..)")
			if bt then
				local r,g,b,a = tonumber(rt,16),tonumber(gt,16),tonumber(bt,16),tonumber(at,16)
				self:SetColorTexture(r/255,g/255,b/255,a/255)
				SetupFrame.glowColor.leftText:Color(.5,.5,.5)
			end
		end
	end
	local checkers = ELib:Texture(SetupFrame.glowColor,1,1,1,1):Point("LEFT",'x',"RIGHT",5,0):Size(40,20)
	SetupFrame.glowColor.preview.checkers = checkers
	checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
	checkers:SetTexCoord(.25, 0, .5, .25)
	checkers:SetDesaturated(true)
	checkers:SetVertexColor(1, 1, 1, 0.75)
	checkers:SetDrawLayer("BORDER", -7)
	checkers:Show()

	SetupFrame.glowColor.colorButton = CreateFrame("Button",nil,SetupFrame.glowColor)
	SetupFrame.glowColor.colorButton:SetPoint("LEFT", SetupFrame.glowColor.preview, "RIGHT", 5, 0)
	SetupFrame.glowColor.colorButton:SetSize(24,24)
	SetupFrame.glowColor.colorButton:SetScript("OnClick",function(self)
		local prevValue = SetupFrame.data.glowColor

		local colorPalette = SetupFrame.data.glowColor or "ffffffff"
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

					SetupFrame.data.glowColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
					SetupFrame.glowColor:Disable()
					SetupFrame.glowColor.preview:Update()
				end,
				opacityFunc = function()
					local newR, newG, newB = ColorPickerFrame:GetColorRGB()
					local newA = ColorPickerFrame:GetColorAlpha()
					newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

					SetupFrame.data.glowColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

					SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
					SetupFrame.glowColor:Disable()
					SetupFrame.glowColor.preview:Update()
				end,
				cancelFunc = function()
					SetupFrame.data.glowColor = prevValue

					SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
					SetupFrame.glowColor:Disable()
					SetupFrame.glowColor.preview:Update()
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

				SetupFrame.data.glowColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
				SetupFrame.glowColor:Disable()
				SetupFrame.glowColor.preview:Update()
			end

			ColorPickerFrame.opacityFunc = function()
				local newR, newG, newB = ColorPickerFrame:GetColorRGB()
				local newA = OpacitySliderFrame:GetValue()
				newA = COLORPICKER_INVERTED_ALPHA and 1 - newA or newA

				SetupFrame.data.glowColor = format("%02x%02x%02x%02x",newA*255,newR*255,newG*255,newB*255)

				SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
				SetupFrame.glowColor:Disable()
				SetupFrame.glowColor.preview:Update()
			end

			ColorPickerFrame.cancelFunc = function()
				 SetupFrame.data.glowColor = prevValue

				SetupFrame.glowColor:SetText(SetupFrame.data.glowColor or "")
				SetupFrame.glowColor:Disable()
				SetupFrame.glowColor.preview:Update()
			end

			ColorPickerFrame:Show()
		end
	end)
	SetupFrame.glowColor.colorButton:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(L.ReminderSelectColor)
		GameTooltip:Show()
	end)
	SetupFrame.glowColor.colorButton:SetScript("OnLeave",function(self)
		GameTooltip_Hide()
	end)
	SetupFrame.glowColor.colorButton.Texture = SetupFrame.glowColor.colorButton:CreateTexture(nil,"ARTWORK")
	SetupFrame.glowColor.colorButton.Texture:SetPoint("CENTER")
	SetupFrame.glowColor.colorButton.Texture:SetSize(20,20)
	SetupFrame.glowColor.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])
	SetupFrame.glowColor.leftText = ELib:Text(SetupFrame.glowColor,COLOR..":",12):Point("RIGHT",SetupFrame.glowColor,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()



	SetupFrame.glowType = ELib:DropDown(SetupFrame.generalScrollFrame.C,270,#module.datas.glowTypes):Size(270):Point("TOPLEFT",SetupFrame.glowColor,"BOTTOMLEFT",0,-5)
	do
		local function glowTypeDropDown_SetValue(_,glowType)
			SetupFrame.data.glowType = glowType
			ELib:DropDownClose()
			if SetupFrame.data.nameplateGlow then
				SetupFrame.glowOnlyText:Show()
				SetupFrame.nameplateText:Show()
				SetupFrame.glowType:Show()

				if SetupFrame.data.glowOnlyText then -- only text
					SetupFrame.glowType:Hide()
					SetupFrame.glowThick:Hide()
					SetupFrame.glowScale:Hide()
					SetupFrame.glowN:Hide()
					SetupFrame.glowImage:Hide()
					SetupFrame.glowColor:Hide()
					return
				else
					SetupFrame.glowColor:Show()
				end

				SetupFrame.glowImage:Shown(glowType == 7)
				SetupFrame.glowThick:Shown(glowType == 1 or glowType == 5)
				SetupFrame.glowScale:Shown(glowType == 3 or glowType == 7)
				SetupFrame.glowN:Shown(glowType == 1 or glowType == 8)
				SetupFrame.glowN.leftText:SetText(glowType == 8 and "HP, %:" or LR.glowN..":")
				SetupFrame.glowN:Tooltip(glowType == 8 and L.ReminderExample..": |cff00ff0035|r" or LR["glowNTip"])

			else
				SetupFrame.glowType:Hide()
				SetupFrame.glowImage:Hide()
				SetupFrame.glowOnlyText:Hide()
				SetupFrame.nameplateText:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			end

			for i=1,#module.datas.glowTypes do
				if module.datas.glowTypes[i][1] == glowType then
					SetupFrame.glowType:SetText(module.datas.glowTypes[i][2])
					break
				end
			end

			if SetupFrame.data.nameplateGlow then
				SetupFrame.glowType.leftText:Color()
			else
				SetupFrame.glowType.leftText:Color(.5,.5,.5)
			end

			SetupFrame:RepositionGlowFields()
		end

		local List = SetupFrame.glowType.List
		for i=1,#module.datas.glowTypes do
			List[#List+1] = {
				text = module.datas.glowTypes[i][2],
				arg1 = module.datas.glowTypes[i][1],
				func = glowTypeDropDown_SetValue,
			}
		end
		SetupFrame.glowType.SetValue = glowTypeDropDown_SetValue

	end
	SetupFrame.glowType.leftText = ELib:Text(SetupFrame.glowType,LR.glowType,12):Point("RIGHT",SetupFrame.glowType,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowThick = ELib:Edit(SetupFrame.generalScrollFrame.C,nil,true):Size(270,20):Point("TOPLEFT",SetupFrame.glowType,"BOTTOMLEFT",0,-5):Tooltip(LR["glowThickTip"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.glowThick = tonumber(self:GetText())
		end
		if SetupFrame.data.glowThick then
			SetupFrame.glowThick.leftText:Color()
		else
			SetupFrame.glowThick.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.glowThick.leftText = ELib:Text(SetupFrame.glowThick,LR.glowThick,12):Point("RIGHT",SetupFrame.glowThick,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowScale = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(270,20):Point("TOPLEFT",SetupFrame.glowThick,"BOTTOMLEFT",0,-5):Tooltip(LR["glowScaleTip"]):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.glowScale = tonumber(self:GetText())
		end
		if SetupFrame.data.glowScale then
			SetupFrame.glowScale.leftText:Color()
		else
			SetupFrame.glowScale.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.glowScale.leftText = ELib:Text(SetupFrame.glowScale,LR.glowScale,12):Point("RIGHT",SetupFrame.glowScale,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowN = ELib:Edit(SetupFrame.generalScrollFrame.C):Size(270,20):Point("TOPLEFT",SetupFrame.glowScale,"BOTTOMLEFT",0,-5):Tooltip(LR.glowNTip):OnChange(function(self,isUser)
		if isUser then
			SetupFrame.data.glowN = tonumber(self:GetText())
		end
		if SetupFrame.data.glowN then
			SetupFrame.glowN.leftText:Color()
		else
			SetupFrame.glowN.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.glowN.leftText = ELib:Text(SetupFrame.glowN,LR.glowN,12):Point("RIGHT",SetupFrame.glowN,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowImage = ELib:DropDown(SetupFrame.generalScrollFrame.C,270,#module.datas.glowImages):Size(270):Point("TOPLEFT",SetupFrame.glowN,"BOTTOMLEFT",0,-5)
	do
		local function glowImageDropDown_SetValue(_,glowImage)
			SetupFrame.glowImage.preview:SetTexture()

			local isCustomImg
			if glowImage == 0 or type(glowImage) == 'string' then
				isCustomImg = true
				glowImage = glowImage ~= 0 and glowImage or nil
			end
			SetupFrame.data.glowImage = glowImage
			local glow = MRT.F.table_find3(module.datas.glowImages,glowImage,1)
			if isCustomImg then
				SetupFrame.glowImage:SetText(LR.Manually)
				SetupFrame.glowImageCustom:SetText(glowImage or "")
				SetupFrame.glowImageCustom:Show()
			elseif glow then
				SetupFrame.glowImage:SetText(glow[2])
				SetupFrame.glowImageCustom:Hide()
			else
				SetupFrame.glowImage:SetText("Glow image "..(glowImage or 0))
				SetupFrame.glowImageCustom:Hide()
			end
			SetupFrame.glowImage.preview:Update()
			ELib:DropDownClose()

			if SetupFrame.data.glowImage and SetupFrame.data.glowImage ~= 0 then
				SetupFrame.glowImage.leftText:Color()
			else
				SetupFrame.glowImage.leftText:Color(.5,.5,.5)
			end
		end
		SetupFrame.glowImage.SetValue = glowImageDropDown_SetValue

		local List = SetupFrame.glowImage.List
		for i=1,#module.datas.glowImages do
			List[#List+1] = {
				text = module.datas.glowImages[i][2],
				arg1 = module.datas.glowImages[i][1],
				func = glowImageDropDown_SetValue,
				icon = module.datas.glowImages[i][3],
				iconcoord = module.datas.glowImages[i][6],
			}
		end
	end
	SetupFrame.glowImage.leftText = ELib:Text(SetupFrame.glowImage,LR.glowImage,12):Point("RIGHT",SetupFrame.glowImage,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.glowImage.preview = SetupFrame.glowImage:CreateTexture()
	SetupFrame.glowImage.preview:SetPoint("LEFT",SetupFrame.glowImage,"RIGHT",5,0)
	SetupFrame.glowImage.preview:SetSize(30,30)
	SetupFrame.glowImage.preview.Update = function(self)
		local glowImage = SetupFrame.data.glowImage
		if type(glowImage) == 'string' then
			if glowImage:find("^A:") then
				self:SetTexCoord(0,1,0,1)
				self:SetAtlas(glowImage:sub(3))
			else
				self:SetTexture(glowImage)
				self:SetTexCoord(0,1,0,1)
			end
		else
			glowImage = MRT.F.table_find3(module.datas.glowImages,glowImage,1)
			if glowImage then
				self:SetTexture(glowImage[3])
				if glowImage[6] then
					self:SetTexCoord(unpack(glowImage[6]))
				else
					self:SetTexCoord(0,1,0,1)
				end
			else
				self:SetTexture()
			end
		end
	end

	local customImageTip = [[Path to the file e.g. Interface\\AddOns\\ExRT_Reminder\\media\\textures\\badito.png
Or Atlas prefixed with 'A:' e.g. A:GarrMission_MissionIcon-Combat]]
	SetupFrame.glowImageCustom = ELib:Edit(SetupFrame.glowImage):Tooltip(customImageTip):Size(0,20):Point("TOP",SetupFrame.glowImage,"BOTTOM",0,-25):Point("LEFT",SetupFrame,"LEFT",30,0):Point("RIGHT",SetupFrame,"RIGHT",-40,0):OnChange(function(self,isUser)
		if isUser then
			local text = self:GetText()
			if text == "" then
				text = 0
			end
			SetupFrame.data.glowImage = text
			SetupFrame.glowImage.preview:Update()
		end
		if type(SetupFrame.data.glowImage) == "string" then
			SetupFrame.glowImageCustom.leftText:Color()
		else
			SetupFrame.glowImageCustom.leftText:Color(.5,.5,.5)
		end
		if SetupFrame.data.glowImage and SetupFrame.data.glowImage ~= 0 then
			SetupFrame.glowImage.leftText:Color()
		else
			SetupFrame.glowImage.leftText:Color(.5,.5,.5)
		end
	end)
	SetupFrame.glowImageCustom.leftText = ELib:Text(SetupFrame.glowImageCustom,LR.glowImageCustom,12):Point("BOTTOMLEFT",SetupFrame.glowImageCustom,"TOPLEFT",2,5):Right():Middle():Color(.5,.5,.5):Shadow()


	local glowFields = {"glowThick","glowScale","glowN","glowImage"}
	function SetupFrame:RepositionGlowFields()
		local prevField = "glowType"
		for i=1,#glowFields do
			local field = SetupFrame[glowFields[i]]
			if field:IsVisible() then
				field:Point("TOPLEFT",SetupFrame[prevField] or SetupFrame.nameplateText,"BOTTOMLEFT",0,-5)
				prevField = glowFields[i]
			end
		end
	end

	----------------------------------
	-- Triggers Scroll
	----------------------------------

	SetupFrame.triggersScrollFrame = ELib:ScrollFrame(SetupFrame.tab.tabs[2]):Point("TOP",0,-4):Size(SetupFrameWidth,SetupFrameHeight-78):Height(500)
	SetupFrame.triggersScrollFrame.mouseWheelRange = 120
	ELib:Border(SetupFrame.triggersScrollFrame,0)

	SetupFrame.triggersScrollFrame.triggers = {}

	local function TriggerButton_Update(self)
		if self.state == 1 then
			self.expandIcon.texture:SetTexCoord(0.375,0.4375,.5,0.625)
			self.sub:Hide()
			self.sub:SetHeight(1)
		elseif self.state == 2 then
			self.expandIcon.texture:SetTexCoord(0.25,0.3125,.5,0.625)
			self.sub:Show()
			self.sub:SetHeight(self.HEIGHT or 10)
		end

		local heightNow = 5 + 30 + (30 + (SetupFrame.triggersScrollFrame.generalOptions.sub:IsShown() and (SetupFrame.triggersScrollFrame.generalOptions.HEIGHT or 10) or 1))
		for _,t in next, SetupFrame.triggersScrollFrame.triggers do
			if t:IsShown() then
				local height = t.HEIGHT or 10
				heightNow = heightNow + 5 + 30 + (t.sub:IsShown() and height or 1)
			end
		end
		SetupFrame.triggersScrollFrame:Height(heightNow)
	end

	SetupFrame.TriggersAlerts = {}
	function SetupFrame.UpdateTriggerAlerts(button)
		local triggerData = SetupFrame.data.triggers[button.num]
		if not triggerData then
			return
		end
		SetupFrame.TriggersAlerts[button.num] = {}
		if module.C[triggerData.event] then
			local alertFields = module.C[triggerData.event].alertFields
			if alertFields then
				local alertType = 1
				local toHide
				for i,v in ipairs(alertFields) do
					if v == 0 then
						alertType = 2
						for j=i+1,#alertFields do
							if triggerData[ alertFields[j] ] then
								toHide = true
								break
							end
						end
					else
						local field = button[v]
						if (alertType == 1 and not triggerData[v]) or (alertType == 2 and not toHide) then
							SetupFrame.TriggersAlerts[button.num][v] = alertType
							if not field.alert then
								field.alert = MLib:CreateAlertIcon(field,LR.AlertFieldReq,LR.Alert,true)
							end
							field.alert:SetType(alertType)
							field.alert:Show()
						elseif field.alert then
							field.alert:Hide()
						end
					end
				end
			end
		end
		SetupFrame:UpdateHistoryCheck()
		SetupFrame.tab.tabs[2].button.alert:Update()
	end

	function SetupFrame:UpdateTriggerFieldsForEvent(button,event)
		for _,v in next, module.datas.fields do
			local b = button[v]
			b:Hide()
			if b.alert then
				b.alert:Hide()
			end
			if b.repText then
				if b.LeftText then
					b:LeftText(b.repText)
				elseif b.SetText then
					b:SetText(b.repText)
				end
				b.repText = nil
			end
			if b.repTipText then
				b.tooltipText = b.repTipText
				b.repTipText = nil
			end
		end
		local eventDB = module.C[event]
		if not eventDB then
			return
		end

		local height = 0
		local prev = "eventDropDown"
		for _,v in ipairs(eventDB.triggerSynqFields or eventDB.triggerFields) do
			height = height + 25
			button[v]:Point("TOPLEFT",button[prev],"BOTTOMLEFT",0,-5-(prev == "spellID" and 25 or 0))
			button[v]:Show()
			prev = v
			if v == "spellID" then
				height = height + 25
			end
		end
		button.HEIGHT = 30 + height
		button:Update()

		if eventDB.main_id == 1 then
			button.eventDropDown:SetText(module.C[1].lname)
			button.eventCLEU:SetValue(event,true)
		elseif event == 1 then
			button.eventDropDown:SetText(eventDB.lname)
			button.eventCLEU:SetValue(nil,true)
		else
			button.eventDropDown:SetText(eventDB.lname)
		end

		if eventDB.fieldNames then
			for v,text in next, eventDB.fieldNames do
				local b = button[v]
				if b.LeftText then
					b.repText = b.leftText:GetText()
					b:LeftText(text)
				elseif b.SetText then
					b.repText = b:GetText()
					b:SetText(text)
				end
			end
		end
		if eventDB.fieldTooltips then
			for v,text in next, eventDB.fieldTooltips do
				local b = button[v]
				b.repTipText = b.tooltipText or 0
				b.tooltipText = text
			end
		end

		if eventDB.help or eventDB.replaceres then
			if not button.eventDropDown.help then
				button.eventDropDown.help = MLib:CreateAlertIcon(button.eventDropDown,nil,nil,true)
			end
			button.eventDropDown.help:SetType(3)
			button.eventDropDown.help:Show()

			local text = eventDB.help or ""
			if eventDB.replaceres then
				text = text .. (text ~= "" and "\n" or "") .. LR["Available replacers:"]
				for _,v in ipairs(eventDB.replaceres) do
					text = text .. "\n|cffffffff{" .. v .. "}|r - ".. (eventDB.replaceres[v] or LR["r"..v])
				end
			end
			button.eventDropDown.help.tooltip = text
			button.eventDropDown.help.tooltipTitle = eventDB.lname
		elseif button.eventDropDown.help then
			button.eventDropDown.help:Hide()
		end

		button:UpdateTriggerAlerts()
	end

	local COLOR_BORDER_FULL = {CreateColor(0, 0, 0, 0.3), CreateColor(0, .5, 0, 0.3)}
	local COLOR_BORDER_EMPTY = {0,0,0,.3}
	local COLOR_BORDER_ALERT = {CreateColor(0, 0, 0, 0.3), CreateColor(.5, 0, 0, 0.3)}

	do
		local button = MLib:Button(SetupFrame.triggersScrollFrame.C,LR.TriggerOptionsGen):Size(520,25):OnClick(function(self)
			self.state = self.state == 1 and 2 or 1
			self:Update()
		end)
		SetupFrame.triggersScrollFrame.generalOptions = button

		button:Point("TOP",0,-5)

		local textObj = button:GetTextObj()
		textObj:ClearAllPoints()
		textObj:SetJustifyH("LEFT")
		textObj:SetPoint("LEFT",60,0)
		textObj:SetPoint("RIGHT",-10,0)
		textObj:SetPoint("TOP",0,0)
		textObj:SetPoint("BOTTOM",0,0)

		button.expandIcon = ELib:Icon(button,"Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128",18):Point("RIGHT",-5,0)

		button.sub = CreateFrame("Frame",nil,button)
		button.sub:Hide()
		button.sub:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-1)
		button.sub:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-1)
		ELib:Border(button.sub,1,0,0,0,1)
		button.sub:SetHeight(1)

		button.sub.back = button.sub:CreateTexture(nil,"BACKGROUND")
		button.sub.back:SetAllPoints()
		button.sub.back:SetColorTexture(.2,.2,.2,.9)

		button.HEIGHT = 5 + 25 * 6 + 10

		button.Update = TriggerButton_Update
		button.state = 2
		button:Update()


		local function CheckDelayTimeText(text)
			if not text or text == "" then
				return false
			else
				for c in string_gmatch(text, "[^ ,]+") do
					if not (tonumber(c) or c:find("%d+:%d+%.?%d*")) then
						return false
					end
				end
				return true
			end
		end

		SetupFrame.delay = ELib:Edit(button.sub):Size(270,20):Point(210,-5):Tooltip(LR.delayTip):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if not CheckDelayTimeText(text) then
					text = nil
				end
				SetupFrame.data.delay = text
				SetupFrame:UpdateAlerts()
			end
			if SetupFrame.data.delay then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end)
		SetupFrame.delay.Background:SetColorTexture(1,1,1,1)
		SetupFrame.delay.leftText = ELib:Text(SetupFrame.delay,LR.delayText,12):Point("RIGHT",SetupFrame.delay,"LEFT",-5,0):Right():Middle():Shadow()

		SetupFrame.hideTextChangedCheck = ELib:Check(button.sub,""):Point("TOPLEFT",SetupFrame.delay,"BOTTOMLEFT",0,-5):Left(5):Tooltip(LR.hideTextChangedTip):OnClick(function(self)
			SetupFrame.data.hideTextChanged = self:GetChecked() or nil
		end)
		SetupFrame.hideTextChangedCheck.leftText = ELib:Text(SetupFrame.hideTextChangedCheck,LR.hideTextChanged,12):Point("RIGHT",SetupFrame.hideTextChangedCheck,"LEFT",-5,0):Right():Middle():Shadow()

		SetupFrame.sametargets = ELib:Check(button.sub,""):Point("TOPLEFT",SetupFrame.hideTextChangedCheck,"BOTTOMLEFT",0,-5):Left(5):Tooltip(LR.sametargetsTip):OnClick(function(self)
			SetupFrame.data.sametargets = self:GetChecked() or nil
		end)
		SetupFrame.sametargets.leftText = ELib:Text(SetupFrame.sametargets,LR.sametargets,12):Point("RIGHT",SetupFrame.sametargets,"LEFT",-5,0):Right():Middle():Shadow()

		SetupFrame.specialTarget = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",SetupFrame.sametargets,"BOTTOMLEFT",0,-5):Tooltip(LR.specialTargetTip):OnChange(function(self,isUser)
			local text = self:GetText():trim()
			if text == "" then text = nil end
			if not text then
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			else
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			end
			if not isUser then return end
			SetupFrame.data.specialTarget = text
		end)
		SetupFrame.specialTarget.Background:SetColorTexture(1,1,1,1)
		SetupFrame.specialTarget.leftText = ELib:Text(SetupFrame.specialTarget,LR.specialTarget,12):Point("RIGHT",SetupFrame.specialTarget,"LEFT",-5,0):Right():Middle():Shadow()

		local nulltable = {}

		SetupFrame.extraCheck = MLib:MultiEdit(button.sub):Size(270,50):FontSize(14):Point("TOP",SetupFrame.specialTarget,"BOTTOM",0,-5):HideScrollOnNoScroll():OnChange(function(self,isUser)
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			local isPass, isValid = module:ExtraCheckParams(text,nulltable)
			if text == "" then
				SetupFrame.extraCheck.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			elseif not isValid then
				SetupFrame.extraCheck.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_ALERT))
			else
				SetupFrame.extraCheck.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			end
			if not isUser then return end
			if text == "" then text = nil end
			SetupFrame.data.extraCheck = text
		end)
		do
			SetupFrame.extraCheck:Tooltip("Similiar to \"Condition\" replacer but just the condition itself, e.g.:\n{counter1} > {counter2}\n{math:{counter1}+{counter2}} > 14")
			SetupFrame.extraCheck.leftText = ELib:Text(SetupFrame.extraCheck,LR["extraCheck"],12):Point("RIGHT",SetupFrame.extraCheck,"TOPLEFT",-7,-10):Shadow()
			SetupFrame.extraCheck.Background:SetColorTexture(1,1,1,1)
		end
	end

	local function GetTriggerButton(triggerNum)
		local button = SetupFrame.triggersScrollFrame.triggers[triggerNum]
		if button then
			return button
		end

		button = MLib:Button(SetupFrame.triggersScrollFrame.C,LR.Trigger..triggerNum):Size(520,30):OnClick(function(self)
			self.state = self.state == 1 and 2 or 1
			self:Update()
		end)
		SetupFrame.triggersScrollFrame.triggers[triggerNum] = button

		if triggerNum == 1 then
			--button:Point("TOP",0,-5)
			button:Point("TOP",SetupFrame.triggersScrollFrame.generalOptions.sub,"BOTTOM",0,-5)
		else
			button:Point("TOP",SetupFrame.triggersScrollFrame.triggers[triggerNum-1].sub,"BOTTOM",0,-5)
		end

		button.num = triggerNum

		local textObj = button:GetTextObj()
		textObj:ClearAllPoints()
		textObj:SetJustifyH("LEFT")
		textObj:SetPoint("LEFT",60,0)
		textObj:SetPoint("RIGHT",-10,0)
		textObj:SetPoint("TOP",0,0)
		textObj:SetPoint("BOTTOM",0,0)

		button.expandIcon = ELib:Icon(button,"Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128",18):Point("RIGHT",-5,0)

		button.sub = CreateFrame("Frame",nil,button)
		button.sub:Hide()
		button.sub:SetPoint("TOPLEFT",button,"BOTTOMLEFT",0,-1)
		button.sub:SetPoint("TOPRIGHT",button,"BOTTOMRIGHT",0,-1)
		ELib:Border(button.sub,1,0,0,0,1)
		button.sub:SetHeight(1)

		button.sub.back = button.sub:CreateTexture(nil,"BACKGROUND")
		button.sub.back:SetAllPoints()
		button.sub.back:SetColorTexture(.2,.2,.2,.9)

		button.Update = TriggerButton_Update
		button.state = triggerNum == 1 and 2 or 1
		button:Update()

		button.UpdateTriggerAlerts = SetupFrame.UpdateTriggerAlerts

		button.andor = MLib:Button(button,"AND"):Size(45,20):Point("LEFT",10,0):Shown(triggerNum ~= 1):OnClick(function(self)
			-- 1, 5, 2, 3, 4
			-- AND, AND+, OR, OR+, ignore
			self.state = self.state == 1 and 5 or self.state == 5 and 2 or self.state == 2 and 3 or self.state == 3 and 4 or 1
			self:Update()

			SetupFrame.data.triggers[button.num].andor = self.state

			self:GetScript("OnLeave")(self)
			self:GetScript("OnEnter")(self)
		end):OnEnter(function(self)
			local triggers = SetupFrame.data.triggers
			local triggersStr = ""
			local opened = false
			for i=#triggers,2,-1 do
				local trigger = triggers[i]
				if not trigger.andor or trigger.andor == 1 then
					triggersStr = " and "..(opened and "(" or "")..(trigger.invert and "not " or "")..i.. triggersStr
					opened = false
				elseif trigger.andor == 2 then
					triggersStr = " or "..(opened and "(" or "")..(trigger.invert and "not " or "")..i..triggersStr
					opened = false
				elseif trigger.andor == 3 then
					triggersStr = " or "..(trigger.invert and "not " or "")..i..(not opened and ")" or "").. triggersStr
					opened = true
				elseif trigger.andor == 5 then
					triggersStr = " and "..(trigger.invert and "not " or "")..i..(not opened and ")" or "").. triggersStr
					opened = true
				end
			end
			triggersStr = (opened and "(" or "")..(SetupFrame.data.triggers[1].invert and "not " or "").."1"..triggersStr

			if SetupFrame.data.triggers[button.num].andor == 4 then
				triggersStr = LR.TriggerTipIgnored:format(tostring(button.num)).."\n" .. triggersStr
			end

			ELib.Tooltip.Show(self,nil,triggersStr)
		end):OnLeave(function()
			GameTooltip_Hide()
		end)
		button.andor.state = 1
		button.andor.Update = function(self)
			if self.state == 1 then
				self:SetText("AND")
			elseif self.state == 2 then
				self:SetText("OR")
			elseif self.state == 3 then
				self:SetText("OR+")
			elseif self.state == 4 then
				self:SetText(" ")
			elseif self.state == 5 then
				self:SetText("AND+")
			end
		end

		button.remove = Button_Create(button):Point("RIGHT",button,"RIGHT",-30,0)
		button.remove:SetScript("OnClick",function()
			tremove(SetupFrame.data.triggers,button.num)
			SetupFrame:Update(SetupFrame.data)
			button:Update()
		end)
		button.remove.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
		button.remove.tooltip1 = DELETE

		button.tobottom = Button_Create(button):Point("RIGHT",button.remove,"LEFT",-2,0)
		button.tobottom:SetScript("OnClick",function()
			local triggers = SetupFrame.data.triggers
			if button.num < #triggers then
				triggers[button.num], triggers[button.num+1] = triggers[button.num+1], triggers[button.num]
				SetupFrame:Update(SetupFrame.data)
			end
		end)
		button.tobottom.texture:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		button.tobottom.texture:SetTexCoord(0.25,0.3125,.5,0.625)
		button.tobottom.texture:SetSize(24,24)

		button.totop = Button_Create(button):Point("RIGHT",button.tobottom,"LEFT",-2,0)
		button.totop:SetScript("OnClick",function()
			local triggers = SetupFrame.data.triggers
			if button.num > 1 then
				triggers[button.num], triggers[button.num-1] = triggers[button.num-1], triggers[button.num]
				SetupFrame:Update(SetupFrame.data)
			end
		end)
		button.totop.texture:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		button.totop.texture:SetTexCoord(0.25,0.3125,0.625,.5)
		button.totop.texture:SetSize(24,24)

		button.copy = Button_Create(button):Point("RIGHT",button.totop,"LEFT",-2,0)
		button.copy:SetScript("OnClick",function()
			local triggers = SetupFrame.data.triggers
			local copy = MRT.F.table_copy2(triggers[button.num])
			tinsert(triggers, button.num, copy)
			SetupFrame:Update(SetupFrame.data)
		end)
		button.copy.texture:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		button.copy.texture:SetTexCoord(0.125,0.1875,0.875,1)
		button.copy.texture:SetSize(24,24)
		button.copy.tooltip1 = LR["Copy trigger"]


		button.eventDropDown = ELib:DropDown(button.sub,220,#module.datas.events):AddText("|cffffd100"..LR["event"]):Size(270):Point("TOPLEFT",210,-5)
		do
			local function events_SetValue(_,arg1)
				SetupFrame.data.triggers[button.num].event = arg1

				if arg1 == 1 then
					-- if not SetupFrame.data.triggers[button.num].eventCLEU then
					-- 	SetupFrame.data.triggers[button.num].eventCLEU = "SPELL_CAST_SUCCESS"
					-- end
					SetupFrame:UpdateTriggerFieldsForEvent(button,SetupFrame.data.triggers[button.num].eventCLEU or 1)
				else
					SetupFrame:UpdateTriggerFieldsForEvent(button,arg1)
				end
				ELib:DropDownClose()
			end

			local function events_Tooltip(self,arg1)
				GameTooltip:SetOwner(self,"ANCHOR_RIGHT",10)
				GameTooltip:SetText(arg1,nil,nil,nil,nil,true)
				GameTooltip:Show()
			end
			local function events_Tooltip_Hide()
				GameTooltip_Hide()
			end

			local List = button.eventDropDown.List
			for i=1,#module.datas.events do
				local eventDB = module.C[ module.datas.events[i] ]
				local l = {
					text = eventDB.lname,
					arg1 = eventDB.id,
					func = events_SetValue,
				}
				if eventDB.tooltip then
					l.hoverFunc = events_Tooltip
					l.leaveFunc = events_Tooltip_Hide
					l.hoverArg = eventDB.tooltip
				end
				List[#List+1] = l
			end
		end
		button.eventDropDown.Background:SetColorTexture(1,1,1,1)
		button.eventDropDown.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))


		button.eventCLEU = ELib:DropDown(button.sub,220,#module.C[1].subEvents):AddText("|cffffd100"..LR.eventCLEU):Size(270):Point("TOPLEFT",button.eventDropDown,"BOTTOMLEFT",0,-5)
		do
			local function events_CLEU_SetValue(_,arg1,ignoreTriggerUpdates)
				SetupFrame.data.triggers[button.num].eventCLEU = arg1
				if not ignoreTriggerUpdates then
					SetupFrame:UpdateTriggerFieldsForEvent(button,arg1)
				end
				ELib:DropDownClose()

				if arg1 then
					local eventDB = module.C[arg1]
					if eventDB then
						button.eventCLEU:SetText(eventDB.lname)
					else
						button.eventCLEU:SetText("")
					end
				else
					button.eventCLEU:SetText("")
				end

				if arg1 then
					button.eventCLEU.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.eventCLEU.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
			end
			button.eventCLEU.SetValue = events_CLEU_SetValue

			local List = button.eventCLEU.List
			for i=1,#module.C[1].subEvents do
				local event = module.C[1].subEvents[i]
				List[#List+1] = {
					text = module.C[event] and module.C[event].lname or event,
					arg1 = event,
					func = events_CLEU_SetValue,
				}
			end
		end
		button.eventCLEU.Background:SetColorTexture(1,1,1,1)
		button.eventCLEU.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))

		button.sourceName = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.eventCLEU,"BOTTOMLEFT",0,-5):LeftText(LR.sourceName,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].sourceName = text
			end
			if SetupFrame.data.triggers[button.num].sourceName then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["UnitNameConditions"])
		button.sourceName.Background:SetColorTexture(1,1,1,1)

		button.sourceID = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.sourceName,"BOTTOMLEFT",0,-5):LeftText(LR.sourceID,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].sourceID = text
			end
			if SetupFrame.data.triggers[button.num].sourceID then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["MobIDCondition"])
		button.sourceID.Background:SetColorTexture(1,1,1,1)

		button.sourceUnit = ELib:DropDown(button.sub,220,-1):AddText("|cffffd100"..LR.sourceUnit):Size(270):Point("TOPLEFT",button.sourceID,"BOTTOMLEFT",0,-5)
		button.sourceUnit.Background:SetColorTexture(1,1,1,1)
		do
			local function unit_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].sourceUnit = arg1
				local val = MRT.F.table_find3(module.datas.units,arg1,1)
				if type(arg1) == "number" and arg1 < 0 then
					button.sourceUnit:SetText("Acvite GUID from trigger "..(-arg1))
				elseif val then
					button.sourceUnit:SetText(val[2] or val[1])
				else
					button.sourceUnit:SetText(arg1)
				end
				button:UpdateTriggerAlerts()

				if SetupFrame.data.triggers[button.num].sourceUnit then
					button.sourceUnit.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.sourceUnit.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
			end
			button.sourceUnit.SetValue = unit_SetValue

			local List = button.sourceUnit.List
			for i=1,#module.datas.units do
				List[#List+1] = {
					text = module.datas.units[i][2] or module.datas.units[i][1],
					arg1 = module.datas.units[i][1],
					func = unit_SetValue,
				}
			end

			local ListMaxDef = #List
			function button.sourceUnit:PreUpdate()
				for i=ListMaxDef+1,#List do
					List[i] = nil
				end
				local triggers = SetupFrame.data.triggers
				for i=1,#triggers do
					if i ~= triggerNum then
						List[#List+1] = {
							text = "Acvite GUID from trigger "..i,
							arg1 = -i,
							func = unit_SetValue,
						}
					end
				end
			end
		end

		button.sourceMark = ELib:DropDown(button.sub,220,#module.datas.marks):AddText("|cffffd100"..LR.sourceMark):Size(270):Point("TOPLEFT",button.sourceUnit,"BOTTOMLEFT",0,-5)
		button.sourceMark.Background:SetColorTexture(1,1,1,1)
		do
			local function mark_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].sourceMark = arg1
				local val = MRT.F.table_find3(module.datas.marks,arg1,1)
				if val then
					button.sourceMark:SetText(val[2])
				else
					button.sourceMark:SetText(arg1)
				end

				if SetupFrame.data.triggers[button.num].sourceMark then
					button.sourceMark.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.sourceMark.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
			end
			button.sourceMark.SetValue = mark_SetValue

			local List = button.sourceMark.List
			for i=1,#module.datas.marks do
				List[#List+1] = {
					text = module.datas.marks[i][2],
					arg1 = module.datas.marks[i][1],
					func = mark_SetValue,
				}
			end
		end

		button.targetName = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.sourceMark,"BOTTOMLEFT",0,-5):LeftText(LR.targetName,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].targetName = text
			end
			if SetupFrame.data.triggers[button.num].targetName then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["UnitNameConditions"])
		button.targetName.Background:SetColorTexture(1,1,1,1)

		button.targetID = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.targetName,"BOTTOMLEFT",0,-5):LeftText(LR.targetID,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].targetID = text
			end
			if SetupFrame.data.triggers[button.num].targetID then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["MobIDCondition"])
		button.targetID.Background:SetColorTexture(1,1,1,1)

		button.targetUnit = ELib:DropDown(button.sub,220,-1):AddText("|cffffd100"..LR.targetUnit):Size(270):Point("TOPLEFT",button.targetID,"BOTTOMLEFT",0,-5)
		button.targetUnit.Background:SetColorTexture(1,1,1,1)
		do
			local function unit_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].targetUnit = arg1
				local val = MRT.F.table_find3(module.datas.units,arg1,1)
				if type(arg1) == "number" and arg1 < 0 then
					button.targetUnit:SetText("Acvite GUID from trigger "..(-arg1))
				elseif val then
					button.targetUnit:SetText(val[2] or val[1])
				else
					button.targetUnit:SetText(arg1)
				end
				button:UpdateTriggerAlerts()

				if SetupFrame.data.triggers[button.num].targetUnit then
					button.targetUnit.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.targetUnit.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
			end
			button.targetUnit.SetValue = unit_SetValue

			local List = button.targetUnit.List
			for i=1,#module.datas.units do
				List[#List+1] = {
					text = module.datas.units[i][2] or module.datas.units[i][1],
					arg1 = module.datas.units[i][1],
					func = unit_SetValue,
				}
			end

			local ListMaxDef = #List
			function button.targetUnit:PreUpdate()
				for i=ListMaxDef+1,#List do
					List[i] = nil
				end
				local triggers = SetupFrame.data.triggers
				for i=1,#triggers do
					if i ~= triggerNum then
						List[#List+1] = {
							text = "Acvite GUID from trigger "..i,
							arg1 = -i,
							func = unit_SetValue,
						}
					end
				end
			end
		end

		button.targetMark = ELib:DropDown(button.sub,220,#module.datas.marks):AddText("|cffffd100"..LR.targetMark):Size(270):Point("TOPLEFT",button.targetUnit,"BOTTOMLEFT",0,-5)
		button.targetMark.Background:SetColorTexture(1,1,1,1)
		do
			local function mark_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].targetMark = arg1
				local val = MRT.F.table_find3(module.datas.marks,arg1,1)
				if val then
					button.targetMark:SetText(val[2])
				else
					button.targetMark:SetText(arg1)
				end

				if SetupFrame.data.triggers[button.num].targetMark then
					button.targetMark.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.targetMark.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
			end
			button.targetMark.SetValue = mark_SetValue

			local List = button.targetMark.List
			for i=1,#module.datas.marks do
				List[#List+1] = {
					text = module.datas.marks[i][2],
					arg1 = module.datas.marks[i][1],
					func = mark_SetValue,
				}
			end
		end

		button.targetRole = ELib:DropDown(button.sub,220,-1):AddText("|cffffd100"..LR.targetRole):Size(270):Point("TOPLEFT",button.targetMark,"BOTTOMLEFT",0,-5)
		button.targetRole.Background:SetColorTexture(1,1,1,1)
		do
			local function role_SetValue(_,arg1)
				SetupFrame.data.triggers[button.num].targetRole = arg1
				local val = MRT.F.table_find3(module.datas.rolesList,arg1,1)
				if type(arg1) == "number" and arg1 > 100 then
					local text = ""
					for i=1,#module.datas.rolesList do
						if bit_band(arg1-100,module.datas.rolesList[i][4]) > 0 then
							text = text..(text ~= "" and "," or "")..module.datas.rolesList[i][2]
						end
					end
					button.targetRole:SetText(text)
				elseif val then
					button.targetRole:SetText(val[2])
				elseif not arg1 then
					button.targetRole:SetText("")
				else
					if arg1 == 6 then arg1 = LR["NotTank"] end
					button.targetRole:SetText(arg1)
				end

				for i=1,#module.datas.rolesList do
					if (type(arg1) == "number" and arg1 >= 100 and bit_band(arg1-100,module.datas.rolesList[i][4]) > 0) or (type(arg1) == "number" and arg1 < 100 and arg1 == module.datas.rolesList[i][1]) then
						button.targetRole.List[i+1].checkState = true
					else
						button.targetRole.List[i+1].checkState = false
					end
				end

				if SetupFrame.data.triggers[button.num].targetRole then
					button.targetRole.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
				else
					button.targetRole.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
				end
				button.targetRole.Button:Click()
				button.targetRole.Button:Click()
			end
			button.targetRole.SetValue = role_SetValue

			local function role_SetCheck(self,checkState)
				local val = SetupFrame.data.triggers[button.num].targetRole or 0
				if val < 100 then
					local t = MRT.F.table_find3(module.datas.rolesList,val,1)
					val = 100 + (t and t[4] or 0)
				end
				if val >= 100 then
					val = val - 100
				end
				if checkState then
					val = bit_bor(val,self.arg2)
				else
					val = bit_bxor(val,self.arg2)
				end
				val = val + 100
				if val == 100 then val = nil end
				role_SetValue(nil,val)
			end

			local List = button.targetRole.List
			List[#List+1] = {
				text = "-",
				arg1 = nil,
				func = role_SetValue,
			}
			for i=1,#module.datas.rolesList do
				List[#List+1] = {
					text = module.datas.rolesList[i][2],
					arg1 = module.datas.rolesList[i][1],
					arg2 = module.datas.rolesList[i][4],
					func = role_SetValue,
					checkable = true,
					checkFunc = role_SetCheck,
				}
			end
			List[#List+1] = {
				text = LR["NotTank"],
				arg1 = 6,
				func = role_SetValue,
			}
		end

		button.spellID = ELib:Edit(button.sub,nil,true):Size(270,20):Point("TOPLEFT",button.targetRole,"BOTTOMLEFT",0,-5):LeftText(LR.spellID,12):OnChange(function(self,isUser)
			local spellID = tonumber(self:GetText())
			if isUser then
				SetupFrame.data.triggers[button.num].spellID = spellID
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].spellID then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
			button:UpdateSIDText()
		end):Tooltip(function(self)
			local t = SetupFrame.data.triggers[button.num]
 			if t.event == 1 and t.eventCLEU == "ENVIRONMENTAL_DAMAGE" then
				self.lockTooltipText = false
				return "1 - "..STRING_ENVIRONMENTAL_DAMAGE_FALLING.."\n2 - "..STRING_ENVIRONMENTAL_DAMAGE_DROWNING.."\n3 - "..STRING_ENVIRONMENTAL_DAMAGE_FATIGUE.."\n4 - "..STRING_ENVIRONMENTAL_DAMAGE_FIRE.."\n5 - "..STRING_ENVIRONMENTAL_DAMAGE_LAVA.."\n6 - "..STRING_ENVIRONMENTAL_DAMAGE_SLIME
			elseif t.event == 6 or t.event == 7 then
				self.lockTooltipText = false
				return LR.SpellIDBWTip
			else
				self.lockTooltipText = true
			end
 		end)
		button.spellID.Background:SetColorTexture(1,1,1,1)

		button.spellID.SIDtext = ELib:Text(button.spellID,"",14):Point("TOPLEFT",button.spellID,"BOTTOMLEFT",2,-3):Size(270-4,20):Left():Middle():Color()
		function button:UpdateSIDText()
			local t = SetupFrame.data.triggers[button.num]
			if t.spellID then
				local spellID = t.spellID
				if t.event == 1 and t.eventCLEU == "ENVIRONMENTAL_DAMAGE" then
					if spellID == 1 then spellID = 110122
					elseif spellID == 2 then spellID = 68730
					elseif spellID == 3 then spellID = 125024
					elseif spellID == 4 then spellID = 103795
 					elseif spellID == 5 then spellID = 119741
 					elseif spellID == 6 then spellID = 16456 end
				end

				local spellName,_,spellTexture = GetSpellInfo(spellID)
				self.spellID.SIDtext:SetText((spellTexture and "|T"..spellTexture..":20|t " or "")..(spellName or ""))
				return
			end
			if t.spellName then
				local spellName,_,spellTexture = GetSpellInfo(tonumber(t.spellName) or t.spellName)
				self.spellID.SIDtext:SetText((spellTexture and "|T"..spellTexture..":20|t " or "")..(spellName or ""))
				return
			end
			self.spellID.SIDtext:SetText("")
		end

		if AddonDB.EJ_DATA.encounterIDtoEJ then
			button.spellID.dropDown = ELib:DropDown(button.spellID,260,15):Size(20):Point("RIGHT",button.spellID,"RIGHT",0,0)
			button.spellID.dropDown:HideBorders()

			local function SpellIDDropDown_SetValue(_,spellID)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].spellID = spellID
				button.spellID:SetText(spellID)
				button.spellID:GetScript("OnTextChanged")(button.spellID,true)
			end

			local function SpellIDDropDown_hoverFunc(self,spellID)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT",20)
				GameTooltip:AddLine("SpellID: "..spellID) -- text is redunant
				GameTooltip:Show()
				GameTooltip:SetSpellByID(spellID)
			end

			local PA_IDS = {}
			local PA_Names = {}
			for i = 400000, 500000 do
				if C_UnitAuras.AuraIsPrivate(i) then
					local name = GetSpellName(i)
					PA_Names[name] = true
					PA_IDS[i] = true
				end
			end

			local List =  button.spellID.dropDown.List
			function button.spellID.dropDown:PreUpdate()
				local data = SetupFrame.data
				local boss = data.boss
				if not boss then return end
				local bossJID = AddonDB.EJ_DATA.encounterIDtoEJ[boss]
				if not bossJID then return end
				local stack, encounter, _, _, curSectionID, link, journalInstanceID = {}, EJ_GetEncounterInfo(bossJID)
				EJ_SelectInstance(journalInstanceID)
				local spellIDs = {}

				local oldDiff = EJ_GetDifficulty()
				local checkFirst = {data.diff or 0, 16, 15, 14, 17, 7, 6, 5, 4, 3, 9, 8, 23, 24, 2, 1}
				local iterate = 200
				local isValid
				while true do
					local diff = tremove(checkFirst,1)
					if not diff then
						if iterate > 0 then
							diff = iterate
							iterate = iterate - 1
						else
							break
						end
					end
					isValid = EJ_IsValidInstanceDifficulty(diff)
					if isValid then
						EJ_SetDifficulty(diff)
						tinsert(spellIDs,"List for difficulty: "..(LR.diff_name[diff] or diff))
						break
					end
				end


				-- https://warcraft.wiki.gg/wiki/API_C_EncounterJournal.GetSectionInfo

				repeat
					local info = C_EncounterJournal.GetSectionInfo(curSectionID)
					if not info.filteredByDifficulty then --info.headerType == 0 and
						local title = info.title
						if title and (title:lower():find("stage") or title:lower():find("intermission") or title:lower():find("фаза") or title:lower():find("смена фаз")) then
							tinsert(spellIDs,title)
						end
					end

					if not info.filteredByDifficulty and info.spellID and info.spellID > 0 then
						tinsert(spellIDs,info.spellID)
					end

					tinsert(stack, info.siblingSectionID)
					if not info.filteredByDifficulty then
						tinsert(stack, info.firstChildSectionID)
					end
					curSectionID = tremove(stack)
				until not curSectionID

				wipe(List)
				for j=1,#spellIDs do
					local ID = spellIDs[j]
					if type(ID) == "number" then
						local spellName,_,spellTexture = GetSpellInfo(ID)
						if spellName then
							local isPrivateAura = PA_IDS[ID] or PA_Names[spellName]

							List[#List+1] = {
								text = spellName .. (isPrivateAura and " |cff00ff00(Private Aura)|r" or ""),
								arg1 = ID,
								func = SpellIDDropDown_SetValue,
								icon = spellTexture or 134400,
								hoverFunc = SpellIDDropDown_hoverFunc,
								hoverArg = ID,
							}
						end
					else
						List[#List+1] = {
							text = ID,
							isTitle = true,
							justifyH = "CENTER",
						}
					end
				end
				-- restore diff
				EJ_SetDifficulty(oldDiff)
			end
		end

		button.spellName = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.spellID,"BOTTOMLEFT",0,-5):LeftText(LR.spellName,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].spellName = text
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].spellName then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
			button:UpdateSIDText()
		end)
		button.spellName.Background:SetColorTexture(1,1,1,1)

		button.extraSpellID = ELib:Edit(button.sub,nil,true):Size(270,20):Point("TOPLEFT",button.spellName,"BOTTOMLEFT",0,-5):LeftText(LR.extraSpellID,12):OnChange(function(self,isUser)
			if isUser then
				SetupFrame.data.triggers[button.num].extraSpellID = tonumber(self:GetText())
			end
			if SetupFrame.data.triggers[button.num].extraSpellID then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["extraSpellIDTip"])
		button.extraSpellID.Background:SetColorTexture(1,1,1,1)

		button.stacks = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.extraSpellID,"BOTTOMLEFT",0,-5):LeftText(LR.stacks,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].stacks = text
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].stacks then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(function(self)
				self.lockTooltipText = true
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(LR.MultiplyTip2)
				GameTooltip:AddLine(LR.MultiplyTip3)
				GameTooltip:AddLine(LR.MultiplyTip4)
				GameTooltip:AddLine(LR.MultiplyTip5)
				GameTooltip:AddLine(LR.MultiplyTip6)
				GameTooltip:AddLine(LR.MultiplyTip7)
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(LR["NumberCondition"])
				GameTooltip:Show()
			end)
		button.stacks.Background:SetColorTexture(1,1,1,1)

		button.numberPercent = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.stacks,"BOTTOMLEFT",0,-5):LeftText(LR.numberPercent,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].numberPercent = text
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].numberPercent then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(function(self)
				self.lockTooltipText = true
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(LR.MultiplyTip2)
				GameTooltip:AddLine(LR.MultiplyTip3)
				GameTooltip:AddLine(LR.MultiplyTip4b)
				GameTooltip:AddLine(LR.MultiplyTip6)
				GameTooltip:AddLine(LR.MultiplyTip7b)
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(LR["NumberCondition"])
				GameTooltip:Show()
			end)
		button.numberPercent.Background:SetColorTexture(1,1,1,1)

		button.pattFind = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.numberPercent,"BOTTOMLEFT",0,-5):LeftText(LR.pattFind,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].pattFind = text
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].pattFind then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(function(self)
			local t = SetupFrame.data.triggers[button.num]
 			if t.event == 1 and t.eventCLEU == "SPELL_MISSED" then
				self.lockTooltipText = false
				return LR.MissTypeLabelTooltip..":\nABSORB, BLOCK, DEFLECT, DODGE, EVADE, IMMUNE, MISS, PARRY, REFLECT, RESIST"
			else
				self.lockTooltipText = true
			end
			if self.tooltipText then
				self.lockTooltipText = false
				return self.tooltipText
			end
		end)
		button.pattFind.Background:SetColorTexture(1,1,1,1)

		button.bwtimeleft = ELib:Edit(button.sub,nil,true):Size(270,20):Point("TOPLEFT",button.pattFind,"BOTTOMLEFT",0,-5):LeftText(LR.bwtimeleft,12):OnChange(function(self,isUser)
			if isUser then
				SetupFrame.data.triggers[button.num].bwtimeleft = tonumber(self:GetText())
				button:UpdateTriggerAlerts()
			end
			if SetupFrame.data.triggers[button.num].bwtimeleft then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip("")
		button.bwtimeleft.Background:SetColorTexture(1,1,1,1)

		button.counter = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.bwtimeleft,"BOTTOMLEFT",0,-5):LeftText(LR.counter,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if text == "" then text = nil end
				SetupFrame.data.triggers[button.num].counter = text
			end
			if SetupFrame.data.triggers[button.num].counter then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(function(self)
				self.lockTooltipText = true
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
				GameTooltip:AddLine(LR.MultiplyTip2)
				GameTooltip:AddLine(LR.MultiplyTip3)
				GameTooltip:AddLine(LR.MultiplyTip4)
				GameTooltip:AddLine(LR.MultiplyTip5)
				GameTooltip:AddLine(LR.MultiplyTip6)
				GameTooltip:AddLine(LR.MultiplyTip7)
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(LR["NumberCondition"])
				GameTooltip:Show()
			end)
		button.counter.Background:SetColorTexture(1,1,1,1)

		button.cbehavior = ELib:DropDown(button.sub,220,#module.datas.counterBehavior):AddText("|cffffd100"..LR.cbehavior):Size(270):Point("TOPLEFT",button.counter,"BOTTOMLEFT",0,-5)
		button.cbehavior.Background:SetColorTexture(1,1,1,1)
		button.cbehavior.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
		do
			local function counterBehavior_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].cbehavior = arg1
				local val = MRT.F.table_find3(module.datas.counterBehavior,arg1,1)
				if val then
					button.cbehavior:SetText(val[2])
				else
					button.cbehavior:SetText(arg1)
				end
			end
			button.cbehavior.SetValue = counterBehavior_SetValue

			local function counterBehavior_Tooltip(self,arg1)
				GameTooltip:SetOwner(self,"ANCHOR_RIGHT")
				GameTooltip:SetText(arg1,nil,nil,nil,nil,true)
				GameTooltip:Show()
			end
			local function counterBehavior_Tooltip_Hide()
				GameTooltip_Hide()
			end

			local List = button.cbehavior.List
			for i=1,#module.datas.counterBehavior do
				List[#List+1] = {
					text = module.datas.counterBehavior[i][2],
					arg1 = module.datas.counterBehavior[i][1],
					func = counterBehavior_SetValue,
					hoverFunc = counterBehavior_Tooltip,
					leaveFunc = counterBehavior_Tooltip_Hide,
					hoverArg = module.datas.counterBehavior[i][3],
				}
			end
		end

		local function CheckDelayTimeText(text)
			if not text or (text == "") then
				return false
			else
				for c in string_gmatch(text, "[^ ,]+") do
					if not (tonumber(c) or c:find("%d+:%d+%.?%d*") or c:lower()=="note") then
						return false
					end
				end
				return true
			end
		end

		button.delayTime = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.counter,"BOTTOMLEFT",0,-5):LeftText(LR.delayTime,12):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText():trim()
				if not CheckDelayTimeText(text) then
					text = nil
				end
				SetupFrame.data.triggers[button.num].delayTime = text
			end
			if SetupFrame.data.triggers[button.num].delayTime then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR.delayTimeTip)
		button.delayTime.Background:SetColorTexture(1,1,1,1)

		button.activeTime = ELib:Edit(button.sub):Size(270,20):Point("TOPLEFT",button.delayTime,"BOTTOMLEFT",0,-5):LeftText(LR.activeTime,12):OnChange(function(self,isUser)
			if isUser then

				SetupFrame.data.triggers[button.num].activeTime = tonumber(self:GetText())
			end
			if SetupFrame.data.triggers[button.num].activeTime then
				self.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
			else
				self.Background:SetVertexColor(unpack(COLOR_BORDER_EMPTY))
			end
		end):Tooltip(LR["activeTimeTip"] )
		button.activeTime.Background:SetColorTexture(1,1,1,1)

		button.invert = ELib:Check(button.sub,""):Point("TOPLEFT",button.activeTime,"BOTTOMLEFT",0,-5):Left(5):OnClick(function(self)
			if self:GetChecked() then
				SetupFrame.data.triggers[button.num].invert = true
			else
				SetupFrame.data.triggers[button.num].invert = nil
			end
		end):Tooltip(LR["invertTip"])
		button.invert.leftText = ELib:Text(button.invert,LR.invert,12):Point("RIGHT",button.invert,"LEFT",-5,0):Shadow()

		button.guidunit = ELib:DropDown(button.sub,220,2):AddText("|cffffd100"..LR.guidunit):Size(270):Point("TOPLEFT",button.invert,"BOTTOMLEFT",0,-5):Tooltip(LR["guidunitTip"])
		button.guidunit.Background:SetColorTexture(1,1,1,1)
		button.guidunit.Background:SetGradient("HORIZONTAL",unpack(COLOR_BORDER_FULL))
		do
			local function guidunit_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.triggers[button.num].guidunit = arg1
				button.guidunit:SetText(arg1 == 1 and LR.Source or LR.Target)
			end
			button.guidunit.SetValue = guidunit_SetValue

			local List = button.guidunit.List
			List[#List+1] = {
				text = LR.Source,
				arg1 = 1,
				func = guidunit_SetValue,
			}
			List[#List+1] = {
				text = LR.Target,
				arg1 = nil,
				func = guidunit_SetValue,
			}
		end

		button.onlyPlayer = ELib:Check(button.sub,""):Point("TOPLEFT",button.activeTime,"BOTTOMLEFT",0,-5):Left(5):OnClick(function(self)
			if self:GetChecked() then
				SetupFrame.data.triggers[button.num].onlyPlayer = true
			else
				SetupFrame.data.triggers[button.num].onlyPlayer = nil
			end
		end):Tooltip(LR["onlyPlayerTip"])
		button.onlyPlayer.leftText = ELib:Text(button.onlyPlayer,LR.onlyPlayer,12):Point("RIGHT",button.onlyPlayer,"LEFT",-5,0):Shadow()

		button.HEIGHT = 10

		return button
	end

	SetupFrame.triggersScrollFrame.addTrigger = MLib:Button(SetupFrame.triggersScrollFrame.C,LR.AddTrigger):Size(520,20):Point("BOTTOM",0,5):OnClick(function(self)
		SetupFrame.data.triggers[#SetupFrame.data.triggers+1] = {
			event = 1,
		}
		SetupFrame:Update(SetupFrame.data)
	end)

	-------------------------
	-- Load Scroll
	-------------------------

	SetupFrame.loadScrollFrame = ELib:ScrollFrame(SetupFrame.tab.tabs[3]):Size(SetupFrameWidth,SetupFrameHeight-78):Point("TOP",0,-4)

	SetupFrame.loadScrollFrame.C:EnableMouse(false)
	SetupFrame.loadScrollFrame:EnableMouse(false)
	SetupFrame.loadScrollFrame.mouseWheelRange = 120

	SetupFrame.loadScrollFrame:Height(840)

	SetupFrame.loadScrollFrame.C:SetWidth(SetupFrameWidth - 18)
	ELib:Border(SetupFrame.loadScrollFrame,0)

	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-85):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-85)
	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-115):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-115)
	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-195):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-195)
	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-250):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-250)
	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-305):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-305)
	ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-585):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-585)
	if not module.PUBLIC then
		ELib:DecorationLine(SetupFrame.loadScrollFrame.C,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",0,-645):Point("TOPRIGHT",SetupFrame.loadScrollFrame.C,"TOPRIGHT",0,-645)
	end


	SetupFrame.bossList = ELib:DropDown(SetupFrame.loadScrollFrame.C,300,13):Tooltip(LR["Hold shift while opening to show full encounters list"]):Size(270):Point("TOP",SetupFrame.loadScrollFrame.C,"TOP",0,-10)
	do
		local function bossList_SetValue(_,encounterID)
			SetupFrame.data.boss = encounterID
			ELib:DropDownClose()

			if SetupFrame.data.boss then
				SetupFrame.bossList:SetText(LR.boss_name[SetupFrame.data.boss])
				SetupFrame.bossListRaw:SetText(SetupFrame.data.boss)
			else
				SetupFrame.bossList:SetText(LR.Always)
				SetupFrame.bossListRaw:SetText("")
			end
			if SetupFrame.data.boss then
				SetupFrame.bossList.leftText:Color()
			else
				SetupFrame.bossList.leftText:Color(.5,.5,.5)
			end
			SetupFrame.tab.tabs[3].button.alert:Update()
		end
		SetupFrame.bossList.SetValue = bossList_SetValue

		local List = SetupFrame.bossList.List

		function SetupFrame.bossList:PreUpdate()
			wipe(List)
			tinsert(List,1,{
				text = LR.Always,
				func = bossList_SetValue,
			})
			if VMRT.Reminder.lastEncounterID then
				local bossImg = AddonDB:GetBossPortrait(VMRT.Reminder.lastEncounterID)
				tinsert(List,2,{
					text = LR.boss_name[VMRT.Reminder.lastEncounterID] .. " |cff00ff00("..LR.LastPull..")|r",
					func = bossList_SetValue,
					arg1 = VMRT.Reminder.lastEncounterID,
					icon = bossImg,
					iconsize = 30,
				})
			end

			local encList
			if IsShiftKeyDown() then
				encList = AddonDB.EJ_DATA.encountersList
				self.Lines = 15
			else
				encList = AddonDB.EJ_DATA.encountersListShort
				self.Lines = nil
			end
			for i=1,#encList do
				local instance = encList[i]
				local subMenu = {}

				local zoneImg
				if AddonDB.EJ_DATA.instanceIDtoEJ[instance[1]] and EJ_GetInstanceInfo then
					zoneImg = select(6, EJ_GetInstanceInfo(AddonDB.EJ_DATA.instanceIDtoEJ[instance[1]]))
				end


				for j=#instance,2,-1 do
					local encounterID = instance[j]
					local bossImg = AddonDB:GetBossPortrait(encounterID)

					subMenu[#subMenu+1] = {
						text  = LR.boss_name[ instance[j] ],
						arg1 = instance[j],
						func = bossList_SetValue,
						icon = bossImg,
						iconsize = 30,
					}
				end
				List[#List+1] = {
					text = LR.instance_name[instance[1]],
					subMenu = subMenu,
					icon = zoneImg,
					iconsize = 30,
				}
			end
		end
	end
	SetupFrame.bossListRaw = ELib:Edit(SetupFrame.loadScrollFrame.C,nil,true):Size(270,20):Point("TOPLEFT",SetupFrame.bossList,"TOPLEFT",0,0):OnChange(function(self,isUser)
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		if text then
			self:ExtraText(LR.boss_name[tonumber(text)] or "")
		else
			self:ExtraText("")
		end

		if isUser then
			SetupFrame.data.boss = tonumber(text)
		end

		if SetupFrame.data.boss then
			SetupFrame.bossList.leftText:Color()
		else
			SetupFrame.bossList.leftText:Color(.5,.5,.5)
		end
		SetupFrame.tab.tabs[3].button.alert:Update()
	end):Shown(false)

	SetupFrame.bossList.leftText = ELib:Text(SetupFrame.loadScrollFrame.C,LR.Boss,12):Point("RIGHT",SetupFrame.bossList,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.RawDataCheck = ELib:Check(SetupFrame.loadScrollFrame.C,LR.Manually):Point("LEFT", SetupFrame.bossList, "RIGHT", 5,0):Tooltip(LR.ManuallyTip):OnClick(function(self)
		SetupFrame.RawData = self:GetChecked()
		SetupFrame:Update()
	end)

	SetupFrame.diffList = ELib:DropDown(SetupFrame.loadScrollFrame.C,220,MRT.isMoP and 6 or 10):Size(270):Point("TOPRIGHT",SetupFrame.bossList,"BOTTOMRIGHT",0,-5):OnEnter(function(self)
		local diff = select(3,GetInstanceInfo())
		local text = LR["Current difficulty"] .. ": " .. (diff or "none")
		ELib.Tooltip.Show(self,nil,text)
	end):OnLeave(GameTooltip_Hide)

	do
		local function diffList_SetValue(_,diff)
			SetupFrame.data.diff = diff
			ELib:DropDownClose()

			if SetupFrame.data.diff then
				local diff_name = LR.diff_name[SetupFrame.data.diff]
				SetupFrame.diffList:SetText(diff_name or ("Difficulty ID: " .. SetupFrame.data.diff))
				SetupFrame.diffListRaw:SetText(SetupFrame.data.diff)
			else
				SetupFrame.diffList:SetText(LR.Always)
				SetupFrame.diffListRaw:SetText("")
			end
			if SetupFrame.data.diff then
				SetupFrame.diffList.leftText:Color()
			else
				SetupFrame.diffList.leftText:Color(.5,.5,.5)
			end
			SetupFrame.tab.tabs[3].button.alert:Update()
		end
		SetupFrame.diffList.SetValue = diffList_SetValue

		local List = SetupFrame.diffList.List
		for i=1,#diffsList do
			List[#List+1] = {
				text = diffsList[i][2],
				arg1 = diffsList[i][1],
				func = diffList_SetValue,
			}
		end

		tinsert(List,2,{
			text = LR["Current difficulty"],
			func = function()
				local name, instanceType, difficultyID, difficulty = GetInstanceInfo()
				diffList_SetValue(nil,difficultyID)
			end,
			hoverFunc = function(self)
				local name, instanceType, difficultyID, difficulty = GetInstanceInfo()
				GameTooltip:SetOwner(self,"ANCHOR_RIGHT",20)
				GameTooltip:SetText(LR["Current difficulty:"] .. " " .. (difficulty and difficulty ~= "" and difficulty or "none") .. (" (%s)"):format(difficultyID),nil,nil,nil,nil,true)
				GameTooltip:Show()
			end,
		})
	end
	SetupFrame.diffList.leftText = ELib:Text(SetupFrame.loadScrollFrame.C,LR.DifficultyID,12):Point("RIGHT",SetupFrame.diffList,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.diffListRaw = ELib:Edit(SetupFrame.loadScrollFrame.C,nil,true):Size(270,20):Point("TOPRIGHT",SetupFrame.bossList,"BOTTOMRIGHT",0,-5):Tooltip(function() local diff = select(3,GetInstanceInfo()) return LR["Current difficulty:"] .. " " .. (diff or "none") end):OnChange(function(self,isUser)
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		if text then
			local diff_name = LR.diff_name[tonumber(text)]
			self:ExtraText(diff_name or "")
		else
			self:ExtraText("")
		end

		if isUser then
			SetupFrame.data.diff = tonumber(text)
		end

		if SetupFrame.data.diff then
			SetupFrame.diffList.leftText:Color()
		else
			SetupFrame.diffList.leftText:Color(.5,.5,.5)
		end
		SetupFrame.tab.tabs[3].button.alert:Update()
	end):Shown(false)

	SetupFrame.zoneList = ELib:DropDown(SetupFrame.loadScrollFrame.C,280,-1):Size(270):Point("TOPRIGHT",SetupFrame.diffList,"BOTTOMRIGHT",0,-5)
	do
		local function SetZone(_,zoneID)
			SetupFrame.data.zoneID = zoneID and tostring(zoneID) or nil
			ELib:DropDownClose()

			if SetupFrame.data.zoneID then
				local zoneID = tonumber(tostring(SetupFrame.data.zoneID):match("^[^, ]+") or "",10)
				local zoneName = LR.instance_name[zoneID]

				SetupFrame.zoneList:SetText(zoneName)
			else
				SetupFrame.zoneList:SetText(LR.Always)
			end

			SetupFrame.zoneListRaw:SetText(SetupFrame.data.zoneID or "")

			if SetupFrame.data.zoneID then
				SetupFrame.zoneList.leftText:Color()
			else
				SetupFrame.zoneList.leftText:Color(.5,.5,.5)
			end
			SetupFrame.tab.tabs[3].button.alert:Update()
		end
		SetupFrame.zoneList.SetValue = SetZone

		local List = {
			{
				text = LR.Always,
				func = SetZone,
			},
			{
				text = LR["Current instance"],
				func = function()
					local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
					SetZone(nil,instanceID)
				end,
				hoverFunc = function(self)
					local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID = GetInstanceInfo()
					GameTooltip:SetOwner(self,"ANCHOR_RIGHT",10)
					GameTooltip:SetText(LR["Current instance"] .. ": " .. (name or "none") .. (" (%s)"):format(instanceID),nil,nil,nil,nil,true)
					GameTooltip:Show()
				end,
			},
		}
		SetupFrame.zoneList.List = List

		if EJ_GetInstanceInfo then
			for i=1,#AddonDB.EJ_DATA.journalInstances do
				local line = AddonDB.EJ_DATA.journalInstances[i]
				local subMenu = {}
				for j=2,#line do
					if line[j] == 0 then
						subMenu[#subMenu+1] = {
							text = " ",
							isTitle = true,
						}
					else
						local name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, instance_id = EJ_GetInstanceInfo(line[j])
						if instance_id then
							subMenu[#subMenu+1] = {
								text = LR.instance_name[instance_id],
								arg1 = instance_id,
								func = SetZone,
								icon = buttonImage2,
								iconsize = 30,
							}
						else
							print("Error: ",instance_id)
						end
					end
				end
				tinsert(List, {text = EJ_GetTierInfo(line[1]),subMenu = subMenu})
			end
		end
	end
	SetupFrame.zoneList.leftText = ELib:Text(SetupFrame.loadScrollFrame.C,LR.Zone,12):Point("RIGHT",SetupFrame.zoneList,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()

	SetupFrame.zoneListRaw = ELib:Edit(SetupFrame.loadScrollFrame.C):Size(270,20):Point("TOPRIGHT",SetupFrame.diffList,"BOTTOMRIGHT",0,-5):Tooltip(function()
		local name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize, LfgDungeonID = GetInstanceInfo()
		return LR.ZoneIDTip1..(name or "")..LR.ZoneIDTip2..(instanceID or 0)
	end):OnChange(function(self,isUser)
		local zoneID = self:GetText():trim()
		if zoneID == "" then zoneID = nil end
		if zoneID then
			local instance_id = tonumber(zoneID) or tonumber(strsplit(",",zoneID),10) or ""
			local instance_name = LR.instance_name[instance_id]
			self:ExtraText(instance_name or "")
		else
			self:ExtraText("")
		end
		if isUser then
			SetupFrame.data.zoneID = zoneID
		end

		if SetupFrame.data.zoneID then
			SetupFrame.zoneList.leftText:Color()
		else
			SetupFrame.zoneList.leftText:Color(.5,.5,.5)
		end
		SetupFrame.tab.tabs[3].button.alert:Update()
	end):Shown(false)

	SetupFrame.doNotLoadOnBosses = ELib:Check(SetupFrame.loadScrollFrame.C,""):Point("LEFT",SetupFrame.zoneList,"RIGHT",5,0):OnClick(function(self)
		SetupFrame.data.doNotLoadOnBosses = self:GetChecked()
		SetupFrame:Update()
	end)
	SetupFrame.doNotLoadOnBosses.leftText = ELib:Text(SetupFrame.doNotLoadOnBosses,LR.doNotLoadOnBosses,12):Point("LEFT",SetupFrame.doNotLoadOnBosses,"RIGHT",5,0):Middle():Color(.5,.5,.5):Shadow()


	SetupFrame.disabled = ELib:Check(SetupFrame.loadScrollFrame.C,LR["Enabled"]):Tooltip(LR["EnabledTip"]):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",10,-90):TextSize(12):AddColorState():OnClick(function(self)
		SetupFrame.data.disabled = not self:GetChecked()
		SetupFrame:Update()
	end)

	SetupFrame.defDisabled = ELib:Check(SetupFrame.loadScrollFrame.C,LR["Default State"]):Tooltip(LR["Default StateTip"]):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",110,-90):TextSize(12):AddColorState():OnClick(function(self)
		SetupFrame.data.defDisabled = not self:GetChecked()
		SetupFrame:Update()
	end)

	local topPos = 120

	local classChecks = {}
	SetupFrame.classChecks = classChecks

	local function CheckPlayerClass(self)
		local r = "#"
		for i=1,#classesList do
			local cFrame = classChecks[i]
			if cFrame:GetChecked() then
				r = r .. cFrame.token .. "#"
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrame.data.classes = r
		SetupFrame.classChecks:Update()
		SetupFrame.otherChecks:Update()
	end

	for i=1,#classesList do -- 5 checks in one line
		local x = (i-1)%5
		local y = floor((i-1)/5)
		classChecks[i] = ELib:Check(SetupFrame.loadScrollFrame.C,classesList[i][2]):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",x*100 + 10,-y*25 - topPos):OnClick(CheckPlayerClass)
		classChecks[i].text:SetWidth(80)
		classChecks[i].text:SetJustifyH("LEFT")
		classChecks[i].token = classesList[i][1]
	end

	function classChecks:Update()
		for i=1,#classesList do
			local cFrame = classChecks[i]
			local isChecked = SetupFrame.data.classes and SetupFrame.data.classes:find("#"..cFrame.token.."#")
			cFrame:SetChecked(isChecked)
		end
	end

	topPos = topPos + 80

	local roleChecks = {}
	SetupFrame.roleChecks = roleChecks

	local function CheckPlayerRole()
		local r = "#"
		for i=1,#rolesList do
			local cFrame = roleChecks[i]
			if cFrame:GetChecked() then
				r = r .. cFrame.token .. "#"
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrame.data.roles = r
		SetupFrame.roleChecks:Update()
		SetupFrame.otherChecks:Update()
	end

	for i=1,#rolesList do
		local x = (i-1)%5
		local y = floor((i-1)/5)
		roleChecks[i] = ELib:Check(SetupFrame.loadScrollFrame.C,rolesList[i][2]):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",x*100 + 10,-y*25 - topPos):OnClick(CheckPlayerRole)
		roleChecks[i].text:SetWidth(80)
		roleChecks[i].text:SetJustifyH("LEFT")
		roleChecks[i].token = rolesList[i][1]
	end

	function roleChecks:Update()
		for i=1,#rolesList do
			local cFrame = roleChecks[i]
			local isChecked = SetupFrame.data.roles and SetupFrame.data.roles:find("#"..cFrame.token.."#")
			cFrame:SetChecked(isChecked)
		end
	end

	topPos = topPos + 55

	local groupChecks = {}
	SetupFrame.groupChecks = groupChecks

	local function CheckGroupClick()
		local r = ""
		for i=1,6 do
			local cFrame = groupChecks[i]
			if cFrame:GetChecked() then
				r = r .. i
			end
		end
		if r == "" then
			r = nil
		end
		SetupFrame.data.groups = r
		SetupFrame.groupChecks:Update()
		SetupFrame.otherChecks:Update()
	end

	for i=1,6 do
		local x = (i-1)%5
		local y = floor((i-1)/5)
		groupChecks[i] = ELib:Check(SetupFrame.loadScrollFrame.C,LR["Group"] .. " " .. i):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",x*100 + 10,-y*25 - topPos):OnClick(CheckGroupClick)
	end

	function groupChecks:Update()
		for i=1,6 do
			local cFrame = groupChecks[i]
			local isChecked = SetupFrame.data.groups and SetupFrame.data.groups:find(tostring(i))
			cFrame:SetChecked(isChecked)
		end
	end

	topPos = topPos + 55

	local otherChecks = {}
	SetupFrame.otherChecks = otherChecks

	otherChecks["AllPlayers"] = ELib:Check(SetupFrame.loadScrollFrame.C,LR.AllPlayers):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT", 10,-topPos):OnClick(function(self)
		self:SetChecked(true)
		SetupFrame.data.roles = nil
		SetupFrame.data.units = nil
		SetupFrame.data.classes = nil
		SetupFrame.data.reversed = nil
		SetupFrame.data.groups = nil
		SetupFrame:Update()
	end)
	otherChecks["AllPlayers"].text:SetWidth(80)
	otherChecks["AllPlayers"].text:SetJustifyH("LEFT")

	otherChecks["Reverse"] = ELib:Check(SetupFrame.loadScrollFrame.C,LR.Reverse):Tooltip(LR.ReverseTip):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT", 110,-topPos):OnClick(function(self)
		SetupFrame.data.reversed = not SetupFrame.data.reversed or nil
		SetupFrame.otherChecks:Update()
	end)
	otherChecks["Reverse"].text:SetJustifyH("LEFT")

	function otherChecks:Update()
		otherChecks["AllPlayers"]:SetChecked(not SetupFrame.data.units and not SetupFrame.data.roles and not SetupFrame.data.classes and not SetupFrame.data.groups)
		otherChecks["Reverse"]:SetChecked(SetupFrame.data.reversed)
		if not SetupFrame.data.units then
			otherChecks["Reverse"]:Disable()
			otherChecks["Reverse"]:SetChecked(false)
		else
			otherChecks["Reverse"]:Enable()
			otherChecks["Reverse"]:SetChecked(SetupFrame.data.reversed)
		end
	end

	topPos = topPos + 25

	local playerChecks = {}
	SetupFrame.playerChecks = playerChecks

	local function CheckPlayerClick(self)
		local r = "#"
		local tmp = {}
		for i=1,30 do
			local cFrame = playerChecks[i]
			if cFrame.name and cFrame:GetChecked() then
				r = r .. cFrame.name .. "#"
				tmp[ cFrame.name ] = true
			end
		end
		local allUnits = {strsplit(" ",SetupFrame.otherUnitsEdit:GetText())}
		for i=1,#allUnits do
			local name = allUnits[i]
			if name ~= "" and not tmp[ name ] then
				r = r .. name .. "#"
				tmp[ name ] = true
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrame.data.units = r
		SetupFrame.playerChecks:Update()
		SetupFrame.otherChecks:Update()
	end

	for i=1,30 do
		local x = (i-1)%5
		local y = floor((i-1)/5)
		playerChecks[i] = ELib:Check(SetupFrame.loadScrollFrame.C,"Player "..i):Point("TOPLEFT",SetupFrame.loadScrollFrame.C,"TOPLEFT",x*100 + 10,-y*25 - topPos):OnClick(CheckPlayerClick)
		playerChecks[i].text:SetWidth(80)
		playerChecks[i].text:SetJustifyH("LEFT")

	end

	function playerChecks:Update()
		for i=1,30 do
			playerChecks[i].name = nil
			playerChecks[i]:Hide()
		end

		local allUnits = {strsplit("#",SetupFrame.data.units or "")}
		tDeleteItem(allUnits,"")
		sort(allUnits)

		local groups = {}
		for _, name, subgroup, class in MRT.F.IterateRoster, 6 do
			groups[subgroup] = groups[subgroup] or {}
			local g = groups[subgroup]

			name = MRT.F.delUnitNameServer(name)

			g[#g+1] = name

			local i = #g + (subgroup-1)*5

			local cFrame = playerChecks[i]


			cFrame:SetText(AddonDB:ClassColorName(name))
			local isChecked = SetupFrame.data.units and SetupFrame.data.units:find("#"..name.."#")
			cFrame:SetChecked(isChecked)

			tDeleteItem(allUnits,name)

			cFrame.name = name
			cFrame:Show()
		end

		SetupFrame.otherUnitsEdit:SetText(strjoin(" ",unpack(allUnits)))
		if SetupFrame.data.units then
			SetupFrame.unitsText:Color()
		else
			SetupFrame.unitsText:Color(.5,.5,.5)
		end
	end

	topPos = topPos + 170 -- not 175 her coz the gap between players and "AllPlayers"+"Reverse" is lower then 25

	local function CheckForConfirm(self)
		local text = self:GetText()

		local allUnits = {strsplit("#",SetupFrame.data.units or "")}
		tDeleteItem(allUnits, "")
		sort(allUnits)

		for unit in AddonDB:IterateGroupMembers(6) do
			local name = UnitNameUnmodified(unit)
			tDeleteItem(allUnits, name)
		end

		local unitsText = strjoin(" ",unpack(allUnits))

		if unitsText ~= text then
			SetupFrame.unitsText:SetText(LR["Custom players:"] .. " " .. LR["*(press Enter to save changes)"])
		else
			SetupFrame.unitsText:SetText(LR["Custom players:"])
		end
	end

	SetupFrame.otherUnitsEditFrame = MLib:MultiEdit(SetupFrame.loadScrollFrame.C):FontSize(14):Size(490,70):Point("TOP",SetupFrame.loadScrollFrame.C,"TOP",0,-topPos):HideScrollOnNoScroll():OnChange(function(self,isUser)
		if isUser then
			CheckForConfirm(self)
		end

	end)
	SetupFrame.otherUnitsEdit = SetupFrame.otherUnitsEditFrame.EditBox
	SetupFrame.otherUnitsEdit.ColorBorder = nil


	SetupFrame.otherUnitsEdit:SetScript("OnEnterPressed",function(self)
		CheckPlayerClick()
		CheckForConfirm(self)
		self:ClearFocus()
	end)
	SetupFrame.unitsText = ELib:Text(SetupFrame.otherUnitsEditFrame,LR["Custom players:"],12):Point("TOPLEFT",SetupFrame.otherUnitsEditFrame,"TOPLEFT",0,15):Color():Shadow()

	SetupFrame.otherUnitsEditFrame.ScrollBar:Size(12,0)

	-- topPos = topPos + 15 * 25 + 35

	local function UpdatePlayersForCurrentNote()
		if SetupFrame.data.notepat then
			local isOkay,list = pcall(module.FindPlayersListInNote,nil,SetupFrame.data.notepat,SetupFrame.data.noteIsBlock)
			if isOkay and list then
				list = list:gsub("([%S]+)",function(name)
					if not UnitExists(name) then
						return "|cffaaaaaa"..name.."|r"
					end
				end)
			end
			SetupFrame.notePatternCurr:SetText(isOkay and list or "---")
			SetupFrame.notePatternEdit.leftText:Color()
		else
			SetupFrame.notePatternCurr:SetText("")
			SetupFrame.notePatternEdit.leftText:Color(.5,.5,.5)
		end
	end

	SetupFrame.notePatternEdit = ELib:Edit(SetupFrame.loadScrollFrame.C):Size(240,20):Point("TOP",SetupFrame.otherUnitsEditFrame,"BOTTOM",0,-20):Tooltip(LR.notePatternEditTip):OnChange(function(self,isUser)
		if isUser then
			local text = self:GetText()
			if text == "" then
				text = nil
			else
				text = text:gsub("%^","")
			end
			SetupFrame.data.notepat = text
		end

		UpdatePlayersForCurrentNote()
	end)
	SetupFrame.notePatternEdit.leftText = ELib:Text(SetupFrame.notePatternEdit,LR.notePattern,12):Point("RIGHT",SetupFrame.notePatternEdit,"LEFT",-5,0):Right():Middle():Color(.5,.5,.5):Shadow()
	SetupFrame.notePatternCurr = ELib:Text(SetupFrame.loadScrollFrame.C,"",12):Point("LEFT",SetupFrame.notePatternEdit,"LEFT",-110,-25):Size(0,20):Point("RIGHT",SetupFrame.notePatternEdit,"RIGHT",110,-25):Middle():Color():Shadow():Tooltip()

	SetupFrame.noteIsBlock = ELib:Check(SetupFrame.loadScrollFrame.C,LR.noteIsBlock):Tooltip(LR.noteIsBlockTip):Point("LEFT",SetupFrame.notePatternEdit,"RIGHT",5,0):OnClick(function(self)
		SetupFrame.data.noteIsBlock = self:GetChecked()
		SetupFrame:Update()
		UpdatePlayersForCurrentNote()
	end)

	if not module.PUBLIC and AddonDB.RGAPI then
		SetupFrame.RGAPIList = ELib:DropDown(SetupFrame.loadScrollFrame.C,240,10):Size(240):Point("TOP",SetupFrame.notePatternEdit,"BOTTOM",0,-40)
		SetupFrame.RGAPIList.leftText = ELib:Text(SetupFrame.RGAPIList,LR.RGList,12):Point("RIGHT",SetupFrame.RGAPIList,"LEFT",-5,0):Right():Middle():Color():Shadow()

		do
			local function RGAPIList_SetValue(_,arg1)
				ELib:DropDownClose()
				SetupFrame.data.RGAPIList = arg1
				SetupFrame.RGAPIList:SetText(arg1 or "-")
				if arg1 then
					SetupFrame.RGAPIList.leftText:Color()
				else
					SetupFrame.RGAPIList.leftText:Color(.5,.5,.5)
				end

				SetupFrame.RGAPIPlayersCurr:Update()
			end
			SetupFrame.RGAPIList.SetValue = RGAPIList_SetValue

			local List = SetupFrame.RGAPIList.List
			function SetupFrame.RGAPIList:PreUpdate()
				wipe(List)

				for i,v in ipairs(VMRT.RG_Assignments.Data) do
					List[#List+1] = {
						text = v.name,
						arg1 = v.name,
						func = RGAPIList_SetValue,
					}
				end
				sort(List,function(a,b) return a.text < b.text end)
				tinsert(List,1,{
					text = "-",
					arg1 = nil,
					func = RGAPIList_SetValue,
				})
			end
		end

		SetupFrame.RGAPICondition = ELib:Edit(SetupFrame.loadScrollFrame.C):Size(240,20):Point("TOP",SetupFrame.RGAPIList,"BOTTOM",0,-5):OnChange(function(self,isUser)
			if isUser then
				local text = self:GetText()
				if text == "" then
					text = nil
				end
				SetupFrame.data.RGAPICondition = text
				SetupFrame.RGAPIPlayersCurr:Update()
			end

			if SetupFrame.data.RGAPICondition then
				self.leftText:Color()
			else
				self.leftText:Color(.5,.5,.5)
			end
		end)
		SetupFrame.RGAPICondition.leftText = ELib:Text(SetupFrame.RGAPICondition,LR.RGConditions,12):Point("RIGHT",SetupFrame.RGAPICondition,"LEFT",-5,0):Right():Middle():Color():Shadow()
		SetupFrame.RGAPICondition:SetScript("OnEnter", function()
			GameTooltip:SetOwner(SetupFrame.RGAPICondition,"ANCHOR_TOP")
			GameTooltip:SetMinimumWidth(500, true)
			GameTooltip:AddLine(LR.RGConditionsTip, nil, nil, nil, true)
			GameTooltip:Show()
			GameTooltip:SetMinimumWidth(0, false)
		end)
		SetupFrame.RGAPICondition:SetScript("OnLeave", GameTooltip_Hide)

		SetupFrame.RGAPIOnlyRG = ELib:Check(SetupFrame.loadScrollFrame.C,LR.RGOnly):Tooltip(LR.RGOnlyTip):Point("LEFT",SetupFrame.RGAPICondition,"RIGHT",5,0):OnClick(function(self)
			SetupFrame.data.RGAPIOnlyRG = self:GetChecked()
			SetupFrame:Update()
		end)

		SetupFrame.RGAPIPlayersCurr = ELib:Text(SetupFrame.loadScrollFrame.C,"",12):Point("LEFT",SetupFrame.RGAPICondition,"LEFT",-130,-25):Size(0,20):Point("RIGHT",SetupFrame.RGAPICondition,"RIGHT",130,-25):Middle():Color():Shadow():Tooltip()
		function SetupFrame.RGAPIPlayersCurr:Update()
			local data = SetupFrame.data
			if data.RGAPIList then
				local isOkay, list = pcall(AddonDB.RGAPI.GetPlayersList, nil, data.RGAPIList, nil, data.RGAPIOnlyRG)

				if isOkay and type(list) == 'table' then
					local passList = AddonDB.RGAPI:GetPlayersListCondition(list, data.RGAPICondition)

					for k, GUID in next, list do
						local isInList = tContains(passList, GUID)
						local name = AddonDB.RGAPI:NameFromGUID(GUID, false, true)
						if not isInList then
							list[k] = "|cffaaaaaa" .. name .. "|r"
						else
							list[k] = name
						end
					end

					local text = #list > 0 and table.concat(list, " ") or "---"
					SetupFrame.RGAPIPlayersCurr:SetText(text)
				elseif type(list) == 'string' then -- probably error
					SetupFrame.RGAPIPlayersCurr:SetText(list)
				end
			else
				SetupFrame.RGAPIPlayersCurr:SetText("")
			end
		end


		--load by alias
		local function CheckForConfirmAlias(self)
			local text = self:GetText()

			local allUnits = {strsplit("#",SetupFrame.data.RGAPIAlias or "")}
			tDeleteItem(allUnits,"")
			sort(allUnits)

			local unitsText = strjoin(" ",unpack(allUnits))

			if unitsText ~= text then
				SetupFrame.aliasText:SetText(LR["Alias:"] .. " " .. LR["*(press Enter to save changes)"])
			else
				SetupFrame.aliasText:SetText(LR["Alias:"])
			end
		end

		SetupFrame.RGAPIAliasEditFrame = MLib:MultiEdit(SetupFrame.loadScrollFrame.C):FontSize(14):Size(490,70):Point("TOP",SetupFrame.loadScrollFrame.C,"TOP",0,-(topPos+240)):HideScrollOnNoScroll():OnChange(function(self,isUser)
			if isUser then
				CheckForConfirmAlias(self)
			end

		end)
		SetupFrame.RGAPIAliasEdit = SetupFrame.RGAPIAliasEditFrame.EditBox
		SetupFrame.RGAPIAliasEdit.ColorBorder = nil


		SetupFrame.RGAPIAliasEdit:SetScript("OnEnterPressed",function(self)
			local r = "#"
			local tmp = {}
			local allUnits = {strsplit(" ",SetupFrame.RGAPIAliasEdit:GetText())}
			sort(allUnits)
			for i=1,#allUnits do
				local name = allUnits[i]
				if name ~= "" and not tmp[ name ] then
					r = r .. name .. "#"
					tmp[ name ] = true
				end
			end
			if r == "#" then
				r = nil
			end
			SetupFrame.data.RGAPIAlias = r

			SetupFrame.RGAPIAliasEdit:Update()
			CheckForConfirmAlias(self)
			self:ClearFocus()
		end)
		SetupFrame.aliasText = ELib:Text(SetupFrame.RGAPIAliasEditFrame,LR["Alias:"],12):Point("TOPLEFT",SetupFrame.RGAPIAliasEditFrame,"TOPLEFT",0,15):Color():Shadow()

		function SetupFrame.RGAPIAliasEdit:Update()
			if not SetupFrame.data.RGAPIAlias then
				SetupFrame.RGAPIAliasEdit:SetText("")
				SetupFrame.aliasText:Color(.5,.5,.5)
			else
				local allUnits = {strsplit("#",SetupFrame.data.RGAPIAlias or "")}
				tDeleteItem(allUnits,"")
				sort(allUnits)
				SetupFrame.RGAPIAliasEdit:SetText(strjoin(" ",unpack(allUnits)))
				SetupFrame.aliasText:Color()
			end
		end

		SetupFrame.RGAPIAliasEditFrame.ScrollBar:Size(12,0)
	end


	local function ensureTriggersDataTypes() -- check for data types
		local triggers = SetupFrame.data.triggers

		local fieldTypes = module.datas.triggerFieldTypes

		for i=1,#triggers do
			local triggerData = triggers[i]
			if not triggerData.event then
				error(format("Reminder: trigger's %d event is corrupted is %q, tell the author, abort saving reminder",i,type(triggerData.event)))
				print(format("Reminder: trigger's %d event is corrupted is %q, tell the author, abort saving reminder",i,type(triggerData.event)))
				return
			end -- wtf??? an older version maybe?
			local eventDB = module.C[triggerData.event == 1 and triggerData.eventCLEU or triggerData.event]

			if not eventDB then return end -- wtf??? an older version maybe?

			for k,v in next, triggerData do
				local vtype = type(v)
				if type(fieldTypes[k]) == "table" then
					if not tContains(fieldTypes[k],vtype) then
						-- type missmatch
						error(format("field %q is not supposed to be of type %q in trigger with event %q, tell the author\nDebug:\ntoken:%s\nname:%s\nvalue:%s",k,vtype,triggerData.event == 1 and triggerData.eventCLEU or triggerData.event,SetupFrame.data.token,SetupFrame.data.name,v))
						-- triggerData[k] = nil
					end
				elseif fieldTypes[k] ~= vtype then
					-- type missmatch
					error(string.format("field %q is not supposed to be of type %q in trigger with event %q, tell the author\nDebug:\ntoken:%s\nname:%s\nvalue:%s",k,vtype,triggerData.event == 1 and triggerData.eventCLEU or triggerData.event,SetupFrame.data.token,SetupFrame.data.name,v))
					-- triggerData[k] = nil
				end
			end
		end
		return true
	end

	-- for token,data in next, VMRT.Reminder.data do
	--     SetupFrame.data = data
	--     xpcall(ensureTriggersDataTypes,function(err)
	--         print("Reminder: failed to load reminder with token",token)
	--         print(err)
	--     end)
	-- end



	SetupFrame.SaveButton = MLib:Button(SetupFrame,LR.save,13):Point("BOTTOM",SetupFrame,"BOTTOM",0,5):Size(202,22):Tooltip(LR["Hold shift to save and send reminder"]):OnClick(function()
		local success = ensureTriggersDataTypes()
		if not success then
			print("Reminder: failed to save reminder")
			return
		end
		SetupFrame:Hide()

		CheckPlayerClick()

		if not SetupFrame.data.token then
			SetupFrame.data.token = module:GenerateToken()
		end

		module:AddReminder(SetupFrame.data.token,SetupFrame.data)

		module:ReloadAll()

		if IsShiftKeyDown() then
			module:Sync(false,nil,nil,SetupFrame.data.token)
		end

		SetupFrame.data = nil
		if module.options.Update then
			module.options:Update()
		end
	end)

	function SetupFrame.SaveButton:Update()
		local alert1 = SetupFrame.tab.tabs[1].button.alert:IsShown()
		local alert2 = SetupFrame.tab.tabs[2].button.alert:IsShown()
		self:SetEnabled(not alert1 and not alert2)
	end

	SetupFrame.HistoryCheck = ELib:Check(SetupFrame,LR.QuickSetup,VMRT.Reminder.HistoryCheck):Point("BOTTOMRIGHT", SetupFrame, "BOTTOMRIGHT", -3,3):TextSize(12):Left():OnClick(function(self)
		VMRT.Reminder.HistoryCheck = self:GetChecked()
		if VMRT.Reminder.HistoryCheck then
			if not SetupFrame.QuickList then
				module.options:InitHistory()
			end
			SetupFrame.QuickList:Show()
			SetupFrame.QuickList:Attach()
			SetupFrame:UpdateHistory()
		elseif SetupFrame.QuickList then
			SetupFrame.QuickList:Hide()
		end
	end)
	SetupFrame.HistoryCheck:GetFontString():SetFont(defaultFont, 12, "OUTLINE")

	SetupFrame.SnippetsCheck = ELib:Check(SetupFrame,LR.ShowSnippets,VMRT.Reminder.showSnippets):Point("BOTTOMLEFT", SetupFrame, "BOTTOMLEFT", 3,3):TextSize(12):OnClick(function(self)
		VMRT.Reminder.showSnippets = self:GetChecked()
		if not VMRT.Reminder.showSnippets then
			SetupFrame.SnippetsList:Hide()
		else
			SetupFrame.SnippetsList:Show()
			SetupFrame.SnippetsList:UpdateNames()
		end
	end)
	SetupFrame.SnippetsCheck:GetFontString():SetFont(defaultFont, 12, "OUTLINE")



	SetupFrame.comment = MLib:MultiEdit(SetupFrame.tab.tabs[4]):FontSize(14):Size(490,90):Point("TOP",SetupFrame.tab.tabs[4],"TOP",0,-30):HideScrollOnNoScroll():OnChange(function(self,isUser)
		if isUser then
			local text, c = self:GetText():gsub("\n","")
			if c > 0 then
				self:SetText(text)
			end
			if text == "" then
				text = nil
			end

			SetupFrame.data.comment = text
		end

		if SetupFrame.data.comment then
			SetupFrame.comment.leftText:Color()
		else
			SetupFrame.comment.leftText:Color(.5,.5,.5)
		end
	end)
	do
		SetupFrame.comment.leftText = ELib:Text(SetupFrame.comment,LR["Comment"],12):Point("BOTTOMLEFT",SetupFrame.comment,"TOPLEFT",0,5):Right():Middle():Color():Shadow()
	end

	SetupFrame.personalChecks = {}
	SetupFrame.personalChecks.disabled = ELib:Check(SetupFrame.tab.tabs[4],LR.PersonalDisable):Point("TOPLEFT",SetupFrame.comment,"BOTTOMLEFT",0,-5):OnClick(function(self)
		module:ToggleDataOption(SetupFrame.data.token, "DISABLED")
		SetupFrame:Update()
	end)
	SetupFrame.personalChecks.defEnabled = ELib:Check(SetupFrame.tab.tabs[4],LR.PersonalDisable):Point("TOPLEFT",SetupFrame.comment,"BOTTOMLEFT",0,-5):OnClick(function(self)
		module:ToggleDataOption(SetupFrame.data.token, "DEF_ENABLED")
		SetupFrame:Update()
	end)
	SetupFrame.personalChecks.locked = ELib:Check(SetupFrame.tab.tabs[4],LR.UpdatesDisable):Point("TOPLEFT",SetupFrame.personalChecks.defEnabled,"BOTTOMLEFT",0,-5):OnClick(function(self)
		module:ToggleDataOption(SetupFrame.data.token, "LOCKED")
		SetupFrame:Update()
	end)
	SetupFrame.personalChecks.disableSounds = ELib:Check(SetupFrame.tab.tabs[4],LR.SoundDisable):Point("TOPLEFT",SetupFrame.personalChecks.locked,"BOTTOMLEFT",0,-5):OnClick(function(self)
		module:ToggleDataOption(SetupFrame.data.token, "SOUND_DISABLED")
		SetupFrame:Update()
	end)
	SetupFrame.personalChecks.lockedSounds = ELib:Check(SetupFrame.tab.tabs[4],LR.SoundUpdatesDisable):Point("TOPLEFT",SetupFrame.personalChecks.disableSounds,"BOTTOMLEFT",0,-5):OnClick(function(self)
		module:ToggleDataOption(SetupFrame.data.token, "SOUND_LOCKED")
		SetupFrame:Update()
	end)

	SetupFrame.DevToolAddData = MLib:Button(SetupFrame.tab.tabs[4],"DevTool:AddData(data)",12):Point("TOPLEFT",SetupFrame.personalChecks.lockedSounds,"BOTTOMLEFT",0,-5):Size(202,22):OnClick(function()
		DevTool:AddData(SetupFrame.data)
	end):Shown(DevTool and DevTool.AddData)


	local function GetRandom(t)
		local n = {}
		for k in next, t do
			n[#n+1] = k
		end
		if #n == 0 then
			return
		end
		return n[math.random(1,#n)]
	end

	SetupFrame.testData_RunTrigger = function(self,button)
		if button == "RightButton" then
			self.trigger.count = 0
		end
		if self.trigger.status then
			local target = UnitGUID'target'
			if target then
				module:DeactivateTrigger(self.trigger, target, false, true)
			else
				for uid in next, self.trigger.active do
					module:DeactivateTrigger(self.trigger, uid, false, true)
				end
			end
		else
			local new
			local triggerID = self.trigger._trigger.event
			local eventData = module.C[triggerID]
			if eventData.subEventField and self.trigger._trigger[eventData.subEventField] then
				eventData = module.C[ self.trigger._trigger[eventData.subEventField] ]
			end
			if eventData.testVals then
				new = MRT.F.table_copy2(eventData.testVals)
			else
				new = {}
			end
			module:AddTriggerCounter(self.trigger)

			new.counter = self.trigger.count
			new.sourceName = self.trigger.DsourceName and GetRandom(self.trigger.DsourceName) or self.trigger._trigger.sourceName or UnitName'player'
			new.targetName = self.trigger.DtargetName and GetRandom(self.trigger.DtargetName) or self.trigger._trigger.targetName or UnitName'target' or UnitName'player'
			new.spellID = self.trigger._trigger.spellID or 17
			new.spellName = self.trigger._trigger.spellName or GetSpellInfo(17) or "PW:S"
			new.sourceGUID = UnitGUID'player'
			new.targetGUID = UnitGUID'target' or new.sourceGUID
			if new.targetGUID then new.guid = new.targetGUID end
			if self.trigger._trigger.sourceMark then new.sourceMark = self.trigger._trigger.sourceMark end
			if self.trigger._trigger.targetMark then new.targetMark = self.trigger._trigger.targetMark end
			if self.trigger._trigger.bwtimeleft then new.timeLeft = GetTime() + self.trigger._trigger.bwtimeleft end
			if self.trigger.Dstacks then new.stacks = 1 end
			if self.trigger._trigger.text then new.text = self.trigger._trigger.text else new.text = "^_^" end
			if self.trigger.DnumberPercent then new.value = 910 new.health = 91 end

			module:RunTrigger(self.trigger, new, nil, true)

		end
		self:GetScript("OnEnter")(self)
	end

	SetupFrame.testData_TriggerButtonOnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("Current counter: "..self.trigger.count)
		GameTooltip:AddLine("Right Click for reset")
		GameTooltip:Show()
	end
	SetupFrame.testData_TriggerButtonOnLeave = function(self)
		GameTooltip_Hide()
	end

	SetupFrame.updateTestData = function()
		local token = SetupFrame.data.token
		if not token then
			for i=1,#SetupFrame.triggerTestButtons do
				local button = SetupFrame.triggerTestButtons[i]
				if button:IsShown() then
					button:Hide()
				end
			end
			if SetupFrame.testLoadButton.status ~= 1 then
				SetupFrame.testLoadButton:SetText("Reminder not saved")
				SetupFrame.testLoadButton:Disable()
				SetupFrame.testLoadButton.status = 1
			end
			return
		end
		for i=1,#module.db.reminders do
			if module.db.reminders[i].data.token == token then
				for j=1,#module.db.reminders[i].triggers do
					local trigger = module.db.reminders[i].triggers[j]

					local button = SetupFrame.triggerTestButtons[j]
					if not button then
						button = MLib:Button(SetupFrame.tab.tabs[5],"Trigger "..j):Size(490,20):OnClick(SetupFrame.testData_RunTrigger):OnEnter(SetupFrame.testData_TriggerButtonOnEnter):OnLeave(SetupFrame.testData_TriggerButtonOnLeave):Run(function(self) self:RegisterForClicks("LeftButtonUp","RightButtonUp") end)
						if j == 1 then
							button:Point("TOPLEFT",SetupFrame.testLoadButton,"BOTTOMLEFT",0,-5)
						else
							button:Point("TOPLEFT",SetupFrame.triggerTestButtons[j-1],"BOTTOMLEFT",0,-5)
						end
						SetupFrame.triggerTestButtons[j] = button
					end
					button.trigger = trigger
					if not button:IsShown() then
						button:Show()
					end
					if trigger.status then
						button:SetText("Deactivate Trigger "..j.." (Current status: |cff00ff00ON|r)")
					else
						button:SetText("Activate Trigger "..j..((trigger.untimed or trigger._trigger.activeTime) and " (Current status: |cffff0000OFF|r)" or " (Trigger with instant deactivation)"))
					end
				end
				for j=#module.db.reminders[i].triggers+1,#SetupFrame.triggerTestButtons do
					local button = SetupFrame.triggerTestButtons[j]
					if button:IsShown() then
						button:Hide()
					end
				end
				local isOutdated = MRT.F.table_compare(SetupFrame.data,module.db.reminders[i].data) ~= 1
				if SetupFrame.testLoadButton.status ~= 2 and not isOutdated then
					SetupFrame.testLoadButton:SetText("Already loaded")
					SetupFrame.testLoadButton:Disable()
					SetupFrame.testLoadButton.status = 2
				end
				if SetupFrame.testLoadButton.status ~= 4 and isOutdated then
					SetupFrame.testLoadButton:SetText("Already loaded (loaded reminder is outdated. Save current for update)")
					SetupFrame.testLoadButton:Disable()
					SetupFrame.testLoadButton.status = 4
				end
				return
			end
		end
		for i=1,#SetupFrame.triggerTestButtons do
			local button = SetupFrame.triggerTestButtons[i]
			if button:IsShown() then
				button:Hide()
			end
		end
		if SetupFrame.testLoadButton.status ~= 3 and not SetupFrame.data.disabled then
			SetupFrame.testLoadButton:SetText("Load Reminder")
			SetupFrame.testLoadButton:Enable()
			SetupFrame.testLoadButton.status = 3
		end
		if SetupFrame.testLoadButton.status ~= 5 and SetupFrame.data.disabled then
			SetupFrame.testLoadButton:SetText("Reminder Disabled")
			SetupFrame.testLoadButton:Disable()
			SetupFrame.testLoadButton.status = 5
		end
	end

	SetupFrame.UnloadTestButton = MLib:Button(SetupFrame.tab.tabs[5],"Reload Reminders"):Point("TOP",0,-40):Size(490,20):OnClick(function()
		module:ReloadAll()
	end)

	SetupFrame.testLoadButton = MLib:Button(SetupFrame.tab.tabs[5],"Load Reminder"):Point("TOP",0,-65):Size(490,20):OnClick(function()
		local token = SetupFrame.data.token
		if not token then
			prettyPrint(L.ReminderAlertNoCopyEmpty)
			return
		end
		module:LoadOneReminder(token)
	end):OnUpdate(function()
		SetupFrame.updateTestData()
	end)

	SetupFrame.testPageHelp = MLib:CreateAlertIcon(SetupFrame.tab.tabs[5],nil,nil,nil,true)
	SetupFrame.testPageHelp:SetPoint("TOP",0,-10)
	SetupFrame.testPageHelp:SetType(3)
	SetupFrame.testPageHelp:Show()
	SetupFrame.testPageHelp:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine("You can manually activate triggers by yourself for test purposes.")
		GameTooltip:AddLine("But note that most information (such as names, IDs, marks, etc.) available only for real events.")
		GameTooltip:AddLine("Your current target (if exists) will be used for target data for some type of triggers.")
		GameTooltip:Show()
	end)

	SetupFrame.triggerTestButtons = {}


	SetupFrame:Hide()

	-- here was history
	if VMRT.Reminder.HistoryCheck then
		module.options:InitHistory()
	end

---------------------------------------
-- Datas and updating for ReplaceDropDown
---------------------------------------

	local replaceData = {
		["sourceName"] = {LR["rsourceName"]},
		["sourceMark"] = {LR["rsourceMark"]},
		["sourceGUID"] = {LR["rsourceGUID"]},
		["targetName"] = {LR["rtargetName"]},
		["targetMark"] = {LR["rtargetMark"]},
		["targetGUID"] = {LR["rtargetGUID"]},
		["spellName"] = {LR["rspellName"]},
		["spellID"] = {LR["rspellID"]},
		["extraSpellID"] = {LR["rextraSpellID"]},
		["stacks"] = {LR["rstacks"]},
		["counter"] = {LR["rcounter"],LR["rcounterTip"]},
		["guid"] = {LR["rguid"]},
		["health"] = {LR["rhealth"]},
		["value"] = {LR["rvalue"]},
		["timeLeft"] = {LR["rtimeLeft"]},
		["text"] = {LR["rtext"]},
		["phase"] = {LR["rphase"]},
		["auraValA"] = {LR["rauraValA"]},
		["auraValB"] = {LR["rauraValB"]},
		["auraValC"] = {LR["rauraValC"]},
		["textNote"] = {LR["rtextNote"],LR["rtextNoteTip"]},
		["textModIcon:X:Y"] = {LR["rtextModIcon"],LR["rtextModIconTip"]},
		["fullLine"] = {LR["rfullLine"]},
		["fullLineClear"] = {LR["rfullLineClear"]},

		NOCLOSER = {
			{"{setparam:key:value}",LR["rsetparam"],LR["rsetparamTip"]},
			{"{math:x+x}",LR["rmath"],LR["rmathTip"]},
			{"{noteline:patt}",LR["rnoteline"],LR["rnotelineTip"]},
			{"{note:pos:patt}",LR["rnote"],LR["rnoteTip"]},
			{"{notepos:y:x}",LR["rnotepos"],LR["rnoteposTip"]},
			{"{min:x;y;z,c,v,b}",LR["rmin"],LR["rminTip"]},
			{"{max:x;y;z,c,v,b}",LR["rmax"],LR["rmaxTip"]},
			{"{role:name}",LR["rrole"],LR["rroleTip"]},
			{"{roleextra:name}",LR["rextraRole"],LR["rextraRoleTip"]},
			{"{sub:pos1:pos2:text}",LR["rsub"],LR["rsubTip"]},
			{"{trim:text}",LR["rtrim"],LR["rtrimTip"]},
			{"{shortnum:num}",LR["rshortnum"],LR["rshortnumTip"]},
			{"{funit:CONDITION:NUM_IN_LIST}",LR["rfunit"],LR["rfunitTip"]},
		},
		CLOSER = {
			{"{num:x}","{/num}",LR["rnum"],LR["rnumTip"]},
			{"{up}","{/up}",LR["rup"],LR["rupTip"]},
			{"{lower}","{/lower}",LR["rlower"],LR["rlowerTip"]},
			{"{rep:x}","{/rep}",LR["rrep"],LR["rrepTip"]},
			{"{len:x}","{/len}",LR["rlen"],LR["rlenTip"]},
			{"{0}","{/0}",LR["rnone"],LR["rnoneTip"]},
			{"{cond:1<2 AND 1=1}yes;no","{/cond}",LR["rcondition"],LR["rconditionTip"],maxW=600},
			{"{find:patt:text}yes;no","{/find}",LR["rfind"],LR["rfindTip"]},
			{"{replace:x:y}","{/replace}",LR["rreplace"],LR["rreplaceTip"]},
			{"{set:1}","{/set}",LR["rsetsave"],LR["rsetsaveTip"]},
			{"%set1","",LR["rsetload"],LR["rsetloadTip"]},
		},
		BASE_REPLACERS = {
			{"{spell:}",LR["rspellIcon"],LR["rspellIconTip"]},
			{"%classColor",LR["rclassColor"],LR["rclassColorTip"]},
			{"%specIcon",LR["rspecIcon"],LR["rspecIconTip"]},
			{"%specIconAndClassColor",LR["rclassColorAndSpecIcon"],LR["rclassColorAndSpecIconTip"]},
			{"%playerName",LR["rplayerName"]},
			{"%playerClass",LR["rplayerClass"]},
			{"%playerSpec",LR["rplayerSpec"]},
			{"%defCDIcon",LR["rPersonalIcon"], "|cffff7c0aDRUID|r - |T136097:0|t\n|cff0070ddSHAMAN|r - |T538565:0|t\n|cff8788eeWARLOCK|r - |T136150:0|t\n|cff00ff98MONK|r - |T615341:0|t\n|cff3fc7ebMAGE|r - |T135994:0|t\n|cffa330c9DEMONHUNTER|r - |T1305150:0|t\n|cffc41e3aDEATHKNIGHT|r - |T237525:0|t\n|cffffffffPRIEST|r - |T237550:0|t\n|cffaad372HUNTER|r - |T136094:0|t\n|cfff48cbaPALADIN|r - |T524353:0|t\n|cffc69b6dWARRIOR|r - |T132345:0|t\n|cfffff468ROGUE|r - |T132294:0|t\n|cff33937fEVOKER|r - |T1394891:0|t"},
			{"%damageImmuneCDIcon",LR["rImmuneIcon"],"|cff3fc7ebMAGE|r - |T135841:0|t\n|cffaad372HUNTER|r - |T132199:0|t\n|cfff48cbaPALADIN|r - |T524354:0|t\n|cfffff468ROGUE|r - |T136177:0|t\n|cffa330c9DEMONHUNTER|r - |T463284:0|t"},
			{"%sprintCDIcon",LR["rSprintIcon"], "|cffff7c0aDRUID|r - |T464343:0|t\n|cff0070ddSHAMAN|r - |T538576:0|t \n|cff00ff98MONK|r - |T651727:0|t\n|cff33937fEVOKER|r - |T4622479:0|t"},
			{"%healCDIcon",LR["rHealCDIcon"],"|cfff48cbaHOLY|r - |T135875:0|t\n|cffffffffHOLY|r - |T237540:0|t \n|cff0070ddRESTORATION|r - |T538569:0|t\n|cff00ff98MISTWEAVER|r - |T1020466:0|t\n|cffff7c0aRESTORATION|r - |T136107:0|t\n|cff33937fPRESERVATION|r - |T4622474:0|t"},
			{"%raidCDIcon",LR["rRaidCDIcon"],"|cfff48cbaHOLY|r - |T135872:0|t\n|cfff48cbaPROTECTION|r - |T135880:0|t\n|cffffffffDISCIPLINE|r - |T253400:0|t\n|cff0070ddRESTORATION|r - |T237586:0|t\n|cffc69b6dWARRIOR|r - |T132351:0|t \n|cffa330c9DEMON HUNTER|r - |T1305154:0|t\n|cffc41e3aDEATH KNIGHT|r - |T237510:0|t"},
			{"%externalCDIcon",LR["rExternalCDIcon"],"|cffc69b6dWARRIOR|r - |T132365:0|t\n|cfff48cbaPALADIN|r - |T135966:0|t\n|cffffffffHOLY|r - |T237542:0|t\n|cffffffffDISCIPLINE|r - |T135936:0|t\n|cff00ff98MISTWEAVER|r - |T627485:0|t\n|cffff7c0aRESTORATION|r - |T572025:0|t\n|cff33937fPRESERVATION|r - |T4622478:0|t"},
			{"%freedomCDIcon",LR["rFreedomCDIcon"],"|cfff48cbaPALADIN|r -|T135968:0|t\n|cffaad372HUNTER|r - |T236189:0|t\n|cff00ff98MONK|r - |T651727:0|t"},
		},
		ADV_REPLACERS = {
			{"{counter}",LR["rcounter"],LR["rcounterTip"]},
			{"{timeLeft}",LR["rtimeLeft"],LR["rtimeLeftTip"]},
			{"{activeTime}",LR["rActiveTime"],LR["rActiveTimeTip"]},
			{"{activeNum}",LR["rActiveNum"],LR["rActiveNumTip"]},
			{"{timeMinLeft}",LR["rMinTimeLeft"],LR["rMinTimeLeftTip"]},
			{"%status",LR["rTriggerStatus2"],LR["rTriggerStatus2Tip"]},
			{"{status:triggerNum:uid}",LR["rTriggerStatus"],LR["rTriggerStatusTip"]},
			{"{allSourceNames}",LR["rAllSourceNames"],LR["rAllSourceNamesTip"]},
			{"{allTargetNames}",LR["rAllTargetNames"],LR["rAllTargetNamesTip"]},
			{"{allActiveUIDs}",LR["rAllActiveUIDs"],LR["rAllActiveUIDsTip"]},
			{"{patt}",LR["rNoteAll"]},
			{"%notePlayer",LR["rNoteLeft"]},
			{"%notePlayerRight",LR["rNoteRight"]},
			{"{triggerActivations:1}",LR["rTriggerActivations"],LR["rTriggerActivationsTip"]},
			{"{remActivations}",LR["rRemActivations"],LR["rRemActivationsTip"]},
		},
	}
	if not module.PUBLIC then
		replaceData.NOCLOSER[#replaceData.NOCLOSER+1] = {"{rgapilist:new:1:1}","Rg list pos","{rgapilist:id:condition:rgonly}\nrgonly should equals 1"}
	end

	do
		local function replaceSetValue(self,replacer,closer)
			ELib:DropDownClose()
			local selectedStart,selectedEnd = SetupFrame.msg:GetTextHighlight()
			if replacer and closer then
				if selectedStart == selectedEnd then
					AddTextToEditBox(nil,replacer..closer,nil,true)
				else
					AddTextToEditBox(nil,closer,selectedEnd,true)
					AddTextToEditBox(nil,replacer,selectedStart,true)
				end
			else
				AddTextToEditBox(nil,replacer,selectedStart,true)
			end
		end
		local TOOLTIP_MAX_WIDTH = 350
		local function hoverFunc(self,hoverArg)
			local maxW = self.data.maxW or TOOLTIP_MAX_WIDTH
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT",20)
			GameTooltip:AddLine(self:GetText())
			GameTooltip:AddLine(self.arg1 .. (self.arg2 or ""),.5,1,.5)
			GameTooltip:SetMinimumWidth(maxW, true)
			if hoverArg then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(hoverArg,1,1,1,true)
			end
			GameTooltip:Show()
			local fontString = _G["GameTooltipTextLeft4"]
				if fontString then
					local maxWidth = fontString:GetWrappedWidth()
					GameTooltip:SetMinimumWidth(min(maxW,maxWidth), true)
				end
			GameTooltip:Show()
			GameTooltip:SetMinimumWidth(0, false)
		end

		function SetupFrame.replaceDropDown:PreUpdate()
			wipe(SetupFrame.replaceDropDown.List)
			if not SetupFrame.data then
				return
			end
			local List = SetupFrame.replaceDropDown.List

				----------REPLACERS FOR TRIGGERS
			List[#List+1] = {
				text = "TRIGGER REPLACERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.ADV_REPLACERS do
				List[#List+1] = {
					text = replaceData.ADV_REPLACERS[i][2],
					arg1 = replaceData.ADV_REPLACERS[i][1],
					hoverFunc = hoverFunc,
					hoverArg = replaceData.ADV_REPLACERS[i][3],
					func = replaceSetValue,
					maxW = replaceData.ADV_REPLACERS[i].maxW,
				}
			end
			for i=1,#SetupFrame.data.triggers do
				local triggerData = SetupFrame.data.triggers[i]
				local eventDB = module.C[triggerData.event == 1 and triggerData.eventCLEU or triggerData.event]
				local eventReplaceres = eventDB.replaceres
				if eventReplaceres then
					List[#List+1] = {
						text ="TRIGGER " .. i .. " REPLACERS",
						justifyH = "CENTER",
						isTitle = true,
					}

					for j=1,#eventReplaceres do
						if eventReplaceres[j] == "targetMark" or eventReplaceres[j] == "sourceMark" then
							List[#List+1] = {
								text = eventReplaceres[eventReplaceres[j]] or replaceData[ eventReplaceres[j] ] and replaceData[ eventReplaceres[j] ][1] or eventReplaceres[j],
								arg1 = "{" .. eventReplaceres[j] .. "Num" .. i  .. "}",
								func = replaceSetValue,
								hoverFunc = hoverFunc,
							}

							List[#List].text = List[#List].text .. " (Number)"
						end

						local text = eventReplaceres[eventReplaceres[j]] or -- rename for a specific trigger
						replaceData[ eventReplaceres[j] ] and replaceData[ eventReplaceres[j] ][1] or  -- name from replaceData
									eventReplaceres[j] -- fallback to eventReplaceres
						local hoverArg = replaceData[ eventReplaceres[j] ] and replaceData[ eventReplaceres[j] ][2] -- hover text from replaceData

						List[#List+1] = {
							text = text,
							arg1 = "{" .. eventReplaceres[j] .. i .. "}",
							func = replaceSetValue,
							hoverFunc = hoverFunc,
							hoverArg = hoverArg,
						}
					end
				end
			end

			------BASE REPLACERS BASE_REPLACERS
			List[#List+1] = {
				text = "BASE REPLACERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.BASE_REPLACERS do
				List[#List+1] = {
					text = replaceData.BASE_REPLACERS[i][2],
					arg1 = replaceData.BASE_REPLACERS[i][1],
					hoverFunc = hoverFunc,
					hoverArg = replaceData.BASE_REPLACERS[i][3],
					func = replaceSetValue,
					maxW = replaceData.BASE_REPLACERS[i].maxW,
				}
			end
			---------------NOCLOSER
			List[#List+1] = {
				text = "NOCLOSER MODIFIERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.NOCLOSER do
				List[#List+1] = {
					text = replaceData.NOCLOSER[i][2],
					arg1 = replaceData.NOCLOSER[i][1],
					hoverFunc = hoverFunc,
					hoverArg = replaceData.NOCLOSER[i][3],
					func = replaceSetValue,
					maxW = replaceData.NOCLOSER[i].maxW,
				}
			end
			---------------CLOSER
			List[#List+1] = {
				text = "CLOSER MODIFIERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.CLOSER do
				List[#List+1] = {
					text = replaceData.CLOSER[i][3],
					arg1 = replaceData.CLOSER[i][1],
					arg2 = replaceData.CLOSER[i][2],
					hoverFunc = hoverFunc,
					hoverArg = replaceData.CLOSER[i][4],
					func = replaceSetValue,
					maxW = replaceData.CLOSER[i].maxW,
				}
			end
		end
	end

---------------------------------------
-- SetupFrameUpdate
---------------------------------------

	function SetupFrame:UpdateAlerts()
		--remove all alerts first
		for k,v in next, SetupFrame do
			if type(SetupFrame[k]) == 'table' and SetupFrame[k].ColorBorder then
				SetupFrame[k]:ColorBorder()
				if k == 'duration' then
					SetupFrame[k].tooltipText = LR.durationTip
				end
			end
		end
		-- 1 - red
		-- 2 - blue
		SetupFrame.GeneralAlerts = {}

		for k,v in next, module.SetupFrameDataRequirements do
			if type(k) == 'number' then --always check
				local oneOF = false
				if not SetupFrame.data[ v["exception"] ] then
					for i,field in ipairs(v) do
						if field == 0 then
							oneOF = i + 1
						elseif oneOF then
							local anyFilled
							for  j=oneOF,#v do
								if SetupFrame.data[ v[j] ] then
									anyFilled = true
								end
							end
							if not anyFilled then
								for  j=oneOF,#v do
									if not SetupFrame.GeneralAlerts[ v[j] ] or (SetupFrame.GeneralAlerts[ v[j] ] and SetupFrame.GeneralAlerts[ v[j] ] < 2) then
										SetupFrame.GeneralAlerts[ v[j] ] = 2
									end
								end
							end
						else
							if not SetupFrame.data[field] then
								if not SetupFrame.GeneralAlerts[field] or (SetupFrame.GeneralAlerts[field] and SetupFrame.GeneralAlerts[field] < 3) then
									SetupFrame.GeneralAlerts[field] = 1
								end
							end
						end
					end
				end
			elseif type(k) == 'string' then --check only if SetupFrame.data[k]
				if SetupFrame.data[k] then
					for i,field in ipairs(v) do
						if not SetupFrame.data[field] then
							if not SetupFrame.GeneralAlerts[field] or (SetupFrame.GeneralAlerts[field] and SetupFrame.GeneralAlerts[field] < 3) then
								SetupFrame.GeneralAlerts[field] = 1
							end
						end
					end
				end
			end
		end

		for k,v in next, SetupFrame.GeneralAlerts do
			if v == 1 then
				if SetupFrame[k] and SetupFrame[k].ColorBorder then
					SetupFrame[k]:ColorBorder(true)
				end
			elseif v == 2 then
				if SetupFrame[k] and SetupFrame[k].ColorBorder  then
					SetupFrame[k]:ColorBorder(0,.5,1,1)
				end
			end
		end

		SetupFrame.tab.tabs[1].button.alert:Update()
	end

	local ignoreKeys = {
		activeTime = true,
		delayTime = true,
		invert = true,
		targetID = true,
		targetUnit = true,
		sourceUnit = true,
		bwtimeleft = true,
		stacks = true,
		extraSpellID = true,
		numberPercent = true,
		cbehavior = true,
		counter = true,
		guidunit = true,
		onlyPlayer = true,
		targetRole = true,
	}

	local triggerSnapshot
	-- this function check is there any substantial difference between current trigger and previous one
	local function CheckDifferenceForHistory(trigger)
		if not trigger then return end
		if not triggerSnapshot then
			triggerSnapshot = CopyTable(trigger)
			return true
		end
		local diff
		for k,v in next, trigger do
			if not ignoreKeys[k] and triggerSnapshot[k] ~= v then
				diff = true
			end
		end
		for k,v in next, triggerSnapshot do
			if not ignoreKeys[k] and trigger[k] ~= v then
				diff = true
			end
		end
		triggerSnapshot = CopyTable(trigger)
		return diff
	end

	function SetupFrame:UpdateHistoryCheck()
		if SetupFrame.QuickList and SetupFrame.QuickList:IsVisible() and CheckDifferenceForHistory(SetupFrame.data.triggers[SetupFrame.QuickList.TRIGGER]) then
			SetupFrame:UpdateHistory(true)
		end
	end

	function SetupFrame:Update(UpdateHistory)
		---@type ReminderData
		local data = self.data

		-- General
		SetupFrame.title:SetText(SetupFrame.data.name or "")
		SetupFrame.name:SetText(data.name or "")

		SetupFrame.msgSize:SetValue(data.msgSize, true)
		SetupFrame.msg:SetText(data.msg or "")

		SetupFrame.duration:SetText(data.duration or "")
		SetupFrame.durationReverse:SetChecked(data.durrev)
		if data.durrev then
			SetupFrame.durationReverse.leftText:Color()
		else
			SetupFrame.durationReverse.leftText:Color(.5,.5,.5)
		end

		SetupFrame.countdownCheck:SetChecked(data.countdown)
		SetupFrame.countdownType:SetValue(data.countdownType)

		local isBar = data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5
		if isBar then
			SetupFrame.barTicks:Show()
			SetupFrame.barColor:Show()
			SetupFrame.barIcon:Show()

			SetupFrame.barTicks:SetText(data.barTicks or "")
			SetupFrame.barColor:SetText(data.barColor or "")
			SetupFrame.barColor.preview:Update()
			SetupFrame.barIcon:SetText(data.barIcon or "")

			SetupFrame.voiceCountdown:SetPoint("TOPLEFT",SetupFrame.barIcon,"BOTTOMLEFT",0,-20)
		else
			SetupFrame.barTicks:Hide()
			SetupFrame.barColor:Hide()
			SetupFrame.barIcon:Hide()

			SetupFrame.voiceCountdown:SetPoint("TOPLEFT",SetupFrame.countdownCheck,"BOTTOMLEFT",0,-20)
		end


		SetupFrame.voiceCountdown:SetValue(data.voiceCountdown)
		SetupFrame.sound:SetValue(data.sound)
		SetupFrame.soundOnHide:SetValue(data.soundOnHide)
		SetupFrame.tts:SetText(data.tts or "")
		SetupFrame.ttsOnHide:SetText(data.ttsOnHide or "")

		SetupFrame.sound_delay:SetText(data.sound_delay or "")
		SetupFrame.soundOnHide_delay:SetText(data.soundOnHide_delay or "")
		SetupFrame.tts_delay:SetText(data.tts_delay or "")
		SetupFrame.ttsOnHide_delay:SetText(data.ttsOnHide_delay or "")

		SetupFrame.glow:SetText(data.glow or "")
		SetupFrame.glowFrameColor:SetText(data.glowFrameColor or "")
		SetupFrame.glowFrameColor.preview:Update()

		SetupFrame.spamType:SetValue(data.spamType)
		SetupFrame.spamChannel:SetValue(data.spamChannel)
		SetupFrame.spamMsg:SetText(data.spamMsg or "")

		SetupFrame.WAmsg:SetText(data.WAmsg or "")

		SetupFrame.addOptionsList:Update()

		SetupFrame.nameplateGlow:SetChecked(data.nameplateGlow)
		if data.nameplateGlow then
			SetupFrame.nameplateGlow.leftText:Color()
		else
			SetupFrame.nameplateGlow.leftText:Color(.5,.5,.5)
		end
		SetupFrame.glowType:SetValue(data.glowType)

		SetupFrame.glowColor:SetText(data.glowColor or "")
		SetupFrame.glowColor.preview:Update()

		SetupFrame.nameplateText:SetText(data.nameplateText or "")
		SetupFrame.glowOnlyText:SetChecked(data.glowOnlyText)
		if data.glowOnlyText then
			SetupFrame.glowOnlyText.leftText:Color()
		else
			SetupFrame.glowOnlyText.leftText:Color(.5,.5,.5)
		end

		SetupFrame.glowThick:SetText(data.glowThick or "")
		SetupFrame.glowScale:SetText(data.glowScale or "")
		SetupFrame.glowN:SetText(data.glowN or "")

		SetupFrame.glowImage:SetValue(data.glowImage)

		-- Triggers

		SetupFrame.delay:SetText(data.delay or "")
		SetupFrame.hideTextChangedCheck:SetChecked(data.hideTextChanged)
		SetupFrame.sametargets:SetChecked(data.sametargets)
		SetupFrame.specialTarget:SetText(data.specialTarget or "")
		SetupFrame.extraCheck:SetText(data.extraCheck or "")

		data.triggers = data.triggers or {
			{event=3}
		}

		for i=#data.triggers+1,#self.triggersScrollFrame.triggers do
			self.triggersScrollFrame.triggers[i]:Hide()
		end

		for i=1,#data.triggers do
			local button = GetTriggerButton(i)
			button:Show()

			local trigger = data.triggers[i]
			button.data = trigger

			button.andor.state = trigger.andor or 1
			button.andor:Update()

			if trigger.event == 1 then
				self:UpdateTriggerFieldsForEvent(button,trigger.eventCLEU or trigger.event)
			else
				self:UpdateTriggerFieldsForEvent(button,trigger.event)
			end

			button.sourceName:SetText(trigger.sourceName or "")
			button.sourceID:SetText(trigger.sourceID or "")
			button.sourceUnit:SetValue(trigger.sourceUnit)
			button.sourceMark:SetValue(trigger.sourceMark)
			button.targetName:SetText(trigger.targetName or "")
			button.targetID:SetText(trigger.targetID or "")
			button.targetUnit:SetValue(trigger.targetUnit)
			button.targetMark:SetValue(trigger.targetMark)
			button.targetRole:SetValue(trigger.targetRole)
			button.spellID:SetText(trigger.spellID or "")
			button.spellName:SetText(trigger.spellName or "")
			button.extraSpellID:SetText(trigger.extraSpellID or "")
			button.stacks:SetText(trigger.stacks or "")
			button.numberPercent:SetText(trigger.numberPercent or "")
			button.pattFind:SetText(trigger.pattFind or "")
			button.bwtimeleft:SetText(trigger.bwtimeleft or "")
			button.counter:SetText(trigger.counter or "")
			button.cbehavior:SetValue(trigger.cbehavior)
			button.delayTime:SetText(trigger.delayTime or "")
			button.activeTime:SetText(trigger.activeTime or "")
			button.invert:SetChecked(trigger.invert)
			button.guidunit:SetValue(trigger.guidunit)
			button.onlyPlayer:SetChecked(trigger.onlyPlayer)

			button:UpdateTriggerAlerts()
		end

		-- Load
		SetupFrame.disabled:SetChecked(not data.disabled)
		SetupFrame.defDisabled:SetChecked(not data.defDisabled)

		SetupFrame.bossListRaw:Shown(SetupFrame.RawData)
		SetupFrame.zoneListRaw:Shown(SetupFrame.RawData)
		SetupFrame.diffListRaw:Shown(SetupFrame.RawData)
		SetupFrame.bossList:Shown(not SetupFrame.RawData)
		SetupFrame.zoneList:Shown(not SetupFrame.RawData)
		SetupFrame.diffList:Shown(not SetupFrame.RawData)
		if SetupFrame.RawData then
			SetupFrame.bossList.leftText:SetText(LR.EncounterID)
			SetupFrame.diffList.leftText:SetText(LR.DifficultyID)
			SetupFrame.zoneList.leftText:SetText(LR.ZoneID)
		else
			SetupFrame.bossList.leftText:SetText(LR.Boss)
			SetupFrame.diffList.leftText:SetText(LR.Difficulty)
			SetupFrame.zoneList.leftText:SetText(LR.Zone)
		end

		SetupFrame.bossList:SetValue(data.boss)
		SetupFrame.diffList:SetValue(data.diff)
		SetupFrame.zoneList:SetValue(data.zoneID)

		SetupFrame.doNotLoadOnBosses:SetChecked(data.doNotLoadOnBosses)
		if data.doNotLoadOnBosses then
			SetupFrame.doNotLoadOnBosses.leftText:Color()
		else
			SetupFrame.doNotLoadOnBosses.leftText:Color(.5,.5,.5)
		end

		classChecks:Update()
		roleChecks:Update()
		groupChecks:Update()
		playerChecks:Update()
		otherChecks:Update()

		SetupFrame.notePatternEdit:SetText(data.notepat or "")
		SetupFrame.noteIsBlock:SetChecked(data.noteIsBlock)

		if not module.PUBLIC then
			SetupFrame.RGAPIList:SetValue(data.RGAPIList)
			SetupFrame.RGAPICondition:SetText(data.RGAPICondition or "")
			SetupFrame.RGAPIOnlyRG:SetChecked(data.RGAPIOnlyRG)
			SetupFrame.RGAPIPlayersCurr:Update()

			SetupFrame.RGAPIAliasEdit:Update()
		end

		SetupFrame.comment:SetText(data.comment or "")

		SetupFrame.personalChecks.disabled:Shown(not not data.token and not data.defDisabled)
		SetupFrame.personalChecks.defEnabled:Shown(not not data.token and data.defDisabled)
		SetupFrame.personalChecks.locked:Shown(not not data.token)
		SetupFrame.personalChecks.disableSounds:Shown(not not data.token)
		SetupFrame.personalChecks.lockedSounds:Shown(not not data.token)

		if data.token then
			SetupFrame.personalChecks.disabled:SetChecked(module:GetDataOption(data.token, "DISABLED"))
			SetupFrame.personalChecks.defEnabled:SetChecked(not module:GetDataOption(data.token, "DEF_ENABLED"))
			SetupFrame.personalChecks.locked:SetChecked(module:GetDataOption(data.token, "LOCKED"))
			SetupFrame.personalChecks.disableSounds:SetChecked(module:GetDataOption(data.token, "SOUND_DISABLED"))
			SetupFrame.personalChecks.lockedSounds:SetChecked(module:GetDataOption(data.token, "SOUND_LOCKED"))
		end

		SetupFrame:UpdateAlerts()
		if UpdateHistory and SetupFrame.QuickList and SetupFrame.QuickList:IsVisible() then
			SetupFrame:UpdateHistory()
		end
	end
end
