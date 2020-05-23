bc.admin = {}
bc.admin.defaultChannel = {
    name = "Admin",
    icon = "shield.png",
    send = function( self, txt )
        RunConsoleCommand( "ulx", "asay", txt )
    end,
    doPrints = false,
    addNewLines = true,
    allFunc = function( self, tab, idx )
        table.insert( tab, idx, bc.defines.theme.admin )
        table.insert( tab, idx + 1, "(" .. self.displayName .. ") " )
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
    if bc.channels.isOpen( "Admin" ) then return end
    local channel = bc.channels.get( "Admin" )

    menu:AddOption( channel.displayName, function()
        local chan = bc.channels.get( "Admin" )
        if not chan then return end
        if not bc.admin.allowed() then return end

        bc.channels.open( "Admin" )
        bc.channels.focus( "Admin" )
    end )
end )

function bc.admin.allowed( ply )
    if ply then return bc.settings.isAllowed( ply, "seeasay" ) end
    return bc.settings.isAllowed( "seeasay" )
end

net.Receive( "BC_AM", function()
    if not bc.admin.allowed() then return end
    local ply = net.ReadEntity()
    local text = net.ReadString()
    local chan = bc.channels.get( "Admin" )

    if not chan then return end
    if not chan.openOnMessage then return end

    bc.channels.open( "Admin" )

    local isAlive, isAdmin = true, true
    if ply:IsValid() then
        isAlive = ply:Alive()
        isAdmin = bc.admin.allowed( ply )
    end

    local tab = bc.formatting.formatMessage( ply, text, not isAlive, isAdmin and bc.defines.colors.white or bc.defines.theme.nonAdminText )
    bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
end )

function bc.admin.addChannel()
    return bc.channels.add( table.Copy( bc.admin.defaultChannel ) )
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
    if bc.admin.allowed() then
        if not bc.admin.buttonEnabled then
            bc.channels.open( "Admin" )
            bc.admin.addButton()
        end
    else
        bc.channels.close( "Admin" )
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
                local prefix = ( bc.admin.allowed() or FAdmin.Access.PlayerHasPrivilege( ply, "AdminChat" ) ) and "[Admin Chat] " or "[To admins] "

                chat.AddNonParsedText( bc.defines.colors.red, prefix, team.GetColor( Team ), Nick .. ": ", bc.defines.colors.white, text )
            else
                if bc.admin.allowed() then
                    local chan = bc.channels.get( "Admin" )

                    local tab = bc.formatting.formatMessage( ply, text, not ply:Alive(), bc.defines.colors.white )
                    bc.channels.message( { chan.name, "MsgC" }, unpack( tab ) )
                else
                    local tab = {
                        bc.util.you(),
                        bc.defines.colors.printBlue,
                        " to admins: ",
                        bc.defines.theme.nonAdminText,
                        text
                    }
                    bc.channels.message( { "All", "MsgC" }, unpack( tab ) )
                end
            end
        end )
        DarkRP.addChatReceiver( "/adminhelp", "talk in Admin", function( ply, text )
            return bc.admin.allowed( ply )
        end )
    end
end )
