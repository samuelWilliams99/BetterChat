chatBox.spriteSheets = {}

hook.Add( "BC_InitPanels", "BC_InitImages", function()
    chatBox.spriteSheets = {}
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
            table.insert( chatBox.spriteSheets, data )
            MsgC( Color( 0, 255, 0 ), "[BetterChat] Added SpriteSheet \"" .. v .. "\".\n" )
        else
            MsgC( Color( 255, 100, 0 ), "[BetterChat] Found SpriteSheet \"" .. v .. "\" but no \"" .. name .. ".json\", ignoring.\n" )
        end
    end
    chatBox.generateSpriteLookups()

    local g = chatBox.graphics

    local imageBtn = vgui.Create( "DImageButton", g.chatFrame )
    imageBtn:SetSize( 20, 20 )
    imageBtn:SetMaterial( chatBox.materials.getMaterial( "icons/emojibutton.png" ) )
    imageBtn:SetPos( g.size.x - 25, g.size.y - 25 )
    imageBtn:SetIsMenu( true )
    imageBtn.DoClick = function( self )
        chatBox.toggleEmojiMenu()
    end
    local oldLayout = imageBtn.PerformLayout
    function imageBtn:PerformLayout()
        self:SetSize( 20, 20 )
        self:SetPos( g.size.x - 25, g.size.y - 25 )
        oldLayout( self )
    end
    g.emojiButton = imageBtn


    local mw, mh = 150, 150
    local emojiMenu = vgui.Create( "DPanel", g.chatFrame )
    emojiMenu:SetSize( mw, mh )
    emojiMenu:MoveToFront()
    emojiMenu:Hide()
    emojiMenu:SetIsMenu( true )
    emojiMenu.GetDeleteSelf = function() return false end
    emojiMenu.Paint = function( self, w, h ) 
        surface.SetDrawColor( 190, 190, 190, 255 )
        surface.DrawRect( 0, 0, w, h )
    end
    g.emojiMenu = emojiMenu

    local uPanel = vgui.Create( "DScrollPanel" )
    local aPanel = vgui.Create( "DScrollPanel" )

    local ePSheet = vgui.Create( "DPropertySheet", emojiMenu )

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

    local usedEmotes, usage = chatBox.getUsedEmotes()
    chatBox.addEmotesToPanel( uPanel, usedEmotes, usage )

    local allEmotes = chatBox.getAllEmotes()
    chatBox.addEmotesToPanel( aPanel, allEmotes )

    g.emojiPSheet = ePSheet
    g.emojiUsedPanel = uPanel
    g.emojiAllPanel = aPanel
end )

hook.Add( "BC_ShowChat", "BC_showEmojiButton", function() chatBox.graphics.emojiButton:Show() end )
hook.Add( "BC_HideChat", "BC_hideEmojiButton", function() 
    chatBox.graphics.emojiButton:Hide()
    chatBox.graphics.emojiMenu:Hide()

end )

hook.Add( "BC_KeyCodeTyped", "BC_EmojiShortCutHook", function( code, ctrl, shift )
    if ctrl and code == KEY_E then
        chatBox.toggleEmojiMenu()
    elseif chatBox.graphics.emojiMenu:IsVisible() then
        if code >= KEY_1 and code <= KEY_9 and ctrl then
            local idx = code - KEY_1 + 1
            local p = chatBox.graphics.emojiPSheet:GetActiveTab():GetPanel()
            local emoji = p.emojis[idx]
            if not emoji then return true end

            local entry = chatBox.graphics.textEntry
            local txt = entry:GetText()
            local cPos = entry:GetCaretPos()

            local newTxt = string.sub( txt, 0, cPos ) .. emoji .. string.sub( txt, cPos + 1 )
            local newCPos = cPos + #emoji

            entry:SetText( newTxt )
            entry:SetCaretPos( newCPos )
            return true
        elseif code == KEY_TAB and ctrl then
            local psheet = chatBox.graphics.emojiPSheet
            local tabs = psheet:GetItems()
            local emojiMode = psheet:GetActiveTab()


            if tabs[1].Tab == emojiMode then
                psheet:SetActiveTab( tabs[2].Tab )
            else
                psheet:SetActiveTab( tabs[1].Tab )
            end
            return true
        end
    end
end )

function chatBox.reloadUsedEmotesMenu()
    local uPanel = chatBox.graphics.emojiUsedPanel
    uPanel:Clear()
    local usedEmotes, usage = chatBox.getUsedEmotes()
    chatBox.addEmotesToPanel( uPanel, usedEmotes, usage )
end

function chatBox.getUsedEmotes()
    chatBox.autoComplete.emoteUsage = chatBox.autoComplete.emoteUsage or {}
    local totalUsage = {}
    for str, val in pairs( chatBox.autoComplete.emoteUsage ) do
        if val == 0 then continue end

        local d = chatBox.spriteLookup.lookup[str]
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

function chatBox.getAllEmotes()
    local out = {}
    for k, sheet in pairs( chatBox.spriteSheets ) do
        for k1, sprite in pairs( sheet.sprites ) do
            table.insert( out, sprite.name )
        end
    end

    return out
end

function chatBox.addEmotesToPanel( panel, data, usage )
    local gw = 6
    local gridSize = panel:GetWide() / gw
    local padding = ( ( gridSize ) - 20 ) / 2
    panel.emojis = {}
    for k = 1, #data do
        local str = data[k]
        local sprite = chatBox.spriteLookup.lookup[":" .. str .. ":"]
        --print(str)
        --PrintTable(table.GetKeys(chatBox.spriteLookup.lookup))
        local g = chatBox.createImage( sprite )
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

        table.insert( panel.emojis, g.str )

        g:SetCursor( "hand" )
        g.OnMousePressed = function( self, t )
            if t == MOUSE_LEFT then
                local entry = chatBox.graphics.textEntry
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

