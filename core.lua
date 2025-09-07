--[[
project-revision 			1199
project-hash 				51feaef517f9f8ae768758102eb3569ae5c5035c
project-abbreviated-hash 	51feaef
project-author 				m33shoq
project-date-iso 			2025-08-31T22:38:35Z
project-date-integer 		20250831223835
project-timestamp 			1756679915
project-version 			v66.5
]]

local GlobalAddonName = ...

---@class AddonDB
local AddonDB = select(2, ...)

local MRT = GMRT

---@type ELib
local ELib = MRT.lib

-----------------------------------------------------------
-- Upvalues
-----------------------------------------------------------
local format = format
local next = next
local random = random
local tInsertUnique = tInsertUnique
local tonumber = tonumber
local xpcall = xpcall


local function noop() end
RGLOG = noop
rglog = noop
RGlog = noop
rgLog = noop
if not ddt then ddt = noop end
if not DDT then DDT = noop end
if not ddtD then ddtD = noop end
if not DDTD then DDTD = noop end

-----------------------------------------------------------
-- MRT modules wrapper
-----------------------------------------------------------

local AddonModules = {}

---@param moduleName string
---@param localizedName string?
---@param disableOptions boolean?
---@return MRTmodule|false
function AddonDB:New(moduleName, localizedName, disableOptions)
	local module = MRT:New(moduleName, localizedName, disableOptions)
	if module then
		AddonModules[module] = true
	end
	return module
end

if MRT.A.WAChecker then
	AddonModules[MRT.A.WAChecker] = true -- workaround for ADDON_LOADED in WASync
end

local MRTdev = CreateFrame("Frame")
MRTdev:RegisterEvent("ADDON_LOADED")
MRTdev:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName ~= GlobalAddonName then
			return
		end

		for module in next, AddonModules do
			if not module.IsLoaded then
				module.main:ADDON_LOADED()
				module.IsLoaded = true

				--for old versions
				if MRT.ModulesLoaded then
					for i = #MRT.Modules, 1, -1 do
						if MRT.Modules[i] == module then
							MRT.ModulesLoaded[i] = true
							break
						end
					end
				end
			end
		end
		self:UnregisterEvent("ADDON_LOADED")
	end
end)

-----------------------------------------------------------
-- Rename and switch modules order
-----------------------------------------------------------

function AddonDB:RenameModule(module, newName)
	if not module or not newName then
		return
	end

	local localizedName = module.options.name
	module.options.name = newName

	for i, lName in next, MRT.Options.Frame.modulesList.L do
		if lName == localizedName then
			MRT.Options.Frame.modulesList.L[i] = newName
		end
	end
end

function AddonDB:SwitchModulesOrder(module1, module2)
	if not module1 or not module2 then
		return
	end
	-- Minimap icon order
	local index1 = nil
	local index2 = nil

	for i, opts in next, MRT.ModulesOptions do
		if opts == module1.options then
			index1 = i
		elseif opts == module2.options then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.ModulesOptions[index1], MRT.ModulesOptions[index2] = MRT.ModulesOptions[index2], MRT.ModulesOptions[index1]
	end

	-- Change order of frames in Options
	index1 = nil
	index2 = nil
	for i, opts in next, MRT.Options.Frame.Frames do
		if opts == module1.options then
			index1 = i
		elseif opts == module2.options then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.Options.Frame.Frames[index1], MRT.Options.Frame.Frames[index2] = MRT.Options.Frame.Frames[index2], MRT.Options.Frame.Frames[index1]
	end

	-- Change order of frames in Options.modulesList.L
	index1 = nil
	index2 = nil
	for i, localizedName in next, MRT.Options.Frame.modulesList.L do
		if localizedName == module1.options.name then
			index1 = i
		elseif localizedName == module2.options.name then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.Options.Frame.modulesList.L[index1], MRT.Options.Frame.modulesList.L[index2] = MRT.Options.Frame.modulesList.L[index2], MRT.Options.Frame.modulesList.L[index1]
	end

	-- Change order of modules in MRT.Modules and MRT.ModulesLoaded
	index1 = nil
	index2 = nil
	for i, module in next, MRT.Modules do
		if module == module1 then
			index1 = i
		elseif module == module2 then
			index2 = i
		end
	end

	if index1 and index2 then
		MRT.Modules[index1], MRT.Modules[index2] = MRT.Modules[index2], MRT.Modules[index1]
		MRT.ModulesLoaded[index1], MRT.ModulesLoaded[index2] = MRT.ModulesLoaded[index2], MRT.ModulesLoaded[index1]
	end
