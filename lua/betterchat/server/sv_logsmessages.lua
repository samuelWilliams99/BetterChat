function chatBox.sendLog(channelType, channelName, ...)
    chatBox.sendLogConsole(channelName, ...)
    chatBox.sendLogPlayers(channelType, channelName, ...)
end

function chatBox.sendLogConsole(channel, ...)
    local data = {}
    for k, v in ipairs({...}) do
        if type(v) == "string" then
            table.insert(data, v)
        elseif type(v) == "Player" then
            table.insert(data, v:GetName() .. "~[" .. v:SteamID() .. "]")
        elseif type(v) == "table" and v.text then
            table.insert(data, v.text)
        elseif type(v) == "Entity" and v:EntIndex() == 0 then
            table.insert(data, "(Server)")
        end
    end
    local consoleStr = "<" .. channel .. "> " .. table.concat(data, "")
    print(consoleStr)
    local logFile = GetConVar("ulx_logfile")
    if logFile:GetBool() then
        ulx.logString(consoleStr)
    end
end

function chatBox.sendLogPlayers(channelType, channel, ...)
    local plys = {}
    for k, v in pairs(player.GetAll()) do
        if chatBox.getAllowed(v, "bc_chatlogs") then
            table.insert(plys, v)
        end
    end
    net.Start("BC_LM")
    net.WriteUInt(channelType, 4)
    net.WriteString(channel)
    net.WriteTable({...})
    net.Send(plys)
end

hook.Add("PlayerSay", "BC_LogTeam", function( ply, text, t )
    if t then
        chatBox.sendLog(chatBox.channelTypes.TEAM, "Team - " .. team.GetName(ply:Team()), ply, ": ", text )
    end
end, HOOK_MONITOR_HIGH)