--includes
include( "betterchat/client/channels/mainchannels.lua" )
include( "betterchat/client/channels/privatechannels.lua" )
include( "betterchat/client/channels/adminchannel.lua" )
include( "betterchat/client/channels/logschannel.lua" )
include( "betterchat/client/channels/groupchannels.lua" )
include( "betterchat/client/channels/teamoverload.lua" )

bc.channels = bc.channels or {}
bc.channels.panels = bc.channels.panels or {}

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
    bc.channels.channels = {}
    bc.channels.openChannels = {}
    bc.channels.lastMessageTime = 0

    local g = bc.graphics
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
        bc.sidePanel.close( "Channel Settings" )
        bc.sidePanel.close( "Group Members" )
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
    btn:SetSize( 18, 18 )
    btn:SetText( "" )
    function btn:Paint( w, h )
        --draw.RoundedBox( 0, 0, 0, w, h, bc.defines.theme.foreground )
        local plusThickness = 2
        local plusMargin = 3
        -- V line of plus
        draw.RoundedBox( 0, ( w - plusThickness ) / 2, plusMargin, plusThickness, h - ( 2 * plusMargin ), bc.defines.theme.buttonTextFocused )
        -- H line of plus
        draw.RoundedBox( 0, plusMargin, ( h - plusThickness ) / 2, w - ( 2 * plusMargin ), plusThickness, bc.defines.theme.buttonTextFocused )
    end
    function btn:DoClick()
        local menu = DermaMenu()
        hook.Run( "BC_makeChannelButtons", menu )
        menu:Open()
    end

    local oldLayout = btn.PerformLayout or function() end
    function btn:PerformLayout()
        local tabs = d.psheet.tabScroller.Panels
        local rightTab = tabs[#tabs]
        local x = rightTab:GetPos()
        x = x + rightTab:GetWide()
        self:SetPos( x + 4, 6 )
        oldLayout( self )
    end

    d.channelButton = btn

    d.psheet.tabScroller:DockMargin( 3, 0, 88, 0 )

end )

function bc.channels.updateButtonPosition()
    bc.graphics.derma.psheet.tabScroller:InvalidateLayout( true )
    bc.graphics.derma.channelButton:InvalidateLayout( true )
end

function bc.channels.openSaved()
    bc.data.setSavingEnabled( false )

    local channels = {}
    if bc.data.openChannels and bc.settings.getValue( "saveOpenChannels" ) then
        for k, channel in pairs( bc.channels.channels ) do
            if channel.disallowClose and not table.HasValue( bc.data.openChannels, channel.name ) then
                table.insert( bc.data.openChannels, channel.name )
            end
        end
        for k, chanName in pairs( bc.data.openChannels ) do
            local channel = bc.channels.getOrCreate( chanName )
            if channel then table.insert( channels, channel ) end
        end
    else
        channels = table.filter( bc.channels.channels, function( channel ) return channel.openOnStart end )
    end

    for k, channel in pairs( channels ) do
        local shouldOpen = channel.openOnStart
        if type( shouldOpen ) == "function" then
            shouldOpen = shouldOpen( channel )
        end

        if shouldOpen ~= false then
            bc.channels.open( channel.name )
        end
    end
    bc.data.setSavingEnabled( true )
end

function bc.channels.canMessage()
    local cTime = CurTime()
    local deltaTime = cTime - bc.channels.lastMessageTime

    bc.channels.minDelay = GetConVar( "ulx_chattime" ):GetFloat()
    local canMessage = deltaTime > bc.channels.minDelay

    if canMessage then
        bc.channels.lastMessageTime = cTime
        return true
    end

    return false
end

hook.Add( "BC_postInitPanels", "BC_postInitChannels", function()
    bc.channels.openSaved()

    --[[
	The only way I can change the "Some people can hear you..." from DarkRP is to create a ChatReceiver
	This needs a prefix which we will pushed to DarkRP by overloading the ChatTextChanged
	This prefix should never ever be typed in normal chat, else the wrong listener will be called (wont error, just wont be correct)
	So heres a wacky string that people probably wont ever type :)
	]]
    bc.channels.wackyString = "┘♣├ôÒ"
