local GlobalAddonName, ExRT = ...

if ExRT.locale == "ruRU" or (VExRT and VExRT.Reminder and VExRT.Reminder.forceRUlocale) then
	return
end

ExRT.LR = {}
local LR = ExRT.LR

LR.OutlinesNone = "NONE"
LR.OutlinesNormal = "OUTLINE"
LR.OutlinesThick = "THICK OUTLINE"
LR.OutlinesMono = "MONOCHROME"
LR.OutlinesMonoNormal = "MONOCHROME, OUTLINE"
LR.OutlinesMonoThick = "MONOCHROME, THICK OUTLINE"

LR.EventsSCC = "Cast Success"
LR.EventsSCS = "Cast Start"
LR.EventsBossPhase = "Boss Phase BigWigs/DBM"
LR.EventsBossStart = "Boss Pull"
LR.EventsBossHp = "Boss HP%"
LR.EventsBossMana = "Boss Mana%"
LR.EventsBWMsg = "Message BigWigs/DBM"
LR.EventsBWTimer = "Timer BigWigs/DBM"
LR.EventsBWTimerText = "Timer BW/DBM by text"
LR.EventsSAA = "AURA APLIED"
LR.EventsSAR = "AURA REMOVED"
LR.EventsSAAS = "AURA APLIED [SELF]"
LR.EventsSARS = "AURA REMOVED [SELF]"

LR.Castse21 = "every 2 [1,3]"
LR.Castse22 = "every 2 [2,4]"
LR.Castse31 = "every 3 [1,4,7]"
LR.Castse32 = "every 3 [2,5,8]"
LR.Castse33 = "every 3 [3,6,9]"
LR.Castse41 = "every 4 [1,5,9,13]"
LR.Castse42 = "every 4 [2,6,10,14]"
LR.Castse43 = "every 4 [3,7,11,15]"
LR.Castse44 = "every 4 [4,8,12,16]"

LR.Conditionstarget = "Target"
LR.Conditionsfocus = "Focus"
LR.Conditionsnomark = "No Mark"

LR.RolesTanks = "Tanks"
LR.RolesHeals = "Heals"
LR.RolesMheals = "MHeals"
LR.RolesMhealsTip = "Melee healers are Holy Paladin and Mistweaver Monk"
LR.RolesRheals = "RHeals"
LR.RolesRhealsTip = "Ranged healers"
LR.RolesDps = "Dps"
LR.RolesRdps = "RDps"
LR.RolesMdps = "MDps"

LR.DiffsAny = "Any"
LR.DiffsHeroic = "Heroic"
LR.DiffsMythic = "Mythic"
LR.Diffsn10 = "10 Normal"
LR.Diffsn25 = "25 Normal"
LR.Diffsh10 = "10 Heroic"
LR.Diffsh25 = "25 Heroic"

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
LR.YellowAlertTip = "Reminder's duration or trigger's active time \n should not be 0 in reminder without 'untimed' triggers"
LR.EnvironmentalDMGTip = "1 - Falling\n2 - Drowning\n3 - Fatigue\n4 - Fire\n5 - Lava\n6 - Slime"
LR.DifficultyID = "Difficulty ID"
LR.EncounterID = "Encounter ID:"
LR.CountdownFormat = "Countdown Format:"
LR.AddTextReplacers = "Add Text Replacements"
LR.CustomEventTip = "Reminder will send custom event instead of showing text on the screen.\nYou can catch this event with WeakAura's custom trigger"
LR.CustomEvent = "Send WeakAuras event"
LR.GlowTip = "\nPlayer name or |cffff0000{targetName}|r or |cffff0000{sourceName}|r\n|cffff0000{SourceName|cff80ff001|r}|r to specify trigger"
LR.SpamType = "Message Type:"
LR.SpamChannel = "Chat Channel:"
LR.SpamMessage = "Chat Message:"
LR.ReverseTip = "Reverse load by player names"
LR.Reverse = "Reverse"
LR.Manually = "Manually"
LR.ManuallyTip = "Set custom encounter ID, difficulty ID, zone ID or cast number for old event types"
LR.WipePulls = "Clear History"
LR.DungeonHistory = "Dungeon History"
LR.RaidHistory = "Raid History"
LR.Duplicated = "Duplicated"
LR.ListNotSendedTip = "Not sended"
LR.ClearImport = "You are 'clear' importing data\n|cffff0000All old reminders will be deleted|r"
LR.ForceRemove = "Are you sure you want force delete all reminders from 'removed list'"
LR.ClearRemove = "Are you sure u want to clear 'removed list'?"
LR.CenterByX = "Center by X"
LR.CenterByY = "Center by Y"
LR.EnableHistory = "Record history"
LR.EnableHistoryRaid ="Record history in raids"
LR.EnableHistoryDungeon = "Record history in dungeons"

