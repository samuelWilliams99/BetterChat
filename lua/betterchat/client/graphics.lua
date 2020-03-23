-- Delete if already defined, for development
if chatBox.graphics and chatBox.graphics.remove then
    chatBox.graphics.remove()
end
chatBox.graphics = {}
include( "betterchat/client/sizemove.lua" )

function chatBox.graphics.build()
    chatBox.graphics.remove()

    local g = chatBox.graphics
    g.derma = {}
    local d = g.derma

    g.font = "BC_default"
    g.minSize = { x = 400, y = 250 }
    g.originalSize = { x = 550, y = 301 }
    g.size = table.Copy( g.originalSize )
    g.originalFramePos = { x = 38, y = ScrH() - g.size.y - 150 }

    timer.Create( "BC_visCheck", 1 / 60, 0, function()
        if not d.frame or not d.frame:IsValid() then
            timer.Remove( "BC_visCheck" )
            return
        end
        if gui.IsGameUIVisible() then
            d.frame:Hide()
        elseif not d.frame:IsVisible() then
            d.frame:Show()
        end
    end )

    d.frame = vgui.Create( "DFrame" )
    d.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
    d.frame:SetSize( g.size.x, g.size.y )
    d.frame:SetTitle( "" )
    d.frame:SetName( "BC_chatFrame" )
    d.frame:ShowCloseButton( false )
    d.frame:SetDraggable( false )
    d.frame:SetSizable( false )
    d.frame.Paint = nil
    d.frame.EscapeDown = false
    function d.frame:Think()
        if input.IsKeyDown( KEY_ESCAPE ) then
            if self.EscapeDown then return end
            self.EscapeDown = true

            if not chatBox.base.isOpen then return end

            local mx, my = gui.MousePos()
            -- Work around to hide the chatbox when the client presses escape
            gui.HideGameUI()

            if vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() == "BC_settingsKeyEntry" then
                chatBox.graphics.derma.textEntry:RequestFocus()
            else
                chatBox.graphics.derma.textEntry:SetText( "" )
                chatBox.base.closeChatBox()
            end
        else
            self.EscapeDown = false
        end
    end

    d.chatFrame = vgui.Create( "DFrame", d.frame )
    d.chatFrame:SetPos( 0, 0 )
    d.chatFrame:SetSize( g.size.x, g.size.y )
    d.chatFrame:SetTitle( "" )
    d.chatFrame:SetName( "BC_innerChatFrame" )
    d.chatFrame:ShowCloseButton( false )
    d.chatFrame:SetDraggable( false )
    d.chatFrame:SetSizable( false )
    d.chatFrame:MoveToBack()

    function d.chatFrame:PerformLayout()
        self:SetSize( g.size.x, g.size.y )
    end

    function d.chatFrame:Paint( w, h )
        if not self.doPaint then return end
        chatBox.util.blur( self, 10, 20, 255 )
        --main box
        draw.RoundedBox( 0, 0, 0, w, h - 33, chatBox.defines.theme.background )
        --left text bg
        draw.RoundedBox( 0, 0, h - 31, w - 32, 31, chatBox.defines.theme.background )
        --left text fg
        local c = chatBox.channels.getActiveChannel()
        local col = chatBox.defines.theme.foreground
        if c.textEntryColor then
            col = table.Copy( c.textEntryColor )
            col.a = 100
        end
        draw.RoundedBox( 0, 5, h - 26, w - 42, 21, col )
        --right bg
        draw.RoundedBox( 0, w - 30, h - 31, 30, 31, chatBox.defines.theme.background )

    end
    d.chatFrame.doPaint = true

    local allowedFocus = { "BC_settingsEntry", "BC_settingsKeyEntry", "BC_chatEntry" }
    function d.chatFrame:Think()
        local focusName = vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() or ""
        if chatBox.base.isOpen and not table.HasValue( allowedFocus, focusName ) then
            d.textEntry:RequestFocus()
        end

        chatBox.sizeMove.think()

        if chatBox.sidePanel.panels then
            for k, v in pairs( chatBox.sidePanel.panels ) do
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

    d.textEntry = vgui.Create( "DTextEntry", d.chatFrame )
    d.textEntry:SetName( "BC_chatEntry" )
    d.textEntry:SetPos( 10, g.size.y - 10 - 16 )
    d.textEntry:SetSize( g.size.x - 52, 20 )
    d.textEntry:SetFont( g.font )
    d.textEntry:SetTextColor( chatBox.defines.theme.inputText )
    d.textEntry:SetCursorColor( chatBox.defines.theme.inputText )
    d.textEntry:SetHighlightColor( chatBox.defines.theme.textHighlight )
    d.textEntry:SetHistoryEnabled( true )

    function d.textEntry:PerformLayout()
        self:SetPos( 10, g.size.y - 10 - 16 )
        self:SetSize( g.size.x - 52, 20 )
    end

    function d.textEntry:Paint( w, h )
        surface.SetFont( self:GetFont() )
        surface.SetTextColor( chatBox.defines.theme.inputSuggestionText )
        surface.SetTextPos( 3, -1 )
        surface.DrawText( d.textEntry.bgText )

        self:DrawTextEntryText( self:GetTextColor(), self:GetHighlightColor(), self:GetCursorColor() )
    end
    d.textEntry.bgText = ""

    function d.textEntry:Think()
        if d.textEntry:IsMultiline() then
            d.textEntry:SetMultiline( false )
        end
    end

    function d.textEntry:OnKeyCodeTyped( code )
        local ctrl = input.IsKeyDown( KEY_LCONTROL ) or input.IsKeyDown( KEY_RCONTROL )
        local shift = input.IsKeyDown( KEY_LSHIFT ) or input.IsKeyDown( KEY_RSHIFT )
        if code == KEY_ESCAPE then
            return true
        end
        return hook.Run( "BC_keyCodeTyped", code, ctrl, shift, self )
    end
    function d.textEntry:OnTextChanged()
        self.maxCharacters = chatBox.settings.getServerValue( "maxLength" )
        if self and self:GetText() then
            if chatBox.util.getChatTextLength( self:GetText() ) > self.maxCharacters then
                self:SetText( chatBox.util.shortenChatText( self:GetText(), self.maxCharacters ) )
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

            local c = chatBox.channels.getActiveChannel()
            if c.hideChatText then
                hook.Run( "ChatTextChanged", chatBox.channels.wackyString )
            else
                hook.Run( "ChatTextChanged", self:GetText() or "" )
            end
            hook.Run( "BC_chatTextChanged", self:GetText() or "" )
        end
    end

    function d.textEntry:OnMousePressed( keyCode )
        if keyCode == MOUSE_LEFT then
            for k, v in pairs( chatBox.graphics.derma.psheet:GetItems() ) do
                v.Panel.text:UnselectText()
            end
        end
    end

    hook.Add( "BC_channelChanged", "BC_disableTextEntry", function()
        local text = chatBox.graphics.derma.textEntry
        local chan = chatBox.channels.getActiveChannel()
        if not chan then return end
        text:SetDisabled( chan.noSend )
        text:SetTooltip( chan.noSend and "This channel does not allow messages to be sent" or nil )
    end )

    hook.Run( "BC_preInitPanels" )
    hook.Run( "BC_initPanels" )

    chatBox.base.ready = true

    hook.Run( "BC_postInitPanels" )
