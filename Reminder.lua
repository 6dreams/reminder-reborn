local GlobalAddonName, ExRT = ...

G_ExRT = ExRT;

local ELib,L = ExRT.lib,ExRT.L

local LR = setmetatable({}, {__index=function (t, k)
	-- if not ExRT.LR[k] then print("Missing locale for:"..k) end
	return ExRT.LR[k] or k
end})



local module = ExRT:New("Reminder","|cffff8000Reminder|r",nil,true)
if not module then return end

local GetSpellInfo = function (...)
  local data = C_Spell.GetSpellInfo(...);
  
  if data == nil then
    return nil
  end
  
  --local iconID, originalIconID = C_Spell.GetSpellTexture(spellIdentifier);
  
  -- name, rank, icon, castTime, minRange, maxRange, spellID, originalIcon
  return data.name, nil, data.iconID, data.castTime, data.minRange, data.maxRange, data.spellID, data.originalIconID
end

local LibDeflate = LibStub:GetLibrary("LibDeflate")
local LCG = LibStub("LibCustomGlow-1.0")
local LGF = LibStub("LibGetFrame-1.0")
local LGFNullOpt = {}

local VExRT = nil
local ReminderLog = nil

local GetInstanceInfo, UnitGroupRolesAssigned, UnitPowerMax = GetInstanceInfo, UnitGroupRolesAssigned, UnitPowerMax
local GetSpecialization, tonumber, floor, UnitGUID, C_Timer = GetSpecialization, tonumber, floor, UnitGUID, C_Timer
local UnitHealthMax, UnitHealth, string_gmatch, PlaySoundFile = UnitHealthMax, UnitHealth, string.gmatch, PlaySoundFile
local ScheduleTimer, pairs, bit_band = ExRT.F.ScheduleTimer, pairs, bit.band


local SENDER_VERSION = 3
local DATA_VERSION = 33

--[[
-- TODO FOR NEXT PATCH
Обновить TOC для ретейла

-- TODO FOR FUTURE
Переделать отправку ВАшек, всегда перезаписывать существующие вашки, оставляя старыми предопределенные поля если не полный апдейт
Вынести весь UI в отдельный файл 14к строк is too much
Refactor ChatSpams
Добавить шаблоны
Расширить andor для триггеров

-- TODO FOR NEXT EXPANSION
Удалить все говно связанное со старыми ремайндером?(но нахуя...)

-- TODO FOR PUBLIC RELEASE
Убрать бигвигс модуль
Убрать лишние медиа файлы из папок
Убрать лишние медиа строки из ВА модуля

-- KNOWN ISSUES
* NoteAnalyzer: Sending note through NoteAnalyzer may sometimes result in sending incomplete note

]]

local changelog = [=[
|cff88ff88 v.33
* Added indicator which shows reminder's difficulty
* Added sorting by difficulty in Reminders tab
* Added option for voice countdowns(only if reminder has specified duration(not trigger))
* Load by note pattern will no longer ignore load by role/class/names
* WASync: Added button to skip update
* WASync: Added possibility to send WA to specific player(only if players in same guild)
* RaidLockuts: Added Amirdrassil
* Fixes
|r
|cff88ff88 v.32.2
* Added new media images
|r
|cff88ff88 v.32.1
* NoteAnalyzer: Strictness checkboxes will now be saved between sessions
* WASync: Improved queue system
* Personal disable icon will now be desaturated if reminder is disabled
* Fixes
|r
|cff88ff88 v.32
|cffff0000** UPDATED SENDER VERSION TO 3. OLD IMPORT STRINGS WILL NO LONGER WORK.|r
  - This means that users who have older versions of the addon will not be able to accept or send reminders to the updated users.
** Improved data compression by roughly 20-25%
  - Classes, roles and true/false values are now sended in bit arrays
  - Events are now sended as numbers instead of strings
  - Sound paths are now partially encoded
  - Sender version in import string is now first string of exported data
* Added boss portaits for DF dungeons
* Added option to disable reminder which is transmitted when sending reminders
  - Reminders disabled this way will be colored gray in the list
* Adjusted colors in reminder list
* Fixes
|r
 v.31.1
* Fixes

 v.31
** Reworked Remidner Setup Frame
* Added option to disable load on boss fight for specific reminders
* Added slash command '/rt ra' to open Raid Analyzer
* Added option to set extra conditions to activate reminder
* Added option to set custom reminder's GUID
* Added option attach glow/textures to nameplate by reminder's GUID
* RaidAnalyzer: Added Group Invites module to invite players from other factions
* WASync: Added estimated time to send WA
* Fixes

 v.30
* Added advanced trigger to check raid group number
* NoteAnalyzer: Module renamed to Raid Analyzer
* NoteAnalyzer: Added possibility to backup last 5 notes
* RaidAnalyzer: Added possibility to check raid lockouts for players in raid

 v.29.4
* Fixes

 v.29.3
* Added search
* Added possibility to load reminder by zone ID
* Added 'self' chat channel for spam reminders
* Added new replacer {setparam:key:value} which sets local variable for current reminder
  - Can be called later with {#key}
* Raidframe glow now fully supports text replacers
* WASync: added import queue
* NoteAnalyzer: added checkboxes to select how strict name patterns may be
* NoteAnalyzer: improved search logic
* Fixes

 v.29.2
* Removed /rt cnote
* English Text to Speech voice will now translit russian words
* Added possibility to check last update time for specific reminder(may require additional testing)
* Added checkbox to force ru localization for eu clients
* Added right click menu when interacting with boss specific lines
  - Only option for now is: export all reminders for current boss
* Localization updates
* Fixes

 v.29.1
* Added reminder summary when mouseovering line in list
* Fixes

 v.29
* Added Note Analyzer module to check if players are assigned in note and quickly replace them
* Reminders list rework
* Added UI to inspect 'removed list'
* Added new frame glow type - 'proc glow'(looks insanly good)
* Added option to mute sound for specific reminder, this option will not be sended with reminder
* Added buttons to move triggers position
* Added summary output to chat when accepting reminder data
* Added new history event 'NEW UNIT'
* Improved history click logic to work with advanced triggers
  - line 1 setup boss id and diff id
  - column 1 setup event
  - if line is phase specific it will set phase settings
  - column 2 setup spell id
  - column 3 setup spell id and counter
  - column 4 setup boss pull event with specified delay
  - column 5 setup boss phase event with specified delay
  - column 6 setup combat log event with timer from last cast of this ability
  - column 7 setup source name
  - column 8 setup target name
* Fixes

v.28.7
* Fixes

v.28.6
* Added encounters from Icecrown Citadel for Classic
* UI updates
* Added additional options for Reminders
  - Disable dynamic updates(reminder replacers will not update after reminder is shown)
  - Stop rewriting(If reminder activates while already active it will not be rewrited)
  - Allow duplicates(If reminder activates while already active it will be shown on next line, as old reminders do)
  - Do not send this reminder(Makes reminder personal, so it cant be sended to other people)
* Localization updates
* Major fixes

v.28.5
* More tooltips for advanced triggers
* Setting tab revamp
* Added possibility to choose how to align text reminders
* Added possibility to disable history completely
* Localization updates
* Fixes

v.28.4
* Fixes

v.28.3
* Fixes

v.28.2
* Added slash command which checks if players are assigned in Note
  - /rt cnote startline endline maxGroup
  - It checks if players from groups 1-maxGroup are found in note from startline to endline
  - e.g. /rt cnote 1 3 6 will search from 1st to 3rd note lines and check if players from groups 1-6 are found in Note
* Added Unit Health and Unit Energy to advanced triggers
* Added advanced Unit Absorb trigger
* Added advanced Aura trigger
* Added advanced 'Unit Target' trigger
* Added advanced Spell Cooldown trigger
* Added advanced 'New Boss Frame' triggers
* Added advanced BigWigs/DBM Message and Timers triggers
* Added advanced Boss Pull and Boss Phase triggers
* Added advanced Chat Message trigger
* Introducing concept of triggers that can be 'untimed'
  - If the trigger is untimed, this means that if no active duration is specified for the trigger it will be active until canceled
  - Untimed triggers are: Boss Phase, Unit Health, Energy, Absorb, Aura, Target, Aura and Spell CD
* Glow and Chat spam can now be 'untimed', so if duration is 0 glow and chat spam will be active while reminder is active
* Chat spam can now be formated the same way as message
* Fixed replacers' names for some advanced trigger replacers
* Added tooltips for extra spell id in advanced triggers

v.28.1
* Added to base replacers:
  - Spell icon
  - Class Color
  - Role Icon
* Removed dummy text between 'closer' replacers

v.28
* Introducing new ADVANCED event type with WA'ish triggers system
  - Have only combat log events now, more to come
* Added Trial of the Crusader encounters for Classic
* Updates and fixes for WeakAuras Sync module
* Fixed sending reminders with "spam message" but without default message
* Fixed Lib Custom Glow erorr(probably not)
* Fixed issue when Save button was disabled when reminder has Send Custom Event and no duration
* Fixed issue with reminder data being corrupted when NaN is present in import string
  - Added a chat alert when importing string with NaN
  - Added a popup dialog when importing string with NaN
* Added popup confirmation dialogs when clear importing and deleting all reminders
* Added possibility to choose countdown format
* Added 'Delete All Removed' and 'Clear Removed' buttons
  - When deleting a reminder with shift key down this reminder goes to 'remove list'
  - 'Delete All Removed' deletes all reminders from 'remove list',
  - If you are raid leader or assistant reminders will be deleted for other people
  - 'Clear Removed' resets 'remove list'
* Added guide for new conditions and counter types to Help tab
* Insane amount of new text substitution patterns
  - Accessible through drop down under message edit
* Added PARTY and RAID options for spam channel
* Removed '*' shwoing reminder status (Sended/Duplicated) in the end of the line
  - Duplicate, Export and Send buttons' text color and tooltip now represents reminder status
* Starting new chat spam will now stop old chat spam
* Added possibility to set more than 1 glow at a time
  - Separate names with comma
* Added possibility to load reminder by classes
* Reworked Reminder Edit UI
* Extended tooltip for Note Pattern
* Delay time may now be set in MM:SS.MS format

v.27.2
* Reworked function which shows text on screen
  - The number of reminders that can be displayed at the same time is now unlimited
* Added possibility to show count in message with {counter}

v.27.1
* Added possibility to setup glow dynamically on cast's or aura's target
  - Use {destName} instead of player name
* Added %classColor Nickname formatting for message
  - example: %classColor Mishok will format into |cFFC69B6DMishok|r

v.27
* Added possibility to setup spam to chat during reminder

v.26.3
* Code improvements
* Added possibility to set custom cast number
  - Can have multiple values separated by a comma

v.26.2
* Added checkbox "Reverse load by Custom Players string and names checkboxes"
* Rhealer/Mhealer roles check fix
* Potential "constant table overflow" fix
* Decreased maximum amount of recorded pulls to 12
* Reminders activated when 3 reminders were already active will be omitted
* Reminders now can't be deleted by other players if you have "Locked" them

v.26.1
* Font fix

v.26
* Added possibility to setup glow on raidframes during reminder
* Added Versions tab
* Removed /rt rem ver command
* UI update
* WA Sync module enabled

v.25
* Added Text To Speech feature
* Settings tab has got some changes ^_^

v.24.2
* Reminder version check now have colors represeting is addon updated
* Added button "Send All For This Boss"
* Fixed error when sending reminders without duration with Send All button

v.24.1
* Added possibility to include arguments with custom addon events
  - For example message RELOE_CD_TRIGGER 1022 Watest BoP 135964 1
    will fire event RELOE_CD_TRIGGER with 1022 as first arg Watest as second arg etc.
  - It will automatically convert strings to 'number' type if possible

v.24
* Added possibility to send custom addon events instead of showing message on the screen
  - You can catch this with WeakAuras custom trigger

v.23
* Added separate history for dungeons
  - Turned off by default
  - You can toogle between raid and dungeon history with button under recorded pulls

v.22.2
* Added slash commands to open reminder
  - /rt rem or /rt r
* Added output EncounterID checkbox
* First line in history will now show boss name, bossID and difficultyID
  - Clicking this line will set boss id

v.22.1
* Added possibility to set custom encounter and difficulty ID

v.22
* Added BigWigs and DBM Timer by text event
  - Added for cases when timer don't have any ID e.g. M Jailer Hearth of Azeroth soak
  - It searches for exact text on a bar so be carefull when setting this up
  - Avoid using it if possible(pls)

v.21.2
* Fixed issue when import window didn't have import button

v.21.1
* Updatec ToC and added icon for addon

v.21
* Added module WeakAuras_Sync(disabled for now)

v.20
* Added output to chat when raid leader or assistant deletes reminder
* Added possibility to choose limit of recorded pulls
  - Added warning to checkbox for recording pulls
* Added English localization
* Improved DBM compability
  - Added support for situations when bar stops before expiration
  - Requires additional testing
* Reminder's duration can now be a decimal

v.19.7
* Добавлены опции выбора ролей для мили и ренж хилов
  - Мили хилы это паладины и монки
* Очистка кода

v.19.6
* Небольшие фиксы отправки ремайндеров
  - Звездочки теперь работают как должны
* Теперь запись истории пуллов идет только в рейдовой группе
* Теперь цвет текста кнопок выбора пуллов для окна быстрой настройки
меняеться в зависимости от успешности боя с боссом
  - Красный текст означает что бой закончился вайпом
  - Зеленый текст означает что бой закончился киллом
  - Старые данные изначально будут считаться киллом

v.19.5
* Изменен формат текста на кнопках выбора пуллов для окна быстрой настройки
* Добавлены подсказки к кнопкам выбора пуллов для окна быстрой настройки
  - Изначальное отображение старых данных может быть немного кривым

v.19.4
* Теперь пуллы в историю добавляються только если время боя с боссом было больше 30 секунд

v.19.3
* Множество фиксов окна быстрой настройки
  - Пофикшен чекбокс "Добавить события аур"
  - Пофикшен чекбокс "Все события(игнорировать текущее)"
  - Пофикшено обновление окна быстрой настройки при выборе события для ремайндера
* Обновлена вкладка внешний вид
  - Добавлена возможность выбрать слой

v.19.2
* Теперь в окне быстрой настройки "Время с предыдущего такого же события"
отображаеться в десятичном формате
* В окне быстрой настройки при нажатии на значении из столбца "Время с начала фазы"
теперь выставляеться значение таймера фазы а не таймера пула
* Добавлен чекбокс в окне настройки ремайндера позволяющий
выключить окно быстрой настройки
* Вкладка помощь дополнена

v.19.1
* Множество фиксов для WotLK Classic

v.19
* Добавлена функция записи истории пуллов для окна быстрой настройки
  - Максимально в памяти может храниться до 12 пулов

v.18
* Добавлена поддержка WotLK Classic

v.17.2
* Список №каста дополнен условиями с 21 до 99

v.17.1
* Пофикшена ситуация когда событие первой фазы в начале пула прокало 2 раза

v.17
* Добавлена первоначальная поддержка DBM
  - Работают таймеры, сообщения и фазы
  - Номера фаз у пользователей BigWigs и DBM могут различаться
  - Нет поддержки ситуаций когда таймер останавливаеться
    и после возобновляеться(например как на Лордах Ужаса или Совете Крови)
* С помощью команды /rt rem ver можно узнать использует игрок BigWigs или DBM
  - Однако для этого рекомендуеться использовать /bwv или аналогичную команду из DBM
* Пофикшена ошибка появляющаяся когда таймер BigWigs изначально появлялся с
таймером меньшим чем задержка(показать через, с.) ремайндера
* В окне истории событий теперь отображаеться номер повторения фазы
  - Может быть полезно в будующем на боссе типа Курога где идут фазы 1,2,1,2,3
* Окно единичного экспорта теперь может выходить за рамки экрана

v.16.1
* Теперь напротив дублированых неотправленных ремайндеров будет отображаться
оранжевая звездочка, напротив оригинальных неотправленных белая
* В подсказке к кнопкам Удалить, Отправить и Экспорт отображаеться ID ремайндера
  - Если вы дублировали ремайндер у него будет новый ID отличный от оригинального
  - Если вы создаете новый ремайндер дублируя старый рекомендуеться вносить
    изменения в дублированный.
  - В случае если вы отправляете ремайндеры по одному(с помощью новой функции) и при создании
    ремайндера вы использовали дублирование и внесли изменения в оригинальный а
    не дублированный то отправленный ремайндер перезапишет
    оригинальный т.к. у него будет тот же ID
* Теперь с помощью /rt rem ver можно узнать включен ли
у игроков ремайндер(*галочка сверху справа)

v.16
* Добавлены кнопки Отправить и Экспорт для каждого ремайндера
  - Можно нажимать кнопку Экспорт на разных ремайндерах и пошагово добавлять их в окно экспорта

v.15.1
* Добавлена возможность выбирать различные типы контуров шрифта
* Добавлена возможность включить\выключить тень шрифта

v.15
* Добавлена команда /rt rem ver позволяющая узнать версию ремайндера игроков в группе
  - Будет писать в чат список ников и верcию аддона, если у игроков нет аддона или
	его версия младше 15 то список их ников будет выделен |cffff0000красным|r
* Добавлена вкладка Помощь.
* Добавлены кнопки Center By X и Center By Y во вкладке внешний вид

v.14
* Теперь может отображаться до трех ремайндеров одновременно
  - В ситуации когда 3 ремайндера активно 4й будет перезаписывать первую строку
* Небольшая полировка кода

v.13
* Добавлена вкладка Changelog
* Переработан способ получения информации о фазах
  - Теперь можно использовать фазы с дробным числом по типу 1.5
  - Все еще нет поддержки DBM, работает только с BigWigs
* Пофикшена ошибка связанная со spellTexture,
из-за которой иногда не получалось сохранять настройки ремайндеров
* Добавлена возможность включать и выключать контур шрифта

v.12
* Пофикшены условия кастов "каждый 4 [1,5,9,13] и "каждый 4 [3,7,11,15]
* Добавлен контур(OUTLINE) текста
* Добавлена возможность переносить текст на следующую строку с помощью \n в сообщении
  -  Например text1 \ntext2 будет выглядеть как:
    text1
    text2
]=]



local frame = CreateFrame('Frame',nil,UIParent)
frame:SetSize(30,30)
frame:SetPoint("CENTER",UIParent,"TOP",0,-100)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self)
	if self:IsMovable() then
		self:StartMoving()
	end
end)
frame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
	VExRT.Reminder.Left = self:GetLeft()
	VExRT.Reminder.Top = self:GetTop()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Reminder.Left,VExRT.Reminder.Top)
end)


frame.text1 = frame:CreateFontString(nil,"ARTWORK")
frame.text1:SetPoint("TOP")
frame.text1:SetFont(ExRT.F.defFont, 40, "OUTLINE, OUTLINE")
frame.text1:SetShadowOffset(0,0)
frame.text1:SetTextColor(1,1,1,1)
frame.text1:SetText("Test\nTest\nTest")

local ChatSpamTimers = {}

frame.dot = frame:CreateTexture(nil, "BACKGROUND",nil,-6)
frame.dot:SetTexture("Interface\\AddOns\\MRT\\media\\circle256")
frame.dot:SetAllPoints()
frame.dot:SetVertexColor(1,0,0,1)

frame:Hide()
frame.dot:Hide()

local FlagMarkToIndex = {
	[0] = 0,
	[0x1] = 1,
	[0x2] = 2,
	[0x4] = 3,
	[0x8] = 4,
	[0x10] = 5,
	[0x20] = 6,
	[0x40] = 7,
	[0x80] = 8,
	[0x100] = 9,
	[0x200] = 10,
	[0x400] = 11,
	[0x800] = 12,
	[0x1000] = 13,
	[0x2000] = 14,
	[0x4000] = 15,
	[0x8000] = 16,
	[0x10000] = 17,
	[0x20000] = 18,
}

local oldBWFrame = CreateFrame("Frame")
local CLEU_SPELL_CAST_SUCCESS = {}
local CLEU_SPELL_CAST_START = {}
local CLEU_BOSS_PHASE = {}
local CLEU_BOSS_START = {}
local CLEU_BOSS_HP = {}
local CLEU_BOSS_MANA = {}
local CLEU_BW_MSG = {}
local CLEU_BW_TIMER = {}
local CLEU_SPELL_AURA_APPLIED = {}
local CLEU_SPELL_AURA_REMOVED = {}
local CLEU_SPELL_AURA_APPLIED_SELF = {}
local CLEU_SPELL_AURA_REMOVED_SELF = {}

local CastNumbers_SUCCESS = {}
local CastNumbers_START = {}
local CastNumbers_PHASE = {}
local CastNumbers_HP = {}
local CastNumbers_MANA,CastNumbers_MANA2 = {},{}
local CastNumbers_BW_MSG = {}
local CastNumbers_BW_TIMER = {}
local CastNumbers_AURA_APPLIED = {}
local CastNumbers_AURA_REMOVED = {}
local CastNumbers_AURA_APPLIED_SELF = {}
local CastNumbers_AURA_REMOVED_SELF = {}

local ChatSpamUntimed = {}
module.db.ChatSpamUntimed = ChatSpamUntimed
local GlowCancelTimers = {}
module.db.GlowCancelTimers = GlowCancelTimers

module.db.nameplateFrames = {}
module.db.nameplateHL = {}
module.db.nameplateGUIDToFrames = {}
module.db.nameplateGUIDToUnit = {}


module.db.debug = false
module.db.timers = {}
module.db.reminders = {}
local reminders = module.db.reminders
local sReminders = {}
module.db.showedReminders = sReminders
local eventsUsed, unitsUsed = {}, {}
local nameplateUsed

module.db.eventsToTriggers = {}
local tCOMBAT_LOG_EVENT_UNFILTERED, tUNIT_HEALTH, tUNIT_POWER_FREQUENT, tUNIT_ABSORB_AMOUNT_CHANGED, tUNIT_AURA, tUNIT_TARGET, tUNIT_SPELLCAST_SUCCEEDED, tUNIT_CAST

module.db.CLEU_SPELL_CAST_SUCCESS = CLEU_SPELL_CAST_SUCCESS
module.db.CLEU_SPELL_CAST_START = CLEU_SPELL_CAST_START
module.db.CLEU_BOSS_PHASE = CLEU_BOSS_PHASE
module.db.CLEU_BOSS_START = CLEU_BOSS_START
module.db.CLEU_BOSS_HP = CLEU_BOSS_HP
module.db.CLEU_BOSS_MANA = CLEU_BOSS_MANA
module.db.CLEU_BW_MSG = CLEU_BW_MSG
module.db.CLEU_BW_TIMER = CLEU_BW_TIMER
module.db.CLEU_SPELL_AURA_APPLIED = CLEU_SPELL_AURA_APPLIED
module.db.CLEU_SPELL_AURA_REMOVED = CLEU_SPELL_AURA_REMOVED
module.db.CLEU_SPELL_AURA_APPLIED_SELF = CLEU_SPELL_AURA_APPLIED_SELF
module.db.CLEU_SPELL_AURA_REMOVED_SELF = CLEU_SPELL_AURA_REMOVED_SELF

local tabFont,tabFontSize,TabFontOutline = GameFontNormal:GetFont()

function ELib:mStyledButton(parent,text,textSize)
    if not textSize then textSize = 13 end
    local button =  ELib:Button(parent,text)
    button.Texture:SetGradient("VERTICAL",CreateColor(0.12,0.12,0.12,1), CreateColor(0.14,0.14,0.14,1))--:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0.8), CreateColor(0.15,0.15,0.15,0.8))
    button:GetFontString():SetFont(tabFont, textSize, "OUTLINE")
    return button
end

local LastUpdateTimeByThisSender = {}
local currentTrueHistory
local UpdateHistory
local isExportOpen = false
local ActiveBossMod = " N/A"
local frameStrataList = {"BACKGROUND","LOW","MEDIUM","HIGH","DIALOG","FULLSCREEN","FULLSCREEN_DIALOG","TOOLTIP"}
local font_flags = {
	{ "",                         LR.OutlinesNone },
	{ "OUTLINE",                  LR.OutlinesNormal },
	{ "THICKOUTLINE",             LR.OutlinesThick },
	{ "MONOCHROME",               LR.OutlinesMono },
	{ "MONOCHROME, OUTLINE",      LR.OutlinesMonoNormal },
	{ "MONOCHROME, THICKOUTLINE", LR.OutlinesMonoThick },
}


local ttsVoices = C_VoiceChat.GetTtsVoices()
local isTtsTranslateNeeded = false

local glowList = LCG.glowList
-- local glowStart = LCG.startList
-- local glowStop = LCG.stopList

local lastHistory = 0
local stopHistory = true
local history = {}
module.db.history = history

local ActiveEncounter = nil
local ActiveEncounterStart = nil
local ActivePhase = 0
local ActiveDelays = {}

local CombatStartTimer
local CombatStartDate
local throttleTimer
local NameByID
local CLEU = CreateFrame("Frame")

local RawData

local gsub_trigger_params_now
local gsub_trigger_update_req

local function GetMRTNoteLines()
	return {strsplit("\n", VExRT.Note.Text1..(VExRT.Note.SelfText and "\n"..VExRT.Note.SelfText or ""))}
end

local defCDList = {
	DRUID = 22812,
	SHAMAN = 108271,
	WARLOCK = 104773,
	MONK = 115203,
	MAGE = 55342,
	DEMONHUNTER = 198589,
	DEATHKNIGHT = 48792,
	PRIEST = 19236,
	HUNTER = 281195,
	PALADIN = 498,
	WARRIOR = 184364,
	ROGUE = 1966,
	EVOKER = 363916,
}

local defSpecName = {
	[62] = "arcane",
	[63] = "fire",
	[64] = "frost",
	[65] = "holy",
	[66] = "protection",
	[70] = "retribution",
	[71] = "arms",
	[72] = "fury",
	[73] = "protection",
	[74] = "ferocity",
	[79] = "cunning",
	[81] = "tenacity",
	[102] = "balance",
	[103] = "feral",
	[104] = "guardian",
	[105] = "restoration",
	[250] = "blood",
	[251] = "frost",
	[252] = "unholy",
	[253] = "beast mastery",
	[254] = "marksmanship",
	[255] = "survival",
	[256] = "discipline",
	[257] = "holy",
	[258] = "shadow",
	[259] = "assassination",
	[260] = "outlaw",
	[261] = "subtlety",
	[262] = "elemental",
	[263] = "enhancement",
	[264] = "restoration",
	[265] = "affliction",
	[266] = "demonology",
	[267] = "destruction",
	[268] = "brewmaster",
	[269] = "windwalker",
	[270] = "mistweaver",
	[535] = "ferocity",
	[536] = "cunning",
	[537] = "tenacity",
	[577] = "havoc",
	[581] = "vengeance",
	[1467] = "devastation",
	[1468] = "preservation",
	[1473] = "augmentation"
}

local damageImmuneCDList = {
	MAGE = 45438,
	HUNTER = 186265,
	PALADIN = 642,
	ROGUE = 31224,
	DEMONHUNTER = 196555,
}

local sprintCDList = {
	DRUID = 106898,
	SHAMAN = 192077,
	MONK = 116841,
	EVOKER = 374968,
}

local healCDList = {
	[65] = 317223,
	[257] = 64844,
	[264] = 108280,
	[270] = 115310,
	[105] = 157982,
	[1468] = 363534,
}

local raidCDList = {
	[65] = 31821,
	[66] = 204018,
	[256] = 62618,
	[264] = 98008,
	[71] = 97463,
	[72] = 97463,
	[73] = 97463,
	[577] = 196718,
	[250] = 51052,
	[251] = 51052,
	[252] = 51052,
}

local function GSUB_NumCondition(num,str)
	num = tonumber(num)
	if not num or num == 0 then
		return ""
	end
	return select(num,strsplit(";",str or "")) or ""
end

local function GSUB_Icon(str)
	local spellID,iconSize = strsplit(":",str)
	spellID = tonumber(spellID)
	if spellID then
		local _,_,spellTexture = GetSpellInfo( spellID )
		if not iconSize or iconSize == "" then
			iconSize = 0
		end
		return "|T"..(spellTexture or "134400")..":"..iconSize.."|t"
	end
end

local function GSUB_Upper(_,str)
	return (str or ""):upper()
end

local function GSUB_Lower(_,str)
	return (str or ""):lower()
end

local function GSUB_ModNextWord(str)
	if str:find("^specIconAndClassColor") then
		local name = str:match("^specIconAndClassColor *(.-)$")
		if name then
			local mod = name
			local class = select(2,UnitClass(name))
			if class and RAID_CLASS_COLORS[class] then
				mod = "|c"..RAID_CLASS_COLORS[class].colorStr..mod.."|r"
			end
			local role = UnitGroupRolesAssigned(name)
			if role == "TANK" then
				mod = "|A:groupfinder-icon-role-large-tank:0:0|a"..mod
			elseif role == "DAMAGER" then
				mod = "|A:groupfinder-icon-role-large-dps:0:0|a"..mod
			elseif role == "HEALER" then
				mod = "|A:groupfinder-icon-role-large-heal:0:0|a"..mod
			end
			return mod
		else
			return ""
		end
	elseif str:find("^specIcon") then
		local name = str:match("^specIcon *(.-)$")

		if name then
			local role = UnitGroupRolesAssigned(name)
			if role == "TANK" then
				return "|A:groupfinder-icon-role-large-tank:0:0|a"..name
			elseif role == "DAMAGER" then
				return "|A:groupfinder-icon-role-large-dps:0:0|a"..name
			elseif role == "HEALER" then
				return "|A:groupfinder-icon-role-large-heal:0:0|a"..name
			else
				return name
			end
		else
			return ""
		end
	elseif str:find("^classColor") then
		local name = str:match("^classColor *(.-)$")
		if name then
			local class = select(2,UnitClass(name))
			if class and RAID_CLASS_COLORS[class] then
				return "|c"..RAID_CLASS_COLORS[class].colorStr..name.."|r"
			end
			return name
		else
			return ""
		end
	end
end

local GSUB_Math
do
	local setfenv = setfenv
	GSUB_Math = function(line)
		local c,lastChar = line:match("^([%d%.%+%-/%*%(%)%%%^]+)([rfc]?)$")
		if c then
			local func, error = loadstring("return "..c)
			if func then
				setfenv(func, {})
				local isFine, res = pcall(func)
				if type(res) == "number" then
					if lastChar == "r" then
						return tostring(floor(res+0.5))
					elseif lastChar == "f" then
						return tostring(floor(res))
					elseif lastChar == "c" then
						return tostring(ceil(res))
					else
						return tostring(res)
					end
				end
			end
		else
			local isHex,hexBase,str = line:match("^(hex):(%d-):?([^:]+)$")
			if isHex == "hex" then
				if hexBase == "" then hexBase = 16 end
				str = str:match("[0-9A-Za-z]+$")
				if str then
					local res = tonumber(str,tonumber(hexBase))
					if res then
						return tostring(res)
					end
				end
			end
		end
		return "0"
	end
end

local function GSUB_Repeat(num,line)
	return (line or ""):rep(min(100,tonumber(num) or 0))
end

local function GSUB_Length(num,line)
	local res = ExRT.F.utf8sub(line or "", 1, tonumber(num) or 0)
	if res:find("|c.?.?.?.?.?.?.?.?$") then
		res = res:gsub("|c.?.?.?.?.?.?.?.?$","")
	end
	return res
end

local function GSUB_None()
	return ""
end

local function GSUB_ExRTNote(patt)
	patt = "^"..patt:gsub("%%","%%%%"):gsub("[%-%.%+%*%(%)%$%[%?%^]","%%%1")
	if VExRT and VExRT.Note and VExRT.Note.Text1 then
		local lines = GetMRTNoteLines()
		for i=1,#lines do
			if lines[i]:find(patt) then
				return lines[i]
			end
		end
	end
	return ""
end

local function GSUB_ExRTNoteList(str)
	local pos,patt = strsplit(":",str,2)
	patt = "^"..(patt or ""):gsub("%%","%%%%"):gsub("[%-%.%+%*%(%)%$]","%%%1")
	if VExRT and VExRT.Note and VExRT.Note.Text1 and tonumber(pos) then
		local lines = GetMRTNoteLines()
		for i=1,#lines do
			if lines[i]:find(patt) then
				pos = tonumber(pos)
				local line = lines[i]:gsub(patt,""):gsub("|c........",""):gsub("|r",""):gsub("%b{}",""):gsub("|",""):gsub(" +"," "):trim()
				local u,uc = {},0
				line = line:gsub("%b()",function(a)
					uc = uc + 1
					u[uc] = a:sub(2,-2)
					return "##"..uc
				end)
				local allpos = {strsplit(" ", line)}
				pos = pos % #allpos
				if pos == 0 then pos = #allpos end
				local res = allpos[pos]
				if not res then
					return ""
				end
				if res:find("^##%d+$") then
					local c = res:match("^##(%d+)$")
					res = u[tonumber(c)]
					res = res:gsub(" ",";")
				end
				return res
			end
		end
	end
	return ""
end

local function GSUB_Min(line)
	local m
	for c in string_gmatch(line, "[^;,]+") do
		c = tonumber(c)
		if c and (not m or c < m) then
			m = c
		end
	end
	return m or ""
end

local function GSUB_Max(line)
	local m
	for c in string_gmatch(line, "[^;,]+") do
		c = tonumber(c)
		if c and (not m or c > m) then
			m = c
		end
	end
	return m or ""
end

local function GSUB_Status(str)
	gsub_trigger_update_req = true
	if gsub_trigger_params_now and gsub_trigger_params_now._reminder then
		local triggerNum,uid = strsplit(":",str,2)

		triggerNum = tonumber(triggerNum) or 0
		local trigger = gsub_trigger_params_now._reminder.triggers[triggerNum]
		uid = tonumber(uid) or uid or ""
		if trigger and trigger.active and trigger.active[uid] then
			return "on"
		end
	end
	return "off"
end

local function GSUB_YesNoCondition(condition,str)
	local res = 1
	local pnow = 1
	local isORnow = false
	while true do
		local andps,andpe = condition:find(" AND ",pnow)
		local orps,orpe = condition:find(" OR ",pnow)

		local curre = condition:len()
		local nexts
		local isOR
		if andps then
			curre = andps - 1
			nexts = andpe + 1
		end
		if orps and orps < curre then
			curre = orps - 1
			nexts = orpe + 1
			isOR = true
		end
		local condNow = condition:sub(pnow,curre)
		local a,b,condRest = condNow:match("^([^}=~<>]*)([=~<>]=?)(.-)$")

		local isPass
		if condRest then
			for c in string_gmatch(condRest, "[^;]+") do
				if
					(b == "=" and a == c) or
					(b == "~" and a ~= c) or
					(b == ">" and tonumber(a) and tonumber(c) and tonumber(a) > tonumber(c)) or
					(b == "<" and tonumber(a) and tonumber(c) and tonumber(a) < tonumber(c)) or
					(b == "<=" and tonumber(a) and tonumber(c) and tonumber(a) <= tonumber(c)) or
					(b == ">=" and tonumber(a) and tonumber(c) and tonumber(a) >= tonumber(c)) or
					(b == ">" and a > c) or
					(b == "<" and a < c)
				then
					isPass = true
					break
				end
			end
		end

		if isORnow then
			res = res + (isPass and 1 or 0)
		else
			res = res * (isPass and 1 or 0)
		end

		isORnow = isOR

		if not nexts then
			break
		end
		pnow = nexts
	end

	local yes,no = strsplit(";",str or "")
	if res > 0 then
		return yes
	else
		return no or ""
	end
end

local function GSUB_Mark(num)
	if tonumber(num) then
		return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..num..":0|t"
	end
end

local function GSUB_Role(name)
	local role = UnitGroupRolesAssigned(name)
	return (role or "none"):lower()
end

local function GSUB_RoleExtra(name)
	local role1,role2 = module:GetUnitRole(name)
	return (role2 or role1 or "none"):lower()
end

local function GSUB_Find(arg,res)
	local find,str = strsplit(":",arg,2)
	local yes,no = strsplit(";",res or "")
	if (str or ""):find(find) then
		return yes
	else
		return no or ""
	end
end

local function GSUB_Replace(arg,res)
	local from,to = strsplit(":",arg,2)
	local isOk, resOk = pcall(string.gsub, res, from, to)
	return isOk and resOk or res
end

local function GSUB_Sub(arg)
	local from,to,str = strsplit(":",arg,3)
	from = tonumber(from)
	to = tonumber(to or "")
	if from and to and str then
		if to == 0 then to = -1 end
		return str:sub(from,to)
	else
		return ""
	end
end

local function GSUB_EscapeSequences(a)
	if a == "n" then
		return "\n"
	else
		return "|"..a
	end
end

local function GSUB_OnlyIconsFix(text)
	if text:gsub("|T.-|t","") == "" then
		return text .. " "
	end
end

local function GSUB_Trim(text)
	return text:trim()
end


local GSUB_TriggerExtra, GSUB_Trigger

local CreateListOfReplacers
do
	local listOfExtraTriggerWords = {
		allSourceNames = true,
		allTargetNames = true,
		activeTime = true,
		timeLeft = true,
		status = true,
		allActiveUIDs = true,
		activeNum = true,
		timeMinLeft = true,
		counter = true,
		patt = true,
	}
	local listOfReplacers = {}

	function CreateListOfReplacers()
		for k,v in pairs(module.C) do
			if v.replaceres then
				for _,r in ipairs(v.replaceres) do
					listOfReplacers[r] = true
				end
			end
		end
	end

	function GSUB_TriggerExtra(mword,word,num,rest)
		if gsub_trigger_params_now then
			local r = gsub_trigger_params_now[mword or word]

			if word == "counter" then
				local mod,subrest = rest:match("^:(%d+)(.-)$")

				if mod then
					local c = tonumber(r) or 0
					if c == 0 then
						return "0"..subrest
					end
					return ( (c-1)%(tonumber(mod) or 1) + 1 )..subrest
				elseif r then
					return r..rest
				else
					return "0"..rest
				end
			elseif word == "timeLeft" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger
				if t and not t.status then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
				end
				if t and t.status then
					local mod,subrest = rest:match("^:(%d+)(.-)$")
					if mod then
						return format("%."..mod.."f",max((t.status.timeLeft or t.status.timeLeftB) - GetTime(),0))..subrest
					else
						return format("%.1f",max((t.status.timeLeft or t.status.timeLeftB) - GetTime(),0))..rest
					end
				end
				return rest
			elseif type(r) == "function" then
				gsub_trigger_update_req = true
				local res,cutRest = r(select(2,strsplit(":",rest)))
				if res then
					return res..(not cutRest and rest or "")
				end
			elseif r then
				return r..rest
			elseif word == "allSourceNames" or word == "allTargetNames" then
				local key = word == "allSourceNames" and "sourceName" or "targetName"

				local indexFrom,indexTo,customPattern = select(2,strsplit(":",rest))
				local onlyText

				if indexFrom then indexFrom = tonumber(indexFrom) end
				if indexTo then indexTo = tonumber(indexTo) end
				if indexFrom == 0 or indexTo == 0 then indexFrom = nil end
				if customPattern == "1" then onlyText = true customPattern = nil else onlyText = false end
				local r=""
				local lowestindex = 0
				local count = 0

				if not onlyText then
					gsub_trigger_update_req = true
				end

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0]
				if not t and gsub_trigger_params_now._reminder then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
					t = t or gsub_trigger_params_now._reminder.triggers[1]
				end
				if t then
					repeat
						local lownow, vnow
						for _,v in pairs(t.active) do
							if (not lownow or v.aindex < lownow) and v.aindex > lowestindex then
								vnow = v
								lownow = v.aindex
							end
						end
						if vnow then
							count = count + 1
							if not indexFrom or (count >= indexFrom and count <= indexTo) then
								if vnow[key] then
									if customPattern then
										r=r..customPattern:gsub("([A-Za-z]+)",function(a)
											return vnow[a]
										end)
									else
										local index = UnitName(vnow[key]) and GetRaidTargetIndex(vnow[key])
										if index and not onlyText then r=r..ExRT.F.GetRaidTargetText(index,0) end
										r=r..(onlyText and "" or "%classColor")..vnow[key]..", "
									end
								end
							end
							lowestindex = lownow
						else
							lowestindex = nil
						end
					until (not lowestindex)
					return (customPattern and r:gsub("|?|?[n;,] *$","") or r:sub(1,-3))..(not rest:find("^:") and rest or "")
				end
				return rest
			elseif word == "allActiveUIDs" then
				local indexFrom,indexTo = select(2,strsplit(":",rest))

				if indexFrom then indexFrom = tonumber(indexFrom) end
				if indexTo then indexTo = tonumber(indexTo) end
				local r=""
				local lowestindex = 0
				local count = 0
				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 1]
				if t then
					repeat
						local lownow, vnow
						for _,v in pairs(t.active) do
							if (not lownow or v.aindex < lownow) and v.aindex > lowestindex then
								vnow = v
								lownow = v.aindex
							end
						end
						if vnow then
							count = count + 1
							if not indexFrom or (count >= indexFrom and count <= indexTo) then
								if vnow.uid or vnow.guid then
									r=r..(vnow.uid or vnow.guid)..";"
								end
							end
							lowestindex = lownow
						else
							lowestindex = nil
						end
					until (not lowestindex)
					return r:sub(1,-2) .. (not indexFrom and rest or "")
				end
				return rest
			elseif word == "activeTime" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger
				if t and not t.status then
					local ts = gsub_trigger_params_now._reminder.triggers
					for j=1,#ts do
						if ts[j].status then
							t = ts[j]
							break
						end
					end
				end
				if t and t.status then
					local mod,subrest = rest:match("^:(%d+)(.-)$")
					if mod then
						return format("%."..mod.."f",GetTime() - t.status.atime)..subrest
					else
						return format("%.1f",GetTime() - t.status.atime)..rest
					end
				end
				return rest
			elseif word == "status" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 1]
				if t and t.status then
					return "on"..rest
				else
					return "off"..rest
				end
			elseif word == "activeNum" then
				gsub_trigger_update_req = true

				local c = 0
				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger or gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[1]
				if t and t.active then
					for _ in pairs(t.active) do
						c=c+1
					end
				end
				return tostring(c)..rest
			elseif word == "timeMinLeft" then
				gsub_trigger_update_req = true

				local t = gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[tonumber(num) or 0] or gsub_trigger_params_now._trigger or gsub_trigger_params_now._reminder and gsub_trigger_params_now._reminder.triggers[1]
				if t and t._trigger.activeTime then
					local lowest
					for _,v in pairs(t.active) do
						if v.atime and (not lowest or lowest > v.atime) then
							lowest = v.atime
						end
					end
					if lowest then
						local mod,subrest = rest:match("^:(%d+)(.-)$")
						if mod then
							return format("%."..mod.."f",lowest + t._trigger.activeTime - GetTime())..subrest
						else
							return format("%.1f",lowest + t._trigger.activeTime - GetTime())..rest
						end
					end
				end
				return rest
			elseif word == "patt" then
				if gsub_trigger_params_now._data and gsub_trigger_params_now._data.notepat then
					local players = module:FindPlayersListInNote(gsub_trigger_params_now._data.notepat)
					if players then
						local c = 1
						local isOpen
						players = players:gsub("%b{}","")
						local list = {}
						for p in string_gmatch(players, "[^ ]+") do
							if p:sub(1,1) == "(" then
								isOpen = true
								p = p:sub(2)
							end
							if p:sub(-1,-1) == ")" then
								isOpen = false
								p = p:sub(1,-2)
							end
							if isOpen and list[c] then
								list[c] = list[c] .. " " .. p
							else
								list[c] = p
							end
							if not isOpen then
								c = c + 1
							end
						end
						if num ~= "" then
							return (list[tonumber(num)] or "")..rest
						else
							return players..rest
						end
					end
				end
			elseif listOfReplacers[word] then
				return rest or ""
			end
		end
	end

	function GSUB_Trigger(mword,word,num,rest)
		if word == "playerName" then
			return UnitName'player'..rest
		elseif word == "playerClass" then
			return (select(2,UnitClass'player'):lower())..rest
		elseif word == "playerSpec" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			return (defSpecName[specid or 0] or specname and specname:lower())..rest
		elseif word == "defCDIcon" then
			local icon = defCDList[select(2,UnitClass'player') or ""]
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "damageImmuneCDIcon" then
			local icon = damageImmuneCDList[select(2,UnitClass'player') or ""]
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "sprintCDIcon" then
			local icon = sprintCDList[select(2,UnitClass'player') or ""]
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "healCDIcon" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			local icon = healCDList[specid or 0]
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "raidCDIcon" then
			local specid,specname = GetSpecializationInfo(GetSpecialization() or 1)
			local icon = raidCDList[specid or 0]
			return (icon and "{spell:"..icon.."}" or "")..rest
		elseif word == "notePlayer" or word == "notePlayerRight" then
			if gsub_trigger_params_now and gsub_trigger_params_now._data then
				local notePattern = gsub_trigger_params_now._data.notepat
				if notePattern then
					local found, line = module:FindPlayerInNote(notePattern)
					if found and line then
						line = line:gsub(notePattern.." *",""):gsub("|c........",""):gsub("|r",""):gsub("{time[^}]+}",""):gsub("{0}.-{/0}",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
						local playerName = UnitName'player'
						if word == "notePlayer" then
							local prefix = line:match("([^ ]+) +[^ ]*"..playerName) or ""
							if prefix:find("_$") then
								local prefix2 = line:match("(%b__) +[^ ]*"..playerName)
								if prefix2 then
									prefix = prefix2:sub(2,-2)
								end
							end
							if prefix:find("^%(") then prefix = prefix:sub(2) end
							return prefix..rest
						else
							local suffix = line:match(playerName.."[^ ]* +([^ ]+)") or ""
							if suffix:find("^_") then
								local suffix2 = line:match(playerName.."[^ ]* +(%b__)")
								if suffix2 then
									suffix = suffix2:sub(2,-2)
								end
							end
							return suffix..rest
						end
					end
				end
			end
			return rest
		elseif mword:find("^specIcon") or mword:find("^classColor") then
			--nothing, save for GSUB_ModNextWord
			return
		end
		return GSUB_TriggerExtra(mword,word,num,rest) or ("%"..mword..rest)
	end

	local set_list = {}
	local set_update_req
	local function GSUB_Set(num,str)
		if num ~= "" and tonumber(num) then
			if set_update_req then
				wipe(set_list)
				set_update_req = false
			end
			set_list[num] = str
		end
		return ""
	end
	local function GSUB_SetBack(num)
		return set_list[num] or ""
	end

	local function GSUB_Setparam(str)
		if gsub_trigger_params_now then
			local key,value = strsplit(":",str,2)
			gsub_trigger_params_now["#"..key] = value
		end
	end

	local replace_counter = false
	local replace_forchat = false

	local handlers_nocloser = {
		spell = GSUB_Icon,
		math = GSUB_Math,
		noteline = GSUB_ExRTNote,
		note = GSUB_ExRTNoteList,
		min = GSUB_Min,
		max = GSUB_Max,
		status = GSUB_Status,
		role = GSUB_Role,
		roleextra = GSUB_RoleExtra,
		sub = GSUB_Sub,
		trim = GSUB_Trim,
		setparam = GSUB_Setparam,
	}

	local function replace_nocloser(mword,word,num,fullArg,arg)
		local handler = handlers_nocloser[word]
		-- print(mword,word,num,fullArg,arg,gsub_trigger_params_now, (mword:match("^#") or word:match("^#")),gsub_trigger_params_now[mword], gsub_trigger_params_now[word])
		if handler then
			--print('nc',word,arg)
			replace_counter = true
			return handler(arg) or ""
		elseif word == "rt" then
			replace_counter = true
			--print('nc',word,arg)
			if replace_forchat then
				return "___M"..num.."___"
			end
			return GSUB_Mark(num) or ""
		elseif gsub_trigger_params_now and (gsub_trigger_params_now[word] or gsub_trigger_params_now[mword] or listOfExtraTriggerWords[word] or listOfExtraTriggerWords[mword]) then
			replace_counter = true
			--print('nc',word,arg)
			return GSUB_TriggerExtra(mword,word,num,fullArg) or ""
		elseif gsub_trigger_params_now and (mword:match("^#") or word:match("^#")) and (gsub_trigger_params_now[mword] or gsub_trigger_params_now[word]) then
			return gsub_trigger_params_now[mword] or gsub_trigger_params_now[word]
		end
	end

	local handlers_closer = {
		num = GSUB_NumCondition,
		up = GSUB_Upper,
		lower = GSUB_Lower,
		rep = GSUB_Repeat,
		len = GSUB_Length,
		["0"] = GSUB_None,
		cond = GSUB_YesNoCondition,
		find = GSUB_Find,
		replace = GSUB_Replace,
		set = GSUB_Set,
	}

	local function replace_closer(word,arg,data)
		local handler = handlers_closer[word]
		if handler then
			replace_counter = true
			--print('c',word,arg,data)
			return handler(arg,data) or ""
		end
	end

	function module:FormatMsg(msg,params,isForChat)
		gsub_trigger_params_now = params
		gsub_trigger_update_req = false

		set_update_req = true
		replace_forchat = false
		if isForChat then
			replace_forchat = true
		end

		msg = msg:gsub("%%(([A-Za-z]+)(%d*))([^%% ,{}]*)",GSUB_Trigger)

		local subcount = 0
		while true do
			replace_counter = false
			subcount = subcount + 1
			--print('sc',subcount,msg)
			msg = msg:gsub("{(([A-Za-z#]+)(%d*))(:?([^{}]*))}",replace_nocloser) --# for setparam
				:gsub("{([^:{}]+):?([^{}]*)}([^{}]-){/%1}",replace_closer)
			if not replace_counter or subcount > 100 then
				if not set_update_req then
					msg = msg:gsub("%%set(%d+)",GSUB_SetBack)
					set_update_req = true
				else
					break
				end
			end
		end

		msg = msg:gsub("||([crTtnAa])",GSUB_EscapeSequences)
			:gsub("%%([sc][A-Za-z]+ *[^ ,%%;:%(%)|]*)",GSUB_ModNextWord)
			:gsub("[^\n]+",GSUB_OnlyIconsFix)

		if replace_forchat then
			msg = msg:gsub("___M(%d+)___","{rt%1}")
		end

		msg = msg:gsub("\\n", "\n")
		return msg, gsub_trigger_update_req
	end
end

function module:FormatMsgForChat(msg)
	return msg:gsub("|c........",""):gsub("|[rn]",""):gsub("|[TA][^|]+|[ta]","")
end

function module:ExtraCheckParams(extraCheck,params)
	extraCheck = module:FormatMsg(extraCheck,params)

	if not extraCheck:find("[=~]") then
		return false, false
	else
		if GSUB_YesNoCondition(extraCheck,1) == "1" then
			return true, true
		else
			return false, true
		end
	end
end

module.datas = {
	countdownType = {
		{1,"5"," %d"},
		{nil,"5.3"," %.1f"},
		{3,"5.32"," %.2f"},
	},
	-- countdownTypeText = {
	-- {1,"Every 2 sec"," %d"},
	-- {nil,"Every 1 sec"," %.1f"},
	-- {3,"Every 0.5 sec"," %.2f"},
	-- },

	-- messageSize = {
	-- {nil,L.ReminderDefText},
	-- {2,L.ReminderBigText},
	-- {3,L.ReminderSmallText},
	-- {12,"Progress Bar"},
	-- {13,"Small Progress Bar"},
	-- {14,"Big Progress Bar"},
	-- {4,L.ReminderMsgSay},
	-- {5,L.ReminderMsgYell},
	-- {8,L.ReminderMsgRaid},
	-- {11,"Print in chat (personal)"},
	-- {6,L.ReminderMsgNameplate},
	-- {7,L.ReminderMsgNameplateText},
	-- {9,L.ReminderMsgRaidFrame},
	-- {10,L.ReminderMsgWA,"Custom event MRT_REMINDER_EVENT"},
	-- },
	-- bossDiff = {
	-- {nil,ALL},
	-- {14,PLAYER_DIFFICULTY1 or "Normal"},
	-- {15,PLAYER_DIFFICULTY2 or "HC"},
	-- {16,PLAYER_DIFFICULTY6 or "Mythic"},
	-- },
	rolesList = {
		{nil,nil,"|cff808080-|r"},
		{1,LR.RolesTanks,"TANK"},
		{2,LR.RolesHeals,"HEALER"},
		{3,LR.RolesDps,"DAMAGER"},
		{4,LR.RolesMheals,"MHEALER"},
		{5,LR.RolesRheals,"RHEALER"},
		{6,LR.RolesMdps,"MDD"},
		{7,LR.RolesRdps,"RDD"},
	},
	events = {
		1, 2, 3, 6, 7, 4, 5, 11, 8, 9, 10, 12, 13, 14, 16, 15, 19 --,17,18
	},
	counterBehavior = {
		{nil,LR.ReminderGlobalCounter,LR.ReminderGlobalCounterTip},
		{1,LR.ReminderCounterSource,LR.ReminderCounterSourceTip},
		{2,LR.ReminderCounterDest,LR.ReminderCounterDestTip},
		{3,LR.ReminderCounterTriggers,LR.ReminderCounterTriggersTip},
		{4,LR.ReminderCounterTriggersPersonal,LR.ReminderCounterTriggersPersonalTip},
		{5,LR["Global counter for reminder"],LR.ReminderCounterGlobalForReminderTip},
		{6,LR["Reset in 5 sec"],LR.ReminderCounterResetIn5SecTip},
	},
	units = {
		{nil,"|cff808080-|r"},
		{"player",STATUS_TEXT_PLAYER or "Player"},
		{"target",TARGET or "Target"},
		{"focus",LR.Conditionsfocus},
		{"mouseover","Mouseover"},
		{"boss1"},
		{"boss2"},
		{"boss3"},
		{"boss4"},
		{"boss5"},
		{"boss6"},
		{"boss7"},
		{"boss8"},
		{"pet",PET or "Pet"},
		{1,LR.ReminderAnyBoss},
		{2,LR.ReminderAnyNameplate},
		{3,LR.ReminderAnyRaid},
		{4,LR.ReminderAnyParty},
	},
	marks = {
		{nil,"|cff808080-|r"},
		{0,LR.Conditionsnomark},
		{1,ExRT.F.GetRaidTargetText(1,20)},
		{2,ExRT.F.GetRaidTargetText(2,20)},
		{3,ExRT.F.GetRaidTargetText(3,20)},
		{4,ExRT.F.GetRaidTargetText(4,20)},
		{5,ExRT.F.GetRaidTargetText(5,20)},
		{6,ExRT.F.GetRaidTargetText(6,20)},
		{7,ExRT.F.GetRaidTargetText(7,20)},
		{8,ExRT.F.GetRaidTargetText(8,20)},
		{9,ExRT.F.GetRaidTargetText(9,20)},
		{10,ExRT.F.GetRaidTargetText(10,20)},
		{11,ExRT.F.GetRaidTargetText(11,20)},
		{12,ExRT.F.GetRaidTargetText(12,20)},
		{13,ExRT.F.GetRaidTargetText(13,20)},
		{14,ExRT.F.GetRaidTargetText(14,20)},
		{15,ExRT.F.GetRaidTargetText(15,20)},
		{16,ExRT.F.GetRaidTargetText(16,20)},
	},
	markToIndex = {
		[0] = 0,
		[0x1] = 1,
		[0x2] = 2,
		[0x4] = 3,
		[0x8] = 4,
		[0x10] = 5,
		[0x20] = 6,
		[0x40] = 7,
		[0x80] = 8,
		[0x100] = 9,
		[0x200] = 10,
		[0x400] = 11,
		[0x800] = 12,
		[0x1000] = 13,
		[0x2000] = 14,
		[0x4000] = 15,
		[0x8000] = 16,
		[0x10000] = 17,
		[0x20000] = 18,
	},
	unitsList = {
		{"boss1","boss2","boss3","boss4","boss5"},
		{"nameplate1","nameplate2","nameplate3","nameplate4","nameplate5","nameplate6","nameplate7","nameplate8","nameplate9","nameplate10",
			"nameplate11","nameplate12","nameplate13","nameplate14","nameplate15","nameplate16","nameplate17","nameplate18","nameplate19","nameplate20",
			"nameplate21","nameplate22","nameplate23","nameplate24","nameplate25","nameplate26","nameplate27","nameplate28","nameplate29","nameplate30",
			"nameplate31","nameplate32","nameplate33","nameplate34","nameplate35","nameplate36","nameplate37","nameplate38","nameplate39","nameplate40"},
		{"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10",
			"raid11","raid12","raid13","raid14","raid15","raid16","raid17","raid18","raid19","raid20",
			"raid21","raid22","raid23","raid24","raid25","raid26","raid27","raid28","raid29","raid30",
			"raid31","raid32","raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40"},
		{"player","party1","party2","party3","party4"},
		ALL = {"boss1","boss2","boss3","boss4","boss5",
			"nameplate1","nameplate2","nameplate3","nameplate4","nameplate5","nameplate6","nameplate7","nameplate8","nameplate9","nameplate10",
			"nameplate11","nameplate12","nameplate13","nameplate14","nameplate15","nameplate16","nameplate17","nameplate18","nameplate19","nameplate20",
			"nameplate21","nameplate22","nameplate23","nameplate24","nameplate25","nameplate26","nameplate27","nameplate28","nameplate29","nameplate30",
			"nameplate31","nameplate32","nameplate33","nameplate34","nameplate35","nameplate36","nameplate37","nameplate38","nameplate39","nameplate40",
			"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10",
			"raid11","raid12","raid13","raid14","raid15","raid16","raid17","raid18","raid19","raid20",
			"raid21","raid22","raid23","raid24","raid25","raid26","raid27","raid28","raid29","raid30",
			"raid31","raid32","raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40",
			"player","party1","party2","party3","party4"},
		ALL_FRIENDLY = {"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10",
			"raid11","raid12","raid13","raid14","raid15","raid16","raid17","raid18","raid19","raid20",
			"raid21","raid22","raid23","raid24","raid25","raid26","raid27","raid28","raid29","raid30",
			"raid31","raid32","raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40",
			"player","party1","party2","party3","party4"},
	},
	fields = {
		"eventCLEU","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole",
		"spellID","spellName","extraSpellID","stacks","numberPercent","pattFind","bwtimeleft","counter","cbehavior","delayTime","activeTime","invert","guidunit","onlyPlayer",
	},
	glowTypes = {
		{nil,LR.NameplateGlowTypeDef},
		{1,LR.NameplateGlowType1},
		{2,LR.NameplateGlowType2},
		{3,LR.NameplateGlowType3},
		{4,LR.NameplateGlowType4},
		{5,LR["AIM"]},
		{6,LR["Solid color"]},
		{7,LR["Custom icon above"]},
		{8,LR["% HP"]},
	},
	glowImages = {
		{nil,"-"},
		{1,"Target mark",[[Interface\AddOns\WeakAuras\Media\Textures\target_indicator.tga]],100,50,{0,1,0,0.5}},
		{4,"Target mark 2",[[Interface\AddOns\WeakAuras\Media\Textures\targeting-mark.tga]]},
		{2,"Jesus",[[Interface\Addons\WeakAuras\PowerAurasMedia\Auras\Aura113]]},
		{3,"Swords",[[Interface\Addons\WeakAuras\PowerAurasMedia\Auras\Aura19]]},
		{5,"X",[[Interface\Addons\WeakAuras\PowerAurasMedia\Auras\Aura118]]},
		{6,"STOP",[[Interface\Addons\WeakAuras\PowerAurasMedia\Auras\Aura138]]},
		{7,"Logo",[[Interface\AddOns\MRT\media\OptionLogo2.tga]]},
		{8,"Boom",[[Interface\AddOns\MRT\media\deathstard.tga]]},
		{9,"BigWigs",[[Interface\AddOns\BigWigs\Media\Icons\core-enabled.tga]],64,64},
		{0,LR.Manually},
	},
	glowImagesData = {},	--create later via func from <glowImages>
	vcountdowns = {
	{nil,"-"},
	{1,"English: Amy","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Amy\\"},
	{2,"English: David","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\David\\"},
	{3,"English: Jim","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Jim\\"},
	{4,"English: Default (Female)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\enUS\\female\\"},
	{5,"English: Default (Male)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\enUS\\male\\"},
	{6,"Deutsch: Standard (Female)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\deDE\\female\\"},
	{7,"Deutsch: Standard (Male)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\deDE\\male\\"},
	{8,"Español: Predeterminado (es) (Femenino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\esES\\female\\"},
	{9,"Español: Predeterminado (es) (Masculino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\esES\\male\\"},
	{10,"Español: Predeterminado (mx) (Femenino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\esMX\\female\\"},
	{11,"Español: Predeterminado (mx) (Masculino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\esMX\\male\\"},
	{12,"Français: Défaut (Femme)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\frFR\\female\\"},
	{13,"Français: Défaut (Homme)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\frFR\\male\\"},
	{14,"Italiano: Predefinito (Femmina)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\itIT\\female\\"},
	{15,"Italiano: Predefinito (Maschio)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\itIT\\male\\"},
	{16,"Русский: По умолчанию (Женский)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\ruRU\\female\\"},
	{17,"Русский: По умолчанию (Мужской)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\ruRU\\male\\"},
	{18,"한국어: 기본 (여성)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\koKR\\female\\"},
	{19,"한국어: 기본 (남성)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\koKR\\male\\"},
	{20,"Português: Padrão (Feminino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\ptBR\\female\\"},
	{21,"Português: Padrão (Masculino)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\ptBR\\male\\"},
	{22,"简体中文:默认 (女性)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\zhCN\\female\\"},
	{23,"简体中文:默认 (男性)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\zhCN\\male\\"},
	{24,"繁體中文:預設值 (女性)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\zhTW\\female\\"},
	{25,"繁體中文:預設值 (男性)","Interface\\AddOns\\"..GlobalAddonName.."\\Media\\Sounds\\Heroes\\zhTW\\male\\"},
	},
	vcdsounds = {},	--create later via func from <vcountdowns>
}

for _,v in pairs(module.datas.vcountdowns) do
	if v[3] then
		module.datas.vcdsounds[ v[1] ] = v[3]
	end
end
for _,v in pairs(module.datas.glowImages) do
	if v[3] then
		module.datas.glowImagesData[ v[1] ] = v
	end
end
module.C = {
	[1] = {
		id = 1,
		name = "COMBAT_LOG_EVENT_UNFILTERED",
		lname = LR.ReminderCombatLog,
		events = "COMBAT_LOG_EVENT_UNFILTERED",
		isUntimed = false,
		isUnits = false,
		subEventField = "eventCLEU",
		subEvents = {
			"SPELL_CAST_START",
			"SPELL_CAST_SUCCESS",
			"SPELL_AURA_APPLIED",
			"SPELL_AURA_REMOVED",
			"SPELL_DAMAGE",
			"SPELL_PERIODIC_DAMAGE",
			"SWING_DAMAGE",
			"SPELL_HEAL",
			"SPELL_PERIODIC_HEAL",
			"SPELL_ABSORBED",
			"SPELL_ENERGIZE",
			"SPELL_MISSED",
			"UNIT_DIED",
			"SPELL_SUMMON",
			"SPELL_INTERRUPT",
			"SPELL_DISPEL",
			"SPELL_AURA_BROKEN_SPELL",
			"ENVIRONMENTAL_DAMAGE",
		},
		triggerFields = {"eventCLEU"},
		alertFields = {"eventCLEU"},
	},
	["SPELL_CAST_START"] = {
		main_id = 1,
		subID = 1,
		lname = LR.ReminderCastStart,
		events = "SPELL_CAST_START",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","sourceID","sourceMark","spellName","invert"},
		replaceres = {"sourceName","sourceMark","sourceGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_CAST_SUCCESS"] = {
		main_id = 1,
		subID = 2,
		lname = LR.ReminderCastDone,
		events = "SPELL_CAST_SUCCESS",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_AURA_APPLIED"] = {
		main_id = 1,
		subID = 3,
		lname = LR.ReminderAuraAdd,
		events = {"SPELL_AURA_APPLIED","SPELL_AURA_APPLIED_DOSE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","stacks","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","stacks","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","counter","guid"},
	},
	["SPELL_AURA_REMOVED"] = {
		main_id = 1,
		subID = 4,
		lname = LR.ReminderAuraRem,
		events = {"SPELL_AURA_REMOVED","SPELL_AURA_REMOVED_DOSE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","stacks","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","stacks","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","counter","guid"},
	},
	["SPELL_DAMAGE"] = {
		main_id = 1,
		subID = 5,
		lname = LR.ReminderSpellDamage,
		events = {"SPELL_DAMAGE","RANGE_DAMAGE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_PERIODIC_DAMAGE"] = {
		main_id = 1,
		subID = 6,
		lname = LR.ReminderSpellDamageTick,
		events = "SPELL_PERIODIC_DAMAGE",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SWING_DAMAGE"] = {
		main_id = 1,
		subID = 7,
		lname = LR.ReminderMeleeDamage,
		events = "SWING_DAMAGE",
		triggerFields = {"eventCLEU","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellID",spellID=LR.ReminderReplacerspellIDSwing,"counter","guid"},
	},
	["SPELL_HEAL"] = {
		main_id = 1,
		subID = 8,
		lname = LR.ReminderSpellHeal,
		events = "SPELL_HEAL",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_PERIODIC_HEAL"] = {
		main_id = 1,
		subID = 9,
		lname = LR.ReminderSpellHealTick,
		events = "SPELL_PERIODIC_HEAL",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_ABSORBED"] = {
		main_id = 1,
		subID = 10,
		lname = LR.ReminderSpellAbsorb,
		events = "SPELL_ABSORBED",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_ENERGIZE"] = {
		main_id = 1,
		subID = 11,
		lname = LR.ReminderCLEUEnergize,
		events = {"SPELL_ENERGIZE","SPELL_PERIODIC_ENERGIZE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_MISSED"] = {
		main_id = 1,
		subID = 12,
		lname = LR.ReminderCLEUMiss,
		events = {"SPELL_MISSED","RANGE_MISSED","SPELL_PERIODIC_MISSED"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		fieldNames = {["pattFind"]=LR.ReminderMissType},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","pattFind","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["UNIT_DIED"] = {
		main_id = 1,
		subID = 13,
		lname = LR.ReminderDeath,
		events = {"UNIT_DIED","UNIT_DESTROYED"},
		triggerFields = {"eventCLEU","targetName","targetID","targetUnit","targetMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","targetMark","invert"},
		replaceres = {"targetName","targetMark","targetGUID","counter","guid"},
	},
	["SPELL_SUMMON"] = {
		main_id = 1,
		subID = 14,
		lname = LR.ReminderSummon,
		events = {"SPELL_SUMMON","SPELL_CREATE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_DISPEL"] = {
		main_id = 1,
		subID = 15,
		lname = LR.ReminderDispel,
		events = {"SPELL_DISPEL","SPELL_STOLEN"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID","counter","guid"},
	},
	["SPELL_AURA_BROKEN_SPELL"] = {
		main_id = 1,
		subID = 16,
		lname = LR.ReminderCCBroke,
		events = {"SPELL_AURA_BROKEN_SPELL","SPELL_AURA_BROKEN"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReminderReplacerextraSpellID,"counter","guid"},
	},
	["ENVIRONMENTAL_DAMAGE"] = {
		main_id = 1,
		subID = 17,
		lname = LR.ReminderEnvDamage,
		events = "ENVIRONMENTAL_DAMAGE",
		triggerFields = {"eventCLEU","spellID","targetName","targetID","targetUnit","targetMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","targetMark","invert"},
		replaceres = {"targetName","targetMark","targetGUID","spellName","counter","guid"},
	},
	["SPELL_INTERRUPT"] = {
		main_id = 1,
		subID = 18,
		lname = LR.ReminderInterrupt,
		events = "SPELL_INTERRUPT",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID","counter","guid"},
	},
	[2] = {
		id = 2,
		name = "BOSS_PHASE",
		lname = LR.ReminderBossPhase,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage"},
		isUntimed = true,
		isUnits = false,
		triggerFields = {"pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"pattFind"},
		fieldNames = {["pattFind"]=LR.ReminderBossPhaseLabel},
		triggerSynqFields = {"pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		help = LR.ReminderBossPhaseTip,
		replaceres = {"phase","counter"},
	},
	[3] = {
		id = 3,
		name = "BOSS_START",
		lname = LR.ReminderBossPull,
		isUntimed = false,
		isUnits = false,
		triggerFields = {"delayTime","activeTime","invert"},
		triggerSynqFields = {"delayTime","activeTime","invert"},
	},
	[4] = {
		id = 4,
		name = "UNIT_HEALTH",
		lname = LR.ReminderHealth,
		events = "UNIT_HEALTH",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.ReminderHealthTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReminderReplacertargetGUID,"health","value","counter"},
	},
	[5] = {
		id = 5,
		name = "UNIT_POWER_FREQUENT",
		lname = LR.ReminderMana,
		events = "UNIT_POWER_FREQUENT",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.ReminderManaTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReminderReplacertargetGUID,"health",health=LR.ReminderReplacerhealthenergy,"value",value=LR.ReminderReplacervalueenergy,"counter"},
	},
	[6] = {
		id = 6,
		name = "BW_MSG",
		lname = LR.ReminderBWMsg,
		events = {"BigWigs_Message","DBM_Announce"},
		isUntimed = false,
		isUnits = false,
		triggerFields = {"pattFind","spellID","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {0,"pattFind","spellID"},
		triggerSynqFields = {"spellID","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		replaceres = {"spellID","spellName",spellName=LR.ReminderReplacerspellNameBWMsg,"counter"},
	},
	[7] = {
		id = 7,
		name = "BW_TIMER",
		lname = LR.ReminderBWTimer,
		events = {"BigWigs_StartBar","BigWigs_StopBar","BigWigs_PauseBar","BigWigs_ResumeBar","BigWigs_StopBars","BigWigs_OnBossDisable","DBM_TimerStart","DBM_TimerStop","DBM_TimerPause","DBM_TimerResume","DBM_TimerUpdate","DBM_kill","DBM_kill"},
		isUntimed = false,
		isUnits = false,
		extraDelayTable = true,
		triggerFields = {"pattFind","spellID","bwtimeleft","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"bwtimeleft",0,"pattFind","spellID"},
		triggerSynqFields = {"bwtimeleft","spellID","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		replaceres = {"spellID","spellName",spellName=LR.ReminderReplacerspellNameBWTimer,"timeLeft","counter"},
	},
	[8] = {
		id = 8,
		name = "CHAT_MSG",
		lname = LR.ReminderChat,
		events = {"CHAT_MSG_RAID_WARNING","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_MONSTER_SAY","CHAT_MSG_MONSTER_WHISPER","CHAT_MSG_RAID_BOSS_EMOTE","CHAT_MSG_RAID_BOSS_WHISPER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_WHISPER"},
		isUntimed = false,
		isUnits = false,
		triggerFields = {"pattFind","sourceName","sourceID","sourceUnit","targetName","targetUnit","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"pattFind"},
		triggerSynqFields = {"pattFind","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","invert"},
		help = LR.ReminderChatHelp,
		replaceres = {"sourceName","targetName","text","counter"},
	},
	[9] = {
		id = 9,
		name = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
		lname = LR.ReminderBossFrames,
		events = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
		isUntimed = false,
		isUnits = false,
		triggerFields = {"targetName","targetID","targetUnit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","invert"},
		replaceres = {"targetName","guid",guid=LR.ReminderReplacertargetGUID,"counter"},
	},
	[10] = {
		id = 10,
		name = "UNIT_AURA",
		lname = LR.ReminderAura,
		events = "UNIT_AURA",
		isUntimed = true,
		isUnits = true,
		extraDelayTable = true,
		unitField = "targetUnit",
		triggerFields = {"spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","stacks","bwtimeleft","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"targetUnit",0,"spellID","spellName"},
		triggerSynqFields = {"targetUnit","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","sourceID","sourceMark","targetID","targetMark","spellName","stacks","bwtimeleft","invert","onlyPlayer","targetRole"},
		help = LR.ReminderAuraTip,
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","timeLeft","counter","guid","auraValA","auraValB","auraValC"},
	},
	[11] = {
		id = 11,
		name = "UNIT_ABSORB_AMOUNT_CHANGED",
		lname = LR.ReminderAbsorb,
		events = "UNIT_ABSORB_AMOUNT_CHANGED",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		fieldNames = {["numberPercent"]=LR.ReminderAbsorbLabel},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.ReminderAbsorbTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReminderReplacertargetGUID,"value",value=LR.ReminderReplacervalueabsorb,"counter"},
	},
	[12] = {
		id = 12,
		name = "UNIT_TARGET",
		lname = LR.ReminderCurTarget,
		events = {"UNIT_TARGET","UNIT_THREAT_LIST_UPDATE"},
		isUntimed = true,
		isUnits = true,
		unitField = "sourceUnit",
		triggerFields = {"sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"sourceUnit"},
		triggerSynqFields = {"sourceUnit","counter","cbehavior","delayTime","activeTime","sourceName","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","invert","guidunit"},
		help = LR.ReminderCurTargetTip,
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","counter","guid"},
	},
	[13] = {
		id = 13,
		name = "CDABIL",
		lname = LR.ReminderSpellCD,
		events = "SPELL_UPDATE_COOLDOWN",
		tooltip = LR.ReminderSpellCDTooltip,
		isUntimed = true,
		isUnits = false,
		triggerFields = {"spellID","spellName","bwtimeleft","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {0,"spellID","spellName"},
		triggerSynqFields = {"spellID","counter","cbehavior","delayTime","activeTime","spellName","bwtimeleft","invert"},
		help = LR.ReminderSpellCDTip,
		replaceres = {"spellName","spellID","counter","timeLeft"},
	},
	[14] = {
		id = 14,
		name = "UNIT_SPELLCAST_SUCCEEDED",
		lname = LR.SpellCastDone,
		events = "UNIT_SPELLCAST_SUCCEEDED",
		tooltip = LR.SpellCastDoneTooltip,
		isUntimed = false,
		isUnits = true,
		unitField = "sourceUnit",
		triggerFields = {"spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"sourceUnit"},
		triggerSynqFields = {"sourceUnit","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceID","sourceMark","spellName","invert"},
		replaceres = {"sourceName","sourceMark","guid",guid=LR.ReplacersourceGUID,"spellID","spellName","counter"},
	},
	[15] = {
		id = 15,
		name = "UPDATE_UI_WIDGET",
		lname = LR.Widget,
		events = "UPDATE_UI_WIDGET",
		isUntimed = true,
		isUnits = false,
		triggerFields = {"spellID","spellName","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent",0,"spellID","spellName"},
		fieldNames = {["spellID"]=LR.WidgetLabelID,["spellName"]=LR.WidgetLabelName},
		triggerSynqFields = {"numberPercent","spellID","counter","cbehavior","delayTime","activeTime","spellName","invert"},
		help = LR.WidgetTip,
		replaceres = {"spellID",spellID=LR.ReplacerspellIDwigdet,"spellName",spellName=LR.ReplacerspellNamewigdet,"value",value=LR.Replacervaluewigdet,"counter"},
	},
	[16] = {
		id = 16,
		name = "UNIT_CAST",
		lname = LR.UnitCast,
		events = {"UNIT_SPELLCAST_START","UNIT_SPELLCAST_STOP","UNIT_SPELLCAST_CHANNEL_START","UNIT_SPELLCAST_CHANNEL_STOP"},
		isUntimed = true,
		isUnits = true,
		unitField = "sourceUnit",
		triggerFields = {"sourceName","sourceID", "sourceUnit", "sourceMark","spellID","spellName","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"sourceUnit"},
		triggerSynqFields = {"spellID","sourceUnit","counter","cbehavior","delayTime","activeTime","sourceName","spellName","sourceID","sourceMark","invert"},
		help = LR.UnitCastTip,
		replaceres = {"sourceName","sourceMark","guid",guid=LR.ReplacersourceGUID,"spellID","spellName","timeLeft"},
	},
	[17] = {
		id = 17,
		name = "NOTE_TIMERS",
		lname = "Note timers",
		isUntimed = true,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage","COMBAT_LOG_EVENT_UNFILTERED"},
		triggerFields = {"bwtimeleft","activeTime","invert"},
		triggerSynqFields = {"bwtimeleft","activeTime","invert"},
		help = "Automatic timers for all lines from MRT note with players name and {time:x:xx} template.",
		replaceres = {"text",text=L.ReminderReplacertextnotetimers,"textLeft","textModIcon:X:Y",value=L.ReminderReplacerlistmobrange,"fullLine","fullLineClear","phase"},
	},
	[18] = {
		id = 18,
		name = "NOTE_TIMERS_ALL",
		lname = "Note timers [all]",
		isUntimed = true,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage","COMBAT_LOG_EVENT_UNFILTERED"},
		triggerFields = {"bwtimeleft","activeTime","invert"},
		triggerSynqFields = {"bwtimeleft","activeTime","invert"},
		help = "Automatic timers for all lines from MRT note with {time:x:xx} template.",
		replaceres = {"text",text=L.ReminderReplacertextnotetimers,"textLeft","textModIcon:X:Y",value=L.ReminderReplacerlistmobrange,"fullLine","fullLineClear","phase"},
	},
	--add a raid group number trigger
	[19] = {
		id = 19,
		name = "RAID_GROUP_NUMBER",
		lname = LR["Raid group number"],
		isUntimed = true,
		isUnits = true,
		unitField = "",
		events = {"GROUP_ROSTER_UPDATE"},
		triggerFields = {"stacks","sourceName","sourceUnit","invert"},
		fieldNames = {["stacks"]=LR["Raid group number"]},
		alertFields = {0,"sourceUnit","sourceName"},
		triggerSynqFields = {"stacks","sourceName","sourceUnit","invert"},
		-- help = "Trigger when player in raid group number.",
		replaceres = {"sourceName","sourceGUID","stacks",stacks=LR["Raid group number"],"guid"},

	}
}

CreateListOfReplacers()

function module:CheckUnit(unitVal,unitguid,trigger)
	if not unitguid then
		return false
	elseif type(unitVal) == "string" then
		return UnitGUID(unitVal) == unitguid
	elseif type(unitVal) == "number" then
		if unitVal < 0 then
			local triggerDest = trigger and trigger._reminder.triggers[-unitVal]
			if triggerDest then
				for uid,data in pairs(triggerDest.active) do
					if data.guid == unitguid then
						return true
					end
				end
			end
		else
			local list = module.datas.unitsList[unitVal]
			for i=1,#list do
				local guid = UnitGUID(list[i])
				if guid == unitguid then
					return true
				end
			end
		end
	end
end

function module:CheckNumber(checkFuncs,num)
	for k,v in pairs(checkFuncs) do
		if v(num) then
			return true
		end
	end
end

function module:FindPlayersListInNote(pat)
	pat = "^"..pat:gsub("([%.%(%)%-%$])","%%%1")
	if not VExRT or not VExRT.Note or not VExRT.Note.Text1 then
		return
	end
	local lines = GetMRTNoteLines()
	local res
	for i=1,#lines do
		if lines[i]:find(pat) then
			local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
			if not res then res = "" end
			res = res..(res ~= "" and " " or "")..l
		end
	end
	return res
end

function module:GetUnitRole(unit)
	local role = UnitGroupRolesAssigned(unit)
	if role == "HEALER" then
		local _,class = UnitClass(unit)
		return role, (class == "PALADIN" or class == "MONK") and "MHEALER" or "RHEALER"
	elseif role ~= "DAMAGER" then
		--TANK, NONE
		return role
	else
		local _,class = UnitClass(unit)
		local isMelee = (class == "WARRIOR" or class == "PALADIN" or class == "ROGUE" or class == "DEATHKNIGHT" or class == "MONK" or class == "DEMONHUNTER")
		if class == "DRUID" then
			isMelee = not (UnitPowerType(unit) == 8)	--astral power
		elseif class == "SHAMAN" then
			isMelee = not ((ExRT.A.Inspect and UnitName(unit) and ExRT.A.Inspect.db.inspectDB[UnitName(unit)] and ExRT.A.Inspect.db.inspectDB[UnitName(unit)].spec) == 262)
		elseif class == "HUNTER" then
			isMelee = (ExRT.A.Inspect and UnitName(unit) and ExRT.A.Inspect.db.inspectDB[UnitName(unit)] and ExRT.A.Inspect.db.inspectDB[UnitName(unit)].spec) == 255
		end
		if isMelee then
			return role, "MDD"
		else
			return role, "RDD"
		end
	end
end

function module:CmpUnitRole(unit,roleIndex)
	local mainRole, subRole = module:GetUnitRole(unit)
	local sub = ExRT.F.table_find3(module.datas.rolesList,subRole,3)
	if sub and roleIndex == sub[1] then
		return true
	end

	local main = ExRT.F.table_find3(module.datas.rolesList,mainRole,3)
	if main and roleIndex == main[1] then
		return true
	end

	if roleIndex == 6 and main ~= "TANK" then	--not tank role, hardcoded
		return true
	end
end

function module:GetRoleIndex()
	local mainRole, subRole = ExRT.F.GetPlayerRole()

	local sub = ExRT.F.table_find3(module.datas.rolesList,subRole,3)
	if sub then
		return sub[1]
	end

	local main = ExRT.F.table_find3(module.datas.rolesList,mainRole,3)
	if main then
		return main[1]
	else
		return 0
	end
end

local playerName = UnitName'player'

local GetPlayerRole = ExRT.F.GetPlayerRole

local function CheckRole(roles,role1, role2)
	if roles:find("#"..role1.."#") then
		return true
	elseif role2 and roles:find("#"..role2.."#") then
		return true
	end
end

function module:CheckPlayerCondition(data,myName,myClass,role1,role2)
	if not role1 and not role2 then
		role1, role2 = GetPlayerRole()
	end
	if not myName then
		myName = ExRT.SDB.charName
	end

	if not myClass then
		myClass = UnitClassBase('player')
	end

	local isNoteOn,isInNote
	if data.notepat then
		isNoteOn = true
		isInNote = module:FindPlayerInNote(data.notepat)
	end
	if
        (
            (not isNoteOn or isInNote) and
			(not data.units or (not data.reversed and data.units:find("#"..myName.."#")) or (data.reversed and not data.units:find("#"..myName.."#"))) and
			(not data.roles or CheckRole(data.roles, role1, role2)) and
			(not data.classes or data.classes:find("#".. myClass .."#"))
		)
	then
		return true
	end
end

do
	local function ResetCounter(trigger)
		trigger.count = 0
	end
	function module:AddTriggerCounter(trigger,behav1,behav2)
		if trigger._trigger.cbehavior == 1 and behav1 then
			trigger.count = behav1
		elseif trigger._trigger.cbehavior == 2 and behav2 then
			trigger.count = behav2
		elseif trigger._trigger.cbehavior == 3 or trigger._trigger.cbehavior == 4 then
			if trigger._reminder.activeFunc2(trigger._reminder.triggers,trigger._i) then
				trigger.count = trigger.count + 1
			end
		elseif trigger._trigger.cbehavior == 5 then
			trigger.count = (trigger._reminder.globalcounter or 0) + 1
			trigger._reminder.globalcounter = trigger.count
		else
			trigger.count = trigger.count + 1

			if trigger._trigger.cbehavior == 6 then
				module.db.timers[#module.db.timers+1] = ScheduleTimer(ResetCounter, 5, trigger)
			end
		end
	end
end

do
	local UIDNow = 1
	function module:GetNextUID()
		UIDNow = UIDNow + 1
		return UIDNow
	end
end

function module:RunTrigger(trigger, vars)
	-- local triggerData = trigger._trigger
	if trigger.DdelayTime then
		for i=1,#trigger.DdelayTime do
			local t = ScheduleTimer(module.ActivateTrigger, trigger.DdelayTime[i], 0, trigger, vars)
			module.db.timers[#module.db.timers+1] = t
			if trigger.delays then
				trigger.delays[#trigger.delays+1] = t
			end
		end
	else
		module:ActivateTrigger(trigger, vars)
	end
end

do
	local indexNow = 1
	function module:ActivateTrigger(trigger, vars)
		vars = vars or {}
		if (vars.uid or vars.guid) and trigger.active[vars.uid or vars.guid] then
			return
		end
		if module.db.debugLog then module:DebugLogAdd("ActivateTrigger",trigger._data.name or trigger._data.msg,vars.uid or vars.guid) end

		trigger.status = vars

		trigger.active[vars.uid or vars.guid or 1] = vars

		vars.aindex = indexNow
		indexNow = indexNow + 1

		vars.atime = GetTime()
		vars.timeLeftB = vars.atime + (trigger._trigger.activeTime or 0)

		if trigger.untimed and trigger.units then	--??? double recheck for units
			module:CheckUnitTriggerStatus(trigger)
		end
		module:CheckAllTriggers(trigger)

		if trigger._trigger.activeTime then
			module.db.timers[#module.db.timers+1] = ScheduleTimer(module.DeactivateTrigger, max(trigger._trigger.activeTime, 0.01), 0, trigger, vars.uid or vars.guid or 1, true)
		elseif not trigger.untimed then
			module:DeactivateTrigger(trigger, vars.uid or vars.guid or 1)
		end
	end
end

do
	local valsExtra = {
		["sourceMark"] = function(m) return ExRT.F.GetRaidTargetText(m,0) end,
		["targetMark"] = function(m) return ExRT.F.GetRaidTargetText(m,0) end,
		["sourceMarkNum"] = function(_,t) return t.sourceMark or 0 end,
		["targetMarkNum"] = function(_,t) return t.targetMark or 0 end,
		["health"] = function(_,t)
			return function(accuracy,...)
				if accuracy then
					local a,b = accuracy:match("^(%d+)(.-)$")
					return format("%."..(a or "1").."f",t.health)..(b or "")..strjoin(":",...), true
				else
					return format("%.1f",t.health)
				end
			end
		end,
		["value"] = function(_,t) return function() return t.value and format("%d",t.value) or "" end end,
		["auraValA"] = function(_,t) return function() return t._auraData and t._auraData[8] or "" end end,
		["auraValB"] = function(_,t) return function() return t._auraData and t._auraData[9] or "" end end,
		["auraValC"] = function(_,t) return function() return t._auraData and t._auraData[10] or "" end end,
		["textModIcon"] = function(_,t)
			return function(iconSize,repeatNum,otherStr)
				if not iconSize or not repeatNum then
					return t.text or ""
				end
				local isPass = not otherStr
				local t = t.text or ""
				if not isPass then
					local c = 1
					local tf = select(c,strsplit(";",otherStr))
					while tf do
						if t:find(tf) then
							isPass = true
							break
						end
						c = c + 1
						tf = select(c,strsplit(";",otherStr))
					end
				end
				if isPass then
					repeatNum = tonumber(repeatNum)
					t = t:gsub("{spell:(%d+):?(%d*)}",("{spell:%1:"..iconSize.."}"):rep(repeatNum))
					return t
				else
					return t
				end
			end
		end,
		["text"] = function(v,_,t)
			if t and t._trigger.event == 19 then
				if v and v:find("^{spell:[^}]+}$") then
					return v:rep(3)
				else
					return v
				end
			else
				return v
			end
		end,
	}
	local valsAdditional = {
		{"sourceMarkNum","sourceMark"},
		{"targetMarkNum","targetMark"},
		{"textModIcon","text"},
		{"auraValA","_auraData"},
		{"auraValB","_auraData"},
		{"auraValC","_auraData"},
	}
	local valsAdditionalFull = {
	}

	local function CancelSoundTimers(self)
		for i=1,#self do
			self[i]:Cancel()
		end
	end

	function module:ShowReminder(trigger)
		local data, reminder = trigger._data, trigger._reminder
		if module.db.debug then print('ShowReminder',data.name,date("%X",time())) end
		if module.db.debugLog then module:DebugLogAdd("ShowReminder",trigger._data.name or trigger._data.msg) end

		local params = {_data = data,_reminder = reminder,_trigger = trigger,_status = trigger.status}
		for j=1,#reminder.triggers do
			local trigger = reminder.triggers[j]
			if trigger.status then
				for k,v in pairs(trigger.status) do
					if valsExtra[k] then
						v = valsExtra[k](v,trigger.status,trigger)
					end
					params[k..j] = v
					if not params[k] then
						params[k] = v
					end
				end
				for _,k in pairs(valsAdditional) do
					if type(k)~="table" or trigger.status[ k[2] ] then
						k = type(k) == "table" and k[1] or k
						local v = valsExtra[k](nil,trigger.status,trigger)
						params[k..j] = v
						if not params[k] then
							params[k] = v
						end
					end
				end
			else
				if trigger.count then
					params["counter"..j] = trigger.count
				end
			end
			for _,k in pairs(valsAdditionalFull) do
				local v = valsExtra[k](nil,trigger.status,trigger)
				params[k..j] = v
				if not params[k] then
					params[k] = v
				end
			end
		end

		if data.specialTarget then
			local guid
			local sourcedest,triggerNum = data.specialTarget:match("^%%([^%d]+)(%d+)")
			if (sourcedest == "source" or sourcedest == "target") and triggerNum then
				guid = params[(sourcedest == "source" and "sourceGUID" or "targetGUID")..triggerNum]
			else
				guid = UnitGUID(data.specialTarget)
			end
			if guid then
				params.guid = guid
			end
		end
		--if module.db.debug and data.debug then
		--	print("Activate unit",params.guid)
		--end

		if data.extraCheck then
			local isPass,isValid = module:ExtraCheckParams(data.extraCheck,params)
			if isValid and not isPass then
				return
			end
		end

		if reminder.delayedActivation then
			for i=1,#reminder.delayedActivation do
				local t = ScheduleTimer(module.ShowReminderVisual, reminder.delayedActivation[i], self, trigger, data, reminder, params)
				module.db.timers[#module.db.timers+1] = t
			end
		else
			module:ShowReminderVisual(trigger,data,reminder,params)
		end
	end

	function module:ShowReminderVisual(trigger,data,reminder,params)

		--hide all showed copies
		if not data.copy then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == data then
					if data.norewrite then
						return
					end
					if showed.voice then
						showed.voice:Cancel()
					end
					tremove(module.db.showedReminders,j)
				end
			end
		end

		local reminderDuration = trigger.status and trigger.status._customDuration or data.duration or 2

		--stop duplicates for untimed text reminders
		if data.copy and reminderDuration == 0 then
			for j=#module.db.showedReminders,1,-1 do
				local showed = module.db.showedReminders[j]
				if showed.data == data and ((params.guid and showed.params and showed.params.guid == params.guid) or (params.uid and showed.params and showed.params.uid == params.uid)) then
					return
				end
			end
		end

		local now = GetTime()

		reminder.params = params

		if data.msg and data.msg:find("{setparam:") then
			module:FormatMsg(data.msg or "",params)
		end

		if data.glow and data.glow ~= "" then
			module:ParseGlow(data,params)
		end

		if data.nameplateGlow then
			if params.guid then
				if reminder.nameplateguid then
					module:NameplateRemoveHighlight(reminder.nameplateguid)
				end
				local frame = module:NameplateAddHighlight(params.guid,data,params)
				if not data.copy then
					--	reminder.nameplateguid = params.guid
				end
				if reminderDuration ~= 0 then
					module.db.timers[#module.db.timers+1] = ScheduleTimer(module.NameplateRemoveHighlight, reminderDuration, module, params.guid, data.uid)
				end
			end
		end

		if data.sendEvent and data.msg and WeakAuras then
			module:SendWeakAurasCustomEvent(data.msg)
		end

		if data.tts and not VExRT.Reminder.disableSound and not VExRT.Reminder.disableSounds[data.token] then
			local LibTranslit = LibStub("LibTranslit-1.0")
            local message = module:FormatMsg(data.tts or "",params)
			C_VoiceChat.SpeakText(
				VExRT.Reminder.ttsVoice,
				isTtsTranslateNeeded and LibTranslit:Transliterate(message) or message,
				Enum.VoiceTtsDestination.QueuedLocalPlayback,
				VExRT.Reminder.ttsVoiceRate,
				VExRT.Reminder.ttsVoiceVolume)
		end

		if data.sound and not VExRT.Reminder.disableSound and not VExRT.Reminder.disableSounds[data.token] then
			pcall(PlaySoundFile, data.sound, "Master")
		end

		if data.spamType and data.spamChannel then
			module:SayChatSpam(data, params)
		end

		if data.sendEvent then
			return
		end --finish

		local t = {
			data = data,
			expirationTime = now + (reminderDuration == 0 and 86400 or reminderDuration or 2),
			params = params,
			dur = reminderDuration,
		}
		module.db.showedReminders[#module.db.showedReminders+1] = t
		if data.voiceCountdown and reminderDuration ~= 0 and reminderDuration >= 1.3 then
			local clist = {Cancel = CancelSoundTimers}
			local soundTemplate = module.datas.vcdsounds[ data.voiceCountdown ]
			if soundTemplate then
				for i=1,min(5,reminderDuration-0.3) do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = ScheduleTimer(PlaySoundFile, reminderDuration-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
					clist[#clist+1] = tmr
				end
				t.voice = clist
			end
		end

		frame:Show()
	end
end

function module:CheckUnitTriggerStatus(trigger)
	for guid in pairs(trigger.statuses) do
		if UnitGUID(trigger.units[guid]) ~= guid then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			module:DeactivateTrigger(trigger, guid)
		end
	end
end

function module:CheckUnitTriggerStatusOnDeactivating(trigger)
	for guid in pairs(trigger.statuses) do
		if UnitGUID(trigger.units[guid]) ~= guid then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			if not trigger.ignoreManualOff then
				trigger.active[guid] = nil
			end
		end
	end
end

function module:DeactivateTrigger(trigger, uid, isScheduled)
	if trigger.delays and #trigger.delays > 0 then
		for j=#trigger.delays,1,-1 do
			local delayTimer = trigger.delays[j]
			if not uid or delayTimer.args[3].uid == uid or delayTimer.args[3].guid == uid then
				delayTimer:Cancel()
				tremove(trigger.delays, j)
			end
		end
	end

	if not trigger.active[uid or 1] then
		return
	end
	if trigger.ignoreManualOff and not isScheduled then
		return
	end
	if module.db.debugLog then module:DebugLogAdd("DeactivateTrigger",trigger._data.name or trigger._data.msg,uid) end

	trigger.active[uid or 1] = nil

	if trigger.untimed and trigger.units then	--??? double recheck for units
		module:CheckUnitTriggerStatusOnDeactivating(trigger)
	end

	local status = false
	for _ in pairs(trigger.active) do
		status = true
		break
	end
	if not status then
		trigger.status = false
		module:CheckAllTriggers(trigger)
	elseif uid and trigger._data.duration == 0 then --and (trigger._data.copy) then
		for j=#module.db.showedReminders,1,-1 do
			local showed = module.db.showedReminders[j]
			if showed.data == trigger._data and showed.params and (showed.params.uid == uid or showed.params.guid == uid) then
				if showed.voice then
					showed.voice:Cancel()
				end
				tremove(module.db.showedReminders,j)
			end
		end
		for j=1,#module.db.GlowCancelTimers do
			local glow = module.db.GlowCancelTimers[j]
			if glow and glow.data == trigger._data and
				glow.params and (glow.params.uid == uid or glow.params.guid == uid) then
				if not glow.timer then
					LCG.PixelGlow_Stop(glow.unitFrame)
					LCG.AutoCastGlow_Stop(glow.unitFrame)
					LCG.ProcGlow_Stop(glow.unitFrame)
					LCG.ButtonGlow_Stop(glow.unitFrame)

					tremove(module.db.GlowCancelTimers,j)
				end
			end
		end
		if trigger._data.nameplateGlow then
			module:NameplateRemoveHighlight(uid, trigger._data.uid)
		end
	end
end

function module:ParseNoteTimers(phaseNum,doCLEU,globalPhaseNum,ignoreName)
	local playerName = ExRT.SDB.charName
	local playerClass = select(2,UnitClass'player'):lower()
	local data = {}

	local lines = GetMRTNoteLines()
	for i=1,#lines do
		if lines[i]:find("{time:[^}]+}") then
			local l = lines[i]:gsub(" *$",""):gsub(" +"," ")
			local list = {strsplit(" ", l)}
			for j=1,#list do
				if (list[j]:gsub("|c........",""):gsub("|r",""):gsub("|","") == playerName) or ignoreName then
					local fulltime,subOpts = l:match("{time:([0-9:%.]+)([^{}]*)}")
					local phase
					local difftime,difflen = 0
					local isDisabled, isCLEU, isGlobalPhaseCounter
					if subOpts then
						for w in string_gmatch(subOpts,"[^,]+") do
							local igp,pf = w:match("^p(g?)([%d%.]+)$")
							if pf then
								phase = tonumber(pf)
							end
							if igp then
								isGlobalPhaseCounter = true
							end
							local a,b,c = strsplit(":",w)
							if a == "diff" and b and (b == playerName or b:lower() == playerClass) and c then
								difftime = difftime + (tonumber(c) or 0)
							end
							if a == "difflen" and b and (b == playerName or b:lower() == playerClass) and c then
								difflen = tonumber(c)
							end
							if w == "off" then
								isDisabled = true
							elseif w:find("^S[CA][CSAR]:") then
								isCLEU = w
							end
						end
					end
					if not isDisabled and ((doCLEU and isCLEU) or (not doCLEU and not isCLEU)) then
						local line2 = l:gsub("{time[^}]+}",""):gsub("{0}.-{/0}","")
						local prefix = line2:match("([^ ]+) +[^ ]*"..playerName) or ""
						if prefix:find("_$") then
							local prefix2 = line2:match("(%b__) +[^ ]*"..playerName)
							if prefix2 then
								prefix = prefix2:sub(2,-2)
							end
						end
						if prefix:find("^%(") then prefix = prefix:sub(2) end

						local suffix = line2:match(playerName.."[^ ]* +([^ ]+)") or ""
						if suffix:find("^_") then
							local suffix2 = line2:match(playerName.."[^ ]* +(%b__)")
							if suffix2 then
								suffix = suffix2:sub(2,-2)
							end
						end

						local phaseCheck = isGlobalPhaseCounter and globalPhaseNum or phaseNum

						data[#data+1] = {
							time = fulltime,
							phaseMatch = phaseCheck == tostring(phase or 1),
							textRight = suffix,
							textLeft = prefix,
							fullLine = l,
							phase = phase,
							diffTime = difftime,
							diffLen = difflen or nil,
							cleu = isCLEU,
						}
					end
					break
				end
			end
		end
	end

	return data
end

function module:TriggerBossPhase(phaseText,globalPhaseNum)
	local phaseNum = phaseText:match("%d+%.?%d*")

	if module.db.eventsToTriggers.BOSS_PHASE then
		local triggers = module.db.eventsToTriggers.BOSS_PHASE
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				triggerData.pattFind
			then
				local phaseCheck = (phaseNum == triggerData.pattFind or phaseText:find(triggerData.pattFind,1,true))

				if not trigger.statuses[1] and phaseCheck then
					module:AddTriggerCounter(trigger)
					local vars = {
						phase = phaseText,
						counter = trigger.count,
					}
					trigger.statuses[1] = vars
					if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
						module:RunTrigger(trigger, vars)
					end
				elseif trigger.statuses[1] and not phaseCheck then
					trigger.statuses[1] = nil
					module:DeactivateTrigger(trigger)
				end
			end
		end
	end
	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and VMRT and VMRT.Note and VMRT.Note.Text1 and phaseNum then

		for _,event_name in pairs({"NOTE_TIMERS","NOTE_TIMERS_ALL"}) do
			local triggers = module.db.eventsToTriggers[event_name]
			if triggers then
				local data = module:ParseNoteTimers(phaseNum,false,globalPhaseNum,event_name == "NOTE_TIMERS_ALL")
				for i=1,#triggers do
					local trigger = triggers[i]
					for j=1,#data do
						local now = data[j]
						trigger.DdelayTime = module:ConvertMinuteStrToNum(now.time)
						if trigger.DdelayTime then
							for k=1,#trigger.DdelayTime do
								trigger.DdelayTime[k] = max(trigger.DdelayTime[k] - (trigger._trigger.bwtimeleft or 0) + now.diffTime,0.01)
							end
						end
						local uid = event_name .. ":" .. i .. ":" .. (now.phase or "0") .. ":" .. j

						if not trigger.statuses[uid] and now.phaseMatch then

							local vars = {
								phase = phaseText,
								counter = 0,
								text = now.textRight,
								textLeft = now.textLeft,
								fullLine = now.fullLine,
								fullLineClear = (now.fullLine or ""):gsub("[{}]",""),
								uid = uid,
							}

							if now.diffLen then
								vars._customDuration = max((trigger._data.dur or 2) + now.diffLen,0.01)
							end
							trigger.statuses[uid] = vars
							module:RunTrigger(trigger, vars)
						elseif trigger.statuses[uid] and not now.phaseMatch then
							trigger.statuses[uid] = nil
							if now.phase then
								module:DeactivateTrigger(trigger, uid)
							end
						end
					end
				end
			end
		end
	end
end

--/run GExRT.A.Reminder:TriggerBossPhase("1")

function module:TriggerBossPull(encounterID, encounterName)
	local triggers = module.db.eventsToTriggers.BOSS_START
	if triggers then
		for i=1,#triggers do
			module:RunTrigger(triggers[i])
		end
	end
	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and VMRT and VMRT.Note and VMRT.Note.Text1 then

		for _,event_name in pairs({"NOTE_TIMERS","NOTE_TIMERS_ALL"}) do
			local triggers = module.db.eventsToTriggers[event_name]
			if triggers then
				local data = module:ParseNoteTimers(0,true,nil,event_name == "NOTE_TIMERS_ALL")
				for j=1,#data do
					local now = data[j]

					local prefix,spellID,counter = strsplit(":",now.cleu)
					local event =
						prefix == "SCC" and "SPELL_CAST_SUCCESS" or
						prefix == "SCS" and "SPELL_CAST_START" or
						prefix == "SAA" and "SPELL_AURA_APPLIED" or
						prefix == "SAR" and "SPELL_AURA_REMOVED"
					if event and spellID and tonumber(spellID) and counter and tonumber(counter) then
						local triggerOverwrite = {
							Dcounter = counter ~= "0" and module:CreateNumberConditions(counter) or false,
							DsourceName = false,
							DsourceID = false,
							DtargetName = false,
							DtargetID = false,
							Dstacks = false,
							untimed = false,
						}
						local triggerDataOverwrite = {
							spellID = tonumber(spellID),
							spellName = false,
							sourceMark = false,
							sourceUnit = false,
							targetMark = false,
							targetUnit = false,
							extraSpellID = false,
							pattFind = false,
							cbehavior = false,
						}

						for i=1,#triggers do
							local trigger = triggers[i]
							local triggerData = trigger._trigger

							local DdelayTime = module:ConvertMinuteStrToNum(now.time)
							if DdelayTime then
								for k=1,#DdelayTime do
									DdelayTime[k] = max(DdelayTime[k] - (triggerData.bwtimeleft or 0) + now.diffTime,0.01)
								end
							end
							local dataTable = {count = 0}

							local newData = setmetatable({},{__index = function(_,a)
									if type(triggerDataOverwrite[a]) == "boolean" then
										return triggerDataOverwrite[a]
									end
									return triggerDataOverwrite[a] or triggerData[a]
								end})

							local new = setmetatable({},{__index = function(_,a)
									if a == "_trigger" then
										return newData
									elseif a == "DdelayTime" then
										return DdelayTime
									elseif a == "status" then
										return trigger.status
									elseif a == "count" then
										return dataTable.count
									else
										if type(triggerOverwrite[a]) == "boolean" then
											return triggerOverwrite[a]
										end
										return triggerOverwrite[a] or trigger[a]
									end
								end, __newindex = function(_,a,v)
									if a == "status" then
										trigger.status = v
										if type(v) == "table" then
											v.text = now.textRight
											v.textLeft = now.textLeft
											v.fullLine = now.fullLine
										end
									elseif a == "count" then
										dataTable.count = v
										trigger.count = v
									end
								end})
							tCOMBAT_LOG_EVENT_UNFILTERED[event] = tCOMBAT_LOG_EVENT_UNFILTERED[event] or {}
							tCOMBAT_LOG_EVENT_UNFILTERED[event][#tCOMBAT_LOG_EVENT_UNFILTERED[event]+1] = new
						end
					end
				end
			end
		end
	end
end
--/run GExRT.A.Reminder:TriggerBossPull()

function module:TriggerHPLookup(unit,triggers,hp,hpValue)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DtargetName or name and trigger.DtargetName[name]) and
			(not trigger.DtargetID or trigger.DtargetID(guid)) and
			(type(triggerData.targetUnit) ~= "number" or triggerData.targetUnit >= 0 or module:CheckUnit(triggerData.targetUnit,guid,trigger))
		then
			local hpCheck =
				(not triggerData.targetMark or (GetRaidTargetIndex(unit) or 0) == triggerData.targetMark) and
				trigger.DnumberPercent and module:CheckNumber(trigger.DnumberPercent,hp)

			if not trigger.statuses[guid] and hpCheck then
				trigger.countsD[guid] = (trigger.countsD[guid] or 0) + 1
				module:AddTriggerCounter(trigger,nil,trigger.countsD[guid])
				local vars = {
					targetName = UnitName(unit),
					targetMark = GetRaidTargetIndex(unit),
					guid = guid,
					counter = trigger.count,
					health = hp,
					value = hpValue,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not hpCheck then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end

			if trigger.statuses[guid] then
				trigger.statuses[guid].health = hp
				trigger.statuses[guid].value = hpValue
			end
		end
	end
end

function module.main:UNIT_HEALTH(unit)
	local triggers = tUNIT_HEALTH[unit]
	if triggers then
		local hpMax = UnitHealthMax(unit)
		if hpMax == 0 then
			module:TriggerHPLookup(unit,triggers,0)
			return
		end
		local hpNow = UnitHealth(unit)
		local hp = hpNow / hpMax * 100
		module:TriggerHPLookup(unit,triggers,hp,hpNow)
	end
end

function module.main:UNIT_POWER_FREQUENT(unit)
	local triggers = tUNIT_POWER_FREQUENT[unit]
	if triggers then
		local powerMax = UnitPowerMax(unit)
		if powerMax == 0 then
			module:TriggerHPLookup(unit,triggers,0)
			return
		end
		local powerNow = UnitPower(unit)
		local power = powerNow / powerMax * 100
		module:TriggerHPLookup(unit,triggers,power,powerNow)
	end
end

function module.main:UNIT_ABSORB_AMOUNT_CHANGED(unit)
	local triggers = tUNIT_ABSORB_AMOUNT_CHANGED[unit]
	if triggers then
		local absorbs = UnitGetTotalAbsorbs(unit)
		module:TriggerHPLookup(unit,triggers,absorbs,absorbs)
	end
end

function module:TriggerChat(text, sourceName, sourceGUID, targetName)
	local triggers = module.db.eventsToTriggers.CHAT_MSG
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		--print(sourceGUID, triggerData.sourceUnit, module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger))
		if
			triggerData.pattFind and
			text:find(triggerData.pattFind,1,true) and
			(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
			(not trigger.DsourceID or not sourceGUID or trigger.DsourceID(sourceGUID)) and
			(not triggerData.sourceUnit or not sourceGUID or module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger)) and
			(not trigger.DtargetName or targetName and trigger.DtargetName[targetName]) and
			(not triggerData.targetUnit or not targetName or (UnitGUID(targetName) and module:CheckUnit(triggerData.targetUnit,UnitGUID(targetName),trigger)))
		then
			module:AddTriggerCounter(trigger)
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				if sourceName and sourceName:find("%-") and UnitName(strsplit("-",sourceName),nil) then
					sourceName = strsplit("-",sourceName)
				end
				if targetName and targetName:find("%-") and UnitName(strsplit("-",targetName),nil) then
					targetName = strsplit("-",targetName)
				end
				local vars = {
					sourceName = sourceName,
					targetName = targetName,
					counter = trigger.count,
					guid = sourceGUID or UnitGUID(sourceName or ""),
					text = text,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end

	-- if IsHistoryEnabled then
	-- module:AddHistoryRecord(8, text, sourceName, sourceGUID, targetName)
	-- end
end

local function CHAT_MSG(self, text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons)
	module:TriggerChat(text, playerName, guid, playerName2)
end

module.main.CHAT_MSG_RAID_WARNING = CHAT_MSG
module.main.CHAT_MSG_MONSTER_YELL = CHAT_MSG
module.main.CHAT_MSG_MONSTER_EMOTE = CHAT_MSG
module.main.CHAT_MSG_MONSTER_SAY = CHAT_MSG
module.main.CHAT_MSG_MONSTER_WHISPER = CHAT_MSG
module.main.CHAT_MSG_RAID_BOSS_EMOTE = CHAT_MSG
module.main.CHAT_MSG_RAID_BOSS_WHISPER = CHAT_MSG
module.main.CHAT_MSG_RAID = CHAT_MSG
module.main.CHAT_MSG_RAID_LEADER = CHAT_MSG
module.main.CHAT_MSG_PARTY = CHAT_MSG
module.main.CHAT_MSG_PARTY_LEADER = CHAT_MSG
module.main.CHAT_MSG_WHISPER = CHAT_MSG

local function RAID_MSG(self, text, playerName, displayTime, enableBossEmoteWarningSound)
	module:TriggerChat(text)
end

module.main.RAID_BOSS_EMOTE = RAID_MSG
module.main.RAID_BOSS_WHISPER = RAID_MSG

function module:TriggerBossFrame(targetName, targetGUID, targetUnit)
	local triggers = module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT
	if triggers then
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				(not trigger.DtargetName or targetName and trigger.DtargetName[targetName]) and
				(not trigger.DtargetID or trigger.DtargetID(targetGUID)) and
				(not triggerData.targetUnit or triggerData.targetUnit == targetUnit)
			then
				trigger.countsD[targetGUID] = (trigger.countsD[targetGUID] or 0) + 1
				module:AddTriggerCounter(trigger,nil,trigger.countsD[targetGUID])
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					local vars = {
						targetName = targetName,
						counter = trigger.count,
						guid = targetGUID,
						uid = module:GetNextUID(),
					}
					module:RunTrigger(trigger, vars)
				end
			end
		end
	end


	-- if IsHistoryEnabled then
	history[#history+1] = {GetTime(),"UNIT_ENGAGE",targetName,targetGUID,targetUnit}
	-- module:AddHistoryRecord(9, targetName, targetGUID, targetUnit)
	-- end
end

local bossFramesblackList = {}
module.db.bossFramesblackList = bossFramesblackList
function module.main:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	for _,unit in pairs(module.datas.unitsList[1]) do
		local guid = UnitGUID(unit)
		if guid then
			if not bossFramesblackList[guid] then
				bossFramesblackList[guid] = true
				local name = UnitName(unit) or ""
				module:TriggerBossFrame(name, guid, unit)
			end
			module:CycleAllUnitEvents(unit)
		end
		module:CycleAllUnitEvents_UnitRefresh(unit)
	end
end

function module:CycleAllUnitEvents(unit)
	if UnitGUID(unit) then
		if tUNIT_HEALTH then module.main:UNIT_HEALTH(unit) end
		if tUNIT_POWER_FREQUENT then module.main:UNIT_POWER_FREQUENT(unit) end
		if tUNIT_ABSORB_AMOUNT_CHANGED then module.main:UNIT_ABSORB_AMOUNT_CHANGED(unit) end
		if tUNIT_AURA then module.main:UNIT_AURA(unit) end
		if tUNIT_TARGET then module.main:UNIT_TARGET(unit) end
		if tUNIT_CAST then module.main:UNIT_CAST_CHECK(unit) end
	end
end


function module:TriggerUnitRemovedLookup(unit,triggers,guid)
	guid = guid or UnitGUID(unit)
	for i=1,#triggers do
		local trigger = triggers[i]

		if trigger.statuses[guid] then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil
			module:DeactivateTrigger(trigger,guid)
		end
	end
end

do
	local tablesList = {"UNIT_HEALTH","UNIT_POWER_FREQUENT","UNIT_ABSORB_AMOUNT_CHANGED","UNIT_TARGET","UNIT_AURA","UNIT_CAST"}
	function module:CycleAllUnitEvents_UnitRefresh(unit)
		for _,e in pairs(tablesList) do
			if module.db.eventsToTriggers[e] then
				local triggers = module.db.eventsToTriggers[e][unit]
				if triggers then
					for i=1,#triggers do
						local trigger = triggers[i]

						module:CheckUnitTriggerStatus(trigger)
					end
				end
			end
		end
	end

	function module:CycleAllUnitEvents_UnitRemoved(unit, guid)
		for _,e in pairs(tablesList) do
			if module.db.eventsToTriggers[e] then
				local triggers = module.db.eventsToTriggers[e][unit]
				if triggers then
					module:TriggerUnitRemovedLookup(unit,triggers,guid)
				end
			end
		end
	end
end

do
	local scheduled = nil
	local function scheduleFunc()
		scheduled = nil
		for _,unit in pairs(module.datas.unitsList[1]) do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in pairs(module.datas.unitsList[2]) do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in pairs(module.datas.unitsList[3]) do
			module:CycleAllUnitEvents(unit)
		end
		for _,unit in pairs(module.datas.unitsList[4]) do
			module:CycleAllUnitEvents(unit)
		end
	end
	function module.main:RAID_TARGET_UPDATE()
		if not scheduled then
			scheduled = C_Timer.NewTimer(0.05,scheduleFunc)
		end
	end
end

do
	local prev
	function module.main:PLAYER_TARGET_CHANGED()
		local guid = UnitGUID("target")
		if guid then
			module:CycleAllUnitEvents("target")
			prev = guid
		else
			module:CycleAllUnitEvents_UnitRemoved("target", prev)
			prev = nil
		end
	end
end

do
	local prev
	function module.main:PLAYER_FOCUS_CHANGED()
		local guid = UnitGUID("focus")
		if guid then
			module:CycleAllUnitEvents("focus")
			prev = guid
		else
			module:CycleAllUnitEvents_UnitRemoved("focus", prev)
			prev = nil
		end
	end
end

do
	local prev
	local mouseoverframe = CreateFrame("Frame")
	local function mouseoverframe_onupdate()
		local guid = UnitGUID("mouseover")
		if not guid then
			mouseoverframe:SetScript("OnUpdate",nil)
			module:CycleAllUnitEvents_UnitRemoved("mouseover", prev)
			prev = nil
		end
	end
	function module.main:UPDATE_MOUSEOVER_UNIT()
		local guid = UnitGUID("mouseover")
		if guid then
			module:CycleAllUnitEvents("mouseover")
			prev = guid
			mouseoverframe:SetScript("OnUpdate",mouseoverframe_onupdate)
		end
	end
end

function module.main:NAME_PLATE_UNIT_ADDED(unit)
	module:CycleAllUnitEvents(unit)
	local guid = UnitGUID(unit)
	if guid then
		module.db.nameplateGUIDToUnit[guid] = unit
		local data = module.db.nameplateHL[guid]
		if data then
			module:NameplateUpdateForUnit(unit, guid, data)
		end
	end
end

function module.main:NAME_PLATE_UNIT_REMOVED(unit)
	module:CycleAllUnitEvents_UnitRemoved(unit)
	local guid = UnitGUID(unit)
	if guid then
		module.db.nameplateGUIDToUnit[guid] = nil
		module:NameplateHideForGUID(guid)
	end
end

function module:NameplatesReloadCycle()
	for _,unit in pairs(module.datas.unitsList[2]) do
		if UnitGUID(unit) then
			module.main:NAME_PLATE_UNIT_ADDED(unit)
		end
	end
end

function module:NameplateUpdateForUnit(unit, guid, guidTable)
	local nameplate = C_NamePlate.GetNamePlateForUnit(unit)
	if not nameplate then
		return
	end
	module:NameplateHideForGUID(guid)
	if guidTable then
		for uid,data in pairs(guidTable) do
			local frame = module:GetNameplateFrame(nameplate,data.text,data.textUpdateReq,data.color,data.noEdge,data.thick,data.type,data.customN,data.scale,data.textSize,data.posX,data.posY,data.pos,data.glowImage)
			module.db.nameplateGUIDToFrames[guid] = frame
			break
		end
	end
end

function module:NameplateHideForGUID(guid)
	local frame = module.db.nameplateGUIDToFrames[guid]
	if frame then
		frame:Hide()
		module.db.nameplateGUIDToFrames[guid] = nil
	end
end

function module:NameplateAddHighlight(guid,data,params)
	if module.db.nameplateHL[guid] and module.db.nameplateHL[guid][data and data.uid or 1] then
		return
	end
	local t = {
		data = data,
	}
	if data and data.nameplateText then
		local text = data.nameplateText

		if text:find("%%tsize:%d+") then
			local tsize = text:match("%%tsize:(%d+)")
			t.textSize = tonumber(tsize)
			text = text:gsub("%%tsize:%d+","")
		end

		if text:find("%%tposx:%-?%d+") then
			local posX = text:match("%%tposx:(%-?%d+)")
			t.posX = tonumber(posX)
			text = text:gsub("%%tposx:%-?%d+","")
		end

		if text:find("%%tposy:%-?%d+") then
			local posY = text:match("%%tposy:(%-?%d+)")
			t.posY = tonumber(posY)
			text = text:gsub("%%tposy:%-?%d+","")
		end

		if text:find("%%tpos:%d+") then
			local pos = text:match("%%tpos:(%d+)")
			t.pos = tonumber(pos)
			text = text:gsub("%%tpos:%d+","")
		end

		t.text, t.textUpdateReq = module:FormatMsg(text,params)
		if t.textUpdateReq and not data.dynamicdisable then
			t.textUpdateReq = function()
				return module:FormatMsg(text,params)
			end
		else
			t.textUpdateReq = nil
		end
	end
	if data and data.glowType then
		t.type = data.glowType
	end
	if data and data.glowScale then
		t.scale = data.glowScale
	end
	if data and data.glowN then
		t.customN = data.glowN
	end
	if data and data.glowThick then
		t.thick = data.glowThick
	end
	if data and data.glowColor then
		local a,r,g,b = data.glowColor:match("(..)(..)(..)(..)")
		if r and g and b and a then
			a,r,g,b = tonumber(a,16),tonumber(r,16),tonumber(g,16),tonumber(b,16)
			t.color = {r/255,g/255,b/255,a/255}
		end
	end
	if data and data.glowImage then
		t.glowImage = data.glowImage
	end
	if data and data.glowOnlyText then
		t.noEdge = true
	end
	if not module.db.nameplateHL[guid] then
		module.db.nameplateHL[guid] = {}
	end
	module.db.nameplateHL[guid][data and data.uid or 1] = t
	local unit = module.db.nameplateGUIDToUnit[guid]
	if unit then
		module:NameplateUpdateForUnit(unit, guid, module.db.nameplateHL[guid])
	end
end

function module:NameplateRemoveHighlight(guid, uid)
	module:NameplateHideForGUID(guid)
	local hl_data = module.db.nameplateHL[guid]
	if hl_data then
		for c_uid,data in pairs(hl_data) do
			if not uid or c_uid == uid then
				hl_data[c_uid] = nil
			end
		end
	end
	local unit = module.db.nameplateGUIDToUnit[guid]
	if unit then
		module:NameplateUpdateForUnit(unit, guid, hl_data)
	end
end

local function NameplateFrame_OnUpdate(self)
	if GetTime() > self.expirationTime then
		self:Hide()
	end
end
local function NameplateFrame_SetExpiration(self,expirationTime)
	self.expirationTime = expirationTime
	self:SetScript("OnUpdate",NameplateFrame_OnUpdate)
end
local function NameplateFrame_OnHide(self)
	local LCG = LibStub("LibCustomGlow-1.0",true)
	if LCG then
		LCG.ButtonGlow_Stop(self)
		LCG.AutoCastGlow_Stop(self)
		LCG.ProcGlow_Stop(self)
		LCG.PixelGlow_Stop(self)
	end
	self.textUpate:Hide()
	self.textUpate.tmr = 0

	self.aim1:Hide()
	self.aim2:Hide()
	self.imgabove:Hide()

	self:SetScript("OnUpdate",nil)
end

local function NameplateFrame_TextUpdate(self, elapsed)
	self.tmr = self.tmr + elapsed
	if self.tmr > 0.03 then
		self.tmr = 0
		self.text:SetText( self.func() )
	end
end

local function NameplateFrame_OnScaleCheck(self,elapsed)
	self.tmr = self.tmr - elapsed
	if self.tmr <= 0 then
		self:SetScript("OnUpdate",nil)
	end
	local p = self:GetParent()
	local s1,s2 = p:GetSize()
	if p.s1 ~= s1 or p.s2 ~= s2 then
		p.s1,p.s2 = s1,s2
		p:UpdateGlow()
	end
end
local function NameplateFrame_OnShow(self)
	if not self.frameNP then
		return
	end
	if not self.scalecheck then
		self.scalecheck = CreateFrame("Frame",nil,self)
		self.scalecheck:SetPoint("TOPLEFT",0,0)
		self.scalecheck:SetSize(1,1)
	end
	self.scalecheck.tmr = 1
	if self.glow_customGlowType == 7 then
		self.scalecheck.tmr = 10000
	end
	self.scalecheck:SetScript("OnUpdate",NameplateFrame_OnScaleCheck)
end

local function NameplateFrame_UpdateGlow(frame)
	local color,noEdge,customThick,customGlowType,customN,customScale,glowImage = frame.glow_color,frame.glow_noEdge,frame.glow_customThick,frame.glow_customGlowType,frame.glow_customN,frame.glow_customScale,frame.glow_glowImage

	local LCG = LibStub("LibCustomGlow-1.0",true)
	if noEdge then
		return
	end

	local glowType = customGlowType or VExRT.Reminder.NameplateGlowType
	if glowType == 2 then
		if not LCG then return end
		LCG.ButtonGlow_Start(frame,color)
	elseif glowType == 3 then
		if not LCG then return end
		LCG.AutoCastGlow_Start(frame,color,customN,nil,customScale or 1)

	elseif glowType == 4 then
		if not LCG then return end
		LCG.ProcGlow_Start(frame,{color=color},nil,true)
	elseif glowType == 5 then
		if color then
			frame.aim1:SetVertexColor(unpack(color))
			frame.aim2:SetVertexColor(unpack(color))
		else
			frame.aim1:SetVertexColor(1,1,1,1)
			frame.aim2:SetVertexColor(1,1,1,1)
		end
		if customThick then
			frame.aim1:SetWidth(customThick)
			frame.aim2:SetHeight(customThick)
		else
			frame.aim1:SetWidth(2)
			frame.aim2:SetHeight(2)
		end
		frame.aim1:Show()
		frame.aim2:Show()
	elseif glowType == 6 then
		if color then
			frame.solid:SetColorTexture(unpack(color))
		else
			frame.solid:SetColorTexture(1,1,1,1)
		end
		frame.solid:Show()
	elseif glowType == 7 then
		local imgData = module.datas.glowImagesData[glowImage or 0]
		if imgData or type(glowImage)=='string' then
			if imgData then
				frame.imgabove:SetTexture(imgData[3])
				frame.imgabove:SetSize((imgData[4] or 80)*(customScale or 1),(imgData[5] or 80)*(customScale or 1))
				if imgData[6] then
					frame.imgabove:SetTexCoord(unpack(imgData[6]))
				else
					frame.imgabove:SetTexCoord(0,1,0,1)
				end
			else
				frame.imgabove:SetSize(80*(customScale or 1),80*(customScale or 1))
				if type(glowImage)=='string' and glowImage:find("^A:") then
					frame.imgabove:SetTexCoord(0,1,0,1)
					frame.imgabove:SetAtlas(glowImage:sub(3))
				else
					frame.imgabove:SetTexture(glowImage)
					frame.imgabove:SetTexCoord(0,1,0,1)
				end
			end
			if color then
				frame.imgabove:SetVertexColor(unpack(color))
			else
				frame.imgabove:SetVertexColor(1,1,1,1)
			end
			frame.imgabove:Show()
		end
	elseif glowType == 8 then
		customN = customN or 100
		frame.hpline:SetPoint("LEFT",customN/100*frame:GetWidth(),0)
		if color then
			frame.hpline:SetColorTexture(unpack(color))
		else
			frame.hpline:SetColorTexture(1,1,1,1)
		end
		frame.hpline.hp = customN/100
		frame.hpline:SetWidth(customThick or 3)
		frame.hpline:Show()
	else
		if not LCG then return end
		local thick = customThick or VExRT.Reminder.NameplateThick
		thick = tonumber(thick or 2)
		thick = floor(thick)
		LCG.PixelGlow_Start(frame,color,customN,nil,nil,thick,1,1)
	end
end

function module:GetNameplateFrame(nameplate,text,textUpdateReq,color,noEdge,customThick,customGlowType,customN,customScale,textSize,posX,posY,pos,glowImage)
	local frame
	for i=1,#module.db.nameplateFrames do
		if not module.db.nameplateFrames[i]:IsShown() then
			frame = module.db.nameplateFrames[i]
			break
		end
	end
	if not frame then
		frame = CreateFrame("Frame",nil,UIParent)
		module.db.nameplateFrames[#module.db.nameplateFrames+1] = frame
		frame:Hide()
		frame:SetScript("OnHide",NameplateFrame_OnHide)
		frame.SetExpiration = NameplateFrame_SetExpiration
		frame:SetScript("OnShow",NameplateFrame_OnShow)
		frame.UpdateGlow = NameplateFrame_UpdateGlow

		frame.text = frame:CreateFontString(nil,"ARTWORK")
		frame.text:SetPoint("BOTTOMLEFT",frame,"TOPLEFT",2,2)
		frame.text:SetFont(ExRT.F.defFont, 12, "OUTLINE")
		--frame.text:SetShadowOffset(1,-1)
		frame.text:SetTextColor(1,1,1,1)
		frame.text.size = 12

		frame.textUpate = CreateFrame("Frame",nil,frame)
		frame.textUpate:SetPoint("CENTER")
		frame.textUpate:SetSize(1,1)
		frame.textUpate:Hide()
		frame.textUpate.tmr = 0
		frame.textUpate.text = frame.text
		frame.textUpate:SetScript("OnUpdate",NameplateFrame_TextUpdate)

		frame.aim1 = frame:CreateTexture(nil, "ARTWORK")
		frame.aim1:SetColorTexture(1,1,1,1)
		frame.aim1:SetPoint("CENTER")
		frame.aim1:SetSize(2,3000)
		frame.aim1:Hide()
		frame.aim2 = frame:CreateTexture(nil, "ARTWORK")
		frame.aim2:SetColorTexture(1,1,1,1)
		frame.aim2:SetPoint("CENTER")
		frame.aim2:SetSize(3000,2)
		frame.aim2:Hide()

		frame.imgabove = frame:CreateTexture(nil, "ARTWORK")
		frame.imgabove:SetPoint("BOTTOM",frame,"TOP",0,1)
		frame.imgabove:Hide()

		frame.solid = frame:CreateTexture(nil,"ARTWORK")
		frame.solid:SetAllPoints()
		frame.solid:Hide()

		frame.hpline = frame:CreateTexture(nil,"ARTWORK")
		frame.hpline:SetPoint("TOP")
		frame.hpline:SetPoint("BOTTOM")
		frame.hpline:Hide()
	end
	local frameNP = (nameplate.unitFramePlater and nameplate.unitFramePlater.healthBar) or (nameplate.unitFrame and nameplate.unitFrame.Health) or (nameplate.UnitFrame and nameplate.UnitFrame.healthBar) or nameplate
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT",frameNP,0,0)
	frame:SetPoint("BOTTOMRIGHT",frameNP,0,0)
	frame:SetFrameStrata( nameplate:GetFrameStrata() )
	frame.solid:Hide()
	frame.hpline:Hide()
	frame.frameNP = frameNP

	frame.s1,frame.s2 = frame:GetSize()

	if textSize and frame.text.size ~= textSize then
		frame.text:SetFont(ExRT.F.defFont, textSize, "OUTLINE")
		frame.text.size = textSize
	elseif not textSize and frame.text.size ~= 12 then
		frame.text:SetFont(ExRT.F.defFont, 12, "OUTLINE")
		frame.text.size = 12
	end

	posX = posX or 2
	posY = posY or 2
	pos = pos or 1
	if frame.text.posX ~= posX or frame.text.posY ~= posY or frame.text.pos ~= pos then
		frame.text.posX = posX
		frame.text.posY = posY
		frame.text.pos = pos
		local anchor1, anchor2 = "BOTTOMLEFT", "TOPLEFT"
		if pos == 2 then
			anchor1, anchor2 = "BOTTOM", "TOP"
		elseif pos == 3 then
			anchor1, anchor2 = "BOTTOMRIGHT", "TOPRIGHT"
		elseif pos == 4 then
			anchor1, anchor2 = "LEFT", "RIGHT"
		elseif pos == 5 then
			anchor1, anchor2 = "TOPRIGHT", "BOTTOMRIGHT"
		elseif pos == 6 then
			anchor1, anchor2 = "TOP", "BOTTOM"
		elseif pos == 7 then
			anchor1, anchor2 = "TOPLEFT", "BOTTOMLEFT"
		elseif pos == 8 then
			anchor1, anchor2 = "RIGHT", "LEFT"
		elseif pos == 9 then
			anchor1, anchor2 = "CENTER", "CENTER"
		end
		frame.text:ClearAllPoints()
		frame.text:SetPoint(anchor1,frame,anchor2,posX,posY)
	end

	frame.text:SetText(text or "")
	if textUpdateReq then
		frame.textUpate.func = textUpdateReq
		frame.textUpate:Show()
	else
		frame.textUpate:Hide()
	end

	frame.glow_color = color
	frame.glow_noEdge = noEdge
	frame.glow_customThick = customThick
	frame.glow_customGlowType = customGlowType
	frame.glow_customN = customN
	frame.glow_customScale = customScale
	frame.glow_glowImage = glowImage

	frame:UpdateGlow()

	frame:Show()
	return frame
end

local function TriggerAura_DelayActive(trigger, triggerData, guid, vars)
	trigger.countsD[guid] = (trigger.countsD[guid] or 0) + 1
	if vars.sourceGUID then
		trigger.countsS[vars.sourceGUID] = (trigger.countsS[vars.sourceGUID] or 0) + 1
	end
	module:AddTriggerCounter(trigger,vars.sourceGUID and trigger.countsS[vars.sourceGUID],trigger.countsD[guid])
	if
		(not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count)) and
		(not triggerData.onlyPlayer or guid == UnitGUID("player"))
	then
		vars.counter = trigger.count
		module:RunTrigger(trigger, vars)
	end
end

local unitAuras = {}
module.db.unitAuras = unitAuras
function module.main:UNIT_AURA(unit,isFullUpdate,updatedAuras)
	local triggers = tUNIT_AURA[unit]
	if triggers then
		local guid = UnitGUID(unit)
		if guid then
			local a = unitAuras[guid]
			if not a then
				a = {}
				unitAuras[guid] = a
			end
			for k,v in pairs(a) do v.r=true end
			for i=1,255 do
				local name, _, count, _, duration, expirationTime, source, _, _, spellId, _, _, _, _, _, val1, val2, val3 = UnitAura(unit, i, "HELPFUL")
				if not spellId then
					break
				elseif not a[spellId] then
					a[spellId] = {name, count, duration, expirationTime, source, spellId, nil, val1, val2, val3}
				else
					local b = a[spellId]
					b[2] = count
					b[3] = duration
					if b[4] ~= expirationTime or b[2] ~= count then
						b[7] = true
					else
						b[7] = nil
					end
					b[4] = expirationTime
					b[8] = val1
					b[9] = val2
					b[10] = val3
					b.r = false
				end
			end
			for i=1,255 do
				local name, _, count, _, duration, expirationTime, source, _, _, spellId, _, _, _, _, _, val1, val2, val3 = UnitAura(unit, i, "HARMFUL")
				if not spellId then
					break
				elseif not a[spellId] then
					a[spellId] = {name, count, duration, expirationTime, source, spellId, nil, val1, val2, val3}
				else
					local b = a[spellId]
					b[2] = count
					b[3] = duration
					b[4] = expirationTime
					if b[4] ~= expirationTime or b[2] ~= count then
						b[7] = true
					else
						b[7] = nil
					end
					b[8] = val1
					b[9] = val2
					b[10] = val3
					b.r = false
				end
			end
			for k,v in pairs(a) do if v.r then a[k]=nil end end

			local name = UnitName(unit)
			local now = GetTime()
			for i=1,#triggers do
				local trigger = triggers[i]
				local triggerData = trigger._trigger
				local auraData
				if triggerData.spellID then
					auraData = a[triggerData.spellID]
				elseif triggerData.spellName then
					for k, v in pairs(a) do
						if v[1] == triggerData.spellName then
							auraData = v
							break
						end
					end
				end
				local sourceName = auraData and auraData[5] and UnitName(auraData[5]) or nil

				if
					auraData and
					(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
					(not trigger.DsourceID or auraData[5] and trigger.DsourceID(UnitGUID(auraData[5]))) and
					(not triggerData.sourceMark or auraData[5] and (GetRaidTargetIndex(auraData[5]) or 0) == triggerData.sourceMark) and
					(not triggerData.sourceUnit or auraData[5] and module:CheckUnit(triggerData.sourceUnit,UnitGUID(auraData[5]),trigger)) and
					(not trigger.DtargetName or name and trigger.DtargetName[name]) and
					(not trigger.DtargetID or trigger.DtargetID(guid)) and
					(not triggerData.targetMark or (GetRaidTargetIndex(unit) or 0) == triggerData.targetMark) and
					(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,guid,trigger)) and
					(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,auraData[2])) and
					(not triggerData.targetRole or module:CmpUnitRole(unit,triggerData.targetRole))
				then
					if not trigger.statuses[guid] or auraData[7] then

						if auraData[7] then	--for auras with changed durations
							for j=#trigger.delays2,1,-1 do
								if trigger.delays2[j].args[3] == guid then
									trigger.delays2[j]:Cancel()
									tremove(trigger.delays2, j)
								end
							end
						end

						local vars = {
							sourceName = sourceName,
							sourceMark = auraData[5] and GetRaidTargetIndex(auraData[5]) or nil,
							targetName = name,
							targetMark = GetRaidTargetIndex(unit),
							stacks = auraData[2],
							guid = guid,
							sourceGUID = auraData[5] and UnitGUID(auraData[5]) or nil,
							targetGUID = guid,
							timeLeft = auraData[4],
							_auraData = auraData,
							spellID = auraData[6],
							spellName = auraData[1],
						}
						trigger.statuses[guid] = vars
						trigger.units[guid] = unit
						if not triggerData.bwtimeleft or auraData[4] - now < triggerData.bwtimeleft then
							TriggerAura_DelayActive(trigger, triggerData, guid, vars)
						else
							local t = ScheduleTimer(TriggerAura_DelayActive, max(auraData[4] - triggerData.bwtimeleft - now, 0.01), trigger, triggerData, guid, vars)
							module.db.timers[#module.db.timers+1] = t
							trigger.delays2[#trigger.delays2+1] = t
						end
					end

					if trigger.statuses[guid] then
						trigger.statuses[guid].timeLeft = auraData[4]
					end
				elseif trigger.statuses[guid] then
					trigger.statuses[guid] = nil
					trigger.units[guid] = nil
					module:DeactivateTrigger(trigger,guid)
					if #trigger.delays2 > 0 then
						for j=#trigger.delays2,1,-1 do
							if trigger.delays2[j].args[3] == guid then
								trigger.delays2[j]:Cancel()
								tremove(trigger.delays2, j)
							end
						end
					end

				end
			end
		end
	end
end

function module:TriggerTargetLookup(unit,triggers)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or trigger.DsourceID(guid))
		then
			local tunit = unit.."target"
			local tguid = UnitGUID(tunit)
			local tname = UnitName(tunit)
			local targetCheck = tguid and
				(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark) and
				(not trigger.DtargetName or tname and trigger.DtargetName[tname]) and
				(not trigger.DtargetID or trigger.DtargetID(tguid)) and
				(not triggerData.targetMark or (GetRaidTargetIndex(tunit) or 0) == triggerData.targetMark) and
				(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,tguid,trigger))

			if not trigger.statuses[guid] and targetCheck then
				trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[guid])
				local vars = {
					sourceName = name,
					sourceMark = GetRaidTargetIndex(unit),
					targetName = tname,
					targetMark = GetRaidTargetIndex(tunit),
					guid = triggerData.guidunit == 1 and guid or tguid,
					counter = trigger.count,
					sourceGUID = guid,
					targetGUID = tguid,
					uid = guid,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not targetCheck then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil
				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:UNIT_TARGET(unit)
	local triggers = tUNIT_TARGET[unit]
	if triggers then
		module:TriggerTargetLookup(unit,triggers)
	end
end

function module.main:UNIT_THREAT_LIST_UPDATE(unit)
	local triggers = tUNIT_TARGET[unit]
	if triggers then
		module:TriggerTargetLookup(unit,triggers)
	end
end

function module:TriggerSpellCD(triggers)
	local gstartTime, gduration, genabled = GetSpellCooldown(61304)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger

		local spell = triggerData.spellID or triggerData.spellName
		if spell then
			local startTime, duration, enabled = GetSpellCooldown(spell)
			if duration then	--spell found
				local cdCheck = duration > gduration and duration > 0 and (not triggerData.bwtimeleft or (startTime + duration - GetTime()) < triggerData.bwtimeleft)

				if not trigger.statuses[1] and cdCheck then
					module:AddTriggerCounter(trigger)
					local vars = {
						spellID = select(7,GetSpellInfo(spell)),
						spellName = GetSpellInfo(spell),
						counter = trigger.count,
						timeLeft = startTime + duration,
					}
					trigger.statuses[1] = vars
					if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
						module:RunTrigger(trigger, vars)
					end
				elseif trigger.statuses[1] and not cdCheck then
					trigger.statuses[1] = nil
					module:DeactivateTrigger(trigger)
				end

				if trigger.statuses[1] then
					trigger.statuses[1].timeLeft = startTime + duration
				end
			end
		end
	end
end

function module.main:SPELL_UPDATE_COOLDOWN(unit)
	local triggers = module.db.eventsToTriggers.CDABIL
	if triggers then
		module:TriggerSpellCD(triggers)
	end
end

function module:TriggerSpellcastSucceeded(unit, triggers, spellID)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or trigger.DsourceID(guid)) and
			(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark) and
			(not triggerData.sourceUnit or module:CheckUnit(triggerData.sourceUnit,guid,trigger)) and
			(not triggerData.spellID or triggerData.spellID == spellID) and
			(not triggerData.spellName or triggerData.spellName == GetSpellInfo(spellID))
		then
			trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
			module:AddTriggerCounter(trigger,trigger.countsS[guid])
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				local vars = {
					sourceName = UnitName(unit),
					sourceMark = GetRaidTargetIndex(unit),
					spellID = spellID,
					spellName = GetSpellInfo(spellID),
					guid = guid,
					counter = trigger.count,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end
end

function module.main:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
	local triggers = tUNIT_SPELLCAST_SUCCEEDED[unit]
	if triggers then
		module:TriggerSpellcastSucceeded(unit, triggers, spellID)
	end
end

function module:TriggerWidgetUpdate(widgetID, widgetInfo)
	local widgetProgressData, isDouble, widgetRemoved = C_UIWidgetManager.GetStatusBarWidgetVisualizationInfo(widgetID)
	if not widgetProgressData then
		widgetProgressData = C_UIWidgetManager.GetDoubleStatusBarWidgetVisualizationInfo(widgetID)
		if not widgetProgressData then
			widgetRemoved = true
		end
		isDouble = true
	end
	local widgetVal, widgetValLeft, widgetValRight
	if not widgetRemoved then
		if not isDouble then
			widgetVal = ((widgetProgressData.barValue or 0) - (widgetProgressData.barMin or 0)) / max((widgetProgressData.barMax or 0) - (widgetProgressData.barMin or 0),1) * 100
		else
			widgetValLeft = ((widgetProgressData.leftBarValue or 0) - (widgetProgressData.leftBarMin or 0)) / max((widgetProgressData.leftBarMax or 0) - (widgetProgressData.leftBarMin or 0),1) * 100
			widgetValRight = ((widgetProgressData.rightBarValue or 0) - (widgetProgressData.rightBarMin or 0)) / max((widgetProgressData.rightBarMax or 0) - (widgetProgressData.rightBarMin or 0),1) * 100
		end
	end
	local triggers = module.db.eventsToTriggers.UPDATE_UI_WIDGET
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if not widgetRemoved and
			(not triggerData.spellID or triggerData.spellID == widgetID) and
			(not triggerData.spellName or (
				widgetProgressData.text ~= "" and triggerData.spellName == widgetProgressData.text or
				widgetProgressData.overrideBarText and widgetProgressData.overrideBarText ~= "" and widgetProgressData.overrideBarText:find(triggerData.spellName) or
				widgetProgressData.tooltip and widgetProgressData.tooltip ~= "" and widgetProgressData.tooltip:find(triggerData.spellName)
			))
		then
			local check = trigger.DnumberPercent and
				(
					(widgetVal and module:CheckNumber(trigger.DnumberPercent,widgetVal)) or
					(widgetValLeft and module:CheckNumber(trigger.DnumberPercent,widgetValLeft)) or
					(widgetValRight and module:CheckNumber(trigger.DnumberPercent,widgetValRight))
				)

			if not trigger.statuses[widgetID] and check then
				module:AddTriggerCounter(trigger)
				local vars = {
					counter = trigger.count,
					spellName = widgetProgressData.text ~= "" and widgetProgressData.text or widgetProgressData.overrideBarText ~= "" and widgetProgressData.overrideBarText or widgetProgressData.tooltip,
					spellID = widgetID,
					value = widgetVal,
					uid = widgetID,
				}
				trigger.statuses[widgetID] = vars
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[widgetID] and not check then
				trigger.statuses[widgetID] = nil
				module:DeactivateTrigger(trigger,widgetID)
			end

			if trigger.statuses[widgetID] then
				trigger.statuses[widgetID].value = widgetVal
			end
		end
	end
end

function module.main:UPDATE_UI_WIDGET(widgetInfo)
	module:TriggerWidgetUpdate(widgetInfo.widgetID, widgetInfo)
end

function module:IterateGroupCondition(allNames,Dtable)
	for name,v in pairs(Dtable) do
		if allNames[name] then
			return true
		end
	end
end

function module:TriggerPartyUnitUpdate(triggers)
	local allGUIDs,allNames, allGroups = {},{},{}
	for _, name, subgroup, class, guid in ExRT.F.IterateRoster, ExRT.F.GetRaidDiffMaxGroup() do
		if guid and name then
			allGUIDs[guid] = name
			allNames[name] = guid
			allGroups[name] = subgroup
		end
	end
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger

		local name = triggerData.sourceUnit and UnitName(triggerData.sourceUnit) or triggerData.sourceName
		local guid = allNames[name]
		local group = allGroups[name]

		if
			(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,group)) and
			(not trigger.DsourceName or module:IterateGroupCondition(allNames,trigger.DsourceName)) and
			(not triggerData.sourceUnit or allNames[ name ])
		then
			if guid and not trigger.statuses[guid] then
				local vars = {
					sourceName = name,
					sourceGUID = guid,
					guid = guid,
					stacks = group,
					uid = guid,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = name

				module:RunTrigger(trigger, vars)
            elseif guid and trigger.statuses[guid] and trigger._reminder.params then
                trigger._reminder.params.stacks = group
			    trigger._reminder.params["stacks".. trigger._i] = group
			end
		elseif trigger.statuses[guid] then
			trigger.statuses[guid] = nil
			trigger.units[guid] = nil

			module:DeactivateTrigger(trigger,guid)
		end
		for guid in pairs(trigger.statuses) do
			-- print(not allGUIDs[guid], not (not trigger.Dstacks or module:CheckNumber(trigger.Dstacks, allGroups[ allGUIDs [guid] ])), guid, allGUIDs[guid], allGroups[ allGUIDs [guid] ])
			if not allGUIDs[guid] or not (not trigger.Dstacks or module:CheckNumber(trigger.Dstacks, allGroups[ allGUIDs [guid] ])) then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:GROUP_ROSTER_UPDATE()
	local triggers = module.db.eventsToTriggers.RAID_GROUP_NUMBER
	if triggers then
		module:TriggerPartyUnitUpdate(triggers)
	end
end

function module:TriggerCast(unit,triggers,spellID,isStart,endTime)
	local guid = UnitGUID(unit)
	local name = UnitName(unit)
	local spellName = GetSpellInfo(spellID)
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(not triggerData.spellID or spellID == triggerData.spellID) and
			(not triggerData.spellName or spellName == triggerData.spellName) and
			(not trigger.DsourceName or name and trigger.DsourceName[name]) and
			(not trigger.DsourceID or guid and trigger.DsourceID(guid)) and
			(not triggerData.sourceMark or (GetRaidTargetIndex(unit) or 0) == triggerData.sourceMark)
		then
			if not trigger.statuses[guid] and isStart then
				trigger.countsS[guid] = (trigger.countsS[guid] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[guid])
				local vars = {
					sourceName = name,
					sourceMark = GetRaidTargetIndex(unit),
					guid = guid,
					counter = trigger.count,
					spellID = spellID,
					spellName = spellName,
					timeLeft = endTime,
				}
				trigger.statuses[guid] = vars
				trigger.units[guid] = unit
				if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
					module:RunTrigger(trigger, vars)
				end
			elseif trigger.statuses[guid] and not isStart then
				trigger.statuses[guid] = nil
				trigger.units[guid] = nil

				module:DeactivateTrigger(trigger,guid)
			end
		end
	end
end

function module.main:UNIT_SPELLCAST_START(unit, castGUID, spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		local name, text, texture, startTime, endTime, isTradeSkill, castID, interruptible, spellId = UnitCastingInfo(unit)
		module:TriggerCast(unit,triggers,spellID,true,(endTime or 0)/1000)
	end
end

function module.main:UNIT_SPELLCAST_CHANNEL_START(unit, castGUID, spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		local name, text, texture, startTime, endTime, isTradeSkill, interruptible, spellId = UnitChannelInfo(unit)
		module:TriggerCast(unit, triggers, spellID, true, (endTime or 0) / 1000)
	end
end

function module.main:UNIT_SPELLCAST_STOP(unit, castGUID, spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		module:TriggerCast(unit, triggers, spellID, false)
	end
end

function module.main:UNIT_SPELLCAST_CHANNEL_STOP(unit, castGUID, spellID)
	local triggers = tUNIT_CAST[unit]
	if triggers then
		module:TriggerCast(unit, triggers, spellID, false)
	end
end

function module.main:UNIT_CAST_CHECK(unit)
	local name, text, texture, startTime, endTime, isTradeSkill, castID, interruptible, spellId = UnitCastingInfo(unit)
	if name then
		local triggers = tUNIT_CAST[unit]
		if triggers then
			module:TriggerCast(unit,triggers,spellId,true,(endTime or 0)/1000)
		end
	else
		local name, text, texture, startTime, endTime, isTradeSkill, interruptible, spellId = UnitChannelInfo(unit)
		if name then
			local triggers = tUNIT_CAST[unit]
			if triggers then
				module:TriggerCast(unit,triggers,spellId,true,(endTime or 0)/1000)
			end
		end
	end
end

function module.main.COMBAT_LOG_EVENT_UNFILTERED(timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellID,spellName,school,arg1,arg2)
	local triggers = tCOMBAT_LOG_EVENT_UNFILTERED[event]
	if triggers then
		for i=1,#triggers do
			local trigger = triggers[i]
			local triggerData = trigger._trigger
			if
				(not triggerData.spellID or triggerData.spellID == spellID) and
				(not triggerData.spellName or triggerData.spellName == spellName) and
				(not trigger.DsourceName or sourceName and trigger.DsourceName[sourceName]) and
				(not trigger.DsourceID or trigger.DsourceID(sourceGUID)) and
				(not triggerData.sourceMark or module.datas.markToIndex[sourceFlags2] == triggerData.sourceMark) and
				(not triggerData.sourceUnit or module:CheckUnit(triggerData.sourceUnit,sourceGUID,trigger)) and
				(not trigger.DtargetName or destName and trigger.DtargetName[destName]) and
				(not trigger.DtargetID or trigger.DtargetID(destGUID)) and
				(not triggerData.targetMark or module.datas.markToIndex[destFlags2] == triggerData.targetMark) and
				(not triggerData.targetUnit or module:CheckUnit(triggerData.targetUnit,destGUID,trigger)) and
				(not triggerData.extraSpellID or triggerData.extraSpellID == arg1) and
				(not trigger.Dstacks or module:CheckNumber(trigger.Dstacks,arg2)) and
				(not triggerData.pattFind or triggerData.pattFind == arg1) and
				(not triggerData.targetRole or module:CmpUnitRole(destName,triggerData.targetRole))
			then
				trigger.countsS[sourceGUID] = (trigger.countsS[sourceGUID] or 0) + 1
				trigger.countsD[destGUID] = (trigger.countsD[destGUID] or 0) + 1
				module:AddTriggerCounter(trigger,trigger.countsS[sourceGUID],trigger.countsD[destGUID])
				if
					(not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count)) and
					(not triggerData.onlyPlayer or destGUID == UnitGUID("player"))
				then
					local vars = {
						sourceName = sourceName,
						sourceMark = module.datas.markToIndex[sourceFlags2],
						targetName = destName,
						targetMark = module.datas.markToIndex[destFlags2],
						spellName = spellName,
						spellID = spellID,
						extraSpellID = arg1,
						stacks = arg2,
						counter = trigger.count,
						guid = triggerData.guidunit == 1 and sourceGUID or destGUID,
						sourceGUID = sourceGUID,
						targetGUID = destGUID,
						uid = module:GetNextUID(),
					}
					module:RunTrigger(trigger, vars)
				end
			end
		end
	end

	-- if IsHistoryEnabled and CLEUIsHistoryEvent[event] and bit_band(sourceFlags,0x000000F0) ~= 0x00000010 then
	-- module:AddHistoryRecord(1,event,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellID)
	-- end
end

function module:TriggerBWMessage(key, text)
	local triggers = module.db.eventsToTriggers.BW_MSG
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			(triggerData.pattFind and type(text)=="string" and text:find(triggerData.pattFind,1,true)) or
			(triggerData.spellID and key == triggerData.spellID)
		then
			module:AddTriggerCounter(trigger)
			if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter,trigger.count) then
				local vars = {
					counter = trigger.count,
					spellID = key,
					spellName = text,
					uid = module:GetNextUID(),
				}
				module:RunTrigger(trigger, vars)
			end
		end
	end
end

local function TriggerBWTimer_DelayActive(trigger, triggerData, expirationTime, key, text)
	module:AddTriggerCounter(trigger)
	if not trigger.Dcounter or module:CheckNumber(trigger.Dcounter, trigger.count) then
		local vars = {
			counter = trigger.count,
			spellID = key,
			spellName = text,
			timeLeft = expirationTime,
			uid = module:GetNextUID(),
		}
		module:RunTrigger(trigger, vars)
	end
end

function module:TriggerBWTimer(key, text, duration)
	local triggers = module.db.eventsToTriggers.BW_TIMER
	for i=1,#triggers do
		local trigger = triggers[i]
		local triggerData = trigger._trigger
		if
			key == -1 or
			(
				triggerData.bwtimeleft and tonumber(triggerData.bwtimeleft) and
				(duration == 0 or duration >= tonumber(triggerData.bwtimeleft)) and
				(
					(triggerData.pattFind and type(text)=="string" and text:find(triggerData.pattFind,1,true)) or
					(triggerData.spellID and key == triggerData.spellID)
				)
			)
		then
			if duration == 0 then
				for i=1,#trigger.delays2 do
					trigger.delays2[i]:Cancel()
				end
				wipe(trigger.delays2)
			else
				local t = ScheduleTimer(TriggerBWTimer_DelayActive, max(duration - triggerData.bwtimeleft, 0.01), trigger, triggerData, GetTime() + duration, key, text)
				module.db.timers[#module.db.timers+1] = t
				trigger.delays2[#trigger.delays2+1] = t
			end
		end
	end
end

do
	local BW_Locale
	local BW_Locale_Soon

	local BigWigsTextToKeys = {}
	local function BigWigsEventCallback(event, ...)
		if (event == "BigWigs_Message") then
			local bwModule, key, text, color, icon = ...

			if module.db.eventsToTriggers.BW_MSG then
				module:TriggerBWMessage(key, text)
			end
		elseif event == "BigWigs_SetStage" then
			local bwModule, stage = ...
			if VExRT.Reminder.bwDebug then print("BigWigs_SetStage",...) end
			if stage and module.db.eventsToTriggers.BOSS_PHASE then
				module:TriggerBossPhase(tostring(stage))
			end
		elseif (event == "BigWigs_StartBar") then
			local bwModule, key, text, duration, icon = ...

			BigWigsTextToKeys[text] = key
			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(key, text, 0)
				module:TriggerBWTimer(key, text, duration)
			end
		elseif (event == "BigWigs_ResumeBar") then
			local bwModule, text = ...

			local duration = 0
			if BigWigs:GetPlugin("Bars") and bwModule then
				duration = bwModule:BarTimeLeft(text)
			else
				if VExRT.Reminder.bwDebug then print("else IN: if BigWigs:GetPlugin(\"Bars\") and bwModule then") end
				if not BigWigs:GetPlugin("Bars") then
					if VExRT.Reminder.bwDebug then VExRT.Reminder.bwDebugprint("else IN: if BigWigs:GetPlugin(\"Bars\") then") end
				end

				if not bwModule then
					if VExRT.Reminder.bwDebug then print("else IN: if bwModule then") end
				end
			end
			if duration == 0 then
				return
			end

			if module.db.eventsToTriggers.BW_TIMER and text then
				module:TriggerBWTimer(BigWigsTextToKeys[text], text, duration)
			end
		elseif (event == "BigWigs_StopBar") or (event == "BigWigs_PauseBar") then
			local bwModule, text = ...

			if module.db.eventsToTriggers.BW_TIMER and text then
				module:TriggerBWTimer(BigWigsTextToKeys[text], text, 0)
				if VExRT.Reminder.bwDebug then print("elseif (event == \"BigWigs_StopBar\") or (event == \"BigWigs_PauseBar\") then",...,BigWigsTextToKeys[text]) end
			end
		elseif (event == "BigWigs_StopBars" or event == "BigWigs_OnBossDisable"	or event == "BigWigs_OnPluginDisable") then
			local bwModule = ...

			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(-1, nil, 0)
			end
		end
	end

	local registeredBigWigsEvents = {}
	function module:RegisterBigWigsCallbackNew(event)
		if (registeredBigWigsEvents[event]) then
			return
		end
		if (BigWigsLoader) then
			BigWigsLoader.RegisterMessage(module, event, BigWigsEventCallback)
			registeredBigWigsEvents[event] = true
		end
	end

	function module:UnregisterBigWigsCallbackNew(event)
		if not (registeredBigWigsEvents[event]) then
			return
		end
		if (BigWigsLoader) then
			BigWigsLoader.UnregisterMessage(module, event)
			registeredBigWigsEvents[event] = nil
		end
	end
end

do
	local DBMIdToSpellID = {}
	local DBMIdToText = {}
	local function DBMEventCallback(event, ...)
		if BigWigsLoader then
			return
		end
		if (event == "DBM_Announce") then
			local message, icon, announce_type, spellId, modId = ...

			if module.db.eventsToTriggers.BW_MSG then
				module:TriggerBWMessage(spellId, message)
			end
		elseif event == "DBM_TimerStart" then
			local id, msg, duration, icon, timerType, spellId, dbmType = ...
			if module.db.eventsToTriggers.BW_TIMER and id then
				DBMIdToSpellID[id] = spellId
				DBMIdToText[id] = msg or ""
				module:TriggerBWTimer(spellId, msg, duration)
			end
		elseif event == "DBM_TimerStop" or event == "DBM_TimerPause" then
			local id = ...
			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", 0)
			end
		elseif (event == "DBM_TimerResume") then
			local id = ...

			local duration = 0
			if type(DBT) == "table" and DBT.GetBar and id then
				local bar = DBT:GetBar(id)
				duration = bar and bar.timer or 0
			end
			if duration == 0 then
				return
			end

			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", duration)
			end
		elseif (event == "DBM_TimerUpdate") then
			local id, elapsed, duration = ...

			if module.db.eventsToTriggers.BW_TIMER and id and DBMIdToSpellID[id] then
				module:TriggerBWTimer(DBMIdToSpellID[id], DBMIdToText[id] or "", duration - elapsed)
			end
		elseif event == "DBM_SetStage" then
			local addon, modId, stage, encounterId, stageTotal = ...
			if stage then
				module:TriggerBossPhase(tostring(stage),tostring(stageTotal))
			end
		elseif event == "kill" or event == "wipe" then
			if module.db.eventsToTriggers.BW_TIMER then
				module:TriggerBWTimer(-1, nil, 0)
			end
		end
	end

	local registeredDBMEvents = {}
	function module:RegisterDBMCallbackNew(event)
		if (registeredDBMEvents[event]) then
			return
		end
		if type(DBM)=='table' and DBM.RegisterCallback then
			registeredDBMEvents[event] = true

			if event == "DBM_kill" or event == "DBM_wipe" then
				event = event:sub(5)
			end
			DBM:RegisterCallback(event, DBMEventCallback)
		end
	end

	function module:UnregisterDBMCallbackNew(event)
		if not (registeredDBMEvents[event]) then
			return
		end
		if type(DBM)=='table' and DBM.UnregisterCallback then
			registeredDBMEvents[event] = nil

			if event == "DBM_kill" or event == "DBM_wipe" then
				event = event:sub(5)
			end
			DBM:UnregisterCallback(event, DBMEventCallback)
		end
	end
end


--CLEU:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
CLEU:SetScript("OnEvent",function()
	local timestamp,event,hideCaster,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2,spellID,spellName,school,arg1,arg2 = CombatLogGetCurrentEventInfo()

	if event == "SPELL_CAST_SUCCESS" then
		local f = CLEU_SPELL_CAST_SUCCESS[spellID]
		if f then
			CastNumbers_SUCCESS[sourceGUID] = CastNumbers_SUCCESS[sourceGUID] or {}
			CastNumbers_SUCCESS[sourceGUID][spellID] = (CastNumbers_SUCCESS[sourceGUID][spellID] or 0) + 1
			CastNumbers_SUCCESS[spellID] = (CastNumbers_SUCCESS[spellID] or 0) + 1
			--castNumber,sourceGUID,sourceMark,globalCastNumber)
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_SUCCESS[sourceGUID][spellID],sourceGUID,sourceFlags2 or 0,CastNumbers_SUCCESS[spellID],vars)
			end
		end
		if bit_band(sourceFlags,0x000000F0) ~= 0x00000010 and not stopHistory then
			history[#history+1] = {GetTime(),"SPELL_CAST_SUCCESS",spellID,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2}
		end
	elseif event == "SPELL_CAST_START" then
		local f = CLEU_SPELL_CAST_START[spellID]
		if f then
			CastNumbers_START[sourceGUID] = CastNumbers_START[sourceGUID] or {}
			CastNumbers_START[sourceGUID][spellID] = (CastNumbers_START[sourceGUID][spellID] or 0) + 1
			CastNumbers_START[spellID] = (CastNumbers_START[spellID] or 0) + 1
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_START[sourceGUID][spellID],sourceGUID,sourceFlags2 or 0,CastNumbers_START[spellID],vars)
			end
		end
		if bit_band(sourceFlags,0x000000F0) ~= 0x00000010 and not stopHistory then
			history[#history+1] = {GetTime(),"SPELL_CAST_START",spellID,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2}
		end
	elseif event == "SPELL_AURA_APPLIED" then
		local f = CLEU_SPELL_AURA_APPLIED[spellID]
		if f then
			CastNumbers_AURA_APPLIED[sourceGUID] = CastNumbers_AURA_APPLIED[sourceGUID] or {}
			CastNumbers_AURA_APPLIED[sourceGUID][spellID] = (CastNumbers_AURA_APPLIED[sourceGUID][spellID] or 0) + 1
			CastNumbers_AURA_APPLIED[spellID] = (CastNumbers_AURA_APPLIED[spellID] or 0) + 1
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_AURA_APPLIED[sourceGUID][spellID],sourceGUID,destFlags2 or 0,CastNumbers_AURA_APPLIED[spellID],vars)
			end
		end
		f = CLEU_SPELL_AURA_APPLIED_SELF[spellID]
		if f and destGUID == UnitGUID'player' then
			CastNumbers_AURA_APPLIED_SELF[sourceGUID] = CastNumbers_AURA_APPLIED_SELF[sourceGUID] or {}
			CastNumbers_AURA_APPLIED_SELF[sourceGUID][spellID] = (CastNumbers_AURA_APPLIED_SELF[sourceGUID][spellID] or 0) + 1
			CastNumbers_AURA_APPLIED_SELF[spellID] = (CastNumbers_AURA_APPLIED_SELF[spellID] or 0) + 1
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_AURA_APPLIED_SELF[sourceGUID][spellID],sourceGUID,sourceFlags2 or 0,CastNumbers_AURA_APPLIED_SELF[spellID],vars)
			end
		end
		if bit_band(sourceFlags,0x000000F0) ~= 0x00000010 and not stopHistory then
			history[#history+1] = {GetTime(),"SPELL_AURA_APPLIED",spellID,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2}
		end
	elseif event == "SPELL_AURA_REMOVED" then
		local f = CLEU_SPELL_AURA_REMOVED[spellID]
		if f then
			CastNumbers_AURA_REMOVED[sourceGUID] = CastNumbers_AURA_REMOVED[sourceGUID] or {}
			CastNumbers_AURA_REMOVED[sourceGUID][spellID] = (CastNumbers_AURA_REMOVED[sourceGUID][spellID] or 0) + 1
			CastNumbers_AURA_REMOVED[spellID] = (CastNumbers_AURA_REMOVED[spellID] or 0) + 1
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_AURA_REMOVED[sourceGUID][spellID],sourceGUID,destFlags2 or 0,CastNumbers_AURA_REMOVED[spellID],vars)
			end
		end
		f = CLEU_SPELL_AURA_REMOVED_SELF[spellID]
		if f and destGUID == UnitGUID'player' then
			CastNumbers_AURA_REMOVED_SELF[sourceGUID] = CastNumbers_AURA_REMOVED_SELF[sourceGUID] or {}
			CastNumbers_AURA_REMOVED_SELF[sourceGUID][spellID] = (CastNumbers_AURA_REMOVED_SELF[sourceGUID][spellID] or 0) + 1
			CastNumbers_AURA_REMOVED_SELF[spellID] = (CastNumbers_AURA_REMOVED_SELF[spellID] or 0) + 1
			local vars = {
				sourceName = sourceName,
				sourceMark = module.datas.markToIndex[sourceFlags2],
				targetName = destName,
				targetMark = module.datas.markToIndex[destFlags2],
				spellName = spellName,
				spellID = spellID,
				extraSpellID = arg1,
				stacks = arg2,
				sourceGUID = sourceGUID,
				targetGUID = destGUID,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_AURA_REMOVED_SELF[sourceGUID][spellID],sourceGUID,sourceFlags2 or 0,CastNumbers_AURA_REMOVED_SELF[spellID],vars)
			end
		end
		if bit_band(sourceFlags,0x000000F0) ~= 0x00000010 and not stopHistory then
			history[#history+1] = {GetTime(),"SPELL_AURA_REMOVED",spellID,sourceGUID,sourceName,sourceFlags,sourceFlags2,destGUID,destName,destFlags,destFlags2}
		end
	end
end)

-- if false then
-- stopHistory = false
-- CLEU:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
-- bit_band = function() return 1 end
-- end

local BOSSHPFrame = CreateFrame("Frame")
BOSSHPFrame:SetScript("OnEvent",function(self,_,unit)
	local thisUnit = CLEU_BOSS_HP[unit]
	if thisUnit then
		local hpMax = UnitHealthMax(unit)
		if hpMax == 0 then
			return
		end
		local hp = UnitHealth(unit) / hpMax * 100
		if hp == 0 then
			return
		end

		for HP,funcs in pairs(thisUnit) do
			if hp <= HP then
				for i=1,#funcs do
					local f = funcs[i]
					if not CastNumbers_HP[f] then
						CastNumbers_HP[f] = true
						f()
					end
				end
			end
		end
	end
end)

local bossManaPrev = {}

local BOSSManaFrame = CreateFrame("Frame")
BOSSManaFrame:SetScript("OnEvent",function(self,_,unit)
	local thisUnit = CLEU_BOSS_MANA[unit]
	if thisUnit then
		local hpMax = UnitPowerMax(unit)
		if hpMax == 0 then
			return
		end

		CastNumbers_MANA2[unit] = CastNumbers_MANA2[unit] or 1

		local hp = UnitPower(unit) / hpMax * 100
		if bossManaPrev[unit] and hp < bossManaPrev[unit] then
			CastNumbers_MANA2[unit] = CastNumbers_MANA2[unit] + 1
			for _,funcs in pairs(thisUnit) do --HP,funcs
				for i=1,#funcs do
					CastNumbers_MANA[ funcs[i] ] = nil
				end
			end
		end
		bossManaPrev[unit] = hp

		for HP,funcs in pairs(thisUnit) do
			if hp >= HP then
				for i=1,#funcs do
					local f = funcs[i]
					if not CastNumbers_MANA[f] then
						CastNumbers_MANA[f] = true
						f(CastNumbers_MANA2[unit])
					end
				end
			end
		end
	end
end)

-----------
-----------
-----------
--OLD BIGWIGS CALLBACK
local bwBars = {}
local dbmBars = {}
local bwTextToSpellID = {}
local function bigWigsEventCallback(event, ...)
	if (event == "BigWigs_Message") then
		local addon, spellID, text, name, icon = ...
		local f = CLEU_BW_MSG[spellID]
		if f then
			CastNumbers_BW_MSG[spellID] = (CastNumbers_BW_MSG[spellID] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = text,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_MSG[spellID],nil,0,nil,vars)
			end
		end
	elseif (event == "BigWigs_StartBar") then
		-- local addon, spellID, text, duration, icon = ...
		local _, spellID, text, duration, _ = ...
		local now = GetTime()
		local expirationTime = now + duration
		local curr_uid = now
		bwBars[text] = curr_uid
		bwTextToSpellID[text] = spellID
		local f = CLEU_BW_TIMER[spellID]
		if f then
			CastNumbers_BW_TIMER[spellID] = (CastNumbers_BW_TIMER[spellID] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[spellID],text,curr_uid,expirationTime,vars)
			end
		end
		local f = CLEU_BW_TIMER[text]
		if f then
			CastNumbers_BW_TIMER[text] = (CastNumbers_BW_TIMER[text] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[text],text,curr_uid,expirationTime,vars)
			end
		end
	elseif (event == "BigWigs_ResumeBar") then
		-- local addon, text = ...
		local addon, text = ...
		if not BigWigs or not BigWigs.modules or not BigWigs.modules.Bosses or not BigWigs.modules.Bosses.modules then
			return
		end

		local duration = 0
		local bars = BigWigs:GetPlugin("Bars")
		if bars and addon then
			duration = addon:BarTimeLeft(text)
		end
		if duration == 0 then
			return
		end

		local spellID = bwTextToSpellID[text]
		if not spellID then
			return
		end

		local now = GetTime()
		local expirationTime = now + duration

		local curr_uid = now
		bwBars[text] = curr_uid

		local f = CLEU_BW_TIMER[spellID]
		if f then
			CastNumbers_BW_TIMER[spellID] = (CastNumbers_BW_TIMER[spellID] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[spellID],text,curr_uid,expirationTime,vars)
			end
		end
		local f = CLEU_BW_TIMER[text]
		if f then
			CastNumbers_BW_TIMER[text] = (CastNumbers_BW_TIMER[text] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[text],text,curr_uid,expirationTime,vars)
			end
		end
	elseif (event == "BigWigs_StopBar") or (event == "BigWigs_PauseBar") then
		-- local addon, text = ...
		local _, id = ...
		bwBars[id] = nil


	elseif (event == "BigWigs_StopBars" or event == "BigWigs_OnBossDisable"	or event == "BigWigs_OnPluginDisable") then
		-- local addon = ...
		for key, _ in pairs(bwBars) do --for key, bar in pairs(bwBars) do
			bwBars[key] = nil
		end
	end
end

-----------
-----------
-----------
--OLD DBM CALLBACK
local function dbmEventCallback(event, ...)
	if (event == "DBM_Announce") then  --message, self.icon, self.type, self.spellId, self.mod.id
		local message, _, _, spellID = ...
		local f = CLEU_BW_MSG[spellID]
		if f then
			CastNumbers_BW_MSG[spellID] = (CastNumbers_BW_MSG[spellID] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = message,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_MSG[spellID],nil,0,nil,vars)
			end
		end
	elseif (event == "DBM_TimerStart") then -- id, msg, timer, self.icon, self.type, self.spellId, colorId, self.mod.id, self.keep, self.fade, self.name, guid)
		local id, text, duration, _, _, spellID = ...

		local now = GetTime()
		local expirationTime = now + duration

		local curr_uid = now
		dbmBars[id] = {}
		dbmBars[id].curr_uid = curr_uid
		dbmBars[id].expirationTime = expirationTime
		dbmBars[id].duration = duration
		dbmBars[id].text = text
		bwTextToSpellID[id] = spellID

		local f = CLEU_BW_TIMER[spellID]
		if f then
			CastNumbers_BW_TIMER[spellID] = (CastNumbers_BW_TIMER[spellID] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[spellID],id,curr_uid,expirationTime,vars)
			end
		end
		local f = CLEU_BW_TIMER[text]
		if f then
			CastNumbers_BW_TIMER[text] = (CastNumbers_BW_TIMER[text] or 0) + 1
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[text],id,curr_uid,expirationTime,vars)
			end
		end
	elseif (event == "DBM_TimerPause") then
		local id, _ = ...
		if not dbmBars[id] or not bwTextToSpellID[id] then return end --nil check

		dbmBars[id].remainingTime = dbmBars[id].expirationTime - GetTime()
		dbmBars[id].curr_uid = nil
	elseif (event == "DBM_TimerResume")  then
		local id = ...

		if not dbmBars[id] or not bwTextToSpellID[id] or not dbmBars[id].remainingTime then return end --nil check


		local duration = 0
		if type(DBT) == "table" and DBT.GetBar and id then
			local bar = DBT:GetBar(id)
			duration = bar and bar.timer or 0
		end
		if duration == 0 then
			return
		end

		local now = GetTime()
		local expirationTime = now + duration
		local curr_uid = now

		dbmBars[id].curr_uid = curr_uid
		dbmBars[id].expirationTime = expirationTime
		dbmBars[id].duration = duration

		local spellID = bwTextToSpellID[id]
		local text = dbmBars[id].text

		-- print(event,dbmBars[id].duration, dbmBars[id].expirationTime,dbmBars[id].curr_uid)

		local f = CLEU_BW_TIMER[spellID]
		if f then
			CastNumbers_BW_TIMER[spellID] = (CastNumbers_BW_TIMER[spellID] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[spellID],id,curr_uid,expirationTime,vars)
			end
		end
		local f = CLEU_BW_TIMER[text]
		if f then
			CastNumbers_BW_TIMER[text] = (CastNumbers_BW_TIMER[text] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[text],id,curr_uid,expirationTime,vars)
			end
		end
	elseif (event == "DBM_TimerUpdate")  then
		local id, elapsed, total = ...   --id, elapsed, total

		if not dbmBars[id] or not bwTextToSpellID[id] then print("|cffff8000[Reminder]|r no data for DBM_TimerUpdate") return end --nil check

		local now = GetTime()
		local duration = total - elapsed
		local expirationTime = now + duration
		local curr_uid = now

		dbmBars[id].curr_uid = curr_uid
		dbmBars[id].expirationTime = expirationTime
		dbmBars[id].duration = duration
		-- bwTextToSpellID[id] = spellID

		local spellID = bwTextToSpellID[id]
		local text = dbmBars[id].text
		-- print(event,dbmBars[id].duration, dbmBars[id].expirationTime,dbmBars[id].curr_uid)

		local f = CLEU_BW_TIMER[spellID]
		if f then
			CastNumbers_BW_TIMER[spellID] = (CastNumbers_BW_TIMER[spellID] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[spellID],id,curr_uid,expirationTime,vars)
			end
		end
		local f = CLEU_BW_TIMER[text]
		if f then
			CastNumbers_BW_TIMER[text] = (CastNumbers_BW_TIMER[text] or 0)
			local vars = {
				spellID = spellID,
				spellName = text,
				timeLeft = expirationTime,
				uid = module:GetNextUID(),
			}
			for i=1,#f do
				f[i](CastNumbers_BW_TIMER[text],id,curr_uid,expirationTime,vars)
			end
		end
	elseif (event == "DBM_TimerStop") then
		local id, _ = ...
		dbmBars[id] = nil
	elseif  event == "DBM_Kill" or event == "DBM_Wipe" then
		for key, bar in pairs(dbmBars) do
			dbmBars[key] = nil
		end
	end
end

function module:CopyTriggerEventForReminder(trigger)
	if trigger.event ~= 1 then
		return trigger
	end
	local new = ExRT.F.table_copy2(trigger)
	local eventDB = module.C[trigger.eventCLEU or 0]
	for k,v in pairs(new) do
		if eventDB and not ExRT.F.table_find(eventDB.triggerFields,k) and k ~= "andor" and k ~= "event" then
			new[k] = nil
		end
	end
	if eventDB and not ExRT.F.table_find(eventDB.triggerFields,"targetName") then
		new.guidunit = 1
	end
	if eventDB and not ExRT.F.table_find(eventDB.triggerFields,"sourceName") then
		new.guidunit = nil
	end
	if new.eventCLEU == "ENVIRONMENTAL_DAMAGE" then
		if new.spellID == 1 then
			new.spellID = "Falling"
		elseif new.spellID == 2 then
			new.spellID = "Drowning"
		elseif new.spellID == 3 then
			new.spellID = "Fatigue"
		elseif new.spellID == 4 then
			new.spellID = "Fire"
		elseif new.spellID == 5 then
			new.spellID = "Lava"
		elseif new.spellID == 6 then
			new.spellID = "Slime"
		end
	end
	return new
end

function module:FindNumberInString(num,str)
	if type(str) == "number" then
		return num == str
	elseif type(str) ~= "string" then
		return
	end
	num = tostring(num)
	for n in string_gmatch(str,"[^, ]+") do
		if n == num then
			return true
		end
	end
end

function module:CreateNumberConditions(str)
	if not str then
		return
	end
	local r = {}
	for w in string_gmatch(str, "[^, ]+") do
		local isPlus
		if w:find("^%+") then
			isPlus = true
			w = w:sub(2)
		end
		local n = tonumber(w)
		local f
		if n then
			if n < 0 then
				n = -n
				local n1,n2 = floor(n),floor((n % 1) * 10)
				f = function(v) return (v % n1) == n2 end
			else
				f = function(v) return v == n end
			end
		elseif w:find("%%") then
			local a,b = w:match("(%d+)%%(%d+)")
			if a and b then
				a = tonumber(a) - 1
				b = tonumber(b)
				f = function(v)
					if a == (v - 1) % b then
						return true
					end
				end
			end
		elseif w:find("^>=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v >= n end
		elseif w:find("^>") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v > n end
		elseif w:find("^<=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v <= n end
		elseif w:find("^<") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v < n end
		elseif w:find("^!") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v ~= n end
		elseif w:find("^=") then
			n = tonumber(w:match("[0-9%.]+"),10)
			f = function(v) return v == n end
		end
		if f then
			if isPlus and #r > 0 then
				local c = r[#r]
				r[#r] = function(v)
					return c(v) and f(v)
				end
			else
				r[#r+1] = f
			end
		end
	end
	return r
end

function module:CreateStringConditions(str)
	if not str then
		return
	end
	local isReverse
	if str:find("^%-") then
		isReverse = true
		str = str:sub(2)
	end
	local r = {}
	for w in string_gmatch(str, "[^;]+") do
		r[w] = true
	end
	if isReverse then
		local t = r
		r = setmetatable({},{__index = function(_,v)
				if t[v] then
					return false
				else
					return true
				end
			end})
	end
	return r
end

function module:CreateMobIDConditions(str)
	if not str then
		return
	end
	local r = {}
	for w in string_gmatch(str,"[^,]+") do
		local substr = w
		if w:find(":") then
			local condID,condSpawn = strsplit(":",substr,2)
			r[#r+1] = function(guid)
				local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
				if mobID == condID and (unitType == "Creature" or unitType == "Vehicle") then
					local spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnID, 1, 5), 16), 0xffff8), 3)
					if VExRT.Reminder.debug then print("|cffff8000[Reminder]|r SpawnIndex: "..tostring(spawnIndex)) end
					return condSpawn == tostring(spawnIndex)
				end
			end
		else
			r[#r+1] = function(guid)
				return select(6,strsplit("-", guid or "")) == substr
			end
		end
	end
	if #r > 1 then
		return function(guid)
			for i=1,#r do
				if r[i](guid) then
					return true
				end
			end
		end
	else
		return r[1]
	end
end


function module:ConvertMinuteStrToNum(delayStr,notePattern)
	if not delayStr then
		return
	end
	local r = {}
	for w in string_gmatch(delayStr,"[^, ]+") do
		if w:lower() == "note" then
			w = "0"
			if notePattern then
				local found, line = module:FindPlayerInNote(notePattern)
				if found and line then
					local t = line:match("{time:([0-9:%.]+)")
					if t then
						w = t
					end
				end
			end
		end

		local delayNum = tonumber(w)
		if delayNum then
			r[#r+1] = delayNum > 0 and delayNum or 0.01
		else
			local m,s,ms = w:match("(%d+):(%d+)%.?(%d*)")
			if m and s then
				m = tonumber(m)
				s = tonumber(s)
				ms = ms and tonumber("0."..ms) or 0
				local rn = m * 60 + s + ms
				r[#r+1] = rn > 0 and rn or 0.01
			end
		end
	end
	if #r > 0 then
		return r
	else
		return
	end
end

do
	local helpTable = {}
	function module.IterateTable(t)
		if type(t) == "table" then
			return next, t
		else
			helpTable[1] = t
			return next, helpTable
		end
	end
end






function module:FindPlayerInNote(pat)
	local reverse = pat:find("^%-")
	pat = "^"..pat:gsub("^%-",""):gsub("([%.%(%)%-%$])","%%%1")
	if not VExRT or not VExRT.Note or not VExRT.Note.Text1 then
		return
	end
	local lines = {strsplit("\n", VExRT.Note.Text1)}
	for i=1,#lines do
		if lines[i]:find(pat) then
			local l = lines[i]:gsub(pat.." *",""):gsub("|c........",""):gsub("|r",""):gsub(" *$",""):gsub("|",""):gsub(" +"," ")
			local list = {strsplit(" ", l)}
			for j=1,#list do
				if list[j] == playerName then
					if reverse then
						return false, lines[i]
					else
						return true, lines[i]
					end
				end
			end
		end
	end
	if reverse then
		return true
	end
end

do
	local tmr = 0
	-- local sReminders = module.db.showedReminders
	frame:SetScript("OnUpdate",function(self,elapsed)
		tmr = tmr + elapsed
		if tmr > 0.03 then

			tmr = 0

			if VExRT.Reminder.lock then	--test mode active
				return
			end

			local text1,text2,text3
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
						-- countdownFormat = module.datas.countdownType[data.countdownType or 2][3]
						countdownFormat = module.datas.countdownType[data.countdownType or 2][3]
						showed.countdownFormat = countdownFormat
					end
					text1 = msg .. (showed.dur ~= 0 and data.countdown and format(countdownFormat,t - now) or "") .. (text1 and "\n|r" or "|r") .. (text1 or "")

				else
					if showed.voice then
						showed.voice:Cancel()
					end
					tremove(sReminders,j)
				end
			end

			if text1 ~= self.text1.prev then
				self.text1:SetText(text1 or "")
				self.text1.prev = text1
			end
			-- if text ~= self.text.prev then
			-- self.text:SetText(text or "")
			-- self.text.prev = text
			-- end
			-- if textSmall ~= self.textSmall.prev then
			-- self.textSmall:SetText(textSmall or "")
			-- self.textSmall.prev = textSmall
			-- end
			if not text1 and not text2 and not text3 then
				self:Hide()
			end
		end
	end)
end

function module:SendWeakAurasCustomEvent(msg)
	msg = module:FormatMsg(msg)
	local argsTable = {}

	for v in string_gmatch(msg, "[^ ]+") do
		tinsert(argsTable, v)
	end

	WeakAuras.ScanEvents(unpack(argsTable))
end

function module:ParseGlow(data,params)
	local formatedString = module:FormatMsg(data.glow,params):gsub("|*c%x%x%x%x%x%x%x%x([^|]+)|*r", "%1")
	for glowTarget in string_gmatch(formatedString, "[^,; ]+") do
		if glowTarget == "{destName}" then
			glowTarget = params.targetName
			-- elseif glowTarget:match("{sourceName(%d*)}") then
			-- 	glowTarget = params["sourceName"]
			-- elseif glowTarget:match("{targetName+(%d*)}") then
			-- 	glowTarget = params["targetName"]
		end
		local unit = UnitInRaid(glowTarget) and "raid" .. UnitInRaid(glowTarget)
		local unitFrame = LGF.GetFrame(unit,LGFNullOpt)
		if unitFrame then
			module:StartFrameGlow(unitFrame,data,params)
		else
			C_Timer.After(0.2, function()
				local unitFrame = LGF.GetFrame(unit,LGFNullOpt)
				if unitFrame then
					module:StartFrameGlow(unitFrame,data,params)
				end
			end)
		end
	end
end

function module:StartFrameGlow(unitFrame,data,params)
	if unitFrame then
		local duration = data.duration and data.duration ~= 0 and data.duration or 2
		local untimed = data.event == "ADVANCED" and (not data.duration or (data.duration and data.duration == 0)) and true or false
		local Glow = VExRT.Reminder.Glow
		local type = Glow.type
		if type == "Pixel Glow" then
			local PixelGlow = Glow.PixelGlow
					LCG.PixelGlow_Start(unitFrame,{
							Glow.ColorR,
							Glow.ColorG,
							Glow.ColorB,
							Glow.ColorA
						},
						PixelGlow.count,
						PixelGlow.frequency,
						PixelGlow.length,
						PixelGlow.thickness,
						PixelGlow.xOffset,
						PixelGlow.yOffset,
						PixelGlow.border)
			local timer
			if not untimed and duration then
				timer =  C_Timer.NewTimer(duration, function() if unitFrame then LCG.PixelGlow_Stop(unitFrame) end end)
			end

			GlowCancelTimers[#GlowCancelTimers+1] = {
				timer = timer,
				data = data,
				unitFrame = unitFrame,
				params = params,
			}

		elseif type == "Autocast Shine" then
			local AutoCastGlow = Glow.AutoCastGlow
			LCG.AutoCastGlow_Start(unitFrame,{
					Glow.ColorR,
					Glow.ColorG,
					Glow.ColorB,
					Glow.ColorA
				},
				AutoCastGlow.count,
				AutoCastGlow.frequency,
				AutoCastGlow.scale,
				AutoCastGlow.xOffset,
				AutoCastGlow.yOffset)
			local timer
			if not untimed and duration then
				timer = C_Timer.NewTimer(duration, function() if unitFrame then LCG.AutoCastGlow_Stop(unitFrame) end end)
			end
			GlowCancelTimers[#GlowCancelTimers+1] = {
				timer = timer,
				data = data,
				unitFrame = unitFrame,
				params = params,
			}
		elseif type == "Proc Glow" then
			local ProcGlow = Glow.ProcGlow
			LCG.ProcGlow_Start(unitFrame,{
				color = {
					Glow.ColorR,
					Glow.ColorG,
					Glow.ColorB,
					Glow.ColorA
				},
				duration = ProcGlow.duration,
				startAnim = ProcGlow.startAnim,
				xOffset = ProcGlow.xOffset,
				yOffset = ProcGlow.yOffset,
			})
			local timer
			if not untimed and duration then
				timer = C_Timer.NewTimer(duration, function() if unitFrame then LCG.ProcGlow_Stop(unitFrame) end end)
			end
			GlowCancelTimers[#GlowCancelTimers+1] = {
				timer = timer,
				data = data,
				unitFrame = unitFrame,
				params = params,
			}

		else
			LCG.ButtonGlow_Start(unitFrame,{
					Glow.ColorR,
					Glow.ColorG,
					Glow.ColorB,
					Glow.ColorA
				},
				Glow.ActionButtonGlow.frequency)
			local timer
			if not untimed and duration then
				timer = C_Timer.NewTimer(duration, function() if unitFrame then LCG.ButtonGlow_Stop(unitFrame) end end)
			end
			GlowCancelTimers[#GlowCancelTimers+1] = {
				timer = timer,
				data = data,
				unitFrame = unitFrame,
				params = params,
			}
		end
	end
end

function module:SayChatSpam(data, params)
	local sType = data.spamType
	local str = data.spamMsg
	local channelName = data.spamChannel == 1 and "SAY" or data.spamChannel == 2 and  "YELL" or data.spamChannel == 3 and "PARTY" or data.spamChannel == 4 and "RAID" or ""
	local untimed = data.event == "ADVANCED" and (not data.duration or (data.duration and data.duration == 0)) and true or false
	local duration = data.duration or 3

	for i=1,#ChatSpamTimers do
		ChatSpamTimers[i]:Cancel()
	end
	wipe(ChatSpamTimers)
	wipe(ChatSpamUntimed)

	local _SendChatMessage
	if data.spamChannel == 5 then
		_SendChatMessage = print
	elseif (data.spamChannel == 3 and (IsInGroup() or IsInRaid())) or (data.spamChannel == 4 and IsInRaid()) then
		_SendChatMessage = SendChatMessage
	elseif select(2,GetInstanceInfo()) == "none" then
		_SendChatMessage = ExRT.NULLfunc
	else
		_SendChatMessage = SendChatMessage
	end

	if untimed then
		if sType == 1 or sType == 2 then
			local function printf()
				local msg = module:FormatMsgForChat(module:FormatMsg(str or "", params, true))
				_SendChatMessage(msg, channelName)
				ChatSpamTimers[#ChatSpamTimers+1] = ScheduleTimer(printf,1.5)
				ChatSpamUntimed = {
					timer = ChatSpamTimers[#ChatSpamTimers],
					data = data,
				}
			end

			ChatSpamTimers[1] = ScheduleTimer(printf,0.01)
			ChatSpamUntimed = {
				timer = ChatSpamTimers[1],
				data = data,
			}

		elseif sType == 3 then
			local function printf()
				local msg = module:FormatMsgForChat(module:FormatMsg(str or "", params, true))
				_SendChatMessage(msg, channelName)
			end
			printf()
		end
	else
		if sType == 1 then
			local function printf(c)
				local msg = module:FormatMsgForChat(module:FormatMsg(str or "", params, true))
				_SendChatMessage(msg.." "..c, channelName)
			end
			for i=1,duration+1,1 do
				ChatSpamTimers[i] = ScheduleTimer(printf,max(i-1,0.01),floor(duration-(i-1)))
			end
		elseif sType == 2 then
			local function printf()
				local msg = module:FormatMsgForChat(module:FormatMsg(str or "", params, true))
				_SendChatMessage(msg, channelName)
			end
			for i=1,duration+1,1 do
				ChatSpamTimers[i] = ScheduleTimer(printf,max(i-1,0.01))
			end
		elseif sType == 3 then
			local function printf()
				local msg = module:FormatMsgForChat(module:FormatMsg(str or "", params, true))
				_SendChatMessage(msg, channelName)
			end
			printf()
		end
	end
end
function module:CheckAllTriggers(trigger)
	local data, reminder = trigger._data, trigger._reminder
	local check = reminder.activeFunc(reminder.triggers)

	--if module.db.debug and data.debug then
	if module.db.debug then
		for i=1,#reminder.triggers do
			print(GetTime(),data.msg,i,reminder.triggers[i].status,reminder.triggers[i]["count"])
		end
		print('CheckAllTriggers',GetTime(),data.name or data.msg,"Check: "..tostring(check))
	end
	if module.db.debugLog then module:DebugLogAdd("CheckAllTriggers",data.name or data.msg,data.uid,check) end

	if not check then
		for i,t in pairs(reminder.triggers) do
			if t ~= trigger and t._trigger.cbehavior == 4 and not reminder.activeFunc2(reminder.triggers,i) then
				-- print("activeFunc2based counter reset")
				t.count = 0
			end
		end
	end


	if check then
		module:ShowReminder(trigger)
	end

	--hide all copies for reminders without duration
	if data.duration == 0 and not check then
		for j=#module.db.showedReminders,1,-1 do
			local showed = module.db.showedReminders[j]
			if showed.data == data then
				if showed.voice then
					showed.voice:Cancel()
				end
				tremove(module.db.showedReminders,j)
			end
		end
		for j=1,#module.db.GlowCancelTimers do
			local glow = module.db.GlowCancelTimers[j]
			if glow and glow.data == data then
				if not glow.timer then
					LCG.PixelGlow_Stop(glow.unitFrame)
					LCG.AutoCastGlow_Stop(glow.unitFrame)
					LCG.ButtonGlow_Stop(glow.unitFrame)
					LCG.ProcGlow_Stop(glow.unitFrame)

					-- tremove(module.db.GlowCancelTimers,j)
				end
			end
		end
		if ChatSpamUntimed and ChatSpamUntimed.data and ChatSpamUntimed.data == data then
			ChatSpamUntimed.timer:Cancel()
		end
		if data.nameplateGlow then
			if reminder.nameplateguid then
				module:NameplateRemoveHighlight(reminder.nameplateguid)
				reminder.nameplateguid = nil
			end
			for guid,list in pairs(module.db.nameplateHL) do
				for uid,t in pairs(list) do
					if t.data == data then
						module:NameplateRemoveHighlight(guid, uid)
					end
				end
			end
		end
	end
end

local function LoadAdvanced(data)
	local reminder = {
		triggers = {},
		data = data,
	}
	reminders[#reminders+1] = reminder
	for i=1,#data.triggers do
		local trigger = data.triggers[i]
		local triggerData = module:CopyTriggerEventForReminder(trigger)

		local triggerNow = {
			_i = i,
			_trigger = triggerData,
			_reminder = reminder,
			_data = data,

			status = false,
			count = 0,
			countsS = {},
			countsD = {},
			active = {},
			statuses = {},

			Dcounter = module:CreateNumberConditions(triggerData.counter),
			DnumberPercent = module:CreateNumberConditions(triggerData.numberPercent),
			Dstacks = module:CreateNumberConditions(triggerData.stacks),

			DdelayTime = module:ConvertMinuteStrToNum(triggerData.delayTime,data.notepat),
			DsourceName = module:CreateStringConditions(triggerData.sourceName),
			DtargetName = module:CreateStringConditions(triggerData.targetName),
			DsourceID = module:CreateMobIDConditions(triggerData.sourceID),
			DtargetID = module:CreateMobIDConditions(triggerData.targetID),
		}
		reminder.triggers[i] = triggerNow

		if trigger.event and module.C[trigger.event] then
			local eventDB = module.C[trigger.event]

			eventsUsed[trigger.event] = true

			local eventTable = module.db.eventsToTriggers[eventDB.name]
			if not eventTable then
				eventTable = {}
				module.db.eventsToTriggers[eventDB.name] = eventTable
			end

			if eventDB.isUntimed and not trigger.activeTime then
				triggerNow.untimed = true
				triggerNow.delays = {}
			end
			if eventDB.extraDelayTable then
				triggerNow.delays2 = {}
			end
			if eventDB.isUntimed and trigger.activeTime then
				triggerNow.ignoreManualOff = true
			end

			if eventDB.subEventField then
				local subEventDB = module.C[ trigger[eventDB.subEventField] ]
				if subEventDB then
					for _,subRegEvent in module.IterateTable(subEventDB.events) do
						local subEventTable = eventTable[subRegEvent]
						if not subEventTable then
							subEventTable = {}
							eventTable[subRegEvent] = subEventTable
						end

						subEventTable[#subEventTable+1] = triggerNow
					end
				end
			elseif eventDB.isUnits then
				triggerNow.units = {}

				local units = trigger[eventDB.unitField]

				unitsUsed[units or 0] = true

				if type(units) == "number" then
					if units < 0 then
						units = module.datas.unitsList.ALL
						for j=1,#module.datas.unitsList do
							unitsUsed[j] = true
						end
					else
						units = module.datas.unitsList[units]
					end
				end

				if units then
					for _,unit in module.IterateTable(units) do
						local unitTable = eventTable[unit]
						if not unitTable then
							unitTable = {}
							eventTable[unit] = unitTable
						end

						unitTable[#unitTable+1] = triggerNow
					end
				else
					eventTable[#eventTable+1] = triggerNow
				end
			else
				eventTable[#eventTable+1] = triggerNow
			end
		end
	end
	local triggersStr = ""
	local opened = false
	for i=#data.triggers,2,-1 do
		local trigger = data.triggers[i]
		if not trigger.andor or trigger.andor == 1 then
			triggersStr = "and "..(opened and "(" or "")..(trigger.invert and "not " or "").."t["..i.."].status " .. triggersStr
			opened = false
		elseif trigger.andor == 2 then
			triggersStr = "or "..(opened and "(" or "")..(trigger.invert and "not " or "").."t["..i.."].status " .. triggersStr
			opened = false
		elseif trigger.andor == 3 then
			triggersStr = "or "..(trigger.invert and "not " or "").."t["..i.."].status"..(not opened and ")" or "").." " .. triggersStr
			opened = true
		end
	end
	triggersStr = (opened and "(" or "")..(data.triggers[1].invert and "not " or "").."t[1].status "..triggersStr
	reminder.activeFunc = loadstring("return function(t) return "..triggersStr.." end")()
	reminder.activeFunc2 = loadstring("return function(t,n) local s=t[n].status t[n].status=not t[n]._trigger.invert local r="..triggersStr.." t[n].status=s return r end")()

	reminder.delayedActivation = module:ConvertMinuteStrToNum(data.delay)

	if data.nameplateGlow then
		nameplateUsed = true
	end

	if #data.triggers > 0 then
		module:CheckAllTriggers(reminder.triggers[1])
	end
end
--------------------
---------------------
--------------------
local function InitEvents(zoneID, zoneName)
	for id in pairs(eventsUsed) do
		local eventDB = module.C[id]
		if eventDB and eventDB.events then
			for _,event in module.IterateTable(eventDB.events) do
				if event:find("^BigWigs_") then
					module:RegisterBigWigsCallbackNew(event)
				elseif event:find("^DBM_") then
					module:RegisterDBMCallbackNew(event)
				else
					module:RegisterEvents(event)
				end
			end
		end
	end

	local anyUnit
	for unit in pairs(unitsUsed) do
		if unit == "target" then
			module:RegisterEvents("PLAYER_TARGET_CHANGED")
		elseif unit == "focus" then
			module:RegisterEvents("PLAYER_FOCUS_CHANGED")
		elseif unit == "mouseover" then
			module:RegisterEvents("UPDATE_MOUSEOVER_UNIT")
		elseif (type(unit) == "string" and unit:find("^boss")) or unit == 1 then
			module:RegisterEvents("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		elseif unit == 2 then
			nameplateUsed = true
		end

		anyUnit = true
	end

	if module.db.eventsToTriggers.RAID_GROUP_NUMBER then
		module.main:GROUP_ROSTER_UPDATE()
	end

	if anyUnit then
		module:RegisterEvents("RAID_TARGET_UPDATE")
	end

	if nameplateUsed then
		module:RegisterEvents("NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED")
	end

	if (module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL) and not module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED then
		module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED = {}
	end

	tCOMBAT_LOG_EVENT_UNFILTERED = module.db.eventsToTriggers.COMBAT_LOG_EVENT_UNFILTERED
	tUNIT_HEALTH = module.db.eventsToTriggers.UNIT_HEALTH
	tUNIT_POWER_FREQUENT = module.db.eventsToTriggers.UNIT_POWER_FREQUENT
	tUNIT_ABSORB_AMOUNT_CHANGED = module.db.eventsToTriggers.UNIT_ABSORB_AMOUNT_CHANGED
	tUNIT_AURA = module.db.eventsToTriggers.UNIT_AURA
	tUNIT_TARGET = module.db.eventsToTriggers.UNIT_TARGET
	tUNIT_SPELLCAST_SUCCEEDED = module.db.eventsToTriggers.UNIT_SPELLCAST_SUCCEEDED
	tUNIT_CAST = module.db.eventsToTriggers.UNIT_CAST

	if nameplateUsed then
		module:NameplatesReloadCycle()
	end

	if anyUnit then
		module.main:RAID_TARGET_UPDATE()
	end
	if #reminders > 0 and zoneID and zoneName then
		VExRT.Reminder.zoneNames[zoneID] = zoneName
	end


	if VExRT.Reminder.HistoryEnabled then
		if not module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT then
			module.db.eventsToTriggers.INSTANCE_ENCOUNTER_ENGAGE_UNIT = {}
			module:RegisterEvents("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		end
	end
end

function module:ReloadAll()
	module:ResetPrevZone()
	module:LoadForCurrentZone()
end

function module:UnloadAll()
	module:UnregisterEvents(
		"NAME_PLATE_UNIT_ADDED","NAME_PLATE_UNIT_REMOVED","RAID_TARGET_UPDATE",
		"PLAYER_TARGET_CHANGED","PLAYER_FOCUS_CHANGED","UPDATE_MOUSEOVER_UNIT"
	)

	for _,c in pairs(module.C) do
		if c.id and c.events then
			for _,event in module.IterateTable(c.events) do
				if event:find("^BigWigs_") then
					module:UnregisterBigWigsCallbackNew(event)
				elseif event:find("^DBM_") then
					module:UnregisterDBMCallbackNew(event)
				elseif event == "TIMER" then
					-- module:UnregisterTimer()
				else
					module:UnregisterEvents(event)
				end
			end
		end
	end
	wipe(module.db.eventsToTriggers)

	for i=1,#module.db.timers do
		module.db.timers[i]:Cancel()
	end

	wipe(module.db.timers)
	wipe(module.db.showedReminders)
	wipe(reminders)

	for _,f in pairs(module.db.nameplateFrames) do
		f:Hide()
	end
	wipe(module.db.nameplateHL)
	wipe(module.db.nameplateGUIDToFrames)

	wipe(eventsUsed)
	wipe(unitsUsed)
	nameplateUsed = false

	for j=1,#module.db.GlowCancelTimers do
		local glow = module.db.GlowCancelTimers[j]
		LCG.PixelGlow_Stop(glow.unitFrame)
		LCG.AutoCastGlow_Stop(glow.unitFrame)
		LCG.ButtonGlow_Stop(glow.unitFrame)
		LCG.ProcGlow_Stop(glow.unitFrame)
	end
	wipe(module.db.GlowCancelTimers)

	for i=1,#ChatSpamTimers do
		ChatSpamTimers[i]:Cancel()
	end
	wipe(ChatSpamTimers)
	wipe(ChatSpamUntimed)

	wipe(unitAuras)
	wipe(bossFramesblackList)

	tCOMBAT_LOG_EVENT_UNFILTERED = nil
	tUNIT_HEALTH = nil
	tUNIT_POWER_FREQUENT = nil
	tUNIT_ABSORB_AMOUNT_CHANGED = nil
	tUNIT_AURA = nil
	tUNIT_TARGET = nil
	tUNIT_SPELLCAST_SUCCEEDED = nil
	tUNIT_CAST = nil

	if C_VoiceChat and C_VoiceChat.StopSpeakingText then
		C_VoiceChat.StopSpeakingText()
	end
end

local function CancelSoundTimers(self)
	for i=1,#self do
		self[i]:Cancel()
	end
end

local function OldGo(data,vars,castNumber)
	local newRem = {}
	newRem.expirationTime = GetTime() + (data.duration or 0)
	newRem.dur = data.duration
	newRem.data = data
	newRem.params = vars or {}
	newRem.params.counter = castNumber
	newRem.params.atime  = GetTime() + (data.duration or 0)
	newRem.params.uid = newRem.params.uid or module:GetNextUID()

	--prepeare for setparam
	if data.msg and data.msg:find("{setparam:") then
		module:FormatMsg(data.msg or "",newRem.params)
	end
	--setup frame glow
	if data.glow and data.glow ~= "" then
		module:ParseGlow(data,newRem.params)
	end
	-- Send WA custom event
	if data.sendEvent and data.msg and WeakAuras then
		module:SendWeakAurasCustomEvent(data.msg)
	end
	-- Play tts
	if data.tts and not VExRT.Reminder.disableSound and not VExRT.Reminder.disableSounds[data.token] then
		local LibTranslit = LibStub("LibTranslit-1.0")
        local message = module:FormatMsg(data.tts or "",newRem.params)
		C_VoiceChat.SpeakText(
			VExRT.Reminder.ttsVoice,
			isTtsTranslateNeeded and LibTranslit:Transliterate(message) or message,
			Enum.VoiceTtsDestination.QueuedLocalPlayback,
			VExRT.Reminder.ttsVoiceRate,
			VExRT.Reminder.ttsVoiceVolume)
	end
	-- Play Sound
	if data.sound and not VExRT.Reminder.disableSound and not VExRT.Reminder.disableSounds[data.token] then
		pcall(PlaySoundFile,data.sound, "Master")
	end

	--Show text
	if data.msg and data.duration and not data.sendEvent then
		tinsert(sReminders,newRem)
		frame:Show()
	end
	local reminderDuration = data.duration
	if data.voiceCountdown and reminderDuration ~= 0 and reminderDuration >= 1.3 then
		local clist = {Cancel = CancelSoundTimers}
		local soundTemplate = module.datas.vcdsounds[ data.voiceCountdown ]
		if soundTemplate then
			for i=1,min(5,reminderDuration-0.3) do
				local sound = soundTemplate .. i .. ".ogg"
				local tmr = ScheduleTimer(PlaySoundFile, reminderDuration-(i+0.3), sound, "Master")
				module.db.timers[#module.db.timers+1] = tmr
				clist[#clist+1] = tmr
			end
			newRem.voice = clist
		end
	end
	--Chat Spam
	if data.spamType and data.spamChannel then
		module:SayChatSpam(data,newRem.params)
	end
end

local function CreateFunctions(encounterID,encounterDiff,zoneID,zoneName)
	module:UnloadAll()

	if not module.IsEnabled then
		return
	end

	local myName = ExRT.SDB.charName
	local myClass = select(2,UnitClass'player')
	local role1, role2 = GetPlayerRole()

	wipe(CLEU_SPELL_CAST_SUCCESS)
	wipe(CLEU_SPELL_CAST_START)
	wipe(CLEU_BOSS_PHASE)
	wipe(CLEU_BOSS_START)
	wipe(CLEU_BOSS_HP)
	wipe(CLEU_BOSS_MANA)
	wipe(CLEU_BW_MSG)
	wipe(CLEU_BW_TIMER)
	wipe(CLEU_SPELL_AURA_APPLIED)
	wipe(CLEU_SPELL_AURA_REMOVED)
	wipe(CLEU_SPELL_AURA_APPLIED_SELF)
	wipe(CLEU_SPELL_AURA_REMOVED_SELF)

	isTtsTranslateNeeded = false
	for k,v in pairs(ttsVoices) do
		if v.voiceID == VExRT.Reminder.ttsVoice then
			if v.name:match("English") then
				isTtsTranslateNeeded = true
			end
			break
		end
	end
	-- DevTool:AddData(isTtsTranslateNeeded)
	-- wipe(eventsUsed)
	-- wipe(unitsUsed)
	-- tCOMBAT_LOG_EVENT_UNFILTERED[event] = tCOMBAT_LOG_EVENT_UNFILTERED[event] or {}

	for _,data in pairs(VExRT.Reminder.data) do
		local funcTable
		local triggers
		if data.event == "SPELL_CAST_SUCCESS" then
			funcTable = CLEU_SPELL_CAST_SUCCESS
		elseif data.event == "SPELL_CAST_START" then
			funcTable = CLEU_SPELL_CAST_START
		elseif data.event == "BOSS_PHASE" then
			funcTable = CLEU_BOSS_PHASE
		elseif data.event == "BOSS_START" then
			funcTable = CLEU_BOSS_START
		elseif data.event == "BOSS_HP" then
			funcTable = CLEU_BOSS_HP
		elseif data.event == "BOSS_MANA" then
			funcTable = CLEU_BOSS_MANA
		elseif data.event == "BW_MSG" then
			funcTable = CLEU_BW_MSG
		elseif data.event == "BW_TIMER" or data.event == "BW_TIMER_TEXT" then
			funcTable = CLEU_BW_TIMER
		elseif data.event == "SPELL_AURA_APPLIED" then
			funcTable = CLEU_SPELL_AURA_APPLIED
		elseif data.event == "SPELL_AURA_REMOVED" then
			funcTable = CLEU_SPELL_AURA_REMOVED
		elseif data.event == "SPELL_AURA_APPLIED_SELF" then
			funcTable = CLEU_SPELL_AURA_APPLIED_SELF
		elseif data.event == "SPELL_AURA_REMOVED_SELF" then
			funcTable = CLEU_SPELL_AURA_REMOVED_SELF
		elseif data.event == "ADVANCED" and
			data.triggers and #data.triggers > 0 and
			(not VExRT.Reminder.disabled[data.token]) and not data.disabled and
			(not data.doNotLoadOnBosses or not encounterID) and
			(
				(not data.boss and not data.zoneID) or
				(encounterID  and data.boss == encounterID and (not data.diff or data.diff == encounterDiff)) or
				(zoneID and module:FindNumberInString(zoneID,data.zoneID))
			) and
			module:CheckPlayerCondition(data,myName,myClass,role1, role2)

		then
			LoadAdvanced(data)
		end
		if funcTable and not VExRT.Reminder.disabled[ data.token ] and not data.disabled and
			(not data.doNotLoadOnBosses or not encounterID) and
			(
				(not data.boss and not data.zoneID) or
				(encounterID and data.boss == encounterID and (not data.diff or data.diff == encounterDiff)) or
				(zoneID and module:FindNumberInString(zoneID,data.zoneID))
			) and
			module:CheckPlayerCondition(data,myName,myClass,role1, role2)
		then
			reminders[#reminders+1] = {
				data = data,
				triggers = {},
			}
			local newFunc
			if data.event == "BW_TIMER" or data.event == "BW_TIMER_TEXT" then
				newFunc = function(castNumber,barText,callUID,expirationTime,vars)
					if data.cast then
						local c = data.cast
						if type(c) == 'number' then
							if c < 0 then
								c = -c
								local c1,c2 = floor(c),floor((c % 1) * 10)
								if (castNumber % c1) ~= c2 then
									return
								end
							else
								if castNumber ~= data.cast then
									return
								end
							end
						elseif type(c) == 'string' then
							local castBool = false
							local castsArray = {strsplit(",", c)}
							if castsArray then
								for i=1,#castsArray do
									if castNumber  == tonumber(castsArray[i]) then
										castBool = true
									end
								end
							end
							if not castBool then
								return
							end
						end
					end
					local go = function()
						if bwBars[barText] ~= callUID and (not dbmBars[barText] or (dbmBars[barText] and dbmBars[barText].curr_uid ~= callUID)) then
							return
						end

						OldGo(data,vars,castNumber)



					end

					if data.delay and data.delay ~= "" then
						local d = data.delay
						local now = GetTime()
						if tonumber(d) then
							if expirationTime - tonumber(d) < now then return end
							ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer((expirationTime - tonumber(d)) - now,go)
						else
							for w in string_gmatch(d,"[^, ]+") do
								local delayNum = tonumber(w)
								if delayNum then
									if expirationTime - delayNum < now then return end
									ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer(expirationTime - delayNum,go)
								else
									local m,s,ms = w:match("(%d+):(%d+)%.?(%d*)")
									if m and s then
										m = tonumber(m)
										s = tonumber(s)
										ms = ms and tonumber("0."..ms) or 0
										local rn = m * 60 + s + ms
										if expirationTime - rn < now then return end
										ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer(expirationTime - rn,go)
									end
								end
							end
						end
					end
				end
			else
				newFunc = function(castNumber,sourceGUID,sourceMark,globalCastNumber,vars)
					if data.cast and data.event ~= "BOSS_HP" and data.event ~= "BOSS_START" then
						local currCastNumber = data.globalCounter and globalCastNumber or castNumber
						local c = data.cast
						if type(c) == 'number' then
							if c < 0 then
								c = -c
								local c1,c2 = floor(c),floor((c % 1) * 10)
								if (currCastNumber % c1) ~= c2 then
									return
								end
							else
								if currCastNumber ~= data.cast then
									return
								end
							end
						elseif type(c) == 'string' then
							local castBool = false
							local castsArray = {strsplit(",", c)}
							if castsArray then
								for i=1,#castsArray do
									if currCastNumber  == tonumber(castsArray[i]) then
										castBool = true
									end
								end
							end
							if not castBool then
								return
							end
						end
					end
					if data.condition and data.event ~= "BOSS_HP" and data.event ~= "BOSS_MANA" and data.event ~= "BOSS_PHASE" and data.event ~= "BOSS_START" then
						local c = data.condition
						if c == "target" then
							if UnitGUID'target' ~= sourceGUID then
								return
							end
						elseif c == "focus" then
							if UnitGUID'focus' ~= sourceGUID then
								return
							end
						elseif c == "mouseover" then
							if UnitGUID'mouseover' ~= sourceGUID then
								return
							end
						elseif type(c) == 'number' then
							if FlagMarkToIndex[sourceMark] ~= c then
								return
							end
						end
					end
					local go = function()
						if (data.event == "BOSS_PHASE" and (ActivePhase ~= tonumber(data.spellID) or ActiveEncounterStart ~= globalCastNumber)) or
							(data.event == "BOSS_START" and (ActiveEncounterStart ~= globalCastNumber)) then
							return
						end

						OldGo(data,vars,data.globalCounter and globalCastNumber or castNumber)


					end
					if data.delay and data.delay ~= "" then
						local d = data.delay
						if tonumber(d) then
							ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer(tonumber(d),go)
						else
							for w in string_gmatch(d,"[^, ]+") do
								local delayNum = tonumber(w)
								if delayNum then
									ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer(delayNum,go)
								else
									local m,s,ms = w:match("(%d+):(%d+)%.?(%d*)")
									if m and s then
										m = tonumber(m)
										s = tonumber(s)
										ms = ms and tonumber("0."..ms) or 0
										local rn = m * 60 + s + ms
										ActiveDelays[#ActiveDelays+1] = C_Timer.NewTimer(rn,go)
									end
								end
							end
						end
					else
						go()
					end
				end
			end
			--функции с использованием spellID храняться в funcTable
			--функции без использования spellID храняться в ff
			if (data.event == "SPELL_CAST_SUCCESS" or data.event == "SPELL_CAST_START"
					or data.event == "SPELL_AURA_APPLIED" or data.event == "SPELL_AURA_REMOVED"
					or data.event == "SPELL_AURA_APPLIED_SELF" or data.event == "SPELL_AURA_REMOVED_SELF") then
				funcTable[tonumber(data.spellID)] = funcTable[tonumber(data.spellID)] or {}
				funcTable[tonumber(data.spellID)][ #funcTable[tonumber(data.spellID)] + 1 ] = newFunc
			elseif (data.event == "BW_MSG" or data.event == "BW_TIMER") then
				funcTable[tonumber(data.spellID)] = funcTable[tonumber(data.spellID)] or {}
				funcTable[tonumber(data.spellID)][ #funcTable[tonumber(data.spellID)] + 1 ] = newFunc
			elseif (data.event == "BW_TIMER_TEXT") then
				funcTable[data.spellID] = funcTable[data.spellID] or {}
				funcTable[data.spellID][ #funcTable[data.spellID] + 1 ] = newFunc
			elseif data.event == "BOSS_HP" or data.event == "BOSS_MANA" then
				local condition = type(data.condition) == 'nil' and "boss1" or data.condition
				if type(condition) == 'string' and type(data.spellID) == 'number' then
					funcTable[condition] = funcTable[condition] or {}
					funcTable[condition][data.spellID] = funcTable[condition][data.spellID] or {}
					local ff = funcTable[condition][data.spellID]
					ff[#ff+1] = newFunc
					-- if data.event ==  "BOSS_HP" then
					-- CLEU_BOSS_HP_EID[data.boss] = 1
					-- elseif data.event == "BOSS_MANA" then
					-- CLEU_BOSS_MANA_EID[data.boss] = 1
					-- end
				end
			elseif data.boss and data.event == "BOSS_PHASE" then
				funcTable[data.boss] = funcTable[data.boss] or {}
				funcTable[data.boss][tonumber(data.spellID)] = funcTable[data.boss][tonumber(data.spellID)] or {}
				local ff = funcTable[data.boss][tonumber(data.spellID)]
				ff[#ff+1] = newFunc
			elseif data.boss and data.event == "BOSS_START" then
				funcTable[data.boss] = funcTable[data.boss] or {}
				local ff = funcTable[data.boss]
				ff[#ff+1] = newFunc
			end
		end
	end
	InitEvents(zoneID,zoneName)
end

function module.options:Load()
	self:CreateTilte()

	if ExRT.locale ~= "ruRU" then
		local localeCheck = ELib:Check(self,"Force RU locale",VExRT.Reminder.forceRUlocale):Point(640,-2):Size(18,18):OnClick(function(self)
		VExRT.Reminder.forceRUlocale = self:GetChecked()
			ReloadUI()
		end)

	end

	-- self.HelpPlate = {
	-- FramePos = { x = 0, y = 0 },FrameSize = { width = 660, height = 615 },
	-- [1] = { ButtonPos = { x = 50,	y = -42 },  	HighLightBox = { x = 5, y = -25, width = 660, height = 80 },		ToolTipDir = "RIGHT",	ToolTipText = L.inviteHelpRaid },
	-- [2] = { ButtonPos = { x = 50,  y = -128 }, 	HighLightBox = { x = 5, y = -110, width = 660, height = 105 },		ToolTipDir = "RIGHT",	ToolTipText = L.inviteHelpAutoInv },
	-- [3] = { ButtonPos = { x = 50,  y = -212 }, 	HighLightBox = { x = 5, y = -220, width = 660, height = 30 },		ToolTipDir = "RIGHT",	ToolTipText = L.inviteHelpAutoAccept },
	-- [4] = { ButtonPos = { x = 50,  y = -280},  	HighLightBox = { x = 5, y = -255, width = 660, height = 135 },		ToolTipDir = "RIGHT",	ToolTipText = L.inviteHelpAutoPromote },
	-- }
	-- if not ExRT.isClassic then
	-- self.HELPButton = ExRT.lib.CreateHelpButton(self,self.HelpPlate)
	-- self.HELPButton:SetPoint("CENTER",self,"TOPLEFT",0,15)
	-- end

    --[[
    df encounterIDtoEJ

    JournalEncounterID  Name                Map                         DisplayID DungeonEncounterID InstanceID Patch
    2471	Hackclaw's War-Band	            Brackenhide Hollow	        105696	2570	2520	10.0.0
    2472	Gutshot	                        Brackenhide Hollow	        109135	2567	2520	10.0.0
    2473	Treemouth	                    Brackenhide Hollow	        106294	2568	2520	10.0.0
    2474	Decatriarch Wratheye	        Brackenhide Hollow	        106069	2569	2520	10.0.0
    2475	The Lost Dwarves	            Uldaman: Legacy of Tyr	    105887	2555	2451	10.0.0
    2476	Emberon	                        Uldaman: Legacy of Tyr	    107816	2558	2451	10.0.0
    2477	Balakar Khan	                The Nokhud Offensive	    107680	2580	2516	10.0.0
    2478	Teera and Maruuk	            The Nokhud Offensive	    105721	2581	2516	10.0.0
    2479	Chrono-Lord Deios	            ldaman: Legacy of Tyr	    106056	2559	2451	10.0.0
    2483	Telash Greywing	The             Azure Vault	                109087	2583	2515	10.0.0
    2484	Sentinel Talondras	            Uldaman: Legacy of Tyr	    106790	2557	2451	10.0.0
    2485	Kokia Blazehoof	Ruby            Life Pools	                106851	2606	2521	10.0.0
    2487	Bromach	                        Uldaman: Legacy of Tyr	    107143	2556	2451	10.0.0
    2488	Melidrussa Chillworn	        Ruby Life Pools	            106891	2609	2521	10.0.0
    2489	Forgemaster Gorek	            Neltharus	                107189	2612	2519	10.0.0
    2490	Chargath, Bane of Scales	    Neltharus	                108248	2613	2519	10.0.0
    2492	Leymor	                        The Azure Vault	            107127	2582	2515	10.0.0
    2494	Magmatusk	                    Neltharus	                102604	2610	2519	10.0.0
    2495	Crawth	                        Algeth'ar Academy	        64923	2564	2526	10.0.0
    2497	The Raging Tempest	            The Nokhud Offensive	    107145	2636	2516	10.0.0
    2498	Granyth	                        The Nokhud Offensive	    105823	2637	2516	10.0.0
    2501	Warlord Sargha	                Neltharus	                107029	2611	2519	10.0.0
    2503	Kyrakka and Erkhart Stormvein	Ruby Life Pools	            107137	2623	2521	10.0.0
    2504	Watcher Irideus	                Halls of Infusion	        106801	2615	2527	10.0.0
    2505	Azureblade	                    The Azure Vault	            106829	2585	2515	10.0.0
    2507	Gulping Goliath	                Halls of Infusion	        103584	2616	2527	10.0.0
    2508	Umbrelskul	                    The Azure Vault	            106802	2584	2515	10.0.0
    2509	Vexamus	                        Algeth'ar Academy	        107525	2562	2526	10.0.0
    2510	Khajin the Unyielding	        Halls of Infusion	        107064	2617	2527	10.0.0
    2511	Primal Tsunami	                Halls of Infusion	        106934	2618	2527	10.0.0
    2512	Overgrown Ancient	            Algeth'ar Academy	        109194	2563	2526	10.0.0
    2514	Echo of Doragosa	            Algeth'ar Academy	        108925	2565	2526	10.0.0


    2521	Chronikar	                    Dawn of the Infinite	    111556	2666	2579	10.1.5
    2526	Tyr, the Infinite Keeper	    Dawn of the Infinite	    112999	2670	2579	10.1.5
    2528	Manifested Timeways	            Dawn of the Infinite	    113190	2667	2579	10.1.5
    2533	Time-Lost Battlefield	        Dawn of the Infinite	    112017	2672	2579	10.1.5
    2534	Time-Lost Battlefield	        Dawn of the Infinite	    112018	2672	2579	10.1.5
    2535	Blight of Galakrond	            Dawn of the Infinite	    112066	2668	2579	10.1.5
    2536	Morchie	                        Dawn of the Infinite	    111457	2671	2579	10.1.5
    2537	Iridikron the Stonescaled	    Dawn of the Infinite	    105326	2669	2579	10.1.5
    2538	Chrono-Lord Deios	            Dawn of the Infinite	    106056	2673	2579	10.1.5



    ]]
    local DFDencounterIDtoEJ = {
        [2555] = 2475,
        [2556] = 2487,
        [2557] = 2484,
        [2558] = 2476,
        [2559] = 2479,
        [2562] = 2509,
        [2563] = 2512,
        [2564] = 2495,
        [2565] = 2514,
        [2567] = 2472,
        [2568] = 2473,
        [2569] = 2474,
        [2570] = 2471,
        [2580] = 2477,
        [2581] = 2478,
        [2582] = 2492,
        [2583] = 2483,
        [2584] = 2508,
        [2585] = 2505,
        [2606] = 2485,
        [2609] = 2488,
        [2610] = 2494,
        [2611] = 2501,
        [2612] = 2489,
        [2613] = 2490,
        [2615] = 2504,
        [2616] = 2507,
        [2617] = 2510,
        [2618] = 2511,
        [2623] = 2503,
        [2636] = 2497,
        [2637] = 2498,
        [2666] = 2521,
        [2667] = 2528,
        [2668] = 2535,
        [2669] = 2537,
        [2670] = 2526,
        [2671] = 2536,
        [2672] = 2533,
        [2673] = 2538,

        [2820] = 2564,
        [2709] = 2554,
        [2737] = 2557,
        [2728] = 2555,
        [2731] = 2553,
        [2708] = 2556,
        [2824] = 2563,
        [2786] = 2565,
        [2677] = 2519,

    }
	local encounterIDtoEJidChache = {
	}
	LR.bossName = setmetatable({}, {__index=function (t, k)
		if not encounterIDtoEJidChache[k] then
			encounterIDtoEJidChache[k] = EJ_GetEncounterInfo(DFDencounterIDtoEJ[k] or 0) or ""
		end
		return encounterIDtoEJidChache[k]
	end})

	ExRT.lib:Text(self,"v"..DATA_VERSION.. " |cFFC69B6Dm33shoq tweak|r |cff0080ffDiscord for feedback and bug reports: m33shoq|r",13):Point("BOTTOMLEFT",self.title,"BOTTOMRIGHT",5,2)
	local encountersList = {}
	if ExRT.is11 then
		encountersList = ExRT.F.GetEncountersList(true, nil, true)
	elseif ExRT.isLK then
		--EncounterID from https://wowpedia.fandom.com/wiki/DungeonEncounterID
		--DisplayID from https://wowpedia.fandom.com/wiki/JournalEncounterID
		encountersList = {
			{ "Icecrown Citadel",
				{ 845, "|cff0070ddLord Marrowgar|r",          31119 }, -- Blue
				{ 846, "|cff0070ddLady Deathwhisper|r",       30893 }, -- Blue
				{ 847, "|cffcc99ffIcecrown Gunship Battle|r", 30416 }, -- Light Purple
				{ 848, "|cffcc99ffDeathbringer Saurfang|r",   30790 }, -- Light Purple
				{ 849, "|cff66ff99Festergut|r",               31006 }, -- Light Toxic Green
				{ 850, "|cff66ff99Rotface|r",                 31005 }, -- Light Toxic Green
				{ 851, "|cff66ff99Professor Putricide|r",     30881 }, -- Light Toxic Green
				{ 852, "|cffff6666Blood Council|r",           30858 }, -- Light Red
				{ 853, "|cffff6666Queen Lana'thel|r",         31165 }, -- Light Red
				{ 854, "|cff00cc66Valithria Dreamwalker|r",   30318 }, -- Light Emerald Green
				{ 855, "|cff00cc66Sindragosa|r",              30362 }, -- Light Emerald Green
				{ 856, "|cff99ccffThe Lich King|r",           30721 }, -- Light Blue
			},
			{ "Trial of the Crusader",
				{ 629, "|cff0070ddNorthrend Beasts|r",  29614 }, -- Blue
				{ 633, "|cff0070ddLord Jaraxxus|r",     29615 }, -- Blue
				{ 637, "|cff0070ddFaction Champions|r", 29770 }, -- Blue
				{ 641, "|cffadd8e6Val'kyr Twins|r",     29240 }, -- Ice Blue
				{ 645, "|cffadd8e6Anub'arak|r",         29268 }, -- Ice Blue
			},
			{ "Ulduar",
				{ 744, "|cff00ffffFlame Leviathan|r",          28875 },
				{ 745, "|cff00ffffIgnis the Furnace Master|r", 29185 },
				{ 746, "|cff00ffffRazorscale|r",               28787 },
				{ 747, "|cff00ffffXT-002 Deconstructor|r",     28611 },
				{ 748, "|cffff8000The Assembly of Iron|r",     28344 },
				{ 749, "|cffff8000Kologarn|r",                 28638 },
				{ 750, "|cffff8000Auriaya|r",                  28651 },
				{ 751, "|cff80ff00Hodir|r",                    28743 },
				{ 752, "|cff80ff00Thorim|r",                   28977 },
				{ 753, "|cff80ff00Freya|r",                    28777 },
				{ 754, "|cff80ff00Mimiron|r",                  28578 },
				{ 755, "|cffa953ffGeneral Vezax|r",            28548 },
				{ 756, "|cffa953ffYogg-Saron|r",               28817 },
				{ 757, "|cffa953ffAlgalon the Observer|r",     28641 }
			},
			{ "Naxxramas",
				{ 1107, "|cff8787edAnub'Rekhan|r",            15931 },
				{ 1110, "|cff8787edGrand Widow Faerlina|r",   15940 },
				{ 1116, "|cff8787edMaexxna|r",                15928 },
				{ 1117, "|cffa330c9Noth the Plaguebringer|r", 16590 },
				{ 1112, "|cffa330c9Heigan the Unclean|r",     16309 },
				{ 1115, "|cffa330c9Loatheb|r",                16110 },
				{ 1113, "|cffc69b6dInstructor Razuvious|r",   16582 },
				{ 1109, "|cffc69b6dGothik the Harvester|r",   16279 },
				{ 1121, "|cffc69b6dThe Four Horsemen|r",      10729 },
				{ 1118, "|cffff8800Patchwerk|r",              16174 },
				{ 1108, "|cffff8800Gluth|r",                  16064 },
				{ 1111, "|cffff8800Grobbulus|r",              16035 },
				{ 1120, "|cffff8800Thaddius|r",               16137 },
				{ 1119, "|cff55ee55Sapphiron|r",              16033 },
				{ 1114, "|cff55ee55Kel'Thuzad|r",             15945 }
			},
			{ "Eye of Eternity",
				{ 734, "|cff3fc6eaMalygos|r", 26752 }
			},
			{ "Obsidian Sanctum",
				{ 742, "|cffc41e3aSartharion|r", 27035 }
			},
		}

		NameByID = function(fID)
			for i = 1, #encountersList do
				local instance = encountersList[i]
				for j = 2, #instance do
					if instance[j][1] == fID then
						return instance[j][2], instance[j][3]
					end
				end
			end
            return fID, 15556
		end
	end
	local eventsList = {
        {"ADVANCED","|cff80ff00Advanced|r"},
		{"SPELL_CAST_SUCCESS",LR.EventsSCC},
		{"SPELL_CAST_START",LR.EventsSCS},
		{"BOSS_PHASE",LR.EventsBossPhase},
		{"BOSS_START",LR.EventsBossStart},
		{"BOSS_HP",LR.EventsBossHp},
		{"BOSS_MANA",LR.EventsBossMana},
		{"BW_MSG",LR.EventsBWMsg},
		{"BW_TIMER",LR.EventsBWTimer},
		{"BW_TIMER_TEXT",LR.EventsBWTimerText},
		{"SPELL_AURA_APPLIED",LR.EventsSAA},
		{"SPELL_AURA_REMOVED",LR.EventsSAR},
		{"SPELL_AURA_APPLIED_SELF",LR.EventsSAAS},
		{"SPELL_AURA_REMOVED_SELF",LR.EventsSARS},
	}

	local castsList = {
		{nil,LR.All},
		{1,"1"},
		{2,"2"},
		{3,"3"},
		{4,"4"},
		{5,"5"},
		{6,"6"},
		{7,"7"},
		{8,"8"},
		{9,"9"},
		{10,"10"},
		{-2.1,LR.Castse21},
		{-2.0,LR.Castse22},
		{-3.1,LR.Castse31},
		{-3.2,LR.Castse32},
		{-3.0,LR.Castse33},
		{-4.11,LR.Castse41},
		{-4.2,LR.Castse42},
		{-4.31,LR.Castse43},
		{-4.0,LR.Castse44},
		{11,"11"},{12,"12"},{13,"13"},{14,"14"},{15,"15"},{16,"16"},{17,"17"},{18,"18"},{19,"19"},
		{20,"20"},{21,"21"},{22,"22"},{23,"23"},{24,"24"},{25,"25"},{26,"26"},{27,"27"},{28,"28"},{29,"29"},
		{30,"30"},{31,"31"},{32,"32"},{33,"33"},{34,"34"},{35,"35"},{36,"36"},{37,"37"},{38,"38"},{39,"39"},
		{40,"40"},{41,"41"},{42,"42"},{43,"43"},{44,"44"},{45,"45"},{46,"46"},{47,"47"},{48,"48"},{49,"49"},
		{50,"50"},{51,"51"},{52,"52"},{53,"53"},{54,"54"},{55,"55"},{56,"56"},{57,"57"},{58,"58"},{59,"59"},
		{60,"60"},{61,"61"},{62,"62"},{63,"63"},{64,"64"},{65,"65"},{66,"66"},{67,"67"},{68,"68"},{69,"69"},
		{70,"70"},{71,"71"},{72,"72"},{73,"73"},{74,"74"},{75,"75"},{76,"76"},{77,"77"},{78,"78"},{79,"79"},
		{80,"80"},{81,"81"},{82,"82"},{83,"83"},{84,"84"},{85,"85"},{86,"86"},{87,"87"},{88,"88"},{89,"89"},
		{90,"90"},{91,"91"},{92,"92"},{93,"93"},{94,"94"},{95,"95"},{96,"96"},{97,"97"},{98,"98"},{99,"99"},
	}
	local andorList = {
		{1,"AND"},
		{2,"OR"},
		{3,"OR )"},
	}
	local conditionsList = {}
	if ExRT.is11 then
		conditionsList = {
			{nil,"-"},
			{"target",LR.Conditionstarget},
			{"focus",LR.Conditionsfocus},
			{"mouseover","Mouseover"},
			{1,ExRT.F.GetRaidTargetText(1,20)},
			{2,ExRT.F.GetRaidTargetText(2,20)},
			{3,ExRT.F.GetRaidTargetText(3,20)},
			{4,ExRT.F.GetRaidTargetText(4,20)},
			{5,ExRT.F.GetRaidTargetText(5,20)},
			{6,ExRT.F.GetRaidTargetText(6,20)},
			{7,ExRT.F.GetRaidTargetText(7,20)},
			{8,ExRT.F.GetRaidTargetText(8,20)},
			{0,LR.Conditionsnomark},
			{"boss1","boss1"},
			{"boss2","boss2"},
			{"boss3","boss3"},
			{"boss4","boss4"},
			{"boss5","boss5"},
		}
	elseif ExRT.isLK then
		conditionsList = {
			{nil,"-"},
			{"target",LR.Conditionstarget},
			{"focus",LR.Conditionsfocus},
			{"mouseover","Mouseover"},
			{1,ExRT.F.GetRaidTargetText(1,20)},
			{2,ExRT.F.GetRaidTargetText(2,20)},
			{3,ExRT.F.GetRaidTargetText(3,20)},
			{4,ExRT.F.GetRaidTargetText(4,20)},
			{5,ExRT.F.GetRaidTargetText(5,20)},
			{6,ExRT.F.GetRaidTargetText(6,20)},
			{7,ExRT.F.GetRaidTargetText(7,20)},
			{8,ExRT.F.GetRaidTargetText(8,20)},
			{0,LR.Conditionsnomark},
		}
	end
	-- if RAID_TARGET_USE_EXTRA then
	-- for i=16,9,-1 do
	-- tinsert(conditionsList,13,{i,ExRT.F.GetRaidTargetText(i,20)})
	-- end
	-- end
	local spamTypes = {
		{nil,"-"},
		{1,LR.spamType1},
		{2,LR.spamType2},
		{3,LR.spamType3},
	}
	local spamChannels = {
		{nil,"-"},
		{1,LR.spamChannel1},
		{2,LR.spamChannel2},
		{3,LR.spamChannel3},
		{4,LR.spamChannel4},
		{5,LR.spamChannel5},
	}
	local rolesList = {
		{"TANK",LR.RolesTanks},
		{"HEALER",LR.RolesHeals},
		{"DAMAGER",LR.RolesDps},
		{"MHEALER",LR.RolesMheals, LR.RolesMhealsTip},
		{"RHEALER",LR.RolesRheals, LR.RolesRhealsTip},
		{"MDD",LR.RolesMdps},
		{"RDD",LR.RolesRdps},
	}
	local classesList = {
		{"WARRIOR","|cffc69b6dWarrior|r"},
		{"PALADIN","|cfff48cbaPaladin|r"},
		{"HUNTER","|cffaad372Hunter|r"},
		{"ROGUE","|cfffff468Rogue|r"},
		{"PRIEST","|cffffffffPriest|r"},
		{"DEATHKNIGHT","|cffc41e3aDK|r"},
		{"SHAMAN","|cff0070ddShaman|r"},
		{"MAGE","|cff3fc7ebMage|r"},
		{"WARLOCK","|cff8788eeWarlock|r"},
		{"MONK","|cff00ff98Monk|r"},
		{"DRUID","|cffff7c0aDruid|r"},
		{"DEMONHUNTER","|cffa330c9DH|r"},
		{"EVOKER","|cff33937fEvoker|r"},
	}

	local soundsList = {
		--{nil,"-"},
	}
	do
		for name, path in ExRT.F.IterateMediaData("sound") do
			soundsList[#soundsList + 1] = {
				path,
				name,
			}
		end

		sort(soundsList,function(a,b) return a[2]<b[2] end)
		tinsert(soundsList,1,{nil,"-"})
	end
	local diffsList = {}
	if ExRT.is11 then
		diffsList = {
			{nil,LR.DiffsAny},
			{15,LR.DiffsHeroic},
			{16,LR.DiffsMythic},
		}
	elseif ExRT.isLK then
		diffsList = {
			{nil,LR.DiffsAny},
			{175,LR.Diffsn10},
			{176,LR.Diffsn25},
			{193,LR.Diffsh10},
			{194,LR.Diffsh25}
		}
	end
	local GetEncounterSortIndex
	if ExRT.is11 then
		local FullEncountersList = ExRT.F.GetEncountersList(false,nil,true)
		function GetEncounterSortIndex(id,unk)
			for i=1,#FullEncountersList do
				local dung = FullEncountersList[i]
				for j=2,#dung do
					if id == dung[j] then
						return i * 100 + (#dung - j)
					end
				end
			end
			return unk
		end
	elseif ExRT.isLK then
		function GetEncounterSortIndex(id,unk)
			for i=1,#encountersList do
				local dung = encountersList[i]
				for j=2,#dung do
					if id == dung[j][1] then
						return i * 100 + (#dung - j)
					end
				end
			end
			return unk
		end
	end

	local SetupFrame
	local SetupFrameData
	-- local SaveButtonCheck

	local advAlert

	local decorationLine = ELib:DecorationLine(self,true,"BACKGROUND",-5):Point("TOPLEFT",self,0,-25):Point("BOTTOMRIGHT",self,"TOPRIGHT",0,-45)

	decorationLine:SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	self.chkEnable = ELib:Check(self,L.Enable,VExRT.Reminder.enabled):Point(650,-26):Size(18,18):AddColorState():OnClick(function(self)
		VExRT.Reminder.enabled = self:GetChecked()
		if VExRT.Reminder.enabled then
			module:Enable()
		else
			module:Disable()
		end
	end)

	local function mStyledTabs(parent,template,...)
		local newTabs = ELib:Tabs(parent,template,...) --(self, padding, absoluteSize, minWidth, maxWidth, absoluteTextSize)

		tabFont = newTabs.tabs[1].button:GetFontString():GetFont()
		for i=1,#newTabs.tabs do
			if newTabs.tabs[i].button.ButtonState then
				newTabs.tabs[i].button:GetFontString():SetFont(tabFont, 13, "OUTLINE")
				newTabs.resizeFunc(newTabs.tabs[i].button, 0, nil, nil, newTabs.tabs[i].button:GetFontString():GetStringWidth(), newTabs.tabs[i].button:GetFontString():GetStringWidth())
			else
				newTabs.tabs[i].button:GetFontString():SetFont(tabFont, 13)
				newTabs.resizeFunc(newTabs.tabs[i].button, 0, nil, nil, newTabs.tabs[i].button:GetFontString():GetStringWidth(), newTabs.tabs[i].button:GetFontString():GetStringWidth())
			end
		end
		local function TabFrameUpdateTabs(self)
			for i=1,#self.tabs do
				if i == self.selected then
					self.tabs[i].button.Select(self.tabs[i].button)
					self.tabs[i].button:GetFontString():SetFont(tabFont, 13, "OUTLINE")
				else
					self.tabs[i].button.Deselect(self.tabs[i].button)
					self.tabs[i].button:GetFontString():SetFont(tabFont, 13)
				end
				self.tabs[i]:Hide()

				if self.tabs[i].disabled then
					PanelTemplates_SetDisabledTabState(self.tabs[i].button)
				end
			end
			if self.selected and self.tabs[self.selected] then
				self.tabs[self.selected]:Show()
			end
			if self.navigation then
				if self.disabled then
					self.navigation:SetEnabled(nil)
				else
					self.navigation:SetEnabled(true)
				end
			end
		end
		newTabs.UpdateTabs = TabFrameUpdateTabs

		newTabs:SetBackdropBorderColor(0,0,0,0)
		newTabs:SetBackdropColor(0,0,0,0)
		return newTabs
	end

	self.tab = mStyledTabs(self,0,LR["Reminders"],LR["Settings"], "Changelog", LR["Help"], LR.Versions):Point(0,-45):Size(698,570):SetTo(1)

	self.searchEdit = ELib:Edit(self.tab.tabs[1]):AddSearchIcon():Size(170,18):Tooltip(LR.searchTip):Point("RIGHT",self.chkEnable,"LEFT",-5,0):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():lower()
		if text == "" then
			text = nil
		end
		module.options.search = text
		module.options:UpdateData()
	end)

	local SetupFramWidth = 560
	local SetupFrameHeight = 730
	SetupFrame = ELib:Popup(" "):Size(SetupFramWidth,SetupFrameHeight):OnShow(function()
		if not SetupFrameData then
			SetupFrameData = {event="ADVANCED"}
		end
		if module.SetupFrameUpdate then
			module:SetupFrameUpdate(true)
		end
	end)
	SetupFrame:SetClampedToScreen(false)
	SetupFrame.title:SetPoint("TOPLEFT",SetupFrame,"TOPLEFT",10,-5)
	SetupFrame.title:SetPoint("BOTTOMRIGHT",SetupFrame,"TOPRIGHT",-15,-10)
	SetupFrame.title:SetDrawLayer("BACKGROUND",7)

	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SetupFrame,"TOPRIGHT",0,-20):SetVertexColor(0.13,0.13,0.13,0.3)--title background
	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",5):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,-20):Point("TOPRIGHT",SetupFrame,"TOPRIGHT",0,-20)--line between title and scroll frame

	ELib:DecorationLine(SetupFrame,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame,"BOTTOMLEFT",0,32):Point("BOTTOMRIGHT",SetupFrame,"BOTTOMRIGHT",0,0):SetVertexColor(0.13,0.13,0.13,0.3)--save button background

	SetupFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)

	local SetupFrameScroll = ELib:ScrollFrame(SetupFrame):Size(SetupFramWidth,SetupFrameHeight-52):Point("TOPLEFT",SetupFrame,"TOPLEFT",0,-20)

	SetupFrameScroll.C:EnableMouse(false)
	SetupFrameScroll:EnableMouse(false)
	SetupFrameScroll.mouseWheelRange = 120

	SetupFrameScroll:Height(2500)

	SetupFrameScroll.C:SetWidth(SetupFramWidth - 18)
	ELib:Border(SetupFrameScroll,0)
	ELib:DecorationLine(SetupFrameScroll):Point("TOP",SetupFrameScroll,"BOTTOM",0,0):Point("LEFT",SetupFrameScroll):Point("RIGHT",SetupFrameScroll):Size(0,1)
	ELib:Border(SetupFrame,1,.24,.25,.30,1,nil,3)

	local GENERALBORDERFRAME, VISUALBORDERFRAME, LOADBORDERFRAME, TRIGGERSBORDERFRAME, CUSTOMBORDERFRAME
	do
		local function CreateBackground(frame)
			local background = ELib:DecorationLine(frame,true,"BACKGROUND",-7)
			background:SetAllPoints(frame)
			background:SetVertexColor(0.13,0.13,0.13,0.3)--(0.05,0.05,0.05,0.15)
		end
		GENERALBORDERFRAME = CreateFrame("Frame",nil,SetupFrameScroll.C)
		GENERALBORDERFRAME:SetSize(SetupFramWidth - 36,155)
		GENERALBORDERFRAME:SetPoint("TOP",SetupFrameScroll.C,"TOP",0,-30)
		ELib:Border(GENERALBORDERFRAME,1,.24,.25,.30,1,nil,3)
		ELib:Text(GENERALBORDERFRAME,LR["GENERAL"],16):Point("BOTTOM",GENERALBORDERFRAME,"TOP",0,5):Color():Shadow()
		CreateBackground(GENERALBORDERFRAME)

		VISUALBORDERFRAME = CreateFrame("Frame",nil,SetupFrameScroll.C)
		VISUALBORDERFRAME:SetSize(SetupFramWidth - 36,440)
		VISUALBORDERFRAME:SetPoint("TOP",GENERALBORDERFRAME,"BOTTOM",0,-30)
		ELib:Border(VISUALBORDERFRAME,1,.24,.25,.30,1,nil,3)
		ELib:Text(VISUALBORDERFRAME,LR["TEXT, GLOW AND SOUNDS"],16):Point("BOTTOM",VISUALBORDERFRAME,"TOP",0,5):Color():Shadow()
		CreateBackground(VISUALBORDERFRAME)

		LOADBORDERFRAME = CreateFrame("Frame",nil,SetupFrameScroll.C)
		LOADBORDERFRAME:SetSize(SetupFramWidth - 36,485)
		LOADBORDERFRAME:SetPoint("TOP",VISUALBORDERFRAME,"BOTTOM",0,-30)
		ELib:Border(LOADBORDERFRAME,1,.24,.25,.30,1,nil,3)
		ELib:Text(LOADBORDERFRAME,LR["LOAD CONDITIONS"],16):Point("BOTTOM",LOADBORDERFRAME,"TOP",0,5):Color():Shadow()
		CreateBackground(LOADBORDERFRAME)
        ELib:DecorationLine(LOADBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",LOADBORDERFRAME,"TOPLEFT",0,-95):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",0,-95)
        ELib:DecorationLine(LOADBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",LOADBORDERFRAME,"TOPLEFT",0,-160):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",0,-160)
        ELib:DecorationLine(LOADBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",LOADBORDERFRAME,"TOPLEFT",0,-355):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",0,-355)
		--trigger borders

		TRIGGERSBORDERFRAME = CreateFrame("Frame",nil,SetupFrameScroll.C)
		TRIGGERSBORDERFRAME:SetSize(SetupFramWidth - 18,700)
		TRIGGERSBORDERFRAME:SetPoint("TOP",LOADBORDERFRAME,"BOTTOM",0,-156)
		ELib:DecorationLine(SetupFrameScroll.C,true,"BACKGROUND",5):Point("TOPLEFT",LOADBORDERFRAME,"BOTTOMLEFT",-9,-45):Point("TOPRIGHT",LOADBORDERFRAME,"BOTTOMRIGHT",7,-45)
		CreateBackground(TRIGGERSBORDERFRAME)

		ELib:Text(SetupFrameScroll.C,LR["TRIGGERS"],20):Point("TOP",LOADBORDERFRAME,"BOTTOM",0,-18):Color():Shadow()
		ELib:DecorationLine(TRIGGERSBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",TRIGGERSBORDERFRAME,"TOPLEFT",0,0):Point("TOPRIGHT",TRIGGERSBORDERFRAME,"TOPRIGHT",-2,0)
		ELib:DecorationLine(TRIGGERSBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",TRIGGERSBORDERFRAME,"BOTTOMLEFT",0,0):Point("TOPRIGHT",TRIGGERSBORDERFRAME,"BOTTOMRIGHT",-2,0)
		ELib:DecorationLine(TRIGGERSBORDERFRAME,true,"BACKGROUND",5):Point("TOPLEFT",TRIGGERSBORDERFRAME,"TOPLEFT",140,0):Point("BOTTOMLEFT",TRIGGERSBORDERFRAME,"BOTTOMLEFT",140,0)

		CUSTOMBORDERFRAME = CreateFrame("Frame",nil,SetupFrameScroll.C)
		CUSTOMBORDERFRAME:SetSize(SetupFramWidth - 36,400)
		CUSTOMBORDERFRAME:SetPoint("TOP",TRIGGERSBORDERFRAME,"BOTTOM",0,-30)
		ELib:Text(CUSTOMBORDERFRAME,LR["CUSTOM"],16):Point("BOTTOM",CUSTOMBORDERFRAME,"TOP",0,5):Color():Shadow()
		ELib:Border(CUSTOMBORDERFRAME,1,.24,.25,.30,1,nil,3)
		CreateBackground(CUSTOMBORDERFRAME)
	end


	local advSetupFrameUpdate
	local activeFuncText

	local function styledTriggerButton(parent,text,misc)
		local button = ELib:Button(parent,text)
		local state1 = button:GetNormalFontObject()
		local state2 = button:GetDisabledFontObject()
		button.Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button.DisabledTexture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button:SetDisabledFontObject(misc and state2 or state1)
		button:SetNormalFontObject(misc and state1 or state2)
		button.BorderBottom:Hide()
		button.BorderTop:Hide()
		button.BorderLeft:Hide()
		button.BorderRight:Hide()
		button:GetFontString():SetFont(tabFont, 13, "OUTLINE")
		button:GetFontString():SetPoint("LEFT", 4, 0)
		return button
	end
	SetupFrame.border:Hide()

	local subEventField = {}
	local subEventFieldText = {}

	local triggerTabs

	local function SetTriggerPage(page)
		triggerTabs:SetTo(page)
		for j=1,#triggerTabs.nButtons do
			if page == j then
				triggerTabs.nButtons[j]:Disable()
				triggerTabs.nButtons[j]:SetText(LR.Trigger..j.." <<<")
			else
				triggerTabs.nButtons[j]:Enable()
				triggerTabs.nButtons[j]:SetText(LR.Trigger..j)
			end
		end
	end

	local function SwapTriggers(noteFrom,noteTo)
		if noteTo < 1 or noteFrom < 1 or noteTo > #SetupFrameData.triggers or noteFrom > #SetupFrameData.triggers or not SetupFrameData.triggers[noteTo] or not SetupFrameData.triggers[noteFrom] then
			return
		end
		local trigger = ExRT.F.table_copy2(SetupFrameData.triggers[noteTo])

		SetupFrameData.triggers[noteTo] = SetupFrameData.triggers[noteFrom]
		SetupFrameData.triggers[noteFrom] = trigger

		SetupFrame.CreateTriggerTabs(noteTo)
	end


	local UpdateAlerts
	function SetupFrame.CreateTriggerTabs(page)
		wipe(subEventField)
		wipe(subEventFieldText)

		local triggerCount = #SetupFrameData.triggers
		local tabs = {}
		for i=1,triggerCount do
			tinsert(tabs,"trigger "..i)
			tinsert(subEventField,{})
			tinsert(subEventFieldText,{})
		end

		if triggerTabs then triggerTabs:Hide() end --delete old trigger tabs
		triggerTabs = ELib:Tabs(SetupFrameScroll.C,0,unpack(tabs)):Size(400,640):Point("TOPLEFT",SetupFrame,"TOPLEFT",-10,-20)
		triggerTabs.nButtons = {}

		local AddTriggerButton = styledTriggerButton(triggerTabs,LR.AddTrigger,true):Point("TOPLEFT",TRIGGERSBORDERFRAME,"TOPLEFT",0,-1):Size(140,24):OnClick(function()
			tinsert(SetupFrameData.triggers, {event=1});
			SetupFrame.CreateTriggerTabs(#SetupFrameData.triggers);
		end)
		AddTriggerButton.Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		AddTriggerButton:GetFontString():SetFont(tabFont, 13, "OUTLINE")
		AddTriggerButton:GetFontString():SetPoint("LEFT", 4, 0)

		local DeleteTriggerButton = styledTriggerButton(triggerTabs,LR.DeleteTrigger,true):Point("TOPLEFT",AddTriggerButton,"BOTTOMLEFT",0,-2):Size(140,24):OnClick(function()
			local currentTrigger = triggerTabs.selected
			tremove(SetupFrameData.triggers, currentTrigger)
			SetupFrame.CreateTriggerTabs(currentTrigger > 1 and currentTrigger - 1)
		end)
		DeleteTriggerButton.Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		DeleteTriggerButton:GetFontString():SetFont(tabFont, 13, "OUTLINE")
		DeleteTriggerButton:GetFontString():SetPoint("LEFT", 4, 0)

		if #SetupFrameData.triggers < 2 then
			DeleteTriggerButton:Disable()
		end

		for i=1,#triggerTabs.tabs do
			triggerTabs.tabs[i].button:Hide()
			triggerTabs.nButtons[i] = styledTriggerButton(triggerTabs,LR.Trigger..i):Point("TOPLEFT",DeleteTriggerButton,"TOPLEFT",0,(-50*i)-10):Size(140,24):OnClick(function()
				SetTriggerPage(i)
			end)
			if i == 1 then
				triggerTabs.nButtons[i]:Disable()
			end
			triggerTabs.nButtons[i].Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
			triggerTabs.nButtons[i]:GetFontString():SetFont(tabFont, 13, "OUTLINE")
			triggerTabs.nButtons[i]:GetFontString():SetPoint("LEFT", 4, 0)
		end

		triggerTabs:SetBackdropBorderColor(0,0,0,0)
		triggerTabs:SetBackdropColor(0,0,0,0)

		activeFuncText = ELib:Text(triggerTabs,"",11):Point("BOTTOMLEFT",TRIGGERSBORDERFRAME, "TOPLEFT", 5, 5)

		triggerTabs.ButtonMoveUp = CreateFrame("Button",nil,triggerTabs)
		triggerTabs.ButtonMoveUp:Hide()
		triggerTabs.ButtonMoveUp:SetSize(12,12)
		triggerTabs.ButtonMoveUp:SetScript("OnClick",function(self)
			SwapTriggers(self.index,self.index - 1)
		end)
		triggerTabs.ButtonMoveUp.i = triggerTabs.ButtonMoveUp:CreateTexture()
		triggerTabs.ButtonMoveUp.i:SetPoint("CENTER")
		triggerTabs.ButtonMoveUp.i:SetSize(18,18)
		triggerTabs.ButtonMoveUp.i:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		triggerTabs.ButtonMoveUp.i:SetTexCoord(0.25,0.3125,0.625,0.5)

		triggerTabs.ButtonMoveDown = CreateFrame("Button",nil,triggerTabs)
		triggerTabs.ButtonMoveDown:Hide()
		triggerTabs.ButtonMoveDown:SetSize(12,12)
		triggerTabs.ButtonMoveDown:SetScript("OnClick",function(self)
			SwapTriggers(self.index,self.index + 1)
		end)
		triggerTabs.ButtonMoveDown.i = triggerTabs.ButtonMoveDown:CreateTexture()
		triggerTabs.ButtonMoveDown.i:SetPoint("CENTER")
		triggerTabs.ButtonMoveDown.i:SetSize(18,18)
		triggerTabs.ButtonMoveDown.i:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		triggerTabs.ButtonMoveDown.i:SetTexCoord(0.25,0.3125,0.5,0.625)


		function triggerTabs:buttonAdditionalFunc()
			triggerTabs.ButtonMoveUp:Hide()
			triggerTabs.ButtonMoveDown:Hide()

			for i=1,#SetupFrameData.triggers do
				if triggerTabs.selected == i then
					triggerTabs.ButtonMoveUp:SetPoint("BOTTOMRIGHT",triggerTabs.nButtons[i],"RIGHT",-32,0)
					triggerTabs.ButtonMoveDown:SetPoint("TOPRIGHT",triggerTabs.nButtons[i],"RIGHT",-32,0)
					triggerTabs.ButtonMoveUp:SetParent(triggerTabs.nButtons[i])
					triggerTabs.ButtonMoveDown:SetParent(triggerTabs.nButtons[i])
					triggerTabs.ButtonMoveUp.index = i
					triggerTabs.ButtonMoveDown.index = i
					if i > 1 then
						triggerTabs.ButtonMoveUp:Show()
					end
					if i >= 1 and i < #SetupFrameData.triggers then
						triggerTabs.ButtonMoveDown:Show()
					end
					return
				end
			end
		end

		SetTriggerPage(page or 1)

		for i=1,triggerCount do

			subEventField[i] = {}
			subEventFieldText[i] = {}

			if i > 1 then
				subEventField[i]["andor"] = ELib:DropDown(triggerTabs,80,#andorList):Size(80):Point("BOTTOMLEFT",triggerTabs.nButtons[i],"TOPLEFT",0,5)
				do
					local FieldSetValue = function(_,andor)
						ELib:DropDownClose()
						SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
						SetupFrameData.triggers[i].andor = andor
						advSetupFrameUpdate()
					end

					local List = subEventField[i]["andor"].List
					for j=1,#andorList do
						List[#List+1] = {
							text = andorList[j][2],
							arg1 = andorList[j][1],
							func = FieldSetValue,
						}
					end
				end
				subEventField[i]["andor"].BorderBottom:Hide()
				subEventField[i]["andor"].BorderTop:Hide()
				subEventField[i]["andor"].BorderLeft:Hide()
				subEventField[i]["andor"].BorderRight:Hide()
				subEventField[i]["andor"].Background:Hide()
			end
			--ADVANCED EVENT
			subEventField[i]["event"] = ELib:DropDown(triggerTabs.tabs[i],200,#module.datas.events):Size(200):Point("TOPRIGHT",TRIGGERSBORDERFRAME,"TOPRIGHT",-10,-10)
			do
				local FieldSetValue = function(_,event)
					ELib:DropDownClose()
					SetupFrameData.triggers[i] = {event=event}

					advSetupFrameUpdate()
				end

				local List = subEventField[i]["event"].List
				for j=1,#module.datas.events do
					j = module.datas.events[j]
					List[#List+1] = {
						text = module.C[j].lname,
						arg1 = module.C[j].id,
						tooltip = module.C[j].tooltip,
						func = FieldSetValue,
					}
				end
			end
			subEventFieldText[i]["event"] = ELib:Text(subEventField[i]["event"],LR["event"],12):Point("RIGHT",subEventField[i]["event"],"LEFT",-5,0):Right():Middle():Color():Shadow()
			subEventFieldText[i]["event"].help = ELib:Text(subEventField[i]["event"],"help label\nhelplabel",12):Point("TOPLEFT",TRIGGERSBORDERFRAME,"BOTTOMLEFT",145,100):Point("BOTTOMRIGHT",SetupFrameScroll.C,"BOTTOMLEFT",520,20):Top():Left():Color():Shadow()
			for j=1,#module.datas.fields do
				if module.datas.fields[j] == "eventCLEU" then -- eventCLEU
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,#module.C[1].subEvents):Size(200)--:Point("TOPRIGHT", subEventField[i]["event"],"BOTTOMRIGHT",0,-5)
					do
						local FieldSetValue = function(_,subEvent)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i]["eventCLEU"] = subEvent
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List
						for j=1,#module.C[1].subEvents do
							List[#List+1] = {
								text = module.C[module.C[1].subEvents[j]].lname,
								arg1 = module.C[1].subEvents[j],
								--tooltip = module.C[module.C[1].subEvents[j]].help,
								func = FieldSetValue,
							}
						end
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()
				elseif module.datas.fields[j] == "invert" then
					subEventField[i][module.datas.fields[j]] = ELib:Check(triggerTabs.nButtons[i],""):Point("RIGHT",triggerTabs.nButtons[i],"RIGHT",-5,0):Tooltip("If trigger must be active to activate reminder"):OnClick(function(self)
						SetupFrameData.triggers[i]["invert"] = not self:GetChecked()
						advSetupFrameUpdate()
					end)
				elseif module.datas.fields[j] == "onlyPlayer" then
					subEventField[i][module.datas.fields[j]] = ELib:Check(triggerTabs.tabs[i],""):Left():Tooltip("Only show reminder if target is player,\nAll counts will still be proceed"):OnClick(function(self)

						SetupFrameData.triggers[i]["onlyPlayer"] = self:GetChecked()
						advSetupFrameUpdate()
					end)
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR["onlyPlayer"],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				elseif module.datas.fields[j] == "cbehavior" then
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,#module.datas.counterBehavior):Size(200)--:Point("TOPLEFT",module.datas.fields[j] == "guidunit" and subEventField[i][module.datas.fields[j-2]] or subEventField[i][module.datas.fields[j-1]] or triggerTabs.tabs[i],subEventField[i][module.datas.fields[j-1]] and "BOTTOMLEFT" or "TOPLEFT", subEventField[i][module.datas.fields[j-1]] and 0 or 300,subEventField[i][module.datas.fields[j-1]] and -5 or -20)
					do
						local FieldSetValue = function(_,cbehavior)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i]["cbehavior"] = cbehavior
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List
						for j=1,#module.datas.counterBehavior do
							List[#List+1] = {
								text = module.datas.counterBehavior[j][2],
								arg1 = module.datas.counterBehavior[j][1],
								tooltip = module.datas.counterBehavior[j][3],
								func = FieldSetValue,
							}
						end
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				elseif module.datas.fields[j] == "sourceMark" or module.datas.fields[j] == "targetMark" then
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,10):Size(200)--:Point("TOPLEFT",module.datas.fields[j] == "guidunit" and subEventField[i][module.datas.fields[j-2]] or subEventField[i][module.datas.fields[j-1]] or triggerTabs.tabs[i],subEventField[i][module.datas.fields[j-1]] and "BOTTOMLEFT" or "TOPLEFT", subEventField[i][module.datas.fields[j-1]] and 0 or 300,subEventField[i][module.datas.fields[j-1]] and -5 or -20)
					do
						local FieldSetValue = function(_,mark)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i][module.datas.fields[j]] = mark
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List
						for j=1,10 do
							List[#List+1] = {
								text = module.datas.marks[j][2],
								arg1 = module.datas.marks[j][1],
								func = FieldSetValue,
							}
						end
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				elseif module.datas.fields[j] == "sourceUnit" or module.datas.fields[j] == "targetUnit" then
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,#module.datas.units):Size(200)--:Point("TOPLEFT",module.datas.fields[j] == "guidunit" and subEventField[i][module.datas.fields[j-2]] or subEventField[i][module.datas.fields[j-1]] or triggerTabs.tabs[i],subEventField[i][module.datas.fields[j-1]] and "BOTTOMLEFT" or "TOPLEFT", subEventField[i][module.datas.fields[j-1]] and 0 or 300,subEventField[i][module.datas.fields[j-1]] and -5 or -20)
					do
						local FieldSetValue = function(_,unit)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i][module.datas.fields[j]] = unit
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List
						for j=1,#module.datas.units do
							List[#List+1] = {
								text = module.datas.units[j][2] or module.datas.units[j][1],
								arg1 = module.datas.units[j][1],
								func = FieldSetValue,
							}
						end
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				elseif module.datas.fields[j] == "targetRole" then
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,#module.datas.rolesList):Size(200)--:Point("TOPLEFT",subEventField[i][module.datas.fields[j-1]] or triggerTabs.tabs[i],subEventField[i][module.datas.fields[j-1]] and "BOTTOMLEFT" or "TOPLEFT", subEventField[i][module.datas.fields[j-1]] and 0 or 300,subEventField[i][module.datas.fields[j-1]] and -5 or -20)
					do
						local FieldSetValue = function(_,role)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i][module.datas.fields[j]] = role
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List
						for j=1,#module.datas.rolesList do
							List[#List+1] = {
								text = module.datas.rolesList[j][3],
								arg1 = module.datas.rolesList[j][1],
								func = FieldSetValue,
							}
						end
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()
				elseif module.datas.fields[j] == "guidunit" then
					subEventField[i][module.datas.fields[j]] = ELib:DropDown(triggerTabs.tabs[i],200,2):Size(200)--:Point("TOPLEFT",subEventField[i][module.datas.fields[j-1]] or triggerTabs.tabs[i],subEventField[i][module.datas.fields[j-1]] and "BOTTOMLEFT" or "TOPLEFT", subEventField[i][module.datas.fields[j-1]] and 0 or 300,subEventField[i][module.datas.fields[j-1]] and -5 or -20)
					do
						local FieldSetValue = function(_,unit)
							ELib:DropDownClose()
							SetupFrameData.triggers[i] = SetupFrameData.triggers[i] or {}
							SetupFrameData.triggers[i][module.datas.fields[j]] = unit
							advSetupFrameUpdate()
						end

						local List = subEventField[i][module.datas.fields[j]].List

						List[1] = {
							text = LR.Target,
							arg1 = nil,
							func = FieldSetValue,
						}
						List[2] = {
							text = LR.Source,
							arg1 = 1,
							func = FieldSetValue,
						}
					end
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()
				elseif module.datas.fields[j] == "spellID" then
					subEventField[i][module.datas.fields[j]] = ELib:Edit(triggerTabs.tabs[i]):Size(200,20):OnChange(function(self,isUser)
						local text = self:GetText()
						local sid = text or "?"
						if sid and SetupFrameData.triggers[i].eventCLEU ~= "SWING_DAMAGE" and SetupFrameData.triggers[i].eventCLEU ~= "ENVIRONMENTAL_DAMAGE" then
							local spellName,_,spellTexture = GetSpellInfo(sid)
							subEventFieldText[i].spellID.subText:SetText((spellTexture and "|T"..spellTexture..":20|t " or "")..(spellName or ""))
						else
							subEventFieldText[i].spellID.subText:SetText("")
						end
						if not isUser then
							return
						end

						if text == "" then
							text = nil
						end
						SetupFrameData.triggers[i].spellID = tonumber(text)
						UpdateAlerts()
						-- SaveButtonCheck()

					end)
					subEventFieldText[i].spellID = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()
					subEventFieldText[i].spellID.subText = ELib:Text(subEventField[i][module.datas.fields[j]],"",12):Point("LEFT",subEventField[i][module.datas.fields[j]],"BOTTOMLEFT",0,-16):Size(30,20):Point("RIGHT", subEventField[i][module.datas.fields[j]],"BOTTOMRIGHT",0,-16):Middle():Color():Shadow()
				elseif module.datas.fields[j] == "bwtimeleft" then
					subEventField[i][module.datas.fields[j]] = ELib:Edit(triggerTabs.tabs[i]):Size(200,20):OnChange(function(self,isUser)
						local text = self:GetText()

						if not isUser then
							return
						end

						if text == "" then
							text = nil
						end
						SetupFrameData.triggers[i].bwtimeleft = tonumber(text)
						UpdateAlerts()
						-- SaveButtonCheck()
					end)
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()
				elseif module.datas.fields[j] == "activeTime" then
					subEventField[i][module.datas.fields[j]] = ELib:Edit(triggerTabs.tabs[i]):Size(200,20):OnChange(function(self,isUser)
						local text = self:GetText()

						if not isUser then
							return
						end

						if text == "" then
							text = nil
						end
						SetupFrameData.triggers[i].activeTime = tonumber(text)
						UpdateAlerts()
						-- SaveButtonCheck()
					end)
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				else --OTHER FIELDS
					subEventField[i][module.datas.fields[j]] = ELib:Edit(triggerTabs.tabs[i]):Size(200,20):OnChange(function(self,isUser)
						if not isUser then
							return
						end
						local text = self:GetText()
						if text == "" then
							text = nil
						end
						SetupFrameData.triggers[i][module.datas.fields[j]] = text
						UpdateAlerts()
						-- SaveButtonCheck()
					end)
					subEventFieldText[i][module.datas.fields[j]] = ELib:Text(subEventField[i][module.datas.fields[j]],LR[module.datas.fields[j]],12):Point("RIGHT",subEventField[i][module.datas.fields[j]],"LEFT",-5,0):Right():Middle():Color():Shadow()

				end
			end
			subEventField[i]["extraSpellID"]:Tooltip(LR["extraSpellIDTip"])
			subEventField[i]["extraSpellID"]:SetNumeric(true)
			subEventField[i]["spellID"]:SetNumeric(true)
			subEventField[i]["activeTime"]:SetNumeric(true)
			subEventField[i]["bwtimeleft"]:SetNumeric(true)
			subEventField[i]["delayTime"]:Tooltip(LR.delayTip)

			subEventField[i]["counter"]:Tooltip(LR["NumberCondition"])
			subEventField[i]["numberPercent"]:Tooltip(LR["NumberCondition"])
			subEventField[i]["stacks"]:Tooltip(LR["NumberCondition"])

			subEventField[i]["targetName"]:Tooltip(LR["StringCondition"])
			subEventField[i]["sourceName"]:Tooltip(LR["StringCondition"])

			subEventField[i]["targetID"]:Tooltip(LR["UnitIDCondition"])
			subEventField[i]["sourceID"]:Tooltip(LR["UnitIDCondition"])
		end
		advSetupFrameUpdate()
	end

	local function GetMapNameByID(mapID)
		return (C_Map.GetMapInfo(mapID or 0) or {}).name or ("Map ID "..mapID)
	end

    SetupFrame.disabled = ELib:Check(SetupFrameScroll.C,LR["Enabled:"]):Tooltip(LR["Transmitted when sending"]):Point("TOP",GENERALBORDERFRAME,"TOP",-100,-15):TextSize(12):Left(7):AddColorState():OnClick(function(self)
        SetupFrameData.disabled = not self:GetChecked()
        module:SetupFrameUpdate()
    end)

	SetupFrame.bossList = ELib:DropDown(SetupFrameScroll.C,220,15):AddText(LR.Boss):Size(220):Point("TOP",GENERALBORDERFRAME,"TOP",0,-40)
	do
		local function bossList_SetValue(_,encounterID)
			SetupFrameData.boss = encounterID
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.bossList.List
		if ExRT.is11 then
			for i=1,#encountersList do
				local instance = encountersList[i]
				List[#List+1] = {
					text = type(instance[1])=='string' and instance[1] or GetMapNameByID(instance[1]) or "???",
					isTitle = true,
				}
				for j=2,#instance do
					if L.bossName[ instance[j] ] ~= "" then
						List[#List+1] = {
							text  = L.bossName[ instance[j] ],
							arg1 = instance[j],
							func = bossList_SetValue,
						}
					else
						List[#List+1] = {
							text = instance[j],
							arg1 = instance[j],
							func = bossList_SetValue,
						}
					end
				end
			end
		elseif ExRT.isLK then
			for i=1,#encountersList do
				local instance = encountersList[i]
				List[#List+1] = {
					text = type(instance[1])=='string' and instance[1] or GetMapNameByID(instance[1]) or "???",
					isTitle = true,
				}
				for j=2,#instance do
					List[#List+1] = {
						text = NameByID( instance[j][1] ),
						arg1 = instance[j][1],
						func = bossList_SetValue,
					}
				end
			end
		end
		List[#List+1] = {
			text = LR.Any,
			isTitle = true,
		}
		List[#List+1] = {
			text = LR.AnyAlways,
			func = bossList_SetValue,
		}
	end

	SetupFrame.diffList = ELib:DropDown(SetupFrameScroll.C,200,ExRT.is11 and 3 or 5):Size(100):Point("LEFT",SetupFrame.bossList,"RIGHT",5,0)
	do
		local function diffList_SetValue(_,diff)
			SetupFrameData.diff = diff
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.diffList.List
		for i=1,#diffsList do
			List[#List+1] = {
				text = diffsList[i][2],
				arg1 = diffsList[i][1],
				func = diffList_SetValue,
			}
		end
	end

	------------------
	SetupFrame.BossListRaw = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOPLEFT",SetupFrame.bossList,"TOPLEFT",0,0):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.boss = tonumber(text)
		module:SetupFrameUpdate()
	end)
	ELib:Text(SetupFrame.BossListRaw,LR.EncounterID,12):Point("RIGHT",SetupFrame.BossListRaw,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.DiffListRaw = ELib:Edit(SetupFrameScroll.C):Size(100,20):Point("LEFT",SetupFrame.BossListRaw,"RIGHT",5,0):Tooltip(LR.DifficultyID):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.diff = tonumber(text)
		module:SetupFrameUpdate()
	end)
	-- ELib:Text(DiffListRaw,"Encounter ID:",12):Point("RIGHT",DiffListRaw,"LEFT",-5,0):Right():Middle():Color():Shadow()

	local zonesList = {
        {"Amirdrassil",2549},
		{"Aberrus",2569},
	}

	SetupFrame.zone = ELib:DropDown(SetupFrameScroll.C,220,5):Size(220):Point("TOPRIGHT",SetupFrame.bossList,"BOTTOMRIGHT",0,-5)
	do
		local function bossList_SetValue(_,zoneID)
			SetupFrameData.zoneID = tostring(zoneID)
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.zone.List
		for k,v in ipairs(zonesList) do
			List[#List+1] = {
				text = v[1],
				arg1 = v[2],
				func = bossList_SetValue,
			}
		end
	end
	SetupFrame.zoneText = ELib:Text(SetupFrame.zone,LR.Zone,12):Point("RIGHT",SetupFrame.zone,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.zoneRaw = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOPRIGHT",SetupFrame.bossList,"BOTTOMRIGHT",0,-5):Tooltip(LR.commaTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.zoneID = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.zoneRawText = ELib:Text(SetupFrame.zoneRaw,LR.ZoneID,12):Point("RIGHT",SetupFrame.zoneRaw,"LEFT",-5,0):Right():Middle():Color():Shadow()
	SetupFrame.zoneRaw:Hide()

	SetupFrame.ZoneSetButton = ELib:mStyledButton(SetupFrameScroll.C,"Set Current Zone"):FontSize(12):Size(100,20):Point("LEFT",SetupFrame.zoneRaw,"RIGHT",5,0):OnClick(function()
		SetupFrameData.zoneID = select(8,GetInstanceInfo())
		module:SetupFrameUpdate()
	end)

	SetupFrame.name = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOPRIGHT",SetupFrame.zone,"BOTTOMRIGHT",0,-5):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.name = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.nameText = ELib:Text(SetupFrame.name,LR.Name,12):Point("RIGHT",SetupFrame.name,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.doNotLoadOnBosses = ELib:Check(SetupFrameScroll.C,""):Point("TOPLEFT",SetupFrame.name,"BOTTOMLEFT",0,-5):OnClick(function(self)
		SetupFrameData.doNotLoadOnBosses = self:GetChecked()
		module:SetupFrameUpdate()
	end)
	SetupFrame.doNotLoadOnBossesText = ELib:Text(SetupFrame.doNotLoadOnBosses,LR.doNotLoadOnBosses,12):Point("RIGHT",SetupFrame.doNotLoadOnBosses,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.msg = ELib:MultiEdit(SetupFrameScroll.C):Size(490,90):Point("TOP",VISUALBORDERFRAME,"TOP",0,-25):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():gsub("\n","\\n")
		if text == "" then
			text = nil
		end

		SetupFrameData.msg = text
		module:SetupFrameUpdate()
	end)
    do
        SetupFrame.msgText = ELib:Text(SetupFrame.msg,"",12):Point("BOTTOMLEFT",SetupFrame.msg,"TOPLEFT",0,5):Right():Middle():Color():Shadow()
        ELib:DecorationLine(SetupFrame.msg,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame.msg,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SetupFrame.msg,"BOTTOMRIGHT",0,0):SetVertexColor(0.0,0.0,0.0,0.25)
        SetupFrame.msg:EnableMouseWheel(false)
        ELib:Border(SetupFrame.msg,1,.24,.25,.30,1)
        local msgFont,msgFontSize,msgFontStyle = SetupFrame.msg.EditBox:GetRegions():GetFont()
        SetupFrame.msg:Font(msgFont,14,msgFontStyle)
        function SetupFrame.msg:ColorBorder(r,g,b,a)
            if type(r) == 'boolean' then
                if r then
                    r,g,b,a = 1,0,0,1
                else
                    r,g,b,a = 0.24,0.25,0.30,1
                end
            elseif not r then
                r,g,b,a = 0.24,0.25,0.30,1
            end
            ELib:Border(SetupFrame.msg,1,r,g,b,a)
        end
    end

	local function AddTextToEditBox(self,text,mypos,noremove)
		local addedText = nil
		if not self then
			addedText = text
		else
			addedText = self.iconText
			if IsShiftKeyDown() then
				addedText = self.iconTextShift
			end
		end
		if not noremove then
			SetupFrame.msg:Insert("")
		end
		local txt = SetupFrame.msg:GetText()
		local pos = SetupFrame.msg.EditBox:GetCursorPosition()
		if not self and type(mypos)=='number' then
			pos = mypos
		end
		txt = string.sub (txt, 1 , pos) .. addedText .. string.sub (txt, pos+1)
		SetupFrame.msg:SetText(txt)
		local adjust = 0
		SetupFrame.msg.EditBox:SetCursorPosition(pos+addedText:len()-adjust)

		SetupFrameData.msg = SetupFrame.msg:GetText()
		module:SetupFrameUpdate()
	end

	SetupFrame.ColorDropDown = ELib:DropDown(SetupFrameScroll.C,170,10):Point("TOPLEFT",SetupFrame.msg,"BOTTOMLEFT",0,-5):Size(130):SetText(L.NoteColor)
	SetupFrame.ColorDropDown.list = {
		{L.NoteColorRed,"|cffff0000"},
		{L.NoteColorGreen,"|cff00ff00"},
		{L.NoteColorBlue,"|cff0000ff"},
		{L.NoteColorYellow,"|cffffff00"},
		{L.NoteColorPurple,"|cffff00ff"},
		{L.NoteColorAzure,"|cff00ffff"},
		{L.NoteColorBlack,"|cff000000"},
		{L.NoteColorGrey,"|cff808080"},
		{L.NoteColorRedSoft,"|cffee5555"},
		{L.NoteColorGreenSoft,"|cff55ee55"},
		{L.NoteColorBlueSoft,"|cff5555ee"},
		{"Lime","|cff80ff00"},
		{"Orange","|cffff8000"},
		{"Blue","|cff0080ff"},
	}
	local classNames = ExRT.GDB.ClassList
	for i,class in ipairs(classNames) do
		local colorTable = RAID_CLASS_COLORS[class]
		if colorTable and type(colorTable)=="table" then
			SetupFrame.ColorDropDown.list[#SetupFrame.ColorDropDown.list + 1] = {L.classLocalizate[class] or class,"|c"..(colorTable.colorStr or "ffaaaaaa")}
		end
	end
	SetupFrame.ColorDropDown:SetScript("OnEnter",function (self)
		ELib.Tooltip.Show(self,"ANCHOR_LEFT",L.NoteColor,{L.NoteColorTooltip1,1,1,1,true},{L.NoteColorTooltip2,1,1,1,true})
	end)
	SetupFrame.ColorDropDown:SetScript("OnLeave",function ()
		ELib.Tooltip:Hide()
	end)
	function SetupFrame.ColorDropDown:SetValue(colorCode)
		ELib:DropDownClose()

		local selectedStart,selectedEnd = SetupFrame.msg:GetTextHighlight()
		colorCode = string.gsub(colorCode,"|","||")
		if selectedStart == selectedEnd then
			AddTextToEditBox(nil,colorCode.."||r",nil,true)
		else
			AddTextToEditBox(nil,"||r",selectedEnd,true)
			AddTextToEditBox(nil,colorCode,selectedStart,true)
		end
	end
for i=1,#SetupFrame.ColorDropDown.list do
		local colorData = SetupFrame.ColorDropDown.list[i]
		SetupFrame.ColorDropDown.List[i] = {
			text = colorData[2]..colorData[1],
			func = SetupFrame.ColorDropDown.SetValue,
			justifyH = "CENTER",
			arg1 = colorData[2],
		}
	end
	SetupFrame.ColorDropDown.Lines = #SetupFrame.ColorDropDown.List


	SetupFrame.replaceDropDown = ELib:DropDown(SetupFrameScroll.C,240,18):Size(220):Point("TOP",SetupFrame.msg,"BOTTOM",0,-5):SetText(LR.AddTextReplacers)


	SetupFrame.sendEventCheck = ELib:Check(SetupFrameScroll.C,LR.CustomEvent,SetupFrameData.sendEvent):Point("LEFT", SetupFrame.replaceDropDown, "RIGHT", 5,0):Tooltip(LR.CustomEventTip):OnClick(function(self)
		SetupFrameData.sendEvent = self:GetChecked()
		module:SetupFrameUpdate()
	end)

	SetupFrame.countdownTypeDropDown = ELib:DropDown(SetupFrameScroll.C,60,#module.datas.countdownType):Size(220):Point("TOP",SetupFrame.replaceDropDown,"BOTTOM",0,-5)
	do
		local function countdownTypeDropDown_SetValue(_,arg1)
			SetupFrameData.countdownType = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.countdownTypeDropDown.List
		for i=1,#module.datas.countdownType do
			List[#List+1] = {
				text = module.datas.countdownType[i][2],
				arg1 = module.datas.countdownType[i][1],
				func = countdownTypeDropDown_SetValue,
			}
		end
	end

	SetupFrame.countdownTypeDropDownText = ELib:Text(SetupFrame.countdownTypeDropDown,LR.CountdownFormat ,12):Point("RIGHT",SetupFrame.countdownTypeDropDown,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.countdownCheck = ELib:Check(SetupFrameScroll.C,LR.countdown):Point("LEFT",SetupFrame.countdownTypeDropDown,"RIGHT",5,0):OnClick(function(self)
		SetupFrameData.countdown = not SetupFrameData.countdown
		module:SetupFrameUpdate()
	end)


	SetupFrame.voiceCountdown = ELib:DropDown(SetupFrameScroll.C,220,15):Size(220):Tooltip("Only for reminders with specified duration(not 0)"):Point("TOP",SetupFrame.countdownTypeDropDown,"BOTTOM",0,-20)
	do
		local function countdowns_SetValue(_,arg1)
			SetupFrameData.voiceCountdown = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end
		local countdowns = module.datas.vcountdowns
		local List = SetupFrame.voiceCountdown.List
		for i=1,#countdowns do
			List[#List+1] = {
				text = countdowns[i][2],
				arg1 = countdowns[i][1],
				func = countdowns_SetValue,
			}
		end
	end

	SetupFrame.voiceCountdownText = ELib:Text(SetupFrame.voiceCountdown,LR.voiceCountdown,12):Point("RIGHT",SetupFrame.voiceCountdown,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.voiceCountdownTestButton = ELib:mStyledButton(SetupFrame.voiceCountdown,"COUNTDOWN TEST"):Size(100,20):FontSize(11):Point("LEFT",SetupFrame.voiceCountdown,"RIGHT",5,0):OnClick(function()
		if SetupFrameData.voiceCountdown then
			local soundTemplate = module.datas.vcdsounds[ SetupFrameData.voiceCountdown ]
			if soundTemplate then
				for i=1,5 do
					local sound = soundTemplate .. i .. ".ogg"
					local tmr = ScheduleTimer(PlaySoundFile, 6-(i+0.3), sound, "Master")
					module.db.timers[#module.db.timers+1] = tmr
				end
			end
		end
	end)


	SetupFrame.sound = ELib:DropDown(SetupFrameScroll.C,220,15):Size(220):Point("TOP",SetupFrame.voiceCountdown,"BOTTOM",0,-5)
	do
		local function soundList_SetValue(_,arg1)
			SetupFrameData.sound = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
			if arg1 then
				PlaySoundFile(arg1, "Master")
			end
		end

		local List = SetupFrame.sound.List
		for i=1,#soundsList do
			List[#List+1] = {
				text = soundsList[i][2],
				arg1 = soundsList[i][1],
				func = soundList_SetValue,
			}
		end
	end

	SetupFrame.soundText = ELib:Text(SetupFrame.sound,LR.sound ,12):Point("RIGHT",SetupFrame.sound,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.SoundTestSetupFrameButton = ELib:mStyledButton(SetupFrame.sound,"SOUND TEST"):Size(100,20):FontSize(11):Point("LEFT",SetupFrame.sound,"RIGHT",5,0):OnClick(function()
		if SetupFrameData.sound and not VExRT.Reminder.disableSound then
			pcall(PlaySoundFile,SetupFrameData.sound, "Master")
		end
	end)

	SetupFrame.tts = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOP",SetupFrame.sound,"BOTTOM",0,-5):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.tts = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.ttsText = ELib:Text(SetupFrame.tts,"Text to Speech:",12):Point("RIGHT",SetupFrame.tts,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.ttsVoiceTestSetupFrameButton = ELib:mStyledButton(SetupFrame.tts,"TTS TEST"):Size(100,20):FontSize(11):Point("LEFT",SetupFrame.tts,"RIGHT",5,0):OnClick(function()
		local LibTranslit = LibStub("LibTranslit-1.0")
		if SetupFrameData.tts then
			C_VoiceChat.SpeakText(VExRT.Reminder.ttsVoice,
				isTtsTranslateNeeded and LibTranslit:Transliterate(SetupFrameData.tts) or SetupFrameData.tts,
				Enum.VoiceTtsDestination.QueuedLocalPlayback,
				VExRT.Reminder.ttsVoiceRate
				,VExRT.Reminder.ttsVoiceVolume)
		end
	end)

	SetupFrame.glow = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOP",SetupFrame.tts,"BOTTOM",0,-20):Tooltip(LR.commaTip .. LR.GlowTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.glow = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.glowText = ELib:Text(SetupFrame.glow,"Raidframe Glow:",12):Point("RIGHT",SetupFrame.glow,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.spamType = ELib:DropDown(SetupFrameScroll.C,220,#spamTypes):Size(220):Point("TOP",SetupFrame.glow,"BOTTOM",0,-20)
	do
		local function spamTypeList_SetValue(_,arg1)
			SetupFrameData.spamType = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.spamType.List
		for i=1,#spamTypes do
			List[#List+1] = {
				text = spamTypes[i][2],
				arg1 = spamTypes[i][1],
				func = spamTypeList_SetValue,
			}
		end
	end
	SetupFrame.spamTypeText = ELib:Text(SetupFrame.spamType,LR.SpamType,12):Point("RIGHT",SetupFrame.spamType,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.spamChannel = ELib:DropDown(SetupFrameScroll.C,150,#spamChannels):Size(220):Point("TOP",SetupFrame.spamType,"BOTTOM",0,-5)
	do
		local function spamTypeList_SetValue(_,arg1)
			SetupFrameData.spamChannel = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.spamChannel.List
		for i=1,#spamChannels do
			List[#List+1] = {
				text = spamChannels[i][2],
				arg1 = spamChannels[i][1],
				func = spamTypeList_SetValue,
			}
		end
	end
	SetupFrame.spamChannelText = ELib:Text(SetupFrame.spamChannel,LR.SpamChannel,12):Point("RIGHT",SetupFrame.spamChannel,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.spamMsg = ELib:Edit(SetupFrameScroll.C):Size(220,20):Point("TOP",SetupFrame.spamChannel,"BOTTOM",0,-5):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.spamMsg = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.spamMsgText = ELib:Text(SetupFrame.spamMsg,LR.SpamMessage,12):Point("RIGHT",SetupFrame.spamMsg,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.addOptionsList = ELib:DropDown(SetupFrameScroll.C,250,5):Size(220):Point("TOP",SetupFrame.spamMsg,"BOTTOM",0,-20)
    SetupFrame.addOptionsListText = ELib:Text(SetupFrame.addOptionsList,LR["AdditionalOptions"],12):Point("RIGHT",SetupFrame.addOptionsList,"LEFT",-5,0):Right():Middle():Color():Shadow()
	do
		local function addOptionsList_SetValue(_,arg1)
			SetupFrameData[arg1] = not SetupFrameData[arg1]
			module:SetupFrameUpdate()
			SetupFrame.addOptionsList.Button:Click()
		end

		local List = SetupFrame.addOptionsList.List
		List[1] = {
			text = LR.copy,
			arg1 = "copy",
			checkable = true,
			checkState = SetupFrameData.copy,
			func = addOptionsList_SetValue,
			tooltip = LR.copyTip,
		}
		List[2] = {
			text = LR.norewrite,
			arg1 = "norewrite",
			checkable = true,
			checkState = SetupFrameData.norewrite,
			func = addOptionsList_SetValue,
			tooltip = LR.norewriteTip,
		}
		List[3] = {
			text = LR.dynamicdisable,
			arg1 = "dynamicdisable",
			checkable = true,
			checkState = SetupFrameData.dynamicdisable,
			func = addOptionsList_SetValue,
			tooltip = LR.dynamicdisableTip,
		}
		List[4] = {
			text = LR.isPersonal,
			arg1 = "isPersonal",
			checkable = true,
			checkState = SetupFrameData.isPersonal,
			func = addOptionsList_SetValue,
			tooltip = LR.isPersonalTip,
		}
		tinsert(List,{text = L.minimapmenuclose, func = function()
				ELib:DropDownClose()
			end})
	end
	local topPos = -10

	local playersChecks = {}
	SetupFrame.playersChecks = playersChecks

	local function CheckPlayerClass(self)
		local r = "#"
		for i=1,3 do
			for j=1,5 do
				if classesList[((i-1)*5+j)] and classesList[((i-1)*5+j)][1] then
					local cFrame = playersChecks[i][j]
					if cFrame:GetChecked() then
						r = r .. cFrame.token .. "#"
					end
				else
					break
				end
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrameData.classes = r
		module:SetupFrameUpdate()
	end

	for i=1,3 do
		playersChecks[i] = {}
		for j=1,5 do
			if classesList[((i-1)*5+j)] and classesList[((i-1)*5+j)][1] then
				playersChecks[i][j] = ELib:Check(SetupFrameScroll.C,classesList[((i-1)*5+j)][2] or ""):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(j-1)*100,-topPos - (i)*25):OnClick(CheckPlayerClass)
				playersChecks[i][j].text:SetWidth(80)
				playersChecks[i][j].text:SetJustifyH("LEFT")
				playersChecks[i][j].token = classesList[((i-1)*5+j)][1]
			else
				break
			end
		end
	end

	topPos = topPos + 15

	local function CheckPlayerClick(self)
		local r = "#"
		local tmp = {}
		for i=4,9 do
			for j=1,5 do
				local cFrame = playersChecks[i][j]
				if cFrame.name and cFrame:GetChecked() then
					r = r .. cFrame.name .. "#"
					tmp[ cFrame.name ] = true
				end
			end
		end
		local allUnits = {strsplit(" ",SetupFrame.otherUnitsEdit:GetText())}
		for i=1,#allUnits do
			local name = allUnits[i]
			if name ~= "" and not tmp[ name ] then
				r = r .. name .. "#"
				tmp[ name ] = true
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrameData.units = r
		module:SetupFrameUpdate()
	end
	for i=4,9 do
		playersChecks[i] = {}
		for j=1,5 do
			playersChecks[i][j] = ELib:Check(SetupFrameScroll.C,"Player "..((i-1)*5+j)):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(j-1)*100,-65-topPos - (i)*25):OnClick(CheckPlayerClick)
			playersChecks[i][j].text:SetWidth(80)
			playersChecks[i][j].text:SetJustifyH("LEFT")
		end
	end

	local function CheckPlayerRole()
		local r = "#"
		for j=1,#rolesList do
			local cFrame = playersChecks[10][j]
			if cFrame:GetChecked() then
				r = r .. cFrame.token .. "#"
			end
		end
		if r == "#" then
			r = nil
		end
		SetupFrameData.roles = r
		module:SetupFrameUpdate()
	end
	topPos = topPos + 15

	playersChecks[10] = {}
	for i=1,#rolesList do
		playersChecks[10][i] = ELib:Check(SetupFrameScroll.C,rolesList[i][2]):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(i-1)*100,165-topPos - (11-1)*25):OnClick(CheckPlayerRole)
		playersChecks[10][i].text:SetWidth(80)
		playersChecks[10][i].text:SetJustifyH("LEFT")

		playersChecks[10][i].token = rolesList[i][1]
		playersChecks[10][i]:Tooltip(rolesList[i][3])
	end
	playersChecks[10][6]:Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(3)*100,(165-topPos - (11-1)*25) - 25)
	playersChecks[10][7]:Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(4)*100,(165-topPos - (11-1)*25) - 25)


    -- topPos = topPos + 50
	playersChecks[11] = ELib:Check(SetupFrameScroll.C,LR.AllPlayers):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(1-1)*100,-25-topPos - (12-1)*25):OnClick(function(self)
		self:SetChecked(true)
		SetupFrameData.roles = nil
		SetupFrameData.units = nil
		module:SetupFrameUpdate()
	end)
	playersChecks[11].text:SetWidth(80)
	playersChecks[11].text:SetJustifyH("LEFT")

	playersChecks[12] = ELib:Check(SetupFrameScroll.C,LR.Reverse):Tooltip(LR.ReverseTip):Point("TOPRIGHT",LOADBORDERFRAME,"TOPRIGHT",-494+(2-1)*100,-25-topPos - (12-1)*25):OnClick(function(self)
		if SetupFrameData.reversed then
			self:SetChecked(false)
			SetupFrameData.reversed = false
		else
			self:SetChecked(true)
			SetupFrameData.reversed = true
		end
		module:SetupFrameUpdate()
	end)
	playersChecks[12].text:SetJustifyH("LEFT")


	SetupFrame.otherUnitsEditFrame = ELib:MultiEdit(SetupFrameScroll.C):Size(490,70):Point("TOP",LOADBORDERFRAME,"TOP",0,-topPos - (13-1)*25 -60):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():gsub("\n","")
		self:SetText(text)
	end)
	ELib:DecorationLine(SetupFrame.otherUnitsEditFrame,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame.otherUnitsEditFrame,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SetupFrame.otherUnitsEditFrame,"BOTTOMRIGHT",0,0):SetVertexColor(0.0,0.0,0.0,0.25)
	SetupFrame.otherUnitsEditFrame:EnableMouseWheel(false)
	SetupFrame.otherUnitsEdit = SetupFrame.otherUnitsEditFrame.EditBox
	SetupFrame.otherUnitsEdit.ColorBorder = nil
	function SetupFrame.otherUnitsEditFrame:ColorBorder(r,g,b,a)
		if type(r) == 'boolean' then
			if r then
				r,g,b,a = 1,0,0,1
			else
				r,g,b,a = 0.24,0.25,0.30,1
			end
		elseif not r then
			r,g,b,a = 0.24,0.25,0.30,1
		end
		ELib:Border(SetupFrame.otherUnitsEditFrame,1,r,g,b,a)
	end

	SetupFrame.unitsText = ELib:Text(SetupFrame.otherUnitsEditFrame,"Custom players:",12):Point("TOPLEFT",SetupFrame.otherUnitsEditFrame,"TOPLEFT",0,15):Color():Shadow()
	do
		ELib:Border(SetupFrame.otherUnitsEditFrame,1,.24,.25,.30,1)
		local msgFont,msgFontSize,msgFontStyle = SetupFrame.otherUnitsEdit:GetRegions():GetFont()
		SetupFrame.otherUnitsEditFrame:Font(msgFont,14,msgFontStyle)
	end

	topPos = topPos + 15 * 25 + 35

	SetupFrame.notePatternEdit = ELib:Edit(SetupFrameScroll.C):Size(240,20):Point("TOP",SetupFrame.otherUnitsEditFrame,"BOTTOM",0,-5):Tooltip(LR.notePatternEditTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		else
			text = text:gsub("%^","")
		end
		SetupFrameData.notepat = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.notePatternEditText = ELib:Text(SetupFrame.notePatternEdit,LR.notePattern,12):Point("RIGHT",SetupFrame.notePatternEdit,"LEFT",-5,0):Right():Middle():Color():Shadow()
	SetupFrame.notePatternCurr = ELib:Text(SetupFrame.notePatternEdit,"",12):Point("LEFT",SetupFrame.notePatternEdit,"RIGHT",5,0):Size(0,20):Point("RIGHT",SetupFrame,"RIGHT",-5,0):Middle():Color():Shadow():Tooltip()

	SetupFrame.extraCheck = ELib:MultiEdit(CUSTOMBORDERFRAME):Size(490,100):Point("TOP",CUSTOMBORDERFRAME,"TOP",0,-30):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText():gsub("\n","")
		if text == "" then
			text = nil
		end

		SetupFrameData.extraCheck = text
		module:SetupFrameUpdate()
	end)
	do
		SetupFrame.extraCheckText = ELib:Text(SetupFrame.extraCheck,LR["extraCheck"],12):Point("TOPLEFT",SetupFrame.extraCheck,"TOPLEFT",0,15):Color():Shadow()
		ELib:DecorationLine(SetupFrame.extraCheck,true,"BACKGROUND",4):Point("TOPLEFT",SetupFrame.extraCheck,"TOPLEFT",0,0):Point("BOTTOMRIGHT",SetupFrame.extraCheck,"BOTTOMRIGHT",0,0):SetVertexColor(0.0,0.0,0.0,0.25)
		SetupFrame.extraCheck:EnableMouseWheel(false)
		ELib:Border(SetupFrame.extraCheck,1,.24,.25,.30,1)
		local msgFont,msgFontSize,msgFontStyle = SetupFrame.extraCheck.EditBox:GetRegions():GetFont()
		SetupFrame.extraCheck:Font(msgFont,14,msgFontStyle)
	end

	SetupFrame.specialTarget = ELib:Edit(CUSTOMBORDERFRAME):Size(200,20):Point("TOP",SetupFrame.extraCheck,"BOTTOM",0,-5):Tooltip(LR.specialTargetTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.specialTarget = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.specialTargetText = ELib:Text(SetupFrame.specialTarget,LR.specialTarget,12):Point("RIGHT",SetupFrame.specialTarget,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.nameplateGlow = ELib:Check(CUSTOMBORDERFRAME,""):Tooltip(LR["GlowNameplateTip"]):Point("TOPLEFT",SetupFrame.specialTarget,"BOTTOMLEFT",0,-5):OnClick(function(self)
		SetupFrameData.nameplateGlow = self:GetChecked()
		module:SetupFrameUpdate()
	end)
	SetupFrame.nameplateGlowText = ELib:Text(SetupFrame.nameplateGlow,LR["GlowNameplate"],12):Point("RIGHT",SetupFrame.nameplateGlow,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowType = ELib:DropDown(CUSTOMBORDERFRAME,200,#module.datas.glowTypes):Size(200):Point("TOPLEFT",SetupFrame.nameplateGlow,"BOTTOMLEFT",0,-5)
	do
		local function glowTypeDropDown_SetValue(_,arg1)
			SetupFrameData.glowType = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.glowType.List
		for i=1,#module.datas.glowTypes do
			List[#List+1] = {
				text = module.datas.glowTypes[i][2],
				arg1 = module.datas.glowTypes[i][1],
				func = glowTypeDropDown_SetValue,
			}
		end
	end
	SetupFrame.glowTypeText = ELib:Text(SetupFrame.glowType,LR.glowType,12):Point("RIGHT",SetupFrame.glowType,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.nameplateText = ELib:Edit(CUSTOMBORDERFRAME):Size(200,20):Point("TOP",SetupFrame.glowType,"BOTTOM",0,-5):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.nameplateText = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.nameplateTextText = ELib:Text(SetupFrame.nameplateText,LR["On-Nameplate Text:"],12):Point("RIGHT",SetupFrame.nameplateText,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowOnlyText = ELib:Check(CUSTOMBORDERFRAME,LR["glowOnlyText"]):Tooltip(LR["glowOnlyTextTip"]):Point("LEFT",SetupFrame.nameplateText,"RIGHT",5,0):OnClick(function(self)
		SetupFrameData.glowOnlyText = self:GetChecked()
		module:SetupFrameUpdate()
	end)

	SetupFrame.UseCustomGlowColor = ELib:Check(CUSTOMBORDERFRAME,LR["UseCustomGlowColor"]):Point("LEFT",SetupFrame.glowType,"RIGHT",5,0):OnClick(function(self,isUser)
		if not isUser then
			return
		end
		SetupFrameData.UseCustomGlowColor = self:GetChecked()
		if not self:GetChecked() then
			SetupFrameData.glowColor = nil
		else
			SetupFrameData.glowColor = "0000FFFF"
		end
		module:SetupFrameUpdate()
	end)

	SetupFrame.glowThick = ELib:Edit(CUSTOMBORDERFRAME,nil,true):Size(200,20):Point("TOP",SetupFrame.nameplateText,"BOTTOM",0,-5):OnChange(function(self,isUser)
		local text = self:GetText()
		if not isUser then
			return
		end
		if text:find("%.+$") then
			return
		end
		SetupFrameData.glowThick = tonumber(text)
		module:SetupFrameUpdate()
	end)
	SetupFrame.glowThickText = ELib:Text(SetupFrame.glowThick,LR.glowThick,12):Point("RIGHT",SetupFrame.glowThick,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowColor = ExRT.lib.CreateColorPickButton(SetupFrame.glowType,20,20,nil,205,25)
	SetupFrame.glowColor:SetScript("OnClick",function (self)
		local colorPalette = SetupFrameData.glowColor or "0000FFFF"
		local r, g, b = tonumber('0x'..strsub(colorPalette, 3, 4))/255, tonumber('0x'..strsub(colorPalette, 5, 6))/255, tonumber('0x'..strsub(colorPalette, 7, 8))/255
		ColorPickerFrame.previousValues = {1, r, g, b}
		ColorPickerFrame.hasOpacity = false
		local nilFunc = ExRT.NULLfunc
		local function changedCallback(restore)
			local newR, newG, newB, newA
			if restore then
				newA, newR, newG, newB = unpack(restore)
			else
				newA, newR, newG, newB = 1, ColorPickerFrame:GetColorRGB()
			end
			SetupFrameData.glowColor = string.format("%.2x%.2x%.2x%.2x", 255, newR*255, newG*255, newB*255)
			self.color:SetColorTexture(newR,newG,newB,newA)
		end
		ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nilFunc, nilFunc, nilFunc
		ColorPickerFrame.opacity = 1
		ColorPickerFrame:SetColorRGB(r,g,b)
		ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
		ColorPickerFrame:Show()
	end)

	do
		local texture = SetupFrame.glowColor:CreateTexture(nil, "BACKGROUND")
		SetupFrame.glowColor.color.background = texture
		texture:SetWidth(16)
		texture:SetHeight(16)
		texture:SetColorTexture(1, 1, 1)
		texture:SetPoint("CENTER", SetupFrame.glowColor.color)
		texture:Show()

		local checkers = SetupFrame.glowColor:CreateTexture(nil, "BACKGROUND")
		SetupFrame.glowColor.color.checkers = checkers
		checkers:SetWidth(14)
		checkers:SetHeight(14)
		checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
		checkers:SetTexCoord(.25, 0, 0.5, .25)
		checkers:SetDesaturated(true)
		checkers:SetVertexColor(1, 1, 1, 0.75)
		checkers:SetPoint("CENTER", SetupFrame.glowColor.color)
		checkers:Show()

		SetupFrame.glowColor.color:SetDrawLayer("BORDER", -7)
		ELib:Text(SetupFrame.glowColor,"Glow Color",12):Point("LEFT",SetupFrame.glowColor,"RIGHT",5,0):Left():Middle():Color():Shadow()
	end

	SetupFrame.glowScale = ELib:Edit(CUSTOMBORDERFRAME):Size(200,20):Point("TOP",SetupFrame.glowThick,"BOTTOM",0,-5):OnChange(function(self,isUser)
		local text = self:GetText()
		if not isUser then
			return
		end
		if text:find("%.+$") then
			return
		end
		SetupFrameData.glowScale = tonumber(text)
		module:SetupFrameUpdate()
	end)
	SetupFrame.glowScaleText = ELib:Text(SetupFrame.glowScale,LR.glowScale,12):Point("RIGHT",SetupFrame.glowScale,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowN = ELib:Edit(CUSTOMBORDERFRAME):Size(200,20):Point("TOP",SetupFrame.glowScale,"BOTTOM",0,-5):Tooltip(LR.glowNTip):OnChange(function(self,isUser)
		local text = self:GetText()
		if not isUser then
			return
		end
		if text:find("%.+$") then
			return
		end
		SetupFrameData.glowN = tonumber(text)
		module:SetupFrameUpdate()
	end)
	SetupFrame.glowNText = ELib:Text(SetupFrame.glowN,LR.glowN,12):Point("RIGHT",SetupFrame.glowN,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowImage = ELib:DropDown(CUSTOMBORDERFRAME,200,#module.datas.glowImages):Size(200):Point("TOP",SetupFrame.glowN,"BOTTOM",0,-5)
	do
		local function glowImageDropDown_SetValue(_,arg1)
			SetupFrameData.glowImage = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.glowImage.List
		for i=1,#module.datas.glowImages do
			List[#List+1] = {
				text = module.datas.glowImages[i][2],
				arg1 = module.datas.glowImages[i][1],
				func = glowImageDropDown_SetValue,
			}
		end
	end
	SetupFrame.glowImageText = ELib:Text(SetupFrame.glowImage,LR.glowImage,12):Point("RIGHT",SetupFrame.glowImage,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.glowImageCustom = ELib:Edit(CUSTOMBORDERFRAME):Size(490,20):Point("TOP",SetupFrame.glowImage,"BOTTOM",0,-25):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = 0
		end
		SetupFrameData.glowImage = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.glowImageCustomText = ELib:Text(SetupFrame.glowImageCustom,"Custom:",12):Point("BOTTOMLEFT",SetupFrame.glowImageCustom,"TOPLEFT",2,5):Right():Middle():Color():Shadow()



	SetupFrame.SaveButton = ELib:mStyledButton(SetupFrame,LR.save,13):Point("BOTTOM",SetupFrame,"BOTTOM",0,5):Size(202,22):OnClick(function()
		SetupFrame:Hide()

		CheckPlayerClick()

		if not SetupFrameData.token then
			SetupFrameData.token = time() + GetTime() % 1
		end

		SetupFrameData.notSync = true

		if SetupFrameData.event == "BOSS_START" then
			SetupFrameData.spellID = 0
		end
		SetupFrameData.UseCustomGlowColor = nil

		VExRT.Reminder.data[ SetupFrameData.token ] = SetupFrameData

		module:ReloadAll()

		SetupFrameData = nil
		module.options:UpdateData()
	end)

	SetupFrame.event = ELib:DropDown(SetupFrameScroll.C,220,#eventsList):AddText(LR.Event):Size(200):Point("TOP",LOADBORDERFRAME,"BOTTOM",160,-60)
	do
		local function eventList_SetValue(_,event)
			SetupFrameData.event = event
			ELib:DropDownClose()
			module:SetupFrameUpdate(true)
		end

		local List = SetupFrame.event.List
		for i=1,#eventsList do
			List[#List+1] = {
				text = eventsList[i][2],
				arg1 = eventsList[i][1],
				func = eventList_SetValue,
			}
		end
	end

	SetupFrame.delay = ELib:Edit(SetupFrameScroll.C):Size(200,20):Point("TOP",SetupFrame.event,"BOTTOM",0,-5):Tooltip(LR.delayTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end

		local text = self:GetText()
		if text == "" then text = nil end

		SetupFrameData.delay = text
		module:SetupFrameUpdate()
	end)
	SetupFrame.delayText = ELib:Text(SetupFrame.delay,LR.delayText,12):Point("RIGHT",SetupFrame.delay,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.duration = ELib:Edit(SetupFrameScroll.C,nil,true):Size(200,20):Point("TOP",SetupFrame.delay,"BOTTOM",0,-5):Tooltip(LR.durationTip):OnChange(function(self,isUser)
		local text = self:GetText()
		if not isUser then
			return
		end
		if text:find("%.$") then
			return
		end
		SetupFrameData.duration = tonumber(text)
		module:SetupFrameUpdate()
	end)
	SetupFrame.durationText = ELib:Text(SetupFrame.duration,LR.duration ,12):Point("RIGHT",SetupFrame.duration,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.spellID = ELib:Edit(SetupFrameScroll.C,nil,true):Size(200,20):Point("TOP",SetupFrame.duration,"BOTTOM",0,-5):OnChange(function(self,isUser)
		local text = self:GetText()
		local sid = text or "?"
		if sid and (SetupFrameData.event ~= "BOSS_PHASE" and SetupFrameData.event ~= "BOSS_HP" and SetupFrameData.event ~= "BOSS_MANA" and SetupFrameData.event ~= "BOSS_START" and SetupFrameData.event ~= "BW_TIMER_TEXT") then
			local spellName,_,spellTexture = GetSpellInfo(sid)
			SetupFrame.eventSIDSpellNameText:SetText((spellTexture and "|T"..spellTexture..":20|t " or "")..(spellName or ""))
		else
			SetupFrame.eventSIDSpellNameText:SetText("")
		end
		if not isUser then
			return
		end
		if (SetupFrameData.event == "BOSS_HP" or SetupFrameData.event == "BOSS_MANA" or SetupFrameData.event == "BOSS_PHASE")and text:find("%.+$") then
			return
		end
		if SetupFrameData.event == "BW_TIMER_TEXT" then
			SetupFrameData.spellID = text
		else
			SetupFrameData.spellID = tonumber(text)
		end
		module:SetupFrameUpdate()
	end)
	SetupFrame.spellIDText = ELib:Text(SetupFrame.spellID,"Spell ID:",12):Point("RIGHT",SetupFrame.spellID,"LEFT",-5,0):Right():Middle():Color():Shadow()
	SetupFrame.eventSIDSpellNameText = ELib:Text(SetupFrame.spellID,"",12):Point("LEFT",SetupFrame.spellID,"BOTTOMLEFT",0,-16):Size(0,20):Point("RIGHT",SetupFrame.spellID,"BOTTOMRIGHT",0,-16):Middle():Color():Shadow()

	SetupFrame.castList = ELib:DropDown(SetupFrameScroll.C,200,20):Size(200):Point("TOP",SetupFrame.spellID,"BOTTOM",0,-30)
	do
		local function castsList_SetValue(_,event)
			SetupFrameData.cast = event
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.castList.List
		for i=1,#castsList do
			List[#List+1] = {
				text = castsList[i][2],
				arg1 = castsList[i][1],
				func = castsList_SetValue,
			}
		end
	end
	SetupFrame.castListText = ELib:Text(SetupFrame.castList,LR.CastNumber,12):Point("RIGHT",SetupFrame.castList,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.useGlobalCounterCheck = ELib:Check(SetupFrameScroll.C,LR.GlobalCounter):Point("TOPLEFT",SetupFrame.castList,"BOTTOMLEFT",0,-5):Tooltip(LR.GlobalCounterTip):OnClick(function(self)
		SetupFrameData.globalCounter = not SetupFrameData.globalCounter
		module:SetupFrameUpdate()
	end)

	SetupFrame.rawCastEdit = ELib:Edit(SetupFrameScroll.C):Size(200,20):Point("TOP",SetupFrame.spellID,"BOTTOM",0,-5):Tooltip(LR.commaTip):OnChange(function(self,isUser)
		if not isUser then
			return
		end
		local text = self:GetText()
		if text == "" then
			text = nil
		end
		SetupFrameData.cast = tonumber(text) and tonumber(text) or text
		module:SetupFrameUpdate()
	end)
	SetupFrame.rawCastEditText = ELib:Text(SetupFrame.rawCastEdit,LR.CastNumber,12):Point("RIGHT",SetupFrame.rawCastEdit,"LEFT",-5,0):Right():Middle():Color():Shadow()

	SetupFrame.conditionList = ELib:DropDown(SetupFrameScroll.C,200,#conditionsList):Size(200):Point("TOP",SetupFrame.castList,"BOTTOM",0,-30)
	do
		local function conditionList_SetValue(_,arg1)
			SetupFrameData.condition = arg1
			ELib:DropDownClose()
			module:SetupFrameUpdate()
		end

		local List = SetupFrame.conditionList.List
		for i=1,#conditionsList do
			List[#List+1] = {
				text = conditionsList[i][2],
				arg1 = conditionsList[i][1],
				func = conditionList_SetValue,
			}
		end
	end
	SetupFrame.conditionListText = ELib:Text(SetupFrame.conditionList,LR.condition,12):Point("RIGHT",SetupFrame.conditionList,"LEFT",-5,0):Right():Middle():Color():Shadow()

	local function RemoveFromList(table,val)
		for i=#table,1,-1 do
			if table[i]==val then
				tremove(table,i)
			end
		end
	end

    do
        local QuickList = ELib:ScrollTableList(SetupFrame,90,50,0,50,55,36,90,90):Size(600,500):Point("TOPLEFT",SetupFrame,"TOPRIGHT",1,-60):FontSize(11)
        SetupFrame.QuickList = QuickList
        QuickList.SetHistoryButton = {}
        QuickList:Hide()
        function QuickList:UpdateAdditional()
            for i=1,#self.List do
                self.List[i].text3:SetWordWrap(false)
                self.List[i].text6:SetWordWrap(false)
                self.List[i].text7:SetWordWrap(false)
            end
        end
        QuickList.Frame.mouseWheelRange = 50
        QuickList.Background = QuickList:CreateTexture(nil,"BACKGROUND")
        QuickList.Background:SetColorTexture(0.05,0.05,0.07,0.98)
        QuickList.Background:SetPoint("TOPLEFT")
        QuickList.Background:SetPoint("BOTTOMRIGHT")
        QuickList:EnableMouse(true)
        QuickList:RegisterForDrag("LeftButton")
        QuickList:SetScript("OnDragStart", function(self)
            SetupFrame:StartMoving()
        end)
        QuickList:SetScript("OnDragStop", function(self)
            SetupFrame:StopMovingOrSizing()
        end)

        QuickList.HistoryBackground = ELib:Template("ExRTDialogModernTemplate",QuickList)
        QuickList.HistoryBackground:SetSize(600,115)
        QuickList.HistoryBackground:Show()
        QuickList.HistoryBackground:SetPoint("TOPLEFT", QuickList, "BOTTOMLEFT",0,-1)
        QuickList.HistoryBackground:EnableMouse(true)
        QuickList.HistoryBackground:RegisterForDrag("LeftButton")
        QuickList.HistoryBackground:SetScript("OnDragStart", function(self)
            SetupFrame:StartMoving()
        end)
        QuickList.HistoryBackground:SetScript("OnDragStop", function(self)
            SetupFrame:StopMovingOrSizing()
        end)
        ELib:Border(QuickList.HistoryBackground,1,.24,.25,.30,1)
        QuickList.HistoryBackground.Close:Hide()

        ELib:Border(QuickList,1,.24,.25,.30,1)
        ELib:Border(QuickList,0,0,0,0,1,2,1)
        ELib:Border(QuickList.Frame,0,.24,.25,.30,1)

        QuickList.HistoryBackground:Hide()


        QuickList.ChecksBackground	 = ELib:Template("ExRTDialogModernTemplate",QuickList)
        QuickList.ChecksBackground:SetSize(600,59)
        QuickList.ChecksBackground:Show()
        QuickList.ChecksBackground:SetFrameStrata("DIALOG")
        QuickList.ChecksBackground:SetPoint("BOTTOMLEFT", QuickList, "TOPLEFT",0,1)
        QuickList.ChecksBackground:EnableMouse(true)
        QuickList.ChecksBackground:RegisterForDrag("LeftButton")
        QuickList.ChecksBackground:SetScript("OnDragStart", function(self)
            SetupFrame:StartMoving()
        end)
        QuickList.ChecksBackground:SetScript("OnDragStop", function(self)
            SetupFrame:StopMovingOrSizing()
        end)
        ELib:Border(QuickList.ChecksBackground,1,.24,.25,.30,1)
        QuickList.ChecksBackground.Close:Hide()

        QuickList.additionalLineFunctions = true
        function QuickList:HoverMultitableListValue(isEnter,index,obj)
            if not isEnter then
                local line = obj.parent:GetParent()
                line.HighlightTexture2:Hide()

                GameTooltip_Hide()
            else
                local line = obj.parent:GetParent()
                if not line.HighlightTexture2 then
                    line.HighlightTexture2 = line:CreateTexture()
                    line.HighlightTexture2:SetTexture("Interface\\QuestFrame\\UI-QuestLogTitleHighlight")
                    line.HighlightTexture2:SetBlendMode("ADD")
                    line.HighlightTexture2:SetPoint("LEFT",0,0)
                    line.HighlightTexture2:SetPoint("RIGHT",0,0)
                    line.HighlightTexture2:SetHeight(15)
                    line.HighlightTexture2:SetVertexColor(1,1,1,1)
                end
                line.HighlightTexture2:Show()

                local data = line.table
                if data[2] == "" then
                    if index == 1 then
                        obj.parent:SetWidth(240)
                    end
                    if index < 5 then
                        GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                        GameTooltip:AddLine("Encounter ID")
                        GameTooltip:AddLine(data[4])
                        GameTooltip:Show()
                    elseif data[5] == "DiffID:" then
                        GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                        GameTooltip:AddLine("Difficulty ID")
                        GameTooltip:AddLine(data[6])
                        GameTooltip:Show()
                    end
                    return
                end
                if index == 3 then
                    if data.notspell then
                        return
                    end
                    GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                    GameTooltip:SetHyperlink("spell:"..data[2] )
                    GameTooltip:Show()
                elseif index == 4 then
                    GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                    GameTooltip:AddLine(LR.QuickSetupTimerFromPull)

                    if data.timeFromStart then
                        GameTooltip:AddLine(LR.QuickSetupSec.. tonumber(format("%.1f",data.timeFromStart)))
                    end

                    GameTooltip:Show()
                elseif index == 5 then
                    GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                    GameTooltip:AddLine(LR.QuickSetupTimerFromPhase)

                    if data.timeFromPhase then
                        GameTooltip:AddLine(LR.QuickSetupSec.. tonumber(format("%.1f",data.timeFromPhase)))
                    end

                    GameTooltip:Show()
                elseif index == 6 then
                    GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                    GameTooltip:AddLine(LR.QuickSetupTimerFromEvent)
                    GameTooltip:Show()
                elseif index == 2 then
                    GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                    GameTooltip:AddLine("Spell ID")
                    GameTooltip:Show()
                else
                    if obj.parent:IsTruncated() then
                        GameTooltip:SetOwner(obj,"ANCHOR_CURSOR")
                        GameTooltip:AddLine(obj.parent:GetText() )
                        GameTooltip:Show()
                    end
                end
            end
        end
    function QuickList:ClickMultitableListValue(index,obj)
            local data = obj:GetParent().table
            if not data then
                return
            end
            if SetupFrameData.event == "ADVANCED" then
                local currentTrigger = triggerTabs.selected
                if not currentTrigger then
                    return
                end
                local triggerData = SetupFrameData.triggers[currentTrigger]
                if not triggerData then
                    return
                end

                local eventDB = module.C[triggerData.eventCLEU] or module.C[triggerData.event]
                if not eventDB then return end
                local triggerFields = {}
                for k,v in pairs(eventDB.triggerFields) do
                    triggerFields[v] = true
                end


                -- local localedEvent = data[1]
                local spellID = data[2]
                -- local localedCast = data[3]
                -- local formatedTimeFromPull = data[4]
                -- local formatedTimeFromPhase = data[5]
                local sourceName = data[7]
                local targetName = data[8]
                local event = data.event
                local phaseNumber = data.phase and data.phase[1]
                local phaseRep = data.phase and data.phase[2]
                local timeFromPhase = data.timeFromPhase and tonumber(format("%.1f",data.timeFromPhase))
                local timeFromStart = data.timeFromStart and tonumber(format("%.1f",data.timeFromStart))
                local timeFromPrevCast = data.timeFromPrev and tonumber(format("%.1f",data.timeFromPrev[1]))
                local prevCastNumber = data.timeFromPrev and data.timeFromPrev[2]

                local eventCLEU
                if event == "PHASE" or event == "BOSS_PHASE" then
                    event = 2
                elseif event == "UNIT_ENGAGE" then
                    event = 9
                elseif event == "SPELL_CAST_START" or
                    event == "SPELL_CAST_SUCCESS" or
                    event == "SPELL_AURA_APPLIED" or
                    event == "SPELL_AURA_REMOVED"
                then
                    eventCLEU = event
                    event = 1
                end


                if spellID == "" then
                    if index < 5 then
                        SetupFrameData.boss = data[4]
                    elseif data[5] == "DiffID:" then
                        SetupFrameData.diff = data[6]
                    end
                    module:SetupFrameUpdate()
                    return
                end

                spellID = tonumber(spellID)

                if index == 1 then
                    triggerData = {
                        event = event,
                        eventCLEU = eventCLEU,
                    }
                elseif event == 2 then
                    triggerData = {
                        event = event,
                        pattFind = spellID,
                        counter = (prevCastNumber and prevCastNumber + 1) or 1,
                    }
                elseif index == 4 then
                    triggerData = {
                        event = 3,
                        delayTime = timeFromStart,
                    }
                elseif index == 5 then
                    triggerData = {
                        event = 2,
                        delayTime = timeFromPhase,
                        pattFind = tostring(phaseNumber),
                        counter = phaseRep,
                    }
                elseif event == 9 then
                    if index == 2 then
                        triggerData= {
                            event = 9,
                            targetID = tostring(spellID),
                        }
                    elseif index == 3 then
                        triggerData = {
                            event = 9,
                            targetName = data[3],
                        }
                    elseif index == 6 then
                        triggerData = {
                            event = 9,
                            targetUnit = data[6],
                        }
                    elseif index == 7 or index == 8 then
                        triggerData = {
                            event = 9,
                            targetID = tostring(spellID) .. ":" ..tostring(data[8]),
                        }
                    end
                elseif index == 2 then
                    if event == 2 then
                        triggerData.pattFind = spellID
                    else
                        if triggerFields["spellID"] then
                            triggerData.spellID = spellID
                        end
                    end
                elseif index == 3 then
                    if event == 2 then
                        triggerData.pattFind = spellID
                        triggerData.counter = (prevCastNumber and prevCastNumber + 1) or 1
                    else
                        if triggerFields["spellID"] then
                            triggerData.spellID = spellID
                        end
                        if triggerFields["counter"] then
                            triggerData.counter = (prevCastNumber and prevCastNumber + 1) or 1
                        end
                    end
                elseif index == 6 then
                    triggerData = {
                        event = 1,
                        eventCLEU = eventCLEU,
                        spellID = spellID,
                        counter = prevCastNumber,
                        delayTime = timeFromPrevCast,
                    }
                elseif index == 7 then
                    if triggerFields["sourceName"] then
                        triggerData.sourceName = sourceName
                    end
                elseif index == 8 then
                    if triggerFields["targetName"] then
                        triggerData.targetName = targetName
                    end
                end

                SetupFrameData.triggers[currentTrigger] = triggerData

                advSetupFrameUpdate()
                module:SetupFrameUpdate()
            else
                local spellID = data[2]
                if spellID == "" then
                    if index < 5 then
                        SetupFrameData.boss = data[4]
                    elseif data[5] == "DiffID:" then
                        SetupFrameData.diff = data[6]
                    end
                    module:SetupFrameUpdate(true)
                    return
                end
                local event = data.event

                if event == "UNIT_ENGAGE" then return end

                if event == "PHASE" then event = "BOSS_PHASE" end

                SetupFrameData.spellID = tonumber(spellID)
                SetupFrameData.event = event

                if index == 4  and event ~= "BOSS_PHASE" then
                    SetupFrameData.event = "BOSS_START"
                    SetupFrameData.delay = tonumber(format("%.1f",data.timeFromStart))
                elseif index == 5 then
                    if data.event == "PHASE" then
                        SetupFrameData.event = "BOSS_PHASE"
                        SetupFrameData.spellID = data[2]
                        SetupFrameData.cast = data.rep
                    else
                        SetupFrameData.event = "BOSS_PHASE"
                        SetupFrameData.delay = tonumber(format("%.1f",data.timeFromPhase))
                        SetupFrameData.spellID = data.phase[1]
                        SetupFrameData.cast = data.phase[2]
                    end
                elseif index == 6 and data.timeFromPrev then
                    SetupFrameData.delay = tonumber(format("%.1f",data.timeFromPrev[1]))
                    SetupFrameData.cast = data.timeFromPrev[2]
                end
                module:SetupFrameUpdate(true)
            end
        end

        QuickList.AurasChk = ELib:Check(QuickList,LR.QuickSetupAddAurasEvents):Point("BOTTOMLEFT",'x',"TOPLEFT",5,6):Scale(1):OnClick(function()
            module:SetupFrameUpdate()
        end)
        QuickList.AurasChk:SetFrameStrata("FULLSCREEN_DIALOG")

        QuickList.AllEventsChk = ELib:Check(QuickList,LR.QuickSetupAddAllEvents):Point("BOTTOMLEFT",'x',"TOPLEFT",205,6):Scale(1):OnClick(function()
            module:SetupFrameUpdate()
        end)
        QuickList.AllEventsChk:SetFrameStrata("FULLSCREEN_DIALOG")

        QuickList.CurrentTriggerMatch = ELib:Check(QuickList,LR.CurrentTriggerMatch):Point("BOTTOMLEFT",'x',"TOPLEFT",5,34):Scale(1):OnClick(function()
            module:SetupFrameUpdate()
        end)
        QuickList.CurrentTriggerMatch:SetFrameStrata("FULLSCREEN_DIALOG")
    end

	SetupFrame.HistoryCheck = ELib:Check(SetupFrame,LR.QuickSetup,VExRT.Reminder.HistoryCheck):Point("BOTTOMRIGHT", SetupFrame, "BOTTOMRIGHT", -3,3):TextSize(12):Left():OnClick(function(self)
		VExRT.Reminder.HistoryCheck = self:GetChecked()
		if not VExRT.Reminder.HistoryCheck then
			SetupFrame.QuickList.HistoryBackground:Hide()
			SetupFrame.QuickList:Hide()
		end
		UpdateHistory(lastHistory)
	end)
	SetupFrame.HistoryCheck:GetFontString():SetFont(tabFont, 12, "OUTLINE")

	SetupFrame.RawDataCheck = ELib:Check(SetupFrameScroll.C,LR.Manually,RawData):Point("LEFT", SetupFrame.name, "RIGHT", 5,0):Tooltip(LR.ManuallyTip):OnClick(function(self)
		RawData = self:GetChecked()
		module:SetupFrameUpdate()
	end)

	SetupFrame.QuickList.ToogleHistory = ELib:mStyledButton(SetupFrame.QuickList,LR.DungeonHistory,15):Size(160,22):Point("TOPLEFT", SetupFrame.QuickList.HistoryBackground, "BOTTOMLEFT",1,-2):OnClick(function(self)
		if currentTrueHistory == ReminderLog.TrueHistory then
			currentTrueHistory = ReminderLog.TrueHistoryDungeon
			self.Texture:SetGradient("HORIZONTAL",CreateColor(1,0.55,0.1,0.9), CreateColor(0.9,0.5,0,0.9))
			self:SetText(LR.RaidHistory)
		elseif currentTrueHistory == ReminderLog.TrueHistoryDungeon then
			currentTrueHistory = ReminderLog.TrueHistory
			self.Texture:SetGradient("HORIZONTAL",CreateColor(0.1,0.55,1,0.9), CreateColor(0,0.5,0.9,0.9))
			self:SetText(LR.DungeonHistory)
		end
		UpdateHistory()
	end)

	SetupFrame.QuickList.ToogleHistory.Texture:SetGradient("HORIZONTAL",CreateColor(0.1,0.55,1,1), CreateColor(0,0.5,0.9,1))

	SetupFrame.QuickList.WipeHistoryButton = ELib:mStyledButton(SetupFrame.QuickList,LR.WipePulls,15):Size(160,22):Point("TOPLEFT", SetupFrame.QuickList.ToogleHistory, "BOTTOMLEFT",0,-1):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_WIPE_HISTORY"] = {
			text = LR.WipePulls.."?",
			button1 = LR.Listdelete,
			button2 = L.NoText,
			OnAccept = function()
				SetupFrame.QuickList.HistoryBackground:Hide()
				ReminderLog.TrueHistory = {}
				ReminderLog.TrueHistoryDungeon = {}
				currentTrueHistory = ReminderLog.TrueHistory

				lastHistory = 0
				UpdateHistory(lastHistory)
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_WIPE_HISTORY")
	end)
	SetupFrame.QuickList.WipeHistoryButton.Texture:SetGradient("HORIZONTAL",CreateColor(0.55,0.21,0.25,1), CreateColor(0.7,0.21,0.25,1))

	local function FormatTime(t)
		return format("%d:%02d",t/60,t%60)
	end
	local function FormatName(name,flags)
		if not name and not flags then
			return
		elseif name and flags then
			if UnitClass(name) then
				name = "|c" .. RAID_CLASS_COLORS[select(2,UnitClass(name))].colorStr .. name
			end
			local mark = FlagMarkToIndex[flags]
			if mark and mark > 0 then
				name = ExRT.F.GetRaidTargetText(mark).." " .. name
			end
			return name
		elseif flags then
			local mark = FlagMarkToIndex[flags]
			if mark and mark > 0 then
				return ExRT.F.GetRaidTargetText(mark)
			end
		else
			if UnitClass(name) then
				name = "|c" .. RAID_CLASS_COLORS[select(2,UnitClass(name))].colorStr .. name
			end
			return name
		end
	end

	local function CreateHistoryButtons(table,number)
		local MaxPulls = VExRT.Reminder.HistoryMaxPulls
		if MaxPulls < #table then
			MaxPulls = #table
		end
		SetupFrame.QuickList.HistoryBackground:SetHeight(19 * ((MaxPulls / 2) + (MaxPulls % 2 == 1 and 0.5 or 0))  + 1)
		if #table > 0 and VExRT.Reminder.HistoryCheck then
			SetupFrame.QuickList.WipeHistoryButton:Show()
			SetupFrame.QuickList.HistoryBackground:Show()

			-- SetupFrame.QuickList.SetHistoryButton = {}
			--date , history, eName , dID , CTT -- ReminderLog.TrueHistory[i][1]
			for i=1, #table do
				if not SetupFrame.QuickList.SetHistoryButton[i] then
					local buttonText = (table[i][6] and table[i][6] == 0 and "|cffff0000" or "|cff00ff00") .. (ExRT.F.utf8sub(table[i][3],1,33)) .. " (#" .. i .. (table[i][5] and " " .. table[i][5] or "") .. ")|r"
					if i == 1 then
						SetupFrame.QuickList.SetHistoryButton[i] = ELib:Button(SetupFrame.QuickList, buttonText):Size(299,18):Point("TOPLEFT", SetupFrame.QuickList.HistoryBackground, "TOPLEFT",1,-1):OnClick(function()
							UpdateHistory(i)
						end)
					elseif i < ((MaxPulls / 2) + (MaxPulls % 2 == 1 and 0.5 or 0)) + 1  then -- go down
						SetupFrame.QuickList.SetHistoryButton[i] = ELib:Button(SetupFrame.QuickList, buttonText):Size(299,18):Point("TOP", SetupFrame.QuickList.SetHistoryButton[i - 1], "BOTTOM",0,-1):OnClick(function()
							UpdateHistory(i)
						end)
					elseif i > ((MaxPulls / 2) + (MaxPulls % 2 == 1 and 0.5 or 0))  then --go right
						SetupFrame.QuickList.SetHistoryButton[i] = ELib:Button(SetupFrame.QuickList, buttonText):Size(298,18):Point("LEFT",SetupFrame.QuickList.SetHistoryButton[i - ((MaxPulls / 2) + (MaxPulls % 2 == 1 and 0.5 or 0))] or SetupFrame.QuickList.WipeHistoryButton, "RIGHT",1,0):OnClick(function()
							UpdateHistory(i)
						end)
					end
					if number and type(number) == 'number' and i == number then
						SetupFrame.QuickList.SetHistoryButton[i].Texture:SetGradient("VERTICAL",CreateColor(0.09,0.10,0.12,0.8), CreateColor(0.12,0.13,0.14,0.8))
					else
						SetupFrame.QuickList.SetHistoryButton[i].Texture:SetGradient("VERTICAL",CreateColor(0.16,0.17,0.20,0.8), CreateColor(0.19,0.20,0.21,0.8))
					end


					SetupFrame.QuickList.SetHistoryButton[i]:GetFontString():SetFont(tabFont, 12, "OUTLINE")
					SetupFrame.QuickList.SetHistoryButton[i]:GetFontString():SetPoint("LEFT", 4, 0)
					SetupFrame.QuickList.SetHistoryButton[i]:SetFrameStrata("FULLSCREEN")
					---------------------------Tooltip
					SetupFrame.QuickList.SetHistoryButton[i]:Tooltip(LR.Boss .. (table[i][3] or "") ..
						LR.QuickSetupChoosTipPullTimer .. (table[i][5] or "") ..
						LR.QuickSetupChoosTipStartTimer .. (table[i][1] or "") ..
						LR.QuickSetupChoosTipDiff .. (table[i][4] or ""))
				end
			end
		end
	end

	local function parseGUID(guid, dataID)
		local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
		if unitType == "Creature" or unitType == "Vehicle" then
			spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnID, 1, 5), 16), 0xffff8), 3)
		end
		if dataID == mobID or dataID == (mobID .. ":" .. spawnIndex) then
			return true
		end
	end

    local spellIDBlacklist = {
        -- [0] = true
    }

	function UpdateHistory(number)
		if VExRT.Reminder.HistoryCheck then
			SetupFrame.QuickList:Show()
		end
		if #ReminderLog.TrueHistoryDungeon == 0 and #ReminderLog.TrueHistory == 0 then
			SetupFrame.QuickList.WipeHistoryButton:Hide()
		end

		if not ReminderLog.TrueHistoryDungeonEnabled or #ReminderLog.TrueHistoryDungeon == 0 then
			SetupFrame.QuickList.ToogleHistory:Hide()
		else
			SetupFrame.QuickList.ToogleHistory:Show()
		end


		for i=1, #SetupFrame.QuickList.SetHistoryButton do
			SetupFrame.QuickList.SetHistoryButton[i]:Shown(false)
		end
		SetupFrame.QuickList.SetHistoryButton = {}

		CreateHistoryButtons(currentTrueHistory,number)

		local tempHistory
		if number and number ~= 0 then
			if #currentTrueHistory > 0 and currentTrueHistory[number][2] then
				tempHistory = currentTrueHistory[number][2]
				lastHistory = number
			end
		else
			tempHistory = history
			lastHistory = 0
		end

		local phaseNow = 1
		local phaseRepeat
		local startTime = tempHistory[1] and tempHistory[1][1] or 0
		local phaseTime = startTime
		local counter = {cs={},ce={},aa={},ar={}}
		local prev = {cs={},ce={},aa={},ar={}}

		local result = {}
		local triggerData = SetupFrameData.event == "ADVANCED" and SetupFrame.QuickList.CurrentTriggerMatch:GetChecked() and SetupFrameData.triggers[triggerTabs.selected]

		-- history[#history+1] = {GetTime(),"UNIT_ENGAGE",targetName,targetGUID,targetUnit}
		local line, prevNow
		result[1] = {tempHistory[1] and tempHistory[1][3] and tempHistory[1][3] or "", "",tempHistory[1] and tempHistory[1][4] and "" or "",tempHistory[1] and tempHistory[1][4] and tempHistory[1][4] or "", tempHistory[1] and tempHistory[1][5] and "DiffID:" or "",tempHistory[1] and tempHistory[1][5] and tempHistory[1][5] or "",}
		for i=2,#tempHistory do
			line = tempHistory[i]

			prevNow = nil

			if line[2] == "SPELL_CAST_START" then
				counter.cs[ line[4] ] = counter.cs[ line[4] ] or {}
				counter.cs[ line[4] ][ line[3] ] = (counter.cs[ line[4] ][ line[3] ] or 0) + 1

				prev.cs[ line[4] ] = prev.cs[ line[4] ] or {}
				prevNow = prev.cs[ line[4] ][ line[3] ]
				prev.cs[ line[4] ][ line[3] ] = line[1]
			elseif line[2] == "SPELL_CAST_SUCCESS" then
				counter.ce[ line[4] ] = counter.ce[ line[4] ] or {}
				counter.ce[ line[4] ][ line[3] ] = (counter.ce[ line[4] ][ line[3] ] or 0) + 1

				prev.ce[ line[4] ] = prev.ce[ line[4] ] or {}
				prevNow = prev.ce[ line[4] ][ line[3] ]
				prev.ce[ line[4] ][ line[3] ] = line[1]
			elseif line[2] == "SPELL_AURA_APPLIED" then
				counter.aa[ line[4] ] = counter.aa[ line[4] ] or {}
				counter.aa[ line[4] ][ line[3] ] = (counter.aa[ line[4] ][ line[3] ] or 0) + 1

				prev.aa[ line[4] ] = prev.aa[ line[4] ] or {}
				prevNow = prev.aa[ line[4] ][ line[3] ]
				prev.aa[ line[4] ][ line[3] ] = line[1]
			elseif line[2] == "SPELL_AURA_REMOVED" then
				counter.ar[ line[4] ] = counter.ar[ line[4] ] or {}
				counter.ar[ line[4] ][ line[3] ] = (counter.ar[ line[4] ][ line[3] ] or 0) + 1

				prev.ar[ line[4] ] = prev.ar[ line[4] ] or {}
				prevNow = prev.ar[ line[4] ][ line[3] ]
				prev.ar[ line[4] ][ line[3] ] = line[1]
			end

            if line[2] and line[2]:find("^SPELL_") and spellIDBlacklist[tonumber(line[3]) or 0] then
                -- empty scope for blacklisting
			elseif triggerData then
				if line[2] == "PHASE" then --евент --line[4] = phasecount
					phaseTime = line[1] --геттайм
					phaseNow = line[3] or 0 --значение
					phaseRepeat=line[4] or 0 --кастнамбер

					result[#result+1] = {LR.QS_Phase,line[3],LR.QS_PhaseRepeat..phaseRepeat,FormatTime(line[1]-startTime),notspell=true,event=line[2],rep=line[4]}
				elseif line[2] == "UNIT_ENGAGE" then
					local time = line[1]
					local name = line[3]
					local guid = line[4]
					local unit = line[5]
					local spawnIndex

					local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
					if unitType == "Creature" or unitType == "Vehicle" then
						spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnID, 1, 5), 16), 0xffff8), 3)
					end

					result[#result+1] = {"NEW UNIT",mobID,name,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),unit,guid,spawnIndex,notspell=true,rep=line[4],event="UNIT_ENGAGE",timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat}}

				elseif
					line[2] == "SPELL_CAST_START" and
					(
						(not triggerData.eventCLEU or triggerData.eventCLEU == "SPELL_CAST_START") and
						(not triggerData.spellID or triggerData.spellID == tonumber(line[3])) and
						(not triggerData.spellName or triggerData.spellName == GetSpellInfo(tonumber(line[3]))) and
						(not triggerData.sourceName or triggerData.sourceName == line[5]) and
						(not triggerData.sourceID or triggerData.sourceID and parseGUID(line[4],triggerData.sourceID)) and
						(not triggerData.targetName or triggerData.targetName == line[9])
					)
				-- (SetupFrameData.event == "SPELL_CAST_START" or SetupFrameData.event == "ADVANCED" or (SetupFrameData.event == "BOSS_PHASE" and tostring(phaseNow) == tostring(SetupFrameData.spellID)) or SetupFrameData.event == "BOSS_START" or not SetupFrameData.event or SetupFrame.QuickList.AllEventsChk:GetChecked())
				then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SCC,line[3],counter.cs[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.cs[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_CAST_SUCCESS" and
					(
						(not triggerData.eventCLEU or triggerData.eventCLEU == "SPELL_CAST_SUCCESS") and
						(not triggerData.spellID or triggerData.spellID == tonumber(line[3])) and
						(not triggerData.spellName or triggerData.spellName == GetSpellInfo(tonumber(line[3]))) and
						(not triggerData.sourceName or triggerData.sourceName == line[5]) and
						(not triggerData.sourceID or triggerData.sourceID and parseGUID(line[4],triggerData.sourceID)) and
						(not triggerData.targetName or triggerData.targetName == line[9])
					)
				then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SCS,line[3],counter.ce[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.ce[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_AURA_APPLIED" and
					(
						(not triggerData.eventCLEU or triggerData.eventCLEU == "SPELL_AURA_APPLIED") and
						(not triggerData.spellID or triggerData.spellID == tonumber(line[3])) and
						(not triggerData.spellName or triggerData.spellName == GetSpellInfo(tonumber(line[3]))) and
						(not triggerData.sourceName or triggerData.sourceName == line[5]) and
						(not triggerData.sourceID or triggerData.sourceID and parseGUID(line[4],triggerData.sourceID)) and
						(not triggerData.targetName or triggerData.targetName == line[9])
					)
				then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SAA,line[3],counter.aa[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.aa[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_AURA_REMOVED" and
					(
						(not triggerData.eventCLEU or triggerData.eventCLEU == "SPELL_AURA_REMOVED") and
						(not triggerData.spellID or triggerData.spellID == tonumber(line[3])) and
						(not triggerData.spellName or triggerData.spellName == GetSpellInfo(tonumber(line[3]))) and
						(not triggerData.sourceName or triggerData.sourceName == line[5]) and
						(not triggerData.sourceID or triggerData.sourceID and parseGUID(line[4],triggerData.sourceID)) and
						(not triggerData.targetName or triggerData.targetName == line[9])
					)
				then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SAR,line[3],counter.ar[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.ar[ line[4] ][ line[3] ]-1}
					}
				end
			else
				if line[2] == "PHASE" then --евент --line[4] = phasecount
					phaseTime = line[1] --геттайм
					phaseNow = line[3] or 0 --значение
					phaseRepeat=line[4] or 0 --кастнамбер

					result[#result+1] = {LR.QS_Phase,line[3],LR.QS_PhaseRepeat..phaseRepeat,FormatTime(line[1]-startTime),notspell=true,event=line[2],rep=line[4]}
				elseif line[2] == "UNIT_ENGAGE" then
					local time = line[1]
					local name = line[3]
					local guid = line[4]
					local unit = line[5]
					local spawnIndex

					local unitType,_,serverID,instanceID,zoneUID,mobID,spawnID = strsplit("-", guid or "")
					if unitType == "Creature" or unitType == "Vehicle" then
						spawnIndex = bit.rshift(bit.band(tonumber(string.sub(spawnID, 1, 5), 16), 0xffff8), 3)
					end

					result[#result+1] = {"NEW UNIT",mobID,name,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),unit,guid,spawnIndex,notspell=true,rep=line[4],event="UNIT_ENGAGE",timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat}}

				elseif line[2] == "SPELL_CAST_START" and (SetupFrameData.event == "SPELL_CAST_START" or SetupFrameData.event == "ADVANCED" or (SetupFrameData.event == "BOSS_PHASE" and tostring(phaseNow) == tostring(SetupFrameData.spellID)) or SetupFrameData.event == "BOSS_START" or not SetupFrameData.event or SetupFrame.QuickList.AllEventsChk:GetChecked()) then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SCC,line[3],counter.cs[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.cs[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_CAST_SUCCESS" and (SetupFrameData.event == "SPELL_CAST_SUCCESS" or SetupFrameData.event == "ADVANCED" or (SetupFrameData.event == "BOSS_PHASE" and tostring(phaseNow) == tostring(SetupFrameData.spellID)) or SetupFrameData.event == "BOSS_START" or not SetupFrameData.event or SetupFrame.QuickList.AllEventsChk:GetChecked()) then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SCS,line[3],counter.ce[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.ce[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_AURA_APPLIED" and ((SetupFrameData.event == "SPELL_AURA_APPLIED_SELF" and line[9] == playerName) or SetupFrameData.event == "SPELL_AURA_APPLIED" or (SetupFrame.QuickList.AurasChk:GetChecked() and SetupFrameData.event == "BOSS_PHASE" and tostring(phaseNow) == tostring(SetupFrameData.spellID)) or (SetupFrame.QuickList.AurasChk:GetChecked() and (SetupFrameData.event == "BOSS_START" or not SetupFrameData.event)) or (SetupFrame.QuickList.AurasChk:GetChecked())) then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SAA,line[3],counter.aa[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.aa[ line[4] ][ line[3] ]-1}
					}
				elseif line[2] == "SPELL_AURA_REMOVED" and ((SetupFrameData.event == "SPELL_AURA_REMOVED_SELF" and line[9] == playerName) or SetupFrameData.event == "SPELL_AURA_REMOVED" or (SetupFrame.QuickList.AurasChk:GetChecked() and SetupFrameData.event == "BOSS_PHASE" and tostring(phaseNow) == tostring(SetupFrameData.spellID)) or (SetupFrame.QuickList.AurasChk:GetChecked() and (SetupFrameData.event == "BOSS_START" or not SetupFrameData.event)) or (SetupFrame.QuickList.AurasChk:GetChecked())) then
					local spellName,_,spellTexture = GetSpellInfo(line[3])
					if (spellTexture == nil) then spellTexture = 136243 end
					result[#result+1] = {LR.QS_SAR,line[3],counter.ar[ line[4] ][ line[3] ].." |T"..spellTexture..":0|t "..spellName,FormatTime(line[1]-startTime),"["..phaseNow.."] "..FormatTime(line[1]-phaseTime),prevNow and format("%.1f",line[1]-prevNow),FormatName(line[5],line[7]),FormatName(line[9],line[11]),
						event=line[2],timeFromStart=line[1]-startTime,timeFromPhase=line[1]-phaseTime,phase={phaseNow,phaseRepeat},timeFromPrev=prevNow and {line[1]-prevNow,counter.ar[ line[4] ][ line[3] ]-1}
					}
				end
			end
		end
		SetupFrame.QuickList.L = result
		SetupFrame.QuickList:Update()
		for i=1, select("#", SetupFrame.QuickList.Frame.C:GetChildren()) do
			local ChildFrame = select(i, SetupFrame.QuickList.Frame.C:GetChildren())
			if ChildFrame.id == 1 then
				ChildFrame.text1:SetWidth(240)
				break
			end
		end
	end

	local replaceData = {
		OLD_CLEU = {
			{"{sourceName}",LR["rsourceName"] },
			{"{sourceMark}",LR["rsourceMark"] },
			{"{targetName}",LR["rtargetName"] },
			{"{targetMark}",LR["rtargetMark"] },
			{"{spellName}",LR["rspellName"] },
			{"{spellID}",LR["rspellID"] },
			{"{stacks}",LR["rstacks"] },
			{"{sourceGUID}",LR["rsourceGUID"] },
			{"{targetGUID}",LR["rtargetGUID"] },
			{"{counter}",LR["rcounter"] },
		},

		OLD_BIGWIGS = {
			{"{spellName}",LR["rspellName"] },
			{"{spellID}",LR["rspellID"] },
		},

		["sourceName"] = LR["rsourceName"],
		["sourceMark"] = LR["rsourceMark"],
		["sourceGUID"] = LR["rsourceGUID"],
		["targetName"] = LR["rtargetName"],
		["targetMark"] = LR["rtargetMark"],
		["targetGUID"] = LR["rtargetGUID"],
		["spellName"] = LR["rspellName"],
		["spellID"] = LR["rspellID"],
		["extraSpellID"] = LR["rextraSpellID"],
		["stacks"] = LR["rstacks"],
		["counter"] = LR["rcounter"],
		["guid"] = LR["rguid"],
		["health"] = LR["rhealth"],
		["value"] = LR["rvalue"],
		["timeLeft"] = LR["rtimeLeft"],
		["text"] = LR["rtext"],
		["phase"] = LR["rphase"],
		["auraValA"] = LR["rauraValA"],
		["auraValB"] = LR["rauraValB"],
		["auraValC"] = LR["rauraValC"],


		NOCLOSER = {
			{"{setparam:key:value}",LR["rsetparam"],LR["rsetparamTip"]},
			{"{math:x+x}",LR["rmath"],LR["rmathTip"]},
			{"{noteline:patt}",LR["rnoteline"],LR["rnotelineTip"]},
			{"{note:pos:patt}",LR["rnote"],LR["rnoteTip"]},
			{"{min:x;y;z,c,v,b}",LR["rmin"],LR["rminTip"]},
			{"{max:x;y;z,c,v,b}",LR["rmax"],LR["rmaxTip"]},
			{"{role:name}",LR["rrole"],LR["rroleTip"]},
			{"{roleextra:name}",LR["rextraRole"],LR["rextraRoleTip"]},
			{"{sub:pos1:pos2:text}",LR["rsub"],LR["rsubTip"]},
			{"{trim:text}",LR["rtrim"],LR["rtrimTip"]},
		},
		CLOSER = {
			{"{num:x}","{/num}",LR["rnum"],LR["rnumTip"]},
			{"{up}","{/up}",LR["rup"],LR["rupTip"]},
			{"{lower}","{/lower}",LR["rlower"],LR["rlowerTip"]},
			{"{rep:x}","{/rep}",LR["rrep"],LR["rrepTip"]},
			{"{len:x}","{/len}",LR["rlen"],LR["rlenTip"]},
			{"{0}line","{/0}",LR["rnone"],LR["rnoneTip"]},
			{"{cond:1<2 AND 1=1}yes;no","{/cond}",LR["rcondition"],LR["rconditionTip"]},
			{"{find:patt:text}yes;no","{/find}",LR["rfind"],LR["rfindTip"]},
			{"{replace:x:y}","{/replace}",LR["rreplace"],LR["rreplaceTip"]},
			{"{set:1}","{/set}",LR["rsetsave"],LR["rsetsaveTip"]},
			{"%set1","",LR["rsetload"],LR["rsetloadTip"]},
		},
		BASE_REPLACERS = {
			{"{spell:}",LR["rspellIcon"],LR["rspellIconTip"]},
			{"%classColor",LR["rclassColor"],LR["rclassColorTip"]},
			{"%specIcon",LR["rspecIcon"],LR["rspecIconTip"]},
			{"%specIconAndClassColor",LR["rclassColorAndSpecIcon"],LR["rclassColorAndSpecIconTip"]},
			{"%playerName",LR["rplayerName"]},
			{"%playerClass",LR["rplayerClass"]},
			{"%playerSpec",LR["rplayerSpec"]},
			{"%defCDIcon",LR["rPersonalIcon"], "|cffff7c0aDRUID|r - |T136097:0|t\n|cff0070ddSHAMAN|r - |T538565:0|t\n|cff8788eeWARLOCK|r - |T136150:0|t\n|cff00ff98MONK|r - |T615341:0|t\n|cff3fc7ebMAGE|r - |T135994:0|t\n|cffa330c9DEMONHUNTER|r - |T1305150:0|t\n|cffc41e3aDEATHKNIGHT|r - |T237525:0|t\n|cffffffffPRIEST|r - |T237550:0|t\n|cffaad372HUNTER|r - |T136094:0|t\n|cfff48cbaPALADIN|r - |T524353:0|t\n|cffc69b6dWARRIOR|r - |T132345:0|t\n|cfffff468ROGUE|r - |T132294:0|t\n|cff33937fEVOKER|r - |T1394891:0|t"},
			{"%damageImmuneCDIcon",LR["rImmuneIcon"],"|cff3fc7ebMAGE|r - |T135841:0|t\n|cffaad372HUNTER|r - |T132199:0|t\n|cfff48cbaPALADIN|r - |T524354:0|t\n|cfffff468ROGUE|r - |T136177:0|t\n|cffa330c9DEMONHUNTER|r - |T463284:0|t"},
			{"%sprintCDIcon",LR["rSprintIcon"], "|cffff7c0aDRUID|r - |T464343:0|t\n|cff0070ddSHAMAN|r - |T538576:0|t \n|cff00ff98MONK|r - |T651727:0|t\n|cff33937fEVOKER|r - |T4622479:0|t"},
			{"%healCDIcon",LR["rHealCDIcon"],"|cfff48cbaHOLY|r - |T3565722:0|t\n|cffffffffHOLY|r - |T237540:0|t \n|cff0070ddRESTORATION|r - |T538569:0|t\n|cff00ff98MISTWEAVER|r - |T1020466:0|t\n|cffff7c0aRESTORATION|r - |T136107:0|t\n|cff33937fPRESERVATION|r - |T4622474:0|t"},
			{"%raidCDIcon",LR["rRaidCDIcon"],"|cfff48cbaHOLY|r - |T135872:0|t\n|cfff48cbaPROTECTION|r - |T135880:0|t\n|cffffffffDISCIPLINE|r - |T253400:0|t\n|cff0070ddRESTORATION|r - |T237586:0|t\n|cffc69b6dWARRIOR|r - |T132351:0|t \n|cffa330c9DEMON HUNTER|r - |T1305154:0|t\n|cffc41e3aDEATH KNIGHT|r - |T237510:0|t"},
			{"{counter}",LR["rCounter"]},
		},
		ADV_REPLACERS = {
			{"{timeLeftx:y}",LR["rTimeLeft"],LR["rTimeLeftTip"]},
			{"{activeTimex:y}",LR["rActiveTime"],LR["rActiveTimeTip"]},
			{"{activeNum}",LR["rActiveNum"],LR["rActiveNumTip"]},
			{"{timeMinLeft:x}",LR["rMinTimeLeft"],LR["rMinTimeLeftTip"]},
			{"{status:triggerNum:uid}",LR["rTriggerStatus"],LR["rTriggerStatusTip"]},
			{"{allSourceNames:num1:num2:customPattern}",LR["rAllSourceNames"],LR["rAllSourceNamesTip"]},
			{"{allTargetNames:num1:num2:customPattern}",LR["rAllTargetNames"],LR["rAllTargetNamesTip"]},
			{"{allActiveUIDs:num1:num2}",LR["rAllActiveUIDs"],LR["rAllActiveUIDsTip"]},
			{"{patt}",LR["rNoteAll"]},
			{"%notePlayer",LR["rNoteLeft"]},
			{"%notePlayerRight",LR["rNoteRight"]},
		},
	}

	function SetupFrame.replaceDropDown:replaceSetValue(replacer,closer)
		ELib:DropDownClose()
		local selectedStart,selectedEnd = SetupFrame.msg:GetTextHighlight()
		if replacer and closer then
			if selectedStart == selectedEnd then
				AddTextToEditBox(nil,replacer..closer,nil,true)
			else
				AddTextToEditBox(nil,closer,selectedEnd,true)
				AddTextToEditBox(nil,replacer,selectedStart,true)
			end
		else
			AddTextToEditBox(nil,replacer,selectedStart,true)
		end
	end

	function SetupFrame.replaceDropDownUpdate()
		wipe(SetupFrame.replaceDropDown.List)
		if not SetupFrameData then
			return
		end
		local List = SetupFrame.replaceDropDown.List
		if not List then
			return
		end
		-----------OLD CLEU
		if SetupFrameData.event == "SPELL_CAST_START" or SetupFrameData.event == "SPELL_CAST_SUCCESS" or
			SetupFrameData.event == "SPELL_AURA_APPLIED"  or SetupFrameData.event == "SPELL_AURA_REMOVED"  or
			SetupFrameData.event == "SPELL_AURA_APPLIED_SELF"  or SetupFrameData.event == "SPELL_AURA_REMOVED_SELF"
		then
			List[#List+1] = {
				text ="OLD CLEU REPLACERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.OLD_CLEU do
				List[#List+1] = {
					text = replaceData.OLD_CLEU[i][2],
					arg1 = replaceData.OLD_CLEU[i][1],
					func = SetupFrame.replaceDropDown.replaceSetValue,
				}
			end
			---------OLD BIGWIGS
		elseif SetupFrameData.event == "BW_MSG" or
			SetupFrameData.event == "BW_TIMER" or
			SetupFrameData.event == "BW_TIMER_TEXT"
		then
			List[#List+1] = {
				text ="OLD BIGWIGS REPLACERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.OLD_BIGWIGS do
				List[#List+1] = {
					text = replaceData.OLD_BIGWIGS[i][2],
					arg1 = replaceData.OLD_BIGWIGS[i][1],
					func = SetupFrame.replaceDropDown.replaceSetValue,
				}
			end
			----------REPLACERS FOR TRIGGERS
		elseif SetupFrameData.event == "ADVANCED" then
			List[#List+1] = {
				text = "ADVANCED TRIGGER REPLACERS",
				justifyH = "CENTER",
				isTitle = true,
			}
			for i=1,#replaceData.ADV_REPLACERS do
				List[#List+1] = {
					text = replaceData.ADV_REPLACERS[i][2],
					arg1 = replaceData.ADV_REPLACERS[i][1],
					tooltip = replaceData.ADV_REPLACERS[i][3],
					func = SetupFrame.replaceDropDown.replaceSetValue,
				}
			end
			for i=1,#SetupFrameData.triggers do
				local triggerData = SetupFrameData.triggers[i]
				local eventDB = module.C[triggerData.eventCLEU or triggerData.event]
				if eventDB and eventDB.replaceres then
					List[#List+1] = {
						text ="TRIGGER " .. i .. " REPLACERS",
						justifyH = "CENTER",
						isTitle = true,

					}

					for j=1,#eventDB.replaceres do
						if eventDB.replaceres[j] == "targetMark" or eventDB.replaceres[j] == "sourceMark" then
							List[#List+1] = {
								text = eventDB.replaceres[eventDB.replaceres[j]] or replaceData[ eventDB.replaceres[j] ] or eventDB.replaceres[j],
								arg1 = "{" .. eventDB.replaceres[j] .. "Num" .. i  .. "}",
								func = SetupFrame.replaceDropDown.replaceSetValue,
							}
							List[#List].text = List[#List].text .. " (Number)"
						end
						List[#List+1] = {
							text = eventDB.replaceres[eventDB.replaceres[j]] or replaceData[ eventDB.replaceres[j] ] or eventDB.replaceres[j],
							arg1 = "{" .. eventDB.replaceres[j] .. i .. "}",
							func = SetupFrame.replaceDropDown.replaceSetValue,
						}
					end
				end
			end
		end
		------BASE REPLACERS BASE_REPLACERS
		List[#List+1] = {
			text = "BASE REPLACERS",
			justifyH = "CENTER",
			isTitle = true,
		}
		for i=1,#replaceData.BASE_REPLACERS do
			List[#List+1] = {
				text = replaceData.BASE_REPLACERS[i][2],
				arg1 = replaceData.BASE_REPLACERS[i][1],
				tooltip = replaceData.BASE_REPLACERS[i][3],
				func = SetupFrame.replaceDropDown.replaceSetValue,
			}
		end
		---------------NOCLOSER
		List[#List+1] = {
			text = "NOCLOSER MODIFIERS",
			justifyH = "CENTER",
			isTitle = true,
		}
		for i=1,#replaceData.NOCLOSER do
			List[#List+1] = {
				text = replaceData.NOCLOSER[i][2],
				arg1 = replaceData.NOCLOSER[i][1],
				tooltip = replaceData.NOCLOSER[i][3],
				func = SetupFrame.replaceDropDown.replaceSetValue,
			}
		end
		---------------CLOSER
		List[#List+1] = {
			text = "CLOSER MODIFIERS",
			justifyH = "CENTER",
			isTitle = true,
		}
		for i=1,#replaceData.CLOSER do
			List[#List+1] = {
				text = replaceData.CLOSER[i][3],
				arg1 = replaceData.CLOSER[i][1],
				arg2 = replaceData.CLOSER[i][2],
				tooltip = replaceData.CLOSER[i][4],
				func = SetupFrame.replaceDropDown.replaceSetValue,
			}
		end
	end

	local function SideColors()
		if not SetupFrameData.zoneID then
			SetupFrame.zoneText:Color(0.5,0.5,0.5)
			SetupFrame.zoneRawText:Color(0.5,0.5,0.5)
		else
			SetupFrame.zoneText:Color()
			SetupFrame.zoneRawText:Color()
		end

		if not SetupFrameData.name then
			SetupFrame.nameText:Color(0.5,0.5,0.5)
		else
			SetupFrame.nameText:Color()
		end

		if SetupFrameData.doNotLoadOnBosses then
			SetupFrame.doNotLoadOnBossesText:Color()
		else
			SetupFrame.doNotLoadOnBossesText:Color(0.5,0.5,0.5)
		end

		if not SetupFrameData.msg then
			SetupFrame.msgText:Color(0.5,0.5,0.5)
		else
			SetupFrame.msgText:Color()
		end

		if not SetupFrameData.spellID then
			SetupFrame.spellIDText:Color(0.5,0.5,0.5)
		else
			SetupFrame.spellIDText:Color()
		end

		if not SetupFrameData.cast then
			SetupFrame.rawCastEditText:Color(0.5,0.5,0.5)
			SetupFrame.castListText:Color(0.5,0.5,0.5)
		else
			SetupFrame.rawCastEditText:Color()
			SetupFrame.castListText:Color()
		end

		if not SetupFrameData.condition then
			SetupFrame.conditionListText:Color(0.5,0.5,0.5)
		else
			SetupFrame.conditionListText:Color()
		end

		if not SetupFrameData.delay then
			SetupFrame.delayText:Color(0.5,0.5,0.5)
		else
			SetupFrame.delayText:Color()
		end

		if not SetupFrameData.duration then
			SetupFrame.durationText:Color(0.5,0.5,0.5)
		else
			SetupFrame.durationText:Color()
		end

		if not SetupFrameData.sound then
			SetupFrame.soundText:Color(0.5,0.5,0.5)
		else
			SetupFrame.soundText:Color()
		end
		if not SetupFrameData.voiceCountdown then
			SetupFrame.voiceCountdownText:Color(0.5,0.5,0.5)
		else
			SetupFrame.voiceCountdownText:Color()
		end

		if not SetupFrameData.tts then
			SetupFrame.ttsText:Color(0.5,0.5,0.5)
		else
			SetupFrame.ttsText:Color()
		end

		if not SetupFrameData.glow then
			SetupFrame.glowText:Color(0.5,0.5,0.5)
		else
			SetupFrame.glowText:Color()
		end

		if not SetupFrameData.spamType then
			SetupFrame.spamTypeText:Color(0.5,0.5,0.5)
		else
			SetupFrame.spamTypeText:Color()
		end

		if not SetupFrameData.spamChannel then
			SetupFrame.spamChannelText:Color(0.5,0.5,0.5)
		else
			SetupFrame.spamChannelText:Color()
		end

		if not SetupFrameData.spamMsg then
			SetupFrame.spamMsgText:Color(0.5,0.5,0.5)
		else
			SetupFrame.spamMsgText:Color()
		end

        if not SetupFrameData.units then
            SetupFrame.unitsText:Color(0.5,0.5,0.5)
        else
            SetupFrame.unitsText:Color()
        end

        if not SetupFrameData.notepat then
            SetupFrame.notePatternEditText:Color(0.5,0.5,0.5)
        else
            SetupFrame.notePatternEditText:Color()
        end

        if not SetupFrameData.copy and not SetupFrameData.isPersonal and not SetupFrameData.norewrite and not SetupFrameData.dynamicdisable then
            SetupFrame.addOptionsListText:Color(0.5,0.5,0.5)
        else
            SetupFrame.addOptionsListText:Color()
        end

        if not SetupFrameData.extraCheck then
            SetupFrame.extraCheckText:Color(0.5,0.5,0.5)
        else
            SetupFrame.extraCheckText:Color()
        end

        if not SetupFrameData.specialTarget then
            SetupFrame.specialTargetText:Color(0.5,0.5,0.5)
        else
            SetupFrame.specialTargetText:Color()
        end

        if not SetupFrameData.nameplateGlow then
            SetupFrame.nameplateGlowText:Color(0.5,0.5,0.5)
        else
            SetupFrame.nameplateGlowText:Color()
        end

        if not SetupFrameData.glowScale then
            SetupFrame.glowScaleText:Color(0.5,0.5,0.5)
        else
            SetupFrame.glowScaleText:Color()
        end

        if not SetupFrameData.glowThick then
            SetupFrame.glowThickText:Color(0.5,0.5,0.5)
        else
            SetupFrame.glowThickText:Color()
        end

        if not SetupFrameData.glowN then
            SetupFrame.glowNText:Color(0.5,0.5,0.5)
        else
            SetupFrame.glowNText:Color()
        end

        if not SetupFrameData.nameplateText then
            SetupFrame.nameplateTextText:Color(0.5,0.5,0.5)
        else
            SetupFrame.nameplateTextText:Color()
        end

        if not SetupFrameData.glowImage then
            SetupFrame.glowImageText:Color(0.5,0.5,0.5)
        else
            SetupFrame.glowImageText:Color()
            if SetupFrameData.glowImage == 0 then
                SetupFrame.glowImageCustomText:Color(0.5,0.5,0.5)
            else
                SetupFrame.glowImageCustomText:Color()
            end
        end

        if not SetupFrameData.countdown then
            SetupFrame.countdownTypeDropDownText:Color(0.5,0.5,0.5)
        else
            SetupFrame.countdownTypeDropDownText:Color()
        end

	end
	module.SetupFrameDataRequirements = {
		[1] = {0,"msg","spamMsg","nameplateGlow","sound","tts","glow"},--0 значит достаточно любого из следующих значений

		--exception: значит что условие не должно проверяться когда значение exception == true
		[2] = {"duration",["exception"] = "sendEvent"},
		[3] = {"event"},

		--имяПоля = {...} означает что ... проверяеться когда имяПоля есть в дате
		["spamMsg"] = {"spamType","spamChannel"},
		["spamType"] = {"spamMsg","spamChannel"},
		["spamChannel"] = {"spamMsg","spamType"},

		["sendEvent"] = {"msg"},

		["NOT ADVANCED"] = --условия для всех кроме ADVANCED
		{"spellID",["exception"]="BOSS_START"},--здесть exception только для event

		--условия для проверки advanced прописаны в module.C >>> 'alertFields'
	}

	local FieldsToMove = {
		eventCLEU = true,sourceName= true,sourceID= true,sourceUnit= true,sourceMark= true,
		targetName= true,targetID= true,targetUnit= true,targetMark= true,targetRole= true,
		spellID= true,spellName= true,extraSpellID= true,stacks= true,numberPercent= true,
		pattFind= true,bwtimeleft= true,counter= true,cbehavior= true,delayTime= true,
		activeTime= true,guidunit= true,onlyPlayer= true,
	}

	function UpdateAlerts()
		--remove all alerts first
		for k,v in pairs(SetupFrame) do
			if type(SetupFrame[k]) == 'table' and SetupFrame[k].ColorBorder then
				SetupFrame[k]:ColorBorder()
			end
		end
		-- 1 - yellow(only for advanced)
		-- 2 - blue
		-- 3 - red
		local alertsLevel = {}

		for k,v in pairs(module.SetupFrameDataRequirements) do
			if type(k) == 'number' then --always check
				local oneOF = false
				if not SetupFrameData[ v["exception"] ] then
					for i,field in ipairs(v) do
						if field == 0 then
							oneOF = i + 1
						elseif oneOF then
							local anyFilled
							for  j=oneOF,#v do
								if SetupFrameData[ v[j] ] then
									anyFilled = true
								end
							end
							if not anyFilled then
								for  j=oneOF,#v do
									if not alertsLevel[ v[j] ] or (alertsLevel[ v[j] ] and alertsLevel[ v[j] ] < 2) then
										alertsLevel[ v[j] ] = 2
									end
								end
							end
						else
							if not SetupFrameData[field] then
								if not alertsLevel[field] or (alertsLevel[field] and alertsLevel[field] < 3) then
									alertsLevel[field] = 3
								end
							end
						end
					end
				end
			elseif type(k) == 'string' then --check only if SetupFrameData[k]
				-- print(SetupFrameData.event[v["exception"]],v['exception'])
				if SetupFrameData[k] or (k == "NOT ADVANCED" and SetupFrameData.event ~= "ADVANCED" and SetupFrameData.event ~= v["exception"]) then
					for i,field in ipairs(v) do
						if not SetupFrameData[field] then
							if not alertsLevel[field] or (alertsLevel[field] and alertsLevel[field] < 3) then
								alertsLevel[field] = 3
							end
						end
					end
				end
			end
		end


		local yellowAlert = {}
		local anyUntimed = false
		advAlert = false
		local triggersCount = SetupFrameData.triggers and #SetupFrameData.triggers or 0
		for t=1,triggersCount do
			local triggerFields = subEventField[t]
			local triggerData = SetupFrameData.triggers[t]
			local eventDB = module.C[triggerData.eventCLEU or triggerData.event]
			local fieldsDB = eventDB.triggerSynqFields or eventDB.triggerFields
			local oneOf
			for k,currentField in pairs(fieldsDB) do
				--removing advanced alerts
				if triggerFields[currentField] and triggerFields[currentField].ColorBorder then triggerFields[currentField]:ColorBorder() end

				if currentField ~= "guidunit" and currentField ~= "cbehavior" then
					if eventDB.fieldNames and eventDB.fieldNames[currentField] then
						subEventFieldText[t][currentField]:SetText(triggerData[currentField] and eventDB.fieldNames[currentField] or "|cff808080" .. eventDB.fieldNames[currentField] .. "|r" )
					elseif subEventFieldText[t][currentField] then
						subEventFieldText[t][currentField]:SetText(triggerData[currentField] and LR[currentField] or "|cff808080" .. LR[currentField] .. "|r" )
					end
				end
			end
			if module.C[triggerData.event].alertFields then
				for j=1,#module.C[triggerData.event].alertFields  do
					local currField = module.C[triggerData.event].alertFields[j]
					if currField == 0 then
						oneOf = j
					elseif oneOf then
						local anyFilled
						for i=oneOf,#module.C[triggerData.event].alertFields  do
							local currField2 = module.C[triggerData.event].alertFields[i]
							if triggerData[currField2] and triggerData[currField2] ~= "" then anyFilled = true end
						end

						if not anyFilled then
							triggerFields[currField]:ColorBorder(0,0.5,1,1)
							advAlert = true
							triggerTabs.nButtons[t].Texture:SetGradient("VERTICAL",CreateColor(0.5,0,0,1), CreateColor(0.4,0,0,1))
						else
							triggerFields[currField]:ColorBorder()
							triggerTabs.nButtons[t].Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
						end
					else
						if not triggerData[currField] then
							triggerFields[currField]:ColorBorder(true)
							advAlert = true
							triggerTabs.nButtons[t].Texture:SetGradient("VERTICAL",CreateColor(0.5,0,0,1), CreateColor(0.4,0,0,1))
						else
							triggerFields[currField]:ColorBorder()
							triggerTabs.nButtons[t].Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
						end
					end
				end
			else
				for j=1,#fieldsDB do
					if triggerFields[fieldsDB[j]].ColorBorder then
						triggerFields[fieldsDB[j]]:ColorBorder()
						triggerTabs.nButtons[t].Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
					end
				end
			end

			if
				not eventDB.isUntimed and
				(not triggerData.activeTime or triggerData.activeTime == "0" or triggerData.activeTime == "" ) and
				(not SetupFrameData.duration or SetupFrameData.duration == 0 or SetupFrameData.duration == "" )
			then
				yellowAlert[t] = true
			end
			if eventDB.isUntimed then
				anyUntimed = true
			end
			triggerTabs.nButtons[t].tooltip = nil
			subEventField[t]["activeTime"].tooltip = nil
			subEventField[t]["activeTime"]:ColorBorder()
			-- if not SetupFrameData.duration then
			-- 	SetupFrame.duration:ColorBorder(true)
			-- else
			-- 	SetupFrame.duration:ColorBorder()
			-- end
		end
		if not advAlert and not anyUntimed and #yellowAlert > 0 then
			for k,v in pairs(yellowAlert) do
				triggerTabs.nButtons[k]:Tooltip(LR.YellowAlertTip)
				triggerTabs.nButtons[k].Texture:SetGradient("VERTICAL",CreateColor(0.5,0.5,0,1), CreateColor(0.4,0.4,0,1))
				subEventField[k]["activeTime"]:Tooltip(LR.YellowAlertTip)
				subEventField[k]["activeTime"]:ColorBorder(0.5,0.5,0,1)
			end
			if not alertsLevel['duration'] or (alertsLevel['duration'] and alertsLevel['duration'] < 1) then
				alertsLevel['duration'] = 1
			end
		end
		if not advAlert then
			SetupFrame.SaveButton:Enable()
			SetupFrame.SaveButton:GetFontString():SetFont(tabFont, 13, "OUTLINE")
		else
			SetupFrame.SaveButton:Disable()
			SetupFrame.SaveButton:GetFontString():SetFont(tabFont, 13)
		end
		for k,v in pairs(alertsLevel) do
			if v == 3 then
				if SetupFrame[k] and SetupFrame[k].ColorBorder then
					SetupFrame[k]:ColorBorder(true)
					SetupFrame.SaveButton:Disable()
					SetupFrame.SaveButton:GetFontString():SetFont(tabFont, 13)
				end
			elseif v == 2 then
				if SetupFrame[k] and SetupFrame[k].ColorBorder  then
					SetupFrame[k]:ColorBorder(0,0.5,1,1)
					SetupFrame.SaveButton:Disable()
					SetupFrame.SaveButton:GetFontString():SetFont(tabFont, 13)
				end
			elseif v == 1 then
				if SetupFrame[k] and SetupFrame[k].ColorBorder  then
					SetupFrame[k]:ColorBorder(1,1,0,1)
				end
			end
		end
	end

	function advSetupFrameUpdate()
		local triggersStr = ""
		local opened = false
		for i=#SetupFrameData.triggers,2,-1 do
			local trigger = SetupFrameData.triggers[i]
			if not trigger.andor or trigger.andor == 1 then
				triggersStr = " and "..(opened and "(" or "")..(trigger.invert and "not " or "").."t" .. i .. triggersStr
				opened = false
			elseif trigger.andor == 2 then
				triggersStr = " or "..(opened and "(" or "")..(trigger.invert and "not " or "").."t"..i .. triggersStr
				opened = false
			elseif trigger.andor == 3 then
				triggersStr = " or "..(trigger.invert and "not " or "").."t"..i..(not opened and ")" or "").." " .. triggersStr
				opened = true
			end
		end
		triggersStr = "Activation function: "..(opened and "(" or "")..(SetupFrameData.triggers[1].invert and "not " or "").."t1"..triggersStr
		activeFuncText:SetText(triggersStr)
		for t=1,#SetupFrameData.triggers do
			local triggerFields = subEventField[t]
			local triggerData = SetupFrameData.triggers[t]
			local eventDB = module.C[triggerData.eventCLEU or triggerData.event]
			if not eventDB then return end


			if t > 1 and triggerFields["andor"] then
				local andorText = triggerData["andor"] and andorList[triggerData["andor"]][2] or "AND"
				triggerFields["andor"]:SetText(andorText)
			end
			for j=1,#module.datas.fields do
				triggerFields[module.datas.fields[j]]:Hide()
			end


			local fieldsDB = eventDB.triggerSynqFields or eventDB.triggerFields

			subEventFieldText[t]["event"].help:SetText(module.C[triggerData.event].help)

			for j=1,#fieldsDB do
				triggerFields[fieldsDB[j]]:Show()
			end

			local fieldIndex = 0
			for j=1,#fieldsDB do
				if FieldsToMove[fieldsDB[j]] then
					local currField = triggerFields[fieldsDB[j]]
					if currField:IsShown() then
						fieldIndex = fieldIndex + 1
						currField:Point("TOPLEFT",triggerFields["event"],"BOTTOMLEFT",0,(-25*fieldIndex)+20)
						if fieldsDB[j] == "spellID" then
							fieldIndex = fieldIndex + 1
						end
					end
				end
			end


			triggerFields["event"]:SetText(module.C[triggerData.event].lname or "")
			for j=1,#module.datas.fields do
				local currentField = module.datas.fields[j]

				if currentField == "eventCLEU" then
					triggerFields["eventCLEU"]:SetText(triggerData.eventCLEU and eventDB.lname or "")
				elseif currentField == "invert" then
					triggerFields["invert"]:SetChecked(not triggerData["invert"])
				elseif currentField == "onlyPlayer" then
					triggerFields["onlyPlayer"]:SetChecked(triggerData["onlyPlayer"])
				elseif currentField == "cbehavior" then
					local datacbeh = triggerData.cbehavior
					for i=1,#module.datas.counterBehavior do
						if module.datas.counterBehavior[i][1] == datacbeh then
							triggerFields["cbehavior"]:SetText(module.datas.counterBehavior[i][2] or "Default")
							break
						end
					end
				elseif currentField == "sourceMark" then
					local dataMark  = triggerData.sourceMark
					for i=1,#module.datas.marks do
						if module.datas.marks[i][1] == dataMark then
							triggerFields["sourceMark"]:SetText(module.datas.marks[i][2] or module.datas.marks[i][1])
							break
						end
					end
				elseif currentField == "targetMark" then
					local dataMark = triggerData.targetMark
					for i=1,#module.datas.marks do
						if module.datas.marks[i][1] == dataMark then
							triggerFields["targetMark"]:SetText(module.datas.marks[i][2] or module.datas.marks[i][1])
							break
						end
					end
				elseif currentField == "sourceUnit" then
					local dataMark = triggerData.sourceUnit
					for i=1,#module.datas.units do
						if module.datas.units[i][1] == dataMark then
							triggerFields["sourceUnit"]:SetText(module.datas.units[i][2] or module.datas.units[i][1])
							break
						end
					end
				elseif currentField == "targetUnit" then
					local dataMark = triggerData.targetUnit
					for i=1,#module.datas.units do
						if module.datas.units[i][1] == dataMark then
							triggerFields["targetUnit"]:SetText(module.datas.units[i][2] or module.datas.units[i][1])
							break
						end
					end
				elseif currentField == "targetRole" then
					local dataRole = triggerData.targetRole
					for i=1,#module.datas.rolesList do
						if module.datas.rolesList[i][1] == dataRole then
							triggerFields["targetRole"]:SetText(module.datas.rolesList[i][3] or "")
							break
						end
					end
				elseif currentField == "guidunit" then
					local dataRole = triggerData.targetRole
					for i=1,#module.datas.rolesList do
						if module.datas.rolesList[i][1] == dataRole then
							triggerFields["guidunit"]:SetText(triggerData.guidunit and triggerData.guidunit == 1 and LR["Source"] or LR["Target"])
							break
						end
					end
				elseif currentField == "spellID" then
					if triggerData.eventCLEU ~= "ENVIRONMENTAL_DAMAGE" then
						triggerFields["spellID"]:Tooltip("")
					else
						triggerFields["spellID"]:Tooltip(LR.EnvironmentalDMGTip)
					end
					triggerFields[currentField]:SetText(triggerData[currentField] or "")
				else
					triggerFields[currentField]:SetText(triggerData[currentField] or "")
				end
			end
		end
		SetupFrame.replaceDropDownUpdate()
		UpdateAlerts()
		-- SaveButtonCheck()
	end

	function module:SetupFrameUpdate(UpdateAdvanced)
		advAlert = false
		SetupFrame.title:SetText(SetupFrameData.name or "")
		SetupFrame.conditionList:Show()
        SetupFrame.disabled:SetChecked(not SetupFrameData.disabled)

		if RawData then
			SetupFrame.BossListRaw:Show()
			SetupFrame.zoneRaw:Show()
			SetupFrame.DiffListRaw:Show()
			SetupFrame.rawCastEdit:Show()
			SetupFrame.bossList:Hide()
			SetupFrame.zone:Hide()
			SetupFrame.diffList:Hide()
			SetupFrame.castList:Hide()
		else
			SetupFrame.BossListRaw:Hide()
			SetupFrame.zoneRaw:Hide()
			SetupFrame.DiffListRaw:Hide()
			SetupFrame.rawCastEdit:Hide()
			SetupFrame.bossList:Show()
			SetupFrame.zone:Show()
			SetupFrame.diffList:Show()
			SetupFrame.castList:Show()
		end

		SetupFrame.zone:SetText("")
		if SetupFrameData.zoneID then
			local zoneID = tonumber(tostring(SetupFrameData.zoneID):match("^[^, ]+") or "",10)
			local zoneName = VExRT.Reminder.zoneNames[zoneID] or SetupFrameData.zoneID

			SetupFrame.zone:SetText(zoneName)
		end

		if ExRT.is11 then
			SetupFrame.bossList:SetText(SetupFrameData.boss and L.bossName[ SetupFrameData.boss ] ~= "" and L.bossName[ SetupFrameData.boss ] or SetupFrameData.boss or LR.Always)
		elseif ExRT.isLK then
			SetupFrame.bossList:SetText(SetupFrameData.boss and NameByID(SetupFrameData.boss) or SetupFrameData.boss or LR.Always)
		end

		SetupFrame.event:SetText("")

		for i=1,#eventsList do
			if eventsList[i][1] == SetupFrameData.event then
				SetupFrame.event:SetText(eventsList[i][2])
				break
			end
		end
		for i=1,#module.datas.countdownType do
			if module.datas.countdownType[i][1] == SetupFrameData.countdownType then
				SetupFrame.countdownTypeDropDown:SetText((SetupFrameData.countdown and "" or "|cff888888") .. module.datas.countdownType[i][2])
			end
		end
		SetupFrame.spellID:SetNumeric(true)
		SetupFrame.duration:SetNumeric(false)


		SetupFrame.msgText:SetText(SetupFrameData.sendEvent and "WeakAuras Event Message:" or LR.msg)

		SetupFrame.msg.EditBox:Tooltip(SetupFrameData.sendEvent and "WeakAuras Event Message:" or LR.msg)

		if (SetupFrameData.event ~= "BOSS_PHASE" and SetupFrameData.event ~= "BOSS_HP" and SetupFrameData.event ~= "BOSS_MANA" and SetupFrameData.event ~= "BOSS_START" and SetupFrameData.event ~= "BW_TIMER_TEXT") then
			SetupFrame.eventSIDSpellNameText:Show()
		else
			SetupFrame.eventSIDSpellNameText:Hide()
		end
		local isAdvanced = false
		if SetupFrameData.event == "ADVANCED" then
			isAdvanced = true
		elseif SetupFrameData.event == "BOSS_PHASE" then
			SetupFrame.spellIDText:SetText(LR.PhaseNumber)
			SetupFrame.spellID:Show()
			SetupFrame.spellID:SetNumeric(false)
			SetupFrame.useGlobalCounterCheck:Hide()
			SetupFrame.conditionList:Hide()
		elseif SetupFrameData.event == "BOSS_START" then
			SetupFrame.spellIDText:SetText("")
			SetupFrame.castList:Hide()
			SetupFrame.rawCastEdit:Hide()
			SetupFrame.spellID:Hide()
			SetupFrame.useGlobalCounterCheck:Hide()
			SetupFrame.conditionList:Hide()
		elseif SetupFrameData.event == "BOSS_HP" then
			SetupFrame.spellIDText:SetText(LR.BossHpLess)
			SetupFrame.spellID:Show()
			SetupFrame.spellID:SetNumeric(false)
			SetupFrame.useGlobalCounterCheck:Hide()
			SetupFrame.castList:Hide()
			SetupFrame.rawCastEdit:Hide()
		elseif SetupFrameData.event == "BOSS_MANA" then
			SetupFrame.spellIDText:SetText(LR.BossManaLess)
			SetupFrame.spellID:Show()
			SetupFrame.spellID:SetNumeric(false)
			SetupFrame.useGlobalCounterCheck:Hide()
		elseif SetupFrameData.event == "BW_TIMER_TEXT" then
			SetupFrame.spellID:SetNumeric(false)
			SetupFrame.spellIDText:SetText(LR.TimerText)
			SetupFrame.spellID:Show()
		else
			SetupFrame.spellIDText:SetText("Spell ID:")
			SetupFrame.spellID:Show()
			SetupFrame.useGlobalCounterCheck:Show()
		end
		if isAdvanced then
			TRIGGERSBORDERFRAME:Show()
			CUSTOMBORDERFRAME:Show()
			SetupFrameScroll:Height(2425)

			SetupFrame.spellID:Hide()
			SetupFrame.castList:Hide()
			SetupFrame.rawCastEdit:Hide()
			SetupFrame.conditionList:Hide()
			SetupFrame.useGlobalCounterCheck:Hide()
			SetupFrameData.spellID = nil
			SetupFrameData.cast = nil
            SetupFrameData.condition = nil
			SetupFrameData.triggers = SetupFrameData.triggers or {{event=1}}
			if UpdateAdvanced then
				SetupFrame.CreateTriggerTabs()
			end
		else
			SetupFrameData.extraCheck = nil
			SetupFrameData.specialTarget = nil
			SetupFrameData.nameplateGlow = nil
			SetupFrameData.nameplateText = nil
			TRIGGERSBORDERFRAME:Hide()
			CUSTOMBORDERFRAME:Hide()
			SetupFrameScroll:Height(1500)

			SetupFrameData.triggers = nil
			if triggerTabs then triggerTabs:Hide() end
		end
		if SetupFrameData.event == "BW_TIMER" or SetupFrameData.event == "BW_TIMER_TEXT"  then
			SetupFrame.delayText:SetText(LR.TimerTimeLeft)
			SetupFrame.conditionList:Hide()
		else
			SetupFrame.delayText:SetText(LR.delayText)
		end
		if  SetupFrameData.event == "BW_TIMER_TEXT"  then
			SetupFrame.spellID:Tooltip("Exact text from timer bar")
		else
			SetupFrame.spellID:Tooltip("")
		end

		if SetupFrameData.diff then
			SetupFrame.diffList:SetText(SetupFrameData.diff)
		else
			SetupFrame.diffList:SetText(LR.All)
		end
		for i=1,#diffsList do
			if diffsList[i][1] == SetupFrameData.diff then
				SetupFrame.diffList:SetText(diffsList[i][2] or SetupFrameData.diff)
				break
			end
		end

		SetupFrame.castList:SetText(SetupFrameData.cast or LR.All)
		for i=1,#castsList do
			if castsList[i][1] == SetupFrameData.cast then
				SetupFrame.castList:SetText(castsList[i][2])
				break
			end
		end

		SetupFrame.conditionList:SetText("|cff808080-|r")
		for i=1,#conditionsList do
			if conditionsList[i][1] == SetupFrameData.condition then
				SetupFrame.conditionList:SetText(conditionsList[i][2])
				break
			end
		end

		SetupFrame.sound:SetText("|cff808080-|r")
        if SetupFrameData.sound then
            local any = false
            for i=1,#soundsList do
                if soundsList[i][1] == SetupFrameData.sound then
                    SetupFrame.sound:SetText(soundsList[i][2])
                    any = true
                    break
                end
            end
            if not any then
                SetupFrame.sound:SetText("..." .. (ExRT.F.utf8sub(SetupFrameData.sound, -33, -5)))
            end
        end

		SetupFrame.voiceCountdown:SetText("|cff808080-|r")
		if SetupFrameData.voiceCountdown then
			local countdowns = module.datas.vcountdowns
			for i=1,#countdowns do
				if countdowns[i][1] == SetupFrameData.voiceCountdown then
					SetupFrame.voiceCountdown:SetText(countdowns[i][2])
					break
				end
			end
		end

		SetupFrame.spamChannel:SetText("|cff808080-|r")
		for i=1,#spamChannels do
			if spamChannels[i][1] == SetupFrameData.spamChannel then
				SetupFrame.spamChannel:SetText(spamChannels[i][2])
				break
			end
		end
		SetupFrame.spamType:SetText("|cff808080-|r")
		for i=1,#spamTypes do
			if spamTypes[i][1] == SetupFrameData.spamType then
				SetupFrame.spamType:SetText(spamTypes[i][2])
				break
			end
		end
		for i=1,#SetupFrame.addOptionsList.List do
			SetupFrame.addOptionsList.List[i].checkState = SetupFrameData[SetupFrame.addOptionsList.List[i].arg1]
		end
		SetupFrame.addOptionsList:SetText((SetupFrameData.copy and "DUPL " or "") .. (SetupFrameData.norewrite and "NR " or "") .. (SetupFrameData.dynamicdisable and "ND " or "") .. (SetupFrameData.isPersonal and "P " or ""))

		SetupFrame.nameplateText:SetText(SetupFrameData.nameplateText or "")
		SetupFrame.nameplateGlow:SetChecked(SetupFrameData.nameplateGlow)
		SetupFrame.glowThick:SetText(SetupFrameData.glowThick or "")
		SetupFrame.glowScale:SetText(SetupFrameData.glowScale or "")
		SetupFrame.glowN:SetText(SetupFrameData.glowN or "")
		SetupFrame.glowOnlyText:SetChecked(SetupFrameData.glowOnlyText)

		for i=1,#module.datas.glowImages do
			if module.datas.glowImages[i][1] == SetupFrameData.glowImage then
				SetupFrame.glowImage:SetText(module.datas.glowImages[i][2])
				break
			end
		end

		for i=1,#module.datas.glowTypes do
			if module.datas.glowTypes[i][1] == SetupFrameData.glowType then
				SetupFrame.glowType:SetText(module.datas.glowTypes[i][2])
				break
			end
		end
		SetupFrame.UseCustomGlowColor:SetChecked(SetupFrameData.UseCustomGlowColor)
		if not SetupFrameData.glowColor and not SetupFrame.UseCustomGlowColor:GetChecked() then
			SetupFrame.glowColor:Hide()
			SetupFrameData.glowColor = nil
			SetupFrameData.UseCustomGlowColor = nil
		elseif SetupFrameData.nameplateGlow then
			SetupFrameData.UseCustomGlowColor = true
			SetupFrame.UseCustomGlowColor:SetChecked(true)
			if not SetupFrameData.glowColor then
				SetupFrameData.glowColor = "0000FFFF"
			end
			local r, g, b = tonumber('0x'..strsub(SetupFrameData.glowColor, 3, 4)), tonumber('0x'..strsub(SetupFrameData.glowColor, 5, 6)), tonumber('0x'..strsub(SetupFrameData.glowColor, 7, 8))
			SetupFrame.glowColor.color:SetColorTexture(r/255, g/255, b/255, 1)
			SetupFrame.glowColor:Show()
		end

		if SetupFrameData.nameplateGlow then
			SetupFrame.glowOnlyText:Show()
			SetupFrame.nameplateText:Show()
			SetupFrame.UseCustomGlowColor:Show()
			SetupFrame.glowType:Show()

			if SetupFrameData.glowType == 1 then --pixel glow
				SetupFrame.glowThick:Show()
				SetupFrame.glowN:Show()
			elseif SetupFrameData.glowType == 2 then --action button glow
				SetupFrame.glowImage:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			elseif SetupFrameData.glowType == 3 then --autocast shine
				SetupFrame.glowScale:Show()

				SetupFrame.glowImage:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			elseif SetupFrameData.glowType == 4 then --proc glow
				SetupFrame.glowImage:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			elseif SetupFrameData.glowType == 5 then --aim
				SetupFrame.glowThick:Show()

				SetupFrame.glowImage:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			elseif SetupFrameData.glowType == 6 then --solid color
				SetupFrame.glowImage:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowN:Hide()
				SetupFrame.glowImageCustom:Hide()
			elseif SetupFrameData.glowType == 7 then --custom icon
				SetupFrame.glowImage:Show()
				SetupFrame.glowScale:Show()

				SetupFrame.glowThick:Hide()
				SetupFrame.glowN:Hide()
				if SetupFrameData.glowImage == 0 or type(SetupFrameData.glowImage) == 'string' then
					SetupFrame.glowImageCustom:Show()
                    if SetupFrameData.glowImage == 0 then
                        SetupFrame.glowImage:SetText(LR.Manually)
                        SetupFrame.glowImageCustom:SetText("")
                    else
                        SetupFrame.glowImage:SetText(LR.Manually)
                        SetupFrame.glowImageCustom:SetText(SetupFrameData.glowImage)
                    end
				else
					SetupFrame.glowImageCustom:Hide()
				end
			elseif SetupFrameData.glowType == 8 then --% hp
				SetupFrame.glowN:Show()

				SetupFrame.glowImage:Hide()
				SetupFrame.glowThick:Hide()
				SetupFrame.glowScale:Hide()
				SetupFrame.glowImageCustom:Hide()
			end
		else
			SetupFrame.glowType:Hide()
			SetupFrame.glowImage:Hide()
			SetupFrame.glowOnlyText:Hide()
			SetupFrame.nameplateText:Hide()
			SetupFrame.glowThick:Hide()
			SetupFrame.glowScale:Hide()
			SetupFrame.glowN:Hide()
			SetupFrame.glowImageCustom:Hide()
			SetupFrame.UseCustomGlowColor:Hide()
		end


		SetupFrame.spellID:SetText(SetupFrameData.spellID or "")
		SetupFrame.delay:SetText(SetupFrameData.delay or "")
		SetupFrame.duration:SetText(SetupFrameData.duration or "")
		SetupFrame.msg:SetText(SetupFrameData.msg or "")
		SetupFrame.extraCheck:SetText(SetupFrameData.extraCheck or "")
		SetupFrame.specialTarget:SetText(SetupFrameData.specialTarget or "")
		SetupFrame.tts:SetText(SetupFrameData.tts or "")
		SetupFrame.glow:SetText(SetupFrameData.glow or "")
		SetupFrame.name:SetText(SetupFrameData.name or "")
		SetupFrame.BossListRaw:SetText(SetupFrameData.boss or "")
		SetupFrame.zoneRaw:SetText(SetupFrameData.zoneID or "")
		SetupFrame.DiffListRaw:SetText(SetupFrameData.diff or "")
		SetupFrame.rawCastEdit:SetText(SetupFrameData.cast or "")
		SetupFrame.spamMsg:SetText(SetupFrameData.spamMsg or "")


		SetupFrame.countdownCheck:SetChecked(SetupFrameData.countdown)
		SetupFrame.useGlobalCounterCheck:SetChecked(SetupFrameData.globalCounter)
		SetupFrame.sendEventCheck:SetChecked(SetupFrameData.sendEvent)
		SetupFrame.doNotLoadOnBosses:SetChecked(SetupFrameData.doNotLoadOnBosses)

		SideColors()

		for i=4,9 do
			playersChecks[i].c = 0
		end

		local allUnits = {strsplit("#",SetupFrameData.units or "")}
		RemoveFromList(allUnits,"")
		sort(allUnits)

		for _, name, subgroup, class in ExRT.F.IterateRoster, 6 do
			playersChecks[subgroup+3].c = playersChecks[subgroup+3].c + 1
			local cFrame = playersChecks[subgroup+3][ playersChecks[subgroup+3].c ]

			name = ExRT.F.delUnitNameServer(name)

			cFrame:SetText("|c"..ExRT.F.classColor(class)..name)
			local isChecked = SetupFrameData.units and SetupFrameData.units:find("#"..name.."#")
			cFrame:SetChecked(isChecked)

			RemoveFromList(allUnits,name)

			cFrame.name = name
			cFrame:Show()
		end

		SetupFrame.otherUnitsEdit:SetText(strjoin(" ",unpack(allUnits)))

		for i=4,9 do
			for j=playersChecks[i].c+1,5 do
				local cFrame = playersChecks[i][j]
				cFrame.name = nil
				cFrame:Hide()
			end
		end

		for i=1,#rolesList do
			local cFrame = playersChecks[10][i]

			local isChecked = SetupFrameData.roles and SetupFrameData.roles:find("#"..cFrame.token.."#")
			cFrame:SetChecked(isChecked)
		end

		for i=1,3 do
			for j=1,5 do
				if classesList[((i-1)*5+j)] and classesList[((i-1)*5+j)][1] then
					local cFrame = playersChecks[i][j]

					local isChecked = SetupFrameData.classes and SetupFrameData.classes:find("#"..cFrame.token.."#")
					cFrame:SetChecked(isChecked)
				else
					break
				end
			end
		end

		playersChecks[11]:SetChecked(not SetupFrameData.units and not SetupFrameData.roles and not SetupFrameData.classes)
		playersChecks[12]:SetChecked(SetupFrameData.reversed)
		if not SetupFrameData.units then
			playersChecks[12]:Disable()
			playersChecks[12]:SetChecked(false)
		else
			playersChecks[12]:Enable()
			playersChecks[12]:SetChecked(SetupFrameData.reversed)
		end

		SetupFrame.notePatternEdit:SetText(SetupFrameData.notepat or "")
		if SetupFrameData.notepat then
			local isOkay,list = pcall(module.FindPlayersListInNote,nil,SetupFrameData.notepat)
			if isOkay and list then
				list = list:gsub("([%S]+)",function(name)
					if not UnitName(name) then
						return "|cffaaaaaa"..name.."|r"
					end
				end)
			end
			SetupFrame.notePatternCurr:SetText(isOkay and list or "---")
		else
			SetupFrame.notePatternCurr:SetText("")
		end

		if SetupFrameData.sendEvent then
			SetupFrame.duration:Hide()
			SetupFrame.countdownCheck:Hide()
		else
			SetupFrame.duration:Show()
			SetupFrame.countdownCheck:Show()
		end

		UpdateAlerts()
		SetupFrame.replaceDropDownUpdate()

		UpdateHistory(lastHistory)
	end

	local function DeleteData(self) --self
		local parent = self:GetParent()
		if not parent.data and not self.data then
			return
		end
		local data = parent.data and parent.data.data or self.data and self.data.data
		if not IsShiftKeyDown() then
			StaticPopupDialogs["EXRT_REMINDER_DELETE_CURRENT"] = {
				text = LR.Listdelete.."?",
				button1 = LR.Listdelete,
				button2 = L.NoText,
				OnAccept = function()
					local token = data.token
					VExRT.Reminder.data[ token ] = nil
					ExRT.F.SendExMsg("reminder","R\t"..token)
					module.options:UpdateData()
					module:ReloadAll()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("EXRT_REMINDER_DELETE_CURRENT")
		else
			local token = data.token

			ExRT.F.SendExMsg("reminder","R\t"..token)

			print("|cffff8000[Reminder]|r Reminder added to 'remove list'")
			local data = VExRT.Reminder.data[ token ]
			VExRT.Reminder.removed[ token ] = {
				time = time(),
				boss = data.boss,
				name = data.name,
				type = type,
				token = token,
			}
			VExRT.Reminder.data[ token ] = nil
			module.options:UpdateData()
			module.options:UpdateBinData()
			module:ReloadAll()
		end
	end

	local function EditData(data)
		if not data then
			return
		end
		SetupFrameData = ExRT.F.table_copy2(data)
		SetupFrame:Show()
		module:SetupFrameUpdate(true)
	end

	local function SendData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end
		module:SyncCurrent(false, parent.data.data, true)
	end

	local function SendFullBossData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end

		local bossID = parent.data.bossID or parent.data.otherID == 0 and -1
		local zoneID = parent.data.zoneID

		module:Sync(false, bossID, zoneID)
	end

	local function ExportFullBossData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end
		local bossID = parent.data.bossID or parent.data.otherID == 0 and -1
		local zoneID = parent.data.zoneID


		local export = module:Sync(true, bossID, zoneID)
		ExRT.F:Export(export)
	end

	local exportWindow
	local function exportWindowOnEscapePressed(self)
		local parent = self:GetParent():GetParent():GetParent()
		parent:Hide()
	end
	local function ExportData(self)
		local parent = self:GetParent()
		if not parent.data then
			return
		end


		if not isExportOpen then
			exportWindow = ELib:Popup(LR["Export"]):Size(650,615)
			exportWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			exportWindow:SetClampedToScreen(false)

			isExportOpen = true
			exportWindow.Edit = ELib:MultiEdit(exportWindow):Point("TOP",0,-20):Size(640,575)
			exportWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			exportWindow.TextInfo = ELib:Text(exportWindow,LR.SingularExportTip,12):Color():Point("BOTTOM",0,3):Size(640,15):Bottom():Left()
			exportWindow:SetScript("OnHide",function(self)
				self.Edit:SetText("")
				isExportOpen = false
			end)
			exportWindow.Next = ExRT.lib:Button(exportWindow,">>>"):Size(100,16):Point("BOTTOMRIGHT",0,0):OnClick(function (self)
				self.now = self.now + 1
				self:SetText(">>> "..self.now.."/"..#exportWindow.hugeText)
				exportWindow.Edit:SetText(exportWindow.hugeText[self.now])
				exportWindow.Edit.EditBox:HighlightText()
				exportWindow.Edit.EditBox:SetFocus()
				if self.now == #exportWindow.hugeText then
					self:Hide()
				end
			end)
            local stringData = module:SyncCurrent(true, parent.data.data, true)
			exportWindow.title:SetText(ExRT.LR.Export)
			exportWindow:NewPoint("CENTER",UIParent,0,0)
			exportWindow:Show()

			exportWindow.hugeText = nil
			exportWindow.Next:Hide()
			exportWindow.Edit:SetText(stringData)
			exportWindow.Edit.EditBox:HighlightText()
			exportWindow.Edit.EditBox:SetFocus()
			exportWindow.Edit.EditBox:SetScript("OnEscapePressed",exportWindowOnEscapePressed)
		elseif (exportWindow.Edit:GetText():find("^" .. SENDER_VERSION .. "%^" .. DATA_VERSION .. "\n")) then -- if export window is open and contains senderVer^dataVer
            local stringData = module:SyncCurrent(true, parent.data.data)
			exportWindow.Edit:SetText(exportWindow.Edit:GetText() .. "\n" .. stringData)
        else -- cant find senderVer^dataVer, starting export from start
            local stringData = module:SyncCurrent(true, parent.data.data, true)
			exportWindow.Edit:SetText(stringData)
		end
		exportWindow:ClearAllPoints()
		exportWindow:Point("LEFT",module.options.scrollList,"RIGHT",0,0)

	end

	local function DuplicateData(data)
		local token = time() + GetTime() % 1
		VExRT.Reminder.data[ token ] = ExRT.F.table_copy2(data)
		VExRT.Reminder.data[ token ].token = token
		VExRT.Reminder.data[ token ].notSync = 2

		module.options:UpdateData()

		module:ReloadAll()
	end

	self.scrollList = ELib:ScrollButtonsList(self.tab.tabs[1]):Point("TOPLEFT",0,-2):Size(760,528)
	self.scrollList.ButtonsInLine = 0.986
	self.scrollList.mouseWheelRange = 50
	ELib:Border(self.scrollList,0)

	local AddButton = ELib:mStyledButton(self.tab.tabs[1],LR.Add,13):Point("TOPLEFT",self.scrollList,"BOTTOMLEFT",4,-5):Size(100,20):OnClick(function()
		SetupFrameData = {event="ADVANCED"}
		SetupFrame:Show()
		module:SetupFrameUpdate(true)
	end)

	self.lastUpdate = ELib:Text(self.tab.tabs[1],"",11):Point("LEFT",AddButton,"RIGHT",10,0):Color()
	self.lastUpdate.Update = function()
		if VExRT.Reminder.LastUpdateName and VExRT.Reminder.LastUpdateTime then
			self.lastUpdate:SetText( L.NoteLastUpdate..": "..VExRT.Reminder.LastUpdateName.." ("..date("%H:%M:%S %d.%m.%Y",VExRT.Reminder.LastUpdateTime)..")" )
		end
	end
	self.lastUpdate:Update()

	self.SyncButton = ELib:mStyledButton(self.tab.tabs[1],LR.SendAll,13):Point("TOPLEFT",AddButton,"BOTTOMLEFT",0,-5):Size(100,20):OnClick(function()
		module:Sync()
	end)

	self.ResetForAllButton = ELib:mStyledButton(self.tab.tabs[1],LR.DeleteAll,13):Point("TOPRIGHT",self.scrollList,"BOTTOMRIGHT",-5,-30):Size(120,20):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_DELETE_ALL_ALERT"] = {
			text = LR.DeleteAll.."?",
			button1 = L.YesText,
			button2 = L.NoText,
			OnAccept = function()
				wipe(VExRT.Reminder.data)
				module.options:UpdateData()
				module:ReloadAll()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_DELETE_ALL_ALERT")

	end)

	self.ExportButton = ELib:mStyledButton(self.tab.tabs[1],LR.ExportAll,13):Point("RIGHT",self.ResetForAllButton,"LEFT",-5,0):Size(120,20):OnClick(function()
		local export = module:Sync(true)
		ExRT.F:Export(export)
	end)

	local importWindow
	self.ImportButton = ELib:mStyledButton(self.tab.tabs[1],LR.Import,13):Point("RIGHT",self.ExportButton,"LEFT",-5,0):Size(80,20):OnClick(function()
		if not importWindow then
			importWindow = ELib:Popup(LR.Import):Size(650,615)
			importWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
			importWindow.Edit = ELib:MultiEdit(importWindow):Point("TOP",0,-20):Size(640,570)
			importWindow.Save = ELib:mStyledButton(importWindow,LR.Import,13):Tooltip(LR.ImportTip):Point("BOTTOM",0,2):Size(120,20):OnClick(function()
				importWindow:Hide()
				if IsShiftKeyDown() then

					StaticPopupDialogs["EXRT_REMINDER_CLEAR_IMPORT_ALERT"] = {
						text = LR.ClearImport,
						button1 = ACCEPT,
						button2 = CANCEL,
						OnAccept = function()
							wipe(VExRT.Reminder.data)
							module:ProcessTextToData(importWindow.Edit:GetText(),true)
						end,
						timeout = 0,
						whileDead = true,
						hideOnEscape = true,
						preferredIndex = 3,
					}
					StaticPopup_Show("EXRT_REMINDER_CLEAR_IMPORT_ALERT")
				else
					module:ProcessTextToData(importWindow.Edit:GetText(),true)
				end
			end)
		end
		importWindow.Edit:SetText("")
		importWindow:NewPoint("CENTER",UIParent,0,0)
		importWindow:Show()
		importWindow.Edit.EditBox:SetScript("OnEscapePressed",exportWindowOnEscapePressed)
		importWindow.Edit.EditBox:SetFocus()
	end)

	local prevIndex
	self.DeleteAllFromRemovedButton = ELib:mStyledButton(self.tab.tabs[1],LR["Delete All Removed"],13):Tooltip(LR["Deletes reminders from 'removed list to all raiders'"]):Point("BOTTOM",self.ResetForAllButton,"TOP",0,5):Size(120,20):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_DELETE_ALL_REMOVED"] = {
			text = LR.ForceRemove,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				if VExRT.Reminder.removed then
					print("|cffff8000[Reminder]|r Deleting all reminders from 'remove list'")

					local r = ""
					local rc = 0
					for token,_ in pairs(VExRT.Reminder.removed) do
						r = r .. token .. "^"
						rc = rc + 1
					end
					r = r:gsub("^$","")
					if rc > 0 then
						local encoded = r .. "##F##"

						print("|cff80ff00|cffff8000[Reminder]|r Deleted token count: " .. rc .. "|r")

						local newIndex
						while prevIndex == newIndex do
							newIndex = math.random(100,999)
						end
						prevIndex = newIndex

						newIndex = tostring(newIndex)
						local parts = ceil(#encoded / 239)
						for i=1,parts do
							local msg = encoded:sub( (i-1)*239+1 , i*239 )
							ExRT.F.SendExMsg("reminder","RA\t"..newIndex.."\t"..msg)
						end
					else
						print("|cffee5555|cffff8000[Reminder]|r Deleted token count: " .. rc .. "|r")
					end

					for token,_ in pairs(VExRT.Reminder.removed) do
						if not VExRT.Reminder.locked[ token ] then
							VExRT.Reminder.data[ token ] = nil
						end
					end

					module.options:UpdateData()
					module:ReloadAll()
				end
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_DELETE_ALL_REMOVED")
	end)

	do
		self.BinFrame = ELib:Template("ExRTDialogModernTemplate",self)

		self.BinFrame.Close.NormalTexture:SetVertexColor(1,0,0,1)
		ELib:Shadow(self.BinFrame,20)
		self.BinFrame:SetSize(690,600)
		self.BinFrame:SetPoint("CENTER")
		self.BinFrame:SetFrameStrata("DIALOG")
		self.BinFrame:EnableMouse(true)

		self.BinFrame.ScrollList = ELib:ScrollButtonsList(self.BinFrame):Point("TOPLEFT",0,-20):Size(690,550)
		self.BinFrame.ScrollList.ButtonsInLine = 3
		self.BinFrame.ScrollList.mouseWheelRange = 50
		ELib:Border(self.BinFrame.ScrollList,0)
		self.BinFrame:Hide()

		local function DeleteFromRemoved(self)
			local parent = self:GetParent()
			local token = parent.uid
			if not token then return end

			print("|cffff8000[Reminder]|r Reminder removed from 'remove list'")
			VExRT.Reminder.removed[ token ] = nil
			module.options:UpdateBinData()
		end

		function self.BinFrame.ScrollList:ButtonClick(button)
			-- local data = self.data
			-- if not data then
			-- return
			-- end
			-- if button == "RightButton" then
			-- if data.data and type(data.data) == 'table' then
			-- local menu = {
			-- { text = data.name or "~no name", isTitle = true, notCheckable = true, notClickable = true },
			-- { text = DELETE, func = function() ELib.ScrollDropDown.Close() DeleteFromRemoved(self) end, notCheckable = true },
			-- { text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
			-- }

			-- local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
			-- cursorPoint:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)

			-- ELib.ScrollDropDown.EasyMenu(cursorPoint,menu,200)
			-- end
			-- return
			-- elseif button == "LeftButton" then
			-- EditData(data.data)
			-- end
		end

		local function ButtonIcon_OnEnter(self)
			if not self["tooltip"..(self.status or 1)] then
				return
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(self["tooltip"..(self.status or 1)])
			GameTooltip:Show()
		end

		local function ButtonIcon_OnLeave(self)
			GameTooltip_Hide()
		end

		local function Button_Create(parent,size)
			if not size then size = 14 end
			local self = ELib:Button(parent,"",1):Size(20,20)
			self.texture = self:CreateTexture(nil,"ARTWORK")
			self.texture:SetPoint("CENTER")
			self.texture:SetSize(size,size)

			self.HighlightTexture = self:CreateTexture(nil,"BACKGROUND")
			self.HighlightTexture:SetColorTexture(1,1,1,.3)
			self.HighlightTexture:SetPoint("TOPLEFT")
			self.HighlightTexture:SetPoint("BOTTOMRIGHT")
			self:SetHighlightTexture(self.HighlightTexture)

			self:SetScript("OnEnter",ButtonIcon_OnEnter)
			self:SetScript("OnLeave",ButtonIcon_OnLeave)

			return self
		end

		local function Button_OnEnter(self)
			if not self["tooltip"] then
				return
			end
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:AddLine(self["tooltip"])
			GameTooltip:Show()
		end
		local function Button_OnLeave(self)
			GameTooltip_Hide()
		end

		local function Button_Lvl1_Remove(self)
			StaticPopupDialogs["EXRT_REMINDER_CLEAR_LVL1_REMOVE"] = {
				text = LR.DeleteSection.."?",
				button1 = L.YesText,
				button2 = L.NoText,
				OnAccept = function()
					for token,data in pairs(VExRT.Reminder.removed) do
						if (type(data) == 'table' and (self.bossID and data.boss == self.bossID)) or
							(type(data) == 'boolean' and self.bossID and self.bossID == 0)
						then
							VExRT.Reminder.removed[ token ] = nil
						end
					end
					module.options:UpdateBinData()
					module.options:UpdateData()
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("EXRT_REMINDER_CLEAR_LVL1_REMOVE")
		end

		local function Button_Lvl2_SetTypeIcon(self,iconType)
			self.text:Hide()
			self.glow:Hide()
			self.glow2:Hide()
			self.bar:Hide()

			if iconType == 1 then
				self.text:FontSize(12)
				self.text:SetText("T")
				self.text:Show()
			elseif iconType == 2 then
				self.text:FontSize(18)
				self.text:SetText("T")
				self.text:Show()
			elseif iconType == 3 then
				self.text:FontSize(8)
				self.text:SetText("t")
				self.text:Show()
			elseif iconType == 4 then
				self.glow:Show()
			elseif iconType == 5 then
				self.glow2:Show()
			elseif iconType == 6 then
				self.text:FontSize(8)
				self.text:SetText("/say")
				self.text:Show()
			elseif iconType == 7 then
				self.text:FontSize(10)
				self.text:SetText("WA")
				self.text:Show()
			elseif iconType == 8 then
				self.bar:Show()
			end
		end

		function self.BinFrame.ScrollList:ModButton(button,level)
			if level == 1 then
				local textObj = button:GetTextObj()
				textObj:SetPoint("LEFT",5+30+3,0)

				button.bossImg = button:CreateTexture(nil, "ARTWORK")
				button.bossImg:SetSize(28,28)
				button.bossImg:SetPoint("LEFT",5,0)

				button.remove = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-30,0)
				button.remove:SetScript("OnClick",Button_Lvl1_Remove)
				button.remove.tooltip1 = LR.ReminderRemoveSection
				button.remove.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")

				button.Texture:SetGradient("VERTICAL",CreateColor(.13,.13,.13,1), CreateColor(.16,.16,.16,1))
			elseif level == 2 then
				local textObj = button:GetTextObj()
				textObj:SetPoint("LEFT",button,"LEFT",25,0)
				textObj:SetPoint("RIGHT",button,"LEFT",190,0)

				button.typeicon = CreateFrame("Frame",nil,button)
				button.typeicon:SetPoint("LEFT",button,"LEFT",5,0)
				button.typeicon:SetSize(20,20)
				button.typeicon.text = ELib:Text(button.typeicon,"T"):Point("CENTER"):Color()
				button.typeicon.glow = ELib:Texture(button.typeicon,[[Interface\SpellActivationOverlay\IconAlert]]):Point("CENTER",-1,0):Size(18,18):TexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
				button.typeicon.glow:SetDesaturated(true)
				button.typeicon.glow2 = CreateFrame("Frame",nil,button.typeicon)
				button.typeicon.glow2:SetSize(18,18)
				button.typeicon.glow2:SetPoint("CENTER")
				button.typeicon.glow2.t1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(5,2)
				button.typeicon.glow2.t2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(5,2)
				button.typeicon.glow2.l1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(2,5)
				button.typeicon.glow2.l2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(2,5)
				button.typeicon.glow2.r1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(2,5)
				button.typeicon.glow2.r2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(2,5)
				button.typeicon.glow2.b1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(5,2)
				button.typeicon.glow2.b2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(5,2)
				button.typeicon.bar = ELib:Texture(button.typeicon,1,1,1,1):Point("CENTER",-1,0):Size(18,4)
				button.typeicon.SetType = Button_Lvl2_SetTypeIcon
				button.typeicon:SetType()

				button.delete = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-5,0)
				button.delete:SetScript("OnClick",DeleteFromRemoved)
				button.delete.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")

				button:SetScript("OnEnter",Button_OnEnter)
				button:SetScript("OnLeave",Button_OnLeave)

				button:RegisterForClicks("LeftButtonUp","RightButtonUp")
			end
		end
		function self.BinFrame.ScrollList:ModButtonUpdate(button,level)
			if level == 1 then
				local data = button.data
				if data.bossID then
                    if ExRT.is11 then
                        if ExRT.GDB.encounterIDtoEJ[data.bossID] then
                            local displayInfo = select(4, EJ_GetCreatureInfo(1, ExRT.GDB.encounterIDtoEJ[data.bossID]))
                            if displayInfo then
                                SetPortraitTextureFromCreatureDisplayID(button.bossImg, displayInfo)
                            else
                                SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
                            end
                        elseif DFDencounterIDtoEJ[data.bossID] then
                            local displayInfo = select(4, EJ_GetCreatureInfo(1, DFDencounterIDtoEJ[data.bossID]))
                            if displayInfo then
                                SetPortraitTextureFromCreatureDisplayID(button.bossImg, displayInfo)
                            else
                                SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
                            end
                        else
                            SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
                        end
                    else
                        local _, dispayInfo = NameByID(data.bossID)
                        SetPortraitTextureFromCreatureDisplayID(button.bossImg, dispayInfo)
                    end
                elseif data.zoneID then
                    SetPortraitTextureFromCreatureDisplayID(button.bossImg, 51173)
                else
                    SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
                end

				if data.bossID or data.zoneID then
					button.remove.bossID = data.bossID
					button.remove.zoneID = data.zoneID
					button.remove:Show()
				else
					button.remove:Hide()
				end
			elseif level == 2 then
				button:GetTextObj():SetWordWrap(false)

				local data = button.data

				if data.nohud and not button.ishudhidden then
					button.ishudhidden = true
				elseif not data.nohud and button.ishudhidden then
					button.ishudhidden = false
				end

				if data.data and type(data.data) == 'table' then
					local data = data.data
					button.tooltip = data.time and "DELETED ("..date("%H:%M:%S %d.%m.%Y",data.time)..")"

					if data.type == "WA" then --WA
						button.typeicon:SetType(7)
					elseif data.type == "FRAMEGLOW" then  --RAIDFRAME
						button.typeicon:SetType(4)
					elseif data.type == "/say" then --CHAT
						button.typeicon:SetType(6)
					else                  -- NORMAL TEXT
						button.typeicon:SetType(1)
					end
				else
					button.typeicon:SetType()
				end
			end
		end

		function self:UpdateBinData()
			local currZoneID = select(8,GetInstanceInfo())

			local Mdata = {}
			for token,data in pairs(VExRT.Reminder.removed) do
				local tableToAdd
				local bossID, zoneID

				if type(data) == 'table' then
					bossID = data.boss
					zoneID = data.zoneID
				else
					bossID = 0
				end
				if zoneID then
					zoneID = tonumber(tostring(zoneID):match("^[^, ]+") or "",10)
				end

				if bossID then
					local bossData = ExRT.F.table_find3(Mdata,bossID,"bossID")
					if not bossData then
						local instanceName
						for i=1,#encountersList do
							local instance = encountersList[i]
							for j=2,#instance do
								if instance[j] == bossID then
									instanceName = GetMapNameByID(instance[1]) or ""
									break
								end
							end
							if instanceName then
								break
							end
						end
						local encounterName
						if ExRT.is11 then
							encounterName = L.bossName[ bossID ] ~= "" and L.bossName[ bossID ] or VExRT.Encounter.names[bossID] or (bossID and "Encounter ID: "..bossID) or LR.Always
						else
							encounterName = NameByID(bossID) or VExRT.Encounter.names[bossID] or (bossID and "Encounter ID: "..bossID) or LR.Always
						end
						if encounterName == "" then
							encounterName = nil
						end
						bossData = {
							bossID = bossID,
							name = (false and instanceName and instanceName ~= "" and instanceName..": " or "")..(encounterName or L.ReminderEncounterID.." "..bossID)..(bossID == module.db.lastEncounterID and " |cff00ff00("..LR.LastPull..")|r" or ""),
							data = {},
							uid = "boss"..bossID,
						}
						Mdata[#Mdata+1] = bossData
					end
					tableToAdd = bossData.data
				elseif zoneID then
					local zoneData = ExRT.F.table_find3(Mdata,zoneID,"zoneID")
					if not zoneData then
						zoneData = {
							zoneID = zoneID,
							name = LR.ZoneID.." "..zoneID..(VExRT.Reminder.zoneNames[zoneID] and ": "..VExRT.Reminder.zoneNames[zoneID] or "")..(currZoneID == zoneID and " |cff00ff00("..LR.Now..")|r" or ""),
							data = {},
							uid = "zone"..zoneID,
						}
						Mdata[#Mdata+1] = zoneData
					end
					tableToAdd = zoneData.data
				else
					local otherData = ExRT.F.table_find3(Mdata,0,"otherID")
					if not otherData then
						otherData = {
							otherID = 0,
							name = LR.Always,
							data = {},
							uid = "other0",
						}
						Mdata[#Mdata+1] = otherData
					end
					tableToAdd = otherData.data
				end

				tableToAdd[#tableToAdd+1] = {
					name = type(data) == 'table' and data.name or "~"..LR.NoName,
					uid = token,
					data = data,
				}
			end
			sort(Mdata,function(a,b)
				if a.bossID and b.bossID then
					return GetEncounterSortIndex(a.bossID,100000-a.bossID) < GetEncounterSortIndex(b.bossID,100000-b.bossID)
				elseif a.zoneID and b.zoneID then
					return a.zoneID > b.zoneID
				elseif a.otherID then
					return false
				elseif b.otherID then
					return true
				elseif a.bossID then
					return true
				elseif b.bossID then
					return false
				end
				return true
			end)

			for i=1,#Mdata do
				local t = Mdata[i].data
				sort(t,function(a,b)
					if a.name:lower() ~= b.name:lower() then
						return a.name:lower() < b.name:lower()
					else
						return a.uid < b.uid
					end
				end)
			end

			module.options.BinFrame.ScrollList.data = Mdata
			module.options.BinFrame.ScrollList:Update(true)
		end

		module.options:UpdateBinData()
	end

	self.ShowRemovedButton = ELib:mStyledButton(self.tab.tabs[1],LR["Show Removed"],13):Point("BOTTOM",self.ExportButton,"TOP",0,5):Size(120,20):OnClick(function()
		self.BinFrame:Show()
	end)

	ELib:DecorationLine(self.BinFrame):Point("TOPLEFT",self.BinFrame,"BOTTOMLEFT",0,30):Point("BOTTOMRIGHT",self.BinFrame,"BOTTOMRIGHT",0,29)

	self.ClearRemovedButton = ELib:mStyledButton(self.BinFrame,LR["Clear Removed"],13):Point("BOTTOMRIGHT",self.BinFrame,"BOTTOMRIGHT",-5,5):Size(120,20):OnClick(function()
		StaticPopupDialogs["EXRT_REMINDER_CLEAR_REMOVED"] = {
			text = LR.ClearRemove,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				wipe(VExRT.Reminder.removed)
				print("|cffff8000[Reminder]|r Cleared 'remove list'")
				module.options:UpdateBinData()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_CLEAR_REMOVED")
	end)

	local LastSyncWindow = ELib:Template("ExRTDialogModernTemplate",self)
	LastSyncWindow.Close.NormalTexture:SetVertexColor(1,0,0,1)
	LastSyncWindow:SetSize(940,135)
	LastSyncWindow:Hide()
	LastSyncWindow:SetPoint("CENTER")
	LastSyncWindow:SetFrameStrata("DIALOG")
	LastSyncWindow:SetDontSavePosition(true)
	LastSyncWindow:SetMovable(true)
	LastSyncWindow:EnableMouse(true)
	LastSyncWindow:RegisterForDrag("LeftButton")
	LastSyncWindow:SetScript("OnDragStart", function(self)
		LastSyncWindow:StartMoving()
	end)
	LastSyncWindow:SetScript("OnDragStop", function(self)
		LastSyncWindow:StopMovingOrSizing()
	end)
	ELib:Border(LastSyncWindow,1,.24,.25,.30,1)

	local function LineName_Icon_OnEnter(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Show(self,nil,self.HOVER_TEXT)
		end
	end
	local function LineName_Icon_OnLeave(self)
		if self.HOVER_TEXT then
			ELib.Tooltip.Hide()
		end
	end

	function LastSyncWindow.SetIcon(self,type) -- 1 = x 2 = v 3 = lock 4 = ...
		if not type or type == 0 then
			self:SetAlpha(0)
		elseif type == 1 then
			self:SetTexCoord(0.5,0.5625,0.5,0.625)
			self:SetVertexColor(.8,0,0,1)
		elseif type == 2 then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(0,.8,0,1)
		elseif type == 3 then
			self:SetTexCoord(0.625,0.6875,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == 4 then
			self:SetTexCoord(0.875,0.9375,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		elseif type == "OUTDATED" then
			self:SetTexCoord(0.5625,0.625,0.5,0.625)
			self:SetVertexColor(.8,.8,0,1)
		end
	end

	local function RaidNames_OnEnter(self)
		local t = self.t:GetText()
		if t ~= "" then
			ELib.Tooltip.Show(self,"ANCHOR_LEFT",t)
		end
	end

	local raidNames = CreateFrame("Frame",nil,LastSyncWindow)
	local VERTICALNAME_COUNT = 30
	local LINE_NAME_WIDTH = 15
	local VERTICALNAME_WIDTH = 30
	local PAGE_HEIGHT = 35
	for i=1,VERTICALNAME_COUNT do
		raidNames[i] = ELib:Text(raidNames,"RaidName"..i,10):Point("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + 0 + VERTICALNAME_WIDTH*(i-1),-100):Color(1,1,1)

		local f = CreateFrame("Frame",nil,LastSyncWindow)
		f:SetPoint("BOTTOMLEFT",LastSyncWindow,"TOPLEFT",LINE_NAME_WIDTH + 0 + VERTICALNAME_WIDTH*(i-1),0)
		f:SetSize(VERTICALNAME_WIDTH,80)
		f:SetScript("OnEnter",RaidNames_OnEnter)
		f:SetScript("OnLeave",ELib.Tooltip.Hide)
		f.t = raidNames[i]

		local t = LastSyncWindow:CreateTexture(nil,"BACKGROUND")
		raidNames[i].t = t
		t:SetPoint("TOPLEFT",raidNames[i],"BOTTOMLEFT",0,0)
		t:SetDrawLayer("ARTWORK")
		t:SetSize(VERTICALNAME_WIDTH,PAGE_HEIGHT)
		if i%2==1 then
			t:SetColorTexture(.5,.5,1,.05)
			t.Vis = true
		end

		local icon = LastSyncWindow:CreateTexture(nil,"ARTWORK")
		raidNames[i].icon = icon
		icon:SetPoint("CENTER",raidNames[i].t,"CENTER",0,0)
		icon:SetSize(20,20)
		icon:SetTexture("Interface\\AddOns\\MRT\\media\\DiesalGUIcons16x256x128")
		LastSyncWindow.SetIcon(icon,0) -- 1 = x 2 = v 3 = lock 4 = ...

		icon.hoverFrame = CreateFrame("Frame",nil,LastSyncWindow)
		icon.hoverFrame:Hide()
		icon.hoverFrame:SetAllPoints(icon)
		icon.hoverFrame:SetScript("OnEnter",LineName_Icon_OnEnter)
		icon.hoverFrame:SetScript("OnLeave",LineName_Icon_OnLeave)
	end
	local group = raidNames:CreateAnimationGroup()
	group:SetScript('OnFinished', function() group:Play() end)
	local rotation = group:CreateAnimation('Rotation')
	rotation:SetDuration(0.000001)
	rotation:SetEndDelay(2147483647)
	rotation:SetOrigin('BOTTOMRIGHT', 0, 0)
	rotation:SetDegrees(60)
	group:Play()

	local function sortByName(a,b)
		if a and b and a.name and b.name then
			return a.name < b.name
		end
	end

	function LastSyncWindow:Update(token)
		local namesList,namesList2 = {},{}
		for _,name,_,class in ExRT.F.IterateRoster do
			namesList[#namesList + 1] = {
				name = name,
				class = class,
			}
		end
		sort(namesList,sortByName)

		local raidNamesUsed = 0
		for i=1,#namesList do
			raidNamesUsed = raidNamesUsed + 1
			if not raidNames[raidNamesUsed] then
				break
			end
			local name = ExRT.F.delUnitNameServer(namesList[i].name)
			raidNames[raidNamesUsed]:SetText(name)
			raidNames[raidNamesUsed]:SetTextColor(ExRT.F.classColorNum(namesList[i].class))
			namesList2[raidNamesUsed] = name
			if raidNames[raidNamesUsed].Vis then
				raidNames[raidNamesUsed]:SetAlpha(.05)
			end
			local data
			for long_name,v in pairs(module.db.responcesData) do -- for name-server, status(time() or string status)
				if long_name:find("^"..name) then
					data = v and v[token] and v[token].date
					break
				end
			end

			if data == "NOLS" then -- no lastSync but reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,3)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "Have reminder but no last sync data provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif data == "NODATA" then -- no reminder
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,1)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No data found"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			elseif tonumber(data) then -- lastSync info
				if VExRT.Reminder.data[token].lastSync <= tonumber(data) then
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,2)
				else
					LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,"OUTDATED")
				end
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = date("%X %x",data)
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			else
				LastSyncWindow.SetIcon(raidNames[raidNamesUsed].icon,4)
				raidNames[raidNamesUsed].icon.hoverFrame.HOVER_TEXT = "No proper response provided"
				raidNames[raidNamesUsed].icon.hoverFrame:Show()
			end
		end

		for i=raidNamesUsed+1,#raidNames do
			raidNames[i]:SetText("")
			raidNames[i].t:SetAlpha(0)
			LastSyncWindow.SetIcon(raidNames[i].icon,0)
			raidNames[i].icon.hoverFrame:Hide()
		end


	end
	LastSyncWindow:Update()

	local function GetLastSync(token)
		wipe(module.db.responcesData)
		ExRT.F.SendExMsg("reminder", "GRV\t"..token)

		LastSyncWindow:Update(token)
		C_Timer.After(1.5,function() LastSyncWindow:Update(token) end)

		LastSyncWindow:Show()
	end

	local cursorPoint = UIParent:CreateTexture()
	cursorPoint.toggleX = 200
	cursorPoint.toggleY = 0
	cursorPoint:SetSize(4,4)

	local function ButtonLevel1Click(self,button) -- level 1 click
		if button == "LeftButton" then
			local parent = self:GetParent():GetParent()
			local uid = self.uid
			parent.stateExpand[uid] = not parent.stateExpand[uid]
			parent:Update()
		elseif button == "RightButton" then
			local data = self.data
			if data.data then
				local menu = {
					{ text = data.name or "~no name", isTitle = true, notCheckable = true, notClickable = true },

					{ text = LR["Export All For This Boss"], func = function() ELib.ScrollDropDown.Close() ExportFullBossData(self.expandSend) end, notCheckable = true },
					{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
				}

				local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
				cursorPoint:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)

				ELib.ScrollDropDown.EasyMenu(cursorPoint, menu, 250)
			end
		end
	end

	function self.scrollList:ButtonClick(button) -- level 2 click
		local data = self.data
		if not data then
			return
		end
		if button == "RightButton" then
			if data.data then
				local menu = {
					{ text = data.name or "~no name", isTitle = true, notCheckable = true, notClickable = true },
					{ text = DELETE, func = function() ELib.ScrollDropDown.Close() DeleteData(self) end, notCheckable = true },
					{ text = LR["Listduplicate"], func = function() ELib.ScrollDropDown.Close() DuplicateData(data.data) end, notCheckable = true },
					{ text = LR["Get last update time"], func = function() ELib.ScrollDropDown.Close() GetLastSync(data.data.token) end, notCheckable = true },
					{ text = CLOSE, func = function() ELib.ScrollDropDown.Close() end, notCheckable = true },
				}

				local uiScale, x, y = UIParent:GetEffectiveScale(), GetCursorPosition()
				cursorPoint:SetPoint("CENTER", nil, "BOTTOMLEFT", x / uiScale, y / uiScale)

				ELib.ScrollDropDown.EasyMenu(cursorPoint,menu,250)
			end
			return
		elseif button == "LeftButton" then
			EditData(data.data)
		end
	end

	local function Button_OnOff_Click(self)
		local status = self.status
		if status == 1 then
			status = 2
		elseif status == 2 then
			status = 1
		end
		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		VExRT.Reminder.disabled[token] = not VExRT.Reminder.disabled[token]

		module:ReloadAll()
	end
	local function Button_OnOff_Update(self,status)
		if status == 1 then
			self.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
		elseif status == 2 then
			self.texture:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
		end
	end

	local function Button_Sound_Click(self)
		local status = self.status
		if status == 1 then
			status = 2
		elseif status == 2 then
			status = 1
		end
		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		VExRT.Reminder.disableSounds[token] = not VExRT.Reminder.disableSounds[token]
	end
	local function Button_Sound_Update(self,status)
		if status == 1 then
			self.line:Hide()
		elseif status == 2 then
			self.line:Show()
		end
	end

	local function Button_Lock_Click(self)
		local status = self.status
		if status == 1 then
			status = 2
		elseif status == 2 then
			status = 1
		end
		self.status = status
		self:Update(status)

		local token = self:GetParent().data.data.token
		VExRT.Reminder.locked[token] = not VExRT.Reminder.locked[token]
	end
	local function Button_Lock_Update(self,status)
		if status == 1 then
			self.texture:SetTexCoord(.6875,.7425,.5,.625)
			self.texture:SetVertexColor(1,1,1,1)
		elseif status == 2 then
			self.texture:SetTexCoord(.625,.68,.5,.625)
			self.texture:SetVertexColor(1,0.82,0,1)
		end
	end

	local function ButtonIcon_OnEnter(self)
		if not self["tooltip"..(self.status or 1)] then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:AddLine(self["tooltip"..(self.status or 1)])
		GameTooltip:Show()
	end

	local function ButtonIcon_OnLeave(self)
		GameTooltip_Hide()
	end

	local function lineStyledButton(parent,text)
		local button = ELib:Button(parent,text)
		button.Texture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button.DisabledTexture:SetGradient("VERTICAL",CreateColor(0.15,0.15,0.15,0), CreateColor(0.15,0.15,0.15,0))
		button:GetFontString():SetFont(tabFont, 12,"")
		button.BorderLeft:Hide()
		button.BorderRight:Hide()
		button.BorderTop:Hide()
		button.BorderBottom:Hide()
		return button
	end

	local function Button_Create(parent,size)
		if not size then size = 14 end
		local self = ELib:Button(parent,"",1):Size(20,20)
		self.texture = self:CreateTexture(nil,"ARTWORK")
		self.texture:SetPoint("CENTER")
		self.texture:SetSize(size,size)

		self.HighlightTexture = self:CreateTexture(nil,"BACKGROUND")
		self.HighlightTexture:SetColorTexture(1,1,1,.3)
		self.HighlightTexture:SetPoint("TOPLEFT")
		self.HighlightTexture:SetPoint("BOTTOMRIGHT")
		self:SetHighlightTexture(self.HighlightTexture)

		self:SetScript("OnEnter",ButtonIcon_OnEnter)
		self:SetScript("OnLeave",ButtonIcon_OnLeave)

		return self
	end

	local function Button_OnLeave(self)
		GameTooltip:SetMinimumWidth(0,false)
		GameTooltip_Hide()
	end

	local function Button_OnEnter(self)
		local data = self.data.data
		local role1, role2 = GetPlayerRole()
		local myClass = select(2, UnitClass 'player')

		local isNoteOn, isInNote, noteLine, isReversed
		if data.notepat then
			isNoteOn = true
			isInNote, noteLine = module:FindPlayerInNote(data.notepat)
			isReversed = data.notepat:find("^%-")
			if not noteLine then
				noteLine = module:FindPlayersListInNote(data.notepat:gsub("^%-", ""))
			else
				noteLine = noteLine:gsub((data.notepat:gsub("^%-", "")) .. " *", ""):gsub("|c........", ""):gsub("|r", "")
					:gsub(" *$", ""):gsub("|", ""):gsub(" +", " ")
			end
		end

		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		-- GameTooltip:SetShrinkToFitWrapped()
		GameTooltip:SetMinimumWidth(200,true)

		GameTooltip:AddLine(LR.Name)
		GameTooltip:AddLine(data.name or ("~"..LR.NoName))

		if data.msg and not data.sendEvent then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(LR.msg)
			local text = module:FormatMsg(data.msg or "")
			GameTooltip:AddLine(text)
		end

		if data.msg and data.sendEvent then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(LR.CustomEvent)
			GameTooltip:AddLine(module:FormatMsg(data.msg or ""))
		end

		if data.spamMsg then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(LR.SpamMessage)
			GameTooltip:AddLine(module:FormatMsg(data.spamMsg or ""))
		end

		if data.glow then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Raidframe glow:")
			GameTooltip:AddLine(data.glow)
		end

		if data.tts then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Text to speech:")
			GameTooltip:AddLine(data.tts)
		end

		if data.nameplateGlow then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine("Nameplate glow:")
			for i = 1, #module.datas.glowTypes do
				if module.datas.glowTypes[i][1] == data.glowType then
					GameTooltip:AddLine(module.datas.glowTypes[i][2])
					break
				end
			end
			if data.nameplateText then
				GameTooltip:AddLine("Text: " .. (module:FormatMsg(data.nameplateText)))
			end
		end

		if data.notepat then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(isReversed and "Load by note pattern(reversed):" or "Load by note pattern:")
			GameTooltip:AddLine(noteLine and "Note pattern: " .. data.notepat:gsub("^%-", ""))
			GameTooltip:AddLine(noteLine and "|cffee5555" .. (noteLine:gsub(playerName,"|cff55ee55"..playerName.."|r"):gsub("^%s+","") or "") or "|cffee5555Note line for current pattern is not found:\n" .. data.notepat)
		else
			local playersInRaid = {}
			for _, name in ExRT.F.IterateRoster, 6 do
				name = ExRT.F.delUnitNameServer(name)
				playersInRaid[name] = true
			end

			if data.classes then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Load by class:")
				GameTooltip:AddLine("|cffee5555" .. data.classes:gsub("#".. myClass .. "#","#|cff55ee55"..myClass.."|r#"):gsub("#", " "):gsub("^%s+",""))
			end
			if data.roles then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Load by role:")
				GameTooltip:AddLine("|cffee5555" .. data.roles:gsub("#".. role1.."#","#|cff55ee55"..role1.."|r#"):gsub(( role2 and ("#" .. role2 .. "#") or "NIL"),"#|cff55ee55"..(role2 or "role2dummy").."|r#"):gsub("#", " "):gsub("^%s+",""))
			end
			if data.units then
				GameTooltip:AddLine(" ")
				GameTooltip:AddLine("Load by name:")
				local unitsPattern = "|cffee5555" .. (data.units:gsub("#", " "):gsub("^%s+","") or "")

				for name in pairs(playersInRaid) do
					unitsPattern = unitsPattern:gsub(" " .. name .. " "," |cff55ee55"..name.."|r ")
				end
				GameTooltip:AddLine(unitsPattern)
			end
		end
		GameTooltip:Show()
	end

	local function Button_Lvl1_Remove(self)
		StaticPopupDialogs["EXRT_REMINDER_CLEAR_LVL1_REMOVE"] = {
			text = LR.DeleteSection.."?",
			button1 = L.YesText,
			button2 = L.NoText,
			OnAccept = function()
				for token,data in pairs(VExRT.Reminder.data) do
					if
						(
							(self.bossID and data.boss == self.bossID) or
							(self.zoneID and data.zoneID == self.zoneID)
						) and
						not VExRT.Reminder.locked[token]
					then
						local type
						if data.sendEvent then --WA
							type = "WA"
						elseif data.glow and data.glow ~= "" then  --RAIDFRAME
							type = "FRAMEGLOW"
						elseif data.spamMsg then --CHAT
							type = "/say"
						else -- NORMAL TEXT
							type = "T"
						end
						VExRT.Reminder.removed[token] = {
							time = time(),
							boss = data.boss,
							name = data.name,
							type = type,
							token = token,
						}
						VExRT.Reminder.data[token] = nil
					end
				end
				module.options:UpdateData()
				module.options:UpdateBinData()
				module:ReloadAll()
			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("EXRT_REMINDER_CLEAR_LVL1_REMOVE")
	end

	local function Button_Lvl2_SetTypeIcon(self,iconType)
		self.text:Hide()
		self.glow:Hide()
		self.glow2:Hide()
		self.bar:Hide()

		if iconType == 1 then
			self.text:FontSize(12)
			self.text:SetText("T")
			self.text:Show()
		elseif iconType == 2 then
			self.text:FontSize(18)
			self.text:SetText("T")
			self.text:Show()
		elseif iconType == 3 then
			self.text:FontSize(8)
			self.text:SetText("t")
			self.text:Show()
		elseif iconType == 4 then
			self.glow:Show()
		elseif iconType == 5 then
			self.glow2:Show()
		elseif iconType == 6 then
			self.text:FontSize(8)
			self.text:SetText("/say")
			self.text:Show()
		elseif iconType == 7 then
			self.text:FontSize(10)
			self.text:SetText("WA")
			self.text:Show()
		elseif iconType == 8 then
			self.bar:Show()
		end
	end

	local function Button_Lvl2_SetDiffText(self,diff)
		if diff == 15 then
			diff = "H"
		elseif diff == 16 then
			diff = "M"
		elseif diff == 14 then
			diff = "N"
		elseif diff == 175 then
			diff = "10N"
		elseif diff == 176 then
			diff = "25N"
		elseif diff == 193 then
			diff = "10H"
		elseif diff == 194 then
			diff = "25H"
		end
		self.text:SetText(diff)
	end

	function self.scrollList:ModButton(button,level)
		if level == 1 then
			local textObj = button:GetTextObj()
			textObj:SetPoint("LEFT",5+30+3,0)

			button.bossImg = button:CreateTexture(nil, "ARTWORK")
			button.bossImg:SetSize(28,28)
			button.bossImg:SetPoint("LEFT",5,0)

			button.remove = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-30,0)
			button.remove:SetScript("OnClick",Button_Lvl1_Remove)
			button.remove.tooltip1 = LR.ReminderRemoveSection
			button.remove.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")

			button.expandSend = lineStyledButton(button,LR["Send All For This Boss"]):Point("RIGHT",button.remove,"LEFT",-15,0):Size(150,30):OnClick(SendFullBossData)

			button.Texture:SetGradient("VERTICAL",CreateColor(.13,.13,.13,1), CreateColor(.16,.16,.16,1))

			button:OnClick(ButtonLevel1Click)
			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		elseif level == 2 then
			local textObj = button:GetTextObj()
			textObj:SetPoint("LEFT",button,"LEFT",85,0)
			textObj:SetPoint("RIGHT",button,"LEFT",260,0)

			button.msg = ELib:Text(button,"test"):Point("LEFT",textObj,"RIGHT",5,0):Size(235,20)
			textObj:SetFont(button.msg:GetFont())

			button.onoff = Button_Create(button):Point("LEFT",button,"LEFT",0,0)
			button.onoff:SetScript("OnClick",Button_OnOff_Click)
			button.onoff.Update = Button_OnOff_Update
			button.onoff.tooltip1 = LR.ReminderPersonalDisable
			button.onoff.tooltip2 = LR.ReminderPersonalEnable

			button.lock = Button_Create(button):Point("LEFT",button.onoff,"RIGHT",0,0)
			button.lock.texture:SetTexture([[Interface\AddOns\MRT\media\DiesalGUIcons16x256x128.tga]])
			button.lock:SetScript("OnClick",Button_Lock_Click)
			button.lock.Update = Button_Lock_Update
			button.lock.tooltip1 = LR.ReminderUpdatesDisable
			button.lock.tooltip2 = LR.ReminderUpdatesEnable

			button.typeicon = CreateFrame("Frame",nil,button)
			button.typeicon:SetPoint("LEFT",button.lock,"RIGHT",0,0)
			button.typeicon:SetSize(20,20)
			button.typeicon.text = ELib:Text(button.typeicon,"T"):Point("CENTER"):Color()
			button.typeicon.glow = ELib:Texture(button.typeicon,[[Interface\SpellActivationOverlay\IconAlert]]):Point("CENTER",-1,0):Size(18,18):TexCoord(0.00781250, 0.50781250, 0.27734375, 0.52734375)
			button.typeicon.glow:SetDesaturated(true)
			button.typeicon.glow2 = CreateFrame("Frame",nil,button.typeicon)
			button.typeicon.glow2:SetSize(18,18)
			button.typeicon.glow2:SetPoint("CENTER")
			button.typeicon.glow2.t1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(5,2)
			button.typeicon.glow2.t2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(5,2)
			button.typeicon.glow2.l1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPLEFT",button.typeicon.glow2,"CENTER",-7,7):Size(2,5)
			button.typeicon.glow2.l2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(2,5)
			button.typeicon.glow2.r1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("TOPRIGHT",button.typeicon.glow2,"CENTER",7,7):Size(2,5)
			button.typeicon.glow2.r2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(2,5)
			button.typeicon.glow2.b1 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMLEFT",button.typeicon.glow2,"CENTER",-7,-7):Size(5,2)
			button.typeicon.glow2.b2 = ELib:Texture(button.typeicon.glow2,1,1,1,1):Point("BOTTOMRIGHT",button.typeicon.glow2,"CENTER",7,-7):Size(5,2)
			button.typeicon.bar = ELib:Texture(button.typeicon,1,1,1,1):Point("CENTER",-1,0):Size(18,4)
			button.typeicon.SetType = Button_Lvl2_SetTypeIcon
			button.typeicon:SetType()

            button.difftext = CreateFrame("Frame",nil,button)
			button.difftext:SetPoint("LEFT",button.typeicon,"RIGHT",0,0)
			button.difftext:SetSize(20,20)
			button.difftext.text = ELib:Text(button.difftext,"A"):Point("CENTER"):Color()
			button.difftext.SetDiff = Button_Lvl2_SetDiffText
			button.difftext:SetDiff()

			button.delete = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-5,0)
			button.delete:SetScript("OnClick",DeleteData)
			button.delete.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")
			button.delete.tooltip1 = LR.ListdeleteTip

			button.dSend = lineStyledButton(button,LR.ListdSend):Point("RIGHT",button.delete,"LEFT",0,0):Size(80,20):OnClick(SendData)
			button.dExport = lineStyledButton(button,LR.ListdExport):Point("RIGHT",button.dSend,"LEFT",0,0):Size(80,20):OnClick(ExportData)

			button.sound = Button_Create(button):Point("RIGHT",button.dExport,"LEFT",0,0)
			button.sound.texture:SetTexture([[Interface\AddOns\MRT\media\volume.tga]])
			button.sound.line = button.sound:CreateLine(nil,"ARTWORK",nil,2)
			button.sound.line:SetColorTexture(1,0,0,1)
			button.sound.line:SetStartPoint("CENTER",-5,-5)
			button.sound.line:SetEndPoint("CENTER",5,5)
			button.sound.line:SetThickness(2)
			button.sound:SetScript("OnClick",Button_Sound_Click)
			button.sound.Update = Button_Sound_Update
			button.sound.tooltip1 = LR.ReminderSoundDisable
			button.sound.tooltip2 = LR.ReminderSoundEnable

			button:SetScript("OnEnter",Button_OnEnter)
			button:SetScript("OnLeave",Button_OnLeave)

			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		end
	end

	function self.scrollList:ModButtonUpdate(button, level)
		if level == 1 then
			local data = button.data
			if data.bossID then
				if ExRT.is11 then
					if ExRT.GDB.encounterIDtoEJ[data.bossID] then
						local displayInfo = select(4, EJ_GetCreatureInfo(1, ExRT.GDB.encounterIDtoEJ[data.bossID]))
						if displayInfo then
							SetPortraitTextureFromCreatureDisplayID(button.bossImg, displayInfo)
						else
							SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
						end
					elseif DFDencounterIDtoEJ[data.bossID] then
                        local displayInfo = select(4, EJ_GetCreatureInfo(1, DFDencounterIDtoEJ[data.bossID]))
                        if displayInfo then
                            SetPortraitTextureFromCreatureDisplayID(button.bossImg, displayInfo)
                        else
                            SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
                        end
                    else
						SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
					end
				else
					local _, dispayInfo = NameByID(data.bossID)
					SetPortraitTextureFromCreatureDisplayID(button.bossImg, dispayInfo)
				end
			elseif data.zoneID then
				SetPortraitTextureFromCreatureDisplayID(button.bossImg, 51173)
			else
				SetPortraitTextureFromCreatureDisplayID(button.bossImg, 15556)
			end

			if data.bossID or data.zoneID then
				button.remove.bossID = data.bossID
				button.remove.zoneID = data.zoneID
				button.remove:Show()
			else
				button.remove:Hide()
			end
		elseif level == 2 then
			button:GetTextObj():SetWordWrap(false)

			local data = button.data
			local reminderData = data.data
			if reminderData.notSync == 2 then
				button:GetTextObj():SetTextColor(1,0.5,0)
			else
				button:GetTextObj():SetTextColor(1,.82,0)
			end
			button.msg:SetText(reminderData.sendEvent and reminderData.msg and reminderData.msg ~= "" and
				"|cff9370DBWA:|r " .. reminderData.msg .. "|r" or
				reminderData.msg and reminderData.msg ~= "" and module:FormatMsg(reminderData.msg) or
				reminderData.spamMsg and "|cff0088ffCHAT:|r " .. (module:FormatMsg(reminderData.spamMsg)) .. "|r" or
				reminderData.nameplateText and "|cff0088ffNAMEPLATE:|r " .. (module:FormatMsg(reminderData.nameplateText)) or
				"")

			if data.nohud and not button.ishudhidden then
				button.onoff:Hide()
				button.sound:Hide()
				button.lock:Hide()
				button.ishudhidden = true
			elseif not data.nohud and button.ishudhidden then
				button.onoff:Show()
				button.sound:Show()
				button.lock:Show()
				button.ishudhidden = false
			end

			if not VExRT.Reminder.disabled[ reminderData.token ] then
				button.onoff.status = 1
			else
				button.onoff.status = 2
			end
			button.onoff:Update(button.onoff.status)

			if not VExRT.Reminder.disableSounds[ reminderData.token ] then
				button.sound.status = 1
			else
				button.sound.status = 2
			end
			button.sound:Update(button.sound.status)
			if not button.ishudhidden then
				if reminderData and (reminderData.sound or reminderData.tts) then
					button.sound:Show()
				else
					button.sound:Hide()
				end
			end

			if not VExRT.Reminder.locked[ reminderData.token ] then
				button.lock.status = 1
			else
				button.lock.status = 2
			end
			button.lock:Update(button.lock.status)

			if reminderData then
				local data = reminderData
				if data.sendEvent then        --WA
					button.typeicon:SetType(7)
				elseif data.nameplateGlow then --NAMEPLATE
					button.typeicon:SetType(5)
				elseif data.glow and data.glow ~= "" then --RAIDFRAME
					button.typeicon:SetType(4)
				elseif data.spamMsg then      --CHAT
					button.typeicon:SetType(6)
				else                          -- NORMAL TEXT
					button.typeicon:SetType(1)
				end
				local diff = data.diff
				button.difftext:SetDiff(diff or "A")
				-- local rem_type = module:GetReminderType(data.data.msgSize)
				-- if data.data.msgSize == 2 then
				-- button.typeicon:SetType(2)
				-- elseif data.data.msgSize == 3 then
				-- button.typeicon:SetType(3)
				-- elseif rem_type == REM.TYPE_CHAT then
				-- button.typeicon:SetType(6)
				-- elseif rem_type == REM.TYPE_NAMEPLATE then
				-- button.typeicon:SetType(5)
				-- elseif rem_type == REM.TYPE_RAIDFRAME then
				-- button.typeicon:SetType(4)
				-- elseif rem_type == REM.TYPE_WA then
				-- button.typeicon:SetType(7)
				-- elseif rem_type == REM.TYPE_BAR then
				-- button.typeicon:SetType(8)
				-- else
				-- button.typeicon:SetType(1)
				-- end
			else
				button.typeicon:SetType()
				button.difftext:SetDiff("A")
			end

			button.dSend:Enable()
			button.dExport:Enable()

			if data.data.isPersonal then
				button.dSend:Disable()
				button.dExport:Disable()
				button.dSend:SetText(LR.ListdSend)
			elseif data.data.notSync then
				button.dSend:SetText("|cffffffff"..LR.ListdSend.."|r")
				button.dSend:Tooltip("|cffff0000"..LR.ListNotSendedTip .. "|r\nID: ".. data.data.token)
				button.dExport:Tooltip("|cffff0000"..LR.ListNotSendedTip .. "|r\nID: ".. data.data.token)
			else
				button.dSend:SetText(LR.ListdSend)
				button.dSend:Tooltip("ID: ".. data.data.token)
				button.dExport:Tooltip("ID: ".. data.data.token)
			end
            if data.data.disabled then
                button.Texture:SetGradient("HORIZONTAL",CreateColor(.05,.05,.05,.5), CreateColor(.45,.45,.45,.5))
                button.onoff.texture:SetDesaturated(1)
                return
            else
                button.onoff.texture:SetDesaturated()
            end
			if module:CheckPlayerCondition(data.data) then
				if data.data.isPersonal then
					button.Texture:SetGradient("HORIZONTAL",CreateColor(.1,.5,1,.35), CreateColor(.1,.5,1,.6))
				else
					button.Texture:SetGradient("HORIZONTAL",CreateColor(0,.42,0,.35), CreateColor(0.1,.48,0,.55))
				end
			else
				if data.data.isPersonal then
					button.Texture:SetGradient("HORIZONTAL",CreateColor(.7,.45,0,.5), CreateColor(.75,.50,0.1,1))
				else
					button.Texture:SetGradient("HORIZONTAL",CreateColor(.6,0,0,.35), CreateColor(.65,0.1,0.1,.55))
				end
			end
		end
	end

	function self:UpdateData()
		local currZoneID = select(8, GetInstanceInfo())

		local Mdata = {}
		for token,data in pairs(VExRT.Reminder.data) do
			local tableToAdd

			local bossID = data.boss
			local zoneID = data.zoneID

			if zoneID then
				zoneID = tonumber(tostring(zoneID):match("^[^, ]+") or "",10)
			end
			if  (not module.options.search or
					(data.name and data.name:lower():find(module.options.search,1,true)) or
					(data.msg and data.msg:lower():find(module.options.search,1,true)) or
					(data.tts and data.tts:lower():find(module.options.search,1,true)) or
					(data.spamMsg and data.spamMsg:lower():find(module.options.search,1,true)) or
                    (data.nameplateText and data.nameplateText:lower():find(module.options.search,1,true))
                )
                then
				if bossID then
					local bossData = ExRT.F.table_find3(Mdata,bossID,"bossID")
					if not bossData then
						local instanceName
						for i=1,#encountersList do
							local instance = encountersList[i]
							for j=2,#instance do
								if instance[j] == bossID then
									instanceName = GetMapNameByID(instance[1]) or ""
									break
								end
							end
							if instanceName then
								break
							end
						end

						local encounterName
						if ExRT.is11 then
							encounterName = L.bossName[ bossID ] ~= "" and L.bossName[ bossID ] or LR.bossName[ bossID ] ~= "" and LR.bossName[ bossID ] or VExRT.Encounter.names[bossID] or (bossID and "Encounter ID: "..bossID) or LR.Always
						else
							encounterName = NameByID(bossID) or VExRT.Encounter.names[bossID] or (bossID and "Encounter ID: "..bossID) or LR.Always
						end

						if encounterName == "" then
							encounterName = nil
						end
						bossData = {
							bossID = bossID,
							name = (false and instanceName and instanceName ~= "" and instanceName..": " or "")..(encounterName or "")..(bossID == module.db.lastEncounterID and " |cff00ff00("..LR.LastPull..")|r" or ""),
							data = {},
							uid = "boss"..bossID,
						}
						Mdata[#Mdata+1] = bossData
					end
					tableToAdd = bossData.data
				elseif zoneID then
					local zoneData = ExRT.F.table_find3(Mdata,zoneID,"zoneID")
					if not zoneData then
						zoneData = {
							zoneID = zoneID,
							name = LR.ZoneID.." "..zoneID..(VExRT.Reminder.zoneNames[zoneID] and ": "..VExRT.Reminder.zoneNames[zoneID] or "")..(currZoneID == zoneID and " |cff00ff00("..LR.Now..")|r" or ""),
							data = {},
							uid = "zone"..zoneID,
						}
						Mdata[#Mdata+1] = zoneData
					end
					tableToAdd = zoneData.data
				else
					local otherData = ExRT.F.table_find3(Mdata,0,"otherID")
					if not otherData then
						otherData = {
							otherID = 0,
							name = LR.Always,
							data = {},
							uid = "other0",
						}
						Mdata[#Mdata+1] = otherData
					end
					tableToAdd = otherData.data
				end

				tableToAdd[#tableToAdd+1] = {
					name = data.name or ("~"..LR.NoName),
					uid = token,
					data = data,
					isPersonal = data.isPersonal,
					diff = data.diff or 0,
				}
			end
		end
		sort(Mdata,function(a,b)
			if a.bossID and b.bossID then
				return GetEncounterSortIndex(a.bossID,100000-a.bossID) < GetEncounterSortIndex(b.bossID,100000-b.bossID)
			elseif a.zoneID and b.zoneID then
				return a.zoneID > b.zoneID
			elseif a.otherID then
				return false
			elseif b.otherID then
				return true
			elseif a.bossID then
				return true
			elseif b.bossID then
				return false
			end
			return false
		end)
		for i=1,#Mdata do
			local t = Mdata[i].data
			sort(t,function(a,b)
				if a.isPersonal and not b.isPersonal then
					return false
				elseif not a.isPersonal and b.isPersonal then
					return true
				elseif a.diff ~= b.diff then
					return a.diff > b.diff
				elseif a.name:lower() ~= b.name:lower() then
					return a.name:lower() < b.name:lower()
				else
					return a.uid < b.uid
				end
			end)
		end

		module.options.scrollList.data = Mdata
		module.options.scrollList:Update(true)

		if module.options.lastUpdate then
			module.options.lastUpdate:Update()
		end
	end

	self:UpdateData()

	self.chkLock = ELib:Check(self.tab.tabs[2],L.cd2fix,not VExRT.Reminder.lock):Point(10,-10):OnClick(function(self)
		VExRT.Reminder.lock = not self:GetChecked()
		module:UpdateVisual()
	end)

	self.disableSound = ELib:Check(self.tab.tabs[2],LR.DisableSound,VExRT.Reminder.disableSound):Point(10,-35):OnClick(function(self)
		VExRT.Reminder.disableSound = self:GetChecked()
	end)

	self.updatesDebug = ELib:Check(self.tab.tabs[2],"DEBUG UPDATES",VExRT.Reminder.debugUpdates):Point(325,-10):OnClick(function(self)
		VExRT.Reminder.debugUpdates = self:GetChecked()
	end)
	self.disableUpdates = ELib:Check(self.tab.tabs[2],"DISABLE UPDATES",VExRT.Reminder.disableUpdates):Point(325,-35):OnClick(function(self)
		VExRT.Reminder.disableUpdates = self:GetChecked()
	end)
	self.bwDebug = ELib:Check(self.tab.tabs[2],"BIGWIGS DEBUG",VExRT.Reminder.bwDebug):Point(325,-60):OnClick(function(self)
		VExRT.Reminder.bwDebug = self:GetChecked()
	end)

	local debugCheckFrame = CreateFrame("Frame",nil,self.tab.tabs[2])
	debugCheckFrame:SetPoint("TOPLEFT")
	debugCheckFrame:SetSize(1,1)
	debugCheckFrame:SetScript("OnShow",function()
		if IsShiftKeyDown() and IsAltKeyDown() then
			self.updatesDebug:Show()
			self.disableUpdates:Show()
			self.bwDebug:Show()
		else
			self.updatesDebug:Hide()
			self.disableUpdates:Hide()
			self.bwDebug:Hide()
		end
	end)

	self.optionWidgets = mStyledTabs(self.tab.tabs[2],0,"Text","Text To Speech","Raid Frame Glow","Nameplate Glow"):Point(0,-300):Point("LEFT",self.tab.tabs[2]):Size(698,200):SetTo(1)
	self.optionWidgets:SetBackdropBorderColor(0,0,0,0)
	self.optionWidgets:SetBackdropColor(0,0,0,0)
	local OWDecorationLine = ELib:DecorationLine(self.optionWidgets,true,"BACKGROUND",1):Point("TOP",0,20):Point("LEFT",-1,0):Point("RIGHT",62,0):Size(0,20)
	OWDecorationLine:SetGradient("VERTICAL",CreateColor(0.17,0.17,0.17,0.77), CreateColor(0.17,0.17,0.17,0.77))

	local function DropDownFont_Click(_,arg)
		VExRT.Reminder.Font = arg
		local FontNameForDropDown = arg:match("\\([^\\]*)$"):gsub("%....$", "")
		self.dropDownFont:SetText(FontNameForDropDown or arg)
		ELib:DropDownClose()
		module:UpdateVisual()
	end

	self.dropDownFont = ELib:DropDown(self.optionWidgets.tabs[1],250,10):Size(280):Point(100,-15):AddText("|cffffce00"..LR.Font)
	for i=1,#ExRT.F.fontList do
		local info = {}

		info.text = ExRT.F.fontList[i]:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = ExRT.F.fontList[i]
		info.func = DropDownFont_Click
		info.font = ExRT.F.fontList[i]
		info.justifyH = "LEFT"

		self.dropDownFont.List[i] = info
	end
	for name,font in ExRT.F.IterateMediaData("font") do
		local info = {}

		info.text = name--font:match("\\([^\\]*)$"):gsub("%....$", "")
		info.arg1 = font
		info.func = DropDownFont_Click
		info.font = font
		info.justifyH = "LEFT"

		self.dropDownFont.List[#self.dropDownFont.List+1] = info
	end
	do
		local arg = VExRT.Reminder.Font or ExRT.F.defFont
		local FontNameForDropDown = arg:match("\\([^\\]*)$"):gsub("%....$" , "")
		self.dropDownFont:SetText(FontNameForDropDown or arg)
	end

	self.chkShadow = ELib:Check(self.optionWidgets.tabs[1],LR.OutlineChk, VExRT.Reminder.Shadow):Point("LEFT",self.dropDownFont,"RIGHT",10,0):OnClick(function(self)
		VExRT.Reminder.Shadow = self:GetChecked()
		module:UpdateVisual()
	end)

	local function flagListTextUpdate(arg)
		if arg == "update" then
			for i=1,#font_flags do
				if font_flags[i][1] == VExRT.Reminder.OutlineType then
					self.flagList:SetText(font_flags[i][2])
					break
				end
			end
		else
			for i=1,#font_flags do
				if font_flags[i][1] == VExRT.Reminder.OutlineType then
					return font_flags[i][2]
				end
			end
		end
	end

	local function flagList_SetValue(_,flag)
		VExRT.Reminder.OutlineType = flag
		ELib:DropDownClose()
		module:UpdateVisual()
		flagListTextUpdate("update")
	end

	self.flagList = ELib:DropDown(self.optionWidgets.tabs[1],250,6):Size(280):Point(100,-40):SetText(flagListTextUpdate() or LR.OutlinesNormal):AddText("|cffffce00"..LR.Outline)
	do
		local List = self.flagList.List
		for i=1,#font_flags do
			List[#List+1] = {
				text = font_flags[i][2],
				arg1 = font_flags[i][1],
				func = flagList_SetValue,
			}
		end
	end

	self.moreOptionsDropDown = ELib:DropDown(self.optionWidgets.tabs[1],250,#frameStrataList+1):Point(100,-65):Size(280):SetText(VExRT.Reminder.FrameStrata):AddText("|cffffce00"..LR.Strata)

	local function moreOptionsDropDown_SetVaule(_,arg)
		VExRT.Reminder.FrameStrata = arg
		self.moreOptionsDropDown:SetText(VExRT.Reminder.FrameStrata)
		ELib:DropDownClose()
		for i=1,#self.moreOptionsDropDown.List-1 do
			self.moreOptionsDropDown.List[i].checkState = VExRT.Reminder.FrameStrata == self.moreOptionsDropDown.List[i].arg1
		end
		module:UpdateVisual()
	end

	for i=1,#frameStrataList do
		self.moreOptionsDropDown.List[i] = {
			text = frameStrataList[i],
			checkState = VExRT.Reminder.FrameStrata == frameStrataList[i],
			radio = true,
			arg1 = frameStrataList[i],
			func = moreOptionsDropDown_SetVaule,
		}
	end
	tinsert(self.moreOptionsDropDown.List,{text = L.minimapmenuclose, func = function()
			ELib:DropDownClose()
		end})

	local function dropDownFontAdjSetValue(_,arg1)
		ELib:DropDownClose()
		VExRT.Reminder.JustifyH = arg1
		self.dropDownFontAdj:SetText(VExRT.Reminder.JustifyH == 1 and L.cd2ColSetFontPosLeft or VExRT.Reminder.JustifyH == 2 and L.cd2ColSetFontPosRight or L.cd2ColSetFontPosCenter)
		module:UpdateVisual()
	end
	self.dropDownFontAdj = ELib:DropDown(self.optionWidgets.tabs[1],350,-1):Size(280):Point("TOPLEFT",self.moreOptionsDropDown,"BOTTOMLEFT",0,-5):SetText(VExRT.Reminder.JustifyH == 1 and L.cd2ColSetFontPosLeft or VExRT.Reminder.JustifyH == 2 and L.cd2ColSetFontPosRight or L.cd2ColSetFontPosCenter):AddText("|cffffce00"..LR.Justify)
	self.dropDownFontAdj.List[1] = {text = L.cd2ColSetFontPosCenter, func = dropDownFontAdjSetValue, arg1 = nil, justifyH = "CENTER"}
	self.dropDownFontAdj.List[2] = {text = L.cd2ColSetFontPosLeft, func = dropDownFontAdjSetValue, arg1 = 1, justifyH = "LEFT"}
	self.dropDownFontAdj.List[3] = {text = L.cd2ColSetFontPosRight, func = dropDownFontAdjSetValue, arg1 = 2, justifyH = "RIGHT"}

	self.sliderFontSize = ELib:Slider(self.optionWidgets.tabs[1],L.NoteFontSize):Size(280):Point(100,-125):Range(12,120):SetTo(VExRT.Reminder.FontSize or 72):OnChange(function(self,event)
		event = floor(event + .5)
		VExRT.Reminder.FontSize = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.CenterXButton = ELib:mStyledButton(self.optionWidgets.tabs[1],LR.CenterByX,13):Point(100,-150):Size(139,20):Tooltip(LR.CenterXTip):OnClick(function()
		frame:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VExRT.Reminder.Left = frame:GetLeft() - 15
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Reminder.Left,VExRT.Reminder.Top)
	end)

	self.CenterYButton = ELib:mStyledButton(self.optionWidgets.tabs[1],LR.CenterByY,13):Point("LEFT",self.CenterXButton,"RIGHT",3,0):Size(139,20):Tooltip(LR.CenterYTip):OnClick(function()
		frame:SetPoint("TOPLEFT",UIParent,"CENTER",0,0)
		VExRT.Reminder.Top = frame:GetTop() + 15
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Reminder.Left,VExRT.Reminder.Top)
	end)

	self.chkEnableHistory = ELib:Check(self.tab.tabs[2],LR.EnableHistory,VExRT.Reminder.HistoryEnabled):Point(10,-60):OnClick(function(self) -- :AddColorState() :Size(18,18)
		VExRT.Reminder.HistoryEnabled = self:GetChecked()
	end)

	self.chkEnableHistory = ELib:Check(self.tab.tabs[2],LR.EnableHistoryRaid,ReminderLog.TrueHistoryEnabled):Point(10,-85):Tooltip(LR.chkEnableHistoryTip):OnClick(function(self) -- :AddColorState() :Size(18,18)
		ReminderLog.TrueHistoryEnabled = self:GetChecked()
		if not ReminderLog.TrueHistoryEnabled then
			SetupFrame.QuickList.HistoryBackground:Hide()
			ReminderLog.TrueHistory = {}
			if ReminderLog.TrueHistoryDungeonEnabled then
				currentTrueHistory = ReminderLog.TrueHistoryDungeon
			else
				currentTrueHistory = {}
			end
			lastHistory = 0
			UpdateHistory(lastHistory)
		end
	end)

	self.chkTrueHistoryDungeon = ELib:Check(self.tab.tabs[2],LR.EnableHistoryDungeon,ReminderLog.TrueHistoryDungeonEnabled):Point(10,-110):Tooltip(LR.chkEnableHistoryTip):OnClick(function(self) -- :AddColorState() :Size(18,18)
		ReminderLog.TrueHistoryDungeonEnabled =  self:GetChecked()
		if not ReminderLog.TrueHistoryDungeonEnabled then
			SetupFrame.QuickList.HistoryBackground:Hide()
			ReminderLog.TrueHistoryDungeon = {}
			if ReminderLog.TrueHistoryEnabled then
				currentTrueHistory = ReminderLog.TrueHistory
			else
				currentTrueHistory = {}
			end
			lastHistory = 0
			UpdateHistory(lastHistory)
		end
	end)

	self.HistorySlider = ELib:Slider(self.tab.tabs[2],L.BossWatcherOptionsFightsSave):Size(280):Point(10,-145):Range(2,12):SetTo(VExRT.Reminder.HistoryMaxPulls or 5):OnChange(function(self,event)
		event = floor(event + .5)
		VExRT.Reminder.HistoryMaxPulls = event
		module:UpdateVisual()
		self.tooltipText = event
		self:tooltipReload(self)
		UpdateHistory(lastHistory)
	end)

	---------------------------------------
	self.chkDebug = ELib:Check(self.tab.tabs[2],"", VExRT.Reminder.Debug):Point(10,-250):OnClick(function(self)
		VExRT.Reminder.Debug = self:GetChecked()
	end)
	ELib:Text(self.chkDebug,"|cffffce00Output EncounterID to chat on end of the pull\nOutput spawn index when checking unit condition",12):Point("LEFT",self.chkDebug,"RIGHT",5,0):Shadow()

	----------------------------------------------------------------
	local ttsDropDownText
	for i=1, #ttsVoices do
		if ttsVoices[i].voiceID == VExRT.Reminder.ttsVoice then
			ttsDropDownText = ttsVoices[i].name
		end
	end

	self.ttsVoiceDropDown = ELib:DropDown(self.optionWidgets.tabs[2],275,#ttsVoices+1):Point(100,-15):Size(280):SetText(ttsDropDownText):AddText("|cffffce00TTS Voice")

	local function ttsVoiceDropDown_SetVaule(_,arg)
		VExRT.Reminder.ttsVoice = arg.voiceID
		self.ttsVoiceDropDown:SetText(arg.name)
		ELib:DropDownClose()
		for i=1,#self.ttsVoiceDropDown.List-1 do
			self.ttsVoiceDropDown.List[i].checkState = VExRT.Reminder.ttsVoice == self.ttsVoiceDropDown.List[i].arg1.voiceID
		end
		module:UpdateVisual()
	end

	for i=1,#ttsVoices do
		self.ttsVoiceDropDown.List[i] = {
			text = ttsVoices[i].name,
			arg1 = ttsVoices[i],
			func = ttsVoiceDropDown_SetVaule,
		}
	end
	tinsert(self.ttsVoiceDropDown.List,{text = L.minimapmenuclose, func = function()
			ELib:DropDownClose()
		end})

	self.ttsVolumeSlider = ELib:Slider(self.optionWidgets.tabs[2],"TTS Volume"):Size(280):Point(100,-55):Range(1,100):SetTo(VExRT.Reminder.ttsVoiceVolume or 100):OnChange(function(self,event)
		event = floor(event + .5)
		VExRT.Reminder.ttsVoiceVolume = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.ttsRateSlider = ELib:Slider(self.optionWidgets.tabs[2],"TTS Rate"):Size(280):Point(100,-85):Range(-10,10):SetTo(VExRT.Reminder.ttsVoiceRate or 100):OnChange(function(self,event)
		event = floor(event + .5)
		VExRT.Reminder.ttsVoiceRate = event
		self.tooltipText = event
		self:tooltipReload(self)
	end)

	self.ttsVoiceTestButton = ELib:mStyledButton(self.optionWidgets.tabs[2],"TTS TEST",13):Size(80,20):FontSize(12):Point("LEFT",self.ttsVoiceDropDown,"RIGHT",5,0):OnClick(function()
		C_VoiceChat.SpeakText(VExRT.Reminder.ttsVoice,
			"This is an example of text to speech",
			Enum.VoiceTtsDestination.QueuedLocalPlayback,
			VExRT.Reminder.ttsVoiceRate,
			VExRT.Reminder.ttsVoiceVolume)
	end)

	do
		local Glow = VExRT.Reminder.Glow
		local PixelGlow = Glow.PixelGlow
		local AutoCastGlow = Glow.AutoCastGlow
		local ProcGlow = Glow.ProcGlow
		local ActionButtonGlow = Glow.ActionButtonGlow

		self.GlowColorPicker = ExRT.lib.CreateColorPickButton(self.optionWidgets.tabs[3],19,19,nil,100,-50)
		self.GlowColorPicker:SetScript("OnClick",function (self)
			ColorPickerFrame.previousValues = {Glow.ColorR or 1, Glow.ColorG or 1, Glow.ColorB or 1, Glow.ColorA or 1}
			ColorPickerFrame.hasOpacity = true
			local nilFunc = ExRT.NULLfunc
			local function changedCallback(restore)
				local newR, newG, newB, newA
				if restore then
					newR, newG, newB, newA = unpack(restore)
				else
					newA, newR, newG, newB = 1 - OpacitySliderFrame:GetValue(), ColorPickerFrame:GetColorRGB()
					newA = newA
				end
				Glow.ColorR  = newR
				Glow.ColorG  = newG
				Glow.ColorB  = newB
				Glow.ColorA  = newA

				self.color:SetColorTexture(newR,newG,newB,newA)
			end
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = nilFunc, nilFunc, nilFunc
			ColorPickerFrame.opacity = 1 - (Glow.ColorA or 0)
			ColorPickerFrame:SetColorRGB(Glow.ColorR or 1, Glow.ColorG or 1, Glow.ColorB or 1)
			ColorPickerFrame.func, ColorPickerFrame.opacityFunc, ColorPickerFrame.cancelFunc = changedCallback, changedCallback, changedCallback
			ColorPickerFrame:Show()
		end)

		local texture = self.GlowColorPicker:CreateTexture(nil, "BACKGROUND")
		self.GlowColorPicker.color.background = texture
		texture:SetWidth(16)
		texture:SetHeight(16)
		texture:SetColorTexture(1, 1, 1)
		texture:SetPoint("CENTER", self.GlowColorPicker.color)
		texture:Show()

		local checkers = self.GlowColorPicker:CreateTexture(nil, "BACKGROUND")
		self.GlowColorPicker.color.checkers = checkers
		checkers:SetWidth(14)
		checkers:SetHeight(14)
		checkers:SetTexture(188523) -- Tileset\\Generic\\Checkers
		checkers:SetTexCoord(.25, 0, 0.5, .25)
		checkers:SetDesaturated(true)
		checkers:SetVertexColor(1, 1, 1, 0.75)
		checkers:SetPoint("CENTER", self.GlowColorPicker.color)
		checkers:Show()

		self.GlowColorPicker.color:SetDrawLayer("BORDER", -7)
		self.GlowColorPicker.color:SetColorTexture(Glow.ColorR or 1, Glow.ColorG or 1, Glow.ColorB or 1, Glow.ColorA or 1) --ColorA or 1)
		ELib:Text(self.GlowColorPicker,"Glow Color",12):Point("LEFT",self.GlowColorPicker,"RIGHT",5,0):Left():Middle():Color():Shadow()


		-------------------------------------------------------------------
		-------------------------PIXEL GLOW--------------------------------
		-------------------------------------------------------------------

		self.pixelGlowFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(PixelGlow.frequency):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.pixelGlowFrequencySlider.High:SetText("5")
		self.pixelGlowFrequencySlider.Low:SetText("-5")

		self.pixelGlowCountSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Count"):Size(120):Point(230,-85):Range(1,20):SetTo(PixelGlow.count):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowLengthSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Length"):Size(120):Point(360,-85):Range(1,50):SetTo(PixelGlow.length):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.length = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowThicknessSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Thickness"):Size(120):Point(490,-85):Range(1,6):SetTo(PixelGlow.thickness):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.thickness = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(PixelGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.pixelGlowYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(PixelGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			PixelGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.chkPixelGlowBorder = ELib:Check(self.optionWidgets.tabs[3],"Glow Border", PixelGlow.border):Point(360,-115):OnClick(function(self)
			PixelGlow.border = self:GetChecked()
		end)

		-------------------------------------------------------------------
		-------------------------AUTO CAST GLOW----------------------------
		-------------------------------------------------------------------

		self.autoCastFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(AutoCastGlow.frequency):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.autoCastFrequencySlider.High:SetText("5")
		self.autoCastFrequencySlider.Low:SetText("-5")

		self.autoCastCountSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Count"):Size(120):Point(230,-85):Range(1,20):SetTo(AutoCastGlow.count):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.count = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.autoCastScaleSlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Scale"):Size(120):Point(360,-85):Range(4,20):SetTo(AutoCastGlow.scale):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.scale = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.autoCastScaleSlider.High:SetText("5")
		self.autoCastScaleSlider.Low:SetText("1")
		self.autoCastScaleSlider.tooltipText = AutoCastGlow.scale*4

		self.autoCastXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(AutoCastGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.autoCastYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(AutoCastGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			AutoCastGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		-------------------------------------------------------------------
		-------------------------PROC GLOW---------------------------------
		-------------------------------------------------------------------

		self.procGlowDurationSlider = ELib:Slider(self.optionWidgets.tabs[3],"Animation duration"):Size(120):Point(100,-85):Range(0,20):SetTo(ProcGlow.duration*8):OnChange(function(self,event)
			event = event
			ProcGlow.duration = event/8
			self.tooltipText = event/8
			self:tooltipReload(self)
		end)
		self.procGlowDurationSlider.High:SetText("2.5")
		self.procGlowDurationSlider.Low:SetText("0")
		self.procGlowDurationSlider.tooltipText = ProcGlow.duration
		-- self.procGlowDurationSlider.tooltipReload(self.procGlowDurationSlider)

		self.procGlowXOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"x Offset"):Size(120):Point(100,-115):Range(-15,15):SetTo(ProcGlow.xOffset):OnChange(function(self,event)
			event = floor(event + .5)
			ProcGlow.xOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.proclGlowYOffsetSlider = ELib:Slider(self.optionWidgets.tabs[3],"y Offset"):Size(120):Point(230,-115):Range(-15,15):SetTo(ProcGlow.yOffset):OnChange(function(self,event)
			event = floor(event + .5)
			ProcGlow.yOffset = event
			self.tooltipText = event
			self:tooltipReload(self)
		end)

		self.chkProcGlowStartAnim = ELib:Check(self.optionWidgets.tabs[3],"Start Animation", ProcGlow.startAnim):Point(360,-115):OnClick(function(self)
			ProcGlow.startAnim = self:GetChecked()
		end)

		-------------------------------------------------------------------
		-------------------------ACTION BUTTON GLOW------------------------
		-------------------------------------------------------------------

		self.actionButtonFrequencySlider = ELib:Slider(self.optionWidgets.tabs[3],"Glow Frequency"):Size(120):Point(100,-85):Range(-20,20):SetTo(ActionButtonGlow.frequency/4):OnChange(function(self,event)
			event = floor(event + .5)
			ActionButtonGlow.frequency = event/4
			self.tooltipText = event/4
			self:tooltipReload(self)
		end)
		self.actionButtonFrequencySlider.High:SetText("5")
		self.actionButtonFrequencySlider.Low:SetText("-5")
		------------------------------------------------------------------
		local function SetGlowButtons()
			local type = Glow.type

			self.pixelGlowCountSlider:Hide()
			self.pixelGlowFrequencySlider:Hide()
			self.pixelGlowLengthSlider:Hide()
			self.pixelGlowThicknessSlider:Hide()
			self.pixelGlowXOffsetSlider:Hide()
			self.pixelGlowYOffsetSlider:Hide()
			self.chkPixelGlowBorder:Hide()

			self.autoCastCountSlider:Hide()
			self.autoCastFrequencySlider:Hide()
			self.autoCastScaleSlider:Hide()
			self.autoCastXOffsetSlider:Hide()
			self.autoCastYOffsetSlider:Hide()

			self.procGlowDurationSlider:Hide()
			self.procGlowXOffsetSlider:Hide()
			self.proclGlowYOffsetSlider:Hide()
			self.chkProcGlowStartAnim:Hide()

			self.actionButtonFrequencySlider:Hide()

			if type == "Pixel Glow" then
				self.pixelGlowCountSlider:Show()
				self.pixelGlowFrequencySlider:Show()
				self.pixelGlowLengthSlider:Show()
				self.pixelGlowThicknessSlider:Show()
				self.pixelGlowXOffsetSlider:Show()
				self.pixelGlowYOffsetSlider:Show()
				self.chkPixelGlowBorder:Show()
			elseif type == "Autocast Shine" then
				self.autoCastCountSlider:Show()
				self.autoCastFrequencySlider:Show()
				self.autoCastScaleSlider:Show()
				self.autoCastXOffsetSlider:Show()
				self.autoCastYOffsetSlider:Show()
			elseif type == "Proc Glow" then
				self.procGlowDurationSlider:Show()
				self.procGlowXOffsetSlider:Show()
				self.proclGlowYOffsetSlider:Show()
				self.chkProcGlowStartAnim:Show()
			else
				self.actionButtonFrequencySlider:Show()
			end
		end
		SetGlowButtons()
		self.glowDropDown = ELib:DropDown(self.optionWidgets.tabs[3],275,#glowList+1):Point(100,-15):Size(280):SetText(Glow.type):AddText("|cffffce00Glow Type")

		local function glowDropDown_SetVaule(_,arg)
			Glow.type = arg
			self.glowDropDown:SetText(arg)
			ELib:DropDownClose()
			for i=1,#self.glowDropDown.List-1 do
				self.glowDropDown.List[i].checkState = Glow.type == self.glowDropDown.List[i].arg1
			end
			SetGlowButtons()
		end

		for i=1,#glowList do
			self.glowDropDown.List[i] = {
				text = glowList[i],
				arg1 = glowList[i],
				func = glowDropDown_SetVaule,
			}
		end
		tinsert(self.glowDropDown.List,{text = L.minimapmenuclose, func = function()
				ELib:DropDownClose()
			end})

		self.glowTestButton = ELib:mStyledButton(self.optionWidgets.tabs[3],"GLOW TEST",13):Size(80,20):FontSize(12):Point("LEFT",self.glowDropDown,"RIGHT",5, 0):Tooltip("Only in raid group\nGlows raid1 for 5 sec"):OnClick(function()
			LGF.ScanForUnitFrames()
			C_Timer.After(0.2, function()
				local unit = "raid1"
				local unitFrame = LGF.GetFrame(unit,LGFNullOpt)

				if unitFrame then
					local Glow = VExRT.Reminder.Glow
					local type = Glow.type
					if type == "Pixel Glow" then
						local PixelGlow = Glow.PixelGlow
						LCG.PixelGlow_Start(unitFrame,{
								Glow.ColorR,
								Glow.ColorG,
								Glow.ColorB,
								Glow.ColorA
							},
							PixelGlow.count,
							PixelGlow.frequency,
							PixelGlow.length,
							PixelGlow.thickness,
							PixelGlow.xOffset,
							PixelGlow.yOffset,
							PixelGlow.border)
						C_Timer.After(5, function() LCG.PixelGlow_Stop(unitFrame) end)

					elseif type == "Autocast Shine" then
						local AutoCastGlow = Glow.AutoCastGlow
						LCG.AutoCastGlow_Start(unitFrame,{
								Glow.ColorR,
								Glow.ColorG,
								Glow.ColorB,
								Glow.ColorA
							},
							AutoCastGlow.count,
							AutoCastGlow.frequency,
							AutoCastGlow.scale,
							AutoCastGlow.xOffset,
							AutoCastGlow.yOffset)
						C_Timer.After(5, function() LCG.AutoCastGlow_Stop(unitFrame) end)
					elseif type == "Proc Glow" then
						local ProcGlow = Glow.ProcGlow
						LCG.ProcGlow_Start(unitFrame,{
							color = {
								Glow.ColorR,
								Glow.ColorG,
								Glow.ColorB,
								Glow.ColorA
							},
							duration = ProcGlow.duration,
							startAnim = ProcGlow.startAnim,
							xOffset = ProcGlow.xOffset,
							yOffset = ProcGlow.yOffset,
						})
						C_Timer.After(5, function() LCG.ProcGlow_Stop(unitFrame) end)
					else
						LCG.ButtonGlow_Start(unitFrame,{
								Glow.ColorR,
								Glow.ColorG,
								Glow.ColorB,
								Glow.ColorA
							},
							Glow.ActionButtonGlow.frequency)
						C_Timer.After(5, function() LCG.ButtonGlow_Stop(unitFrame) end)
					end
				end
			end)
		end)

	end
	--end of raidframe glow settings
	----------------------------------------------------------------

	local NamePlateGlowTypeDropDown = ELib:DropDown(self.optionWidgets.tabs[4],275,#module.datas.glowTypes):Point(100,-15):Size(280):AddText("|cffffce00Nameplate\nGlow Type")
	do
		local function NamePlateGlowTypeDropDown_SetVaule(_,arg)
			VExRT.Reminder.NameplateGlowType = arg
			ELib:DropDownClose()
			for i=1,#module.datas.glowTypes do
				if module.datas.glowTypes[i][1] == arg then
					NamePlateGlowTypeDropDown:SetText(module.datas.glowTypes[i][2])
					break
				end
			end
		end

		List = NamePlateGlowTypeDropDown.List
		for i=1,#module.datas.glowTypes do
			List[i] = {
				text = module.datas.glowTypes[i][2],
				arg1 = module.datas.glowTypes[i][1],
				func = NamePlateGlowTypeDropDown_SetVaule,
			}
		end

		for i=1,#module.datas.glowTypes do
			if module.datas.glowTypes[i][1] == VExRT.Reminder.NameplateGlowType then
				NamePlateGlowTypeDropDown:SetText(module.datas.glowTypes[i][2])
				break
			end
		end
	end

	--additional tabs
	local changelogScroll = ELib:ScrollFrame(self.tab.tabs[3]):Size(760,530):Point("TOPLEFT",0,0)
	local changelogText = ELib:Text(changelogScroll.C, changelog):Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5):Color()
	changelogScroll:Height(changelogText:GetStringHeight()+100)

	changelogScroll.C:SetWidth(695 - 16)
	ELib:Border(changelogScroll,0)
	ELib:DecorationLine(self):Point("TOP",changelogScroll,"BOTTOM",0,0):Point("LEFT",self):Point("RIGHT",self):Size(0,1)

	local helpScroll = ELib:ScrollFrame(self.tab.tabs[4]):Size(760,530):Point("TOPLEFT",0,0)
	local helpText = ELib:Text(helpScroll.C, LR.HelpText):Point("LEFT",10,0):Point("RIGHT",-10,0):Point("TOP",0,-5):Color()

	helpScroll:Height(helpText:GetStringHeight()+100)
	helpScroll.C:SetWidth(695 - 16)
	ELib:Border(helpScroll,0)
	ELib:DecorationLine(self):Point("TOP",helpScroll,"BOTTOM",0,0):Point("LEFT",self):Point("RIGHT",self):Size(0,1)


	local VersionCheckReqSended = {}
	local function UpdateVersionCheck()
		self.VersionUpdateButton:Enable()
		local list = self.VersionCheck.L
		wipe(list)

		list[#list + 1] = {
			"|cff9b9b9bName",
			"|cff9b9b9bVersion",
			"|cff9b9b9bStatus",
			"|cff9b9b9bBoss Mod",
			"AAAAAAAAAAA",
		}
		for _, name, _, class in ExRT.F.IterateRoster do
			list[#list + 1] = {
				"|c"..ExRT.F.classColor(class or "?")..name,
				0,
				0,
				0,
				name,
			}
		end

		for i=2,#list do
			local name = list[i][5]

			local ver = module.db.gettedVersions[name]
			if not ver and not name:find("%-") then
				for long_name,v in pairs(module.db.gettedVersions) do
					if long_name:find("^"..name) then
						ver = v
						break
					end
				end
			end
			local stringTbl = {}
			if ver then
				for v in string.gmatch(ver, "[^ ]+") do
					tinsert(stringTbl, v)
				end
			end
			local ver, enabled, bossmod = stringTbl[1],stringTbl[2],stringTbl[3]
			if not ver then
				if VersionCheckReqSended[name] then
					if not UnitIsConnected(name) then
						ver = "|cff888888offline"
					else
						ver = "|cffff8888no addon"
					end
				else
					ver = "???"
				end
			elseif not tonumber(ver) then
				ver = "|cffffe7be"..ver
			elseif tonumber(ver) >= DATA_VERSION then
				ver = "|cff88ff88"..ver
			else
				ver = "|cffffff88"..ver
			end

			if UnitIsConnected(name) then
				if enabled == "Enabled" then
					enabled = "|cff88ff88Enabled|r"
				elseif enabled == "Disabled" then
					enabled = "|cffffff88Disabled"
				else
					enabled = ""
				end

				if bossmod == "BW" then
					bossmod = "|cff88ff88BigWigs|r"
				elseif bossmod == "DBM" then
					bossmod = "|cffffff88DBM"
				else
					bossmod = ""
				end
			else
				bossmod = ""
				enabled = ""
			end

			list[i][2] = ver
			list[i][3] = enabled
			list[i][4] = bossmod
		end

		sort(list,function(a,b) return a[5]<b[5] end)
		self.VersionCheck:Update()

		self.VersionCheck.List[1].HighlightTexture:SetVertexColor(0,0,0,0)
	end

	self.VersionCheck = ELib:ScrollTableList(self.tab.tabs[5],0,60, 60, 60):Point(5,-5):Size(380,520):HideBorders():OnShow(UpdateVersionCheck,true) --:HideBorders()

	self.VersionUpdateButton = ELib:mStyledButton(self.tab.tabs[5],UPDATE,13):Point("TOPLEFT",self.VersionCheck,"TOPRIGHT",0,0):Size(100,20):Tooltip(L.OptionsUpdateVerTooltip):OnClick(function() --:Point("BOTTOMLEFT",self.VersionCheck,"BOTTOMRIGHT",10,3)
		module.db.getVersion = GetTime()
		wipe(module.db.gettedVersions)
		ExRT.F.SendExMsg("ADV", "GV")

		C_Timer.After(2,UpdateVersionCheck)
		for _, name in ExRT.F.IterateRoster do
			VersionCheckReqSended[name]=true
		end
		local list = self.VersionCheck.L
		for i=2,#list do
			list[i][2] = "..."
		end
		self.VersionCheck:Update()
		self.VersionUpdateButton:Disable()
	end)

	self.isWide = 760
end

function module:Modernize()
    --refactoring bin table
   if not VExRT.Reminder.v29 then
		VExRT.Reminder.v29 = true
		for k,v in ipairs(VExRT.Reminder.removed) do
			VExRT.Reminder.removed[k] = nil
			VExRT.Reminder.removed[v] = true
		end
    end
    if not VExRT.Reminder.v32 then -- remove this from ADDON_LOADED
        VExRT.Reminder.v32 = true
        for token,data in pairs(VExRT.Reminder.data) do
            if data.event == "BOSS_START" then
                data.spellID = nil
            end
        end
    end
end

local function GetDefaultTTSVoiceID()
	if C_VoiceChat then
		local TTSVOICES = C_VoiceChat.GetTtsVoices()
		local voiceID = 0
		for k, v in pairs(TTSVOICES) do
			if v.name:match("English") then
				voiceID = v.voiceID
				break
			end
		end
		return voiceID
	else
		return 0
	end
end

function module.main:ADDON_LOADED()
	VExRT = _G.VExRT
	ReminderLog = _G.ReminderLog or {}
	VExRT.Reminder = VExRT.Reminder or {enabled=true,HistoryEnabled=true,v29=true,v32=true}
	VExRT.Reminder.data = VExRT.Reminder.data or {}
	VExRT.Reminder.disabled = VExRT.Reminder.disabled or {}
	VExRT.Reminder.locked = VExRT.Reminder.locked or {}
	VExRT.Reminder.OutlineType = VExRT.Reminder.OutlineType or "OUTLINE"
	VExRT.Reminder.removed = VExRT.Reminder.removed or {}
	VExRT.Reminder.disableSounds = VExRT.Reminder.disableSounds or {}
	VExRT.Reminder.zoneNames = VExRT.Reminder.zoneNames or {}

    module:Modernize()

	VExRT.Reminder.HistoryEnabled = (VExRT.Reminder.HistoryEnabled == nil and true) or VExRT.Reminder.HistoryEnabled

    -- ReminderLog is SavedVariables for ExRT Reminder, switching MRT profile will not affect it
	ReminderLog.TrueHistory = ReminderLog.TrueHistory or VExRT.Reminder.TrueHistory or {}
	ReminderLog.TrueHistoryEnabled = ReminderLog.TrueHistoryEnabled or VExRT.Reminder.TrueHistoryEnabled
	ReminderLog.TrueHistoryDungeon = ReminderLog.TrueHistoryDungeon or VExRT.Reminder.TrueHistoryDungeon or  {}
	ReminderLog.TrueHistoryDungeonEnabled = ReminderLog.TrueHistoryDungeonEnabled or VExRT.Reminder.TrueHistoryDungeonEnabled
	VExRT.Reminder.HistoryMaxPulls = VExRT.Reminder.HistoryMaxPulls or 2

	---Clear old data
	VExRT.Reminder.TrueHistory = nil
	VExRT.Reminder.TrueHistoryEnabled = nil
	VExRT.Reminder.TrueHistoryDungeon = nil
	VExRT.Reminder.TrueHistoryDungeonEnabled = nil
	if VExRT.Reminder.HistoryMaxPulls > 12 then
		VExRT.Reminder.HistoryMaxPulls = 12
	end

	if ReminderLog.TrueHistoryEnabled then
		currentTrueHistory = ReminderLog.TrueHistory
	elseif ReminderLog.TrueHistoryDungeonEnabled then
		currentTrueHistory = ReminderLog.TrueHistoryDungeon
	else
		currentTrueHistory = ReminderLog.TrueHistory
	end

	VExRT.Reminder.FrameStrata = VExRT.Reminder.FrameStrata or "HIGH"

	VExRT.Reminder.ttsVoice = VExRT.Reminder.ttsVoice or GetDefaultTTSVoiceID()
	VExRT.Reminder.ttsVoiceVolume = VExRT.Reminder.ttsVoiceVolume or 75
	VExRT.Reminder.ttsVoiceRate = VExRT.Reminder.ttsVoiceRate or 0


	VExRT.Reminder.Glow = VExRT.Reminder.Glow or {}
	local Glow = VExRT.Reminder.Glow
	Glow.type = Glow.type or "Action Button Glow"

	Glow.PixelGlow = Glow.PixelGlow or {
		count = 8,
		frequency = 0.25,
		length = 20,
		thickness = 3,
		xOffset = 0,
		yOffset = 0,
		border = true,
	}

	Glow.AutoCastGlow = Glow.AutoCastGlow or {
		count = 10,
		frequency = 0.25,
		scale = 1.5,
		xOffset = 0,
		yOffset = 0,
	}

	Glow.ProcGlow = Glow.ProcGlow or {
		xOffset = 0,
		yOffset = 0,
		startAnim = true,
		duration = 1,
	}

	Glow.ActionButtonGlow = Glow.ActionButtonGlow or {
		frequency = 0.125,
	}

	Glow.ColorR = Glow.ColorR or 1
	Glow.ColorG = Glow.ColorG or 0
	Glow.ColorB = Glow.ColorB or 0
	Glow.ColorA = Glow.ColorA or 1

	if VExRT.Reminder.Left and VExRT.Reminder.Top then
		frame:ClearAllPoints()
		frame:SetPoint("TOPLEFT",UIParent,"BOTTOMLEFT",VExRT.Reminder.Left,VExRT.Reminder.Top)
	end

	module:UpdateVisual()
	module:RegisterAddonMessage()
	module:RegisterSlash()

	if VExRT.Reminder.enabled then
		module:Enable()
	end
end

local function BossPhaseCheck(phase,phaseCount)
	if not ActiveEncounter or not CLEU_BOSS_PHASE[ActiveEncounter] or not CLEU_BOSS_PHASE[ActiveEncounter][phase] then
		return
	end
	ActivePhase = phase
	local ff = CLEU_BOSS_PHASE[ActiveEncounter][phase]
	for i=1,#ff do
		local f = ff[i]
		f(phaseCount or 0,"",0,ActiveEncounterStart,{})
	end
end

local function BossPullCheck()
	if not ActiveEncounter or not CLEU_BOSS_START[ActiveEncounter] or not CLEU_BOSS_START[ActiveEncounter] then
		return
	end
	local ff = CLEU_BOSS_START[ActiveEncounter]
	for i=1,#ff do
		local f = ff[i]
		f(1,"",0,ActiveEncounterStart,{})
	end
end

local BossModsLink, BossModsRefresh
do
	local isAdded = nil
	local prevPhase = nil
	function BossModsLink()
		if isAdded then
			return
		end
		if (BigWigsLoader) and BigWigsLoader.RegisterMessage then
			local r = {}
			function r:BigWigs_SetStage (_, _, key, ...)
				local phase = key
				phase = tonumber (phase)

				if (phase and type (phase) == "number" and prevPhase ~= phase) then
					prevPhase = phase

					CastNumbers_PHASE[phase] = (CastNumbers_PHASE[phase] or 0)+1
					BossPhaseCheck(phase,CastNumbers_PHASE[phase])

					history[#history+1] = {GetTime(),"PHASE",phase,CastNumbers_PHASE[phase]}
				end
			end

			BigWigsLoader.RegisterMessage (r, "BigWigs_SetStage")


			isAdded = true
		elseif (DBM) then
			local function r(event,mod,modID,key,encounterID,stageTotal)

				local phase = key
				phase = tonumber (phase)
				if (phase and type (phase) == "number" and prevPhase ~= phase) then
					prevPhase = phase

					CastNumbers_PHASE[phase] = (CastNumbers_PHASE[phase] or 0)+1
					BossPhaseCheck(phase,CastNumbers_PHASE[phase])

					history[#history+1] = {GetTime(),"PHASE",phase,CastNumbers_PHASE[phase]}
				end
			end

			DBM:RegisterCallback("DBM_SetStage", r)

			isAdded = true
		end
	end
	function BossModsRefresh()
		prevPhase = nil
	end
end

do
	local scheduledUpdate
	local prevZoneID
	function module:LoadForCurrentZone()
		scheduledUpdate = nil
		if ActiveEncounter then
			return
		end
		local zoneName, _, _, _, _, _, _, zoneID = GetInstanceInfo()
		if zoneID ~= prevZoneID then
			prevZoneID = zoneID
			CreateFunctions(_,_,zoneID,zoneName)
		end
	end
	function module.main:ZONE_CHANGED_NEW_AREA()
		if not scheduledUpdate then
			scheduledUpdate = ScheduleTimer(module.LoadForCurrentZone,1)
		end
	end
	function module:ResetPrevZone()
		prevZoneID = nil
	end
end

function module.main:ENCOUNTER_START(encounterID, encounterName, difficultyID, groupSize)
	module.db.lastEncounterID = encounterID
	ActiveEncounter = encounterID

	local zoneName, _, _, _, _, _, _, zoneID = GetInstanceInfo()
	CreateFunctions(encounterID, difficultyID, zoneID, zoneName)

	wipe(CastNumbers_SUCCESS)
	wipe(CastNumbers_START)
	wipe(CastNumbers_HP)
	wipe(CastNumbers_MANA)
	wipe(CastNumbers_MANA2)
	wipe(CastNumbers_PHASE)
	wipe(CastNumbers_BW_MSG)
	wipe(CastNumbers_BW_TIMER)
	wipe(CastNumbers_AURA_APPLIED)
	wipe(CastNumbers_AURA_REMOVED)
	wipe(CastNumbers_AURA_APPLIED_SELF)
	wipe(CastNumbers_AURA_REMOVED_SELF)
	wipe(bossManaPrev)
	BossModsRefresh()
	BossModsLink()
	CastNumbers_PHASE[1] = 0
	ActivePhase = 1
	ActiveEncounterStart = GetTime()
	BossPhaseCheck(0, 0)
	BossPullCheck()
	if module.db.eventsToTriggers.BOSS_START or module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL then
		module:TriggerBossPull(encounterID, encounterName)
	end
	if module.db.eventsToTriggers.BOSS_PHASE or module.db.eventsToTriggers.NOTE_TIMERS or module.db.eventsToTriggers.NOTE_TIMERS_ALL then
		module:TriggerBossPhase("1")
	end
	if module.db.eventsToTriggers.RAID_GROUP_NUMBER then
		module.main:GROUP_ROSTER_UPDATE()
	end

	LGF.ScanForUnitFrames()

	for k,v in pairs(CLEU_BOSS_HP) do
		if v then
			BOSSHPFrame:RegisterEvent("UNIT_HEALTH")
			break
		end
	end

	for k,v in pairs(CLEU_BOSS_MANA) do
		if v then
			BOSSManaFrame:RegisterUnitEvent("UNIT_POWER_FREQUENT","boss1","boss2")
			break
		end
	end

	if VExRT.Reminder.HistoryEnabled then
		stopHistory = false

		history = {}
		history[1] = {ActiveEncounterStart,"START_FIGHT", encounterName, encounterID, difficultyID}
		CombatStartTimer = ActiveEncounterStart
		CombatStartDate = date("%H:%M:%S")
	end
end

function module.main:ENCOUNTER_END(encounterID, encounterName, difficultyID, groupSize, success)
	ActiveEncounter = nil

	module:ReloadAll()

	if C_VoiceChat and C_VoiceChat.StopSpeakingText then
		C_VoiceChat.StopSpeakingText()
	end

	for i=1,#ChatSpamTimers do
		ChatSpamTimers[i]:Cancel()
	end
	wipe(ChatSpamTimers)

	for i=1,#ActiveDelays do
		ActiveDelays[i]:Cancel()
	end
	wipe(ActiveDelays)

	BOSSHPFrame:UnregisterAllEvents()
	BOSSManaFrame:UnregisterAllEvents()

	stopHistory = true
	if VExRT.Reminder.HistoryEnabled then
		if not CombatStartTimer then return end
		local CombatTotalTimer = GetTime() - CombatStartTimer
		local inInstance, instanceType = IsInInstance()
		if (ReminderLog.TrueHistoryEnabled  and CombatTotalTimer > 30  and inInstance and instanceType == "raid") or false then
			tinsert(ReminderLog.TrueHistory,1,
				{
					CombatStartDate, history, encounterName,
					(difficultyID == 15 and "Heroic" or
						difficultyID == 16 and "Mythic" or
						difficultyID == 175 and "10 Normal" or
						difficultyID == 176 and "25 Normal" or
						difficultyID == 193 and "10 Heroic" or
						difficultyID == 194 and "25 Heroic" or
						groupSize), format("%d:%02d",CombatTotalTimer/60,CombatTotalTimer%60), success, encounterID
				})

			print("|cffff8000[Reminder]|r Raid boss history data added")

		elseif (ReminderLog.TrueHistoryDungeonEnabled  and CombatTotalTimer > 30  and inInstance and instanceType == "party") or false then
			tinsert(ReminderLog.TrueHistoryDungeon,1,
				{
					CombatStartDate, history, encounterName,
					(difficultyID == 15 and "Heroic" or
						difficultyID == 16 and "Mythic" or
						difficultyID == 175 and "10 Normal" or
						difficultyID == 176 and "25 Normal" or
						difficultyID == 193 and "10 Heroic" or
						difficultyID == 194 and "25 Heroic" or
						groupSize), format("%d:%02d",CombatTotalTimer/60,CombatTotalTimer%60), success, encounterID
				})
			print("|cffff8000[Reminder]|r Dungeon boss history data added")
		end
	end

	while(#ReminderLog.TrueHistory > VExRT.Reminder.HistoryMaxPulls) do
		table.remove(ReminderLog.TrueHistory)
	end

	while(#ReminderLog.TrueHistoryDungeon > VExRT.Reminder.HistoryMaxPulls) do
		table.remove(ReminderLog.TrueHistoryDungeon)
	end

	if VExRT.Reminder.Debug then
		print("|cffff8000[Reminder]|r EncounterID: " .. encounterID)
	end
end

local registeredBigWigsEventsOld = {}
function module:RegisterBigWigsCallback(event)
	if (registeredBigWigsEventsOld[event]) then
		return
	end
	if (BigWigsLoader) then
		ActiveBossMod = " BW"
		BigWigsLoader.RegisterMessage(oldBWFrame, event, bigWigsEventCallback)
		registeredBigWigsEventsOld[event] = true
	end
end

function module:UnregisterBigWigsCallback(event)
	if not (registeredBigWigsEventsOld[event]) then
		return
	end
	if (BigWigsLoader) then
		BigWigsLoader.UnregisterMessage(oldBWFrame, event)
		registeredBigWigsEventsOld[event] = nil
	end
end

local registeredDBMEventsOld = {}
function oldBWFrame:RegisterDBMCallback(event)
	if registeredDBMEventsOld[event] then
		return
	end
	if DBM then
		ActiveBossMod = " DBM"
		DBM:RegisterCallback(event, dbmEventCallback)
		registeredDBMEventsOld[event] = true
	end
end

function oldBWFrame:UnregisterDBMCallback(event)
	if not registeredDBMEventsOld[event] then
		return
	end
	if DBM then
		DBM:UnregisterCallback(event, dbmEventCallback)
		registeredDBMEventsOld[event] = nil
	end
end

function module:Enable()
	module.IsEnabled = true

	module:RegisterEvents('ENCOUNTER_START','ENCOUNTER_END','ZONE_CHANGED_NEW_AREA')

	module:ResetPrevZone()
	module:LoadForCurrentZone()

	CLEU:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	if BigWigsLoader then
		module:RegisterBigWigsCallback("BigWigs_Message")
		module:RegisterBigWigsCallback("BigWigs_StartBar")
		module:RegisterBigWigsCallback("BigWigs_StopBar")
		module:RegisterBigWigsCallback("BigWigs_PauseBar")
		module:RegisterBigWigsCallback("BigWigs_ResumeBar")
		module:RegisterBigWigsCallback("BigWigs_StopBars")
		module:RegisterBigWigsCallback("BigWigs_OnBossDisable")
	elseif DBM then
		oldBWFrame:RegisterDBMCallback("DBM_Announce")
		oldBWFrame:RegisterDBMCallback("DBM_TimerStart")
		oldBWFrame:RegisterDBMCallback("DBM_TimerStop")
		oldBWFrame:RegisterDBMCallback("DBM_TimerPause")
		oldBWFrame:RegisterDBMCallback("DBM_TimerResume")
		oldBWFrame:RegisterDBMCallback("DBM_TimerUpdate")
		oldBWFrame:RegisterDBMCallback("DBM_Wipe")
		oldBWFrame:RegisterDBMCallback("DBM_Kill")
	end
end

function module:Disable()
	module.IsEnabled = false

	module:UnregisterEvents('ENCOUNTER_START','ENCOUNTER_END','ZONE_CHANGED_NEW_AREA')

	CLEU:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	if BigWigsLoader then
		module:UnregisterBigWigsCallback("BigWigs_Message")
		module:UnregisterBigWigsCallback("BigWigs_StartBar")
		module:UnregisterBigWigsCallback("BigWigs_StopBar")
		module:UnregisterBigWigsCallback("BigWigs_PauseBar")
		module:UnregisterBigWigsCallback("BigWigs_ResumeBar")
		module:UnregisterBigWigsCallback("BigWigs_StopBars")
		module:UnregisterBigWigsCallback("BigWigs_OnBossDisable")
	elseif DBM then
		oldBWFrame:UnregisterDBMCallback("DBM_Announce")
		oldBWFrame:UnregisterDBMCallback("DBM_TimerStart")
		oldBWFrame:UnregisterDBMCallback("DBM_TimerStop")
		oldBWFrame:UnregisterDBMCallback("DBM_TimerPause")
		oldBWFrame:UnregisterDBMCallback("DBM_TimerResume")
		oldBWFrame:UnregisterDBMCallback("DBM_TimerUpdate")
		oldBWFrame:UnregisterDBMCallback("DBM_Wipe")
		oldBWFrame:UnregisterDBMCallback("DBM_Kill")
	end
	module:UnloadAll()
end

function module:UpdateVisual(onlyFont)
	if not onlyFont then
		if VExRT.Reminder.lock then
			frame.dot:Show()
			frame:EnableMouse(true)
			frame:SetMovable(true)
			frame.text1:SetText(module:FormatMsg("Test message Тест1\nTest message Тест2{spell:97462}\n{spell:23920}{spell:23920}{spell:23920}"))
			frame:Show()
		else
			frame.dot:Hide()
			frame:EnableMouse(false)
			frame:SetMovable(false)
			frame.text1:SetText("")
			frame:Hide()
		end
	end
	frame.text1:ClearAllPoints()
	frame.text1:SetFont(VExRT.Reminder.Font or ExRT.F.defFont, VExRT.Reminder.FontSize or 72, VExRT.Reminder.OutlineType or "OUTLINE, OUTLINE")
	if VExRT.Reminder.Shadow then
		frame.text1:SetShadowOffset(1, -1)
	else
		frame.text1:SetShadowOffset(0, 0)
	end
	frame:SetFrameStrata(VExRT.Reminder.FrameStrata)
	if VExRT.Reminder.JustifyH == 1 then
		frame.text1:SetPoint("TOPLEFT")
	elseif VExRT.Reminder.JustifyH == 2 then
		frame.text1:SetPoint("TOPRIGHT")
	else
		frame.text1:SetPoint("TOP")
	end
	frame.text1:SetJustifyH(VExRT.Reminder.JustifyH == 1 and "LEFT" or VExRT.Reminder.JustifyH == 2 and "RIGHT" or "CENTER")
end

ELib:FixPreloadFont(frame,function()
	if VExRT then
		frame.text1:SetFont(GameFontWhite:GetFont(),11)
		module:UpdateVisual(true)
		return true
	end
end)

local DELIMITER_1 = string.char(172)
local DELIMITER_2 = string.char(164)

local STRING_CONVERT = {
	list = {
		["\17"] = "\18",
		[DELIMITER_1] = "\19",
		[DELIMITER_2] = "\20",
	},
	listRev = {},
}
do
	local senc,sdec = "",""

	for k,v in pairs(STRING_CONVERT.list) do
		STRING_CONVERT.listRev[v] = k
		senc = senc .. k
		sdec = sdec .. v
	end

	STRING_CONVERT.encodePatt = "["..senc.."]"
	STRING_CONVERT.encodeFunc = function(a)
		return "\17"..STRING_CONVERT.list[a]
	end

	STRING_CONVERT.decodePatt = "\17(["..sdec.."])"
	STRING_CONVERT.decodeFunc = function(a)
		return STRING_CONVERT.listRev[a]
	end
end

do
	local checkType = {
		["invert"] = true,
		["onlyPlayer"] = true,
	}
	local stringType = {
		["sourceName"] = true,
		["sourceID"] = true,
		["targetName"] = true,
		["targetID"] = true,
		["spellName"] = true,
		["pattFind"] = true,
		["counter"] = true,
		["delayTime"] = true,
		["stacks"] = true,
		["numberPercent"] = true,
	}
	local numberType = {
		["sourceMark"] = true,
		["targetMark"] = true,
		["spellID"] = true,
		["extraSpellID"] = true,
		["bwtimeleft"] = true,
		["cbehavior"] = true,
		["activeTime"] = true,
		["guidunit"] = true,
		["targetRole"] = true,
	}
	local mixedType = {
		["sourceUnit"] = true,
		["targetUnit"] = true,
	}
	local cleu_events = {}
	for k,v in pairs(module.C) do
		if v.main_id == 1 and v.subID then
			cleu_events[tostring(v.subID)] = k
			cleu_events[k] = tostring(v.subID)
		end
	end
	function module:GetTriggerSyncString(trigger)
		local r = (trigger.event or "") .. DELIMITER_2 .. (trigger.andor or "")

		local eventDB
		if trigger.event == 1 then
			eventDB = module.C[trigger.eventCLEU or 0]
		else
			eventDB = module.C[trigger.event or 0]
		end

		local keysList
		if eventDB then
			keysList = eventDB.triggerSynqFields or eventDB.triggerFields
		end

		if keysList then
			for i=1,#keysList do
				local key = keysList[i]
				if key == "eventCLEU" then
					r = r .. DELIMITER_2 .. (cleu_events[ trigger[key] or 0 ] or trigger[key] or "")
				elseif checkType[key] then
					r = r .. DELIMITER_2 .. (trigger[key] and "1" or "")
				elseif stringType[key] then
					r = r .. DELIMITER_2 .. tostring(trigger[key] or ""):gsub(STRING_CONVERT.encodePatt,STRING_CONVERT.encodeFunc)
				else
					r = r .. DELIMITER_2 .. (trigger[key] or "")
				end
			end
		end

		r = r:gsub("["..DELIMITER_2.."]+$","")

		return r
	end

--[[
SENDER_VER^DATA_VER
token^boss^diff^name^event^msg^duration^delay^oldTypeOptions^trigeersNum^triggersData^checks^
loadOptions^soundOptions^glow^spamOptions^glowOptions^zoneID^countdownType^extraCheck^specialTarget


local nameplateText,glowType,glowColor,glowThick,glowScale,glowN,glowImage = strsplit(DELIMITER_1,glowOptions or "")
local spamMsg,spamType,spamChannel = strsplit(DELIMITER_1,spamOptions or "")
local sound, tts, voiceCountdown = strsplit(DELIMITER_1,soundOptions or "")
local roles,classes,units,notepat = strsplit(DELIMITER_1,loadOptions or "")
local spellID, cast, condition = strsplit(DELIMITER_1,oldTypeOptions or "")


local checksTable = {"countdown", "globalCounter", "reversed", "sendEvent", "nameplateGlow", "glowOnlyText", "doNotLoadOnBosses", "dynamicdisable", "norewrite", "copy", "disabled"}
]]

	local function CheckDataIntegrity(data)
		for k,v in pairs(module.SetupFrameDataRequirements) do
			if type(k) == 'number' then --always check
				local oneOF = false
				if not data[ v["exception"] ] then
					for i,field in ipairs(v) do
						if field == 0 then
							oneOF = i + 1
						elseif oneOF then
							local anyFilled
							for  j=oneOF,#v do
								if data[ v[j] ] then
									anyFilled = true
								end
							end
							if not anyFilled then
								for  j=oneOF,#v do
									return true
								end
							end
						else
							if not data[field] then
								return true
							end
						end
					end
				end
			elseif type(k) == 'string' then --check only if SetupFrameData[k]
				-- print(SetupFrameData.event[v["exception"]],v['exception'])
				if data[k] or (k == "NOT ADVANCED" and data.event ~= "ADVANCED" and data.event ~= v["exception"]) then
					for i,field in ipairs(v) do
						if not data[field] then
							return true
						end
					end
				end
			end
		end

	end
	local EVENT_KEYS = {
		[1] = "ADVANCED",
		[2] = "SPELL_CAST_SUCCESS",
		[3] = "SPELL_CAST_START",
		[4] = "BOSS_PHASE",
		[5] = "BOSS_START",
		[6] = "BOSS_HP",
		[7] = "BOSS_MANA",
		[8] = "BW_MSG",
		[9] = "BW_TIMER",
		[10] = "BW_TIMER_TEXT",
		[11] = "SPELL_AURA_APPLIED",
		[12] = "SPELL_AURA_REMOVED",
		[13] = "SPELL_AURA_APPLIED_SELF",
		[14] = "SPELL_AURA_REMOVED_SELF",

		["ADVANCED"] = 1,
		["SPELL_CAST_SUCCESS"] = 2,
		["SPELL_CAST_START"] = 3,
		["BOSS_PHASE"] = 4,
		["BOSS_START"] = 5,
		["BOSS_HP"] = 6,
		["BOSS_MANA"] = 7,
		["BW_MSG"] = 8,
		["BW_TIMER"] = 9,
		["BW_TIMER_TEXT"] = 10,
		["SPELL_AURA_APPLIED"] = 11,
		["SPELL_AURA_REMOVED"] = 12,
		["SPELL_AURA_APPLIED_SELF"] = 13,
		["SPELL_AURA_REMOVED_SELF"] = 14,
	}
	--add to start of the table
                -- countdown, globalCounter, reversed, sendEvent, nameplateGlow, glowOnlyText, doNotLoadOnBosses, dynamicdisable, norewrite, copy
	local checksTable = {"countdown", "globalCounter", "reversed", "sendEvent", "nameplateGlow", "glowOnlyText", "doNotLoadOnBosses", "dynamicdisable", "norewrite", "copy", "disabled"}
	local function GetChecksString(data)
		local checks = ""

		for i=1,#checksTable do
			local key = checksTable[i]
			checks = (data[key] and "1" or "0") .. checks
		end
        checks = tonumber(checks,2)
		return checks ~= 0 and checks or ""
	end

    local function GetClassesString(data)
        local classes = ""
        local classesList = ExRT.GDB.ClassList
        if data.classes then
            for i=1,#ExRT.GDB.ClassList do
                classes =  (data.classes:find("#".. classesList[i] .. "#") and "1" or "0") .. classes
            end
        end
        classes = tonumber(classes,2)
        return classes ~= 0 and classes or ""
    end

    local function GetRolesString(data)
        local roles = ""
        local rolesList = module.datas.rolesList
        if data.roles then
            for i=2,#rolesList do
                roles =  (data.roles:find("#" .. rolesList[i][3] .. "#") and "1" or "0") .. roles
            end
        end
        roles = tonumber(roles,2)
        return roles ~= 0 and roles or ""
    end

    local function TruncateOptionsString(string,isExport)
        string = string:gsub("%^", ""):gsub("["..DELIMITER_1.."]+$","") -- preventing griefed input
        if isExport then
            string = string:gsub("\\19",""):gsub("\\20",""):gsub(DELIMITER_1,"\\19") -- export fix
        end
        return string
    end

	local r
    local soundPatt1 = "^[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee][\\/][Aa][Dd][Dd][Oo][Nn][Ss][\\/]"
	function module:GetExportDataString(data,rc,isExport)

		local WRONG_DATA = CheckDataIntegrity(data)

		if WRONG_DATA then
			print("|cffff8000[Reminder]|r|cffff0000 Can't send reminder:", data.name, data.token)
			return rc
		else
			if data.isPersonal then return rc end
			local triggersData = ""
			if data.triggers and #data.triggers > 0 then
				for i=1,#data.triggers do
					triggersData = triggersData .. module:GetTriggerSyncString(data.triggers[i]) .. DELIMITER_1
				end
			end

            triggersData = triggersData:gsub("%^", "") -- preventing griefed input
            if isExport then
			    triggersData = triggersData:gsub("\\19",""):gsub("\\20",""):gsub(DELIMITER_1,"\\19"):gsub(DELIMITER_2,"\\20")--export fix
            end

			local glowOptions = ""
			if data.nameplateGlow and (data.nameplateText or data.glowType or data.glowColor or data.glowThick or data.glowScale or data.glowN or data.glowImage) then
				glowOptions = (data.nameplateText or "") .. DELIMITER_1 .. (data.glowType or "") .. DELIMITER_1 .. (data.glowColor or "") .. DELIMITER_1 .. (data.glowThick or "") .. DELIMITER_1 .. (data.glowScale or "") .. DELIMITER_1 .. (data.glowN or "") .. DELIMITER_1 .. (data.glowImage or "")
			end
            glowOptions = TruncateOptionsString(glowOptions,isExport)

            local spamOptions = ""
            if data.spamMsg or data.spamType or data.spamChannel then
                spamOptions = (data.spamMsg or "") .. DELIMITER_1 .. (data.spamType or "") .. DELIMITER_1 .. (data.spamChannel or "")
            end
            spamOptions = TruncateOptionsString(spamOptions,isExport)


            local oldTypeOptions = "" -- spellID conditions castnum
            if data.spellID or data.conditions or data.cast then
                oldTypeOptions = (data.spellID or "") .. DELIMITER_1 .. (data.cast  or "") .. DELIMITER_1 .. (data.conditions or "")
            end
            oldTypeOptions = TruncateOptionsString(oldTypeOptions,isExport)


            local checks = GetChecksString(data)
            local classes = GetClassesString(data)
            local roles = GetRolesString(data)

            local loadOptions = ""
            if data.units or data.roles or data.classes or data.notepat then
                loadOptions = (data.units or "") .. DELIMITER_1 .. (roles or "") .. DELIMITER_1 .. (classes or "") .. DELIMITER_1 .. (data.notepat or "")
            end
            loadOptions = TruncateOptionsString(loadOptions,isExport)

            local soundOptions = ""
            if data.sound or data.tts or data.voiceCountdown then
                soundOptions = (type(data.sound) == 'string' and data.sound:gsub("%^", "")
                                :gsub(soundPatt1 .. "SharedMedia","IAOSM"):gsub(soundPatt1 .. "WeakAuras\\Media\\","IAOWA"):gsub(soundPatt1, "IAO")
                                 or data.sound or "")
                                 .. DELIMITER_1 .. (data.tts or "") .. DELIMITER_1 .. (data.voiceCountdown or "")
            end
            soundOptions = TruncateOptionsString(soundOptions,isExport)

			r = r ..
				(
					data.token .. "^" .. -- 100%
					(data.boss or "") .. "^" .. -- 92.43%
					(data.diff or "") .. "^" .. -- 68%
					(data.name or "") .. "^" .. -- 99%
					EVENT_KEYS[data.event] .. "^" .. -- 100%
					(data.msg and data.msg:gsub("%^", "") or "") .. "^" .. -- 96%
					(data.duration or "") .. "^" .. -- 98.3%
					(data.delay and data.delay:gsub("%^", "") or "") .. "^" .. -- 80.5%
                    (oldTypeOptions) .. "^" .. -- 48%
					(data.triggers and #data.triggers or "") .. "^" .. -- 28.5%
					(triggersData) .. "^" .. -- 28.5%
					(checks) .. "^" .. -- 34%
					(loadOptions) .. "^" .. -- 55%
                    (soundOptions) .. "^" .. -- 44%
					(data.glow and data.glow:gsub("%^", "") or "") .. "^" .. -- 10%
					(spamOptions) .. "^" .. -- 6%
					(glowOptions) .. "^" .. -- 2%
					(data.zoneID and string.gsub(tostring(data.zoneID), "%^", "") or "") .. "^" .. -- 3.24%
					(data.countdownType or "") .. "^" .. -- 2.7%
					(data.extraCheck and data.extraCheck:gsub("%^", "") or "") .. "^" .. -- 1%
					(data.specialTarget and data.specialTarget:gsub("%^", "") or "") -- .. "^" .. --0.5%

				):gsub("[%^]+$","") .. -- removing useless ^ at the end
				"\n"
			rc = rc + 1
			VExRT.Reminder.data[data.token].notSync = false
		end
		return rc
	end

	local prevIndex = nil

	function module:SyncCurrent(isExport, data, isStart)
		if not isExport and ((not IsInRaid() or not ExRT.F.IsPlayerRLorOfficer("player")) and not VExRT.Reminder.debugUpdates) then
			print("|cffff8000[Reminder]|r|cffff0000 You are trying to send Reminder data. You are not in Raid or not RL or Assistant|r")
			return
		end
		r = isStart and (SENDER_VERSION .. "^" .. DATA_VERSION .. "\n") or ""
		local rc = 0
		rc = module:GetExportDataString(data,rc,isExport)
		if not isExport then
			VExRT.Reminder.data[data.token].lastSync = time()
		end
		r = r:gsub("\n$","")
		if isExport then
			return r
		end
		if rc > 0 then

			local compressed = LibDeflate:CompressDeflate(r,{level = 9})
			local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
			encoded = encoded .. "##F##"

			print("|cff80ff00|cffff8000[Reminder]|r Sended token count: " .. rc .. "|r")

			local newIndex
			while prevIndex == newIndex do
				newIndex = math.random(100,999)
			end
			prevIndex = newIndex

			newIndex = tostring(newIndex)
			local parts = ceil(#encoded / 240)
			for i=1,parts do
				local msg = encoded:sub( (i-1)*240+1 , i*240 )
				ExRT.F.SendExMsg("reminder","D\t"..newIndex.."\t"..msg)
			end
		else
			print("|cffee5555|cffff8000[Reminder]|r Sended token count: " .. rc .. "|r")
		end
	end

	function module:Sync(isExport,bossID,zoneID)
		if not isExport and ((not IsInRaid() or not ExRT.F.IsPlayerRLorOfficer("player")) and not VExRT.Reminder.debugUpdates) then
			print("|cffff8000[Reminder]|r|cffff0000 You are trying to send Reminder data. You are not in Raid or not RL or Assistant|r")
			return
		end
		r = SENDER_VERSION .. "^" ..DATA_VERSION .. "\n"
		local rc = 0
		local now = time()
		for _,data in pairs(VExRT.Reminder.data) do
			if (not bossID or
                 (data.boss == bossID) or
                 (bossID == -1 and not data.boss and not data.zoneID)
                ) and
				(not zoneID or (tonumber(tostring(data.zoneID):match("^[^, ]+") or "",10) == zoneID))
			then

				rc = module:GetExportDataString(data,rc,isExport)
				if not isExport then
					data.lastSync = now
				end
			end
		end
		r = r:gsub("\n$","")
		if isExport then
			return r
		end

		if rc > 0 then

			local compressed = LibDeflate:CompressDeflate(r,{level = 9})
			local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)

			encoded = encoded .. "##F##"

			print("|cff80ff00|cffff8000[Reminder]|r Sended reminders count: " .. rc .. "|r")

			local newIndex
			while prevIndex == newIndex do
				newIndex = math.random(100,999)
			end
			prevIndex = newIndex


			newIndex = tostring(newIndex)
			local parts = ceil(#encoded / 240)

			--[[
				first check
			[Reminder] Reminder data length:
			total: 193
			encoded: 8970
			decoded: 33397
			encoded per reminder: 46.476683937824
			decoded per reminder 173.0414507772

                v32 first (binary classes and roles)
            [03:46:17] [Reminder] Reminder data length:
            total: 185
            encoded: 8459
            decoded: 30659
            encoded per reminder: 45.724324324324
            decoded per reminder 165.72432432432

                v32 second (added EVENT_KEYS)
            [03:52:52] [Reminder] Reminder data length:
            total: 185
            encoded: 8303
            decoded: 28524
            encoded per reminder: 44.881081081081
            decoded per reminder 154.18378378378

                v32 third (added partial encoding for sound paths)
            [04:57:17] [Reminder] Reminder data length:
            total: 185
            encoded: 8295
            decoded: 27349
            encoded per reminder: 44.837837837838
            decoded per reminder 147.83243243243

                v32 fourth (fixed delimiters sended, stacked spam settings to spamOptions group)
            [07:38:20] [Reminder] Reminder data length:
            total: 185
            encoded: 8253
            decoded: 25890
            encoded per reminder: 44.610810810811
            decoded per reminder 139.94594594595

                v32 fifth (not sending 0 in bit arrays)
            [05:08:28] [Reminder] Reminder data length:
            total: 185
            encoded: 8185
            decoded: 25386
            encoded per reminder: 44.243243243243
            decoded per reminder 137.22162162162

                v32 sixth (stacked more data to 'options' groups)
            [07:26:35] [Reminder] Reminder data length:
            total: 185
            encoded: 8157
            decoded: 25003
            encoded per reminder: 44.091891891892
            decoded per reminder 135.15135135135
			]]

			-- print("|cffff8000[Reminder]|r Reminder data length:","\ntotal:",rc,"\nencoded:",#encoded,"\ndecoded:",#r,"\nencoded per reminder:",#encoded/rc,"\ndecoded per reminder",#r/rc)

			for i = 1, parts do
				local msg = encoded:sub((i - 1) * 240 + 1, i * 240)
				ExRT.F.SendExMsg("reminder", "D\t" .. newIndex .. "\t" .. msg)
			end
		else
			print("|cffee5555|cffff8000[Reminder]|r Sended reminders count: " .. rc .. "|r")
		end
	end

	function module:ProcessTextToData(text,isImport)
        -- NaN in strings from excel workaround
		local text, replaces = text:gsub("%^(NaN)",function() print("|cffff8000[Reminder]|r Found 'NaN' in import string, import data may be incomplete.")return "^" end)
		if replaces > 0 then
			StaticPopupDialogs["EXRT_REMINDER_CORRUPTED_DATA_ALERT"] = {
				text =
				"Found 'NaN' in import string, delete 'NaN' from string and import data or cancel import\n|cffff0000IMPORT DATA MAY BE INCOMPLETE",
				button1 = ACCEPT,
				button2 = CANCEL,
				OnAccept = function()
					module:ProcessTextToData(text, isImport)
				end,
				timeout = 0,
				whileDead = true,
				hideOnEscape = true,
				preferredIndex = 3,
			}
			StaticPopup_Show("EXRT_REMINDER_CORRUPTED_DATA_ALERT")
		else
			local data = {strsplit("\n",text)}

            if data[1] then
                local VER,DATA_VER = strsplit("^",data[1])
                if tonumber(VER or "?") ~= SENDER_VERSION then
                    if tonumber(VER or "0") > SENDER_VERSION then
                        print("|cffff8000[Reminder]|r Your reminder addon version is outdated (string ver."..(DATA_VER or "unk")..", your addon ver."..DATA_VERSION..")")
                    else
                        print("|cffff8000[Reminder]|r Import data is outdated (string ver."..(DATA_VER or "unk")..", your addon ver."..DATA_VERSION..")")
                    end
                    return
                end
            else
                return
            end

			local totalReminders = 0
			local totalUpdated = 0
			local totalNew = 0
			local totalLocked = 0

			local now = time()
			for i=2,#data do

             local token,boss,diff,name,event,text,duration,delay,oldTypeOptions,triggersNum,triggersData,checks,
                    loadOptions,soundOptions,glow,spamOptions,glowOptions,zoneID,countdownType,extraCheck,specialTarget = strsplit("^",data[i])

                token = tonumber(token)
                local triggers
                if triggersNum and tonumber(triggersNum) and tonumber(triggersNum) > 0 then
                    triggers = {}
                end

                --triggersData and glowOptions may be nil when importing old strings
                if triggersData and isImport then
                    triggersData = triggersData:gsub("\\19",DELIMITER_1):gsub("\\20",DELIMITER_2)
                end
                if glowOptions and isImport then
                    glowOptions = glowOptions:gsub("\\19",DELIMITER_1)
                end
                if spamOptions and isImport then
                    spamOptions = spamOptions:gsub("\\19",DELIMITER_1)
                end
                if oldTypeOptions and isImport then
                    oldTypeOptions = oldTypeOptions:gsub("\\19",DELIMITER_1)
                end
                if loadOptions and isImport then
                    loadOptions = loadOptions:gsub("\\19",DELIMITER_1)
                end
                if soundOptions and isImport then
                    soundOptions = soundOptions:gsub("\\19",DELIMITER_1)
                end

                local nameplateText, glowType, glowColor, glowThick, glowScale, glowN, glowImage = strsplit(DELIMITER_1, glowOptions or "")
                local spamMsg ,spamType, spamChannel = strsplit(DELIMITER_1, spamOptions or "")
                local spellID, castnum, conditions = strsplit(DELIMITER_1, oldTypeOptions or "")
                local units, roles, classes, notepat = strsplit(DELIMITER_1, loadOptions or "")
                local sound, tts, voiceCountdown = strsplit(DELIMITER_1, soundOptions or "")


                local new = {
                    token = token,
                    event = EVENT_KEYS[tonumber(event)],
                    boss = tonumber(boss),
                    zoneID = zoneID ~= "" and zoneID or nil,
                    spellID = spellID ~= "" and (tonumber(spellID) or spellID) or nil,
                    delay = delay ~= "" and delay or nil,
                    duration = tonumber(duration),
                    condition = conditions ~= "" and (tonumber(conditions) or conditions) or nil,
                    units = units ~= "" and units or nil,
                    msg = text ~= "" and text or nil,
                    sound = sound ~= "" and (tonumber(sound) or sound:gsub("^IAOSM","Interface\\Addons\\SharedMedia")
                                                :gsub("^IAOWA", "Interface\\AddOns\\WeakAuras\\Media\\")
                                                :gsub("^IAO", "Interface\\AddOns\\")) or nil,
                    voiceCountdown = voiceCountdown ~= "" and tonumber(voiceCountdown) or nil,
                    cast = castnum ~= "" and (tonumber(castnum) or castnum) or nil,
                    name = name ~= "" and name or nil,
                    diff = tonumber(diff),
                    notepat = notepat ~= "" and notepat or nil,
                    tts = tts ~= "" and tts or nil,
                    glow = glow ~= "" and glow or nil,
                    spamType = tonumber(spamType),
                    spamChannel = tonumber(spamChannel),
                    spamMsg = spamMsg ~= "" and spamMsg or nil,
                    countdownType = tonumber(countdownType) or nil,
                    triggers = triggers,
                    extraCheck = extraCheck ~= "" and extraCheck or nil,
                    specialTarget = specialTarget ~= "" and specialTarget or nil,
                    nameplateText = nameplateText ~= "" and nameplateText or nil,
                    glowType = tonumber(glowType),
                    glowColor = glowColor ~= "" and glowColor or nil,
                    glowThick = tonumber(glowThick),
                    glowScale = tonumber(glowScale),
                    glowN = tonumber(glowN),
                    glowImage = glowImage ~= "" and (tonumber(glowImage) or glowImage) or nil,
                }
                checks = tonumber(checks or 0) or 0

                if bit.band(checks,bit.lshift(1,0)) > 0 then new.countdown = true end
                if bit.band(checks,bit.lshift(1,1)) > 0 then new.globalCounter = true end
                if bit.band(checks,bit.lshift(1,2)) > 0 then new.reversed = true end
                if bit.band(checks,bit.lshift(1,3)) > 0 then new.sendEvent = true end
                if bit.band(checks,bit.lshift(1,4)) > 0 then new.nameplateGlow = true end
                if bit.band(checks,bit.lshift(1,5)) > 0 then new.glowOnlyText = true end
                if bit.band(checks,bit.lshift(1,6)) > 0 then new.doNotLoadOnBosses = true end
                if bit.band(checks,bit.lshift(1,7)) > 0 then new.dynamicdisable = true end
                if bit.band(checks,bit.lshift(1,8)) > 0 then new.norewrite = true end
                if bit.band(checks,bit.lshift(1,9)) > 0 then new.copy = true end
                if bit.band(checks,bit.lshift(1,10)) > 0 then new.disabled = true end

                classes = tonumber(classes or 0) or 0

                for j=1,#ExRT.GDB.ClassList do
                    if bit.band(classes,bit.lshift(1,j-1)) > 0 then
                        new.classes = (new.classes or "#") .. ExRT.GDB.ClassList[j] .. "#"
                    end
                end

                roles = tonumber(roles or 0) or 0

                for j=2,#module.datas.rolesList do
                    if bit.band(roles,bit.lshift(1,j-2)) > 0 then
                        new.roles = (new.roles or "#") .. module.datas.rolesList[j][3] .. "#"
                    end
                end


                if isImport then
                    new.notSync = true
                else
                    new.lastSync = now
                end
                if tonumber(spellID) == nil then new.spellID = spellID end

                if triggersNum and tonumber(triggersNum) and tonumber(triggersNum) > 0 then
                    for j=1,tonumber(triggersNum) do
                        local triggerStr = select(j,strsplit(DELIMITER_1,triggersData))
                        local tnew = {event = 1}
                        triggers[j] = tnew

                        local c = 1
                        local keysList

                        local arg = strsplit(DELIMITER_2,triggerStr)
                        while arg do
                            if c == 3 and tnew.event == 1 then
                                arg = cleu_events[arg] or arg
                                tnew[ keysList[1] ] = arg
                                keysList = module.C[arg or 0] and (module.C[arg].triggerSynqFields or module.C[arg].triggerFields)
                            elseif c > 2 then
                                if keysList then
                                    local key = keysList[c-2]
                                    if key then
                                        if checkType[key] then
                                            tnew[key] = arg=="1" and true or nil
                                        elseif numberType[key] then
                                            tnew[key] = arg~="" and tonumber(arg) or nil
                                        elseif mixedType[key] then
                                            tnew[key] = arg~="" and (tonumber(arg) or arg:gsub(STRING_CONVERT.decodePatt,STRING_CONVERT.decodeFunc)) or nil
                                        else
                                            tnew[key] = arg~="" and arg:gsub(STRING_CONVERT.decodePatt,STRING_CONVERT.decodeFunc) or nil
                                        end
                                    end
                                end
                            elseif c == 1 then
                                tnew.event = tonumber(arg)
                                keysList = module.C[tnew.event or 0] and (module.C[tnew.event].triggerSynqFields or module.C[tnew.event].triggerFields)
                            elseif c == 2 then
                                tnew.andor = arg~="" and tonumber(arg) or nil
                            end
                            c = c + 1
                            arg = select(c,strsplit(DELIMITER_2,triggerStr))
                        end
                    end
                end
                totalReminders = totalReminders + 1

                if not VExRT.Reminder.data[token] then
                    totalNew = totalNew + 1
                else
                    if VExRT.Reminder.locked[token] then
                        totalLocked = totalLocked + 1
                    else
                        totalUpdated = totalUpdated + 1
                    end
                end

                if not VExRT.Reminder.data[token] or not VExRT.Reminder.locked[token] then
                    VExRT.Reminder.data[token] = new
                end

			end

			print("|cffff8000[Reminder]|r |cff80ff00Got reminders:",totalReminders)
			if totalUpdated > 0 then
				print("|cffff8000[Reminder]|r |cff00ffffUpdated reminders:",totalUpdated)
			end
			if totalNew > 0 then
				print("|cffff8000[Reminder]|r |cff0080ffNew reminders:",totalNew)
			end
			if totalLocked > 0 then
				print("|cffff8000[Reminder]|r |cffee5555Reminders that can't be updated due to lock:",totalLocked)
			end
			if module.options.lastUpdate then
				module.options.lastUpdate:Update()
			end
			if module.options:IsVisible() and module.options.UpdateData then
				module.options.UpdateData()
			end
			module:ReloadAll()
		end
	end
end


function module:slash(arg)
	arg = arg and type(arg) == 'string' and arg:lower()
	if arg:find("^rem$") or arg:find("^r$") then
		ExRT.Options:Open()
		ExRT.Options:OpenByModuleName("Reminder")
	elseif arg:find("^ra$") then
		ExRT.Options:Open()
		ExRT.Options:OpenByModuleName("NoteAnalyzer")
	end
end

function module:addonMessage(sender, prefix, prefix2, token, ...)
	if prefix == "reminder" then
		if prefix2 == "D" then
			if (not IsInRaid() or not ExRT.F.IsPlayerRLorOfficer(sender)) and not (VExRT.Reminder.debugUpdates and sender == UnitName'player') then
				if not throttleTimer or throttleTimer < GetTime() - 1 then
					throttleTimer = GetTime()
					print("|cffff8000[Reminder]|r |cffff0000" .. sender .. " trying to send Reminder data. Not in Raid or Sender is not RL or Assistant|r")
				end
				return
			end


			if not LastUpdateTimeByThisSender[sender] or LastUpdateTimeByThisSender[sender] < GetTime() - 4 then
				LastUpdateTimeByThisSender[sender] = GetTime()
				print("|cffff8000[Reminder]|r Accepting Reminder data from " .. sender)
			end
			VExRT.Reminder.LastUpdateName = ExRT.F.delUnitNameServer(sender)
			VExRT.Reminder.LastUpdateTime = time()

			local currMsg = table.concat({...}, "\t")
			if tostring(token) == tostring(module.db.msgindex) and type(module.db.lasttext)=='string' then
				module.db.lasttext = module.db.lasttext .. currMsg
			else
				module.db.lasttext = currMsg
			end
			module.db.msgindex = token


			if type(module.db.lasttext)=='string' and module.db.lasttext:find("##F##$") then
				local str = module.db.lasttext:sub(1,-6)
				local decoded = LibDeflate:DecodeForWoWAddonChannel(str)
				local decompressed = LibDeflate:DecompressDeflate(decoded)
				if not decompressed then return end

				local data = {strsplit("\n",decompressed)}
				for i=1,#data do
					local _,syncToken = strsplit("^",data[i])
					if syncToken and VExRT.Reminder.data[syncToken] and tonumber(syncToken) == tonumber(VExRT.Reminder.data[syncToken]) then
						data.notSync = false
					end
				end

				if VExRT.Reminder.disableUpdates then
					print("|cffff8000[Reminder]|r |cffff0000" .. sender .. " trying to send Reminder data. All updates are disabled|r")
					if module.options:IsVisible() and module.options.UpdateData then
						module.options.UpdateData()
					end
					return
				end

				module:ProcessTextToData(decompressed)
				module.db.lasttext = nil
			end
		elseif prefix2 == "RA" then
			if not IsInRaid() or not ExRT.F.IsPlayerRLorOfficer(sender) or VExRT.Reminder.disableUpdates then
				return
			end
			local currMsg = table.concat({...}, "\t")
			if tostring(token) == tostring(module.db.Rmsgindex) and type(module.db.Rlasttext)=='string' then
				module.db.Rlasttext = module.db.Rlasttext .. currMsg
			else
				module.db.Rlasttext = currMsg
			end
			module.db.Rmsgindex = token
			if type(module.db.Rlasttext)=='string' and module.db.Rlasttext:find("##F##$") then
				local str = module.db.Rlasttext:sub(1,-6)
				local tokens = {strsplit("^",str)}
				for i=1,#tokens do
					if VExRT.Reminder.data[ tonumber(tokens[i]) ] and not VExRT.Reminder.locked[ tonumber(tokens[i]) ] then
						local bossName = "BossNamePH"
						if ExRT.is11 then
							bossName = VExRT.Reminder.data[token].boss and L.bossName[ VExRT.Reminder.data[token].boss ] ~= "" and  L.bossName[VExRT.Reminder.data[token].boss] or VExRT.Reminder.data[token].boss or "unk"
						elseif ExRT.isLK then
							bossName = NameByID(VExRT.Reminder.data[token].boss)
						end
						print("|cffff8000[Reminder]|r " .. (bossName or "") .. ": " .. (VExRT.Reminder.data[token].name or "") .. " deleted by " .. sender)

						VExRT.Reminder.data[ tonumber(tokens[i]) ] = nil
					end
				end
				if module.options:IsVisible() and module.options.UpdateData then
					module.options.UpdateData()
				end

				module:ReloadAll()
				module.db.Rlasttext = nil
			end
		elseif prefix2 == "R" then
			if not IsInRaid() or not ExRT.F.IsPlayerRLorOfficer(sender) or VExRT.Reminder.disableUpdates then
				return
			end
			token = tonumber(token)
			if VExRT.Reminder.data[token] and not VExRT.Reminder.locked[token] then
				local bossName = "BossNamePH"
				if ExRT.is11 then
					bossName = VExRT.Reminder.data[token].boss and L.bossName[ VExRT.Reminder.data[token].boss ] ~= "" and  L.bossName[VExRT.Reminder.data[token].boss] or VExRT.Reminder.data[token].boss or "unk"
				elseif ExRT.isLK then
					bossName = NameByID(VExRT.Reminder.data[token].boss)
				end
				print("|cffff8000[Reminder]|r " .. (bossName or "") .. ": " .. (VExRT.Reminder.data[token].name or "") .. " deleted by " .. sender)
				VExRT.Reminder.data[token] = nil
			end

			if module.options:IsVisible() and module.options.UpdateData then
				module.options.UpdateData()
			end

			module:ReloadAll()
		elseif prefix2 == "GRV" then
			token = tonumber(token)
			local data = VExRT.Reminder.data[token]
			if data then
				if data.lastSync then
					ExRT.F.SendExMsg("reminder", "RV\t"..token.."\t"..data.lastSync)
				else
					ExRT.F.SendExMsg("reminder", "RV\t"..token.."\t".."NOLS")
				end
			else
				ExRT.F.SendExMsg("reminder", "RV\t"..token.."\t".."NODATA")
			end
		elseif prefix2 == "RV" then
			local response = ...
			token = tonumber(token)
			module.db.responcesData[ sender ] = module.db.responcesData[ sender ] or {}
			module.db.responcesData[ sender ][token] = module.db.responcesData[ sender ][token] or {}
			module.db.responcesData[ sender ][token].date = tonumber(response) or response or "unk"

		end
	elseif prefix == "ADV" then
		local cmd, arg1 = prefix2, token
		if cmd == "GV" then
			local isEnabled = VExRT.Reminder.enabled and " Enabled" or " Disabled"

			ExRT.F.SendExMsg("ADV", "V\t" .. DATA_VERSION .. isEnabled .. ActiveBossMod)
		elseif cmd == "V" then
			if not sender or not arg1 then
				return
			end
			module.db.gettedVersions[sender] = arg1
		end
	end
end

module.db.gettedVersions = {}
module.db.getVersion = 0

module.db.responcesData = {}

--[[
-- Handle coroutines
local dynFrame = {};
do
-- Internal data
dynFrame.frame = CreateFrame("Frame");
dynFrame.update = {};
dynFrame.size = 0;

-- Add an action to be resumed via OnUpdate
function dynFrame.AddAction(self, name, func)
	if not name then
	name = string.format("NIL", dynFrame.size+1);
	end

	if not dynFrame.update[name] then
	dynFrame.update[name] = func;
	dynFrame.size = dynFrame.size + 1
	dynFrame.frame:Show();
	end
end

-- Remove an action from OnUpdate
function dynFrame.RemoveAction(self, name)
	if dynFrame.update[name] then
	dynFrame.update[name] = nil;
	dynFrame.size = dynFrame.size - 1
	if dynFrame.size == 0 then
		dynFrame.frame:Hide();
	end
	end
end

-- Setup frame
dynFrame.frame:Hide();
dynFrame.frame:SetScript("OnUpdate", function(self, elapsed)
	-- Start timing
	local start = debugprofilestop();
	local hasData = true;

	-- Resume as often as possible (Limit to 16ms per frame -> 60 FPS)
	while (debugprofilestop() - start < 16 and hasData) do
	-- Stop loop without data
	hasData = false;

	-- Resume all coroutines
	for name, func in pairs(dynFrame.update) do
		-- Loop has data
		hasData = true;

		-- Resume or remove
		if coroutine.status(func) ~= "dead" then
		local ok, msg = coroutine.resume(func)
		if not ok then
			geterrorhandler()(msg .. '\n' .. debugstack(func))
		end
		else
		dynFrame:RemoveAction(name);
		end
	end
	end
end);
end

module.dynFrame = dynFrame;

-- Use this to create a coroutine and add coroutine.yield inside a functions you call here
-- module.dynFrame:AddAction("export",coroutine.create(function()
	-- local export = module:Sync(true)
	-- ExRT.F:Export(export)
-- end))
]]
   --
