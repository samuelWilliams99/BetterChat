chatBox.defaultPrivateChannel = {
	init = false,
	displayName = "[Offline]",
	icon = "user.png",
	addNewLines = true,
	send = function(self, txt)
		if IsValid(self.ply) then
			if self.ply != LocalPlayer() then --so you can PM yourself and not get the message twice
				chatBox.printOwnPrivate(self.name, txt)
			end

			net.Start("BC_PM")
			net.WriteEntity(self.ply)
			net.WriteString(txt)
			net.SendToServer()
		else -- if offline, print to chat, do nothing
			chatBox.messageChannelDirect("All", Color(255,0,0), "This player is not online. They will not recieve this message. Right click the channel to close it.")
			chatBox.messageChannelDirect(self, Color(255,0,0), "This player is not online. They will not recieve this message. Right click the channel to close it.")
		end
	end,
	allFunc = function(self, tab, idx, isConsole)
		local sender = table.remove(tab, idx+1)
		local arrow = isConsole and " to " or " → "
		if sender == self.ply then --Receive
			table.insert(tab, idx, self.ply)
			table.insert(tab, idx+1, chatBox.colors.printBlue)
			table.insert(tab, idx+2, arrow)
			table.insert(tab, idx+3, {formatter=true, type="clickable", signal="Player-"..LocalPlayer():SteamID(), text="You", color=chatBox.colors.purple})
		else --send
			table.insert(tab, idx, {formatter=true, type="clickable", signal="Player-"..LocalPlayer():SteamID(), text="You", color=chatBox.colors.purple})
			table.insert(tab, idx+1, chatBox.colors.printBlue)
			table.insert(tab, idx+2, arrow)
			table.insert(tab, idx+3, self.ply)
		end
	end,
	tickMode = 2,
	popMode = 0,
	hideRealName = true,
	hideInitMessage = true,
	runCommandSeparately = true,
	hideChatText = true,
}

function chatBox.allowedPrivate(ply)
	ply = ply or LocalPlayer()
	if ply:IsAdmin() then
		return chatBox.getServerSetting("allowPMAdmin")
	end
	return chatBox.getServerSetting("allowPM")
end

function chatBox.canPrivateMessage(ply)
	return chatBox.allowedPrivate() and chatBox.allowedPrivate(ply)
end

function chatBox.printOwnPrivate(name, txt)
	if not chatBox.allowedPrivate() then return end
	local tab = table.Add({{isController = true, doSound = false}, LocalPlayer(), chatBox.colors.white, ": "}, chatBox.formatText(txt))
	chatBox.messageChannel( {name, "MsgC"}, unpack(tab))
end

hook.Add("BC_PreInitPanels", "BC_PrivateAddHooks", function()
	if not chatBox.allowedPrivate() then return end
	hook.Add("BC_PlayerConnect", "BC_PrivateChannelPlayerReload", function(ply)
		if not chatBox.enabled then return end
		for k, v in pairs(chatBox.channels) do
			if v.plySID then
				v.ply = player.GetBySteamID(v.plySID)
			end
		end
	end)

	net.Receive("BC_PM", function(len)
		local ply = net.ReadEntity()
		local sender = net.ReadEntity()
		local text = net.ReadString()

		local chan = chatBox.getChannel( "Player - " .. ply:SteamID())
		if not chan or chan.needsData then
			chan = chatBox.createPrivateChannel( ply )
		end

		local plySettings = chatBox.playerSettings[ply:SteamID()]

		if not plySettings or plySettings.ignore == 0 then
			if not chatBox.isChannelOpen(chan) then
				chatBox.addPrivateChannel(chan)
			end
			local tab = table.Add({{isController = true, doSound = (ply == sender) and (ply != LocalPlayer())}, sender, chatBox.colors.white, ": "}, chatBox.formatText(text))
			chatBox.messageChannel( {chan.name, "MsgC"}, unpack(tab) )
			chatBox.lastPrivate = chan
		end
	end)
end)


function chatBox.createPrivateChannel( ply )
	if not chatBox.allowedPrivate() then return nil end
	local name = "Player - " .. ply:SteamID()
	local channel = chatBox.getChannel(name)
	if not channel then
		channel = table.Copy(chatBox.defaultPrivateChannel)
		channel.name = name
		channel.plySID = ply:SteamID()
		table.insert(chatBox.channels, channel)
	end
	if channel.needsData then
		for k, v in pairs(chatBox.defaultPrivateChannel) do
			if channel[k] == nil then 
				channel[k] = v 
			end
		end
		channel.plySID = ply:SteamID()
		channel.needsData = nil
	end
	channel.ply = ply
	channel.displayName = ply:GetName()
	if not channel.dataChanged then channel.dataChanged = {} end
	return channel
end

function chatBox.addPrivateChannel(channel)
	if not channel then return end
	chatBox.addChannel(channel)
	chatBox.messageChannelDirect("All", {isController = true, doSound = false}, chatBox.colors.printBlue, "Private channel with ", channel.ply, " has been opened.")
	chatBox.messageChannelDirect(channel, {isController = true, doSound = false}, chatBox.colors.printBlue, "This is a private channel with ", channel.ply, ". Any messages posted here will not affect Expression2 or Starfall chips.")
end