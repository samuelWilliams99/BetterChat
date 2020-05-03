include( "drichertextgraphic.lua" )

local RICHERTEXT = {}

local function getFrom( idx, ... ) -- Simple helper function that picks an input from a list. getFrom(2, a, b, c) = b
    local d = { ... }
    return d[idx]
end

local function getElementSize( elem, subHalfChar )
    if elem:GetClassName() == "Label" then
        surface.SetFont( elem:GetFont() )
        local txt = elem:GetText()
        local sx, sy = surface.GetTextSize( txt )
        return sx - ( subHalfChar and getFrom( 1, surface.GetTextSize( txt[#txt] ) ) / 2 or 0 ), sy
    else
        return elem:GetWide()
    end
end

local function getElementSizeX( elem, subHalfChar )
    return getFrom( 1, getElementSize( elem, subHalfChar ) )
end

local function getTextSizeX( txt, subHalfChar )
    return getFrom( 1, surface.GetTextSize( txt ) )
end

local function isLabel( elem )
    return elem:GetClassName() == "Label"
end

local function orderChars( s, e )
    if s.line < e.line then
        return s, e
    elseif s.line > e.line then
        return e, s
    end

    if s.element < e.element then
        return s, e
    elseif s.element > e.element then
        return e, s
    end

    if s.char > e.char then
        return e, s
    end

    return s, e
end

local function isNewLineObj( obj )
    return type( obj ) == "table" and obj.isNewLine
end

local idCounter = 0
function RICHERTEXT:Init()
    local this = self

    self:SetSize( 100, 100 )
    self.scrollPanel = vgui.Create( "DNiceScrollPanel", self ) -- Same as scrollPanel with nicer graphics
    self.id = idCounter
    idCounter = idCounter + 1

    self.log = {}
    self.graphics = {}

    self:SetMouseInputEnabled( true )
    self.scrollPanel:SetMouseInputEnabled( true )
    self.scrollPanel:GetCanvas():SetMouseInputEnabled( true )
    self.scrollPanel:GetCanvas():SetSelectionCanvas( true )

    self:setClickEvents( self.scrollPanel )

    self.scrollPanel:SetScrollbarEnabled( true )
    self.scrollPanel:Dock( FILL )
    local scrollBar = self.scrollPanel:GetVBar()

    self.select = {}
    self.select.lastClick = 0
    self.select.clickCounter = 0
    self.select.selectCol = Color( 0, 0, 255 ) -- normal blue highlight

    self.lastScroll = -1

    function self:Think()
        if self.select.mouseDown then
            local sPanel = self.scrollPanel
            local x, y = gui.MousePos()
            local px, py = sPanel:LocalToScreen( 0, 0 )
            local sx, sy = sPanel:GetSize()
            local x, y = math.Clamp( x, px, px + sx ), math.Clamp( y, py, py + sy )

            local lx, ly = self:ScreenToCanvas( x, y )
            local cd = self:getCharacter( lx, ly )
            local scd = self.select.startChar
            if math.abs( cd.pos.x - scd.pos.x ) < 2 and math.abs( cd.pos.y - scd.pos.y ) < 2 then
                self.select.hasSelection = false
            else
                self.select.hasSelection = true
                self.select.endChar = cd
            end
            if not input.IsMouseDown( MOUSE_LEFT ) then
                self.select.mouseDown = false
            end
        end
        local scrollBar = self.scrollPanel:GetVBar()
        self.showSTBButton = scrollBar.Scroll < scrollBar.CanvasSize - 100

        if self.STBButtonAnim < 100 and self.showSTBButton then
            if self.STBButtonAnim == 0 then
                self.scrollToBottomBtn:Show()
            end
            self.STBButtonAnim = math.Clamp( self.STBButtonAnim + self.STBButtonAnimSpeed, 0, 100 )
        end

        if self.STBButtonAnim > 0 and not self.showSTBButton then
            self.STBButtonAnim = math.Clamp( self.STBButtonAnim - self.STBButtonAnimSpeed, 0, 100 )
            if self.STBButtonAnim == 0 then
                self.scrollToBottomBtn:Hide()
            end
        end

        self.scrollToBottomBtn.m_Image:SetImageColor( Color( 255, 255, 255, self.STBButtonAnim * 2.55 ) )

        if self.lastScroll ~= scrollBar.Scroll then
            local sPanel = self.scrollPanel
            local sx, sy = sPanel:GetSize()

            local csx, csy = sPanel:GetCanvas():GetSize()

            -- before
            local scrollProp = self.lastScroll / scrollBar.CanvasSize
            local minYB = math.max( 0, scrollProp * ( csy - sy ) )
            local maxYB = minYB + sy
            self:SetDoRenderInRange( minYB, maxYB, false )

            -- after
            self.lastScroll = scrollBar.Scroll
            scrollProp = self.lastScroll / scrollBar.CanvasSize
            local minYA = math.max( 0, scrollProp * ( csy - sy ) )
            local maxYA = minYA + sy
            self:SetDoRenderInRange( minYA, maxYA, true )

        end

    end

    self.scrollToBottomBtn = vgui.Create( "DImageButton", self )
    self.scrollToBottomBtn:SetImage( "icons/triple_arrows.png" )
    self.scrollToBottomBtn.Paint = nil
    self.scrollToBottomBtn:SetSize( 32, 32 )
    self.scrollToBottomBtn:Hide()
    function self.scrollToBottomBtn:DoClick()
        this:scrollToBottom()
    end
    self:InvalidateLayout( true )
    self.showSTBButton = false
    self.STBButtonAnim = 0
    self.STBButtonAnimSpeed = 2

    local canvas = self.scrollPanel:GetCanvas()

    function canvas:Paint( w, h ) -- Rendering selection, if I put images in the line stack, this will need updating TODO
        if this.select.hasSelection then
            --do draw selection stuff
            local c = this.select.selectCol
            surface.SetDrawColor( c.r, c.g, c.b, 255 )
            local s, e = orderChars( this.select.startChar, this.select.endChar )
            for l = s.line, e.line do
                local line = this.lines[l]

                if #line == 0 then continue end

                local lastElement = line[#line]
                local px, py = lastElement:GetPos()
                local sx = getElementSizeX( lastElement )
                local startX, endX = getFrom( 1, line[1]:GetPos() ), px + sx

                if l == s.line then
                    local element = line[s.element]

                    if not element then
                        self:UnselectText()
                    end

                    local sx
                    local px, py = element:GetPos()
                    if isLabel( element ) then
                        surface.SetFont( element:GetFont() )
                        sx = getTextSizeX( string.sub( element:GetText(), 1, s.char - 1 ) )
                    else
                        if s.char > 1 then
                            sx = element:GetWide()
                        else
                            sx = 0
                        end
                    end
                    startX = px + sx
                end
                if l == e.line then
                    local element = line[e.element]
                    local sx
                    local px, py = element:GetPos()
                    if isLabel( element ) then
                        surface.SetFont( element:GetFont() )
                        sx = getTextSizeX( string.sub( element:GetText(), 1, e.char ) )
                    else
                        if e.char > 1 then
                            sx = element:GetWide()
                        else
                            sx = 0
                        end
                    end
                    endX = px + sx
                end

                local h = this.fontHeight

                if #line == 1 and not isLabel( lastElement ) and lastElement:GetTall() > h then
                    h = lastElement:GetTall()
                end

                surface.DrawRect( startX, ( l - 1 ) * this.fontHeight, endX - startX, h )

            end

        end
    end

    self:OnRemove()
    hook.Add( "RICHERTEXT:NewTextSelection", "NewTextSelection - " .. self.id, function( id )
        if self.id ~= id then
            self:UnselectText()
        end
    end )

    hook.Add( "RICHERTEXT:CopyText", "CopyText - " .. self.id, function()
        local t = self:GetSelectedText()
        if t then
            return t
        end
    end )

    self.lines = { {} }
    self.offset = { x = 0, y = 0 }
    self.fontHeight = 20
    self.linesYs = { { top = 0, bottom = self.fontHeight } }
    self.innerFont = "Default"
    self.addNewLine = false
    self.doFormatting = true
    self.showGraphics = true
    self.maxLines = 200
    self.yRemoved = 0
    self.allowDecorations = true

    self.textColor = Color( 255, 255, 255, 255 )
    self.clickable = nil
    self.tabSize = 40

    self.ready = true
end

function RICHERTEXT:SetDoRenderInRange( minY, maxY, value )
    local inArea = false
    for k, v in ipairs( self.linesYs ) do
        if ( v.bottom - self.yRemoved ) > minY then
            inArea = true
        end
        if inArea then
            if ( v.top - self.yRemoved ) > maxY then
                break
            end
            for i, el in pairs( self.lines[k] ) do
                el:SetDoRender( value )
            end
        end
    end
end

function RICHERTEXT:SetFormattingEnabled( val )
    self.doFormatting = val
end

function RICHERTEXT:SetGraphicsEnabled( val )
    self.showGraphics = val
end

function RICHERTEXT:SetGifsEnabled( val )
    self.showGifs = val
end

function RICHERTEXT:SetMaxLines( val )
    self.maxLines = val
end

function RICHERTEXT:SetHighlightColor( col )
    self.select.selectCol = col
end

function RICHERTEXT:Reload() -- Clear the text, reset a bunch of shit, then run through the logs again

    for k1, v1 in pairs( self.lines ) do
        for k, v in pairs( v1 ) do
            v:Remove()
        end
    end

    self.lines = { {} }
    self.linesYs = { { top = 0, bottom = self.fontHeight } }
    self.select.hasSelection = false
    self.textColor = Color( 255, 255, 255, 255 )
    self.clickable = nil
    self.offset = { x = 0, y = 0 }
    self.addNewLine = false
    self.graphics = {}
    self.yRemoved = 0

    local funcs = {
        ["text"] = RICHERTEXT.AppendText,
        ["col"] = RICHERTEXT.InsertColorChange,
        ["clickStart"] = RICHERTEXT.InsertClickableTextStart,
        ["clickEnd"] = RICHERTEXT.InsertClickableTextEnd,
        ["image"] = RICHERTEXT.AddImage,
        ["gif"] = RICHERTEXT.AddGif,
        ["decorations"] = RICHERTEXT.SetDecorations
    }

    self.logCopy = table.Copy( self.log )
    self.log = {}

    for k = 1, #self.logCopy do
        funcs[self.logCopy[k].type]( self, unpack( self.logCopy[k].data or {} ) )
    end
end

function RICHERTEXT:OnRemove()
    if not self.id then return end
    hook.Remove( "RICHERTEXT:NewTextSelection", "NewTextSelection - " .. self.id )
    hook.Remove( "RICHERTEXT:CopyText", "CopyText - " .. self.id )
end

function RICHERTEXT:createContextMenu( dontOpen, m )
    m = m or DermaMenu()
    local mPos = { self:ScreenToCanvas( gui.MousePos() ) }

    local c = self:getCharacter( mPos[1], mPos[2] )
    local element = self.lines[c.line][c.element]

    m:AddOption( "Copy Text", function()
        local txt = hook.Run( "RICHERTEXT:CopyText" )
        if txt then
            SetClipboardText( txt )
        end
    end )

    if isLabel( element ) then
        m:AddOption( "Copy Color", function()
            local col = element:GetTextColor()
            SetClipboardText( col.r .. ", " .. col.g .. ", " .. col.b )
        end )
    end

    if not dontOpen then
        m:Open()
    end

    return m
end

function RICHERTEXT:setClickEvents( panel )
    local this = self
    local prevMousePressed = panel.OnMousePressed
    function panel:OnMousePressed( keyCode )
        if keyCode == MOUSE_LEFT then
            if this.lines and #this.lines >= 1 and #this.lines[1] >= 1 then
                hook.Run( "RICHERTEXT:NewTextSelection", this.id )
                if CurTime() - this.select.lastClick < 0.2 then
                    this.select.clickCounter = this.select.clickCounter + 1
                else
                    this.select.clickCounter = 1
                end
                this.select.lastClick = CurTime()

                if this.select.clickCounter > 1 then
                    this.select.clickCounter = ( ( this.select.clickCounter ) % 2 ) + 2 --make it loop quad back to double, and quin to trip etc. so 1,2,3,4,5 -> 1,2,3,2,3
                end

                local x, y = this:ScreenToCanvas( gui.MousePos() )
                this.select.startPos = { x = x, y = y }
                this.select.startChar = this:getCharacter( this.select.startPos.x, this.select.startPos.y )

                if this.select.clickCounter == 1 then
                    this.select.mouseDown = true
                elseif this.select.clickCounter == 2 then
                    this.select.mouseDown = false
                    --do this one somehow
                    local c = this.select.startChar
                    local lineText = this:GetLineRaw( c.line )

                    local element = this.lines[c.line][c.element]

                    if isLabel( element ) then

                        local realCharIdx = element.rawTextIdx + c.char - 1

                        local sIdx = 1
                        local isSpace = false
                        if lineText[realCharIdx] == " " or lineText[realCharIdx] == "\t" or lineText[realCharIdx] == "\n" then
                            isSpace = true --selecting spaces/tabs
                        end

                        for i = realCharIdx, 1, -1 do
                            local char = lineText[i]
                            if isSpace ~= ( char == " " or char == "\t" or char == "\n" ) then
                                sIdx = i + 1
                                break
                            end
                        end

                        local eIdx = #lineText
                        for i = realCharIdx, #lineText do
                            local char = lineText[i]
                            if isSpace ~= ( char == " " or char == "\t" or char == "\n" ) then
                                eIdx = i - 1
                                break
                            end
                        end

                        this.select.startChar = this:CharIdxToChar( c.line, sIdx + 1 )
                        this.select.endChar = this:CharIdxToChar( c.line, eIdx + 1 )
                    else
                        this.select.startChar = c
                        local ec = table.Copy( c )
                        ec.char = ec.char + 1
                        this.select.endChar = ec
                    end
                    this.select.hasSelection = true
                elseif this.select.clickCounter == 3 then
                    this.select.mouseDown = false
                    this.select.startChar.element = 1
                    this.select.startChar.char = 1
                    local sChar = this.select.startChar
                    local line = this.lines[sChar.line]

                    this.select.endChar = {
                        line = sChar.line,
                        element = #line,
                        char = ( isLabel( line[#line] ) and ( #line[#line]:GetText() ) or 2 )
                    }
                    this.select.hasSelection = true
                end
            end
        elseif keyCode == MOUSE_RIGHT then
            this:createContextMenu()
        end

        if prevMousePressed then
            prevMousePressed( self, keyCode )
        end
    end
    local prevMouseReleased = panel.OnMouseReleased
    function panel:OnMouseReleased( keyCode )
        if keyCode == MOUSE_LEFT then
            this.select.mouseDown = false
        end
        if prevMouseReleased then
            prevMouseReleased( self, keyCode )
        end
    end
    panel:SetCursor( "beam" )
end

function RICHERTEXT:UnselectText()
    self.select.hasSelection = false
    self.select.mouseDown = false
end

function RICHERTEXT:HasSelection()
    return self.select.hasSelection
end

function RICHERTEXT:ScreenToCanvas( x, y )
    local sPanel = self.scrollPanel

    local px, py = sPanel:LocalToScreen( 0, 0 )
    local sx, sy = sPanel:GetSize()
    local rMousePos = { x = x - px, y = y - py }

    local csx, csy = sPanel:GetCanvas():GetSize()
    local vBar = sPanel:GetVBar()
    local scrollProp = vBar.Scroll / vBar.CanvasSize
    rMousePos.y = rMousePos.y + math.max( 0, scrollProp * ( csy - sy ) )
    return rMousePos.x, rMousePos.y
end

function RICHERTEXT:GetLineRaw( lineIdx )
    local line = self.lines[lineIdx]
    if not line then return "" end
    local str = ""
    for k = 1, #line do
        str = str .. line[k].rawText
    end
    return str
end

function RICHERTEXT:CharIdxToChar( lineIdx, charIdx )
    local line = self.lines[lineIdx]
    if not line then return nil end
    local char = { line = lineIdx, element = 1 }
    for k = 1, #line do
        local element = line[k]
        if element.rawTextIdx >= charIdx then break end
        char.element = k
    end
    char.char = charIdx - line[char.element].rawTextIdx
    return char
end

function RICHERTEXT:GetSelectedText()
    if not self.select.hasSelection then return nil end
    local s, e = orderChars( self.select.startChar, self.select.endChar )
    local txt = ""
    for l = s.line, e.line do
        local line = self.lines[l]

        local lineTxt = self:GetLineRaw( l )
        local sChar, eChar = 1, #lineTxt

        if l == s.line then
            if not isLabel( line[s.element] ) and s.char == 2 then
                sChar = line[s.element].rawTextIdx + #line[s.element].rawText
            else
                sChar = line[s.element].rawTextIdx + s.char - 1
            end
        end
        if l == e.line then

            local element = line[e.element]
            if isLabel( element ) then
                eChar = element.rawTextIdx + math.min( e.char, #element:GetText() ) - 1 -- This might be wrong, i think it should be .rawText not GetText() TODO
            else
                eChar = element.rawTextIdx + #element.rawText - 1
            end
        end
        txt = txt .. string.sub( lineTxt, sChar, eChar )
    end
    return txt
end

function RICHERTEXT:getCharacter( x, y )
    local lineNum = math.floor( y / self.fontHeight ) + 1 --calc line easily, since all lines are same height
    lineNum = math.Clamp( lineNum, 1, #self.lines - 1 )
    local line = self.lines[lineNum]

    if not line then
        return { line = 1, element = 1, char = 1, pos = { x = x, y = y } }
    end

    while #line == 0 do
        lineNum = lineNum - 1
        line = self.lines[lineNum]
    end

    local elementNum = 1

    x = math.max( x, getFrom( 1, line[1]:GetPos() ) )  -- clamp x to x of first element
    for k = 2, #line do
        local curStart = getFrom( 1, line[k]:GetPos() )
        local prevEnd = getFrom( 1, line[k - 1]:GetPos() ) + getElementSizeX( line[k - 1] )
        if ( prevEnd + curStart ) / 2 >= x then break end --loop through all elements in that line until find a element with posX > x, set elementNum to idx of previous
        elementNum = k
    end
    x = math.max( x, getFrom( 1, line[elementNum]:GetPos() ) ) -- clamp x to x of selected element
    local element = line[elementNum]
    local realChar = 1

    if isLabel( element ) then
        local elementText = element:GetText()
        local lpx, lpy = element:GetPos()
        local lsx, lsy = element:GetTextSize()
        local estimateChar = math.floor( ( ( x - lpx ) / lsx ) * #elementText ) + 1 --estimate the character position assuming all characters are same width (this optimises things)
        estimateChar = math.min( estimateChar, #elementText )

        surface.SetFont( element:GetFont() )

        local minStr = string.sub( elementText, 1, estimateChar - 1 )
        local maxStr = minStr .. elementText[estimateChar]

        realChar = estimateChar
        local lx = x - lpx
        local loopCount = 0
        local loopMax = 100
        while lx < getTextSizeX( minStr, true ) and realChar > 1 and loopCount < loopMax do --underestimate
            realChar = realChar - 1
            minStr = string.sub( elementText, 1, realChar - 1 )
            loopCount = loopCount + 1
        end
        while getTextSizeX( maxStr, true ) < lx and realChar <= #elementText and loopCount < loopMax do --over estimate
            realChar = realChar + 1
            maxStr = string.sub( elementText, 1, realChar )
            loopCount = loopCount + 1
        end --else got it right
        if loopCount == loopMax then
            MsgC( Color( 255, 0, 0 ), "[RicherText] Prevented infinite loop in selection, please report this to Sam\n" )
            MsgC( Color( 255, 0, 0 ), "[RicherText] text = \"" .. elementText .. "\", x = " .. lx .. ", estChar = " .. estimateChar .. ", realChar = " .. realChar .. "\n" )
        end

    else
        local ex, ey = element:GetPos()
        if ( x - ex ) > element:GetWide() / 2 then
            realChar = 2
        end
    end
    return { line = lineNum, element = elementNum, char = realChar, pos = { x = x, y = y } }
end

function RICHERTEXT:SetFont( font )
    if not font then return end
    self.innerFont = font
    self:AddLabel()
end

function RICHERTEXT:GetFont()
    return self.innerFont
end

function RICHERTEXT:SetDecorations( bold, italics, underline, strike )
    table.insert( self.log, { type = "decorations", data = { bold, italics, underline, strike } } )
    self.textBold = bold
    self.textItalics = italics
    self.textUnderline = underline
    self.textStrike = strike
    self:AddLabel()
end

function RICHERTEXT:GetAllowDecorations()
    return self.allowDecorations
end

function RICHERTEXT:SetAllowDecorations( v )
    self.allowDecorations = v
end

function RICHERTEXT:SetVerticalScrollbarEnabled( draw )
    self.scrollPanel:SetScrollbarEnabled( draw )
end

function RICHERTEXT:AddLine()
    self.offset.y = self.offset.y + self.fontHeight -- Set offset to start of next line
    self.offset.x = 0
    table.insert( self.linesYs, { top = self.offset.y, bottom = self.offset.y + self.fontHeight } )
    table.insert( self.lines, {} ) -- Add empty line to lines stack

    if #self.lines > self.maxLines then
        local offset = 0
        while( #self.lines > self.maxLines ) do
            for k, v in pairs( self.lines[1] ) do
                v:Remove()
            end
            table.remove( self.lines, 1 )
            offset = offset + ( self.linesYs[1].bottom - self.linesYs[1].top )
            table.remove( self.linesYs, 1 )
        end
        self.yRemoved = self.linesYs[1].top
        for k, line in pairs( self.lines ) do
            for i, el in pairs( line ) do
                local x, y = el:GetPos()
                el:SetPos( x, y - offset )
            end
        end
    end

    if self.NewLine then
        self.NewLine( self.lines[#self.lines], #self.lines ) -- Call newLine event
    end
end

function RICHERTEXT:PrepNewElement()
    local line = self.lines[#self.lines]
    local lastElement = line[#line]
    if lastElement then
        if #lastElement.rawText == 0 and isLabel( lastElement ) then -- If it has no rawText (aka is empty, so created to be used for next input)
            lastElement:Remove() -- just fuckin delete its entire existance
            table.remove( line, #line )
            lastElement = line[#line] -- update to new lastElement
        else
            self.offset.x = self.offset.x + getElementSizeX( lastElement ) -- Update offsetX using the size of the element
        end
    end

    if lastElement then
        return lastElement.rawTextIdx + #lastElement.rawText
    else
        return 1
    end
end

function RICHERTEXT:UpdateLineHeight()
    local l = #self.lines
    local line = self.lines[l]
    local lastEl = line[#line]
    local h = lastEl:GetTall()
    local yData = self.linesYs[l]
    if ( yData.bottom - yData.top ) < h then
        yData.bottom = yData.top + h
    end
end

function RICHERTEXT:MakeClickable( element )
    local rText = self

    element:SetCursor( "hand" )
    local clickVal = self.clickable
    element.isClickable = true
    rText.lastClick = 0
    rText.clickCounter = 1
    --local oldPress = element.OnMousePressed  -- dont rly want old func called tbh
    function element:OnMousePressed( keyCode )
        --oldPress(self, keyCode)
        if keyCode == MOUSE_LEFT then
            if rText.EventHandler then

                if CurTime() - rText.lastClick < 0.2 then
                    rText.clickCounter = rText.clickCounter + 1
                else
                    rText.clickCounter = 1
                end
                rText.lastClick = CurTime()

                local tName = "RICHERTEXT_elementClickTimer"
                if not timer.Exists( tName ) then
                    timer.Create( tName, 0.2, 1, function()
                        if rText.clickCounter == 1 then
                            rText:EventHandler( "LeftClick", clickVal )
                        elseif rText.clickCounter == 2 then
                            rText:EventHandler( "DoubleClick", clickVal )
                        end
                    end )
                end
            end
        elseif keyCode == MOUSE_RIGHT then
            if rText.EventHandler then
                local m = DermaMenu()
                local dontOpen = rText:EventHandler( "RightClickPreMenu", clickVal, m )

                rText:createContextMenu( true, m )

                dontOpen = dontOpen or rText:EventHandler( "RightClick", clickVal, m )
                if not dontOpen then
                    m:Open()
                end
            else
                rText:createContextMenu()
            end
        end
    end
end

function RICHERTEXT:GetLabelFont()
    local newFont = self.innerFont
    if not self:GetAllowDecorations() then return newFont end
    if not self.doFormatting then return newFont end
    if self.textBold then
        newFont = newFont .. "_bold"
    end
    if self.textItalics then
        newFont = newFont .. "_italics"
    end
    return newFont
end

local function addLabelPaint( label )
    function label:PaintOver( _w, h )
        local w = self:GetTextSize()
        local tCol = self:GetTextColor()
        local thickness = self.textBold and 2 or 1
        if self.textUnderline then
            surface.SetDrawColor( Color( 0, 0, 0, tCol.a ) )
            surface.DrawRect( 1, h - thickness, w, thickness )
            surface.SetDrawColor( tCol )
            surface.DrawRect( 0, h - thickness - 1, w, thickness )
        end
        if self.textStrike then
            surface.SetDrawColor( Color( 0, 0, 0, tCol.a ) )
            surface.DrawRect( 1, h / 2 + 1, w, thickness )
            surface.SetDrawColor( tCol )
            surface.DrawRect( 0, h / 2, w, thickness )
        end
    end
end

function RICHERTEXT:AddLabel()
    local line = self.lines[#self.lines] -- Get last line
    local idx = self:PrepNewElement()

    local label = vgui.Create( "DLabel", self.scrollPanel:GetCanvas() ) -- Make a fokin label
    label:SetFont( self:GetLabelFont() )
    if self.doFormatting then
        label.textUnderline = self.textUnderline
        label.textStrike = self.textStrike
        label.textBold = self.textBold
        addLabelPaint( label )
    end
    label:SetTextColor( table.Copy( self.textColor ) )
    label:SetText( "" )
    label.rawText = ""
    label.rawTextIdx = idx
    label:SetPos( 5 + self.offset.x, self.offset.y - self.yRemoved )
    label:SetSize( self:GetWide() - self.offset.x - 40, self.fontHeight )
    label:SetMouseInputEnabled( true )
    label:MoveToFront()

    function label:SetDoRender( v )
        if self.showText == v then return end
        self.showText = v
        if v then
            local text = self.text or self:GetText()
            if text[1] == "#" then text = "#" .. text end

            self:SetText( text )
        else
            self.text = self:GetText()
            self:SetText( "" )
        end
    end

    self:setClickEvents( label ) -- Set its events (right click menu and text select events)

    if self.clickable then -- handle all the click events, Right calls the event handler, Left works out if its single or double click, then calls handler
        self:MakeClickable( label )
    end

    if self.NewElement then
        self:NewElement( label, #self.lines ) -- Call the new element func
    end

    table.insert( line, label ) -- pop new label in line stack
    local scrollBar = self.scrollPanel:GetVBar()
    if scrollBar.Scroll >= scrollBar.CanvasSize - 1 then -- If current scroll at bottom, update for new message
        self:scrollToBottom()
    end

    self:UpdateLineHeight()
    return label
end

function RICHERTEXT:scrollToBottom( noAnim )
    if not self:IsReady() then return end
    local id = "richTextScrollBottom - " .. self.id
    if timer.Exists( id ) then timer.Remove( id ) end

    if noAnim then
        local bar = self.scrollPanel:GetVBar()
        self:InvalidateLayout( true )
        self.scrollPanel:GetCanvas():InvalidateLayout( true )
        local offset = self.scrollPanel:GetCanvas():GetTall() - self.scrollPanel:GetTall()
        bar:SetScroll( offset )

        return
    end


    timer.Create( id, 0.1, 1, function()
        if not self.scrollPanel then return end
        local bar = self.scrollPanel:GetVBar()
        self.scrollPanel:GetCanvas():InvalidateLayout( true ) -- Even with the delay, it may not have resized itself
        bar:AnimateTo( self.scrollPanel:GetCanvas():GetTall(), 0.2 )
    end )
end

function RICHERTEXT:IsReady()
    return self.ready and self.lines
end

function RICHERTEXT:addNewLines( txt ) -- Goes through big bit of text, puts in new lines when needed to avoid overspill. returns table of lines and "\n"s
    local line = self.lines[#self.lines] or {}
    local lastElement = line[#line]

    local offsetX = self.offset.x

    if lastElement then
        offsetX = offsetX + getElementSizeX( lastElement )
    end

    local limitX = self:GetWide() - 50
    local data = string.Explode( " ", txt )
    local out = {}
    surface.SetFont( self.innerFont )
    local k = 1
    local loopLimit = 200
    while k <= #data and loopLimit > 0 do
        loopLimit = loopLimit - 1
        local word = data[k] .. ( k == #data and "" or " " )
        local sizeX = getFrom( 1, surface.GetTextSize( word ) )
        if offsetX + sizeX > limitX then
            if not isNewLineObj( out[#out] ) and offsetX > 0 then
                table.insert( out, { isNewLine = true } )
                k = k - 1
                offsetX = 0
            else
                -- 20 = guess for minimum characters needed to fill a whole line. to save a little performance
                for l = 20, #word do
                    local str = string.Left( word, l )
                    local sizeX = getFrom( 1, surface.GetTextSize( str ) )
                    if offsetX + sizeX > limitX - 10 then
                        table.insert( out, string.Left( word, l - 1 ) )
                        table.insert( out, { isNewLine = true } )
                        data[k] = string.Right( word, #word - l + 1 )
                        k = k - 1
                        offsetX = 0
                        break
                    end
                end
            end
        else
            table.insert( out, word )
            offsetX = offsetX + sizeX
        end
        k = k + 1
    end
    local nlPoses = {}
    local pCounter = 1
    for k, v in pairs( out ) do
        if isNewLineObj( v ) then
            table.insert( nlPoses, pCounter )
            out[k] = "\n"
        end
        pCounter = pCounter + #out[k]
    end
    return table.concat( out, "" ), nlPoses
end


function RICHERTEXT:AppendText( txt, noLog ) --Deals with the tumour that is tabs before passing to AppendTextNoTabs
    if not noLog then
        table.insert( self.log, { type = "text", data = { txt } } )
    end
    local tabChunks = string.Explode( "\t", txt )
    for k = 1, #tabChunks do
        local chunk = tabChunks[k]
        if k == #tabChunks then
            if #chunk ~= 0 then
                self:AppendTextNoTab( chunk )
            end
            return
        end

        self:AppendTextNoTab( chunk .. "\t" )

        if k == #tabChunks then return end --dont add tab for last chunk

        local line = self.lines[#self.lines]
        local lastElement = line[#line]
        if lastElement then
            self.offset.x = self.offset.x + getElementSizeX( lastElement ) -- Push offset to end of line if its not empty
        end

        local modVal = ( self.offset.x / self.tabSize ) % 1 -- Find out how far through a tab we are
        if modVal > 0.9 or modVal < 0.01 then
            self.offset.x = self.offset.x + self.tabSize -- If very close to end or basically at the start, add an extra tab. 
        end
        self.offset.x = ( math.ceil( self.offset.x / self.tabSize ) * self.tabSize ) -- Push current offset value up to next multiple of tabSize

        if lastElement then
            self.offset.x = self.offset.x - getElementSizeX( lastElement ) -- This will be added back when AddLabel is called
        end
        self:AddLabel()
    end

end

function RICHERTEXT:AppendTextNoTab( txt ) --This func cannot handle tabs
    txt, nlPoses = self:addNewLines( txt )
    local line = self.lines[#self.lines]
    if #line == 0 or not isLabel( line[#line] ) then
        self:AddLabel()
    end
    local curText = ""
    for k = 1, #txt do
        local char = txt[k]

        if char == "\n" then
            local lastElement = line[#line] -- This will exist due to previous AddLabel in this func
            if not isLabel( lastElement ) then
                self:AddLabel()
                lastElement = line[#line]
            end
            local tmpText = lastElement:GetText() .. string.Replace( curText, "\t", "" ) -- Should a tab have made its way in here, get rid of it! Then append to labels text
            if tmpText[1] == "#" then tmpText = "#" .. tmpText end --dLabels remove the first character if its a hash, so add in new one to counter that

            lastElement:SetText( tmpText ) -- Update label
            lastElement.rawText = lastElement.rawText .. curText -- Update label's raw text

            if not table.HasValue( nlPoses, k ) then
                lastElement.rawText = lastElement.rawText .. "\n"
            end

            self:AddLine()

            if k ~= #txt then -- If not at the end of the input
                line = self.lines[#self.lines] -- Update line var to newly created line
                self:AddLabel() -- Give it a starting label
            end
            curText = "" -- Reset curText buffer
        else --Add character to curText buffer until reach a newline char
            curText = curText .. char
        end
    end
    if #curText > 0 then -- If no newline at end, buffer will still have text
        local lastElement = line[#line]
        if not isLabel( lastElement ) then
            self:AddLabel()
            lastElement = line[#line]
        end
        local tmpText = lastElement:GetText() .. string.Replace( curText, "\t", "" )
        if tmpText[1] == "#" then tmpText = "#" .. tmpText end --dLabels remove the first character if its a hash, so add in new one to counter that

        lastElement:SetText( tmpText )
        lastElement.rawText = lastElement.rawText .. curText -- Basically do the shit from the start of new line 
    end
end
function RICHERTEXT:InsertColorChange( r, g, b, a )
    table.insert( self.log, { type = "col", data = { r, g, b, a } } )
    if not self.doFormatting then return end
    if IsColor( r ) then
        self.textColor = r
    else
        self.textColor = Color( r, g, b, a )
    end

    self:AddLabel()
end
function RICHERTEXT:InsertClickableTextStart( sigVal )
    table.insert( self.log, { type = "clickStart", data = { sigVal } } )
    if not self.doFormatting then return end
    self.clickable = sigVal
    self:AddLabel()
end
function RICHERTEXT:InsertClickableTextEnd()
    table.insert( self.log, { type = "clickEnd", data = {} } )
    if not self.doFormatting then return end
    self.clickable = nil
    self:AddLabel()
end

function RICHERTEXT:PerformLayout()
    local w, h = self:GetSize()
    self.scrollToBottomBtn:SetPos( w - 60, h - 32 )
end

function RICHERTEXT:Paint( w, h ) end

function RICHERTEXT:AddGraphic( element, rawText )
    if rawText == "" then rawText = "[image]" end

    if element:GetSizeScale() then
        local size = element:GetSizeScale()
        size.x = size.x * self.fontHeight
        size.y = size.y * self.fontHeight
        element:SetSize( size.x, size.y )
    end

    local imagePadding = 2

    local limitX = self:GetWide() - 60
    local w, h = element:GetWide(), element:GetTall()
    local line = self.lines[#self.lines]

    element.rawTextIdx = self:PrepNewElement()
    element.rawText = rawText

    if h > self.fontHeight then -- Image has own line
        if #line > 0 then
            self:AddLine()
            line = self.lines[#self.lines]
        end

        table.insert( line, element ) -- pop new element on line stack

        element:SetPos( 5 + imagePadding + self.offset.x, self.offset.y - self.yRemoved )
        self.linesYs[#self.linesYs].bottom = self.linesYs[#self.linesYs].bottom + ( h - self.fontHeight )
        local newLines = math.ceil( h / self.fontHeight ) - 1
        for k = 1, newLines do
            self:AddLine()
        end
    else
        if self.offset.x + w > limitX then
            self:AddLine()
        end

        line = self.lines[#self.lines]

        element:SetPos( 5 + imagePadding + self.offset.x, self.offset.y - self.yRemoved )

        self.offset.x = self.offset.x + ( imagePadding * 2 )
        table.insert( line, element ) -- pop new element in line stack
    end

    element:SetMouseInputEnabled( true )
    element:MoveToFront()
    self:setClickEvents( element )

    if self.clickable then
        self:MakeClickable( element )
    end

    if self.NewElement then
        self:NewElement( element, #self.lines ) -- Call the new element func
    end

    local scrollBar = self.scrollPanel:GetVBar()
    if scrollBar.Scroll >= scrollBar.CanvasSize - 1 then -- If current scroll at bottom, update for new message
        self:scrollToBottom()
    end

    element:SetTooltip( rawText[#rawText] == "\n" and string.sub( rawText, 1, #rawText - 1 ) or rawText )

    table.insert( self.graphics, element )

    if #self.lines[#self.lines] > 0 then
        self:UpdateLineHeight()
    end
    return element
end

function RICHERTEXT:AddImage( ... )
    table.insert( self.log, { type = "image", data = { ... } } )
    return self:CreateGraphic( "image", ... )
end

function RICHERTEXT:AddGif( ... )
    table.insert( self.log, { type = "gif", data = { ... } } )
    if not self.showGifs then
        self:AppendText( self.log[#self.log].data[2], true )
        return
    end
    return self:CreateGraphic( "gif", ... )
end

function RICHERTEXT:CreateGraphic( t, path, text, sizeX, sizeY, imOffsetX, imOffsetY, imSizeX, imSizeY )
    if not self.doFormatting or not self.showGraphics then
        self:AppendText( text, true )
        return
    end
    local g = vgui.Create( "DRicherTextGraphic", self.scrollPanel:GetCanvas() )
    g:SetType( t )
    g:SetSizeScale( sizeX, sizeY )
    g:SetPath( path )
    if imOffsetX then
        g:SetSubImage( imOffsetX, imOffsetY, imSizeX, imSizeY )
    end
    self:AddGraphic( g, text )
    return g
end

vgui.Register( "DRicherText", RICHERTEXT, "Panel" )
