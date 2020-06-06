bc.input = bc.input or {}
local i = bc.input
include( "betterchat/client/input/autocomplete.lua" )

i.modifierOrder = {
    "italics",
    "bold",
    "strike",
    "underline",
    "rainbow",
    "pulsing",
    "shaking",
    "spaced",
}

hook.Add( "BC_initPanels", "BC_initInput", function()
    i.history = {}
    i.historyIndex = 0
    i.historyInput = ""

    local g = bc.graphics
    local d = g.derma

    i.fMenu = vgui.Create( "DPanel", d.frame )
    i.fMenu:SetSize( 0, g.textEntryHeight )
    function i.fMenu:Paint( w, h )
        bc.util.blur( self, 10, 20, 255 )
        draw.RoundedBox( 0, 0, 0, w, h, bc.defines.theme.background )
    end
    function i.fMenu:PerformLayout()
        self:SetPos( 0, g.size.y + 2 )
    end
    i.fMenu:Hide()

    i.fButton = vgui.Create( "DButton", d.chatFrame )
    i.fButton:SetText( "?" )
    i.fButton:SetFont( g.textEntryFont )
    i.fButton:SetTextColor( bc.defines.theme.buttonTextFocused )
    i.fButton.Paint = nil
    i.fButton:SizeToContents()
    i.fButton:Hide()
    function i.fButton:DoClick()
        i.toggleFormattingMenu()
    end
    function i.fButton:PerformLayout()
        self:SetPos( g.size.x - 52, g.size.y - g.textEntryHeight + 3 )
    end

    i.inverseModifierKeyMap = {}
    for k, v in pairs( bc.formatting.modifierKeyMap ) do
        i.inverseModifierKeyMap[v] = k
    end

    i.updateFormattingButton()
end )

hook.Add( "BC_hideChat", "BC_hideFMenu", function()
    i.hideFormattingMenu()
    i.fButton:Hide()
end )

hook.Add( "BC_showChat", "bc_showFButton", function()
    if i.fButton.enabled then
        i.fButton:Show()
    end
end )

