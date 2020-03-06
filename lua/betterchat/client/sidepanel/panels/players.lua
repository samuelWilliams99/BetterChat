include( "betterchat/client/sidepanel/templates/playersettings.lua" )
include( "betterchat/client/sidepanel/panels/players_add_option.lua" )

chatBox.playerSettings = {}

net.Receive( "BC_sendPlayerState", function()
    local t = net.ReadString()
    local ply = net.ReadEntity()
    if not ply or not ply:IsValid() then return end
    local state = net.ReadBool()
    if chatBox.playerSettings and chatBox.playerSettings[ply:SteamID()] then
        chatBox.playerSettings[ply:SteamID()][t] = state
    end
end )

hook.Add( "BC_InitPanels", "BC_InitSidePanelPlayers", function()
    local g = chatBox.graphics
    chatBox.createSidePanel( "Player", 300, { icon = "icon16/group.png", border = 1 } )
    ownRank = team.GetName( LocalPlayer() )
end )

net.Receive( "BC_UserRankChange", function()
    chatBox.closeChatBox()
    chatBox.removeAllPlayerPanels()
    hook.Run( "BC_UserAccessChange" )
end )

function chatBox.generatePlayerPanelEntry( ply )
    if not ply then return end
    if not chatBox.playerSettings[ply:SteamID()] then
        chatBox.playerSettings[ply:SteamID()] = { needsData = true }
    end

    local plySettings = chatBox.playerSettings[ply:SteamID()]

    if plySettings.needsData then 
        for idx, v in pairs( chatBox.playerSettingsTemplate ) do
            if not v.value then continue end
            if plySettings[v.value] == nil then
                plySettings[v.value] = v.default
            end
        end
        plySettings.dataChanged = plySettings.dataChanged or {}
    end

    --chatBox.removeFromSidePanel("Player", ply:SteamID()) --Attempt remove
    plySettings.ply = ply

    local p = chatBox.addToSidePanel( "Player", ply:SteamID() )
    local w, h = p:GetSize()
    local avatar = vgui.Create( "AvatarImageCircle", p )
    avatar:SetSize( 64, 64 )
    --avatar:SetPos( (w - 32) / 2 - 32 + 6, 4 )
    avatar:SetPos( 4, 4 )
    avatar:SetPlayer( ply )
    avatar.Avatar.OnMousePressed = function( self, keyCode )
        if keyCode == MOUSE_LEFT then
            ply:ShowProfile()
        end
    end
    avatar.Avatar:SetCursor( "hand" )

    local vLine = vgui.Create( "DShape", p )
    vLine:SetType( "Rect" )
    vLine:SetSize( 1, 48 )
    vLine:SetPos( 76, 4 + 8 )
    vLine:SetColor( Color( 150, 150, 150, 250 ) )

    local bg = vgui.Create( "DShape", p )
    bg:SetType( "Rect" )
    bg:SetSize( 130, 48 )
    bg:SetPos( 77, 4 + 8 )
    bg.Paint = function( self, w, h )
        surface.SetMaterial( chatBox.materials.getMaterial( "vgui/gradient-l" ) )
        surface.SetDrawColor( 100, 100, 100, 200 )
        surface.DrawTexturedRect( 0, 0, w, h )

        surface.SetDrawColor( 150, 150, 150, 200 )
        surface.DrawTexturedRect( 0, h / 2, w, 1 )
    end


    local nameLabel = vgui.Create( "DComboBox", p )
    nameLabel:SetFont( chatBox.graphics.font )
    nameLabel:SetTextColor( Color( 220, 220, 220, 255 ) )
    nameLabel:SetSize( w - 32 - 70, 20 )
    nameLabel:SetPos( 80, 14 )
    nameLabel.Paint = nil
    nameLabel.lp = {}
    nameLabel.ownID = 1
    nameLabel.Think = function( self )
        local plys = player.GetAll()
        local GetName = getmetatable( plys[1] ).GetName
        if diff( self.lp, plys ) or diff( map( plys, GetName ), self.Choices ) then
            self.lp = plys
            self:Clear()
            for k, p in pairs( player.GetAll() ) do
                self:AddChoice( p:GetName(), p )
                if p == ply then
                    self:ChooseOptionID( k )
                    self.ownID = k
                end
            end
        end
    end

    nameLabel.id = ply:SteamID()
    nameLabel.OnMousePressed = function( self, keyCode )
        if keyCode == MOUSE_RIGHT then
            SetClipboardText( self.id )
        elseif keyCode == MOUSE_LEFT then
            self:DoClick()
        end
    end

    nameLabel.OnSelect = function( self, idx, value, data )
        self:SetText( ply:GetName() )
        local p = data
        local id = p:SteamID()
        if not chatBox.panelExists( "Player", id ) then
            chatBox.generatePlayerPanelEntry( p )
        end

        chatBox.openSidePanel( "Player", id )

    end


    local rankLabel = vgui.Create( "DLabel", p )
    rankLabel:SetText( team.GetName( ply:Team() ) )
    rankLabel:SetFont( chatBox.graphics.font )
    rankLabel:SetColor( team.GetColor( ply:Team() ) )
    rankLabel:SetSize( w - 32 - 88, 20 )
    rankLabel:SetPos( 88, 38 )
    rankLabel:SetMouseInputEnabled( true )
    rankLabel.ply = ply
    if ULib then
        rankLabel:SetTooltip( "ULX Rank: " .. ply:GetUserGroup() )
        rankLabel.uRank = ply:GetUserGroup()
    end
    rankLabel.Think = function( self )
        local ply = self.ply
        if not ply or not ply:IsValid() then return end
        local rank = team.GetName( ply:Team() )
        if rank ~= self:GetText() then
            self:SetText( rank )
            self:SetColor( team.GetColor( ply:Team() ) )
        end
        if ULib then
            local uRank = ply:GetUserGroup()
            if self.uRank ~= uRank then
                rankLabel:SetTooltip( "ULX Rank: " .. ply:GetUserGroup() )
            end
        end
    end

    local hLine = vgui.Create( "DShape", p )
    hLine:SetType( "Rect" )
    hLine:SetSize( w - 32 - 2, 7 )
    hLine:SetPos( 4, 4 + 64 + 8 )
    hLine:SetColor( Color( 150, 150, 150, 250 ) )
    hLine.Paint = function( self, w, h )
        surface.SetDrawColor( 150, 150, 150, 200 )
        surface.DrawRect( 0, 0, w, 1 )

        surface.SetMaterial( chatBox.materials.getMaterial( "vgui/gradient-u" ) )
        surface.SetDrawColor( 60, 60, 60, 150 )
        surface.DrawTexturedRect( 0, 1, w, h - 1 )
    end

    local data = chatBox.playerSettings[ply:SteamID()]

    local k = 3.7 -- weird number simple used for positioning, not index
    local settingsAdded = {}
    for idx, v in pairs( chatBox.playerSettingsTemplate ) do
        if not chatBox.canAddPlayerSetting( ply, v, settingsAdded ) then continue end
        table.insert( settingsAdded, v.name )
        chatBox.renderSetting( p, data, v, k )
        k = k + 1
    end
