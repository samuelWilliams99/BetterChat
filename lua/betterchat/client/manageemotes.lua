bc.emotes = bc.emotes or {}
local e = bc.emotes

function e.openManager()
    if not bc.settings.isAllowed( "manageEmotes" ) then return end
    
    
end

concommand.Add( "bc_manageEmotes", function()
    bc.emotes.openManager()
end )