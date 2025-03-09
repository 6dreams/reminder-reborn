--[=[

Target group is a weak aura with the same ID as the imported weak aura or in case the imported weak aura
does not exists on user's side then the target group is the imported weak aura itself.

Deleting notes:
    If there is an ID collision with a weak aura that exists outside the target group, the user's weak aura is deleted.
    If a weak aura with the same ID does not exist, it checks for a weak aura with the same UID and deletes it if it exists.
    If target group has weak aura that does not exist in the imported data, the user's weak aura is deleted.
    Note that the delete process also deletes all children of the deleted weak aura.

    There is currently no technique to handle weak aura duplicates, so all collisions are handled by deleting the weak aura.
    Before deleting any weak aura, it is saved to the archive(with all the children).

Assigning parent notes:
     If the imported weak aura was a top-level aura on the sender's side:
        1. If the weak aura exists on the user's side and has a parent, it is assigned to the existing parent.
        2. Else if the weak aura exists on the user's side but does not have a parent, it remains a top-level aura.

    If the imported weak aura had a parent aura on the sender's side:
        1. If the parent of the weak aura exists on the user's side, it is assigned to that parent.
        2. Else if the weak aura exists on the user's side and has a parent, it is assigned to the existing parent.
        3. Else if the weak aura does not exist on the user's side, it remains a top-level aura.

No support for importing data with SortHybridTable, it may error/import incorrectly.

]=]

local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

-- ---@class Locale
-- local LR = AddonDB.LR

-- ---@class MLib
-- local MLib = AddonDB.MLib

---@class WASyncPrivate
local WASync = AddonDB.WASYNC


local prettyPrint = module.prettyPrint

-- upvalues
local bit_band = bit.band
local max = math.max
local tIndexOf = tIndexOf
local tinsert = tinsert
local tContains = tContains
local ipairs = ipairs
local ipairs_reverse = ipairs_reverse
local next = next
local coroutine_yield = coroutine.yield
local format = string.format
local xpcall = xpcall
local geterrorhandler = geterrorhandler


function module:CompressAndSend(id,updateLastSync,justEnqueue,hideFrameOnFinish)
	local ImportType = module.SenderFrameData.ImportType
    local channel = module.SenderFrameData.customChannel
    local touser = module.SenderFrameData.customTarget
    local skipPrompt = module.SenderFrameData.skipPrompt
    local needReload = module.SenderFrameData.needReload

	if not (touser and channel == "WHISPER") then
		local isPass, reason = AddonDB:CheckSelfPermissions(WASync.isDebugMode)
		if not isPass then
			prettyPrint(module.WASYNC_ERROR, reason)
			return
		end
	end

	local data = WeakAuras.GetData(id)
	if not data then
		prettyPrint(module.WASYNC_ERROR, "WA does not exist!")
		return
	end
	module.SenderFrame.bar:SetValue(0)
    -- module.SenderFrame.EstimateTimeLeft:SetText("Creating backup...")
    -- module.Archive:Save(data,"On Export")
    module.SenderFrame.EstimateTimeLeft:SetText("Exporting...")

    if not data.exrtLastSync or updateLastSync then
        local now = time()
        for c in module.pTraverseAll(data) do
            c.exrtLastSync = now
        end
    end
    data.exrtLastSender = MRT.SDB.charKey


    if ImportType == 3 then
        data.exrtUpdateConfig = module.SenderFrameData.updateConfig or 0
    end

    -- local start = debugprofilestop()
	local str = module.DisplayToString(data)
    if not str then
        module.SenderFrame.EstimateTimeLeft:SetText("|cffff0000Error exporting!|r")
        return
    end
    -- prettyPrint("exported in", debugprofilestop() - start, "ms")

	-- WeakAuras.Import(str) -- to test export string

    if justEnqueue then
        module.SenderFrame.EstimateTimeLeft:SetText("Ctrl Click to send")
        prettyPrint(format("|cff88ff88ENQUED:|r %q | %s | %s", id, WASync.ImportTypes[ImportType], touser or channel or "Auto"))
    end

    module:SendWA({
        str = str,
        id = id,
        importMode = ImportType,
        channel = channel,
        touser = touser,
        skipPrompt = skipPrompt,
        exrtLastSync = not updateLastSync and data.exrtLastSync,
        needReload = needReload
    }, justEnqueue, hideFrameOnFinish)


    module.SenderFrame:Update()