LR.chkEnableHistory = "Record pulls history"
LR.chkEnableHistoryTip = "Responsible for recording pull history for the Quick Setup window.\nIf disabled, events from the last pull will still be displayed. \n|cffff0000***Saved fights by this feature require more memory.\n**On turn off the recorded pulls are deleted from memory"
LR.Add = "Add"
LR.SendAll = "Send All"
LR.Boss = "Boss: "
LR.Any = "Any"
LR.AnyAlways = "Any (always)"

LR.Name = "Name:"
LR.CastNumber = "#Cast:"
LR.Event = "Event:"
LR.TimerText = "Timer text:"
LR.GlobalCounter = "Global Counter"
LR.GlobalCounterTip = "Use the cast number from the start of the fight regardless of who is casting"
LR.delayTip = "MM:SS.MS - 1:35.5 or time in seconds\nYou can have several, separated by commas"
LR.commaTip = "You can have several, separated by commas"
LR.delayText = "Show after, sec.:"
LR.duration = "Duration, sec.:"
LR.durationTip = "Duration of text/glow/chat spam.\nIf duration equals 0 then reminder will be shown while all triggers are active"
LR.countdown = "Countdown"
LR.msg = "On-Screen Message:"
LR.condition = "Condition:"
LR.sound = "Sound:"
LR.voiceCountdown = "Voice Countdown:"
LR.AllPlayers = "All Players"
LR.notePatternEditTip = [[The beginning of the note line, all players from that line will be selected for display. Example: "|cff00ff001. |r"
If you put a '-' before the start of the pattern, the reminder will be loaded for everyone who is NOT in the note line. Example: "|cff00ff00-1. |r"
]]
LR.notePattern = "Note pattern:"
LR.save = "Save"
LR.QuickSetup = "Show History"

LR.QuickSetupTimerFromPull = "Timer from pull"
LR.QuickSetupSec = "Seconds: "
LR.QuickSetupTimerFromPhase = "Timer from phase"
LR.QuickSetupTimerFromEvent = "Time since the previous same event"

LR.QuickSetupAddAurasEvents = "Show Aura Events"
LR.QuickSetupAddAllEvents = "Show All Events (ignore selected)"

LR.QuickSetupChoosTipStartTimer = "\nFight Start: "
LR.QuickSetupChoosTipPullTimer = "\nFight Duration: "
LR.QuickSetupChoosTipDiff = "\nDifficulty: "

LR.QS_Phase = "Boss Phase"
LR.QS_PhaseRepeat = "Phase Repeat "
LR.QS_SCC = "Cast Start"
LR.QS_SCS = "Cast Success"
LR.QS_SAA = "AURA APLIED"
LR.QS_SAR = "AURA REMOVED"

LR.Always = "Always"
LR.All = "All"

LR.PhaseNumber = "Phase number:"
LR.BossHpLess = "less than boss hp%:"
LR.BossManaLess = "more than boss mana%:"
LR.TimerTimeLeft = "Timer duration remaining:"

LR.SingularExportTip = "You can add more reminders to the export window by clicking on the export button"

