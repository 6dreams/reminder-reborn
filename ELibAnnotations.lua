---@meta _

--- This file is AI generated so it may contain errors and may not be complete.


---@class ELib
local ELib = {}

---@class ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self



---@class ELibBorder : Frame
local Border = {}

--- Create a border around a parent frame
---@param parent Frame|Texture The parent frame to which the border will be added or texture which parent will be used
---@param size number The size (thickness) of the border
---@param colorR number? The red component of the border color (0-1)
---@param colorG number? The green component of the border color (0-1)
---@param colorB number? The blue component of the border color (0-1)
---@param colorA number? The alpha (transparency) component of the border color (0-1)
---@param outside number? Whether the border should be outside the parent frame
---@param layerCounter number The layer counter for the border
---@return ELibText
function ELib:Border(parent, size, colorR, colorG, colorB, colorA, outside, layerCounter) end



---@class ELibText : FontString, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Text = {}

--- Create a text frame
---@param parent Frame The parent frame to which the text will be added
---@param text string The text to display
---@param size number The size of the text
---@param template string The template to use for the text
---@return ELibText
function ELib:Text(parent, text, size, template) end

--- Set the font of the text
---@param ... any The font parameters
---@return self
function Text:Font(...) end

--- Set the color of the text
---@param r number The red component of the color
---@param g number The green component of the color
---@param b number The blue component of the color
---@return self
function Text:Color(r, g, b) end

--- Add or remove shadow from the text
---@param bool boolean Whether to remove the shadow
---@return self
function Text:Shadow(bool) end

--- Add or remove outline from the text
---@param bool boolean Whether to remove the outline
---@return self
function Text:Outline(bool) end

--- Set the text justification to left
---@return self
function Text:Left() end

--- Set the text justification to center
---@return self
function Text:Center() end

--- Set the text justification to right
---@return self
function Text:Right() end

--- Set the text vertical alignment to top
---@return self
function Text:Top() end

--- Set the text vertical alignment to middle
---@return self
function Text:Middle() end

--- Set the text vertical alignment to bottom
---@return self
function Text:Bottom() end

--- Set the font size of the text
---@param size number The size of the font
---@return self
function Text:FontSize(size) end

--- Add a tooltip if the text is cropped
---@param anchor string The anchor point for the tooltip
---@param isBut boolean Whether the text is a button
---@return self
function Text:Tooltip(anchor, isBut) end

---@param num number
function Text:MaxLines(num) end



---@class ELibButton : Button, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field GetTextObj fun(self : ELibButton): FontString
---@field FontSize fun(self : ELibButton, size: number): self
---@field SetVertical fun(self : ELibButton): self
local Button = {}

--- Create a button
---@param parent Frame The parent frame to which the button will be added
---@param text string The text to display on the button
---@param template string|number? The template to use for the button
---@return ELibButton
function ELib:Button(parent, text, template) end

--- -> [add tooltip]
---@overload fun(self: ELibButton, str: string): self
---@overload fun(self: ELibButton, textFunc: fun(self) : string?): self
function Button:Tooltip(...) end



---@class Check : CheckButton, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Check = {}

--- Create a check button
---@param parent Frame The parent frame to which the check button will be added
---@param text string The text to display next to the check button
---@param state boolean The initial state of the check button (checked or unchecked)
---@param template string The template to use for the check button
---@return Check
function ELib:Check(parent, text, state, template) end

--- Add a tooltip to the check button
---@param str string The tooltip text
---@return self
function Check:Tooltip(str) end

--- Move the text to the left side of the check button
---@param relativeX number The relative X position for the text (default is 2)
---@return self
function Check:Left(relativeX) end

--- Set the text size of the check button
---@param size number The size of the text
---@return self
function Check:TextSize(size) end

---@param isBorderInsteadText boolean
function Check:ColorState(isBorderInsteadText) end

--- Add red/green colors for text or borders based on the state
---@param isBorderInsteadText boolean Whether to color the borders instead of the text
---@return self
function Check:AddColorState(isBorderInsteadText) end

--- Set the text to be clickable
---@return self
function Check:TextButton() end



