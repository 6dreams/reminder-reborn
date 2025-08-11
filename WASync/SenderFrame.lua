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

local bit_band = bit.band
local bit_bor = bit.bor
local bit_bxor = bit.bxor
local bit_lshift = bit.lshift

local COLOR_DEF = {CreateColor(0.12,0.12,0.12,1), CreateColor(0.14,0.14,0.14,1)}
local COLOR_RED = {CreateColor(0.52,0.12,0.12,1), CreateColor(0.64,0.14,0.14,1)}
local COLOR_GREEN = {CreateColor(0.12,0.52,0.12,1), CreateColor(0.14,0.64,0.14,1)}

-- used for debugging
-- local function decToBin(n)
--     if n == 0 then
--         return "0"
--     end
--     local bin = {}
--     while n > 0 do
--         local rem = n % 2
--         table.insert(bin, 1, rem)
--         n = math.floor(n / 2)
--     end
--     return table.concat(bin)
-- end

local default_update_config = module.getDefaultUpdateConfig()

function module:CreateSenderFrame()
	local SenderFrame = ELib:Popup("|cFF8855FFWeakAuras Sync Sender|r"):Size(400,370)
	module.SenderFrame = SenderFrame

	SenderFrame:SetFrameStrata("FULLSCREEN_DIALOG")

	ELib:DecorationLine(SenderFrame,true,"BACKGROUND",4):Point("TOPLEFT",SenderFrame,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SenderFrame,"TOPRIGHT",0,-20):SetVertexColor(0.13,0.13,0.13,0.3)--title background
	ELib:DecorationLine(SenderFrame,true,"BACKGROUND",5):Point("TOPLEFT",SenderFrame,"TOPLEFT",0,-20):Point("TOPRIGHT",SenderFrame,"TOPRIGHT",0,-20)--line between title and frame

	ELib:DecorationLine(SenderFrame,true,"BACKGROUND",4):Point("TOPLEFT",SenderFrame,"BOTTOMLEFT",0,50):Point("BOTTOMRIGHT",SenderFrame,"BOTTOMRIGHT",0,0):SetVertexColor(0.13,0.13,0.13,0.3)--save button background
	ELib:DecorationLine(SenderFrame,true,"BACKGROUND",5):Point("TOPLEFT",SenderFrame,"BOTTOMLEFT",0,50):Point("TOPRIGHT",SenderFrame,"BOTTOMRIGHT",0,50)--line between send button and frame

	SenderFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)
	SenderFrame.border:Hide()
	ELib:Border(SenderFrame,1,.24,.25,.30,1,nil,3)

	-- SenderFrame.HelpIcon = MLib:CreateAlertIcon(SenderFrame,LR.WASyncTip1,"|cFF00FF00Help:|r")
	-- SenderFrame.HelpIcon:SetPoint("TOPRIGHT",SenderFrame,"TOPRIGHT",-5,-25)
	-- SenderFrame.HelpIcon:Show()
	-- SenderFrame.HelpIcon:SetType(3)
	-- SenderFrame.HelpIcon:SetScale(1.2)

	local SenderFrameData = {}
	module.SenderFrameData = SenderFrameData

	if module.PUBLIC then
		SenderFrameData.importType = 1
	else
		SenderFrameData.importType = 3
	end
	SenderFrameData.id = ""

	SenderFrameData.updateConfig = module.getDefaultUpdateConfig()

	-- there is a mirror of this widget in module.importWindow
	SenderFrame.updateConfigDropDown = ELib:DropDown(SenderFrame,230,-1):Size(300,20):Point("BOTTOMLEFT",SenderFrame,"BOTTOMLEFT",10,110)
	SenderFrame.updateConfigText = ELib:Text(SenderFrame.updateConfigDropDown,LR["Categories to ignore when importing:"]):Point("BOTTOMLEFT",SenderFrame.updateConfigDropDown,"TOPLEFT",0,5):Color():Shadow()
	do
		local function config_SetValue(_,arg1)
			SenderFrameData.updateConfig = arg1
			-- update drop down text
			local text = ""
			for i=1,#WASync.update_categories do
				if bit_band(SenderFrameData.updateConfig or 0,bit_lshift(1,i-1)) > 0 then
					text = text .. (text == "" and "" or ", ") .. WASync.update_categories[i].label2
				end
			end
			-- update state cheks
			for i=1,#SenderFrame.updateConfigDropDown.List do
				local check = bit_band(SenderFrameData.updateConfig or 0,bit_lshift(1,i-1)) > 0
				SenderFrame.updateConfigDropDown.List[i].checkState = check

				local allMatch = true
				if SenderFrameData.id then
					local WAdata = WeakAuras.GetData(SenderFrameData.id)
					if WAdata then
						for d in module.pTraverseAll(WeakAuras.GetData(SenderFrameData.id)) do
							if (bit_band(d.exrtUpdateConfig or default_update_config,bit_lshift(1,i-1)) > 0) ~= check then
								allMatch = false
								break
							end
						end
					end
				end
				if allMatch then
					SenderFrame.updateConfigDropDown.List[i].colorCode = nil
				else
					SenderFrame.updateConfigDropDown.List[i].colorCode = "|cff0080ff"
				end
			end

			SenderFrame.updateConfigDropDown:SetText(text)
			if ELib.ScrollDropDown.DropDownList[1].parent == SenderFrame.updateConfigDropDown then
				SenderFrame.updateConfigDropDown.Button:Click()
				SenderFrame.updateConfigDropDown.Button:Click()
			end
		end
		SenderFrame.updateConfigDropDown.SetValue = config_SetValue

		local function applyConfigChanes(data,mask,newState)
			for d in module.pTraverseAll(data) do
				if newState then
					d.exrtUpdateConfig = bit_bor(d.exrtUpdateConfig or default_update_config, mask)
				else
					d.exrtUpdateConfig = bit_bxor(d.exrtUpdateConfig or default_update_config, mask)
				end
			end
		end

		local function config_SetCheck(self)
			local val = SenderFrameData.updateConfig or 0
			local arg1 = self.data.arg1
			local arg2 = self.data.arg2
			-- val is out bitfield
			-- arg1 is index of bit to change
			-- check state is new state of bit
			-- use bit functions to change bit
			local checkState = not (bit_band(val,bit_lshift(1,arg1)) > 0)

			if checkState then
				val = bit_bor(val,arg2)
			else
				val = bit_bxor(val,arg2)
			end
			local WAdata = WeakAuras.GetData(SenderFrameData.id)

			if WAdata then
				applyConfigChanes(WAdata,arg2,checkState)
			end

			config_SetValue(nil,val)
		end

		local function hoverFunc(self,hoverArg)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT",20)
			GameTooltip:AddLine(self:GetText())
			if hoverArg then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(hoverArg,1,1,1,true)
			end
			GameTooltip:Show()
		end

		local List = SenderFrame.updateConfigDropDown.List
		for i=1,#WASync.update_categories do
			local tooltipText = WASync.update_categories[i].fieldsTooltip or table.concat(MRT.F.TableToText(WASync.update_categories[i].fields),"\n")

			List[#List+1] = {
				text = WASync.update_categories[i].label,
				arg1 = i - 1,
				arg2 = 2^(i-1),
				func = config_SetCheck,
				checkable = true,
				checkFunc = config_SetCheck,
				hoverFunc = hoverFunc,
				hoverArg = tooltipText,
			}
		end
		SenderFrame.updateConfigDropDown:SetValue(SenderFrameData.updateConfig)
	end
	-- nil - save previous or inherit imported
	-- 1 - load never
	-- 2 - load always
	-- 3 - load never force
	-- 4 - load always force

	SenderFrame.defaultLoadNever = MLib:Button(SenderFrame.updateConfigDropDown,"Load Never"):Size(74,20):Point("LEFT",SenderFrame.updateConfigDropDown,"RIGHT",5,0):OnClick(function(self)
		if not SenderFrameData.id then return end
		local WAdata = WeakAuras.GetData(SenderFrameData.id)
		if WAdata then

			WAdata.exrtDefaultLoadNever = (WAdata.exrtDefaultLoadNever or 0) + 1
			if WAdata.exrtDefaultLoadNever >= 5 then
				WAdata.exrtDefaultLoadNever = nil
			end
			if WAdata.regionType == "group" or WAdata.regionType == "dynamicgroup" then
				for c in module.pTraverseAllChildren(WAdata) do
					c.exrtDefaultLoadNever = WAdata.exrtDefaultLoadNever
				end
			end
			self:SetValue(WAdata.exrtDefaultLoadNever)
			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage(true)
			end
		end
	end):Tooltip([[Inherit - use settings from previous or from imported
Never - sets load never on first import
Always - unchecks load never on first import
Never(F) - sets load never on import
Always(F) - unchecks load never on import]])

	function SenderFrame.defaultLoadNever:SetValue(val)
		local text = "Inherit"
		local color = COLOR_DEF

		if val == 1 then
			text = "Never"
			color = COLOR_RED
		elseif val == 2 then
			text = "Always"
			color = COLOR_GREEN
		elseif val == 3 then
			text = "Never(F)"
			color = COLOR_RED
		elseif val == 4 then
			text = "Always(F)"
			color = COLOR_GREEN
		end

		self.Texture:SetGradient("VERTICAL",unpack(color))
		self:SetText(text)

	end

	SenderFrame.customErrorHandler = MLib:Button(SenderFrame,LR["Custom EH"]):Size(74,20):Point("BOTTOM",SenderFrame.defaultLoadNever,"TOP",0,5):OnClick(function(self)
		if not SenderFrameData.id then return end
		local WAdata = WeakAuras.GetData(SenderFrameData.id)
		if WAdata then
			WAdata.rg_custom_error_handler = not WAdata.rg_custom_error_handler or nil
			if WAdata.regionType == "group" or WAdata.regionType == "dynamicgroup" then
				for c in module.pTraverseAllChildren(WAdata) do
					c.rg_custom_error_handler = WAdata.rg_custom_error_handler
				end
			end
		end
		self:Update()
	end):Shown(AddonDB.RGAPI and true or false):Tooltip(LR["Use custom error handler for this WA"])

	function SenderFrame.customErrorHandler:Update()
		if not SenderFrameData.id then return end
		local WAdata = WeakAuras.GetData(SenderFrameData.id)
		if WAdata and WAdata.rg_custom_error_handler then
			self.Texture:SetGradient("VERTICAL",unpack(COLOR_GREEN))
		else
			self.Texture:SetGradient("VERTICAL",unpack(COLOR_DEF))
		end
	end

	SenderFrame.needReloadCheck = ELib:Check(SenderFrame,LR["Ask for Reload UI after import"]):Point("BOTTOMLEFT",SenderFrame.updateConfigDropDown,"TOPLEFT",0,25):OnClick(function(self)
		SenderFrameData.needReload = self:GetChecked()
	end)

	SenderFrame.ImportTypeDropDown = ELib:DropDown(SenderFrame,230,#WASync.ImportTypes):Size(200,20):Point("BOTTOMLEFT",SenderFrame.needReloadCheck,"TOPLEFT",0,5)
	SenderFrame.ImportTypeText = ELib:Text(SenderFrame.ImportTypeDropDown,LR["Import Mode:"]):Size(140,20):Point("BOTTOMLEFT",SenderFrame.ImportTypeDropDown,"TOPLEFT",0,0):Color():Shadow()
	do
		local ImportSetValue = function(_,arg)
			ELib:DropDownClose()
			SenderFrameData.importType = arg
			SenderFrame:Update()
		end

		local List = SenderFrame.ImportTypeDropDown.List
		for i=1,#WASync.ImportTypes do
			List[#List+1] = {
				text = WASync.ImportTypes[i],
				arg1 = i,
				func = ImportSetValue,
			}
		end
	end

	SenderFrame.UpdateLastSyncCheck = ELib:Check(SenderFrame,LR["New Update"],VMRT.WASync.UpdateLastSync):Tooltip(LR["Update last sync time"]):Point("LEFT",SenderFrame.ImportTypeDropDown,"RIGHT",5,0):OnClick(function(self)
		VMRT.WASync.UpdateLastSync = self:GetChecked()
	end)

	SenderFrame.customTargetDropDown = ELib:DropDown(SenderFrame,230,10):Size(200,20):Point("BOTTOMLEFT",SenderFrame.ImportTypeDropDown,"TOPLEFT",0,25)
	-- SenderFrame.customTargetDropDown:HideBorders()
	-- SenderFrame.customTargetDropDown.Background:Hide()
	ELib:Text(SenderFrame.customTargetDropDown,LR["Send to:"]):Point("BOTTOMLEFT",SenderFrame.customTargetDropDown,"TOPLEFT",0,5):Color():Shadow()

	local function customTargetDropDown_SetValue(self,arg1,arg2, ignoreUpdate)
		SenderFrameData.customChannel = arg1
		SenderFrameData.customTarget = arg2

		SenderFrame.customTargetDropDown:SetText(self and ((self.data.colorCode or "") .. (self.data.text or "")) or "AUTO")
		ELib:DropDownClose()
		if SenderFrame.Update and not ignoreUpdate then
			SenderFrame:Update()
		end
	end
	customTargetDropDown_SetValue()

	function SenderFrame.customTargetDropDown:PreUpdate()
		local list = self.List
		wipe(list)

		list[#list+1] = {
			text = "AUTO",
			arg1 = nil,
			arg2 = nil,
			func = customTargetDropDown_SetValue,
			prio = 1,
		}
		list[#list+1] = {
			text = "GUILD",
			arg1 = "GUILD",
			arg2 = nil,
			colorCode =  "|cff3CE13F",
			func = customTargetDropDown_SetValue,
			prio = 2,
		}
		list[#list+1] = {
			text = "RAID/PARTY",
			arg1 = "RAID",
			arg2 = nil,
			colorCode = "|cffFF7D01",
			func = customTargetDropDown_SetValue,
			prio = 3,
		}
		list[#list+1] = {
			text = "PARTY",
			arg1 = "PARTY",
			arg2 = nil,
			colorCode = "|cff77C8FF",
			func = customTargetDropDown_SetValue,
			prio = 4,
		}

		for index, name, subgroup, class, guid, rank, level, online in MRT.F.IterateRoster do
			if online then
				local isHidden = (not WASync.isDebugMode and (name == MRT.SDB.charKey or name == MRT.SDB.charName))
				local key = isHidden and guid or #list+1 -- to not include hidden entries in array part to not screw the length

				local nick = AddonDB.RGAPI and AddonDB.RGAPI:ClassColorName(name) or AddonDB:ClassColorName(name) or name
				list[key] = {
					text = nick .. (" (whisper)"),
					arg1 = "WHISPER",
					arg2 = name,
					func = customTargetDropDown_SetValue,
					prio = 5,
				}
			end
		end
		sort(list,function(a,b)
			if a.prio == b.prio then
				return a.text < b.text
			else
				return a.prio < b.prio
			end
		end)

		self.Lines = min(#list,12)
	end

	SenderFrame.skipPrompt = ELib:Check(SenderFrame,"Skip Prompt",false):Tooltip("Force import, skipping import prompt"):Point("LEFT",SenderFrame.customTargetDropDown,"RIGHT",5,0):OnClick(function(self)
		SenderFrameData.skipPrompt = self:GetChecked()
	end):Shown(AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender("player"))

	SenderFrame.IDText = ELib:Text(SenderFrame,"ID:"):Size(380,20):Point("TOP",SenderFrame,"TOP",0,-30):Color():Shadow()
	SenderFrame.UIDText = ELib:Text(SenderFrame,"UID:"):Size(380,20):Point("TOPLEFT",SenderFrame.IDText,"BOTTOMLEFT",0,0):Color():Shadow()

	SenderFrame.exrtLastSyncText = ELib:Text(SenderFrame,"Last Sync:"):Size(380,20):Point("TOPLEFT",SenderFrame.UIDText,"BOTTOMLEFT",0,0):Color():Shadow()

	-- show when information.debugLog == true, disable untill specified player is selected
	SenderFrame.RequestDebugLog = MLib:Button(SenderFrame,LR["Get DebugLog"],15):Size(20,120):SetVertical():Point("TOPRIGHT",SenderFrame,"TOPRIGHT",-5,-30):OnClick(function()
		if SenderFrameData.id and SenderFrameData.customChannel == "WHISPER" and SenderFrameData.customTarget then
			module:RequestDebugLog(SenderFrameData.id,SenderFrameData.customTarget)
		end
	end):Shown(false)

	-- SenderFrame.versionText = ELib:Text(SenderFrame,"Version:"):Size(0,20):Point("TOPLEFT",SenderFrame.exrtLastSyncText,"BOTTOMLEFT",0,0):Color():Shadow()
	-- SenderFrame.versionEdit = ELib:Edit(SenderFrame,4,true):Size(40,16):Point("LEFT",SenderFrame.versionText,"RIGHT",5,0):OnChange(function(self)
	--     local WAData = WeakAuras.GetData(SenderFrameData.id or "")
	--     if WAData then
	--         local version = tonumber(self:GetText())
	--         if WAData.version == version then
	--             self:SetTextColor(1,1,1,1)
	--             return
	--         end
	--     end
	--     self:SetTextColor(.5,.5,.5,1)
	-- end)
	-- SenderFrame.versionEdit:SetTextInsets(0,0,0,0)
	-- local GameFontNormal_Font = GameFontNormal:GetFont()
	-- SenderFrame.versionEdit:SetFont(GameFontNormal_Font,12,"")
	-- SenderFrame.versionEdit:SetJustifyH("CENTER")
	-- SenderFrame.versionPlusButton = MLib:Button(SenderFrame,"+"):Size(20,16):Point("LEFT",SenderFrame.versionEdit,"RIGHT",5,0):OnClick(function()
	--     local id = SenderFrameData.id
	--     if id then
	--         local WAData = WeakAuras.GetData(id)
	--         if WAData then
	--             WAData.version = (WAData.version or 0) + 1
	--             SenderFrame.versionEdit:SetText("") -- trigger OnChange script
	--             SenderFrame.versionEdit:SetText(WAData.version or "0")
	--         end
	--     end
	--     SenderFrame.versionEdit:ClearFocus()
	-- end)
	-- SenderFrame.versionSetButton = MLib:Button(SenderFrame,"Set"):Size(40,16):Point("LEFT",SenderFrame.versionPlusButton,"RIGHT",5,0):OnClick(function()
	--     local id = SenderFrameData.id
	--     if id then
	--         local version = tonumber(SenderFrame.versionEdit:GetText())

	--         local WAData = WeakAuras.GetData(id)
	--         if WAData then
	--             WAData.version = version
	--             SenderFrame.versionEdit:SetText("") -- trigger OnChange script
	--             SenderFrame.versionEdit:SetText(version or "0")
	--         end
	--     end
	--     SenderFrame.versionEdit:ClearFocus()
	-- end)



	SenderFrame.SendButton = MLib:Button(SenderFrame,LR.ListdSend,15):Tooltip(LR["Pressing while holding |cff00ff00shift|r will add WA to queue but wont start sending\n\nPressing while holding |cff00ff00alt|r will not update last sync time for current WA(ignoring checkbox)\n\nPressing while holding |cff00ff00ctrl|r will start sending WAs added to queue"]):Size(380,30):Point("BOTTOM",SenderFrame,"BOTTOM",0,10):OnClick(function()
		if IsControlKeyDown() then
			module:SendAllQueued()
		else
			local id = SenderFrameData.id
			if id then
				module:Async(function()
					module:CompressAndSend(id, VMRT.WASync.UpdateLastSync and not IsAltKeyDown(), IsShiftKeyDown()) -- alt for not update last sync time, shift for just add to queue
				end)
			end
		end
	end)

	local bar = CreateFrame("StatusBar",nil,SenderFrame)
	Mixin(bar,SmoothStatusBarMixin)

	bar:SetSize(380,18)
	bar:SetPoint("BOTTOM",SenderFrame,"BOTTOM",0,55)

	bar:SetStatusBarTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Statusbar_Clean")
	bar:SetStatusBarColor(0.5,0.5,0.5)

	ELib:Border(bar,1,0,0,0,1)

	bar.Background = bar:CreateTexture(nil,"BACKGROUND")
	bar.Background:SetVertexColor(.15,.15,.15,.8)
	bar.Background:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Statusbar_Clean")
	bar.Background:SetPoint("TOPLEFT")
	bar.Background:SetPoint("BOTTOMRIGHT")

	SenderFrame.bar = bar


	SenderFrame.bar:SetMinMaxSmoothedValue(0,100)
	SenderFrame.bar:SetValue(0)

	SenderFrame.EstimateTimeLeft = ELib:Text(SenderFrame,""):Point("BOTTOMLEFT",SenderFrame.bar,"TOPLEFT",2,5):Color():Shadow():Left()
	SenderFrame.SendingProgressText = ELib:Text(SenderFrame,""):Point("BOTTOMRIGHT",SenderFrame.bar,"TOPRIGHT",-2,5):Color():Shadow():Right()


	SenderFrame.SendQueueFrame = ELib:Template("ExRTDialogModernTemplate",SenderFrame)
	SenderFrame.SendQueueFrame.Close:Hide()
	SenderFrame.SendQueueFrame:SetPoint("TOPLEFT",SenderFrame,"TOPRIGHT",0,0)
	SenderFrame.SendQueueFrame:SetPoint("BOTTOMRIGHT",SenderFrame,"BOTTOMRIGHT",200,0)
	ELib:Border(SenderFrame.SendQueueFrame,1,.24,.25,.30,1,nil,3)

	SenderFrame.SendQueueFrame.Bars = {}

	local function bar_Value(self,value,smooth,color)
		if color then
			local min,max = self:GetMinMaxValues()
			self:SetStatusBarColor(0.8-(value/max),(value/max)-0.2,0.12)
		end

		if not smooth or value == 0 or value == 1 then
			self:ResetSmoothedValue(value)
		else
			self:SetSmoothedValue(value)
		end
	end

	local function bar_Update(self)
		local data = self.data
		if data then
			self:Show()
			self:SetText(format("%s", data.id))
			self:SetProgressText(format("%d/%d",data.current, data.total))
			if data.justEnqueued and data.current == 0 then
				self.enquedLock = true
				local min,max = self:GetMinMaxValues()
				self:Value(max)
				self:SetStatusBarColor(0.4,0.4,0.8)
			elseif self.enquedLock or data.current == 0 then
				self.enquedLock = nil
				self:SetMinMaxValues(0,data.total)
				self:Value(0)
			else
				-- self:SetMinMaxValues(0,data.total)
				self:Value(data.current,true,true)
			end
		else
			self:Hide()
			self:Value(0)
		end
	end

	local function GetQueueButton(i)
		if i > 8 then
			return
		end

		if SenderFrame.SendQueueFrame.Bars[i] then
			return SenderFrame.SendQueueFrame.Bars[i]
		end

		local bar = CreateFrame("StatusBar",nil,SenderFrame.SendQueueFrame)
		SenderFrame.SendQueueFrame.Bars[i] = bar
		Mixin(bar,SmoothStatusBarMixin)

		bar:SetSize(196,40)
		bar:SetPoint("TOPLEFT",SenderFrame.SendQueueFrame,"TOPLEFT",2,-2 + -(i-1)*44)

		bar:SetStatusBarTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Statusbar_Clean")
		bar:SetStatusBarColor(0.5,0.5,0.5)

		ELib:Border(SenderFrame.SendQueueFrame.Bars[i],1,0,0,0,1)

		bar.Background = SenderFrame.SendQueueFrame.Bars[i]:CreateTexture(nil,"BACKGROUND")
		bar.Background:SetVertexColor(.15,.15,.15,.8)
		bar.Background:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\Statusbar_Clean")
		bar.Background:SetPoint("TOPLEFT")
		bar.Background:SetPoint("BOTTOMRIGHT")

		bar:SetMinMaxValues(0,100)
		bar:SetValue(0)

		bar.num = i
		bar.Text = ELib:Text(bar,""):Point("TOPLEFT",bar,"TOPLEFT",2,-5):Point("TOPRIGHT",bar,"TOPRIGHT",-2,-5):Color():Shadow():Left():Outline():Tooltip()
		bar.Text:SetWordWrap(false)
		function bar:SetText(text)
			self.Text:SetText(text)
		end

		bar.progress = ELib:Text(bar,""):Point("BOTTOMLEFT",bar,"BOTTOMLEFT",2,5):Color():Shadow():Left():Outline()
		function bar:SetProgressText(text)
			self.progress:SetText(text)
		end

		bar.Value = bar_Value
		bar.Update = bar_Update

		return bar
	end

	SenderFrame.SendQueueFrame.queue = {}

	function SenderFrame:AddToQueue(entry,id,totalParts,justEnqueued)
		tinsert(SenderFrame.SendQueueFrame.queue,{
			entry = entry,
			id = id,
			total = totalParts,
			current = 0,
			justEnqueued = justEnqueued,
		})
		SenderFrame.SendQueueFrame:Update()
	end

	function SenderFrame:RemoveFromQueue(entry)
		for i=1,#SenderFrame.SendQueueFrame.queue do
			if SenderFrame.SendQueueFrame.queue[i].entry == entry then
				tremove(SenderFrame.SendQueueFrame.queue,i)
				break
			end
		end
		SenderFrame.SendQueueFrame:Update()
	end

	function SenderFrame.SendQueueFrame:Update()
		if #SenderFrame.SendQueueFrame.queue == 0 then
			SenderFrame.SendQueueFrame:Hide()
			return
		else
			SenderFrame.SendQueueFrame:Show()
		end
		for i=1,#SenderFrame.SendQueueFrame.queue do
			local bar = GetQueueButton(i)
			if not bar then
				break
			end

			bar.data =  SenderFrame.SendQueueFrame.queue[i]
			bar:Update()
		end

		for i=#SenderFrame.SendQueueFrame.queue+1,#SenderFrame.SendQueueFrame.Bars do
			local bar = SenderFrame.SendQueueFrame.Bars[i]
			bar.data = nil
			bar:Update()
		end
	end

	function SenderFrame:UpdateBar(entryKey,current,total)
		local red = min(255, (1 - current / total) * 700)
		local green = min(255, (current / total) * 511)

		SenderFrame.SendingProgressText:SetTextColor(red/255,green/255,0)
		SenderFrame.SendingProgressText:SetText(current * 255 .. "|cFF00FF00/" .. total * 255)

		SenderFrame.bar:SetMinMaxSmoothedValue(0,total)
		SenderFrame.bar:SetStatusBarColor(red/255,green/280,0.12)
		SenderFrame.bar:SetSmoothedValue(current)

		for i=1,#SenderFrame.SendQueueFrame.queue do
			if SenderFrame.SendQueueFrame.queue[i].entry == entryKey then
				SenderFrame.SendQueueFrame.queue[i].current = current
				SenderFrame.SendQueueFrame.Bars[i]:Update()
				break
			end
		end
		-- we have speed of 10 parts per second, but we only send once every 5 sec
		local estimatedTime = ceil( (total - current) / 50 ) * 5
		SenderFrame.EstimateTimeLeft:SetText("Estimated time left: ".. estimatedTime .." sec")
	end

	function SenderFrame:FinishBar(entryKey)
		SenderFrame.EstimateTimeLeft:SetText("Sent!")
		SenderFrame.bar:SetMinMaxValues(0,1)
		SenderFrame.bar:SetSmoothedValue(1)
		SenderFrame:RemoveFromQueue(entryKey)
	end

	function SenderFrame:Update(id)
		SenderFrame.SendQueueFrame:Update()

		local data = SenderFrameData
		if id then
			data.id = id
			SenderFrame.bar:SetValue(0)
			SenderFrame.SendingProgressText:SetText("")
			SenderFrame.EstimateTimeLeft:SetText("")

			SenderFrame:Show()
		end

		local WAData = WeakAuras.GetData(data.id)
		if WAData then
			if id then -- first setted frame for this id
				data.updateConfig = WAData.exrtUpdateConfig or module.getDefaultUpdateConfig()
			end

			local exrtLastSync = WAData.exrtLastSync
			if exrtLastSync then
				SenderFrame.exrtLastSyncText:SetText(LR["Last Sync:"] .. date("%d.%m.%Y %H:%M:%S",exrtLastSync))
				SenderFrame.UpdateLastSyncCheck:SetChecked(VMRT.WASync.UpdateLastSync)
				SenderFrame.UpdateLastSyncCheck:Enable()
			else
				SenderFrame.exrtLastSyncText:SetText(LR["Last Sync:"] .. LR["Never"])
				SenderFrame.UpdateLastSyncCheck:SetChecked(true)
				SenderFrame.UpdateLastSyncCheck:Disable()
			end
			-- SenderFrame.versionEdit:SetText(WAData.version or "0")
			SenderFrame.SendButton:SetText(LR.ListdSend)
			SenderFrame.SendButton:Enable()
			SenderFrame.UIDText:SetText("UID: "..(WAData.uid or ""))
			SenderFrame.defaultLoadNever:SetValue(WAData.exrtDefaultLoadNever)
			if WASYNC_MAIN_PRIVATE and WAData.information and WAData.information.debugLog then
				SenderFrame.RequestDebugLog:Show()
			else
				SenderFrame.RequestDebugLog:Hide()
			end
			if SenderFrameData.customChannel == "WHISPER" and SenderFrameData.customTarget then
				SenderFrame.RequestDebugLog:Enable()
			else
				SenderFrame.RequestDebugLog:Disable()
			end
			SenderFrame.customErrorHandler:Update()
		else
			SenderFrame.exrtLastSyncText:SetText(LR["Last Sync:"] .. LR["Never"])
			SenderFrame.UpdateLastSyncCheck:SetChecked(false)
			-- SenderFrame.versionEdit:SetText("")
			SenderFrame.SendButton:SetText("No WA found")
			SenderFrame.SendButton:Disable()
			SenderFrame.UIDText:SetText("UID:")
			SenderFrame.defaultLoadNever:SetValue()
			SenderFrame.RequestDebugLog:Hide()
		end


		if data.importType == 3 then
			SenderFrame.updateConfigDropDown:Show()
			SenderFrame.updateConfigDropDown:SetValue(data.updateConfig)
		else
			SenderFrame.updateConfigDropDown:Hide()
		end
		SenderFrame.skipPrompt:Shown(AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender("player"))

		SenderFrame.ImportTypeDropDown:SetText(WASync.ImportTypes[data.importType])
		if SenderFrameData.customTarget then
			SenderFrame.customTargetDropDown:PreUpdate()
			for _,data in next, SenderFrame.customTargetDropDown.List do -- hidden keys are not included in array part
				if data.arg2 == SenderFrameData.customTarget or data.arg2 == MRT.F.delUnitNameServer(SenderFrameData.customTarget) then
					customTargetDropDown_SetValue({data=data},data.arg1,data.arg2,true)
					break
				end
			end
		else
			local isPass, reason = AddonDB:CheckSelfPermissions(WASync.isDebugMode)
			if not isPass then
				SenderFrame.SendButton:SetText(reason or LR.ListdSend)
				SenderFrame.SendButton:Disable()
			end
		end
		SenderFrame.IDText:SetText("ID: "..(data.id or ""))
	end
	SenderFrame:SetScript("OnShow",function(self)
		self:RegisterEvent("GROUP_ROSTER_UPDATE")
	end)
	SenderFrame:SetScript("OnHide",function(self)
		self:UnregisterEvent("GROUP_ROSTER_UPDATE")
	end)

	SenderFrame:SetScript("OnEvent",function(self)
		if self:IsVisible() then
			self:Update()
		end
	end)


	SenderFrame:Update()
end
