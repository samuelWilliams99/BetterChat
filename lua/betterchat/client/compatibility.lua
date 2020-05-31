bc.compatibility = bc.compatibility or {}

local function captureAddText( f, ... )
    local oldAddText = chat.AddText
    local data = {}
    function chat.AddText( ... )
        table.Add( data, { ... } )
    end
    local out = f( ... )
    chat.AddText = oldAddText
    return data, out
end

hook.Add( "BC_overload", "BC_ATAG_chatOverload", function()
    timer.Simple( 0.5, function()
        if ATAG then
            print( "[BetterChat] Found ATAG, attempting overload" )

            local playerChatTable = hook.GetULibTable().OnPlayerChat
            if playerChatTable and playerChatTable[0].ATAG_ChatTags then
                print( "[BetterChat] Found ATAG_ChatTags hook, overloading" )
                bc.compatibility.atagHook = hook.GetULibTable().OnPlayerChat[0].ATAG_ChatTags.fn
                hook.Remove( "OnPlayerChat", "ATAG_ChatTags" )
            end
        end
    end )
end )

hook.Add( "BC_overload", "BC_DarkRP_chatOverload", function()
    timer.Simple( 0.5, function()
        if DarkRP then
            bc.compatibility.darkRPReceiver = net.Receivers.darkrp_chat
            if bc.compatibility.darkRPReceiver then
                net.Receive( "DarkRP_Chat", function( bits )
                    -- hush now
                    local chatPlaySound = chat.PlaySound
                    chat.PlaySound = function() end

                    bc.compatibility.defaultDarkRPReceiver( bits )

                    chat.PlaySound = chatPlaySound
                end )
            end
        end
    end )
end )

function bc.compatibility.darkRPDefaultChatReceiver( ply )
    if GAMEMODE.Config.alltalk then return nil end

    return LocalPlayer():GetPos():DistToSqr( ply:GetPos() ) <
        GAMEMODE.Config.talkDistance * GAMEMODE.Config.talkDistance
end

hook.Add( "BC_channelChanged", "BC_DarkRP_UpdateReceiver", function()
    if not DarkRP then return end

    local phrase = DarkRP.getPhrase( "talk" )
    local channel = bc.channels.getActiveChannel()

    if channel.name ~= "All" and channel.name ~= "Players" then
        phrase = "talk in " .. channel.displayName
    end

    bc.compatibility.overrideDarkRPChatReceivers( phrase )
end )

function bc.compatibility.overrideDarkRPChatReceivers( phrase )
    DarkRP.addChatReceiver( "", phrase, function( ply )
        local channel = bc.channels.getActiveChannel()
        if not channel then return false end

        local chanName = channel.name
        if chanName == "All" or chanName == "Players" then
            return bc.compatibility.darkRPDefaultChatReceiver( ply )
        elseif chanName == "Team" then
            for _, func in pairs( GAMEMODE.DarkRPGroupChats ) do
                if func( LocalPlayer() ) and func( ply ) then
                    return true
                end
            end

            return false
        elseif string.sub( chanName, 1, 15 ) == "TeamOverload - " then
            return ply:Team() == LocalPlayer():Team()
        elseif chanName == "Admin" then
            return bc.admin.allowed( ply )
        elseif channel.plySID then
            return ply:SteamID() == channel.plySID
        elseif channel.group then
            return table.HasValue( channel.group.members or {}, ply:SteamID() )
        end
        return false
    end )
end

hook.Add( "OnGamemodeLoaded", "BC_DarkRP_ATAG_compatibility", function()
    bc.compatibility.defaultDarkRPReceiver = net.Receivers.darkrp_chat
end )

local function fixColor( col )
    return Color( col.r, col.g, col.b, col.a )
end

hook.Add( "BC_getNameTable", "BC_ATAG_getNameTable", function( ply )
    if not ATAG then return end
    local pieces, messageColor, nameColor = ply:getChatTag()
    if not pieces then return end

    local out = {}
    for k, v in pairs( pieces ) do
        table.insert( out, fixColor( v.color ) or Color( 255, 255, 255 ) )
        table.insert( out, v.name or "" )
    end

    table.insert( out, {
        formatter = true,
        type = "clickable",
        signal = "Player-" .. ply:SteamID(),
        color = nameColor or team.GetColor( ply:Team() ),
        text = bc.channels.parseName( ply:Nick() )
    } )

    return out, messageColor
end )

function bc.compatibility.getNameTable( ply )
    return hook.Run( "BC_getNameTable", ply ) or { ply }
end

