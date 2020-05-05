bc.settings = {}
bc.settings.clientTemplate = {
    {
        name = "Chat Fade time",
        value = "fadeTime",
        type = "number",
        extra = "Time for a chat message to fade (0 for never)",
        default = 10,
        min = 0,
        max = 30,
    },
    {
        name = "Maximum history",
        value = "chatHistory",
        type = "number",
        extra = "Number of messages received before old messages are deleted",
        default = 200,
        min = 20,
        max = 1000,
    },
    {
        name = "Team chat opens recent PM",
        value = "teamOpenPM",
        type = "boolean",
        extra = "Should opening team chat open to most recent unread PM",
        default = true,
    },
    {
        name = "Remember channel on close",
        value = "rememberChannel",
        type = "boolean",
        extra = "Should betterchat remember your most recent channel when opening",
        default = false,
    },
    {
        name = "Save open channels on exit",
        value = "saveOpenChannels",
        type = "boolean",
        extra = "Should channels from your previous session be re-opened on join",
        default = true,
    },
    {
        name = "Numbered channel shortcuts",
        value = "channelNumShortcut",
        type = "boolean",
        extra = "Should the shortcuts CTRL+[0-9] change channel",
        default = true,
    },
    {
        name = "Display suggestions",
        value = "acDisplay",
        type = "boolean",
        extra = "Should autocomplete suggestions be showed in the text input",
        default = true,
    },
    {
        name = "Autocomplete Suggest on usage",
        value = "acUsage",
        type = "boolean",
        extra = "Should autocomplete order its suggestions based on your usage of them",
        default = true,
    },
    {
        name = "Clickable links",
        value = "clickableLinks",
        type = "boolean",
        extra = "Should any hyperlinks posted to chat be clickable",
        default = true,
    },
    {
        name = "Show channel events",
        value = "printChannelEvents",
        type = "boolean",
        extra = "Should messages like \"Channel All created\" be shown",
        default = true
    },
    {
        name = "Console Commands with '%'",
        value = "allowConsole",
        type = "boolean",
        extra = "Should any message starting with '%' be run as a console command instead",
        default = false,
    },
    {
        name = "Auto Convert Emoticons",
        value = "convertEmotes",
        type = "boolean",
        extra = "Should emotes like \":)\" be converted to their respective emoticon. Note this is purely client side, others will still see the emoticon",
        default = true,
    },
    {
        name = "Show gifs",
        value = "showGifs",
        type = "boolean",
        extra = "Should gifs from !giphy (if it is enabled) be rendered",
        default = true,
    },
    {
        name = "Pop enabled",
        value = "doPop",
        type = "boolean",
        extra = "Should the chat ever play the Pop sound (based on other settings)",
        default = true,
    },
    {
        name = "Tick enabled",
        value = "doTick",
        type = "boolean",
        extra = "Should the chat ever play the Tick sound (based on other settings)",
        default = true,
    },
    {
        name = "Format colors",
        value = "formatColors",
        type = "boolean",
        extra = "Should colors typed in chat be displayed in their respective color",
        default = true,
    },
    {
        name = "Color commands",
        value = "colorCmds",
        type = "boolean",
        extra = "Should messages starting with ! be dimmed",
        default = true,
    },
    {
        name = "Enable/Restart BetterChat",
        type = "button",
        extra = "Restart the entirety of BetterChat, this will remove all chat history.",
        value = "restart",
    },
    {
        name = "Reload all BetterChat Files",
        type = "button",
        extra = "A complete reload of all BetterChat files, as if you left and rejoined the game. Warning: This can lead to some unexpected behaviour",
        value = "reload",
        requireConfirm = true,
    },
    {
        name = "Factory Reset BetterChat",
        type = "button",
        extra = "Remove all BetterChat save data on your client (This will not remove you from groups)",
        value = "removesavedata",
        requireConfirm = true,
    },
    {
        name = "Revert to old chat",
        type = "button",
        extra = "Revert back to the default Garry's Mod chat, this chat can be re-enabled with bc_enablechat",
        value = "disable",
    }
}

