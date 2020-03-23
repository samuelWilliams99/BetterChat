timer.Create( "BC_delayOverload", 0, 1, function()
    function ulx.psay( calling_ply, target_ply, message )
        if calling_ply:GetNWBool( "ulx_muted", false ) then
            ULib.tsayError( calling_ply, "You are muted, and therefore cannot speak! Use asay for admin chat if urgent.", true )
            return
        end
        bc.private.sendPrivate( target_ply, calling_ply, calling_ply, message, true )
        bc.private.sendPrivate( calling_ply, calling_ply, target_ply, message )
    end
    local psay = ulx.command( "Chat", "ulx psay", ulx.psay, "!p", true )
    psay:addParam{ type = ULib.cmds.PlayerArg, target = "!^", ULib.cmds.ignoreCanTarget }
    psay:addParam{ type = ULib.cmds.StringArg, hint = "message", ULib.cmds.takeRestOfLine }
    psay:defaultAccess( ULib.ACCESS_ALL )
    psay:help( "Send a private message to target." )

    function ulx.asay( calling_ply, message )
        bc.admin.sendAdmin( calling_ply, message )
    end
    local asay = ulx.command( CATEGORY_NAME, "ulx asay", ulx.asay, "@", true, true )
    asay:addParam{ type = ULib.cmds.StringArg, hint = "message", ULib.cmds.takeRestOfLine }
    asay:defaultAccess( ULib.ACCESS_ALL )
    asay:help( "Send a message to currently connected admins." )
end )
