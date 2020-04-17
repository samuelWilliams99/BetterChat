bc.group = {}
bc.group.inviteExpires = 60

local function joinTables( a, b )
    local aCopy = table.Copy( a )
    for k, val in pairs( b ) do
        if not table.HasValue( aCopy, val ) then
            table.insert( aCopy, val )
        end
    end
    return aCopy
end

function bc.group.saveGroups()
    local data = table.Copy( bc.group )
    for k, v in pairs( data.groups ) do
        data.groups[k] = {
            members = v.members,
            admins = v.admins,
            id = v.id,
            name = v.name
        }
    end
    file.Write( "bc_group_data_sv.txt", util.TableToJSON( data ) )
end

function bc.group.loadGroups()
    bc.group.groups = {}
    bc.group.groupIDCounter = 0
    if not file.Exists( "bc_group_data_sv.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_group_data_sv.txt" ) )
    if not data then return end

    for k, v in pairs( data.groups ) do
        v.invites = {}
    end

    bc.group.groups = data.groups
    bc.group.inviteExpires = data.inviteExpires or 60
    bc.group.groupIDCounter = data.groupIDCounter
end

function bc.group.get( groupID )
    for k, group in pairs( bc.group.groups ) do
        if group.id == groupID then
            return group, k
        end
    end
end

