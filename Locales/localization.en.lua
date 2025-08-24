---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

AddonDB.LR = {}
---@class Locale
local LR = AddonDB.LR

if AddonDB.IsDev then
    setmetatable(LR, {__index = function(self, key)
        --print if translation is missing
        print("Missing translation for key: "..key)
        -- print(debugstack())
        self[key] = (key or "")
        VMRT.Reminder.missingLocale = VMRT.Reminder.missingLocale or {}
        tInsertUnique(VMRT.Reminder.missingLocale, key)
        return key
    end})
else
    setmetatable(LR, {__index = function(self, key)
        self[key] = (key or "")
        return key
    end})
end

-- add slash cmd that will use MRT.F.Export(str) to export all missing locale strings

local function ExportMissingLocale()
    local missingLocale = VMRT.Reminder.missingLocale
    if not missingLocale then return end
    for i=1, #missingLocale do
        missingLocale[i] = missingLocale[i]:gsub("|", "||")
        if missingLocale[i]:find("\n") then
            missingLocale[i] = "LR[ [[" .. missingLocale[i].."]] ] = [[".. missingLocale[i].."]]"
        else
            missingLocale[i] = "LR[\"" .. missingLocale[i].."\"] = \"".. missingLocale[i].."\""
        end
    end
    MRT.F:Export(table.concat(missingLocale, "\n"))
    wipe(missingLocale)
end

SlashCmdList["REMINDER_EXPORT_MISSING_LOCALE"] = ExportMissingLocale
SLASH_REMINDER_EXPORT_MISSING_LOCALE1 = "/reminderlocale"



LR.OutlinesNone = "NONE"
LR.OutlinesNormal = "OUTLINE"
LR.OutlinesThick = "THICK OUTLINE"
LR.OutlinesMono = "MONOCHROME"
LR.OutlinesMonoNormal = "MONOCHROME, OUTLINE"
LR.OutlinesMonoThick = "MONOCHROME, THICK OUTLINE"

LR.RolesTanks = "Tanks"
LR.RolesHeals = "Heals"
LR.RolesMheals = "MHeals"
LR.RolesMhealsTip = "Melee healers are Holy Paladin and Mistweaver Monk"
LR.RolesRheals = "RHeals"
LR.RolesRhealsTip = "Ranged healers"
LR.RolesDps = "Dps"
LR.RolesRdps = "RDps"
LR.RolesMdps = "MDps"

LR.spamType1 = "Chat Spam with countdown"
LR.spamType2 = "Chat Spam"
LR.spamType3 = "Chat Single message"

LR.spamChannel1 = "Say"
LR.spamChannel2 = "|cffff4040Yell|r"
LR.spamChannel3 = "|cff76c8ffParty|r"
LR.spamChannel4 = "|cffff7f00Raid|r"
LR.spamChannel5 = "Self chat(print)"

LR.Reminders = "Reminders"
LR["Settings"] = "Settings"
LR["Help"] = "Help"
LR.Versions = "Versions"
LR.Trigger = "Trigger "
LR.AddTrigger = "Add Trigger"
LR.DeleteTrigger = "Delete Trigger"
LR.Source = "Source"
LR.Target = "Target"
LR.YellowAlertTip = "|cffff0000Reminder's duration or trigger's active time\n should not be 0 in reminder without 'untimed' triggers\n\nSet active time in not untimed triggers|r"
LR.EnvironmentalDMGTip = "1 - Falling\n2 - Drowning\n3 - Fatigue\n4 - Fire\n5 - Lava\n6 - Slime"
LR.DifficultyID = "Difficulty ID:"
LR.Difficulty = "Difficulty:"
LR.EncounterID = "Encounter ID:"
LR.CountdownFormat = "Countdown Format:"
LR.AddTextReplacers = "Add Text Replacements"
LR["replaceDropDownTip"] = "|cffffffffThis is a list of available text replacement templates.\nYou can use them in message text,\nTTS, chat spam, frame glow, text on nameplate,\nWeakAuras event message and extra activation condition.\n\nThe contents may vary depending on the selected triggers"
LR.WAmsgTip = "The reminder will send events for WeakAuaras.\nArguments for |cff55ee55WeakAuras.ScanEvents|r are separated by spaces."
LR.WAmsg = "WeakAuras event:"
LR.GlowTip = "\nPlayer name or |cffff0000{targetName}|r or |cffff0000{sourceName}|r\n|cffff0000{SourceName|cff80ff001|r}|r to specify trigger"
LR.SpamType = "Message Type:"
LR.SpamChannel = "Chat Channel:"
LR.spamMsg = "Chat Message:"
LR.ReverseTip = "Reverse load by player names"
LR.Reverse = "Reverse"
LR.Manually = "Manually"
LR.ManuallyTip = "Set custom encounter ID, difficulty ID or Instance ID"
LR.WipePulls = "Clear History"
LR.DungeonHistory = "Dungeon History"
LR.RaidHistory = "Raid History"
LR.Duplicated = "Duplicated"
LR.ListNotSentTip = "Not sent"
LR.ClearImport = "You are 'clear' importing data\n|cffff0000All old reminders will be deleted|r"
LR.ForceRemove = "Are you sure you want force delete all reminders from 'removed list'"
LR.ClearRemove = "Are you sure you want to clear 'removed list'?"
LR.CenterByX = "Center by X"
LR.CenterByY = "Center by Y"
LR.EnableHistory = "Record history"
LR.EnableHistoryRaid ="Record history in raids"
LR.EnableHistoryDungeon = "Record history in dungeons"

LR.chkEnableHistory = "Record pulls history"
LR.chkEnableHistoryTip = "Responsible for recording pull history for the Quick Setup window.\nIf disabled, events from the last pull will still be displayed.\n|cffff0000***Saved fights by this feature require more memory.\n**On turn off the recorded pulls are deleted from memory"
LR.Add = "Add"
LR.SendAll = "Send All"
LR.Boss = "Boss: "

LR.Name = "Name:"
LR.delayTip = "Show reminder X seconds after all triggers conditions are met.\nCan be blank - instant reminder activation\nYou can use minute format, examples: |cff00ff001:30.5|r - will be active in 90.5 seconds.\nYou can specify more than one comma separated."
LR.delayTimeTip = "Can be blank - instant trigger activation\nYou can use minute format, examples: |cff00ff001:30.5|r - will be active in 90.5 seconds.\nYou can specify more than one comma separated.\nYou can use |cff00ff00NOTE|r - will grab delay time from note pattern ({time:x:xx})"
LR.delayText = "Show after:"
LR.duration = "Duration, sec.:"
LR.durationTip = [[Duration of text/glow/chat spam.

If duration equals 0 then reminder will be untimed, meaning
it will be shown while all triggers are active]]
LR.countdown = "Countdown:"
LR.msg = "On-Screen Message:"
LR.sound = "On Show Sound:"
LR.soundOnHide = "On Hide Sound:"
LR.voiceCountdown = "Voice Countdown:"
LR.AllPlayers = "All Players"
LR.notePatternEditTip = "See Help - Loading by Note"

LR.notePattern = "Note pattern:"
LR.save = "Save"
LR.QuickSetup = "Show History"

LR.IgnoreTrigger = "Ignore trigger(use only filters)"

LR.QS_PhaseRepeat = "Phase Repeat "
LR["QS_1"] = "Combat Log"
LR["QS_SPELL_CAST_START"] = "Cast Start"
LR["QS_SPELL_CAST_SUCCESS"] = "Cast Success"
LR["QS_SPELL_AURA_APPLIED"] = "AURA APLIED"
LR["QS_SPELL_AURA_REMOVED"] = "AURA REMOVED"
LR["QS_2"] = "Boss Phase"
LR["QS_3"] = "Boss Pull"
LR["QS_8"] = "Chat"
LR["QS_9"] = "New Frame"
LR["QS_0"] = "Encounter end"

LR["Fight timer"] = "Fight timer:"
LR["Fight started"] = "Fight started:"

LR.Always = "Always"

LR.SingularExportTip = "You can add more reminders to the export window by clicking on the export button"

LR.DeleteSection = "Delete all unlocked in this section"
LR.NoName = "Unnamed"
LR.RemoveSection = "Delete this section\nAll unlocked reminders will be deleted"
LR.PersonalDisable = "Disable this reminder for yourself"
LR.PersonalEnable = "Enable this reminder for yourself"
LR.UpdatesDisable = "Disable updates for this reminder"
LR.UpdatesEnable = "Enable updates for this reminder"
LR.SoundDisable = "Disable sound and tts for this reminder"
LR["SoundUpdatesDisable"] = "Disable sound and tts updates for this reminder"
LR.Listduplicate ="Dupl."
LR.Listdelete = "Delete"
LR.ListdeleteTip = "Delete\n|cffffffffHold shift to delete\nwithout confirmation"
LR.ListdExport = "Export"
LR.ListdSend = "Send"

LR["Enabled"] = "Enable"
LR["EnabledTip"] = "Enable/disable reminder\nTransmitted when sending a reminder\n\nThis setting has priority over the personal enable/disable setting"

LR["Default State"] = "Default State"
LR["Default StateTip"] = "Affects personal enable/disable reminder\n\nEnabled - reminder will be enabled by default\nDisabled - reminder will be disabled by default\n\nUse if you want to let users decide to enable or disable the reminder but think that most of them will want it disabled"

LR.DeleteAll = "Delete All"
LR.ExportAll = "Export All"
LR.Import = "Import"
LR.Export = "Export"
LR.ImportTip = "If you click with the Shift key pressed, then a clean installation will occur. All old reminders will be removed."

LR.DisableSound = "Disable sound"
LR.Font = "Font"
LR.Outline = "Outline"
LR.Strata = "Strata"
LR.Justify = "Align"

LR.OutlineChk = "Font with shadow"
LR.CenterXTip = "Align horizontally"
LR.CenterYTip = "Align vertically"

LR.GlobalCounter = "Global Default"
LR.CounterSource = "Per Source"
LR.CounterDest = "Per Target"
LR.CounterTriggers = "Trigger Overlap"
LR.CounterTriggersPersonal = "Trigger Overlap with Reset"
LR["Global counter for reminder"] = "Global for this reminder"
LR["Reset in 5 sec"] = "Reset in 5 sec"

LR["GlobalCounterTip"] = "|cff00ff00Default|r - Adds +1 with each trigger activation"
LR["CounterSourceTip"] = "|cff00ff00Per Source|r - Adds +1 with each trigger activation. Separate counter for each caster"
LR["CounterDestTip"] = "|cff00ff00Per Target|r - Adds +1 with each trigger activation. Separate counter for each target"

