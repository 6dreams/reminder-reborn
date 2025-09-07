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

local LibDeflate = LibStub("LibDeflate")

local GetSpellInfo = AddonDB.GetSpellInfo
local GetSpellName = AddonDB.GetSpellName
local GetSpellTexture = AddonDB.GetSpellTexture
local prettyPrint = module.prettyPrint
local options = module.options
local GUIDIsPlayer = C_PlayerInfo.GUIDIsPlayer
local GetNumSpecializationsForClassID = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID or GetNumSpecializationsForClassID

local defaultAsyncConfig = {
	maxTime = 4,
	maxTimeCombat = 2,

	errorHandler = function(msg, stackTrace)
		geterrorhandler()(msg)
		if options.timeLine and options.timeLine.frame then
			options.timeLine.frame.initSpinner:Stop()
		end
		if options.assign and options.assign.frame then
			options.assign.frame.initSpinner:Stop()
		end
	end,
}

local diffSortPrio = {
	[16] = 1,
	[15] = 2,
	[14] = 3,
	[17] = 4,
}

local SimrunScheduler
local function CreateSimrunScheduler()
	SimrunScheduler = CreateFrame("Frame")
	SimrunScheduler:Hide()
	SimrunScheduler.paused = true
	SimrunScheduler:SetScript("OnShow", function(self)
		self.paused = false
	end)

	SimrunScheduler:SetScript("OnHide", function(self)
		self.paused = true
	end)
	SimrunScheduler.timers = {}
	SimrunScheduler:SetScript("OnUpdate", function(self, elapsed)
		if not module.db.simrun then return end
		local e = elapsed * (module.db.simrunspeed or 1)
		module.db.simrun = module.db.simrun + e
		for timer in next, self.timers do
			timer.time = timer.time - e
			if timer.time <= 0 then
				timer.func(unpack(timer.args))
				self.timers[timer] = nil
			end
		end
	end)
end

local function TimerCancel(self)
	SimrunScheduler.timers[self] = nil
end

local function ScheduleSimrunTimer(func, time, ...)
	if not SimrunScheduler then
		CreateSimrunScheduler()
	end

	if time < 0 then
		func(...)
		return
	end

	if not SimrunScheduler:IsShown() then
		SimrunScheduler:Show()
	end

	local timer = {func = func, time = time, args = {...}, Cancel = TimerCancel}
	SimrunScheduler.timers[timer] = true
	return timer
end

module.ScheduleSimrunTimer = ScheduleSimrunTimer

local function CancelAllSimrunTimers()
	if SimrunScheduler then
		for k in next, SimrunScheduler.timers do
			SimrunScheduler.timers[k] = nil
		end
		SimrunScheduler:Hide()
	end
	module.db.simrun_mute = nil
	module.db.simrun = nil
end

local function PauseSimrunTimers()
	if SimrunScheduler then
		SimrunScheduler:Hide()
	end
end

local function ResumeSimrunTimers()
	if SimrunScheduler then
		SimrunScheduler:Show()
	end
end


function options:TimelineInitialize()
	local function GenerateReminderName(data, force) -- generate reminder name
		if not data.name or data.autoName or force then
			local msg = data.msg or ""
			msg = msg:gsub("^{spell:%d+} *","")

			msg = module:FormatMsgForChat(module:FormatMsg(msg))

			if msg == "" then
				local spell = data.msg and data.msg:match("^{spell:(%d+)}")
				if spell then
					spell = tonumber(spell)
					local n = GetSpellName(spell)
					if n then
						msg = n
					end
				end
			end

			if msg == "" then
				msg = data.tts or ""
				msg = module:FormatMsgForChat(module:FormatMsg(msg))
			end

			if data.units then
				for k in string.gmatch(data.units,"[^#]+") do
					k = AddonDB.RGAPI and AddonDB.RGAPI:GetNick(k) or k
					msg = k.. (msg ~= "" and ": ".. msg or "")
				end
			end


			local prefix = "[P] "
			local pd = 0
			if data.triggers[1].event == 2 then -- phase
				local dt = module:ConvertMinuteStrToNum(data.triggers[1].delayTime or "0")
				local p = data.triggers[1].pattFind
				local pc = data.triggers[1].counter
				local globalCombatTime, phaseGlobalCount = options.timeLine:GetTimeOnPhase(dt[1], p, pc)
				pd = globalCombatTime or 0
			elseif data.triggers[1].event == 3 then -- pull
				local dt = module:ConvertMinuteStrToNum(data.triggers[1].delayTime or "0")
				pd = dt[1] or 0
			elseif data.triggers[1].event == 1 then -- cleu
				local spellID = data.triggers[1].spellID
				local eventCLEU = data.triggers[1].eventCLEU
				local counter = data.triggers[1].counter

				local dt = module:ConvertMinuteStrToNum(data.triggers[1].delayTime)

				local afterEnd = eventCLEU == "SPELL_AURA_REMOVED"
				pd = options.timeLine:GetTimeForSpell(dt and dt[1] or 0, spellID, counter, afterEnd, eventCLEU)
			end

			local time
			if pd then
				local phase = options.timeLine:GetPhaseFromTime(pd)
				prefix = "[P" .. (phase or "1") .. "] "
				if pd > 0 then
					time = module:FormatTime(pd)
					if time then
						prefix = prefix .. time .. " "
					end
				end
			end

			data.name = prefix .. "" .. msg
			data.autoName = true
		end
	end


	options.timeLine = {
		Data = module.TimelineData,

		BOSS_ID = 0,

		TIMELINE_SCALE = 80,
		TIMELINE_ADJUST_NUM = 3,
		TIMELINE_ADJUST = 100,
		TIMELINE_ADJUST_DATA = {},

		TL_LINESIZE = 20,
		TL_REMSIZE = 24,
		TL_HEADER_COLOR_OFF = {.2,.2,.2,1},
		TL_HEADER_COLOR_ON = {1,1,1,1},
		TL_HEADER_COLOR_HOVER = {1,1,0,1},

		FILTER_AURA = true,

		spell_status = type(VMRT.Reminder.OptTLSpellDisabled) == "table" and VMRT.Reminder.OptTLSpellDisabled or {},
		spell_dur = {},
		custom_phase = {},
		reminder_hide = {},

		saved_colors = {},

		FILTER_SPELL_REP = VMRT.Reminder.OptAssigFSpellsRep,
		FILTER_REM_ONLYMY = VMRT.Reminder.OptAssigOnlyMy,
		FILTER_NOTE = VMRT.Reminder.OptAssigFNote,
	}

	VMRT.Reminder.OptTLSpellDisabled = options.timeLine.spell_status

	for k, v in next, VMRT.Reminder.TimelineFilter do
		options.timeLine[k] = v
	end

	function options.timeLine.util_sort_by2(a,b) return a[2]<b[2] end

	function options.timeLine:GetPosFromTime(t)
		local s = self.TIMELINE_SCALE
		if s < 100 then
			if s > 0 then
				s = 2^(-math.ceil((100-s)/10)+1) - (2^(-math.ceil((100-s)/10)))/10*(10-(s%10))
			else
				s = 1
			end
		elseif s > 100 then
			s = (s-90)/10
		else
			s = 1
		end
		return t/s
	end
	function options.timeLine:GetTimeFromPos(x)
		local s = self.TIMELINE_SCALE
		if s < 100 then
			if s > 0 then
				s = 2^(-math.ceil((100-s)/10)+1) - (2^(-math.ceil((100-s)/10)))/10*(10-(s%10))
			else
				s = 1
			end
		elseif s > 100 then
			s = (s-90)/10
		else
			s = 1
		end
		return x*s
	end
	function options.timeLine:GetTimeAdjust(t,reverse)
		if not reverse then t = t * (self.TIMELINE_ADJUST / 100) end
		for i=1,self.TIMELINE_ADJUST_NUM do
			local adj = self.TIMELINE_ADJUST_DATA[ i ]
			if adj[1] and adj[2] and t >= adj[1] then
				t = t + adj[2] * (reverse and -1 or 1)
			end
		end
		if reverse then t = t / (self.TIMELINE_ADJUST / 100) end
		return t
	end
	function options.timeLine:IsRemovedByTimeAdjust(t)
		t = t * (self.TIMELINE_ADJUST / 100)
		for i=1,self.TIMELINE_ADJUST_NUM do
			local adj = self.TIMELINE_ADJUST_DATA[ i ]
			if adj[1] and adj[2] then
				if adj[2] < 0 and t >= adj[1]+adj[2] and t < adj[1] then
					return true
				end
				if t >= adj[1] then
					t = t + adj[2]
				end
			end
		end
	end

	function options.timeLine:GetPhaseCounter(phaseNum,notIgnoreFirst)
		local timeLineData = self.timeLineData
		local c = {}
		local f, fc
		for i=1,#timeLineData.p do
			local p = self.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i
			c[p] = (c[p] or 0) + 1
			if phaseNum == i then
				f = p
				fc = c[p]
			end
		end
		if f and (notIgnoreFirst or fc ~= 1 or c[f] > 1) then
			return fc
		end
		return nil
	end

	--phaseNum here for timeline phase, not actual phase
	---@param phaseNum number
	function options.timeLine:GetPhaseTotalCount(phaseNum)
		local timeLineData = self.timeLineData
		local c = {}
		local f = 1
		for i=1,#timeLineData.p do
			local p = self.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i
			c[p] = (c[p] or 0) + 1
			if phaseNum == i then
				f = p
			end
		end
		return c[f]
	end

	---@param time number
	---@return number? phaseName phase name or phase global counter
	---@return number? phaseStartTime
	---@return number? phaseCount
	---@return number? phaseGlobalCount
	function options.timeLine:GetPhaseFromTime(time)
		local timeLineData = self.timeLineData
		if not timeLineData or not timeLineData.p then
			return nil, nil, nil, nil
		end

		local res
		local res_time
		for i=1,#timeLineData.p do
			local phase_time = self:GetTimeAdjust(timeLineData.p[i])
			if time > phase_time then
				--do this for wrong ordered phases
				if not res_time or res_time < phase_time then
					res = i
					res_time = phase_time
				end
			end
		end
		if res then
			return (self.custom_phase[res] or timeLineData.p.n and timeLineData.p.n[res]) or res, time-self:GetTimeAdjust(timeLineData.p[res]), self:GetPhaseCounter(res), res
		end
	end

	---@param time number time since phase start
	---@param phase string|number desired phase
	---@param phaseCount string  NumberCondition for desired phase
	---@return number? globalCombatTime  time since fight start
	---@return number? phaseGlobalCount  global phase counter
	function options.timeLine:GetTimeOnPhase(time,phase,phaseCount)
		local timeLineData = self.timeLineData
		if not timeLineData or not timeLineData.p then
			return nil, nil
		end

		if phaseCount then
			phaseCount = module:CreateNumberConditions(phaseCount)
		end

		for i=1,#timeLineData.p do
			if (tostring(self.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i) == tostring(phase)) and (not phaseCount or module:CheckNumber(phaseCount,self:GetPhaseCounter(i,true))) then
				return time + self:GetTimeAdjust(timeLineData.p[i]), i
			end
		end
	end

	do
		local res = {}

		---@param time number time since phase start
		---@param phase string desired phase
		---@param phaseCount string  NumberCondition for desired phase
		---@return number? globalCombatTime  time since fight start
		---@return number? phaseGlobalCount  global phase counter
		---@return ...
		function options.timeLine:GetTimeOnPhaseMulti(time,phase,phaseCount)
			local timeLineData = self.timeLineData
			if not timeLineData then
				return nil, nil
			end

			for k in next, res do res[k]=nil end

			if phaseCount then
				phaseCount = module:CreateNumberConditions(phaseCount)
			end

			if timeLineData.p then
				for i=1,#timeLineData.p do
					if (tostring(self.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i) == tostring(phase)) and (not phaseCount or module:CheckNumber(phaseCount,self:GetPhaseCounter(i,true))) then
						res[#res+1] = time + self:GetTimeAdjust(timeLineData.p[i])
						res[#res+1] = i
					end
				end
			end

			-- if tostring(phase) == "1" and (not phaseCount or module:CheckNumber(phaseCount,1)) then
			-- 	res[#res+1] = time
			-- end
			return unpack(res)
		end
	end

	function options.timeLine:GetTimeUntilPhaseEnd(time)
		local timeLineData = self.timeLineData
		if not timeLineData.p then return end
		for i=1,#timeLineData.p do
			if time < self:GetTimeAdjust(timeLineData.p[i]) then
				return self:GetTimeAdjust(timeLineData.p[i]) - time
			end
		end
	end

	function options.timeLine:GetSpellFromTime(time,spell,afterEnd,event)
		local timeLineData = self.timeLineData
		if not timeLineData then return end

		if event and timeLineData.events and timeLineData.events[event] then
			local spellData = timeLineData.events[event][spell]
			if spellData then
				local counter = 0
				local res_time, res_counter
				for i=1,#spellData do
					local spell_time = type(spellData[i]) == "table" and spellData[i][1] or spellData[i]
					if not self:IsRemovedByTimeAdjust(spell_time) then
						local r = (type(spellData[i]) == "table" and spellData[i].r or 1)
						for j=1,r do
							counter = counter + 1

							spell_time = self:GetTimeAdjust(spell_time)

							if time >= spell_time then
								res_time = time - spell_time
								res_counter = counter
							end
						end
					end
				end

				return res_time, res_counter
			end
		elseif not event then
			if timeLineData[spell] then
				local spellData = timeLineData[spell]
				local counter = 0
				local res_time, res_counter
				for i=1,#spellData do
					local spell_time_og = (type(spellData[i]) == "table" and spellData[i][1] or spellData[i])
					if not self:IsRemovedByTimeAdjust(spell_time_og) then
						counter = counter + 1

						local spell_time = self:GetTimeAdjust(spell_time_og)

						local dur = (afterEnd and (type(spellData[i])=="table" and spellData[i].d or spellData.d or 2) or 0)
						if dur == "p" then dur = self:GetTimeUntilPhaseEnd(spell_time) or 2 end

						if time > spell_time and (not afterEnd or (time - spell_time) > dur) then
							res_time = time - spell_time - dur
							res_counter = counter
						end
					end
				end

				return res_time, res_counter
			end
		end
	end

	do
		local res = {}
		function options.timeLine:GetTimeForSpell(time,spell,counter,afterEnd,event)
			local timeLineData = self:GetTimeLineData()
			if not timeLineData then return end

			for k in next, res do res[k]=nil end

			if event and timeLineData.events and timeLineData.events[event] then
				local spellData = timeLineData.events[event][spell]
				if spellData then
					if counter then
						counter = module:CreateNumberConditions(counter)
					end

					local ci = 0
					for i=1,#spellData do
						local spell_time = (type(spellData[i]) == "table" and spellData[i][1] or spellData[i])
						if not self:IsRemovedByTimeAdjust(spell_time) then
							local r = (type(spellData[i]) == "table" and spellData[i].r or 1)
							for j=1,r do
								ci = ci + 1

								if not counter or module:CheckNumber(counter,ci) then
									spell_time = self:GetTimeAdjust(spell_time)

									res[#res+1] = time + spell_time
									res[#res+1] = ci
								end
							end
						end
					end
				end
			else --if not event then
				local spellData = timeLineData[spell]
				if spellData then
					if counter then
						counter = module:CreateNumberConditions(counter)
					end

					local ci = 0
					for i=1,#spellData do
						local spell_time = type(spellData[i])=="table" and spellData[i][1] or spellData[i]
						if not self:IsRemovedByTimeAdjust(spell_time) then
							ci = ci + 1

							if not counter or module:CheckNumber(counter,ci) then
								spell_time = self:GetTimeAdjust(spell_time)

								local dur = (afterEnd and (type(spellData[i])=="table" and spellData[i].d or spellData.d or 2) or 0)
								if dur == "p" then dur = self:GetTimeUntilPhaseEnd(spell_time) or 2 end

								res[#res+1] = time + spell_time + dur
								res[#res+1] = ci
							end
						end
					end
				end
			end

			return unpack(res)
		end
	end

	function options.timeLine:IsPassFilterSpellType(spellData,spell)
		if
			(
			 ((spellData.spellType or 1) == 1 and not self.FILTER_CAST) or
			 (spellData.spellType == 2 and not self.FILTER_AURA)
			) and
			(not self.FILTER_SPELL or self.FILTER_SPELL[spell])
		then
			return true
		end
	end

	function options.timeLine:GetTimeLineData()
		local timeLineData = self.CUSTOM_TIMELINE or (self.BOSS_ID and self.Data[self.BOSS_ID]) or (self.ZONE_ID and self.Data[-self.ZONE_ID])
		if timeLineData and timeLineData.m then return timeLineData[1] end
		return timeLineData
	end

	function options.timeLine:GetCompareTimeLineData()
		local timeLineData = self.CUSTOM_TIMELINE_CMP
		return timeLineData
	end

	options.timeLine.util_sort_reminders = function(a,b) -- {data, time, customData, timeOnPhase}
		local offsetA = a[1].durrev and a[1].duration or 0
		local offsetB = b[1].durrev and b[1].duration or 0
		local timeA = a[2] - offsetA
		local timeB = b[2] - offsetB
		if timeA~=timeB then
			return timeA<timeB
		else
			return a[1].token<b[1].token
		end
	end

	function options.timeLine:GetRemindersList(includeNote)
		local timeLineData = self.timeLineData
		-- print("GetRemindersList", timeLineData, self.BOSS_ID, self.ZONE_ID, self.FILTER_REM_ONLYMY)
		local bossList
		if timeLineData and timeLineData.p and timeLineData.p.n then
			for i=1,#timeLineData.p.n do
				if timeLineData.p.n[i] < 0 and timeLineData.p.n[i]>-10000 then
					if not bossList then bossList = {} end
					bossList[ -timeLineData.p.n[i] ] = timeLineData.p[i]
				end
			end
		end

		local data_list, data_uncategorized = {}

		local function parseReminder(token,data)
			local bossID = data.boss
			local zoneID = tostring(data.zoneID)

			local isPass = data.msg or data.glow or data.sound

			local ignoreTimeline = data.ignoreTimeline

			local searchPat = module.options.search
			if
				module:SearchInData(data,searchPat) and
				isPass and
				not ignoreTimeline and
				(not data.diff or data.diff == self.DIFF_ID) and
				(not self.BOSS_ID or bossID == self.BOSS_ID) and
				(not self.ZONE_ID or (
				 (bossList and (bossID and bossList[bossID])) or
				 module:FindNumberInString(self.ZONE_ID,zoneID)
				))
			then
				local isAdded = false
					if
					not data.disabled and
					(
						data.defDisabled and module:GetDataOption(data.token, "DEF_ENABLED") or
						not data.defDisabled and not module:GetDataOption(data.token, "DISABLED")
					) and
						#data.triggers >= 1 and #data.triggers <= 2 and
					(
						data.triggers[1].event == 3 or
						data.triggers[1].event == 2 or
						data.triggers[1].event == 20 or
						(data.triggers[1].event == 1 and ( -- and data.triggers[1].counter
							data.triggers[1].eventCLEU == "SPELL_CAST_SUCCESS" or
							data.triggers[1].eventCLEU == "SPELL_CAST_START" or
							data.triggers[1].eventCLEU == "SPELL_AURA_REMOVED" or
							data.triggers[1].eventCLEU == "SPELL_AURA_APPLIED"
						))
					) and
					(not data.triggers[2] or
						data.triggers[2].event == 13
					) and
					(not self.FILTER_REM_ONLYMY or module:CheckPlayerCondition(data))
				then
					local timeTable = module:ConvertMinuteStrToNum(data.triggers[1].delayTime) or {0}

					if bossList and bossList[bossID] then
						for i=1,#timeTable do
							if timeTable[i] then
								timeTable[i] = timeTable[i] + bossList[bossID]
							end
						end
					end

					for _, time in ipairs(timeTable) do
						local timeOnPhase, customData
						if data.triggers[1].event == 2 then
							timeOnPhase = time
							local phaseData = {self:GetTimeOnPhaseMulti(time,data.triggers[1].pattFind,data.triggers[1].counter)}
							time, customData = {}, {}
							for i=1,#phaseData,2 do
								if phaseData[i] then
									time[#time+1] = phaseData[i]
									local phaseNum = phaseData[i+1]
									if phaseNum and (self:GetPhaseTotalCount(phaseNum) or 0) > 1 then
										phaseNum = {pg = phaseData[i+1]}
									elseif phaseNum then
										phaseNum = {p = data.triggers[1].pattFind}
									end
									customData[#time] = phaseNum
								end
							end
						elseif data.triggers[1].event == 1 then
							timeOnPhase = time
							local isAfterEnd = data.triggers[1].eventCLEU == "SPELL_AURA_REMOVED"
							local spellData = {self:GetTimeForSpell(time,data.triggers[1].spellID,data.triggers[1].counter,isAfterEnd,data.triggers[1].eventCLEU)}

							time, customData = {}, {}
							for i=1,#spellData,2 do
								if spellData[i] then
									time[#time+1] = spellData[i]
									customData[#time] = {
										s = data.triggers[1].spellID,
										c = spellData[i+1],
										e = data.triggers[1].eventCLEU == "SPELL_CAST_SUCCESS" and "SCC" or
											data.triggers[1].eventCLEU == "SPELL_CAST_START" and "SCS" or
											data.triggers[1].eventCLEU == "SPELL_AURA_REMOVED" and "SAR" or
											data.triggers[1].eventCLEU == "SPELL_AURA_APPLIED" and "SAA"
									}
								end
							end

							if self.FILTER_SPELL_REP and not tonumber(data.triggers[1].counter) then
								time = nil
							end
						end

						if self.reminder_hide[token] then
							time = nil
						end

						if type(time)=="table" then
							if #time > 0 then
								for i=1,#time do
									data_list[#data_list+1] = {data, time[i], customData[i], timeOnPhase}
								end
								isAdded = true
							end
						elseif time then
							data_list[#data_list+1] = {data, time, customData, timeOnPhase}
							isAdded = true
						end
					end
				end
				if not isAdded then
					if not data_uncategorized then
						data_uncategorized = {}
					end
					if not data.fromNote then
						data_uncategorized[#data_uncategorized+1] = data
					end
				end
			end
		end

		for token,data in next, VMRT.Reminder.data do
			parseReminder(token,data)
		end

		if includeNote then
			local noteReminders = self:GetRemindersFromString(table.concat(AddonDB.GetNoteLinesForTimers(), "\n"))
			if noteReminders then
				for token,data in next, noteReminders do
					data.fromNote = true
					parseReminder(token,data)
				end
			end
		end

		sort(data_list,self.util_sort_reminders)

		return data_list, data_uncategorized
	end
	function options.timeLine:ExportToString()
		local data_list = self:GetRemindersList()

		local str = ""
		local prevTime
		for i=1,#data_list do
			---@type ReminderData
			local data, time, customData, timeOnPhase = unpack(data_list[i])

			local msg = data.msg or ""
			local pmsg
			if data.units then
				for k in string.gmatch(data.units,"[^#]+") do
					local class = select(2,UnitClass(k))
					local color
					if class and RAID_CLASS_COLORS[class] then
						color = RAID_CLASS_COLORS[class].colorStr
					end
					if not color and data.clases then
						for class in string.gmatch(data.classes,"[^#]+") do
							if RAID_CLASS_COLORS[class] then
								color = RAID_CLASS_COLORS[class].colorStr
								break
							end
						end
					end
					pmsg = (pmsg or "").."||c"..(color or "ffffffff")..k.."||r "..msg.." "
				end
			end


			if data.msg then

				local timestr = module:FormatTime(time)

				if time ~= prevTime then
					str = str .. "\n" .. "{time:"..module:FormatTime(timeOnPhase or time)..
						(customData and customData.p and ",p"..customData.p or "")..
						(customData and customData.pg and ",pg"..customData.pg or "")..
						(customData and customData.s and ","..customData.e..":"..customData.s..":"..customData.c or "")..
						"}"..timestr
					prevTime = time
				end

				str = str .. "  " .. (pmsg and pmsg:trim() or msg)

			end

		end
		str = str:trim()

		return str
	end

	local cleuToPhase = {
		["SAR:447207:1"] = "3",
		["SCS:449986:1"] = "4",
		["SCS:450483:1"] = "2",
		["SAA:447207:1"] = "2",
		["SAA:442432:1"] = "2",
		["SAA:442432:2"] = "3",
		["SAA:442432:3"] = "4",
		-- silken court
		["SAR:450980:1"] = "2",
		["SAA:451277:1"] = "2.5",
		["SAR:451277:1"] = "3",

	}

	function options.timeLine:GetRemindersFromString(text)
		if not text then return end
		local mainframe = self
		local parent = options.timeLineImportFromNoteFrame
		local timeLineData =  mainframe:GetTimeLineData()
		if not timeLineData then return end

		local reminders = {}

		local lines = {strsplit("\n",text)}
		for i=1,#lines do
			local line = lines[i]
			if line:find("{time:") then
				local time = line:match("{time:([^,}]+)")
				local isgp,p = line:match("{time:[^,}]+,p(g?)([%d%.]+)")
				local cleu = line:match("{time:[^,}]+,(S[^},]+)")
				if time then
					local x = module:ConvertMinuteStrToNum(time)
					x = x and x[1]
					if x then
						local data = MRT.F.table_copy2(module.datas.newReminderTemplate)
						data.boss = mainframe.BOSS_ID
						data.diff = mainframe.DIFF_ID
						data.zoneID = mainframe.ZONE_ID
						data.token = module:GenerateToken(reminders)
						data.duration = 3
						data.countdown = true

						local toadd = true

						--manual fixes
						if cleuToPhase[cleu] then
							p = cleuToPhase[cleu]
							cleu = nil
						end

						if not data.triggers[1] then
							data.triggers[1] = {}
						end
						data.triggers[1].event = data.zoneID and 20 or 3
						if p and p~="1" then
							local isValid = false
							if timeLineData and timeLineData.p then
								data.triggers[1].event = 2
								p = tonumber(p)
								if p then
									if isgp == "g" then
										data.triggers[1].pattFind = timeLineData.p and timeLineData.p.n and tostring(timeLineData.p.n[p-1]) or tostring(p)
									else
										data.triggers[1].pattFind = tostring(p)
									end
									if timeLineData.p.nc and tonumber(p) then
										data.triggers[1].counter = tostring(timeLineData.p.nc[tonumber(p)-1])
									end
									if data.triggers[1].pattFind then
										isValid = true
									end
								end
							end
							if not isValid then
								toadd = false
							end
						end

						if cleu then
							local isValid = false
							local cleu_event,cleu_spell,cleu_count = strsplit(":",cleu)
							if cleu_event and cleu_spell and cleu_count then
								cleu_spell = tonumber(cleu_spell)
								cleu_count = tonumber(cleu_count)

								if not cleu_spell or not cleu_count or cleu_count <= 0 then
								elseif cleu_event == "SCC" or cleu_event == "SAA" or cleu_event == "SAR" or cleu_event == "SCS" then
									data.triggers[1].event = 1
									data.triggers[1].eventCLEU = cleu_event == "SCC" and "SPELL_CAST_SUCCESS" or cleu_event == "SCS" and "SPELL_CAST_START" or cleu_event == "SAR" and "SPELL_AURA_REMOVED" or "SPELL_AURA_APPLIED"
									data.triggers[1].spellID = cleu_spell
									data.triggers[1].counter = tostring(cleu_count)
									isValid = true
								end
							end
							if not isValid then
								toadd = false
							end
						end

						local t=floor(x*10)/10
						data.triggers[1].delayTime = module:FormatTime(t,true)

						local msg = line:gsub("{time:[^}]+}",""):trim()

						if parent.opt_filter_names then
							local ability,names = strsplit("-",msg,2)
							if names then
								local str = "#"
								names = names:gsub("%b{}","")
								for n in names:gmatch("[^ ]+") do
									if not n:find("[%d_#]") then
										n = n:gsub("|+c........",""):gsub("|+r","")
										str = str .. n .. "#"
									end
								end
								if str ~= "#" then
									data.units = str
								end

								if ability then
									msg = ability
								end
							end
						end
						local everylist
						if parent.opt_everyplayer then
							for player,spell in msg:gmatch("([^ _]+) *{spell:(%d+)}") do
								player = player:gsub("||c........",""):gsub("||r","")
								if not player:find("[%d:]") and #player > 1 then
									if not everylist then everylist = {} end

									local msg1 = "{spell:"..spell.."}"
									if not parent.opt_nospellname then
										spell = tonumber(spell)
										local name = GetSpellName(spell)
										if name then
											msg1 = msg1 .. " " .. name
										end
									end
									everylist[#everylist+1] = {player,msg1}
								end
							end
						end
						if parent.opt_linesmy then
							local playerName = UnitName'player'
							if not msg:find( playerName ) then
								toadd = false
							end
						end
						if parent.opt_wordmy then
							local playerName = UnitName'player'
							if not msg:find( playerName ) then
								toadd = false
							else
								msg = msg:match(playerName.."[^ ]* ([^ ]+)")
								if not msg then
									toadd = false
								end
								if msg and msg:gsub("%b{}",""):trim() == "" and msg:find("{spell:%d+") then
									local spell = msg:match("{spell:(%d+)")
									if not parent.opt_nospellname then
										spell = tonumber(spell)
										local name = GetSpellName(spell)
										if name then
											msg = msg .. " " .. name
										end
									end
								end
							end
						end
						if parent.opt_rev then
							data.durrev = true
						end

						if msg:find("^ *%- *") then
							msg = msg:gsub("^ *%- *","")
						end

						data.msg = msg

						if toadd and (not p or timeLineData) then
							if everylist then
								for i=1,#everylist do
									local player,msg = everylist[i][1],everylist[i][2]

									local data3 = MRT.F.table_copy2(data)
									data3.token = module:GenerateToken(reminders)

									data3.msg = msg
									data3.units = "#" .. player .. "#"

									if parent.opt_spellcd then
										options:AddSpellCDCheckTrigger(data3)
									end

									reminders[data3.token] = data3

									-- prettyPrint("Added line with player filter",data3.triggers[1].delayTime,player,msg)
								end
							else
								if parent.opt_spellcd then
									options:AddSpellCDCheckTrigger(data)
								end

								reminders[data.token] = data
								-- prettyPrint("Added line",data.triggers[1].delayTime,msg)
							end
						end
					end
				end
			end
		end
		return reminders
	end

	function options.timeLine:ResetAdjust()
		self.TIMELINE_ADJUST = 100
		wipe(self.TIMELINE_ADJUST_DATA)
		options.timeLineAdjustFL.subframe.timeScale.lock = true
		options.timeLineAdjustFL.subframe.timeScale:SetValue(self.TIMELINE_ADJUST)
		options.timeLineAdjustFL.subframe.timeScale.lock = false
		for i=1,self.TIMELINE_ADJUST_NUM do
			self.TIMELINE_ADJUST_DATA[i] = {0,0}
			options.timeLineAdjustFL.subframe["tpos"..i]:SetText("0")
			options.timeLineAdjustFL.subframe["addtime"..i]:SetText("0")
		end
	end

	function options.timeLine:CreateCustomTimelineFromHistory(fight,fightData)
		local isChallenge = fight[1] and fight[1][2] == 20

		local data = {
			events={},
			fightData=fightData,
			d={
				[1] = isChallenge and 8 or fightData.diff,
				[2] = fight[1] and (fight[#fight][1]-fight[1][1]),
				k = isChallenge and fightData.diff or nil
			},
		}


		local var = {spell = {}, aura = {}}
		local phase_counters = {}

		local function add(spell,spellType,time,dur,cast) -- 1 cast, 2 aura
			if data[spell] and data[spell].spellType == 2 and spellType == 1 then
				data[spell] = {spellType = spellType}
			end
			if data[spell] and data[spell].spellType ~= spellType then
				return
			end
			if not data[spell] then
				data[spell] = {spellType = spellType}
			end
			local r = time
			if dur or cast then r = {r} end
			if dur then r.d = dur end
			if cast then r.c = cast end
			data[spell][ #data[spell]+1 ] = r
		end

		local start = fight[1] and fight[1][1]
		for i=1,#fight do
			local hline = fight[i]
			if hline[2] == 1 and false then
				if
				 (hline[3] == "SPELL_CAST_SUCCESS" or hline[3] == "SPELL_CAST_START") or
				 (hline[3] == "SPELL_AURA_APPLIED" or hline[3] == "SPELL_AURA_REMOVED")
				then
					local spell = hline[12]
					if not data[spell] then data[spell] = {} end
					data[spell][ #data[spell]+1 ] = hline[1] - start
				end
			elseif hline[2] == 1 and not GUIDIsPlayer(hline[5]) then
				local subEvent = hline[3]
				local spellID = hline[4]
				local sourceGUID = hline[5]
				local destGUID = hline[8]

				data.events[subEvent] = data.events[subEvent] or {}
				data.events[subEvent][spellID] = data.events[subEvent][spellID] or {}
				data.events[subEvent][spellID][#data.events[subEvent][spellID]+1] = hline[1] - start


				if hline[3] == "SPELL_CAST_START" then
					var.spell[#var.spell+1] = hline
				elseif hline[3] == "SPELL_CAST_SUCCESS" then
					local s, cast, dur = hline[1] - start
					for j=#var.spell,1,-1 do
						if var.spell[j][4] == hline[4] and var.spell[j][5] == hline[5] then -- 4 source - 12 spell
							cast = hline[1]-var.spell[j][1]
							if cast >= 10 then
								-- dur, cast = cast
								-- s = var.spell[j][1] - start
							end
							-- if cast > 10 then
							-- 	cast = nil
							-- end
							tremove(var.spell,j)
							break
						end
					end
					add(hline[4],1,s,dur,cast)
				elseif hline[3] == "SPELL_AURA_APPLIED" then
					var.aura[#var.aura+1] = hline
				elseif hline[3] == "SPELL_AURA_REMOVED" then
					local s, dur = hline[1] - start
					for j=1,#var.aura do
						if var.aura[j][4] == hline[4] and var.aura[j][5] == hline[5] and var.aura[j][8] == hline[8] then -- 4 source - 8 dest - 12 spell
							dur = hline[1]-var.aura[j][1] -- 4 spell 5 source 8 dest
							s = var.aura[j][1] - start
							tremove(var.aura,j)
							break
						end
					end
					add(hline[4],2,s,dur)
				end
			elseif hline[2] == 2 and not isChallenge then -- phase
				local phase = tonumber(hline[3])
				phase_counters[phase] = (phase_counters[phase] or 0) + 1
				if not data.p then data.p = {n={},nc={}} end
				data.p[ #data.p+1 ] = hline[1] - start
				data.p.n[ #data.p ] = phase
				data.p.nc[ #data.p ] = phase_counters[phase]
			elseif hline[2] == 3 and isChallenge then -- boss in m+
				if not data.p then data.p = {n={}} end
				data.p[ #data.p+1 ] = hline[1] - start
				data.p.n[ #data.p ] = -hline[3]
			elseif hline[2] == 0 and isChallenge then -- end of the fight with the boss in m+
				if not data.p then data.p = {n={}} end
				data.p[ #data.p+1 ] = hline[1] - start
				data.p.n[ #data.p ] = 0
			end
		end
		-- for i=1,#var.spell do add(var.spell[i][4],1,var.spell[i][1] - start) end
		-- for i=1,#var.aura do add(var.aura[i][4],2,var.aura[i][1] - start) end
		for _,list in next, data do
			sort(list,function(a,b)
				local timea = type(a)=="table" and a[1] or a
				local timeb = type(b)=="table" and b[1] or b
				return timea < timeb
			end)
		end

		-- local dump = {data = data, fightData = fightData, fight = fight}
		-- REMINDER_LAST_TIMELINE_DUMP = dump
		-- ddt(dump, "Custom timeline data")
		return data
	end

	local TLbossMenu
	self.timeLineBoss = ELib:DropDown(self.TIMELINE_TAB,250,-1):Point("TOPLEFT",10,-10):Size(220):SetText(LR["Select boss"])
	self.timeLineBoss.mainframe = options.timeLine

	self.timeLineBoss.UpdateText = function(self)
		local timeLineData = self.mainframe:GetTimeLineData()

		local bossID = self.mainframe.BOSS_ID
		local zoneID = self.mainframe.ZONE_ID
		local fightDuration = timeLineData and timeLineData.d and timeLineData.d[2] and module:FormatTime(timeLineData.d[2])
		local diffID = timeLineData and timeLineData.d and timeLineData.d[1]
		local keyLevel = timeLineData and timeLineData.d and timeLineData.d.k -- in old data we can have key level in d[1]
		-- local customTimelineCmp = self.mainframe.CUSTOM_TIMELINE_CMP

		local str = ""
		if fightDuration then
			str = format("(%s)",fightDuration)
		end
		if zoneID and keyLevel then
			str = str .. " " .. "+"..keyLevel
		elseif diffID then
			str = str .. " " .. LR.diff_name_short[diffID]
		end

		if bossID then
			str = str .. " " .. LR.boss_name[bossID]
		elseif zoneID then
			str = str .. " " .. LR.instance_name[zoneID]
		end

		self:SetText(str)
	end


	self.timeLineBoss.SetValue = AddonDB:WrapAsyncSingleton(defaultAsyncConfig, function(data)
		if TLbossMenu then
			TLbossMenu:Close()
		end
		ELib:DropDownClose()
		data = data.data or data

		options.timeLine.frame.bigBossButtons:Hide()

		if IsShiftKeyDown() and IsAltKeyDown() then
			local cmp
			if data.tl then
				cmp = data.tl
				if cmp.m then
					cmp = cmp[1]
				end
			elseif data.fightData then
				local tempHistory
				if type(data.fightData.log) == "string" then
					tempHistory = AddonDB.RestoreFromHistory(data.fightData.log)
				elseif type(data.fightData.log) == "table" then
					tempHistory = data.fightData.log
				end

				cmp = options.timeLine:CreateCustomTimelineFromHistory(tempHistory, data.fightData)
				options.timeLine.frame.initSpinner:Stop()
			end
			if cmp then
				options.timeLine.CUSTOM_TIMELINE_CMP = cmp
				prettyPrint('Comparing timelines')
				options.timeLine:Update()
			end
			self.timeLineBoss:UpdateText()
			return
		end

		module.db.simrun = nil
		wipe(options.timeLine.custom_phase)
		wipe(options.timeLine.reminder_hide)

		options.timeLine:ResetAdjust()

		options.timeLine.BOSS_ID = nil
		options.timeLine.ZONE_ID = nil
		options.timeLine.DIFF_ID = nil
		options.timeLine.CUSTOM_TIMELINE = nil
		options.timeLine.CUSTOM_TIMELINE_CMP = nil
		VMRT.Reminder.TLBoss = nil
		options.timeLine.FILTER_SPELL = nil

		if data.bossID > 0 then
			options.timeLine.BOSS_ID = data.bossID
		else -- M+ timeline
			options.timeLine.ZONE_ID = -data.bossID
		end
		VMRT.Reminder.TLBoss = {bossID = data.bossID}

		local selectedTimeline = self.timeLine:GetTimeLineData()
		if data.tl then
			selectedTimeline = data.tl
			if selectedTimeline.m then
				selectedTimeline = selectedTimeline[1]
			end
		elseif data.fightData then
			options.timeLine.frame.initSpinner:Start(10)
			local tempHistory
			if type(data.fightData.log) == "string" then
				tempHistory = AddonDB.RestoreFromHistory(data.fightData.log)
			elseif type(data.fightData.log) == "table" then
				tempHistory = data.fightData.log
			end

			-- ddt(tempHistory)
			selectedTimeline = options.timeLine:CreateCustomTimelineFromHistory(tempHistory, data.fightData)
			options.timeLine.frame.initSpinner:Stop()
		end

		if selectedTimeline then
			options.timeLine.DIFF_ID = selectedTimeline.d and selectedTimeline.d[1]
			options.timeLine.CUSTOM_TIMELINE = selectedTimeline
		end

		local bossData = options.timeLine.Data[data.bossID]
		if bossData and bossData.m then
			for i=1,#bossData do
				if bossData[i] == selectedTimeline then
					VMRT.Reminder.TLBoss.dataIndex = i
					break
				end
			end
		end

		self.timeLineBoss:UpdateText()
		if not data.ignoreReload then
			options.timeLine:Update()
			data.tl = selectedTimeline
			data.ignoreReload = true
			options.assignBoss.SetValue(data)
		end
	end)

	local extent = 20
	local maxCharacters = 12
	local maxScrollExtent = extent * maxCharacters

	local function SelectFirstEntry(data)
		if data.subMenu then
			SelectFirstEntry(data.subMenu[1])
		elseif data.func then
			data.func(data)
		else
			data.dropdown.SetValue(data)
		end
	end

	local function CheckSubMenu(_,button)
		if button:CanOpenSubmenu() then
			button:ForceOpenSubmenu()
		end
	end

	---@param dropdown any
	---@param elementDescription RootMenuDescriptionProxy|ElementMenuDescriptionProxy
	local function MenuProcessor(dropdown, elementDescription, data)
		data.dropdown = dropdown

		if data.isHidden then
			return
		end

		if data.isTitle then
			elementDescription:CreateTitle(data.text)
		elseif data.isSpacer then
			elementDescription:CreateSpacer()
		elseif data.isDivider then
			elementDescription:CreateDivider()
		elseif data.subMenu then
			local text = data.text
			if data.icon then
				text = "|T"..data.icon..":"..extent..":"..(extent*1.5).."|t "..text
			end

			local button = elementDescription:CreateButton(text, data.func or SelectFirstEntry, data)
			button:SetScrollMode(maxScrollExtent)
			button:HookOnEnter(CheckSubMenu)

			for i, subData in ipairs(data.subMenu) do
				MenuProcessor(dropdown, button, subData)
			end
		elseif data.func then
			local button = elementDescription:CreateButton(data.text, data.func, data)
			if data.isDisabled then
				button:SetEnabled(false)
			end
		else
			local text
			if data.fightData and data.fightData.success == 1 then
				text = "|cff88ff88"..data.text
			else
				text = data.text
			end

			if data.icon then
				text = "|T"..data.icon..":"..extent..":"..(extent*1.5).."|t "..text
			end

			local button = elementDescription:CreateButton(text, function(...) dropdown.SetValue(...) end, data)
			button:SetTooltip(function(tooltip, elementDescription)
				tooltip:AddLine(MenuUtil.GetElementText(elementDescription))
				local fightData = elementDescription.data.fightData
				if fightData then
					tooltip:AddDoubleLine(LR["Fight timer"], module:FormatTime(fightData.duration), 1, 1, 1, 1, 1, 1)
					tooltip:AddDoubleLine(LR["Fight started"], date("%H:%M:%S %d/%m/%y", fightData.date), 1, 1, 1, 1, 1, 1)
					tooltip:AddDoubleLine(LR["Difficulty"], not fightData.isMPlus and LR.diff_name[fightData.diff] or fightData.diff, 1, 1, 1, 1, 1, 1)
					if fightData.source then
						tooltip:AddDoubleLine(LR["Source"], fightData.source, 1, 1, 1, 1, 1, 1)
					end
				elseif elementDescription.data.tooltip then
					tooltip:AddLine(elementDescription.data.tooltip, 1, 1, 1)
				end
			end)
			return button
		end
	end

	---@param ownerRegion any
	---@param rootDescription RootMenuDescriptionProxy|ElementMenuDescriptionProxy
	local menuGenerator = function(ownerRegion,rootDescription)
		for i,data in ipairs(ownerRegion.List) do
			MenuProcessor(ownerRegion,rootDescription,data)
		end
	end

	self.timeLineBoss.Button:SetScript("OnClick",function(self)
		options.timeLineBoss:PreUpdate()
		TLbossMenu = MenuUtil.CreateContextMenu(options.timeLineBoss,menuGenerator)
	end)

	function self.timeLineBoss:SelectBoss(bossID)
		local L = self.List
		for i=1,#L do
			local line = L[i]
			if line.subMenu then
				for j=1,#line.subMenu do
					local subline = line.subMenu[j]
					if subline.arg1 == bossID then
						return subline.func(subline)
					end
				end
			end
		end
	end

	local ImportHistory = AddonDB:WrapAsync(function(str)
		if not str or #str < 200 then
			prettyPrint("Invalid import string")
		end
		local historyEntry = module:ProcessHistoryTextToData("Import", str)
		if not historyEntry then
			prettyPrint("Invalid import string")
			return
		end
		local encounterID = historyEntry.encounterID

		local d = {
			bossID = encounterID,
			fightData = historyEntry,
		}
		if options.assign.frame:IsVisible() then
			options.assignBoss.SetValue(d)
		else
			self.timeLineBoss.SetValue(d)
		end
	end)

	local ExportHistory = AddonDB:WrapAsync(function(fightData)
		return module:GetHistoryExportString(fightData)
	end)

	local function importDropDownFunc()
		AddonDB:QuickPaste(LR["Import History"], ImportHistory)
	end

	local function exportDropDownFunc()
		local fightData = self.timeLineBoss.mainframe.CUSTOM_TIMELINE and self.timeLineBoss.mainframe.CUSTOM_TIMELINE.fightData
		if fightData then
			AddonDB:QuickCopy(ExportHistory(fightData), LR["Export History"])
		end
	end

	local function subMenuSortFunc(a, b)
		if a.zoneID and b.zoneID then
			return (a.prio or 0) < (b.prio or 0)
		elseif a.zoneID then
			return true
		elseif b.zoneID then
			return false
		elseif a.bossID and b.bossID then
			return (a.prio or 0) < (b.prio or 0)
		elseif a.bossID then
			return true
		elseif b.bossID then
			return false
		end
	end

	local function PrepareSubmenu(subMenu, parent) -- merge submenu with parent if there is only one option
		for k, v in next, subMenu do
			if v.subMenu and #v.subMenu > 0 then
				PrepareSubmenu(v.subMenu, v)
			end
		end
		sort(subMenu, subMenuSortFunc)
	end

	function self.timeLineBoss:PreUpdate()
		local List = self.List
		wipe(List)

		local res
		local listDung = {}
		local listMPlus = {}

		local function Add(tableToAdd, bossID, bossData, category)
			local diff = bossData.d[1]
			local diffName = LR.diff_name[diff]
			local keyLevel = bossData.d.k
			local hasEventsData = bossData.events
			local isPtr = bossData.PTR

			if category == "raid" or category == "dung" then -- boss
				local encounterName = LR.boss_name[bossID]
				local bossImg = AddonDB:GetBossPortrait(bossID)

				local bossMenu = MRT.F.table_find3(tableToAdd.subMenu, bossID, "bossID")
				if not bossMenu then
					bossMenu = {
						text = encounterName,
						subMenu = {},
						bossID = bossID,
						icon = bossImg,
						prio = AddonDB:GetEncounterSortIndex(bossID),
					}
					tableToAdd.subMenu[#tableToAdd.subMenu+1] = bossMenu
				end

				local text = (diffName or "") .. (keyLevel and " +"..keyLevel or "") .. " "..
					"(" .. module:FormatTime(bossData.d[2]) .. ")" ..
					(hasEventsData and " |cff00ff00*|r" or "") ..
					(isPtr and " |cffff0000PTR|r" or "")

				text = text:trim()

				bossMenu.subMenu[#bossMenu.subMenu+1] = {
					text = text,
					bossID = bossID,
					tl = bossData,
					icon = bossImg,
					iconsize = 32,
				}
			else -- m+ run
				local zoneID = -bossID
				local foregroundImage, backgroundImage, instanceName = AddonDB:GetInstanceImage(zoneID)
				local customName = bossData.n
				local text = (customName or "") .." ".. (keyLevel and "+"..keyLevel or "") .. " "..
					"(" .. module:FormatTime(bossData.d[2]) .. ")" ..
					(hasEventsData and " |cff00ff00*|r" or "") ..
					(isPtr and " |cffff0000PTR|r" or "")

				text = text:trim()

				tableToAdd.subMenu[#tableToAdd.subMenu+1] = {
					text = text,
					bossID = bossID,
					tl = bossData,
					zoneID = zoneID,
					icon = foregroundImage,
					iconsize = 32,
				}
			end
		end

		for bossID, bossData in next, options.timeLine.Data do
			local isZone = bossID < 0
			local instanceID = isZone and -bossID or AddonDB:GetInstanceForEncounter(bossID)

			local category = bossID < 0 and "m+" or AddonDB:InstanceIsDungeon(AddonDB.EJ_DATA.instanceIDtoEJ[ instanceID ]) and "dung" or "raid"
			local tableToAdd

			local l = category == "dung" and listDung or category == "m+" and listMPlus or self.List
			tableToAdd = MRT.F.table_find3(l, instanceID, "zoneID")
			if not tableToAdd then
				local foregroundImage, backgroundImage, instanceName = AddonDB:GetInstanceImage(instanceID)
				tableToAdd = {
					text = instanceName,
					zoneID = instanceID,
					subMenu = {},
					icon = foregroundImage,
					category = category,
					prio = AddonDB:GetInstanceSortIndex(instanceID),
				}
				l[#l+1] = tableToAdd
			end

			if bossData.m then -- multiple
				for i, bossData_i in ipairs(bossData) do
					Add(tableToAdd, bossID, bossData_i, category)
				end
			else -- single
				Add(tableToAdd, bossID, bossData, category)
			end

				-- After login select previously selected boss or boss that was previously pulled
			if VMRT.Reminder.TLBoss and (type(VMRT.Reminder.TLBoss) == "table" and VMRT.Reminder.TLBoss.bossID == bossID) then
				if VMRT.Reminder.TLBoss.dataIndex then
					local d = {
						bossID = bossID,
						tl = bossData.m and (bossData[VMRT.Reminder.TLBoss.dataIndex] or bossData[1]) or bossData,
					}
					res = function() self.SetValue(d) end
				else
					local d = {
						bossID = bossID,
					}
					res = function() self.SetValue(d) end
				end
			elseif not res and VMRT.Reminder.lastEncounterID == bossID then
				local d = {
					bossID = bossID,
				}
				res = function() self.SetValue(d) end
			end
		end

		PrepareSubmenu(self.List)

		if self.mainframe.frame.bigBossButtons:IsShown() then
			local list = self.List[1] -- most recent tier
			if list and list.category == "raid" then
				self.mainframe.frame.bigBossButtons:Reset()
				for i=1,#list.subMenu do
					local encounterID = list.subMenu[i].bossID
					local inlist = list.subMenu[i]
					if inlist then
						self.mainframe.frame.bigBossButtons:Add(encounterID, function() self.SetValue(inlist) end)
					end
				end
			end
		end

		if #listDung > 0 then
			PrepareSubmenu(listDung)
			self.List[#self.List+1] = { text = DUNGEONS or "DUNGEONS", entryID = "dung", subMenu = listDung }
			-- sort here
		end
		if #listMPlus > 0 then
			PrepareSubmenu(listMPlus)
			self.List[#self.List+1] = { text = PLAYER_DIFFICULTY_MYTHIC_PLUS or "M+", entryID = "m+", subMenu = listMPlus }
			-- sort here
		end

		tinsert(self.List, 1, {
			text = LR.Main,
			isTitle = true,
		})

		self.List[ #self.List+1 ] = {
			isDivider = true,
		}

		self.List[#self.List+1] = {
			text = LR["Own Data"],
			isTitle = true,
		}

		local historyList = {}
		for encounterID, tbl in next, module.db.history do
			local tableToAdd -- zone or subMenu
			local isZone = encounterID == "m+"

			local bossImg, instanceID

			if not isZone then -- boss
				bossImg = AddonDB:GetBossPortrait(encounterID)
				instanceID = AddonDB:GetInstanceForEncounter(encounterID)
			end

			if not isZone and instanceID then
				local zone_data = MRT.F.table_find3(historyList, instanceID, "zoneID")
				if not zone_data then
					local instanceName = LR.instance_name[instanceID]
					zone_data = {
						zoneID = instanceID,
						prio = AddonDB:GetInstanceSortIndex(instanceID),
						text = instanceName,
						subMenu = {},
						icon = AddonDB:GetInstanceImage(instanceID),
					}
					historyList[#historyList+1] = zone_data
				end
				tableToAdd = zone_data.subMenu
			else
				tableToAdd = historyList
			end

			local bossMenu
			if not isZone then
				local encounterName = LR.boss_name[encounterID]
				bossMenu = {
					text = encounterName,
					subMenu = {},
					bossID = encounterID,
					prio = AddonDB:GetEncounterSortIndex(encounterID),
					icon = bossImg,
				}
			else
				bossMenu = {
					text = PLAYER_DIFFICULTY_MYTHIC_PLUS or "M+",
					subMenu = {},
					zoneID = -1,
				}
			end
			tableToAdd[#tableToAdd+1] = bossMenu

			for diffID, history in next, tbl do -- for zones it is -zoneID, history
				local text, zoneImg
				if isZone then
					text = LR.instance_name[-diffID]
					zoneImg = AddonDB:GetInstanceImage(-diffID)
				else
					text = LR.diff_name[diffID]
				end
				local diffMenu = {
					text = text, -- for zone it is instanceName, for boss it is diff name
					subMenu = {},
					prio = diffID,
					icon = zoneImg,
				}
				bossMenu.subMenu[#bossMenu.subMenu+1] = diffMenu
				for i, fightData in ipairs(history) do
					local duration = fightData.duration

					local lockIcon = "|TInterface\\AddOns\\" .. GlobalAddonName .. "\\Media\\Textures\\lock.tga:0|t "
					if isZone then
						local instanceName = LR.instance_name[-diffID]
						local keyLevel = fightData.diff
						local text = (fightData.pinned and lockIcon or "") .. instanceName .. " +" .. keyLevel .. " " .. (module:FormatTime(duration))
						diffMenu.subMenu[#diffMenu.subMenu+1] = {
							text = text,
							fightData = fightData,
							bossID = diffID,
						}
					else
						local diffName = LR.diff_name[diffID] or diffID
						local text = (fightData.pinned and lockIcon or "") ..(LR.boss_name[encounterID]).." - #"..i .." "..diffName ..  " "..(module:FormatTime(duration))
						diffMenu.subMenu[#diffMenu.subMenu+1] = {
							text = text,
							fightData = fightData,
							bossID = encounterID,
							prio = AddonDB:GetEncounterSortIndex(encounterID),
						}
					end
				end
			end

			sort(bossMenu.subMenu, function(a,b)
				local prioA = diffSortPrio[a.prio]
				local prioB = diffSortPrio[b.prio]
				if prioA and prioB then
					return prioA < prioB
				elseif prioA then
					return true
				elseif prioB then
					return false
				else
					return a.prio > b.prio
				end
			end)
		end

		if #historyList > 0 then
			sort(historyList, subMenuSortFunc)
			for i=1,#historyList do
				local t = historyList[i]
				if t.zoneID then
					sort(t.subMenu, subMenuSortFunc)
				end
			end

			self.List[ #self.List+1 ] = {
				text = LR.FromHistory,
				subMenu = historyList,
				prio = -99996,
			}
			self.List[ #self.List+1 ] = {
				isSpacer = true,
				prio = -99997,
			}
		end

		self.List[ #self.List+1 ] = {
			text = LR.ImportHistory,
			func = importDropDownFunc,
		}
		self.List[ #self.List+1 ] = {
			text = LR.ExportHistory,
			func = exportDropDownFunc,
			isDisabled = not (self.mainframe.CUSTOM_TIMELINE and self.mainframe.CUSTOM_TIMELINE.fightData),
		}

		self.List[#self.List+1] = {
			text = LR.Custom .. " encounter ID",
			func = function()
				ELib:DropDownClose()
				MRT.F.ShowInput2(LR["Custom"] .. " encounter id",function(res)
					local id = tonumber(res[1] or "?")
					if not id then
						return
					end
					local diff = tonumber(res[2] or "?")

					self.SetValue({
						bossID=id,
						tl={
							d={diff or nil, 600}
						}
					})
				end,{text=LR.EncounterID,onlyNum=true},{text=LR.DifficultyID,onlyNum=true}) end,
		}
		local customSubMenu = {}
		if VMRT.Reminder.CustomTLData then
			for bossID,data in next, VMRT.Reminder.CustomTLData do
				local name = bossID < 0 and LR.instance_name[-bossID] or LR.boss_name[bossID]
				customSubMenu[#customSubMenu+1] = {
					text = name .. " ".. module:FormatTime(data.d and data.d[2] or 0),
					bossID = bossID,
					tl = data,
					prio = bossID,
					subMenu = {
						{
							text = LR["Edit"],
							arg1 = bossID,
							arg2 = data,
							func = function(data)
								ELib:DropDownClose()
								options.timeLine.customTimeLineDataFrame:OpenEdit(data.arg1,data.arg2)
							end
						},
						{
							text = LR["Delete"],
							arg1 = bossID,
							arg2 = data,
							func = function(data)
								ELib:DropDownClose()
								VMRT.Reminder.CustomTLData[data.arg1] = nil
							end
						},
					},
				}
			end
		end
		customSubMenu[#customSubMenu+1] = {
			text = LR["Open editor"],
			func = function() ELib:DropDownClose() options.timeLine.customTimeLineDataFrame:OpenEdit(nil,{}) end,
		}
		sort(customSubMenu,function(a,b)
			return (a.prio or 0) > (b.prio or 0)
		end)
		self.List[#self.List+1] = {
			text = LR.Custom,
			subMenu = customSubMenu,
			Lines = #customSubMenu > 15 and 15,
		}
		if AddonDB.IsDev then
			self.List[#self.List+1] = {
				isDivider = true,
			}
			self.List[#self.List+1] = {
				text = "Dev: Export timeline",
				func = function()
					options:ExportTimeline(true)
				end,
			}
		end

		return res
	end

	for bossID, bossData in next, options.timeLine.Data do
		if bossData.m then
			for i = 1, #bossData do
				if bossData[i].p and bossData[i].p[1] < 0 then
					local spell = -bossData[i].p[1]
					local diff = bossData[i].p[2] and bossData[i].p[2] > 0 and bossData[i].p[2] or 0
					for j=1,#bossData[i][spell] do
						bossData[i].p[j] = bossData[i][spell][j] + diff
					end
				end
			end
		end
	end


	local function StartTestRun()
		CancelAllSimrunTimers()

		module:CreateFunctions(options.timeLine.BOSS_ID,options.timeLine.DIFF_ID,options.timeLine.ZONE_ID,true)
		module.db.simrun = 0
		module.db.simrunspeed = module.db.SIMRUN_SPEED_MULTIPLIER or 1

		-- do not show reminders that are shown immediately while in the SIMRUN_START_OFFSET window
		module.db.simrun_mute = module.db.SIMRUN_START_OFFSET and true or nil

		if options.timeLine.ZONE_ID then
			module:TriggerMplusStart()
		else
			module:TriggerBossPull()
		end

		local timeLineData = options.timeLine:GetTimeLineData()
		if timeLineData and not options.timeLine.ZONE_ID and timeLineData.p then
			for i=1,#timeLineData.p do
				local delay = timeLineData.p[i]
				local phase = options.timeLine.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i
				local globalPhase = i
				if not options.timeLine:IsRemovedByTimeAdjust(delay) then
					ScheduleSimrunTimer(module.TriggerBossPhase, delay, module, tostring(phase), tostring(globalPhase))
				end
			end
			if timeLineData.events then
				for event, eventsTable in next, timeLineData.events do
					for spellID, delaysTable in next, eventsTable do
						for i,delay in next, delaysTable do
							local d = type(delay) == "table" and delay[1] or delay
							local r = type(delay) == "table" and delay.r or 1
							if module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED then
								if not options.timeLine:IsRemovedByTimeAdjust(d) then
									d = options.timeLine:GetTimeAdjust(d)
									for j = 1, r do
										ScheduleSimrunTimer(module.main.COMBAT_LOG_EVENT_UNFILTERED, d,
										nil, event, nil,
										"Creature-0-4255-1530-15001-108361-000065DDA7", "Crystalline Scorpid", 0, 0,
										UnitGUID("player"), MRT.SDB.charKey, 0, 0,
										spellID, GetSpellName(spellID) or ""
										)
									end
								end
							end
						end
					end
				end
			end
		end

		-- just dont be clowns pls
		if module.db.SIMRUN_START_OFFSET and module.db.SIMRUN_START_OFFSET > 0 and module.db.SIMRUN_START_OFFSET < 10000 then
			local onUpdateScript = SimrunScheduler:GetScript("OnUpdate")
			while module.db.simrun < module.db.SIMRUN_START_OFFSET do
				onUpdateScript(SimrunScheduler, 0.05)
			end
		end

		module.db.simrun_mute = nil

		local tt = module.db.simrun
		C_Timer.NewTicker(0.05, function(self)
			if not module.db.simrun or not options:IsVisible() or not SimrunScheduler or not next(SimrunScheduler.timers) then
				if not SimrunScheduler or not next(SimrunScheduler.timers) then
					prettyPrint("No timers left, stopping simulation")
				end
				options.timeLineTestRun:SetText(LR["Timeline simulation"])
				self:Cancel()
				prettyPrint("Test run ended on "..module:FormatTime(tt,true))
				CancelAllSimrunTimers()
				module:ReloadAll()
				return
			end
			tt = module.db.simrun
			options.timeLineTestRun:SetText("Run: "..module:FormatTime(module.db.simrun,true))
		end)
	end

	self.timeLineTestRun = MLib:Button(self.TIMELINE_TAB,LR["Timeline simulation"]):Tooltip(LR.StartTestFightTip):Point("TOP",self.TIMELINE_TAB,0,-10):Point("RIGHT",self,-10,0):Size(160,20):OnClick(function(self,...)
		self:PreUpdate()
		if #self.List > 0 then
			ELib.ScrollDropDown.ClickButton(self,...)
		end
	end)
	self.timeLineTestRun:SetScript("OnHide",function()
		ELib:DropDownClose()
	end)
	self.timeLineTestRun.List = {}
	self.timeLineTestRun.Width = 200
	-- self.timeLineTestRun.Lines = -1
	self.timeLineTestRun.isButton = true
	self.timeLineTestRun.isModern = true

	function self.timeLineTestRun:PreUpdate()
		local List = self.List
		wipe(List)

		if not module.db.simrun then
			List[#List+1] = {
				text = LR["Start simulation"],
				func = function()
					ELib:DropDownClose()
					module.db.simrunspeed = nil
					StartTestRun()
				end,
			}
			List[#List+1] = {
				isTitle = true,
			}
			List[#List+1] = {
				text = LR["Simulation start time"],
				isTitle = true,
			}
			List[#List+1] = {
				edit = module.db.SIMRUN_START_OFFSET and module:FormatTime(module.db.SIMRUN_START_OFFSET) or "0",
				editFunc = function(self)
					local dt = module:ConvertMinuteStrToNum(self:GetText())
					if dt and dt[1] and dt[1] > 0 then
						module.db.SIMRUN_START_OFFSET = dt[1]
						return
					end
					module.db.SIMRUN_START_OFFSET = nil
				end,
			}
		elseif SimrunScheduler and SimrunScheduler.paused then
			List[#List+1] = {
				text = LR["Resume simulation"],
				func = function()
					ELib:DropDownClose()
					ResumeSimrunTimers()
				end,
			}
			List[#List+1] = {
				text = LR["Cancel simulation"],
				func = function()
					ELib:DropDownClose()
					CancelAllSimrunTimers()
					module:ReloadAll()
				end,
			}
		else
			List[#List+1] = {
				text = LR["Pause simulation"],
				func = function()
					ELib:DropDownClose()
					PauseSimrunTimers()
				end,
			}
			List[#List+1] = {
				text = LR["Cancel simulation"],
				func = function()
					ELib:DropDownClose()
					CancelAllSimrunTimers()
					module:ReloadAll()
				end,
			}
		end

		List[#List+1] = {
			isTitle = true,
		}
		List[#List+1] = {
			text = LR["Simulation speed multiplier"],
			isTitle = true,
		}
		List[#List+1] = {
			text = "",
			isTitle = true,
			slider = {min = 1, max = 20, val = module.db.SIMRUN_SPEED_MULTIPLIER or 1, afterText = "x", func = function(self,val)
				module.db.SIMRUN_SPEED_MULTIPLIER = floor(val + .5)
				if module.db.simrun then
					module.db.simrunspeed = module.db.SIMRUN_SPEED_MULTIPLIER
				end
			end},
		}
	end


	self.timeLineImportFromNoteFrame = ELib:Popup(" "):Size(600,400+200+25)
	ELib:Border(self.timeLineImportFromNoteFrame,1,.4,.4,.4,.9)

	self.timeLineImportFromNoteFrame.Edit = ELib:MultiEdit(self.timeLineImportFromNoteFrame):Point("TOP",0,-15):Size(590,355)
	self.timeLineImportFromNoteFrame.Import = MLib:Button(self.timeLineImportFromNoteFrame,LR.ImportAdd):Point("BOTTOM",0,5):Size(590,20):OnClick(function(self)
		local parent = self:GetParent()
		local text = parent.Edit:GetText()
		local mainframe = parent.mainframe
		local timeLineData =  mainframe:GetTimeLineData()
		if not timeLineData then return end

		mainframe.undoimportlist = {remove={},repair={}}

		if parent.opt_removebefore then
			local currentlist = options.timeLine:GetRemindersList()

			for i=1,#currentlist do
				local token = currentlist[i][1].token
				mainframe.undoimportlist.repair[token] = VMRT.Reminder.data[token]
				VMRT.Reminder.data[token] = nil
			end
		end

		local reminders = mainframe:GetRemindersFromString(text)

		for token,data in next, reminders do
			prettyPrint("Added line",data.triggers[1].delayTime,data.msg,data.units and data.units:gsub("#", ""):trim() or "")
			module:AddReminder(token,data)
			mainframe.undoimportlist.remove[token] = true
		end

		parent:Hide()
		options:Update()
		module:ReloadAll()

		mainframe.UndoButton:Show()
	end)
	self.timeLineImportFromNoteFrame.Copy = MLib:Button(self.timeLineImportFromNoteFrame,LR.ImportTextFromNote):Point("BOTTOM",0,30+25*8):Size(590,20):OnClick(function()
		self.timeLineImportFromNoteFrame.Edit:SetText(MRT.F:GetNote())
	end)

	options.timeLineImportFromNoteFrame.opt_spellcd = true
	self.timeLineImportFromNoteFrame.isSpellCDcheck = ELib:Check(self.timeLineImportFromNoteFrame,LR["Hide message after using a spell"],true):Tooltip(LR.HideMsgCheck):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.Import,25,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_spellcd = true
		else
			options.timeLineImportFromNoteFrame.opt_spellcd = nil
		end
	end)

	options.timeLineImportFromNoteFrame.opt_rev = true
	self.timeLineImportFromNoteFrame.durRevCheck = ELib:Check(self.timeLineImportFromNoteFrame,LR.durationReverse,true):Tooltip(LR.DurRevTooltip2):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.isSpellCDcheck,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_rev = true
		else
			options.timeLineImportFromNoteFrame.opt_rev = nil
		end
	end)

	self.timeLineImportFromNoteFrame.removeBefore = ELib:Check(self.timeLineImportFromNoteFrame,LR.RemoveBeforeExport):Tooltip(LR.RemoveBeforeExportTip):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.durRevCheck,-25,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_removebefore = true
		else
			options.timeLineImportFromNoteFrame.opt_removebefore = nil
		end
	end)
	options.timeLineImportFromNoteFrame.opt_everyplayer = true
	self.timeLineImportFromNoteFrame.forEveryPlayer = ELib:Check(self.timeLineImportFromNoteFrame,LR.ForEveryPlayer,true):Tooltip(LR.ForEveryPlayerTip):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.removeBefore,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_everyplayer = true
		else
			options.timeLineImportFromNoteFrame.opt_everyplayer = nil
		end
	end)

	self.timeLineImportFromNoteFrame.useFilterNames = ELib:Check(self.timeLineImportFromNoteFrame,LR.ImportNameAsFilter):Tooltip(LR.ImportNameAsFilterTip):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.forEveryPlayer,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_filter_names = true
		else
			options.timeLineImportFromNoteFrame.opt_filter_names = nil
		end
	end)


	self.timeLineImportFromNoteFrame.onlyMyAbility = ELib:Check(self.timeLineImportFromNoteFrame,LR.ImportNoteWordMy):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.useFilterNames,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_wordmy = true
		else
			options.timeLineImportFromNoteFrame.opt_wordmy = nil
		end
	end)

	self.timeLineImportFromNoteFrame.onlyMyNameLines = ELib:Check(self.timeLineImportFromNoteFrame,LR.ImportNoteLinesMy):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.onlyMyAbility,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_linesmy = true
		else
			options.timeLineImportFromNoteFrame.opt_linesmy = nil
		end
	end)

	self.timeLineImportFromNoteFrame.noSpellName = ELib:Check(self.timeLineImportFromNoteFrame,LR["Icon without spell name"]):Point("BOTTOMLEFT",self.timeLineImportFromNoteFrame.onlyMyNameLines,0,25):OnClick(function(self)
		if self:GetChecked() then
			options.timeLineImportFromNoteFrame.opt_nospellname = true
		else
			options.timeLineImportFromNoteFrame.opt_nospellname = nil
		end
	end)

	self.timeLineImportFromNote = MLib:Button(self.TIMELINE_TAB,LR.ImportFromNote):Point("RIGHT",self.timeLineTestRun,"LEFT",-5,0):Size(140,20):OnClick(function()
		self.timeLineImportFromNoteFrame.mainframe = options.timeLine
		self.timeLineImportFromNoteFrame:Show()
	end)
	options.timeLine.UndoButton = MLib:Button(self.TIMELINE_TAB,LR.Undo):Tooltip(LR.UndoTip):Point("TOP",self.timeLineImportFromNote,"BOTTOM",0,-4):Shown(false):Size(140,16):OnClick(function(self)
		for token in next, options.timeLine.undoimportlist.remove do
			VMRT.Reminder.data[token] = nil
		end
		for token,data in next, options.timeLine.undoimportlist.repair do
			VMRT.Reminder.data[token] = data
		end
		if module.options.Update then
			module.options.Update()
		end
		module:ReloadAll()
		self:Hide()
	end)
	-- :OnShow(function(self)
	-- 	-- if self.tmr then
	-- 	-- 	self.tmr:Cancel()
	-- 	-- end
	-- 	-- self.tmr = C_Timer.NewTimer(30,function() self:Hide() end)
	-- end,true)

	self.timeLineExportToNote = MLib:Button(options.TIMELINE_TAB,LR.ExportToNote):Point("RIGHT",self.timeLineImportFromNote,"LEFT",-5,0):Size(140,20):OnClick(function()
		local str = options.timeLine:ExportToString()

		MRT.F:Export(str,true)
	end)
	-- self.timeLineExportToNote:Hide()

	self.timeLineAdjustFL = MLib:Button(options.TIMELINE_TAB,LR.AdjustFL):Point("RIGHT",self.timeLineExportToNote,"LEFT",-5,0):Size(140,20):OnEnter(function(self)
		self.subframe:Show()
	end)

	self.timeLineAdjustFL.subframe = CreateFrame("Frame",nil,self.timeLineAdjustFL)
	self.timeLineAdjustFL.subframe:SetPoint("TOPLEFT",self.timeLineAdjustFL,"BOTTOMLEFT",-40,2)
	self.timeLineAdjustFL.subframe:SetPoint("TOPRIGHT",self.timeLineAdjustFL,"BOTTOMRIGHT",40,2)
	self.timeLineAdjustFL.subframe:SetHeight(25+25*options.timeLine.TIMELINE_ADJUST_NUM)
	self.timeLineAdjustFL.subframe:Hide()
	self.timeLineAdjustFL.subframe:SetScript("OnUpdate",function(self)
		if not self:IsMouseOver() and not self:GetParent():IsMouseOver() then
			self:Hide()
		end
	end)
	self.timeLineAdjustFL.subframe.bg = self.timeLineAdjustFL.subframe:CreateTexture(nil,"BACKGROUND")
	self.timeLineAdjustFL.subframe.bg:SetAllPoints()
	self.timeLineAdjustFL.subframe.bg:SetColorTexture(0,0,0,1)

	self.timeLineAdjustFL.subframe.timeScale = ELib:Slider(self.timeLineAdjustFL.subframe):Size(100):Point("TOP",0,-5):Range(10,200,true):SetTo(options.timeLine.TIMELINE_ADJUST):OnChange(function(self,val)
		options.timeLine.TIMELINE_ADJUST = floor(val+0.5)
		if not self.lock then
			options.timeLine:Update()
			options.timeLine:UpdateTimeText()
		end
		self.tooltipText = LR.GlobalTimeScale..": "..options.timeLine.TIMELINE_ADJUST .. "%"
		self:tooltipReload(self)
	end)
	self.timeLineAdjustFL.subframe.timeScale.tooltipText = LR.GlobalTimeScale..": "..options.timeLine.TIMELINE_ADJUST .. "%"

	for i=1,options.timeLine.TIMELINE_ADJUST_NUM do
		options.timeLine.TIMELINE_ADJUST_DATA[i] = {0,0}
		self.timeLineAdjustFL.subframe["tpos"..i] = ELib:Edit(self.timeLineAdjustFL.subframe):Size(40,20):Point("TOPLEFT",35,-20-(i-1)*25):LeftText(LR.TimeScaleT1):Tooltip(LR.TimeScaleTip1):OnChange(function(self,isUser)
			if not isUser then return end
			local t = self:GetText() or ""
			t = module:ConvertMinuteStrToNum(t)
			options.timeLine.TIMELINE_ADJUST_DATA[i][1] = t and t[1] or nil

			options.timeLine:Update()
			options.timeLine:UpdateTimeText()
		end)

		self.timeLineAdjustFL.subframe["addtime"..i] = ELib:Edit(self.timeLineAdjustFL.subframe):Size(40,20):Point("LEFT",self.timeLineAdjustFL.subframe["tpos"..i],"RIGHT",55,0):LeftText(LR.TimeScaleT2):RightText(LR.TimeScaleT3):Tooltip(LR.TimeScaleTip2):OnChange(function(self,isUser)
			if not isUser then return end
			options.timeLine.TIMELINE_ADJUST_DATA[i][2] = tonumber(self:GetText() or "")

			options.timeLine:Update()
			options.timeLine:UpdateTimeText()
		end)
	end

	self.timeLineFilterButton = MLib:DropDownButton(options.TIMELINE_TAB,FILTER,220,-1):Point("RIGHT",self.timeLineAdjustFL,"LEFT",-5,0):Size(140,20)

	function self.timeLineFilterButton:SetValue(arg1,arg2)
		ELib:DropDownClose()
		options.timeLine[arg1] = not options.timeLine[arg1]
		if not arg2 then
			VMRT.Reminder.TimelineFilter[arg1] = options.timeLine[arg1]
		else
			VMRT.Reminder[arg2] = options.timeLine[arg1]
			options.assign[arg1] = options.timeLine[arg1]
		end
		options.timeLine:Update()
	end
	function self.timeLineFilterButton:SetValueTable(arg1)
		ELib:DropDownClose()
		if options.timeLine[arg1] then
			options.timeLine[arg1] = nil
		elseif arg1 == "FILTER_SPELL" then
			local filter = {}
			local data = options.timeLine.Data[options.timeLine.BOSS_ID]
			for _,e in next, (data.m and data or {data}) do
				if type(e) == "table" then
					for k in next, e do
						filter[k] = true
					end
				end
			end
			options.timeLine[arg1] = filter
		end
		options.timeLine:Update()
	end
	self.timeLineFilterButton.List = {
		{
			text = LR.FilterCasts,
			checkable = true,
			func = self.timeLineFilterButton.SetValue,
			arg1 = "FILTER_CAST",
			alter = true,
		},{
			text = LR.FilterAuras,
			checkable = true,
			func = self.timeLineFilterButton.SetValue,
			arg1 = "FILTER_AURA",
			alter = true,
		},{
			text = LR.PresetFilter,
			checkable = true,
			func = self.timeLineFilterButton.SetValueTable,
			arg1 = "FILTER_SPELL",
			hidF = function() if options.timeLine.Data[options.timeLine.BOSS_ID] and options.timeLine.CUSTOM_TIMELINE and options.timeLine.CUSTOM_TIMELINE.fightData then return true end end,
		},{
			text = " ",
			isTitle = true,
		},{
			text = LR.Reminders,
			isTitle = true,
		},{
			text = LR.OnlyMine,
			checkable = true,
			func = self.timeLineFilterButton.SetValue,
			arg1 = "FILTER_REM_ONLYMY",
			arg2 = "OptAssigOnlyMy"
		},{
			text = LR.RepeatableFilter,
			tooltip = LR.RepeatableFilterTip,
			checkable = true,
			func = self.timeLineFilterButton.SetValue,
			arg1 = "FILTER_SPELL_REP",
			arg2 = "OptAssigFSpellsRep",
			alter = true,
		},{
			text = LR["Simulate note timers"],
			checkable = true,
			func = self.timeLineFilterButton.SetValue,
			arg1 = "FILTER_NOTE",
			arg2 = "OptAssigFNote",
			tooltip = LR.SimNoteTimersTip,
		},
	}
	function self.timeLineFilterButton:PreUpdate()
		for i=1,#self.List do
			local line = self.List[i]
			line.checkState = (line.alter and not options.timeLine[line.arg1]) or (not line.alter and options.timeLine[line.arg1])
			if line.hidF then
				line.isHidden = not line.hidF()
			end
		end
	end

	options.timeLine.frame = ELib:ScrollFrame(options.TIMELINE_TAB):Size(780,494):Height(494):AddHorizontal(true):Width(1000)
	ELib:Border(options.timeLine.frame,0)
	options.timeLine.frame.headers = ELib:ScrollFrame(options.TIMELINE_TAB):Point("TOPLEFT",0,-50):Size(220,494):Height(474)
	ELib:Border(options.timeLine.frame.headers,0)
	options.timeLine.frame:Point("TOPLEFT",options.timeLine.frame.headers,"TOPRIGHT",0,0)
	options.timeLine.frame.D = CreateFrame("Frame",nil,options.timeLine.frame.C)
	options.timeLine.frame.D:SetAllPoints()
	options.timeLine.frame.D:SetFrameLevel(8000)

	options.timeLine.frame.ScrollBar:Hide()
	options.timeLine.frame.headers.ScrollBar:NewPoint("TOPLEFT",3,-3):Point("BOTTOMLEFT",3,3)
	options.timeLine.frame.headers.ScrollBar:Hide()

	options.timeLine.frame.lines = {}
	options.timeLine.frame.buttons = {}
	options.timeLine.frame.pcursors = {}

	function options.timeLine:UpdateScale(val,forMid)
		local x,y = MRT.F.GetCursorPos(self.frame)
		if forMid then x = self.frame:GetWidth() / 2 end
		local htime = self:GetTimeFromPos(x + self.frame:GetHorizontalScroll())

		self.TIMELINE_SCALE = val
		self:Update()
		self:UpdateTimeText()

		local htime2 = self:GetTimeFromPos(x + self.frame:GetHorizontalScroll())

		local newVal = self.frame.ScrollBarHorizontal:GetValue() - self:GetPosFromTime(htime2-htime)
		local min,max = self.frame.ScrollBarHorizontal:GetMinMaxValues()
		if newVal < min then newVal = min end
		if newVal > max then newVal = max end
		self.frame.ScrollBarHorizontal:SetValue(newVal)

		self.frame.zoomSlider:SetTo(self.TIMELINE_SCALE)
	end

	options.timeLine.frame.zoomSlider = ELib:Slider(options.timeLine.frame,"",true):Size(40):Point("BOTTOMRIGHT",-5,-15):Range(50,110):SetTo(options.timeLine.TIMELINE_SCALE):OnChange(function(self,val)
		if self.lock then return end
		self.lock = true
		options.timeLine:UpdateScale( floor(val+0.5),true )
		self.lock = nil
	end):OnEnter(function() options.timeLine.HideCursor = true end):OnLeave(function() options.timeLine.HideCursor = false end)

	options.timeLine.frame:SetScript("OnMouseWheel", function(self,delta)
		options.timeLine:UpdateScale( options.timeLine.TIMELINE_SCALE - delta )
	end)

	options.timeLine.frame.headers:SetScript("OnVerticalScroll", function(self)
		options.timeLine.frame:SetVerticalScroll( self:GetVerticalScroll() )
	end)

	options.timeLine.frame.timeLeft = ELib:Text(options.TIMELINE_TAB,"0:00",14):Point("BOTTOMLEFT",options.timeLine.frame,"TOPLEFT",0,2)
	options.timeLine.frame.timeRight = ELib:Text(options.TIMELINE_TAB,"1:00",14):Point("BOTTOMRIGHT",options.timeLine.frame,"TOPRIGHT",0,2):Right()

	options.timeLine.frame.cursor = options.timeLine.frame.D:CreateTexture(nil,"BACKGROUND")
	options.timeLine.frame.cursor:SetWidth(2)
	options.timeLine.frame.cursor:SetPoint("BOTTOM",0,0)
	options.timeLine.frame.cursor:SetColorTexture(1,1,1,.7)
	options.timeLine.frame.cursor:Hide()

	options.timeLine.frame.cursorH = options.timeLine.frame.C:CreateTexture(nil,"BACKGROUND")
	options.timeLine.frame.cursorH:SetSize(1000,2)
	options.timeLine.frame.cursorH:SetColorTexture(.2,.2,.2,1)

	options.timeLine.frame.cursorHT2 = options.TIMELINE_TAB:CreateTexture(nil,"BACKGROUND")
	options.timeLine.frame.cursorHT2:SetHeight(2)
	options.timeLine.frame.cursorHT2:SetPoint("LEFT",options,0,0)
	options.timeLine.frame.cursorHT2:SetPoint("RIGHT",options,0,0)
	options.timeLine.frame.cursorHT2:SetPoint("BOTTOM",options.timeLine.frame,"TOP",0,0)
	options.timeLine.frame.cursorHT2:SetColorTexture(.2,.2,.2,1)

	options.timeLine.frame.runLine = options.timeLine.frame.D:CreateTexture(nil,"ARTWORK",nil,3)
	options.timeLine.frame.runLine:SetWidth(2)
	options.timeLine.frame.runLine:SetPoint("TOP",options.timeLine.frame.cursorHT2,"BOTTOM",0,0)
	options.timeLine.frame.runLine:SetPoint("BOTTOM",options.timeLine.frame.cursorH,"TOP",0,0)
	options.timeLine.frame.runLine:SetColorTexture(1,0,0,1)
	options.timeLine.frame.runLine:Hide()

	options.timeLine.frame.bg = options.timeLine.frame.C:CreateTexture(nil,"BACKGROUND",nil,-8)
	options.timeLine.frame.bg:SetColorTexture(23/255, 31/255, 33/255, 1)
	options.timeLine.frame.bg:SetPoint("TOPLEFT",0,0)
	--options.timeLine.frame.bg:SetPoint("BOTTOMRIGHT",options.timeLine.frame.cursorH,"TOPRIGHT",0,0)
	--options.timeLine.frame.bg:SetPoint("BOTTOMRIGHT",0,0)
	options.timeLine.frame.bg:SetPoint("BOTTOM",0,0)
	options.timeLine.frame.bg:SetPoint("RIGHT",options,0,0)

	options.timeLine.frame.bg2 = options.timeLine.frame.C:CreateTexture(nil,"BACKGROUND",nil,-7)
	options.timeLine.frame.bg2:SetPoint("LEFT",options.timeLine.frame.bg,0,0)
	options.timeLine.frame.bg2:SetPoint("RIGHT",options.timeLine.frame.bg,0,0)
	options.timeLine.frame.bg2:SetPoint("TOP",options.timeLine.frame.cursorHT2,"BOTTOM",0,0)
	options.timeLine.frame.bg2:SetPoint("BOTTOM",options.timeLine.frame.cursorH,"TOP",0,0)
	options.timeLine.frame.bg2:SetColorTexture(1,1,1, 1)
	options.timeLine.frame.bg2:SetGradient("VERTICAL",CreateColor(0,0,0,.2), CreateColor(0,0,0,0))


	options.timeLine.frame.timeCursor = ELib:Text(options.TIMELINE_TAB,"1:00",14):Point("CENTER",options.timeLine.frame.cursor,"TOP",0,0):Point("BOTTOM",options.timeLine.frame,"TOP",0,2):Shown(false)

	options.timeLine.frame:SetScript("OnUpdate",function(self)
		local x,y = MRT.F.GetCursorPos(self)

		if self.saved_x and self.saved_y then
			if abs(x - self.saved_x) > 5 then
				local newVal = self.saved_scroll - (x - self.saved_x)
				local min,max = self.ScrollBarHorizontal:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBarHorizontal:SetValue(newVal)

				self.moveSpotted = true
			end
			if self.headers.ScrollBar:IsShown() and abs(y - self.saved_y) > 5 then
				local newVal = self.saved_scroll_v - (y - self.saved_y)
				local min,max = self.headers.ScrollBar:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.headers.ScrollBar:SetValue(newVal)

				self.moveSpotted = true
			end
		end

		if self:IsMouseOver() and (not options.quickSetupFrame:IsShown() or not options.quickSetupFrame:IsMouseOver()) and not self.moveSpotted then
			if x <= 40 and self.timeLeft:IsShown() then
				self.timeLeft:Hide()
			elseif x > 40 and not self.timeLeft:IsShown() then
				self.timeLeft:Show()
			end

			if x >= self:GetWidth()-40 and self.timeRight:IsShown() then
				self.timeRight:Hide()
			elseif x < self:GetWidth()-40 and not self.timeRight:IsShown() then
				self.timeRight:Show()
			end

			x = x + self:GetHorizontalScroll()
			self.cursor:SetPoint("TOPLEFT",x,0)

			x = options.timeLine:GetTimeFromPos(x)
			self.timeCursor:SetText(module:FormatTime(x))
			if not self.cursor:IsShown() then
				self.cursor:Show()
				self.timeCursor:Show()
			end
		elseif self.cursor:IsShown() then
			self.cursor:Hide()
			self.timeCursor:Hide()
			if not self.timeLeft:IsShown() then
				self.timeLeft:Show()
			end
			if not self.timeRight:IsShown() then
				self.timeRight:Show()
			end
		end

		if options.timeLine.HideCursor and self.cursor:IsShown() then
			self.cursor:Hide()
		end

		if module.db.simrun then
			local x = options.timeLine:GetPosFromTime(module.db.simrun)
			self.runLine:SetPoint("LEFT",x,0)
			if not self.runLine:IsShown() then
				self.runLine:Show()
			end
		elseif self.runLine:IsShown() then
			self.runLine:Hide()
		end
	end)

	options.timeLine.frame:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll = self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.headers.ScrollBar:GetValue()
		self.moveSpotted = nil

	end)

	options.timeLine.frame:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil
		if self.moveSpotted then
			self.moveSpotted = nil
			return
		end

		local x,y = MRT.F.GetCursorPos(self)
		x = x + self:GetHorizontalScroll()
		y = y + self:GetVerticalScroll()
		options.timeLine:ProcessClick(x, y, button)
	end)

	options.timeLine.frame.HighlighSpellLine = function(self,id,show)
		for i=1,#self.lines do
			local line = self.lines[i]
			if (line.header.spell == id and show) or not show then
				line:SetAlpha(1)
			else
				line:SetAlpha(.3)
			end
		end
	end

	function options.timeLine:UpdateTimeText()
		local x = self:GetTimeFromPos(self.frame:GetHorizontalScroll())
		self.frame.timeLeft:SetText(module:FormatTime(x))

		local x2 = self:GetTimeFromPos(self.frame:GetHorizontalScroll() + self.frame:GetWidth())
		self.frame.timeRight:SetText(module:FormatTime(x2))

		local p,s = self:GetPosFromTime(30), self:GetPosFromTime(x)
		local c = 0
		for i=ceil(s/p)*p,s + self.frame:GetWidth(),p do
			c = c + 1
			local tc = self.frame.timeCursor[c]
			if not tc then
				tc = options.TIMELINE_TAB:CreateTexture(nil,"BACKGROUND")
				self.frame.timeCursor[c] = tc
				tc:SetSize(2,4)
				tc:SetPoint("BOTTOM",self.frame.cursorHT2,"TOP",0,0)
				tc:SetColorTexture(.2,.2,.2,1)
				tc:Hide()
			end
			tc:SetPoint("LEFT",self.frame,i - s,0)
			tc:Show()
		end
		for i=c+1,#self.frame.timeCursor do
			self.frame.timeCursor[i]:Hide()
		end

	end
	options.timeLine.frame:SetScript("OnScrollRangeChanged",function(self)
		options.timeLine:UpdateTimeText()
	end)
	options.timeLine.frame:SetScript("OnHorizontalScroll",function(self)
		options.timeLine:UpdateTimeText()
	end)

	options.timeLine.frame.bigBossButtons = CreateFrame("Button",nil,options.timeLine.frame)
	options.timeLine.frame.bigBossButtons:SetPoint("TOPLEFT",options.timeLine.frame.headers,0,0)
	options.timeLine.frame.bigBossButtons:SetPoint("BOTTOMRIGHT",options,0,0)
	options.timeLine.frame.bigBossButtons:SetFrameLevel(9000)
	options.timeLine.frame.bigBossButtons:SetFrameStrata("DIALOG")

	options.timeLine.frame.bigBossButtons.bg = options.timeLine.frame.bigBossButtons:CreateTexture(nil,"BACKGROUND",nil,-8)
	options.timeLine.frame.bigBossButtons.bg:SetColorTexture(0,0,0, 1)
	options.timeLine.frame.bigBossButtons.bg:SetAllPoints()

	options.timeLine.frame.bigBossButtons.buttons = {}
	function options.timeLine.frame.bigBossButtons:Reset()
		for i=1,#self.buttons do
			self.buttons[i]:Hide()
		end
	end
	function options.timeLine.frame.bigBossButtons:Repos(t)
		local SIZE_W = 200 * (t.mini and 0.75 or 1)
		local SIZE_H = 200 * (t.mini and 0.75 or 1)
		for i=1,#t do
			for j=1,#t[i] do
				local button = self.buttons[ t[i][j] ]
				button:ClearAllPoints()
				button:SetPoint("CENTER",-SIZE_W*(#t[i]-1)/2+(j-1)*SIZE_W,SIZE_H*(#t-1)/2-(i-1)*SIZE_H)
			end
		end
	end

	function options.timeLine.frame.bigBossButtons.Util_BottonOnEnter(self)
		self.text:Color(1,1,0,1)
	end
	function options.timeLine.frame.bigBossButtons.Util_BottonOnLeave(self)
		self.text:Color()
	end
	function options.timeLine.frame.bigBossButtons.Util_BottonOnClick(self)
		self.click()
		options.timeLine.frame.bigBossButtons:Hide()
	end

	function options.timeLine.frame.bigBossButtons:Add(encounterID, clickFunc)
		local button
		for i=1,#self.buttons do
			if not self.buttons[i]:IsShown() then
				button = self.buttons[i]
				break
			end
		end
		if not button then
			button = CreateFrame("Button",nil,self)
			self.buttons[#self.buttons+1] = button

			button._i = #self.buttons

			button:SetSize(150,100)

			button.bg = button:CreateTexture()
			button.bg:SetSize(128,64)
			button.bg:SetPoint("CENTER",0,20)

			button.text = ELib:Text(button,"",16):Point("TOP",button.bg,"BOTTOM",0,-5):Color():Center()
			button.text:SetWidth(150)

			button:SetScript("OnEnter",self.Util_BottonOnEnter)
			button:SetScript("OnLeave",self.Util_BottonOnLeave)
			button:SetScript("OnClick",self.Util_BottonOnClick)
		end

		local bossImg = AddonDB:GetBossPortrait(encounterID)

		button.text:SetText(LR.boss_name[encounterID])

		button.bg:SetTexture(bossImg)
		button.click = clickFunc

		button:Show()

		local tr
		if button._i <= 3 then
			tr = {{}}
			for i=1,button._i do tinsert(tr[1],i) end
		elseif button._i <= 8 then
			tr = {{},{}}
			local m = ceil(button._i / 2)
			for i=1,button._i do tinsert(tr[floor((i-1)/m)+1],i) end
		elseif button._i <= 12 then
			tr = {{},{},{}}
			local m = ceil(button._i / 3)
			for i=1,button._i do tinsert(tr[floor((i-1)/m)+1],i) end
		elseif button._i <= 16 then
			tr = {{},{},{},{},mini=true}
			local m = ceil(button._i / 4)
			for i=1,button._i do tinsert(tr[floor((i-1)/m)+1],i) end
		end
		self:Repos(tr)
	end

	options.timeLine.frame.initSpinner = MLib:LoadingSpinner(options.timeLine.frame):Size(60, 60):Point("CENTER", 0, 0)

	self.quickSetupFrame = ELib:Popup(" "):Size(510,470)
	-- ELib:Border(self.quickSetupFrame,1,.4,.4,.4,.9)
	ELib:Border(self.quickSetupFrame,1,.24,.25,.30,1,nil,3)
	self.quickSetupFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)
	self.quickSetupFrame.border:Hide()

	self.quickSetupFrame.titleText = ELib:Text(self.quickSetupFrame,LR.QuickSetup,12):Point("TOP",0,-10):Top():Center():Color():Size(490,36)

	function options:AddSpellCDCheckTrigger(data)
		local msg = data.msg
		if msg then
			local spellID = msg:match("^{spell:(%d+)}")
			if spellID then
				data.triggers[2] = {
					event = 13,
					spellID = tonumber(spellID),
					invert = true,
				}
				data.hideTextChanged = true

				return true
			end
		end
	end

	self.quickSetupFrame.saveButton = MLib:Button(self.quickSetupFrame,LR.save):Point("BOTTOMRIGHT",self.quickSetupFrame,"BOTTOM",-5,10):Size(200,20):Tooltip(LR["Hold shift to save and send reminder"]):OnClick(function()
		local data = self.quickSetupFrame.data
		self.quickSetupFrame:Hide()
		local token = data.token or module:GenerateToken()
		self.quickSetupFrame.data.token = token

		local removeTrigger2 = true
		if data.tmp_tl_cd then
			if options:AddSpellCDCheckTrigger(data) then
				removeTrigger2 = false
			end
		end
		if removeTrigger2 and data.triggers[2] and data.triggers[2].event == 13 and data.hideTextChanged then
			tremove(data.triggers, 2)
			data.hideTextChanged = nil
		end

		GenerateReminderName(data)

		local dataChanged = true
		if VMRT.Reminder.data[token] then
			dataChanged = MRT.F.table_compare(VMRT.Reminder.data[token],data) ~= 1
		end

		if dataChanged then
			data.notSync = true
		end

		module:AddReminder(token,data)
		if module.options.Update then
			module.options.Update()
		end
		module:ReloadAll()

		if IsShiftKeyDown() then
			module:Sync(false,nil,nil,token)
		end

		options.quickSetupFrame.prev = options.quickSetupFrame.data
		options.quickSetupFrame:Hide()
	end)

	self.quickSetupFrame.removeButton = MLib:Button(self.quickSetupFrame,LR.Listdelete):Point("BOTTOMLEFT",self.quickSetupFrame,"BOTTOM",5,10):Size(200,20):OnClick(function()
		local token = self.quickSetupFrame.data.token
		local data = VMRT.Reminder.data[token]
		if data then
			module:DeleteReminder(data)
		end
		self.quickSetupFrame:Hide()
	end)

	self.quickSetupFrame.copyButton = MLib:Button(self.quickSetupFrame,LR.CopyPrev):Point("BOTTOM",0,35):Size(410,20):OnClick(function()
		local prev = self.quickSetupFrame.prev
		if not prev then
			return
		end
		local data = options.quickSetupFrame.data

		data.duration = prev.duration
		data.durrev = prev.durrev
		data.msg = prev.msg
		data.countdown = prev.countdown
		data.voiceCountdown = prev.voiceCountdown
		data.sound = prev.sound
		data.tts = prev.tts
		data.glow = prev.glow
		data.tmp_tl_cd = prev.tmp_tl_cd

		data.units = prev.units
		data.classes = prev.classes
		data.roles = prev.roles

		options.quickSetupFrame:Update(data)
	end)

	self.quickSetupFrame.quickFilter = ELib:DropDown(self.quickSetupFrame,220,-1):AddText("|cffffd100"..LR.ShowFor):Size(270):Point("TOPLEFT",180,-50)
	do
		self.quickSetupFrame.quickFilter.List[#self.quickSetupFrame.quickFilter.List+1] = {
			text = LR.AllPlayers,
			func = function()
				options.quickSetupFrame.data.roles = nil
				options.quickSetupFrame.data.units = nil
				options.quickSetupFrame.data.classes = nil
				options.quickSetupFrame.data.reversed = nil
				options.quickSetupFrame.data.groups = nil

				ELib:DropDownClose()
				self.quickSetupFrame.quickFilter:Update()
			end
		}

		self.quickSetupFrame.quickFilter.List[#self.quickSetupFrame.quickFilter.List+1] = {
			text = LR.PlayerNames,
			func = function()
				options.quickSetupFrame.quickFilter:SetText(LR.PlayerNames)
				options.quickSetupFrame.playersEdit:SetText("")
				options.quickSetupFrame.playersEdit:ExtraShow()
				ELib:DropDownClose()
			end,
		}
		local PLAYER = (MRT.F.utf8sub(PLAYER, 1, 1)):upper() .. MRT.F.utf8sub(PLAYER, 2)
		self.quickSetupFrame.quickFilter.List[#self.quickSetupFrame.quickFilter.List+1] = {
			text = PLAYER,
			func = function()
				local data = options.quickSetupFrame.data
				data.roles = nil
				data.classes = nil
				data.groups = nil
				data.units = "#" .. UnitName'player' .. "#"
				-- options.quickSetupFrame.data.allPlayers = nil
				options.quickSetupFrame.quickFilter:SetText(PLAYER)
				options.quickSetupFrame.playersEdit:SetText(UnitName'player')
				options.quickSetupFrame.playersEdit:ExtraShow()
				ELib:DropDownClose()
			end,
		}

		local listNow = {}
		self.quickSetupFrame.quickFilter.List[#self.quickSetupFrame.quickFilter.List+1] = {
			text = LR["rrole"],
			subMenu = listNow,
		}
		for i=1,#module.datas.rolesList do
			local token = module.datas.rolesList[i][3]
			listNow[#listNow+1] = {
				text = module.datas.rolesList[i][2],
				func = function()
					options.quickSetupFrame.data.units = nil
					options.quickSetupFrame.data.classes = nil
					options.quickSetupFrame.data.reversed = nil
					options.quickSetupFrame.data.groups = nil

					options.quickSetupFrame.data.roles = "#" .. token .. "#"
					ELib:DropDownClose()
					self.quickSetupFrame.quickFilter:Update()
				end
			}
		end

		local listNow = {}
		self.quickSetupFrame.quickFilter.List[#self.quickSetupFrame.quickFilter.List+1] = {
			text = CLASS,
			subMenu = listNow,
		}
		for i=1,#MRT.GDB.ClassList do
			local class = MRT.GDB.ClassList[i]
			listNow[#listNow+1] = {
				text = (RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr and "|c"..RAID_CLASS_COLORS[class].colorStr or "")..L.classLocalizate[class],
				func = function()
					options.quickSetupFrame.data.roles = nil
					options.quickSetupFrame.data.units = nil
					options.quickSetupFrame.data.reversed = nil
					options.quickSetupFrame.data.groups = nil

					options.quickSetupFrame.data.classes = "#" .. class .. "#"
					ELib:DropDownClose()
					self.quickSetupFrame.quickFilter:Update()
				end
			}
		end

		self.quickSetupFrame.quickFilter.Update = function(self)
			options.quickSetupFrame.playersEdit:ExtraShow(true)
			local data = options.quickSetupFrame.data
			if not (data.roles or data.units or data.reversed or data.groups or data.classes) then
				self:SetText(LR.AllPlayers)
				return
			end

			if data.reversed or data.groups or data.notepat then
				self:SetText("Complex")
				return
			end

			local text = {}

			if data.units then
				text[#text+1] = LR.PlayerNames
				local str = ""
				for unit in string.gmatch(data.units, "[^#]+") do
					str = str .. unit .. " "
				end
				options.quickSetupFrame.playersEdit:SetText(str:trim())
				options.quickSetupFrame.playersEdit:ExtraShow()
			end

			if data.roles then
				local token = data.roles:match("[^#]+")
				for i=1,#module.datas.rolesList do
					if module.datas.rolesList[i][3] == token then
						text[#text+1] = module.datas.rolesList[i][2]
					end
				end
			end
			if data.classes then
				local token = data.classes:match("[^#]+")
				for i=1,#MRT.GDB.ClassList do
					if MRT.GDB.ClassList[i] == token then
						text[#text+1] = (RAID_CLASS_COLORS[token] and RAID_CLASS_COLORS[token].colorStr and "|c"..RAID_CLASS_COLORS[token].colorStr or "")..L.classLocalizate[token]
					end
				end
			end

			self:SetText(table.concat(text,", "))
		end
	end

	self.quickSetupFrame.playersEdit = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.quickFilter,"BOTTOMLEFT",0,-5+25):Shown(false):LeftText(LR.PlayerNames..":"):Tooltip(LR.PlayerNamesTip):OnChange(function(self,isUser)
		if not isUser then return end
		local data = options.quickSetupFrame.data

		local r = "#"
		local tmp = {}
		local allUnits = {strsplit(" ",self:GetText())}
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
		data.units = r

	end)
	function self.quickSetupFrame.playersEdit:ExtraShow(isHide)
		if isHide then
			self:Point("TOPLEFT",options.quickSetupFrame.quickFilter,"BOTTOMLEFT",0,-5+25):Shown(false)
		else
			self:Point("TOPLEFT",options.quickSetupFrame.quickFilter,"BOTTOMLEFT",0,-5):Shown(true)
		end
	end

	self.quickSetupFrame.spellDD = ELib:DropDown(self.quickSetupFrame,220,-1):AddText("|cffffd100"..LR.Spell..":"):Size(270):Point("TOPLEFT",self.quickSetupFrame.playersEdit,"BOTTOMLEFT",0,-5)

	function self.quickSetupFrame.spellDD:ModText(isFromEdit)
		local msg = options.quickSetupFrame.msgEdit:GetText() or ""
		local spell = options.quickSetupFrame.spellDD.spell

		if msg:trim() == "" and spell and not isFromEdit then
			local spellName = GetSpellName(spell or 0)
			if spellName then
				msg = spellName
			end
		end

		if spell then
			msg = "{spell:"..spell.."} "..msg
		end

		if msg:trim() == "" then msg = nil end
		options.quickSetupFrame.data.msg = msg

		local showedText = msg and msg:gsub("^{spell:%d+} *","",1) or ""
		if showedText ~= options.quickSetupFrame.msgEdit:GetText() then
			options.quickSetupFrame.msgEdit:SetText(showedText)
		end
	end

	self.quickSetupFrame.spellDD.SetValue = function(_,arg1)
		local isCustom
		if arg1 == -1 then
			arg1 = nil
			options.quickSetupFrame.spellDD_extra:Point("TOPLEFT",options.quickSetupFrame.spellDD,"BOTTOMLEFT",0,-5):Shown(true)
			self.quickSetupFrame.spellDD:SetText(LR.Custom)
			local spell = (options.quickSetupFrame.data.msg or ""):match("{spell:(%d+)}")
			options.quickSetupFrame.spellDD_extra:SetText(spell or "")
			isCustom = true
		else
			options.quickSetupFrame.spellDD_extra:Point("TOPLEFT",options.quickSetupFrame.spellDD,"BOTTOMLEFT",0,-5+25):Shown(false)
		end
		self.quickSetupFrame.spellDD.spell = arg1
		if arg1 then
			local spellName = GetSpellName(arg1)
			local spellTexture = GetSpellTexture(arg1)
			self.quickSetupFrame.spellDD:SetText( (spellTexture and "|T"..spellTexture..":20|t " or "")..(spellName or ("spell:"..arg1)) )
		elseif not isCustom then
			self.quickSetupFrame.spellDD:SetText("-")
		end
		options.quickSetupFrame.spellDD:ModText()
		options.quickSetupFrame.msgEdit:UpdateColorBorder()
		ELib:DropDownClose()
	end
	self.quickSetupFrame.cooldownCheck = ELib:Check(self.quickSetupFrame,""):Tooltip(LR.HideMsgCheck):Point("LEFT",self.quickSetupFrame.spellDD,"RIGHT",5,0):OnClick(function(self)
		if self:GetChecked() then
			options.quickSetupFrame.data.tmp_tl_cd = true
		else
			options.quickSetupFrame.data.tmp_tl_cd = nil
		end
	end)
	do
		local cd_module = MRT.A.ExCD2
		local List = self.quickSetupFrame.spellDD.List
		for i=1,#cd_module.db.AllSpells do
			local line = cd_module.db.AllSpells[i]
			local class = strsplit(",",line[2] or "")
			if class and MRT.GDB.ClassID[class] then
				local l
				for j=1,#List do
					if List[j].arg1 == class then
						l = List[j].subMenu
						break
					end
				end
				if not l then
					l = {
						text = L.classLocalizate[class],
						colorCode = (RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr and "|c"..RAID_CLASS_COLORS[class].colorStr or ""),
						arg1 = class,
						subMenu = {},
						Lines = 15,
					}
					List[#List+1] = l
					l = l.subMenu
				end
				local name = GetSpellName(line[1]) or ("spell:"..line[1])
				local texture = GetSpellTexture(line[1])

				for j=4,8 do
					if line[j] then
						local specSubMenu
						if j > 4 then
							for k=1,#l do
								if l[k].s == j then
									specSubMenu = l[k]
									break
								end
							end
							if not specSubMenu then
								local specID = MRT.GDB.ClassSpecializationList[class] and MRT.GDB.ClassSpecializationList[class][j-4]
								specSubMenu = {
									text = specID and L.specLocalizate[ cd_module.db.specInLocalizate[specID] ] or "Spec "..j,
									s = j,
									subMenu = {},
									arg2 = "aaa"..string.char(64+j),
									icon = specID and MRT.GDB.ClassSpecializationIcons[specID],
								}
								l[#l+1] = specSubMenu
							end
							specSubMenu = specSubMenu.subMenu
						else
							specSubMenu = l
						end

						specSubMenu[#specSubMenu+1] = {
							text = (texture and "|T"..texture..":20|t " or "")..name,
							arg1 = line[1],
							arg2 = name,
							func = self.quickSetupFrame.spellDD.SetValue,
						}
					end
				end
			end
		end
		for i=1,#List do
			if List[i].subMenu then
				for j=1,#List[i].subMenu do
					if List[i].subMenu[j].subMenu then
						sort(List[i].subMenu[j].subMenu,function(a,b) return a.arg2 < b.arg2 end)
					end
				end
				sort(List[i].subMenu,function(a,b) return a.arg2 < b.arg2 end)
			end
		end
		List[#List+1] = {
			text = LR.Boss2,
			subMenu = {},
		}
		List[#List+1] = {
			text = LR.Custom,
			arg1 = -1,
			func = self.quickSetupFrame.spellDD.SetValue,
		}
		List[#List+1] = {
			text = "-",
			arg1 = nil,
			func = self.quickSetupFrame.spellDD.SetValue,
		}
		function self.quickSetupFrame.spellDD:PreUpdate()
			for i=1,#self.List do
				if self.List[i].text == LR.Boss2 then
					local subMenu = self.List[i].subMenu
					wipe(subMenu)

					if options.timeLine.timeLineData then
						for k in next, options.timeLine.timeLineData do
							if type(k) == "number" then
								local name,_,texture = GetSpellInfo(k)
								if name then
									subMenu[#subMenu+1] = {
										text = (texture and "|T"..texture..":20|t " or "")..name,
										arg1 = k,
										arg2 = name,
										func = self.SetValue,
									}
								end
							end
						end
						sort(subMenu,function(a,b) return a.arg2 < b.arg2 end)
						self.List[i].isHidden = false
					else
						self.List[i].isHidden = true
					end

					break
				end
			end
		end
	end
	self.quickSetupFrame.spellDD_extra = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.spellDD,"BOTTOMLEFT",0,-5+25):LeftText(LR.CustomSpell):Shown(false):OnChange(function(self,isUser)
		local text = self:GetText():trim()
		if text == "" then text = nil end
		local texture = GetSpellTexture(text or "")
		self:InsideIcon(texture)
		if not isUser then return end
		if texture then
			options.quickSetupFrame.spellDD.spell = text
		else
			options.quickSetupFrame.spellDD.spell = nil
		end
		options.quickSetupFrame.spellDD:ModText(true)
		options.quickSetupFrame.msgEdit:UpdateColorBorder()
	end)
	function self.quickSetupFrame.spellDD_extra:ExtraHide()
		options.quickSetupFrame.spellDD_extra:Point("TOPLEFT",options.quickSetupFrame.spellDD,"BOTTOMLEFT",0,-5+25):Shown(false)
	end

	self.quickSetupFrame.msgEdit = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.spellDD_extra,"BOTTOMLEFT",0,-5):LeftText(LR.msg):OnChange(function(self,isUser)
		local text = self:GetText():trim()
		if text == "" then
			text = nil
		end
		self:UpdateColorBorder()
		if not isUser then return end
		options.quickSetupFrame.spellDD:ModText(true)
		self:UpdateColorBorder()
	end)
	function self.quickSetupFrame.msgEdit:UpdateColorBorder()
		local text = options.quickSetupFrame.data.msg
		if text and text:trim() == "" then text = nil end
		if not text and not options.quickSetupFrame.data.tmp_tl_glow then self:ColorBorder(true) else self:ColorBorder(false) end
	end

	self.quickSetupFrame.msgEdit.colorButton = CreateFrame("Button",nil,self.quickSetupFrame.msgEdit)
	self.quickSetupFrame.msgEdit.colorButton:SetPoint("LEFT", self.quickSetupFrame.msgEdit, "RIGHT", 3, 0)
	self.quickSetupFrame.msgEdit.colorButton:SetSize(24,24)
	self.quickSetupFrame.msgEdit.colorButton:SetScript("OnClick",function(self)
		if ColorPickerFrame.SetupColorPickerAndShow then
			local info = {}
			info.r, info.g, info.b = 1,1,1
			if options.quickSetupFrame.msgEdit then
				local at,rt,gt,bt = options.quickSetupFrame.msgEdit:GetText():match("|c(..)(..)(..)(..)")
				if bt then
					info.r, info.g, info.b = tonumber(rt,16)/255,tonumber(gt,16)/255,tonumber(bt,16)/255
				end
			end
			info.opacity = 1
			info.hasOpacity = false
			info.swatchFunc = function()
				local btn = ColorPickerFrame.Footer and ColorPickerFrame.Footer.OkayButton or ColorPickerOkayButton
				if not MouseIsOver(btn) or IsMouseButtonDown() then return end
				local r,g,b = ColorPickerFrame:GetColorRGB()
				local code = format("%02x%02x%02x",r*255,g*255,b*255)
				local hlstart,hlend = options.quickSetupFrame.msgEdit:GetTextHighlight()
				if hlstart == hlend then
					if options.quickSetupFrame.msgEdit:GetText():find("||cff") then
						options.quickSetupFrame.msgEdit:SetText( options.quickSetupFrame.msgEdit:GetText():gsub("||cff......","||cff"..code) )
					else
						options.quickSetupFrame.msgEdit:SetText( "||cff"..code..options.quickSetupFrame.msgEdit:GetText().."||r" )
					end
				else
					local text = options.quickSetupFrame.msgEdit:GetText()
					text = text:sub(1, hlend) .. "||r" .. text:sub(hlend+1)
					text = text:sub(1, hlstart) .. "||cff"..code .. text:sub(hlstart+1)
					options.quickSetupFrame.msgEdit:SetText( text )
				end
				options.quickSetupFrame.msgEdit:GetScript("OnTextChanged")(options.quickSetupFrame.msgEdit,true)
			end
			info.cancelFunc = function()
				local newR, newG, newB, newA = ColorPickerFrame:GetPreviousValues()
			end
			ColorPickerFrame:SetupColorPickerAndShow(info)
		end
	end)
	self.quickSetupFrame.msgEdit.colorButton:SetScript("OnEnter",function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(LR["Text color"])
		GameTooltip:Show()
	end)
	self.quickSetupFrame.msgEdit.colorButton:SetScript("OnLeave",function(self)
		GameTooltip_Hide()
	end)
	self.quickSetupFrame.msgEdit.colorButton.Texture = self.quickSetupFrame.msgEdit.colorButton:CreateTexture(nil,"ARTWORK")
	self.quickSetupFrame.msgEdit.colorButton.Texture:SetPoint("CENTER")
	self.quickSetupFrame.msgEdit.colorButton.Texture:SetSize(20,20)
	self.quickSetupFrame.msgEdit.colorButton.Texture:SetTexture([[Interface\AddOns\MRT\media\wheeltexture]])


	self.quickSetupFrame.eventDD = ELib:DropDown(self.quickSetupFrame,220,-1):AddText("|cffffd100"..(LR.Trigger):trim()..":"):Size(270):Point("TOPLEFT",self.quickSetupFrame.msgEdit,"BOTTOMLEFT",0,-5)
	do
		self.quickSetupFrame.eventDD.SliderHidden = true

		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C[20].lname,
			func = function()
				if options.quickSetupFrame.mainframe.SAVED_VAR_X then
					local t=floor(options.quickSetupFrame.mainframe.SAVED_VAR_X*10)/10
					options.quickSetupFrame.data.triggers[1].delayTime = format("%d:%02d.%d",t/60,t%60,(t*10)%10)
				end
				options.quickSetupFrame.data.triggers[1].event = 20
				options.quickSetupFrame.data.zoneID = options.quickSetupFrame.mainframe.SAVED_VAR_ZONE
				options.quickSetupFrame.data.boss = nil
				ELib:DropDownClose()
				self.quickSetupFrame:Update(options.quickSetupFrame.data)
			end
		}
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C[3].lname,
			func = function()
				local saved = module.options.quickSetupFrame.mainframe.ZONE_ID and options.quickSetupFrame.mainframe.SAVED_VAR_XP or options.quickSetupFrame.mainframe.SAVED_VAR_X
				if saved then
					local t=floor(saved*10)/10
					options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(t,true)
				end
				options.quickSetupFrame.data.triggers[1].event = 3
				options.quickSetupFrame.data.zoneID = nil
				options.quickSetupFrame.data.boss = options.quickSetupFrame.mainframe.SAVED_VAR_BOSS_ZONE or options.quickSetupFrame.mainframe.SAVED_VAR_BOSS
				ELib:DropDownClose()
				self.quickSetupFrame:Update(options.quickSetupFrame.data)
			end
		}
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C[2].lname,
			func = function()
				if options.quickSetupFrame.mainframe.SAVED_VAR_XP then
					local t=floor(options.quickSetupFrame.mainframe.SAVED_VAR_XP*10)/10
					options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(t,true)
					options.quickSetupFrame.data.triggers[1].pattFind = tostring(options.quickSetupFrame.mainframe.SAVED_VAR_P)
				else
					options.quickSetupFrame.data.triggers[1].pattFind = "1"
				end
				if options.quickSetupFrame.mainframe.SAVED_VAR_PC then
					options.quickSetupFrame.data.triggers[1].counter = tostring(options.quickSetupFrame.mainframe.SAVED_VAR_PC)
				else
					options.quickSetupFrame.data.triggers[1].counter = nil
				end
				options.quickSetupFrame.data.triggers[1].event = 2
				options.quickSetupFrame.data.zoneID = nil
				options.quickSetupFrame.data.boss = options.quickSetupFrame.mainframe.SAVED_VAR_BOSS
				options.quickSetupFrame.data.diff = options.quickSetupFrame.mainframe.SAVED_VAR_DIFF
				ELib:DropDownClose()
				self.quickSetupFrame:Update(options.quickSetupFrame.data)
			end
		}
		local function SetCLEU(_,event)
			local savedArgs = event == "SPELL_CAST_SUCCESS" and options.quickSetupFrame.mainframe.SAVED_VAR_SCC or
				event == "SPELL_AURA_REMOVED" and options.quickSetupFrame.mainframe.SAVED_VAR_SAR or
				event == "SPELL_AURA_APPLIED" and options.quickSetupFrame.mainframe.SAVED_VAR_SAA or
				event == "SPELL_CAST_START" and options.quickSetupFrame.mainframe.SAVED_VAR_SCS

			local t = savedArgs[1]
			local c = savedArgs[2]
			options.quickSetupFrame.data.triggers[1].event = 1
			options.quickSetupFrame.data.triggers[1].eventCLEU = event
			options.quickSetupFrame.data.triggers[1].spellID = tonumber(options.quickSetupFrame.mainframe.SAVED_VAR_SID)
			options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(t,true)
			options.quickSetupFrame.data.triggers[1].counter = tostring(c)

			options.quickSetupFrame.data.zoneID = options.quickSetupFrame.mainframe.SAVED_VAR_ZONE
			options.quickSetupFrame.data.boss = options.quickSetupFrame.mainframe.SAVED_VAR_BOSS
			options.quickSetupFrame.data.diff = options.quickSetupFrame.mainframe.SAVED_VAR_DIFF
			ELib:DropDownClose()
			self.quickSetupFrame:Update(options.quickSetupFrame.data)
		end
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C["SPELL_CAST_SUCCESS"].lname,
			func = SetCLEU,
			arg1 = "SPELL_CAST_SUCCESS",
		}
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C["SPELL_AURA_REMOVED"].lname,
			func = SetCLEU,
			arg1 = "SPELL_AURA_REMOVED",
		}
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C["SPELL_AURA_APPLIED"].lname,
			func = SetCLEU,
			arg1 = "SPELL_AURA_APPLIED",
		}
		self.quickSetupFrame.eventDD.List[#self.quickSetupFrame.eventDD.List+1] = {
			text = module.C["SPELL_CAST_START"].lname,
			func = SetCLEU,
			arg1 = "SPELL_CAST_START",
		}
		function self.quickSetupFrame.eventDD:PreUpdate()
			self.List[1].isHidden = (not options.quickSetupFrame.mainframe.ZONE_ID) and true or false
			self.List[3].isHidden = options.quickSetupFrame.mainframe.ZONE_ID and true or false
			-- self.List[4].isHidden = (not options.quickSetupFrame.mainframe.SAVED_VAR_S or (options.quickSetupFrame.mainframe.timeLineData[options.quickSetupFrame.mainframe.SAVED_VAR_SID].spellType or 1) ~= 1) and true or false
			-- self.List[5].isHidden = (not options.quickSetupFrame.mainframe.SAVED_VAR_S or (options.quickSetupFrame.mainframe.timeLineData[options.quickSetupFrame.mainframe.SAVED_VAR_SID].spellType or 1) ~= 2) and true or false
			-- self.List[6].isHidden = options.quickSetupFrame.data.triggers[1].eventCLEU ~= "SPELL_AURA_APPLIED"
			-- self.List[7].isHidden = options.quickSetupFrame.data.triggers[1].eventCLEU ~= "SPELL_CAST_START"

			self.List[4].isHidden = not options.quickSetupFrame.mainframe.SAVED_VAR_SCC and true or false -- scc
			self.List[5].isHidden = not options.quickSetupFrame.mainframe.SAVED_VAR_SAR and true or false -- sar
			self.List[6].isHidden = not options.quickSetupFrame.mainframe.SAVED_VAR_SAA and true or false -- saa
			self.List[7].isHidden = not options.quickSetupFrame.mainframe.SAVED_VAR_SCS and true or false -- scs

			-- self.List[4].isTitle = not options.quickSetupFrame.mainframe.SAVED_VAR_SCC and true or false -- scc
			-- self.List[5].isTitle = not options.quickSetupFrame.mainframe.SAVED_VAR_SAR and true or false -- sar
			-- self.List[6].isTitle = not options.quickSetupFrame.mainframe.SAVED_VAR_SAA and true or false -- saa
			-- self.List[7].isTitle = not options.quickSetupFrame.mainframe.SAVED_VAR_SCS and true or false -- scs
		end
		self.quickSetupFrame.eventDD.Update = function(self)
			local trigger = options.quickSetupFrame.data.triggers[1]
			if trigger.event == 2 then -- phase
				options.quickSetupFrame.eventDD_extra:Point("TOPLEFT",options.quickSetupFrame.eventDD,"BOTTOMLEFT",0,-5):Shown(true)
				options.quickSetupFrame.eventDD_extra:ExtraText(trigger.counter and "["..trigger.counter.."]" or "")
			else
				options.quickSetupFrame.eventDD_extra:Point("TOPLEFT",options.quickSetupFrame.eventDD,"BOTTOMLEFT",0,-5+25):Shown(false)
			end
			if trigger.event == 1 then -- cleu
				local name,_,texture = GetSpellInfo(trigger.spellID or 0)
				self:TextInside((trigger.counter and "["..trigger.counter.."]" or "")..(texture and "|T"..texture..":0|t" or "")..(name or ""),10)
			else
				self:TextInside("",10)
			end
			for n,e in next, module.C do
				if (e.id == trigger.event and trigger.event ~= 1) or (trigger.event == 1 and n == trigger.eventCLEU) then
					self:SetText(e.lname)
					return
				end
			end
			self:SetText("Event "..trigger.event)
		end
	end
	self.quickSetupFrame.eventDD_extra = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.eventDD,"BOTTOMLEFT",0,-5+25):LeftText(LR.BossPhaseLabel):Shown(false):OnChange(function(self,isUser)
		if not isUser then return end
		local text = self:GetText():trim()
		if text == "" then text = nil end
		options.quickSetupFrame.data.triggers[1].pattFind = text
	end)
	-- self.quickSetupFrame.eventDD_extraCounter = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.eventDD_extra,"BOTTOMLEFT",0,-5+25):LeftText((LR.QS_PhaseRepeat):trim() .. ":"):Shown(false):OnChange(function(self,isUser)
	--     if not isUser then return end
	--     local text = self:GetText():trim()
	--     if text == "" then text = nil end
	--     options.quickSetupFrame.data.triggers[1].counter = text
	-- end)

	self.quickSetupFrame.timeEdit = ELib:Edit(self.quickSetupFrame):Size(200,20):Point("TOPLEFT",self.quickSetupFrame.eventDD_extra,"BOTTOMLEFT",0,-5):LeftText(LR.delayText):OnChange(function(self,isUser)
		if not isUser then return end
		local text = self:GetText():trim()
		if text == "" then text = nil end
		options.quickSetupFrame.data.triggers[1].delayTime = text
	end)
	self.quickSetupFrame.timeEdit.mod = ELib:DropDown(self.quickSetupFrame.timeEdit,100,-1):Point("LEFT",self.quickSetupFrame.timeEdit,"RIGHT",5,0):Size(65):SetText("Mod")
	function self.quickSetupFrame.timeEdit.mod:SetValue(arg1)
		local dt = module:ConvertMinuteStrToNum(options.quickSetupFrame.data.triggers[1].delayTime)
		if not dt or not dt[1] then
			return
		end
		local didSomething = false
		if options.quickSetupFrame.mainframe.SAVED_VAR_X then
			local phase1, phase_time1 = options.quickSetupFrame.mainframe:GetPhaseFromTime(options.quickSetupFrame.mainframe.SAVED_VAR_X)
			local phase2, phase_time2, phaseCount, phaseGlobalCount = options.quickSetupFrame.mainframe:GetPhaseFromTime(options.quickSetupFrame.mainframe.SAVED_VAR_X + arg1)
			if phase1 ~= phase2 and phase_time2 then
				options.quickSetupFrame.data.triggers[1].pattFind = tostring(phase2)
				options.quickSetupFrame.data.triggers[1].event = 2
				options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(phase_time2,true)
				if phaseCount then
					options.quickSetupFrame.data.triggers[1].counter = tostring(phaseCount)
				else
					options.quickSetupFrame.data.triggers[1].counter = nil
				end

				options.quickSetupFrame:Update(options.quickSetupFrame.data)

				didSomething = true
			end
		end
		if not didSomething then
			dt = dt[1] + arg1
			if dt < 0 then dt = 0 end
			options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(dt,true)
		end
		options.quickSetupFrame.timeEdit:SetText(options.quickSetupFrame.data.triggers[1].delayTime)
		ELib:DropDownClose()
	end
	for i=-20,20 do
		if (abs(i)<=10 or abs(i)%5 == 0) and i ~= 0 then
			self.quickSetupFrame.timeEdit.mod.List[#self.quickSetupFrame.timeEdit.mod.List+1] = {
				text = (i>0 and "+" or "")..i,
				arg1 = i,
				func = self.quickSetupFrame.timeEdit.mod.SetValue,
			}
		end
	end
	self.quickSetupFrame.timeEdit.mod.List[#self.quickSetupFrame.timeEdit.mod.List+1] = {
		text = LR["Round"],
		func = function()
			local dt = module:ConvertMinuteStrToNum(options.quickSetupFrame.data.triggers[1].delayTime)
			if not dt or not dt[1] then
				return
			end
			dt = floor(dt[1] + 0.5)
			if dt < 0 then dt = 0 end
			options.quickSetupFrame.data.triggers[1].delayTime = module:FormatTime(dt)
			options.quickSetupFrame.timeEdit:SetText(options.quickSetupFrame.data.triggers[1].delayTime)
			ELib:DropDownClose()
		end,
	}

	self.quickSetupFrame.durEdit = ELib:Edit(self.quickSetupFrame):Size(135,20):Point("TOPLEFT",self.quickSetupFrame.timeEdit,"BOTTOMLEFT",0,-5):LeftText(LR.duration):OnChange(function(self,isUser)
		if isUser then
			local text = self:GetText():trim()
			if text == "" then text = nil end
			if text then text = tonumber(text) end
			options.quickSetupFrame.data.duration = text
		end

		if not options.quickSetupFrame.data.duration then
			self:ColorBorder(true)
			options.quickSetupFrame.saveButton:Disable()
		else
			self:ColorBorder(false)
			options.quickSetupFrame.saveButton:Enable()
		end
	end)

	self.quickSetupFrame.durRevese = ELib:Check(self.quickSetupFrame,LR.durationReverse):Tooltip(LR.durationReverseTip):Point("LEFT",self.quickSetupFrame.durEdit,"RIGHT",5,0):OnClick(function(self)
		if self:GetChecked() then
			options.quickSetupFrame.data.durrev = true
		else
			options.quickSetupFrame.data.durrev = nil
		end
	end)


	self.quickSetupFrame.countdownCheck = ELib:Check(self.quickSetupFrame,LR.countdown):Left(5):Point("TOPLEFT",self.quickSetupFrame.durEdit,"BOTTOMLEFT",0,-5):OnClick(function(self)
		if self:GetChecked() then
			options.quickSetupFrame.data.countdown = true
		else
			options.quickSetupFrame.data.countdown = nil
		end
		options.quickSetupFrame.voiceCountdown:Update()
	end)

	self.quickSetupFrame.voiceCountdown = ELib:DropDown(self.quickSetupFrame,220,10):AddText("|cffffd100"..LR.voiceCountdown):Point("TOPLEFT",self.quickSetupFrame.countdownCheck,"BOTTOMLEFT",0,-5+25):Shown(false):Size(270)
	do
		local function voiceCountdown_SetValue(_,arg1)
			ELib:DropDownClose()
			options.quickSetupFrame.data.voiceCountdown = arg1
			local val = MRT.F.table_find3(module.datas.vcountdowns,arg1,1)
			if val then
				self.quickSetupFrame.voiceCountdown:SetText(val[2])
			else
				self.quickSetupFrame.voiceCountdown:SetText("-")
			end
		end
		self.quickSetupFrame.voiceCountdown.SetValue = voiceCountdown_SetValue

		local List = self.quickSetupFrame.voiceCountdown.List
		for i=1,#module.datas.vcountdowns do
			List[#List+1] = {
				text = module.datas.vcountdowns[i][2],
				arg1 = module.datas.vcountdowns[i][1],
				func = voiceCountdown_SetValue,
			}
		end

		function self.quickSetupFrame.voiceCountdown:Update()
			if options.quickSetupFrame.data.countdown then
				options.quickSetupFrame.voiceCountdown:Point("TOPLEFT",options.quickSetupFrame.countdownCheck,"BOTTOMLEFT",0,-5):Shown(true)
			else
				options.quickSetupFrame.voiceCountdown:Point("TOPLEFT",options.quickSetupFrame.countdownCheck,"BOTTOMLEFT",0,-5+25):Shown(false)
			end
		end
	end

	self.quickSetupFrame.voiceCountdown.testButton = MLib:Button(self.quickSetupFrame.voiceCountdown):Size(20,20):Point("LEFT",self.quickSetupFrame.voiceCountdown,"RIGHT",5,0):Tooltip("Play Countdown"):OnClick(function()
		if self.quickSetupFrame.data.voiceCountdown then
			local soundTemplate = module.datas.vcdsounds[ self.quickSetupFrame.data.voiceCountdown ]
			if soundTemplate then
				for i=1,5 do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = MRT.F.ScheduleTimer(PlaySoundFile, 6-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
				end
			end
		end
	end)
	self.quickSetupFrame.voiceCountdown.testButton.background = self.quickSetupFrame.voiceCountdown.testButton:CreateTexture(nil,"ARTWORK")
	self.quickSetupFrame.voiceCountdown.testButton.background:SetPoint("CENTER")
	self.quickSetupFrame.voiceCountdown.testButton.background:SetSize(16,16)
	self.quickSetupFrame.voiceCountdown.testButton.background:SetAtlas("common-icon-forwardarrow")
	self.quickSetupFrame.voiceCountdown.testButton.background:SetDesaturated(true)



	self.quickSetupFrame.soundList = ELib:DropDown(self.quickSetupFrame,270,15):AddText("|cffffd100"..LR.sound):Size(270):Point("TOPLEFT",self.quickSetupFrame.voiceCountdown,"BOTTOMLEFT",0,-5)

	local function soundList_SetValue(_,arg1)
		self.quickSetupFrame.data.sound = arg1
		ELib:DropDownClose()

		self.quickSetupFrame.soundList:SetText("-")
		if self.quickSetupFrame.data.sound then
			local any = false
			local sound = self.quickSetupFrame.data.sound
			for i=1,#module.datas.soundsList do
				local sound2 = module.datas.soundsList[i][1]
				if type(sound) == "string" and type(sound2) == "string" and sound2:lower() == sound:lower() or sound2 == sound then
					self.quickSetupFrame.soundList:SetText(module.datas.soundsList[i][2])
					any = true
					break
				end
			end
			if not any then
				self.quickSetupFrame.soundList:SetText("..." .. (MRT.F.utf8sub(self.quickSetupFrame.data.sound, -40, -5)))
			end
		end
	end
	self.quickSetupFrame.soundList.SetValue = soundList_SetValue

	do
		local List = self.quickSetupFrame.soundList.List
		wipe(List)
		for i=1,#module.datas.soundsList do
			List[#List+1] = {
				text = module.datas.soundsList[i][2],
				arg1 = module.datas.soundsList[i][1],
				func = soundList_SetValue,
			}
		end
	end


	self.quickSetupFrame.soundList.testButton = MLib:Button(self.quickSetupFrame.soundList):Size(20,20):Point("LEFT",self.quickSetupFrame.soundList,"RIGHT",5,0):Tooltip("Play Sound"):OnClick(function()
		if self.quickSetupFrame.data.sound then
			if VMRT.Reminder.disableSound then
				prettyPrint("Sound is disabled")
			else
				pcall(PlaySoundFile,self.quickSetupFrame.data.sound, "Master")
			end
		end
	end)
	self.quickSetupFrame.soundList.testButton.background = self.quickSetupFrame.soundList.testButton:CreateTexture(nil,"ARTWORK")
	self.quickSetupFrame.soundList.testButton.background:SetPoint("CENTER")
	self.quickSetupFrame.soundList.testButton.background:SetSize(16,16)
	self.quickSetupFrame.soundList.testButton.background:SetAtlas("common-icon-forwardarrow")
	self.quickSetupFrame.soundList.testButton.background:SetDesaturated(true)

	self.quickSetupFrame.TTSEdit = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.soundList,"BOTTOMLEFT",0,-5):LeftText(LR.tts):OnChange(function(self,isUser)
		if not isUser then return end
		local text = self:GetText():trim()
		if text == "" then text = nil end
		options.quickSetupFrame.data.tts = text
	end)

	self.quickSetupFrame.TTSEdit.testButton = MLib:Button(self.quickSetupFrame.TTSEdit):Size(20,20):Point("LEFT",self.quickSetupFrame.TTSEdit,"RIGHT",5,0):Tooltip("Play TTS"):OnClick(function()
		if self.quickSetupFrame.data.tts then
			if VMRT.Reminder.disableSound then
				prettyPrint("Sound is disabled")
			else
				module:PlayTTS(self.quickSetupFrame.data.tts)
			end
		end
	end)

	self.quickSetupFrame.TTSEdit.testButton.background = self.quickSetupFrame.TTSEdit.testButton:CreateTexture(nil,"ARTWORK")
	self.quickSetupFrame.TTSEdit.testButton.background:SetPoint("CENTER")
	self.quickSetupFrame.TTSEdit.testButton.background:SetSize(16,16)
	self.quickSetupFrame.TTSEdit.testButton.background:SetAtlas("common-icon-forwardarrow")
	self.quickSetupFrame.TTSEdit.testButton.background:SetDesaturated(true)

	self.quickSetupFrame.glowEdit = ELib:Edit(self.quickSetupFrame):Size(270,20):Point("TOPLEFT",self.quickSetupFrame.TTSEdit,"BOTTOMLEFT",0,-5):Tooltip(LR["Player names to glow\nMay use many separated by\nspace comma or semicolomn"]):LeftText(LR.glow):OnChange(function(self,isUser)
		if not isUser then return end
		local text = self:GetText():trim()
		if text == "" then text = nil end
		options.quickSetupFrame.data.glow = text
	end)


	function self.quickSetupFrame:Update(data)
		self.data = data
		self.setup = true

		local titleText = ""
		if data.boss then
			titleText = titleText .. LR.boss_name[data.boss] .. "\n"
		end

		if data.zoneID then
			local zoneID = tonumber(tostring(data.zoneID):match("^[^, ]+") or "",10)
			titleText = titleText .. LR.instance_name[zoneID] .. "\n"
		end

		if data.diff then
			titleText = titleText .. LR.diff_name[data.diff] .. "\n"
		end

		self.titleText:SetText(titleText)

		self.durEdit:SetText(data.duration or "")

		local msg = data.msg or ""
		if msg:find("^{spell:%d+}") then
			local spell = tonumber( msg:match("^{spell:(%d+)}"))
			local name,_,texture = GetSpellInfo(spell or 0)
			self.spellDD:SetText( (texture and "|T"..texture..":20|t " or "")..(name or ("spell:"..spell)) )
			self.spellDD.spell = spell
			msg = msg:gsub("{spell:%d+} *","",1)
		else
			self.spellDD:SetText( "-" )
			self.spellDD.spell = nil
		end
		self.spellDD_extra:ExtraHide()
		self.msgEdit:SetText(msg)
		self.msgEdit:UpdateColorBorder()
		self.countdownCheck:SetChecked(data.countdown)
		self.voiceCountdown:SetValue(data.voiceCountdown)
		self.voiceCountdown:Update()
		self.quickFilter:Update()
		self.durRevese:SetChecked(data.durrev)

		for i=1,1 do
			local trigger = data.triggers[i]

			self.timeEdit:SetText(trigger.delayTime or "")
			self.eventDD_extra:SetText(trigger.pattFind or "")
			-- self.eventDD_extraCounter:SetText(trigger.counter or "")
		end

		if not data.tmp_tl_cd and data.triggers[2] and data.triggers[2].event == 13 and data.triggers[2].invert and self.spellDD.spell and data.triggers[2].spellID == (tonumber(self.spellDD.spell) or 0) then
			data.tmp_tl_cd = true
		end

		self.cooldownCheck:SetChecked(data.tmp_tl_cd)

		self.eventDD:Update()

		self.soundList:SetValue(data.sound)
		self.TTSEdit:SetText(data.tts or "")
		self.glowEdit:SetText(data.glow or "")

		if data.token and VMRT.Reminder.data[data.token] then
			self.removeButton:Show()
			self.saveButton:NewPoint("BOTTOMRIGHT",self,"BOTTOM",-5,10):Size(200,20)
		else
			self.removeButton:Hide()
			self.saveButton:NewPoint("BOTTOM",self,"BOTTOM",0,10):Size(410,20)
		end

		if not self.prev then
			self.copyButton:Disable()
		else
			self.copyButton:Enable()
		end

		self.setup = false
	end


	function options.timeLine:ResetSavedVars()
		self.SAVED_VAR_X = nil
		self.SAVED_VAR_XP = nil
		self.SAVED_VAR_P = nil
		self.SAVED_VAR_PC = nil
		self.SAVED_VAR_PGC = nil
		self.SAVED_VAR_SID = nil
		self.SAVED_VAR_S = nil
		self.SAVED_VAR_SC = nil

		self.SAVED_VAR_BOSS = nil
		self.SAVED_VAR_DIFF = nil
		self.SAVED_VAR_ZONE = nil
		self.SAVED_VAR_BOSS_ZONE = nil

		self.SAVED_VAR_SCS = nil
		self.SAVED_VAR_SCC = nil
		self.SAVED_VAR_SAA = nil
		self.SAVED_VAR_SAR = nil
	end

	function options.timeLine:PrepareSavedVars(x,y)
		local line = type(y) == "table" and y or self.frame.lines[y]
		if line and line.spell and line:IsShown() then
			local spell_id = line.spell
			self.SAVED_VAR_SID = spell_id

			-- {timeOffster,counter}
			self.SAVED_VAR_SCS = {self:GetSpellFromTime(x, spell_id, nil, "SPELL_CAST_START")}
			self.SAVED_VAR_SCC = {self:GetSpellFromTime(x, spell_id, nil, "SPELL_CAST_SUCCESS")}
			self.SAVED_VAR_SAA = {self:GetSpellFromTime(x, spell_id, nil, "SPELL_AURA_APPLIED")}
			self.SAVED_VAR_SAR = {self:GetSpellFromTime(x, spell_id, nil, "SPELL_AURA_REMOVED")}

			if #self.SAVED_VAR_SCS == 0 then
				self.SAVED_VAR_SCS = nil
			end
			if #self.SAVED_VAR_SCC == 0 then
				self.SAVED_VAR_SCC = nil
			end
			if #self.SAVED_VAR_SAA == 0 then
				self.SAVED_VAR_SAA = nil
			end
			if #self.SAVED_VAR_SAR == 0 then
				self.SAVED_VAR_SAR = nil
			end
		end

		local phase, x_phase, phaseCount, phaseGlobalCount = self:GetPhaseFromTime(x)

		if phase == 0 then
			phase, x_phase, phaseCount, phaseGlobalCount = nil, nil, nil, nil
		end

		self.SAVED_VAR_X = x
		self.SAVED_VAR_XP = x_phase
		self.SAVED_VAR_P = phase
		self.SAVED_VAR_PC = phaseCount
		self.SAVED_VAR_PGC = phaseGlobalCount
	end

	function options.timeLine:OpenQuickSetupFrame(x, y, button, data2)
		--x - time, y - lineNum
		self:PrepareSavedVars(x,y)

		local phase, x_phase, phaseCount, phaseGlobalCount = self.SAVED_VAR_P, self.SAVED_VAR_XP, self.SAVED_VAR_PC, self.SAVED_VAR_PGC

		local data
		if options.quickSetupFrame:IsShown() then
			data = options.quickSetupFrame.data
		else
			data = MRT.F.table_copy2(module.datas.newReminderTemplate)
			data.token = module:GenerateToken()
			data.durrev = true
			data.countdown = true
		end

		if self.ZONE_ID then
			data.boss = nil
			data.zoneID = self.ZONE_ID
		else
			data.boss = self.BOSS_ID
			data.zoneID = nil
		end

		if self.DIFF_ID then
			data.diff = self.DIFF_ID
		else
			data.diff = nil
		end

		self.SAVED_VAR_BOSS = data.boss
		self.SAVED_VAR_ZONE = data.zoneID
		self.SAVED_VAR_DIFF = data.diff
		self.SAVED_VAR_BOSS_ZONE = nil

		if not data.triggers[1] then
			data.triggers[1] = {}
		end
		data.triggers[1].event = self.ZONE_ID and 20 or 3

		if phase and phase > 0 and (phaseGlobalCount ~= 1 or phase ~= 1) then -- and (phase ~= 1 or phaseCount)
			data.triggers[1].event = 2
			data.triggers[1].pattFind = tostring(phase)
			if phaseCount then
				data.triggers[1].counter = tostring(phaseCount)
			else
				data.triggers[1].counter = nil
			end

			x = x_phase
		elseif phase and phase < 0 and phase > -10000 then
			data.triggers[1].event = 3
			data.boss = -phase
			data.zoneID = nil
			x = x_phase

			self.SAVED_VAR_BOSS_ZONE = data.boss
		end

		if button == "RightButton" and self.SAVED_VAR_SID then
			local saved = {self.SAVED_VAR_SCC,self.SAVED_VAR_SCS,self.SAVED_VAR_SAA,self.SAVED_VAR_SAR}
			tDeleteItem(saved,nil)
			sort(saved,function(a,b) return a[1] < b[1] end)
			local savedArgs = saved[1]

			if savedArgs then
				local event = savedArgs == self.SAVED_VAR_SCC and "SPELL_CAST_SUCCESS" or
					savedArgs == self.SAVED_VAR_SCS and "SPELL_CAST_START" or
					savedArgs == self.SAVED_VAR_SAA and "SPELL_AURA_APPLIED" or
					savedArgs == self.SAVED_VAR_SAR and "SPELL_AURA_REMOVED"

				if event then
					local t,c = savedArgs[1],savedArgs[2]
					data.triggers[1].event = 1
					data.triggers[1].eventCLEU = event
					data.triggers[1].counter = tostring(c)
					data.triggers[1].spellID = tonumber(self.SAVED_VAR_SID)
					x = t

					data.zoneID = self.SAVED_VAR_ZONE
					data.boss = self.SAVED_VAR_BOSS
					data.diff = self.SAVED_VAR_DIFF
				end
			end
		end

		local t=floor(x*10)/10
		data.triggers[1].delayTime = module:FormatTime(t,true)

		if self.OPTS_DURDEF then
			data.duration = self.OPTS_DURDEF
		end

		--ignore any updates
		if data2 then
			data = MRT.F.table_copy2(data2)
		end

		if IsShiftKeyDown() then
			module:EditData(data)
			module.SetupFrame.mainframe = self
		else
			options.quickSetupFrame.mainframe = self
			options.quickSetupFrame:Update(data)
			options.quickSetupFrame:Show()
		end
	end

	function options.timeLine:ProcessClick(x, y, button)
		x = self:GetTimeFromPos(x)

		y = ceil(y / self.TL_LINESIZE)

		local phase, x_phase, phaseCount, phaseGlobalCount = self:GetPhaseFromTime(x)

		if phase == 0 then
			phase, x_phase, phaseCount, phaseGlobalCount = nil, nil, nil, nil
		end

		if button == "RightButton" and phase and x_phase <= 3 and y and y <= 2 then
			MRT.F.ShowInput("Change phase (use numbers)",function(_,p)
				options.timeLine.custom_phase[phaseGlobalCount] = tonumber(p)
				options.timeLine:Update()
			end)
			return
		end

		options.timeLine:OpenQuickSetupFrame(x, y, button)
	end

	options.timeLine.Util_SetLineTexture = function(self,line,c,data,color)
		local texture = line.textures[c]
		if not texture then
			texture = line:CreateTexture(nil,"ARTWORK",nil,2)
			line.textures[c] = texture
			texture:SetHeight(options.timeLine.TL_LINESIZE)

			texture.cast = line:CreateTexture(nil,"ARTWORK",nil,2)
			texture.cast:SetSize(2,14)
			texture.cast:Hide()

			texture.l = line:CreateTexture(nil,"ARTWORK",nil,2)
			texture.l:SetHeight(2)
			texture.l:SetPoint("LEFT",texture.cast,"RIGHT",0,0)
			texture.l:SetPoint("RIGHT",texture,"LEFT",0,0)
			texture.l:Hide()

		end
		if color then
			texture:SetColorTexture(unpack(color))
			texture.cast:SetColorTexture(unpack(color))
			texture.l:SetColorTexture(unpack(color))
		else
			texture:SetColorTexture(1,1,1,.7)
			texture.cast:SetColorTexture(1,1,1,.7)
			texture.l:SetColorTexture(1,1,1,.7)
		end
		texture:SetPoint("LEFT",self:GetPosFromTime(data.pos),0)
		texture:SetWidth(self:GetPosFromTime(data.len))
		texture:Show()
		if data.cast then
			texture.cast:SetPoint("LEFT",self:GetPosFromTime(data.pos-data.cast),0)
			texture.cast:Show()
			texture.l:Show()
		else
			texture.cast:Hide()
			texture.l:Hide()
		end
	end

	options.timeLine.Util_ButtonOnClick = function(self,button)
		if button == "RightButton" then
			if not self.data then return end
			local menu = {
				{ text = LR.AdvancedEdit, func = function()
					ELib.ScrollDropDown.Close()
					local data = MRT.F.table_copy2(self.data)
					module:EditData(data)
				end, notCheckable = true },
				{ text = LR.ListdSend, func = function() ELib.ScrollDropDown.Close() module:Sync(false,nil,nil,self.data.token) end, notCheckable = true, isTitle = IsInRaid() and not MRT.F.IsPlayerRLorOfficer("player") },
				{ text = LR.HideOne, tooltip = LR.HideOneTip, func = function() ELib.ScrollDropDown.Close() options.timeLine.reminder_hide[self.data.token]=true options.timeLine:Update() end, notCheckable = true },
				{ text = DELETE, func = function() ELib.ScrollDropDown.Close() module:DeleteReminder(self.data,nil,true) end, notCheckable = true },
				{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
			}
			ELib.ScrollDropDown.EasyMenu(self,menu,200)
		else
			if self.uncategorized then
				if ELib:DropDownCloseIfOpened() then return end
				local menu = {}
				local function Click(_,data)
					ELib.ScrollDropDown.Close()
					local data2 = MRT.F.table_copy2(data)
					module:EditData(data2)
				end
				for i=1,#self.uncategorized do
					local data = self.uncategorized[i]
					menu[#menu+1] = { text = data.name or data.msg or "#"..i, func = Click, arg1 = data, notCheckable = true }
				end
				menu[#menu+1] = { text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true }
				ELib.ScrollDropDown.EasyMenu(self,menu,250,min(#menu,15))
			else
				if self.data and self.data.fromNote then
					prettyPrint(LR["You can't edit reminder simulated from note"])
					return
				end
				options.timeLine:ResetSavedVars()
				options.timeLine:OpenQuickSetupFrame(self.timestamp, nil, nil, self.data)
			end
		end
	end
	options.timeLine.Util_ButtonOnEnter = function(self)
		local data = self.data
		local timestamp = self.timestamp

		self:SetAlpha(.7)

		options.timeLine.HideCursor = true
		self.cursor:SetColorTexture(1,1,0,1)
		self.cursorToSpell:SetColorTexture(1,1,0,1)

		GameTooltip:SetOwner(self, "ANCHOR_LEFT")

		if not data then
			GameTooltip:AddLine(STABLE_PET_UNCATEGORIZED or "Uncategorized")
			GameTooltip:Show()
			return
		end

		local p,pc,pd
		local dt = module:ConvertMinuteStrToNum(data.triggers[1].delayTime or "0")
		if data.triggers[1].event == 2 then
			p = data.triggers[1].pattFind
			pc = data.triggers[1].counter
			-- pd = dt and options.timeLine:GetTimeOnPhase(dt[1],p,pc)
		elseif data.triggers[1].event == 1 and data.triggers[1].eventCLEU then
			local trigger = data.triggers[1]
			local name,_,texture = GetSpellInfo(trigger.spellID)
			local levent = module.C[trigger.eventCLEU].lname

			local desc = (trigger.counter and "["..trigger.counter.."]" or "")..(texture and "|T"..texture..":0|t" or "")..(name or "")
			GameTooltip:AddLine(levent ..": ".. desc)
		end
		if dt and data.triggers[1].event ~= 3 then
			GameTooltip:AddLine((p and LR["Phase "]..p..(pc and " (#"..pc..")" or "")..": " or "")..module:FormatTime(dt[1]))
		end
		if timestamp then
			GameTooltip:AddLine(LR["From start: "]..module:FormatTime(timestamp))
		end

		if data.units then
			local tip = LR["Players:"]
			for i,player in next, {strsplit("#",data.units or "")} do tip = tip .. player .. " " end
			GameTooltip:AddLine(tip)
		end
		if data.roles then
			local tip = LR["Roles:"]
			for i,role in next, {strsplit("#",data.roles or "")} do
				local roleData =  MRT.F.table_find3(module.datas.rolesList,role,3)
				role = roleData and roleData[2] or role

				tip = tip .. role .. " "
			end
			GameTooltip:AddLine(tip)
		end
		if data.classes then
			local tip = LR["Classes:"]
			for i,class in next, {strsplit("#",data.classes or "")} do
				local classLocalized = L.classLocalizate[class]
				tip = tip .. (RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr and "|c"..RAID_CLASS_COLORS[class].colorStr or "") .. classLocalized .. " "
			end
			GameTooltip:AddLine(tip)
		end
		if data.notepat then
			GameTooltip:AddLine(LR["Note: "] .. data.notepat)
		end

		local output = ""

		if data.msg then
			output = output .. LR["Message: "] .. module:FormatMsg(data.msg) .. "\n"
		end

		if data.glow then
			output = output .. LR["Glow: "] .. module:FormatMsg(data.glow) .. "\n"
		end

		if data.tts then
			output = output .. LR["TTS: "] .. module:FormatMsg(data.tts) .. "\n"
		end
		if data.sound then
			output = output .. LR["Sound: "] .. (tostring(data.sound):match("([^\\/]+)$") or data.sound) .. "\n"
		end

		GameTooltip:AddLine(output)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR["Left click - config"])
		GameTooltip:AddLine(LR["Shift+Left click - advanced config"])
		GameTooltip:Show()
	end

	options.timeLine.Util_ButtonOnLeave = function(self)
		options.timeLine.HideCursor = false
		GameTooltip_Hide()
		self:SetAlpha(1)
		self.cursor:SetColorTexture(1,1,1,.5)
		self.cursorToSpell:SetColorTexture(1,1,1,.5)
	end

	options.timeLine.Util_HeaderOnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink("spell:"..self.spell )
		GameTooltip:Show()

		options.timeLine.frame:HighlighSpellLine(self.spell,true)

		if not self.isOff then
			self.name:Color(unpack(options.timeLine.TL_HEADER_COLOR_HOVER))
		end
	end
	options.timeLine.Util_HeaderOnLeave = function(self)
		GameTooltip_Hide()

		options.timeLine.frame:HighlighSpellLine(self.spell,false)

		self.name:Color(unpack(self.isOff and options.timeLine.TL_HEADER_COLOR_OFF or options.timeLine.TL_HEADER_COLOR_ON))
	end

	options.timeLine.Util_LineOnEnter = function(self)
		if not self.header.isOff then
			self.header.name:Color(unpack(options.timeLine.TL_HEADER_COLOR_HOVER))
		end
	end
	options.timeLine.Util_LineOnLeave = function(self)
		self.header.name:Color(unpack(self.header.isOff and options.timeLine.TL_HEADER_COLOR_OFF or options.timeLine.TL_HEADER_COLOR_ON))
	end

	options.timeLine.Util_HeaderOnClick = function(self,button)
		if button == "RightButton" then
			local menu = {
				{ text = LR.CustomDurationLen, func = function()
					ELib.ScrollDropDown.Close()
					MRT.F.ShowInput(LR.CustomDurationLenMore:format(GetSpellInfo(self.spell) or ("spell"..self.spell)),function(spell,dur)
						options.timeLine.spell_dur[spell]=tonumber(dur)
						options.timeLine:Update()
					end,self.spell,true,2)
				end, notCheckable = true },
				{ text = LR.ChangeColorRng, func = function()
					ELib.ScrollDropDown.Close()
					options.timeLine.saved_colors[self.spell]={math.random(1,100)/100,math.random(1,100)/100,math.random(1,100)/100,1}
					options.timeLine:Update()
				end, notCheckable = true },
				{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
			}
			ELib.ScrollDropDown.EasyMenu(self,menu,200)
		elseif button == "LeftButton" and IsControlKeyDown() then
			AddonDB:QuickCopy(self.spell, "Spell ID")
		else
			options.timeLine.spell_status[self.spell] = not options.timeLine.spell_status[self.spell]
			local currSpellStatus = options.timeLine.spell_status[self.spell]
			if IsShiftKeyDown() then
				local changeNext = false
				for i=1,#options.timeLine.frame.lines do
					local line = options.timeLine.frame.lines[i]
					if line and line.header:IsShown() and line.spell == self.spell then
						changeNext = true
					elseif line and line.header:IsShown() and line.spell and changeNext then
						options.timeLine.spell_status[line.spell] = currSpellStatus
					end
				end
			end
			options.timeLine:Update()
		end
	end

	function options.timeLine:Update()
		local timeLineData = self:GetTimeLineData()
		self.timeLineData = timeLineData

		local data_list, data_uncategorized = self:GetRemindersList(self.FILTER_NOTE)
		local max_delay = #data_list > 0 and data_list[#data_list][2] or 0

		local width = self:GetPosFromTime(self:GetTimeAdjust(max_delay)+10)

		local line_c = 0
		local line_c_off = 0
		local line_p = 0
		if timeLineData then
			local spells_sorted = {}
			for spell,spell_times in next, timeLineData do
				if type(spell) == "number" and self:IsPassFilterSpellType(spell_times,spell) then
					spells_sorted[#spells_sorted+1] = {
						id = spell,
						name = GetSpellName(spell) or ("spell"..spell),
						isOff = self.spell_status[spell],
						prio = self.spell_status[spell] and 0 or 1,
						first = type(spell_times[1])=="table" and spell_times[1][1] or spell_times[1] or 0,
						times = spell_times,
					}
					for i=1,#spell_times do
						local t = type(spell_times[i])=="table" and spell_times[i][1] or spell_times[i]
						if t > max_delay then
							max_delay = t
						end
					end
				end
			end
			local cmpTimeLineData = self:GetCompareTimeLineData()
			if cmpTimeLineData then
				for spell,spell_times in next, cmpTimeLineData do
					if type(spell) == "number" and self:IsPassFilterSpellType(spell_times,spell) then
						spells_sorted[#spells_sorted+1] = {
							id = spell,
							name = "|A:None:0:0|a"..(GetSpellName(spell) or ("spell"..spell)),
							isOff = self.spell_status[spell],
							prio = self.spell_status[spell] and 0 or 1,
							first = type(spell_times[1])=="table" and spell_times[1][1] or spell_times[1] or 0,
							times = spell_times,
							isCompare = true,
						}
						for i=1,#spell_times do
							local t = type(spell_times[i])=="table" and spell_times[i][1] or spell_times[i]
							if t > max_delay then
								max_delay = t
							end
						end
					end
				end
			end

			local sortByFirst = #spells_sorted >= 0
			sort(spells_sorted,function(a,b)
				if a.prio ~= b.prio then
					return a.prio > b.prio
				elseif sortByFirst and a.first ~= b.first then
					return a.first < b.first
				else
					return a.name < b.name
				end
			end)
			width = self:GetPosFromTime(self:GetTimeAdjust(max_delay)+10)

			for j=1,#spells_sorted do
				local spell_data = spells_sorted[j]
				local spell = spell_data.id
				local spell_times = spell_data.times
				local isOff = spell_data.isOff
				line_c = line_c + 1
				local line = self.frame.lines[line_c]
				if not line then
					line = CreateFrame("Frame",nil,self.frame.C)
					self.frame.lines[line_c] = line
					line:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(line_c-1))
					line:SetSize(1000,self.TL_LINESIZE)
					if line.SetPropagateMouseClicks then	--not working on classic client rn
						line:SetScript("OnEnter",self.Util_LineOnEnter)
						line:SetScript("OnLeave",self.Util_LineOnLeave)
						line:SetPropagateMouseClicks(true)
					end

					line.textures = {}

					line.header = CreateFrame("Button",nil,self.frame.headers.C)
					line.header:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(line_c-1))
					line.header:SetSize(220,self.TL_LINESIZE)
					line.header:RegisterForClicks("LeftButtonUp","RightButtonUp")
					line.header:SetScript("OnClick",self.Util_HeaderOnClick)
					line.header:SetScript("OnEnter",self.Util_HeaderOnEnter)
					line.header:SetScript("OnLeave",self.Util_HeaderOnLeave)

					line.header.icon = line.header:CreateTexture()
					line.header.icon:SetPoint("RIGHT",0,0)
					line.header.icon:SetSize(self.TL_LINESIZE,self.TL_LINESIZE)

					line.header.name = ELib:Text(line.header,"Spell Name",12):Point("RIGHT",-22,0):Right()

					if line_c%2 == 1 then
						line.bg = line:CreateTexture(nil,"BACKGROUND")
						line.bg:SetAllPoints()
						line.bg:SetColorTexture(1,1,1,.005)

						line.header.bg = line.header:CreateTexture(nil,"BACKGROUND")
						line.header.bg:SetAllPoints()
						line.header.bg:SetColorTexture(1,1,1,.03)
					end
				end

				if spell_data.isCompare then
					if not line.cmpbg then
						line.cmpbg = line:CreateTexture(nil,"BACKGROUND")
						line.cmpbg:SetAllPoints()
						line.cmpbg:SetColorTexture(1,0,1,.1)

						line.header.cmpbg = line.header:CreateTexture(nil,"BACKGROUND")
						line.header.cmpbg:SetAllPoints()
						line.header.cmpbg:SetColorTexture(1,0,1,.1)
					end
					line.cmpbg:Show()
					line.header.cmpbg:Show()
				elseif line.cmpbg then
					line.cmpbg:Hide()
					line.header.cmpbg:Hide()
				end

				local color = spell_times.c or self.saved_colors[spell] or {math.random(1,100)/100,math.random(1,100)/100,math.random(1,100)/100,1}
				self.saved_colors[spell] = color
				local t_c = 0
				if not isOff then
					for i=1,#spell_times do
						local st = spell_times[i]
						local len = self.spell_dur[spell] or (type(st) == "table" and st.d) or spell_times.d or 2
						local cast = (type(st) == "table" and st.c) or (spell_times.cast)
						st = type(st) == "table" and st[1] or st
						if not self:IsRemovedByTimeAdjust(st) then
							st = self:GetTimeAdjust(st)
							if len == "p" then len = self:GetTimeUntilPhaseEnd(st) or 2 end
							t_c = t_c + 1
							self:Util_SetLineTexture(line,t_c,{pos=st,len=len,cast=cast},color)
						end
					end
				end
				for i=t_c+1,#line.textures do
					local t = line.textures[i]
					t:Hide()
					t.cast:Hide()
					t.l:Hide()
				end
				local name,_,texture = GetSpellInfo(spell)
				line.header.name:SetText(spell_data.name or name or "spell"..spell)
				line.header.icon:SetTexture(texture)
				if isOff then
					line.header.isOff = true
					line.header.name:SetTextColor(unpack(self.TL_HEADER_COLOR_OFF))
					line:Hide()

					line_c_off = line_c_off + 1
				else
					line.header.isOff = false
					line.header.name:SetTextColor(unpack(self.TL_HEADER_COLOR_ON))

					line:Show()
				end
				line.header.spell = spell
				line.spell = spell

				line:SetWidth(width)

				line:Show()
				line.header:Show()
			end

			if timeLineData.p then
				for i=1,#timeLineData.p do
					local x = timeLineData.p[i]

					line_p = line_p + 1
					local pcursor = self.frame.pcursors[line_p]
					if not pcursor then
						pcursor = self.frame.D:CreateTexture(nil,"ARTWORK", nil, 4)
						self.frame.pcursors[i] = pcursor
						pcursor:SetWidth(1)
						pcursor:SetPoint("TOP")
						pcursor:SetPoint("BOTTOM",self.frame.cursorH,"TOP",0,0)
						pcursor:SetColorTexture(0,1,0,.7)

						pcursor.text = ELib:Text(self.frame.D,"Phase "..(i),10):Point("LEFT",pcursor,"TOPRIGHT",1,0):Point("TOP",self.frame.cursorHT2,"BOTTOM",0,-1):Left():Color(0,1,0,.7):Outline()
						-- pcursor.text:SetRotation(90*math.pi/180)
						pcursor.text:SetDrawLayer("ARTWORK", 4)
					end
					local pn = self.custom_phase[i] or (timeLineData.p.n and timeLineData.p.n[i]) or i
					local phase_time = self:GetTimeOnPhase(0,pn,self:GetPhaseCounter(i))
					x = self:GetPosFromTime(phase_time)
					pcursor:SetPoint("LEFT",x,0)
					local text = "Phase "..pn
					if tostring(pn):find("%d%.%d") then
						-- text = "Intermission "..tostring(pn):match("^%d+")
					elseif pn == 0 then
						text = ""
					elseif pn and type(pn)=="number" and pn < 0 and pn > -10000 then
						text = LR.boss_name[ -pn ]
					end
					pcursor.text:SetText(text)
					pcursor:Show()
					pcursor.text:Show()
				end
			end
		end
		for i=line_c+1,#self.frame.lines do
			local line = self.frame.lines[i]
			line:Hide()
			line.header:Hide()
		end
		for i=line_p+1,#self.frame.pcursors do
			local line = self.frame.pcursors[i]
			line:Hide()
			line.text:Hide()
		end
		local max_y = (line_c+1)*self.TL_LINESIZE

		line_c = line_c - line_c_off
		if line_c == 0 then
			line_c = 1
		end

		self.frame.cursorH:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(line_c))

		self.frame.cursorH:SetSize(width,2)

		self.frame:Width(width)

		max_y = max((line_c+1)*self.TL_LINESIZE,max_y)
		local prevButton = -100
		local prevY = 0
		local b_c = 0
		sort(data_list,self.util_sort_by2)
		for i=(data_uncategorized and 0 or 1),#data_list do
			b_c = b_c + 1

			local button = self.frame.buttons[b_c]
			if not button then
				button = CreateFrame("Button",nil,self.frame.C)
				self.frame.buttons[b_c] = button
				button:SetSize(self.TL_REMSIZE,self.TL_REMSIZE)

				button.cursor = button:CreateTexture(nil,"ARTWORK",nil,3)
				button.cursor:SetWidth(1)
				button.cursor:SetPoint("TOP",self.frame.cursorHT2,"BOTTOM",0,0)
				button.cursor:SetPoint("BOTTOMLEFT",button,"TOPLEFT",0,0)
				button.cursor:SetColorTexture(1,1,1,.5)

				button.cursorToSpell = button:CreateTexture(nil,"ARTWORK",nil,3)
				button.cursorToSpell:SetHeight(1)
				button.cursorToSpell:SetPoint("RIGHT",button.cursor,"TOP",0,0)
				button.cursorToSpell:SetColorTexture(1,1,1,.5)
				button.cursorToSpell:Hide()

				button.icon = button:CreateTexture()
				button.icon:SetAllPoints()

				button.rightIcon = button:CreateTexture(nil,nil,nil,1)
				button.rightIcon:SetSize(self.TL_REMSIZE+2,self.TL_REMSIZE+2)
				button.rightIcon:SetPoint("CENTER",button,"CENTER")
				button.rightIcon:SetAtlas("transmog-frame-pink")

				button:RegisterForClicks("LeftButtonUp","RightButtonUp")
				button:SetScript("OnClick",self.Util_ButtonOnClick)
				button:SetScript("OnEnter",self.Util_ButtonOnEnter)
				button:SetScript("OnLeave",self.Util_ButtonOnLeave)
			end

			local data_line = data_list[i]
			local data = data_line and data_line[1]
			local x = data_line and data_line[2] or 0

			local pos = self:GetPosFromTime(x)
			local anchorLeft = data and not data.durrev

			if pos < (anchorLeft and 0 or self.TL_REMSIZE) then
				pos = (anchorLeft and 0 or self.TL_REMSIZE)
			end

			if prevButton > (pos - (anchorLeft and 0 or self.TL_REMSIZE)) then
				prevY = prevY + self.TL_REMSIZE
			else
				prevY = 0
			end
			button:ClearAllPoints()

			prevButton = max(pos + (anchorLeft and self.TL_REMSIZE or 0),prevButton)

			button:SetPoint(anchorLeft and "TOPLEFT" or "TOPRIGHT",self.frame.C,"TOPLEFT",pos,-(line_c+1)*self.TL_LINESIZE-prevY)

			button.cursor:ClearAllPoints()
			button.cursor:SetPoint(anchorLeft and "BOTTOMLEFT" or "BOTTOMRIGHT",button,anchorLeft and "TOPLEFT" or "TOPRIGHT",0,0)
			button.cursor:SetPoint("TOP",self.frame.cursorHT2,"BOTTOM",0,0)
			button.cursor:Show()

			button.cursorToSpell:Hide()
			if data_line and data_line[3] and data_line[3].s then
				local spell = data_line[3].s
				local found = false
				for j=1,#self.frame.lines do
					local line = self.frame.lines[j]
					if line.spell == spell and line:IsShown() then
						button.cursor:SetPoint("TOP",line,"RIGHT",0,0)

						button.cursorToSpell:SetWidth( self:GetPosFromTime(data_line[4]) )
						button.cursorToSpell:Show()

						found = true
						break
					end
				end
				if not found then
					button.cursor:Hide()
				end
			end

			if i == 0 then
				button.cursor:Hide()
			end

			local texture = 134938
			if i == 0 then
				texture = 294476
			end
			if data and data.glow then
				texture = MRT.isClassic and 134993 or 878211
			end

			if data and (data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5) and data.barIcon then
				local spellID = tonumber(data.barIcon) or texture
				if spellID == 0 then
					spellID = data.triggers[1].spellID or data.triggers[2].spellID
				end
				if spellID then
					texture = GetSpellTexture(spellID) or texture
				end
			end

			if data and type(data.msg) == "string" and module:FormatMsg(data.msg):find("|T.+|t") then
				local msg = module:FormatMsg(data.msg)
				texture = tonumber(msg:match("|T([^:|]+)") or "") or texture
			end
			if data and data.fromNote then
				button.rightIcon:Show()
			else
				button.rightIcon:Hide()
			end

			button.icon:SetTexture(texture)
			button.data = data
			button.uncategorized = i == 0 and data_uncategorized
			button.timestamp = x
			button:Show()

			if max_y < (line_c+1)*self.TL_LINESIZE + prevY + self.TL_REMSIZE*2 then
				max_y = (line_c+1)*self.TL_LINESIZE + prevY + self.TL_REMSIZE*2
			end
		end
		for i=b_c+1,#self.frame.buttons do
			self.frame.buttons[i]:Hide()
		end

		if max_y > self.frame:GetHeight() then
			self.frame:Height(max_y)
			self.frame.headers:Height(max_y)
			self.frame.headers.ScrollBar:Show()
		elseif self.frame.headers.ScrollBar:IsShown() then
			self.frame.headers.ScrollBar:SetValue(0)
			self.frame.headers.ScrollBar:Hide()
		end
	end
	self.timeLine:Update()

	options.timeLine.customTimeLineDataFrame = ELib:Popup(LR["Edit custom encounter"]):Size(800,600):OnShow(function(self) self:Update() end,true)
	ELib:Border(options.timeLine.customTimeLineDataFrame,1,.4,.4,.4,.9)

	options.timeLine.customTimeLineDataFrame.bossList = ELib:DropDown(options.timeLine.customTimeLineDataFrame,270,min(#AddonDB.EJ_DATA.encountersListShort,15)):AddText("|cffffd100"..LR.Boss):Size(270):Point("TOPLEFT",100,-20)
	do
		local List = options.timeLine.customTimeLineDataFrame.bossList.List
		local function bossList_SetValue(_,encounterID)
			options.timeLine.customTimeLineDataFrame.bossID = encounterID
			options.timeLine.customTimeLineDataFrame.bossList:AutoText(encounterID,nil,true)
			ELib:DropDownClose()
		end
		options.timeLine.customTimeLineDataFrame.bossList.SetValue = bossList_SetValue

		local encountersList = AddonDB.EJ_DATA.encountersListShort
		for i=1,#encountersList do
			local instance = encountersList[i]
			local instanceMenu = {}
			local zoneImg = AddonDB:GetInstanceImage(instance[1])
			List[#List+1] = {
				text = LR.instance_name[instance[1]],
				subMenu = instanceMenu,
				icon = zoneImg,
				iconsize = 30,
			}
			for j=#instance,2,-1 do
				local bossID, bossImg = instance[j], AddonDB:GetBossPortrait(instance[j])
				instanceMenu[#instanceMenu+1] = {
					text = LR.boss_name[ bossID ],
					arg1 = bossID,
					func = bossList_SetValue,
					icon = bossImg,
					iconsize = 32,
				}
			end
		end

	end

	options.timeLine.customTimeLineDataFrame.copyFrom = ELib:DropDown(options.timeLine.customTimeLineDataFrame,270,15):Size(200):SetText("Copy from"):Point("TOPRIGHT",-30,-20)
	function options.timeLine.customTimeLineDataFrame.copyFrom:AddBoss(bossID,bossData,fightLen,extraNameText)
		local bossImg = AddonDB:GetBossPortrait(bossID)
		local name = LR.boss_name[bossID]

		if bossID < 0 then
			name = LR.instance_name[-bossID]
		end

		local res = {
			text = name..(extraNameText or "").." ".. module:FormatTime(fightLen or bossData.d and bossData.d[2] or 0),
			arg1 = bossID,
			arg2 = bossData,
			func = self.SetValue,
			icon = bossImg,
			iconsize = bossImg and 32,
		}

		return res
	end
	function options.timeLine.customTimeLineDataFrame.copyFrom:PreUpdate()
		wipe(self.List)

		for bossID,bossDatas in next, options.timeLine.Data do
			for _,bossData in next, (bossDatas.m and bossDatas or {bossDatas}) do
				if type(bossData) == "table" then
					self.List[#self.List+1] = self:AddBoss(bossID, bossData)
				end
			end
		end
		-- for i=1,#module.db[h_key] do
		-- 	local fight = module.db[h_key][i]
		-- 	local fightLen = #fight > 1 and fight[#fight][1] - fight[1][1]
		-- 	local bossID
		-- 	if #fight > 0 and fight[1][2] == 22 then
		-- 		bossID = -fight[1][3]
		-- 	elseif #fight > 0 and fight[1][2] == 3 then
		-- 		bossID = fight[1][3]
		-- 	end
		-- 	if bossID and fightLen then
		-- 		local n = self:AddBoss(bossID, fight, fightLen, "*")
		-- 		n.arg3 = 2
		-- 		self.List[#self.List+1] = n
		-- 	end
		-- end

		sort(self.List,function(a,b) return a.arg1 > b.arg1 end)

		local editInList = {text = " ", isTitle = true, edit = "", editIcon = [[Interface\Common\UI-Searchbox-Icon]]}
		editInList.editFunc = function(this)
			local search = this:GetText()
			if search and search:trim() == "" then
				search = nil
			end
			search = search and search:lower()
			for i=1,#self.List do
				local l = self.List[i]
				if not l.edit then
					l.isHidden = search and not l.text:lower():find(search,1,true)
				end
			end
			editInList.edit = search or ""
			ELib.ScrollDropDown:Reload()
			--this:SetFocus()
		end
		tinsert(self.List, 1, editInList)
	end
	function options.timeLine.customTimeLineDataFrame.copyFrom:SetValue(bossID,bossData,opt)
		ELib:DropDownClose()
		options.timeLine.customTimeLineDataFrame.bossID = bossID
		if opt == 2 then bossData = options.timeLine:CreateCustomTimelineFromHistory(bossData) end
		options.timeLine.customTimeLineDataFrame.data = MRT.F.table_copy2(bossData)
		options.timeLine.customTimeLineDataFrame.bossList:AutoText(bossID,nil,true)
		options.timeLine.customTimeLineDataFrame:Update()
	end

	options.timeLine.customTimeLineDataFrame.frame = ELib:ScrollFrame(options.timeLine.customTimeLineDataFrame):Size(800,600-95-18):Height(600-40):AddHorizontal(true):Width(800):Point("TOP",0,-95)
	ELib:Border(options.timeLine.customTimeLineDataFrame.frame,0)
	options.timeLine.customTimeLineDataFrame.frame.lines = {}

	function options.timeLine.customTimeLineDataFrame:PrepData()
		local max_len = 0
		for k,v in next, self.data do
			if type(k) == "number" or k == "p" then
				for i=#v,1,-1 do
					if not v[i] or (type(v[i])=="table" and not v[i][1]) then
						tremove(v, i)
					end
					max_len = max(max_len,type(v[i])=="number" and v[i] or type(v[i])=="table" and type(v[i][1])=="number" and v[i][1] or max_len)
				end
			end
		end
		if not self.data.d then
			self.data.d = {}
		end
		self.data.d[2] = max_len
	end
	function options.timeLine.customTimeLineDataFrame:Save()
		if not VMRT.Reminder.CustomTLData then
			VMRT.Reminder.CustomTLData = {}
		end
		local bossID = self.bossID
		if not bossID then
			prettyPrint('data not saved, no boss selected')
			return
		end
		self:PrepData()
		VMRT.Reminder.CustomTLData[bossID] = self.data
	end

	options.timeLine.customTimeLineDataFrame:SetScript("OnHide",function(self)
		MLib:DialogPopup({
			id = "EXRT_REMINDER_CLOSE",
			title = LR["Save data?"],
			buttons = {
				{
					text = YES,
					func = function()
						self:Save()
					end,
				},
				{
					text = NO,
				}
			},
		})
	end)

	options.timeLine.customTimeLineDataFrame.frame:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll_h = self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.ScrollBar:GetValue()
		self.moveSpotted = nil

	end)

	options.timeLine.customTimeLineDataFrame.frame:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil
		self.moveSpotted = nil
	end)


	options.timeLine.customTimeLineDataFrame.frame:SetScript("OnUpdate",function(self)
		local x,y = MRT.F.GetCursorPos(self)

		if self.saved_x and self.saved_y then
			if self.ScrollBarHorizontal:IsShown() and abs(x - self.saved_x) > 5 then
				local newVal = self.saved_scroll_h - (x - self.saved_x)
				local min,max = self.ScrollBarHorizontal:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBarHorizontal:SetValue(newVal)

				self.moveSpotted = true
			end
			if self.ScrollBar:IsShown() and abs(y - self.saved_y) > 5 then
				local newVal = self.saved_scroll_v - (y - self.saved_y)
				local min,max = self.ScrollBar:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBar:SetValue(newVal)

				self.moveSpotted = true
			end
		end
	end)


	options.timeLine.customTimeLineDataFrame.importWindow, options.timeLine.customTimeLineDataFrame.exportWindow = MRT.F.CreateImportExportWindows()
	options.timeLine.customTimeLineDataFrame.importWindow:SetFrameStrata("FULLSCREEN")
	options.timeLine.customTimeLineDataFrame.exportWindow:SetFrameStrata("FULLSCREEN")

	function options.timeLine.customTimeLineDataFrame.importWindow:ImportFunc(str)
		local bossID,datastr = strsplit("=",str,2)
		bossID = bossID:match("%d+")
		local data = MRT.F.TextToTable(datastr)
		if not data or not bossID then
			print('import string is corrupted')
			return
		end
		options.timeLine.customTimeLineDataFrame:OpenEdit(tonumber(bossID), data)
	end

	options.timeLine.customTimeLineDataFrame.ExportButton = ELib:Button(options.timeLine.customTimeLineDataFrame,LR.Export):Point("TOPRIGHT",options.timeLine.customTimeLineDataFrame.copyFrom,"BOTTOMRIGHT",0,-5):Size(200,20):OnClick(function()
		local str = ""

		options.timeLine.customTimeLineDataFrame:PrepData()

		str = MRT.F.TableToText(options.timeLine.customTimeLineDataFrame.data)
		str[1] = "["..(options.timeLine.customTimeLineDataFrame.bossID or 0).."]="..str[1]
		str = table.concat(str)

		MRT.F:Export2(str)
		-- options.timeLine.historyExportWindow.Edit:SetText(str)
		-- options.timeLine.historyExportWindow:Show()

		options.timeLine.customTimeLineDataFrame:Update()
	end)


	options.timeLine.customTimeLineDataFrame.ImportButton = ELib:Button(options.timeLine.customTimeLineDataFrame,LR.Import):Point("TOPRIGHT",options.timeLine.customTimeLineDataFrame.ExportButton,"BOTTOMRIGHT",0,-5):Size(200,20):OnClick(function()
		options.timeLine.customTimeLineDataFrame.importWindow:NewPoint("CENTER",UIParent,0,0)
		options.timeLine.customTimeLineDataFrame.importWindow:Show()
	end)

	options.timeLine.customTimeLineDataFrame.addButton = ELib:Button(options.timeLine.customTimeLineDataFrame.frame.C,LR["Add"]):Size(100,20):OnClick(function(self)
		local data = options.timeLine.customTimeLineDataFrame.data

		data[self.spell] = {}

		self:Hide()
		options.timeLine.customTimeLineDataFrame:Update()
	end)


	function options.timeLine.customTimeLineDataFrame:removeButton_click()
		local data = options.timeLine.customTimeLineDataFrame.data
		local sList = options.timeLine.customTimeLineDataFrame.sList
		local i = self:GetParent().data_i
		data[ sList[i].spell ] = nil

		options.timeLine.customTimeLineDataFrame:Update()
	end

	function options.timeLine.customTimeLineDataFrame:spell_edit(isUser)
		local text = tonumber(self:GetText() or "")
		local texture = text and GetSpellTexture(text)
		self:InsideIcon(texture)
		self:BackgroundTextCheck()
		local data = self:GetParent().data
		options.timeLine.customTimeLineDataFrame.addButton:NewPoint("LEFT",self,"RIGHT",5,0):SetShown(text and not data)
		options.timeLine.customTimeLineDataFrame.addButton.spell = text
		if not isUser then return end
		if data then
			local mdata = options.timeLine.customTimeLineDataFrame.data
			mdata[data.spell] = nil
			data.spell = text
			mdata[data.spell] = data.data
		end
	end
	function options.timeLine.customTimeLineDataFrame:spell_enter()
		local text = tonumber(self:GetText() or "")
		if not text then return end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink("spell:"..text )
		GameTooltip:Show()
	end
	function options.timeLine.customTimeLineDataFrame:spell_leave()
		GameTooltip_Hide()
	end

	---@param self ELibEdit
	function options.timeLine.customTimeLineDataFrame:time_mini_update()
		local parent = self:GetParent()

		local now = parent.data[parent._i]
		local prev = parent.data[parent._i-1]
		if type(now) == "table" then now = now[1] end
		if type(prev) == "table" then prev = prev[1] end
		local diff = now and prev and now - prev
		if diff and diff < 0 then diff = nil end
		self:Text(diff or "")
	end

	function options.timeLine.customTimeLineDataFrame:time_edit(isUser)
		if not isUser then return end
		local text = self:GetText()
		local t = module:ConvertMinuteStrToNum(text or "")
		if t then t = t[1] end
		self.data[self._i] = t
		self.mini:Update()
		if self.next then
			self.next.mini:Update()
		end
	end

	function options.timeLine.customTimeLineDataFrame:time_editmini(isUser)
		if not isUser then return end
		local text = self:GetText()
		local t = module:ConvertMinuteStrToNum(text or "")
		if t then t = t[1] end
		if not t then return end
		local parent = self:GetParent()
		local prev = parent.data[parent._i-1]
		if type(prev) == "table" then prev = prev[1] end
		parent.data[parent._i] = prev + t
		parent:Text( module:FormatTime(parent.data[parent._i]) or "" )
		if parent.next then
			parent.next.mini:Update()
		end
	end

	function options.timeLine.customTimeLineDataFrame:time_remove_click()
		local parent = self:GetParent()
		tremove(parent.data, parent._i)

		options.timeLine.customTimeLineDataFrame:Update()
	end

	function options.timeLine.customTimeLineDataFrame:time_add_click()
		local parent = self:GetParent()
		tinsert(parent.data, self._I or parent._i, self._T or parent.data[parent._i] or 0)

		options.timeLine.customTimeLineDataFrame:Update()
	end

	options.timeLine.customTimeLineDataFrame.dataToLine = {}
	function options.timeLine.customTimeLineDataFrame:UpdateView()
		local pos = self.frame:GetVerticalScroll()
		local h_pos = self.frame:GetHorizontalScroll()

		local spellsList = self.sList

		for i=1,#self.frame.lines do
			self.frame.lines[i].used = false
		end

		local datasUsed = {}
		for i=1,#spellsList do
			local data = spellsList[i]
			if data.pos + 25 >= pos and data.pos <= pos+self.frame:GetHeight() then
				local line = self.dataToLine[data]
				if line then
					line.used = true
				end
			elseif self.dataToLine[data] then
				self.dataToLine[data] = nil
			end
		end

		for i=1,#spellsList do
			local data = spellsList[i]
			if data.pos + 25 >= pos and data.pos <= pos+self.frame:GetHeight() then
				local line = self.dataToLine[data]
				if not line then
					for j=1,#self.frame.lines do
						if not self.frame.lines[j].used then
							line = self.frame.lines[j]
							break
						end
					end
				end
				if not line then
					line = CreateFrame("Frame",nil,self.frame.C)
					self.frame.lines[#self.frame.lines+1] = line
					line:SetSize(500,24)

					line.spell = ELib:Edit(line):Size(100,20):Point("LEFT",5,0):BackgroundText("Spell ID"):OnChange(self.spell_edit):OnEnter(self.spell_enter):OnLeave(self.spell_leave)

					line.remove = ELib:Button(line,""):Size(12,20):Point("LEFT",line.spell,"RIGHT",3,0):OnClick(self.removeButton_click)
					ELib:Text(line.remove,"x"):Point("CENTER",0,0)
					line.remove.Texture:SetGradient("VERTICAL",CreateColor(0.35,0.06,0.09,1), CreateColor(0.50,0.21,0.25,1))

					line.bg = line:CreateTexture(nil,"BACKGROUND")
					line.bg:SetAllPoints()

					line.add = ELib:Button(line,""):Size(20,20):OnClick(self.time_add_click)
					ELib:Text(line.add,"+"):Point("CENTER",0,0)
					line.add.Texture:SetGradient("VERTICAL",CreateColor(0.25,0.25,0.09,1), CreateColor(0.45,0.45,0.17,1))

					line.timers = {}
				end
				line.used = true
				self.dataToLine[data] = line

				local timers_c = 0
				local data_len = 0
				if data.data then
					line.remove:Show()
					line.add:Show()

					local prev = nil
					data_len = #data.data
					for j=1,data_len do
						local timer_pos = 5+100+30+(j-1)*130
						if timer_pos + 50 >= h_pos and timer_pos - 80 <= h_pos+self.frame:GetWidth() then
							timers_c = timers_c + 1
							local timer_edit = line.timers[timers_c]
							if not timer_edit then
								timer_edit = ELib:Edit(line):Size(50,20):OnChange(self.time_edit)

								timer_edit.remove = ELib:Button(timer_edit,""):Size(8,20):Point("LEFT",timer_edit,"RIGHT",0,0):OnClick(self.time_remove_click)
								ELib:Text(timer_edit.remove,"x",8):Point("CENTER",0,0)
								timer_edit.remove.Texture:SetGradient("VERTICAL",CreateColor(0.35,0.06,0.09,1), CreateColor(0.50,0.21,0.25,1))

								timer_edit.add = ELib:Button(timer_edit,""):Size(8,20):Point("RIGHT",timer_edit,"LEFT",0,0):OnClick(self.time_add_click)
								ELib:Text(timer_edit.add,"+",8):Point("CENTER",0,0)
								timer_edit.add.Texture:SetGradient("VERTICAL",CreateColor(0.06,0.2,0.09,1), CreateColor(0.14,0.35,0.17,1))

								timer_edit.mini = ELib:Edit(timer_edit):Size(30,12):FontSize(8):OnChange(self.time_editmini):Point("RIGHT",timer_edit,"LEFT",-25,0)
								timer_edit.mini.Update = self.time_mini_update

								timer_edit.borderleft = timer_edit:CreateTexture(nil,"BACKGROUND")
								timer_edit.borderleft:SetSize(20,1)
								timer_edit.borderleft:SetPoint("RIGHT",timer_edit.mini,"LEFT",0,0)
								timer_edit.borderleft:SetColorTexture(0.24,0.25,0.3,1)

								timer_edit.borderright = timer_edit:CreateTexture(nil,"BACKGROUND")
								timer_edit.borderright:SetSize(20,1)
								timer_edit.borderright:SetPoint("LEFT",timer_edit.mini,"RIGHT",0,0)
								timer_edit.borderright:SetColorTexture(0.24,0.25,0.3,1)

								line.timers[timers_c] = timer_edit
							end

							timer_edit._i = j
							timer_edit:Point("LEFT",timer_pos,0)
							if prev then
								prev.next = timer_edit
							end
							timer_edit.next = nil

							timer_edit.mini:SetShown(j > 1)
							timer_edit.borderleft:SetShown(j > 1)
							timer_edit.borderright:SetShown(j > 1)

							local t = data.data[j]
							if type(t) == "table" then t = t[1] end

							timer_edit.data = data.data
							timer_edit:Text( t and module:FormatTime(t) or "" )
							timer_edit.mini:Update()
							timer_edit:Show()

							prev = timer_edit
						end
					end
				else
					line.remove:Hide()
					line.add:Hide()
				end

				for j=timers_c+1,#line.timers do
					line.timers[j]:Hide()
				end
				line.add:Point("LEFT",line.spell,"RIGHT",30+data_len*50+max(0,data_len-1)*80+20,0)
				line.add._I = data_len+1
				line.add._T = data.data and data_len > 0 and (type(data.data[data_len])=="table" and data.data[data_len][1] or data.data[data_len]) or 0

				line.data = data.data
				line:SetPoint("TOPLEFT",0,-data.pos)
				line.spell:SetText(data.spell or "")
				if data.spell == "p" then
					line.spell:SetText("Phases")
					line.spell:Disable()
				else
					line.spell:Enable()
				end
				line.data_i = data._i
				line.remove._i = i

				line:SetWidth(max(200,self:GetWidth()))

				line:Show()
			end
		end
		for i=1,#self.frame.lines do
			if not self.frame.lines[i].used then
				self.frame.lines[i]:Hide()
			end
		end
	end

	function options.timeLine.customTimeLineDataFrame:OpenEdit(bossID, data)
		self.data = data
		self.bossID = bossID
		self.bossList:AutoText(bossID or 0,nil,true)
		self:Show()
		self:Update()
	end
	function options.timeLine.customTimeLineDataFrame:Update()
		if not self.data then
			self.data = {}
		end
		local data = self.data
		wipe(self.dataToLine)

		local maxw = max(0,data.p and #data.p or 0)
		self.sList = {}
		if data.p then
			self.sList[#self.sList+1] = {
				spell = "p",
				data = data.p or {},
				sort = -1,
			}
		end
		for k,v in next, data do
			if type(k) == "number" and type(v) ~= "userdata" then
				self.sList[#self.sList + 1] = {
					spell = k,
					data = v,
					sort = #v == 0 and math.huge or type(v[1]) == "table" and v[1][1] or v[1],
				}
				maxw = max(maxw,#v)
			end
		end
		sort(self.sList,function(a,b)
			return a.sort < b.sort
		end)
		self.sList[#self.sList + 1] = {}

		for i=1,#self.sList do
			self.sList[i].pos = 5 + 25 * (i-1)
			self.sList[i]._i = i
		end

		local maxheight = 5 + #self.sList * 25 + 15
		local maxwidth = max(5+100+30+maxw*50+(maxw-1)*80+20+30+20, self:GetWidth())

		self.frame:Height(maxheight)
		self.frame:Width(maxwidth)

		self:UpdateView()
	end

	options.timeLine.customTimeLineDataFrame.frame:SetScript("OnVerticalScroll", function(self)
		self:GetParent():UpdateView()
	end)
	options.timeLine.customTimeLineDataFrame.frame:SetScript("OnHorizontalScroll", function(self)
		self:GetParent():UpdateView()
	end)



	self.assign = {
		Data = module.TimelineData,

		BOSS_ID = 0,

		TIMELINE_SCALE = 80,
		TIMELINE_ADJUST_NUM = 3,
		TIMELINE_ADJUST = 100,
		TIMELINE_ADJUST_DATA = {},

		TL_PAGEWIDTH = type(VMRT.Reminder.OptAssigWidth) == "number" and VMRT.Reminder.OptAssigWidth or 1000,
		TL_LINESIZE = type(VMRT.Reminder.OptAssigLineSize) == "number" and VMRT.Reminder.OptAssigLineSize or 16,
		TL_REMSIZE = 24,
		TL_HEADER_COLOR_OFF = {.2,.2,.2,1},
		TL_HEADER_COLOR_ON = {.5,.8,1,1},
		TL_HEADER_COLOR_HOVER = {1,1,0,1},
		TL_ASSIGNWIDTH = 100,
		TL_ASSIGNSPACING = 5,

		FILTER_AURA = true,

		gluerange = 2,

		spell_status = type(VMRT.Reminder.OptAssigSpellDisabled) == "table" and VMRT.Reminder.OptAssigSpellDisabled or {},
		spell_dur = {},
		custom_phase = {},
		reminder_hide = {},
		custom_line = {},
		custom_cd = type(VMRT.Reminder.OptAssigCustomCD) == "table" and VMRT.Reminder.OptAssigCustomCD or {},
		custom_charges = {},
		custom_spells = {},

		QFILTER_CLASS = type(VMRT.Reminder.OptAssigQFClass) == "table" and VMRT.Reminder.OptAssigQFClass or {},
		QFILTER_ROLE = type(VMRT.Reminder.OptAssigQFRole) == "table" and VMRT.Reminder.OptAssigQFRole or {},
		QFILTER_SPELL = type(VMRT.Reminder.OptAssigQFSpell) == "table" and VMRT.Reminder.OptAssigQFSpell or {},

		FILTER_SPELLS = VMRT.Reminder.OptAssigFSpells,

		SpellGroups_Presetup = {
			["names"] = {"raid cd","personals","externals","ultility","movement","dps cd","aoe cc","single cc",},
			{[388615]=true,[51052]=true,[200183]=true,[370960]=true,[47536]=true,[97462]=true,[370537]=true,[265202]=true,[33891]=true,[124974]=true,[207399]=true,[197721]=true,[325197]=true,[374227]=true,[359816]=true,[472433]=true,[363534]=true,[216331]=true,[108280]=true,[34433]=true,[414660]=true,[200652]=true,[15286]=true,[322118]=true,[62618]=true,[98008]=true,[108281]=true,[31821]=true,[31884]=true,[105809]=true,[740]=true,[114052]=true,[271466]=true,[421453]=true,[64843]=true,[115310]=true,[196718]=true,},
			{[115203]=true,[47585]=true,[108270]=true,[55342]=true,[48792]=true,[19236]=true,[1160]=true,[374348]=true,[48743]=true,[86659]=true,[184364]=true,[198589]=true,[498]=true,[110959]=true,[196555]=true,[22842]=true,[49028]=true,[235450]=true,[31224]=true,[122470]=true,[104773]=true,[11426]=true,[23920]=true,[198103]=true,[586]=true,[871]=true,[185311]=true,[49039]=true,[642]=true,[235219]=true,[108271]=true,[264735]=true,[12975]=true,[122278]=true,[109304]=true,[186265]=true,[108416]=true,[55233]=true,[118038]=true,[5277]=true,[194679]=true,[45438]=true,[342245]=true,[184662]=true,[363916]=true,[1966]=true,[61336]=true,[155835]=true,[22812]=true,[122783]=true,[48707]=true,[108238]=true,[132578]=true,[115176]=true,[205191]=true,[235313]=true,[31850]=true,},
			{[102342]=true,[116849]=true,[633]=true,[6940]=true,[357170]=true,[108968]=true,[10060]=true,[204018]=true,[33206]=true,[47788]=true,},
			{[101643]=true,[157981]=true,[102793]=true,[19801]=true,[372048]=true,[186387]=true,[111771]=true,[115315]=true,[406732]=true,[49576]=true,[383013]=true,[388007]=true,[132469]=true,[66]=true,[51490]=true,[278326]=true,[116844]=true,[408233]=true,[8143]=true,[5938]=true,[57934]=true,[235219]=true,[1044]=true,[360827]=true,[383269]=true,[16191]=true,[29166]=true,[370665]=true,[236776]=true,[64901]=true,[374251]=true,[32375]=true,[319454]=true,[108285]=true,[2908]=true,[342245]=true,[1856]=true,[328774]=true,[157980]=true,[205364]=true,[79206]=true,[34477]=true,[1022]=true,[119996]=true,},
			{[48018]=true,[79206]=true,[195457]=true,[389713]=true,[6544]=true,[1953]=true,[190784]=true,[48265]=true,[374968]=true,[36554]=true,[106898]=true,[252216]=true,[58875]=true,[196884]=true,[102401]=true,[73325]=true,[121536]=true,[212653]=true,[111771]=true,[192077]=true,[101545]=true,[186257]=true,[212552]=true,[370665]=true,[2983]=true,[1850]=true,[116841]=true,},
			{[201430]=true,[409311]=true,[384631]=true,[376079]=true,[10060]=true,[1719]=true,[152279]=true,[49206]=true,[387184]=true,[191427]=true,[375087]=true,[228260]=true,[193530]=true,[13750]=true,[114051]=true,[51271]=true,[359844]=true,[107574]=true,[381989]=true,[50334]=true,[42650]=true,[357210]=true,[47568]=true,[102558]=true,[403631]=true,[1856]=true,[260402]=true,[111898]=true,[190319]=true,[19574]=true,[279302]=true,[370965]=true,[194223]=true,[192249]=true,[383269]=true,[102543]=true,[123904]=true,[360194]=true,[34433]=true,[360952]=true,[12472]=true,[288613]=true,[121471]=true,[198067]=true,[186289]=true,[12051]=true,[265187]=true,[1122]=true,[205180]=true,[443028]=true,[207289]=true,[343142]=true,[196937]=true,[365350]=true,[31884]=true,[102560]=true,[46924]=true,[227847]=true,[137639]=true,[391528]=true,[106951]=true,[114050]=true,[385408]=true,},
			{[197214]=true,[376079]=true,[157997]=true,[372048]=true,[202137]=true,[383121]=true,[113724]=true,[192058]=true,[8122]=true,[179057]=true,[109248]=true,[30283]=true,[386071]=true,[51490]=true,[207684]=true,[99]=true,[116844]=true,[46968]=true,[187698]=true,[2484]=true,[31661]=true,[115750]=true,[108199]=true,[102359]=true,[120]=true,[78675]=true,[5246]=true,[191427]=true,[5484]=true,[198898]=true,[2094]=true,[207167]=true,[122]=true,[12323]=true,[108920]=true,[51485]=true,[119381]=true,[202138]=true,[358385]=true,},
			{[20066]=true,[2094]=true,[5211]=true,[360806]=true,[51514]=true,[217832]=true,[853]=true,[187650]=true,[6789]=true,[64044]=true,[19577]=true,[107570]=true,[22570]=true,[213691]=true,[305483]=true,[10326]=true,[221562]=true,[183218]=true,[408]=true,[162488]=true,[1776]=true,[115078]=true,[211881]=true,},
		},

		spellsCDAdditional = {
			{414658,"MAGE",3,{414658,180,6}},
			{48018,"WARLOCK",3,{48018,10,0}},
			{48020,"WARLOCK",3,{48020,30,0}},
			{451235,"PRIEST",3,{451235,120,15}},
		},

		OPTS_TTS = VMRT.Reminder.OptAssigTTS,
		OPTS_NOSPELLNAME = VMRT.Reminder.OptAssigNospellname,
		OPTS_MARKSHARED = VMRT.Reminder.OptAssigMarkShared,
		OPTS_SOUNDDELAY = VMRT.Reminder.OptAssigSoundDelay,
		OPTS_DURDEF = VMRT.Reminder.OptAssigDur or 3,
		OPTS_NOSPELLCD = VMRT.Reminder.OptAssigNospellcd,

		FILTER_SPELL_REP = VMRT.Reminder.OptAssigFSpellsRep,
		FILTER_REM_ONLYMY = VMRT.Reminder.OptAssigOnlyMy,
		FILTER_NOTE = VMRT.Reminder.OptAssigFNote,
	}

	VMRT.Reminder.OptAssigQFClass = self.assign.QFILTER_CLASS
	VMRT.Reminder.OptAssigQFRole = self.assign.QFILTER_ROLE
	VMRT.Reminder.OptAssigQFSpell = self.assign.QFILTER_SPELL
	VMRT.Reminder.OptAssigCustomCD = self.assign.custom_cd
	VMRT.Reminder.OptAssigSpellDisabled = self.assign.spell_status

	options.assign.GetTimeLineData = options.timeLine.GetTimeLineData

	options.assign.GetTimeForSpell = options.timeLine.GetTimeForSpell
	options.assign.GetSpellFromTime = options.timeLine.GetSpellFromTime
	options.assign.GetTimeUntilPhaseEnd = options.timeLine.GetTimeUntilPhaseEnd
	options.assign.GetTimeOnPhaseMulti = options.timeLine.GetTimeOnPhaseMulti
	options.assign.GetTimeOnPhase = options.timeLine.GetTimeOnPhase
	options.assign.GetPhaseFromTime = options.timeLine.GetPhaseFromTime
	options.assign.GetPhaseTotalCount = options.timeLine.GetPhaseTotalCount
	options.assign.GetPhaseCounter = options.timeLine.GetPhaseCounter
	options.assign.IsRemovedByTimeAdjust = options.timeLine.IsRemovedByTimeAdjust
	options.assign.GetTimeAdjust = options.timeLine.GetTimeAdjust
	options.assign.GetTimeFromPos = options.timeLine.GetTimeFromPos
	options.assign.GetPosFromTime = options.timeLine.GetPosFromTime
	options.assign.util_sort_by2 = options.timeLine.util_sort_by2
	options.assign.util_sort_reminders = options.timeLine.util_sort_reminders
	options.assign.ExportToString = options.timeLine.ExportToString
	options.assign.GetRemindersFromString = options.timeLine.GetRemindersFromString
	options.assign.ResetSavedVars = options.timeLine.ResetSavedVars
	options.assign.PrepareSavedVars = options.timeLine.PrepareSavedVars

	options.assign.OpenQuickSetupFrame = options.timeLine.OpenQuickSetupFrame

	function options.assign:IsPassFilterSpellType(spellData,spell)
		if
			(
			 ((spellData.spellType or 1) == 1 and not self.FILTER_CAST) or
			 (spellData.spellType == 2 and not self.FILTER_AURA)
			) and
			(not self.FILTER_SPELL or self.FILTER_SPELL[spell])
		then
			return true
		end
	end

	options.assign.GetRemindersList = options.timeLine.GetRemindersList

	options.assign.ResetAdjust = options.timeLine.ResetAdjust

	options.assign.CreateCustomTimelineFromHistory = options.timeLine.CreateCustomTimelineFromHistory

	function options.assign:GetSpellsCDList()
		local list = self.spellsCDList
		if not list then
			list = {}
			self.spellsCDList = list

			local cd_module = MRT.A.ExCD2
			for i=1,#cd_module.db.AllSpells do
				local line = cd_module.db.AllSpells[i]
				local class = strsplit(",",line[2])
				if MRT.GDB.ClassID[class or 0] and not line[2]:find("PVP") then
					list[#list+1] = line
				end
			end

			for i=1,#self.spellsCDAdditional do
				list[#list+1] = self.spellsCDAdditional[i]
			end

			if VMRT.ExCD2 and type(VMRT.ExCD2.userDB)=="table" then
				for i=1,#VMRT.ExCD2.userDB do
					local data = VMRT.ExCD2.userDB[i]
					if 	--Prevent any errors for userbased cds
						type(data[1]) == "number" and
						type(data[2]) == "string" and
						(data[4] or data[5] or data[6] or data[7] or data[8]) and
						((data[4] and data[4][1] and data[4][2] and data[4][3]) or not data[4]) and
						((data[5] and data[5][1] and data[5][2] and data[5][3]) or not data[5]) and
						((data[6] and data[6][1] and data[6][2] and data[6][3]) or not data[6]) and
						((data[7] and data[7][1] and data[7][2] and data[7][3]) or not data[7]) and
						((data[8] and data[8][1] and data[8][2] and data[8][3]) or not data[8])
					then
						local isInDBAlready
						for j=1,#list do
							if list[j][1] == data[1] then
								isInDBAlready = true
								break
							end
						end

						if not isInDBAlready then
							local class = strsplit(",",data[2])
							if MRT.GDB.ClassID[class or 0] and not data[2]:find("PVP") then
								list[#list+1] = data
							end
						end
					end
				end
			end
		end

		return list
	end

	function options.assign:GetSpellsCDListClass(class)
		if not self.spellsCDListClass then
			self.spellsCDListClass = {}
		end
		if self.spellsCDListClass[class] then
			return self.spellsCDListClass[class]
		end
		local list = {}
		self.spellsCDListClass[class] = list
		local AllSpells = self:GetSpellsCDList()
		for i=1,#AllSpells do
			local line = AllSpells[i]
			if strsplit(",",line[2]) == class or strsplit(",",line[2]) == "ALL" then
				list[#list+1] = line
			end
		end

		return list
	end

	function options.assign:UpdatePageWidth()
		local width = self.TL_PAGEWIDTH
		VMRT.Reminder.OptAssigWidth = width

		local left = ELib.ScrollDropDown.DropDownList[1]:GetLeft()
		local top = ELib.ScrollDropDown.DropDownList[1]:GetTop()
		ELib.ScrollDropDown.DropDownList[1]:ClearAllPoints()
		ELib.ScrollDropDown.DropDownList[1]:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",left,top)

		options.isWide = width
		MRT.Options.Frame:SetPage(MRT.Options.Frame.CurrentFrame,true)

		self.frame:Size((width-300)-((options.assign.TL_ASSIGNWIDTH + 10) * 2 + 5 + 15),self.frame:GetHeight())

		local width = self.frame.width_now
		self.frame:Width(width)
		if width > self.frame:GetWidth() then
			self.frame.ScrollBarHorizontal:Show()
		elseif self.frame.ScrollBarHorizontal:IsShown() then
			self.frame.ScrollBarHorizontal:SetValue(0)
			self.frame.ScrollBarHorizontal:Hide()
		end
	end

	self.assignBoss = ELib:DropDown(self.ASSIGNMENTS_TAB,250,-1):Point("TOPLEFT",10,-10):Size(220):SetText(LR["Select boss"])
	self.assignBoss.mainframe = options.assign
	self.assignBoss.UpdateText = self.timeLineBoss.UpdateText


	self.assignBoss.SetValue = AddonDB:WrapAsyncSingleton(defaultAsyncConfig, function(data)
		if TLbossMenu then
			TLbossMenu:Close()
		end
		ELib:DropDownClose()
		data = data.data or data

		options.assign.frame.bigBossButtons:Hide()

		module.db.simrun = nil
		wipe(options.assign.custom_phase)
		wipe(options.assign.reminder_hide)
		wipe(options.assign.custom_line)

		options.assign:ResetAdjust()

		options.assign.BOSS_ID = nil
		options.assign.ZONE_ID = nil
		options.assign.DIFF_ID = nil
		options.assign.CUSTOM_TIMELINE = nil
		VMRT.Reminder.TLBoss = nil
		options.assign.FILTER_SPELL = nil

		options.assign.var_draggedlastline = nil

		if data.bossID > 0 then
			options.assign.BOSS_ID = data.bossID
		else -- M+ timeline
			options.assign.ZONE_ID = -data.bossID
		end
		VMRT.Reminder.TLBoss = {bossID = data.bossID}

		local selectedTimeline = self.assign:GetTimeLineData()
		if data.tl then
			selectedTimeline = data.tl
			if selectedTimeline.m then
				selectedTimeline = selectedTimeline[1]
			end
		elseif data.fightData then
			options.assign.frame.initSpinner:Start(10)
			local tempHistory
			if type(data.fightData.log) == "string" then
				tempHistory = AddonDB.RestoreFromHistory(data.fightData.log)
			elseif type(data.fightData.log) == "table" then
				tempHistory = data.fightData.log
			end

			-- ddt(tempHistory)
			selectedTimeline = options.assign:CreateCustomTimelineFromHistory(tempHistory, data.fightData)
			options.assign.frame.initSpinner:Stop()
		end

		if selectedTimeline then
			options.assign.DIFF_ID = selectedTimeline.d and selectedTimeline.d[1]
			options.assign.CUSTOM_TIMELINE = selectedTimeline
		end

		local bossData = options.assign.Data[data.bossID]
		if bossData and bossData.m then
			for i=1,#bossData do
				if bossData[i] == selectedTimeline then
					VMRT.Reminder.TLBoss.dataIndex = i
					break
				end
			end
		end

		self.assignBoss:UpdateText()
		if not data.ignoreReload then
			options.assign:Update()
			data.tl = selectedTimeline
			data.ignoreReload = true
			options.timeLineBoss.SetValue(data)
		end
	end)


	self.assignBoss.Button:SetScript("OnClick",function(self)
		options.assignBoss:PreUpdate()
		TLbossMenu = MenuUtil.CreateContextMenu(options.assignBoss,menuGenerator)
	end)

	self.assignBoss.PreUpdate = self.timeLineBoss.PreUpdate
	self.assignBoss.SelectBoss = self.timeLineBoss.SelectBoss


	self.assignSettingsButton = MLib:DropDownButton(self.ASSIGNMENTS_TAB,SETTINGS,220,-1):Point("LEFT",self.assignBoss,"RIGHT",40,0):Size(140,20)
	function self.assignSettingsButton:SetFilterValue(arg1,arg2)
		ELib:DropDownClose()
		options.assign[arg1] = not options.assign[arg1]
		options.assign:Update()
		if arg2 then
			VMRT.Reminder[arg2] = options.assign[arg1]
		end
		if self.data and self.data.adjustTimelineOption then
			options.timeLine[arg1] = options.assign[arg1]
		end
	end
	function self.assignSettingsButton:SetValueTable(arg1)
		ELib:DropDownClose()
		if options.assign[arg1] then
			options.assign[arg1] = nil
		elseif arg1 == "FILTER_SPELL" then
			local filter = {}
			local data = options.assign.Data[options.assign.BOSS_ID]
			for _,e in next, (data.m and data or {data}) do
				if type(e) == "table" then
					for k in next, e do
						filter[k] = true
					end
				end
			end
			options.assign[arg1] = filter
		end
		options.assign:Update()
	end
	self.assignSettingsButton.List = {
		{
			text = "Assignment range for spell",
			isTitle = true,
		},{
			text = "",
			isTitle = true,
			slider = {min = 0, max = 60, val = options.assign.gluerange, afterText = " "..(SECONDS or "sec."), func = function(self,val)
				options.assign.gluerange = floor(val + .5)
				self:GetParent().data.slider.val = val
				options.assign:Update()
			end}
		},{
			text = " ",
			isTitle = true,
		},{
			text = "Line height",
			isTitle = true,
		},{
			text = "",
			isTitle = true,
			slider = {min = 3, max = 102, reset = 16, val = options.assign.TL_LINESIZE, func = function(self,val)
				options.assign.TL_LINESIZE = floor(val+0.5)
				options.assign:UpdateLineSize()
				self:GetParent().data.slider.val = val
			end}
		},{
			text = " ",
			isTitle = true,
		},{
			text = "Page width",
			isTitle = true,
		},{
			text = "",
			isTitle = true,
			slider = {min = 800, max = 1600, reset = 1000, val = options.assign.TL_PAGEWIDTH, func = function(self,val)
				options.assign.TL_PAGEWIDTH = floor(val+0.5)
				options.assign:UpdatePageWidth()
				self:GetParent().data.slider.val = val
			end}
		},{
			text = " ",
			isTitle = true,
		},{
			text = LR["Lines filters"],
			isTitle = true,
		},{
			text = LR.FilterCasts,
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_CAST",
			alter = true,
		},{
			text = LR.FilterAuras,
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_AURA",
			alter = true,
		},{
			text = LR.PresetFilter,
			checkable = true,
			func = self.assignSettingsButton.SetValueTable,
			arg1 = "FILTER_SPELL",
			hidF = function() if options.assign.Data[options.assign.BOSS_ID] and options.assign.CUSTOM_TIMELINE and options.assign.CUSTOM_TIMELINE.fightData then return true end end,
		},{
			text = " ",
			isTitle = true,
		},{
			text = LR["Reminders filters"],
			isTitle = true,
		},{
			text = LR["Show only reminders for filtered spells"],
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_SPELLS",
			arg2 = "OptAssigFSpells",
			alter = true,
		},{
			text = LR.OnlyMine,
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_REM_ONLYMY",
			arg2 = "OptAssigOnlyMy",
			adjustTimelineOption = true,
		},{
			text = LR.RepeatableFilter,
			tooltip = LR.RepeatableFilterTip,
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_SPELL_REP",
			arg2 = "OptAssigFSpellsRep",
			adjustTimelineOption = true,
			alter = true,
		},{
			text = LR["Simulate note timers"],
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "FILTER_NOTE",
			arg2 = "OptAssigFNote",
			tooltip = LR.SimNoteTimersTip,
		},{
			text = " ",
			isTitle = true,
		},{
			text = LR["New reminders options"],
			isTitle = true,
		},{
			text = "",
			isTitle = true,
			slider = {min = 1, max = 5, reset = 3, sliderText = function(_,val) return format("Duration: %d",val) end, val = options.assign.OPTS_DURDEF or 3, func = function(self,val)
				val = floor(val+0.5)
				self:GetParent().data.slider.val = val
				if val == 3 then val = nil end
				options.assign.OPTS_DURDEF = val
				VMRT.Reminder.OptAssigDur = val
			end}
		},
		{
			text = LR["Use TTS"],
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "OPTS_TTS",
			arg2 = "OptAssigTTS",
			alter = true,
		},
		{
			text = LR["Icon without spell name"],
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "OPTS_NOSPELLNAME",
			arg2 = "OptAssigNospellname",
			alter = false,
		},
		{
			text = LR["Don't check on spell CD"],
			checkable = true,
			func = self.assignSettingsButton.SetFilterValue,
			arg1 = "OPTS_NOSPELLCD",
			arg2 = "OptAssigNospellcd",
			alter = false,
		},
	}
	function self.assignSettingsButton:PreUpdate()
		for i=1,#self.List do
			local line = self.List[i]
			if line.func == self.SetFilterValue then
				line.checkState = (line.alter and not options.assign[line.arg1]) or (not line.alter and options.assign[line.arg1])
			elseif line.func == self.SetValueTable then
				line.checkState = options.assign[line.arg1]
			end
			if line.hidF then
				line.isHidden = not line.hidF()
			end
		end
	end


	self.assignAdjustFL = MLib:Button(self.ASSIGNMENTS_TAB,LR.AdjustFL):Point("LEFT",self.assignSettingsButton,"RIGHT",5,0):Size(140,20):OnEnter(function(self)
		self.subframe:Show()
	end)

	self.assignAdjustFL.subframe = CreateFrame("Frame",nil,self.assignAdjustFL)
	self.assignAdjustFL.subframe:SetPoint("TOPLEFT",self.assignAdjustFL,"BOTTOMLEFT",-40,2)
	self.assignAdjustFL.subframe:SetPoint("TOPRIGHT",self.assignAdjustFL,"BOTTOMRIGHT",40,2)
	self.assignAdjustFL.subframe:SetHeight(25+25*options.assign.TIMELINE_ADJUST_NUM)
	self.assignAdjustFL.subframe:Hide()
	self.assignAdjustFL.subframe:SetScript("OnUpdate",function(self)
		if not self:IsMouseOver() and not self:GetParent():IsMouseOver() then
			self:Hide()
		end
	end)
	self.assignAdjustFL.subframe.bg = self.assignAdjustFL.subframe:CreateTexture(nil,"BACKGROUND")
	self.assignAdjustFL.subframe.bg:SetAllPoints()
	self.assignAdjustFL.subframe.bg:SetColorTexture(0,0,0,1)

	self.assignAdjustFL.subframe.timeScale = ELib:Slider(self.assignAdjustFL.subframe):Size(100):Point("TOP",0,-5):Range(10,200,true):SetTo(options.assign.TIMELINE_ADJUST):OnChange(function(self,val)
		options.assign.TIMELINE_ADJUST = floor(val+0.5)
		if not self.lock then
			options.assign:Update()
		end
		self.tooltipText = LR.GlobalTimeScale..": "..options.assign.TIMELINE_ADJUST .. "%"
		self:tooltipReload(self)
	end)
	self.assignAdjustFL.subframe.timeScale.tooltipText = LR.GlobalTimeScale..": "..options.assign.TIMELINE_ADJUST .. "%"

	for i=1,options.assign.TIMELINE_ADJUST_NUM do
		options.assign.TIMELINE_ADJUST_DATA[i] = {0,0}
		self.assignAdjustFL.subframe["tpos"..i] = ELib:Edit(self.assignAdjustFL.subframe):Size(40,20):Point("TOPLEFT",35,-20-(i-1)*25):LeftText(LR.TimeScaleT1):Tooltip(LR.TimeScaleTip1):OnChange(function(self,isUser)
			if not isUser then return end
			local t = self:GetText() or ""
			t = module:ConvertMinuteStrToNum(t)
			options.assign.TIMELINE_ADJUST_DATA[i][1] = t and t[1] or nil

			options.assign:Update()
		end)

		self.assignAdjustFL.subframe["addtime"..i] = ELib:Edit(self.assignAdjustFL.subframe):Size(40,20):Point("LEFT",self.assignAdjustFL.subframe["tpos"..i],"RIGHT",55,0):LeftText(LR.TimeScaleT2):RightText(LR.TimeScaleT3):Tooltip(LR.TimeScaleTip2):OnChange(function(self,isUser)
			if not isUser then return end
			options.assign.TIMELINE_ADJUST_DATA[i][2] = tonumber(self:GetText() or "")

			options.assign:Update()
		end)
	end

	self.assignExportToNote = MLib:Button(self.ASSIGNMENTS_TAB,LR.ExportToNote):Point("LEFT",self.assignAdjustFL,"RIGHT",5,0):Size(140,20):OnClick(function()
		local str = options.assign:ExportToString()

		MRT.F:Export(str,true)
	end)


	self.assignImportFromNote = MLib:Button(self.ASSIGNMENTS_TAB,LR.ImportFromNote):Point("LEFT",self.assignExportToNote,"RIGHT",5,0):Size(140,20):OnClick(function()
		self.timeLineImportFromNoteFrame.mainframe = options.assign
		self.timeLineImportFromNoteFrame:Show()
	end)

	options.assign.UndoButton = MLib:Button(self.ASSIGNMENTS_TAB,LR.Undo):Tooltip(LR.UndoTip):Point("TOP",self.assignImportFromNote,"BOTTOM",0,0):Shown(false):Size(140,20):OnClick(function(self)
		for token in next, options.assign.undoimportlist.remove do
			VMRT.Reminder.data[token] = nil
		end
		for token,data in next, options.assign.undoimportlist.repair do
			VMRT.Reminder.data[token] = data
		end
		options.Update()
		module:ReloadAll()
		self:Hide()
	end)
	-- :OnShow(function(self)
	-- 	if self.tmr then
	-- 		self.tmr:Cancel()
	-- 	end
	-- 	self.tmr = C_Timer.NewTimer(30,function() self:Hide() end)
	-- end,true)

	self.assignSend = MLib:Button(self.ASSIGNMENTS_TAB,LR.Send):Point("LEFT",self.assignImportFromNote,"RIGHT",5,0):Size(140,20):OnClick(function()
		module:Sync(false,options.assign.BOSS_ID,options.assign.ZONE_ID)
	end)

	self.assignLive = MLib:Button(self.ASSIGNMENTS_TAB,LR["Start live session"]):Point("BOTTOM",self.assignSend,"TOP",0,10):Size(140,20):Tooltip(LR["Players will be invited to live session. Everyone who accept will able to add/change/remove reminders. All changes will be in shared profile, don't forget to copy them to any profile if you want to save them."]):OnClick(function()
		if module.db.isLiveSession then
			if module.db.liveSessionInitiated then
				module:StopLive()
			else
				module:StopLiveUser()
			end
		else
			module:StartLive(options.assign.BOSS_ID and {[options.assign.BOSS_ID]=true},options.assign.ZONE_ID)
		end
	end):OnShow(function(self) self:UpdateStatus() end,true)
	function self.assignLive:UpdateStatus()
		options.assignRevertLive:UpdateStatus()
		if module.db.isLiveSession then
			self:SetText(LR["|cff00ff00Live session is ON"])
			self.alert:Show()
		else
			self:SetText(LR["Start live session"])
			self.alert:Hide()
		end
		if module.db.isLiveSession then
			self:Enable()
			if not module.db.liveSessionInitiated then
				self:SetText(LR["|cffff0000Exit live session"])
			end
			return
		end
		if not IsInRaid() or AddonDB:CheckSelfPermissions() then
			self:Enable()
		else
			self:Disable()
		end
	end
	self.assignLiveAlert = ELib:Text(self,LR["Live session is on"],12):Color(0,1,0,1):Right():Shown(false):Point("TOPRIGHT",options,"TOPRIGHT",-60,-5)
	self.assignLive.alert = self.assignLiveAlert

	self.assignRevertLive = MLib:Button(self.ASSIGNMENTS_TAB,LR["Revert changes"]):Point("RIGHT",self.assignLive,"LEFT",-5,0):Size(140,20):OnClick(function()
		if not VMRT.Reminder.liveChanges then return end
		for token,data in next, VMRT.Reminder.liveChanges.changed do
			module:AddReminder(token,data)
		end
		for token in next, VMRT.Reminder.liveChanges.added do
			local data = VMRT.Reminder.data[token]
			if data then
				module:DeleteReminder(data,true,true)
			end
		end
		VMRT.Reminder.liveChanges = nil
		module:ReloadAll()
		options:Update()
		self.assignRevertLive:UpdateStatus()
	end):OnEnter(function(self)
		if not VMRT.Reminder.liveChanges then return end
		GameTooltip:SetOwner(self,"ANCHOR_TOP")
		GameTooltip:SetText(LR["Revert all changes made during last live session."])
		GameTooltip:AddLine(date("%X",VMRT.Reminder.liveChanges.time))
		GameTooltip:Show()
	end):OnLeave(GameTooltip_Hide)
	function self.assignRevertLive:UpdateStatus()
		if not module.db.isLiveSession and VMRT.Reminder.liveChanges and (next(VMRT.Reminder.liveChanges.added) or next(VMRT.Reminder.liveChanges.changed)) then
			self:Enable()
		else
			self:Disable()
		end
	end
	self.assignRevertLive:UpdateStatus()




	options.assign.frame = ELib:ScrollFrame(self.ASSIGNMENTS_TAB):Size(((options.assign.TL_PAGEWIDTH or 1000)-300)-((options.assign.TL_ASSIGNWIDTH + 10) * 2 + 5 + 15),494):Height(494):AddHorizontal(true):Width(1000)
	ELib:Border(options.assign.frame,0)

	options.assign.frame.headers = ELib:ScrollFrame(self.ASSIGNMENTS_TAB):Point("TOPLEFT",0,-50):Size(300,494):Height(474)
	ELib:Border(options.assign.frame.headers,0)

	options.assign.frame:Point("TOPLEFT",options.assign.frame.headers,"TOPRIGHT",0,0)

	options.assign.frame.QUICK_HEIGHT = 60 + 20 + 10
	options.assign.frame.quick = ELib:ScrollFrame(self.ASSIGNMENTS_TAB):Size(((options.assign.TL_ASSIGNWIDTH + 10) * 2 + 5 + 15),494-options.assign.frame.QUICK_HEIGHT):Height(100):Point("TOPLEFT",options.assign.frame,"TOPRIGHT",0,-options.assign.frame.QUICK_HEIGHT)
	ELib:Border(options.assign.frame.quick,0)
	options.assign.frame.quick.ScrollBar.thumb:SetHeight(60)

	options.assign.frame.D = CreateFrame("Frame",nil,options.assign.frame.C)
	options.assign.frame.D:SetAllPoints()
	options.assign.frame.D:SetFrameLevel(8000)

	--options.assign.frame.ScrollBar:Hide()
	options.assign.frame.headers.ScrollBar:Hide()

	options.assign.frame.lines = {}
	options.assign.frame.red = {}
	options.assign.frame.yellow = {}

	options.assign.frame:SetScript("OnVerticalScroll", function(self)
		options.assign.frame.headers:SetVerticalScroll( self:GetVerticalScroll() )
		options.assign:UpdateView()
	end)
	options.assign.frame.headers:SetScript("OnMouseWheel", function(self,delta)
		options.assign.frame:GetScript("OnMouseWheel")(options.assign.frame, delta)
	end)

	options.assign.frame.bg = options.assign.frame.C:CreateTexture(nil,"BACKGROUND",nil,-8)
	options.assign.frame.bg:SetColorTexture(23/255, 31/255, 33/255, 1)
	options.assign.frame.bg:SetPoint("TOPLEFT",0,0)
	options.assign.frame.bg:SetPoint("BOTTOM",0,0)
	options.assign.frame.bg:SetPoint("RIGHT",options,0,0)

	options.assign.frame.bg2 = options.assign.frame.C:CreateTexture(nil,"BACKGROUND",nil,-7)
	options.assign.frame.bg2:SetPoint("LEFT",options.assign.frame.bg,0,0)
	options.assign.frame.bg2:SetPoint("RIGHT",options.assign.frame.bg,0,0)
	options.assign.frame.bg2:SetPoint("TOP",0,0)
	options.assign.frame.bg2:SetPoint("BOTTOM",0,0)
	options.assign.frame.bg2:SetColorTexture(1,1,1, 1)
	options.assign.frame.bg2:SetGradient("VERTICAL",CreateColor(0,0,0,.2), CreateColor(0,0,0,0))


	options.assign.frame.bigBossButtons = CreateFrame("Button",nil,options.assign.frame)
	options.assign.frame.bigBossButtons:SetPoint("TOPLEFT",options.assign.frame.headers,0,0)
	options.assign.frame.bigBossButtons:SetPoint("BOTTOMRIGHT",options,0,0)
	options.assign.frame.bigBossButtons:SetFrameLevel(9000)
	options.assign.frame.bigBossButtons:SetFrameStrata("DIALOG")

	options.assign.frame.bigBossButtons.bg = options.assign.frame.bigBossButtons:CreateTexture(nil,"BACKGROUND",nil,-8)
	options.assign.frame.bigBossButtons.bg:SetColorTexture(0,0,0, 1)
	options.assign.frame.bigBossButtons.bg:SetAllPoints()

	options.assign.frame.bigBossButtons.buttons = {}
	options.assign.frame.bigBossButtons.Reset = options.timeLine.frame.bigBossButtons.Reset
	options.assign.frame.bigBossButtons.Repos = options.timeLine.frame.bigBossButtons.Repos

	options.assign.frame.bigBossButtons.Util_BottonOnEnter = options.timeLine.frame.bigBossButtons.Util_BottonOnEnter
	options.assign.frame.bigBossButtons.Util_BottonOnLeave = options.timeLine.frame.bigBossButtons.Util_BottonOnLeave
	options.assign.frame.bigBossButtons.Util_BottonOnClick = options.timeLine.frame.bigBossButtons.Util_BottonOnClick
	options.assign.frame.bigBossButtons.Add = options.timeLine.frame.bigBossButtons.Add

	options.assign.frame.initSpinner = MLib:LoadingSpinner(options.assign.frame):Size(60, 60):Point("CENTER", 0, 0)

	options.assign.frame:SetScript("OnUpdate",function(self)
		local x,y = MRT.F.GetCursorPos(self)

		if self.saved_x and self.saved_y then
			if self.ScrollBarHorizontal:IsShown() and abs(x - self.saved_x) > 5 then
				local newVal = self.saved_scroll - (x - self.saved_x)
				local min,max = self.ScrollBarHorizontal:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBarHorizontal:SetValue(newVal)

				self.moveSpotted = true
			end
			if self.ScrollBar:IsShown() and abs(y - self.saved_y) > 5 then
				local newVal = self.saved_scroll_v - (y - self.saved_y)
				local min,max = self.ScrollBar:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBar:SetValue(newVal)

				self.moveSpotted = true
			end
		end

		if self.dragging then
			self.draggingNow = nil

			y = ceil((y + self:GetVerticalScroll()) / options.assign.TL_LINESIZE)

			x = x + self:GetHorizontalScroll() - self.draggingX - 1

			local line = options.assign.linedata[y]

			if not (self:IsMouseOver() or self.headers:IsMouseOver()) then
				line = nil
			end

			if IsShiftKeyDown() and not self.draggingShowShift then
				self.dragging:_SetAlpha(1)
				self.draggingShowShift = true
			elseif not IsShiftKeyDown() and self.draggingShowShift then
				self.dragging:_SetAlpha(0)
				self.draggingShowShift = false
			end

			options.assign:Util_LineAssignRemoveSpace()
			if line then
				self.draggingNow = line

				local p = ceil( x / ( options.assign.TL_ASSIGNWIDTH + options.assign.TL_ASSIGNSPACING ) )
				if p < 1 then p = 1 end

				if p <= #line.a and self.dragging ~= line.a[p].frame then
					line.a[p].frame:AddSpace(true)
				elseif self.dragging.line ~= line or IsShiftKeyDown() then
					options.assign:Util_LineAssignAddPhantom(line)
				end

				if self.prevHL and self.prevHL ~= line then
					options.assign.Util_LineOnLeave(self.prevHL)
					self.prevHL = nil
				end
				if not self.prevHL then
					options.assign.Util_LineOnEnter(line.line)
					self.prevHL = line.line
				end
			else
				if self.prevHL then
					options.assign.Util_LineOnLeave(self.prevHL)
					self.prevHL = nil
				end
			end
		end
	end)


	options.assign.frame:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll = self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.ScrollBar:GetValue()
		self.moveSpotted = nil

	end)

	options.assign.frame:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil
		if self.moveSpotted then
			self.moveSpotted = nil
			return
		end

		if self.dragging then
			return
		end

		local x,y = MRT.F.GetCursorPos(self)
		x = x + self:GetHorizontalScroll()
		y = y + self:GetVerticalScroll()
		options.assign:ProcessClick(x, y, button)
	end)

	function options.assign:ProcessClick(x, y, button)
		y = ceil(y / self.TL_LINESIZE)

		local line = options.assign.linedata[y]
		if not line then
			return
		end
		if button == "RightButton" then
			return
		end
		self:ResetSavedVars()
		options.assign:AddNewReminderToLine(line, nil, true)
	end

	function options.assign:UpdateLineSize()
		VMRT.Reminder.OptAssigLineSize = self.TL_LINESIZE
		for i=1,#self.frame.lines do
			local line = self.frame.lines[i]
			line:SetHeight(self.TL_LINESIZE)
			line:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(i-1))

			line.header:SetHeight(self.TL_LINESIZE)
			line.header:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(i-1))

			line.header.trigger:SetSize(self.TL_LINESIZE-2, self.TL_LINESIZE-2)
			line.header.icon:SetSize(self.TL_LINESIZE,self.TL_LINESIZE)
		end
		for j=1,#self.frame.assigns do
			local a = self.frame.assigns[j]
			a:SetHeight(self.TL_LINESIZE-2)
			a.icon:SetHeight(self.TL_LINESIZE-2)
			if a.icon:GetTexture() then
				a.icon:SetWidth(self.TL_LINESIZE-2)
			end
			a.iconRight:SetWidth(self.TL_LINESIZE-2)
		end
		for i=1,self.frame.quick.COLS_NUM do
			self.frame.quick.COLS_NOW[i] = 0
		end
		for i=1,#self.frame.quick.pframes do
			local line = self.frame.quick.pframes[i]
			local c = 0
			for j=1,#line.btn do
				local a = line.btn[j]
				a:SetHeight(self.TL_LINESIZE-2)
				a.icon:SetHeight(self.TL_LINESIZE-2)
				if a.icon:GetTexture() then
					a.icon:SetWidth(self.TL_LINESIZE-2)
				end
				a.iconRight:SetWidth(self.TL_LINESIZE-2)
			end
		end
		self:PlayerListUpdate()
		if self.frame.phantom_assign then
			local a = self.frame.phantom_assign
			a:SetHeight(self.TL_LINESIZE-2)
			a.icon:SetHeight(self.TL_LINESIZE-2)
			if a.icon:GetTexture() then
				a.icon:SetWidth(self.TL_LINESIZE-2)
			end
			a.iconRight:SetWidth(self.TL_LINESIZE-2)
		end
		if self.frame.draggingAssign then
			local a = self.frame.draggingAssign
			a:SetHeight(self.TL_LINESIZE-2)
			a.icon:SetHeight(self.TL_LINESIZE-2)
			if a.icon:GetTexture() then
				a.icon:SetWidth(self.TL_LINESIZE-2)
			end
			a.iconRight:SetWidth(self.TL_LINESIZE-2)
		end
		self:Update()
	end

	options.assign.Util_HeaderOnClick = function(self,button)
		local x,y = MRT.F.GetCursorPos(self)
		local iconPos = self.icon:GetLeft() - self:GetLeft()
		if x < iconPos then
			MRT.F.ShowInput(LR["Add custom line(s) at +X seconds"],function(timestamp,t)
				t = module:ConvertMinuteStrToNum(t)
				if not t then return end
				for _,time in ipairs(t) do
					options.assign.custom_line[#options.assign.custom_line+1] = timestamp + time
				end
				options.assign:Update()
			end,self.data.time)
			return
		end
		if button == "RightButton" then
			if self.data.isCustom then
				for i=1,#options.assign.custom_line do
					if options.assign.custom_line[i] == self.data.isCustom then
						tremove(options.assign.custom_line, i)
						break
					end
				end
				options.assign:Update()
			end
		else
			options.assign.spell_status[self.spell] = not options.assign.spell_status[self.spell]
			options.assign:Update()
		end
	end

	options.assign.Util_HeaderOnEnter = function(self)
		if self.spell and self.spell ~= 0 then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:SetHyperlink("spell:"..self.spell )
			GameTooltip:Show()
		elseif self.tiptime then
			GameTooltip:SetOwner(self, "ANCHOR_LEFT")
			GameTooltip:AddLine(module:FormatTime(self.tiptime,true))
			GameTooltip:Show()
		end

		if not self.isOff then
			self.name:Color(unpack(options.assign.TL_HEADER_COLOR_HOVER))
		end
	end
	options.assign.Util_HeaderOnLeave = function(self)
		GameTooltip_Hide()

		self.name:Color(unpack(self.isOff and options.assign.TL_HEADER_COLOR_OFF or options.assign.TL_HEADER_COLOR_ON))
	end


	options.assign.Util_LineOnClick = function(self)
		--options.assign:AddNewReminderToLine(self,nil,true)
	end

	options.assign.Util_LineOnEnter = function(self)
		if not self.header.isOff then
			self.header.name:Color(unpack(options.assign.TL_HEADER_COLOR_HOVER))
		end
	end
	options.assign.Util_LineOnLeave = function(self)
		self.header.name:Color(unpack(self.header.isOff and options.assign.TL_HEADER_COLOR_OFF or options.assign.TL_HEADER_COLOR_ON))
	end

	options.assign.Util_LineAssignOnClick = function(self,button)
		if self.setup and self.setup.funcOnClick then return self.setup.funcOnClick(self.setup.funcOnClickArg) end
		if self.funcOnClick then self.funcOnClick(self) end
		if self.setup and button == "RightButton" then
			local spellName = GetSpellName(self.setup.spell)
			MRT.F.ShowInput2("Set custom options for " .. (spellName or self.setup.spell), function(res)
				local t = module:ConvertMinuteStrToNum(res[1])
				if not t then
					self.setup.cd = options.assign:GetSpellBaseCD(self.setup.spell)
					options.assign.custom_cd[self.setup.spell] = nil
				else
					self.setup.cd = t[1]
					options.assign.custom_cd[self.setup.spell] = t[1]
				end
				local c = tonumber(res[2] or 0)
				if type(c) == "number" and c > 1 then
					options.assign.custom_charges[self.setup.spell] = c
				else
					options.assign.custom_charges[self.setup.spell] = nil
				end
				self:UpdateFromData(self.setup, true)
			end, { text = LR["Cooldown:"], tip = LR["Leave empty for reset to default value"] }, { text = LR["Charges:"], tip = LR["Leave empty for reset to default value"] })
			return
		elseif self.setup then
			if options.assign.var_draggedlastline then
				options.assign:AddNewReminderToLine(options.assign.var_draggedlastline, self.setup)
			end
		end
		if not self.data then return end
		if button == "RightButton" then
			module:DeleteReminder(self.data, nil, nil, module.db.isLiveSession)
		else
			if self.data and self.data.fromNote then
				prettyPrint(LR["You can't edit reminder simulated from note"])
				return
			end
			options.assign:OpenQuickSetupFrame(self.timestamp, self.line.line, nil, self.data)
		end
	end

	function options.assign:GetSpellBaseCD(spell)
		if not self.spellsBaseCDs then
			self.spellsBaseCDs = {}
		end
		if self.spellsBaseCDs[spell] then
			return self.spellsBaseCDs[spell]
		end

		local AllSpells = self:GetSpellsCDList()
		for i=1,#AllSpells do
			local line = AllSpells[i]
			if line[1] == spell then
				for j=4,8 do
					if line[j] then
						self.spellsBaseCDs[spell] = line[j][2]
						return line[j][2]
					end
				end
			end
		end
	end

	options.assign.Util_LineAssignOnEnter = function(self)
		if self.funcOnEnter then self.funcOnEnter(self) end
		local data = self.data
		local timestamp = self.timestamp

		self:SetAlpha(.7)

		local spell = (data and options.assign:GetSpell(data)) or (self.setup and self.setup.spell)
		if spell then
			local cd = self.setup and self.setup.cd or options.assign.custom_cd[spell] or options.assign:GetSpellBaseCD(spell)
			if cd then
				options.assign.frame:ShowCD(spell,cd,(data and data.units) or (self.setup and self.setup.units))
			end
		end

		if self.setup then
			if self.setup.cd then
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				if self.setup.spell then
					GameTooltip:SetHyperlink("spell:"..self.setup.spell)
				end
				GameTooltip:AddLine(LR["CD: "]..module:FormatTime(self.setup.cd))
				if self.setup.spell and options.assign.custom_charges[self.setup.spell] then
					GameTooltip:AddLine(LR["Charges: "]..options.assign.custom_charges[self.setup.spell])
				end
				GameTooltip:Show()
			end
		end

		if not data then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		local p,pc,pd
		local dt = module:ConvertMinuteStrToNum(data.triggers[1].delayTime)
		if data.triggers[1].event == 2 then
			p = data.triggers[1].pattFind
			pc = data.triggers[1].counter
			-- pd = dt and options.assign:GetTimeOnPhase(dt[1],p,pc)
		elseif data.triggers[1].event == 1 and data.triggers[1].eventCLEU then
			local trigger = data.triggers[1]
			local name,_,texture = GetSpellInfo(trigger.spellID)
			local levent = module.C[trigger.eventCLEU].lname

			local desc = (trigger.counter and "["..trigger.counter.."]" or "")..(texture and "|T"..texture..":0|t" or "")..(name or "")
			-- local afterEnd = trigger.eventCLEU == "SPELL_AURA_REMOVED"
			-- pd = options.assign:GetTimeForSpell(dt and dt[1] or 0,trigger.spellID,trigger.counter,afterEnd,trigger.eventCLEU)
			GameTooltip:AddLine(levent ..": ".. desc)
		end
		if dt and data.triggers[1].event ~= 3 then
			GameTooltip:AddLine((p and LR["Phase "]..p..(pc and " (#"..pc..")" or "")..": " or "")..module:FormatTime(dt[1]))
		end
		if timestamp then
			GameTooltip:AddLine(LR["From start: "]..module:FormatTime(timestamp))
		end

		if data.units then
			local tip = LR["Players:"]
			for i,player in next, {strsplit("#",data.units or "")} do tip = tip .. player .. " " end
			GameTooltip:AddLine(tip)
		end
		if data.roles then
			local tip = LR["Roles:"]
			for i,role in next, {strsplit("#",data.roles or "")} do
				local roleData =  MRT.F.table_find3(module.datas.rolesList,role,3)
				role = roleData and roleData[2] or role

				tip = tip .. role .. " "
			end
			GameTooltip:AddLine(tip)
		end
		if data.classes then
			local tip = LR["Classes:"]
			for i,class in next, {strsplit("#",data.classes or "")} do
				local classLocalized = L.classLocalizate[class]
				tip = tip .. (RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr and "|c"..RAID_CLASS_COLORS[class].colorStr or "") .. classLocalized .. " "
			end
			GameTooltip:AddLine(tip)
		end
		if data.notepat then
		   GameTooltip:AddLine(LR["Note: "] .. data.notepat)
		end

		local output = ""

		if data.msg then
			output = output .. LR["Message: "] .. module:FormatMsg(data.msg) .. "\n"
		end

		if data.glow then
			output = output .. LR["Glow: "] .. module:FormatMsg(data.glow) .. "\n"
		end

		if data.tts then
			output = output .. LR["TTS: "] .. module:FormatMsg(data.tts) .. "\n"
		end
		if data.sound then
			output = output .. LR["Sound: "] .. (tostring(data.sound):match("([^\\/]+)$") or data.sound) .. "\n"
		end
		GameTooltip:AddLine(output)
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR["Left click - config"])
		GameTooltip:AddLine(LR["Shift+Left click - advanced config"])
		GameTooltip:AddLine(LR["Right click - remove"])
		GameTooltip:Show()
	end
	options.assign.Util_LineAssignOnLeave = function(self)
		if self.funcOnLeave then self.funcOnLeave(self) end
		GameTooltip_Hide()
		self:SetAlpha(1)

		options.assign.frame:ShowCD()
	end

	function options.assign:GetSpell(data)
		local spell = (data.msg or ""):match("^{spell:(%d+)}")
		if spell then
			return tonumber(spell)
		else
			return nil
		end
	end

	local hympOfHope_Spells = {
		[22812]=true,[198589]=true,[48792]=true,[204021]=true,[109304]=true,[55342]=true,
		[115203]=true,[19236]=true,[108271]=true,[104773]=true,[871]=true,[118038]=true,
		[184364]=true,[498]=true,[31850]=true,[185311]=true,[212800]=true,
		[403876]=true,[363916]=true,[243435]=true,[55233]=true,
	}

	options.assign.frame.hoveredNow = {}
	options.assign.frame.ShowCD = function(self,spell,length,names,cancelKey,doNotShowSelf)
		if not spell then
			if self.red.cancelKey and self.red.cancelKey ~= cancelKey then
				return
			end
			for i=1,#self.red do
				self.red[i]:Hide()
				self.red[i].h:Hide()
			end
			for i=1,#self.yellow do
				self.yellow[i]:Hide()
				self.yellow[i].h:Hide()
			end
			for k in next, self.hoveredNow do
				k:HoverBorder(false)
			end
			self.red.cancelKey = nil
			return
		end
		if self.red.cancelKey then
			return
		end
		if names and #names == 0 then
			names = nil
		end
		local filledRed = {}
		local yellowCheck = {}
		local chargesAv = {}
		local chargesCdD = {}
		local chargesMax = options.assign.custom_charges[spell] or 1
		local count = 0
		local linedata = options.assign.linedata
		for i=1,#linedata do
			local line = linedata[i]
			for j=1,#line.a do
				local a = line.a[j].frame
				if not line.isOff and a:IsShown() and a.data and options.assign:GetSpell(a.data) == spell and (not names or (names == a.data.units)) and ((not doNotShowSelf) or (doNotShowSelf ~= a)) then
					if not self.red then
						self.red = {}
					end
					count = count + 1
					local r = self.red[count]
					if not r then
						r = self.C:CreateTexture(nil,"BACKGROUND")

						self.red[count] = r

						r:SetColorTexture(1,.2,.2,.3)
						r:SetPoint("LEFT",self.headers,0,0)
						r:SetPoint("RIGHT",self,0,0)

						r.h = self.headers.C:CreateTexture(nil,"BACKGROUND")
						r.h:SetColorTexture(1,0,0,.2)
						r.h:SetPoint("LEFT",self.headers,0,0)
						r.h:SetPoint("RIGHT",self,0,0)
						r.h:SetPoint("TOP",r,0,0)
						r.h:SetPoint("BOTTOM",r,0,0)
					end

					r:SetPoint("TOP",0,-line.pos)

					local bottom
					local lengthNow = length
					if hympOfHope_Spells[spell] then
						for l=1,#line.a do
							local ba = line.a[l].frame
							if ba:IsShown() and ba.data and options.assign:GetSpell(ba.data) == 64901 then
								lengthNow = lengthNow - min(30,(a.timestamp + lengthNow) - ba.timestamp)
							end
						end
					end
					chargesAv[i] = (chargesAv[i] or chargesMax) - 1
					local cdStartTime = (chargesMax > 1 and chargesCdD[i]) or a.timestamp
					for k=i+1,#linedata do
						local bline = linedata[k]
						if hympOfHope_Spells[spell] and not bline.isOff then
							for l=1,#bline.a do
								local ba = bline.a[l].frame
								if ba:IsShown() and ba.data and options.assign:GetSpell(ba.data) == 64901 then
									lengthNow = lengthNow - min(30,(cdStartTime + lengthNow) - ba.timestamp)
								end
							end
						end
						if bline.time < cdStartTime + lengthNow and not bline.isOff then
							--bottom = bline

							--filledRed[bline] = true

							chargesCdD[k] = cdStartTime + lengthNow
							chargesAv[k] = (chargesAv[k] or chargesMax) - 1
							if (chargesAv[k] or chargesMax) <= 0 then
								bottom = bline
								filledRed[bline] = true
							end
						end
					end
					if (chargesAv[i] or chargesMax) <= 0 then
						filledRed[line] = true
					end

					if bottom then
						r:SetPoint("BOTTOM",self.C,"TOP",0,-bottom.pos-bottom.height)
					else
						r:SetPoint("BOTTOM",self.C,"TOP",0,-line.pos-line.height)
					end

					if (chargesAv[i] or chargesMax) == 0 then
						yellowCheck[#yellowCheck+1] = i
						yellowCheck[#yellowCheck+1] = a.timestamp
					end

					if (chargesAv[i] or chargesMax) <= 0 then
						r:Show()
						r.h:Show()
					else
						r:Hide()
						r.h:Hide()
					end

					a:HoverBorder(true)
					for k=j+1,#line.a do
						local a = line.a[k].frame
						if a:IsShown() and a.data and options.assign:GetSpell(a.data) == spell and (not names or (names == a.data.units)) and ((not doNotShowSelf) or (doNotShowSelf ~= a)) then
							a:HoverBorder(true)
						end
					end

					break
				end
			end
		end

		local c_y = 0
		for i=1,#yellowCheck,2 do
			local line_i = yellowCheck[i]
			local line = linedata[line_i]
			local timestamp = yellowCheck[i+1]
			local isPass
			local lengthNow = length
			for k=line_i-1,1,-1 do
				local bline = linedata[k]
				if hympOfHope_Spells[spell] and not bline.isOff then
					for l=1,#bline.a do
						local ba = bline.a[l].frame
						if ba:IsShown() and ba.data and options.assign:GetSpell(ba.data) == 64901 then
							lengthNow = lengthNow - min(30,timestamp - ba.timestamp)
						end
					end
				end
				if chargesMax > 1 then
					for l=1,#bline.a do
						local ba = bline.a[l].frame
						if ba:IsShown() and ba.data and options.assign:GetSpell(ba.data) == spell then
							--lengthNow = lengthNow + length
							--timestamp = ba.timestamp
						end
					end
				end
				if (bline.time > timestamp - lengthNow) and not bline.isOff then
					if filledRed[bline] then
						--isPass = false
						break
					end
					isPass = bline
				elseif bline.time < timestamp - lengthNow then
					break
				end
			end
			if isPass then
				c_y = c_y + 1
				local r = self.yellow[c_y]
				if not r then
					r = self.C:CreateTexture(nil,"BACKGROUND")

					self.yellow[c_y] = r

					r:SetColorTexture(1,1,.2,.2)
					r:SetPoint("LEFT",self.headers,0,0)
					r:SetPoint("RIGHT",self,0,0)

					r.h = self.headers.C:CreateTexture(nil,"BACKGROUND")
					r.h:SetColorTexture(1,1,0,.2)
					r.h:SetPoint("LEFT",self.headers,0,0)
					r.h:SetPoint("RIGHT",self,0,0)
					r.h:SetPoint("TOP",r,0,0)
					r.h:SetPoint("BOTTOM",r,0,0)
				end

				r:SetPoint("BOTTOM",self.C,"TOP",0,-line.pos)
				r:SetPoint("TOP",0,-isPass.pos)

				r:Show()
				r.h:Show()
			end
		end

		self.red.cancelKey = cancelKey
	end

	function options.assign:Util_LineAssignAddPhantom(line)
		local phantom = self.frame.phantom_assign
		if not phantom then
			phantom = self:Util_CreateLineAssign(self.frame.C)
			phantom.text:SetText("")
			phantom.icon:SetTexture()
			phantom.bg:SetColorTexture(1,1,1,1)
			phantom.bg:SetGradient("HORIZONTAL",CreateColor(.6,.6,.6,1), CreateColor(.25,.25,.25,.7))

			self.frame.phantom_assign = phantom
		end

		local pos = #line.a

		phantom:ClearAllPoints()
		if pos == 0 then
			phantom:SetPoint("TOPLEFT", 1, -line.pos)
		else
			phantom:SetPoint("LEFT",line.a[pos].frame, "RIGHT", options.assign.TL_ASSIGNSPACING, 0)
		end
		phantom:Show()
	end
	function options.assign:Util_LineAssignRemoveSpace()
		if options.assign.line_space_last then
			options.assign.line_space_last:AddSpace(false,true)
		end
		if options.assign.frame.phantom_assign then
			options.assign.frame.phantom_assign:Hide()
		end
	end
	function options.assign:Util_LineAssignAddSpace(isAdd,secondCall)
		if options.assign.line_space_last ~= self then
			options.assign:Util_LineAssignRemoveSpace()
		end
		if isAdd then
			if self.spaceisadded then return end
			self:SetWidth( options.assign.TL_ASSIGNWIDTH + options.assign.TL_ASSIGNWIDTH + options.assign.TL_ASSIGNSPACING )
			self.bg:SetPoint("TOPLEFT",(options.assign.TL_ASSIGNWIDTH + options.assign.TL_ASSIGNSPACING),0)
			if not secondCall then
				options.assign.line_space_last = self
			end
			self.spaceisadded = true
		else
			if not self.spaceisadded then return end
			self:SetWidth( options.assign.TL_ASSIGNWIDTH )
			self.bg:SetPoint("TOPLEFT",0,0)
			self.spaceisadded = false
		end
	end
	function options.assign:Util_LineAssignHoverBorder(isHover)
		if isHover then
			options.assign.frame.hoveredNow[self] = true
			ELib:Border(self.bg,2,.7,.7,.7,1,nil,10)
		else
			options.assign.frame.hoveredNow[self] = nil
			ELib:Border(self.bg,0,nil,nil,nil,nil,nil,10)
		end
	end

	function options.assign:Util_CreateLineAssign(parent)
		local a = CreateFrame("Button",nil,parent or self.frame.D)

		a:SetSize(self.TL_ASSIGNWIDTH, self.TL_LINESIZE-2)

		a.bg = a:CreateTexture(nil,"BACKGROUND")
		a.bg:SetPoint("TOPLEFT",0,0)
		a.bg:SetPoint("BOTTOMRIGHT",0,0)
		--local color = MRT.F.table_random(RAID_CLASS_COLORS)
		--a.bg:SetColorTexture(color.r,color.g,color.b)

		a.iconRight = a:CreateTexture(nil,"BACKGROUND",nil,2)
		a.iconRight:SetPoint("TOPRIGHT",0,0)
		a.iconRight:SetPoint("BOTTOMRIGHT",0,0)
		a.iconRight:SetWidth(self.TL_LINESIZE-2)

		a.icon = a:CreateTexture(nil, "ARTWORK")
		a.icon:SetSize(self.TL_LINESIZE-2,self.TL_LINESIZE-2)
		a.icon:SetPoint("LEFT",a.bg,0,0)
		a.icon:SetTexture(134399)

		a.text = ELib:Text(a,"Myname",10):Color(0,0,0):Outline():Shadow(true) -- :Point("TOPLEFT",a.icon,"TOPRIGHT",2,-2):Point("BOTTOMRIGHT",a,-2,2)
		a.text:Point("TOP",a.icon,"TOP",0,-2):Point("BOTTOM",a.icon,"BOTTOM",0,2):Point("LEFT",a.icon,"RIGHT",2,0):Point("RIGHT",a,-2,0)
		a.text:SetWordWrap(false)

		a.AddSpace = self.Util_LineAssignAddSpace

		a.UpdateFromData = self.Util_LineAssignUpdateFromData

		a:RegisterForClicks("LeftButtonUp","RightButtonUp")
		a:SetScript("OnClick",self.Util_LineAssignOnClick)
		a:SetScript("OnEnter",self.Util_LineAssignOnEnter)
		a:SetScript("OnLeave",self.Util_LineAssignOnLeave)

		a:SetMovable(true)
		a:RegisterForDrag("LeftButton")
		a:SetScript("OnDragStart", self.Util_AsignOnDragStart)
		a:SetScript("OnMouseDown", self.Util_AsignOnMouseDown)
		--a:SetScript("OnDragStop", self.Util_AsignOnDragStop)

		a._SetAlpha = a.SetAlpha
		a.HoverBorder = options.assign.Util_LineAssignHoverBorder

		return a
	end

	local assign_line_gragient_opts = {offset = 14}
	function options.assign:Util_LineAssignUpdateFromData(data,isSetup)
		local msg = data.msg or ""
		msg = msg:gsub("^{spell:%d+} *","")

		msg = module:FormatMsgForChat(module:FormatMsg(msg,nil,true))

		if msg == "" then
			msg = data.tts or ""
			msg = module:FormatMsgForChat(module:FormatMsg(msg))
		end
		msg = msg:trim()
		local spell = data.msg and data.msg:match("^{spell:(%d+)}")
		self.icon:SetTexture()
		self.icon:SetWidth(2)

		if spell then
			spell = tonumber(spell)
			local texture = GetSpellTexture(spell)
			if texture then
				self.icon:SetTexture(texture)
				self.icon:SetWidth(options.assign.TL_LINESIZE-2)
			end
		elseif type(data.msg) == "string" and module:FormatMsg(data.msg):find("|T.+|t") then
			local texture = tonumber(module:FormatMsg(data.msg):match("|T([^:|]+)") or "")
			if texture then
				self.icon:SetTexture(texture)
				self.icon:SetWidth(options.assign.TL_LINESIZE-2)
			end
		elseif (data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5) and data.barIcon then
			local spellID = tonumber(data.barIcon)
			if spellID == 0 then
				spellID = data.triggers[1].spellID or data.triggers[2].spellID
			end
			if spellID then
				local texture = GetSpellTexture(spellID)
				self.icon:SetTexture(texture)
				self.icon:SetWidth(options.assign.TL_LINESIZE-2)
			end
		end

		local color
		local multicolor
		if data.classes then
			for class in string.gmatch(data.classes,"[^#]+") do
				if RAID_CLASS_COLORS[class] then
					if not multicolor and color then
						multicolor = {CreateColor(color.r,color.g,color.b,1)}
					end

					color = RAID_CLASS_COLORS[class]

					if multicolor and color then
						multicolor[#multicolor+1] = CreateColor(color.r,color.g,color.b,1)
					end
				end
			end
		end

		if data.units and not isSetup then
			local any = false
			for k in string.gmatch(data.units,"[^#]+") do
				if not any then
					msg = k.. (msg ~= "" and ": ".. msg or "")
					any = true
				end

				if UnitClass(k) then
					color = RAID_CLASS_COLORS[select(2,UnitClass(k))] or color
					break
				end
			end
		end

		local roleicon
		if data.roles then
			for j=1,#module.datas.rolesList do
				if data.roles:find(module.datas.rolesList[j][3]) then
					roleicon = (roleicon or "")..(module.datas.rolesList[j][5] and "|A:"..module.datas.rolesList[j][5]..":0:0:|a" or "")
				end
			end
		end

		if multicolor then
			ELib:Gradient(self,assign_line_gragient_opts,unpack(multicolor))
			self.bg:SetColorTexture(1,1,1,0)
			ELib:Border(self.bg,0)
		elseif color then
			self.bg:SetColorTexture(color.r,color.g,color.b)
			ELib:Border(self.bg,0)
			ELib:Gradient(self)
		else
			self.bg:SetColorTexture(.1,.1,.1)
			ELib:Border(self.bg,1,.8,.8,.8,.8,-1)
			ELib:Gradient(self)
		end
		self.text:Color(1,1,1)

		local customCD
		if isSetup and spell and options.assign.custom_cd[spell] and options.assign.custom_cd[spell] == data.cd then
			customCD = module:FormatTime(options.assign.custom_cd[spell]).." "
		end

		self.text:SetText((roleicon or "")..(customCD or "")..msg)
	end

	options.assign.frame.assigns = {}
	local iconNotifAtlas = C_Texture.GetAtlasInfo("ShipMissionIcon-Bonus-MapBadge")
	function options.assign:Util_LineAddAssign(assign_num,data,line_data)
		local a
		for i=1,#self.frame.assigns do
			if not self.frame.assigns[i]:IsShown() then
				a = self.frame.assigns[i]
				break
			end
		end

		if not a then
			a = self:Util_CreateLineAssign()
			self.frame.assigns[#self.frame.assigns+1] = a
		end

		a.data = data
		a:UpdateFromData(data)
		a.timestamp = nil

		a._i = assign_num
		a.line = line_data

		if data and data.fromNote then
			a.iconRight:SetAtlas("transmog-wardrobe-border-selected-smoke")
			if iconNotifAtlas then
				a.iconRight:SetTexCoord(0,.75,0.125,0.875)
			end
			a.iconRight:Show()
		else
			a.iconRight:Hide()
		end

		line_data.a[assign_num].frame = a

		a:ClearAllPoints()
		if assign_num == 1 then
			a:SetPoint("TOPLEFT",1,-line_data.pos)
		else
			a:SetPoint("LEFT",line_data.a[assign_num - 1].frame,"RIGHT",self.TL_ASSIGNSPACING,0)
		end

		a:Show()

		return a
	end

	function options.assign:Util_AsignOnMouseDown()
		self.md_x, self.md_y = MRT.F.GetCursorPos(self)
	end

	function options.assign:Util_AsignOnDragStart()
		if not self:IsMovable() then
			return
		end
		if options.assign.frame.dragging then
			return
		end
		if self.setup and self.setup.notMovable then
			return
		end
		if self.funcOnDrag then self.funcOnDrag(self) end
		local da = options.assign.frame.draggingAssign
		if not da then
			da = options.assign:Util_CreateLineAssign(options.assign.frame)
			options.assign.frame.draggingAssign = da
			da:SetScript("OnUpdate", options.assign.Util_AsignOnDragStop)
			da:SetParent(options)
			da:SetFrameLevel(9000)
		end
		da:ClearAllPoints()
		da:SetPoint(self:GetPoint())

		local x,y = MRT.F.GetCursorPos(self)
		da:AdjustPointsOffset(x - self.md_x, -(y - self.md_y))

		da.data = self.data
		da.setup = self.setup
		da:UpdateFromData(self.data or self.setup)
		self:StopMovingOrSizing()

		self:_SetAlpha(0)
		self.SetAlpha = self.IsShown

		options.assign.frame.draggingNow = nil
		options.assign.frame.dragging = self
		options.assign.frame.draggingShowShift = nil

		options.assign.frame.draggingData = self.data
		options.assign.frame.draggingCopy = nil

		options.assign.frame.draggingX = x + (x - self.md_x)

		da:Show()
		da:StartMoving(true)

		options.assign.frame:ShowCD()
		local spell = (self.data and options.assign:GetSpell(self.data)) or (self.setup and self.setup.spell)
		if spell then
			local cd = self.setup and self.setup.cd or options.assign.custom_cd[spell] or options.assign:GetSpellBaseCD(spell)
			if cd then
				options.assign.frame:ShowCD(spell,cd,self.data and self.data.units or self.setup and self.setup.units,"DRAGGING",self)
			end
		end

		GameTooltip_Hide()
		C_Timer.After(.1,GameTooltip_Hide)
	end
	function options.assign:Util_AsignOnDragStop()
		local isCancel = IsMouseButtonDown("RightButton")
		if IsMouseButtonDown() and not isCancel then
			return
		end
		options.assign.frame.dragging:_SetAlpha(1)
		options.assign.frame.dragging.SetAlpha = options.assign.frame.dragging._SetAlpha
		options.assign.frame.dragging = nil

		self:StopMovingOrSizing()
		self:Hide()

		options.assign:Util_LineAssignRemoveSpace()
		options.assign.frame:ShowCD(nil, nil, nil, "DRAGGING")

		if options.assign.frame.draggingNow and not isCancel then
			options.assign:AddNewReminderToLine(options.assign.frame.draggingNow, self.setup, false, options.assign.frame.draggingData, IsShiftKeyDown())

			options.assign.var_draggedlastline = options.assign.frame.draggingNow
		end
	end

	function options.assign:AddNewReminderToLine(line, setup, window, existed, makeNew)
		local line_data = line

		local time = line_data.time
		self:PrepareSavedVars(time, line.line)

		local phase, x_phase, phaseCount, phaseGlobalCount = self.SAVED_VAR_P, self.SAVED_VAR_XP, self.SAVED_VAR_PC, self.SAVED_VAR_PGC

		local data
		if existed then
			data = MRT.F.table_copy2(existed)
		else
			data = MRT.F.table_copy2(module.datas.newReminderTemplate)
		end

		data.token = (not makeNew and data.token) or module:GenerateToken()
		data.durrev = true
		data.countdown = true

		data.zoneID = self.ZONE_ID
		data.boss = self.BOSS_ID
		data.diff = self.DIFF_ID

		if not data.triggers[1] then
			data.triggers[1] = {}
		end
		data.triggers[1].event = self.ZONE_ID and 20 or 3

		if phase and phase > 0 and (phaseGlobalCount ~= 1 or phase ~= 1) then -- and (phase ~= 1 or phaseCount)
			data.triggers[1].event = 2
			data.triggers[1].pattFind = tostring(phase)
			if phaseCount then
				data.triggers[1].counter = tostring(phaseCount)
			else
				data.triggers[1].counter = nil
			end

			time = x_phase
		elseif phase and phase < 0 and phase > -10000 then
			data.triggers[1].event = 3
			data.boss = -phase
			data.zoneID = nil
			time = x_phase
		end

		if setup then
			data.msg = setup.msg or nil
			data.classes = setup.classes or nil
			data.roles = setup.roles or nil
			data.units = setup.units or nil
			if setup.triggers and setup.triggers[2] then
				data.triggers[2] = setup.triggers[2]
			end
			data.hideTextChanged = setup.hideTextChanged
			if not self.OPTS_TTS then
				local msg = data.msg or ""
				local spell = msg:match("{spell:(%d+)")
				spell = spell and tonumber(spell)
				if spell then
					data.tts = GetSpellName(spell) or msg:gsub("{spell:%d+}", ""):trim()
				else
					data.tts = msg:gsub("{spell:%d+}", ""):trim()
				end
			end
			if self.OPTS_NOSPELLNAME and data.msg then
				data.msg = data.msg:gsub("^({spell:%d+}).-$", "%1")
			end

			if self.OPTS_NOSPELLCD then
				data.triggers[2] = nil
			end

			if self.OPTS_DURDEF then
				data.duration = self.OPTS_DURDEF
			end
		end

		local t = floor(time * 10) / 10
		data.triggers[1].delayTime = module:FormatTime(t, true)

		GenerateReminderName(data, makeNew)

		if window then
			if IsShiftKeyDown() then
				module:EditData(data)
				module.SetupFrame.mainframe = self
			else
				options.quickSetupFrame.mainframe = self
				options.quickSetupFrame:Update(data)
				options.quickSetupFrame:Show()
			end
		else
			module:AddReminder(data.token, data)

			options.assign:Update()
			module:ReloadAll()
		end
	end


	self.assign.frame.quick.pframes = {}
	self.assign.frame.quick.pframes_data = {}
	self.assign.frame.quick.COLS_NUM = 2
	self.assign.frame.quick.COLS_NOW = {}
	function options.assign:PlayerListReset()
		options.assign.frame.quick.lock = false
		for i=1,self.frame.quick.COLS_NUM do
			self.frame.quick.COLS_NOW[i] = 0
		end
		for i=1,#self.frame.quick.pframes do
			self.frame.quick.pframes[i]:Hide()
		end
		wipe(self.frame.quick.pframes_data)

		options.assign.frame.quick:Height(10)
		--options.assign.frame.quick:UpdateView()
	end

	function options.assign:IsPassQFilter(fliter_table,filterval)
		local isAny = false
		for k,v in next, fliter_table do
			if v then
				isAny = true
				break
			end
		end
		if not isAny then
			return true
		elseif type(filterval) == "table" then
			for k in next, filterval do
				if fliter_table[k] then
					return true
				end
			end
			return false
		elseif fliter_table[filterval] then
			return true
		else
			return false
		end
	end

	function options.assign.count_from_to(t,from,to)
		local c = 0
		for i=from,to do
			if t[i] then
				c = c + 1
			end
		end
		return c
	end

	function options.assign.do_search(where,what,exact)
		if type(what) == "table" then
			for i=1,#what do
				if (not exact and tostring(where or ""):lower():find(what[i],1,true)) or (exact and tostring(where or ""):lower() == what[i]) then
					return true
				end
			end
		else
			if (not exact and tostring(where or ""):lower():find(what,1,true)) or (exact and tostring(where or ""):lower() == what) then
				return true
			end
		end
		return false
	end

	local ROLE_TO_ROLE = {
		RANGE = "DAMAGER",
		MELEE = "DAMAGER",
		TANK = "TANK",
		HEAL = "HEALER",

		RDD = "DAMAGER",
		MDD = "DAMAGER",
		RHEALER = "HEALER",
		MHEALER = "HEALER",

		DAMAGER = "DAMAGER",
		HEALER = "HEALER",
	}

	function options.assign.addCustomSpellWindow(class)
		local alertWindow = options.assign.customSpellWindow
		if not alertWindow then
			alertWindow = ELib:Popup():Size(500,90)
			options.assign.customSpellWindow = alertWindow
			alertWindow:SetFrameStrata("FULLSCREEN_DIALOG")

			alertWindow.header = ELib:Text(alertWindow,"Temporarily add custom spell",10):Point("TOP",0,-1):Center()

			alertWindow.SpellIDDD = ELib:DropDown(alertWindow,200,-1):Size(200):Point("TOPLEFT",90,-15-0*20)

			function alertWindow.SpellIDDD:PreUpdate()
				wipe(self.List)

				local classLocName,_,classID = UnitClass'player'

				local tabsToCollect = {[classLocName or 0]=true}
				self.List[#self.List+1] = {
					text = classLocName,
					subMenu = {},
				}

				if not GetNumSpecializationsForClassID or not GetSpecializationInfoForClassID or not C_SpellBook then
					return
				end

				for spec=1,GetNumSpecializationsForClassID(classID) do
					local specName = select(2, GetSpecializationInfoForClassID(classID, spec))

					tabsToCollect[specName or 0] = true
					self.List[#self.List+1] = {
						text = specName,
						subMenu = {},
					}
				end

				local function SetValue(_,arg)
					ELib:DropDownClose()
					alertWindow.SpellID:SetText(arg)
					local cd = GetSpellBaseCooldown(arg)
					alertWindow.CD:SetText(cd/1000)
				end

				for tab=1,C_SpellBook.GetNumSpellBookSkillLines() do
					local skillLineInfo = C_SpellBook.GetSpellBookSkillLineInfo(tab)

					local tabName = skillLineInfo.name
					local offset = skillLineInfo.itemIndexOffset
					local numSlots = skillLineInfo.numSpellBookItems

					if tabName and tabsToCollect[tabName] then
						local subMenu = MRT.F.table_find3(self.List,tabName,"text")
						if subMenu then
							subMenu = subMenu.subMenu
							for i=offset+1,offset+numSlots do
								local spellData = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
								local spellID = spellData.spellID
								local isPassive = spellData.isPassive

								if spellID and not isPassive then
									subMenu[#subMenu+1] = {
										icon = spellData.iconID,
										text = spellData.name,
										arg1 = spellID,
										func = SetValue,
										tooltip = "spell:"..spellID
									}
								end
							end
						end
					end
				end
			end

			alertWindow.SpellID = ELib:Edit(alertWindow):Size(100,20):Point("LEFT",alertWindow.SpellIDDD,"RIGHT",70,0):LeftText("or Spell ID:"):OnChange(function(self)
				local text = self:GetText()
				text = tonumber(text or 0) or 0
				local spellName = GetSpellName(text)
				local spellTexture = GetSpellTexture(text)
				alertWindow.SpellIDDD:SetText("|T"..(spellTexture or "134400")..":0|t"..(spellName or ""))
				alertWindow.SpellID.t:SetText("|T"..(spellTexture or "134400")..":0|t"..(spellName or ""))
				alertWindow.SPELL_ID = text
			end)
			alertWindow.SpellID.t = ELib:Text(alertWindow.SpellID,"",12):Point("LEFT",alertWindow.SpellID,"RIGHT",5,0):Color():Left()
			alertWindow.CD = ELib:Edit(alertWindow):Size(200,20):Point("TOPLEFT",alertWindow.SpellIDDD,"BOTTOMLEFT",0,-5):LeftText("CD:"):OnChange(function(self)
				local text = self:GetText()
				text = tonumber(text or 0)
				alertWindow.SPELL_CD = text
			end)

			alertWindow.OK = MLib:Button(alertWindow,ACCEPT):Size(130,20):Point("BOTTOM",0,3):OnClick(function (self)
				alertWindow:Hide()

				if alertWindow.SPELL_ID and alertWindow.SPELL_ID ~= 0 then
					options.assign.custom_spells[alertWindow.SPELL_ID] = alertWindow.CLASS
					options.assign.custom_cd[alertWindow.SPELL_ID] = alertWindow.SPELL_CD

					local new = {alertWindow.SPELL_ID,alertWindow.CLASS,3,{alertWindow.SPELL_ID,alertWindow.SPELL_CD,0}}
					tinsert(options.assign.spellsCDListClass[alertWindow.CLASS],new)
					tinsert(options.assign.spellsCDList,new)

					options.assign:PlayerListUpdate()
				end
			end)
		end

		if class == select(2,UnitClass'player') then
			alertWindow.SpellIDDD:Show()
			alertWindow.SpellID:Point("LEFT",alertWindow.SpellIDDD,"RIGHT",70,0):LeftText("or Spell ID:"):Size(100,20)
			alertWindow.SpellID.t:Hide()
		else
			alertWindow.SpellIDDD:Hide()
			alertWindow.SpellID:Point("LEFT",alertWindow.SpellIDDD,"LEFT",0,0):LeftText("Spell ID:"):Size(200,20)
			alertWindow.SpellID.t:Show()
		end

		alertWindow.header:SetText(LR["Temporarily add custom spell"]..(MRT.GDB.ClassID[class or 0] and " for "..L.classLocalizate[class] or ""))

		alertWindow.SpellID:SetText("")
		alertWindow.SpellIDDD:SetText("")
		alertWindow.CD:SetText("")
		alertWindow.CLASS = class
		alertWindow.SPELL_ID = nil
		alertWindow.SPELL_CD = nil

		alertWindow:Show()
	end


	function options.assign:PlayerListAdd(name,class,spec,role)
		local new = {}

		local search = self.frame.quick.search

		local passSearch = false

		new.name = name or class and L.classLocalizate[class]
		if search then
			spec,role = nil
		end
		if search and options.assign.do_search(new.name,search) then
			passSearch = true
		end

		local list = {}
		if
			(not class or options.assign:IsPassQFilter(self.QFILTER_CLASS,class)) and
			(not role or options.assign:IsPassQFilter(self.QFILTER_ROLE,role))
		then
			local AllSpells = self:GetSpellsCDListClass(class)

			for i=1,#AllSpells do
				local line = AllSpells[i]
				for j=4,8 do
					local spell_role
					if j > 4 and MRT.GDB.ClassSpecializationList[class] then
						spell_role = ROLE_TO_ROLE[ MRT.GDB.ClassSpecializationRole[ MRT.GDB.ClassSpecializationList[class][j-4] or 0 ] or 0 ]
					elseif MRT.GDB.ClassSpecializationList[class] then
						local l = MRT.GDB.ClassSpecializationList[class]
						spell_role = {}
						for k=1,#l do
							local r = ROLE_TO_ROLE[ MRT.GDB.ClassSpecializationRole[ l[k] ] or 0 ]
							if r then spell_role[r] = true end
						end
					end

					local spell_filter
					if VMRT.Reminder.SpellGroups then
						for i=1,#VMRT.Reminder.SpellGroups.names do
							if VMRT.Reminder.SpellGroups[i][ line[1] ] then
								spell_filter = spell_filter or {}
								spell_filter[i] = true
							end
						end
					end
					if not spell_filter then
						spell_filter = -1
					end

					if
						line[j] and
						(name or (not spell_role or options.assign:IsPassQFilter(self.QFILTER_ROLE,spell_role))) and
						(not name or j == 4 or not role or spell_role == role) and
						options.assign:IsPassQFilter(self.QFILTER_SPELL,spell_filter)
					then
						local spellName = GetSpellName(line[1])
						if spellName and (not search or passSearch or (spellName and options.assign.do_search(spellName,search)) or options.assign.do_search(line[1],search,true)) then
							local setup = {
								msg = "{spell:"..line[1].."} "..(spellName or name),
								spell = line[1],
								cd = options.assign.custom_cd[ line[1] ] or line[j][2],
							}
							if name then
								setup.units = "#"..name.."#"
							end
							if class then
								setup.classes = "#"..class.."#"
							end
							if j > 4 and spell_role and options.assign.count_from_to(line,4,8) > 1 then
								local roles = 0
								for j=1,#module.datas.rolesList do
									if module.datas.rolesList[j][3] == spell_role then setup.roles = "#"..spell_role.."#" end
								end
							end
							if not name and options.assign.custom_cd[ line[1] ] then
								setup.cd = options.assign.custom_cd[ line[1] ]
							end
							setup.triggers = {}
							setup.triggers[2] = {
								event = 13,
								spellID = line[1],
								invert = true,
							}
							setup.hideTextChanged = true

							list[#list+1] = {setup,line[1],spellName or tostring(line[1] or 0)}
						end
					end
				end
			end
		end
		if #list == 0 then
			return
		end

		sort(list,function(a,b) if a[3]~=b[3] then return a[3]<b[3] else return a[2]<b[2] end end)

		if class and not search and options.assign:IsPassQFilter(self.QFILTER_SPELL,-1) then
			list[#list+1] = {{funcOnClick=self.addCustomSpellWindow,funcOnClickArg = class,msg = "+custom",notMovable=true},0,"+custom"}
		end

		new.list = list

		local c = #list

		new.height = 20 + (self.TL_LINESIZE-2 + 2)*c + 5

		local col = 1
		for i=1,self.frame.quick.COLS_NUM do
			if self.frame.quick.COLS_NOW[i] < self.frame.quick.COLS_NOW[col] then
				col = i
			end
		end

		new.pos = self.frame.quick.COLS_NOW[col]
		new.col = col

		if c > 0 then
			self.frame.quick.COLS_NOW[col] = self.frame.quick.COLS_NOW[col] + new.height + 5
		end

		local height = 0
		for i=1,self.frame.quick.COLS_NUM do
			height = max(height,self.frame.quick.COLS_NOW[i])
		end

		self.frame.quick:Height(height)
		self.frame.quick.ScrollBar:SetShown(height > self.frame.quick:GetHeight())

		if c > 0 then
			self.frame.quick.pframes_data[#self.frame.quick.pframes_data+1] = new
		end
		self.frame.quick:UpdateView()
	end

	function options.assign.frame.quick:OnUpdate()
	  	local x,y = MRT.F.GetCursorPos(self)

		if self.saved_x and self.saved_y then
			if self.ScrollBarHorizontal and self.ScrollBarHorizontal:IsShown() and abs(x - self.saved_x) > 5 then
				local newVal = self.saved_scroll - (x - self.saved_x)
				local min,max = self.ScrollBarHorizontal:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBarHorizontal:SetValue(newVal)

				self.moveSpotted = true
			end
			if self.ScrollBar:IsShown() and abs(y - self.saved_y) > 5 then
				local newVal = self.saved_scroll_v - (y - self.saved_y)
				local min,max = self.ScrollBar:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBar:SetValue(newVal)

				self.moveSpotted = true
			end
		end
	end

	options.assign.frame.quick:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll = self.ScrollBarHorizontal and self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.ScrollBar:GetValue()
		self.moveSpotted = nil

		self:SetScript("OnUpdate",self.OnUpdate)
	end)

	options.assign.frame.quick:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil

		if self.moveSpotted then
			self.moveSpotted = nil
			self:SetScript("OnUpdate",nil)
			return
		end
	end)

	options.assign.frame.quick.CDFrame = CreateFrame("Frame",nil,options.assign.frame.quick)
	options.assign.frame.quick.CDFrame:SetSize(90,32)
	options.assign.frame.quick.CDFrame:Hide()
	options.assign.frame.quick.CDFrame:SetFrameLevel(1000)
	options.assign.frame.quick.CDFrame:EnableMouse(true)
	options.assign.frame.quick.CDFrame:SetScript("OnUpdate",function(self)
		if not self.parent or not self.parent:IsVisible() then
			self:Hide()
		end
		local x,y = MRT.F.GetCursorPos(self)
		local xp,yp = MRT.F.GetCursorPos(self.parent)
		if (xp < -5 or xp > self.parent:GetWidth() + 5 or yp < -5 or yp > self.parent:GetHeight() + 5) and (x < -10 or x > self:GetWidth() + 10 or y < -10 or y > self:GetHeight() + 10) then
			self:Hide()
		elseif options.assign.frame.quick.ScrollBar.thumb:IsMouseOver() and (x < 0 or x > self:GetWidth() or y < 0 or y > self:GetHeight()) then
			self:Hide()
		end
	end)
	options.assign.frame.quick.CDFrame.bg = options.assign.frame.quick.CDFrame:CreateTexture(nil,"BACKGROUND")
	options.assign.frame.quick.CDFrame.bg:SetAllPoints()
	options.assign.frame.quick.CDFrame.bg:SetColorTexture(0,0,0,1)
	ELib:Border(options.assign.frame.quick.CDFrame,1,.24,.25,.30,1)

	options.assign.frame.quick.CDFrame.icon = options.assign.frame.quick.CDFrame:CreateTexture(nil,"ARTWORK")
	options.assign.frame.quick.CDFrame.icon:SetPoint("TOPLEFT",2,-2)
	options.assign.frame.quick.CDFrame.icon:SetSize(14,14)

	options.assign.frame.quick.CDFrame.CD = ELib:Edit(options.assign.frame.quick.CDFrame):Size(40,16):Point("TOPLEFT",50,0):LeftText("CD:",9):FontSize(9):Tooltip("Used only for visual red/yellow lines. Leave empty for reset to default"):OnChange(function(self,isUser)
		if not isUser then return end
		local t = self:GetText() or ""
		t = module:ConvertMinuteStrToNum(t)
		t = t and t[1]
		local parent = self:GetParent().parent
		local setup = parent.setup
		setup.cd = t or options.assign:GetSpellBaseCD(setup.spell)
		options.assign.custom_cd[ setup.spell ] = t
		parent:UpdateFromData(setup, true)
		for i=1,#options.assign.frame.quick.pframes_data do
			local data = options.assign.frame.quick.pframes_data[i]
			for i=1,#data.list do
				local setup2 = data.list[i][1]

				if setup2.spell == setup.spell then
					setup2.cd = setup.cd
				end
			end
		end
		for i=1,#options.assign.frame.quick.pframes do
			local line = options.assign.frame.quick.pframes[i]
			local c = 0
			for j=1,#line.btn do
				local a = line.btn[j]
				if a.setup and a.setup.spell == setup.spell then
					a:UpdateFromData(a.setup, true)
				end
			end
		end
	end)

	options.assign.frame.quick.CDFrame.Charges = ELib:Edit(options.assign.frame.quick.CDFrame):Size(40,16):Point("TOPLEFT",50,-16):LeftText("Charges:",9):FontSize(9):Tooltip("Used only for visual red/yellow lines. Leave empty for reset to default"):OnChange(function(self,isUser)
		if not isUser then return end
		local t = self:GetText() or ""
		t = tonumber(t)
		local setup = self:GetParent().parent.setup
		options.assign.custom_charges[setup.spell] = t
	end)

	function options.assign:Util_AssignSetupOnEnter()
	  	if not self.setup then
			return
		end
		local spell = self.setup.spell
		if not spell then
			return
		end
		if IsMouseButtonDown() then
			return
		end
		options.assign.frame.quick.CDFrame.parent = self
		options.assign.frame.quick.CDFrame:SetPoint("TOPLEFT",self,"BOTTOMRIGHT",0,5)
		local texture = GetSpellTexture(spell)
		options.assign.frame.quick.CDFrame.icon:SetTexture(texture)
		options.assign.frame.quick.CDFrame.CD:SetText( module:FormatTime(self.setup.cd) )
		options.assign.frame.quick.CDFrame.Charges:SetText( tostring(options.assign.custom_charges[spell] or 1) )
		options.assign.frame.quick.CDFrame.CD:ClearFocus()
		options.assign.frame.quick.CDFrame.Charges:ClearFocus()
		options.assign.frame.quick.CDFrame:Show()
	end
	function options.assign:Util_AssignSetupOnDrag()
		options.assign.frame.quick.CDFrame:Hide()
	end

	function options.assign.frame.quick:UpdateView(forceUnderLock)
		if self.lock and not forceUnderLock then return end
		local pos = self:GetVerticalScroll()

		local c = 0
		for i=1,#self.pframes_data do
			local data = self.pframes_data[i]
			if data.pos + data.height >= pos and data.pos <= pos+self:GetHeight() then
				c = c + 1

				local a = self.pframes[c]

				if not a then
					a = CreateFrame("Frame",nil,self.C)
					self.pframes[c] = a

					a:SetSize(options.assign.TL_ASSIGNWIDTH + 10, 80)
					a.btn = {}

					a.name = ELib:Text(a,"",12):Point("TOP",0,-2):Color()

					a._i = pos
				end

				a.name:SetText(data.name)

				local cb = 0
				for i=1,#data.list do
					cb = cb + 1
					local b = a.btn[cb]
					if not b then
						b = options.assign:Util_CreateLineAssign(a)

						b.funcOnEnter = options.assign.Util_AssignSetupOnEnter
						b.funcOnLeave = options.assign.Util_AssignSetupOnLeave
						b.funcOnDrag = options.assign.Util_AssignSetupOnDrag

						a.btn[cb] = b

					end
					b:SetPoint("TOP",0,-20-(cb-1)*(options.assign.TL_LINESIZE-2 + 2))

					b.setup = data.list[i][1]

					b:UpdateFromData(b.setup, true)
					b:Show()
				end
				for j=cb+1,#a.btn do
					a.btn[j]:Hide()
				end

				a:SetHeight(data.height)

				a:ClearAllPoints()
				a:SetPoint("TOPLEFT",(data.col - 1) * (options.assign.TL_ASSIGNWIDTH + 10 + 5),-data.pos)

				a:Show()
			end
		end
		for i=c+1,#self.pframes do
			self.pframes[i]:Hide()
		end
	end

	options.assign.frame.quick:SetScript("OnVerticalScroll", function(self)
		self:UpdateView()
	end)


	function options.assign:PlayerListUpdateFromRoster()
		self:PlayerListReset()
		self.frame.quick.lock = true
		for _, name, subgroup, class, guid, rank, level, online, isDead, combatRole in MRT.F.IterateRoster, MRT.F.GetRaidDiffMaxGroup() do
			name = MRT.F.delUnitNameServer(name)

			if combatRole == "NONE" then
				combatRole = nil
				if name == MRT.SDB.charName and GetSpecializationInfo and GetSpecialization then
					combatRole = select(5,GetSpecializationInfo(GetSpecialization()))
				end
			end

			self:PlayerListAdd(name,class,nil,combatRole)
		end
		self.frame.quick.lock = false
		self.frame.quick:UpdateView()
	end

	function options.assign:PlayerListUpdateFromGuild()
		self:PlayerListReset()
		local guildList = {}
		for i=1, GetNumGuildMembers() do
			local name, _, rankIndex, level, _, _, _, _, _, _, class = GetGuildRosterInfo(i)

			name = MRT.F.delUnitNameServer(name)

			guildList[#guildList+1] = {name,class,rankIndex}
		end
		sort(guildList,function(a,b)
			if a[3] == b[3] then
				return a[1] < b[1]
			else
				return a[3] < b[3]
			end
		end)

		if #guildList > 500 then
			local uid = debugprofilestop()
			self.coroutine_uid = uid
			MRT.F:AddCoroutine(function()
				self.frame.quick.lock = true
				for i=1, #guildList do
					self:PlayerListAdd(guildList[i][1],guildList[i][2],nil,nil)
					if i % 100 == 0 then
						self.frame.quick:UpdateView(true)
					end
					if i % 50 == 0 then
						options.assign.frame.quick.dd:SetText(format("%d/%d",i,#guildList))
						coroutine.yield()
						if self.coroutine_uid ~= uid then
							return
						end
					end
				end
				self.frame.quick.lock = false
				self.frame.quick:UpdateView()

				options.assign.frame.quick.dd:AutoText(options.assign.frame.quick.last)
			end)
		else
			self.frame.quick.lock = true
			for i=1, #guildList do
				self:PlayerListAdd(guildList[i][1],guildList[i][2],nil,nil)
			end
			self.frame.quick.lock = false
			self.frame.quick:UpdateView()
		end
	end

	function options.assign:PlayerListUpdateAllClasses()
		self:PlayerListReset()
		self.frame.quick.lock = true
		for i=1,#MRT.GDB.ClassList do
			self:PlayerListAdd(nil,MRT.GDB.ClassList[i],nil,nil)
		end
		self.frame.quick.lock = false
		self.frame.quick:UpdateView()
	end

	function options.assign:PlayerListUpdateFromSavedRoster()
		self:PlayerListReset()
		self.frame.quick.lock = true
		for i=1,#VMRT.Reminder.CustomRoster do
			local name, class, role = unpack(VMRT.Reminder.CustomRoster[i])

			if name and class then
				if role then role = ROLE_TO_ROLE[role] end

				self:PlayerListAdd(name,class,nil,role)
			end

		end
		self.frame.quick.lock = false
		self.frame.quick:UpdateView()
	end

	options.assign.frame.quick.last = VMRT.Reminder.OptAssigLastQuick
	function options.assign:PlayerListUpdate()
		if self.frame.quick.last == 1 or not self.frame.quick.last then
			self:PlayerListUpdateFromRoster()
		elseif self.frame.quick.last == 3 then
			self:PlayerListUpdateFromGuild()
		elseif self.frame.quick.last == 4 then
			self:PlayerListUpdateFromSavedRoster()
		else
			self:PlayerListUpdateAllClasses()
		end
	end
	function options.assign:PlayerListUpdateOnShow()
		if self.frame.quick.last == 1 or not self.frame.quick.last then
			self:PlayerListUpdateFromRoster()
		end
	end
	--options.assign:PlayerListUpdate()


	options.assign.frame.quick.filter = CreateFrame("Frame",nil,self.ASSIGNMENTS_TAB)
	options.assign.frame.quick.filter:SetPoint("TOPLEFT",options.assign.frame,"TOPRIGHT",0,-10)
	options.assign.frame.quick.filter:SetSize(options.assign.frame.quick:GetWidth(),options.assign.frame.QUICK_HEIGHT)

	function options.assign:UpdateQFilter()
		for _,t in next, ({{self.QFILTER_CLASS,self.frame.quick.filter.class},{self.QFILTER_ROLE,self.frame.quick.filter.role},{self.QFILTER_SPELL,self.frame.quick.filter.filterbutton}}) do
			local fliter_table = t[1]
			local isAny = false
			for k,v in next, fliter_table do
				if v then
					isAny = true
					break
				end
			end

			for _,b in next, t[2] do
				if not isAny or fliter_table[b.filter] then
					b:UpdateState(true)
				else
					b:UpdateState(false)
				end
			end
		end

		options.assign:PlayerListUpdate()
		if not options.assign.FILTER_SPELLS and options.assign.Update then
			options.assign:Update()
		end
	end

	function options.assign:Util_QuickFilterButtonOnClick(button)
		local fliter_table = options.assign["QFILTER_"..self.fheader]
		if button == "RightButton" then
			for k,v in next, fliter_table do fliter_table[k] = nil end
			fliter_table[self.filter] = true
		else
			fliter_table[self.filter] = not fliter_table[self.filter]
		end

		options.assign:UpdateQFilter()
	end
	function options.assign:Util_QuickFilterButtonOnEnter()
		self:SetAlpha(.7)
	end
	function options.assign:Util_QuickFilterButtonOnLeave()
		self:SetAlpha(1)
	end

	function options.assign:Util_QuickFilterButtonUpdateState(isOn)
		if isOn then
			self.icon:SetAlpha(1)
			self.icon:SetVertexColor(1,1,1)
		else
			self.icon:SetAlpha(.3)
			self.icon:SetVertexColor(1,.5,.5)
		end
	end
	function options.assign:Util_QuickFilterButtonUpdateStateCheck(isOn)
		if isOn then
			self:SetChecked(true)
		else
			self:SetChecked(false)
		end
	end

	options.assign.frame.quick.filter.class = {}
	options.assign.frame.quick.filter.role = {}
	options.assign.frame.quick.filter.filterbutton = {}

	for i=1,#MRT.GDB.ClassList do
		local b = CreateFrame("Button",nil,options.assign.frame.quick.filter)
		options.assign.frame.quick.filter.class[i] = b
		b:SetSize(26,26)
		b:SetPoint("TOPLEFT",2+((i-1)%8)*28,-(floor((i-1)/8)*28))

		b.icon = b:CreateTexture(nil,"BACKGROUND")
		b.icon:SetPoint("CENTER")
		b.icon:SetSize(26,26)
		b.icon:SetAtlas("classicon-"..MRT.GDB.ClassList[i]:lower())

		b.fheader = "CLASS"
		b.filter = MRT.GDB.ClassList[i]

		b:RegisterForClicks("LeftButtonUp","RightButtonUp")
		b:SetScript("OnClick",options.assign.Util_QuickFilterButtonOnClick)
		b:SetScript("OnEnter",options.assign.Util_QuickFilterButtonOnEnter)
		b:SetScript("OnLeave",options.assign.Util_QuickFilterButtonOnLeave)

		b.UpdateState = options.assign.Util_QuickFilterButtonUpdateState
	end
	for i,role in next, ({{"DAMAGER",MRT.isClassic and "UI-LFG-RoleIcon-DPS" or "UI-Frame-DpsIcon"},{"HEALER",MRT.isClassic and "UI-LFG-RoleIcon-Healer" or "UI-Frame-HealerIcon"},{"TANK",MRT.isClassic and "UI-LFG-RoleIcon-Tank" or "UI-Frame-TankIcon"}}) do
		local b = CreateFrame("Button",nil,options.assign.frame.quick.filter)
		options.assign.frame.quick.filter.role[i] = b
		b:SetSize(26,26)
		local j = #MRT.GDB.ClassList + i
		b:SetPoint("TOPLEFT",2+((j-1)%8)*28,-(floor((j-1)/8)*28))

		b.icon = b:CreateTexture(nil,"ARTWORK")
		b.icon:SetPoint("CENTER")
		b.icon:SetSize(26,26)
		b.icon:SetAtlas(role[2])

		b.fheader = "ROLE"
		b.filter = role[1]

		b:RegisterForClicks("LeftButtonUp","RightButtonUp")
		b:SetScript("OnClick",options.assign.Util_QuickFilterButtonOnClick)
		b:SetScript("OnEnter",options.assign.Util_QuickFilterButtonOnEnter)
		b:SetScript("OnLeave",options.assign.Util_QuickFilterButtonOnLeave)

		b.UpdateState = options.assign.Util_QuickFilterButtonUpdateState
	end


	options.assign.frame.quick.filter.editgroupsbut = ELib:ButtonIcon(options.assign.frame.quick.filter,MRT.isClassic and "charactercreate-icon-customize-speechbubble" or "GM-icon-settings-hover",true):Size(20,20):IconSize(2):Point("TOPRIGHT",-5,-55):OnClick(function() options.assign.frame.quick.edit:Show() end):Tooltip("Edit spell groups"):VisualHover()


	options.assign.frame.quick.filter.searchEditBox = ELib:Edit(options.assign.frame.quick.filter):Point("BOTTOM",options.assign.frame.quick,"TOP",0,2):Size(200,16):AddSearchIcon():OnChange(function (self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():lower()
		if text == "" then
			text = nil
		else
			if text:find(",") then
				text = {strsplit(",",text)}
				for i=#text,1,-1 do
					if text[i] == "" then
						tremove(text,i)
					end
				end
				if #text == 0 then
					text = nil
				end
			end
		end
		options.assign.frame.quick.search = text

		if self.scheduledUpdate then
			return
		end
		self.scheduledUpdate = C_Timer.NewTimer(.3,function()
			self.scheduledUpdate = nil
			options.assign:PlayerListUpdate()
		end)
	end):Tooltip(SEARCH)

	function options.assign.frame.quick.filter:Update()
		if not VMRT.Reminder.SpellGroups then
			VMRT.Reminder.SpellGroups = MRT.F.table_copy2(options.assign.SpellGroups_Presetup)
		end
		if not VMRT.Reminder.CustomRoster then
			VMRT.Reminder.CustomRoster = {}
		end

		local names_len = #VMRT.Reminder.SpellGroups.names
		for i=1,names_len+1 do
			local b = options.assign.frame.quick.filter.filterbutton[i]
			if not b then
				b = ELib:Check(options.assign.frame.quick.filter,"",true):Size(10,10):TextButton()
				options.assign.frame.quick.filter.filterbutton[i] = b
				if i%2 == 1 then
					b:SetPoint("TOPLEFT",5,-(floor((i-1)/2)*14)-56-3)
				else
					b:SetPoint("TOPLEFT",options.assign.frame.quick.filter,"TOP",5,-(floor((i-1)/2)*14)-56-3)
				end

				b.UpdateState = options.assign.Util_QuickFilterButtonUpdateStateCheck

				b.fheader = "SPELL"
				b.filter = i

				b:RegisterForClicks("LeftButtonUp","RightButtonUp")
				b:SetScript("OnClick",options.assign.Util_QuickFilterButtonOnClick)
			end

			if i <= names_len then
				b:SetText(VMRT.Reminder.SpellGroups.names[i])
				b.filter = i
			else
				b:SetText(LR["Other"])
				b.filter = -1
			end
			b:Show()
		end

		local height = 14 * ceil((names_len+1) / 2)

		for i=names_len+2,#options.assign.frame.quick.filter.filterbutton do
			options.assign.frame.quick.filter.filterbutton[i]:Hide()
		end

		options.assign.frame.quick:Size(options.assign.frame.quick:GetWidth(),520-(options.assign.frame.QUICK_HEIGHT+height)-26):Point("TOPLEFT",options.assign.frame,"TOPRIGHT",0,-(options.assign.frame.QUICK_HEIGHT+height))

		options.assign:UpdateQFilter()
	end
	options.assign.frame.quick.filter:Update()

	options.assign.frame.quick.dd = ELib:DropDown(options.assign.frame.quick,250,-1):Point("BOTTOM",options.assign.frame.quick.filter,"TOP",0,5):Size(220):SetText("Select roster"):OnShow(function() options.assign:PlayerListUpdateOnShow() end,true)
	function options.assign.frame.quick.dd:SetValue(arg1)
		ELib:DropDownClose()
		options.assign.frame.quick.last = arg1
		VMRT.Reminder.OptAssigLastQuick = arg1
		options.assign.frame.quick.dd:AutoText(arg1)
		options.assign:PlayerListUpdate()
	end
	function options.assign.frame.quick.dd:SetValue2(arg1)
		ELib:DropDownClose()
		options.assign.frame.quick.rosteredit:Show()
	end
	options.assign.frame.quick.dd.List = {
		{
			text = LR["Current roster"],
			arg1 = 1,
			func = options.assign.frame.quick.dd.SetValue,
		},
		{
			text = LR["Guild"],
			arg1 = 3,
			func = options.assign.frame.quick.dd.SetValue,
		},
		{
			text = LR["All classes"],
			arg1 = 2,
			func = options.assign.frame.quick.dd.SetValue,
		},
		{
			text = LR["Custom roster"],
			arg1 = 4,
			func = options.assign.frame.quick.dd.SetValue,
			subMenu = {
				{
					text = LR["Edit"],
					func = options.assign.frame.quick.dd.SetValue2,
				}
			},
		}
	}

	options.assign.frame.quick.rosteredit = ELib:Popup(LR["Edit custom roster"]):Size(600,600):OnShow(function(self) self:Update() end,true)
	ELib:Border(options.assign.frame.quick.rosteredit,1,.4,.4,.4,.9)

	options.assign.frame.quick.rosteredit.frame = ELib:ScrollFrame(options.assign.frame.quick.rosteredit):Size(600,585):Height(585):AddHorizontal(true):Width(600):Point("TOP",0,-15)
	ELib:Border(options.assign.frame.quick.rosteredit.frame,0)
	options.assign.frame.quick.rosteredit.frame.lines = {}

	options.assign.frame.quick.rosteredit.groupsedit = {}


	options.assign.frame.quick.rosteredit:SetScript("OnHide",function()
		options.assign.frame.quick.filter:Update()
	end)

	options.assign.frame.quick.rosteredit.frame:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll_h = self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.ScrollBar:GetValue()
		self.moveSpotted = nil

	end)

	options.assign.frame.quick.rosteredit.frame:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil
		self.moveSpotted = nil
	end)


	options.assign.frame.quick.rosteredit.ExportButton = MLib:Button(options.assign.frame.quick.rosteredit.frame.C,LR.Export):Point("TOPLEFT",600-250,-0):Size(200,20):OnClick(function()
		local str = ""
		for i=1,#VMRT.Reminder.CustomRoster do
			if VMRT.Reminder.CustomRoster[i][1] then
				str = str .. VMRT.Reminder.CustomRoster[i][1]  .."\t".. (VMRT.Reminder.CustomRoster[i][2] or "").."\t" ..(VMRT.Reminder.CustomRoster[i][3] or "").. "\n"
			end
		end
		MRT.F:Export2(str)
	end)

	options.assign.frame.quick.rosteredit.importWindow = ELib:Popup(" "):Size(600,400)
	ELib:Border(options.assign.frame.quick.rosteredit.importWindow,1,.4,.4,.4,.9)

	function options.assign.frame.quick.rosteredit.importWindow:DoImport(isErase)
		local text = options.assign.frame.quick.rosteredit.importWindow.Edit:GetText()
	  	if isErase then
			wipe(VMRT.Reminder.CustomRoster)
		end

		local lines = {strsplit("\n",text)}
		for i=1,#lines do
			local l = {}
			for k in lines[i]:gmatch("[^\n\t ]+") do
				l[#l+1] = k
			end
			local name,class,role = unpack(l)

			if name and name:trim() == ""  then name = nil end

			if name then
				if class and class:trim() == ""  then class = nil end
				if role and role:trim() == ""  then role = nil end

				if class then
					local mclass
					for i=1,#MRT.GDB.ClassList do
						if MRT.GDB.ClassList[i]:lower() == class:lower() or (GetClassInfo(MRT.GDB.ClassID[ MRT.GDB.ClassList[i] ]) or "") == class:lower() then
							mclass = MRT.GDB.ClassList[i]
							break
						end
					end
					class = mclass
				end

				if role then
					local mrole
					for i=1,#module.datas.rolesList do
						if module.datas.rolesList[i][3]:lower() == role:lower() or module.datas.rolesList[i][2]:lower() == role:lower() then
							mrole = module.datas.rolesList[i][3]
							break
						end
					end
					role = mrole
				end

				VMRT.Reminder.CustomRoster[#VMRT.Reminder.CustomRoster+1] = {
					name,
					class,
					role,
				}
			end
		end
		options.assign.frame.quick.rosteredit.importWindow:Hide()
		options.assign.frame.quick.rosteredit:Update()
	end

	options.assign.frame.quick.rosteredit.importWindow.Tip = ELib:Text(options.assign.frame.quick.rosteredit.importWindow,LR["1 line - 1 player, format: |cff00ff00name   class   role|r"],12):Point("TOPLEFT",10,-5)
	options.assign.frame.quick.rosteredit.importWindow.Edit = ELib:MultiEdit(options.assign.frame.quick.rosteredit.importWindow):Point("TOP",0,-25):Size(590,400-50-30)
	options.assign.frame.quick.rosteredit.importWindow.Import = MLib:Button(options.assign.frame.quick.rosteredit.importWindow,LR["Add"]):Point("BOTTOM",0,5):Size(590,20):OnClick(function()
		options.assign.frame.quick.rosteredit.importWindow:DoImport(false)
	end)
	options.assign.frame.quick.rosteredit.importWindow.Import2 = MLib:Button(options.assign.frame.quick.rosteredit.importWindow,LR["Add (rewrite current roster)"]):Point("BOTTOM",options.assign.frame.quick.rosteredit.importWindow.Import,"TOP",0,5):Size(590,20):OnClick(function()
		options.assign.frame.quick.rosteredit.importWindow:DoImport(true)
	end)

	options.assign.frame.quick.rosteredit.ImportButton = MLib:Button(options.assign.frame.quick.rosteredit.frame.C,LR.Import):Point("TOP",options.assign.frame.quick.rosteredit.ExportButton,"BOTTOM",0,-5):Size(200,20):OnClick(function()
		options.assign.frame.quick.rosteredit.importWindow:NewPoint("CENTER",UIParent,0,0)
		options.assign.frame.quick.rosteredit.importWindow.Edit:SetText("")
		options.assign.frame.quick.rosteredit.importWindow:Show()
	end)

	options.assign.frame.quick.rosteredit.CurrRoster = MLib:Button(options.assign.frame.quick.rosteredit.frame.C,LR["Add from current raid/group"]):Point("RIGHT",options.assign.frame.quick.rosteredit.ExportButton,"LEFT",-5,0):Size(200,20):OnClick(function()
		for _, name, subgroup, class, guid, rank, level, online, isDead, combatRole in MRT.F.IterateRoster, MRT.F.GetRaidDiffMaxGroup() do
			name = MRT.F.delUnitNameServer(name)

			if combatRole == "NONE" then combatRole = nil end

			VMRT.Reminder.CustomRoster[#VMRT.Reminder.CustomRoster+1] = {
				name,
				class,
				combatRole,
			}
		end
		options.assign.frame.quick.rosteredit:Update()
	end)

	options.assign.frame.quick.rosteredit.ClearList = MLib:Button(options.assign.frame.quick.rosteredit.frame.C,LR["Clear list"]):Point("TOP",options.assign.frame.quick.rosteredit.CurrRoster,"BOTTOM",0,-5):Size(200,20):OnClick(function()
		MLib:DialogPopup({
			id = "RG_MRT_REMINDER_RESET",
			title = LR["Clear list?"],
			buttons = {
				{
					text = YES,
					func = function()
						wipe(VMRT.Reminder.CustomRoster)
						options.assign.frame.quick.rosteredit:Update()
					end,
				},
				{
					text = NO,
				}
			},
		})
	end)

	options.assign.frame.quick.rosteredit.addButton = MLib:Button(options.assign.frame.quick.rosteredit.frame.C,LR["Add"]):Size(100,20):OnClick(function(self)
		local pos = #VMRT.Reminder.CustomRoster+1
		VMRT.Reminder.CustomRoster[pos] = {self.gtext}

		self:Hide()
		options.assign.frame.quick.rosteredit:Update()
	end)

	function options.assign.frame.quick.rosteredit:removeButton_click()
		local i = self:GetParent().data_i
		tremove(VMRT.Reminder.CustomRoster, i)

		options.assign.frame.quick.rosteredit:Update()
	end

	function options.assign.frame.quick.rosteredit:class_click(class)
		ELib:DropDownClose()

		local data = self:GetParent().parent:GetParent().data
		data[2] = class

		options.assign.frame.quick.rosteredit:Update()
	end
	options.assign.frame.quick.rosteredit.ClassDD_List = {
		{
			text = "-",
			func = options.assign.frame.quick.rosteredit.class_click,
		},
	}
	for i=1,#MRT.GDB.ClassList do
		local class = MRT.GDB.ClassList[i]
		options.assign.frame.quick.rosteredit.ClassDD_List[#options.assign.frame.quick.rosteredit.ClassDD_List+1] = {
			text = (RAID_CLASS_COLORS[class] and RAID_CLASS_COLORS[class].colorStr and "|c"..RAID_CLASS_COLORS[class].colorStr or "")..L.classLocalizate[class],
			func = options.assign.frame.quick.rosteredit.class_click,
			arg1 = class,
		}
	end

	function options.assign.frame.quick.rosteredit:role_click(role)
		ELib:DropDownClose()

		local data = self:GetParent().parent:GetParent().data
		data[3] = role

		options.assign.frame.quick.rosteredit:Update()
	end
	options.assign.frame.quick.rosteredit.RoleDD_List = {
		{
			text = "-",
			func = options.assign.frame.quick.rosteredit.role_click,
		},
	}
	for i=1,#module.datas.rolesList do
		local roledata = module.datas.rolesList[i]
		options.assign.frame.quick.rosteredit.RoleDD_List[#options.assign.frame.quick.rosteredit.RoleDD_List+1] = {
			text = roledata[2],
			func = options.assign.frame.quick.rosteredit.role_click,
			arg1 = roledata[3],
			atlas = roledata[5],
		}
	end

	function options.assign.frame.quick.rosteredit:UpdateView()
		local pos = self.frame:GetVerticalScroll()

		local spellsList = self.pList

		local c = 0
		for i=1,#spellsList do
			local data = spellsList[i]
			if data.pos + 25 >= pos and data.pos <= pos+self.frame:GetHeight() then
				c = c + 1

				local line = self.frame.lines[c]
				if not line then
					line = CreateFrame("Frame",nil,self.frame.C)
					self.frame.lines[c] = line
					line:SetSize(500,24)

					line.edit = ELib:Edit(line):Size(200,20):Point("LEFT",5,0):OnChange(function(self,isUser)
						local text = self:GetText() or ""
						options.assign.frame.quick.rosteredit.addButton:NewPoint("LEFT",self,"RIGHT",5,0):SetShown(text:trim() ~= "" and not self:GetParent().data)
						if not isUser then return end
						local data = self:GetParent().data
						if data then
							data[1] = text
						else
							options.assign.frame.quick.rosteredit.addButton.gtext = text
						end
					end)

					line.remove = MLib:Button(line,""):Size(12,20):Point("LEFT",line.edit,"RIGHT",3,0):OnClick(self.removeButton_click)
					ELib:Text(line.remove,"x"):Point("CENTER",0,0)
					line.remove.Texture:SetGradient("VERTICAL",CreateColor(0.35,0.06,0.09,1), CreateColor(0.50,0.21,0.25,1))
					line.remove._i = i

					line.bg = line:CreateTexture(nil,"BACKGROUND")
					line.bg:SetAllPoints()

					line.class = ELib:DropDown(line,220,-1):Size(150):Point("LEFT",line.edit,"RIGHT",25,0)
					line.class.List = options.assign.frame.quick.rosteredit.ClassDD_List

					line.role = ELib:DropDown(line,220,-1):Size(150):Point("LEFT",line.class,"RIGHT",10,0)
					line.role.List = options.assign.frame.quick.rosteredit.RoleDD_List
				end

				if data.data then
					line.edit:SetScript("OnEditFocusGained",self.editgname_OnEditFocusGained)
					line.edit:SetScript("OnEditFocusLost",self.editgname_OnEditFocusLost)

					line.remove:Show()
					line.class:Show()
					line.role:Show()
				else
					line.edit:SetScript("OnEditFocusGained",nil)
					line.edit:SetScript("OnEditFocusLost",nil)

					line.remove:Hide()
					line.class:Hide()
					line.role:Hide()
				end

				line.data = data.data
				line:SetPoint("TOPLEFT",10,-data.pos)
				line.edit:SetText(data.data and data.data[1] or "")
				line.class:AutoText(data.data and data.data[2])
				line.role:AutoText(data.data and data.data[3])
				line.data_i = data._i

				local classColor = data.data and data.data[2] and RAID_CLASS_COLORS[ data.data[2] ]
				line.bg:SetColorTexture(1,1,1,1)
				if classColor then
					line.bg:SetGradient("HORIZONTAL",CreateColor(classColor.r,classColor.g,classColor.b, .5), CreateColor(classColor.r,classColor.g,classColor.b, 0))
				else
					line.bg:SetGradient("HORIZONTAL",CreateColor(1,1,1, 0), CreateColor(1,1,1, 0))
				end

				line:SetWidth(max(200,self:GetWidth()))

				line:Show()
			end
		end
		for i=c+1,#self.frame.lines do
			self.frame.lines[i]:Hide()
		end
	end

	function options.assign.frame.quick.rosteredit:editgname_OnEditFocusGained()
		self.prefocustext = self:GetText()
	end
	function options.assign.frame.quick.rosteredit:editgname_OnEditFocusLost()
		if self.prefocustext ~= self:GetText() then
			options.assign.frame.quick.rosteredit:Update()
		end
	end

	function options.assign.frame.quick.rosteredit:Update()
		local names_len = #VMRT.Reminder.CustomRoster

		self.pList = {}
		for i=1,names_len do
			self.pList[#self.pList + 1] = {
				data = VMRT.Reminder.CustomRoster[i],
				_i = i,
			}
		end
		self.pList[#self.pList + 1] = {}

		for i=1,#self.pList do
			self.pList[i].pos = 50 + 25 * (i-1)
		end

		local maxheight = 50 + #self.pList * 25 + 15
		local maxwidth = max(200, self:GetWidth())

		self.frame:Height(maxheight)
		self.frame:Width(maxwidth)

		self:UpdateView()
	end

	options.assign.frame.quick.rosteredit.frame:SetScript("OnVerticalScroll", function(self)
		self:GetParent():UpdateView()
	end)




	options.assign.frame.quick.edit = ELib:Popup(LR["Edit spells groups"]):Size(900,600):OnShow(function(self) self:Update() end,true)
	ELib:Border(options.assign.frame.quick.edit,1,.4,.4,.4,.9)

	options.assign.frame.quick.edit.frame = ELib:ScrollFrame(options.assign.frame.quick.edit):Size(900,585):Height(585):AddHorizontal(true):Width(600):Point("TOP",0,-15)
	ELib:Border(options.assign.frame.quick.edit.frame,0)
	options.assign.frame.quick.edit.frame.lines = {}

	options.assign.frame.quick.edit.groupsedit = {}

	options.assign.frame.quick.edit:SetScript("OnHide",function()
		wipe(options.assign.QFILTER_SPELL)
		options.assign.frame.quick.edit:Update()
		options.assign.frame.quick.filter:Update()
	end)

	options.assign.frame.quick.edit.frame:SetScript("OnMouseDown",function(self)
		local x,y = MRT.F.GetCursorPos(self)
		self.saved_x = x
		self.saved_y = y
		self.saved_scroll_h = self.ScrollBarHorizontal:GetValue()
		self.saved_scroll_v = self.ScrollBar:GetValue()
		self.moveSpotted = nil

	end)

	options.assign.frame.quick.edit.frame:SetScript("OnMouseUp",function(self, button)
		self.saved_x = nil
		self.saved_y = nil
		self.moveSpotted = nil
	end)

	options.assign.frame.quick.edit.frame:SetScript("OnUpdate",function(self)
		local x,y = MRT.F.GetCursorPos(self)

		if self.saved_x and self.saved_y then
			if self.ScrollBarHorizontal:IsShown() and abs(x - self.saved_x) > 5 then
				local newVal = self.saved_scroll_h - (x - self.saved_x)
				local min,max = self.ScrollBarHorizontal:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBarHorizontal:SetValue(newVal)

				self.moveSpotted = true
			end
			if self.ScrollBar:IsShown() and abs(y - self.saved_y) > 5 then
				local newVal = self.saved_scroll_v - (y - self.saved_y)
				local min,max = self.ScrollBar:GetMinMaxValues()
				if newVal < min then newVal = min end
				if newVal > max then newVal = max end
				self.ScrollBar:SetValue(newVal)

				self.moveSpotted = true
			end
		end

		local isAnyHL = false
		if self:IsMouseOver() and not self.moveSpotted then
			for i=1,#self.lines do
				if self.lines[i]:IsMouseOver() and self.lines[i]:IsShown() then
					if self.lines[i] ~= self.prevHL then
						if self.prevHL then
							self.prevHL.bg:SetColorTexture(1,1,1,1)
						end
						self.prevHL = self.lines[i]
						self.prevHL.bg:SetColorTexture(1,1,1,.4)
					end
					isAnyHL = true
					break
				end
			end
		end

		if not isAnyHL and self.prevHL then
			self.prevHL.bg:SetColorTexture(1,1,1,1)
			self.prevHL = nil
		end
	end)

	options.assign.frame.quick.edit.importWindow, options.assign.frame.quick.edit.exportWindow = MRT.F.CreateImportExportWindows()
	options.assign.frame.quick.edit.importWindow:SetFrameStrata("FULLSCREEN")
	options.assign.frame.quick.edit.exportWindow:SetFrameStrata("FULLSCREEN")

	function options.assign.frame.quick.edit.importWindow:ImportFunc(str)
		local headerSize = str:sub(1,4) == "EXRT" and 9 or 8
		local header = str:sub(1,headerSize)
		if not (header:sub(1,headerSize-1) == "MRTREMS" or header:sub(1,headerSize-1) == "EXRTREMS") or (header:sub(headerSize,headerSize) ~= "0" and header:sub(headerSize,headerSize) ~= "1") then
			MLib:DialogPopup({
				id = "EXRT_REM_IMPORT",
				title = LR["Import error"],
				text = "|cffff0000"..ERROR_CAPS.."|r "..L.ProfilesFail3,
				buttons = {
					{
						text = OKAY,
					}
				},
			})
			return
		end

		self:TextToData(str:sub(headerSize+1),header:sub(headerSize,headerSize)=="0",header:sub(headerSize,headerSize)=="2")
	end

	function options.assign.frame.quick.edit.importWindow:TextToData(str,uncompressed,undecoded)
		local decoded = LibDeflate:DecodeForPrint(str:trim():gsub("^[\t\n\r]*",""):gsub("[\t\n\r]*$",""))
		local decompressed
		if uncompressed then
			decompressed = decoded
		else
			decompressed = LibDeflate:DecompressDeflate(decoded)
			if not decompressed or decompressed:sub(-5) ~= "##F##" then
				decompressed = nil
				MLib:DialogPopup({
					id = "EXRT_REM_IMPORT",
					title = LR["Import error"],
					text = "|cffff0000"..ERROR_CAPS.."|r "..L.ProfilesFail3,
					buttons = {
						{
							text = OKAY,
						}
					},
				})
				return
			end
			decompressed = decompressed:sub(1,-6)
		end
		decoded = nil

		if undecoded then
			decompressed = str
		end

		local successful, res = pcall(MRT.F.TextToTable,decompressed)
		decompressed = nil
		if successful and res then
			local checks = true

			if type(res.names) ~= "table" or #res.names == 0 then
				checks = false
			end

			if checks then
				for i=1,#res.names do
					if type(res[i]) ~= "table" then res[i] = {} end
				end
				VMRT.Reminder.SpellGroups = res

				options.assign.frame.quick.edit:Update()
				options.assign.frame.quick.filter:Update()
			else
				print("Import error: wrong data")
			end
		else
			print("Import error")
		end
	end


	function options.assign.frame.quick.edit:ExportStr(export)
		options.assign.frame.quick.edit.exportWindow:NewPoint("CENTER",UIParent,0,0)

		local compressed
		if #export < 1000000 then
			compressed = LibDeflate:CompressDeflate(export.."##F##",{level = 5})
		end
		local encoded = "MRTREMS"..(compressed and "1" or "0")..LibDeflate:EncodeForPrint(compressed or export)

		MRT.F.dprint("Str len:",#export,"Encoded len:",#encoded)

		if IsShiftKeyDown() and IsControlKeyDown() then
			--encoded = "EXRTREMD".."2"..export
		end
		options.assign.frame.quick.edit.exportWindow.Edit:SetText(encoded)
		options.assign.frame.quick.edit.exportWindow:Show()
	end

	options.assign.frame.quick.edit.ExportButton = MLib:Button(options.assign.frame.quick.edit.frame.C,LR.Export):Point("TOPLEFT",900-300,-5):Size(250,20):OnClick(function()
		local strlist = MRT.F.TableToText(VMRT.Reminder.SpellGroups)
		local str = table.concat(strlist)

		options.assign.frame.quick.edit:ExportStr(str)
	end)

	options.assign.frame.quick.edit.ImportButton = MLib:Button(options.assign.frame.quick.edit.frame.C,LR.Import):Point("TOP",options.assign.frame.quick.edit.ExportButton,"BOTTOM",0,-5):Size(250,20):OnClick(function()
		options.assign.frame.quick.edit.importWindow:NewPoint("CENTER",UIParent,0,0)
		options.assign.frame.quick.edit.importWindow:Show()
	end)

	options.assign.frame.quick.edit.ResetButton = MLib:Button(options.assign.frame.quick.edit.frame.C,LR["Reset to default"]):Point("TOP",options.assign.frame.quick.edit.ImportButton,"BOTTOM",0,-5):Size(250,20):OnClick(function()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_RESET",
			title = LR["Reset spell settings"],
			text = LR["Current spell settings will be lost. Reset to default preset?"],
			buttons = {
				{
					text = YES,
					func = function()
						VMRT.Reminder.SpellGroups = MRT.F.table_copy2(options.assign.SpellGroups_Presetup)

						options.assign.frame.quick.edit:Update()
						options.assign.frame.quick.filter:Update()
					end
				},
				{
					text = NO,
				}
			},
		})
	end)

	options.assign.frame.quick.edit.addButton = MLib:Button(options.assign.frame.quick.edit.frame.C,LR["Add"]):Size(100,20):OnClick(function(self)
		local pos = #VMRT.Reminder.SpellGroups.names+1
		VMRT.Reminder.SpellGroups.names[pos] = self.gtext
		VMRT.Reminder.SpellGroups[pos] = {}

		self:Hide()
		options.assign.frame.quick.edit:Update()
	end)

	function options.assign.frame.quick.edit:removeButton_click()
		tremove(VMRT.Reminder.SpellGroups.names, self._i)
		tremove(VMRT.Reminder.SpellGroups, self._i)

		options.assign.frame.quick.edit:Update()
	end

	function options.assign.frame.quick.edit:line_onenter()
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		GameTooltip:SetHyperlink("spell:"..self.spell )
		GameTooltip:Show()
	end
	function options.assign.frame.quick.edit:line_onleave()
		GameTooltip_Hide()
	end

	function options.assign.frame.quick.edit:UpdateView()
		local pos = self.frame:GetVerticalScroll()

		local spellsList = self.spellsList
		local groups = VMRT.Reminder.SpellGroups.names
		local spellsData = VMRT.Reminder.SpellGroups

		local c = 0
		for i=1,#spellsList do
			local data = spellsList[i]
			if data.pos + 25 >= pos and data.pos <= pos+self.frame:GetHeight() then
				c = c + 1

				local line = self.frame.lines[c]
				if not line then
					line = CreateFrame("Frame",nil,self.frame.C)
					self.frame.lines[c] = line
					line:SetSize(500,24)

					line.gbuttons = {}

					line.bg = line:CreateTexture(nil,"BACKGROUND")
					line.bg:SetAllPoints()

					line.icon = line:CreateTexture()
					line.icon:SetPoint("LEFT",0,0)
					line.icon:SetSize(20,20)

					line.name = ELib:Text(line,LR["Spell Name"],12):Point("LEFT",line.icon,"RIGHT",2,0):Left():Color()

					line:SetScript("OnEnter",self.line_onenter)
					line:SetScript("OnLeave",self.line_onleave)

					if line.SetPropagateMouseClicks then	--not working on classic client rn
						line:SetPropagateMouseClicks(true)
					end
				end

				line:SetPoint("TOPLEFT",10,-data.pos)
				local name,_,texture = GetSpellInfo(data.spell)
				line.name:SetText(name or ("spell"..data.spell))
				line.icon:SetTexture(texture)
				line.data = data

				local classColor = data.class and RAID_CLASS_COLORS[data.class]
				line.bg:SetColorTexture(1,1,1,1)
				if classColor then
					line.bg:SetGradient("HORIZONTAL",CreateColor(classColor.r,classColor.g,classColor.b, .5), CreateColor(classColor.r,classColor.g,classColor.b, 0))
				else
					line.bg:SetGradient("HORIZONTAL",CreateColor(1,1,1, 0), CreateColor(1,1,1, 0))
				end


				local isAnyGroup = false
				for j=1,#groups do
					local gbutton = line.gbuttons[j]
					if not gbutton then
						gbutton = CreateFrame("Button",nil,line)
						line.gbuttons[j] = gbutton
						gbutton:SetSize(80,24)
						gbutton:SetPoint("LEFT",(j-1)*85+200,0)

						gbutton.bg = gbutton:CreateTexture(nil,"BACKGROUND")
						gbutton.bg:SetAllPoints()

						gbutton.text = ELib:Text(gbutton,"",10):Point("CENTER"):Color()

						gbutton:RegisterForClicks("LeftButtonUp","RightButtonUp")
						gbutton:SetScript("OnClick",options.assign.frame.quick.edit.gbutton_click)
						gbutton.g = j

						if gbutton.SetPropagateMouseClicks then	--not working on classic client rn
							gbutton:SetPropagateMouseClicks(true)
						end
					end
					gbutton.text:SetText(groups[j])
					if spellsData[j][data.spell] then
						gbutton.bg:SetColorTexture(.2,.7,.2,1)
						isAnyGroup = true
					else
						gbutton.bg:SetColorTexture(.7,.2,.2,1)
					end

					gbutton:Show()
				end
				for j=#groups+1,#line.gbuttons do
					line.gbuttons[j]:Hide()
				end

				if isAnyGroup then
					line.name:Color(1,1,1,1)
				else
					line.name:Color(1,.8,.8,1)
				end

				line:SetWidth(max(200 + 85*#groups,self:GetWidth()))

				line.spell = data.spell
				line:Show()
			end
		end
		for i=c+1,#self.frame.lines do
			self.frame.lines[i]:Hide()
		end
	end

	function options.assign.frame.quick.edit:editgname_OnEditFocusGained()
		self.prefocustext = self:GetText()
	end
	function options.assign.frame.quick.edit:editgname_OnEditFocusLost()
		if self.prefocustext ~= self:GetText() then
			options.assign.frame.quick.edit:Update()
		end
	end


	function options.assign.frame.quick.edit:Update()
		local names_len = #VMRT.Reminder.SpellGroups.names
		for i=1,names_len+1 do
			local edit = self.groupsedit[i]
			if not edit then
				edit = ELib:Edit(self.frame.C):Size(270,20):Point("TOPLEFT",100,-5-25*(i-1)):LeftText("Group #"..i..":"):OnChange(function(self,isUser)
					local text = self:GetText() or ""
					if VMRT.Reminder.SpellGroups.names[i] then
						if not isUser then return end
						VMRT.Reminder.SpellGroups.names[i] = text
					else
						options.assign.frame.quick.edit.addButton:NewPoint("LEFT",self,"RIGHT",5,0):SetShown(text:trim() ~= "")
						if not isUser then return end
						options.assign.frame.quick.edit.addButton.gtext = text
					end
				end)
				self.groupsedit[i] = edit

				edit.remove = MLib:Button(edit,""):Size(12,20):Point("LEFT",edit,"RIGHT",3,0):OnClick(self.removeButton_click)
				ELib:Text(edit.remove,"x"):Point("CENTER",0,0)
				edit.remove.Texture:SetGradient("VERTICAL",CreateColor(0.35,0.06,0.09,1), CreateColor(0.50,0.21,0.25,1))
				edit.remove._i = i
			end

			if i <= names_len then
				edit:SetScript("OnEditFocusGained",self.editgname_OnEditFocusGained)
				edit:SetScript("OnEditFocusLost",self.editgname_OnEditFocusLost)
			else
				edit:SetScript("OnEditFocusGained",nil)
				edit:SetScript("OnEditFocusLost",nil)
			end

			edit:SetText(VMRT.Reminder.SpellGroups.names[i] or "")
			edit:Show()

			edit.remove:SetShown(i <= names_len)
		end
		for i=names_len+2,#self.groupsedit do
			self.groupsedit[i]:Hide()
		end


		self.spellsList = {}
		local AllSpells = options.assign:GetSpellsCDList()
		local classprio = {}
		local classprio_c = 0
		for i=1,#AllSpells do
			local data = AllSpells[i]

			local class = strsplit(",",data[2])
			if not classprio[class] then
				classprio_c = classprio_c + 1
				classprio[class] = classprio_c
			end
			if MRT.GDB.ClassID[class or 0] then

				self.spellsList[#self.spellsList + 1] = {
					spell = data[1],
					pos = (names_len + 1)*25 + 5 + 25 + 25 * #self.spellsList,
					class = class,
					spellName = GetSpellName(data[1]) or tostring(data[1] or 0),
					classprio = classprio[class],
				}
			end
		end

		sort(self.spellsList,function(a,b) if a.classprio ~= b.classprio then return a.classprio < b.classprio else return a.spellName < b.spellName end end)
		for i=1,#self.spellsList do
			self.spellsList[i].pos = (names_len + 1)*25 + 5 + 25 + 25 * (i-1)
		end

		local maxheight = (names_len + 1) * 25 + 5 + 25 + #self.spellsList * 25
		local maxwidth = max(200 + 85 * names_len + 15, self:GetWidth())

		self.frame:Height(maxheight)
		self.frame:Width(maxwidth)

		self:UpdateView()
	end

	function options.assign.frame.quick.edit:gbutton_click()
		local spell = self:GetParent().spell
		local data_table = VMRT.Reminder.SpellGroups[self.g]

		if data_table[spell] then
			data_table[spell] = nil
			self.bg:SetColorTexture(.7,.2,.2)
		else
			data_table[spell] = true
			self.bg:SetColorTexture(.2,.7,.2)
		end

		local groups = VMRT.Reminder.SpellGroups.names
		local spellsData = VMRT.Reminder.SpellGroups

		local parent = self:GetParent()
		local isAnyGroup = false
		for j=1,#groups do
			if spellsData[j][parent.spell] then
				isAnyGroup = true
				break
			end
		end

		if isAnyGroup then
			parent.name:Color(1,1,1,1)
		else
			parent.name:Color(1,.7,.7,1)
		end
	end

	options.assign.frame.quick.edit.frame:SetScript("OnVerticalScroll", function(self)
		self:GetParent():UpdateView()
	end)

	function options.assign:Util_DebugLine(text)
		if not self.debugtext then
			self.debugtext = ELib:Text(self,"",10):Point("LEFT",250,0):Left():Color()
		end
		self.debugtext:SetText(text)
	end

	function options.assign:UpdateView()
		local pos = self.frame:GetVerticalScroll()

		local line_c = 0
		for j=1,#self.linedata do
			local spell_data = self.linedata[j]
			if spell_data.pos + spell_data.height >= pos and spell_data.pos <= pos+self.frame:GetHeight() then
				if line_c == 0 then
					if self.frame.prevVPos == j then
						return
					end
					self.frame.prevVPos = j
				end
				local spell = spell_data.id
				local isOff = spell_data.isOff
				line_c = line_c + 1
				local line = self.frame.lines[line_c]
				if not line then
					line = CreateFrame("Button",nil,self.frame.C)
					self.frame.lines[line_c] = line
					line:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(line_c-1))
					line:SetSize(1000,self.TL_LINESIZE)
					--line:SetScript("OnClick",self.Util_LineOnClick)
					if line.SetPropagateMouseClicks then	--not working on classic client rn
						line:SetScript("OnEnter",self.Util_LineOnEnter)
						line:SetScript("OnLeave",self.Util_LineOnLeave)
						line:SetPropagateMouseClicks(true)
					end
					line.DebugText = self.Util_DebugLine

					line.assigns = {}

					line._i = line_c

					line.header = CreateFrame("Button",nil,self.frame.headers.C)
					line.header:SetPoint("TOPLEFT",0,-self.TL_LINESIZE*(line_c-1))
					line.header:SetSize(self.frame.headers:GetWidth(),self.TL_LINESIZE)
					line.header:RegisterForClicks("LeftButtonUp","RightButtonUp")
					line.header:SetScript("OnClick",self.Util_HeaderOnClick)
					line.header:SetScript("OnEnter",self.Util_HeaderOnEnter)
					line.header:SetScript("OnLeave",self.Util_HeaderOnLeave)

					line.header.time = ELib:Text(line.header,LR["Spell Name"],10):Point("LEFT",5,0):Size(35,0):Left():Color(unpack(self.TL_HEADER_COLOR_ON))

					line.header.trigger = CreateFrame("Button",nil,line.header)
					line.header.trigger:SetSize(self.TL_LINESIZE-2, self.TL_LINESIZE-2)
					line.header.trigger:SetPoint("LEFT",line.header.time,"RIGHT",3,0)

					line.header.trigger.bg = line.header.trigger:CreateTexture(nil,"BACKGROUND")
					line.header.trigger.bg:SetPoint("TOPLEFT",0,0)
					line.header.trigger.bg:SetPoint("BOTTOMRIGHT",0,0)
					line.header.trigger.bg:SetColorTexture(.8,.33,1,.5)

					line.header.trigger.text = ELib:Text(line.header.trigger,"T",10):Point("CENTER",line.header.trigger):Color(1,1,1):Outline(true):Shadow(true)
					line.header.trigger.text2 = ELib:Text(line.header.trigger,"",10):Point("LEFT",line.header.trigger,"RIGHT",2,0):Point("RIGHT",line.header.trigger,"RIGHT",45,0):MaxLines(1):Left():Color(unpack(self.TL_HEADER_COLOR_ON))

					line.header.icon = line.header:CreateTexture()
					line.header.icon:SetPoint("LEFT",line.header.trigger,"RIGHT",40,0)
					line.header.icon:SetSize(self.TL_LINESIZE,self.TL_LINESIZE)

					line.header.name = ELib:Text(line.header,LR["Spell Name"],10):Point("LEFT",line.header.icon,"RIGHT",3,0):Left():Color(unpack(self.TL_HEADER_COLOR_ON))

					if line_c%2 == 1 then
						line.bg = line:CreateTexture(nil,"BACKGROUND")
						line.bg:SetAllPoints()
						line.bg:SetColorTexture(1,1,1,.005)

						line.header.bg = line.header:CreateTexture(nil,"BACKGROUND")
						line.header.bg:SetAllPoints()
						line.header.bg:SetColorTexture(1,1,1,.03)
					end

				end

				line:SetPoint("TOPLEFT",0,-spell_data.pos)
				line.header:SetPoint("TOPLEFT",0,-spell_data.pos)
				line:SetWidth(max(self.frame.width_now,self.frame:GetWidth()))

				line.header.name:SetText(spell_data.line_name or "")
				line.header.icon:SetTexture(spell_data.line_icon)
				line.header.time:SetText(spell_data.line_time or "")
				line.header.trigger:SetShown(spell_data.line_trigger and true or false)
				line.header.tiptime = spell_data.line_tiptime

				line.header.trigger.text:SetText(spell_data.line_trigger_text or "")
				line.header.trigger.text2:SetText(spell_data.line_trigger_text2 or "")

				if isOff then
					line.header.isOff = true
					line.header.name:SetTextColor(unpack(self.TL_HEADER_COLOR_OFF))
					line:Hide()

				else
					line.header.isOff = false
					line.header.name:SetTextColor(unpack(self.TL_HEADER_COLOR_ON))

					line:Show()
				end
				line.header.spell = spell
				line.spell = spell

				line._i = j

				for i=1,#line.assigns do
					local t = line.assigns[i]
					t:Hide()
				end

				spell_data.line = line
				line.data = spell_data
				line.header.data = spell_data

				line.header:Show()
			end
		end
		for i=line_c+1,#self.frame.lines do
			local line = self.frame.lines[i]
			line:Hide()
			line.header:Hide()
		end
	end

	function options.assign:FilterRemindersList(data_list)

		for j=#data_list,1,-1 do
			local spell = self:GetSpell(data_list[j][1])

			local spell_filter
			if spell then
				if VMRT.Reminder.SpellGroups then
					for i=1,#VMRT.Reminder.SpellGroups.names do
						if VMRT.Reminder.SpellGroups[i][ spell ] then
							if type(spell_filter) == "table" then
								spell_filter[i] = true
							elseif spell_filter then
								spell_filter = {[spell_filter]=true,[i]=true}
							else
								spell_filter = i
							end
						end
					end
				end
			end
			if not spell_filter then
				spell_filter = -1
			end
			if not self:IsPassQFilter(self.QFILTER_SPELL,spell_filter) then
				tremove(data_list, j)
			end
		end
	end

	function options.assign:Update()
		local timeLineData = self:GetTimeLineData()
		self.timeLineData = timeLineData

		local data_list, data_uncategorized = self:GetRemindersList(self.FILTER_NOTE)

		if not self.FILTER_SPELLS then
			self:FilterRemindersList(data_list)
		end

		self:Util_LineAssignRemoveSpace()

		local line_c = 0
		local line_c_off = 0

		self.linedata = {}

		local spells_sorted = {}
		if timeLineData then
			for spell,spell_times in next, timeLineData do
				if type(spell) == "number" and self:IsPassFilterSpellType(spell_times,spell) then
					for i=1,#spell_times do
						local t = type(spell_times[i])=="table" and spell_times[i][1] or spell_times[i]

						local isAdd = true

						if true then
							for j=#spells_sorted,1,-1 do
								if spells_sorted[j].id == spell and (t - spells_sorted[j].time) < 10 then
									isAdd = false
									break
								end
							end
						end

						if self:IsRemovedByTimeAdjust(t) then
							isAdd = false
						end

						if isAdd then
							t = self:GetTimeAdjust(t)
							local pname,ptime,pcount,pgcount = self:GetPhaseFromTime(t)

							spells_sorted[#spells_sorted+1] = {
								id = spell,
								name = (GetSpellName(spell) or ("spell"..spell)),
								isOff = self.spell_status[spell],
								prio = self.spell_status[spell] and 0 or 1,
								time = t,
								counter = i,
								main = spell_times,
								phase = pname,
								cuid = #spells_sorted+1,
							}
						end
					end
				end
			end
		end
		for i=1,#self.custom_line do
			local t = self.custom_line[i]
			local pname,ptime,pcount,pnum = self:GetPhaseFromTime(t)

			spells_sorted[#spells_sorted+1] = {
				id = 0,
				name = "",
				prio = 1,
				time = t,
				counter = 0,
				phase = pname,
				isCustom = t,
				cuid = #spells_sorted+1,
			}
		end
		sort(spells_sorted,function(a,b)
			if a.prio ~= b.prio then
				return a.prio > b.prio
			elseif a.time ~= b.time then
				return a.time < b.time
			elseif a.name ~= b.name then
				return a.name < b.name
			else
				return a.cuid < b.cuid
			end
		end)

		for i=1,#data_list do
			local data_line = data_list[i]
			local time = data_line and data_line[2] or 0
			local line, linepos

			for j=1,#spells_sorted do
				if not spells_sorted[j].isOff and (time >= spells_sorted[j].time - self.gluerange and time <= min(spells_sorted[j].time + self.gluerange,spells_sorted[j+1] and not spells_sorted[j+1].isOff and spells_sorted[j+1].time or math.huge)) then
					line = spells_sorted[j]
					linepos = j
					break
				end
			end

			if not line then
				local pos = 1
				for j=1,#spells_sorted do
					if not spells_sorted[j].isOff then
						pos = j + 1
						if time < spells_sorted[j].time then
							pos = j
							break
						end
					end
				end
				tinsert(spells_sorted, pos, {
					id = 0,
					name = "",
					prio = 1,
					time = time,
				})
			end
		end

		if #data_list == 0 and #spells_sorted == 0 then
			tinsert(spells_sorted, 1, {
				id = 0,
				name = "",
				prio = 1,
				time = 0,
			})
		end

		for j=1,#spells_sorted do
			local spell_data = spells_sorted[j]
			local spell = spell_data.id
			local isOff = spell_data.isOff
			line_c = line_c + 1

			self.linedata[#self.linedata+1] = spell_data

			if spell == 0 then
				local prevTime
				for i=j-1,1,-1 do
					if spells_sorted[i] and spells_sorted[i].id and spells_sorted[i].id ~= 0 then
						prevTime = spells_sorted[i].time
						break
					end
				end
				if prevTime then
					spell_data.line_name = "+"..module:FormatTime(spell_data.time - prevTime)
					spell_data.line_tiptime = spell_data.time
				else
					spell_data.line_time = module:FormatTime(spell_data.time)
				end
			else
				local name = GetSpellName(spell)
				local texture = GetSpellTexture(spell)
				spell_data.line_name = (name or ("spell"..spell)).." ("..spell_data.counter..")"
				spell_data.line_icon = texture
				spell_data.line_time = module:FormatTime(spell_data.time)
				spell_data.line_trigger = true
			end

			if spell_data.phase and spell_data.phase ~= 0 then
				if type(spell_data.phase)=="number" and spell_data.phase < 0 and spell_data.phase > -10000 then
					spell_data.line_trigger_text = "E"
					spell_data.line_trigger_text2 = MRT.F.utf8sub(LR.boss_name[-spell_data.phase] or "", 1, 5)
				else
					spell_data.line_trigger_text = "P"
					spell_data.line_trigger_text2 = spell_data.phase
				end
			else
				spell_data.line_trigger_text = "T"
			end

			if isOff then
				line_c_off = line_c_off + 1
			end

			spell_data.pos = self.TL_LINESIZE*(line_c-1)
			spell_data.height = self.TL_LINESIZE
			spell_data.a = {}
		end

		local max_y = (line_c+1)*self.TL_LINESIZE

		line_c = line_c - line_c_off
		if line_c == 0 then
			line_c = 1
		end

		max_y = max((line_c+1)*self.TL_LINESIZE,max_y)
		local max_in_line = 0
		for i=1,#data_list do

			local data_line = data_list[i]
			local data = data_line and data_line[1]
			local time = data_line and data_line[2] or 0
			local line

			for j=1,#spells_sorted do
				if not spells_sorted[j].isOff and (time >= spells_sorted[j].time - self.gluerange and time <= min(spells_sorted[j].time + self.gluerange,spells_sorted[j+1] and spells_sorted[j+1].time or math.huge)) then
					line = spells_sorted[j]
					break
				end
			end

			if line then
				line.a[#line.a+1] = data_line

				if max_in_line < #line.a then
					max_in_line = #line.a
				end
			else
				--no lines for out-of-bounds
				--print('line not found for',time,module:FormatTime(time))
			end
		end


		for i=1,#self.frame.assigns do
			self.frame.assigns[i]:Hide()
		end
		for j=1,#self.linedata do
			local spell_data = self.linedata[j]
			for i=1,#spell_data.a do
				local data_line = spell_data.a[i]
				local data = data_line and data_line[1]
				local time = data_line and data_line[2] or 0

				local assign = self:Util_LineAddAssign(i,data,spell_data)

				assign.timestamp = time
			end
		end

		self.frame.spells_sorted = spells_sorted

		local width = 10 + max_in_line * (self.TL_ASSIGNSPACING + self.TL_ASSIGNWIDTH)
		self.frame.width_now = width
		self.frame:Width(width)
		if width > self.frame:GetWidth() then
			self.frame.ScrollBarHorizontal:Show()
		elseif self.frame.ScrollBarHorizontal:IsShown() then
			self.frame.ScrollBarHorizontal:SetValue(0)
			self.frame.ScrollBarHorizontal:Hide()
		end

		self.frame:Height(max_y)
		self.frame.headers:Height(max_y)
		if max_y > self.frame:GetHeight() then
			self.frame.ScrollBar:Show()
		elseif self.frame.ScrollBar:IsShown() then
			self.frame.ScrollBar:SetValue(0)
			self.frame.ScrollBar:Hide()
		end

		self.frame.prevVPos = nil
		self:UpdateView()
	end


	----- Export custom timeline created from history -----

	local cleuKeys = {
		["SPELL_CAST_SUCCESS"] = true,
		["SPELL_CAST_START"] = true,
		["SPELL_AURA_APPLIED"] = true,
		["SPELL_AURA_REMOVED"] = true,
	}
	local ignoreFields = {
		["fightData"] = true,
		["spellType"] = true,
	}

	local function IsTimeSame(a,b)
		a = a * 10
		a = floor(a + 0.5)
		a = a / 10

		b = b * 10
		b = floor(b + 0.5)
		b = b / 10
		return math.abs(a-b) <= 0.1
	end

	-- /run GMRT.A.Reminder.options:ExportTimeline(true)
	function options:ExportTimeline(useCustomSpells,cData)
		local data
		local customSpells = {}
		if cData then
			data = cData
		else
			local mod
			if options.main_tab.selected == 2 then
				mod = options.timeLine
			elseif options.main_tab.selected == 3 then
				mod = options.assign
			end

			if not mod or not mod.CUSTOM_TIMELINE then return end
			customSpells = type(useCustomSpells) == "table" and useCustomSpells or useCustomSpells and mod.FILTER_SPELL

			data = CopyTable(mod.CUSTOM_TIMELINE)
		end
		ddt(data,"TimelineData")
		local function serializeTable(tbl, indent, nextIndent, isEvents)
			local res = {nextIndent}
			indent = indent or "\n"
			isEvents = isEvents or false

			for k, v in next, tbl do
				if not ignoreFields[k] and (not options.timeLine.spell_status[k] or data == cData) then -- and (not customSpells or type(k) ~= "number" or k < 200 or customSpells[k])
					local keyIsNum = false
					if type(k) == "number" then
						keyIsNum = true
						if (k == 1 or k < 200 and tbl[k-1]) then
							k = nil
						else
							k = "[" .. k .. "]"
						end
					elseif type(k) == "string" and string.find(k,"[^%w%_]") then
						k = format("[%q]", k)
					end

					if type(v) == "table" and next(v) then

							-- reduce events spam, remove every event that already happened in last 2 seconds
							if keyIsNum then
							if isEvents then
								for i=#v,1,-1 do
									local time = type(v[i]) == "table" and v[i][1] or v[i]
									if time then
										for j=i-1,1,-1 do
											local prevTime = type(v[j]) == "table" and v[j][1] or v[j]
											if prevTime and prevTime > time - 2 then
												local removedEntry = table.remove(v, i)
												local r = type(removedEntry) == "table" and removedEntry.r or 1
												if type(v[j]) ~= "table" then
													v[j] = {v[j],r=1+r}
												else
													v[j].r = v[j].r + r
												end
												break
											end
										end
									end
								end
							else
								for i=#v,1,-1 do
									local time = type(v[i]) == "table" and v[i][1] or v[i]
									if time then
										for j=i-1,1,-1 do
											local prevTime = type(v[j]) == "table" and v[j][1] or v[j]
											if prevTime and prevTime > time - 2 then
												table.remove(v, i)
												break
											end
										end
									end
								end
							end
						end

						if type(v[1]) == "table" and v[1].d then -- compress tables with .d
							local sameD = true
							for i=2,#v do
								if not IsTimeSame((type(v[i]) == "table" and v[i].d or v.d or v[1].d), v[1].d) then
									sameD = false
									break
								end
							end
							if sameD then
								v.d = v[1].d
								for i=1,#v do
									if type(v[i]) == "table" then
										v[i] = v[i][1]
									end
								end
							end
						end

						if type(v[1]) == "table" and v[1].c then -- compress tables with .c
							local sameC = true
							for i=2,#v do
								if not IsTimeSame((type(v[i]) == "table" and v[i].c or v.cast or v[1].c), v[1].c) then
									sameC = false
									break
								end
							end
							if sameC then
								v.cast = v[1].c
								for i=1,#v do
									if type(v[i]) == "table" then
										v[i] = v[i][1]
									end
								end
							end
						end

						local indent2 = cleuKeys[k] and "\n    " or ""
						res[#res + 1] = indent2 ..(k and (k .. "=") or "")  .. "{" .. indent2 .. serializeTable(v, indent2, nil, isEvents or k == "events") .. "},"
					elseif type(v) ~= "table" then
						if type(v) == "number" then
							v = v * 10
							v = floor(v + 0.5)
							v = v / 10
						elseif type(v) == "string" then --and string.find(v,"%A")
							v = format("%q", v)
						end
						res[#res + 1] = indent .. (k and (k .. "=") or "") .. tostring(v) .. ","
					end
				end
			end
			if tbl == data or data.events and (
				tbl == data.events or
				tbl == data.events.SPELL_CAST_SUCCESS or
				tbl == data.events.SPELL_CAST_START or
				tbl == data.events.SPELL_AURA_APPLIED or
				tbl == data.events.SPELL_AURA_REMOVED
			) then
				sort(res,function(A,B)
					local aIsSpell = string.find(A,"^%[%d+%]")
					local bIsSpell = string.find(B,"^%[%d+%]")
					local aIsEvents = string.find(A,"^events")
					local bIsEvents = string.find(B,"^events")
					local aIsPhase = string.find(A,"^p")
					local bIsPhase = string.find(B,"^p")
					local aisD = string.find(A,"^d")
					local bisD = string.find(B,"^d")

					local prioA = aIsSpell and 1 or aIsPhase and 2 or aisD and 3 or aIsEvents and 4 or 5
					local prioB = bIsSpell and 1 or bIsPhase and 2 or bisD and 3 or bIsEvents and 4 or 5
					if aIsSpell and bIsSpell then
						return tonumber(A:match("^%[(%d+)%]") or 0) < tonumber(B:match("^%[(%d+)%]") or 0)
					elseif tbl == data then
						return prioA < prioB
					else
						return false
					end
				end)
			end

			if tbl == data then
				for i=1,#res do
					local spellID = tonumber(res[i]:match("^%[(%d+)%]") or "?")
					if spellID then
						local spellName = GetSpellName(spellID)
						if spellName then
							res[i] = res[i] .. " -- " .. spellName
						end
					end
				end
			end

			return table.concat(res, indent)
		end

		local str = serializeTable(data)
		str = str:gsub("%,%}","}")
		print(#str)
		MRT.F:Export(str)
	end


	options.timeLine.preload = options.timeLineBoss:PreUpdate()
	options.assign.preload = options.assignBoss:PreUpdate()
end