---@class ELibDropDown : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field Enable fun(self : ELibDropDown): self
---@field Disable fun(self : ELibDropDown): self
---@field SetWidth fun(self : ELibDropDown, width : number): self
---@field _SetWidth fun(self : ELibDropDown, width)
local DropDown = {}

--- Create a dropdown menu
---@param parent Frame The parent frame to which the dropdown menu will be added
---@param width number The width of the dropdown menu
---@param lines number The amount of lines to display in the dropdown menu -1 will display all lines
---@param template string The template to use for the dropdown menu
---@return ELibDropDown
function ELib:DropDown(parent, width, lines, template) end

--- Set the text of the dropdown menu
---@param str string The text to set
---@return self
function DropDown:SetText(str) end

--- Add a tooltip to the dropdown menu
---@param str string The tooltip text
---@return self
function DropDown:Tooltip(str) end

--- Add text to the left side of the dropdown menu
---@param text string The text to add
---@return self
function DropDown:AddText(text) end

---@param text string
---@param size number?
---@param extra_func fun(self:ELibText)
---@return self
function DropDown:TextInside(text,size,extra_func) end

--- Set the width of the dropdown menu
---@param width number The width to set
---@return self
function DropDown:Size(width) end

--- -> Set colors for the border; [true: red; false: default]
---@overload fun(self : ELibEdit, bool: boolean): self : ELibDropDown
---@overload fun(self : ELibEdit, cR: number, cG: number, cB: number, cA: number): self : ELibDropDown
function DropDown:ColorBorder(...) end

--- calls PreUpdate if it exists and scans .List for the value
---@param value any
---@param key any defaults to "arg1"
---@param includeSubMenus boolean?
function DropDown:AutoText(value, key, includeSubMenus) end



---@class ELibDropDownButton : ELibButton, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local DropDownButton = {}

--- Create a dropdown button
---@param parent Frame The parent frame to which the dropdown button will be added
---@param defText string The default text to display on the dropdown button
---@param dropDownWidth number The width of the dropdown menu
---@param lines number? The lines (options) to display in the dropdown menu
---@param template string The template to use for the dropdown button
---@return ELibDropDownButton
function ELib:DropDownButton(parent, defText, dropDownWidth, lines, template) end



---@class ELibEdit : EditBox, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Edit = {}

--- Create an edit box
---@param parent Frame The parent frame to which the edit box will be added
---@param maxLetters number? The maximum number of letters allowed in the edit box
---@param onlyNum boolean? Whether the edit box should only accept numeric input
---@param template string The template to use for the edit box
---@return ELibEdit
function ELib:Edit(parent, maxLetters, onlyNum, template) end

--- -> SetText(str)
---@param str string
---@return self
function Edit:Text(str) end

--- -> [add tooltip]
---@param str string|fun(self) : string?
---@return self
function Edit:Tooltip(str) end

--- -> SetScript("OnTextChanged",func)
---@param func fun(self : ELibEdit, isUser: boolean)
---@return self
function Edit:OnChange(func) end

--- -> SetScript("OnFocusGained",gained) SetScript("OnEditFocusLost",lost)
---@param gained function
---@param lost function
---@return self
function Edit:OnFocus(gained, lost) end

--- -> Add an icon inside the edit box
---@param texture string|number
---@param size number [optional]
---@param offset number [optional]
---@return self
function Edit:InsideIcon(texture, size, offset) end

--- -> Add a search icon inside the edit box
---@return self
function Edit:AddSearchIcon(size) end

--- -> Add text at the left of the edit box
---@param text string
---@param size number?
---@return self
function Edit:LeftText(text, size) end

--- -> Add text at the right of the edit box
--- @param text string
--- @param size number?
--- @return self
function Edit:RightText(text, size) end

--- -> Add text at the top left of the edit box, conflicts with :LeftText
---@param text string
---@param size number?
function Edit:TopText(text, size) end

--- -> Add text inside the edit box while not in focus
---@param text string
---@return self
function Edit:BackgroundText(text) end

--- -> Set colors for the border; [true: red; false: default]
---@overload fun(self : ELibEdit, bool: boolean): self : ELibEdit
---@overload fun(self : ELibEdit, cR: number, cG: number, cB: number, cA: number): self : ELibEdit
function Edit:ColorBorder(...) end

---@return number highlightStart
---@return number highlightEnd
function Edit:GetTextHighlight() end

