-- Standard amesome library
local gears = require("gears")
local awful = require("awful")
require("awful.autofocus")

-- Widget and layout library
local wibox = require("wibox")

-- Theme handling library
local beautiful = require("beautiful")

-- Notification library
local naughty = require("naughty")
local menubar = require("menubar")
local hotkeys_popup = require("awful.hotkeys_popup").widget


-- ERROR HANDLING ------------------------------------------------------------

-- Check if awesome encountered an error during startup and fell back to
-- another config (This code will only ever execute for the fallback config)
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title = "Oops, there were errors during startup!",
        text = awesome.startup_errors
    })
end

-- Handle runtime errors after startup
do
    local in_error = false
    awesome.connect_signal("debug::error", function (err)
        -- Make sure we don't go into an endless error loop
        if in_error then return end
        in_error = true
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, an error happened!",
            text = tostring(err)
        })
        in_error = false
    end)
end

-- VARIABLES -----------------------------------------------------------------

-- Themes define colours, icons, font and wallpapers.
beautiful.init(awful.util.get_themes_dir() .. "default/theme.lua")

-- This is used later as the default terminal and editor to run.
-- terminal = "gnome-terminal"
-- terminal = "xfce4-terminal"
terminal = "termite"

-- Default modkey, the "windows" key.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
awful.layout.layouts = {
    awful.layout.suit.floating,
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.corner.nw,
}


-- HELPER FUNCTIONS -----------------------------------------------------------

local function client_menu_toggle_fn()
    local instance = nil
    return function ()
        if instance and instance.wibox.visible then
            instance:hide()
            instance = nil
        else
            instance = awful.menu.clients({ theme = { width = 250 } })
        end
    end
end

local function toggle_client_minimalized(c)
    if c == client.focus then
        c.minimized = true
    else
        -- Without this, the following
        -- :isvisible() makes no sense
        c.minimized = false
        if not c:isvisible() and c.first_tag then
            c.first_tag:view_only()
        end
        -- This will also un-minimize
        -- the client, if needed
        client.focus = c
        c:raise()
    end
end

local function is_file(filename)
    local file = io.open(filename, "rb")
    if file == nil then
        return false
    end
    file:close()
    return true
end


local function set_wallpaper(s)

    local wallpaper_wide = os.getenv("HOME") .. "/.config/awesome/wallpaper-wide.png"
    local wallpaper_tall = os.getenv("HOME") .. "/.config/awesome/wallpaper-tall.png"

    if not is_file(wallpaper_wide) or not is_file(wallpaper_tall) then
        naughty.notify({
            preset = naughty.config.presets.critical,
            title = "Oops, could not find wallpaper files!",
            screen = mouse.screen,
            text = string.format("File not found: \n %s \n %s", wallpaper_tall, wallpaper_wide)
        })
        wallpaper_wide = beautiful.wallpaper
        wallpaper_tall = beautiful.wallpaper
    end

    local wp
    if screen[s].geometry.height > screen[s].geometry.width then
        wp = wallpaper_tall
    else
        wp = wallpaper_wide
    end

    gears.wallpaper.maximized(wp, s, true)
end

local function output_of(command)
    local process = io.popen(command)
    local output = process:read("*all")
    process:close()
    return output
end

local function battery_status()
    local output = output_of("acpi -b")
    local level = string.match(output, "(%d?%d?%d?)%%")
    if level == nil then
        return "AcpiErr!"
    end
    local mark = "?"
    for status, m in pairs({Charging="▲", Full="●", Discharging="▼"}) do
        if string.find(output, status, 1, true) then
            mark = m
        end
    end
    local retval = mark .. " " .. level
    if tonumber(level) < 11 then
        retval =  '<span color="red">' .. retval .. '</span>'
    end
    return retval
end

local function keyboard_status()
    local output = output_of("setxkbmap -query")
    return string.match(output, "layout: +(..)")
end

local function volume_status()
    local output = output_of("amixer -c 1 get Master")
    local level = string.match(output, "(%d?%d?%d)%%")

    if level == nil then return "AmixerErr!" end

    if string.find(output, "[on]", 1, true) then
        return "♬ " .. level
    end
    return "M " .. level
end

local function statusbar_widget()   -- starts it too!
    local widget = wibox.widget.textbox()
    widget:set_font("Fira Sans 13")
    local function update()
        local markup = string.format("| %s | %s | %s | %s ",
            volume_status(),
            battery_status(),
            keyboard_status(),
            os.date("%a %b %d, %R")
        )
        widget:set_markup(markup)
    end
    update()
    widget.timer = timer({timeout = 1})
    widget.timer:connect_signal("timeout", update)
    widget.timer:start()
    return widget
end

local function focus_previous_client()
    awful.client.focus.history.previous()
    if client.focus then
        client.focus:raise()
    end
end

local function view_tag_only(i)
    local screen = awful.screen.focused()
    local tag = screen.tags[i]
    if tag then
        tag:view_only()
    end
end

