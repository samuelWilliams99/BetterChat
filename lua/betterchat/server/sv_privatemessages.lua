net.Receive("BC_PM", function(len, ply)
	//Add ulx mute checking
	local targ = net.ReadEntity()
	local text = net.ReadString()

	sendPrivate(ply, ply, targ, text)
end)

function sendPrivate(chan, from, to, text)
	if chatBox.chatBoxEnabled[to] then
		print("" .. from:GetName() .. " → " .. to:GetName() .. ": " .. text)
		
		net.Start("BC_PM")
		net.WriteEntity(chan)
		net.WriteEntity(from)
		net.WriteString(text)
		net.Send(to)

	else
		ulx.fancyLog( {to}, "#P to #P: " .. text, from, to )
	end
end

function chatBox.allowedPrivate(ply)
	if ply:IsAdmin() then
		return chatBox.getServerSetting("allowPMAdmin")
	end
	return chatBox.getServerSetting("allowPM")
end

function chatBox.canPrivateMessage(from, to)
	return chatBox.allowedPrivate(from) and chatBox.allowedPrivate(to)
end

hook.Add("PostGamemodeLoaded", "BC_RPOverload", function()
	if DarkRP then
		local chatcommands = DarkRP.getChatCommands()
		if chatcommands then
			if chatcommands["pm"] then
				print("[BetterChat] Found DarkRP PM, replacing with BetterChat PM")
				local function PM(ply, args)
				    local namepos = string.find(args, " ")
				    if not namepos then
				        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
				        return ""
				    end

				    local name = string.sub(args, 1, namepos - 1)
				    local msg = string.sub(args, namepos + 1)

				    if msg == "" then
				        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
				        return ""
				    end

				    local target = DarkRP.findPlayer(name)
				    if not chatBox.canPrivateMessage(ply, target) then return "" end
				    if target == ply then 
				    	if chatBox.chatBoxEnabled[ply] then
				    		sendPrivate(ply, ply, ply, msg)
				    	end
				    	return "" 
				    end

				    if target then
				        sendPrivate(ply, ply, target, msg)
				        sendPrivate(target, ply, ply, msg)
				    else
				        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("could_not_find", tostring(name)))
				    end

				    return ""
				end
				DarkRP.defineChatCommand("pm", PM, 1.5)
			end
		end
	end

end)