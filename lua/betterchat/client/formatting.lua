bc.formatting = {}
local f = bc.formatting

function f.formatMessage( ply, text, dead, defaultColor, dontRecolorColon, data )

    text = table.concat( string.Explode( "\t[\t]+", text, true ), "\t" )

    local tab = {}
    defaultColor = defaultColor or bc.defines.colors.white
    data = data or { ply, text, false, dead }

    if dead then
        table.insert( tab, bc.defines.theme.dead )
        table.insert( tab, "*DEAD* " )
    end

    table.insert( tab, { formatter = true, type = "prefix" } )

    if not ply:IsValid() then
        table.insert( tab, bc.defines.theme.server )
        table.insert( tab, "Server" )
    else
        table.insert( tab, {
            formatter = true,
            type = "sender",
            ply = ply
        } )
    end
    table.insert( tab, dontRecolorColon and defaultColor or bc.defines.colors.white )
    table.insert( tab, ": " )
    table.insert( tab, defaultColor )

    local messageTab = f.formatText( text, nil, ply )
    table.Add( tab, messageTab )

    return tab
end

function f.formatText( text, defaultColor, ply )
    local tab = {}

    defaultColor = defaultColor or bc.defines.colors.white

    -- Make ulx commands grey
    if text[1] == "!" and text[2] ~= "!" and bc.settings.getValue( "colorCmds" ) then
        local spacePos = string.find( text, " ", nil, true )
        if not spacePos then spacePos = #text + 1 end
        if spacePos ~= 2 then
            table.insert( tab, bc.defines.theme.commands )
            table.insert( tab, string.sub( text, 0, spacePos - 1 ) )
            table.insert( tab, defaultColor )
            text = string.sub( text, spacePos, -1 )
        end
    end

    tab = f.formatSpecialWords( text, tab, ply )

    tab = f.formatCustomColor( tab, defaultColor, ply )

    -- format links
    if bc.settings.getValue( "clickableLinks" ) then
        tab = f.formatLinks( tab )
    end

    tab = f.formatEmotes( tab )

    tab = f.formatModifiers( tab, ply )

    return tab
end

function f.formatCustomColor( tab, currentColor, ply )
    local out = {}
    local canUse = bc.settings.isAllowed( ply, "bc_color" )
    for k, v in ipairs( tab ) do
        if type( v ) == "string" and canUse then
            local ret
            ret, currentColor = f.formatCustomColorSingle( v, currentColor )
            table.Add( out, ret )
        else
            table.insert( out, v )
        end
    end
    return out
end

local function firstMatch( text, ... )
    local out = {}
    local firstPos = 100000
    local firstIdx = -1
    for k, v in pairs{ ... } do
        local data = { string.find( text, v ) }
        if not data[1] then continue end
        if data[1] < firstPos then
            firstPos = data[1]
            out = data
            firstIdx = k
        end
    end
    return firstIdx, table.remove( out, 1 ), table.remove( out, 1 ), out
end

function f.formatCustomColorSingle( text, currentColor )
    local out = {}
    while true do
        local i, s, e, data = firstMatch( text, "%[#(%x%x)(%x%x)(%x%x)%]", "%[#%]", "%[@([^%]]+)%]" )
        if i == -1 then
            break
        end
        local col
        if i == 1 then
            local r = tonumber( data[1], 16 )
            local g = tonumber( data[2], 16 )
            local b = tonumber( data[3], 16 )
            col = Color( r, g, b )
        elseif i == 2 then
            col = bc.defines.colors.white
        else
            local colName = string.lower( data[1] )
            colName = chatHelper.spaceToCamel( colName )
            col = bc.defines.colors[colName]
            if not col then
                table.insert( out, string.sub( text, 1, e ) )
                text = string.sub( text, e + 1 )
                continue
            end
        end
        currentColor = col
        local preText = string.sub( text, 1, s - 1 )
        text = string.sub( text, e + 1 )
        if #preText > 0 then
            table.insert( out, preText )
        end
        table.insert( out, col )
    end
    if #text > 0 then
        table.insert( out, text )
    end
    return out, currentColor
end

local longEmotePattern = "(\\?)(:[%w_]+:)"

