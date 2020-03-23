chatBox.private = {}
local you

chatBox.private.lastMessaged = nil
chatBox.private.defaultChannel = { 
    init = false, 
    displayName = "[Offline]", 
    icon = "user.png", 
    addNewLines = true, 
    send = function( self, txt )
        if IsValid( self.ply ) then
            if self.ply ~= LocalPlayer() then --so you can PM yourself and not get the message twice
                chatBox.private.printOwn( self.name, txt )
            end

            net.Start( "BC_PM" )
            net.WriteEntity( self.ply )
            net.WriteString( txt )
            net.SendToServer()
        else -- if offline, print to chat, do nothing
            chatBox.channels.messageDirect( "All", chatBox.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
            chatBox.channels.messageDirect( self, chatBox.defines.colors.red, "This player is not online. They will not recieve this message. Right click the channel to close it." )
        end
    end, 
    allFunc = function( self, tab, idx, isConsole )
        local sender = table.remove( tab, idx + 1 )
        sender = sender.isConsole and chatBox.defines.consolePlayer or sender
        local arrow = isConsole and " to " or " → "
        if sender == self.ply then --Receive
            table.insert( tab, idx, self.ply )
            table.insert( tab, idx + 1, chatBox.defines.colors.printBlue )
            table.insert( tab, idx + 2, arrow )
            table.insert( tab, idx + 3, you )
        else --send
            table.insert( tab, idx, you )
            table.insert( tab, idx + 1, chatBox.defines.colors.printBlue )
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

function chatBox.private.allowed( ply )
    ply = ply or LocalPlayer()
    return chatBox.settings.isAllowed( ply, "psay" )
end

function chatBox.private.canMessage( ply )
    return chatBox.private.allowed() and chatBox.private.allowed( ply )
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

function chatBox.private.printOwn( name, txt )
    if not chatBox.private.allowed() then return end
    local tab = table.Add( { 
        { 
            isController = true, 
            doSound = false
        }, 
        LocalPlayer(), 
        chatBox.defines.colors.white, 
        ": "
    }, chatBox.formatting.formatText( txt, nil, LocalPlayer() ) )
    chatBox.channels.message( { name, "MsgC" }, unpack( tab ) )
end

hook.Add( "BC_userAccessChange", "BC_privateChannelCheck", function()
    if not chatBox.private.allowed() then
        for k, v in pairs( chatBox.channels.channels ) do
            if string.sub( v.name, 1, 9 ) == "Player - " then
                chatBox.channels.remove( v )
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
        color = chatBox.defines.colors.ulxYou
    }
    if not chatBox.private.allowed() then return end
    hook.Add( "BC_playerConnect", "BC_privateChannelPlayerReload", function( ply )
        if not chatBox.base.enabled then return end
        for k, v in pairs( chatBox.channels.channels ) do
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
                chatBox.defines.consolePlayer, 
                chatBox.defines.theme.server, 
                " to ",
                you,
                chatBox.defines.colors.white,
                ": "
            }, chatBox.formatting.formatText( text, nil, ply ) )
            chatBox.channels.message( { "All", "MsgC" }, unpack( tab ) )
            return
        end

        local chan = chatBox.channels.getChannel( "Player - " .. getSteamID( ply ) )
        if not chan or chan.needsData then
            chan = chatBox.private.createChannel( ply )
        end

        local plySettings = chatBox.sidePanel.players.settings[getSteamID( ply )]

        if not plySettings or plySettings.ignore == 0 then
            if not chatBox.channels.isOpen( chan ) then
                chatBox.private.addChannel( chan )
            end
            local tab = table.Add( { 
                { 
                    isController = true, 
                    doSound = ( ply == sender ) and ( ply ~= LocalPlayer() )
                }, 
                sender:IsValid() and sender or chatBox.defines.consolePlayer, 
                chatBox.defines.colors.white, 
                ": "
            }, chatBox.formatting.formatText( text, nil, sender ) )
            chatBox.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
            chatBox.private.lastMessaged = chan
        end
    end )
end )


function chatBox.private.createChannel( ply )
    if not chatBox.private.allowed() then return nil end
    local name = "Player - " .. getSteamID( ply )
    local channel = chatBox.channels.getChannel( name )
    if not channel then
        channel = table.Copy( chatBox.private.defaultChannel )
        channel.name = name
        channel.plySID = getSteamID( ply )
        table.insert( chatBox.channels.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( chatBox.private.defaultChannel ) do
            if channel[k] == nil then 
                channel[k] = v 
            end
        end
        channel.plySID = getSteamID( ply )
        channel.needsData = nil
    end
    channel.ply = ply:IsValid() and ply or chatBox.defines.consolePlayer
    channel.displayName = getName( ply )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

function chatBox.private.addChannel( channel )
    if not channel then return end
    chatBox.channels.add( channel )
    chatBox.channels.messageDirect( "All", { isController = true, doSound = false }, chatBox.defines.colors.printBlue, "Private channel with ", channel.ply, " has been opened." )
    chatBox.channels.messageDirect( channel, { isController = true, doSound = false }, chatBox.defines.colors.printBlue, "This is a private channel with ", channel.ply, ". Any messages posted here will not affect Expression2 or Starfall chips." )
end