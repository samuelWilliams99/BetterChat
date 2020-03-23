bc.admin = {}
bc.admin.defaultChannel = {
    name = "Admin",
    icon = "shield.png",
    send = function( self, txt )
        net.Start( "BC_AM" )
        net.WriteString( txt )
        net.SendToServer()
    end,
    doPrints = false,
    addNewLines = true,
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.admin )
        table.insert( tab, idx + 1, "(ADMIN) " )
    end,
    openOnStart = function()
        return bc.admin.allowed()
    end,
    runCommandSeparately = true,
    hideChatText = true,
    textEntryColor = bc.defines.theme.adminTextEntry,
    position = 6,
}
bc.admin.buttonEnabled = false

function bc.admin.addButton()
    bc.admin.buttonEnabled = true
end

function bc.admin.removeButton()
    bc.admin.buttonEnabled = false
end

hook.Add( "BC_makeChannelButtons", "BC_makeAdminButton", function( menu )
    if not bc.admin.buttonEnabled then return end
    menu:AddOption( "Admin", function()
        local chan = bc.channels.getChannel( "Admin" )
        if not chan then return end

        if not bc.channels.isOpen( chan ) and bc.admin.allowed() then
            bc.channels.add( chan )
        end
        bc.channels.focus( chan )
    end )
end )

function bc.admin.allowed()
    return bc.settings.isAllowed( "seeasay" )
end

net.Receive( "BC_AM", function()
    local ply = net.ReadEntity()
    local text = net.ReadString()
    local chan = bc.channels.getChannel( "Admin" )

    if not chan then return end

    if not chan.openOnMessage then return end

    if not bc.channels.isOpen( chan ) and bc.admin.allowed() then
        bc.channels.add( chan )
    end

    local isAlive, isAdmin = true, true
    if ply:IsValid() then
        isAlive = ply:Alive()
        isAdmin = ply:IsAdmin()
    end

    local tab = bc.formatting.formatMessage( ply, text, not isAlive, isAdmin and bc.defines.colors.white or bc.defines.theme.nonAdminText )
    bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
end )

function bc.admin.addChannel()
    local channel = bc.channels.getChannel( "Admin" )
    if not channel then
        channel = table.Copy( bc.admin.defaultChannel )
        table.insert( bc.channels.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( bc.admin.defaultChannel ) do
            if channel[k] == nil then
                channel[k] = v
            end
        end
        channel.needsData = nil
    end
    bc.sidePanel.channels.applyDefaults( channel )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

hook.Add( "BC_initPanels", "BC_initAddAdminChannel", function()
    bc.admin.addChannel()
end )

hook.Add( "BC_postInitPanels", "BC_adminAddButton", function()
    if bc.admin.allowed() then
        bc.admin.addButton()
    end
end )

hook.Add( "BC_userAccessChange", "BC_adminChannelCheck", function()
    local adminChannel = bc.channels.getChannel( "Admin" )
    if bc.admin.allowed() then
        if not adminChannel then
            adminChannel = bc.admin.addChannel()
        end
        if not bc.channels.isOpen( adminChannel ) then
            bc.channels.add( adminChannel )
        end
        bc.admin.addButton()
    else
        if adminChannel and bc.channels.isOpen( adminChannel ) then
            bc.channels.remove( adminChannel ) -- closes
        end
        bc.admin.removeButton()
    end
end )

-- Overloads
hook.Add( "PostGamemodeLoaded", "BC_RPAdminOverload", function()
    if DarkRP then
        net.Receive( "FAdmin_ReceiveAdminMessage", function( len )
            local ply = net.ReadEntity()
            local text = net.ReadString()

            if not bc.base.enabled then

                local Team = ply:IsPlayer() and ply:Team() or 1
                local Nick = ply:IsPlayer() and ply:Nick() or "Console"
                local prefix = ( FAdmin.Access.PlayerHasPrivilege( ply, "AdminChat" ) or ply:IsAdmin() ) and "[Admin Chat] " or "[To admins] "

                chat.AddNonParsedText( bc.defines.colors.red, prefix, team.GetColor( Team ), Nick .. ": ", bc.defines.colors.white, text )
            else
                local chan = bc.channels.getChannel( "Admin" )

                local tab = bc.formatting.formatMessage( ply, text, not ply:Alive(), ply:IsAdmin() and bc.defines.colors.white or bc.defines.theme.admin )
                bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
            end
        end )
        DarkRP.addChatReceiver( "/adminhelp", "talk in Admin", function( ply, text )
            return bc.admin.allowed()
        end )
    end
end )
