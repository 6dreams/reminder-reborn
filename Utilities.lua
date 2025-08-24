local GlobalAddonName = ...

---@class AddonDB
local AddonDB = select(2, ...)

local MRT = GMRT

local Ambiguate = Ambiguate
local GetNumGroupMembers = GetNumGroupMembers
local GetNumSubgroupMembers = GetNumSubgroupMembers
local GetRaidRosterInfo = GetRaidRosterInfo
local GetServerTime = GetServerTime
local IsInGroup = IsInGroup
local IsInRaid = IsInRaid
local strsplit = strsplit
local strsub = strsub
local tonumber = tonumber
local sort = sort
local tinsert = tinsert
local next = next
local tostring = tostring
local type = type
local UnitClassBase = UnitClassBase
local UnitExists = UnitExists
local UnitFullName = UnitFullName
local UnitGUID = UnitGUID
local UnitInParty = UnitInParty
local UnitInRaid = UnitInRaid
local UnitIsUnit = UnitIsUnit
local UnitName = UnitName
local bit_band = bit.band
local bit_rshift = bit.rshift

-----------------------------------------------------------
-- Compability
-----------------------------------------------------------

AddonDB.GetSpellInfo = C_Spell and C_Spell.GetSpellInfo and function(spellID)
	if not spellID then
		return nil
	end
	local sp = C_Spell.GetSpellInfo(spellID)
	if sp then
		return sp.name, nil, sp.iconID, sp.castTime, sp.minRange, sp.maxRange, sp.spellID, sp.originalIconID
	end
end or GetSpellInfo
AddonDB.GetSpellName = C_Spell and C_Spell.GetSpellName or GetSpellInfo
AddonDB.GetSpellTexture = C_Spell and C_Spell.GetSpellTexture or GetSpellTexture
AddonDB.GetSpellCooldown = C_Spell and C_Spell.GetSpellCooldown and function(spellID)
	if not spellID then
		return nil
	end
	local cd = C_Spell.GetSpellCooldown(spellID)
	if cd then
		return cd.startTime, cd.duration, cd.isEnabled, cd.modRate
	end
end or GetSpellCooldown


AddonDB.GetSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization or GetSpecialization or MRT.NULLfunc
AddonDB.GetSpecializationInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo or GetSpecializationInfo or MRT.NULLfunc

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

