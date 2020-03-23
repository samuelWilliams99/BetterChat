bc.logs = {}
bc.logs.defaultChannel = {
    name = "Logs",
    icon = "book_open.png",
    noSend = true,
    doPrints = false,
    addNewLines = true,
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.logs )
        table.insert( tab, idx + 1, "[LOGS] " )
    end,
    openOnStart = function()
        return bc.logs.allowed()
    end,
    runCommandSeparately = true,
    showTimestamps = true,
    position = 7,
}
bc.logs.buttonEnabled = false

function bc.logs.addButton()
    bc.logs.buttonEnabled = true
end

function bc.logs.removeButton()
    bc.logs.buttonEnabled = false
end

hook.Add( "BC_makeChannelButtons", "BC_makeLogsButton", function( menu )
    if not bc.logs.buttonEnabled then return end
    menu:AddOption( "Logs", function()
        local chan = bc.channels.getChannel( "Logs" )
        if not chan then return end

        if not bc.channels.isOpen( chan ) and bc.logs.allowed() then
            bc.channels.add( chan )
        end
        bc.channels.focus( chan )
    end )
end )

function bc.logs.allowed()
    return bc.settings.isAllowed( "bc_chatlogs" )
end

net.Receive( "BC_LM", function()
    local channelType = net.ReadUInt( 4 )
    local channelName = net.ReadString()
    local data = net.ReadTable()

    local chan = bc.channels.getChannel( "Logs" )
    if not chan then return end
    if not bc.channels.isOpen( chan ) then return end

    if channelType == bc.defines.channelTypes.TEAM then
        local ply = data[1]
        if ply:Team() == LocalPlayer():Team() then return end
        bc.channels.message( "Logs", bc.defines.theme.logsPrefix, "<TEAM - " .. team.GetName( ply:Team() ) .. ">", bc.defines.colors.white, " | ", unpack( data ) )
    elseif channelType == bc.defines.channelTypes.PRIVATE then
        local from = data[1]
        local to = data[3]
        if from == LocalPlayer() or to == LocalPlayer() then return end
        table.insert( data, 2, bc.defines.colors.printBlue )
        table.insert( data, 4, bc.defines.colors.white )
        bc.channels.message( "Logs", bc.defines.theme.logsPrefix, "<PRIVATE>", bc.defines.colors.white, " | ", unpack( data ) )
    elseif channelType == bc.defines.channelTypes.GROUP then
        local s, e, id = string.find( channelName, "^Group (%d+) " )
        id = tonumber( id )
        for k, v in pairs( bc.group.groups ) do
            if v.id == id then
                local group = v
                local chan = bc.channels.getChannel( "Group - " + group.id )
                if bc.channels.isOpen( chan ) then
                    return
                end
            end
        end
        bc.channels.message( "Logs", bc.defines.theme.logsPrefix, "<" .. channelName .. ">", bc.defines.colors.white, " | ", unpack( data ) )
    end
end )

function bc.logs.addChannel()
    local channel = bc.channels.getChannel( "Logs" )
    if not channel then
        channel = table.Copy( bc.logs.defaultChannel )
        table.insert( bc.channels.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( bc.logs.defaultChannel ) do
            if channel[k] == nil then
                channel[k] = v
            end
        end
        channel.needsData = nil
    end
    bc.sidePanel.channels.applyDefaults( channel )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

hook.Add( "BC_initPanels", "BC_initAddLogsChannel", function()
    bc.logs.addChannel()
end )

hook.Add( "BC_postInitPanels", "BC_logsAddButton", function()
    if bc.logs.allowed() then
        bc.logs.addButton()
    end
end )

hook.Add( "BC_userAccessChange", "BC_logsChannelCheck", function()
    local logsChannel = bc.channels.getChannel( "Logs" )
    if bc.logs.allowed() then
        if not logsChannel then
            logsChannel = bc.logs.addChannel()
        end
        if not bc.channels.isOpen( logsChannel ) then
            bc.channels.add( logsChannel )
        end
        bc.logs.addButton()
    else
        if logsChannel and bc.channels.isOpen( logsChannel ) then
            bc.channels.remove( logsChannel ) -- closes
        end
        bc.logs.removeButton()
    end
end )
