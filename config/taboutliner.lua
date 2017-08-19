
local lousy = require("lousy")
local pickle = lousy.pickle
local chrome = require("chrome")
local json = require("json")

local window = require("window")
local webview = require("webview")
local session = require("session")

local modes = require("modes")
local new_mode, get_mode = modes.new_mode, modes.get_mode

local taborder = require("taborder")

-- TODO move these somewhere else (factor out with binds.lua)
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


local next_uid = 1
local tabtree = {}

lousy.signal.setup(tabtree, true)

local _M = {}

local tab_by_view = setmetatable({}, { __mode = "k" })
local tab_by_uid = setmetatable({}, { __mode = "v" })
local tab_already_created = nil

-- i/o
tabs_file = luakit.data_dir .. "/tabs"

local function rm(file)
  luakit.spawn(string.format("rm %q", file))
end

function save_tab_list(tabs)
  local saved_tabs = {}
  for i, tab in ipairs(tabs) do
    saved_tabs[i] = {
      uid = tab.uid,
      title = tab.title,
      uri = tab.uri,
      collapsed = tab.collapsed,
      typ = tab.typ,
      favicon = tab.favicon,
      children = save_tab_list(tab.children)
    }
    if tab.comment then
      saved_tabs[i].comment = tab.comment
    end
  end
  return saved_tabs
end

function save()
  local tabs = save_tab_list(tabtree)

  local data = {
    tabs = tabs,
    next_uid = next_uid
  }

  if #tabs > 0 then
    local fh = io.open(tabs_file, "wb")
    fh = io.open(tabs_file .. ".json", "wb")
    fh:write(json.encode(data))
    io.close(fh)
  else
    rm(tabs_file)
  end
  print("Tabtree saved.")
end

function restore_tab_list(tabs, parent)
  for _, tab in ipairs(tabs) do
    tab_by_uid[tab.uid] = tab
    tab.view = nil
    tab.parent = parent
    if tab.uid >= next_uid then
      next_uid = tab.uid + 1
    end
    if tab.typ == nil then
      tab.typ = "tab"
    end
    if tab.children then
      restore_tab_list(tab.children, tab)
    else
      tab.children = {}
    end
  end
end

function load()
  if not os.exists(tabs_file) then return end
  local fh = io.open(tabs_file .. ".json", "rb")
  local data = json.decode(fh:read("*all"))
  io.close(fh)
  next_uid = data.next_uid
  restore_tab_list(data.tabs)
  for _, tab in ipairs(data.tabs) do
    table.insert(tabtree, tab)
  end
end

session.add_signal(
  "save", function (state)
    save()
    for w, data in pairs(state) do
      for ti, view in pairs(w.tabs.children) do
        local tab = tab_by_view[view]
        if tab then
          assert(data.open[ti].ti == ti)
          data.open[ti].tab_uid = tab.uid
          print("saving known tab:", view.title, tab.uid)
        else
          print("Unknown tab!", view.title, view.uri)
        end
      end
    end
end)

session.add_signal(
  "restore", function (state)
    load()

    for w, data in pairs(state) do
      for ti, view in pairs(w.tabs.children) do
        local uid = data.open[ti].tab_uid
        if uid == nil then
          print("Tab not known in tabtree!", view.uri)
          init_webview(view)
          table.insert(tabtree, tab_by_view[view])
        else
          local tab = tab_by_uid[uid]
          if tab then
            print("Loading known tab:", uid, view.uri, "is", tab.title)
            tab.view = view
            tab_by_view[view] = tab
          else
            print("Tab uid not found:", uid)
            init_webview(view)
            table.insert(tabtree, tab_by_view[view])
          end
        end
      end
    end

    tabtree.emit_signal("changed")

    -- now listen for new tabs
    webview.add_signal("init", init_webview)
end)

-- json import
function trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function import(file)
  print("import '" .. file .. "'")
  if not os.exists(file) then
    print("doesn't exist")
    return
  end
  local fh = io.open(file, "r")
  local data_json = fh:read("*all");
  io.close(fh)
  local tabs = json.decode(data_json)
  restore_tab_list(tabs)
  for _, tab in ipairs(tabs) do
    table.insert(tabtree, tab)
  end
  tabtree.emit_signal("changed")
end

-- keep track of new tabs
function create_tab(view)
  local tab = {
    typ = "tab",
    title = view.title or view.uri or "??",
    uri = view.uri,
    view = view,
    uid = next_uid,
    collapsed = false,
    parent = nil,
    children = {}
  }
  next_uid = next_uid + 1
  tab_by_uid[tab.uid] = tab
  return tab
end

function update_title(tab)
  local v = tab.view
  if not v then
    return
  end
  if v.uri == "luakit://taboutliner" then
    tab.title = "Tab outliner"
  else
    tab.title = v.title or v.uri or "??"
  end
