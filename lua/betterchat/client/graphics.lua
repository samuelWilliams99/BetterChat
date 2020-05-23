bc.graphics = bc.graphics or {}
include( "betterchat/client/sizemove.lua" )

function bc.graphics.build()
    bc.graphics.remove()

    local g = bc.graphics
    g.derma = {}
    local d = g.derma

    g.font = "BC_default"
    g.minSize = { x = 400, y = 250 }

    g.originalSize = { x = 600, y = 300 }
    g.size = table.Copy( bc.data.size or g.originalSize )

    g.originalFramePos = { x = 38, y = ScrH() - g.size.y - 150 }
    local framePos = table.Copy( bc.data.pos or g.originalFramePos )

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
    d.frame:SetPos( framePos.x, framePos.y )
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

            if not bc.base.isOpen then return end

            local mx, my = gui.MousePos()
            -- Work around to hide the chatbox when the client presses escape
            gui.HideGameUI()

            if vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() == "BC_settingsKeyEntry" then
                bc.graphics.derma.textEntry:RequestFocus()
            else
                bc.graphics.derma.textEntry:SetText( "" )
                bc.base.close()
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
        bc.util.blur( self, 10, 20, 255 )
        --main box
        draw.RoundedBox( 0, 0, 0, w, h - 33, bc.defines.theme.background )
        --left text bg
        draw.RoundedBox( 0, 0, h - 31, w - 32, 31, bc.defines.theme.background )
        --left text fg
        local c = bc.channels.getActiveChannel()
        local col = bc.defines.theme.foreground
        if c.textEntryColor then
            col = table.Copy( c.textEntryColor )
            col.a = 100
        end
        draw.RoundedBox( 0, 5, h - 26, w - 42, 21, col )
        --right bg
        draw.RoundedBox( 0, w - 30, h - 31, 30, 31, bc.defines.theme.background )

        --anything else
        hook.Run( "BC_framePaint", self, w, h )

    end
    d.chatFrame.doPaint = true

    local allowedFocus = { "BC_settingsEntry", "BC_settingsKeyEntry", "BC_chatEntry" }
    function d.chatFrame:Think()
        local focusName = vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetName() or ""
        if bc.base.isOpen and not table.HasValue( allowedFocus, focusName ) then
            d.textEntry:RequestFocus()
        end

        bc.sizeMove.think()

        if bc.sidePanel.panels then
            for k, v in pairs( bc.sidePanel.panels ) do
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
    d.textEntry:SetTextColor( bc.defines.theme.inputText )
    d.textEntry:SetCursorColor( bc.defines.theme.inputText )
    d.textEntry:SetHighlightColor( bc.defines.theme.textHighlight )
    d.textEntry:SetHistoryEnabled( true )

    function d.textEntry:PerformLayout()
        self:SetPos( 10, g.size.y - 10 - 16 )
        self:SetSize( g.size.x - 52, 20 )
    end

    function d.textEntry:Paint( w, h )
        surface.SetFont( self:GetFont() )
        surface.SetTextColor( bc.defines.theme.inputSuggestionText )
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
        local ctrl = input.IsKeyDown( KEY_LCONTROL )
        local shift = input.IsKeyDown( KEY_LSHIFT )
        if code == KEY_ESCAPE then
            return true
        end
        return hook.Run( "BC_keyCodeTyped", code, ctrl, shift, self )
    end
    function d.textEntry:OnTextChanged()
        self.maxCharacters = bc.settings.getServerValue( "maxLength" )
        if self and self:GetText() then
            if bc.util.getChatTextLength( self:GetText() ) > self.maxCharacters then
                self:SetText( bc.util.shortenChatText( self:GetText(), self.maxCharacters ) )
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

            local c = bc.channels.getActiveChannel()
            if c.hideChatText then
                hook.Run( "ChatTextChanged", bc.channels.wackyString )
            else
                hook.Run( "ChatTextChanged", self:GetText() or "" )
            end
            hook.Run( "BC_chatTextChanged", self:GetText() or "" )
        end
    end

    function d.textEntry:OnMousePressed( keyCode )
        if keyCode == MOUSE_LEFT then
            for k, v in pairs( bc.graphics.derma.psheet:GetItems() ) do
                v.Panel.text:UnselectText()
            end
        end
    end

    hook.Add( "BC_channelChanged", "BC_disableTextEntry", function()
        local text = bc.graphics.derma.textEntry
        local chan = bc.channels.getActiveChannel()
        if not chan then return end
        text:SetDisabled( chan.noSend )
        text:SetCursor( chan.noSend and "no" or "beam" )
        text:SetTooltip( chan.noSend and "This channel does not allow messages to be sent" or nil )
    end )

    hook.Run( "BC_preInitPanels" )
    hook.Run( "BC_initPanels" )

    bc.base.ready = true

    hook.Run( "BC_postInitPanels" )