do
	local function __genOrderedIndex(t)
		local orderedIndex = {}
		for key in next, t do
			if key ~= "__orderedIndex" then
				tinsert(orderedIndex, key)
			end
		end
		sort(orderedIndex, function(a, b)
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
-- Encoding and Decoding wrappers
-----------------------------------------------------------

do
	local LibDeflateAsync = LibStub("LibDeflateAsync-reminder")
	local LibSerializeAsync = LibStub("LibSerializeAsync-reminder")

	local configForLS = { errorOnUnserializableType = false }
	local configForDeflate = { level = 9 }
	---@param table table
	---@param forPrint boolean
	---@return string
	function AddonDB:CompressTable(table, forPrint)
		if not table then
			return nil
		end

		local serialized = LibSerializeAsync:SerializeEx(configForLS, table)
		local compressed = C_EncodingUtil and C_EncodingUtil.CompressString(serialized, Enum.CompressionMethod.Deflate, Enum.CompressionLevel.Default) or LibDeflateAsync:CompressDeflate(serialized, configForDeflate)
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

		local compressed = C_EncodingUtil and C_EncodingUtil.CompressString(str) or LibDeflateAsync:CompressDeflate(str, configForDeflate)
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
end

-----------------------------------------------------------
-- Mark flags metatable
-----------------------------------------------------------
do

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
end

-----------------------------------------------------------
-- Import and Export windows
-----------------------------------------------------------

do
	local importFrame, exportFrame
	local function createImportFrame()
		local MLib = AddonDB.MLib

		local function onFinish(thread)
			-- thread == thread or nil == nil
			if importFrame.awaitedThread == thread then
				importFrame.spinner:Stop()
				importFrame:Hide()
			end
		end
		local function ImportOnUpdate(self, elapsed)
			self.tmr = self.tmr + elapsed
			if self.tmr >= 0.1 then
				self.tmr = 0
				self:SetScript("OnUpdate", nil)
				local str = table.concat(self.buff):trim()

				self:SetMaxBytes(1000)
				self:SetText(str:sub(1, 1000)) -- show start of the text for convenience
				self.parent.Edit:ToTop()

				self.buff = {}
				self.buffPos = 0

				if self.parent.ImportFunc then
					local res = self.parent.ImportFunc(str) -- if importFunc is async thread we show spinner while data is processed
					if AddonDB:IsThread(res) then
						self.parent.awaitedThread = res
						self.parent.spinner:Start()
						res:Finally(onFinish)
					else
						onFinish()
					end
				else
					onFinish()
				end
			end
		end

		local importWindow = MLib:Popup(AddonDB.LR["Import"]):Size(650, 100)
		importWindow.Edit = MLib:MultiEdit(importWindow):Point("TOP", 0, -20):Size(640, 75)
		importWindow:SetScript("OnHide", function(self)
			self.Edit:SetText("")
			self.spinner:Stop()
			self.awaitedThread = nil
			self.Edit.EditBox:SetMaxBytes(1)
		end)
		importWindow:SetScript("OnShow", function(self)
			self.Edit.EditBox.buffPos = 0
			self.Edit.EditBox.tmr = 0
			self.Edit.EditBox.buff = {}
			self.Edit.EditBox:SetFocus()
			self:NewPoint("CENTER", UIParent, "CENTER", 0, 0)
		end)
		importWindow.Edit.EditBox:SetMaxBytes(1)
		importWindow.Edit.EditBox:SetScript("OnChar", function(self, c)
			self.buffPos = self.buffPos + 1
			self.buff[self.buffPos] = c
			self:SetScript("OnUpdate", ImportOnUpdate)
		end)
		importWindow.Edit.EditBox.parent = importWindow
		importWindow:SetFrameStrata("FULLSCREEN_DIALOG")
		importWindow.spinner = MLib:LoadingSpinner(importWindow):Point("CENTER", 0, 0):Size(60, 60)

		return importWindow
	end

	---@param title string?
	---@param onPasteFunc fun(str: string): AsyncThreadData?
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
		local ELib = MRT.lib
		local MLib = AddonDB.MLib

		local exportWindow = MLib:Popup(AddonDB.LR["Export"]):Size(650, 50)
		exportWindow.Edit = ELib:Edit(exportWindow):Point("TOP", 0, -20):Size(640, 25)
		function exportWindow:Update(noText)
			if not noText then
				if self.Edit.fixedText then
					if self.Edit:GetText() ~= self.Edit.fixedText then
						self.Edit:SetText(self.Edit.fixedText)
					end
				else
					self.Edit:SetText("")
				end
			end
			self.Edit:HighlightText()
			self.Edit:SetCursorPosition(0)
		end
		exportWindow:SetScript("OnHide", function(self)
			self.Edit:SetText("")
			self.Edit.fixedText = nil
			self.spinner:Stop()
			if self.awaitedThread then
				self.awaitedThread:Kill()
				self.awaitedThread = nil
			end
		end)
		exportWindow.Edit:SetScript("OnEditFocusGained", function(self)
			exportWindow:Update()
		end)
		exportWindow.Edit:SetScript("OnMouseUp", function(self, button)
			if button == "RightButton" then
				exportWindow:Hide()
			else
				exportWindow:Update()
			end
		end)
		exportWindow.Edit:SetScript("OnKeyUp", function(self, c)
			if (c == "c" or c == "C") and IsControlKeyDown() and not exportWindow.awaitedThread then
				exportWindow:Hide()
			end
		end)
		exportWindow.Edit:OnChange(function(self, isUser)
			if isUser then
				exportWindow:Update()
			else
				exportWindow:Update(true) -- update without text to avoid recursion
			end
		end)
		exportWindow.Edit:SetScript("OnEscapePressed", function(self)
			exportWindow:Hide()
		end)
		function exportWindow:OnShow()
			self.tmr = 0
			self.Edit:SetFocus()

			self:NewPoint("CENTER", UIParent, "CENTER", 0, 0)
		end
		exportWindow:SetFrameStrata("FULLSCREEN_DIALOG")
		exportWindow.spinner = MLib:LoadingSpinner(exportWindow):Point("CENTER", 0, -10):Size(60, 60)

		return exportWindow
	end

	local function onTextReady(text)
		if type(text) ~= "string" then
			error(GlobalAddonName ..": text must be a string, got ".. type(text))
		end

		exportFrame.Edit.fixedText = text
		exportFrame.spinner:Stop()
		exportFrame.awaitedThread = nil

		exportFrame:Update()
	end
	local function onError(err)
		exportFrame:Hide()
		exportFrame.awaitedThread = nil
	end

	---@param text string|AsyncThreadData
	---@param title string?
	function AddonDB:QuickCopy(text, title)
		if type(text) == "number" then
			text = tostring(text)
		end
		assert(type(text) == "string" or AddonDB:IsThread(text), GlobalAddonName ..": text must be a string or AsyncThreadData, got ".. type(text))
		if not exportFrame then
			exportFrame = createExportFrame()
		end
		exportFrame:Hide() -- trigger OnHide script in case it was shown before

		exportFrame.title:SetText(title or AddonDB.LR["Export"])


		if AddonDB:IsThread(text) then
			exportFrame.awaitedThread = text
			exportFrame.spinner:Start()
			text:OnSuccess(onTextReady):Catch(onError)
		else
			onTextReady(text)
		end

		exportFrame:Show()
	end
end
