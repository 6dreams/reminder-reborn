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



function module.options:BinScrollButtonsListInitialize()
	module.options.BinScrollButtonsListInitialize = nil
	local prettyPrint = module.prettyPrint
	local encountersList = AddonDB.EJ_DATA.encountersList

	self.DELETED_TAB.ScrollList = ELib:ScrollButtonsList(self.DELETED_TAB):Point("TOPLEFT",0,-2):Size(760,508)
	ELib:DecorationLine(self.DELETED_TAB.ScrollList):Point("TOP",self.DELETED_TAB.ScrollList,"BOTTOM",0,0):Point("LEFT",self):Point("RIGHT",self):Size(0,1)
	self.DELETED_TAB.ScrollList.ButtonsInLine = 2
	self.DELETED_TAB.ScrollList.mouseWheelRange = 50
	ELib:Border(self.DELETED_TAB.ScrollList,0)

	local function DeleteFromRemoved(self)
		local parent = self:GetParent()
		local token = parent.uid
		if not token then return end

		if not IsShiftKeyDown() then
			MLib:DialogPopup({
				id = "EXRT_REMINDER_DELETE_BIN",
				title = LR["Delete from 'removed list'"],
				text = LR.Listdelete.."?",
				buttons = {
					{
						text = LR.Listdelete,
						func = function()
							prettyPrint("Reminder removed from 'removed list'")
							VMRT.Reminder.removed[ token ] = nil
							module.options:UpdateBinData()
						end,
					},
					{
						text = NO
					}
				},
			})
		else
			prettyPrint("Reminder removed from 'removed list'")
			VMRT.Reminder.removed[ token ] = nil
			module.options:UpdateBinData()
		end
	end

	self.ClearRemovedButton = MLib:Button(self.DELETED_TAB,LR["Clear Removed"],13):Point("TOPRIGHT",self.DELETED_TAB.ScrollList,"BOTTOMRIGHT",-5,-30):Size(140,20):OnClick(function()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_CLEAR_REMOVED",
			title = LR["Clear Removed"],
			text = LR.ClearRemove,
			buttons = {
				{
					text = ACCEPT,
					func = function()
						wipe(VMRT.Reminder.removed)
						prettyPrint("Cleared 'removed list'")
						module.options:UpdateBinData()
					end,
				},
				{
					text = CANCEL,
				},
			},
		})
	end)

	function module:DeleteForAllFromRemoved()
		local pass, reason = AddonDB:CheckSelfPermissions()
		if not pass then
			if reason then
				prettyPrint("|cffee5555" .. reason .. "|r")
			end
			return
		end
		prettyPrint("Deleting all reminders from 'removed list'")
		local r = {}
		local rc = 0
		for token,_ in next, VMRT.Reminder.removed do
			r[#r+1] = token
			rc = rc + 1
		end
		if rc > 0 then
			prettyPrint("|cff80ff00Deleted token count: " .. rc .. "|r")
			local str = table.concat(r,"^")
			local encoded = AddonDB:CompressString(str)
			AddonDB:SendComm("REMINDER_DEL",encoded)
		else
			prettyPrint("|cffee5555Deleted token count: " .. rc .. "|r")
		end

		for token,_ in next, VMRT.Reminder.removed do
			if not module:GetDataOption(token, "LOCKED") then
				VMRT.Reminder.data[ token ] = nil
			end
		end

		if module.options.Update then
			module.options.Update()
		end
		module:ReloadAll()
	end

	self.DeleteAllFromRemovedButton = MLib:Button(self.DELETED_TAB,LR["Delete All Removed"],13):Tooltip(LR["Deletes reminders from 'removed list' to all raiders"]):Point("RIGHT",self.ClearRemovedButton,"LEFT",-5,0):Size(140,20):OnClick(function()
		MLib:DialogPopup({
			id = "EXRT_REMINDER_DELETE_ALL_REMOVED",
			title = LR["Delete All Removed"],
			text = LR.ForceRemove,
			buttons = {
				{
					text = ACCEPT,
					func = module.DeleteForAllFromRemoved,
				},
				{
					text = CANCEL,
				},
			},
		})
	end)

	self.DELETED_TAB.DeletedRemindersTip = ELib:Text(self.DELETED_TAB,LR.DeletedTabTip,11):Point("TOPLEFT",self.DELETED_TAB.ScrollList,"BOTTOMLEFT",5,-10):Color()

	local function RestoreData(self)
		if not self.data then
			return
		end

		local data = self.data.data.archived_data
		if data then
			module:EditData(data)
			module.SetupFrame.SaveButton:Click()
		end
		module.options:UpdateBinData()
	end

	function self.DELETED_TAB.ScrollList:ButtonClick(button)
		RestoreData(self)
	end

	local function ButtonIcon_OnEnter(self)
		if not self["tooltip"..(self.status or 1)] then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self["tooltip"..(self.status or 1)])
		GameTooltip:Show()
	end

	local function ButtonIcon_OnLeave(self)
		GameTooltip_Hide()
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

	local function Button_OnEnter(self)
		if not self["tooltip"] then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		if self.data and self.data.data and self.data.data.archived_data then
			module:AddTooltipLinesForData(self.data.data.archived_data)
			GameTooltip:AddLine(" ")
		end

		GameTooltip:AddLine(self["tooltip"])
		GameTooltip:AddLine("Click to restore",1,1,1)
		GameTooltip:Show()
	end
	local function Button_OnLeave(self)
		GameTooltip_Hide()
	end

	local function Button_Lvl1_Remove(self)
		MLib:DialogPopup({
			id = "EXRT_REMINDER_CLEAR_LVL1_REMOVE",
			title = LR["Delete Section"],
			text = LR.DeleteSection.."?",
			buttons = {
				{
					text = YES,
					func = function()
						for token,data in next, VMRT.Reminder.removed do
							if (type(data) == 'table' and (self.bossID and data.boss == self.bossID)) or
								(type(data) == 'boolean' and self.bossID and self.bossID == 0)
							then
								VMRT.Reminder.removed[ token ] = nil
							end
						end
						module.options:UpdateBinData()
						if module.options.Update then
							module.options.Update()
						end
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
			self.text:FontSize(18)
			self.text:SetText("T")
			self.text:Show()
		elseif iconType == 3 then
			self.text:FontSize(8)
			self.text:SetText("t")
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
	local lvl1_color1, lvl1_color2 = CreateColor(.18,.13,.13,1), CreateColor(.22,.16,.16,1)
	local lvl2_color1, lvl2_color2 = CreateColor(0.17,0.12,0.12,1), CreateColor(0.35,0.20,0.20,1)
	function self.DELETED_TAB.ScrollList:ModButton(button,level)
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

			button.Texture:SetGradient("VERTICAL",lvl1_color1, lvl1_color2)
		elseif level == 2 then
			local textObj = button:GetTextObj()
			textObj:SetPoint("LEFT",button,"LEFT",25,0)
			textObj:SetPoint("RIGHT",button,"LEFT",240,0)
			local font, size, style = textObj:GetFont()
			textObj:SetFont(font, 12, style)
			textObj:SetShadowColor(0,0,0,1)
			textObj:SetShadowOffset(1,-1)

			button.typeicon = CreateFrame("Frame",nil,button)
			button.typeicon:SetPoint("LEFT",button,"LEFT",5,0)
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

			button.delete = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-5,0)
			button.delete:SetScript("OnClick",DeleteFromRemoved)
			button.delete.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")
			button.delete.tooltip1 = LR.ListdeleteTip

			-- button.restore = lineStyledButton(button,LR["Restore"]):Point("RIGHT",button.delete,"LEFT",0,0):Size(100,20):OnClick(RestoreData)


			button:SetScript("OnEnter",Button_OnEnter)
			button:SetScript("OnLeave",Button_OnLeave)

			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
			button.Texture:SetGradient("VERTICAL",lvl2_color1, lvl2_color2)
		end
	end
	function self.DELETED_TAB.ScrollList:ModButtonUpdate(button,level)
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
			else
				button.bossImg:SetPoint("LEFT",2,0)
			end
		elseif level == 2 then
			button:GetTextObj():SetWordWrap(false)

			local data = button.data

			if data.nohud and not button.ishudhidden then
				button.ishudhidden = true
			elseif not data.nohud and button.ishudhidden then
				button.ishudhidden = false
			end
			if data.data.archived_data then
				button:Enable()
			else
				button:Disable()
			end

			if data.data then
				local data = data.data
				button.tooltip = data.time and "DELETED ("..date("%H:%M:%S %d.%m.%Y",data.time)..")"

				if data.type == "WA" then -- WA
					button.typeicon:SetType(7)
				elseif data.type == "FRAMEGLOW" then  -- RAIDFRAME
					button.typeicon:SetType(4)
				elseif data.type == "NAMEPLATEGLOW" then  -- NAMEPLATE
					button.typeicon:SetType(5)
				elseif data.type == "/say" then -- CHAT
					button.typeicon:SetType(6)
				elseif data.type == "SMALLTEXT" then
					button.typeicon:SetType(2)
				elseif data.type == "BIGTEXT" then
					button.typeicon:SetType(3)
				elseif data.type == "T" then -- NORMAL TEXT
					button.typeicon:SetType(1)
				elseif data.type == "BAR" then -- BAR
					button.typeicon:SetType(8)
				else -- NORMAL TEXT
					button.typeicon:SetType(1)
				end
			else
				button.typeicon:SetType()
			end
		end
	end

	function self:UpdateBinData()
		local currZoneID = select(8,GetInstanceInfo())

		local Mdata = {}
		local zoneHeaders = {}
		for token,data in next, VMRT.Reminder.removed do
			local tableToAdd
			local bossID, zoneID

			local searchPat = module.options.search
			if module:SearchInData(data.archived_data,searchPat) then

				if data.old and not data.boss then
					bossID = -1
				else
					bossID = data.boss
					zoneID = data.zoneID
				end
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

				if bossID then
					local bossData = MRT.F.table_find3(Mdata,bossID,"bossID")
					if not bossData then
						local instanceName
						if bossID == -1 then
							instanceName = ""
						end
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

						if bossID == -1 then
							encounterName = "Old data"
						elseif encounterName == "" then
							encounterName = nil
						end
						bossData = {
							bossID = bossID,
							name = (instanceName and instanceName ~= "" and instanceName..": " or "")..(encounterName or LR.EncounterID.." "..bossID)..(bossID == VMRT.Reminder.lastEncounterID and " |cff00ff00("..LR.LastPull..")|r" or ""),
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
					name = type(data) == 'table' and data.name or
						(data.archived_data and data.archived_data.msg and module:FormatMsg(data.archived_data.msg)) or
						("~"..LR.NoName),
					uid = token,
					data = data,
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
				if a.name:lower() ~= b.name:lower() then
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

		module.options.DELETED_TAB.ScrollList.data = Mdata
		module.options.DELETED_TAB.ScrollList:Update(true)
	end
end
