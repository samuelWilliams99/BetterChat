chatHelper = {}
ch = chatHelper

-- Pull out basic ops into functions
function chatHelper.add( a, b )
    return a + b
end

function chatHelper.sub( a, b )
    return a - b
end

function chatHelper.mul( a, b )
    return a * b
end

function chatHelper.div( a, b )
    return a / b
end

function chatHelper.lAnd( a, b )
    return a and b
end

function chatHelper.lOr( a, b )
    return a or b
end

function chatHelper.lNot( x )
    return not x
end

function chatHelper.eq( a, b )
    return a == b
end

function chatHelper.nEq( a, b )
    return a ~= b
end

function chatHelper.compose( a, b )
    return function( ... ) 
        return a( b( ... ) )
    end
end

function chatHelper.rep( x, n )
    return unpack( table.rep( x, n ) )
end

function chatHelper.curry( f, ... )
    local args = { ... }
    return function( ... ) return f( unpack( args ), ... ) end
end

function chatHelper.unCurry( f )
    return function( a, ... ) return f( ... ) end
end

function table.mapSelf( tab, f )
    for k, v in pairs( tab ) do
        tab[k] = f( v )
    end
end

function table.map( tab, f )
    local out = table.Copy( tab )
    table.mapSelf( out, f )
    return out
end

function table.reduce( tab, f, s )
    local total = s
    for k, v in pairs( tab ) do
        total = f( total, v )
    end
    return total
end

function table.sum( tab )
    return table.reduce( tab, chatHelper.add, 0 )
end

function table.product( tab )
    return table.reduce( tab, chatHelper.mul, 1 )
end

function table.all( tab ) 
    return table.reduce( tab, function( a, b )
        return a and b
    end, true )
end

function table.any( tab ) 
    return table.reduce( tab, function( a, b )
        return a or b
    end, false )
end

function table.Repeat( x, n )
    local out = {}
    for k = 1, n do
        table.insert( out, x )
    end
    return out
end

function table.filter( tab, f )
    local out = {}
    for k, v in pairs( tab ) do
        if f( v ) then
            table.insert( tab, v )
        end
    end
    return out
end

table.rep = table.Repeat

function chatHelper.const( x )
    return function() return x end
end

function chatHelper.getFrom( k, ... )
    return ( { ... } )[k]
end

chatHelper.fst = chatHelper.curry( chatHelper.getFrom, 1 )
chatHelper.snd = chatHelper.curry( chatHelper.getFrom, 2 )

function pack( ... )
    return { ... }
end

function asBool( x )
    return x and true or false
end

function printA( ... )
    local d = { ... }
    if #d == 0 then 
        print(nil)
        return
    end
    for k, v in ipairs( d ) do
        if istable( v ) then
            PrintTable( v )
        else
            print( v )
        end
    end
end

p = printA

function chatHelper.indexable( x )
    local s = xpcall( function() return x[1] end, function() end )
    return s
end

local function idxValid( a, b )
    if not a then return false end
    local valid = asBool( string.match(b, "^%a%w-$") )
    return valid
end

function chatHelper.index( tab, idx )
    local idxs = string.Explode( "[./]", idx, true )
    local allValid = table.reduce( idxs, idxValid, true )
    if not allValid then 
        error( "Malformed index " .. idx )
    end

    local poses = {}
    local pos = tab
    for k, v in ipairs( idxs ) do
        if not chatHelper.indexable( pos ) then return nil end
        table.insert( poses, pos )
        pos = pos[v]
    end

    return pos, poses, idxs
end

local hookCounter = 0
function hook.Once( event, f )
    hookCounter = hookCounter + 1
    local id = "HOOKONCE" .. hookCounter
    hook.Add( event, id, function( ... )
        f( ... )
        hook.Remove( event, id )
    end )
end

function hook.When( cond, f )
    hookCounter = hookCounter + 1
    local id = "HOOKWHEN" .. hookCounter
    hook.Add( "Think", id, function()
        if cond() then
            hook.Remove( "Think", id )
            f()
        end
    end )
end

function net.SendEmpty( id, ply )
    net.Start( id )
    if SERVER then
        if ply then
            net.Send( ply )
        else
            net.Broadcast()
        end
    else
        net.SendToServer()
    end
end

function chatHelper.errInfo( str, c )
    local pre = string.sub( str, 1, c )
    local line = chatHelper.snd( string.gsub(pre, "\n", "") ) + 1
    local col = c
    local nextN = string.find( str, "\n" ) - 1
    local lineStr = string.sub( str, 1, nextN )
    for k = c - 1, 1, -1 do
        if str[k] == "\n" then
            col = c - k
            local nextN = string.find( string.sub( str, c + 1 ), "\n" )
            lineStr = string.sub( str, k + 1, nextN and ( nextN + c - 1 ) or #str )
            break
        end
    end
    return "line " .. line .. ", column " .. col .. " (" .. lineStr .. ")"
end

local index = {}
function chatHelper.getProxy( x )
    if type(x) ~= "table" then return x end
    if ( debug.getmetatable( x ) or {} ).__IsProxy then return x end

    local newX = {}
    newX[index] = x
    
    local oldmt = getmetatable( x ) or {}
    local mt = {}
    
    for k, v in pairs( oldmt ) do
        if isfunction( v ) then
            local f_k = k
            mt[k] = function( self, ... ) 
                return oldmt[f_k]( self[index], ... ) 
            end
        else
            mt[k] = oldmt[k]
        end
    end
    
    mt.__index = function( t, k )
        return t[index][k]
    end
    
    mt.__newindex = function( t, k, v )
        t[index][k] = v
    end
    
    mt.__metatable = oldmt
    mt.__pairs = function( tbl )
        return pairs( tbl[index] )
    end
    mt.__ipairs = function( tbl )
        return ipairs( tbl[index] )
    end
    mt.__type = function() return type( x ) end
    mt.__IsProxy = true
    
    debug.setmetatable( newX, mt )
    return newX
end

function chatHelper.splitStringSpecial( str, splitChars, surrChars )
    local surr = nil
    local t = ""
    local out = {}
    surrChars = surrChars or {}
    for k = 1, #str do
        local v = str[k]
        if not surr then
            if surrChars[v] then
                surr = v
                t = t .. v
            else
                if table.HasValue( splitChars, v ) then
                    if #t == 0 then
                        if #out == 0 then
                            table.insert( out, { str = "", split = "" } )
                        end
                        out[#out].split = out[#out].split .. v
                    else
                        table.insert( out, { str = t, split = v } )
                        t = ""
                    end
                else
                    t = t .. v
                end
            end
        else
            t = t .. v
            if v == surrChars[surr] then
                surr = nil
            end
        end
    end

    if #t > 0 then
        table.insert( out, { str = t } )
    end

    return out
end