function chatBox.sidePanel.renderSettingFuncs.options( sPanel, panel, data, y, w, h, setting )
    if not setting.optionValues then setting.optionValues = setting.options end
    local width = setting.overrideWidth or chatBox.sidePanel.defaultWidth
    local comboBox = vgui.Create( "DComboBox", panel )
    comboBox:SetSortItems( false )
    comboBox:SetPos( w - width, y - 2 )
    comboBox:SetSize( width, 18 )
    comboBox:SetTooltip( setting.extra )
    comboBox:SetDisabled( setting.disabled or false )

    local options = setting.options
    for k = 1, #options do
        comboBox:AddChoice( options[k], setting.optionValues[k] )
    end
    local val = data[setting.value]
    local idx
    for k = 1, #setting.optionValues do
        local v = setting.optionValues[k]
        if val == v then
            idx = k
        end
    end

    if not idx then return width end -- should never happen (somehow its value isnt one of the options)

    comboBox:ChooseOption( options[idx], idx )

    comboBox.data = data
    comboBox.val = setting.value
    comboBox.setting = setting

    function comboBox:Think()
        if self.data.dataChanged[self.val] then
            local setting = self.setting
            local val = self.data[self.val]
            local idx
            for k = 1, #setting.optionValues do
                local v = setting.optionValues[k]
                if val == v then
                    idx = k
                end
            end

            self:ChooseOption( setting.options[idx], idx )
            self.data.dataChanged[self.val] = false
        end
        if self:IsMenuOpen() and not self.Menu.paintSet then
            self.Menu.paintSet = true
            local this = self
            function this.Menu:Paint( w, h )
                if not chatBox.base.isOpen then
                    self:GetParent():CloseMenu()
                end
                if ( !self:GetPaintBackground() ) then return end

                derma.SkinHook( "Paint", "Menu", self, w, h )
                return true
            end
        end
    end

    function comboBox:OnSelect( idx, name, val )
        local changed = self.data[self.val] ~= val
        self.data[self.val] = val

        if changed then
            if setting.onChange then setting.onChange( data ) end
            chatBox.data.saveData()
        end
    end

    return width
end
