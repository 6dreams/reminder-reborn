local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ReminderModule: MRTmodule
local module = MRT.A.Reminder
if not module then return end

---@class ELib
local ELib, L = MRT.lib, MRT.L

---@class Locale
local LR = AddonDB.LR

---@alias triggerUnit
--- | "player"
--- | "target"
--- | "focus
--- | "mouseover"
--- | "boss1"
--- | "boss2"
--- | "boss3"
--- | "boss4"
--- | "boss5"
--- | "boss6"
--- | "boss7"
--- | "boss8"
--- | "pet"
--- | 1 # Any Boss
--- | 2 # Any Nameplate
--- | 3 # Any Raid
--- | 4 # Any Party
--- | -1 # Negative numbers are for refering to units of other triggers; -1 is the first trigger, -2 the second, etc.

--- @class triggersData
--- @field event number event name
--- @field eventCLEU string? eventCLEU
--- @field sourceName string? source name
--- @field sourceID string? source id
--- @field sourceUnit triggerUnit? source unit
--- @field sourceMark number? source mark
--- @field targetName string? target name
--- @field targetID string? target id
--- @field targetUnit triggerUnit? target unit
--- @field targetMark number? target mark
--- @field spellID number? spell id
--- @field spellName string? spell name
--- @field extraSpellID number? extra spell id
--- @field stacks number? stacks
--- @field numberPercent number? numberPercent
--- @field pattFind string? pattFind
--- @field bwtimeleft number? bwtimeleft
--- @field counter string? counter
--- @field cbehavior # cbehavior
--- | nil # default global
--- | 1   # CounterSource
--- | 2   # CounterDest
--- | 3   # CounterTriggers
--- | 4   # CounterTriggersPersonal
--- | 5   # CounterGlobalForReminder
--- | 6   # CounterResetIn5Sec
--- @field delayTime string? delayTime
--- @field activeTime number? activeTime
--- @field invert boolean? invert
--- @field guidunit # guidunit 1 - source, nil - target
--- | nil # target
--- | 1   # source
--- @field onlyPlayer boolean? onlyPlayer
--- @field andor # how to connect triggers <br> 1|nil - , 2 - or, 3 or+, 4 ignore
--- | nil # and
--- | 1   # and
--- | 2   # or
--- | 3   # or+
--- | 4   # ignore

--- @class ReminderData
--- @field token number? id for reminders
--- @field name string? name of reminder, main purpose is sorting
--- load by boss|zone
--- @field disabled boolean? disable reminder
--- @field defDisabled boolean? personally disable reminder by default
--- @field zoneID string|number? instanceID, comma separated list of instanceIDs
--- @field boss number? EncounterID
--- @field diff number? difficultyID
--- @field doNotLoadOnBosses boolean? don't load reminder on bosses
--- general
--- @field triggers triggersData[]
--- @field msg string? message to show
--- @field msgSize number? size of message
--- @field duration number? duration of reminder
--- @field delay string? delay of reminder, mm:ss.ms, comma separated list of delays
--- @field countdown boolean? show countdown based on duration
--- @field countdownType number? format of countdown 5 5.3 5.34
--- @field WAmsg string? send a WeakAuras.ScanEvents event
--- @field dynamicdisable boolean? disable dynamic update of reminder, will only format msg on show
--- @field norewrite boolean? don't rewrite reminder if it's already shown
--- @field copy boolean? allow more than one iteration of a reminder
--- load
--- @field classes string? classes
--- @field roles string? roles
--- @field groups string?
--- @field units string? units
--- @field reveresed boolean? inverts load by units
--- @field notepat string? notepat
--- @field noteIsBlock boolean? check for note block instead of note line
--- @field RGAPIList string?
--- @field RGAPICondition string?
--- @field RGAPIOnlyRG boolean?
--- @field RGAPIAlias string? load for specified aliases
--- sounds
--- @field sound string|number? sound
--- @field soundOnHide string|number? soundOnHide
--- @field tts string? tts
--- @field voiceCountdown number? voiceCountdown
--- chat spam
--- @field spamMsg string? spamMsg
--- @field spamType number? spamType
--- @field spamChannel number? spamChannel
--- frame glow
--- @field glow string? name of a unit which nameplate will be glowing
--- @field glowFrameColor string? color of glow in hex format
--- nameplate glow
--- @field nameplateGlow boolean? show glow on nameplate
--- @field nameplateText string? text to show on nameplate
--- @field glowOnlyText boolean? show only text on nameplate
--- @field glowType number? type of glow
--- @field glowColor string? color of glow in hex format
--- @field glowThick number? thickness of glow
--- @field glowScale number? scale of glow
--- @field glowN number? number of glow
--- @field glowImage string? image of glow
--- custom
--- @field sametargets boolean? show reminder only if trigger units are the same
--- @field extraCheck string? extraCheck before reminder activation
--- @field specialTarget string? sets special guid for reminder
--- @field comment string?
--- misc
--- @field notSync boolean|number? shows the status of reminder false is sent, true is not sent, 2 is duplicated
--- @field lastSync number? last time reminder was sent
--- @field isPersonal boolean? if true reminder will never be sent


