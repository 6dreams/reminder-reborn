local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)

local MRT = GMRT
---@class Locale

---@class ELib
local ELib = MRT.lib

-----------------------------------------------------------
-- Upvalues
-----------------------------------------------------------
local _G = _G
local C_AddOns = C_AddOns
local CreateFrame = CreateFrame
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local IsInRaid = IsInRaid
local tonumber = tonumber
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local Ambiguate = Ambiguate
local UnitIsUnit = UnitIsUnit
local IsInGroup = IsInGroup
local ceil = ceil
local random = random
local strchar = string.char
local tostring = tostring
local tremove = tremove
local tinsert = tinsert
local tInsertUnique = tInsertUnique
local format = format
local strsplit = strsplit
local xpcall = xpcall
local next = next
local table_concat = table.concat
local UnitExists, UnitGUID, GetServerTime, bit_band, strsub, bit_rshift = UnitExists, UnitGUID, GetServerTime, bit.band, strsub, bit.rshift


local function noop() end
RGLOG = noop
rglog = noop
RGlog = noop
rgLog = noop
if not ddt then ddt = noop end
if not DDT then DDT = noop end
if not ddtD then ddtD = noop end
if not DDTD then DDTD = noop end

-----------------------------------------------------------
-- Compability
-----------------------------------------------------------

AddonDB.GetSpellInfo = C_Spell and C_Spell.GetSpellInfo and function(spellID)
	if not spellID then
		return nil
	end
	local spellInfo = C_Spell.GetSpellInfo(spellID)
	if spellInfo then
        return spellInfo.name, nil, spellInfo.iconID, spellInfo.castTime, spellInfo.minRange, spellInfo.maxRange, spellInfo.spellID, spellInfo.originalIconID
	end
end or GetSpellInfo
AddonDB.GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
AddonDB.GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
AddonDB.GetSpellCooldown = C_Spell and C_Spell.GetSpellCooldown and function(spellID)
	if not spellID then
		return nil
	end
	local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
	if cooldownInfo then
		return cooldownInfo.startTime, cooldownInfo.duration, cooldownInfo.isEnabled, cooldownInfo.modRate
	end
end or GetSpellCooldown

if MRT.isCata then
	AddonDB.GetSpecialization = GetPrimaryTalentTree or function()
		local n, m = 1, 1
		for spec = 1, 3 do
			local selectedNum = 0
			for talPos = 1, 22 do
				local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(spec,
					talPos)
				if name and maxRank > 0 and rank > 0 then
					selectedNum = selectedNum + 1
				end
			end
			if selectedNum > m then
				n = spec
				m = selectedNum
			end
		end
		return n
	end
	AddonDB.GetSpecializationInfo = function(specNum)
		local specID = GetTalentTabInfo(specNum)
		if not specID then
			return
		end
		local role = MRT.GDB.ClassSpecializationRole[specID]
		if role == "MELEE" or role == "RANGE" then
			role = "DAMAGER"
		elseif role == "HEAL" then
			role = "HEALER"
		end
		if specID == 750 and not IsPlayerSpell(57880) then -- Cataclysm Feral Druids, if you don't have 2 points in 'Natural Reaction' we assume you're a cat
			role = "DAMAGER"
		else
			role = "TANK"
		end
		local _, name = GetSpecializationInfoForSpecID(specID)
		return 0, name, 0, 0, role
	end
elseif MRT.isClassic then
	AddonDB.GetSpecialization = MRT.NULLfunc
	AddonDB.GetSpecializationInfo = MRT.NULLfunc
else
	AddonDB.GetSpecialization = GetSpecialization
	AddonDB.GetSpecializationInfo = GetSpecializationInfo
end

-----------------------------------------------------------
-- MRT modules wrapper
-----------------------------------------------------------

local AddonModules = {}
---@param moduleName string
---@param localizedName string
---@param disableOptions boolean?
---@return MRTmodule|false
function AddonDB:New(moduleName, localizedName, disableOptions)
	local module = MRT:New(moduleName, localizedName, disableOptions)
	if module then
		AddonModules[module] = true
	end
	return module
end

if MRT.A.WAChecker then
	AddonModules[MRT.A.WAChecker] = true -- workaround for ADDON_LOADED in WASync
end

