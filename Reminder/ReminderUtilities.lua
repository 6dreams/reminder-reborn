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


local GetSpecialization = AddonDB.GetSpecialization
local GetSpecializationInfo = AddonDB.GetSpecializationInfo

local bit_bor, bit_band, bit_bnot, bit_bxor = bit.bor, bit.band, bit.bnot, bit.bxor


function module:AddReminder(token,data)
	if not (data and token) then
		return
	end

	if module.db.isLiveSession then
		if not VMRT.Reminder.liveChanges.added[token] and not VMRT.Reminder.liveChanges.changed[token] then
			if not VMRT.Reminder.data[token] then
				VMRT.Reminder.liveChanges.added[token] = true
			else
				VMRT.Reminder.liveChanges.changed[token] = VMRT.Reminder.data[token]
			end
		end
	end

	if not VMRT.Reminder.data[token] or MRT.F.table_compare(VMRT.Reminder.data[ token ], data) ~= 1 then
		data.notSync = true
	end

	VMRT.Reminder.data[token] = data
	VMRT.Reminder.removed[token] = nil

	if module.db.isLiveSession then
		module:Sync(false,nil,nil,token,nil,true)
	end

	module:ReloadAll()
end

function module:DeleteReminder(data, massRemove, ignoreComms, liveSession)
	if not data then
		return
	end

	local boss_name = LR.boss_name[data.boss] -- metatable so no need to nil check
	if (not boss_name or boss_name == "") and data.zoneID then
		local zoneID = data.zoneID and tonumber(tostring(data.zoneID):match("^[^, ]")) or nil
		boss_name = LR.instance_name[zoneID]
	end
	module.prettyPrint(format("Deleted %q for %q", data.name or LR.NoName, boss_name ~= "" and boss_name or "unknown"))

	local type
	if data.WAmsg then --WA
		type = "WA"
	elseif data.nameplateGlow then
		type = "NAMEPLATEGLOW"
	elseif data.glow then  --RAIDFRAME
		type = "FRAMEGLOW"
	elseif data.spamMsg then --CHAT
		type = "/say"
	elseif data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5 then -- BARS
		type = "BAR"
	else -- NORMAL TEXT
		if data.msgSize == 1 then
			type = "SMALLTEXT"
		elseif data.msgSize == 2 then
			type = "BIGTEXT"
		else
			type = "T"
		end
	end
	local token = data.token
	VMRT.Reminder.removed[ token ] = {
		time = time(),
		boss = data.boss,
		zoneID = data.zoneID,
		name = data.name,
		type = type,
		token = token,
		archived_data = CopyTable(data)
	}
	VMRT.Reminder.data[ token ] = nil

	if liveSession then
		if not VMRT.Reminder.liveChanges.changed[token] and not VMRT.Reminder.liveChanges.added[token] then
			VMRT.Reminder.liveChanges.changed[token] = data
		end
		module:Sync(false,nil,nil,token,nil,true)
	elseif not ignoreComms and AddonDB:CheckSelfPermissions() then
		local encoded = AddonDB:CompressString(tostring(token))
		AddonDB:SendComm("REMINDER_DEL", encoded)
	end

	if not massRemove then
		if module.options.Update then
			module.options.Update()
		end
		module:ReloadAll()
	end
end


local function findFirstOf(input, words, start, plain)
  local startPos, endPos
  for _, w in ipairs(words) do
    local s, e = input:find(w, start, plain)
    if s and (not startPos or startPos > s) then
      startPos, endPos = s, e
    end
  end
  return startPos, endPos
end

---@param input string
---@return string[] subStrings
function module:splitAtOr(input)
  input = input or ""
  local ret = {}
  local splitStart, splitEnd, element = nil, nil, nil
  local separators = { "|", " or "}
  splitStart, splitEnd = findFirstOf(input, separators, 1, true);
  while(splitStart) do
    element, input = input:sub(1, splitStart -1 ), input:sub(splitEnd + 1)
    if(element ~= "") then
      tinsert(ret, element)
    end
    splitStart, splitEnd = findFirstOf(input, separators, 1, true);
  end
  if(input ~= "") then
    tinsert(ret, input)
  end
  return ret;
