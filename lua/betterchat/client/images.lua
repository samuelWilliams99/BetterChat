chatBox.images = {}

local function cleanPanel( panel, w, h, padding )
    panel:SetSize( w - padding * 2 - 2, h - padding * 2 - 20 )

    local bar = panel:GetVBar()
    bar.Paint = nil
    bar.btnUp.Paint = nil
    bar.btnDown.Paint = nil
    function bar.btnGrip:Paint( w, h )
        surface.SetDrawColor( chatBox.defines.theme.emoteAccent )
        surface.DrawRect( w - 2, 0, 2, h )
    end
    bar:SetWidth( 5 )
end

local function cleanTab( data, first )
    tab = data.Tab
    tab.first = first
    function tab:Paint( w, h )
        local a = self:IsActive()
        local bgCol = a and chatBox.defines.gray( 230 ) or chatBox.defines.gray( 210 )
        surface.SetDrawColor( bgCol )
        surface.DrawRect( 0, 0, w, h )

        if a and self.selectProg < 100 then self.selectProg = self.selectProg + 2.5 end
        if not a and self.selectProg > 0 then self.selectProg = self.selectProg - 2.5 end
        self.selectProg = math.Clamp( self.selectProg, 0, 100 )

        surface.SetDrawColor( chatBox.defines.theme.emoteAccent )
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

    tab:SetTextColor( chatBox.defines.colors.black )

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
    chatBox.images.emoteSheets = {}
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
            data.path = "spritesheets/" .. v
            table.insert( chatBox.images.emoteSheets, data )
            MsgC( chatBox.defines.colors.green, "[BetterChat] Added SpriteSheet \"" .. v .. "\".\n" )
        else
            MsgC( chatBox.defines.colors.orange, "[BetterChat] Found SpriteSheet \"" .. v .. "\" but no \"" .. name .. ".json\", ignoring.\n" )
        end
    end
    chatBox.images.generateSpriteLookups()

    local g = chatBox.graphics
    local d = g.derma

    local emoteBtn = vgui.Create( "DImageButton", d.chatFrame )
    emoteBtn:SetSize( 20, 20 )
    emoteBtn:SetMaterial( chatBox.defines.materials.emoteButton )
    emoteBtn:SetPos( g.size.x - 25, g.size.y - 25 )
    emoteBtn:SetIsMenu( true )
    function emoteBtn:DoClick()
        chatBox.images.toggleEmoteMenu()
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
        surface.SetDrawColor( chatBox.defines.gray( 190 ) )
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

    local usedEmotes, usage = chatBox.images.getUsedEmotes()
    chatBox.images.addEmotesToPanel( uPanel, usedEmotes, usage )

    local allEmotes = chatBox.images.getAllEmotes()
    chatBox.images.addEmotesToPanel( aPanel, allEmotes )

    d.emotePSheet = ePSheet
    d.emoteUsedPanel = uPanel
    d.emoteAllPanel = aPanel
end )

hook.Add( "BC_showChat", "BC_showEmoteButton", function() chatBox.graphics.derma.emoteButton:Show() end )
hook.Add( "BC_hideChat", "BC_hideEmoteButton", function() 
    chatBox.graphics.derma.emoteButton:Hide()
    chatBox.graphics.derma.emoteMenu:Hide()
end )

