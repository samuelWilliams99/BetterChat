function allowedPrivate(ply)
	return chatBox.getAllowed(ply, "ulx psay")
end

function canPrivateMessage(from, to)
	return allowedPrivate(from) and allowedPrivate(to)
end

timer.Create("BC_DelayOverload", 5, 1, function()
	function ulx.psay( calling_ply, target_ply, message )
		if calling_ply:GetNWBool( "ulx_muted", false ) then
			ULib.tsayError( calling_ply, "You are muted, and therefore cannot speak! Use asay for admin chat if urgent.", true )
			return
		end
		if not canPrivateMessage(calling_ply, target_ply) then return end
		local plys = {}
		if not chatBox.chatBoxEnabled[calling_ply] then
			table.insert(plys, calling_ply)
		else
			net.Start("BC_PM")
			net.WriteEntity(target_ply)
			net.WriteEntity(calling_ply)
			net.WriteString(message)
			net.Send(calling_ply)
		end

		if not chatBox.chatBoxEnabled[target_ply] then
			table.insert(plys, target_ply)
		else
			net.Start("BC_PM")
			net.WriteEntity(calling_ply)
			net.WriteEntity(calling_ply)
			net.WriteString(message)
			net.Send(target_ply)
		end

		if #plys > 0 then
			ulx.fancyLog( plys, "#P to #P: " .. message, calling_ply, target_ply )
		end
	end
	local psay = ulx.command( "Chat", "ulx psay", ulx.psay, "!p", true )
	psay:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
	psay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
	psay:defaultAccess( ULib.ACCESS_ALL )
	psay:help( "Send a private message to target." )

	function ulx.asay( calling_ply, message )
		local players = player.GetAll()
		for i=#players, 1, -1 do
			local v = players[ i ]
			if not ULib.ucl.query( v, "ulx seeasay" ) and v ~= calling_ply then -- Calling player always gets to see the echo
				table.remove( players, i )
			end
		end
		for i=#players, 1, -1 do
			local v = players[ i ]
			if chatBox.chatBoxEnabled[v] then
				table.remove(players, i)
				net.Start("BC_AM")
				net.WriteEntity(calling_ply)
				net.WriteString(message)
				net.Send(v)
			end
		end

		--This code is in the original function, seems pretty pointless but best not remove it.
		local format
		local me = "/me "
		if message:sub( 1, me:len() ) == me then
			format = "(ADMINS) *** #P #s"
			message = message:sub( me:len() + 1 )
		else
			format = "#P to admins: #s"
		end

		ulx.fancyLog( players, format, calling_ply, message ) -- log even if players == {} as it'll log to console
	end
	local asay = ulx.command( CATEGORY_NAME, "ulx asay", ulx.asay, "@", true, true )
	asay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
	asay:defaultAccess( ULib.ACCESS_ALL )
	asay:help( "Send a message to currently connected admins." )
end)