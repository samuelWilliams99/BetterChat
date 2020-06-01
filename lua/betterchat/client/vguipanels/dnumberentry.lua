local PANEL = {}

local upTriangle = {
    { x = 8, y = 4 },
    { x = 12, y = 8 },
    { x = 4, y = 8 },
}

local downTriangle = {
    { x = 8, y = 5 },
    { x = 4, y = 1 },
    { x = 12, y = 1 },
}

function PANEL:Init()
    self._isInt = true
    self._allowNegative = false
    self._def = 0

    self._min = 0
    self._max = 100

    self:SetValue( 0 )

    local this = self
    local upBtn = vgui.Create( "DButton", self )
    upBtn:SetText( "" )
    function upBtn:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        draw.NoTexture()
        surface.DrawPoly( upTriangle )
    end

    function upBtn:DoClick()
        this:SetValue( this:GetValue() + 1 )
    end

    self.__upButton = upBtn

    local downBtn = vgui.Create( "DButton", self )
    downBtn:SetText( "" )
    function downBtn:Paint( w, h )
        surface.SetDrawColor( 0, 0, 0, 255 )
        draw.NoTexture()
        surface.DrawPoly( downTriangle )
    end

    function downBtn:DoClick()
        this:SetValue( this:GetValue() - 1 )
    end

    self.__downButton = downBtn
end

function PANEL:PerformLayout()
    local w, h = self:GetSize()

    self.__upButton:SetSize( 16, h / 2 )
    self.__upButton:SetPos( w - 16, 0 )

    self.__downButton:SetSize( 16, h / 2 )
    self.__downButton:SetPos( w - 16, h / 2 )
end

function PANEL:ValidateValue( v )
    if type( v ) ~= "number" then
        error( "Value " .. tostring( v ) .. " is not a number" )
    end

    if self._isInt then
        v = math.Round( v )
    end

    if v < self._min then
        v = self._min
    end

    if v > self._max then
        v = self._max
    end

    return v
end

function PANEL:SetValue( v )
    v = self:ValidateValue( v )

    self:SetText( tostring( v ) )

    if self.OnValueChanged then
        self:OnValueChanged( v )
    end
end

function PANEL:GetValue()
    local str = self:GetText()
    return tonumber( str )
end

function PANEL:SetIsInteger( isInt )
    self._isInt = isInt
end

function PANEL:GetIsInteger()
    return self._isInt
end

local numbers = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }

function PANEL:AllowInput( c )
    if table.HasValue( numbers, c ) then return false end

    if self._allowNegative then
        if c == "-" and self:GetCaretPos() == 0 then return false end
    end

    if not self._isInt then
        if c == "." and not string.find( self:GetText(), ".", nil, true ) then return false end
    end

    return true
end

function PANEL:OnValueChange( newVal )
    local num = tonumber( newVal )
    if not num then
        self:SetValue( self._def )
        return
    end

    local validNum = self:ValidateValue( num )

    if validNum ~= num then
        self:SetText( tostring( validNum ) )
    end

    if self.OnValueChanged then
        self:OnValueChanged( validNum )
    end
end

function PANEL:UpdateAllowNegative()
    self._allowNegative = self._min < 0
end

function PANEL:SetMin( min )
    if min >= self._max then
        error( "Min cannot be less than max" )
    end

    self._min = min
    if self._def < min then
        self._def = min
    end

    self:UpdateAllowNegative()
end

function PANEL:SetMax( max )
    if max <= self._min then
        error( "Max cannot be less than min" )
    end

    self._max = max
    if self._def > max then
        self._def = max
    end

    self:UpdateAllowNegative()
end

function PANEL:SetDefault( def )
    self._def = def
end

vgui.Register( "DNumberEntry", PANEL, "DTextEntry" )