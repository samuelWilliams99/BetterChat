bc.sidePanel.channels.template = {
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
        name = "Display prints",
        value = "doPrints",
        type = "boolean",
        default = false,
        extra = "Set whether prints (from ulx, expression2, server, etc.) should be displayed in this channel",
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
        name = "Font",
        value = "font",
        type = "options",
        options = { "Default", "Default Large", "Original", "MonoSpace", "MonoSpace Large" },
        optionValues = { "BC_default", "BC_defaultLarge", "ChatFont", "BC_monospace", "BC_monospaceLarge" },
        default = "BC_default",
        extra = "Set the font of this channel",
        onChange = function( data )
            local txt = bc.channels.panels[data.name].text
            if not txt or not IsValid( txt ) then return end
            if data.font == "ChatFont" then
                bc.channels.messageDirect( data, bc.defines.colors.orange, "Warning: This font is not compatible with font editors like **bold**" )
            end
            txt:SetAllowDecorations( data.font ~= "ChatFont" )
            surface.SetFont( data.font )
            local _, h = surface.GetTextSize( "A" )
            txt.fontHeight = h - 2
            txt:SetFont( data.font )
            txt:Reload()
        end,
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
    }
}
