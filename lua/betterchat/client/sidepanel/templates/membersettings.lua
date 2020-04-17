bc.sidePanel.members.template = {
    member = {
        name = "Player",
        value = "SteamID",
        type = "options",
        options = { "Admin", "Member", "Remove" },
        optionValues = { 0, 1, 2 },
        default = 1,
        extra = "Set this player's role in the group",
        onChange = function( data )
            local chan = bc.channels.get( "Group - " .. data.group.id )
            if not chan then return end -- Shouldn't be able to edit this but u kno

            local oldGroup = data.group
            local newGroup = { name = oldGroup.name, id = oldGroup.id, members = {}, admins = {}, invites = oldGroup.invites }
            for k, v in pairs( data ) do
                if type( v ) ~= "number" then continue end
                if v <= 1 then table.insert( newGroup.members, k ) end
                if v == 0 then table.insert( newGroup.admins, k ) end
            end

            net.Start( "BC_updateGroup" )
            net.WriteUInt( newGroup.id, 16 )
            net.WriteString( util.TableToJSON( newGroup ) )
            net.SendToServer()
        end,
        overrideWidth = 62,
    },
    nonMember = {
        name = "Player",
        value = "SteamID",
        type = "button",
        text = "Invite",
        extra = "Invite this player to the group, limited to 1 invite per minute",
        onClick = function( data, self )
            local group = data.group
            local id = self.value
            group.invites[id] = -1

            net.Start( "BC_updateGroup" )
            net.WriteUInt( group.id, 16 )
            net.WriteString( util.TableToJSON( group ) )
            net.SendToServer()
        end,
        overrideWidth = 62,
    },
    leaveGroup = {
        name = "",
        value = "",
        type = "button",
        text = "Leave Group",
        extra = "Leave this group and close the channel",
        onClick = function( data, self )
            net.Start( "BC_leaveGroup" )
            net.WriteUInt( data.group.id, 16 )
            net.SendToServer()
        end,
        overrideWidth = -1,
    },
    deleteGroup = {
        name = "",
        value = "",
        type = "button",
        text = "Delete Group",
        extra = "Delete this group permanently",
        onClick = function( data, self )
            net.Start( "BC_deleteGroup" )
            net.WriteUInt( data.group.id, 16 )
            net.SendToServer()
        end,
        overrideWidth = -1,
        requireConfirm = true,
    }
}
