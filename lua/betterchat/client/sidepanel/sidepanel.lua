chatBox.sidePanel = {}
include( "betterchat/client/sidepanel/panels/channels.lua" )
include( "betterchat/client/sidepanel/panels/players.lua" )
include( "betterchat/client/sidepanel/panels/members.lua" )

chatBox.sidePanel.defaultWidth = 110
chatBox.sidePanel.totalWidth = 0

chatBox.sidePanel.renderSettingFuncs = {
    blank = function( sPanel, panel, data, y, w, h, setting )
        return 0
    end
}

include( "betterchat/client/sidepanel/types/string.lua" )
include( "betterchat/client/sidepanel/types/key.lua" )
include( "betterchat/client/sidepanel/types/boolean.lua" )
include( "betterchat/client/sidepanel/types/options.lua" )
include( "betterchat/client/sidepanel/types/button.lua" )
include( "betterchat/client/sidepanel/types/color.lua" )

function chatBox.sidePanel.renderSetting( sPanel, data, setting, k )
    local panel = sPanel:GetCanvas()
    local w, h = sPanel:GetSize()
    local y = k * 20 + 12

    local noName = setting.overrideWidth == -1

    local label
    if not noName then
        label = vgui.Create( "DLabel", panel )
        label:SetText( setting.name )
        if setting.nameColor then
            label:SetTextColor( setting.nameColor )
        end
        if setting.extra then
            label:SetTooltip( setting.extra )
        end
        label:SetPos( 10, y )
        label:SizeToContents()
        label:SetMouseInputEnabled( true )
    else
        setting = table.Copy( setting )
        setting.overrideWidth = w - 39
    end

    if not data.dataChanged then data.dataChanged = {} end

    local elemWidth = chatBox.sidePanel.renderSettingFuncs[setting.type]( sPanel, panel, data, y, w - 32, h, setting ) or 0

    if not noName then
        local line = vgui.Create( "DShape", panel )
        line:SetType( "Rect" )
        local lw, lh = label:GetSize()
        line:SetPos( 15 + lw, y + 7 )
        line:SetSize( w - 32 - 15 - lw - 5 - elemWidth, 1 )
        line:SetColor( chatBox.defines.theme.sidePanelAccent )
    end
end

hook.Add( "BC_preInitPanels", "BC_initSidePanels", function()
    chatBox.sidePanel.panels = {}
    chatBox.sidePanel.idCounter = 0
end )

hook.Add( "BC_keyCodeTyped", "BC_sidePanelShortCutHook", function( code, ctrl, shift )
    if code == KEY_S then
        if ctrl then
            if shift then
                local s = chatBox.sidePanel.panels["Player"]
                if not chatBox.sidePanel.childExists( "Player", LocalPlayer():SteamID() ) then
                    chatBox.sidePanel.players.generateEntry( LocalPlayer() )
                end
                if s.isOpen then
                    chatBox.sidePanel.close( s.name )
                else
                    chatBox.sidePanel.open( s.name, LocalPlayer():SteamID() )
                end
            else
                local s = chatBox.sidePanel.panels["Channel Settings"]
                if s.isOpen then
                    chatBox.sidePanel.close( s.name )
                else
                    chatBox.sidePanel.open( s.name, chatBox.channels.getActiveChannel().name )
                end
            end
            return true
        end
    end
end )

