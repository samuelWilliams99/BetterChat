bc.admin = {}

function bc.admin.sendAdmin( ply, text )
    if not bc.manager.canMessage( ply ) then return end

    bc.logs.sendLogConsole( bc.defines.channelTypes.ADMIN, "Admin", ply, ": ", text )

    local plys = {}
    for k, p in pairs( player.GetAll() ) do
        if bc.settings.isAllowed( p, "seeasay" ) then
            if bc.base.playersEnabled[p] then
                net.Start( "BC_AM" )
                net.WriteEntity( ply )
                net.WriteString( text )
                net.Send( p )
            else
                table.insert( plys, p )
            end
        end
    end

    if not bc.settings.isAllowed( ply, "seeasay" ) then
        table.insert( plys, ply )
    end

    for k, v in pairs( plys ) do
        bc.manager.sendNormalClient( v, ply, " to admins: ", bc.defines.colors.green, text )
    end
end
