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

if not EJ_GetInstanceInfo then return end

---@class RaidAnalyzer: MRTmodule
local parentModule = MRT.A.RaidAnalyzer
if not parentModule then return end

---@class RaidLockouts: MRTmodule
local module = AddonDB:New("RaidLockouts",nil,true)
if not module then return end

module.db.responces = {}

local CURRENT_INSTANCE = MRT.isCata and 671 or MRT.clientVersion >= 110000 and 2657 or 2549 -- 1530 nighthold for test
local CURRENT_DIFFICULTY = MRT.isCata and 4 or 15 -- 17 nighthold for test

module.db.encountersOrder = {}

local function SetIcon(self,type)
    if self.lastType == type then
        return
    end
    self.lastType = type

    if not type or type == 0 then
        self:SetAlpha(0)
        return
    end

    self:SetAlpha(1)

    if type == 1 then -- not ready
        self:SetAtlas("UI-LFG-DeclineMark")
    elseif type == 2 then -- ready
        self:SetAtlas("UI-LFG-ReadyMark")
    end
end
local WA_IterateGroupMembers = AddonDB.IterateGroupMembers
local function sortByName(a,b)
    if a and b and a.name and b.name then
        local nameA = a.name
        local nameB = b.name
        local shortNameA = MRT.F.delUnitNameServer(nameA)
        local shortNameB = MRT.F.delUnitNameServer(nameB)

        local hasCyrA = nameA:find("([\194-\244])") --("([%z\1-\127\194-\244][\128-\191]*)(.*)")
        local hasCyrB = nameB:find("([\194-\244])")

        local hasDBA = module.db.responces[nameA]
        local hasDBB = module.db.responces[nameB]

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
            return a.name < b.name
        end
    end
end

