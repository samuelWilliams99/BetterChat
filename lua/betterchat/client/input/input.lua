bc.input = {}
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

    i.fMenu = vgui.Create( "DPanel", bc.graphics.derma.frame )
    i.fMenu:SetSize( 0, bc.graphics.textEntryHeight )
    i.fMenu:SetPos( 0, bc.graphics.size.y + 2 )
    function i.fMenu:Paint( w, h )
        bc.util.blur( self, 10, 20, 255 )
        draw.RoundedBox( 0, 0, 0, w, h, bc.defines.theme.background )
    end
    i.fMenu:Hide()

    i.inverseModifierKeyMap = {}
    for k, v in pairs( bc.formatting.modifierKeyMap ) do
        i.inverseModifierKeyMap[v] = k
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
        else
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
    for k, d in pairs( allowedData ) do
        local label = vgui.Create( "DLabelPaintable", i.fMenu )
        label:Dock( LEFT )
        label:DockMargin( 5, 5, 0, 5 )
        label:SetText( d.example )
        label:SetFont( bc.graphics.textEntryFont )
        label:SizeToContents( 6, 0 )
        label:SetBackgroundColor( bc.defines.theme.foreground )
        label.selected = k == i.fMenuSelected
        label.modStr = d.modStr
        function label:Paint( w, h )
            surface.SetDrawColor( self.selected and bc.defines.theme.foregroundLight or self:GetBackgroundColor() )
            surface.DrawRect( 0, 0, w, h )
            local y = ( h - bc.graphics.textEntryFontHeight ) / 2
            draw.DrawText( self._text, self:GetFont(), 3, y - 1, self:GetTextColor() )
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

function i.applyFMenuSelected( rejectNextChange )
    if not i.fMenuShowing then return end
    local str = i.fMenu:GetChildren()[i.getFMenuSelected()].modStr

    local textEntry = bc.graphics.derma.textEntry

    textEntry.rejectNextChange = rejectNextChange

    local text = undoChanges and textEntry.prevText or textEntry:GetText()
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
    text = pre .. str .. selectText .. str .. post

    textEntry:SetText( text )
    textEntry:SetCaretPos( curPos + utf8.len( str ) )

    i.hideFormattingMenu()
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
            modStr = i.inverseModifierKeyMap[mod]
        } )
    end

    return out
end
