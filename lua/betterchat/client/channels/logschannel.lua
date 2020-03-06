chatBox.logs = {}
chatBox.logs.defaultChannel = {
	name = "Logs", 
	icon = "book_open.png",
	noSend = true,
	doPrints = false,
	addNewLines = true,
	allFunc = function(self, tab, idx)
		table.insert(tab, idx, Color(138,43,226) )
		table.insert(tab, idx+1, "[LOGS] " )
	end,
	openOnStart = function()
		return chatBox.allowedLogs()
	end,
	runCommandSeparately = true,
	showTimestamps = true,
}
chatBox.logs.buttonEnabled = false

function chatBox.addLogsButton()
	chatBox.logs.buttonEnabled = true
end

function chatBox.removeLogsButton()
	chatBox.logs.buttonEnabled = false
end

hook.Add("BC_MakeChannelButtons", "BC_MakeLogsButton", function(menu)
	if not chatBox.logs.buttonEnabled then return end
	menu:AddOption( "Logs", function()
		local chan = chatBox.getChannel("Logs")
		if not chan then return end

		if not chatBox.isChannelOpen(chan) and chatBox.allowedLogs() then
			chatBox.addChannel(chan)
		end
		chatBox.focusChannel(chan)
	end )
end )

function chatBox.allowedLogs()
	return chatBox.getAllowed("bc_chatlogs")
end

--[[
chatBox.channelTypes = {
    GLOBAL = 1,
    TEAM = 2,
    PRIVATE = 3,
    ADMIN = 4,
    GROUP = 5
}
]]

net.Receive("BC_LM", function()
	local channelType = net.ReadUInt(4)
    local channelName = net.ReadString()
    local data = net.ReadTable()

    local chan = chatBox.getChannel("Logs")
	if not chan then return end
	if not chatBox.isChannelOpen(chan) then return end

	if channelType == chatBox.channelTypes.TEAM then
		local ply = data[1]
		if ply:Team() == LocalPlayer():Team() then return end
		chatBox.messageChannel( "Logs", Color(0,170,0), "<TEAM - " .. team.GetName( ply:Team() ) .. ">", Color(255,255,255), " | ", unpack( data ) )
	elseif channelType == chatBox.channelTypes.PRIVATE then
		local from = data[1]
		local to = data[3]
		if from == LocalPlayer() or to == LocalPlayer() then return end
		table.insert(data, 2, chatBox.colors.printBlue)
		table.insert(data, 4, chatBox.colors.white)
		chatBox.messageChannel( "Logs", Color(0,170,0), "<PRIVATE>", Color(255,255,255), " | ", unpack( data ) )
	elseif channelType == chatBox.channelTypes.GROUP then
		local s, e, id = string.find(channelName, "^Group (%d+) ")
		id = tonumber(id)
		print(id)
		for k, v in pairs(chatBox.group.groups) do
			if v.id == id then
				local group = v
				local chan = chatBox.getChannel("Group - " + group.id)
				if chatBox.isChannelOpen( chan ) then
					return
				end
			end
		end
		chatBox.messageChannel( "Logs", Color(0,170,0), "<" .. channelName .. ">", Color(255,255,255), " | ", unpack( data ) )
	end
end)

function chatBox.addLogsChannel()
	local channel = chatBox.getChannel("Logs")
	if not channel then
		channel = table.Copy(chatBox.logs.defaultChannel)
		table.insert(chatBox.channels, channel)
	end
	if channel.needsData then
		for k, v in pairs(chatBox.logs.defaultChannel) do
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

hook.Add("BC_PreInitPanels", "BC_InitAddLogsChannel", function()
	chatBox.addLogsChannel()
end)

hook.Add("BC_PostInitPanels", "BC_LogsAddButton", function()
	if chatBox.allowedLogs() then
		chatBox.addLogsButton()
	end
end)

hook.Add("BC_UserAccessChange", "BC_LogsChannelCheck", function()
	local logsChannel = chatBox.getChannel("Logs")
	if chatBox.allowedLogs() then
		if not logsChannel then
			logsChannel = chatBox.addLogsChannel()
		end
		if not chatBox.isChannelOpen(logsChannel) then
			chatBox.addChannel(logsChannel)
		end
		chatBox.addLogsButton()
	else
		if logsChannel and chatBox.isChannelOpen(logsChannel) then
			chatBox.removeChannel(logsChannel) -- closes
		end
		chatBox.removeLogsButton()
	end
end )
