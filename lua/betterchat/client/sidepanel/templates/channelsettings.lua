chatBox.channelSettingsTemplate = {
	{
		name = "Channel name",
		value = "displayName",
		type = "string",
		trim = true,
		limit = 16,
		extra = "Set the name displayed for this tab in chat. Maximum of 16 characters",
		shouldSave = true,
		onChange = function(data) -- for groups
			if string.Left(data.name, 8) == "Group - " then
				data.group.name = data.displayName
				net.Start("BC_updateGroup")
				net.WriteUInt(data.group.id, 16)
				net.WriteString(util.TableToJSON(data.group))
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
		options = {"Always", "On mention", "Never"},
		optionValues = {0, 1, 2},
		default = 0,
		extra = "What should trigger the \"tick\" sound in this channel",
		shouldSave = true,
	},
	{
		name = "Play \"Pop\" sound",
		value = "popMode",
		type = "options",
		options = {"Always", "On mention", "Never"},
		optionValues = {0, 1, 2},
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
		onChange = function(data)
			local txt = chatBox.channelPanels[data.name].text
			if not txt or not IsValid(txt) then return end
			txt:SetFormattingEnabled(data.doFormatting)
			txt:Reload()
		end,
		shouldSave = true,
		onInit = function(data, textBox)
			textBox:SetFormattingEnabled(data.doFormatting)
		end,
	},
	{
		name = "Show Images",
		value = "showImages",
		type = "boolean",
		default = true,
		extra = "Set whether this channel should display color, links, images, etc.",
		onChange = function(data)
			local txt = chatBox.channelPanels[data.name].text
			if not txt or not IsValid(txt) then return end
			txt:SetImagesEnabled(data.showImages)
			txt:Reload()
		end,
		shouldSave = true,
		onInit = function(data, textBox)
			textBox:SetImagesEnabled(data.showImages)
		end,
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
		default = Color( 140, 140, 140)
	},
	{
		name = "Font",
		value = "font",
		type = "options",
		options = {"ChatFont", "Old ChatFont", "Mono-space"},
		optionValues = {"chatFont_18", "ChatFont", "Monospace"},
		default = "chatFont_18",
		extra = "Set the font of this channel",
		onChange = function(data)
			local txt = chatBox.channelPanels[data.name].text
			if not txt or not IsValid(txt) then return end
			txt:SetFont(data.font)
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
		shouldAdd = function(data)
			return (data.group or data.name == "Admin") and true or false
		end,
	}
}