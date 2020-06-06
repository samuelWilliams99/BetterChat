bc.settings = bc.settings or {}

bc.settings.clientTemplate = {
    {
        name = "Chatbox size",
        type = "catDivider"
    },
    {
        name = "Chatbox width",
        value = "chatWidth",
        type = "number",
        extra = "Width in pixels of the chatbox",
        default = 600,
        min = 400,
        max = 2000,
    },
    {
        name = "Chatbox height",
        value = "chatHeight",
        type = "number",
        extra = "Height in pixels of the chatbox",
        default = 300,
        min = 250,
        max = 1000,
    },
    {
        name = "Apply size",
        type = "button",
        extra = "Apply width and height to the chatbox.",
        value = "applysize",
    },
    {
        name = "Reset size",
        type = "button",
        extra = "Reset width and height of the chatbox back to 600x300",
        value = "resetsize",
    },

    {
        name = "Font",
        type = "catDivider",
        extra = "Warning: Changing font clears your chat history",
    },
    {
        name = "Font family",
        value = "fontFamilyTemp",
        type = "options",
        options = CLIENT and bc.fontManager.fontFamilies,
        default = CLIENT and bc.fontManager.systemFont,
        extra = "Default channel and text entry font family",
        noServerDefault = true,
    },
    {
        value = "fontFamily",
        type = "options",
        options = CLIENT and bc.fontManager.fontFamilies,
        default = CLIENT and bc.fontManager.systemFont,
        noServerDefault = true,
        noMenu = true,
    },
    {
        name = "Font size",
        value = "fontSizeTemp",
        type = "number",
        default = 21,
        min = 10,
        max = 50,
        extra = "Default channel and text entry font size",
        noServerDefault = true,
    },
    {
        value = "fontSize",
        type = "number",
        default = 21,
        min = 10,
        max = 50,
        noServerDefault = true,
        noMenu = true,
    },
    {
        name = "Font line spacing",
        value = "fontLineSpacingTemp",
        type = "number",
        default = -2,
        min = -5,
        max = 15,
        extra = "Default channel font line spacing",
        noServerDefault = true,
    },
    {
        value = "fontLineSpacing",
        type = "number",
        default = -2,
        min = -5,
        max = 15,
        noServerDefault = true,
        noMenu = true,
    },
    {
        name = "Is bold",
        value = "fontBoldTemp",
        type = "boolean",
        default = false,
        extra = "Default channel and text entry bold",
        noServerDefault = true,
    },
    {
        value = "fontBold",
        type = "boolean",
        default = false,
        noServerDefault = true,
        noMenu = true,
    },
     {
        name = "Anti-Alias",
        value = "fontAntiAliasTemp",
        type = "boolean",
        default = false,
        extra = "Default channel and text entry anti-aliasing",
        noServerDefault = true,
    },
    {
        value = "fontAntiAlias",
        type = "boolean",
        default = false,
        noServerDefault = true,
        noMenu = true,
    },
    {
        name = "Scale Text entry",
        value = "fontScaleEntryTemp",
        type = "boolean",
        default = true,
        extra = "Should the text entry use the global font size (else, 21)",
        noServerDefault = true,
    },
    {
        value = "fontScaleEntry",
        type = "boolean",
        default = true,
        noServerDefault = true,
        noMenu = true,
    },
    {
        name = "Apply font",
        type = "button",
        extra = "Apply font data to chatbox, RELOADS CHATBOX!",
        value = "applyfont",
        requireConfirm = true,
    },
    {
        name = "Reset font",
        type = "button",
        extra = "Reset font data to default, RELOADS CHATBOX!",
        value = "resetfont",
        requireConfirm = true,
    },

    {
        name = "General",
        type = "catDivider"
    },
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
        name = "Channels",
        type = "catDivider"
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
        name = "Show channel events",
        value = "printChannelEvents",
        type = "boolean",
        extra = "Should messages like \"Channel All created\" be shown",
        default = true
    },

    {
        name = "Input",
        type = "catDivider"
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
        name = "Console Commands with '##'",
        value = "allowConsole",
        type = "boolean",
        extra = "Should any message starting with '##' be run as a console command instead",
        default = false,
    },

    {
        name = "Formatting",
        type = "catDivider"
    },
    {
        name = "Clickable links",
        value = "clickableLinks",
        type = "boolean",
        extra = "Should any hyperlinks posted to chat be clickable",
        default = true,
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
        name = "Close formatter on type",
        value = "formattingCloseOnType",
        type = "boolean",
        extra = "Should the formatting helper close when typing a normal character",
        default = true,
    },

    {
        name = "Sound",
        type = "catDivider"
    },
    {
        name = "Tick enabled",
        value = "doTick",
        type = "boolean",
        extra = "Should the chat ever play the Tick sound (based on other settings)",
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
        name = "Actions",
        type = "catDivider"
    },
    {
        name = "Enable/Restart BetterChat",
        type = "button",
        extra = "Restart the entirety of BetterChat, this will remove all chat history.",
        value = "restart",
    },
    {
        name = "Revert to old chat",
        type = "button",
        extra = "Revert back to the default Garry's Mod chat, this chat can be re-enabled with bc_enablechat",
        value = "disable",
    },
    {
        name = "Reload all BetterChat Files",
        type = "button",
        extra = "A complete reload of all BetterChat files, as if you left and rejoined the game. Warning: This can lead to some unexpected behaviour",
        value = "reload",
        requireConfirm = true,
    },
    {
        name = "Reload this settings panel",
        type = "button",
        extra = "Remove and re-generate this settings panel",
        value = "reloadSettingsPanel",
    },
    {
        name = "Factory Reset BetterChat",
        type = "button",
        extra = "Remove all BetterChat save data on your client (This will not remove you from groups)",
        value = "removesavedata",
        requireConfirm = true,
    },
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
        {
            value = "rainbow",
            defaultAccess = ULib.ACCESS_OPERATOR,
            extra = "Ability to use &&rainbow&& in chat",
        },
        {
            value = "pulsing",
            defaultAccess = ULib.ACCESS_OPERATOR,
            extra = "Ability to use %%pulsing%% in chat",
        },
        {
            value = "shaking",
            defaultAccess = ULib.ACCESS_OPERATOR,
            extra = "Ability to use $$shaking$$ in chat",
        },
        {
            value = "spaced",
            defaultAccess = ULib.ACCESS_ALL,
            extra = "Ability to use $$spaced$$ in chat",
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

function bc.settings.getValue( name, isServer )
    local setting = bc.settings.getObject( name, isServer )
    if not setting then return end

    local var = GetConVar( "bc_" .. ( isServer and "server_" or "" ) .. name )
    if not var then return setting.default end
    if setting.type == "boolean" then
        return var:GetBool()
    elseif setting.type == "number" then
        return var:GetInt()
    elseif setting.type == "string" or setting.type == "options" then
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
        if v.type == "button" or v.type == "catDivider" or ConVarExists( "bc_" .. v.value .. "_default" ) then continue end
        if v.noServerDefault then continue end

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

if not CLIENT then return end

concommand.Add( "bc_reloadSettingsPanel", function()
    bc.settings.generateToolMenu()
end )

function bc.settings.getDefault( setting )
    local val = "bc_" .. setting.value
    local def
    if ConVarExists( val .. "_default" ) and not setting.noServerDefault then
        if setting.type == "boolean" then
            def = GetConVar( val .. "_default" ):GetBool()
        elseif setting.type == "number" then
            def = GetConVar( val .. "_default" ):GetInt()
        elseif setting.type == "options" then
            def = GetConVar( val .. "_default" ):GetString()
        end
    else
        def = setting.default
    end

    if type( def ) == "boolean" then def = def and 1 or 0 end
    return def
end

hook.Add( "BC_initPanels", "BC_initClientConvars", function()
    for k, setting in pairs( bc.settings.clientTemplate ) do
        if setting.type == "button" or setting.type == "catDivider" then continue end

        local val = "bc_" .. setting.value

        if ConVarExists( val ) then continue end

        local def = bc.settings.getDefault( setting )
        if def == nil then
            p( val, setting )
        end
        local var = CreateClientConVar( val, def )

        if setting.type == "number" then
            cvars.AddChangeCallback( val, function( cv, old, new )
                old = tonumber( old )
                new = tonumber( new )
                if old == new then return end
                if type( new ) ~= "number" then
                    var:SetInt( old )
                    print( "Invalid value type" )
                    return
                end

                if ( setting.min or setting.max ) and ( new > ( setting.max or 1000000000 ) or new < ( setting.min or 0 ) ) then
                    var:SetInt( old )
                    print( "Valid out of range ( " .. ( setting.min or 0 ) .. ", " .. ( setting.max or 1000000000 ) .. " )" )
                    return
                end

                if setting.onChange then
                    setting.onChange( old, new )
                end
            end )
            continue
        elseif setting.type == "options" then
            cvars.AddChangeCallback( val, function( cv, old, new )
                if old == new then return end

                local options = setting.optionValues or setting.options
                if not table.HasValue( options, new ) then
                    var:SetString( old )
                    print( "Value not in list:" )
                    for _, v in pairs( options ) do
                        print( "    " .. v )
                    end
                else
                    if setting.onChange then
                        setting.onChange( old, new )
                    end
                end
            end )
            continue
        end

        if setting.onChange then
            cvars.AddChangeCallback( val, function( cv, old, new )
                setting.onChange( old, new )
            end )
        end
    end
end )

function bc.settings.generateToolMenu( panel )
    if not panel then
        panel = bc.settings.toolPanel
    else
        bc.settings.toolPanel = panel
    end

    if not panel then return end

    panel:ClearControls()
    for _, setting in pairs( bc.settings.clientTemplate ) do
        if setting.noMenu then continue end

        local val = "bc_" .. ( setting.value or "" )

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
        elseif setting.type == "options" then
            c = panel:ComboBox( setting.name, val )
            for k, optionName in pairs( setting.options ) do
                local optionValue = optionName
                if setting.optionValues then
                    optionValue = setting.optionValues[k]
                end

                c:AddChoice( optionName, optionValue )
            end
        elseif setting.type == "catDivider" then
            local container = vgui.Create( "DPanel" )
            container.Paint = nil
            container:SetSize( 100, 21 )

            local div = vgui.Create( "DShape", container )
            div:SetType( "Rect" )
            div:DockMargin( 0, 10, 0, 10 )
            div:Dock( FILL )
            div:SetColor( bc.defines.colors.gmodBlue )

            local text = vgui.Create( "DLabel", container )
            text:SetText( "  " .. setting.name .. "  " )
            text:SetTextColor( bc.defines.colors.gmodBlue )
            text:SizeToContents()
            function text:Paint( w, h )
                draw.RoundedBox( 0, 0, 0, w, h, bc.defines.colors.white )
            end

            function container:PerformLayout()
                text:CenterHorizontal()
                text:CenterVertical( 0.45 )
            end

            panel:AddItem( container )

            if setting.extra then
                panel:ControlHelp( setting.extra )
            end
            continue
        end

        c:SetTooltip( setting.extra )
    end

    -- Add some padding to bottom
    panel:DockPadding( 0, 0, 0, 10 )
end

hook.Add( "PopulateToolMenu", "BC_globalSettingsTool", function()
    spawnmenu.AddToolMenuOption( "Options", "Better Chat", "bc_settings", "Global Settings", "", "", bc.settings.generateToolMenu )
end )

function bc.settings.revertToDefaults()
    for k, setting in pairs( bc.settings.clientTemplate ) do
        if setting.type == "button" or setting.type == "catDivider" then continue end

        local val = "bc_" .. setting.value

        local cv = GetConVar( val )
        if not cv then continue end

        cv:Revert()
    end
end
