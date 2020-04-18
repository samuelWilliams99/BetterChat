function bc.sidePanel.renderSettingFuncs.button( sPanel, panel, data, y, w, h, setting )
    local button = vgui.Create( "DButton", panel )
    local width = setting.overrideWidth or bc.sidePanel.defaultWidth

    local confirm = setting.requireConfirm

    button:SetText( setting.text )
    button:SetDisabled( setting.disabled or false )

    local bw, bh = width, 18
    button:SetSize( bw, bh )
    button:SetPos( w - bw, y - 2 )
    button:SetTooltip( setting.extra )
    button.setting = setting
    button.data = data
    button.confirm = confirm
    button.lastClick = 0
    function button:DoClick()
        if not self.confirm or ( CurTime() - self.lastClick < 2 ) then
            self.setting.onClick( self.data, self.setting )
            self.lastClick = 0
            if self.setting.closeOnTrigger then
                --TODO: Close here, might not be needed tho, literally only for kicking bots via the menu
            end
        else
            self.lastClick = CurTime()
        end
    end

    function button:Think()
        if self.confirm and CurTime() - self.lastClick < 2 then
            self:SetText( "CONFIRM" )
            self:SetTextColor( bc.defines.colors.red )
        else
            if self.setting.toggle then
                self:SetText( self.data[self.setting.value] and self.setting.toggleText or self.setting.text )
            else
                self:SetText( self.setting.text )
            end
            self:SetTextColor( bc.defines.colors.black )
        end
    end

    function button:DoRightClick()
        if setting.onRightClick then
            setting.onRightClick( data.ply, setting )
        end
    end

    return bw
end