LR.DeleteSection = "Delete all unlocked in this section"
LR.NoName = "Unnamed"
LR.ReminderRemoveSection = "Delete this section\nAll unlocked reminders will be deleted"
LR.ReminderPersonalDisable = "Disable this reminder for yourself"
LR.ReminderPersonalEnable = "Enable this reminder for yourself"
LR.ReminderUpdatesDisable = "Disable updates for this reminder"
LR.ReminderUpdatesEnable = "Enable updates for this reminder"
LR.ReminderSoundDisable = "Disable sound for this reminder"
LR.ReminderSoundEnable = "Enable sound for this reminder"
LR.Listchk = "When disabled, the remainder will not be shown.\nThe setting affects only you, it is not transmitted when sending"
LR.Listchk_lock = "Block\nAny updates from other players will be ignored for this reminder"
LR.Listedit = "Edit"
LR.Listduplicate ="Dupl."
LR.Listdelete = "Delete"
LR.ListdeleteTip = "Delete\n|cffffffffHold shift to delete without confirmation and move to 'removed list'"
LR.ListdExport = "Export"
LR.ListdSend = "Send"

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

LR.ReminderGlobalCounter = "Global Default"
LR.ReminderCounterSource = "Per Source"
LR.ReminderCounterDest = "Per Target"
LR.ReminderCounterTriggers = "Trigger Overlap"
LR.ReminderCounterTriggersPersonal = "Trigger Overlap with Reset"
LR["Global counter for reminder"] = "Global for this reminder"
LR["Reset in 5 sec"] = "Reset in 5 sec"

LR["ReminderGlobalCounterTip"] = "|cff00ff00Default|r - Adds +1 with each trigger activation"
LR["ReminderCounterSourceTip"] = "|cff00ff00Per Source|r - Adds +1 with each trigger activation. Separate counter for each caster"
LR["ReminderCounterDestTip"] = "|cff00ff00Per Target|r - Adds +1 with each trigger activation. Separate counter for each target"

LR["ReminderCounterTriggersTip"] = "|cff00ff00Trigger Overlap|r - Adds +1 when the trigger activates during a time when all triggers are active (overlap)"
LR["ReminderCounterTriggersPersonalTip"] = "|cff00ff00Trigger Overlap with Reset|r - Adds +1 when the trigger activates during a time when all triggers are active (overlap). Resets the counter to 0 when the reminder deactivates"

LR["ReminderCounterGlobalForReminderTip"] = "|cff00ff00Global for this reminder|r - Adds +1 with each trigger activation. Global counter shared among each trigger with the same counter type in this reminder"
LR["ReminderCounterResetIn5SecTip"] = "|cff00ff00Reset in 5 sec|r - Adds +1 with each trigger activation. Resets the counter to 0 after 5 seconds following each trigger activation"

LR.ReminderAnyBoss = "Any Boss"
LR.ReminderAnyNameplate = "Any Nameplate"
LR.ReminderAnyRaid = "Any from Raid"
LR.ReminderAnyParty = "Any from Party"

LR.ReminderCombatLog = "Combat Log"
LR.ReminderBossPhase = "Boss Phase"
LR.ReminderBossPhaseTip = "Boss phase information is taken from BigWigs or DBM\nIf the activation duration is not specified, the trigger will be active until the end of the phase"
LR.ReminderBossPhaseLabel = "Phase (Name/Number)"
LR.ReminderBossPull = "Boss Pull"
LR.ReminderHealth = "Unit Health"
LR.ReminderHealthTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.ReminderReplacertargetGUID = "GUID"
LR.ReminderMana = "Unit Mana"
LR.ReminderManaTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.ReminderReplacerhealthenergy = "Energy Percentage"
LR.ReminderReplacervalueenergy = "Energy Value"
LR.ReminderBWMsg = "BigWigs/DBM Message"
LR.ReminderReplacerspellNameBWMsg = "BigWigs/DBM Message Text"
LR.ReminderBWTimer = "BigWigs/DBM Timer"
LR.ReminderReplacerspellNameBWTimer = "BigWigs/DBM Timer Text"
LR.ReminderChat = "Chat Message"
LR.ReminderChatHelp = "Allies: Party, Raid, Whisper\nEnemies: Say, Yell, Whisper, Emote"
LR.ReminderBossFrames = "New Boss Frame"
LR.ReminderAura = "Aura"
LR.ReminderAuraTip = "If the activation duration is not specified, the trigger will be active as long as the aura is present"
LR.ReminderAbsorb = "Unit Absorb"
LR.ReminderAbsorbLabel = "Absorb Amount"
LR.ReminderAbsorbTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"
LR.ReminderReplacervalueabsorb = "Absorb Amount"

