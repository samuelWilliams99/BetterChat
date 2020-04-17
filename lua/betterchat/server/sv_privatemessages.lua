bc.private = {}

function bc.private.sendPrivate( chan, from, to, text, noLog )
    if not to or not to:IsValid() then return end
    if not noLog then
        bc.logs.sendLog( bc.defines.channelTypes.PRIVATE, "Private", from, " → ", to, ": ", text )
    end
    if bc.base.playersEnabled[to] then
        net.Start( "BC_PM" )
        net.WriteEntity( chan )
        net.WriteEntity( from )
        net.WriteString( text )
        net.Send( to )
    else
        local recip = chan == from and to or chan
        bc.manager.sendNormalClient( to, from, " to ", recip, bc.defines.colors.white, ": ", text )
    end
end

function bc.private.allowed( ply )
    return bc.settings.isAllowed( ply, "psay" )
end

function bc.private.canMessage( from, to )
    if not bc.manager.canMessage( from ) then return false end

    return bc.private.allowed( from ) and bc.private.allowed( to )
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
    if not bc.private.canMessage( ply, target ) then return "" end
    if target == ply then
        if bc.base.playersEnabled[ply] then
            bc.private.sendPrivate( ply, ply, ply, msg )
        end
        return ""
    end

    if target then
        bc.private.sendPrivate( ply, ply, target, msg, true )
        bc.private.sendPrivate( target, ply, ply, msg )
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
