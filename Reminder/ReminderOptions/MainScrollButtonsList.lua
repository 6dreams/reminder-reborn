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

local options = module.options

function module.options:MainScrollButtonsListInitialize()
	local prettyPrint = module.prettyPrint
	local encountersList = AddonDB.EJ_DATA.encountersList
	local isExportOpen


	local function DeleteData(self) --self
		local parent = self:GetParent()
		if not parent.data and not self.data then
			return
		end
		local data = parent.data and parent.data.data or self.data and self.data.data
		local token = data.token
		if not IsShiftKeyDown() then
			MLib:DialogPopup({
				id = "EXRT_REMINDER_DELETE_CURRENT",
				title = LR["Delete Reminder"],
				text = LR.Listdelete.."?",
				buttons = {
					{
						text = LR.Listdelete,
						func = function()
							module:DeleteReminder(data)
						end,
					},
					{
						text = NO,
					},
				},
			})
		else
			module:DeleteReminder(data)
		end
	end

	function module:EditData(data)
		if not data then
			return
		end
		if not module.SetupFrame then
			module.options:SetupFrameInitialize()
		end

		module.SetupFrame.data = MRT.F.table_copy2(data)

		if module.SetupFrame:IsVisible() then
			module.SetupFrame:Update()
		else
			module.SetupFrame:Show()
		end
	end

	local function SendData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end
		local token = parent.data.data.token
		if token then
			module:Sync(false, nil, nil, token)
		else
			prettyPrint("ERROR: No token")
		end
	end

	local function SendFullBossData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end

		local bossID = parent.data.bossID or parent.data.zone_bossID or parent.data.otherID == 0 and -1
		local zoneID = parent.data.zoneID

		module:Sync(false, bossID, zoneID)
	end

	local function ExportFullBossData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end
		local bossID = parent.data.bossID or parent.data.zone_bossID or parent.data.otherID == 0 and -1
		local zoneID = parent.data.zoneID


		local export = module:Sync(true, bossID, zoneID)
		MRT.F:Export(export)
	end

	local exportWindow

	local function ExportData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end


		if not isExportOpen then
			exportWindow = ELib:Popup(LR["Export"]):Size(650,615)
			exportWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			exportWindow:SetClampedToScreen(false)

			isExportOpen = true
			exportWindow.Edit = ELib:MultiEdit(exportWindow):Point("TOP",0,-20):Size(640,575)
			exportWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			exportWindow.TextInfo = ELib:Text(exportWindow,LR.SingularExportTip,12):Color():Point("BOTTOM",0,3):Size(640,15):Bottom():Left()
			exportWindow:SetScript("OnHide",function(self)
				self.Edit:SetText("")
				isExportOpen = false
			end)
			exportWindow.Next = MRT.lib:Button(exportWindow,">>>"):Size(100,16):Point("BOTTOMRIGHT",0,0):OnClick(function (self)
				self.now = self.now + 1
				self:SetText(">>> "..self.now.."/"..#exportWindow.hugeText)
				exportWindow.Edit:SetText(exportWindow.hugeText[self.now])
				exportWindow.Edit.EditBox:HighlightText()
				exportWindow.Edit.EditBox:SetFocus()
				if self.now == #exportWindow.hugeText then
					self:Hide()
				end
			end)
			local token = parent.data.data.token
			local stringData = module:Sync(true, nil, nil, token)
			exportWindow.title:SetText(AddonDB.LR.Export)
			exportWindow:NewPoint("CENTER",UIParent,0,0)
			exportWindow:Show()

			exportWindow.hugeText = nil
			exportWindow.Next:Hide()
			exportWindow.Edit:SetText(stringData)
			exportWindow.Edit.EditBox:HighlightText()
			exportWindow.Edit.EditBox:SetFocus()
			exportWindow.Edit.EditBox:SetScript("OnEscapePressed",function(self)
				exportWindow:Hide()
			end)
		elseif (exportWindow.Edit:GetText():find("^" .. module.SENDER_VERSION .. "%^" .. module.DATA_VERSION)) then -- if export window is open and contains senderVer^dataVer
			local token = parent.data.data.token
			local stringData = module:Sync(true, nil, nil, token, true)
			exportWindow.Edit:SetText(exportWindow.Edit:GetText() .. "\n" .. stringData)
		else -- cant find senderVer^dataVer, starting export from start
			local token = parent.data.data.token
			local stringData = module:Sync(true, nil, nil, token)
			exportWindow.Edit:SetText(stringData)
		end
		exportWindow:ClearAllPoints()
		exportWindow:Point("LEFT",module.options.scrollList,"RIGHT",0,0)

	end

	local function DuplicateData(data)
		local token = time() + GetTime() % 1
		VMRT.Reminder.data[ token ] = MRT.F.table_copy2(data)
		VMRT.Reminder.data[ token ].token = token
		VMRT.Reminder.data[ token ].notSync = 2

		if module.options.Update then
			module.options.Update()
		end

		module:ReloadAll()
	end

	options.scrollList = ELib:ScrollButtonsList(options.REMINDERS_SCROLL_LIST):Point("TOPLEFT",0,-2):Size(760,508)
	ELib:DecorationLine(options.scrollList):Point("TOP",options.scrollList,"BOTTOM",0,0):Point("LEFT",options):Point("RIGHT",options):Size(0,1)

	options.scrollList.ButtonsInLine = 1 --0.992
	options.scrollList.mouseWheelRange = 50
	ELib:Border(options.scrollList,0)

	local cursorPoint = UIParent:CreateTexture()
	cursorPoint.toggleX = 200
	cursorPoint.toggleY = 0
	cursorPoint:SetSize(4,4)


	local function ButtonLevel1Click(self,button) -- level 1 click
		if button == "LeftButton" then
			local parent = self.parent
			local uid = self.uid
			parent.stateExpand[uid] = not parent.stateExpand[uid]
			parent:Update()
		elseif button == "RightButton" then
			local data = self.data
			if data.data then
				local menu = {
					{ text = data.name or "~no name", isTitle = true, notCheckable = true, notClickable = true },

					{ text = LR["Export All For This Boss"], func = function() ELib.ScrollDropDown.Close() ExportFullBossData(self.expandSend) end, notCheckable = true },
					{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
				}

				local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
				cursorPoint:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)

				ELib.ScrollDropDown.EasyMenu(cursorPoint, menu, 250)
			end
		end
	end

	function options.scrollList:ButtonClick(button) -- level 2 click
		local data = self.data
		if not data then
			return
		end
		if button == "RightButton" then
			if data.data then
				local menu = {
					{ text = data.name or "~no name", isTitle = true, notCheckable = true, notClickable = true },
					{ text = DELETE, func = function() ELib.ScrollDropDown.Close() DeleteData(self) end, notCheckable = true },
					{ text = LR["Listduplicate"], func = function() ELib.ScrollDropDown.Close() DuplicateData(data.data) end, notCheckable = true },
					{ text = LR["Get last update time"], func = function() ELib.ScrollDropDown.Close() module:GetLastSync(data.data.token) end, notCheckable = true },
					{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
				}

				local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
				cursorPoint:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)

				ELib.ScrollDropDown.EasyMenu(cursorPoint,menu,250)
			end
			return
		elseif button == "LeftButton" then
			module:EditData(data.data)
		end
	end

	local function Button_OnOff_Click(self)
		local status = self.status
		if status == 1 then
			status = 2
		elseif status == 2 then
			status = 1
		end
		self.status = status
		self:Update(status)

		local data = self:GetParent().data.data
		local token = data.token
		if data.defDisabled then
			module:ToggleDataOption(data.token, "DEF_ENABLED")
		else
			module:ToggleDataOption(data.token, "DISABLED")
		end
		module:ReloadAll()
		if self:GetScript("OnEnter") then
			self:GetScript("OnEnter")(self)
		end
	end
	local function Button_OnOff_Update(self,status)
		if status == 1 then
			self.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		elseif status == 2 then
			self.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
		end
	end

	local function GetSoundStatus(token)
		if not module:GetDataOption(token, "SOUND_DISABLED") and not module:GetDataOption(token, "SOUND_LOCKED")then
			return 1
		elseif module:GetDataOption(token, "SOUND_LOCKED") then
			return 2
		elseif module:GetDataOption(token, "SOUND_DISABLED") then
			return 3
		end
	end

	local function Button_Sound_Click(self)
		local status = self.status
		status = status == 1 and 2 or status == 2 and 3 or 1

		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		if status == 1 then -- no mute, no lock
			module:SetDataOption(token, "SOUND_LOCKED", false)
			module:SetDataOption(token, "SOUND_DISABLED", false)
		elseif status == 2 then -- lock, no mute
			module:SetDataOption(token, "SOUND_LOCKED", true)
			module:SetDataOption(token, "SOUND_DISABLED", false)
		elseif status == 3 then -- mute, no lock
			module:SetDataOption(token, "SOUND_LOCKED", false)
			module:SetDataOption(token, "SOUND_DISABLED", true)
		end

		if self:GetScript("OnEnter") then
			self:GetScript("OnEnter")(self)
		end
	end
	local function Button_Sound_Update(self,status)
		if status == 1 then
			self.texture:SetDesaturated(true)
			self.line:Hide()
		elseif status == 2 then
			self.texture:SetDesaturated(false)
			self.line:Hide()
		elseif status == 3 then
			self.texture:SetDesaturated(false)
			self.line:Show()
		end
	end

	local function Button_Personal_Click(self)
		local status = self.status
		status = status == 1 and 2 or 1

		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		VMRT.Reminder.data[token].isPersonal = status == 2 or nil

		module.options.scrollList:ModButtonUpdate(self:GetParent(),2)
		if self:GetScript("OnEnter") then
			self:GetScript("OnEnter")(self)
		end
	end

	local function Button_Personal_Update(self,status)
		if status == 1 then
			self.text:Color()
		elseif status == 2 then
			self.text:Color(1,.82,0)
		end
	end

	local function Button_Lock_Click(self)
		local status = self.status
		if status == 1 then
			status = 2
		elseif status == 2 then
			status = 1
		end
		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		module:ToggleDataOption(token, "LOCKED")
		if self:GetScript("OnEnter") then
			self:GetScript("OnEnter")(self)
		end
	end
	local function Button_Lock_Update(self,status)
		if status == 1 then
			self.texture:SetTexCoord(.6875,.7425,.5,.625)
			self.texture:SetVertexColor(1,1,1,1)
		elseif status == 2 then
			self.texture:SetTexCoord(.625,.68,.5,.625)
			self.texture:SetVertexColor(1,0.82,0,1)
		end
	end

	local function ButtonIcon_OnEnter(self)
		if not self["tooltip"..(self.status or 1)] then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self["tooltip"..(self.status or 1)],nil,nil,nil,true)
		GameTooltip:Show()
	end

	local function ButtonIcon_OnLeave(self)
		GameTooltip_Hide()
	end

	local function lineStyledButton(parent,text)
		local button = ELib:Button(parent,text):FontSize(12)
		button.Texture:SetColorTexture(0,0,0,0)
		button.DisabledTexture:SetColorTexture(0,0,0,0)
		button.BorderLeft:Hide()
		button.BorderRight:Hide()
		button.BorderTop:Hide()
		button.BorderBottom:Hide()

		local textObj = button:GetTextObj()
		textObj:SetShadowColor(0,0,0,1)
		textObj:SetShadowOffset(1,-1)

		return button
	end

	local function Button_Create(parent,size)
		if not size then size = 14 end
		local self = ELib:Button(parent,"",1):Size(20,20)
		self.texture = self:CreateTexture(nil,"ARTWORK")
		self.texture:SetPoint("CENTER")
		self.texture:SetSize(size,size)

		self.HighlightTexture = self:CreateTexture(nil,"BACKGROUND")
		self.HighlightTexture:SetColorTexture(1,1,1,.3)
		self.HighlightTexture:SetPoint("TOPLEFT")
		self.HighlightTexture:SetPoint("BOTTOMRIGHT")
		self:SetHighlightTexture(self.HighlightTexture)

		self:SetScript("OnEnter",ButtonIcon_OnEnter)
		self:SetScript("OnLeave",ButtonIcon_OnLeave)

		return self
	end

	local function Button_OnLeave(self)
		GameTooltip_Hide()
	end

	local function Button_OnEnter(self)
		---@type ReminderData
		local data = self.data.data
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		module:AddTooltipLinesForData(data)
		GameTooltip:Show()
	end

	local function Button_Lvl1_Remove(self)
		MLib:DialogPopup({
			id = "EXRT_REMINDER_CLEAR_LVL1_REMOVE",
			title = LR["Delete Reminders"],
			text = LR.DeleteSection.."?",
			buttons = {
				{
					text = YES,
					func = function()
						for token,data in next, VMRT.Reminder.data do
							if
								(
								(self.bossID and data.boss == self.bossID) or
								(type(self.bossID)=="table" and self.bossID[data.boss]) or
								(self.zoneID and (tonumber(tostring(data.zoneID):match("^[^, ]+") or "",10) == self.zoneID))
								) and
								not module:GetDataOption(token, "LOCKED")
							then
								module:DeleteReminder(data,true)
							end
						end
						if module.options.Update then
							module.options.Update()
						end
						module:ReloadAll()
					end,
				},
				{
					text = NO,
				},
			},
		})
	end

	local function Button_Lvl2_SetTypeIcon(self,iconType)
		self.text:Hide()
		self.glow:Hide()
		self.glow2:Hide()
		self.bar:Hide()
		if iconType == 1 then
			self.text:FontSize(12)
			self.text:SetText("T")
			self.text:Show()
		elseif iconType == 2 then
			self.text:FontSize(11)
			self.text:SetText("t")
			self.text:Show()
		elseif iconType == 3 then
			self.text:FontSize(18)
			self.text:SetText("T")
			self.text:Show()
		elseif iconType == 4 then
			self.glow:Show()
		elseif iconType == 5 then
			self.glow2:Show()
		elseif iconType == 6 then
			self.text:FontSize(8)
			self.text:SetText("/say")
			self.text:Show()
		elseif iconType == 7 then
			self.text:FontSize(10)
			self.text:SetText("WA")
			self.text:Show()
		elseif iconType == 8 then
			self.bar:Show()
		end
	end

	local function Button_Lvl2_SetDiffText(self,diff)
		self.text:SetText(type(diff) == "number" and LR.diff_name_short[diff] or diff)
	end

	function options.scrollList:ModButton(button,level)
		if level == 1 then
			local textObj = button:GetTextObj()
			textObj:SetPoint("LEFT",5+30,0)
			textObj:SetShadowColor(0,0,0,1)
			textObj:SetShadowOffset(1,-1)

			button.bossImg = button:CreateTexture(nil, "ARTWORK")
			button.bossImg:SetSize(28,28)
			button.bossImg:SetPoint("LEFT",2,0)

			button.dungImg = button:CreateTexture(nil, "ARTWORK")
			button.dungImg:SetPoint("TOPLEFT",20,0)
			button.dungImg:SetPoint("BOTTOMRIGHT",button,"BOTTOM",20,0)
			button.dungImg:SetAlpha(.4)
			button.dungImg:SetTexCoord(0,1,.35,.45)

			button.remove = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-30,0)
			button.remove:SetScript("OnClick",Button_Lvl1_Remove)
			button.remove.tooltip1 = LR.RemoveSection
			button.remove.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")
			-- button.remove.texture:SetAtlas("common-icon-redx")
			-- button.remove.texture:SetDesaturated(true)

			button.expandSend = lineStyledButton(button,LR["Send All For This Boss"]):Point("RIGHT",button.remove,"LEFT",-15,0):Size(150,30):OnClick(SendFullBossData)

			button.Texture:SetGradient("VERTICAL",CreateColor(.13,.13,.13,1), CreateColor(.16,.16,.16,1))

			button:OnClick(ButtonLevel1Click)
			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		elseif level == 2 then
			button.onoff = Button_Create(button):Point("LEFT",button,"LEFT",0,0)
			button.onoff:SetScript("OnClick",Button_OnOff_Click)
			button.onoff.Update = Button_OnOff_Update
			button.onoff.tooltip1 = LR.PersonalDisable
			button.onoff.tooltip2 = LR.PersonalEnable

			button.lock = Button_Create(button):Point("LEFT",button.onoff,"RIGHT",0,0)
			button.lock.texture:SetTexture([[Interface\AddOns\MRT\media\DiesalGUIcons16x256x128.tga]])
			button.lock:SetScript("OnClick",Button_Lock_Click)
			button.lock.Update = Button_Lock_Update
			button.lock.tooltip1 = LR.UpdatesDisable
			button.lock.tooltip2 = LR.UpdatesEnable

			button.typeicon = CreateFrame("Frame",nil,button)
			button.typeicon:SetPoint("LEFT",button.lock,"RIGHT",0,0)
			button.typeicon:SetSize(20,20)
			button.typeicon.text = ELib:Text(button.typeicon,"T"):Point("CENTER"):Color()
			button.typeicon.glow = ELib:Texture(button.typeicon,[[Interface\SpellActivationOverlay\IconAlert]]):Point("CENTER",-1,0):Size(18,18):TexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
			button.typeicon.glow:SetDesaturated(true)
			button.typeicon.glow2 = CreateFrame("Frame",nil,button.typeicon)
			button.typeicon.glow2:SetSize(18,18)
			button.typeicon.glow2:SetPoint("CENTER")
			button.typeicon.glow2.t1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(5,2)
			button.typeicon.glow2.t2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(5,2)
			button.typeicon.glow2.l1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(2,5)
			button.typeicon.glow2.l2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(2,5)
			button.typeicon.glow2.r1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(2,5)
			button.typeicon.glow2.r2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(2,5)
			button.typeicon.glow2.b1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(5,2)
			button.typeicon.glow2.b2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(5,2)
			button.typeicon.bar = ELib:Texture(button.typeicon,1,1,1,1):Point("CENTER",-1,0):Size(18,4)
			button.typeicon.SetType = Button_Lvl2_SetTypeIcon
			button.typeicon:SetType()

			button.difftext = CreateFrame("Frame",nil,button)
			button.difftext:SetPoint("LEFT",button.typeicon,"RIGHT",0,0)
			button.difftext:SetSize(20,20)
			button.difftext.text = ELib:Text(button.difftext,"A"):Point("CENTER"):Color()
			button.difftext.SetDiff = Button_Lvl2_SetDiffText
			button.difftext:SetDiff()

			button.name = button:GetTextObj()
			button.name:SetPoint("LEFT",button.difftext,"RIGHT",5,0)
			button.name:SetPoint("RIGHT",button.difftext,"RIGHT",210,0)

			button.msg = ELib:Text(button,"",12):Point("LEFT",button.name,"RIGHT",5,0):Size(185,20)

			button.name:SetFont(button.msg:GetFont())
			button.name:SetShadowColor(button.msg:GetShadowColor())
			button.name:SetShadowOffset(button.msg:GetShadowOffset())

			---

			button.delete = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-5,0)
			button.delete:SetScript("OnClick",DeleteData)
			button.delete.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")
			button.delete.tooltip1 = LR.ListdeleteTip

			button.dSend = lineStyledButton(button,LR.ListdSend):Point("RIGHT",button.delete,"LEFT",0,0):Size(80,20):OnClick(SendData)
			button.dExport = lineStyledButton(button,LR.ListdExport):Point("RIGHT",button.dSend,"LEFT",0,0):Size(80,20):OnClick(ExportData)

			button.personal = Button_Create(button):Point("RIGHT",button.dExport,"LEFT",0,0)
			button.personal.text = ELib:Text(button.personal,"P"):Point("CENTER"):Color()
			button.personal:SetScript("OnClick",Button_Personal_Click)
			button.personal.Update = Button_Personal_Update
			button.personal.tooltip1 = LR["PersonalStatus1"]
			button.personal.tooltip2 = LR["PersonalStatus2"]

			button.sound = Button_Create(button):Point("RIGHT",button.personal,"LEFT",0,0)
			button.sound.texture:SetAtlas("voicechat-icon-speaker")
			button.sound.line = button.sound:CreateLine(nil,"ARTWORK",nil,2)
			button.sound.line:SetColorTexture(1,0,0,1)
			button.sound.line:SetStartPoint("CENTER",-5,-5)
			button.sound.line:SetEndPoint("CENTER",5,5)
			button.sound.line:SetThickness(2)
			button.sound:SetScript("OnClick",Button_Sound_Click)
			button.sound.Update = Button_Sound_Update
			button.sound.tooltip1 = LR["SoundStatus1"] -- all enabled
			button.sound.tooltip2 = LR["SoundStatus2"] -- sound is locked
			button.sound.tooltip3 = LR["SoundStatus3"] -- sound is muted

			button:SetScript("OnEnter",Button_OnEnter)
			button:SetScript("OnLeave",Button_OnLeave)

			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		end
	end

	local COLOR_BLACK1, COLOR_BLACK2 = CreateColor(.15,.15,.15,1), CreateColor(.18,.18,.18,1)
	local COLOR_GREEN1, COLOR_GREEN2 = CreateColor(.1,.28,.1,1), CreateColor(.16,.37,.1,1)
	local COLOR_RED1, COLOR_RED2 = CreateColor(.35,.13,.13,1), CreateColor(.44,.14,.14,1)
	local COLOR_BLUE1, COLOR_BLUE2 = CreateColor(.16,.3,.47,1), CreateColor(.14,.37,.67,1)
	local COLOR_ORANGE1, COLOR_ORANGE2 = CreateColor(.45,.32,.1,1), CreateColor(.75,.5,0.1,1)

	function options.scrollList:ModButtonUpdate(button, level)
		if level == 1 then
			local data = button.data
			local resetBossImg,resetDungImg = true,true
			if data.bossID then
				resetBossImg = false
				if not AddonDB:SetBossPortait(button.bossImg, data.bossID) then
					SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
				end
			elseif data.zoneID then
				resetBossImg = false
				local zoneID = tonumber(tostring(data.zoneID):match("^[^, ]+") or "",10)
				local foregroundImage, backgroundImage, instanceName = AddonDB:GetInstanceImage(zoneID)

				if foregroundImage and backgroundImage then
					button.bossImg:SetTexture(foregroundImage)
					button.dungImg:SetTexture(backgroundImage)
					resetDungImg = false
				else
					SetPortraitTextureFromCreatureDisplayID(button.bossImg, 51173)
				end
			else
				resetBossImg = false
				SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
			end

			if resetBossImg then
				button.bossImg:SetTexture("")
			end
			if resetDungImg then
				button.dungImg:SetTexture("")
			end

			if data.bossID or data.zoneID then
				button.remove.bossID = data.bossID or data.zone_bossID
				button.remove.zoneID = data.zoneID
				button.remove:Show()
			else
				button.remove:Hide()
			end

			if data.zone_bossID then
				button.bossImg:SetPoint("LEFT",0,0)
				button.expandSend:SetText(LR["Send All (This Zone)"])
			else
				button.bossImg:SetPoint("LEFT",2,0)
				button.expandSend:SetText(LR["Send All For This Boss"])
			end

		elseif level == 2 then
			button:GetTextObj():SetWordWrap(false)

			local data = button.data
			local reminderData = data.data
			if not reminderData then return end
			if reminderData.notSync == 2 then
				button:GetTextObj():SetTextColor(1,0.5,0)
			else
				button:GetTextObj():SetTextColor(1,.82,0)
			end
			button.msg:SetText(reminderData.WAmsg and "|cff9370DBWA:|r " .. module:FormatMsg(reminderData.WAmsg) .. "|r" or
				reminderData.msg and reminderData.msg ~= "" and module:FormatMsg(reminderData.msg) or
				reminderData.spamMsg and "|cff0088ffCHAT:|r " .. (module:FormatMsg(reminderData.spamMsg)) .. "|r" or
				reminderData.nameplateText and "|cff0088ffNAMEPLATE:|r " .. (module:FormatMsg(reminderData.nameplateText)) or
				reminderData.tts and "|cff0088ffTTS:|r " .. (module:FormatMsg(reminderData.tts)) or
				reminderData.glow and "|cff0088ffFRAME GLOW:|r " .. (module:FormatMsg(reminderData.glow)) or
				"")

			if data.nohud and not button.ishudhidden then
				button.onoff:Hide()
				button.sound:Hide()
				button.lock:Hide()
				button.personal:Hide()
				button.ishudhidden = true
			elseif not data.nohud and button.ishudhidden then
				button.onoff:Show()
				button.sound:Show()
				button.lock:Show()
				button.personal:Show()
				button.ishudhidden = false
			end
			if reminderData.defDisabled then
				if module:GetDataOption(reminderData.token, "DEF_ENABLED") then
					button.onoff.status = 1
				else
					button.onoff.status = 2
				end
			else
				if not module:GetDataOption(reminderData.token, "DISABLED") then
					button.onoff.status = 1
				else
					button.onoff.status = 2
				end
			end
			button.onoff:Update(button.onoff.status)

			if not module:GetDataOption(reminderData.token, "LOCKED") then
				button.lock.status = 1
			else
				button.lock.status = 2
			end
			button.lock:Update(button.lock.status)

			button.sound.status = GetSoundStatus(reminderData.token)
			button.sound:Update(button.sound.status)

			if not button.ishudhidden then
				if reminderData and (reminderData.sound or reminderData.tts) then
					button.sound:Show()
				else
					button.sound:Hide()
				end
			end

			if reminderData.isPersonal then
				button.personal.status = 2
			else
				button.personal.status = 1
			end
			button.personal:Update(button.personal.status)


			if reminderData then
				local data = reminderData
				if data.WAmsg then        --WA
					button.typeicon:SetType(7)
				elseif data.nameplateGlow then --NAMEPLATE
					button.typeicon:SetType(5)
				elseif data.glow then --RAIDFRAME
					button.typeicon:SetType(4)
				elseif data.spamMsg then      --CHAT
					button.typeicon:SetType(6)
				elseif data.msgSize == 3 or data.msgSize == 4 or data.msgSize == 5 then
					button.typeicon:SetType(8)
				else                          -- NORMAL TEXT
					-- button.typeicon:SetType(1)
					if data.msgSize == 1 then
						button.typeicon:SetType(2)
					elseif data.msgSize == 2 then
						button.typeicon:SetType(3)
					else
						button.typeicon:SetType(1)
					end

				end
				local diff = data.diff
				button.difftext:SetDiff(diff or "A")
			else
				button.typeicon:SetType()
				button.difftext:SetDiff("A")
			end

			button.dSend:Enable()
			button.dExport:Enable()

			if data.data.isPersonal then
				button.dSend:Disable()
				button.dExport:Disable()
				button.dSend:SetText(LR.ListdSend)
			elseif data.data.notSync then
				button.dSend:SetText("|cffffffff"..LR.ListdSend.."|r")
				button.dSend:Tooltip("|cffff0000"..LR.ListNotSentTip .. "|r\nID: ".. data.data.token)
				button.dExport:Tooltip("|cffff0000"..LR.ListNotSentTip .. "|r\nID: ".. data.data.token)
			else
				button.dSend:SetText(LR.ListdSend)
				button.dSend:Tooltip("ID: ".. data.data.token)
				button.dExport:Tooltip("ID: ".. data.data.token)
			end
			if data.data.disabled then
				if not VMRT.Reminder.alternativeColorScheme then
					button.Texture:SetGradient("HORIZONTAL", COLOR_BLACK1, COLOR_BLACK2) --black
				else
					button.Texture:SetGradient("HORIZONTAL", COLOR_BLACK1, COLOR_BLACK2) --black
				end
				button.onoff.texture:SetDesaturated(1)
				return
			else
				button.onoff.texture:SetDesaturated()
			end
			if module:CheckPlayerCondition(data.data) then -- loaded
				if data.data.isPersonal then
					if VMRT.Reminder.alternativeColorScheme then
						button.Texture:SetGradient("HORIZONTAL", COLOR_GREEN1, COLOR_GREEN2) -- green
					else
						button.Texture:SetGradient("HORIZONTAL", COLOR_BLUE1, COLOR_BLUE2) -- blue
					end
				else
					if VMRT.Reminder.alternativeColorScheme then
						button.Texture:SetGradient("HORIZONTAL", COLOR_BLUE1, COLOR_BLUE2) -- blue
					else
						button.Texture:SetGradient("HORIZONTAL", COLOR_GREEN1, COLOR_GREEN2) -- green
					end
				end
			else -- not loaded
				if data.data.isPersonal then
					if VMRT.Reminder.alternativeColorScheme then
						button.Texture:SetGradient("HORIZONTAL", COLOR_RED1, COLOR_RED2) -- red
					else
						button.Texture:SetGradient("HORIZONTAL", COLOR_ORANGE1, COLOR_ORANGE2) -- orange
					end
				else
					if VMRT.Reminder.alternativeColorScheme then
						button.Texture:SetGradient("HORIZONTAL", COLOR_ORANGE1, COLOR_ORANGE2) -- orange
					else
						button.Texture:SetGradient("HORIZONTAL", COLOR_RED1, COLOR_RED2) -- red
					end
				end
			end
		end
	end

	function options:UpdateData()
		local currZoneID = select(8, GetInstanceInfo())

		local Mdata = {}
		local zoneHeaders = {}
		for token,data in next, VMRT.Reminder.data do
			local tableToAdd

			local bossID = data.boss
			local zoneID = data.zoneID

			if zoneID then
				zoneID = tonumber(tostring(zoneID):match("^[^, ]+") or "",10)
			end

			local function AddZone(zoneID)
				local zoneData = MRT.F.table_find3(Mdata,zoneID,"zoneID")
				if not zoneData then
					local instanceName = LR.instance_name[zoneID]

					zoneData = {
						zoneID = zoneID,
						name = instanceName ..(currZoneID == zoneID and " |cff00ff00("..LR.Now..")|r" or ""),
						data = {},
						uid = "zone"..zoneID,
					}
					Mdata[#Mdata+1] = zoneData

					zoneHeaders[zoneID] = zoneData
				end
				return zoneData
			end

			local searchPat = module.options.search
			if module:SearchInData(data,searchPat) then
				if bossID then
					local bossData = MRT.F.table_find3(Mdata,bossID,"bossID")
					if not bossData then
						local instanceName
						for i=1,#encountersList do
							local instance = encountersList[i]
							for j=2,#instance do
								if instance[j] == bossID then
									instanceName = LR.instance_name[instance[1]]:gsub(",.+","")
									break
								end
							end
							if instanceName then
								break
							end
						end

						local encounterName = LR.boss_name[bossID]

						if encounterName == "" then
							encounterName = nil
						end

						bossData = {
							bossID = bossID,
							name = (instanceName and instanceName ~= "" and instanceName..": " or "")..(encounterName or "")..(bossID == VMRT.Reminder.lastEncounterID and " |cff00ff00("..LR.LastPull..")|r" or ""),
							data = {},
							uid = "boss"..bossID,
						}
						Mdata[#Mdata+1] = bossData
					end

					local ej_bossID = AddonDB.EJ_DATA.encounterIDtoEJ[bossID]
					if ej_bossID and EJ_GetEncounterInfo then
						local name, description, journalEncounterID, rootSectionID, link, journalInstanceID, dungeonEncounterID, instanceID = EJ_GetEncounterInfo(ej_bossID)
						if journalInstanceID then
							local name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, mapID = EJ_GetInstanceInfo(journalInstanceID)
							if mapID then
								local zoneData = AddZone(mapID)
								if not zoneData.zone_bossID then
									zoneData.zone_bossID = {}
								end
								zoneData.zone_bossID[bossID] = true
							end
						end
					end

					tableToAdd = bossData.data
				elseif zoneID then
					tableToAdd = AddZone(zoneID).data
				else
					local otherData = MRT.F.table_find3(Mdata,0,"otherID")
					if not otherData then
						otherData = {
							otherID = 0,
							name = LR.Always,
							data = {},
							uid = "other0",
						}
						Mdata[#Mdata+1] = otherData
					end
					tableToAdd = otherData.data
				end

				tableToAdd[#tableToAdd+1] = {
					name = data.name or ("~"..LR.NoName),
					uid = token,
					data = data,
					isPersonal = data.isPersonal,
					diff = data.diff or 0,
				}
			end
		end

		sort(Mdata,function(a,b)
			if a.zoneID and b.zoneID then
				return AddonDB:GetInstanceSortIndex(a.zoneID,100000-a.zoneID) < AddonDB:GetInstanceSortIndex(b.zoneID,100000-b.zoneID)
			elseif a.zoneID then
				return true
			elseif b.zoneID then
				return false
			elseif a.bossID and b.bossID then
				return AddonDB:GetEncounterSortIndex(a.bossID,100000-a.bossID) < AddonDB:GetEncounterSortIndex(b.bossID,100000-b.bossID)
			elseif a.otherID then
				return false
			elseif b.otherID then
				return true
			elseif a.bossID then
				return true
			elseif b.bossID then
				return false
			end
			return false
		end)
		for i=1,#Mdata do
			local t = Mdata[i].data
			sort(t,function(a,b)
				if a.isPersonal and not b.isPersonal then
					return false
				elseif not a.isPersonal and b.isPersonal then
					return true
				elseif a.diff ~= b.diff then
					return a.diff > b.diff
				elseif a.name:lower() ~= b.name:lower() then
					return a.name:lower():gsub("%.",strchar(255)) < b.name:lower():gsub("%.",strchar(255))
				else
					return a.uid < b.uid
				end
			end)
		end

		--re add boss to dungeons
		for i=#Mdata,1,-1 do
			local bossID = Mdata[i].bossID
			if bossID then
				local ej_bossID = AddonDB.EJ_DATA.encounterIDtoEJ[bossID]
				if ej_bossID and EJ_GetEncounterInfo then
					local name, description, journalEncounterID, rootSectionID, link, journalInstanceID, dungeonEncounterID, instanceID = EJ_GetEncounterInfo(ej_bossID)
					if journalInstanceID then
						local name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, mapID = EJ_GetInstanceInfo(journalInstanceID)
						if mapID and zoneHeaders[mapID] then
							Mdata[i].isSubData = true
							tinsert(zoneHeaders[mapID].data,1,Mdata[i])
							tremove(Mdata,i)
						end
					end
				end
			end
		end


		module.options.scrollList.data = Mdata
		module.options.scrollList:Update(true)
		if module.options.timeLine then
			module.options.timeLine:Update()
		end

		if module.options.lastUpdate then
			module.options.lastUpdate:Update()
		end
	end

	local AddButton = MLib:Button(options.REMINDERS_SCROLL_LIST,LR.Add,13):Point("TOPLEFT",options.scrollList,"BOTTOMLEFT",4,-5):Size(100,20):OnClick(function()
		if not module.SetupFrame then
			options:SetupFrameInitialize()
		end

		module.SetupFrame.data = CopyTable(module.datas.newReminderTemplate)

		if module.SetupFrame:IsVisible() then
			module.SetupFrame:Update()
		else
			module.SetupFrame:Show()
		end
	end)

	options.lastUpdate = ELib:Text(options.REMINDERS_SCROLL_LIST,"",11):Point("LEFT",AddButton,"RIGHT",10,0):Color()
	function options.lastUpdate:Update()
		if VMRT.Reminder.LastUpdateName and VMRT.Reminder.LastUpdateTime then
			self:SetText( L.NoteLastUpdate..": "..VMRT.Reminder.LastUpdateName.." ("..date("%H:%M:%S %d.%m.%Y",VMRT.Reminder.LastUpdateTime)..")" )
		end
	end
	options.lastUpdate:Update()

	options.SyncButton = MLib:Button(options.REMINDERS_SCROLL_LIST,LR.SendAll,13):Point("TOPLEFT",AddButton,"BOTTOMLEFT",0,-5):Size(100,20):OnClick(function()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_SYNC_ALL_CONFIRMATION",
			title = LR["Sync All"],
			text = LR.SyncAllConfirm,
			buttons = {
				{
					text = YES,
					func = function()
						module:Sync()
					end,
				},
				{
					text = NO,
				},
			},
		})
	end)

	options.ResetForAllButton = MLib:Button(options.REMINDERS_SCROLL_LIST,LR.DeleteAll,13):Point("TOPRIGHT",options.scrollList,"BOTTOMRIGHT",-5,-30):Size(120,20):OnClick(function()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_DELETE_ALL_ALERT",
			title = LR.DeleteAll.."?",
			buttons = {
				{
					text = YES,
					func = function()
						wipe(VMRT.Reminder.data)
						if options.Update then
							options.Update()
						end
						module:ReloadAll()
					end,
				},
				{
					text = NO,
				},
			},
		})
	end)

	options.ExportButton = MLib:Button(options.REMINDERS_SCROLL_LIST,LR.ExportAll,13):Point("RIGHT",options.ResetForAllButton,"LEFT",-5,0):Size(120,20):OnClick(function()
		local export = module:Sync(true)
		MRT.F:Export(export)
	end)

	local importWindow
	options.ImportButton = MLib:Button(options.REMINDERS_SCROLL_LIST,LR.Import,13):Point("RIGHT",options.ExportButton,"LEFT",-5,0):Size(80,20):OnClick(function()
		if not importWindow then
			importWindow = ELib:Popup(LR.Import):Size(650,615)
			importWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			importWindow.Edit = ELib:MultiEdit(importWindow):Point("TOP",0,-20):Size(640,570)
			importWindow.Save = MLib:Button(importWindow,LR.Import,13):Tooltip(LR.ImportTip):Point("BOTTOM",0,2):Size(120,20):OnClick(function()
				importWindow:Hide()
				if IsShiftKeyDown() then
					MLib:DialogPopup({
						id = "EXRT_REMINDER_CLEAR_IMPORT_ALERT",
						title = LR["Clear Import"],
						text = LR.ClearImport,
						buttons = {
							{
								text = ACCEPT,
								func = function()
									wipe(VMRT.Reminder.data)
									module:ProcessTextToData(importWindow.Edit:GetText(),true)
								end,
							},
							{
								text = CANCEL,
							},
						},
					})
				else
					module:ProcessTextToData(importWindow.Edit:GetText(),true)
				end
			end)
		end
		importWindow.Edit:SetText("")
		importWindow:NewPoint("CENTER",UIParent,0,0)
		importWindow:Show()
		importWindow.Edit.EditBox:SetScript("OnEscapePressed",function(self)
			importWindow:Hide()
		end)
		importWindow.Edit.EditBox:SetFocus()
	end)

	options:UpdateData()
end
