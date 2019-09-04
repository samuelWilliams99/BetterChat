chatBox.colors = {
	printYellow = Color( 255, 222, 102 ),
	printBlue = Color( 137, 222, 255 ),
	yellow = Color(254,254,0),
	red = Color(255,0,0),
	ulx = Color(152,212,255),
	command = Color(190,190,190),
	private = Color(200,95,170),
	purple = Color(75,0,130),
	white = color_white,
	tabText = Color(200,200,200,255),
	hTabText = Color(220,220,220,255),
	admin = Color(0,255,0),
	green = Color(0,255,0),
	group = Color(0,255,255),
}

function chatBox.PrintTable(tab, indent, done) -- Seems some assholes like overloading PrintTable, disgustang.
    done = done or {tab}
    indent = indent or 0
    local indentStr = string.rep("\t", indent)
    for k, v in pairs(tab) do
        if type(v) == "table" and not table.HasValue(done, v) then
            table.insert(done, v)
            print(indentStr .. tostring(k) .. ":")
            chatBox.PrintTable(v, indent + 1, done)
        else
            print(indentStr .. tostring(k) .. "\t=\t" .. tostring(v))
        end
    end
end

function chatBox.canRunULX(cmd, target, ply)
	if not ULib then return false end
	local ply = ply or LocalPlayer()

	if ply:SteamID() == "STEAM_0:0:0" or ply:SteamID() == "STEAM_0:0:00000000" then return true end

	local canRun, tag = ULib.ucl.query(ply, cmd) --Get global can run
	if not canRun then return false end --If  they cant, return no
	if not target then return true end --If no target specified, just return if they can run the func at all
	if not tag then
		success, tag = pcall(function() return ULib.ucl.getGroupCanTarget(ply:GetUserGroup()) end) --if no player specific tag, get tag from their rank
	end
	if not success then return false end -- Edge case when rank doesnt exist but previous had permissions (e.g. SA -> unassigned)
	if not tag then return true end --if still no tag, player has no restriction, return yes

	local users = ULib.getUsers(tag, true, ply) --get users our player can target
	return table.HasValue(users, target)
end

if SERVER then

	function chatBox.getRunnableULXCommands(ply)
		local sayCmds = ULib.sayCmds
		local allCmds = {}
		for cmd, data in pairs(sayCmds) do
			if data.__cmd and chatBox.canRunULX(data.__cmd, nil, ply) and cmd[1] == "!" then
				table.insert(allCmds, string.sub(cmd, 0, #cmd-1))
			end
		end

		return allCmds
	end

end

function lerpCol(a, b, l)
    return Color(a.r * (1-l) + b.r * l, a.g * (1-l) + b.g * l, a.b * (1-l) + b.b * l,a.a * (1-l) + b.a * l)
end

function getFrom(idx, ...)
	local d = {...}
	return d[idx]
end

function chatBox.isLetter(char)
	return string.byte(char) >= string.byte("A") and string.byte(char) <= string.byte("z")
end

function getChatTextLength(txt)
	local _, count = string.gsub(txt, "\t", "")
	return #txt + count * 3
end

function chatBox.shortenChatText(txt, len)
	local a = 1000
	while getChatTextLength(txt) > len and a > 0 do
		a = a - 1
		txt = string.sub(txt, 1, -2)
	end
	if a == 0 then print("loop") end
	return txt
end

if CLIENT then
	surface.CreateFont( "chatFont_18", {
		font = "Verdana",
		size = 17,
		weight = 700,
		antialias = false,
		shadow = true,
		extended = true,
	} )

	surface.CreateFont( "Monospace", {
		font = "Lucida Console",
		size = 15,
		weight = 500,
		antialias = false,
		shadow = false,
		extended = true,
	} )

	local blur = Material( "pp/blurscreen" )

	function chatBox.blur( panel, layers, density, alpha, w, h )
		-- Its a scientifically proven fact that blur improves a script
		-- It's also been proven that writing scripts lazily is generally not a good thing. --Script modified to support custom size
		local x, y = panel:LocalToScreen(0, 0)
		if not w then
			w, h = panel:GetSize()
		end

		surface.SetDrawColor( 255, 255, 255, alpha )
		surface.SetMaterial( blur )

		for i = 1, 3 do
			blur:SetFloat( "$blur", ( i / layers ) * density )
			blur:Recompute()

			render.UpdateScreenEffectTexture()
			surface.DrawTexturedRectUV( 0, 0, w, h, x/ScrW(), y/ScrH(), (x+w)/ScrW(), (y+h)/ScrH() )
		end
	end

	function chatBox.isColor(tab)
		return type(tab) == "table" and tab.r and type(tab.r) == "number" and tab.g and type(tab.g) == "number" and tab.b and type(tab.b) == "number" and tab.a and type(tab.a) == "number" and #table.GetKeys(tab) == 4
	end

	function chatBox.goodMsgC( ... )
		local data = {...}

		local lastCol = Color(255,255,255)
		local k = 1
		while k <= #data do
			local v = data[k]
			if type(v) == "Player" then
				table.remove(data, k)
				table.insert(data, k, lastCol)
				table.insert(data, k, v:Nick())
				table.insert(data, k, team.GetColor(v:Team()))
				k = k + 2
			elseif type(v) == "table" then
				if v.formatter or v.isController then
					if v.formatter and (v.type == "image" or v.type == "clickable") then
						if v.colour then v.color = v.colour end
						data[k] = v.text
						if v.type == "clickable" and v.color then
							table.insert(data, k, v.color)
							table.insert(data, k+2, lastCol)
							k = k + 2
						end
					else
						table.remove(data, k)
						k = k - 1
					end
				else
					lastCol = v
				end
			end
			k = k + 1
		end
		data[#data + 1] = "\n"
		MsgC(unpack(data))
	end

	chatBox.materials = chatBox.materials or {}

	chatBox.materials.mats = {
		["icons/cog.png"] = Material("icons/cog.png"),
		["icon16/cog.png"] = Material("icon16/cog.png"),
		["icons/menu.png"] = Material("icons/menu.png"),
		["icons/groupBW.png"] = Material("icons/groupBW.png"),
		["icons/emojiButton.png"] = Material("icons/emojiButton.png"),
	}
	function chatBox.materials.getMaterial(str)
		if not chatBox.materials.mats[str] then
			chatBox.materials.mats[str] = Material(str)
		end
		return chatBox.materials.mats[str]
	end
end