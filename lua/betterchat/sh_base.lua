//might be useful: https://unpkg.com/emoji-mart@0.2.7/sheets/sheet_emojione_64.png
chatBox = chatBox or {}

if SERVER then
	--includes
	include("betterchat/server/sv_overloads.lua")
	include("betterchat/server/sv_playerstates.lua")
	include("betterchat/server/sv_privatemessages.lua")
	include("betterchat/server/sv_adminmessages.lua")
	include("betterchat/server/sv_sendcommands.lua")
	include("betterchat/server/sv_sidepanelsinit.lua")
	include("betterchat/server/sv_groups.lua")
	include("betterchat/server/sv_teamoverload.lua")
	include("betterchat/server/sv_sayoverload.lua")

	--addfiles
	AddCSLuaFile("betterchat/sh_base.lua")
	AddCSLuaFile("betterchat/sh_util.lua")
	AddCSLuaFile("betterchat/client/chat.lua")
	AddCSLuaFile("betterchat/client/overload.lua")
	AddCSLuaFile("betterchat/sh_globalsettings.lua")
	AddCSLuaFile("betterchat/client/datamanager.lua")
	AddCSLuaFile("betterchat/client/images.lua")
	AddCSLuaFile("betterchat/client/compatibility.lua")

	AddCSLuaFile("betterchat/client/channels/channels.lua")
	AddCSLuaFile("betterchat/client/channels/mainchannels.lua")
	AddCSLuaFile("betterchat/client/channels/adminchannel.lua")
	AddCSLuaFile("betterchat/client/channels/privatechannels.lua")
	AddCSLuaFile("betterchat/client/channels/groupchannels.lua")
	AddCSLuaFile("betterchat/client/channels/teamoverload.lua")

	AddCSLuaFile("betterchat/client/input/input.lua")
	AddCSLuaFile("betterchat/client/input/autocomplete.lua")

	AddCSLuaFile("betterchat/client/sidepanel/sidepanel.lua")
	AddCSLuaFile("betterchat/client/sidepanel/panels/channels.lua")
	AddCSLuaFile("betterchat/client/sidepanel/panels/players.lua")
	AddCSLuaFile("betterchat/client/sidepanel/panels/members.lua")
	AddCSLuaFile("betterchat/client/sidepanel/panels/players_add_option.lua")
	AddCSLuaFile("betterchat/client/sidepanel/templates/channelsettings.lua")
	AddCSLuaFile("betterchat/client/sidepanel/templates/playersettings.lua")
	AddCSLuaFile("betterchat/client/sidepanel/templates/membersettings.lua")
	

	--panels
	AddCSLuaFile("betterchat/client/vguipanels/davatarimagerounded.lua")
	AddCSLuaFile("betterchat/client/vguipanels/dnicescrollpanel.lua")
	AddCSLuaFile("betterchat/client/vguipanels/drichertext.lua")
	AddCSLuaFile("betterchat/client/vguipanels/drichertextgraphic.lua")

	util.AddNetworkString( "BC_openChat" )
	util.AddNetworkString( "BC_closeChat" )
	util.AddNetworkString( "BC_sendPlayerState" )
	util.AddNetworkString( "BC_plyReady" )
	util.AddNetworkString( "BC_disable" )
	util.AddNetworkString( "BC_PM" )
	util.AddNetworkString( "BC_AM" )
	util.AddNetworkString( "BC_sendULXCommands" )
	util.AddNetworkString( "BC_UserRankChange" )
	util.AddNetworkString( "BC_PlayerDisconnected" )
	util.AddNetworkString( "BC_sendGroups" )
	util.AddNetworkString( "BC_GM" )
	util.AddNetworkString( "BC_updateGroup" )
	util.AddNetworkString( "BC_newGroup" )
	util.AddNetworkString( "BC_groupAccept" )
	util.AddNetworkString( "BC_leaveGroup" )
	util.AddNetworkString( "BC_deleteGroup" )
	util.AddNetworkString( "BC_forwardMessage" )
	util.AddNetworkString( "BC_TM" )
	util.AddNetworkString( "BC_SayOverload" )

	function chatBox.getEnabledPlayers()
		local out = {}
		for k, v in pairs(player.GetAll()) do
			if chatBox.chatBoxEnabled[v] then
				table.insert(out, v)
			end
		end
		return out
	end

	chatBox.chatBoxEnabled = {}

	net.Receive( "BC_openChat", function(len, ply)
		ULib.clientRPC(nil, "chatBox.setPlayersOpen", ply, true)
	end)
	net.Receive( "BC_closeChat", function(len, ply)
		ULib.clientRPC(nil, "chatBox.setPlayersOpen", ply, false)
	end)

	net.Receive( "BC_forwardMessage", function(len, ply)
		hook.Run("PlayerSay", ply, net.ReadString(), true)
	end)

	hook.Add("PlayerInitialSpawn", "BC_PlySpawn", function(ply)
		local plys = chatBox.getEnabledPlayers()
		local plysCopy = table.Copy(plys)
		table.RemoveByValue(plys,ply)

		ULib.clientRPC(plys, "chatBox.generatePlayerPanelEntry", ply)
		ULib.clientRPC(plys, "hook.Run", "BC_PlayerConnect", ply)
		

		-- Haven't got my name anywhere in this chat, so heres my lil credit :)
		-- Just a cheeky lil welcome message for me
		if ply:SteamID() == "STEAM_0:1:46658202" then
			timer.Simple(2, function()
				ULib.clientRPC(plys, "chatBox.messageChannel", "All", chatBox.colors.printBlue, "Yay! ", ply, "'s here!")
			end)
		end

	end)

	hook.Add("PlayerDisconnected", "BC_PlyLeave", function(ply)
		chatBox.chatBoxEnabled[ply] = false
		local plys = chatBox.getEnabledPlayers()
		table.RemoveByValue(plys,ply)

		ULib.clientRPC(plys, "chatBox.removePlayerPanel", ply:SteamID())
		ULib.clientRPC(plys, "hook.Run", "BC_PlayerDisconnect", ply:SteamID())
	end)

	net.Receive( "BC_plyReady", function(len, ply) --can now send data to ply
		chatBox.chatBoxEnabled[ply] = true
		hook.Run( "BC_plyReady", ply)

	end)

	net.Receive( "BC_disable", function(len, ply)
		chatBox.chatBoxEnabled[ply] = false
	end)


