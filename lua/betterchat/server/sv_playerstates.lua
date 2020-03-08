--add tracked states, idx is name (same as value in setting), func is how to get cur state, must return bool
local trackedStates = { 
    jailed = function( ply ) return ply.jail and true or false end, 
    inGod = function( ply ) return ply:HasGodMode() end, 
    isFrozen = function( ply ) return ply.frozen end, 
    isRagdolled = function( ply ) return ply.ragdoll end, 
    isChatEnabled = function( ply ) return chatBox.chatBoxEnabled[ply] end, 
    isMuted = function( ply ) return ply:GetNWBool( "ulx_muted", false ) end, 
}

local onChanges = { 
    isChatEnabled = function( ply, newVal ) ULib.clientRPC( chatBox.getEnabledPlayers(), "chatBox.reloadAllMemberMenus" ) end, 
}

--dont touch

chatBox.states = chatBox.states or {}

for k, state in pairs( trackedStates ) do
    chatBox.states[k] = {}
    for k1, ply in pairs( player.GetAll() ) do
        chatBox.states[k][ply] = state( ply )
    end
end

if timer.Exists( "BC_stateMonitor" ) then timer.Remove( "BC_stateMonitor" ) end
timer.Create( "BC_stateMonitor", 1 / 30, 0, function()
    for k, state in pairs( trackedStates ) do
        for k1, ply in pairs( player.GetAll() ) do
            local newState = state( ply )
            if newState ~= chatBox.states[k][ply] then
                chatBox.states[k][ply] = newState
                net.Start( "BC_sendPlayerState" )
                net.WriteString( k )
                net.WriteEntity( ply )
                net.WriteBool( newState )
                net.Broadcast()
                if onChanges[k] then
                    onChanges[k]( ply, newState )
                end
            end
        end
    end
end )

hook.Add( "BC_plyReady", "BC_stateInit", function( ply )
    for k, state in pairs( trackedStates ) do
        for k1, sPly in pairs( player.GetAll() ) do
            net.Start( "BC_sendPlayerState" )
            net.WriteString( k )
            net.WriteEntity( sPly )
            net.WriteBool( chatBox.states[k][sPly] )
            net.Send( ply )
        end
    end
end )

function accessChange( id, ... )
    local ply
    if type( id ) == "Player" then
        ply = id
    elseif string.sub( id, 1, 5 ) == "STEAM" then -- steamid
        ply = player.GetBySteamID( id )
    else -- Weird ulib id
        ply = ULib.getPlyByID( id )
    end
    timer.Simple( 0.1, function() --Delay the message as ULibUserGroupChange is called before permission changes
        net.Start( "BC_userRankChange" )
        net.Send( ply )
    end )
end

function accessChangeGlobal()
    timer.Simple( 0.1, function() --Delay the message as ULibUserGroupChange is called before permission changes
        net.Start( "BC_userRankChange" )
        net.Broadcast()
    end )
end

hook.Add( "ULibUserGroupChange", "BC_rankChange", accessChange )
hook.Add( "ULibUserAccessChange", "BC_rankChange", accessChange )
hook.Add( "ULibUserRemoved", "BC_rankChange", accessChange )
hook.Add( "ULibGroupAccessChanged", "BC_rankChange", accessChangeGlobal )
hook.Add( "CAMI.PlayerUsergroupChanged", "BC_rankChange", accessChange )