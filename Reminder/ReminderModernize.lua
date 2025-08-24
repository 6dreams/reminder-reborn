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

function module:Modernize()
	--refactoring bin table
	if VMRT.Reminder.v29 then
		VMRT.Reminder.v29 = nil
		VMRT.Reminder.Version = max(VMRT.Reminder.Version, 29)
	end
   	if VMRT.Reminder.Version < 29 then
		if VMRT.Reminder.removed then
			for i,token in ipairs(VMRT.Reminder.removed) do
				VMRT.Reminder.removed[i] = nil
				VMRT.Reminder.removed[token] = true
			end
		end
	end

	if VMRT.Reminder.v32 then -- what was the lore?
		VMRT.Reminder.v32 = nil
		VMRT.Reminder.Version = max(VMRT.Reminder.Version, 32)
	end

	-- todo remove next xpac
	-- /run VMRT.Reminder.data=VMRT.Reminder.pre_v43;VMRT.Reminder.Version = 0;ReloadUI();

	if VMRT.Reminder.Version < 43 then
		VMRT.Reminder.pre_v43 = VMRT.Reminder.pre_v43 or CopyTable(VMRT.Reminder.data or {}) -- this gets corrupted by the next login after error happened. probably not a big deal?

		local function ParseConditions(data, isTarget)
			local condition = data.condition
			if not condition then
				return
			end
			condition = tostring(condition)
			local unit = isTarget and "target" or "source"
			if condition == "target" or condition == "focus" or condition == "mouseover" or condition:find("^boss") then
				data.triggers[1][unit .. "Unit"] = condition
			elseif tonumber(condition) then
				data.triggers[1][unit .. "Mark"] = tonumber(condition)
			end
		end

		local function ParseCast(data)
			local cast = data.cast -- cast may be either number or string
			if not cast then
				return
			end

			if cast == -2.1 then
				data.triggers[1].counter = "1%2"
			elseif cast == -2.0 then
				data.triggers[1].counter = "2%2"
			elseif cast == -3.1 then
				data.triggers[1].counter = "1%3"
			elseif cast == -3.2 then
				data.triggers[1].counter = "2%3"
			elseif cast == -3.0 then
				data.triggers[1].counter = "3%3"
			elseif cast == -4.11 then
				data.triggers[1].counter = "1%4"
			elseif cast == -4.2 then
				data.triggers[1].counter = "2%4"
			elseif cast == -4.31 then
				data.triggers[1].counter = "3%4"
			elseif cast == -4.0 then
				data.triggers[1].counter = "4%4"
			else
				data.triggers[1].counter = tostring(cast)
			end
		end

		-- dont directly set activeTime, use duration so countdown works properly
		for token,data in next, VMRT.Reminder.data or {} do
			if data.event == "BOSS_START" then
				data.triggers = {
					{
						event = 3,
						delayTime = data.delay,
					}
				}
			elseif data.event == "BOSS_PHASE" then
				data.triggers = {
					{
						event = 2,
						delayTime = data.delay,
						pattFind = tostring(data.spellID),
					}
				}
			elseif data.event == "SPELL_CAST_SUCCESS" then
				data.triggers = {
					{
						event = 1,
						eventCLEU = "SPELL_CAST_SUCCESS",
						spellID = data.spellID,
						delayTime = data.delay,
					}
				}
				ParseConditions(data)
				ParseCast(data)
				if not data.globalCounter then
					data.triggers[1].cbehavior = 1
				end
			elseif data.event == "SPELL_CAST_START" then
				data.triggers = {
					{
						event = 1,
						eventCLEU = "SPELL_CAST_START",
						spellID = data.spellID,
						delayTime = data.delay,
					}
				}
				ParseConditions(data)
				ParseCast(data)
				if not data.globalCounter then
					data.triggers[1].cbehavior = 1
				end

			elseif data.event == "SPELL_AURA_APPLIED" or data.event == "SPELL_AURA_APPLIED_SELF" then
				data.triggers = {
					{
						event = 1,
						eventCLEU = "SPELL_AURA_APPLIED",
						spellID = data.spellID,
						targetUnit = data.event == "SPELL_AURA_APPLIED_SELF" and "player" or nil,
						delayTime = data.delay,
					}
				}
				ParseConditions(data)
				ParseCast(data)
				if not data.globalCounter then
					data.triggers[1].cbehavior = 1
				end
			elseif data.event == "SPELL_AURA_REMOVED" or data.event == "SPELL_AURA_REMOVED_SELF" then
				data.triggers = {
					{
						event = 1,
						eventCLEU = "SPELL_AURA_REMOVED",
						spellID = data.spellID,
						targetUnit = data.event == "SPELL_AURA_REMOVED_SELF" and "player" or nil,
						delayTime = data.delay,
					}
				}
				ParseConditions(data)
				ParseCast(data)
				if not data.globalCounter then
					data.triggers[1].cbehavior = 1
				end
			elseif data.event == "BOSS_HP" then
				data.triggers = {
					{
						event = 4,
						targetUnit = 1, --any boss
						numberPercent = "<" .. (data.spellID or 100),
						delayTime = data.delay,
						counter = "1",
						cbehavior = 2,
					}
				}
				ParseConditions(data,true)
			elseif data.event == "BOSS_MANA" then
				data.triggers = {
					{
						event = 5,
						targetUnit = 1, --any boss
						numberPercent = ">" .. (data.spellID or 0),
						delayTime = data.delay,
						cbehavior = 2,
					}
				}
					ParseConditions(data,true)
					ParseCast(data)
			elseif data.event == "BW_MSG" then
				data.triggers = {
					{
						event = 6,
						spellID = data.spellID,
						delayTime = data.delay,
					}
				}
				ParseCast(data)
			elseif data.event == "BW_TIMER" or data.event == "BW_TIMER_TEXT" then
				data.triggers = {
					{
						event = 7,
						bwtimeleft = tonumber(tostring(data.delay):match("^[^, ]+") or "",10),
					}
				}
				local key = data.event == "BW_TIMER" and "spellID" or "pattFind"
				data.triggers[1][key] = data.spellID
				ParseCast(data)
			end

			--clear old vars
			data.delay = nil -- set in triggers
			data.event = nil
			data.spellID = nil
			data.cast = nil
			data.globalCounter = nil
			data.condition = nil

			-- clear empty strings that could happen due to the bug in sender
			if data.tts == "" then
				data.tts = nil
			end
			if data.glow == "" then
				data.glow = nil
			end
			if data.sendEvent then
				data.WAmsg = data.msg
				data.msg = nil
				data.sendEvent = nil
				if not data.duration then
					data.duration = 2
				end
			end
		end
		if VMRT.Reminder.Glow and VMRT.Reminder.Glow.ColorA then
			local a,r,g,b = VMRT.Reminder.Glow.ColorA,VMRT.Reminder.Glow.ColorR,VMRT.Reminder.Glow.ColorG,VMRT.Reminder.Glow.ColorB
			local color = format("%02x%02x%02x%02x",a*255,r*255,g*255,b*255)
			VMRT.Reminder.Glow.Color = color
			VMRT.Reminder.Glow.ColorA = nil
			VMRT.Reminder.Glow.ColorR = nil
			VMRT.Reminder.Glow.ColorG = nil
			VMRT.Reminder.Glow.ColorB = nil
		end
		if VMRT.Reminder.forceRUlocale then
			VMRT.Reminder.ForceLocale = "ru"
		end
	end

	if VMRT.Reminder.Version < 44 then
		for token,data in next, VMRT.Reminder.removed or {} do
			if type(data) == "table" then
				-- VMRT.Reminder.removed[ token ] = {
				--     time = time(),
				--     boss = data.boss,
				--     name = data.name,
				--     type = type,
				--     token = token,
				-- }
				data.old = true
			elseif type(data) == "boolean" then
				VMRT.Reminder.removed[token] = {old=true,token=token}
			end

		end
	end

	if VMRT.Reminder.Version < 46.3 then
		VMRT.Reminder.BarFont = nil
	end

	if VMRT.Reminder.Version < 47.1 then
		for token,data in next, VMRT.Reminder.data or {} do
			if not data.triggers then
				module:DeleteReminder(data,true,true)
			end
		end
	end

	if VMRT.Reminder.Version < 48 then
		VMRT.Reminder.OptSavedTabNum = nil
	end

	if VMRT.Reminder.Version < 48.3 then
		if ReminderLog and ReminderLog.history then
			local mPlusEntries = {}
			for encID,encTable in next, ReminderLog.history do
				if type(encID) == "number" and encID < 0 then
					local maxDiff
					for diffKey,diffTable in next, encTable do
						if type(diffKey) == "number" then
							if not maxDiff or diffKey > maxDiff then
								maxDiff = diffKey
							end
						end
					end
					for i=1,#encTable[maxDiff] do
						if encTable[maxDiff][i] then
							mPlusEntries[encID] = mPlusEntries[encID] or {encounterID="m+",difficultyID=encID}
							tinsert(mPlusEntries[encID],encTable[maxDiff][i])
						end
					end
					ReminderLog.history[encID] = nil
				end
			end
			if next(mPlusEntries) then
				ReminderLog.history["m+"] = mPlusEntries
			end
		end
	end

	if VMRT.Reminder.Version < 48.4 then
		if ReminderLog and ReminderLog.history then
			for _, encTbl in next, ReminderLog.history do
				for _, diffTbl in next, encTbl do
					for i=1,#diffTbl do
						local entry = diffTbl[i]
						if type(entry) == "table" and type(entry.log) == "string" then
							if entry.pinned and not AddonDB.GetHistoryPinnedState(entry.log) then
								AddonDB.SetHistoryPinnedState(entry.log,true)
							end
						end
					end
				end
			end
		end
	end

	if VMRT.Reminder.Version < 48.5 then
		VMRT.Reminder.TimelineFilter = {}
	end

	if VMRT.Reminder.Version < 49.7 then
		--[[ data in may got to this state if reminders where deleted using data comms with just token sent
		{
			[token] = {
				archived_data = {
					token = token,
					lastSync = lastSync,
				}
			}
		}
		]]
		local function IsDataCorrupted(data)
			for k in next, data do
				if k ~= "token" and k ~= "lastSync" then
					return false
				end
			end
			return true
		end

		for token,data,source in module:IterateAllData() do
			if type(data) ~= "table" or (type(data.triggers) ~= "table" and IsDataCorrupted(data)) then
				source[token] = nil
			end
		end
	end

	-- move all visual settings to VMRT.Reminder.VisualSettings so we can easily maintain profile system
	if VMRT.Reminder.Version < 58 then -- visual settings merge
		if not VMRT.Reminder.VisualSettings then
			-- GetScreenWidth and GetScreenHeight are not available on ADDON_LOADED so we do it here
			C_Timer.After(15, function()
				local textFramePosX, textFramePosY
				if VMRT.Reminder.Left and VMRT.Reminder.Top then
					textFramePosX = VMRT.Reminder.Left + 15 - (GetScreenWidth() / 2)
					textFramePosY = VMRT.Reminder.Top - 15 - (GetScreenHeight() / 2)

					VMRT.Reminder.VisualSettings.Text_PosX = textFramePosX
					VMRT.Reminder.VisualSettings.Text_PosY = textFramePosY
				end

				local barsFramePosX, barsFramePosY
				if VMRT.Reminder.BarsLeft and VMRT.Reminder.BarsTop then
					barsFramePosX = VMRT.Reminder.BarsLeft + 15 - (GetScreenWidth() / 2)
					barsFramePosY = VMRT.Reminder.BarsTop - 15 - (GetScreenHeight() / 2)

					VMRT.Reminder.VisualSettings.Bar_PosX = barsFramePosX
					VMRT.Reminder.VisualSettings.Bar_PosY = barsFramePosY
				end
				module:UpdateVisual()
			end)

			VMRT.Reminder.VisualSettings = {
				Text_Font = VMRT.Reminder.Font,
				Text_FontShadow = VMRT.Reminder.Shadow,
				Text_FontOutlineType = VMRT.Reminder.OutlineType,
				Text_FrameStrata = VMRT.Reminder.FrameStrata,
				Text_JustifyH = VMRT.Reminder.JustifyH, -- could be nil previously
				Text_FontTimerExcluded = VMRT.Reminder.FontTimerExcluded,
				Text_FontSizeBig = VMRT.Reminder.FontSizeBig,
				Text_FontSize = VMRT.Reminder.FontSize,
				Text_FontSizeSmall = VMRT.Reminder.FontSizeSmall,
				Text_PosX = 0,
				Text_PosY = 100,

				Bar_Width = VMRT.Reminder.BarWidth,
				Bar_Height = VMRT.Reminder.BarHeight,
				Bar_Texture = VMRT.Reminder.BarTexture,
				Bar_Font = VMRT.Reminder.BarFont,
				Bar_PosX = 0,
				Bar_PosY = 250,

				Glow = type(VMRT.Reminder.Glow) == "table" and CopyTable(VMRT.Reminder.Glow) or nil,

				TTS_Voice = VMRT.Reminder.ttsVoice,
				TTS_VoiceAlt = VMRT.Reminder.ruTTSVoice or VMRT.Reminder.koTTSVoice, -- ru/kr tts
				TTS_VoiceVolume = VMRT.Reminder.ttsVoiceVolume,
				TTS_VoiceRate = VMRT.Reminder.ttsVoiceRate,
				TTS_IgnoreFiles = VMRT.Reminder.ttsIgnoreFiles,

				NameplateGlow_DefaultType = VMRT.Reminder.NameplateGlowType, -- nil is pixel glow
			}
		end

		-- These fields were removed far ago but here is the last time we ensure they are removed
		VMRT.Reminder.TrueHistory = nil
		VMRT.Reminder.TrueHistoryEnabled = nil
		VMRT.Reminder.TrueHistoryDungeon = nil
		VMRT.Reminder.TrueHistoryDungeonEnabled = nil

		ReminderLog.TrueHistory = nil
		ReminderLog.TrueHistoryEnabled = nil
		ReminderLog.TrueHistoryDungeon = nil
		ReminderLog.TrueHistoryDungeonEnabled = nil
	end

	if VMRT.Reminder.Version < 59 then
		VMRT.Reminder.options = {}

		local keyToBit = {
			locked = "LOCKED",
			disabled = "DISABLED",
			defEnabled = "DEF_ENABLED",
			soundLocked = "SOUND_LOCKED",
			soundDisabled = "SOUND_DISABLED",
		}

		for key, option in next, keyToBit do
			local optionsTable = VMRT.Reminder[key]
			if optionsTable then
				for token, value in next, optionsTable do
					if value == true then
						module:SetDataOption(token, option, true)
					end
				end
			end
		end

		if VMRT.Reminder.DataProfiles then
			for profileKey, profileData in next, VMRT.Reminder.DataProfiles do
				if next(profileData) then -- loaded profile is empty table in DataProfiles
					profileData.options = CopyTable(VMRT.Reminder.options)
				end
			end
		end
	end


	-- for token,data,source in module:IterateAllData() do

	-- end

	-- for visualSettings, profileName, isActive in module:IterateVisualSettings() do
	-- 	print(visualSettings, profileName, isActive)
	-- end

	-- for future versions consider modernizing VMRT.Reminder.removed[token].archived_data
	if VMRT.Reminder.Version < 63 then
		if ReminderLog and ReminderLog.history then
			-- weird events sequence could lead to expected encounterID to be another value
			for k, v in next, ReminderLog.history do
				if type(k) ~= "number" and k ~=	"m+" then
					ReminderLog.history[k] = nil
				end
			end
		end
	end

	if VMRT.Reminder.Version < 65 then
		for token, data in module:IterateAllData() do
			if data.triggers then
				for i, trigger in ipairs(data.triggers) do -- those could be created from timeline module
					if trigger.event == 2 and type(trigger.pattFind) == "number" then
						trigger.pattFind = tostring(trigger.pattFind)
					end
				end
			end
		end
	end


	VMRT.Reminder.Version = max(VMRT.Reminder.Version or 0, AddonDB.Version)
end
