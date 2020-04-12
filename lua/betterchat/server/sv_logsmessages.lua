bc.logs = {}

function bc.logs.sendLog( channelType, channelName, ... )
    bc.logs.sendLogConsole( channelName, ... )
    bc.logs.sendLogPlayers( channelType, channelName, ... )
end

function bc.logs.sendLogConsole( channel, ... )
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
