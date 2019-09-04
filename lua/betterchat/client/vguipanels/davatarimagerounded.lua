-- Thanks Acecool and HandsomeMatt for your code
 
local function GenerateCircle(radius)
    local seg = 100
    local cir = {}

    table.insert( cir, { x = 0, y = 0, u = 0.5, v = 0.5 } )
    for i = 0, seg do
        local a = math.rad( ( i / seg ) * -360 )
        table.insert( cir, { x = radius/2 + math.sin( a ) * radius * 0.5, y = radius/2 + math.cos( a ) * radius * 0.5, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
    end

    local a = math.rad( 0 ) -- This is needed for non absolute segment counts
    table.insert( cir, { x = radius/2 + math.sin( a ) * radius * 0.5, y = radius/2 + math.cos( a ) * radius * 0.5, u = math.sin( a ) / 2 + 0.5, v = math.cos( a ) / 2 + 0.5 } )
    return cir
end

local _material = Material( "effects/flashlight001" );
 
local PANEL = {}
 
function PANEL:Init()
    self.Avatar = vgui.Create("AvatarImage", self)
    self.Avatar:SetPaintedManually(true)
    self:UpdatePoly()
end

function PANEL:UpdatePoly()
    self.poly = GenerateCircle(self:GetWide())
end

function PANEL:OnSizeChanged()
    self:SetSize(self:GetWide(), self:GetWide())
    self:UpdatePoly()
end
 
function PANEL:PerformLayout()
    self.Avatar:SetSize(self:GetWide(), self:GetTall())
end
 
function PANEL:Paint(w, h)
    render.ClearStencil()
    render.SetStencilEnable(true)

    render.SetStencilWriteMask( 1 )
    render.SetStencilTestMask( 1 )

    render.SetStencilFailOperation( STENCIL_REPLACE )
    render.SetStencilPassOperation( STENCIL_ZERO )
    render.SetStencilZFailOperation( STENCIL_ZERO )
    render.SetStencilCompareFunction( STENCIL_NEVER )
    render.SetStencilReferenceValue( 1 )

    draw.NoTexture( );
    surface.SetMaterial( _material );
    surface.SetDrawColor( color_black )
    surface.DrawPoly( self.poly )

    render.SetStencilFailOperation( STENCIL_ZERO )
    render.SetStencilPassOperation( STENCIL_REPLACE )
    render.SetStencilZFailOperation( STENCIL_ZERO )
    render.SetStencilCompareFunction( STENCIL_EQUAL )
    render.SetStencilReferenceValue( 1 )

    self.Avatar:SetPaintedManually(false)
    self.Avatar:PaintManual()
    self.Avatar:SetPaintedManually(true)

    render.SetStencilEnable(false)
    render.ClearStencil()
end

function PANEL:SetPlayer(ply)
    self.Avatar:SetPlayer(ply)
end
 
vgui.Register("AvatarImageCircle", PANEL)
 
 