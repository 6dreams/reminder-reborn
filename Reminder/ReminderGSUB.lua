local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ReminderModule: MRTmodule
local module = MRT.A.Reminder
if not module then return end

---@class ELib
local ELib, L = MRT.lib, MRT.L

---@class Locale
local LR = AddonDB.LR

--upvalues
local setfenv, min, tonumber, tostring = setfenv, min, tonumber, tostring
local floor, ceil, UnitName, GetRaidTargetIndex, strsplit, GetTime = floor, ceil, UnitName, GetRaidTargetIndex, strsplit, GetTime
local UnitClass, UnitGroupRolesAssigned, next, ipairs, string_gmatch, pcall, format = UnitClass, UnitGroupRolesAssigned, next, ipairs, string.gmatch, pcall, format
local wipe, type, select, loadstring, max, RAID_CLASS_COLORS, string_gsub = wipe, type, select, loadstring, math.max, RAID_CLASS_COLORS, string.gsub
local UnitClassBase, table_concat = UnitClassBase, table.concat

local GetSpecialization = AddonDB.GetSpecialization
local GetSpecializationInfo = AddonDB.GetSpecializationInfo

local prettyPrint = module.prettyPrint

local GetSpellTexture = AddonDB.GetSpellTexture

---@class VMRT
local VMRT = VMRT

local gsub_trigger_params_now
local gsub_trigger_update_req

local function GetMRTNoteLines()
	return {strsplit("\n", VMRT.Note.Text1..(VMRT.Note.SelfText and "\n"..VMRT.Note.SelfText or ""))}
end

local defCDList = {
	DRUID = 22812,
	SHAMAN = 108271,
	WARLOCK = 104773,
	MONK = 115203,
	MAGE = 55342,
	DEMONHUNTER = 198589,
	DEATHKNIGHT = 48792,
	PRIEST = 19236,
	HUNTER = 281195,
	PALADIN = 498,
	WARRIOR = 184364,
	ROGUE = 1966,
	EVOKER = 363916,
}

local defSpecName = {
	[62] = "arcane",
	[63] = "fire",
	[64] = "frost",
	[65] = "holy",
	[66] = "protection",
	[70] = "retribution",
	[71] = "arms",
	[72] = "fury",
	[73] = "protection",
	[74] = "ferocity",
	[79] = "cunning",
	[81] = "tenacity",
	[102] = "balance",
	[103] = "feral",
	[104] = "guardian",
	[105] = "restoration",
	[250] = "blood",
	[251] = "frost",
	[252] = "unholy",
	[253] = "beast mastery",
	[254] = "marksmanship",
	[255] = "survival",
	[256] = "discipline",
	[257] = "holy",
	[258] = "shadow",
	[259] = "assassination",
	[260] = "outlaw",
	[261] = "subtlety",
	[262] = "elemental",
	[263] = "enhancement",
	[264] = "restoration",
	[265] = "affliction",
	[266] = "demonology",
	[267] = "destruction",
	[268] = "brewmaster",
	[269] = "windwalker",
	[270] = "mistweaver",
	[535] = "ferocity",
	[536] = "cunning",
	[537] = "tenacity",
	[577] = "havoc",
	[581] = "vengeance",
	[1467] = "devastation",
	[1468] = "preservation",
	[1473] = "augmentation"
}

local damageImmuneCDList = {
	MAGE = 45438,
	HUNTER = 186265,
	PALADIN = 642,
	ROGUE = 31224,
	DEMONHUNTER = 196555,
}

local sprintCDList = {
	DRUID = 106898,
	SHAMAN = 192077,
	MONK = 116841,
	EVOKER = 374968,
}

local healCDList = {
	[65] = 31884,
	[257] = 64844,
	[264] = 108280,
	[270] = 115310,
	[105] = 157982,
	[1468] = 363534,
}

local raidCDList = {
	[65] = 31821,
	[66] = 204018,
	[256] = 62618,
	[264] = 98008,
	[71] = 97463,
	[72] = 97463,
	[73] = 97463,
	[577] = 196718,
	[250] = 51052,
	[251] = 51052,
	[252] = 51052,
}

local externalCDList = {
	[71] = 3411,
	[72] = 3411,
	[73] = 3411,
	[65] = 6940,
	[66] = 6940,
	[70] = 6940,
	[256] = 33206,
	[257] = 47788,
	[270] = 116849,
	[105] = 102342,
	[1468] = 357170,
}

local freedomCDList = {
	PALADIN = 1044,
	HUNTER = 272682,
	MONK = 116841,
}

-- local textureToSpell = {}
-- module.textureToSpell = textureToSpell
-- for _,tbl in next, ({defCDList,damageImmuneCDList,sprintCDList,healCDList,raidCDList,externalCDList,freedomCDList}) do
--     for k,spellID in next, (tbl) do
--         textureToSpell[GetSpellTexture(spellID)] = spellID
--     end
-- end


