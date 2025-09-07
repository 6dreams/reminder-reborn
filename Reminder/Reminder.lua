local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ELib
local ELib, L = MRT.lib, MRT.L

---@class ReminderModule: MRTmodule
local module = AddonDB:New("Reminder","|cffff8000Reminder RG|r")
if not module then return end

module.SENDER_VERSION = 5
module.DATA_VERSION = AddonDB.Version
module.PUBLIC = AddonDB.PUBLIC

---@class Locale
local LR = AddonDB.LR

---@class MLib
local MLib = AddonDB.MLib

local LCG = LibStub("LibCustomGlow-1.0")
local LGF = LibStub("LibGetFrame-1.0")
local LGFNullOpt = {}

---@class VMRT
local VMRT = VMRT
local ReminderLog = nil

-- upvalues
local UnitPowerMax, tonumber, tostring, UnitGUID, PlaySoundFile, floor = UnitPowerMax, tonumber, tostring, UnitGUID, PlaySoundFile, floor
local UnitHealthMax, UnitHealth, ScheduleTimer, UnitName, GetRaidTargetIndex, UnitCastingInfo, UnitChannelInfo = UnitHealthMax, UnitHealth, MRT.F.ScheduleTimer, UnitName, GetRaidTargetIndex, UnitCastingInfo, UnitChannelInfo
local strsplit, GetTime, UnitPower, UnitGetTotalAbsorbs, UnitClassBase = strsplit, GetTime, UnitPower, UnitGetTotalAbsorbs, UnitClassBase
local next, ipairs, bit, string_gmatch, tremove, pcall, format, wipe, type, select, loadstring, bit_band, unpack = next, ipairs, bit, string.gmatch, tremove, pcall, format, wipe, type, select, loadstring, bit.band, unpack
local UnitInRaid, IsInRaid, IsInGroup, UnitInParty, UnitTokenFromGUID, UnitIsUnit = UnitInRaid, IsInRaid, IsInGroup, UnitInParty, UnitTokenFromGUID or MRT.NULLfunc, UnitIsUnit
local min, max, time, date, GetInstanceInfo, IsEncounterInProgress = math.min, math.max, time, date, GetInstanceInfo, IsEncounterInProgress
local C_VoiceChat, tinsert, print = C_VoiceChat, tinsert, print

local C_VoiceChat_SpeakText = C_VoiceChat.SpeakText

local GetSpellInfo = AddonDB.GetSpellInfo
local GetSpellName = AddonDB.GetSpellName
local GetSpellCooldown = AddonDB.GetSpellCooldown

local GetSpecialization = AddonDB.GetSpecialization
local GetSpecializationInfo = AddonDB.GetSpecializationInfo

local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local SendChatMessage = C_ChatInfo.SendChatMessage or SendChatMessage


local function prettyPrint(...)
	print("|cffff8000[Reminder]|r", ...)
end
module.prettyPrint = prettyPrint

---------------------------------------
-- Text Frame Initialization and Update
---------------------------------------


local frameBars = CreateFrame('Frame',nil,UIParent)
module.frameBars = frameBars
frameBars:SetSize(30,30)
frameBars:SetPoint("CENTER",UIParent,"TOP",0,-250)
frameBars:EnableMouse(false)
frameBars:SetMovable(true)
frameBars:RegisterForDrag("LeftButton")
frameBars:SetScript("OnDragStart", function(self)
	if self:IsMovable() then
		self:StartMoving()
	end
end)
frameBars:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local offsetLeft, offsetBottom = self:GetCenter()
	VMRT.Reminder.VisualSettings.Bar_PosX = (offsetLeft) - (GetScreenWidth() / 2)
	VMRT.Reminder.VisualSettings.Bar_PosY = (offsetBottom) - (GetScreenHeight() / 2)
	frameBars:ClearAllPoints()
	frameBars:SetPoint("CENTER",UIParent,"CENTER",VMRT.Reminder.VisualSettings.Bar_PosX,VMRT.Reminder.VisualSettings.Bar_PosY)
end)

frameBars.dot = frameBars:CreateTexture(nil, "BACKGROUND",nil,-6)
frameBars.dot:SetTexture("Interface\\AddOns\\MRT\\media\\circle256")
frameBars.dot:SetAllPoints()
frameBars.dot:SetVertexColor(0,0,1,1)

frameBars:Hide()
frameBars.dot:Hide()

frameBars.IDtoBar = {}
frameBars.bars = {}
frameBars.slots = {}

function frameBars:BarOnUpdate()
	local t = GetTime()
	local timeLeft = self.time_end - t
	if self.check then
		if not self:check() then
			frameBars:StopBar(self.id)
			return
		end
		if timeLeft <= 0 then
			timeLeft = 0.01
		end
	elseif timeLeft <= 0 then
		frameBars:StopBar(self.id)
		return
	end
	if not self.progressFunc then
		self.progress:SetWidth( self.width * (timeLeft/self.time_dur) )
		self.progress:SetTexCoord(0,timeLeft/self.time_dur,0,1)
		-- if self.icon.on then
		-- 	self.icon:SetPoint("LEFT", (self.width - self.height) * (timeLeft/self.time_dur), 0 )
		-- end
	else
		local pos,val = self:progressFunc()
		self.progress:SetWidth( self:GetWidth() * pos )
		self.progress:SetTexCoord(0,pos,0,1)
		-- if self.icon.on then
		-- 	self.icon:SetPoint("LEFT", (self.width - self.height) * pos, 0 )
		-- end
		timeLeft = pos * 100
	end

	local time = self.time
	time:SetFormattedText(self.countdownFormat or "%.1f",timeLeft)
	local wnow,wold = time:GetStringWidth(),time.w
	if (wnow > wold and wnow - wold > 3) or (wnow < wold and wold - wnow > 3) then
		time:SetPoint("LEFT",self,"RIGHT",-wnow-3,0)
		time.w = wnow
	end

	if self.text_data and t - self.text_prev >= 0.05 then
		local text = module:FormatMsg(self.text_data[1],self.text_data[2])
		self.text:SetText(text or "")
		self.text_prev = t
	end
end

