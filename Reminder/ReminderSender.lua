local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ReminderModule: MRTmodule
local module = MRT.A.Reminder
if not module then return end

---@class Locale
local LR = AddonDB.LR

---@class VMRT
local VMRT = VMRT

---@class ELib
local ELib = MRT.lib

---@class MLib
local MLib = AddonDB.MLib

local LibDeflate = LibStub:GetLibrary("LibDeflate")

local SENDER_VERSION = module.SENDER_VERSION
local DATA_VERSION = module.DATA_VERSION

--upvalues
local next,ipairs,type,tonumber,select,ceil,math = next,ipairs,type,tonumber,select,ceil,math
local time = time
local strsplit = strsplit
local tostring = tostring
local bit = bit

local prettyPrint = module.prettyPrint

module.db.gettedVersions = {}
module.db.getVersion = 0

module.db.responcesData = {}

module.Sender = {
    LastUpdateSender = {
        -- ["name"] = {
        --     time = GetTime(),
        --     totalSent = 0,
        --     totalUpdated = 0,
        --     totalNew = 0,
        --     totalLocked = 0,
        -- },
    },
}

local DELIMITER_1 = string.char(19)
local DELIMITER_2 = string.char(20)

local checkType = {
    ["invert"] = true,
    ["onlyPlayer"] = true,
}
local stringType = {
    ["sourceName"] = true,
    ["sourceID"] = true,
    ["targetName"] = true,
    ["targetID"] = true,
    ["spellName"] = true,
    ["pattFind"] = true,
    ["counter"] = true,
    ["delayTime"] = true,
    ["stacks"] = true,
    ["numberPercent"] = true,
}
local numberType = {
    ["sourceMark"] = true,
    ["targetMark"] = true,
    ["spellID"] = true,
    ["extraSpellID"] = true,
    ["bwtimeleft"] = true,
    ["cbehavior"] = true,
    ["activeTime"] = true,
    ["guidunit"] = true,
    ["targetRole"] = true,
}
local mixedType = {
    ["sourceUnit"] = true,
    ["targetUnit"] = true,
}
module.datas.triggerFieldTypes = {
    ["event"] = "number",
    ["andor"] = "number",
    ["eventCLEU"] = "string",
    ["invert"] = "boolean",
    ["onlyPlayer"] = "boolean",
    ["sourceName"] = "string",
    ["sourceID"] = "string",
    ["targetName"] = "string",
    ["targetID"] = "string",
    ["spellName"] = "string",
    ["pattFind"] = "string",
    ["counter"] = {"number","string"},
    ["delayTime"] = "string",
    ["stacks"] = "string",
    ["numberPercent"] = "string",
    ["sourceMark"] = "number",
    ["targetMark"] = "number",
    ["spellID"] = "number",
    ["extraSpellID"] = "number",
    ["bwtimeleft"] = "number",
    ["cbehavior"] = "number",
    ["activeTime"] = "number",
    ["guidunit"] = "number",
    ["targetRole"] = "number",
    ["sourceUnit"] = {"number","string"},
    ["targetUnit"] = {"number","string"},

}
local cleu_events = {}
for k,v in next, module.C do
    if v.main_id == 1 and v.subID then
        cleu_events[tostring(v.subID)] = k
        cleu_events[k] = tostring(v.subID)
    end
end
function module:GetTriggerSyncString(trigger)
    local r = (trigger.event or "") .. DELIMITER_2 .. (trigger.andor or "")

    local eventDB
    if trigger.event == 1 then
        eventDB = module.C[trigger.eventCLEU or 0]
    else
        eventDB = module.C[trigger.event or 0]
    end

    local keysList
    if eventDB then
        keysList = eventDB.triggerSynqFields or eventDB.triggerFields
    end
    if keysList then
        for i=1,#keysList do
            local key = keysList[i]
            if key == "eventCLEU" then
                r = r .. DELIMITER_2 .. (cleu_events[ trigger[key] or 0 ] or trigger[key] or "")
            elseif checkType[key] then
                r = r .. DELIMITER_2 .. (trigger[key] and "1" or "")
            elseif stringType[key] then
                r = r .. DELIMITER_2 .. tostring(trigger[key] or "") -- :gsub(STRING_CONVERT.encodePatt,STRING_CONVERT.encodeFunc)
            else
                r = r .. DELIMITER_2 .. (trigger[key] or "")
            end
        end
    end

    r = r:gsub("["..DELIMITER_2.."]+$","")

    return r
end

--[[

Export string format:
1st string is always info about sender and data versions

SENDER_VER^DATA_VER^EXPORT_TIME
token^boss^diff^name^msg^duration^delay^trigeersNum^triggersData^checks^
loadOptions^soundOptions^glow^spamOptions^glowOptions^zoneID^countdownType^extraCheck^specialTarget^
comment^msgSize^RGOptions^WAmsg


local nameplateText, glowType, glowColor, glowThick, glowScale, glowN, glowImage = strsplit(DELIMITER_1, glowOptions or "")
local spamMsg ,spamType, spamChannel = strsplit(DELIMITER_1, spamOptions or "")
local units, roles, classes, notepat, groups = strsplit(DELIMITER_1, loadOptions or "")
local sound, tts, voiceCountdown = strsplit(DELIMITER_1, soundOptions or "")
local RGAPIList, RGAPICondition = strsplit(DELIMITER_1, RGOptions or "")

local checksTable = {"countdown", "reversed", "nameplateGlow", "glowOnlyText", "doNotLoadOnBosses", "dynamicdisable", "norewrite", "copy", "disabled", "defDisabled", "RGAPIOnlyRG", "noteIsBlock", "sametargets"}
]]

local compareIgnoreFields = {
    ["lastSync"] = true,
    ["lastSender"] = true,
    ["isPersonal"] = true,
    ["notSync"] = true,
    ["sound"] = true,
    ["soundOnHide"] = true,
    ["tts"] = true,
    ["debug"] = true,
}

-- return true if data has changes
local function CompareReminders(data1, data2)
    if type(data1) ~= 'table' or type(data2) ~= 'table' then
        return true
    end

    local function deepCompare(t1, t2)
        if type(t1) ~= 'table' or type(t2) ~= 'table' then
            return t1 == t2
        end
        for k, v in next, t1 do
            if not compareIgnoreFields[k] then
                if not deepCompare(v, t2[k]) then
                    return false
                end
            end
        end
        for k, v in next, t2 do
            if not compareIgnoreFields[k] then
                if not deepCompare(v, t1[k]) then
                    return false
                end
            end
        end
        return true
    end

    return not deepCompare(data1, data2)
