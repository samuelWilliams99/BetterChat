chatBox.private = {}

function chatBox.private.sendPrivate( chan, from, to, text, noLog )
    if not to or not to:IsValid() then return end
    if not noLog then
        chatBox.logs.sendLog( chatBox.defines.channelTypes.PRIVATE, "Private", from, " → ", to, ": ", text )
    end
    if chatBox.base.chatBoxEnabled[to] then
        net.Start( "BC_PM" )
        net.WriteEntity( chan )
        net.WriteEntity( from )
        net.WriteString( text )
        net.Send( to )
    else
        local recip = chan == from and to or chan
        chatBox.manager.sendNormalClient( to, from, " to ", recip, chatBox.defines.colors.white, ": ", text )
    end
end

function chatBox.private.allowed( ply )
    return chatBox.settings.isAllowed( ply, "psay" )
end

function chatBox.private.canMessage( from, to )
    return chatBox.private.allowed( from ) and chatBox.private.allowed( to )
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
    if not chatBox.private.canMessage( ply, target ) then return "" end
    if target == ply then
        if chatBox.base.chatBoxEnabled[ply] then
            chatBox.private.sendPrivate( ply, ply, ply, msg )
        end
        return ""
    end

    if target then
        chatBox.private.sendPrivate( ply, ply, target, msg )
        chatBox.private.sendPrivate( target, ply, ply, msg )
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

net.Receive( "BC_PM", function( len, ply )
    --Add ulx mute checking
    local targ = net.ReadEntity()
    local text = net.ReadString()

    chatBox.private.sendPrivate( ply, ply, targ, text )
end )
