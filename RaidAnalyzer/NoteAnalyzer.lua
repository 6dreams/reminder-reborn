local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ELib
local ELib, L = MRT.lib, MRT.L
---@class MLib
local MLib = AddonDB.MLib
---@class Locale
local LR = AddonDB.LR
local VMRT = nil

---@class RaidAnalyzer: MRTmodule
local parentModule = MRT.A.RaidAnalyzer
if not parentModule then return end

---@class NoteAnalyzer: MRTmodule
local module = AddonDB:New("NoteAnalyzer",nil,true)
if not module then return end

local IsFormattingOn = true
local CurrentUnformatedText = ""
local GroupToCount = 4
local ReplaceOnlySelected = true

local RealClassColors = {
	--INNER MRT COLORCODES
	["||cffc69b6d"] = true,
	["||cfff48cba"] = true,
	["||cffaad372"] = true,
	["||cfffff468"] = true,
	["||cffffffff"] = true,
	["||cffc41e3a"] = true,
	["||cff0070dd"] = true,
	["||cff3fc7eb"] = true,
	["||cff8788ee"] = true,
	["||cff00ff98"] = true,
	["||cffff7c0a"] = true,
	["||cffa330c9"] = true,
	["||cff33937f"] = true,
	--VISERIO COLOROCDES
	["||cffc31d39"] = true,
	["||cffa22fc8"] = true,
	["||cfffe7b09"] = true,
	["||cff3ec6ea"] = true,
	["||cff00fe97"] = true,
	["||cfff38bb9"] = true,
	["||cfffefefe"] = true,
	["||cfff0ead6"] = true,
	["||cffffff00"] = true,
	["||cfffef367"] = true,
	["||cff006fdc"] = true,
	["||cff8687ed"] = true,
	["||cffc59a6c"] = true,
	["||cffa9d271"] = true,
	--CLASSIC COLORCODES
	["||cffc79c6e"] = true, -- WARRIOR
	["||cff9797ed"] = true, -- WARLOCK
	["||cff0070de"] = true, -- SHAMAN
	["||cfffff569"] = true, -- ROGUE
	["||cfff58cba"] = true, -- PALADIN
	["||cff00ff96"] = true, -- MONK??
	["||cff40c7eb"] = true, -- MAGE
	["||cffabd473"] = true, -- HUNTER
	["||cffff7d0a"] = true, -- DRUID
	["||cffc41f3b"] = true, -- DEATHKNIGHT
}

local PAT_SEP = AddonDB.STRING_PATTERNS.PAT_SEP
local PAT_SEP_CAPTURE = AddonDB.STRING_PATTERNS.PAT_SEP_CAPTURE
local PAT_SEP_INVERSE = AddonDB.STRING_PATTERNS.PAT_SEP_INVERSE

