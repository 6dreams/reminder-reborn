--[[
project-revision 			1049
project-hash 				75551959092c8ca74a9fa86eb6c390dbed762a1a
project-abbreviated-hash 	7555195
project-author 				m33shoq
project-date-iso 			2025-07-31T21:38:01Z
project-date-integer 		20250731213801
project-timestamp 			1753997881
project-version 			v63
]]

local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)

local MRT = GMRT
---@class Locale

---@class ELib
local ELib = MRT.lib

local LibDeflateAsync = LibStub("LibDeflateAsync-reminder")
local LibSerializeAsync = LibStub("LibSerializeAsync-reminder")

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
---@param localizedName string?
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
		AddonDB:FireCallback("EXRT_REMINDER_POST_ADDON_LOADED")
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUi = ...
		if isInitialLogin or isReloadingUi then
			AddonDB:ParseEncounterJournal()
			AddonDB:FireCallback("EXRT_REMINDER_PLAYER_ENTERING_WORLD")
		end
	end
end)
MRTdev:RegisterEvent("ADDON_LOADED")
MRTdev:RegisterEvent("PLAYER_ENTERING_WORLD")

-----------------------------------------------------------
-- Callbacks
-----------------------------------------------------------

do
	local callbacks = {}

	function AddonDB:RegisterCallback(name, func)
		if type(func) ~= "function" then
			error(GlobalAddonName..": RegisterCallback: func is not a function", 2)
		end
		if not callbacks[name] then
			callbacks[name] = {}
		end
		tInsertUnique(callbacks[name], func)
	end

	function AddonDB:UnregisterCallback(name, func)
		if not callbacks[name] then
			return
		end
		for i = #callbacks[name], 1, -1 do
			if callbacks[name][i] == func then
				tremove(callbacks[name], i)
				break
			end
		end
	end

	function AddonDB:FireCallback(name, ...)
		if not callbacks[name] then
			return
		end
		for i, func in ipairs(callbacks[name]) do
			if func then
				xpcall(func, geterrorhandler(), ...)
			end
		end
	end
end



-----------------------------------------------------------
-- Utility functions
-----------------------------------------------------------

function AddonDB:ClassColorName(unit, useFullName)
	if unit and UnitExists(unit) then
		local name
		if useFullName then
			name = AddonDB:GetFullName(unit)
		else
			name = UnitName(unit)
		end
		local class = UnitClassBase(unit)
		if not class then
		  	return name
		else
			local classData = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
			local coloredName = ("|c%s%s|r"):format(classData.colorStr, name)
			return coloredName
		end
	else
		return "" -- ¯\_(ツ)_/¯
	end
end

function AddonDB:GetUnitGroup(unit)
	local raidIndex = UnitInRaid(unit)
	if raidIndex then
		local name, rank, subgroup = GetRaidRosterInfo(raidIndex)
		return subgroup
	end
   	return 1
end

function AddonDB:IterateGroupMembers(maxGroup, reversed, forceParty)
	local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
	local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
	local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)

	local f
	f = function()
		local ret
		if i == 0 and unit == 'party' then
			ret = 'player'
		elseif i <= numGroupMembers and i > 0 then
			ret = unit .. i
		end
		i = i + (reversed and -1 or 1)

		if ret and maxGroup and AddonDB:GetUnitGroup(ret) > maxGroup then
			return f()
		end

		return ret
	end
	return f
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

if C_TooltipInfo and C_TooltipInfo.GetHyperlink then
	function AddonDB:NpcNameFromGUID(GUID)
		local tooltipInfo = C_TooltipInfo.GetHyperlink("unit:"..GUID)
		local name = tooltipInfo and tooltipInfo.lines and tooltipInfo.lines[1] and tooltipInfo.lines[1].leftText
		if name and name ~= "" then
			return name
		end
	end