--- -> Add text background after the main text
---@param text string
---@return self
function Edit:ExtraText(text) end

---@param size number
---@return self
function Edit:FontSize(size) end



---@class ELibFrame : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Frame = {}

--- Create a frame
---@param parent Frame The parent frame to which the new frame will be added
---@param template string The template to use for the frame
---@return ELibFrame
function ELib:Frame(parent, template) end

--- Create and/or set a texture
---@param texture string The texture to set
---@param layer DrawLayer The layer to set the texture on
---@return self
function Frame:Texture(texture, layer) end

--- Create and/or set a texture with color
---@param cR number The red component of the color
---@param cG number The green component of the color
---@param cB number The blue component of the color
---@param cA number The alpha component of the color
---@param layer DrawLayer The layer to set the texture on
---@return self
function Frame:Texture(cR, cG, cB, cA, layer) end

--- Add a point to the texture
---@param ... any The points to add to the texture
---@return self
function Frame:TexturePoint(...) end

--- Set the size of the texture
---@param ... any The size parameters to set for the texture
---@return self
function Frame:TextureSize(...) end



---@class ELibIcon : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field Tooltip fun(self,text): self
local Icon = {}

--- Create an icon
---@param parent Frame The parent frame to which the icon will be added
---@param textureIcon string The texture to use for the icon
---@param size number The size of the icon
---@param isButton boolean Whether the icon should behave as a button
---@return ELibIcon
function ELib:Icon(parent, textureIcon, size, isButton) end

--- Set the texture of the icon
---@overload fun(self : ELibIcon, texture: string|number): self
---@overload fun(self : ELibIcon, cR: number, cG: number, cB: number, cA: number): self
function Icon:Icon(...) end



---@class ELibListButton : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local ListButton = {}

--- Create a list button
---@param parent Frame The parent frame to which the list button will be added
---@param text string The text to display on the button
---@param width number The width of the button
---@param lines number The number of lines to display
---@param template string The template to use for the button
---@return ELibListButton
function ELib:ListButton(parent, text, width, lines, template) end

--- Move text to the left side
---@return self
function ListButton:Left() end



---@class ELibMultiEdit : ELibScrollFrame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field EditBox ELibEdit
---@field HideScrollOnNoScroll fun(self): self
local MultiEdit = {}

--- Create a multi-line edit box
---@param parent Frame The parent frame to which the multi-edit box will be added
---@return ELibMultiEdit
function ELib:MultiEdit(parent) end

--- Set the script for the "OnTextChanged" event
---@param func function The function to call when the text changes
---@return self
function MultiEdit:OnChange(func) end

--- Set the font for the multi-edit box
---@param ... any The font parameters to set
---@return self
function MultiEdit:Font(...) end

--- Enable hyperlinks in the text (spells, items, etc.)
---@return self
function MultiEdit:Hyperlinks() end

--- Set the scroll value to the minimum (scroll to top)
---@return self
function MultiEdit:ToTop() end

--- Get the highlight positions in the text
---@return number highlightStart
---@return number highlightEnd
function MultiEdit:GetTextHighlight() end

--- Add colored text syntax
---@param syntax "lua" | string | nil
---@return self
function MultiEdit:SetSyntax(syntax) end

--- Add an indicator at the bottom right that shows current line number:current column number
---@return self
function MultiEdit:AddPosText() end

---@return self
function MultiEdit:OnCursorChanged(func) end



---@class ELibOneTab : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local OneTab = {}

--- Create a tab
---@param parent Frame The parent frame to which the tab will be added
---@param text string The text to display on the tab
---@param isOld boolean Whether the tab is an old version
---@return ELibOneTab
function ELib:OneTab(parent, text, isOld) end



---@class ELibPopup : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Popup = {}

--- Create a popup
---@param title string The title of the popup
---@param template string The template to use for the popup
---@return ELibPopup
function ELib:Popup(title, template) end

---@return self
function Popup:AddScroll() end



---@class ELibRadio : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Radio = {}

--- Create a radio button
---@param parent Frame The parent frame to which the radio button will be added
---@param text string The text to display next to the radio button
---@param checked boolean Whether the radio button is initially checked
---@param template string The template to use for the radio button
---@return ELibRadio
function ELib:Radio(parent, text, checked, template) end

