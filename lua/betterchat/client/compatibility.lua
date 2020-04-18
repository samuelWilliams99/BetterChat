bc.compatibility = bc.compatibility or {}

local function captureAddText( f, ... )
    local oldAddText = chat.AddText
    local data = {}
    function chat.AddText( ... )
        table.Add( data, { ... } )
    end
    local out = f( ... )
    chat.AddText = oldAddText
    return data, out
end

hook.Add( "BC_overload", "BC_ATAG_chatOverload", function()
    timer.Simple( 0.5, function()
        if ATAG then
            print( "[BetterChat] Found ATAG, attempting overload" )

            local playerChatTable = hook.GetULibTable().OnPlayerChat
            if playerChatTable and playerChatTable[0].ATAG_ChatTags then
                print( "[BetterChat] Found ATAG_ChatTags hook, overloading" )
                bc.compatibility.atagHook = hook.GetULibTable().OnPlayerChat[0].ATAG_ChatTags.fn
                hook.Remove( "OnPlayerChat", "ATAG_ChatTags" )
            end
        end
    end )
end )

hook.Add( "BC_overload", "BC_DarkRP_chatOverload", function()
    timer.Simple( 0.5, function()
        if DarkRP then
            bc.compatibility.darkRPReceiver = net.Receivers.darkrp_chat
            if bc.compatibility.darkRPReceiver then
                net.Receive( "DarkRP_Chat", function( bits )
                    -- hush now
                    local chatPlaySound = chat.PlaySound
                    chat.PlaySound = function() end

                    bc.compatibility.defaultDarkRPReceiver( bits )

                    chat.PlaySound = chatPlaySound
                end )
            end
        end
    end )
end )

function bc.compatibility.darkRPDefaultChatReceiver( ply )
    if GAMEMODE.Config.alltalk then return nil end

    return LocalPlayer():GetPos():DistToSqr( ply:GetPos() ) <
        GAMEMODE.Config.talkDistance * GAMEMODE.Config.talkDistance
end

hook.Add( "BC_channelChanged", "BC_DarkRP_UpdateReceiver", function()
    if not DarkRP then return end

    local phrase = DarkRP.getPhrase( "talk" )
    local channel = bc.channels.getActiveChannel()

    if channel.name ~= "All" and channel.name ~= "Players" then
        phrase = "talk in " .. channel.displayName
    end

    bc.compatibility.overrideDarkRPChatReceivers( phrase )
end )

function bc.compatibility.overrideDarkRPChatReceivers( phrase )
    DarkRP.addChatReceiver( "", phrase, function( ply )
        local channel = bc.channels.getActiveChannel()
        if not channel then return false end

        local chanName = channel.name
        if chanName == "All" or chanName == "Players" then
            return bc.compatibility.darkRPDefaultChatReceiver( ply )
        elseif string.sub( chanName, 1, 15 ) == "TeamOverload - " then
            return ply:Team() == LocalPlayer():Team()
        elseif chanName == "Admin" then
            return bc.admin.allowed( ply )
        elseif channel.plySID then
            return ply:SteamID() == channel.plySID
        elseif channel.group then
            return table.HasValue( channel.group.members or {}, ply:SteamID() )
        end
        return false
    end )
end

hook.Add( "OnGamemodeLoaded", "BC_DarkRP_ATAG_compatibility", function()
    bc.compatibility.defaultDarkRPReceiver = net.Receivers.darkrp_chat
end )

local function fixColor( col )
    return Color( col.r, col.g, col.b, col.a )
end

hook.Add( "BC_getNameTable", "BC_ATAG_getNameTable", function( ply )
    if not ATAG then return end
    local pieces, messageColor, nameColor = ply:getChatTag()
    if not pieces then return end

    local out = {}
    for k, v in pairs( pieces ) do
        table.insert( out, fixColor( v.color ) or Color( 255, 255, 255 ) )
        table.insert( out, v.name or "" )
    end

    table.insert( out, {
        formatter = true,
        type = "clickable",
        signal = "Player-" .. ply:SteamID(),
        color = nameColor or team.GetColor( ply:Team() ),
        text = bc.channels.parseName( ply:Nick() )
    } )

    return out, messageColor
end )

function bc.compatibility.getNameTable( ply )
    return hook.Run( "BC_getNameTable", ply ) or { ply }
end

hook.Add( "BC_overloadUndo", "BC_compatibilityUndo", function()
    if bc.compatibility.atagHook then
        print( "[BetterChat] Undoing ATAG Overload" )
        hook.Add( "OnPlayerChat", "ATAG_ChatTags", bc.compatibility.atagHook )
    end
    if bc.compatibility.darkRPReceiver then
        print( "[BetterChat] Undoing DarkRP PlayerChat Overload" )
        net.Receivers.darkrp_chat = bc.compatibility.darkRPReceiver
        DarkRP.addChatReceiver( "", DarkRP.getPhrase( "talk" ), bc.compatibility.darkRPDefaultChatReceiver )
    end
end )

hook.Add( "BC_getDefaultTab", "BC_ATAG_default", function( ... )
    if not bc.compatibility.atagHook then return end

    local data, madeChange = captureAddText( bc.compatibility.atagHook, ... )
    return data, madeChange
end )