function frameBars:GetBar()
	for i=1,#self.bars do
		local bar = self.bars[i]
		if not bar:IsShown() then
			return bar
		end
	end
	local bar = CreateFrame("Frame",nil,self)
	self.bars[#self.bars+1] = bar

	local VisualSettings = VMRT.Reminder.VisualSettings

	local height = VisualSettings.Bar_Height or 30
	local width = VisualSettings.Bar_Width or 300
	local fontSize = floor(height*0.5/2)*2

	bar:SetSize(width,height)
	bar.height = height
	bar.width = width
	ELib:Border(bar,1,0,0,0,1)
	bar.background = bar:CreateTexture(nil, "BACKGROUND")
	bar.background:SetAllPoints()
	bar.background:SetColorTexture(0,0,0,.8)

	bar.progress = bar:CreateTexture(nil, "BORDER")
	bar.progress:SetPoint("TOPLEFT",0,0)
	bar.progress:SetPoint("BOTTOMLEFT",0,0)
	bar.progress:SetTexture(VisualSettings.Bar_Texture or [[Interface\AddOns\MRT\media\bar34.tga]])

	bar.text = bar:CreateFontString(nil,"ARTWORK")
	bar.text:SetPoint("LEFT",3,0)
	bar.text:SetFont(VisualSettings.Bar_Font or MRT.F.defFont, fontSize, VisualSettings.Text_FontOutlineType)
	bar.text:SetTextColor(1,1,1,1)
	if VisualSettings.Text_FontShadow then
		bar.text:SetShadowOffset(1, -1)
	else
		bar.text:SetShadowOffset(0, 0)
	end

	bar.text_prev = 0

	bar.time = bar:CreateFontString(nil,"ARTWORK")
	bar.time:SetPoint("LEFT",self,"RIGHT",-height,0)
	bar.time:SetFont(VisualSettings.Bar_Font or MRT.F.defFont, fontSize, VisualSettings.Text_FontOutlineType)
	bar.time:SetTextColor(1,1,1,1)
	if VisualSettings.Text_FontShadow then
		bar.time:SetShadowOffset(1, -1)
	else
		bar.time:SetShadowOffset(0, 0)
	end
	bar.time:SetJustifyH("LEFT")
	bar.time.w = 0

	bar.iconFrame = CreateFrame("Frame",nil,bar)
	bar.icon = bar.iconFrame:CreateTexture(nil, "BORDER", nil, 2)
	bar.icon:SetWidth(height)
	bar.icon:SetPoint("TOPRIGHT",bar,"TOPLEFT",0,0)
	bar.icon:SetPoint("BOTTOMRIGHT",bar,"BOTTOMLEFT",0,0)
	ELib:Border(bar.icon,1,0,0,0,1)
	bar.iconFrame:Hide()

	bar.ticks = {}

	bar:SetScript("OnUpdate",self.BarOnUpdate)

	return bar
end

do
	local function CancelSoundTimers(self)
		for i=1,#self do
			self[i]:Cancel()
		end
	end
	function frameBars:StartBar(id,time,text,size,color,countdownFormat,voice,ticks,icon,checkFunc,progressFunc)
		if not id or time <= 0 then
			return
		end
		if self.IDtoBar[id] then
			self:StopBar(id)
		end
		local bar = self:GetBar()
		bar.time_start = GetTime()
		bar.time_end = bar.time_start + time
		bar.time_dur = time
		bar.id = id
		bar:ClearAllPoints()
		local slot
		for i=1,#self.bars do
			if not self.slots[i] then
				slot = i
				break
			end
		end
		if slot > 30 then
			return
		end
		bar.slot = slot
		if slot == 1 then
			bar:SetPoint("TOP",self,"CENTER",0,0)
		else
			bar:SetPoint("TOP",self.bars[slot-1],"BOTTOM",0,-4)
		end
		size = size or 1
		if bar.size ~= size or true then
			bar.size = size
			bar.icon:SetWidth((bar.height*size))
			bar:SetHeight(bar.height*size)

			bar.text:SetScale(size < 1 and size * 1.5 or size)
			bar.time:SetScale(size < 1 and size * 1.5 or size)
		end
		if type(text) == "table" then
			bar.text:SetText(text[3] or "")
			bar.text_data = text
		else
			bar.text:SetText(text or "")
			bar.text_data = nil
		end
		if color then
			bar.progress:SetVertexColor(unpack(color))
		else
			bar.progress:SetVertexColor(1,.3,.3,1)
		end
		bar.countdownFormat = countdownFormat

		if voice and time >= 1.3 then
			local clist = {Cancel = CancelSoundTimers}
			local soundTemplate = module.datas.vcdsounds[ voice ]
			if soundTemplate then
				for i=1,min(5,time-0.3) do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = MRT.F.ScheduleTimer(PlaySoundFile, time-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
					clist[#clist+1] = tmr
				end
				bar.voice = clist
			end
		else
			bar.voice = nil
		end

		for i,t in next, bar.ticks do
			t:Hide()
		end
		if ticks then
			for i=1,#ticks do
				local tick = bar.ticks[i]
				if not tick then
					tick = bar:CreateTexture(nil,"ARTWORK")
					bar.ticks[i] = tick
					tick:SetPoint("TOP")
					tick:SetPoint("BOTTOM")
					tick:SetWidth(2)
					tick:SetColorTexture(0,1,0,1)
				end
				local tt = ticks[i]
				if tt > 0 and tt < time then
					tick:SetPoint("LEFT",bar:GetWidth() * (tt/time) - 1,0)
					tick:Show()
				end
			end
		end
		if icon then
			if type(icon) == "table" then
				bar.icon:SetTexture(icon[3])
				if icon[6] then
					bar.icon:SetTexCoord(unpack(icon[6]))
				else
					bar.icon:SetTexCoord(0,1,0,1)
				end
			else
				if type(icon)=='string' and icon:find("^A:") then
					bar.icon:SetTexCoord(0,1,0,1)
					bar.icon:SetAtlas(icon:sub(3))
				else
					bar.icon:SetTexture(icon)
					bar.icon:SetTexCoord(0,1,0,1)
				end
			end
			-- bar.icon.on = true
			bar.iconFrame:Show()
		else
			bar.iconFrame:Hide()
			-- bar.icon.on = false
		end
		if type(checkFunc) == "function" then
			bar.check = checkFunc
		else
			bar.check = nil
		end
		if type(progressFunc) == "function" then
			bar.progressFunc = progressFunc
		else
			bar.progressFunc = nil
		end

		self.slots[slot] = true
		self.IDtoBar[id] = bar

		bar:Show()
		self:Show()
	end
end

function frameBars:GetBarByID(id)
	if id then
		return self.IDtoBar[id]
	end
end


function frameBars:StopBar(id)
	local bar = self.IDtoBar[id]
	if bar then
		if bar.voice then
			bar.voice:Cancel()
		end
		self.IDtoBar[id] = nil
		bar:Hide()
		self.slots[bar.slot] = false
	end
end

function frameBars:StopAllBars()
	for id,bar in next, self.IDtoBar do
		bar:Hide()
	end
	wipe(self.IDtoBar)
	wipe(self.slots)
	self:Hide()
end

function module:UpdateVisual(onlyFont)
	module.frame:UpdateTextStyle()
	local VisualSettings = VMRT.Reminder.VisualSettings

	local width = VisualSettings.Bar_Width or 300
	local height = VisualSettings.Bar_Height or 30
	local fontSize = floor(height*0.5/2)*2
	local texture = VisualSettings.Bar_Texture or [[Interface\AddOns\MRT\media\bar34.tga]]
	local barfont = VisualSettings.Bar_Font or MRT.F.defFont
	local fontFlags = VisualSettings.Text_FontOutlineType or "OUTLINE, OUTLINE"
	for i=1,#frameBars.bars do
		local bar = frameBars.bars[i]

		bar:SetSize(width,height*(bar.size or 1))
		bar.progress:SetTexture(texture)
		bar.text:SetFont(barfont, fontSize, fontFlags)
		bar.time:SetFont(barfont, fontSize, fontFlags)
		if VisualSettings.Text_FontShadow then
			bar.text:SetShadowOffset(1, -1)
			bar.time:SetShadowOffset(1, -1)
		else
			bar.text:SetShadowOffset(0, 0)
			bar.time:SetShadowOffset(0, 0)
		end
		bar.icon:SetWidth((height*(bar.size or 1)))
		bar.height = height
		bar.width = width
	end

	if onlyFont then
		return
	end
	local frame = module.frame

	if VisualSettings.Text_PosX and VisualSettings.Text_PosY then
		frame:ClearAllPoints()
		frame:SetPoint("CENTER",UIParent,"CENTER",VisualSettings.Text_PosX,VisualSettings.Text_PosY)
	end

	frame:SetFrameStrata(VisualSettings.Text_FrameStrata)

	if frame.unlocked then
		frame.dot:Show()
		frame:EnableMouse(true)
		frame:SetMovable(true)
		wipe(frame.text)
		wipe(frame.textBig)
		wipe(frame.textSmall)
		frame.text[#frame.text+1] = module:FormatMsg("Test message Тест1 {spell:23920}{spell:23920}{spell:23920}")
		frame.text[#frame.text+1] = " 2.3"
		frame.textBig[#frame.textBig+1] = module:FormatMsg("Big message Тест1 {spell:23920}{spell:23920}{spell:23920}")
		frame.textBig[#frame.textBig+1] = " 4.5"
		frame.textSmall[#frame.textSmall+1] = module:FormatMsg("Small message Тест2")
		frame.textSmall[#frame.textSmall+1] = " 6.7"
		frame:Update()
		frame:Show()

		frameBars.dot:Show()
		frameBars:EnableMouse(true)
		frameBars:SetMovable(true)
		frameBars:StopAllBars()
		frameBars:StartBar("test"..tostring({}),11,"Test Bar",nil,nil,nil,nil,nil,132361)
		frameBars:StartBar("test"..tostring({}),11,"Big Test Bar",1.5)
		frameBars:StartBar("test"..tostring({}),11,"Small Test Bar",0.68)
		frameBars:Show()
	else
		frame.dot:Hide()
		frame:EnableMouse(false)
		frame:SetMovable(false)

		wipe(frame.text)
		wipe(frame.textBig)
		wipe(frame.textSmall)
		frame:Update()
		frame:Hide()

		frameBars.dot:Hide()
		frameBars:EnableMouse(false)
		frameBars:SetMovable(false)
		frameBars:StopAllBars()
		frameBars:Hide()
	end


	if VisualSettings.Bar_PosX and VisualSettings.Bar_PosY then
		frameBars:ClearAllPoints()
		frameBars:SetPoint("CENTER",UIParent,"CENTER",VisualSettings.Bar_PosX,VisualSettings.Bar_PosY)
	end
	frameBars:SetFrameStrata(VisualSettings.Bar_FrameStrata)
end



---------------------------------------
-- Locals and db tables Initialization
---------------------------------------

local ChatSpamTimers = {}

local ChatSpamUntimed = {}

local glow_frame_monitor = nil

module.db.nameplateFrames = {}
module.db.nameplateHL = {}
module.db.nameplateGUIDToFrames = {}
module.db.nameplateGUIDToUnit = {}
module.db.onHideSounds = {}
module.db.onHideTTS = {}

module.db.debug = false
module.db.timers = {}
local reminders = {}
module.db.reminders = reminders

local sReminders = {}
module.db.showedReminders = sReminders

local voiceCountdowns ={}
module.db.voiceCountdowns = voiceCountdowns

local notePatsCache = {}
module.db.notePatsCache = notePatsCache

local nameplateUsed
local eventsUsed, unitsUsed = {}, {}
module.db.eventsToTriggers = {}
local tCOMBAT_LOG_EVENT_UNFILTERED, tUNIT_HEALTH, tUNIT_POWER_FREQUENT, tUNIT_ABSORB_AMOUNT_CHANGED, tUNIT_AURA, tUNIT_TARGET, tUNIT_SPELLCAST_SUCCEEDED, tUNIT_CAST

module.ActiveBossMod = "N/A"

local ttsVoices = C_VoiceChat.GetTtsVoices()

local IsHistoryEnabled = false

---------------------------------------
-- Functions for handling triggers
---------------------------------------

local function GetMRTNoteLines()
	return {strsplit("\n", VMRT.Note.Text1..(VMRT.Note.SelfText and "\n"..VMRT.Note.SelfText or ""))}
end

function module:FindPlayersListInNote(pat,noteIsBlock)
	local reverse
	reverse, pat = pat:match("^(%-?)([^{]+)")
	pat = "^"..pat:gsub("([%.%(%)%-%$])","%%%1"):gsub("%b{}","")
	pat = pat and pat:trim()
	if not VMRT or not VMRT.Note or not VMRT.Note.Text1 then
		return
	end
	local lines = GetMRTNoteLines()
	local res
	if noteIsBlock then
		local betweenLines = false
		for i=1,#lines do
			if lines[i]:trim():find(pat.."Start$") then
				betweenLines = true
				res = ""
				local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				res = res .. l .. "\n"

			elseif lines[i]:trim():find(pat.."End$") then
				betweenLines = false
				local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				res = res .. l .. "\n"
				break
			elseif betweenLines then
				local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				res = res .. l .. "\n"
			end
		end
	else
		for i=1,#lines do
			if lines[i]:find(pat) then
				local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				if not res then res = "" end
				res = res..(res ~= "" and " " or "")..l
				break
			end
		end
	end

	return res
end

local playerName = UnitName'player'

local GetOwnPartyNum = MRT.F.GetOwnPartyNum

local function CheckRole(roles,role1, role2)
	if roles:find("#"..role1.."#") then
		return true
	elseif role2 and roles:find("#"..role2.."#") then
		return true
	end
end

function module:CheckPlayerCondition(data,myName,myClass,role1,role2,alias)
	if VMRT.Reminder.alwaysLoad then
		return true
	end

	if not role1 and not role2 then
		role1, role2 = module:GetPlayerRole()
	end
	if not myName then
		myName = MRT.SDB.charName
	end

	if not myClass then
		myClass = UnitClassBase('player')
	end

	if not alias then
		alias = AddonDB.RGAPI and AddonDB.RGAPI:GetNick("player")
	end

	local isNoteOn,isInNote
	if data.notepat then
		isNoteOn = true
		isInNote = module:ParseNote(data) --module:FindPlayerInNote(data.notepat)
	end
	if
		(
			(not isNoteOn or isInNote) and
			(not data.units or (not data.reversed and data.units:find("#"..myName.."#")) or (data.reversed and not data.units:find("#"..myName.."#"))) and
			(not data.roles or CheckRole(data.roles, role1, role2)) and
			(not data.classes or data.classes:find("#".. myClass .."#")) and
			(not data.groups or data.groups:find(GetOwnPartyNum())) and
			(not data.RGAPIList or AddonDB.RGAPI and AddonDB.RGAPI:CheckListCondition(data.RGAPIList, data.RGAPICondition, data.RGAPIOnlyRG)) and
			(not data.RGAPIAlias or AddonDB.RGAPI and alias and data.RGAPIAlias:find("#"..alias.."#"))
		)
	then
		return true
	end
end

do
	local function ResetCounter(trigger)
		trigger.count = 0
	end
	function module:AddTriggerCounter(trigger,behav1,behav2)
		if trigger._trigger.cbehavior == 1 and behav1 then
			trigger.count = behav1
		elseif trigger._trigger.cbehavior == 2 and behav2 then
			trigger.count = behav2
		elseif trigger._trigger.cbehavior == 3 or trigger._trigger.cbehavior == 4 then
			if trigger._reminder.activeFunc2(trigger._reminder.triggers,trigger._i) then
				trigger.count = trigger.count + 1
			end
		elseif trigger._trigger.cbehavior == 5 then
			trigger.count = (trigger._reminder.globalcounter or 0) + 1
			trigger._reminder.globalcounter = trigger.count
		else
			trigger.count = trigger.count + 1

			if trigger._trigger.cbehavior == 6 then
				module.db.timers[#module.db.timers+1] = MRT.F.ScheduleTimer(ResetCounter, 5, trigger)
			end
		end
	end
end

do
	local UIDNow = 1
	function module:GetNextUID()
		UIDNow = UIDNow + 1
		return UIDNow
	end
end

function module:RunTrigger(trigger, vars, pullDelayTime, printLog)
	if printLog then
		prettyPrint(trigger._data.name or "","Run trigger #"..trigger._i)
	end
	if trigger.unloaded then return end
	-- local triggerData = trigger._trigger
	if trigger.DdelayTime then
		for i=1,#trigger.DdelayTime do
			local offset = trigger._data.durrev and trigger._data.duration or 0
			local delay = trigger.DdelayTime[i] >= offset and trigger.DdelayTime[i]-offset or 0
			if pullDelayTime then
				delay = delay - pullDelayTime
			end
			if delay > -0.1 then
				local t = ScheduleTimer(module.ActivateTrigger, max(0.01,delay), 0, trigger, vars)
				module.db.timers[#module.db.timers+1] = t
				if trigger.delays then
					trigger.delays[#trigger.delays+1] = t
				end
			end
			if printLog then
				prettyPrint("Activation delayed by "..delay.." sec.")
			end
		end
	elseif not pullDelayTime then
		module:ActivateTrigger(trigger, vars, printLog)
	end
end

do
	local indexNow = 1
	function module:ActivateTrigger(trigger, vars, printLog)
		vars = vars or {}
		if (vars.uid or vars.guid) and trigger.active[vars.uid or vars.guid] then
			return
		end
		if module.db.debugLog then module:DebugLogAdd("ActivateTrigger",trigger._data.name or trigger._data.msg,vars.uid or vars.guid) end
		if printLog then
			prettyPrint("Trigger #"..trigger._i.." activated")
		end

		trigger.status = vars

		trigger.active[vars.uid or vars.guid or 1] = vars

		trigger.triggerActivations = (trigger.triggerActivations or 0) + 1

		vars.aindex = indexNow
		indexNow = indexNow + 1


		vars.atime = GetTime()
		vars.timeLeftB = vars.atime + (trigger._trigger.activeTime or 0)

		if trigger.untimed and trigger.units then	--??? double recheck for units
			module:CheckUnitTriggerStatus(trigger)
		end
		module:CheckAllTriggers(trigger, printLog)

		if trigger._trigger.activeTime then
			module.db.timers[#module.db.timers+1] = ScheduleTimer(module.DeactivateTrigger, max(trigger._trigger.activeTime, 0.01), 0, trigger, vars.uid or vars.guid or 1, true, printLog)
		elseif (not trigger.untimed or trigger._trigger.event == 2) and trigger._data.hideTextChanged and trigger._data.duration > 0 then
			module.db.timers[#module.db.timers+1] = ScheduleTimer(module.DeactivateTrigger, max(trigger._data.duration, 0.01), 0, trigger, vars.uid or vars.guid or 1, true, printLog)
		elseif not trigger.untimed then
			module:DeactivateTrigger(trigger, vars.uid or vars.guid or 1, printLog)
		end
	end
end

local function RemoveTimer(needRun,func,...)
	local debugCount = 0
	for j=#module.db.timers,1,-1 do
		local timer = module.db.timers[j]
		if timer.func == func then
			local isPass = true
			for i=1,select("#",...) do
				local arg = select(i,...)
				if arg and arg ~= timer.args[i] then
					isPass = false
					break
				end
			end
			if isPass then
				if needRun then
					timer.func(unpack(timer.args))
				end
				timer:Cancel()
				tremove(module.db.timers, j)
				debugCount = debugCount + 1
			end
		end
	end
end

function module:RemoveTimer(func,...)
	RemoveTimer(false,func,...)
end

function module:RunAndRemoveTimer(func,...)
	RemoveTimer(true,func,...)
end

do
	local valsExtra = {
		["sourceMark"] = function(m) return MRT.F.GetRaidTargetText(m,0) end,
		["targetMark"] = function(m) return MRT.F.GetRaidTargetText(m,0) end,
		["sourceMarkNum"] = function(_,t) return t.sourceMark or 0 end,
		["targetMarkNum"] = function(_,t) return t.targetMark or 0 end,
		["health"] = function(_,t)
			return function(accuracy,...)
				if accuracy then
					local a,b = accuracy:match("^(%d+)(.-)$")
					return format("%."..(a or "1").."f",t.health)..(b or "")..strjoin(":",...), true
				else
					return format("%.1f",t.health)
				end
			end
		end,
		["value"] = function(_,t) return function() return t.value and format("%d",t.value) or "" end end,
		["auraValA"] = function(_,t) return function() return t._auraData and (t._auraData.points and t._auraData.points[1] or t._auraData[8]) or "" end end,
		["auraValB"] = function(_,t) return function() return t._auraData and (t._auraData.points and t._auraData.points[2] or t._auraData[9]) or "" end end,
		["auraValC"] = function(_,t) return function() return t._auraData and (t._auraData.points and t._auraData.points[3] or t._auraData[10]) or "" end end,
		["textModIcon"] = function(_,t)
			return function(iconSize,repeatNum,otherStr)
				if not iconSize or not repeatNum then
					return t.textNote or ""
				end
				local isPass = not otherStr
				local t = t.textNote or ""
				if not isPass then
					local c = 1
					local tf = select(c,strsplit(";",otherStr))
					while tf do
						if t:find(tf) then
							isPass = true
							break
						end
						c = c + 1
						tf = select(c,strsplit(";",otherStr))
					end
				end
				if isPass then
					repeatNum = tonumber(repeatNum)
					t = t:gsub("{spell:(%d+):?(%d*)}",("{spell:%1:"..iconSize.."}"):rep(repeatNum))
					return t, true
				else
					if t and t:find("^{spell:[^}]+}$") then
						return t:rep(3), true
					else
						return t, true
					end
				end
			end
		end,
		["textNote"] = function(v,_,t)
			if t and (t._trigger.event == 17 or t._trigger.event == 18) then
				if v and v:find("^{spell:[^}]+}$") then
					return v:rep(3)
				else
					return v
				end
			else
				return v
			end
		end,
	}
	local valsAdditional = {
		{"sourceMarkNum","sourceMark"},
		{"targetMarkNum","targetMark"},
		{"textModIcon","textNote"},
		{"auraValA","_auraData"},
		{"auraValB","_auraData"},
		{"auraValC","_auraData"},
	}
	local valsAdditionalFull = {
	}

	local function CancelSoundTimers(self)
		for i=1,#self do
			self[i]:Cancel()
		end
	end

	function module:ShowReminder(trigger, printLog)
		local data, reminder = trigger._data, trigger._reminder
		if module.db.debug then prettyPrint('ShowReminder',data.name,date("%X",time())) end
		if module.db.debugLog then module:DebugLogAdd("ShowReminder",trigger._data.name or trigger._data.msg) end

		local params = {_data = data,_reminder = reminder,_trigger = trigger,_status = trigger.status}
		for j=1,#reminder.triggers do
			local trigger = reminder.triggers[j]
			if trigger.status then
				for k,v in next, trigger.status do
					if valsExtra[k] then
						v = valsExtra[k](v,trigger.status,trigger)
					end
					params[k..j] = v
					if not params[k] then
						params[k] = v
					end
				end
				for _,k in next, valsAdditional do
					if type(k)~="table" or trigger.status[ k[2] ] then
						k = type(k) == "table" and k[1] or k
						local v = valsExtra[k](nil,trigger.status,trigger)
						params[k..j] = v
						if not params[k] then
							params[k] = v
						end
					end
				end
			else
				if trigger.count then
					params["counter"..j] = trigger.count
				end
			end
			for _,k in next, valsAdditionalFull do
				local v = valsExtra[k](nil,trigger.status,trigger)
				params[k..j] = v
				if not params[k] then
					params[k] = v
				end
			end
		end

		if data.specialTarget then
			local guid
			local sourcedest,triggerNum = data.specialTarget:match("^%%([^%d]+)(%d+)")
			if (sourcedest == "source" or sourcedest == "target") and triggerNum then
				guid = params[(sourcedest == "source" and "sourceGUID" or "targetGUID")..triggerNum]
			else
				guid = UnitGUID(data.specialTarget)
				if not guid then
					local fmt = module:FormatMsg(data.specialTarget,params)
					if fmt and type(fmt)=="string" then
						if fmt:find("[;,]") then
							for c in fmt:gmatch("[^;,]+") do
								guid = (c:find("^guid:") and c:sub(6,100)) or (#c<=100 and UnitGUID(c))
								if guid then
									break
								end
							end
						else
							guid = (fmt:find("^guid:") and fmt:sub(6,100)) or (#fmt<=100 and UnitGUID(fmt))
						end
					end
				end
			end
			if guid then
				params.guid = guid
			end
		end
		--if module.db.debug and data.debug then
		--	prettyPrint("Activate unit",params.guid)
		--end

		if data.extraCheck then
			local isPass,isValid,extraCheckString = module:ExtraCheckParams(data.extraCheck,params)
			if isValid and not isPass then
				if module.db.debug then print('ShowReminder',data.name,date("%X",time()),'not pass extra check') print(extraCheckString) end
				if printLog then
					prettyPrint("Extra check |cffff0000not passed|r. Extra check string: |cffaaaaaa"..extraCheckString.."|r")
					module:ExtraCheckParams(data.extraCheck,params,printLog)
				end
				return
			end
			if printLog then
				prettyPrint("Extra check passed. "..(not isValid and "Warning! String is not valid" or "").."Extra check string: |cffaaaaaa"..extraCheckString.."|r")
			end
		end

		if reminder.delayedActivation then
			for i=1,#reminder.delayedActivation do
				local t = ScheduleTimer(module.ShowReminderVisual, reminder.delayedActivation[i], self, trigger, data, reminder, params)
				module.db.timers[#module.db.timers+1] = t
				if printLog then
					prettyPrint("All checks |cff00ff00passed|r. Delayed activation in ",reminder.delayedActivation[i],"sec.")
				end
			end
		else
			if printLog then
				prettyPrint("All checks |cff00ff00passed|r. Activation now")
			end
			module:ShowReminderVisual(trigger,data,reminder,params)
		end
	end

	function module:ShowReminderVisual(trigger,data,reminder,params)


		--hide all showed copies of text reminder
		if not data.copy then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == data then
					if data.norewrite then
						return
					end
					-- if showed.voice then
					-- 	showed.voice:Cancel()
					-- end
					tremove(module.db.showedReminders,j)
				end
			end
			-- dont allow duplicating on hide sounds
			for j=#module.db.onHideSounds,1,-1 do
				local sound = module.db.onHideSounds[j]
				if sound.data == data then
					if sound.timer then
						sound.timer:Cancel()
					end
					tremove(module.db.onHideSounds,j)
				end
			end
			for j=#module.db.onHideTTS,1,-1 do
				local tts = module.db.onHideTTS[j]
				if tts.data == data then
					if tts.timer then
						tts.timer:Cancel()
					end
					tremove(module.db.onHideTTS,j)
				end
			end
			-- dont allow duplication voice countdowns
			for j=#module.db.voiceCountdowns,1,-1 do
				local voice = module.db.voiceCountdowns[j]
				if voice.data == data then
					for k=#voice.voice,1,-1 do
						voice.voice[k]:Cancel()
					end
					tremove(module.db.voiceCountdowns,j)
				end
			end
		end

		reminder.remActivations = (reminder.remActivations or 0) + 1

		local reminderDuration = trigger.status and trigger.status._customDuration or data.duration or 2 -- custom duration is for note triggers

		--stop duplicates for untimed text reminders
		if data.copy and reminderDuration == 0 then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == data and ((params.guid and showed.params and showed.params.guid == params.guid) or (params.uid and showed.params and showed.params.uid == params.uid)) then
					return
				end
			end
		end

		local now = GetTime()

		reminder.params = params

		if data.msg and data.msg:find("{setparam:") then
			module:FormatMsg(data.msg or "",params)
		end

		if module.db.simrun_mute then
			return
		end

		if data.glow and data.glow ~= "" then
			-- module:HideGlowByData(reminder) -- why i do this?
			module:ParseGlow(data,params)
		end

		if data.nameplateGlow then
			if params.guid then
				if reminder.nameplateguid then
					module:NameplateRemoveHighlight(reminder.nameplateguid)
				end
				local frame = module:NameplateAddHighlight(params.guid,data,params)
				if not data.copy then
					--	reminder.nameplateguid = params.guid
				end
				if reminderDuration ~= 0 then
					module.db.timers[#module.db.timers+1] = MRT.F.ScheduleTimer(module.NameplateRemoveHighlight, reminderDuration, module, params.guid, data.token)
				end
			end
		end

		if data.tts and not VMRT.Reminder.disableSound and not module:GetDataOption(data.token, "SOUND_DISABLED") then
			if data.tts_delay then
				local ttsDelay = data.tts_delay
				if data.tts_delay < 0 then
					ttsDelay = reminderDuration + data.tts_delay
				end
				local tmr = MRT.F.ScheduleTimer(module.PlayTTS, max(ttsDelay,0.01), module, data.tts, params)
				module.db.timers[#module.db.timers+1] = tmr
			else
				module:PlayTTS(data.tts,params)
			end
		end

		if data.sound and not VMRT.Reminder.disableSound and not module:GetDataOption(data.token, "SOUND_DISABLED") then
			if data.sound_delay then
				local soundDelay = data.sound_delay
				if data.sound_delay < 0 then
					soundDelay = reminderDuration + data.sound_delay
				end
				local tmr = MRT.F.ScheduleTimer(PlaySoundFile, max(soundDelay,0.01), data.sound, "Master")
				module.db.timers[#module.db.timers+1] = tmr
			else
				pcall(PlaySoundFile, data.sound, "Master")
			end
		end

		if data.soundOnHide and not VMRT.Reminder.disableSound and not module:GetDataOption(data.token, "SOUND_DISABLED") then
			if reminderDuration ~= 0 then
				local tmr = MRT.F.ScheduleTimer(PlaySoundFile, max(0.01,reminderDuration + (data.soundOnHide_delay or 0)), data.soundOnHide, "Master")
				module.db.timers[#module.db.timers+1] = tmr
				module.db.onHideSounds[#module.db.onHideSounds+1] = {
					data = data,
					params = params,
					sound = data.soundOnHide,
					timer = tmr,
				}
			else
				local s = {
					data = data,
					params = params,
					sound = data.soundOnHide,
					delay = data.soundOnHide_delay
				}
				module.db.onHideSounds[#module.db.onHideSounds+1] = s
			end
		end

		if data.ttsOnHide and not VMRT.Reminder.disableSound and not module:GetDataOption(data.token, "SOUND_DISABLED") then
			if reminderDuration ~= 0 then
				local tmr = MRT.F.ScheduleTimer(module.PlayTTS, max(0.01,reminderDuration + (data.ttsOnHide_delay or 0)), module, data.ttsOnHide, params)
				module.db.timers[#module.db.timers+1] = tmr
				module.db.onHideTTS[#module.db.onHideTTS+1] = {
					data = data,
					params = params,
					tts = data.ttsOnHide,
					timer = tmr,
				}
			else
				local s = {
					data = data,
					params = params,
					tts = data.ttsOnHide,
					delay = data.ttsOnHide_delay
				}
				module.db.onHideTTS[#module.db.onHideTTS+1] = s
			end
		end

		if data.spamType and data.spamChannel then
			module:SayChatSpam(data, params)
		end

		if data.WAmsg and WeakAuras then
			module:SendWeakAurasCustomEvent(data.WAmsg,params)
		end

		if data.voiceCountdown and reminderDuration ~= 0 and reminderDuration >= 1.3 then
			local clist = {Cancel = CancelSoundTimers}
			local soundTemplate = module.datas.vcdsounds[ data.voiceCountdown ]
			if soundTemplate then
				for i=1,min(5,reminderDuration-0.3) do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = MRT.F.ScheduleTimer(PlaySoundFile, reminderDuration-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
					clist[#clist+1] = tmr
				end
				voiceCountdowns[#voiceCountdowns+1] = {
					data = data,
					params = params,
					voice = clist,
				}
			end
		end

		local isBar = data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5
		if isBar then
			local checkFunc, progressFunc
			if reminderDuration == 0 then
				if trigger.status and trigger.status.timeLeft then
					reminderDuration = trigger.status.timeLeft - now
					checkFunc = function() return trigger.status end
				elseif trigger.status and trigger.status.health then
					reminderDuration = 100
					checkFunc = function() return trigger.status end
					progressFunc = function() return trigger.status.health / 100,trigger.status.value end
				end
			end
			if reminderDuration > 0 then
				local id = data.token
				if data.copy and not checkFunc then
					id = id .. tostring({})
				elseif data.copy then
					id = id .. (trigger.status and (trigger.status.uid or trigger.status.guid or 1) or tostring({}))
				end
				local msg, updateReq = module:FormatMsg(data.msg or "",params)
				if updateReq and not data.dynamicdisable then
					msg = {data.msg or "",params,msg}
				end
				local color
				if data.barColor then
					local a,r,g,b = data.barColor:match("(..)(..)(..)(..)")
					if r and g and b and a then
						a,r,g,b = tonumber(a,16),tonumber(r,16),tonumber(g,16),tonumber(b,16)
						color = {r/255,g/255,b/255,a/255}
					end
				end
				local countdownFormat = module.datas.countdownType[data.countdownType or 2][3]
				local voice = data.voiceCountdown
				if progressFunc then
					voice = nil
				end
				local ticks = data.barTicks
				if ticks then
					ticks = module:ConvertMinuteStrToNum(ticks)
				end
				local icon = data.barIcon
				if icon then
					if tonumber(icon) == 0 and trigger.status and trigger.status.spellID then -- 0 to use info from trigger
						icon = select(3,GetSpellInfo(trigger.status.spellID))
					elseif tonumber(icon) then -- icon is spellID
						icon = select(3,GetSpellInfo(icon)) or 134400
					end
				end

				local barSize = data.msgSize == 4 and 0.68 or data.msgSize == 5 and 1.5 or 1

				frameBars:StartBar(id,reminderDuration,msg,barSize,color,countdownFormat,voice,ticks,icon,checkFunc,progressFunc)
			end
		elseif data.msg then
			local t = {
				data = data,
				expirationTime = now + (reminderDuration == 0 and 86400 or reminderDuration or 2),
				params = params,
				dur = reminderDuration,
			}
			module.db.showedReminders[#module.db.showedReminders+1] = t

			module.frame:Show()
		end
	end
end

function module:UnloadTrigger(trigger)
	local data, reminder = trigger._data, trigger._reminder

	trigger.unloaded = true

	if data.msg then
		for j=#module.db.showedReminders,1,-1 do
			local showed = module.db.showedReminders[j]
			if showed.data == data then
				if showed.voice then
					showed.voice:Cancel()
				end
				tremove(module.db.showedReminders,j)
			end
		end
	end

	if data.soundOnHide then
		for j=#module.db.onHideSounds,1,-1 do
			local sound = module.db.onHideSounds[j]
			if sound.data == data then
				if sound.timer then
					sound.timer:Cancel()
				end
				-- pcall(PlaySoundFile, sound.sound, "Master")
				tremove(module.db.onHideSounds,j)
			end
		end
	end

	if data.ttsOnHide then
		for j=#module.db.onHideTTS,1,-1 do
			local tts = module.db.onHideTTS[j]
			if tts.data == data then
				if tts.timer then
					tts.timer:Cancel()
				end
				tremove(module.db.onHideTTS,j)
			end
		end
	end

	if data.spamType and data.spamChannel then
		module:StopChatSpam(data)

	end

	if data.glow then
		module:HideGlowByData(trigger._reminder)
	end
	if ChatSpamUntimed and ChatSpamUntimed.data == data then
		ChatSpamUntimed.timer:Cancel()
	end
	if data.nameplateGlow then
		if reminder.nameplateguid then
			module:NameplateRemoveHighlight(reminder.nameplateguid)
			reminder.nameplateguid = nil
		end
		for guid,list in next, module.db.nameplateHL do
			for uid,t in next, list do
				if t.data == data then
					module:NameplateRemoveHighlight(guid, uid)
				end
			end
		end
	end

	if data.voiceCountdown then
		for i=1,#voiceCountdowns do
			if voiceCountdowns[i].data == data then
				voiceCountdowns[i].voice:Cancel()
				tremove(voiceCountdowns,i)
			end
		end
	end
end

function module:CheckUnitTriggerStatus(trigger)
	for guid in next, trigger.statuses do
		if UnitGUID(trigger.units[guid]) ~= guid then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			module:DeactivateTrigger(trigger, guid)
		end
	end
end

function module:CheckUnitTriggerStatusOnDeactivating(trigger)
	for guid in next, trigger.statuses do
		if UnitGUID(trigger.units[guid]) ~= guid then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			if not trigger.ignoreManualOff then
				trigger.active[guid] = nil
			end
		end
	end
end

function module:DeactivateTrigger(trigger, uid, isScheduled, printLog)
	if trigger.delays and #trigger.delays > 0 then
		for j=#trigger.delays,1,-1 do
			local delayTimer = trigger.delays[j]
			if not uid or delayTimer.args[3].uid == uid or delayTimer.args[3].guid == uid then
				delayTimer:Cancel()
				tremove(trigger.delays, j)
			end
		end
	end

	if not trigger.active[uid or 1] then
		return
	end
	if trigger.ignoreManualOff and not isScheduled then
		return
	end
	if module.db.debugLog then module:DebugLogAdd("DeactivateTrigger",trigger._data.name or trigger._data.msg,uid) end
	if printLog then
		prettyPrint("Trigger #"..trigger._i.." deactivated")
	end

	trigger.active[uid or 1] = nil

	if trigger.untimed and trigger.units then	--??? double recheck for units
		module:CheckUnitTriggerStatusOnDeactivating(trigger)
	end

	local status = false
	for _ in next, trigger.active do
		status = true
		break
	end
	if not status then
		trigger.status = false
		module:CheckAllTriggers(trigger, printLog)
	elseif uid and trigger._data.duration == 0 then -- hide untimed reminder for specific uid/guid
		if trigger._data.msg then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == trigger._data and showed.params and (showed.params.uid == uid or showed.params.guid == uid) then
					-- if showed.voice then
					--     showed.voice:Cancel()
					-- end
					tremove(module.db.showedReminders,j)
				end
			end
		end

		if trigger._data.voiceCountdown then
			for j=#voiceCountdowns,1,-1 do
				local voice = voiceCountdowns[j]
				if voice.data == trigger._data and voice.params and (voice.params.uid == uid or voice.params.guid == uid) then
					voice.voice:Cancel()
					tremove(voiceCountdowns,j)
				end
			end
		end

		if trigger._data.soundOnHide then
			for j=#module.db.onHideSounds,1,-1 do
				local sound = module.db.onHideSounds[j]
				if sound.data == trigger._data and sound.params and (sound.params.uid == uid or sound.params.guid == uid) then
					if sound.delay then
						local tmr = MRT.F.ScheduleTimer(PlaySoundFile, max(sound.delay,0.01), sound.sound, "Master")
						module.db.timers[#module.db.timers+1] = tmr
					else
						pcall(PlaySoundFile, sound.sound, "Master")
					end
					tremove(module.db.onHideSounds,j)
				end
			end
		end

		if trigger._data.ttsOnHide then
			for j=#module.db.onHideTTS,1,-1 do
				local tts = module.db.onHideTTS[j]
				if tts.data == trigger._data and tts.params and (tts.params.uid == uid or tts.params.guid == uid) then
					if tts.delay then
						local tmr = MRT.F.ScheduleTimer(module.PlayTTS, max(tts.delay,0.01), module, tts.tts,tts.params)
						module.db.timers[#module.db.timers+1] = tmr
					else
						module:PlayTTS(tts.tts,tts.params)
					end
					tremove(module.db.onHideTTS,j)
				end
			end
		end


		if trigger._data.glow then
			module:HideGlowByUID(trigger._reminder, uid)
		end

		if trigger._data.nameplateGlow then
			module:NameplateRemoveHighlight(uid, trigger._data.token)
		end
	end
end

local unitreplace = {
	arena1 = "boss6",
	arena2 = "boss7",
	arena3 = "boss8",
	arena4 = "boss9",
	arena5 = "boss10",
	arenapet1 = "boss11",
	arenapet2 = "boss12",
	arenapet3 = "boss13",
	arenapet4 = "boss14",
	arenapet5 = "boss15",
	npc = "boss16",
}
local unitreplace_rev = {}
for k,v in next, unitreplace do unitreplace_rev[v]=k end

-- Kaze MRT Note Timers shenanigans
do
	local specToType = {
		-- Mage
		[62] = "Ranged", -- Arcane
		[63] = "Ranged", -- Fire
		[64] = "Ranged", -- Frost
		-- Paladin
		[65] = "Melee", -- Holy
		[66] = "Melee", -- Protection
		[70] = "Melee", -- Retribution
		-- Warrior
		[71] = "Melee", -- Arms
		[72] = "Melee", -- Fury
		[73] = "Melee", -- Protection
		-- Druid
		[102] = "Ranged", -- Balance
		[103] = "Melee", -- Feral
		[104] = "Melee", -- Guardian
		[105] = "Ranged", -- Restoration
		-- Death Knight
		[250] = "Melee", -- Blood
		[251] = "Melee", -- Frost
		[252] = "Melee", -- Unholy
		-- Hunter
		[253] = "Ranged", -- Beast Mastery
		[254] = "Ranged", -- Marksmanship
		[255] = "Melee", -- Survival
		-- Priest
		[256] = "Ranged", -- Discipline
		[257] = "Ranged", -- Holy
		[258] = "Ranged", -- Shadow
		-- Rogue
		[259] = "Melee", -- Assassination
		[260] = "Melee", -- Outlaw
		[261] = "Melee", -- Subtlety
		-- Shaman
		[262] = "Ranged", -- Elemental
		[263] = "Melee", -- Enhancement
		[264] = "Ranged", -- Restoration
		-- Warlock
		[265] = "Ranged", -- Affliction
		[266] = "Ranged", -- Demonology
		[267] = "Ranged", -- Destruction
		-- Monk
		[268] = "Melee", -- Brewmaster
		[270] = "Melee", -- Mistweaver
		[269] = "Melee", -- Windwalker
		-- Demon Hunter
		[577] = "Melee", -- Havoc
		[581] = "Melee", -- Vengeance
		-- Evoker
		[1467] = "Ranged", -- Devastation
		[1468] = "Ranged", -- Preservation
		[1473] = "Ranged" -- Augmentation
	}

	local ReplaceData = {}
	local function replaceName(match)
		local name = match:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|", "")
		if ReplaceData[name] then
			return ReplaceData[name]
		else
			return match
		end
	end

	local function GSUB_RGAPIList(str)
		if not AddonDB.RGAPI then
			return
		end
		local listName, condition, RGOnly = strsplit(":", str)
		local list = AddonDB.RGAPI:GetPlayersListCondition(listName, condition, RGOnly == "1")
		AddonDB.RGAPI:ConvertGUIDsToNames(list)
		return list[1] or "Unknown"
	end

	local function GetNoteLinesForTimers()
		local lines = GetMRTNoteLines()
		ReplaceData = {}
		local betweenLines
		for i=1,#lines do
			local line = lines[i]
			if line:match("kazestart") then
				betweenLines = true
			elseif line:match("kazeend") then
				betweenLines = false
			elseif betweenLines then
				local cmd, arg1, arg2 = line:match("^#([^, ]+)[ ]+([^, ]+),+[ ]*([^,]+)")
				if (cmd == "nr" or cmd == "namereplace") and arg1 and arg2 then
					arg1 = arg1:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|","")
					arg2 = arg2:gsub("#(.+)", GSUB_RGAPIList):trim()
					ReplaceData[arg1] = arg2
				end
			elseif line:find("{time:[^}]+}") then
				lines[i] = lines[i]:gsub("[^ \n,%(%)%[%]%}%{_%$#@!&]+", replaceName)
			end
		end

		return lines
	end
	AddonDB.GetNoteLinesForTimers = GetNoteLinesForTimers

	local keywordsString = "class:{class},group:{mygroup},spec:{spec},role:{role},everyone,type:{type],personals" -- {name},
	local keywords = {}
	keywords["%%caster"] = true
	keywords["%%target"] = true

	local replaceKeywordTable = {}
	local function updateReplaceTable()
		local specId, spec, _, _, role = GetSpecializationInfo(GetSpecialization())

		replaceKeywordTable = {
			-- ["{name}"] = UnitName("player"),
			["{mygroup}"] = MRT.F.GetOwnPartyNum(),
			["{class}"] = UnitClassBase("player"),
			["{spec}"] = spec,
			["{role}"] = role,
			["{type}"] = specToType[specId]
		}
	end
	local function updateKeywords()
		updateReplaceTable()

		for k in keywordsString:gmatch("([^,]+)") do
			k = k:trim():lower():gsub("{.-}", replaceKeywordTable)
			keywords[k] = true
		end
	end

	local function shouldInputShow(line)
		line = line:gsub("@(%S+)", ""):lower()

		local clearedLine = line:gsub("{.-}", ""):gsub("||", "|"):gsub("|c........", ""):gsub("|r", ""):gsub("|",""):trim()
		-- print(format("%q",clearedLine))
		if UnitIsUnit(clearedLine,"player") then
			-- print("Player found",clearedLine,line)
			return MRT.SDB.charName
		end

		for k in next, keywords do
			if line:match(k:lower()) then
				return k
			end
		end
		return false
	end

	local allowedTextReplacers = {
		["spell"] = true
	}

	function module:ParseNoteTimers(phaseNum,doCLEU,globalPhaseNum,ignoreName)
		updateKeywords()

		local playerName = MRT.SDB.charName
		local playerClass = UnitClassBase('player'):lower()
		local data = {}

		local lines = GetNoteLinesForTimers()
		for i=1,#lines do
			if lines[i]:find("{time:[^}]+}") then
				local l = lines[i]
				local fulltime,subOpts = l:match("{time:([0-9:%.]+)([^{}]*)}")
				local phase
				local difftime,difflen = 0
				local isDisabled, isCLEU, isGlobalPhaseCounter
				if subOpts then
					for w in string_gmatch(subOpts,"[^,]+") do
						local igp,pf = w:match("^p(g?)([%d%.]+)$")
						if pf then
							phase = tonumber(pf)
						end
						if igp then
							isGlobalPhaseCounter = true
						end
						local a,b,c = strsplit(":",w)
						if a == "diff" and b and (b == playerName or b:lower() == playerClass) and c then
							difftime = difftime + (tonumber(c) or 0)
						end
						if a == "difflen" and b and (b == playerName or b:lower() == playerClass) and c then
							difflen = tonumber(c)
						end
						if w == "off" then
							isDisabled = true
						elseif w:find("^S[CA][CSAR]:") then
							isCLEU = w
						end
					end
				end
				if not isDisabled and ((doCLEU and isCLEU) or (not doCLEU and not isCLEU)) then
					for str in string_gmatch(l .. "  ", "([^ \n-][^\n-]-)  +") do
						local keyword = shouldInputShow(str)
						if ignoreName or keyword then
							str = str:gsub("{(.-)}",function(s)
								local a,b = strsplit(":",s)
								if allowedTextReplacers[a] then
									return "{" .. s .. "}"
								end
								return ""
							end)
							local targetName = (str:match("@(%S+)") or ""):gsub("||", "|"):gsub("|c........", ""):gsub("|r", "")
							str = str:gsub("@", "")

							local suffix = keyword and str:gsub(keyword, ""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):gsub("|",""):trim() or str
							if targetName ~= "" then
								suffix = (suffix .. " " .. targetName):trim()
							end

							local spellName
							local spellID = tonumber(str:match("{spell:(%d+):?%d*}") or "?")
							if spellID then
								spellName = GetSpellName(spellID)
							else
								spellName = str
							end

							-- print(format("line: %q, keyword: %q, suffix: %q, spellName: %q", l, keyword, suffix, spellName))
							local phaseCheck = isGlobalPhaseCounter and globalPhaseNum or phaseNum

							data[#data+1] = {
								time = fulltime,
								phaseMatch = phaseCheck == tostring(phase or 1),
								textRight = suffix,
								-- textLeft = prefix,
								spellName = spellName,
								fullLine = l,
								phase = phase,
								diffTime = difftime,
								diffLen = difflen or nil,
								cleu = isCLEU,
								targetName = targetName,
							}
						end
					end
				end
			end
		end

		return data
	end
end

function module:TriggerBossPhase(phaseText, globalPhaseNum, phaseDelayTime)
	if module.db.currentPhase == phaseText and GetTime() - (module.db.currentPhaseTime or 0) < 0.5 then
		return
	end
	module.db.currentPhase = phaseText
	module.db.currentPhaseTime = GetTime() - (phaseDelayTime or 0)

	local phaseNum = phaseText:match("%d+%.?%d*")

	if module.db.eventsToTriggers.BOSS_PHASE then
		local triggers = module.db.eventsToTriggers.BOSS_PHASE
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				triggerData.pattFind
			then
				local phaseCheck = (phaseNum == triggerData.pattFind or (not tonumber(triggerData.pattFind) and phaseText:find(triggerData.pattFind,1,true)))

				if not trigger.statuses[1] and phaseCheck then
					module:AddTriggerCounter(trigger)
					local vars = {
						phase = phaseText,
						counter = trigger.count,
					}
					trigger.statuses[1] = vars
					if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
						module:RunTrigger(trigger, vars, phaseDelayTime)
					end
				elseif trigger.statuses[1] and not phaseCheck then
					trigger.statuses[1] = nil
					module:DeactivateTrigger(trigger)
				end
			end
		end
	end
	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and VMRT and VMRT.Note and VMRT.Note.Text1 and phaseNum then

		for _,event_name in next, {"NOTE_TIMERS","NOTE_TIMERS_ALL"} do
			local triggers = module.db.eventsToTriggers[event_name]
			if triggers then
				local data = module:ParseNoteTimers(phaseNum,false,globalPhaseNum,event_name == "NOTE_TIMERS_ALL")
				for i=1,#triggers do
					local trigger = triggers[i]
					local triggerData = trigger._trigger
					for j=1,#data do
						local now = data[j]
						trigger.DdelayTime = module:ConvertMinuteStrToNum(now.time)
						if trigger.DdelayTime then
							for k=1,#trigger.DdelayTime do
								trigger.DdelayTime[k] = max(trigger.DdelayTime[k] - (trigger._trigger.bwtimeleft or 0) + now.diffTime,0.01)
							end
						end
						local uid = event_name .. ":" .. i .. ":" .. (now.phase or "0") .. ":" .. j

						if not trigger.statuses[uid] and now.phaseMatch then
							local vars = {
								phase = phaseText,
								counter = 0,
								textNote = now.textRight,
								textLeft = now.textLeft,
								fullLine = now.fullLine,
								spellName = now.spellName,
								fullLineClear = (now.fullLine or ""):gsub("[{}]",""),
								targetName = now.targetName,
								uid = uid,
							}
							if now.diffLen then
								vars._customDuration = max((trigger._data.duration or 2) + now.diffLen,0.01)
							end
							trigger.statuses[uid] = vars
							module:RunTrigger(trigger, vars)
						elseif trigger.statuses[uid] and not now.phaseMatch then
							trigger.statuses[uid] = nil
							if now.phase then
								module:DeactivateTrigger(trigger, uid)
							end
						end
					end
				end
			end
		end
	end
	if IsHistoryEnabled then
		module:AddHistoryEntry(2, phaseText)
	end
end

--/run GMRT.A.Reminder:TriggerBossPhase("1")

function module:TriggerBossPull(encounterID, difficultyID, pullDelayTime)
	local triggers = module.db.eventsToTriggers.BOSS_START
	if triggers then
		for i=1,#triggers do
			module:RunTrigger(triggers[i],nil,pullDelayTime)
		end
	end
	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and VMRT and VMRT.Note and VMRT.Note.Text1 then

		for _,event_name in next, {"NOTE_TIMERS","NOTE_TIMERS_ALL"} do
			local triggers = module.db.eventsToTriggers[event_name]
			if triggers then
				local data = module:ParseNoteTimers(0,true,nil,event_name == "NOTE_TIMERS_ALL")
				for j=1,#data do
					local now = data[j]

					local prefix,spellID,counter = strsplit(":",now.cleu)
					local event =
						prefix == "SCC" and "SPELL_CAST_SUCCESS" or
						prefix == "SCS" and "SPELL_CAST_START" or
						prefix == "SAA" and "SPELL_AURA_APPLIED" or
						prefix == "SAR" and "SPELL_AURA_REMOVED"
					if event and spellID and tonumber(spellID) and counter and tonumber(counter) then
						local triggerOverwrite = {
							Dcounter = counter ~= "0" and module:CreateNumberConditions(counter) or false,
							DsourceName = false,
							DsourceID = false,
							DtargetName = false,
							DtargetID = false,
							Dstacks = false,
							untimed = false,
						}
						local triggerDataOverwrite = {
							spellID = tonumber(spellID),
							spellName = false,
							sourceMark = false,
							sourceUnit = false,
							targetMark = false,
							targetUnit = false,
							extraSpellID = false,
							pattFind = false,
							cbehavior = false,
						}

						for i=1,#triggers do
							local trigger = triggers[i]
							local triggerData = trigger._trigger

							local DdelayTime = module:ConvertMinuteStrToNum(now.time)
							if DdelayTime then
								for k=1,#DdelayTime do
									DdelayTime[k] = max(DdelayTime[k] - (triggerData.bwtimeleft or 0) + now.diffTime,0.01)
								end
							end
							local dataTable = {count = 0}

							local newData = setmetatable({},{__index = function(_,a)
									if type(triggerDataOverwrite[a]) == "boolean" then
										return triggerDataOverwrite[a]
									end
									return triggerDataOverwrite[a] or triggerData[a]
								end})

							local new = setmetatable({},{__index = function(_,a)
								if a == "_trigger" then
									return newData
								elseif a == "DdelayTime" then
									return DdelayTime
								elseif a == "status" then
									return trigger.status
								elseif a == "count" then
									return dataTable.count
								else
									if type(triggerOverwrite[a]) == "boolean" then
										return triggerOverwrite[a]
									end
									return triggerOverwrite[a] or trigger[a]
								end
							end, __newindex = function(_,a,v)
								if a == "status" then
									trigger.status = v
									if type(v) == "table" then
										v.textNote = now.textRight
										v.textLeft = now.textLeft
										v.fullLine = now.fullLine
										v.fullLineClear = (now.fullLine or ""):gsub("[{}]","")
										v.spellName = now.spellName
										v.targetName = now.targetName
									end
								elseif a == "count" then
									dataTable.count = v
									trigger.count = v
								end
							end})

							local match = true
							if triggerData.pattFind and ((triggerData.pattFind:find("^%-") and now.fullLine:find(triggerData.pattFind:sub(2),1,true)) or (not triggerData.pattFind:find("^%-") and not now.fullLine:find(triggerData.pattFind,1,true))) then
								match = false
							end

							if match then
								tCOMBAT_LOG_EVENT_UNFILTERED[event] = tCOMBAT_LOG_EVENT_UNFILTERED[event] or {}
								tCOMBAT_LOG_EVENT_UNFILTERED[event][#tCOMBAT_LOG_EVENT_UNFILTERED[event]+1] = new
							end
						end
					end
				end
			end
		end
	end
	if IsHistoryEnabled then
		module:AddHistoryEntry(3, encounterID, difficultyID)
	end
end
--/run GMRT.A.Reminder:TriggerBossPull()

function module:TriggerMplusStart()
	local triggers = module.db.eventsToTriggers.MPLUS_START
	if triggers then
		for i=1,#triggers do
			module:RunTrigger(triggers[i])
		end
	end
end

function module:TriggerHPLookup(unit,triggers,hp,hpValue)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DtargetName or name and trigger.DtargetName[name]) and
			(not trigger.DtargetID or trigger.DtargetID(guid)) and
			(type(triggerData.targetUnit) ~= "number" or triggerData.targetUnit >= 0 or module:CheckUnit(triggerData.targetUnit,guid,trigger))
		then
			local hpCheck =
				(not triggerData.targetMark or (GetRaidTargetIndex(unit) or 0) == triggerData.targetMark) and
				trigger.DnumberPercent and module:CheckNumber(trigger.DnumberPercent,hp)

			if not trigger.statuses[guid] and hpCheck then
				trigger.countsD[guid] = (trigger.countsD[guid] or 0) + 1
				module:AddTriggerCounter(trigger,nil,trigger.countsD[guid])
				local vars = {
					targetName = UnitName(unit),
					targetMark = GetRaidTargetIndex(unit),
					guid = guid,
					counter = trigger.count,
					health = hp,
					value = hpValue,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not hpCheck then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end

			if trigger.statuses[guid] then
				trigger.statuses[guid].health = hp
				trigger.statuses[guid].value = hpValue
			end
		end
	end
end

function module.main:UNIT_HEALTH(unit)
	local triggers = tUNIT_HEALTH[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		local hpMax = UnitHealthMax(funit)
		if hpMax == 0 then
			module:TriggerHPLookup(funit,triggers,0,0)
			return
		end
		local hpNow = UnitHealth(funit)
		local hp = hpNow / hpMax * 100
		module:TriggerHPLookup(funit,triggers,hp,hpNow)
	end
end

function module.main:UNIT_POWER_FREQUENT(unit)
	local triggers = tUNIT_POWER_FREQUENT[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		local powerMax = UnitPowerMax(funit)
		if powerMax == 0 then
			module:TriggerHPLookup(funit,triggers,0,0)
			return
		end
		local powerNow = UnitPower(funit)
		local power = powerNow / powerMax * 100
		module:TriggerHPLookup(funit,triggers,power,powerNow)
	end
end

function module.main:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	local triggers = tUNIT_ABSORB_AMOUNT_CHANGED[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		local absorbs = UnitGetTotalAbsorbs(funit)
		module:TriggerHPLookup(funit,triggers,absorbs,absorbs)
	end
end

function module:TriggerChat(text, sourceName, sourceGUID, targetName)
	local triggers = module.db.eventsToTriggers.CHAT_MSG
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		--prettyPrint(sourceGUID, triggerData.sourceUnit, module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger))
		if
			triggerData.pattFind and
			text:find(triggerData.pattFind,1,true) and
			(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
			(not trigger.DsourceID or not sourceGUID or trigger.DsourceID(sourceGUID)) and
			(not triggerData.sourceUnit or not sourceGUID or module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger)) and
			(not trigger.DtargetName or targetName and trigger.DtargetName[targetName]) and
			(not triggerData.targetUnit or not targetName or (UnitGUID(targetName) and module:CheckUnit(triggerData.targetUnit,UnitGUID(targetName),trigger)))
		then
			module:AddTriggerCounter(trigger)
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				if sourceName and sourceName:find("%-") and UnitName(strsplit("-",sourceName),nil) then
					sourceName = strsplit("-",sourceName)
				end
				if targetName and targetName:find("%-") and UnitName(strsplit("-",targetName),nil) then
					targetName = strsplit("-",targetName)
				end
				local vars = {
					sourceName = sourceName,
					targetName = targetName,
					counter = trigger.count,
					guid = sourceGUID or UnitGUID(sourceName or ""),
					text = text,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end

	if IsHistoryEnabled then
		module:AddHistoryEntry(8, text, sourceName, sourceGUID, targetName)
	end
end

local function CHAT_MSG(self, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	module:TriggerChat(text, playerName, guid, playerName2)
end

module.main.CHAT_MSG_RAID_WARNING = CHAT_MSG
module.main.CHAT_MSG_MONSTER_YELL = CHAT_MSG
module.main.CHAT_MSG_MONSTER_EMOTE = CHAT_MSG
module.main.CHAT_MSG_MONSTER_SAY = CHAT_MSG
module.main.CHAT_MSG_MONSTER_WHISPER = CHAT_MSG
module.main.CHAT_MSG_RAID_BOSS_EMOTE = CHAT_MSG
module.main.CHAT_MSG_RAID_BOSS_WHISPER = CHAT_MSG
module.main.CHAT_MSG_RAID = CHAT_MSG
module.main.CHAT_MSG_RAID_LEADER = CHAT_MSG
module.main.CHAT_MSG_PARTY = CHAT_MSG
module.main.CHAT_MSG_PARTY_LEADER = CHAT_MSG
module.main.CHAT_MSG_WHISPER = CHAT_MSG

local function RAID_MSG(self, text, playerName, displayTime, enableBossEmoteWarningSound)
	module:TriggerChat(text)
end

module.main.RAID_BOSS_EMOTE = RAID_MSG
module.main.RAID_BOSS_WHISPER = RAID_MSG

function module:TriggerBossFrame(targetName, targetGUID, targetUnit)
	local triggers = module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT
	if triggers then
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				(not trigger.DtargetName or targetName and trigger.DtargetName[targetName]) and
				(not trigger.DtargetID or trigger.DtargetID(targetGUID)) and
				(not triggerData.targetUnit or triggerData.targetUnit == targetUnit)
			then
				trigger.countsD[targetGUID] = (trigger.countsD[targetGUID] or 0) + 1
				module:AddTriggerCounter(trigger,nil,trigger.countsD[targetGUID])
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					local vars = {
						targetName = targetName,
						counter = trigger.count,
						guid = targetGUID,
						uid = module:GetNextUID(),
					}
					module:RunTrigger(trigger, vars)
				end
			end
		end
	end

	if IsHistoryEnabled then
		module:AddHistoryEntry(9,targetName,targetGUID,targetUnit)
	end
end

local bossFramesblackList = {}
module.db.bossFramesblackList = bossFramesblackList
function module.main:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	for _,unit in next, module.datas.unitsList[1] do
		local funit = unitreplace[unit] or unit

		local guid = UnitGUID(funit)
		if guid then
			if not bossFramesblackList[guid] then
				bossFramesblackList[guid] = true
				local name = UnitName(funit) or ""
				module:TriggerBossFrame(name, guid, funit)
			end
			module:CycleAllUnitEvents(unit)
		end
		module:CycleAllUnitEvents_UnitRefresh(unit)
	end
end

local fakeUnitAuraInfo = {isFullUpdate = true}
function module:CycleAllUnitEvents(unit)
	local funit = unitreplace[unit] or unit
	if UnitGUID(funit) then
		if tUNIT_HEALTH then module.main:UNIT_HEALTH(unit) end
		if tUNIT_POWER_FREQUENT then module.main:UNIT_POWER_FREQUENT(unit) end
		if tUNIT_ABSORB_AMOUNT_CHANGED then module.main:UNIT_ABSORB_AMOUNT_CHANGED(unit) end
		if tUNIT_AURA then module.main:UNIT_AURA(unit,fakeUnitAuraInfo) end
		if tUNIT_TARGET then module.main:UNIT_TARGET(unit) end
		if tUNIT_CAST then module.main:UNIT_CAST_CHECK(unit) end
	end
end


function module:TriggerUnitRemovedLookup(unit,triggers,guid)
	local funit = unitreplace[unit] or unit

	guid = guid or UnitGUID(funit)
	for i=1,#triggers do
		local trigger = triggers[i]

		if trigger.statuses[guid] then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			module:DeactivateTrigger(trigger,guid)
		end
	end
end

do
	local tablesList = {"UNIT_HEALTH","UNIT_POWER_FREQUENT","UNIT_ABSORB_AMOUNT_CHANGED","UNIT_TARGET","UNIT_AURA","UNIT_CAST"}
	function module:CycleAllUnitEvents_UnitRefresh(unit)
		for _,e in next, tablesList do
			if module.db.eventsToTriggers[e] then
				local triggers = module.db.eventsToTriggers[e][unit]
				if triggers then
					for i=1,#triggers do
						local trigger = triggers[i]

						module:CheckUnitTriggerStatus(trigger)
					end
				end
			end
		end
	end

	function module:CycleAllUnitEvents_UnitRemoved(unit, guid)
		for _,e in next, tablesList do
			if module.db.eventsToTriggers[e] then
				local triggers = module.db.eventsToTriggers[e][unit]
				if triggers then
					module:TriggerUnitRemovedLookup(unit,triggers,guid)
				end
			end
		end
	end
end

do
	local scheduled = nil
	local function scheduleFunc()
		scheduled = nil
		for _,unit in next, module.datas.unitsList[1] do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in next, module.datas.unitsList[2] do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in next, module.datas.unitsList[3] do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in next, module.datas.unitsList[4] do
			module:CycleAllUnitEvents(unit)
		end
	end
	function module.main:RAID_TARGET_UPDATE()
		if not scheduled then
			scheduled = MRT.F.ScheduleTimer(scheduleFunc,0.05)
		end
	end
end

do
	local prev
	function module.main:PLAYER_TARGET_CHANGED()
		local guid = UnitGUID("target")
		if prev == guid then return end
		if guid then
			module:CycleAllUnitEvents("target")
		else
			module:CycleAllUnitEvents_UnitRemoved("target", prev)
		end
		prev = guid
	end
end

do
	local prev
	function module.main:PLAYER_FOCUS_CHANGED()
		local guid = UnitGUID("focus")
		if guid then
			module:CycleAllUnitEvents("focus")
			prev = guid
		else
			module:CycleAllUnitEvents_UnitRemoved("focus", prev)
			prev = nil
		end
	end
end

do
	local prev
	local mouseoverframe = CreateFrame("Frame")
	local function mouseoverframe_onupdate()
		local guid = UnitGUID("mouseover")
		if not guid then
			mouseoverframe:SetScript("OnUpdate",nil)
			module:CycleAllUnitEvents_UnitRemoved("mouseover", prev)
			prev = nil
		end
	end
	function module.main:UPDATE_MOUSEOVER_UNIT()
		local guid = UnitGUID("mouseover")
		if guid then
			module:CycleAllUnitEvents("mouseover")
			prev = guid
			mouseoverframe:SetScript("OnUpdate",mouseoverframe_onupdate)
		end
	end
end

function module.main:NAME_PLATE_UNIT_ADDED(unit)
	module:CycleAllUnitEvents(unit)
	local guid = UnitGUID(unit)
	if guid then
		module.db.nameplateGUIDToUnit[guid] = unit
		local data = module.db.nameplateHL[guid]
		if data then
			module:NameplateUpdateForUnit(unit, guid, data)
		end
	end
end

function module.main:NAME_PLATE_UNIT_REMOVED(unit)
	module:CycleAllUnitEvents_UnitRemoved(unit)
	local guid = UnitGUID(unit)
	if guid then
		module.db.nameplateGUIDToUnit[guid] = nil
		module:NameplateHideForGUID(guid)
	end
end

function module:NameplatesReloadCycle()
	for _,unit in next, module.datas.unitsList[2] do
		if UnitGUID(unit) then
			module.main:NAME_PLATE_UNIT_ADDED(unit)
		end
	end
end

function module:NameplateUpdateForUnit(unit, guid, guidTable)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then
		return
	end
	module:NameplateHideForGUID(guid)
	if guidTable then
		for uid,data in next, guidTable do
			local frame = module:GetNameplateFrame(nameplate,data.text,data.textUpdateReq,data.color,data.noEdge,data.thick,data.type,data.customN,data.scale,data.textSize,data.posX,data.posY,data.pos,data.glowImage)
			module.db.nameplateGUIDToFrames[guid] = frame
			break
		end
	end
end

function module:NameplateHideForGUID(guid)
	local frame = module.db.nameplateGUIDToFrames[guid]
	if frame then
		frame:Hide()
		module.db.nameplateGUIDToFrames[guid] = nil
	end
end

function module:NameplateAddHighlight(guid,data,params)
	if module.db.nameplateHL[guid] and module.db.nameplateHL[guid][data and data.token or 1] then
		return
	end
	local t = {
		data = data,
	}
	if data and data.nameplateText then
		local text = data.nameplateText

		if text:find("%%tsize:%d+") then
			local tsize = text:match("%%tsize:(%d+)")
			t.textSize = tonumber(tsize)
			text = text:gsub("%%tsize:%d+","")
		end

		if text:find("%%tposx:%-?%d+") then
			local posX = text:match("%%tposx:(%-?%d+)")
			t.posX = tonumber(posX)
			text = text:gsub("%%tposx:%-?%d+","")
		end

		if text:find("%%tposy:%-?%d+") then
			local posY = text:match("%%tposy:(%-?%d+)")
			t.posY = tonumber(posY)
			text = text:gsub("%%tposy:%-?%d+","")
		end

		if text:find("%%tpos:%d+") then
			local pos = text:match("%%tpos:(%d+)")
			t.pos = tonumber(pos)
			text = text:gsub("%%tpos:%d+","")
		end

		t.text, t.textUpdateReq = module:FormatMsg(text,params)
		if t.textUpdateReq and not data.dynamicdisable then
			t.textUpdateReq = function()
				return module:FormatMsg(text,params)
			end
		else
			t.textUpdateReq = nil
		end
	end
	if data and data.glowType then
		t.type = data.glowType
	end
	if data and data.glowScale then
		t.scale = data.glowScale
	end
	if data and data.glowN then
		t.customN = data.glowN
	end
	if data and data.glowThick then
		t.thick = data.glowThick
	end
	if data and data.glowColor then
		local a,r,g,b = data.glowColor:match("(..)(..)(..)(..)")
		if r and g and b and a then
			a,r,g,b = tonumber(a,16),tonumber(r,16),tonumber(g,16),tonumber(b,16)
			t.color = {r/255,g/255,b/255,a/255}
		end
	end
	if data and data.glowImage then
		t.glowImage = data.glowImage
	end
	if data and data.glowOnlyText then
		t.noEdge = true
	end
	if not module.db.nameplateHL[guid] then
		module.db.nameplateHL[guid] = {}
	end
	module.db.nameplateHL[guid][data and data.token or 1] = t
	local unit = module.db.nameplateGUIDToUnit[guid]
	if unit then
		module:NameplateUpdateForUnit(unit, guid, module.db.nameplateHL[guid])
	end
end

function module:NameplateRemoveHighlight(guid, uid)
	module:NameplateHideForGUID(guid)
	local hl_data = module.db.nameplateHL[guid]
	if hl_data then
		for c_uid,data in next, hl_data do
			if not uid or c_uid == uid then
				hl_data[c_uid] = nil
			end
		end
	end
	local unit = module.db.nameplateGUIDToUnit[guid]
	if unit then
		module:NameplateUpdateForUnit(unit, guid, hl_data)
	end
end

local function NameplateFrame_OnUpdate(self)
	if GetTime() > self.expirationTime then
		self:Hide()
	end
end
local function NameplateFrame_SetExpiration(self,expirationTime)
	self.expirationTime = expirationTime
	self:SetScript("OnUpdate",NameplateFrame_OnUpdate)
end
local function NameplateFrame_OnHide(self)
	if LCG then
		LCG.ButtonGlow_Stop(self)
		LCG.AutoCastGlow_Stop(self)
		LCG.ProcGlow_Stop(self)
		LCG.PixelGlow_Stop(self)
	end
	self.textUpate:Hide()
	self.textUpate.tmr = 0

	self.aim1:Hide()
	self.aim2:Hide()
	self.imgabove:Hide()

	self:SetScript("OnUpdate",nil)
end

local function NameplateFrame_TextUpdate(self, elapsed)
	self.tmr = self.tmr + elapsed
	if self.tmr > 0.03 then
		self.tmr = 0
		self.text:SetText( self.func() )
	end
end

local function NameplateFrame_OnScaleCheck(self,elapsed)
	self.tmr = self.tmr - elapsed
	if self.tmr <= 0 then
		self:SetScript("OnUpdate",nil)
	end
	local p = self:GetParent()
	local s1,s2 = p:GetSize()
	if p.s1 ~= s1 or p.s2 ~= s2 then
		p.s1,p.s2 = s1,s2
		p:UpdateGlow()
	end
end
local function NameplateFrame_OnShow(self)
	if not self.frameNP then
		return
	end
	if not self.scalecheck then
		self.scalecheck = CreateFrame("Frame",nil,self)
		self.scalecheck:SetPoint("TOPLEFT",0,0)
		self.scalecheck:SetSize(1,1)
	end
	self.scalecheck.tmr = 1
	if self.glow_customGlowType == 7 then
		self.scalecheck.tmr = 10000
	end
	self.scalecheck:SetScript("OnUpdate",NameplateFrame_OnScaleCheck)
end

local function NameplateFrame_UpdateGlow(frame)
	local color,noEdge,customThick,customGlowType,customN,customScale,glowImage = frame.glow_color,frame.glow_noEdge,frame.glow_customThick,frame.glow_customGlowType,frame.glow_customN,frame.glow_customScale,frame.glow_glowImage
	if noEdge then
		return
	end

	local glowType = customGlowType or VMRT.Reminder.NameplateGlowType
	if glowType == 2 then
		if not LCG then return end
		LCG.ButtonGlow_Start(frame,color)
	elseif glowType == 3 then
		if not LCG then return end
		LCG.AutoCastGlow_Start(frame,color,customN,nil,customScale or 1)

	elseif glowType == 4 then
		if not LCG then return end
		LCG.ProcGlow_Start(frame,{color=color},nil,true)
	elseif glowType == 5 then
		if color then
			frame.aim1:SetVertexColor(unpack(color))
			frame.aim2:SetVertexColor(unpack(color))
		else
			frame.aim1:SetVertexColor(1,1,1,1)
			frame.aim2:SetVertexColor(1,1,1,1)
		end
		if customThick then
			frame.aim1:SetWidth(customThick)
			frame.aim2:SetHeight(customThick)
		else
			frame.aim1:SetWidth(2)
			frame.aim2:SetHeight(2)
		end
		frame.aim1:Show()
		frame.aim2:Show()
	elseif glowType == 6 then
		if color then
			frame.solid:SetColorTexture(unpack(color))
		else
			frame.solid:SetColorTexture(1,1,1,1)
		end
		frame.solid:Show()
	elseif glowType == 7 then
		local imgData = module.datas.glowImagesData[glowImage or 0]
		if imgData or type(glowImage)=='string' then
			if imgData then
				frame.imgabove:SetTexture(imgData[3])
				frame.imgabove:SetSize((imgData[4] or 80)*(customScale or 1),(imgData[5] or 80)*(customScale or 1))
				if imgData[6] then
					frame.imgabove:SetTexCoord(unpack(imgData[6]))
				else
					frame.imgabove:SetTexCoord(0,1,0,1)
				end
			else
				frame.imgabove:SetSize(80*(customScale or 1),80*(customScale or 1))
				if type(glowImage)=='string' and glowImage:find("^A:") then
					frame.imgabove:SetTexCoord(0,1,0,1)
					frame.imgabove:SetAtlas(glowImage:sub(3))
				else
					frame.imgabove:SetTexture(glowImage)
					frame.imgabove:SetTexCoord(0,1,0,1)
				end
			end
			if color then
				frame.imgabove:SetVertexColor(unpack(color))
			else
				frame.imgabove:SetVertexColor(1,1,1,1)
			end
			frame.imgabove:Show()
		end
	elseif glowType == 8 then
		customN = customN or 100
		frame.hpline:SetPoint("LEFT",customN/100*frame:GetWidth(),0)
		if color then
			frame.hpline:SetColorTexture(unpack(color))
		else
			frame.hpline:SetColorTexture(1,1,1,1)
		end
		frame.hpline.hp = customN/100
		frame.hpline:SetWidth(customThick or 3)
		frame.hpline:Show()
	else
		if not LCG then return end
		local thick = customThick or 2
		thick = tonumber(thick or 2)
		thick = floor(thick)
		LCG.PixelGlow_Start(frame,color,customN,nil,nil,thick,1,1)
	end
end

function module:GetNameplateFrame(nameplate,text,textUpdateReq,color,noEdge,customThick,customGlowType,customN,customScale,textSize,posX,posY,pos,glowImage)
	local frame
	for i=1,#module.db.nameplateFrames do
		if not module.db.nameplateFrames[i]:IsShown() then
			frame = module.db.nameplateFrames[i]
			break
		end
	end
	if not frame then
		frame = CreateFrame("Frame",nil,UIParent)
		module.db.nameplateFrames[#module.db.nameplateFrames+1] = frame
		frame:Hide()
		frame:SetScript("OnHide",NameplateFrame_OnHide)
		frame.SetExpiration = NameplateFrame_SetExpiration
		frame:SetScript("OnShow",NameplateFrame_OnShow)
		frame.UpdateGlow = NameplateFrame_UpdateGlow

		frame.text = frame:CreateFontString(nil,"ARTWORK")
		frame.text:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",2,2)
		frame.text:SetFont(MRT.F.defFont, 12, "OUTLINE")
		--frame.text:SetShadowOffset(1,-1)
		frame.text:SetTextColor(1,1,1,1)
		frame.text.size = 12

		frame.textUpate = CreateFrame("Frame",nil,frame)
		frame.textUpate:SetPoint("CENTER")
		frame.textUpate:SetSize(1,1)
		frame.textUpate:Hide()
		frame.textUpate.tmr = 0
		frame.textUpate.text = frame.text
		frame.textUpate:SetScript("OnUpdate",NameplateFrame_TextUpdate)

		frame.aim1 = frame:CreateTexture(nil, "ARTWORK")
		frame.aim1:SetColorTexture(1,1,1,1)
		frame.aim1:SetPoint("CENTER")
		frame.aim1:SetSize(2,3000)
		frame.aim1:Hide()
		frame.aim2 = frame:CreateTexture(nil, "ARTWORK")
		frame.aim2:SetColorTexture(1,1,1,1)
		frame.aim2:SetPoint("CENTER")
		frame.aim2:SetSize(3000,2)
		frame.aim2:Hide()

		frame.imgabove = frame:CreateTexture(nil, "ARTWORK")
		frame.imgabove:SetPoint("BOTTOM",frame,"TOP",0,1)
		frame.imgabove:Hide()

		frame.solid = frame:CreateTexture(nil,"ARTWORK")
		frame.solid:SetAllPoints()
		frame.solid:Hide()

		frame.hpline = frame:CreateTexture(nil,"ARTWORK")
		frame.hpline:SetPoint("TOP")
		frame.hpline:SetPoint("BOTTOM")
		frame.hpline:Hide()
	end
	local frameNP = (nameplate.unitFramePlater and nameplate.unitFramePlater.healthBar) or (nameplate.unitFrame and nameplate.unitFrame.Health) or (nameplate.UnitFrame and nameplate.UnitFrame.healthBar) or nameplate
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT",frameNP,0,0)
	frame:SetPoint("BOTTOMRIGHT",frameNP,0,0)
	frame:SetFrameStrata( nameplate:GetFrameStrata() )
	frame.solid:Hide()
	frame.hpline:Hide()
	frame.frameNP = frameNP

	frame.s1,frame.s2 = frame:GetSize()

	if textSize and frame.text.size ~= textSize then
		frame.text:SetFont(MRT.F.defFont, textSize, "OUTLINE")
		frame.text.size = textSize
	elseif not textSize and frame.text.size ~= 12 then
		frame.text:SetFont(MRT.F.defFont, 12, "OUTLINE")
		frame.text.size = 12
	end

	posX = posX or 2
	posY = posY or 2
	pos = pos or 1
	if frame.text.posX ~= posX or frame.text.posY ~= posY or frame.text.pos ~= pos then
		frame.text.posX = posX
		frame.text.posY = posY
		frame.text.pos = pos
		local anchor1, anchor2 = "BOTTOMLEFT", "TOPLEFT"
		if pos == 2 then
			anchor1, anchor2 = "BOTTOM", "TOP"
		elseif pos == 3 then
			anchor1, anchor2 = "BOTTOMRIGHT", "TOPRIGHT"
		elseif pos == 4 then
			anchor1, anchor2 = "LEFT", "RIGHT"
		elseif pos == 5 then
			anchor1, anchor2 = "TOPRIGHT", "BOTTOMRIGHT"
		elseif pos == 6 then
			anchor1, anchor2 = "TOP", "BOTTOM"
		elseif pos == 7 then
			anchor1, anchor2 = "TOPLEFT", "BOTTOMLEFT"
		elseif pos == 8 then
			anchor1, anchor2 = "RIGHT", "LEFT"
		elseif pos == 9 then
			anchor1, anchor2 = "CENTER", "CENTER"
		end
		frame.text:ClearAllPoints()
		frame.text:SetPoint(anchor1,frame,anchor2,posX,posY)
	end

	frame.text:SetText(text or "")
	if textUpdateReq then
		frame.textUpate.func = textUpdateReq
		frame.textUpate:Show()
	else
		frame.textUpate:Hide()
	end

	frame.glow_color = color
	frame.glow_noEdge = noEdge
	frame.glow_customThick = customThick
	frame.glow_customGlowType = customGlowType
	frame.glow_customN = customN
	frame.glow_customScale = customScale
	frame.glow_glowImage = glowImage

	frame:UpdateGlow()

	frame:Show()
	return frame
end

local function TriggerAura_DelayActive(trigger, triggerData, guid, vars)
	if not vars.__counter_added then
		vars.__counter_added = true
		trigger.countsD[guid] = (trigger.countsD[guid] or 0) + 1
		if vars.sourceGUID then
			trigger.countsS[vars.sourceGUID] = (trigger.countsS[vars.sourceGUID] or 0) + 1
		end
		module:AddTriggerCounter(trigger,vars.sourceGUID and trigger.countsS[vars.sourceGUID],trigger.countsD[guid])
	end
	if
		(not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count)) and
		(not triggerData.onlyPlayer or guid == UnitGUID("player"))
	then
		vars.counter = trigger.count
		module:RunTrigger(trigger, vars)
	end
end

local unitAurasInstances = {}
local unitAuras = {}
module.db.unitAuras = unitAuras
module.db.unitAurasInstances = unitAurasInstances
local C_UnitAuras_GetAuraDataByAuraInstanceID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
local C_UnitAuras_GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
if not MRT.isClassic or C_UnitAuras_GetAuraDataByIndex then
	function module.main:UNIT_AURA(unit,updateInfo)
		local triggers = tUNIT_AURA[unit]
		if triggers then
			local funit = unitreplace[unit] or unit

			local guid = UnitGUID(funit)
			if guid then
				local a = unitAurasInstances[guid]
				if not a then
					a = {s = {},n = {}}
					unitAurasInstances[guid] = a
				end

				if updateInfo and not updateInfo.isFullUpdate then
					if updateInfo.removedAuraInstanceIDs then
						for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs) do
							local aura = a[auraInstanceID]
							if aura then
								a[auraInstanceID] = nil
								if aura.spellId then a.s[aura.spellId] = nil end
								if aura.name then a.n[aura.name] = nil end

							end
						end
					end

					if updateInfo.addedAuras then
						for _, aura in next, updateInfo.addedAuras do
							a[aura.auraInstanceID] = aura
							if aura.spellId then a.s[aura.spellId] = aura.auraInstanceID end
							if aura.name then a.n[aura.name] = aura.auraInstanceID end
						end
					end

					if updateInfo.updatedAuraInstanceIDs then
						for _, auraInstanceID in next, updateInfo.updatedAuraInstanceIDs do
							local oldAura = a[auraInstanceID]
							local newAura = C_UnitAuras_GetAuraDataByAuraInstanceID(funit, auraInstanceID)
							if newAura then
								a[auraInstanceID] = newAura
								if oldAura and (oldAura.applications ~= newAura.applications or oldAura.expirationTime ~= newAura.expirationTime) then
									newAura.rem_changed_dur = true
								else
									newAura.rem_changed_dur = nil
								end
							end
						end
					end
				else
					if updateInfo and updateInfo.isFullUpdate then
						wipe(a)
						a.s = {}
						a.n = {}
					end
					for index=1,255 do
						local aura = C_UnitAuras_GetAuraDataByIndex(funit, index, "HELPFUL")
						if not aura then
							break
						end
						a[aura.auraInstanceID] = aura
						if aura.spellId then a.s[aura.spellId] = aura.auraInstanceID end
						if aura.name then a.n[aura.name] = aura.auraInstanceID end
					end
					for index=1,255 do
						local aura = C_UnitAuras_GetAuraDataByIndex(funit, index, "HARMFUL")
						if not aura then
							break
						end
						a[aura.auraInstanceID] = aura
						if aura.spellId then a.s[aura.spellId] = aura.auraInstanceID end
						if aura.name then a.n[aura.name] = aura.auraInstanceID end
					end
				end

				local name = UnitName(funit)
				local now = GetTime()
				for i=1,#triggers do
					local trigger = triggers[i]
					local triggerData = trigger._trigger
					local auraData
					if triggerData.spellID then
						local auraInstanceID = a.s[triggerData.spellID]
						if auraInstanceID then
							auraData = a[auraInstanceID]
						end
					elseif trigger.DspellName then
						local auraInstanceID = a.n[trigger.DspellName]
						if auraInstanceID then
							auraData = a[auraInstanceID]
						end
					end
					local sourceName = auraData and auraData.sourceUnit and UnitName(auraData.sourceUnit) or nil

					if
						auraData and
						(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
						(not trigger.DsourceID or auraData.sourceUnit and trigger.DsourceID(UnitGUID(auraData.sourceUnit))) and
						(not triggerData.sourceMark or auraData.sourceUnit and (GetRaidTargetIndex(auraData.sourceUnit) or 0) == triggerData.sourceMark) and
						(not triggerData.sourceUnit or auraData.sourceUnit and module:CheckUnit(triggerData.sourceUnit,UnitGUID(auraData.sourceUnit),trigger)) and
						(not trigger.DtargetName or name and trigger.DtargetName[name]) and
						(not trigger.DtargetID or trigger.DtargetID(guid)) and
						(not triggerData.targetMark or (GetRaidTargetIndex(funit) or 0) == triggerData.targetMark) and
						(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,guid,trigger)) and
						(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,auraData.applications)) and
						(not triggerData.targetRole or module:CmpUnitRole(funit,triggerData.targetRole))
					then
						if not trigger.statuses[guid] then

							local vars = {
								sourceName = sourceName,
								sourceMark = auraData.sourceUnit and GetRaidTargetIndex(auraData.sourceUnit) or nil,
								targetName = name,
								targetMark = GetRaidTargetIndex(funit),
								stacks = auraData.applications,
								guid = guid,
								sourceGUID = auraData.sourceUnit and UnitGUID(auraData.sourceUnit) or nil,
								targetGUID = guid,
								timeLeft = auraData.expirationTime,
								_auraData = auraData,
								spellID = auraData.spellId,
								spellName = auraData.name,
							}
							trigger.statuses[guid] = vars
							trigger.units[guid] = funit
							if not triggerData.bwtimeleft or auraData.expirationTime - now < triggerData.bwtimeleft then
								TriggerAura_DelayActive(trigger, triggerData, guid, vars)
							else
								local t = MRT.F.ScheduleTimer(TriggerAura_DelayActive, max(auraData.expirationTime - triggerData.bwtimeleft - now, 0.01), trigger, triggerData, guid, vars)
								module.db.timers[#module.db.timers+1] = t
								trigger.delays2[#trigger.delays2+1] = t
							end
						else
							local vars = trigger.statuses[guid]

							vars.timeLeft = auraData.expirationTime
							vars.stacks = auraData.applications

							if auraData.rem_changed_dur then	--for auras with changed durations
								for j=#trigger.delays2,1,-1 do
									if trigger.delays2[j].args[3] == guid then
										trigger.delays2[j]:Cancel()
										tremove(trigger.delays2, j)
									end
								end

								if not triggerData.bwtimeleft or auraData.expirationTime - now < triggerData.bwtimeleft then
									TriggerAura_DelayActive(trigger, triggerData, guid, vars)
								else
									local t = MRT.F.ScheduleTimer(TriggerAura_DelayActive, max(auraData.expirationTime - triggerData.bwtimeleft - now, 0.01), trigger, triggerData, guid, vars)
									module.db.timers[#module.db.timers+1] = t
									trigger.delays2[#trigger.delays2+1] = t
								end
							end
						end
					elseif trigger.statuses[guid] then
						trigger.statuses[guid] = nil
						trigger.units[guid] = nil
						module:DeactivateTrigger(trigger,guid)
						if #trigger.delays2 > 0 then
							for j=#trigger.delays2,1,-1 do
								if trigger.delays2[j].args[3] == guid then
									trigger.delays2[j]:Cancel()
									tremove(trigger.delays2, j)
								end
							end
						end
					end
				end
			end
		end
	end
else
	function module.main:UNIT_AURA(unit,updateInfo)
		local triggers = tUNIT_AURA[unit]
		if triggers then
			local guid = UnitGUID(unit)
			if guid then
				local a = unitAuras[guid]
				if not a then
					a = {}
					unitAuras[guid] = a
				end
				for k,v in next, a do v.r=true end
				for i=1,255 do
					local name, _, count, _, duration, expirationTime, source, _, _, spellId, _, _, _, _, _, val1, val2, val3 = UnitAura(unit, i, "HELPFUL")
					if not spellId then
						break
					elseif not a[spellId] then
						a[spellId] = {name, count, duration, expirationTime, source, spellId, nil, val1, val2, val3}
					else
						local b = a[spellId]
						b[2] = count
						b[3] = duration
						if b[4] ~= expirationTime or b[2] ~= count then
							b[7] = true
						else
							b[7] = nil
						end
						b[4] = expirationTime
						b[8] = val1
						b[9] = val2
						b[10] = val3
						b.r = false
					end
				end
				for i=1,255 do
					local name, _, count, _, duration, expirationTime, source, _, _, spellId, _, _, _, _, _, val1, val2, val3 = UnitAura(unit, i, "HARMFUL")
					if not spellId then
						break
					elseif not a[spellId] then
						a[spellId] = {name, count, duration, expirationTime, source, spellId, nil, val1, val2, val3}
					else
						local b = a[spellId]
						b[2] = count
						b[3] = duration
						b[4] = expirationTime
						if b[4] ~= expirationTime or b[2] ~= count then
							b[7] = true
						else
							b[7] = nil
						end
						b[8] = val1
						b[9] = val2
						b[10] = val3
						b.r = false
					end
				end
				for k,v in next, a do if v.r then a[k]=nil end end

				local name = UnitName(unit)
				local now = GetTime()
				for i=1,#triggers do
					local trigger = triggers[i]
					local triggerData = trigger._trigger
					local auraData
					if triggerData.spellID then
						auraData = a[triggerData.spellID]
					elseif trigger.DspellName then
						for k,v in next, a do
							if v[1] == trigger.DspellName then
								auraData = v
								break
							end
						end
					end
					local sourceName = auraData and auraData[5] and UnitName(auraData[5]) or nil

					if
						auraData and
						(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
						(not trigger.DsourceID or auraData[5] and trigger.DsourceID(UnitGUID(auraData[5]))) and
						(not triggerData.sourceMark or auraData[5] and (GetRaidTargetIndex(auraData[5]) or 0) == triggerData.sourceMark) and
						(not triggerData.sourceUnit or auraData[5] and module:CheckUnit(triggerData.sourceUnit,UnitGUID(auraData[5]),trigger)) and
						(not trigger.DtargetName or name and trigger.DtargetName[name]) and
						(not trigger.DtargetID or trigger.DtargetID(guid)) and
						(not triggerData.targetMark or (GetRaidTargetIndex(unit) or 0) == triggerData.targetMark) and
						(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,guid,trigger)) and
						(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,auraData[2])) and
						(not triggerData.targetRole or module:CmpUnitRole(unit,triggerData.targetRole))
					then
						if not trigger.statuses[guid] or auraData[7] then

							if auraData[7] then	--for auras with changed durations
								for j=#trigger.delays2,1,-1 do
									if trigger.delays2[j].args[3] == guid then
										trigger.delays2[j]:Cancel()
										tremove(trigger.delays2, j)
									end
								end
							end

							local vars = {
								sourceName = sourceName,
								sourceMark = auraData[5] and GetRaidTargetIndex(auraData[5]) or nil,
								targetName = name,
								targetMark = GetRaidTargetIndex(unit),
								stacks = auraData[2],
								guid = guid,
								sourceGUID = auraData[5] and UnitGUID(auraData[5]) or nil,
								targetGUID = guid,
								timeLeft = auraData[4],
								_auraData = auraData,
								spellID = auraData[6],
								spellName = auraData[1],
							}
							trigger.statuses[guid] = vars
							trigger.units[guid] = unit
							if not triggerData.bwtimeleft or auraData[4] - now < triggerData.bwtimeleft then
								TriggerAura_DelayActive(trigger, triggerData, guid, vars)
							else
								local t = MRT.F.ScheduleTimer(TriggerAura_DelayActive, max(auraData[4] - triggerData.bwtimeleft - now, 0.01), trigger, triggerData, guid, vars)
								module.db.timers[#module.db.timers+1] = t
								trigger.delays2[#trigger.delays2+1] = t
							end
						end

						if trigger.statuses[guid] then
							trigger.statuses[guid].timeLeft = auraData[4]
						end
					elseif trigger.statuses[guid] then
						trigger.statuses[guid] = nil
						trigger.units[guid] = nil
						module:DeactivateTrigger(trigger,guid)
						if #trigger.delays2 > 0 then
							for j=#trigger.delays2,1,-1 do
								if trigger.delays2[j].args[3] == guid then
									trigger.delays2[j]:Cancel()
									tremove(trigger.delays2, j)
								end
							end
						end
					end
				end
			end
		end
	end
end

function module:TriggerTargetLookup(unit,triggers)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or trigger.DsourceID(guid))
		then
			local tunit = unit.."target"
			local tguid = UnitGUID(tunit)
			local tname = UnitName(tunit)
			local targetCheck = tguid and
				(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark) and
				(not trigger.DtargetName or tname and trigger.DtargetName[tname]) and
				(not trigger.DtargetID or trigger.DtargetID(tguid)) and
				(not triggerData.targetMark or (GetRaidTargetIndex(tunit) or 0) == triggerData.targetMark) and
				(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,tguid,trigger))

			if not trigger.statuses[guid] and targetCheck then
				trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[guid])
				local vars = {
					sourceName = name,
					sourceMark = GetRaidTargetIndex(unit),
					targetName = tname,
					targetMark = GetRaidTargetIndex(tunit),
					guid = triggerData.guidunit == 1 and guid or tguid,
					counter = trigger.count,
					sourceGUID = guid,
					targetGUID = tguid,
					uid = guid,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not targetCheck then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil
				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:UNIT_TARGET(unit)
	local triggers = tUNIT_TARGET[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		module:TriggerTargetLookup(funit,triggers)
	end
end

function module.main:UNIT_THREAT_LIST_UPDATE(unit)
	local triggers = tUNIT_TARGET[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		module:TriggerTargetLookup(funit,triggers)
	end
end

function module:TriggerSpellCD(triggers)
	local gstartTime, gduration, genabled = GetSpellCooldown(61304)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger

		local spell = triggerData.spellID or trigger.DspellName
		if spell then
			local startTime, duration, enabled, modRate = GetSpellCooldown(spell)
			if type(spell) == "number" and duration == 0 and startTime == 0 then
				startTime, duration, enabled, modRate = GetSpellCooldown(GetSpellName(spell))
			end
			if duration then -- spell found
				if not enabled and select(7, GetSpellInfo(spell)) == 370537 then -- stasis workaround
					duration = 3600
				end
				local cdCheck = duration > gduration and duration > 0 and (not triggerData.bwtimeleft or (startTime + duration - GetTime()) < triggerData.bwtimeleft)

				if not trigger.statuses[1] and cdCheck then
					module:AddTriggerCounter(trigger)
					local name, _, _, _, _, _, spellID = GetSpellInfo(spell)
					local vars = {
						spellID = spellID,
						spellName = name,
						counter = trigger.count,
						timeLeft = startTime + duration * (modRate or 1),
					}
					--special case, check if spell have cd less then dur
					if cdCheck and trigger._data.hideTextChanged and trigger._data.dur and tonumber(trigger._data.dur) > 0 then
						vars.specialTriggerCheck = function(s) if vars.timeLeft < GetTime() + trigger._data.dur then return false else return s or true end end
					end
					trigger.statuses[1] = vars
					if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
						module:RunTrigger(trigger, vars)
					end

					--schedule recheck after cd expiration
					--still can be wrong if cd duration will change afterwards
					local t = MRT.F.ScheduleTimer(module.TriggerSpellCD, max(0.01,duration * (modRate or 1)), self, triggers)
					module.db.timers[#module.db.timers+1] = t
				elseif trigger.statuses[1] and not cdCheck then
					trigger.statuses[1] = nil
					module:DeactivateTrigger(trigger)
				end

				if trigger.statuses[1] then
					trigger.statuses[1].timeLeft = startTime + duration * (modRate or 1)
				end
			end
		end
	end
end

function module.main:SPELL_UPDATE_COOLDOWN()
	local triggers = module.db.eventsToTriggers.CDABIL
	if triggers then
		module:TriggerSpellCD(triggers)
	end
end

function module:TriggerSpellcastSucceeded(unit, triggers, spellID)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or trigger.DsourceID(guid)) and
			(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark) and
			(not triggerData.sourceUnit or module:CheckUnit(triggerData.sourceUnit,guid,trigger)) and
			(not triggerData.spellID or triggerData.spellID == spellID) and
			(not trigger.DspellName or trigger.DspellName == GetSpellName(spellID))
		then
			trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
			module:AddTriggerCounter(trigger,trigger.countsS[guid])
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				local vars = {
					sourceName = UnitName(unit),
					sourceMark = GetRaidTargetIndex(unit),
					spellID = spellID,
					spellName = GetSpellName(spellID),
					guid = guid,
					counter = trigger.count,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end
end

function module.main:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	local triggers = tUNIT_SPELLCAST_SUCCEEDED[unit]

	if triggers then
		local funit = unitreplace[unit] or unit

		module:TriggerSpellcastSucceeded(funit, triggers, spellID)
	end
end

function module:TriggerWidgetUpdate(widgetID, widgetInfo)
	local widgetProgressData, isDouble, widgetRemoved = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(widgetID)
	if not widgetProgressData then
		widgetProgressData = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo(widgetID)
		if not widgetProgressData then
			widgetRemoved = true
		end
		isDouble = true
	end
	local widgetVal, widgetValLeft, widgetValRight
	if not widgetRemoved then
		if not isDouble then
			widgetVal = ((widgetProgressData.barValue or 0) - (widgetProgressData.barMin or 0)) / max((widgetProgressData.barMax or 0) - (widgetProgressData.barMin or 0),1) * 100
		else
			widgetValLeft = ((widgetProgressData.leftBarValue or 0) - (widgetProgressData.leftBarMin or 0)) / max((widgetProgressData.leftBarMax or 0) - (widgetProgressData.leftBarMin or 0),1) * 100
			widgetValRight = ((widgetProgressData.rightBarValue or 0) - (widgetProgressData.rightBarMin or 0)) / max((widgetProgressData.rightBarMax or 0) - (widgetProgressData.rightBarMin or 0),1) * 100
		end
	end
	local triggers = module.db.eventsToTriggers.UPDATE_UI_WIDGET
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not triggerData.spellID or triggerData.spellID == widgetID) and
			(not trigger.DspellName or (
				widgetProgressData.text ~= "" and trigger.DspellName == widgetProgressData.text or
				widgetProgressData.overrideBarText and widgetProgressData.overrideBarText ~= "" and widgetProgressData.overrideBarText:find(trigger.DspellName) or
				widgetProgressData.tooltip and widgetProgressData.tooltip ~= "" and widgetProgressData.tooltip:find(trigger.DspellName)
			))
		then
			local check = trigger.DnumberPercent and
				not widgetRemoved and
				(
				 (widgetVal and module:CheckNumber(trigger.DnumberPercent,widgetVal)) or
				 (widgetValLeft and module:CheckNumber(trigger.DnumberPercent,widgetValLeft)) or
				 (widgetValRight and module:CheckNumber(trigger.DnumberPercent,widgetValRight))
				)

			if not trigger.statuses[widgetID] and check then
				module:AddTriggerCounter(trigger)
				local vars = {
					counter = trigger.count,
					spellName = widgetProgressData.text ~= "" and widgetProgressData.text or widgetProgressData.overrideBarText ~= "" and widgetProgressData.overrideBarText or widgetProgressData.tooltip,
					spellID = widgetID,
					value = widgetVal,
					uid = widgetID,
				}
				trigger.statuses[widgetID] = vars
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[widgetID] and not check then
				trigger.statuses[widgetID] = nil
				module:DeactivateTrigger(trigger,widgetID)
			end

			if trigger.statuses[widgetID] then
				trigger.statuses[widgetID].value = widgetVal
			end
		end
	end
end

do
	local ticker = nil
	local timerWidgets = {}
	local function WidgetTicker(self)
		for id, widget in next, timerWidgets do
			local toremove = true
			local widgetProgressData = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(id)
			--print('tick',id,widgetProgressData and widgetProgressData.barValue)
			if widgetProgressData and widgetProgressData.barValue ~= (widgetProgressData.layoutDirection == 0 and widgetProgressData.barMin or widgetProgressData.barMax) then
				module.main:UPDATE_UI_WIDGET(widget)
				toremove = false
			end
			if toremove then
				timerWidgets[id] = nil
			end
		end
		for _ in next, timerWidgets do
			return
		end
		ticker = nil
		self:Cancel()
	end
	function module.main:UPDATE_UI_WIDGET(widgetInfo)
		module:TriggerWidgetUpdate(widgetInfo.widgetID, widgetInfo)

		if widgetInfo.hasTimer then
			timerWidgets[widgetInfo.widgetID] = widgetInfo
			if not ticker then
				ticker = MRT.F.ScheduleTimer(WidgetTicker,-1)
			end
		end
	end
end

function module:TriggerPartyUnitUpdate(triggers)
	local allGUIDs,allNames, allGroups = {},{},{}
	for _, name, subgroup, class, guid in MRT.F.IterateRoster, MRT.F.GetRaidDiffMaxGroup() do
		if guid and name then
			allGUIDs[guid] = name
			allNames[name] = guid
			allGroups[name] = subgroup
		end
	end
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger

		local list
		local isFirstArg

		if triggerData.pattFind then
			local pattList = module:FindPlayersListInNote(triggerData.pattFind)
			if pattList then
				list = {strsplit(" ",pattList)}
			end
		elseif triggerData.sourceUnit then
			if type(triggerData.sourceUnit) == "number" then
				if triggerData.sourceUnit >= 0 then
					list = {}
					local unitsList = module.datas.unitsList[triggerData.sourceUnit]
					for j=1,#unitsList do
						local name = UnitName(unitsList[j])
						if name then
							list[#list+1] = name
						end
					end
				end
			else
				list = {UnitName(triggerData.sourceUnit)}
			end
		elseif trigger.DsourceName then
			list = trigger.DsourceName
			isFirstArg = true
		end

		if list then
			for arg1,arg2 in next, list do
				local name = isFirstArg and arg1 or arg2
				local guid = allNames[name]
				local group = allGroups[name]

				if
					guid and
					(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,group))
				then
					-- if guid and not trigger.statuses[guid] then
						local vars = {
							sourceName = name,
							sourceGUID = guid,
							guid = guid,
							stacks = group,
							uid = guid,
							counter = 0,
						}
						trigger.statuses[guid] = vars
						trigger.units[guid] = name

						module:RunTrigger(trigger, vars)
					-- elseif guid and trigger.statuses[guid] and trigger._reminder.params then
						-- trigger._reminder.params.stacks = group
						-- trigger._reminder.params["stacks".. trigger._i] = group
					-- end
				elseif trigger.statuses[guid] then
					trigger.statuses[guid] = nil
					trigger.units[guid] = nil

					module:DeactivateTrigger(trigger,guid)
				end
			end
		end

		for guid in next, trigger.statuses do
			if not allGUIDs[guid] or not (not trigger.Dstacks or module:CheckNumber(trigger.Dstacks, allGroups[ allGUIDs [guid] ])) then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:GROUP_ROSTER_UPDATE()
	local triggers = module.db.eventsToTriggers.RAID_GROUP_NUMBER
	if triggers then
		module:TriggerPartyUnitUpdate(triggers)
	end
end

function module:TriggerCast(unit,triggers,spellID,isStart,endTime)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	local spellName = GetSpellName(spellID)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not triggerData.spellID or spellID == triggerData.spellID) and
			(not trigger.DspellName or spellName == trigger.DspellName) and
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or guid and trigger.DsourceID(guid)) and
			(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark)
		then
			if not trigger.statuses[guid] and isStart then
				trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[guid])
				local vars = {
					sourceName = name,
					sourceMark = GetRaidTargetIndex(unit),
					guid = guid,
					counter = trigger.count,
					spellID = spellID,
					spellName = spellName,
					timeLeft = endTime,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not isStart then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:UNIT_SPELLCAST_START(unit,castGUID,spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		local name, text, texture, startTime, endTime, isTradeSkill, castID, interruptible, spellId = UnitCastingInfo(funit)
		module:TriggerCast(funit,triggers,spellID,true,(endTime or 0)/1000)
	end
end
function module.main:UNIT_SPELLCAST_CHANNEL_START(unit,castGUID,spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		local name, text, texture, startTime, endTime, isTradeSkill, interruptible, spellId = UnitChannelInfo(funit)
		module:TriggerCast(funit,triggers,spellID,true,(endTime or 0)/1000)
	end
end

function module.main:UNIT_SPELLCAST_STOP(unit,castGUID,spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		local funit = unitreplace[unit] or unit

		module:TriggerCast(funit,triggers,spellID,false)
	end
end

function module.main:UNIT_SPELLCAST_CHANNEL_STOP(unit, castGUID, spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		module:TriggerCast(unit, triggers, spellID, false)
	end
end

function module.main:UNIT_CAST_CHECK(unit)
	local funit = unitreplace[unit] or unit

	local name, text, texture, startTime, endTime, isTradeSkill, castID, interruptible, spellId = UnitCastingInfo(funit)
	if name then
		local triggers = tUNIT_CAST[unit]
		if triggers then
			module:TriggerCast(funit,triggers,spellId,true,(endTime or 0)/1000)
		end
	else
		local name, text, texture, startTime, endTime, isTradeSkill, interruptible, spellId = UnitChannelInfo(funit)
		if name then
			local triggers = tUNIT_CAST[unit]
			if triggers then
				module:TriggerCast(funit,triggers,spellId,true,(endTime or 0)/1000)
			end
		end
	end
end

local CLEUIsHistoryEvent = {
	["SPELL_CAST_SUCCESS"] = true,
	["SPELL_CAST_START"] = true,
	["SPELL_AURA_APPLIED"] = true,
	["SPELL_AURA_REMOVED"] = true,
}

function module.main.COMBAT_LOG_EVENT_UNFILTERED(timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellID,spellName,school,arg1,arg2)
	local triggers = tCOMBAT_LOG_EVENT_UNFILTERED[event]
	if triggers then
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				(not triggerData.spellID or triggerData.spellID == spellID) and
				(not trigger.DspellName or trigger.DspellName == spellName) and
				(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
				(not trigger.DsourceID or trigger.DsourceID(sourceGUID)) and
				(not triggerData.sourceMark or module.datas.markToIndex[sourceFlags2] == triggerData.sourceMark) and
				(not triggerData.sourceUnit or module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger)) and
				(not trigger.DtargetName or destName and trigger.DtargetName[destName]) and
				(not trigger.DtargetID or trigger.DtargetID(destGUID)) and
				(not triggerData.targetMark or module.datas.markToIndex[destFlags2] == triggerData.targetMark) and
				(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,destGUID,trigger)) and
				(not triggerData.extraSpellID or triggerData.extraSpellID == arg1) and
				(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,arg2)) and
				(not triggerData.pattFind or triggerData.pattFind == arg1) and
				(not triggerData.targetRole or destName and module:CmpUnitRole(destName,triggerData.targetRole))
			then
				trigger.countsS[sourceGUID] = (trigger.countsS[sourceGUID] or 0) + 1
				trigger.countsD[destGUID] = (trigger.countsD[destGUID] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[sourceGUID],trigger.countsD[destGUID])
				if
					(not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count)) and
					(not triggerData.onlyPlayer or destGUID == UnitGUID("player"))
				then
					local vars = {
						sourceName = sourceName,
						sourceMark = module.datas.markToIndex[sourceFlags2],
						targetName = destName,
						targetMark = module.datas.markToIndex[destFlags2],
						spellName = spellName,
						spellID = spellID,
						extraSpellID = arg1,
						stacks = (event == "SPELL_AURA_APPLIED_DOSE" or event == "SPELL_AURA_REMOVED_DOSE") and arg2 or 1,
						counter = trigger.count,
						guid = triggerData.guidunit == 1 and sourceGUID or destGUID,
						sourceGUID = sourceGUID,
						targetGUID = destGUID,
						uid = module:GetNextUID(),
					}
					module:RunTrigger(trigger, vars)
				end
			end
		end
	end

	-- https://warcraft.wiki.gg/wiki/UnitFlag
	-- bitflag checks for hostile and controlled by npc
	-- but MC'd players may be recognized as outsider pet controlled by npc
	-- so we have to check if sourceGUID is player
	if IsHistoryEnabled and CLEUIsHistoryEvent[event] and bit_band(sourceFlags, 0x000003F0) == 0x00000240 and not GUIDIsPlayer(sourceGUID) then
		module:AddHistoryEntry(1,event,spellID,sourceGUID,sourceName,sourceFlags2,destGUID,destName,destFlags2)
	end
end

function module:TriggerBWMessage(key, text)
	local triggers = module.db.eventsToTriggers.BW_MSG
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(triggerData.pattFind or triggerData.spellID) and
			(not triggerData.pattFind or module:FindInString(text,triggerData.pattFind)) and
			(not triggerData.spellID or key == triggerData.spellID)
		then
			module:AddTriggerCounter(trigger)
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				local vars = {
					counter = trigger.count,
					spellID = key,
					spellName = text,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end
end

local function TriggerBWTimer_DelayActive(trigger, triggerData, expirationTime, key, text)
	module:AddTriggerCounter(trigger)
	if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter, trigger.count) then
		local vars = {
			counter = trigger.count,
			spellID = key,
			spellName = text,
			timeLeft = expirationTime,
			uid = module:GetNextUID(),
		}
		module:RunTrigger(trigger, vars)
	end
end

function module:TriggerBWTimer(key, text, duration)
	local triggers = module.db.eventsToTriggers.BW_TIMER
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			key == -1 or
			(
				triggerData.bwtimeleft and tonumber(triggerData.bwtimeleft) and
				(duration == 0 or duration >= tonumber(triggerData.bwtimeleft)) and
				(
					(triggerData.pattFind or triggerData.spellID) and
					(not triggerData.pattFind or module:FindInString(text,triggerData.pattFind)) and
					(not triggerData.spellID or key == triggerData.spellID)
				)
			)
		then
			if duration == 0 then
				for i=1,#trigger.delays2 do
					trigger.delays2[i]:Cancel()
				end
				wipe(trigger.delays2)
			else
				local t = MRT.F.ScheduleTimer(TriggerBWTimer_DelayActive, max(duration - triggerData.bwtimeleft, 0.01), trigger, triggerData, GetTime() + duration, key, text)
				module.db.timers[#module.db.timers+1] = t
				trigger.delays2[#trigger.delays2+1] = t
			end
		end
	end
end

do
	local BigWigsTextToKeys = {}

	local registeredBigWigsEvents = {}
	local timers_on_pull = {}

	local function BigWigsEventCallback(event, ...)
		if not event or not registeredBigWigsEvents[event] then
			return
		end
		if (event == "BigWigs_Message") then
			local bwModule, key, text, color, icon = ...

			if module.db.eventsToTriggers.BW_MSG then
				module:TriggerBWMessage(key, text)
			end
		elseif event == "BigWigs_SetStage" then
			local bwModule, stage = ...
			if VMRT.Reminder.bwDebug then prettyPrint("BigWigs_SetStage",...) end
			if stage and module.db.eventsToTriggers.BOSS_PHASE then
				module:TriggerBossPhase(tostring(stage))
			end
		elseif (event == "BigWigs_StartBar") then
			local bwModule, key, text, duration, icon = ...

			BigWigsTextToKeys[text] = key
			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(key, text, 0)
				module:TriggerBWTimer(key, text, duration)
			end

			if not module.db.encounterID then
				timers_on_pull[#timers_on_pull+1] = {event, ...}
			end
		elseif (event == "BigWigs_ResumeBar") then
			local bwModule, text = ...

			local duration = 0
			if BigWigs:GetPlugin("Bars") and bwModule then
				duration = bwModule:BarTimeLeft(text)
			else
				if VMRT.Reminder.bwDebug then prettyPrint("else IN: if BigWigs:GetPlugin(\"Bars\") and bwModule then") end
				if not BigWigs:GetPlugin("Bars") then
					if VMRT.Reminder.bwDebug then VMRT.Reminder.bwDebugprint("else IN: if BigWigs:GetPlugin(\"Bars\") then") end
				end

				if not bwModule then
					if VMRT.Reminder.bwDebug then prettyPrint("else IN: if bwModule then") end
				end
			end
			if duration == 0 then
				return
			end

			if module.db.eventsToTriggers.BW_TIMER and text then
				module:TriggerBWTimer(BigWigsTextToKeys[text], text, duration)
			end
		elseif (event == "BigWigs_StopBar") or (event == "BigWigs_PauseBar") then
			local bwModule, text = ...

			if module.db.eventsToTriggers.BW_TIMER and text then
				module:TriggerBWTimer(BigWigsTextToKeys[text], text, 0)
				if VMRT.Reminder.bwDebug then prettyPrint("elseif (event == \"BigWigs_StopBar\") or (event == \"BigWigs_PauseBar\") then",...,BigWigsTextToKeys[text]) end
			end
		elseif (event == "BigWigs_StopBars" or event == "BigWigs_OnBossDisable"	or event == "BigWigs_OnPluginDisable") then
			local bwModule = ...

			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(-1, nil, 0)
			end
		elseif event == "BigWigs_OnBossEngage" then
			module:RegisterBigWigsCallback("BigWigs_StartBar")

			wipe(timers_on_pull)
			MRT.F.After(2,function()
				wipe(timers_on_pull)
			end)
		end
	end

	function module:BigWigsRecallEncounterStartEvents()
		for i=1,#timers_on_pull do
			BigWigsEventCallback(unpack(timers_on_pull[i]))
		end
		wipe(timers_on_pull)
	end

	function module:RegisterBigWigsCallback(event)
		if registeredBigWigsEvents[event] then
			return
		end
		if BigWigsLoader then
			BigWigsLoader.RegisterMessage(module, event, BigWigsEventCallback)
			registeredBigWigsEvents[event] = true
		end
	end

	function module:UnregisterBigWigsCallback(event)
		if not registeredBigWigsEvents[event] then
			return
		end
		if BigWigsLoader then
			BigWigsLoader.UnregisterMessage(module, event)
			registeredBigWigsEvents[event] = nil
		end
	end
end

do
	local registeredDBMEvents = {}
	local timers_on_pull = {}

	local DBMIdToSpellID = {}
	local DBMIdToText = {}
	local function DBMEventCallback(event, ...)
		if BigWigsLoader then
			return
		end
		if not event or not registeredDBMEvents[event] then
			return
		end

		if (event == "DBM_Announce") then
			local message, icon, announce_type, spellId, modId = ...

			if module.db.eventsToTriggers.BW_MSG then
				module:TriggerBWMessage(spellId, message)
			end
		elseif event == "DBM_TimerStart" then
			local id, msg, duration, icon, timerType, spellId, dbmType = ...

			if not id then return end
			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(spellId, msg, duration)
			end

			if not module.db.encounterID then
				timers_on_pull[#timers_on_pull+1] = {event, ...}
			end
		elseif event == "DBM_TimerStop" or event == "DBM_TimerPause" then
			local id = ...
			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", 0)
			end
		elseif (event == "DBM_TimerResume") then
			local id = ...

			local duration = 0
			if type(DBT) == "table" and DBT.GetBar and id then
				local bar = DBT:GetBar(id)
				duration = bar and bar.timer or 0
			end
			if duration == 0 then
				return
			end

			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", duration)
			end
		elseif (event == "DBM_TimerUpdate") then
			local id, elapsed, duration = ...

			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", duration - elapsed)
			end
		elseif event == "DBM_SetStage" then
			local addon, modId, stage, encounterId, stageTotal = ...
			if stage then
				module:TriggerBossPhase(tostring(stage),tostring(stageTotal))
			end
		elseif event == "kill" or event == "wipe" then
			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(-1, nil, 0)
			end
		elseif event == "DBM_Pull" then
			module:RegisterDBMCallback("DBM_TimerStart")

			wipe(timers_on_pull)
			MRT.F.After(2,function()
				wipe(timers_on_pull)
			end)
		end
	end

	function module:DBMRecallEncounterStartEvents()
		for i=1,#timers_on_pull do
			DBMEventCallback(unpack(timers_on_pull[i]))
		end
		wipe(timers_on_pull)
	end

	function module:RegisterDBMCallback(event)
		if registeredDBMEvents[event] then
			return
		end
		if type(DBM)=='table' and DBM.RegisterCallback then
			registeredDBMEvents[event] = true

			if event == "DBM_kill" or event == "DBM_wipe" then
				event = event:sub(5)
			end
			if not DBM:IsCallbackRegistered(event, DBMEventCallback) then
				DBM:RegisterCallback(event, DBMEventCallback)
			end
		end
	end

	function module:UnregisterDBMCallback(event)
		if not registeredDBMEvents[event] then
			return
		end
		if type(DBM)=='table' and DBM.UnregisterCallback then
			registeredDBMEvents[event] = nil

			if event == "DBM_kill" or event == "DBM_wipe" then
				event = event:sub(5)
			end
			DBM:UnregisterCallback(event, DBMEventCallback)
		end
	end
end

---------------------------------------
-- Triggers Handling 2 (Creating Triggres)
---------------------------------------

function module:CopyTriggerEventForReminder(trigger)
	if trigger.event ~= 1 then
		return trigger
	end
	local new = MRT.F.table_copy2(trigger)
	local eventDB = module.C[trigger.eventCLEU or 0]
	for k,v in next, new do
		if eventDB and not MRT.F.table_find(eventDB.triggerFields,k) and k ~= "andor" and k ~= "event" then
			new[k] = nil
		end
	end
	if eventDB and not MRT.F.table_find(eventDB.triggerFields,"targetName") then
		new.guidunit = 1
	end
	if eventDB and not MRT.F.table_find(eventDB.triggerFields,"sourceName") then
		new.guidunit = nil
	end
	if new.eventCLEU == "ENVIRONMENTAL_DAMAGE" then
		if new.spellID == 1 then
			new.spellID = "Falling"
		elseif new.spellID == 2 then
			new.spellID = "Drowning"
		elseif new.spellID == 3 then
			new.spellID = "Fatigue"
		elseif new.spellID == 4 then
			new.spellID = "Fire"
		elseif new.spellID == 5 then
			new.spellID = "Lava"
		elseif new.spellID == 6 then
			new.spellID = "Slime"
		end
	end
	return new
end

function module:FindInString(text, subj)
	if type(text) ~= "string" or not subj then
		return
	end
	subj = tostring(subj)
	if subj:find("^=") then
		if text == subj:sub(2) then
			return true
		else
			return false
		end
	elseif text:find(subj, 1, true) then
		return true
	else
		return false
	end
end

function module:FindNumberInString(num,str)
	if type(str) == "number" then
		return num == str
	elseif type(str) ~= "string" then
		return
	end
	num = tostring(num)
	for n in string_gmatch(str,"[^, ]+") do
		if n == num then
			return true
		end
	end
end

function module:CreateNumberConditions(str)
	if not str then
		return
	end
	local r = {}
	for w in string_gmatch(str, "[^, ]+") do
		local isPlus
		if w:find("^%+") then
			isPlus = true
			w = w:sub(2)
		end
		local n = tonumber(w)
		local f
		if n then
			if n < 0 then
				n = -n
				local n1,n2 = floor(n),floor((n % 1) * 10)
				f = function(v) return (v % n1) == n2 end
			else
				f = function(v) return v == n end
			end
		elseif w:find("%%") then
			local a,b = w:match("(%d+)%%(%d+)")
			if a and b then
				a = tonumber(a) - 1
				b = tonumber(b)
				f = function(v)
					if a == (v - 1) % b then
						return true
					end
				end
			end
		elseif w:find("^>=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v >= n end
		elseif w:find("^>") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v > n end
		elseif w:find("^<=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v <= n end
		elseif w:find("^<") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v < n end
		elseif w:find("^!") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v ~= n end
		elseif w:find("^=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v == n end
		end
		if f then
			if isPlus and #r > 0 then
				local c = r[#r]
				r[#r] = function(v)
					return c(v) and f(v)
				end
			else
				r[#r+1] = f
			end
		end
	end
	return r
end

function module:CreateStringConditions(str)
	if not str then
		return
	end
	local isReverse
	if str:find("^%-") then
		isReverse = true
		str = str:sub(2)
	end
	local r = {}
	for w in string_gmatch(str, "[^;]+") do
		r[w] = true
	end
	if isReverse then
		local t = r
		r = setmetatable({},{__index = function(_,v)
				if t[v] then
					return false
				else
					return true
				end
			end})
	end
	return r
end

function module:CreateMobIDConditions(str)
	if not str then
		return
	end
	local r = {}
	for w in string_gmatch(str,"[^,]+") do
		local substr = w
		if w:find(":") then
			local condID,condSpawn = strsplit(":",substr,2)
			r[#r+1] = function(guid)
				local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
				if mobID == condID and (unitType == "Creature" or unitType == "Vehicle") then
					local spawnIndex = bit.rshift(bit.band(tonumber(strsub(spawnID, 1, 5), 16), 0xffff8), 3)
					-- if VMRT.Reminder.debug then prettyPrint("SpawnIndex: "..tostring(spawnIndex)) end
					return condSpawn == tostring(spawnIndex)
				end
			end
		else
			r[#r+1] = function(guid)
				return select(6,strsplit("-", guid or "")) == substr
			end
		end
	end
	if #r > 1 then
		return function(guid)
			for i=1,#r do
				if r[i](guid) then
					return true
				end
			end
		end
	else
		return r[1]
	end
end


function module:ConvertMinuteStrToNum(delayStr,notePattern)
	if not delayStr then
		return
	end
	local r = {}
	for w in string_gmatch(delayStr,"[^, ]+") do
		if w:lower() == "note" then
			w = "0"
			if notePattern then
				local found, line = module:FindPlayerInNote(notePattern)
				if found and line then
					local t = line:match("{time:([0-9:%.]+)")
					if t then
						w = t
					end
				end
			end
		end

		local delayNum = tonumber(w)
		if delayNum then
			r[#r+1] = delayNum > 0 and delayNum or 0.01
		else
			local m,s,ms = w:match("(%d+):(%d+)%.?(%d*)")
			if m and s then
				m = tonumber(m)
				s = tonumber(s)
				ms = ms and tonumber("0."..ms) or 0
				local rn = m * 60 + s + ms
				r[#r+1] = rn > 0 and rn or 0.01
			end
		end
	end
	if #r > 0 then
		return r
	else
		return
	end
end

do
	local helpTable = {}
	function module.IterateTable(t)
		if type(t) == "table" then
			return next, t
		else
			helpTable[1] = t
			return next, helpTable
		end
	end
end

local function CheckNoteCache(cacheKey, y, x, customName)
	local nameToFind = customName or playerName
	-- pos = pos % #allpos
	-- if pos == 0 then pos = #allpos end
	if cacheKey:find("^block") then
		if notePatsCache[cacheKey] then
			local currCache = notePatsCache[cacheKey]
			if y then
				y = y % #currCache
				if y == 0 then y = #currCache end
				if x and currCache[y] then -- targeted spot
					x = x % #currCache[y]
					if x == 0 then x = #currCache[y] end
					if currCache[y][x] and currCache[y][x]:find(nameToFind) then
						return true, true
					end
				else -- iterate whole line
					for i=1,#currCache[y] do
						if currCache[y][i] and currCache[y][i]:find(nameToFind) then
							return true, true
						end
					end
				end
			else -- iterate whole cache
				for i=1,#currCache do
					for j=1,#currCache[i] do
						if currCache[i][j] and currCache[i][j]:find(nameToFind) then
							return true, true
						end
					end
				end
			end

			return true -- have cache but no player found
		end
	else -- patt is for lines
		if notePatsCache[cacheKey] then
			local currCache = notePatsCache[cacheKey]
			if y then -- targeted spot
				y = y % #currCache
				if y == 0 then y = #currCache end
				if currCache[y] and currCache[y]:find(nameToFind) then
					return true, true
				end
				return true -- have cache but no player found
			else -- iterate whole line
				for i,name in next, currCache do
					if name:find(nameToFind) then
						return true, true
					end
				end
			end
		end
	end

	-- no cache
end

function module:ParseNote(data, nameToFind)
	local notepat = data.notepat
	local reverse, pat, storePosData, y, x = notepat:match("^(%-?)([^{]+){(pos):?(%d*):?(%d*)}")
	pat = pat and pat:trim() -- trim is needed to securly catch patStart patEnd
	reverse = reverse ~= "" -- if reverse is not found it returns an empty string, make sure it is not counts as "true"
	if not storePosData then
		return module:FindPlayerInNote(data.notepat,data.noteIsBlock)
	end

	x = tonumber(x) -- pos in line
	y = tonumber(y) -- line num


	local cacheKey = (data.noteIsBlock and "block" or "line") .. pat
	local haveCache, playerFound = CheckNoteCache(cacheKey, y, x, nameToFind)
	if playerFound then
		return not reverse -- true
	elseif haveCache then
		return reverse -- false
	end

	pat = "^"..pat:gsub("([%.%(%)%-%$])","%%%1"):gsub("%b{}","") -- double {} check
	local noteData = {}

	if data.noteIsBlock then
		local lines = {strsplit("\n", VMRT.Note.Text1)}
		local lineNum = 0
		local betweenLines = false
		for i=1,#lines do
			if lines[i]:trim():find(pat.."Start$") then
				betweenLines = true
			elseif lines[i]:trim():find(pat.."End$") then
				betweenLines = false
				break
			elseif betweenLines then
				local line = lines[i]:gsub("|c........",""):gsub("|r",""):gsub("%b{}",""):gsub("|",""):gsub(" +"," "):trim()
				lineNum = lineNum + 1
				local u,uc = {},0
				line = line:gsub("%b()",function(a)
					uc = uc + 1
					u[uc] = a:sub(2,-2):trim()
					return "##"..uc
				end)
				local allpos = {strsplit(" ", line)}
				for i,name in ipairs(allpos) do
					if name:find("^##%d+$") then
						local c = name:match("^##(%d+)$")
						allpos[i] = u[tonumber(c)]
					end
				end
				noteData[lineNum] = allpos
			end
		end
	else
		local lines = {strsplit("\n", VMRT.Note.Text1)}
		for i=1,#lines do
			if lines[i]:find(pat) then
				-- pos = tonumber(pos)
				local line = lines[i]:gsub(pat,""):gsub("|c........",""):gsub("|r",""):gsub("%b{}",""):gsub("|",""):gsub(" +"," "):trim()
				local u,uc = {},0
				line = line:gsub("%b()",function(a)
					uc = uc + 1
					u[uc] = a:sub(2,-2):trim()
					return "##"..uc
				end)
				local allpos = {strsplit(" ", line)}

				for i,name in ipairs(allpos) do
					if name:find("^##%d+$") then
						local c = name:match("^##(%d+)$")
						allpos[i] = u[tonumber(c)]
					end
				end

				noteData = allpos
				break
			end
		end
	end
	if #noteData == 0 then
		noteData = nil
	end
	notePatsCache[cacheKey] = noteData
	haveCache, playerFound = CheckNoteCache(cacheKey, y, x, nameToFind)
	if playerFound then
		return not reverse -- true
	else
		return reverse --false
	end
end

function module:FindPlayerInNote(pat,isNoteBlock)
	local reverse, pat = pat:match("^(%-?)([^{]+)")
	pat = pat and pat:trim()
	reverse = reverse ~= "" -- if reverse is not found it returns an empty string, make sure it is not counts as "true"
	-- local reverse = pat:find("^%-")
	pat = "^"..pat:gsub("([%.%(%)%-%$])","%%%1"):gsub("%b{}","") -- double {} check
	if not VMRT or not VMRT.Note or not VMRT.Note.Text1 then
		return
	end
	if not isNoteBlock then
		local lines = {strsplit("\n", VMRT.Note.Text1)}
		for i=1,#lines do
			if lines[i]:find(pat) then
				local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				l = l:gsub("%b()",function(a)
					return a:sub(2,-2):trim()
				end)
				local list = {strsplit(" ", l)}
				for j=1,#list do
					if list[j] == playerName then
						if reverse then
							return false, lines[i]
						else
							return true, lines[i]
						end
					end
				end
			end
		end
	else
		local lines = {strsplit("\n", VMRT.Note.Text1)}
		local betweenLines = false
		for i=1,#lines do
			if lines[i]:find(pat.."Start$") then
				betweenLines = true
			elseif lines[i]:find(pat.."End$") then
				betweenLines = false
				break
			elseif betweenLines then
				local l = lines[i]:gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
				l = l:gsub("%b()",function(a)
					return a:sub(2,-2):trim()
				end)
				local list = {strsplit(" ", l)}
				for j=1,#list do
					if list[j] == playerName then
						if reverse then
							return false, lines[i]
						else
							return true, lines[i]
						end
					end
				end
			end
		end
	end
	if reverse then
		return true
	end
end

---------------------------------------
-- Functions That Used When Showing Reminders
---------------------------------------
do
	local function isMostlyRussian(text)
		-- Remove everything except letters (both Latin and Cyrillic)
		local letters = text:gsub("[^%aА-ЯЁа-яё]", "")
		if letters == "" then
		   return false
		end
		local russianCount = 0
		for uchar in letters:gmatch(".") do
		   if uchar:match("[А-ЯЁа-яё]") then
			  russianCount = russianCount + 1
		   end
		end
		return (russianCount / #letters) > 0.5
	 end

	 local function isMostlyKorean(text)
		-- Get all alphabetical characters (English and Korean)
		local letters = text:gsub("[^%a가-힣]", "")
		if letters == "" then
			return false
		end

		local koreanCount = 0
		for uchar in letters:gmatch(".") do
			if uchar:match("[가-힣]") then
				koreanCount = koreanCount + 1
			end
		end
		return (koreanCount / #letters) > 0.5
	end

	local missingTTSStrings = {}

	if VMRT.Reminder then
		missingTTSStrings = VMRT.Reminder.missingTTSStrings or {}
		VMRT.Reminder.missingTTSStrings = missingTTSStrings
	end
	local function exportMissingTTSStrings()
		local t = {}
		for k in next, missingTTSStrings do
			tinsert(t,k)
		end
		table.sort(t)
		MRT.F:Export(table.concat(t, "\n"))
		wipe(missingTTSStrings)
	end
	SlashCmdList["REMINDER_EXPORT_MISSING_TTS"] = exportMissingTTSStrings
	SLASH_REMINDER_EXPORT_MISSING_TTS1 = "/remindertts"

	local soundPaths = {
		"Interface\\TTS\\",
		"Interface\\AddOns\\".. GlobalAddonName.. "\\Media\\Private\\TTS\\",
		"Interface\\AddOns\\".. GlobalAddonName.. "\\Media\\Sounds\\TTS\\",
	}
	local markToText = {
		["{rt1}"] = "Star",
		["{rt2}"] = "Orange",
		["{rt3}"] = "Purple",
		["{rt4}"] = "Green",
		["{rt5}"] = "Moon",
		["{rt6}"] = "Blue",
		["{rt7}"] = "Cross",
		["{rt8}"] = "Skull",
	}


	local LibTranslit = LibStub("LibTranslit-1.0")
	function module:PlayTTS(msg, params, forceUseTTSFiles)
		if type(msg) == "number" then
			msg = tostring(msg)
		end
		if type(msg) ~= "string" then
			error("PlayTTS: msg must be a string or number, got: "..type(msg), 2)
		end
		msg = msg:gsub("{rt%d}", markToText)

		local message = module:FormatMsg(msg or "", params)


		local willPlay

		if not VMRT.Reminder.VisualSettings.TTS_IgnoreFiles or forceUseTTSFiles then
			local sound = tostring(message):trim()

			for i=1,#soundPaths do
				local soundFile = format("%s%s.mp3", soundPaths[i], sound)
				willPlay = PlaySoundFile(soundFile, "Master")
				if willPlay then break end

				soundFile = format("%s%s.ogg", soundPaths[i], sound)
				willPlay = PlaySoundFile(soundFile, "Master")
				if willPlay then break end
			end
		end

		if not willPlay then
			if AddonDB.IsDev then
				missingTTSStrings[message] = true
			end
			local ttsVoice = VMRT.Reminder.VisualSettings.TTS_Voice or TextToSpeech_GetSelectedVoice(Enum.TtsVoiceType.Standard).voiceID
			if MRT.locale ~= "koKR" and VMRT.Reminder.VisualSettings.TTS_VoiceAlt and isMostlyRussian(message) then
				ttsVoice = VMRT.Reminder.VisualSettings.TTS_VoiceAlt
			elseif MRT.locale == "koKR" and VMRT.Reminder.VisualSettings.TTS_VoiceAlt and isMostlyKorean(message) then
				ttsVoice = VMRT.Reminder.VisualSettings.TTS_VoiceAlt
			elseif module.db.isTtsTranslateNeeded then
				message = LibTranslit:Transliterate(message)
			end

			C_VoiceChat_SpeakText(
				ttsVoice,
				message,
				Enum.VoiceTtsDestination.QueuedLocalPlayback,
				VMRT.Reminder.VisualSettings.TTS_VoiceRate or 0,
				VMRT.Reminder.VisualSettings.TTS_VoiceVolume or 75
			)
		end
	end
end

function module:SendWeakAurasCustomEvent(msg,params)
	msg = module:FormatMsg(msg,params)
	local argsTable = {}

	for v in string_gmatch(msg, "[^ ]+") do
		tinsert(argsTable, v)
	end

	-- for i,arg in ipairs(argsTable) do
	-- 	prettyPrint(i,arg,type(arg))
	-- end

	WeakAuras.ScanEvents(unpack(argsTable))
end

local function stopFrameGlow(unitData)
	local glow_frame = unitData.frame and unitData.frame.__ReminderGlowFrame
	local id = unitData.key
	if glow_frame then
		if unitData.cancelFunc then
			unitData.cancelFunc(glow_frame,id)
		end

		-- if glow_frame.text then
		--     glow_frame.text:Hide()
		--     glow_frame.textUpate:Hide()
		-- end
	end
end

local function startFrameGlow(unitData)
	local unitFrame = unitData.frame
	if not unitFrame then return end

	if not unitFrame.__ReminderGlowFrame then
		unitFrame.__ReminderGlowFrame = CreateFrame("Frame", nil, unitFrame)
		unitFrame.__ReminderGlowFrame:SetAllPoints(unitFrame)
		unitFrame.__ReminderGlowFrame:SetSize(unitFrame:GetSize())
		unitFrame.__ReminderGlowFrame:SetFrameLevel(unitFrame:GetFrameLevel() + 15)
	end

	local glow_frame = unitFrame.__ReminderGlowFrame
	if glow_frame:GetWidth() < 1 or glow_frame:GetHeight() < 1 then
		stopFrameGlow(unitData)
		return
	end

	local data = unitData.data
	-- local frameText = data.frameText or "%tsize:30{spell:642}"

	-- if frameText then

	--     if not glow_frame.text then
	--         glow_frame.text = glow_frame:CreateFontString(nil,"OVERLAY","GameFontWhite")
	--         glow_frame.text:SetFont(MRT.F.defFont, 12, "OUTLINE")
	--         glow_frame.text.size = 12
	--         glow_frame.text:SetAllPoints()

	--         glow_frame.textUpate = CreateFrame("Frame",nil,glow_frame)
	--         glow_frame.textUpate:SetPoint("CENTER")
	--         glow_frame.textUpate:SetSize(1,1)
	--         glow_frame.textUpate:Hide()
	--         glow_frame.textUpate.tmr = 0
	--         glow_frame.textUpate.text = glow_frame.text
	--         glow_frame.textUpate:SetScript("OnUpdate",NameplateFrame_TextUpdate)
	--     end

	--     local text = frameText
	--     local t = unitData


	-- 	if text:find("%%tsize:%d+") then
	-- 		local tsize = text:match("%%tsize:(%d+)")
	-- 		t.textSize = tonumber(tsize)
	-- 		text = text:gsub("%%tsize:%d+","")
	--     else
	--         t.textSize = 12
	-- 	end

	-- 	if text:find("%%tpos:..") then
	-- 		local posH,posV = text:match("%%tpos:(.)(.)")
	-- 		if posH == "L" then t.justifyH = "LEFT"
	-- 			elseif posH == "C" then t.justifyH = "CENTER"
	-- 			elseif posH == "R" then t.justifyH = "RIGHT" end
	-- 		if posV == "T" then t.justifyV = "TOP"
	-- 			elseif posV == "M" then t.justifyV = "MIDDLE"
	-- 			elseif posV == "B" then t.justifyV = "BOTTOM" end
	-- 		text = text:gsub("%%tpos:..","")
	-- 	end

	-- 	local textPreFormat = text
	-- 	t.text, t.textUpdateReq = module:FormatMsg(text,t.params)
	-- 	if t.textUpdateReq and not data.dynamicdisable then
	-- 		glow_frame.textUpate.func = function()
	-- 			return module:FormatMsg(textPreFormat,t.params)
	-- 		end
	--         glow_frame.textUpate:Show()
	-- 	else
	-- 		t.textUpdateReq = nil
	-- 	end
	--     if t.textSize ~= glow_frame.text.size then
	--         glow_frame.text:SetFont(glow_frame.text:GetFont(),t.textSize,"OUTLINE")
	--         glow_frame.text.size = t.textSize
	--     end
	--     glow_frame.text:ClearAllPoints()
	--     if t.justifyH == "LEFT" then glow_frame.text:SetPoint("LEFT")
	--         elseif t.justifyH == "RIGHT" then glow_frame.text:SetPoint("RIGHT")
	--         else glow_frame.text:SetPoint("CENTER") end
	--     if t.justifyV == "TOP" then glow_frame.text:SetPoint("TOP")
	--         elseif data.justifyV == "BOTTOM" then glow_frame.text:SetPoint("BOTTOM")
	--         else glow_frame.text:SetPoint("CENTER") end
	--     glow_frame.text:SetText(t.text or "")

	--     glow_frame.text:Show()
	-- else
	--     if glow_frame.text then
	--         glow_frame.text:Hide()
	--         glow_frame.textUpate:Hide()
	--     end
	-- end

	local id = unitData.key

	local duration = data.duration and data.duration ~= 0 and data.duration or 2
	local untimed = (data.duration and data.duration == 0) and true or false
	if data.glow then
		local GlowSettings = VMRT.Reminder.VisualSettings.Glow

		local colorPalette = data.glowFrameColor or GlowSettings.Color
		local a, r, g, b = tonumber('0x'..strsub(colorPalette, 1, 2))/255,tonumber('0x'..strsub(colorPalette, 3, 4))/255, tonumber('0x'..strsub(colorPalette, 5, 6))/255, tonumber('0x'..strsub(colorPalette, 7, 8))/255
		local color = {r,g,b,a}

		local GlowType = GlowSettings.type
		if GlowType == "Pixel Glow" then
			local PixelGlow = GlowSettings.PixelGlow
			LCG.PixelGlow_Start(
				glow_frame,
				color,
				PixelGlow.count,
				PixelGlow.frequency,
				PixelGlow.length,
				PixelGlow.thickness,
				PixelGlow.xOffset,
				PixelGlow.yOffset,
				PixelGlow.border,
				id
			)

			unitData.cancelFunc = LCG.PixelGlow_Stop
		elseif GlowType == "Autocast Shine" then
			local AutoCastGlow = GlowSettings.AutoCastGlow
			LCG.AutoCastGlow_Start(
				glow_frame,
				color,
				AutoCastGlow.count,
				AutoCastGlow.frequency,
				AutoCastGlow.scale,
				AutoCastGlow.xOffset,
				AutoCastGlow.yOffset,
				id
			)

			unitData.cancelFunc = LCG.AutoCastGlow_Stop
		elseif GlowType == "Proc Glow" then
			local ProcGlow = GlowSettings.ProcGlow
			LCG.ProcGlow_Start(
				glow_frame,
				{
					color = color,
					duration = ProcGlow.duration,
					startAnim = ProcGlow.startAnim,
					xOffset = ProcGlow.xOffset,
					yOffset = ProcGlow.yOffset,
					key = id,
				}
			)

			unitData.cancelFunc = LCG.ProcGlow_Stop
		else
			LCG.ButtonGlow_Start(
				glow_frame,
				color,
				GlowSettings.ActionButtonGlow.frequency
			)

			unitData.cancelFunc = LCG.ButtonGlow_Stop
		end
	end

	if not unitData.timer then
		if not untimed and duration then
			local timer = MRT.F.ScheduleTimer(function()
				stopFrameGlow(unitData)
				unitData:stopFrameMonitoring()
			end, duration)
			unitData.timer = timer
			module.db.timers[#module.db.timers+1] = timer
		end
	end
end

do
	local function frame_monitor_callback(event, frame, unit, previousUnit)
		local new_frame
		local FRAME_UNIT_UPDATE = event == "FRAME_UNIT_UPDATE"
		local FRAME_UNIT_ADDED = event == "FRAME_UNIT_ADDED"
		local FRAME_UNIT_REMOVED = event == "FRAME_UNIT_REMOVED"
		local GUID = UnitGUID(unit)

		if type(glow_frame_monitor) == "table" then
			for reminder, units in next, glow_frame_monitor do
				local unitData = units[GUID]
				if unitData and
				(
				  ((FRAME_UNIT_ADDED or FRAME_UNIT_UPDATE) and (unitData.frame ~= frame)) or
				  (FRAME_UNIT_REMOVED and unitData.frame == frame)
				)
				then
					if not new_frame then
						new_frame = LGF.GetFrame(unit,LGFNullOpt)
					end
					if new_frame ~= unitData.frame then
						-- remove previous glow
						stopFrameGlow(unitData)
						if new_frame then
							-- apply the glow to new_frame
							unitData.frame = new_frame
							startFrameGlow(unitData)
						end
					end
				end
			end
		end
	end

	LGF.RegisterCallback("Reminder", "FRAME_UNIT_UPDATE", frame_monitor_callback)
	LGF.RegisterCallback("Reminder", "FRAME_UNIT_ADDED", frame_monitor_callback)
	LGF.RegisterCallback("Reminder", "FRAME_UNIT_REMOVED", frame_monitor_callback)
end

local function stopFrameMonitoring(self)
	if type(glow_frame_monitor) == "table" then
		glow_frame_monitor[self.reminder][self.GUID] = nil
	end
	if self.timer then
		self.timer:Cancel()
		self.timer = nil
	end
end

function module:ParseGlow(data,params)
	local formatedString = module:FormatMsg(data.glow,params):gsub("|*c%x%x%x%x%x%x%x%x([^|]+)|*r", "%1")
	for glowTarget in string_gmatch(formatedString, "[^,; ]+") do
		if glowTarget == "{destName}" then -- back compability
			glowTarget = params.targetName
		end
		local unit = glowTarget and ((IsInRaid() and UnitInRaid(glowTarget) and "raid" .. UnitInRaid(glowTarget)) or
		(IsInGroup() and UnitInParty(glowTarget) and UnitTokenFromGUID(UnitGUID(glowTarget))) or
		(UnitIsUnit("player", glowTarget) and "player"))
		-- print(unit)
		if unit then
			local unitFrame = LGF.GetFrame(unit,LGFNullOpt)

			local reminder = params._reminder

			glow_frame_monitor = glow_frame_monitor or {}
			glow_frame_monitor[reminder] = glow_frame_monitor[reminder] or {}

			local GUID = UnitGUID(glowTarget)

			if GUID and not glow_frame_monitor[reminder][GUID] then
				local unitData = {
					GUID = GUID,
					data = data,
					params = params,
					reminder = reminder,
					frame = unitFrame,
					key = data.token,
					stopFrameMonitoring = stopFrameMonitoring,
				}

				glow_frame_monitor[reminder][GUID] = unitData

				if unitFrame then
					startFrameGlow(unitData)
				end
				-- DevTool:AddData(glow_frame_monitor)
			end
		end
	end
end

function module:ResetAllGlows()
	if type(glow_frame_monitor) == "table" then
		for reminder, units in next, glow_frame_monitor do
			for GUID, unitData in next, units do
				stopFrameGlow(unitData)
				unitData:stopFrameMonitoring()
			end
		end
	end
	glow_frame_monitor = nil
end

function module:HideGlowByUID(reminder, uid)
	if type(glow_frame_monitor) == "table" then
		local units = glow_frame_monitor[reminder]
		if units then
			for GUID, unitData in next, units do
				if unitData.params.guid == uid or unitData.params.uid == uid then
					stopFrameGlow(unitData)
					unitData:stopFrameMonitoring()
				end
			end
		end
	end
end

function module:HideGlowByData(reminder)
	if type(glow_frame_monitor) == "table" then
		local units = glow_frame_monitor[reminder]
		if units then
			for GUID, unitData in next, units do
				stopFrameGlow(unitData)
				unitData:stopFrameMonitoring()
			end
		end
	end
end

function module:SayChatSpam(data, params)
	local sType = data.spamType
	local str = data.spamMsg
	local channelName = data.spamChannel == 1 and "SAY" or data.spamChannel == 3 and IsInGroup() and "PARTY" or data.spamChannel == 4 and (IsInRaid() and "RAID" or "PARTY") or "YELL" -- 2 = YELL
	local untimed = (data.duration and data.duration == 0) and true or false
	local duration = data.duration or 3
	local msg, msgUpdateReq = module:FormatMsg(data.spamMsg or "",params,true)
	msg = module:FormatMsgForChat(msg)


	for i=1,#ChatSpamTimers do
		ChatSpamTimers[i]:Cancel()
	end
	wipe(ChatSpamTimers)

	local _SendChatMessage = SendChatMessage
	if (channelName == "SAY" or channelName == "YELL") and select(2,GetInstanceInfo()) == "none" then
		_SendChatMessage = MRT.NULLfunc
	end
	if data.spamChannel == 5 then
		_SendChatMessage = prettyPrint
	end

	if untimed then
		if sType == 1 or sType == 2 then
			local function printf()
				local newmsg = msgUpdateReq and module:FormatMsgForChat(module:FormatMsg(str or "", params, true)) or msg
				_SendChatMessage(newmsg, channelName)
				ChatSpamTimers[#ChatSpamTimers+1] = MRT.F.ScheduleTimer(printf,1.5)
				ChatSpamUntimed = {
					timer = ChatSpamTimers[#ChatSpamTimers],
					data = data,
				}
			end

			ChatSpamTimers[1] = MRT.F.ScheduleTimer(printf,0.01)
			ChatSpamUntimed = {
				timer = ChatSpamTimers[1],
				data = data,
			}

		elseif sType == 3 then
			local function printf()
				local newmsg = msgUpdateReq and module:FormatMsgForChat(module:FormatMsg(str or "", params, true)) or msg
				_SendChatMessage(newmsg, channelName)
			end
			printf()
		end
	else
		if sType == 1 then
			local function printf(c)
				local newmsg = msgUpdateReq and module:FormatMsgForChat(module:FormatMsg(str or "", params, true)) or msg
				_SendChatMessage(newmsg.." "..c, channelName)
			end
			for i=1,duration+1 do
				ChatSpamTimers[i] = MRT.F.ScheduleTimer(printf,max(i-1,0.01),floor(duration-(i-1)))
			end
		elseif sType == 2 then
			local function printf()
				local newmsg = msgUpdateReq and module:FormatMsgForChat(module:FormatMsg(str or "", params, true)) or msg
				_SendChatMessage(newmsg, channelName)
			end
			for i=1,duration+1 do
				ChatSpamTimers[i] = MRT.F.ScheduleTimer(printf,max(i-1,0.01))
			end
		elseif sType == 3 then
			local function printf()
				local newmsg = msgUpdateReq and module:FormatMsgForChat(module:FormatMsg(str or "", params, true)) or msg
				_SendChatMessage(newmsg, channelName)
			end
			printf()
		end
	end
end

---------------------------------------
-- Trigger Handling 3 ?
---------------------------------------
function module:CheckAllTriggers(trigger, printLog)
	local data, reminder = trigger._data, trigger._reminder

	for i,t in ipairs(reminder.triggers) do
		if t.status and t.status.specialTriggerCheck and not t.status.specialTriggerCheck() then
			module:DeactivateTrigger(t)
			--module:RunAndRemoveTimer(module.DeactivateTrigger,nil,t,t.status.uid or t.status.guid or 1,true)

			--print('discard trigger status',i)
		end
	end

	local check = reminder.activeFunc(reminder.triggers)

	--if module.db.debug and data.debug then
	if module.db.debug then
		for i=1,#reminder.triggers do
			prettyPrint(GetTime(),data.msg,i,reminder.triggers[i].status,reminder.triggers[i]["count"])
		end
		prettyPrint('CheckAllTriggers',GetTime(),data.name or data.msg,"Check: "..tostring(check))
	end
	if module.db.debugLog then module:DebugLogAdd("CheckAllTriggers",data.name or data.msg,data.token,check) end

	if not check then
		for i,t in next, reminder.triggers do
			if t ~= trigger and t._trigger.cbehavior == 4 and not reminder.activeFunc2(reminder.triggers,i) then
				-- prettyPrint("activeFunc2based counter reset")
				t.count = 0
			end
		end
		if printLog then
			prettyPrint("Activation: all triggers check |cffff0000not passed|r")
		end
	end

	if check then
		if printLog then
			prettyPrint("Activation: all triggers check passed")
		end
		if data.sametargets then
			local guid = type(trigger.status) == "table" and trigger.status.guid
			if guid then
				local allguidsaresame = true
				for _,t in ipairs(reminder.triggers) do
					local foundAny, foundSame
					for _,s in next, t.active do
						foundAny = true
						if s.guid and s.guid == guid then
							t.status = s
							foundSame = true
							break
						elseif not s.guid then
							foundSame = true
							break
						end
					end
					if foundAny and not foundSame then
						allguidsaresame = false
						break
					end
				end
				if allguidsaresame then
					module:ShowReminder(trigger, printLog)
				end
			end
		else
			module:ShowReminder(trigger, printLog)
		end
	end

	--hide all copies for reminders without duration
	if (data.duration == 0 or data.hideTextChanged) and not check then
		if data.msg then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == data then
					-- if showed.voice then
					--     showed.voice:Cancel()
					-- end
					tremove(module.db.showedReminders,j)
				end
			end
		end

		if data.soundOnHide then
			for j=#module.db.onHideSounds,1,-1 do
				local sound = module.db.onHideSounds[j]
				if sound.data == data then
					if sound.delay then
						local tmr = MRT.F.ScheduleTimer(PlaySoundFile, max(sound.delay,0.01), sound.sound, "Master")
						module.db.timers[#module.db.timers+1] = tmr
					else
						pcall(PlaySoundFile, sound.sound, "Master")
					end
					tremove(module.db.onHideSounds,j)
				end
			end
		end

		if data.ttsOnHide then
			for j=#module.db.onHideTTS,1,-1 do
				local tts = module.db.onHideTTS[j]
				if tts.data == data then
					if tts.delay then
						local tmr = MRT.F.ScheduleTimer(module.PlayTTS, max(tts.delay,0.01), module, tts.tts,tts.params)
						module.db.timers[#module.db.timers+1] = tmr
					else
						module:PlayTTS(tts.tts,tts.params)
					end
					tremove(module.db.onHideTTS,j)
				end
			end
		end

		if data.glow then
			module:HideGlowByData(trigger._reminder)
		end
		if ChatSpamUntimed and ChatSpamUntimed.data == data then
			ChatSpamUntimed.timer:Cancel()
		end
		if data.nameplateGlow then
			if reminder.nameplateguid then
				module:NameplateRemoveHighlight(reminder.nameplateguid)
				reminder.nameplateguid = nil
			end
			for guid,list in next, module.db.nameplateHL do
				for uid,t in next, list do
					if t.data == data then
						module:NameplateRemoveHighlight(guid, uid)
					end
				end
			end
		end
		if data.voiceCountdown then
			for i=1,#voiceCountdowns do
				if voiceCountdowns[i].data == data then
					voiceCountdowns[i].voice:Cancel()
					tremove(voiceCountdowns,i)
				end
			end
		end
	end
end

---------------------------------------
-- Loading Reminders
---------------------------------------
function module:ReloadAll()
	module:ResetPrevZone()
	module:LoadForCurrentZone()
end

function module:UnloadAll()
	module:UnregisterEvents(
		"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","RAID_TARGET_UPDATE",
		"PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UPDATE_MOUSEOVER_UNIT"
	)

	for _,c in next, module.C do
		if c.id and c.events then
			for _,event in module.IterateTable(c.events) do
				if event:find("^BigWigs_") then
					module:UnregisterBigWigsCallback(event)
				elseif event:find("^DBM_") then
					module:UnregisterDBMCallback(event)
				elseif event == "TIMER" then
					-- module:UnregisterTimer()
				else
					module:UnregisterEvents(event)
				end
			end
		end
	end
	wipe(module.db.eventsToTriggers)

	for i=1,#module.db.timers do
		module.db.timers[i]:Cancel()
	end

	wipe(module.db.timers)
	wipe(module.db.showedReminders)
	wipe(reminders)

	wipe(module.db.onHideSounds)
	wipe(module.db.onHideTTS)

	for _,f in next, module.db.nameplateFrames do
		f:Hide()
	end
	wipe(module.db.nameplateHL)
	wipe(module.db.nameplateGUIDToFrames)

	wipe(eventsUsed)
	wipe(unitsUsed)

	nameplateUsed = false

	module:ResetAllGlows()

	for i=1,#ChatSpamTimers do
		ChatSpamTimers[i]:Cancel()
	end
	wipe(ChatSpamTimers)
	wipe(ChatSpamUntimed)

	wipe(unitAuras)
	wipe(unitAurasInstances)
	wipe(bossFramesblackList)

	wipe(voiceCountdowns)

	tCOMBAT_LOG_EVENT_UNFILTERED = nil
	tUNIT_HEALTH = nil
	tUNIT_POWER_FREQUENT = nil
	tUNIT_ABSORB_AMOUNT_CHANGED = nil
	tUNIT_AURA = nil
	tUNIT_TARGET = nil
	tUNIT_SPELLCAST_SUCCEEDED = nil
	tUNIT_CAST = nil

	wipe(module.db.notePatsCache)
	if MRT.A.RG_Assignments then
		wipe(MRT.A.RG_Assignments.db.listsCache)
	end

	if C_VoiceChat and C_VoiceChat.StopSpeakingText then
		C_VoiceChat.StopSpeakingText()
	end

	frameBars:StopAllBars()

	module.db.simrun = nil
	module.db.simrun_mute = nil
end

local function CancelSoundTimers(self)
	for i=1,#self do
		self[i]:Cancel()
	end
end

---------------------------------------
-- Create Functions Itslef
---------------------------------------

module.db.forceLoadUIDs = {}
function module:LoadOneReminder(token)
	module.db.forceLoadUIDs[token] = true
	module:ReloadAll()
	if module.db.encounterID then
		prettyPrint("Unable to reload during active boss encounter")
	end
end

function module:FindReminderByData(data)
	for i=1,#reminders do
		if reminders[i].data == data or reminders[i].data.token == data.token then
			return reminders[i]
		end
	end
end

function module:FilterFuncReminders(data,encounterID,difficultyID,zoneID,myName,myClass,myRole1,myRole2,alias,checkIsLoaded)
	if
		not data.disabled and
			data.triggers and #data.triggers > 0 and
			(not checkIsLoaded or not module:FindReminderByData(data)) and
			(
				data.defDisabled and module:GetDataOption(data.token, "DEF_ENABLED") or
				not data.defDisabled and not module:GetDataOption(data.token, "DISABLED")
			) and
			(not data.doNotLoadOnBosses or not encounterID) and
			(
				(not data.boss or data.boss == encounterID) and
				(not data.diff or data.diff == difficultyID) and
				(not data.zoneID or zoneID and module:FindNumberInString(zoneID,data.zoneID))
			) and
			(not myName or module:CheckPlayerCondition(data,myName,myClass,myRole1,myRole2,alias)) or
			module.db.forceLoadUIDs[data.token]
	then
		return true
	else
		return false
	end
end

function module:UnloadUnusedReminders()
	local eventsTable = module.db.eventsToTriggers
	local count = 0
	for i=#reminders,1,-1 do
		local reminder = reminders[i]
		if not module:FilterFuncReminders(reminder.data,module.db.encounterID,module.db.encounterDiff,module.db.currentZoneID) then
			count = count + 1

			for event,edata in next, eventsTable do
				for _,edata2 in next, (#edata == 0 and edata or {edata}) do
					for j=#edata2,1,-1 do
						if edata2[j]._reminder == reminder then
							tremove(edata2, j)
						end
					end
				end
			end

			for j=1,#reminder.triggers do
				module:UnloadTrigger(reminder.triggers[j])
			end

			tremove(reminders, i)
		end
	end

	if module.db.debug then print("Unloaded Reminders",count) end
end

function module:UpdateTTSTransliterateStatus()
	module.db.isTtsTranslateNeeded = false
	for k,v in next, ttsVoices do
		if v.voiceID == VMRT.Reminder.VisualSettings.TTS_Voice then
			if v.name:match("English") then
				module.db.isTtsTranslateNeeded = true
			end
			break
		end
	end
end

function module:CreateFunctions(encounterID,difficultyID,zoneID,isSimrun)
	if module.db.stayLoaded then
		module:UnloadUnusedReminders()
	else
		module:UnloadAll()
	end

	if not module.IsEnabled then
		return
	end

	if isSimrun then
		ScheduleTimer = module.ScheduleSimrunTimer
	else
		ScheduleTimer = MRT.F.ScheduleTimer
	end

	local myName = MRT.SDB.charName
	local myClass = UnitClassBase('player')
	local myRole1, myRole2 = module:GetPlayerRole()
	local alias = AddonDB.RGAPI and AddonDB.RGAPI:GetNick("player")

	module:UpdateTTSTransliterateStatus()

	for token,data in next, VMRT.Reminder.data do
		if module:FilterFuncReminders(data,encounterID,difficultyID,zoneID,myName,myClass,myRole1,myRole2,alias,true) then
			local reminder = {
				triggers = {},
				data = data,
			}
			reminders[#reminders+1] = reminder
			for i=1,#data.triggers do
				local trigger = data.triggers[i]
				local triggerData = module:CopyTriggerEventForReminder(trigger)

				local triggerNow = {
					_i = i,
					_trigger = triggerData,
					_reminder = reminder,
					_data = data,

					status = false,
					count = 0,
					countsS = {},
					countsD = {},
					active = {},
					statuses = {},

					Dcounter = module:CreateNumberConditions(triggerData.counter),
					DnumberPercent = module:CreateNumberConditions(triggerData.numberPercent),
					Dstacks = module:CreateNumberConditions(triggerData.stacks),

					DdelayTime = module:ConvertMinuteStrToNum(triggerData.delayTime,data.notepat),
					DsourceName = module:CreateStringConditions(triggerData.sourceName),
					DtargetName = module:CreateStringConditions(triggerData.targetName),
					DsourceID = module:CreateMobIDConditions(triggerData.sourceID),
					DtargetID = module:CreateMobIDConditions(triggerData.targetID),

					DspellName = triggerData.spellName and tonumber(triggerData.spellName) and GetSpellName(tonumber(triggerData.spellName)) or triggerData.spellName,
				}
				reminder.triggers[i] = triggerNow

				if trigger.event and module.C[trigger.event] then
					local eventDB = module.C[trigger.event]

					eventsUsed[trigger.event] = true

					local eventTable = module.db.eventsToTriggers[eventDB.name]
					if not eventTable then
						eventTable = {}
						module.db.eventsToTriggers[eventDB.name] = eventTable
					end

					if eventDB.isUntimed and not trigger.activeTime then
						triggerNow.untimed = true
						triggerNow.delays = {}
					end
					if eventDB.extraDelayTable then
						triggerNow.delays2 = {}
					end
					if eventDB.isUntimed and trigger.activeTime then
						triggerNow.ignoreManualOff = true
					end

					if eventDB.subEventField then
						local subEventDB = module.C[ trigger[eventDB.subEventField] ]
						if subEventDB then
							for _,subRegEvent in module.IterateTable(subEventDB.events) do
								local subEventTable = eventTable[subRegEvent]
								if not subEventTable then
									subEventTable = {}
									eventTable[subRegEvent] = subEventTable
								end

								subEventTable[#subEventTable+1] = triggerNow
							end
						end
					elseif eventDB.isUnits then
						triggerNow.units = {}

						local units = trigger[eventDB.unitField]

						unitsUsed[units or 0] = true

						if type(units) == "number" then
							if units < 0 then
								units = module.datas.unitsList.ALL
								for j=1,#module.datas.unitsList do
									unitsUsed[j] = true
								end
							else
								units = module.datas.unitsList[units]
							end
						end

						if units then
							for _,unit in module.IterateTable(units) do
								local funit = unitreplace_rev[unit] or unit

								local unitTable = eventTable[funit]
								if not unitTable then
									unitTable = {}
									eventTable[funit] = unitTable
								end

								unitTable[#unitTable+1] = triggerNow
							end
						else
							eventTable[#eventTable+1] = triggerNow
						end
					else
						eventTable[#eventTable+1] = triggerNow
					end
				end
			end
			local triggersStr = ""
			local opened = false
			for i = #data.triggers, 2, -1 do
				local trigger = data.triggers[i]
				if not trigger.andor or trigger.andor == 1 then
					triggersStr = "and "..(opened and "(" or "")..(trigger.invert and "not " or "").."t["..i.."].status " .. triggersStr
					opened = false
				elseif trigger.andor == 2 then
					triggersStr = "or "..(opened and "(" or "")..(trigger.invert and "not " or "").."t["..i.."].status " .. triggersStr
					opened = false
				elseif trigger.andor == 3 then
					triggersStr = "or "..(trigger.invert and "not " or "").."t["..i.."].status"..(not opened and ")" or "").." " .. triggersStr
					opened = true
				elseif trigger.andor == 4 then -- ignore
				elseif trigger.andor == 5 then -- and with opened = true
					triggersStr = "and "..(trigger.invert and "not " or "").."t["..i.."].status"..(not opened and ")" or "").." " .. triggersStr
					opened = true
				end
			end
			triggersStr = (opened and "(" or "")..(data.triggers[1].invert and "not " or "").."t[1].status "..triggersStr
			-- is reminder active
			reminder.activeFunc = loadstring("return function(t) return "..triggersStr.." end")()
			-- would reminder be active if trigger n would be active
			reminder.activeFunc2 = loadstring("return function(t,n) local s=t[n].status t[n].status=not t[n]._trigger.invert local r="..triggersStr.." t[n].status=s return r end")()

			reminder.delayedActivation = module:ConvertMinuteStrToNum(data.delay)

			if data.nameplateGlow then
				nameplateUsed = true
			end

			if #data.triggers > 0 then
				module:CheckAllTriggers(reminder.triggers[1])
			end
		end
	end

	-- Register Events
	for id in next, eventsUsed do
		local eventDB = module.C[id]
		if eventDB and eventDB.events then
			for _,event in module.IterateTable(eventDB.events) do
				if event:find("^BigWigs_") then
					module:RegisterBigWigsCallback(event)
				elseif event:find("^DBM_") then
					module:RegisterDBMCallback(event)
				elseif eventDB.isUnits then
					local eventTable = module.db.eventsToTriggers[eventDB.name]
					local units = {}
					local i = 0
					for unit in next, eventTable do
						i = i + 1
						if i > 4 then
							i = nil
							break
						end
						tinsert(units,unit)
					end
					if i then
						module:RegisterUnitEvent(event,unpack(units))
					else
						module:RegisterEvents(event)
					end
				else
					module:RegisterEvents(event)
				end
			end
		end
	end

	local anyUnit
	for unit in next, unitsUsed do
		if unit == "target" then
			module:RegisterEvents("PLAYER_TARGET_CHANGED")
		elseif unit == "focus" then
			module:RegisterEvents("PLAYER_FOCUS_CHANGED")
		elseif unit == "mouseover" then
			module:RegisterEvents("UPDATE_MOUSEOVER_UNIT")
		elseif (type(unit) == "string" and unit:find("^boss")) or unit == 1 then
			module:RegisterEvents("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		elseif unit == 2 then
			nameplateUsed = true
		end

		anyUnit = true
	end

	if module.db.eventsToTriggers.RAID_GROUP_NUMBER then
		module.main:GROUP_ROSTER_UPDATE()
	end

	if anyUnit then
		module:RegisterEvents("RAID_TARGET_UPDATE")
	end

	if nameplateUsed then
		module:RegisterEvents("NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED")
	end

	if encounterID then
		module:PrepeareForHistoryRecording()
	end

	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and not module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED then
		module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED = {}
	end

	tCOMBAT_LOG_EVENT_UNFILTERED = module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED
	tUNIT_HEALTH = module.db.eventsToTriggers.UNIT_HEALTH
	tUNIT_POWER_FREQUENT = module.db.eventsToTriggers.UNIT_POWER_FREQUENT
	tUNIT_ABSORB_AMOUNT_CHANGED = module.db.eventsToTriggers.UNIT_ABSORB_AMOUNT_CHANGED
	tUNIT_AURA = module.db.eventsToTriggers.UNIT_AURA
	tUNIT_TARGET = module.db.eventsToTriggers.UNIT_TARGET
	tUNIT_SPELLCAST_SUCCEEDED = module.db.eventsToTriggers.UNIT_SPELLCAST_SUCCEEDED
	tUNIT_CAST = module.db.eventsToTriggers.UNIT_CAST

	if nameplateUsed then
		module:NameplatesReloadCycle()
	end

	if anyUnit then
		module.main:RAID_TARGET_UPDATE()
	end

	wipe(module.db.forceLoadUIDs)

end

---------------------------------------
-- Initializing Saved Variables and Starting whole reminder processing
---------------------------------------

function module:SetDataProfile(profileName)
	VMRT.Reminder.DataProfile = VMRT.Reminder.DataProfile or "Default"
	if VMRT.Reminder.DataProfile == profileName then
		module:ReloadAll()
		if module.options.Update then
			module.options:Update()
		end
		return
	end
	-- save current profile
	VMRT.Reminder.DataProfiles[VMRT.Reminder.DataProfile] = {
		data = VMRT.Reminder.data,
		removed = VMRT.Reminder.removed,
		options = VMRT.Reminder.options,
	}
	-- apply new profile
	VMRT.Reminder.DataProfile = profileName
	if VMRT.Reminder.DataProfiles[profileName] then
		VMRT.Reminder.data = VMRT.Reminder.DataProfiles[profileName].data or {}
		VMRT.Reminder.removed = VMRT.Reminder.DataProfiles[profileName].removed or {}
		VMRT.Reminder.options = VMRT.Reminder.DataProfiles[profileName].options or {}
	else
		VMRT.Reminder.data = {}
		VMRT.Reminder.removed = {}
		VMRT.Reminder.options = {}
	end
	VMRT.Reminder.DataProfiles[profileName] = {}

	module:ReloadAll()
	if module.options.Update then
		module.options:Update()
	end

	MLib:DialogPopupHide("EXRT_REMINDER_COPY_PROFILE")
	MLib:DialogPopupHide("EXRT_REMINDER_DELETE_PROFILE")
end

function module:LoadDataProfile()
	if VMRT.Reminder.ForcedDataProfile then
		module:SetDataProfile(VMRT.Reminder.ForcedDataProfile)
	elseif VMRT.Reminder.DataProfileKeys[ MRT.SDB.charKey ] then
		module:SetDataProfile(VMRT.Reminder.DataProfileKeys[ MRT.SDB.charKey ])
	else
		module:SetDataProfile("Default")
	end
end

function module:SetVisualProfile(profileName)
	VMRT.Reminder.VisualProfile = VMRT.Reminder.VisualProfile or "Default"
	if VMRT.Reminder.VisualProfile == profileName then
		module:UpdateVisual()
		return
	end
	-- save current profile
	VMRT.Reminder.VisualProfiles[VMRT.Reminder.VisualProfile] = {
		VisualSettings = VMRT.Reminder.VisualSettings,
	}
	-- apply new profile
	VMRT.Reminder.VisualProfile = profileName
	if VMRT.Reminder.VisualProfiles[profileName] then
		VMRT.Reminder.VisualSettings = VMRT.Reminder.VisualProfiles[profileName].VisualSettings or CopyTable(module.DefaultReminderDB.VisualSettings)
	else
		VMRT.Reminder.VisualSettings = CopyTable(module.DefaultReminderDB.VisualSettings)
	end
	VMRT.Reminder.VisualProfiles[profileName] = {}

	module:UpdateVisual()
	module:ReloadAll()
	if module.options.Update then
		module.options:Update()
	end
	AddonDB:FireCallback("Reminder_VisualProfileChanged")

	MLib:DialogPopupHide("EXRT_REMINDER_COPY_VISUAL_PROFILE")
	MLib:DialogPopupHide("EXRT_REMINDER_DELETE_VISUAL_PROFILE")
end

function module:LoadVisualProfile()
	if VMRT.Reminder.ForcedVisualProfile then
		module:SetVisualProfile(VMRT.Reminder.ForcedVisualProfile)
	elseif VMRT.Reminder.VisualProfileKeys[ MRT.SDB.charKey ] then
		module:SetVisualProfile(VMRT.Reminder.VisualProfileKeys[ MRT.SDB.charKey ])
	else
		module:SetVisualProfile("Default")
	end
end

function module:CleanRemovedData(days)
	local cutoffTime = time() - days*24*60*60
	for token,data in module:IterateRemovedData() do
		if not data.time or data.time < cutoffTime then
			VMRT.Reminder.removed[token] = nil
		end
	end
end

local function ensureDefaults(default, db)
	for k, v in next, default do
		if type(v) == "table" then
			if type(db[k]) ~= "table" then
				db[k] = {}
			end
			ensureDefaults(v, db[k])
		elseif db[k] == nil then
			db[k] = v
			-- print("Defaulting", k, v)
		end
	end
end

function module.main:ADDON_LOADED()
	_G.ReminderLog = _G.ReminderLog or {}
	ReminderLog = _G.ReminderLog

	VMRT.Reminder = VMRT.Reminder or CopyTable(module.DefaultReminderDB)

	-- for fresh SV Version is set in DefaultReminderDB
	-- so this is only for old SV
	VMRT.Reminder.Version = VMRT.Reminder.Version or 0
	if VMRT.Reminder.Version < AddonDB.Version or AddonDB.IsDev then -- upgrading db
		module:Modernize()

		-- ensure default settings are applied
		ensureDefaults(module.DefaultReminderDB, VMRT.Reminder)
		for visualSettings, profileName, isActive in module:IterateVisualSettings() do
			if not isActive then
				ensureDefaults(module.DefaultReminderDB.VisualSettings, visualSettings)
			end
		end
	end

	module:LoadDataProfile()
	module:LoadVisualProfile()

	module:CleanRemovedData(180)

	if VMRT.Reminder.SaveHistory then
		module.db.history = ReminderLog.history or {}
		ReminderLog.history = module.db.history
	end

	if VMRT.Reminder.HistoryMaxPulls > 16 then
		VMRT.Reminder.HistoryMaxPulls = 16
	end

	module:RegisterAddonMessage()
	module:RegisterSlash()

	module:RegisterEvents("PLAYER_ENTERING_WORLD")
end

function module:slash(arg)
	arg = arg and type(arg) == 'string' and arg:lower()
	if arg:find("^rem$") or arg:find("^r$") then
		MRT.Options:Open()
		MRT.Options:OpenByModuleName("Reminder")
	elseif arg:find("^ra$") then
		MRT.Options:Open()
		MRT.Options:OpenByModuleName("RaidAnalyzer")
	elseif arg:find("^was$") then
		MRT.Options:Open()
		MRT.Options:OpenByModuleName("WAChecker")
	end
end

---------------------------------------
-- Initializing Addon
---------------------------------------

do
	local scheduledUpdate
	local prevZoneID
	function module:LoadForCurrentZone()
		scheduledUpdate = nil
		if module.db.encounterID then
			return
		end
		local zoneName, _, difficultyID, _, _, _, _, zoneID = GetInstanceInfo()
		if zoneID ~= prevZoneID then
			prevZoneID = zoneID
			if module.db.debug then print("Load Zone ID",zoneID,zoneName) end

			if difficultyID ~= 8 then
				if module.db.InChallengeMode then
					module:StoreHistory(0)
					IsHistoryEnabled = false
				end
				module.db.stayLoaded = false
				module.db.InChallengeMode = false
			end

			module.db.currentZoneID = zoneID
			module.db.encounterDiff = difficultyID
			module:CreateFunctions(nil,difficultyID,zoneID)
		end
	end
	function module.main:ZONE_CHANGED_NEW_AREA()
		if not scheduledUpdate then
			scheduledUpdate = MRT.F.ScheduleTimer(module.LoadForCurrentZone,1)
		end
	end
	function module:ResetPrevZone()
		prevZoneID = nil
	end
end

function module.main:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
	module:StopLiveForce()

	module.db.encounterID = encounterID
	module.db.encounterDiff = difficultyID
	VMRT.Reminder.lastEncounterID = encounterID
	module.db.encounterPullTime = GetTime() - (module.db.nextPullIsDelayed or 0)

	module.db.currentPhase = nil
	module.db.currentPhaseTime = nil

	local _, _, _, _, _, _, _, zoneID = GetInstanceInfo()
	module:CreateFunctions(encounterID, difficultyID, zoneID)

	module:StartHistoryRecord()

	if (module.db.eventsToTriggers.BOSS_START or module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) then
		module:TriggerBossPull(encounterID, difficultyID, module.db.nextPullIsDelayed)
	end

	if module.db.eventsToTriggers.BOSS_PHASE then
		local t = MRT.F.ScheduleTimer(function()
			if not module.db.currentPhase then
				module:TriggerBossPhase(module.db.currentDelayedPhase or "1", nil, module.db.currentDelayedPhaseTime)
			end
		end, 0.5)
		module.db.timers[#module.db.timers+1] = t
	end
	if module.db.eventsToTriggers.RAID_GROUP_NUMBER then
		module.main:GROUP_ROSTER_UPDATE()
	end

	module:BigWigsRecallEncounterStartEvents()
	module:DBMRecallEncounterStartEvents()

	module.db.nextPullIsDelayed = nil
	module.db.currentDelayedPhase = nil
	module.db.currentDelayedPhaseTime = nil
end

function module.main:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, kill)
	module.db.encounterID = nil
	module.db.currentPhase = nil
	module.db.currentPhaseTime = nil

	module:ReloadAll()

	if IsHistoryEnabled then
		if not module.db.InChallengeMode then
			module:StoreHistory(kill)
			IsHistoryEnabled = false
		else
			module:AddHistoryEntry(0)
		end
	end
end

function module.main:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	if isInitialLogin or isReloadingUi then
		if BigWigsLoader then
			module.ActiveBossMod = "BW"
		elseif DBM then
			module.ActiveBossMod = "DBM"
		end

		if VMRT.Reminder.enabled then
			module:Enable()
		end

		module.main:GROUP_FORMED()
		module:RegisterEvents("GROUP_FORMED", "GROUP_JOINED")
		module:UnregisterEvents("PLAYER_ENTERING_WORLD")
	end
end

do
	local function requestVer2(v2Check)
		module.requestVer2timer = nil
		module:RequestVersion2(v2Check)
	end
	function module.main:GROUP_FORMED()
		if not module.requestVer2timer then -- canceled when we recieve request ver comms
			module.requestVer2timer = MRT.F.ScheduleTimer(requestVer2, 5)
		end
	end
	module.main.GROUP_JOINED = module.main.GROUP_FORMED
end

function module:Enable()
	local RequiredMRT = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-RequiredMRT") or "0")
	if RequiredMRT and MRT.V < RequiredMRT then
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

	module.IsEnabled = true

	module:RegisterEvents('ENCOUNTER_START','ENCOUNTER_END','ZONE_CHANGED_NEW_AREA')
	if MRT.is11 then -- to avoid errors in mop challenges
		module:RegisterEvents('CHALLENGE_MODE_START','CHALLENGE_MODE_COMPLETED','CHALLENGE_MODE_RESET')
	end

	module:RegisterBigWigsCallback("BigWigs_OnBossEngage")
	module:RegisterDBMCallback("DBM_Pull")

	module:ReloadAll()

	MRT.F.After(3,function()
		if (IsEncounterInProgress() or UnitExists("boss1")) and not module.db.encounterID then
			module.db.requestEncounterID = GetTime()
			local zoneID = select(8,GetInstanceInfo())
			AddonDB:SendComm("REMINDER_ENCOUNTER_SYNC_REQUEST",zoneID)
		end
	end)
end

function module:Disable()
	module.IsEnabled = false

	module:UnregisterEvents('ENCOUNTER_START','ENCOUNTER_END','ZONE_CHANGED_NEW_AREA','CHALLENGE_MODE_START','CHALLENGE_MODE_COMPLETED','CHALLENGE_MODE_RESET')
	module:UnregisterBigWigsCallback("BigWigs_OnBossEngage")
	module:UnregisterDBMCallback("DBM_Pull")

	module:UnloadAll()
end

function module.main:CHALLENGE_MODE_START(...)
	module:StopLiveForce()

	module.db.stayLoaded = true
	module.db.InChallengeMode = true

	module:PrepeareForHistoryRecording()

	local t = MRT.F.ScheduleTimer(function()
		module:StartHistoryRecord(2)
		if IsHistoryEnabled then
			local zoneName, _, _, _, _, _, _, zoneID = GetInstanceInfo()
			local level = C_ChallengeMode.GetActiveKeystoneInfo()
			module:AddHistoryEntry(20, zoneID, level)
		end
		if (module.db.eventsToTriggers.MPLUS_START) then
			module:TriggerMplusStart()
		end
	end,10)
	module.db.timers[#module.db.timers+1] = t
end
function module.main:CHALLENGE_MODE_RESET(...)
	module.db.stayLoaded = false
	module.db.InChallengeMode = false

	module:ResetPrevZone()
	module:LoadForCurrentZone()

	module:StoreHistory(0)
	IsHistoryEnabled = false
end
-- module.main.CHALLENGE_MODE_COMPLETED = module.main.CHALLENGE_MODE_RESET
function module.main:CHALLENGE_MODE_COMPLETED(...)
	module.db.stayLoaded = false
	module.db.InChallengeMode = false

	module:ResetPrevZone()
	module:LoadForCurrentZone()
	local success = select(4,C_ChallengeMode.GetCompletionInfo())
	module:StoreHistory(success and 1 or 0)
	IsHistoryEnabled = false
end

function module:PrepeareForHistoryRecording()
	if not VMRT.Reminder.HistoryEnabled then
		return
	end
	if not module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED then
		module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED = {}
		module:RegisterEvents("COMBAT_LOG_EVENT_UNFILTERED")

		tCOMBAT_LOG_EVENT_UNFILTERED = module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED
	end
	if not module.db.eventsToTriggers.BOSS_START then
		module.db.eventsToTriggers.BOSS_START = {}
	end
	if not module.db.eventsToTriggers.BOSS_PHASE then
		module.db.eventsToTriggers.BOSS_PHASE = {}
		module:RegisterBigWigsCallback("BigWigs_Message")
		module:RegisterBigWigsCallback("BigWigs_SetStage")
		module:RegisterDBMCallback("DBM_SetStage")
	end
	if not module.db.eventsToTriggers.CHAT_MSG then
		module.db.eventsToTriggers.CHAT_MSG = {}
		module:RegisterEvents(unpack(module.C[8].events))
	end
	if not module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT then
		module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT = {}
		module:RegisterEvents("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	end
end

function module:StartHistoryRecord()
	if VMRT.Reminder.HistoryEnabled then
		IsHistoryEnabled = true
	else
		IsHistoryEnabled = false
	end
end

do
	local savedbossID, savedzoneID
	function module:StartLive(bossID,zoneID)
		AddonDB:SendComm("REMINDER_LIVE_START",(bossID and next(bossID) or "").."\t"..(zoneID and next(zoneID) or ""))
		module.db.isLiveSession = true
		module.db.liveSessionInitiated = true
		savedbossID, savedzoneID = bossID, zoneID
		VMRT.Reminder.liveChanges = {changed={},added={},time=time()}
		module:Sync(false,bossID,zoneID,nil,nil,true)
		if module.options.assignLive then
			module.options.assignLive:UpdateStatus()
		end
	end

	function module:StopLive()
		module.db.isLiveSession = false
		module.db.liveSessionInitiated = false
		AddonDB:SendComm("REMINDER_LIVE_STOP")
		--module:Sync(false,savedbossID,savedzoneID)
		if module.options.assignLive then
			module.options.assignLive:UpdateStatus()
		end
	end

	function module:StartLiveUser(bossID, zoneID)
		if not module.db.preLiveSession then
			if module.db.isLiveSession then
				prettyPrint('Live session already started')
			else
				prettyPrint('Live session already ended')
			end
			return
		end
		VMRT.Reminder.liveChanges = {changed={},added={},time=time()}
		module.db.isLiveSession = true
		for i=1,#module.db.preLiveSession do
			module:ProcessTextToData(unpack(module.db.preLiveSession[i]))
		end
		module.db.preLiveSession = nil
		if not module.options:IsVisible() then
			if module.options.tab then
				module.options.tab:SetTo(1)
				module.options.main_tab:SetTo(3)
			else
				VMRT.Reminder.OptSavedTabNum = 3
			end
			MRT.Options:OpenByModuleName(module.name)
		end
		if module.options.assignBoss and bossID and bossID ~= "" and tonumber(bossID) then
			module.options.assignBoss:SelectBoss(tonumber(bossID))
		end
		if module.options.assignLive then
			module.options.assignLive:UpdateStatus()
		end
	end

	function module:StopLiveUser()
		module.db.isLiveSession = false
		module.db.preLiveSession = nil

		if module.options.assignLive then
			module.options.assignLive:UpdateStatus()
		end
	end

	function module:StopLiveForce()
		if not module.db.isLiveSession then
			return
		end
		if module.db.liveSessionInitiated then
			module:StopLive()
		else
			module:StopLiveUser()
		end
	end
end
