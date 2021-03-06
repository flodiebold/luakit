--- lousy.uri library.
--
-- URI parsing functions
--
-- @module lousy.uri
-- @copyright 2011 Mason Larobina <mason.larobina@gmail.com>

-- Get luakit environment
local util = require "lousy.util"
local uri_encode = luakit.uri_encode
local uri_decode = luakit.uri_decode

local _M = {}

local opts_metatable = {
    __tostring = function (opts)
        local ret, done = {}, {}
        -- Get opt order from metatable
        local mt = getmetatable(opts)
        -- Add original args first in order
        if mt and mt.order then
            for _, k in ipairs(mt.order) do
                local v = opts[k]
                if v and v ~= "" then
                    table.insert(ret, uri_encode(k) .. "=" .. uri_encode(v))
                    done[k] = true
                end
            end
        end
        -- Add new args
        for k, v in pairs(opts) do
            if not done[k] and v ~= "" then
                table.insert(ret, uri_encode(k) .. "=" .. uri_encode(v))
            end
        end
        -- Join query opts
        return table.concat(ret, "&")
    end,
    __add = function (op1, op2)
        assert(type(op1) == "table" and type(op2) == "table",
            "non-table operands")
        local ret = util.table.copy(op1)
        for k, v in pairs(op2) do
            ret[k] = v
        end
        return ret
    end,
    __sub = function (op1, op2)
        assert(type(op1) == "table" and type(op2) == "table",
            "non-table operands")
        local ret = util.table.copy(op1)
        for _, k in ipairs(op2) do
            ret[k] = nil
        end
        return ret
    end,
}

--- Parse the query component of a URI and return it as a table.
-- @tparam string query The query component of a URI.
-- @treturn table The parsed table of query options.
function _M.parse_query(query)
    local opts, order = {}, {}
    string.gsub(query or "", "&*([^&=]+)=([^&]+)", function (k, v)
        opts[k] = uri_decode(v)
        table.insert(order, k)
    end)
    -- Put order table in opts metatable
    local mt = util.table.clone(opts_metatable)
    mt.order = order
    return setmetatable(opts, mt)
end

-- Allowed URI table properties
local uri_allowed = { scheme = true, user = true, password = true, port = true,
    host = true, path = true, query = true, fragment = true, opts = true }

-- URI table metatable
local uri_metatable = {
    __tostring = function (uri)
        local t = util.table.clone(uri)
        t.query = tostring(t.opts)
        return soup.uri_tostring(t)
    end,
    __add = function (op1, op2)
        assert(type(op1) == "table" and type(op2) == "table",
            "non-table operands")
        local ret = util.table.copy(op1)
        for k, v in pairs(op2) do
            assert(uri_allowed[k], "invalid property: " .. k)
            if k == "query" and type(v) == "string" then
                ret.opts = _M.parse_query(v)
            else
                ret[k] = v
            end
        end
        return ret
    end,
}

--- Parse a URI string and return a URI table.
-- @tparam string uri The URI as a string.
-- @treturn table The URI as a table.
function _M.parse(uri)
    -- Get uri table
    uri = soup.parse_uri(uri)
    if not uri then return end
    -- Parse uri.query and set uri.opts
    uri.opts = _M.parse_query(uri.query)
    uri.query = nil
    return setmetatable(uri, uri_metatable)
end

--- Duplicate a URI table.
-- @tparam table uri The URI as a table.
-- @treturn table A new copy of the URI table.
function _M.copy(uri)
    assert(type(uri) == "table", "not a table")
    return _M.parse(tostring(uri))
end

return _M

-- vim: et:sw=4:ts=8:sts=4:tw=80
