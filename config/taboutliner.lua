
local lousy = require("lousy")
local chrome = require("chrome")

local window = require("window")
local webview = require("webview")

local modes = require("modes")
local new_mode, get_mode = modes.new_mode, modes.get_mode

local next_uid = 1

-- Add binds to a mode
local function add_binds(mode, binds, before)
  assert(binds and type(binds) == "table", "invalid binds table type: " .. type(binds))
  mode = type(mode) ~= "table" and {mode} or mode
  for _, m in ipairs(mode) do
    local mdata = get_mode(m)
    if mdata and before then
      mdata.binds = join(binds, mdata.binds or {})
    elseif mdata then
      mdata.binds = mdata.binds or {}
      for _, b in ipairs(binds) do table.insert(mdata.binds, b) end
    else
      new_mode(m, { binds = binds })
    end
  end
end

-- Add commands to command mode
local function add_cmds(cmds, before)
  add_binds("command", cmds, before)
end

local tabtree = {}

lousy.signal.setup(tabtree, true)

local _M = {}

local tab_by_view = setmetatable({}, { __mode = "k" })
local tab_by_uid = setmetatable({}, { __mode = "v" })
local tab_being_created = nil

-- keep track of new tabs
function init_webview(view)
  local tab = nil
  if tab_being_created then
    tab = tab_being_created
    tab.view = view
    tab_being_created = nil
  else
    tab = {
      title = view.title or view.uri or "??",
      uri = view.uri,
      view = view,
      uid = next_uid
    }
    next_uid = next_uid + 1
    tab_by_uid[tab.uid] = tab
    table.insert(tabtree, tab)
  end
  tab_by_view[view] = tab
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
  view:add_signal(
    "property::uri", function (v)
      local olduri = v.uri
      tab.uri = v.uri
      if olduri == tab.uri then
        return
      end
      print("uri changed from", olduri, "to", tab.uri)
      tabtree.emit_signal("changed")
  end)
  tabtree.emit_signal("changed")
end
webview.add_signal("init", init_webview)

function archive_tab(tab)
  print("archive tab", tab.title)
end

function on_tab_close(w, view)
  local tab = tab_by_view[view]
  if tab.view then
    archive_tab(tab)
  end
end

window.add_signal(
  "init", function (w)
    w:add_signal("close-tab", on_tab_close)
end)

chrome_name = "taboutliner"
chrome_uri = string.format("luakit://%s", chrome_name)

function focus_or_activate_uid(uid)
  local tab = tab_by_uid[uid]
  if tab.view then
    local w = webview.window(tab.view)
    local tabindex = nil
    for i, some_view in ipairs(w.tabs.children) do
      if some_view == tab.view then
        tabindex = i
      end
    end
    if tabindex then
      w.tabs:switch(tabindex)
    end
    -- make the window focus
    w.win.screen = w.win.screen
    w.win.urgency_hint = true
  else
    -- find window to put it in (TODO)
    local w = nil
    for _, some_window in pairs(window.bywidget) do
      if #some_window.tabs.children > 1 or some_window.tabs[1].uri ~= "luakit://taboutliner" then
        w = some_window
      end
    end
    if not w then
      -- TODO: create window if we don't find one
      print("TODO")
      return
    end

    -- let the webview init handler know this is supposed to be that tab
    tab_being_created = tab
    local view = webview.new({ private = false })
    -- TODO: find the right place to put the tab
    w:attach_tab(view, true, function (ww)
                   return #ww.tabs.children + 1
    end)
    -- TODO: session state
    webview.set_location(view, { uri = tab.uri })
    w.win.screen = w.win.screen
    w.win.urgency_hint = true
  end
end

-- Functions that are also callable from javascript go here.
export_funcs = {
  log = function (_, s)
    print("TABOUTLINER JS: " .. s)
  end,
  getData = function (view, s)
    local tabs = {}
    for _, tab in ipairs(tabtree) do
      table.insert(tabs, { title = tab.title, active = (tab.view ~= nil), uid = tab.uid })
    end
    return {
      tabs = tabs
    }
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

local key, buf, but, any = lousy.bind.key, lousy.bind.buf, lousy.bind.but, lousy.bind.any

add_binds(
  "taboutliner",
  {
    key({}, "Escape", "No escape!", function (w)
        print("You won't escape me!")
    end),
    key({}, "e", "Select previous", function (w)
        w.view:eval_js("previous()", { no_return = true })
    end),
    key({}, "n", "Select next", function (w)
        w.view:eval_js("next()", { no_return = true })
    end),
    key({}, "Return", "Focus or open tab", function (w)
        w.view:eval_js("getSelected()", { callback = focus_or_activate_uid })
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

function _M.deactivate_tab(w, view)
  view = view or w.view
  tab_by_view[view].view = nil
  tabtree.emit_signal("changed")
  w:close_tab(view)
end

function _M.archive_tab(w, view)
  view = view or w.view
  w:close_tab(view)
end

return _M