end

--------------------------------------------------------------------------------------------------------------------------------
-- Import Functions
--------------------------------------------------------------------------------------------------------------------------------
local update_ignore_fields

-- config is a bitfield, we need to conver it to a table of fields from WASync.update_categories
local function parseUpdateConfig(config)
    update_ignore_fields = {}
    for i=1,#WASync.update_categories do
        if bit_band(config,2^(i-1)) > 0 then
            for j,field in next, WASync.update_categories[i].fields do
                update_ignore_fields[field] = true
            end
        end
    end
end
update_ignore_fields = parseUpdateConfig(module.getDefaultUpdateConfig())

local function table_update(tableFrom,tableTo,isSublevel)
	local keysToRemove = {}
	for key,val in next, tableFrom do
		keysToRemove[key] = true
	end
	for key,val in next, tableTo do
		if type(val) == 'table' and type(tableFrom[key]) == 'table' and not update_ignore_fields[key] then
			keysToRemove[key] = nil
			table_update(tableFrom[key],tableTo[key],true)
		else
			keysToRemove[key] = nil
			if isSublevel or not update_ignore_fields[key] then
				tableFrom[key] = tableTo[key]
			end
		end
	end
	for key,_ in next, keysToRemove do
		tableFrom[key] = nil
	end
end

local importedAuras = {}
local childernMap = {}
local parentMap = {}
local uidtodata = {}
local aurasToDelete = {}


local function CreateChildParentMaps(data,children)
    local id = data.id
    if data.controlledChildren then
        childernMap[id] = data.controlledChildren
        data.controlledChildren = {}
    end
    if data.parent then
        parentMap[id] = data.parent
        data.parent = nil
    end
	if children then
		for i,child in ipairs(children) do
			CreateChildParentMaps(child)
		end
	end
end

local function RestoreChildParentRelations()
    for id,controlledChildren in next, childernMap do
        local data = WeakAuras.GetData(id)
		if data then
			data.controlledChildren = controlledChildren
		end
    end
    for id,parent in next, parentMap do
        local parentData = WeakAuras.GetData(parent)
        if parentData and parentData.controlledChildren then
            if not tContains(parentData.controlledChildren, id) then
                tinsert(parentData.controlledChildren, id)
            end
        end
		local data = WeakAuras.GetData(id)
		if data then
			data.parent = parent
		end
    end
end

-- when importing groups we need to make sure that auras which were in the oldData but not in the newData are deleted
-- delete must be processed with WeakAuras.Delete(data), data is got by WeakAuras.GetData(id)
local function DeleteDisplayAndChildren(data)
	aurasToDelete[data.id] = true
	if data.controlledChildren then
		for i,childID in ipairs(data.controlledChildren) do
			local childData = WeakAuras.GetData(childID)
			if childData then
				DeleteDisplayAndChildren(childData)
			end
		end
	end
end

-- Deletes all WA that are in oldData but not in newData.
-- If WA with the same ID does not exist then it looks
-- for WA with the same UID and deletes it if it exists.
local function DeleteNotFound(data)
    local id = data.id
    local uid = data.uid

    local oldData = WeakAuras.GetData(id)
    if not oldData then -- check for uid and if is then delete it
        local uidData = uid and uidtodata[uid] or nil -- какие подводные?
        if uidData then
            module.Archive:Save(uidData,"On Delete")
            DeleteDisplayAndChildren(uidData)
        end
    elseif oldData and oldData.controlledChildren and data.controlledChildren then
        for i, childID in ipairs(oldData.controlledChildren) do
            if not tContains(data.controlledChildren, childID) then
                local childData = WeakAuras.GetData(childID)
                if childData then
                    module.Archive:Save(childData,"On Delete")
                    DeleteDisplayAndChildren(childData)
                end
            end
        end
    end
end

local function DeletePhase2()
    for id in next, aurasToDelete do
		local data = WeakAuras.GetData(id)
        if data then
		    WeakAuras.Delete(data)
            coroutine_yield()
        end
		prettyPrint(format("%q deleted", id))
	end
end

local function WA_Add_Phase1(data)
    WeakAuras.Add(data)
end
local function WA_Add_Phase2(data)
    local id = data.id
    data = WeakAuras.GetData(id)
    if data then
        xpcall(WeakAuras.Add, geterrorhandler(), data)
    end