end )

hook.Add( "BC_channelChanged", "BC_changeRPListener", function()
    local c = bc.channels.getActiveChannel()
    if c.hideChatText then
        hook.Run( "ChatTextChanged", bc.channels.wackyString )
    else
        hook.Run( "ChatTextChanged", bc.graphics.derma.textEntry:GetText() or "" )
    end
end )

hook.Add( "BC_framePaint", "BC_paintCooldown", function( panel, w, h )
    if bc.channels.showCooldown then
        local prog = ( CurTime() - bc.channels.lastMessageTime ) / bc.channels.minDelay
        prog = math.Clamp( prog, 0, 1 )

        draw.RoundedBox( 0, 5, h - 25 + prog * 21, w - 42, ( 1 - prog ) * 21, bc.defines.theme.textEntryCooldown )

        if prog == 1 then
            bc.channels.showCooldown = false
        end
    end
end )

hook.Add( "BC_keyCodeTyped", "BC_sendMessageHook", function( code, ctrl, shift )
    if code == KEY_ENTER then
        local txt = bc.graphics.derma.textEntry:GetText()
        local channel = bc.channels.getActiveChannel()

        if #txt == 0 then
            bc.base.close()
            return true
        end

        if not bc.channels.canMessage() then
            bc.channels.showCooldown = true
            return
        end

        bc.graphics.derma.textEntry:SetText( "" )

        local abort, dontClose = hook.Run( "BC_messageCanSend", channel, txt )

        if abort then
            if not dontClose then
                bc.base.close()
            end
            return
        end

        if channel.trim then
            txt = string.Trim( txt )
        end

        channel.send( channel, txt )
        table.insert( bc.input.history, txt )

        hook.Run( "BC_messageSent", channel, txt )
        bc.base.close()
        return true
    elseif not bc.graphics.derma.emoteMenu:IsVisible() then
        if code == KEY_TAB and ctrl then
            local psheet = bc.graphics.derma.psheet
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
        elseif code >= KEY_1 and code <= KEY_9 and ctrl and bc.settings.getValue( "channelNumShortcut" ) then
            local psheet = bc.graphics.derma.psheet
            local index = code - 1
            local tabs = psheet.tabScroller.Panels
            if tabs[index] then
                psheet:SetActiveTab( tabs[index] )
            end
        elseif code == KEY_W and ctrl then
            local channel = bc.channels.getActiveChannel()

            if not channel.disallowClose then
                bc.channels.close( channel.name )
            end
        elseif code == KEY_O and ctrl then
            local menu = DermaMenu()
            hook.Run( "BC_makeChannelButtons", menu )
            local w, h = bc.graphics.derma.channelButton:GetSize()
            local x, y = bc.graphics.derma.channelButton:LocalToScreen( w / 2, h / 2 )
            menu:Open( x, y )
        end
    end
end )

hook.Add( "BC_showChat", "BC_showChannelElements", function()
    bc.graphics.derma.psheet.tabScroller:Show()
    bc.graphics.derma.channelButton:Show()
    bc.channels.updateButtonPosition()
    hook.Run( "BC_channelChanged" )
end )
hook.Add( "BC_hideChat", "BC_hideChannelElements", function()
    bc.graphics.derma.psheet.tabScroller:Hide()
    bc.graphics.derma.channelButton:Hide()
end )

function bc.channels.get( chanName )
    for k, v in pairs( bc.channels.channels ) do
        if v.name == chanName then
            return v
        end
    end
    return nil
end

function bc.channels.isOpen( name )
    if not name then return false end
    return table.HasValue( bc.channels.openChannels, name )
end

function bc.channels.getActiveChannel()
    local tab = bc.graphics.derma.psheet:GetActiveTab()
    local tabs = bc.graphics.derma.psheet:GetItems()
    local name = nil
    for k, v in pairs( tabs ) do
        if v.Tab == tab then
            name = v.Name
        end
    end
    return bc.channels.get( name )
