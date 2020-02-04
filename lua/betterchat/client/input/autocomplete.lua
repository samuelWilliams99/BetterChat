net.Receive("BC_sendULXCommands", function()
	local cmds = util.JSONToTable(net.ReadString())
	chatBox.autoComplete.cmds = chatBox.autoComplete.cmds or {}
	local newCmds = {}
	for k, v in pairs(cmds) do
		newCmds[v] = chatBox.autoComplete.cmds[v] or 0
	end
	chatBox.autoComplete.cmds = newCmds
	chatBox.autoComplete.emoteUsage = chatBox.autoComplete.emoteUsage or {}
end)

hook.Add("BC_InitPanels", "BC_InitAutoComplete", function()
	chatBox.autoComplete = chatBox.autoComplete or {}
	chatBox.autoComplete.cur = {}
	chatBox.autoComplete.cur.option = 0
end)

hook.Add("BC_KeyCodeTyped", "BC_AutoCompleteHook", function(code, ctrl, shift, entry)
	local txt = entry:GetText()
	if entry:GetCaretPos() ~= #txt then return end
	local txtEx = string.Explode(" ", txt)
	if code == KEY_TAB then
		if not ctrl then
			if #chatBox.autoComplete.cur.options == 0 then
				local options
				if #txtEx == 1 and txtEx[1][1] == "!" then
					options = getSimilarCommands(txtEx[1])
				elseif txtEx[#txtEx][1] == ":" and #txtEx[#txtEx] >= 2 then
					options = getSimilarEmotes(txtEx[#txtEx])
				else
					options = getSimilarNames(txtEx[#txtEx])
				end
				setSuggestions(txt, options)
			end
			incOption()
		end
	elseif code == KEY_SPACE or code == KEY_ENTER then
		local strCompleted
		local c = chatBox.autoComplete.cur
		
		if chatBox.autoComplete.cur.option != 0 then
			strCompleted = c.options[c.option]
		else
			strCompleted = txtEx[#txtEx]
		end

		if txt[1] == "!" and #txtEx == 1 then //Is command
			if chatBox.autoComplete.cmds[strCompleted] != nil then
				chatBox.autoComplete.cmds[strCompleted] = chatBox.autoComplete.cmds[strCompleted] + 1
				chatBox.saveData()
			end
		end
	end
end)

hook.Add("BC_MessageSent", "BC_AutoCompleteUsageTracker", function(channel, txt)
	local tab = chatBox.formatMessage(LocalPlayer(), txt, false)
	local change = false
	for k, v in pairs(tab) do
		if type(v) == "table" and v.formatter and v.type == "image" then
			if chatBox.autoComplete.emoteUsage[v.text] ~= nil then
				chatBox.autoComplete.emoteUsage[v.text] = chatBox.autoComplete.emoteUsage[v.text] + 1
				change = true
			end
		end
	end

	setSuggestions()

	if change then
		chatBox.reloadUsedEmotesMenu()
		chatBox.saveData()
	end
end)

hook.Add("BC_ChannelChanged", "BC_HideAutocomplete", function()
	hook.Run("ChatTextChanged", chatBox.graphics.textEntry:GetText())
end)

hook.Add("BC_ChatTextChanged", "AutoCompletePreview", function(txt)
	if not chatBox.enabled then return end
	local txtEx = string.Explode(" ", txt)
	local options
	if #txtEx == 1 and txtEx[1][1] == "!" then
		options = getSimilarCommands(txtEx[1])
	elseif #txtEx[#txtEx] > 2 then
		if txtEx[#txtEx][1] == ":" then
			options = getSimilarEmotes(txtEx[#txtEx])
		else
			options = getSimilarNames(txtEx[#txtEx])
		end
	else
		setSuggestions()
		return
	end

	setSuggestions(txt, options)
end)

function setSuggestions(text, options)
	if text then
		chatBox.autoComplete.cur.options = options
		chatBox.autoComplete.cur.option = 0
		chatBox.autoComplete.cur.originalText = text
		local split = string.Explode(" ", text)
		chatBox.autoComplete.cur.word = table.remove(split, #split)
		chatBox.autoComplete.cur.prefix = table.concat(split, " ") .. (#split > 0 and " " or "")
	else
		chatBox.autoComplete.cur.options = {}
	end
	updateText()
end

function updateText()
	if not chatBox.getSetting("acDisplay") then return end
	if #chatBox.autoComplete.cur.options > 0 then
		local c = chatBox.autoComplete.cur
		OPTIONS_SHOWN = math.min(4, #c.options)
		local sIdx = c.option and math.max(c.option, 1) or 1
		local options = table.Copy(c.options)
		options[1] = c.word .. string.sub(options[1], #c.word + 1, -1)

		local t = c.prefix .. table.concat(options, "; ", sIdx, math.min(sIdx -1 + OPTIONS_SHOWN, #c.options)) .. "; "
		if c.option != 0 then
			t = t .. "... ; "
		end

		if c.option > (#c.options - OPTIONS_SHOWN + 1) then
			t = t .. table.concat(c.options, "; ", 1, OPTIONS_SHOWN - (#c.options - c.option) - 1)
		end
		chatBox.graphics.textEntry.bgText = t
	else
		chatBox.graphics.textEntry.bgText = ""
	end

end

function incOption()
	setOption( (chatBox.autoComplete.cur.option + 1) % (#chatBox.autoComplete.cur.options + 1) )
end

function setOption(n)
	chatBox.autoComplete.cur.option = n
	if n == 0 then
		setText(chatBox.autoComplete.cur.originalText)
	else
		setText(chatBox.autoComplete.cur.prefix .. chatBox.autoComplete.cur.options[n])
	end
	updateText()
end

function setText(txt)
	chatBox.graphics.textEntry:SetText(txt)
	chatBox.graphics.textEntry:SetCaretPos(#txt)
end

--takes a string and assiative array, array format
--arr[string/name] = usage --to sort by
function getSimilarStrings(str, arr)
	str = string.lower(str)
	local out = {}
	for k, val in pairs(arr) do
		local s, _ = string.find(string.lower(val), str, 1, true)
		if s == 1 then
			table.insert(out, val)
		end
	end
	
	return out
end

function getSimilarCommands(str)
	local out = getSimilarStrings(str, table.GetKeys(chatBox.autoComplete.cmds))
	table.sort(out, function(a,b)
		if chatBox.autoComplete.cmds[a] == chatBox.autoComplete.cmds[b] or not chatBox.getSetting("acUsage") then
			if #a == #b then
				return a < b
			end
			return #a < #b
		end
		return chatBox.autoComplete.cmds[a] > chatBox.autoComplete.cmds[b]
	end)
	return out
end

function getSimilarNames(str)
	local names = {}
	for k, ply in pairs(player.GetAll()) do
		table.insert(names, ply:GetName())
	end
	return getSimilarStrings(str, names)
end

function getSimilarEmotes(str)
	local longEmotes = {}
	for k, v in pairs(chatBox.spriteLookup.list) do
		if v[1] == ":" and v[#v] == ":" then
			table.insert(longEmotes, v)
		end
	end

	local out = getSimilarStrings(str, longEmotes)

	table.sort(out, function(a,b)
		if chatBox.autoComplete.emoteUsage[a] == chatBox.autoComplete.emoteUsage[b] or not chatBox.getSetting("acUsage") then
			if #a == #b then
				return a < b
			end
			return #a < #b
		end
		return chatBox.autoComplete.emoteUsage[a] > chatBox.autoComplete.emoteUsage[b]
	end)
	return out
end