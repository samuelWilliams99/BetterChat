bc.fontManager = bc.fontManager or {}
local fm = bc.fontManager

fm.fonts = fm.fonts or {}

fm.systemFont = system.IsLinux() and "DejaVu Sans" or "Tahoma"

fm.fontFamilies = {
    fm.systemFont,
    "Lucida Console",
    "Arial",
    "Verdana",
    "Times New Roman",
    "Courier New",
    "Courier",
    "Garamond",
}

local function spaceToUnderscore( txt )
    return string.Replace( txt, " ", "_" )
end

local function getFontNameHash( fontData )
    return "bc_generatedFont_" .. spaceToUnderscore( fontData.family )
        .. "_" .. fontData.size ..
        ( fontData.bold and "_b" or "" ) .. ( fontData.italics and "_i" or "" )
end

local function makeFont( name, data )
    data.antialias = false
    data.shadow = true
    data.extended = true
    data.weight = data.weight or 500

    surface.CreateFont( name, data )
end

local function makeFonts( name, data )
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

            makeFont( newName, newData )
        end
    end
end

function fm.getFont( fontData )
    local hash = getFontNameHash( fontData )
    if fm.fonts[hash] then
        return hash
    end

    makeFonts( hash, {
        font = fontData.family,
        size = fontData.size,
        weight = 500 + ( fontData.bold and 200 or 0 ),
        italics = fontData.italics
    } )

    fm.fonts[hash] = fontData
    return hash
end

function fm.getGlobalFontData( noSize )
    return {
        family = bc.settings.getValue( "fontFamily" ),
        size = noSize and 21 or bc.settings.getValue( "fontSize" ),
        bold = bc.settings.getValue( "fontBold" ),
    }
end

function fm.applyFontChange()
    GetConVar( "bc_fontFamily" ):SetString( bc.settings.getValue( "fontFamilyTemp" ) )
    GetConVar( "bc_fontSize" ):SetInt( bc.settings.getValue( "fontSizeTemp" ) )
    GetConVar( "bc_fontBold" ):SetBool( bc.settings.getValue( "fontBoldTemp" ) )
    GetConVar( "bc_fontScaleEntry" ):SetBool( bc.settings.getValue( "fontScaleEntryTemp" ) )
    if bc.base.enabled then
        bc.base.disable()
        bc.base.enable()
    end
end

concommand.Add( "bc_applyfont", fm.applyFontChange )
concommand.Add( "bc_resetfont", function()
    GetConVar( "bc_fontFamilyTemp" ):Revert()
    GetConVar( "bc_fontSizeTemp" ):Revert()
    GetConVar( "bc_fontBoldTemp" ):Revert()
    GetConVar( "bc_fontScaleEntryTemp" ):Revert()
    fm.applyFontChange()
end )

hook.Add( "bc_preInitPanels", "BC_setFontValues", function()
    GetConVar( "bc_fontFamilyTemp" ):SetString( GetConVar( "bc_fontFamily" ):GetString() )
    GetConVar( "bc_fontSizeTemp" ):SetInt( GetConVar( "bc_fontSize" ):GetInt() )
    GetConVar( "bc_fontBoldTemp" ):SetBool( GetConVar( "bc_fontBold" ):GetBool() )
    GetConVar( "bc_fontScaleEntryTemp" ):SetBool( GetConVar( "bc_fontScaleEntry" ):GetBool() )
end )

function fm.getGlobalFont( noSize )
    return fm.getFont( fm.getGlobalFontData( noSize ) )
end

function fm.getChannelFont( channel )
    if channel.useOverrideFont then
        return fm.getFont( {
            family = channel.fontFamily,
            size = channel.fontSize,
            bold = channel.fontBold
        } )
    else
        return fm.getGlobalFont()
    end
end

function fm.updateChannelFont( channel, noReload )
    local oldFont = channel.font
    channel.font = fm.getChannelFont( channel )

    if channel.font ~= oldFont then
        local txt = bc.channels.panels[channel.name].text
        if not txt or not IsValid( txt ) then return end

        txt:SetFont( channel.font )

        if not noReload then
            txt:Reload()
        else
            txt:Clear()
        end
    end
end

makeFont( "bc_default", {
    font = fm.systemFont,
    size = 21,
} )

makeFont( "bc_monospace", {
    font = "Lucida Console",
    size = 15,
} )

makeFont( "bc_monospaceSmall", {
    font = "Lucida Console",
    size = 10,
} )
