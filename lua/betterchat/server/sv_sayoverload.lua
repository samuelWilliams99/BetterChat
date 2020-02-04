net.Receive("BC_SayOverload", function(len, ply)
	local isTeam = net.ReadBool()
	local isDead = net.ReadBool()
	local msg = net.ReadString()
	local recips = isTeam and team.GetPlayers(ply:Team()) or player.GetAll()

	local ret = hook.Run("PlayerSay", ply, msg, isTeam)
	if ret ~= nil then msg = ret end

	if not msg or msg == "" then return end

	net.Start("BC_SayOverload")
	net.WriteEntity(ply)
	net.WriteBool(isTeam)
	net.WriteBool(isDead)
	net.WriteString(msg)
	net.Send(recips)
end)