end

function bc.graphics.show( selectedTab )
    local d = bc.graphics.derma
    d.frame:MakePopup()
    d.textEntry.maxCharacters = bc.settings.getServerValue( "maxLength" )

    d.chatFrame.doPaint = true
    d.textEntry:Show()
    d.frame:SetMouseInputEnabled( true )
    d.frame:SetKeyboardInputEnabled( true )
    bc.channels.showPSheet()
    hook.Run( "BC_showChat" )

    d.textEntry:RequestFocus()

    bc.channels.focus( selectedTab )
end

function bc.graphics.hide()
    CloseDermaMenus()
    local d = bc.graphics.derma
    d.chatFrame.doPaint = false

    d.textEntry:Hide()
    d.frame:SetMouseInputEnabled( false )
    d.frame:SetKeyboardInputEnabled( false )
    gui.EnableScreenClicker( false )
    bc.channels.hidePSheet()
    hook.Run( "BC_hideChat" )

    for k, v in pairs( bc.sidePanel.panels ) do
        bc.sidePanel.close( v.name, true )
    end
end

hook.Add( "PlayerButtonDown", "BC_buttonDown", function( ply, keyCode )
    if not bc.base.enabled or ply ~= LocalPlayer() then return end

    for k, v in pairs( bc.channels.channels or {} ) do
        if v.openKey and v.openKey == keyCode then
            bc.base.open( v.name )
            return
        end
    end
end )

function bc.graphics.remove()
    local g = bc.graphics
    if g and g.derma and g.derma.frame then
        g.derma.frame:Remove()
    end
end

hook.Add( "Think", "BC_hidePauseMenu", function()
    if not bc.base.enabled then return end
    if bc.base.isOpen and gui.IsGameUIVisible() then
        gui.HideGameUI()
    end
end )

hook.Add( "PlayerBindPress", "BC_overrideChatBind", function( ply, bind, pressed )
    if not bc.base.enabled or not pressed then return end

    local chan = "All"

    if bind == "messagemode2" then
        if bc.private.lastMessaged and bc.settings.getValue( "teamOpenPM" ) then
            chan = bc.private.lastMessaged.name
            bc.private.lastMessaged = nil
        else
            if bc.settings.getServerValue( "replaceTeam" ) then
                local t = chatHelper.teamName( LocalPlayer() )
                chan = "TeamOverload - " .. t
            elseif DarkRP or bc.settings.getServerValue( "removeTeam" ) then
                return true
            else
                chan = "Team"
            end
        end
    elseif bind ~= "messagemode" then
        return
    end

    local succ, err = pcall( function()
        if chan == "Team" and not DarkRP then
            bc.channels.open( "Team" )
        end
        bc.base.open( chan )
    end )
    if not succ then
        print( "Chatbox not initialized, disabling." )
        bc.base.enabled = false
    else
        return true -- Doesn't allow any functions to be called for this bind
    end
end, HOOK_LOW )

hook.Add( "HUDShouldDraw", "BC_hideDefaultChat", function( name )
    if not bc.base.enabled then return end
    if name == "CHudChat" then
        return false
    end
end )