function chatBox.sidePanel.create( name, width, data )
    local size = { x = width, y = chatBox.graphics.size.y - 33 }
    chatBox.sidePanel.idCounter = chatBox.sidePanel.idCounter + 1
    local _, h = chatBox.graphics.derma.frame:GetSize()
    chatBox.sidePanel.totalWidth = chatBox.sidePanel.totalWidth + size.x + 2
    chatBox.graphics.derma.frame:SetSize( chatBox.graphics.size.x + chatBox.sidePanel.totalWidth, h )

    local icon = data.icon or chatBox.defines.materials.cog
    local rot = data.rotate
    local col = data.col or chatBox.defines.colors.white
    local border = data.border or 0

    chatBox.sidePanel.panels[name] = {}
    local s = chatBox.sidePanel.panels[name]
    s.graphics = {}
    local g = s.graphics
    s.idx = chatBox.sidePanel.idCounter

    s.isOpen = false
    s.animState = 1
    s.animDelta = 0.03
    s.size = size
    s.name = name
    g.panels = {}

    g.pane = vgui.Create( "DFrame", chatBox.graphics.derma.frame )
    g.pane:SetName( "BC_settingsPane" )
    g.pane:SetPos( chatBox.graphics.size.x, 0 )
    g.pane:SetSize( s.size.x, s.size.y )
    g.pane:SetTitle( "" )
    g.pane:ShowCloseButton( false )
    g.pane:SetDraggable( false )
    g.pane:SetSizable( false )
    g.pane:MoveToFront()
    g.pane.name = name
    s.lastTime = CurTime()

    local pOldLayout = g.pane.PerformLayout
    function g.pane:PerformLayout()
        s.size.y = chatBox.graphics.size.y - 33
        self:SetSize( s.size.x, s.size.y )
        pOldLayout( self )
    end

    g.pane:SetKeyboardInputEnabled( true )
    g.pane:SetMouseInputEnabled( true )

    function g.pane:Think()
        local s = chatBox.sidePanel.panels[self.name]
        local g = s.graphics

        local xSum = chatBox.graphics.size.x
        for k, v in pairs( chatBox.sidePanel.panels ) do
            if v.idx < s.idx and v.animState > 0 then
                xSum = xSum + ( v.animState * v.size.x ) + 2
            end
        end

        local px, py = chatHelper.getFrom( 1, xSum ) + 2, 0
        local cx, cy = self:GetPos()
        if cx ~= px or cy ~= py then
            self:SetPos( px, py )
        end

        local w = chatHelper.getFrom( 1, g.frame:GetSize() )
        local px, py = w * s.animState - w, 0
        local cx, cy = g.frame:GetPos()
        if px ~= cx or py ~= cy then
            g.frame:SetPos( px, py )
        end

        if not chatBox.base.isOpen then 
            s.isOpen = false
        end

        local tPassed = CurTime() - s.lastTime
        if tPassed > 0.1 then tPassed = 0 end
        s.lastTime = CurTime()
        tPassed = tPassed * 150

        if s.isOpen and s.animState < 1 then
            s.animState = math.min( 1, s.animState + ( s.animDelta * tPassed ) )
        elseif not s.isOpen and s.animState > 0 then
            s.animState = math.max( 0, s.animState - ( s.animDelta * tPassed ) )
        end
    end
    function g.pane:Paint( w, h )
        local s = chatBox.sidePanel.panels[self.name]
        local g = s.graphics

        chatBox.util.blur( self, 10, 20, 255, w * s.animState, h )
        local x = w * s.animState - w
        draw.RoundedBox( 0, x, 0, w, h, chatBox.defines.theme.background )
        draw.RoundedBox( 0, x + 4, 27, w - 8 - 23, h - 4 - 27, chatBox.defines.theme.foreground )
        draw.RoundedBox( 0, x + 4 + w - 8 - 20, 27, 20, h - 4 - 27, chatBox.defines.theme.foreground )

        draw.RoundedBox( 0, x + 4, 4, 21, 21, chatBox.defines.theme.foreground )
        surface.SetFont( chatBox.graphics.font )
        local tw, th = surface.GetTextSize( self.name )
        draw.RoundedBox( 0, x + 4 + 23, 4, tw + 8, 21, chatBox.defines.theme.foreground )
        draw.DrawText( self.name, chatBox.graphics.font, x + 8 + 23, 4 + ( 21 - th ) / 2, chatBox.defines.colors.white )

        surface.SetDrawColor( col )
        surface.SetMaterial( icon )
        surface.DrawTexturedRectRotated( x + 6 + 9, 6 + 9, 19 - border * 2, 19 - border * 2, rot and ( -CurTime() * 15 ) or 0 )
    end

    g.frame = vgui.Create( "DFrame", g.pane )
    g.frame:SetName( "BC_settingsFrame" )
    g.frame:SetPos( 0, 0 )
    g.frame:SetSize( g.pane:GetSize() )
    g.frame:SetTitle( "" )
    g.frame:ShowCloseButton( false )
    g.frame:SetDraggable( false )
    g.frame:SetSizable( false )
    g.frame.Paint = nil
    g.frame.name = name

    local fOldLayout = g.frame.PerformLayout
    function g.frame:PerformLayout()
        self:SetSize( self:GetParent():GetSize() )
        fOldLayout( self )
    end

    g.frame.closeBtn = vgui.Create( "DButton", g.frame )
    local btn = g.frame.closeBtn
    local pane = g.frame
    btn.name = name
    btn:SetPos( chatHelper.getFrom( 1, g.frame:GetSize() ) - 4 - 20, 4 )
    btn:SetSize( 20, 20 )
    btn:SetText( "" )
    function btn:DoClick()
        chatBox.sidePanel.close( self.name )
    end
    function btn:Paint( w, h )
        draw.RoundedBox( 0, 0, 0, w, h, chatBox.defines.theme.foreground )
        local cross1 = { 
            { x = 2, y = 5 }, 
            { x = 5, y = 2 }, 
            { x = 18, y = 15 }, 
            { x = 15, y = 18 }, 
        }
        local cross2 = { 
            { x = 2, y = 15 }, 
            { x = 15, y = 2 }, 
            { x = 18, y = 5 }, 
            { x = 5, y = 18 }, 
        }

        surface.SetDrawColor( chatBox.defines.theme.sidePanelAccent )
        draw.NoTexture()
        surface.DrawPoly( cross1 )
        surface.DrawPoly( cross2 )
    end
