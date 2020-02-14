--[[
	Save:
		chatBox.extraPlayerSettings
		chatBox.playerSettings
		chatBox.channelSettings
]]--

function filter(tab, f)
	for k, v in pairs(tab) do
		if not f(v) then
			tab[k] = nil
		end
	end
	return tab
end

function chatBox.saveData()
	local data = {}
	data.channelSettings = {}
	data.playerSettings = {}
	data.extraPlayerSettings = chatBox.extraPlayerSettings
	data.enabled = chatBox.enabled
	data.size = chatBox.graphics.size
	if chatBox.graphics.frame and IsValid(chatBox.graphics.frame) then
		local x, y = chatBox.graphics.frame:GetPos()
		data.pos = { x = x, y = y }
	end

	for k, v in pairs(chatBox.channels) do
		data.channelSettings[v.name] = {}
		saveFromTemplate(v, data.channelSettings[v.name], chatBox.channelSettingsTemplate)
	end

	for k, v in pairs(chatBox.playerSettings) do
		if not k or k == "NULL" then continue end --Dont save bots
		data.playerSettings[k] = {}
		saveFromTemplate(v, data.playerSettings[k], chatBox.playerSettingsTemplate)
	end

	if chatBox.autoComplete then
		data.cmdUsage = filter(table.Copy(chatBox.autoComplete.cmds), function(x) return x > 0 end)
		for k, v in pairs(chatBox.autoComplete.extraCmds) do
			if not data.cmdUsage[k] then
				data.cmdUsage[k] = v
			end
		end
		data.emoteUsage = filter(table.Copy(chatBox.autoComplete.emoteUsage), function(x) return x > 0 end)
	end

	file.Write( "bc_data_cl.txt", util.TableToJSON(data) )
end

function chatBox.loadData() 
	print("attempt load")
	if not file.Exists("bc_data_cl.txt", "DATA") then 
		print("NO DATA")
		timer.Simple(5, function()
			print("======================================")
			print("BETTERCHAT DATA WAS RESET")
			print("======================================")
			surface.PlaySound("air-raid.wav")
		end)
		return 
	end

	local data = util.JSONToTable(file.Read("bc_data_cl.txt"))
	if not data then 
		print("MALFORMED DATA")
		print(file.Read("bc_data_cl.txt"))
		timer.Simple(5, function()
			print("======================================")
			print("BETTERCHAT DATA WAS RESET")
			print("======================================")
			surface.PlaySound("air-raid.wav")
		end)
		return
	end
	local t = table.Copy(data)
	for k, v in pairs(t) do
		if type(v) == "table" then
			t[k] = table.Count(v)
		end
	end
	PrintTable(t)
	if t.emoteUsage == 0 then
		timer.Simple(5, function()
			print("======================================")
			print("BETTERCHAT DATA WAS RESET")
			print("======================================")
			surface.PlaySound("air-raid.wav")
		end)
	end

	if data.pos then
		chatBox.graphics.frame:SetPos(data.pos.x, data.pos.y)
	end

	if data.size then
		chatBox.resizeBox(data.size.x, data.size.y, true)
	end

	if data.extraPlayerSettings then
		for k, v in pairs(data.extraPlayerSettings) do
			chatBox.createPlayerSetting(v)
		end
	end

	for k, v in pairs(chatBox.channels) do --load over already open channels quickly
		v.dataChanged = {}
		if data.channelSettings and data.channelSettings[v.name] then
			loadFromData(data.channelSettings[v.name], v)
			for k1, setting in pairs(chatBox.channelSettingsTemplate) do
				if setting.onChange then setting.onChange(v) end
			end
			data.channelSettings[v.name] = nil
		end
	end

	if data.channelSettings then
		for k, v in pairs(data.channelSettings) do --load remaining channels slowly
			channel = {}
			channel.name = k
			channel.needsData = true
			channel.dataChanged = {}
			loadFromData(v, channel)
			table.insert(chatBox.channels, channel)
		end
	end

	if data.playerSettings then
		for k, v in pairs(data.playerSettings) do
			if not chatBox.playerSettings[k] then
				chatBox.playerSettings[k] = {}
				chatBox.playerSettings[k].needsData = true
			end
			chatBox.playerSettings[k].dataChanged = {}
			loadFromData(v, chatBox.playerSettings[k])
		end
	end

	if not chatBox.autoComplete then chatBox.autoComplete = {cmds={}, emoteUsage={}} end
	if not chatBox.autoComplete.cmds then chatBox.autoComplete.cmds = {} end
	if not chatBox.autoComplete.emoteUsage then chatBox.autoComplete.emoteUsage = {} end

	if data.cmdUsage then
		for k, v in pairs(data.cmdUsage) do
			chatBox.autoComplete.cmds[k] = v
		end
	end
	
	if data.emoteUsage then
		for k, v in pairs(data.emoteUsage) do
			chatBox.autoComplete.emoteUsage[k] = v
		end
		chatBox.reloadUsedEmotesMenu()
	end

end

function chatBox.loadEnabled() 
	if not file.Exists("bc_data_cl.txt", "DATA") then return end
	local data = util.JSONToTable(file.Read("bc_data_cl.txt"))
	if not data then 
		chatBox.enabled = true
	else
		chatBox.enabled = data.enabled == nil or data.enabled
	end
end

function chatBox.saveEnabled()
	if not file.Exists("bc_data_cl.txt", "DATA") then return end
	local data = util.JSONToTable(file.Read("bc_data_cl.txt"))
	if not data then data = {} end
	data.enabled = true
	file.Write( "bc_data_cl.txt", util.TableToJSON(data) )
end

function chatBox.deleteSaveData()
	file.Write( "bc_data_cl.txt", util.TableToJSON({enabled=chatBox.enabled}) )
end


function saveFromTemplate(src, data, template)
	for k, v in pairs(template) do
		if not v.shouldSave then continue end
		local value = src[v.value]
		if value == v.default then continue end 
		if v.preSave then 
			value = v.preSave(src) 
		end
		data[v.value] = value
	end
end

function loadFromData(data, dest)
	for k, v in pairs(data) do
		dest[k] = v
		dest.dataChanged[k] = true
	end
end