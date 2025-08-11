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

local L = WeakAuras.L

-- upvalues
local tinsert = tinsert
local tremove = tremove
local unpack = unpack
local bit_band = bit.band
local bit_rshift = bit.rshift
local bit_lshift = bit.lshift
local string_char = string.char
local next = next
local table_concat = table.concat
local random = random
local WeakAuras = WeakAuras
local CopyTable = CopyTable
local ipairs = ipairs
local coroutine_yield = coroutine.yield
local coroutine_wrap = coroutine.wrap
local type = type
local tonumber = tonumber

local Serializer = LibStub:GetLibrary("AceSerializer-3.0")
local Compresser = LibStub:GetLibrary("LibCompress")
local LibDeflateAsync = LibStub:GetLibrary("LibDeflateAsync-reminder")
local LibSerializeAsync = LibStub:GetLibrary("LibSerializeAsync-reminder")

--------------------------------------------------------------------------------------------------------------------------------
-- A bunch of code from WeakAuras
--------------------------------------------------------------------------------------------------------------------------------
local prettyPrint = module.prettyPrint

local function shouldInclude(data, includeGroups, includeLeafs)
	if data.controlledChildren then
		return includeGroups
	else
		return includeLeafs
	end
end

local function Traverse(data, includeSelf, includeGroups, includeLeafs)
	if includeSelf and shouldInclude(data, includeGroups, includeLeafs) then
		coroutine_yield(data)
	end

	if data.controlledChildren then
		for _, child in ipairs(data.controlledChildren) do
			Traverse(WeakAuras.GetData(child), true, includeGroups, includeLeafs)
		end
	end
end

local function TraverseLeafs(data)
	return Traverse(data, false, false, true)
end

local function TraverseLeafsOrAura(data)
	return Traverse(data, true, false, true)
end

local function TraverseGroups(data)
	return Traverse(data, true, true, false)
end

local function TraverseSubGroups(data)
	return Traverse(data, false, true, false)
end

local function TraverseAllChildren(data)
	return Traverse(data, false, true, true)
end

local function TraverseAll(data)
	return Traverse(data, true, true, true)
end

local function TraverseParents(data)
	while data.parent do
		local parentData = WeakAuras.GetData(data.parent)
		coroutine_yield(parentData)
		data = parentData
	end
end

-- Only non-group auras, not include self
local function pTraverseLeafs(data)
	return coroutine_wrap(TraverseLeafs), data
end

-- The root if it is a non-group, otherwise non-group children
local function pTraverseLeafsOrAura(data)
	return coroutine_wrap(TraverseLeafsOrAura), data
end

-- All groups, includes self
local function pTraverseGroups(data)
	return coroutine_wrap(TraverseGroups), data
end

-- All groups, excludes self
local function pTraverseSubGroups(data)
	return coroutine_wrap(TraverseSubGroups), data
end

-- All Children, excludes self
local function pTraverseAllChildren(data)
	return coroutine_wrap(TraverseAllChildren), data
end

-- All Children and self
local function pTraverseAll(data)
	return coroutine_wrap(TraverseAll), data
end

local function pTraverseParents(data)
	return coroutine_wrap(TraverseParents), data
end
module.pTraverseAllChildren = pTraverseAllChildren
module.pTraverseSubGroups = pTraverseSubGroups
module.pTraverseGroups = pTraverseGroups
module.pTraverseLeafs = pTraverseLeafs
module.pTraverseLeafsOrAura = pTraverseLeafsOrAura
module.pTraverseAll = pTraverseAll
module.pTraverseParents = pTraverseParents


function module.ValidateUniqueDataIds(silent)
	-- ensure that there are no duplicated uids anywhere in the database

	local seenUIDs = {}
	local db = WeakAurasSaved
	for _, data in next, db.displays do
		if type(data.uid) == "string" then
			if seenUIDs[data.uid] then
				if not silent then
					prettyPrint("Duplicate uid \""..data.uid.."\" detected in saved variables between \""..data.id.."\" and \""..seenUIDs[data.uid].id.."\".")
				end
				data.uid = WeakAuras.GenerateUniqueID()
				seenUIDs[data.uid] = data
				else
				seenUIDs[data.uid] = data
			end
		elseif data.uid ~= nil then
			if not silent then
				prettyPrint("Invalid uid detected in saved variables for \""..data.id.."\"")
			end
			data.uid = WeakAuras.GenerateUniqueID()
			seenUIDs[data.uid] = data
		end
	end
