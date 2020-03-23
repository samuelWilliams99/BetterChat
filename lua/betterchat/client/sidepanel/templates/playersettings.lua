chatBox.sidePanel.players.template = { 
    { 
        name = "Ignore", 
        value = "ignore", 
        type = "options", 
        options = { "Don't ignore", "Ignore", "Perma ignore" }, 
        optionValues = { 0, 1, 2 }, 
        default = 0, 
        extra = "No longer see messages from this user. (Ignore is for rest of this session, Perma ignore saves across sessions)", 
        extraCanRun = function( ply ) 
            return ( ply ~= LocalPlayer() and not ply:IsSuperAdmin() )
        end, 
        shouldSave = true, 
        preSave = function( data )
            if data.ignore == 1 then return 0 end
            return data.ignore
        end
    }, 
    { 
        name = "Private message", 
        type = "button", 
        text = "Open channel", 
        extra = "Open a private channel with this player", 
        onClick = function( data )
            channel = chatBox.private.createChannel( data.ply )
            if not chatBox.channels.isOpen( channel ) then
                chatBox.private.addChannel( channel )
            end
            chatBox.channels.focus( channel.name )
        end, 
        extraCanRun = function( ply )
            return chatBox.private.canMessage( ply )
        end, 
        disallowPlayerContext = true
    }, 
    { 
        name = "Custom command", 
        type = "button", 
        text = "Add", 
        extra = "Add a custom console command for quick access on players", 
        onClick = function( data )
            chatBox.sidePanel.players.addCustomSetting( data.ply )
        end, 
        disallowPlayerContext = true
    }, 
    { 
        name = "Mute", 
        toggleName = "Unmute", 
        toggle = true, 
        command = "ulx mute", 
        toggleCommand = "ulx unmute", 
        type = "command", 
        value = "isMuted", 
        default = false, 
        addToPlayerContext = true
    }, 
    { 
        name = "Jail", 
        toggle = true, 
        command = "ulx jail", 
        toggleCommand = "ulx unjail", 
        type = "command", 
        value = "jailed", 
        default = false
    }, 
    { 
        name = "God", 
        toggle = true, 
        command = "ulx god", 
        toggleCommand = "ulx ungod", 
        type = "command", 
        value = "inGod", 
        default = false, 
        extraCanRun = function( ply ) return ply == LocalPlayer() end
    }, 
    { 
        name = "Goto", 
        command = "ulx goto", 
        type = "command", 
        extraCanRun = function( ply ) return ply ~= LocalPlayer() end, 
        addToPlayerContext = true
    }, 
    { 
        name = "Bring", 
        command = "ulx bring", 
        type = "command", 
        extraCanRun = function( ply ) return ply ~= LocalPlayer() end
    }, 
    { 
        name = "Kick", 
        command = "ulx kick", 
        type = "command", 
        postArgs = { 
            function( data )
                local r = data.kickReason
                if r == "Unspecified" then return "" end
                return "You have been kicked for \"" .. r .. "\". If you rejoin, please read the rules" --kick adds its own "."
            end
        }, 
        requireConfirm = true, 
        closeOnTrigger = true
    }, 
    { 
        name = "Kick Reason", 
        value = "kickReason", 
        type = "options", 
        options = { "Unspecified", "Lagging server", "Prop block", "Prop spam", "Rope spam", "RDM", "Racism", "Minge", "Being a prick" }, 
        default = "Unspecified", 
        extra = "The reason for kicking the player", 
        parentSetting = "Kick"
    }, 
    { 
        name = "Freeze", 
        toggle = true, 
        command = "ulx freeze", 
        toggleCommand = "ulx unfreeze", 
        default = false, 
        value = "isFrozen", 
        type = "command", 
    }, 
    { 
        name = "Slay", 
        command = "ulx slay", 
        type = "command", 
        extraCanRun = function( ply ) return ply ~= LocalPlayer() end
    }, 
    { 
        name = "Freezeprops", 
        command = "ulx freezeprops", 
        type = "command", 
    }, 
    { 
        name = "Cleanup props", 
        command = "ulx cleanup", 
        type = "command", 
    }, 
    { 
        name = "Ragdoll", 
        toggle = true, 
        command = "ulx ragdoll", 
        toggleCommand = "ulx unragdoll", 
        default = false, 
        value = "isRagdolled", 
        type = "command", 
    }, 
}

hook.Add( "BC_playerRightClick", "BC_addPlySettings", function( ply, menu )
    for k, v in pairs( chatBox.sidePanel.players.template ) do
        if v.addToPlayerContext and v.type == "button" then

            if not chatBox.sidePanel.players.canAddSetting( ply, v ) then continue end

            local d = chatBox.sidePanel.players.settings[ply:SteamID()]
            if not d then continue end
            local name = v.name
            if v.toggle then
                name = d[v.value] and v.toggleName or v.name
            end
            menu:AddOption( name, function()
                v.onClick( d, v )
            end )
        end
    end
end )

function chatBox.sidePanel.players.parse()
    for k, v in pairs( chatBox.sidePanel.players.template ) do
        if v.type == "command" then
            v.type = "button"
            v.text = v.command
            v.toggleText = v.toggleCommand
            local tog = v.toggle
            local cmd = string.Explode( " ", v.command )
            local cmdTog
            if tog then
                cmdTog = string.Explode( " ", v.toggleCommand )
            end
            v.extra = "Run " .. v.command .. ( tog and ( " or " .. v.toggleCommand ) or "" ) .. " on this player"

            local preArgs = v.preArgs
            local postArgs = v.postArgs

            function v.onClick( data, setting )

                local state = false
                if tog then
                    state = data[setting.value]
                end
                local cmdCopy = table.Copy( state and cmdTog or cmd )

                if preArgs then
                    for l, w in pairs( preArgs ) do
                        if type( w ) == "function" then
                            w = w( data )
                        end
                        table.insert( cmdCopy, w )
                    end
                end
                
                table.insert( cmdCopy, data.ply:GetName() )

                if postArgs then
                    for l, w in pairs( postArgs ) do
                        if type( w ) == "function" then
                            w = w( data )
                        end
                        table.insert( cmdCopy, w )
                    end
                end

                RunConsoleCommand( unpack( cmdCopy ) )
            end
        end
        if v.type == "button" then
            function v.onRightClick( ply, setting )
                if setting.disallowPlayerContext then return end
                local m = DermaMenu()
                m:AddOption( setting.addToPlayerContext and "Remove from Player Context" or "Add to Player Context", function()
                    setting.addToPlayerContext = not setting.addToPlayerContext
                end )
                m:Open()
            end
        end
    end
end
