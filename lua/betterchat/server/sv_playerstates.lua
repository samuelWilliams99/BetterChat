--add tracked states, idx is name (same as value in setting), func is how to get cur state, must return bool
local trackedStates = {
    jailed = function( ply ) return asBool( ply.jail ) end,
    inGod = function( ply ) return ply:HasGodMode() end,
    isFrozen = function( ply ) return ply.frozen end,
    isRagdolled = function( ply ) return ply.ragdoll end,
    isChatEnabled = function( ply ) return chatBox.base.chatBoxEnabled[ply] end,
    isMuted = function( ply ) return ply:GetNWBool( "ulx_muted", false ) end,
}

local onChanges = {
    isChatEnabled = function( ply, newVal )
        ULib.clientRPC( chatBox.base.getEnabledPlayers(), "chatBox.sidePanel.members.reloadAll" )
    end,
}

--dont touch

chatBox.states = chatBox.states or {}

for state, getter in pairs( trackedStates ) do
    chatBox.states[state] = {}
    for k1, ply in pairs( player.GetAll() ) do
        chatBox.states[state][ply] = getter( ply )
    end
end

timer.Create( "BC_stateMonitor", 1 / 30, 0, function()
    for state, getter in pairs( trackedStates ) do
        for k, ply in pairs( player.GetAll() ) do
            local newState = getter( ply )
            if newState ~= chatBox.states[state][ply] then
                chatBox.states[state][ply] = newState
                net.Start( "BC_sendPlayerState" )
                net.WriteString( state )
                net.WriteEntity( ply )
                net.WriteBool( newState )
                net.Broadcast()
                if onChanges[state] then
                    onChanges[state]( ply, newState )
                end
            end
        end
    end
end )

hook.Add( "BC_playerReady", "BC_stateInit", function( ply )
    for state, getter in pairs( trackedStates ) do
        for k, sPly in pairs( player.GetAll() ) do
            net.Start( "BC_sendPlayerState" )
            net.WriteString( state )
            net.WriteEntity( sPly )
            net.WriteBool( chatBox.states[state][sPly] )
            net.Send( ply )
        end
    end
end )

local function accessChange( id, ... )
    local ply
    if type( id ) == "Player" then
        ply = id
    elseif string.sub( id, 1, 5 ) == "STEAM" then -- steamid
        ply = player.GetBySteamID( id )
    else -- Weird ulib id
        ply = ULib.getPlyByID( id )
    end
    timer.Simple( 0.1, function() --Delay the message as ULibUserGroupChange is called before permission changes
        net.SendEmpty( "BC_userRankChange", ply )
    end )
end

local function accessChangeGlobal()
    timer.Simple( 0.1, function() --Delay the message as ULibUserGroupChange is called before permission changes
        net.SendEmpty( "BC_userRankChange" )
    end )
end

hook.Add( "ULibUserGroupChange", "BC_rankChange", accessChange )
hook.Add( "ULibUserAccessChange", "BC_rankChange", accessChange )
hook.Add( "ULibUserRemoved", "BC_rankChange", accessChange )
hook.Add( "ULibGroupAccessChanged", "BC_rankChange", accessChangeGlobal )
hook.Add( "CAMI.PlayerUsergroupChanged", "BC_rankChange", accessChange )
