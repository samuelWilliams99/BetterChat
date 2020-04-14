bc.sizeMove = {}

hook.Add( "BC_initPanels", "BC_sizeMove", function()
    bc.sizeMove.dragging = false
    bc.sizeMove.draggingOffset = { x = 0, y = 0 }
end )

hook.Add( "BC_hideChat", "BC_sizeMoveHide", function()
    bc.sizeMove.dragging = false
end )

function bc.sizeMove.think()
    local g = bc.graphics
    local d = g.derma
    if bc.sizeMove.dragging then
        local x, y = gui.MousePos()
        x = x - bc.sizeMove.draggingOffset.x
        y = y - bc.sizeMove.draggingOffset.y
        x = math.Clamp( x, 0, ScrW() - g.size.x )
        y = math.Clamp( y, 0, ScrH() - g.size.y )

        d.frame:SetPos( x, y )
        if not input.IsMouseDown( MOUSE_LEFT ) then
            bc.sizeMove.dragging = false
        end
    elseif bc.sizeMove.resizing then
        local x, y = gui.MousePos()
        x = math.Clamp( x, 0, ScrW() )
        y = math.Clamp( y, 0, ScrH() )

        local px, py = d.frame:GetPos()
        local rData = bc.sizeMove.resizingData
        local w, h = g.size.x, g.size.y
        local doMove = false
        if rData.type == 0 then
            w = rData.originalRight - x
            w = math.Max( w, g.minSize.x )
            px = rData.originalRight - w
            doMove = true
        elseif rData.type == 1 then
            h = rData.originalBottom - y
            h = math.Max( h, g.minSize.y )
            py = rData.originalBottom - h
            doMove = true
        elseif rData.type == 2 then
            w = x - px
            w = math.Max( w, g.minSize.x )
        else
            h = y - py
            h = math.Max( h, g.minSize.y )
        end
        local final = not input.IsMouseDown( MOUSE_LEFT )
        if doMove then
            d.frame:SetPos( px, py )
        end
        bc.sizeMove.resize( w, h, final )
        if final then
            bc.sizeMove.resizing = false
        end
    end
end

function bc.sizeMove.resize( w, h, final )
    local g = bc.graphics
    local d = g.derma

    g.size = { x = w, y = h }
    g.originalFramePos = { x = 38, y = ScrH() - g.size.y - 150 }

    d.frame:SetSize( g.size.x + ( bc.sidePanel.totalWidth or 0 ), g.size.y )

    -- Seems some things don't update until mouseover, trigger them here instead
    if d.channelButton then
        d.channelButton:InvalidateLayout()
    end

    d.chatFrame:InvalidateLayout()
    d.psheet:InvalidateLayout()
    d.emoteButton:InvalidateLayout()
    d.textEntry:InvalidateLayout()

    for k, v in pairs( bc.channels.panels ) do
        if not IsValid( v.panel ) then continue end
        v.panel:InvalidateLayout( true )
        v.text:InvalidateLayout( true )
        if final then
            v.text:Reload()
        end
    end

    for k, v in pairs( bc.sidePanel.panels ) do
        local g = v.graphics
        g.pane:InvalidateLayout( true )
        g.frame:InvalidateLayout( true )
        for _, data in pairs( g.panels ) do
            data.Panel:InvalidateLayout( true )
        end
    end
end

local function inDragCorner( elem )
    local g = bc.graphics
    local x, y = elem:LocalCursorPos()
    local w, h = g.size.x, g.size.y

    if x < 0 or y < 0 or x > w or y > h then return end

    if x > w - 30 and y < 30 then
        return x, y
    end
end

local function inResizeEdge( elem )
    -- Disabled until i can be bothered to work out how to do this properly
    do return nil end
    local g = bc.graphics
    local x, y = elem:LocalCursorPos()
    local w, h = g.size.x, g.size.y

    if x < 0 or y < 0 or x > w or y > h then return end

    local edgeSize = 6
    if x < edgeSize then
        return 0
    elseif y < edgeSize then
        return 1
    elseif x > ( w - edgeSize ) then
        return 2
    elseif y > ( h - edgeSize ) then
        return 3
    end
end

hook.Add( "VGUIMousePressed", "BC_sizeMoveMousePressed", function( self, keyCode )
    if not bc.base.enabled or not bc.base.isOpen then return end
    local g = bc.graphics
    local x, y = inDragCorner( g.derma.frame )
    if x then
        if keyCode == MOUSE_LEFT then
            bc.sizeMove.dragging = true
            bc.sizeMove.draggingOffset = { x = x, y = y }
        elseif keyCode == MOUSE_RIGHT then
            -- local t = SysTime()
            -- local diff = t - ( bc.base.lastRClick or 0 )
            -- if diff < 0.5 then
            --     bc.sizeMove.resize( g.originalSize.x, g.originalSize.y, true )
            --     g.derma.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
            -- else
            g.derma.frame:SetPos( g.originalFramePos.x, g.originalFramePos.y )
            -- end
            -- bc.base.lastRClick = t
        end
        return
    end

    local edge = inResizeEdge( g.derma.frame )
    if edge then
        bc.sizeMove.resizing = true
        bc.sizeMove.resizingData = {
            originalRight = chatHelper.getFrom( 1, g.derma.frame:GetPos() ) + g.size.x,
            originalBottom = chatHelper.getFrom( 2, g.derma.frame:GetPos() ) + g.size.y,
            type = edge
        }
    end
end )