LR["CounterTriggersTip"] = "|cff00ff00Trigger Overlap|r - Adds +1 when the trigger activates during a time when all triggers are active (overlap)"
LR["CounterTriggersPersonalTip"] = "|cff00ff00Trigger Overlap with Reset|r - Adds +1 when the trigger activates during a time when all triggers are active (overlap). Resets the counter to 0 when the reminder deactivates"

LR["CounterGlobalForReminderTip"] = "|cff00ff00Global for this reminder|r - Adds +1 with each trigger activation. Global counter shared among each trigger with the same counter type in this reminder"
LR["CounterResetIn5SecTip"] = "|cff00ff00Reset in 5 sec|r - Adds +1 with each trigger activation. Resets the counter to 0 after 5 seconds following each trigger activation"

LR.AnyBoss = "Any Boss"
LR.AnyNameplate = "Any Nameplate"
LR.AnyRaid = "Any from Raid"
LR.AnyParty = "Any from Party"

LR.CombatLog = "Combat Log"
LR.BossPhase = "Boss Phase"
LR.BossPhaseTip = "Boss phase information is taken from BigWigs or DBM\nIf the activation duration is not specified, the trigger will be active until the end of the phase"
LR.BossPhaseLabel = "Phase (Name/Number)"
LR.BossPull = "Boss Pull"
LR.Health = "Unit Health"
LR.HealthTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.ReplacertargetGUID = "GUID"
LR.Mana = "Unit Mana"
LR.ManaTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.Replacerhealthenergy = "Energy Percentage"
LR.Replacervalueenergy = "Energy Value"
LR.BWMsg = "BigWigs/DBM Message"
LR.ReplacerspellNameBWMsg = "BigWigs/DBM Message Text"
LR.BWTimer = "BigWigs/DBM Timer"
LR.ReplacerspellNameBWTimer = "BigWigs/DBM Timer Text"
LR.Chat = "Chat Message"
LR.ChatHelp = "Allies: Party, Raid, Whisper\nEnemies: Say, Yell, Whisper, Emote"
LR.BossFrames = "New Boss Frame"
LR.Aura = "Aura"
LR.AuraTip = "If the activation duration is not specified, the trigger will be active as long as the aura is present"
LR.Absorb = "Unit Absorb"
LR.AbsorbLabel = "Absorb Amount"
LR.AbsorbTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.Replacervalueabsorb = "Absorb Amount"

LR.CurTarget = "Current Target"
LR.CurTargetTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"

LR.SpellCD = "Spell Cooldown"
LR.SpellCDTooltip = "The trigger is active as long as the spell is on cooldown"
LR.SpellCDTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"

LR.SpellCastDone = "Spell Successfully Cast"
LR.SpellCastDoneTooltip = ""
LR.ReplacersourceGUID = "Source GUID"

LR.Widget = "Widget"
LR.WidgetLabelID = "Widget ID"
LR.WidgetLabelName = "Widget Name"
LR.WidgetTip = "Active as long as the widget is present"
LR.ReplacerspellIDwigdet = "Widget ID"
LR.ReplacerspellNamewigdet = "Widget Name"
LR.Replacervaluewigdet = "Widget Value"

LR.UnitCast = "Unit cast"
LR.UnitCastTip = "Cancelled if the unit stops casting or if the unit is no longer available."

LR.CastStart = "Cast Start"
LR.CastDone = "Cast Success"
LR.AuraAdd = "Aura Applied"
LR.AuraRem = "Aura Removed"
LR.SpellDamage = "Spell Damage"
LR.SpellDamageTick = "Periodic Spell Damage"
LR.MeleeDamage = "Melee Damage"
LR.SpellHeal = "Healing"
LR.SpellHealTick = "Periodic Healing"
LR.SpellAbsorb = "Absorb"
LR.CLEUEnergize = "Energize"
LR.CLEUMiss = "Miss"
LR.Death = "Death"
LR.Summon = "Summon"
LR.Dispel = "Dispel"
LR.CCBroke = "CC Broke"
LR.EnvDamage = "Environmental Damage"
LR.Interrupt = "Interrupt"

LR["ReplacerextraSpellIDSpellDmg"] = "Amount"
LR["ReplacerextraSpellID"] = "Interrupted Spell"
LR["MissType"] = "Miss Type"
LR.MissTypeLabelTooltip = "Available miss types:"
LR["ReplacerspellIDSwing"] = "Amount"

LR["event"] = "Event:"
LR["eventCLEU"] = "Combat Log Event:"

LR["UnitNameConditions"] = "You can specify more than one, separated by \"|cffffff00;|r\"\nYou can add \"|cffffff00-|r\" as first symbol to invert list (i.e.\ncondition will be succeed for all names except names in the list)\n\nSee Help - String Conditions for more info"

LR["sourceName"] = "Source Name:"
LR["sourceID"] = "Source ID:"
LR["sourceUnit"] = "Source Unit:"
LR["sourceMark"] = "Source Mark:"

LR["targetName"] = "Target Name:"
LR["targetID"] = "Target ID:"
LR["targetUnit"] = "Target Unit:"
LR["targetMark"] = "Target Mark:"
LR["targetRole"] = "Target Role:"

LR["spellID"] = "Spell ID:"
LR["spellName"] = "Spell Name:"
LR["extraSpellID"] = "Extra Spell ID:"
LR["extraSpellIDTip"] = "For Damage/Heal, this is the amount of damage/healing\nFor CC Broke, this is the spell ID of the interrupted spell\nFor dispel, this is the spell ID of the dispelled ability\nFor interrupt, this is the spell ID of the interrupted spell"
LR["stacks"] = "Stacks:"
LR["numberPercent"] = "Percentage:"

LR["pattFind"] = "Search Pattern:"
LR["bwtimeleft"] = "Time Left:"

LR["counter"] = "Cast Number:"
LR["cbehavior"] = "Counter Type:"

LR["delayTime"] = "Activation Delay:"
LR["activeTime"] = "Activation Time:"
LR["activeTimeTip"] = "Can be blank, useful for complex conditions with multiple triggers"

LR["invert"] = "Invert:"
LR["guidunit"] = "Trigger unit:"
LR["guidunitTip"] = "Used for nameplates glow and\nfor the option to define a same unit for every trigger."
LR["onlyPlayer"] = "Target is player:"

LR.MultiplyTip2 = "You can specify more than one comma separated."
LR.MultiplyTip3 = "Available syntaxes:"
LR.MultiplyTip4 = "|cffffff00[condition][number]|r - examples: |cff00ff00>3|r (more than 3), |cff00ff00<=2|r (first and second), |cff00ff00!4|r (all, except fourth), |cff00ff005|r (only fifth)"
LR.MultiplyTip4b = "|cffffff00[condition][number]|r - examples: |cff00ff00<50.5|r (less than 50.5), |cff00ff00>=90|r (less or exact 90)"
LR.MultiplyTip5 = "|cffffff00[number in loop]%[loop size]|r - examples: |cff00ff001%3|r (1,4,7,10,...), |cff00ff002%4|r (2,6,10,14,...)"
LR.MultiplyTip6 = "If there are several conditions (separated by commas), any successful one will be selected."
LR.MultiplyTip7 = "You can combine several conditions with \"|cffffff00+|r\" (comma must also be present) - example: |cff00ff00>3,+<7|r (more than 3 and less then 7)"
LR.MultiplyTip7b = "You can combine several conditions with\"|cffffff00+|r\" (comma must also be present) - example: |cff00ff00>70,+<=75|r (more than 70 and less or equal 75)"

LR["Send All For This Boss"] = "Send (this boss)"
LR["Export All For This Boss"] = "Export (this boss)"
LR["Get last update time"] = "Check update date"
LR["Clear Removed"] = "Clear Trash"
LR["Delete All Removed"] = "Delete for All"
LR["Deletes reminders from 'removed list' to all raiders"] = "Deletes reminders from 'removed list' to all raiders"

LR["NumberCondition"] = "See Help - Number Conditions for more info"
LR["MobIDCondition"] = "See Help - MobID Conditions for more info"

LR["rtimeLeft"] = "Time Left"
LR["rActiveTime"] = "Active Time"
LR["rActiveNum"] = "Number of Active Triggers"
LR["rMinTimeLeft"] = "Minimum Time Left"
LR["rTriggerStatus2"] = "Trigger Status"
LR["rTriggerStatus"] = "Trigger Status(by uid)"
LR["rAllSourceNames"] = "All Source Names"
LR["rAllTargetNames"] = "All Target Names"
LR["rAllActiveUIDs"] = "All Active UID"
LR["rNoteAll"] = "All Players from Note Template"
LR["rNoteLeft"] = "Left of Player in Note"
LR["rNoteRight"] = "Right of Player in Note"
LR["rTriggerActivations"] = "Amount of Trigger Activations"
LR["rRemActivations"] = "Amount of Reminder Activations"

LR["rsourceName"] = "Source Name"
LR["rsourceMark"] = "Source Mark"
LR["rsourceGUID"] = "Source GUID"
LR["rtargetName"] = "Target Name"
LR["rtargetMark"] = "Target Mark"
LR["rtargetGUID"] = "Target GUID"
LR["rspellName"] = "Spell Name"
LR["rspellID"] = "Spell ID"
LR["rextraSpellID"] = "Extra Spell ID"
LR["rstacks"] = "Stacks"
LR["rcounter"] = "Cast Number"
LR["rguid"] = "GUID"
LR["rhealth"] = "Health Percentage"
LR["rvalue"] = "Health Value"
LR["rtext"] = "Text Message"
LR["rphase"] = "Phase"
LR["rauraValA"] = "Tooltip Value 1"
LR["rauraValB"] = "Tooltip Value 2"
LR["rauraValC"] = "Tooltip Value 3"

LR["rspellIcon"] = "Spell Icon"
LR["rclassColor"] = "Class Color"
LR["rspecIcon"] = "Role Icon"
LR["rclassColorAndSpecIcon"] = "Role Icon and Class Color"
LR["rplayerName"] = "Player Name"
LR["rplayerClass"] = "Player Class"
LR["rplayerSpec"] = "Player Spec"
LR["rPersonalIcon"] = "Personal Icon"
LR["rImmuneIcon"] = "Immune Icon"
LR["rSprintIcon"] = "Sprint Icon"
LR["rHealCDIcon"] = "Heal Cooldown Icon"
LR["rRaidCDIcon"] = "Raid Cooldown Icon"
LR["rExternalCDIcon"] = "External Cooldown Icon"
LR["rFreedomCDIcon"] = "Freedom Cooldown Icon"

LR["rsetparam"] = "Set variable"
LR["rmath"] = "Math"
LR["rnoteline"] = "Note Line"
LR["rnote"] = "Note Line with Position"
LR["rnotepos"] = "Player from the note with position"
LR["rmin"] = "Minimum Value"
LR["rmax"] = "Maximum Value"
LR["rrole"] = "Player Role"
LR["rextraRole"] = "Extra Player Role"
LR["rsub"] = "Substring"
LR["rtrim"] = "Trim Spaces"