end

function chatBox.canAddPlayerSetting( ply, setting, settingsAdded )
    settingsAdded = settingsAdded or {}
    if setting.command and not chatBox.canRunULX( setting.command, ply ) then return false end
    if setting.extraCanRun and not setting.extraCanRun( ply, setting ) then return false end
    if setting.parentSetting then
        if not table.HasValue( settingsAdded, setting.parentSetting ) then
            return false
        end    
    end
    return true
end

function chatBox.removePlayerPanel( id )
    if not chatBox.playerSettings[id] then return end

    if chatBox.sidePanels["Player"].isOpen and chatBox.sidePanels["Player"].activePanel == id then
        chatBox.closeSidePanel( "Player", true )
    end

    local panels = chatBox.sidePanels["Player"].graphics.panels
    local idx = -1
    for k, v in pairs( panels ) do
        if v.Name == id then
            idx = k
        end
    end
    if idx ~= -1 then
        local panel = table.remove( panels, idx )
        panel.Panel:Remove()
    end
end

function chatBox.removeAllPlayerPanels()
    local panels = chatBox.sidePanels["Player"].graphics.panels
    for k, v in pairs( panels ) do
        v.Panel:Remove()
    end
    chatBox.sidePanels["Player"].graphics.panels = {}
end

function diff( a, b )
    if #a ~= #b then
        return true
    end
    for k, v in pairs( a, b ) do
        if a[k] ~= b[k] then
            return true
        end
    end
    return false
end

function map( input, f )
    local out = {}
    for k, v in pairs( input ) do
        out[k] = f( v )
    end
    return out
end