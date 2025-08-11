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

---@class RaidAnalyzer: MRTmodule
local parentModule = MRT.A.RaidAnalyzer
if not parentModule then return end

---@class GroupInvites: MRTmodule
local module = AddonDB:New("GroupInvites",nil,true)
if not module then return end

module.db.invitersReady = {}

local function prettyPrint(...)
	print("|cff0088ff[Group Inviter]|r", ...)
end

local function GroupInvitesInit()
	local GroupInvites = parentModule.options:NewPage("Group Invites")
	local self = GroupInvites
	module.GroupInvitesUI = GroupInvites

	local CurrentInviter --name

	local UpdateInviterListButton = MLib:Button(self, LR["Update inviters list"]):Point("TOPLEFT", self, "TOPLEFT", 5, -5):Size(285, 20):OnClick(function(self)
		wipe(module.db.invitersReady)
		AddonDB:SendComm("GROUP_INVITE_POLL")
	end)

	local InvitersDropDown = ELib:DropDown(self, 220, -1):Point("TOPLEFT", UpdateInviterListButton,"BOTTOMLEFT", 0, -5):Size(285, 20):SetText("Choose Inviter")

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
		for name in next, module.db.invitersReady do
			local faction = UnitFactionGroup(name)
			List[#List + 1] = {
				text = (faction == "Horde" and "|cffff0000" or faction == "Alliance" and "|cff0080ff" or "") .. name,
				arg1 = name,
				func = InvitersDropDown_SetValue,
			}
		end
		sort(List, function(a, b)
			return a.arg1 < b.arg1
		end)
	end

	local Fields = {}
	for i = 1, 18 do
		Fields[i] = {}
		Fields[i]["Edit"] = ELib:Edit(self):Point("TOPLEFT", self, "TOPLEFT", 5, -80 - i * 25):Size(200, 20):OnChange(function(self)
			local text = self:GetText()

			if text == "" then
				text = nil
			end
		end)

		Fields[i]["Button"] = MLib:Button(self, "Invite"):Tooltip("Hold shift to NOT promote to assistant\nHold ctrl to start invite timer"):Point("LEFT", Fields[i]["Edit"], "RIGHT", 5,0):Size(80, 20):OnClick(function(self)
			local text = Fields[i]["Edit"]:GetText()
			if text == "" then
				text = nil
			end
			if IsControlKeyDown() then
				if self.timer then
					self:StopTimer()
				else
					self:StartTimer()
				end
			end

			if module:InviteSingle(i) then
				self:StopTimer()
			end
		end)
		Fields[i]["Icon"] = CreateFrame("Frame", nil, Fields[i]["Button"])
		Fields[i]["Icon"].t = Fields[i]["Icon"]:CreateTexture(nil, "ARTWORK")
		Fields[i]["Icon"].t:SetPoint("LEFT", Fields[i]["Button"], "RIGHT", 5, 0)
		Fields[i]["Icon"].t:SetSize(16, 16)
		SetInviteIcon(Fields[i]["Icon"].t, 0)

		Fields[i]["Button"].StartTimer = function(self)
			ELib:Border(self, 1, .24, .45, 1, 1)
			self.timer = C_Timer.NewTicker(10, function()
				if module:InviteSingle(i) then
					self:StopTimer()
					module:PlayInviteSuccessSound()
				end
			end)
		end
		Fields[i]["Button"].StopTimer = function(self)
			if self.timer then
				self.timer:Cancel()
				self.timer = nil
				ELib:Border(self, 1, 0, 0, 0, 1)
			end
		end
	end
	local multiInvite = ""
	local MultiLineEditField = ELib:MultiEdit(self):Point("BOTTOMRIGHT", self, "BOTTOMRIGHT", -10, 38):Size(530, 445):OnChange(function(self)
		local text = self:GetText()

		multiInvite = text
	end)
	do
		ELib:Border(MultiLineEditField, 1, .24, .25, .30, 1)
		local msgFont, msgFontSize, msgFontStyle = MultiLineEditField.EditBox:GetRegions():GetFont()
		MultiLineEditField:Font(msgFont, 14, msgFontStyle)
		ELib:DecorationLine(MultiLineEditField, true, "BACKGROUND", 4):Point("TOPLEFT", MultiLineEditField, "TOPLEFT",0, 0):Point("BOTTOMRIGHT", MultiLineEditField, "BOTTOMRIGHT", 0, 0):SetVertexColor(0.0, 0.0, 0.0, 0.35)
	end
	local InviteAllFromListButton = MLib:Button(self, "Invite All From List"):Tooltip("Hold shift to NOT promote to assistant"):Point("TOPLEFT",MultiLineEditField, "BOTTOMLEFT", 0, -5):Size(264, 24):OnClick(function(self)
		if not CurrentInviter then
			return
		end
		module:InviteMulti()
	end)

	local ProcessToSingularInvitesButton = MLib:Button(self, "Process To Singular Invites"):Point("TOPLEFT", InviteAllFromListButton, "TOPRIGHT", 3, 0):Size(264, 24):OnClick(function(self)
		local data = { strsplit("\n", multiInvite) }
		for i = 1, #data do
			Fields[i].Edit:SetText(string.trim(data[i]))
		end
	end)

	local InviteAllButton = MLib:Button(self, "Invite All"):Tooltip("Hold shift to NOT promote to assistant\nHold ctrl to start invite timer"):Point("BOTTOMLEFT", self, "BOTTOMLEFT", 5,10):Size(285, 24):OnClick(function(self)
		if not CurrentInviter then
			return
		end
		if IsControlKeyDown() then
			if self.timer then
				self:StopTimer()
			else
				self:StartTimer()
			end
		end

		if module:InviteAll() then
			self:StopTimer()
		end
	end)
	function InviteAllButton:StartTimer()
		ELib:Border(self, 1, .24, .45, 1, 1)
		self.timer = C_Timer.NewTicker(10, function()
			if module:InviteAll() then
				self:StopTimer()
				module:PlayInviteSuccessSound()
			end
		end)
	end
	function InviteAllButton:StopTimer()
		if self.timer then
			self.timer:Cancel()
			self.timer = nil
			ELib:Border(self, 1, 0, 0, 0, 1)
		end
	end

	function module:PlayInviteSuccessSound()
		MRT.A.Reminder:PlayTTS("Invite Succeeded")
	end

	local function PromoteBeforeInvite(name)
		if IsShiftKeyDown() then
			return
		end
		local ambiguatedName = Ambiguate(name,"none")

		if ambiguatedName == MRT.SDB.charKey or ambiguatedName == MRT.SDB.charName then
			return
		end

		if MRT.F.IsPlayerRLorOfficer(name) then
			return
		end

		PromoteToAssistant(name)

		if module.demoteTimer then -- todo: support multiple timers
			module.demoteTimer:Cancel()
		end

		module.demoteTimer = MRT.F.ScheduleTimer(DemoteAssistant, 5, name)
	end

	function module:InviteMulti()
		if not CurrentInviter then
			return
		end

		local list = {}
		local data = { strsplit("\n", multiInvite) }

		if not data or #data == 0 then
			return
		end

		for i=1, #data do
			local text = string.trim(data[i])
			text = text:gsub("/inv", ""):trim()
			local ambiguatedName = Ambiguate(text,"none")
			if text ~= "" and not UnitInRaid(ambiguatedName) and not UnitInParty(ambiguatedName) and not UnitIsVisible(ambiguatedName) and not UnitExists(ambiguatedName) then
				list[#list + 1] = text
			end
		end


		PromoteBeforeInvite(CurrentInviter)
		tinsert(list, 1, CurrentInviter)
		AddonDB:SendComm("GROUP_INVITE_REQUEST_INVITE", AddonDB:CreateHeader(list))
	end

	---@return boolean true if can't invite due to already being in group or no inviter selected
	function module:InviteSingle(i)
		if not CurrentInviter then
			return true
		end

		local text = string.trim(Fields[i]["Edit"]:GetText())
		text = text:gsub("/inv", ""):trim()

		if not text or text == "" then
			return true
		end

		local ambiguatedName = Ambiguate(text,"none")
		if UnitInRaid(ambiguatedName) or UnitInParty(ambiguatedName) or UnitIsVisible(ambiguatedName) or UnitExists(ambiguatedName) then
			return true
		end

		PromoteBeforeInvite(CurrentInviter)
		AddonDB:SendComm("GROUP_INVITE_REQUEST_INVITE", AddonDB:CreateHeader(CurrentInviter, text))
		return nil
	end

	function module:InviteAll()
		if not CurrentInviter then
			return true
		end

		local list = {}

		for i = 1, #Fields do
			local text = string.trim(Fields[i]["Edit"]:GetText())
			text = text:gsub("/inv", ""):trim()
			local ambiguatedName = Ambiguate(text,"none")
			if text ~= "" and not UnitInRaid(ambiguatedName) and not UnitInParty(ambiguatedName) and not UnitIsVisible(ambiguatedName) and not UnitExists(ambiguatedName) then
				list[#list + 1] = text
			end
		end

		if #list == 0 then
			return true
		end

		PromoteBeforeInvite(CurrentInviter)
		tinsert(list, 1, CurrentInviter)
		AddonDB:SendComm("GROUP_INVITE_REQUEST_INVITE", AddonDB:CreateHeader(list))
	end

	ELib:DecorationLine(self, true, "BACKGROUND", -5):Point("TOPLEFT", self, "TOPLEFT", 0, -96):Point("BOTTOMRIGHT", self, "TOPRIGHT", 0, -97)
	ELib:DecorationLine(self, true, "BACKGROUND", -5):Point("TOPLEFT", self, "TOPLEFT", 300, -96):Point("BOTTOMRIGHT", self, "BOTTOMLEFT", 301, 0)
	AddonDB:SendComm("GROUP_INVITE_POLL")
end

tinsert(parentModule.options.ModulesToLoad,GroupInvitesInit)

-- https://www.townlong-yak.com/framexml/live/GlobalStrings.lua/RU
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
		AddonDB:SendComm("GROUP_INVITE_ERROR", AddonDB:CreateHeader(module.db.lastInviteRequester, errorMessage))
	end
end

function module.main:CHAT_MSG_SYSTEM(...)
	local errorMessage = ...
	if errorMessage:find(ERR_BAD_PLAYER_NAME_S:gsub("%%s","[^ ]+")) or errorMessage:find(ERR_ALREADY_IN_GROUP_S:gsub("%%s","[^ ]+")) then
		AddonDB:SendComm("GROUP_INVITE_ERROR", AddonDB:CreateHeader(module.db.lastInviteRequester, errorMessage))
	end
end

function module:RegisterInviteErrorEvents()
	module:RegisterEvents("CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE")
end

function module:UnregisterInviteErrorEvents()
	module:UnregisterEvents("CHAT_MSG_SYSTEM", "UI_ERROR_MESSAGE")
end

function module:ProcessInvite(name,sender)
	prettyPrint("|cffffff00" .. sender .. " Requested Invite: " .. name)
	if name and name:find("/inv") then
		name = name:gsub("/inv", ""):trim()
	end
	C_PartyInfo.InviteUnit(name)
end

AddonDB:RegisterComm("GROUP_INVITE_POLL", function(prefix, sender, data, channel, key)
	AddonDB:SendComm("GROUP_INVITE_POLL_RESPONSE")
end)

AddonDB:RegisterComm("GROUP_INVITE_POLL_RESPONSE", function(prefix, sender, data, channel, key)
	sender = MRT.F.delUnitNameServer(sender)
	module.db.invitersReady[sender] = true
	if module.GroupInvitesUI and module.GroupInvitesUI:IsVisible() and module.UpdateInvitersDropDown then
		module:UpdateInvitersDropDown()
	end
end)

AddonDB:RegisterComm("GROUP_INVITE_REQUEST_INVITE", function(prefix, sender, data, channel, key)
	if not AddonDB:CheckSenderPermissions(sender, true) then
		return
	end

	local inviteData = {AddonDB:ParseHeader(data)}
	local inviter = inviteData[1]

	if inviter ~= MRT.SDB.charKey and inviter ~= MRT.SDB.charName then
		return
	end

	module.db.lastInviteRequester = sender
	module:RegisterInviteErrorEvents()
	sender = MRT.F.delUnitNameServer(sender)

	for i=2, #inviteData do
		module:ProcessInvite(inviteData[i],sender)
	end

	if module.db.UnregisterTimer then
		module.db.UnregisterTimer:Cancel()
	end
	module.db.UnregisterTimer = MRT.F.ScheduleTimer(module.UnregisterInviteErrorEvents, 2)
end)

AddonDB:RegisterComm("GROUP_INVITE_ERROR", function(prefix, sender, data, channel, key)
	local requester, errorMsg = AddonDB:ParseHeader(data)
	if requester ~= MRT.SDB.charKey and requester ~= MRT.SDB.charName then
		return
	end
	prettyPrint("|cffff0000" .. MRT.F.delUnitNameServer(sender) .. " Error:|r |cffffff00" .. errorMsg)
end)

