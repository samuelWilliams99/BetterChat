function bc.sidePanel.renderSettingFuncs.string( sPanel, panel, data, y, w, h, setting )
    local textEntry = vgui.Create( "DTextEntry", panel )
    textEntry:SetName( "BC_settingsEntry" )
    textEntry:SetPos( w - bc.sidePanel.defaultWidth, y - 1 )
    textEntry:SetSize( bc.sidePanel.defaultWidth, 18 )
    textEntry:SetText( data[setting.value] )
    textEntry:SetTooltip( setting.extra )
    textEntry:SetUpdateOnType( false )
    textEntry:SetDisabled( setting.disabled or false )

    textEntry.data = data
    textEntry.val = setting.value
    textEntry.limit = setting.limit
    textEntry.trim = setting.trim

    function textEntry:OnValueChange( val )
        if self.trim then
            val = string.Trim( val )
        end
        if #val == 0 then
            self:SetText( self.data[self.val] )
        else
            self.data[self.val] = val
        end
        if setting.onChange then setting.onChange( data ) end
        bc.data.saveData()
    end
    function textEntry:OnLoseFocus() self:OnValueChange( self:GetText() ) end
    function textEntry:AllowInput( char )
        local txt = self:GetText()
        if self.trim then
            if #txt < 1 and char == " " then
                return true
            end
        end
        if self.limit then
            if #txt == self.limit then
                return true
            end
        end
        return false
    end


    return bc.sidePanel.defaultWidth
end
