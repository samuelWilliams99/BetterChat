bc.teamOverload = {}

bc.teamOverload.defaultChannel = {
    icon = "group.png",
    send = function( self, msg )
        if DarkRP and not LocalPlayer():IsAlive() then return end
        net.Start( "BC_TM" )
        net.WriteString( msg )
        net.SendToServer()
    end,
    onMessage = function()
        bc.private.lastMessaged = nil
    end,
    doPrints = true,
    addNewLines = true,
    disabledSettings = { "openKey" },
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.team )
        table.insert( tab, idx + 1, "(" .. chatHelper.teamName( LocalPlayer() ) .. ") " )
    end,
    openOnStart = true,
    disallowClose = true,
    hideRealName = true,
    textEntryColor = bc.defines.theme.teamTextEntry,
    replicateAll = true,
    position = 3,
}

hook.Add( "BC_initPanels", "BC_initAddTeamOverloadChannel", function()
    if bc.settings.getServerValue( "replaceTeam" ) then
        local teamName = chatHelper.teamName( LocalPlayer() )
        local chanName = "TeamOverload-" .. teamName
        local channel = table.Copy( bc.teamOverload.defaultChannel )
        channel.name = chanName
        channel.displayName = teamName

        bc.channels.add( channel )

        net.Receive( "BC_TM", function()

            local ply = net.ReadEntity()
            local text = net.ReadString()

            local t = chatHelper.teamName( LocalPlayer() )
            local chanName = "TeamOverload-" .. t
            local chan = bc.channels.getChannel( chanName )

            if chan and bc.channels.isOpen( chan ) then
                local tab = bc.formatting.formatMessage( ply, text, not ply:Alive() )
                bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
            end
        end )
    end
end )