local MRTdev = CreateFrame("Frame")
MRTdev:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= GlobalAddonName then
			return
		end

		for module in next, AddonModules do
			if not module.IsLoaded then
				module.main:ADDON_LOADED()
				module.IsLoaded = true

				--for old versions
				if MRT.ModulesLoaded then
					for i = #MRT.Modules, 1, -1 do
						if MRT.Modules[i] == module then
							MRT.ModulesLoaded[i] = true
							break
						end
					end
				end
			end
		end
		self:UnregisterEvent("ADDON_LOADED")

		ReminderArchive = ReminderArchive or {}
		WASyncArchiveDB = WASyncArchiveDB or {}

		AddonDB.CleanArchive(30) -- clean history and WAArchive data older than 30 days
		MRT.F:FireCallback("EXRT_REMINDER_POST_ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUi = ...
		if isInitialLogin or isReloadingUi then
			AddonDB:ParseEncounterJournal()
		end
	end
end)
MRTdev:RegisterEvent("ADDON_LOADED")
MRTdev:RegisterEvent("PLAYER_ENTERING_WORLD")

-----------------------------------------------------------
-- Utility functions
-----------------------------------------------------------

AddonDB.IterateGroupMembers = function(reversed, forceParty)
	local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
	local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
	local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
	return function()
		local ret
		if i == 0 and unit == 'party' then
			ret = 'player'
		elseif i <= numGroupMembers and i > 0 then
			ret = unit .. i
		end
		i = i + (reversed and -1 or 1)
		return ret
	end
end

function AddonDB:CreatureInfo(GUID)
	if UnitExists(GUID) then -- If a unit ID was passed instead of GUID, convert it
		GUID = UnitGUID(GUID)
	end

	local unitType, _, _, _, _, npcID, spawnUID = strsplit("-", GUID)

	if unitType == "Creature" or unitType == "Vehicle" then
		local spawnEpoch = GetServerTime() - (GetServerTime() % 2 ^ 23)
		local spawnEpochOffset = bit_band(tonumber(strsub(spawnUID, 5), 16), 0x7fffff)
		local spawnIndex = bit_rshift(bit_band(tonumber(strsub(spawnUID, 1, 5), 16), 0xffff8), 3)
		local spawnTime = spawnEpoch + spawnEpochOffset

		if spawnTime > GetServerTime() then
			-- This only occurs if the epoch has rolled over since a unit has spawned.
			spawnTime = spawnTime - ((2 ^ 23) - 1)
		end

		return tonumber(npcID), spawnTime, spawnIndex
	end
end

function AddonDB:CheckSelfPermissions(isDebugMode)
	if isDebugMode then
		return true, nil
	elseif not IsInGroup() and not IsInRaid() then
		return false, ERR_NOT_IN_GROUP
	elseif AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender("player") then
		return true, nil
	elseif IsInRaid() and not MRT.F.IsPlayerRLorOfficer("player") then
		return false, AddonDB.LR["You are not Raid Leader or Raid Assistant"]
	else
		return true, nil
	end
end

---@return boolean isPass
---@return string? reason
function AddonDB:CheckSenderPermissions(sender, isDebugMode, ignoreSelfCheck)
    local sender_short = Ambiguate(sender, "none")
    if not ignoreSelfCheck and UnitIsUnit('player', sender_short) then -- self sending
		return isDebugMode, nil -- ignore error msg here
	elseif not UnitInRaid(sender_short) and not UnitInParty(sender_short) then -- sender not in current raid/party
		return false, nil -- ignore error msg here
	elseif AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender) then
		return true, nil
	elseif IsInRaid() and not MRT.F.IsPlayerRLorOfficer(sender) then
		return false, AddonDB.LR["Not Raid Leader or Raid Assistant"]
	else
		return true, nil
	end
end

-----------------------------------------------------------
-- Rename and switch modules order
-----------------------------------------------------------

function AddonDB:RenameModule(module, newName)
	if not module or not newName then
		return
	end

	local localizedName = module.options.name
	module.options.name = newName

	for i, lName in next, MRT.Options.Frame.modulesList.L do
		if lName == localizedName then
			MRT.Options.Frame.modulesList.L[i] = newName
		end
	end
end

