net.Receive("BC_AM",function(len, ply)
	local txt = net.ReadString()

	local plys = {}

	for k, p in pairs(player.GetAll()) do
		if chatBox.getAllowed(p, "ulx seeasay") then
			if chatBox.chatBoxEnabled[p] then
				net.Start("BC_AM")
				net.WriteEntity(ply)
				net.WriteString(txt)
				net.Send(p)
			else
				table.insert(plys, p)
			end
		end
	end

	if #plys > 0 then
		ulx.fancyLog( plys, "#P to admins: #s", ply, txt )
	else
		print("(ADMIN) " .. ply:GetName() .. ": " .. txt)
	end
end)