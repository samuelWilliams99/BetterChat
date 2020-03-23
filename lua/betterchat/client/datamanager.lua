chatBox.data = {}

local function saveFromTemplate( src, data, template )
    for k, v in pairs( template ) do
        if not v.shouldSave then continue end
        local value = src[v.value]
        if value == v.default then continue end 
        if v.preSave then 
            value = v.preSave( src ) 
        end
        data[v.value] = value
    end
end

local function loadFromTemplate( data, dest, template )
    for k, v in pairs( template ) do
        if not data[v.value] then continue end
        -- If data is options but value isn't a valid option
        if v.type == "options" and not table.HasValue( v.optionValues, data[v.value] ) then
            data[v.value] = v.default
        end
        dest[v.value] = data[v.value]
        dest.dataChanged[v.value] = true
    end
end

function chatBox.data.saveData()
    local data = {}
    data.channelSettings = {}
    data.playerSettings = {}
    data.extraPlayerSettings = chatBox.sidePanel.players.extraSettings
    data.enabled = chatBox.base.enabled
    data.size = chatBox.graphics.size
    if chatBox.graphics.derma.frame and IsValid( chatBox.graphics.derma.frame ) then
        local x, y = chatBox.graphics.derma.frame:GetPos()
        data.pos = { x = x, y = y }
    end

    for k, v in pairs( chatBox.channels.channels ) do
        data.channelSettings[v.name] = {}
        saveFromTemplate( v, data.channelSettings[v.name], chatBox.sidePanel.channels.template )
    end

    for k, v in pairs( chatBox.sidePanel.players.settings ) do
        if not k or k == "NULL" then continue end --Dont save bots
        data.playerSettings[k] = {}
        saveFromTemplate( v, data.playerSettings[k], chatBox.sidePanel.players.template )
    end

    if chatBox.autoComplete then
        local cmdUsage = table.filter( chatBox.autoComplete.cmds, function( x ) return x > 0 end )
        data.cmdUsage = table.Merge( table.Copy( chatBox.autoComplete.extraCmds or {} ), cmdUsage )
        data.emoteUsage = table.filter( chatBox.autoComplete.emoteUsage, function( x ) return x > 0 end )
    end

    file.Write( "bc_data_cl.txt", util.TableToJSON( data ) )
end

function chatBox.data.loadData() 
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end

    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then return end

    if data.pos then
        chatBox.graphics.derma.frame:SetPos( data.pos.x, data.pos.y )
    end

    if data.size then
        chatBox.sizeMove.resize( data.size.x, data.size.y, true )
    end

    if data.extraPlayerSettings then
        for k, v in pairs( data.extraPlayerSettings ) do
            chatBox.sidePanel.players.createCustomSetting( v )
        end
    end

    for k, v in pairs( chatBox.channels.channels ) do --load over already open channels
        v.dataChanged = {}
        if data.channelSettings and data.channelSettings[v.name] then
            loadFromTemplate( data.channelSettings[v.name], v, chatBox.sidePanel.channels.template )
            for k1, setting in pairs( chatBox.sidePanel.channels.template ) do
                if setting.onChange then setting.onChange( v ) end
            end
            data.channelSettings[v.name] = nil
        end
    end

    if data.channelSettings then
        for k, v in pairs( data.channelSettings ) do --load remaining channels
            channel = {}
            channel.name = k
            channel.needsData = true
            channel.dataChanged = {}
            loadFromTemplate( v, channel, chatBox.sidePanel.channels.template )
            table.insert( chatBox.channels.channels, channel )
        end
    end

    if data.playerSettings then
        for k, v in pairs( data.playerSettings ) do
            if not chatBox.sidePanel.players.settings[k] then
                chatBox.sidePanel.players.settings[k] = {}
                chatBox.sidePanel.players.settings[k].needsData = true
            end
            chatBox.sidePanel.players.settings[k].dataChanged = {}
            loadFromTemplate( v, chatBox.sidePanel.players.settings[k], chatBox.sidePanel.players.template )
        end
    end

    if not chatBox.autoComplete then chatBox.autoComplete = { cmds = {}, emoteUsage = {} } end
    if not chatBox.autoComplete.cmds then chatBox.autoComplete.cmds = {} end
    if not chatBox.autoComplete.emoteUsage then chatBox.autoComplete.emoteUsage = {} end

    if data.cmdUsage then
        for k, v in pairs( data.cmdUsage ) do
            chatBox.autoComplete.cmds[k] = v
        end
    end
    
    if data.emoteUsage then
        table.Merge( chatBox.autoComplete.emoteUsage, data.emoteUsage )
        chatBox.images.reloadUsedEmotesMenu()
    end
end

function chatBox.data.loadEnabled() 
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then 
        chatBox.base.enabled = true
    else
        chatBox.base.enabled = data.enabled == nil or data.enabled
    end
end

function chatBox.data.saveEnabled()
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then data = {} end
    data.enabled = true
    file.Write( "bc_data_cl.txt", util.TableToJSON( data ) )
end

function chatBox.data.deleteSaveData()
    file.Write( "bc_data_cl.txt", util.TableToJSON( { enabled = chatBox.base.enabled } ) )
end
