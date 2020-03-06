local RTG = {}
local RTGTypes = { "image", "gif" }

function RTG:Init()
    self.offset = { ["x"] = 0, ["y"] = 0, ["w"] = 0, ["h"] = 0 }
    self.useOffset = false
    self.doRender = true
    self.prevDoRender = true
    self.color = Color( 255, 255, 255, 255 )
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
			element.style.opacity = ]] .. ( a / 255 ) .. ";" )
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

        g.Paint = function( im, w, h )
            
            if ( !im.m_Material ) then return true end

            surface.SetMaterial( im.m_Material )
            surface.SetDrawColor( im.m_Color.r, im.m_Color.g, im.m_Color.b, im.m_Color.a )


            if not im.useOffset then
                surface.DrawTexturedRect( 0, 0, w, h )
            else
                local sx, sy = im.m_Material:Width(), im.m_Material:Height()

                local u0, u1, v0, v1 = im.offset.x / sx, im.offset.y / sy, ( im.offset.x + im.offset.w ) / sx, ( im.offset.y + im.offset.h ) / sy
                
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