end

include("betterchat/sh_util.lua")
include("betterchat/sh_globalsettings.lua")
hook.Run("BC_SharedInit")
if SERVER then 
	return
end

--includes
include("betterchat/client/chat.lua")
include("betterchat/client/overload.lua")
include("betterchat/client/datamanager.lua")
include("betterchat/client/images.lua")
include("betterchat/client/compatibility.lua")
include("betterchat/client/channels/channels.lua")
include("betterchat/client/sidepanel/sidepanel.lua")
include("betterchat/client/input/input.lua")
--panels
include("betterchat/client/vguipanels/davatarimagerounded.lua")
include("betterchat/client/vguipanels/dnicescrollpanel.lua")
include("betterchat/client/vguipanels/drichertext.lua")

concommand.Add( "bc_enable", function()
	if chatBox.enabled then
		chatBox.disableChatBox()
	end
	chatBox.enableChatBox()
end, true, "Enables BetterChat")



concommand.Add( "bc_reload", function()
	if chatBox.enabled then
		chatBox.disableChatBox()
	end
	timer.Simple(0.1, function() -- Delay to allow save
		include("betterChat/sh_base.lua")
		chatBox.enableChatBox()
	end)
end, true, "Rebuilds the new chat box" )

concommand.Add( "bc_savedata", chatBox.saveData, true, "Saves all chat data to file")


if chatBox and chatBox.graphics and chatBox.graphics.frame then 
	chatBox.graphics.frame:Remove()	
end

chatBox.enabled = true
chatBox.ready = false
chatBox.playersOpen = {}

chatBox.channels = {}
chatBox.lastPrivate = nil
chatBox.openChannels = {}

hook.Add( "InitPostEntity", "BC_Loaded", function()
	chatBox.loadEnabled()
	if chatBox.enabled then
		chatBox.buildBox()
		net.Start("BC_plyReady")
		net.SendToServer()
		chatBox.loadData()
	else
		chat.AddText(chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "is currently disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it.")
	end
end )

chatBox.validatePlayerSettings()

function chatBox.enableChatBox()
	chatBox.enabled = true
	chatBox.buildBox()
	net.Start("BC_plyReady")
	net.SendToServer()

	chatBox.loadData()
	chatBox.enabled = true
	chatBox.saveEnabled()
