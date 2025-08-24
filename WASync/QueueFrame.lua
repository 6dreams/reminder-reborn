local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

---@class ELib
local ELib = MRT.lib

---@class Locale
local LR = AddonDB.LR

---@class MLib
local MLib = AddonDB.MLib

---@class WASyncPrivate
local WASync = AddonDB.WASYNC

-- upvaluse
local prettyPrint = module.prettyPrint

--------------------------------------------------------------------------------------------------------------------------------
-- Queue Frame
--------------------------------------------------------------------------------------------------------------------------------

---@class WASyncImportQueueItem
---@field str string|table
---@field sender string
---@field id string
---@field importType number
---@field stringNum number
---@field imageNum number
---@field skipPrompt boolean?
---@field needReload boolean?
---@field postImportCallback function?


local importText = ELib:Text(UIParent, "|cFF8855FF[WAS]|r Importing...",60):Point("TOP",0,-50):Color(1,1,1):Outline()
importText:Hide()

---@class QueueFrame
local QueueFrame = ELib:Popup("|cFF8855FFWeakAuras Sync Import|r"):Size(450,275)
---@type QueueFrame
module.QueueFrame = QueueFrame

QueueFrame.Close:Hide()
QueueFrame:SetFrameStrata("FULLSCREEN_DIALOG")
ELib:Border(QueueFrame,1,.24,.25,.30,1,nil,3)
QueueFrame:Hide()

QueueFrame.memeSender = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-20):Color()
QueueFrame.currentWA = ELib:Text(QueueFrame,"Importing WA:"):Point("TOPLEFT",10,-54):Color()
QueueFrame.currentWATitle = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-70):Color()
QueueFrame.ImportTypeText = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-86):Color()
QueueFrame.importsLeft = ELib:Text(QueueFrame,""):Point("TOPLEFT",10,-115):Color(0.3,1,0.3)
QueueFrame.texture = ELib:Texture(QueueFrame):Point("BOTTOMRIGHT",QueueFrame,"BOTTOMRIGHT",-5,70):Size(170,170)
QueueFrame.processNextButton = MLib:Button(QueueFrame,LR.Import,15):Point("BOTTOM",QueueFrame,"BOTTOM",0,30):Size(440,25):OnClick(function()
	QueueFrame:Hide()
	MLib:DialogPopupHide("WA_SYNC_SKIP_IMPORT_CONFIRMATION")
	QueueFrame:ProcessNext()
end)
QueueFrame.processNextButton.Texture:SetGradient("VERTICAL",CreateColor(0.12,0.7,0.12,1), CreateColor(0.14,0.5,0.14,1))

QueueFrame.skipNextButton = MLib:Button(QueueFrame,LR.Skip,15):Point("TOP",QueueFrame.processNextButton,"BOTTOM",0,-5):Size(440,20):OnClick(function()
	MLib:DialogPopup({
		id = "WA_SYNC_SKIP_IMPORT_CONFIRMATION",
		title = LR["Skip Import"],
		text = LR.WASyncUpdateSkipTitle,
		buttons = {
			{
				text = format("|cffff0000%s|r", LR.Skip),
				func = function()
					local queueItem = QueueFrame:SkipImport()
					module:ErrorComms(queueItem.sender, 2, queueItem.id)
					module:SendWAVer(queueItem.id)
				end
			},
			{
				text = NO,
			}
		},
		alert = true,
	})
end)
QueueFrame.skipNextButton.Texture:SetGradient("VERTICAL",CreateColor(0.7,0.12,0.12,1), CreateColor(0.5,0.14,0.14,1))

function QueueFrame.SetupSession()
	---@type WASyncImportQueueItem
	local queueItem = QueueFrame.queue[1]

	QueueFrame.SessionStarted = true
	QueueFrame:Update()
	if module.PUBLIC then
		QueueFrame.texture:Color(1,1,1,0.05)
		QueueFrame.texture:SetTexture(AddonDB:GetImage())
		QueueFrame.memeSender:SetText(WASync.QueueSenderStrings[1]:format(MRT.F.delUnitNameServer(queueItem.sender)))
	else
		QueueFrame.texture:SetTexture(AddonDB:GetImage(queueItem.textureNum))
		QueueFrame.memeSender:SetText(WASync.QueueSenderStrings[queueItem.stringNum]:format(MRT.F.delUnitNameServer(queueItem.sender)))
	end
end

