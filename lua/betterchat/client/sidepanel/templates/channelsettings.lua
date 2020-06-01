bc.sidePanel.channels.template = {
    {
        name = "General",
        type = "catDivider",
    },
    {
        name = "Channel name",
        value = "displayName",
        type = "string",
        trim = true,
        limit = 16,
        extra = "Set the name displayed for this tab in chat. Maximum of 16 characters",
        shouldSave = true,
        onChange = function( data ) -- for groups
            if data.group then
                data.group.name = data.displayName
                net.Start( "BC_updateGroup" )
                net.WriteUInt( data.group.id, 16 )
                net.WriteString( util.TableToJSON( data.group ) )
                net.SendToServer()
            end
        end,
    },
    {
        name = "Set as display channel",
        value = "displayClosed",
        type = "boolean",
        unique = true,
        extra = "Set this channel as the channel displayed when the chat is closed",
        shouldSave = true,
    },
    {
        name = "Set open key",
        value = "openKey",
        type = "key",
        extra = "Bind this channel to a key",
        shouldSave = true,
    },
    {
        name = "Input background color",
        value = "textEntryColor",
        type = "color",
        extra = "Set the color of the text input background",
        shouldSave = true,
        default = bc.defines.theme.foreground
    },
    {
        name = "Open on message",
        value = "openOnMessage",
        type = "boolean",
        default = true,
        extra = "Should this channel automatically open when you receive a message",
        shouldSave = true,
        shouldAdd = function( data )
            return ( data.group or data.name == "Admin" ) and true or false
        end,
    },

    {
        name = "Sound",
        type = "catDivider",
    },
    {
        name = "Play \"tick\" sound",
        value = "tickMode",
        type = "options",
        options = { "Always", "On mention", "Never" },
        optionValues = { 0, 1, 2 },
        default = 0,
        extra = "What should trigger the \"tick\" sound in this channel",
        shouldSave = true,
    },
    {
        name = "Play \"pop\" sound",
        value = "popMode",
        type = "options",
        options = { "Always", "On mention", "Never" },
        optionValues = { 0, 1, 2 },
        default = 1,
        extra = "What should trigger the \"pop\" sound in this channel",
        shouldSave = true,
    },

    {
        name = "Formatting",
        type = "catDivider",
    },
    {
        name = "Allow formatting",
        value = "doFormatting",
        type = "boolean",
        default = true,
        extra = "Set whether this channel should display color, links, images, etc.",
        onChange = function( data )
            local txt = bc.channels.panels[data.name].text
            if not txt or not IsValid( txt ) then return end
            txt:SetFormattingEnabled( data.doFormatting )
            txt:Reload()
        end,
        shouldSave = true,
        onInit = function( data, textBox )
            textBox:SetFormattingEnabled( data.doFormatting )
        end,
    },
    {
        name = "Show images",
        value = "showImages",
        type = "boolean",
        default = true,
        extra = "Set whether this channel should display images",
        onChange = function( data )
            local txt = bc.channels.panels[data.name].text
            if not txt or not IsValid( txt ) then return end
            txt:SetGraphicsEnabled( data.showImages )
            txt:Reload()
        end,
        shouldSave = true,
        onInit = function( data, textBox )
            textBox:SetGraphicsEnabled( data.showImages )
        end,
    },
    {
        name = "Show gifs",
        value = "showGifs",
        type = "boolean",
        default = true,
        extra = "Set whether this channel should render gifs (can be laggy)",
        onChange = function( data )
            local txt = bc.channels.panels[data.name].text
            if not txt or not IsValid( txt ) then return end
            txt:SetGifsEnabled( data.showGifs )
            txt:Reload()
        end,
        shouldSave = true,
        onInit = function( data, textBox )
            textBox:SetGifsEnabled( data.showGifs )
        end,
    },
    {
        name = "Show timestamps",
        value = "showTimestamps",
        type = "boolean",
        default = false,
        extra = "Show timestamps before every message",
        shouldSave = true,
    },

    {
        name = "Font override",
        type = "catDivider",
    },
    {
        name = "Use font override",
        value = "useOverrideFont",
        type = "boolean",
        default = false,
        extra = "Use the following font info for this channel ONLY. The global setting for this is in the Q menu.",
        onChange = function( data )
            local newVal = data.useOverrideFont
            data.disabledSettings = data.disabledSettings or {}

            table.RemoveByValue( data.disabledSettings, "fontFamily" )
            table.RemoveByValue( data.disabledSettings, "fontSize" )
            table.RemoveByValue( data.disabledSettings, "fontBold" )
            table.RemoveByValue( data.disabledSettings, "fontAntiAlias" )
            table.RemoveByValue( data.disabledSettings, "fontLineSpacing" )

            if not newVal then
                table.Add( data.disabledSettings, { "fontFamily", "fontSize", "fontBold", "fontAntiAlias", "fontLineSpacing" } )
                bc.fontManager.updateChannelFont( data )
            else
                local defaultData = bc.fontManager.getGlobalFontData()
                data.fontFamily = defaultData.family
                data.fontSize = defaultData.size
                data.fontBold = defaultData.bold
                data.fontAntiAlias = defaultData.antiAlias
                data.fontLineSpacing = bc.settings.getValue( "fontLineSpacing" )
            end

            bc.sidePanel.channels.reloadSettings( data )
        end,
        shouldSave = true,
    },
    {
        name = "Font family",
        value = "fontFamily",
        type = "options",
        options = bc.fontManager.fontFamilies,
        default = bc.fontManager.systemFont,
        extra = "Set the font family for this channel only",
        onChange = function( data ) bc.fontManager.updateChannelFont( data ) end,
        shouldSave = true,
    },
    {
        name = "Font size",
        value = "fontSize",
        type = "number",
        default = 21,
        min = 10,
        max = 50,
        extra = "Set the font size for this channel only",
        onChange = function( data ) bc.fontManager.updateChannelFont( data ) end,
        shouldSave = true,
    },
    {
        name = "Font line spacing",
        value = "fontLineSpacing",
        type = "number",
        default = -2,
        min = -5,
        max = 15,
        extra = "Default channel font line spacing",
        onChange = function( data ) bc.fontManager.updateChannelFont( data ) end,
        shouldSave = true,
    },
    {
        name = "Is bold",
        value = "fontBold",
        type = "boolean",
        default = false,
        extra = "Set if this channels font is bold",
        onChange = function( data ) bc.fontManager.updateChannelFont( data ) end,
        shouldSave = true,
    },
    {
        name = "Anti-Alias",
        value = "fontAntiAlias",
        type = "boolean",
        default = false,
        extra = "Default channel and text entry anti-aliasing",
        onChange = function( data ) bc.fontManager.updateChannelFont( data ) end,
        shouldSave = true,
    },

    {
        name = "Channel interaction",
        type = "catDivider",
    },
    {
        name = "Display prints",
        value = "doPrints",
        type = "boolean",
        default = false,
        extra = "Set whether prints (from ulx, expression2, server, etc.) should be displayed in this channel",
        shouldSave = true,
    },
    {
        name = "Show All prefix",
        value = "showAllPrefix",
        type = "boolean",
        default = false,
        extra = "Should the prefix added in the All channel be shown here",
        shouldSave = true,
    },
    {
        name = "Replicate All",
        value = "replicateAll",
        type = "boolean",
        default = false,
        extra = "Should this channel replicate messages from the All channel (This channel's settings will still be used)",
        shouldSave = true,
    },
    {
        name = "Relay messages to All",
        value = "relayAll",
        type = "boolean",
        default = true,
        extra = "Should messages in this channel be relayed to the All channel",
        shouldSave = true,
    },
}
