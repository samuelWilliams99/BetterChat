chatBox = chatBox or {}
chatBox.consolePlayer = { isConsole = true } -- some unique table to pass around
chatBox.channelTypes = { 
    GLOBAL = 1, 
    TEAM = 2, 
    PRIVATE = 3, 
    ADMIN = 4, 
    GROUP = 5
}

--[[
naming convention
all vars/functions camel
always full names
hookIds: BC_camelCase
eventNames: BC_camelCase


code cleanup
do hook/function checkup in sidepanel
make admin + logs code look nicer
change how settings are loaded, so you dont need to check everywhere if they need data
    dataChanged should be rare
egrep:
    BC_[A-Z]
    warnings on whitespace fixer, speaking of:
theres fukin spaces after "{ \n"
retest url, complex pattern stuff may have gotten fukt by script
rename every function by its location, e.g. chatBox.isColor -> chatBox.util.isColor

ctrt+w for close tab

make players closable

joining after bots
	[ERROR] addons/betterchat/lua/betterchat/client/sidepanel/panels/players.lua:30: attempt to call method 'SteamID' (a nil value)
  1. fn - addons/betterchat/lua/betterchat/client/sidepanel/panels/players.lua:30
   2. func - addons/ulib-master/lua/ulib/client/cl_util.lua:22
    3. unknown - lua/includes/extensions/net.lua:32



	logs channel - implement with a ulx permission, ulx bc_seechatlogs

	chat cooldown - sounds like a fair bit of work, especially when other addons already do it
		maybe call onchat with generic ply/message to trigger it?

	resize/move
		double right click on thing in corner requires mouse movement ????
		preferable change hand to sizeall when hovering
		some button to enable moving/resizing, as a mode
			panel over top of the whole chat, removes issue with cursor as panel will be only focused thing
			gray the panel a bit and pop an icon in the middle?

		scroll bar on side panels not updating -- this is a problem, idk how fix
			could just not show chat when resizing/moving
			enter kinda like an edit hud mode, where no gui are actually rendered, just shitty boxes

	test darkrp - l o l


]]

if SERVER then
    --includes
    include( "betterchat/server/sv_manager.lua" )

    local networkStrings = { 
        "BC_chatOpenState", "BC_sendPlayerState", "BC_playerReady", "BC_disable", -- Chat states
        "BC_PM", "BC_AM", "BC_GM", "BC_TM", "BC_LM", -- Messages (Private, Admin, Group, Team)
        "BC_sendULXCommands", "BC_userRankChange", -- Ulx
        "BC_sendGroups", "BC_updateGroup", "BC_newGroup", "BC_groupAccept", "BC_leaveGroup", "BC_deleteGroup", -- Groups
        "BC_forwardMessage", "BC_sayOverload", "BC_sendGif", "BC_playerDisconnected", -- Misc
    }

    for k, v in pairs( networkStrings ) do
        util.AddNetworkString( v )
    end

    function chatBox.getEnabledPlayers()
        local out = {}
        for k, v in pairs( player.GetAll() ) do
            if chatBox.chatBoxEnabled[v] then
                table.insert( out, v )
            end
        end
        return out
    end

    chatBox.chatBoxEnabled = {}

    net.Receive( "BC_chatOpenState", function( len, ply )
        ULib.clientRPC( nil, "chatBox.setPlayersOpen", ply, net.ReadBool() )
    end )

    net.Receive( "BC_forwardMessage", function( len, ply )
        hook.Run( "PlayerSay", ply, net.ReadString(), true )
    end )

    hook.Add( "PlayerInitialSpawn", "BC_playerSpawn", function( ply )
        local plys = chatBox.getEnabledPlayers()

        ULib.clientRPC( plys, "chatBox.generatePlayerPanelEntry", ply )
        ULib.clientRPC( plys, "hook.Run", "BC_playerConnect", ply )

        if chatBox.giphy.enabled then
            ULib.clientRPC( ply, "chatBox.enableGiphy" )
        end
        
        -- Haven't got my name anywhere in this chat, so heres my lil credit :)
        -- Just a cheeky lil welcome message for me
        if ply:SteamID() == "STEAM_0:1:46658202" then
            timer.Simple( 2, function()
                ULib.clientRPC( plys, "chatBox.messageChannel", "All", chatBox.colors.printBlue, "Yay! ", ply, "'s here!" )
            end )
        end

    end )

    hook.Add( "PlayerDisconnected", "BC_plyLeave", function( ply )
        chatBox.chatBoxEnabled[ply] = false
        local plys = chatBox.getEnabledPlayers()
        table.RemoveByValue( plys, ply )

        ULib.clientRPC( plys, "chatBox.removePlayerPanel", ply:SteamID() )
        ULib.clientRPC( plys, "hook.Run", "BC_playerDisconnect", ply:SteamID() )
    end )

    net.Receive( "BC_plyReady", function( len, ply ) --can now send data to ply
        chatBox.chatBoxEnabled[ply] = true
        hook.Run( "BC_plyReady", ply )

    end )

    net.Receive( "BC_disable", function( len, ply )
        chatBox.chatBoxEnabled[ply] = false
    end )


