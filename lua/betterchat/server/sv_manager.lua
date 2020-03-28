bc.manager = bc.manager or {}
bc.manager.overload = bc.manager.overload or {}
local o = bc.manager.overload

include( "sv_logsmessages.lua" )
include( "sv_playerstates.lua" )
include( "sv_privatemessages.lua" )
include( "sv_adminmessages.lua" )
include( "sv_groups.lua" )
include( "sv_giphy.lua" )

net.Receive( "BC_sayOverload", function( len, ply )
    local isTeam = net.ReadBool()
    local isDead = net.ReadBool()
    local msg = net.ReadString()
    local recips = isTeam and team.GetPlayers( ply:Team() ) or player.GetAll()

    local maxLen = bc.settings.getServerValue( "maxLength" )
    if #msg > maxLen then
        msg = string.sub( msg, 1, maxLen )
    end

    local ret = hook.Run( "PlayerSay", ply, msg, isTeam )
    if ret ~= nil then msg = ret end

    if not msg or msg == "" then return end

    net.Start( "BC_sayOverload" )
    net.WriteEntity( ply )
    net.WriteBool( isTeam )
    net.WriteBool( isDead )
    net.WriteString( msg )
    net.Send( recips )
end )

-- Overloads
function MsgAll( ... )
    ULib.clientRPC( nil, "Msg", ... )
    Msg( ... )
end

o.PrintMessage = o.PrintMessage or PrintMessage
function PrintMessage( type, message )
    if type == HUD_PRINTTALK then
        ULib.clientRPC( nil, "bc.formatting.print", bc.defines.colors.printBlue, message )
    end
    o.PrintMessage( type, message )
end

local plyMeta = FindMetaTable( "Player" )
o.PlyPrintMessage = o.PlyPrintMessage or plyMeta.PrintMessage
function plyMeta:PrintMessage( type, message )
    if type == HUD_PRINTTALK then
        ULib.clientRPC( self, "bc.formatting.print", bc.defines.colors.printBlue, message )
    end
    o.PlyPrintMessage( self, type, message )
end

o.ChatPrint = o.ChatPrint or plyMeta.ChatPrint
function plyMeta:ChatPrint( msg )
    ULib.clientRPC( self, "bc.formatting.print", bc.defines.colors.printBlue, msg )
    o.ChatPrint( self, msg )
end
-- end

function bc.manager.formatName( recip, ply )
    local plyColor = recip == ply and bc.defines.colors.ulxYou or team.GetColor( ply:Team() )
    local plyName = recip == ply and "You" or ply:GetName()
    return plyColor, plyName
end

function bc.manager.sendNormalClient( ply, ... )
    local data = {}
    for k, v in ipairs( { ... } ) do
        if type( v ) == "Player" then
            local plyColor, plyName = bc.manager.formatName( ply, v )
            table.insert( data, plyColor )
            table.insert( data, plyName )
            table.insert( data, bc.defines.colors.printBlue )
        elseif type( v ) == "Entity" and v:EntIndex() == 0 then
            table.insert( data, bc.defines.colors.black )
            table.insert( data, "(Console)" )
            table.insert( data, bc.defines.colors.printBlue )
        else
            table.insert( data, v )
        end
    end
    ULib.clientRPC( ply, "chat.AddText", unpack( data ) )
end

function bc.manager.themeColor( name )
    return {
        formatter = true,
        type = "themeColor",
        name = name
    }
end

function bc.manager.getClients( chanName, sender )
    if chanName == "All" or chanName == "Players" then
        return player.GetAll()
    elseif chanName == "Team" then
        return team.GetPlayers( sender:Team() )
    elseif chanName == "Admin" then
        local out = {}
        for k, p in pairs( player.GetAll() ) do
            if bc.settings.isAllowed( v, "ulx seeasay" ) then
                table.insert( out, p )
            end
        end
        return out
    elseif string.sub( chanName, 1, 9 ) == "Player - " then
        local ply = player.GetBySteamID( string.sub( chanName, 10 ) )
        if ply then return { sender, ply } end
        return { sender }
    elseif string.sub( chanName, 1, 8 ) == "Group - " then
        local groupId = tonumber( string.sub( chanName, 9 ) )
        for k, group in pairs( bc.group.groups ) do
            if group.id == groupId then
                return bc.group.getGroupMembers( group )
            end
        end
    end
    return {}
end

hook.Add( "BC_playerReady", "BC_sendCommandsInit", function( ply )
    local tab = bc.util.getRunnableULXCommands( ply )
    net.Start( "BC_sendULXCommands" )
    net.WriteString( util.TableToJSON( tab ) )
    net.Send( ply )
end )

hook.Add( "BC_playerReady", "BC_sidePanelsInit", function( ply )
    for k, v in pairs( player.GetAll() ) do
        ULib.clientRPC( ply, "bc.sidePanel.players.generateEntry", v )
    end
end )

net.Receive( "BC_TM", function( len, ply )
    local t = ply:Team()
    local plys = {}
    for k, v in pairs( player.GetAll() ) do
        if t == v:Team() then
            table.insert( plys, v )
        end
    end
    local msg = net.ReadString()

    bc.logs.sendLog( bc.defines.channelTypes.TEAM, "Team - " .. team.GetName( t ), ply, ": ", msg )

    net.Start( "BC_TM" )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Send( plys )
end )
