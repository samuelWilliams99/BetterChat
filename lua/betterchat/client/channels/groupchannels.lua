chatBox.group = {}
chatBox.group.groups = {}
chatBox.group.buttonEnabled = false

chatBox.group.defaultChannel = { 
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
        table.insert( tab, idx, chatBox.defines.theme.group )
        table.insert( tab, idx + 1, "(" .. self.displayName .. ") " )
    end, 
    tickMode = 0, 
    popMode = 1, 
    hideRealName = true, 
    postAdd = function( data, panel )
        local g = chatBox.graphics
        local membersBtn = vgui.Create( "DButton", panel )
        membersBtn:SetPos( g.chatFrame:GetWide() - 59, 34 )
        membersBtn:SetSize( 24, 24 )
        membersBtn:SetText( "" )
        membersBtn:SetColor( chatBox.defines.theme.groupMembers )
        membersBtn.name = data.name
        membersBtn.DoClick = function( self )
            local s = chatBox.sidePanels["Group Members"]
            if s.isOpen then
                chatBox.closeSidePanel( s.name )
            else
                chatBox.openSidePanel( s.name, self.name )
            end
        end
        membersBtn.Paint = function( self, w, h )
            local animState = chatBox.sidePanels["Group Members"].animState
            self:SetColor( lerpCol( chatBox.defines.theme.groupMembers, chatBox.defines.theme.groupMembersFocused, animState ) )
            surface.SetMaterial( chatBox.materials.getMaterial( "icons/groupbw.png" ) )
            surface.SetDrawColor( self:GetColor() )
            surface.DrawTexturedRect( 0, 0, w, h )
        end
    end, 
    runCommandSeparately = true, 
    hideChatText = true, 
    textEntryColor = chatBox.defines.theme.groupTextEntry, 
}

function chatBox.allowedGroups()
    return chatBox.getAllowed( "bc_groups" )
end

function chatBox.removeGroupHooks()
    hook.Remove( "PlayerConnect", "BC_reloadMembersConnect" )
    hook.Remove( "BC_playerDisconnect", "BC_reloadMembersDisconnect" )
end

hook.Add( "BC_postInitPanels", "BC_groupAddButton", function() -- add group change check
    if chatBox.allowedGroups() then 
        chatBox.enableGroups()
    else
        chatBox.removeGroupHooks()
    end
end )

hook.Add( "BC_userAccessChange", "BC_groupChannelCheck", function()
    if chatBox.allowedGroups() then 
        chatBox.enableGroups()
    else
        chatBox.disableGroups()
    end
end )

function chatBox.disableGroups()
    chatBox.group.buttonEnabled = false
    chatBox.removeGroupHooks()
    for k, v in pairs( chatBox.channels ) do
        if string.sub( v.name, 1, 8 ) == "Group - " then
            chatBox.removeChannel( v )
        end
    end
end

function chatBox.enableGroups()
    chatBox.group.buttonEnabled = true
    hook.Add( "PlayerConnect", "BC_reloadMembersConnect", function()
        for k, v in pairs( chatBox.channels ) do
            if chatBox.isChannelOpen( v ) and v.group then
                chatBox.reloadGroupMemberMenu( v )
            end
        end
    end )

    hook.Add( "BC_playerDisconnect", "BC_reloadMembersDisconnect", function()
        for k, v in pairs( chatBox.channels ) do
            if chatBox.isChannelOpen( v ) and v.group then
                chatBox.reloadGroupMemberMenu( v )
            end
        end
    end )

    net.Receive( "BC_sendGroups", chatBox.group.onReceiveGroups )
    net.Receive( "BC_updateGroup", chatBox.group.onUpdate )
    net.Receive( "BC_GM", chatBox.group.onMessage )
end

hook.Add( "BC_makeChannelButtons", "BC_makeGroupButton", function( menu )
    if not chatBox.group.buttonEnabled then return end
    local subMenu = menu:AddSubMenu( "Groups" )
    if #chatBox.group.groups < 5 then
        subMenu:AddOption( "Create Group", function()
            net.Start( "BC_newGroup" )
            net.SendToServer()
        end )
        if #chatBox.group.groups > 0 then
            subMenu:AddSpacer()
        end
    end

    for k, group in pairs( chatBox.group.groups ) do
        subMenu:AddOption( group.name, function()
            local chan = chatBox.getChannel( "Group - " .. group.id )
            if not chan or chan.needsData then
                chan = chatBox.createGroupChannel( group )
            end
            if not chatBox.isChannelOpen( chan ) then
                chatBox.addChannel( chan )
            end
            chatBox.reloadGroupMemberMenu( chan )
            chatBox.focusChannel( chan )
        end )
    end
end )

