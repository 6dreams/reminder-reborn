-- This file represents backup system for WASync
-- Creating backup everytime WA is exported or deleted
-- Backups are keyd by uid, each backup stores a table of nested children
-- Each entry is deleted after a month of inactivity
--[[
SV entry structure:
--
{
    lastAccess = time(),
    type = "ondelete|onexport"
    [uid] = {
        id = id
        children = {uid1, uid2, uid3} -- parent -> children map in uid
        data = "serialized data" -- basic WA export ?
    }
}

]]
local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class ELib
local ELib, L = MRT.lib, MRT.L
---@class MLib
local MLib = AddonDB.MLib

---@class Locale
local LR = AddonDB.LR

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end


local WASyncArchive = {}

module.Archive = WASyncArchive

local function fillChildren(tbl,data)
    for child in module.pTraverseAllChildren(data) do
        tbl[#tbl+1] = child.uid
    end
end

---@param data table|string either a table or id to be saved
---@param source string "ondelete" or "onexport"
function WASyncArchive:Save(data,source)
    if module.PUBLIC then return end
    if not data then return end

    if type(data) == "string" then
        data = WeakAurasSaved.displays[data]
    end

    if type(data) ~= "table" then
        return
    end
    local entry = {
        id = data.id,
        uid = data.uid,
        parent = data.parent,
        lastAccess = time(),
        source = source,
        data = {
            [data.uid] = {
                id = data.id,
                data = module.TableToString(data, true)
            }
        }
    }

    if data.controlledChildren then
        entry.data[data.uid].children = {}
        fillChildren(entry.data[data.uid].children,data)
    end

    for child in module.pTraverseAllChildren(data) do
        entry.data[child.uid] = {
            id = child.id,
            data = module.TableToString(child, true)
        }
        if child.controlledChildren then
            entry.data[child.uid].children = {}
            fillChildren(entry.data[child.uid].children,child)
        end
    end
    WASyncArchiveDB = WASyncArchiveDB or {}
    WASyncArchiveDB[data.uid] = entry
    if module.options and module.options.tab and module.options.tab.tabs[2] and module.options.tab.tabs[2]:IsVisible() then
        module.options.tab.tabs[2]:UpdateData()
    end
end

local function GetData(entry,uid)
    if not entry then return end
    local data = entry[uid]
    if not data then return end

    local d = module.StringToTable(data.data, true)
    return d
end

function WASyncArchive:Restore(entry, uid)
    if not entry then return end

    local data = entry.data[uid]
    local transmit = {
        m = "d",
        d = GetData(entry.data,uid),
        v = 2000,
        s = WeakAuras.versionString,
    }

    if not data.children then
        return transmit
    end

    local c = {}
    for i=1,#data.children do
        c[i] = GetData(entry.data,data.children[i])
    end
    transmit.c = c

    return transmit
end

function module.options:LoadArchive()
    self = module.options.tab.tabs[2]

    if module.PUBLIC then
        self.button:Hide()
    end


    self.scrollList = ELib:ScrollButtonsList(self):Point("TOPLEFT",0,-2):Size(798,578)
	self.scrollList.ButtonsInLine = 1
	self.scrollList.mouseWheelRange = 50
	ELib:Border(self.scrollList,0)


	local function ButtonLevel1Click(self,button) -- level 1 click
		if button == "LeftButton" then
			local parent = self:GetParent():GetParent()
			local uid = self.uid
			parent.stateExpand[uid] = not parent.stateExpand[uid]
			parent:Update()
		elseif button == "RightButton" then

		end
	end

	function self.scrollList:ButtonClick(button) -- level 2 click
		local data = self.data
		if not data then
			return
		end
		if button == "RightButton" then

		elseif button == "LeftButton" then
            local UID = self.data.UID
            local entry = self.data.entry
            local d = WASyncArchive:Restore(entry, UID)

            local queueItem = {
                str = d,
                sender = "Backup",
                id = self.data.name,
                importMode = 3,
                stringNum = 1,
                imageNum = 1,
            }

            module.QueueFrame:AddToQueue(queueItem)
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
		GameTooltip_Hide()
	end

    local function GetWATree(entry,UID)
        local tree = {}
        local function traverse(uid, depth, parent)
            local data = entry.data[uid]
            tree[uid] = {
                depth = depth,
                parent = parent,
                id = data.id,
                children = data.children
            }
            if data.children then
                for i=1,#data.children do
                    traverse(data.children[i], depth+1, uid)
                end
            end
        end
        traverse(UID, 0, nil)
        return tree
    end

	local function Button_OnEnter(self)
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")

        local entry = self.data.entry
        local UID = self.data.UID
        local data = entry.data[UID]
        local tree = GetWATree(entry,UID)

        local added = {}
        local function traverse(uid, depth)
            local data = tree[uid]
            local line = ""
            for i=1,depth do
                line = line .. "    "
            end
            line = line .. data.id
            if not added[uid] then
                added[uid] = true
                GameTooltip:AddLine(line)
            end
            if data.children then
                for i=1,#data.children do
                    traverse(data.children[i], depth+1)
                end
            end
        end
        traverse(UID, 0)

		GameTooltip:Show()
	end

	local function Button_Lvl1_Remove(self)
		StaticPopupDialogs["WASYNC_ARCHIVE_CLEAR_LVL1_REMOVE"] = {
			text = LR.DeleteSection.."?",
			button1 = YES,
			button2 = NO,
			OnAccept = function()
                WASyncArchiveDB[self:GetParent().data.UID or ""] = nil

				module.options.tab.tabs[2]:UpdateData()

			end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
		}
		StaticPopup_Show("WASYNC_ARCHIVE_CLEAR_LVL1_REMOVE")
	end


	function self.scrollList:ModButton(button,level)
		if level == 1 then
			local textObj = button:GetTextObj()
            textObj:SetFont(textObj:GetFont(), 13,"OUTLINE")
			textObj:SetPoint("LEFT",5+30+3,0)

			button.bossImg = button:CreateTexture(nil, "ARTWORK")
			button.bossImg:SetSize(28,28)
			button.bossImg:SetPoint("LEFT",5,0)
            button.bossImg:SetTexture("Interface\\AddOns\\WeakAuras\\Media\\Textures\\logo_256_round.tga")

			button.remove = Button_Create(button,20):Point("RIGHT",button,"RIGHT",-30,0)
			button.remove:SetScript("OnClick",Button_Lvl1_Remove)
			button.remove.texture:SetTexture("Interface\\AddOns\\ExRT_Reminder\\Media\\Textures\\delete")

			button.Texture:SetGradient("VERTICAL",CreateColor(.13,.13,.13,1), CreateColor(.16,.16,.16,1))

			button:OnClick(ButtonLevel1Click)
			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		elseif level == 2 then
			local textObj = button:GetTextObj()
            textObj:SetFont(textObj:GetFont(), 12,"OUTLINE")
			textObj:SetPoint("LEFT",button,"LEFT",5,0)
			textObj:SetPoint("RIGHT",button,"LEFT",300,0)

			button:SetScript("OnEnter",Button_OnEnter)
			button:SetScript("OnLeave",Button_OnLeave)

			button:RegisterForClicks("LeftButtonUp","RightButtonUp")
		end
	end

	function self.scrollList:ModButtonUpdate(button, level)
		if level == 1 then

		elseif level == 2 then
			button:GetTextObj():SetWordWrap(false)

			-- local data = button.data
            button.Texture:SetGradient("HORIZONTAL",CreateColor(.1,.5,1,.35), CreateColor(.1,.5,1,.6))
		end
	end

	function self:UpdateData()
		local Mdata = {}
		for _,entry in next, WASyncArchiveDB do
            local id = entry.id
            local mainuid = entry.uid
            local lastAccess = entry.lastAccess

			local tableToAdd = {
                name = id .. " | " .. (entry.source or "") .. " | " .. date("%d.%m.%Y %H:%M:%S",lastAccess),
                uid = mainuid .. id .. lastAccess,
                data = {},
                lastAccess = lastAccess,
                UID = mainuid,
                entry = entry,
            }

            Mdata[#Mdata+1] = tableToAdd
            local tree = GetWATree(entry,mainuid)

            local added = {}
            local function traverse(uid, depth)
                if not added[uid] then
                    local data = tree[uid]
                    added[uid] = true
                    local prefix = depth > 0 and ("   "):rep(depth) .. "- " or ""
                    tableToAdd.data[#tableToAdd.data+1] = {
                        name = prefix .. data.id or ("~"..LR.NoName),
                        uid = uid .. lastAccess,
                        data = data,
                        UID = uid,
                        entry = entry,
                    }

                    if data.children then
                        for i=1,#data.children do
                            traverse(data.children[i], depth+1)
                        end
                    end
                end
            end
            traverse(mainuid, 0)
		end

		sort(Mdata,function(a,b)
			return a.lastAccess > b.lastAccess
		end)

		self.scrollList.data = Mdata
		self.scrollList:Update(true)
	end

	self:UpdateData()
    self:SetScript("OnShow",function()
        self:UpdateData()
    end)
end
