local RTG = {}
local RTGTypes = { "image", "gif" }

function RTG:Init()
    self.offset = { ["x"] = 0, ["y"] = 0, ["w"] = 0, ["h"] = 0 }
    self.useOffset = false
    self.doRender = true
    self.prevDoRender = true
    self.color = Color( 255, 255, 255, 255 )
    self.sizeScale = nil
end

function RTG:SetSizeScale( x, y )
    self.sizeScale = { x = x, y = y }
end

function RTG:GetSizeScale()
    return self.sizeScale
end

function RTG:SetType( t )
    if table.HasValue( RTGTypes, t ) then
        self.type = t
        self:UpdateGraphic()
    else
        self.type = "image"
        MsgC( Color( 255, 0, 0 ), "[RicherTextGraphic] Invalid graphic type \"" .. t .. "\"" )
    end
end

function RTG:GetTextColor()
    return self.color
end

function RTG:SetTextColor( col )
    self.color = col
    self:UpdateColor()
end

function RTG:UpdateColor()
    self:SetAlpha( self.color.a )
    if self.type == "gif" and self.graphic and IsValid( self.graphic ) then
        local a = self:GetAlpha()
        self.graphic:RunJavascript( [[
			var element = document.getElementsByTagName("img")[0]
            if (element) {
			element.style.opacity = ]] .. ( a / 255 ) .. [[;
        }]] )
    end
end

function RTG:SetSubImage( x, y, w, h )
    if x == nil then
        self.useOffset = false
    else
        self.offset.x = x
        self.offset.y = y
        self.offset.w = w
        self.offset.h = h
        self.useOffset = true
    end
    self:UpdateGraphic()
end

function RTG:SetPath( path )
    self.path = path
    self:UpdateGraphic()
end

function RTG:UpdateGraphic()
    if self.graphic then self.graphic:Remove() end
    if not self.doRender then return end
    if not self.path or not self.type then return end

    if self.type == "image" then
        local g = vgui.Create( "DImage", self )
        g:Dock( FILL )
        local mat = Material( self.path )

        g.m_Material = mat

        g.offset = self.offset
        g.useOffset = self.useOffset

        function g:Paint( w, h )

            if ( !self.m_Material ) then return true end

            surface.SetMaterial( self.m_Material )
            surface.SetDrawColor( self.m_Color.r, self.m_Color.g, self.m_Color.b, self.m_Color.a )


            if not self.useOffset then
                surface.DrawTexturedRect( 0, 0, w, h )
            else
                local sx, sy = self.m_Material:Width(), self.m_Material:Height()

                local u0, u1, v0, v1 = self.offset.x / sx, self.offset.y / sy, ( self.offset.x + self.offset.w ) / sx, ( self.offset.y + self.offset.h ) / sy

                surface.DrawTexturedRectUV( 0, 0, w, h, u0, u1, v0, v1 )
            end
        end


        self.graphic = g
    else
        local g = vgui.Create( "DHTML", self )
        g:Dock( FILL )
        g:SetHTML(
            [[
				<style> 
					body, div, img {
						margin: 0px;
						overflow: hidden;
					    width: ]] .. self:GetWide() .. [[px;
					    height: ]] .. self:GetTall() .. [[px;
					}
				</style>
			]] .. "<body><div><img src=\"" .. self.path .. "\"></div></body>" )
        self.graphic = g
    end
end

function RTG:SetDoRender( r )
    if self.doRender == r then return end
    self.doRender = r
    timer.Simple( 0.1, function()
        self:UpdateDoRender()
    end )
end

function RTG:UpdateDoRender()
    if self.prevDoRender == self.doRender then return end
    local r = self.doRender
    if self.type == "image" then
        if r then self.graphic:Show() else self.graphic:Hide() end
    else
        if r then
            self:UpdateGraphic()
        else
            self.graphic:Remove()
        end
    end
    self.prevDoRender = self.doRender
end

vgui.Register( "DRicherTextGraphic", RTG, "Panel" )
