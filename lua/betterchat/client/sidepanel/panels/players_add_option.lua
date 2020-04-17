bc.sidePanel.players.extraSettings = {}

function bc.sidePanel.players.addCustomSetting( ply )
    local sx, sy = 400, 300
    local frame = vgui.Create( "DFrame" )
    frame:SetSize( sx, sy )
    frame:Center()
    frame:SetTitle( "Add new command" )
    frame:SetDraggable( false )
    frame:SetSizable( false )
    frame:MakePopup()
    frame:SetBackgroundBlur( true )

    --Action name
    local nameLabel = vgui.Create( "DLabel", frame )
    nameLabel:SetText( "Action name:" )
    nameLabel:SetPos( 15, 38 )
    nameLabel:SetSize( 80, 20 )
    function nameLabel:Paint( w, h )
        local tw, th = self:GetTextSize()
        draw.DrawText( self:GetText(), self:GetFont(), w - tw, 0, self:GetTextColor() )
        return true
    end

    local name = vgui.Create( "DTextEntry", frame )
    name:SetPos( 80 + 15 + 15, 35 )
    name:SetSize( 120, 20 )
    function name:AllowInput( c )
        local txt = self:GetText() .. c
        surface.SetFont( self:GetFont() )
        local x, y = surface.GetTextSize( txt )
        if x > self:GetWide() - 10 then return true end
    end
    name:RequestFocus()

    local nameErrorLabel = vgui.Create( "DLabel", frame )
    nameErrorLabel:SetText( "Name already taken" )
    nameErrorLabel:SetPos( 15 + 230, 38 )
    nameErrorLabel:SetSize( 120, 20 )
    nameErrorLabel.errorOpacity = 0
    function nameErrorLabel:Paint( w, h )
        local alpha = math.Clamp( self.errorOpacity, 0, 255 )
        draw.DrawText( self:GetText(), self:GetFont(), 0, 0, ch.setA( bc.defines.colors.red, alpha ) )
        return true
    end
    function nameErrorLabel:Think()
        if self.errorOpacity > 0 then
            self.errorOpacity = self.errorOpacity - 3
        else
            self.errorOpacity = 0
        end
    end

    --Command
    local commandLabel = vgui.Create( "DLabel", frame )
    commandLabel:SetText( "Command:" )
    commandLabel:SetPos( 15, 63 )
    commandLabel:SetSize( 80, 20 )
    function commandLabel:Paint( w, h )
        local tw, th = self:GetTextSize()
        draw.DrawText( self:GetText(), self:GetFont(), w - tw, 0, self:GetTextColor() )
        return true
    end

    local command = vgui.Create( "DTextEntry", frame )
    command:SetPos( 80 + 15 + 15, 60 )
    command:SetSize( sx - 110 - 20, 20 )
    command:SetTooltip( "Command to be run. [$name] will be replaced with player name, [$id] will be replaced with steam ID" )

    -- Tab from name to command
    function name:OnKeyCodeTyped( c )
        if c == KEY_TAB then
            command:RequestFocus()
            return true
        end
    end

    --Command options
    local commandOptionsLabel = vgui.Create( "DLabel", frame )
    commandOptionsLabel:SetText( "Command config:" )
    commandOptionsLabel:SetPos( 115, 83 )
    commandOptionsLabel:SetSize( 85, 20 )

    local quoteBox = vgui.Create( "DCheckBoxLabel", frame )
    quoteBox:SetPos( 115 + 85 + 10, 86 )
    quoteBox:SetText( "Name quotes" )
    quoteBox:SetTooltip( "Should names be encased in quotes (Only needed if used in chat)" )
    quoteBox:SetValue( 1 )

    local truncBox = vgui.Create( "DCheckBoxLabel", frame )
    truncBox:SetPos( 115 + 85 + 10, 106 )
    truncBox:SetText( "Name to first space" )
    truncBox:SetTooltip( "Should name be cut up to the first space" )
    truncBox:SetValue( 0 )

    --Players
    local playerTypeLabel = vgui.Create( "DLabel", frame )
    playerTypeLabel:SetText( "Targets:" )
    playerTypeLabel:SetPos( 15, 131 )
    playerTypeLabel:SetSize( 80, 20 )
    function playerTypeLabel:Paint( w, h )
        local tw, th = self:GetTextSize()
        draw.DrawText( self:GetText(), self:GetFont(), w - tw, 0, self:GetTextColor() )
        return true
    end

    local playerType = vgui.Create( "DComboBox", frame )
    playerType:SetPos( 80 + 15 + 15, 129 )
    playerType:SetSize( 120, 20 )
    playerType:AddChoice( "All" )
    playerType:AddChoice( "Rank(s)" )
    playerType:AddChoice( "Player(s)" )
    playerType:ChooseOption( "All", 1 )

    --PlayerType Lists

    local playersList = vgui.Create( "DListView", frame )
    playersList:SetMultiSelect( true )
    playersList:AddColumn( "Player" )
    for k, p in pairs( player.GetAll() ) do
        local line = playersList:AddLine( p:Nick(), p:SteamID() )
        if p == LocalPlayer() then line:SetSelected( true ) end
        function line:OnMousePressed( button )
            if button == MOUSE_LEFT then
                self:SetSelected( not self:IsSelected() ) --Fancy stuff to allow actual multi select (not requiring ctrl, or shift or whatever)
            end
        end
    end
    function playersList:OnClickLine() end -- This function is required, but I don't want it to do anything, thus empty implementation
    playersList:SetVerticalScrollbarEnabled( true )
    playersList:SetPos( 80 + 15 + 15, 154 )
    playersList:SetSize( sx - 110 - 20, 90 )
    playersList:Hide()

    local ranksList = vgui.Create( "DListView", frame )
    ranksList:SetMultiSelect( true )
    ranksList:AddColumn( "Rank" )
    for k, t in pairs( team.GetAllTeams() ) do
        local line = ranksList:AddLine( t.Name, t.Name )
        if t.Name == team.GetName( LocalPlayer():Team() ) then line:SetSelected( true ) end
        function line:OnMousePressed( button )
            if button == MOUSE_LEFT then
                self:SetSelected( not self:IsSelected() )
            end
        end
    end
    function ranksList:OnClickLine() end
    ranksList:SetVerticalScrollbarEnabled( true )
    ranksList:SetPos( 80 + 15 + 15, 154 )
    ranksList:SetSize( sx - 110 - 20, 90 )
    ranksList:Hide()

    local noOptions = vgui.Create( "DPanel", frame )
    noOptions:SetPos( 80 + 15 + 15, 154 )
    noOptions:SetSize( sx - 110 - 20, 90 )
    function noOptions:Paint( w, h )
        surface.SetDrawColor( bc.defines.gray( 200, 150 ) )
        surface.DrawOutlinedRect( 0, 0, w, h )
    end

    local noOptionsLabel = vgui.Create( "DLabel", noOptions )
    noOptionsLabel:SetText( "No Target Options" )
    noOptionsLabel:SizeToContents()
    noOptionsLabel:Center()

    --Finish playerType
    function playerType:OnSelect( index, value )
        playersList:Hide()
        ranksList:Hide()
        noOptions:Hide()
        if value == "Rank(s)" then
            ranksList:Show()
            ranksList:MoveToFront()
            ranksList:SetKeyboardInputEnabled( true )
        elseif value == "Player(s)" then
            playersList:Show()
            playersList:MoveToFront()
            playersList:SetKeyboardInputEnabled( true )
        else
            noOptions:Show()
        end
    end

    --Require confirm
    local confirmLabel = vgui.Create( "DLabel", frame )
    confirmLabel:SetText( "Require Confirm:" )
    confirmLabel:SetPos( 10, 249 )
    confirmLabel:SetSize( 85, 20 )
    function confirmLabel:Paint( w, h )
        local tw, th = self:GetTextSize()
        draw.DrawText( self:GetText(), self:GetFont(), w - tw, 0, self:GetTextColor() )
        return true
    end
    confirmLabel:SetTooltip( "Should the button require two clicks to runs" )

    local confirm = vgui.Create( "DCheckBox", frame )
    confirm:SetPos( 80 + 15 + 15, 249 )
    confirm:SetValue( 0 )
    confirm:SetTooltip( "Should the button require two clicks to runs" )

    --Add to player context
    local plyContextLabel = vgui.Create( "DLabel", frame )
    plyContextLabel:SetText( "Add to Player Context:" )
    plyContextLabel:SetPos( 230, 249 )
    plyContextLabel:SetSize( 120, 20 )
    function plyContextLabel:Paint( w, h )
        local tw, th = self:GetTextSize()
        draw.DrawText( self:GetText(), self:GetFont(), w - tw, 0, self:GetTextColor() )
        return true
    end
    plyContextLabel:SetTooltip( "Should this button show in the player right click menu" )

    local plyContext = vgui.Create( "DCheckBox", frame )
    plyContext:SetPos( sx - 20 - 15, 249 )
    plyContext:SetValue( 0 )
    plyContext:SetTooltip( "Should this button show in the player right click menu" )

    -- Cancel
    local cancelBtn = vgui.Create( "DButton", frame )
    cancelBtn:SetText( "Cancel" )
    cancelBtn:SetSize( 100, 20 )
    cancelBtn:SetPos( 5, sy - 25 )
    function cancelBtn:DoClick()
        frame:Close()
    end

    local createBtn = vgui.Create( "DButton", frame )
    createBtn:SetText( "Create" )
    createBtn:SetSize( 100, 20 )
    createBtn:SetPos( sx - 100 - 5, sy - 25 )
    function createBtn:DoClick()
        --first check name exists
        if string.Trim( name:GetText() ) == "" then
            nameErrorLabel.errorOpacity = 1000
            nameErrorLabel:SetText( "Must enter name" )
            return
        end

        --then check for unique name
        for k, v in pairs( bc.sidePanel.players.template ) do
            if v.name == name:GetText() then
                nameErrorLabel.errorOpacity = 1000
                nameErrorLabel:SetText( "Name already taken" )
                return
            end
        end


        local selected = {}
        local targType = playerType:GetValue()
        if targType == "Rank(s)" then
            selected = ranksList:GetSelected()
        elseif targType == "Player(s)" then
            selected = playersList:GetSelected()
        end
        for k = 1, #selected do
            selected[k] = selected[k]:GetColumnText( 2 )
        end
        bc.sidePanel.players.createCustomSetting( {
            name = name:GetText(),
            command = command:GetText(),
            config = {
                quotes = quoteBox:GetChecked(),
                trunc = truncBox:GetChecked(),
            },
            targetType = targType,
            selected = selected,
            require_confirm = confirm:GetChecked(),
            addToPlayerContext = plyContext:GetChecked(),
            call_ply = ply,
        }, true )
        frame:Close()
    end