end

-----------------------------------------------------------
-- Callbacks
-----------------------------------------------------------

do
	local callbacks = {}

	function AddonDB:RegisterCallback(name, func)
		if type(func) ~= "function" then
			error(GlobalAddonName..": RegisterCallback: func is not a function", 2)
		end
		if not callbacks[name] then
			callbacks[name] = {}
		end
		tInsertUnique(callbacks[name], func)
	end

	function AddonDB:UnregisterCallback(name, func)
		if not callbacks[name] then
			return
		end
		for i = #callbacks[name], 1, -1 do
			if callbacks[name][i] == func then
				tremove(callbacks[name], i)
				break
			end
		end
	end

	function AddonDB:FireCallback(name, ...)
		if not callbacks[name] then
			return
		end
		for i, func in ipairs(callbacks[name]) do
			if func then
				xpcall(func, geterrorhandler(), ...)
			end
		end
	end
end

-----------------------------------------------------------
-- Global proxy
-----------------------------------------------------------

local privateFields = {
	RGAPI = true,
	Archivist = true,
	WASYNC = true,
}

_G.GREMINDER = setmetatable({}, {
	__index = function(t, k)
		if privateFields[k] then
			return nil
		end
		return AddonDB[k]
	end,
	__newindex = function() end,
	__metatable = false
})

-----------------------------------------------------------
-- Constants
-----------------------------------------------------------

AddonDB.defaultFont = GameFontNormal:GetFont()

AddonDB.VersionHash = "51feaef"
if AddonDB.VersionHash:find("@") then
	AddonDB.VersionHash = "DEV"
	AddonDB.IsDev = true
end

AddonDB.PUBLIC = C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-Release") == "Public"
AddonDB.Version = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "Version") or "0")
AddonDB.VersionString = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ") |cff0080ffDiscord for feedback and bug reports: mishoq|r"
AddonDB.VersionStringShort = "v"..AddonDB.Version .. "-" .. (AddonDB.PUBLIC and "public" or "private")..  "(".. AddonDB.VersionHash .. ")"
-- This one is used for the version check in public releases
AddonDB.VersionMajor = tonumber(C_AddOns.GetAddOnMetadata(GlobalAddonName, "X-VersionMajor") or "0")

AddonDB.externalLinks = {
	{
		name = "Discord",
		tooltip = "Download updates, provide feedback,\nreport bugs and request features",
		url = "https://discord.gg/dmqVFvU4qv",
	},
}

AddonDB.MY_REALM = GetRealmName():gsub("[%s%-]","")

-----------------------------------------------------------
-- Useful string matching patterns
-----------------------------------------------------------

AddonDB.STRING_PATTERNS = {}
AddonDB.STRING_PATTERNS.SEP = " ,\n\r:%{%}%(%)%+%[%]\"%@%!%$%_%#%&"
AddonDB.STRING_PATTERNS.PAT_SEP = "[" .. AddonDB.STRING_PATTERNS.SEP .. "]"
AddonDB.STRING_PATTERNS.PAT_SEP_INVERSE = "[^" .. AddonDB.STRING_PATTERNS.SEP .. "]+"
AddonDB.STRING_PATTERNS.PAT_SEP_CAPTURE = "(" .. AddonDB.STRING_PATTERNS.PAT_SEP .. ")"

-----------------------------------------------------------
-- Slash commands
-----------------------------------------------------------

SLASH_ReminderSlash1 = "/rem"
SLASH_ReminderSlash2 = "/reminder"
SLASH_ReminderSlash3 = "/куь" -- /rem but in russian

SlashCmdList["ReminderSlash"] = function(msg)
	MRT.Options:Open()
	MRT.Options:OpenByModuleName("Reminder")
end

SLASH_WASYNC1 = "/was"
SLASH_WASYNC2 = "/wasync"
SLASH_WASYNC3 = "/цфы" -- /was but in russian

SlashCmdList["WASYNC"] = function(msg)
	MRT.Options:Open()
	MRT.Options:OpenByModuleName("WAChecker")
end

-----------------------------------------------------------
-- Private images API
-----------------------------------------------------------