LR["rnum"] = "Select"
LR["rup"] = "UPPER CASE"
LR["rlower"] = "lower case"
LR["rrep"] = "Repeat"
LR["rlen"] = "Limit Length"
LR["rnone"] = "Nothing"
LR["rcondition"] = "Yes-no condition"
LR["rfind"] = "Find"
LR["rreplace"] = "Replace"
LR["rsetsave"] = "Save"
LR["rsetload"] = "Load"

LR["rtimeLeftTip"] = "|cffffff00{timeLeft|cff00ff00x|r:|cff00ff00y|r}|r\nRemaining time of the trigger,\n|cff00ff00x|r - trigger number (optional)\n|cff00ff00y|r - number of decimal places"
LR["rActiveTimeTip"] = "|cffffff00{activeTime|cff00ff00x|r:|cff00ff00y|r}|r\nActive time of the trigger,\n|cff00ff00x|r - trigger number (optional)\n|cff00ff00y|r - number of decimal places"
LR["rActiveNumTip"] = "|cffffff00{activeNum}|r\nNumber of active triggers"
LR["rMinTimeLeftTip"] = "|cffffff00{timeMinLeft|cff00ff00x|r:|cff00ff00y|r}|r\nShows the minimum remaining time among active triggers or active statuses inside the trigger\n|cff00ff00x|r - trigger number (optional)\n|cff00ff00y|r - number of decimals"
LR["rTriggerStatusTip"] = "|cffffff00{status:|cff00ff00x|r:|cff00ff00guid|r}|r\nShows current status of the guid inside the trigger, |cff00ff00on|r for active, |cff00ff00off|r otherwise\n|cff00ff00x|r - trigger number\n|cff00ff00guid|r - is the guid of the trigger"
LR["rTriggerStatus2Tip"] = "|cffffff00%status|cff00ff00x|r|r\nShows current status of the trigger, |cff00ff00on|r for active, |cff00ff00off|r otherwise\n|cff00ff00x|r - trigger number"
LR["rAllSourceNamesTip"] = "|cffffff00%allSourceNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\nShows the names of all sources,\n|cff00ff00x|r - trigger number (optional)\ncan limit sources from |cff00ff00num1|r to |cff00ff00num2|r,\n|cff00ff00pat|r = 1 makes names colorless, other values replace names with themselves"
LR["rAllTargetNamesTip"] = "|cffffff00%allTargetNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00pat|r|r\nShows the names of all targets,\n|cff00ff00x|r - trigger number (optional)\ncan limit targets from |cff00ff00num1|r to |cff00ff00num2|r,\n|cff00ff00pat|r = 1 makes names colorless, other values replace names with themselves"
LR["rAllActiveUIDsTip"] = "|cffffff00%allActiveUIDs|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r|r\nShows all active GUIDs,\ncan limit GUID from |cff00ff00num1|r to |cff00ff00num2|r\n|cff00ff00x|r - trigger number"
LR["rTriggerActivationsTip"] = "|cffffffff|cffffff00{triggerActivations:|cff00ff00x|r}|r\nAmount of trigger activations\n|cff00ff00x|r - trigger number"
LR["rRemActivationsTip"] = "|cffffffff|cffffff00{remActivations}|r\nAmount of reminder activations"

LR["rcounterTip"] = "|cffffff00{counter|cff00ff00x|r:|cff00ff00y|r}|r\nCurrent cast number\n|cff00ff00x|r - trigger number (optional),\n|cff00ff00y|r can be specified to loop counter after |cff00ff00y|r casts.\nExample: {counter:3} - 1, 2, 3, 1, 2, 3, 1, 2, 3..."

LR["rspellIconTip"] = "|cffffff00{spell:|cff00ff00id|r:|cff00ff00size|r}|r\n|cff00ff00id|r - the spell ID\n|cff00ff00size|r - the icon size(optional)"
LR["rclassColorTip"] = "|cffffff00%classColor |cff00ff00Name|r|r\nColors |cff00ff00Name|r with the class color"
LR["rspecIconTip"] = "|cffffff00%specIcon |cff00ff00Name|r|r\nDisplays the role icon for |cff00ff00Name|r"
LR["rclassColorAndSpecIconTip"] = "|cffffff00%specIconAndClassColor |cff00ff00Name|r|r\nShows the role icon and colors the |cff00ff00Name|r with the class color"

LR["rsetparamTip"] = "|cffffff00{setparam:|cff00ff00key|r:|cff00ff00value|r}|r\nSet local variable |cff00ff00key|r for current reminder,\nyou can call it later with {#|cff00ff00key|r}"
LR["rmathTip"] = "|cffffff00{math:|cff00ff00x+y-zf|r}|r\nwhere |cff00ff00x y z|r are numbers in the mathematical calculation,\noperators + - * / %(modulo)\nf - rounding mode\nf - to the lower value\nc - to the higher value\nr - to the nearest value"
LR["rnotelineTip"] = "|cffffff00{noteline:|cff00ff00patt|r}|r\nLine from note started with |cff00ff00patt|r"
LR["rnoteTip"] = "|cffffff00{note:|cff00ff00pos|r:|cff00ff00patt|r}|r\nWord from note line\n|cff00ff00pos|r - the order number of word in the line\n|cff00ff00patt|r - start of the line to search for in note\n\nIf |cff00ff00pos|r is bigger than the number of words in the line, then circulates the line\ne.g. total 5 words, |cff00ff00pos|r = 7, then 2nd word will show"
LR["rnoteposTip"] = "|cffffff00{notepos:|cff00ff00y|r:|cff00ff00x|r}|r\nShows player from note line started with note pattern for current reminder (it must contain {pos} parameter, read \"Help\" tab for more info)\n|cff00ff00y|r - the position of the line in a \"block note\" or the position of the player in a \"line note\",\n|cff00ff00x|r - the position of the player in a line |cff00ff00y|r for \"block note\".\nIf |cff00ff00x|r is ommitted in a \"block note\" then shows the whole line"
LR["rminTip"] = "|cffffff00{min:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r are numbers\ncan be separated by |cff00ff00;|r or |cff00ff00,|r"
LR["rmaxTip"] = "|cffffff00{max:|cff00ff00x;y;z,c,v,b|r}|r\n|cff00ff00x y z c v b|r are numbers\ncan be separated by |cff00ff00;|r or |cff00ff00,|r"
LR["rroleTip"] = "|cffffff00{role:|cff00ff00name|r}|r\n|cff00ff00name|r - the player name for which you want to show the role\nroles are: tank, healer, damager, none"
LR["rextraRoleTip"] = "|cffffff00{roleextra:|cff00ff00name|r}|r\n|cff00ff00name|r - the player name for which you want to show the extra role\nextra roles are: mdd, rdd, mhealer, rhealer, none"
LR["rsubTip"] = "|cffffff00{sub:|cff00ff00pos1|r:|cff00ff00pos2|r:|cff00ff00text|r}|r\nshows |cff00ff00text|r starting from pos1 and ending at pos2"
LR["rtrimTip"] = "|cffffff00{trim:|cff00ff00text|r}|r\n|cff00ff00text|r - the text in which you want to remove spaces"

LR["rnumTip"] = "|cffffff00{num:|cff00ff00x|r}|cff00ff00a;b;c;d|r{/num}|r\nSelects the line under number |cff00ff00x|r where |cff00ff00a|r - 1 |cff00ff00b|r - 2 |cff00ff00c|r - 3 |cff00ff00d|r - 4\n\nExample: |cff00ff00{num:%counter2}Left;Right;Forward{/num}|r"
LR["rupTip"] = "|cffffff00{up}|cff00ff00string|r{/up}|r\nShows the |cff00ff00string|r in UPPER CASE"
LR["rlowerTip"] = "|cffffff00{lower}|cff00ff00STRING|r{/lower}|r\nShows the |cff00ff00string|r in lower case"
LR["rrepTip"] = "|cffffff00{rep:|cff00ff00x|r}|cff00ff00line|r{/rep}|r\nRepeats |cff00ff00line|r |cff00ff00x|r times"
LR["rlenTip"] = "|cffffff00{len:|cff00ff00x|r}|cff00ff00line|r{/len}|r\nLimits the length of |cff00ff00line|r to |cff00ff00x|r characters"
LR["rnoneTip"] = "|cffffff00{0}|cff00ff00line|r{/0}|r\nShows an empty string"
LR["rconditionTip"] = ("|cffffff00{cond:|cff00ff001<2 AND 1=1|r}|cff00ff00yes;no|r{/cond}|r\nWill be shown as \"yes\" message if conditions match, or \"no\" message, if they don't match.\nExample: |cff00ff00{cond:%targetName=$PN$}solo;soak{/cond}|r\n\nSeveral conditions can be used (any successful will be selected)\n|cff00ff00{cond:condition1=condition2;condition3;condition4}yes;no{/cond}|r\n\nFor numerical comparisons you can use the signs for more or less\nExample: |cff00ff00{cond:%health<20}DPS;STOP DPS{/cond}|r\n\nYou can use multiple conditions separated with magic words |cff00ff00AND|r and |cff00ff00OR|r\nExamples:\n|cff00ff00{cond:%health<20 OR %health>80}EXECUTE{/cond}|r\n|cff00ff00{cond:%playerClass=shaman AND %playerSpec=restoration}RSHAM;NOT RSHAM{/cond}|r"):gsub("%$PN%$",UnitName("player"))
LR["rfindTip"] = "|cffffff00{find:|cff00ff00patt|r:|cff00ff00text|r}|cff00ff00yes;no|r{/find}|r\nFinds patt in text. Shows yes or no depending on whether a match is found"
LR["rreplaceTip"] = "|cffffff00{replace:|cff00ff00x|r:|cff00ff00y|r}|cff00ff00text|r{/replace}|r\nReplaces x with y in text"
LR["rsetsaveTip"] = "|cffffff00{set:|cff00ff001|r}|cff00ff00text|r{/set}|r\nSaves text under key '|cff00ff001|r'"
LR["rsetloadTip"] = "|cffffff00%set|cff00ff001|r|r\nLoads text under key, in this example, the key is '|cff00ff001|r'"

LR.LastPull = "Last Pull"

LR.copy = "Do Not Hide Duplicates"
LR.copyTip = "If the reminder is activated when it is already active, it will show a duplicate"

LR.norewrite = "Do Not Rewrite"
LR.norewriteTip = "If the reminder is activated when it is already active, it will not rewrite the first iteration"

LR.dynamicdisable = "Disable Dynamic Updating"
LR.dynamicdisableTip = "Dynamic text replacements will update information only when the reminder appears"

