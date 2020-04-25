bc.logs = {}

function bc.logs.sendLog( channelType, channelName, ... )
    bc.logs.sendLogConsole( channelType, channelName, ... )
    bc.logs.sendLogPlayers( channelType, channelName, ... )
end

function bc.logs.sendLogConsole( channelType, channel, ... )
    local data = {}
    for k, v in ipairs( { ... } ) do
        if type( v ) == "string" then
            table.insert( data, v )
        elseif type( v ) == "Player" then
            table.insert( data, v:Nick() .. "~[" .. v:SteamID() .. "]" )
        elseif type( v ) == "table" and v.text then
            table.insert( data, v.text )
        elseif type( v ) == "Entity" and v:EntIndex() == 0 then
            table.insert( data, "(Server)" )
        end
    end
    local consoleStr = "<" .. channel .. "> " .. table.concat( data, "" )
    local replacementStr = hook.Run( "BC_onServerLog", channelType, channel, ... )
    consoleStr = replacementStr or consoleStr

    if #consoleStr == 0 then return end
    print( consoleStr )
    local logFile = GetConVar( "ulx_logfile" )
    if logFile:GetBool() then
        ulx.logString( consoleStr )
    end
end

function bc.logs.sendLogPlayers( channelType, channel, ... )
    do return end
    local plys = table.filterSeq( player.GetAll(), function( ply )
        return bc.settings.isAllowed( ply, "bc_chatlogs" )
    end )

    net.Start( "BC_LM" )
    net.WriteUInt( channelType, 4 )
    net.WriteString( channel )
    net.WriteTable( { ... } )
    net.Send( plys )
end
