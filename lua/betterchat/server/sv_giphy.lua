chatBox.giphy = chatBox.giphy or {}
chatBox.giphy.counts = chatBox.giphy.counts or {}
chatBox.giphy.lastResetHour = chatBox.giphy.lastResetHour or -1

-- Single think hook call so http is ready
hook.Add("Think", "BC_GiphyInit", function()
	hook.Remove("Think", "BC_GiphyInit")
	chatBox.getGiphyURL("thing", function(success, data)
		if success then
			print("[BetterChat] Giphy key test successful, giphy command enabled.")
			chatBox.giphy.enabled = true
		else
			print("[BetterChat] No valid Giphy API key found in bc_server_giphykey, giphy command disabled. Generate an app key from https://developers.giphy.com/ to use this feature.")
		end
	end )
end )

function escape(s)
	s = string.gsub(s, "([&=+%c])", function (c)
		return string.format("%%%02X", string.byte(c))
	end)
	s = string.gsub(s, " ", "+")
	return s
end

function encode(t)
	local s = ""
	for k,v in pairs(t) do
		s = s .. "&" .. escape(k) .. "=" .. escape(v)
	end
	return string.sub(s, 2)
end

function chatBox.getGiphyURL(query, cb)
	local key = chatBox.getServerSetting("giphyKey")
	if not key or #key == 0 then
		return cb(false)
	end

	http.Fetch( "https://api.giphy.com/v1/gifs/search?" .. encode({
		api_key = key,
		q = query,
		limit = 1
	}), function( body, _, _, code )
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

net.Receive("BC_SendGif", function(len, ply)
	if not chatBox.giphy.enabled then return end

	if not chatBox.getAllowed(ply, "bc_giphy") then
		ULib.clientRPC(ply, "chatBox.messageChannel", channel, chatBox.colors.red, "You don't have permission to use !giphy")
		return
	end

	local curDateTime = os.date("*t", os.time())
	local hour = curDateTime.hour
	if hour ~= chatBox.giphy.lastResetHour then
		chatBox.giphy.lastResetHour = hour
		chatBox.giphy.counts = {}
	end

	local curCount = chatBox.giphy.counts[ply:SteamID()] or 0
	local maxCount = chatBox.getServerSetting("giphyHourlyLimit")
	chatBox.giphy.counts[ply:SteamID()] = curCount + 1
	if curCount >= maxCount then
		ULib.clientRPC(ply, "chatBox.messageChannel", channel, chatBox.colors.red, "You have surpassed your hourly giphy limit of " .. maxCount .. 
			". Your quota will reset in approximately " .. (60 - curDateTime.min) .. " minute(s).")
		return
	end

	local str = net.ReadString()
	local channel = net.ReadString()
	if string.match(str, "^[%w_%. %-]+$") then
		chatBox.getGiphyURL(str, function(success, data)
			if success then
				ULib.clientRPC(ply, "chatBox.messageChannel", channel, chatBox.colors.printYellow, "You have " .. (maxCount - curCount - 1) .. " giphy uses left for this hour.")
				local recips = chatBox.getClients(channel, ply)
				net.Start("BC_SendGif")
				net.WriteString(data)
				net.WriteString(channel)
				net.WriteString(str)
				net.Send(recips)
			else
				ULib.clientRPC(ply, "chatBox.messageChannel", channel, chatBox.colors.red, "Giphy query failed, server wide hourly limit may have been reached")
			end
		end )
	else
		ULib.clientRPC(ply, "chatBox.messageChannel", channel, chatBox.colors.red, "Invalid giphy query string, only alphanumeric characters, underscores or dots.")
	end
end )

function chatBox.getClients( chanName, sender )
	if chanName == "All" or chanName == "Players" then
		return player.GetAll()
	elseif chanName == "Team" then
		return team.GetPlayers(sender:Team())
	elseif chanName == "Admin" then
		local out = {}
		for k, p in pairs(player.GetAll()) do
			if chatBox.getAllowed(v, "ulx seeasay") then
				table.insert(out, p)
			end
		end
		return out
	elseif string.sub(chanName, 1, 9) == "Player - " then
		local ply = player.GetBySteamID(string.sub(chanName, 10))
		if ply then return {sender, ply} end
		return {sender}
	elseif string.sub(chanName, 1, 8) == "Group - " then
		local groupId = tonumber(string.sub(chanName, 9))
		for k, group in pairs(chatBox.group.groups) do
			if group.id == groupId then
				return chatBox.getGroupMembers(group)
			end
		end
		return {}
	end
	return {}
end