end

function chatBox.graphics.show( selectedTab )
    local d = chatBox.graphics.derma
    d.frame:MakePopup()
    d.textEntry.maxCharacters = chatBox.settings.getServerValue( "maxLength" )

    d.chatFrame.doPaint = true
    d.textEntry:Show()
    d.frame:SetMouseInputEnabled( true )
    d.frame:SetKeyboardInputEnabled( true )
    chatBox.channels.showPSheet()
    hook.Run( "BC_showChat" )

    d.textEntry:RequestFocus()

    chatBox.channels.focus( selectedTab )
end

function chatBox.graphics.hide()
    CloseDermaMenus()
    local d = chatBox.graphics.derma
    d.chatFrame.doPaint = false

    d.textEntry:Hide()
    d.frame:SetMouseInputEnabled( false )
    d.frame:SetKeyboardInputEnabled( false )
    gui.EnableScreenClicker( false )
    chatBox.channels.hidePSheet()
    hook.Run( "BC_hideChat" )

    for k, v in pairs( chatBox.sidePanel.panels ) do
        chatBox.sidePanel.close( v.name, true )
    end
end

hook.Add( "PlayerButtonDown", "BC_buttonDown", function( ply, keyCode )
    if not chatBox.base.enabled or ply ~= LocalPlayer() then return end

    for k, v in pairs( chatBox.channels.channels ) do
        if v.openKey and v.openKey == keyCode then
            chatBox.base.openChatBox( v.name )
            return
        end
    end
end )

function chatBox.graphics.remove()
    local g = chatBox.graphics
    if g and g.derma and g.derma.frame then
        g.derma.frame:Remove()
    end
end

hook.Add( "Think", "BC_hidePauseMenu", function()
    if not chatBox.base.enabled then return end
    if chatBox.base.isOpen and gui.IsGameUIVisible() then
        gui.HideGameUI()
    end
end )

hook.Add( "PlayerBindPress", "BC_overrideChatBind", function( ply, bind, pressed )
    if not chatBox.base.enabled or not pressed then return end

    local chan = "All"

    if bind == "messagemode2" then
        if chatBox.private.lastMessaged and chatBox.settings.getValue( "teamOpenPM" ) then
            chan = chatBox.private.lastMessaged.name
            chatBox.private.lastMessaged = nil
        else
            if DarkRP then
                if chatBox.settings.getServerValue( "replaceTeam" ) then
                    local t = chatHelper.teamName( LocalPlayer() )
                    chan = "TeamOverload-" .. t
                else
                    return true
                end
            else
                chan = "Team"
            end
        end
    elseif bind ~= "messagemode" then
        return
    end

    local succ, err = pcall( function( chan ) chatBox.base.openChatBox( chan ) end, chan )
    if not succ then
        print( "Chatbox not initialized, disabling." )
        chatBox.base.enabled = false
    else
        return true -- Doesn't allow any functions to be called for this bind
    end
end )

hook.Add( "HUDShouldDraw", "BC_hideDefaultChat", function( name )
    if not chatBox.base.enabled then return end
    if name == "CHudChat" then
        return false
    end
end )