end

include( "betterchat/shared/sh_util.lua" )
include( "betterchat/shared/sh_globalsettings.lua" )
include( "betterchat/shared/sh_helper.lua" )
hook.Run( "BC_sharedInit" )
if SERVER then 
    return
end

--includes
include( "betterchat/client/chat.lua" )
include( "betterchat/client/overload.lua" )
include( "betterchat/client/datamanager.lua" )
include( "betterchat/client/images.lua" )
include( "betterchat/client/compatibility.lua" )
include( "betterchat/client/channels/channels.lua" )
include( "betterchat/client/sidepanel/sidepanel.lua" )
include( "betterchat/client/input/input.lua" )
--panels
include( "betterchat/client/vguipanels/davatarimagerounded.lua" )
include( "betterchat/client/vguipanels/dnicescrollpanel.lua" )
include( "betterchat/client/vguipanels/drichertext.lua" )

concommand.Add( "bc_enable", function()
    if chatBox.enabled then
        chatBox.disableChatBox()
    end
    chatBox.enableChatBox()
end, true, "Enables BetterChat" )

concommand.Add( "bc_reload", function()
    if chatBox.enabled then
        chatBox.disableChatBox()
    end
    timer.Simple( 0.1, function() -- Delay to allow save
        include( "betterChat/sh_base.lua" )
        chatBox.enableChatBox()
    end )
end, true, "Rebuilds the new chat box" )

concommand.Add( "bc_savedata", chatBox.saveData, true, "Saves all chat data to file" )