--- makes text clickable
---@return self
function Radio:AddButton() end

---@param str string
---@return self
function Radio:Tooltip(str) end



---@class ELibScrollBar : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local ScrollBar = {}

--- Create a scroll bar
---@param parent Frame The parent frame to which the scroll bar will be added
---@param isOld boolean Whether the scroll bar is an old version
---@return ELibScrollBar
function ELib:ScrollBar(parent, isOld) end

--- Set the minimum and maximum values of the scroll bar
---@param min number The minimum value
---@param max number The maximum value
function ScrollBar:Range(min, max) end

--- Set the scroll bar to a specific value
---@param value number The value to set the scroll bar to
---@return self
function ScrollBar:SetValue(value) end

--- Set the scroll bar to a specific value
---@param value number The value to set the scroll bar to
function ScrollBar:SetTo(value) end

---@return number value The current value of the scroll bar
function ScrollBar:GetValue() end

---@return number min, number max The minimum and maximum values of the scroll bar
function ScrollBar:GetMinMaxValues() end

---@return self
function ScrollBar:SetMinMaxValues(...) end

---sets script on the slider
---@param ... any
---@return self
function ScrollBar:SetScript(...) end

--- Set a function to be called when the scroll bar value changes
---@param func function The function to call on value change
function ScrollBar:OnChange(func) end

--- Update the states of the up and down buttons
function ScrollBar:UpdateButtons() end

--- Set the value range for clicks on the buttons
---@param i number The value range for clicks
function ScrollBar:ClickRange(i) end

---@return self
function ScrollBar:SetHorizontal() end

--- self.slider:SetObeyStepOnDrag(bool)
---@param bool boolean?
---@return self
function ScrollBar:SetObey(bool) end

---@return self
function ScrollBar:Minimal() end



---@class ELibScrollList : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local ScrollList = {}

--- Create a scroll list
---@param parent Frame The parent frame to which the scroll list will be added
---@param list table The list of items to display in the scroll list
---@return ELibScrollList
function ELib:ScrollList(parent, list) end

--- Update the scroll list
---@return self
function ScrollList:Update() end

--- Set the font size of the scroll list
---@param size number The font size to set
---@return self
function ScrollList:FontSize(size) end

---@param fontName string
---@param fontSize number
---@return self
function ScrollList:Font(fontName, fontSize) end

---@param height number
---@return self
function ScrollList:LineHeight(height) end

--- makes lines draggable
---@return self
function ScrollList:AddDrag() end

---@return self
function ScrollList:HideBorders() end

--- emulates a line click?
---@return self
function ScrollList:SetTo(value) end

---@alias buttonClick
---|"LeftButton"
---|"RightButton"
---|"MiddleButton"
---|"Button4"
---|"Button5"

--- Fires on line click, after SetListValue
---@param line Frame|Button
---@param button buttonClick?
---@param isDown boolean?
function ScrollList.AdditionalLineClick(line,button,isDown) end

--- Fires on line click, before AdditionalLineClick
---@param index number corresponding to the self.L[index]
---@param button buttonClick
---@param isDown boolean
function ScrollList:SetListValue(index,button,isDown) end


---@class ELibScrollCheckList : ELibScrollList, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local ScrollCheckList = {}

--- Create a scroll check list
---@param parent Frame The parent frame to which the scroll check list will be added
---@param list table The list of items to display in the scroll check list
---@return ELibScrollCheckList
function ELib:ScrollCheckList(parent, list) end

--- Update the scroll check list
function ScrollCheckList:Update() end

--- Set the font size of the scroll check list
---@param size number The font size to set
function ScrollCheckList:FontSize(size) end



---@class ELibScrollFrame : ScrollFrame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field SetNewHeight fun(self,height): self
---@field Height fun(self,height): self
---@field AddHorizontal fun(self, outside): self
---@field HideScrollOnNoScroll fun(self): self
local ScrollFrame = {}

--- Create a scroll frame
---@param parent Frame The parent frame to which the scroll frame will be added
---@param isOld boolean Whether the scroll frame is an old version
---@return ELibScrollFrame
function ELib:ScrollFrame(parent, isOld) end

