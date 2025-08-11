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


---------------------------------------
-- Initializing LastSyncWindow. Would prefer some renaming and restiling here. Also need to refactor creating LastSync data as it seems unstable.
---------------------------------------
function options:InitializeLastSyncWindow()
	local VERTICALNAME_COUNT = 30
	local LINE_NAME_WIDTH = 5
	local VERTICALNAME_WIDTH = 24
	local PAGE_HEIGHT = 24
	local TOTAL_HEIGHT = 135

	local LastSyncWindow = ELib:Template("ExRTDialogModernTemplate",UIParent)

	LastSyncWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
	LastSyncWindow:SetSize(LINE_NAME_WIDTH + (VERTICALNAME_COUNT * VERTICALNAME_WIDTH) + 10,TOTAL_HEIGHT)
	LastSyncWindow:Hide()

	LastSyncWindow:SetPoint("CENTER")
	LastSyncWindow:SetFrameStrata("DIALOG")
	LastSyncWindow:SetDontSavePosition(true)

	LastSyncWindow:SetMovable(true)
	LastSyncWindow:EnableMouse(true)

	LastSyncWindow:RegisterForDrag("LeftButton")
	LastSyncWindow:SetScript("OnDragStart", function(self)
		LastSyncWindow:StartMoving()
	end)
	LastSyncWindow:SetScript("OnDragStop", function(self)
		LastSyncWindow:StopMovingOrSizing()
	end)
	ELib:Border(LastSyncWindow,1,.24,.25,.30,1)
	LastSyncWindow.border = MRT.lib.CreateShadow(LastSyncWindow,20)

	local function LineName_Icon_OnEnter(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Show(self,nil,self.HOVER_TEXT)
		end
	end
	local function LineName_Icon_OnLeave(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Hide()
		end
	end

	function LastSyncWindow.SetIcon(self,type) -- 1 = x 2 = v 3 = lock 4 = ...
		if not type or type == 0 then
			self:SetAlpha(0)
		elseif type == 1 then
			self:SetTexCoord(0.5,0.5625,0.5,0.625)
			self:SetVertexColor(.8,0,0,1)
		elseif type == 2 then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(0,.8,0,1)
		elseif type == 3 then
			self:SetTexCoord(0.625,0.6875,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == 4 then
			self:SetTexCoord(0.875,0.9375,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == "OUTDATED" then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		end
	end

	local function RaidNames_OnEnter(self)
		local t = self.t:GetText()
		if t ~= "" then
			ELib.Tooltip.Show(self,"ANCHOR_LEFT",t)
		end
	end

	local raidNames = CreateFrame("Frame",nil,LastSyncWindow)

	for i=1,VERTICALNAME_COUNT do
		raidNames[i] = ELib:Text(raidNames,"RaidName"..i,10):Point("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + VERTICALNAME_WIDTH*(i-1),-(TOTAL_HEIGHT-PAGE_HEIGHT)):Color(1,1,1)

		local f = CreateFrame("Frame",nil,LastSyncWindow)
		f:SetPoint("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + VERTICALNAME_WIDTH*(i-1),-(TOTAL_HEIGHT-PAGE_HEIGHT))
		f:SetSize(VERTICALNAME_WIDTH,TOTAL_HEIGHT-PAGE_HEIGHT)
		f:SetScript("OnEnter",RaidNames_OnEnter)
		f:SetScript("OnLeave",ELib.Tooltip.Hide)
		f.t = raidNames[i]

		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", function(self)
			self:GetParent():StartMoving()
		end)
		f:SetScript("OnDragStop", function(self)
			self:GetParent():StopMovingOrSizing()
		end)

		local t = LastSyncWindow:CreateTexture(nil,"BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT",raidNames[i],"BOTTOMLEFT",0,0)
		t:SetDrawLayer("ARTWORK")
		t:SetSize(VERTICALNAME_WIDTH,PAGE_HEIGHT)
		if i%2==1 then
			t:SetColorTexture(.5,.5,1,.05)
			t.Vis = true
		end

		local icon = LastSyncWindow:CreateTexture(nil,"ARTWORK")
		raidNames[i].icon = icon
		icon:SetPoint("CENTER",raidNames[i].t,"CENTER",0,0)
		icon:SetSize(20,20)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		LastSyncWindow.SetIcon(icon,0) -- 1 = x 2 = v 3 = lock 4 = ...

		icon.hoverFrame = CreateFrame("Frame",nil,LastSyncWindow)
		icon.hoverFrame:Hide()
		icon.hoverFrame:SetAllPoints(icon)
		icon.hoverFrame:SetScript("OnEnter",LineName_Icon_OnEnter)
		icon.hoverFrame:SetScript("OnLeave",LineName_Icon_OnLeave)
	end
	local group = raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local function sortByName(nameA,nameB)
		if nameA and nameB then
			local shortNameA = Ambiguate(nameA,"none")
			local shortNameB = Ambiguate(nameB,"none")

			local hasCyrA = nameA:find("([\194-\244])") --("([%z\1-\127\194-\244][\128-\191]*)(.*)")
			local hasCyrB = nameB:find("([\194-\244])")

			local hasDBA = module.db.lastSyncData[nameA]
			local hasDBB = module.db.lastSyncData[nameB]

			local isVisA = UnitIsVisible(shortNameA)
			local isVisB = UnitIsVisible(shortNameB)

			local isConA = UnitIsConnected(shortNameA)
			local isConB = UnitIsConnected(shortNameB)

			if isConA and not isConB then
				return true
			elseif not isConA and isConB then
				return false
			elseif hasCyrA and not hasCyrB then
				return true
			elseif not hasCyrA and hasCyrB then
				return false
			elseif hasDBA and not hasDBB then
				return true
			elseif not hasDBA and hasDBB then
				return false
			elseif isVisA and not isVisB then
				return true
			elseif not isVisA and isVisB then
				return false
			else
				return nameA < nameB
			end
		end
	end

	function LastSyncWindow:Update(token)
		local namesList = {}
		for unit in AddonDB:IterateGroupMembers() do
			namesList[#namesList + 1] = AddonDB:GetFullName(unit)
		end
		sort(namesList,sortByName)

		local raidNamesUsed = 0
		for i=1,#namesList do
			raidNamesUsed = raidNamesUsed + 1
			if not raidNames[raidNamesUsed] then
				break
			end

			local fullName = namesList[i]
			local name = Ambiguate(namesList[i], "none")
			local coloredName = AddonDB:ClassColorName(name)
			raidNames[raidNamesUsed]:SetText(coloredName)

			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
			local data = module.db.lastSyncData[fullName] and module.db.lastSyncData[fullName][token]

			if data == "NOLS" then -- no lastSync but reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,3)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "Have reminder but no last sync data provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif data == "NODATA" then -- no reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,1)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No data found"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif tonumber(data) then -- lastSync info
				if VMRT.Reminder.data[token].lastSync <= tonumber(data) then
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,2)
				else
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,"OUTDATED")
				end
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = date("%X %x",data)
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			else
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,4)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No proper response provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			end
		end

		for i=raidNamesUsed+1,#raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
			LastSyncWindow.SetIcon(raidNames[i].icon,0)
			raidNames[i].icon.hoverFrame:Hide()
		end


	end
	LastSyncWindow:Update()

	function module:GetLastSync(token)
		wipe(module.db.lastSyncData)
		AddonDB:SendComm("REMINDER_DATA_SYNC_CHECK", token)

		LastSyncWindow:Update(token)
		C_Timer.After(1.5,function() LastSyncWindow:Update(token) end)

		LastSyncWindow:Show()
	end
end