function AddonDB:SwitchModulesOrder(module1, module2)
	if not module1 or not module2 then
		return
	end
	-- Minimap icon order
	local index1 = nil
	local index2 = nil

	for i, opts in next, MRT.ModulesOptions do
		if opts == module1.options then
			index1 = i
		elseif opts == module2.options then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.ModulesOptions[index1], MRT.ModulesOptions[index2] = MRT.ModulesOptions[index2], MRT.ModulesOptions[index1]
	end

	-- Change order of frames in Options
	index1 = nil
	index2 = nil
	for i, opts in next, MRT.Options.Frame.Frames do
		if opts == module1.options then
			index1 = i
		elseif opts == module2.options then
			index2 = i
		end
	end

	if index1 and index2 then
        MRT.Options.Frame.Frames[index1], MRT.Options.Frame.Frames[index2] = MRT.Options.Frame.Frames[index2], MRT.Options.Frame.Frames[index1]
	end

	-- Change order of frames in Options.modulesList.L
	index1 = nil
	index2 = nil
	for i, localizedName in next, MRT.Options.Frame.modulesList.L do
		if localizedName == module1.options.name then
			index1 = i
		elseif localizedName == module2.options.name then
			index2 = i
		end
	end

	if index1 and index2 then
        MRT.Options.Frame.modulesList.L[index1], MRT.Options.Frame.modulesList.L[index2] = MRT.Options.Frame.modulesList.L[index2], MRT.Options.Frame.modulesList.L[index1]
	end

	-- Change order of modules in MRT.Modules and MRT.ModulesLoaded
	index1 = nil
	index2 = nil
	for i, module in next, MRT.Modules do
		if module == module1 then
			index1 = i
		elseif module == module2 then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.Modules[index1], MRT.Modules[index2] = MRT.Modules[index2], MRT.Modules[index1]
		MRT.ModulesLoaded[index1], MRT.ModulesLoaded[index2] = MRT.ModulesLoaded[index2], MRT.ModulesLoaded[index1]
	end
end

-----------------------------------------------------------
-- Global proxy
-----------------------------------------------------------

local privateFields = {
	RGAPI = true,
	Archivist = true,
	WASYNC = true,
}

_G.GREMINDER = setmetatable({}, {__index = function(t, k)
		if privateFields[k] then
			return nil
		end
		return AddonDB[k]
end, __newindex = function() end, __metatable = false })

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

AddonDB.defaultFont = GameFontNormal:GetFont()

AddonDB.VersionHash = "f01a5e8"
if AddonDB.VersionHash:find("@") then
	AddonDB.VersionHash = "DEV"
end

AddonDB.PUBLIC = C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-Release") == "Public"
AddonDB.Version = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "Version") or "0")
AddonDB.VersionString = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ") |cff0080ffDiscord for feedback and bug reports: mishoq|r"
AddonDB.VersionStringShort = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ")"

AddonDB.externalLinks = {
	{
		name = "Discord",
		tooltip = "Download updates, provide feedback,\nreport bugs and request features",
		url = "https://discord.gg/dmqVFvU4qv",
	},
}

-----------------------------------------------------------
-- Slash commands
-----------------------------------------------------------

SLASH_ReminderSlash1 = "/rem"
SLASH_ReminderSlash2 = "/reminder"
SLASH_ReminderSlash3 = "/куь" -- /rem but in russian

SlashCmdList["ReminderSlash"] = function(msg)
	MRT.Options:Open()
	MRT.Options:OpenByModuleName("Reminder")
end

SLASH_WASYNC1 = "/was"
SLASH_WASYNC2 = "/wasync"
SLASH_WASYNC3 = "/цфы" -- /was but in russian

SlashCmdList["WASYNC"] = function(msg)
	MRT.Options:Open()
	MRT.Options:OpenByModuleName("WAChecker")
end

