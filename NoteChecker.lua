--/run VExRT.Note.Text1 = VExRT.NoteChecker.NoteBackups[1]
local GlobalAddonName, ExRT = ...

local ELib, L = ExRT.lib, ExRT.L

local LR = setmetatable({}, {
	__index = function(t, k)
		return ExRT.LR[k] or k
	end
})

local module = ExRT:New("NoteAnalyzer", "|cff80ff00Raid Analyzer|r", nil, true)
if not module then return end

module.db.responces = {}
module.db.invitersReady = {}

local DEFAULT_INSTANCE = 2569
local DEFAULT_DIFFICULTY = 15

local InstanceIDtoJournalInstanceID = {
	[2569] = 1208, --aberrus
	[2549] = 1207, --amir
	[2522] = 1200, --vault
}

local tabFont, tabFontSize, TabFontOutline = GameFontNormal:GetFont()
local IsFormattingOn = true
local CurrentUnformatedText = ""
local GroupToCount = 4
local ReplaceOnlySelected = true

local RealClassColors = {
	--INNER MRT COLORCODES
	["|cffc69b6d"] = true,
	["|cfff48cba"] = true,
	["|cffaad372"] = true,
	["|cfffff468"] = true,
	["|cffffffff"] = true,
	["|cffc41e3a"] = true,
	["|cff0070dd"] = true,
	["|cff3fc7eb"] = true,
	["|cff8788ee"] = true,
	["|cff00ff98"] = true,
	["|cffff7c0a"] = true,
	["|cffa330c9"] = true,
	["|cff33937f"] = true,
	--VISERIO COLOROCDES
	["|cffc31d39"] = true,
	["|cffa22fc8"] = true,
	["|cfffe7b09"] = true,
	["|cff3ec6ea"] = true,
	["|cff00fe97"] = true,
	["|cfff38bb9"] = true,
	["|cfffefefe"] = true,
	["|cfff0ead6"] = true,
	["|cffffff00"] = true,
	["|cfffef367"] = true,
	["|cff006fdc"] = true,
	["|cff8687ed"] = true,
	["|cffc59a6c"] = true,
	["|cffa9d271"] = true,
}

