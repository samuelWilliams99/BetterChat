include( "betterchat/client/input/autocomplete.lua" )

hook.Add( "BC_InitPanels", "BC_InitInput", function()
    chatBox.history = {}
    chatBox.historyIndex = 0
    chatBox.historyInput = ""
end )

hook.Add( "BC_KeyCodeTyped", "BC_InputHook", function( code, ctrl, shift, entry )
    if code == KEY_UP then
        if chatBox.historyIndex == 0 then
            chatBox.historyInput = entry:GetText()
        end
        chatBox.historyIndex = math.Min( chatBox.historyIndex + 1, #chatBox.history )
        if chatBox.historyIndex ~= 0 then
            entry:SetText( chatBox.history[( #chatBox.history + 1 ) - chatBox.historyIndex] )
            entry:SetCaretPos( #entry:GetText() )
        end
        return true
    elseif code == KEY_DOWN then
        if chatBox.historyIndex == 0 then
            return true
        end
        chatBox.historyIndex = math.Max( chatBox.historyIndex - 1, 0 )
        if chatBox.historyIndex ~= 0 then
            entry:SetText( chatBox.history[( #chatBox.history + 1 ) - chatBox.historyIndex] )
            entry:SetCaretPos( #entry:GetText() )
        else
            entry:SetText( chatBox.historyInput )
            entry:SetCaretPos( #entry:GetText() )
        end
        return true
    elseif code == KEY_C then
        if ctrl then
            local txt = hook.Run( "RICHERTEXT:CopyText" )
            if txt then
                SetClipboardText( txt )
                return true
            end
        end
    elseif code == KEY_V then
        if ctrl then
            entry:SetMultiline( true )
        end
    elseif code == KEY_BACKSPACE and ctrl then
        local cPos = entry:GetCaretPos() + 1
        local txt = entry:GetText()
        if shift then
            entry:SetText( string.sub( txt, cPos, #txt ) )
        else
            local preTxt = string.TrimRight( string.sub( entry:GetText(), 1, cPos - 1 ) )

            local spacePos = 0

            for k = 1, math.min( cPos, #preTxt ) do
                if txt[k] == " " then
                    spacePos = k
                end
            end
            entry:SetText( string.sub( preTxt, 1, spacePos ) .. string.sub( txt, cPos, #txt ) )
            entry:SetCaretPos( spacePos )
        end
        return true
    end
    
end )

hook.Add( "BC_MessageCanSend", "BC_RunConsoleCommand", function( channel, txt )
    if chatBox.getSetting( "allowConsole" ) then
        if txt and txt[1] == "%" then
            local cmd = txt:sub( 2 )
            if not cmd or #cmd == 0 then return true end
            LocalPlayer():ConCommand( cmd )
            return true
        end
    end
    if chatBox.giphyEnabled and string.sub( txt, 1, 7 ) == "!giphy " then
        local str = string.sub( txt, 8 )
        net.Start( "BC_SendGif" )
        net.WriteString( str )
        net.WriteString( channel.name == "All" and "Players" or channel.name )
        net.SendToServer()
    end
end )

hook.Add( "BC_MessageSent", "BC_RelayULX", function( channel, txt )
    if channel.runCommandSeparately and txt[1] == "!" then
        net.Start( "BC_forwardMessage" )
        net.WriteString( txt )
        net.SendToServer()
    end
end )