function chatBox.createImage( obj )
    local g = vgui.Create( "DRicherTextGraphic" )
    g:SetType( "image" )
    g:SetSize( 20, 20 )
    g:SetPath( obj.sheet.path )
    local im = obj.sheet.sprites[obj.idx]
    g:SetSubImage( im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )
    return g
end

function chatBox.addImage( richText, obj )
    local im = obj.sheet.sprites[obj.idx]
    richText:AddImage( obj.sheet.path, obj.text, 20, 20, im.posX * obj.sheet.spriteWidth, im.posY * obj.sheet.spriteHeight, obj.sheet.spriteWidth, obj.sheet.spriteHeight )        
end

function cleanPanel( panel, w, h, padding )
    panel:SetSize( w - padding * 2 - 2, h - padding * 2 - 20 )

    local bar = panel:GetVBar()
    bar.Paint = nil
    bar.btnUp.Paint = nil
    bar.btnDown.Paint = nil
    bar.btnGrip.Paint = function( self, w, h )
        surface.SetDrawColor( Color( 65, 105, 225 ) )
        surface.DrawRect( w - 2, 0, 2, h )
    end
    bar:SetWidth( 5 )
end

function cleanTab( data, first )
    tab = data.Tab
    tab.first = first
    tab.Paint = function( self, w, h )
        local a = self:IsActive()
        local bgCol = a and Color( 230, 230, 230 ) or Color( 210, 210, 210 )
        surface.SetDrawColor( bgCol )
        surface.DrawRect( 0, 0, w, h )

        if a and self.selectProg < 100 then self.selectProg = self.selectProg + 2.5 end
        if not a and self.selectProg > 0 then self.selectProg = self.selectProg - 2.5 end
        self.selectProg = math.Clamp( self.selectProg, 0, 100 )

        surface.SetDrawColor( Color( 65, 105, 225 ) )
        local p = self.selectProg / 100
        if self.first then
            surface.DrawRect( ( 1 - p ) * w, h - 2, p * w, 2 )
        else
            surface.DrawRect( 0, h - 2, p * w, 2 )
        end

    end
    tab.selectProg = first and 100 or 0
    tab:SetContentAlignment( 5 )
    tab.GetTabHeight = function() return 20 end

    tab:SetTextColor( Color( 0, 0, 0 ) )

    tab.ApplySchemeSettings = function( self )

        local w, h = self:GetContentSize()
        h = self:GetTabHeight()

        local xI, _ = self:GetTextInset()
        self:SetTextInset( xI, 0 )
        self:SetSize( 72, h )

        DLabel.ApplySchemeSettings( self )

    end
    return data
end

function chatBox.toggleEmojiMenu()
    local g = chatBox.graphics

    local isOpen = g.emojiMenu:IsVisible()
    if isOpen then
        g.emojiMenu:Hide()
    else
        local x, y = g.frame:GetPos()
        g.emojiMenu:SetPos( x + g.size.x, y + g.size.y - 150 )
        g.emojiMenu:Show()
        RegisterDermaMenuForClose( g.emojiMenu )
        g.emojiMenu:MakePopup()
        g.emojiMenu:SetKeyboardInputEnabled( false )
    end
end

function chatBox.generateSpriteLookups()
    local lookup = {}
    local nameList = {}
    local emotes = {}

    chatBox.autoComplete = chatBox.autoComplete or {}
    chatBox.autoComplete.emoteUsage = chatBox.autoComplete.emoteUsage or {}
    local u = chatBox.autoComplete.emoteUsage

    for k, sheet in pairs( chatBox.spriteSheets ) do
        for i, sprite in pairs( sheet.sprites ) do
            local strs = table.Copy( sprite.chatStrings )
            table.insert( strs, ":" .. sprite.name .. ":" )

            for l, str in pairs( strs ) do
                table.insert( nameList, str )
                if str[1] ~= ":" or str[#str] ~= ":" then
                    table.insert( emotes, str )
                end
                u[str] = u[str] or 0
                lookup[str] = { sheet = sheet, idx = i }
            end
        end
    end

    table.sort( nameList, function( a, b )
        return #a > #b
    end )

    chatBox.spriteLookup = { lookup = lookup, list = nameList, emotes = emotes }

end

function chatBox.enableGiphy()
    chatBox.giphyEnabled = true
    if chatBox.autoComplete and chatBox.autoComplete.gotCommands then
        chatBox.autoComplete.cmds["!giphy"] = chatBox.autoComplete.extraCmds["!giphy"] or 0
    end
end

local function sendGif( channel, url, text )
    -- Doesnt make it clickable :(
    -- Fix this another time
    local rt = chatBox.channelPanels[channel.name].text
    rt:InsertClickableTextStart( "Link-" .. url )
    rt:AddGif( url, text .. "\n", 100, 100 )
    rt:InsertClickableTextEnd()
end

net.Receive( "BC_SendGif", function( len, ply )
    if not chatBox.enabled then return end

    if not chatBox.getSetting( "showGifs" ) then return end

    local url = net.ReadString()
    local chanName = net.ReadString()
    local text = net.ReadString()
    local channel = chatBox.getChannel( chanName )
    if not channel or not chatBox.isChannelOpen( channel ) then return end

    if not channel.replicateAll then
        sendGif( channel, url, text )
    end

    if channel.relayAll then
        sendGif( chatBox.getChannel( "All" ), url, text )
        for k, v in pairs( chatBox.channels ) do
            if v.replicateAll and chatBox.isChannelOpen( v ) then
                sendGif( v, url, text )
            end
        end
    end
end )