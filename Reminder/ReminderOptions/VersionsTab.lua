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


function options:InitializeVersionsTab()
	local NAME_COL = 1
	local REMINDER_VER_COL = 2
	local MRT_VER_COL = 3
	local BOSSMOD_COL = 4
	local WEAKAURAS_COL = 5
	local RCLC_COL = 6
	local RELEASE_COL = 7

	local EMPTY_VERSION = {}
	local VersionCheckReqSent = {}
	local function UpdateVersionCheck()
		options.VersionUpdateButton:Enable()
		local list = options.VersionCheck.L
		wipe(list)

		list[1] = {
			[NAME_COL] = " |cff9b9b9bName",
			[REMINDER_VER_COL] = "|cff9b9b9bReminder",
			[MRT_VER_COL] = "|cff9b9b9bMRT",
			[BOSSMOD_COL] = "|cff9b9b9bBoss Mod",
			[WEAKAURAS_COL] = "|cff9b9b9bWeakAuras",
			[RCLC_COL] = "|cff9b9b9bRCLC",
			[RELEASE_COL] = "|cff9b9b9bRelease",
			name = "AAAAAAAAAAA",
			ver = 9999,
		}

		for unit in AddonDB:IterateGroupMembers() do
			local name = UnitNameUnmodified(unit)
			local coloredName = AddonDB:ClassColorName(unit)
			local fullName = AddonDB:GetFullName(unit)
			list[#list + 1] = {
				coloredName,
				0,
				name = name,
				fullName = fullName,
				ver = 0,
			}
		end

		-- for i=1,40 do
		--     list[#list + 1] = {
		--         "Name "..i,
		--         0,
		--         name = "Name "..i,
		--         ver = 0,
		--     }
		-- end

		for i=2,#list do
			local playerInfo = list[i]
			---@type versionInfo
			local versionInfo = module.db.gettedVersions[playerInfo.fullName] or EMPTY_VERSION


			if type(versionInfo.Version) == "number" then
				list[i].ver = versionInfo.Version

				local ver, hash, enabled

				if versionInfo.Version == AddonDB.Version then
					ver = "|cff88ff88"..versionInfo.Version
				else
					ver = "|cffffff88"..versionInfo.Version
				end

				if versionInfo.VersionHash == AddonDB.VersionHash then
					hash = "|cff88ff88"..versionInfo.VersionHash
				elseif versionInfo.VersionHash then
					hash = "|cffffff88"..versionInfo.VersionHash
				end

				if versionInfo.Enabled == true then
					enabled = "(|cff88ff88E|r)"
				elseif versionInfo.Enabled == false then
					enabled = "(|cffff8888D|r)"
				end

				list[i][REMINDER_VER_COL] = ver .. " " ..  (hash or "") .. " " .. (enabled or "")

				local bossmod, bm_ver

				if versionInfo.BM == module.ActiveBossMod then
					bossmod = "|cff88ff88" .. versionInfo.BM
				elseif versionInfo.BM then
					bossmod = "|cffffff88" .. versionInfo.BM
				end

				if versionInfo.BMVer == AddonDB:GetBossModVersion() then
					bm_ver = "|cff88ff88"..versionInfo.BMVer
				elseif versionInfo.BMVer then
					bm_ver = "|cffffff88"..versionInfo.BMVer
				end

				list[i][BOSSMOD_COL] = (bossmod or "") .. " " .. (bm_ver or "")


				if versionInfo.Public ~= nil then
					local colorPublic = AddonDB.PUBLIC and "88ff88" or "ffff88"
					local colorPrivate = AddonDB.PUBLIC and "ffff88" or "88ff88"
					list[i][RELEASE_COL] = versionInfo.Public == true and "|cff"..colorPublic.."Public" or versionInfo.Public == false and "|cff"..colorPrivate.."Private"
				end

				if type(versionInfo.MRTVer) == "number" and versionInfo.MRTVer >= MRT.V then
					list[i][MRT_VER_COL] = "|cff88ff88"..versionInfo.MRTVer
				elseif versionInfo.MRTVer then
					list[i][MRT_VER_COL] = "|cffffff88"..versionInfo.MRTVer
				end

				if versionInfo.WAVer == (WeakAuras and WeakAuras.versionString or "?") then
					list[i][WEAKAURAS_COL] = "|cff88ff88"..versionInfo.WAVer
				elseif versionInfo.WAVer then
					list[i][WEAKAURAS_COL] = "|cffffff88"..versionInfo.WAVer
				end

				if versionInfo.RCLCVer == (RCLootCouncil and RCLootCouncil.version:gsub(" ", "") or "?") then
					list[i][RCLC_COL] = "|cff88ff88"..versionInfo.RCLCVer
				elseif versionInfo.RCLCVer then
					list[i][RCLC_COL] = "|cffffff88"..versionInfo.RCLCVer
				end

			elseif VersionCheckReqSent[playerInfo.fullName] then
				if not UnitIsConnected(playerInfo.name) then
					list[i][REMINDER_VER_COL] = "|cff888888offline"
				else
					list[i][REMINDER_VER_COL] = "|cffff8888no addon"
				end
			else
				list[i][REMINDER_VER_COL] = "???"
			end


			if not AddonDB.PUBLIC and AddonDB.RGAPI then
				list[i][NAME_COL] = AddonDB.RGAPI:ClassColorName(playerInfo.name) or list[i][NAME_COL]
				list[i].name = AddonDB.RGAPI:UnitName(playerInfo.name) or list[i].name
			end
			list[i][NAME_COL] = " " .. (list[i][NAME_COL] or "")
			list[i].versionInfo = versionInfo
		end

		sort(list,function(a,b)
			if a.ver ~= b.ver then
				return a.ver > b.ver
			else
				return a.name < b.name
			end
		end)
		options.VersionCheck:Update()

		options.VersionCheck.List[1].HighlightTexture:SetVertexColor(0,0,0,0)
	end


	local tmr
	function module:UpdateVersionCheck()
		if not options:IsVisible() then return end
		if tmr then return end

		tmr = C_Timer.NewTimer(1, function()
			tmr = nil
			UpdateVersionCheck()
		end)
	end

	local verColumns = {
		[NAME_COL] = 0, -- flex
		[REMINDER_VER_COL] = 118,
		[MRT_VER_COL] = 55,
		[BOSSMOD_COL] = 120,
		[WEAKAURAS_COL] = 130,
		[RCLC_COL] = 60,
		[RELEASE_COL] = 70
	}

	local total_size = 755
	if AddonDB.PUBLIC then
		total_size = total_size - verColumns[RELEASE_COL]
		verColumns[RELEASE_COL] = nil
	end

	options.VersionCheck = ELib:ScrollTableList(options.VERSIONS_TAB,unpack(verColumns)):Point(0,-5):Size(total_size,525):HideBorders():OnShow(UpdateVersionCheck,true)
	ELib:DecorationLine(options.VERSIONS_TAB):Point("TOP",options.VersionCheck,"BOTTOM",0,0):Point("LEFT",options):Point("RIGHT",options):Size(0,1)
	options.VersionCheck.LINE_PADDING_LEFT = 7
	options.VersionCheck.LINE_TEXTURE = "Interface\\Addons\\MRT\\media\\White"
	options.VersionCheck.LINE_TEXTURE_IGNOREBLEND = true
	options.VersionCheck.LINE_TEXTURE_COLOR_HL = {1,1,1,.5}
	options.VersionCheck.LINE_TEXTURE_COLOR_P = {1,.82,0,.6}

	options.VersionCheck.Frame.ScrollBar:Size(14,0):Point("TOPRIGHT",0,0):Point("BOTTOMRIGHT",0,0)
	options.VersionCheck.Frame.ScrollBar.thumb:SetHeight(50)

	-- local offset = first_column_size
	-- for i=1,#verColumns-1 do
	--     offset = offset + verColumns[i]
	--     ELib:DecorationLine(options.VersionCheck):Point("TOPLEFT",offset,0):Point("BOTTOMLEFT",offset,0):Size(1,0)
	-- end

	-- to enable hover and click funcs
	options.VersionCheck.additionalLineFunctions = true

	function options.VersionCheck:ClickMultitableListValue(index, obj)
		local data = obj:GetParent().table
		if not data then return end

		local versionInfo = data.versionInfo
		if not versionInfo then return end

		if type(versionInfo.Version) == "number" and versionInfo.Version < AddonDB.Version then
			AddonDB:SendComm("VERSION_OUTDATED_NOTIFICATION_FORCE", AddonDB:CreateHeader(AddonDB.Version), "WHISPER", data.fullName)
			module.prettyPrint("Sent!", AddonDB.Version, versionInfo.Version, data.fullName)
		end
	end



	options.VersionUpdateButton = MLib:Button(options.VersionCheck,UPDATE,12):Point("TOPLEFT",options.VersionCheck,"BOTTOMLEFT",5,-5):Size(100,20):Tooltip(L.OptionsUpdateVerTooltip):OnClick(function()
		module.db.getVersion = GetTime()
		wipe(module.db.gettedVersions)
		UpdateVersionCheck()
		module:RequestVersion()

		for unit in AddonDB:IterateGroupMembers() do
			local fullName = AddonDB:GetFullName(unit)
			VersionCheckReqSent[fullName] = true
		end
		local list = options.VersionCheck.L
		for i=2,#list do
			list[i][REMINDER_VER_COL] = "..."
		end
		options.VersionCheck:Update()
		options.VersionUpdateButton:Disable()
	end)
	options.VersionUpdateButton:SetFrameStrata("DIALOG")
end
