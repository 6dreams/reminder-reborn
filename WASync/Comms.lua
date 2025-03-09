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

-- upvaluse
local tinsert = tinsert
local tremove = tremove
local strchar = strchar
local random = random
local ceil = ceil
local time = time
local format = format
local floor = floor
local max = max
local min = min
local strjoin = strjoin
local unpack = unpack

local prettyPrint = module.prettyPrint
local WASYNC_ERROR = module.WASYNC_ERROR
local importData = module.db.importData
local errorsData = module.db.errorsData

local LibDeflateAsync = LibStub:GetLibrary("LibDeflateAsync-reminder")
local LibSerializeAsync = LibStub:GetLibrary("LibSerializeAsync-reminder")
local configForLS = {
    errorOnUnserializableType = false
  }

local configForDeflate = {level = 9}

---@class dataToSend
---@field str string
---@field id string
---@field importMode number
---@field skipPrompt boolean
---@field channel string?
---@field touser string?
---@field exrtLastSync number? -- add this to let the receiver compare the last sync time

-- 14.7.2024
-- Blizzard per prefix throttle is 10 messages at once and than 1 message per second, if trying to send more messages dropped silently
-- MRT sending limits are:
-- 10 prefixes x 10 messages = 25500 symbols until prefix throttle
-- 10 prefixes x 1  messages = 2550  symbols during prefix throttle
-- We're throttling with delayC, setting minimal delay between messages
-- which redecues amount of burst messages to 20 per second (delayC = 0.05)
-- messages that sent after prefix limits are getting their throttle by MRT itself
-- Possible issues with low delayC values:
-- 1. Possible to get a disconnect if you send a lot of data at once
module.delayC = 0.05 -- 50 ms is a safe value

local SendExMsg = MRT.F.SendExMsgExt

local frame = CreateFrame("Frame")
module.SendingQueueFrame = frame
frame:Hide()

local messageQueue = {}
local partsTotal = 0
local partsSent = 0

function module.SendingQueueFrame:ProcessAll()
    for i=1,#messageQueue do
        messageQueue[i].justEnqueued = nil
    end
    frame:Show()
end

