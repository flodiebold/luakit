local lousy = require("lousy")
local webview = require("webview")
local globals = require("globals")

default_zoom = 1.5

webview.add_signal(
  "init",
  function (view)
    view:add_signal(
      "load-status",
      function (v, status)
        if status ~= "committed" or v.uri == "about:blank" then return end
        -- get domain
        local domain = lousy.uri.parse(v.uri).host
        -- strip leading www.
        domain = string.match(domain or "", "^www%.(.+)") or domain or "all"
        -- TODO per-domain zoom levels
        v.zoom_level = default_zoom
    end)
  end
)
