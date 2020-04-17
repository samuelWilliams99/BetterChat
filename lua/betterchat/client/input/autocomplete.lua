-- Order of function calls is annoying, can't be done by making all functions local
-- just gonna declare all of them here
local setSuggestions, updateText, incOption, setOption, setText, getSimilarStrings,
    getSimilarCommands, getSimilarNames, getSimilarEmotes

net.Receive( "BC_sendULXCommands", function()
    local cmds = util.JSONToTable( net.ReadString() )
    if bc.images.giphyEnabled then
        table.insert( cmds, bc.defines.giphyCommand )
    end
    bc.autoComplete.cmds = bc.autoComplete.cmds or {}
    local newCmds = {}
    for k, v in pairs( cmds ) do
        newCmds[v] = bc.autoComplete.cmds[v] or 0
        bc.autoComplete.cmds[v] = nil
    end
    bc.autoComplete.disabledCmds = bc.autoComplete.cmds
    bc.autoComplete.cmds = newCmds
    bc.autoComplete.emoteUsage = bc.autoComplete.emoteUsage or {}
    bc.autoComplete.gotCommands = true
end )

hook.Add( "BC_hideChat", "BC_removeSuggestions", function()
    setSuggestions()
end )

hook.Add( "BC_initPanels", "BC_initAutoComplete", function()
    bc.autoComplete = bc.autoComplete or {}
    bc.autoComplete.cur = {}
    bc.autoComplete.cur.option = 0
end )

