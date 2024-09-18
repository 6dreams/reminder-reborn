local GlobalAddonName,ExRT = ...

local module = ExRT.A.WAChecker
local ELib,L = ExRT.lib,ExRT.L
if not module then return end
if not WeakAuras then return end

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LibSerialize = LibStub("LibSerialize")
local Serializer = LibStub:GetLibrary("AceSerializer-3.0")
local Compresser = LibStub:GetLibrary("LibCompress")

local importDelays = {}
local delayC = 0.5
local sendingData = false
local VERSION = 10

local isDebugMode = false

local importData = {}
module.db.importData = importData

local importWAs = {}
module.db.importWAs = importWAs

module.db.getVersion = 0
module.db.gettedVersions = {}

module.db.responcesData = {}

module.db.random = {time = 0, num1 = 1, num2 = 1}

function module:ShareButtonClick(button)
	local id = self:GetParent().db.data.id
	if id then
		if button == "RightButton" then
			module:GetWAVer(id)
		else
			module:ExportWA(id)
		end
	end
end

local QueueImagesStrings = {
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito2.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito3.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito4.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito5.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito6.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito7.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito8.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito9.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito_10.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\badito11.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\Nercho_pes.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\Azargul_kot.png",
	"Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\Selfless.png",
    "Interface\\Addons\\ExRT_Reminder\\Media\\Textures\\Zmei_mario.png",
}

local QueueSenderStrings = {
    "%s приложил свои пальчики к вашему...",
    -- "%s сейчас вставит свою ВАшку в ваш...",
    -- "%s намайнил на вас очередной биткоин",
    -- "%s ОПЯТЬ??????????",
    -- "Я сейчас удалю твой аддон (с) Змей",
    -- "ПЛАЧ ДЕДОВ? СЕКС С МОЛИС?",
    -- "МИШОК Я ТУТ ТАКОЕ ПРИДУМАЛ СЕЙЧАС РАСКАЖУ...",
    -- "СУКА ЕБАНЫЕ АДДОНЫ МИШОК",
    -- "Приготовьтесь, %s отправил обновление!",
    -- "Интересно, что на этот раз сделал %s.",
    -- "Получено обновление от %s. Давайте посмотрим, что там.",
    -- "%s отправил вам обновление интерфейса.",
    -- "%s не может остановиться! Новое обновление!",
    -- "Снова %s с обновлениями. Как вы думаете, что там?",
    -- "А это нормальный аддон? Я всякое говно не ставлю (с) Бадито",
	-- "%s разобрал боссов по полочкам",
	-- "%s получает коучинг в прямом эфире",
	-- "%s - кринжевик без урона но может в механики и выживание",
	-- "%s ваще тут?",
	-- "%s снова сделал что-то непонятное",
	-- "%s хуярит с Марса и не выкупает ничего кроме своих ВАшек",
	-- "%s - клоун с заваленным ебалом",
	-- "В классы чуть не попали, компенсируем ВАшками",
	-- "%s не понимает че происходит",
	-- "%s: тут все +- адекватно",
    -- "Че за нахуй иди нахуй бля "
}
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--[[
A ton of code from WeakAuras\Transmission.lua

]]--

local tostring, string_char, strsplit = tostring, string.char, strsplit
local bit_band, bit_lshift, bit_rshift = bit.band, bit.lshift, bit.rshift


