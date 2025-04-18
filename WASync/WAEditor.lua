local GlobalAddonName = ...
---@class AddonDB
local AddonDB = select(2, ...)
local MRT = GMRT

---@class WAChecker: MRTmodule
local module = MRT.A.WAChecker
if not module then return end
if not WeakAuras then return end

---@class ELib
local ELib, L = MRT.lib, MRT.L

---@class Locale
local LR = AddonDB.LR

---@class MLib
local MLib = AddonDB.MLib

---@class WASyncPrivate
local WASync = AddonDB.WASYNC

local prettyPrint = module.prettyPrint
local WASYNC_ERROR = module.WASYNC_ERROR


local orderedPairs
do
	local function __genOrderedIndex(t)
		local orderedIndex = {}
		for key in pairs(t) do
			if key ~= "__orderedIndex" then
				table.insert(orderedIndex, key)
			end
		end
		table.sort(orderedIndex, function(a, b)
			local typeA, typeB = type(a), type(b)
			if typeA ~= typeB then
				return typeA < typeB
			else
				return a < b
			end
		end)
		return orderedIndex
	end

	local function orderedNext(t, state)
		-- Equivalent of the next function, but returns the keys in the alphabetic
		-- order. We use a temporary ordered key table that is stored in the
		-- table being iterated.
		local key = nil
		if state == nil then
			-- the first time, generate the index
			t.__orderedIndex = __genOrderedIndex(t)
			key = t.__orderedIndex[1]
		else
			-- fetch the next value
			for i = 1, table.getn(t.__orderedIndex) do
				if t.__orderedIndex[i] == state then
					key = t.__orderedIndex[i + 1]
				end
			end
		end

		if key then
			return key, t[key]
		end

		-- no more value to return, cleanup
		t.__orderedIndex = nil
	end

	function orderedPairs(t)
		return orderedNext, t, nil
	end
end

local function recurseStringify(data, level, lines, sorted)
	local pairsFn = sorted and orderedPairs or pairs
	for k, v in pairsFn(data) do
		local lineFormat = strrep("    ", level) .. "[%s] = %s"
		local form1, form2, value
		local kType, vType = type(k), type(v)
		if kType == "string" then
			form1 = "%q"
		elseif kType == "number" then
			form1 = "%d"
		else
			form1 = "%s"
		end
		if vType == "string" then
			form2 = "%q"
			v = v:gsub("\\", "\\\\"):gsub("\n", "\\n"):gsub("\"", "\\\"")
		elseif vType == "boolean" then
			v = tostring(v)
			form2 = "%s"
		else
			form2 = "%s"
		end
		lineFormat = lineFormat:format(form1, form2)
		if vType == "table" then
			tinsert(lines, lineFormat:format(k, "{"))
			recurseStringify(v, level + 1, lines, sorted)
			tinsert(lines, strrep("    ", level) .. "},")
		else
			tinsert(lines, lineFormat:format(k, v) .. ",")
		end
	end
end

local function DisplayToTableString(data)
	if (data) then
		local lines = { "{" };
		recurseStringify(data, 1, lines, true);
		tinsert(lines, "}")
		return table.concat(lines, "\n");
	end
end

local function FixStrings(data)
	for k, v in pairs(data) do
		if type(v) == 'string' then
			data[k] = v:gsub("\\\"", "\""):gsub("\\n", "\n"):gsub("\\\\", "\\")
		elseif type(v) == 'table' then
			FixStrings(v)
		end
	end
end

local function TableStringToTable(dataStr)
	local f, err = loadstring("return " .. dataStr)
	if not f then
		return false, err
	end
	local isSuccessful, data = pcall(f)
	if isSuccessful then
		if type(data) ~= "table" then
			return false, "Text is not a table"
		end
		FixStrings(data)
	end
	return isSuccessful, data
end


