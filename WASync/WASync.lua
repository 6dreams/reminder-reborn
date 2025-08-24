--[[

Guide was written December 26th, 2023 and some info may be outdated(Last update August 2nd, 2025)
Explanation on WeakAuras Sync and WAChecker

A dictrionary of terms used in this file:
* WeakAuras - the addon
* WA - a singular entity that exists in WeakAuras, may include children

WeakAuras Sync is an expansion for WAChecker module.
It allows you to send WAs to other players directly, without using chat links.
It also allows you to track state of WAs of other players, including info about:
	- if they have WA
	- when was the last time they updated it(through WeakAuras Sync)
	- who was the last person to update it
	- current wago version(version/semver)
	- current load "never" state

WeakAuras Sync changes default behavior of WAChecker module,

Normal behavior of 'share' button is replaced, but still can be accessed.
To use default WAChecker functionality:(these are applicable if users you poll don't have this addon installed):
	- to check if users have WA installed either:
		- left click on WA name
		- using right click menu select `Check WA availability`
	- to link WA in chat:
		- using right click menu select `Link WA in chat`

How to use WeakAuras Sync functionallity:
	To send WA:
		click on 'share' button to open WeakAuras Sync Sender window
		here you can choose import mode, custom receiver and whether to update last sync time

		import mode is used to determine how to import WA on receiving end

		for PUBLIC version of this addon there is only one import mode available which is using internal WeakAuras import function and safe to use.
			Other import modes are available only for PRIVATE version of this addon, because of possible issues:
				- Main issue is that import logic of advanced modes is not perfect and instead of creating duplicates
				  it deletes WAs if they have the same name as the imported ones even if they are located in different groups/have different UID,
				  but this behavior is intended to avoid duplicates so advanced modes are not coming to public release

		for PRIVATE version of WeakAuras Sync there is 5 import modes available:
			- [DEFAULT] WeakAuras Import - uses internal WeakAuras import function and safe to use

			See ImportFunctions.lua for more information about import process

			- [WAS] Import Missing - imports only WAs that are not present on receiving end

			- [WAS] Update - updates WAs data except fields that are handled with 'categories to ignore when importing' setting:

			- [WAS] Force Update(Save Load 'Never') - updates WAs data except load 'Never'

			- [WAS] Force Full Update - fully updates WAs data

		You can specify where to send a WA: channel/specific player, AUTO will send to all players in a group
		If you use GUILD channel, only players who are in your guild and in the same group as you will receive the WA

		update last sync is used to update information about last sync time for WeakAura(pressing send button with alt key pressed will ignore this checkbox)
		last sync is used to show information about when was the last time WA was updated
		if using import modes other than    [WAS] Force Update(Save Load 'Never') or
											[WAS] Force Full Update
			last sync time will be used to determine if WA should be updated or not

		Send button is used to send WAs to other players but there is also some modifiers:
			- default click - to send WA
			- shift click - to add WA to the queue but do not send it yet
			- alt click - to not update last sync time for current WA(ignoring checkbox)
			- ctrl click - instead of adding WA to queue will start sending WAs that are already queued

	To poll information about last sync and last sender:
		right click on 'share' button to start poll
		when information is received it will be shown in tooltips for icons(yellow cheks or thiccker red x)
		to poll information about WeakAuras ADDON VERSION you need to left click on line "WeakAuras AddOn Version" or press "Update" button
]]

local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

---@class Locale
local LR = AddonDB.LR

AddonDB:RenameModule(module, "|cFF8855FFWeakAuras Sync|r")
AddonDB:SwitchModulesOrder(module, MRT.A.Profiles)

---@class ELib
local ELib, L = MRT.lib, MRT.L
---@class MLib
local MLib = AddonDB.MLib

---@class WASyncPrivate
AddonDB.WASYNC = {}

---@class WASyncPrivate
local WASync = AddonDB.WASYNC
WASync.RELOAD_AFTER_IMPORTS = false -- in case we need to reload due to changes in WeakAuras
WASync.FORCE_IMPORTS = false -- in case we dont want people to have an option to skip imports
WASync.isDebugMode = false
WASync.VERSION = 13
WASync.WAMAP_VERSION = 2

local defaultAsyncConfig = {
	maxTime = 50,
	maxTimeCombat = 8,
	errorHandler = geterrorhandler(),
}

function module:Async(func, ...)
	AddonDB:Async(defaultAsyncConfig, func, ...)
end

-- WASYNC_MAIN_PRIVATE - global for WeakAuras addon's namespace
-- WASYNC_OPTIONS_PRIVATE - global for WeakAurasOptions addon's namespace
WASYNC_PROXY = WeakAuras -- global to access WeakAuras functions from custom code
module.PUBLIC = AddonDB.PUBLIC

local importData = {}
module.db.importData = importData

module.db.versionsData = {}
module.db.inspectData = {}

module.db.versionChecks = {}
module.db.versionChecksNames = {}

local errorsData = {}
module.db.errorsData = errorsData

module.db.allowList = {}

-- upvalues
local type, next, unpack, string, print = type, next, unpack, string, print
local min, Ambiguate, wipe, time, floor, max = min, Ambiguate, wipe, time, floor, max
local bit_lshift, bit_bor, GetTime, IsInGroup, IsShiftKeyDown, IsAltKeyDown =
	bit.lshift, bit.bor, GetTime, IsInGroup, IsShiftKeyDown, IsAltKeyDown
local bit_band, bit_bxor, UnitFullName, GetCurrentKeyBoardFocus, ChatFrame_OpenChat =
	bit.band, bit.bxor, UnitFullName, GetCurrentKeyBoardFocus, ChatFrame_OpenChat

---@class WeakAuras
local WeakAuras = WeakAuras

local WASYNC_ERROR = "|cffee5555ERROR:|r"
module.WASYNC_ERROR = WASYNC_ERROR
module.colorCode = "|cff9f3fff"

local function prettyPrint(...)
	print("|cff9f3fff[WASync]|r", ...)
end
module.prettyPrint = prettyPrint

function module:ShareButtonClick(button)
	local id = self:GetParent().db.data.id
	if id then
		if button == "RightButton" then
			if IsShiftKeyDown() then
				local WAData = WeakAuras.GetData(id)
				if WAData then
					WAData.exrtToSend = not WAData.exrtToSend
					module.options.UpdatePage(true)
				end
			else
				module:GetWAVer(id)
			end
		else
			if not module.SenderFrame then
				module:CreateSenderFrame()
			end
			module.SenderFrame:Update(id)
		end
	end
end

function module:ExternalExportWA(id, config)
	assert(type(id) == "string", "module:ExternalExportWA(id, config): id must be string")
	if not module.SenderFrame then
		module:CreateSenderFrame()
	end
	if config then
		for k,v in next, config do
			module.SenderFrameData[k] = v
		end
	end
	module.SenderFrame:Update(id)
	if config and config.send then
		module:Async(module.CompressAndSend, module, id, true, nil, true)
	end
end

WASync.QueueSenderStrings = { -- всегда оставлять первую строку
	"%s сделал вам подарок",
	"%s приложил свои пальчики к вашему...",
	"%s сейчас вставит свою ВАшку в ваш...",
	"%s намайнил на вас очередной биткоин",
	"%s ОПЯТЬ??????????",
	"Я сейчас удалю твой аддон (с) Змей",
	"ПЛАЧ ДЕДОВ? СЕКС С МОЛИС?",
	"МИШОК Я ТУТ ТАКОЕ ПРИДУМАЛ СЕЙЧАС РАСКАЖУ...",
	"СУКА ЕБАНЫЕ АДДОНЫ МИШОК",
	"Приготовьтесь, %s отправил обновление!",
	"Интересно, что на этот раз сделал %s.",
	"Получено обновление от %s. Давайте посмотрим, что там.",
	"%s отправил вам обновление интерфейса.",
	"%s не может остановиться! Новое обновление!",
	"Снова %s с обновлениями. Как вы думаете, что там?",
	"А это нормальный аддон? Я всякое говно не ставлю (с) Бадито",
	"%s разобрал боссов по полочкам",
	"%s получает коучинг в прямом эфире",
	"%s - кринжевик без урона но может в механики и выживание",
	"%s ваще тут?",
	"%s снова сделал что-то непонятное",
	"%s хуярит с Марса и не выкупает ничего кроме своих ВАшек",
	"%s - клоун с заваленным ебалом",
	"В классы чуть не попали, компенсируем ВАшками",
	"%s не понимает че происходит",
	"%s: тут все +- адекватно",
	"Че за нахуй иди нахуй бля ",
	"Я ТЕБЯ НАЙДУ МИШОК",
	"ПОЛУНДРА, %s ПРИШЕЛ",

}

if module.PUBLIC then
	WASync.ImportTypes = {
		[1] = "[DEFAULT] WeakAuras Import",
	}
else
	WASync.ImportTypes = {
		[1] = "[DEFAULT] WeakAuras Import",
		[2] = "|cFF8855FF[WAS]|r Import Missing",
		[3] = "|cFF8855FF[WAS]|r Update",
		[4] = "|cFF8855FF[WAS]|r Force Update(Save Load 'Never')",
		[5] = "|cFF8855FF[WAS]|r Force Full Update",
	}
end

-- those categories can be ignored while updating with import type 3(update)
--
WASync.update_categories = {
	{
		name = "anchor",
		fields = {
			xOffset = true,
			yOffset = true,
			selfPoint = true,
			anchorPoint = true,
			anchorFrameType = true,
			anchorFrameFrame = true,
			frameStrata = true,
			height = true,
			width = true,
			fontSize = true,
			scale = true,
			grow = true,
			align = true,
			zoom = true,
			keepAspectRatio = true,
		},
		label = "Size & Position",
		label2 = "S&P",
		default = false,
	},
	{
		name = "userconfig",
		fields = {
			config = true,
		},
		label = "Custom Configuration",
		label2 = "Conf",
		default = false,
	},
	{
		name = "trigger",
		fields = {
			triggers = true,
		},
		default = true,
		label = "Triggers",
		label2 = "Trig",
	},
	{
		name = "conditions",
		fields = {
			conditions = true,
		},
		default = true,
		label = "Conditions",
		label2 = "Cond",
	},
	{
		name = "load",
		fields = {
			load = true,
		},
		default = true,
		label = "Load Conditions",
		label2 = "Load",
	},
	{
		name = "actions",
		fields = {
			actions = true,
		},
		default = true,
		label = "Actions",
		label2 = "AC",
	},
	{
		name = "animation",
		fields = {
			animation = true,
		},
		default = true,
		label = "Animations",
		label2 = "Anm",
	},
	{
		name = "authoroptions",
		fields = {
			authorOptions = true,
		},
		default = true,
		label = "Author Options",
		label2 = "AO",
	},
	{
		name = "subregions",
		fields = {
			subRegions = true,
		},
		default = true,
		label = "Sub Regions",
		label2 = "SR",
	},
	{
		name = "color",
		fields = {
			color = true,
			barColor = true,
			barColor2 = true,
			backdropColor = true,
			backgroundColor = true,
			icon_color = true,
			shadowColor = true,
			enableGradient = true,
			gradientOrientation = true,
			texture = true,
			textureSource = true,
		},
		default = false,
		label = "Color and Textures",
		label2 = "Clr&Tex",
	},
	{
		name = "fonts",
		fields = {
			subRegions = {}, -- filled later
			font = true,
			fontSize = true,
			shadowXOffset = true,
			shadowYOffset = true,
			shadowColor = true,
			outline = true,
			justify = true,

		},
		default = false,
		label = "Fonts and Borders",
		label2 = "Fonts",
		fieldsTooltip = "Font and border settings for sub regions",
	},
	{
		name = "sounds",
		fields = {
			conditions = {}, -- filled later
			actions = {
				start = {
					sound = true,
					sound_channel = true,
					do_sound = true,
				},
				finish = {
					sound = true,
					sound_channel = true,
					do_sound = true,
				}
			},
		},
		default = false,
		label = "Sounds",
		label2 = "Sounds",
		fieldsTooltip = "Sound settings for conditions and actions",
	},
	{
		name = "glows",
		fields = {
			conditions = {}, -- filled later
			subRegions = {}, -- filled later
			actions = {
				start = {
					glow_color = true,
					use_glow_color = true,
					glow_type = true,
					glow_lines = true,
					glow_length = true,
					glow_thickness = true,
					glow_frequency = true,
				},
				finish = {
					glow_color = true,
					use_glow_color = true,
					glow_type = true,
					glow_lines = true,
					glow_length = true,
					glow_thickness = true,
					glow_frequency = true,
				},
			},
		},
		default = false,
		label = "Glows",
		label2 = "Glows",
		fieldsTooltip = "Glow settings for sub regions, conditions and actions",
	},
}

-- C_Timer.After(2,function() ddt(WASync) end)

do

	local subregionGlows = {
		glow = true,
		glowBorder = true,
		glowColor = true,
		glowFrequency = true,
		glowLength = true,
		glowLines = true,
		glowScale = true,
		glowThickness = true,
		glowType = true,
		glowXOffset = true,
		glowYOffset = true,
		useGlowColor = true,
		__WASYNC_ADDITIONAL_CHECK = function(data1, data2) return data1.type == data2.type end, -- do not preserve settings if subregion type has changed
	}

	local subregionFonts = {
		anchorXOffset = true,
		anchorYOffset = true,
		anchor_point = true,
		text_selfPoint = true,

		text_anchorPoint = true,
		text_anchorXOffset = true,
		text_anchorYOffset = true,
		text_automaticWidth = true,
		text_color = true,
		text_fixedWidth = true,
		text_font = true,
		text_fontSize = true,
		text_fontType = true,
		text_justify = true,
		text_shadowColor = true,
		text_shadowXOffset = true,
		text_shadowYOffset = true,
		text_visible = true,
		text_wordWrap = true,

		border_color = true,
		border_edge = true,
		border_offset = true,
		border_size = true,
		border_visible = true,
		__WASYNC_ADDITIONAL_CHECK = function(data1, data2) return data1.type == data2.type end, -- do not preserve settings if subregion type has changed
	}

	for i, c in next, WASync.update_categories do
		if c.name == "sounds" then
			for i = 1, 12 do
				local changes_template = {
					value = true,
					__WASYNC_ADDITIONAL_CHECK = function(data1, data2) -- do not preserve settings if property has changed
						return data1.property == data2.property and
						data1.property == "sound" and
						type(data1.value) == "table" and type(data2.value) == "table" and
						data1.value.sound_type == data2.value.sound_type
					end,
				}
				local changes = {}
				for j = 1, 12 do
					tinsert(changes, changes_template)
				end
				tinsert(c.fields.conditions, {
					changes = changes
				})
			end
		elseif c.name == "glows" then
			for i = 1, 12 do
				tinsert(c.fields.subRegions,CopyTable(subregionGlows))

				local changes_template = {
					value = true,
					__WASYNC_ADDITIONAL_CHECK = function(data1, data2) -- do not preserve settings if property has changed
						return data1.property == data2.property and
						(
							( -- glow external element
								data1.property == "glowexternal" and
								type(data1.value) == "table" and type(data2.value) == "table" and
								data1.value.glow_frame_type == data2.value.glow_frame_type
							) or
							( -- changes to glow subregion
								type(data1.property) == "string" and
								string.find(data1.property, "sub%.%d+%.glow") and
								type(data1.value or false) == type(data2.value or false) -- treat nil values as false)
							)
						)
					end,
				}
				local changes = {}
				for j = 1, 10 do
					tinsert(changes, changes_template)
				end
				tinsert(c.fields.conditions, {
					changes = changes
				})
			end
		elseif c.name == "fonts" then
			for i = 1, 12 do
				tinsert(c.fields.subRegions, CopyTable(subregionFonts))
			end
		end
	end