end

function bc.sidePanel.players.createCustomSetting( data, userMade )
    --Convert command
    if table.hasMember( bc.sidePanel.players.template, "name", data.name ) then return end

    table.insert( bc.sidePanel.players.extraSettings, data )
    local cmd = data.command

    setting = {}
    setting.type = "button"
    setting.name = data.name
    setting.text = "Run"
    setting.extra = "Run custom command \"" .. setting.name .. "\""
    setting.targetType = data.targetType
    setting.targets = data.selected

    setting.requireConfirm = data.require_confirm

    setting.customCommand = data.command
    setting.addToPlayerContext = data.addToPlayerContext

    function setting.onClick( d, setting )
        local ply = d.ply
        local cmdPlyExplode = string.Explode( "[$name]", setting.customCommand )
        local str = ""

        local name = ply:Nick()
        name = string.Explode( ";", name )[1]
        if data.config.trunc then
            name = string.Explode( " ", name )[1]
        end
        if data.config.quotes then
            name = "\"" .. name .. "\""
        end
        for k = 1, #cmdPlyExplode - 1 do
            str = str .. cmdPlyExplode[k] .. name
        end
        str = str .. cmdPlyExplode[#cmdPlyExplode]

        local cmdPlyExplode = string.Explode( "[$id]", str )
        local id = ply:SteamID()
        if data.config.quotes then
            id = "\"" .. id .. "\""
        end
        str = ""
        for k = 1, #cmdPlyExplode - 1 do
            str = str .. cmdPlyExplode[k]

            str = str .. id
        end
        str = str .. cmdPlyExplode[#cmdPlyExplode]
        LocalPlayer():ConCommand( str )
    end

    function setting.onRightClick( ply, setting )
        local m = DermaMenu()
        m:AddOption( "Remove", function()
            table.RemoveByValue( bc.sidePanel.players.template, setting )
            for k, v in pairs( bc.sidePanel.players.extraSettings ) do
                if v.name == setting.name then
                    table.remove( bc.sidePanel.players.extraSettings, k )
                    break
                end
            end

            local openPlyId = bc.sidePanel.panels["Player"].activePanel
            local openPly = player.GetBySteamID( openPlyId )

            bc.sidePanel.players.removeAllEntries()

            if openPly then
                bc.sidePanel.players.generateEntry( openPly )
                bc.sidePanel.show( "Player", openPly:SteamID() )
            else
                bc.sidePanel.close( "Player", true )
            end
            bc.data.saveData()
        end )
        m:AddOption( setting.addToPlayerContext and "Remove from Player Context" or "Add to Player Context", function()
            setting.addToPlayerContext = not setting.addToPlayerContext
        end )
        m:Open()
    end

    function setting.extraCanRun( ply, setting )
        if setting.targetType == "Rank(s)" then
            return table.HasValue( setting.targets, team.GetName( ply:Team() ) )
        elseif setting.targetType == "Player(s)" then
            return table.HasValue( setting.targets, ply:SteamID() )
        end
        return true
    end

    table.insert( bc.sidePanel.players.template, 1, setting )

    if userMade then
        bc.sidePanel.players.removeAllEntries()

        if data.call_ply then
            bc.sidePanel.players.generateEntry( data.call_ply )
            bc.sidePanel.show( "Player", data.call_ply:SteamID() )
        end

        bc.data.saveData()
    end
end
