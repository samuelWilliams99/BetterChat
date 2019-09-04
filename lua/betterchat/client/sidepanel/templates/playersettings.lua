chatBox.playerSettingsTemplate = {
	{
		name = "Ignore",
		value = "ignore",
		type = "options",
		options = {"Don't ignore", "Ignore", "Perma ignore"},
		optionValues = {0, 1, 2},
		default = 0,
		extra = "No longer see messages from this user. (Ignore is for rest of this session, Perma ignore saves across sessions)",
		extraCanRun = function(ply) 
			return (ply != LocalPlayer() and not ply:IsSuperAdmin())
		end,
		shouldSave = true,
		preSave = function(data)
			if data.ignore == 1 then return 0 end
			return data.ignore
		end
	},
	{
		name = "Private message",
		type = "button",
		text = "Open channel",
		extra = "Open a private channel with this player",
		onClick = function(data)
			channel = chatBox.createPrivateChannel( data.ply )
			if not chatBox.isChannelOpen(channel) then
				chatBox.addPrivateChannel(channel)
			end
			chatBox.focusChannel(channel.name)
		end
	},
	{
		name = "Custom command",
		type = "button",
		text = "Add",
		extra = "Add a custom console command for quick access on players",
		onClick = function(data)
			chatBox.addPlayerSetting(data.ply)
		end
	},
	{
		name = "Jail",
		toggle = true,
		command = "ulx jail",
		toggleCommand = "ulx unjail",
		type = "command",
		value = "jailed",
		default = false,
		//extraCanRun = function(ply) return ply != LocalPlayer() end
	},
	{
		name = "God",
		toggle = true,
		command = "ulx god",
		toggleCommand = "ulx ungod",
		type = "command",
		value = "inGod",
		default = false,
		extraCanRun = function(ply) return ply == LocalPlayer() end
	},
	{
		name = "Goto",
		command = "ulx goto",
		type = "command",
		extraCanRun = function(ply) return ply != LocalPlayer() end
	},
	{
		name = "Bring",
		command = "ulx bring",
		type = "command",
		extraCanRun = function(ply) return ply != LocalPlayer() end
	},
	{
		name = "Kick",
		command = "ulx kick",
		type = "command",
		postArgs = {
			function(data)
				local r = data.kickReason
				if r == "Unspecified" then return "" end
				return "You have been kicked for \"" .. r .. "\". If you rejoin, please read the rules" --kick adds its own "."
			end
		},
		requireConfirm = true,
		closeOnTrigger = true
	},
	{
		name = "Kick Reason",
		value = "kickReason",
		type = "options",
		options = {"Unspecified", "Lagging server", "Prop block", "Prop spam", "Rope spam", "RDM", "Racism", "Minge", "Being a prick"},
		default = "Unspecified",
		extra = "The reason for kicking the player",
		parentSetting = "Kick"
	},
	{
		name = "Freeze",
		toggle = true,
		command = "ulx freeze",
		toggleCommand = "ulx unfreeze",
		default = false,
		value = "isFrozen",
		type = "command",
	},
	{
		name = "Slay",
		command = "ulx slay",
		type = "command",
		extraCanRun = function(ply) return ply != LocalPlayer() end
	},
	{
		name = "Freezeprops",
		command = "ulx freezeprops",
		type = "command",
	},
	{
		name = "Cleanup props",
		command = "ulx cleanup",
		type = "command",
	},
	{
		name = "Ragdoll",
		toggle = true,
		command = "ulx ragdoll",
		toggleCommand = "ulx unragdoll",
		default = false,
		value = "isRagdolled",
		type = "command",
	},
}

function chatBox.validatePlayerSettings()
	for k, v in pairs(chatBox.playerSettingsTemplate) do
		if v.type == "command" then
			v.type = "button"
			v.text = v.command
			v.toggleText = v.toggleCommand
			local tog = v.toggle
			local cmd = string.Explode(" ", v.command)
			local cmdTog
			if tog then
				cmdTog = string.Explode(" ", v.toggleCommand)
			end
			v.extra = "Run " .. v.command .. (tog and (" or " .. v.toggleCommand) or "") .. " on this player"

			local preArgs = v.preArgs
			local postArgs = v.postArgs

			v.onClick = function(data, setting)

				local state = false
				if tog then
					state = data[setting.value]
				end
				local cmdCopy = table.Copy(state and cmdTog or cmd)

				if preArgs then
					for l, w in pairs(preArgs) do
						if type(w) == "function" then
							w = w(data)
						end
						table.insert(cmdCopy, w)
					end
				end
				
				table.insert(cmdCopy, data.ply:GetName())

				if postArgs then
					for l, w in pairs(postArgs) do
						if type(w) == "function" then
							w = w(data)
						end
						table.insert(cmdCopy, w)
					end
				end

				RunConsoleCommand(unpack(cmdCopy))
			end
		
		end
	end
end