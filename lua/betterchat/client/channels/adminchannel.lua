chatBox.admin = {}
chatBox.admin.defaultChannel = { 
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
        table.insert( tab, idx, chatBox.defines.theme.admin )
        table.insert( tab, idx + 1, "(ADMIN) " )
    end, 
    openOnStart = function()
        return chatBox.allowedAdmin()
    end, 
    runCommandSeparately = true, 
    hideChatText = true, 
    textEntryColor = chatBox.defines.theme.adminTextEntry, 
}
chatBox.admin.buttonEnabled = false

function chatBox.addAdminButton()
    chatBox.admin.buttonEnabled = true
end

function chatBox.removeAdminButton()
    chatBox.admin.buttonEnabled = false
end

hook.Add( "BC_makeChannelButtons", "BC_makeAdminButton", function( menu )
    if not chatBox.admin.buttonEnabled then return end
    menu:AddOption( "Admin", function()
        local chan = chatBox.getChannel( "Admin" )
        if not chan then return end

        if not chatBox.isChannelOpen( chan ) and chatBox.allowedAdmin() then
            chatBox.addChannel( chan )
        end
        chatBox.focusChannel( chan )
    end )
end )

function chatBox.allowedAdmin()
    return chatBox.getAllowed( "seeasay" )
end

net.Receive( "BC_AM", function()
    local ply = net.ReadEntity()
    local text = net.ReadString()
    local chan = chatBox.getChannel( "Admin" )

    if not chan then return end

    if not chan.openOnMessage then return end

    if not chatBox.isChannelOpen( chan ) and chatBox.allowedAdmin() then
        chatBox.addChannel( chan )
    end

    local isAlive, isAdmin = true, true
    if ply:IsValid() then
        isAlive = ply:Alive()
        isAdmin = ply:IsAdmin()
    end

    local tab = chatBox.formatMessage( ply, text, not isAlive, isAdmin and chatBox.defines.colors.white or chatBox.defines.theme.nonAdminText )
    chatBox.messageChannel( { chan.name, "MsgC" }, unpack( tab ) )
end )

function chatBox.addAdminChannel()
    local channel = chatBox.getChannel( "Admin" )
    if not channel then
        channel = table.Copy( chatBox.admin.defaultChannel )
        table.insert( chatBox.channels, channel )
    end
    if channel.needsData then
        for k, v in pairs( chatBox.admin.defaultChannel ) do
            if channel[k] == nil then 
                channel[k] = v 
            end
        end
        channel.needsData = nil
    end
    chatBox.applyDefaults( channel )
    if not channel.dataChanged then channel.dataChanged = {} end
    return channel
end

hook.Add( "BC_preInitPanels", "BC_initAddAdminChannel", function()
    chatBox.addAdminChannel()
end )

hook.Add( "BC_postInitPanels", "BC_adminAddButton", function()
    if chatBox.allowedAdmin() then
        chatBox.addAdminButton()
    end
end )

hook.Add( "BC_userAccessChange", "BC_adminChannelCheck", function()
    local adminChannel = chatBox.getChannel( "Admin" )
    if chatBox.allowedAdmin() then
        if not adminChannel then
            adminChannel = chatBox.addAdminChannel()
        end
        if not chatBox.isChannelOpen( adminChannel ) then
            chatBox.addChannel( adminChannel )
        end
        chatBox.addAdminButton()
    else
        if adminChannel and chatBox.isChannelOpen( adminChannel ) then
            chatBox.removeChannel( adminChannel ) -- closes
        end
        chatBox.removeAdminButton()
    end
end )

-- Overloads
hook.Add( "PostGamemodeLoaded", "BC_RPAdminOverload", function()
    if DarkRP then
        net.Receive( "FAdmin_ReceiveAdminMessage", function( len )
            local ply = net.ReadEntity()
            local text = net.ReadString()
            
            if not chatBox.enabled then

                local Team = ply:IsPlayer() and ply:Team() or 1
                local Nick = ply:IsPlayer() and ply:Nick() or "Console"
                local prefix = ( FAdmin.Access.PlayerHasPrivilege( ply, "AdminChat" ) or ply:IsAdmin() ) and "[Admin Chat] " or "[To admins] "

                chat.AddNonParsedText( chatBox.defines.colors.red, prefix, team.GetColor( Team ), Nick .. ": ", chatBox.defines.colors.white, text )
            else
                local chan = chatBox.getChannel( "Admin" )

                local tab = chatBox.formatMessage( ply, text, not ply:Alive(), ply:IsAdmin() and chatBox.defines.colors.white or chatBox.defines.theme.admin )
                chatBox.messageChannel( { chan.name, "MsgC" }, unpack( tab ) )
            end
        end )
        DarkRP.addChatReceiver( "/adminhelp", "talk in Admin", function( ply, text )
            return chatBox.allowedAdmin()
        end )
    end
end )