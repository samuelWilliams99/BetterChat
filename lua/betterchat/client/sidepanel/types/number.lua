function bc.sidePanel.renderSettingFuncs.number( sPanel, panel, data, y, w, h, setting )
    local entryWidth = setting.overrideWidth or 35

    local numberEntry = vgui.Create( "DNumberEntry", panel )
    numberEntry:SetName( "BC_settingsEntry" )
    numberEntry:SetPos( w - entryWidth, y - 1 )
    numberEntry:SetSize( entryWidth, 18 )
    numberEntry:SetTooltip( setting.extra )
    numberEntry:SetUpdateOnType( false )
    numberEntry:SetDisabled( setting.disabled or false )
    numberEntry:SetDefault( data[setting.value] )

    numberEntry:SetMin( setting.min or 0 )
    numberEntry:SetMax( setting.max or 100 )

    numberEntry:SetValue( data[setting.value] )
    
    numberEntry.data = data
    numberEntry.val = setting.value

    function numberEntry:OnValueChanged( val )
        self:SetDefault( val )
        self.data[self.val] = val

        if setting.onChange then setting.onChange( data ) end
        bc.data.saveData()
    end
    function numberEntry:OnLoseFocus() self:OnValueChange( self:GetText() ) end

    return entryWidth
end