local function CreateWAEditor()
	local WAEditorFrame = ELib:Popup("WASync WA Editor"):Size(800, 600)
	module.WAEditorFrame = WAEditorFrame


	WAEditorFrame.Editor = ELib:MultiEdit(WAEditorFrame):Size(780, 500):Point("TOP", 0, -30):AddPosText():OnChange(function(self)
		local isSuccessful, data = TableStringToTable(self:GetText())
		if isSuccessful then
			WAEditorFrame.data = data
			WAEditorFrame.errorText:SetText("")
		else
			WAEditorFrame.errorText:SetText(data)
		end
	end)
	WAEditorFrame.Editor.background = WAEditorFrame.Editor:CreateTexture(nil,"BACKGROUND",nil,-8)
	WAEditorFrame.Editor.background:SetAllPoints(WAEditorFrame.Editor)
	WAEditorFrame.Editor.background:SetColorTexture(.05, .05, .05, 0.85)
	ELib:Border(WAEditorFrame.Editor,1,.24,.25,.30,1)
	if IndentationLib then
		local editor_themes = {
			["Standard"] = {
				["Table"] = "|c00ff3333",
				["Arithmetic"] = "|c00ff3333",
				["Relational"] = "|c00ff3333",
				["Logical"] = "|c004444ff",
				["Special"] = "|c00ff3333",
				["Keyword"] = "|c004444ff",
				["Comment"] = "|c0000aa00",
				["Number"] = "|c00ff9900",
				["String"] = "|c00999999"
			},
			["Monokai"] = {
				["Table"] = "|c00ffffff",
				["Arithmetic"] = "|c00f92672",
				["Relational"] = "|c00ff3333",
				["Logical"] = "|c00f92672",
				["Special"] = "|c0066d9ef",
				["Keyword"] = "|c00f92672",
				["Comment"] = "|c0075715e",
				["Number"] = "|c00ae81ff",
				["String"] = "|c00e6db74"
			},
			["Obsidian"] = {
				["Table"] = "|c00AFC0E5",
				["Arithmetic"] = "|c00E0E2E4",
				["Relational"] = "|c00B3B689",
				["Logical"] = "|c0093C763",
				["Special"] = "|c00AFC0E5",
				["Keyword"] = "|c0093C763",
				["Comment"] = "|c0066747B",
				["Number"] = "|c00FFCD22",
				["String"] = "|c00EC7600"
			}
		}

		local color_scheme = {[0] = "|r"}
		local function set_scheme()
			local theme = editor_themes["Obsidian"]
			color_scheme[IndentationLib.tokens.TOKEN_SPECIAL] = theme["Special"]
			color_scheme[IndentationLib.tokens.TOKEN_KEYWORD] = theme["Keyword"]
			color_scheme[IndentationLib.tokens.TOKEN_COMMENT_SHORT] = theme["Comment"]
			color_scheme[IndentationLib.tokens.TOKEN_COMMENT_LONG] = theme["Comment"]
			color_scheme[IndentationLib.tokens.TOKEN_NUMBER] = theme["Number"]
			color_scheme[IndentationLib.tokens.TOKEN_STRING] = theme["String"]

			color_scheme["..."] = theme["Table"]
			color_scheme["{"] = theme["Table"]
			color_scheme["}"] = theme["Table"]
			color_scheme["["] = theme["Table"]
			color_scheme["]"] = theme["Table"]

			color_scheme["+"] = theme["Arithmetic"]
			color_scheme["-"] = theme["Arithmetic"]
			color_scheme["/"] = theme["Arithmetic"]
			color_scheme["*"] = theme["Arithmetic"]
			color_scheme[".."] = theme["Arithmetic"]

			color_scheme["=="] = theme["Relational"]
			color_scheme["<"] = theme["Relational"]
			color_scheme["<="] = theme["Relational"]
			color_scheme[">"] = theme["Relational"]
			color_scheme[">="] = theme["Relational"]
			color_scheme["~="] = theme["Relational"]

			color_scheme["and"] = theme["Logical"]
			color_scheme["or"] = theme["Logical"]
			color_scheme["not"] = theme["Logical"]
		end

		local textObj = WAEditorFrame.Editor.EditBox:GetRegions()

		local fontPath
		local SharedMedia = LibStub("LibSharedMedia-3.0")
		if SharedMedia then
			fontPath = SharedMedia:Fetch("font", "Fira Mono Medium")
			if (fontPath) then
				textObj:SetFont(fontPath, 12, "")
			end
		end

		WAEditorFrame.Editor.EditBox._GetText = WAEditorFrame.Editor.EditBox.GetText
		set_scheme()
		IndentationLib.enable(WAEditorFrame.Editor.EditBox, color_scheme, 4)
	end

	WAEditorFrame.errorText = ELib:Text(WAEditorFrame):Size(780, 20):Point("TOPLEFT", WAEditorFrame.Editor, "BOTTOMLEFT", 0, -10):Color(1,0,0)

	local function ShowDiffs()
		local diffs = {}
		local perc, c, t = MRT.F.table_compare(WAEditorFrame.dataSnapshot, WAEditorFrame.data, diffs)

		if perc == 1 then
			WAEditorFrame.errorText:SetText("No changes")
		else
			WAEditorFrame.errorText:SetText(format("Changes: %.2f%%", (1 - perc) * 100))
			prettyPrint(DisplayToTableString(diffs))
		end
	end

	WAEditorFrame.ShowDiffsButton = MLib:Button(WAEditorFrame, "Show diffs"):Size(100, 20):Point("BOTTOMLEFT", 10, 10):OnClick(function()
		ShowDiffs()
	end)

	WAEditorFrame.SendButton = MLib:Button(WAEditorFrame, LR["Send"]):Size(100, 20):Point("LEFT", WAEditorFrame.ShowDiffsButton, "RIGHT", 10, 0):OnClick(function()
		module:SendDisplayTable(WAEditorFrame.data, WAEditorFrame.source)
		WAEditorFrame:Hide()
	end)

	WAEditorFrame.RevertToLastValid = MLib:Button(WAEditorFrame, "Revert to last valid"):Size(180, 20):Point("LEFT", WAEditorFrame.SendButton, "RIGHT", 10, 0):OnClick(function()
		WAEditorFrame.Editor:SetText(DisplayToTableString(WAEditorFrame.data))
	end)

	function WAEditorFrame:StartEditing(data, source)
		self.dataSnapshot = data
		self.source = source
		local stringData = DisplayToTableString(data)
		self.Editor:SetText(stringData)
		self:Show()
	end
