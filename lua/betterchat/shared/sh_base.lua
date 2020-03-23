chatBox = chatBox or {}
chatBox.base = chatBox.base or {}

--[[
naming convention
all vars/functions camel
always full names
hookIds: BC_camelCase
eventNames: BC_camelCase

ctrt+w for close tab

make players closable

joining after bots
	[ERROR] addons/betterchat/lua/betterchat/client/sidepanel/panels/players.lua:30: attempt to call method 'SteamID' (a nil value)
  1. fn - addons/betterchat/lua/betterchat/client/sidepanel/panels/players.lua:30
   2. func - addons/ulib-master/lua/ulib/client/cl_util.lua:22
    3. unknown - lua/includes/extensions/net.lua:32



	logs channel - implement with a ulx permission, ulx bc_seechatlogs

	chat cooldown - sounds like a fair bit of work, especially when other addons already do it
		maybe call onchat with generic ply/message to trigger it?

	resize/move
		double right click on thing in corner requires mouse movement ????
		preferable change hand to sizeall when hovering
		some button to enable moving/resizing, as a mode
			panel over top of the whole chat, removes issue with cursor as panel will be only focused thing
			gray the panel a bit and pop an icon in the middle?

		scroll bar on side panels not updating -- this is a problem, idk how fix
			could just not show chat when resizing/moving
			enter kinda like an edit hud mode, where no gui are actually rendered, just shitty boxes

	test darkrp - l o l

    maybe a little "creator of betterchat" in my sidepanel?
]]

include( "betterchat/shared/sh_defines.lua" )
include( "betterchat/shared/sh_helper.lua" )
include( "betterchat/shared/sh_util.lua" )
include( "betterchat/shared/sh_globalsettings.lua" )

if SERVER then
    --includes
    include( "betterchat/server/sv_manager.lua" )

    table.mapSelf( chatBox.defines.networkStrings, util.AddNetworkString )

    chatBox.base.chatBoxEnabled = {}
    function chatBox.base.getEnabledPlayers()
        return table.filterSeq( table.GetKeys( chatBox.base.chatBoxEnabled ), IsValid )
    end

    net.Receive( "BC_chatOpenState", function( len, ply )
        ULib.clientRPC( nil, "chatBox.base.setPlayersOpen", ply, net.ReadBool() )
    end )

    net.Receive( "BC_forwardMessage", function( len, ply )
        hook.Run( "PlayerSay", ply, net.ReadString(), true )
    end )

    hook.Add( "PlayerInitialSpawn", "BC_playerSpawn", function( ply )
        local plys = chatBox.base.getEnabledPlayers()

        ULib.clientRPC( plys, "chatBox.sidePanel.players.generateEntry", ply )
        ULib.clientRPC( plys, "hook.Run", "BC_playerConnect", ply )

        if chatBox.giphy.enabled then
            ULib.clientRPC( ply, "chatBox.images.enableGiphy" )
        end
    end )

    hook.Add( "PlayerDisconnected", "BC_plyLeave", function( ply )
        chatBox.base.chatBoxEnabled[ply] = false
        local plys = chatBox.base.getEnabledPlayers()
        table.RemoveByValue( plys, ply )

        ULib.clientRPC( plys, "chatBox.sidePanel.players.removeEntry", ply:SteamID() )
        ULib.clientRPC( plys, "hook.Run", "BC_playerDisconnect", ply:SteamID() )
    end )

    net.Receive( "BC_playerReady", function( len, ply ) --can now send data to ply
        chatBox.base.chatBoxEnabled[ply] = true
        hook.Run( "BC_playerReady", ply )
    end )

    net.Receive( "BC_disable", function( len, ply )
        chatBox.base.chatBoxEnabled[ply] = false
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
    if chatBox.base.enabled then
        chatBox.base.disableChatBox()
    end
    chatBox.base.enableChatBox()
end, true, "Enables BetterChat" )

