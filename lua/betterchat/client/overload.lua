bc.overload = {}

function bc.overload.overload()
    if bc.overload.overloaded then return end
    bc.overload.old = {}
    local o = bc.overload.old
    o.AddText = chat.AddText
    function chat.AddText( ... )
        bc.formatting.print( ... )
        -- Call the original function (replace some stuff)
        local data = { ... }
        for k, v in pairs( data ) do
            if type( v ) == "table" and v.formatter and ( v.type == "clickable" or v.type == "image" or v.type == "gif" ) then
                data[k] = v.text
            end
        end
        o.AddText( unpack( data ) )
    end

    o.GetChatBoxPos = chat.GetChatBoxPos
    function chat.GetChatBoxPos()
        return bc.graphics.derma.frame:GetPos()
    end

    o.GetChatBoxSize = chat.GetChatBoxSize
    function chat.GetChatBoxSize()
        local xSum = bc.graphics.size.x
        for k, v in pairs( bc.sidePanel.panels ) do
            if v.animState > 0 then
                xSum = xSum + ( v.animState * v.size.x ) + 2
            end
        end

        return xSum, bc.graphics.size.y
    end

    o.Open = chat.Open
    function chat.Open( mode )
        local chan
        if mode == 1 then
            if DarkRP then
                if bc.settings.getServerValue( "replaceTeam" ) then
                    local t = chatHelper.teamName( LocalPlayer() )
                    chan = "TeamOverload-" .. t
                else
                    return
                end
            else -- Dont open normal team chat, do nothing to allow for bind
                chan = "Team"
            end
        end
        bc.base.open( chan )
    end

    o.Close = chat.Close
    chat.Close = bc.base.close

    o.plyMeta = FindMetaTable( "Player" )
    o.plyChatPrint = o.plyMeta.ChatPrint
    function o.plyMeta:ChatPrint( str )
        bc.formatting.print( printBlue, str )

        o.plyChatPrint( self, str )
    end

    o.plyIsTyping = o.plyMeta.IsTyping
    function o.plyMeta:IsTyping()
        return bc.base.playersOpen[self]
    end

    o.hookAdd = hook.Add
    bc.overload.hooks = { OnPlayerChat = table.Copy( hook.GetULibTable().OnPlayerChat or {} ) }
    for k, v in pairs( hook.GetTable().OnPlayerChat or {} ) do
        hook.Remove( "OnPlayerChat", k )
    end
    hook.Add( "OnPlayerChat", "BC_chatHook", function( ... )
        if bc.formatting.onPlayerSayHook then
            return bc.formatting.onPlayerSayHook( ... )
        end
    end )

    -- DLib loves complaining about this, no other way to do it though
    rawset( hook, "Add", function( event, id, func, ... )
        if event == "OnPlayerChat" then
            bc.overload.hooks.OnPlayerChat[id] = func
        else
            o.hookAdd( event, id, func, ... )
        end
    end )

    o.hookRemove = hook.Remove
    rawset( hook, "Remove", function( event, id )
        if event == "OnPlayerChat" then
            bc.overload.hooks.OnPlayerChat[id] = nil
        else
            o.hookRemove( event, id )
        end
    end )

    hook.Run( "BC_overload" )

    bc.overload.overloaded = true
end

function bc.overload.undo()
    if not bc.overload.overloaded then return end
    local o = bc.overload.old
    chat.AddText = o.AddText
    chat.GetChatBoxSize = o.GetChatBoxSize
    chat.GetChatBoxPos = o.GetChatBoxPos
    chat.Open = o.Open
    chat.Close = o.Close

    rawset( hook, "Add", o.hookAdd )
    rawset( hook, "Remove", o.hookRemove )
    hook.Remove( "OnPlayerChat", "BC_chatHook" )
    for id, data in pairs( bc.overload.hooks.OnPlayerChat ) do
        if type( fn ) == "table" then -- Ulib hooks have priority, must maintain that
            for priority, d in pairs( fn ) do
                hook.Add( "OnPlayerChat", id, d.fn, priority )
            end
        end
    end
    hook.GetTable().OnPlayerChat = table.Copy( bc.overload.hooks.OnPlayerChat )

    o.plyMeta.ChatPrint = o.plyChatPrint
    o.plyMeta.IsTyping = o.plyIsTyping
    bc.overload.old = {}
    hook.Run( "BC_overloadUndo" )
    bc.overload.overloaded = false
end
