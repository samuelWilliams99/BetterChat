chatBox.admin = {}
chatBox.admin.defaultChannel = {
	name = "Admin", 
	icon = "shield.png",
	send = function(self, txt)
		net.Start("BC_AM")
		net.WriteString(txt)
		net.SendToServer()
	end,
	doPrints = false,
	addNewLines = true,
	allFunc = function(self, tab, idx)
		table.insert(tab, idx, Color(255,0,0) )
		table.insert(tab, idx+1, "(ADMIN) " )
	end,
	openOnStart = function()
		return LocalPlayer():IsAdmin() or (DarkRP and FAdmin.Access.PlayerHasPrivilege(LocalPlayer(), "AdminChat"))
	end,
	runCommandSeparately = true,
	hideChatText = true,
}

net.Receive("BC_AM",function()
	local ply = net.ReadEntity()
	local text = net.ReadString()
	local chan = chatBox.getChannel("Admin")

	if not chan then return end

	if not chan.openOnMessage then return end

	if not chatBox.isChannelOpen(chan) and (ply:IsAdmin() or (DarkRP and FAdmin.Access.PlayerHasPrivilege(ply, "AdminChat"))) then
		chatBox.addChannel(chan)
	end

	local tab = chatBox.formatMessage(ply, text, not ply:Alive(), ply:IsAdmin() and chatBox.colors.white or chatBox.colors.admin)
	chatBox.messageChannel( {chan.name, "MsgC"}, unpack(tab) )
end)

function chatBox.addAdminChannel()
	local channel = chatBox.getChannel("Admin")
	if not channel then
		channel = table.Copy(chatBox.admin.defaultChannel)
		table.insert(chatBox.channels, channel)
	end
	if channel.needsData then
		for k, v in pairs(chatBox.admin.defaultChannel) do
			if channel[k] == nil then 
				channel[k] = v 
			end
		end
		channel.needsData = nil
	end
	chatBox.applyDefaults(channel)
	if not channel.dataChanged then channel.dataChanged = {} end
	return channel
end

hook.Add("BC_PreInitPanels", "BC_InitAddAdminChannel", function()
	chatBox.addAdminChannel()
end)

-- Overloads
hook.Add("PostGamemodeLoaded", "BC_RPAdminOverload", function()
	if DarkRP then
		net.Receive("FAdmin_ReceiveAdminMessage", function(len)
		    local ply = net.ReadEntity()
		    local text = net.ReadString()
		    
		    if not chatBox.enabled then

			    local Team = ply:IsPlayer() and ply:Team() or 1
			    local Nick = ply:IsPlayer() and ply:Nick() or "Console"
			    local prefix = (FAdmin.Access.PlayerHasPrivilege(ply, "AdminChat") or ply:IsAdmin()) and "[Admin Chat] " or "[To admins] "

			    chat.AddNonParsedText(Color(255, 0, 0, 255), prefix, team.GetColor(Team), Nick .. ": ", Color(255, 255, 255, 255), text)
			else
				local chan = chatBox.getChannel("Admin")

				local tab = chatBox.formatMessage(ply, text, not ply:Alive(), ply:IsAdmin() and chatBox.colors.white or chatBox.colors.admin)
				chatBox.messageChannel( {chan.name, "MsgC"}, unpack(tab) )
			end
		end)
		DarkRP.addChatReceiver("/adminhelp", "talk in Admin", function(ply, text)
			return FAdmin.Access.PlayerHasPrivilege(LocalPlayer(), "SeeAdmins") and (ply:IsAdmin() or FAdmin.Access.PlayerHasPrivilege(ply, "AdminChat"))
		end)
	end
end)

