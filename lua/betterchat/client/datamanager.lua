bc.data = {}
bc.data.savingEnabled = true

local function saveFromTemplate( src, data, template )
    for k, v in pairs( template ) do
        if not v.shouldSave then continue end
        local value = src[v.value]
        if value == v.default then continue end
        if v.preSave then
            value = v.preSave( src )
        end
        if IsColor( value ) then
            value = { r = value.r, g = value.g, b = value.b, a = value.a }
        end
        data[v.value] = value
    end
end

local function loadFromTemplate( data, dest, template )
    for k, v in pairs( template ) do
        if data[v.value] == nil then continue end
        -- If data is options but value isn't a valid option
        if v.type == "options" and not table.HasValue( v.optionValues, data[v.value] ) then
            data[v.value] = v.default
        end
        dest[v.value] = data[v.value]
    end
end

function bc.data.setSavingEnabled( val )
    bc.data.savingEnabled = val
end

function bc.data.saveData()
    if not bc.data.savingEnabled then return end

    local data = {}
    data.channelSettings = bc.data.channels or {}
    data.playerSettings = bc.data.players or {}
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
        data.cmdUsage = table.Merge( table.Copy( bc.autoComplete.disabledCmds or {} ), cmdUsage )
        data.emoteUsage = table.filter( bc.autoComplete.emoteUsage, function( x ) return x > 0 end )
    end

    if bc.settings.getValue( "saveOpenChannels" ) then
        data.openChannels = bc.channels.openChannels
    end

    file.Write( "bc_data_cl.txt", util.TableToJSON( data ) )
end

function bc.data.loadChannel( chan )
    if bc.data.channels and bc.data.channels[chan.name] then
        loadFromTemplate( bc.data.channels[chan.name], chan, bc.sidePanel.channels.template )
        bc.data.channels[chan.name] = nil
    end
end

function bc.data.loadPlayer( data )
    local ply = data.ply
    if bc.data.players and bc.data.players[ply:SteamID()] then
        loadFromTemplate( data, bc.data.players[ply:SteamID()], bc.sidePanel.players.template )
        bc.data.players[ply:SteamID()] = nil
    end
end

function bc.data.loadData()
    if not file.Exists( "bc_data_cl.txt", "DATA" ) then return end

    local data = util.JSONToTable( file.Read( "bc_data_cl.txt" ) )
    if not data then return end

    bc.data.pos = data.pos
    bc.data.size = data.size

    for k, v in pairs( data.extraPlayerSettings or {} ) do
        bc.sidePanel.players.createCustomSetting( v )
    end

    bc.data.channels = data.channelSettings or {}

    bc.data.players = data.playerSettings or {}

    bc.data.openChannels = data.openChannels

    bc.autoComplete = { cmds = {}, emoteUsage = {} }

    if data.cmdUsage then
        bc.autoComplete.cmds = data.cmdUsage
    end

    if data.emoteUsage then
        bc.autoComplete.emoteUsage = data.emoteUsage
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
