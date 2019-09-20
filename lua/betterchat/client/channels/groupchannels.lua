chatBox.group = {}
chatBox.group.groups = {}

chatBox.group.defaultChannel = {
	init = false,
	displayName = "[Loading]",
	icon = "group.png",
	addNewLines = true,
	send = function(self, txt)
		net.Start("BC_GM")
		net.WriteUInt(self.group.id,16)
		net.WriteString(txt)
		net.SendToServer()
	end,
	allFunc = function(self, tab, idx)
		table.insert(tab, idx, chatBox.colors.group )
		table.insert(tab, idx+1, "(" .. self.displayName .. ") " )
	end,
	tickMode = 0,
	popMode = 1,
	hideRealName = true,
	runCommandSeparately = true,
	postAdd = function(data, panel)
		local g = chatBox.graphics
		local membersBtn = vgui.Create("DButton", panel)
		membersBtn:SetPos(g.chatFrame:GetWide() - 59, 34)
		membersBtn:SetSize(24,24)
		membersBtn:SetText("")
		membersBtn:SetColor(Color(255,255,255,150))
		membersBtn.name = data.name
		membersBtn.DoClick = function(self)
			local s = chatBox.sidePanels["Group Members"]
			if s.isOpen then
				chatBox.closeSidePanel(s.name)
			else
				chatBox.openSidePanel(s.name, self.name)
			end
		end
		membersBtn.Paint = function(self, w, h)
			local animState = chatBox.sidePanels["Group Members"].animState
			self:SetColor(lerpCol(Color(255,255,255,150), Color(255,255,255,230), animState))
			surface.SetMaterial(chatBox.materials.getMaterial("icons/groupbw.png"))
			surface.SetDrawColor( self:GetColor() )
			surface.DrawTexturedRect( 0, 0, w, h)
		end
	end,
	hideChatText = true,
}

function chatBox.allowedGroups()
	if LocalPlayer():IsAdmin() then
		return chatBox.getServerSetting("allowGroupsAdmin")
	end
	return chatBox.getServerSetting("allowGroups")
end

function chatBox.removeGroupHooks()
	hook.Remove("BC_ShowChat", "BC_showGroupButton")
	hook.Remove("BC_HideChat", "BC_hideGroupButton")
	hook.Remove("BC_KeyCodeTyped", "BC_GroupMenuShortcut")
	hook.Remove("PlayerConnect", "BC_ReloadMembersConnect")
	hook.Remove("BC_PlayerDisconnect", "BC_ReloadMembersDisconnect")
end

