function chatBox.sidePanel.renderSettingFuncs.key( sPanel, panel, data, y, w, h, setting )
    local textEntry = vgui.Create( "DTextEntry", panel )
    textEntry:SetName( "BC_settingsKeyEntry" )
    textEntry:SetPos( w - chatBox.sidePanel.defaultWidth, y - 1 )
    textEntry:SetSize( chatBox.sidePanel.defaultWidth, 18 )
    textEntry:SetFont( "BC_monospace" )
    textEntry:SetDisabled( setting.disabled or false )

    textEntry:SetText( "" )
    textEntry:SetPlaceholderText( data[setting.value] and input.GetKeyEnum( data[setting.value] ) or "NOT SET" )

    textEntry:SetTooltip( setting.extra )
    textEntry:SetUpdateOnType( true )

    textEntry.data = data
    textEntry.val = setting.value
    function textEntry:Think()
        if self.data.dataChanged[self.val] then
            self:SetPlaceholderText( self.data[self.val] and input.GetKeyEnum( self.data[self.val] ) or "NOT SET" )
            self.data.dataChanged[self.val] = false
        end
    end
    function textEntry:OnKeyCodeTyped( val )
        if val ~= KEY_ESCAPE then
            if val == KEY_BACKSPACE then
                self.data[self.val] = nil
                self:SetPlaceholderText( "NOT SET" )
            else
                self.data[self.val] = val
                self:SetPlaceholderText( input.GetKeyEnum( val ) )
            end
            if setting.onChange then setting.onChange( data ) end
            chatBox.data.saveData()
        else
            self:SetPlaceholderText( self.data[self.val] and input.GetKeyEnum( self.data[self.val] ) or "NOT SET" )
        end
        self:KillFocus()
        chatBox.graphics.derma.textEntry:RequestFocus()
    end
    function textEntry:OnFocusChanged( gained )
        if gained then
            self:SetPlaceholderText( "Press key" )
        else
            self:SetPlaceholderText( self.data[self.val] and input.GetKeyEnum( self.data[self.val] ) or "NOT SET" )
        end
    end
    function textEntry:AllowInput( char )
        return true
    end

    return chatBox.sidePanel.defaultWidth
end