end

local function processDefaultLoadNever(data)
    local dln = data.exrtDefaultLoadNever
    if (dln == 1 and not WeakAuras.GetData(data.id)) or dln == 3 then
        if data.load then
            data.load.use_never = true
        end
        return true
    elseif (dln == 2 and not WeakAuras.GetData(data.id) or dln == 4) then
        if data.load then
            data.load.use_never = false
        end
        return false
    end
end

local function SingularImport(data,importMode)
    importedAuras[data.id] = true
    if importMode == 2 then
        -- import only missing WAs
        if WeakAuras.GetData(data.id) then
            return
        end
        xpcall(WA_Add_Phase1, geterrorhandler(), data)
	elseif importMode == 3 then
        -- update WAs
        local old = WeakAuras.GetData(data.id)
        local old_use_never = processDefaultLoadNever(data)
        if old then
            if old_use_never == nil and old["load"] then
                old_use_never = old["load"]["use_never"]
            end

            table_update(old,data,false)

            if old["load"] then
                old["load"]["use_never"] = old_use_never
            end
            xpcall(WA_Add_Phase1, geterrorhandler(), old)
        else
            xpcall(WA_Add_Phase1, geterrorhandler(), data)
        end
    elseif importMode == 4 then
        -- force update except use_never
        local old = WeakAuras.GetData(data.id)
        local old_use_never = processDefaultLoadNever(data)
        if old then

            if old_use_never == nil and old["load"] then
                old_use_never = old["load"]["use_never"]
            end

            table_update(old,data,true)

            if old["load"] then
                old["load"]["use_never"] = old_use_never
            end
            xpcall(WA_Add_Phase1, geterrorhandler(), old)
        else
            xpcall(WA_Add_Phase1, geterrorhandler(), data)
        end
    elseif importMode == 5 then
        -- force full update WAs
        xpcall(WA_Add_Phase1, geterrorhandler(), data)
	end
end

