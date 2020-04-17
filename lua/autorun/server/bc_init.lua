AddCSLuaFile( "autorun/client/bc_init.lua" )

local function runRecurse( dir, ext, f )
    local files, dirs = file.Find( dir .. "/*", "GAME" )
    if not files then return end
    for k, v in pairs( files ) do
        if string.match( v, "^.+%." .. ext .. "$" ) then
            f( dir .. "/" .. v )
        end
    end
    for k, v in pairs( dirs ) do
        runRecurse( dir .. "/" .. v, ext, f )
    end
end

-- AddCSLuaFile Full Path, removes the "lua/" from start of paths, as AddCSLuaFile doesn't like it
local function AddCSLuaFileFP( path )
    AddCSLuaFile( string.sub( path, 5 ) )
end

runRecurse( "lua/betterchat/client", "lua", AddCSLuaFileFP )
runRecurse( "lua/betterchat/shared", "lua", AddCSLuaFileFP )
runRecurse( "materials/icons", "png", resource.AddSingleFile )
runRecurse( "resource/fonts", "ttf", resource.AddFile )
runRecurse( "materials/spritesheets", "vmt", resource.AddFile )
runRecurse( "materials/spritesheets", "png", resource.AddSingleFile )
runRecurse( "materials/spritesheets", "json", resource.AddSingleFile )

include( "betterchat/shared/sh_base.lua" )
