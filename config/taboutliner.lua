local binds = require("binds")
local menu_binds = binds.menu_binds
local add_binds, add_cmds = binds.add_binds, binds.add_cmds

local lousy = require("lousy")
local chrome = require("chrome")

local key, buf, but = lousy.bind.key, lousy.bind.buf, lousy.bind.but

local window = require("window")
local webview = require("webview")

local modes = require("modes")
local new_mode = modes.new_mode

local tabtree = {}

lousy.signal.setup(tabtree, true)

local tab_by_view = setmetatable({}, { __mode = "k" })

-- keep track of new tabs
function init_webview(view)
  local tab = {
    title = view.title or view.uri or "??",
    active = true,
    view = view
  }
  tab_by_view[view] = tab
  table.insert(tabtree, tab)
  view:add_signal(
    "property::title", function (v)
      local oldtitle = tab.title
      if v.uri == "luakit://taboutliner" then
        tab.title = "Tab outliner"
      else
        tab.title = v.title or v.uri or "??"
      end
      if oldtitle == tab.title then
        return
      end
      print("title changed from", oldtitle, "to", tab.title)
      tabtree.emit_signal("changed")
  end)
end
webview.add_signal("init", init_webview)

function on_tab_close(w, view)
  tab_by_view[view].active = false
  tabtree.emit_signal("changed")
end

window.add_signal(
  "init", function (w)
    w:add_signal("close-tab", on_tab_close)
end)

chrome_name = "taboutliner"
chrome_uri = string.format("luakit://%s", chrome_name)

-- Functions that are also callable from javascript go here.
export_funcs = {
  log = function (_, s)
    print("TABOUTLINER JS: " .. s)
  end,
  getData = function (_, s)
    local tabs = {}
    for _, tab in ipairs(tabtree) do
      table.insert(tabs, { title = tab.title, active = tab.active })
    end
    return tabs
  end
}

function update_tabtree(view)
  view:eval_js("window.update()", {})
end

chrome.add(
  chrome_name,
  function (view, meta)
    print("taboutliner request:", meta.path)
    if meta.path ~= "" then
      local mime = "application/javascript"
      return lousy.load("config/taboutliner/" .. meta.path), mime
    else
      -- TODO: cleanup
      tabtree.add_signal(
        "changed", function ()
          update_tabtree(view)
      end)
      return lousy.load("config/taboutliner/index.html")
    end
  end,
  function (view)
    local w = webview.window(view)
    -- update_tabtree(view)
    w:set_mode("taboutliner")
  end, export_funcs
)

new_mode(
  "taboutliner", "Mode for the taboutliner window", {
    enter = function (w)
      print("taboutliner enter")
      w:set_prompt("-- TABOUTLINER --")
    end,

    leave = function (w)
      print("taboutliner leave")
    end,

    -- Don't exit mode when clicking outside of form fields
    reset_on_focus = false,
    -- Don't exit mode on navigation
    reset_on_navigation = false,
})

add_binds(
  "taboutliner",
  {
    key({}, "Escape", "No escape!", function (w)
        print("You won't escape me!")
    end)
})

function open_taboutliner_window(w)
  ww = window.new({"luakit://taboutliner"})
  ww.win.urgency_hint = true
  ww.tablist.visible = false
end

local cmd = lousy.bind.cmd
add_cmds({
    cmd("taboutliner", "Open taboutliner window", open_taboutliner_window),
})
