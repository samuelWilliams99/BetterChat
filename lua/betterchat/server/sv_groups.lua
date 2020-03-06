chatBox.group = {}
chatBox.group.inviteExpires = 60

function chatBox.saveGroups()
    local data = table.Copy( chatBox.group )
    for k, v in pairs( data.groups ) do
        v.invites = nil
    end
    file.Write( "bc_group_data_sv.txt", util.TableToJSON( data ) )
end

function chatBox.loadGroups()
    chatBox.group.groups = {}
    chatBox.group.groupIDCounter = 0
    if not file.Exists( "bc_group_data_sv.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_group_data_sv.txt" ) )
    if not data then return end

    for k, v in pairs( data.groups ) do
        v.invites = {}
    end

    chatBox.group = data
    chatBox.group.inviteExpires = chatBox.group.inviteExpires or 60
end

function chatBox.newGroup( owner, name )
    local oId = owner:SteamID()
    table.insert( chatBox.group.groups, { 
        id = chatBox.group.groupIDCounter, 
        name = name, 
        members = { oId }, 
        admins = { oId }, 
        invites = {}, 
    } )
    chatBox.group.groupIDCounter = chatBox.group.groupIDCounter + 1
    chatBox.saveGroups()
    return chatBox.group.groups[#chatBox.group.groups]
end

function chatBox.sendAllGroupData( ply )
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

function chatBox.sendGroupData( group, members, openNow )
    members = members or chatBox.getGroupMembers( group )
    group.openNow = openNow
    net.Start( "BC_updateGroup" )
    net.WriteString( util.TableToJSON( group ) )
    net.Send( members )
    group.openNow = nil
end

function chatBox.getGroupMembers( group )
    local members = {}
    for k, v in pairs( group.members ) do
        local member = player.GetBySteamID( v )
        if member then table.insert( members, member ) end
    end
    return members
end

function joinTables( a, b )
    local aCopy = table.Copy( a )
    for k, val in pairs( b ) do
        if not table.HasValue( aCopy, val ) then
            table.insert( aCopy, val )
        end
    end
    return aCopy
end

function chatBox.allowedGroups( ply )
    return chatBox.getAllowed( ply, "bc_groups" )
end

function chatBox.removeInvalidMembers( members )
    local out = {}
    for k, v in pairs( members ) do
        if chatBox.allowedGroups( v ) then
            table.insert( out, v )
        end
    end
    return out
end

function chatBox.handleInvites( group )
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
            if not chatBox.allowedGroups( ply ) then continue end
            ULib.clientRPC( ply, "chatBox.messageChannel", "All", 
                chatBox.colors.printYellow, "You have been invited to group \"", chatBox.colors.group, group.name, 
                chatBox.colors.printYellow, "\".\n\t", 
                { 
                    formatter = true, 
                    type = "clickable", 
                    signal = "GroupAcceptInvite-" .. group.id, 
                    text = "Click here to join!", 
                    colour = chatBox.colors.green, 
                }
            )
            timer.Simple( chatBox.group.inviteExpires + 0.5, function()
                chatBox.handleInvites( group )
                chatBox.sendGroupData( group )
                chatBox.saveGroups()
            end )
        else
            if ( v + chatBox.group.inviteExpires ) < CurTime() then
                group.invites[k] = nil
            end
        end
    end
end

function chatBox.groupRankChange( group, sId, old, new, members )
    if old == new then return end
    local ply = player.GetBySteamID( sId )
    local msg = { chatBox.colors.printYellow, ply or sId }
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

    members = members or chatBox.getGroupMembers( group )
    members = chatBox.removeInvalidMembers( members )
    ULib.clientRPC( members, "chatBox.messageChannel", "Group - " .. group.id, unpack( msg ) )
end

function chatBox.generateMemberData( group )
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

function chatBox.handleGroupRankChanges( old, new )
    local members = chatBox.getGroupMembers( new )
    local oldMemberData = chatBox.generateMemberData( old )
    local newMemberData = chatBox.generateMemberData( new )

    for k, v in pairs( oldMemberData ) do
        chatBox.groupRankChange( new, k, v, newMemberData[k] or 2, members )
        newMemberData[k] = nil
    end

    for k, v in pairs( newMemberData ) do
        chatBox.groupRankChange( new, k, 2, v, members )
    end
end

do
    chatBox.loadGroups()
end

concommand.Add( "bc_loadgroups", function()
    chatBox.loadGroups()
    for k, v in pairs( chatBox.group.groups ) do
        chatBox.handleInvites( v )
    end
    for k, v in pairs( player.GetAll() ) do
        chatBox.sendAllGroupData( v )
    end
end, true, "Loads group data from file" )

hook.Add( "BC_plyReady", "BC_sendGroups", function( ply )
    chatBox.sendAllGroupData( ply )
end )

net.Receive( "BC_newGroup", function( len, ply )
    local g = chatBox.newGroup( ply, "New Group" )
    chatBox.sendGroupData( g, nil, true )

end )

net.Receive( "BC_GM", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local msg = net.ReadString()
    for k, group in pairs( chatBox.group.groups ) do
        if group.id == groupID then
            if table.HasValue( group.members, ply:SteamID() ) then
                local members = chatBox.getGroupMembers( group )

                chatBox.sendLog( chatBox.channelTypes.GROUP, "Group " .. group.id .. " - " .. group.name, ply, ": ", msg )

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
        if group.id == groupID then
            if table.HasValue( group.admins, ply:SteamID() ) then
                local oldMembers = chatBox.getGroupMembers( group )

                local oldGroup = table.Copy( group )

                chatBox.group.groups[k] = util.JSONToTable( newData )
                group = chatBox.group.groups[k]

                for k, v in pairs( group.invites ) do
                    local invTime = oldGroup.invites[k]
                    if invTime and invTime + chatBox.group.inviteExpires > CurTime() then
                        group.invites[k] = invTime
                    end
                end

                local newMembers = chatBox.getGroupMembers( group )

                local members = joinTables( oldMembers, newMembers ) --This means players removed and players added both are updated of the change

                chatBox.handleInvites( group )

                chatBox.sendGroupData( group, members )

                if #group.members == 0 then
                    table.remove( chatBox.group.groups, k )
                else
                    chatBox.handleGroupRankChanges( oldGroup, group )
                end

                chatBox.saveGroups()
            end
            break
        end
    end
end )

net.Receive( "BC_deleteGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local newData = net.ReadString()
    for k, group in pairs( chatBox.group.groups ) do
        if group.id == groupID then
            if table.HasValue( group.admins, ply:SteamID() ) then
                local oldMembers = chatBox.getGroupMembers( group ) -- Get current members
                group.members = {} -- Empty the group
                group.admins = {}
                group.invites = {}
                chatBox.sendGroupData( group, oldMembers ) -- Tell all members that there are no members anymore
                table.remove( chatBox.group.groups, k ) -- Delete the group
                chatBox.saveGroups() -- Give it a good ol' save
            end
            break
        end
    end
end )

net.Receive( "BC_leaveGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    for k, group in pairs( chatBox.group.groups ) do
        if group.id == groupID then
            if table.HasValue( group.members, ply:SteamID() ) then
                local oldMembers = chatBox.getGroupMembers( group )

                table.RemoveByValue( group.members, ply:SteamID() )
                table.RemoveByValue( group.admins, ply:SteamID() )

                chatBox.sendGroupData( group, oldMembers )

                if #group.members == 0 then
                    table.remove( chatBox.group.groups, k )
                else
                    chatBox.groupRankChange( group, ply:SteamID(), 1, 2 )
                end

                chatBox.saveGroups()
                
            end
            break
        end
    end

end )

net.Receive( "BC_groupAccept", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local sId = ply:SteamID()

    for k, group in pairs( chatBox.group.groups ) do
        if group.id == groupID then
            local t = group.invites[sId]
            if t and t > 0 and ( ( t + chatBox.group.inviteExpires ) > CurTime() ) then
                local oldMembers = chatBox.getGroupMembers( group )
                table.insert( group.members, sId )
                group.invites[sId] = nil
                chatBox.sendGroupData( group, oldMembers )
                chatBox.sendGroupData( group, { ply }, true )
                chatBox.saveGroups()

                chatBox.groupRankChange( group, ply:SteamID(), 2, 1 )
            else
                group.invites[sId] = nil
                ULib.clientRPC( ply, "chatBox.messageChannel", "All", 
                    chatBox.colors.printYellow, "Sorry, this invite has expired or is no longer valid." )
            end
            break
        end
    end

end )