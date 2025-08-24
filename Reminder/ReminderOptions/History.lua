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


-- upvalues
local prettyPrint, GetTime, tinsert, type, next, C_Timer, tonumber, tostring, wipe, strsplit, bit = module.prettyPrint, GetTime, tinsert, type, next, C_Timer, tonumber, tostring, wipe, strsplit, bit
local strsub, GameTooltip_Hide, GameTooltip, next, ipairs, floor, format, IsControlKeyDown, IsShiftKeyDown = strsub, GameTooltip_Hide, GameTooltip, next, ipairs, floor, format, IsControlKeyDown, IsShiftKeyDown
local sort, UnitClassBase, GetPlayerInfoByGUID, RAID_CLASS_COLORS, max, ceil = sort, UnitClassBase, GetPlayerInfoByGUID, RAID_CLASS_COLORS, max, ceil
local tconcat, date, GetInstanceInfo, select, CreateColor, tDeleteItem = table.concat, date, GetInstanceInfo, select, CreateColor, tDeleteItem

local GetSpellInfo = AddonDB.GetSpellInfo
local GetSpellName = AddonDB.GetSpellName
local GetSpellTexture = AddonDB.GetSpellTexture

---@class VMRT
local VMRT = VMRT


---@class historyEntry
---@field encounterID number Encounter ID, negative values for zoneID
---@field diff number Difficulty ID or key level
---@field success number 1 for kill, 0 for wipe
---@field date number Unix timestamp
---@field duration number Combat duration
---@field log string|table Log data or unique ID of log data in archive
---@field source string? Sender of the data
---@field isMPlus boolean Is m+ data

---@class historyRecord
---@field [1] number Timestamp of the event
---@field [2] number Event type
---@field [3] any Additional event data

local LibDeflateAsync = LibStub("LibDeflateAsync-reminder")
local historyAsyncConfig = {
	maxTime = 2,
	maxTimeCombat = 2,
	errorHandler = function(msg, stackTrace, name)
		geterrorhandler()(msg)
		if module.options and module.options.SetupFrame and module.options.SetupFrame.QuickList then
			module.options.SetupFrame.QuickList.initSpinner:Stop()
		end
	end,
}

local function Async(...)
	return AddonDB:Async(historyAsyncConfig, ...)
end

---@type historyRecord[]
module.db.historyNow = {}
---@type historyEntry[]
module.db.history = {}

local defaultFont = GameFontNormal:GetFont()

local MIN_COMBAT_TIME = 30
local DELAY_BEFORE_SENDING = 5

---@param entry historyEntry
local function clearOversized(entry)
	for i=#entry,1,-1 do
		if #entry > VMRT.Reminder.HistoryMaxPulls then
			if not entry[i].pinned then
				if type(entry[i].log) == "string" then
					AddonDB.RemoveHistory(entry[i].log)
				end
				tremove(entry,i)
			end
		else
			break
		end
	end
end

---@return historyEntry
local function getEntryForEncounter(encounterID,difficultyID)
	module.db.history = VMRT.Reminder.SaveHistory and ReminderLog.history or module.db.history or {}

	module.db.history[encounterID] = module.db.history[encounterID] or {}
	module.db.history[encounterID][difficultyID] = module.db.history[encounterID][difficultyID] or {}

	module.db.history[encounterID][difficultyID].encounterID = encounterID
	module.db.history[encounterID][difficultyID].difficultyID = difficultyID

	return module.db.history[encounterID][difficultyID]
