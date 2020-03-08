net.Receive( "BC_AM", function( len, ply )
    local text = net.ReadString()
    chatBox.sendAdmin( ply, text )
end )

function chatBox.sendAdmin( ply, text )
    chatBox.sendLogConsole( chatBox.channelTypes.ADMIN, "Admin", ply, ": ", text )

    local plys = {}
    for k, p in pairs( player.GetAll() ) do
        if chatBox.getAllowed( p, "seeasay" ) then
            if chatBox.chatBoxEnabled[p] then
                net.Start( "BC_AM" )
                net.WriteEntity( ply )
                net.WriteString( text )
                net.Send( p )
            else
                table.insert( plys, p )
            end
        end
    end

    if not chatBox.getAllowed( ply, "seeasay" ) then
        table.insert( plys, ply )
    end

    for k, v in pairs( plys ) do
        chatBox.sendNormalClient( v, ply, " to admins: ", Color( 0, 255, 0 ), text )
    end
end
