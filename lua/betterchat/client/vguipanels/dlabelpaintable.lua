local PANEL = {}

function PANEL:Init()
    self:SetTextColor( Color( 255, 255, 255, 255 ) )
end

function PANEL:Paint( w, h )
    if #self._text == 0 then return end
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

function PANEL:SizeToContents( addW, addH )
    addW = addW or 0
    addH = addH or 0
    local w, h = self:GetTextSize()
    self:SetSize( w + addW, h + addH )
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

function PANEL:SetFont( font )
    self._font = font
end

function PANEL:GetFont()
    return self._font
end

function PANEL:SetTextColor( col )
    self._textCol = col
end

function PANEL:GetTextColor()
    return self._textCol
end

vgui.Register( "DLabelPaintable", PANEL, "DPanel" )