LR.isPersonal = "Do Not Send Reminder"
LR.isPersonalTip = "Make the reminder personal, it cannot be sent to other players"

LR["AdditionalOptions"] = "Extra Options:"
LR["Show Removed"] = "Show removed"

LR.Zone = "Instance:"
LR.ZoneID = "Instance ID:"
LR.ZoneTip = "Do not confuse with the zone ID,\nan instance is a separate continent or dungeon/raid"

LR.searchTip = "Searches for matches in boss' name, reminder's name, message, chat message, text to speech, on-nameplate text and load by name"
LR.search = "Search"

LR.BossKilled = "Boss Killed"
LR.BossNotKilled = "Boss Not Killed"

LR["Raid group number"] = "Raid group number"

LR["GENERAL"] = "GENERAL"
LR["LOAD"] = "LOAD"
LR["TRIGGERS"] = "TRIGGERS"
LR["OTHER"] = "OTHER"

LR["doNotLoadOnBosses"] = "Do not load\non bosses"

LR["specialTarget"] = "Special Target:"
LR["specialTargetTip"] = "Special target unit. You can use this option to highlight special nameplate(if auto-select is not suitable).\nPlayer name or any unitID.\nYou can use replacers %source1, %target3 for selecting unit from specific trigger.\nYou can use formatting options"
LR["extraCheck"] = "Extra activation condition:"

LR.sametargets = "Same trigger unit"
LR.sametargetsTip = "Will be shown only if all triggers have a matching unit."

LR.NameplateGlowTypeDef = "Default"
LR.NameplateGlowType1 = "Pixel Glow"
LR.NameplateGlowType2 = "Action Button Glow"
LR.NameplateGlowType3 = "Auto Cast Shine"
LR.NameplateGlowType4 = "Proc Glow"

LR["AIM"] = "Aim"
LR["Solid color"] = "Solid color"
LR["Custom icon above"] = "Custom icon above"
LR["% HP"] = "% HP"

LR["glowType"] = "Glow Type:"
LR["glowColor"] = "Glow Color:"
LR["glowThick"] = "Glow Thickness:"
LR["glowThickTip"] = "Pixel glow thickness (default 2)"
LR["glowScale"] = "Glow Scale:"
LR["glowScaleTip"] = "Glow scale (default 1)"
LR["glowN"] = "Glow Particles:"
LR["glowNTip"] = "Number of particles for pixel or autocast glow (default: 4 for autocast, 8 for pixel)"
LR["glowImage"] = "Glow Image:"
LR.glowImageCustom = "Custom Image:"

LR["glowOnlyText"] = "Show Only Text"
LR["glowOnlyTextTip"] = "Show only text, without glow"

LR["nameplateGlow"] = "Glow Nameplate:"
LR["nameplateGlowTip"] = "Highlights the nameplate based on the trigger's unit"
LR["UseCustomGlowColor"] = "Use Custom Glow Color"

LR["On-Nameplate Text:"] = "On-Nameplate Text:"

LR.CurrentTriggerMatch = "Current Trigger Match"

LR.SyncAllConfirm = "Are you sure you want to send all reminders?"

LR.noteIsBlock = "Note is block"
LR.noteIsBlockTip = "Searching by note template will be performed within the block from patStart to patEnd.\nExample:\n\n\npatStart\nMishok Ambi\nPauell Kroifel\nNimb Loves\npatEnd"

LR["Tip!"] = "Tip!"

LR["GeneralBFTip"] = "|cffffffffBoss/instance-based loading operates in OR mode. In other words,\nif both the boss and the instance are specified, only one match is needed\nfor the reminder to load."
LR["LoadBFTip"] = [[|cffffffffLoading can be performed based on the following conditions: Class, Role, Group Number, Nickname, or Note.
Within each condition, at least one match must be found, i.e., using an OR logic.

For example, loading for Warrior and Paladin classes:
    - If the player is a Warrior or Paladin, the reminder will load.

When using multiple loading conditions, the reminder will be loaded if all conditions
are met, i.e., using an AND logic.

For example, loading for Warrior and Paladin classes and the Tank role:
    - If the player is a Warrior or Paladin and is a Tank, the reminder will load.
    - If the player is a Warrior or Paladin and not a Tank, the reminder will not load.

Refer to the Help tab for information on loading conditions based on notes.|r]]

LR["TriggerBFTip"] = [[|cffffffffIf the duration of the reminder is 0, it will be considered untimed
and will be shown while the reminder activation conditions are met.

Some triggers can be untimed, i.e. not have a specific duration (if not specified).
Examples:
    - Boss Phase trigger will be active while the boss is in the specified phase.
    - Unit Health trigger will be active while the unit is in the specified health range.
    - Combat Log trigger cannot be untimed, so in untimed reminders for
      Combat Log triggers, you must always specify the activation duration.
]]

LR.Snippets = "Snippets"
LR.ShowSnippets = "Show snippets"
LR.SaveCurrent = "Save current"

LR.Comment = "Comment:"

LR["Last Sync:"] = "Last Sync: "
LR["Never"] = "Never"
LR["New Update"] = "New Update"
LR["Update last sync time"] = "Update last sync date\n\nIf the receiver has a last update date greater than or equal to yours, then he will not receive the update"
LR["Send to:"] = "Send to:"
LR["CustomReceiverTip"] = "Send WA to specified player"
LR["Import Mode:"] = "Import Mode:"

LR.DefText = "Normal text"
LR.BigText = "Big text"
LR.SmallText = "Small text"

LR["Big Font Size"] = "Big Font Size"
LR["Normal Font Size"] = "Normal Font Size"
LR["Small Font Size"] = "Small Font Size"

LR["10 Player Raid"] = "10 Player Raid"
LR["10 Player Raid (Heroic)"] = "10 Player Raid (Heroic)"
LR["10 Player Raid (Normal)"] = "10 Player Raid (Normal)"
LR["20 Player Raid"] = "20 Player Raid"
LR["25 Player Raid"] = "25 Player Raid"
LR["25 Player Raid (Heroic)"] = "25 Player Raid (Heroic)"
LR["25 Player Raid (Normal)"] = "25 Player Raid (Normal)"
LR["40 Player Raid"] = "40 Player Raid"
LR["Raid"] = "Raid"
LR["Raid (Heroic)"] = "Raid (Heroic)"
LR["Raid (Mythic)"] = "Raid (Mythic)"
LR["Raid (Normal)"] = "Raid (Normal)"
LR["Raid (Timewalking)"] = "Raid (Timewalking)"
LR["Looking for Raid"] = "Looking for Raid"
LR["Legacy Looking for Raid"] = "Legacy Looking for Raid"
LR["Dungeon (Heroic)"] = "Dungeon (Heroic)"
LR["Dungeon (Mythic)"] = "Dungeon (Mythic)"
LR["Dungeon (Mythic+)"] = "Dungeon (Mythic+)"
LR["Dungeon (Normal)"] = "Dungeon (Normal)"
LR["Dungeon (Timewalking)"] = "Dungeon (Timewalking)"
LR["Mythic Keystone"] = "Mythic Keystone"
LR["Scenario (Heroic)"] = "Scenario (Heroic)"
LR["Scenario (Normal)"] = "Scenario (Normal)"
LR["Island Expedition (Heroic)"] = "Island Expedition (Heroic)"
LR["Island Expedition (Mythic)"] = "Island Expedition (Mythic)"
LR["Island Expedition (Normal)"] = "Island Expedition (Normal)"
LR["Island Expeditions (PvP)"] = "Island Expeditions (PvP)"
LR["Warfront (Heroic)"] = "Warfront (Heroic)"
LR["Warfront (Normal)"] = "Warfront (Normal)"
LR["Visions of N'Zoth"] = "Visions of N'Zoth"
LR["Torghast"] = "Torghast"
LR["Path of Ascension: Courage"] = "Path of Ascension: Courage"
LR["Path of Ascension: Humility"] = "Path of Ascension: Humility"
LR["Path of Ascension: Loyalty"] = "Path of Ascension: Loyalty"
LR["Path of Ascension: Wisdom"] = "Path of Ascension: Wisdom"
LR["Normal Party"] = "Normal Party"
LR["Heroic Party"] = "Heroic Party"

LR["CUSTOM"] = "CUSTOM"

LR["Now"] = "Now"

LR["Show On Ready Check"] = "Show On Ready Check"
LR["Dont Show On Mythic"] = "Don't Show On Mythic"

LR["Hold shift while opening to show full encounters list"] = "Hold shift while opening to\nshow full encounters list"

LR["errorLabel1"] = "Reminder has encountered errors."
LR["errorLabel2"] = "Please, send error below to Author."
LR["errorLabel3"] = "Press CTRL + C to copy!"
LR["copiedToClipboard"] = "copied!"
LR["Copy error"] = "Copy error"

LR["ChooseEncounter"] = "Choose Encounter"

LR["Save history between sessions"] = "Save history between sessions"
LR["May cause fps spike on end of the boss fight"] = "|cffff0000May cause fps spike on end of the boss fight|r"

LR["Amount of pulls to save\nper boss and difficulty"] = "Amount of pulls to save\nper boss and difficulty"

LR["Any Click:"] = "Any click:"
LR["Normal Click:"] = "Normal click:"
LR["Shift Click:"] = "Shift click:"
LR["Ctrl Click:"] = "Ctrl click:"
LR["Difficulty:"] = "Difficulty:"
LR["Spells Blacklist"] = "Spells Blacklist"
LR["Add to blacklist: "] = "Add to blacklist: "
LR["|cffff8000Shift click to remove from blacklist|r"] = "|cffff8000Shift click to remove from blacklist|r"
LR["|cffff8000Shift click to delete|r"] = "|cffff8000Shift click to delete|r"
LR["Filters"] = "Filters"
LR["Filters ignored because of trigger:"] = "Filters ignored because of trigger:"
LR["|cffff8000Trigger reset|r"] = "|cffff8000Trigger reset|r"
LR["Use source counters"] = "Use source counters"

LR["Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"] = "Enable history transmission for players outside of the raid and accept history that is trasmitted for those players"
LR["History transmission"] = "Enable history transmission"

LR["Accept Reminders while not in a raid group"] = "Accept Reminders while not in a raid group"
LR["Alternative color scheme for reminders list"] = "Alternative color scheme for reminders list"
LR["Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"] = "Using data compression to store big amounts of data. High data usage is normal when interacting with history frame"

LR["Aura not updated"] = "Aura not updated"
LR["Aura updated"] = "Aura updated"
LR["User didn't respond"] = "User didn't respond"

