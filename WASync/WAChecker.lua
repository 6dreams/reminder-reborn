local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

if not WeakAuras then return end

local LibDeflate = LibStub:GetLibrary("LibDeflate")

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then
	module = AddonDB:New("WAChecker",MRT.L.WAChecker)
end


-- Overwriting base functions to make sure they are not changed by Afiya in future
module.db.responces = {}
module.db.responces2 = {}
module.db.lastReq = {}
module.db.lastReq2 = {}
module.db.lastCheck = {}
module.db.lastCheckName = {}
local sync_db = {}
module.db.sync_db = sync_db

function module:SendReq(ownList)
	local str = ""
	local c = 0
	if type(ownList) == "table" then
		for WA_name in next, ownList do
			str = str..WA_name.."''"
			c = c + 1
		end
	else
		for WA_name,WA_data in next, WeakAurasSaved.displays do
			str = str..WA_name.."''"
			c = c + 1
		end
	end
	str = str:gsub("''$","")

	if #str == 0 then
		return
	end

	local compressed = LibDeflate:CompressDeflate(str,{level = 7})
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
	encoded = encoded .. "##F##"
	local parts = ceil(#encoded / 245)

	--print(#str,#encoded,parts,c)

	for i=1,parts do
		local msg = encoded:sub( (i-1)*245+1 , i*245 )
		if i == 1 then
			MRT.F.SendExMsg("wac2", MRT.F.CreateAddonMsg("G","H",msg))
		else
			MRT.F.SendExMsg("wac2", MRT.F.CreateAddonMsg("G",msg))
		end
	end
end


local SendRespSch = nil

function module:SendResp()
	SendRespSch = nil
	if not WeakAurasSaved then
		MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("R","NOWA"))
		return
	end
	MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("R","DATA",tostring(WeakAuras.versionString)))

	local isChanged = true
	local buffer,bufferStart = {},0
	local r,rNow = 0,0
	for i=1,#module.db.lastReq do
		if WeakAurasSaved.displays[ module.db.lastReq[i] ] then
			r = bit.bor(r,2^rNow)
		end
		rNow = rNow + 1
		isChanged = true
		if i % 32 == 0 then
			buffer[#buffer + 1] = r
			r = 0
			rNow = 0
			if #buffer == 19 then
				MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("R",bufferStart,unpack(buffer)))
				wipe(buffer)
				bufferStart = i
				isChanged = false
			end
		end
	end
	if isChanged then
		buffer[#buffer + 1] = r
		MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("R",bufferStart,unpack(buffer)))
	end
end


local LONG = 2^31
function module:hash(str)
	local h = 5381
	for i=1, #str do
		h = math.fmod(h*33 + str:byte(i),LONG)
	end
	return h
end



local fieldsToClear = {
		load = {
		use_never = true,
		use_ingroup = true,
		ingroup = true,
		use_difficulty = true,
		difficulty = true,
		use_size = true,
		size = true,
		use_instance_type = true,
		instance_type = true,
	},
		grow = true,
		xOffset = true,
		yOffset = true,
		width = true,
		height = true,
		zoom = true,
		scale = true,
		texture = true,
		barColor = true,
		barColor2 = true,
		enableGradient = true,
		backgroundColor = true,
		color = true,
		font = true,
		fontSize = true,
	alpha = true,
	align = true,
	anchorFrameType = true,
  	anchorPerUnit = true,
	anchorPoint = true,
	backdropColor = true,
	columnSpace = true,
	selfPoint = true,
	frameStrata = true,
	inverse = true,
	rotation = true,
	sort = true,
	space = true,
	rowSpace = true,
	keepAspectRatio = true,
	gridType = true,
	gridWidth = true,
	limit = true,
	useLimit = true,
	 	subRegions = {},
		conditions = {},
		actions = {
			start = {
				glow_color = true,
				use_glow_color = true,
				glow_type = true,
				glow_lines = true,
				glow_length = true,
				glow_thickness = true,
				glow_frequency = true,
				sound = true,
				sound_channel = true,
		do_sound = true,
			},
		},
	config = true,

	preferToUpdate = true,
	source = true,
	tocversion = true,
	fsdate = true,
	sortHybridTable = true,
	controlledChildren = true,
	uid = true,
	authorMode = true,
	skipWagoUpdate = true,
	ignoreWagoUpdate = true,
	information = {
		saved = true,
	},
}