end

function chatBox.sidePanel.createChild( pName, name )
    local s = chatBox.sidePanel.panels[pName]
    local g = s.graphics
    local p = vgui.Create( "DNiceScrollPanel", g.frame )
    p.graphics = g
    local w, h = g.frame:GetSize()
    p:SetSize( w - 8 - 8, h - 4 - 27 - 10 )
    p:SetPos( 4 + 5, 27 + 5 )

    local oldLayout = p.PerformLayout
    function p:PerformLayout()
        local w, h = self.graphics.frame:GetSize()
        self:SetSize( w - 8 - 8, h - 4 - 27 - 10 )
        self:SetPos( 4 + 5, 27 + 5 )
        oldLayout( self )
    end
    
    table.insert( g.panels, { Name = name, Panel = p } )
    p:Hide()
    return p
end

function chatBox.sidePanel.getChild( pName, name )
    local s = chatBox.sidePanel.panels[pName]
    local g = s.graphics
    for k, v in pairs( g.panels ) do
        if v.Name == name then
            return v.Panel
        end
    end
    return false
end


function chatBox.sidePanel.removeChild( pName, name, dontClose )
    local s = chatBox.sidePanel.panels[pName]
    local g = s.graphics
    if s.activePanel == name and not dontClose then
        chatBox.sidePanel.close( pName, true )
    end
    local success = false
    for k, p in pairs( g.panels ) do
        if p.Name == name then
            p.Panel:Remove()
            table.remove( g.panels, k )
            success = true
            break
        end
    end
    return success
end

function chatBox.sidePanel.show( pName, name )
    local s = chatBox.sidePanel.panels[pName]
    s.activePanel = name
    local g = s.graphics
    if not name then name = g.panels[1].Name end
    for k, v in pairs( g.panels ) do
        if v.Name == name then
            v.Panel:Show()
        else
            v.Panel:Hide()
        end
    end
end

function chatBox.sidePanel.childExists( pName, name )
    return asBool( chatBox.sidePanel.getChild( pName, name ) )
end

function chatBox.sidePanel.open( pName, name )
    chatBox.sidePanel.show( pName, name )
    chatBox.sidePanel.panels[pName].isOpen = true
end

function chatBox.sidePanel.close( pName, noAnim )
    chatBox.graphics.derma.textEntry:RequestFocus()
    chatBox.sidePanel.panels[pName].isOpen = false
    if noAnim then
        chatBox.sidePanel.panels[pName].animState = 0
    end
end
