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

function options:InitializeChangelogTab()
	local changelog = AddonDB.Changelog

	local text = {{}}
	local c = 1
	local lennow = 0
	for line in changelog:gmatch("[^\n]+\n*") do
		lennow = lennow + #line
		if lennow > 8192 then
			c = c + 1
			text[c] = {}
			lennow = 0
		end
		text[c][#text[c] + 1] = line
	end

	local changelogScroll = ELib:ScrollFrame(options.CHANGELOG_TAB):Size(756, 589):Point("TOPLEFT", 0, 0):OnShow(function(self)
		local height = 0
		for i = 1, #self.texts do
			height = height + self.texts[i]:GetStringHeight() + 6
		end

		self:Height(height)
	end, true)

	changelogScroll.texts = {}
	local totalHeight = 0
	for i = 1, #text do
		-- print(i, table.concat(text[i]))
		changelogScroll.texts[i] = ELib:Text(changelogScroll.C, table.concat(text[i])):Color()
		totalHeight = totalHeight + changelogScroll.texts[i]:GetStringHeight() + 5
		if i == 1 then
			changelogScroll.texts[i]:Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5)
		else
			changelogScroll.texts[i]:Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",changelogScroll.texts[i-1], "BOTTOM", 0, -5)
		end
	end

	changelogScroll:Height(totalHeight)
	changelogScroll.C:SetWidth(695 - 16)
	ELib:Border(changelogScroll, 0)
end
