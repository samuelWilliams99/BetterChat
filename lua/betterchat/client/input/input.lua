bc.input = {}
local i = bc.input
include( "betterchat/client/input/autocomplete.lua" )

hook.Add( "BC_initPanels", "BC_initInput", function()
    i.history = {}
    i.historyIndex = 0
    i.historyInput = ""
end )

hook.Add( "BC_keyCodeTyped", "BC_inputHook", function( code, ctrl, shift, entry )
    local txt = entry:GetText()
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
        elseif code == KEY_LEFT or code == KEY_RIGHT then
            if #txt == 0 then return true end

            local isLeft = code == KEY_LEFT
            local cPos = entry:GetCaretPos()
            local changeBy = isLeft and -1 or 1
            local endValue = isLeft and 0 or utf8.len( txt )

            if cPos == endValue then return true end

            local bytePos = utf8.offset( txt, isLeft and cPos - 1 or cPos ) or #txt + 1
            local seenNonSpace = txt[bytePos] and txt[bytePos] ~= " "

            repeat
                cPos = cPos + changeBy
                bytePos = utf8.offset( txt, cPos ) or #txt + 1

                if txt[bytePos] == " " then
                    if seenNonSpace then
                        break
                    end
                else
                    seenNonSpace = true
                end
            until cPos == endValue

            if isLeft and cPos ~= 0 then
                cPos = cPos + 1
            end

            entry:SetCaretPos( cPos )

            return true
        end
    end

end )

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