local function toggle_tag(i)
    local screen = awful.screen.focused()
    local tag = screen.tags[i]
    if tag then
         awful.tag.viewtoggle(tag)
    end
end

local function move_client_to_tag(i)
    if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
            client.focus:move_to_tag(tag)
        end
    end
end

local function toggle_tag_on_focused(i)
    if client.focus then
        local tag = client.focus.screen.tags[i]
        if tag then
            client.focus:toggle_tag(tag)
        end
    end
end


-- TOP PANEL ------------------------------------------------------------------

-- Set the terminal for applications that require it
menubar.utils.terminal = terminal

-- Re-set wallpaper when a screen's geometry changes (e.g. different resolution)
screen.connect_signal("property::geometry", set_wallpaper)

local taglist_buttons = awful.util.table.join(
    awful.button({}, 1, function(t) t:view_only() end),
    awful.button({}, 3, awful.tag.viewtoggle),
    awful.button({}, 4, function(t) awful.tag.viewnext(t.screen) end),
    awful.button({}, 5, function(t) awful.tag.viewprev(t.screen) end)
)

local tasklist_buttons = awful.util.table.join(
    awful.button({}, 1, toggle_client_minimalized),
    awful.button({}, 3, client_menu_toggle_fn()),
    awful.button({}, 4, function() awful.client.focus.byidx( 1) end),
    awful.button({}, 5, function() awful.client.focus.byidx(-1) end)
)

local layoutbox_buttons = awful.util.table.join(
    awful.button({ }, 1, function () awful.layout.inc( 1) end),
    awful.button({ }, 3, function () awful.layout.inc(-1) end),
    awful.button({ }, 4, function () awful.layout.inc( 1) end),
    awful.button({ }, 5, function () awful.layout.inc(-1) end)
)

local tags = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }
local w_systray   = wibox.widget.systray()
local w_statusbar = statusbar_widget()


awful.screen.connect_for_each_screen(function(s)
    set_wallpaper(s)

    awful.tag(tags, s, awful.layout.layouts[1])

    s.w_promptbox = awful.widget.prompt()
    s.w_layoutbox = awful.widget.layoutbox(s)
    s.w_layoutbox:buttons(layoutbox_buttons)
    s.w_taglist   = awful.widget.taglist(s, awful.widget.taglist.filter.all, taglist_buttons)
    s.w_tasklist  = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, tasklist_buttons)

    s.w_wibox = awful.wibar { position = "top", screen = s }   -- panel

    s.w_wibox:setup {
        layout = wibox.layout.align.horizontal,
        {
            layout = wibox.layout.fixed.horizontal,
            s.w_taglist,
            s.w_promptbox
        },
        s.w_tasklist,
        {
            layout = wibox.layout.fixed.horizontal,
            w_systray,
            w_statusbar,
            s.w_layoutbox
        }
    }
end)


-- KEYS -----------------------------------------------------------------------

local M   = {modkey};
local MC  = {modkey, "Control"}
local MS  = {modkey, "Shift"}
local MCS = {modkey, "Control", "Shift"}

local function key(group, description, speckeys, key, callback)
    return awful.key(speckeys, key, callback, {group=group, description=description})
end

local global_keys = awful.util.table.join(
    --   group       description        keys            callback
    key("awesome",  "show help",        M,   "F1",      hotkeys_popup.show_help),
    key("awesome",  "reload config",    MC,  "r",       awesome.restart),
    key("awesome",  "open prompt",      M,   "r",       function() awful.screen.focused().w_promptbox:run() end),

    -- key("screen", "focus next",      MC,  "j",       function() awful.screen.focus_relative, 1) end),
    -- key("screen", "focus prev",      MC,  "k",       function() awful.screen.focus_relative,-1) end),

    key("tag",      "view prev",        M,   "Left",    awful.tag.viewprev),
    key("tag",      "view next",        M,   "Right",   awful.tag.viewnext),
    key("tag",      "go back",          M,   "Escape",  awful.tag.history.restore),

    key("client",   "go back",          M,   "Tab",     focus_previous_client),
    key("client",   "focus next",       M,   "j",       function() awful.client.focus.byidx( 1) end),
    key("client",   "focus prev",       M,   "k",       function() awful.client.focus.byidx(-1) end),
    key("client",   "jump to urgent",   M,   "u",       awful.client.urgent.jumpto),
    key("client",   "swap with next",   MC,  "j",       function() awful.client.swap.byidx( 1) end),
    key("client",   "swap with prev",   MC,  "k",       function() awful.client.swap.byidx(-1) end),

    key("launcher", "open terminal",    M,   "Return",  function() awful.spawn(terminal)         end),
    key("launcher", "open firefox",     MCS, "f",       function() awful.spawn("firefox")        end),