end

function bc.channels.getActiveChannelIdx()
    local tab = bc.graphics.derma.psheet:GetActiveTab()
    local tabs = bc.graphics.derma.psheet:GetItems()
    for k, v in pairs( tabs ) do
        if v.Tab == tab then
            return k
        end
    end
    return nil
end

function bc.channels.message( channelNames, ... )
    if not bc.base.ready then return end
    if channelNames == nil then
        for k, v in pairs( bc.channels.channels ) do
            if v.replicateAll then continue end
            bc.channels.messageDirect( v, ... )
        end
        return
    end
    if type( channelNames ) == "string" then
        channelNames = { channelNames } --if passed single channel, pack into array
    end


    local editIdx
    local useEditFunc = true

    local data = { ... }
    local controller

    if type( data[1] ) == "table" and data[1].controller then
        controller = table.remove( data, 1 )
        if controller.noPrefix then
            useEditFunc = false
        end
    end

    for k = 1, #data do
        local v = data[k]
        if type( v ) == "table" and v.formatter and v.type == "prefix" then
            editIdx = editIdx or k
            table.remove( data, editIdx )
        end
    end

    local relayToAll = false
    local editChan = nil
    local relayToMsgC = false

    local channels = {}

    local tickMode = 2
    local popMode = 2

    for k = 1, #channelNames do
        local chanName = channelNames[k]
        if chanName == "MsgC" then
            relayToMsgC = true
            continue
        end

        local channel = bc.channels.get( chanName )
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

        if channel.tickMode < tickMode then tickMode = channel.tickMode end
        if channel.popMode < popMode then popMode = channel.popMode end

        if channel.replicateAll then continue end
        table.insert( channels, channel )
    end

    controller = controller or { controller = true }
    controller.tickMode = tickMode
    controller.popMode = popMode

    local dataAll = table.Copy( data )

    if editChan and useEditFunc then
        editChan.allFunc( editChan, dataAll, editIdx or 1 )
    end

    if relayToAll then
        bc.channels.messageDirect( "All", controller, unpack( dataAll ) )
    end

    for k, c in pairs( channels ) do
        if c.showAllPrefix then
            bc.channels.messageDirect( c, controller, unpack( dataAll ) )
        else
            bc.channels.messageDirect( c, controller, unpack( data ) )
        end
    end

    if relayToMsgC then
        if editChan and useEditFunc then
            editChan.allFunc( editChan, data, editIdx or 1, true )
        end
        bc.util.msgC( unpack( data ) )
    end
end

function bc.channels.parseName( name )
    name = string.Replace( name, "\n", "" )
    name = string.Replace( name, "\t", "" )
    return name
end

function bc.channels.fromSender( ply )
    local out = {}
    local senderData = bc.compatibility.getNameTable( ply )

    for l, senderElem in pairs( senderData ) do
        if type( senderElem ) == "Player" then
            table.Add( out, {
                { formatter = true, type = "escape" },
                senderElem
            } )
        else
            table.insert( out, senderElem )
        end
    end

    return out
end

function bc.channels.preProcess( data )
    local out = {}

    for k, elem in pairs( data ) do
        if type( elem ) == "table" and elem.formatter then
            if elem.type == "sender" then
                local senderData = bc.channels.fromSender( elem.ply )
                table.insertMany( out, senderData )
            else
                table.insert( out, elem )
            end
        else
            table.insert( out, elem )
        end
    end

    return out
end

