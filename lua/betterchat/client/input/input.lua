bc.input = {}
local i = bc.input
include( "betterchat/client/input/autocomplete.lua" )

hook.Add( "BC_initPanels", "BC_initInput", function()
    i.history = {}
    i.historyIndex = 0
    i.historyInput = ""
end )

hook.Add( "BC_keyCodeTyped", "BC_inputHook", function( code, ctrl, shift, entry )
    if code == KEY_UP then
        if i.historyIndex == 0 then
            i.historyInput = entry:GetText()
        end
        i.historyIndex = math.Min( i.historyIndex + 1, #i.history )
        if i.historyIndex ~= 0 then
            entry:SetText( i.history[( #i.history + 1 ) - i.historyIndex] )
            entry:SetCaretPos( #entry:GetText() )
        end
        return true
    elseif code == KEY_DOWN then
        if i.historyIndex == 0 then
            return true
        end
        i.historyIndex = math.Max( i.historyIndex - 1, 0 )
        if i.historyIndex ~= 0 then
            entry:SetText( i.history[( #i.history + 1 ) - i.historyIndex] )
            entry:SetCaretPos( #entry:GetText() )
        else
            entry:SetText( i.historyInput )
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

hook.Add( "BC_messageCanSend", "BC_runConsoleCommand", function( channel, txt )
    if bc.settings.getValue( "allowConsole" ) then
        if txt and txt[1] == "%" then
            local cmd = txt:sub( 2 )
            if not cmd or #cmd == 0 then return true end
            LocalPlayer():ConCommand( cmd )
            return true
        end
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