--- Set the height of the scroll frame
---@param px number The height in pixels
function ScrollFrame:Height(px) end



---@class ELibScrollTableList : ELibScrollFrame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field T table
local ScrollTableList = {}

--- Create a scroll table list
---@param parent Frame The parent frame to which the scroll table list will be added
---@vararg number The widths of the columns, one of which must be 0
---@return ELibScrollTableList
function ELib:ScrollTableList(parent, ...) end

--- Update the scroll table list
---@return self
function ScrollTableList:Update() end

--- Set the font size of the scroll table list
---@param size number The font size to set
---@return self
function ScrollTableList:FontSize(size) end



---@class ScrollTabsFrame : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field list ELibScrollList
local ScrollTabsFrame = {}

--- Create a scroll tabs frame
---@param parent Frame The parent frame to which the scroll tabs frame will be added
---@vararg number The widths of the tabs, one of which must be 0
---@return ScrollTabsFrame
function ELib:ScrollTabsFrame(parent, ...) end



---@class ELibScrollButtonsList : ELibScrollFrame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
---@field Update fun(self,forceUpdate): self
---@field ResetScroll fun(self): self
local ScrollButtonsList = {}

--- Create a scroll buttons list
---@param parent Frame The parent frame to which the scroll buttons list will be added
---@return ELibScrollButtonsList
function ELib:ScrollButtonsList(parent) end



---@class ELibSlider : Slider, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Slider = {}

--- Create a slider
---@param parent Frame The parent frame to which the slider will be added
---@param text string The text label for the slider
---@param isVertical boolean Whether the slider is vertical
---@param template string The template to use for the slider
---@return ELibSlider
function ELib:Slider(parent, text, isVertical, template) end

--- Set the range of the slider
---@param min number The minimum value of the slider
---@param max number The maximum value of the slider
---@return self
function Slider:Range(min, max) end

--- Set the slider to a specific value
---@param value number The value to set the slider to
---@return self
function Slider:SetTo(value) end

--- Set the function to call when the slider value changes
---@param func function The function to call on value change
---@return self
function Slider:OnChange(func) end

--- Set the width of the slider
---@param width number The width to set
---@return self
function Slider:Size(width) end

--- Set whether the slider obeys step on drag
---@param bool boolean Whether to obey step on drag
---@return self
function Slider:SetObey(bool) end

---@param str string
---@return self
function Slider:Tooltip(str) end



---@class ELibSliderBox : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local SliderBox = {}

--- Create a slider box
---@param parent Frame The parent frame to which the slider box will be added
---@param list table The list of values for the slider box
---@return ELibSliderBox
function ELib:SliderBox(parent, list) end

--- Set the slider box to a specific value from the list
---@param value any The value to set the slider box to
---@return self
function SliderBox:SetTo(value) end



---@class ELibShadow : Frame
local Shadow = {}

--- Create a shadow frame
---@param parent Frame The parent frame to which the shadow will be added
---@param size number The size of the shadow
---@param edgeSize number The edge size of the shadow
---@return ELibShadow
function ELib:Shadow(parent, size, edgeSize) end



--- Create a shadow inside frame, no return
---@param parent Frame The parent frame to which the shadow inside will be added
---@param enableBorder boolean Whether to enable the border
---@param enableLine boolean Whether to enable the line
function ELib:ShadowInside(parent, enableBorder, enableLine) end



---@class ELibTabs : Frame, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Tabs = {}

--- Create a tabs frame
---@param parent Frame The parent frame to which the tabs will be added
---@param template string|number? The template to use for the tabs
---@param ... string Tab names
---@return ELibTabs
function ELib:Tabs(parent, template, ...) end

--- Set the tabs to a specific page
---@param page number The page to set the tabs to
---@return self
function Tabs:SetTo(page) end



---@class ELibTexture : Texture, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local Texture = {}

--- Create a texture
---@param parent Frame The parent frame to which the texture will be added
---@param texture string|nil The texture file path
---@param layer DrawLayer? The layer of the texture
---@return ELibTexture
function ELib:Texture(parent, texture, layer) end

--- Create a colored texture
---@param parent Frame The parent frame to which the texture will be added
---@param cR number The red component of the color
---@param cG number The green component of the color
---@param cB number The blue component of the color
---@param cA number The alpha component of the color
---@param layer DrawLayer? The layer of the texture
---@return Texture
function ELib:Texture(parent, cR, cG, cB, cA, layer) end

