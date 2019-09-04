local RTG = {}
local RTGTypes = {"image", "gif"}

function RTG:Init()
	self.offset = {["x"] = 0, ["y"] = 0, ["w"] = 0, ["h"] = 0}
	self.useOffset = false
	self.doRender = true
	self.color = Color(255,255,255,255)
end

function RTG:SetType(t)
	if table.HasValue(RTGTypes, t) then
		self.type = t
		self:UpdateGraphic()
	else
		self.type = "image"
		MsgC(Color(255,0,0), "[RicherTextGraphic] Invalid graphic type \"" .. t .. "\"")
	end
end

function RTG:GetTextColor()
	return self.color
end

function RTG:SetTextColor(col)
	self.color = col
	self:UpdateColor()
end

function RTG:UpdateColor()
	self:SetAlpha(self.color.a)
end

function RTG:SetSubImage(x, y, w, h)
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

function RTG:SetPath(path)
	self.path = path
	self:UpdateGraphic()
end

function RTG:UpdateGraphic()
	if self.graphic then self.graphic:Remove() end
	if not self.doRender then return end
	if not self.path or not self.type then return end
	
	if self.type == "image" then
		local g = vgui.Create("DImage", self)
		g:Dock(FILL)
		local mat = Material(self.path)

		g.m_Material = mat

		g.offset = self.offset
		g.useOffset = self.useOffset

		g.Paint = function(im, w, h)
			
			if ( !im.m_Material ) then return true end

			surface.SetMaterial( im.m_Material )
			surface.SetDrawColor( im.m_Color.r, im.m_Color.g, im.m_Color.b, im.m_Color.a )


			if not im.useOffset then
				surface.DrawTexturedRect( 0, 0, w, h )
			else
				local sx, sy = im.m_Material:Width(), im.m_Material:Height()

				local u0, u1, v0, v1 = im.offset.x/sx, im.offset.y/sy, (im.offset.x + im.offset.w)/sx, (im.offset.y + im.offset.h)/sy

				-- Code from DrawTexturedRectUV wiki for removing invalid pixel correction
				-- local du = 0.5 / 32 -- half pixel anticorrection
				-- local dv = 0.5 / 32 -- half pixel anticorrection
				-- u0, v0 = ( u0 - du ) / ( 1 - 2 * du ), ( v0 - dv ) / ( 1 - 2 * dv )
				-- u1, v1 = ( u1 - du ) / ( 1 - 2 * du ), ( v1 - dv ) / ( 1 - 2 * dv )
				
				surface.DrawTexturedRectUV( 0, 0, w, h, u0, u1, v0, v1)
			end
		end


		self.graphic = g
	else
		local g = vgui.Create("DHTML", self)
		g:Dock()
		g:SetHTML(
			[[
				<style> 
					div {
					    width: ]] .. self:GetWidth() .. [[px;
					    height: ]] .. self:GetHeight() .. [[px;
					    overflow: hidden;
					}
					body {
						margin: 0px;
					}
				</style>
			]] .. "<body><div><img src=\"" .. self.path .. "\"></div></body>")

		g:RunJavascript(
			"var w = " .. self:GetWidth() .. "; " ..
			"var h = " .. self:GetHeight() .. "; " ..
			"var offsetX = " .. self.offset.x .. "; " ..
			"var offsetY = " .. self.offset.y .. "; " ..
			"var offsetW = " .. self.offset.w .. "; " ..
			"var offsetH = " .. self.offset.h .. "; " ..
			[[
			var im = document.getElementsByTagName("img")[0];
			var originalW = im.naturalWidth;
			var originalH = im.naturalHeight;
			var scaleX = w/offsetW;
			var scaleY = h/offsetH;
			var left = -offsetX * scaleX;
			var top = -offsetY * scaleY;

			im.width = originalW * scaleX;
			im.height = originalH * scaleY;

			im.style.margin = top + "px 0px 0px "+left+"px";
		]])
		self.graphic = g
	end
end

function RTG:SetDoRender(r)
	if self.doRender == r then return end
	if self.type == "image" then
		if r then self.graphic:Show() else self.graphic:Hide() end
	else
		if r then
			self:UpdateGraphic()
		else
			self.graphic:Remove()
		end
	end
	self.doRender = r
end

vgui.Register( "DRicherTextGraphic", RTG, "Panel" )