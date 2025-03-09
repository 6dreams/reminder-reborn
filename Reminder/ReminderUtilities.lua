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
        boss_name = GetRealZoneText(zoneID)
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
        MRT.F.SendExMsg("reminder","R\t"..token)
    end

    if not massRemove then
        if module.options.Update then
            module.options.Update()
        end
        module:ReloadAll()
    end
end

function module:SearchInData(data,searchPat)
	if not data then return end
	if not searchPat then return true end

	if
		(data.name and data.name:lower():find(searchPat,1,true)) or
		(data.msg and data.msg:lower():find(searchPat,1,true)) or
		(data.tts and data.tts:lower():find(searchPat,1,true)) or
		(data.spamMsg and data.spamMsg:lower():find(searchPat,1,true)) or
		(data.nameplateText and data.nameplateText:lower():find(searchPat,1,true)) or
		data.boss and LR.boss_name[data.boss]:lower():find(searchPat,1,true) or
		(data.units and data.units:lower():find(searchPat,1,true))
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
			isMelee = not ((MRT.A.Inspect and UnitName(unit) and MRT.A.Inspect.db.inspectDB[UnitName(unit)] and MRT.A.Inspect.db.inspectDB[UnitName(unit)].spec) == 262)
		elseif class == "HUNTER" then
			isMelee = not (MRT.isClassic) and (MRT.A.Inspect and UnitName(unit) and MRT.A.Inspect.db.inspectDB[UnitName(unit)] and MRT.A.Inspect.db.inspectDB[UnitName(unit)].spec) == 255
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

function module:AddTooltipLinesForData(data)
	local role1, role2 = module:GetPlayerRole()
	local myClass = UnitClassBase'player'
    local playerName = UnitName("player")

	local noteLine, isReversed
	if data.notepat then
		noteLine = module:FindPlayersListInNote(data.notepat,data.noteIsBlock)
		isReversed = data.notepat:find("^%-")

		if noteLine then
			noteLine = noteLine:gsub((data.notepat:gsub("^%-", "")) .. " *", ""):gsub("|c........", ""):gsub("|r", "")
				:gsub(" *$", ""):gsub("|", ""):gsub(" +", " ")
		end
	end


	GameTooltip:AddLine(LR.Name)
	GameTooltip:AddLine(data.name or ("~"..LR.NoName),nil,nil,nil,true)

	if data.msg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.msg)
		local text = module:FormatMsg(data.msg or "")
		GameTooltip:AddLine(text,nil,nil,nil,true)
	end

	if data.spamMsg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.spamMsg)
		GameTooltip:AddLine(module:FormatMsg(data.spamMsg or ""),nil,nil,nil,true)
	end

	if data.glow then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Frame glow:")
		GameTooltip:AddLine(module:FormatMsg(data.glow or ""),nil,nil,nil,true)
	end

	if data.tts then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Text to speech:")
		GameTooltip:AddLine(module:FormatMsg(data.tts),nil,nil,nil,true)
	end

	if data.WAmsg then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(LR.WAmsg)
		GameTooltip:AddLine(module:FormatMsg(data.WAmsg),nil,nil,nil,true)
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
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine(isReversed and "Load by note pattern(reversed):" or "Load by note pattern:")
		GameTooltip:AddLine(noteLine and "Note pattern: " .. data.notepat:gsub("^%-", ""))
		GameTooltip:AddLine(noteLine and "|cffee5555" .. (noteLine:gsub(playerName,"|cff55ee55"..playerName.."|r"):gsub("^%s+","") or "") or "|cffee5555Note line for current pattern is not found:\n" .. data.notepat,nil,nil,nil,true)
	end
	local playersInRaid = {}
	for _, name in MRT.F.IterateRoster, 6 do
		name = MRT.F.delUnitNameServer(name)
		playersInRaid[name] = true
	end

	if data.classes then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by class:(green is your class)")
		GameTooltip:AddLine("|cffee5555" .. data.classes:gsub("#".. myClass .. "#","#|cff55ee55"..myClass.."|r#")
													:gsub("%u+",function(class) return (LOCALIZED_CLASS_NAMES_MALE[class] or class) end)
													:gsub("#", " ")
													:gsub("^%s+",""),nil,nil,nil,true)
	end
	if data.roles then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by role:(green is your role)")
		GameTooltip:AddLine("|cffee5555" .. data.roles:gsub("#".. role1.."#","#|cff55ee55"..role1.."|r#")
													:gsub(( role2 and ("#" .. role2 .. "#") or "NIL"),"#|cff55ee55"..(role2 or "").."|r#")
													:gsub("%u+",function(role) local r = MRT.F.table_find3(module.datas.rolesList,role,3) return r and r[2] or role end)
													:gsub("#", " ")
													:gsub("^%s+",""),nil,nil,nil,true)
	end
	if data.groups then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by group:(green is your group)")
		local myGroup = MRT.F.GetOwnPartyNum()
		for w in string_gmatch(data.groups, "%d") do
			local isMy = tonumber(w) == myGroup
			GameTooltip:AddLine((isMy and "|cff55ee55" or "|cffee5555") ..  LR["Group"].." " .. w .. "|r")
		end

	end
	if data.units then
		GameTooltip:AddLine(" ")
		GameTooltip:AddLine("Load by name:(green are in raid)" .. (data.reversed and " (|cffff0000reversed|r)" or ""))
		local unitsPattern = "|cffee5555" .. (data.units:gsub("#", " "):gsub("^%s+","") or "")

		for name in next, playersInRaid do
			unitsPattern = unitsPattern:gsub(name .. " ","|cff55ee55"..name.."|r ")
		end
		GameTooltip:AddLine(unitsPattern,nil,nil,nil,true)
	end
	if not module.PUBLIC and AddonDB.RGAPI then
		if data.RGAPIAlias then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Load by RGAPI alias(green is me):")
			local aliasPattern = "|cffee5555" .. (data.RGAPIAlias:gsub("#", " "):gsub("^%s+","") or "")
			local myAlias = AddonDB.RGAPI:GetNick("player")
			if myAlias then
				aliasPattern = aliasPattern:gsub(myAlias .. " ","|cff55ee55"..myAlias.."|r ")
			end
			GameTooltip:AddLine(aliasPattern,nil,nil,nil,true)
		end

		if data.RGAPIList then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Load by RGAPI list: (green are loaded)")
			GameTooltip:AddLine("List: " .. data.RGAPIList .. (data.RGAPICondition and " |cff55ee55" .. data.RGAPICondition or "") .. (data.RGAPIOnlyRG and " |cff55ee55only RG" or ""))

			local isOkay,list = pcall(AddonDB.RGAPI.GetPlayersList,nil,data.RGAPIList,nil,data.RGAPIOnlyRG)

			if isOkay and list then
				list = table.concat(list," ")
				list = list:gsub("([%S]+)",function(name)
					local isOkay,isInList = pcall(module.RGAPICheckListCondition,nil,data.RGAPIList,data.RGAPICondition,data.RGAPIOnlyRG,name)
					if isOkay and not isInList then
						return "|cffee5555"..name.."|r"
					end
				end)
				if #list > 0 then
					GameTooltip:AddLine("|cff55ee55" .. list,nil,nil,nil,true)
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
