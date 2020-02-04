--includes
include("betterchat/client/channels/mainchannels.lua")
include("betterchat/client/channels/privatechannels.lua")
include("betterchat/client/channels/adminchannel.lua")
include("betterchat/client/channels/groupchannels.lua")
include("betterchat/client/channels/teamoverload.lua")

chatBox.channelOrder = {"All", "Players", "Team", "Admin"}

hook.Add("BC_InitPanels", "BC_InitChannels", function()
	chatBox.openChannels = {}
	local g = chatBox.graphics

	g.psheet = vgui.Create( "DPropertySheet", g.chatFrame )
	g.psheet:SetName("BC_TabSheet")
	g.psheet:SetPos(0,5)
	g.psheet:SetSize(g.size.x, g.size.y-37)
	g.psheet:SetPadding(0)
	g.psheet:SetFadeTime(0)
	g.psheet:SetMouseInputEnabled(true)
	g.psheet.Paint = nil
	g.psheet.OnActiveTabChanged = function(self, old, new)
		chatBox.closeSidePanel("Channel Settings")
		chatBox.closeSidePanel("Group Members")
		timer.Simple(0.02,function()
			hook.Run("BC_ChannelChanged") -- delay to allow channel data to change
		end)
	end

	g.psheet.tabScroller:DockMargin(3,0,88,0)

end)

hook.Add("BC_PostInitPanels", "BC_PostInitChannels", function()
	table.sort(chatBox.channels, function(a,b)
		aIdx = table.KeyFromValue(chatBox.channelOrder, a.name) or 100
		bIdx = table.KeyFromValue(chatBox.channelOrder, b.name) or 100
		return aIdx < bIdx
	end)
	for k, channel in pairs(chatBox.channels) do
		local shouldOpen = channel.openOnStart
		if type(shouldOpen) == "function" then
			shouldOpen = shouldOpen()
		end
		if shouldOpen then
			chatBox.addChannel(channel)
		end
	end

	--[[
	The only way I can change the "Some people can hear you..." from DarkRP is to create a ChatReceiver
	This needs a prefix which we will pushed to DarkRP by overloading the ChatTextChanged
	This prefix should never ever be typed in normal chat, else the wrong listener will be called (wont error, just wont be correct)
	So heres a wacky string that people probably wont ever type :)
	]]
	chatBox.wackyString = "┘♣├ôÒ"

	updateRPListener()
	
end)

function updateRPListener()
	if not DarkRP then return end

	local c = chatBox.getActiveChannel()

	DarkRP.addChatReceiver(chatBox.wackyString, "talk in " .. c.displayName, function(ply)
		local chan = chatBox.getActiveChannel()

		if chan.group then
			return table.HasValue(chan.group.members, ply:SteamID())
		elseif chan.plySID then
			return chan.plySID == ply:SteamID()
		elseif chan.name == "Admin" then
			return ply:IsAdmin() or (FAdmin and FAdmin.Access.PlayerHasPrivilege(ply, "AdminChat"))
		else
			return false
		end
	end)
end

hook.Add("BC_ChannelChanged", "BC_ChangeRPListener", function()
	updateRPListener()
	local c = chatBox.getActiveChannel()
	if c.hideChatText then
		hook.Run("ChatTextChanged", chatBox.wackyString)
	else
		hook.Run("ChatTextChanged", chatBox.graphics.textEntry:GetText() or "")
	end
end)