local function UpdatePage(self)
    if self.UpdateButton then
        self.UpdateButton:Enable()
    end

    local journalInstanceID = AddonDB.EJ_DATA.instanceIDtoEJ[CURRENT_INSTANCE]
    -- wrap in pcall
    -- EJ_SelectInstance(journalInstanceID)
    local ok, result = pcall(EJ_SelectInstance, journalInstanceID)
    if not ok then
        print("RaidLockouts: Error in EJ_SelectInstance", result)
        return
    end

    local bosses = {}

    for i = 1, 20 do
        local name = EJ_GetEncounterInfoByIndex(i, journalInstanceID)
        if not name then break end

        bosses[#bosses + 1] = {
            name = name,
            i = i,
        }
    end

    local sortedTable = {}

    for i = 1, #bosses do
        sortedTable[#sortedTable + 1] = bosses[i]
    end

    self.mainScroll.ScrollBar:Range(0, max(0, #sortedTable * self.LINE_HEIGHT - 1 - self.PAGE_HEIGHT), nil, true)

    local namesList, namesList2 = {}, {}
    for unit in WA_IterateGroupMembers() do
        -- if UnitIsConnected(unit) then
            local name, realm = UnitName(unit)
            local normalizedRealm = MRT.SDB.realmKey or GetNormalizedRealmName()
            local fullName = name.."-"..(realm or normalizedRealm)
            local class = UnitClassBase(unit)
            namesList[#namesList + 1] = {
                name = fullName,
                class = class,
            }
        -- end
    end


    -- for i=1,30 do
    --     namesList[#namesList + 1] = {
    --         name = "Player"..i,
    --         class = "WARRIOR",
    --     }
    -- end
    sort(namesList, sortByName)

    if self.isDynamic then
        local height = self.LINE_HEIGHT * (#sortedTable)
        self:SetSize(self.PAGE_WIDTH, height + 80)
        self.mainScroll:SetSize(self.PAGE_WIDTH, height)
        if #namesList <= self.VERTICALNAME_COUNT then
            self.mainScroll:SetPoint("BOTTOMLEFT", 0, 0)
        else
            self.mainScroll:SetPoint("BOTTOMLEFT", 0, 20)
        end
    end

    if #namesList <= self.VERTICALNAME_COUNT then
        self.raidSlider:Hide()
        self.prevPlayerCol = 0
    else
        self.raidSlider:Show()
        self.raidSlider:Range(0, #namesList - self.VERTICALNAME_COUNT)
    end

    local raidNamesUsed = 0
    for i = 1 + self.prevPlayerCol, #namesList do
        raidNamesUsed = raidNamesUsed + 1
        if not self.raidNames[raidNamesUsed] then
            break
        end
        local name = namesList[i].name
        local shortName = MRT.F.delUnitNameServer(namesList[i].name)
        self.raidNames[raidNamesUsed]:SetText(shortName)
        self.raidNames[raidNamesUsed]:SetTextColor(MRT.F.classColorNum(namesList[i].class))
        self.raidNames[raidNamesUsed]:SetAlpha(1)

        namesList2[raidNamesUsed] = name
        if not UnitIsConnected(shortName) then
            self.raidNames[raidNamesUsed]:SetTextColor(0.3,0.3,0.3)
        elseif not UnitIsVisible(shortName) then
            self.raidNames[raidNamesUsed]:SetAlpha(.5)
        end
        if self.raidNames[raidNamesUsed].Vis then
            self.raidNames[raidNamesUsed]:SetAlpha(.05)
        end
    end
    for i = raidNamesUsed + 1, #self.raidNames do
        self.raidNames[i]:SetText("")
        self.raidNames[i].t:SetAlpha(0)
    end

    local lineNum = 1
    local backgroundLineStatus = (self.prevTopLine % 2) == 1


    for i = self.prevTopLine + 1, #sortedTable do
        local boss = sortedTable[i]
        local line = self.lines[lineNum]
        if not line then
            break
        end
        line:Show()
        line.name:SetText(" " .. (boss.name or ""))
        line.db = boss
        line.t:SetShown(backgroundLineStatus)

        for j = 1, self.VERTICALNAME_COUNT do
            local pname = namesList2[j] or "-"
            local db = module.db.responces[pname] or not IsInGroup() and module.db.responces[MRT.F.delUnitNameServer(pname)]

            if not db then
                SetIcon(line.icons[j], 0)
            elseif db then
                if db[CURRENT_INSTANCE] and
                    db[CURRENT_INSTANCE][CURRENT_DIFFICULTY] and
                    type(db[CURRENT_INSTANCE][CURRENT_DIFFICULTY]) == 'table' and
                    db[CURRENT_INSTANCE][CURRENT_DIFFICULTY][boss.name] ~= nil
                then
                    local isKilled = db[CURRENT_INSTANCE][CURRENT_DIFFICULTY][boss.name]
                    if isKilled then
                        SetIcon(line.icons[j], 2)
                    else
                        SetIcon(line.icons[j], 1)
                    end
                elseif db[CURRENT_INSTANCE] and
                    db[CURRENT_INSTANCE][CURRENT_DIFFICULTY] and
                    db[CURRENT_INSTANCE][CURRENT_DIFFICULTY] == 'NO_ID_INFO'
                then
                    SetIcon(line.icons[j], 1)
                else
                    SetIcon(line.icons[j], 0)
                end
            end
        end
        backgroundLineStatus = not backgroundLineStatus
        lineNum = lineNum + 1
    end
    for i = lineNum, #self.lines do
        self.lines[i]:Hide()
    end
end


function module:InitRaidLockoutsPopupFrame()
    module.frame = ELib:Template("ExRTDialogModernTemplate",UIParent)
    local frame = module.frame
    self = frame

    self.PAGE_HEIGHT, self.PAGE_WIDTH = 250, 750
    self.LINE_HEIGHT, self.LINE_NAME_WIDTH = 18, 190
	self.VERTICALNAME_WIDTH = 18
	self.VERTICALNAME_COUNT = 30
    self.isDynamic = true


    frame:SetSize(850,self.PAGE_HEIGHT+100)
    frame:SetPoint("CENTER",UIParent,"CENTER",0,0)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    frame:SetScript("OnDragStart", function(self)
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        VMRT.RaidLockouts.PopupLeft = self:GetLeft()
        VMRT.RaidLockouts.PopupTop = self:GetTop()
    end)
    frame:SetScript("OnMouseDown", function(self,button)
        if button == "RightButton" then
            self:Hide()
        end
    end)
    frame:Hide()
    frame.border = MRT.lib.CreateShadow(frame,20)

    if VMRT.RaidLockouts.PopupLeft and VMRT.RaidLockouts.PopupTop then
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VMRT.RaidLockouts.PopupLeft,VMRT.RaidLockouts.PopupTop)
	end


	self.mainScroll = ELib:ScrollFrame(frame):Size(self.PAGE_WIDTH, self.PAGE_HEIGHT):Point("BOTTOMLEFT", 0, 0):Height(self.PAGE_HEIGHT)
	ELib:Border(self.mainScroll, 0)

	ELib:DecorationLine(frame):Point("BOTTOM", self.mainScroll, "TOP", 0, 0):Point("LEFT", frame):Point("RIGHT",
    frame):Size(0, 1)
	ELib:DecorationLine(frame):Point("TOP", self.mainScroll, "BOTTOM", 0, 0):Point("LEFT", frame):Point("RIGHT",
    frame):Size(0, 1)

	self.prevTopLine = 0
	self.prevPlayerCol = 0

	self.mainScroll.ScrollBar:ClickRange(self.LINE_HEIGHT)
	self.mainScroll.ScrollBar.slider:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % frame.LINE_HEIGHT)
		self:UpdateButtons()
		local currTopLine = floor(value / frame.LINE_HEIGHT)
		if currTopLine ~= frame.prevTopLine then
			frame.prevTopLine = currTopLine
			frame:UpdatePage()
		end
	end)
    self.mainScroll.ScrollBar:Hide()
    do
        local width = self.mainScroll.C:GetWidth()
        self.mainScroll.C:SetWidth(width + 20)
    end


	self.raidSlider = ELib:Slider(frame, ""):Point("TOPLEFT", self.mainScroll, "BOTTOMLEFT", self.LINE_NAME_WIDTH + 15,-3):Range(0, 25):Size(self.VERTICALNAME_WIDTH * self.VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
		local currPlayerCol = floor(value)
		if currPlayerCol ~= frame.prevPlayerCol then
			frame.prevPlayerCol = currPlayerCol
			frame:UpdatePage()
		end
	end)
	self.raidSlider.Low:Hide()
	self.raidSlider.High:Hide()
	self.raidSlider.text:Hide()
	self.raidSlider.Low.Show = self.raidSlider.Low.Hide
	self.raidSlider.High.Show = self.raidSlider.High.Hide


	local lines = {}
	frame.lines = lines
	for i = 1, floor(self.PAGE_HEIGHT / self.LINE_HEIGHT) + 2 do
		local line = CreateFrame("Frame", nil, self.mainScroll.C)
		lines[i] = line
		line:SetPoint("TOPLEFT", 0, -(i - 1) * self.LINE_HEIGHT)
		line:SetPoint("TOPRIGHT", 0, -(i - 1) * self.LINE_HEIGHT)
		line:SetSize(0, self.LINE_HEIGHT)

		line.name = ELib:Text(line, "", 11):Point("LEFT", 2, 0):Size(self.LINE_NAME_WIDTH - self.LINE_HEIGHT / 2, self.LINE_HEIGHT):Color(1, 1, 1)--:Tooltip("ANCHOR_LEFT")

		line.icons = {}
		local iconSize = min(self.VERTICALNAME_WIDTH, self.LINE_HEIGHT) - 4
		for j = 1, self.VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil, "ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER", line, "LEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (j - 1) + self.VERTICALNAME_WIDTH / 2, 0)
			icon:SetSize(iconSize, iconSize)
			icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
			SetIcon(icon, (i + j) % 4)

			-- icon.hoverFrame = CreateFrame("Frame", nil, line)
			-- icon.hoverFrame:Hide()
			-- icon.hoverFrame:SetAllPoints(icon)
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

    local function LineOnClick(self,button)
        if button == "RightButton" then
            self:GetParent():Hide()
        end
    end

	self.raidNames = CreateFrame("Frame", nil, frame)
	for i = 1, self.VERTICALNAME_COUNT do
		self.raidNames[i] = ELib:Text(self.raidNames, "RaidName" .. i, 10):Point("BOTTOMLEFT", self.mainScroll, "TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0):Color(1, 1, 1)

		local f = CreateFrame("Button", nil, frame)
		f:SetPoint("BOTTOMLEFT", self.mainScroll, "TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0)
		f:SetSize(self.VERTICALNAME_WIDTH, 80)
		f:SetScript("OnEnter", RaidNames_OnEnter)
		f:SetScript("OnLeave", ELib.Tooltip.Hide)
		f:SetScript("OnClick", LineOnClick)
        f:RegisterForClicks("RightButtonDown")

        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", function(self)
            self:GetParent():StartMoving()
        end)
        f:SetScript("OnDragStop", function(self)
            self:GetParent():StopMovingOrSizing()
        end)

		f.t = self.raidNames[i]

		local t = self.mainScroll.C:CreateTexture(nil, "BACKGROUND")
		self.raidNames[i].t = t
		t:SetPoint("TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0)
		t:SetSize(self.VERTICALNAME_WIDTH, self.PAGE_HEIGHT)
		if i % 2 == 1 then
			t:SetColorTexture(.5, .5, 1, .05)
			t.Vis = true
		end
	end
	local group = self.raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local highlight_y = self.mainScroll.C:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_y:SetColorTexture(1, 1, 1, .2)
	local highlight_x = self.mainScroll.C:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_x:SetColorTexture(1, 1, 1, .2)

	local highlight_onupdate_maxY = (floor(self.PAGE_HEIGHT / self.LINE_HEIGHT) + 2) * self.LINE_HEIGHT
	local highlight_onupdate_minX = self.LINE_NAME_WIDTH + 15
	local highlight_onupdate_maxX = highlight_onupdate_minX + #self.raidNames * self.VERTICALNAME_WIDTH
	self.mainScroll.C:SetScript("OnUpdate", function(self)
		local x, y = MRT.F.GetCursorPos(frame.mainScroll)
		if y < 0 or y > frame.PAGE_HEIGHT then
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		local x, y = MRT.F.GetCursorPos(self)
		if y >= 0 and y <= highlight_onupdate_maxY then
			y = floor(y / frame.LINE_HEIGHT)
			highlight_y:ClearAllPoints()
			highlight_y:SetAllPoints(lines[y + 1])
			highlight_y:Show()
		else
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		if x >= highlight_onupdate_minX and x <= highlight_onupdate_maxX then
			x = floor((x - highlight_onupdate_minX) / frame.VERTICALNAME_WIDTH)
			highlight_x:ClearAllPoints()
			highlight_x:SetAllPoints(frame.raidNames[x + 1].t)
			highlight_x:Show()
		elseif x >= 0 and x <= (frame.PAGE_WIDTH - 16) then
			highlight_x:Hide()
		else
			highlight_x:Hide()
			highlight_y:Hide()
		end
	end)

	frame.UpdatePage = UpdatePage

    local function PopupFrame(self, event, ...)
        local _, instanceType, difficultyID, _, _, _, _, instanceID = GetInstanceInfo()

        if  not IsInRaid() or
            instanceType ~= "raid" or
            VMRT.RaidLockouts.DoNotShowOnMythic and difficultyID == 16
        then
            return
        end
        if type(difficultyID) == "number" and difficultyID > 12 and difficultyID < 17 then
            CURRENT_INSTANCE = instanceID
            CURRENT_DIFFICULTY = difficultyID
        end

		self:UpdatePage()
        self:Show()
        self:SetAlpha(1)
        if AddonDB:CheckSelfPermissions() then
            MRT.F.SendExMsg("RaidLockouts", "R\t" .. CURRENT_INSTANCE .. "\t" .. CURRENT_DIFFICULTY)
        end
        C_Timer.After(12, function()
            self:PrepToHide()
        end)
    end

    module.frame:SetScript("OnEvent",PopupFrame)

    module.frame.anim_frame = CreateFrame("Frame",nil,module.frame)
    module.frame.anim_frame:SetPoint("TOPLEFT")
    module.frame.anim_frame:SetSize(1,1)

    module.frame.anim = module.frame.anim_frame:CreateAnimationGroup()
    module.frame.timer = module.frame.anim:CreateAnimation()
    module.frame.timer:SetScript("OnFinished", function()
        module.frame.anim:Stop()
        module.frame:Hide()
    end)
    module.frame.timer:SetDuration(2)
    module.frame.timer:SetScript("OnUpdate", function(self,elapsed)
        module.frame:SetAlpha(1-self:GetProgress())
    end)
    module.frame:SetScript("OnHide", function(self)
        -- self:UnregisterAllEvents()
        if module.frame.anim:IsPlaying() then
            module.frame.anim:Stop()
        end
        if module.frame.hideTimer then
            module.frame.hideTimer:Cancel()
            module.frame.hideTimer = nil
        end
    end)

    function module.frame:PrepToHide()
        if (not module.frame:IsShown()) or (self.isManual) then
            return
        end

        local delay = 4
        module.frame.hideTimer = C_Timer.NewTimer(max(0.01,delay),function()
            module.frame.hideTimer = nil
            module.frame.anim:Play()
        end)
        -- module.frame.timeLeftLine:Stop()
    end
end
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
local function RaidLockoutsInit()
    local RaidLockouts = parentModule.options:NewPage("Raid Lockouts")
    local self = RaidLockouts
    module.RaidLockoutsUI = RaidLockouts

	self.helpicons = {}
	for i = 0, 1 do
		local icon = RaidLockouts:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", 2, -5 - i * 12)
		icon:SetSize(14, 14)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		SetIcon(icon, i + 1)
		local t = ELib:Text(RaidLockouts, "", 10):Point("LEFT", icon, "RIGHT", 2, 0):Size(0, 16):Color(1, 1, 1)
		if i == 0 then
			t:SetText(LR.BossNotKilled)
		elseif i == 1 then
			t:SetText(LR.BossKilled)
		end

		self.helpicons[i + 1] = { icon, t }
	end

    local ShowOnReadyCheck = ELib:Check(RaidLockouts, LR["Show On Ready Check"],VMRT.RaidLockouts.ShowOnReadyCheck):Point("TOPLEFT", self.helpicons[2][2], "BOTTOMLEFT", 0, -5):OnClick(function(self)
        VMRT.RaidLockouts.ShowOnReadyCheck = self:GetChecked()
        if VMRT.RaidLockouts.ShowOnReadyCheck then
            if not module.frame then module:InitRaidLockoutsPopupFrame() end
            module.frame:RegisterEvent("READY_CHECK") -- raid lockouts
        else
            module.frame:UnregisterEvent("READY_CHECK") -- raid lockouts
        end
    end)
    local DontShowOnMythic = ELib:Check(RaidLockouts, LR["Dont Show On Mythic"],VMRT.RaidLockouts.DoNotShowOnMythic):Point("TOPLEFT", ShowOnReadyCheck, "BOTTOMLEFT", 0, -5):OnClick(function(self)
        VMRT.RaidLockouts.DoNotShowOnMythic = self:GetChecked()
    end)


	self.PAGE_HEIGHT, self.PAGE_WIDTH = 280, 850
	self.LINE_HEIGHT, self.LINE_NAME_WIDTH = 20, 190
	self.VERTICALNAME_WIDTH = 20
	self.VERTICALNAME_COUNT = 31

    -- spacing between updated button and scroll frame is for raid slider
	self.mainScroll = ELib:ScrollFrame(RaidLockouts):Size(self.PAGE_WIDTH, self.PAGE_HEIGHT):Point("TOPLEFT", 0, -260):Height(700)
	ELib:Border(self.mainScroll, 0)

	ELib:DecorationLine(RaidLockouts):Point("BOTTOM", self.mainScroll, "TOP", 0, 0):Point("LEFT", self):Point("RIGHT",
		self):Size(0, 1)
	ELib:DecorationLine(RaidLockouts):Point("TOP", self.mainScroll, "BOTTOM", 0, 0):Point("LEFT", self):Point("RIGHT",
		self):Size(0, 1)

	self.prevTopLine = 0
	self.prevPlayerCol = 0

	self.mainScroll.ScrollBar:ClickRange(self.LINE_HEIGHT)
	self.mainScroll.ScrollBar.slider:SetScript("OnValueChanged", function(self, value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % RaidLockouts.LINE_HEIGHT)
		self:UpdateButtons()
		local currTopLine = floor(value / RaidLockouts.LINE_HEIGHT)
		if currTopLine ~= RaidLockouts.prevTopLine then
			RaidLockouts.prevTopLine = currTopLine
			RaidLockouts:UpdatePage()
		end
	end)

	self.raidSlider = ELib:Slider(RaidLockouts, ""):Point("TOPLEFT", self.mainScroll, "BOTTOMLEFT", self.LINE_NAME_WIDTH + 15,-3):Range(0, 25):Size(self.VERTICALNAME_WIDTH * self.VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
		local currPlayerCol = floor(value)
		if currPlayerCol ~= RaidLockouts.prevPlayerCol then
			RaidLockouts.prevPlayerCol = currPlayerCol
			RaidLockouts:UpdatePage()
		end
	end)
	self.raidSlider.Low:Hide()
	self.raidSlider.High:Hide()
	self.raidSlider.text:Hide()
	self.raidSlider.Low.Show = self.raidSlider.Low.Hide
	self.raidSlider.High.Show = self.raidSlider.High.Hide


	local lines = {}
	self.lines = lines
	for i = 1, floor(self.PAGE_HEIGHT / self.LINE_HEIGHT) + 2 do
		local line = CreateFrame("Frame", nil, self.mainScroll.C)
		lines[i] = line
		line:SetPoint("TOPLEFT", 0, -(i - 1) * self.LINE_HEIGHT)
		line:SetPoint("TOPRIGHT", 0, -(i - 1) * self.LINE_HEIGHT)
		line:SetSize(0, self.LINE_HEIGHT)

		line.name = ELib:Text(line, "", 11):Point("LEFT", 2, 0):Size(self.LINE_NAME_WIDTH - self.LINE_HEIGHT / 2, self.LINE_HEIGHT):Color(1, 1, 1):Tooltip("ANCHOR_LEFT", true)

		line.icons = {}
		local iconSize = min(self.VERTICALNAME_WIDTH, self.LINE_HEIGHT) - 4
		for j = 1, self.VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil, "ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER", line, "LEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (j - 1) + self.VERTICALNAME_WIDTH / 2, 0)
			icon:SetSize(iconSize, iconSize)
			icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
			SetIcon(icon, (i + j) % 4)

			-- icon.hoverFrame = CreateFrame("Frame", nil, line)
			-- icon.hoverFrame:Hide()
			-- icon.hoverFrame:SetAllPoints(icon)
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

	self.raidNames = CreateFrame("Frame", nil, RaidLockouts)
	for i = 1, self.VERTICALNAME_COUNT do
		self.raidNames[i] = ELib:Text(self.raidNames, "RaidName" .. i, 10):Point("BOTTOMLEFT", self.mainScroll, "TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0):Color(1, 1, 1)

		local f = CreateFrame("Frame", nil, RaidLockouts)
		f:SetPoint("BOTTOMLEFT", self.mainScroll, "TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0)
		f:SetSize(self.VERTICALNAME_WIDTH, 80)
		f:SetScript("OnEnter", RaidNames_OnEnter)
		f:SetScript("OnLeave", ELib.Tooltip.Hide)
		f.t = self.raidNames[i]

		local t = self.mainScroll:CreateTexture(nil, "BACKGROUND")
		self.raidNames[i].t = t
		t:SetPoint("TOPLEFT", self.LINE_NAME_WIDTH + 15 + self.VERTICALNAME_WIDTH * (i - 1), 0)
		t:SetSize(self.VERTICALNAME_WIDTH, self.PAGE_HEIGHT)
		if i % 2 == 1 then
			t:SetColorTexture(.5, .5, 1, .05)
			t.Vis = true
		end
	end
	local group = self.raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local highlight_y = self.mainScroll.C:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_y:SetColorTexture(1, 1, 1, .2)
	local highlight_x = self.mainScroll:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_x:SetColorTexture(1, 1, 1, .2)

	local highlight_onupdate_maxY = (floor(self.PAGE_HEIGHT / self.LINE_HEIGHT) + 2) * self.LINE_HEIGHT
	local highlight_onupdate_minX = self.LINE_NAME_WIDTH + 15
	local highlight_onupdate_maxX = highlight_onupdate_minX + #self.raidNames * self.VERTICALNAME_WIDTH
	self.mainScroll.C:SetScript("OnUpdate", function(self)
		local x, y = MRT.F.GetCursorPos(RaidLockouts.mainScroll)
		if y < 0 or y > RaidLockouts.PAGE_HEIGHT then
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		local x, y = MRT.F.GetCursorPos(self)
		if y >= 0 and y <= highlight_onupdate_maxY then
			y = floor(y / RaidLockouts.LINE_HEIGHT)
			highlight_y:ClearAllPoints()
			highlight_y:SetAllPoints(lines[y + 1])
			highlight_y:Show()
		else
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		if x >= highlight_onupdate_minX and x <= highlight_onupdate_maxX then
			x = floor((x - highlight_onupdate_minX) / RaidLockouts.VERTICALNAME_WIDTH)
			highlight_x:ClearAllPoints()
			highlight_x:SetAllPoints(RaidLockouts.raidNames[x + 1].t)
			highlight_x:Show()
		elseif x >= 0 and x <= (RaidLockouts.PAGE_WIDTH - 16) then
			highlight_x:Hide()
		else
			highlight_x:Hide()
			highlight_y:Hide()
		end
	end)

	self.UpdateButton = MLib:Button(RaidLockouts, UPDATE):Point("TOPLEFT", self.mainScroll, "BOTTOMLEFT", 2, -25):Size(130, 20):OnClick(function(self)
		MRT.F.SendExMsg("RaidLockouts", "R\t" .. CURRENT_INSTANCE .. "\t" .. CURRENT_DIFFICULTY)

		C_Timer.After(2, function() RaidLockouts:UpdatePage() end)
		self:Disable()
	end)

    ---@return boolean? false if difficulty is valid for current instance, true if update for widget is needed
    local function IsDiffUpdateNeeded()
        EJ_SelectInstance(AddonDB.EJ_DATA.instanceIDtoEJ[CURRENT_INSTANCE])
        local isValid = EJ_IsValidInstanceDifficulty(CURRENT_DIFFICULTY)
        if isValid then
            return false
        else
            for diff_id=1,220 do
                if EJ_IsValidInstanceDifficulty(diff_id) then
                   CURRENT_DIFFICULTY = diff_id
                   return true
                end
            end
        end
    end


	self.InstanceDropDown = ELib:DropDown(RaidLockouts, 230, -1):Point("TOPLEFT", self.UpdateButton, "TOPRIGHT", 5, 0):Size(230, 20):SetText("Instance"):Tooltip("Select instance to update")
	do
		self.InstanceDropDown:SetText(GetRealZoneText(CURRENT_INSTANCE))
		local function InstanceDropDown_SetValue(_, arg)
			CURRENT_INSTANCE = arg
			ELib:DropDownClose()
            self.InstanceDropDown:SetText(GetRealZoneText(CURRENT_INSTANCE))
            if IsDiffUpdateNeeded() then
                self.DifficultyDropDown:SetText(MRT.A.Reminder.datas.instance_difficulty_types[CURRENT_DIFFICULTY])
            end
            RaidLockouts:UpdatePage()
		end
		local List = self.InstanceDropDown.List

        if EJ_GetInstanceInfo then
			for i=1,5 do
				local line = AddonDB.EJ_DATA.journalInstances[i]
                if not line then break end
				local subMenu = {}
				for j=2,#line do
					if line[j] == 0 then
                        subMenu[#subMenu+1] = {
                            text = " ",
                            isTitle = true,
                        }
					else
						local name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, mapID = EJ_GetInstanceInfo(line[j])
						if mapID then
							subMenu[#subMenu+1] = {
								text = name,
								arg1 = mapID,
								func = InstanceDropDown_SetValue,
							}
						end
					end
				end
				tinsert(List, {text = EJ_GetTierInfo(line[1]),subMenu = subMenu})
			end
		end
	end


	self.DifficultyDropDown = ELib:DropDown(RaidLockouts, 200, -1):Point("TOPLEFT", self.InstanceDropDown, "TOPRIGHT", 5,0):Size(200, 20):SetText("Difficulty"):Tooltip("Select difficulty to update")
	do
		self.DifficultyDropDown:SetText(MRT.A.Reminder.datas.instance_difficulty_types[CURRENT_DIFFICULTY])
		local function DifficultyDropDown_SetValue(_, arg)
			CURRENT_DIFFICULTY = arg
			ELib:DropDownClose()
			self.DifficultyDropDown:SetText(MRT.A.Reminder.datas.instance_difficulty_types[CURRENT_DIFFICULTY])
			RaidLockouts:UpdatePage()
		end
        function self.DifficultyDropDown:PreUpdate()
            local List = self.List
            wipe(List)
            EJ_SelectInstance(AddonDB.EJ_DATA.instanceIDtoEJ[CURRENT_INSTANCE])
            for diff_id=1,200 do
                if EJ_IsValidInstanceDifficulty(diff_id) then
                    List[#List + 1] = {
                        text = MRT.A.Reminder.datas.instance_difficulty_types[diff_id],
                        arg1 = diff_id,
                        func = DifficultyDropDown_SetValue,
                    }
                end
            end
        end
	end

	self.UpdatePage = UpdatePage

    self:SetScript("OnShow",function (self)
        self:UpdatePage()
    end)
end

tinsert(parentModule.options.ModulesToLoad,RaidLockoutsInit)

function module.main.ADDON_LOADED()
    VMRT = _G.VMRT
    VMRT.RaidLockouts = VMRT.RaidLockouts or {}
    VMRT.RaidLockouts.DoNotShowOnMythic =  (VMRT.RaidLockouts.DoNotShowOnMythic == nil and true) or VMRT.RaidLockouts.DoNotShowOnMythic

    if VMRT.RaidLockouts.ShowOnReadyCheck then
        module:InitRaidLockoutsPopupFrame()
        module.frame:RegisterEvent("READY_CHECK") -- raid lockouts
    end

    module:RegisterAddonMessage()
end

local lastRequested = {} -- {{instanceID,diffID}}
function module.main:UPDATE_INSTANCE_INFO()
    for _, last in next, lastRequested do
        local lastInstance = last[1]
        local lastDiff = last[2]
        local LockoutInfo = ""
        local bossInfo = {}
        local numSavedInstances = GetNumSavedInstances()
        for i = 1, numSavedInstances do
            local name, lockoutID, reset, difficultyID, locked, extended, instanceIDMostSig, isRaid,
            maxPlayers, difficultyName, numEncounters, encounterProgress, extendDisabled, instanceID = GetSavedInstanceInfo(i)
            if instanceID == lastInstance and difficultyID == lastDiff then
                if not module.db.encountersOrder[instanceID] then
                    local journalInstanceID = AddonDB.EJ_DATA.instanceIDtoEJ[instanceID]

                    if not journalInstanceID then
                        break
                    end

                    module.db.encountersOrder[instanceID] = {}

                    EJ_SelectInstance(journalInstanceID)
                    for j = 1, numEncounters do
                        local bossName = EJ_GetEncounterInfoByIndex(j, journalInstanceID)
                        if bossName then
                            module.db.encountersOrder[instanceID][bossName] = j
                        end
                    end
                end

                for j = 1, numEncounters do
                    local bossName, fileDataID, isKilled = GetSavedInstanceEncounterInfo(i, j)
                    local customOrder = module.db.encountersOrder[instanceID][bossName]
                    if customOrder then
                        bossInfo[customOrder] = isKilled and locked and "1" or "0"
                    elseif not bossInfo[j] then
                        bossInfo[j] = isKilled and locked and "1" or "0"
                    end
                end
                LockoutInfo = table.concat(bossInfo)
                break
            end
        end
        if LockoutInfo == "" then
            LockoutInfo = lastInstance .. "^" .. lastDiff .. "^" .. "NO_ID_INFO"
        else
            LockoutInfo = lastInstance .. "^" .. lastDiff .. "^" .. LockoutInfo
        end
        MRT.F.SendExMsg("RaidLockouts", "S\t" .. LockoutInfo)
    end
    wipe(lastRequested)
    module:UnregisterEvents("UPDATE_INSTANCE_INFO")
end

-- /dump GMRT.A.NoteAnalyzer:CreateLockoutInfo(2549,15)
function module:CreateLockoutInfo(RequestedInstanceID, RequestedDifficultyID)
    tinsert(lastRequested, {RequestedInstanceID, RequestedDifficultyID})

    module:RegisterEvents("UPDATE_INSTANCE_INFO")
    RequestRaidInfo() -- request updated data
end

function module:ParseLockoutInfo(string)
    if MRT.isClassic and not MRT.isCata then return end
	local instanceID, difficultyID, bosses = string:match("^(%d+)%^(%d+)%^(.+)$")

	if not instanceID then
		return
	end

	instanceID = tonumber(instanceID)
	difficultyID = tonumber(difficultyID)

	local journalInstanceID = AddonDB.EJ_DATA.instanceIDtoEJ[instanceID]

	if not journalInstanceID then
		return
	end

	EJ_SelectInstance(journalInstanceID)

	if bosses == "NO_ID_INFO" then
		return instanceID, difficultyID, "NO_ID_INFO"
	end
	local numEncounters = #bosses
	local bossKills = {}

    for i = 1, numEncounters do
        local name = EJ_GetEncounterInfoByIndex(i, journalInstanceID) -- may return enexpected nil
        if name then
            bossKills[name] = bosses:sub(i, i) == "1"
        end
    end

	return instanceID, difficultyID, bossKills
end

function module:addonMessage(sender, prefix, prefix2, ...)
    if prefix == "RaidLockouts" then
		if prefix2 == "R" then -- request
			local instanceID, difficultyID = ...
            module:CreateLockoutInfo(tonumber(instanceID), tonumber(difficultyID))
		elseif prefix2 == "S" then -- send
			local lockoutInfo = ...
			local instanceID, difficultyID, bossKills = module:ParseLockoutInfo(lockoutInfo)
			if instanceID then
				module.db.responces[sender] = module.db.responces[sender] or {}
				module.db.responces[sender][instanceID] = module.db.responces[sender][instanceID] or {}
				module.db.responces[sender][instanceID][difficultyID] = bossKills
			end
			if module.RaidLockoutsUI and module.RaidLockoutsUI:IsVisible() and module.RaidLockoutsUI.UpdatePage then
                if not module.RaidLockoutsUI.updTimer then
                    module.RaidLockoutsUI.updTimer = C_Timer.NewTimer(0.2, function()
                        module.RaidLockoutsUI.updTimer = nil
                        module.RaidLockoutsUI:UpdatePage()
                    end)
                end
			end
            if module.frame and module.frame:IsVisible() and module.frame.UpdatePage then
                if not module.frame.updTimer then
                    module.frame.updTimer = C_Timer.NewTimer(0.2, function()
                        module.frame.updTimer = nil
                        module.frame:UpdatePage()
                    end)
                end
            end
		end
    end
end

