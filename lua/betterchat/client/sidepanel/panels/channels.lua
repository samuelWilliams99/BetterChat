include( "betterchat/client/sidepanel/templates/channelsettings.lua" )

hook.Add( "BC_InitPanels", "BC_InitSidePanelChannels", function()
    local g = chatBox.graphics
    chatBox.createSidePanel( "Channel Settings", 300, { icon = "icons/cog.png", rotate = true, col = Color( 50, 50, 50, 210 ) } )
end )

function chatBox.generateChannelSettings( sPanel, data )
    local canvas = sPanel:GetCanvas()
    local w, h = sPanel:GetSize()
    local icon = vgui.Create( "DImage", canvas )
    icon:SetImage( "icon16/" .. data.icon )
    icon:SetSize( 16, 16 )
    icon:SetPos( 2, 1 )

    local line = vgui.Create( "DShape", canvas )
    line:SetType( "Rect" )
    line:SetPos( 2, 22 )
    line:SetSize( w - 29, 2 )
    line:SetColor( Color( 180, 180, 180, 200 ) )

    local title = vgui.Create( "DLabel", canvas )
    title:SetPos( 24, 0 )
    title:SetFont( chatBox.graphics.font )
    title:SetText( data.displayName )
    title:SizeToContents()
    title.data = data
    title.Think = function( self )
        if self.data.name ~= self.data.displayName and not self.data.hideRealName then
            self:SetText( self.data.displayName .. " (" .. self.data.name .. ")" )
        else
            self:SetText( self.data.displayName )
        end
        title:SizeToContents()
    end

    local k = 1
    for idx, v in pairs( chatBox.channelSettingsTemplate ) do
        if data.disabledSettings and table.HasValue( data.disabledSettings, v.value ) then continue end
        if v.shouldAdd then if not v.shouldAdd( data ) then return end end

        chatBox.renderSetting( sPanel, data, chatBox.channelSettingsTemplate[idx], k )
        k = k + 1
    end

end

function chatBox.applyDefaults( data )
    for k, v in pairs( chatBox.channelSettingsTemplate ) do
        if data[v.value] == nil then data[v.value] = v.default end
    end
end

function chatBox.reloadChannelSettings( data )
    local pName = "Channel Settings"
    if chatBox.getSidePanelChild( pName, data.name ) then
        chatBox.removeFromSidePanel( pName, data.name, true )
        local p = chatBox.addToSidePanel( pName, data.name )
        chatBox.generateChannelSettings( p, data )
        if chatBox.sidePanels[pName].activePanel == data.name then
            chatBox.showSidePanel( pName, data.name )
        end
    end
end