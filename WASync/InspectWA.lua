local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

---@class ELib
local ELib,L = MRT.lib,MRT.L

---@class Locale
local LR = AddonDB.LR

---@class MLib
local MLib = AddonDB.MLib

---@class WASyncPrivate
local WASync = AddonDB.WASYNC

local prettyPrint = module.prettyPrint
local WASYNC_ERROR = module.WASYNC_ERROR

local function MergeWAMap(oldMap, newMap)
	for k, v in next, newMap do
		if type(v) == "table" then
			if not oldMap[k] then
				oldMap[k] = {}
			end
			MergeWAMap(oldMap[k], v)
		else
			oldMap[k] = v
		end
	end
end

function module.options:InitializeInspect()

	local inspectFrame = ELib:Popup("|cFF8855FFWeakAuras Sync Inspector|r"):Size(620,546)
	module.inspectFrame = inspectFrame
	inspectFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)
	inspectFrame.border:Hide()
	ELib:Border(inspectFrame,1,.24,.25,.30,1,nil,3)

	inspectFrame.Name = ELib:Text(inspectFrame,"",16):Size(380,20):Point("TOPLEFT",inspectFrame,"TOPLEFT",5,-60):Color():Shadow()

	inspectFrame.depthNum = 0
	inspectFrame.depth = ELib:Edit(inspectFrame):Size(40,20):Tooltip("Depth"):Point("TOPRIGHT",inspectFrame,"TOPRIGHT",-5,-35):OnChange(function(self)
		local depth = tonumber(self:GetText())
		if depth then
			inspectFrame.depthNum = depth
		end
		self:SetText(inspectFrame.depthNum)
	end)
	inspectFrame.depth:SetText(inspectFrame.depthNum)
	inspectFrame.depth:SetNumeric(true)

	inspectFrame.requestButton = MLib:Button(inspectFrame,"Inspect"):Size(100,20):Point("RIGHT",inspectFrame.depth,"LEFT",-5,0):OnClick(function(self)
		module:RequestWAMap(inspectFrame.selected,"",inspectFrame.depthNum)
	end)

	inspectFrame.resetButton = MLib:Button(inspectFrame,"Reset"):Size(100,20):Point("RIGHT",inspectFrame.requestButton,"LEFT",-5,0):OnClick(function(self)
		if inspectFrame.selected then
			module.db.inspectData[inspectFrame.selected] = nil

			inspectFrame:UpdateData()
		end
	end)

	if AddonDB.DoImports and AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender("player") then
		inspectFrame.forceAutoImportButton = MLib:Button(inspectFrame,"Trigger AutoImport"):Size(120,20):Point("RIGHT",inspectFrame.resetButton,"LEFT",-5,0):OnClick(function(self)
			if inspectFrame.selected then
				module:ForceAutoImport(inspectFrame.selected)
			end
		end)
	end

	inspectFrame.searchEdit = ELib:Edit(inspectFrame):Size(250,20):Point("TOPRIGHT",inspectFrame,"TOPRIGHT",-5,-60):AddSearchIcon():Tooltip(SEARCH):OnChange(function(self,isUser)
		if not isUser then
			return
		end

		local text = self:GetText():lower()
		if text == "" then
			text = nil
			self:BackgroundText(SEARCH)
		else
			self:BackgroundText("")
		end
		inspectFrame.search = text

		if self.scheduledUpdate then
			return
		end
		self.scheduledUpdate = C_Timer.NewTimer(.1,function()
			self.scheduledUpdate = nil
			inspectFrame.scrollList.ScrollBar.slider:SetValue(0)
			inspectFrame:UpdateData()
		end)
	end)
	inspectFrame.searchEdit:BackgroundText(SEARCH)
	inspectFrame.searchEdit:SetTextColor(0,1,0,1)

	inspectFrame.scrollList = ELib:ScrollButtonsList(inspectFrame):Size(610,450):Point("BOTTOM",inspectFrame,"BOTTOM",0,5)
	inspectFrame.scrollList.ButtonsInLine = 1
	inspectFrame.scrollList.mouseWheelRange = 50
	ELib:Border(inspectFrame.scrollList,0)
	ELib:Border(inspectFrame.scrollList,1,.24,.25,.30,1,nil,3)

	inspectFrame.scrollList.expandState2 = {}
	function inspectFrame.scrollList:ButtonClick(button) -- level 2 click
		local data = self.data
		if not data then
			return
		end
		if button == "RightButton" then
			MenuUtil.CreateContextMenu(self, function(ownerRegion,rootDescription, id)
				rootDescription:CreateTitle(id)
				local b1 = rootDescription:CreateButton(LR["Request WA"], function(id)
					module:RequestWA(id, inspectFrame.selected)
					return MenuResponse.CloseAll
				end, id)
				if AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender("player") then
					local loadNeverButton = rootDescription:CreateButton(LR["Set Load Never"])
					loadNeverButton:CreateButton("|cffff0000true|r", function(id)
						module:SendSetLoadNever(id, inspectFrame.selected, true)
						return MenuResponse.CloseAll
					end,id)
					loadNeverButton:CreateButton("|cff00ff00false|r", function(id)
						module:SendSetLoadNever(id, inspectFrame.selected, false)
						return MenuResponse.CloseAll
					end,id)
					local deleteButton = rootDescription:CreateButton(LR["Archive and Delete"], function(id)
						module:SendDeleteWA(id, inspectFrame.selected)
						return MenuResponse.CloseAll
					end, id)
					local editButton = rootDescription:CreateButton(LR["Edit"], function(id)
						module:RequestDisplayTable(id, inspectFrame.selected)
						return MenuResponse.CloseAll
					end, id)
					local requestDebugLogButton = rootDescription:CreateButton(LR["Get DebugLog"], function(id)
						module:RequestDebugLog(id, inspectFrame.selected)
						return MenuResponse.CloseAll
					end, id)
				end
			end, data.uid)
		elseif button == "LeftButton" then
			if data.isGroup then
				local uid = data.uid
				inspectFrame.scrollList.expandState2[uid] = not inspectFrame.scrollList.expandState2[uid]
				inspectFrame:UpdateData()
			end
		end
	end

	local function Button_OnLeave(self)
		GameTooltip_Hide()
	end

	local function Button_OnEnter(self)
		if self:GetTextObj():IsTruncated() then
			GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
			GameTooltip:AddLine(self:GetTextObj():GetText():trim())
			GameTooltip:Show()
		end
	end

	local function lineStyledButton(parent,text)
		local button = ELib:Button(parent,text)
		button.Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button.DisabledTexture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button:GetFontString():SetFont(GameFontNormal:GetFont(), 12,"")
		button.BorderLeft:Hide()
		button.BorderRight:Hide()
		button.BorderTop:Hide()
		button.BorderBottom:Hide()
		return button
	end

	local function Lvl2_Request(self)
		inspectFrame.scrollList.expandState2[self:GetParent().data.uid] = true
		module:RequestWAMap(inspectFrame.selected,self:GetParent().data.uid,max(inspectFrame.depthNum,1))
	end

	function inspectFrame.scrollList:ModButton(button,level)
		if level == 1 then
		button.Texture:SetGradient("HORIZONTAL",CreateColor(.17,.17,.17,1), CreateColor(.17,.17,.17,1))

		elseif level == 2 then
			local textObj = button:GetTextObj()
			textObj:SetPoint("LEFT",button,"LEFT",23,0)
			textObj:SetPoint("RIGHT",button,"LEFT",450,0)

			button.requestButton = lineStyledButton(button,"Inspect"):Size(80,20):Point("RIGHT",button,"RIGHT",-5,0):OnClick(Lvl2_Request)
			button.expandIcon = ELib:Icon(button,"Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128",18):Point("LEFT",5,0)


			button:SetScript("OnEnter",Button_OnEnter)
			button:SetScript("OnLeave",Button_OnLeave)

			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		end
	end

	local COLOR_SINGLE1 = CreateColor(.1,.5,1,.35)
	local COLOR_SINGLE2 = CreateColor(.1,.5,1,.6)

	local COLOR_GROUP1 = CreateColor(.5,.5,1,.35)
	local COLOR_GROUP2 = CreateColor(.5,.5,1,.6)
	local COLOR_GROUP_EMPTY = CreateColor(.2,.2,.2,.35)

	local COLOR_USE_NEVER1 = CreateColor(1,.3,.3,.35)
	local COLOR_USE_NEVER2 = CreateColor(1,.3,.3,.6)

	function inspectFrame.scrollList:ModButtonUpdate(button, level)
		if level == 1 then

		elseif level == 2 then
			local text = button:GetTextObj()
			text:SetWordWrap(false)

			local data = button.data
			local offset = data.depth * 7

			text:SetPoint("LEFT", 23 + offset, 0)

			if data.isGroup then
				button.requestButton:Show()
				button.expandIcon:Show()
				button.expandIcon:Point("LEFT", offset, 0)

				if data.isExpanded then
					button.expandIcon.texture:SetTexCoord(0.25, 0.3125, 0.5, 0.625)
				else
					button.expandIcon.texture:SetTexCoord(0.375, 0.4375, 0.5, 0.625)
				end
			else
				button.requestButton:Hide()
				button.expandIcon:Hide()
			end

			if data.isGroup then
				if data.size > 0 then
					button.Texture:SetGradient("HORIZONTAL", COLOR_GROUP1, COLOR_GROUP2)
				else
					button.Texture:SetGradient("HORIZONTAL", COLOR_GROUP1, COLOR_GROUP_EMPTY)
				end
			elseif data.use_never then
				button.Texture:SetGradient("HORIZONTAL", COLOR_USE_NEVER1, COLOR_USE_NEVER2)
			else
				button.Texture:SetGradient("HORIZONTAL", COLOR_SINGLE1, COLOR_SINGLE2)
			end
		end
	end

	function inspectFrame:UpdateData()
		local Mdata = {}
		if not inspectFrame.selected then return end

		inspectFrame.Name:SetText(AddonDB:ClassColorName(Ambiguate(inspectFrame.selected,"none")))


		local db = module.db.inspectData[inspectFrame.selected or ""] or not IsInGroup() and module.db.inspectData[MRT.F.delUnitNameServer(inspectFrame.selected)] or {}

		if not db then
			inspectFrame.scrollList.data = {}
			inspectFrame.scrollList:Update(true)
			return
		end

		for id, entry in next, db do
			local tableToAdd = {
				name = id,
				uid = id,
				data = {},
				entry = entry,
			}
			Mdata[#Mdata+1] = tableToAdd

			local function traverse(id, entry, depth)
				local prefix = depth > 0 and false and ("   "):rep(depth) or "" .. "- " or ""
				local size = type(entry) == "table" and CountTable(entry) or nil
				tableToAdd.data[#tableToAdd.data+1] = {
					name = prefix .. id .. (size and ( " (" .. (size or "0") .. ")") or ""),
					uid = id,
					depth = depth,
					use_never = entry == false,
					isGroup = type(entry) == "table",
					isExpanded = inspectFrame.scrollList.expandState2[id],
					size = size,
				}

				if type(entry) == "table" then
					for id, entry in next, entry do
						traverse(id, entry, depth + 1)
					end
				end
			end
			traverse(id, entry, 0)

			if inspectFrame.search then
				local newTableToAdd = {}
				local i = 1
				local total = #tableToAdd.data
				while i <= total do
					if tableToAdd.data[i].name:lower():find(inspectFrame.search,1,true) then
						newTableToAdd[#newTableToAdd+1] = tableToAdd.data[i]
						if tableToAdd.data[i].isGroup then
						local pass = tableToAdd.data[i].depth
							while tableToAdd.data[i+1] and (pass < tableToAdd.data[i+1].depth) do
								i = i + 1
								newTableToAdd[#newTableToAdd+1] = tableToAdd.data[i]
							end
						end
					end
					i = i + 1
				end
				tableToAdd.data = newTableToAdd
			end


			-- iterate over tableToAdd.data and remove following groups if they are not expanded
			local i = 1
			local total = #tableToAdd.data
			while i <= total do
				if tableToAdd.data[i].isGroup then
					local pass = tableToAdd.data[i].depth
					if not tableToAdd.data[i].isExpanded then
						while tableToAdd.data[i+1] and (pass < tableToAdd.data[i+1].depth) do
							-- tableToAdd.data[i+1] = nil
							-- i = i + 1
							tremove(tableToAdd.data,i+1)
							total = total - 1
						end
					end
				end
				i = i + 1
			end


			if #tableToAdd.data == 0 then
				Mdata[#Mdata] = nil
			end
		end

		sort(Mdata,function(a,b)
			return a.name < b.name
		end)
		inspectFrame.scrollList.data = Mdata
		inspectFrame.scrollList:Update(true)
	end

	inspectFrame:UpdateData()
	inspectFrame:SetScript("OnShow",function()
		inspectFrame:UpdateData()
	end)

	function inspectFrame:SetNewPlayer(name)
		name = AddonDB:GetFullName(name, true)
		inspectFrame.selected = name
		inspectFrame.scrollList.expandState2 = {}
		inspectFrame.scrollList.stateExpand = {}
		inspectFrame:UpdateData()
		inspectFrame:Show()
	end
end



local map
local seen
local levels

local function build(d, maxDepth, toplevel)
	if toplevel then
		map[d.id] = d.controlledChildren and {} or true
		seen[d.id] = map[d.id]
		levels[d.id] = 0
	else
		local entry = seen[d.parent]
		if entry and levels[d.parent] < maxDepth then
			if d.controlledChildren then
				entry[d.id] = {}
			elseif d.load and d.load.use_never then
				entry[d.id] = false
			else
				entry[d.id] = true
			end
			seen[d.id] = entry[d.id]
			levels[d.id] = levels[d.parent] + 1
		end
	end
end

local function buildall(d, maxDepth, toplevel)
	build(d, maxDepth, toplevel)
	-- seen[d.id] = true
	if d.controlledChildren then
		for _, child in ipairs(d.controlledChildren) do
			buildall(WeakAuras.GetData(child), maxDepth)
		end
	end
end

-- args are relevant
local function BuildWAMap(parent, maxDepth)
	maxDepth = maxDepth or 999

	map = {}
	seen = {}
	levels = {}

	parent = WeakAuras.GetData(parent)

	if parent then
		buildall(parent, maxDepth, true)
		for d in module.pTraverseParents(parent) do
			map = { [d.id] = map }
		end

		return map
	end
end

local function BuildFullWAMap(maxDepth)
	maxDepth = maxDepth or 999

	map = {}
	seen = {}
	levels = {}

	for _, data in next, WeakAurasSaved.displays do
		if not data.parent then
			if coroutine.running() then
				coroutine.yield()
			end

			buildall(data, maxDepth, true)
		end
	end
	return map
end


function module:RequestWAMap(receiver, parent, maxDepth)
	parent = parent or ""
	local isPass, reason = AddonDB:CheckSelfPermissions(WASync.isDebugMode)
	if isPass then
		AddonDB:SendComm("WAS_INS_REQ", AddonDB:CreateHeader(parent, maxDepth), "WHISPER", receiver)
	else
		prettyPrint(WASYNC_ERROR, reason)
	end
end

AddonDB:RegisterComm("WAS_INS_REQ", function(prefix, sender, data, channel, key) -- WHISPER
	if channel ~= "WHISPER" then return end
	sender = AddonDB:GetFullName(sender, true)

	local isPass, reason = AddonDB:CheckSenderPermissions(sender, true)
	if not isPass then
		return
	end
	local parent, maxDepth = AddonDB:ParseHeader(data)

	-- if InCombatLockdown() then
	-- 	module:ErrorComms(sender, 3)
	-- 	return
	-- end

	if parent == "" then parent = nil end
	maxDepth = tonumber(maxDepth or "?") or 0
	prettyPrint(sender, "requested WA map:", parent or "Full Map","| depth:", maxDepth)

	module:SendWAMap(sender, parent, maxDepth)
end)

do
	local sendConfig = {
		maxPer5Sec = 50,
	}

	module.SendWAMap = AddonDB:WrapAsyncSingleton(function(self, sender, parent, maxDepth)
		local map
		if parent then
			map = BuildWAMap(parent, maxDepth)
		else
			map = BuildFullWAMap(maxDepth)
		end
		if not map then
			prettyPrint(WASYNC_ERROR, "Error building map for", parent)
			return
		end

		local header = AddonDB:CreateHeader(WASync.WAMAP_VERSION)
		local encoded = AddonDB:CompressTable(map)

		local commsMessage = AddonDB:CreateHeaderCommsMessage(header, encoded)
		AddonDB:SendComm("WAS_INS", commsMessage, "WHISPER", sender, nil, nil, sendConfig)
	end)
end

AddonDB:RegisterComm("WAS_INS", function(prefix, sender, data, channel, key)
	if channel ~= "WHISPER" then return end
	sender = AddonDB:GetFullName(sender, true)

	local header, body = AddonDB:SplitHeaderAndMain(data)
	local version = AddonDB:ParseHeader(header)

	-- version check
	if tonumber(version or "?") ~= WASync.WAMAP_VERSION then
		if tonumber(version or "0") > WASync.WAMAP_VERSION then
			prettyPrint(WASYNC_ERROR, ("Your WeakAuras Sync version is outdated (sender ver.%s, your addon(wa map) ver.%s)"):format(version or "unk", WASync.WAMAP_VERSION))
		else
			prettyPrint(WASYNC_ERROR, ("Import data is outdated (sender ver.%s, your addon(wa map) ver.%s)"):format(version or "unk", WASync.WAMAP_VERSION))
		end
		return
	end

	local decodedMap, error = AddonDB:DecompressTable(body)
	if not decodedMap then
		prettyPrint(WASYNC_ERROR, "Error decompressing map", error)
		return
	end

	module.db.inspectData[sender] = module.db.inspectData[sender] or {}
	MergeWAMap(module.db.inspectData[sender], decodedMap)

	if module.inspectFrame and module.inspectFrame:IsVisible() then
		module.inspectFrame:UpdateData()
	end
end)


