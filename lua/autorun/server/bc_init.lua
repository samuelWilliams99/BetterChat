AddCSLuaFile( "autorun/client/bc_init.lua" )

resource.AddSingleFile( "materials/icons/cog.png" )
resource.AddSingleFile( "materials/icons/menu.png" )
resource.AddSingleFile( "materials/icons/triple_arrows.png" )
resource.AddSingleFile( "materials/icons/groupbw.png" )
resource.AddSingleFile( "materials/icons/emojibutton.png" )

local files, _ = file.Find( "resource/fonts/*.ttf", "GAME" )
for k, v in pairs( files ) do
    resource.AddFile( "resource/fonts/" .. v )
end

local files, _ = file.Find( "materials/spritesheets/*.vmt", "GAME" )
for k, v in pairs( files ) do
    resource.AddFile( "materials/spritesheets/" .. v )
end

local files, _ = file.Find( "materials/spritesheets/*.png", "GAME" )
for k, v in pairs( files ) do
    resource.AddSingleFile( "materials/spritesheets/" .. v )
end

local function addFiles( dir )
    local files, dirs = file.Find( dir .. "/*", "LUA" )
    if not files then return end
    for k, v in pairs( files ) do
        if string.match( v, "^.+%.lua$" ) then
            AddCSLuaFile( dir .. "/" .. v )
        end
    end
    for k, v in pairs( dirs ) do
        addFiles( dir .. "/" .. v )
    end
end
addFiles( "betterchat" )

include( "betterchat/sh_base.lua" )