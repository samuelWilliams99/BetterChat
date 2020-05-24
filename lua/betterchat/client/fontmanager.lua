bc.fontManager = bc.fontManager or {}
local fm = bc.fontManager

fm.fonts = fm.fonts or {}

local function makeFonts( name, data )
    name = "BC_" .. name
    data.antialias = false
    data.shadow = true
    data.extended = true

    for boldI = 0, 1 do
        local bold = boldI == 1
        for italicsI = 0, 1 do
            local italics = italicsI == 1
            local newName = name
            local newData = table.Copy( data )
            if bold then
                newName = newName .. "_bold"
                newData.weight = newData.weight + 200
            end
            if italics then
                newName = newName .. "_italics"
                newData.italic = true
            end
            surface.CreateFont( newName, newData )
        end
    end
end

makeFonts( "default", {
    font = system.IsLinux() and "DejaVu Sans" or "Tahoma",
    size = 21,
    weight = 500,
} )

makeFonts( "defaultLarge", {
    font = system.IsLinux() and "DejaVu Sans" or "Tahoma",
    size = 26,
    weight = 500,
} )

makeFonts( "monospace", {
    font = "Lucida Console",
    size = 15,
    weight = 500,
} )

makeFonts( "monospaceLarge", {
    font = "Lucida Console",
    size = 22,
    weight = 500,
} )

makeFonts( "monospaceSmall", {
    font = "Lucida Console",
    size = 10,
    weight = 300,
} )