local function enqueueMessage(message)
    messageQueue[#messageQueue+1] = message
end

local function processMessage()
    if messageQueue[1] and messageQueue[1].justEnqueued then
        for i=2,#messageQueue do
            if not messageQueue[i].justEnqueued then
                tinsert(messageQueue,1,tremove(messageQueue,i))
                break
            end
        end
    end

    local message = messageQueue[1] and tremove(messageQueue[1],1)
    if #messageQueue[1] == 0 then
        tremove(messageQueue,1)
    end

    SendExMsg({ondone = message.ondone}, message.prefix, message.str, message.channel, message.touser)
end

do
    local tmr = 0
    frame:SetScript("OnUpdate", function(self,elapsed)
        tmr = tmr + elapsed
        if tmr > module.delayC then
            tmr = 0

            if #messageQueue == 0 then
                frame:Hide()
            else
                local anyToSend = false -- hide if no messages to send
                for i=1,#messageQueue do
                    if not messageQueue[i].justEnqueued then
                        anyToSend = true
                        break
                    end
                end
                if not anyToSend then
                    frame:Hide()
                    return
                end
                processMessage()
            end
        end
    end)
end

local imgData = {
    time = 0,
    num1 = 0,
    num2 = 0
}

---@param dataToSend dataToSend
---@param justEnqueue boolean?
function module:SendWA(dataToSend,justEnqueue,hideFrameOnFinish)
    local str = dataToSend.str
    local id = dataToSend.id
    local ImportType = dataToSend.importMode
    local channel = dataToSend.channel
    local touser = dataToSend.touser
    local skipPrompt = dataToSend.skipPrompt
    local needReload = dataToSend.needReload

    module:SetPending(dataToSend.id,60,dataToSend.touser,true)

    local tokenStr = strchar(random(33,255),random(33,255),random(33,255),random(33,255))


    if imgData.time < (time() - 120) then
        imgData.time = time()
        imgData.num1 = random(1, AddonDB.PUBLIC and 1 or #WASync.QueueSenderStrings)
        imgData.num2 = random(1, AddonDB.PUBLIC and 1 or AddonDB.TotalImages)
    end

	local parts = ceil(#str / 247)

    local entry = {}
    local entryKey = tostring(entry)

    local function ondoneFirst()
        partsTotal = parts
        partsSent = 0
        module.SenderFrame:UpdateBar(entryKey,0,partsTotal)
    end
    local function ondoneNext()
        partsSent = partsSent + 1
        module.SenderFrame:UpdateBar(entryKey,partsSent,partsTotal)
    end
    local function ondoneFinal()
        partsTotal = 0
        partsSent = 0
        module.SenderFrame:FinishBar(entryKey)
		if hideFrameOnFinish and not next(module.SenderFrame.SendQueueFrame.queue) then
			module.SenderFrame:Hide()
		end

        prettyPrint(format("|cff0080ffSENDED:|r %q | %s | %s", id, WASync.ImportTypes[ImportType], touser or channel or "Auto"))
    end

    -- header
    local hash = LibDeflateAsync:Adler32(str)
    hash = format("%X",hash)

    local header = tokenStr .. strjoin("^","start",WASync.VERSION,parts,id,ImportType,imgData.num1,imgData.num2,(dataToSend.exrtLastSync or ""),touser or "",skipPrompt and "1" or "", needReload and "1" or "", hash)

    if #header > 255 then
        prettyPrint(WASYNC_ERROR,"Header is too long", #header)
        return
    end

    entry[#entry+1] = {
        prefix = "WAS",
        str = header,
        channel = channel,
        touser = touser,
        ondone = ondoneFirst
    }


    -- data
    for i=1,parts do
        entry[#entry+1] = {
            prefix = "WAS",
            str = tokenStr..str:sub( (i-1)*247+1 , i*247 ),
            channel = channel,
            touser = touser,
            ondone = ondoneNext
        }
    end
    -- final
    entry[#entry+1] = {
        prefix ="WAS",
        str = tokenStr .. "Done",
        channel = channel,
        touser = touser,
        ondone = ondoneFinal
    }

    if justEnqueue then
        entry.justEnqueued = true
    end


    module.SenderFrame:AddToQueue(entryKey,id,parts,justEnqueue)
    enqueueMessage(entry)
    frame:Show()
end


local throttleError = function() module.throttleError = false end

local prev_addonMessage = module.addonMessage
function module:addonMessage(sender, prefix, data, ...)
    -- ensure sender has -realm suffix
    local name,realm = strsplit("-",sender)
    if not realm then
        local normalizedRealm = MRT.SDB.realmKey or GetNormalizedRealmName()
        sender = name.."-"..normalizedRealm
    end
	prev_addonMessage(self,sender, prefix, data, ...)
	if prefix == "WAS" then -- we don't use AddonDB:RegisterComm here coz we want progress tooltips
		local checkForID = false
		local isPass, reason = AddonDB:CheckSenderPermissions(sender, WASync.isDebugMode)
		if not isPass and module.db.allowList[sender] then
			checkForID = true
		elseif not isPass then
			if reason and not module.throttleError then
				module.throttleError = true
				C_Timer.After(15,throttleError)

				prettyPrint(WASYNC_ERROR, format(LR.WASNoPermission, sender, reason))
			end
			return
		end

        module.lastAddonMsg = GetTime()
		local token = data:sub(1,4)
		local str = data:sub(5,-1)

        -- TODO remove Done part from sending,
        -- we can just count parts knowing total amount from header,
        -- also kinda want to implement packet counter into string in case packets are out of order
		if str:find("^Done") and importData[sender] and importData[sender][token] then
            ItemRefTooltip:Hide()

            local impData = importData[sender][token]
            if impData.ignore then
                importData[sender][token] = nil
                return
            end
			str = impData.str
            if str then
                local hash = LibDeflateAsync:Adler32(str)
                if impData.hash and (hash % 4294967296) == (impData.hash % 4294967296) then
                    impData.ready = true

                    ---@type queueItem
                    local queueItem = {
                        id = impData.id,
                        str = str,
                        importMode = module.PUBLIC and 1 or impData.importMode,
                        stringNum = impData.stringNum,
                        imageNum = impData.imageNum,
                        sender = sender,
                        skipPrompt = impData.skipPrompt,
                        needReload = impData.needReload
                    }

                    module.QueueFrame:AddToQueue(queueItem)
                else
                    prettyPrint(WASYNC_ERROR,"GOT CORRUPTED DATA, HASH MISMATCH")
					module:ErrorComms(sender, 4, (impData.i == impData.parts and "msg out of order" or "hash mismatch"))
                end
            end
            importData[sender][token] = nil
        elseif str:find("^start") then
            local startText, version, parts, id, importMode, stringNum, imageNum, lastSync, target, skipPrompt, needReload, hash = strsplit("^",str)

            if tonumber(version or "?") ~= WASync.VERSION then
                if tonumber(version or "0") > WASync.VERSION then
                    prettyPrint(WASYNC_ERROR,"Your WeakAuras Sync version is outdated (sender ver."..(version or "unk")..", your addon ver."..WASync.VERSION..")")
                else
                    prettyPrint(WASYNC_ERROR,"Import data is outdated (sender ver."..(version or "unk")..", your addon ver."..WASync.VERSION..")")
                end
                return
            end
            importData[sender] = importData[sender] or {}
            importData[sender][token] = {
                str = "",
                parts = tonumber(parts),
                i = 0,
                id = id,
                importMode = tonumber(importMode),
                stringNum = tonumber(stringNum),
                imageNum = tonumber(imageNum),
                ready = false,
                skipPrompt = skipPrompt == "1" and AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender),
                needReload = needReload == "1",
                hash = tonumber(hash or "?", 16),
            }
            if lastSync and tonumber(lastSync) then
                local WAdata = WeakAuras.GetData(id)
                if WAdata and WAdata.exrtLastSync and WAdata.exrtLastSync >= tonumber(lastSync) and tonumber(importMode) < 4 and not (WASync.isDebugMode and UnitIsUnit('player',MRT.F.delUnitNameServer(sender))) then
					prettyPrint(format("%q is up to date. Ignoring update",id))
                    importData[sender][token].ignore = true
                    module:SendWAVer(id)
                end
            end

            if target and target ~= "" and Ambiguate(target,"none") ~= UnitName('player') then
                importData[sender][token].ignore = true
            end
			if checkForID and not module.db.allowList[sender][id] then
				prettyPrint(WASYNC_ERROR, format(LR.WASNoPermission, sender, id),"is not in white list")
				importData[sender][token].ignore = true
			end
		else -- data itself
            if importData[sender] and importData[sender][token] then
				if importData[sender][token].ignore then return end
				local str = table.concat({str, ...}, "\t")

				local impData = importData[sender][token]
				impData.str = impData.str .. str
				impData.i = impData.i + 1

				local red = min(255, (1 - impData.i / impData.parts) * 511)
				local green = min(255, (impData.i / impData.parts) * 511)
				module.ShowTooltip({
					{1, "WeakAuras Sync", 0.533, 0, 1},
					{1, "Accepting WeakAuras data from " .. Ambiguate(sender,"none"), 1, 0.82, 0},
					{1," "},
					{1, impData.id, 1, 1, 1},
					{2, WASync.ImportTypes[impData.importMode], ("|cFF%2x%2x00"):format(red, green)..impData.i * 251 .."|cFF00FF00/"..impData.parts * 251, 1, 1, 1}
				})
            else
                if not errorsData[token] then
                    errorsData[token] = true
					module:ErrorComms(sender, 1, "missed import start")
                end
            end
		end
	elseif prefix == "WAS_STATUS" then
		if data == "10" then --polling addon version with /rt was ver
			MRT.F.SendExMsg("WAS_STATUS", "11\t"..WASync.VERSION)
		elseif data == "11" then -- answers for addon version
			local ver = ...
			if not ver or not module.db.gettedVersions then
				return
			end
			module.db.gettedVersions[sender] = ver
		elseif data == "1" then -- some unused stuff i guess
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

			module.db.responcesData[ sender ] = module.db.responcesData[ sender ] or {}
			module.db.responcesData[ sender ][id] = module.db.responcesData[ sender ][id] or {}
            local db = module.db.responcesData[ sender ][id]
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
	elseif prefix == "WAS_IMPORT_ERROR" then
		if data == "ERROR" then
			local waSender, success, error = ...
			if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then
                pcall(PlaySoundFile,"Interface\\AddOns\\BugSack\\Media\\error.ogg","Master")
				prettyPrint(WASYNC_ERROR, sender, "-", success, "-", error)
			end
        elseif data == "1" then -- missed import start
            local waSender = ...
			if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then
                prettyPrint(WASYNC_ERROR, sender, "- missed import start")
            end
        elseif data == "2" then -- declined import
            local waSender,id = ...
            if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then

                prettyPrint(format("|cffee5555SKIPPED:|r %s - %q", sender, id))
            end
        elseif data == "3" then -- aborted inspect request due to combat lockdown
            local waSender = ...
            if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then
                prettyPrint(WASYNC_ERROR, sender, "- aborted inspect request due to combat lockdown")
            end
        elseif data == "4" then -- error when validating data
            local waSender, error = ...
            if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then
                prettyPrint(WASYNC_ERROR, sender, error)
            end
		elseif data == "5" then -- no data when requesting data for editor
			local waSender, id = ...
			if MRT.F.delUnitNameServer(waSender) == MRT.SDB.charName then
				prettyPrint(WASYNC_ERROR, sender, "No data for", id)
			end
		end
    elseif prefix == "WASIR" then -- request wa map
        if not AddonDB:CheckSenderPermissions(sender,WASync.isDebugMode,true) then
			return
		end

        local reciever, parent, maxDepth = data, ...

        if MRT.F.delUnitNameServer(reciever) ~= UnitName'player' then
            return
        end

        if InCombatLockdown() then
			module:ErrorComms(sender, 3)
            return
        end

        -- sender requested wa map for parent

        if parent == "" then parent = nil end
        maxDepth = tonumber(maxDepth or "?") or 0
        prettyPrint(sender, "requested WA map:", parent or "Full Map","| depth:", maxDepth)

        module:SendWAMap(sender, parent, maxDepth)
    end
end


---@class versionsAnswer
---@field id string
---@field exrtLastSync number
---@field exrtLastSender string?
---@field version number?
---@field semver string?
---@field load_never boolean?


---@type versionsAnswer[]
local versionsData = {}
local d = versionsData[1]

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

            tinsert(answer,a)
        else
            tinsert(answer,{id = id, NO_WA = true})
        end
    end
    local serialized = LibSerializeAsync:SerializeEx(configForLS,answer)
    local compressed = LibDeflateAsync:CompressDeflate(serialized,configForDeflate)
    local str = LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
    AddonDB:SendComm("WAS_VM", str)
end

AddonDB:RegisterComm("WAS_VM", function(prefix, sender, encoded, ...)
    if prefix == "WAS_VM" then
        local compressed = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
        local serialized = LibDeflateAsync:DecompressDeflate(compressed)
        local success, answer = LibSerializeAsync:Deserialize(serialized)
        if not success then
            prettyPrint(WASYNC_ERROR,"Failed to deserialize versions answer", sender)
            return
        end
        for i=1,#answer do
            local a = answer[i]
            local id = a.id
            if a.NO_WA then
                module.db.responces[sender] = module.db.responces[sender] or {}
                module.db.responces[sender][id] = 1
            else
                module.db.responcesData[sender] = module.db.responcesData[sender] or {}
                module.db.responcesData[sender][id] = module.db.responcesData[sender][id] or {}
                local db = module.db.responcesData[sender][id]
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

function module:RequestDebugLog(id,customTarget)
	AddonDB:SendComm("WAS_DEBUG_REQUEST", id, nil, "WHISPER", customTarget)
end

AddonDB:RegisterComm("WAS_DEBUG_ERROR", function(prefix, sender, error)
	prettyPrint(WASYNC_ERROR, sender, error)
end)

AddonDB:RegisterComm("WAS_DEBUG_REQUEST", function(prefix, sender, id)
	if not WASYNC_MAIN_PRIVATE then
		AddonDB:SendComm("WAS_DEBUG_ERROR", "WASYNC_MAIN_PRIVATE is not declared", nil, "WHISPER", sender)
		return
	end
	local uid = WeakAuras.GetData(id) and WeakAuras.GetData(id).uid
	if not uid then
		AddonDB:SendComm("WAS_DEBUG_ERROR", "No uid for "..id, nil, "WHISPER", sender)
		return
	end
	local debugLogEnabled = WASYNC_MAIN_PRIVATE.DebugLog.IsEnabled(uid)
	if not debugLogEnabled then
		AddonDB:SendComm("WAS_DEBUG_ERROR", "Debug log is disabled for "..id, nil, "WHISPER", sender)
		return
	end

	local debugLog = WASYNC_MAIN_PRIVATE.DebugLog.GetLogs(uid)
	if not debugLog then
		AddonDB:SendComm("WAS_DEBUG_ERROR", "No debug log for "..id, nil, "WHISPER", sender)
		return
	end
	local compressed = LibDeflateAsync:CompressDeflate(debugLog,configForDeflate)
	local str = LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
	AddonDB:SendComm("WAS_DEBUG", str, nil, "WHISPER", sender)
end)

AddonDB:RegisterComm("WAS_DEBUG", function(prefix, sender, encoded)
	local compressed = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
	local debugLog = LibDeflateAsync:DecompressDeflate(compressed)
	if not debugLog then
		prettyPrint(WASYNC_ERROR,"Failed to decompress debug log", sender)
		return
	end
	prettyPrint("Debug log from", sender, #debugLog, "bytes")
	MRT.F:Export(debugLog)
end)

function module:RequestReloadUI()
	AddonDB:SendComm("WAS_RELOADUI_REQUEST")
end

AddonDB:RegisterComm("WAS_RELOADUI_REQUEST", function(prefix, sender)
	if not AddonDB:CheckSenderPermissions(sender,WASync.isDebugMode) then
		return
	end
	module:ShowReloadPrompt(sender)
end)


function module:RequestWA(id,customTarget)
	AddonDB:SendComm("WAS_REQUEST_WA", id.."\t"..customTarget, nil, "WHISPER", customTarget)
	module.db.allowList[customTarget] = module.db.allowList[customTarget] or {}
	module.db.allowList[customTarget][id] = true
end

local baseRequestConfig = {
	ImportType = 1,
	send = true,
}
AddonDB:RegisterComm("WAS_REQUEST_WA", function(prefix, sender, msg, channel)
	local id, customTarget = strsplit("\t",msg)
	if customTarget == MRT.SDB.charKey or customTarget == MRT.SDB.charName then
		StaticPopupDialogs["WASYNC_CONFIRM_REQUEST_WA"] = {
			text = format(LR["%s requests your version of WA %q. Do you want to send it?"], sender, id),
			button1 = YES or "Yes",
			button2 = NO or "No",
			OnAccept = function()
				baseRequestConfig.customTarget = sender
				module:ExternalExportWA(id, baseRequestConfig)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("WASYNC_CONFIRM_REQUEST_WA")
	end
end)

function module:SendSetLoadNever(id,target,load_never)
	AddonDB:SendComm("WAS_SET_LOAD_NEVER", id.."\t"..(load_never and "1" or "0").."\t"..target)
end

AddonDB:RegisterComm("WAS_SET_LOAD_NEVER", function(prefix, sender, msg)
	local id, load_never, target = strsplit("\t",msg)
	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) and target == MRT.SDB.charKey or target == MRT.SDB.charName  then
		prettyPrint(format("Set load_never for %q to %s by %s", id, load_never =="1" and "true" or "false", sender))
		module:SetLoadNever(id,load_never == "1")
	end
end)

function module:SendDeleteWA(id,target)
	StaticPopupDialogs["WASYNC_CONFIRM_DELETE_WA"] = {
		text = format("Delete %q for %s?", target, id),
		button1 = YES or "Yes",
		button2 = NO or "No",
		OnAccept = function()
			AddonDB:SendComm("WAS_DELETE_WA", id.."\t"..target)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
		preferredIndex = 3,
	}
	StaticPopup_Show("WASYNC_CONFIRM_DELETE_WA")
end

AddonDB:RegisterComm("WAS_DELETE_WA", function(prefix, sender, msg)
	local id, target = strsplit("\t",msg)
	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) and target == MRT.SDB.charKey or target == MRT.SDB.charName  then
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
	assert(sender and (prefix or error), "ErrorComms: sender and error are required")
	MRT.F.SendExMsg("WAS_IMPORT_ERROR",  (prefix or "ERROR").."\t" .. sender .. (error and ("\t" .. error) or ""))
end

function module:ForceAutoImport(name)
	AddonDB:SendComm("WAS_FORCE_AUTO_IMPORT",name)
end

AddonDB:RegisterComm("WAS_FORCE_AUTO_IMPORT", function(prefix, sender, name)
	if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		if name == MRT.SDB.charKey or name == MRT.SDB.charName then
			if AddonDB.DoImports then
				AddonDB:DoImports(true)
			end
		end
	end
end)