bc.settings.serverTemplate = {
    {
        name = "Replace Team chat",
        value = "replaceTeam",
        type = "boolean",
        extra = "Should BetterChat replace the team channel (This stops other addons like DarkRP overwriting/removing team chat)",
        default = false,
        onChange = function( self, old, new )
            if old == new then return end -- Not really a change then is it

            if new ~= "0" then
                if bc.settings.getServerValue( "removeTeam" ) then
                    print( "[BetterChat] Cannot replaceTeam while bc_server_removeTeam is true" )
                    return old
                end
                ULib.clientRPC( bc.base.getEnabledPlayers(), "bc.teamOverload.enable" )
            else
                ULib.clientRPC( bc.base.getEnabledPlayers(), "bc.teamOverload.disable" )
            end
        end,
    },
    {
        name = "Remove default team chat",
        value = "removeTeam",
        type = "boolean",
        extra = "Should default team chat be disabled",
        default = false,
        onChange = function( self, old, new )
            if old == new then return end -- Not really a change then is it

            if new ~= "0" then
                if bc.settings.getServerValue( "replaceTeam" ) then
                    print( "[BetterChat] Cannot removeTeam while bc_server_replaceTeam is true" )
                    return "0"
                end
                if DarkRP then
                    print( "[BetterChat] Team is already removed in DarkRP" )
                    return "0"
                end
                ULib.clientRPC( bc.base.getEnabledPlayers(), "bc.channels.close", "Team" )
            else
                ULib.clientRPC( bc.base.getEnabledPlayers(), "bc.channels.open", "Team" )
            end
        end,
    },
    {
        name = "Maximum message length",
        value = "maxLength",
        type = "number",
        extra = "Maximum length of message",
        default = 126,
    },
    {
        name = "Giphy API Key",
        value = "giphyKey",
        type = "string",
        extra = "Giphy API key needed for !giphy",
        default = "",
        onChange = function( self, old, new )
            bc.giphy.getGiphyURL( "thing", function( success, data )
                if success then
                    print( "[BetterChat] Giphy key test successful, giphy command enabled." )
                    bc.giphy.enabled = true
                    ULib.clientRPC( bc.base.getEnabledPlayers(), "bc.images.enableGiphy" )
                else
                    print( "[BetterChat] No valid Giphy API key found in bc_server_giphykey, giphy command disabled. Generate an app key from https://developers.giphy.com/ to use this feature." )
                end
            end )
        end,
    },
    {
        name = "Player gif hourly limit",
        value = "giphyHourlyLimit",
        type = "number",
        extra = "Maximum giphy calls a single player is allowed in 1 hour",
        default = 10,
    },
}

hook.Add( "Initialize", "BC_ulxSetup", function()
    bc.settings.ulxPermissions = {
        {
            value = "chatlogs",
            defaultAccess = ULib.ACCESS_SUPERADMIN,
            extra = "Enables the 'Logs' channel which receives all messages from groups, PM, team, etc.",
        },
        {
            value = "giphy",
            defaultAccess = ULib.ACCESS_OPERATOR,
            extra = "Ability to use !giphy if bc_server_giphykey is valid",
        },
        {
            value = "color",
            defaultAccess = ULib.ACCESS_OPERATOR,
            extra = "Ability to use [#ff0000]Red in chat",
        },
        {
            value = "groups",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use BetterChat groups",
        },
        {
            value = "italics",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use *italics* in chat",
        },
        {
            value = "bold",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use **bold** in chat",
        },
        {
            value = "underline",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use __underline__ in chat",
        },
        {
            value = "strike",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use ~~strike~~ in chat",
        },
    }
    
    if SERVER then
        for _, perm in pairs( bc.settings.ulxPermissions ) do
            ULib.ucl.registerAccess( "ulx bc_" .. perm.value, perm.defaultAccess, perm.extra, "BetterChat" )
        end
    end
end )

if SERVER then
    hook.Add( "Initialize", "BC_handleChatTime", function()
        -- Gmod implements 0.5s delay by default, but this chat bypasses it
        -- It is too risky to allow 0s delay, spam can crash clients
        -- It's for your own good!
        local chattimeConvar = GetConVar( "ulx_chattime" )
        if chattimeConvar and chattimeConvar:GetFloat() == 0 then
            chattimeConvar:SetFloat( 0.5 )
        end
    end )
end

function bc.settings.isAllowed( ply, perm )
    if not perm then
        perm = ply
        ply = LocalPlayer()
    end
    if not ply or not ply:IsValid() then return true end
    if string.sub( perm, 1, 4 ) == "ulx " then
        perm = string.sub( perm, 5 )
    end
    return tobool( ULib.ucl.query( ply, "ulx " .. perm ) )
end