hook.Add( "BC_keyCodeTyped", "BC_emoteShortCutHook", function( code, ctrl, shift )
    if ctrl and code == KEY_E then
        chatBox.images.toggleEmoteMenu()
    elseif chatBox.graphics.derma.emoteMenu:IsVisible() then
        if code >= KEY_1 and code <= KEY_9 and ctrl then
            local idx = code - KEY_1 + 1
            local p = chatBox.graphics.derma.emotePSheet:GetActiveTab():GetPanel()
            local emote = p.emotes[idx]
            if not emote then return true end

            local entry = chatBox.graphics.derma.textEntry
            local txt = entry:GetText()
            local cPos = entry:GetCaretPos()

            local newTxt = string.sub( txt, 0, cPos ) .. emote .. string.sub( txt, cPos + 1 )
            local newCPos = cPos + #emote

            entry:SetText( newTxt )
            entry:SetCaretPos( newCPos )
            return true
        elseif code == KEY_TAB and ctrl then
            local psheet = chatBox.graphics.derma.emotePSheet
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

function chatBox.images.reloadUsedEmotesMenu()
    local uPanel = chatBox.graphics.derma.emoteUsedPanel
    uPanel:Clear()
    local usedEmotes, usage = chatBox.images.getUsedEmotes()
    chatBox.images.addEmotesToPanel( uPanel, usedEmotes, usage )
end

function chatBox.images.getUsedEmotes()
    chatBox.autoComplete.emoteUsage = chatBox.autoComplete.emoteUsage or {}
    local totalUsage = {}
    for str, val in pairs( chatBox.autoComplete.emoteUsage ) do
        if val == 0 then continue end

        local d = chatBox.images.emoteLookup.lookup[str]
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

function chatBox.images.getAllEmotes()
    local out = {}
    for k, sheet in pairs( chatBox.images.emoteSheets ) do
        for k1, sprite in pairs( sheet.sprites ) do
            table.insert( out, sprite.name )
        end
    end

    return out
end

function chatBox.images.addEmotesToPanel( panel, data, usage )
    local gw = 6
    local gridSize = panel:GetWide() / gw
    local padding = ( ( gridSize ) - 20 ) / 2
    panel.emotes = {}
    for k = 1, #data do
        local str = data[k]
        local sprite = chatBox.images.emoteLookup.lookup[":" .. str .. ":"]

        local g = chatBox.images.createEmote( sprite )
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
                local entry = chatBox.graphics.derma.textEntry
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

function chatBox.images.createEmote( obj )
    local g = vgui.Create( "DRicherTextGraphic" )
    g:SetType( "image" )
    g:SetSize( 20, 20 )
    g:SetPath( obj.sheet.path )
    local im = obj.sheet.sprites[obj.idx]
    g:SetSubImage( im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )
    return g
end

function chatBox.images.addEmote( richText, obj )
    local im = obj.sheet.sprites[obj.idx]
    richText:AddImage( obj.sheet.path, obj.text, 20, 20, im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )        
end

function chatBox.images.addGif( richText, obj )
    richText:InsertClickableTextStart( "Link-" .. obj.url )
    local size = richText.fontHeight * 5
    richText:AddGif( obj.url, obj.text .. "\n", size, size )
    richText:InsertClickableTextEnd()
end

function chatBox.images.toggleEmoteMenu()
    local g = chatBox.graphics
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

function chatBox.images.generateSpriteLookups()
    local lookup = {}
    local nameList = {}
    local emotes = {}

    chatBox.autoComplete = chatBox.autoComplete or {}
    chatBox.autoComplete.emoteUsage = chatBox.autoComplete.emoteUsage or {}
    local usage = chatBox.autoComplete.emoteUsage

    for k, sheet in pairs( chatBox.images.emoteSheets ) do
        for i, sprite in pairs( sheet.sprites ) do
            local names = table.Copy( sprite.chatStrings )
            table.insert( names, ":" .. sprite.name .. ":" )

            for l, name in pairs( names ) do
                table.insert( nameList, name )
                if name[1] ~= ":" or name[#name] ~= ":" then
                    table.insert( emotes, name )
                end
                usage[name] = usage[name] or 0
                lookup[name] = { sheet = sheet, idx = i }
            end
        end
    end

    table.sort( nameList, function( a, b )
        return #a > #b
    end )

    chatBox.images.emoteLookup = {
        lookup = lookup,
        list = nameList,
        emotes = emotes
    }
end

function chatBox.images.enableGiphy()
    chatBox.images.giphyEnabled = true
    if chatBox.autoComplete and chatBox.autoComplete.gotCommands then
        chatBox.autoComplete.cmds[chatBox.defines.giphyCommand] = chatBox.autoComplete.extraCmds[chatBox.defines.giphyCommand] or 0
    end
end

net.Receive( "BC_sendGif", function( len, ply )
    if not chatBox.base.enabled then return end
    if not chatBox.settings.getValue( "showGifs" ) then return end

    local chanName = net.ReadString()
    local url = net.ReadString()
    local text = net.ReadString()

    chatBox.channels.message( chanName, {
        formatter = true,
        type = "gif",
        text = text,
        url = url
    } )
end )