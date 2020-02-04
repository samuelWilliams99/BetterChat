
local function useOverload()
	return chatBox.getSettingObject("maxLength", true).default ~= chatBox.getServerSetting("maxLength") 
end

function globalSend(self, txt)
	if useOverload() then
		net.Start("BC_SayOverload")
		net.WriteBool(false)
		net.WriteBool(not LocalPlayer():Alive())
		net.WriteString(txt)
		net.SendToServer()
	else
		RunConsoleCommand("say", txt)
	end
end
function teamSend(self, txt)
	if useOverload() then
		net.Start("BC_SayOverload")
		net.WriteBool(true)
		net.WriteBool(not LocalPlayer():Alive())
		net.WriteString(txt)
		net.SendToServer()
	else
		RunConsoleCommand("say_team", txt)
	end
end

hook.Add("BC_PreInitPanels", "BC_InitAddMainChannels", function()
	table.insert(chatBox.channels, {
		name = "All", 
		icon = "world.png",
		send = globalSend,
		displayClosed = true,
		doPrints = true,
		addNewLines = true,
		trim = true,
		disabledSettings = {"relayAll", "openKey", "replicateAll", "showAllPrefix"},
		tickMode = 2,
		popMode = 2,
		openOnStart = true,
		disallowClose = true,
		relayAll = false,
	}) 
	table.insert(chatBox.channels, {
		name = "Players", 
		icon = "group.png",
		send = globalSend,
		trim = true,
		addNewLines = true,
		openOnStart = true,
		disallowClose = true,
	})
	if not DarkRP then
		table.insert(chatBox.channels, {
			name = "Team", 
			icon = "group.png",
			send = teamSend,
			onMessage = function()
				chatBox.lastPrivate = nil
			end,
			doPrints = true,
			addNewLines = true,
			disabledSettings = {"openKey"},
			allFunc = function(self, tab, idx)
				table.insert(tab, idx, Color(0,170,0) )
				table.insert(tab, idx+1, "(TEAM) " )
			end,
			openOnStart = true,
			disallowClose = true,
			textEntryColor = Color(100,200,100),
			replicateAll = true,
		})
	end
end)