-- -- tip to hook for Private
local displayButtonsArray = {}
local WeakAurasPrivate
local PrivateHook = CreateFrame("Frame")
PrivateHook:RegisterEvent("ADDON_LOADED")
PrivateHook:SetScript("OnEvent",function(self,event,addon)
    if addon == "WeakAurasOptions" then
        hooksecurefunc(WeakAuras,"ToggleOptions",function(msg,_Private)
            if _Private then
                WeakAurasPrivate = _Private
            end
        end)

        local AceGUI = LibStub("AceGUI-3.0")
        if not AceGUI then return end

        local _WeakAurasDisplayButton = AceGUI.WidgetRegistry.WeakAurasDisplayButton
        if not _WeakAurasDisplayButton then return end

        function AceGUI.WidgetRegistry.WeakAurasDisplayButton()
            local obj = _WeakAurasDisplayButton()
            displayButtonsArray[#displayButtonsArray+1] = obj
            local _Initialize = obj.Initialize
            if not _Initialize then return obj end

            function obj:Initialize()
                _Initialize(self)

                if not obj.menu then return end

                local first_separator = MRT.F.table_find(obj.menu," ", "text")
                local startpos = first_separator or 7

                tinsert(obj.menu,startpos,{
                    text = " ",
                    notClickable = true,
                    notCheckable = true,
                })
                tinsert(obj.menu,startpos+1,{
                    text = "|cFF8855FFWASync|r Send...",
                    notCheckable = true,
                    func = function()
                        local id = self.data.id
                        module:ExternalExportWA(id)
                    end
                })
                tinsert(obj.menu,startpos+2,{
                    text = "|cFF8855FFWASync|r Check Version",
                    notCheckable = true,
                    func = function()
                        local id = self.data.id
                        MRT.Options:OpenByModuleName("WAChecker")
                        module.options.filterEdit:SetText("")
                        module.options.filterEdit:SetText(id)
                        module:GetWAVer(id)
                    end
                })
            end
            return obj
        end

        self:UnregisterEvent("ADDON_LOADED")
    end
end)

local function StopWeakAuras()
	if not WeakAuras.IsOptionsOpen() then
        if not WeakAuras.IsPaused() then
            WeakAuras.Toggle()
        end
    end
end

local function ReloadWeakAuras()
	if not WeakAuras.IsOptionsOpen() then
        if not WeakAuras.IsPaused() then
            WeakAuras.Toggle()
            WeakAuras.Toggle()
        else
            WeakAuras.Toggle() -- maybe i will break some stuff here?
        end
    end
end

local function UpdateOptions(data,children)
    -- print("UpdateOptions", WeakAurasOptions)
    if not WeakAurasOptions then return end
    -- local start = debugprofilestop()

	local wasShown = WeakAurasOptions:IsVisible()
	if wasShown then WeakAurasOptions:Hide() end -- WeakAuras.HideOptions()
    -- reload system now so we now which auras are loaded
    WeakAuras.Toggle()
    WeakAuras.Toggle()

    -- prettyPrint("UpdateOptions1", debugprofilestop() - start)
    -- ensure display buttons exists? was earlier in p1 add
    if WASYNC_OPTIONS_PRIVATE then
        if children then
            for i,child in ipairs(children) do
                WASYNC_OPTIONS_PRIVATE.AddDisplayButton(child)
                coroutine_yield()
            end
        end
        WASYNC_OPTIONS_PRIVATE.AddDisplayButton(data)
    else
        if children then
            for i,child in ipairs(children) do
                WeakAuras.NewDisplayButton(child, true)
                coroutine_yield()
            end
        end
        WeakAuras.NewDisplayButton(data,true) -- NO LONGER SORTING XXX sorting data before iterating display buttons so we can find all of them
    end


    local displayButtons = {}

    if WASYNC_OPTIONS_PRIVATE then
        displayButtons = WASYNC_OPTIONS_PRIVATE.displayButtons
    else
        for i,obj in ipairs(displayButtonsArray) do
            local data = obj.data
            if obj.type == "WeakAurasDisplayButton" and data and importedAuras[data.id] then
                importedAuras[data.id] = nil
                displayButtons[data.id] = obj
            end
        end

    end

    -- prettyPrint("UpdateOptions4", debugprofilestop() - start)

    if WASYNC_OPTIONS_PRIVATE or true then
        local id = data.id
        local data = WeakAuras.GetData(id)
        local obj = displayButtons[id]

        obj:SetData(data)
        if data.parent  then
            local parent = WeakAuras.GetData(data.parent)
            obj:SetGroup(data.parent,parent.regionType == "dynamicgroup")
            local total = #parent.controlledChildren
            for j,child in ipairs(parent.controlledChildren) do
                if child == id then
                    obj:SetGroupOrder(j,total)
                    break
                end
            end
        else
            obj:SetGroup()
            obj:SetGroupOrder(nil, nil)
        end

        obj.callbacks.UpdateExpandButton()
        if obj.UpdateParentWarning then
            obj:UpdateParentWarning()
        end

        WeakAuras.UpdateGroupOrders(data)
        WeakAuras.UpdateThumbnail(data)
        WeakAuras.ClearAndUpdateOptions(data.id)
        coroutine_yield()
        if children then
            for i,child in ipairs(children) do
                local id = child.id
                local data = WeakAuras.GetData(id)
                local obj = displayButtons[id]

                obj:SetData(data)
                if data.parent  then
                    local parent = WeakAuras.GetData(data.parent)
                    obj:SetGroup(data.parent,parent.regionType == "dynamicgroup")
                    local total = #parent.controlledChildren
                    for j,child in ipairs(parent.controlledChildren) do
                        if child == id then
                            obj:SetGroupOrder(j,total)
                            break
                        end
                    end
                else
                    obj:SetGroup()
                    obj:SetGroupOrder(nil, nil)
                end

                obj.callbacks.UpdateExpandButton()
                if obj.UpdateParentWarning then
                    obj:UpdateParentWarning()
                end

                WeakAuras.UpdateGroupOrders(data)
                WeakAuras.UpdateThumbnail(data)
                WeakAuras.ClearAndUpdateOptions(data.id)
                coroutine_yield()
            end
        end
    end

    -- prettyPrint("UpdateOptions5", debugprofilestop() - start)
	if wasShown then WeakAuras.OpenOptions() end -- it will do right things if we're in combat or something
    if WASYNC_OPTIONS_PRIVATE and WASYNC_OPTIONS_PRIVATE.SortDisplayButtons then
        WASYNC_OPTIONS_PRIVATE.SortDisplayButtons()
    else
        WeakAurasOptions.filterInput:SetText("")
        WeakAurasOptions.filterInput:GetScript("OnTextChanged")(WeakAurasOptions.filterInput)
    end
    WeakAuras.PickDisplay(data.id, (data.regionType == "group" or data.regionType == "dynamicgroup") and "group" or "region") -- this is required to expand all groups on th way to imported data
    -- prettyPrint("UpdateOptions6", debugprofilestop() - start)
end


-- This is processing of sent string copied from WeakAuras.Import
local function WAImport(inData,importMode,callbackFunction)
    local start = debugprofilestop()
    -- convert import string to tables
    local data, children, version
    if type(inData) == 'string' then
        -- encoded data
        local received = module.StringToTable(inData)
        if type(received) == 'string' then
            -- this is probably an error message from LibDeflate. Display it.
            module.ShowTooltip{
                {1, "WeakAuras Sync", 0.5, 0, 1},
                {1, received, 1, 0, 0, 1}
            }
            return nil, received
        elseif received.m == "d" then
            data = received.d
            children = received.c
            version = received.v
        end
    elseif type(inData.d) == 'table' then
        data = inData.d
        children = inData.c
        version = inData.v
    end
    if type(data) ~= "table" then
        return nil, "Invalid import data."
    end

    if version < 2000 then
        if children then
            data.controlledChildren = {}
            for i, child in ipairs(children) do
                tinsert(data.controlledChildren, child.id)
                child.parent = data.id
            end
        end
    end

    local needPreAdd = true
    local highestVersion = data.internalVersion or 0
    if children then
        for _, child in ipairs(children) do
            highestVersion = max(highestVersion, child.internalVersion or 0)
        end
    end
    if highestVersion > WeakAuras.InternalVersion() then
        -- Do not run PreAdd
        needPreAdd = false
    end

    -- print("decompressed in", debugprofilestop() - start, "ms")

    StopWeakAuras()
    -- print("paused in", debugprofilestop() - start, "ms")

	-- here import itself is starting
	-- 1. run preAdd if it is needed
	-- 2. delete all data that is part of a target group but not in the import data
	-- 3. create map of children and parents from data that is going to be imported
    -- TODO: consider mapping sortHybridTable, make yields more reasonable?
	-- 4. import clean data
	-- 5. restore children and parents relationship using map that was created earlier
    -- 6. fix parent's controlledChildren
    -- 7. ensure that all displays have correct parent child relationship, ensure all UIDs are unique
    -- 8. reimport mapped data
    -- 9. update WeakAuras options
    -- 10. reload WeakAuras so updated data is applied

    importedAuras = {}
    childernMap = {}
	parentMap = {}
    uidtodata = {}
    aurasToDelete = {}

    if importMode == 3 then
        if data.exrtUpdateConfig and type(data.exrtUpdateConfig) == "number" then
            parseUpdateConfig(data.exrtUpdateConfig)
        else
            parseUpdateConfig(module.getDefaultUpdateConfig())
        end
    end

    local oldData = WeakAuras.GetData(data.id)
    local oldParent = oldData and oldData.parent
    if oldParent and children then -- special case of circular dependency, if user places imported group into wa that was part of the imported group we get circular dependency
        -- scan if oldParent is in the import
        for par in module.pTraverseParents(oldData) do
            for i,child in ipairs(children) do
                if child.id == par.id then
                    oldData.parent = nil
                    oldParent = nil

                    -- archive singular
                    -- par.parent = nil
                    -- par.controlledChildren = nil
                    -- module.Archive:Save(par,"Circular Dependency")

                    WeakAuras.Delete(par)
                end
            end
        end
    end

    local parent = data.parent

    if needPreAdd then
        WeakAuras.PreAdd(data)
        if children then
            for i,child in ipairs(children) do
                if i % 10 == 0 then coroutine_yield() end
                WeakAuras.PreAdd(child)
            end
        end
    end

    -- print("preadded in", debugprofilestop() - start, "ms")
    coroutine_yield()

    for _,data in next, WeakAurasSaved.displays do
        uidtodata[data.uid] = data
    end

    -- print("created uid map in", debugprofilestop() - start, "ms")

    -- phase 1

	DeleteNotFound(data)
	if children then
		for i,child in ipairs(children) do
            if i % 10 == 0 then coroutine_yield() end
			DeleteNotFound(child)
		end
	end
    -- print("deleted in", debugprofilestop() - start, "ms")
    coroutine_yield()

    DeletePhase2()

	CreateChildParentMaps(data,children)
    -- print("created maps in", debugprofilestop() - start, "ms")
    coroutine_yield()

    SingularImport(data,importMode)
    if children then
        for i,child in ipairs(children) do
            coroutine_yield()
            SingularImport(child,importMode)
        end
    end
    -- print("imported in", debugprofilestop() - start, "ms")
    coroutine_yield()

    -- phase 2
    RestoreChildParentRelations()
    -- print("restored relations in", debugprofilestop() - start, "ms")

    --fix controlledChildren of parent
    local parentData = WeakAuras.GetData(parent)
    if parentData then
        local indexOfMe = tIndexOf(parentData.controlledChildren, data.id)
        data.parent = parent
        if not indexOfMe then
            tinsert(parentData.controlledChildren, data.id)
        end
    elseif oldParent then
		local oldData = WeakAuras.GetData(data.id)
        if oldData then
			oldData.parent = oldParent -- another GetData is needed coz data is not guaranteed to be imported, it may be updated with table_update
		end
    end

    coroutine_yield()

	-- removing "saved variables corruption" notification, should not use this in ideal world
    -- for now main purpose is to fix WA's that were out of imported group
    module.SyncParentChildRelationships(true)
    module.ValidateUniqueDataIds(true)
    -- print("fixed relations in", debugprofilestop() - start, "ms")
    coroutine_yield()

    if children then
        for i,child in ipairs_reverse(children) do
            if i % 10 == 0 then coroutine_yield() end
            WA_Add_Phase2(child)
        end
    end
    WA_Add_Phase2(data)
	if oldParent then
		local oldParentData = WeakAuras.GetData(oldParent)
		if oldParentData then
			WA_Add_Phase2(oldParentData)
		end
	end
    -- print("reimported in", debugprofilestop() - start, "ms")
    coroutine_yield()

    UpdateOptions(data,children)
    -- print("updated options in", debugprofilestop() - start, "ms")

    ReloadWeakAuras()

    local t = string.format("%.2f", debugprofilestop() - start)

    prettyPrint(format("|cff22ff22IMPORTED:|r %q in %s ms", data.id, t))

    -- print("imported in", debugprofilestop() - start, "ms")

    -- clear references
    importedAuras = {}
    childernMap = {}
	parentMap = {}

    callbackFunction(true, data.id)
    return true
end

function module:ImportWA(dataStr, sender, importMode)
    if type(dataStr) == "string" then
        dataStr = module.StringToTable(dataStr, sender == "WAS Import" and true or false)
    end

    local success, error
    if importMode == 1 then
		local importFunc = WASYNC_MAIN_PRIVATE and WASYNC_MAIN_PRIVATE.Import or WeakAurasPrivate and WeakAurasPrivate.Import or WeakAuras.Import
        success, error = importFunc(dataStr, nil, module.QueueFrame.RemoveFromQueue)
    else
        if WASync.RELOAD_AFTER_IMPORTS then
            module.QueueFrame.needReload = true
        end
        success, error = WAImport(dataStr, importMode, module.QueueFrame.RemoveFromQueue)
    end

	if not success and error ~= nil then
		module:ErrorComms(sender, "ERROR", tostring(success) .. "\t" .. tostring(error))
        module.QueueFrame.RemoveFromQueue()
	end
end

function module:SetLoadNever(id, value, level)
	if not level then
		StopWeakAuras()
	end
	local data = WeakAuras.GetData(id)
	if data then
		if data.controlledChildren then
			for _,childID in ipairs(data.controlledChildren) do
				module:SetLoadNever(childID, value, (level or 0) + 1)
			end
		else
			if data.load then
				data.load.use_never = value
				prettyPrint(format("%q load.use_never set to %s", tostring(id), tostring(value)))
				WeakAuras.Add(data)
			end
		end
	end
	if not level then
		ReloadWeakAuras()
	end
end

function module:QuickImportWA(data)
	if not data or type(data) ~= "table" then
		prettyPrint(module.WASYNC_ERROR, "Invalid data!")
		return
	end

	StopWeakAuras()

	xpcall(WeakAuras.Add, geterrorhandler(), data)
	if data.parent then
		local parent = WeakAuras.GetData(data.parent)
		if parent then
			xpcall(WeakAuras.Add, geterrorhandler(), parent)
		end
	end

	ReloadWeakAuras()
end
