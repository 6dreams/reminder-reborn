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

-- Upvalue declarations
local GetTime, format, tremove, ipairs, next = GetTime, format, tremove, ipairs, next


local frame = CreateFrame('Frame',nil,UIParent)
module.frame = frame
frame:SetSize(30,30)
frame:SetPoint("CENTER",UIParent,"TOP",0,-100)
frame:EnableMouse(false)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
	if self:IsMovable() then
		self:StartMoving()
	end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	local offsetLeft, offsetBottom = self:GetCenter()
	VMRT.Reminder.VisualSettings.Text_PosX = offsetLeft - (GetScreenWidth() / 2)
	VMRT.Reminder.VisualSettings.Text_PosY = offsetBottom - (GetScreenHeight() / 2)
	self:ClearAllPoints()
	self:SetPoint("CENTER",UIParent,"CENTER",VMRT.Reminder.VisualSettings.Text_PosX,VMRT.Reminder.VisualSettings.Text_PosY)
end)

frame.dot = frame:CreateTexture(nil, "BACKGROUND",nil,-6)
frame.dot:SetTexture("Interface\\AddOns\\MRT\\media\\circle256")
frame.dot:SetAllPoints()
frame.dot:SetVertexColor(1,0,0,1)

frame:Hide()
frame.dot:Hide()


frame.textBigD = {}
frame.textD = {}
frame.textSmallD = {}

frame.textBig = {}
frame.text = {}
frame.textSmall = {}
function frame:CreateText(t,i,textSizeScale)
	local text = t[i]
	if text then
		return text
	end

	text = self:CreateFontString(nil,"ARTWORK")
	t[i] = text

	text.tss = textSizeScale -- 1 big -- 2 normal -- 3 small

	text.tmr = self:CreateFontString(nil,"ARTWORK")

	self:UpdateTextStyle(text)

	return text
end

function frame:UpdateTextStyle(obj)
	if not VMRT then
		return
	end
	local font = VMRT.Reminder.VisualSettings.Text_Font or MRT.F.defFont
	local outline = VMRT.Reminder.VisualSettings.Text_FontOutlineType or "OUTLINE, OUTLINE"
	local fontSizeBig = VMRT.Reminder.VisualSettings.Text_FontSizeBig or 60
	local fontSize = VMRT.Reminder.VisualSettings.Text_FontSize or 40
	local fontSizeSmall = VMRT.Reminder.VisualSettings.Text_FontSizeSmall or 20
	local hasShadow = VMRT.Reminder.VisualSettings.Text_FontShadow
	local frameStata = VMRT.Reminder.FrameState or "HIGH"
	frame:SetFrameStrata(frameStata)

	local ahText = (VMRT.Reminder.JustifyH == 1 and "LEFT") or (VMRT.Reminder.JustifyH == 2 and "RIGHT") or ""
	local avTextT,avTextB = "TOP","BOTTOM"
	if VMRT.Reminder.GrowUp then -- TODO
		avTextT,avTextB = avTextB,avTextT
	end
	local te = VMRT.Reminder.VisualSettings.Text_FontTimerExcluded

	local rpf = avTextT..ahText
	local rpt = avTextB..ahText

	for o,t in next, (obj and {{obj}} or {self.textBigD,self.textD,self.textSmallD}) do
		for ci,text in next, t do
			local fSize = text.tss == 1 and fontSizeBig or text.tss == 2 and fontSize or fontSizeSmall
			if not text:SetFont(font, fSize, outline) then
				text:SetFont(MRT.F.defFont, fSize, outline)
			end
			if not text.tmr:SetFont(font, fSize, outline) then
				text.tmr:SetFont(MRT.F.defFont, fSize, outline)
			end
			if hasShadow then
				text:SetShadowOffset(1,-1)
				text.tmr:SetShadowOffset(1,-1)
			else
				text:SetShadowOffset(0,0)
				text.tmr:SetShadowOffset(0,0)
			end
			text.tmr:SetPoint("LEFT",text,"RIGHT",0,0) --floor(fSize / 10 + 0.5)

			text.te = te

			text.rpf = rpf
			text.rpt = rpt

			text.point = nil
		end
	end
end

do
	local pd = {"textBig","text","textSmall"}
	local p = {"textBigD","textD","textSmallD"}
	function frame:Update()
		local lastT
		for j,t in ipairs(pd) do
			local fp = self[t]
			local f = self[ p[j] ]
			local c = 0
			for i=#fp,1,-2 do
				c = c + 1
				local text = f[c]
				if not text then
					text = self:CreateText(f,c,j)
				end

				if text.te then
					text:SetText((fp[i-1] or "")..(fp[i] or ""))
					text.tmr:SetText("")
				else
					text:SetText(fp[i-1])
					text.tmr:SetText((fp[i] or "").." ")
				end

				if text.point ~= (lastT or self) then
					text:ClearAllPoints()
					if lastT then
						text:SetPoint(text.rpf or "TOP",lastT,text.rpt or "BOTTOM",0,0)
						text.point = lastT
					else
						text:SetPoint(text.rpf or "TOP",self,"CENTER",0,0)
						text.point = self
					end
				end

				lastT = text
			end
			for i=c+1,#f do
				local text = f[i]

				text:SetText("")
				text.tmr:SetText("")
			end
		end
	end
end


do
	-- local countdownTypes = module.datas.countdownType
	local tmr = 0
	local sReminders = module.db.showedReminders
	frame:SetScript("OnUpdate",function(self,elapsed)
		tmr = tmr + elapsed
		if tmr > 0.03 then
			tmr = 0

			if frame.unlocked then	--test mode active
				return
			end

			for k in next, self.textBig do self.textBig[k]=nil end
			for k in next, self.text do self.text[k]=nil end
			for k in next, self.textSmall do self.textSmall[k]=nil end
			local total_c = 0
			local now = GetTime()
			for j=#sReminders,1,-1 do
				local showed = sReminders[j]
				local data,t,params = showed.data, showed.expirationTime, showed.params
				if now <= t then
					local msg, updateReq = showed.msg
					if not msg then
						msg, updateReq = module:FormatMsg(data.msg or "",params)
						if not updateReq or data.dynamicdisable then
							showed.msg = msg
						end
					end
					local countdownFormat = showed.countdownFormat
					if not countdownFormat then
						countdownFormat = module.datas.countdownType[data.countdownType or 2][3]
						showed.countdownFormat = countdownFormat
					end
					local table
					if data.msgSize == 2 then
						table = self.textBig
					elseif data.msgSize == 1 then
						table = self.textSmall
					else
						table = self.text
					end
					table[#table+1] = msg or ""
					table[#table+1] = showed.dur ~= 0 and data.countdown and format(countdownFormat,t - now) or ""
					total_c = total_c + 1
				else
					tremove(sReminders,j)
				end
			end

			self:Update()
			if total_c == 0 then
				self:Hide()
			end
		end
	end)
end

ELib:FixPreloadFont(frame,function()
	if VMRT then
		module:UpdateVisual(true)
		return true
	end
end)