else
	local cache_tooltip = CreateFrame("GameTooltip", "ExRT_Reminder_CacheTooltip", _G.UIParent, "GameTooltipTemplate")
	cache_tooltip:SetOwner(_G.WorldFrame, "ANCHOR_NONE")
	function AddonDB:NpcNameFromGUID(GUID)
		cache_tooltip:ClearLines()
		cache_tooltip:SetHyperlink("unit:"..GUID)
		local text = _G["ExRT_Reminder_CacheTooltipTextLeft1"]:GetText()
		if text and text ~= "" then
			return text
		end
	end
end

do
	local sortF = function(GUID1, GUID2)
		local _, spawnTime1, spawnIndex1 = AddonDB:CreatureInfo(GUID1)
		local _, spawnTime2, spawnIndex2 = AddonDB:CreatureInfo(GUID2)

		return (spawnTime1 * 1000 + spawnIndex1) < (spawnTime2 * 1000 + spawnIndex2)
	end

	function AddonDB:SortBySpawnIndex(arr)
		sort(arr, sortF)
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

---@param unit string
---@return string fullName # name-realm, the same format as used in combat log and addon comms
function AddonDB:GetFullName(unit, unitIsName)
	local name, realm = UnitFullName(unit)
	if not name then
		name, realm = UnitFullName(Ambiguate(unit, "none"))
	end
	if not realm or realm == "" then
		realm = AddonDB.MY_REALM
	end
	if not name then
		return unitIsName and unit or nil
	end
	return name .. "-" .. realm
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

AddonDB.VersionHash = "7555195"
if AddonDB.VersionHash:find("@") then
	AddonDB.VersionHash = "DEV"
	AddonDB.IsDev = true
end

AddonDB.PUBLIC = C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-Release") == "Public"
AddonDB.Version = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "Version") or "0")
AddonDB.VersionString = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ") |cff0080ffDiscord for feedback and bug reports: mishoq|r"
AddonDB.VersionStringShort = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ")"
-- This one is used for the version check in public releases
AddonDB.VersionMajor = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-VersionMajor") or "0")

AddonDB.externalLinks = {
	{
		name = "Discord",
		tooltip = "Download updates, provide feedback,\nreport bugs and request features",
		url = "https://discord.gg/dmqVFvU4qv",
	},
}