end

---@param data ReminderData
local function CheckDataIntegrity(data)
    for k,v in next, module.SetupFrameDataRequirements do
        if type(k) == 'number' then --always check
            local oneOF = false
            if not data[ v["exception"] ] then
                for i,field in ipairs(v) do
                    if field == 0 then
                        oneOF = i + 1
                    elseif oneOF then
                        local anyFilled
                        for j=oneOF,#v do
                            if data[ v[j] ] then
                                anyFilled = true
                            end
                        end
                        if not anyFilled then
                            for  j=oneOF,#v do
                                return true
                            end
                        end
                    else
                        if not data[field] then
                            return true
                        end
                    end
                end
            end
        elseif type(k) == 'string' then --check only if SetupFrame.data[k]
            if data[k] then
                for i,field in ipairs(v) do
                    if not data[field] then
                        return true
                    end
                end
            end
        end
    end

end

local checksTable = {"countdown", "reversed", "nameplateGlow", "glowOnlyText", "doNotLoadOnBosses", "dynamicdisable",
"norewrite", "copy", "disabled", "defDisabled", "RGAPIOnlyRG", "noteIsBlock", "sametargets", "durrev", "hideTextChanged", "ignoreTimeline"}
local function GetChecksString(data)
    local checks = ""

    for i=1,#checksTable do
        local key = checksTable[i]
        checks = (data[key] and "1" or "0") .. checks
    end
    checks = tonumber(checks,2)
    return checks ~= 0 and checks or ""
end

local function GetClassesString(data)
    local classes = ""
    local classesList = MRT.GDB.ClassList
    if data.classes then
        for i=1,#MRT.GDB.ClassList do
            classes = (data.classes:find("#".. classesList[i] .. "#") and "1" or "0") .. classes
        end
    end
    classes = tonumber(classes,2)
    return classes ~= 0 and classes or ""
end

local function GetRolesString(data)
    local roles = ""
    local rolesList = module.datas.rolesList
    if data.roles then
        for i=1,#rolesList do
            roles =  (data.roles:find("#" .. rolesList[i][3] .. "#") and "1" or "0") .. roles
        end
    end
    roles = tonumber(roles,2)
    return roles ~= 0 and roles or ""
end

local function TruncateOptionsString(string,isExport)
    string = string:gsub("%^", ""):gsub("["..DELIMITER_1.."]+$","") -- preventing griefed input
    if isExport then
        string = string:gsub("\\19",""):gsub("\\20",""):gsub(DELIMITER_1,"\\19") -- export fix
    end
    return string
end

