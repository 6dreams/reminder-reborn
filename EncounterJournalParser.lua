local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT
local LR = AddonDB.LR


AddonDB.EJ_DATA = {
    encountersList = {},            -- {{journal_instance_id, encounter_id, encounter_id, ...}, ...}
    encountersListShort = {},       -- {{journal_instance_id, encounter_id, encounter_id, ...}, ...} but only for 2 latest tiers
    encounterIDtoEJ = {},           -- {[encounter_id] = journal_encounter_id, ...}
    encounterIDtoEJCache = {},      -- {[encounter_id] = journal_encounter_name, ...}
    instanceIDtoEJ = {},            -- {[instance_id] = journal_instance_id, ...}
    instanceIDtoEJCache = {},       -- {[instance_id] = journal_instance_name, ...}
    journalInstances = {},          -- {{tier, instance_id, instance_id, ...}, ...}
}

-- workaround for bug when EJ_GetInstanceInfo returns wrong instance_id for open world entries
local blacklisted_journal_instances = {
    [959] = true, -- Argus
    [557] = true, -- Draenor
    [322] = true, -- Pandaria
}

function AddonDB:ParseEncounterJournal()
    local encountersList = {}
    AddonDB.EJ_DATA.encountersList = encountersList
    local encountersListShort = {}
    AddonDB.EJ_DATA.encountersListShort = encountersListShort

    local encounterIDtoEJ = {}
    AddonDB.EJ_DATA.encounterIDtoEJ = encounterIDtoEJ
    local encounterIDtoEJCache = {}
    AddonDB.EJ_DATA.encounterIDtoEJCache = encounterIDtoEJCache

    local instanceIDtoEJ = {}
    AddonDB.EJ_DATA.instanceIDtoEJ = instanceIDtoEJ
    local instanceIDtoEJCache = {}
    AddonDB.EJ_DATA.instanceIDtoEJCache = instanceIDtoEJCache

    local journalInstances = {}
    AddonDB.EJ_DATA.journalInstances = journalInstances


    LR.instance_name = setmetatable({}, {__index=function (t, k) -- instance_id to name
        if not k then return nil end

        if not instanceIDtoEJCache[k] then
            local name = GetRealZoneText(k)
            if name and name ~= "" then
                instanceIDtoEJCache[k] = name
            end
        end

        local name = instanceIDtoEJCache[k]
        if not name then
            name = "Instance ID: "..k
        end
        return name


    end})

    LR.boss_name = setmetatable({}, {__index=function (t, k) -- encounter_id to name
        if not k then return nil end

        if not encounterIDtoEJCache[k] and EJ_GetEncounterInfo then
            encounterIDtoEJCache[k] = EJ_GetEncounterInfo(encounterIDtoEJ[k] or 0)
        end
        if not encounterIDtoEJCache[k] and VMRT then
            encounterIDtoEJCache[k] = VMRT.Encounter.names[k]
        end

        local name = encounterIDtoEJCache[k]
        if not name or name == "" then
            name = "Encounter ID: "..k
        end
        return name:gsub(",.+","")
    end})

    -- LR.journal_instance_name = setmetatable({}, {__index=function (t, k) -- journal_instance_id to name
    --     if not k then return nil end

    --     if not instanceIDtoEJCache[k] and EJ_GetInstanceInfo then
    --         instanceIDtoEJCache[k] = EJ_GetInstanceInfo(k)
    --     end

    --     local name = instanceIDtoEJCache[k]
    --     if not name then
    --         name = "EJ Instance ID: "..k
    --     end
    --     return name
    -- end})

    if not EJ_GetNumTiers or EJ_GetNumTiers() < 1 then
        return
    end

    local currTier = EJ_GetCurrentTier()
    local totalTiers = EJ_GetNumTiers()

    for _, inRaid in ipairs({true, false}) do
        for tier = totalTiers,1,-1  do
            EJ_SelectTier(tier)
            local instance_index = 1
            local startForTier = #encountersList + 1
            local startForTierShort = #encountersListShort + 1
            local journal_instance_id = EJ_GetInstanceByIndex(instance_index, inRaid)

            -- subtract 1 to match EXPANSION_NAME global names
            -- -1 is current season workaround
            local tier_data = MRT.F.table_find3(journalInstances,tier,1)
            if not tier_data then
                tier_data = {tier}
                tinsert(journalInstances, tier_data)
            else
                tier_data[#tier_data+1] = 0
            end
            local start_for_tier = #tier_data+1

            while journal_instance_id do
                EJ_SelectInstance(journal_instance_id)
                local instance_name, description, bgImage, buttonImage1, loreImage, buttonImage2, dungeonAreaMapID, link, shouldDisplayDifficulty, instance_id = EJ_GetInstanceInfo(journal_instance_id)
                local isMapAlreadyParsed = MRT.F.table_find3(encountersList,instance_id,1)

                if dungeonAreaMapID ~= 0 and not blacklisted_journal_instances[journal_instance_id] then
                    tinsert(tier_data, start_for_tier, journal_instance_id)
                end

                if not isMapAlreadyParsed then
                    local ej_index = 1
                    local boss, _, journalEncounterID, _, _, _, encounter_id = EJ_GetEncounterInfoByIndex(ej_index, journal_instance_id)

                    -- Encounter ids
                    local currentInstance = {instance_id}
                    while boss do
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

                    if currentInstance and #currentInstance > 1 and dungeonAreaMapID ~= 0 then
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
end

function AddonDB:InstanceIsDungeon(journal_instance_id)
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
