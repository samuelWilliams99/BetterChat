net.Receive( "BC_PM", function( len, ply )
    --Add ulx mute checking
    local targ = net.ReadEntity()
    local text = net.ReadString()

    chatBox.sendPrivate( ply, ply, targ, text )
end )

function chatBox.sendPrivate( chan, from, to, text, noLog )
    if not to or not to:IsValid() then return end
    if not noLog then
        chatBox.sendLog( chatBox.channelTypes.PRIVATE, "Private", from, " → ", to, ": ", text )
    end
    if chatBox.chatBoxEnabled[to] then
        net.Start( "BC_PM" )
        net.WriteEntity( chan )
        net.WriteEntity( from )
        net.WriteString( text )
        net.Send( to )
    else
        local recip = chan == from and to or chan
        chatBox.sendNormalClient( to, from, " to ", recip, Color( 255, 255, 255 ), ": ", text )
    end
end

function chatBox.allowedPrivate( ply )
    return chatBox.getAllowed( ply, "psay" )
end

function chatBox.canPrivateMessage( from, to )
    return chatBox.allowedPrivate( from ) and chatBox.allowedPrivate( to )
end

-- Dark rp

local function DarkRP_PM( ply, args )
    local namepos = string.find( args, " " )
    if not namepos then
        DarkRP.notify( ply, 1, 4, DarkRP.getPhrase( "invalid_x", DarkRP.getPhrase( "arguments" ), "" ) )
        return ""
    end

    local name = string.sub( args, 1, namepos - 1 )
    local msg = string.sub( args, namepos + 1 )

    if msg == "" then
        DarkRP.notify( ply, 1, 4, DarkRP.getPhrase( "invalid_x", DarkRP.getPhrase( "arguments" ), "" ) )
        return ""
    end

    local target = DarkRP.findPlayer( name )
    if not chatBox.canPrivateMessage( ply, target ) then return "" end
    if target == ply then 
        if chatBox.chatBoxEnabled[ply] then
            chatBox.sendPrivate( ply, ply, ply, msg )
        end
        return "" 
    end

    if target then
        chatBox.sendPrivate( ply, ply, target, msg )
        chatBox.sendPrivate( target, ply, ply, msg )
    else
        DarkRP.notify( ply, 1, 4, DarkRP.getPhrase( "could_not_find", tostring( name ) ) )
    end

    return ""
end

hook.Add( "PostGamemodeLoaded", "BC_RPOverload", function()
    if DarkRP then
        local chatcommands = DarkRP.getChatCommands()
        if chatcommands and chatcommands["pm"] then
            print( "[BetterChat] Found DarkRP PM, replacing with BetterChat PM" )
            DarkRP.defineChatCommand( "pm", DarkRP_PM, 1.5 )
        end
    end
end )
