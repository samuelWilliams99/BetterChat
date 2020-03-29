bc = bc or {}
bc.base = bc.base or {}

--[[
naming convention
all vars/functions camel
always full names
hookIds: BC_camelCase
eventNames: BC_camelCase

TODO

ctrt+w for close tab
make players closable
Tab in custom player command moves to next box
make it clear that "mute" means "ulx mute", not ignore
add ignore to context menu
group rename print
swtich private and admin channels to use psay and asay internally

chat cooldown - sounds like a fair bit of work, especially when other addons already do it
	maybe call onchat with generic ply/message to trigger it?

global settings menu
    using utility menu is shit
    make my own menu
    make it a Spanner icon
    change Open channel button to be "+", put this icon next to it

redo emotes
    Emotes should be downloaded after join, in background
        hosted by the server, not external
    Support adding separate emotes, store data about custom on server
    Adding new emotes should be done in game, via link to image and names def
        server takes link to image, downloads images to it's data folder, uses that to serve to clients
        on the new global settings menu
    option to serve emotes on external server
        figure something out for this

animated text would be cool, another modifier like &&rainbow&&, %%pulsing%%, etc.

redo autocomplete to be nicer, vertical design (below?), show the emote next to emote name, profile pic next to player name, something generic for ulx commands

resize/move
	button at top right to edit box
    Fades to white showing areas to drag
        middle = move
        edges/corners = resize
    little "Done" button

test darkrp - l o l

maybe a cheeky little "creator of betterchat" in my sidepanel?
]]

include( "betterchat/shared/sh_defines.lua" )
include( "betterchat/shared/sh_helper.lua" )
include( "betterchat/shared/sh_util.lua" )
include( "betterchat/shared/sh_globalsettings.lua" )

if SERVER then
    --includes
    include( "betterchat/server/sv_manager.lua" )

    table.mapSelf( bc.defines.networkStrings, util.AddNetworkString )

    bc.base.playersEnabled = {}
    function bc.base.getEnabledPlayers()
        return table.filterSeq( table.GetKeys( bc.base.playersEnabled ), IsValid )
    end

    net.Receive( "BC_chatOpenState", function( len, ply )
        ULib.clientRPC( nil, "bc.base.setPlayersOpen", ply, net.ReadBool() )
    end )

    net.Receive( "BC_forwardMessage", function( len, ply )
        hook.Run( "PlayerSay", ply, net.ReadString(), true )
    end )

    hook.Add( "PlayerInitialSpawn", "BC_playerSpawn", function( ply )
        local plys = bc.base.getEnabledPlayers()

        ULib.clientRPC( plys, "bc.sidePanel.players.generateEntry", ply )
        ULib.clientRPC( plys, "hook.Run", "BC_playerConnect", ply )
    end )

    hook.Add( "PlayerDisconnected", "BC_plyLeave", function( ply )
        bc.base.playersEnabled[ply] = false
        local plys = bc.base.getEnabledPlayers()
        table.RemoveByValue( plys, ply )

        ULib.clientRPC( plys, "bc.sidePanel.players.removeEntry", ply:SteamID() )
        ULib.clientRPC( plys, "hook.Run", "BC_playerDisconnect", ply:SteamID() )
    end )

    net.Receive( "BC_playerReady", function( len, ply ) --can now send data to ply
        bc.base.playersEnabled[ply] = true
        hook.Run( "BC_playerReady", ply )
    end )

    net.Receive( "BC_disable", function( len, ply )
        bc.base.playersEnabled[ply] = false
    end )
end

hook.Run( "BC_sharedInit" )

if SERVER then return end

--includes
include( "betterchat/client/graphics.lua" )
include( "betterchat/client/formatting.lua" )
include( "betterchat/client/overload.lua" )
include( "betterchat/client/datamanager.lua" )
include( "betterchat/client/images.lua" )
include( "betterchat/client/compatibility.lua" )
include( "betterchat/client/channels/channels.lua" )
include( "betterchat/client/sidepanel/sidepanel.lua" )
include( "betterchat/client/input/input.lua" )
--panels
include( "betterchat/client/vguipanels/davatarimagerounded.lua" )
include( "betterchat/client/vguipanels/dnicescrollpanel.lua" )
include( "betterchat/client/vguipanels/drichertext.lua" )