function QueueFrame:Update()
	if #QueueFrame.queue == 0 then
		QueueFrame:Hide()
		QueueFrame.SessionStarted = false

		if QueueFrame.needReload then
			QueueFrame.needReload = nil
			module:ShowReloadPrompt(QueueFrame.LastSender)
		end
	elseif InCombatLockdown() then
		QueueFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
		QueueFrame:SetScript("OnEvent", function()
			QueueFrame:UnregisterEvent("PLAYER_REGEN_ENABLED")
			QueueFrame:Update()
		end)
	elseif QueueFrame.SessionStarted and not QueueFrame.ImportedItem then
		local queueItem = QueueFrame.queue[1]

		QueueFrame:Show()

		QueueFrame.currentWATitle:SetText(queueItem.id)
		QueueFrame.ImportTypeText:SetText("Mode: " .. WASync.ImportTypes[queueItem.importType])
		QueueFrame.importsLeft:SetText("Total imports left: " .. (#QueueFrame.queue or ""))

		QueueFrame.processNextButton:SetText(LR.Import)

		if queueItem.skipPrompt or WASync.FORCE_IMPORTS then
			QueueFrame.processNextButton:Click()
		end
	end
end

---@type WASyncImportQueueItem[]
QueueFrame.queue = {}
QueueFrame.size = 0

---@param queueItem WASyncImportQueueItem
function QueueFrame:AddToQueue(queueItem)
	if not queueItem.str or not queueItem.sender or not queueItem.id or not queueItem.importType then
		return
	end

	if queueItem.skipPrompt then
		for i = 1, #QueueFrame.queue+1 do
			if not QueueFrame.queue[i] or not QueueFrame.queue[i].skipPrompt then
					tinsert(QueueFrame.queue, i, queueItem)
				break
			end
		end
	else
		QueueFrame.queue[#QueueFrame.queue+1] = queueItem
	end

	prettyPrint(format("%s |cff0080ffsent WA|r %q", queueItem.sender:gsub("%-[^%-]*$",""), queueItem.id))

	if not QueueFrame.SessionStarted and #QueueFrame.queue > 0 then
		QueueFrame.SetupSession()
	else
		QueueFrame:Update()
	end
end

function QueueFrame.postImportCallback(success, id)
	---@type WASyncImportQueueItem
	local queueItem = QueueFrame.ImportedItem

	importText:Hide()

	if success and id then
		WeakAuras.GetData(id).preferToUpdate = true -- so users dont get automatically prompted with "import as copy"
		if queueItem.needReload then
			QueueFrame.needReload = true
		end
	end

	if id then
		module:SendWAVer(id)
	end

	if queueItem.postImportCallback then
		xpcall(queueItem.postImportCallback, geterrorhandler(), success, id)
	end

	QueueFrame.ImportedItem = nil
	QueueFrame:Update()
	return queueItem
end

---@return WASyncImportQueueItem
function QueueFrame:SkipImport()
	local queueItem = tremove(QueueFrame.queue, 1)

	QueueFrame:Update()
	return queueItem
end

function QueueFrame:ProcessNext()
	if #QueueFrame.queue == 0 then
		QueueFrame.SessionStarted = false -- probably will never get there?
		return
	end

	local queueItem = tremove(QueueFrame.queue, 1)

	if not module.PUBLIC then importText:Show() end
	QueueFrame.ImportedItem = queueItem

	QueueFrame.LastSender = queueItem.sender

	module:ImportWA(queueItem)
end

-- create a string that will be shown in error frame to diagnose the problem
-- do not include dataStr directly, it can be too long, include length of dataStr instead
function module:GetDiagonsticsForQueueItem(queueItem)
	local dataStr = queueItem.str
	local sender = queueItem.sender
	local importType = queueItem.importType
	local stringNum = queueItem.stringNum
	local imageNum = queueItem.imageNum
	local skipPrompt = queueItem.skipPrompt

	local str = format([[
Diagnostics for queueItem:
dataStr (type: %s): %s
sender (type: %s): %s
importType (type: %s): %s
stringNum (type: %s): %s
imageNum (type: %s): %s
skipPrompt (type: %s): %s


]],
		type(dataStr), type(dataStr) == "string" and #dataStr or "table",
		type(sender), tostring(sender),
		type(importType), tostring(importType),
		type(stringNum), tostring(stringNum),
		type(imageNum), tostring(imageNum),
		type(skipPrompt), tostring(skipPrompt)
	)

	return str
end