end

function module.SyncParentChildRelationships(silent)
	-- 1. Find all auras where data.parent ~= nil or data.controlledChildren ~= nil
	--    If an aura has data.parent which doesn't exist, then remove data.parent
	--    If an aura has data.parent which doesn't have data.controlledChildren, then remove data.parent
	-- 2. For each aura with data.controlledChildren, iterate through the list of children and remove entries where:
	--    The child doesn't exist in the database
	--    The child ID is duplicated in data.controlledChildren (only the first will be kept)
	--    The child's data.parent points to a different parent
	--    The parent is a dynamic group and the child is a group/dynamic group
	--    Otherwise, mark the child as having a valid parent relationship
	-- 3. For each aura with data.parent, remove data.parent if it was not marked to have a valid relationship in 2.

	local db = WeakAurasSaved

	local parents = {}
	local children = {}
	local childHasParent = {}

	for ID, data in next, db.displays do
		local id = data.id or ID
		if data.parent then
			if not db.displays[data.parent] then
				if not(silent) then
					prettyPrint("Detected corruption in saved variables: "..id.." has a nonexistent parent.")
				end
				data.parent = nil
			elseif not db.displays[data.parent].controlledChildren then
				if not silent then
					prettyPrint("Detected corruption in saved variables: "..id.." thinks "..data.parent..
					" controls it, but "..data.parent.." is not a group.")
				end
			data.parent = nil
			else
				children[id] = data
			end
		end
		if data.controlledChildren then
			parents[id] = data
		end
	end

	for id, data in next, parents do
		local groupChildren = {}
		local childrenToRemove = {}
		local dynamicGroup = data.regionType == "dynamicgroup"
		for index, childID in ipairs(data.controlledChildren) do
			local child = children[childID]
			if not child then
				if not silent then
					prettyPrint("Detected corruption in saved variables: "..id.." thinks it controls "..childID.." which doesn't exist.")
				end
				childrenToRemove[index] = true
			elseif child.parent ~= id then
				if not silent then
					prettyPrint("Detected corruption in saved variables: "..id.." thinks it controls "..childID.." which it does not.")
				end
				childrenToRemove[index] = true
			elseif dynamicGroup and child.controlledChildren then
				if not silent then
					prettyPrint("Detected corruption in saved variables: "..id.." is a dynamic group and controls "..childID.." which is a group/dynamicgroup.")
				end
				child.parent = nil
				children[child.id] = nil
				childrenToRemove[index] = true
			elseif groupChildren[childID] then
				if not silent then
					prettyPrint("Detected corruption in saved variables: "..id.." has "..childID.." as a child in multiple positions.")
				end
				childrenToRemove[index] = true
			else
				groupChildren[childID] = index
				childHasParent[childID] = true
			end
		end
		if next(childrenToRemove) ~= nil then
			for i = #data.controlledChildren, 1, -1 do
				if childrenToRemove[i] then
					tremove(data.controlledChildren, i)
				end
			end
		end
	end

	for id, data in next, children do
		if not childHasParent[id] then
			if not silent then
				prettyPrint("Detected corruption in saved variables: "..id.." should be controlled by "..data.parent.." but isn't.")
			end
			local parent = parents[data.parent]
			tinsert(parent.controlledChildren, id)
		end
	end
end


--A ton of code from WeakAuras\Transmission.lua

local function ShowTooltip(lines)
	ItemRefTooltip:Show();
	if not ItemRefTooltip:IsVisible() then
		ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
	end
	ItemRefTooltip:ClearLines();
	for i, line in ipairs(lines) do
		local sides, a1, a2, a3, a4, a5, a6, a7, a8 = unpack(line);
		if(sides == 1) then
			ItemRefTooltip:AddLine(a1, a2, a3, a4, a5);
		elseif(sides == 2) then
			ItemRefTooltip:AddDoubleLine(a1, a2, a3, a4, a5, a6, a7, a8);
		end
	end
	ItemRefTooltip:Show()
end
module.ShowTooltip = ShowTooltip