concommand.Add( "bc_enable", function()
    if bc.base.enabled then
        bc.base.disable()
    end
    bc.base.enable()
end, true, "Enables BetterChat" )

concommand.Add( "bc_disable", function()
    if bc.base.enabled then
        bc.base.disable()
    end
    chat.AddText( bc.defines.theme.betterChat, "BetterChat ",
        bc.defines.colors.printBlue, "has been disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
end, true, "Disables BetterChat" )

concommand.Add( "bc_restart", function()
    if bc.base.enabled then
        bc.base.disable()
    end
    bc.base.enable()
end )

concommand.Add( "bc_reload", function()
    if bc.base.enabled then
        bc.base.disable()
    end
    timer.Simple( 0.1, function() -- Delay to allow save
        include( "betterChat/shared/sh_base.lua" )
        bc.base.enable()
    end )
end, true, "Rebuilds BetterChat" )

concommand.Add( "bc_savedata", bc.data.saveData, true, "Saves all BetterChat data to file" )

concommand.Add( "bc_removesavedata", function()
    bc.data.deleteSaveData()
    if bc.base.enabled then
        bc.base.disable( true )
        bc.base.enable()
    end
    chat.AddText( bc.defines.theme.betterChat, "BetterChat ", bc.defines.colors.printBlue, "data has been deleted." )
end )

bc.base.enabled = true
bc.base.ready = false
bc.base.playersOpen = {}

hook.Add( "InitPostEntity", "BC_loaded", function()
    bc.data.loadEnabled()
    if bc.base.enabled then
        bc.base.enable()
    else
        chat.AddText( bc.defines.theme.betterChat, "BetterChat ", bc.defines.colors.printBlue, "is currently disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
    end
end )

bc.sidePanel.players.parse()

function bc.base.enable()
    bc.base.enabled = true
    bc.base.initializing = true

    bc.overload.undo()
    bc.overload.overload()

    bc.data.loadData()
    bc.graphics.build()

    -- Wait for other prints
    timer.Simple( 0, function()
        bc.channels.message( nil, bc.defines.theme.betterChat, "BetterChat", bc.defines.colors.printBlue, " initialisation complete." )
    end )
    bc.base.initializing = false
    bc.base.close()

    net.SendEmpty( "BC_playerReady" )

    bc.base.enabled = true
    bc.data.saveEnabled()
end

function bc.base.disable( noSave )
    bc.base.close()
    bc.base.enabled = false
    if not noSave then
        bc.data.saveData()
    end
    bc.overload.undo()

    bc.graphics.remove()
    bc.autoComplete = nil

    net.SendEmpty( "BC_disable" )
end

function bc.base.open( selectedTab )
    if bc.base.isOpen then return end

    bc.overload.old.Close()
    selectedTab = selectedTab or "All"

    if bc.settings.getValue( "rememberChannel" ) and selectedTab == "All" and bc.base.lastChannel then
        selectedTab = bc.base.lastChannel
    end

    local chan = bc.channels.getAndOpen( selectedTab )
    if not chan then return end

    selectedTab = chan.name

    bc.graphics.show( selectedTab )

    hook.Run( "StartChat" )
    bc.base.isOpen = true
    net.Start( "BC_chatOpenState" )
    net.WriteBool( true )
    net.SendToServer()
end

function bc.base.close()
    if not bc.base.enabled then return end
    bc.overload.old.Close()

    bc.base.lastChannel = ( bc.channels.getActiveChannel() or {} ).name

    bc.graphics.hide()

    hook.Run( "FinishChat" )
    bc.base.isOpen = false
    net.Start( "BC_chatOpenState" )
    net.WriteBool( false )
    net.SendToServer()

    -- Clear the text entry
    hook.Run( "ChatTextChanged", "" )
end

function bc.base.setPlayersOpen( ply, val )
    bc.base.playersOpen[ply] = val
end
