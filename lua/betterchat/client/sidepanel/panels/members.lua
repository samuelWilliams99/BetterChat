chatBox.sidePanel.members = {}
include( "betterchat/client/sidepanel/templates/membersettings.lua" )

hook.Add( "BC_initPanels", "BC_initSidePanelMembers", function()
    chatBox.sidePanel.create( "Group Members", 250, {
        icon = chatBox.defines.materials.group,
        border = 1
    } )
end )

hook.Add( "BC_chatTextClick", "BC_groupAccept", function( eventType, dataType, dataArg )
    if dataType == "GroupAcceptInvite" and ( eventType == "LeftClick" or eventType == "DoubleClick" ) then
        local groupId = tonumber( dataArg )
        if not groupId or type( groupId ) ~= "number" then return end

        net.Start( "BC_groupAccept" )
        net.WriteUInt( groupId, 16 )
        net.SendToServer()
    end
end )

hook.Add( "BC_playerDisconnect", "BC_memberUpdateDiscon", chatBox.sidePanel.members.reloadAll )
hook.Add( "BC_playerConnect", "BC_memberUpdateCon", chatBox.sidePanel.members.reloadAll )

function chatBox.sidePanel.members.reloadAll()
    if not chatBox.base.enabled then return end
    for k, v in pairs( chatBox.channels.channels ) do
        if v.group then
            chatBox.sidePanel.members.reload( v )
        end
    end
end

function chatBox.sidePanel.members.addMenu( chan )
    local group = chan.group
    local p = chatBox.sidePanel.createChild( "Group Members", chan.name )

    chatBox.sidePanel.members.generateMenu( p, group )
end

function chatBox.sidePanel.members.reload( chan )
    local p = chatBox.sidePanel.getChild( "Group Members", chan.name )
    if p then
        p:Clear()
    else
        p = chatBox.sidePanel.createChild( "Group Members", chan.name )
    end
    chatBox.sidePanel.members.generateMenu( p, chan.group )
end

function chatBox.sidePanel.members.generateMenu( panel, group )
    panel.data = chatBox.group.generateMemberData( group )

    -- first sort by value in panel.data, then alphabetically by name (names before sids)
    -- Then for nonmembers, invited at the top
    local sortedIds = table.GetKeys( panel.data )
    table.sort( sortedIds, function( a, b ) 
        local aRole = panel.data[a]
        local bRole = panel.data[b]

        if aRole < bRole then
            return true
        elseif aRole > bRole then
            return false
        else
            local aPly = player.GetBySteamID( a )
            local aPlyExists = aPly and true or false
            local bPly = player.GetBySteamID( b )
            local bPlyExists = bPly and true or false

            local aInvited = group.invites[a] and true or false
            local bInvited = group.invites[b] and true or false

            if aRole <= 1 or aInvited == bInvited then -- members/admins
                if not aPlyExists and not bPlyExists then
                    return ( a < b ) -- sort by sid
                elseif aPlyExists ~= bPlyExists then
                    return aPlyExists    -- put real player above offline
                else
                    return ( aPly:GetName() < bPly:GetName() ) -- sort by name
                end
            else -- non members
                return aInvited --Put invited over not invited
            end
        end
    end )

    panel.data.group = group

    local channel = chatBox.channels.getChannel( "Group - " .. group.id )

    if not channel then return end

    local canvas = panel:GetCanvas()
    local w, h = panel:GetSize()
    local icon = vgui.Create( "DImage", canvas )
    icon:SetImage( "icon16/" .. channel.icon )
    icon:SetSize( 16, 16 )
    icon:SetPos( 2, 1 )

    local line = vgui.Create( "DShape", canvas )
    line:SetType( "Rect" )
    line:SetPos( 2, 22 )
    line:SetSize( w - 29, 2 )
    line:SetColor( chatBox.defines.theme.sidePanelAccent )

    local title = vgui.Create( "DLabel", canvas )
    title:SetPos( 24, 0 )
    title:SetFont( chatBox.graphics.font )
    title:SetText( channel.displayName )
    title:SizeToContents()
    title.data = channel
    function title:Think()
        if self.data.displayName ~= self:GetText() then
            self:SetText( self.data.displayName )    
            title:SizeToContents()
        end
    end

    local isAdmin = table.HasValue( group.admins, LocalPlayer():SteamID() )

    chatBox.sidePanel.renderSetting( panel, panel.data, chatBox.sidePanel.members.template.leaveGroup, 1 )

    local counter = 2

    if isAdmin then
        chatBox.sidePanel.renderSetting( panel, panel.data, chatBox.sidePanel.members.template.deleteGroup, 2 )
        counter = 3
    end

    local line2 = vgui.Create( "DShape", canvas )
    line2:SetType( "Rect" )
    line2:SetPos( 2, 14 + counter * 20 )
    line2:SetSize( w - 29, 1 )
    line2:SetColor( chatBox.defines.theme.sidePanelAccent )
    counter = counter + 0.5

    local lastRole = panel.data[sortedIds[1]]
    for k, id in ipairs( sortedIds ) do
        local role = panel.data[id]
        local setting
        if role < 2 then
            setting = table.Copy( chatBox.sidePanel.members.template.member )
            setting.disabled = not isAdmin
        else
            if not isAdmin then continue end
            setting = table.Copy( chatBox.sidePanel.members.template.nonMember )
            setting.disabled = ( group.invites[id] or not chatBox.sidePanel.players.settings[id].isChatEnabled ) and true or false
            setting.text = setting.disabled and ( group.invites[id] and "Invited" or "Disabled" ) or "Invite"
        end
        local ply = player.GetBySteamID( id )
        if ply then
            local chatEnabled = chatBox.sidePanel.players.settings[id] and chatBox.sidePanel.players.settings[id].isChatEnabled or false
            if not chatEnabled then 
                setting.nameColor = chatBox.defines.colors.red
                setting.extra = setting.extra .. ". This person currently has BetterChat disabled"
            end

            setting.name = ply:GetName()

        else
            setting.name = id
        end
        setting.value = id
        setting.default = role

        if role ~= lastRole then
            lastRole = role
            local w, h = panel:GetSize()
            local line = vgui.Create( "DShape", canvas )
            line:SetType( "Rect" )
            line:SetPos( 4, ( counter * 20 ) + 11 )
            line:SetSize( w - 33, 1 )
            line:SetColor( chatBox.defines.theme.sidePanelAccent )
            counter = counter + 0.25
        end

        chatBox.sidePanel.renderSetting( panel, panel.data, setting, counter )
        counter = counter + 1
    end
end
