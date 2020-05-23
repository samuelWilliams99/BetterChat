bc.sidePanel.players = {}
include( "betterchat/client/sidepanel/templates/playersettings.lua" )
include( "betterchat/client/sidepanel/panels/players_add_option.lua" )

bc.sidePanel.players.settings = {}

net.Receive( "BC_sendPlayerState", function()
    local t = net.ReadString()
    local ply = net.ReadEntity()
    if not ply or not ply:IsValid() then return end
    local state = net.ReadBool()
    if bc.sidePanel.players.settings and bc.sidePanel.players.settings[ply:SteamID()] then
        bc.sidePanel.players.settings[ply:SteamID()][t] = state
    end
end )

hook.Add( "BC_initPanels", "BC_initSidePanelPlayers", function()
    bc.sidePanel.create( "Player", 300, {
        icon = bc.defines.materials.group,
        border = 1
    } )
end )

net.Receive( "BC_userRankChange", function()
    local openPanelPly
    if bc.sidePanel.panels["Player"].isOpen then
        local id = bc.sidePanel.panels["Player"].activePanel
        openPanelPly = player.GetBySteamID( id )

        if not openPanelPly then
            bc.sidePanel.close( "Player", true )
        end
    end

    bc.sidePanel.players.removeAllEntries()
    if openPanelPly then
        bc.sidePanel.players.generateEntry( openPanelPly )
        bc.sidePanel.open( "Player", openPanelPly:SteamID() )
    end

    hook.Run( "BC_userAccessChange" )
end )

function bc.sidePanel.players.applyDefaults( data )
    for k, v in pairs( bc.sidePanel.players.template ) do
        if not v.value then continue end
        if data[v.value] == nil then data[v.value] = v.default end
    end
end