--- Set the vertex color of the texture
---@param r number The red component of the color
---@param g number The green component of the color
---@param b number The blue component of the color
---@param a number The alpha component of the color
---@return self
function Texture:Color(r, g, b, a) end

--- Set the texture coordinates
---@param ... any The texture coordinates
---@return self
function Texture:TexCoord(...) end

---@return self
function Texture:BlendMode(...) end

--- Set the gradient alpha of the texture
---@param ... any The gradient alpha parameters
---@return self
function Texture:Gradient(...) end

---@overload fun(self: ELibTexture, texture: string): self
---@overload fun(self: ELibTexture, cR: number, cG: number, cB: number, cA: number): self
function Texture:Texture(...) end

--- Set the atlas of the texture
---@param ... any The atlas parameters
---@return self
function Texture:Atlas(...) end

---@param layer DrawLayer
---@return self
function Texture:Layer(layer) end



---@class DecorationLine : Texture, ELibBaseMethods
---@field Point fun(self,point: FramePoint,relativeFrame,relativePoint: FramePoint,x,y): self
---@field Size fun(self,width:number,height:number): self
---@field NewPoint fun(self,point,relativeFrame,relativePoint,x,y): self
---@field Scale fun(self,scale): self
---@field OnClick fun(self,func): self
---@field OnShow fun(self,func,disableFirstRun : boolean?): self
---@field Run fun(self,func,...): self vararg will be passed to the function
---@field Shown fun(self,func): self
---@field OnEnter fun(self,func): self
---@field OnLeave fun(self,func): self
---@field OnUpdate fun(self,func): self
local DecorationLine = {}

--- Create a decoration line
---@param parent Frame The parent frame to which the decoration line will be added
---@param isGradient boolean Whether the decoration line is a gradient
---@param layer DrawLayer The layer of the decoration line
---@param layerCounter number The layer counter of the decoration line
---@return DecorationLine
function ELib:DecorationLine(parent,isGradient,layer,layerCounter) end



--- Hides the tooltip.
function ELib.Tooltip:Hide() end

--- Displays a standard tooltip based on self.tooltipText, anchored to anchorUser.
---@param anchorUser any
function ELib.Tooltip:Std(anchorUser) end

--- Displays a tooltip for hyperlinks, such as "item:9999" or "spell:774".
---@param data string
---@vararg any
function ELib.Tooltip:Link(data, ...) end

--- Shows a tooltip with a title and additional lines of text, anchored to anchorUser.
---@param anchorUser any
---@param title string
---@vararg any
function ELib.Tooltip:Show(anchorUser, title, ...) end

--- Displays a tooltip for links in edit boxes or simple HTML elements.
---@param linkData any
---@param link string
function ELib.Tooltip:Edit_Show(linkData, link) end

--- Handles clicks on links in edit boxes or simple HTML elements.
---@param linkData any
---@param link string
---@param button any
function ELib.Tooltip:Edit_Click(linkData, link, button) end

--- Adds additional tooltips; data is a table parameter.
---@param link string
---@param data table
---@param enableMultiline boolean
---@param disableTitle boolean
function ELib.Tooltip:Add(link, data, enableMultiline, disableTitle) end

--- Hides all additional tooltips.
function ELib.Tooltip:HideAdd() end



---@alias TemplateName string
---| "ExRTFontNormal"
---| "ExRTFontGrayTemplate"
---| "ExRTUIChatDownButtonTemplate"
---| "ExRTTranslucentFrameTemplate"
---| "ExRTDropDownMenuButtonTemplate"
---| "ExRTDropDownListTemplate"
---| "ExRTDropDownListModernTemplate"
---| "ExRTButtonTransparentTemplate"
---| "ExRTButtonModernTemplate"
---| "ExRTBWInterfaceFrame"
---| "ExRTTabButtonTransparentTemplate"
---| "ExRTTabButtonTemplate"
---| "ExRTDialogTemplate"
---| "ExRTDialogModernTemplate"
---| "ExRTDropDownMenuTemplate"
---| "ExRTDropDownMenuModernTemplate"
---| "ExRTInputBoxTemplate"
---| "ExRTInputBoxModernTemplate"
---| "ExRTSliderTemplate"
---| "ExRTSliderModernTemplate"
---| "ExRTSliderModernVerticalTemplate"
---| "ExRTTrackingButtonModernTemplate"
---| "ExRTCheckButtonModernTemplate"
---| "ExRTButtonDownModernTemplate"
---| "ExRTButtonUpModernTemplate"
---| "ExRTUIChatDownButtonModernTemplate"
---| "ExRTRadioButtonModernTemplate"