LR.ReminderCurTarget = "Current Target"
LR.ReminderCurTargetTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"

LR.ReminderSpellCD = "Spell Cooldown"
LR.ReminderSpellCDTooltip = "The trigger is active as long as the spell is on cooldown"
LR.ReminderSpellCDTip = "If the activation duration is not specified, the trigger will be active as long as the conditions are met"

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

LR.ReminderCastStart = "Cast Start"
LR.ReminderCastDone = "Cast Success"
LR.ReminderAuraAdd = "+Aura"
LR.ReminderAuraRem = "-Aura"
LR.ReminderSpellDamage = "Spell Damage"
LR.ReminderSpellDamageTick = "Periodic Spell Damage"
LR.ReminderMeleeDamage = "Melee Damage"
LR.ReminderSpellHeal = "Healing"
LR.ReminderSpellHealTick = "Periodic Healing"
LR.ReminderSpellAbsorb = "Absorb"
LR.ReminderCLEUEnergize = "Energize"
LR.ReminderCLEUMiss = "Miss"
LR.ReminderDeath = "Death"
LR.ReminderSummon = "Summon"
LR.ReminderDispel = "Dispel"
LR.ReminderCCBroke = "CC Broke"
LR.ReminderEnvDamage = "Environmental Damage"
LR.ReminderInterrupt = "Interrupt"

LR["ReminderReplacerextraSpellIDSpellDmg"] = "Amount"
LR["ReminderReplacerextraSpellID"] = "Interrupted Spell"
LR["ReminderMissType"] = "Miss Type"
LR["ReminderReplacerspellIDSwing"] = "Amount"

LR["event"] = "Advanced Event:"
LR["eventCLEU"] = "Combat Log Event:"

LR["sourceName"] = "Source Name:"
LR["sourceID"] = "Source ID:"
LR["sourceUnit"] = "Source Condition:"
LR["sourceMark"] = "Source Marker:"

LR["targetName"] = "Target Name:"
LR["targetID"] = "Target ID:"
LR["targetUnit"] = "Target Condition:"
LR["targetMark"] = "Target Marker:"
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
LR["activeTime"] = "Activation Duration:"

LR["invert"] = ""
LR["guidunit"] = "GUID:"
LR["onlyPlayer"] = "Only Player:"


LR["Send All For This Boss"] = "Send (this boss)"
LR["Export All For This Boss"] = "Export (this boss)"
LR["Get last update time"] = "Check update date"
LR["Clear Removed"] = "Clear Trash"
LR["Delete All Removed"] = "Delete for All"
LR["Deletes reminders from 'removed list to all raiders'"] = "Deletes reminders from the trash to all raiders"

LR["NumberCondition"] = "See Help - Number Conditions"
LR["StringCondition"] = "See Help - String Conditions"
LR["UnitIDCondition"] = "See Help - UnitID Conditions"

LR["rsourceName"] = "Source Name"
LR["rsourceMark"] = "Source Marker"
LR["rsourceGUID"] = "Source GUID"
LR["rtargetName"] = "Target Name"
LR["rtargetMark"] = "Target Marker"
LR["rtargetGUID"] = "Target GUID"
LR["rspellName"] = "Spell Name"
LR["rspellID"] = "Spell ID"
LR["rextraSpellID"] = "Extra Spell ID"
LR["rstacks"] = "Stacks"
LR["rsourceGUID"] = "Source GUID"
LR["rtargetGUID"] = "Target GUID"
LR["rcounter"] = "Counter"
LR["rguid"] = "GUID"
LR["rhealth"] = "Health Percentage"
LR["rvalue"] = "Health Value"
LR["rtimeLeft"] = "Time Left"
LR["rtext"] = "Text Message"
LR["rphase"] = "Phase"
LR["rauraValA"] = "Tooltip Value 1"
LR["rauraValB"] = "Tooltip Value 2"
LR["rauraValC"] = "Tooltip Value 3"