local function GSUB_NumCondition(num,str)
	num = tonumber(num)
	if not num or num == 0 then
		return ""
	end
	return select(num,strsplit(";",str or "")) or ""
end

local function GSUB_Icon(str)
	local spellID,iconSize = strsplit(":",str)
	spellID = tonumber(spellID)
	if spellID then
		local spellTexture = GetSpellTexture( spellID )
		if not iconSize or iconSize == "" then
			iconSize = 0
		end
		return "|T"..(spellTexture or "134400")..":"..iconSize.."|t"
	end
end

local function GSUB_Upper(_,str)
	return (str or ""):upper()
end

local function GSUB_Lower(_,str)
	return (str or ""):lower()
end

local function GSUB_ModNextWord(str)
	if str:find("^specIconAndClassColor") then
		local name = str:match("^specIconAndClassColor *(.-)$")
		if name then
			local mod = name
			local class = select(2,UnitClass(name))
			if class and RAID_CLASS_COLORS[class] then
				mod = "|c"..RAID_CLASS_COLORS[class].colorStr..mod.."|r"
			end
			local role = UnitGroupRolesAssigned(name)
			if role == "TANK" then
				mod = "|A:groupfinder-icon-role-large-tank:0:0|a"..mod
			elseif role == "DAMAGER" then
				mod = "|A:groupfinder-icon-role-large-dps:0:0|a"..mod
			elseif role == "HEALER" then
				mod = "|A:groupfinder-icon-role-large-heal:0:0|a"..mod
			end
			return mod
		else
			return ""
		end
	elseif str:find("^specIcon") then
		local name = str:match("^specIcon *(.-)$")

		if name then
			local role = UnitGroupRolesAssigned(name)
			if role == "TANK" then
				return "|A:groupfinder-icon-role-large-tank:0:0|a"..name
			elseif role == "DAMAGER" then
				return "|A:groupfinder-icon-role-large-dps:0:0|a"..name
			elseif role == "HEALER" then
				return "|A:groupfinder-icon-role-large-heal:0:0|a"..name
			else
				return name
			end
		else
			return ""
		end
	elseif str:find("^classColor") then
		local name = str:match("^classColor *(.-)$")
		if name then
			local class = select(2,UnitClass(name))
			if class and RAID_CLASS_COLORS[class] then
				return "|c"..RAID_CLASS_COLORS[class].colorStr..name.."|r"
			end
			return name
		else
			return ""
		end
	end
end

local GSUB_Math
do
	local setfenv = setfenv
	GSUB_Math = function(line)
		local c,lastChar = line:match("^([%d%.%+%-/%*%(%)%%%^]+)([rfc]?)$")
		if c then
			local func, error = loadstring("return "..c)
			if func then
				setfenv(func, {})
				local isFine, res = pcall(func)
				if type(res) == "number" then
					if lastChar == "r" then
						return tostring(floor(res+0.5))
					elseif lastChar == "f" then
						return tostring(floor(res))
					elseif lastChar == "c" then
						return tostring(ceil(res))
					else
						return tostring(res)
					end
				end
			end
		else
			local isHex,hexBase,str = line:match("^(hex):(%d-):?([^:]+)$")
			if isHex == "hex" then
				if hexBase == "" then hexBase = 16 end
				str = str:match("[0-9A-Za-z]+$")
				if str then
					local res = tonumber(str,tonumber(hexBase))
					if res then
						return tostring(res)
					end
				end
			end
		end
		return "0"
	end
end

local function GSUB_Repeat(num,line)
	return (line or ""):rep(min(100,tonumber(num) or 0))
end

local function GSUB_Length(num,line)
	local res = MRT.F.utf8sub(line or "", 1, tonumber(num) or 0)
	if res:find("|c.?.?.?.?.?.?.?.?$") then
		res = res:gsub("|c.?.?.?.?.?.?.?.?$","")
	end
	return res
end

local function GSUB_None()
	return ""
end

local function GSUB_ExRTNote(patt)
	patt = "^"..patt:gsub("%%","%%%%"):gsub("[%-%.%+%*%(%)%$%[%?%^]","%%%1")
	if VMRT and VMRT.Note and VMRT.Note.Text1 then
		local lines = GetMRTNoteLines()
		for i=1,#lines do
			if lines[i]:find(patt) then
				return lines[i]
			end
		end
	end
	return ""
end

