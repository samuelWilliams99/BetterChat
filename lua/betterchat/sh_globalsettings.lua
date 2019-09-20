chatBox.globalSettingsTemplate = {
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
		name = "Team chat opens recent PM",
		value = "teamOpenPM",
		type = "boolean",
		extra = "Should opening team chat open to most recent unread PM",
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
		name = "Console Commands with '¬'",
		value = "allowConsole",
		type = "boolean",
		extra = "Should any message starting with '¬' be run as a console command instead",
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
		name = "Hide Bug/workshop message",
		value = "hideBugMessage",
		type = "boolean",
		extra = "Stop the \"Found a bug?\" message from periodically showing in chat",
		default = false,
	},
	{	
		name = "Enable/Restart BetterChat",
		type = "button",
		extra = "Restart the entirety of BetterChat, this will remove all chat history.",
		value = "restart"
	},
	{	
		name = "Reload all BetterChat Files",
		type = "button",
		extra = "A complete reload of all BetterChat files, as if you left and rejoined the game. Warning: This can lead to some unexpected behaviour",
		value = "reload",
		requireConfirm = true
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
		value = "disable"
	}
}

chatBox.serverSettings = {
	{
		name = "Allow Group chats",
		value = "allowGroups",
		type = "boolean",
		extra = "Should players be able to create group chats",
		default = true
	},
	{
		name = "Allow Admin Group chats",
		value = "allowGroupsAdmin",
		type = "boolean",
		extra = "Should admins be able to create group chats",
		default = true
	},
	{
		name = "Allow Private chats",
		value = "allowPM",
		type = "boolean",
		extra = "Should players be able to open private chats",
		default = true
	},
	{
		name = "Allow Admin Private chats",
		value = "allowPMAdmin",
		type = "boolean",
		extra = "Should admins be able to open private chats",
		default = true
	},
	{
		name = "Replace Team chat",
		value = "replaceTeam",
		type = "boolean",
		extra = "Should BetterChat replace the team channel (This stops other addons like DarkRP overwriting/removing team chat)",
		default = false
	}
}

if CLIENT then

	concommand.Add("bc_disable", function()
		if chatBox.enabled then
			chatBox.closeChatBox()
			chatBox.disableChatBox()
		end
		chat.AddText(chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "has been disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it.")
	end)

	concommand.Add("bc_restart", function()
		if chatBox.enabled then
			chatBox.closeChatBox()
			chatBox.disableChatBox()
		end
		chatBox.enableChatBox()
	end)

	concommand.Add("bc_removesavedata", function()
		chatBox.deleteSaveData()
		if chatBox.enabled then
			chatBox.closeChatBox()
			chatBox.disableChatBox()
			chatBox.enableChatBox()
		end
		chat.AddText(chatBox.colors.yellow, "BetterChat ", chatBox.colors.ulx, "data has been deleted.")
	end)

	hook.Add("BC_InitPanels", "BC_ConVarInit", function()
		for k, setting in pairs(chatBox.globalSettingsTemplate) do
			local val = "bc_" .. setting.value
			if setting.type ~= "button" then
				if not ConVarExists(val) then
					local def
					if ConVarExists(val .. "_default") then
						if setting.type == "boolean" then
							def = GetConVar(val .. "_default"):GetBool()
						elseif setting.type == "number" then
							def = GetConVar(val .. "_default"):GetInt()
						end
					else
						def = setting.default
					end
					if type(def) == "boolean" then def = def and 1 or 0 end
					local var = CreateClientConVar(val, def)
				end
			end
		end
	end)

	hook.Add( "PopulateToolMenu", "BC_GlobalSettingsTool", function()
		spawnmenu.AddToolMenuOption( "Options", "Better Chat", "bc_settings", "Global Settings", "", "", function( panel )
			panel:ClearControls()
			for k, setting in pairs(chatBox.globalSettingsTemplate) do
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
						c.DoClick = function(self)
							if CurTime() - self.lastClick < 2 then
								RunConsoleCommand(c.val)
								self.lastClick = 0
							else
								self.lastClick = CurTime()
							end
						end

						c.Think = function(self)
							if CurTime() - self.lastClick < 2 then
								self:SetText("CONFIRM")
								self:SetTextColor(Color(255,0,0))
							else
								self:SetText(self.setting.name)
								self:SetTextColor(Color(0,0,0))
							end
						end
					end
				elseif setting.type == "number" then
					c = panel:NumSlider(setting.name, val, setting.min or 0, setting.max or 100, 0)
				end

				c:SetTooltip(setting.extra)

			end
		end )
	end )

end

function chatBox.getSetting(name)
	local var = GetConVar("bc_" .. name)
	--for now, all settings are boolean, maybe in the future change this to lookup the setting and get the type
	if not var then 
		return false 
	end

	local data
	for k, v in pairs(chatBox.globalSettingsTemplate) do
		if v.value == name then
			data = v
		end
	end
	if not data then return false end

	if data.type == "boolean" then
		return var:GetBool()
	elseif data.type == "number" then
		return var:GetInt()
	end
end

function chatBox.getServerSetting(name)
	local var = GetConVar("bc_server_" .. name)
	--for now, all settings are boolean, maybe in the future change this to lookup the setting and get the type
	if not var then 
		return false 
	end
	return var:GetBool()
end

hook.Add("BC_SharedInit", "BC_InitConvars", function()
	for k, v in pairs(chatBox.globalSettingsTemplate) do
		if v.type == "button" then continue end
		if not ConVarExists("bc_" .. v.value .. "_default") then
			local def = v.default
			if type(def) == "boolean" then def = def and 1 or 0 end
			CreateConVar("bc_" .. v.value .. "_default", def, FCVAR_REPLICATED+FCVAR_ARCHIVE+FCVAR_PROTECTED)
		end
	end

	for k, v in pairs(chatBox.serverSettings) do
		local def = v.default
		if type(def) == "boolean" then def = def and 1 or 0 end
		CreateConVar("bc_server_" .. v.value, def, FCVAR_REPLICATED+FCVAR_ARCHIVE+FCVAR_PROTECTED)
	end
end)