---@class ExRTFontNormal : Font
---@class ExRTFontGrayTemplate : Font
---@class ExRTUIChatDownButtonTemplate : Button
---@class ExRTTranslucentFrameTemplate : Frame
---@class ExRTDropDownMenuButtonTemplate : Button
---@class ExRTDropDownListTemplate : Frame
---@class ExRTDropDownListModernTemplate : Button
---@class ExRTButtonTransparentTemplate : Button
---@class ExRTButtonModernTemplate : ExRTButtonTransparentTemplate
---@class ExRTBWInterfaceFrame : Frame
---@class ExRTTabButtonTransparentTemplate : Button
---@class ExRTTabButtonTemplate : ExRTTabButtonTransparentTemplate
---@class ExRTDialogTemplate : Frame
---@class ExRTDialogModernTemplate : Frame
---@class ExRTDropDownMenuTemplate : Frame
---@class ExRTDropDownMenuModernTemplate : Frame
---@class ExRTInputBoxTemplate : EditBox
---@class ExRTInputBoxModernTemplate : EditBox
---@class ExRTSliderTemplate : Slider
---@class ExRTSliderModernTemplate : Slider
---@class ExRTSliderModernVerticalTemplate : Slider
---@class ExRTTrackingButtonModernTemplate : Frame
---@class ExRTCheckButtonModernTemplate : CheckButton
---@class ExRTButtonDownModernTemplate : ExRTButtonModernTemplate
---@class ExRTButtonUpModernTemplate : ExRTButtonModernTemplate
---@class ExRTUIChatDownButtonModernTemplate : ExRTButtonModernTemplate
---@class ExRTRadioButtonModernTemplate : CheckButton

---@alias MRTTemplate
---| ExRTFontNormal
---| ExRTFontGrayTemplate
---| ExRTUIChatDownButtonTemplate
---| ExRTTranslucentFrameTemplate
---| ExRTDropDownMenuButtonTemplate
---| ExRTDropDownListTemplate
---| ExRTDropDownListModernTemplate
---| ExRTButtonTransparentTemplate
---| ExRTButtonModernTemplate
---| ExRTBWInterfaceFrame
---| ExRTTabButtonTransparentTemplate
---| ExRTTabButtonTemplate
---| ExRTDialogTemplate
---| ExRTDialogModernTemplate
---| ExRTDropDownMenuTemplate
---| ExRTDropDownMenuModernTemplate
---| ExRTInputBoxTemplate
---| ExRTInputBoxModernTemplate
---| ExRTSliderTemplate
---| ExRTSliderModernTemplate
---| ExRTSliderModernVerticalTemplate
---| ExRTTrackingButtonModernTemplate
---| ExRTCheckButtonModernTemplate
---| ExRTButtonDownModernTemplate
---| ExRTButtonUpModernTemplate
---| ExRTUIChatDownButtonModernTemplate
---| ExRTRadioButtonModernTemplate

--- Create a template
--- @param name TemplateName The name of the template
--- @param parent frame The parent template
--- @return MRTTemplate
function ELib:Template(name,parent) end


---@class MRTmodule
---@field options table?
---@field main table
---@field db table
---@field name string
---@field CLEU table|Frame
---@field Event function
---@field EventProfiling function
---@field HookEvent function
---@field RegisterAddonMessage function
---@field RegisterEvents function
---@field RegisterHideOnPetBattle function
---@field RegisterMiniMapMenu function
---@field RegisterSlash function
---@field RegisterTimer function
---@field RegisterUnitEvent function
---@field UnregisterAddonMessage function
---@field UnregisterEvents function
---@field UnregisterMiniMapMenu function
---@field UnregisterSlash function
---@field UnregisterTimer function
