local function openColorMixer( data, setting )
    local btnH = 20
    local w, h = 267, 186 + btnH
    local mixerFrame = vgui.Create( "DFrame" )

    mixerFrame:SetTitle( "" )
    mixerFrame:SetSize( w, h )
    mixerFrame:SetPos( gui.MouseX(), gui.MouseY() - h )
    mixerFrame:MakePopup()
    mixerFrame:SetDraggable( false )
    mixerFrame:ShowCloseButton( false )
    mixerFrame:SetIsMenu( true )

    local mixer -- Init here so mixerFrame can grab it

    function mixerFrame:Paint( w, h )
        bc.util.blur( self, 10, 20, 255 )
        draw.RoundedBox( 0, 0, 0, w, h, bc.defines.theme.background )
    end

    function mixerFrame:Think()
        if not bc.base.isOpen then
            self:Remove()
        end
    end

    function mixerFrame:OnRemove()
        timer.Remove( "BC_colorHideTimer" )
    end

    mixer = vgui.Create( "DColorMixer", mixerFrame )
    mixer:SetPos( 2, 2 )
    mixer:SetSize( w - 4, h - 4 - btnH )
    mixer:SetColor( table.Copy( data[setting.value] ) )
    mixer:SetPalette( false )
    mixer:SetAlphaBar( data.allowedAlpha )

    local lastDown = false
    timer.Create( "BC_colorHideTimer", 1 / 30, 0, function()
        if not input.IsMouseDown( MOUSE_LEFT ) and not input.IsMouseDown( MOUSE_RIGHT ) then
            lastDown = false
            return
        end
        if lastDown then return end
        lastDown = true
        local mx, my = gui.MousePos()
        if not Vector( mx, my ):WithinAABox( Vector( mixerFrame:LocalToScreen( 0, 0 ) ), Vector( mixerFrame:LocalToScreen( w, h ) ) ) then
            mixerFrame:Remove()
        end
    end )

    local backBtn = vgui.Create( "DButton", mixerFrame )
    backBtn:SetText( "Back" )
    backBtn:SetSize( 87, btnH - 2 )
    backBtn:SetPos( 2, h - btnH )
    function backBtn:DoClick()
        mixerFrame:Remove()
    end

    local defaultBtn = vgui.Create( "DButton", mixerFrame )
    defaultBtn:SetText( "Default" )
    defaultBtn:SetSize( 87, btnH - 2 )
    defaultBtn:SetPos( w / 2 - 40, h - btnH )
    function defaultBtn:DoClick()
        if data.defaults and data.defaults[setting.value] then
            mixer:SetColor( table.Copy( data.defaults[setting.value] ) )
        else
            mixer:SetColor( table.Copy( setting.default ) )
        end

    end

    local confirmBtn = vgui.Create( "DButton", mixerFrame )
    confirmBtn:SetText( "Confirm" )
    confirmBtn:SetSize( 81, btnH - 2 )
    confirmBtn:SetPos( w - 80 - 3, h - btnH )
    function confirmBtn:DoClick()
        if data[setting.value] ~= mixer:GetColor() then
            data[setting.value] = table.Copy( mixer:GetColor() )
            if setting.onChange then setting.onChange( data ) end
            bc.data.saveData()
        end
        mixerFrame:Remove()
    end
end

function bc.sidePanel.renderSettingFuncs.color( sPanel, panel, data, y, w, h, setting )
    local curCol = data[setting.value]
    local width = setting.overrideWidth or bc.sidePanel.defaultWidth
    local allowedAlpha = setting.allowAlpha

    local button = vgui.Create( "DColorButton", panel )

    button:SetDisabled( setting.disabled or false )

    local bw, bh = width, 18
    button:SetSize( bw, bh )
    button:SetPos( w - bw, y - 2 )
    button:SetFont( "BC_monospaceSmall" )
    button:SetTooltip( setting.extra )
    button:SetColor( data[setting.value], true )

    function button:Paint( w, h )
        local col = self:GetColor()
        draw.RoundedBox( 2, 0, 0, w, h, bc.defines.colors.black )
        draw.RoundedBox( 2, 1, 1, w - 2, h - 2, col )
        draw.DrawText( self:GetText(), self:GetFont(), w / 2, h / 4, bc.defines.theme.buttonTextFocused, TEXT_ALIGN_CENTER )
        return true
    end
    function button:DoClick()
        CloseDermaMenus()
        openColorMixer( data, setting )
    end

    function button:Think()
        self:SetColor( data[setting.value], true )
        local col = data[setting.value]
        self:SetText( chatHelper.padString( col.r, 3, nil, true ) ..
            "|" .. chatHelper.padString( col.g, 3, nil, true ) ..
            "|" .. chatHelper.padString( col.b, 3, nil, true ) ..
            ( allowedAlpha and ( "|" .. chatHelper.padString( col.a, 3, nil, true ) ) or "" )
        )
        self:SetCursor( self:GetDisabled() and "no" or "hand" )
    end

    return bw
end
