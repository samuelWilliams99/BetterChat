net.Receive("BC_TM", function(len, ply)
	local t = ply:Team()
	local plys = {}
	for k, v in pairs(player.GetAll()) do
		if t == v:Team() then
			table.insert(plys, v)
		end
	end
	local msg = net.ReadString()

	print("(" .. team.GetName(t) .. ") " .. ply:GetName() .. ": " .. msg)

	net.Start("BC_TM")
	net.WriteEntity(ply)
	net.WriteString(msg)
	net.Send(plys)
end)