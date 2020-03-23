local function useOverload()
    return chatBox.settings.getObject( "maxLength", true ).default ~= chatBox.settings.getServerValue( "maxLength" )
end

local function globalSend( self, txt )
    if useOverload() then
        net.Start( "BC_sayOverload" )
        net.WriteBool( false )
        net.WriteBool( not LocalPlayer():Alive() )
        net.WriteString( txt )
        net.SendToServer()
    else
        RunConsoleCommand( "say", txt )
    end
end
local function teamSend( self, txt )
    if useOverload() then
        net.Start( "BC_sayOverload" )
        net.WriteBool( true )
        net.WriteBool( not LocalPlayer():Alive() )
        net.WriteString( txt )
        net.SendToServer()
    else
        RunConsoleCommand( "say_team", txt )
    end
end

hook.Add( "BC_initPanels", "BC_initAddMainChannels", function()
    table.insert( chatBox.channels.channels, {
        name = "All",
        icon = "world.png",
        send = globalSend,
        displayClosed = true,
        doPrints = true,
        addNewLines = true,
        trim = true,
        disabledSettings = { "relayAll", "openKey", "replicateAll", "showAllPrefix" },
        tickMode = 2,
        popMode = 2,
        openOnStart = true,
        disallowClose = true,
        relayAll = false,
        position = 1,
    } )
    table.insert( chatBox.channels.channels, {
        name = "Players",
        icon = "group.png",
        send = globalSend,
        trim = true,
        addNewLines = true,
        openOnStart = true,
        disallowClose = true,
        position = 2,
    } )
    if not DarkRP then
        table.insert( chatBox.channels.channels, {
            name = "Team",
            icon = "group.png",
            send = teamSend,
            onMessage = function()
                chatBox.private.lastMessaged = nil
            end,
            doPrints = true,
            addNewLines = true,
            disabledSettings = { "openKey" },
            allFunc = function( self, tab, idx )
                table.insert( tab, idx, chatBox.defines.theme.team )
                table.insert( tab, idx + 1, "(TEAM) " )
            end,
            openOnStart = true,
            disallowClose = true,
            textEntryColor = chatBox.defines.theme.teamTextEntry,
            replicateAll = true,
            position = 3,
        } )
    end
end )