hook.Add( "BC_keyCodeTyped", "BC_autoCompleteHook", function( code, ctrl, shift, entry )
    local txt = entry:GetText()
    if entry:GetCaretPos() ~= #txt then return end
    local txtEx = string.Explode( " ", txt )
    if code == KEY_TAB then
        if not ctrl then
            if #bc.autoComplete.cur.options == 0 then
                local options
                if #txtEx == 1 and txtEx[1][1] == "!" then
                    options = getSimilarCommands( txtEx[1] )
                elseif txtEx[#txtEx][1] == ":" and #txtEx[#txtEx] >= 2 then
                    options = getSimilarEmotes( txtEx[#txtEx] )
                else
                    options = getSimilarNames( txtEx[#txtEx] )
                end
                setSuggestions( txt, options )
            end
            incOption()
        end
    elseif code == KEY_SPACE or code == KEY_ENTER then
        local strCompleted
        local c = bc.autoComplete.cur

        if bc.autoComplete.cur.option ~= 0 then
            strCompleted = c.options[c.option]
        else
            strCompleted = txtEx[#txtEx]
        end

        if txt[1] == "!" and #txtEx == 1 then --Is command
            if bc.autoComplete.cmds[strCompleted] ~= nil then
                bc.autoComplete.cmds[strCompleted] = bc.autoComplete.cmds[strCompleted] + 1
                bc.data.saveData()
            end
        end
    end
end )

hook.Add( "BC_messageSent", "BC_autoCompleteUsageTracker", function( channel, txt )
    local tab = bc.formatting.formatMessage( LocalPlayer(), txt, false )
    local change = false
    for k, v in pairs( tab ) do
        if type( v ) == "table" and v.formatter and v.type == "image" then
            if bc.autoComplete.emoteUsage[v.text] ~= nil then
                bc.autoComplete.emoteUsage[v.text] = bc.autoComplete.emoteUsage[v.text] + 1
                change = true
            end
        end
    end

    setSuggestions()

    if change then
        bc.images.reloadUsedEmotesMenu()
        bc.data.saveData()
    end
end )

hook.Add( "BC_channelChanged", "BC_hideAutocomplete", function()
    hook.Run( "ChatTextChanged", bc.graphics.derma.textEntry:GetText() )
end )

hook.Add( "BC_chatTextChanged", "autoCompletePreview", function( txt )
    if not bc.base.enabled then return end
    local txtEx = string.Explode( " ", txt )
    local options
    if #txtEx == 1 and txtEx[1][1] == "!" then
        options = getSimilarCommands( txtEx[1] )
    elseif #txtEx[#txtEx] > 2 then
        if txtEx[#txtEx][1] == ":" then
            options = getSimilarEmotes( txtEx[#txtEx] )
        else
            options = getSimilarNames( txtEx[#txtEx] )
        end
    else
        setSuggestions()
        return
    end

    setSuggestions( txt, options )
end )

function setSuggestions( text, options )
    if text then
        bc.autoComplete.cur.options = options
        bc.autoComplete.cur.option = 0
        bc.autoComplete.cur.originalText = text
        local split = string.Explode( " ", text )
        bc.autoComplete.cur.word = table.remove( split, #split )
        bc.autoComplete.cur.prefix = table.concat( split, " " ) .. ( #split > 0 and " " or "" )
    else
        bc.autoComplete.cur.options = {}
    end
    updateText()
end

function updateText()
    if not bc.settings.getValue( "acDisplay" ) then return end
    if #bc.autoComplete.cur.options > 0 then
        local c = bc.autoComplete.cur
        local OPTIONS_SHOWN = math.min( 4, #c.options )

        local sIdx = c.option and math.max( c.option, 1 ) or 1
        local options = table.Copy( c.options )
        if c.option == 0 then
            options[1] = c.word .. string.sub( options[1], #c.word + 1, -1 )
        end

        local t = c.prefix .. table.concat( options, "; ", sIdx, math.min( sIdx - 1 + OPTIONS_SHOWN, #c.options ) ) .. "; "
        if c.option ~= 0 then
            t = t .. "... ; "
        end

        if c.option > ( #c.options - OPTIONS_SHOWN + 1 ) then
            t = t .. table.concat( c.options, "; ", 1, OPTIONS_SHOWN - ( #c.options - c.option ) - 1 )
        end
        bc.graphics.derma.textEntry.bgText = t
    else
        bc.graphics.derma.textEntry.bgText = ""
    end

end

function incOption()
    setOption( ( bc.autoComplete.cur.option + 1 ) % ( #bc.autoComplete.cur.options + 1 ) )
end

function setOption( n )
    bc.autoComplete.cur.option = n
    if n == 0 then
        setText( bc.autoComplete.cur.originalText )
    else
        setText( bc.autoComplete.cur.prefix .. bc.autoComplete.cur.options[n] )
    end
    updateText()
end

function setText( txt )
    bc.graphics.derma.textEntry:SetText( txt )
    bc.graphics.derma.textEntry:SetCaretPos( #txt )
end

--takes a string and assiative array, array format
--arr[string/name] = usage --to sort by
function getSimilarStrings( str, arr )
    str = string.lower( str )
    local out = {}
    for k, val in pairs( arr ) do
        local s, _ = string.find( string.lower( val ), str, 1, true )
        if s == 1 then
            table.insert( out, val )
        end
    end

    return out
end

function getSimilarCommands( str )
    local out = getSimilarStrings( str, table.GetKeys( bc.autoComplete.cmds ) )
    table.sort( out, function( a, b )
        if bc.autoComplete.cmds[a] == bc.autoComplete.cmds[b] or not bc.settings.getValue( "acUsage" ) then
            if #a == #b then
                return a < b
            end
            return #a < #b
        end
        return bc.autoComplete.cmds[a] > bc.autoComplete.cmds[b]
    end )
    return out
end

function getSimilarNames( str )
    local names = {}
    for k, ply in pairs( player.GetAll() ) do
        table.insert( names, ply:Nick() )
    end
    return getSimilarStrings( str, names )
end

function getSimilarEmotes( str )
    local out = getSimilarStrings( str, bc.images.emoteLookup.long )

    table.sort( out, function( a, b )
        if bc.autoComplete.emoteUsage[a] == bc.autoComplete.emoteUsage[b] or not bc.settings.getValue( "acUsage" ) then
            if #a == #b then
                return a < b
            end
            return #a < #b
        end
        return bc.autoComplete.emoteUsage[a] > bc.autoComplete.emoteUsage[b]
    end )
    return out
end
