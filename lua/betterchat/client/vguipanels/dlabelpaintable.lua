local PANEL = {}

function PANEL:Init()
    self.BaseClass.SetText( self, "" )
end

function PANEL:Paint( w, h )
    draw.DrawText( self._text, self:GetFont(), 0, -1, self:GetTextColor() )
end

function PANEL:SizeToContentsX( addVal )
    addVal = addVal or 0
    local w, _ = self:GetTextSize()
    self:SetWide( w + addVal )
end

function PANEL:SizeToContentsY( addVal )
    addVal = addVal or 0
    local _, h = self:GetTextSize()
    self:SetTall( h + addVal )
end

function PANEL:SizeToContents()
    local w, h = self:GetTextSize()
    self:SetSize( w, h )
end

function PANEL:GetTextSize()
    surface.SetFont( self:GetFont() )
    return surface.GetTextSize( self._text )
end

function PANEL:SetText( text )
    self._text = text
end

function PANEL:GetText()
    return self._text
end

vgui.Register( "DLabelPaintable", PANEL, "DLabel" )
