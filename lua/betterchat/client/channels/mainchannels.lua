
function globalSend(self, txt)
	RunConsoleCommand("say", txt)
end
function teamSend(self, txt)
	RunConsoleCommand("say_team", txt)
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
		disabledSettings = {"relayAll", "openKey"},
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
		})
	end
end)

local skipNext = false

timer.Create("BC_BugMessage", 300, 0, function()
	if not chatBox.getSetting("hideBugMessage") and not skipNext then
		skipNext = true
		chatBox.messageChannelDirect("All", chatBox.colors.printBlue, "Found a bug with ",chatBox.colors.yellow,"BetterChat", 
			chatBox.colors.printBlue,"? Get in touch with ", {formatter=true, type="clickable", signal="Link-https://steamcommunity.com/id/bobdinator/", text="me", color=chatBox.colors.yellow},
			" or put it in discussions on the ", {formatter=true, type="clickable", signal="Link-https://steamcommunity.com/sharedfiles/filedetails/?id=1841694244", text="workshop page", color=chatBox.colors.yellow},"!")
	end
end)

hook.Add("OnPlayerChat", "BC_BugMessageChat", function()
	skipNext = false
end)