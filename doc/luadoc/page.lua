--- Web process counterpart to the webview widget
--
-- The page is the web process counterpart to the webview widget; for each
-- webview widget created on the UI process, a corresponding page instance
-- is created in a web process.
--
-- @class page
-- @author Aidan Holm
-- @copyright 2016 Aidan Holm

--- Emitted when the DOM document of the page has finished loading.
-- @signal document-loaded

--- Emitted before every HTTP request is sent. By connecting to this signal
-- one can redirect the request to a different URI, or block the request
-- entirely. It is also possible to modify the HTTP headers sent with the
-- request.
--
-- #### Redirecting a request to a different URI
--
-- To redirect a request to a different URI, return the new URI from your
-- signal handler.
--
--     page:add_signal("send-request", function ()
-- 		return "http://0.0.0.0/" -- Redirect everything to localhost
-- 	end)
--
-- #### Blocking a request
--
-- To block a request, return `false`.
--
--     page:add_signal("send-request", function (_, uri)
-- 	    if uri:match("^http:") then
-- 		    return false -- Block all http:// requests
-- 		end
-- 	end)
--
-- #### Modifying HTTP headers
--
-- To modify the HTTP headers sent with the request, modify the `headers` table.
--
--     page:add_signal("send-request", function (_, _, headers)
-- 	    headers.Referer = nil -- Don't send Referer header
-- 	end)
-- @signal send-request
-- @tparam page The page.
-- @tparam string uri The URI of the request.
-- @tparam table headers The HTTP headers of the request.
-- @treturn string|false A redirect URI, or `false` to block the request.

--- The current active URI of the page.
-- @property uri
-- @type string
-- @readonly

--- @property document
-- The `dom_document` currently loaded in the page.
-- @type dom_document
-- @readonly

--- Unique ID number associated with the web page.
--
-- A page and webview widget pair will always have the same ID; this is
-- useful for coordinating Lua accross processes.
-- @property id
-- @type integer
-- @readonly

--- Synchronously run a string of JavaScript code in the context of the
-- webview. The JavaScript will run even if the `enable_javascript`
-- property of the webview is `false`, as it is run within a separate
-- JavaScript script world.
--
-- If the `options` parameter is provided, only the `source` key is
-- recognized; if provided, it should be a string to use in error messages.
--
-- @method eval_js
-- @tparam string script The JavaScript string to evaluate.
-- @tparam[opt] table options Additional arguments.
-- @default `{}`

-- vim: et:sw=4:ts=8:sts=4:tw=80