function bc.channels.messageDirect( channel, controller, ... )
    if not bc.base.ready then return end
    if type( channel ) == "string" then
        channel = bc.channels.get( channel )
    end

    if not channel or not table.HasValue( bc.channels.openChannels, channel.name ) then return end

    if channel.name == "All" then
        for k, v in pairs( bc.channels.channels ) do
            if v.replicateAll then
                bc.channels.messageDirect( v, controller, ... )
            end
        end
    end

    local data = { ... }

    local doSound = true
    local tickMode = channel.tickMode
    local popMode = channel.popMode
    if type( controller ) == "table" and controller.controller then --if they gave a controller
        if controller.doSound ~= nil then
            doSound = controller.doSound
        end
        if controller.tickMode ~= nil then
            tickMode = controller.tickMode
        end
        if controller.popMode ~= nil then
            popMode = controller.popMode
        end
    else
        table.insert( data, 1, controller )
    end


    if not channel then return end
    local chanName = channel.name

    if doSound then
        if tickMode == 0 then
            bc.formatting.triggerTick()
        end
        if popMode == 0 then
            bc.formatting.triggerPop()
        end
    end

    data = bc.channels.preProcess( data )

    if channel.showTimestamps then
        table.insert( data, 1, bc.defines.theme.timeStamps )
        local timeData = os.date( "*t" )
        table.insert( data, 2, string.format( "%02i:%02i", timeData.hour, timeData.min ) .. " - " )
        table.insert( data, 3, bc.defines.colors.white )
    end

    local richText = bc.channels.panels[chanName].text
    local prevCol = bc.defines.colors.white
    richText:InsertColorChange( prevCol )
    richText:SetMaxLines( bc.settings.getValue( "chatHistory" ) )
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
                    bc.images.addEmote( richText, obj )
                elseif obj.type == "gif" then
                    bc.images.addGif( richText, obj )
                elseif obj.type == "text" then
                    if obj.font then
                        richText:SetFont( obj.font )
                    end
                    if obj.color then
                        richText:InsertColorChange( obj.color )
                    end
                    richText:AppendText( obj.text )
                    if obj.font then
                        richText:SetFont( channel.font )
                    end
                    if obj.color then
                        richText:InsertColorChange( prevCol )
                    end
                elseif obj.type == "decoration" then
                    richText:SetDecorations( obj.bold, obj.italic, obj.underline, obj.strike )
                elseif obj.type == "themeColor" then
                    local col = table.Copy( bc.defines.theme[obj.name] )
                    if col then
                        col.a = 255
                        richText:InsertColorChange( col )
                        prevCol = col
                    end
                end
            elseif obj.isConsole then
                richText:InsertColorChange( bc.defines.theme.server )
                richText:AppendText( "Server" )
                richText:InsertColorChange( prevCol )
            elseif IsColor( obj ) then
                obj = table.Copy( obj )
                obj.a = 255
                richText:InsertColorChange( obj )
                prevCol = obj
            end
        elseif type( obj ) == "Player" then --ply
            if not IsValid( obj ) then
                richText:AppendText( tostring( obj ) )
            else
                local col = team.GetColor( obj:Team() )
                richText:InsertColorChange( col.r, col.g, col.b, 255 )
                richText:InsertClickableTextStart( "Player-" .. obj:SteamID() )
                richText:AppendText( bc.channels.parseName( obj:Nick() ) )
                richText:InsertClickableTextEnd()
                richText:InsertColorChange( prevCol )
                if obj == LocalPlayer() and not ignoreNext then
                    if doSound then
                        if tickMode == 1 then
                            bc.formatting.triggerTick()
                        end
                        if popMode == 1 then
                            bc.formatting.triggerPop()
                        end
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
        channel:onMessage( data )
    end
end

function bc.channels.close( name )
    local idx = table.keyFromMember( bc.channels.channels, "name", name )
    if not idx then return end
    local channel = bc.channels.channels[idx]
    if not bc.channels.isOpen( name ) then return end

    local d = bc.channels.panels[channel.name]
    local psheet = bc.graphics.derma.psheet
    local tabs = psheet.tabScroller.Panels
    local activeTab = psheet:GetActiveTab()

    timer.Remove( "BC_ChannelScroll-" .. channel.name )

    local nextChannel
    if d.tab == activeTab then
        local tabIdx = table.KeyFromValue( tabs, activeTab )
        if tabIdx == #tabs then
            nextChannel = tabs[tabIdx - 1].data.name
        else
            nextChannel = tabs[tabIdx + 1].data.name
        end
    end

    bc.graphics.derma.psheet:CloseTab( d.tab, true )
    table.RemoveByValue( bc.channels.openChannels, channel.name )
    if not channel.hideInitMessage then
        local chanName = channel.hideRealName and channel.displayName or channel.name
        if channel.name ~= "All" and bc.settings.getValue( "printChannelEvents" ) then
            bc.channels.messageDirect( "All", bc.defines.colors.printBlue, "Channel ",
                bc.defines.theme.channels, chanName, bc.defines.colors.printBlue, " removed." )
        end
    end
    bc.sidePanel.removeChild( "Channel Settings", channel.name )
    if channel.group then
        bc.sidePanel.removeChild( "Group Members", channel.name )
    end

    if nextChannel then
        bc.channels.focus( nextChannel )
    end

    bc.data.saveData()
    bc.channels.updateButtonPosition()

    timer.Simple( 0.02, function()
        hook.Run( "BC_channelChanged" ) -- delay to allow channel data to change
    end )
