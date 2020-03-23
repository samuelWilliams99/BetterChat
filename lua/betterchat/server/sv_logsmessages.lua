chatBox.logs = {}

function chatBox.logs.sendLog( channelType, channelName, ... )
    chatBox.logs.sendLogConsole( channelName, ... )
    chatBox.logs.sendLogPlayers( channelType, channelName, ... )
end

function chatBox.logs.sendLogConsole( channel, ... )
    local data = {}
    for k, v in ipairs( { ... } ) do
        if type( v ) == "string" then
            table.insert( data, v )
        elseif type( v ) == "Player" then
            table.insert( data, v:GetName() .. "~[" .. v:SteamID() .. "]" )
        elseif type( v ) == "table" and v.text then
            table.insert( data, v.text )
        elseif type( v ) == "Entity" and v:EntIndex() == 0 then
            table.insert( data, "(Server)" )
        end
    end
    local consoleStr = "<" .. channel .. "> " .. table.concat( data, "" )
    print( consoleStr )
    local logFile = GetConVar( "ulx_logfile" )
    if logFile:GetBool() then
        ulx.logString( consoleStr )
    end
end

function chatBox.logs.sendLogPlayers( channelType, channel, ... )
    do return end
    local plys = table.filterSeq( player.GetAll(), function( ply )
        return chatBox.settings.isAllowed( ply, "bc_chatlogs" )
    end )

    net.Start( "BC_LM" )
    net.WriteUInt( channelType, 4 )
    net.WriteString( channel )
    net.WriteTable( { ... } )
    net.Send( plys )
end

hook.Add( "PlayerSay", "BC_logTeam", function( ply, text, t )
    if t then
        chatBox.logs.sendLog( chatBox.defines.channelTypes.TEAM, "Team - " .. team.GetName( ply:Team() ), ply, ": ", text )
    end
end, HOOK_MONITOR_HIGH )