do
	local subregionKeep = {
	anchorXOffset = true,
	anchorYOffset = true,

	text_anchorPoint = true,
	text_anchorXOffset = true,
	text_anchorYOffset = true,
	text_automaticWidth = true,
		text_color = true,
	text_fixedWidth = true,
		text_font = true,
	text_fontSize = true,
	text_fontType = true,
	text_justify = true,
	text_selfPoint = true,
	text_shadowColor = true,
	text_shadowXOffset = true,
	text_shadowYOffset = true,
	text_visible = true,
	text_wordWrap = true,

	glow = true,
		glowBorder = true,
		glowColor = true,
	glowFrequency = true,
	glowLength = true,
		glowLines = true,
		glowScale = true,
		glowThickness = true,
		glowType = true,
	glowXOffset = true,
	glowYOffset = true,
		useGlowColor = true,

	border_color = true,
	border_edge = true,
	border_offset = true,
	border_size = true,
	border_visible = true,
	}

	local conditionKeep = {
		glow_color = true,
		use_glow_color = true,
		glow_type = true,
		glow_lines = true,
		glow_length = true,
		glow_thickness = true,
		glow_frequency = true,
		sound = true,
		sound_channel = true,
	[1] = true,
	[2] = true,
	[3] = true,
	[4] = true,
	}

	for i = 1, 10 do
		tinsert(fieldsToClear.subRegions, CopyTable(subregionKeep))
	local changes_template = {
		value = CopyTable(conditionKeep)
	}
	local changes = {}
	for j=1,10 do
		tinsert(changes,changes_template)
	end
		tinsert(fieldsToClear.conditions, {
		changes = changes
		})
	end
end

local function ClearFields(table,fields)
	for name,arg in next, fields do
		if type(arg) == "table" then
			if type(table[name])=="table" then
				ClearFields(table[name],arg)
			end
		elseif arg then
			table[name] = nil
		end
	end
end
local function ClearBools(table)
	for name,arg in next, table do
		if type(arg) == "table" then
			ClearBools(arg)
		elseif arg == false then
			table[name] = nil
		end
	end
end

function module:wa_clear(data)
	local data = MRT.F.table_copy2(data)

	ClearFields(data, fieldsToClear)
	ClearBools(data)

	return data
end


function module:SendReq2(ownList)
	if self.locked then return end
	self.locked = true
	MRT.F:AddCoroutine(function()
		local str = ""
		local c = 0
		if type(ownList) == "table" then
			for WA_name in next, ownList do
				local WA_data = WeakAurasSaved.displays[WA_name]
				str = str..WA_name.."''"..module:hash(MRT.F.table_to_string(module:wa_clear(WA_data))).."''"
				c = c + 1
			end
		else
			for WA_name,WA_data in next, WeakAurasSaved.displays do
				str = str..WA_name.."''"..module:hash(MRT.F.table_to_string(module:wa_clear(WA_data))).."''"
				c = c + 1

				if c % 10 == 0 then
					coroutine.yield()
				end
			end
		end
		str = str:gsub("''$","")

		self.locked = false

		if #str == 0 then
			return
		end

		local compressed = LibDeflate:CompressDeflate(str,{level = 7})
		local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
		encoded = encoded .. "##F##"
		local parts = ceil(#encoded / 245)

		for i=1,parts do
			local msg = encoded:sub( (i-1)*245+1 , i*245 )
			if i == 1 then
				MRT.F.SendExMsg("wac3", MRT.F.CreateAddonMsg("G","H",msg))
			else
				MRT.F.SendExMsg("wac3", MRT.F.CreateAddonMsg("G",msg))
			end
		end
	end)
end
--/run GExRT.F.table_to_string(GMRT.A.WAChecker:wa_clear(WeakAurasSaved.displays[]))

function module:SendResp2(reqTable)
	SendRespSch = nil

	if not WeakAurasSaved then
		MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("R","NOWA"))
		return
	end

	MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("Y","DATA",tostring(WeakAuras.versionString)))

	local reqTable = MRT.F.table_copy2(reqTable)
	MRT.F:AddCoroutine(function()
		local res = ""
		local c = 0
		for i,data in next, reqTable do
			local wa_name, wa_hash = data[1],data[2]
			c = c + 1

			local r = 0
			if WeakAurasSaved.displays[ wa_name ] then
				r = 1
				if wa_hash == tostring( module:hash(MRT.F.table_to_string(module:wa_clear(WeakAurasSaved.displays[ wa_name ]))) or "") then
					r = 2
				end
			end
			res = res .. r

			if c % 10 == 0 then
				coroutine.yield()
			end
		end

		if #res == 0 then return end

		local compressed = LibDeflate:CompressDeflate(res,{level = 7})
		local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
		encoded = encoded .. "#F#"
		local parts = ceil(#encoded / 245)

		for i=1,parts do
			local msg = encoded:sub( (i-1)*245+1 , i*245 )
			if i == 1 then
				MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("Y","H",msg))
			else
				MRT.F.SendExMsg("wachk", MRT.F.CreateAddonMsg("Y",msg))
			end
		end
	end)
