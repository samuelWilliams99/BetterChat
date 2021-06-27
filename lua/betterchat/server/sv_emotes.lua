bc.emotes = bc.emotes or {}
local e = bc.emotes

function e.isAllowed( ply )
    return bc.settings.isAllowed( ply, "manageEmotes" )
end