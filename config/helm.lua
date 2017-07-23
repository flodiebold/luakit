-- TODO: 'fuzzy' matching
-- TODO: highlight matched parts
-- TODO: multiple actions using tab
-- TODO: allow adding new element
-- TODO: sort by most recently used

local _M = {}

local lousy = require("lousy")
local binds = require("binds")
local menu_binds = binds.menu_binds
local add_binds, add_cmds = binds.add_binds, binds.add_cmds
local new_mode = require("modes").new_mode

lousy.signal.setup(_M, true)

local data = {
  "ousohut",
  "oddourtskemgiart",
  "tstourwouktmxeth",
  "foduthsoeto",
  "owgohtshteno"
}

new_mode("helm", {
           enter = function (w)
             local rows = {}
             for uid, text in ipairs(data) do
               table.insert(rows, { text, uid = uid })
             end
             w.menu:build(rows)
             w.menu:move_down()
             local prompt = "> "
             w:set_prompt(prompt)
             w:set_input("")
           end,

           changed = function (w, input)
             local rows = {}
             for uid, text in ipairs(data) do
               if string.find(text, input, 1, true) then
                 table.insert(rows, { text, uid = uid })
               end
             end
             w.menu:build(rows)
             w.menu:move_down()
           end,

           activate = function (w, input)
             local selected = w.menu:get()
             if selected then
               w:notify("you selected: " .. selected[1])
             end
           end,

           leave = function (w)
             w:notify("whooo...")
             w.menu:hide()
           end
})

local key = lousy.bind.key
add_binds("helm", menu_binds)

function _M.init(data, callback)
  -- TODO: init with data and callback; how to integrate?
end


local cmd = lousy.bind.cmd
add_cmds({
    cmd("helmtest", "Helm test command", function (w)
          w:set_mode("helm")
    end)
})

return _M