end


local lastSenderTime,lastSender = 0

function module.main:ADDON_LOADED() -- doesn't work if module is registered from MRT, but will work if module is registered from this file
	module:RegisterAddonMessage()
end

local extra_resp_to_old = {
	[0] = 1,
	[1] = 5,
	[2] = 2,
}

function module:addonMessage(sender, prefix, prefix2, ...)
	if prefix == "wachk" then
		if prefix2 == "G" then
			local time = GetTime()
			if lastSender ~= sender and (time - lastSenderTime) < 1.5 then
				return
			end
			lastSender = sender
			lastSenderTime = time
			local str1, str2 = ...
			if str1 == "H" and str2 then
				wipe(module.db.lastReq)
				str1 = str2
			end
			if not str1 then
				return
			end

			while str1:find("''") do
				local wa_name,o = str1:match("^(.-)''(.*)$")

				module.db.lastReq[#module.db.lastReq + 1] = wa_name

				str1 = o
			end

			module.db.lastReq[#module.db.lastReq + 1] = str1

			if not SendRespSch then
				SendRespSch = C_Timer.NewTimer(1,module.SendResp)
			end
		elseif prefix2 == "R" then
			local str1, str2 = ...
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			if str1 == "NOWA" then
				module.db.responces[ sender ].noWA = true
				return
			elseif str1 == "DATA" then
				local _, wa_ver = ...
				module.db.responces[ sender ].wa_ver = wa_ver

				if module.options:IsVisible() and module.options.ScheduleUpdate then
					module.options.ScheduleUpdate()
				end
				return
			end
			local start = tonumber(str1 or "?")
			if not start then
				return
			end
			module.db.responces[ sender ].noWA = nil
			for j=2,select("#", ...) do
				local res = tonumber(select(j, ...),nil)

				for i=1,32 do
					if not module.db.lastReq[i + start] then
						break
					elseif bit.band(res,2^(i-1)) > 0 then
						module.db.responces[ sender ][ module.db.lastReq[i + start] ] = true
					else
						module.db.responces[ sender ][ module.db.lastReq[i + start] ] = false
					end
				end

				start = start + 32
			end

			if module.options:IsVisible() and module.options.ScheduleUpdate then
				module.options.ScheduleUpdate()
			end
		elseif prefix2 == "Y" then
			local str1, str2 = ...
			module.db.responces2[ sender ] = module.db.responces2[ sender ] or {}
			module.db.responces[ sender ] = module.db.responces[ sender ] or {}
			if str1 == "NOWA" then
				module.db.responces2[ sender ].noWA = true
				module.db.responces[ sender ].noWA = true
				return
			elseif str1 == "DATA" then
				local _, wa_ver = ...
				module.db.responces2[ sender ].wa_ver = wa_ver
				module.db.responces[ sender ].wa_ver = wa_ver

				if module.options:IsVisible() and module.options.UpdatePage then
					module.options.UpdatePage()
				end
				return
			end
			if ... == "H" then
				if not module.db.syncStr2 then
					module.db.syncStr2 = {}
				end
				module.db.syncStr2[ sender ] = ""
			end
			local str = table.concat({select(... == "H" and 2 or 1,...)}, "\t")

			module.db.syncStr2[ sender ] = (module.db.syncStr2[ sender ] or "") .. str
			if module.db.syncStr2[ sender ]:find("#F#$") then
				local str = module.db.syncStr2[ sender ]:sub(1,-4)
				module.db.syncStr2[ sender ] = nil

				local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
				local decompressed = LibDeflate:DecompressDeflate(decoded)

				local workingReq
				for j=#module.db.lastReq2,1,-1 do
					local lastReq = module.db.lastReq2[j]
					if type(lastReq)=="table" and #lastReq == #decompressed and not lastReq[sender] then
						workingReq = lastReq
						break
					end
				end
				if workingReq then
					workingReq[sender] = true
					for i=1,#decompressed do
						local r = tonumber( decompressed:sub(i,i),10 )
						module.db.responces2[ sender ][ workingReq[i][1] ] = r
						module.db.responces[ sender ][ workingReq[i][1] ] = extra_resp_to_old[r]
					end
				end
			end

			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage()
			end
		elseif prefix2 == "SWA" then
			local id, playername = ...

			if module.db.synqWAData[sender] then
				if WeakAurasSaved.displays[ id ] then
					local str = module.db.synqWAData[sender]:sub(7)
					local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
					if decoded then
						local decompressed = LibDeflate:DecompressDeflate(decoded)
						if decompressed then
							local LibSerialize = LibStub("LibSerialize")
							local success, deserialized = LibSerialize:Deserialize(decompressed)
							if success and deserialized.d then
								local hash1 = module:hash(MRT.F.table_to_string(module:wa_clear(deserialized.d)))
								local hash2 = module:hash(MRT.F.table_to_string(module:wa_clear(WeakAurasSaved.displays[ id ])))
								if hash1 == hash2 then
									-- print('aura is same')
									return
								end
							end
						end
					end
				end

				local link = "|Hgarrmission:weakauras|h|cFF8800FF["..playername.." |r|cFF8800FF- "..id.."]|h|r"
				SetItemRef("garrmission:weakauras",link)

				local Comm = LibStub:GetLibrary("AceComm-3.0")

				Comm.callbacks:Fire("WeakAuras", module.db.synqWAData[sender], "RAID", playername)
			end
		end
	elseif prefix == "wac2" then
		if prefix2 == "G" then
			local time = GetTime()
			if lastSender ~= sender and (time - lastSenderTime) < 1.5 then
				return
			end
			lastSender = sender
			lastSenderTime = time
			if ... == "H" then
				wipe(module.db.lastReq)
				module.db.syncStr = ""
			end

			local str = table.concat({select(... == "H" and 2 or 1,...)}, "\t")
			module.db.syncStr = module.db.syncStr or ""
			module.db.syncStr = module.db.syncStr .. str
			if module.db.syncStr:find("##F##$") then
				local str = module.db.syncStr:sub(1,-6)
				module.db.syncStr = nil

				local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
				local decompressed = LibDeflate:DecompressDeflate(decoded)

				while decompressed:find("''") do
					local wa_name,o = decompressed:match("^(.-)''(.*)$")

					module.db.lastReq[#module.db.lastReq + 1] = wa_name

					decompressed = o
				end

				module.db.lastReq[#module.db.lastReq + 1] = decompressed

				module:SendResp()
			end
		end
	elseif prefix == "wac3" then
		if prefix2 == "G" then
			if not sync_db.wac3_G_syncStr then sync_db.wac3_G_syncStr = {} end
			if not sync_db.wac3_G_senderToCount then sync_db.wac3_G_senderToCount = {} end
			if ... == "H" then
				sync_db.wac3_G_count = (sync_db.wac3_G_count or 0) + 1
				sync_db.wac3_G_senderToCount[sender] = sync_db.wac3_G_count
				module.db.lastReq2[sync_db.wac3_G_count] = {}
				sync_db.wac3_G_syncStr[sender] = ""
			end
			if not sync_db.wac3_G_senderToCount[sender] then
				return
			end

			local str = table.concat({select(... == "H" and 2 or 1,...)}, "\t")
			sync_db.wac3_G_syncStr[sender] = (sync_db.wac3_G_syncStr[sender] or "") .. str
			if sync_db.wac3_G_syncStr[sender]:find("##F##$") then
				local str = sync_db.wac3_G_syncStr[sender]:sub(1,-6)
				sync_db.wac3_G_syncStr[sender] = nil

				local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
				local decompressed = LibDeflate:DecompressDeflate(decoded)

				local c = sync_db.wac3_G_senderToCount[sender]
				local now_time = time()
				local pos = 1
				while true do
					local ns,ne = decompressed:find("''",pos)
					if not ns then break end
					local wa_name = decompressed:sub(pos,ns-1)
					local hs,he = decompressed:find("''",ne+1)
					if hs then hs = hs-1 end
					local wa_hash = decompressed:sub(ne+1,hs)

					module.db.lastReq2[c][#module.db.lastReq2[c] + 1] = {wa_name,wa_hash}
					module.db.lastCheck[wa_name] = now_time
					module.db.lastCheckName[wa_name] = sender
					if not he then break end
					pos = he + 1
				end

				C_Timer.After(60,function() module.db.lastReq2[c] = 0 end)	--kill outdated table
				module:SendResp2(module.db.lastReq2[c])
			end
		elseif prefix2 == "D" then
			if IsInRaid() and not MRT.F.IsPlayerRLorOfficer(sender) then
				return
			end
			local arg1 = ...

			local currMsg = table.concat({select(2,...)}, "\t")
			if tostring(arg1) == tostring(module.db.synqIndexWA[sender]) and type(module.db.synqTextWA[sender])=='string' then
				module.db.synqTextWA[sender] = module.db.synqTextWA[sender] .. currMsg
			else
				module.db.synqTextWA[sender] = currMsg
			end
			module.db.synqIndexWA[sender] = arg1

			if type(module.db.synqTextWA[sender])=='string' and module.db.synqTextWA[sender]:find("##F##$") then
				local str = module.db.synqTextWA[sender]:sub(1,-6)

				module.db.synqTextWA[sender] = nil
				module.db.synqIndexWA[sender] = nil
				module.db.synqWAData[sender] = str
			end
		end
	end
end

module.db.synqTextWA = {}
module.db.synqIndexWA = {}
module.db.synqWAData = {}

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
			Traverse(WeakAurasSaved.displays[child], true, includeGroups, includeLeafs)
		end
	end
end

local function TraverseAllCo(data)
	return Traverse(data, true, true, true)
end

local function TraverseAllChildrenCo(data)
	return Traverse(data, false, true, true)
end

local function TraverseAll(data)
	return coroutine.wrap(TraverseAllCo), data
end

local function TraverseAllChildren(data)
	return coroutine.wrap(TraverseAllChildrenCo), data
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

local function GenerateUniqueID()
	-- generates a unique random 11 digit number in base64
	local s = {}
	for i = 1, 11 do
		tinsert(s, bytetoB64[math.random(0, 63)])
	end
	return table.concat(s)
end

local function WA_DisplayToTable(id)
	local data = WeakAurasSaved.displays[id]
	if data then
		data.uid = data.uid or GenerateUniqueID()
		local transmit = {
			m = "d",
			d = data,
			s = WeakAuras.versionString,
			v = 2000,
		}
		if data.controlledChildren then
			transmit.c = {}
			local uids = {}
			local index = 1
			for child in TraverseAllChildren(data) do
				if child.uid then
					if uids[child.uid] then
						child.uid = GenerateUniqueID()
					else
						uids[child.uid] = true
					end
				else
					child.uid = GenerateUniqueID()
				end
				transmit.c[index] = child
				index = index + 1
			end
		end
		return transmit
	end
end

local function TableToString(t)
	local LibSerialize = LibStub("LibSerialize")

	local serialized = LibSerialize:SerializeEx({errorOnUnserializableType=false}, t)
	local compressed = LibDeflate:CompressDeflate(serialized, {level=5})
	local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
	return encoded
end

function module:SendWA_OG(id)
	local now = GetTime()
	if module.db.prevSendWA and now - module.db.prevSendWA < 1 then
		return
	end
	module.db.prevSendWA = now

	local name, realm = UnitFullName("player")
	local fullName = name.."-"..realm

	local encoded = "!WA:2!"..TableToString(WA_DisplayToTable(id))

	encoded = encoded .. "##F##"

	local newIndex = math.random(100,999)
	while module.db.synqPrevIndex == newIndex do
		newIndex = math.random(100,999)
	end
	module.db.synqPrevIndex = newIndex

	newIndex = tostring(newIndex)
	local parts = ceil(#encoded / 244)
	for i=1,parts do
		local msg = encoded:sub( (i-1)*244+1 , i*244 )
		local progress = i

		local opt = {
			maxPer5Sec = 50,
		}
		if i==parts then
			opt.ondone = function() print(id,'sended') end
		elseif parts > 50 then
			if i%20 == 0 then
				opt.ondone = function() print(id,'sending',progress.."/"..parts) end
			end
		end
		MRT.F.SendExMsgExt(opt,"wac3","D\t"..newIndex.."\t"..msg)
	end
	MRT.F.SendExMsgExt({maxPer5Sec = 50},"wachk", "SWA\t"..id.."\t"..fullName)
end