end

function init_webview(view)
  local tab = nil
  if tab_already_created then
    tab = tab_already_created
    tab.view = view
  else
    tab = create_tab(view)
  end

  tab_by_view[view] = tab

  if tab_already_created then
    tab_already_created = nil
    tabtree.emit_signal("changed")
  end

  view:add_signal(
    "property::title", function (v)
      local oldtitle = tab.title
      update_title(tab)
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
      update_title(tab)
      if olduri == tab.uri then
        return
      end
      print("uri changed from", olduri, "to", tab.uri)
      tabtree.emit_signal("changed")
  end)
end

function find(haystack, needle)
  for i, elem in ipairs(haystack) do
    if elem == needle then
      return i
    end
  end
  return nil
end

function find_tab_index(w, new_tab, subtree_to_search)
  -- print("search subtree:", subtree_to_search and subtree_to_search.title)
  local max_index = 0
  local subtrees
  if subtree_to_search then
    if subtree_to_search == new_tab then
      return nil, true
    end
    subtrees = subtree_to_search.children
    local v = subtree_to_search.view
    if v and webview.window(v) == w then
      local i = find(w.tabs.children, v)
      if i then
        max_index = i
      end
      -- print("found an active tab with index", i, "max_index now", max_index)
    end
  else
    subtrees = tabtree
  end
  for i, subtree in ipairs(subtrees) do
    index, found = find_tab_index(w, new_tab, subtree)
    if index ~= nil and index > max_index then
      max_index = index
    end
    -- print("max_index now", max_index)
    if found then
      -- print("found the target, returning", max_index)
      return max_index, true
    end
  end
  -- print("didn't find the target yet, returning", max_index)
  return max_index, false
end

function _M.taborder_next_sibling (w, newview)
  -- should open after all children of the current tab, as a sibling
  print("taborder_next_sibling", w, newview)
  local current_tab = tab_by_view[w.view]
  local new_tab = tab_by_view[newview]
  if not new_tab then
    print("unknown tab!")
    return taborder.last(w, newview)
  end

  new_tab.parent = current_tab and current_tab.parent
  if new_tab.parent then
    table.insert(new_tab.parent.children, new_tab)
  else
    table.insert(tabtree, new_tab)
  end

  tabtree.emit_signal("changed")

  local index, _ = find_tab_index(w, new_tab)
  return index + 1
end

function _M.taborder_below (w, newview)
  -- should open below the current tab, as last child
  print("taborder_below", w, newview)
  local current_tab = tab_by_view[w.view]
  local new_tab = tab_by_view[newview]
  if not new_tab then
    print("unknown tab!")
    return taborder.last(w, newview)
  end

  new_tab.parent = current_tab
  table.insert(current_tab.children, new_tab)



  tabtree.emit_signal("changed")

  local index, _ = find_tab_index(w, new_tab)
  return index + 1
end

taborder.default = _M.taborder_next_sibling
taborder.default_bg = _M.taborder_below

function archive_tab(tab)
  print("archive tab", tab.title)
  local parent_list
  if tab.parent then
    parent_list = tab.parent.children
  else
    parent_list = tabtree
  end
  local index = find(parent_list, tab)
  table.remove(parent_list, index)
  tabtree.emit_signal("changed")
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
  if tab.typ ~= "tab" then
    return
  end
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
    tab_already_created = tab
    local view = webview.new({ private = false })
    w:attach_tab(view, true, function (ww)
                   local index, _ = find_tab_index(ww, tab)
                   return index + 1
    end)
    -- TODO: session state
    webview.set_location(view, { uri = tab.uri })
    w.win.screen = w.win.screen
    w.win.urgency_hint = true
  end
end

function toggle_collapse(uid)
  local tab = tab_by_uid[uid]
  tab.collapsed = not tab.collapsed
  tabtree.emit_signal("changed")
end

function build_tree_for_js(tabs)
  local js_tabs = {}
  for _, tab in ipairs(tabs) do
    local js_tab = {
      title = tab.title,
      uri = tab.uri,
      active = (tab.view ~= nil),
      uid = tab.uid,
      collapsed = tab.collapsed == true,
      children = build_tree_for_js(tab.children),
      comment = tab.comment
    }
    table.insert(js_tabs, js_tab)
  end
  return js_tabs
end

-- Functions that are also callable from javascript go here.
export_funcs = {
  print = function (_, s)
    print("TABOUTLINER JS: " .. s)
  end,
  getData = function (view, s)
    return {
      tabs = build_tree_for_js(tabtree)
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
    key({}, "Tab", "Collapse/uncollapse", function (w)
        w.view:eval_js("getSelected()", { callback = toggle_collapse })
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
    cmd("taboutliner_import", "Import taboutliner tree from json", function (w, a)
          import(trim(a))
    end)
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
