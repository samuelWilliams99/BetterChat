function chatBox.teamName(ply)
	return team.GetName(ply:Team())
end

chatBox.defaultTeamChannel = {
	icon = "group.png",
	send = function(self, msg)
		if DarkRP and not LocalPlayer():IsAlive() then return end
		net.Start("BC_TM")
		net.WriteString(msg)
		net.SendToServer()
	end,
	onMessage = function()
		chatBox.lastPrivate = nil
	end,
	doPrints = true,
	addNewLines = true,
	disabledSettings = {"openKey"},
	allFunc = function(self, tab, idx)
		table.insert(tab, idx, Color(0,170,0) )
		table.insert(tab, idx+1, "(" .. chatBox.teamName(LocalPlayer()) .. ") " )
	end,
	openOnStart = true,
	disallowClose = true,
	hideRealName = true
}

hook.Add("BC_PreInitPanels", "BC_InitAddTeamOverloadChannel", function()
	if chatBox.getServerSetting("replaceTeam") then
		local teamName = chatBox.teamName(LocalPlayer())
		local chanName = "TeamOverload-" .. teamName
		local channel = chatBox.getChannel(chanName)

		if not channel then
			channel = table.Copy(chatBox.defaultTeamChannel)
			channel.name = chanName
			table.insert(chatBox.channels, channel)
		end
		if channel.needsData then
			for k, v in pairs(chatBox.defaultTeamChannel) do
				if channel[k] == nil then 
					channel[k] = v 
				end
			end
			channel.needsData = nil
		end
		channel.displayName = teamName

		if not channel.dataChanged then channel.dataChanged = {} end

		net.Receive("BC_TM", function()

			local ply = net.ReadEntity()
			local text = net.ReadString()

			local t = chatBox.teamName(LocalPlayer())
			local chanName = "TeamOverload-"..t
			local chan = chatBox.getChannel(chanName)


			
			if chan and chatBox.isChannelOpen(chan) then
				local tab = chatBox.formatMessage(ply, text, not ply:Alive())
				chatBox.messageChannel( {chan.name, "MsgC"}, unpack(tab) )
			end
		end)
	end
end)