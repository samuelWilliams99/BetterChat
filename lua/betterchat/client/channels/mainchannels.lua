bc.mainChannels = {}
bc.mainChannels.allHistory = {}

local function globalSend( self, txt )
    net.Start( "BC_sayOverload" )
    net.WriteBool( false )
    net.WriteString( txt )
    net.SendToServer()
end
local function teamSend( self, txt )
    net.Start( "BC_sayOverload" )
    net.WriteBool( true )
    net.WriteString( txt )
    net.SendToServer()
end

local serverSetting = bc.settings.getServerValue

hook.Add( "BC_initPanels", "BC_initAddMainChannels", function()
    bc.mainChannels.allHistory = {}
    bc.channels.add( {
        name = "All",
        icon = "world.png",
        send = globalSend,
        displayClosed = true,
        doPrints = true,
        addNewLines = true,
        trim = true,
        disabledSettings = { "relayAll", "openKey", "replicateAll", "showAllPrefix" },
        onMessage = function( self, data )
            table.insert( bc.mainChannels.allHistory, data )
            if #bc.mainChannels.allHistory > 15 then
                table.remove( bc.mainChannels.allHistory, 1 )
            end
        end,
        tickMode = 2,
        popMode = 1,
        openOnStart = true,
        disallowClose = true,
        relayAll = false,
        position = 1,
    } )
    bc.channels.add( {
        name = "Players",
        icon = "group.png",
        send = globalSend,
        trim = true,
        popMode = 2,
        addNewLines = true,
        position = 2,
    } )
    bc.channels.add( {
        name = "Team",
        icon = "group.png",
        send = teamSend,
        trim = true,
        onMessage = function()
            bc.private.lastMessaged = nil
        end,
        doPrints = true,
        addNewLines = true,
        disabledSettings = { "openKey" },
        allFunc = function( self, tab, idx )
            table.insert( tab, idx, bc.defines.theme.team )
            table.insert( tab, idx + 1, "(" .. self.displayName .. ") " )
        end,
        openOnStart = function( self )
            return bc.mainChannels.teamEnabled()
        end,
        textEntryColor = bc.defines.theme.teamTextEntry,
        replicateAll = true,
        position = 3,
    } )
    bc.channels.add( {
        name = "Prints",
        icon = "application_xp_terminal.png",
        addNewLines = true,
        doPrints = true,
        position = 100,
        noSend = true,
        tickMode = 2,
        popMode = 2,
        disabledSettings = { "doPrints", "relayAll", "replicateAll", "showAllPrefix", "showImages", "showGifs" },
        showTimestamps = true,
    } )
end )

function bc.mainChannels.teamEnabled()
    return not ( DarkRP or serverSetting( "removeTeam" ) or serverSetting( "replaceTeam" ) )
end

local function channelButton( menu, chanName )
    if bc.channels.isOpen( chanName ) then return end
    local channel = bc.channels.get( chanName )

    menu:AddOption( channel.displayName, function()
        local chan = bc.channels.get( chanName )
        if not chan then return end

        bc.channels.open( chanName )
        bc.channels.focus( chanName )
    end )
end

hook.Add( "BC_makeChannelButtons", "BC_makeMainButtons", function( menu )
    channelButton( menu, "Players" )
    if bc.mainChannels.teamEnabled() then
        channelButton( menu, "Team" )
    end
    channelButton( menu, "Prints" )
end )
