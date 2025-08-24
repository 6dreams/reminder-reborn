local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)

do -- Archive stuff
	local Archivist = select(2, ...).Archivist
	local function OpenArchive()
		if Archivist:IsInitialized() then
			return Archivist
		else
			Archivist:Initialize(ReminderArchive)
		end
		return Archivist
	end

	function AddonDB.LoadFromArchive(storeType, storeID)
		local Archive = OpenArchive()
		return Archive:Load(storeType, storeID)
	end
end

local histRepo
local function loadHistory()
	if not histRepo then
		histRepo = AddonDB.LoadFromArchive("Repository", "history")
	end
	return histRepo
end

function AddonDB.CleanArchive(historyCutoff)
	if VMRT.Reminder.lastArchiveCheck or 0 < time() - 86400 then
		VMRT.Reminder.lastArchiveCheck = time()
		local repo = loadHistory()
		local cutoffTime = time() - (historyCutoff * 86400)

		for uid, subStore in next, repo.stores do
			-- Ideally we would just use Clean and not access the stores list directly,
			-- but that'd mean having Clean take a predicate which seems like overkill for the moment
			if not subStore.pinned and subStore.timestamp < cutoffTime then
				repo:Drop(uid)
			end
		end

		if ReminderLog.history then
			for encounterID,tbl in next, ReminderLog.history do
				for diffID,history in next, tbl do
					for i=#history,1,-1 do
						if not history[i].pinned and history[i] and history[i].date < cutoffTime then
							local entry = tremove(history, i)
							if type(entry.log) == "string" then
								AddonDB.RemoveHistory(entry.log)
							end
						end
					end
					if #history == 0 then
						tbl[diffID] = nil
					end
				end
				if not next(tbl) then
					ReminderLog.history[encounterID] = nil
				end
			end
		end


		for k,v in next, WASyncArchiveDB do
			if v.lastAccess < cutoffTime then
				WASyncArchiveDB[k] = nil
			end
		end
	end
end

function AddonDB.SetHistory(uid, data, source)
	if uid and data then
		local start = debugprofilestop()
		local repo = loadHistory()
		data.source = source
		local hist = repo:Set(uid, data, true)
		GMRT.A.Reminder.prettyPrint("Saved pull history:", format("%d", debugprofilestop() - start), "ms,", #data, "entries")
		return hist
	end
end

local function GetHistory(uid, load)
	return loadHistory():Get(uid, load)
end

function AddonDB.RemoveHistory(uid)
	return loadHistory():Drop(uid)
end

function AddonDB.RestoreFromHistory(uid)
	local subStore, histData = GetHistory(uid, true)
	if histData then
		return histData
	end
end

function AddonDB.SetHistoryPinnedState(uid, pinned)
	local subStore = GetHistory(uid)
	if subStore then
		subStore:SetPinned(pinned)
	end
end

function AddonDB.GetHistoryPinnedState(uid)
	local subStore = GetHistory(uid)
	if subStore then
		return subStore.pinned
	end
end

AddonDB:RegisterCallback("EXRT_REMINDER_ADDON_LOADED", function()
	AddonDB.CleanArchive(30) -- clean history and WAArchive data older than 30 days
end)
