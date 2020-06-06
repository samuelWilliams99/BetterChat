bc.logs = {}
bc.logs.defaultChannel = {
    name = "Logs",
    icon = "book_open.png",
    noSend = true,
    doPrints = false,
    addNewLines = true,
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.logs )
        table.insert( tab, idx + 1, "[" .. self.displayName .. "] " )
    end,
    openOnStart = function()
        return bc.logs.allowed()
    end,
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
    if bc.channels.isOpen( "Logs" ) then return end
    local channel = bc.channels.get( "Logs" )

    menu:AddOption( channel.displayName, function()
        local chan = bc.channels.get( "Logs" )
        if not chan then return end
        if not bc.logs.allowed() then return end

        bc.channels.open( "Logs" )
        bc.channels.focus( "Logs" )
    end )
end )

function bc.logs.allowed()
    return bc.settings.isAllowed( "bc_chatlogs" )
end

net.Receive( "BC_LM", function()
    local channelType = net.ReadUInt( 4 )
    local channelName = net.ReadString()
    local data = net.ReadTable()

    local message

    if channelType == bc.defines.channelTypes.TEAM then
        local ply = data[1]
        if ply:Team() == LocalPlayer():Team() then return end
        message = { bc.defines.theme.logsPrefix, "Team:" .. team.GetName( ply:Team() ), bc.defines.colors.white, " | ", unpack( data ) }
    elseif channelType == bc.defines.channelTypes.PRIVATE then
        local from = data[1]
        local to = data[3]
        if from == LocalPlayer() or to == LocalPlayer() then return end
        table.insert( data, 2, bc.defines.colors.printBlue )
        table.insert( data, 4, bc.defines.colors.white )
        message = { bc.defines.theme.logsPrefix, "PM", bc.defines.colors.white, " | ", unpack( data ) }
    elseif channelType == bc.defines.channelTypes.GROUP then
        if bc.base.enabled then
            local s, e, id = string.find( channelName, "^Group (%d+) " )
            id = tonumber( id )
            for k, v in pairs( bc.group.groups ) do
                if v.id == id then
                    local group = v
                    if bc.channels.isOpen( "Group - " + group.id ) then
                        return
                    end
                end
            end
        end
        message = { bc.defines.theme.logsPrefix, channelName, bc.defines.colors.white, " | ", unpack( data ) }
    end

    if not message then return end

    if bc.base.enabled then
        if not bc.channels.get( "Logs" ) then return end
        if not bc.channels.isOpen( "Logs" ) then return end

        bc.channels.message( "Logs", unpack( message ) )
    else
        chat.AddText( bc.defines.theme.logs, "[LOGS] ", unpack( message ) )
    end
end )

function bc.logs.addChannel()
    return bc.channels.add( table.Copy( bc.logs.defaultChannel ) )
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
    if bc.logs.allowed() then
        if not bc.logs.buttonEnabled then
            bc.channels.open( "Logs" )
            bc.logs.addButton()
        end
    else
        bc.channels.close( "Logs" )
        bc.logs.removeButton()
    end
end )