function bc.sidePanel.players.generateEntry( ply )
    if not ply or not IsValid( ply ) or not ply.SteamID then return end

    local plySettings = bc.sidePanel.players.settings[ply:SteamID()]
    if not plySettings then
        plySettings = {}
        plySettings.ply = ply
        bc.data.loadPlayer( plySettings )
        bc.sidePanel.players.applyDefaults( plySettings )

        bc.sidePanel.players.settings[ply:SteamID()] = plySettings
    else
        plySettings.ply = ply
    end

    local p = bc.sidePanel.createChild( "Player", ply:SteamID() )
    local w, h = p:GetSize()

    -- My credit :D
    if ply:SteamID64() == "76561198053582133" then
        local creditLabel = vgui.Create( "DLabel", p )
        creditLabel:SetText( "Creator of BetterChat!" )
        creditLabel:SizeToContents()
        local textW, textH = creditLabel:GetTextSize()
        creditLabel:SetPos( w - textW - 28, -2 )
        creditLabel:SetTextColor( bc.defines.theme.betterChat )
    end

    local avatar = vgui.Create( "AvatarImageCircle", p )
    avatar:SetSize( 64, 64 )
    avatar:SetPos( 4, 4 )
    avatar:SetPlayer( ply )
    avatar:SetClickable( true )

    local vLine = vgui.Create( "DShape", p )
    vLine:SetType( "Rect" )
    vLine:SetSize( 1, 48 )
    vLine:SetPos( 76, 4 + 8 )
    vLine:SetColor( bc.defines.theme.sidePanelAccent )

    local bg = vgui.Create( "DShape", p )
    bg:SetType( "Rect" )
    bg:SetSize( 130, 48 )
    bg:SetPos( 77, 4 + 8 )
    function bg:Paint( w, h )
        surface.SetMaterial( bc.defines.materials.gradientLeft )
        surface.SetDrawColor( bc.defines.theme.sidePanelForeground )
        surface.DrawTexturedRect( 0, 0, w, h )

        surface.SetDrawColor( bc.defines.theme.sidePanelAccent )
        surface.DrawTexturedRect( 0, h / 2, w, 1 )
    end


    local nameLabel = vgui.Create( "DComboBox", p )
    nameLabel:SetFont( bc.graphics.font )
    nameLabel:SetTextColor( bc.defines.colors.white )
    nameLabel:SetSize( w - 32 - 70, 20 )
    nameLabel:SetPos( 80, 14 )
    nameLabel.Paint = nil
    nameLabel.lp = {}
    nameLabel.ownID = 1
    function nameLabel:Think()
        local plys = player.GetAll()
        local Nick = FindMetaTable( "Player" ).Nick
        -- If players list has changed or any player names have changed
        -- Iterates players 3 times on think, maybe handle differently, by event or something
        if not table.equalSeq( self.lp, plys ) or not table.equalSeq( table.map( plys, Nick ), self.Choices ) then
            self.lp = plys
            self:Clear()
            for k, p in pairs( player.GetAll() ) do
                self:AddChoice( p:Nick(), p )
                if p == ply then
                    self:ChooseOptionID( k )
                    self.ownID = k
                end
            end
        end
    end

    nameLabel.id = ply:SteamID()
    function nameLabel:OnMousePressed( keyCode )
        if keyCode == MOUSE_RIGHT then
            SetClipboardText( self.id )
        elseif keyCode == MOUSE_LEFT then
            self:DoClick()
        end
    end

    function nameLabel:OnSelect( idx, value, data )
        self:SetText( ply:Nick() )
        local p = data
        local id = p:SteamID()
        if not bc.sidePanel.childExists( "Player", id ) then
            bc.sidePanel.players.generateEntry( p )
        end

        bc.sidePanel.open( "Player", id )

    end


    local rankLabel = vgui.Create( "DLabel", p )
    rankLabel:SetText( team.GetName( ply:Team() ) )
    rankLabel:SetFont( bc.graphics.font )
    rankLabel:SetColor( team.GetColor( ply:Team() ) )
    rankLabel:SetSize( w - 32 - 88, 20 )
    rankLabel:SetPos( 88, 38 )
    rankLabel:SetMouseInputEnabled( true )
    rankLabel.ply = ply
    if ULib then
        rankLabel:SetTooltip( "ULX Rank: " .. ply:GetUserGroup() )
        rankLabel.uRank = ply:GetUserGroup()
    end
    function rankLabel:Think()
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
    function hLine:Paint( w, h )
        surface.SetDrawColor( bc.defines.theme.sidePanelAccent )
        surface.DrawRect( 0, 0, w, 1 )

        surface.SetMaterial( bc.defines.materials.gradientUp )
        surface.SetDrawColor( bc.defines.theme.sidePanelForeground )
        surface.DrawTexturedRect( 0, 1, w, h - 1 )
    end

    local data = bc.sidePanel.players.settings[ply:SteamID()]

    local k = 3.7 -- weird number simply used for positioning (as if this was drawn at index 3.7), not index
    local settingsAdded = {}
    for idx, v in pairs( bc.sidePanel.players.template ) do
        if not bc.sidePanel.players.canAddSetting( ply, v, settingsAdded ) then continue end
        table.insert( settingsAdded, v.name )
        bc.sidePanel.renderSetting( p, data, v, k )
        k = k + 1
    end
end

function bc.sidePanel.players.canAddSetting( ply, setting, settingsAdded )
    settingsAdded = settingsAdded or {}
    if setting.command and not bc.util.canRunULX( setting.command, ply ) then return false end
    if setting.extraCanRun and not setting.extraCanRun( ply, setting ) then return false end
    if setting.parentSetting then
        if not table.HasValue( settingsAdded, setting.parentSetting ) then
            return false
        end
    end
    return true
end

function bc.sidePanel.players.removeEntry( id )
    if not bc.sidePanel.players.settings[id] then return end

    if bc.sidePanel.panels["Player"].isOpen and bc.sidePanel.panels["Player"].activePanel == id then
        bc.sidePanel.close( "Player", true )
    end

    local panels = bc.sidePanel.panels["Player"].graphics.panels
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

function bc.sidePanel.players.removeAllEntries()
    local panels = bc.sidePanel.panels["Player"].graphics.panels
    for k, v in pairs( panels ) do
        v.Panel:Remove()
    end
    bc.sidePanel.panels["Player"].graphics.panels = {}
end