LR.WASyncLineNameTip1 = "Click on line name to check if user has WA\nRight click to open context menu"
LR.WASyncLineNameTip2 = "Click on line name to check user's WeakAuras Addon Version"
LR["Left Click to share"] = "Left Click to share"
LR["Right Click to check versions"] = "Right Click to check version"
LR["Pressing while holding |cff00ff00shift|r will add WA to queue but wont start sending\n\nPressing while holding |cff00ff00alt|r will not update last sync time for current WA(ignoring checkbox)\n\nPressing while holding |cff00ff00ctrl|r will start sending WAs added to queue"] = "Pressing while holding |cff00ff00shift|r will add WA to queue but wont start sending\n\nPressing while holding |cff00ff00alt|r will not update last sync time for current WA(ignoring checkbox)\n\nPressing while holding |cff00ff00ctrl|r will start sending WAs added to queue"

LR["Load Current Note"] = "Load Current Note"
LR["Analyze Highlighted Text"] = "Analyze Highlighted Text"
LR["Analyze All/Highlighted Text"] = "Analyze All/Highlighted Text"
LR["Send Note"] = "Send Note"
LR["Note is empty. Probably a bug?"] = "Note is empty. Probably a bug?"
LR["Groups:"] = "Groups:"
LR["Replace only in highlighted text"] = "Replace only in highlighted text"
LR["Allow numbers in names"] = "Allow numbers in names"
LR["Allow non letter symbols in names"] = "Allow non letter symbols in names"
LR["Non letter symbols are:"] = "Non letter symbols are:"
LR["Allow # symbol in names"] = "Allow # symbol in names"

LR["Shift click to use default glow color"] = "Shift click to use default glow color"
LR["Player names to glow\nMay use many separated by\nspace comma or semicolomn"]= "Player names to glow\nMay use many separated by\nspace comma or semicolomn"

LR["For untimed reminders use {timeLeft} text replacer"] = "For untimed reminders use {timeLeft} text replacer"

LR["Hisory recording disabled"] = "Hisory recording disabled"

LR["onlyPlayerTip"] = "Counter do +1 only if triggers conditions are met (including source/target unit conditions).\nEnable this option if you want to use counter for range of units, but activate the trigger only if the target is a player itself."
LR["invertTip"] = "Inverts the trigger state required\nto activate the reminder"

LR["Marked To Send"] = "Marked To Send"
LR["Was ever sent"] = "Was ever sent"
LR["Updated less then 2 weeks ago"] = "Updated less then 2 weeks ago"

LR["send"] = "send"
LR["delete"] = "delete"

LR["rtextNote"] = "Notification/icons"
LR["rtextNoteTip"] = "3 icons if the notification contains only an icon\notherwise just a notification"

LR["rtextModIcon"]= "Notification/icons with modifier"
LR["rtextModIcon:X:Y"] = LR["rtextModIcon"]
LR["rtextModIconTip"] = "Same as \"Notification/icons\" but with additional settings\n\n|cffffff00{textModIcon:|cff00ff00X|r:|cff00ff00Y|r:|cff00ff00patt|r}|r\n|cff00ff00X|r - icon size\n|cff00ff00Y|r - number of icons\n|cff00ff00patt|r - condition\nIf a condition is specified, the icon size and number of icons will only be applied if a match is found in the notification based on the pattern, multiple patterns can be specified separated by ;(semicolon).\nExample: |cff00ff00{textModIcon:25:4:6442;1022;Personals|r}|r"

LR["Note timers"] = "Note timers"
LR["Note timers [all]"] = "Note timers (all)"

LR["rfullLine"] = "Full line"
LR["rfullLineClear"] = "Full line without {}"
LR["MRTNoteTimersComment"] = "The reminder will display cooldowns from the note similar to Kaze MRT Timers WeakAura.\n\nSet the load for a specific instance so that the reminder does not appear in dungeons.\nCompatible with automatically generated Viserio notes.\n\nBy default, this snippet makes reminder personal, meaning it will not be sent to other players."

LR["Send All (This Zone)"] = "Send All (this zone)"
LR["Current difficulty:"] = "Current difficulty:"

LR["ZoneIDTip1"] = "Leave empty for ignore\nYou can specify more than one, separated by commas.\nCurrent zone name: "
LR["ZoneIDTip2"] = "\nCurrent zone ID: "
LR["Current instance"] = "Current instance"
LR["Current difficulty"] = "Current difficulty"

LR.OutdatedVersionAnnounce = "Your version of %q is outdated. Please update to the latest version.\n\nLatest version: %s\nYour version: %s"

LR["Text color"] = "Text color"

LR.Alert = "Attention!"
LR.AlertFieldReq = "This field must be filled."
LR.AlertFieldSome = "Any of marked fields must be filled."

LR.TriggerOptionsGen = "General trigger options"
LR.TriggerTipIgnored = "Trigger %s is ignored"
LR.SpellIDBWTip = "SpellID that used by BigWigs/DBM addon.\nYou can find all spellID's on bosses page in BW/DBM\nTop right corner in the spell settings"

LR["No Mark"] = "No Mark"

LR["ActionDelete"] = "delete reminders"
LR["ActionSend"] = "accept reminders"

LR.msgSize = "Message type:"

LR.LoadAlert1 = "No load conditions set"
LR.LoadAlert2 = "You may want to set boss, zone or difficulty condition"
LR.tts = "Text To Speech:"
LR.glow = "Frame Glow:"

LR["Setup trigger"] = "Setup Trigger"

LR["Required fields must be filled:"] = "Required fields must be filled:"
LR["Any of those fields must be filled:"] = "Any of those fields must be filled:"

LR["Available replacers:"] = "Available replacers:"
LR["Detach"] = "Detach"

LR["BWEnableTip1"] = "Boss module overwriting is disabled. \"/reload\" to restore the module to its original state"
LR["BWModName"] = "Boss module name"
LR["BWSelectBoss"] = "Select boss"
LR["BWAddOptions"] = 'Additional options'

LR["Update inviters list"] = "Update inviters list"

LR.RGList = "RG List:"
LR.RGConditions = "List condition:"
LR.RGConditionsTip = [[|cffffffffCan accept multiple values, by default passing any one of them is enough to pass the check. If you combine several conditions with |cffffff00+|r, they become additive.

|cffffff00-|r before all conditions inverts the check, i.e., if the condition is not met, it will be considered as passed.

|cffffff00R|r before a condition inverts the order of the list when checking the condition, R1 - last player in the list, R1/3 - last third of the list

|cffffff00x|r - only the player at position x in the list passes the check
|cffffff00x%y|r - every y, starting from x, e.g., 2%3 - 2, 5, 8, 11, etc.
|cffffff00x-y|r - range of players, if the player is in the list between x and y, they pass, e.g., 2-4 - 2, 3, 4
|cffffff00x/y|r - the list is divided into y parts, the condition passes if the player is in part x. If it is not possible to divide evenly, the first parts will be larger than the last. For example, if a list of 10 players is divided into 3 parts, it will be 4, 3, 3, i.e., 1-4, 5-7, 8-10

|cffffff00>=x|r - player's position is greater than or equal to x
|cffffff00>x|r - player's position is greater than x
|cffffff00<=x|r - player's position is less than or equal to x
|cffffff00<x|r - player's position is less than x
|cffffff00!x|r - player is not at position x in the list

Example of an additive condition:
|cffffff001/3,+!R6|r - players from the first third of the list, excluding the 6th player counting from the end of the list

Additive conditions can be combined with regular conditions, for example:
|cffffff00R1/3,+!R6,7|r - players from the first third of the list, excluding the 6th player from the end of the list and including the 7th player from the list|r]]
LR.RGOnly = "Only RG players"
LR.RGOnlyTip = "List only consists of players who are in RGDB"

LR.SplitsWrongChar = "Wrong character:"
LR.SplitsNotInRaid = "Not in raid:"
LR.SplitsNotInTheList = "Not in the list:"
LR.SplitsLastImport = "Last import was made"
LR.SplitsShouldNotBeInRaid = " shouldn't be in raid:"

LR.AssignmentsListID = "List's ID"
LR.AssignmentsHelpTip = "Priority:\nNickname > Custom Condition > Alias > \"Not in characters DB\"> Spec > Class > Subrole(melee/range) > Role > Nested list > Not in list"
LR.AssignmentsAutoSendTip = "Automatically send the list"
LR.AssignmentsTestTip = "Normal click to test priority\nShift click to test list\nAlt click to test with RG players first"
LR.AssignmentsAutoSendEditTip = [=[|cffffffffAutomatically send list when
ready checking or switching zone.

Current zone:
|cff55ee55%s %s|r

Current zone group:
|cff55ee55%s %s|r

Current parent zone:
|cff55ee55%s %s|r

Current instance:
|cff55ee55%s %s|r

Current area:
|cff55ee55%s %s|r

To include child zone ids, prefix with 'c', e.g. 'c2022'.
Group Zone IDs must be prefixed with 'g', e.g. 'g277'.
Supports Area IDs from https://wago.tools/db2/AreaTable prefixed with 'a'.
Supports Instance IDs prefixed with 'i'.
Supports Encounter IDs prefixed with 'b', depends on BigWigs]=]
LR.AssignmentsIgnoreValidationTip = "Ignore list validation when auto sending"
LR["NotTank"] = "Not Tank"
LR["Copy trigger"] = "Copy trigger"
LR["Use TTS files if possible"] = "Use TTS files if possible"
LR["Categories to ignore when importing:"] = "Categories to ignore when importing:"
LR.Focus = "Focus"
LR["Restore"] = "Restore"

LR["You are not Raid Leader or Raid Assistant"] = "You are not Raid Leader or Raid Assistant"
LR["Not Raid Leader or Raid Assistant"] = "Not Raid Leader or Raid Assistant"
LR.WASyncUpdateSkipTitle = "ARE YOU SURE YOU WANT TO SKIP THE UPDATE?"
LR.Skip = "Skip"
LR.WASNoPermission = "%s trying to send WA. %s"

LR.TriggersCount = "Triggers number"

LR.WASyncVersionCheck = "Check versions"
LR.WASyncWACheck = "Check WA availability"
LR.WASyncWACheckTip = "Works even for those who don't have WA Sync"
LR.WASyncLinkToChat = "Link to chat"
LR.WASyncMarkToSend = "Mark to send"
LR.WASyncUnmarkToSend = "Unmark to send"
LR.WASyncMarkToSendTip = "Used for keyword search"
LR.WASyncShowInWA = "Show in WeakAuras"
LR.WASyncShowInWATip = "Will not pick WA if WeakAuras window has not been opened at least once in this session"

LR.WASyncReloadPrompt = "%s asks you to Reload UI"
LR["Ask for Reload UI after import"] = "Ask for Reload UI after import"
LR.WASyncKeywordToSendTip = "Shift click to request versions\nfor all WAs marked for sending"