local rg_logo = "Interface\\Addons\\" .. GlobalAddonName .. "\\Media\\Textures\\rg_logo_white.png"
local path = "Interface\\Addons\\" .. GlobalAddonName .. "\\Media\\Private\\Textures\\%s"
local privateImages = {
	format(path, "badito.png"),
	format(path, "badito2.png"),
	format(path, "badito3.png"),
	format(path, "badito4.png"),
	format(path, "badito5.png"),
	format(path, "badito6.png"),
	format(path, "badito7.png"),
	format(path, "badito8.png"),
	format(path, "badito9.png"),
	format(path, "badito11.png"),
	format(path, "badito12.png"),
	format(path, "badito13.png"),
	format(path, "Spiderdito.png"),
	format(path, "Nercho_pes.png"),
	format(path, "Azargul_kot.png"),
	format(path, "Selfless.png"),
	format(path, "Zmei_mario.png"),
	format(path, "zmey2.png"),
	format(path, "zmey3.png"),
	format(path, "darkless.png"),
	format(path, "mishok.png"),
	format(path, "nimb_mishoq.png"),
	format(path, "UAZb.png"),
	format(path, "Jeniss_Korgy.png"),
	format(path, "feyta.png"),
	format(path, "feyta2.png"),
	format(path, "badito14.png"),
	format(path, "kroyfell.png"),
	format(path, "murchal.png"),
	format(path, "pauel.png"),
	format(path, "anti_kit.png"),
}
AddonDB.TotalImages = #privateImages

function AddonDB:GetImage(num, depth)
	depth = (depth or 0) + 1

	local allBlacklisted = false
	if depth == 1 and RGDB and RGDB.ImagesBlacklist then
		allBlacklisted = true
		for _, image in ipairs(privateImages) do
			if not RGDB.ImagesBlacklist[image] then
				allBlacklisted = false
				break
			end
		end
	end

	if AddonDB.PUBLIC or allBlacklisted or depth > 500 then
		return rg_logo
	elseif num then
		local image = privateImages[num]
		if not image or RGDB and RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[image] then
			return AddonDB:GetImage(nil, depth)
		end
		return image
	else
		local image = privateImages[random(1, #privateImages)]
		if not image or RGDB and RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[image] then
			return AddonDB:GetImage(nil, depth)
		end
		return image
	end
end

if not AddonDB.PUBLIC then
	local imgFrame
	SLASH_RGIMAGES1 = "/rgimg"
	SlashCmdList["RGIMAGES"] = function(msg)
		if not imgFrame then
			imgFrame = ELib:Popup("RG Images"):Size(220,50)
			imgFrame.DropDown = ELib:DropDown(imgFrame, 200, 10):Size(200):Point("BOTTOM", imgFrame, "BOTTOM", 0, 5):SetText("Settings")
			local function SetValue(self, img)
				RGDB.ImagesBlacklist = RGDB.ImagesBlacklist or {}
				RGDB.ImagesBlacklist[img] = not RGDB.ImagesBlacklist[img] or nil
				imgFrame.DropDown.List[self.id].colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00"
				ELib.ScrollDropDown:Reload()
			end
			local function hoverFunc(self)
				GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 15, 0)
				GameTooltip:SetText(format("|T%s:200:200|t", self.data.arg1))
				GameTooltip:Show()
			end
			function imgFrame.DropDown:PreUpdate()
				for i, img in ipairs(privateImages) do
					if not self.List[i] then
						self.List[i] = {
							text = i,
							arg1 = img,
							func = SetValue,
							colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00",
							hoverFunc = hoverFunc,
						}
					else
						self.List[i].colorCode = RGDB.ImagesBlacklist and RGDB.ImagesBlacklist[img] and "|cffff0000" or "|cff00ff00"
					end
				end
			end
		end
		imgFrame:Show()
	end
end


-----------------------------------------------------------
-- Loading events handler
-----------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(self, event, ...)
	if event == "ADDON_LOADED" then
		local addonName = ...
		if addonName == GlobalAddonName then
			self:UnregisterEvent("ADDON_LOADED")

			ReminderArchive = ReminderArchive or {}
			WASyncArchiveDB = WASyncArchiveDB or {}

			AddonDB:FireCallback("EXRT_REMINDER_ADDON_LOADED")
			C_Timer.After(1, function()
				AddonDB:FireCallback("EXRT_REMINDER_POST_ADDON_LOADED")
			end)
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		local isInitialLogin, isReloadingUi = ...
		if isInitialLogin or isReloadingUi then
			AddonDB:FireCallback("EXRT_REMINDER_PLAYER_ENTERING_WORLD")
		end
	end
end)