end

function chatBox.disableChatBox()
	chatBox.enabled = false
	chatBox.saveData()
	if chatBox.overloaded then
		chatBox.returnFunctions()
	end
	chatBox.removeGraphics()
	chatBox.autoComplete = nil
	chatBox.channels = nil

	net.Start("BC_disable")
	net.SendToServer()
end


function chatBox.buildBox()
	if chatBox.overloaded then
		chatBox.returnFunctions()
	end
	chatBox.overloadFunctions()
	
	if chatBox.graphics then
		chatBox.removeGraphics()
	end

	chatBox.channels = {}
	chatBox.graphics = {}
	local g = chatBox.graphics
	g.font = "chatFont_18"
	g.size = {x = 550, y = 301}
	g.originalFramePos = { x = 38, y = ScrH() - 450 }

	g.visCheck = timer.Create("chatBox_visCheck", 1/60, 0, function()
		if not g.frame or not g.frame:IsValid() then
			timer.Destroy("chatBox_visCheck")
			return
		end
		if gui.IsGameUIVisible() then
			g.frame:Hide()
		else
			if not g.frame:IsVisible() then
				g.frame:Show()
			end
		end
	end)

	g.frame = vgui.Create( "DFrame" )
	g.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
	g.frame:SetSize( g.size.x, g.size.y + 40 ) --Added 40 for AutoComplete
	g.frame:SetTitle( "" )
	g.frame:SetName("BC_ChatFrame")
	g.frame:ShowCloseButton(false)
	g.frame:SetDraggable(false)
	g.frame:SetSizable(false)
	g.frame.Paint = nil
	g.frame.EscapeDown = false
	g.frame.Think = function(self)
		if input.IsKeyDown( KEY_ESCAPE ) then
			if self.EscapeDown then return end
			self.EscapeDown = true

			if not chatBox.isOpen then return end

			local mx, my = gui.MousePos()
			-- Work around to hide the chatbox when the client presses escape
			gui.HideGameUI()

			if vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() == "BC_SettingsKeyEntry" then
				chatBox.graphics.textEntry:RequestFocus()
			-- elseif chatBox.settings.isOpen then --This bit doesnt really work since multiple sidePanels
			-- 	chatBox.closeSettings()
			-- 	timer.Create("BC_MoveMouseBack", 0.01, 1, function()
			-- 		gui.SetMousePos(mx, my)
			-- 	end)
			else
				chatBox.graphics.textEntry:SetText( "" )
				chatBox.closeChatBox()
			end
		else
			self.EscapeDown = false
		end
	end

	g.chatFrame = vgui.Create( "DFrame", g.frame )
	g.chatFrame:SetPos( 0, 0 )
	g.chatFrame:SetSize( g.size.x, g.size.y )
	g.chatFrame:SetTitle( "" )
	g.chatFrame:SetName("BC_ChatFrame")
	g.chatFrame:ShowCloseButton(false)
	g.chatFrame:SetDraggable(false)
	g.chatFrame:SetSizable(false)
	g.chatFrame:MoveToBack()

	g.chatFrame.Paint = function( self, w, h )
		if not self.doPaint then return end
		chatBox.blur( self, 10, 20, 255 )
		--main box
		draw.RoundedBox( 0, 0, 0, w, h - 33, Color( 30, 30, 30, 200 ) )
		--left text bg
		draw.RoundedBox( 0, 0, h-31, w - 32, 31, Color( 30, 30, 30, 200 ) )
		--left text fg
		draw.RoundedBox( 0, 5, h-26, w-42, 21, Color( 140, 140, 140, 100 ) )
		--right bg
		draw.RoundedBox( 0, w-30, h-31, 30, 31, Color( 30, 30, 30, 200 ) )
		
	end
	g.chatFrame.doPaint = true
	g.chatFrame.Think = function(self)
		if not g.textEntry:HasFocus() and ( (not vgui.GetKeyboardFocus() ) or 
		  (vgui.GetKeyboardFocus():GetName() != "BC_SettingsEntry" and vgui.GetKeyboardFocus():GetName() != "BC_SettingsKeyEntry" ) ) then
			g.textEntry:RequestFocus()
		end
		if chatBox.dragging then
			local x,y = gui.MousePos()
			g.frame:SetPos( x - chatBox.draggingOffset.x, y - chatBox.draggingOffset.y )
			if not input.IsMouseDown(MOUSE_LEFT) then 
				chatBox.dragging = false
			end
		end

		if chatBox.sidePanels then
			for k, v in pairs(chatBox.sidePanels) do
				local g = v.graphics
				if v.isOpen or v.animState > 0 then
					g.pane:Show()
					g.pane:SetKeyboardInputEnabled(true)
					g.pane:SetMouseInputEnabled(true)

				else
					g.pane:Hide()
				end
			end
		end
	end

	g.textEntry = vgui.Create( "DTextEntry", g.chatFrame )
	g.textEntry:SetName("BC_ChatEntry")
	g.textEntry:SetPos( 10, g.size.y - 10 - 16 )
	g.textEntry:SetSize( g.size.x-52, 20 )
	g.textEntry:SetFont(g.font)
	g.textEntry:SetTextColor(Color(255,255,255))
	g.textEntry:SetCursorColor(Color(255,255,255))
	g.textEntry:SetHighlightColor(Color(255,156,0))
	g.textEntry:SetHistoryEnabled(true)
	g.textEntry.Paint = function( panel, w, h )
		surface.SetFont( panel:GetFont() )
		surface.SetTextColor( 100, 100, 100 )
		surface.SetTextPos( 3, 1 )
		surface.DrawText( g.textEntry.bgText )

		panel:DrawTextEntryText( panel:GetTextColor(), panel:GetHighlightColor(), panel:GetCursorColor() )
	end
	g.textEntry.bgText = ""

	g.textEntry.Think = function( self )
		if g.textEntry:IsMultiline() then
			g.textEntry:SetMultiline(false)
		end
	end

	g.textEntry.OnKeyCodeTyped = function(self, code)
		local ctrl = input.IsKeyDown(KEY_LCONTROL) or input.IsKeyDown(KEY_RCONTROL)
		local shift = input.IsKeyDown(KEY_LSHIFT) or input.IsKeyDown(KEY_RSHIFT)
		if code == KEY_ESCAPE then
			return true
		end 
		return hook.Run("BC_KeyCodeTyped", code, ctrl, shift, self)
	end
	g.textEntry.maxCharacters = chatBox.getServerSetting("maxLength")
	g.textEntry.OnTextChanged = function( self )
		if self and self:GetText() then
			if getChatTextLength(self:GetText()) > self.maxCharacters then
				self:SetText(chatBox.shortenChatText(self:GetText(), self.maxCharacters))
				self:SetCaretPos(self.maxCharacters)
				surface.PlaySound("resource/warning.wav")
			end

			local cPos = self:GetCaretPos()
			local txt = string.Replace(self:GetText(), "\n", "\t")
			if txt[1] == "#" then
				txt = "#" .. txt --Seems it removes the first character only if its a hash, so just add another one :)
			end
			self:SetText(txt)
			self:SetCaretPos(cPos)

			local c = chatBox.getActiveChannel()
			if c.hideChatText then
				hook.Run("ChatTextChanged", chatBox.wackyString)
			else
				hook.Run("ChatTextChanged", self:GetText() or "")
			end
		end
	end

	g.textEntry.OnMousePressed = function(self, keyCode)
		if keyCode == MOUSE_LEFT then
			for k, v in pairs(chatBox.graphics.psheet:GetItems()) do
				v.Panel.text:UnselectText()
			end
		end
	end
	hook.Run( "BC_PreInitPanels" )
	hook.Run( "BC_InitPanels" )

	chatBox.dragging = false
	chatBox.draggingOffset = {x=0,y=0}
	chatBox.ready = true

	hook.Run( "BC_PostInitPanels" )

	chatBox.messageChannel(nil, chatBox.colors.yellow, "BetterChat", chatBox.colors.printBlue, " initialisation complete.")

	chatBox.closeChatBox()
