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
	textEntryColor = Color(200,100,100),
}

function chatBox.addAdminButton()
	local g = chatBox.graphics
	if g.adminButton then return end
	local btn = vgui.Create("DButton", g.chatFrame)
	btn:SetPos( g.size.x - 50 - 3 - 50 - 33, 5 )
	btn:SetSize(50,19)
	btn:SetTextColor(Color(220,220,220,255))
	btn:SetText("Admin")

	btn.Paint = function(self, w, h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 150,  150, 150, 50 ) )
	end

	btn.DoClick = function(self, w, h)
		local chan = chatBox.getChannel("Admin")

		if not chan then return end

		if not chatBox.isChannelOpen(chan) and chatBox.allowedAdmin() then
			chatBox.addChannel(chan)
		end

		chatBox.focusChannel(chan)
	end

	hook.Add("BC_ShowChat", "BC_showAdminButton", function() chatBox.graphics.adminButton:Show() end)
	hook.Add("BC_HideChat", "BC_hideAdminButton", function() chatBox.graphics.adminButton:Hide() end)

	g.psheet.tabScroller:DockMargin(3,0,88 + 53,0)

	g.adminButton = btn
end

function chatBox.removeAdminButton()
	local g = chatBox.graphics
	if not g.adminButton then return end
	g.adminButton:Remove()
	g.adminButton = nil

	g.psheet.tabScroller:DockMargin(3,0,88,0)

	hook.Remove("BC_ShowChat", "BC_showAdminButton")
	hook.Remove("BC_HideChat", "BC_hideAdminButton")
end

function chatBox.allowedAdmin()
	local ply = LocalPlayer()
	return ply:IsAdmin() or (DarkRP and FAdmin.Access.PlayerHasPrivilege(ply, "AdminChat"))
end

net.Receive("BC_AM", function()
	local ply = net.ReadEntity()
	local text = net.ReadString()
	local chan = chatBox.getChannel("Admin")

	if not chan then return end

	if not chan.openOnMessage then return end

	if not chatBox.isChannelOpen(chan) and chatBox.allowedAdmin() then
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

hook.Add("BC_PostInitPanels", "BC_adminAddButton", function() 
	if chatBox.allowedAdmin() then
		chatBox.addAdminButton()
	end
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

