chatBox.admin = {}

net.Receive( "BC_AM", function( len, ply )
    local text = net.ReadString()
    chatBox.admin.sendAdmin( ply, text )
end )

function chatBox.admin.sendAdmin( ply, text )
    chatBox.logs.sendLogConsole( "Admin", ply, ": ", text )

    local plys = {}
    for k, p in pairs( player.GetAll() ) do
        if chatBox.settings.isAllowed( p, "seeasay" ) then
            if chatBox.base.chatBoxEnabled[p] then
                net.Start( "BC_AM" )
                net.WriteEntity( ply )
                net.WriteString( text )
                net.Send( p )
            else
                table.insert( plys, p )
            end
        end
    end

    if not chatBox.settings.isAllowed( ply, "seeasay" ) then
        table.insert( plys, ply )
    end

    for k, v in pairs( plys ) do
        chatBox.manager.sendNormalClient( v, ply, " to admins: ", chatBox.defines.colors.green, text )
    end
end