end

hook.Add("VGUIMousePressed", "BC_MousePressed", function(self, keyCode)
	if not chatBox.enabled then return end
	if chatBox.isOpen then
		local x,y = inDragCorner()
		if x then
			if keyCode == MOUSE_LEFT then
				chatBox.dragging = true
				chatBox.draggingOffset = {x=x, y=y}
			elseif keyCode == MOUSE_RIGHT then
				chatBox.graphics.frame:SetPos( chatBox.graphics.originalFramePos.x, chatBox.graphics.originalFramePos.y )
			end
		end
	end
end)

hook.Add("PlayerButtonDown", "BC_ButtonDown", function(ply, keyCode)
	if not chatBox.enabled then return end
	if ply != LocalPlayer() then return end
	for k, v in pairs(chatBox.channels) do
		if v.openKey and v.openKey == keyCode then
			chatBox.openChatBox(v.name)
			return 
		end
	end
end)



function chatBox.removeGraphics()
	local g = chatBox.graphics
	if g then
		g.frame:Remove()
	end
end

function inDragCorner()
	local g = chatBox.graphics
	local posX, posY = g.frame:GetPos()
	local tl = {x = posX + getFrom(1, g.chatFrame:GetSize()) - 30, y = posY}
	local br = {x = posX + getFrom(1, g.chatFrame:GetSize()), y = posY + 30}
	local x,y = gui.MousePos()
	if  x > tl.x and x < br.x and y > tl.y and y < br.y then
		return x - posX, y - posY
	end