LR.barTicks = "Bar ticks:"
LR.barTicksTip = "Position of ticks on the bar\nExample:\n3\n2, 5, 8"
LR.barColor = "Bar color:"
LR.barIcon = "Bar icon:"
LR.barIconTip = "Icon for the bar, use 0 for automatic icon from triggers\nuse spellID for specific icon"
LR.barWidth = "Width:"
LR.barHeight = "Height:"
LR.barTexture = "Texture:"
LR.barFontTip = "Shadow and outline follow the text reminder settings"
LR["Progress Bar"] = "Progress Bar"
LR["Small Progress Bar"] = "Small Progress Bar"
LR["Big Progress Bar"] = "Big Progress Bar"

LR["RGASSrefreshTooltip"] = "Reset all changes and refresh the list"

LR.hideTextChanged = "Hide after status change:"
LR.hideTextChangedTip = "Allows to make reminders with specified duration semi-untimed\n\nReminder will be hidden on either expiration or trigger's status change."
LR.timeLineDisable = "Don't show on timeline"
LR.durationReverse = "Show in advance"
LR.durationReverseTip = "Show message X sec before chosen time (X - duration length) (if it possible)"
LR.TEST = "TEST"
LR.OnlyMine = "Only mine"
LR.ImportHistory = "Import Spell History"
LR.ExportHistory = "Export Spell History"
LR.FromHistory = "From History"
LR.Custom = "Custom"
LR.CustomSpell = "Custom Spell:"
LR.PlayerNames = "Player Names"
LR.PlayerNamesTip = "Player names separated by space"
LR.ShowFor = "Show for:"
LR.Spell = "Spell"
LR.HideMsgCheck = "Hide message after using the spell\nDo not show if the spell is on cooldown"
LR.AdjustFL = "Adjust fight length"
LR.CopyPrev = "Copy from previous saved"
LR.Main = "Main"
LR["rshortnum"] = "Shorten number"
LR["rshortnumTip"] = [[Shorten numbers. Examples:
15.69 16
156.9 157
1569 1.6K
15690 15.7K
156900 156.9K
1569000 1.6M
15690000 15.7M
156900000 156.9M
1569000000 1.6B
15690000000 15.7B
156900000000 156.9B
1569000000000 1569B
15690000000000 15690B
]]
LR.TimerExcluded = "Enable Timer Alignment"
LR.TimerExcludedTip = "Consider the countdown timer when aligning the reminder.\n\nDisable if you want the text to stop shaking when the timer updates."
LR["QS_20"] = "M+ start"
LR.StartTestFightTip = "Works only for reminders with the trigger \"Boss Pull\", \"Boss Phase\", \"M+ start\" and \"Combat log\" events Cast start, Cast success, Aura applied and Aura removed"

LR.GlobalTimeScale = "Global Time Scale"
LR.TimeScaleT1 = "At"
LR.TimeScaleTip1  = "You can use time format (5:25)"
LR.TimeScaleT2 = "sec. +  "
LR.TimeScaleT3 = "sec."
LR.TimeScaleTip2 = "Can be negative"
LR.FilterCasts = "Casts"
LR.FilterAuras = "Auras"
LR.PresetFilter = "Boss Preset Filter"
LR.RepeatableFilter = "Repeatable Spells"
LR.RepeatableFilterTip = "Show a separate reminder button for each spell if an advanced counter condition is used.\nWith the filter off, only reminders for spells with the specified single number will be shown."
LR.Boss2 = "Boss"
LR.AdvancedEdit = "Edit in advanced mode"
LR.HideOne = "Hide Reminder"
LR.HideOneTip = "Hide this reminder until the boss changes.\n(Will be placed in the \"Uncategorized\" menu)"
LR.CustomDurationLen = "Set Custom Duration"
LR.ChangeColorRng  = "Change Color (Random)"
LR.ImportAdd = "Add to Reminders"
LR.AdjustFL = "Scale Fight"
LR.MRTOUTDATED = "|cffffce00%s|r module requires |cffffce00Method Raid Tools|r version |cffff0000%s|r or higher. Please update MRT to use this module.\n\nYou can do it using CurseForge or other addon manager"
LR.SearchStringTip = "Use \"|cff00ff00=|r\" at the beginning of the string to exact matching."
LR["Send All"] = "Send All"
LR["Send all lists that have auto send enabled"] = "Send all lists that have auto send enabled"
LR["Copy list"] = "Copy list"
LR["Add new"] = "Add new"
LR["Delete list"] = "Delete list"
LR.ImportTextFromNote = "Copy current text from note"
LR.DurRevTooltip2 = "The message will be shown 3 seconds before the timer ends.\nIf this option is disabled, messages will be shown immediately after the timer expires."
LR.RemoveBeforeExport = "Remove current reminders"
LR.RemoveBeforeExportTip = "All reminders that currently visible on the timeline will be removed before import"
LR.ForEveryPlayer = "For each player separately"
LR.ForEveryPlayerTip = "Create multiple reminders from single line for every player"
LR.ImportNameAsFilter = "Use names as filter"
LR.ImportNameAsFilterTip = "For lines with template: ability - name name name.\nNew reminder will be added, but shown only for filtered players"
LR.ImportNoteWordMy = "Use only 1 word after my name for the message"
LR.ImportNoteLinesMy = "Lines only with my name"
LR.ImportFromNote = "Import from note"
LR.Undo = "Undo"
LR.UndoTip = "Remove recently added reminders"
LR.AssignmentsConditionTip = [[|cffffffffname - player name
role1 - main role (TANK, HEALER, DAMAGER)
role2 - sub role (MHEALER, RHEALER, MDD, RDD)
alias - player's alias
class - player's class (WARRIOR, PALADIN, etc.)
spec - player's specialization ID (71, 72, etc.)
group - player's raid group number

Example: |cffffd100class == WARRIOR and alias == "Mishok"|r]]
LR.CustomDurationLenMore = "Set duration in sec. for %s (for session)"

LR["WASyncSendOG"] = "Send (not WASync)"
LR["WASyncSendOGTooltip"] = "Send WA using built-in MRT technology. Will work for players without ExRT_Reminder."

LR["Follower Dungeon"] = "Follower Dungeon"
LR["Delve"] = "Delve"
LR["Quest Party"] = "Quest Party"
LR["Story Raid"] = "Story Raid"

LR["rfunit"] = "Player by Condition"
LR["rfunitTip"] = "|cff00ff00{funit:CONDITIONS:INDEX_IN_LIST}|r - select a player from the raid/group who meets the conditions. Conditions can be class (|cff00ff00priest|r,|cff00ff00mage|r),\nrole (|cff00ff00healer|r,|cff00ff00damager|r), group (|cff00ff00g2|r,|cff00ff00g5|r). Multiple conditions should be separated by commas, and a player will be added to the list if any condition is met.\nYou can use the |cff00ff00+|r symbol before a condition to make it additive. Examples: |cff00ff00{funit:paladin,+damager:2}|r, |cff00ff00{funit:mage,+g2,priest:3}|r\n(mages from group 2 or priests from any group will be added to the list. The template will return the name of the third player from this list)"

LR["Randomize"] = "Randomize"
LR["Current roster"] = "Current roster"
LR["Current list"] = "Current list"
LR["All specs"] = "All specs"
LR["All classes"] = "All classes"
LR["All roles"] = "All roles"
LR["All aliases"] = "All aliases"

LR["Timeline"] = "Timeline"
LR["Assignments"] = "Assignments"

LR["Select boss"] = "Select boss"

LR["Hide message after using a spell"] = "Hide message after using a spell"
LR["Lines filters"] = "Lines filters"
LR["Reminders filters"] = "Reminders filters"
LR["Show only reminders for filtered spells"] = "Show only reminders for filtered spells"
LR["New reminders options"] = "New reminders options"
LR["Use TTS"] = "Use TTS"
LR["Icon without spell name"] = "Icon without spell name"
LR["ExportToNote"] = "Export to note"
LR["Send"] = "Send"
LR["Start live session"] = "Start live session"
LR["Players will be invited to live session. Everyone who accept will able to add/change/remove reminders. All changes will be in shared profile, don't forget to copy them to any profile if you want to save them."] = "Players will be invited to live session. Everyone who accept will able to add/change/remove reminders. All changes will be in shared profile, don't forget to copy them to any profile if you want to save them."
LR["Live session is on"] = "Live session is on"
LR["Guild"] = "Guild"
LR["Custom roster"] = "Custom roster"
LR["Edit"] = "Edit"
LR["Edit custom roster"] = "Edit custom roster"
LR["1 line - 1 player, format: |cff00ff00name   class   role|r"] = "1 line - 1 player, format: |cff00ff00name   class   role|r"
LR["Add (rewrite current roster)"] = "Add (rewrite current roster)"
LR["Add from current raid/group"] = "Add from current raid/group"
LR["Clear list"] = "Clear list"
LR["Edit spells groups"] = "Edit spells groups"
LR["Reset to default"] = "Reset to default"
LR["Spell Name"] = "Spell Name"
LR["Message: "] = "Message: "
LR["Sound: "] = "Sound: "
LR["Glow: "] = "Glow: "
LR["TTS: "] = "TTS: "
LR["Phase "] = "Phase "
LR["Note: "] = "Note: "
LR["From start: "] = "From start: "
LR["CD: "] = "CD: "
LR["%s is starting |A:unitframeicon-chromietime:20:20|a live session"] = "%s is starting |A:unitframeicon-chromietime:20:20|a live session"
LR["Cooldown:"] = "Cooldown:"
LR["Leave empty for reset to default value"] = "Leave empty for reset to default value"
LR["Charges:"] = "Charges:"
LR["Reminder is untimed"] = "Reminder is untimed"
LR["GUID"] = "GUID"
LR["NPC ID"] = "NPC ID"
LR["Spawn Time"] = "Spawn Time"
LR["Spawn UNIX Time"] = "Spawn UNIX Time"
LR["Spawn Index"] = "Spawn Index"
LR["Revert changes"] = "Revert changes"
LR["Revert all changes made during last live session."] = "Revert all changes made during last live session."
LR["|cff00ff00Live session is ON"] = "|cff00ff00Live session is ON"
LR["|cffff0000Exit live session"] = "|cffff0000Exit live session"
LR["Stop this session"] = "Stop this session"
LR["Select color in Color Picker"] = "Select color in Color Picker"
LR["Temporarily add custom spell"] = "Temporarily add custom spell"
LR["Round"] = "Round"
LR["Group"] = "Group"
LR["Alias:"] = "Alias:"
LR["Custom players:"] = "Custom players:"
LR["*(press Enter to save changes)"] = "*(press Enter to save changes)"
LR["Add custom line(s) at +X seconds"] = "Add custom line(s) at +X seconds"
LR["Classes:"] = "Classes:"
LR["Players:"] = "Players:"
LR["Roles:"] = "Roles:"
LR["Right Click to pin this fight"] = "Right Click to pin this fight"
LR["Right Click to unpin this fight"] = "Right Click to unpin this fight"
LR["Convert Group"] = "Convert Group"
LR["Profile"] = "Profile"
LR["Default"] = "Default"
LR["Use for all characters"] = "Use for all characters"
LR["Enter profile name"] = "Enter profile name"
LR["Delete"] = "Delete"
LR["Delete profile"] = "Delete profile"
LR["Copy into current profile from"] = "Copy into current profile from"
LR["WA is different version/changed"] = "WA is different version/changed"
LR["Clear list?"] = "Clear list?"
LR["Other"] = "Other"
LR["Deleted"] = "Deleted"
LR["You can't edit reminder simulated from note"] = "You can't edit reminder simulated from note"
LR["Simulate note timers"] = "Simulate note timers"
LR["SimNoteTimersTip"] = "Simulates reminders from the current note as if you imported reminders through \"Import from note\".\nCheckbox settings in \"Import from note\" affect the simulation of reminders on the timeline."
LR.DeletedTabTip = "Deleted reminders are stored for 180 days and can be restored at any time"
LR["Own Data"] = "Own Data"
LR["Pixel Glow"] = "Pixel Glow"
LR["Autocast Shine"] = "Autocast Shine"
LR["Action Button Glow"] = "Action Button Glow"
LR["Proc Glow"] = "Proc Glow"
LR["Last basic check:"] = "Last basic check:"
LR["seconds ago by"] = "seconds ago by"
LR["Last version check:"] = "Last version check:"
LR["Open editor"] = "Open editor"
LR["Edit custom encounter"] = "Edit custom encounter"
LR["Not enough permissions to request reload UI"] = "Not enough permissions to request reload UI"
LR["Get DebugLog"] = "Get DebugLog"
LR["Request ReloadUI"] = "Request ReloadUI"
LR["Manual Replacement"] = "Manual Replacement"
LR["Change names manually"] = "Change names manually"
LR["Name to find:"] = "Name to find:"
LR["New name:"] = "New name:"
LR["Error"] = "Error"
LR["Custom EH"] = "Custom EH"
LR["Use custom error handler for this WA"] = "Use custom error handler for this WA"
LR["Request WA"] = "Request WA"
LR["Player has to be in the same guild to request WA"] = "Player has to be in the same guild to request WA"
LR["%s requests your version of WA %q. Do you want to send it?"] = "%s requests your version of WA %q. Do you want to send it?"
LR["Set Load Never"] = "Set Load Never"
LR["Archive and Delete"] = "Archive and Delete"
LR["Last note update was sent by %s at %s"] = "Last note update was sent by %s at %s"
LR["Hold shift to save and send reminder"] = "Hold shift to save and send reminder"