local r
local soundPatt1 = "^[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee][\\/][Aa][Dd][Dd][Oo][Nn][Ss][\\/]"
function module:GetExportDataString(data,rc,isExport)

    local WRONG_DATA = CheckDataIntegrity(data)

    if WRONG_DATA then
        prettyPrint("|cffff0000Can't send reminder:", data.name, data.token)
        return rc
    else
        if data.isPersonal then return rc end
        local triggersData = ""
        if data.triggers and #data.triggers > 0 then
            for i=1,#data.triggers do
                triggersData = triggersData .. module:GetTriggerSyncString(data.triggers[i]) .. DELIMITER_1
            end
        end

        triggersData = triggersData:gsub("%^", "") -- preventing griefed input
        if isExport then
            triggersData = triggersData:gsub("\\19",""):gsub("\\20",""):gsub(DELIMITER_1,"\\19"):gsub(DELIMITER_2,"\\20")--export fix
        end

        local glowOptions = table.concat({
            (data.nameplateText or ""),
            (data.glowType or ""),
            (data.glowColor or ""),
            (data.glowThick or ""),
            (data.glowScale or ""),
            (data.glowN or ""),
            (data.glowImage or ""),
            (data.glowFrameColor or "")
        },DELIMITER_1)
        glowOptions = TruncateOptionsString(glowOptions,isExport)

        local spamOptions = table.concat({
            (data.spamMsg or ""),
            (data.spamType or ""),
            (data.spamChannel or "")
        },DELIMITER_1)
        spamOptions = TruncateOptionsString(spamOptions,isExport)


        local checks = GetChecksString(data)
        local classes = GetClassesString(data)
        local roles = GetRolesString(data)

        local loadOptions = table.concat({
            (data.units or ""),
            (roles or ""),
            (classes or ""),
            (data.notepat or ""),
            (data.groups or "")
        },DELIMITER_1)

        loadOptions = TruncateOptionsString(loadOptions,isExport)

        local soundOptions = table.concat({
                (type(data.sound) == 'string' and
                    data.sound:gsub("%^", "")
                        :gsub(soundPatt1 .. "SharedMedia","IAOSM")
                        :gsub(soundPatt1 .. "WeakAuras\\Media\\","IAOWA")
                        :gsub(soundPatt1, "IAO") or
                    data.sound or ""),
                (data.tts or ""),
                (data.voiceCountdown or ""),
                (type(data.soundOnHide) == 'string' and
                data.soundOnHide:gsub("%^", "")
                    :gsub(soundPatt1 .. "SharedMedia","IAOSM")
                    :gsub(soundPatt1 .. "WeakAuras\\Media\\","IAOWA")
                    :gsub(soundPatt1, "IAO") or
                data.soundOnHide or "")
                            },DELIMITER_1)
        soundOptions = TruncateOptionsString(soundOptions,isExport)

        local RGOptions = table.concat({
            (data.RGAPIList or ""),
            (data.RGAPICondition or ""),
            (data.RGAPIAlias or ""),
        },DELIMITER_1)
        RGOptions = TruncateOptionsString(RGOptions,isExport)

        local barOptions = table.concat({
            (data.barColor or ""),
            (data.barTicks or ""),
            (data.barIcon or ""),
        },DELIMITER_1)
        barOptions = TruncateOptionsString(barOptions,isExport)

        r[#r+1] =
            table.concat({
                data.token, -- 100%
                (data.boss or ""),  -- 92.43%
                (data.diff or ""),  -- 68%
                (data.name or ""),  -- 99%
                (data.msg and data.msg:gsub("%^", "") or ""),  -- 96%
                (data.duration or ""), -- 98.3%
                (data.delay and data.delay:gsub("%^", "") or ""),  -- 80.5%
                (data.triggers and #data.triggers or ""), -- 28.5%
                (triggersData), -- 28.5%
                (checks), -- 34%
                (loadOptions),  -- 55%
                (soundOptions), -- 44%
                (data.glow and data.glow:gsub("%^", "") or ""), -- 10%
                (spamOptions),-- 6%
                (glowOptions), -- 2%
                (data.zoneID and string.gsub(tostring(data.zoneID), "%^", "") or ""), -- 3.24%
                (data.countdownType or ""),-- 2.7%
                (data.extraCheck and data.extraCheck:gsub("%^", "") or ""),-- 1%
                (data.specialTarget and data.specialTarget:gsub("%^", "") or ""), -- .. "^" .. --0.5%
                (data.comment and data.comment:gsub("%^", "") or ""),
                (data.msgSize or ""),
                (RGOptions),
                (data.WAmsg or ""):gsub("%^", ""),
                (barOptions),

            }, "^"):gsub("[%^]+$",""):gsub("\n","\\n") -- removing useless ^ at the end and all newlines as they break the import

        rc = rc + 1
    end
    return rc
end

local prevIndex = nil

function module:Sync(isExport,bossID,zoneID,token,noHeader,liveSession)
    local now = time()
    r = noHeader and {} or {(SENDER_VERSION .. "^" .. DATA_VERSION .. "^" .. now)}
    local rc = 0

    for _,data in next, VMRT.Reminder.data do
        if
            (not bossID and not zoneID and not token) or
            (bossID and ((type(bossID) == "table" and data.boss and bossID[data.boss]) or (type(bossID) ~= "table" and data.boss == bossID))) or
            (bossID == -1 and not data.boss and not data.zoneID) or
            (zoneID and module:FindNumberInString(zoneID,data.zoneID)) or
            (token and data.token == token)
        then
            rc = module:GetExportDataString(data,rc,isExport)
            if not isExport then
                if not liveSession then data.notSync = false end
                data.lastSync = now
                data.lastSender = MRT.GDB.charKey
            end
        end
    end

    if token and rc == 0 and liveSession then -- deleting 1 reminder through live Sync comms
        r[#r+1] =  token .. "^"
        rc = rc + 1
    elseif not token and not isExport then -- dont include deleted part when sending 1 reminder and when exporting
        for t in next, VMRT.Reminder.removed do
            r[#r+1] = t .. "^"
        end
    end
    local str = table.concat(r,"\n")
    str = str:gsub("\n+$","")
    if isExport then
        return str
    end
    if module.options.Update then
        module.options.Update()
    end

    if rc > 0 then
        local compressed = LibDeflate:CompressDeflate(str,{level = 9})
        local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

        encoded = encoded .. "##F##"

        prettyPrint("|cff80ff00Sent reminders count: " .. rc .. "|r")

        local newIndex = math.random(0,9)
        while prevIndex == newIndex do
            newIndex = math.random(0,9)
        end
        prevIndex = newIndex


        newIndex = tostring(newIndex)
        local parts = ceil(#encoded / 242)

        -- prettyPrint("Reminder data length:","\ntotal:",rc,"\nencoded:",#encoded,"\ndecoded:",#str,"\nencoded per reminder:",#encoded/rc,"\ndecoded per reminder",#str/rc)

        for i = 1, parts do
            local msg = encoded:sub((i - 1) * 242 + 1, i * 242)
            if liveSession then
                MRT.F.SendExMsg("reminder", "L\t" .. newIndex .. "\t" .. msg)
            else
                MRT.F.SendExMsg("reminder", "D\t" .. newIndex .. "\t" .. msg)
            end
        end
    else
        prettyPrint("|cffee5555Sent reminders count: " .. rc .. "|r")
    end
end

 --[[
    first check
[Reminder] Reminder data length:
total: 193
encoded: 8970
decoded: 33397
encoded per reminder: 46.476683937824
decoded per reminder 173.0414507772

    v32 first (binary classes and roles)
[03:46:17] [Reminder] Reminder data length:
total: 185
encoded: 8459
decoded: 30659
encoded per reminder: 45.724324324324
decoded per reminder 165.72432432432

    v32 second (added EVENT_KEYS)
[03:52:52] [Reminder] Reminder data length:
total: 185
encoded: 8303
decoded: 28524
encoded per reminder: 44.881081081081
decoded per reminder 154.18378378378

    v32 third (added partial encoding for sound paths)
[04:57:17] [Reminder] Reminder data length:
total: 185
encoded: 8295
decoded: 27349
encoded per reminder: 44.837837837838
decoded per reminder 147.83243243243

    v32 fourth (fixed delimiters sent, stacked spam settings to spamOptions group)
[07:38:20] [Reminder] Reminder data length:
total: 185
encoded: 8253
decoded: 25890
encoded per reminder: 44.610810810811
decoded per reminder 139.94594594595

    v32 fifth (not sending 0 in bit arrays)
[05:08:28] [Reminder] Reminder data length:
total: 185
encoded: 8185
decoded: 25386
encoded per reminder: 44.243243243243
decoded per reminder 137.22162162162

    v32 sixth (stacked more data to 'options' groups)
[07:26:35] [Reminder] Reminder data length:
total: 185
encoded: 8157
decoded: 25003
encoded per reminder: 44.091891891892
decoded per reminder 135.15135135135

    v48 diagnostics, encoded per reminder looks good
[05:16:09] [Reminder] Reminder data length:
total: 686
encoded: 29386
decoded: 100377
encoded per reminder: 42.836734693878
decoded per reminder 146.3221574344
]]

function module:ProcessTextToData(text,isImport,sender,liveSession,ignoreOutdated)
    -- NaN in strings from excel workaround
    local importTime
    local text, replaces = text:gsub("%^(NaN)",function() prettyPrint("Found 'NaN' in import string, import data may be incomplete.")return "^" end)
    if replaces > 0 then
        StaticPopupDialogs["EXRT_REMINDER_CORRUPTED_DATA_ALERT"] = {
            text = "Found 'NaN' in import string, delete 'NaN' from string and import data or cancel import\n|cffff0000IMPORT DATA MAY BE INCOMPLETE",
            button1 = ACCEPT,
            button2 = CANCEL,
            OnAccept = function()
                module:ProcessTextToData(text, isImport, sender, liveSession)
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("EXRT_REMINDER_CORRUPTED_DATA_ALERT")
        return
    end

    local data = {strsplit("\n",text)}
    if data[1] then
        local VER,DATA_VER,EXPORT_TIME = strsplit("^",data[1])
        importTime = tonumber(EXPORT_TIME)
        if tonumber(VER or "?") ~= SENDER_VERSION then
            if tonumber(VER or "0") > SENDER_VERSION then
                prettyPrint("Your reminder addon version is outdated (string ver."..(DATA_VER or "unk")..", your addon ver."..DATA_VERSION..")")
            else
                prettyPrint("Import data is outdated (string ver."..(DATA_VER or "unk")..", your addon ver."..DATA_VERSION..")")
            end
            return
        end
    else
        return
    end

    local SenderDB
    if sender then
        SenderDB = module.Sender.LastUpdateSender[sender]
        if not SenderDB.totalReminders or SenderDB.time and SenderDB.time < GetTime() - 4  then
            SenderDB.totalReminders = 0
            SenderDB.totalUpdated = 0
            SenderDB.totalNew = 0
            SenderDB.totalLocked = 0
            SenderDB.totalDeleted = 0
        end
    end

    for i=2,#data do
        local token,boss,diff,name,text,duration,delay,triggersNum,triggersData,checks,
            loadOptions,soundOptions,glow,spamOptions,glowOptions,zoneID,countdownType,
            extraCheck,specialTarget,comment,msgSize,RGOptions,WAmsg,barOptions = strsplit("^",data[i])

        token = tonumber(token)
        local triggers
        if triggersNum and tonumber(triggersNum) and tonumber(triggersNum) > 0 then
            triggers = {}
        end
        if token and not triggers then
            local data = VMRT.Reminder.data[token]
            if data and not VMRT.Reminder.locked[token] then
                module:DeleteReminder(data,true,true)
                if liveSession then
                    if not VMRT.Reminder.liveChanges.changed[token] and not VMRT.Reminder.liveChanges.added[token] then
                        VMRT.Reminder.liveChanges.changed[token] = data
                    end
                end

                if SenderDB then
                    SenderDB.totalDeleted = SenderDB.totalDeleted + 1
                end
            end
        elseif token and
		(
			not ignoreOutdated or
			not VMRT.Reminder.data[token] or
			not VMRT.Reminder.data[token].lastSync or
			VMRT.Reminder.data[token].lastSync < importTime
		) then
            --triggersData and glowOptions may be nil when importing old strings
            if isImport then
                if triggersData  then
                    triggersData = triggersData:gsub("\\19",DELIMITER_1):gsub("\\20",DELIMITER_2)
                end
                if glowOptions  then
                    glowOptions = glowOptions:gsub("\\19",DELIMITER_1)
                end
                if spamOptions  then
                    spamOptions = spamOptions:gsub("\\19",DELIMITER_1)
                end
                if loadOptions  then
                    loadOptions = loadOptions:gsub("\\19",DELIMITER_1)
                end
                if soundOptions  then
                    soundOptions = soundOptions:gsub("\\19",DELIMITER_1)
                end
                if RGOptions  then
                    RGOptions = RGOptions:gsub("\\19",DELIMITER_1)
                end
                if barOptions  then
                    barOptions = barOptions:gsub("\\19",DELIMITER_1)
                end
            end

            local nameplateText, glowType, glowColor, glowThick, glowScale, glowN, glowImage, glowFrameColor = strsplit(DELIMITER_1, glowOptions or "")
            local spamMsg ,spamType, spamChannel = strsplit(DELIMITER_1, spamOptions or "")
            local units, roles, classes, notepat, groups = strsplit(DELIMITER_1, loadOptions or "")
            local sound, tts, voiceCountdown, soundOnHide = strsplit(DELIMITER_1, soundOptions or "")
            local RGAPIList, RGAPICondition, RGAPIAlias = strsplit(DELIMITER_1, RGOptions or "")
            local barColor, barTicks, barIcon = strsplit(DELIMITER_1, barOptions or "")

            if glowImage then
                local num = tonumber(glowImage)
                if num and num < 1000 then
                    glowImage = num
                elseif glowImage == "" then
                    glowImage = nil
                end
            end

            -- print("token",token,"\n","boss",boss,"\n", "diff",diff,"\n", "name",name,"\n", "event",event,"\n", "text",text,"\n", "duration",duration,"\n", "delay",delay,"\n", "oldTypeOptions",oldTypeOptions,"\n", "triggersNum",triggersNum,"\n", "triggersData",triggersData,"\n", "checks",checks,"\n", "loadOptions",loadOptions,"\n", "soundOptions",soundOptions,"\n", "glow",glow,"\n", "spamOptions",spamOptions,"\n", "glowOptions",glowOptions,"\n", "zoneID",zoneID,"\n", "countdownType",countdownType,"\n", "extraCheck",extraCheck,"\n", "specialTarget",specialTarget,"\n", "comment",comment,"\n", "msgSize",msgSize,"\n", "RGOptions",RGOptions)

            local new = {
                token = token,
                boss = tonumber(boss),
                zoneID = zoneID ~= "" and zoneID or nil,
                delay = delay ~= "" and delay or nil,
                duration = tonumber(duration),
                units = units ~= "" and units or nil,
                msg = text ~= "" and text or nil,
                sound = sound and sound ~= "" and (tonumber(sound) or sound:gsub("^IAOSM","Interface\\Addons\\SharedMedia")
                                            :gsub("^IAOWA", "Interface\\AddOns\\WeakAuras\\Media\\")
                                            :gsub("^IAO", "Interface\\AddOns\\")) or nil,
                soundOnHide = soundOnHide and soundOnHide ~= "" and (tonumber(soundOnHide) or soundOnHide:gsub("^IAOSM","Interface\\Addons\\SharedMedia")
                                            :gsub("^IAOWA", "Interface\\AddOns\\WeakAuras\\Media\\")
                                            :gsub("^IAO", "Interface\\AddOns\\")) or nil,
                voiceCountdown = voiceCountdown ~= "" and tonumber(voiceCountdown) or nil,
                name = name ~= "" and name or nil,
                diff = tonumber(diff),
                notepat = notepat ~= "" and notepat or nil,
                tts = tts ~= "" and tts or nil,
                glow = glow ~= "" and glow or nil,
                spamType = tonumber(spamType),
                spamChannel = tonumber(spamChannel),
                spamMsg = spamMsg ~= "" and spamMsg or nil,
                countdownType = tonumber(countdownType) or nil,
                triggers = triggers,
                extraCheck = extraCheck ~= "" and extraCheck or nil,
                specialTarget = specialTarget ~= "" and specialTarget or nil,
                nameplateText = nameplateText ~= "" and nameplateText or nil,
                glowType = tonumber(glowType),
                glowColor = glowColor ~= "" and glowColor or nil,
                glowThick = tonumber(glowThick),
                glowScale = tonumber(glowScale),
                glowN = tonumber(glowN),
                glowImage = glowImage or nil,
                groups = groups ~= "" and groups or nil,
                comment = comment ~= "" and comment or nil,
                msgSize = tonumber(msgSize),
                RGAPIList = RGAPIList ~= "" and RGAPIList or nil,
                RGAPICondition = RGAPICondition ~= "" and RGAPICondition or nil,
                RGAPIAlias = RGAPIAlias ~= "" and RGAPIAlias or nil,
                glowFrameColor = glowFrameColor ~= "" and glowFrameColor or nil,
                WAmsg = WAmsg ~= "" and WAmsg or nil,
                barColor = barColor ~= "" and barColor or nil,
                barTicks = barTicks ~= "" and barTicks or nil,
                barIcon = barIcon ~= "" and barIcon or nil,
            }
            checks = tonumber(checks or 0) or 0

            for j=1,#checksTable do
                local key = checksTable[j]
                new[key] = bit.band(checks,bit.lshift(1,j-1)) > 0 or nil
            end

            classes = tonumber(classes or 0) or 0

            for j=1,#MRT.GDB.ClassList do
                if bit.band(classes,bit.lshift(1,j-1)) > 0 then
                    new.classes = (new.classes or "#") .. MRT.GDB.ClassList[j] .. "#"
                end
            end

            roles = tonumber(roles or 0) or 0

            for j=1,#module.datas.rolesList do
                if bit.band(roles,bit.lshift(1,j-1)) > 0 then
                    new.roles = (new.roles or "#") .. module.datas.rolesList[j][3] .. "#"
                end
            end


            if isImport then
                new.notSync = true
            else
                new.lastSender = sender
            end
			new.lastSync = importTime or time()

            if triggersNum and tonumber(triggersNum) and tonumber(triggersNum) > 0 then
                for j=1,tonumber(triggersNum) do
                    local triggerStr = select(j,strsplit(DELIMITER_1,triggersData))
                    local tnew = {event = 1}
                    triggers[j] = tnew

                    local c = 1
                    local keysList

                    local arg = strsplit(DELIMITER_2,triggerStr)
                    while arg do
                        if c == 3 and tnew.event == 1 then
                            arg = cleu_events[arg] or arg
                            tnew[ keysList[1] ] = arg
                            keysList = module.C[arg or 0] and (module.C[arg].triggerSynqFields or module.C[arg].triggerFields)
                        elseif c > 2 then
                            if keysList then
                                local key = keysList[c-2]
                                if key then
                                    if checkType[key] then
                                        tnew[key] = arg=="1" and true or nil
                                    elseif numberType[key] then
                                        tnew[key] = arg~="" and tonumber(arg) or nil
                                    elseif mixedType[key] then
                                        tnew[key] = arg~="" and (tonumber(arg) or arg) or nil
                                    else
                                        tnew[key] = arg~="" and arg or nil
                                    end
                                end
                            end
                        elseif c == 1 then
                            tnew.event = tonumber(arg)
                            keysList = module.C[tnew.event or 0] and (module.C[tnew.event].triggerSynqFields or module.C[tnew.event].triggerFields)
                        elseif c == 2 then
                            tnew.andor = arg~="" and tonumber(arg) or nil
                        end
                        c = c + 1
                        arg = select(c,strsplit(DELIMITER_2,triggerStr))
                    end
                end
            end
            if SenderDB then
                SenderDB.totalReminders = SenderDB.totalReminders + 1

                if not VMRT.Reminder.data[token] then
                    SenderDB.totalNew = SenderDB.totalNew + 1
                else
                    if VMRT.Reminder.locked[token] then
                        SenderDB.totalLocked = SenderDB.totalLocked + 1
                    elseif CompareReminders(VMRT.Reminder.data[token],new) then
                        SenderDB.totalUpdated = SenderDB.totalUpdated + 1
                    end
                end
            end

            if VMRT.Reminder.data[token] and VMRT.Reminder.lockedSounds[token] then
                new.sound = VMRT.Reminder.data[token].sound
                new.soundOnHide = VMRT.Reminder.data[token].soundOnHide
                new.tts = VMRT.Reminder.data[token].tts
            end

            if liveSession and not VMRT.Reminder.locked[token] then
                if not VMRT.Reminder.liveChanges.added[token] and not VMRT.Reminder.liveChanges.changed[token] then
                    if not VMRT.Reminder.data[token] then
                        VMRT.Reminder.liveChanges.added[token] = true
                    else
                        VMRT.Reminder.liveChanges.changed[token] = VMRT.Reminder.data[token]
                    end
                end
            end

            if not VMRT.Reminder.data[token] or not VMRT.Reminder.locked[token] then
                VMRT.Reminder.data[token] = new
            end
            VMRT.Reminder.removed[token] = nil
		end
    end

    if SenderDB then
        if SenderDB.printTimer then
            SenderDB.printTimer:Cancel()
        end
        SenderDB.printTimer = C_Timer.NewTimer(4,function()
            prettyPrint("|cff80ff00Got reminders:",SenderDB.totalReminders)
            if SenderDB.totalUpdated > 0 then
                prettyPrint("|cff00ffffUpdated reminders:",SenderDB.totalUpdated)
            end
            if SenderDB.totalNew > 0 then
                prettyPrint("|cff0080ffNew reminders:",SenderDB.totalNew)
            end
            if SenderDB.totalLocked > 0 then
                prettyPrint("|cffee5555Reminders that can't be updated due to lock:",SenderDB.totalLocked)
            end
            if SenderDB.totalDeleted > 0 then
                prettyPrint("|cffee5555Deleted reminders:",SenderDB.totalDeleted)
            end
            SenderDB.totalReminders = nil
            SenderDB.totalUpdated = nil
            SenderDB.totalNew = nil
            SenderDB.totalLocked = nil
            SenderDB.totalDeleted = nil
        end)
    end

    if module.options.lastUpdate then
        module.options.lastUpdate:Update()
    end
    if module.options.Update then
        module.options.Update()
    end
    module:ReloadAll()
end

function module:SendVersion()
    local isEnabled = VMRT.Reminder.enabled and "Enabled" or "Disabled"
    -- space is separator
    -- ADDON_VERSION, REMINDER_ENABLED, ACTIVE_BOSS_MOD, ADDON_VERSION_HASH, RELEASE_TYPE, MRT_VERSION, BIGWIGS_VERSION, WEAKAURAS_VERSION, RCLC_VERSION
		MRT.F.SendExMsg("ADV", "V\t" .. strjoin(" ",
		DATA_VERSION,
		isEnabled,
		module.ActiveBossMod,
		AddonDB.VersionHash,
		module.PUBLIC and "1" or "0",
		MRT.V,
		BigWigsLoader and BigWigsLoader:GetVersionString() or DBM and DBM.DisplayVersion:gsub(" ", "") or "?",
		WeakAuras and WeakAuras.versionString or "?",
		RCLootCouncil and RCLootCouncil.version:gsub(" ", "") or "?"
	))
end

function module:RequestVersion()
    MRT.F.SendExMsg("ADV", "GV")
end

local throttleTimer
local function CheckSenderPermission(sender)
    local sender_short = Ambiguate(sender,"none")
    if UnitIsUnit('player',MRT.F.delUnitNameServer(sender)) then
        if VMRT.Reminder.debugUpdates then
            return true
        else
            return false
        end
    elseif VMRT.Reminder.disableUpdates then
        prettyPrint("|cffff0000" .. sender .. " trying to send Reminders. All updates are disabled|r")
        return
    elseif not UnitInRaid(sender_short) and not UnitInParty(sender_short) then -- sender not in current raid/party
        return false
    elseif AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
        return true
    elseif IsInRaid() and not MRT.F.IsPlayerRLorOfficer(sender)then
        if not throttleTimer or throttleTimer < GetTime() - 2 then
            prettyPrint("|cffff0000" .. sender .. " trying to send Reminders. Sender is not RL or Assistant|r")
        end
        throttleTimer = GetTime()
        return false
    end
    return true
end

module.db.synqText = {}
module.db.synqIndex = {}
module.db.RsynqText = {}
module.db.RsynqIndex = {}
function module:addonMessage(sender, prefix, prefix2, token, ...)
	if prefix == "reminder" then
		if prefix2 == "D" or prefix2 == "L" then
            if prefix2 == "D" and not CheckSenderPermission(sender) then return end

            if prefix2 == "L" and not (module.db.isLiveSession or module.db.preLiveSession) then
				return
			end

            if VMRT.Reminder.disableUpdates then
                if not throttleTimer or throttleTimer < GetTime() - 2 then
                    prettyPrint("|cffff0000" .. sender .. " trying to send Reminders. All updates are disabled|r")
                end
                throttleTimer = GetTime()
                return
            end

            module.Sender.LastUpdateSender[sender] = module.Sender.LastUpdateSender[sender] or {}
            module.Sender.LastUpdateSender[sender].time = GetTime()


			local currMsg = table.concat({...}, "\t")
			if tostring(token) == tostring(module.db.synqIndex[sender]) and type(module.db.synqText[sender])=='string' then
				module.db.synqText[sender] = module.db.synqText[sender] .. currMsg
			else
				module.db.synqText[sender] = currMsg
			end
			module.db.synqIndex[sender] = token


			if type(module.db.synqText[sender])=='string' and module.db.synqText[sender]:find("##F##$") then
				local str = module.db.synqText[sender]:sub(1,-6)
				local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
				local decompressed = LibDeflate:DecompressDeflate(decoded)

				module.db.synqText[sender] = nil
                module.db.synqIndex[sender] = nil

				if not decompressed then
                    prettyPrint("|cffff0000Error decompressing reminder data from " .. sender .. "|r")
                    return
                end
                -- MRT.F:Export(decompressed:gsub(DELIMITER_1,"\\19"):gsub(DELIMITER_2,"\\20"))
                if prefix2 == "L" then
                    if not module.db.isLiveSession and module.db.preLiveSession  then
                        module.db.preLiveSession[#module.db.preLiveSession+1] = {decompressed,nil,sender,true}
                    elseif module.db.isLiveSession then
                        VMRT.Reminder.LastUpdateName = MRT.F.delUnitNameServer(sender)
                        VMRT.Reminder.LastUpdateTime = time()

                        module:ProcessTextToData(decompressed,nil,sender,true)
                    end
                else
                    module.popup:Popup(sender,function()
                        VMRT.Reminder.LastUpdateName = MRT.F.delUnitNameServer(sender)
                        VMRT.Reminder.LastUpdateTime = time()

                        module:ProcessTextToData(decompressed,nil,sender)
                    end, "ActionSend")
                end
			end
        elseif prefix2 == "C" then
			if token == "LIVE_SESSION" then
				if VMRT.Reminder.disableUpdates then
					return
				end
				if sender == MRT.SDB.charKey or sender == MRT.SDB.charName then
					return
				end
				if not CheckSenderPermission(sender) then
					return
				end
				if module.db.isLiveSession then
					return
				end
				local bossID, zoneID = ...
				module.db.preLiveSession = {}
				module.popup:Popup(sender,function()
					module:StartLiveUser(bossID, zoneID)
				end,nil,true)
			elseif token == "LIVE_SESSION_STOP" then
				if VMRT.Reminder.disableUpdates then
					return
				end
				if sender == MRT.SDB.charKey or sender == MRT.SDB.charName then
					return
				end
				if not CheckSenderPermission(sender) then
					return
				end
				module:StopLiveUser()
			end
		elseif prefix2 == "RA" then
            if not CheckSenderPermission(sender) then return end

			local currMsg = table.concat({...}, "\t")
			if tostring(token) == tostring(module.db.RsynqIndex[sender]) and type(module.db.RsynqText[sender])=='string' then
				module.db.RsynqText[sender] = module.db.RsynqText[sender] .. currMsg
			else
				module.db.RsynqText[sender] = currMsg
			end
			module.db.RsynqIndex[sender] = token
			if type(module.db.RsynqText[sender])=='string' and module.db.RsynqText[sender]:find("##F##$") then
                local str = module.db.RsynqText[sender]:sub(1,-6)
				local tokens = {strsplit("^",str)}

                module.db.RsynqText[sender] = nil
			    module.db.RsynqIndex[sender] = nil

                local anyData = false
                for i=1,#tokens do
                    local token = tonumber(tokens[i])
                    if token then
                        local data = not VMRT.Reminder.locked[token] and VMRT.Reminder.data[token]
                        if data then
                            anyData = true
                            break
                        end
                    end
                end

                if not anyData then return end
                module.popup:Popup(sender,function()
                    for i=1,#tokens do
                        local token = tonumber(tokens[i])
                        if token then
                            local data = not VMRT.Reminder.locked[token] and VMRT.Reminder.data[token]
                            if data then
                                module:DeleteReminder(data,true,true)
                            end
                        end
                    end
                    if module.options.Update then
                        module.options.Update()
                    end
                    module:ReloadAll()
                end, "ActionDelete")
			end
		elseif prefix2 == "R" then
            if not CheckSenderPermission(sender) then return end

			token = tonumber(token)
			if VMRT.Reminder.data[token] and not VMRT.Reminder.locked[token] then
                module.popup:Popup(sender,function()
                    local data = VMRT.Reminder.data[token]
                    module:DeleteReminder(data,nil,true)
                end, "ActionDelete")
			end
		elseif prefix2 == "GRV" then
			token = tonumber(token)
			local data = VMRT.Reminder.data[token]
			if data then
				if data.lastSync then
					MRT.F.SendExMsg("reminder", "RV\t"..token.."\t"..data.lastSync)
				else
					MRT.F.SendExMsg("reminder", "RV\t"..token.."\t".."NOLS")
				end
			else
				MRT.F.SendExMsg("reminder", "RV\t"..token.."\t".."NODATA")
			end
		elseif prefix2 == "RV" then
			local response = ...
			token = tonumber(token)
			module.db.responcesData[ sender ] = module.db.responcesData[ sender ] or {}
			module.db.responcesData[ sender ][token] = module.db.responcesData[ sender ][token] or {}
			module.db.responcesData[ sender ][token].date = tonumber(response) or response or "unk"
        elseif prefix2 == "S" then
			if token == "E" and module.IsEnabled then
				local prefix3,ZoneID,EncounterID,pullOffset,phase,phaseOffset = ...
				if prefix3 == "P" then -- pull
					local zoneID = tostring(select(8,GetInstanceInfo()))
					if module.db.requestEncounterID and ( GetTime() - module.db.requestEncounterID < 5 ) and zoneID == ZoneID and not module.db.encounterID then -- delayed pull
						module.db.requestEncounterID = nil

                        module.db.nextPullIsDelayed = tonumber(pullOffset or "?")
                        module.db.currentDelayedPhase = phase
                        module.db.currentDelayedPhaseTime = tonumber(phaseOffset or "?")

						prettyPrint("Starting delayed pull Encounter ID:",EncounterID,"Difficulty ID",select(3,GetInstanceInfo()),"Pull time:",module.db.nextPullIsDelayed,"Phase",module.db.currentDelayedPhase,"Phase time",module.db.currentDelayedPhaseTime)
						module.main:ENCOUNTER_START(tonumber(EncounterID), nil, select(3,GetInstanceInfo()), select(9,GetInstanceInfo()))
					end
				elseif prefix3 == "R" then -- request
					local zoneID = tostring(select(8,GetInstanceInfo()))
					if module.db.encounterID and zoneID == ZoneID then
                        local currentPhase = module.db.currentPhase
                        EncounterID = module.db.encounterID
                        pullOffset = GetTime() - (module.db.encounterPullTime or 0)
                        phaseOffset = GetTime() - (module.db.currentPhaseTime or 0)
						MRT.F.SendExMsg("reminder", MRT.F.CreateAddonMsg("S","E","P",ZoneID,EncounterID,pullOffset,currentPhase,phaseOffset))
					end
				end
			end
		end
	elseif prefix == "ADV" then
		if prefix2 == "GV" then
			module:SendVersion()
        elseif prefix2 == "V" then
			if not sender or not token then
				return
			end
			module.db.gettedVersions[sender] = token
            if module.UpdateVersionCheck then
                module:UpdateVersionCheck()
            end
            local version, status, bm, hash, release_type = strsplit(" ", token)
            module:CheckForOutdatedVersion(version, release_type, hash)
		end
	end
end

do
	local queue = {}

	local frame = CreateFrame("Frame",nil,UIParent,BackdropTemplateMixin and "BackdropTemplate")
	module.popup = frame

	function frame:NextQueue()
		frame:Hide()
		tremove(queue, 1)
        tremove(queue, 1)
		C_Timer.After(0.2,function()
			frame:PopupNext()
		end)
	end

	frame:Hide()
	frame:SetBackdrop({bgFile="Interface\\Addons\\MRT\\media\\White"})
	frame:SetBackdropColor(0.05,0.05,0.07,0.98)
	frame:SetSize(250,65)
	frame:SetPoint("RIGHT",UIParent,"CENTER",-200,0)
	frame:SetFrameStrata("DIALOG")
	frame:SetClampedToScreen(true)

	frame.border = MRT.lib:Shadow(frame,20)

	frame.label = frame:CreateFontString(nil,"OVERLAY","GameFontWhiteSmall")
	frame.label:SetFont(frame.label:GetFont(),10,"")
	frame.label:SetPoint("TOP",0,-4)
	frame.label:SetTextColor(1,1,1,1)
	frame.label:SetText("|cffff8000Reminder RG|r")

	frame.player = frame:CreateFontString(nil,"OVERLAY","GameFontWhiteSmall")
	frame.player:SetFont(frame.player:GetFont(),10,"")
	frame.player:SetPoint("TOP",0,-16)
	frame.player:SetTextColor(1,1,1,1)
	frame.player:SetText("MyName-MyRealm")

	local function OnUpdate_HoverCheck(self)
		if not frame:IsShown() then
			self:SetScript("OnUpdate",nil)
			self.subButton:Hide()
			return
		end
		local extraSpace = 10
		local x,y = GetCursorPosition()
		local rect1x,rect1y,rect1w,rect1h = self:GetScaledRect()
		local rect2x,rect2y,rect2w,rect2h = self.subButton:GetScaledRect()
		if not (x >= rect1x-extraSpace and x <= rect1x+rect1w+extraSpace and y >= rect1y-extraSpace and y <= rect1y+rect1h+extraSpace) and
			not (x >= rect2x-extraSpace and x <= rect2x+rect2w+extraSpace and y >= rect2y-extraSpace and y <= rect2y+rect2h+extraSpace) then
			self:SetScript("OnUpdate",nil)
			self.subButton:Hide()
		end
	end

	frame.b1 = MLib:Button(frame,DECLINE):Point("BOTTOMLEFT",5,5):Size(100,20):OnClick(function()
		frame:NextQueue()
	end):OnEnter(function(self)
        if frame.ignoreAlwaysButtons then return end
		frame.b1always:Show()
		self:SetScript("OnUpdate",OnUpdate_HoverCheck)
	end)

	frame.b3 = MLib:Button(frame,ACCEPT):Point("BOTTOMRIGHT",-5,5):Size(100,20):OnClick(function()
		queue[2]()
		frame:NextQueue()
	end):OnEnter(function(self)
        if frame.ignoreAlwaysButtons then return end
		frame.b3always:Show()
		self:SetScript("OnUpdate",OnUpdate_HoverCheck)
	end)

	frame.b1always = MLib:Button(frame,ALWAYS.." "..DECLINE):Point("TOPLEFT",frame.b1,"BOTTOMLEFT",0,-10):Size(140,20):OnClick(function()
		StaticPopupDialogs["VMRT_REMINDER_SYNC_PLAYER"] = {
            text = "Do you want to always |cffff0000decline|r reminders from |cffff0000"..frame.playerRaw.."|r?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                VMRT.Reminder.SyncPlayers[frame.playerRaw] = -1
                frame:NextQueue()
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            preferredIndex = 3,
        }
        StaticPopup_Show("VMRT_REMINDER_SYNC_PLAYER")
	end):Shown(false)
	frame.b3always = MLib:Button(frame,ALWAYS.." "..ACCEPT):Point("TOPRIGHT",frame.b3,"BOTTOMRIGHT",0,-10):Size(140,20):OnClick(function()
		StaticPopupDialogs["VMRT_REMINDER_SYNC_PLAYER"] = {
            text = "Do you want to always |cff00ff00accept|r reminders from |cff00ff00"..frame.playerRaw.."|r?",
            button1 = YES,
            button2 = NO,
            OnAccept = function()
                VMRT.Reminder.SyncPlayers[frame.playerRaw] = 1
                if type(queue[2]) == 'function' then
                    queue[2]()
                end
                frame:NextQueue()
            end,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            preferredIndex = 3,
        }
        StaticPopup_Show("VMRT_REMINDER_SYNC_PLAYER")
	end):Shown(false)

	frame.b1.subButton = frame.b1always
	frame.b3.subButton = frame.b3always

	for _,btn in next, {frame.b1,frame.b1always,frame.b3,frame.b3always} do
		btn.icon = btn:CreateTexture(nil,"ARTWORK")
		btn.icon:SetPoint("RIGHT",btn:GetTextObj(),"LEFT")
		btn.icon:SetSize(18,18)
		btn.icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		btn.icon:SetTexCoord(0.125+(0.1875 - 0.125)*6,0.1875+(0.1875 - 0.125)*6,0.5,0.625)
		btn.icon:SetVertexColor(1,0,0,1)
	end

	frame.b3.icon:SetTexCoord(0.125+(0.1875 - 0.125)*7,0.1875+(0.1875 - 0.125)*7,0.5,0.625)
	frame.b3.icon:SetVertexColor(0,1,0,1)
	frame.b3always.icon:SetTexCoord(0.125+(0.1875 - 0.125)*7,0.1875+(0.1875 - 0.125)*7,0.5,0.625)
	frame.b3always.icon:SetVertexColor(0,1,0,1)

	function frame:PopupNext()
		if VMRT and VMRT.Reminder and VMRT.Reminder.disablePopups then
			return
		end
		local player = queue[1] and queue[1].player
        local action = queue[1] and queue[1].action
		if not player then
			return
		end
        local diffText
		frame.ignoreAlwaysButtons = nil
		if (player == MRT.SDB.charKey or player == MRT.SDB.charName) then -- test
			queue[2]()
			frame:NextQueue()
			return
        elseif queue[1] and queue[1] and queue[1].livesession then
			diffText = format(LR["%s is starting |A:unitframeicon-chromietime:20:20|a live session"],strsplit("-",player))
			frame.ignoreAlwaysButtons = true
		elseif VMRT.Reminder.SyncPlayers[player] == -1 then
            prettyPrint(format("|cffff0000%s trying to send reminders(always ignored)",player))
			frame:NextQueue()
			return
		elseif VMRT.Reminder.SyncPlayers[player] == 1 or (AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(player)) then
			queue[2]()
			frame:NextQueue()
			return
		end
		frame.playerRaw = player
        if diffText then
			frame.player:SetText(diffText)
		else
		    frame.player:SetText(player .. " - " .. LR[action])
        end
		frame:Show()
	end

	function frame:Popup(player,func,action,livesession)
		queue[#queue+1] = {player = player, action = action, livesession = livesession}
		queue[#queue+1] = func

		frame:PopupNext()
	end

	--C_Timer.After(2,function() frame:Popup("Myself",function()end) end)
end

local highestAnnounce = 0
local announce_tmr
local addon_name = C_AddOns.GetAddOnMetadata(GlobalAddonName, "Title")
function module:CheckForOutdatedVersion(version, release_type, hash)
    if InCombatLockdown() then
        C_Timer.After(10,function()
            module:CheckForOutdatedVersion(version, release_type, hash)
        end)
        return
    end

    if hash == "DEV" or (release_type == "1") ~= AddonDB.PUBLIC then
        return
    end
    version = tonumber(version)

    if not version or version <= DATA_VERSION then
        return
    end

    if highestAnnounce >= version then
        return
    end
    highestAnnounce = version
    if announce_tmr then return end
    announce_tmr = C_Timer.NewTimer(3,function()
        announce_tmr = nil
        StaticPopupDialogs["MRT_REMINDER_OUTDATED_VERSION"] = {
            text = format(LR.OutdatedVersionAnnounce, addon_name, highestAnnounce, DATA_VERSION),
            button1 = OKAY,
            showAlert = true,
            timeout = 0,
            whileDead = 1,
            hideOnEscape = 1,
            preferredIndex = 3,
        }
        StaticPopup_Show("MRT_REMINDER_OUTDATED_VERSION")
    end)
end