-----------------------------------------------------------
-- Comms sending
-----------------------------------------------------------
do
	local callbacks = {}
	callbacks.prefixes = {}
	-- callbacks.prefixes_on_part = {}

	---@param prefix string
	---@param handler fun(prefix: string, sender: string, data: string, channel: string)
	function AddonDB:RegisterComm(prefix, handler)
		callbacks.prefixes[prefix] = callbacks.prefixes[prefix] or {}
		tInsertUnique(callbacks.prefixes[prefix], handler)
	end

	function AddonDB:UnregisterComm(prefix, handler)
		if callbacks.prefixes[prefix] then
			for index, f in ipairs(callbacks.prefixes[prefix]) do
				if f == handler then
					tremove(callbacks.prefixes[prefix], index)
					break
				end
			end
		end
	end

	local function Fire(prefix, ...)
		if callbacks.prefixes[prefix] then
			for index, f in ipairs(callbacks.prefixes[prefix]) do
				xpcall(f, geterrorhandler(), prefix, ...)
			end
		end
	end

	-- ---@param prefix string
	-- ---@param handler fun(prefix: string, sender: string, token: string, data: string, channel: string)
	-- function AddonDB:RegisterCommOnPart(prefix, handler)
	--     callbacks.prefixes_on_part[prefix] = callbacks.prefixes_on_part[prefix] or {}
	--     tInsertUnique(callbacks.prefixes_on_part[prefix], handler)
	-- end

	-- function AddonDB:UnregisterCommOnPart(prefix, handler)
	--     if callbacks.prefixes_on_part[prefix] then
	--         for index, f in ipairs(callbacks.prefixes_on_part[prefix]) do
	--             if f == handler then
	--                 tremove(callbacks.prefixes_on_part[prefix], index)
	--                 break
	--             end
	--         end
	--     end
	-- end

	-- local function FireOnPart(prefix, ...)
	--     if callbacks.prefixes_on_part[prefix] then
	--         for index, f in ipairs(callbacks.prefixes_on_part[prefix]) do
	--             xpcall(f, geterrorhandler(), prefix, ...)
	--         end
	--     end
	-- end

	local comms = {}
    local compost = setmetatable({}, {__mode = "k"})
	local function new()
		local t = next(compost)
		if t then
			compost[t]=nil
			for i=#t,1,-1 do	-- faster than pairs loop
				t[i]=nil
			end
			return t
		end

		return {}
	end

	local prefixes = MRT.msg_prefix
	local commsFrame = CreateFrame("Frame")
	commsFrame:SetScript("OnEvent", function(self, event, addon_prefix, data, channel, sender)
		if addon_prefix and prefixes[addon_prefix] then
			local prefix, msg = strsplit("\t", data, 2)
            local token = msg:sub(1,4)
			local data = msg:sub(5)
            local key = sender.."\t"..token.."\t"..prefix
			comms[key] = comms[key] or new()
			tinsert(comms[key], data)
			-- FireOnPart(prefix, sender, token, data, channel, #comms[key])
			if data:sub(-5) == "##F##" then
                local str = table_concat(comms[key]):sub(1,-6)
				comms[key] = nil
				Fire(prefix, sender, str, channel)
			end
		end
	end)
	commsFrame:RegisterEvent("CHAT_MSG_ADDON")

	local send = MRT.F.SendExMsgExt
	local MAX_BYTES = 255
    function AddonDB:SendComm(prefix,data,prefix2,tochat,touser,callbackFunction,callbackArg,options)
		-- implement a script to create a random 4 bytes token
        local token = prefix2 or strchar(random(33,255),random(33,255),random(33,255),random(33,255)) -- 222^4 = 2,428,912,656 possible combinations
		token = token and tostring(token) or ""

		local postfix = "##F##"

		if type(data) == "number" then
			data = tostring(data)
		end

		local str = data or ""
		local len = #str
		local META_OFFSET = #prefix + 1 + #token

		local PART_SIZE = MAX_BYTES - META_OFFSET
		local parts = ceil(len / PART_SIZE)


		-- calculate length of the last part and check if postfix will fit into it, increase parts if needed
		local lastPartSize = (len - (parts - 1) * PART_SIZE) + META_OFFSET
		if MAX_BYTES - lastPartSize < #postfix then
			parts = parts + 1
		end

		local chat_type, playerName
		if not tochat then
			chat_type, playerName = MRT.F.chatType()
		end
		if chat_type == "WHISPER" and playerName == MRT.SDB.charName then
            local me = Ambiguate(MRT.SDB.charKey,"none")
            for i=1,parts do
                local msg = token .. str:sub((i-1)*PART_SIZE+1,i*PART_SIZE) .. (i == parts and postfix or "")
				if callbackFunction then xpcall(callbackFunction, geterrorhandler(), callbackArg, i, parts) end
                commsFrame:GetScript("OnEvent")(commsFrame, "CHAT_MSG_ADDON", next(prefixes), prefix .. "\t".. msg, chat_type, me)
			end
			return
		end

        for i=1,parts do
			local opt = options or {}
			if callbackFunction then
				opt.ondone = function() xpcall(callbackFunction, geterrorhandler(), callbackArg, i, parts) end
			end

            local msg = token .. str:sub((i-1)*PART_SIZE+1,i*PART_SIZE) .. (i == parts and postfix or "")
            send(opt,prefix,msg,tochat,touser)
		end
	end
end

-----------------------------------------------------------
-- Private images API
-----------------------------------------------------------

local rg_logo = "Interface\\Addons\\" .. GlobalAddonName .. "\\Media\\Textures\\rg_logo_white.png"
local path = "Interface\\Addons\\" .. GlobalAddonName .. "\\Media\\Private\\Textures\\%s"
local privateImages = {
	format(path, "badito.png"),
	format(path, "badito2.png"),
	format(path, "badito3.png"),
	format(path, "badito4.png"),
	format(path, "badito5.png"),
	format(path, "badito6.png"),
	format(path, "badito7.png"),
	format(path, "badito8.png"),
	format(path, "badito9.png"),
	format(path, "badito11.png"),
	format(path, "badito12.png"),
	format(path, "badito13.png"),
	format(path, "Spiderdito.png"),
	format(path, "Nercho_pes.png"),
	format(path, "Azargul_kot.png"),
	format(path, "Selfless.png"),
	format(path, "Zmei_mario.png"),
	format(path, "zmey2.png"),
	format(path, "zmey3.png"),
	format(path, "darkless.png"),
	format(path, "mishok.png"),
	format(path, "nimb_mishoq.png"),
	format(path, "UAZb.png"),
	format(path, "Jeniss_Korgy.png"),
	format(path, "feyta.png"),
	format(path, "feyta2.png"),
	format(path, "badito14.png"),
	format(path, "kroyfell.png"),
	format(path, "murchal.png"),
	format(path, "pauel.png"),
}
AddonDB.TotalImages = #privateImages

function AddonDB:GetImage(num, depth)
	depth = (depth or 0) + 1

	local allBlacklisted = false
	if depth == 1 and RGDB and RGDB.ImagesBlacklist then
		allBlacklisted = true
		for _, image in ipairs(privateImages) do
			if not RGDB.ImagesBlacklist[image] then
				allBlacklisted = false
				break
			end
		end
	end

	if AddonDB.PUBLIC or allBlacklisted or depth > 500 then
		return rg_logo
	elseif num then
		local image = privateImages[num]
		if not image or RGDB and RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[image] then
			return AddonDB:GetImage(nil, depth)
		end
		return image
	else
		local image = privateImages[random(1, #privateImages)]
		if not image or RGDB and RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[image] then
			return AddonDB:GetImage(nil, depth)
		end
		return image
	end
end

if not AddonDB.PUBLIC then
	local imgFrame
	SLASH_RGIMAGES1 = "/rgimg"
	SlashCmdList["RGIMAGES"] = function(msg)
		if not imgFrame then
            imgFrame = ELib:Popup("RG Images"):Size(220,50)
            imgFrame.DropDown = ELib:DropDown(imgFrame, 200, 10):Size(200):Point("BOTTOM", imgFrame, "BOTTOM", 0, 5):SetText("Settings")
			local function SetValue(self, img)
				RGDB.ImagesBlacklist = RGDB.ImagesBlacklist or {}
				RGDB.ImagesBlacklist[img] = not RGDB.ImagesBlacklist[img] or nil
                imgFrame.DropDown.List[self.id].colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00"
				ELib.ScrollDropDown:Reload()
			end
			local function hoverFunc(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 15, 0)
				GameTooltip:SetText(format("|T%s:200:200|t", self.data.arg1))
				GameTooltip:Show()
			end
			function imgFrame.DropDown:PreUpdate()
				for i, img in ipairs(privateImages) do
					if not self.List[i] then
						self.List[i] = {
							text = i,
							arg1 = img,
							func = SetValue,
                            colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00",
							hoverFunc = hoverFunc,
						}
					else
                        self.List[i].colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00"
					end
				end
			end
		end
		imgFrame:Show()
	end
end


local configForLS = {
	errorOnUnserializableType = false
}
---@param table table
---@param forChat boolean
---@param level number?
---@return string
function AddonDB:CompressTable(table, forChat, level)
	if not table then
		return nil
	end

	local LibDeflateAsync = LibStub("LibDeflateAsync-reminder")
	local LibSerializeAsync = LibStub("LibSerializeAsync-reminder")

	local serialized = LibSerializeAsync:SerializeEx(configForLS, table)
	local compressed = LibDeflateAsync:CompressDeflate(serialized, { level = level or 9 })
	local encoded
	if (forChat) then
		encoded = LibDeflateAsync:EncodeForPrint(compressed)
	else
		encoded = LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
	end
	return encoded
end

---@param encoded string
---@param fromChat boolean?
---@return table|string
function AddonDB:DecompressTable(encoded, fromChat)
	local LibDeflateAsync = LibStub("LibDeflateAsync-reminder")
	local LibSerializeAsync = LibStub("LibSerializeAsync-reminder")

	local decoded
	if (fromChat) then
		decoded = LibDeflateAsync:DecodeForPrint(encoded)
	else
		decoded = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
	end

	if not decoded then
		return "Error decoding."
	end

	local decompressed = LibDeflateAsync:DecompressDeflate(decoded)
	if not decompressed then
		return "Error decompressing"
	end

	local success, deserialized = LibSerializeAsync:Deserialize(decompressed)
	if not success then
		return "Error deserializing"
	end
	return deserialized
end

--[[
-- FIFO multi stream Async Handler
local AsyncFrame = CreateFrame("Frame")
AsyncFrame.streams = {}
AsyncFrame:SetScript("OnUpdate", function(self, elapsed)
    local globalStart = debugprofilestop()
    local hasData = false
    elapsed = elapsed * 1000
    for stream, datas in next, AsyncFrame.streams do
        if datas[1] then
            -- print(stream, datas[1].maxTime, datas[1].maxTimeCombat)
            hasData = true
            local data = datas[1]
            local maxExecutionTime = ((InCombatLockdown() and IsInInstance()) and data.maxTimeCombat or data.maxTime)
            local start = debugprofilestop()
            while (debugprofilestop() - start < max(1, maxExecutionTime - elapsed)) do
                local func = data.func
                if func and coroutine.status(func) ~= "dead" then
                    local ok, msg = coroutine.resume(func)
                    if not ok then
                        data.errorHandler(msg, debugstack(func))
                    end
                else
                    tremove(datas, 1)
                    break
                end

                if InCombatLockdown() and (debugprofilestop() - globalStart > 100) then
                    return
                end
            end
        end
    end
    if not hasData then
        self:Hide()
    end
end)

--- @class AsyncConfig
--- @field stream string?
--- @field maxTime number
--- @field maxTimeCombat number
--- @field errorHandler fun(msg: string, stacktrace?: string)

--- @type AsyncConfig
local defaultConfig = {
    stream = nil,
    maxTime = 40,
    maxTimeCombat = 5,
    errorHandler = geterrorhandler(),
}

--- @param config AsyncConfig
function AddonDB:Async(config, func)
    if not func then return end

    if type(config) ~= "table" then
        config = CopyTable(defaultConfig)
    end

    if config.stream == nil then
        config.stream = AddonDB:GenerateUniqueID()
    end

    if type(config.maxTime) ~= "number" or config.maxTime < 0 then
        config.maxTime = 40
    end

    if type(config.maxTimeCombat) ~= "number" or config.maxTimeCombat < 0 then
        config.maxTimeCombat = 5
    end

    if type(config.errorHandler) ~= "function" then
        config.errorHandler = geterrorhandler()
    end

    if not AsyncFrame.streams[config.stream] then
        AsyncFrame.streams[config.stream] = {}
    end

    local co
    if type(func) == "function" then
        co = coroutine.create(func)
    elseif type(func) == "thread" then
        co = func
    end

    assert(type(co) == "thread", "Invalid coroutine or function passed to Async")

    local data = {
        maxTime = config.maxTime,
        maxTimeCombat = config.maxTimeCombat,
        errorHandler = config.errorHandler,
        func = co,
    }

    tinsert(AsyncFrame.streams[config.stream], data)
    AsyncFrame:Show()
end
]]
