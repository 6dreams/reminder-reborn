-- local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class MLib
AddonDB.MLib = {}

---@class Locale
local LR = AddonDB.LR

---@class ELib
local ELib = MRT.lib

---@class MLib
local MLib = AddonDB.MLib

local btn_clr1, btn_clr2 = CreateColor(0.12,0.12,0.12,1), CreateColor(0.14,0.14,0.14,1)
local function SetVertical(self)
	self._SetVertical(self)
	self.Texture:SetGradient("HORIZONTAL",btn_clr1, btn_clr2)
	return self
end

---@param parent Frame The parent frame to which the button will be added
---@param text string The text to display on the button
---@param textSize number? text size, will default to 13 if not provided
---@return ELibButton
function MLib:Button(parent,text,textSize)
	if not textSize then textSize = 13 end
	local button = ELib:Button(parent,text)
	button.Texture:SetGradient("VERTICAL",btn_clr1, btn_clr2)
	local fontObject = button:GetFontString()
	if fontObject then
		fontObject:SetFont(fontObject:GetFont(), textSize, "OUTLINE")
	end

	button._SetVertical = button.SetVertical
	button.SetVertical = SetVertical

	return button
end

function MLib:DropDownButton(...)
	local button = ELib:DropDownButton(...)
	button.Texture:SetGradient("VERTICAL",btn_clr1, btn_clr2)
	local fontObject = button:GetFontString()
	if fontObject then
		fontObject:SetFont(fontObject:GetFont(), 13, "OUTLINE")
	end
	return button
end

local function TabFrameUpdateTabs(self)
	for i = 1, #self.tabs do
		local button = self.tabs[i].button
		local fontString = button:GetFontString()
		if i == self.selected then
			button.Select(button)
			fontString:SetFont(fontString:GetFont(), 13, "OUTLINE")
		else
			button.Deselect(button)
			fontString:SetFont(fontString:GetFont(), 13)
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

--- Create a tabs frame
---@param parent Frame The parent frame to which the tabs will be added
---@param template string The template to use for the tabs
---@param ... string Tab names
---@return ELibTabs
function MLib:Tabs(parent, template, ...)
	local newTabs = ELib:Tabs(parent, template, ...)

	-- Init for new tabs
	newTabs.totalPlaced = 0
	newTabs.TabByName = {}
	for i = 1, #newTabs.tabs do
		local button = newTabs.tabs[i].button
		local fontString = button:GetFontString()
		if button.ButtonState then
			fontString:SetFont(fontString:GetFont(), 13, "OUTLINE")
		else
			fontString:SetFont(fontString:GetFont(), 13)
		end
		local fontStringWidth = fontString:GetStringWidth()
		newTabs.resizeFunc(button, 0, nil, nil, fontStringWidth, fontStringWidth)
	end

	-- Replacing Update Tabs function to match new style

	newTabs.UpdateTabs = TabFrameUpdateTabs

	for i=1,newTabs.tabCount do
		newTabs.tabs[i].button:Hide()
	end

	local function SetupTab(text)
		newTabs.totalPlaced = newTabs.totalPlaced + 1
		local currentTabNum = newTabs.totalPlaced
		local tab = newTabs.tabs[currentTabNum]
		newTabs.TabByName[text] = tab

		tab.button:Show()
		tab.button:SetText(text)
		local fontStringWidth = tab.button:GetFontString():GetStringWidth()
		tab.button:Resize(0,nil,nil,fontStringWidth,fontStringWidth)
		-- tab:SetAllPoints(parent,true)
		tab:SetPoint("BOTTOMRIGHT",parent,"BOTTOMRIGHT",0,0)
		return tab
	end
	newTabs.SetupTab = SetupTab

	newTabs:SetBackdropBorderColor(0, 0, 0, 0)
	newTabs:SetBackdropColor(0, 0, 0, 0)
	return newTabs
end

