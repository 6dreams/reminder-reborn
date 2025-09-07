local GlobalAddonName, AddonDB = ...

AddonDB.Changelog = [=[
|cffffff00* MRT now has its own reminder, so there will be 2 reminders for users of this addon.
 - In general, the capabilities of both reminders are not very different, but the addons are still different
   and do not interact with each other
 - This addon will still be updated with new features and improvements
 - Also note that |cFF8855FFWeakAuras Sync|r and |cff80ff00Raid Analyzer|r modules are also included with this addon.
|r

 v.66.5
* Fixes

 v.66.4
* Reminder: when searching in reminder it is now possible to use `|` and ` or ` to search for multiple terms at once
 - e.g. soak|break will find reminders that contain either "soak" or "break"
* Reminder: fixed issue when casting empowered spells made spell cd trigger work incorrectly
* Timeline: fixed issue when simulating timeline for certain data sets wasn't working

 v.66.3
* Timeline: Added data for Mythic Dimensius, based on Liquid's pov so timings are not precise

 v.66.1
* Timeline: Updated data for Mythic Araz and Salhadaar

 v.66
* Reminder: Added new trigger activation logical operand AND+
 - This allows expressing logic like (t1 and t2) or (t3 and t4)
* Reminder: Extra check conditions like "1=1 OR 1=1 AND 1=0" are now properly evaluated as true

 v.65.3
* Timeline: Updated data for Mythic Soulhunters and Fractilus

 v.65
* Fixes

 v.64
* Added season 3 mythic+ dungeons timeline data
* Fixes

 v.63.1
* Spells disabled in timeline and assignments will now be saved between sessions
* Manually edited cooldown timers in assignments will now be saved between sessions
* WASync: Allow inspecting WA maps in combat
* Fix error in MoP Classic challenge mode dungeons

 v.63
* MoP Classic fixes

 v.62.1
* Fixed sending WAs using whisper channel
* Fixed encounters list for MoP Classic
* Fixed borders in new popup dialogs

 v.62
* Fixed issue when changelog was truncated because it was too long
* Addon is now using its own popup dialogs to avoid taint

 v.61.2
* Added timeline data for MFO Mythic and Heroic encounters based on PTR testing
* Added timeline data for ToES and HoF encounters based on beta testing

 v.60.1
* Fixed mark condition for combat log triggers

 v.60
* Added initial MoP Classic support
* Added timeline data for MSV encounters based on beta testing

 v.59
* Personal reminder options such as disable, lock updates, disable sound, lock sound are now attached to the current reminder data profile(active set of reminders)
* Option to lock sound for the reminder now also locks TTS on hide

 v.58
* Added profiles system for visual settings such as anchors, text/bars appearance, tts and glow settings
* Added option to set frame strata for reminder bars
* Improved display of font names and bar texture names from SharedMedia
* Fixed issue when certain instances were named incorrectly
* Fixed issue when text frame strata option was not working
* Fixed issue when some glow options was missing from settings

 v.57.8
* Fixed version check for BigWigs users

 v.57.7
* Fixed issue when glow reminder was not showing if listed players was out of raid group

 v.57
|cffee5555** Breaking changes to addon communication system|r
 - Fixed issue when cross realm comms could be sent out of order which lead to failed decompression/deserialization
 - Players with older versions of the addon will not be able to accept or send reminders, WAs, etc. to those with the updated version
* NoteAnalyzer: added @!$_#+& as separator signs to better match player names
* Improved performance of data compression for retail

 v.56
* Added option to set tts on hide
* Added option to set delay for sounds and tts

 v.55.1
* Fixes

 v.55
* Simrun now respects time scale adjustments
* Added option to pause timeline simulation to resume it later
* Added option to start timeline simulation from a specific time
* Simulation speed multiplier now can be changed with a slider

 v.54.2
* Fixes

 v.54.1
* Fixes

 v.54
* Added option to select separate tts voice for russian speech
* Simulating test fight in timeline now may use timeline data to simulate combat log events
 - Only supported events: cast start, cast success, aura applied, aura removed
 - Source/target fields are not supported for simulated events
 - Do not expect events that are fired frequently(e.g. aura applied to the whole raid) to have proper counters
* A lot of timeline fixes
 - Fixed automatic name generation for reminders
 - Reminders that use phase trigger and check spell cooldown now properly show only once during the phase
 - Improved display of currently selected boss, now always shows difficulty and duration of the fight
 - Display a separate reminder for each comma separated value in trigger's activation delay time
 - If "Repeatable Spells" is enabled display a separate reminder for each combat log event if counter is not specified
* Export to note now also includes unformatted timestamp
* Import from note now sets difficulty of the current timeline boss to imported reminders
* New version notifications now only appear with major updates for public version of the addon

 v.53.4
* Updated Mythic Gallywix timeline data
* Timelines now always show all phases for the fight
* Fixed phase handling for fights where first phase is not 1(e.g. Mythic Gallywix and Mug'Zee)

 v.53.3
* Fixes to Mythic Gallywix timeline data
* Fixes to Mythic Mug'zee timeline data

 v.53.2
* Added Mythic Gallywix timeline data
* Added Mythic Mug'zee timeline data

 v.53
* Updated Mythic One-Armed Bandit timeline data

 v.52.5
* Updated Mythic Vexie timeline data
* Updated Mythic Stix Bunkjunker timeline data
* Updated Mythic Sprocketmonger Lockenstock timeline data
* Reminder TTS now automatically converts marks formatted like {rt1} to english text

 v.52.1
* Added Mythic Cauldron of Carnage timeline data
* Added Mythic Rik Reverb timeline data

 v.52
* Added Heroic Gallywix timeline data
* Updated Heroic Mug'Zee timeline data

 v.51.2
* Added Mug'Zee and M+ dungeons timeline data from ptr

 v.51.1
* TTS files from Interface/TTS will now have higher priority than files from ExRT_Reminder/Media/Sounds/TTS/

 v.51
* Added RCLootCouncil version to the Versions tab
* Reminder's status in Versions tab will now be included in Reminder version (E) - enabled, (D) - disabled
* Group Invites: if during scheduled invite player is already in group, scheduled invite will cancel and play a tts "Invite succeeded"

 v.50.1
* Group Invites: Added option to ctrl click on "Invite" to schedule timer that will try to invite players every 8 seconds
* Added initial timeline data for Liberation of Undermine bosses

 v.50
* Removed the sound lock button in reminder options
* The sound mute button is now a tristate, allowing it to be 'normal', 'locked', or 'muted'
* Added a button to make reminder personal, so it won't be sent to other players

 v.49.8
* Fixes

 v.49.7
* Fixes

 v.49.6
* Holding shift when saving reminder will now also send it
* Fixes

 v.49.5
* Fixes

 v.49.4
* Added possiblity to request WA through WASync Inspector

 v.49.3
* Added indicator for current boss and difficulty in simplified setup frame
* Added option to set spell name as spell id to match spell by name found for that ID
* Fixes

 v.49.2
* WASync: Added possibility to request reload UI separatly from sending WA
* NoteAnalyzer: Added possibility to manually enter player names for replacement
* Fixes for Cataclysm

 v.49.1
* Fixes

 v.49
* Added data profiles system to reminders
 - Only affects current set of active and deleted reminders. Does not affect any visual settings
* Moved deleted reminders to separate tab instead of separate window
* Search now works for all 4 tabs
* Added option to simulate reminders from note on timeline and assign
* Fixes

 v.48.4
* Fixes

 v.48.3
* Fixes

 v.48.2
* Update timeline for Mythic Queen Ansurek with post nerf timings
* Fixes

 v.48.1
* Fixes

 v.48
* Added "assignments" page for quick raid cooldowns organization for your roster
* Improvements to timeline
* Added compability with new version of WAChecker
* Sending reminders will now also archive all reminders from the 'removed list'
 - Archived reminders can be restored from the 'removed list' within the next 180 days
 - Sending singular reminder won't start archiving
* Added option to pin history fights so they won't be deleted after 30 days or when reaching the limit
 - Available by right clicking pull in history frame
* Don't mark reminder as 'not sent' when saving reminder without any changes
* WASync: last update property will now be set for all nested WAs when sending group
* Fixes

 v.47.2
* Fixes

 v.47.1
* Archiving all reminders that failed convertation to the new triggers system in v43
 - This could happen if you had data from other forks of ExRT_Reminder/MRT_Reminder
* Minor fixes

 v.47
* Added "boss timeline" with simplified way to setup reminders
* Added option to show reminder before timer ends instead of after
 - Enabled by default in reminders made from "boss timeline"
* Added triggers test tab
* Moved Help under Settings tab
* Only save history CLEU events that comes from hostile npcs
 - Should remove shaman's totems/guardians from new history records
* Added replacer "shortnum" that abbreviates numbers
* Removed attempt to delete reminder for everyone if person who deleted it is not assistant or leader
* Reminders with "countdown" enabled will now have fixed position for countdown text
 - This will remove "shaking" effect when text on a timer is changing
 - Old behaviour can be restored by enabling "Enable Timer Alignment" in settings
* Added Start M+ trigger
* Spell history in M+ dungeons will now as well record all events outside of boss combat
* Fixed issue when BW/DBM timers were not properly triggered on boss pull

 v.46.3
* Fixes

 v.46.2
* Fixes

 v.46.1
* Fixes

 v.46
* Added option to make bars in Reminder

 v.45.7
* Fixes

 v.45.6
* Fixes

 v.45.5
* WASync: Added hash validation before importing WA
 - Comms for WASync could be sent out of order or dropped during sending, so this may prevent some issues
* Added link to discord server
* Fixes

 v.45.4
* Fixes

 v.45.3
* WASync: Added option to ask for ReloadUI after importing WA
* WASync: State of "New update" check is now saved between sessions
* Fixes

 v.45.2
* Fixes

 v.45.1
* Fixes

 v.45
* WA Inspect sender version updated to 2
* Reminder history sender version updated to 2
* Increased max amount of fights saved to history to 16
* Added possibility to import/export history entries
* Fixes

 v.44.4
* Fixes

 v.44.3
* WASync: Added search by predefined keywords
 - All keywords are accessible through dropdown in search editbox
* WASync: Right clicking on WA name will now open context menu
* Fixes

 v.44.2
* Fixes

 v.44.1
* Fixes

 v.44
* Added option to restore reminders after deleting
 - Open 'removed list' and click on reminder you want to restore
* Load tab layout updates
* TTS will now also try to play .ogg sounds
* TTS will now also try to play sounds from Interface\TTS
* WASync: removed permission requirements for checking WA version
* WASync: right clicking WA's name will now also check WA version
* Fixes

 v.43
|cffee5555** Reminder sender version updated to 5|r
 - Users with older versions of the addon will not be able to accept or send reminders to
   those with the updated version.
* All reminders are converted to new trigger system
* Pre |cff80ff00Advanced|r events are removed
* Reworked Reminder Edit UI
* Added option to activate reminder only if target/source units of all triggers are the same
* Difficulty load option now independent from boss load option and can be used as standalone load option
* WASync: version check now compares .version if WA was never sent with WASync
* Added KR localization
* Fixes

 v.42.2
* Fixes

 v.42.1
* Fixes

|cff99ff99 v.42
* Reminder: All bosses are now grouped in instance folders
* WASync: Added WASync related entries to the WeakAurasDisplayButton menu
* More Cata compability
* Versions tab update
* Added notification for players with outdated version of the addon
 - Triggered by version check through versions tab
|r
 v.41.5
* Fixes

 v.41.4
* Fixes

 v.41.3
* Fixes

 v.41.2
* Added MRT Note timers event
 - Mimics Kaze's WA logic
 - It is recommended to use newly added snippet for this event instead of trying to
   create a new reminder yourself as there are some magic involved

 v.41.1
* Initial Cata compability
 - Some things may not work correctly due to lack of testing
* Fixes

 v.41
* Initial TWW compability
* RaidLockouts: automated raids list for future expansions
* RaidLockouts: fixed boss order for VotI and future raids
 - Players with old version may show with wrong boss order
* Fixes

 v.40.3
* Added a popup to accept sent reminders
 - When reminder is sent, you will be prompted to accept it
 - There is an option to add sender to always accept or always decline list which can later be changed in settings
* Fixes

 v.40.2
* Fixes

 v.40.1
* Fixes

 v.40
* WASync: added possibility to send WeakAuras to GUILD channel
 - Only players inside the same raid will get the import
* Fixes

 v.39.1
* Fixes

 v.39
* WASync: added possibility to inspect WeakAuras of other players
 - Click on names in WASync to open inspect frame
* Fixes

 v.38.1
* Added option to disable tts playing sound files from ExRT_Reminder/Media/Sounds/TTS/
* Fixes

 v.38
|cffee5555** Sender version updated to 4|r
 - Users with older versions of the addon will not be able to accept or send reminders to
   those with the updated version.
|cffee5555** WASync: version updated to 12|r
 - Users with older versions of the addon will not be able to accept or send WeakAuras to
   those with the updated version.
* Renamed Reminder to Reminder RG to be more distinct from internal MRT Reminder
* Reworked group number trigger to be raid unit stastus
 - Added option to set note pattern for group number trigger
* TTS will now try to play sound file from ExRT_Reminder/Media/Sounds/TTS/ first then fallback to default TTS
* Added text replacers for amount of times trigger activated
* Added text replacers for amount of times reminder shown
* Performance improvements for Unit Aura trigger
* Added option to ignore trigger for reminder's activation
 - e.g. reminder with 2 triggers can be configured to be shown only when first trigger is active
* WASync: targeted wa sending now works without "same realm" and "same guild" limitations
* Fixes

 v.37.5
* Fixes

 v.37.4
* Versions tab update
* Fixes

 v.37.3
* Fixes

 v.37.2
* Added option to set frame glow color for specific reminder
* Fixes

 v.37.1
* Fixes

 v.37
* Reworked history handling
 - Pre rework history is deleted
 - Some history settings was replaced with new ones. check settings tab
 - Saving history between sessions is now disabled by default
 - Amount of pulls that can be saved in now limited up to 12 per boss + difficulty
   e.g 12 for mythic Fyrakk, 12 for heroic Fyrakk
 - History older than 30 days is automatically deleted
 - Using compression for history that is saved between sessions, so high memory usage will only occur when interacting with history frame
 - History is now sent for players outside of raid instance(disabled by default)
* Added more options to difficulty dropdown
* After reconnecting mid pull reminders will now correctly load for current boss, with correct phase and pull timers
- Limitations:
    phase counters may be wrong(depends on boss mods),
    combat log counters will mostly be wrong
* Added option to set alternative color scheme for reminders list
* WASync: Added archive
 - backuping every time wa is exported through WASync
 - backups older than 30 days is automatically deleted
* RaidLockouts: Ready Check popup is now accepts right clicks to close itself anywhere on the frame
* NoteAnalyzer: Don't backup empty notes anymore
* Fixes

 v.36.1
* Fixes

 v.36
* Added option to set on hide sound
* Added option to set reminder's default state, to control default state of personal enable/disable
* Added option to lock reminder's sound and tts, so they won't be changed when reminder is reseneded
* Encounters and Instances lists are now automatically generated from Encounter Journal data
 - Now also includes all dungeon encounters
 - By default contains only encounters and instances from current
   expansion and season(e.g. old M+ dungeons)
 - Full encounters list can be accessed if you open boss drop down menu with shift key down
* Added option to allow sending reminders outside of raid groups, disabled by default
* Improvements to spellID drop down menu
* Fixes

 v.35.8
* WASync: Some UX improvements
* Fixes

 v.35.7
* Added fallback icons for CDIcon text replacers if spell icon is not found while in reminder options
* Added options to choose units as active GUIDs from another triggers of the same reminder
* Glow can now be applied to party frames
* Optimizations to unit triggers
* Reminders list is now properly updated every time when reminder options
  are opened and when recieveing a new note
* Attempt to fix issue when reminder is wrapped or truncated
* Fixes

 v.35.6
* Added text replacer for freedoms
* More 10.2.5 compability
* Fixed issue when some text replacers were not working when sending WA events
* Fixes

 v.35.5
* WASync: Reworked WeakAuras list, it now supports showing nested groups
 - All children of the searched result will be always shown
* WASync: Added indicator (S) at the end of the WeakAuras name that means
  that this WeakAura was ever sent by WASync
* 10.2.5 compability
* Fixes

 v.35.4
* Added text replacer for external cds
* Improvements to text replacers drop down
* Added new predefined snippet
* Fixes

 v.35.3
* Fixes

 v.35.2
* Added options to choose font size for small\normal\big reminders
* NoteAnalyzer: Extended note backups system
 - Backuping is now disabled by default

 v.35.1
* Fixes

 v.35
* Added possibility to choose reminder's size(small\normal\big)
* Added possibility to load reminder by specific position in specific note pattern
* Added possibility to load reminder by block in note(see Help tab)
* Added possibility to load reminder by player's group number
* Added possibility to confirm Custom players input string with Enter key
* Added drop down menu with spellIDs for current boss
 - Data is taken from Encounter Journal, so something may be missing
* Added search for History
 - Currently supports: Spell Name, Spell ID, Source Name, Target Name, Events(as SPELL_CAST_START)
* Performance improvements to triggers in Reminder Edit UI
* Reduced spam to chat when sending singular reminders
* Added possibility to save reminder snippets
 - There is also some predefined snippets
* Added possibility to write comments for reminders
* New content in Help tab
  - Guide to Loading Conditions Logic
  - Guide to Load by Note
* Reordered modules in MRT Options
* WASync: renamed localized WAChecker to WeakAuras Sync
* WASync: added tracking last sender of WA
* RaidLockouts: fixed a bug when Larodar was shown as Council Of Dreams
* RaidLockouts: added popup window on ready check, disabled by default
* Fixes

 v.34
* Major code restructure
* Major WASync rework
* Fixed issue when WASync was breaking basic WAChecker functionality

 v.33.2
* Fixed history checks
* Added Amirdrassil to zones list
* Fixes

 v.33.1
* Fixes

 v.33
* Added indicator which shows reminder's difficulty
* Added sorting by difficulty in Reminders tab
* Added option for voice countdowns(only if reminder has specified duration(not trigger))
* Load by note pattern will no longer ignore load by role/class/names
* WASync: Added button to skip update
* WASync: Added possibility to send WA to specific player(only if players in same guild)
* RaidLockuts: Added Amirdrassil
* Fixes

v.32.2
* Added new media images

v.32.1
* NoteAnalyzer: Strictness checkboxes will now be saved between sessions
* WASync: Improved queue system
* Personal disable icon will now be desaturated if reminder is disabled
* Fixes

v.32
|cffee5555** UPDATED SENDER VERSION TO 3. OLD IMPORT STRINGS WILL NO LONGER WORK.|r
    - This means that users who have older versions of the addon will not be able to accept or send reminders to the updated users.
** Improved data compression by roughly 20-25%
    - Classes, roles and true/false values are now sent in bit arrays
    - Events are now sent as numbers instead of strings
    - Sound paths are now partially encoded
    - Sender version in import string is now first string of exported data
* Added boss portaits for DF dungeons
* Added option to disable reminder which is transmitted when sending reminders
    - Reminders disabled this way will be colored gray in the list
* Adjusted colors in reminder list
* Fixes

v.31.1
* Fixes

v.31
** Reworked Reminder Setup Frame
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
* Added option to mute sound for specific reminder, this option will not be sent with reminder
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
    - Do not send this reminder(Makes reminder personal, so it cant be sent to other people)
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
    - When deleting a reminder with shift key down this reminder goes to 'removed list'
    - 'Delete All Removed' deletes all reminders from 'removed list',
    - If you are raid leader or assistant reminders will be deleted for other people
    - 'Clear Removed' resets 'removed list'
* Added guide for new conditions and counter types to Help tab
* Insane amount of new text substitution patterns
    - Accessible through drop down under message edit
* Added PARTY and RAID options for spam channel
* Removed '*' shwoing reminder status (Sent/Duplicated) in the end of the line
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

AddonDB.Changelog = AddonDB.Changelog:gsub("\t", "    "):gsub("^[ \n]*","|cff99ff99"):gsub("v%.(%d+)",function(ver)
    if tonumber(ver) < floor(AddonDB.Version) then
        return "|rv."..ver
    end
end)
