bc.data = {}

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

function bc.data.saveData()
    local data = {}
    data.channelSettings = {}
    data.playerSettings = {}
    data.extraPlayerSettings = bc.sidePanel.players.extraSettings
    data.enabled = bc.base.enabled
    data.size = bc.graphics.size
    if bc.graphics.derma.frame and IsValid( bc.graphics.derma.frame ) then
        local x, y = bc.graphics.derma.frame:GetPos()
        data.pos = { x = x, y = y }
    end

    for k, v in pairs( bc.channels.channels ) do
        data.channelSettings[v.name] = {}
        saveFromTemplate( v, data.channelSettings[v.name], bc.sidePanel.channels.template )
    end

    for k, v in pairs( bc.sidePanel.players.settings ) do
        if not k or k == "NULL" then continue end --Dont save bots
        data.playerSettings[k] = {}
        saveFromTemplate( v, data.playerSettings[k], bc.sidePanel.players.template )
    end

    if bc.autoComplete then
        local cmdUsage = table.filter( bc.autoComplete.cmds, function( x ) return x > 0 end )
        data.cmdUsage = table.Merge( table.Copy( bc.autoComplete.extraCmds or {} ), cmdUsage )
        data.emoteUsage = table.filter( bc.autoComplete.emoteUsage, function( x ) return x > 0 end )
    end

    file.Write( "bc_data_cl.txt", util.TableToJSON( data ) )
end

function bc.data.loadData()
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end

    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then return end

    if data.pos then
        bc.graphics.derma.frame:SetPos( data.pos.x, data.pos.y )
    end

    if data.size then
        bc.sizeMove.resize( data.size.x, data.size.y, true )
    end

    if data.extraPlayerSettings then
        for k, v in pairs( data.extraPlayerSettings ) do
            bc.sidePanel.players.createCustomSetting( v )
        end
    end

    for k, v in pairs( bc.channels.channels ) do --load over already open channels
        v.dataChanged = {}
        if data.channelSettings and data.channelSettings[v.name] then
            loadFromTemplate( data.channelSettings[v.name], v, bc.sidePanel.channels.template )
            for k1, setting in pairs( bc.sidePanel.channels.template ) do
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
            loadFromTemplate( v, channel, bc.sidePanel.channels.template )
            table.insert( bc.channels.channels, channel )
        end
    end

    if data.playerSettings then
        for k, v in pairs( data.playerSettings ) do
            if not bc.sidePanel.players.settings[k] then
                bc.sidePanel.players.settings[k] = {}
                bc.sidePanel.players.settings[k].needsData = true
            end
            bc.sidePanel.players.settings[k].dataChanged = {}
            loadFromTemplate( v, bc.sidePanel.players.settings[k], bc.sidePanel.players.template )
        end
    end

    if not bc.autoComplete then bc.autoComplete = { cmds = {}, emoteUsage = {} } end
    if not bc.autoComplete.cmds then bc.autoComplete.cmds = {} end
    if not bc.autoComplete.emoteUsage then bc.autoComplete.emoteUsage = {} end

    if data.cmdUsage then
        for k, v in pairs( data.cmdUsage ) do
            bc.autoComplete.cmds[k] = v
        end
    end

    if data.emoteUsage then
        table.Merge( bc.autoComplete.emoteUsage, data.emoteUsage )
        bc.images.reloadUsedEmotesMenu()
    end
end

function bc.data.loadEnabled()
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then
        bc.base.enabled = true
    else
        bc.base.enabled = data.enabled == nil or data.enabled
    end
end

function bc.data.saveEnabled()
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end
    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then data = {} end
    data.enabled = true
    file.Write( "bc_data_cl.txt", util.TableToJSON( data ) )
end

function bc.data.deleteSaveData()
    file.Write( "bc_data_cl.txt", util.TableToJSON( { enabled = bc.base.enabled } ) )
end