LR["rmath"] = "Math"
LR["rmathTip"] = "|cffffffff|cffffff00{math:|cff00ff00x+y-zf|r}|r\nwhere x y z are numbers in the mathematical calculation, \noperators + - * / %(modulo)\nf - rounding mode \nf - to the lower value \nc - to the higher value \nr - to the nearest value"
LR["rnoteline"] = "Note Line"
LR["rnotelineTip"] = "|cffffffff|cffffff00{noteline:|cff00ff00patt|r}|r\nwhere patt is the search pattern in the note"
LR["rnote"] = "Note Line with Position"
LR["rnoteTip"] = "|cffffffff|cffffff00{note:|cff00ff00pos|r:|cff00ff00patt|r}|r\nwhere pos is the word number after the pattern patt in the note"
LR["rmin"] = "Minimum Value"
LR["rminTip"] = "|cffffffff|cffffff00{min:|cff00ff00x;y;z,c,v,b|r}|r\nwhere x y z c v b are numbers, can be separated by ; or ,"
LR["rmax"] = "Maximum Value"
LR["rmaxTip"] = "|cffffffff|cffffff00{max:|cff00ff00x;y;z,c,v,b|r}|r\nwhere x y z c v b are numbers, can be separated by ; or ,"
LR["rrole"] = "Player Role"
LR["rroleTip"] = "|cffffffff|cffffff00{role:|cff00ff00name|r}|r\nwhere name is the player name for which you want to know the role"
LR["rextraRole"] = "Extra Player Role"
LR["rextraRoleTip"] = "|cffffffff|cffffff00{roleextra:|cff00ff00name|r}|r\nwhere name is the player name for which you want to know the extra role"
LR["rsub"] = "Substring"
LR["rsubTip"] = "|cffffffff|cffffff00{sub:|cff00ff00pos1|r:|cff00ff00pos2|r:|cff00ff00text|r}|r\nshows text starting from pos1 and ending at pos2"
LR["rtrim"] = "Remove Spaces"
LR["rtrimTip"] = "|cffffffff|cffffff00{trim:|cff00ff00text|r}|r\nwhere text is the text in which you want to remove spaces"

LR["rnum"] = "Select"
LR["rnumTip"] = "|cffffffff|cffffff00 {num:|cff00ff00x|r}|cff00ff00a;b;c;d|r{/num}|r \nSelects the line under number x where a - 1 b - 2 c - 3 d - 4"
LR["rup"] = "UPPER CASE"
LR["rupTip"] = "|cffffffff|cffffff00 {up}|cff00ff00string|r{/up}|r \nReturns the string in UPPER CASE"
LR["rlower"] = "lower case"
LR["rlowerTip"] = "|cffffffff|cffffff00 {lower}|cff00ff00STRING|r{/lower}|r \nReturns the string in lower case"
LR["rrep"] = "Repeat"
LR["rrepTip"] = "|cffffffff|cffffff00 {rep:|cff00ff00x|r}|cff00ff00line|r{/rep}|r \nRepeats line x times"
LR["rlen"] = "Limit Length"
LR["rlenTip"] = "|cffffffff|cffffff00 {len:|cff00ff00x|r}|cff00ff00line|r{/len}|r \nLimits the length of line to x characters"
LR["rnone"] = "Nothing"
LR["rnoneTip"] = "|cffffffff|cffffff00 {0}|cff00ff00line|r{/0}|r \nReturns an empty string"
LR["rcondition"] = "Condition"
LR["rconditionTip"] = "|cffffffff|cffffff00 {cond:|cff00ff001<2 AND 1=1|r}|cff00ff00yes;no|r{/cond}|r \nReturns yes or no depending on the condition"
LR["rfind"] = "Find"
LR["rfindTip"] = "|cffffffff|cffffff00 {find:|cff00ff00patt|r:|cff00ff00text|r}|cff00ff00yes;no|r{/find}|r \nFinds patt in text. Returns yes or no depending on whether a match is found"
LR["rreplace"] = "Replace"
LR["rreplaceTip"] = "|cffffffff|cffffff00 {replace:|cff00ff00x|r:|cff00ff00y|r}|cff00ff00text|r{/replace}|r \nReplaces x with y in text"
LR["rsetsave"] = "Save"
LR["rsetsaveTip"] = "|cffffffff|cffffff00 {set:|cff00ff001|r}|cff00ff00text|r{/set}|r \nSaves text under key '1'"
LR["rsetload"] = "Load"
LR["rsetloadTip"] = "|cffffffff|cffffff00 %set|cff00ff001|r|r \nLoads text under key, in this example, the key is '1'"