function module.options:Load()
	self:CreateTilte()

	local function mStyledTabs(parent, template, ...)
		local newTabs = ELib:Tabs(parent, template, ...) --(self, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)

		for i = 1, #newTabs.tabs do
			if newTabs.tabs[i].button.ButtonState then
				newTabs.tabs[i].button:GetFontString():SetFont(tabFont, 13, "OUTLINE")
				newTabs.resizeFunc(newTabs.tabs[i].button, 0, nil, nil,
					newTabs.tabs[i].button:GetFontString():GetStringWidth(),
					newTabs.tabs[i].button:GetFontString():GetStringWidth())
			else
				newTabs.tabs[i].button:GetFontString():SetFont(tabFont, 13)
				newTabs.resizeFunc(newTabs.tabs[i].button, 0, nil, nil,
					newTabs.tabs[i].button:GetFontString():GetStringWidth(),
					newTabs.tabs[i].button:GetFontString():GetStringWidth())
			end
		end
		local function TabFrameUpdateTabs(self)
			for i = 1, #self.tabs do
				if i == self.selected then
					self.tabs[i].button.Select(self.tabs[i].button)
					self.tabs[i].button:GetFontString():SetFont(tabFont, 13, "OUTLINE")
				else
					self.tabs[i].button.Deselect(self.tabs[i].button)
					self.tabs[i].button:GetFontString():SetFont(tabFont, 13)
				end
				self.tabs[i]:Hide()

				if self.tabs[i].disabled then
					PanelTemplates_SetDisabledTabState(self.tabs[i].button)
				end
			end
			if self.selected and self.tabs[self.selected] then
				self.tabs[self.selected]:Show()
			end
			if self.navigation then
				if self.disabled then
					self.navigation:SetEnabled(nil)
				else
					self.navigation:SetEnabled(true)
				end
			end
		end
		newTabs.UpdateTabs = TabFrameUpdateTabs

		newTabs:SetBackdropBorderColor(0, 0, 0, 0)
		newTabs:SetBackdropColor(0, 0, 0, 0)
		return newTabs
	end


	local decorationLine = ELib:DecorationLine(self, true, "BACKGROUND", -5):Point("TOPLEFT", self, 0, -25):Point("BOTTOMRIGHT", self, "TOPRIGHT", 0, -45)
	decorationLine:SetGradient("VERTICAL", CreateColor(0.17, 0.17, 0.17, 0.77), CreateColor(0.17, 0.17, 0.17, 0.77)) --:SetGradient("HORIZONTAL",CreateColor(0.55,0.21,0.25,0.9), CreateColor(0.7,0.21,0.25,0.9))

	self.tab = mStyledTabs(self, 0, "Note Analyzer", ExRT.isClassic and "" or "Raid Lockouts", "Group Invites"):Run(function(self) if ExRT.isClassic  then self.tabs[2].button:Hide()  end end):Point(0, -45):Size(698, 570):SetTo(1)                                                                                                       --(self, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)


	self.NoteEditBox = ELib:MultiEdit(self.tab.tabs[1]):Point("BOTTOMRIGHT", self, "BOTTOMRIGHT", -5, 35):Size(616, 370)
	ELib:Border(self.NoteEditBox, 0, .24, .25, .30, 1)

	--NoteEditBox lines
	ELib:DecorationLine(self.NoteEditBox):Point("TOPLEFT", -1, 1):Point("BOTTOMLEFT", self, "BOTTOM", 0, 0):Size(1, 0)
	ELib:DecorationLine(self.NoteEditBox):Point("TOPLEFT", -1, 1):Point("TOPRIGHT", self, "RIGHT", 0, 0):Size(0, 1)

	--RaidNames lines
	ELib:DecorationLine(self.tab.tabs[1]):Point("TOPLEFT", self, "TOPLEFT", 0, -123):Point("TOPRIGHT", self, "TOPRIGHT",0, -123):Size(0, 1)
	ELib:DecorationLine(self.tab.tabs[1]):Point("TOPLEFT", self, "TOPLEFT", 0, -200):Point("TOPRIGHT", self, "TOPRIGHT",0, -200):Size(0, 1)


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
		local h_start, h_end = module.options.NoteEditBox:GetTextHighlight()
		local pos = module.options.NoteEditBox.EditBox:GetCursorPosition()


		module.options.NoteEditBox.EditBox:SetText(text)
		module.options.NoteEditBox.EditBox:SetCursorPosition(pos)
		if h_start ~= h_end then
			module.options.NoteEditBox.EditBox:HighlightText(h_start, h_end + (changed or 0))
		end
	end

	function self.NoteEditBox.EditBox:OnTextChanged(isUser)
		if not isUser and (not module.options.InsertFix or GetTime() - module.options.InsertFix > 0.1) then
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
			module.options.InsertFix = nil
			IsFormattingOn_Saved = true
			IsFormattingOn = false
			local h_start, h_end = module.options.NoteEditBox:GetTextHighlight()
			local h_cursor = self:GetCursorPosition()
			local text = module.options.NoteEditBox.EditBox:GetText()

			-- last_highlight_start,last_highlight_end,last_cursor_pos = h_start,h_end,h_cursor

			local c_start, c_end, c_cursor = 0, 0, 0
			text:sub(1, h_start):gsub("|([cr])", function() c_start = c_start + 1 end)
			text:sub(1, h_end):gsub("|([cr])", function() c_end = c_end + 1 end)
			text:sub(1, h_cursor):gsub("|([cr])", function() c_cursor = c_cursor + 1 end)

			text = text:gsub("|([cr])", "||%1")
			module.options.NoteEditBox.EditBox:_SetText(text)

			module.options.NoteEditBox.EditBox:HighlightText(h_start + c_start, h_end + c_end)
			module.options.NoteEditBox.EditBox:SetCursorPosition(h_cursor + c_cursor)
		end
	end)

	self.NoteEditBox.EditBox:SetScript("OnKeyUp", function(self, key)
		if IsFormattingOn_Saved and key == "LCTRL" then
			local text = module.options.NoteEditBox.EditBox:GetText()
			local h_start, h_end = module.options.NoteEditBox:GetTextHighlight()
			local h_cursor = self:GetCursorPosition()
			local c_start, c_end, c_cursor = 0, 0, 0
			text:sub(1, h_start):gsub("||([cr])", function() c_start = c_start + 1 end)
			text:sub(1, h_end):gsub("||([cr])", function() c_end = c_end + 1 end)
			text:sub(1, h_cursor):gsub("||([cr])", function() c_cursor = c_cursor + 1 end)

			IsFormattingOn = true
			IsFormattingOn_Saved = nil
			module.options.InsertFix = nil
			UpdateText()
			module.options.NoteEditBox.EditBox:HighlightText(h_start - c_start, h_end - c_end)
			module.options.NoteEditBox.EditBox:SetCursorPosition(h_cursor - c_cursor)
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
			module.options.NoteEditBox.EditBox:Insert("")
		end
		local txt = module.options.NoteEditBox.EditBox:GetText()
		local pos = module.options.NoteEditBox.EditBox:GetCursorPosition()
		if not self and type(mypos) == 'number' then
			pos = mypos
		end
		txt = string.sub(txt, 1, pos) .. addedText .. string.sub(txt, pos + 1)
		module.options.InsertFix = GetTime()
		module.options.NoteEditBox.EditBox:SetText(txt)
		local adjust = 0
		if IsFormattingOn then
			addedText:gsub("||", function() adjust = adjust + 1 end)
		end
		module.options.NoteEditBox.EditBox:SetCursorPosition(pos + addedText:len() - adjust)
	end

	local function Analyze(old)
		local h_start, h_end = module.options.NoteEditBox:GetTextHighlight()
		local h_cursor = module.options.NoteEditBox.EditBox:GetCursorPosition()
		local text = module.options.NoteEditBox.EditBox:GetText():sub(h_start, h_end)



		if old then
			text = self.analyzedText
		elseif h_start == h_end and not ReplaceOnlySelected then
			-- return
			text = module.options.NoteEditBox.EditBox:GetText()
			self.analyzedText = text
		else
			self.analyzedText = text
		end

		-- if not IsFormattingOn or IsFormattingOn_Saved then
		text = text:gsub("||([cr])", "|%1")
		-- end

		self.lastSelected = nil

		local playersInNote = {}
		local playersRepeated = {}
		local AnyRepeated = false

		local InRaidNotAssigned = {}
		local AssignedNotInRaid = {}

		local lines = { strsplit("\n", text) }
		local namesCount = 0
		for i = 1, #lines do
			if lines[i] then
				local l = lines[i]
				for name in string.gmatch(l, "[^, ]+") do
					if name:match(":") then
						name = strsplit(":", name, 1)
					end
					local isName = true

					local nameClear = name:gsub("(|c[fF][fF]......)([^|]+)|*r", function(colorCode, arg2)
						-- print(colorCode,arg2)
						if not RealClassColors[colorCode] then
							isName = false
						end
						-- if arg2 then name = arg2 end
						return arg2 or ""
					end):gsub("|r", ""):gsub("|", "")

					if isName and
						(
							(VExRT.NoteChecker.allowNumbers or not nameClear:match("%d")) and
							(VExRT.NoteChecker.allowNonLetterSymbols or not nameClear:match("[%'%-\"%{%}:]")) and
							(VExRT.NoteChecker.allowHashtag or not nameClear:match("#"))
						--  not nameClear:match("[%d%'#%-\"{} ]")
						) and
						not nameClear:match("^%l")
					then
						namesCount = namesCount + 1
						nameClear = nameClear:gsub("[%d%'%#%-\"%{%}:]", "")
						if not playersInNote[nameClear] then
							playersInNote[nameClear] = name
						else
							playersRepeated[nameClear] = (playersRepeated[nameClear] or 1) + 1
							AnyRepeated = true
						end
					end
				end
			end
		end

		module.options.totalPlayers:SetText("Total names in analyzed text: " .. namesCount)
		local repPlayersText = AnyRepeated and "|cffee5555Repeated players:|r\n" or "Repeated players:\n"

		for k, v in pairs(playersRepeated) do
			repPlayersText = repPlayersText .. k .. " - " .. v .. "\n"
		end
		module.options.repeatedPlayers:SetText(repPlayersText)

		for _, name, _, class in ExRT.F.IterateRoster, GroupToCount do
			name = ExRT.F.delUnitNameServer(name)
			local cR, cG, cB = ExRT.F.classColorNum(class)
			local colorCode = ExRT.F.classColor(class)

			if playersInNote[name] then
				-- AssignedInRaid[name] = {cR,cG,cB,colorCode}
				playersInNote[name] = nil
			else
				InRaidNotAssigned[name] = { cR, cG, cB, colorCode }
				playersInNote[name] = nil
			end
		end

		for name, nameColored in pairs(playersInNote) do
			AssignedNotInRaid[name] = nameColored
		end

		for i = 1, 40 do
			local obj = module.options.raidnames1[i]
			if not obj then return end

			obj.iconText = ""
			obj.iconTextShift = ""
			obj.html:SetText("")
			obj.html:SetTextColor(1, 1, 1, 1)
		end

		local index1 = 0
		for k, color in pairs(InRaidNotAssigned) do
			local r, g, b, colorCode = unpack(color)
			index1 = index1 + 1
			local obj = module.options.raidnames1[index1]
			if not obj then return end

			obj.iconText = k
			obj.iconTextShift = "||c" .. colorCode .. k .. "||r"
			obj.html:SetText(k)
			obj.html:SetTextColor(r, g, b, 1)
		end


		for i = 1, 40 do
			local obj = module.options.raidnames2[i]
			if not obj then return end

			obj.iconText = ""
			obj.iconTextShift = ""
			obj.html:SetText("")
		end

		local index2 = 0
		for name, nameColored in pairs(AssignedNotInRaid) do
			index2 = index2 + 1
			local obj = module.options.raidnames2[index2]
			if not obj then return end

			obj.iconText = nameColored
			obj.iconTextShift = name
			obj.html:SetText(nameColored)
			obj.html:SetTextColor(1, 1, 1, 1)
		end
	end

	local function RaidNamesOnEnter(self)
		self.html:SetShadowColor(0.2, 0.2, 0.2, 1)
	end
	local function RaidNamesOnLeave(self)
		self.html:SetShadowColor(0, 0, 0, 1)
	end

	local function SubSelected(self2)
		if self2.iconText == "" then return end
		if self.lastSelected and self.lastSelected.iconText ~= "" and not IsShiftKeyDown() then -- if obj have text and shift not pressed
			local pos = module.options.NoteEditBox.EditBox:GetCursorPosition()

			local oldSize, newSize, changed

			if not ReplaceOnlySelected then
				local text = module.options.NoteEditBox.EditBox:GetText()

				-- if not IsFormattingOn or IsFormattingOn_Saved then
				text = text:gsub("||([cr])", "|%1")
				-- end

				text = text:gsub("|cff%x%x%x%x%x%x" .. self.lastSelected.iconTextShift .. "|r", self2.iconTextShift)
				text = text:gsub(self.lastSelected.iconTextShift, self2.iconTextShift)


				oldSize = IsFormattingOn and #self.analyzedText:gsub("||([cr])", "|%1") or #self.analyzedText

				self.analyzedText = self.analyzedText:gsub("|cff%x%x%x%x%x%x" .. self.lastSelected.iconTextShift .. "|r",
					self2.iconTextShift)
				self.analyzedText = self.analyzedText:gsub(self.lastSelected.iconTextShift, self2.iconTextShift)

				newSize = IsFormattingOn and #self.analyzedText:gsub("||([cr])", "|%1") or #self.analyzedText
				changed = newSize - oldSize

				CurrentUnformatedText = text
			else
				local h_start, h_end = module.options.NoteEditBox:GetTextHighlight()


				local textOld1 = module.options.NoteEditBox.EditBox:GetText():sub(0, max(h_start - 1, 0))
				local text = module.options.NoteEditBox.EditBox:GetText():sub(h_start, h_end)
				local textOld2 = module.options.NoteEditBox.EditBox:GetText():sub(h_end + 1,
					#module.options.NoteEditBox.EditBox:GetText())

				oldSize = IsFormattingOn and #text:gsub("||([cr])", "|%1") or #text
				-- "|*c%x%x%x%x%x%x%x%x([^|]+)|*r"
				text = text:gsub("|cff%x%x%x%x%x%x" .. self.lastSelected.iconTextShift .. "|r", self2.iconTextShift)
				text = text:gsub(self.lastSelected.iconTextShift, self2.iconTextShift)


				newSize = IsFormattingOn and #text:gsub("||([cr])", "|%1") or #text

				changed = newSize - oldSize
				CurrentUnformatedText = textOld1 .. text .. textOld2

				self.analyzedText = text
			end

			UpdateText(changed)
			module.options.NoteEditBox.EditBox:SetCursorPosition(pos)

			self.lastSelected.html:SetText(self.lastSelected.html:GetText():gsub("^>", ""))
			self.lastSelected.html:SetTextColor(1, 1, 1, 1)
			self.lastSelected = nil

			Analyze(true)
		elseif self2 and self2.iconTextShift ~= "" then
			AddTextToEditBox(self2)
		end
	end

	self.raidnames1 = {}
	for i = 1, 40 do
		local button = CreateFrame("Button", nil, self.tab.tabs[1])
		self.raidnames1[i] = button
		button:SetSize(90, 14)
		button:SetPoint("TOPLEFT", 15 + math.floor((i - 1) / 5) * 93, -5 - 14 * ((i - 1) % 5))

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
			self.lastSelected.html:SetText(self.lastSelected.html:GetText():gsub("^>", ""))
			self.lastSelected.html:SetTextColor(1, 1, 1, 1)
		end
		self.lastSelected = self2
		self2.html:SetText(">" .. self2.html:GetText())
		self2.html:SetTextColor(1, 0, 0, 1)
	end

	self.raidnames2 = {}
	for i = 1, 40 do
		local button = CreateFrame("Button", nil, self.tab.tabs[1])
		self.raidnames2[i] = button
		button:SetSize(90, 14)
		button:SetPoint("TOPLEFT", 15 + math.floor((i - 1) / 5) * 93, -80 - 14 * ((i - 1) % 5))

		button.html = ELib:Text(button, "", 11):Color()
		button.html:SetAllPoints()
		button.txt = ""
		button:RegisterForClicks("LeftButtonDown")
		button.iconText = ""
		button:SetScript("OnClick", SelectPlayer)

		button:SetScript("OnEnter", RaidNamesOnEnter)
		button:SetScript("OnLeave", RaidNamesOnLeave)
	end

	self.NoteBackupsDropDown = ELib:DropDown(self.tab.tabs[1], 200, 5):Size(218, 20):Point("BOTTOMLEFT", self,
		"BOTTOMLEFT", 5, 5):SetText("Note Backups"):Tooltip("Select backup to load")

	do
		local function NoteBackupsDropDown_SetValue(_, key)
			if VExRT.NoteChecker.NoteBackups[key] then
				CurrentUnformatedText = VExRT.NoteChecker.NoteBackups[key]
				UpdateText()
				ELib:DropDownClose()
			end
		end

		local List = self.NoteBackupsDropDown.List
		for i = 1, 5 do
			List[i] = {
				text = "Note " .. i,
				func = NoteBackupsDropDown_SetValue,
				arg1 = i,
			}
		end
	end

	self.LoadCurrentNoteButton = ELib:mStyledButton(self.NoteEditBox, "Load Current Note"):Point("BOTTOMLEFT", "x","TOPLEFT", 90, 5):Size(262, 20):OnClick(function()
		CurrentUnformatedText = VMRT.Note.Text1
		UpdateText()
	end)

	self.AnalyzeNoteButton = ELib:mStyledButton(self.NoteEditBox, "Analyze Highlighted Text"):Point("LEFT",self.LoadCurrentNoteButton, "RIGHT", 4, 0):Size(262, 20):OnClick(function()
		Analyze()
	end)

	self.SaveNoteButton = ELib:mStyledButton(self.NoteEditBox, "Send Note"):Size(0, 30):Point("LEFT",self.NoteEditBox, "BOTTOMLEFT", 2, 0):Point("RIGHT", self, "BOTTOMRIGHT", -2, 0):Point("BOTTOM", self,"BOTTOM", 0, 2):OnClick(function()
		if CurrentUnformatedText == "" then
            print("Note is empty. Probably a bug?")
            return
        end

        VExRT.Note.Text1 = CurrentUnformatedText
		GMRT.A.Note.frame:Save()
	end)

	self.GroupToCountSlider = ELib:Slider(self.NoteEditBox, ""):Size(150):Point("BOTTOMRIGHT", "x", "TOPLEFT",-10, 10):Range(1, 8):SetTo(GroupToCount):OnChange(function(self, event)
		event = floor(event + .5)
		GroupToCount = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)
	ELib:Text(self.NoteEditBox, "Groups:", 11):Point("RIGHT", self.GroupToCountSlider, "LEFT", -5, 0):Color(1,.82, 0, 1):Right()

	self.optFormatting = ELib:Check(self.tab.tabs[1], FORMATTING, IsFormattingOn):Point("BOTTOMLEFT",self.NoteEditBox, "TOPLEFT", 0, 5):Size(15, 15):OnClick(function(self)
		IsFormattingOn = self:GetChecked()
		UpdateText()
	end)

	self.ReplaceOnlySelected = ELib:Check(self.tab.tabs[1], "Replace only in highlighted text", ReplaceOnlySelected):Point("TOPLEFT", module.options.NoteEditBox, "TOPLEFT", -225, -5):Size(15, 15):OnClick(function(self)
		ReplaceOnlySelected = self:GetChecked()
		if ReplaceOnlySelected then
			module.options.AnalyzeNoteButton:SetText("Analyze Highlighted Text")
		else
			module.options.AnalyzeNoteButton:SetText("Analyze All/Highlighted Text")
		end
	end)

	self.allowNumbersCheck = ELib:Check(self.tab.tabs[1], "Allow numbers in names", VExRT.NoteChecker.allowNumbers):Point("TOPLEFT",self.ReplaceOnlySelected, "BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
        VExRT.NoteChecker.allowNumbers = self:GetChecked()
	end)

	self.allowNonLetterSymbolsCheck = ELib:Check(self.tab.tabs[1], "Allow non letter symbols in names",VExRT.NoteChecker.allowNonLetterSymbols):Tooltip("Non letter symbols are:\n' - \" { } :"):Point("TOPLEFT", self.allowNumbersCheck,"BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
        VExRT.NoteChecker.allowNonLetterSymbols = self:GetChecked()
	end)

	self.allowHashtagCheck = ELib:Check(self.tab.tabs[1], "Allow # symbol in names", VExRT.NoteChecker.allowHashtag):Point("TOPLEFT",
		self.allowNonLetterSymbolsCheck, "BOTTOMLEFT", 0, -5):Size(15, 15):OnClick(function(self)
            VExRT.NoteChecker.allowHashtag = self:GetChecked()
	end)

	self.totalPlayers = ELib:Text(self.tab.tabs[1], "", 12):Point("TOPLEFT", self.allowHashtagCheck, "BOTTOMLEFT", 0, -10)
	:Color():Shadow()
	self.repeatedPlayers = ELib:Text(self.tab.tabs[1], "", 12):Point("TOPLEFT", self.totalPlayers, "BOTTOMLEFT", 0, -10)
	:Size(0, 200):Top():Left():Color():Shadow():MaxLines(30)


	self.isWide = true

	--Raid Lockouts
	---------------
	---------------
	---------------

	local UpdatePage

	local function SetIcon(self, type)
		if not type or type == 0 then
			self:SetAlpha(0)
		elseif type == 1 then
			self:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
			self:SetAlpha(1)
			-- self:SetTexCoord(0.5,0.5625,0.5,0.625)
			-- self:SetVertexColor(.8,0,0,1)
		elseif type == 2 then
			self:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
			self:SetAlpha(1)
			-- self:SetTexCoord(0.5625,0.625,0.5,0.625)
			-- self:SetVertexColor(0,.8,0,1)
		elseif type == 3 then
			-- self:SetTexCoord(0.625,0.6875,0.5,0.625)
			-- self:SetVertexColor(.8,.8,0,1)
		elseif type == 4 then
			-- self:SetTexCoord(0.875,0.9375,0.5,0.625)
			-- self:SetVertexColor(.8,.8,0,1)
		elseif type == -1 or type < 0 then
			if module.SetIconExtra then
				module.SetIconExtra(self, type)
			end
		end
	end

	self.helpicons = {}
	for i = 0, 1 do
		local icon = self.tab.tabs[2]:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", 2, -5 - i * 12)
		icon:SetSize(14, 14)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		SetIcon(icon, i + 1)
		local t = ELib:Text(self.tab.tabs[2], "", 10):Point("LEFT", icon, "RIGHT", 2, 0):Size(0, 16):Color(1, 1, 1)
		if i == 0 then
			t:SetText(LR.BossNotKilled)
		elseif i == 1 then
			t:SetText(LR.BossKilled)
			-- elseif i==2 then
			-- 	t:SetText(L.WACheckerPlayerHaveNotWA)
		end
		self.helpicons[i + 1] = { icon, t }
	end


	local PAGE_HEIGHT, PAGE_WIDTH = 480, 850
	local LINE_HEIGHT, LINE_NAME_WIDTH = 20, 190
	local VERTICALNAME_WIDTH = 20
	local VERTICALNAME_COUNT = 31

	local mainScroll = ELib:ScrollFrame(self.tab.tabs[2]):Size(PAGE_WIDTH, PAGE_HEIGHT):Point("TOP", 76, -80):Height(700)
	ELib:Border(mainScroll, 0)

	ELib:DecorationLine(self.tab.tabs[2]):Point("BOTTOM", mainScroll, "TOP", 0, 0):Point("LEFT", self):Point("RIGHT",
		self):Size(0, 1)
	ELib:DecorationLine(self.tab.tabs[2]):Point("TOP", mainScroll, "BOTTOM", 0, 0):Point("LEFT", self):Point("RIGHT",
		self):Size(0, 1)

	local prevTopLine = 0
	local prevPlayerCol = 0

	mainScroll.ScrollBar:ClickRange(LINE_HEIGHT)
	mainScroll.ScrollBar.slider:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % LINE_HEIGHT)
		self:UpdateButtons()
		local currTopLine = floor(value / LINE_HEIGHT)
		if currTopLine ~= prevTopLine then
			prevTopLine = currTopLine
			UpdatePage()
		end
	end)

	local raidSlider = ELib:Slider(self.tab.tabs[2], ""):Point("TOPLEFT", mainScroll, "BOTTOMLEFT", LINE_NAME_WIDTH + 15,
		-3):Range(0, 25):Size(VERTICALNAME_WIDTH * VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
		local currPlayerCol = floor(value)
		if currPlayerCol ~= prevPlayerCol then
			prevPlayerCol = currPlayerCol
			UpdatePage()
		end
	end)
	raidSlider.Low:Hide()
	raidSlider.High:Hide()
	raidSlider.text:Hide()
	raidSlider.Low.Show = raidSlider.Low.Hide
	raidSlider.High.Show = raidSlider.High.Hide


	local lines = {}
	self.lines = lines
	for i = 1, floor(PAGE_HEIGHT / LINE_HEIGHT) + 2 do
		local line = CreateFrame("Frame", nil, mainScroll.C)
		lines[i] = line
		line:SetPoint("TOPLEFT", 0, -(i - 1) * LINE_HEIGHT)
		line:SetPoint("TOPRIGHT", 0, -(i - 1) * LINE_HEIGHT)
		line:SetSize(0, LINE_HEIGHT)

		line.name = ELib:Text(line, "", 11):Point("LEFT", 2, 0):Size(LINE_NAME_WIDTH - LINE_HEIGHT / 2, LINE_HEIGHT)
		:Color(1, 1, 1):Tooltip("ANCHOR_LEFT", true)
		-- line.name.TooltipFrame:SetScript("OnClick",LineName_OnClick)

		-- line.share = CreateFrame("Button",nil,line)
		-- line.share:SetPoint("LEFT",line.name,"RIGHT",0,0)
		-- line.share:SetSize(LINE_HEIGHT,LINE_HEIGHT)
		-- line.share:SetScript("OnEnter",LineName_ShareButton_OnEnter)
		-- line.share:SetScript("OnLeave",LineName_ShareButton_OnLeave)
		-- line.share:SetScript("OnClick",LineName_ShareButton_OnClick)
		-- line.share:RegisterForClicks("LeftButtonUp","RightButtonUp")

		-- line.share.background = line.share:CreateTexture(nil,"ARTWORK")
		-- line.share.background:SetPoint("CENTER")
		-- line.share.background:SetSize(LINE_HEIGHT,LINE_HEIGHT)
		-- line.share.background:SetTexture("Interface\\AddOns\\"..GlobalAddonName.."\\media\\DiesalGUIcons16x256x128")
		-- line.share.background:SetTexCoord(0.125+(0.1875 - 0.125)*4,0.1875+(0.1875 - 0.125)*4,0.5,0.625)
		-- line.share.background:SetVertexColor(1,1,1,0.7)

		line.icons = {}
		local iconSize = min(VERTICALNAME_WIDTH, LINE_HEIGHT) - 4
		for j = 1, VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil, "ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER", line, "LEFT",
				LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH * (j - 1) + VERTICALNAME_WIDTH / 2, 0)
			icon:SetSize(iconSize, iconSize)
			icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
			SetIcon(icon, (i + j) % 4)

			icon.hoverFrame = CreateFrame("Frame", nil, line)
			icon.hoverFrame:Hide()
			icon.hoverFrame:SetAllPoints(icon)
			-- icon.hoverFrame:SetScript("OnEnter",LineName_Icon_OnEnter)
			-- icon.hoverFrame:SetScript("OnLeave",LineName_Icon_OnLeave)
		end

		line.t = line:CreateTexture(nil, "BACKGROUND")
		line.t:SetAllPoints()
		line.t:SetColorTexture(1, 1, 1, .05)
	end

	local function RaidNames_OnEnter(self)
		local t = self.t:GetText()
		if t ~= "" then
			ELib.Tooltip.Show(self, "ANCHOR_LEFT", t)
		end
	end

	local raidNames = CreateFrame("Frame", nil, self.tab.tabs[2])
	for i = 1, VERTICALNAME_COUNT do
		raidNames[i] = ELib:Text(raidNames, "RaidName" .. i, 10):Point("BOTTOMLEFT", mainScroll, "TOPLEFT",
			LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH * (i - 1), 0):Color(1, 1, 1)

		local f = CreateFrame("Frame", nil, self)
		f:SetPoint("BOTTOMLEFT", mainScroll, "TOPLEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH * (i - 1), 0)
		f:SetSize(VERTICALNAME_WIDTH, 80)
		f:SetScript("OnEnter", RaidNames_OnEnter)
		f:SetScript("OnLeave", ELib.Tooltip.Hide)
		f.t = raidNames[i]

		local t = mainScroll:CreateTexture(nil, "BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH * (i - 1), 0)
		t:SetSize(VERTICALNAME_WIDTH, PAGE_HEIGHT)
		if i % 2 == 1 then
			t:SetColorTexture(.5, .5, 1, .05)
			t.Vis = true
		end
	end
	local group = raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	--rotation:SetDegrees(90)
	rotation:SetDegrees(60)
	group:Play()

	local highlight_y = mainScroll.C:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_y:SetColorTexture(1, 1, 1, .2)
	local highlight_x = mainScroll:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_x:SetColorTexture(1, 1, 1, .2)

	local highlight_onupdate_maxY = (floor(PAGE_HEIGHT / LINE_HEIGHT) + 2) * LINE_HEIGHT
	local highlight_onupdate_minX = LINE_NAME_WIDTH + 15
	local highlight_onupdate_maxX = highlight_onupdate_minX + #raidNames * VERTICALNAME_WIDTH
	mainScroll.C:SetScript("OnUpdate", function(self)
		local x, y = ExRT.F.GetCursorPos(mainScroll)
		if y < 0 or y > PAGE_HEIGHT then
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		local x, y = ExRT.F.GetCursorPos(self)
		if y >= 0 and y <= highlight_onupdate_maxY then
			y = floor(y / LINE_HEIGHT)
			highlight_y:ClearAllPoints()
			highlight_y:SetAllPoints(lines[y + 1])
			highlight_y:Show()
		else
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		if x >= highlight_onupdate_minX and x <= highlight_onupdate_maxX then
			x = floor((x - highlight_onupdate_minX) / VERTICALNAME_WIDTH)
			highlight_x:ClearAllPoints()
			highlight_x:SetAllPoints(raidNames[x + 1].t)
			highlight_x:Show()
		elseif x >= 0 and x <= (PAGE_WIDTH - 16) then
			highlight_x:Hide()
		else
			highlight_x:Hide()
			highlight_y:Hide()
		end
	end)

	local UpdateButton = ELib:mStyledButton(self.tab.tabs[2], UPDATE):Point("TOPLEFT", mainScroll, "BOTTOMLEFT", 2, -5):Size(
	130, 20):OnClick(function(self)
		ExRT.F.SendExMsg("RaidLockouts", "R\t" .. DEFAULT_INSTANCE .. "\t" .. DEFAULT_DIFFICULTY)

		C_Timer.After(2, UpdatePage)
		self:Disable()
	end)

	local Instances = {
		[2569] = "Aberrus",
		[2549] = "Amirdrassil",
		[2522] = "Vault of Incarnates"
	}
	local Difficulties = {
		[15] = "Heroic",
		[16] = "Mythic",
	}
	local InstanceDropDown = ELib:DropDown(self.tab.tabs[2], 130, 3):Point("TOPLEFT", UpdateButton, "TOPRIGHT", 5, 0):Size(130, 20):SetText("Instance"):Tooltip("Select instance to update")

	do
		InstanceDropDown:SetText(Instances[DEFAULT_INSTANCE])
		local function InstanceDropDown_SetValue(_, arg)
			DEFAULT_INSTANCE = arg
			ELib:DropDownClose()
			InstanceDropDown:SetText(Instances[DEFAULT_INSTANCE])
			UpdatePage()
		end
		local List = InstanceDropDown.List
		for id, name in pairs(Instances) do
			List[#List + 1] = {
				text = name,
				arg1 = id,
				func = InstanceDropDown_SetValue,
			}
		end
	end


	local DifficultyDropDown = ELib:DropDown(self.tab.tabs[2], 130, 2):Point("TOPLEFT", InstanceDropDown, "TOPRIGHT", 5,
		0):Size(130, 20):SetText("Difficulty"):Tooltip("Select difficulty to update")

	do
		DifficultyDropDown:SetText(Difficulties[DEFAULT_DIFFICULTY])
		local function DifficultyDropDown_SetValue(_, arg)
			DEFAULT_DIFFICULTY = arg
			ELib:DropDownClose()
			DifficultyDropDown:SetText(Difficulties[DEFAULT_DIFFICULTY])
			UpdatePage()
		end
		local List = DifficultyDropDown.List
		for id, name in pairs(Difficulties) do
			List[#List + 1] = {
				text = name,
				arg1 = id,
				func = DifficultyDropDown_SetValue,
			}
		end
	end


	local function sortByName(a, b)
		if a and b and a.name and b.name then
			return a.name < b.name
		end
	end

	function UpdatePage()
        if ExRT.isClassic then return end
		UpdateButton:Enable()

		local journalInstanceID = InstanceIDtoJournalInstanceID[DEFAULT_INSTANCE]
		EJ_SelectInstance(journalInstanceID)

		local bosses = {}
		for i = 1, 20 do
			local name = EJ_GetEncounterInfoByIndex(i, journalInstanceID)
			if not name then break end

			bosses[#bosses + 1] = {
				name = name,
			}
		end

		local sortedTable = {}

		for i = 1, #bosses do
			sortedTable[#sortedTable + 1] = bosses[i]
		end
		mainScroll.ScrollBar:Range(0, max(0, #sortedTable * LINE_HEIGHT - 1 - PAGE_HEIGHT), nil, true)

		local namesList, namesList2 = {}, {}
		for _, name, _, class in ExRT.F.IterateRoster do
			namesList[#namesList + 1] = {
				name = name,
				class = class,
			}
		end
		sort(namesList, sortByName)

		if #namesList <= VERTICALNAME_COUNT then
			raidSlider:Hide()
			prevPlayerCol = 0
		else
			raidSlider:Show()
			raidSlider:Range(0, #namesList - VERTICALNAME_COUNT)
		end

		local raidNamesUsed = 0
		for i = 1 + prevPlayerCol, #namesList do
			raidNamesUsed = raidNamesUsed + 1
			if not raidNames[raidNamesUsed] then
				break
			end
			local name = ExRT.F.delUnitNameServer(namesList[i].name)
			raidNames[raidNamesUsed]:SetText(name)
			raidNames[raidNamesUsed]:SetTextColor(ExRT.F.classColorNum(namesList[i].class))
			namesList2[raidNamesUsed] = name
			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
		end
		for i = raidNamesUsed + 1, #raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
		end

		local lineNum = 1
		local backgroundLineStatus = (prevTopLine % 2) == 1


		for i = prevTopLine + 1, #sortedTable do
			local boss = sortedTable[i]
			local line = lines[lineNum]
			if not line then
				break
			end
			line:Show()
			line.name:SetText(" " .. (boss.name or ""))
			line.db = boss
			line.t:SetShown(backgroundLineStatus)

			for j = 1, VERTICALNAME_COUNT do
				local pname = namesList2[j] or "-"
				local db

				for name, DB in pairs(module.db.responces) do
					if name == pname or name:find("^" .. pname) then
						db = DB
						break
					end
				end

				if not db then
					SetIcon(line.icons[j], 0)
				elseif db then
					if db[DEFAULT_INSTANCE] and
						db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY] and
						type(db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY]) == 'table' and
						db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY][boss.name] ~= nil
					then
						local isKilled = db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY][boss.name]
						if isKilled then
							SetIcon(line.icons[j], 2)
						else
							SetIcon(line.icons[j], 1)
						end
					elseif db[DEFAULT_INSTANCE] and
						db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY] and
						db[DEFAULT_INSTANCE][DEFAULT_DIFFICULTY] == 'NO_ID_INFO'
					then
						SetIcon(line.icons[j], 1)
					else
						SetIcon(line.icons[j], 0)
					end
				end

				if module.ShowHoverIcons then
					line.icons[j].hoverFrame.HOVER_TEXT = nil
					line.icons[j].hoverFrame.name = pname
					line.icons[j].hoverFrame:Show()
				else
					line.icons[j].hoverFrame.HOVER_TEXT = nil
					line.icons[j].hoverFrame:Hide()
				end
			end
			backgroundLineStatus = not backgroundLineStatus
			lineNum = lineNum + 1
		end
		for i = lineNum, #lines do
			lines[i]:Hide()
		end
	end

	self.UpdatePage = UpdatePage

	function self:OnShow()
		UpdatePage()
	end

	-----------------------
	-----------------------
	-----------------------
	do
		local CurrentInviter --name

		local UpdateInviterListButton = ELib:mStyledButton(self.tab.tabs[3], "Обновить список инвайтеров")
		:Point("TOPLEFT", self.tab.tabs[3], "TOPLEFT", 5, -5):Size(285, 20):OnClick(function(self)
			wipe(module.db.invitersReady)
			ExRT.F.SendExMsg("GInv", "G")
		end)

		local InvitersDropDown = ELib:DropDown(self.tab.tabs[3], 220, 25):Point("TOPLEFT", UpdateInviterListButton,
			"BOTTOMLEFT", 0, -5):Size(285, 20):SetText("Choose Inviter")

		local function InvitersDropDown_SetValue(_, arg)
			ELib:DropDownClose()
			InvitersDropDown:SetText(arg)
			CurrentInviter = arg
		end

		local function SetInviteIcon(self, type)
			if not type or type == 0 then
				self:SetAlpha(0)
			elseif type == 1 then
				self:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
				self:SetAlpha(1)
			elseif type == 2 then
				self:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
				self:SetAlpha(1)
			end
		end

		function module:UpdateInvitersDropDown()
			local List = InvitersDropDown.List
			wipe(List)
			for name in pairs(module.db.invitersReady) do
				local faction = UnitFactionGroup(name)
				List[#List + 1] = {
					text = (faction == "Horde" and "|cffff0000" or faction == "Alliance" and "|cff0080ff" or "") .. name,
					arg1 = name,
					func = InvitersDropDown_SetValue,
				}
			end
		end

		local Fields = {}
		for i = 1, 18 do
			Fields[i] = {}
			Fields[i]["Edit"] = ELib:Edit(self.tab.tabs[3]):Point("TOPLEFT", self.tab.tabs[3], "TOPLEFT", 5, -80 - i * 25)
			:Size(200, 20):OnChange(function(self)
				local text = self:GetText()

				if text == "" then
					text = nil
				end
			end)

			Fields[i]["Button"] = ELib:mStyledButton(self.tab.tabs[3], "Invite"):Point("LEFT", Fields[i]["Edit"], "RIGHT", 5,
				0):Size(80, 20):OnClick(function(self)
				local text = Fields[i]["Edit"]:GetText()
				if text == "" then
					text = nil
				end
				module:InviteSingle(i)
			end)
			Fields[i]["Icon"] = CreateFrame("Frame", nil, Fields[i]["Button"])
			Fields[i]["Icon"].t = Fields[i]["Icon"]:CreateTexture(nil, "ARTWORK")
			Fields[i]["Icon"].t:SetPoint("LEFT", Fields[i]["Button"], "RIGHT", 5, 0)
			Fields[i]["Icon"].t:SetSize(16, 16)
			SetInviteIcon(Fields[i]["Icon"].t, 0)
		end
		local multiInvite
		local MultiLineEditField = ELib:MultiEdit(self.tab.tabs[3]):Point("BOTTOMRIGHT", self, "BOTTOMRIGHT", -10, 38)
		:Size(530, 445):OnChange(function(self)
			local text = self:GetText()

			if text == "" then
				text = nil
			end
			multiInvite = text
		end)
		do
			ELib:Border(MultiLineEditField, 1, .24, .25, .30, 1)
			local msgFont, msgFontSize, msgFontStyle = MultiLineEditField.EditBox:GetRegions():GetFont()
			MultiLineEditField:Font(msgFont, 14, msgFontStyle)
			ELib:DecorationLine(MultiLineEditField, true, "BACKGROUND", 4):Point("TOPLEFT", MultiLineEditField, "TOPLEFT",
				0, 0):Point("BOTTOMRIGHT", MultiLineEditField, "BOTTOMRIGHT", 0, 0):SetVertexColor(0.0, 0.0, 0.0, 0.35)
		end
		local InviteAllFromListButton = ELib:mStyledButton(self.tab.tabs[3], "Invite All From List"):Point("TOPLEFT",
			MultiLineEditField, "BOTTOMLEFT", 0, -5):Size(264, 24):OnClick(function(self)
			if not CurrentInviter then
				return
			end
			module:InviteMulti()
		end)

		local ProcessToSingularInvitesButton = ELib:mStyledButton(self.tab.tabs[3], "Process To Singular Invites"):Point(
		"TOPLEFT", InviteAllFromListButton, "TOPRIGHT", 3, 0):Size(264, 24):OnClick(function(self)
			-- if not CurrentInviter then
			-- 	return
			-- end
			local data = { strsplit("\n", multiInvite) }
			for i = 1, #data do
				Fields[i].Edit:SetText(string.trim(data[i]))
			end
		end)

		local InviteAllButton = ELib:mStyledButton(self.tab.tabs[3], "Invite All"):Point("BOTTOMLEFT", self, "BOTTOMLEFT", 5,
			10):Size(285, 24):OnClick(function(self)
			if not CurrentInviter then
				return
			end
			module:InviteAll()
		end)

		local function PromoteBeforeInvite(name)
			shortName = ExRT.F.delUnitNameServer(name)

			if shortName == UnitName('player') then
				return
			end

			if ExRT.F.IsPlayerRLorOfficer(name) then
				return
			end

			PromoteToAssistant(name)

			if module.demoteTimer then
				module.demoteTimer:Cancel()
			end

			module.demoteTimer = ExRT.F.ScheduleTimer(DemoteAssistant, 5, name)
		end

		function module:InviteMulti()
			if not CurrentInviter then
				return
			end

			local list = ""
			local data = { strsplit("\n", multiInvite) }

			if not data or #data == 0 then
				return
			end

			for i = 1, #data do
				local text = string.trim(data[i])
				list = list .. (text ~= "" and text .. "\t" or "")
			end

			list = list:gsub("\t$", "")

			PromoteBeforeInvite(CurrentInviter)
			ExRT.F.SendExMsg("GInv", "I\t" .. CurrentInviter .. "\t" .. list)
		end

		function module:InviteSingle(i)
			if not CurrentInviter then
				return
			end

			local text = string.trim(Fields[i]["Edit"]:GetText())

			if not text or text == "" then return end

			PromoteBeforeInvite(CurrentInviter)
			ExRT.F.SendExMsg("GInv", "I\t" .. CurrentInviter .. "\t" .. text)
		end

		function module:InviteAll()
			if not CurrentInviter then
				return
			end

			local list = ""

			for i = 1, #Fields do
				local text = string.trim(Fields[i]["Edit"]:GetText())
				list = list .. (text ~= "" and text .. "\t" or "")
			end

			if list == "" then return end

			list = list:gsub("\t$", "")

			PromoteBeforeInvite(CurrentInviter)
			ExRT.F.SendExMsg("GInv", "I\t" .. CurrentInviter .. "\t" .. list)
		end

		ELib:DecorationLine(self.tab.tabs[3], true, "BACKGROUND", -5):Point("TOPLEFT", self, "TOPLEFT", 0, -140):Point(
		"BOTTOMRIGHT", self, "TOPRIGHT", 0, -141)
		ELib:DecorationLine(self.tab.tabs[3], true, "BACKGROUND", -5):Point("TOPLEFT", self, "TOPLEFT", 300, -140):Point(
		"BOTTOMRIGHT", self, "BOTTOMLEFT", 301, -0)
		ExRT.F.SendExMsg("GInv", "G")
	end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	VExRT.NoteChecker = VExRT.NoteChecker or {}
	VExRT.NoteChecker.NoteBackups = VExRT.NoteChecker.NoteBackups or {}

	module:RegisterAddonMessage()
end

-- CHAT_MSG_SYSTEM - "Игрок с именем %s не найден"
-- CHAT_MSG_SYSTEM - "%s уже состоит в группе"
-- UI_ERROR_MESSAGE - 85 - "Вы не можете пригласить в группу собственного персонажа"
-- UI_ERROR_MESSAGE - 708 - "Вы не можете пришлашать игроков из этого игрового мира"
-- UI_ERROR_MESSAGE - 310 - "Цель недружелюбна"



local UI_ERRORS = {
	ERR_NOT_LEADER, ERR_NOT_IN_GROUP, ERR_GROUP_FULL, ERR_QUEST_PUSH_NOT_IN_PARTY_S, ERR_INVITE_SELF,
	ERR_CROSS_REALM_RAID_INVITE, ERR_DECLINE_GROUP_S, ERR_GUILD_NOT_ALLIED,  ERR_INVITE_RESTRICTED_TRIAL,
	ERR_INVITE_IN_COMBAT, ERR_INVITE_UNKNOWN_REALM, ERR_INVITE_NO_PARTY_SERVER, ERR_INVITE_PARTY_BUSY,
	ERR_PARTY_PRIVATE_GROUP_ONLY, ERR_CLUB_FINDER_ERROR_TYPE_NO_INVITE_PERMISSIONS, ERR_ALREADY_IN_GROUP_S,
	ERR_PLAYER_WRONG_FACTION,
}
for k,v in ipairs(UI_ERRORS) do
	UI_ERRORS[v] = true
end

function module.main:UI_ERROR_MESSAGE(errorID, errorMessage)
	if UI_ERRORS[errorMessage] then
		ExRT.F.SendExMsg("GInv", "ERR\t"..module.db.lastInviteReqester .."\t".. errorMessage)
	end
end

function module.main:CHAT_MSG_SYSTEM(...)
	local errorMessage = ...
	if errorMessage:find(ERR_BAD_PLAYER_NAME_S:gsub("%%s","[^ ]+")) or errorMessage:find(ERR_ALREADY_IN_GROUP_S:gsub("%%s","[^ ]+")) then
		ExRT.F.SendExMsg("GInv", "ERR\t"..module.db.lastInviteReqester .."\t".. errorMessage)
	end
end

local function RegisterInviteErrorEvents()
	module:RegisterEvents("CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE")
end

local function UnregisterInviteErrorEvents()
	module:UnregisterEvents("CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE")
end


function module:CreateLockoutInfo(RequestedInstanceID, RequestedDifficultyID)
	local LockoutInfo = ""
	local numSavedInstances = GetNumSavedInstances()
	for i = 1, numSavedInstances do
		local name, lockoutID, reset, difficultyID, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID =
		GetSavedInstanceInfo(i)
		if instanceID == RequestedInstanceID and difficultyID == RequestedDifficultyID then
			LockoutInfo = instanceID .. "^" .. difficultyID .. "^"
			for j = 1, numEncounters do
				local bossName, fileDataID, isKilled, unknown4 = GetSavedInstanceEncounterInfo(i, j)
				if isKilled and locked then
					LockoutInfo = LockoutInfo .. "1"
				else
					LockoutInfo = LockoutInfo .. "0"
				end
			end
			break
		end
	end
	if LockoutInfo == "" then
		LockoutInfo = RequestedInstanceID .. "^" .. RequestedDifficultyID .. "^" .. "NO_ID_INFO"
	end
	return LockoutInfo
end

function module:ParseLockoutInfo(string)
    if ExRT.isClassic then return end
	local instanceID, difficultyID, bosses = string:match("^(%d+)%^(%d+)%^(.+)$")

	if not instanceID then
		return
	end

	instanceID = tonumber(instanceID)
	difficultyID = tonumber(difficultyID)

	local journalInstanceID = InstanceIDtoJournalInstanceID[instanceID]

	if not journalInstanceID then
		return
	end

	EJ_SelectInstance(journalInstanceID) --EJ_GetEncounterInfoByIndex

	if bosses == "NO_ID_INFO" then
		return instanceID, difficultyID, "NO_ID_INFO"
	end
	local numEncounters = #bosses
	local bossKills = {}
	for i = 1, numEncounters do
		local name = EJ_GetEncounterInfoByIndex(i, journalInstanceID)
		bossKills[name] = bosses:sub(i, i) == "1"
	end
	return instanceID, difficultyID, bossKills
end

local function SaveNoteBackup()
	local text = ExRT.F.GetNote()
	if text ~= "" then
		tinsert(VExRT.NoteChecker.NoteBackups, 1, ExRT.F.GetNote())
	end

	module.db.throttleTimer = nil
	while #VExRT.NoteChecker.NoteBackups > 5 do
		tremove(VExRT.NoteChecker.NoteBackups, 6)
	end
end

function module:ProcessInvite(name,sender)
	print("|cff0088ff[Group Inviter]|r |cffffff00" .. sender .. " Requested Invite: " .. name)
	C_PartyInfo.InviteUnit(name)
end

function module:addonMessage(sender, prefix, prefix2, ...)
	if prefix == "multiline" then
		if VExRT.Note.OnlyPromoted and IsInRaid() and not ExRT.F.IsPlayerRLorOfficer(sender) then
			return
		end

		if not module.db.throttleTimer then
			module.db.throttleTimer = ExRT.F.ScheduleTimer(SaveNoteBackup, 4)
		end
	elseif prefix == "RaidLockouts" then --ExRT.F.SendExMsg("RaidLockouts","R\t"..DEFAULT_INSTANCE.."\t"..DEFAULT_DIFFICULTY)
		if prefix2 == "R" then        --request
			--create lockout info and send it with SendExMsg
			local instanceID, difficultyID = ...
			local lockoutInfo = module:CreateLockoutInfo(tonumber(instanceID), tonumber(difficultyID))
			ExRT.F.SendExMsg("RaidLockouts", "S\t" .. lockoutInfo)
		elseif prefix2 == "S" then --send
			--parse lockout info and save it
			local lockoutInfo = ...
			local instanceID, difficultyID, bossKills = module:ParseLockoutInfo(lockoutInfo)
			if instanceID then
				module.db.responces[sender] = module.db.responces[sender] or {}
				module.db.responces[sender][instanceID] = module.db.responces[sender][instanceID] or {}
				module.db.responces[sender][instanceID][difficultyID] = bossKills
			end
			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage()
			end
		end
	elseif prefix == "GInv" then
		if prefix2 == "G" then
			ExRT.F.SendExMsg("GInv", "R")
		elseif prefix2 == "R" then
			sender = ExRT.F.delUnitNameServer(sender)
			module.db.invitersReady[sender] = true
			if module.options:IsVisible() and module.UpdateInvitersDropDown then
				module:UpdateInvitersDropDown()
			end
		elseif prefix2 == "I" then
			local currMsg = table.concat({ ... }, "\t")

			local data = { strsplit("\t", currMsg) }

			local inviter = data[1]
			inviter = ExRT.F.delUnitNameServer(inviter)
			if inviter ~= UnitName("player") then
				return
			end
			module.db.lastInviteReqester = sender
			RegisterInviteErrorEvents()
			sender = ExRT.F.delUnitNameServer(sender)

			for i = 2, #data do
				module:ProcessInvite(data[i],sender)
			end

			if module.db.UnregisterTimer then
				module.db.UnregisterTimer:Cancel()
			end
			module.db.UnregisterTimer = ExRT.F.ScheduleTimer(UnregisterInviteErrorEvents, 2)
		elseif prefix2 == "ERR" then

			local requester, errorMsg = ...
			requester = ExRT.F.delUnitNameServer(requester)
			if requester ~= UnitName("player") then
				return
			end
			print("|cff0088ff[Group Inviter]|r |cffff0000" .. ExRT.F.delUnitNameServer(sender) .. " Error:|r |cffffff00" .. errorMsg)
		end
	end
end