end

function module.getDefaultUpdateConfig()
	local updateConfig = 0
	for i = 1, #WASync.update_categories do
		if not WASync.update_categories[i].default then
			updateConfig = bit_bor(updateConfig, bit_lshift(1, i - 1))
		end
	end
	return updateConfig
end

--[[
default load never logic

* Load always means load never is set to false

exrtDefaultLoadNever
nil - save previous or inherit imported
1 - load never on first import
2 - load always on first import
3 - force load never
4 - force load always
]]


function module:SetPending(id,scheduleRecheck,Sender,ignoreSelf)
	if scheduleRecheck and type(scheduleRecheck) ~= "number" then
		scheduleRecheck = 5
	end

	for sender,db in next, module.db.responces do
		if (not Sender or (Sender == sender or Sender == MRT.F.delUnitNameServer(sender))) and
			(not ignoreSelf or (sender ~= MRT.SDB.charKey and sender ~= MRT.SDB.charName)) then
			db[id] = 4 -- waiting for response
		end
	end

	if module.options:IsVisible() and module.options.UpdatePage then
		module.options.UpdatePage(true)
	end

	if scheduleRecheck then
		C_Timer.After(scheduleRecheck,function ()
			for sender,db in next, module.db.responces do
				if (not Sender or (Sender == sender or Sender == MRT.F.delUnitNameServer(sender))) and
					(not ignoreSelf or (sender ~= MRT.SDB.charKey and sender ~= MRT.SDB.charName)) then
					if db and db[id] == 4 then
						db[id] = -3 -- waiting for response
					end
				end
			end

			if module.options:IsVisible() and module.options.UpdatePage then
				module.options.UpdatePage(true)
			end
		end)
	end
