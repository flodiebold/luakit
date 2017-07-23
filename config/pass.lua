-- pass2luakit
--
-- use `pass` from luakit to paste a password from the store in a password field
--
-- This piece of source code is licensed under GNU GPLv2.0

pass2luakit = {}

pass2luakit.pass_executeable = '/usr/bin/pass';
pass2luakit.pass_args = '';

-- Call pass with this arg string
function pass2luakit.pass_call(args)
    local call = pass2luakit.pass_executeable .. ' ' .. pass2luakit.pass_args
    return call .. ' ' .. args
end

-- Main function, bind this to your preffered key combo
function pass2luakit.call(w)
    local passname = w.view:eval_js(string.format([[
        var e = document.activeElement;
        if (e && e.type && 'password' == e.type) {
            e.value;
        } else {
            'false';
        }
    ]]))

    if passname == 'false' then
        -- Field is not a password field, is it?
        w:set_prompt("[pass2luakit] -- Not a password field")
        return nil
    end

    local exit, stdout, stderr = luakit.spawn_sync(pass2luakit.pass_call(passname));

    local field = w.view:eval_js(string.format([[
        var e = document.activeElement;
        if (e && e.type && 'password' == e.type) {
            e.value = '%s';
            'true';
        } else {
            'false';
        }
    ]], stdout:gsub("\n", "")))

    if 'false' ~= s then
        w:set_prompt("[pass2luakit] -- Inserted password")
    else
        w:set_prompt("[pass2luakit] -- Insert FAILED")
    end
end
