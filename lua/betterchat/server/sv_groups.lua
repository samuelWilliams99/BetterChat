chatBox.group = {}
chatBox.group.inviteExpires = 60

local function joinTables( a, b )
    local aCopy = table.Copy( a )
    for k, val in pairs( b ) do
        if not table.HasValue( aCopy, val ) then
            table.insert( aCopy, val )
        end
    end
    return aCopy
end

function chatBox.group.saveGroups()
    local data = table.Copy( chatBox.group )
    for k, v in pairs( data.groups ) do
        v.invites = nil
    end
    file.Write( "bc_group_data_sv.txt", util.TableToJSON( data ) )
end

function chatBox.group.loadGroups()
    chatBox.group.groups = {}
    chatBox.group.groupIDCounter = 0
    if not file.Exists( "bc_group_data_sv.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_group_data_sv.txt" ) )
    if not data then return end

    for k, v in pairs( data.groups ) do
        v.invites = {}
    end

    chatBox.group.groups = data.groups
    chatBox.group.inviteExpires = data.inviteExpires or 60
    chatBox.group.groupIDCounter = data.groupIDCounter
end

function chatBox.group.newGroup( owner, name )
    local oId = owner:SteamID()
    table.insert( chatBox.group.groups, { 
        id = chatBox.group.groupIDCounter, 
        name = name, 
        members = { oId }, 
        admins = { oId }, 
        invites = {}, 
    } )
    chatBox.group.groupIDCounter = chatBox.group.groupIDCounter + 1
    chatBox.group.saveGroups()
    return chatBox.group.groups[#chatBox.group.groups]
end

function chatBox.group.sendAllGroupData( ply )
    local data = {}
    for k, group in pairs( chatBox.group.groups ) do
        if table.HasValue( group.members, ply:SteamID() ) then
            table.insert( data, group )
        end
    end
    net.Start( "BC_sendGroups" )
    net.WriteString( util.TableToJSON( data ) )
    net.Send( ply )
end

function chatBox.group.sendGroupData( group, members, openNow )
    members = members or chatBox.group.getGroupMembers( group )
    group.openNow = openNow
    net.Start( "BC_updateGroup" )
    net.WriteString( util.TableToJSON( group ) )
    net.Send( members )
    group.openNow = nil
end

function chatBox.group.getGroupMembers( group )
    return table.map( group.members, player.GetBySteamID )
end

function chatBox.group.allowed( ply )
    return chatBox.settings.isAllowed( ply, "bc_groups" )
end

function chatBox.group.removeInvalidMembers( members )
    return table.filterSeq( members, chatBox.group.allowed )
end

function chatBox.group.handleInvites( group )
    for k, v in pairs( group.invites ) do
        if v < 0 then
            if table.HasValue( group.members, k ) then
                group.invites[k] = nil
                continue
            end
            group.invites[k] = CurTime()
            v = group.invites[k]

            --send invite
            local ply = player.GetBySteamID( k )
            if not ply then continue end
            if not chatBox.group.allowed( ply ) then continue end
            ULib.clientRPC( ply, "chatBox.channels.message", "All", 
                chatBox.defines.colors.printYellow, "You have been invited to group \"", chatBox.manager.themeColor( "group" ), group.name, 
                chatBox.defines.colors.printYellow, "\".\n\t", 
                { 
                    formatter = true, 
                    type = "clickable", 
                    signal = "GroupAcceptInvite-" .. group.id, 
                    text = "Click here to join!", 
                    colour = chatBox.defines.colors.green, 
                }
            )
            timer.Simple( chatBox.group.inviteExpires + 0.5, function()
                chatBox.group.handleInvites( group )
                chatBox.group.sendGroupData( group )
                chatBox.group.saveGroups()
            end )
        else
            if ( v + chatBox.group.inviteExpires ) < CurTime() then
                group.invites[k] = nil
            end
        end
    end
end

function chatBox.group.groupRankChange( group, sId, old, new, members )
    if old == new then return end
    local ply = player.GetBySteamID( sId )
    local msg = { chatBox.defines.colors.printYellow, ply or sId }
    if old == 2 then
        if new == 1 then
            table.insert( msg, " has joined the group!" )
        else
            table.insert( msg, " has joined the group and become an admin!" )
        end
        table.insert( msg, 2, { formatter = true, type = "escape" } )
    elseif old == 1 then
        if new == 2 then
            table.insert( msg, " has left the group." )
        else
            table.insert( msg, " has become an admin!" )
        end
    else
        if new == 2 then
            table.insert( msg, " has left the group." )
        else
            table.insert( msg, " is no longer an admin." )
        end
    end

    members = members or chatBox.group.getGroupMembers( group )
    members = chatBox.group.removeInvalidMembers( members )
    ULib.clientRPC( members, "chatBox.channels.message", "Group - " .. group.id, unpack( msg ) )
end

function chatBox.group.generateMemberData( group )
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

function chatBox.group.handleGroupRankChanges( old, new )
    local members = chatBox.group.getGroupMembers( new )
    local oldMemberData = chatBox.group.generateMemberData( old )
    local newMemberData = chatBox.group.generateMemberData( new )

    for k, v in pairs( oldMemberData ) do
        chatBox.group.groupRankChange( new, k, v, newMemberData[k] or 2, members )
        newMemberData[k] = nil
    end

    for k, v in pairs( newMemberData ) do
        chatBox.group.groupRankChange( new, k, 2, v, members )
    end
end

chatBox.group.loadGroups()

concommand.Add( "bc_loadgroups", function()
    chatBox.group.loadGroups()
    for k, v in pairs( chatBox.group.groups ) do
        chatBox.group.handleInvites( v )
    end
    for k, v in pairs( player.GetAll() ) do
        chatBox.group.sendAllGroupData( v )
    end
end, true, "Loads group data from file" )

hook.Add( "BC_playerReady", "BC_sendGroups", function( ply )
    chatBox.group.sendAllGroupData( ply )
end )

net.Receive( "BC_newGroup", function( len, ply )
    local g = chatBox.group.newGroup( ply, "New Group" )
    chatBox.group.sendGroupData( g, nil, true )
end )

net.Receive( "BC_GM", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local msg = net.ReadString()
    for k, group in pairs( chatBox.group.groups ) do
        if group.id == groupID then
            if table.HasValue( group.members, ply:SteamID() ) then
                local members = chatBox.group.getGroupMembers( group )

                chatBox.logs.sendLog( chatBox.defines.channelTypes.GROUP, "Group " .. group.id .. " - " .. group.name, ply, ": ", msg )

                net.Start( "BC_GM" )
                net.WriteUInt( groupID, 16 )
                net.WriteEntity( ply )
                net.WriteString( msg )
                net.Send( members )

            end
            break
        end
    end
end )

net.Receive( "BC_updateGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local newData = net.ReadString()
    for k, group in pairs( chatBox.group.groups ) do
        if group.id ~= groupID then continue end
        if not table.HasValue( group.admins, ply:SteamID() ) then break end

        local oldMembers = chatBox.group.getGroupMembers( group )

        local oldGroup = table.Copy( group )

        chatBox.group.groups[k] = util.JSONToTable( newData )
        group = chatBox.group.groups[k]

        for k, v in pairs( group.invites ) do
            local invTime = oldGroup.invites[k]
            if invTime and invTime + chatBox.group.inviteExpires > CurTime() then
                group.invites[k] = invTime
            end
        end

        local newMembers = chatBox.group.getGroupMembers( group )

        local members = joinTables( oldMembers, newMembers ) --This means players removed and players added both are updated of the change

        chatBox.group.handleInvites( group )

        chatBox.group.sendGroupData( group, members )

        if #group.members == 0 then
            table.remove( chatBox.group.groups, k )
        else
            chatBox.group.handleGroupRankChanges( oldGroup, group )
        end

        chatBox.group.saveGroups()
        break
    end
end )

net.Receive( "BC_deleteGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local newData = net.ReadString()
    for k, group in pairs( chatBox.group.groups ) do
        if group.id ~= groupID then continue end
        if not table.HasValue( group.admins, ply:SteamID() ) then break end
        local oldMembers = chatBox.group.getGroupMembers( group )
        group.members = {}
        group.admins = {}
        group.invites = {}
        chatBox.group.sendGroupData( group, oldMembers )
        table.remove( chatBox.group.groups, k )
        chatBox.group.saveGroups()
    end
end )

net.Receive( "BC_leaveGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    for k, group in pairs( chatBox.group.groups ) do
        if group.id ~= groupID then continue end
        if not table.HasValue( group.members, ply:SteamID() ) then break end

        local oldMembers = chatBox.group.getGroupMembers( group )

        table.RemoveByValue( group.members, ply:SteamID() )
        table.RemoveByValue( group.admins, ply:SteamID() )

        chatBox.group.sendGroupData( group, oldMembers )

        if #group.members == 0 then
            table.remove( chatBox.group.groups, k )
        else
            chatBox.group.groupRankChange( group, ply:SteamID(), 1, 2 )
        end

        chatBox.group.saveGroups()
    end
end )

net.Receive( "BC_groupAccept", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local sId = ply:SteamID()

    for k, group in pairs( chatBox.group.groups ) do
        if group.id ~= groupID then continue end

        local t = group.invites[sId]
        if t and t > 0 and ( ( t + chatBox.group.inviteExpires ) > CurTime() ) then
            local oldMembers = chatBox.group.getGroupMembers( group )
            table.insert( group.members, sId )
            group.invites[sId] = nil
            chatBox.group.sendGroupData( group, oldMembers )
            chatBox.group.sendGroupData( group, { ply }, true )
            chatBox.group.saveGroups()

            chatBox.group.groupRankChange( group, ply:SteamID(), 2, 1 )
        else
            group.invites[sId] = nil
            ULib.clientRPC( ply, "chatBox.channels.message", "All", 
                chatBox.defines.colors.printYellow, "Sorry, this invite has expired or is no longer valid." )
        end
        break
    end
end )
