-- ADDON LOADED fix

local ExRT = GExRT
local GlobalAddonName,DATA_TABLE = ...

setmetatable(DATA_TABLE, {__index=function (t, k)
	return ExRT[k]
end})

local ExRTdev = CreateFrame("Frame")
ExRTdev:SetScript("OnEvent",function (self, event, addonName)
	if addonName == GlobalAddonName then
		for i=1,#ExRT.Modules do
			if not ExRT.ModulesLoaded[i] then
				ExRT.Modules[i].main:ADDON_LOADED()
				ExRT.ModulesLoaded[i] = true
			end
		end
	
		self:UnregisterEvent("ADDON_LOADED")		
	end
end)
ExRTdev:RegisterEvent("ADDON_LOADED") 