function bc.sidePanel.renderSettingFuncs.boolean( sPanel, panel, data, y, w, h, setting )
    local checkBox = vgui.Create( "DCheckBox", panel )
    checkBox:SetPos( w - 16, y )
    checkBox:SetValue( data[setting.value] )
    checkBox:SetTooltip( setting.extra )

    function checkBox:Paint( w, h )
        local disabled = self:GetDisabled()
        local ticked = self:GetChecked()
        local c = disabled and 80 or 120
        draw.RoundedBox( 0, 0, 0, w, h, bc.defines.gray( c, 255 ) )
        draw.RoundedBox( 0, 2, 2, w - 4, h - 4, bc.defines.gray( c - 40, 255 ) )

        if ticked then
            if disabled then
                draw.RoundedBox( 0, 3, 3, w - 6, h - 6, ch.setA( bc.defines.theme.sidePanelCheckBox, 50 ) )
            else
                draw.RoundedBox( 0, 3, 3, w - 6, h - 6, bc.defines.theme.sidePanelCheckBox )
            end
        end
    end

    checkBox.data = data
    checkBox.val = setting.value
    checkBox.unique = setting.unique
    function checkBox:OnChange( val )
        local changed = self.data[self.val] ~= val
        if self.unique and val then
            for k, v in pairs( bc.channels.channels ) do
                v[self.val] = false
            end
        end
        self.data[self.val] = val
        if changed then
            if setting.onChange then setting.onChange( data ) end
            bc.data.saveData()
        end
    end
    if setting.unique then
        function checkBox:Think()
            self:SetValue( self.data[self.val] )
            self:SetDisabled( self.data[self.val] )
            self:SetCursor( self.data[self.val] and "no" or "hand" )
        end
    end

    return 16
end
