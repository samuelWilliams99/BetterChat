include("betterchat/client/input/autocomplete.lua")

hook.Add("BC_InitPanels", "BC_InitInput", function()
	chatBox.history = {}
	chatBox.historyIndex = 0
	chatBox.historyInput = ""
end)

hook.Add("BC_KeyCodeTyped", "BC_InputHook", function(code, ctrl, shift, entry)
	if code == KEY_UP then
		if chatBox.historyIndex == 0 then
			chatBox.historyInput = entry:GetText()
		end
		chatBox.historyIndex = math.Min(chatBox.historyIndex + 1, #chatBox.history)
		if chatBox.historyIndex != 0 then
			entry:SetText(chatBox.history[(#chatBox.history + 1) - chatBox.historyIndex])
			entry:SetCaretPos(#entry:GetText())
		end
		return true
	elseif code == KEY_DOWN then
		if chatBox.historyIndex == 0 then
			return true
		end
		chatBox.historyIndex = math.Max(chatBox.historyIndex - 1, 0)
		if chatBox.historyIndex != 0 then
			entry:SetText(chatBox.history[(#chatBox.history + 1) - chatBox.historyIndex])
			entry:SetCaretPos(#entry:GetText())
		else
			entry:SetText(chatBox.historyInput)
			entry:SetCaretPos(#entry:GetText())
		end
		return true
	elseif code == KEY_C then
		if ctrl then
			local txt = hook.Run("RICHERTEXT:CopyText")
			if txt then
				SetClipboardText(txt)
				return true
			end
		end
	elseif code == KEY_V then
		if ctrl then
			entry:SetMultiline(true)
		end
	elseif code == KEY_BACKSPACE and ctrl then
		local cPos = entry:GetCaretPos()+1
		local txt = entry:GetText()
		if shift then
			entry:SetText(string.sub(txt, cPos, #txt))
		else
			local preTxt = string.TrimRight(string.sub(entry:GetText(), 1, cPos-1))

			local spacePos = 0

			for k = 1, math.min(cPos, #preTxt) do
				if txt[k] == " " then
					spacePos = k
				end
			end
			entry:SetText(string.sub(preTxt, 1, spacePos) .. string.sub(txt, cPos, #txt))
			entry:SetCaretPos(spacePos)
		end
		return true
	end
	
end)

hook.Add("BC_MessageCanSend", "BC_RunConsoleCommand", function(channel, txt)
	if chatBox.getSetting("allowConsole") then
		if txt and (txt[1] .. txt[2]) == "¬" then -- ¬ is actually 2 characters, 194, 172
			local cmd = txt:sub(3) -- accounting for ¬ being 2 chars
			if not cmd then return true end
			RunConsoleCommand(splitCommand(cmd))
			return true
		end
	end
end)

hook.Add("BC_MessageSent", "BC_RelayULX", function(channel, txt)
	if channel.runCommandSeparately and txt[1] == "!" then
		net.Start("BC_forwardMessage")
		net.WriteString(txt)
		net.SendToServer()
	end
end)

function splitCommand(str)
	local out = {}
	local token = ""
	local inQuotes = nil
	for k = 1, #str do
		local v = str[k]
		if inQuotes then
			if v == inQuotes then
				inQuotes = nil
			else
				token = token .. v
			end
		else
			if v == " " then
				table.insert(out, token)
				token = ""
			elseif v == "\"" or v == "'" and #token == 0 then
				inQuotes = v
			else
				token = token .. v
			end
		end
	end
	if #token != 0 then
		table.insert(out, token)
	end

	return unpack(out)
end