module.datas = {
    newReminderTemplate = {
        triggers = {
            {event = 3}
        },
        countdown = true,
    },
	countdownType = {
		{1,"5"," %d"},
		{nil,"5.3"," %.1f"},
		{3,"5.32"," %.2f"},
	},
	messageSize = {
        {nil,LR.DefText},
        {1,LR.SmallText},
	    {2,LR.BigText},
        {3,LR["Progress Bar"]},
        {4,LR["Small Progress Bar"]},
        {5,LR["Big Progress Bar"]},
	},
	rolesList = {
		{1,LR.RolesTanks,"TANK",1,"roleicon-tiny-tank"},
		{2,LR.RolesHeals,"HEALER",2,"roleicon-tiny-healer"},
		{3,LR.RolesDps,"DAMAGER",4,"roleicon-tiny-dps"},
		{4,LR.RolesMheals,"MHEALER",8,"roleicon-tiny-healer"},
		{5,LR.RolesRheals,"RHEALER",16,"roleicon-tiny-healer"},
		{7,LR.RolesMdps,"MDD",32,"roleicon-tiny-dps"},
		{8,LR.RolesRdps,"RDD",64,"roleicon-tiny-dps"},
	},
	events = {
		1, 2, 3, 6, 7, 4, 5, 11, 8, 9, 10, 12, 13, 14, 16, 15, 19, 17, 18, 20
	},
	counterBehavior = {
		{nil,LR.GlobalCounter,LR.GlobalCounterTip},
		{1,LR.CounterSource,LR.CounterSourceTip},
		{2,LR.CounterDest,LR.CounterDestTip},
		{3,LR.CounterTriggers,LR.CounterTriggersTip},
		{4,LR.CounterTriggersPersonal,LR.CounterTriggersPersonalTip},
		{5,LR["Global counter for reminder"],LR.CounterGlobalForReminderTip},
		{6,LR["Reset in 5 sec"],LR.CounterResetIn5SecTip},
	},
	units = {
		{nil,"-"},
		{"player",STATUS_TEXT_PLAYER or "Player"},
		{"target",TARGET or "Target"},
		{"focus",LR.Focus},
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
		{1,LR.AnyBoss},
		{2,LR.AnyNameplate},
		{3,LR.AnyRaid},
		{4,LR.AnyParty},
	},
	marks = {
		{nil,"-"},
		{0,LR["No Mark"]},
		{1,MRT.F.GetRaidTargetText(1,20)},
		{2,MRT.F.GetRaidTargetText(2,20)},
		{3,MRT.F.GetRaidTargetText(3,20)},
		{4,MRT.F.GetRaidTargetText(4,20)},
		{5,MRT.F.GetRaidTargetText(5,20)},
		{6,MRT.F.GetRaidTargetText(6,20)},
		{7,MRT.F.GetRaidTargetText(7,20)},
		{8,MRT.F.GetRaidTargetText(8,20)},
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
	},
	unitsList = {
		{"boss1","boss2","boss3","boss4","boss5","arena1","arena2","arena3","arena4","arena5","arenapet1","arenapet2","arenapet3","arenapet4","arenapet5","npc"},
		{"nameplate1","nameplate2","nameplate3","nameplate4","nameplate5","nameplate6","nameplate7","nameplate8","nameplate9","nameplate10",
			"nameplate11","nameplate12","nameplate13","nameplate14","nameplate15","nameplate16","nameplate17","nameplate18","nameplate19","nameplate20",
			"nameplate21","nameplate22","nameplate23","nameplate24","nameplate25","nameplate26","nameplate27","nameplate28","nameplate29","nameplate30",
			"nameplate31","nameplate32","nameplate33","nameplate34","nameplate35","nameplate36","nameplate37","nameplate38","nameplate39","nameplate40"},
		{"raid1","raid2","raid3","raid4","raid5","raid6","raid7","raid8","raid9","raid10",
			"raid11","raid12","raid13","raid14","raid15","raid16","raid17","raid18","raid19","raid20",
			"raid21","raid22","raid23","raid24","raid25","raid26","raid27","raid28","raid29","raid30",
			"raid31","raid32","raid33","raid34","raid35","raid36","raid37","raid38","raid39","raid40"},
		{"player","party1","party2","party3","party4"},
		ALL = {"boss1","boss2","boss3","boss4","boss5","arena1","arena2","arena3","arena4","arena5","arenapet1","arenapet2","arenapet3","arenapet4","arenapet5","npc",
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
    instance_difficulty_types = {}, -- create later
    soundsList = {}, -- create later
}

for _,v in next, module.datas.vcountdowns do
	if v[3] then
		module.datas.vcdsounds[ v[1] ] = v[3]
	end
end
for _,v in next, module.datas.glowImages do
	if v[3] then
		module.datas.glowImagesData[ v[1] ] = v
	end
end

C_Timer.After(0,function()
    for name, path in MRT.F.IterateMediaData("sound") do
        module.datas.soundsList[#module.datas.soundsList + 1] = {
            path,
            name,
        }
    end

    sort(module.datas.soundsList,function(a,b) return a[2]<b[2] end)
    tinsert(module.datas.soundsList,1,{nil,"-"})
end)


if MRT.clientVersion > 40000 then
    -- Fill out instance_difficulty_types automatically.
    -- Unfortunately the names BLizzard gives are not entirely unique,
    -- so try hard to disambiguate them via the type, and if nothing works by
    -- including the plain id.

    local unused = {}

    local instance_difficulty_names = {
        [1] = LR["Dungeon (Normal)"],
        [2] = LR["Dungeon (Heroic)"],
        [3] = LR["10 Player Raid (Normal)"],
        [4] = LR["25 Player Raid (Normal)"],
        [5] = LR["10 Player Raid (Heroic)"],
        [6] = LR["25 Player Raid (Heroic)"],
        [7] = LR["Legacy Looking for Raid"],
        [8] = LR["Mythic Keystone"],
        [9] = LR["40 Player Raid"],
        [11] = LR["Scenario (Heroic)"],
        [12] = LR["Scenario (Normal)"],
        [14] = LR["Raid (Normal)"],
        [15] = LR["Raid (Heroic)"],
        [16] = LR["Raid (Mythic)"],
        [17] = LR["Looking for Raid"],
        [18] = unused, -- Event Raid
        [19] = unused, -- Event Party
        [20] = unused, -- Event Scenario
        [23] = LR["Dungeon (Mythic)"],
        [24] = LR["Dungeon (Timewalking)"],
        [25] = unused, -- World PvP Scenario
        [29] = unused, -- PvEvP Scenario
        [30] = unused, -- Event Scenario
        [32] = unused, -- World PvP Scenario
        [33] = LR["Raid (Timewalking)"],
        [34] = unused, -- PvP
        [38] = LR["Island Expedition (Normal)"],
        [39] = LR["Island Expedition (Heroic)"],
        [40] = LR["Island Expedition (Mythic)"],
        [45] = LR["Island Expeditions (PvP)"],
        [147] = LR["Warfront (Normal)"],
        [148] = LR["20 Player Raid"],
        [149] = LR["Warfront (Heroic)"],
        [152] = LR["Visions of N'Zoth"],
        [150] = unused, -- Normal Party
        [151] = unused, -- LfR
        [153] = unused, -- Teeming Islands
        [167] = LR["Torghast"],
        [168] = LR["Path of Ascension: Courage"],
        [169] = LR["Path of Ascension: Loyalty"],
        [171] = LR["Path of Ascension: Humility"],
        [170] = LR["Path of Ascension: Wisdom"],
        [172] = unused, -- World Boss
        [173] = LR["Normal Party"],
        [174] = LR["Heroic Party"],
        [175] = LR["10 Player Raid"],
        [176] = LR["25 Player Raid"],
        [192] = LR["Dungeon (Mythic+)"], -- "Challenge Level 1"
        [193] = LR["10 Player Raid (Heroic)"],
        [194] = LR["25 Player Raid (Heroic)"],
        [205] = LR["Follower Dungeon"],
        [208] = LR["Delve"],
        [216] = LR["Quest Party"],
        [220] = LR["Story Raid"]
    }

    for i = 1, 220 do
        local name, type = GetDifficultyInfo(i)
        if name then
            if instance_difficulty_names[i] then
                if instance_difficulty_names[i] ~= unused then
                    module.datas.instance_difficulty_types[i] = instance_difficulty_names[i]
                end
            else
                module.datas.instance_difficulty_types[i] = name
                -- prettyPrint(string.format("Unknown difficulty id found. You are probably running an outdated version. Debug Information: %s %s %s", i, name, type))
            end
        end
    end
end

module.C = {
	[1] = {
		id = 1,
		name = "COMBAT_LOG_EVENT_UNFILTERED",
		lname = LR.CombatLog,
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
		lname = LR.CastStart,
		events = {"SPELL_CAST_START","SPELL_EMPOWER_START"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","sourceID","sourceMark","spellName","invert"},
		replaceres = {"sourceName","sourceMark","sourceGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_CAST_SUCCESS"] = {
		main_id = 1,
		subID = 2,
		lname = LR.CastDone,
		events = {"SPELL_CAST_SUCCESS","SPELL_EMPOWER_END"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_AURA_APPLIED"] = {
		main_id = 1,
		subID = 3,
		lname = LR.AuraAdd,
		events = {"SPELL_AURA_APPLIED","SPELL_AURA_APPLIED_DOSE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","stacks","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","stacks","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","counter","guid"},
	},
	["SPELL_AURA_REMOVED"] = {
		main_id = 1,
		subID = 4,
		lname = LR.AuraRem,
		events = {"SPELL_AURA_REMOVED","SPELL_AURA_REMOVED_DOSE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","guidunit","stacks","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","stacks","invert","guidunit","onlyPlayer","targetRole"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","counter","guid"},
	},
	["SPELL_DAMAGE"] = {
		main_id = 1,
		subID = 5,
		lname = LR.SpellDamage,
		events = {"SPELL_DAMAGE","RANGE_DAMAGE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_PERIODIC_DAMAGE"] = {
		main_id = 1,
		subID = 6,
		lname = LR.SpellDamageTick,
		events = "SPELL_PERIODIC_DAMAGE",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SWING_DAMAGE"] = {
		main_id = 1,
		subID = 7,
		lname = LR.MeleeDamage,
		events = "SWING_DAMAGE",
		triggerFields = {"eventCLEU","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellID",spellID=LR.ReplacerspellIDSwing,"counter","guid"},
	},
	["SPELL_HEAL"] = {
		main_id = 1,
		subID = 8,
		lname = LR.SpellHeal,
		events = "SPELL_HEAL",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_PERIODIC_HEAL"] = {
		main_id = 1,
		subID = 9,
		lname = LR.SpellHealTick,
		events = "SPELL_PERIODIC_HEAL",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_ABSORBED"] = {
		main_id = 1,
		subID = 10,
		lname = LR.SpellAbsorb,
		events = "SPELL_ABSORBED",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_ENERGIZE"] = {
		main_id = 1,
		subID = 11,
		lname = LR.CLEUEnergize,
		events = {"SPELL_ENERGIZE","SPELL_PERIODIC_ENERGIZE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellIDSpellDmg,"counter","guid"},
	},
	["SPELL_MISSED"] = {
		main_id = 1,
		subID = 12,
		lname = LR.CLEUMiss,
		events = {"SPELL_MISSED","RANGE_MISSED","SPELL_PERIODIC_MISSED"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		fieldNames = {["pattFind"]=LR.MissType},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","pattFind","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["UNIT_DIED"] = {
		main_id = 1,
		subID = 13,
		lname = LR.Death,
		events = {"UNIT_DIED","UNIT_DESTROYED"},
		triggerFields = {"eventCLEU","targetName","targetID","targetUnit","targetMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","targetMark","invert"},
		replaceres = {"targetName","targetMark","targetGUID","counter","guid"},
	},
	["SPELL_SUMMON"] = {
		main_id = 1,
		subID = 14,
		lname = LR.Summon,
		events = {"SPELL_SUMMON","SPELL_CREATE"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","counter","guid"},
	},
	["SPELL_DISPEL"] = {
		main_id = 1,
		subID = 15,
		lname = LR.Dispel,
		events = {"SPELL_DISPEL","SPELL_STOLEN"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID","counter","guid"},
	},
	["SPELL_AURA_BROKEN_SPELL"] = {
		main_id = 1,
		subID = 16,
		lname = LR.CCBroke,
		events = {"SPELL_AURA_BROKEN_SPELL","SPELL_AURA_BROKEN"},
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID",extraSpellID=LR.ReplacerextraSpellID,"counter","guid"},
	},
	["ENVIRONMENTAL_DAMAGE"] = {
		main_id = 1,
		subID = 17,
		lname = LR.EnvDamage,
		events = "ENVIRONMENTAL_DAMAGE",
		triggerFields = {"eventCLEU","spellID","targetName","targetID","targetUnit","targetMark","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","targetMark","invert"},
		replaceres = {"targetName","targetMark","targetGUID","spellName","counter","guid"},
	},
	["SPELL_INTERRUPT"] = {
		main_id = 1,
		subID = 18,
		lname = LR.Interrupt,
		events = "SPELL_INTERRUPT",
		triggerFields = {"eventCLEU","spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","extraSpellID","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"eventCLEU","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","spellName","extraSpellID","invert","guidunit"},
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","extraSpellID","counter","guid"},
	},
	[2] = {
		id = 2,
		name = "BOSS_PHASE",
		lname = LR.BossPhase,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage"},
		isUntimed = true,
		isUnits = false,
		triggerFields = {"pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"pattFind"},
		fieldNames = {["pattFind"]=LR.BossPhaseLabel},
		triggerSynqFields = {"pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		help = LR.BossPhaseTip,
		replaceres = {"phase","counter"},
	},
	[3] = {
		id = 3,
		name = "BOSS_START",
		lname = LR.BossPull,
		isUntimed = false,
		isUnits = false,
		triggerFields = {"delayTime","activeTime","invert"},
		triggerSynqFields = {"delayTime","activeTime","invert"},
	},
	[4] = {
		id = 4,
		name = "UNIT_HEALTH",
		lname = LR.Health,
		events = "UNIT_HEALTH",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.HealthTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReplacertargetGUID,"health","value","counter"},
	},
	[5] = {
		id = 5,
		name = "UNIT_POWER_FREQUENT",
		lname = LR.Mana,
		events = "UNIT_POWER_FREQUENT",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.ManaTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReplacertargetGUID,"health",health=LR.Replacerhealthenergy,"value",value=LR.Replacervalueenergy,"counter"},
	},
	[6] = {
		id = 6,
		name = "BW_MSG",
		lname = LR.BWMsg,
		events = {"BigWigs_Message","DBM_Announce"},
		isUntimed = false,
		isUnits = false,
		triggerFields = {"pattFind","spellID","counter","cbehavior","delayTime","activeTime","invert"},
        fieldTooltips = {["pattFind"]=LR.SearchStringTip},
		alertFields = {0,"pattFind","spellID"},
		triggerSynqFields = {"spellID","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		replaceres = {"spellID","spellName",spellName=LR.ReplacerspellNameBWMsg,"counter"},
	},
	[7] = {
		id = 7,
		name = "BW_TIMER",
		lname = LR.BWTimer,
		events = {"BigWigs_StartBar","BigWigs_StopBar","BigWigs_PauseBar","BigWigs_ResumeBar","BigWigs_StopBars","BigWigs_OnBossDisable","DBM_TimerStart","DBM_TimerStop","DBM_TimerPause","DBM_TimerResume","DBM_TimerUpdate","DBM_kill","DBM_kill"},
		isUntimed = false,
		isUnits = false,
		extraDelayTable = true,
		triggerFields = {"pattFind","spellID","bwtimeleft","counter","cbehavior","delayTime","activeTime","invert"},
        fieldTooltips = {["pattFind"]=LR.SearchStringTip},
		alertFields = {"bwtimeleft",0,"pattFind","spellID"},
		triggerSynqFields = {"bwtimeleft","spellID","pattFind","counter","cbehavior","delayTime","activeTime","invert"},
		replaceres = {"spellID","spellName",spellName=LR.ReplacerspellNameBWTimer,"timeLeft","counter"},
	},
	[8] = {
		id = 8,
		name = "CHAT_MSG",
		lname = LR.Chat,
		events = {"CHAT_MSG_RAID_WARNING","CHAT_MSG_MONSTER_YELL","CHAT_MSG_MONSTER_EMOTE","CHAT_MSG_MONSTER_SAY","CHAT_MSG_MONSTER_WHISPER","CHAT_MSG_RAID_BOSS_EMOTE","CHAT_MSG_RAID_BOSS_WHISPER","CHAT_MSG_RAID","CHAT_MSG_RAID_LEADER","CHAT_MSG_PARTY","CHAT_MSG_PARTY_LEADER","CHAT_MSG_WHISPER"},
		isUntimed = false,
		isUnits = false,
		triggerFields = {"pattFind","sourceName","sourceID","sourceUnit","targetName","targetUnit","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"pattFind"},
		triggerSynqFields = {"pattFind","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","targetUnit","sourceID","invert"},
		help = LR.ChatHelp,
		replaceres = {"sourceName","targetName","text","counter"},
	},
	[9] = {
		id = 9,
		name = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
		lname = LR.BossFrames,
		events = "INSTANCE_ENCOUNTER_ENGAGE_UNIT",
		isUntimed = false,
		isUnits = false,
		triggerFields = {"targetName","targetID","targetUnit","counter","cbehavior","delayTime","activeTime","invert"},
		triggerSynqFields = {"counter","cbehavior","delayTime","activeTime","targetName","targetUnit","targetID","invert"},
		replaceres = {"targetName","guid",guid=LR.ReplacertargetGUID,"counter"},
	},
	[10] = {
		id = 10,
		name = "UNIT_AURA",
		lname = LR.Aura,
		events = "UNIT_AURA",
		isUntimed = true,
		isUnits = true,
		extraDelayTable = true,
		unitField = "targetUnit",
		triggerFields = {"spellID","spellName","sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","targetRole","stacks","bwtimeleft","onlyPlayer","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"targetUnit",0,"spellID","spellName"},
		triggerSynqFields = {"targetUnit","spellID","counter","cbehavior","delayTime","activeTime","sourceName","sourceUnit","targetName","sourceID","sourceMark","targetID","targetMark","spellName","stacks","bwtimeleft","invert","onlyPlayer","targetRole"},
		help = LR.AuraTip,
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","spellName","spellID","stacks","timeLeft","counter","guid","auraValA","auraValB","auraValC"},
	},
	[11] = {
		id = 11,
		name = "UNIT_ABSORB_AMOUNT_CHANGED",
		lname = LR.Absorb,
		events = "UNIT_ABSORB_AMOUNT_CHANGED",
		isUntimed = true,
		isUnits = true,
		unitField = "targetUnit",
		triggerFields = {"targetName","targetID", "targetUnit", "targetMark","numberPercent","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"numberPercent","targetUnit"},
		fieldNames = {["numberPercent"]=LR.AbsorbLabel},
		triggerSynqFields = {"numberPercent","targetUnit","counter","cbehavior","delayTime","activeTime","targetName","targetID","targetMark","invert"},
		help = LR.AbsorbTip,
		replaceres = {"targetName","targetMark","guid",guid=LR.ReplacertargetGUID,"value",value=LR.Replacervalueabsorb,"counter"},
	},
	[12] = {
		id = 12,
		name = "UNIT_TARGET",
		lname = LR.CurTarget,
		events = {"UNIT_TARGET","UNIT_THREAT_LIST_UPDATE"},
		isUntimed = true,
		isUnits = true,
		unitField = "sourceUnit",
		triggerFields = {"sourceName","sourceID","sourceUnit","sourceMark","targetName","targetID","targetUnit","targetMark","guidunit","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {"sourceUnit"},
		triggerSynqFields = {"sourceUnit","counter","cbehavior","delayTime","activeTime","sourceName","targetName","targetUnit","sourceID","sourceMark","targetID","targetMark","invert","guidunit"},
		help = LR.CurTargetTip,
		replaceres = {"sourceName","sourceMark","sourceGUID","targetName","targetMark","targetGUID","counter","guid"},
	},
	[13] = {
		id = 13,
		name = "CDABIL",
		lname = LR.SpellCD,
		events = "SPELL_UPDATE_COOLDOWN",
		tooltip = LR.SpellCDTooltip,
		isUntimed = true,
		isUnits = false,
		triggerFields = {"spellID","spellName","bwtimeleft","counter","cbehavior","delayTime","activeTime","invert"},
		alertFields = {0,"spellID","spellName"},
		triggerSynqFields = {"spellID","counter","cbehavior","delayTime","activeTime","spellName","bwtimeleft","invert"},
		help = LR.SpellCDTip,
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
		lname = LR["Note timers"],
		isUntimed = true,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage","COMBAT_LOG_EVENT_UNFILTERED"},
		triggerFields = {"bwtimeleft","activeTime","invert"},
		triggerSynqFields = {"bwtimeleft","activeTime","invert"},
		help = "Automatic timers for all lines from MRT note with players name and {time:x:xx} template.",
		replaceres = {"textNote","textModIcon:X:Y","fullLine","fullLineClear","phase","spellName","targetName"},
	},
	[18] = {
		id = 18,
		name = "NOTE_TIMERS_ALL",
		lname = LR["Note timers [all]"],
		isUntimed = true,
		events = {"BigWigs_Message","BigWigs_SetStage","DBM_SetStage","COMBAT_LOG_EVENT_UNFILTERED"},
		triggerFields = {"bwtimeleft","activeTime","invert"},
		triggerSynqFields = {"bwtimeleft","activeTime","invert"},
		help = "Automatic timers for all lines from MRT note with {time:x:xx} template.",
		replaceres = {"textNote","textModIcon:X:Y","fullLine","fullLineClear","phase","spellName","targetName"},
	},
	[19] = {
		id = 19,
		name = "RAID_GROUP_NUMBER",
		lname = LR["Raid group number"],
		events = {"GROUP_ROSTER_UPDATE"},
		isUntimed = true,
		isUnits = true,
		unitField = "",
		triggerFields = {"stacks","pattFind","sourceName","sourceUnit","invert"},
		fieldNames = {["stacks"]=LR["Raid group number"],["pattFind"]=LR["notePattern"]},
		alertFields = {0,"sourceUnit","sourceName","pattFind"},
		triggerSynqFields = {"stacks","sourceName","sourceUnit","invert","pattFind"},
		help = "Always active trigger.\nCan be used to query unit as name in another triggers.",
		replaceres = {"sourceName","sourceGUID","stacks",stacks=LR["Raid group number"],"guid"},
	},
    [20] = {
		id = 20,
		name = "MPLUS_START",
		lname = LR["QS_20"],
		isUntimed = false,
		isUnits = false,
		triggerFields = {"delayTime","activeTime","invert"},
		triggerSynqFields = {"delayTime","activeTime","invert"},
	},
}

module:CreateListOfReplacers()

module.SetupFrameDataRequirements = {
    [1] = {0,"msg","spamMsg","nameplateGlow","sound","tts","glow","soundOnHide","voiceCountdown","WAmsg"},--0 значит достаточно любого из следующих значений

    --exception: значит что условие не должно проверяться когда значение exception == true
    [2] = {"duration"},

    --имяПоля = {...} означает что ... проверяеться когда имяПоля есть в дате
    ["spamMsg"] = {"spamType","spamChannel"},
    ["spamType"] = {"spamMsg","spamChannel"},
    ["spamChannel"] = {"spamMsg","spamType"},

    --условия для проверки триггеров прописаны в module.C >>> 'alertFields'
}