concommand.Add( "bc_disable", function()
    if chatBox.enabled then
        chatBox.closeChatBox()
        chatBox.disableChatBox()
    end
    chat.AddText( chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "has been disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
end )

concommand.Add( "bc_restart", function()
    if chatBox.enabled then
        chatBox.closeChatBox()
        chatBox.disableChatBox()
    end
    chatBox.enableChatBox()
end )

concommand.Add( "bc_removesavedata", function()
    chatBox.deleteSaveData()
    if chatBox.enabled then
        chatBox.closeChatBox()
        chatBox.disableChatBox( true )
        chatBox.enableChatBox()
    end
    chat.AddText( chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "data has been deleted." )
end )


if chatBox and chatBox.graphics and chatBox.graphics.frame then 
    chatBox.graphics.frame:Remove()    
end

chatBox.enabled = true
chatBox.ready = false
chatBox.playersOpen = {}

chatBox.channels = {}
chatBox.lastPrivate = nil
chatBox.openChannels = {}

hook.Add( "InitPostEntity", "BC_loaded", function()
    chatBox.loadEnabled()
    if chatBox.enabled then
        chatBox.buildBox()
        net.Start( "BC_playerReady" )
        net.SendToServer()
        chatBox.loadData()
    else
        chat.AddText( chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "is currently disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
    end
end )

chatBox.validatePlayerSettings()

function chatBox.enableChatBox()
    chatBox.enabled = true
    chatBox.buildBox()
    net.Start( "BC_playerReady" )
    net.SendToServer()

    chatBox.loadData()
    chatBox.enabled = true
    chatBox.saveEnabled()
end

function chatBox.disableChatBox( noSave )
    chatBox.enabled = false
    if not noSave then
        chatBox.saveData()
    end
    if chatBox.overloaded then
        chatBox.returnFunctions()
    end
    chatBox.removeGraphics()
    chatBox.autoComplete = nil
    chatBox.channels = nil

    net.Start( "BC_disable" )
    net.SendToServer()
end

function chatBox.resizeBox( w, h, final )
    local g = chatBox.graphics

    g.size = { x = w, y = h }
    g.originalFramePos = { x = 38, y = ScrH() - g.size.y - 150 }

    g.frame:SetSize( g.size.x + ( chatBox.sidePanelWidth or 0 ), g.size.y + 40 ) --Added 40 for AutoComplete

    -- Seems some things don't update until mouseover, trigger them here instead
    if g.adminButton then 
        g.adminButton:InvalidateLayout()
    end
    if g.groupButton then 
        g.groupButton:InvalidateLayout()
    end

    g.chatFrame:InvalidateLayout()
    g.psheet:InvalidateLayout()
    g.emojiButton:InvalidateLayout()
    g.textEntry:InvalidateLayout()

    for k, v in pairs( chatBox.channelPanels ) do
        if not IsValid( v.panel ) then continue end
        v.panel:InvalidateLayout( true )
        v.text:InvalidateLayout( true )
        if final then
            v.text:Reload()
        end
    end

    for k, v in pairs( chatBox.sidePanels ) do
        local g = v.graphics
        g.pane:InvalidateLayout( true )
        g.frame:InvalidateLayout( true )
        for _, data in pairs( g.panels ) do
            data.Panel:InvalidateLayout( true )
        end
    end
    
end

function chatBox.buildBox()
    chatBox.initializing = true
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
    g.font = "BC_default"
    g.minSize = { x = 400, y = 250 }
    g.originalSize = { x = 550, y = 301 }
    g.size = table.Copy( g.originalSize )
    g.originalFramePos = { x = 38, y = ScrH() - g.size.y - 150 }

    g.visCheck = timer.Create( "BC_visCheck", 1 / 60, 0, function()
        if not g.frame or not g.frame:IsValid() then
            timer.Destroy( "BC_visCheck" )
            return
        end
        if gui.IsGameUIVisible() then
            g.frame:Hide()
        else
            if not g.frame:IsVisible() then
                g.frame:Show()
            end
        end
    end )

    g.frame = vgui.Create( "DFrame" )
    g.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
    g.frame:SetSize( g.size.x, g.size.y + 40 ) --Added 40 for AutoComplete
    g.frame:SetTitle( "" )
    g.frame:SetName( "BC_chatFrame" )
    g.frame:ShowCloseButton( false )
    g.frame:SetDraggable( false )
    g.frame:SetSizable( false )
    g.frame.Paint = nil
    g.frame.EscapeDown = false
    g.frame.Think = function( self )
        if input.IsKeyDown( KEY_ESCAPE ) then
            if self.EscapeDown then return end
            self.EscapeDown = true

            if not chatBox.isOpen then return end

            local mx, my = gui.MousePos()
            -- Work around to hide the chatbox when the client presses escape
            gui.HideGameUI()

            if vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() == "BC_settingsKeyEntry" then
                chatBox.graphics.textEntry:RequestFocus()
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
    g.chatFrame:SetName( "BC_innerChatFrame" )
    g.chatFrame:ShowCloseButton( false )
    g.chatFrame:SetDraggable( false )
    g.chatFrame:SetSizable( false )
    g.chatFrame:MoveToBack()

    function g.chatFrame:PerformLayout()
        self:SetSize( g.size.x, g.size.y )
    end

    g.chatFrame.Paint = function( self, w, h )
        if not self.doPaint then return end
        chatBox.blur( self, 10, 20, 255 )
        --main box
        draw.RoundedBox( 0, 0, 0, w, h - 33, Color( 30, 30, 30, 200 ) )
        --left text bg
        draw.RoundedBox( 0, 0, h - 31, w - 32, 31, Color( 30, 30, 30, 200 ) )
        --left text fg
        local c = chatBox.getActiveChannel()
        local col = Color( 140, 140, 140, 100 )
        if c.textEntryColor then
            col = c.textEntryColor
            col.a = 100
        end
        draw.RoundedBox( 0, 5, h - 26, w - 42, 21, col )
        --right bg
        draw.RoundedBox( 0, w - 30, h - 31, 30, 31, Color( 30, 30, 30, 200 ) )
        
    end
    g.chatFrame.doPaint = true
    g.chatFrame.Think = function( self )
        if not g.textEntry:HasFocus() and ( ( not vgui.GetKeyboardFocus() ) or 
        ( vgui.GetKeyboardFocus():GetName() ~= "BC_settingsEntry" and vgui.GetKeyboardFocus():GetName() ~= "BC_settingsKeyEntry" ) ) then
            g.textEntry:RequestFocus()
        end
        if chatBox.dragging then
            local x, y = gui.MousePos()
            g.frame:SetPos( x - chatBox.draggingOffset.x, y - chatBox.draggingOffset.y )
            if not input.IsMouseDown( MOUSE_LEFT ) then 
                chatBox.dragging = false
            end
            self.cursor = "hand"
        elseif chatBox.resizing then
            local x, y = gui.MousePos()
            local px, py = g.frame:GetPos()
            local d = chatBox.resizingData
            local w, h = g.size.x, g.size.y
            local doMove = false
            if d.type == 0 then
                w = d.originalRight - x
                w = math.Max( w, g.minSize.x )
                px = d.originalRight - w
                doMove = true
            elseif d.type == 1 then
                h = d.originalBottom - y
                h = math.Max( h, g.minSize.y )
                py = d.originalBottom - h
                doMove = true
            elseif d.type == 2 then
                w = x - px
                w = math.Max( w, g.minSize.x )
            else
                h = y - py
                h = math.Max( h, g.minSize.y )
            end
            local final = not input.IsMouseDown( MOUSE_LEFT )
            if doMove then
                g.frame:SetPos( px, py )
            end
            chatBox.resizeBox( w, h, final )
            if final then
                chatBox.resizing = false
            end
            self.cursor = "sizeall"
        else

        end

        if chatBox.sidePanels then
            for k, v in pairs( chatBox.sidePanels ) do
                local g = v.graphics
                if v.isOpen or v.animState > 0 then
                    g.pane:Show()
                    g.pane:SetKeyboardInputEnabled( true )
                    g.pane:SetMouseInputEnabled( true )
                else
                    g.pane:Hide()
                end
            end
        end
    end

    g.textEntry = vgui.Create( "DTextEntry", g.chatFrame )
    g.textEntry:SetName( "BC_chatEntry" )
    g.textEntry:SetPos( 10, g.size.y - 10 - 16 )
    g.textEntry:SetSize( g.size.x - 52, 20 )
    g.textEntry:SetFont( g.font )
    g.textEntry:SetTextColor( Color( 255, 255, 255 ) )
    g.textEntry:SetCursorColor( Color( 255, 255, 255 ) )
    g.textEntry:SetHighlightColor( Color( 255, 156, 0 ) )
    g.textEntry:SetHistoryEnabled( true )

    function g.textEntry:PerformLayout()
        self:SetPos( 10, g.size.y - 10 - 16 )
        self:SetSize( g.size.x - 52, 20 )
    end

    g.textEntry.Paint = function( panel, w, h )
        surface.SetFont( panel:GetFont() )
        surface.SetTextColor( 130, 130, 130 )
        surface.SetTextPos( 3, -1 )
        surface.DrawText( g.textEntry.bgText )

        panel:DrawTextEntryText( panel:GetTextColor(), panel:GetHighlightColor(), panel:GetCursorColor() )
    end
    g.textEntry.bgText = ""

    g.textEntry.Think = function( self )
        if g.textEntry:IsMultiline() then
            g.textEntry:SetMultiline( false )
        end
    end

    g.textEntry.OnKeyCodeTyped = function( self, code )
        local ctrl = input.IsKeyDown( KEY_LCONTROL ) or input.IsKeyDown( KEY_RCONTROL )
        local shift = input.IsKeyDown( KEY_LSHIFT ) or input.IsKeyDown( KEY_RSHIFT )
        if code == KEY_ESCAPE then
            return true
        end 
        return hook.Run( "BC_keyCodeTyped", code, ctrl, shift, self )
    end
    g.textEntry.OnTextChanged = function( self )
        self.maxCharacters = chatBox.getServerSetting( "maxLength" )
        if self and self:GetText() then
            if getChatTextLength( self:GetText() ) > self.maxCharacters then
                self:SetText( chatBox.shortenChatText( self:GetText(), self.maxCharacters ) )
                self:SetCaretPos( self.maxCharacters )
                surface.PlaySound( "resource/warning.wav" )
            end

            local cPos = self:GetCaretPos()
            local txt = string.Replace( self:GetText(), "\n", "\t" )
            if txt[1] == "#" then
                txt = "#" .. txt --Seems it removes the first character only if its a hash, so just add another one :)
            end
            self:SetText( txt )
            self:SetCaretPos( cPos )

            local c = chatBox.getActiveChannel()
            if c.hideChatText then
                hook.Run( "ChatTextChanged", chatBox.wackyString )
            else
                hook.Run( "ChatTextChanged", self:GetText() or "" )
            end
            hook.Run( "BC_chatTextChanged", self:GetText() or "" )
        end
    end

    g.textEntry.OnMousePressed = function( self, keyCode )
        if keyCode == MOUSE_LEFT then
            for k, v in pairs( chatBox.graphics.psheet:GetItems() ) do
                v.Panel.text:UnselectText()
            end
        end
    end

    hook.Add( "BC_channelChanged", "BC_disableTextEntry", function()
        local text = chatBox.graphics.textEntry
        local chan = chatBox.getActiveChannel()
        if not chan then return end
        text:SetDisabled( chan.noSend )
        text:SetTooltip( chan.noSend and "This channel does not allow messages to be sent" or nil )
    end )

    hook.Run( "BC_preInitPanels" )
    hook.Run( "BC_initPanels" )

    chatBox.dragging = false
    chatBox.draggingOffset = { x = 0, y = 0 }
    chatBox.ready = true

    hook.Run( "BC_postInitPanels" )

    -- Wait for other prints
    timer.Simple( 0, function()
        chatBox.messageChannel( nil, chatBox.colors.yellow, "BetterChat", chatBox.colors.printBlue, " initialisation complete." )
    end )

    chatBox.initializing = false

    chatBox.closeChatBox()
end

hook.Add( "VGUIMousePressed", "BC_mousePressed", function( self, keyCode )
    if not chatBox.enabled then return end
    if chatBox.isOpen then
        local g = chatBox.graphics
        local x, y = inDragCorner( g.frame )
        if x then
            if keyCode == MOUSE_LEFT then
                chatBox.dragging = true
                chatBox.draggingOffset = { x = x, y = y }
            elseif keyCode == MOUSE_RIGHT then
                local t = SysTime()
                local diff = t - ( chatBox.lastRClick or 0 )
                if diff < 0.5 then
                    chatBox.resizeBox( g.originalSize.x, g.originalSize.y, true )
                    g.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
                else
                    g.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
                end
                chatBox.lastRClick = t
            end
            return
        end

        local edge = inResizeEdge( g.frame )
        if edge then
            chatBox.resizing = true
            chatBox.resizingData = { 
                originalRight = getFrom( 1, g.frame:GetPos() ) + g.size.x, 
                originalBottom = getFrom( 2, g.frame:GetPos() ) + g.size.y, 
                type = edge
            }
        end
    end
end )

hook.Add( "PlayerButtonDown", "BC_buttonDown", function( ply, keyCode )
    if not chatBox.enabled then return end
    if ply ~= LocalPlayer() then return end
    for k, v in pairs( chatBox.channels ) do
        if v.openKey and v.openKey == keyCode then
            chatBox.openChatBox( v.name )
            return 
        end
    end
end )



function chatBox.removeGraphics()
    local g = chatBox.graphics
    if g then
        g.frame:Remove()
    end
end

function inDragCorner( elem )
    local g = chatBox.graphics
    local x, y = elem:LocalCursorPos()
    local w, h = g.size.x, g.size.y

    if x < 0 or y < 0 or x > w or y > h then
        return
    end

    if x > w - 30 and y < 30 then
        return x, y
    end
end

function inResizeEdge( elem )
    local g = chatBox.graphics
    local x, y = elem:LocalCursorPos()
    local w, h = g.size.x, g.size.y

    if x < 0 or y < 0 or x > w or y > h then
        return
    end
    local edgeSize = 6
    if x < edgeSize then
        return 0
    elseif y < edgeSize then
        return 1
    elseif x > ( w - edgeSize ) then
        return 2
    elseif y > ( h - edgeSize ) then
        return 3
    end
end

function chatBox.openChatBox( selectedTab )
    if chatBox.isOpen then return end
    chatBox.overloadedFuncs.oldClose()
    selectedTab = selectedTab or "All"

    if selectedTab == "All" and chatBox.getSetting( "rememberChannel" ) then
        if chatBox.lastChannel then
            selectedTab = chatBox.lastChannel
        end
    end

    local chan = chatBox.getAndOpenChannel( selectedTab )
    if not chan then return end
    selectedTab = chan.name

    chatBox.graphics.frame:MakePopup()
    chatBox.graphics.textEntry.maxCharacters = chatBox.getServerSetting( "maxLength" )

    chatBox.graphics.chatFrame.doPaint = true
    chatBox.graphics.textEntry:Show()
    chatBox.graphics.frame:SetMouseInputEnabled( true )
    chatBox.graphics.frame:SetKeyboardInputEnabled( true )
    chatBox.showPSheet()
    hook.Run( "BC_showChat" )

    chatBox.graphics.textEntry:RequestFocus()

    chatBox.focusChannel( selectedTab )

    hook.Run( "StartChat" )
    chatBox.isOpen = true
    net.Start( "BC_chatOpenState" )
    net.WriteBool( true )
    net.SendToServer()
end

function chatBox.setPlayersOpen( ply, val )
    chatBox.playersOpen[ply] = val
end

function chatBox.closeChatBox()
    if not chatBox.enabled then return end

    chatBox.lastChannel = chatBox.getActiveChannel().name

    chatBox.overloadedFuncs.oldClose()
    CloseDermaMenus()

    chatBox.isOpen = false

    chatBox.dragging = false
    chatBox.graphics.chatFrame.doPaint = false

    chatBox.graphics.textEntry:Hide()
    chatBox.graphics.frame:SetMouseInputEnabled( false )
    chatBox.graphics.frame:SetKeyboardInputEnabled( false )
    gui.EnableScreenClicker( false )
    chatBox.hidePSheet()
    hook.Run( "BC_hideChat" )

    for k, v in pairs( chatBox.sidePanels ) do
        chatBox.closeSidePanel( v.name, true )
    end

    hook.Run( "FinishChat" )
    net.Start( "BC_chatOpenState" )
    net.WriteBool( false )
    net.SendToServer()

    -- Clear the text entry
    hook.Run( "ChatTextChanged", "" )
end

hook.Add( "Think", "BC_hidePauseMenu", function()
    if not chatBox.enabled then return end
    if chatBox.isOpen and gui.IsGameUIVisible() then
        gui.HideGameUI()
    end
end )

hook.Add( "PlayerBindPress", "BC_overrideChatBind", function( ply, bind, pressed )
    if not chatBox.enabled then return end
    if not pressed then return end

    local chan = "All"

    if bind == "messagemode2" then
        if chatBox.lastPrivate and chatBox.getSetting( "teamOpenPM" ) then
            chan = chatBox.lastPrivate.name
            chatBox.lastPrivate = nil
        else
            if DarkRP then
                if chatBox.getServerSetting( "replaceTeam" ) then
                    local t = chatBox.teamName( LocalPlayer() )
                    chan = "TeamOverload-" .. t
                else
                    return true 
                end
            else -- Dont open normal team chat, do nothing to allow for bind
                chan = "Team"
            end
        end
    elseif bind ~= "messagemode" then
        return
    end

    local succ, err = pcall( function( chan ) chatBox.openChatBox( chan ) end, chan )
    if not succ then
        print( "Chatbox not initialized, disabling." )
        chatBox.enabled = false
    else
        return true -- Doesn't allow any functions to be called for this bind
    end
end )

hook.Add( "HUDShouldDraw", "BC_hideDefaultChat", function( name )
    if not chatBox.enabled then return end
    if name == "CHudChat" then
        return false
    end
end )