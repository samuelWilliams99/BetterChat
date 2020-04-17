bc.group = {}
bc.group.groups = {}
bc.group.buttonEnabled = false

bc.group.defaultChannel = {
    init = false,
    displayName = "[Loading]",
    icon = "group.png",
    addNewLines = true,
    send = function( self, txt )
        net.Start( "BC_GM" )
        net.WriteUInt( self.group.id, 16 )
        net.WriteString( txt )
        net.SendToServer()
    end,
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.group )
        table.insert( tab, idx + 1, "(" .. self.displayName .. ") " )
    end,
    tickMode = 0,
    popMode = 1,
    hideRealName = true,
    postAdd = function( data, panel )
        local membersBtn = vgui.Create( "DButton", panel )
        membersBtn:SetPos( bc.graphics.derma.chatFrame:GetWide() - 59, 34 )
        membersBtn:SetSize( 24, 24 )
        membersBtn:SetText( "" )
        membersBtn:SetColor( bc.defines.theme.groupMembers )
        membersBtn.name = data.name
        function membersBtn:DoClick()
            local s = bc.sidePanel.panels["Group Members"]
            if s.isOpen then
                bc.sidePanel.close( s.name )
            else
                bc.sidePanel.open( s.name, self.name )
            end
        end
        function membersBtn:Paint( w, h )
            if not panel.doPaint then return end
            local animState = bc.sidePanel.panels["Group Members"].animState
            self:SetColor( chatHelper.lerpCol( bc.defines.theme.groupMembers, bc.defines.theme.groupMembersFocused, animState ) )
            surface.SetMaterial( bc.defines.materials.groupBW )
            surface.SetDrawColor( self:GetColor() )
            surface.DrawTexturedRect( 0, 0, w, h )
        end


    end,
    runCommandSeparately = true,
    hideChatText = true,
    textEntryColor = bc.defines.theme.groupTextEntry,
    position = 5,
}

function bc.group.allowed()
    return bc.settings.isAllowed( "bc_groups" )
end

function bc.group.removeHooks()
    hook.Remove( "PlayerConnect", "BC_reloadMembersConnect" )
    hook.Remove( "BC_playerDisconnect", "BC_reloadMembersDisconnect" )
end

hook.Add( "BC_postInitPanels", "BC_groupAddButton", function() -- add group change check
    if bc.group.allowed() then
        bc.group.enable()
    else
        bc.group.removeHooks()
    end
end )

hook.Add( "BC_userAccessChange", "BC_groupChannelCheck", function()
    if bc.group.allowed() then
        bc.group.enable()
    else
        bc.group.disable()
    end
end )

function bc.group.disable()
    bc.group.buttonEnabled = false
    bc.group.removeHooks()
    for k, v in pairs( bc.channels.channels ) do
        if string.sub( v.name, 1, 8 ) == "Group - " then
            bc.channels.close( v )
        end
    end
end

function bc.group.enable()
    bc.group.buttonEnabled = true
    hook.Add( "PlayerConnect", "BC_reloadMembersConnect", function()
        for k, v in pairs( bc.channels.channels ) do
            if bc.channels.isOpen( v ) and v.group then
                bc.sidePanel.members.reload( v )
            end
        end
    end )

    hook.Add( "BC_playerDisconnect", "BC_reloadMembersDisconnect", function()
        for k, v in pairs( bc.channels.channels ) do
            if bc.channels.isOpen( v ) and v.group then
                bc.sidePanel.members.reload( v )
            end
        end
    end )

    net.Receive( "BC_sendGroups", bc.group.onReceiveGroups )
    net.Receive( "BC_updateGroup", bc.group.onUpdate )
    net.Receive( "BC_GM", bc.group.onMessage )
end

hook.Add( "BC_makeChannelButtons", "BC_makeGroupButton", function( menu )
    if not bc.group.buttonEnabled then return end
    local subMenu = menu:AddSubMenu( "Groups" )
    if #bc.group.groups < 5 then
        subMenu:AddOption( "Create Group", function()
            net.Start( "BC_newGroup" )
            net.SendToServer()
        end )
        if #bc.group.groups > 0 then
            subMenu:AddSpacer()
        end
    end

    for k, group in pairs( bc.group.groups ) do
        local chanName = "Group - " .. group.id
        if bc.channels.isOpen( chanName ) then continue end
        subMenu:AddOption( group.name, function()
            local chan = bc.channels.get( chanName )
            if not chan then
                chan = bc.group.createChannel( group )
            end
            bc.channels.open( chan.name )
            bc.sidePanel.members.reload( chan )
            bc.channels.focus( chan.name )
        end )
    end
end )

