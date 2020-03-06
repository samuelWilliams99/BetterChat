NICESCROLLPANEL = {}

function NICESCROLLPANEL:Init()
    self:SetSize( 100, 100 )
    self.scrollBarEnabled = true

    local scrollBar = self:GetVBar()
    scrollBar.Enabled = true
    local ownSelf = self
    scrollBar.Paint = nil
    scrollBar.btnUp.Paint = function( self, w, h )
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
    scrollBar.btnDown.Paint = function( self, w, h )
        if not ownSelf.scrollBarEnabled then return end
        local canScrollUp = scrollBar.Scroll < scrollBar.CanvasSize - 1
        if canScrollUp then
            surface.SetDrawColor( 200, 200, 200, 100 )
        else
            surface.SetDrawColor( 150, 150, 150, 100 )
        end
        draw.NoTexture()
        drawDownArrow()
    end
    scrollBar.btnGrip.Paint = function( self, w, h )
        if not ownSelf.scrollBarEnabled then return end
        draw.RoundedBox( 0, 5, 0, w - 10, h, Color( 200, 200, 200, 100 ) )
    end
end

function NICESCROLLPANEL:SetScrollbarEnabled( draw )
    self:SetVerticalScrollbarEnabled( draw )
    self.scrollBarEnabled = draw
end

function NICESCROLLPANEL:PerformLayout()
    local Tall = self.pnlCanvas:GetTall()
    local Wide = self:GetWide() - 30
    local YPos = 0

    self:Rebuild()

    self.VBar:SetUp( self:GetTall(), self.pnlCanvas:GetTall() )
    YPos = self.VBar:GetOffset()

    self.pnlCanvas:SetPos( 0, YPos )
    self.pnlCanvas:SetWide( Wide )

    self:Rebuild()

    if ( Tall ~= self.pnlCanvas:GetTall() ) then
        self.VBar:SetScroll( self.VBar:GetScroll() ) -- Make sure we are not too far down!
    end
end

function NICESCROLLPANEL:Paint( w, h )
    self:SetVerticalScrollbarEnabled( self.scrollBarEnabled )
    if self.scrollBarEnabled then
        self:GetVBar():Show()
    end
end

vgui.Register( "DNiceScrollPanel", NICESCROLLPANEL, "DScrollPanel" )