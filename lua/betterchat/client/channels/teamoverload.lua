chatBox.teamOverload = {}

chatBox.teamOverload.defaultChannel = { 
    icon = "group.png", 
    send = function( self, msg )
        if DarkRP and not LocalPlayer():IsAlive() then return end
        net.Start( "BC_TM" )
        net.WriteString( msg )
        net.SendToServer()
    end, 
    onMessage = function()
        chatBox.private.lastMessaged = nil
    end, 
    doPrints = true, 
    addNewLines = true, 
    disabledSettings = { "openKey" }, 
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, chatBox.defines.theme.team )
        table.insert( tab, idx + 1, "(" .. chatHelper.teamName( LocalPlayer() ) .. ") " )
    end, 
    openOnStart = true, 
    disallowClose = true, 
    hideRealName = true, 
    textEntryColor = chatBox.defines.theme.teamTextEntry, 
    replicateAll = true, 
    position = 3,
}

hook.Add( "BC_initPanels", "BC_initAddTeamOverloadChannel", function()
    if chatBox.settings.getServerValue( "replaceTeam" ) then
        local teamName = chatHelper.teamName( LocalPlayer() )
        local chanName = "TeamOverload-" .. teamName
        local channel = chatBox.channels.getChannel( chanName )

        if not channel then
            channel = table.Copy( chatBox.teamOverload.defaultChannel )
            channel.name = chanName
            table.insert( chatBox.channels.channels, channel )
        end
        if channel.needsData then
            for k, v in pairs( chatBox.teamOverload.defaultChannel ) do
                if channel[k] == nil then 
                    channel[k] = v 
                end
            end
            channel.needsData = nil
        end
        channel.displayName = teamName

        if not channel.dataChanged then channel.dataChanged = {} end

        net.Receive( "BC_TM", function()

            local ply = net.ReadEntity()
            local text = net.ReadString()

            local t = chatHelper.teamName( LocalPlayer() )
            local chanName = "TeamOverload-" .. t
            local chan = chatBox.channels.getChannel( chanName )
            
            if chan and chatBox.channels.isOpen( chan ) then
                local tab = chatBox.formatting.formatMessage( ply, text, not ply:Alive() )
                chatBox.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
            end
        end )
    end
end )
