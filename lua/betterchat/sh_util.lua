chatBox.colors = { 
    printYellow = Color( 255, 222, 102 ), 
    printBlue = Color( 137, 222, 255 ), 
    yellow = Color( 254, 254, 0 ), 
    red = Color( 255, 0, 0 ), 
    ulx = Color( 152, 212, 255 ), 
    command = Color( 190, 190, 190 ), 
    private = Color( 200, 95, 170 ), 
    purple = Color( 75, 0, 130 ), 
    white = color_white, 
    tabText = Color( 200, 200, 200, 255 ), 
    hTabText = Color( 220, 220, 220, 255 ), 
    admin = Color( 0, 255, 0 ), 
    green = Color( 0, 255, 0 ), 
    group = Color( 0, 255, 255 ), 
}

-- Adding strings is nice
debug.getmetatable( "a" ).__add = function( a, b ) return a .. b end

-- Explode a string using a pattern and return a table of { text = explodedText, sep = seperator after it }
function string.ExplodeWithSep( pattern, str )
    local startPos = nil
    
    local stopCount = 0
    
    local out = {}
    repeat 
        stopCount = stopCount + 1
        local startPos, endPos = string.find( str, pattern )
        if startPos ~= nil then
            local text = string.sub( str, 0, startPos - 1 )
            local sep = string.sub( str, startPos, endPos )
            table.insert( out, { text = text, sep = sep } )
            str = string.sub( str, endPos + 1 )
        end
    until startPos == nil or stopCount > 20
    table.insert( out, { text = str, sep = nil } )
    return out
end

function chatBox.PrintTable( tab, indent, done ) -- Seems some assholes like overloading PrintTable, disgustang.
    done = done or { tab }
    indent = indent or 0
    local indentStr = string.rep( "\t", indent )
    for k, v in pairs( tab ) do
        if type( v ) == "table" and not table.HasValue( done, v ) then
            table.insert( done, v )
            print( indentStr .. tostring( k ) .. ":" )
            chatBox.PrintTable( v, indent + 1, done )
        else
            print( indentStr .. tostring( k ) .. "\t=\t" .. tostring( v ) )
        end
    end
end

-- Can a player run a command on a person (via ULX)
function chatBox.canRunULX( cmd, target, ply )
    if not ULib then return false end
    local ply = ply or LocalPlayer()

    if ply:SteamID() == "STEAM_0:0:0" or ply:SteamID() == "STEAM_0:0:00000000" then return true end

    local canRun, tag = ULib.ucl.query( ply, cmd ) --Get global can run
    if not canRun then return false end --If  they cant, return no
    if not target then return true end --If no target specified, just return if they can run the func at all
    if not tag then
        success, tag = pcall( function() return ULib.ucl.getGroupCanTarget( ply:GetUserGroup() ) end ) --if no player specific tag, get tag from their rank
    end
    if not success then return false end -- Edge case when rank doesnt exist but previous had permissions (e.g. SA -> unassigned)
    if not tag then return true end --if still no tag, player has no restriction, return yes

    local users = ULib.getUsers( tag, true, ply ) --get users our player can target
    return table.HasValue( users or {}, target )
end