hook.Add("BC_PostInitPanels", "BC_groupAddButton", function() -- add group change check
	if not chatBox.allowedGroups() then chatBox.removeGroupHooks() return end
	local g = chatBox.graphics
	local comboBox = vgui.Create("DComboBox", g.chatFrame)
	comboBox:SetSortItems(false)
	comboBox:SetPos( g.size.x - 50 - 33, 5 )
	comboBox:SetSize(50,19)
	comboBox:SetTextColor(Color(220,220,220,255))

	comboBox.Think = function(self)
		if chatBox.group.changed then
			chatBox.group.changed = false

			self:Clear()
			if #chatBox.group.groups < 5 then
				self:AddChoice("Create Group", -1)
				if #chatBox.group.groups > 0 then
					self:AddChoice("---------------", -2)
				end
			end

			for k, v in pairs(chatBox.group.groups) do
				self:AddChoice(v.name, v.id)
			end

			self:SetValue("Groups")
		end
	end

	comboBox.OnSelect = function(self, idx, name, val)
		comboBox:SetValue("Groups")
		if val == -1 then
			net.Start("BC_newGroup")
			net.SendToServer()
			return
		end
		if val < 0 then return end
		local group
		for k, v in pairs(chatBox.group.groups) do
			if v.id == val then
				group = v
				break
			end
		end

		if not group then return end

		local chan = chatBox.getChannel("Group - " .. val)
		if not chan or chan.needsData then
			chan = chatBox.createGroupChannel(group)
		end

		if not chatBox.isChannelOpen(chan) then
			chatBox.addChannel(chan)
		end
		chatBox.reloadGroupMemberMenu(chan)
		chatBox.focusChannel(chan)
	end

	comboBox.Paint = function(self, w, h)
		draw.RoundedBox( 0, 0, 0, w, h, Color( 150,  150, 150, 50 ) )
	end

	comboBox.DropButton.Paint = nil

	chatBox.group.changed = true

	g.groupButton = comboBox

	hook.Add("BC_ShowChat", "BC_showGroupButton", function() chatBox.graphics.groupButton:Show() end)
	hook.Add("BC_HideChat", "BC_hideGroupButton", function() 
		chatBox.graphics.groupButton:Hide() 
		chatBox.graphics.groupButton:CloseMenu()
	end)

	hook.Add("BC_KeyCodeTyped", "BC_GroupMenuShortcut", function(code, ctrl, shift, entry)
		if ctrl and code == KEY_G then
			local b = chatBox.graphics.groupButton
			if b:IsMenuOpen() then
				b:CloseMenu()
			else
				b:OpenMenu()
			end
			return true
		end
	end)


	hook.Add("PlayerConnect", "BC_ReloadMembersConnect", function()
		for k, v in pairs(chatBox.channels) do
			if chatBox.isChannelOpen(v) and v.group then
				chatBox.reloadGroupMemberMenu(v)
			end
		end
	end)

	hook.Add("BC_PlayerDisconnect", "BC_ReloadMembersDisconnect", function()
		for k, v in pairs(chatBox.channels) do
			if chatBox.isChannelOpen(v) and v.group then
				chatBox.reloadGroupMemberMenu(v)
			end
		end
	end)


	net.Receive("BC_sendGroups", function(len)
		chatBox.group.groups = util.JSONToTable(net.ReadString())
		local ids = {}

		for k, v in ipairs(chatBox.group.groups) do
			table.insert(ids, v.id)
		end

		for k, v in pairs(chatBox.channels) do
			if v.group then
				if not table.HasValue(ids, v.group.id) then
					chatBox.deleteGroup(v.group)
				else
					local index = table.KeyFromValue(ids, v.group.id)
					local newGroup = chatBox.group.groups[index]
					v.group = newGroup
					if chatBox.getSidePanelChild("Group Members", v.name) then
						chatBox.reloadGroupMemberMenu(v)
					end

					if table.HasValue(newGroup.admins, LocalPlayer():SteamID()) then
						v.disabledSettings = {}
					else
						v.disabledSettings = {"displayName"}
					end
					chatBox.reloadChannelSettings(v)

				end
			end
		end

		chatBox.group.changed = true
	end)

	net.Receive("BC_updateGroup", function(len)
		if not chatBox.enabled then return end
		local group = util.JSONToTable(net.ReadString())
		local foundLocal = false
		for k, v in pairs(chatBox.group.groups) do
			if v.id == group.id then
				foundLocal = true
				if table.HasValue(group.members, LocalPlayer():SteamID()) then
					chatBox.group.groups[k] = group
					break
				else
					chatBox.deleteGroup(group)
					chatBox.group.changed = true
					return
				end
				
			end
		end
		if not foundLocal then
			table.insert(chatBox.group.groups, group)
		end

		local chan = chatBox.getChannel("Group - " .. group.id)
		if chan then
			chan.group = group
			chan.displayName = group.name
			chan.dataChanged = chan.dataChanged or {}
			chan.dataChanged.displayName = true
			if chatBox.getSidePanelChild("Group Members", chan.name) then
				chatBox.reloadGroupMemberMenu(chan)
			end

			if chatBox.isChannelOpen(chan) then
				if table.HasValue(group.admins, LocalPlayer():SteamID()) then
					chan.disabledSettings = {}
				else
					chan.disabledSettings = {"displayName"}
				end
				chatBox.reloadChannelSettings(chan)
			end
		end

		if group.openNow then
			if not chan or chan.needsData then
				chan = chatBox.createGroupChannel(group)
			end
			if not chatBox.isChannelOpen(chan) then
				chatBox.addChannel(chan)
			end
			chatBox.focusChannel(chan)
		end

		chatBox.group.changed = true
	end)

	net.Receive("BC_GM", function(len)
		if not chatBox.enabled then return end
		local groupId = net.ReadUInt(16)
		local ply = net.ReadEntity()
		local text = net.ReadString()

		local chan = chatBox.getChannel("Group - " .. groupId)
		if not chan or chan.needsData then
			for k, v in pairs(chatBox.group.groups) do
				if v.id == groupId then
					chan = chatBox.createGroupChannel(v)
					break
				end
			end
		end

		if not chan then return end

		if chan.openOnMessage == false then return end

		if not chatBox.isChannelOpen(chan) then
			chatBox.addChannel(chan)
		end

		local tab = chatBox.formatMessage(ply, text, not ply:Alive())
		table.insert(tab, 1, {isController = true, doSound = ply != LocalPlayer()})
		chatBox.messageChannel( {chan.name, "MsgC"}, unpack(tab) )
	end)
end)

function chatBox.deleteGroup(group)
	if not chatBox.allowedGroups() then return end
	for k, v in pairs(chatBox.group.groups) do --table.RemoveByValue wasn't working so delete by id instead
		if v.id == group.id then 
			table.remove(chatBox.group.groups, k) 
		end 
	end
	local chan = chatBox.getChannel("Group - " .. group.id)
	if chan then
		if chatBox.isChannelOpen(chan) then
			chatBox.removeChannel(chan)
		end
		table.RemoveByValue(chatBox.channels, chan)
	end
	chatBox.messageChannelDirect("All", chatBox.colors.printYellow, "You have been removed from group \"", chatBox.colors.group, group.name, chatBox.colors.printYellow, "\".")
	chatBox.saveData()		
end

function chatBox.createGroupChannel(group)
	if not chatBox.allowedGroups() then return nil end
	local name = "Group - " .. group.id
	local channel = chatBox.getChannel(name)
	if not channel then
		channel = table.Copy(chatBox.group.defaultChannel)
		channel.name = name
		table.insert(chatBox.channels, channel)
	end
	if channel.needsData then
		for k, v in pairs(chatBox.group.defaultChannel) do
			if channel[k] == nil then 
				channel[k] = v 
			end
		end

		channel.needsData = nil
	end
	if not table.HasValue(group.admins, LocalPlayer():SteamID()) then
		channel.disabledSettings = {"displayName"}
	end
	channel.displayName = group.name
	channel.group = group
	chatBox.reloadGroupMemberMenu(channel)
	if not channel.dataChanged then channel.dataChanged = {} end
	return channel
end