function bc.group.newGroup( owner, name )
    local oId = owner:SteamID()
    table.insert( bc.group.groups, {
        id = bc.group.groupIDCounter,
        name = name,
        members = { oId },
        admins = { oId },
        invites = {},
    } )
    bc.group.groupIDCounter = bc.group.groupIDCounter + 1
    bc.group.saveGroups()
    return bc.group.groups[#bc.group.groups]
end

function bc.group.sendAllGroupData( ply )
    local data = {}
    for k, group in pairs( bc.group.groups ) do
        if table.HasValue( group.members, ply:SteamID() ) then
            table.insert( data, group )
        end
    end
    net.Start( "BC_sendGroups" )
    net.WriteString( util.TableToJSON( data ) )
    net.Send( ply )
end

function bc.group.sendGroupData( group, members, openNow )
    members = members or bc.group.getGroupMembers( group )
    group.openNow = openNow
    net.Start( "BC_updateGroup" )
    net.WriteString( util.TableToJSON( group ) )
    net.Send( members )
    group.openNow = nil
end

function bc.group.getGroupMembers( group )
    return table.map( group.members, player.GetBySteamID )
end

function bc.group.allowed( ply )
    return bc.settings.isAllowed( ply, "bc_groups" )
end

function bc.group.removeInvalidMembers( members )
    return table.filterSeq( members, bc.group.allowed )
end

function bc.group.handleInvites( group )
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
            if not bc.group.allowed( ply ) then continue end
            ULib.clientRPC( ply, "bc.channels.message", "All",
                bc.defines.colors.printYellow, "You have been invited to group \"", bc.manager.themeColor( "group" ), group.name,
                bc.defines.colors.printYellow, "\".\n\t",
                {
                    formatter = true,
                    type = "clickable",
                    signal = "GroupAcceptInvite-" .. group.id,
                    text = "Click here to join!",
                    colour = bc.defines.colors.green,
                }
            )

            local groupID = group.id
            timer.Simple( bc.group.inviteExpires + 0.5, function()
                local group = bc.group.get( groupID )
                if not group then return end

                bc.group.handleInvites( group )
                bc.group.sendGroupData( group )
                bc.group.saveGroups()
            end )
        else
            if ( v + bc.group.inviteExpires ) < CurTime() then
                group.invites[k] = nil
            end
        end
    end
end

function bc.group.groupRankChange( group, sId, old, new, members )
    if old == new then return end
    local ply = player.GetBySteamID( sId )
    local msg = { bc.defines.colors.printYellow, ply or sId }
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
            table.insert( msg, " has become an admin of this group!" )
        end
    else
        if new == 2 then
            table.insert( msg, " has left the group." )
        else
            table.insert( msg, " is no longer an admin of this group." )
        end
    end

    if not members then
        members = bc.group.getGroupMembers( group )
        members = bc.group.removeInvalidMembers( members )
    end
    ULib.clientRPC( members, "bc.channels.message", "Group - " .. group.id, unpack( msg ) )
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

function bc.group.handleGroupChanges( old, new, sendPly )
    local members = bc.group.getGroupMembers( new )
    members = bc.group.removeInvalidMembers( members )
    local oldMemberData = bc.group.generateMemberData( old )
    local newMemberData = bc.group.generateMemberData( new )

    for k, v in pairs( oldMemberData ) do
        bc.group.groupRankChange( new, k, v, newMemberData[k] or 2, members )
        newMemberData[k] = nil
    end

    for k, v in pairs( newMemberData ) do
        bc.group.groupRankChange( new, k, 2, v, members )
    end

    if old.name ~= new.name then
        local msg = { { formatter = true, type = "escape" }, sendPly, bc.defines.colors.printYellow, " renamed the group to ", bc.manager.themeColor( "group" ), new.name }
        ULib.clientRPC( members, "bc.channels.message", "Group - " .. new.id, unpack( msg ) )
    end
end

function bc.group.sanitiseGroup( group, oldGroup )
    -- Remove new members, thats illegal
    for k, id in pairs( group.members ) do
        if not table.HasValue( oldGroup.members, id ) then
            table.remove( group.members, k )
        end
    end

    -- Remove non-member admins, like what the fuk, rude
    for k, id in pairs( group.admins ) do
        if not table.HasValue( group.members, id ) then
            table.remove( group.admins, k )
        end
    end

    -- Remove non-strings
    table.filterSelf( group.admins, isstring )
    table.filterSelf( group.members, isstring )

    -- Remove duplicates
    group.admins = table.unique( group.admins )
    group.members = table.unique( group.members )


    -- Remove non-valid ids
    table.filterSelf( group.invites, function( value, id ) return player.GetBySteamID( id ) end )

    -- Check name
    if #group.name < 1 or #group.name > 16 then
        group.name = oldGroup.name
    end

    group.id = oldGroup.id
end

bc.group.loadGroups()

concommand.Add( "bc_loadgroups", function()
    bc.group.loadGroups()
    for k, v in pairs( bc.group.groups ) do
        bc.group.handleInvites( v )
    end
    for k, v in pairs( player.GetAll() ) do
        bc.group.sendAllGroupData( v )
    end
end, true, "Loads group data from file" )

hook.Add( "BC_playerReady", "BC_sendGroups", function( ply )
    bc.group.sendAllGroupData( ply )
end )

net.Receive( "BC_newGroup", function( len, ply )
    local n = 0
    for k, group in pairs( bc.group.groups ) do
        if table.HasValue( group.members, ply:SteamID() ) then
            n = n + 1
        end
    end
    if n >= 5 then return end
    local g = bc.group.newGroup( ply, "New Group" )
    bc.group.sendGroupData( g, nil, true )
end )

net.Receive( "BC_GM", function( len, ply )
    if not bc.manager.canMessage( ply ) then return end

    local groupID = net.ReadUInt( 16 )
    local msg = net.ReadString()

    local group = bc.group.get( groupID )
    if not group then return end
    if not table.HasValue( group.members, ply:SteamID() ) then return end

    local members = bc.group.getGroupMembers( group )

    bc.logs.sendLog( bc.defines.channelTypes.GROUP, "Group " .. group.id .. " - " .. group.name, ply, ": ", msg )

    net.Start( "BC_GM" )
    net.WriteUInt( groupID, 16 )
    net.WriteEntity( ply )
    net.WriteString( msg )
    net.Send( members )
end )

net.Receive( "BC_updateGroup", function( len, ply )
    if not bc.manager.canMessage( ply ) then return end

    local groupID = net.ReadUInt( 16 )
    local newData = net.ReadString()

    local group, k = bc.group.get( groupID )
    if not group then return end

    if not table.HasValue( group.admins, ply:SteamID() ) then return end

    local oldMembers = bc.group.getGroupMembers( group )

    local oldGroup = table.Copy( group )

    local groupTable = util.JSONToTable( newData )
    if not groupTable then return end
    bc.group.groups[k] = groupTable
    group = bc.group.groups[k]

    bc.group.sanitiseGroup( group, oldGroup )

    for k, v in pairs( group.invites ) do
        local invTime = oldGroup.invites[k]
        if invTime and invTime + bc.group.inviteExpires > CurTime() then
            group.invites[k] = invTime
        end
    end

    local newMembers = bc.group.getGroupMembers( group )

    local members = joinTables( oldMembers, newMembers ) --This means players removed and players added both are updated of the change

    bc.group.handleInvites( group )

    bc.group.sendGroupData( group, members )

    if #group.members == 0 then
        table.remove( bc.group.groups, k )
    else
        bc.group.handleGroupChanges( oldGroup, group, ply )
    end

    bc.group.saveGroups()

end )

net.Receive( "BC_deleteGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local newData = net.ReadString()

    local group, k = bc.group.get( groupID )
    if not group then return end
    if not table.HasValue( group.admins, ply:SteamID() ) then return end

    local oldMembers = bc.group.getGroupMembers( group )
    group.members = {}
    group.admins = {}
    group.invites = {}
    bc.group.sendGroupData( group, oldMembers )

    table.remove( bc.group.groups, k )
    bc.group.saveGroups()
end )

net.Receive( "BC_leaveGroup", function( len, ply )
    local groupID = net.ReadUInt( 16 )

    local group, k = bc.group.get( groupID )
    if not group then return end
    if not table.HasValue( group.members, ply:SteamID() ) then return end

    local oldMembers = bc.group.getGroupMembers( group )

    table.RemoveByValue( group.members, ply:SteamID() )
    table.RemoveByValue( group.admins, ply:SteamID() )

    bc.group.sendGroupData( group, oldMembers )

    if #group.members == 0 then
        table.remove( bc.group.groups, k )
    else
        bc.group.groupRankChange( group, ply:SteamID(), 1, 2 )
    end

    bc.group.saveGroups()
end )

net.Receive( "BC_groupAccept", function( len, ply )
    local groupID = net.ReadUInt( 16 )
    local sId = ply:SteamID()

    local group = bc.group.get( groupID )
    if not group then return end

    local t = group.invites[sId]
    if t and t > 0 and ( ( t + bc.group.inviteExpires ) > CurTime() ) then
        local oldMembers = bc.group.getGroupMembers( group )
        table.insert( group.members, sId )
        group.invites[sId] = nil
        bc.group.sendGroupData( group, oldMembers )
        bc.group.sendGroupData( group, { ply }, true )
        bc.group.saveGroups()

        bc.group.groupRankChange( group, ply:SteamID(), 2, 1 )
    else
        group.invites[sId] = nil
        ULib.clientRPC( ply, "bc.channels.message", "All",
            bc.defines.colors.printYellow, "Sorry, this invite has expired or is no longer valid." )
    end
end )
