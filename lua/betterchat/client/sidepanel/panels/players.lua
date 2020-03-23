chatBox.sidePanel.players = {}
include( "betterchat/client/sidepanel/templates/playersettings.lua" )
include( "betterchat/client/sidepanel/panels/players_add_option.lua" )

chatBox.sidePanel.players.settings = {}

net.Receive( "BC_sendPlayerState", function()
    local t = net.ReadString()
    local ply = net.ReadEntity()
    if not ply or not ply:IsValid() then return end
    local state = net.ReadBool()
    if chatBox.sidePanel.players.settings and chatBox.sidePanel.players.settings[ply:SteamID()] then
        chatBox.sidePanel.players.settings[ply:SteamID()][t] = state
    end
end )

hook.Add( "BC_initPanels", "BC_initSidePanelPlayers", function()
    chatBox.sidePanel.create( "Player", 300, {
        icon = chatBox.defines.materials.group,
        border = 1
    } )
end )

net.Receive( "BC_userRankChange", function()
    chatBox.base.closeChatBox()
    chatBox.sidePanel.players.removeAllEntries()
    hook.Run( "BC_userAccessChange" )
end )

function chatBox.sidePanel.players.generateEntry( ply )
    if not ply then return end
    if not chatBox.sidePanel.players.settings[ply:SteamID()] then
        chatBox.sidePanel.players.settings[ply:SteamID()] = { needsData = true }
    end

    local plySettings = chatBox.sidePanel.players.settings[ply:SteamID()]

    if plySettings.needsData then 
        for idx, v in pairs( chatBox.sidePanel.players.template ) do
            if not v.value then continue end
            if plySettings[v.value] == nil then
                plySettings[v.value] = v.default
            end
        end
        plySettings.dataChanged = plySettings.dataChanged or {}
    end

    plySettings.ply = ply

    local p = chatBox.sidePanel.createChild( "Player", ply:SteamID() )
    local w, h = p:GetSize()
    local avatar = vgui.Create( "AvatarImageCircle", p )
    avatar:SetSize( 64, 64 )
    avatar:SetPos( 4, 4 )
    avatar:SetPlayer( ply )
    avatar:SetClickable( true )

    local vLine = vgui.Create( "DShape", p )
    vLine:SetType( "Rect" )
    vLine:SetSize( 1, 48 )
    vLine:SetPos( 76, 4 + 8 )
    vLine:SetColor( chatBox.defines.theme.sidePanelAccent )

    local bg = vgui.Create( "DShape", p )
    bg:SetType( "Rect" )
    bg:SetSize( 130, 48 )
    bg:SetPos( 77, 4 + 8 )
    function bg:Paint( w, h )
        surface.SetMaterial( chatBox.defines.materials.gradientLeft )
        surface.SetDrawColor( chatBox.defines.theme.sidePanelForeground )
        surface.DrawTexturedRect( 0, 0, w, h )

        surface.SetDrawColor( chatBox.defines.theme.sidePanelAccent )
        surface.DrawTexturedRect( 0, h / 2, w, 1 )
    end


    local nameLabel = vgui.Create( "DComboBox", p )
    nameLabel:SetFont( chatBox.graphics.font )
    nameLabel:SetTextColor( chatBox.defines.colors.white )
    nameLabel:SetSize( w - 32 - 70, 20 )
    nameLabel:SetPos( 80, 14 )
    nameLabel.Paint = nil
    nameLabel.lp = {}
    nameLabel.ownID = 1
    function nameLabel:Think()
        local plys = player.GetAll()
        local GetName = getmetatable( plys[1] ).GetName
        -- If players list has changed or any player names have changed
        -- Iterates players 3 times on think, maybe handle differently, by event or something
        if not table.equalSeq( self.lp, plys ) or not table.equalSeq( table.map( plys, GetName ), self.Choices ) then
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
    function nameLabel:OnMousePressed( keyCode )
        if keyCode == MOUSE_RIGHT then
            SetClipboardText( self.id )
        elseif keyCode == MOUSE_LEFT then
            self:DoClick()
        end
    end

    function nameLabel:OnSelect( idx, value, data )
        self:SetText( ply:GetName() )
        local p = data
        local id = p:SteamID()
        if not chatBox.sidePanel.childExists( "Player", id ) then
            chatBox.sidePanel.players.generateEntry( p )
        end

        chatBox.sidePanel.open( "Player", id )

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
        surface.SetDrawColor( chatBox.defines.theme.sidePanelAccent )
        surface.DrawRect( 0, 0, w, 1 )

        surface.SetMaterial( chatBox.defines.materials.gradientUp )
        surface.SetDrawColor( chatBox.defines.theme.sidePanelForeground )
        surface.DrawTexturedRect( 0, 1, w, h - 1 )
    end

    local data = chatBox.sidePanel.players.settings[ply:SteamID()]

    local k = 3.7 -- weird number simply used for positioning (as if this was drawn at index 3.7), not index
    local settingsAdded = {}
    for idx, v in pairs( chatBox.sidePanel.players.template ) do
        if not chatBox.sidePanel.players.canAddSetting( ply, v, settingsAdded ) then continue end
        table.insert( settingsAdded, v.name )
        chatBox.sidePanel.renderSetting( p, data, v, k )
        k = k + 1
    end
end

function chatBox.sidePanel.players.canAddSetting( ply, setting, settingsAdded )
    settingsAdded = settingsAdded or {}
    if setting.command and not chatBox.util.canRunULX( setting.command, ply ) then return false end
    if setting.extraCanRun and not setting.extraCanRun( ply, setting ) then return false end
    if setting.parentSetting then
        if not table.HasValue( settingsAdded, setting.parentSetting ) then
            return false
        end    
    end
    return true
end

function chatBox.sidePanel.players.removeEntry( id )
    if not chatBox.sidePanel.players.settings[id] then return end

    if chatBox.sidePanel.panels["Player"].isOpen and chatBox.sidePanel.panels["Player"].activePanel == id then
        chatBox.sidePanel.close( "Player", true )
    end

    local panels = chatBox.sidePanel.panels["Player"].graphics.panels
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

function chatBox.sidePanel.players.removeAllEntries()
    local panels = chatBox.sidePanel.panels["Player"].graphics.panels
    for k, v in pairs( panels ) do
        v.Panel:Remove()
    end
    chatBox.sidePanel.panels["Player"].graphics.panels = {}
end