function chatBox.padString( str, chars, padChar, post )
    padChar = padChar or " "
    str = tostring( str )
    if post then
        return str .. string.rep( padChar, math.max( 0, chars - #str ) )
    else
        return string.rep( padChar, math.max( 0, chars - #str ) ) .. str
    end
end

if SERVER then

    function chatBox.getRunnableULXCommands( ply )
        local sayCmds = ULib.sayCmds
        local allCmds = {}
        for cmd, data in pairs( sayCmds ) do
            if data.__cmd and chatBox.canRunULX( data.__cmd, nil, ply ) and cmd[1] == "!" then
                table.insert( allCmds, string.sub( cmd, 0, #cmd - 1 ) )
            end
        end

        return allCmds
    end

end

function lerpCol( a, b, l )
    return Color( a.r * ( 1 - l ) + b.r * l, a.g * ( 1 - l ) + b.g * l, a.b * ( 1 - l ) + b.b * l, a.a * ( 1 - l ) + b.a * l )
end

-- Inline unpacking for single arg
function getFrom( idx, ... )
    local d = { ... }
    return d[idx]
end

function chatBox.isLetter( char )
    return string.byte( char ) >= string.byte( "A" ) and string.byte( char ) <= string.byte( "z" )
end

-- Length treating tabs as 4 spaces
function getChatTextLength( txt )
    local _, count = string.gsub( txt, "\t", "" )
    return #txt + count * 3
end

function chatBox.shortenChatText( txt, len )
    local a = 1000
    while getChatTextLength( txt ) > len and a > 0 do
        a = a - 1
        txt = string.sub( txt, 1, -2 )
    end
    if a == 0 then print( "Shouldn't happen, pls message BetterChat creator if you see this :)" ) end
    return txt
end

-- Url finding (https://stackoverflow.com/questions/23590304/finding-a-url-in-a-string-lua-pattern)

-- all characters allowed to be inside URL according to RFC 3986 but without
-- comma, semicolon, apostrophe, equal, brackets and parentheses
-- (as they are used frequently as URL separators)

local domains = [[.ac.ad.ae.aero.af.ag.ai.al.am.an.ao.aq.ar.arpa.as.asia.at.au
   .aw.ax.az.ba.bb.bd.be.bf.bg.bh.bi.biz.bj.bm.bn.bo.br.bs.bt.bv.bw.by.bz.ca
   .cat.cc.cd.cf.cg.ch.ci.ck.cl.cm.cn.co.com.coop.cr.cs.cu.cv.cx.cy.cz.dd.de
   .dj.dk.dm.do.dz.ec.edu.ee.eg.eh.er.es.et.eu.fi.firm.fj.fk.fm.fo.fr.fx.ga
   .gb.gd.ge.gf.gh.gi.gl.gm.gn.gov.gp.gq.gr.gs.gt.gu.gw.gy.hk.hm.hn.hr.ht.hu
   .id.ie.il.im.in.info.int.io.iq.ir.is.it.je.jm.jo.jobs.jp.ke.kg.kh.ki.km.kn
   .kp.kr.kw.ky.kz.la.lb.lc.li.lk.lr.ls.lt.lu.lv.ly.ma.mc.md.me.mg.mh.mil.mk
   .ml.mm.mn.mo.mobi.mp.mq.mr.ms.mt.mu.museum.mv.mw.mx.my.mz.na.name.nato.nc
   .ne.net.nf.ng.ni.nl.no.nom.np.nr.nt.nu.nz.om.org.pa.pe.pf.pg.ph.pk.pl.pm
   .pn.post.pr.pro.ps.pt.pw.py.qa.re.ro.ru.rw.sa.sb.sc.sd.se.sg.sh.si.sj.sk
   .sl.sm.sn.so.sr.ss.st.store.su.sv.sy.sz.tc.td.tel.tf.tg.th.tj.tk.tl.tm.tn
   .to.tp.tr.travel.tt.tv.tw.tz.ua.ug.uk.um.us.uy.va.vc.ve.vg.vi.vn.vu.web.wf
   .ws.xxx.ye.yt.yu.za.zm.zr.zw]]
local tlds = {}
for tld in string.gmatch( domains, "%w+" ) do
   tlds[tld] = true
end
local function max4( a, b, c, d ) return math.max( a + 0, b + 0, c + 0, d + 0 ) end
local protocols = { [""] = 0, ["http://"] = 0, ["https://"] = 0, ["ftp://"] = 0 }

function chatBox.getNextUrl( inputStr )
    local pos_start, pos_end, url, prot, subd, tld, colon, port, slash, path = 
    string.find( inputStr, "(([%w_.~!*:@&+$/?%%#-]-)(%w[-.%w]*%.)(%w+)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))" )
    if pos_start and protocols[prot:lower()] == ( 1 - #slash ) * #path and not string.find( subd, "%W%W" )
    and ( colon == "" or port ~= "" and port + 0 < 65536 )
    and ( tlds[tld:lower()] or string.find( tld, "^%d+$" ) and string.find( subd, "^%d+%.%d+%.%d+%.$" )
    and max4( tld, string.match( subd, "^(%d+)%.(%d+)%.(%d+)%.$" ) ) < 256 ) then
        return pos_start, pos_end, string.sub( inputStr, pos_start, pos_end )
    end
    

    pos_start, pos_end, url, prot, dom, colon, port, slash, path = 
        string.find( inputStr, "((%f[%w]%a+://)(%w[-.%w]*)(:?)(%d*)(/?)([%w_.~!*:@&+$/?%%#=-]*))" )
    if pos_start and not string.find( dom .. ".", "%W%W" )
    and protocols[prot:lower()] == ( 1 - #slash ) * #path
    and ( colon == "" or port ~= "" and port + 0 < 65536 ) then
        return pos_start, pos_end, string.sub( inputStr, pos_start, pos_end )
    end
    return nil
end
-- End urlFinding

if CLIENT then

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

    makeFonts( "Default", { 
        font = "Tahoma", 
        size = 21, 
        weight = 500, 
    } )

    makeFonts( "DefaultLarge", { 
        font = "Tahoma", 
        size = 26, 
        weight = 500, 
    } )

    makeFonts( "Monospace", { 
        font = "Lucida Console", 
        size = 15, 
        weight = 500, 
    } )

    makeFonts( "MonospaceLarge", { 
        font = "Lucida Console", 
        size = 22, 
        weight = 500, 
    } )

    makeFonts( "MonospaceSmall", { 
        font = "Lucida Console", 
        size = 10, 
        weight = 300, 
    } )

    local blur = Material( "pp/blurscreen" )

    function chatBox.blur( panel, layers, density, alpha, w, h )
        -- Its a scientifically proven fact that blur improves a script
        -- It's also been proven that writing scripts lazily is generally not a good thing. --Script modified to support custom size
        local x, y = panel:LocalToScreen( 0, 0 )
        if not w then
            w, h = panel:GetSize()
        end

        surface.SetDrawColor( 255, 255, 255, alpha )
        surface.SetMaterial( blur )

        for i = 1, 3 do
            blur:SetFloat( "$blur", ( i / layers ) * density )
            blur:Recompute()

            render.UpdateScreenEffectTexture()
            surface.DrawTexturedRectUV( 0, 0, w, h, x / ScrW(), y / ScrH(), ( x + w ) / ScrW(), ( y + h ) / ScrH() )
        end
    end

    function chatBox.isColor( tab )
        return type( tab ) == "table" and tab.r and type( tab.r ) == "number" and tab.g and type( tab.g ) == "number" and tab.b and type( tab.b ) == "number" and tab.a and type( tab.a ) == "number" and #table.GetKeys( tab ) == 4
    end

    function chatBox.goodMsgC( ... )
        local data = { ... }

        local lastCol = Color( 255, 255, 255 )
        local k = 1
        while k <= #data do
            local v = data[k]
            if type( v ) == "Player" then
                table.remove( data, k )
                table.insert( data, k, lastCol )
                table.insert( data, k, v:Nick() )
                table.insert( data, k, team.GetColor( v:Team() ) )
                k = k + 2
            elseif type( v ) == "table" then
                if v.formatter or v.isController then
                    if v.formatter and ( v.type == "image" or v.type == "clickable" ) then
                        if v.colour then v.color = v.colour end
                        data[k] = v.text
                        if v.type == "clickable" and v.color then
                            table.insert( data, k, v.color )
                            table.insert( data, k + 2, lastCol )
                            k = k + 2
                        end
                    else
                        table.remove( data, k )
                        k = k - 1
                    end
                elseif v.isConsole then
                    table.remove( data, k )
                    table.insert( data, k, lastCol )
                    table.insert( data, k, "Console" )
                    table.insert( data, k, chatBox.colors.printBlue )
                    k = k + 2
                else
                    lastCol = v
                end
            end
            k = k + 1
        end
        data[#data + 1] = "\n"
        MsgC( unpack( data ) )
    end

    chatBox.materials = chatBox.materials or {}

    chatBox.materials.mats = { 
        ["icons/cog.png"] = Material( "icons/cog.png" ), 
        ["icon16/cog.png"] = Material( "icon16/cog.png" ), 
        ["icons/menu.png"] = Material( "icons/menu.png" ), 
        ["icons/groupBW.png"] = Material( "icons/groupBW.png" ), 
        ["icons/emojiButton.png"] = Material( "icons/emojiButton.png" ), 
    }
    function chatBox.materials.getMaterial( str )
        if not chatBox.materials.mats[str] then
            chatBox.materials.mats[str] = Material( str )
        end
        return chatBox.materials.mats[str]
    end
end