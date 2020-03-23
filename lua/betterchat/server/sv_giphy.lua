chatBox.giphy = chatBox.giphy or {}
chatBox.giphy.counts = chatBox.giphy.counts or {}
chatBox.giphy.lastResetHour = chatBox.giphy.lastResetHour or -1

-- Single think hook call so http is ready
hook.Once( "Think", function()
    chatBox.giphy.getGiphyURL( "thing", function( success, data )
        if success then
            print( "[BetterChat] Giphy key test successful, giphy command enabled." )
            chatBox.giphy.enabled = true
        else
            print( "[BetterChat] No valid Giphy API key found in bc_server_giphykey, giphy command disabled. Generate an app key from https://developers.giphy.com/ to use this feature." )
        end
    end )
end )

local function escape( s )
    s = string.gsub( s, "([&=+%c])", function ( c )
        return string.format( "%%%02X", string.byte( c ) )
    end )
    s = string.gsub( s, " ", "+" )
    return s
end

local function encode( t )
    local s = ""
    for k, v in pairs( t ) do
        s = s .. "&" .. escape( k ) .. "=" .. escape( v )
    end
    return string.sub( s, 2 )
end

function chatBox.giphy.getGiphyURL( query, cb )
    local key = chatBox.settings.getServerValue( "giphyKey" )
    if not key or #key == 0 then
        return cb( false )
    end

    http.Fetch( "https://api.giphy.com/v1/gifs/search?" .. encode( {
        api_key = key,
        q = query,
        limit = 1
    } ), function( body, _, _, code )
        local data = util.JSONToTable( body )
        if data and data.data and #data.data > 0 then
            cb( true, data.data[1].images.fixed_height.url )
        else
            cb( false )
        end
    end, function( ... )
        cb( false, ... )
    end )
end

net.Receive( "BC_sendGif", function( len, ply )
    if not chatBox.giphy.enabled then return end

    if not chatBox.settings.isAllowed( ply, "bc_giphy" ) then
        return ULib.clientRPC( ply, "chatBox.channels.message", channel, chatBox.defines.colors.red, "You don't have permission to use !giphy" )
    end

    local curDateTime = os.date( "*t", os.time() )
    local hour = curDateTime.hour
    if hour ~= chatBox.giphy.lastResetHour then
        chatBox.giphy.lastResetHour = hour
        chatBox.giphy.counts = {}
    end

    local curCount = chatBox.giphy.counts[ply:SteamID()] or 0
    local maxCount = chatBox.settings.getServerValue( "giphyHourlyLimit" )
    chatBox.giphy.counts[ply:SteamID()] = curCount + 1
    if curCount >= maxCount then
        return ULib.clientRPC( ply, "chatBox.channels.message", channel, chatBox.defines.colors.red,
            "You have surpassed your hourly giphy limit of " .. maxCount ..
            ". Your quota will reset in approximately " .. ( 60 - curDateTime.min ) .. " minute(s)." )
    end

    local str = net.ReadString()
    local channel = net.ReadString()
    if string.match( str, "^[%w_%. %-]+$" ) then
        chatBox.giphy.getGiphyURL( str, function( success, data )
            if success then
                ULib.clientRPC( ply, "chatBox.channels.message", channel, chatBox.defines.colors.printYellow, "You have " .. ( maxCount - curCount - 1 ) .. " giphy uses left for this hour." )
                local recips = chatBox.manager.getClients( channel, ply )
                net.Start( "BC_sendGif" )
                net.WriteString( channel )
                net.WriteString( data )
                net.WriteString( str )
                net.Send( recips )
            else
                ULib.clientRPC( ply, "chatBox.channels.message", channel, chatBox.defines.colors.red, "Giphy query failed, server wide hourly limit may have been reached" )
            end
        end )
    else
        ULib.clientRPC( ply, "chatBox.channels.message", channel, chatBox.defines.colors.red, "Invalid giphy query string, only alphanumeric characters, underscores or dots." )
    end
end )