--- Create a tabs frame
---@param parent Frame The parent frame to which the tabs will be added
---@param template string|number? The template to use for the tabs
---@param ... string Tab names
---@return ELibTabs
function MLib:Tabs2(parent,template,...)
	local newTabs = ELib:Tabs(parent,template,...) --(self, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)

	for i=1,#newTabs.tabs do
		local button = newTabs.tabs[i].button
		local fontString = button:GetFontString()
		if button.ButtonState then
			fontString:SetFont(fontString:GetFont(), 13, "OUTLINE")
		else
			fontString:SetFont(fontString:GetFont(), 13)
		end
		local fontStringWidth = fontString:GetStringWidth()
		newTabs.resizeFunc(button, 0, nil, nil, fontStringWidth, fontStringWidth)
	end

	newTabs.UpdateTabs = TabFrameUpdateTabs

	newTabs:SetBackdropBorderColor(0,0,0,0)
	newTabs:SetBackdropColor(0,0,0,0)
	return newTabs
end

local function MultiEdit_TooltipRechek(self)
	self = self.Parent or self
	if not self:IsMouseOver(0, 0, -2, 2) then
		GameTooltip_Hide()
		self:SetScript("OnUpdate",nil)
		self.hookForTip = nil
	end
end

local function Widget_Tooltip_OnEnter(self)
	self = self.Parent or self
	if self.lockTooltipText then
		return
	end
	if type(self.tooltipText) == "function" then
		local text = self.tooltipText(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(text)
		GameTooltip:Show()
	elseif type(self.tooltipText) == "string" then
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:SetText(self.tooltipText)
		GameTooltip:Show()
	end
	if not self.hookForTip then
		self.hookForTip = true
		self:SetScript("OnUpdate",MultiEdit_TooltipRechek)
	end
end

local function MultiEdit_Tooltip(self,text)

	self.C.Parent = self
	self.ScrollBar.Parent = self
	self.ScrollBar.buttonUP.Parent = self
	self.ScrollBar.buttonDown.Parent = self

	self:SetScript("OnEnter",Widget_Tooltip_OnEnter)
	self.EditBox:SetScript("OnEnter",Widget_Tooltip_OnEnter)
	self.C:SetScript("OnEnter",Widget_Tooltip_OnEnter)
	self.ScrollBar:SetScript("OnEnter",Widget_Tooltip_OnEnter)
	self.ScrollBar.buttonUP:SetScript("OnEnter",Widget_Tooltip_OnEnter)
	self.ScrollBar.buttonDown:SetScript("OnEnter",Widget_Tooltip_OnEnter)

	self:SetScript("OnLeave",MultiEdit_TooltipRechek)
	self.EditBox:SetScript("OnLeave",MultiEdit_TooltipRechek)
	self.C:SetScript("OnLeave",MultiEdit_TooltipRechek)
	self.ScrollBar:SetScript("OnLeave",MultiEdit_TooltipRechek)
	self.ScrollBar.buttonUP:SetScript("OnLeave",MultiEdit_TooltipRechek)
	self.ScrollBar.buttonDown:SetScript("OnLeave",MultiEdit_TooltipRechek)

	self.tooltipText = text

	return self
end

local function MultiEdit_ColorBorder(self,r,g,b,a)
	if type(r) == 'boolean' then
		if r then
			r,g,b,a = 1,0,0,1
		else
			r,g,b,a = 0.24,0.25,0.30,1
		end
	elseif not r then
		r,g,b,a = 0.24,0.25,0.30,1
	end
	ELib:Border(self,1,r,g,b,a)
end

local function MultilineEditBoxOnTextChanged(self,...)
	local parent = self.Parent
	local height = self:GetHeight()

	local prevMin,prevMax = parent.ScrollBar:GetMinMaxValues()
	local changeToMax = parent.ScrollBar:GetValue() >= prevMax

	parent:SetNewHeight( max( height,parent:GetHeight() ) )
	if changeToMax then
		local min,max = parent.ScrollBar:GetMinMaxValues()
		parent.ScrollBar:SetValue(max)
	end

	-- toogle mouse wheel
	if parent.ScrollBar:IsVisible() then
		parent:EnableMouseWheel(true)
	else
		parent:EnableMouseWheel(false)
	end

	if parent.OnTextChanged then
		parent.OnTextChanged(self,...)
	elseif self.OnTextChanged then
		self:OnTextChanged(...)
	end

	if parent.SyntaxOnEdit then
		parent:SyntaxOnEdit()
	end

	-- auto resize
	if parent.minSize and parent.maxSize then
		local current_text_height = self:GetHeight()
		local lastCharIsNewLine = self:GetText():sub(-1) == "\n"
		local _, fontsize = self:GetFont()
		parent:SetHeight(math.min(math.max(parent.minSize, current_text_height + (lastCharIsNewLine and (fontsize or 14) or 0)), parent.maxSize))
	end
end

---@param self ELibMultiEdit
---@param fontSize number
---@return ELibMultiEdit
local function MultiEditFontSize(self,fontSize)
	local font,_,fontStyle = self.EditBox:GetFont()
	self.EditBox:SetFont(font,fontSize,fontStyle)
	return self
end

function MLib:MultiEdit(parent,minSize,maxSize)
	local newMultiEdit = ELib:MultiEdit(parent)
	newMultiEdit.EditBox:OnChange(MultilineEditBoxOnTextChanged)
	newMultiEdit.Tooltip = MultiEdit_Tooltip
	newMultiEdit.ColorBorder = MultiEdit_ColorBorder
	newMultiEdit.FontSize = MultiEditFontSize

	if minSize and maxSize then
		newMultiEdit.minSize = minSize
		newMultiEdit.maxSize = maxSize
		newMultiEdit.ScrollBar:Size(12,0)
		newMultiEdit.ScrollBar.thumb:SetHeight(20)
	end
	newMultiEdit:EnableMouseWheel(false)

	newMultiEdit.Background = newMultiEdit:CreateTexture(nil,"BACKGROUND")
	newMultiEdit.Background:SetColorTexture(0,0,0,.3)
	newMultiEdit.Background:SetPoint("TOPLEFT")
	newMultiEdit.Background:SetPoint("BOTTOMRIGHT")

	ELib:Border(newMultiEdit,1,.24,.25,.30,1)
	return newMultiEdit
end

do
	local function AlertIcon_OnEnter(self)
		if not self.tooltip then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		if self.tooltipTitle then
			GameTooltip:AddLine(self.tooltipTitle)
		end
		if type(self.tooltip) == "table" then
			for i=1,#self.tooltip do
				local line = self.tooltip[i]
				if type(line) == "table" then
				   if line.isDouble then
						GameTooltip:AddDoubleLine(unpack(line))
					else
						GameTooltip:AddLine(unpack(line))
					end
				else
					GameTooltip:AddLine(line,1,1,1,true)
				end
			end
		else
			GameTooltip:AddLine(self.tooltip,1,1,1,true)
		end
		GameTooltip:Show()
	end
	local function AlertIcon_OnLeave(self)
		GameTooltip_Hide()
	end
	local function AlertIcon_SetType(self,typeNum)
		if typeNum == 1 then
			self.outterCircle:SetVertexColor(.7,.15,.08,1)
			self.innerCircle:SetVertexColor(.9,0,.24,1)
			self.tooltip = LR.AlertFieldReq
		elseif typeNum == 2 then
			self.outterCircle:SetVertexColor(.75,.6,0,1)
			self.innerCircle:SetVertexColor(.95,.8,.1,1)
			self.tooltip = LR.AlertFieldSome
		elseif typeNum == 3 then
			self.outterCircle:SetVertexColor(.5,.7,.7,1)
			self.innerCircle:SetVertexColor(.7,.9,.9,1)
			self.text:SetText("?")
		end
	end

	function MLib:CreateAlertIcon(parent,tooltip,tooltipTitle,posRight,isButton)
		local self = CreateFrame(isButton and "Button" or "Frame",nil,parent)
		self:SetSize(20,20)

		local outterCircle = self:CreateTexture(nil,"BACKGROUND",nil,1)
		outterCircle:SetPoint("TOPLEFT")
		outterCircle:SetPoint("BOTTOMRIGHT")
		outterCircle:SetTexture([[Interface\AddOns\MRT\media\circle256]])
		outterCircle:SetVertexColor(.7,.15,.08,1)
		self.outterCircle = outterCircle

		local innerCircle = self:CreateTexture(nil,"BACKGROUND",nil,2)
		innerCircle:SetPoint("TOPLEFT",3,-3)
		innerCircle:SetPoint("BOTTOMRIGHT",-3,3)
		innerCircle:SetTexture([[Interface\AddOns\MRT\media\circle256]])
		innerCircle:SetVertexColor(.9,0,.24,1)
		self.innerCircle = innerCircle

		local text = self:CreateFontString(nil,"BACKGROUND","GameFontWhite",3)
		text:SetPoint("CENTER")
		text:SetFont(MRT.F.defFont,14, "")
		text:SetText("!")
		text:SetShadowColor(0,0,0)
		text:SetShadowOffset(1,-1)
		self.text = text

		self:SetScript("OnEnter",AlertIcon_OnEnter)
		self:SetScript("OnLeave",AlertIcon_OnLeave)

		self.SetType = AlertIcon_SetType

		self.tooltip = tooltip
		self.tooltipTitle = tooltipTitle
		if posRight then
			self:SetPoint("LEFT",parent,"RIGHT",3,0)
		end

		self:Hide()

		return self
	end
end


function MLib:CreateModuleHeader(options)
	options.discordText = ELib:Text(options,AddonDB.VersionStringShort,13):Point("BOTTOMLEFT",options.title,"BOTTOMRIGHT",5,2)

	options.headerFields = {}
	for i, data in ipairs(AddonDB.externalLinks) do
		options.headerFields[#options.headerFields+1] = ELib:Edit(options):Size(210,18):Point("LEFT",options.discordText,"RIGHT",80,0):Tooltip(data.tooltip):LeftText(data.name,12):OnChange(function(self)
			self:SetText(data.url)
		end):OnFocus(function(self)
			self:SetText(data.url)
			self:HighlightText()
		end)
		options.headerFields[#options.headerFields]:SetScript("OnKeyDown", function(self, key)
			if key == "C" and IsControlKeyDown() then
				C_Timer.After(0.2, function()
					print("Copied to clipboard: " .. self:GetText())
					self:ClearFocus()
					self:HighlightText(0,0)
				end)
			end
		end)
		options.headerFields[#options.headerFields]:SetText(data.url)
		local font = {options.headerFields[#options.headerFields]:GetFont()}
		options.headerFields[#options.headerFields]:SetFont(font[1], 12, font[3])
	end
end

do
	local function SetBorderColor(self,colorR,colorG,colorB,colorA,layerCounter)
		layerCounter = layerCounter or ""

		self["border_top"..layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
		self["border_bottom"..layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
		self["border_left"..layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
		self["border_right"..layerCounter]:SetColorTexture(colorR,colorG,colorB,colorA)
	end
	function MLib:Border(parent,size,colorR,colorG,colorB,colorA,outside,layerCounter)
		outside = outside or 0
		layerCounter = layerCounter or ""
		if size == 0 then
			if parent["border_top"..layerCounter] then
				parent["border_top"..layerCounter]:Hide()
				parent["border_bottom"..layerCounter]:Hide()
				parent["border_left"..layerCounter]:Hide()
				parent["border_right"..layerCounter]:Hide()
			end
			return
		end

		local textureOwner = parent.CreateTexture and parent or parent:GetParent()

		local top = parent["border_top"..layerCounter] or textureOwner:CreateTexture(nil, "BORDER")
		local bottom = parent["border_bottom"..layerCounter] or textureOwner:CreateTexture(nil, "BORDER")
		local left = parent["border_left"..layerCounter] or textureOwner:CreateTexture(nil, "BORDER")
		local right = parent["border_right"..layerCounter] or textureOwner:CreateTexture(nil, "BORDER")

		top:SetSnapToPixelGrid(false)
		top:SetTexelSnappingBias(0)
		bottom:SetSnapToPixelGrid(false)
		bottom:SetTexelSnappingBias(0)
		left:SetSnapToPixelGrid(false)
		left:SetTexelSnappingBias(0)
		right:SetSnapToPixelGrid(false)
		right:SetTexelSnappingBias(0)

		parent["border_top"..layerCounter] = top
		parent["border_bottom"..layerCounter] = bottom
		parent["border_left"..layerCounter] = left
		parent["border_right"..layerCounter] = right

		top:ClearAllPoints()
		bottom:ClearAllPoints()
		left:ClearAllPoints()
		right:ClearAllPoints()

		PixelUtil.SetPoint(top,"TOPLEFT",parent,"TOPLEFT",-size-outside,size+outside)
		PixelUtil.SetPoint(top,"BOTTOMRIGHT",parent,"TOPRIGHT",size+outside,outside)

		PixelUtil.SetPoint(bottom,"BOTTOMLEFT",parent,"BOTTOMLEFT",-size-outside,-size-outside)
		PixelUtil.SetPoint(bottom,"TOPRIGHT",parent,"BOTTOMRIGHT",size+outside,-outside)

		PixelUtil.SetPoint(left,"TOPLEFT",parent,"TOPLEFT",-size-outside,outside)
		PixelUtil.SetPoint(left,"BOTTOMRIGHT",parent,"BOTTOMLEFT",-outside,-outside)

		PixelUtil.SetPoint(right,"TOPLEFT",parent,"TOPRIGHT",outside,outside)
		PixelUtil.SetPoint(right,"BOTTOMRIGHT",parent,"BOTTOMRIGHT",size+outside,-outside)

		top:SetColorTexture(colorR,colorG,colorB,colorA)
		bottom:SetColorTexture(colorR,colorG,colorB,colorA)
		left:SetColorTexture(colorR,colorG,colorB,colorA)
		right:SetColorTexture(colorR,colorG,colorB,colorA)

		parent.SetBorderColor = SetBorderColor

		top:Show()
		bottom:Show()
		left:Show()
		right:Show()
	end
end

function MLib:Popup(...)
	local popup = ELib:Popup(...)
	popup.Close.NormalTexture:SetVertexColor(1,0,0,1)
	popup.border:Hide()
	MLib:Border(popup,1,.24,.25,.30,1,nil,3)

	return popup
end

--- Popup dialogs system(thanks to taint)

do
	local GetNearestPixelSize = PixelUtil.GetNearestPixelSize
	local function Scale(desiredPixels)
		return GetNearestPixelSize(desiredPixels, UIParent:GetEffectiveScale())
	end

	---@class PopupDialogButtonInfo
	---@field text string The text to display on the button
	---@field func function? The function to call when the button is clicked
	---@field disabled boolean? Whether the button should be disabled

	---@class PopupDialogEditBoxInfo
	---@field text string? The initial text in the edit box
	---@field background string? The background text to display when the edit box is empty
	---@field onChange function? The function to call when the text in the edit box changes

	---@class PopupDialogData
	---@field id string? The unique identifier for the button, used to release it later
	---@field title string The title of the popup dialog
	---@field text string? The main text of the popup dialog
	---@field buttons PopupDialogButtonInfo[]? The buttons in the dialog
	---@field editBox PopupDialogEditBoxInfo? The edit box in the dialog
	---@field OnUpdate function? The function for OnUpdate script
	---@field alert boolean? Whether the dialog should have an alert style (red border)
	---@field minWidth number? The minimum width of the dialog


	local buttonsPool = {
		unused = {},
		used = {},
		Acquire = function(self)
			---@type ELibButton
			local button = tremove(self.unused) or self:CreateNew()
			if button then
				tinsert(self.used, button)
			end
			return button
		end,
		Release = function(self, button)
			if button then
				if button:IsShown() then
					button:Hide()
				end
				button:SetParent(nil)
				tinsert(self.unused, button)
				tDeleteItem(self.used, button)
				self.func = nil
			end
		end,
		CreateNew = function(self)
			local button = MLib:Button(nil, " ", 13)
			button:SetScript("OnClick", function(self)
				local parent = self:GetParent()
				if self.func then
					xpcall(self.func, geterrorhandler(), parent) -- it is possible that release event was triggered here
				end
				if parent and parent:IsShown() then
					parent:Hide() -- triggers release
				end

			end)
			return button
		end,
	}
	local editBoxPool = {
		unused = {},
		used = {},
		Acquire = function(self)
			---@type ELibEdit
			local editBox = tremove(self.unused) or self:CreateNew()
			if editBox then
				tinsert(self.used, editBox)
			end
			return editBox
		end,
		Release = function(self, editBox)
			if editBox then
				if editBox:IsShown() then
					editBox:Hide()
				end
				editBox:SetParent(nil)
				tinsert(self.unused, editBox)
				tDeleteItem(self.used, editBox)
				editBox.onChange = nil
				editBox.background = nil
				editBox:SetText("")
			end
		end,
		CreateNew = function(self)
			local editBox = ELib:Edit(nil):OnChange(function(_self, isUser)
				_self:BackgroundText(_self:GetText() == "" and _self.background or "")

				if _self.onChange then
					_self.onChange(_self, isUser)
				end
			end)
			-- editBox:SetAutoFocus(true)

			return editBox
		end,
	}

	local dialogPool = {
		unused = {},
		used = {},
		unique = {},
		Acquire = function(self, id)
			if id and self.unique[id] then
				self:Release(self.unique[id])
			end

			---@type ELibPopup
			local dialog = tremove(self.unused) or self:CreateNew()
			if dialog then
				if tContains(self.used, dialog) then
					error("Dialog already in use: " .. tostring(id) .. tostring(dialog))
				end
				tinsert(self.used, dialog)
				if id then
					dialog.id = id
					self.unique[id] = dialog
				end
			end

			self:RepositionDialogs()
			return dialog
		end,
		Release = function(self, dialog)
			if dialog and tContains(self.used, dialog) then
				if dialog:IsShown() then
					local hideScript = dialog:GetScript("OnHide")
					dialog:SetScript("OnHide", nil) -- prevent recursion
					dialog:Hide()
					dialog:SetScript("OnHide", hideScript)
				end
				if dialog.id then
					self.unique[dialog.id] = nil
				end

				tinsert(self.unused, dialog)
				tDeleteItem(self.used, dialog)
				-- also release its children
				for _, button in ipairs(dialog.buttons) do
					if button then
						buttonsPool:Release(button)
					end
				end
				dialog.buttons = {}

				if dialog.editBox then
					editBoxPool:Release(dialog.editBox)
					dialog.editBox = nil
				end
				dialog.popupData = nil

				self:RepositionDialogs()
			end
		end,
		CreateNew = function(self)
			local dialog = MLib:Popup("")
			PixelUtil.SetSize(dialog, 300, 100) -- we need to set size here to validate rectangle so we can properly calculate bounds of children
			dialog:SetScript("OnHide", function(_self)
				self:Release(_self)
			end)
			dialog.desc = ELib:Text(dialog, ""):Point("TOP", 0, -35):Point("LEFT", 10, 0):Point("RIGHT", -10, 0):Center():Top():Color() -- :Size(290,250)
			dialog.desc:SetWordWrap(true)
			dialog.desc:SetNonSpaceWrap(true)
			dialog.Close:Hide()

			dialog:RegisterForDrag()
			dialog:SetScript("OnDragStart", nil)
			dialog:SetScript("OnDragStop",nil)

			dialog:SetFrameStrata("FULLSCREEN_DIALOG")
			dialog:SetFrameLevel(8000)

			return dialog
		end,
		HideByID = function(self, id)
			if self.unique[id] then
				self:Release(self.unique[id])
			end
		end,
		RepositionDialogs = function(self)
			for i, dialog in ipairs(self.used) do
				dialog:ClearAllPoints()
				if i == 1 then
					-- dialog:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
					PixelUtil.SetPoint(dialog, "CENTER", UIParent, "CENTER", 0, 300)
				else
					-- dialog:SetPoint("TOP", self.used[i - 1], "BOTTOM", 0, -10)
					PixelUtil.SetPoint(dialog, "TOP", self.used[i - 1], "BOTTOM", 0, -10)
				end
			end
		end,
	}

	function MLib:DialogPopupHide(id)
		if id then
			dialogPool:HideByID(id)
		end
	end

	local BUTTONS_PADDING = 20
	local BOTTOM_MARGIN = 12
	local BUTTON_HEIGHT = 20
	local DEFAULT_BUTTON_WIDTH = 100


	---@param popupData PopupDialogData
	function MLib:DialogPopup(popupData)
		local dialog = dialogPool:Acquire(popupData.id)
		dialog.popupData = popupData
		dialog.title:SetText(popupData.title or "Popup")
		dialog.desc:SetText(popupData.text or "")

		if popupData.alert then
			MLib:Border(dialog,2,1,.25,.30,1,-2,4)
		else
			MLib:Border(dialog,0,1,.25,.30,1,-2,4) -- alpha 0
		end

		local height = 80
		local width = BUTTONS_PADDING

		dialog.buttons = {}
		if popupData.buttons then
			for i, buttonData in ipairs(popupData.buttons) do
				local button = buttonsPool:Acquire()
				button:SetParent(dialog)
				button:Show()

				button:SetText(buttonData.text)
				local buttonWidth = max(button:GetTextWidth() + BUTTONS_PADDING, DEFAULT_BUTTON_WIDTH)

				width = width + buttonWidth + BUTTONS_PADDING
				button:SetSize(buttonWidth, BUTTON_HEIGHT)

				button.func = buttonData.func

				button:ClearAllPoints()
				if #popupData.buttons == 1 then
					button:SetPoint("BOTTOM", dialog, "BOTTOM", 0, BOTTOM_MARGIN)
				elseif #popupData.buttons == 2 then
					if #dialog.buttons == 0 then -- 1
						button:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -BUTTONS_PADDING/2, BOTTOM_MARGIN)
					else -- 2
						button:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", BUTTONS_PADDING/2, BOTTOM_MARGIN)
					end
				else
					if #dialog.buttons == 0 then
						button:SetPoint("BOTTOMLEFT", dialog, "BOTTOMLEFT", BUTTONS_PADDING, BOTTOM_MARGIN)
					else
						button:SetPoint("BOTTOMLEFT", dialog.buttons[#dialog.buttons], "BOTTOMRIGHT", BUTTONS_PADDING, 0)
					end
				end
				tinsert(dialog.buttons, button)
			end
		end

		if popupData.editBox then
			local editBoxData = popupData.editBox
			local editBox = editBoxPool:Acquire()
			editBox:SetParent(dialog)
			editBox:Show()
			editBox:ClearAllPoints()
			editBox:SetPoint("BOTTOM", dialog, "BOTTOM", 0, Scale(BOTTOM_MARGIN + BUTTON_HEIGHT + BOTTOM_MARGIN))
			editBox:SetSize(Scale(200), Scale(BUTTON_HEIGHT))
			editBox:SetText(editBoxData.text or "")
			editBox.background = editBoxData.background
			editBox.onChange = editBoxData.onChange
			editBox:BackgroundText(editBox.background)
			dialog.editBox = editBox

			height = height + BUTTON_HEIGHT + BOTTOM_MARGIN
		end

		if popupData.OnUpdate then
			dialog:SetScript("OnUpdate", popupData.OnUpdate)
		else
			dialog:SetScript("OnUpdate", nil)
		end

		width = max(width, popupData.minWidth or 300)

		PixelUtil.SetWidth(dialog, width) -- set width first so we can calculate height properly

		height = height + dialog.desc:GetStringHeight()
		PixelUtil.SetHeight(dialog, height)

		dialog:Show()
	end
end



--[[

this thing actually works, just not used at the moment
does not support font, justifyH, edit and slider

do

	local function CheckSubMenu(_,button)
		if button:CanOpenSubmenu() then
			button:ForceOpenSubmenu()
		end
	end

	---@param tooltip GameTooltip
	---@param elementDescription ElementMenuDescriptionProxy
	local function MenuSetTooltip(tooltip,elementDescription)
		local data = elementDescription:GetData()
		local tip = data.tooltip
		local text
		if type(tip) == "function" then
			text = tip(tooltip,elementDescription)
		else
			text = tip
		end
		if text then
			tooltip:AddLine(text)
		end
	end

	local MenuHoverFunc = function(frame, elementDescription)
		local data = elementDescription:GetData()
		if data.hoverFunc then
			data.hoverFunc(frame, data.hoverArg)
		end
	end

	local MenuLeaveFunc = function(frame, elementDescription)
		local data = elementDescription:GetData()
		if data.leaveFunc then
			data.leaveFunc(frame, data)
		end
	end

	local MenuIsSelected = function(data)
		if data.checkState then
			return data.checkState
		end
		return false
	end

	local MenuClickFunc = function(data)
		if data.func then
			return data.func(data, data.arg1, data.arg2, data.arg3, data.arg4)
		end
	end


	-- NO WORK :(
	-- ---@param frame Frame
	-- ---@param elementDescription RootMenuDescriptionProxy
	-- local MenuInitializerFunc = function(frame,elementDescription)
	-- 	local data = elementDescription:GetData()
	-- 	local fontString = frame.fontString
	-- 	if data.font then
	-- 		local font, size, style = fontString:GetFont()
	-- 		fontString:SetFont(data.font, size, style)
	-- 		print("SetFont",data.font)
	-- 	end
	-- 	if data.justifyH then
	-- 		fontString:SetJustifyH(data.justifyH)
	-- 		print("SetJustifyH",data.justifyH)
	-- 	end
	-- end


	local extent = 20
	local maxCharacters = 12
	local maxScrollExtent = extent * maxCharacters

	---@param dropdown any
	---@param elementDescription RootMenuDescriptionProxy
	local function MenuProcessor(dropdown,elementDescription,data)
		data.dropdown = dropdown

		if dropdown.width then
			elementDescription:SetMinimumWidth(dropdown.width)
		end

		if data.isHidden then
			return
		end

		local text = data.text
		if data.colorCode then
			text = data.colorCode..text.."|r"
		end
		if data.atlas then
			text = "|A:"..data.atlas..":"..extent..":"..(data.iconsize or extent).."|a "..text
		elseif data.icon then
			if data.iconcoord then -- actual coords
				text = "|T"..data.icon..":"..extent..":"..(data.iconsize or extent)..":"..data.iconcoord[1]..":"..data.iconcoord[2]..":"..data.iconcoord[3]..":"..data.iconcoord[4].."|t "..text
			elseif data.customcoord then -- set coords to 0,1,0,1
				text = "|T"..data.icon..":"..extent..":"..(data.iconsize or extent)..":0:1:0:1|t "..text
			else
				text = "|T"..data.icon..":"..extent..":"..(data.iconsize or extent).."|t "..text
			end
		end

		local element
		if data.isTitle then
			element = elementDescription:CreateTitle(text)
		elseif data.isSpacer then
			element = elementDescription:CreateSpacer()
		elseif data.isDivider then
			element = elementDescription:CreateDivider()
		elseif data.checkable then
			element = elementDescription:CreateCheckbox(text,MenuIsSelected,MenuClickFunc,data)
		elseif data.radio then
			element = elementDescription:CreateRadio(text,MenuIsSelected,MenuClickFunc,data)
		-- elseif data.edit then
		-- 	element = elementDescription:CreateTemplate("EditBox")
		else
			element = elementDescription:CreateButton(text,MenuClickFunc,data)
		end

		element:SetData(data)


		-- if data.font or data.justifyH  then
		-- 	element:AddInitializer(MenuInitializerFunc)
		-- end

		if data.isDisabled then
			element:SetEnabled(false)
		end

		if data.tooltip then -- has to be set before any HookOnEnter
			element:SetTooltip(MenuSetTooltip)
		end

		if data.subMenu then
			if data.Lines and #data.subMenu > data.Lines then
				element:SetScrollMode(extent*data.Lines)
			end

			element:HookOnEnter(CheckSubMenu)
			for i,subData in ipairs(data.subMenu) do
				MenuProcessor(dropdown,element,subData)
			end
		end

		if data.hoverFunc then
			element:HookOnEnter(MenuHoverFunc)
		end
		if data.leaveFunc then
			element:HookOnLeave(MenuLeaveFunc)
		end
	end


	local menuGenerator = function(ownerRegion,rootDescription)
		if ownerRegion.Lines and #ownerRegion.List > ownerRegion.Lines then
			rootDescription:SetScrollMode(extent*ownerRegion.Lines)
		end
		for i,data in ipairs(ownerRegion.List) do
			MenuProcessor(ownerRegion,rootDescription,data)
		end
	end

	local function OnDropDownButtonClick(self)
		local dropdown = self:GetParent()
		if dropdown.PreUpdate then
			dropdown:PreUpdate()
		end
		MenuUtil.CreateContextMenu(dropdown,menuGenerator)
	end

	function MLib:DropDown(...)
		local dropdown = ELib:DropDown(...)
		dropdown.Button:SetScript("OnClick",OnDropDownButtonClick)
		return dropdown
	end
end--]]