LR["SoundStatus1"] = "Sound is working normally"
LR["SoundStatus2"] = "Sound is locked, updates won't override current settings"
LR["SoundStatus3"] = "Sound is muted"
LR["PersonalStatus1"] = "Make reminder personal so it won't be sent to other players"
LR["PersonalStatus2"] = "Make reminder global"
LR.OptPlayersTooltip = "Settings for players to whom the \"Always\" rule is applied."
LR["Current spell settings will be lost. Reset to default preset?"] = "Current spell settings will be lost. Reset to default preset?"

LR["Lua error in overwritten BigWigs module '%s': %s"] = "Lua error in overwritten BigWigs module '%s': %s"
LR["Use default TTS Voice"] = "Use default TTS Voice"
LR["Text"] = "Text"
LR["Text To Speech"] = "Text To Speech"
LR["Raid Frame Glow"] = "Raid Frame Glow"
LR["Nameplate Glow"] = "Nameplate Glow"
LR["Bars"] = "Bars"
LR["Default TTS Voice"] = "Default TTS Voice"
LR["Alternative TTS Voice"] = "Russian TTS Voice"
LR["TTS Volume"] = "TTS Volume"
LR["TTS Rate"] = "TTS Rate"

LR["Timeline simulation"] = "Timeline simulation"
LR["Start simulation"] = "Start simulation"
LR["Cancel simulation"] = "Cancel simulation"
LR["Pause simulation"] = "Pause simulation"
LR["Resume simulation"] = "Resume simulation"
LR["Simulation start time"] = "Simulation start time"
LR["Simulation speed multiplier"] = "Simulation speed multiplier"

LR["ttsOnHide"] = "TTS on hide:"
LR["sound_delayTip"] = "Sound delay(seconds)"
LR["sound_delayTip2"] = "Sound delay(seconds), negative values are 'x' seconds before end"

LR["DataProfileTip1"] = "Includes current set of active and deleted reminders."
LR["VisualProfileTip1"] = "Includes anchors, text/bars appearance, tts and glow settings."
LR["Visual Profile"] = "Visual Profile"
LR["Delete visual profile"] = "Delete visual profile"

