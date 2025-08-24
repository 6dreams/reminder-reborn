local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

---@class Locale
local LR = AddonDB.LR

---@class MLib
local MLib = AddonDB.MLib

---@class WASyncPrivate
local WASync = AddonDB.WASYNC

-- upvalues
local tinsert = tinsert
local random = random
local time = time
local format = format
local max = max
local min = min
local unpack = unpack

local prettyPrint = module.prettyPrint
local WASYNC_ERROR = module.WASYNC_ERROR
local importData = module.db.importData
local errorsData = module.db.errorsData

local LibDeflateAsync = LibStub:GetLibrary("LibDeflateAsync-reminder")

---@class dataToSend
---@field str string
---@field id string
---@field importType number
---@field skipPrompt boolean
---@field channel string?
---@field touser string?
---@field exrtLastSync number? -- add this to let the receiver compare the last sync time

-- 26.4.2025
-- Blizzard per prefix throttle is 10 messages at once and than 1 message per second, if trying to send more messages dropped silently
-- MRT sending limits are:
-- 10 prefixes x 10 messages = 25500 symbols until prefix throttle
-- 10 prefixes x 1  messages = 2550  symbols during prefix throttle
-- We're using wrapper for MRT comms that fixes next issues:
-- 1. Cross realm comms can be sent out of order, we include part index in the header
-- 2. MRT comms limits WHISPER channel to only work for player within the same guild

-- Previously we used throttling where OnUpdate script sent queued messages on interval
-- which reduced amount of burst messages to 20 per second (delayC = 0.05)
-- messages that were sent after prefix limits got their throttle by MRT itself


local messageQueue = {}
function module:SendAllQueued()
	for i=1,#messageQueue do
		AddonDB:SendComm(unpack(messageQueue[i]))
	end
end

local imgData = {
	time = 0,
	num1 = 0,
	num2 = 0
}