local function GSUB_ExRTNoteList(str)
	local pos,patt = strsplit(":",str,2)
	patt = "^"..(patt or ""):gsub("%%","%%%%"):gsub("[%-%.%+%*%(%)%$]","%%%1")
	if VMRT and VMRT.Note and VMRT.Note.Text1 and tonumber(pos) then
		local lines = GetMRTNoteLines()
		for i=1,#lines do
			if lines[i]:find(patt) then
				pos = tonumber(pos)
				local line = lines[i]:gsub(patt,""):gsub("|c........",""):gsub("|r",""):gsub("%b{}",""):gsub("|",""):gsub(" +"," "):trim()
				local u,uc = {},0
				line = line:gsub("%b()",function(a)
					uc = uc + 1
					u[uc] = a:sub(2,-2)
					return "##"..uc
				end)
				local allpos = {strsplit(" ", line)}
				pos = pos % #allpos
				if pos == 0 then pos = #allpos end
				local res = allpos[pos]
				if not res then
					return ""
				end
				if res:find("^##%d+$") then
					local c = res:match("^##(%d+)$")
					res = u[tonumber(c)]
					res = res:gsub(" ",";")
				end
				return res
			end
		end
	end
	return ""
end

local function GSUB_Min(line)
	local m
	for c in string_gmatch(line, "[^;,]+") do
		c = tonumber(c)
		if c and (not m or c < m) then
			m = c
		end
	end
	return m or ""
end

local function GSUB_Max(line)
	local m
	for c in string_gmatch(line, "[^;,]+") do
		c = tonumber(c)
		if c and (not m or c > m) then
			m = c
		end
	end
	return m or ""
end

local function GSUB_Status(str)
	gsub_trigger_update_req = true
	if gsub_trigger_params_now and gsub_trigger_params_now._reminder then
		local triggerNum,uid = strsplit(":",str,2)

		triggerNum = tonumber(triggerNum) or 0
		local trigger = gsub_trigger_params_now._reminder.triggers[triggerNum]
		uid = tonumber(uid) or uid or ""
		if trigger and trigger.active and trigger.active[uid] then
			return "on"
		end
	end
	return "off"
end

local function GSUB_YesNoCondition(condition,str)
	local res = 1
	local pnow = 1
	local isORnow = false
	while true do
		local andps,andpe = condition:find(" AND ",pnow)
		local orps,orpe = condition:find(" OR ",pnow)

		local curre = condition:len()
		local nexts
		local isOR
		if andps then
			curre = andps - 1
			nexts = andpe + 1
		end
		if orps and orps < curre then
			curre = orps - 1
			nexts = orpe + 1
			isOR = true
		end
		local condNow = condition:sub(pnow,curre)
		local a,b,condRest = condNow:match("^([^}=~<>]*)([=~<>]=?)(.-)$")

		local isPass
		if condRest then
			for c in string_gmatch(condRest, "[^;]+") do
				if
					(b == "=" and a == c) or
					(b == "~" and a ~= c) or
					(b == ">" and tonumber(a) and tonumber(c) and tonumber(a) > tonumber(c)) or
					(b == "<" and tonumber(a) and tonumber(c) and tonumber(a) < tonumber(c)) or
					(b == "<=" and tonumber(a) and tonumber(c) and tonumber(a) <= tonumber(c)) or
					(b == ">=" and tonumber(a) and tonumber(c) and tonumber(a) >= tonumber(c)) or
					(b == ">" and a > c) or
					(b == "<" and a < c)
				then
					isPass = true
					break
				end
			end
		end

		if isORnow then
			res = res + (isPass and 1 or 0)
		else
			res = res * (isPass and 1 or 0)
		end

		isORnow = isOR

		if not nexts then
			break
		end
		pnow = nexts
	end

	local yes,no = strsplit(";",str or "")
	if res > 0 then
		return yes
	else
		return no or ""
	end
end

local function GSUB_Mark(num)
	if tonumber(num) then
		return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..num..":0|t"
	end
end

local function GSUB_Role(name)
	local role = UnitGroupRolesAssigned(name)
	return (role or "none"):lower()
end

local function GSUB_RoleExtra(name)
	local role1,role2 = module:GetUnitRole(name)
	return (role2 or role1 or "none"):lower()
end

local function GSUB_Find(arg,res)
	local find,str = strsplit(":",arg,2)
	local yes,no = strsplit(";",res or "")
	if (str or ""):find(find) then
		return yes
	else
		return no or ""
	end
end

local function GSUB_Replace(arg,res)
	local from,to = strsplit(":",arg,2)
	local isOk, resOk = pcall(string_gsub, res, from, to)
	return isOk and resOk or res
end

local function GSUB_Sub(arg)
	local from,to,str = strsplit(":",arg,3)
	from = tonumber(from)
	to = tonumber(to or "")
	if from and to and str then
		if to == 0 then to = -1 end
		return str:sub(from,to)
	else
		return ""
	end
end

local function GSUB_EscapeSequences(a)
	if a == "n" then
		return "\n"
	else
		return "|"..a
	end
end

local function GSUB_OnlyIconsFix(text)
	if text:gsub("|T.-|t","") == "" then
		return text .. " "
	end
