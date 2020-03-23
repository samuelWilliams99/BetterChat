--includes
include( "betterchat/client/channels/mainchannels.lua" )
include( "betterchat/client/channels/privatechannels.lua" )
include( "betterchat/client/channels/adminchannel.lua" )
include( "betterchat/client/channels/logschannel.lua" )
include( "betterchat/client/channels/groupchannels.lua" )
include( "betterchat/client/channels/teamoverload.lua" )

chatBox.channels = {}
chatBox.channels.panels = {}
chatBox.channels.openChannels = {}

-- Changes arguments of AddSheet to AddSheet( label, panel, material, tabIndex )
local function alterAddSheet( sheet )
    function sheet.tabScroller:AddPanel( pnl, idx )
        table.insert( self.Panels, idx or #self.Panels, pnl )
        pnl:SetParent( self.pnlCanvas )
        self:InvalidateLayout( true )
    end

    function sheet:AddSheet( label, panel, material, idx )
        if ( !IsValid( panel ) ) then
            ErrorNoHalt( "DPropertySheet:AddSheet tried to add invalid panel!" )
            debug.Trace()
            return
        end

        local Sheet = {}

        Sheet.Name = label
        Sheet.Tab = vgui.Create( "DTab", self )
        Sheet.Tab:Setup( label, self, panel, material )

        Sheet.Panel = panel
        Sheet.Panel:SetPos( self:GetPadding(), 20 + self:GetPadding() )
        Sheet.Panel:SetVisible( false )
        panel:SetParent( self )
        table.insert( self.Items, Sheet )

        if ( !self:GetActiveTab() ) then
            self:SetActiveTab( Sheet.Tab )
            Sheet.Panel:SetVisible( true )
        end
        self.tabScroller:AddPanel( Sheet.Tab, idx )

        return Sheet
    end
end

hook.Add( "BC_preInitPanels", "BC_initChannels", function()
    chatBox.channels.channels = {}
    chatBox.channels.openChannels = {}
    local g = chatBox.graphics
    local d = g.derma

    d.psheet = vgui.Create( "DPropertySheet", d.chatFrame )
    d.psheet:SetName( "BC_tabSheet" )
    d.psheet:SetPos( 0, 5 )
    d.psheet:SetSize( g.size.x, g.size.y - 37 )
    d.psheet:SetPadding( 0 )
    d.psheet:SetFadeTime( 0 )
    d.psheet:SetMouseInputEnabled( true )
    d.psheet.Paint = nil
    function d.psheet:OnActiveTabChanged( old, new )
        chatBox.sidePanel.close( "Channel Settings" )
        chatBox.sidePanel.close( "Group Members" )
        timer.Simple( 0.02, function()
            hook.Run( "BC_channelChanged" ) -- delay to allow channel data to change
        end )
    end

    alterAddSheet( d.psheet )

    local oldLayout = d.psheet.PerformLayout
    function d.psheet:PerformLayout()
        self:SetSize( g.size.x, g.size.y - 37 )
        oldLayout( self )
    end

    local btn = vgui.Create( "DButton", d.chatFrame )
    btn:SetPos( g.size.x - 50 - 33, 5 )
    btn:SetSize( 50, 19 )
    btn:SetTextColor( chatBox.defines.theme.buttonTextFocused )
    btn:SetText( "Open" )
    function btn:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, chatBox.defines.theme.foreground )
    end
    function btn:DoClick()
        local menu = DermaMenu()
        hook.Run( "BC_makeChannelButtons", menu )
        menu:Open()
    end
    local oldLayout = btn.PerformLayout or function() end
    function btn:PerformLayout()
        self:SetPos( g.size.x - 50 - 33, 5 )
        oldLayout( self )
    end

    d.channelButton = btn

    d.psheet.tabScroller:DockMargin( 3, 0, 88, 0 )

end )

local function updateRPListener()
    if not DarkRP then return end

    local c = chatBox.channels.getActiveChannel()

    DarkRP.addChatReceiver( chatBox.channels.wackyString, "talk in " .. c.displayName, function( ply )
        local chan = chatBox.channels.getActiveChannel()

        if chan.group then
            return table.HasValue( chan.group.members, ply:SteamID() )
        elseif chan.plySID then
            return chan.plySID == ply:SteamID()
        elseif chan.name == "Admin" then
            return ply:IsAdmin() or ( FAdmin and FAdmin.Access.PlayerHasPrivilege( ply, "AdminChat" ) )
        else
            return false
        end
    end )