local function pushEmote( tab, str, pattern, padSpace )
    local searchStr = padSpace and " " .. str .. " " or str
    local s, e, slash, name = string.find( searchStr, pattern )
    if not s then return false, str end
    if padSpace then
        e = e - 2
    end
    slash = slash == "\\" -- Make slash into a boolean

    local data = bc.images.emoteLookup.lookup[name]
    if not slash and data then
        table.insert( tab, string.sub( str, 1, s - 1 ) )
        table.insert( tab, {
            formatter = true,
            type = "image",
            sheet = data.sheet,
            idx = data.idx,
            text = name
        } )
        str = string.sub( str, e + 1 )
    else
        table.insert( tab, string.sub( str, 1, s - 1 ) .. name )
        str = string.sub( str, e + 1 )
    end
    return true, str
end

function f.formatEmotes( tab )
    if not bc.images.emoteLookup then
        return tab
    end
    local longEmoted = {}
    for k, v in pairs( tab ) do
        if type( v ) ~= "string" then
            table.insert( longEmoted, v )
            continue
        end
        local str = v
        local success

        while true do
            success, str = pushEmote( longEmoted, str, longEmotePattern )
            if not success then break end
        end
        if #str > 0 then
            table.insert( longEmoted, str )
        end
    end

    if not bc.settings.getValue( "convertEmotes" ) then
        return longEmoted
    end

    local out = longEmoted
    for j, emote in pairs( bc.images.emoteLookup.short ) do
        local tmpOut = {}
        for k, v in pairs( out ) do
            if type( v ) ~= "string" then
                table.insert( tmpOut, v )
                continue
            end
            local str = v
            local success

            local pattern = " (\\?)(" .. string.PatternSafe( emote ) .. ") "
            while true do
                success, str = pushEmote( tmpOut, str, pattern, true )
                if not success then break end
            end
            if #str > 0 then
                table.insert( tmpOut, str )
            end
        end

        out = tmpOut
    end
    return out
end

local function backTrackModifier( tab, state, key )
    if not state[key] then return end
    for k = #tab, 1, -1 do
        local v = tab[k]
        -- Is it a matching modifier
        if not ( istable( v ) and v.formatter and v.type == "decoration" and v.modifierType == key ) then
            continue
        end
        tab[k] = {
            formatter = true,
            type = "text",
            text = v.text
        }
        break
    end
end

local function getPlyModifiers( ply )
    local out = {}
    out.italic = bc.settings.isAllowed( ply, "bc_italics" )
    out.bold = bc.settings.isAllowed( ply, "bc_bold" )
    out.strike = bc.settings.isAllowed( ply, "bc_strike" )
    out.underline = bc.settings.isAllowed( ply, "bc_underline" )
    return out
end

function f.formatModifiers( tab, ply )
    local newTab = {}
    local state = {
        bold = false,
        underline = false,
        strike = false,
        italic = false
    }
    for k, v in pairs( tab ) do
        if type( v ) == "string" then
            local tab = f.formatModifiersSingle( v, state, getPlyModifiers( ply ) )
            table.Add( newTab, tab )
        else
            table.insert( newTab, v )
        end
    end

    for k, v in pairs( state ) do
        backTrackModifier( newTab, state, k )
    end

    table.insert( newTab, {
        formatter = true,
        type = "decoration"
    } )
    return newTab
end

local modifierKeyMap = {
    ["~~"] = "strike",
    ["**"] = "bold",
    ["__"] = "underline",
    ["*"] = "italic"
}