hook.Add( "BC_keyCodeTyped", "BC_inputHook", function( code, ctrl, shift, entry )
    local txt = entry:GetText()
    if i.isFormattingMenuShowing() then
        if code == KEY_RIGHT then
            i.incFMenuSelected()
            return true
        elseif code == KEY_LEFT then
            i.decFMenuSelected()
            return true
        elseif code == KEY_SPACE or code == KEY_ENTER then
            i.applyFMenuSelected( code == KEY_SPACE )
            return true
        elseif code >= KEY_0 and code <= KEY_9 then
            local num = code - KEY_0
            if num <= 0 or num > #i.fMenu:GetChildren() then
                local textEntry = bc.graphics.derma.textEntry

                textEntry.rejectNextChange = true
                i.hideFormattingMenu()

                return true
            end

            i.applyFMenuValue( num, true )
            return true
        elseif bc.settings.getValue( "formattingCloseOnType" ) and code ~= KEY_LCONTROL and not ctrl then
            i.hideFormattingMenu()
        end
    end

    if code == KEY_UP then
        if i.historyIndex == 0 then
            i.historyInput = txt
        end
        i.historyIndex = math.Min( i.historyIndex + 1, #i.history )
        if i.historyIndex ~= 0 then
            entry:SetText( i.history[( #i.history + 1 ) - i.historyIndex] )
            entry:SetCaretPos( utf8.len( entry:GetText() ) )
        end
        return true
    elseif code == KEY_DOWN then
        if i.historyIndex == 0 then
            return true
        end

        i.historyIndex = math.Max( i.historyIndex - 1, 0 )
        if i.historyIndex ~= 0 then
            entry:SetText( i.history[( #i.history + 1 ) - i.historyIndex] )
        else
            entry:SetText( i.historyInput )
        end

        entry:SetCaretPos( utf8.len( entry:GetText() ) )

        return true
    elseif ctrl then
        if code == KEY_BACKSPACE then
            local cPos

            if #txt == 0 then
                cPos = 1
            else
                cPos = utf8.offset( txt, entry:GetCaretPos() ) or #txt + 1
            end

            if shift then
                entry:SetText( string.sub( txt, cPos ) )
            else
                local preTxt = string.TrimRight( string.sub( entry:GetText(), 1, cPos - 1 ) )

                local spacePos = 0


                for k = 1, math.min( cPos, #preTxt ) do
                    if txt[k] == " " then
                        spacePos = k
                    end
                end

                local preText = string.sub( preTxt, 1, spacePos )
                entry:SetText( preText .. string.sub( txt, cPos ) )
                entry:SetCaretPos( utf8.len( preText ) )
            end
            return true
        elseif code == KEY_C then
            local copiedText = hook.Run( "RICHERTEXT:CopyText" )
            if copiedText then
                SetClipboardText( copiedText )
                return true
            end
        elseif code == KEY_V then
            entry:SetMultiline( true )
        elseif code == KEY_F then
            i.toggleFormattingMenu()
            return true
        end
    end

end, HOOK_HIGH )

hook.Add( "BC_messageCanSend", "BC_runConsoleCommand", function( channel, txt )
    if bc.settings.getValue( "allowConsole" ) and string.Left( txt or "", 2 ) == "##" then
        local cmd = txt:sub( 3 )
        if not cmd or #cmd == 0 then return true end

        bc.channels.messageDirect( channel, bc.defines.theme.commands, "> ", cmd )

        LocalPlayer():ConCommand( cmd )
        return true
    end

    local giphyCommand = bc.defines.giphyCommand
    if bc.images.giphyEnabled and string.sub( txt, 1, #giphyCommand + 1 ) == giphyCommand .. " " then
        local str = string.sub( txt, 8 )
        net.Start( "BC_sendGif" )
        net.WriteString( str )
        net.WriteString( channel.name == "All" and "Players" or channel.name )
        net.SendToServer()
    end
end )

hook.Add( "BC_messageSent", "BC_relayULX", function( channel, txt )
    if channel.runCommandSeparately and txt[1] == "!" then
        net.Start( "BC_forwardMessage" )
        net.WriteString( txt )
        net.SendToServer()
    end
end )


function i.updateFormattingButton()
    local allowedData = i.getAllowedModifierData()

    local visible = #table.GetKeys( allowedData ) > 0
    i.fButton:SetVisible( visible )
    i.fButton.enabled = visible
end

hook.Add( "BC_userAccessChange", "BC_updateFormattingButton", i.updateFormattingButton )

function i.isFormattingMenuShowing()
    return i.fMenuShowing
end

function i.toggleFormattingMenu()
    if i.isFormattingMenuShowing() then
        i.hideFormattingMenu()
    else
        i.showFormattingMenu()
    end
end

function i.showFormattingMenu()
    if i.fMenuShowing then return end
    i.fMenuShowing = true
    i.fMenuSelected = 1

    i.fMenu:Clear()
    local totalWide = 0
    local allowedData = i.getAllowedModifierData()

    if #table.GetKeys( allowedData ) == 0 then return end

    for k, d in pairs( allowedData ) do
        local label = vgui.Create( "DLabelPaintable", i.fMenu )
        label:Dock( LEFT )
        label:DockMargin( 5, 5, 0, 5 )
        label:SetText( d.example )
        label:SetFont( bc.graphics.textEntryFont )
        label:SizeToContents( 6, 0 )
        label:SetBackgroundColor( bc.defines.theme.foreground )
        label:SetCursor( "hand" )
        label.selected = k == i.fMenuSelected
        label.modIndex = k
        label.modStrPre = d.modStrPre
        label.modStrPost = d.modStrPost
        label.caretOverride = d.caretOverride

        function label:Paint( w, h )
            surface.SetDrawColor( self.selected and bc.defines.theme.foregroundLight or self:GetBackgroundColor() )
            surface.DrawRect( 0, 0, w, h )
            local y = ( h - bc.graphics.textEntryFontHeight ) / 2
            draw.DrawText( self._text, self:GetFont(), 3, y - 1, self:GetTextColor() )
        end

        function label:OnMousePressed( btn )
            if btn == MOUSE_LEFT then
                i.applyFMenuValue( self.modIndex )
            end
        end

        label:InvalidateLayout( true )
        totalWide = totalWide + label:GetWide() + 5
    end
    i.fMenu:SetWide( totalWide + 5 )

    i.fMenu:Show()
end

function i.setFMenuSelected( val )
    if not i.fMenuShowing then return end
    i.fMenuSelected = val

    for k, label in pairs( i.fMenu:GetChildren() ) do
        label.selected = k == val
    end
end

function i.getFMenuSelected()
    return i.fMenuSelected
end

function i.incFMenuSelected()
    local cur = i.getFMenuSelected()
    local total = #i.fMenu:GetChildren()
    i.setFMenuSelected( ( cur % total ) + 1 )
end

function i.decFMenuSelected()
    local cur = i.getFMenuSelected()
    local total = #i.fMenu:GetChildren()
    if cur == 1 then cur = total + 1 end
    i.setFMenuSelected( cur - 1 )
end

function i.applyFMenuValue( val, rejectNextChange )
    if not i.fMenuShowing then return end
    local elem = i.fMenu:GetChildren()[val]
    local modPre = elem.modStrPre
    local modPost = elem.modStrPost

    local textEntry = bc.graphics.derma.textEntry

    textEntry.rejectNextChange = rejectNextChange

    local text = textEntry:GetText()
    local curPos = textEntry:GetCaretPos()
    local s, e = textEntry:GetSelectedTextRange()

    local selectText = ""
    if s ~= e or s ~= 0 then
        local startBPos = utf8.offset( text, s ) or 1
        local endBPos = ( utf8.offset( text, e ) or #text + 1 ) - 1
        selectText = string.sub( text, startBPos, endBPos )
    else
        s = curPos
    end

    local bPos = utf8.offset( text, s ) or #text + 1
    local pre, post = string.sub( text, 1, bPos - 1 ), string.sub( text, bPos + #selectText )
    text = pre .. modPre .. selectText .. modPost .. post

    textEntry:SetText( text )

    local caretPos = curPos + utf8.len( modPre )
    if elem.caretOverride then
        caretPos = s + elem.caretOverride
    end
    textEntry:SetCaretPos( caretPos )

    i.hideFormattingMenu()
end

function i.applyFMenuSelected( rejectNextChange )
    i.applyFMenuValue( i.getFMenuSelected(), rejectNextChange )
end

function i.hideFormattingMenu()
    if not i.fMenuShowing then return end
    i.fMenuShowing = false

    i.fMenu:Hide()
end

function i.getAllowedModifierData()
    local f = bc.formatting
    local out = {}
    local allowedModifiers = f.getPlyModifiers( LocalPlayer() )

    for k, mod in pairs( i.modifierOrder ) do
        local allowed = allowedModifiers[mod]
        if not allowed then continue end

        local example = i.inverseModifierKeyMap[mod] .. mod .. i.inverseModifierKeyMap[mod]
        table.insert( out, {
            example = example,
            modStrPre = i.inverseModifierKeyMap[mod],
            modStrPost = i.inverseModifierKeyMap[mod]
        } )
    end

    if bc.settings.isAllowed( LocalPlayer(), "bc_color" ) then
        table.insert( out, {
            example = "[@color]text[#]",
            modStrPre = "[@]",
            modStrPost = "[#]",
            caretOverride = 2,
        } )
    end

    return out
end