end

hook.Add( "BC_postInitPanels", "BC_postInitChannels", function()
    for k, channel in pairs( chatBox.channels.channels ) do
        local shouldOpen = channel.openOnStart
        if type( shouldOpen ) == "function" then
            shouldOpen = shouldOpen()
        end
        if shouldOpen then
            chatBox.channels.add( channel )
        end
    end

    --[[
	The only way I can change the "Some people can hear you..." from DarkRP is to create a ChatReceiver
	This needs a prefix which we will pushed to DarkRP by overloading the ChatTextChanged
	This prefix should never ever be typed in normal chat, else the wrong listener will be called (wont error, just wont be correct)
	So heres a wacky string that people probably wont ever type :)
	]]
    chatBox.channels.wackyString = "┘♣├ôÒ"

    updateRPListener()

end )

hook.Add( "BC_channelChanged", "BC_changeRPListener", function()
    updateRPListener()
    local c = chatBox.channels.getActiveChannel()
    if c.hideChatText then
        hook.Run( "ChatTextChanged", chatBox.channels.wackyString )
    else
        hook.Run( "ChatTextChanged", chatBox.graphics.derma.textEntry:GetText() or "" )
    end
end )

hook.Add( "BC_keyCodeTyped", "BC_sendMessageHook", function( code, ctrl, shift )
    if code == KEY_ENTER then
        local channel = chatBox.channels.getActiveChannel()
        local txt = chatBox.graphics.derma.textEntry:GetText()
        chatBox.graphics.derma.textEntry:SetText( "" )

        local abort, dontClose = hook.Run( "BC_messageCanSend", channel, txt )

        if abort then
            if not dontClose then
                chatBox.input.historyIndex = 0
                chatBox.input.historyInput = ""
                chatBox.base.closeChatBox()
            end
            return
        end

        if channel.trim then
            txt = string.Trim( txt )
        end

        if #txt > 0 then
            channel.send( channel, txt )
            table.insert( chatBox.input.history, txt )
        end
        chatBox.input.historyIndex = 0
        chatBox.input.historyInput = ""

        hook.Run( "BC_messageSent", channel, txt )
        chatBox.base.closeChatBox()
        return true
    elseif not chatBox.graphics.derma.emoteMenu:IsVisible() then
        if code == KEY_TAB and ctrl then
            local psheet = chatBox.graphics.derma.psheet
            local tabs = psheet.tabScroller.Panels
            local activeTab = psheet:GetActiveTab()

            local tabIdx = table.KeyFromValue( tabs, activeTab )

            if not tabIdx then
                print( "(ERROR) TAB INDEX UNDEFINED" )
                return true
            end --Shouldnt ever happen but would rather nothing over an error

            if not shift then
                tabIdx = ( tabIdx % #tabs ) + 1
            else
                tabIdx = tabIdx - 1
                if tabIdx < 1 then tabIdx = #tabs end --simplicity over looks
            end

            psheet:SetActiveTab( tabs[tabIdx] )

            return true
        elseif code >= KEY_1 and code <= KEY_9 and ctrl then
            local psheet = chatBox.graphics.derma.psheet
            local index = code - 1
            local tabs = psheet.tabScroller.Panels
            if tabs[index] then
                psheet:SetActiveTab( tabs[index] )
            end
        end
    end
end )

hook.Add( "BC_showChat", "BC_showChannelElements", function()
    chatBox.graphics.derma.psheet.tabScroller:Show()
    chatBox.graphics.derma.channelButton:Show()
end )
hook.Add( "BC_hideChat", "BC_hideChannelElements", function()
    chatBox.graphics.derma.psheet.tabScroller:Hide()
    chatBox.graphics.derma.channelButton:Hide()
end )

function chatBox.channels.getChannel( chanName )
    for k, v in pairs( chatBox.channels.channels ) do
        if v.name == chanName then
            return v
        end
    end
    return nil
end

function chatBox.channels.isOpen( channel )
    if not channel then return false end
    return table.HasValue( chatBox.channels.openChannels, channel.name )
end

function chatBox.channels.getActiveChannel()
    local tab = chatBox.graphics.derma.psheet:GetActiveTab()
    local tabs = chatBox.graphics.derma.psheet:GetItems()
    local name = nil
    for k, v in pairs( tabs ) do
        if v.Tab == tab then
            name = v.Name
        end
    end
    return chatBox.channels.getChannel( name )
end

function chatBox.channels.getActiveChannelIdx()
    local tab = chatBox.graphics.derma.psheet:GetActiveTab()
    local tabs = chatBox.graphics.derma.psheet:GetItems()
    local name = nil
    for k, v in pairs( tabs ) do
        if v.Tab == tab then
            return k
        end
    end
    return nil
end

function chatBox.channels.message( channelNames, ... )
    if not chatBox.base.ready then return end
    if channelNames == nil then
        for k, v in pairs( chatBox.channels.channels ) do
            if v.replicateAll then continue end
            chatBox.channels.messageDirect( v, ... )
        end
        return
    end
    if type( channelNames ) == "string" then
        channelNames = { channelNames } --if passed single channel, pack into array
    end


    local editIdx
    local useEditFunc = true

    local data = { ... }
    for k = 1, #data do
        local v = data[k]
        if type( v ) == "table" and v.formatter and v.type == "prefix" then
            editIdx = editIdx or k
            table.remove( data, editIdx )
        elseif type( v ) == "table" and v.controller and v.type == "noPrefix" then
            useEditFunc = false
            table.remove( data, k )
        end
    end

    local relayToAll = false
    local editChan = nil
    local relayToMsgC = false

    local channels = {}

    for k = 1, #channelNames do
        local chanName = channelNames[k]
        if chanName == "MsgC" then
            relayToMsgC = true
            continue
        end

        local channel = chatBox.channels.getChannel( chanName )
        if not channel then continue end
        if channel.relayAll then
            relayToAll = true
            if channel.allFunc then
                if not editChan then
                    editChan = channel
                end
            else
                useEditFunc = false
            end
        elseif chanName == "All" then
            relayToAll = true
            useEditFunc = false
            continue
        end
        if channel.replicateAll then continue end
        table.insert( channels, channel )
    end

    local dataAll = table.Copy( data )

    if editChan and useEditFunc then
        editChan.allFunc( editChan, dataAll, editIdx or 1 )
    end

    if relayToAll then
        chatBox.channels.messageDirect( "All", unpack( dataAll ) )
    end

    for k, c in pairs( channels ) do
        if c.showAllPrefix then
            chatBox.channels.messageDirect( c, unpack( dataAll ) )
        else
            chatBox.channels.messageDirect( c, unpack( data ) )
        end
    end

    if relayToMsgC then
        if editChan and useEditFunc then
            editChan.allFunc( editChan, data, editIdx or 1, true )
        end
        chatBox.util.msgC( unpack( data ) )
    end
end

local function parseName( name )
    name = string.Replace( name, "\n", "" )
    name = string.Replace( name, "\t", "" )
    return name
end

function chatBox.channels.messageDirect( channel, controller, ... )
    if not chatBox.base.ready then return end
    if type( channel ) == "string" then
        channel = chatBox.channels.getChannel( channel )
    end

    if not channel or not table.HasValue( chatBox.channels.openChannels, channel.name ) then return end

    if channel.name == "All" then
        for k, v in pairs( chatBox.channels.channels ) do
            if v.replicateAll then
                chatBox.channels.messageDirect( v, controller, ... )
            end
        end
    end

    local data = { ... }

    local doSound = true
    if type( controller ) == "table" and ( controller.isController or controller.controller ) then --if they gave a controller
        if controller.doSound ~= nil then
            doSound = controller.doSound
        end
    else
        table.insert( data, 1, controller )
    end


    if not channel then return end
    local chanName = channel.name

    if doSound then
        if channel.tickMode == 0 then
            chatBox.formatting.triggerTick()
        end
        if channel.popMode == 0 then
            chatBox.formatting.triggerPop()
        end
    end

    if channel.showTimestamps then
        table.insert( data, 1, chatBox.defines.theme.timeStamps )
        local timeData = string.FormattedTime( os.time() )
        timeData.h = timeData.h % 24
        table.insert( data, 2, string.format( "%02i:%02i", timeData.h, timeData.m ) .. " - " )
        table.insert( data, 3, chatBox.defines.colors.white )
    end

    local richText = chatBox.channels.panels[chanName].text
    local prevCol = chatBox.defines.colors.white
    richText:InsertColorChange( prevCol )
    richText:SetMaxLines( chatBox.settings.getValue( "chatHistory" ) )
    local ignoreNext = false
    for _, obj in pairs( data ) do
        if type( obj ) == "table" then --colour/formatter
            if obj.formatter then
                if obj.type == "escape" then
                    ignoreNext = true
                    continue
                elseif obj.type == "clickable" then
                    if obj.colour then
                        obj.color = obj.colour -- Kinda gross but whatever
                    end
                    if obj.color then
                        richText:InsertColorChange( obj.color )
                    end
                    richText:InsertClickableTextStart( obj.signal )
                    richText:AppendText( obj.text )
                    richText:InsertClickableTextEnd()
                    if obj.color then
                        richText:InsertColorChange( prevCol )
                    end
                elseif obj.type == "image" then
                    chatBox.images.addEmote( richText, obj )
                elseif obj.type == "gif" then
                    chatBox.images.addGif( richText, obj )
                elseif obj.type == "text" then
                    if obj.font then
                        richText:SetFont( obj.font )
                    end
                    richText:AppendText( obj.text )
                    richText:SetFont( channel.font )
                elseif obj.type == "decoration" then
                    richText:SetDecorations( obj.bold, obj.italic, obj.underline, obj.strike )
                elseif obj.type == "themeColor" then
                    local col = table.Copy( chatBox.defines.theme[obj.name] )
                    if col then
                        col.a = 255
                        richText:InsertColorChange( col )
                        prevCol = col
                    end
                end
            elseif obj.isConsole then
                richText:InsertColorChange( chatBox.defines.theme.server )
                richText:AppendText( "Server" )
                richText:InsertColorChange( prevCol )
            elseif IsColor( obj ) then
                obj = table.Copy( obj )
                obj.a = 255
                richText:InsertColorChange( obj )
                prevCol = obj
            end
        elseif type( obj ) == "Player" then --ply
            local col = team.GetColor( obj:Team() )
            richText:InsertColorChange( col.r, col.g, col.b, 255 )
            richText:InsertClickableTextStart( "Player-" .. obj:SteamID() )
            richText:AppendText( parseName( obj:Nick() ) )
            richText:InsertClickableTextEnd()
            richText:InsertColorChange( prevCol )
            if obj == LocalPlayer() and not ignoreNext then
                if doSound then
                    if channel.tickMode == 1 then
                        chatBox.formatting.triggerTick()
                    end
                    if channel.popMode == 1 then
                        chatBox.formatting.triggerPop()
                    end
                end
            end
        else --normal
            local val = tostring( obj )
            if val == nil then continue end
            richText:AppendText( val )
        end
        ignoreNext = false
    end

    if channel.addNewLines then
        richText:AppendText( "\n" )
    end

    if channel.onMessage then
        channel.onMessage()
    end
end

function chatBox.channels.remove( channel )
    local d = chatBox.channels.panels[channel.name]
    local psheet = chatBox.graphics.derma.psheet
    local tabs = psheet.tabScroller.Panels
    local activeTab = psheet:GetActiveTab()

    local nextChannel
    if d.tab == activeTab then
        local tabIdx = table.KeyFromValue( tabs, activeTab )
        if tabIdx == #tabs then
            nextChannel = tabs[tabIdx - 1].data.name
        else
            nextChannel = tabs[tabIdx + 1].data.name
        end
    end

    chatBox.graphics.derma.psheet:CloseTab( d.tab, true )
    table.RemoveByValue( chatBox.channels.openChannels, channel.name )
    if not channel.hideInitMessage then
        local chanName = channel.hideRealName and channel.displayName or channel.name
        if channel.name ~= "All" and chatBox.settings.getValue( "printChannelEvents" ) then
            chatBox.channels.messageDirect( "All", chatBox.defines.colors.printBlue, "Channel ",
                chatBox.defines.theme.channels, chanName, chatBox.defines.colors.printBlue, " removed." )
        end
    end
    chatBox.sidePanel.removeChild( "Channel Settings", channel.name )
    if channel.group then
        chatBox.sidePanel.removeChild( "Group Members", channel.name )
    end

    if nextChannel then
        chatBox.channels.focus( nextChannel )
    end
end

local function openLink( url )
    if string.Left( url, 7 ) ~= "http://" and string.Left( url, 8 ) ~= "https://" then
        url = "http://" .. url
    end
    chatBox.base.closeChatBox()
    gui.OpenURL( url )
end

function chatBox.channels.add( data )
    if not data.displayName then data.displayName = data.name end
    local g = chatBox.graphics
    local d = g.derma
    local sPanel = chatBox.sidePanel.createChild( "Channel Settings", data.name )
    chatBox.sidePanel.channels.applyDefaults( data )
    chatBox.sidePanel.channels.generateSettings( sPanel, data )
    table.insert( chatBox.channels.openChannels, data.name )

    data.needsData = false

    local panel = vgui.Create( "DPanel", d.psheet )

    function panel:Paint( w, h )
        self.settingsBtn:SetVisible( self.doPaint )
        if not self.doPaint then return end
        draw.RoundedBox( 0, 5, 2, w - 10 - 28, h - 7, chatBox.defines.theme.foreground )
        draw.RoundedBox( 0, w - 10 - 19, 2, 24, h - 7, chatBox.defines.theme.foreground )
    end
    panel.doPaint = true

    local richText = vgui.Create( "DRicherText", panel )
    richText:SetPos( 10, 10 )
    richText:SetSize( g.size.x - 20, g.size.y - 42 - 37 )
    richText:SetFont( data.font or g.font )
    richText:SetMaxLines( chatBox.settings.getValue( "chatHistory" ) )
    richText:SetHighlightColor( chatBox.defines.theme.textHighlight )

    richText.panel = panel

    local rtOldLayout = richText.PerformLayout
    function richText:PerformLayout()
        self:SetSize( g.size.x - 20, g.size.y - 42 - 37 )
        self.panel.settingsBtn:InvalidateLayout()
        rtOldLayout( self )
    end

    function richText:EventHandler( eventType, data, m )
        local idx = string.find( data, "-" )
        local dataType = string.sub( data, 1, idx - 1 )
        local dataArg = string.sub( data, idx + 1, -1 );
        if eventType == "LeftClick" then
            if dataType == "Player" then
                local ply = player.GetBySteamID( dataArg )
                if not ply then return end

                if not chatBox.sidePanel.childExists( "Player", dataArg ) then
                    chatBox.sidePanel.players.generateEntry( ply )
                end
                local s = chatBox.sidePanel.panels["Player"]
                if s.isOpen and s.activePanel == dataArg then
                    chatBox.sidePanel.close( "Player" )
                else
                    chatBox.sidePanel.open( "Player", dataArg )
                end
            elseif dataType == "Link" then
                openLink( dataArg )
            end
        elseif eventType == "DoubleClick" then
            if dataType == "Player" then
                local ply = player.GetBySteamID( dataArg )
                if not ply then return end
                if not chatBox.private.canMessage( ply ) then return end

                channel = chatBox.private.createChannel( ply )

                if not chatBox.channels.isOpen( channel ) then
                    chatBox.private.addChannel( channel )
                end
                chatBox.channels.focus( channel.name )
            elseif dataType == "Link" then
                openLink( dataArg )
            end
        elseif eventType == "RightClick" then
            if dataType == "Link" then
                m:AddOption( "Copy Link", function()
                    SetClipboardText( dataArg )
                end )
            elseif dataType == "Player" then
                m:AddOption( "Copy SteamID", function()
                    SetClipboardText( dataArg )
                end )
                local ply = player.GetBySteamID( dataArg )
                if ply and chatBox.private.canMessage( ply ) then
                    m:AddOption( "Open Private Channel", function()
                        local ply = player.GetBySteamID( dataArg )
                        if not ply then return end

                        channel = chatBox.private.createChannel( ply )

                        if not chatBox.channels.isOpen( channel ) then
                            chatBox.private.addChannel( channel )
                        end
                        chatBox.channels.focus( channel.name )
                    end )
                end
            end
        elseif eventType == "RightClickPreMenu" then
            if dataType == "Player" then
                local ply = player.GetBySteamID( dataArg )
                hook.Run( "BC_playerRightClick", ply, m )
            end
        end
        hook.Run( "BC_chatTextClick", eventType, dataType, dataArg )
    end

    function richText:NewElement( element, lineNum )
        element.lineNo = lineNum
        element.timeCreated = CurTime()
        function element:Think()
            if chatBox.base.isOpen then
                local col = self:GetTextColor()
                col.a = 255
                self:SetTextColor( col )
            else
                local col = self:GetTextColor()
                local dt = CurTime() - self.timeCreated
                local fadeTime = chatBox.settings.getValue( "fadeTime" )
                if fadeTime == 0 then
                    col.a = 255
                elseif dt > fadeTime + 1 then
                    col.a = 0
                else
                    dt = math.Max( dt - fadeTime, 0 )
                    col.a = math.Max( 255 - dt * 255, 0 )
                end

                self:SetTextColor( col )
            end
        end
    end

    local settingsBtn = vgui.Create( "DButton", panel )
    settingsBtn:SetPos( d.chatFrame:GetWide() - 59, 5 )
    settingsBtn:SetSize( 24, 24 )
    settingsBtn:SetText( "" )
    settingsBtn:SetColor( chatBox.defines.theme.channelCog )
    settingsBtn.ang = 0
    settingsBtn.name = data.name

    local sbOldLayout = settingsBtn.PerformLayout
    function settingsBtn:PerformLayout()
        self:SetPos( d.chatFrame:GetWide() - 59, 5 )
        sbOldLayout( self )
    end

    function settingsBtn:DoClick()
        local s = chatBox.sidePanel.panels["Channel Settings"]
        if s.isOpen then
            chatBox.sidePanel.close( s.name )
        else
            chatBox.sidePanel.open( s.name, self.name )
        end
    end
    function settingsBtn:Paint( w, h )
        self.ang = -45 * chatBox.sidePanel.panels["Channel Settings"].animState
        self:SetColor( chatHelper.lerpCol( chatBox.defines.theme.channelCog, chatBox.defines.theme.channelCogFocused, chatBox.sidePanel.panels["Channel Settings"].animState ) )
        surface.SetMaterial( chatBox.defines.materials.cog )
        surface.SetDrawColor( self:GetColor() )
        surface.DrawTexturedRectRotated( w / 2, h / 2, w, h, self.ang )
    end

    panel.settingsBtn = settingsBtn
    panel.text = richText
    panel.data = data

    local tabs = d.psheet.tabScroller.Panels
    local idx = #tabs + 1
    for k, v in ipairs( tabs ) do
        if v.data.position > data.position then
            idx = k
            break
        end
    end

    local v = d.psheet:AddSheet( data.name, panel, "icon16/" .. data.icon, idx )
    chatBox.channels.panels[data.name] = {
        panel = panel,
        text = richText,
        tab = v.Tab
    }
    function v.Tab:GetTabHeight() return 22 end
    v.Tab.data = data
    function v.Tab:Paint( w, h )
        local a = self:IsActive()
        local col = a and chatBox.defines.theme.foreground or chatBox.defines.theme.foregroundLight

        draw.RoundedBox( 0, 2, 0, w - 4, h, col )
        if self:GetText() ~= self.data.displayName then
            self:SetText( self.data.displayName )
            self:GetPropertySheet().tabScroller:InvalidateLayout( true ) -- to make the tabs resize correctly
        end
    end
    function v.Tab:DoRightClick()
        local menu = DermaMenu()
        menu:AddOption( "Settings", function()
            local s = chatBox.sidePanel.panels["Channel Settings"]
            if s.isOpen and s.activePanel == self.data.name then
                chatBox.sidePanel.close( s.name )
            else
                chatBox.sidePanel.open( s.name, self.data.name )
            end
        end )
        if not self.data.disallowClose then
            menu:AddOption( "Close", function()
                chatBox.channels.remove( self.data )
            end )
        end
        menu:Open()
    end

    function v.Tab:DoMiddleClick()
        if not self.data.disallowClose then
            chatBox.channels.remove( self.data )
        end
    end

    -- only way to edit inset :(
    function v.Tab:ApplySchemeSettings()
        local ExtraInset = 13
        if ( self.Image ) then
            ExtraInset = ExtraInset + self.Image:GetWide()
        end
        self:SetTextInset( ExtraInset, 4 )

        local w, h = self:GetContentSize()
        h = self:GetTabHeight()
        self:SetSize( w + 10, h )
        DLabel.ApplySchemeSettings( self )
    end

    v.Tab:SetText( data.displayName )
    v.Tab:GetPropertySheet().tabScroller:InvalidateLayout( true ) -- Force the Tab size to be correct instantly
                                                                -- Waiting to first paint can cause issues

    if data.postAdd then data.postAdd( data, panel ) end

    for k, v in pairs( chatBox.sidePanel.channels.template ) do
        if v.onInit then
            v.onInit( data, richText )
        end
    end

    if not chatBox.base.isOpen then
        v.Tab:Hide()
    end

    if not data.hideInitMessage and chatBox.settings.getValue( "printChannelEvents" ) then
        local chanName = data.hideRealName and data.displayName or data.name

        local function createdPrint()
            if not data.replicateAll then
                chatBox.channels.messageDirect( data.name, chatBox.defines.colors.printBlue, "Channel ",
                    chatBox.defines.theme.channels, chanName, chatBox.defines.colors.printBlue, " created." )
            end
            if data.name ~= "All" then
                chatBox.channels.messageDirect( "All", chatBox.defines.colors.printBlue, "Channel ",
                    chatBox.defines.theme.channels, chanName, chatBox.defines.colors.printBlue, " created." )
            end
        end
        if chatBox.base.initializing then
            timer.Simple( 0, createdPrint ) -- Delay messages to allow other channels to be created before prints
        else
            createdPrint()
        end
    end
end

function chatBox.channels.focus( channel )
    local tabName
    if type( channel ) == "string" then
        tabName = channel
    else
        tabName = channel.name
    end
    for k, tab in pairs( chatBox.graphics.derma.psheet:GetItems() ) do
        if tab.Name == tabName then
            chatBox.graphics.derma.psheet:SetActiveTab( tab.Tab )
            chatBox.graphics.derma.psheet.tabScroller:ScrollToChild( tab.Tab )
        end
    end
end

function chatBox.channels.showPSheet()
    for k, v in pairs( chatBox.graphics.derma.psheet:GetItems() ) do
        v.Tab:Show()
        v.Panel.text:SetVerticalScrollbarEnabled( true )
        if not v.Panel.data.displayClosed then
            v.Panel:Show()
        end
        v.Panel.doPaint = true
    end
    chatBox.graphics.derma.psheet.tabScroller:InvalidateLayout( true ) --Psheets like to just fuck up their tabs
end

function chatBox.channels.hidePSheet()
    for k, v in pairs( chatBox.graphics.derma.psheet:GetItems() ) do
        v.Panel.text:UnselectText()
        v.Tab:Hide()
        v.Panel.text:scrollToBottom()
        v.Panel.text:SetVerticalScrollbarEnabled( false )
        if not v.Panel.data.displayClosed then
            v.Panel:Hide()
            v.Panel.doPaint = true
        else
            v.Panel.doPaint = false
            chatBox.graphics.derma.psheet:SetActiveTab( v.Tab )
        end
    end
end

function chatBox.channels.getAndOpen( chanName )
    local chan = chatBox.channels.getChannel( chanName )

    if not chan or not chatBox.channels.isOpen( chan ) then
        local dashPos = string.find( chanName, " - ", 1, true )
        if not dashPos then return nil end
        local nameType = string.sub( chanName, 1, dashPos - 1 )
        local nameArg = string.sub( chanName, dashPos + 3 )

        if nameType == "Group" and chatBox.group.allowed() then
            local id = tonumber( nameArg )
            local found = false
            for k, v in pairs( chatBox.group.groups ) do
                if v.id == id then
                    found = true
                    local c = chatBox.group.createChannel( v )
                    if not c then continue end
                    chatBox.channels.add( c )
                end
            end
            if not found then return nil end
        elseif nameType == "Player" and chatBox.private.allowed() then
            local sId = nameArg
            local ply = player.GetBySteamID( sId )
            if not ply then return nil end
            chatBox.private.addChannel( chatBox.private.createChannel( ply ) )
        else
            return chatBox.channels.getChannel( "All" )
        end
    end

    return chan
end