end

local function openLink( url )
    if string.Left( url, 7 ) ~= "http://" and string.Left( url, 8 ) ~= "https://" then
        url = "http://" .. url
    end
    bc.base.close()
    gui.OpenURL( url )
end

function bc.channels.add( data )
    local idx = table.keyFromMember( bc.channels.channels, "name", data.name )
    if idx then
        return bc.channels.channels[idx]
    end
    if not data.displayName then data.displayName = data.name end
    bc.channels.rememberDefaults( data )
    bc.data.loadChannel( data )
    bc.sidePanel.channels.applyDefaults( data )
    table.insert( bc.channels.channels, data )
    return data
end

function bc.channels.rememberDefaults( data )
    data.defaults = data.defaults or {}
    for k, v in pairs( data ) do
        if k == "defaults" then continue end
        data.defaults[k] = v
    end
end

function bc.channels.remove( name )
    local idx = table.keyFromMember( bc.channels.channels, "name", name )
    if not idx then return end
    table.remove( bc.channels.channels, idx )
end

function bc.channels.open( name )
    local idx = table.keyFromMember( bc.channels.channels, "name", name )
    if not idx then return end
    local data = bc.channels.channels[idx]
    if bc.channels.isOpen( name ) then return end

    local g = bc.graphics
    local d = g.derma
    local sPanel = bc.sidePanel.createChild( "Channel Settings", data.name )
    bc.sidePanel.channels.generateSettings( sPanel, data )
    table.insert( bc.channels.openChannels, data.name )

    local panel = vgui.Create( "DPanel", d.psheet )

    function panel:Paint( w, h )
        self.settingsBtn:SetVisible( self.doPaint )
        if not self.doPaint then return end
        draw.RoundedBox( 0, 5, 2, w - 10 - 28, h - 7, bc.defines.theme.foreground )
        draw.RoundedBox( 0, w - 10 - 19, 2, 24, h - 7, bc.defines.theme.foreground )
    end
    panel.doPaint = true

    local richText = vgui.Create( "DRicherText", panel )
    richText:SetPos( 10, 10 )
    richText:SetSize( g.size.x - 20, g.size.y - 42 - 37 )
    richText:SetFont( data.font or g.font )
    richText:SetMaxLines( bc.settings.getValue( "chatHistory" ) )
    richText:SetHighlightColor( bc.defines.theme.textHighlight )
    richText:SetAllowDecorations( richText:GetFont() ~= "ChatFont" )

    richText.panel = panel

    local timerName = "BC_ChannelScroll-" .. data.name
    timer.Create( timerName, 0.5, 0, function()
        if not IsValid( richText ) or not richText.scrollToBottomBtn then
            timer.Remove( timerName )
            return
        end
        if not bc.base.isOpen and richText.scrollToBottomBtn:IsVisible() then
            bc.channels.scrollToBottom( data.name )
        end
    end )

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

                if not bc.sidePanel.childExists( "Player", dataArg ) then
                    bc.sidePanel.players.generateEntry( ply )
                end
                local s = bc.sidePanel.panels["Player"]
                if s.isOpen and s.activePanel == dataArg then
                    bc.sidePanel.close( "Player" )
                else
                    bc.sidePanel.open( "Player", dataArg )
                end
            elseif dataType == "Link" then
                openLink( dataArg )
            end
        elseif eventType == "DoubleClick" then
            if dataType == "Player" then
                local ply = player.GetBySteamID( dataArg )
                if not ply then return end
                if not bc.private.canMessage( ply ) then return end

                channel = bc.private.createChannel( ply )

                if not bc.channels.isOpen( channel.name ) then
                    bc.channels.open( channel.name )
                end
                bc.channels.focus( channel.name )
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
                m:AddOption( "Copy SteamID64", function()
                    SetClipboardText( util.SteamIDTo64( dataArg ) )
                end )

                local ply = player.GetBySteamID( dataArg )
                if ply and bc.private.canMessage( ply ) then
                    m:AddOption( "Open Private Channel", function()
                        local ply = player.GetBySteamID( dataArg )
                        if not ply then return end

                        channel = bc.private.createChannel( ply )

                        if not bc.channels.isOpen( channel.name ) then
                            bc.channels.open( channel.name )
                        end
                        bc.channels.focus( channel.name )
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
            if bc.base.isOpen then
                local col = self:GetTextColor()
                col.a = 255
                self:SetTextColor( col )
            else
                local col = self:GetTextColor()
                local dt = CurTime() - self.timeCreated
                local fadeTime = bc.settings.getValue( "fadeTime" )
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
    settingsBtn:SetColor( bc.defines.theme.channelCog )
    settingsBtn.ang = 0
    settingsBtn.name = data.name

    local sbOldLayout = settingsBtn.PerformLayout
    function settingsBtn:PerformLayout()
        self:SetPos( d.chatFrame:GetWide() - 59, 5 )
        sbOldLayout( self )
    end

    function settingsBtn:DoClick()
        local s = bc.sidePanel.panels["Channel Settings"]
        if s.isOpen then
            bc.sidePanel.close( s.name )
        else
            bc.sidePanel.open( s.name, self.name )
        end
    end
    function settingsBtn:Paint( w, h )
        self.ang = -45 * bc.sidePanel.panels["Channel Settings"].animState
        self:SetColor( chatHelper.lerpCol( bc.defines.theme.channelCog, bc.defines.theme.channelCogFocused, bc.sidePanel.panels["Channel Settings"].animState ) )
        surface.SetMaterial( bc.defines.materials.cog )
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
    bc.channels.panels[data.name] = {
        panel = panel,
        text = richText,
        tab = v.Tab
    }
    function v.Tab:GetTabHeight() return 22 end
    v.Tab.data = data
    function v.Tab:Paint( w, h )
        local a = self:IsActive()
        local col = a and bc.defines.theme.foreground or bc.defines.theme.foregroundLight

        draw.RoundedBox( 0, 2, 0, w - 4, h, col )
        if self:GetText() ~= self.data.displayName then
            self:SetText( self.data.displayName )
            self:GetPropertySheet().tabScroller:InvalidateLayout( true ) -- to make the tabs resize correctly
            bc.channels.updateButtonPosition()
        end
    end
    function v.Tab:DoRightClick()
        local menu = DermaMenu()
        menu:AddOption( "Settings", function()
            local s = bc.sidePanel.panels["Channel Settings"]
            if s.isOpen and s.activePanel == self.data.name then
                bc.sidePanel.close( s.name )
            else
                bc.sidePanel.open( s.name, self.data.name )
            end
        end )
        if not self.data.disallowClose then
            menu:AddOption( "Close", function()
                bc.channels.close( self.data.name )
            end )
        end
        menu:Open()
    end

    function v.Tab:DoMiddleClick()
        if not self.data.disallowClose then
            bc.channels.close( self.data.name )
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

    bc.data.saveData()
    bc.channels.updateButtonPosition()

    if data.postAdd then data.postAdd( data, panel ) end

    for k, v in pairs( bc.sidePanel.channels.template ) do
        if v.onInit then
            v.onInit( data, richText )
        end
    end

    if not bc.base.isOpen then
        v.Tab:Hide()
    end

    if data.replicateAll then
        for k, v in ipairs( bc.mainChannels.allHistory or {} ) do
            bc.channels.messageDirect( data.name, { controller = true, doSound = false }, unpack( v ) )
        end
        bc.channels.scrollToBottom( data.name, true )
        return
    end

    if not data.hideInitMessage and bc.settings.getValue( "printChannelEvents" ) then
        local chanName = data.hideRealName and data.displayName or data.name

        local function createdPrint()
            bc.channels.messageDirect( data.name, bc.defines.colors.printBlue, "Channel ",
                bc.defines.theme.channels, chanName, bc.defines.colors.printBlue, " created." )

            if data.name ~= "All" then
                bc.channels.messageDirect( "All", bc.defines.colors.printBlue, "Channel ",
                    bc.defines.theme.channels, chanName, bc.defines.colors.printBlue, " created." )
            end
        end
        if bc.base.initializing then
            timer.Simple( 0, createdPrint ) -- Delay messages to allow other channels to be created before prints
        else
            createdPrint()
        end
    end
end

function bc.channels.focus( channel )
    local tabName
    if type( channel ) == "string" then
        tabName = channel
    else
        tabName = channel.name
    end
    for k, tab in pairs( bc.graphics.derma.psheet:GetItems() ) do
        if tab.Name == tabName then
            bc.graphics.derma.psheet:SetActiveTab( tab.Tab )
            bc.graphics.derma.psheet.tabScroller:ScrollToChild( tab.Tab )
        end
    end
end

function bc.channels.showPSheet()
    for k, v in pairs( bc.graphics.derma.psheet:GetItems() ) do
        v.Tab:Show()
        v.Panel.text:SetVerticalScrollbarEnabled( true )
        if not v.Panel.data.displayClosed then
            v.Panel:Show()
        end
        v.Panel.doPaint = true
    end
    bc.graphics.derma.psheet.tabScroller:InvalidateLayout( true ) --Psheets like to just fuck up their tabs
end

function bc.channels.hidePSheet()
    for k, v in pairs( bc.graphics.derma.psheet:GetItems() ) do
        v.Panel.text:UnselectText()
        v.Tab:Hide()
        v.Panel.text:scrollToBottom()
        v.Panel.text:SetVerticalScrollbarEnabled( false )
        if not v.Panel.data.displayClosed then
            v.Panel:Hide()
            v.Panel.doPaint = true
        else
            v.Panel.doPaint = false
            bc.graphics.derma.psheet:SetActiveTab( v.Tab )
        end
    end
end

function bc.channels.scrollToBottom( chanName, instant )
    local chan = bc.channels.get( chanName )

    if not chan or not bc.channels.isOpen( chanName ) then
        return
    end

    local rt = bc.channels.panels[chanName].text

    rt:scrollToBottom( instant )
end

function bc.channels.getOrCreate( chanName )
    local chan = bc.channels.get( chanName )

    if not chan then
        local dashPos = string.find( chanName, " - ", 1, true )
        if not dashPos then
            return bc.channels.get( "All" )
        end

        local nameType = string.sub( chanName, 1, dashPos - 1 )
        local nameArg = string.sub( chanName, dashPos + 3 )

        if nameType == "Group" and bc.group.allowed() then
            local id = tonumber( nameArg )
            local found = false
            for k, v in pairs( bc.group.groups ) do
                if v.id == id then
                    found = true
                    local chan = bc.group.createChannel( v )
                    if not chan then continue end
                    return chan
                end
            end
            if not found then return end
        elseif nameType == "Player" and bc.private.allowed() then
            local sId = nameArg
            local ply = player.GetBySteamID( sId )
            if not ply then return nil end
            return bc.private.createChannel( ply )
        else
            return bc.channels.get( "All" )
        end
    end

    return chan
end

function bc.channels.getAndOpen( chanName )
    local chan = bc.channels.getOrCreate( chanName )
    if not chan then return nil end

    bc.channels.open( chan.name )
    return chan
end
