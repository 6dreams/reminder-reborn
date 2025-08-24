local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT
local LR = AddonDB.LR

AddonDB.EJ_DATA = {
	encountersList = {},            -- {{instance_id, encounter_id, encounter_id, ...}, ...}
	encountersListShort = {},       -- {{instance_id, encounter_id, encounter_id, ...}, ...} but only for 2 latest tiers
	encounterIDtoEJ = {},           -- {[encounter_id] = journal_encounter_id, ...}
	encounterIDtoEJCache = {},      -- {[encounter_id] = journal_encounter_name, ...}
	instanceIDtoEJ = {},            -- {[instance_id] = journal_instance_id, ...}
	instanceIDtoEJCache = {},       -- {[instance_id] = journal_instance_name, ...}
	journalInstances = {},          -- {{tier, raid_instance_id, raid_instance_id, ... 0, dungeon_instance_id, dungeon_instance_id ...}, ...}
	diffName = {},                  -- {[difficulty_id] = difficulty_name}
	diffNameShort = {},             -- {[difficulty_id] = difficulty_name_short or difficulty_name}
}

-- workaround for bug when EJ_GetInstanceInfo returns wrong instance_id for open world entries
local blacklisted_journal_instances = {
	[959] = true, -- Argus
	[557] = true, -- Draenor
	[322] = true, -- Pandaria
}

local mopJournalEIDtoEID = {
-- MoP dungeons.
[692] = 1447, -- General Pa'valak
[668] = 1412, -- Ook-Ook
[658] = 1416, -- Liu Flameheart
[656] = 1420, -- Flameweaver Koegler
[671] = 1424, -- Brother Korloff
[665] = 1428, -- Rattlegore
[686] = 1306, -- Taran Zhu
[655] = 1397, -- Saboteur Kip'tilak
[727] = 1464, -- Wing Leader Ner'onok
[675] = 1405, -- Striker Ga'dok
[669] = 1413, -- Hoptallus
[664] = 1417, -- Lorewalker Stonestep
[654] = 1421, -- Armsmaster Harlan
[674] = 1425, -- High Inquisitor Whitemane
[673] = 1303, -- Gu Cloudstrike
[698] = 1441, -- Xin the Weaponmaster
[693] = 1465, -- Vizier Jin'bak
[676] = 1406, -- Commander Ri'mok
[670] = 1414, -- Yan-Zhu the Uncasked
[672] = 1418, -- Wise Mari
[660] = 1422, -- Houndmaster Braun
[659] = 1426, -- Instructor Chillheart
[657] = 1304, -- Master Snowdrift
[708] = 1442, -- Trial of the King
[335] = 1439, -- Sha of Doubt
[690] = 2129, -- Gekkan
[649] = 1419, -- Raigonn
[688] = 1423, -- Thalnos the Soulrender
[663] = 1427, -- Jandice Barov
[685] = 1305, -- Sha of Violence
[666] = 1429, -- Lilian Voss
[738] = 1502, -- Commander Vo'jak
[684] = 1430, -- Darkmaster Gandling

-- MoP raids.
[729] = 1506, -- Lei Shi
[828] = 1573, -- Ji-Kun
[827] = 1577, -- Jin'rokh the Breaker
[713] = 1463, -- Garalon
[853] = 1593, -- Paragons of the Klaxxi
[865] = 1601, -- Siegecrafter Blackfuse
[737] = 1499, -- Amber-Shaper Un'sok
[816] = 1570, -- Council of Elders
[820] = 1574, -- Primordius
[821] = 1578, -- Megaera
[870] = 1594, -- Spoils of Pandaria
[683] = 1409, -- Protectors of the Endless
[852] = 1602, -- Immerseus
[856] = 1606, -- Kor'kron Dark Shaman
[817] = 1559, -- Iron Qon
[726] = 1500, -- Elegon
[744] = 1504, -- Blade Lord Ta'yak
[819] = 1575, -- Horridon
[832] = 1579, -- Lei Shen
[846] = 1595, -- Malkorok
[851] = 1599, -- Thok the Bloodthirsty
[850] = 1603, -- General Nazgrim
[869] = 1623, -- Garrosh Hellscream
[682] = 1434, -- Gara'jal the Spiritbinder
[743] = 1501, -- Grand Empress Shek'zeer
[742] = 1505, -- Tsulong
[818] = 1572, -- Durumu the Forgotten
[824] = 1576, -- Dark Animus
[866] = 1624, -- Norushen
[679] = 1395, -- The Stone Guard
[881] = 1622, -- Galakras
[689] = 1390, -- Feng the Accursed
[677] = 1407, -- Will of the Emperor
[864] = 1600, -- Iron Juggernaut
[867] = 1604, -- Sha of Pride
[849] = 1598, -- The Fallen Protectors
[829] = 1560, -- Twin Empyreans
[687] = 1436, -- The Spirit Kings
[709] = 1431, -- Sha of Fear
[741] = 1498, -- Wind Lord Mel'jarak
[825] = 1565, -- Tortos
[745] = 1507, -- Imperial Vizier Zor'lok
}