function f.formatModifiersSingle( txt, state, allowed )
    if #table.GetKeys( allowed ) == 0 then return { txt } end
    local out = {}
    local s, e, escape, c1, c2
    local lastTxt = ""
    while true do
        s, e, escape, c1, c2 = string.find( " " .. txt, "([\\]?)([%*_~])(.?)" )
        if not s or lastTxt == txt then break end -- Prevent inf loop if something goes wrong
        lastTxt = txt

        if c2 == "" then -- If no second character (end of line), act as if there is
            e = e + 1
        end

        -- To account for added space at start
        s = s - 1
        e = e - 1
        -- Combine characters into a modifier, adjust e accordingly
        local c = c1
        if c1 == c2 then
            c = c .. c2
            e = e + 1
        end

        local key = modifierKeyMap[c]
        -- Do nothing (but separate out text so it doesn't get parsed twice/infinitely)
        if escape ~= "" or not key or not allowed[key] then
            table.insert( out, string.sub( txt, 1, s - 1 ) .. c )
            txt = string.sub( txt, e )
            continue
        end

        -- Get before and after text
        local preText = string.sub( txt, 1, s - 1 )
        txt = string.sub( txt, e )
        -- Make the decoration modifier
        state[key] = not state[key]
        local elem = {
            formatter = true,
            type = "decoration",
            modifierType = key,
            text = c
        }
        table.Merge( elem, state )
        -- Add everything to out
        if #preText > 0 then
            table.insert( out, preText )
        end
        table.insert( out, elem )
    end
    if #txt > 0 then
        table.insert( out, txt )
    end
    return out
end

function f.formatSpecialWords( text, tab, sender )
    local patterns = {}
    local players = player.GetAll()
    local prePattern = "[ '\"%*_~]"
    local postPatternPly = "[ '\"!%?%*_~s:,]"
    local postPatternCol = "[ '\"!%?%*_~,]"
    for k, v in pairs( players ) do
        table.insert( patterns, prePattern .. v:Nick():lower():PatternSafe() .. postPatternPly )
    end

    local colorNames = table.GetKeys( bc.defines.colors )
    if bc.settings.getValue( "formatColors" ) then
        for k, colorName in ipairs( colorNames ) do
            colorName = chatHelper.camelToSpace( colorName )
            table.insert( patterns, prePattern .. colorName:lower():PatternSafe() .. postPatternCol )
        end
    end
    while true do
        local i, s, e = firstMatch( " " .. text:lower() .. " ", unpack( patterns ) )
        if i == -1 then
            break
        end
        e = e - 2

        local insertVals = {}
        if i <= #players then
            local ply = players[i]
            if ply == LocalPlayer() and sender == LocalPlayer() then
                table.insert( insertVals, { formatter = true, type = "escape" } ) --escape pop from ply name
            end
            table.insert( insertVals, ply )
        else
            local colorName = colorNames[i - #players]
            local col = bc.defines.colors[colorName]
            insertVals = { { formatter = true, type = "text", text = string.sub( text, s, e ), color = col } }
        end
        table.insert( tab, string.sub( text, 1, s - 1 ) )
        table.Add( tab, insertVals )
        text = string.sub( text, e + 1 )
    end
    if #text > 0 then
        table.insert( tab, text )
    end

    return tab
end

function f.formatLinks( tab )
    local newTab = {}
    for k, v in pairs( tab ) do
        if type( v ) == "string" then
            local tab = f.convertLinks( v )
            table.Add( newTab, tab )
        else
            table.insert( newTab, v )
        end
    end
    return newTab
end

function f.convertLinks( v )
    if type( v ) ~= "string" then return { v } end
    local tab = {}
    local lStart, lEnd, url = 0, 0, ""
    while true do
        lStart, lEnd, url = bc.util.getNextUrl( v )
        if not lStart then break end
        local preText = string.sub( v, 0, lStart - 1 )
        local postText = string.sub( v, lEnd + 1 )
        if #preText > 0 then
            table.insert( tab, preText )
        end
        table.insert( tab, {
            formatter = true,
            type = "clickable",
            signal = "Link-" .. url,
            text = url,
            color = bc.defines.theme.links
        } )
        v = postText
    end
    if #v > 0 then
        table.insert( tab, v )
    end
    return tab
end

function f.defaultFormatMessage( ply, text, teamChat, dead, col1, col2, data )
    if data then
        local tab, madeChange = hook.Run( "BC_getDefaultTab", unpack( data ) )
        if tab and madeChange then
            return tab
        end
    end

    local tab = {}
    if dead then
        table.insert( tab, bc.defines.colors.red )
        table.insert( tab, "*DEAD* " )
    end

    if teamChat then
        table.insert( tab, bc.defines.colors.teamGreen )
        table.insert( tab, "(TEAM) " )
    end

    if type( ply ) == "Player" and ply:IsValid() then
        table.insert( tab, GAMEMODE:GetTeamColor( ply ) )
        table.insert( tab, ply )
        table.insert( tab, bc.defines.colors.white )
    elseif type( ply ) == "Entity" and not ply:IsValid() then
        table.insert( tab, bc.defines.colors.printBlue )
        table.insert( tab, "Console" )
        table.insert( tab, bc.defines.colors.white )
    else
        table.insert( tab, col1 )
        table.insert( tab, ply )
        table.insert( tab, col2 )
    end
    table.insert( tab, ": " .. text )

    return tab
end

net.Receive( "BC_sayOverload", function()
    local ply = net.ReadEntity()
    local isTeam = net.ReadBool()
    local isDead = ply and IsValid( ply ) and ( not ply:Alive() )
    local msg = net.ReadString()
    hook.Run( "OnPlayerChat", ply, msg, isTeam, isDead )
end )

local function extractDarkRPPrefix( pre, ply )
    pre = string.Replace( pre, ply:Nick(), "" )
    pre = string.Replace( pre, ply:SteamName(), "" )

    return pre
end

-- Should be OnGamemodeLoaded, but that isn't called in non dedicated servers (single or p2p), so fallback on Initialize
hook.First( { "OnGamemodeLoaded", "Initialize" }, function()
    print( "[BetterChat] Replacing base OnPlayerChat" )
    f.oldOnPlayerChat = f.oldOnPlayerChat or ( GAMEMODE.OnPlayerChat or function() end )
    function GAMEMODE:OnPlayerChat( ply, text, teamChat, dead, pre, col1, col2 )
        if not bc.base.enabled then
            return f.oldOnPlayerChat( GAMEMODE, ply, text, teamChat, dead, pre, col1, col2 )
        end

        local args = { ply, text, teamChat, dead, pre, col1, col2 }

        local maxLen = bc.settings.getServerValue( "maxLength" )
        if #text > maxLen then
            text = string.sub( text, 1, maxLen )
        end

        local plyValid = ply and ply:IsValid()
        if plyValid and bc.sidePanel.players.settings[ply:SteamID()] and bc.sidePanel.players.settings[ply:SteamID()].ignore ~= 0 then return true end

        local tab
        if pre then
            local prefix = extractDarkRPPrefix( pre, ply )
            tab = f.formatMessage( ply, text, false, col2, true, args )
            if #prefix > 0 then
                table.insert( tab, 1, col2 )
                table.insert( tab, 2, prefix )
            end
        else
            tab = f.formatMessage( ply, text, dead )
        end

        bc.channels.message( { ( teamChat and not DarkRP ) and "Team" or "Players", "MsgC" }, unpack( tab ) )

        return true
    end
end )

function f.print( ... )
    local data = { ... }
    local col = bc.defines.colors.white
    for k, v in pairs( data ) do
        if type( v ) == "table" then
            col = v
        elseif ( v == "You" or v == "Yourself" ) and col == bc.defines.colors.ulxYou then
            data[k] = { formatter = true, type = "clickable", signal = "Player-" .. LocalPlayer():SteamID(), text = v }
        else
            local isPly = false
            for i, ply in pairs( player.GetAll() ) do
                if ply:Nick() == v and col == team.GetColor( ply:Team() ) then
                    data[k] = ply
                    isPly = true
                end
            end
            if not isPly then
                local tab = f.convertLinks( v )
                if #tab ~= 1 or tab[1] ~= v then
                    table.remove( data, k )
                    for l = #tab, 1, -1 do
                        table.insert( data, k, tab[l] )
                    end
                end
            end
        end
    end
    if not bc.base.enabled then return end
    for k, v in pairs( bc.channels.channels or {} ) do
        if v.doPrints and not v.replicateAll then
            bc.channels.messageDirect( v.name, unpack( data ) )
        end
    end
end

function f.triggerTick()
    if not bc.settings.getValue( "doTick" ) then return end
    if timer.Exists( "BC_triggerTick" ) then timer.Remove( "BC_triggerTick" ) end
    timer.Create( "BC_triggerTick", 0.05, 1, function()
        chat.PlaySound()
    end )
end

function f.triggerPop()
    if not bc.settings.getValue( "doPop" ) then return end
    if timer.Exists( "BC_triggerTick" ) then timer.Remove( "BC_triggerTick" ) end
    if timer.Exists( "BC_triggerPop" ) then timer.Remove( "BC_triggerPop" ) end
    timer.Create( "BC_triggerPop", 0.05, 1, function()
        f.playPop()
    end )
end

function f.playPop()
    surface.PlaySound( "garrysmod/balloon_pop_cute.wav" )
end
