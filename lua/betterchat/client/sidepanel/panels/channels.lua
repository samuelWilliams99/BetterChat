bc.sidePanel.channels = {}
include( "betterchat/client/sidepanel/templates/channelsettings.lua" )

hook.Add( "BC_initPanels", "BC_initSidePanelChannels", function()
    bc.sidePanel.create( "Channel Settings", 300, {
        icon = bc.defines.materials.cog,
        rotate = true,
        col = bc.defines.theme.channelCogFocused
    } )
end )

function bc.sidePanel.channels.generateSettings( sPanel, data )
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
    line:SetColor( bc.defines.theme.sidePanelAccent )

    local title = vgui.Create( "DLabel", canvas )
    title:SetPos( 24, 0 )
    title:SetFont( bc.graphics.font )
    title:SetText( data.displayName )
    title:SizeToContents()
    title.data = data
    function title:Think()
        if self.data.name ~= self.data.displayName and not self.data.hideRealName then
            self:SetText( self.data.displayName .. " (" .. self.data.name .. ")" )
        else
            self:SetText( self.data.displayName )
        end
        title:SizeToContents()
    end

    local k = 1
    for idx, v in pairs( bc.sidePanel.channels.template ) do
        if data.disabledSettings and table.HasValue( data.disabledSettings, v.value ) then continue end
        if v.shouldAdd then if not v.shouldAdd( data ) then return end end

        bc.sidePanel.renderSetting( sPanel, data, bc.sidePanel.channels.template[idx], k )
        k = k + 1
    end

end

function bc.sidePanel.channels.applyDefaults( data )
    for k, v in pairs( bc.sidePanel.channels.template ) do
        if data[v.value] == nil then data[v.value] = v.default end
    end
end

function bc.sidePanel.channels.reloadSettings( data )
    local pName = "Channel Settings"
    if bc.sidePanel.getChild( pName, data.name ) then
        bc.sidePanel.removeChild( pName, data.name, true )
        local p = bc.sidePanel.createChild( pName, data.name )
        bc.sidePanel.channels.generateSettings( p, data )
        if bc.sidePanel.panels[pName].activePanel == data.name then
            bc.sidePanel.show( pName, data.name )
        end
    end
end
