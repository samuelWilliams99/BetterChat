bc.teamOverload = {}

bc.teamOverload.defaultChannel = {
    icon = "group.png",
    send = function( self, msg )
        if DarkRP and not LocalPlayer():Alive() then return end
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
        table.insert( tab, idx + 1, "(" .. self.displayName .. ") " )
    end,
    openOnStart = function( channel )
        if not bc.settings.getServerValue( "replaceTeam" ) then return end

        return "TeamOverload - " .. chatHelper.teamName( LocalPlayer() ) == channel.name
    end,
    hideRealName = true,
    hideChatText = true,
    textEntryColor = bc.defines.theme.teamTextEntry,
    replicateAll = true,
    position = 3,
}

function bc.teamOverload.onMessage()
    local ply = net.ReadEntity()
    local text = net.ReadString()

    local t = chatHelper.teamName( LocalPlayer() )
    local chanName = "TeamOverload - " .. t

    local tab = bc.formatting.formatMessage( ply, text, not ply:Alive() )
    bc.channels.message( { chanName, "MsgC" }, unpack( tab ) )
end

function bc.teamOverload.onPermissionChange()
    local plyTeam = LocalPlayer():Team()
    if bc.teamOverload.currentTeam == plyTeam then return end

    local old = bc.teamOverload.currentTeam
    bc.teamOverload.currentTeam = plyTeam

    local oldChanName = "TeamOverload - " .. team.GetName( old )
    local wasOpen = bc.channels.isOpen( oldChanName )
    bc.channels.close( oldChanName )

    local newChannel = bc.teamOverload.addChannel()

    if wasOpen then
        bc.channels.open( newChannel.name )
    end
end

function bc.teamOverload.makeButtons( menu )
    local teamName = chatHelper.teamName( LocalPlayer() )
    local chanName = "TeamOverload - " .. teamName

    if bc.channels.isOpen( chanName ) then return end
    menu:AddOption( teamName, function()
        local chan = bc.channels.get( chanName )
        if not chan then return end

        bc.channels.open( chanName )
        bc.channels.focus( chanName )
    end )
end

function bc.teamOverload.disable()
    if not bc.base.enabled then return end

    net.Receivers.BC_TM = nil
    hook.Remove( "BC_makeChannelButtons", "BC_makeTeamOverloadButtons" )
    hook.Remove( "BC_userAccessChange", "BC_teamOverloadChange" )

    local chanName = "TeamOverload - " .. chatHelper.teamName( LocalPlayer() )
    bc.channels.close( chanName )

    if bc.mainChannels.teamEnabled() then
        bc.channels.open( "Team" )
    end
end

function bc.teamOverload.addChannel()
    local ply = LocalPlayer()

    local teamName = chatHelper.teamName( ply )
    local chanName = "TeamOverload - " .. teamName
    local channel = table.Copy( bc.teamOverload.defaultChannel )
    channel.name = chanName
    channel.displayName = teamName

    bc.channels.add( channel )

    return channel
end

function bc.teamOverload.enable()
    if not bc.base.enabled then return end

    local channel = bc.teamOverload.addChannel()
    bc.channels.open( channel.name )
    bc.teamOverload.currentTeam = LocalPlayer():Team()

    net.Receive( "BC_TM", bc.teamOverload.onMessage )
    hook.Add( "BC_makeChannelButtons", "BC_makeTeamOverloadButtons", bc.teamOverload.makeButtons )
    hook.Add( "BC_userAccessChange", "BC_teamOverloadChange", bc.teamOverload.onPermissionChange )

    bc.channels.close( "Team" )
end

hook.Add( "BC_initPanels", "BC_initAddTeamOverloadChannel", function()
    if bc.settings.getServerValue( "replaceTeam" ) then
        bc.teamOverload.enable()
    else
        bc.teamOverload.disable()
    end
end )
