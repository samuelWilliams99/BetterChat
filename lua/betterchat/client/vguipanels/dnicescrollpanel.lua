local NICESCROLLPANEL = {}

local upArrowLeft = {
    { x = 0, y = 6 },
    { x = 8, y = 0 },
    { x = 11, y = 3 },
    { x = 3, y = 9 },
}
local upArrowRight = {
    { x = 8, y = 5 },
    { x = 11, y = 3 },
    { x = 15, y = 7 },
    { x = 12, y = 9 }
}

local function drawUpArrow()
    surface.DrawPoly( upArrowLeft )
    surface.DrawPoly( upArrowRight )
end

local function invertTab( tab ) -- For arrow rendering
    local out = {}
    for k = 1, #tab do
        local v = tab[k]
        table.insert( out, { x = 15 - v.x, y = 15 - v.y } )
    end
    return out
end

local function drawDownArrow()
    surface.DrawPoly( invertTab( upArrowLeft ) )
    surface.DrawPoly( invertTab( upArrowRight ) )
end

function NICESCROLLPANEL:Init()
    self:SetSize( 100, 100 )
    self.scrollBarEnabled = true

    local scrollBar = self:GetVBar()
    scrollBar.Enabled = true
    local ownSelf = self
    scrollBar.Paint = nil
    function scrollBar.btnUp:Paint( w, h )
        if not ownSelf.scrollBarEnabled then return end
        local canScrollUp = scrollBar:GetScroll() ~= 0
        if canScrollUp then
            surface.SetDrawColor( 200, 200, 200, 100 )
        else
            surface.SetDrawColor( 150, 150, 150, 100 )
        end
        draw.NoTexture()
        drawUpArrow()
    end
    function scrollBar.btnDown:Paint( w, h )
        if not ownSelf.scrollBarEnabled then return end
        local canScrollDown = scrollBar.Scroll < scrollBar.CanvasSize - 1
        if canScrollDown then
            surface.SetDrawColor( 200, 200, 200, 100 )
        else
            surface.SetDrawColor( 150, 150, 150, 100 )
        end
        draw.NoTexture()
        drawDownArrow()
    end
    function scrollBar.btnGrip:Paint( w, h )
        if not ownSelf.scrollBarEnabled then return end
        draw.RoundedBox( 0, 5, 0, w - 10, h, Color( 200, 200, 200, 100 ) )
    end
end

function NICESCROLLPANEL:SetScrollbarEnabled( draw )
    self:SetVerticalScrollbarEnabled( draw )
    self.scrollBarEnabled = draw
end

function NICESCROLLPANEL:PerformLayout()
    local tall = self.pnlCanvas:GetTall()
    local wide = self:GetWide() - 30
    local yPos = 0

    self:Rebuild()

    self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
    yPos = self.VBar:GetOffset()

    self.pnlCanvas:SetPos( 0, yPos )
    self.pnlCanvas:SetWide( wide )

    self:Rebuild()

    if ( tall ~= self.pnlCanvas:GetTall() ) then
        self.VBar:SetScroll( self.VBar:GetScroll() ) -- Make sure we are not too far down!
    end
end

function NICESCROLLPANEL:Paint( w, h )
    self:SetVerticalScrollbarEnabled( self.scrollBarEnabled )
    if self.scrollBarEnabled and not self:GetVBar():IsVisible() then
        self:GetVBar():Show()
    end
end

vgui.Register( "DNiceScrollPanel", NICESCROLLPANEL, "DScrollPanel" )