if CLIENT then
    function bc.settings.getDefault( setting )
        local val = "bc_" .. setting.value
        local def
        if ConVarExists( val .. "_default" ) then
            if setting.type == "boolean" then
                def = GetConVar( val .. "_default" ):GetBool()
            elseif setting.type == "number" then
                def = GetConVar( val .. "_default" ):GetInt()
            end
        else
            def = setting.default
        end

        if type( def ) == "boolean" then def = def and 1 or 0 end
        return def
    end

    hook.Add( "BC_initPanels", "BC_initClientConvars", function()
        for k, setting in pairs( bc.settings.clientTemplate ) do
            local val = "bc_" .. setting.value

            if setting.type == "button" then continue end
            if ConVarExists( val ) then continue end

            local def = bc.settings.getDefault( setting )
            local var = CreateClientConVar( val, def )

            if setting.min or setting.max then
                cvars.AddChangeCallback( val, function( cv, old, new )
                    old = tonumber( old )
                    new = tonumber( new )
                    if old == new then return end
                    if type( new ) ~= "number" or new > ( setting.max or 1000000000 ) or new < ( setting.min or 0 ) then
                        var:SetInt( old )
                    end
                end )
            end
        end
    end )

    hook.Add( "PopulateToolMenu", "BC_globalSettingsTool", function()
        spawnmenu.AddToolMenuOption( "Options", "Better Chat", "bc_settings", "Global Settings", "", "", function( panel )
            panel:ClearControls()
            for k, setting in pairs( bc.settings.clientTemplate ) do
                local val = "bc_" .. setting.value

                local c
                if setting.type == "boolean" then
                    c = panel:CheckBox( setting.name, val )
                elseif setting.type == "button" then
                    c = panel:Button( setting.name, val )
                    if setting.requireConfirm then
                        c.setting = setting
                        c.lastClick = 0
                        c.val = val
                        function c:DoClick()
                            if CurTime() - self.lastClick < 2 then
                                RunConsoleCommand( c.val )
                                self.lastClick = 0
                            else
                                self.lastClick = CurTime()
                            end
                        end

                        function c:Think()
                            if CurTime() - self.lastClick < 2 then
                                self:SetText( "CONFIRM" )
                                self:SetTextColor( bc.defines.colors.red )
                            else
                                self:SetText( self.setting.name )
                                self:SetTextColor( bc.defines.colors.black )
                            end
                        end
                    end
                elseif setting.type == "number" then
                    c = panel:NumSlider( setting.name, val, setting.min or 0, setting.max or 100, 0 )
                end

                c:SetTooltip( setting.extra )
            end
        end )
    end )

    function bc.settings.revertToDefaults()
        for k, setting in pairs( bc.settings.clientTemplate ) do
            local val = "bc_" .. setting.value

            if setting.type == "button" then continue end

            local cv = GetConVar( val )
            if not cv then continue end

            cv:Revert()
        end
    end

end

function bc.settings.getValue( name, isServer )
    local setting = bc.settings.getObject( name, isServer )
    if not setting then return end

    local var = GetConVar( "bc_" .. ( isServer and "server_" or "" ) .. name )
    if not var then return setting.default end
    if setting.type == "boolean" then
        return var:GetBool()
    elseif setting.type == "number" then
        return var:GetInt()
    elseif setting.type == "string" then
        return var:GetString()
    end
end

function bc.settings.getServerValue( name )
    return bc.settings.getValue( name, true )
end

function bc.settings.getObject( name, isServer )
    for k, v in pairs( isServer and bc.settings.serverTemplate or bc.settings.clientTemplate ) do
        if v.value == name then
            return v
        end
    end
end

hook.Add( "BC_sharedInit", "BC_initServerConvars", function()
    for k, v in pairs( bc.settings.clientTemplate ) do
        if v.type == "button" or ConVarExists( "bc_" .. v.value .. "_default" ) then continue end

        local def = v.default
        if type( def ) == "boolean" then def = def and 1 or 0 end
        CreateConVar( "bc_" .. v.value .. "_default", def, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
    end

    for k, v in pairs( bc.settings.serverTemplate ) do
        local def = v.default
        if type( def ) == "boolean" then def = def and 1 or 0 end
        local cvar = CreateConVar( "bc_server_" .. v.value, def, FCVAR_REPLICATED + FCVAR_ARCHIVE + FCVAR_PROTECTED )
        if not v.onChange then continue end

        if SERVER then
            cvars.AddChangeCallback( "bc_server_" .. v.value, function( _, old, new )
                local ret = v.onChange( v, old, new )
                if ret ~= nil then
                    if v.type == "bool" then
                        cvar:SetBool( ret )
                    elseif v.type == "number" then
                        cvar:SetInt( ret )
                    elseif v.type == "string" then
                        cvar:SetString( ret )
                    end
                end
            end )
        end
    end
end )