LR.HelpText =
([=[Slash Commands:
    |cffaaaaaa/rem|r or |cffaaaaaa/reminder|r or |cffaaaaaa/rt r|r or |cffaaaaaa/rt rem|r - Open Reminder window
    |cffaaaaaa/rt ra|r - Open Raid Analyzer window
    |cffaaaaaa/was|r or |cffaaaaaa/wasync|r or |cffaaaaaa/rt was|r - Open WeakAuras Sync window

]=] ..
    "|cffffff00||cffRRGGBB|r...|cffffff00||r|r - All text within this construction (\"...\" in this example) will be colored with a specific color, where RR,GG,BB is the hexadecimal color code."..
	"|n|n|cffffff00{spell:|r|cff00ff0017|r|cffffff00}|r - This example will be replaced with the spell icon for SpellID \"17\" (|T135940:0|t)."..
	"|n|n|cffffff00{rt|cff00ff001|r}|r - This example will be replaced with raid target mark number 1 (star) |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t."..
	"|n|n|cffffff00\\n|r - Text after this construction will be placed on the next line." ..
	"|n|nRaid Target Mark Numbers: " ..
	"|n1 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t      5 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_5:0|t" ..
	"|n2 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_2:0|t      6 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_6:0|t" ..
	"|n3 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_3:0|t      7 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t" ..
	"|n4 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_4:0|t      8 - |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_8:0|t" ..
[=[


|cff80ff00Guide to Conditions|r

Numeric Conditions - Counter, Percentage, Stacks
    Numeric conditions are not case-sensitive, separated by commas ,
    Operators:
    |cffffff00!x|r    - excluding x
    |cffffff00>=x|r   - greater than or equal to x
    |cffffff00>x|r    - greater than x
    |cffffff00<=x|r   - less than or equal to x
    |cffffff00<x|r    - less than x
    |cffffff00=x|r    - equal to x
    |cffffff00x%y|r   - every y, starting from x
    |cffffff00+|r     - complement to the previous condition

    Example Condition 1: |cff00ff001, 3, 4|r
    This example will trigger on casts 1, 3, 4.

    Example Condition 2: |cff00ff00>=2, +!6, +!7|r
    |cffffff00If mathematical equations are present in the condition, subsequent conditions
    should be complemented with '+' as in the example.|r

    This example implies greater than or equal to 2, but excluding 6 and 7,
    it will trigger on casts 2, 3, 4, 5, 8, and so on.

    Example Condition 3: |cff00ff003%5|r
    This example implies every 5th cast starting from 3, it will trigger on casts 3, 8, 13, 18, and so on.


String Conditions - Source Name, Target Name
    String conditions are case-sensitive, separated by semicolons ;
    Operators:
    |cffffff00-|r    - excluding all matches

    Example Condition 1: |cff00ff00Scalecommander Sarkareth|r
    This example implies that the unit should be "Scalecommander Sarkareth".

    Example Condition 2: |cff00ff00-Scalecommander Sarkareth;Empty Recollection|r
    This example excludes "Scalecommander Sarkareth" and excludes "Empty Recollection".

    Example Condition 3: |cff00ff00Scalecommander Sarkareth;Empty Recollection|r
    This example implies that the unit should be either "Scalecommander Sarkareth"
    or "Empty Recollection".


MobID Conditions - Source ID, Target ID
    MobID conditions are case-sensitive, separated by commas ,
    Operators:
    |cffffff00x:y|r   - where x is the npcID, and y is the spawnIndex

    Example Condition 1: |cff00ff00154131,234156|r
    This example implies that the npcID should be 154131 or 234156.

    Example Condition 2: |cff00ff00154131:1,234156:2|r
    This example implies that the npcID should be 154131 with spawnIndex 1 or 234156 with spawnIndex 2.

|cff80ff00Guide to Counter Types|r

    |cff00ff00Default|r - Adds +1 with each trigger activation.

    |cff00ff00Per Source|r - Adds +1 with each trigger activation. Separate counter for each caster.

    |cff00ff00Per Target|r - Adds +1 with each trigger activation. Separate counter for each target.

    |cff00ff00Trigger Overlap|r - Adds +1 when the trigger activates while
    all other triggers are active.

    |cff00ff00Trigger Overlap with Reset|r - Adds +1 when the trigger activates while
    all other triggers are active. Resets the counter to 0 when the reminder deactivates.

    |cff00ff00Shared for This Reminder|r - Adds +1 with each trigger activation.
    Shared counter with every trigger of the same counter type in this reminder.

    |cff00ff00Reset After 5 Seconds|r - Adds +1 with each trigger activation.
    Resets the counter to 0 after 5 seconds from each trigger activation.

|cff80ff00Guide to Loading Conditions Logic|r

    Loading can be based on the following conditions: Class, Role, Group Number, Nickname, and by Note.
    At least one match must be found within each condition.

    For example, loading for the classes Warrior and Paladin:
        - If a player is a Warrior or Paladin, the reminder will be loaded.

    When using multiple loading conditions, the reminder will be loaded
    only if all conditions are met.

    For example, loading for the classes Warrior, Paladin, and the role Tank:
        - If a player is a Warrior or Paladin and is a Tank, the reminder will be loaded.
        - If a player is a Warrior or Paladin but not a Tank, the reminder will not be loaded.


|cff80ff00Guide to Loading by Note|r

    In the Loading Conditions section, you can specify a note template. By default, the reminder
    will look for a note line that begins with the specified template, and the reminder will be loaded
    for all players in this line.

    You can check the |cffffff00Note is a Block|r option, and then the search will be conducted
    within the block from patStart to patEnd.

    Example of a block:

        liquidStart
        Mishok Ambi
        Powel Kroifel
        Nimb Loves
        liquidEnd

    If additional parameters are not specified (see below), the reminder will be loaded for
    all players in the block.

    You can specify additional parameters for loading by note template.

    If you prefix |cffffff00-|r before the template, the loading logic will be inverted.
    That is, the reminder will be loaded for all players who are not found by the template.

    It is also possible to load the reminder only for specific positions in the note. To do this,
    after the template, you need to specify a special parameter |cffffff00{pos:y:x}|r,
    where |cffffff00y|r and |cffffff00x|r are numbers indicating the player's position
    for whom the reminder should be loaded.

    When using the template for a specific line |cffffff00y|r indicates the ordinal number of
    the player in the line.

    When using the template for a block in the note, |cffffff00y|r indicates the ordinal
    number of the line in the block, and |cffffff00x|r indicates the ordinal number
    of the player in the line. |cffffff00x|r can be omitted, then the reminder will
    be loaded for all players in the line |cffffff00y|r.

    If |cffffff00y|r and |cffffff00x|r are not specified (i.e., simply |cffffff00{pos}|r),
    the reminder will be loaded for all players found by the template. However, you can
    use the text replacement template |cffffff00{notepos:y:x}|r, which shows the
    player's nickname in that position, in other parts of the
    reminder (e.g., on-screen message or TTS).

    Without the additional |cffffff00{pos}|r parameter, using this text replacement template will not work.

    The system of note positions is cyclic. For example,
    if there are 5 players in a line, the 6th position will be occupied by the 1st player,
    if there are 8 lines, the 10th position will be occupied by the 2nd line, and so on.

    Examples:

    Note Template:

        #left

    Note:

        #left |cfff48cbaMishoksempai|r |cffa330c9Facemikh|r |cffa330c9Ennueldh|r |cffaad372Friiraan|r

    The reminder will be loaded for all players in the line
    starting with "#left."

    Note Template:

        -#right

    Note:

        #right |cfffff468Kroifel|r |cfffff468Turboclick|r |cff00ff98Nimbmain|r |cffffffffFaitiasd|r

    The reminder will be loaded for all players except
    those in the line starting with "#right."

    Note Template:

        #center {pos:3}

    Note:

        #center |cfff48cbaMishoksempai|r |cffa330c9Facemikh|r |cffa330c9Ennueldh|r |cffaad372Friiraan|r

    The reminder will be loaded only for the 3rd player
    in the note: |cffa330c9Ennueldh|r

    Note Template for a Block:

        roots

    Note:

        rootsStart
        |cffc41e3aRomadesgrip|r
        |cffa330c9Ennueldh|r
        |cfff48cbaMishoksempai|r
        |cffc69b6dSquishexh|r
        |cffaad372Batkito|r
        rootsEnd

    The reminder will be loaded for all players in the note found starting from "rootsStart" to "rootsEnd."

    Note Template for a Block:

        seeds{pos:2}

    Note:

        seedsStart
        |cffc41e3aRomadesgrip|r |cffa330c9Ennueldh|r |cfff48cbaMishoksempai|r |cffc69b6dSquishexh|r |cffaad372Batkito|r
        |cff00ff98Nimbmain|r Omegachka |cffffffffFaitiasd|r |cfff48cbaLoves|r
        seedsEnd

    The reminder will be loaded for all players in the second
    line: |cff00ff98Nimbmain|r Omegachka |cffffffffFaitiasd|r |cfff48cbaLoves|r

    Note Template for a Block:

        seeds{pos:2:3}

    Note:

        seedsStart
        |cffc41e3aRomadesgrip|r |cffa330c9Ennueldh|r |cfff48cbaMishoksempai|r |cffc69b6dSquishexh|r |cffaad372Batkito|r
        |cff00ff98Nimbmain|r Omegachka |cffffffffFaitiasd|r |cfff48cbaLoves|r
        seedsEnd

    The reminder will be loaded only for the 3rd player in the second line: Faitiasd


    Note Template for a Block:

seeds{pos:6}

Note:

seedsStart
|cffc41e3aРомадесгрип|r |cffa330c9Эннуелдх|r |cfff48cbaМишоксемпай|r |cffc69b6dСквишех|r |cffaad372Батькито|r
|cff00ff98Нимбмейн|r Омежечка |cffffffffФейтясд|r |cfff48cbaЛовес|r
seedsEnd

The reminder will be loaded for all players from the second line because of
the cyclic order of positions in the block: 1, 2, 1, 2, 1, 2, etc.


|cFFC69B6DTips on using the addon|r

1. I recommend familiarizing yourself with the functionality of the History window.
   - By clicking on different columns, you can change the reminder settings.
   - For example, if you want to quickly create a reminder for an ability that the boss uses
     during several phases, and the number of casts in each phase depends on the transition timers,
     I recommend the following:

    In the History window, find the desired boss cast in the desired phase and click on the column
    with the tooltip "Time from phase start". This way, the reminder will be immediately set to the
    timer of the selected phase and will set the delay (show after) to the selected value.

2. I do not recommend using timers from |cffff0000BigWigs/DBM|r if you plan to send
   your reminders to other raiders.
   - In BigWigs and DBM, timers often differ, and it is best to avoid such a way of setting up a reminder.
   - The best option would be to set up a reminder based on the last boss cast and count down to the next one.

3. When creating a reminder based on the boss's phase, you also need to be vigilant,
   as phases in |cffff0000BigWigs and DBM|r may differ in numbering or phase start triggers.
   - The situation with phases in boss mods is much more stable than with timers,
     but it is still worth being wary of discrepancies.
   - The best option would be to find out which trigger in one of the addons is set for phase change
     (for example, "Cast Success" or "Aura Applied") and use this trigger as the start of the phase.

4. Points 2 and 3 are not relevant if everyone in your guild uses the same boss mod addon.

]=]):gsub("\t", "    ") -- \t(tab) may not be printable atleast for some fonts, so replacing it with spaces

LR["Not in list"] = "Not in list"
LR["Not in characters DB"] = "Not in characters DB"
LR["Select nested list"] = "Select nested list"
LR["NotInDBTip"] = "Set a special position in the list for characters who are not in the database.\n\nEven if the list is obtained with the RGOnly option, these characters will be in this list."
LR["NotInListTip"] = "Set a special position in the list for characters who are not in the list.\n\nCan be used as the only priority in the list to sort characters by GUID."

LR["Export for AutoImport"] = "Export for AutoImport"
LR["Show full diffs"] = "Show full diffs"
LR["Please select two auras to compare"] = "Please select two auras to compare"
LR["Diff is too long, showing first 100000 characters only, full length:"] = "Diff is too long, showing first 100000 characters only, full length:"
LR["Imports have different UIDs, cannot be matched. Try checking full diffs"] = "Imports have different UIDs, cannot be matched. Try checking full diffs"
LR["Error comparing auras: "] = "Error comparing auras: "
LR["Import has no UID, cannot be matched."] = "Import has no UID, cannot be matched."
LR["Don't check on spell CD"] = "Don't check on spell CD"
LR["%s note is not synced\nSend note?"]  = "%s note is not synced\nSend note?"
LR["Delete Reminders"] = "Delete Reminders"
LR["Skip Import"] = "Skip Import"

LR["Left click - config"] = "Left click - config"
LR["Shift+Left click - advanced config"] = "Shift+Left click - advanced config"
LR["Right click - remove"] = "Right click - remove"
LR["Export History"] = "Export History"
LR["Import History"] = "Import History"
LR["Automatically fix server names"] = "Automatically fix server names"
LR["Delete WA"] = "Delete WA"
LR["Delete %q for %s?"] = "Delete %q for %s?"
LR["Delete Reminder"] = "Delete reminder"
LR["Save data?"] = "Save data?"
LR["Reload UI Request"] = "Reload UI Request"
LR["Reload UI"] = "Reload UI"
LR["Accepting data"] = "Accepting data"
LR[ [[Trim ignored fields
for compare]] ] = [[Trim ignored fields
for compare]]
LR["Update"] = "Update"
LR["No parent"] = "No parent"
LR["Update(new parent)"] = "Update(new parent)"
LR["Added"] = "Added"
LR["Modified"] = "Modified"
LR["There are multiple lists with the same name. Rename the list before deleting it."] = "There are multiple lists with the same name. Rename the list before deleting it."
LR["Are you sure you want to delete the list |cffffd100%s|r?"] = "Are you sure you want to delete the list |cffffd100%s|r?"
LR["Enter backup name:"] = "Enter backup name:"
LR["List |cffffd100%s|r was updated by |cffffd100%s|r. Do you want to apply changes made by him?"] = "List |cffffd100%s|r was updated by |cffffd100%s|r. Do you want to apply changes made by him?"
LR["Pass loot for all?"] = "Pass loot for all?"
LR["Auto Push Stopped\n\nSome of your autosend lists are not valid, check chat for details"] = "Auto Push Stopped\n\nSome of your autosend lists are not valid, check chat for details"
LR["There are name duplications in your lists, fix them before sending"] = "There are name duplications in your lists, fix them before sending"
LR["Delete from 'removed list'"] = "Delete from 'removed list'"
LR["Clean Import"] = "Clear Import"
LR["MRT Version Outdated"] = "MRT Version Outdated"
LR["Create new profile"] = "Create new profile"
LR["Create visual profile"] = "Create visual profile"
LR["Copy visual profile"] = "Copy visual profile"
LR["Import error"] = "Import error"
LR["Reset spell settings"] = "Reset spell settings"
LR["'NaN' in import string"] = "'NaN' in import string"
LR["Found 'NaN' in import string, delete 'NaN' from string and import data or cancel import\n|cffff0000IMPORT DATA MAY BE INCOMPLETE"] = "Found 'NaN' in import string, delete 'NaN' from string and import data or cancel import\n|cffff0000IMPORT DATA MAY BE INCOMPLETE"
LR["Do you want to always |cffff0000decline|r reminders from |cffff0000%s|r?"] = "Do you want to always |cffff0000decline|r reminders from |cffff0000%s|r?"
LR["Do you want to always |cff00ff00accept|r reminders from |cff00ff00%s|r?"] = "Do you want to always |cff00ff00accept|r reminders from |cff00ff00%s|r?"
LR["Reminder Version Outdated"] = "Reminder Version Outdated"
LR["WA Requested"] = "WA Requested"
LR["Delete section"] = "Delete section"
LR["Unmodified"] = "Unmodified"
LR["No data for added aura, cannot import."] = "No data for added aura, cannot import."
LR["Select old WA:"] = "Select old WA:"
LR["Select new WA:"] = "Select new WA:"
LR["Tree view"] = "Tree view"
LR["Group structure"] = "Group structure"
LR["No parent found for update, cannot import."] = "No parent found for update, cannot import."
LR["No parent found for import, cannot import."] = "No parent found for import, cannot import."
