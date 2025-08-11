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

function options:InitializeHelpTab()
	local helpScroll = ELib:ScrollFrame(options.HELP_TAB):Size(756,589):Point("TOPLEFT",0,0)
	local helpText = ELib:Text(helpScroll.C, LR.HelpText):Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5):Color()

	helpScroll:Height(helpText:GetStringHeight()+100)
	helpScroll.C:SetWidth(695 - 16)
	ELib:Border(helpScroll,0)
end
