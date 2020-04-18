bc.overload = bc.overload or {}

-- formatter types with "text" defined to be replaced with the raw text
local textTypes = { "clickable", "image", "gif" }

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
            if type( v ) == "table" and v.formatter and table.HasValue( textTypes, v.type ) then
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
                    chan = "TeamOverload - " .. t
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
        bc.formatting.print( bc.defines.colors.printBlue, str )

        o.plyChatPrint( self, str )
    end

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

    o.plyMeta.ChatPrint = o.plyChatPrint
    bc.overload.old = {}
    hook.Run( "BC_overloadUndo" )
    bc.overload.overloaded = false
end