end

-- performs lowercase search with support of `|` and `" or "`
function module:AdvancedSearch(input, search) -- return true if found
	if type(search) == "string" then
		search = module:splitAtOr(search)
	end

	for k, word in next, search do
		if input:lower():find(word:lower(), 1, true) then
			return true
		end
	end

	return false
end

function module:SearchInData(data, searchPat)
	if not data then return end
	if not searchPat then return true end

	if
		(data.name and module:AdvancedSearch(data.name, searchPat)) or
		(data.msg and module:AdvancedSearch(data.msg, searchPat)) or
		(data.tts and module:AdvancedSearch(data.tts, searchPat)) or
		(data.spamMsg and module:AdvancedSearch(data.spamMsg, searchPat)) or
		(data.nameplateText and module:AdvancedSearch(data.nameplateText, searchPat)) or
		(data.boss and module:AdvancedSearch(LR.boss_name[data.boss], searchPat)) or
		(data.units and module:AdvancedSearch(data.units, searchPat)) or
		(data.glow and module:AdvancedSearch(data.glow, searchPat))
	then
		return true
	end
end

function module:GetPlayerRole()
	local role = UnitGroupRolesAssigned('player')
	if role == "NONE" then
		local _, _, _, _, specRole = GetSpecializationInfo(GetSpecialization())
		if specRole then role = specRole end
	end
	if role == "HEALER" then
		local _,class = UnitClass('player')
		return role, (class == "PALADIN" or class == "MONK") and "MHEALER" or "RHEALER"
	elseif role ~= "DAMAGER" then
		--TANK, NONE
		return role
	else
		local _,class = UnitClass('player')
		local isMelee = (class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER")
		if class == "DRUID" then
			isMelee = GetSpecialization() ~= 1
		elseif class == "SHAMAN" then
			isMelee = GetSpecialization() == 2
		elseif class == "HUNTER" then
			isMelee = not (MRT.isClassic) and GetSpecialization() == 3
		end
		if isMelee then
			return role, "MDD"
		else
			return role, "RDD"
		end
	end
end

function module:GetUnitRole(unit)
	local role = UnitGroupRolesAssigned(unit)
	if role == "HEALER" then
		local _,class = UnitClass(unit)
		return role, (class == "PALADIN" or class == "MONK") and "MHEALER" or "RHEALER"
	elseif role ~= "DAMAGER" then
		--TANK, NONE
		return role
	else
		local _,class = UnitClass(unit)
		local isMelee = (class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER")
		if class == "DRUID" then
			isMelee = not (UnitPowerType(unit) == 8)	--astral power
		elseif class == "SHAMAN" then
			local name = UnitNameUnmodified(unit)
			isMelee = not ((MRT.A.Inspect and name and MRT.A.Inspect.db.inspectDB[name] and MRT.A.Inspect.db.inspectDB[name].spec) == 262)
		elseif class == "HUNTER" then
			local name = UnitNameUnmodified(unit)
			isMelee = not (MRT.isClassic) and (MRT.A.Inspect and name and MRT.A.Inspect.db.inspectDB[name] and MRT.A.Inspect.db.inspectDB[name].spec) == 255
		end
		if isMelee then
			return role, "MDD"
		else
			return role, "RDD"
		end
	end
end

-- enh shaman can't be checked, always ranged
function module:CmpUnitRole(unit,roleIndex)
	if not UnitGUID(unit) then return end
	local mainRole, subRole = module:GetUnitRole(unit)

	local sub = MRT.F.table_find3(module.datas.rolesList,subRole,3)
	if sub and (roleIndex == sub[1] or (roleIndex >= 100 and bit.band(roleIndex - 100,sub[4]) > 0)) then
		return true
	end

	local main = MRT.F.table_find3(module.datas.rolesList,mainRole,3)
	if main and (roleIndex == main[1] or (roleIndex >= 100 and bit.band(roleIndex - 100,main[4]) > 0)) then
		return true
	end

	if roleIndex == 6 and main ~= "TANK" then --not tank role, hardcoded
		return true
	end
end

function module:GetRoleIndex()
	local mainRole, subRole = module:GetPlayerRole()

	local sub = MRT.F.table_find3(module.datas.rolesList,subRole,3)
	if sub then
		return sub[1]
	end

	local main = MRT.F.table_find3(module.datas.rolesList,mainRole,3)
	if main then
		return main[1]
	else
		return 0
	end
end


local string_gmatch = string.gmatch
local GetSpellInfo = AddonDB.GetSpellInfo


-- by default red, if in list then green, if me then cover with >me<
local function colorizeLineForTooltip(line, inList, me)
	return line:gsub("%S+", function(a)
		local res = a
		if type(inList) == "table" and inList[a] or type(inList) == "function" and inList(a) then
			res =  "|cff55ee55" .. a .. "|r"
		else
			res = "|cffee5555" .. a .. "|r"
		end
		if type(me) == "table" and tContains(me, a) or a == me then
			return "|cffffff00>" .. res .. "<|r"
		end
		return res
	end)
end

function module:AddTooltipLinesForData(data)
	local role1, role2 = module:GetPlayerRole()
	local myClass = UnitClassBase'player'
	local playerName = UnitNameUnmodified("player")

	local playersInRaid, classesInRaid, rolesInRaid = {}, {}, {}
	for unit in AddonDB:IterateGroupMembers(6) do
		playersInRaid[UnitName(unit)] = true
		local class = UnitClassBase(unit)
		if class then
			classesInRaid[ LOCALIZED_CLASS_NAMES_MALE[class] ] = true
		end
		local mainRole, subRole = module:GetUnitRole(unit)
		if mainRole and mainRole ~= "NONE" then
			local localizedMainRole = MRT.F.table_find3(module.datas.rolesList, mainRole, 3)
			rolesInRaid[localizedMainRole[2]] = true
		end
		if subRole then
			local localizedSubRole = MRT.F.table_find3(module.datas.rolesList, subRole, 3)
			rolesInRaid[localizedSubRole[2]] = true
		end
	end


	GameTooltip:AddLine(LR.Name)
	GameTooltip:AddLine(data.name or ("~"..LR.NoName), nil, nil, nil, true)

	if data.msg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.msg)
		local text = module:FormatMsg(data.msg or "")
		GameTooltip:AddLine(text, nil, nil, nil, true)
	end

	if data.spamMsg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.spamMsg)
		GameTooltip:AddLine(module:FormatMsg(data.spamMsg or ""), nil, nil, nil, true)
	end

	if data.glow then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Frame glow:")
		GameTooltip:AddLine(module:FormatMsg(data.glow or ""), nil, nil, nil, true)
	end

	if data.tts then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Text to speech:")
		GameTooltip:AddLine(module:FormatMsg(data.tts), nil, nil, nil, true)
	end

	if data.WAmsg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.WAmsg)
		GameTooltip:AddLine(module:FormatMsg(data.WAmsg), nil, nil, nil, true)
	end

	if data.nameplateGlow then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Nameplate glow:")
		for i = 1, #module.datas.glowTypes do
			if module.datas.glowTypes[i][1] == data.glowType then
				GameTooltip:AddLine(module.datas.glowTypes[i][2])
				break
			end
		end
		if data.nameplateText then
			GameTooltip:AddLine("Text: " .. (module:FormatMsg(data.nameplateText)),nil,nil,nil,true)
		end
	end

	if data.triggers then
		GameTooltip:AddLine(" ")
		GameTooltip:AddDoubleLine(LR.TriggersCount..":",#data.triggers)
		for i=1,#data.triggers do
			local trigger = data.triggers[i]
			local event = trigger.event
			local eventDB = module.C[event]
			if eventDB then
				if event == 1 then
					local spellText = ""
					if trigger.spellID then
						local spellName,_,spellTexture = GetSpellInfo(trigger.spellID)
						spellText = " "
						if spellTexture then
							spellText = "|T"..spellTexture..":0|t "
						end
						spellText = spellText .. (spellName or trigger.spellID)
					elseif trigger.spellName then
						if tonumber(trigger.spellName) then
							local spellName,_,spellTexture = GetSpellInfo(tonumber(trigger.spellName))
							spellText = " "
							if spellTexture then
								spellText = "|T"..spellTexture..":0|t "
							end
							spellText = spellText .. (spellName or trigger.spellName)
						else
							spellText = trigger.spellName
						end
					end
					local countText = trigger.counter and format("(%s)",trigger.counter) or ""
					local delayText = (trigger.delayTime and spellText and " " or "") .. (trigger.delayTime or "")
					GameTooltip:AddDoubleLine("  ["..i.."] "..(trigger.eventCLEU and module.C[trigger.eventCLEU] and module.C[trigger.eventCLEU].lname or "")..":",(spellText or "") .. countText .. delayText)
				elseif event == 3 then
					GameTooltip:AddDoubleLine("  ["..i.."] "..eventDB.lname,(trigger.delayTime or ""))
				elseif event == 2 then
					GameTooltip:AddDoubleLine("  ["..i.."] "..eventDB.lname.." "..(trigger.pattFind or ""),(trigger.delayTime or ""))
				else
					-- check if event has spellID field
					local triggerFields = eventDB.triggerFields
					local hasSpellID = tContains(triggerFields,"spellID")
					local hasNumberPercent = tContains(triggerFields,"numberPercent")
					if hasSpellID then
						local spellText = ""
						if trigger.spellID then
							local spellName,_,spellTexture = GetSpellInfo(trigger.spellID)
							spellText = " "
							if spellTexture then
								spellText = "|T"..spellTexture..":0|t "
							end
							spellText = spellText .. (spellName or trigger.spellID)
						elseif trigger.spellName then
							if tonumber(trigger.spellName) then
								local spellName,_,spellTexture = GetSpellInfo(tonumber(trigger.spellName))
								spellText = " "
								if spellTexture then
									spellText = "|T"..spellTexture..":0|t "
								end
								spellText = spellText .. (spellName or trigger.spellName)
							else
								spellText = trigger.spellName
							end
						end
						local countText = trigger.counter and format("(%s)",trigger.counter) or ""
						local delayText = (trigger.delayTime and spellText and " " or "") .. (trigger.delayTime or "")
						GameTooltip:AddDoubleLine("  ["..i.."] "..eventDB.lname..":",(spellText or "") .. countText .. delayText)
					elseif hasNumberPercent then
						local countText = trigger.counter and format("(%s)",trigger.counter) or ""
						local delayText = (trigger.delayTime and " " or "") .. (trigger.delayTime or "")
						GameTooltip:AddDoubleLine("  ["..i.."] "..eventDB.lname..":",trigger.numberPercent ..  countText .. delayText)
					else
						GameTooltip:AddDoubleLine("  ["..i.."] "..eventDB.lname,"")
					end
				end
			end
		end
	end



	if data.notepat then
		local noteLine = module:FindPlayersListInNote(data.notepat, data.noteIsBlock)
		local isReversed = data.notepat:find("^%-")

		if noteLine then
			noteLine = noteLine:gsub((data.notepat:gsub("^%-", "")) .. " *", ""):gsub("|c........", ""):gsub("|r", "")
				:gsub(" *$", ""):gsub("|", ""):gsub(" +", " ")

			noteLine = colorizeLineForTooltip(noteLine, function(a)
				return playersInRaid[a] and module:ParseNote(data, a)
			end, playerName)
		end

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(isReversed and "Reversed load by note pattern: (green are in raid and loaded)" or "Load by note pattern: (green are in raid and loaded)")
		GameTooltip:AddLine(noteLine and "Note pattern: " .. data.notepat:gsub("^%-", ""))
		GameTooltip:AddLine(noteLine and "|cffee5555" .. noteLine or "|cffee5555Note line for current pattern is not found:\n" .. data.notepat, nil, nil, nil, true)
	end


	if data.classes then
		local classesString = data.classes:gsub("#", " "):trim():gsub("%u+", function(class) return (LOCALIZED_CLASS_NAMES_MALE[class] or class) end)
		classesString = colorizeLineForTooltip(classesString, classesInRaid, LOCALIZED_CLASS_NAMES_MALE[myClass])

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by class: (green are in raid)")
		GameTooltip:AddLine(classesString, nil, nil, nil, true)
	end
	if data.roles then
		local rolesSting = data.roles:gsub("#", " "):trim():gsub("%u+", function(role)
			local r = MRT.F.table_find3(module.datas.rolesList, role, 3)
			return r and r[2] or role
		end)
		rolesSting = colorizeLineForTooltip(rolesSting, rolesInRaid, {role1, role2})

		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by role: (green are in raid)")
		GameTooltip:AddLine(rolesSting, nil, nil, nil, true)
	end
	if data.groups then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by group: (green is your group)")
		local myGroup = MRT.F.GetOwnPartyNum()
		for w in string_gmatch(data.groups, "%d") do
			local isMy = tonumber(w) == myGroup
			if isMy then
				w = "|cff55ee55>" .. w .. "<|r"
			end

			GameTooltip:AddLine(LR["Group"] .. " " .. w)
		end

	end
	if data.units then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(data.reversed and "Reversed load by name: (green are in raid)" or "Load by name: (green are in raid)")
		local unitsPattern = data.units:gsub("#", " "):trim()
		unitsPattern = colorizeLineForTooltip(unitsPattern, playersInRaid, playerName)

		GameTooltip:AddLine(unitsPattern, nil, nil, nil, true)
	end
	if not module.PUBLIC and AddonDB.RGAPI then
		if data.RGAPIAlias then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Load by RGAPI alias(green are in raid):")
			local aliasString = data.RGAPIAlias:gsub("#", " "):trim()
			local myAlias = AddonDB.RGAPI:GetNick("player")
			aliasString = colorizeLineForTooltip(aliasString, function(a)
				return AddonDB.RGAPI:GetCharacterInGroup(a)
			end, myAlias)
			GameTooltip:AddLine(aliasString, nil, nil, nil, true)
		end

		if data.RGAPIList then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Load by RGAPI list: (green are loaded)")
			GameTooltip:AddLine("List: " .. data.RGAPIList .. (data.RGAPICondition and " |cff55ee55" .. data.RGAPICondition or "") .. (data.RGAPIOnlyRG and " |cff55ee55only RG" or ""))

			local isOkay, list = pcall(AddonDB.RGAPI.GetPlayersList, nil, data.RGAPIList, nil, data.RGAPIOnlyRG)

			if isOkay and list then
				AddonDB.RGAPI:ConvertGUIDsToNames(list)
				local passList = AddonDB.RGAPI:GetPlayersListCondition(list, data.RGAPICondition)
				list = table.concat(list, " ")
				list = colorizeLineForTooltip(list, function(a) return tContains(passList, a) end, playerName)

				if #list > 0 then
					GameTooltip:AddLine(list, nil, nil, nil, true)
				else
					GameTooltip:AddLine("|cffee5555No players in list|r")
				end
			else
				GameTooltip:AddLine("|cffff0000Error getting list|r") -- error on getting list
			end
		end
	end

end

function module:CheckUnit(unitVal,unitguid,trigger)
	if not unitguid then
		return false
	elseif type(unitVal) == "string" then
		return UnitGUID(unitVal) == unitguid
	elseif type(unitVal) == "number" then
		if unitVal < 0 then
			local triggerDest = trigger and trigger._reminder.triggers[-unitVal]
			if triggerDest then
				for uid,data in next, triggerDest.active do
					if data.guid == unitguid then
						return true
					end
				end
			end
		else
			local list = module.datas.unitsList[unitVal]
			for i=1,#list do
				local guid = UnitGUID(list[i])
				if guid == unitguid then
					return true
				end
			end
		end
	end
end

function module:CheckNumber(checkFuncs,num)
	if not num then return false end
	for k,v in next, checkFuncs do
		if v(num) then
			return true
		end
	end
end

function module:FormatTime(t, full)
	return full and format("%d:%02d.%d", t/60, t%60, t%1*10) or format("%d:%02d", t/60, t%60)
end

---@param token number
---@param option ReminderModule.PERSONAL_DATA_OPTION
---@param value boolean
function module:SetDataOption(token, option, value)
	local bit = module.ENUM.OPTION_BITS[option]
	if not bit then
		error(format("%s: SetDataOption: Invalid option %s", GlobalAddonName, tostring(option)))
	end
	local o = VMRT.Reminder.options[token] or 0

	if value then
		o = bit_bor(o, bit)
	else
		o = bit_band(o, bit_bnot(bit))
	end

	if o == 0 then
		VMRT.Reminder.options[token] = nil
	else
		VMRT.Reminder.options[token] = o
	end
end


---@param token number
---@param option ReminderModule.PERSONAL_DATA_OPTION
---@return boolean newValue
function module:ToggleDataOption(token, option)
	local bit = module.ENUM.OPTION_BITS[option]
	if not bit then
		error(format("%s: ToggleDataOption: Invalid option %s", GlobalAddonName, tostring(option)))
	end
	local o = VMRT.Reminder.options[token] or 0

	o = bit_bxor(o, bit)

	if o == 0 then
		VMRT.Reminder.options[token] = nil
		return false
	else
		VMRT.Reminder.options[token] = o
		return module:GetDataOption(token, option)
	end
end

---@param token number
---@param option ReminderModule.PERSONAL_DATA_OPTION
---@return boolean value
function module:GetDataOption(token, option)
	local bit = module.ENUM.OPTION_BITS[option]
	if not bit then
		error(format("%s: GetDataOption: Invalid option %s", GlobalAddonName, tostring(option)))
	end

	local o = VMRT.Reminder.options[token]

	return o and bit_band(o, bit) > 0
end

do
	local function iterate()
		if VMRT.Reminder.data then
			for token,data in next, VMRT.Reminder.data do
				coroutine.yield(token,data,VMRT.Reminder.data)
			end
		end

		if VMRT.Reminder.removed then
			for token,data in next, VMRT.Reminder.removed do
				if data.archived_data then
					coroutine.yield(token,data.archived_data,VMRT.Reminder.removed)
				end
			end
		end

		if VMRT.Reminder.DataProfiles then
			for profileKey,profileData in next, VMRT.Reminder.DataProfiles do
				if profileData.data then
					for token,data in next, profileData.data do
						coroutine.yield(token,data,profileData.data)
					end
				end
				if profileData.removed then
					for token,data in next, profileData.removed do
						if data.archived_data then
							coroutine.yield(token,data.archived_data,profileData.removed)
						end
					end
				end
			end
		end
	end

	-- iterates all data that may need modernization
	function module:IterateAllData()
		return coroutine.wrap(iterate)
	end
end

do
	local function iterateRemoved()
		if VMRT.Reminder.removed then
			for token,data in next, VMRT.Reminder.removed do
				coroutine.yield(token, data, VMRT.Reminder.removed)
			end
		end
		if VMRT.Reminder.DataProfiles then
			for profileKey,profileData in next, VMRT.Reminder.DataProfiles do
				if profileData.removed then
					for token,data in next, profileData.removed do
						coroutine.yield(token, data, profileData.removed)
					end
				end
			end
		end
	end
	-- iterates all removed data that may need to be removed due to being old
	function module:IterateRemovedData()
		return coroutine.wrap(iterateRemoved)
	end
end

do
	local function iterateVisualSettings()
		if VMRT.Reminder.VisualSettings then
			coroutine.yield(VMRT.Reminder.VisualSettings, VMRT.Reminder.VisualProfile, true)
		end
		if VMRT.Reminder.VisualProfiles then
			for profileKey,profileData in next, VMRT.Reminder.VisualProfiles do
				if profileData.VisualSettings and profileKey ~= VMRT.Reminder.VisualProfile then -- profile is empty table while it is loaded
					coroutine.yield(profileData.VisualSettings, profileKey, false)
				end
			end
		end
	end

	-- iterates all visual settings that may need modernization
	function module:IterateVisualSettings()
		return coroutine.wrap(iterateVisualSettings)
	end
end