end

local TWO_WEEKS_CUTOFF = time() - 60 * 60 * 24 * 14

local filterKeywords = {
	["exrtToSend"] = {
		name = LR["Marked To Send"],
		tooltip = LR.WASyncKeywordToSendTip,
	},
	["exrtLastSync"] = {
		name = LR["Was ever sent"],
		func = function(id)
			local WAData = WeakAuras.GetData(id)
			if WAData then
				if not WAData.parent then return true end
				local parentData = WeakAuras.GetData(WAData.parent)
				return parentData.exrtLastSync ~= WAData.exrtLastSync
			end
		end,
	},
	["exrtLastSync2"] = {
		name = LR["Updated less then 2 weeks ago"],
		func = function(id)
			local WAData = WeakAuras.GetData(id)
			local cutOffPass = false
			if WAData and WAData.exrtLastSync then
				cutOffPass = WAData.exrtLastSync > TWO_WEEKS_CUTOFF
			end
			if cutOffPass then
				if not WAData.parent then return true end
				local parentData = WeakAuras.GetData(WAData.parent)
				return parentData.exrtLastSync ~= WAData.exrtLastSync
			end
		end
	},
}

local function CheckFilter(id, ignoreKeywords)
	local filter = module.options.Filter
	local filterLower = module.options.FilterLower

	if not id then return false end
	if not filter then return true end
	if not filterLower then return true end

	local isKeyword = filterKeywords[filter]
	if not isKeyword or ignoreKeywords then
		return id:lower():find(filterLower, 1, true) and true or false, false
	elseif type(isKeyword.func) == "function" then
		return isKeyword.func(id), true
	else
		local WAData = WeakAuras.GetData(id)
		if WAData then
			return WAData[filter], true
		end
	end
end


local function sendOnClick(id)
	module:ExternalExportWA(id)
end

local function checkVersionOnClick(id)
	module:GetWAVer(id)
end

local function checkWAOnClick(id)
	module:SetPending(id)
	module:SendReq2({[id]=true})
end

local function checkWATooltip(tooltip,elementDescription)
	tooltip:AddLine(MenuUtil.GetElementText(elementDescription))
	tooltip:AddLine(LR.WASyncWACheckTip, 1, 1, 1, true)
end

local function linkOnClick(id)
	local WAData = WeakAuras.GetData(id)
	if WAData then
		local url = WAData.url and  (" " .. WAData.url) or ""

		local name, realm = UnitFullName("player")
		local fullName = name .. "-" .. realm
		local link = "[WeakAuras: " .. fullName .. " - " .. id .. "]" .. url

		local editbox = GetCurrentKeyBoardFocus()
		if(editbox) then
			editbox:Insert(link)
		else
			ChatFrame_OpenChat(link)
		end
	end
end

local function sendWAOG(id)
	module:SendWA_OG(id)
end

local function sendWAOGTooltip(tooltip, elementDescription)
	tooltip:AddLine(MenuUtil.GetElementText(elementDescription))
	tooltip:AddLine(LR["WASyncSendOGTooltip"], 1, 1, 1, true)
end

local function markToSendOnClick(id)
	local WAData = WeakAuras.GetData(id)
	if WAData then
		WAData.exrtToSend = not WAData.exrtToSend
		module.options.UpdatePage(true)
	end
end
local function markToSendTooltip(tooltip, elementDescription)
	tooltip:AddLine(MenuUtil.GetElementText(elementDescription))
	tooltip:AddLine(LR.WASyncMarkToSendTip, 1, 1, 1, true)
end

local function showWAOnClick(id)
	if WeakAuras.IsOptionsOpen() then
		WeakAurasOptions:PickDisplay(id)
		WeakAurasOptions.buttonsScroll:DoLayout();
		WeakAurasOptions:CenterOnPicked()
	else
		WeakAuras.OpenOptions()
		if WeakAurasOptions.filterInput and WeakAurasOptions.filterInput:IsVisible() then
			WeakAurasOptions:PickDisplay(id)
			WeakAurasOptions.buttonsScroll:DoLayout();
			WeakAurasOptions:CenterOnPicked()
		end
	end
end
local function showWATooltip(tooltip, elementDescription)
	tooltip:AddLine(MenuUtil.GetElementText(elementDescription))
	tooltip:AddLine(LR.WASyncShowInWATip, 1, 1, 1, true)
end

local function ContextMenuGeneratorForID(ownerRegion, rootDescription, id)
	local WAData = WeakAuras.GetData(id)
	if not WAData then return end

	rootDescription:CreateTitle(id)
	rootDescription:CreateButton(LR.ListdSend .. "...", sendOnClick, id)
	rootDescription:CreateButton(LR.WASyncVersionCheck, checkVersionOnClick, id)
	local b1 = rootDescription:CreateButton(LR.WASyncWACheck, checkWAOnClick, id)
	b1:SetTooltip(checkWATooltip)
	rootDescription:CreateButton(LR.WASyncLinkToChat, linkOnClick, id)
	local b2 = rootDescription:CreateButton(LR["WASyncSendOG"], sendWAOG, id)
	b2:SetTooltip(sendWAOGTooltip)
	rootDescription:CreateDivider()
	local b3 = rootDescription:CreateButton(WAData.exrtToSend and LR.WASyncUnmarkToSend or LR.WASyncMarkToSend, markToSendOnClick, id)
	b3:SetTooltip(markToSendTooltip)
	rootDescription:CreateDivider()
	local b4 = rootDescription:CreateButton(LR.WASyncShowInWA, showWAOnClick, id)
	b4:SetTooltip(showWATooltip)
end