-- EJ_SelectInstance sets lowest appropriate difficulty for the instance
-- because of that we dont need to call EJ_SetDifficulty but we also
-- don't see "higher difficulty only" bosses such as Ra-Den in Throne of Thunder.
-- This bug is not always happens, but leave the workaround here for now.
local customInstanceDifficulties = {
	[72] = 6, -- Twighlight Bastion - 25 Heroic
	[362] = 6, -- Throne of Thunder - 25 Heroic
}

function AddonDB:ParseEncounterJournal()
	local encountersList = AddonDB.EJ_DATA.encountersList
	local encountersListShort = AddonDB.EJ_DATA.encountersListShort

	local encounterIDtoEJ = AddonDB.EJ_DATA.encounterIDtoEJ
	local encounterIDtoEJCache = AddonDB.EJ_DATA.encounterIDtoEJCache

	local instanceIDtoEJ = AddonDB.EJ_DATA.instanceIDtoEJ
	local instanceIDtoEJCache = AddonDB.EJ_DATA.instanceIDtoEJCache

	local journalInstances = AddonDB.EJ_DATA.journalInstances


	LR.instance_name = setmetatable({}, {__index = function (t, instanceID) -- instance_id to name
		if not instanceID then return nil end

		if not instanceIDtoEJCache[instanceID] then
			local JournalInstanceID = instanceIDtoEJ[instanceID]
			local name

			if JournalInstanceID and EJ_GetInstanceInfo then
				name = EJ_GetInstanceInfo(JournalInstanceID)
			end

			if not name or name == "" then
				name = GetRealZoneText(instanceID)
			end

			if name and name ~= "" then
				instanceIDtoEJCache[instanceID] = name
			end
		end

		local name = instanceIDtoEJCache[instanceID]
		if not name then
			name = "Instance ID: "..instanceID
		end
		return name
	end})

	LR.boss_name = setmetatable({}, {__index = function (t, k) -- encounter_id to name
		if not k then return nil end

		if not encounterIDtoEJCache[k] and EJ_GetEncounterInfo then
			encounterIDtoEJCache[k] = EJ_GetEncounterInfo(encounterIDtoEJ[k] or 0)
		end
		if not encounterIDtoEJCache[k] and VMRT and VMRT.Encounter then
			encounterIDtoEJCache[k] = VMRT.Encounter.names[k]
		end

		local name = encounterIDtoEJCache[k]
		if not name or name == "" then
			name = "Encounter ID: "..k
		end
		return name:gsub(",.+","") -- remove everything after comma
	end})

	LR.diff_name = setmetatable({}, {__index = function (t, k) -- difficulty_id to name
		if not k then return nil end
		return AddonDB.EJ_DATA.diffName[k] or ("Difficulty ID: "..k)
	end})

	LR.diff_name_short = setmetatable({}, {__index = function (t, k) -- difficulty_id to name
		if not k then return nil end
		return AddonDB.EJ_DATA.diffNameShort[k] or AddonDB.EJ_DATA.diffName[k] or ("D:"..k)
	end})

	if not EJ_GetNumTiers or EJ_GetNumTiers() < 1 then
		AddonDB:FireCallback("ENCOUNTER_JOURNAL_PARSED")
		return
	end

	local currTier = EJ_GetCurrentTier()
	local totalTiers = EJ_GetNumTiers()

	for _, inRaid in ipairs({ true, false }) do
		for tier = totalTiers, 1, -1  do
			EJ_SelectTier(tier)
			local instance_index = 1
			local startForTier = #encountersList + 1
			local startForTierShort = #encountersListShort + 1
			local journal_instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)

			-- subtract 1 to match EXPANSION_NAME global names
			-- -1 is current season workaround
			local tier_data = MRT.F.table_find3(journalInstances, tier, 1)
			if not tier_data then
				tier_data = {tier}
				tinsert(journalInstances, tier_data)
			else
				tier_data[#tier_data + 1] = 0
			end
			local start_for_tier = #tier_data + 1

			while journal_instance_id do
				EJ_SelectInstance(journal_instance_id)

				local customDiffID = customInstanceDifficulties[journal_instance_id]
				if customDiffID then -- double check if custom difficulty is valid -- and EJ_IsValidInstanceDifficulty(customDiffID)
					EJ_SetDifficulty(customDiffID)
				end

				local instance_name, desc, bgImg, buttonImg, loreImg, buttonSmallImg, mapID, link, shouldDisplayDiff, instance_id, covenantID, _inRaid = EJ_GetInstanceInfo(journal_instance_id)
				local isMapAlreadyParsed = MRT.F.table_find3(encountersList, instance_id, 1)

				if mapID ~= 0 and not blacklisted_journal_instances[journal_instance_id] then
					tinsert(tier_data, start_for_tier, journal_instance_id)
				end

				if not isMapAlreadyParsed then
					local ej_index = 1
					-- TODO XXX /dump EJ_GetEncounterInfoByIndex(1,317) -- check mop bug, this needs a 7th return(encounter_id) which was absent for mop encounters in 1st day
					local boss, _, journalEncounterID, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, journal_instance_id)

					-- Encounter ids
					local currentInstance = {instance_id}
					while boss do
						if not encounter_id and mopJournalEIDtoEID[journalEncounterID] then
							encounter_id = mopJournalEIDtoEID[journalEncounterID]
							LR.boss_name[encounter_id] = boss -- update name for mop encounters
						end
						if encounter_id then
							if instance_name then
								instanceIDtoEJ[instance_id] = journal_instance_id

								instance_name = nil -- Only add it once per section
							end
							encounterIDtoEJ[encounter_id] = journalEncounterID
							tinsert(currentInstance, encounter_id) -- insert after journal_instance_id
						end
						ej_index = ej_index + 1
						boss, _, journalEncounterID, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, journal_instance_id)
					end

					if currentInstance and #currentInstance > 1 and mapID ~= 0 then
						tinsert(encountersList, startForTier, currentInstance)
						if tier >= currTier then
							tinsert(encountersListShort, startForTierShort, currentInstance)
						end
					end
				end
				instance_index = instance_index + 1
				journal_instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)
			end
		end
	end
	if EJ_SelectTier then
		EJ_SelectTier(currTier) -- restore previously selected tier
	end

	AddonDB:FireCallback("ENCOUNTER_JOURNAL_PARSED")
