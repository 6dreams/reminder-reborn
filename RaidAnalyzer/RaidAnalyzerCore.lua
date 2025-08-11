local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ELib
local ELib, L = MRT.lib, MRT.L
---@class MLib
local MLib = AddonDB.MLib

---@class RaidAnalyzer: MRTmodule
local module = AddonDB:New("RaidAnalyzer", "|cff80ff00Raid Analyzer|r")
if not module then return end


module.options.ModulesToLoad = {}
module.addonMessages = {}
module.PUBLIC = AddonDB.PUBLIC

function module.options:Load()
	self:CreateTilte()
	MLib:CreateModuleHeader(self)

	local decorationLine = ELib:DecorationLine(self, true, "BACKGROUND", -5):Point("TOPLEFT", self, 0, -25):Point("BOTTOMRIGHT", self, "TOPRIGHT", 0, -45)
	decorationLine:SetGradient("VERTICAL", CreateColor(0.17, 0.17, 0.17, 0.77), CreateColor(0.17, 0.17, 0.17, 0.77))

	self.tab = MLib:Tabs(self, 0, "", "", "","","","",""):Point(0, -45):Size(698, 570):SetTo(1)

	function self:NewPage(...)
		local tab = module.options.tab.SetupTab(...)
		return tab
	end

	for _,submod in ipairs(module.options.ModulesToLoad) do
		submod(module.options)
	end

	self.isWide = true
end