hook.Add( "BC_overloadUndo", "BC_compatibilityUndo", function()
    if bc.compatibility.atagHook then
        print( "[BetterChat] Undoing ATAG Overload" )
        hook.Add( "OnPlayerChat", "ATAG_ChatTags", bc.compatibility.atagHook )
    end
    if bc.compatibility.darkRPReceiver then
        print( "[BetterChat] Undoing DarkRP PlayerChat Overload" )
        net.Receivers.darkrp_chat = bc.compatibility.darkRPReceiver
        DarkRP.addChatReceiver( "", DarkRP.getPhrase( "talk" ), bc.compatibility.darkRPDefaultChatReceiver )
    end
end )

hook.Add( "BC_getDefaultTab", "BC_ATAG_default", function( ... )
    if not bc.compatibility.atagHook then return end

    local data, madeChange = captureAddText( bc.compatibility.atagHook, ... )
    return data, madeChange
end )

-- TTT

local function AddDetectiveText( ply, text )
   chat.AddText( Color( 50, 200, 255 ),
                 ply:Nick(),
                 Color( 255, 255, 255 ),
                 ": ", unpack( bc.formatting.formatText( text, nil, ply ) ) )
end

-- Return true, retVal or false, replaceVals
hook.Add( "BC_compat_OnPlayerChat", "bc_compat_TTT", function( ply, text, isTeam, isDead )
    if GAMEMODE.ThisClass ~= "gamemode_terrortown" then return end

    if not IsValid(ply) then return end

    if ply:IsActiveDetective() then
       AddDetectiveText(ply, text)
       return true, true
    end

    local isSpec = ply:Team() == TEAM_SPEC

    if isSpec and not isDead then
       isDead = true
    end

    local canUseTeam = ply:IsSpecial() and not isSpec
    if not canUseTeam then
        isTeam = false
    end

    return false, ply, text, isTeam, isDead
end )

hook.Add( "BC_overload", "bc_compat_TTT", function()
    if GAMEMODE.ThisClass ~= "gamemode_terrortown" then return end

    bc.compatibility.oldTTTRoleChat = bc.compatibility.oldTTTRoleChat or net.Receivers.ttt_rolechat
    net.Receivers.ttt_rolechat = function()
        -- virtually always our role, but future equipment might allow listening in
        local role = net.ReadUInt(2)
        local sender = net.ReadEntity()
        if not IsValid(sender) then return end

        local text = net.ReadString()

        if role == ROLE_TRAITOR then
            chat.AddText( Color( 255, 30, 40 ),
                Format( "(%s) ", string.upper( LANG.GetTranslation( "traitor" ) ) ),
                Color( 255, 200, 20 ),
                sender:Nick(),
                Color( 255, 255, 200 ),
                ": ", unpack( bc.formatting.formatText( text, nil, sender ) ) )

        elseif role == ROLE_DETECTIVE then
            chat.AddText( Color( 20, 100, 255 ),
                Format( "(%s) ", string.upper( LANG.GetTranslation( "detective" ) ) ),
                Color( 25, 200, 255 ),
                sender:Nick(),
                Color( 200, 255, 255 ),
                ": ", unpack( bc.formatting.formatText( text, nil, sender ) ) )
        end
    end

    bc.compatibility.oldTTTRadioMsg = bc.compatibility.oldTTTRadioMsg or net.Receivers.ttt_radiomsg
    net.Receivers.ttt_radiomsg = function()
        local sender = net.ReadEntity()
        local msg    = net.ReadString()
        local param  = net.ReadString()

        if not (IsValid(sender) and sender:IsPlayer()) then return end

        GAMEMODE:PlayerSentRadioCommand(sender, msg, param)

        -- if param is a language string, translate it
        -- else it's a nickname
        local lang_param = LANG.GetNameParam(param)
        if lang_param then
            if lang_param == "quick_corpse_id" then
                -- special case where nested translation is needed
                param = LANG.GetParamTranslation(lang_param, {player = net.ReadString()})
            else
                param = LANG.GetTranslation(lang_param)
            end
        end

        local text = LANG.GetParamTranslation(msg, {player = param})

        -- don't want to capitalize nicks, but everything else is fair game
        if lang_param then
            text = util.Capitalize(text)
        end

        if sender:IsDetective() then
            AddDetectiveText(sender, text)
        else
            chat.AddText( { formatter = true, type = "escape" }, sender, COLOR_WHITE, ": ",
                unpack( bc.formatting.formatText( text, nil, sender ) ) )
        end
    end
end )

hook.Add( "BC_overloadUndo", "bc_compat_TTT", function()
    if GAMEMODE.ThisClass ~= "gamemode_terrortown" then return end

    net.Receivers.ttt_rolechat = bc.compatibility.oldTTTRoleChat
    net.Receivers.ttt_radiomsg = bc.compatibility.oldTTTRadioMsg
end )