end

AddonDB:RegisterCallback("EXRT_REMINDER_PLAYER_ENTERING_WORLD", function()
	AddonDB:ParseEncounterJournal()
end)

function AddonDB:InstanceIsDungeon(journal_instance_id)
	local name, desc, bgImg, buttonImg, loreImg, buttonSmallImg, mapID, link, shouldDisplayDiff, instance_id, covenantID, inRaid = EJ_GetInstanceInfo(journal_instance_id)
	if type(inRaid) == "boolean" then -- Mop Classic bug workaround
		return not inRaid
	end

	for _, tierInstances in next, AddonDB.EJ_DATA.journalInstances do
		local isDungeons = false
		for i = 2, #tierInstances do
			if tierInstances[i] == 0 then -- 0 is separator between raids and dungeons
				isDungeons = true
			elseif isDungeons and journal_instance_id == tierInstances[i] then
				return true
			end
		end
	end
end


---@param journalInstanceID number
---@return string foregroundImage
---@return string backgroundImage
---@return string name
function AddonDB:GetJournalInstanceImage(journalInstanceID)
	if not journalInstanceID or not EJ_GetInstanceInfo then
		return nil, nil, nil
	end
	local name, desc, bgImg, buttonImg, loreImg, buttonSmallImg, mapID, link, shouldDisplayDiff, instance_id, covenantID, inRaid = EJ_GetInstanceInfo(journalInstanceID)
	return buttonSmallImg, bgImg, instance_id and LR.instance_name[instance_id] or nil
end

---@param instanceID number
---@return string foregroundImage
---@return string backgroundImage
---@return string name
function AddonDB:GetInstanceImage(instanceID)
	local journalInstanceID = AddonDB.EJ_DATA.instanceIDtoEJ[instanceID]
	if not journalInstanceID then
		return nil, nil, LR.instance_name[instanceID] or nil
	end
	return AddonDB:GetJournalInstanceImage(journalInstanceID)
end

---@param encounterID number
---@return number bossPortrait
function AddonDB:GetBossPortrait(encounterID)
	if not encounterID or not EJ_GetCreatureInfo then
		return nil
	end
	local journalEncounterID = AddonDB.EJ_DATA.encounterIDtoEJ[encounterID]
	if not journalEncounterID then
		return nil
	end
	if journalEncounterID then
		local id, name, description, displayInfo, iconImage, uiModelSceneID = EJ_GetCreatureInfo(1, journalEncounterID)
		return iconImage
	end
	return nil