AddonDB.MY_REALM = GetRealmName():gsub("[%s%-]","")

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
	local COMMS_VERSION = 2 -- skip version 9 as horizontal tab is a separator
	local COMMS_VERSION_BYTE = strchar(COMMS_VERSION)
	local MAX_BYTES = 255
	local COMMS_POSTFIX = "##F##"
	local COMMS_POSTFIX_LEN = #COMMS_POSTFIX
	local COMMS_HEADER = "##H##"

	--[[
	header is string with values separated by AddonDB.COMMS_HEADER_DELIMITER where arguments are encoded for delimiter safety
	encoded data is string encoded for addonComms
	comms string should be either:
	 - header
	 - encoded/normal string
	 - header .. ##H## .. encoded/normal string
	do not include encoded data in header as it will inflate the string with delimiter encoding
	if prefix has OnHeader registered then full comm fill fire without header part

	-- Sending table
	local encoded = AddonDB:CompressTable(table)
	AddonDB:SendComm("prefix1", encoded)

	AddonDB:RegisterComm("prefix1", function(prefix, sender, data, channel, key)
		local table = AddonDB:DecompressTable(data)
	end)


	-- Sending string with header
	local encoded = AddonDB:CompressString(str)
	local header = AddonDB:CreateHeader(val1, val2, val3)
	local commsString = AddonDB:CreateHeaderCommsMessage(header, encoded)
	AddonDB:SendComm("prefix2", commsString)

	AddonDB:RegisterComm("prefix2", function(prefix, sender, data, channel, key)
		local header, encoded = AddonDB:SplitHeaderAndMain(data)
		local val1, val2, val3 = AddonDB:ParseHeader(header) -- returns strings
		local str = AddonDB:DecompressString(encoded)
	end)


	-- Sending string with header and OnHeader registered
	local encoded = AddonDB:CompressString(str)
	local header = AddonDB:CreateHeader(val1, val2, val3)
	local commsString = AddonDB:CreateHeaderCommsMessage(header, encoded)
	AddonDB:SendComm("prefix3", commsString)

	-- OnPart always fires before OnHeader
	AddonDB:RegisterCommOnPart("prefix3", function(prefix, sender, data, channel, key, partNum)
		-- do something with partNum or key, for example track progress
		importData[key] = importData[key] or {} -- key is sender.."\t"..token.."\t"..prefix
		importData[key].i = max(importData[key].i or 0, partNum) -- in case comms are received out of order track the highest partNum
	end)

	-- OnHeader fires only once when full header is received
	AddonDB:RegisterCommOnHeader("prefix3", function(prefix, sender, header, channel, key)
		local val1, val2, val3 = AddonDB:ParseHeader(header) -- returns strings
		-- do something with val1, val2, val3
	end)

	AddonDB:RegisterComm("prefix3", function(prefix, sender, data, channel, key)
		-- header is automatically excluded because we have OnHeader registered
		local str = AddonDB:DecompressString(encoded)
	end)


	-- It is possible to send comms without header or data
	AddonDB:SendComm("prefix4")
	AddonDB:RegisterComm("prefix4", function(prefix, sender, data, channel, key)
		-- data is ""
	end)
	]]

	local COMMS_HEADER_DELIMITER = "\172"
	AddonDB.COMMS_HEADER_DELIMITER = COMMS_HEADER_DELIMITER
	-- local DELIMITER_2 = "\162"

	local STRING_CONVERT = {
		list = {
			["\017"] = "\018",
			[COMMS_HEADER_DELIMITER] = "\019",
			["\000"] = "\001", -- escape \000, typically shouldn't be part of the header args but encode just in case
		},
		listRev = {},
	}
	do
		local senc,sdec = "",""

		for k,v in pairs(STRING_CONVERT.list) do
			STRING_CONVERT.listRev[v] = k
			senc = senc .. (k == "\000" and "%z" or k) -- \000 can't be part of a pattern, so use %z
			sdec = sdec .. v
		end

		STRING_CONVERT.encodePatt = "["..senc.."]"
		STRING_CONVERT.encodeFunc = function(a)
			return "\17"..STRING_CONVERT.list[a]
		end

		STRING_CONVERT.decodePatt = "\17(["..sdec.."])"
		STRING_CONVERT.decodeFunc = function(a)
			return STRING_CONVERT.listRev[a]
		end
	end



	---Accepts array or vararg of strings, encodes them to safely join with `AddonDB.COMMS_HEADER_DELIMITER` and returns the result
	---@param ... table|string|number
	---@return string
	function AddonDB:CreateHeader(...)
		local args = type(...) == "table" and ... or {...}
		for i=1,#args do
			if not args[i] then
				args[i] = ""
			elseif type(args[i]) ~= "string" then
				args[i] = tostring(args[i])
			end
			args[i] = args[i]:gsub(STRING_CONVERT.encodePatt, STRING_CONVERT.encodeFunc)
		end

		return table_concat(args, COMMS_HEADER_DELIMITER)
	end

	---Accepts string created with `AddonDB:CreateHeader`, decodes it and returns values
	---@param header string
	---@return string
	function AddonDB:ParseHeader(header)
		if header then
			local args = {strsplit(COMMS_HEADER_DELIMITER, header)}
			for i=1,#args do
				args[i] = args[i]:gsub(STRING_CONVERT.decodePatt, STRING_CONVERT.decodeFunc)
			end
			return unpack(args)
		end
	end

	---Accepts two strings, joins them with (`##H##`) and returns the result
	---@param header string
	---@param data string
	---@return string commsMessage
	function AddonDB:CreateHeaderCommsMessage(header, data)
		return header .. COMMS_HEADER .. data
	end

	---Accepts string created with `AddonDB:CreateHeaderCommsMessage`, splits it into header and data
	---@param data string
	---@return string
	function AddonDB:SplitHeaderAndMain(data)
		return data:match("(.+)"..COMMS_HEADER.."(.+)")
	end

	local send = MRT.F.SendExMsgExt

	local callbacks = {}
	callbacks.prefixes = {}
	callbacks.prefixes_on_part = {}
	callbacks.prefixes_on_header = {}

	---@alias commsHandler fun(prefix: string, sender: string, data: string, channel: string, key: string)
	---@alias commsHandlerOnHeader fun(prefix: string, sender: string, data: string, channel: string, key: string)
	---@alias commsHandlerOnPart fun(prefix: string, sender: string, data: string, channel: string, key: string, partNum: number)

	---@param prefix string
	---@param handler commsHandler
	function AddonDB:RegisterComm(prefix, handler)
		callbacks.prefixes[prefix] = callbacks.prefixes[prefix] or {}
		tInsertUnique(callbacks.prefixes[prefix], handler)
	end

	---@param prefix string
	---@param handler commsHandlerOnPart
	function AddonDB:RegisterCommOnPart(prefix, handler)
		callbacks.prefixes_on_part[prefix] = callbacks.prefixes_on_part[prefix] or {}
		tInsertUnique(callbacks.prefixes_on_part[prefix], handler)
	end

	---@param prefix string
	---@param handler commsHandlerOnHeader
	function AddonDB:RegisterCommOnHeader(prefix, handler)
		callbacks.prefixes_on_header[prefix] = callbacks.prefixes_on_header[prefix] or {}
		tInsertUnique(callbacks.prefixes_on_header[prefix], handler)
	end


	local function Fire(prefix, ...)
		for index, f in ipairs(callbacks.prefixes[prefix]) do
			xpcall(f, geterrorhandler(), prefix, ...)
		end
	end

	local function FireOnPart(prefix, ...)
		for index, f in ipairs(callbacks.prefixes_on_part[prefix]) do
			xpcall(f, geterrorhandler(), prefix, ...)
		end
	end

	local function FireOnHeader(prefix, ...)
		for index, f in ipairs(callbacks.prefixes_on_header[prefix]) do
			xpcall(f, geterrorhandler(), prefix, ...)
		end
	end

	-- function AddonDB:UnregisterComm(prefix, handler)
	-- 	if callbacks.prefixes[prefix] then
	-- 		for index, f in ipairs(callbacks.prefixes[prefix]) do
	-- 			if f == handler then
	-- 				tremove(callbacks.prefixes[prefix], index)
	-- 				break
	-- 			end
	-- 		end
	-- 	end
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

	-- function AddonDB:UnregisterCommOnHeader(prefix, handler)
	--     if callbacks.prefixes_on_header[prefix] then
	--         for index, f in ipairs(callbacks.prefixes_on_header[prefix]) do
	--             if f == handler then
	--                 tremove(callbacks.prefixes_on_header[prefix], index)
	--                 break
	--             end
	--         end
	--     end
	-- end



	-- returns true if:<br>
	-- - comms is table<br>
	-- - all elements are strings<br>
	-- - last element is string ending with "##F##"
	local function IsCommsReady(comms)
		if type(comms[#comms]) ~= "string" or
			comms[#comms]:sub(-COMMS_POSTFIX_LEN) ~= COMMS_POSTFIX -- postfix will be in separate part if it won't fit into the last part
		then
			return false
		end

		-- iterating backwards for performance, last element is already checked so skip it
		for i = #comms-1, 1, -1 do
			if type(comms[i]) ~= "string" then
				return false
			end
		end

		return true
	end

	local function IsCommsHeaderReady(comms)
		if comms.isHeaderFired then
			return false
		end

		local header = ""
		for i = 1, #comms do
			if type(comms[i]) ~= "string" then
				return false
			else
				header = header .. comms[i]
				local fullHeader = header:match("(.+)"..COMMS_HEADER)
				if fullHeader then
					comms.isHeaderFired = true
					return fullHeader
				end
			end
		end

		return false
	end

	local comms = {}
	local compost = setmetatable({}, {__mode = "k"})
	local function new()
		local t = next(compost)
		if t then
			compost[t]=nil
			for i=#t,1,-1 do -- faster than pairs loop
				t[i]=nil
			end
			t.isHeaderFired = nil
			return t
		end

		return {}
	end

	local allowedPrefixes = type(MRT.msg_prefix) == "table" and CopyTable(MRT.msg_prefix) or {
		["EXRTADD"] = true,
		MRTADDA = true,	MRTADDB = true,	MRTADDC = true,
		MRTADDD = true,	MRTADDE = true,	MRTADDF = true,
		MRTADDG = true,	MRTADDH = true,	MRTADDI = true,
	}
	for i=1,10 do -- these prefixes will be used in case we have to move from MRTComms
		allowedPrefixes["RG_REM"..i] = true
	end
	local commsFrame = CreateFrame("Frame")
	commsFrame:SetScript("OnEvent", function(self, event, addon_prefix, message, channel, sender)
		if addon_prefix and allowedPrefixes[addon_prefix] then
			local comms_version_byte, prefix, msg = strsplit("\t", message, 3)
			if comms_version_byte ~= COMMS_VERSION_BYTE or not prefix or not msg then
				return
			end

			local token = msg:sub(1,3)
			local partNumHex = msg:sub(4,6)
			local partNum = tonumber(partNumHex, 16)
			local data = msg:sub(7)
			local key = sender.."\t"..token.."\t"..prefix
			if not partNum then
				comms[key] = nil
				return
			end
			comms[key] = comms[key] or new()
			local comm_data = comms[key]
			comm_data[partNum] = data

			if callbacks.prefixes_on_part[prefix]  then
				FireOnPart(prefix, sender, data, channel, key, partNum)
			end

			if callbacks.prefixes_on_header[prefix] then
				local header = IsCommsHeaderReady(comm_data)
				if header then
					FireOnHeader(prefix, sender, header, channel, key)
				end
			end

			if callbacks.prefixes[prefix] and IsCommsReady(comm_data) then
				comm_data[#comm_data] = comm_data[#comm_data]:sub(1,-(COMMS_POSTFIX_LEN+1)) -- removing postfix here will save some memory
				local str = table_concat(comm_data)
				-- if we have a OnHeader registered we don't need to include header in the full comms
				if callbacks.prefixes_on_header[prefix] then
					str = str:match("##H##(.+)") or str
				end
				compost[comm_data] = true
				comms[key] = nil
				Fire(prefix, sender, str, channel, key)
			end
		end
	end)
	commsFrame:RegisterEvent("CHAT_MSG_ADDON")

	---@param prefix string
	---@param data string?
	---@param tochat string?
	---@param touser string?
	---@param callbackFunction fun(arg: any, i: number, parts: number)?
	---@param callbackArg any?
	---@param options table?
	---@return number parts
	function AddonDB:SendComm(prefix,data,tochat,touser,callbackFunction,callbackArg,options)
		local token = strchar(random(33,255),random(33,255),random(33,255)) -- 222^3 = 10,941,048 possible combinations

		if type(data) == "number" then
			data = tostring(data)
		end

		local str = data or ""

		local PARTS_COUNT, PART_SIZE = AddonDB:CalculateCommsParts(prefix, str)
		assert(PARTS_COUNT <= 4095, GlobalAddonName..": Comms message is too long(over 1,044,225 bytes)")

		local chat_type, playerName
		if not tochat then
			chat_type, playerName = MRT.F.chatType()
		end
		if chat_type == "WHISPER" and playerName == MRT.SDB.charName then
			for i=1,PARTS_COUNT do
				local partNumHex = format("%03x",i)
				local msg = COMMS_VERSION_BYTE .. "\t" .. prefix .. "\t".. token .. partNumHex .. str:sub((i-1)*PART_SIZE+1,i*PART_SIZE) .. (i == PARTS_COUNT and COMMS_POSTFIX or "")
				if callbackFunction then xpcall(callbackFunction, geterrorhandler(), callbackArg, i, PARTS_COUNT) end
				commsFrame:GetScript("OnEvent")(commsFrame, "CHAT_MSG_ADDON", next(allowedPrefixes), msg, chat_type, MRT.SDB.charKey)
			end
			return PARTS_COUNT
		end

		for i=1,PARTS_COUNT do
			local opt = options or {}
			if callbackFunction then
				opt.ondone = function() xpcall(callbackFunction, geterrorhandler(), callbackArg, i, PARTS_COUNT) end
			end

			local partNumHex = format("%03x",i)

			local msg = token .. partNumHex .. str:sub((i-1)*PART_SIZE+1, i*PART_SIZE) .. (i == PARTS_COUNT and COMMS_POSTFIX or "")
			-- MRT.F.SendExMsg will concatenate 2nd and 3rd args with \t
			send(opt, COMMS_VERSION_BYTE .. "\t" .. prefix, msg, tochat, touser)
		end
		return PARTS_COUNT
	end

	function AddonDB:CalculateCommsParts(prefix, str)
		local len = #str
		-- COMMS_VERSION_BYTE + \t + prefix + \t + token + part index(3bytes in hex)
		local META_OFFSET = 1 + 1 + #prefix + 1 + 3 + 3

		local PART_SIZE = MAX_BYTES - META_OFFSET
		local PARTS_COUNT = ceil(len / PART_SIZE)

		-- calculate length of the last part and check if postfix will fit into it, increase parts if needed
		local lastPartSize = (len - (PARTS_COUNT - 1) * PART_SIZE) + META_OFFSET
		if MAX_BYTES - lastPartSize < COMMS_POSTFIX_LEN then
			PARTS_COUNT = PARTS_COUNT + 1
		end
		return PARTS_COUNT, PART_SIZE
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
	format(path, "anti_kit.png"),
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

-----------------------------------------------------------
-- Encoding and Decoding wrappers
-----------------------------------------------------------

local configForLS = {
	errorOnUnserializableType = false
}
---@param table table
---@param forPrint boolean
---@param level number?
---@return string
function AddonDB:CompressTable(table, forPrint, level)
	if not table then
		return nil
	end

	local serialized = LibSerializeAsync:SerializeEx(configForLS, table)
	local compressed = C_EncodingUtil and C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.Default) or LibDeflateAsync:CompressDeflate(serialized, { level = level or 9 })
	local encoded
	if (forPrint) then
		encoded = LibDeflateAsync:EncodeForPrint(compressed)
	else
		encoded = LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
	end
	return encoded
end

---@param encoded string
---@param forPrint boolean?
---@return table|string
function AddonDB:DecompressTable(encoded, forPrint)
	local decoded
	if (forPrint) then
		decoded = LibDeflateAsync:DecodeForPrint(encoded)
	else
		decoded = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
	end

	if not decoded then
		return nil, "Error decoding"
	end

	local decompressed
	if C_EncodingUtil then
		local success, res = pcall(C_EncodingUtil.DecompressString, decoded, Enum.CompressionMethod.Deflate)
		if not success then
			return nil, res
		else
			decompressed = res
		end
	else
		decompressed = LibDeflateAsync:DecompressDeflate(decoded)
	end

	if not decompressed then
		return nil, "Error decompressing"
	end

	local success, deserialized = LibSerializeAsync:Deserialize(decompressed)
	if not success then
		return nil, "Error deserializing"
	end
	return deserialized
end

function AddonDB:CompressString(str, forPrint)
	if not str then
		return nil
	end

	local compressed = C_EncodingUtil and C_EncodingUtil.CompressString(str) or LibDeflateAsync:CompressDeflate(str, { level = 9 })
	local encoded
	if (forPrint) then
		encoded = LibDeflateAsync:EncodeForPrint(compressed)
	else
		encoded = LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
	end
	return encoded
end

function AddonDB:DecompressString(encoded, forPrint)
	local decoded
	if (forPrint) then
		decoded = LibDeflateAsync:DecodeForPrint(encoded)
	else
		decoded = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
	end

	if not decoded then
		return nil, "Error decoding."
	end

	local decompressed
	if C_EncodingUtil then
		local success, res = pcall(C_EncodingUtil.DecompressString, decoded)
		if not success then
			return nil, res
		else
			decompressed = res
		end
	else
		decompressed = LibDeflateAsync:DecompressDeflate(decoded)
	end

	if not decompressed then
		return nil, "Error decompressing"
	end

	return decompressed
end

-----------------------------------------------------------
-- Import and Export windows
-----------------------------------------------------------

do
	local importFrame, exportFrame
	local function createImportFrame()
		local function ImportOnUpdate(self, elapsed)
			self.tmr = self.tmr + elapsed
			if self.tmr >= 0.1 then
				self.tmr = 0
				self:SetScript("OnUpdate",nil)
				local str = table.concat(self.buff):trim()
				self.parent:Hide()

				self.buff = {}
				self.buffPos = 0

				if self.parent.ImportFunc then
					self.parent.ImportFunc(str)
				end
				self.parent:Hide()
			end
		end

		local importWindow = ELib:Popup(AddonDB.LR["Import"]):Size(650,100)
		importWindow.Edit = ELib:MultiEdit(importWindow):Point("TOP",0,-20):Size(640,75)
		importWindow:SetScript("OnHide",function(self)
			self.Edit:SetText("")
		end)
		importWindow:SetScript("OnShow",function(self)
			self.Edit.EditBox.buffPos = 0
			self.Edit.EditBox.tmr = 0
			self.Edit.EditBox.buff = {}
			self.Edit.EditBox:SetFocus()
		end)
		importWindow.Edit.EditBox:SetMaxBytes(1)
		importWindow.Edit.EditBox:SetScript("OnChar", function(self, c)
			self.buffPos = self.buffPos + 1
			self.buff[self.buffPos] = c
			self:SetScript("OnUpdate",ImportOnUpdate)
		end)
		importWindow.Edit.EditBox.parent = importWindow
		importWindow:SetFrameStrata("FULLSCREEN_DIALOG")

		return importWindow
	end

	function AddonDB:QuickPaste(title, onPasteFunc)
		assert(type(onPasteFunc) == "function", GlobalAddonName ..": onPasteFunc must be a function, got ".. type(onPasteFunc))
		if not importFrame then
			importFrame = createImportFrame()
		end
		importFrame:Hide() -- trigger OnHide script in case it was shown before

		importFrame.title:SetText(title or AddonDB.LR["Import"])
		importFrame.ImportFunc = onPasteFunc
		importFrame:Show()
	end

	local function createExportFrame()
		local exportWindow = ELib:Popup(AddonDB.LR["Export"]):Size(650,50)
		exportWindow.Edit = ELib:Edit(exportWindow):Point("TOP",0,-20):Size(640,25)
		exportWindow:SetScript("OnHide",function(self)
			self.Edit:SetText("")
		end)
		exportWindow.Edit:SetScript("OnEditFocusGained", function(self)
			self:HighlightText()
		end)
		exportWindow.Edit:SetScript("OnMouseUp", function(self, button)
			self:HighlightText()
			if button == "RightButton" then
				self:GetParent():Hide()
			end
		end)
		exportWindow.Edit:SetScript("OnKeyUp", function(self, c)
			if (c == "c" or c == "C") and IsControlKeyDown() then
				self:GetParent():Hide()
			end
		end)
		exportWindow.Edit:OnChange(function(self, isUser)
			if isUser and self.fixedText then
				self:SetText(self.fixedText)
				self:HighlightText()
			end
		end)
		exportWindow.Edit:SetScript("OnEscapePressed", function(self)
			self:GetParent():Hide()
		end)
		function exportWindow:OnShow()
			self.Edit:SetFocus()
		end
		exportWindow:SetFrameStrata("FULLSCREEN_DIALOG")

		return exportWindow
	end

	function AddonDB:QuickCopy(text, title)
		if type(text) == "number" then
			text = tostring(text)
		end
		assert(type(text) == "string", GlobalAddonName ..": text must be a string, got ".. type(text))
		if not exportFrame then
			exportFrame = createExportFrame()
		end
		exportFrame:Hide() -- trigger OnHide script in case it was shown before

		exportFrame.title:SetText(title or AddonDB.LR["Export"])

		exportFrame.Edit:SetText(text)
		exportFrame.Edit.fixedText = text
		exportFrame:Show()
	end
end

-----------------------------------------------------------
-- Useful string matching patterns
-----------------------------------------------------------

AddonDB.STRING_PATTERNS = {}
AddonDB.STRING_PATTERNS.SEP = " ,\n\r:%{%}%(%)%+%[%]\"%@%!%$%_%#%&"
AddonDB.STRING_PATTERNS.PAT_SEP = "[" .. AddonDB.STRING_PATTERNS.SEP .. "]"
AddonDB.STRING_PATTERNS.PAT_SEP_INVERSE = "[^" .. AddonDB.STRING_PATTERNS.SEP .. "]+"
AddonDB.STRING_PATTERNS.PAT_SEP_CAPTURE = "(" .. AddonDB.STRING_PATTERNS.PAT_SEP .. ")"

-----------------------------------------------------------
-- Mark flags metatable
-----------------------------------------------------------

local COMBATLOG_OBJECT_RAIDTARGET_MASK = COMBATLOG_OBJECT_RAIDTARGET_MASK or 255
local markToIndex = {
	[0] = 0,
	[0x1] = 1,
	[0x2] = 2,
	[0x4] = 3,
	[0x8] = 4,
	[0x10] = 5,
	[0x20] = 6,
	[0x40] = 7,
	[0x80] = 8,
}

AddonDB.markToIndex = setmetatable({}, {
	__index = function(_, key)
		if type(key) == "number" then
			return markToIndex[ bit_band(key, COMBATLOG_OBJECT_RAIDTARGET_MASK or 255) ]
		else
			return nil
		end
	end,
})


-----------------------------------------------------------
-- Ordered pairs
-----------------------------------------------------------

do
	local function __genOrderedIndex(t)
		local orderedIndex = {}
		for key in next, t do
			if key ~= "__orderedIndex" then
				table.insert(orderedIndex, key)
			end
		end
		table.sort(orderedIndex, function(a, b)
			local typeA, typeB = type(a), type(b)
			if typeA ~= typeB then
				return typeA < typeB
			else
				return a < b
			end
		end)
		return orderedIndex
	end

	local function orderedNext(t, state)
		-- Equivalent of the next function, but returns the keys in the alphabetic
		-- order. We use a temporary ordered key table that is stored in the
		-- table being iterated.
		local key = nil
		if state == nil then
			-- the first time, generate the index
			t.__orderedIndex = __genOrderedIndex(t)
			key = t.__orderedIndex[1]
		else
			-- fetch the next value
			for i = 1, table.getn(t.__orderedIndex) do
				if t.__orderedIndex[i] == state then
					key = t.__orderedIndex[i + 1]
				end
			end
		end

		if key then
			return key, t[key]
		end

		-- no more value to return, cleanup
		t.__orderedIndex = nil
	end

	function AddonDB.orderedPairs(t)
		return orderedNext, t, nil
	end
end

-----------------------------------------------------------
-- Async Handler
-----------------------------------------------------------
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
