chatBox.logs = {}
chatBox.logs.defaultChannel = { 
    name = "Logs", 
    icon = "book_open.png", 
    noSend = true, 
    doPrints = false, 
    addNewLines = true, 
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, chatBox.defines.theme.logs )
        table.insert( tab, idx + 1, "[LOGS] " )
    end, 
    openOnStart = function()
        return chatBox.logs.allowed()
    end, 
    runCommandSeparately = true, 
    showTimestamps = true,
    position = 7,
}
chatBox.logs.buttonEnabled = false

function chatBox.logs.addButton()
    chatBox.logs.buttonEnabled = true
end

function chatBox.logs.removeButton()
    chatBox.logs.buttonEnabled = false
end

hook.Add( "BC_makeChannelButtons", "BC_makeLogsButton", function( menu )
    if not chatBox.logs.buttonEnabled then return end
    menu:AddOption( "Logs", function()
        local chan = chatBox.channels.getChannel( "Logs" )
        if not chan then return end

        if not chatBox.channels.isOpen( chan ) and chatBox.logs.allowed() then
            chatBox.channels.add( chan )
        end
        chatBox.channels.focus( chan )
    end )
end )

function chatBox.logs.allowed()
    return chatBox.settings.isAllowed( "bc_chatlogs" )
end

net.Receive( "BC_LM", function()
    local channelType = net.ReadUInt( 4 )
    local channelName = net.ReadString()
    local data = net.ReadTable()

    local chan = chatBox.channels.getChannel( "Logs" )
    if not chan then return end
    if not chatBox.channels.isOpen( chan ) then return end

    if channelType == chatBox.defines.channelTypes.TEAM then
        local ply = data[1]
        if ply:Team() == LocalPlayer():Team() then return end
        chatBox.channels.message( "Logs", chatBox.defines.theme.logsPrefix, "<TEAM - " .. team.GetName( ply:Team() ) .. ">", chatBox.defines.colors.white, " | ", unpack( data ) )
    elseif channelType == chatBox.defines.channelTypes.PRIVATE then
        local from = data[1]
        local to = data[3]
        if from == LocalPlayer() or to == LocalPlayer() then return end
        table.insert( data, 2, chatBox.defines.colors.printBlue )
        table.insert( data, 4, chatBox.defines.colors.white )
        chatBox.channels.message( "Logs", chatBox.defines.theme.logsPrefix, "<PRIVATE>", chatBox.defines.colors.white, " | ", unpack( data ) )
    elseif channelType == chatBox.defines.channelTypes.GROUP then
        local s, e, id = string.find( channelName, "^Group (%d+) " )
        id = tonumber( id )
        for k, v in pairs( chatBox.group.groups ) do
            if v.id == id then
                local group = v
                local chan = chatBox.channels.getChannel( "Group - " + group.id )
                if chatBox.channels.isOpen( chan ) then
                    return
                end
            end
        end
        chatBox.channels.message( "Logs", chatBox.defines.theme.logsPrefix, "<" .. channelName .. ">", chatBox.defines.colors.white, " | ", unpack( data ) )
    end
end )

function chatBox.logs.addChannel()
    local channel = chatBox.channels.getChannel( "Logs" )
    if not channel then
        channel = table.Copy( chatBox.logs.defaultChannel )
        table.insert( chatBox.channels.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( chatBox.logs.defaultChannel ) do
            if channel[k] == nil then 
                channel[k] = v 
            end
        end
        channel.needsData = nil
    end
    chatBox.sidePanel.channels.applyDefaults( channel )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

hook.Add( "BC_initPanels", "BC_initAddLogsChannel", function()
    chatBox.logs.addChannel()
end )

hook.Add( "BC_postInitPanels", "BC_logsAddButton", function()
    if chatBox.logs.allowed() then
        chatBox.logs.addButton()
    end
end )

hook.Add( "BC_userAccessChange", "BC_logsChannelCheck", function()
    local logsChannel = chatBox.channels.getChannel( "Logs" )
    if chatBox.logs.allowed() then
        if not logsChannel then
            logsChannel = chatBox.logs.addChannel()
        end
        if not chatBox.channels.isOpen( logsChannel ) then
            chatBox.channels.add( logsChannel )
        end
        chatBox.logs.addButton()
    else
        if logsChannel and chatBox.channels.isOpen( logsChannel ) then
            chatBox.channels.remove( logsChannel ) -- closes
        end
        chatBox.logs.removeButton()
    end
end )
