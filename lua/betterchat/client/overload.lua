function chatBox.overloadFunctions()
    chatBox.overloadedFuncs = {}
    chatBox.overloadedFuncs.oldAddText = chat.AddText
    chat.AddText = function( ... )
        chatBox.print( ... )
        -- Call the original function (replace some stuff)
        local data = { ... }
        for k, v in pairs( data ) do
            if type( v ) == "table" and v.formatter and ( v.type == "clickable" or v.type == "image" ) then
                data[k] = v.text
            end
        end
        chatBox.overloadedFuncs.oldAddText( unpack( data ) )
    end

    chatBox.overloadedFuncs.oldGetChatBoxPos = chat.GetChatBoxPos
    chat.GetChatBoxPos = function() 
        return chatBox.graphics.frame:GetPos()
    end

    chatBox.overloadedFuncs.oldGetChatBoxSize = chat.GetChatBoxSize
    chat.GetChatBoxSize = function() 
        local xSum = chatBox.graphics.size.x
        for k, v in pairs( chatBox.sidePanels ) do
            if v.animState > 0 then
                xSum = xSum + ( v.animState * v.size.x ) + 2
            end
        end

        return xSum, chatBox.graphics.size.y
    end

    chatBox.overloadedFuncs.oldOpen = chat.Open
    chat.Open = function( mode )
        local chan
        if mode == 1 then
            if DarkRP then
                if chatBox.getServerSetting( "replaceTeam" ) then
                    local t = chatBox.teamName( LocalPlayer() )
                    chan = "TeamOverload-" .. t
                else
                    return 
                end
            else -- Dont open normal team chat, do nothing to allow for bind
                chan = "Team"
            end
        end
        chatBox.openChatBox( chan )
    end

    chatBox.overloadedFuncs.oldClose = chat.Close
    chat.Close = chatBox.closeChatBox

    chatBox.overloadedFuncs.plyMeta = FindMetaTable( "Player" )
    chatBox.overloadedFuncs.plyChatPrint = chatBox.overloadedFuncs.plyMeta.ChatPrint
    chatBox.overloadedFuncs.plyMeta.ChatPrint = function( self, str )
        chatBox.print( printBlue, str )

        chatBox.overloadedFuncs.plyChatPrint( self, str )
    end

    chatBox.overloadedFuncs.plyIsTyping = chatBox.overloadedFuncs.plyMeta.IsTyping
    chatBox.overloadedFuncs.plyMeta.IsTyping = function( ply )
        return chatBox.playersOpen[ply]
    end

    chatBox.overloadedFuncs.hookAdd = hook.Add
    chatBox.hookOverloads = { OnPlayerChat = table.Copy( hook.GetULibTable().OnPlayerChat or {} ) }
    for k, v in pairs( hook.GetTable().OnPlayerChat or {} ) do
        hook.Remove( "OnPlayerChat", k )
    end
    hook.Add( "OnPlayerChat", "BC_ChatHook", function( ... )
        if chatBox.OnPlayerSayHook then
            return chatBox.OnPlayerSayHook( ... )
        end
    end )

    -- DLib loves complaining about this, no other way to do it though
    rawset( hook, "Add", function( event, id, func, ... )
        if event == "OnPlayerChat" then
            chatBox.hookOverloads.OnPlayerChat[id] = func
        else
            chatBox.overloadedFuncs.hookAdd( event, id, func, ... )
        end
    end )

    chatBox.overloadedFuncs.hookRemove = hook.Remove
    rawset( hook, "Remove", function( event, id )
        if event == "OnPlayerChat" then
            chatBox.hookOverloads.OnPlayerChat[id] = nil
        else
            chatBox.overloadedFuncs.hookRemove( event, id )
        end
    end )

    hook.Run( "BC_Overload" )

    chatBox.overloaded = true
end

function chatBox.returnFunctions()
    if not chatBox.overloaded then return end
    chat.AddText = chatBox.overloadedFuncs.oldAddText
    chat.GetChatBoxSize = chatBox.overloadedFuncs.oldGetChatBoxSize
    chat.GetChatBoxPos = chatBox.overloadedFuncs.oldGetChatBoxPos
    chat.Open = chatBox.overloadedFuncs.oldOpen
    chat.Close = chatBox.overloadedFuncs.oldClose

    hook.Add = chatBox.overloadedFuncs.hookAdd
    hook.Remove = chatBox.overloadedFuncs.hookRemove
    hook.Remove( "OnPlayerChat", "BC_ChatHook" )
    for id, data in pairs( chatBox.hookOverloads.OnPlayerChat ) do
        if type( fn ) == "table" then -- Ulib hooks have priority, must maintain that
            for priority, d in pairs( fn ) do
                hook.Add( "OnPlayerChat", id, d.fn, priority )
            end
        end
    end
    hook.GetTable().OnPlayerChat = table.Copy( chatBox.hookOverloads.OnPlayerChat )

    chatBox.overloadedFuncs.plyMeta.ChatPrint = chatBox.overloadedFuncs.plyChatPrint
    chatBox.overloadedFuncs.plyMeta.IsTyping = chatBox.overloadedFuncs.plyIsTyping
    chatBox.overloadedFuncs = {}
    hook.Run( "BC_Overload_Undo" )
    chatBox.overloaded = false
end