function bc.group.onReceiveGroups()
    bc.group.groups = util.JSONToTable( net.ReadString() )
    local ids = {}

    for k, v in ipairs( bc.group.groups ) do
        table.insert( ids, v.id )
    end

    for k, v in pairs( bc.channels.channels ) do
        if v.group then
            if not table.HasValue( ids, v.group.id ) then
                bc.group.deleteGroup( v.group )
            else
                local index = table.KeyFromValue( ids, v.group.id )
                local newGroup = bc.group.groups[index]
                v.group = newGroup
                if bc.sidePanel.getChild( "Group Members", v.name ) then
                    bc.sidePanel.members.reload( v )
                end

                if table.HasValue( newGroup.admins, LocalPlayer():SteamID() ) then
                    v.disabledSettings = {}
                else
                    v.disabledSettings = { "displayName" }
                end
                bc.sidePanel.channels.reloadSettings( v )

            end
        end
    end

    if bc.data.openChannels then
        bc.channels.openSaved()
    end
end

function bc.group.onUpdate()
    if not bc.base.enabled then return end
    local group = util.JSONToTable( net.ReadString() )
    local foundLocal = false
    for k, v in pairs( bc.group.groups ) do
        if v.id == group.id then
            foundLocal = true
            if table.HasValue( group.members, LocalPlayer():SteamID() ) then
                bc.group.groups[k] = group
                break
            else
                bc.group.deleteGroup( group )
                return
            end

        end
    end
    if not foundLocal then
        table.insert( bc.group.groups, group )
    end

    local chan = bc.channels.get( "Group - " .. group.id )
    if chan then
        chan.group = group
        chan.displayName = group.name
        if bc.sidePanel.getChild( "Group Members", chan.name ) then
            bc.sidePanel.members.reload( chan )
        end

        if bc.channels.isOpen( chan.name ) then
            if table.HasValue( group.admins, LocalPlayer():SteamID() ) then
                chan.disabledSettings = {}
            else
                chan.disabledSettings = { "displayName" }
            end
            bc.sidePanel.channels.reloadSettings( chan )
        end
    end

    if group.openNow then
        if not chan then
            chan = bc.group.createChannel( group )
        end
        bc.channels.open( chan.name )
        bc.channels.focus( chan.name )
    end
end

function bc.group.onMessage()
    if not bc.base.enabled then return end
    local groupId = net.ReadUInt( 16 )
    local ply = net.ReadEntity()
    local text = net.ReadString()

    local chan = bc.channels.get( "Group - " .. groupId )
    if not chan then
        for k, v in pairs( bc.group.groups ) do
            if v.id == groupId then
                chan = bc.group.createChannel( v )
                break
            end
        end
    end

    if not chan then return end

    if not chan.openOnMessage then return end

    bc.channels.open( chan.name )

    local tab = bc.formatting.formatMessage( ply, text, not ply:Alive() )
    table.insert( tab, 1, { controller = true, doSound = ply ~= LocalPlayer() } )
    bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
end

function bc.group.deleteGroup( group )
    if not bc.group.allowed() then return end
    table.removeByMember( bc.group.groups, "id", group.id )

    local chan = bc.channels.get( "Group - " .. group.id )
    if chan then
        bc.channels.close( chan.name )
        bc.channels.remove( chan.name )
    end
    bc.channels.messageDirect( "All", bc.defines.colors.printYellow, "You have been removed from group \"",
        bc.defines.theme.group, group.name, bc.defines.colors.printYellow, "\"." )
    bc.data.saveData()
end

function bc.group.createChannel( group )
    if not bc.group.allowed() then return nil end
    local name = "Group - " .. group.id
    local channel = table.Copy( bc.group.defaultChannel )
    channel.name = name
    bc.channels.add( channel )

    if not table.HasValue( group.admins, LocalPlayer():SteamID() ) then
        channel.disabledSettings = { "displayName" }
    end

    channel.displayName = group.name
    channel.group = group
    bc.sidePanel.members.reload( channel )
    return channel
end

function bc.group.generateMemberData( group )
    local data = {}
    for k, v in pairs( player.GetAll() ) do
        if v:IsBot() then continue end
        data[v:SteamID()] = 2
    end

    for k, v in pairs( group.members ) do
        data[v] = 1
    end

    for k, v in pairs( group.admins ) do
        data[v] = 0
    end

    return data
end