end


function module:EditWA(data, sender)
	assert(type(data) == "table", "EditWA: data must be a table")
	assert(type(sender) == "string", "EditWA: sender must be a string")
	if not module.WAEditorFrame then
		CreateWAEditor()
	end
	module.WAEditorFrame:StartEditing(data, sender)
end

-- ask for a display table
function module:RequestDisplayTable(id, source)
	AddonDB:SendComm("WAS_EDIT_REQUEST", id, nil, "WHISPER", source)
end

AddonDB:RegisterComm("WAS_EDIT_REQUEST", function(prefix, sender, id)
	if not (AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender)) then
		return
	end

	local data = WeakAuras.GetData(id)
	if data then
		local str = AddonDB:CompressTable(data, true)
		AddonDB:SendComm("WAS_EDIT_RESPONSE", str, nil, "WHISPER", sender)
	else
		module:ErrorComms(sender, 5, id)
	end
end)

AddonDB:RegisterComm("WAS_EDIT_RESPONSE", function(prefix, sender, str, channel)
	if channel ~= "WHISPER" then
		return
	end

	local data = AddonDB:DecompressTable(str, true)
	if type(data) == "table" then
		module:EditWA(data, sender)
	else
		prettyPrint(WASYNC_ERROR, data)
	end
end)

-- send back edited display table that should be imported
function module:SendDisplayTable(data, source)
	local str = AddonDB:CompressTable(data, true)
	AddonDB:SendComm("WAS_EDIT_IMPORT", str, nil, "WHISPER", source)
end

AddonDB:RegisterComm("WAS_EDIT_IMPORT", function(prefix, sender, str, channel)
	if channel ~= "WHISPER" then
		return
	end
	if not (AddonDB.RGAPI and AddonDB.RGAPI:IsCustomSender(sender)) then
		return
	end

	local data = AddonDB:DecompressTable(str, true)
	if type(data) == "table" and data.id and data.uid then
		prettyPrint(format("Importing WA %q from %s", data.id, sender))
		module:QuickImportWA(data)
	else
		prettyPrint(WASYNC_ERROR, data)
	end
end)