local versionString = WeakAuras.versionString;
-- fields that are not included in exported data
-- these represent information which is only meaningful inside the db,
-- or are represented in other ways in exported
local non_transmissable_fields = {
	controlledChildren = true,
	parent = true,
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
	for k, v in pairs(fieldMap) do
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
    return table.concat(bit8, "", 1, decoded_size)
  end



local function GenerateUniqueID()
	-- generates a unique random 11 digit number in base64
	local s = {}
	for i=1,11 do
		tinsert(s, bytetoB64[math.random(0, 63)])
	end
	return table.concat(s)
end

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

local function shouldInclude(data, includeGroups, includeLeafs)
	if data.controlledChildren then
		return includeGroups
	else
		return includeLeafs
	end
end

local function Traverse(data, includeSelf, includeGroups, includeLeafs)
	if includeSelf and shouldInclude(data, includeGroups, includeLeafs) then
		coroutine.yield(data)
	end

	if data.controlledChildren then
		for _, child in ipairs(data.controlledChildren) do
			Traverse(WeakAuras.GetData(child), true, includeGroups, includeLeafs)
		end
	end
end

local function TraverseAllChildren(data)
	return Traverse(data, false, true, true)
end

local function pTraverseAllChildren(data)
    return coroutine.wrap(TraverseAllChildren), data
end

local function TraverseSubGroups(data)
	return Traverse(data, false, true, false)
end

local function pTraverseSubGroups(data)
	return coroutine.wrap(TraverseSubGroups), data
end

local configForLS = {
  errorOnUnserializableType =  false
}

local compressedTablesCache = {}
local configForDeflate = {level = 9}

local function TableToString(inTable, forChat)
	local serialized = LibSerialize:SerializeEx(configForLS, inTable)

	local compressed
	-- get from / add to cache
	if compressedTablesCache[serialized] then
		compressed = compressedTablesCache[serialized].compressed
		compressedTablesCache[serialized].lastAccess = time()
	else
		compressed = LibDeflate:CompressDeflate(serialized, configForDeflate)
		compressedTablesCache[serialized] = {
		compressed = compressed,
		lastAccess = time(),
		}
	end
	-- remove cache items after 5 minutes
	for k, v in pairs(compressedTablesCache) do
		if v.lastAccess < (time() - 300) then
		compressedTablesCache[k] = nil
		end
	end
	local encoded = "!WA:2!"
	if(forChat) then
		encoded = encoded .. LibDeflate:EncodeForPrint(compressed)
	else
		encoded = encoded .. LibDeflate:EncodeForWoWAddonChannel(compressed)
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
        	decoded = LibDeflate:DecodeForPrint(encoded)
      	else
        	decoded = decodeB64(encoded)
      	end
    else
      	decoded = LibDeflate:DecodeForWoWAddonChannel(encoded)
    end

    if not decoded then
      	return L["Error decoding."]
    end

    local decompressed
    if encodeVersion > 0 then
      	decompressed = LibDeflate:DecompressDeflate(decoded)
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
      	success, deserialized = LibSerialize:Deserialize(decompressed)
    end
    if not(success) then
      	return L["Error deserializing"]
    end
    return deserialized
  end

local function DisplayToString(data, forChat)
  --local data = WeakAuras.GetData(id);
  	if(data) then
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
    	return TableToString(transmit, forChat);
  	else
    	return "";
  	end
end

--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------



-- local prev_addonMessage = module.addonMessage
function module:addonMessage(sender, prefix, data, ...)
	-- prev_addonMessage(self,sender, prefix, data, ...)
	if prefix == "WAS" then
		if (IsInRaid() and not ExRT.F.IsPlayerRLorOfficer(sender)) or (not isDebugMode and UnitIsUnit('player',ExRT.F.delUnitNameServer(sender))) or not WeakAuras then
			return
		end
		local token = data:sub(1,4)
		local str = data:sub(5,-1)
		-- print(data:sub(1,40))

		if str:find("^done") then
			local doneText, id, forceSend, time, num1, num2 = strsplit("^",str)
			str = importData[sender][token]
			-- print("str",type(str))
			local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
			-- print("decoded",type(decoded))
			local decompressed = LibDeflate:DecompressDeflate(decoded)
			-- print("decompressed",type(decompressed))
			str = decompressed
			if str then
				module.checkFrame:AddToQueue(str, sender, id, forceSend=="1", tonumber(time), tonumber(num1), tonumber(num2))
			else
				print("|cff9f3fff[WASync]|r |cffee5555ERROR:|r GOT CORRUPTED DATA")
				ExRT.F.SendExMsg("WAS_IMPORT_ERROR", "ERROR\t" .. sender .. "\t" .. "1ST DEFLATE ERROR" .. "\t" .."GOT CORRUPTED DATA")
			end
			importData[sender][token] = nil
		else
			local str = table.concat({str, ...}, "\t")
			importData[sender] = importData[sender] or {}
			importData[sender][token] = (importData[sender][token] or "")..str
		end
	elseif prefix == "WAS_STATUS" then
		if data == "10" then
			ExRT.F.SendExMsg("WAS_STATUS", "11\t"..VERSION)
		elseif data == "11" then
			local ver = ...
			if not ver or not module.db.gettedVersions then
				return
			end
			module.db.gettedVersions[sender] = ver
		elseif data == "1" then
			local owner,id = ...
			if ExRT.F.delUnitNameServer(owner) ~= UnitName'player' then
				return
			end
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			module.db.responces[ sender ][id] = true

			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage()
			end
		elseif data == "2" then
			local owner,id = ...
			if ExRT.F.delUnitNameServer(owner) ~= UnitName'player' then
				return
			end
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			module.db.responces[ sender ][id] = false

			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage()
			end
		elseif data == "20" then
			if (IsInRaid() and not ExRT.F.IsPlayerRLorOfficer(sender)) or (not isDebugMode and UnitIsUnit('player',ExRT.F.delUnitNameServer(sender))) or not WeakAuras then
				return
			end
			local id = ...
			if id then
				local data = WeakAuras.GetData(id)
				if data then
					ExRT.F.SendExMsg("WAS_STATUS", "21\t"..(data.exrtLastSync or 0).."\t"..id)
				end
			end
		elseif data == "21" then
			local date, id = ...
			if not id or not WeakAuras then
				return
			end

			module.db.responcesData[ sender ] = module.db.responcesData[ sender ] or {}
			module.db.responcesData[ sender ][id] = module.db.responcesData[ sender ][id] or {}
			module.db.responcesData[ sender ][id].date = tonumber(date or "0")

			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			if WeakAuras.GetData(id) then
				module.db.responces[ sender ][id] = module.db.responcesData[ sender ][id].date == WeakAuras.GetData(id).exrtLastSync
			end

			module.ShowHoverIcons = true
			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage()
			end
			C_Timer.After(20,function()
				module.ShowHoverIcons = nil
			end)
		end
	elseif prefix == "WAS_IMPORT_ERROR" then
		if data == "ERROR" then
			local waSender, success, error = ...
			if ExRT.F.delUnitNameServer(waSender) == ExRT.SDB.charName then
                pcall(PlaySoundFile,"Interface\\AddOns\\BugSack\\Media\\error.ogg","Master")
				print("|cff9f3fff[WASync]|r |cffee5555ERROR:|r", sender, "-", success, "-", error)
			end
		end
	end
end

module.IconHoverFunctions = {
	function(self,isEnter)
		if isEnter then
			local id = self:GetParent().db.name
			local pname = self.name
			local Date
			for name,DB in pairs(module.db.responcesData) do
				if name == pname or name:find("^"..pname) then
					if DB[id] then
						Date = DB[id].date
					end
					break
				end
			end
			if Date then
				ELib.Tooltip.Show(self,nil,date("%X %x",Date))
			end
		else
			ELib.Tooltip.Hide()
		end
	end
}

local token = "A"
local tokenCount = 1
local tokensUsed = {}

function module:CreateToken()
	local newToken = string.char(math.random(1,26) + 64)
	if tokensUsed[newToken] then
		module:CreateToken()
		return
	end
	token = newToken
	tokensUsed[newToken] = true
	tokenCount = 1
end

module:CreateToken()


function module:GetWAVer(id)
	for sender,db in pairs(module.db.responces) do
		db[id] = 4
	end
	ExRT.F.SendExMsg("WAS_STATUS", "20\t"..id)
end

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

local function SendExMsg(prefix, msg, touser)
    if touser then
        ExRT.F.SendExMsg(prefix, msg, "WHISPER", touser)
    else
        ExRT.F.SendExMsg(prefix, msg)
    end
end

function module:ExportWA(id)
	local data = WeakAuras.GetData(id)
	if not data then
		return
	end
    local oldSyncTimer = data.exrtLastSync
    data.exrtLastSync = nil
	local str = DisplayToString(data, true)
	if not str then
        data.exrtLastSync = oldSyncTimer
		return
	end
	-- WeakAuras.Import(str) -- to text export string before sending
	tokenCount = tokenCount + 1
	if tokenCount > 4095 then
		module:CreateToken()
	end

	local tokenStr = format("%s%03X",token,tokenCount)

	for sender,db in pairs(module.db.responces) do
		db[id] = 4
	end
	if module.options:IsVisible() and module.options.UpdatePage then
		module.options.UpdatePage()
	end

    local random = module.db.random
    if random.time < (time() - 60) then
        random.time = time()
        random.num1 = math.random(1, #QueueSenderStrings)
        random.num2 = math.random(1, #QueueImagesStrings)
    end

	local compressed = LibDeflate:CompressDeflate(str,{level = 9})
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

	str = encoded

	local parts = ceil(#str / 247)
	local HR = (IsShiftKeyDown() and "1" or "")

    local touser = module.db.customTarget

	for i=1,parts do --burst sending
		if i<8 and not sendingData then
			local msg = str:sub( (i-1)*247+1 , i*247 )
			SendExMsg("WAS", tokenStr..msg, touser)
		else
			if i == 9 then
				if IsInRaid() then
					SendChatMessage("WeakAuras Sync: "..id.." Estimated time left: "..(floor((parts - i)*delayC) or "unk").." sec","RAID")
				else
					print("|cff9f3fff[WASync]|r "..id.." Estimated time left: "..(floor((parts - i)*delayC) or "unk").." sec")
				end
			end
			local msg = str:sub( (i-1)*247+1 , i*247 )
			local delay = #importDelays*delayC

			importDelays[#importDelays+1] = C_Timer.NewTimer(delay,function()
				sendingData = true
				SendExMsg("WAS", tokenStr..msg, touser)

				local red = min(255, (1 - i / parts) * 511)
				local green = min(255, (i / parts) * 511)
				ShowTooltip({
					{1, "WeakAuras Sync", 0.5, 0, 1},
					{1, id, 1, 1, 1},
					{1, "Sending WeakAuras data".. (HR=="1"and " |cffff44ff<HR>|r" or ""), 1, 0.82, 0},
					{2, "Estimated time: "..(floor((parts - i)*delayC) or "unk").." sec", ("|cFF%2x%2x00"):format(red, green)..(i*247).."|cFF00FF00/".. (parts*247)}
				})

				tremove(importDelays,#importDelays) -- removing last elemtnt in importDelays
			end)
		end
	end

    local now = time()
    data.exrtLastSync = now
	local delay = (#importDelays+1)*delayC

	importDelays[#importDelays+1] = C_Timer.NewTimer(delay,function()
		SendExMsg("WAS", tokenStr.."done^".. id .. "^" ..HR .. "^" .. now .. "^" .. module.db.random.num1 .. "^" .. module.db.random.num2, touser)
		print('|cff9f3fff[WASync]|r Sended', id, (HR=="1"and " |cffff44ff<HR>|r" or ""))
		sendingData = false
		ItemRefTooltip:Hide()
		tremove(importDelays,#importDelays)
	end)
end


module.options.customTargetEdit = ELib:Edit(module.options):Size(200,20):Tooltip("Custom Update Target(only for players in same guild)"):Point("TOPRIGHT",module.options,"TOPRIGHT",-10,-10):OnChange(function(self,isUser)
    if not isUser then
        return
    end
    local text = self:GetText()
    if text == "" then
        text = nil
    end
    module.db.customTarget = text
end)

local QueueFrame = ELib:Popup("|cFF8855FFWeakAuras Sync|r"):Size(450,275)

QueueFrame.Close:Hide()
QueueFrame:SetFrameStrata("FULLSCREEN_DIALOG")
ELib:Border(QueueFrame,1,.24,.25,.30,1,nil,3)
QueueFrame:Hide()

QueueFrame.memeSender = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-20):Color()
QueueFrame.currentWA = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-54):Color()
QueueFrame.currentWATitle = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-70):Color()
QueueFrame.importsLeft = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-100):Color(0.3,1,0.3)
QueueFrame.texture = ELib:Texture(QueueFrame):Point("BOTTOMRIGHT",QueueFrame,"BOTTOMRIGHT",-5,70):Size(170,170)
QueueFrame.processNextButton = ELib:mStyledButton(QueueFrame,"Import",15):Point("BOTTOM",QueueFrame,"BOTTOM",0,35):Size(440,25):OnClick(function()
    module.checkFrame:ProcessNext()
    QueueFrame:Hide()
end)
QueueFrame.processNextButton.Texture:SetGradient("VERTICAL",CreateColor(0.12,0.7,0.12,1), CreateColor(0.14,0.5,0.14,1))

QueueFrame.skipNextButton = ELib:mStyledButton(QueueFrame,"Skip",15):Point("TOP",QueueFrame.processNextButton,"BOTTOM",0,-5):Size(440,25):OnClick(function()
    module.checkFrame:RemoveFromQueue()
end)
QueueFrame.skipNextButton.Texture:SetGradient("VERTICAL",CreateColor(0.7,0.12,0.12,1), CreateColor(0.5,0.14,0.14,1))

function QueueFrame.SetupSession()
    local currentData = module.checkFrame.queue[1]
    local sender = currentData[2]
    local stringNum = currentData.num1
    local textureNum = currentData.num2

    QueueFrame.SessionStarted = true
    QueueFrame:Update()
    QueueFrame.texture:SetTexture(QueueImagesStrings[textureNum])
    QueueFrame.memeSender:SetText(QueueSenderStrings[stringNum]:format(ExRT.F.delUnitNameServer(sender)))

end

function QueueFrame:Update()
    if #module.checkFrame.queue == 0 then
		QueueFrame:Hide()
        QueueFrame.SessionStarted = false
	elseif InCombatLockdown() then
        QueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
        QueueFrame:SetScript("OnEvent", function()
            QueueFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
            QueueFrame:Update()
        end)
    else
        local currentData = module.checkFrame.queue[1]
        local id, forceSend = currentData[3], currentData[4]
        local data = WeakAuras.GetData(id)

        QueueFrame:Show()

        QueueFrame.currentWA:SetText("Current Weak Aura:")
        QueueFrame.currentWATitle:SetText(id .. (data and forceSend and " |cffff44ff<Update>|r" or " |cff00ff00<New>|r"))
        QueueFrame.importsLeft:SetText("Total imports left: " .. (#module.checkFrame.queue or ""))
    end
end

module.checkFrame = CreateFrame("Frame")
module.checkFrame.queue = {}
module.checkFrame.size = 0

function module.checkFrame.AddToQueue(self, dataStr,sender,id,forceSend,time,num1,num2)
	if not dataStr then return end

	local data = WeakAuras.GetData(id)

	if not forceSend and not data then
		module.checkFrame.queue[#module.checkFrame.queue+1] = {dataStr,sender,id,forceSend,time, num1=num1, num2=num2}
		print('|cff9f3fff[WASync]|r '.. sender:gsub("%-[^%-]*$","") .. ' |cff00ff00sended a new WA|r "'.. id ..'"')
	elseif forceSend and not data then
		module.checkFrame.queue[#module.checkFrame.queue+1] = {dataStr,sender,id,forceSend,time, num1=num1, num2=num2}
		print('|cff9f3fff[WASync]|r '.. sender:gsub("%-[^%-]*$","") .. ' |cff00ffffsended a new WA|r "'.. id ..'"')
	elseif forceSend and data then
		module.checkFrame.queue[#module.checkFrame.queue+1] = {dataStr,sender,id,forceSend,time, num1=num1, num2=num2}
		print('|cff9f3fff[WASync]|r '.. sender:gsub("%-[^%-]*$","") .. ' |cffff00ffupdated WA|r "'.. id ..'"')
	end

    if not QueueFrame.SessionStarted and #module.checkFrame.queue > 0 then
        QueueFrame.SetupSession()
    else
        QueueFrame:Update()
	end
end

function module.checkFrame.RemoveFromQueue(success,id)
    if success and id then
        local data = WeakAuras.GetData(id)
        if data then
            data.exrtLastSync = module.checkFrame.queue[1][5]
        end
    else -- we dont have ID return if no success
        local id = module.checkFrame.queue[1][3]
        local data = WeakAuras.GetData(id)
        if data then
            data.exrtLastSync = module.checkFrame.queue[1].oldTime
        end
    end
	tremove(module.checkFrame.queue, 1)

    QueueFrame:Update()
end

function module.checkFrame.ProcessNext(self)
	if #module.checkFrame.queue == 0 then
        QueueFrame.SessionStarted = false -- probably will never get there?
		return
	end

	local data = module.checkFrame.queue[1]
	module:ImportWA(data[1], data[2], data[3], data[4]) --dataStr, sender, id, forceSend
end

-- local oldVars = {["xOffset"]=1,["yOffset"]=1,["anchorFrameType"]=1,["anchorPoint"]=1,["selfPoint"]=1,["parent"]=1,["zoom"]=1,["width"]=1,["height"]=1}

-- TODO: refactor importing, avoid WeakAuras.Import always add data(probably with WeakAuras.Add) then if not forceUpdating restore data from oldVars
-- Big problem with WeakAuras.Add is handling groups
function module:ImportWA(dataStr,sender,id,forceSend)
	local data = WeakAuras.GetData(id)

    if data then
        module.checkFrame.queue[1].oldTime = data.exrtLastSync
        data.exrtLastSync = nil
    end

	local success, error
	if forceSend or not data then
		success, error = WeakAuras.Import(dataStr,nil,module.checkFrame.RemoveFromQueue)
	end

	if not success and error ~= nil then
		ExRT.F.SendExMsg("WAS_IMPORT_ERROR", "ERROR\t".. sender .. "\t" .. tostring(success) .. "\t" .. tostring(error))
        module.checkFrame.RemoveFromQueue()
	end
end

module:RegisterSlash()
function module:slash(arg)
	if arg:find("^was ") then
		local cmd = arg:match(" (.+)$")
		if cmd == "ver" then
			module.db.getVersion = GetTime()
			wipe(module.db.gettedVersions)
			ExRT.F.SendExMsg("WAS_STATUS", "10")

			C_Timer.After(2,function()
				local str = ""
				local inList = {}
				for q,w in pairs(module.db.gettedVersions) do
					local name = ExRT.F.delUnitNameServer(q)
					inList[name] = true
					str = str .. name .. " "
					if tonumber(w) then
						w = tonumber(w)
						str = str .. (w < VERSION and "|cffff0000" or w > VERSION and "|cff00ff00" or "") .. w .. (w ~= VERSION and "|r" or "") .. ","
					else
						str = str .. w .. ","
					end
				end
				str = str:gsub(",$","")
				print(str)

				str = "|cffff0000"
				for _, name in ExRT.F.IterateRoster do
					if not inList[ExRT.F.delUnitNameServer(name)] then
						str = str .. name .. ","
					end
				end

				str = str:gsub(",$","")
				print(str)
			end)
		end
	end
end

-- local function GetRecived(str) -- decode before WeakAuras.Import
--     local data, children, version
--     local received = StringToTable(str, true)

-- 	if received.m == "d" then
-- 		data = received
-- 		children = received.c
-- 		version = received.v
-- 	end
-- 	return data, children, version
-- end

-- local function table_update(tableFrom,tableTo,isSublevel)
	-- local keysToRemove = {}
	-- for key,val in pairs(tableFrom) do
		-- keysToRemove[key] = true
	-- end
	-- for key,val in pairs(tableTo) do
		-- if type(val) == 'table' and type(tableFrom[key]) == 'table' then
			-- keysToRemove[key] = nil
			-- table_update(tableFrom[key],tableTo[key],true)
		-- else
			-- keysToRemove[key] = nil
			-- if isSublevel or not oldVars[key] then
				-- tableFrom[key] = tableTo[key]
			-- end
		-- end
	-- end
	-- for key,_ in pairs(keysToRemove) do
		-- tableFrom[key] = nil
	-- end
-- end
