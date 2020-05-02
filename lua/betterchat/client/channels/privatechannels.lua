bc.private = {}

bc.private.lastMessaged = nil
bc.private.defaultChannel = {
    init = false,
    displayName = "[Offline]",
    icon = "user.png",
    addNewLines = true,
    send = function( self, txt )
        if IsValid( self.ply ) then
            RunConsoleCommand( "ulx", "psay", "$" .. self.ply:SteamID(), txt )
        else -- if offline, print to chat, do nothing
            bc.channels.messageDirect( "All", bc.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
            bc.channels.messageDirect( self, bc.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
        end
    end,
    allFunc = function( self, tab, idx, isConsole )
        local sender = table.remove( tab, idx )
        sender = sender.isConsole and bc.defines.consolePlayer or sender.ply
        local arrow = isConsole and " to " or " → "

        local selfPly = {
            formatter = true,
            type = "sender",
            ply = self.ply
        }
        if sender == self.ply then --Receive
            table.insert( tab, idx, selfPly )
            table.insert( tab, idx + 1, bc.defines.colors.printBlue )
            table.insert( tab, idx + 2, arrow )
            table.insert( tab, idx + 3, bc.util.you() )
        else --send
            table.insert( tab, idx, bc.util.you() )
            table.insert( tab, idx + 1, bc.defines.colors.printBlue )
            table.insert( tab, idx + 2, arrow )
            table.insert( tab, idx + 3, selfPly )
        end
    end,
    tickMode = 2,
    popMode = 0,
    hideRealName = true,
    runCommandSeparately = true,
    hideChatText = true,
    position = 4,
}

function bc.private.allowed( ply )
    ply = ply or LocalPlayer()
    if ply:IsBot() then return false end
    return bc.settings.isAllowed( ply, "psay" )
end

function bc.private.canMessage( ply )
    if ply == LocalPlayer() then return false end
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
        return ply:Nick()
    end
end

hook.Add( "BC_userAccessChange", "BC_privateChannelCheck", function()
    if not bc.private.allowed() then
        for k, v in pairs( bc.channels.channels ) do
            if string.sub( v.name, 1, 9 ) == "Player - " then
                bc.channels.close( v )
            end
        end
    end
end )

hook.Add( "BC_playerConnect", "BC_privateChannelPlayerReload", function( ply )
    if not bc.base.enabled then return end
    for k, v in pairs( bc.channels.channels ) do
        if v.plySID and v.plySID ~= "CONSOLE" then
            v.ply = player.GetBySteamID( v.plySID )
        end
    end
end )

net.Receive( "BC_PM", function( len )
    if not bc.private.allowed() then return end

    local ply = net.ReadEntity()
    local sender = net.ReadEntity()
    local text = net.ReadString()

    if not ply:IsValid() then
        local tab = table.Add( {
            bc.defines.consolePlayer,
            bc.defines.theme.server,
            " to ",
            bc.util.you(),
            bc.defines.colors.white,
            ": "
        }, bc.formatting.formatText( text, nil, ply ) )
        bc.channels.message( { "All", "MsgC" }, unpack( tab ) )
        return
    end

    local chan = bc.channels.get( "Player - " .. getSteamID( ply ) )
    if not chan then
        chan = bc.private.createChannel( ply )
    end

    local plySettings = bc.sidePanel.players.settings[getSteamID( ply )]

    if not plySettings or plySettings.ignore == 0 then
        if not bc.channels.isOpen( chan.name ) then
            bc.channels.open( chan.name )
        end

        local tab = table.Add( {
            {
                controller = true,
                doSound = ( ply == sender ) and ( ply ~= LocalPlayer() )
            },
            sender:IsValid() and {
                formatter = true,
                type = "sender",
                ply = sender
            } or bc.defines.consolePlayer,
            bc.defines.colors.white,
            ": "
        }, bc.formatting.formatText( text, nil, sender ) )
        bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
        bc.private.lastMessaged = chan
    end
end )

function bc.private.createChannel( ply )
    if not bc.private.allowed() then return nil end

    local name = "Player - " .. getSteamID( ply )
    local channel = table.Copy( bc.private.defaultChannel )
    channel.name = name
    channel.ply = ply:IsValid() and ply or bc.defines.consolePlayer
    channel.plySID = getSteamID( ply )
    channel.displayName = getName( ply )

    bc.channels.add( channel )
    return channel
end
