function bc.sidePanel.renderSettingFuncs.options( sPanel, panel, data, y, w, h, setting )
    if not setting.optionValues then setting.optionValues = setting.options end
    local width = setting.overrideWidth or bc.sidePanel.defaultWidth
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
    comboBox.prevOptionValue = val

    function comboBox:Think()
        if self:IsMenuOpen() and not self.Menu.paintSet then
            self.Menu.paintSet = true
            local this = self
            function this.Menu:Paint( w, h )
                if not bc.base.isOpen then
                    self:GetParent():CloseMenu()
                end
                if not self:GetPaintBackground() then return end

                derma.SkinHook( "Paint", "Menu", self, w, h )
                return true
            end
        end
        if self.prevOptionValue ~= self.data[self.val] then
            for k = 1, #setting.optionValues do
                local v = setting.optionValues[k]
                if self.data[self.val] == v then
                    idx = k
                end
            end
            comboBox:ChooseOption( setting.options[idx], idx )

            self.prevOptionValue = self.data[self.val]
        end
    end

    function comboBox:OnSelect( idx, name, val )
        local changed = self.data[self.val] ~= val
        self.data[self.val] = val
        self.prevOptionValue = val

        if changed then
            if setting.onChange then setting.onChange( data ) end
            bc.data.saveData()
        end
    end

    return width
end
