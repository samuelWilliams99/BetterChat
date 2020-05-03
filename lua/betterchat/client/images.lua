bc.images = {}

local function cleanPanel( panel, w, h, padding )
    panel:SetSize( w - padding * 2 - 2, h - padding * 2 - 20 )

    local bar = panel:GetVBar()
    bar.Paint = nil
    bar.btnUp.Paint = nil
    bar.btnDown.Paint = nil
    function bar.btnGrip:Paint( w, h )
        surface.SetDrawColor( bc.defines.theme.emoteAccent )
        surface.DrawRect( w - 2, 0, 2, h )
    end
    bar:SetWidth( 5 )
end

local function cleanTab( data, first )
    local tab = data.Tab
    tab.first = first
    function tab:Paint( w, h )
        local a = self:IsActive()
        local bgCol = a and bc.defines.gray( 230 ) or bc.defines.gray( 210 )
        surface.SetDrawColor( bgCol )
        surface.DrawRect( 0, 0, w, h )

        if a and self.selectProg < 100 then self.selectProg = self.selectProg + 2.5 end
        if not a and self.selectProg > 0 then self.selectProg = self.selectProg - 2.5 end
        self.selectProg = math.Clamp( self.selectProg, 0, 100 )

        surface.SetDrawColor( bc.defines.theme.emoteAccent )
        local p = self.selectProg / 100
        if self.first then
            surface.DrawRect( ( 1 - p ) * w, h - 2, p * w, 2 )
        else
            surface.DrawRect( 0, h - 2, p * w, 2 )
        end

    end
    tab.selectProg = first and 100 or 0
    tab:SetContentAlignment( 5 )
    -- Something else calls the setter, so the only way to override permanently is with this
    function tab:GetTabHeight()
        return 20
    end

    tab:SetTextColor( bc.defines.colors.black )

    function tab:ApplySchemeSettings()
        local w, h = self:GetContentSize()
        h = self:GetTabHeight()

        local xI, _ = self:GetTextInset()
        self:SetTextInset( xI, 0 )
        self:SetSize( 72, h )

        DLabel.ApplySchemeSettings( self )
    end
    return data
end