end

---@param texture any
---@param encounterID number
---@return boolean? success
function AddonDB:SetBossPortait(texture, encounterID)
	if not encounterID or not EJ_GetCreatureInfo then
		return nil
	end
	local journalEncounterID = AddonDB.EJ_DATA.encounterIDtoEJ[encounterID]
	if not journalEncounterID then
		return nil
	end
	if journalEncounterID then
		local id, name, description, displayInfo, iconImage, uiModelSceneID = EJ_GetCreatureInfo(1, journalEncounterID)
		if displayInfo then
			SetPortraitTextureFromCreatureDisplayID(texture, displayInfo)
			return true
		end
	end
	return nil
end


---@param bossID number
---@return table? instance_table `{instance_id, encounter_id, encounter_id, ...}` from `encountersList`
function AddonDB:FindInstanceTableByBossID(bossID)
	local instanceID = AddonDB:GetInstanceForEncounter(bossID)
	for _, instance in ipairs(AddonDB.EJ_DATA.encountersList) do
		if instance[1] == instanceID then
			return instance
		end
	end
end

---@param encounter_id number
---@return number? instanceID
function AddonDB:GetInstanceForEncounter(encounter_id)
	local journalEncounterID = AddonDB.EJ_DATA.encounterIDtoEJ[encounter_id]
	if not journalEncounterID then
		return nil
	end
	local _, _, _, _, _, journalInstanceID, _, instanceID = EJ_GetEncounterInfo(journalEncounterID)
	if not instanceID then -- mop classic bug workaround, mop encounters return no instanceID
		instanceID = select(10, EJ_GetInstanceInfo(journalInstanceID))
	end
	return instanceID
end

---@return number? instanceID
function AddonDB:FindLatestRaidInstance()
	if not AddonDB.EJ_DATA.journalInstances or #AddonDB.EJ_DATA.journalInstances < 1 then
		return nil
	end
	local journal_instance_id = AddonDB.EJ_DATA.journalInstances[1][2] -- 1 is tier number
	if not journal_instance_id or journal_instance_id == 0 then
		return nil
	end
	local name, desc, bgImg, buttonImg, loreImg, buttonSmallImg, mapID, link, shouldDisplayDiff, instance_id, covenantID, inRaid = EJ_GetInstanceInfo(journal_instance_id)

	return instance_id
end

if MRT.clientVersion > 40000 then
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
		[220] = LR["Story Raid"],
		[230] = unused, -- heroic party
		[231] = unused, -- normal raid dungeon
		[232] = unused, -- event party
		[236] = unused,
		-- [236] = LR["Lorewalking"],
	}

	for i = 1, 220 do
		local name, type = GetDifficultyInfo(i)
		if name then
			if instance_difficulty_names[i] then
				if instance_difficulty_names[i] ~= unused then
					AddonDB.EJ_DATA.diffName[i] = instance_difficulty_names[i]
				end
			else
				AddonDB.EJ_DATA.diffName[i] = name
				if AddonDB.IsDev then
					print(GlobalAddonName..":", string.format("Unknown difficulty id found. Debug Information: %s %s %s", i, name, type))
				end
			end
		end
	end

	if MRT.clientVersion > 110000 then
		AddonDB.EJ_DATA.diffNameShort = {
			[14] = "N",
			[15] = "H",
			[16] = "M",
			[175] = "10N",
			[176] = "25N",
			[193] = "10H",
			[194] = "25H",
			[8] = "M+"
		}
	else
		AddonDB.EJ_DATA.diffNameShort = {
			[3] = "10N",
			[4] = "25N",
			[5] = "10H",
			[6] = "25H",
		}
	end
end

function AddonDB:GetEncounterSortIndex(id)
	local encountersList = AddonDB.EJ_DATA.encountersList

	for i = 1, #encountersList do
		local dung = encountersList[i]
		for j = 2, #dung do
			if id == dung[j] then
				return i * 100 + (#dung - j)
			end
		end
	end
	return 100000 - id
end

function AddonDB:GetInstanceSortIndex(instanceID) -- instanceID, unk
	local encountersList = AddonDB.EJ_DATA.encountersList

	for i = 1, #encountersList do
		local dung = encountersList[i]
		if dung[1] == instanceID then
			return i * 100
		end
	end
	return 100000 - instanceID
end