end

local function GSUB_Trim(text)
	return text:trim()
end


local GSUB_TriggerExtra, GSUB_Trigger

do
	local listOfExtraTriggerWords = {
		allSourceNames = true,
		allTargetNames = true,
		activeTime = true,
		timeLeft = true,
		status = true,
		allActiveUIDs = true,
		activeNum = true,
		timeMinLeft = true,
		counter = true,
		patt = true,
	}
	local listOfReplacers = {}

	for k, v in next, module.C do
		if v.replaceres then
			for _,r in ipairs(v.replaceres) do
				listOfReplacers[r] = true
			end
		end
	end

	function GSUB_TriggerExtra(mword,word,num,rest)
		if gsub_trigger_params_now then
			local r = gsub_trigger_params_now[mword or word]

			if word == "counter" then
				local mod,subrest = rest:match("^:(%d+)(.-)$")

				if mod then
					local c = tonumber(r) or 0
					if c == 0 then
						return "0"..subrest
					end
					return ( (c-1)%(tonumber(mod) or 1) + 1 )..subrest
				elseif r then
					return r..rest
				else
					return "0"..rest
				end
			elseif word == "timeLeft" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger
				if t and not t.status then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
				end
				if t and t.status then
					local mod,subrest = rest:match("^:(%d+)(.-)$")
					if mod then
						return format("%."..mod.."f",max((t.status.timeLeft or t.status.timeLeftB) - GetTime(),0))..subrest
					else
						return format("%.1f",max((t.status.timeLeft or t.status.timeLeftB) - GetTime(),0))..rest
					end
				end
				return rest
			elseif type(r) == "function" then
				gsub_trigger_update_req = true
				local res,cutRest = r(select(2,strsplit(":",rest)))
				if res then
					return res..(not cutRest and rest or "")
				end
			elseif r then
				return r..rest
			elseif word == "allSourceNames" or word == "allTargetNames" then
				local key = word == "allSourceNames" and "sourceName" or "targetName"

				local indexFrom,indexTo,customPattern = select(2,strsplit(":",rest))
				local onlyText

				if indexFrom then indexFrom = tonumber(indexFrom) end
				if indexTo then indexTo = tonumber(indexTo) end
				if indexFrom == 0 or indexTo == 0 then indexFrom = nil end
				if customPattern == "1" then onlyText = true customPattern = nil else onlyText = false end
				local r=""
				local lowestindex = 0
				local count = 0

				if not onlyText then
					gsub_trigger_update_req = true
				end

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0]
				if not t and gsub_trigger_params_now._reminder then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
					t = t or gsub_trigger_params_now._reminder.triggers[1]
				end
				if t then
					repeat
						local lownow, vnow
						for _,v in next, t.active do
							if (not lownow or v.aindex < lownow) and v.aindex > lowestindex then
								vnow = v
								lownow = v.aindex
							end
						end
						if vnow then
							count = count + 1
							if not indexFrom or (count >= indexFrom and count <= indexTo) then
								if vnow[key] then
									if customPattern then
										r=r..customPattern:gsub("([A-Za-z]+)",function(a)
											return vnow[a]
										end)
									else
										local index = UnitName(vnow[key]) and GetRaidTargetIndex(vnow[key])
										if index and not onlyText then r=r..MRT.F.GetRaidTargetText(index,0) end
										r=r..(onlyText and "" or "%classColor")..vnow[key]..", "
									end
								end
							end
							lowestindex = lownow
						else
							lowestindex = nil
						end
					until (not lowestindex)
					return (customPattern and r:gsub("|?|?[n;,] *$","") or r:sub(1,-3))..(not rest:find("^:") and rest or "")
				end
				return rest
			elseif word == "allActiveUIDs" then
				local indexFrom,indexTo = select(2,strsplit(":",rest))

				if indexFrom then indexFrom = tonumber(indexFrom) end
				if indexTo then indexTo = tonumber(indexTo) end
				local r=""
				local lowestindex = 0
				local count = 0
				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 1]
				if t then
					repeat
						local lownow, vnow
						for _,v in next, t.active do
							if (not lownow or v.aindex < lownow) and v.aindex > lowestindex then
								vnow = v
								lownow = v.aindex
							end
						end
						if vnow then
							count = count + 1
							if not indexFrom or (count >= indexFrom and count <= indexTo) then
								if vnow.uid or vnow.guid then
									r=r..(vnow.uid or vnow.guid)..";"
								end
							end
							lowestindex = lownow
						else
							lowestindex = nil
						end
					until (not lowestindex)
					return r:sub(1,-2) .. (not indexFrom and rest or "")
				end
				return rest
			elseif word == "activeTime" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger
				if t and not t.status then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
				end
				if t and t.status then
					local mod,subrest = rest:match("^:(%d+)(.-)$")
					if mod then
						return format("%."..mod.."f",GetTime() - t.status.atime)..subrest
					else
						return format("%.1f",GetTime() - t.status.atime)..rest
					end
				end
				return rest
			elseif word == "status" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 1]
				if t and t.status then
					return "on"..rest
				else
					return "off"..rest
				end
			elseif word == "activeNum" then
				gsub_trigger_update_req = true

				local c = 0
				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger or gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[1]
				if t and t.active then
					for _ in next, t.active do
						c=c+1
					end
				end
				return tostring(c)..rest
			elseif word == "timeMinLeft" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger or gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[1]
				if t and t._trigger.activeTime then
					local lowest
					for _,v in next, t.active do
						if v.atime and (not lowest or lowest > v.atime) then
							lowest = v.atime
						end
					end
					if lowest then
						local mod,subrest = rest:match("^:(%d+)(.-)$")
						if mod then
							return format("%."..mod.."f",lowest + t._trigger.activeTime - GetTime())..subrest
						else
							return format("%.1f",lowest + t._trigger.activeTime - GetTime())..rest
						end
					end
				end
				return rest
			elseif word == "patt" then
				if gsub_trigger_params_now._data and gsub_trigger_params_now._data.notepat then
					local players = module:FindPlayersListInNote(gsub_trigger_params_now._data.notepat)
					if players then
						local c = 1
						local isOpen
						players = players:gsub("%b{}","")
						local list = {}
						for p in string_gmatch(players, "[^ ]+") do
							if p:sub(1,1) == "(" then
								isOpen = true
								p = p:sub(2)
							end
							if p:sub(-1,-1) == ")" then
								isOpen = false
								p = p:sub(1,-2)
							end
							if isOpen and list[c] then
								list[c] = list[c] .. " " .. p
							else
								list[c] = p
							end
							if not isOpen then
								c = c + 1
							end
						end
						if num ~= "" then
							return (list[tonumber(num)] or "")..rest
						else
							return players..rest
						end
					end
				end
			elseif listOfReplacers[word] then
				return rest or ""
			end
		end
	end

	function GSUB_Trigger(mword,word,num,rest)
		if word == "playerName" then
			return UnitName'player'..rest
		elseif word == "playerClass" then
			return (select(2,UnitClass'player'):lower())..rest
		elseif word == "playerSpec" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			return (defSpecName[specid or 0] or specname and specname:lower())..rest
		elseif word == "defCDIcon" then
			local icon = defCDList[select(2,UnitClass'player') or ""]
			if not icon and not gsub_trigger_params_now then
				return "{spell:22812}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "damageImmuneCDIcon" then
			local icon = damageImmuneCDList[select(2,UnitClass'player') or ""]
			if not icon and not gsub_trigger_params_now then
				return "{spell:45438}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "sprintCDIcon" then
			local icon = sprintCDList[select(2,UnitClass'player') or ""]
			if not icon and not gsub_trigger_params_now then
				return "{spell:106898}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "healCDIcon" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			local icon = healCDList[specid or 0]
			if not icon and not gsub_trigger_params_now then
				return "{spell:31884}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "raidCDIcon" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			local icon = raidCDList[specid or 0]
			if not icon and not gsub_trigger_params_now then
				return "{spell:31821}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "externalCDIcon" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			local icon = externalCDList[specid or 0]
			if not icon and not gsub_trigger_params_now then
				return "{spell:6940}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "freedomCDIcon" then
			local icon = freedomCDList[UnitClassBase("player") or ""]
			if not icon and not gsub_trigger_params_now then
				return "{spell:1044}" .. rest
			end
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "notePlayer" or word == "notePlayerRight" then
			if gsub_trigger_params_now and gsub_trigger_params_now._data then
				local notePattern = gsub_trigger_params_now._data.notepat
				if notePattern then
					local found, line = module:FindPlayerInNote(notePattern)
					if found and line then
						line = line:gsub(notePattern.." *",""):gsub("|c........",""):gsub("|r",""):gsub("{time[^}]+}",""):gsub("{0}.-{/0}",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
						local playerName = UnitName'player'
						if word == "notePlayer" then
							local prefix = line:match("([^ ]+) +[^ ]*"..playerName) or ""
							if prefix:find("_$") then
								local prefix2 = line:match("(%b__) +[^ ]*"..playerName)
								if prefix2 then
									prefix = prefix2:sub(2,-2)
								end
							end
							if prefix:find("^%(") then prefix = prefix:sub(2) end
							return prefix..rest
						else
							local suffix = line:match(playerName.."[^ ]* +([^ ]+)") or ""
							if suffix:find("^_") then
								local suffix2 = line:match(playerName.."[^ ]* +(%b__)")
								if suffix2 then
									suffix = suffix2:sub(2,-2)
								end
							end
							return suffix..rest
						end
					end
				end
			end
			return rest
		elseif mword:find("^specIcon") or mword:find("^classColor") then
			--nothing, save for GSUB_ModNextWord
			return
		end
		return GSUB_TriggerExtra(mword,word,num,rest) or ("%"..mword..rest)
	end

	local set_list = {}
	local set_update_req
	local function GSUB_Set(num,str)
		if num ~= "" and tonumber(num) then
			if set_update_req then
				wipe(set_list)
				set_update_req = false
			end
			set_list[num] = str
		end
		return ""
	end
	local function GSUB_SetBack(num)
		return set_list[num] or ""
	end

	local function GSUB_Setparam(str)
		if gsub_trigger_params_now then
			local key,value = strsplit(":",str,2)
			gsub_trigger_params_now["#"..key] = value
		end
	end

	local conditionList = {
		["warrior"] = 1,
		["paladin"] = 1,
		["hunter"] = 1,
		["rogue"] = 1,
		["priest"] = 1,
		["deathknight"] = 1,
		["shaman"] = 1,
		["mage"] = 1,
		["warlock"] = 1,
		["monk"] = 1,
		["druid"] = 1,
		["demonhunter"] = 1,
		["evoker"] = 1,
		["healer"] = 2,
		["heal"] = 2,
		["dd"] = 2,
		["damager"] = 2,
		["tank"] = 2,
	}

	local pl_list = {}
	local pl_condres = {}
	local pl_condadd = {}
	local function GSUB_PlayersList_All(line)
		local filters,pos = strsplit(":",line)
		if not pos then
			return ""
		end
		pos = tonumber(pos)
		if not pos then
			return ""
		end
		for k in next, pl_list do pl_list[k]=nil end
		for k in next, pl_condadd do pl_condadd[k]=nil end
		local cond = {strsplit(",",filters:lower())}
		for i=#cond,1,-1 do
			if cond[i]:find("^%+") then
				pl_condadd[i] = pl_condadd[i] or i
				pl_condadd[i-1] = pl_condadd[i]

				cond[i] = cond[i]:sub(2)
			end
		end
		for _, name, subgroup, class, guid, rank, level, online, isDead, combatRole in MRT.F.IterateRoster, MRT.F.GetRaidDiffMaxGroup() do
			for k in next, pl_condres do pl_condres[k]=nil end
			for i=1,#cond do
				local status = false

				local c = cond[i]
				local condType = conditionList[ c ]
				if condType == 1 then
					if class:lower() == c then
						status = true
					end
				elseif c:find("^g%d+") then
					if tostring(subgroup or "") == c:match("^g(%d+)") then
						status = true
					end
				elseif condType == 2 then
					if combatRole:lower() == c then
						status = true
					elseif (combatRole == "HEALER" and c == "heal") or
						(combatRole == "DAMAGER" and c == "dd")
					then
						status = true
					end
				end

				if pl_condadd[i] == i then
					for j=i-1,1,-1 do
						if pl_condadd[j] ~= i then break end
						status = status and pl_condres[j]
					end
					for j=i,1,-1 do
						if pl_condadd[j] ~= i then break end
						pl_condres[j] = status
					end
				else
					pl_condres[i] = status
				end
			end

			local isAny = false
			for i=1,#cond do
				if pl_condres[i] then
					isAny = true
					break
				end
			end
			if isAny then
				pl_list[#pl_list+1] = MRT.F.delUnitNameServer(name)
			end
		end

		if pos < 0 then
			return #pl_list >= 0 and pl_list[-pos] or ""
		end
		return #pl_list >= 0 and pl_list[((pos - 1) % #pl_list) + 1] or ""
	end
	local function GSUB_PlayersList(mword,arg)
		return GSUB_PlayersList_All(mword..":"..arg)
	end

	local replace_counter = false
	local replace_forchat = false

	local playerName = UnitName'player'

	local function GSUB_Notepos(str,word,num,rest)
		if not gsub_trigger_params_now then return "" end
		local data = gsub_trigger_params_now._data
		if not data or not data.notepat then return "" end
		local y,x = strsplit(":",str,2)
		local reverse, pat = data.notepat:match("^(%-?)([^{]+)")
		pat = pat and pat:trim()
		local cacheKey = (data.noteIsBlock and "block" or "line") .. pat
		y = tonumber(y)
		x = tonumber(x)
		local notePatsCache = module.db.notePatsCache
		if cacheKey:find("^block") then
			if notePatsCache[cacheKey] then
				local currCache = notePatsCache[cacheKey]
				if y then
					y = y % #currCache
					if y == 0 then y = #currCache end
					if x and currCache[y] then -- targeted spot
						x = x % #currCache[y]
						if x == 0 then x = #currCache[y] end
						if currCache[y][x] then
							return currCache[y][x]
						end
					else -- iterate whole line
						local str = ""
						for i=1,#currCache[y] do
							if currCache[y][i] then
								str = str .. currCache[y][i] .. " "
							end
						end
						return str:gsub("%s+$","")
					end
				-- else -- iterate whole cache
					-- for i=1,#currCache do
					--     for j=1,#currCache[i] do
					--         if currCache[i][j] then
					--             return currCache[i][j]
					--         end
					--     end
					-- end
				end

				return "" -- have cache but no player found
			end
		else -- patt is for lines
			if notePatsCache[cacheKey] then
				local currCache = notePatsCache[cacheKey]
				if y then -- targeted spot
					y = y % #currCache
					if y == 0 then y = #currCache end
					if currCache[y] then
						return currCache[y]
					end
					return "" -- have cache but no player found
				else -- iterate whole line
					local str = ""
					for i,name in next, currCache do
						str = str .. name .. " "
					end
					return str:gsub("%s+$","")
				end
			end
		end
		-- if notePatsCache[cacheKey] then
		--     local currCache = notePatsCache[cacheKey]
		--     if x and y then
		--         return currCache and currCache[y] and currCache[y][x]
		--     elseif y then
		--         return currCache and type(currCache[y]) == 'string' and currCache[y] or ""
		--     end

		--     return "" .. rest-- have cache but no player found
		-- end

	end

	local function GSUB_RGAPIList(str)
		if not AddonDB.RGAPI then return "" end

		local id, condition, rgonly = strsplit(":", str,3)
		local list = AddonDB.RGAPI:GetListCached(id, rgonly == "1")
		if list then
			AddonDB.RGAPI:ConvertGUIDsToNames(list)
		   	local l = AddonDB.RGAPI:GetPlayersListCondition(list, condition)
		   	return table_concat(l, " ")
		end
	end


	local function GSUB_TriggerActivations(str)
		if gsub_trigger_params_now and gsub_trigger_params_now._reminder then
			local trigger = gsub_trigger_params_now._reminder.triggers[tonumber(str or "?") or 1]
			if trigger then
				return trigger.triggerActivations or 0
			end
			return ""
		end
	end

	local function GSUB_ReminderActivations()
		if gsub_trigger_params_now and gsub_trigger_params_now._reminder then
			return gsub_trigger_params_now._reminder.remActivations or 0
		end
	end

	local GSUB_AbbreviateNum
	local locale = GetLocale()
	if (locale == "koKR" or locale == "zhCN" or locale == "zhTW") then
		local symbol_1K, symbol_10K, symbol_1B, symbol_1T = "천", "만", "억", "조" -- default to kr
		if (locale == "zhCN") then
			symbol_1K, symbol_10K, symbol_1B, symbol_1T = "千", "万", "亿", "兆"
		elseif (locale == "zhTW") then
			symbol_1K, symbol_10K, symbol_1B, symbol_1T = "千", "萬", "億", "兆"
		end

		function GSUB_AbbreviateNum(str)
			local num = tonumber(str)
			if num then
				if (num >= 1000000000000) then
					return format("%.2f", num / 1000000000000):gsub("[%.0]+$", "") .. symbol_1T
				elseif (num >= 100000000) then
					return format("%.2f", num / 100000000):gsub("[%.0]+$", "") .. symbol_1B
				elseif (num >= 10000) then
					return format("%.2f", num / 10000):gsub("[%.0]+$", "") .. symbol_10K
				elseif (num >= 1000) then
					return format("%.2f", num / 1000):gsub("[%.0]+$", "") .. symbol_1K
				else
					return format("%.0f", num)
				end
			end
			return str
		end
	else
		function GSUB_AbbreviateNum(str)
			local num = tonumber(str)
			if num then
				if (num > 999999999) then
					return format("%.1f", num/1000000000):gsub("[%.0]+$","") .. "B"
				elseif (num > 1000000) then
					return format ("%.1f", num/1000000):gsub("[%.0]+$","") .. "M"
				elseif (num > 999) then
					return format ("%.1f", num/1000):gsub("[%.0]+$","") .. "K"
				end

				return format ("%.0f", str)
			end
			return str
		end
	end

	local handlers_nocloser = {
		spell = GSUB_Icon,
		math = GSUB_Math,
		noteline = GSUB_ExRTNote,
		note = GSUB_ExRTNoteList,
		min = GSUB_Min,
		max = GSUB_Max,
		status = GSUB_Status,
		role = GSUB_Role,
		roleextra = GSUB_RoleExtra,
		sub = GSUB_Sub,
		trim = GSUB_Trim,
		setparam = GSUB_Setparam,
		notepos = GSUB_Notepos,
		rgapilist = GSUB_RGAPIList,
		triggerActivations = GSUB_TriggerActivations,
		remActivations = GSUB_ReminderActivations,
		shortnum = GSUB_AbbreviateNum,
		funit = GSUB_PlayersList_All,
	}

	local handlers_nocloser_withname = {
		["warrior"] = GSUB_PlayersList,
		["paladin"] = GSUB_PlayersList,
		["hunter"] = GSUB_PlayersList,
		["rogue"] = GSUB_PlayersList,
		["priest"] = GSUB_PlayersList,
		["deathknight"] = GSUB_PlayersList,
		["shaman"] = GSUB_PlayersList,
		["mage"] = GSUB_PlayersList,
		["warlock"] = GSUB_PlayersList,
		["monk"] = GSUB_PlayersList,
		["druid"] = GSUB_PlayersList,
		["demonhunter"] = GSUB_PlayersList,
		["evoker"] = GSUB_PlayersList,
	}

	local function replace_nocloser(mword,word,num,fullArg,arg)
		local handler = handlers_nocloser[word]
		-- print(mword,word,num,fullArg,arg,gsub_trigger_params_now, (mword:match("^#") or word:match("^#")),gsub_trigger_params_now[mword], gsub_trigger_params_now[word])
		if handler then
			--print('nc',word,arg)
			replace_counter = true
			return handler(arg) or ""
		elseif handlers_nocloser_withname[word] then
			replace_counter = true
			return handlers_nocloser_withname[word](mword,arg) or ""
		elseif word == "rt" then
			replace_counter = true
			--print('nc',word,arg)
			if replace_forchat then
				return "___M"..num.."___"
			end
			return GSUB_Mark(num) or ""
		elseif gsub_trigger_params_now and (gsub_trigger_params_now[word] or gsub_trigger_params_now[mword] or listOfExtraTriggerWords[word] or listOfExtraTriggerWords[mword]) then
			replace_counter = true
			--print('nc',word,arg)
			return GSUB_TriggerExtra(mword,word,num,fullArg) or ""
		elseif gsub_trigger_params_now and (mword:match("^#") or word:match("^#")) and (gsub_trigger_params_now[mword] or gsub_trigger_params_now[word]) then
			return gsub_trigger_params_now[mword] or gsub_trigger_params_now[word]
		end
	end

	local handlers_closer = {
		num = GSUB_NumCondition,
		up = GSUB_Upper,
		lower = GSUB_Lower,
		rep = GSUB_Repeat,
		len = GSUB_Length,
		["0"] = GSUB_None,
		cond = GSUB_YesNoCondition,
		find = GSUB_Find,
		replace = GSUB_Replace,
		set = GSUB_Set,
	}

	local function replace_closer(word,arg,data)
		local handler = handlers_closer[word]
		if handler then
			replace_counter = true
			--print('c',word,arg,data)
			return handler(arg,data) or ""
		end
	end

	function module:FormatMsg(msg,params,isForChat,printLog)
		gsub_trigger_params_now = params
		gsub_trigger_update_req = false

		set_update_req = true
		replace_forchat = false
		if isForChat then
			replace_forchat = true
		end

		msg = msg:gsub("%%(([A-Za-z]+)(%d*))([^%% ,{}]*)",GSUB_Trigger)

		local subcount = 0
		while true do
			replace_counter = false
			if printLog then
				prettyPrint('Iteration',subcount,"|cffaaaaaa"..msg.."|r")
			end
			subcount = subcount + 1
			--print('sc',subcount,msg)
			msg = msg:gsub("{(([A-Za-z#]+)(%d*))(:?([^{}]*))}",replace_nocloser) --# for setparam
				:gsub("{([^:{}]+):?([^{}]*)}([^{}]-){/%1}",replace_closer)
			if not replace_counter or subcount > 100 then
				if not set_update_req then
					msg = msg:gsub("%%set(%d+)",GSUB_SetBack)
					set_update_req = true
				else
					break
				end
			end
		end

		msg = msg:gsub("||([crTtnAa])",GSUB_EscapeSequences)
			:gsub("%%([sc][A-Za-z]+ *[^ ,%%;:%(%)|]*)",GSUB_ModNextWord)
			-- :gsub("[^\n]+",GSUB_OnlyIconsFix)

		if replace_forchat then
			msg = msg:gsub("___M(%d+)___","{rt%1}")
		end

		msg = msg:gsub("\\n", "\n")
		return msg, gsub_trigger_update_req
	end
end

function module:FormatMsgForChat(msg)
	return msg:gsub("|c........",""):gsub("|[rn]",""):gsub("|[TA][^|]+|[ta]","")
end

function module:ExtraCheckParams(extraCheck,params,printLog)
	extraCheck = module:FormatMsg(extraCheck,params,false,printLog)

	if not extraCheck:find("[=~<>]") then
		return false, false, extraCheck
	else
		if GSUB_YesNoCondition(extraCheck,1) == "1" then
			return true, true, extraCheck
		else
			return false, true, extraCheck
		end
	end
end