function module.options:Load()
	-- code from og wachecker, overwriting whole ui part
	self:CreateTilte()
	MLib:CreateModuleHeader(self)

	self.tab = MLib:Tabs2(self, 0, "WeakAuras", "Archive", "Comparator"):Point(0, -45):Size(698, 570):SetTo(1)

	local decorationLine = ELib:DecorationLine(self, true, "BACKGROUND", -5):Point("TOPLEFT", self, 0, -25):Point("BOTTOMRIGHT", self, "TOPRIGHT", 0, -45)
	decorationLine:SetGradient("VERTICAL", CreateColor(0.17, 0.17, 0.17, 0.77), CreateColor(0.17, 0.17, 0.17, 0.77))

	local UpdatePage

	local errorNoWA = ELib:Text(self, L.WACheckerWANotFound):Point("TOP", 0, -30)
	errorNoWA:Hide()

	local PAGE_HEIGHT, PAGE_WIDTH = 435, 799
	local LINE_HEIGHT, LINE_NAME_WIDTH = 16, 243
	local VERTICALNAME_WIDTH = 20
	local VERTICALNAME_COUNT = 26

	self.ReloadRequest = MLib:Button(self, LR["Request ReloadUI"]):Point("TOPRIGHT", self, "TOPRIGHT", -5, -25):Size(140, 20):OnClick(function()
		local isPass, reason = AddonDB:CheckSelfPermissions(WASync.isDebugMode)
		if not isPass then
			prettyPrint(LR["Not enough permissions to request reload UI"] .. (reason and ": " .. reason or ""))
			return
		end
		module:RequestReloadUI()
	end)

	local mainScroll = ELib:ScrollFrame(self.tab.tabs[1]):Size(PAGE_WIDTH, PAGE_HEIGHT):Point("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 30):Height(700)
	ELib:Border(mainScroll, 0)

	ELib:DecorationLine(self.tab.tabs[1]):Point("BOTTOM", mainScroll, "TOP", 0, 0):Point("LEFT", self):Point("RIGHT", self):Size(0, 1)
	ELib:DecorationLine(self.tab.tabs[1]):Point("TOP", mainScroll, "BOTTOM", 0, 0):Point("LEFT", self):Point("RIGHT", self):Size(0, 1)

	local prevTopLine = 0
	local prevPlayerCol = 0

	mainScroll.ScrollBar:ClickRange(LINE_HEIGHT)
	mainScroll.ScrollBar.slider:SetScript("OnValueChanged", function (self, value)
		local parent = self:GetParent():GetParent()
		parent:SetVerticalScroll(value % LINE_HEIGHT)
		self:UpdateButtons()
		local currTopLine = floor(value / LINE_HEIGHT)
		if currTopLine ~= prevTopLine then
			prevTopLine = currTopLine
			UpdatePage()
		end
	end)

	local raidSlider = ELib:Slider(self, ""):Point("TOPLEFT", mainScroll, "BOTTOMLEFT", LINE_NAME_WIDTH + 15, -3):Range(0, 25):Size(VERTICALNAME_WIDTH * VERTICALNAME_COUNT):SetTo(0):OnChange(function(self, value)
		local currPlayerCol = floor(value)
		if currPlayerCol ~= prevPlayerCol then
			prevPlayerCol = currPlayerCol
			UpdatePage()
		end
	end)
	raidSlider.Low:Hide()
	raidSlider.High:Hide()
	raidSlider.text:Hide()
	raidSlider.Low.Show = raidSlider.Low.Hide
	raidSlider.High.Show = raidSlider.High.Hide


	local function SetIcon(self, type)
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
		elseif type == 3 then -- lock
			self:SetAtlas("AdventureMapIcon-Lock")
		elseif type == 4 then -- pending
			self:SetAtlas("ui-lfg-roleicon-pending")
		elseif type == 5 then -- different
			if C_Texture.GetAtlasInfo("Islands-QuestBangDisable") then
				self:SetAtlas("Islands-QuestBangDisable")
			else
				self:SetAtlas("QuestTurnin")
			end
		elseif type == -1 or type < 0 then
			if module.SetIconExtra then
				module.SetIconExtra(self,type)
			end
		end
	end

	self.helpicons = {}
	for i=0,2 do
		local icon = self.tab.tabs[1]:CreateTexture(nil,"ARTWORK")
		icon:SetPoint("TOPLEFT",self,"TOPLEFT",2,(-14-i*14)-40)
		icon:SetSize(16, 16)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		SetIcon(icon, i + 1)
		local t = ELib:Text(self.tab.tabs[1], "", 10):Point("LEFT", icon, "RIGHT", 2, 0):Size(0, 16):Color(1, 1, 1)
		if i == 0 then
			t:SetText(L.WACheckerMissingAura)
		elseif i == 1 then
			t:SetText(L.WACheckerExistsAura)
		elseif i == 2 then
			t:SetText(L.WACheckerPlayerHaveNotWA)
		end
		self.helpicons[i + 1] = {icon, t}
	end
	self.helpicons2 = {}
	for i=0,2 do
		local icon = self.tab.tabs[1]:CreateTexture(nil, "ARTWORK")
		icon:SetPoint("TOPLEFT", self, "TOPLEFT", 150, (-14 - i * 14) - 40)
		icon:SetSize(16, 16)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		SetIcon(icon, -(i + 1))
		local t = ELib:Text(self.tab.tabs[1], "", 10):Point("LEFT", icon, "RIGHT", 2, 0):Size(0, 16):Color(1, 1, 1)
		if i == 0 then
			t:SetText(LR["Aura not updated"])
		elseif i==1 then
			t:SetText(LR["Aura updated"])
		elseif i==2 then
			t:SetText(LR["User didn't respond"])
		end
		self.helpicons2[i+1] = {icon,t}
	end
	self.helpicons3 = {}
	for i=1,3 do
		local icon = ELib:Text(self.tab.tabs[1], "S", 14):Point("TOPLEFT", self, "TOPLEFT", 5, -84 - i * 14):Size(0, 14):Color(1, 1, 1)
		local t = ELib:Text(self.tab.tabs[1], "", 10):Point("LEFT", icon, "RIGHT", 1, 0):Size(0, 16):Color(1, 1, 1)
		if i == 1 then
			t:SetText(LR["Was ever sent"])
			icon:Color(.33, .93, .33)
		elseif i == 2 then
			t:SetText(LR["Updated less then 2 weeks ago"])
			icon:Color(1, .5, .0)
		elseif i == 3 then
			icon:FontSize(12)
			icon:SetText("MTS")
			t:SetText(LR["Marked To Send"])
			icon:Color(0, .5, 1)
		end
		self.helpicons3[i] = {icon, t}
	end

	self.filterEdit = ELib:Edit(self.tab.tabs[1]):Size(LINE_NAME_WIDTH, 20):InsideIcon([[Interface\Common\UI-Searchbox-Icon]], nil, 18):Point("BOTTOMLEFT", mainScroll, "TOPLEFT", 2, 4):Tooltip(SEARCH):OnChange(function(self, isUser)
		local text = self:GetText()
		if text == "" then
			text = nil
			self:BackgroundText(SEARCH)
		else
			self:BackgroundText("")
		end

		module.options.Filter = text
		module.options.FilterLower = text and text:lower() or nil

		if self.scheduledUpdate then
			return
		end
		self.scheduledUpdate = C_Timer.NewTimer(.1, function()
			self.scheduledUpdate = nil
			-- module.options.scrollList.ScrollBar.slider:SetValue(0)
			UpdatePage(true)
		end)
	end)
	self.filterEdit:BackgroundText(SEARCH)
	self.filterEdit:SetTextColor(0, 1, 0, 1)
	self.filterEditDropDown = ELib:DropDown(self.filterEdit, 260, -1):Size(20):Point("RIGHT", self.filterEdit, "RIGHT", 0, 0)
	self.filterEditDropDown:HideBorders()

	do
		local function SetValue(_, k)
			module.options.filterEdit:SetText("")
			module.options.filterEdit:SetText(k or "")
			module.options.filterEdit:ClearFocus()
			ELib:DropDownClose()
			if IsShiftKeyDown() then
				local req = {}
				for id,data in next, WeakAurasSaved.displays do
					if data[k] then
						req[#req+1] = id
					end
				end
				module:GetWAVerMulti(req)
			end
		end
		local List = self.filterEditDropDown.List
		for k, data in next, filterKeywords do
			List[#List+1] = {
				text = data.name,
				arg1 = k,
				func = SetValue,
				tooltip = data.tooltip,
			}
		end
		sort(List, function(a, b) return a.text < b.text end)
		List[#List+1] = {
			text = DELETE,
			func = SetValue,
		}
		List[#List+1] = {
			text = CLOSE,
			func = ELib.DropDownClose,
		}
	end

	local function OnTooltipEnter(self)
		local text = self.t:GetText()
		if text == "WeakAuras AddOn Version" then
			ELib.Tooltip.Show(self, self.a, text:trim(), {LR.WASyncLineNameTip2, 1, 1, 1})
			return
		end
		local line = self:GetParent()
		local db = line.db

		local tooltip = {{LR.WASyncLineNameTip1, 1, 1, 1}}
		local id = db and db.name
		local checkTime = module.db.lastCheck[id]
		if checkTime then
			local checkName = module.db.lastCheckName[id] and Ambiguate(module.db.lastCheckName[id], "none") or "UNKNOWN"
			local now = time()
			local checkTime = module.db.lastCheck[id]
			tooltip[#tooltip+1] = " "
			tooltip[#tooltip+1] = {LR["Last basic check:"].. " " .. date("%X", checkTime), 1, 1, 1}
			if UnitExists(checkName) then
				checkName = AddonDB:ClassColorName(checkName)
			end
			tooltip[#tooltip+1] = {now-checkTime .. " " .. LR["seconds ago by"] .. " " .. checkName, 1, 1, 1}
		end
		local verCheckTime = module.db.versionChecks[id]
		if verCheckTime then
			local now = time()
			tooltip[#tooltip+1] = " "
			tooltip[#tooltip+1] = {LR["Last version check:"] .. " " .. date("%X", verCheckTime), 1, 1, 1}
			local checkName = module.db.versionChecksNames[id] and Ambiguate(module.db.versionChecksNames[id], "none") or "UNKNOWN"
			if UnitExists(checkName) then
				checkName = AddonDB:ClassColorName(checkName)
			end
			tooltip[#tooltip+1] = {now-verCheckTime ..  " " .. LR["seconds ago by"] .. " "  .. checkName, 1, 1, 1}
		end
		ELib.Tooltip.Show(self, self.a, text:trim(), unpack(tooltip))
	end

	local function LineName_OnClick(self, button, isUP)
		if button == "RightButton" then
			local db = self:GetParent().db
			local id = db and db.data and db.data.id or "--"

			-- days untill classic gets new menu system . . .
			if not (MenuUtil and MenuUtil.CreateContextMenu) then
				print("No menu for you classic guy. Stay small")
				return
			end
			MenuUtil.CreateContextMenu(self, ContextMenuGeneratorForID, id)
		else
			local db = self:GetParent().db
			local id = db and db.data and db.data.id or "--"
			if db.name == "VERSION" then
				module:SendReq({[id]=true})
			else
				module:SetPending(id)
				module:SendReq2({[id]=true})
			end
		end
	end
	local function LineName_ShareButton_OnEnter(self)
		if module.ShareButtonHover then
			module.ShareButtonHover(self)
		end
		self.background:SetVertexColor(1, 1, 0, 1)
	end
	local function LineName_ShareButton_OnLeave(self)
		if module.ShareButtonLeave then
			module.ShareButtonLeave(self)
		end
		self.background:SetVertexColor(1, 1, 1, 1)
	end
	local function LineName_ShareButton_OnClick(self, ...)
		module.ShareButtonClick(self, ...)
	end

	local function LineName_Icon_OnEnter(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Show(self, nil, self.HOVER_TEXT)
		end
		if module.IconHoverFunctions then
			for i=1,#module.IconHoverFunctions do
				module.IconHoverFunctions[i](self, true)
			end
		end
	end
	local function LineName_Icon_OnLeave(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Hide()
		end
		if module.IconHoverFunctions then
			for i=1,#module.IconHoverFunctions do
				module.IconHoverFunctions[i](self, false)
			end
		end
	end

	local lines = {}
	self.lines = lines
	for i=1,floor(PAGE_HEIGHT / LINE_HEIGHT) + 2 do
		local line = CreateFrame("Frame", nil, mainScroll.C)
		lines[i] = line
		line:SetPoint("TOPLEFT", 0, -(i-1)*LINE_HEIGHT)
		line:SetPoint("TOPRIGHT", 0, -(i-1)*LINE_HEIGHT)
		line:SetSize(0, LINE_HEIGHT)

		line.name = ELib:Text(line, "", 10):Point("LEFT", 5, 0):Size(LINE_NAME_WIDTH - LINE_HEIGHT/2, LINE_HEIGHT):Color(1, 1, 1):Tooltip("ANCHOR_LEFT", true)
		line.name.TooltipFrame:SetScript("OnClick", LineName_OnClick)
		line.name.TooltipFrame:SetScript("OnEnter", OnTooltipEnter)
		line.name.TooltipFrame:SetScript("OnLeave", ELib.Tooltip.Hide)
		line.name.TooltipFrame:RegisterForClicks("LeftButtonUp", "RightButtonUp")


		line.share = CreateFrame("Button", nil, line)
		line.share:SetPoint("LEFT", line.name, "RIGHT", 0, 0)
		line.share:SetSize(LINE_HEIGHT, LINE_HEIGHT)
		line.share:SetScript("OnEnter", LineName_ShareButton_OnEnter)
		line.share:SetScript("OnLeave", LineName_ShareButton_OnLeave)
		line.share:SetScript("OnClick", LineName_ShareButton_OnClick)
		line.share:RegisterForClicks("LeftButtonUp", "RightButtonUp")

		line.share.background = line.share:CreateTexture(nil, "ARTWORK")
		line.share.background:SetPoint("CENTER")
		line.share.background:SetSize(LINE_HEIGHT-4, LINE_HEIGHT-4)
		line.share.background:SetAtlas("common-icon-forwardarrow")
		line.share.background:SetDesaturated(true)

		line.icons = {}
		local iconSize = min(VERTICALNAME_WIDTH, LINE_HEIGHT) + 2
		for j=1,VERTICALNAME_COUNT do
			local icon = line:CreateTexture(nil, "ARTWORK")
			line.icons[j] = icon
			icon:SetPoint("CENTER", line, "LEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(j-1) + VERTICALNAME_WIDTH / 2, 0)
			icon:SetSize(iconSize, iconSize)
			icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
			SetIcon(icon, (i+j)%4)

			icon.hoverFrame = CreateFrame("Frame", nil, line)
			-- icon.hoverFrame:Hide()
			icon.hoverFrame:SetAllPoints(icon)
			icon.hoverFrame:SetScript("OnEnter", LineName_Icon_OnEnter)
			icon.hoverFrame:SetScript("OnLeave", LineName_Icon_OnLeave)
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

	local function RaidNames_OnClick(self)
		local name = self.t.fullname
		if not module.inspectFrame then
			module.options:InitializeInspect()
		end
		if name then
			module.inspectFrame:SetNewPlayer(name)
		end
	end

	local function RaidNames_OnDragStart(self)
		-- this sometimes snaps frame
		self:GetParent():GetParent():GetParent():GetParent():StartMoving() -- tabs -> tab -> wacheckerframe -> global mrt frame?
	end

	local function RaidNames_OnDragStop(self)
		self:GetParent():GetParent():GetParent():GetParent():StopMovingOrSizing()
	end

	local raidNames = CreateFrame("Frame", nil, self.tab.tabs[1])
	for i=1,VERTICALNAME_COUNT do
		raidNames[i] = ELib:Text(raidNames, "RaidName"..i, 10):Point("BOTTOMLEFT", mainScroll, "TOPLEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0):Color(1, 1, 1)

		local f = CreateFrame("Button", nil, self.tab.tabs[1])
		f:SetPoint("BOTTOMLEFT", mainScroll, "TOPLEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0)
		f:SetSize(VERTICALNAME_WIDTH, 65)
		f:SetScript("OnEnter", RaidNames_OnEnter)
		f:SetScript("OnLeave", ELib.Tooltip.Hide)
		f.t = raidNames[i]

		f:RegisterForClicks("LeftButtonUp")
		f:SetScript("OnClick", RaidNames_OnClick)

		f:RegisterForDrag("LeftButton")
		f:SetScript("OnDragStart", RaidNames_OnDragStart)
		f:SetScript("OnDragStop", RaidNames_OnDragStop)

		local t = mainScroll:CreateTexture(nil, "BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT", LINE_NAME_WIDTH + 15 + VERTICALNAME_WIDTH*(i-1), 0)
		t:SetSize(VERTICALNAME_WIDTH, PAGE_HEIGHT)
		if i%2==1 then
			t:SetColorTexture(.5, .5, 1, .05)
			t.Vis = true
		end
	end
	local group = raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local highlight_y = mainScroll.C:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_y:SetColorTexture(1, 1, 1, .2)
	local highlight_x = mainScroll:CreateTexture(nil, "BACKGROUND", nil, 2)
	highlight_x:SetColorTexture(1, 1, 1, .2)

	local highlight_onupdate_maxY = (floor(PAGE_HEIGHT / LINE_HEIGHT) + 2) * LINE_HEIGHT
	local highlight_onupdate_minX = LINE_NAME_WIDTH + 15
	local highlight_onupdate_maxX = highlight_onupdate_minX + #raidNames * VERTICALNAME_WIDTH
	mainScroll.C:SetScript("OnUpdate", function(self)
		local x, y = MRT.F.GetCursorPos(mainScroll)
		if y < 0 or y > PAGE_HEIGHT then
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		local x, y = MRT.F.GetCursorPos(self)
		if y >= 0 and y <= highlight_onupdate_maxY then
			y = floor(y / LINE_HEIGHT)
			highlight_y:ClearAllPoints()
			highlight_y:SetAllPoints(lines[y+1])
			highlight_y:Show()
		else
			highlight_x:Hide()
			highlight_y:Hide()
			return
		end
		if x >= highlight_onupdate_minX and x <= highlight_onupdate_maxX then
			x = floor((x - highlight_onupdate_minX) / VERTICALNAME_WIDTH)
			highlight_x:ClearAllPoints()
			highlight_x:SetAllPoints(raidNames[x+1].t)
			highlight_x:Show()
		elseif x >= 0 and x <= (PAGE_WIDTH - 16) then
			highlight_x:Hide()
		else
			highlight_x:Hide()
			highlight_y:Hide()
		end
	end)

	self.UpdateButton = MLib:Button(self.tab.tabs[1], UPDATE):Point("TOPLEFT", mainScroll, "BOTTOMLEFT", 2, -5):Size(120, 20):OnClick(function(self)
		wipe(module.db.responces)
		module:SendReq() -- using old here as sendReq2 requires abnormous amount of data
		self:Disable()
		C_Timer.After(5, function()
			self:Enable()
		end)
	end)

	local function sortByUnitName(nameA, nameB)
		if nameA and nameB then
			local shortNameA = Ambiguate(nameA, "none")
			local shortNameB = Ambiguate(nameB, "none")

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
			elseif hasDBA and not hasDBB then
				return true
			elseif not hasDBA and hasDBB then
				return false
			elseif hasCyrA and not hasCyrB then
				return true
			elseif not hasCyrA and hasCyrB then
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

	local function sortByName(a, b)
		return a.name < b.name
	end

	local function GetTopParent(data) -- returns id of the top parent
		local parent = data.parent
		local isPass, isKeyword = CheckFilter(parent, true)
		if parent and not isKeyword and isPass then
			local parentData = WeakAuras.GetData(parent)
			return GetTopParent(parentData)
		else
			return data
		end
	end

	function UpdatePage(fullUpdate)
		local WeakAurasSaved = _G.WeakAurasSaved
		if not WeakAurasSaved then
			errorNoWA:Show()
			mainScroll:Hide()
			raidSlider:Hide()
			for i=1,#self.helpicons do
				self.helpicons[i][1]:SetAlpha(0)
				self.helpicons[i][2]:SetAlpha(0)
			end
			self.UpdateButton:Hide()
			raidNames:Hide()
			self.filterEdit:Hide()
			self.allIsHidden = true
			return
		end
		if self.allIsHidden then
			self.allIsHidden = false
			errorNoWA:Hide()
			mainScroll:Show()
			for i=1,#self.helpicons do
				self.helpicons[i][1]:SetAlpha(1)
				self.helpicons[i][2]:SetAlpha(1)
			end
			self.UpdateButton:Show()
			raidNames:Show()
		end


		local sortedTable
		if not self.sortedTable or fullUpdate then

			local auras = {} -- auras that will be shown, table have a nested structure
			local ignore = {}

			local function addToShow(data, levelCount, prevLevel, shallow)
				levelCount = levelCount or 0

				local aura = {
					name = data.id,
					data = data,
					level = levelCount,
				}

				if not shallow or levelCount == 0 then
					ignore[data.id] = true
					prevLevel = prevLevel or auras
					prevLevel[#prevLevel+1] = aura
				end

				if data.controlledChildren then
					for i=1,#data.controlledChildren do

						local child = WeakAuras.GetData(data.controlledChildren[i])
						if child then
							addToShow(child, levelCount+1, aura, shallow)
						end
					end
				end
			end

			for _,data in next, WeakAurasSaved.displays do
				local id = data.id
				if not ignore[id] then
					-- ignore[id] = true

					local isPass, isKeyword = CheckFilter(id)
					if isPass then
						-- add aura and a parent and a children to auras
						local parent = GetTopParent(data) -- if data is already top level it will return itself's id
						addToShow(parent, nil, nil, isKeyword)

					end
				end
			end

			sortedTable = {}
			if not self.Filter then
				sortedTable[1] = {name="VERSION"}
			end
			sort(auras, sortByName)
			local function addAuras(auras)
				for i=1,#auras do
					local aura = auras[i]
					sortedTable[#sortedTable+1] = aura

					if aura[1] then
						addAuras(aura)
					end
				end
			end
			addAuras(auras)

			self.sortedTable = sortedTable
			self.sortedTableLength = #sortedTable
			mainScroll.ScrollBar:Range(0, max(0, self.sortedTableLength * LINE_HEIGHT - 1 - PAGE_HEIGHT), nil, true)
		else
			sortedTable = self.sortedTable
		end

		local namesList, namesList2 = {}, {}

		for unit in AddonDB:IterateGroupMembers() do
			namesList[#namesList + 1] = AddonDB:GetFullName(unit)
		end

		-- for i=1,30 do
		--     namesList[#namesList + 1] = {
		--         name = "Player"..i,
		--         class = "WARRIOR",
		--     }
		-- end

		sort(namesList,sortByUnitName)

		if #namesList <= VERTICALNAME_COUNT then
			raidSlider:Hide()
			prevPlayerCol = 0
		else
			raidSlider:Show()
			raidSlider:Range(0, #namesList - VERTICALNAME_COUNT)
		end

		local raidNamesUsed = 0
		for i=1+prevPlayerCol, #namesList do
			raidNamesUsed = raidNamesUsed + 1
			if not raidNames[raidNamesUsed] then
				break
			end
			local name = namesList[i]
			local shortName = Ambiguate(name, "none")
			local coloredName = AddonDB:ClassColorName(shortName)
			raidNames[raidNamesUsed]:SetAlpha(1)

			namesList2[raidNamesUsed] = name

			if not UnitIsConnected(shortName) then
				coloredName = "|cff808080" .. coloredName:gsub("|c%x%x%x%x%x%x%x%x", "")
			elseif not UnitIsVisible(shortName) then
				raidNames[raidNamesUsed]:SetAlpha(.5)
			end

			raidNames[raidNamesUsed]:SetText(coloredName)

			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
			raidNames[raidNamesUsed].fullname = name
		end
		for i=raidNamesUsed+1,#raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
			raidNames[i].fullname = nil
		end

		local lineNum = 1
		local backgroundLineStatus = (prevTopLine % 2) == 1

		for i=prevTopLine+1,self.sortedTableLength do
			local aura = sortedTable[i]
			local line = lines[lineNum]
			if not line then
				break
			end
			line:Show()

			local suffix = ""
			if aura.data then
				local parentData = aura.data.parent and WeakAuras.GetData(aura.data.parent)
				if aura.data.exrtLastSync and (not parentData or parentData.exrtLastSync ~= aura.data.exrtLastSync) then
					suffix = " (" .. (aura.data.exrtLastSync < TWO_WEEKS_CUTOFF and "|cff80ff00" or "|cffff8800") .. "S|r)"
				end
				if aura.data.exrtDefaultLoadNever then
					local dln = aura.data.exrtDefaultLoadNever
					if dln == 1 then -- red N
						suffix = suffix .. " |cffff0000N|r"
					elseif dln == 2 then -- green N
						suffix = suffix .. " |cff00ff00N|r"
					elseif dln == 3 then -- red NF
						suffix = suffix .. " |cffff0000NF|r"
					elseif dln == 4 then -- green NF
						suffix = suffix .. " |cff00ff00NF|r"
					end
				end
				if aura.data.exrtToSend then
					suffix = suffix .. " |cff0080ffMTS|r"
				end
			end


			line.name:SetText((aura.level and aura.level > 0 and string.rep("   ", aura.level) .. "- " or "")..aura.name .. suffix)
			line.db = aura
			line.t:SetShown(backgroundLineStatus)
			if i == 1 and aura.name == "VERSION" then
				line.name:SetText("WeakAuras AddOn Version")
				line.share:Hide()
			else
				line.share:Show()
			end

			for j=1,VERTICALNAME_COUNT do
				local pname = namesList2[j] or "-"

				local db = module.db.responces[pname] or not IsInGroup() and module.db.responces[MRT.F.delUnitNameServer(pname)]

				if not db then
					SetIcon(line.icons[j]) -- must be 0 or nil to hide icon
				elseif db.noWA then
					SetIcon(line.icons[j],3)
				elseif aura.name == "VERSION" then
					SetIcon(line.icons[j],WeakAuras.versionString == db.wa_ver and 2 or (db.wa_ver and 1) or 3)
				elseif type(db[ aura.name ]) == 'number' then
					SetIcon(line.icons[j],db[ aura.name ]) -- to show pending status or some unknown stuff
				elseif db[ aura.name ] then
					SetIcon(line.icons[j],2) -- to show ready status
				else
					SetIcon(line.icons[j],1) -- to show missing status
				end

				line.icons[j].hoverFrame.name = pname
			end
			backgroundLineStatus = not backgroundLineStatus
			lineNum = lineNum + 1
		end
		for i=lineNum,#lines do
			lines[i]:Hide()
		end
	end
	self.UpdatePage = UpdatePage
	self.ScheduleUpdate = function()
		if not module.updTimer then
			module.updTimer = C_Timer.NewTimer(0.2, function()
				module.updTimer = nil
				self.UpdatePage()
			end)
		end
	end


	module.importWindow = MLib:Popup(module.colorCode.."WASync Import"):CreateTitleBackground()
	module.importWindow:Size(400, 180)

	module.importWindow.idText = ELib:Text(module.importWindow, "ID:"):Point("TOPLEFT", module.importWindow, "TOPLEFT", 10, -30):Color():Shadow()
	module.importWindow.uidText = ELib:Text(module.importWindow, "UID:"):Point("TOPLEFT", module.importWindow.idText, "BOTTOMLEFT", 0, -5):Color():Shadow()

	module.importWindow.ImportTypeDropDown = ELib:DropDown(module.importWindow, 230, #WASync.ImportTypes):Size(200, 20):Point("BOTTOMLEFT", module.importWindow, "BOTTOMLEFT", 10, 10)
	module.importWindow.ImportTypeText = ELib:Text(module.importWindow, LR["Import Mode:"]):Point("BOTTOMLEFT", module.importWindow.ImportTypeDropDown, "TOPLEFT", 0, 5):Color():Shadow()
	do
		local ImportSetValue = function(_, arg)
			ELib:DropDownClose()
			module.importWindow.importType = arg
			module.importWindow.ImportTypeDropDown:SetText(WASync.ImportTypes[arg])

			if module.importWindow.updateConfigDropDown then
				module.importWindow.updateConfigDropDown:Shown(arg == 3)
			end
		end

		local List = module.importWindow.ImportTypeDropDown.List
		for i=1,#WASync.ImportTypes do
			List[#List+1] = {
				text = WASync.ImportTypes[i],
				arg1 = i,
				func = ImportSetValue,
			}
		end
		ImportSetValue(nil, 3)
	end

	module.importWindow.updateConfig = module.getDefaultUpdateConfig()

	module.importWindow.updateConfigDropDown = ELib:DropDown(module.importWindow, 230, -1):Size(300, 20):Point("BOTTOMLEFT", module.importWindow.ImportTypeDropDown, "TOPLEFT", 0, 25)
	module.importWindow.updateConfigText = ELib:Text(module.importWindow.updateConfigDropDown, LR["Categories to ignore when importing:"]):Point("BOTTOMLEFT", module.importWindow.updateConfigDropDown, "TOPLEFT", 0, 5):Color():Shadow()
	do
		local function config_SetValue(_, arg1)
			module.importWindow.updateConfig = arg1
			-- update drop down text
			local text = ""
			for i=1,#WASync.update_categories do
				if bit_band(module.importWindow.updateConfig or 0, bit_lshift(1,i-1)) > 0 then
					text = text .. (text == "" and "" or ", ") .. WASync.update_categories[i].label2
				end
			end

			-- update state cheks
			for i=1,#module.importWindow.updateConfigDropDown.List do
				local check = bit_band(module.importWindow.updateConfig or 0, bit_lshift(1, i-1)) > 0
				module.importWindow.updateConfigDropDown.List[i].checkState = check
			end

			module.importWindow.updateConfigDropDown:SetText(text)
			if ELib.ScrollDropDown.DropDownList[1].parent == module.importWindow.updateConfigDropDown then
				module.importWindow.updateConfigDropDown.Button:Click()
				module.importWindow.updateConfigDropDown.Button:Click()
			end
		end
		module.importWindow.updateConfigDropDown.SetValue = config_SetValue

		local function config_SetCheck(self)
			local val = module.importWindow.updateConfig or 0
			local arg1 = self.data.arg1
			local arg2 = self.data.arg2
			-- val is our bitfield
			-- arg1 is index of bit to change
			-- check state is new state of bit
			-- use bit functions to change bit
			local checkState = not (bit_band(val, bit_lshift(1, arg1)) > 0)

			if checkState then
				val = bit_bor(val, arg2)
			else
				val = bit_bxor(val, arg2)
			end

			-- if val == 0 then
			--     val = nil
			-- end
			config_SetValue(nil, val)
		end

		local function hoverFunc(self, hoverArg)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 20)
			GameTooltip:AddLine(self:GetText())
			if hoverArg then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine(hoverArg, 1, 1, 1, true)
			end
			GameTooltip:Show()
		end

		local List = module.importWindow.updateConfigDropDown.List
		for i=1,#WASync.update_categories do
			local tooltipText = WASync.update_categories[i].fieldsTooltip or table.concat(MRT.F.TableToText(WASync.update_categories[i].fields))

			List[#List+1] = {
				text = WASync.update_categories[i].label,
				arg1 = i - 1,
				arg2 = 2^(i-1),
				func = config_SetCheck,
				checkable = true,
				checkFunc = config_SetCheck,
				hoverFunc = hoverFunc,
				hoverArg = tooltipText,
			}
		end
		module.importWindow.updateConfigDropDown:SetValue(module.importWindow.updateConfig)
	end
	module.importWindow.updateConfigDropDown:Shown(module.importWindow.importType == 3)
	module.importWindow.importButton = MLib:Button(module.importWindow, LR["Import"]):Size(120, 20):Point("BOTTOMRIGHT", module.importWindow, "BOTTOMRIGHT", -10, 10):OnClick(function(self)
		local transmit = module.importWindow.transmit

		-- apply ignore config to the parent aura and clear children
		transmit.d.exrtUpdateConfig = module.importWindow.updateConfig or module.getDefaultUpdateConfig() or 0
		if transmit.c then
			for i, child in ipairs(transmit.c) do
				child.exrtUpdateConfig = nil
			end
		end

		module.QueueFrame:AddToQueue({
			str = transmit,
			sender = "WAS Import",
			id = transmit.d.id,
			importType = module.PUBLIC and 1 or module.importWindow.importType,
			stringNum = 1,
			imageNum = 1,
			skipPrompt = true,
			postImportCallback = type(transmit.postImportCallback) == "function" and transmit.postImportCallback or nil,
		})
		module.importWindow:Hide()
	end)

	function module.importWindow:Update()
		local transmit = module.importWindow.transmit
		if transmit then
			module.importWindow.idText:SetText("ID: " .. transmit.d.id)
			module.importWindow.uidText:SetText("UID: " .. transmit.d.uid)
		else
			module.importWindow.idText:SetText("ID: none")
			module.importWindow.uidText:SetText("UID: none")
		end
	end

	function module.importWindow:SetTransmit(transmit)
		if transmit then
			module.importWindow.transmit = transmit
			module.importWindow:Update()
			module.importWindow:Show()
		else
			module.importWindow.transmit = nil
			module.importWindow:Hide()
		end
	end

	local ParseImportString = AddonDB:WrapAsyncSingleton(function(str)
		if str:trim() == "" or #str < 200 then
			return
		end

		local data = module.StringToTable(str, true)
		if type(data) == "table" then
			module.importWindow:SetTransmit(data)
		else
			prettyPrint("WASync Import Error", data)
			module.importWindow:SetTransmit(nil)
		end
	end)

	local importButton = MLib:Button(self.tab.tabs[1], LR["Import"]):Size(120, 20):Point("LEFT", self.UpdateButton, "RIGHT", 5, 0):OnClick(function()
		AddonDB:QuickPaste(module.colorCode .. "WASync Import", ParseImportString)
	end):Shown(not module.PUBLIC)

	local debugCheck = ELib:Check(self.tab.tabs[1], L["Debug Mode"], WASync.isDebugMode):Point("LEFT", importButton, "RIGHT", 5, 0):OnClick(function(self)
		WASync.isDebugMode = self:GetChecked()
		if module.SenderFrame then
			module.SenderFrame:Update()
		end
	end):Shown(AddonDB.IsDev)


	module.options:LoadArchive()

	if module.options.LoadComparator then
		module.options:LoadComparator()
	else
		module.options.tab.tabs[3].button:Hide()
	end

	function module.options:AdditionalOnShow()
		UpdatePage(true)
		if (IsShiftKeyDown() and IsAltKeyDown()) or WASync.isDebugMode or AddonDB.IsDev then
			debugCheck:Show()
		else
			debugCheck:Hide()
		end
	end
	module.options:AdditionalOnShow()

	self.isWide = 799
end


local COLOR_GREEN = {.5, 1, .5}
local COLOR_RED = {1, .2, .2}
local COLOR_WHITE = {1, 1, 1}

module.IconHoverFunctions = {
	function(self, isEnter)
		if isEnter then
			local id = self:GetParent().db.name
			local pname = self.name
			if not pname then return end

			if id == "VERSION" then
				local DB = module.db.responces[pname]
				if DB then
					ELib.Tooltip.Show(self, nil, DB.wa_ver or DB.noWA and "WeakAuras is not installed" or "NO DATA")
					return
				end
			else
				local Date, lastSender, uid, version, semver, load_never
				local DB = module.db.versionsData[pname]
				local DB2 = module.db.responces[pname]

				if DB and DB[id] then
					Date = DB[id].date
					lastSender = DB[id].lastSender
					version = DB[id].version
					semver = DB[id].semver
					load_never = DB[id].load_never
					uid = DB[id].uid
				end

				if Date then
					local WAData = WeakAuras.GetData(id)

					-- print(format("Date: %q, lastSender: %q, version: %q, semver: %q, load_never: %q", tostring(Date), tostring(lastSender), tostring(version), tostring(semver), tostring(load_never)))
					local name = AddonDB.RGAPI and AddonDB.RGAPI:ClassColorName(Ambiguate(pname, "none")) or (AddonDB:ClassColorName(Ambiguate(pname, "none")) or pname)
					ELib.Tooltip.Show(self,nil,id,
						{name ~= "" and name or pname},
						{"Last sender:", right=lastSender and Ambiguate(lastSender,"none") or "No data", unpack(COLOR_WHITE)},
						{"Last update:",right=(Date ~= 0) and date("%X %x",Date) or "Never", unpack(WAData and Date ~= 0 and (WAData.exrtLastSync == Date and COLOR_GREEN or COLOR_RED) or COLOR_WHITE)},
						{"UID:", right=uid or "No data", unpack(WAData and (WAData.uid == uid and COLOR_GREEN or COLOR_RED) or COLOR_WHITE)},
						{"Version:", right=version or "No data", unpack(WAData and (WAData.version == version and COLOR_GREEN or COLOR_RED) or COLOR_WHITE)},
						{"Semver:", right=semver or "No data", unpack(WAData and (WAData.semver == semver and COLOR_GREEN or COLOR_RED) or COLOR_WHITE)},
						{"Load never:", right=load_never and "Yes" or "No", unpack(load_never and COLOR_RED or COLOR_GREEN)},
						DB2 and DB2[id] == 5 and {LR["WA is different version/changed"],unpack(COLOR_WHITE)}
					)
				else
					if DB2 and DB2[id] == 5 then -- 1 no wa, 2 has wa, 5 hash missmatch
						ELib.Tooltip.Show(self,nil,id,
						{LR["WA is different version/changed"], unpack(COLOR_WHITE)}
					)
					end
				end
			end
		else
			ELib.Tooltip.Hide()
		end
	end
}

function module.SetIconExtra(self,type)
	type = -type

	if type == 1 then -- not up to date
		self:SetAtlas("common-icon-redx")
	elseif type == 2 then -- up to date
		self:SetAtlas("common-icon-checkmark-yellow")
	elseif type == 3 then -- did not answer
		self:SetAtlas("worldquest-icon-clock")
	end
end

function module.ShareButtonHover(self)
	GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
	local name = self:GetParent().db.name
	GameTooltip:AddLine(name)
	GameTooltip:AddLine(LR["Left Click to share"], 1, 1, 1)
	GameTooltip:AddLine(LR["Right Click to check versions"], 1, 1, 1)
	GameTooltip:Show()
end

function module.ShareButtonLeave()
	ELib.Tooltip.Hide()
end

--------------------------------------------------------------------------------------------------------------------------------
-- Export and Sending
--------------------------------------------------------------------------------------------------------------------------------

function module:GetWAVer(id)
	module:SetPending(id, 3)
	MRT.F.SendExMsg("WAS_STATUS", "20\t" .. id)
end

function module:SendWAVer(id)
	if not id then return end

	local data = WeakAuras.GetData(id)
	if data then
		local lastSync = data.exrtLastSync or 0
		local lastSender = data.exrtLastSender or ""
		local version = data.version or ""
		local semver = data.semver or ""
		local load_never = "1"
		if data.regionType == "group" or data.regionType == "dynamicgroup" then
			-- traverse children to check if any of them dont use load.use_never set
			for c in module.pTraverseAllChildren(data) do
				if not (c.regionType == "group" or c.regionType == "dynamicgroup") and c.load and not c.load.use_never then
					load_never = ""
					break
				end
			end
		else
			load_never = data.load and data.load.use_never and "1" or ""
		end

		local msg = MRT.F.CreateAddonMsg("21", lastSync, id, lastSender, data.uid, version, semver, load_never)
		MRT.F.SendExMsg("WAS_STATUS", msg)
	end
end
function module:ShowReloadPrompt(sender)
	MLib:DialogPopup({
		id = "WA_SYNC_RELOAD_UI",
		title = LR["Reload UI Request"],
		text = LR.WASyncReloadPrompt:format(sender or UNKNOWNOBJECT),
		buttons = {
			{
				text = LR["Reload UI"],
				func = ReloadUI,
			},
			{
				text = CANCEL,
			}
		},
		OnUpdate = function(self, elapsed)
			if #module.QueueFrame.queue ~= 0 or module.QueueFrame.ImportedItem then
				module:HideReloadPrompt("WA_SYNC_RELOAD_UI")
				module.QueueFrame.needReload = true
			elseif module.lastAddonMsg and module.lastAddonMsg + 5 > GetTime() then -- actievly accepting data
				self.buttons[1]:SetText(LR["Accepting data"])
				self.buttons[1]:Disable()
				self.buttons[2]:Disable()
			elseif module.lastAddonMsg and module.lastAddonMsg + 8 > GetTime() then -- timeout
				self.buttons[1]:SetText(LR["Reload UI"] .. " (" .. ceil(module.lastAddonMsg + 8 - GetTime()) .. ")")
				self.buttons[1]:Disable()
				self.buttons[2]:Disable()
			else
				self.buttons[1]:SetText(LR["Reload UI"])
				self.buttons[1]:Enable()
				self.buttons[2]:Enable()
			end
		end,
	})
end

function module:HideReloadPrompt()
	MLib:DialogPopupHide("WA_SYNC_RELOAD_UI")
end

function module.main:ADDON_LOADED()
	VMRT.WASync = VMRT.WASync or {}
end