function chatBox.group.onReceiveGroups()
    chatBox.group.groups = util.JSONToTable( net.ReadString() )
    local ids = {}

    for k, v in ipairs( chatBox.group.groups ) do
        table.insert( ids, v.id )
    end

    for k, v in pairs( chatBox.channels ) do
        if v.group then
            if not table.HasValue( ids, v.group.id ) then
                chatBox.deleteGroup( v.group )
            else
                local index = table.KeyFromValue( ids, v.group.id )
                local newGroup = chatBox.group.groups[index]
                v.group = newGroup
                if chatBox.getSidePanelChild( "Group Members", v.name ) then
                    chatBox.reloadGroupMemberMenu( v )
                end

                if table.HasValue( newGroup.admins, LocalPlayer():SteamID() ) then
                    v.disabledSettings = {}
                else
                    v.disabledSettings = { "displayName" }
                end
                chatBox.reloadChannelSettings( v )

            end
        end
    end
end

function chatBox.group.onUpdate()
    if not chatBox.enabled then return end
    local group = util.JSONToTable( net.ReadString() )
    local foundLocal = false
    for k, v in pairs( chatBox.group.groups ) do
        if v.id == group.id then
            foundLocal = true
            if table.HasValue( group.members, LocalPlayer():SteamID() ) then
                chatBox.group.groups[k] = group
                break
            else
                chatBox.deleteGroup( group )
                return
            end
            
        end
    end
    if not foundLocal then
        table.insert( chatBox.group.groups, group )
    end

    local chan = chatBox.getChannel( "Group - " .. group.id )
    if chan then
        chan.group = group
        chan.displayName = group.name
        chan.dataChanged = chan.dataChanged or {}
        chan.dataChanged.displayName = true
        if chatBox.getSidePanelChild( "Group Members", chan.name ) then
            chatBox.reloadGroupMemberMenu( chan )
        end

        if chatBox.isChannelOpen( chan ) then
            if table.HasValue( group.admins, LocalPlayer():SteamID() ) then
                chan.disabledSettings = {}
            else
                chan.disabledSettings = { "displayName" }
            end
            chatBox.reloadChannelSettings( chan )
        end
    end

    if group.openNow then
        if not chan or chan.needsData then
            chan = chatBox.createGroupChannel( group )
        end
        if not chatBox.isChannelOpen( chan ) then
            chatBox.addChannel( chan )
        end
        chatBox.focusChannel( chan )
    end
end

function chatBox.group.onMessage()
    if not chatBox.enabled then return end
    local groupId = net.ReadUInt( 16 )
    local ply = net.ReadEntity()
    local text = net.ReadString()

    local chan = chatBox.getChannel( "Group - " .. groupId )
    if not chan or chan.needsData then
        for k, v in pairs( chatBox.group.groups ) do
            if v.id == groupId then
                chan = chatBox.createGroupChannel( v )
                break
            end
        end
    end

    if not chan then return end

    if not chan.openOnMessage then return end

    if not chatBox.isChannelOpen( chan ) then
        chatBox.addChannel( chan )
    end

    local tab = chatBox.formatMessage( ply, text, not ply:Alive() )
    table.insert( tab, 1, { isController = true, doSound = ply ~= LocalPlayer() } )
    chatBox.messageChannel( { chan.name, "MsgC" }, unpack( tab ) )
end

function chatBox.deleteGroup( group )
    if not chatBox.allowedGroups() then return end
    -- table.RemoveByMember would work here
    for k, v in pairs( chatBox.group.groups ) do --table.RemoveByValue wasn't working so delete by id instead
        if v.id == group.id then 
            table.remove( chatBox.group.groups, k ) 
        end 
    end
    local chan = chatBox.getChannel( "Group - " .. group.id )
    if chan then
        if chatBox.isChannelOpen( chan ) then
            chatBox.removeChannel( chan )
        end
        table.RemoveByValue( chatBox.channels, chan )
    end
    chatBox.messageChannelDirect( "All", chatBox.defines.colors.printYellow, "You have been removed from group \"", 
        chatBox.defines.theme.group, group.name, chatBox.defines.colors.printYellow, "\"." )
    chatBox.saveData()        
end

function chatBox.createGroupChannel( group )
    if not chatBox.allowedGroups() then return nil end
    local name = "Group - " .. group.id
    local channel = chatBox.getChannel( name )
    if not channel then
        channel = table.Copy( chatBox.group.defaultChannel )
        channel.name = name
        table.insert( chatBox.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( chatBox.group.defaultChannel ) do
            if channel[k] == nil then 
                channel[k] = v 
            end
        end
        channel.needsData = nil
    end
    if not table.HasValue( group.admins, LocalPlayer():SteamID() ) then
        channel.disabledSettings = { "displayName" }
    end
    chatBox.applyDefaults( channel )

    channel.displayName = group.name
    channel.group = group
    chatBox.reloadGroupMemberMenu( channel )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end