end

 module.StoreHistory = AddonDB:WrapAsync(historyAsyncConfig, function(self, kill)
	module:AddHistoryEntry(0)

	local historyNow = module.db.historyNow
	module.db.historyNow = {}

	local CombatTotalTimer = historyNow[#historyNow][1] - historyNow[1][1]
	local CombatStartDate = time() - CombatTotalTimer
	local enoughTime = CombatTotalTimer > MIN_COMBAT_TIME

	local HISTORY_TYPE = historyNow[1][2]
	local ID = historyNow[1][3] -- encounterID/zoneID
	local difficulty = historyNow[1][4] -- difficultyID/keyLevel

	if HISTORY_TYPE ~= 3 and HISTORY_TYPE ~= 20 then
		prettyPrint("Invalid history type", HISTORY_TYPE, "not saving history")
		return
	end

	if type(ID) ~= "number" or type(difficulty) ~= "number" then
		prettyPrint("Invalid history data, ID or difficulty is not a number. ID:", ID, "difficulty:", difficulty)
		return
	end

	if HISTORY_TYPE == 20 then -- negative ID for zones
		ID = -ID
	end

	if not enoughTime then return end

	if VMRT.Reminder.HistoryTransmission then
		module.db.sendHistoryByMe = true
		MRT.F.ScheduleTimer(AddonDB.SendComm, 2, nil, "REM_HIST_V", module.DATA_VERSION)
	end

	local uid = AddonDB.GenerateUniqueID()
	local historyEntry = {
		encounterID = ID,
		diff = difficulty,
		success = kill,
		date = CombatStartDate,
		duration = CombatTotalTimer,
		log = VMRT.Reminder.SaveHistory and uid or historyNow,
		isMPlus = HISTORY_TYPE == 20, -- m+ start event
	}

	local archiveEntry
	if VMRT.Reminder.SaveHistory then
		archiveEntry = AddonDB.SetHistory(uid, historyNow)
	end

	local CurrentEncounterTable
	if historyEntry.isMPlus then
		CurrentEncounterTable = getEntryForEncounter("m+", ID)
	else
		CurrentEncounterTable = getEntryForEncounter(ID, difficulty)
	end


	tinsert(CurrentEncounterTable, 1, historyEntry)
	prettyPrint("History data added")

	clearOversized(CurrentEncounterTable)

	if module.SetupFrame and module.SetupFrame.QuickList then
		module.SetupFrame:UpdateHistory()
	end

	if VMRT.Reminder.HistoryTransmission then
		MRT.F.ScheduleTimer(module.SendHistory, DELAY_BEFORE_SENDING, module, historyEntry, archiveEntry)
	end
 end)


local commsOptions = { maxPer5Sec = 50 }
module.SendHistory = AddonDB:WrapAsync(historyAsyncConfig, function(self, historyEntry, archiveEntry)
	if not module.db.sendHistoryByMe then
		return
	end
	module.db.sendHistoryByMe = false

	-- check if we already have this log entry in compressed format to save time compressing it, reencode is way faster(untill we fully adopt C_EncodingUtil)
	local encoded
	if archiveEntry then
		encoded = ReminderArchive.ReadOnly[archiveEntry.id].data
		if encoded then
			encoded = LibDeflateAsync:DecodeForPrint(encoded)
			encoded = LibDeflateAsync:EncodeForWoWAddonChannel(encoded)
		end
	end

	local str = module:GetHistoryExportString(historyEntry, true, encoded)

	if not str then
		prettyPrint("Failed to get history export string for sending")
		return
	end

	local parts = AddonDB:SendComm("REM_HIST", str, nil, nil, nil, nil, commsOptions)

	prettyPrint("History data sent", format("%d", AddonDB.AsyncEnvironment.TOTAL_TIME), "ms in", parts, "parts")
end)

local function onComm(prefix, sender, str)
	if sender == MRT.SDB.charKey or sender == MRT.SDB.charName then
		return
	end
	if not VMRT.Reminder.HistoryTransmission or not VMRT.Reminder.HistoryEnabled or not IsInRaid() then
		return
	end

	if prefix == "REM_HIST" then
		if select(4, UnitPosition'player') ~= select(4, UnitPosition(Ambiguate(sender, "none"))) then
			Async(module.ProcessHistoryTextToData, module, sender, str, true)
		end
	elseif prefix == "REM_HIST_V" then
		local senderVer = tonumber(str or "?") or 0
		if senderVer and senderVer > module.DATA_VERSION then
			module.db.sendHistoryByMe = false
			return
		end
		if sender < MRT.SDB.charName and senderVer and senderVer >= module.DATA_VERSION then
			module.db.sendHistoryByMe = false
		end
	end
end

AddonDB:RegisterComm("REM_HIST", onComm)
AddonDB:RegisterComm("REM_HIST_V", onComm)

function module:ProcessHistoryTextToData(sender, str, fromChat)
	if fromChat then
		prettyPrint("Processing history from", sender)
	else
		prettyPrint("Importing history")
	end
	local encodeVersion, data = str:match("^(!RH:%d+!)(.+)$")
	if encodeVersion then
		encodeVersion = tonumber(encodeVersion:match("%d+"))
	end

	if not encodeVersion or encodeVersion ~= 2 then
		prettyPrint("Invalid history version from", sender, encodeVersion)
		return
	end

	local header, encoded = AddonDB:SplitHeaderAndMain(data)
	local encounterID, diff, kill, CombatStartDate, CombatTotalTimer, isMPlus = strsplit("!", header)
	encounterID = tonumber(encounterID or "?")
	diff = tonumber(diff or "?")
	kill = (kill == "1" and 1) or 0
	CombatStartDate = tonumber(CombatStartDate or "?")
	CombatTotalTimer = tonumber(CombatTotalTimer or "?")
	isMPlus = isMPlus == "1"


	if not encounterID or not diff then
		prettyPrint("Invalid history header from", sender)
		return
	end

	local log, error = AddonDB:DecompressTable(encoded, not fromChat)
	if not log then
		prettyPrint("Failed to decompress history data from", sender, error)
	end


	local historyEntry = {
		encounterID = encounterID,
		diff = diff,
		success = kill,
		date = CombatStartDate,
		duration = CombatTotalTimer,
		log = log,
		source = sender,
		isMPlus = isMPlus or log and log[1] and log[1][2] == 20, -- m+ start event
	}

	if VMRT.Reminder.SaveHistory then
		local uid = AddonDB.GenerateUniqueID()
		AddonDB.SetHistory(uid, log)
		historyEntry.log = uid
	end
	local CurrentEncounterTable
	if historyEntry.isMPlus then
		CurrentEncounterTable = getEntryForEncounter("m+", encounterID)
	else
		CurrentEncounterTable = getEntryForEncounter(encounterID, diff)
	end

	tinsert(CurrentEncounterTable, 1, historyEntry)

	clearOversized(CurrentEncounterTable)
	if not fromChat then
		if historyEntry.isMPlus then
			prettyPrint("Imported history for", LR.instance_name[-encounterID], diff)
		else
			prettyPrint("Imported history for", LR.boss_name[encounterID], LR.diff_name[diff])
		end
	end

	if module.SetupFrame and module.SetupFrame.QuickList then
		module.SetupFrame:UpdateHistory()
	end
	return historyEntry
end

function module:GetHistoryExportString(historyEntry,forChat,encoded)
	if type(historyEntry) ~= "table" then
		prettyPrint("Could not get history data")
		return
	end

	local log
	if type(historyEntry.log) == "string" then
		log = AddonDB.RestoreFromHistory(historyEntry.log)
	elseif type(historyEntry.log) == "table" then
		log = historyEntry.log
	end

	if type(log) ~= "table" then
		prettyPrint("Could not get log data")
		return
	end

	local header = "!RH:2!" .. historyEntry.encounterID .. "!" .. historyEntry.diff .. "!" .. (historyEntry.success == 1 and "1" or "") .. "!" .. historyEntry.date .. "!" .. historyEntry.duration .."!" .. (historyEntry.isMPlus and "1" or "") .. "##H##"

	if encoded then
		return header .. encoded
	end

	encoded = AddonDB:CompressTable(log, not forChat)

	local str = header .. encoded
	return str
end


function module:HistorySanityCheck()
	for encounterID,tbl in next, module.db.history do
		for diffID,history in next, tbl do
			clearOversized(history)
			if #history == 0 then
				if module.SetupFrame.QuickList.SelectedEncounter == tbl[diffID] then
					module.SetupFrame.QuickList:Reset()
				end
				tbl[diffID] = nil
			end
		end
		if not next(tbl) then
			module.db.history[encounterID] = nil
		end
	end
end

function module.options:InitHistory()
	local SetupFrame = module.SetupFrame

	local function AdjustTableSizes()
		for i=1,#SetupFrame.QuickList.List do
			local line = SetupFrame.QuickList.List[i]
			if line.table.event == 3  then
				line.text1:SetWidth(277)
				line.text2:SetWidth(150)
			elseif line.table.event == 20 then
				line.text1:SetWidth(90)
				line.text2:SetWidth(200)
			elseif line.table.event == 8 then
				line.text1:SetWidth(90)
				line.text2:SetWidth(185)
			-- elseif line.table.event == 1 then
			-- 	line.text1:SetWidth(90)
			-- 	line.text2:SetWidth(1)
			else
				line.text1:SetWidth(90)
				line.text2:SetWidth(55)
			end
		end
	end

	local function ScrollList_ScrollBar_OnValueChanged(self,value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % (parent:GetParent().LINE_HEIGHT or 16))
		self:UpdateButtons()

		parent:GetParent():Update()
		AdjustTableSizes()
	end

	local QuickList = ELib:ScrollTableList(SetupFrame,90,55,0,45,58,36,90,90):Size(630,496):Point("TOPLEFT",SetupFrame,"TOPRIGHT",1,-78):FontSize(11)
	QuickList.Frame.ScrollBar:SetScript("OnValueChanged",ScrollList_ScrollBar_OnValueChanged)
	SetupFrame.QuickList = QuickList
	QuickList.SetHistoryButton = {}

	function QuickList:UpdateAdditional()
		for i=1,#self.List do
			self.List[i].text3:SetWordWrap(false)
			self.List[i].text6:SetWordWrap(false)
			self.List[i].text7:SetWordWrap(false)
		end
	end
	QuickList.Frame.mouseWheelRange = 48
	QuickList.Background = QuickList:CreateTexture(nil,"BACKGROUND")
	QuickList.Background:SetColorTexture(0.05,0.05,0.07,0.98)
	QuickList.Background:SetPoint("TOPLEFT")
	QuickList.Background:SetPoint("BOTTOMRIGHT")
	QuickList:SetMovable(true)
	QuickList:EnableMouse(true)
	QuickList:RegisterForDrag("LeftButton")

	local function QuickList_OnDragStartAttached()
		SetupFrame:StartMoving()
	end
	local function QuickList_OnDragStopAttached()
		SetupFrame:StopMovingOrSizing()
	end
	local function QuickList_OnDragStartDetached()
		QuickList:StartMoving()
	end
	local function QuickList_OnDragStopDetached()
		QuickList:StopMovingOrSizing()
	end

	QuickList.TRIGGER = 1

	QuickList.HistoryBackground = ELib:Template("ExRTDialogModernTemplate",QuickList)
	QuickList.HistoryBackground:SetSize(630,115)
	QuickList.HistoryBackground:SetHeight(21 * (floor(VMRT.Reminder.HistoryMaxPulls / 2)) + 32)
	QuickList.HistoryBackground:Show()
	QuickList.HistoryBackground:SetPoint("TOPLEFT", QuickList, "BOTTOMLEFT",0,-1)
	QuickList.HistoryBackground:EnableMouse(true)
	QuickList.HistoryBackground:RegisterForDrag("LeftButton")

	ELib:Border(QuickList.HistoryBackground,1,.24,.25,.30,1)
	QuickList.HistoryBackground.Close:Hide()

	ELib:Border(QuickList,1,.24,.25,.30,1)
	ELib:Border(QuickList,0,0,0,0,1,2,1)
	ELib:Border(QuickList.Frame,0,.24,.25,.30,1)

	QuickList.ChecksBackground = ELib:Template("ExRTDialogModernTemplate",QuickList)
	QuickList.ChecksBackground:SetSize(630,77)
	QuickList.ChecksBackground:Show()
	QuickList.ChecksBackground:SetPoint("BOTTOMLEFT", QuickList, "TOPLEFT",0,1)
	QuickList.ChecksBackground:EnableMouse(true)
	QuickList.ChecksBackground:RegisterForDrag("LeftButton")


	ELib:Border(QuickList.ChecksBackground,1,.24,.25,.30,1)
	QuickList.ChecksBackground.Close:Hide()
	local b = ELib:DecorationLine(QuickList.ChecksBackground,true,"BACKGROUND",4)
	b:SetVertexColor(0.13,0.13,0.13,0.3)
	b:SetAllPoints()

	QuickList.DisabledText = ELib:Text(QuickList,LR["Hisory recording disabled"],20):Point("CENTER",0,0):Color()

	QuickList.Close = ELib:Templates_GUIcons(1)
	QuickList.Close:SetParent(QuickList.ChecksBackground)
	QuickList.Close:SetPoint("TOPRIGHT",5,5)
	QuickList.Close:SetSize(18,18)
	QuickList.Close:SetScript("OnClick", function()
		QuickList:Hide()
		QuickList:Attach()
	end)
	QuickList.Close.NormalTexture:SetVertexColor(1,0,0,1)

	function QuickList:Attach()
		QuickList:SetParent(SetupFrame)
		QuickList:SetScript("OnDragStart", QuickList_OnDragStartAttached)
		QuickList:SetScript("OnDragStop", QuickList_OnDragStopAttached)
		QuickList.HistoryBackground:SetScript("OnDragStart", QuickList_OnDragStartAttached)
		QuickList.HistoryBackground:SetScript("OnDragStop", QuickList_OnDragStopAttached)
		QuickList.ChecksBackground:SetScript("OnDragStart", QuickList_OnDragStartAttached)
		QuickList.ChecksBackground:SetScript("OnDragStop", QuickList_OnDragStopAttached)
		QuickList:ClearAllPoints()
		QuickList:Point("TOPLEFT",SetupFrame,"TOPRIGHT",1,-78)
		QuickList.detach:SetChecked(false)
		QuickList.Close:Hide()
		SetupFrame.HistoryCheck:SetChecked(VMRT.Reminder.HistoryCheck)
	end

	function QuickList:Detach()
		QuickList:SetParent(UIParent)
		QuickList:SetScript("OnDragStart", QuickList_OnDragStartDetached)
		QuickList:SetScript("OnDragStop", QuickList_OnDragStopDetached)
		QuickList.HistoryBackground:SetScript("OnDragStart", QuickList_OnDragStartDetached)
		QuickList.HistoryBackground:SetScript("OnDragStop", QuickList_OnDragStopDetached)
		QuickList.ChecksBackground:SetScript("OnDragStart", QuickList_OnDragStartDetached)
		QuickList.ChecksBackground:SetScript("OnDragStop", QuickList_OnDragStopDetached)

		local x,y = QuickList:GetCenter()
		QuickList:ClearAllPoints()
		QuickList:Point("CENTER",UIParent,"BOTTOMLEFT",x,y)
		QuickList.detach:SetChecked(true)
		QuickList.Close:Show()
		SetupFrame.HistoryCheck:SetChecked(false)
		QuickList:SetFrameStrata("DIALOG")
	end

	QuickList.initSpinner = MLib:LoadingSpinner(QuickList):Point("CENTER", QuickList, "CENTER", 0, 0):Size(60, 60)

	local function parseGUID(guid, dataID)
		local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
		local spawnIndex
		if unitType == "Creature" or unitType == "Vehicle" then
			spawnIndex = bit.rshift(bit.band(tonumber(strsub(spawnID, 1, 5), 16), 0xffff8), 3)
		end
		if dataID == mobID or dataID == (mobID .. ":" .. spawnIndex) then
			return true
		end
	end

	QuickList.additionalLineFunctions = true

	local function GetEstimatedChanges(index,data)
		local snapshot = SetupFrame.data.triggers[QuickList.TRIGGER]
		local triggerData = CopyTable(snapshot)

		local boss
		local diff
		local zoneID
		local changes = {
			ALL = {},
			NORMAL = {},
			SHIFT = {},
			CTRL = {},
		}

		local eventDB = module.C[triggerData.event == 1 and triggerData.eventCLEU or triggerData.event]
		if not eventDB then return end
		local triggerFields = {}
		for k,v in next, eventDB.triggerFields do
			triggerFields[v] = true
		end

		local event = data.event

		if event == 0 then
			-- no changes
		elseif index == 1 then
			if event == 3 then -- encounter start
				boss = tonumber(data.encounterID)
			elseif event == 20 then -- m+ start
				zoneID = tonumber(data.zoneID)
			else
				if triggerData.event ~= data.event then
					changes.ALL.isReset = true
				elseif triggerData.eventCLEU ~= data.subevent then
					changes.ALL.isReset = true
				end

				changes.ALL.event = tonumber(data.event)
				if data.subevent then
					changes.ALL.eventCLEU = tostring(data.subevent)
				end
			end
		elseif index == 2 then
			if event == 3 then -- encounter start
				diff = tonumber(data.difficultyID)
			elseif event == 2 then -- boss phase
				if triggerData.event ~= 2 then
					changes.ALL.isReset = true
				end
				changes.ALL.event = 2
				changes.ALL.pattFind = tostring(data[2])
			elseif event == 8 then -- chat
				if triggerData.event ~= 8 then
					changes.ALL.isReset = true
				end
				changes.ALL.event = 8
				changes.ALL.pattFind = tostring(data[2])
			elseif event == 9 then -- unit_engage
				if triggerData.event ~= 9 then
					changes.ALL.isReset = true
				end
				changes.ALL.event = 9
				changes.ALL.targetID = tostring(data[2])
			else -- spell event
				changes.CTRL.BLACKLIST = tonumber(data[2])
				changes.NORMAL.spellID = tonumber(data[2])
			end
		elseif index == 3 then
			if event == 2 then -- boss phase
				if triggerData.event ~= 2 then
					changes.ALL.isReset = true
				end

				changes.ALL.event = 2 -- boss phase
				changes.ALL.pattFind = tostring(data[2])
				changes.ALL.counter = tostring(data.rep)
			elseif event == 9 then -- unit_engage
				if triggerData.event ~= 9 then
					changes.ALL.isReset = true
				end

				changes.ALL.event = 9 -- unit_engage
				changes.ALL.counter = tostring(data.rep)
				changes.ALL.targetName = tostring(data.targetName)
			elseif event == 1 then -- cleu
				if not triggerFields.spellID or triggerData.event == 13 then -- reset if event is spell cd
					changes.ALL.isReset = true
					changes.ALL.event = 1 -- cleu
					changes.ALL.eventCLEU = tostring(data.subevent)
				end

				changes.ALL.spellID = tonumber(data[2])

				changes.SHIFT.counter = tostring(data.rep)
				changes.SHIFT.cbehavior = 1

				changes.NORMAL.counter = tostring(data.repGlobal)
				changes.NORMAL.cbehavior = "nil"

				changes.HYPERLINK = "spell:"..data[2]
			end
		elseif index == 4 then
			if data[4] and data.timeFromStart then
				changes.ALL.isReset = true
				changes.ALL.event = data.isMPlus and 20 or 3 -- encounter start

				local minutes = floor(data.timeFromStart / 60)
				local seconds = data.timeFromStart - (minutes * 60)
				changes.ALL.delayTime = format("%01d:%04.3f", minutes, seconds)
			end
		elseif index == 5 then
			if data.phase and data.timeFromPhase then
				changes.ALL.isReset = true
				changes.ALL.event = 2 -- boss phase

				local minutes = floor(data.timeFromPhase / 60)
				local seconds = data.timeFromPhase - (minutes * 60)

				changes.ALL.delayTime = format("%01d:%04.3f", minutes, seconds)

				changes.ALL.pattFind = tostring(data.phase[1])
				changes.ALL.counter = tostring(data.phase[2])
			end
		elseif index == 6 then
			if data[6] then
				if data.timeFromPrev then
					local minutes = floor(data.timeFromPrev[1] / 60)
					local seconds = data.timeFromPrev[1] - (minutes * 60)

					changes.SHIFT.isReset = true
					changes.SHIFT.event = 1 -- cleu
					changes.SHIFT.eventCLEU = tostring(data.subevent)
					changes.SHIFT.spellID = tonumber(data[2])

					changes.SHIFT.delayTime = format("%01d:%04.3f", minutes, seconds)
					changes.SHIFT.counter = tostring(data.timeFromPrev[2])
					changes.SHIFT.cbehavior = 1
				end

				if data.timeFromPrevGlobal then
					local minutes = floor(data.timeFromPrevGlobal[1] / 60)
					local seconds = data.timeFromPrevGlobal[1] - (minutes * 60)

					changes.NORMAL.isReset = true
					changes.NORMAL.event = 1 -- cleu
					changes.NORMAL.eventCLEU = tostring(data.subevent)
					changes.NORMAL.spellID = tonumber(data[2])

					changes.NORMAL.delayTime = format("%01d:%04.3f", minutes, seconds)
					changes.NORMAL.counter = tostring(data.timeFromPrevGlobal[2])
					changes.NORMAL.cbehavior = "nil"
				end
			end
		elseif index == 7 then -- sourceName
			if data[7] then
				if event == 9 then -- unit_engage
					if triggerData.event ~= 9 then
						changes.ALL.isReset = true
					end
					changes.ALL.event = 9 -- unit_engage
					changes.ALL.targetUnit = tostring(data[7])
				elseif data.sourceGUID then
					local mobID, spawnTime, spawnIndex = AddonDB:CreatureInfo(data.sourceGUID)
					if mobID then
						changes.NPC_INFO = {
							mobID = mobID,
							spawnIndex = spawnIndex,
							spawnTime = spawnTime,
						}
					end

					if triggerFields.sourceID then
						if mobID then
							changes.CTRL.sourceID = mobID
							changes.SHIFT.sourceID = mobID
						end
						if spawnIndex then
							changes.CTRL.sourceID = mobID .. ":" .. spawnIndex
						end
					end
					if triggerFields.sourceName then
						local sourceName = tostring(data[7]):gsub("|T.+|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):trim()
						if sourceName ~= "" then
							changes.ALL.sourceName = sourceName
						end
					end
				end
			end
		elseif index == 8 then -- target
			if data[8] then
				if event == 9 then -- unit_engage
					if triggerData.event ~= 9 then
						changes.ALL.isReset = true
					end
					changes.ALL.event = 9 -- unit_engage
					changes.ALL.targetID = tostring(data.npcID) .. ":" .. tostring(data.spawnIndex)
				else
					if triggerFields.targetName then
						local targetName = tostring(data[8]):gsub("|T.+|t",""):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""):trim()
						if targetName ~= "" then
							changes.ALL.targetName = targetName
						end
					end
				end
			end
		end

		return changes, boss, diff, zoneID
	end

	local RESET = LR["|cffff8000Trigger reset|r"]
	local ARROW = " -> |cff0080ff"
	local anyPrev
	local anyReset
	local lastCCAny
	local function parseChangesForHover(cc,CLICK,triggerData)

		local tooltips = {}

		if cc.isReset then
			anyReset = true
			tooltips[#tooltips+1] = RESET
		end
		if cc.BLACKLIST then
			tooltips[#tooltips+1] = LR["Add to blacklist: "].."\n|cff0080ff" .. tostring(cc.BLACKLIST)
		end

		if cc.event then
			if triggerData.event ~= cc.event or anyReset then
				tooltips[#tooltips+1] = LR["event"]..ARROW..(module.C[cc.event].lname or "")
			end
		end

		local eventDB = module.C[cc.eventCLEU or cc.event or lastCCAny and (lastCCAny.eventCLEU or lastCCAny.event) or triggerData.eventCLEU or triggerData.event]

		for _, field in next, eventDB.triggerSynqFields or eventDB.triggerFields do
			if cc[field] then
				local fieldName = eventDB.fieldNames and eventDB.fieldNames[field] or LR[field]
				local valueName = cc[field]
				if valueName == "nil" then
					valueName = nil
				end

				if valueName ~= triggerData[field] or anyReset then
					if field == "cbehavior" then
						for i=1,#module.datas.counterBehavior do
							if module.datas.counterBehavior[i][1] == valueName then
								valueName = module.datas.counterBehavior[i][2] or "Default" -- ?? no default
								break
							end
						end
					elseif field == "event" or field == "eventCLEU" then
						valueName = LR["QS_"..valueName]
					end
					tooltips[#tooltips+1] = fieldName .. ARROW ..tostring(valueName)
				end
			end
		end

		if #tooltips > 0 then
			if anyPrev then
				GameTooltip:AddLine(" ")
			end
			anyPrev = true
			GameTooltip:AddLine(CLICK,1,1,1)
			for i=1,#tooltips do
				GameTooltip:AddLine(tooltips[i])
			end
		end
	end

	function QuickList:HoverMultitableListValue(isEnter,index,obj)
		if not isEnter then
			local line = obj.parent:GetParent()
			line.HighlightTexture2:Hide()
			GameTooltip_Hide()
		else
			local line = obj.parent:GetParent()
			if not line.HighlightTexture2 then
				line.HighlightTexture2 = ELib:Texture(line,"Interface\\Addons\\MRT\\media\\White"):Point("LEFT",0,0):Point("RIGHT",-4,0):Size(0,16):Color(1,1,1,0.3) --:BlendMode("ADD")
			end
			line.HighlightTexture2:Show()

			local currentTrigger = QuickList.TRIGGER
			if not currentTrigger then
				return
			end
			local triggerData = SetupFrame.data.triggers and SetupFrame.data.triggers[currentTrigger]
			if not triggerData then
				return
			end

			local eventDB = module.C[triggerData.eventCLEU] or module.C[triggerData.event]
			if not eventDB then return end

			local data = line.table
			local event = data.event

			if event == 0 then
				return
			end

			local ANCHOR = "ANCHOR_CURSOR"

			local changes, boss, diff, zoneID = GetEstimatedChanges(index,data)
			anyPrev = false
			anyReset = false
			lastCCAny = nil

			GameTooltip:SetOwner(obj, ANCHOR,-7)

			if boss then
				GameTooltip:AddLine(LR["Any Click:"],1,1,1)
				GameTooltip:AddLine(LR["Boss"]..ARROW..LR.boss_name[boss])
			end

			if zoneID then
				GameTooltip:AddLine(LR["Any Click:"],1,1,1)
				GameTooltip:AddLine(LR["Zone"]..ARROW..zoneID)
			end

			if diff then
				GameTooltip:AddLine(LR["Any Click:"],1,1,1)
				GameTooltip:AddLine(LR["Difficulty"] ..ARROW ..(LR.diff_name[diff]))
			end

			if changes.HYPERLINK then
				GameTooltip:SetHyperlink(changes.HYPERLINK)
				GameTooltip:AddLine(" ")
			end

			local needTab = false
			if changes.NPC_INFO then

				local mobID = changes.NPC_INFO.mobID
				local spawnIndex = changes.NPC_INFO.spawnIndex
				local spawnTime = changes.NPC_INFO.spawnTime
				if mobID then
					needTab = true
					GameTooltip:AddLine("Npc summary",1,1,1)
					local npcName = AddonDB:NpcNameFromGUID(data.sourceGUID)
					if npcName then
						GameTooltip:AddDoubleLine(LR["Name"], npcName)
					end
					GameTooltip:AddDoubleLine(LR["GUID"], data.sourceGUID)

					GameTooltip:AddDoubleLine(LR["NPC ID"], mobID)
					GameTooltip:AddDoubleLine(LR["Spawn Time"], date("%Y-%m-%d %H:%M:%S", spawnTime))
					GameTooltip:AddDoubleLine(LR["Spawn UNIX Time"], spawnTime)
					GameTooltip:AddDoubleLine(LR["Spawn Index"], spawnIndex)
				end
			end


			if next(changes.ALL) then
				if needTab then
					needTab = false
					GameTooltip:AddLine(" ")
				end
				lastCCAny = changes.ALL
				local CLICK = LR["Any Click:"]
				parseChangesForHover(changes.ALL,CLICK,triggerData)
			end

			if next(changes.NORMAL) then
				if needTab then
					needTab = false
					GameTooltip:AddLine(" ")
				end
				local CLICK = LR["Normal Click:"]
				parseChangesForHover(changes.NORMAL,CLICK,triggerData)
			end

			if next(changes.SHIFT) then
				if needTab then
					needTab = false
					GameTooltip:AddLine(" ")
				end
				local CLICK = LR["Shift Click:"]
				parseChangesForHover(changes.SHIFT,CLICK,triggerData)
			end

			if next(changes.CTRL) then
				if needTab then
					needTab = false
					GameTooltip:AddLine(" ")
				end
				local CLICK = LR["Ctrl Click:"]
				parseChangesForHover(changes.CTRL,CLICK,triggerData)
			end

			GameTooltip:Show()
		end
	end


	local lastCCAny
	local function parseChangesForClick(cc,triggerData)

		if cc.isReset then
			wipe(triggerData)
		end
		if cc.BLACKLIST then
			VMRT.Reminder.HistoryBlacklist[cc.BLACKLIST] = true
		end

		if cc.event then
			triggerData.event = tonumber(cc.event)
		end

		local eventDB = module.C[cc.eventCLEU or cc.event or lastCCAny and (lastCCAny.eventCLEU or lastCCAny.event) or triggerData.eventCLEU or triggerData.event]

		for _, field in next, eventDB.triggerSynqFields or eventDB.triggerFields do
			if cc[field] then
				if cc[field] == "nil" then
					cc[field] = nil
				end
				triggerData[field] = cc[field]
			end
		end
	end

	function QuickList:ClickMultitableListValue(index,obj)
		local data = obj:GetParent().table
		if not data then
			return
		end

		local currentTrigger = QuickList.TRIGGER
		if not currentTrigger then
			return
		end
		local triggerData = SetupFrame.data.triggers[currentTrigger]
		if not triggerData then
			return
		end

		local eventDB = module.C[triggerData.event == 1 and triggerData.eventCLEU or triggerData.event]
		if not eventDB then return end

		local event = data.event

		if event == 0 then
			return
		end

		local changes, boss, diff, zoneID = GetEstimatedChanges(index,data)
		anyPrev = false
		anyReset = false
		lastCCAny = nil

		if boss then
			SetupFrame.data.boss = tonumber(boss)
		end

		if zoneID then
			SetupFrame.data.zoneID = tostring(zoneID)
		end

		if diff then
			SetupFrame.data.diff = tonumber(diff)
		end

		if next(changes.ALL) then
			lastCCAny = changes.ALL
			parseChangesForClick(changes.ALL,triggerData)
		end

		if not (IsShiftKeyDown() or IsControlKeyDown()) and next(changes.NORMAL) then
			parseChangesForClick(changes.NORMAL,triggerData)
		elseif IsShiftKeyDown() and next(changes.SHIFT) then
			parseChangesForClick(changes.SHIFT,triggerData)
		elseif IsControlKeyDown() and next(changes.CTRL) then
			parseChangesForClick(changes.CTRL,triggerData)
		end

		SetupFrame:Update()
		SetupFrame:UpdateHistory()
	end

	QuickList.SearchEdit = ELib:Edit(QuickList.ChecksBackground):AddSearchIcon():Tooltip("Search in history\nSpell Name, Spell ID, Source Name,\nTarget Name, Events(as SPELL_CAST_START)"):Size(220,20):Point("TOPLEFT",5,-5):OnChange(function(self,isUser)
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
		QuickList.Search = text
		SetupFrame:UpdateHistory()
	end)
	QuickList.SearchEdit:BackgroundText(LR.search)

	--[[
	QuickList.BlacklistDropDown = ELib:DropDown(QuickList.ChecksBackground,220,10):Size(195,20):Point("LEFT",QuickList.SearchEdit,"RIGHT",5,0):SetText(LR["Spells Blacklist"])

	local function Blacklist_SetValue(self,spellID)
		if IsShiftKeyDown() then
			VMRT.Reminder.HistoryBlacklist[spellID] = nil
		end
		QuickList.BlacklistDropDown:PreUpdate()
		ELib.ScrollDropDown:Reload()

		SetupFrame:UpdateHistory()
	end

	function QuickList.BlacklistDropDown:PreUpdate()

		local List = self.List
		wipe(List)

		for spellID in next, VMRT.Reminder.HistoryBlacklist do
			if GetSpellName(spellID) then
				List[#List+1] = {
					text = GetSpellName(spellID) or "UNKNOWN",
					icon = GetSpellTexture(spellID),
					func = Blacklist_SetValue,
					arg1 = spellID,
					hoverArg = spellID,
					hoverFunc = function(self,hoverArg)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT",-7)
						GameTooltip:SetSpellByID(hoverArg)
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(LR["|cffff8000Shift click to remove from blacklist|r"])
						GameTooltip:Show()
					end,
				}
			else
				List[#List+1] = {
					text = "UNKNOWN",
					icon = "Interface\\Icons\\INV_Misc_QuestionMark",
					func = Blacklist_SetValue,
					arg1 = spellID,
					hoverArg = spellID,
					hoverFunc = function(self,hoverArg)
						GameTooltip:SetOwner(self, "ANCHOR_LEFT",-7)
						GameTooltip:AddLine("Spell ID: "..hoverArg)
						GameTooltip:AddLine(" ")
						GameTooltip:AddLine(LR["|cffff8000Shift click to remove from blacklist|r"])
						GameTooltip:Show()
					end,
				}
			end
		end
		sort(List,function(a,b) return a.text < b.text end)
	end
	]]

	do
		local settings = {
			{"SOURCE_COUNTERS",LR["Use source counters"]},
		}
		QuickList.Settings = {}

		QuickList.SettingsDropDown = ELib:DropDown(QuickList.ChecksBackground,260,-1):Size(195,20):Point("TOPRIGHT",QuickList.ChecksBackground,"TOPRIGHT",-5,-5):SetText(LR.Settings)


		local function Settings_SetValue(self,i)
			local arg1 = settings[i][1]

			local state = not QuickList.Settings[arg1]
			QuickList.Settings[arg1] = state
			self.checkButton:SetChecked(state)

			QuickList.SettingsDropDown.List[i].checkState = state
			SetupFrame:UpdateHistory()
		end

		local list = {}
		QuickList.SettingsDropDown.List = list

		for i=1,#settings do
			list[#list+1] = {
				checkable = true,
				checkState = QuickList.Settings[settings[i][1]],
				text = settings[i][2],
				arg1 = i,
				func = Settings_SetValue,
			}
		end

		local ImportHistory = AddonDB:WrapAsync(function(str)
			module:ProcessHistoryTextToData("Import", str)
		end)
		local ExportHistory = AddonDB:WrapAsync(function(historyEntry)
			return module:GetHistoryExportString(historyEntry)
		end)


		list[#settings+2] = {
			text = LR.Import,
			func = function()
				ELib:DropDownClose()
				AddonDB:QuickPaste(LR["Import History"], ImportHistory)
			end,
		}

		list[#settings+3] = {
			text = LR.Export,
			func = function()
				ELib:DropDownClose()

				local historyEntry = QuickList.selected

				if not historyEntry then
					prettyPrint("No history entry selected")
					return
				end

				AddonDB:QuickCopy(ExportHistory(historyEntry), LR["Export History"])
			end,
		}


		local function Blacklist_SetValue(self,spellID)
			if IsShiftKeyDown() then
				VMRT.Reminder.HistoryBlacklist[spellID] = nil
			end
			QuickList.SettingsDropDown:PreUpdate()
			ELib.ScrollDropDown:Reload()

			SetupFrame:UpdateHistory()
		end

		function QuickList.SettingsDropDown:PreUpdate()
			list[#settings+1] = list[#settings+1] or {
				checkable = false,
				text = LR["Spells Blacklist"],
				subMenu = {},
				Lines = 12,
			}
			local subMenu = list[#settings+1].subMenu
			wipe(subMenu)

			for spellID in next, VMRT.Reminder.HistoryBlacklist do
				if GetSpellName(spellID) then
					subMenu[#subMenu+1] = {
						text = GetSpellName(spellID) or "UNKNOWN",
						icon = GetSpellTexture(spellID),
						func = Blacklist_SetValue,
						arg1 = spellID,
						hoverArg = spellID,
						hoverFunc = function(self,hoverArg)
							GameTooltip:SetOwner(self, "ANCHOR_LEFT",-7)
							GameTooltip:SetSpellByID(hoverArg)
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine(LR["|cffff8000Shift click to remove from blacklist|r"])
							GameTooltip:Show()
						end,
					}
				else
					subMenu[#subMenu+1] = {
						text = "UNKNOWN",
						icon = "Interface\\Icons\\INV_Misc_QuestionMark",
						func = Blacklist_SetValue,
						arg1 = spellID,
						hoverArg = spellID,
						hoverFunc = function(self,hoverArg)
							GameTooltip:SetOwner(self, "ANCHOR_LEFT",-7)
							GameTooltip:AddLine("Spell ID: "..hoverArg)
							GameTooltip:AddLine(" ")
							GameTooltip:AddLine(LR["|cffff8000Shift click to remove from blacklist|r"])
							GameTooltip:Show()
						end,
					}
				end
			end
			sort(subMenu,function(a,b) return a.text < b.text end)
			if #subMenu > 12 then
				list[#settings+1].Lines = 12
			else
				list[#settings+1].Lines = #subMenu
			end
		end
		QuickList.SettingsDropDown:PreUpdate()
	end

	do
		QuickList.FiltersDropDown = ELib:DropDown(QuickList.ChecksBackground,200,-1):Size(220,20):Point("TOPLEFT",5,-30):SetText(LR["Filters"])

		local eventList = {
			{1,LR["QS_1"]},
			{"SPELL_CAST_START",LR["QS_SPELL_CAST_START"]},
			{"SPELL_CAST_SUCCESS",LR["QS_SPELL_CAST_SUCCESS"]},
			{"SPELL_AURA_APPLIED",LR["QS_SPELL_AURA_APPLIED"]},
			{"SPELL_AURA_REMOVED",LR["QS_SPELL_AURA_REMOVED"]},
			{2,LR["QS_2"]},
			{8,LR["QS_8"]},
			{9,LR["QS_9"]},
			{3,LR["QS_3"]},
			{0,LR["QS_0"]},
			{20,LR["QS_20"]},
		}
		local defaultDisabledEvents = {
			["SPELL_AURA_APPLIED"] = true,
			["SPELL_AURA_REMOVED"] = true,
			[8] = true,
		}

		local function Filters_SetValue(self,arg1) -- self is a button
			self.checkButton:SetChecked(not QuickList.Filters[eventList[arg1][1]])

			QuickList.FiltersDropDown.List[arg1].checkState = self.checkButton:GetChecked()
			QuickList.Filters[eventList[arg1][1]] = self.checkButton:GetChecked()

			if eventList[arg1][1] == 1 then

				if QuickList.Filters[1] then
					QuickList.Filters["SPELL_CAST_START"] = true
					QuickList.Filters["SPELL_CAST_SUCCESS"] = true
				else
					QuickList.Filters["SPELL_CAST_START"] = false
					QuickList.Filters["SPELL_CAST_SUCCESS"] = false
					QuickList.Filters["SPELL_AURA_APPLIED"] = false
					QuickList.Filters["SPELL_AURA_REMOVED"] = false
				end

			end

			-- update check states
			for i, v in ipairs(eventList) do
				QuickList.FiltersDropDown.List[i].checkState = QuickList.Filters[v[1]]
				self:GetParent().Buttons[i].checkButton:SetChecked(QuickList.Filters[v[1]])
			end

			SetupFrame:UpdateHistory()
		end

		local list = {}
		QuickList.FiltersDropDown.List = list
		QuickList.Filters = {}

		for i=1,#eventList do
			list[#list+1] = {
				checkable = true,
				checkState = not defaultDisabledEvents[eventList[i][1]],
				text = eventList[i][2],
				arg1 = i,
				func = Filters_SetValue,
			}
			QuickList.Filters[eventList[i][1]] = not defaultDisabledEvents[eventList[i][1]]
		end
	end

	QuickList.AllEventsChk = ELib:Check(QuickList.ChecksBackground,LR.IgnoreTrigger):Point("LEFT",QuickList.FiltersDropDown,"RIGHT",5,0):OnClick(function()
		SetupFrame:UpdateHistory()
	end)
	QuickList.AllEventsChk.text:SetJustifyH("LEFT")
	QuickList.AllEventsChk.text:SetHeight(30)

	QuickList.IgnoredFilters = ELib:Text(QuickList.ChecksBackground):Point("TOPLEFT",5,-59):Color():Top():Left()

	QuickList.trigger = ELib:DropDown(QuickList.ChecksBackground,50,-1):AddText("|cffffd100"..LR["Setup trigger"]..":"):Size(50):Point("TOPRIGHT",QuickList.SettingsDropDown,"BOTTOMRIGHT",0,-5):SetText("1")
	function QuickList.trigger:PreUpdate()
		local List = self.List
		wipe(List)
		for i=1,#SetupFrame.data.triggers do
			List[#List+1] = {
				text = i,
				arg1 = i,
				func = function(_,arg1)
					ELib:DropDownClose()
					QuickList.trigger:SetText(arg1)
					QuickList.TRIGGER = i

					QuickList:Update()
				end,
			}
		end
	end
	QuickList.detach = ELib:Check(QuickList.ChecksBackground,LR["Detach"] .. ":"):Left():Point("TOPRIGHT",QuickList.trigger,"BOTTOMRIGHT",0,-5):OnClick(function(self)
		if self:GetChecked() then
			QuickList:Detach()
		else
			QuickList:Attach()
		end
	end)

	local function FormatName(name,flags,GUID)
		if not name and not flags then
			return
		elseif name and flags then
			if UnitClassBase(name) then
				name = "|c" .. RAID_CLASS_COLORS[UnitClassBase(name)].colorStr .. name
			elseif GUID and GetPlayerInfoByGUID(GUID) then
				local localizedClass, englishClass = GetPlayerInfoByGUID(GUID)
				name = "|c" .. RAID_CLASS_COLORS[englishClass or "PRIEST"].colorStr .. name
			elseif GUID and AddonDB:NpcNameFromGUID(GUID) then
				name = AddonDB:NpcNameFromGUID(GUID)
			end
			local mark = module.datas.markToIndex[flags]
			if mark and mark > 0 then
				name = MRT.F.GetRaidTargetText(mark).." " .. name
			end
			return name
		elseif flags then
			local mark = module.datas.markToIndex[flags]
			if mark and mark > 0 then
				return MRT.F.GetRaidTargetText(mark)
			end
		else
			if UnitClassBase(name) then
				name = "|c" .. RAID_CLASS_COLORS[UnitClassBase(name)].colorStr .. name
			elseif GUID and GetPlayerInfoByGUID(GUID) then
				local localizedClass, englishClass = GetPlayerInfoByGUID(GUID)
				name = "|c" .. RAID_CLASS_COLORS[englishClass or "PRIEST"].colorStr .. name
			end
			return name
		end
	end


	local function ButtonOnEnter(self)
		local index = self.index
		local currTable = QuickList.SelectedEncounter and QuickList.SelectedEncounter[index]
		if not currTable then
			return
		end

		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 0)
		local encounterName
		if currTable.isMPlus then
			encounterName = LR.instance_name[-currTable.encounterID] or tostring(currTable.encounterID)
		else
			encounterName = LR.boss_name[currTable.encounterID]:gsub(",.+","")
		end
		GameTooltip:AddLine(MRT.F.utf8sub(encounterName,1, 30))
		GameTooltip:AddDoubleLine(LR["Fight timer"], module:FormatTime(currTable.duration), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(LR["Fight started"], date("%H:%M:%S %d/%m/%y", currTable.date), 1, 1, 1, 1, 1, 1)
		GameTooltip:AddDoubleLine(LR["Difficulty"], not currTable.isMPlus and LR.diff_name[currTable.diff] or currTable.diff, 1, 1, 1, 1, 1, 1)
		if currTable.source then
			GameTooltip:AddDoubleLine(LR["Source"], currTable.source, 1, 1, 1, 1, 1, 1)
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR["|cffff8000Shift click to delete|r"])

		if currTable.pinned then
			GameTooltip:AddLine(LR["Right Click to unpin this fight"])
		else
			GameTooltip:AddLine(LR["Right Click to pin this fight"])
		end
		GameTooltip:Show()

	end

	local function GetPullButton(i)
		if SetupFrame.QuickList.SetHistoryButton[i] then
			return SetupFrame.QuickList.SetHistoryButton[i]
		else
			local button = MLib:Button(SetupFrame.QuickList.HistoryDropDown, " "):Tooltip():OnClick(function(self,button)
				if button == "RightButton" then
					local currTable = self.tbl
					if not currTable then
						return
					end
					currTable.pinned = not currTable.pinned
					if type(currTable.log) == "string"  then
						AddonDB.SetHistoryPinnedState(currTable.log, currTable.pinned)
					end
					QuickList:UpdateSelectPullButtons()
				else
					if IsShiftKeyDown() then
						QuickList:DeletePull(i)
					else
						QuickList:SelectPull(i)
					end
				end
			end)
			SetupFrame.QuickList.SetHistoryButton[i] = button
			button:RegisterForClicks("LeftButtonUp","RightButtonUp")

			ELib:Border(button,1,0,0,0,1)

			button:FontSize(12)
			button:GetFontString():SetPoint("LEFT", 4, 0)

			button:SetScript("OnEnter",ButtonOnEnter)
			button.index = i

			return button
		end
	end

	local lockIcon = "|TInterface\\AddOns\\" .. GlobalAddonName .. "\\Media\\Textures\\lock.tga:0|t "
	function QuickList:UpdateSelectPullButtons()
		local htable = QuickList.SelectedEncounter or {}
		local MaxPulls = max(VMRT.Reminder.HistoryMaxPulls,#htable)
		local halfMaxPulls = ceil(MaxPulls / 2)

		SetupFrame.QuickList.HistoryBackground:SetHeight(21 * (ceil(MaxPulls / 2)) + 29)

		for i=1, #htable do
			local button = GetPullButton(i)
			button:ClearAllPoints()
			if i == 1 then
				button:Size(314,20):Point("TOPLEFT", SetupFrame.QuickList.HistoryDropDown, "BOTTOMLEFT", 0, -1)
			elseif i <= halfMaxPulls then -- go down
				button:Size(314,20):Point("TOP", SetupFrame.QuickList.SetHistoryButton[i - 1], "BOTTOM", 0, -1)
			else -- go right
				button:Size(313,20):Point("LEFT",SetupFrame.QuickList.SetHistoryButton[i - halfMaxPulls], "RIGHT", 1, 0)
			end

			SetupFrame.QuickList.SetHistoryButton[i]:Show()

			if QuickList.selected == htable[i] then
				SetupFrame.QuickList.SetHistoryButton[i]:SetButtonState("PUSHED",true)
			else
				SetupFrame.QuickList.SetHistoryButton[i]:SetButtonState("NORMAL")
			end

			local currTable = htable[i]
			button.tbl = currTable
			local encounterName
			if currTable.isMPlus then
				encounterName = LR.instance_name[-currTable.encounterID] or tostring(currTable.encounterID)
			else
				encounterName = LR.boss_name[currTable.encounterID]:gsub(",.+","")
			end

			local buttonText = (currTable.pinned and lockIcon or "") .. MRT.F.utf8sub(encounterName,1,28) .. " - #" .. i .. " " .. module:FormatTime(currTable.duration)
			SetupFrame.QuickList.SetHistoryButton[i]:SetText(buttonText)
			if currTable.success == 1 then
				SetupFrame.QuickList.SetHistoryButton[i]:GetTextObj():SetTextColor(0,1,0)
			else
				SetupFrame.QuickList.SetHistoryButton[i]:GetTextObj():SetTextColor(1,0,0)
			end
		end

		-- hide leftover buttons
		for i=#htable+1,#SetupFrame.QuickList.SetHistoryButton do
			SetupFrame.QuickList.SetHistoryButton[i]:Hide()
		end
	end

	function QuickList:Reset() -- used from ReminderOptions.lua
		QuickList.selected = nil
		QuickList.SelectedEncounter = nil
		QuickList.L = {}
		QuickList:Update()
		QuickList:UpdateSelectPullButtons()
	end

	function QuickList:SelectPull(index)
		local tempHistory = self.SelectedEncounter and self.SelectedEncounter[index]
		if not tempHistory then
			return
		end

		if tempHistory == self.selected then
			return
		end

		self.selected = tempHistory

		SetupFrame:UpdateHistory()
	end

	function QuickList:DeletePull(index)
		if self.SelectedEncounter and self.SelectedEncounter[index] then
			AddonDB.RemoveHistory(self.SelectedEncounter[index].log)

			local reset
			if QuickList.selected == self.SelectedEncounter[index] then
				QuickList.selected = nil
				reset = true
			end

			tremove(self.SelectedEncounter,index)

			module:HistorySanityCheck()

			QuickList:UpdateSelectPullButtons()

			if reset then
				SetupFrame:UpdateHistory()
			end
		end
	end


	-- QuickList.HistoryDropDown = ELib:DropDown(QuickList.HistoryBackground,300,10):Size(600,20):Point("TOPLEFT",QuickList.HistoryBackground,"TOPLEFT",0,0):SetText(LR.ChooseEncounter)
	QuickList.HistoryDropDown = ELib:DropDownButton(QuickList.HistoryBackground,LR.ChooseEncounter,270,10):Size(628,27):Point("TOPLEFT",QuickList.HistoryBackground,"TOPLEFT",1,-1):OnClick(function(self,...)
		if self.PreUpdate then
			self:PreUpdate()
		end
		ELib.ScrollDropDown.ClickButton(self,...)
	end)

	ELib:Border(QuickList.HistoryDropDown,1,0,0,0,1)
	QuickList.HistoryDropDown.isModern = true
	QuickList.HistoryDropDown.Texture:SetGradient("VERTICAL",CreateColor(0.12,0.12,0.12,1), CreateColor(0.14,0.14,0.14,1))
	QuickList.HistoryDropDown:GetFontString():SetFont(defaultFont, 14, "OUTLINE")


	-- check for encounter when QuickList is created
	if VMRT.Reminder.lastEncounterID then
		local lastEncounter = module.db.history[VMRT.Reminder.lastEncounterID]
		if lastEncounter then
			local currDiff = select(3,GetInstanceInfo())
			local EncounterTable = lastEncounter[currDiff]
			if EncounterTable then
				QuickList.SelectedEncounter = EncounterTable
				QuickList:UpdateSelectPullButtons()
			end
		end
	end


	local function SetHistory(_, newHistory)
		ELib:DropDownClose()
		if not newHistory then
			return
		end

		local oldHistory = QuickList.SelectedEncounter
		if oldHistory == newHistory then
			return
		end

		QuickList.SelectedEncounter = newHistory
		QuickList:UpdateSelectPullButtons()
		-- QuickList:SelectPull(1)
	end

	function QuickList.HistoryDropDown:PreUpdate()
		local List = {}
		self.List = List

		if not module.db.history then
			return
		end
		module:HistorySanityCheck()

		for encounterID,tbl in next, module.db.history do
			-- make second level of dropdown for difficulty
			local isZone = encounterID == "m+"
			local subMenu = {}
			if isZone then
				for zoneID,history in next, tbl do
					local zoneName = LR.instance_name[-zoneID]
					subMenu[#subMenu+1] = {
						text = zoneName,
						func = SetHistory,
						arg1 = history,
					}
				end
			else
				for diffID,history in next, tbl do
					local diffName = LR.diff_name[diffID]
					subMenu[#subMenu+1] = {
						text = diffName,
						func = SetHistory,
						arg1 = history,
					}
				end
			end


			-- make first level of dropdown for encounter name
			local text
			if isZone then
				text = PLAYER_DIFFICULTY_MYTHIC_PLUS or "M+"
			else
				text = LR.boss_name[encounterID]:gsub(",.+","") .. (encounterID == VMRT.Reminder.lastEncounterID and " |cff00ff00("..LR.LastPull..")|r" or "")
			end
			List[#List+1] = {
				text = text,
				subMenu = subMenu,
				encounterID = encounterID,
			}
		end
		sort(List, function(a,b)
			local aIsNum = type(a.encounterID) == "number"
			local bIsNum = type(b.encounterID) == "number"
			if aIsNum and bIsNum then
				return AddonDB:GetEncounterSortIndex(a.encounterID) < AddonDB:GetEncounterSortIndex(b.encounterID)
			elseif aIsNum then
				return true
			elseif bIsNum then
				return false
			else
				return a.encounterID < b.encounterID
			end
		end)
	end

	---------------------------------------
	-- History Frame Updating
	---------------------------------------



	local TIMESTAMP = 1
	local EVENTTYPE = 2
	local SUBEVENT = 3
	local SPELLID = 4
	local SOURCEGUID = 5
	local SOURCENAME = 6
	local SOURCEFLAGS = 7
	local DESTGUID = 8
	local DESTNAME = 9
	local DESTFLAGS = 10
	local PHASE = 3

	local passAllEvents = {
		[2] = true,
		[3] = true,
		[4] = true,
		[5] = true,
		[11] = true,
		[12] = true,
		[13] = true,
		[15] = true,
		[17] = true,
		[18] = true,
		[19] = true,
		[20] = true,
	}

	local subeventToEvents = { -- used to ignore filters and trick triggerData.event match
		["SPELL_CAST_START"] = {
			-- [1] = true,
			[6] = true, -- BW_MSG
			[7] = true, -- BW_TIMER
			[16] = true, -- UNIT_CAST
		},
		["SPELL_CAST_SUCCESS"] = {
			-- [1] = true,
			[6] = true, -- BW_MSG
			[7] = true, -- BW_TIMER
			[14] = true, -- UNIT_SPELLCAST_SUCCEEDED
			[16] = true, -- UNIT_CAST
		},
		["SPELL_AURA_APPLIED"] = {
			-- [1] = true,
			[10] = true, -- UNIT_AURA
		},
		["SPELL_AURA_REMOVED"] = {
			-- [1] = true,
			[10] = true, -- UNIT_AURA
		}
	}

	local lastLog


	SetupFrame.UpdateHistory = AddonDB:WrapAsyncSingleton(function(self, fromTrigger)
		QuickList:UpdateSelectPullButtons()

		if fromTrigger and SetupFrame.QuickList.AllEventsChk:GetChecked() then
			return
		end
		if not VMRT.Reminder.HistoryEnabled then
			QuickList.DisabledText:Show()
		else
			QuickList.DisabledText:Hide()
		end

		if  not VMRT.Reminder.HistoryCheck or
			not QuickList.selected or
			not QuickList.SelectedEncounter
		then
			QuickList.L = {}
			QuickList:Update()
			return
		end
		QuickList.DisabledText:Hide()

		if not lastLog or lastLog ~= QuickList.selected.log then
			lastLog = QuickList.selected.log
			QuickList.initSpinner:Start(10)
			QuickList.L = {}
			QuickList:Update()
		end

		local tempHistory
		if type(QuickList.selected.log) == "string" then
			tempHistory = AddonDB.RestoreFromHistory(QuickList.selected.log)
		elseif type(QuickList.selected.log) == "table" then
			tempHistory = QuickList.selected.log
		end

		if type(tempHistory) ~= "table" then
			AddonDB.RemoveHistory(QuickList.selected.log)
			tDeleteItem(QuickList.SelectedEncounter,QuickList.selected)
			module:HistorySanityCheck()

			prettyPrint("No history found", QuickList.selected.log)

			QuickList:UpdateSelectPullButtons()
			QuickList:SelectPull(1)
			return
		end



		local startTime = tempHistory[1] and tempHistory[1][1] or 0

		local phaseTime
		local phaseNow
		local phaseRepeat
		local prevPhaseNow, prevPhaseTime, prevPhaseRepeat

		local counter = {}
		local prev = {}
		local searchPat = SetupFrame.QuickList.Search

		local result = {}
		local triggerData = SetupFrame.data and not SetupFrame.QuickList.AllEventsChk:GetChecked() and SetupFrame.data.triggers[QuickList.TRIGGER]

		local eventFilters = QuickList.Filters
		local ignoredFilters = {}

		local phaseCheck = triggerData and triggerData.event == 2 and triggerData.pattFind
		local isMPlus = QuickList.selected.isMPlus

		local line, prevNow, prevNowGlobal

		for i=1,#tempHistory do
			if i % 500 == 0 then
				coroutine.yield()
			end
			line = tempHistory[i]

			prevNow = nil
			prevNowGlobal = nil
			local timestamp, eventType = line[TIMESTAMP], line[EVENTTYPE]
			local subevent, spellID, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags
			if eventType == 1 then
				subevent, spellID, sourceGUID, sourceName, sourceFlags, destGUID, destName, destFlags = line[SUBEVENT], line[SPELLID], line[SOURCEGUID], line[SOURCENAME], line[SOURCEFLAGS], line[DESTGUID], line[DESTNAME], line[DESTFLAGS]

				counter[subevent] = counter[subevent] or {}
				counter[subevent][spellID] = counter[subevent][spellID] or {}

				counter[subevent][spellID].global = (counter[subevent][spellID].global or 0) + 1
				counter[subevent][spellID][sourceGUID] = (counter[subevent][spellID][sourceGUID] or 0) + 1

				prev[subevent] = prev[subevent] or {}
				prev[subevent][spellID] = prev[subevent][spellID] or {}

				prevNow = prev[subevent][spellID][sourceGUID]
				prevNowGlobal = prev[subevent][spellID].global

				prev[subevent][spellID].global = timestamp
				prev[subevent][spellID][sourceGUID] = timestamp
			elseif eventType == 2 then
				prevPhaseTime = phaseTime
				prevPhaseNow = phaseNow

				phaseTime = line[TIMESTAMP]
				phaseNow = line[PHASE] or 0

				counter["PHASE"] = counter["PHASE"] or {}
				counter["PHASE"][phaseNow] = (counter["PHASE"][phaseNow] or 0) + 1

				prevPhaseRepeat = phaseRepeat
				phaseRepeat = counter["PHASE"][phaseNow]
			elseif eventType == 9 then -- UNIT_ENGAGE
				local targetName = line[SUBEVENT]
				counter["UNIT_ENGAGE"] = counter["UNIT_ENGAGE"] or {}
				counter["UNIT_ENGAGE"][targetName] = (counter["UNIT_ENGAGE"][targetName] or 0) + 1

			end

			local searchPass = false
			if not searchPat then
				searchPass = true
			else
				local spellName = GetSpellName(line[SPELLID] or 0)
				if spellName and module:AdvancedSearch(spellName, searchPat) then
					searchPass = true
				else
					for j=2,#line do
						if line[j] and module:AdvancedSearch(tostring(line[j]), searchPat) then
							searchPass = true
							break
						end
					end
				end
			end

			if searchPass then
				if
					(eventType == 1 and VMRT.Reminder.HistoryBlacklist[spellID or 0]) or
					(phaseCheck and phaseNow ~= phaseCheck and eventType~=2) or -- phaseCheck
					(
					( -- ignore filters for subevent/event current currently selected in trigger
						not triggerData or triggerData and
						(
						subevent and not subeventToEvents[subevent][triggerData.event] or -- for CLEU check just subevent ||
						not subevent and triggerData.event ~= eventType -- for non-CLEU check just eventType
						)
					) and
					eventFilters and (not eventFilters[eventType] or (subevent and not eventFilters[subevent]))
					)
				then
					-- empty scope for blacklisting
				else
					if triggerData and eventFilters then
						if not eventFilters[eventType] then
							ignoredFilters[eventType] = true
						elseif subevent and not eventFilters[subevent] then
							ignoredFilters[subevent] = true
						end
					end


					if eventType == 1 and
						(not triggerData or
							passAllEvents[triggerData.event] or
							(
								(triggerData.event == eventType or subeventToEvents[subevent][triggerData.event]) and
								(not triggerData.eventCLEU or triggerData.eventCLEU == subevent) and
								-- (triggerData.eventCLEU ~= subevent and QuickList.Filters[subevent]) and
								(not triggerData.spellID or triggerData.spellID == tonumber(spellID)) and
								(not triggerData.spellName or triggerData.spellName == GetSpellName(tonumber(spellID))) and
								(not triggerData.sourceName or triggerData.sourceName == sourceName) and
								(not triggerData.sourceID or triggerData.sourceID and parseGUID(sourceGUID,triggerData.sourceID)) and
								(not triggerData.sourceMark or module.datas.markToIndex[sourceFlags] == triggerData.sourceMark) and
								(not triggerData.targetName or triggerData.targetName == destName) and
								(not triggerData.targetMark or module.datas.markToIndex[destFlags] == triggerData.targetMark)

							)
						)
					then
						local spellName,_,spellTexture = GetSpellInfo(spellID)
						if not spellTexture then spellTexture = 136243 end
						local count
						if QuickList.Settings["SOURCE_COUNTERS"] then
							count = counter[subevent][spellID][sourceGUID]
						else
							count = counter[subevent][spellID].global
						end

						result[#result+1] = {
							LR["QS_" .. subevent], -- localized event
							spellID, -- spellID, subject to remove as it is possible to just click spell name to set spellID or mouseover spellname to see spellID
							count .." |T"..spellTexture..":0|t "..spellName,
							module:FormatTime(timestamp-startTime), -- time from start
							phaseNow and "["..phaseNow.."] "..module:FormatTime(timestamp-phaseTime), -- time from phase
							prevNowGlobal and module:FormatTime(timestamp-prevNowGlobal), -- time from previous
							FormatName(sourceName,sourceFlags,sourceGUID), -- sourceName
							FormatName(destName,destFlags,destGUID), -- destName
							timeFromStart=timestamp-startTime,
							timeFromPhase=phaseTime and timestamp-phaseTime,
							event = eventType,
							subevent = subevent,
							repGlobal = counter[subevent][spellID].global,
							rep = counter[subevent][spellID][sourceGUID],
							phase = {
								phaseNow,
								phaseRepeat
							},
							timeFromPrev = prevNow and {
								timestamp-prevNow,
								counter[subevent][spellID][sourceGUID]-1
							},
							timeFromPrevGlobal = prevNowGlobal and {
								timestamp-prevNowGlobal,
								counter[subevent][spellID].global-1
							},
							sourceGUID = sourceGUID,
							destGUID = destGUID,
							isMPlus = isMPlus,
						}
					elseif eventType == 2 --and
					-- (not triggerData or
					-- (
					--     (not triggerData.event or triggerData.event == 2)

					-- ))
					then -- phase
						result[#result+1] = {
							LR["QS_2"],
							line[3],
							LR.QS_PhaseRepeat..phaseRepeat,
							module:FormatTime(line[1]-startTime),
							prevPhaseNow and "["..prevPhaseNow.."] "..module:FormatTime(line[1]-prevPhaseTime),
							event = eventType,
							rep = phaseRepeat,
							timeFromStart = timestamp-startTime, -- this field is used for click and hover
							timeFromPhase = prevPhaseTime and timestamp-prevPhaseTime,
							phase = {
								prevPhaseNow,
								prevPhaseRepeat
							},
							isMPlus = isMPlus,
						}
					elseif eventType == 8 and
						(not triggerData or
						(
							(not triggerData.event or triggerData.event == 8) and
							(not triggerData.pattFind or line[3]:find(triggerData.pattFind)) and
							(not triggerData.sourceName or triggerData.sourceName == line[4])
						))
					then -- chat msg
						local msg = line[3]
						local sourceName = line[4]
						local sourceGUID = line[5]
						local targetName = line[6]

						result[#result+1] = {
							LR["QS_8"],
							msg:gsub("|T.+|t",""):trim(), --msg:gsub("|","||"):trim(),
							nil,-- MRT.F.utf8sub(line[3],1,15),
							module:FormatTime(line[1]-startTime),
							phaseNow and "["..phaseNow.."] "..module:FormatTime(line[1]-phaseTime),
							nil, -- timeFromPrev?
							FormatName(sourceName,sourceGUID),
							FormatName(targetName),
							chatmessage = msg,
							event = eventType,
							timeFromStart=line[1]-startTime,
							timeFromPhase= phaseTime and line[1]-phaseTime,
							phase={
								phaseNow,
								phaseRepeat
							},
							isMPlus = isMPlus,
						}
					elseif eventType == 9 and
						(not triggerData or
						(
							(not triggerData.event or triggerData.event == 9)
						))
					then -- boss frame
						local name = line[3]
						local guid = line[4]
						local unit = line[5]
						local npcID, spawnTime, spawnIndex = AddonDB:CreatureInfo(guid)
						local count = counter["UNIT_ENGAGE"][name]


						result[#result+1] = {
							LR["QS_9"], -- event
							npcID, -- npc id
							count .. " " .. name,
							module:FormatTime(line[1]-startTime),
							phaseNow and "["..phaseNow.."] "..module:FormatTime(line[1]-phaseTime),
							nil,
							unit,
							spawnIndex,
							rep = count,
							targetName = name,
							npcID = npcID,
							spawnIndex = spawnIndex,
							event = eventType,
							timeFromStart = line[1]-startTime,
							timeFromPhase = phaseTime and line[1]-phaseTime,
							phase = {
								phaseNow,
								phaseRepeat
							},
							isMPlus = isMPlus,
						}

					elseif eventType == 3 then -- enc start
						local encounterID = line[3]
						local difficultyID = line[4]
						local encounterName = LR.boss_name[encounterID]
						local diffName = LR.diff_name[difficultyID]
						result[#result+1] = {
							encounterName,
							diffName,
							encounterID=encounterID,
							difficultyID=difficultyID,
							event = eventType,
							timeFromStart = isMPlus and line[1]-startTime or nil,
							isMPlus = isMPlus,
						}
					elseif eventType == 20 then -- m+ start
						local zoneID = line[3]
						local level = line[4]
						result[#result+1] = {
							LR["QS_20"],
							LR.instance_name[zoneID],
							level,
							event = eventType,
							zoneID = zoneID,
							isMPlus = isMPlus,
						}
					elseif eventType == 0 then -- enc/m+ end
						phaseTime = nil
						phaseNow = nil
						phaseRepeat = nil
						counter["PHASE"] = nil

						result[#result+1] = {
							LR["QS_0"],
							event = eventType,
						}
					end
				end
			end
		end

		local ignoredFilters2 = {}
		for k,v in next, ignoredFilters do
			if v then
				ignoredFilters2[#ignoredFilters2+1] = LR["QS_"..k]
			end
		end
		sort(ignoredFilters2)
		local ignoredText = tconcat(ignoredFilters2,", ")
		if ignoredText ~= "" then
			QuickList.IgnoredFilters:SetText(LR["Filters ignored because of trigger:"].." "..ignoredText)
		else
			QuickList.IgnoredFilters:SetText("")
		end

		QuickList.L = result
		QuickList:Update()

		AdjustTableSizes()

		QuickList.initSpinner:Stop()
	end)

	QuickList:Attach()
end

function module:AddHistoryEntry(eventType, ...)
	if module.db.simrun then
		return
	end
	module.db.historyNow[#module.db.historyNow+1] = {
		GetTime(),
		eventType,
		...
	}
end
