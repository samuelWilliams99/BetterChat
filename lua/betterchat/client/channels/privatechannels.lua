bc.private = {}
local you

bc.private.lastMessaged = nil
bc.private.defaultChannel = {
    init = false,
    displayName = "[Offline]",
    icon = "user.png",
    addNewLines = true,
    send = function( self, txt )
        if IsValid( self.ply ) then
            if self.ply ~= LocalPlayer() then --so you can PM yourself and not get the message twice
                bc.private.printOwn( self.name, txt )
            end

            net.Start( "BC_PM" )
            net.WriteEntity( self.ply )
            net.WriteString( txt )
            net.SendToServer()
        else -- if offline, print to chat, do nothing
            bc.channels.messageDirect( "All", bc.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
            bc.channels.messageDirect( self, bc.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
        end
    end,
    allFunc = function( self, tab, idx, isConsole )
        local sender = table.remove( tab, idx + 1 )
        sender = sender.isConsole and bc.defines.consolePlayer or sender
        local arrow = isConsole and " to " or " → "
        if sender == self.ply then --Receive
            table.insert( tab, idx, self.ply )
            table.insert( tab, idx + 1, bc.defines.colors.printBlue )
            table.insert( tab, idx + 2, arrow )
            table.insert( tab, idx + 3, you )
        else --send
            table.insert( tab, idx, you )
            table.insert( tab, idx + 1, bc.defines.colors.printBlue )
            table.insert( tab, idx + 2, arrow )
            table.insert( tab, idx + 3, self.ply )
        end
    end,
    tickMode = 2,
    popMode = 0,
    hideRealName = true,
    hideInitMessage = true,
    runCommandSeparately = true,
    hideChatText = true,
    position = 4,
}

function bc.private.allowed( ply )
    ply = ply or LocalPlayer()
    return bc.settings.isAllowed( ply, "psay" )
end

function bc.private.canMessage( ply )
    return bc.private.allowed() and bc.private.allowed( ply )
end

local function getSteamID( ply )
    if not ply:IsValid() then
        return "CONSOLE"
    else
        return ply:SteamID()
    end
end

local function getName( ply )
    if not ply:IsValid() then
        return "Server"
    else
        return ply:GetName()
    end
end

function bc.private.printOwn( name, txt )
    if not bc.private.allowed() then return end
    local tab = table.Add( {
        {
            isController = true,
            doSound = false
        },
        LocalPlayer(),
        bc.defines.colors.white,
        ": "
    }, bc.formatting.formatText( txt, nil, LocalPlayer() ) )
    bc.channels.message( { name, "MsgC" }, unpack( tab ) )
end

hook.Add( "BC_userAccessChange", "BC_privateChannelCheck", function()
    if not bc.private.allowed() then
        for k, v in pairs( bc.channels.channels ) do
            if string.sub( v.name, 1, 9 ) == "Player - " then
                bc.channels.remove( v )
            end
        end
    end
end )

hook.Add( "BC_preInitPanels", "BC_privateAddHooks", function()
    you = {
        formatter = true,
        type = "clickable",
        signal = "Player-" .. LocalPlayer():SteamID(),
        text = "You",
        color = bc.defines.colors.ulxYou
    }
    if not bc.private.allowed() then return end
    hook.Add( "BC_playerConnect", "BC_privateChannelPlayerReload", function( ply )
        if not bc.base.enabled then return end
        for k, v in pairs( bc.channels.channels ) do
            if v.plySID and v.plySID ~= "CONSOLE" then
                v.ply = player.GetBySteamID( v.plySID )
            end
        end
    end )

    net.Receive( "BC_PM", function( len )
        local ply = net.ReadEntity()
        local sender = net.ReadEntity()
        local text = net.ReadString()

        if not ply:IsValid() then
            local tab = table.Add( {
                bc.defines.consolePlayer,
                bc.defines.theme.server,
                " to ",
                you,
                bc.defines.colors.white,
                ": "
            }, bc.formatting.formatText( text, nil, ply ) )
            bc.channels.message( { "All", "MsgC" }, unpack( tab ) )
            return
        end

        local chan = bc.channels.getChannel( "Player - " .. getSteamID( ply ) )
        if not chan or chan.needsData then
            chan = bc.private.createChannel( ply )
        end

        local plySettings = bc.sidePanel.players.settings[getSteamID( ply )]

        if not plySettings or plySettings.ignore == 0 then
            if not bc.channels.isOpen( chan ) then
                bc.private.addChannel( chan )
            end
            local tab = table.Add( {
                {
                    isController = true,
                    doSound = ( ply == sender ) and ( ply ~= LocalPlayer() )
                },
                sender:IsValid() and sender or bc.defines.consolePlayer,
                bc.defines.colors.white,
                ": "
            }, bc.formatting.formatText( text, nil, sender ) )
            bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
            bc.private.lastMessaged = chan
        end
    end )
end )


function bc.private.createChannel( ply )
    if not bc.private.allowed() then return nil end
    local name = "Player - " .. getSteamID( ply )
    local channel = bc.channels.getChannel( name )
    if not channel then
        channel = table.Copy( bc.private.defaultChannel )
        channel.name = name
        channel.plySID = getSteamID( ply )
        table.insert( bc.channels.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( bc.private.defaultChannel ) do
            if channel[k] == nil then
                channel[k] = v
            end
        end
        channel.plySID = getSteamID( ply )
        channel.needsData = nil
    end
    channel.ply = ply:IsValid() and ply or bc.defines.consolePlayer
    channel.displayName = getName( ply )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

function bc.private.addChannel( channel )
    if not channel then return end
    bc.channels.add( channel )
    bc.channels.messageDirect( "All", { isController = true, doSound = false }, bc.defines.colors.printBlue, "Private channel with ", channel.ply, " has been opened." )
    bc.channels.messageDirect( channel, { isController = true, doSound = false }, bc.defines.colors.printBlue, "This is a private channel with ", channel.ply, ". Any messages posted here will not affect Expression2 or Starfall chips." )
end
