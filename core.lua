-- ADDON LOADED fix

local MRT = GMRT
local GlobalAddonName,DATA_TABLE = ...

setmetatable(DATA_TABLE, {__index=function (t, k)
	return MRT[k]
end})

local MRTdev = CreateFrame("Frame")
MRTdev:SetScript("OnEvent",function (self, event, addonName)
	if addonName == GlobalAddonName then
		for i=1,#MRT.Modules do
			if not MRT.ModulesLoaded[i] then
				MRT.Modules[i].main:ADDON_LOADED()
				MRT.ModulesLoaded[i] = true
			end
		end
	
		self:UnregisterEvent("ADDON_LOADED")		
	end
end)
MRTdev:RegisterEvent("ADDON_LOADED") 