local function NoteAnalyzerInit()

	local NoteAnalyzer = parentModule.options:NewPage("Note Analyzer")
	local self = NoteAnalyzer
	module.opts = self

	self.NoteEditBox = ELib:MultiEdit(self):Point("BOTTOMRIGHT", self, "BOTTOMRIGHT", -5, 35):Size(616, 370)
	ELib:Border(self.NoteEditBox, 0, .24, .25, .30, 1)

	--NoteEditBox lines
	ELib:DecorationLine(self.NoteEditBox):Point("TOPLEFT", -1, 1):Point("BOTTOMLEFT", self, "BOTTOM", 0, 0):Size(1, 0)
	ELib:DecorationLine(self.NoteEditBox):Point("TOPLEFT", -1, 1):Point("TOPRIGHT", self, "RIGHT", 0, 0):Size(0, 1)

	--RaidNames lines
	ELib:DecorationLine(self):Point("TOPLEFT", self, "TOPLEFT", 0, -80):Point("TOPRIGHT", self, "TOPRIGHT",0, -80):Size(0, 1)
	ELib:DecorationLine(self):Point("TOPLEFT", self, "TOPLEFT", 0, -155):Point("TOPRIGHT", self, "TOPRIGHT",0, -155):Size(0, 1)


	self.NoteEditBox.EditBox._SetText = self.NoteEditBox.EditBox.SetText
	function self.NoteEditBox.EditBox:SetText(text)
		if IsFormattingOn then
			--wipe(IconsFormattingList)
			text = text:gsub("||([cr])", "|%1")
			--:gsub("({spell:(%d+):?(%d*)})",GSUB_Icon_Options)
		end
		return self:_SetText(text)
	end

	local function UpdateText(changed)
		local text = CurrentUnformatedText
		local h_start, h_end = self.NoteEditBox:GetTextHighlight()
		local pos = self.NoteEditBox.EditBox:GetCursorPosition()


		self.NoteEditBox.EditBox:SetText(text)
		self.NoteEditBox.EditBox:SetCursorPosition(pos)
		if h_start ~= h_end then
			self.NoteEditBox.EditBox:HighlightText(h_start, h_end + (changed or 0))
		end
	end

	function self.NoteEditBox.EditBox:OnTextChanged(isUser)
		if not isUser and (not NoteAnalyzer.InsertFix or GetTime() - NoteAnalyzer.InsertFix > 0.1) then
			return
		end
		local text = self:GetText()
		-- CurrentUnformatedText = text
		if IsFormattingOn then
			text = text:gsub("|([cr])", "||%1")
		end
		CurrentUnformatedText = text
		-- print("OnTextChanged")
	end

	-- local last_highlight_start,last_highlight_end,last_cursor_pos = 0,0,0
	local IsFormattingOn_Saved
	self.NoteEditBox.EditBox:SetScript("OnKeyDown", function(self, key)
		if IsFormattingOn and key == "LCTRL" then
			NoteAnalyzer.InsertFix = nil
			IsFormattingOn_Saved = true
			IsFormattingOn = false
			local h_start, h_end = NoteAnalyzer.NoteEditBox:GetTextHighlight()
			local h_cursor = self:GetCursorPosition()
			local text = NoteAnalyzer.NoteEditBox.EditBox:GetText()

			-- last_highlight_start,last_highlight_end,last_cursor_pos = h_start,h_end,h_cursor

			local c_start, c_end, c_cursor = 0, 0, 0
			text:sub(1, h_start):gsub("|([cr])", function() c_start = c_start + 1 end)
			text:sub(1, h_end):gsub("|([cr])", function() c_end = c_end + 1 end)
			text:sub(1, h_cursor):gsub("|([cr])", function() c_cursor = c_cursor + 1 end)

			text = text:gsub("|([cr])", "||%1")
			NoteAnalyzer.NoteEditBox.EditBox:_SetText(text)

			NoteAnalyzer.NoteEditBox.EditBox:HighlightText(h_start + c_start, h_end + c_end)
			NoteAnalyzer.NoteEditBox.EditBox:SetCursorPosition(h_cursor + c_cursor)
		end
	end)

	self.NoteEditBox.EditBox:SetScript("OnKeyUp", function(self, key)
		if IsFormattingOn_Saved and key == "LCTRL" then
			local text = NoteAnalyzer.NoteEditBox.EditBox:GetText()
			local h_start, h_end = NoteAnalyzer.NoteEditBox:GetTextHighlight()
			local h_cursor = self:GetCursorPosition()
			local c_start, c_end, c_cursor = 0, 0, 0
			text:sub(1, h_start):gsub("||([cr])", function() c_start = c_start + 1 end)
			text:sub(1, h_end):gsub("||([cr])", function() c_end = c_end + 1 end)
			text:sub(1, h_cursor):gsub("||([cr])", function() c_cursor = c_cursor + 1 end)

			IsFormattingOn = true
			IsFormattingOn_Saved = nil
			NoteAnalyzer.InsertFix = nil
			UpdateText()
			NoteAnalyzer.NoteEditBox.EditBox:HighlightText(h_start - c_start, h_end - c_end)
			NoteAnalyzer.NoteEditBox.EditBox:SetCursorPosition(h_cursor - c_cursor)
		end
	end)

	local function AddTextToEditBox(self, text, mypos, noremove)
		local addedText = nil
		if not self then
			addedText = text
		else
			addedText = self.iconTextShift .. " "
			-- if IsShiftKeyDown() then
			-- addedText = self.iconTextShift
			-- end
		end
		if not noremove then
			NoteAnalyzer.NoteEditBox.EditBox:Insert("")
		end
		local txt = NoteAnalyzer.NoteEditBox.EditBox:GetText()
		local pos = NoteAnalyzer.NoteEditBox.EditBox:GetCursorPosition()
		if not self and type(mypos) == 'number' then
			pos = mypos
		end
		txt = string.sub(txt, 1, pos) .. addedText .. string.sub(txt, pos + 1)
		NoteAnalyzer.InsertFix = GetTime()
		NoteAnalyzer.NoteEditBox.EditBox:SetText(txt)
		local adjust = 0
		if IsFormattingOn then
			addedText:gsub("||", function() adjust = adjust + 1 end)
		end
		NoteAnalyzer.NoteEditBox.EditBox:SetCursorPosition(pos + addedText:len() - adjust)
	end

	local function Analyze(old)
		local text
		if old then
			text = self.analyzedText
		else
			local h_start, h_end = NoteAnalyzer.NoteEditBox:GetTextHighlight()

			text = NoteAnalyzer.NoteEditBox.EditBox:GetText()
			if not (h_start == h_end and not ReplaceOnlySelected) then
				text = text:sub(h_start, h_end)
			end
		end

		if IsFormattingOn and not old then -- if old then we already have unformatted text
			text = text:gsub("|([cr])", "||%1")
		end

		self.analyzedText = text


		self.lastSelected = nil

		local playersInNote = {}
		local playersRepeated = {}
		local AnyRepeated = false

		local InRaidNotAssigned = {}
		local AssignedNotInRaid = {}


		local namesCount = 0
		for name in string.gmatch(text, PAT_SEP_INVERSE) do
			if name:match(":") then
				name = strsplit(":", name, 1)
			end
			local isName = true

			local nameClear = name:gsub("(||c%x%x%x%x%x%x%x%x)([^|]+)||r", function(colorCode, cleanName)
				if not RealClassColors[colorCode:lower()] then
					isName = false
				end
				-- print(format("colorCode: %q, cleanName: %q, isName: %s", colorCode, cleanName, tostring(isName)))

				return cleanName or ""
			end):gsub("|r", ""):gsub("|", "")

			if isName and
				(
					(VMRT.NoteChecker.allowNumbers or not nameClear:match("%d")) and
					(VMRT.NoteChecker.allowNonLetterSymbols or not nameClear:match("[%'%-\"%{%}:%(%)%+%[%]]")) and
					(VMRT.NoteChecker.allowHashtag or not nameClear:match("#"))
				) and
				not nameClear:match("^%l")
			then
				namesCount = namesCount + 1
				nameClear = nameClear:gsub("[%d%'%#%-\"%{%}:]", "")
				if not playersInNote[nameClear] then
					playersInNote[nameClear] = name:gsub("||([cr])", "|%1") -- this is used only to display name in the list, so we format it back
				else
					playersRepeated[nameClear] = (playersRepeated[nameClear] or 1) + 1
					AnyRepeated = true
				end
			end
		end

		NoteAnalyzer.totalPlayers:SetText("Total names in analyzed text: " .. namesCount)
		local repPlayersText = AnyRepeated and "|cffee5555Repeated players:|r\n" or "Repeated players:\n"

		for k, v in next, playersRepeated do
			repPlayersText = repPlayersText .. k .. " - " .. v .. "\n"
		end
		NoteAnalyzer.repeatedPlayers:SetText(repPlayersText)

		for unit in AddonDB:IterateGroupMembers(GroupToCount) do
			local name = UnitName(unit)
			if playersInNote[name] then
				playersInNote[name] = nil
			else
				InRaidNotAssigned[name] = true
				playersInNote[name] = nil
			end
		end

		for name, nameColored in next, playersInNote do
			AssignedNotInRaid[name] = nameColored
		end

		for i = 1, 40 do
			local obj = NoteAnalyzer.raidnames1[i]
			if not obj then return end

			obj.iconText = ""
			obj.iconTextShift = ""
			obj.html:SetText("")
		end

		local index1 = 0
		for name in next, InRaidNotAssigned do
			index1 = index1 + 1
			local coloredName = AddonDB:ClassColorName(name)

			local obj = NoteAnalyzer.raidnames1[index1]
			if not obj then return end

			obj.iconText = name
			obj.iconTextShift = coloredName:gsub("|","||")
			obj.html:SetText(coloredName)
		end


		for i = 1, 40 do
			local obj = NoteAnalyzer.raidnames2[i]
			if not obj then return end

			obj.iconText = ""
			obj.iconTextShift = ""
			obj.html:SetText("")
		end

		local index2 = 0
		for name, nameColored in next, AssignedNotInRaid do
			index2 = index2 + 1
			local obj = NoteAnalyzer.raidnames2[index2]
			if not obj then return end
			obj.iconText = nameColored
			if name == "" then -- workaround for - symbol
				obj.iconTextShift = nameColored
			else
				obj.iconTextShift = name
			end
			obj.html:SetText(nameColored)
		end
	end

	local function RaidNamesOnEnter(self)
		self.html:SetShadowColor(0.2, 0.2, 0.2, 1)
	end
	local function RaidNamesOnLeave(self)
		self.html:SetShadowColor(0, 0, 0, 1)
	end

	local function ReplaceName(text, nameToFind, nameToReplace)
		text = "\n" .. text .. "\n"
		local total_count, c = 0
		for pat in gmatch(text, PAT_SEP .. "(%||c%x%x%x%x%x%x%x%x" .. nameToFind .. "||r)" .. PAT_SEP) do
			text, c = text:gsub(PAT_SEP_CAPTURE .. pat .. PAT_SEP_CAPTURE, "%1" .. nameToReplace .. "%2")
			total_count = total_count + c
		end
		text, c = text:gsub(PAT_SEP_CAPTURE .. nameToFind .. PAT_SEP_CAPTURE, "%1" .. nameToReplace .. "%2")
		-- fix for case when 2 names are one after another and the second one is not replaced
		text, c = text:gsub(PAT_SEP_CAPTURE .. nameToFind .. PAT_SEP_CAPTURE, "%1" .. nameToReplace .. "%2")
		total_count = total_count + c

		text = text:gsub("^\n", ""):gsub("\n$", "")

		return text, total_count
	end

	local function SubSelected(self2)
		if self2.iconText == "" then return end

		if IsShiftKeyDown() and self2 and self2.iconTextShift ~= "" then -- if shift is pressed insert directly
			AddTextToEditBox(self2)
			return
		end

		if not self.lastSelected or self.lastSelected.iconText == "" then -- if obj have text and shift not pressed
			return
		end

		-- formatting on: |cff000000123|r
		-- formatting off: ||cff000000123||r

		local pos = NoteAnalyzer.NoteEditBox.EditBox:GetCursorPosition()
		local oldSize, newSize, changed

		if ReplaceOnlySelected then
			local h_start, h_end = NoteAnalyzer.NoteEditBox:GetTextHighlight()
			local EditBoxText = NoteAnalyzer.NoteEditBox.EditBox:GetText()

			local textOld1 = EditBoxText:sub(0, max(h_start - 1, 0))
			local text = EditBoxText:sub(h_start, h_end)
			local textOld2 = EditBoxText:sub(h_end + 1, -1)

			if IsFormattingOn then
				textOld1 = textOld1:gsub("|([cr])", "||%1")
				text = text:gsub("|([cr])", "||%1")
				textOld2 = textOld2:gsub("|([cr])", "||%1")
			end

			oldSize = #text:gsub("||([cr])", "|%1") -- check size for formatted text

			text = ReplaceName(text, self.lastSelected.iconTextShift, self2.iconTextShift)

			newSize = #text:gsub("||([cr])", "|%1") -- check size for formatted text

			changed = newSize - oldSize
			CurrentUnformatedText = textOld1 .. text .. textOld2

			self.analyzedText = text
		else
			local text = NoteAnalyzer.NoteEditBox.EditBox:GetText()

			if IsFormattingOn then
				text = text:gsub("|([cr])", "||%1")
			end

			text = ReplaceName(text, self.lastSelected.iconTextShift, self2.iconTextShift)

			oldSize = #self.analyzedText:gsub("||([cr])", "|%1") -- check size for formatted text

			-- this is needed to update analyzed info
			self.analyzedText = ReplaceName(self.analyzedText, self.lastSelected.iconTextShift, self2.iconTextShift)

			newSize = #self.analyzedText:gsub("||([cr])", "|%1") -- check size for formatted text
			changed = newSize - oldSize

			CurrentUnformatedText = text
		end

		UpdateText(changed)
		NoteAnalyzer.NoteEditBox.EditBox:SetCursorPosition(pos)

		self.lastSelected.html:SetText(self.lastSelected.html:GetText():gsub("^>", ""))
		self.lastSelected = nil

		Analyze(true)
	end

	self.raidnames1 = {}
	for i = 1, 40 do
		local button = CreateFrame("Button", nil, self)
		self.raidnames1[i] = button
		button:SetSize(95, 14)
		button:SetPoint("TOPLEFT", 10 + math.floor((i - 1) / 5) * 98, -3 - 14 * ((i - 1) % 5))

		button.html = ELib:Text(button, "", 11):Color()
		button.html:SetAllPoints()
		button.txt = ""
		button:RegisterForClicks("LeftButtonDown")
		button.iconText = ""
		button:SetScript("OnClick", SubSelected)

		button:SetScript("OnEnter", RaidNamesOnEnter)
		button:SetScript("OnLeave", RaidNamesOnLeave)
	end




	local function SelectPlayer(self2)
		if self2.iconText == "" then return end
		if self.lastSelected then
			self.lastSelected.html:SetText(self.lastSelected.html:GetText():gsub("^|cffff0000>|r", ""))
		end
		self.lastSelected = self2
		self2.html:SetText("|cffff0000>|r" .. self2.html:GetText())
	end

	self.raidnames2 = {}
	for i = 1, 40 do
		local button = CreateFrame("Button", nil, self)
		self.raidnames2[i] = button
		button:SetSize(95, 14)
		button:SetPoint("TOPLEFT", 10 + math.floor((i - 1) / 5) * 98, -82 - 14 * ((i - 1) % 5))

		button.html = ELib:Text(button, "", 11):Color()
		button.html:SetAllPoints()
		button.txt = ""
		button:RegisterForClicks("LeftButtonDown")
		button.iconText = ""
		button:SetScript("OnClick", SelectPlayer)

		button:SetScript("OnEnter", RaidNamesOnEnter)
		button:SetScript("OnLeave", RaidNamesOnLeave)
	end

	self.NoteBackupsDropDown = ELib:DropDown(self, 220, 8):Size(218, 20):Point("BOTTOMLEFT", self,"BOTTOMLEFT", 5, 5):SetText("Note Backups"):Tooltip("Select backup to load\nAlt + Shift click to delete backups")

	do
		local function NoteBackupsDropDown_SetValue(_, key, i)
			if VMRT.NoteChecker.NoteBackups[key] then
				if i then
					CurrentUnformatedText = VMRT.NoteChecker.NoteBackups[key][i].text
					UpdateText()
				else
					if IsShiftKeyDown() and IsAltKeyDown() then
						VMRT.NoteChecker.NoteBackups[key] = nil
						ELib:DropDownClose()
						return
					end
					CurrentUnformatedText = VMRT.NoteChecker.NoteBackups[key]
					UpdateText()
				end
			end
			ELib:DropDownClose()
		end

		function self.NoteBackupsDropDown:PreUpdate()
			NoteAnalyzer.NoteBackupsDropDown.List = {}
			local List = NoteAnalyzer.NoteBackupsDropDown.List
			for noteName,noteData in next, VMRT.NoteChecker.NoteBackups do
				if type(noteData) == "table" then
					-- VMRT.NoteChecker.NoteBackups[i].name = VMRT.NoteChecker.NoteBackups[i].name or "Note " .. i
					local latestSendTime = 0
					local subMenu = {}
					for i = 1, #noteData do
						latestSendTime = max(latestSendTime, noteData[i].time or 0)
						subMenu[#subMenu+1] = {
							text = noteData[i].name .. " " .. i .. " - " .. date("%d.%m.%Y %H:%M:%S", noteData[i].time),
							func = NoteBackupsDropDown_SetValue,
							arg1 = noteName,
							arg2 = i,
							tooltip = (date("%d.%m.%Y %H:%M:%S", noteData[i].time)),
							time = noteData[i].time,
						}
					end

					local name = VMRT.NoteChecker.NoteBackups[noteName][1].name
					if not name or name:trim() == "" then
						name = "!!!No name"
					end
					List[#List+1] = {
						text = name,
						subMenu = subMenu,
						func = function()
							if IsShiftKeyDown() and IsAltKeyDown() then
								VMRT.NoteChecker.NoteBackups[noteName] = nil
								ELib:DropDownClose()
							end
						end ,
						time = latestSendTime,
					}
				else
					List[#List+1] = {
						text = "Note " .. #List+1,
						func = NoteBackupsDropDown_SetValue,
						arg1 = noteName,
					}
				end
				sort(List, function(a,b)
					return (a.time or 0) > (b.time or 0)
				end)
			end
		end
	end

	self.NoteBackupsCheck = ELib:Check(self, "Save backups", VMRT.NoteChecker.MakeBackups):Left():Point("BOTTOMRIGHT", self.NoteBackupsDropDown, "TOPRIGHT", 0, 5):OnClick(function(self)
		VMRT.NoteChecker.MakeBackups = self:GetChecked()
	end)

	self.manualReplacement = MLib:Button(self, LR["Manual Replacement"]):Size(140, 20):Point("BOTTOMRIGHT", self.NoteBackupsCheck,"TOPRIGHT", 0, 5):OnClick(function()
		MRT.F.ShowInput2(LR["Change names manually"],function(res)
			if ReplaceOnlySelected then
				local h_start, h_end = NoteAnalyzer.NoteEditBox:GetTextHighlight()
				local EditBoxText = NoteAnalyzer.NoteEditBox.EditBox:GetText()

				local textOld1 = EditBoxText:sub(0, max(h_start - 1, 0))
				local text = EditBoxText:sub(h_start, h_end)
				local textOld2 = EditBoxText:sub(h_end + 1, -1)

				if IsFormattingOn then
					textOld1 = textOld1:gsub("|([cr])", "||%1")
					text = text:gsub("|([cr])", "||%1")
					textOld2 = textOld2:gsub("|([cr])", "||%1")
				end

				text = ReplaceName(text, res[1], res[2])

				local oldSize = #CurrentUnformatedText:gsub("||([cr])", "|%1") -- check size for formatted text

				CurrentUnformatedText = textOld1 .. text .. textOld2

				local newSize = #CurrentUnformatedText:gsub("||([cr])", "|%1") -- check size for formatted text

				local changed = newSize - oldSize

				UpdateText(changed)
			else
				local text = NoteAnalyzer.NoteEditBox.EditBox:GetText()

				if IsFormattingOn then
					text = text:gsub("|([cr])", "||%1")
				end

				text = ReplaceName(text, res[1], res[2])

				local oldSize = #CurrentUnformatedText:gsub("||([cr])", "|%1") -- check size for formatted text

				CurrentUnformatedText = text

				local newSize = #CurrentUnformatedText:gsub("||([cr])", "|%1") -- check size for formatted text

				local changed = newSize - oldSize
				UpdateText(changed)
			end
		end,{text=LR["Name to find:"]},{text=LR["New name:"]})
	end)

	self.LoadCurrentNoteButton = MLib:Button(self.NoteEditBox, LR["Load Current Note"]):Point("BOTTOMLEFT", "x","TOPLEFT", 90, 5):Size(262, 20):OnClick(function(self)
		CurrentUnformatedText = VMRT.Note.Text1 or ""
		UpdateText()

		self:Anim(false)
		module.db.LastNoteUpdate = false
	end):Tooltip(function(self)
		if self.t and VMRT.Note.LastUpdateName and VMRT.Note.LastUpdateTime then
			return format(LR["Last note update was sent by %s at %s"], VMRT.Note.LastUpdateName, date("%d.%m.%Y %H:%M:%S", VMRT.Note.LastUpdateTime))
		end
	end)

	function self.LoadCurrentNoteButton:Anim(on)
		if on then
			self.t = self.t or 0
			self:SetScript("OnUpdate",function(self,elapsed)
				self.t = (self.t + elapsed) % 4

				local c = 0.05 * (self.t > 2 and (4-self.t) or self.t)

				self.Texture:SetGradient("VERTICAL",CreateColor(0.1+c,0.3+c,0.1+c,1), CreateColor(0.1+c,0.3+c,0.1+c,1))
			end)
		else
			self.t = nil
			self:SetScript("OnUpdate",nil)
			self.Texture:SetGradient("VERTICAL",CreateColor(0.12,0.12,0.12,1), CreateColor(0.14,0.14,0.14,1))
		end
	end

	self.AnalyzeNoteButton = MLib:Button(self.NoteEditBox, LR["Analyze Highlighted Text"]):Point("LEFT",self.LoadCurrentNoteButton, "RIGHT", 4, 0):Size(262, 20):OnClick(function()
		Analyze()
	end)

	self.SaveNoteButton = MLib:Button(self.NoteEditBox, LR["Send Note"]):Size(0, 30):Point("LEFT",self.NoteEditBox, "BOTTOMLEFT", 2, 0):Point("RIGHT", self, "BOTTOMRIGHT", -2, 0):Point("BOTTOM", self,"BOTTOM", 0, 2):OnClick(function()
		if CurrentUnformatedText == "" then
			print(LR["Note is empty. Probably a bug?"])
			return
		end

		VMRT.Note.Text1 = CurrentUnformatedText
		MRT.A.Note.frame:Save()
	end)

	self.GroupToCountSlider = ELib:Slider(self.NoteEditBox, ""):Size(150):Point("BOTTOMRIGHT", "x", "TOPLEFT",-10, 10):Range(1, 8):SetTo(GroupToCount):OnChange(function(self, event)
		event = floor(event + .5)
		GroupToCount = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(self.NoteEditBox, LR["Groups:"], 11):Point("RIGHT", self.GroupToCountSlider, "LEFT", -5, 0):Color(1,.82, 0, 1):Right()

	self.optFormatting = ELib:Check(self, FORMATTING, IsFormattingOn):Point("BOTTOMLEFT",self.NoteEditBox, "TOPLEFT", 0, 5):Size(15, 15):OnClick(function(self)
		IsFormattingOn = self:GetChecked()
		UpdateText()
	end)

	self.ReplaceOnlySelected = ELib:Check(self, LR["Replace only in highlighted text"], ReplaceOnlySelected):Point("TOPLEFT", NoteAnalyzer.NoteEditBox, "TOPLEFT", -225, -5):Size(15, 15):OnClick(function(self)
		ReplaceOnlySelected = self:GetChecked()
		if ReplaceOnlySelected then
			NoteAnalyzer.AnalyzeNoteButton:SetText(LR["Analyze Highlighted Text"])
		else
			NoteAnalyzer.AnalyzeNoteButton:SetText(LR["Analyze All/Highlighted Text"])
		end
	end)

	self.allowNumbersCheck = ELib:Check(self, LR["Allow numbers in names"], VMRT.NoteChecker.allowNumbers):Point("TOPLEFT",self.ReplaceOnlySelected, "BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
		VMRT.NoteChecker.allowNumbers = self:GetChecked()
	end)

	self.allowNonLetterSymbolsCheck = ELib:Check(self, LR["Allow non letter symbols in names"],VMRT.NoteChecker.allowNonLetterSymbols):Tooltip(LR["Non letter symbols are:"] .. "\n" .. "' - \" { } : ( ) + - [ ]"):Point("TOPLEFT", self.allowNumbersCheck,"BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
		VMRT.NoteChecker.allowNonLetterSymbols = self:GetChecked()
	end)

	self.allowHashtagCheck = ELib:Check(self, LR["Allow # symbol in names"], VMRT.NoteChecker.allowHashtag):Point("TOPLEFT",self.allowNonLetterSymbolsCheck, "BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
		VMRT.NoteChecker.allowHashtag = self:GetChecked()
	end)

	self.totalPlayers = ELib:Text(self, "", 12):Point("TOPLEFT", self.allowHashtagCheck, "BOTTOMLEFT", 0, -10):Color():Shadow()
	self.repeatedPlayers = ELib:Text(self, "", 12):Point("TOPLEFT", self.totalPlayers, "BOTTOMLEFT", 0, -10):Size(0, 200):Top():Left():Color():Shadow():MaxLines(30)
end

tinsert(parentModule.options.ModulesToLoad,NoteAnalyzerInit)

function module.main:ADDON_LOADED()
	VMRT = _G.VMRT
	VMRT.NoteChecker = VMRT.NoteChecker or {}
	VMRT.NoteChecker.NoteBackups = VMRT.NoteChecker.NoteBackups or {}
end

local function SaveNoteBackup()
	local text = MRT.F.GetNote()
	local noteName = VMRT.Note.DefName or ""
	if text:trim() ~= "" then

		VMRT.NoteChecker.NoteBackups[noteName] = VMRT.NoteChecker.NoteBackups[noteName] or {}
		if #VMRT.NoteChecker.NoteBackups[noteName] > 0 and VMRT.NoteChecker.NoteBackups[noteName][1].text == text then
			return
		end

		tinsert(VMRT.NoteChecker.NoteBackups[noteName], 1, {text = text, time = time(),name = noteName})

		while #VMRT.NoteChecker.NoteBackups[noteName] > 15 do
			tremove(VMRT.NoteChecker.NoteBackups[noteName], 16)
		end
	end

	module.db.BackupTimer = nil
	while #VMRT.NoteChecker.NoteBackups > 5 do
		tremove(VMRT.NoteChecker.NoteBackups, 6)
	end
end

MRT.F:RegisterCallback("Note_ReceivedText", function(note)
	if VMRT.NoteChecker.MakeBackups and not module.db.BackupTimer then
		module.db.BackupTimer = MRT.F.ScheduleTimer(SaveNoteBackup, 15)
	end

	if module.opts then
		if (CurrentUnformatedText and CurrentUnformatedText:trim()) ~= (VMRT.Note.Text1 and VMRT.Note.Text1:trim()) then
			module.opts.LoadCurrentNoteButton:Anim(true)
		else
			module.opts.LoadCurrentNoteButton:Anim(false)
		end
	end
end)