hook.Add( "BC_initPanels", "BC_initImages", function()
    bc.images.emoteSheets = {}
    local files, _ = file.Find( "materials/spritesheets/*.vmt", "GAME" )

    for k, v in pairs( files ) do
        local name = string.Left( v, #v - 4 )
        local jsonName = "materials/spritesheets/" .. name
        local found = false
        if file.Exists( jsonName .. ".png", "GAME" ) then
            found = true
            jsonName = jsonName .. ".png"
        elseif file.Exists( jsonName .. ".json", "GAME" ) then
            found = true
            jsonName = jsonName .. ".json"
        end

        if found then
            local data = util.JSONToTable( file.Read( jsonName, "GAME" ) )
            if not data then
                MsgC( bc.defines.colors.red, "[BetterChat] Sprite sheet descriptor \"" .. v .. "\" contains invalid json!\n" )
                continue
            end
            data.path = "spritesheets/" .. v
            table.insert( bc.images.emoteSheets, data )
            MsgC( bc.defines.colors.green, "[BetterChat] Added SpriteSheet \"" .. v .. "\".\n" )
        else
            MsgC( bc.defines.colors.orange, "[BetterChat] Found SpriteSheet \"" .. v .. "\" but no \"" .. name .. ".json\", ignoring.\n" )
        end
    end
    bc.images.generateSpriteLookups()

    local g = bc.graphics
    local d = g.derma

    local emoteBtn = vgui.Create( "DImageButton", d.chatFrame )
    emoteBtn:SetSize( 20, 20 )
    emoteBtn:SetMaterial( bc.defines.materials.emoteButton )
    emoteBtn:SetPos( g.size.x - 25, g.size.y - 25 )
    emoteBtn:SetIsMenu( true )
    function emoteBtn:OnMousePressed()
        bc.images.toggleEmoteMenu()
    end
    local oldLayout = emoteBtn.PerformLayout
    function emoteBtn:PerformLayout()
        self:SetSize( 20, 20 )
        self:SetPos( g.size.x - 25, g.size.y - 25 )
        oldLayout( self )
    end
    d.emoteButton = emoteBtn


    local mw, mh = 150, 150
    local emoteMenu = vgui.Create( "DPanel", d.chatFrame )
    emoteMenu:SetSize( mw, mh )
    emoteMenu:MoveToFront()
    emoteMenu:Hide()
    emoteMenu:SetIsMenu( true )
    function emoteMenu:GetDeleteSelf()
        return false
    end
    function emoteMenu:Paint( w, h )
        surface.SetDrawColor( bc.defines.gray( 190 ) )
        surface.DrawRect( 0, 0, w, h )
    end
    d.emoteMenu = emoteMenu

    local uPanel = vgui.Create( "DScrollPanel" )
    local aPanel = vgui.Create( "DScrollPanel" )

    local ePSheet = vgui.Create( "DPropertySheet", emoteMenu )

    local padding = 3

    ePSheet:DockMargin( 0, 3, 0, 0 )
    ePSheet:Dock( FILL )
    ePSheet.Paint = nil
    ePSheet:SetPadding( padding )
    ePSheet.tabScroller:SetOverlap( 0 )

    cleanTab( ePSheet:AddSheet( "Most Used", uPanel, nil, false, false, "Most used Emotes" ), true ) -- Sets anim as focused
    cleanTab( ePSheet:AddSheet( "All", aPanel, nil, false, false, "All available Emotes" ) )

    cleanPanel( uPanel, mw, mh, padding )
    cleanPanel( aPanel, mw, mh, padding )

    local usedEmotes, usage = bc.images.getUsedEmotes()
    bc.images.addEmotesToPanel( uPanel, usedEmotes, usage )

    local allEmotes = bc.images.getAllEmotes()
    bc.images.addEmotesToPanel( aPanel, allEmotes )

    d.emotePSheet = ePSheet
    d.emoteUsedPanel = uPanel
    d.emoteAllPanel = aPanel
end )

hook.Add( "BC_showChat", "BC_showEmoteButton", function() bc.graphics.derma.emoteButton:Show() end )
hook.Add( "BC_hideChat", "BC_hideEmoteButton", function()
    bc.graphics.derma.emoteButton:Hide()
    bc.graphics.derma.emoteMenu:Hide()
end )

hook.Add( "BC_keyCodeTyped", "BC_emoteShortCutHook", function( code, ctrl, shift )
    if ctrl and code == KEY_E then
        bc.images.toggleEmoteMenu()
    elseif bc.graphics.derma.emoteMenu:IsVisible() then
        if code >= KEY_1 and code <= KEY_9 and ctrl then
            local idx = code - KEY_1 + 1
            local p = bc.graphics.derma.emotePSheet:GetActiveTab():GetPanel()
            local emote = p.emotes[idx]
            if not emote then return true end

            local entry = bc.graphics.derma.textEntry
            local txt = entry:GetText()
            local cPos = entry:GetCaretPos()

            local newTxt = string.sub( txt, 0, cPos ) .. emote .. string.sub( txt, cPos + 1 )
            local newCPos = cPos + #emote

            entry:SetText( newTxt )
            entry:SetCaretPos( newCPos )
            return true
        elseif code == KEY_TAB and ctrl then
            local psheet = bc.graphics.derma.emotePSheet
            local tabs = psheet:GetItems()
            local emoteMode = psheet:GetActiveTab()


            if tabs[1].Tab == emoteMode then
                psheet:SetActiveTab( tabs[2].Tab )
            else
                psheet:SetActiveTab( tabs[1].Tab )
            end
            return true
        end
    end
end )

function bc.images.reloadUsedEmotesMenu()
    local uPanel = bc.graphics.derma.emoteUsedPanel
    uPanel:Clear()
    local usedEmotes, usage = bc.images.getUsedEmotes()
    bc.images.addEmotesToPanel( uPanel, usedEmotes, usage )
end

function bc.images.getUsedEmotes()
    bc.autoComplete.emoteUsage = bc.autoComplete.emoteUsage or {}
    local totalUsage = {}
    for str, val in pairs( bc.autoComplete.emoteUsage ) do
        if val == 0 then continue end

        local d = bc.images.emoteLookup.lookup[str]
        if not d then continue end

        local name = d.sheet.sprites[d.idx].name
        totalUsage[name] = totalUsage[name] or 0
        totalUsage[name] = totalUsage[name] + val
    end
    local out = table.GetKeys( totalUsage )
    table.sort( out, function( a, b )
        return totalUsage[a] > totalUsage[b]
    end )

    return out, totalUsage
end

function bc.images.getAllEmotes()
    local out = {}
    for k, sheet in pairs( bc.images.emoteSheets ) do
        for k1, sprite in pairs( sheet.sprites ) do
            table.insert( out, sprite.name )
        end
    end

    return out
end

function bc.images.addEmotesToPanel( panel, data, usage )
    local gw = 6
    local gridSize = panel:GetWide() / gw
    local padding = ( ( gridSize ) - 20 ) / 2
    panel.emotes = {}
    for k = 1, #data do
        local str = data[k]
        local sprite = bc.images.emoteLookup.lookup[":" .. str .. ":"]

        local g = bc.images.createEmote( sprite )
        g:SetParent( panel )

        local x = ( k - 1 ) % gw
        local y = math.floor( ( k - 1 ) / gw )

        g:SetPos( padding + ( x * gridSize ), padding + ( y * gridSize ) )


        local toolTip = ":" .. str .. ":"
        if usage then
            toolTip = toolTip .. " | Used " .. usage[str] .. " time"
            if usage[str] ~= 1 then toolTip = toolTip .. "s" end
        end
        g:SetTooltip( toolTip )

        g.str = ":" .. str .. ":"

        table.insert( panel.emotes, g.str )

        g:SetCursor( "hand" )
        function g:OnMousePressed( t )
            if t == MOUSE_LEFT then
                local entry = bc.graphics.derma.textEntry
                local txt = entry:GetText()
                local cPos = entry:GetCaretPos()

                local newTxt = string.sub( txt, 0, cPos ) .. self.str .. string.sub( txt, cPos + 1 )
                if #newTxt > entry.maxCharacters then
                    surface.PlaySound( "resource/warning.wav" )
                    return
                end
                local newCPos = cPos + #self.str

                entry:SetText( newTxt )
                entry:SetCaretPos( newCPos )
            end
        end
    end
end

function bc.images.createEmote( obj )
    local g = vgui.Create( "DRicherTextGraphic" )
    g:SetType( "image" )
    g:SetSize( 20, 20 )
    g:SetPath( obj.sheet.path )
    local im = obj.sheet.sprites[obj.idx]
    g:SetSubImage( im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )
    return g
end

function bc.images.addEmote( richText, obj )
    local im = obj.sheet.sprites[obj.idx]
    richText:AddImage( obj.sheet.path, obj.text, 1, 1, im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )
end

function bc.images.addGif( richText, obj )
    richText:InsertClickableTextStart( "Link-" .. obj.url )
    richText:AddGif( obj.url, obj.text .. "\n", 5, 5 )
    richText:InsertClickableTextEnd()
end

function bc.images.toggleEmoteMenu()
    local g = bc.graphics
    local d = g.derma

    local isOpen = d.emoteMenu:IsVisible()
    if isOpen then
        d.emoteMenu:Hide()
    else
        local x, y = d.frame:GetPos()
        d.emoteMenu:SetPos( x + g.size.x, y + g.size.y - 150 )
        d.emoteMenu:Show()
        RegisterDermaMenuForClose( d.emoteMenu )
        d.emoteMenu:MakePopup()
        d.emoteMenu:SetKeyboardInputEnabled( false )
    end
end

function bc.images.generateSpriteLookups()
    local lookup = {}
    local short = {}
    local long = {}

    bc.autoComplete = bc.autoComplete or {}
    bc.autoComplete.emoteUsage = bc.autoComplete.emoteUsage or {}
    local usage = bc.autoComplete.emoteUsage

    for k, sheet in pairs( bc.images.emoteSheets ) do
        for i, sprite in pairs( sheet.sprites ) do
            local names = table.Copy( sprite.chatStrings )
            table.insert( names, ":" .. sprite.name .. ":" )

            for l, name in pairs( names ) do
                if name[1] ~= ":" or name[#name] ~= ":" then
                    table.insert( short, name )
                else
                    table.insert( long, name )
                end
                usage[name] = usage[name] or 0
                lookup[name] = { sheet = sheet, idx = i }
            end
        end
    end

    table.sort( short, function( a, b )
        return #a > #b
    end )

    bc.images.emoteLookup = {
        lookup = lookup,
        short = short,
        long = long
    }
end

function bc.images.enableGiphy()
    bc.images.giphyEnabled = true
    if bc.autoComplete and bc.autoComplete.gotCommands then
        bc.autoComplete.cmds[bc.defines.giphyCommand] = bc.autoComplete.disabledCmds[bc.defines.giphyCommand] or 0
    end
end

net.Receive( "BC_sendGif", function( len, ply )
    if not bc.base.enabled then return end
    if not bc.settings.getValue( "showGifs" ) then return end

    local chanName = net.ReadString()
    local url = net.ReadString()
    local text = net.ReadString()

    bc.channels.message( chanName, {
        formatter = true,
        type = "gif",
        text = text,
        url = url
    } )
end )
