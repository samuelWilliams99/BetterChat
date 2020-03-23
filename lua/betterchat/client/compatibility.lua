chatBox.compatibility = chatBox.compatibility or {}

hook.Add( "BC_overload", "BC_ATAG_chatOverload", function()
    timer.Simple( 0.5, function()
        if ATAG then
            print( "[BetterChat] Found ATAG, attempting overload" )
            
            if chatBox.hookOverloads.OnPlayerChat.ATAG_ChatTags then
                print( "[BetterChat] Found ATAG_ChatTags hook, overloading" )
                chatBox.compatibility.atagHook = chatBox.hookOverloads.OnPlayerChat.ATAG_ChatTags
                hook.Remove( "OnPlayerChat", "ATAG_ChatTags" )
            end
        end
    end )
end )

hook.Add( "BC_overloadUndo", "BC_compatibilityUndo", function()
    if chatBox.compatibility.atagHook then
        print( "[BetterChat] Undoing ATAG Overload" )
        hook.Add( "OnPlayerChat", "ATAG_ChatTags", chatBox.compatibility.atagHook )
    end    
end )

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

hook.Add( "BC_getPreTab", "BC_ATAG_preTab", function( ply, msg, teamChat, dead, d )
    if chatBox.overload.hooks.OnPlayerChat.ATAG_ChatTags then
        print( "[BetterChat] Found ATAG_ChatTags hook while processing message, overloading" )
        chatBox.compatibility.atagHook = chatBox.overload.hooks.OnPlayerChat.ATAG_ChatTags
        hook.Remove( "OnPlayerChat", "ATAG_ChatTags" )
    end
    if not chatBox.compatibility.atagHook then return end

    local data, madeChange = captureAddText( chatBox.compatibility.atagHook, ply, msg, teamChat, dead, unpack( d or {} ) )
    if not madeChange then return end

    if #data == 0 then
        return data
    end

    data[#data] = ": "

    for k, v in pairs( data ) do
        if v == ply:Nick() then
            data[k] = ply
            table.insert( data, k, { formatter = true, type = "escape" } )
        elseif chatBox.util.isColor( v ) then
            data[k] = Color( v.r, v.g, v.b, v.a ) -- Pack back into a proper colour object, with its metatable
        end
    end
    local lastCol = chatBox.defines.colors.white
    for k = #data, 1, -1 do
        if chatBox.util.isColor( data[k] ) then
            lastCol = data[k]
            break
        end
    end

    return data, lastCol
end )

hook.Add( "BC_getDefaultTab", "BC_ATAG_default", function( ... )
    if not chatBox.compatibility.atagHook then return end
    
    local data, madeChange = captureAddText( chatBox.compatibility.atagHook, ... )
    return data, madeChange
end )