hook.Add("BC_KeyCodeTyped", "BC_SendMessageHook", function(code, ctrl, shift)
	if code == KEY_ENTER then
		local channel = chatBox.getActiveChannel()
		local txt = chatBox.graphics.textEntry:GetText()
		chatBox.graphics.textEntry:SetText( "" )

		local abort, dontClose = hook.Run("BC_MessageCanSend", channel, txt)

		if abort then
			if not dontClose then
				chatBox.historyIndex = 0
				chatBox.historyInput = ""
				chatBox.closeChatBox()
			end
			return
		end

		if channel.trim then
			txt = string.Trim(txt)
		end

		if #txt > 0 then
			channel.send(channel, txt)
			table.insert(chatBox.history, txt)
		end
		chatBox.historyIndex = 0
		chatBox.historyInput = ""
		
		hook.Run("BC_MessageSent", channel, txt)
		chatBox.closeChatBox()
		return true
	elseif not chatBox.graphics.emojiMenu:IsVisible() then
		if code == KEY_TAB and ctrl then
			local psheet = chatBox.graphics.psheet
			local tabs = psheet:GetItems()
			local chanName = psheet:GetActiveTab()

			local tabIdx
			for k, v in pairs(tabs) do
				if v.Tab == chanName then
					tabIdx = k
					break
				end
			end

			if not tabIdx then 
				print("(ERROR) TAB INDEX UNDEFINED")
				return true 
			end --Shouldnt ever happen but would rather nothing over an error

			if not shift then
				tabIdx = (tabIdx % #tabs) + 1
			else
				tabIdx = tabIdx - 1
				if tabIdx < 1 then tabIdx = #tabs end --simplicity over looks
			end

			psheet:SetActiveTab(tabs[tabIdx].Tab)

			return true
		elseif code >= KEY_1 and code <= KEY_9 and ctrl then
			local psheet = chatBox.graphics.psheet
			local index = code - 1
			local tabs = psheet:GetItems()
			if tabs[index] then
				psheet:SetActiveTab(tabs[index].Tab)
			end
		end
	end
end)

hook.Add("BC_ShowChat", "BC_showChannelScroller", function() chatBox.graphics.psheet.tabScroller:Show() end)
hook.Add("BC_HideChat", "BC_hideChannelScroller", function() chatBox.graphics.psheet.tabScroller:Hide() end)

function chatBox.getChannel( chanName )
	for k, v in pairs(chatBox.channels) do
		if v.name == chanName then
			return v
		end
	end
	return nil
end

function chatBox.isChannelOpen(channel)
	if not channel then return false end
	return table.HasValue(chatBox.openChannels, channel.name)
end

function chatBox.getActiveChannel()
	local tab = chatBox.graphics.psheet:GetActiveTab()
	local tabs = chatBox.graphics.psheet:GetItems()
	local name = nil
	for k, v in pairs(tabs) do
		if v.Tab == tab then
			name = v.Name
		end
	end
	name = string.Right(name, #name-1)
	return chatBox.getChannel(name)
end

function chatBox.getActiveChannelIdx()
	local tab = chatBox.graphics.psheet:GetActiveTab()
	local tabs = chatBox.graphics.psheet:GetItems()
	local name = nil
	for k, v in pairs(tabs) do
		if v.Tab == tab then
			return k
		end
	end
	return nil
end

function chatBox.messageChannel( channelNames, ... )
	if not chatBox.ready then return end
	if channelNames == nil then
		for k, v in pairs(chatBox.channels) do
			if v.replicateAll then continue end
			chatBox.messageChannelDirect( v, ...)
		end
		return
	end
	if type(channelNames) == "string" then
		channelNames = {channelNames} --if passed single channel, pack into array
	end

	
	local editIdx
	local useEditFunc = true

	local data = {...}
	for k = 1, #data do
		local v = data[k]
		if type(v) == "table" and v.formatter and v.type == "prefix" then
			editIdx = editIdx or k
			table.remove(data, editIdx)
		elseif type(v) == "table" and v.controller and v.type == "noPrefix" then
			useEditFunc = false
			table.remove(data, k)
		end
	end

	local relayToAll = false
	local editChan = nil
	local relayToMsgC = false

	local channels = {}

	for k=1, #channelNames do
		local chanName = channelNames[k]
		if chanName == "MsgC" then
			relayToMsgC = true
			continue
		end

		local channel = chatBox.getChannel( chanName )
		if not channel then continue end
		if channel.relayAll then
			relayToAll = true
			if channel.allFunc then
				if not editChan then
					editChan = channel
				end
			else
				useEditFunc = false
			end
		elseif chanName == "All" then
			relayToAll = true
			useEditFunc = false
			continue
		end
		if channel.replicateAll then continue end
		table.insert(channels, channel)
	end
	
	local dataAll = table.Copy(data)

	if editChan and useEditFunc then
		editChan.allFunc(editChan, dataAll, editIdx or 1)
	end

	if relayToAll then
		chatBox.messageChannelDirect( "All", unpack(dataAll) )
	end

	for k, c in pairs(channels) do
		if c.showAllPrefix then
			chatBox.messageChannelDirect( c, unpack(dataAll) )
		else
			chatBox.messageChannelDirect( c, unpack(data) )
		end
	end

	if relayToMsgC then
		if editChan and useEditFunc then
			editChan.allFunc(editChan, data, editIdx or 1, true)
		end
		chatBox.goodMsgC(unpack(data))
	end

end

function chatBox.messageChannelDirect( channel, controller, ...)
	if not chatBox.ready then return end
	if type(channel) == "string" then
		channel = chatBox.getChannel(channel)
	end

	if not channel or not table.HasValue(chatBox.openChannels, channel.name) then return end

	if channel.name == "All" then
		for k, v in pairs(chatBox.channels) do
			if v.replicateAll then
				chatBox.messageChannelDirect( v, controller, ... )
			end
		end
	end

	local data = {...}

	local doSound = true
	if type(controller) == "table" and (controller.isController or controller.controller) then --if they gave a controller
		if controller.doSound != nil then 
			doSound = controller.doSound 
		end
	else
		table.insert(data, 1, controller)
	end


	if not channel then return end
	local chanName = channel.name

	if doSound then
		if channel.tickMode == 0 then
			chatBox.triggerTick()
		end
		if channel.popMode == 0 then
			chatBox.triggerPop()
		end
	end



	local richText = chatBox.channelPanels[chanName].text
	local prevCol = Color(255,255,255,255)
	richText:InsertColorChange(prevCol.r, prevCol.g, prevCol.b, 255)
	richText:SetMaxLines(chatBox.getSetting("chatHistory"))
	local ignoreNext = false
	for _, obj in pairs(data) do
		if type(obj) == "table" then --colour/formatter
			if obj.formatter then
				if obj.type == "escape" then
					ignoreNext = true
					continue
				elseif obj.type == "clickable" then
					if obj.colour then
						obj.color = obj.colour -- Kinda gross but whatever
					end
					if obj.color then
						richText:InsertColorChange(obj.color.r, obj.color.g, obj.color.b, obj.color.a)
					end
					richText:InsertClickableTextStart(obj.signal)
					richText:AppendText(obj.text)
					richText:InsertClickableTextEnd()
					if obj.color then
						richText:InsertColorChange(prevCol.r, prevCol.g, prevCol.b, 255)
					end
				elseif obj.type == "image" then
					chatBox.addImage(richText, obj)
				elseif obj.type == "text" then
					richText:AppendText( obj.text )
				end
			elseif IsColor(obj) then
				richText:InsertColorChange( obj.r, obj.g, obj.b, 255 )
				prevCol = obj
			end
		elseif type(obj) == "Player" then --ply
			local col = team.GetColor(obj:Team())
			richText:InsertColorChange(col.r, col.g, col.b, 255)
			richText:InsertClickableTextStart("Player-"..obj:SteamID())
			richText:AppendText(obj:Nick())
			richText:InsertClickableTextEnd()
			richText:InsertColorChange(prevCol.r, prevCol.g, prevCol.b, 255)
			if obj == LocalPlayer() and not ignoreNext then
				if doSound then
					if channel.tickMode == 1 then
						chatBox.triggerTick()
					end
					if channel.popMode == 1 then
						chatBox.triggerPop()
					end
				end

			end
		else --normal
			local val = tostring(obj)
			if val == nil then continue end
			richText:AppendText( val )
		end
		ignoreNext = false
	end

	if channel.addNewLines then
		richText:AppendText( "\n" )
	end

	if channel.onMessage then
		channel.onMessage()
	end
end

function chatBox.removeChannel(channel) --rename to closeChannel
	local d = chatBox.channelPanels[channel.name]
	chatBox.graphics.psheet:CloseTab(d.tab, true)
	table.RemoveByValue(chatBox.openChannels, channel.name)
	if not channel.hideInitMessage then
		local chanName = channel.hideRealName and channel.displayName or channel.name
		if channel.name ~= "All" and chatBox.getSetting("printChannelEvents") then
			chatBox.messageChannelDirect("All", chatBox.colors.printBlue, "Channel ", chatBox.colors.yellow, chanName, chatBox.colors.printBlue, " removed.")
		end
	end
	chatBox.removeFromSidePanel("Channel Settings", channel.name)
	if channel.group then
		chatBox.removeFromSidePanel("Group Members", channel.name)
	end
	chatBox.focusChannel("All")
end

function openLink(url)
	if string.Left(url, 7) != "http://" and string.Left(url, 8) != "https://" then
		url = "http://" .. url
	end
	chatBox.closeChatBox()
	gui.OpenURL(url)
end

function chatBox.addChannel(data)
	if not data.displayName then data.displayName = data.name end
	local g = chatBox.graphics
	if not chatBox.channelPanels then chatBox.channelPanels = {} end
	local sPanel = chatBox.addToSidePanel("Channel Settings", data.name)
	chatBox.applyDefaults(data)
	chatBox.generateChannelSettings(sPanel, data)
	table.insert(chatBox.openChannels, data.name)

	data.needsData = false

	local panel = vgui.Create( "DPanel", g.psheet )
	panel.Paint = function(self, w, h)
		self.settingsBtn:SetVisible(self.doPaint)
		if not self.doPaint then return end
		draw.RoundedBox( 0, 5, 2, w - 10 - 28, h-7, Color( 150,150,150,50 ) )
		draw.RoundedBox( 0, w - 10 - 19, 2, 24, h-7, Color( 150,150,150,50 ) )
	end
	panel.doPaint = true

	local richText = vgui.Create( "DRicherText", panel )
	richText:SetPos(10, 10)
	richText:SetSize(g.chatFrame:GetWide() - 20, g.chatFrame:GetTall() - 42 - 37)
	richText:SetFont(data.font or chatBox.graphics.font)
	richText:SetMaxLines(chatBox.getSetting("chatHistory"))
	richText.EventHandler = function(eventType, data, m) 
		local idx = string.find(data, "-")
		local dataType = string.sub(data, 1, idx-1)
		local dataArg = string.sub(data, idx+1, -1);
		if eventType == "LeftClick" then
			if dataType == "Player" then
				local ply = player.GetBySteamID( dataArg )
				if not ply then return end

				if not chatBox.panelExists("Player", dataArg) then
					chatBox.generatePlayerPanelEntry(ply)
				end
				local s = chatBox.sidePanels["Player"]
				if s.isOpen and s.activePanel == dataArg then
					chatBox.closeSidePanel("Player")
				else
					chatBox.openSidePanel("Player", dataArg)
				end
			elseif dataType == "Link" then
				openLink(dataArg)
			end
		elseif eventType == "DoubleClick" then
			if dataType == "Player" then
				local ply = player.GetBySteamID( dataArg )
				if not ply then return end
				if not chatBox.canPrivateMessage(ply) then return end

				channel = chatBox.createPrivateChannel( ply )

				if not chatBox.isChannelOpen(channel) then
					chatBox.addPrivateChannel(channel)
				end
				chatBox.focusChannel(channel.name)
			elseif dataType == "Link" then
				openLink(dataArg)
			end
		elseif eventType == "RightClick" then
			if dataType == "Link" then
				m:AddOption("Copy Link", function()
					SetClipboardText(dataArg)
				end)
			elseif dataType == "Player" then
				m:AddOption("Copy SteamID", function()
					SetClipboardText(dataArg)
				end)
				local ply = player.GetBySteamID( dataArg )
				if ply and chatBox.canPrivateMessage(ply) then
					m:AddOption("Open Private Channel", function()
						local ply = player.GetBySteamID( dataArg )
						if not ply then return end

						channel = chatBox.createPrivateChannel( ply )

						if not chatBox.isChannelOpen(channel) then
							chatBox.addPrivateChannel(channel)
						end
						chatBox.focusChannel(channel.name)
					end)
				end
			end
		elseif eventType == "RightClickPreMenu" then
			if dataType == "Player" then
				local ply = player.GetBySteamID( dataArg )
				hook.Run("BC_PlayerRightClick", ply, m)
			end
		end
		hook.Run("BC_ChatTextClick", eventType, dataType, dataArg)
	end

	richText.NewElement = function(element, lineNum)
		element.lineNo = lineNum
		element.timeCreated = CurTime()
		element.Think = function(self)
			if chatBox.isOpen then
				local col = self:GetTextColor()
				col.a = 255
				self:SetTextColor(col)
			else
				local col = self:GetTextColor()
				local dt = CurTime() - self.timeCreated
				local fadeTime = chatBox.getSetting("fadeTime")
				if fadeTime == 0 then 
					col.a = 255
				elseif dt > fadeTime + 1 then
					col.a = 0
				else
					dt = math.Max(dt - fadeTime, 0)
					col.a = math.Max(255 - dt*255, 0)
				end
				
				self:SetTextColor(col)
			end
		end
	end

	local settingsBtn = vgui.Create("DButton", panel)
	settingsBtn:SetPos(g.chatFrame:GetWide() - 59, 5)
	settingsBtn:SetSize(24,24)
	settingsBtn:SetText("")
	settingsBtn:SetColor(Color(50,50,50,150))
	settingsBtn.ang = 0
	settingsBtn.name = data.name
	settingsBtn.DoClick = function(self)
		local s = chatBox.sidePanels["Channel Settings"]
		if s.isOpen then
			chatBox.closeSidePanel(s.name)
		else
			chatBox.openSidePanel(s.name, self.name)
		end
	end
	settingsBtn.Paint = function(self, w, h)
		self.ang = -45 * chatBox.sidePanels["Channel Settings"].animState
		self:SetColor(lerpCol(Color(50,50,50,150), Color(50,50,50,230), chatBox.sidePanels["Channel Settings"].animState))
		surface.SetMaterial(chatBox.materials.getMaterial("icons/cog.png"))
		surface.SetDrawColor( self:GetColor() )
		surface.DrawTexturedRectRotated( w/2, h/2, w, h, self.ang )
	end

	panel.settingsBtn = settingsBtn
	panel.text = richText
	panel.data = data

	local v = chatBox.graphics.psheet:AddSheet(" " .. data.name, panel, "icon16/" .. data.icon)
	chatBox.channelPanels[data.name] = {panel = panel, text = richText, tab = v.Tab}
	v.Tab.GetTabHeight = function() return 22 end
	v.Tab.data = data
	v.Tab.Paint = function(self, w, h)
		local a = self:IsActive()
		local c = a and 150 or 200
		
		draw.RoundedBox( 0, 2, 0, w-4, h, Color( c,c,c,50 ) )
		if self:GetText() != " " .. self.data.displayName then
			self:SetText(" " .. self.data.displayName)
			self:GetPropertySheet().tabScroller:InvalidateLayout(true) -- to make the tabs resize correctly
		end
	end
	v.Tab.DoRightClick = function(self)
		local menu = DermaMenu()
		menu:AddOption("Settings", function()
			local s = chatBox.sidePanels["Channel Settings"]
			if s.isOpen and s.activePanel == self.data.name then
				chatBox.closeSidePanel(s.name)
			else
				chatBox.openSidePanel(s.name, self.data.name)
			end
		end)
		if not self.data.disallowClose then
			menu:AddOption("Close", function()
				chatBox.removeChannel(self.data)
			end)
		end
		menu:Open()
	end

	v.Tab.DoMiddleClick = function(self)
		if not self.data.disallowClose then
			chatBox.removeChannel(self.data)
		end
	end

	v.Tab:SetText(" " .. data.displayName)
	v.Tab:GetPropertySheet().tabScroller:InvalidateLayout(true) -- Force the Tab size to be correct instantly
																-- Waiting to first paint can cause issues

	if data.postAdd then data.postAdd(data, panel) end

	for k, v in pairs(chatBox.channelSettingsTemplate) do
		if v.onInit then
			v.onInit(data, richText)
		end
	end

	if not chatBox.isOpen then
		v.Tab:Hide()
	end

	if not data.hideInitMessage and chatBox.getSetting("printChannelEvents") then
		local chanName = data.hideRealName and data.displayName or data.name

		local function createdPrint()
			if not data.replicateAll then
				chatBox.messageChannelDirect(data.name, chatBox.colors.printBlue, "Channel ", chatBox.colors.yellow, chanName, chatBox.colors.printBlue, " created.")
			end
			if data.name ~= "All" then
				chatBox.messageChannelDirect("All", chatBox.colors.printBlue, "Channel ", chatBox.colors.yellow, chanName, chatBox.colors.printBlue, " created.")
			end
		end
		if chatBox.initializing then
			timer.Simple(0, createdPrint) -- Delay messages to allow other channels to be created before prints
		else
			createdPrint()
		end
	end
end

function chatBox.focusChannel(channel)
	local tabName
	if type(channel) == "string" then 
		tabName = channel
	else
		tabName = channel.name
	end
	for k, tab in pairs(chatBox.graphics.psheet:GetItems()) do
		if tab.Name == " " .. tabName then
			chatBox.graphics.psheet:SetActiveTab(tab.Tab)
			chatBox.graphics.psheet.tabScroller:ScrollToChild(tab.Tab)
		end
	end
end

function chatBox.showPSheet()
	for k, v in pairs(chatBox.graphics.psheet:GetItems()) do
		v.Tab:Show()
		v.Panel.text:SetVerticalScrollbarEnabled(true)
		if not v.Panel.data.displayClosed then
			v.Panel:Show()
		end
		v.Panel.doPaint = true
	end
	chatBox.graphics.psheet.tabScroller:InvalidateLayout(true) --Psheets like to just fuck up their tabs
end

function chatBox.hidePSheet()
	for k, v in pairs(chatBox.graphics.psheet:GetItems()) do
		v.Panel.text:UnselectText()
		v.Tab:Hide()
		v.Panel.text:scrollToBottom()
		v.Panel.text:SetVerticalScrollbarEnabled(false)
		if not v.Panel.data.displayClosed then
			v.Panel:Hide()
			v.Panel.doPaint = true
		else
			v.Panel.doPaint = false
			chatBox.graphics.psheet:SetActiveTab(v.Tab)
		end
	end
end

function chatBox.getAndOpenChannel(chanName)
	local chan = chatBox.getChannel(chanName)

	if not chan or not chatBox.isChannelOpen(chan) then
		local dashPos = string.find(chanName, " - ", 1, true)
		if not dashPos then return nil end
		local nameType = string.sub(chanName, 1, dashPos-1)
		local nameArg = string.sub(chanName, dashPos+3)

		if nameType == "Group" and chatBox.allowedGroups() then
			local id = tonumber(nameArg)
			local found = false
			for k, v in pairs(chatBox.group.groups) do
				if v.id == id then
					found = true
					local c = chatBox.createGroupChannel(v)
					if not c then continue end
					chatBox.addChannel(c)
				end
			end
			if not found then return nil end
		elseif nameType == "Player" and chatBox.allowedPrivate() then
			local sId = nameArg
			local ply = player.GetBySteamID(sId)
			if not ply then return nil end
			chatBox.addPrivateChannel(chatBox.createPrivateChannel(ply))
		else
			return chatBox.getChannel("All")
		end
	end

	return chan
end