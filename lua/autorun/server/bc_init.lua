AddCSLuaFile("autorun/client/bc_init.lua")

resource.AddSingleFile("materials/icons/cog.png")
resource.AddSingleFile("materials/icons/menu.png")
resource.AddSingleFile("materials/icons/triple_arrows.png")
resource.AddSingleFile("materials/icons/groupbw.png")
resource.AddSingleFile("materials/icons/emojibutton.png")

local files, _ = file.Find( "materials/spritesheets/*.vmt", "GAME" )
for k, v in pairs(files) do
	resource.AddFile("materials/spritesheets/" .. v)
end

local files, _ = file.Find( "materials/spritesheets/*.png", "GAME" )
for k, v in pairs(files) do
	resource.AddSingleFile("materials/spritesheets/" .. v)
end

include("betterchat/sh_base.lua")