---@param dataToSend dataToSend
---@param justEnqueue boolean?
function module:SendWA(dataToSend,justEnqueue,hideFrameOnFinish)
	module:SetPending(dataToSend.id,60,dataToSend.touser,true)

	if imgData.time < (time() - 120) then
		imgData.time = time()
		imgData.num1 = random(1, AddonDB.PUBLIC and 1 or #WASync.QueueSenderStrings)
		imgData.num2 = random(1, AddonDB.PUBLIC and 1 or AddonDB.TotalImages)
	end

	local entry = {}
	local entryKey = tostring(entry)

	local function callbackFunction(arg,currentPart,totalParts) -- these may be out of order
		module.SenderFrame:UpdateBar(entryKey,currentPart,totalParts)

		if currentPart == totalParts then
			module.SenderFrame:UpdateBar(entryKey,currentPart,totalParts)
			module.SenderFrame:FinishBar(entryKey)
			if hideFrameOnFinish and not next(module.SenderFrame.SendQueueFrame.queue) then
				module.SenderFrame:Hide()
			end

			prettyPrint(format("|cff0080ffSENDED:|r %q | %s | %s", dataToSend.id, WASync.ImportTypes[dataToSend.importType], dataToSend.touser or dataToSend.channel or "Auto"))
		end
	end

	local hash = format("%x",LibDeflateAsync:Adler32(dataToSend.str))

	local header = AddonDB:CreateHeader(
		WASync.VERSION,
		"\11\11\11", -- max amount of parts is 4095 in hex(FFF)so we need to reserve 3 bytes
		dataToSend.id,
		dataToSend.importType,
		imgData.num1,
		imgData.num2,
		dataToSend.exrtLastSync and format("%x",dataToSend.exrtLastSync) or "",
		dataToSend.touser or "",
		dataToSend.skipPrompt and "1" or "",
		dataToSend.needReload and "1" or "",
		hash
	)
	local commsMessage = AddonDB:CreateHeaderCommsMessage(header,dataToSend.str)
	local parts = AddonDB:CalculateCommsParts("was",commsMessage)
	commsMessage = commsMessage:gsub("\11\11\11", format("%x",parts), 1)

	-- Add side bar to the SenderFrame
	module.SenderFrame:AddToQueue(entryKey,dataToSend.id,parts,justEnqueue)

	-- options table has to be creted here as it will be modified for comms that use callbackFunction
	local options = {maxPer5Sec = 50}

	if justEnqueue then
		entry.justEnqueued = true
		messageQueue[#messageQueue+1] = {"was",commsMessage,dataToSend.channel,dataToSend.touser,callbackFunction,nil,options}
	else
		AddonDB:SendComm("was",commsMessage,dataToSend.channel,dataToSend.touser,callbackFunction,nil,options)
	end
end

AddonDB:RegisterCommOnPart("was", function(prefix, sender, data, channel, key, partNum)
	module.lastAddonMsg = GetTime()

	importData[key] = importData[key] or {
		sender = sender,
		ignore = true,
		i = partNum,
	}

	local impData = importData[key]

	if impData.headerReady then
		impData.i = max(impData.i,partNum)
		if impData.ignore then return end

		local red = min(255, (1 - impData.i / impData.parts) * 511)
		local green = min(255, (impData.i / impData.parts) * 511)
		module.ShowTooltip({
			{1, "WeakAuras Sync", 0.533, 0, 1},
			{1, "Accepting WeakAuras data from " .. Ambiguate(sender,"none"), 1, 0.82, 0},
			{1," "},
			{1, impData.id, 1, 1, 1},
			{2, WASync.ImportTypes[impData.importType], ("|cFF%2x%2x00"):format(red, green)..impData.i * 255 .."|cFF00FF00/"..impData.parts * 255, 1, 1, 1}
		})
	elseif partNum > 8 then -- do not expect header to be bigger than 8 parts
		if not errorsData[key] then
			errorsData[key] = true
			module:ErrorComms(sender, 1)
		end
	end
end)

AddonDB:RegisterCommOnHeader("was", function(prefix, sender, data, channel, key)
	local impData = importData[key]
	impData.headerReady = true

	local checkForID = false
	local isPass, reason = AddonDB:CheckSenderPermissions(sender, WASync.isDebugMode)
	if not isPass and module.db.allowList[sender] then
		checkForID = true
	elseif not isPass then
		if reason then
			prettyPrint(WASYNC_ERROR, format(LR.WASNoPermission, sender, reason))
		end
		return
	end

	local version, parts, id, importType, stringNum, imageNum, lastSync, target, skipPrompt, needReload, hash = AddonDB:ParseHeader(data)

	if tonumber(version or "?") ~= WASync.VERSION then
		if tonumber(version or "0") > WASync.VERSION then
			prettyPrint(WASYNC_ERROR, format("Your WeakAuras Sync version is outdated (%s ver.%s, your addon ver.%s)", sender, version or "unk", WASync.VERSION))
		else
			prettyPrint(WASYNC_ERROR, format("Import data is outdated (%s ver.%s, your addon ver.%s)", sender, version or "unk", WASync.VERSION))
		end
		return
	end

	impData.parts = tonumber(parts, 16)
	impData.id = id
	impData.importType = tonumber(importType)
	impData.stringNum = tonumber(stringNum)
	impData.imageNum = tonumber(imageNum)
	impData.skipPrompt = skipPrompt == "1" and AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender)
	impData.needReload = needReload == "1"
	impData.hash = tonumber(hash or "?", 16)
	impData.ignore = false

	if lastSync and tonumber(lastSync,16) then
		local WAdata = WeakAuras.GetData(id)
		if WAdata and
			WAdata.exrtLastSync and WAdata.exrtLastSync >= tonumber(lastSync,16) -- sent data is not an update
			and tonumber(importType) < 4 and -- acknowledge lastSync only for importTypes 1,2,3
			not (WASync.isDebugMode and UnitIsUnit(Ambiguate(sender, "none"), "player")) -- self sending allowed only for debug mode
		then
			prettyPrint(format("%q is up to date. Ignoring update", id))
			impData.ignore = true
			module:SendWAVer(id)
		end
	end

	if target and target ~= "" and not UnitIsUnit(Ambiguate(target, "none"), "player") then -- most likely not needed as targeted WAs are now always in WHISPER
		impData.ignore = true
	end

	if checkForID then
		if module.db.allowList[sender][id] then
			module.db.allowList[sender][id] = nil
		else
			impData.ignore = true
			prettyPrint(WASYNC_ERROR, format(LR.WASNoPermission, sender, id), "is not in white list")
		end
	end
end)

AddonDB:RegisterComm("was", function(prefix, sender, data, channel, key)
	ItemRefTooltip:Hide()

	local impData = importData[key]
	importData[key] = nil

	if impData.ignore then
		return
	end

	local hash = LibDeflateAsync:Adler32(data)
	if impData.hash and (hash % 4294967296) == (impData.hash % 4294967296) then

		---@type WASyncImportQueueItem
		local queueItem = {
			id = impData.id,
			str = data,
			importType = module.PUBLIC and 1 or impData.importType,
			stringNum = impData.stringNum,
			imageNum = impData.imageNum,
			sender = sender,
			skipPrompt = impData.skipPrompt,
			needReload = impData.needReload
		}

		module.QueueFrame:AddToQueue(queueItem)
	else
		prettyPrint(WASYNC_ERROR, "GOT CORRUPTED DATA, HASH MISMATCH")
		module:ErrorComms(sender, 4, "hash mismatch")
	end
end)


local prev_addonMessage = module.addonMessage
function module:addonMessage(sender, prefix, data, ...)
	sender = AddonDB:GetFullName(sender, true) -- ensure db key is always name-realm

	prev_addonMessage(self, sender, prefix, data, ...) -- ensure compability

	if prefix == "WAS_STATUS" then
		if data == "1" then -- some unused stuff i guess
			local owner,id = ...
			if MRT.F.delUnitNameServer(owner) ~= UnitName'player' then
				return
			end
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			module.db.responces[ sender ][id] = true

			if module.options:IsVisible() and module.options.ScheduleUpdate then
				module.options.ScheduleUpdate()
			end
		elseif data == "2" then -- some unused stuff i guess
			local owner,id = ...
			if MRT.F.delUnitNameServer(owner) ~= UnitName'player' then
				return
			end
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			module.db.responces[ sender ][id] = false

			if module.options:IsVisible() and module.options.ScheduleUpdate then
				module.options.ScheduleUpdate()
			end
		elseif data == "20" then -- polling WA version by id
			local id = ...
			if id then
				module.db.versionChecks[id] = time()
				module.db.versionChecksNames[id] = sender
				module:SendWAVer(id)
			end
		elseif data == "21" then -- answers for WA version by id
			local date, id, lastSender, uid, version, semver, load_never = ...
			if not id then
				return
			end

			module.db.versionsData[ sender ] = module.db.versionsData[ sender ] or {}
			module.db.versionsData[ sender ][id] = module.db.versionsData[ sender ][id] or {}
			local db = module.db.versionsData[ sender ][id]
			db.date = tonumber(date or "0")
			db.lastSender = lastSender ~= "" and lastSender or nil
			db.uid = uid ~= "" and uid or nil
			db.version = tonumber(version or "?")
			db.semver = semver ~= "" and semver or nil
			db.load_never = load_never == "1" or nil

			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			local WAData = WeakAuras.GetData(id)
			if WAData then
				if not WAData.exrtLastSync and db.date == 0 then -- both sides never synced
					module.db.responces[ sender ][id] = db.version == WAData.version and -2 or -1 -- for SetIconExtra
				else
					module.db.responces[ sender ][id] = db.date == WAData.exrtLastSync and -2 or -1 -- for SetIconExtra
				end
			end

			if module.options:IsVisible() and module.options.ScheduleUpdate then
				module.options.ScheduleUpdate()
			end
		end
	end
end


---@class versionsAnswer
---@field id string
---@field exrtLastSync number
---@field exrtLastSender string?
---@field version number?
---@field semver string?
---@field load_never boolean?

---@param data string[]
function module:GetWAVerMulti(data)
	local req = table.concat(data,"\t")

	AddonDB:SendComm("WAS_VM_REQ", req)
end

AddonDB:RegisterComm("WAS_VM_REQ", function(prefix, sender, req, ...)
	if prefix == "WAS_VM_REQ" then
	   local data = {strsplit("\t",req)}
	   module:SendWAVerMulti(data,sender)
	end
end)

function module:SendWAVerMulti(data,sender)
	local answer = {}
	for i=1,#data do
		local id = data[i]
		module.db.versionChecks[id] = time()
		module.db.versionChecksNames[id] = sender
		local WAData = WeakAuras.GetData(id)
		if WAData then
			local a = {}
			a.id = id
			a.uid = WAData.uid
			a.date = WAData.exrtLastSync or 0
			a.lastSender = WAData.exrtLastSender
			a.version = WAData.version
			a.semver = WAData.semver
			a.load_never = true
			if data.regionType == "group" or data.regionType == "dynamicgroup" then
				-- traverse children to check if any of them dont use load.use_never set
				for c in module.pTraverseAllChildren(data) do
					if not (c.regionType == "group" or c.regionType == "dynamicgroup") and c.load and not c.load.use_never then
						a.load_never = nil
						break
					end
				end
			else
				a.load_never = data.load and data.load.use_never and true or nil
			end

			tinsert(answer, a)
		else
			tinsert(answer, {id = id, NO_WA = true})
		end
	end
	local encoded = AddonDB:CompressTable(answer)
	AddonDB:SendComm("WAS_VM", encoded)
end

AddonDB:RegisterComm("WAS_VM", function(prefix, sender, encoded, ...)
	if prefix == "WAS_VM" then
		local answer, error = AddonDB:DecompressTable(encoded)
		if not answer then
			prettyPrint(WASYNC_ERROR, "Failed to deserialize versions answer", sender, error)
			return
		end
		for i=1,#answer do
			local a = answer[i]
			local id = a.id
			if a.NO_WA then
				module.db.responces[sender] = module.db.responces[sender] or {}
				module.db.responces[sender][id] = 1
			else
				module.db.versionsData[sender] = module.db.versionsData[sender] or {}
				module.db.versionsData[sender][id] = module.db.versionsData[sender][id] or {}
				local db = module.db.versionsData[sender][id]
				db.date = a.date
				db.lastSender = a.lastSender
				db.uid = a.uid
				db.version = a.version
				db.semver = a.semver
				db.load_never = a.load_never

				module.db.responces[sender] = module.db.responces[sender] or {}
				local WAData = WeakAuras.GetData(id)
				if WAData then
					if not WAData.exrtLastSync and db.date == 0 then -- both sides never synced
						module.db.responces[sender][id] = db.version == WAData.version and -2 or -1 -- for SetIconExtra
					else
						module.db.responces[sender][id] = db.date == WAData.exrtLastSync and -2 or -1 -- for SetIconExtra
					end
				end
			end
		end

		if module.options:IsVisible() and module.options.ScheduleUpdate then
			module.options.ScheduleUpdate()
		end
	end
end)

function module:RequestDebugLog(id, customTarget)
	AddonDB:SendComm("WAS_DEBUG_REQUEST", id, "WHISPER", customTarget)
end

AddonDB:RegisterComm("WAS_DEBUG_ERROR", function(prefix, sender, error, channel, key)
	if channel ~= "WHISPER" then return end

	prettyPrint(WASYNC_ERROR, sender, error)
end)

AddonDB:RegisterComm("WAS_DEBUG_REQUEST", function(prefix, sender, id, channel, key)
	if channel ~= "WHISPER" then return end

	if not WASYNC_MAIN_PRIVATE then
		module:ErrorComms(sender, 6, "WASYNC_MAIN_PRIVATE is not declared")
		return
	end
	local uid = WeakAuras.GetData(id) and WeakAuras.GetData(id).uid
	if not uid then
		module:ErrorComms(sender, 6, "No uid for "..id)
		return
	end
	local debugLogEnabled = WASYNC_MAIN_PRIVATE.DebugLog.IsEnabled(uid)
	if not debugLogEnabled then
		module:ErrorComms(sender, 6, "Debug log is disabled for "..id)
		return
	end

	local debugLog = WASYNC_MAIN_PRIVATE.DebugLog.GetLogs(uid)
	if not debugLog then
		module:ErrorComms(sender, 6, "No debug log for "..id)
		return
	end

	local encoded = AddonDB:CompressString(debugLog)
	AddonDB:SendComm("WAS_DEBUG", encoded, "WHISPER", sender)
end)

AddonDB:RegisterComm("WAS_DEBUG", function(prefix, sender, encoded)
	local debugLog, error = AddonDB:DecompressString(encoded)
	if not debugLog then
		prettyPrint(WASYNC_ERROR, "Failed to decompress debug log", sender, error)
		return
	end
	prettyPrint("Debug log from", sender, #debugLog, "bytes")
	MRT.F:Export(debugLog)
end)

function module:RequestReloadUI()
	AddonDB:SendComm("WAS_RELOADUI_REQUEST")
end

AddonDB:RegisterComm("WAS_RELOADUI_REQUEST", function(prefix, sender)
	if not AddonDB:CheckSenderPermissions(sender, WASync.isDebugMode) then
		return
	end
	module:ShowReloadPrompt(sender)
end)


function module:RequestWA(id,customTarget)
	AddonDB:SendComm("WAS_REQUEST_WA", AddonDB:CreateHeader(id), "WHISPER", customTarget)
	module.db.allowList[customTarget] = module.db.allowList[customTarget] or {}
	module.db.allowList[customTarget][id] = true
end

local baseRequestConfig = {
	importType = 1,
	send = true,
}
AddonDB:RegisterComm("WAS_REQUEST_WA", function(prefix, sender, msg, channel)
	if channel ~= "WHISPER" then return end

	local id = AddonDB:ParseHeader(msg)
	MLib:DialogPopup({
		id = "WASYNC_CONFIRM_REQUEST_WA",
		title = LR["WA Requested"],
		text = LR["%s requests your version of WA %q. Do you want to send it?"]:format(sender, id),
		buttons = {
			{
				text = YES,
				func = function()
					baseRequestConfig.customTarget = sender
					module:ExternalExportWA(id, baseRequestConfig)
				end
			},
			{
				text = NO,
			}
		},
	})
end)

function module:SendSetLoadNever(id, target, load_never)
	AddonDB:SendComm("WAS_SET_LOAD_NEVER", AddonDB:CreateHeader(id, load_never and "1" or "0"), "WHISPER", target)
end

AddonDB:RegisterComm("WAS_SET_LOAD_NEVER", function(prefix, sender, msg, channel, key)
	if channel ~= "WHISPER" then return end

	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		local id, load_never = AddonDB:ParseHeader(msg)
		prettyPrint(format("Set load_never for %q to %s by %s", id, load_never == "1" and "true" or "false", sender))
		module:SetLoadNever(id, load_never == "1")
	end
end)

function module:SendDeleteWA(id,target)
	MLib:DialogPopup({
		id = "WASYNC_CONFIRM_DELETE_WA",
		title = LR["Delete WA"],
		text = LR["Delete %q for %s?"]:format(id, target),
		buttons = {
			{
				text = YES,
				func = function()
					AddonDB:SendComm("WAS_DELETE_WA", AddonDB:CreateHeader(id), "WHISPER", target)
				end
			},
			{
				text = NO,
			}
		},
	})
end

AddonDB:RegisterComm("WAS_DELETE_WA", function(prefix, sender, msg, channel, key)
	if channel ~= "WHISPER" then return end

	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		local id = AddonDB:ParseHeader(msg)
		local WAData = WeakAuras.GetData(id)
		if WAData then
			module.Archive:Save(WAData,"On Delete "..sender)
			prettyPrint(format("Archived and deleted %q by %s", id, sender))
			for data in module.pTraverseAll(WAData) do
				WeakAuras.Delete(data)
			end
		end
	end
end)

function module:ErrorComms(sender, prefix, error)
	AddonDB:SendComm("WAS_IMPORT_ERROR", AddonDB:CreateHeader(prefix, error), "WHISPER", sender)
end

AddonDB:RegisterComm("WAS_IMPORT_ERROR", function (prefix, sender, data, channel, key)
	if channel ~= "WHISPER" then return end

	local code, error = AddonDB:ParseHeader(data)

	if code == "ERROR" then -- error while importing data
		pcall(PlaySoundFile,"Interface\\AddOns\\BugSack\\Media\\error.ogg","Master") -- fatality
		prettyPrint(WASYNC_ERROR, sender, "error while importing", "-", error)
	elseif code == "1" then -- missed transmission start
		prettyPrint(WASYNC_ERROR, sender, "- missed transmission start")
	elseif code == "2" then -- declined import
		-- error message is id
		prettyPrint(format("|cffee5555SKIPPED:|r %s - %q", sender, error))
	elseif code == "3" then -- aborted inspect request due to combat lockdown
		prettyPrint(WASYNC_ERROR, sender, "- aborted inspect request due to combat lockdown")
	elseif code == "4" then -- error when validating data
		-- error checking for hash, used to be "out of order" or "hash mismatch", but now only used for hash mismatch
		prettyPrint(WASYNC_ERROR, sender, error)
	elseif code == "5" then -- no data when requesting data for editor
		-- error message is id
		prettyPrint(WASYNC_ERROR, sender, "No data for", error)
	elseif code == "6" then -- error in requesting debug log
		prettyPrint(WASYNC_ERROR, "[DEBUG LOG]", sender, error)
	end
end)

function module:ForceAutoImport(name)
	AddonDB:SendComm("WAS_FORCE_AUTO_IMPORT", nil, "WHISPER", name)
end

AddonDB:RegisterComm("WAS_FORCE_AUTO_IMPORT", function(prefix, sender, msg, channel, key)
	if channel ~= "WHISPER" then return end

	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		if AddonDB.DoImports then
			AddonDB:DoImports(true)
		end
	end
end)

function AddonDB:RequestLeader()
	AddonDB:SendComm("WAS_REQUEST_LEADER")
end

AddonDB:RegisterComm("WAS_REQUEST_LEADER", function(prefix, sender, msg)
	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		PromoteToLeader(Ambiguate(sender,"none"))
	end
end)

function AddonDB:RequestAssistant()
	AddonDB:SendComm("WAS_REQUEST_ASSISTANT")
end

AddonDB:RegisterComm("WAS_REQUEST_ASSISTANT", function(prefix, sender, msg)
	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		PromoteToAssistant(Ambiguate(sender,"none"))
	end
end)

