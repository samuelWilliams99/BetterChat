hook.Add( "BC_plyReady", "BC_sidePanelsInit", function(ply)
	for k, v in pairs(player.GetAll()) do
		ULib.clientRPC(ply, "chatBox.generatePlayerPanelEntry", v)
	end
end)