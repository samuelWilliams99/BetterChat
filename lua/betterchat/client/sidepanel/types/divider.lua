function bc.sidePanel.renderSettingFuncs.catDivider( sPanel, panel, data, y, w, h, setting )
    local width = setting.overrideWidth or bc.sidePanel.defaultWidth
    local label = vgui.Create( "DLabel", panel )
    label:SetText( setting.name )
    label:SetTextColor( bc.defines.theme.sidePanelCheckBox )
    label:SizeToContents()

    local tw, th = label:GetTextSize()
    local startX = w - width
    local textX = startX + ( width - tw ) / 2
    label:SetPos( textX, y )

    local leftLine = vgui.Create( "DShape", panel )
    leftLine:SetType( "Rect" )
    leftLine:SetColor( bc.defines.theme.sidePanelCheckBox )
    leftLine:SetSize( ( width - tw - 10 ) / 2, 1 )
    leftLine:SetPos( startX, y + 7 )

    local rightLine = vgui.Create( "DShape", panel )
    rightLine:SetType( "Rect" )
    rightLine:SetColor( bc.defines.theme.sidePanelCheckBox )
    local rightLineWidth = ( width - tw - 10 ) / 2
    rightLine:SetSize( rightLineWidth, 1 )
    rightLine:SetPos( w - rightLineWidth, y + 7 )

    return 0
end