local versionString = WeakAuras.versionString;
-- fields that are not included in exported data
-- these represent information which is only meaningful inside the db,
-- or are represented in other ways in exported
local non_transmissable_fields = {
	controlledChildren = true,
	-- parent = true, -- trnasmit parent info so non nested groups are stayed where they should be
	authorMode = true,
	skipWagoUpdate = true,
	ignoreWagoUpdate = true,
	preferToUpdate = true,
	information = {
		saved = true
	}
}

-- For nested groups, we do transmit parent + controlledChildren
local non_transmissable_fields_v2000 = {
	authorMode = true,
	skipWagoUpdate = true,
	ignoreWagoUpdate = true,
	preferToUpdate = true,
	information = {
		saved = true
	}
}

local function stripNonTransmissableFields(datum, fieldMap)
	for k, v in next, fieldMap do
		if type(v) == "table" and type(datum[k]) == "table" then
			stripNonTransmissableFields(datum[k], v)
		elseif v == true then
			datum[k] = nil
		end
	end
end

local bytetoB64 = {
	[0]="a","b","c","d","e","f","g","h",
	"i","j","k","l","m","n","o","p",
	"q","r","s","t","u","v","w","x",
	"y","z","A","B","C","D","E","F",
	"G","H","I","J","K","L","M","N",
	"O","P","Q","R","S","T","U","V",
	"W","X","Y","Z","0","1","2","3",
	"4","5","6","7","8","9","(",")"
}

local B64tobyte = {
	a =  0,  b =  1,  c =  2,  d =  3,  e =  4,  f =  5,  g =  6,  h =  7,
	i =  8,  j =  9,  k = 10,  l = 11,  m = 12,  n = 13,  o = 14,  p = 15,
	q = 16,  r = 17,  s = 18,  t = 19,  u = 20,  v = 21,  w = 22,  x = 23,
	y = 24,  z = 25,  A = 26,  B = 27,  C = 28,  D = 29,  E = 30,  F = 31,
	G = 32,  H = 33,  I = 34,  J = 35,  K = 36,  L = 37,  M = 38,  N = 39,
	O = 40,  P = 41,  Q = 42,  R = 43,  S = 44,  T = 45,  U = 46,  V = 47,
	W = 48,  X = 49,  Y = 50,  Z = 51,["0"]=52,["1"]=53,["2"]=54,["3"]=55,
	["4"]=56,["5"]=57,["6"]=58,["7"]=59,["8"]=60,["9"]=61,["("]=62,[")"]=63
}

-- This code is based on the Encode7Bit algorithm from LibCompress
-- Credit goes to Galmok (galmok@gmail.com)
local decodeB64Table = {}

local function decodeB64(str)
	local bit8 = decodeB64Table;
	local decoded_size = 0;
	local ch;
	local i = 1;
	local bitfield_len = 0;
	local bitfield = 0;
	local l = #str;
	while true do
		if bitfield_len >= 8 then
			decoded_size = decoded_size + 1;
			bit8[decoded_size] = string_char(bit_band(bitfield, 255));
			bitfield = bit_rshift(bitfield, 8);
			bitfield_len = bitfield_len - 8;
		end
		ch = B64tobyte[str:sub(i, i)];
		bitfield = bitfield + bit_lshift(ch or 0, bitfield_len);
		bitfield_len = bitfield_len + 6;
		if i > l then
			break;
		end
		i = i + 1;
	end
	return table_concat(bit8, "", 1, decoded_size)
end


local function GenerateUniqueID()
	-- generates a unique random 11 digit number in base64
	local s = {}
	for i=1,11 do
		tinsert(s, bytetoB64[random(0, 63)])
	end
	return table_concat(s)
end
AddonDB.GenerateUniqueID = GenerateUniqueID

local function CompressDisplay(data, version)
	-- Clean up custom trigger fields that are unused
	-- Those can contain lots of unnecessary data.
	-- Also we warn about any custom code, so removing unnecessary
	-- custom code prevents unnecessary warnings
	for triggernum, triggerData in ipairs(data.triggers) do
		local trigger, untrigger = triggerData.trigger, triggerData.untrigger

		if (trigger and trigger.type ~= "custom") then
			trigger.custom = nil;
			trigger.customDuration = nil;
			trigger.customName = nil;
			trigger.customIcon = nil;
			trigger.customTexture = nil;
			trigger.customStacks = nil;
			if (untrigger) then
				untrigger.custom = nil;
			end
		end
	end

	local copiedData = CopyTable(data)
	local non_transmissable_fields = version >= 2000 and non_transmissable_fields_v2000
														or non_transmissable_fields
	stripNonTransmissableFields(copiedData, non_transmissable_fields)
	copiedData.tocversion = WeakAuras.BuildInfo
	return copiedData;
