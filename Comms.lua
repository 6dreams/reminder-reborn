local GlobalAddonName = ...

---@class AddonDB
local AddonDB = select(2, ...)

local MRT = GMRT

local assert = assert
local ceil = ceil
local CopyTable = CopyTable
local CreateFrame = CreateFrame
local format = format
local geterrorhandler = geterrorhandler
local ipairs = ipairs
local next = next
local random = random
local setmetatable = setmetatable
local strchar = string.char
local strsplit = strsplit
local table_concat = table.concat
local tInsertUnique = tInsertUnique
local tremove = tremove
local tonumber = tonumber
local tostring = tostring
local type = type
local unpack = unpack
local xpcall = xpcall


local COMMS_VERSION = 2 -- skip version 9 as horizontal tab is a separator
local COMMS_VERSION_BYTE = strchar(COMMS_VERSION)
local MAX_BYTES = 255
local COMMS_POSTFIX = "##F##"
local COMMS_POSTFIX_LEN = #COMMS_POSTFIX
local COMMS_HEADER = "##H##"

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

	for k, v in next, STRING_CONVERT.list do
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

function AddonDB:UnregisterCommOnPart(prefix, handler)
    if callbacks.prefixes_on_part[prefix] then
        for index, f in ipairs(callbacks.prefixes_on_part[prefix]) do
            if f == handler then
                tremove(callbacks.prefixes_on_part[prefix], index)
                break
            end
        end
    end
end

function AddonDB:UnregisterCommOnHeader(prefix, handler)
    if callbacks.prefixes_on_header[prefix] then
        for index, f in ipairs(callbacks.prefixes_on_header[prefix]) do
            if f == handler then
                tremove(callbacks.prefixes_on_header[prefix], index)
                break
            end
        end
    end
end



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
function AddonDB:SendComm(prefix, data, tochat, touser, callbackFunction, callbackArg, options)
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