LR["rspellIcon"] = "Spell Icon"
LR["rspellIconTip"] = "|cffffffff|cffffff00{spell:|cff00ff00id|r:|cff00ff00size|r}|r\nwhere id is the spell ID, \nsize is the icon size, \nif size is not specified, the icon size adjusts to the font size"
LR["rclassColor"] = "Class Color"
LR["rclassColorTip"] = "|cffffffff|cffffff00%classColor |cff00ff00Name|r|r \nColors Name with the class color"
LR["rspecIcon"] = "Role Icon"
LR["rspecIconTip"] = "|cffffffff|cffffff00%specIcon |cff00ff00Name|r|r \nDisplays the role icon for Name"
LR["rclassColorAndSpecIcon"] = "Role Icon and Class Color"
LR["rclassColorAndSpecIconTip"] = "|cffffffff|cffffff00%specIconAndClassColor |cff00ff00Name|r|r\nShows the role icon and colors the name with the class color"
LR["rplayerName"] = "Player Name"
LR["rplayerClass"] = "Player Class"
LR["rplayerSpec"] = "Player Spec"
LR["rPersonalIcon"] = "Personal Icon"
LR["rImmuneIcon"] = "Immune Icon"
LR["rSprintIcon"] = "Sprint Icon"
LR["rHealCDIcon"] = "Heal Cooldown Icon"
LR["rRaidCDIcon"] = "Raid Cooldown Icon"
LR["rNoteLeft"] = "Left of Player in Note"
LR["rNoteRight"] = "Right of Player in Note"
LR["rNoteAll"] = "All Players from Note Template"
LR["rCounter"] = "Counter"

LR["rTimeLeft"] = "Time Left"
LR["rTimeLeftTip"] = "|cffffffff|cffffff00{timeLeft|cff00ff00x|r:|cff00ff00y|r}|r\nRemaining time of the trigger, \nx - trigger number (optional)\ny - number of decimal places"
LR["rActiveTime"] = "Active Time"
LR["rActiveTimeTip"] = "|cffffffff|cffffff00{activeTime|cff00ff00x|r:|cff00ff00y|r}|r\nActive time of the trigger, \nx - trigger number (optional)\ny - number of decimal places"
LR["rActiveNum"] = "Number of Active Triggers"
LR["rActiveNumTip"] = "|cffffffff|cffffff00{activeNum}|r\nNumber of active triggers"
LR["rMinTimeLeft"] = "Minimum Time Left"
LR["rMinTimeLeftTip"] = "|cffffffff|cffffff00{timeMinLeft|cff00ff00x|r:|cff00ff00y|r}|r\nShows the minimum remaining time among \nactive triggers or active statuses inside the trigger\nx - trigger number (optional)\ny - number of decimal places"
LR["rTriggerStatus"] = "Trigger Status"
LR["rTriggerStatusTip"] = "|cffffffff|cffffff00{status:|cff00ff00triggerNum|r:|cff00ff00uid|r}|r\nwhere triggerNum is the trigger number in the reminder, \nuid is the UID or GUID of the reminder"
LR["rAllSourceNames"] = "All Source Names"
LR["rAllSourceNamesTip"] = "|cffffffff|cffffff00%allSourceNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00customPattern|r|r \nShows the names of all sources,\nx - trigger number (optional) \ncan limit sources from num1 to num2, \ncustomPattern = 1 makes names colorless, \nother values replace names with themselves"
LR["rAllTargetNames"] = "All Target Names"
LR["rAllTargetNamesTip"] = "|cffffffff|cffffff00%allTargetNames|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r:|cff00ff00customPattern|r|r\nShows the names of all targets,\nx - trigger number (optional) \ncan limit targets from num1 to num2, \ncustomPattern = 1 makes names colorless, \nother values replace names with themselves"
LR["rAllActiveUIDs"] = "All Active UID"
LR["rAllActiveUIDsTip"] = "|cffffffff|cffffff00%allActiveUIDs|cff00ff00x|r:|cff00ff00num1|r:|cff00ff00num2|r|r\nShows all active UIDs, \ncan limit UID from num1 to num2"