concommand.Add( "bc_disable", function()
    if chatBox.base.enabled then
        chatBox.base.disableChatBox()
    end
    chat.AddText( chatBox.defines.theme.betterChat, "BetterChat ", 
        chatBox.defines.colors.printBlue, "has been disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
end, true, "Disables BetterChat" )

concommand.Add( "bc_restart", function()
    if chatBox.base.enabled then
        chatBox.base.disableChatBox()
    end
    chatBox.base.enableChatBox()
end )

concommand.Add( "bc_reload", function()
    if chatBox.base.enabled then
        chatBox.base.disableChatBox()
    end
    timer.Simple( 0.1, function() -- Delay to allow save
        include( "betterChat/shared/sh_base.lua" )
        chatBox.base.enableChatBox()
    end )
end, true, "Rebuilds BetterChat" )

concommand.Add( "bc_savedata", chatBox.data.saveData, true, "Saves all BetterChat data to file" )

concommand.Add( "bc_removesavedata", function()
    chatBox.data.deleteSaveData()
    if chatBox.base.enabled then
        chatBox.base.disableChatBox( true )
        chatBox.base.enableChatBox()
    end
    chat.AddText( chatBox.defines.theme.betterChat, "BetterChat ", chatBox.defines.colors.printBlue, "data has been deleted." )
end )

chatBox.base.enabled = true
chatBox.base.ready = false
chatBox.base.playersOpen = {}

hook.Add( "InitPostEntity", "BC_loaded", function()
    chatBox.data.loadEnabled()
    if chatBox.base.enabled then
        chatBox.base.enableChatBox()
    else
        chat.AddText( chatBox.defines.theme.betterChat, "BetterChat ", chatBox.defines.colors.printBlue, "is currently disabled. Go to Q->Options->BetterChat (or run bc_enable) to enable it." )
    end
end )

chatBox.sidePanel.players.parse()

function chatBox.base.enableChatBox()
    chatBox.base.enabled = true
    chatBox.base.initializing = true

    chatBox.overload.undo()
    chatBox.overload.overload()

    chatBox.graphics.build()

    -- Wait for other prints
    timer.Simple( 0, function()
        chatBox.channels.message( nil, chatBox.defines.theme.betterChat, "BetterChat", chatBox.defines.colors.printBlue, " initialisation complete." )
    end )
    chatBox.base.initializing = false
    chatBox.base.closeChatBox()

    net.SendEmpty( "BC_playerReady" )

    chatBox.data.loadData()
    chatBox.base.enabled = true
    chatBox.data.saveEnabled()
end

function chatBox.base.disableChatBox( noSave )
    chatBox.base.closeChatBox()
    chatBox.base.enabled = false
    if not noSave then
        chatBox.data.saveData()
    end
    chatBox.overload.undo()

    chatBox.graphics.remove()
    chatBox.autoComplete = nil

    net.SendEmpty( "BC_disable" )
end

function chatBox.base.openChatBox( selectedTab )
    if chatBox.base.isOpen then return end
    chatBox.overload.old.Close()
    selectedTab = selectedTab or "All"

    if chatBox.settings.getValue( "rememberChannel" ) and selectedTab == "All" and chatBox.base.lastChannel then
        selectedTab = chatBox.base.lastChannel
    end

    local chan = chatBox.channels.getAndOpen( selectedTab )
    if not chan then return end
    selectedTab = chan.name

    chatBox.graphics.show( selectedTab )

    hook.Run( "StartChat" )
    chatBox.base.isOpen = true
    net.Start( "BC_chatOpenState" )
    net.WriteBool( true )
    net.SendToServer()
end

function chatBox.base.closeChatBox()
    if not chatBox.base.enabled then return end
    chatBox.overload.old.Close()

    chatBox.base.lastChannel = chatBox.channels.getActiveChannel().name

    chatBox.graphics.hide()

    hook.Run( "FinishChat" )
    chatBox.base.isOpen = false
    net.Start( "BC_chatOpenState" )
    net.WriteBool( false )
    net.SendToServer()

    -- Clear the text entry
    hook.Run( "ChatTextChanged", "" )
end

function chatBox.base.setPlayersOpen( ply, val )
    chatBox.base.playersOpen[ply] = val
end
