include( "sv_logsmessages.lua" )
include( "sv_playerstates.lua" )
include( "sv_privatemessages.lua" )
include( "sv_adminmessages.lua" )
include( "sv_groups.lua" )
include( "sv_giphy.lua" )


net.Receive( "BC_SayOverload", function( len, ply )
    local isTeam = net.ReadBool()
    local isDead = net.ReadBool()
    local msg = net.ReadString()
    local recips = isTeam and team.GetPlayers( ply:Team() ) or player.GetAll()

    local maxLen = chatBox.getServerSetting( "maxLength" )
    if #msg > maxLen then
        msg = string.sub( msg, 1, maxLen )
    end

    local ret = hook.Run( "PlayerSay", ply, msg, isTeam )
    if ret ~= nil then msg = ret end

    if not msg or msg == "" then return end

    net.Start( "BC_SayOverload" )
    net.WriteEntity( ply )
    net.WriteBool( isTeam )
    net.WriteBool( isDead )
    net.WriteString( msg )
    net.Send( recips )
end )

-- Overloads
MsgAll = function( ... )
    ULib.clientRPC( nil, "Msg", ... )
    Msg( ... )
end

local oldPrintMessage = PrintMessage
function PrintMessage( type, message )
    if type == HUD_PRINTTALK then
        ULib.clientRPC( nil, "chatBox.print", printBlue, message )
    end
    oldPrintMessage( type, message )
end

local plyMeta = FindMetaTable( "Player" )
local oldPlyPrintMessage = plyMeta.PrintMessage
plyMeta.PrintMessage = function( self, type, message )
    if type == HUD_PRINTTALK then
        ULib.clientRPC( self, "chatBox.print", printBlue, message )
    end
    oldPlyPrintMessage( self, type, message )
end

local oldChatPrint = plyMeta.ChatPrint
plyMeta.ChatPrint = function( self, msg )
    ULib.clientRPC( self, "chatBox.print", printBlue, msg )
    oldChatPrint( self, msg )
end
-- end

function chatBox.formatName( recip, ply )
    local plyColor = recip == ply and Color( 75, 0, 130 ) or team.GetColor( ply:Team() )
    local plyName = recip == ply and "You" or ply:GetName()
    return plyColor, plyName
end

function chatBox.sendNormalClient( ply, ... )
    local data = {}
    for k, v in ipairs( { ... } ) do
        if type( v ) == "Player" then
            local plyColor, plyName = chatBox.formatName( ply, v )
            table.insert( data, plyColor )
            table.insert( data, plyName )
            table.insert( data, chatBox.colors.printBlue )
        elseif type( v ) == "Entity" and v:EntIndex() == 0 then
            table.insert( data, Color( 0, 0, 0 ) )
            table.insert( data, "(Console)" )
            table.insert( data, chatBox.colors.printBlue )
        else
            table.insert( data, v )
        end
    end
    ULib.clientRPC( ply, "chat.AddText", unpack( data ) )
end

hook.Add( "BC_plyReady", "BC_SendCommandsInit", function( ply )
    local tab = chatBox.getRunnableULXCommands( ply )
    net.Start( "BC_sendULXCommands" )
    net.WriteString( util.TableToJSON( tab ) )
    net.Send( ply )
end )

hook.Add( "BC_plyReady", "BC_sidePanelsInit", function( ply )
    for k, v in pairs( player.GetAll() ) do
        ULib.clientRPC( ply, "chatBox.generatePlayerPanelEntry", v )
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

    print( "(" .. team.GetName( t ) .. ") " .. ply:GetName() .. ": " .. msg )

    net.Start( "BC_TM" )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Send( plys )
end )