end

function chatBox.openChatBox( selectedTab )
	if chatBox.isOpen then return end
	selectedTab = selectedTab or "All"

	local chan = chatBox.getAndOpenChannel(selectedTab)
	if not chan then return end
	selectedTab = chan.name

	chatBox.graphics.frame:MakePopup()
	chatBox.graphics.textEntry.maxCharacters = chatBox.getServerSetting("maxLength")

	chatBox.graphics.chatFrame.doPaint = true
	chatBox.graphics.textEntry:Show()
	chatBox.graphics.frame:SetMouseInputEnabled( true )
	chatBox.graphics.frame:SetKeyboardInputEnabled( true )
	chatBox.showPSheet()
	hook.Run( "BC_ShowChat" )

	chatBox.graphics.textEntry:RequestFocus()

	chatBox.focusChannel(selectedTab)

	hook.Run( "StartChat" )
	chatBox.isOpen = true
	net.Start("BC_openChat")
	net.SendToServer()
end

function chatBox.setPlayersOpen(ply, val)
	chatBox.playersOpen[ply] = val
end

function chatBox.closeChatBox()
	if not chatBox.enabled then return end

	CloseDermaMenus()

	chatBox.isOpen = false

	chatBox.dragging = false
	chatBox.graphics.chatFrame.doPaint = false

	chatBox.graphics.textEntry:Hide()
	chatBox.graphics.frame:SetMouseInputEnabled( false )
	chatBox.graphics.frame:SetKeyboardInputEnabled( false )
	gui.EnableScreenClicker(false)
	chatBox.hidePSheet()
	hook.Run( "BC_HideChat" )

	for k, v in pairs(chatBox.sidePanels) do
		chatBox.closeSidePanel(v.name, true)
	end

	hook.Run( "FinishChat" )
	net.Start("BC_closeChat")
	net.SendToServer()

	-- Clear the text entry
	hook.Run( "ChatTextChanged", "" )
end

hook.Add( "Think", "chatBox_Think", function()
	if not chatBox.enabled then return end
	if chatBox.isOpen and gui.IsGameUIVisible() then
		gui.HideGameUI()
	end
end)

hook.Add( "PlayerBindPress", "chatBox_overrideChatbind", function( ply, bind, pressed )
	if not chatBox.enabled then return end
	if not pressed then return end

	local chan = "All"

	if bind == "messagemode" then
	elseif bind == "messagemode2" then
		if chatBox.lastPrivate and chatBox.getSetting("teamOpenPM") then
			chan = chatBox.lastPrivate.name
			chatBox.lastPrivate = nil
		else
			if DarkRP then
				if chatBox.getServerSetting("replaceTeam") then
					local t = chatBox.teamName(LocalPlayer())
					chan = "TeamOverload-"..t
				else
					return true 
				end
			else -- Dont open normal team chat, do nothing to allow for bind
				chan = "Team"
			end
		end
	else
		return
	end

	local succ, err = pcall(function(chan) chatBox.openChatBox( chan ) end, chan )
	if not succ then
		print("Chatbox not initialized, disabling.")
		chatBox.enabled = false
	else
		return true -- Doesn't allow any functions to be called for this bind
	end
end )

hook.Add( "HUDShouldDraw", "chatBox_noMoreDefault", function( name )
	if not chatBox.enabled then return end
	if name == "CHudChat" then
		return false
	end
end )