end

local configForLS = {
  errorOnUnserializableType = false
}

local configForDeflate = {level = 9}

local function TableToString(inTable, forChat)
	local serialized = LibSerializeAsync:SerializeEx(configForLS, inTable)

	local compressed = C_EncodingUtil and C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.OptimizeForSize) or LibDeflateAsync:CompressDeflate(serialized, configForDeflate)

	local encoded = "!WA:2!"
	if(forChat) then
		encoded = encoded .. LibDeflateAsync:EncodeForPrint(compressed)
	else
		encoded = encoded .. LibDeflateAsync:EncodeForWoWAddonChannel(compressed)
	end
	return encoded
end

local function StringToTable(inString, fromChat)
	-- encoding format:
	-- version 0: simple b64 string, compressed with LC and serialized with AS
	-- version 1: b64 string prepended with "!", compressed with LD and serialized with AS
	-- version 2+: b64 string prepended with !WA:N! (where N is encode version)
	--   compressed with LD and serialized with LS
	local _, _, encodeVersion, encoded = inString:find("^(!WA:%d+!)(.+)$")
	if encodeVersion then
	  	encodeVersion = tonumber(encodeVersion:match("%d+"))
	else
	  	encoded, encodeVersion = inString:gsub("^%!", "")
	end

	local decoded
	if(fromChat) then
	  	if encodeVersion > 0 then
			decoded = LibDeflateAsync:DecodeForPrint(encoded)
	  	else
			decoded = decodeB64(encoded)
	  	end
	else
	  	decoded = LibDeflateAsync:DecodeForWoWAddonChannel(encoded)
	end

	if not decoded then
	  	return L["Error decoding."]
	end

	local decompressed
	if encodeVersion > 0 then
	  	decompressed = C_EncodingUtil and C_EncodingUtil.DecompressString(decoded) or LibDeflateAsync:DecompressDeflate(decoded)
	  	if not(decompressed) then
			return L["Error decompressing"]
	  	end
	else
	  -- We ignore the error message, since it's more likely not a weakaura.
	  	decompressed = Compresser:Decompress(decoded)
	  	if not(decompressed) then
			return L["Error decompressing. This doesn't look like a WeakAuras import."]
	  	end
	end

	local success, deserialized
	if encodeVersion < 2 then
	  	success, deserialized = Serializer:Deserialize(decompressed)
	else
	  	success, deserialized = LibSerializeAsync:Deserialize(decompressed)
	end
	if not(success) then
	  	return L["Error deserializing"]
	end
	return deserialized
  end

local function DisplayToTransmit(data)
	if not data then return nil end

	data.uid = data.uid or GenerateUniqueID()
	-- Check which transmission version we want to use
	local version = 1421
	for child in pTraverseSubGroups(data) do -- luacheck: ignore
		version = 2000
		break;
	end
	local transmitData = CompressDisplay(data, version);
	local transmit = {
		m = "d",
		d = transmitData,
		v = version,
		s = versionString
	};
	if(data.controlledChildren) then
		transmit.c = {};
		local uids = {}
		local index = 1
		for child in pTraverseAllChildren(data) do
			if child.uid then
				if uids[child.uid] then
					child.uid = GenerateUniqueID()
				else
					uids[child.uid] = true
				end
			else
				child.uid = GenerateUniqueID()
			end
			transmit.c[index] = CompressDisplay(child, version);
			index = index + 1
		end
	end
	return transmit
end

local function DisplayToString(data, forChat)
	local transmit = DisplayToTransmit(data)
	return transmit and TableToString(transmit, forChat) or ""

end
module.TableToString = TableToString
module.StringToTable = StringToTable
module.DisplayToString = DisplayToString
module.CompressDisplay = CompressDisplay
module.DisplayToTransmit = DisplayToTransmit