LR.LastPull = "Last Pull"

LR.copy = "Do Not Hide Duplicates"
LR.copyTip = "Only for advanced\nIf the reminder is activated when it is already active, \nit will show a duplicate"

LR.norewrite = "Do Not Rewrite"
LR.norewriteTip = "Only for advanced\nIf the reminder is activated when it is already active, \nit will not rewrite the first iteration"

LR.dynamicdisable = "Disable Dynamic Updating"
LR.dynamicdisableTip = "Only for advanced\nDynamic text replacements will update \ninformation only when the reminder appears"

LR.isPersonal = "Do Not Send Reminder"
LR.isPersonalTip = "Make the reminder personal, \nit cannot be sent to other players"

LR["AdditionalOptions"] = "Extra Options:"
LR["Show Removed"] = "Show removed"

LR.Zone = "Zone:"
LR.ZoneID = "Zone ID:"

LR.searchTip = "Searches for matches in name, \nmessage, chat message, \ntext to speech,\non-nameplate text"

LR["rsetparam"] = "Set variable"
LR["rsetparamTip"] = "|cffffffff|cffffff00{setparam:|cff00ff00key|r:|cff00ff00value|r}|r \nSet local variable with key 'key' for current reminder, \nyou can call it later with {#key}"

LR.BossKilled = "Boss Killed"
LR.BossNotKilled = "Boss Not Killed"

LR["Raid group number"] = "Raid group number"

LR["GENERAL"] = "GENERAL"
LR["TEXT, GLOW AND SOUNDS"] = "TEXT, GLOW AND SOUNDS"
LR["LOAD CONDITIONS"] = "LOAD CONDITIONS"
LR["TRIGGERS"] = "TRIGGERS"

LR["doNotLoadOnBosses"] = "Do not load \non bosses:"

LR["specialTarget"] = "Replace GUID:"
LR["specialTargetTip"] = "Replaces main GUID. Use unitToken or \ntarget/source(trigger number).\nFor example source1 or target"
LR["extraCheck"] = "Custom condition:"

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
LR["glowScale"] = "Glow Scale:"
LR["glowN"] = "Glow Number:"
LR["glowImage"] = "Glow Image:"
LR.glowImageCustom = "Custom Image:"

LR["glowOnlyText"] = "Show Only Text"
LR["glowOnlyTextTip"] = "Show only text, without glow"

LR["GlowNameplate"] = "Glow Nameplate:"
LR["UseCustomGlowColor"] = "Use Custom Glow Color"

LR["On-Nameplate Text:"] = "On-Nameplate Text:"

LR.CurrentTriggerMatch = "Current Trigger Match"





LR.HelpText =
	"|cffffff00||cffRRGGBB|r...|cffffff00||r|r - All text within this construction (\"...\" in this example) will be colored with a specific color, where RR,GG,BB is the hexadecimal color code."..
	"|n|n|cffffff00{spell:|r|cff00ff0017|r|cffffff00}|r - This example will be replaced with the spell icon for SpellID \"17\" (|T135940:0|t)."..
	"|n|n|cffffff00{rt|cff00ff001|r}|r - This example will be replaced with raid target marker number 1 (star) |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_1:0|t."..
	"|n|n|cffffff00\\n|r - Text after this construction will be placed on the next line." ..
	"|n|nRaid Target Marker Numbers: " ..
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


UnitID Conditions - Source ID, Target ID
    UnitID conditions are case-sensitive, separated by commas ,
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



|cFFC69B6DTips on using the addon|r

1. I recommend familiarizing yourself with the functionality of the Quick Setup window.
   - By clicking on different columns, you can change the reminder settings.
   - For example, if you want to quickly create a reminder for an ability that the boss uses
     during several phases, and the number of casts in each phase depends on the transition timers,
     I recommend the following:

    In the Quick Setup window, find the desired boss cast in the desired phase and click on the column
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
     (for example, "Cast Success" or "+Aura") and use this trigger as the start of the phase.

4. Points 2 and 3 are not relevant if everyone in your guild uses the same boss mod addon.

]=]