--    key("launcher", "open firefox",     MCS, "f",       function() awful.spawn("/home/pgy/.local/share/umake/web/firefox-dev/firefox")        end),
    key("launcher", "open signal",      MCS, "m",       function() awful.spawn("/usr/bin/chromium-browser --profile-directory=Default --app-id=bikioccmkafdpakkkcpdbppfkghcmihk") end),
    key("launcher", "open dmenu",       M,   "d",       function() awful.spawn("dmenu_run")      end),
    key("launcher", "open sublime",     MCS, "s",       function() awful.spawn("subl3") end),
    key("launcher", "open arandr",      MCS, "a",       function() awful.spawn("arandr")         end),

    key("setting", "raise volume",      {},  "XF86AudioRaiseVolume",  function() awful.spawn("amixer -D pulse -c 1 sset Master 5%+")   end),
    key("setting", "lower volume",      {},  "XF86AudioLowerVolume",  function() awful.spawn("amixer -D pulse -c 1 sset Master 5%-")   end),
    key("setting", "toggle volume",     {},  "XF86AudioMute",         function() awful.spawn("amixer -D pulse -c 1 set Master toggle") end),
    key("setting", "raise brightness",  {},  "XF86MonBrightnessUp",   function() awful.spawn("xbacklight -inc 5") end),
    key("setting", "lower brightness",  {},  "XF86MonBrightnessDown", function() awful.spawn("xbacklight -dec 5") end),

    key("layout", "select next",        M,  "space",   function () awful.layout.inc( 1) end),
    key("layout", "select previous",    MS, "space",   function () awful.layout.inc(-1) end),
    key("layout", "inc master width",   M,  "l",       function () awful.tag.incmwfact( 0.05) end),
    key("layout", "dec master width",   M,  "h",       function () awful.tag.incmwfact(-0.05) end),
    key("layout", "inc num of masters", MS, "h",       function () awful.tag.incnmaster( 1, nil, true) end),
    key("layout", "dec num of masters", MS, "l",       function () awful.tag.incnmaster(-1, nil, true) end),
    key("layout", "inc num of columns", MC, "h",       function () awful.tag.incncol( 1, nil, true) end),
    key("layout", "dec num of columns", MC, "l",       function () awful.tag.incncol(-1, nil, true) end),

    -- becase FIREFOX closes on control+q
    key("client", "prevents ctrl+q", {"Control"},  "q", function() --[[ do nothing! ]] end)

)

for i = 1, 9 do
    global_keys = awful.util.table.join(global_keys,
        key("tag", "view only tag #" .. i,              M,   "#" .. i + 9, function() view_tag_only(i) end),
        key("tag", "toggle tag #" .. i,                 MC,  "#" .. i + 9, function() toggle_tag(i) end),
        key("tag", "move focused client to tag #" .. i, MS,  "#" .. i + 9, function() move_client_to_tag(i) end),
        key("tag", "toggle focused cli. on tag #" .. i, MCS, "#" .. i + 9, function() toggle_tag_on_focused(i) end)
    )
end

local client_keys = awful.util.table.join(
    key("client", "toggle fullscreen",  M,  "f",       function(c) c.fullscreen = not c.fullscreen; c:raise() end),
    key("client", "close (kill)",       M,  "c",       function(c) c:kill() end),
    key("client", "toggle floating",    MC, "space",   function(c) awful.client.floating.toggle(c) end),
    key("client", "move to master",     MC, "Return",  function(c) c:swap(awful.client.getmaster()) end),
    key("client", "to next screen",     M,  "s",       function(c) c:move_to_screen() end),
    key("client", "toggle keep-on-top", M,  "t",       function(c) c.ontop = not c.ontop end)
)

local client_buttons = awful.util.table.join(
    awful.button({}, 1, function (c) client.focus = c; c:raise() end),  --left click
    awful.button(M,  1, awful.mouse.client.move),                       --left click
    awful.button(M,  3, awful.mouse.client.resize)                      --right click
)


root.keys(global_keys)


local default_client_props = {
    border_width = beautiful.border_width,
    border_color = beautiful.border_normal,
    focus = awful.client.focus.filter,
    raise = true,
    keys = client_keys,
    buttons = client_buttons,
    screen = awful.screen.preferred,
    placement = awful.placement.no_overlap + awful.placement.no_offscreen,
    size_hints_honor = false,
    maximized = false,
    maximized_vertical = false, 
    maximized_horizontal = false,
}

local floating_client_props = {floating = true}

local any_floating_rules = {
    instance = {"qemu", "DTA", "plugin-container", "IDA"},
    class    = {"qemu", "VirtualBox", "IDA"},
    name     = {"qemu", "Event Tester", "IDA"},
    role     = {"qemu", "pop-up", "AlarmWindow", "IDA"},
}

awful.rules.rules = {
    { properties = default_client_props,  rule = {} },
    { properties = floating_client_props, rule_any = any_floating_rules },
}


-- SIGNALS --------------------------------------------------------------------

-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position
        then
            -- Prevent clients from being unreachable after screen count changes.
            awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
        and awful.client.focus.filter(c)
        then
            client.focus = c
    end
end)

client.connect_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Compositor
awful.spawn("compton -b --backend glx --vsync opengl-swc")

awful.spawn("setxkbmap hu")
