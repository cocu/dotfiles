-- Standard awesome library
local gears = require("gears")
local awful = require("awful")
awful.rules = require("awful.rules")

-- Widget and layout library
local wibox = require("wibox")
local lain = require("lain")
local markup = lain.util.markup
local vicious = require('vicious')

-- Theme handling library
local beautiful = require("beautiful")
beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")
beautiful.graph_fg = "#7F9F7F"
beautiful.graph_border_color = "#7F9F7F"

-- Notification
awful.util.spawn("dunst")
_dbus = dbus
dbus = nil
local naughty = require("naughty")
dbus = _dbus
local menubar = require("menubar")

local pomodoro = require('pomodoro')

local myconfig = require('myconfig')
local const = require('myconfig.const')

local hotkeys_popup = require("awful.hotkeys_popup").widget
beautiful.hotkeys_font = "Ricty 15"
beautiful.hotkeys_description_font = "Ricty 15"
beautiful.hotkeys_modifiers_fg = "#CDEE69"

local is_double_screen = screen.count() == 2
local is_secondary_main = true

local homedir = os.getenv("HOME")

local is_laptop = const.get("is_laptop", false)
local nic_id = const.get("nic_id", "eno1")

local screen_ids = const.get("screen_ids", {left=3, center=1, right=2})
local screen_id_main = const.get("screen_id_main", 1)

-- {{{ Error handling
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
  awesome.connect_signal("debug::error", function(err)
    -- Make sure we don't go into an endless error loop
    if in_error then return end
    in_error = true

    naughty.notify({
      preset = naughty.config.presets.critical,
      title = "Oops, there were errors during startup!",
      text = err
    })
    in_error = false
  end)
end
-- }}}


--}}}

--{{{ pomodoro timer
pomodoro.init()
pomodoro.on_work_pomodoro_finish_callbacks = {
  function()
    awful.spawn('ogg123 /usr/share/sounds/freedesktop/stereo/complete.oga')
  end
}
pomodoro.on_pause_pomodoro_finish_callbacks = {
  function()
    awful.spawn('ogg123 /usr/share/sounds/freedesktop/stereo/complete.oga')
  end
}
--}}}


-- {{{ Variable definitions
-- Themes define colours, icons, font and wallpapers.

-- This is used later as the default terminal
terminal = "urxvt"

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
local layouts =
{
  awful.layout.suit.max,
  awful.layout.suit.max.fullscreen,
  awful.layout.suit.tile,
  awful.layout.suit.tile.bottom,
  awful.layout.suit.magnifier,
  awful.layout.suit.floating,
}
-- }}}


-- {{{ Tags
-- Define a tag table which hold all screen tags.
tag_names = const.get('tag_names', function(_)return {center={"1"}} end)(screen.count())


local tags = {}
for screen_name, tags_data in pairs(tag_names)do
  tags[screen_name] = awful.tag(tags_data["names"], screen_ids[screen_name], awful.layout.suit.max)
end

function focus_home_position()
  for screen_name, tags_data in pairs(tag_names) do
    local s = screen[screen_ids[screen_name]]
    local t = awful.tag.find_by_name(s, tags_data.home)
    awful.tag.viewonly(t)
  end
end

-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock()

-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
  awful.button({}, 1, awful.tag.viewonly),
  awful.button({ modkey }, 1, awful.client.movetotag),
  awful.button({}, 3, awful.tag.viewtoggle),
  awful.button({ modkey }, 3, awful.client.toggletag),
  awful.button({}, 4, function(t) awful.tag.viewnext(awful.tag.getscreen(t)) end),
  awful.button({}, 5, function(t) awful.tag.viewprev(awful.tag.getscreen(t)) end))
mytasklist = {}
mytasklist.buttons = awful.util.table.join(awful.button({}, 1, function(c)
  if c == client.focus then
    c.minimized = true
  else
    -- Without this, the following
    -- :isvisible() makes no sense
    c.minimized = false
    if not c:isvisible() then
      awful.tag.viewonly(c:tags()[1])
    end
    -- This will also un-minimize
    -- the client, if needed
    client.focus = c
    c:raise()
  end
end),
  awful.button({}, 3, function()
    if instance then
      instance:hide()
      instance = nil
    else
      instance = awful.menu.clients({
        theme = { width = 250 }
      })
    end
  end),
  awful.button({}, 4, function()
    awful.client.focus.byidx(1)
    if client.focus then client.focus:raise() end
  end),
  awful.button({}, 5, function()
    awful.client.focus.byidx(-1)
    if client.focus then client.focus:raise() end
  end))

for s = 1, screen.count() do
  -- Create a promptbox for each screen
  mypromptbox[s] = awful.widget.prompt()
  -- Create an imagebox widget which will contains an icon indicating which layout we're using.
  -- We need one layoutbox per screen.
  mylayoutbox[s] = awful.widget.layoutbox(s)
  mylayoutbox[s]:buttons(awful.util.table.join(
    awful.button({}, 1, function() awful.layout.inc(layouts, 1) end),
    awful.button({}, 3, function() awful.layout.inc(layouts, -1) end),
    awful.button({}, 4, function() awful.layout.inc(layouts, 1) end),
    awful.button({}, 5, function() awful.layout.inc(layouts, -1) end)))
  -- Create a taglist widget
  mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.filter.all, mytaglist.buttons)

  -- Create a tasklist widget
  mytasklist[s] = awful.widget.tasklist(s, awful.widget.tasklist.filter.currenttags, mytasklist.buttons)

  -- Create the wibox
  mywibox[s] = awful.wibox({ position = "top", screen = s })

  -- Widgets that are aligned to the left
  local left_layout = wibox.layout.fixed.horizontal()
  left_layout:add(mytaglist[s])
  left_layout:add(mypromptbox[s])

  -- Widgets that are aligned to the right
  local right_layout = wibox.layout.fixed.horizontal()
  if s == 1 then
    right_layout:add(wibox.container.background(wibox.widget.systray(), beautiful.bg_focus))
    right_layout:add(wibox.container.background(pomodoro.icon_widget, beautiful.bg_focus))
    right_layout:add(wibox.container.background(pomodoro.widget, beautiful.bg_focus))
    if is_laptop then
      local memtext = wibox.widget.textbox()
      vicious.register(memtext, vicious.widgets.mem, '<b><span color="#7F9F7F"> mem: $2 kB($1%)</span><span color="#cccccc"> | </span></b>', 2)
      right_layout:add(wibox.container.background(memtext, beautiful.bg_focus))

      cpuwidget = wibox.widget.graph()
      cpuwidget:set_width(50)
      cpuwidget:set_background_color(beautiful.bg_focus)
      cpuwidget_t = awful.tooltip({ objects = { cpuwidget.widget }, })
      vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 1)
      right_layout:add(wibox.container.mirror(cpuwidget,
        { horizontal = true }))

      local battext = wibox.widget.textbox()
      local formatter = function(widget, args)
        local status = args[1]
        local percent = args[2]
        local str =
        "<span weight='bold' color='%s'>" ..
            "%s</span>%d "
        if percent > 75 then
          return string.format(str, "#00CC00", status, percent)
        elseif percent > 50 then
          return string.format(str, "#66CC00", status, percent)
        elseif percent > 25 then
          return string.format(str, "#CCCC00", status, percent)
        elseif percent > 10 then
          return string.format(str, "#CC6600", status, percent)
        else
          return string.format(str, "#CC0000", status, percent)
        end
      end
      vicious.register(battext, vicious.widgets.bat, formatter, 3, "BAT0")
      right_layout:add(battext)

      local battext = wibox.widget.textbox()
      local formatter = function(widget, args)
        local status = args[1]
        local percent = args[2]
        local str =
        "<span weight='bold' color='%s'>" ..
            "%s</span>%d "
        if percent > 75 then
          return string.format(str, "#00CC00", status, percent)
        elseif percent > 50 then
          return string.format(str, "#66CC00", status, percent)
        elseif percent > 25 then
          return string.format(str, "#CCCC00", status, percent)
        elseif percent > 10 then
          return string.format(str, "#CC6600", status, percent)
        else
          return string.format(str, "#CC0000", status, percent)
        end
      end
      vicious.register(battext, vicious.widgets.bat, formatter, 3, "BAT1")
      right_layout:add(battext)
    end
  else
    memtext = wibox.widget.textbox()
    vicious.register(memtext, vicious.widgets.mem, '<b><span color="#7F9F7F"> mem: $2 kB($1%)</span><span color="#cccccc"> | </span></b>', 2)
    right_layout:add(wibox.container.background(memtext, beautiful.bg_focus))

    nettext = wibox.widget.textbox()
    vicious.register(nettext, vicious.widgets.net, '<b><span color="#CC9933">down: ${' .. nic_id .. ' down_kb} kB/s</span> <span color="#7F9F7F"> up: ${' .. nic_id .. ' up_kb} kB/s</span></b> ', 2)
    right_layout:add(wibox.container.background(nettext, beautiful.bg_focus))

    cpuwidget = wibox.widget.graph()
    cpuwidget:set_width(50)
    cpuwidget_t = awful.tooltip({ objects = { cpuwidget.widget }, })
    vicious.register(cpuwidget, vicious.widgets.cpu, "$1", 1)
    right_layout:add(wibox.container.background(cpuwidget, beautiful.bg_focus))
  end
  right_layout:add(mytextclock)
  right_layout:add(mylayoutbox[s])

  -- Now bring it all together (with the tasklist in the middle)
  local layout = wibox.layout.align.horizontal()
  layout:set_left(left_layout)
  layout:set_middle(mytasklist[s])
  layout:set_right(right_layout)

  mywibox[s]:set_widget(layout)
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(awful.button({}, 3, function() mymainmenu:toggle() end),
  awful.button({}, 4, awful.tag.viewnext),
  awful.button({}, 5, awful.tag.viewprev)))
-- }}}

-- {{{ Key bindings
local cmd_rofi_window_selector = "rofi -show window -font 'Ricty 14' -fg '#a0a0a0' -bg '#000000' -hlfg '#ffb964' -hlbg '#303030' -fg-active '#ffb0b0' -opacity 85"
globalkeys = awful.util.table.join(
  awful.key({ modkey, }, "Left", awful.tag.viewprev),
  awful.key({ modkey, }, "Right", awful.tag.viewnext),
  awful.key({ modkey, }, "Escape", awful.tag.history.restore),

  awful.key({ modkey, }, "j",
    function()
      awful.client.focus.byidx(1)
      if client.focus then client.focus:raise() end
    end),
  awful.key({ modkey, }, "k",
    function()
      awful.client.focus.byidx(-1)
      if client.focus then client.focus:raise() end
    end),

  -- Layout manipulation
  awful.key({ modkey, "Shift" }, "j", function() awful.client.swap.byidx(1) end),
  awful.key({ modkey, "Shift" }, "k", function() awful.client.swap.byidx(-1) end),
  awful.key({ modkey, }, "u", awful.client.urgent.jumpto),

  -- Screen focus
  awful.key({ modkey, }, "[", function() awful.screen.focus(screen_ids.center) end),
  awful.key({ modkey, }, "]", function()
    if is_double_screen then
      awful.screen.focus(screen_ids.right)
    end
  end),
  awful.key({ modkey, }, "r", focus_home_position),

  -- Standard program
  awful.key({ modkey, }, "Return", function() awful.util.spawn(terminal) end),
  awful.key({ modkey, "Shift" }, "Return", function() awful.util.spawn("xterm") end),
  awful.key({ modkey, "Shift" }, "r", awesome.restart),
  awful.key({ modkey, "Shift" }, "Escape", awesome.quit),


  awful.key({ modkey, }, "Tab", function() awful.layout.inc(layouts, 1) end),
  awful.key({ modkey, "Shift" }, "Tab", function() awful.layout.inc(layouts, -1) end),
  awful.key({ modkey, "Shift" }, "n",
    awful.client.restore),
  awful.key({ modkey }, "x",
    function()
      awful.prompt.run({ prompt = "Run Lua code: " },
        mypromptbox[mouse.screen].widget,
        awful.util.eval, nil,
        awful.util.getdir("cache") .. "/history_eval")
    end,
    { description = "Run Lua code", group = "awesome" }),

  -- menuber/toolbar/help
  awful.key({ modkey, }, "d", 
    function() menubar.show() end),
  awful.key({ modkey, }, "s", 
    hotkeys_popup.show_help,
    { description = "show help", group = "awesome" }),
  awful.key({ modkey, }, "e",
    function()
      for s = 1, screen.count() do
        mywibox[s].visible = not mywibox[s].visible
      end
    end,
    { description = "toggle bar", group = "bar" }),

  awful.key({ modkey, }, "b",
    function() awful.util.spawn("xbacklight =5") end),
  awful.key({ modkey, "Shift" }, "b",
    function() awful.util.spawn("xbacklight +5") end),

  -- program
  awful.key({ modkey, }, "l", 
    function() awful.util.spawn("xscreensaver-command -lock") end),
  awful.key({ modkey, "Shift" }, "l",
    function() awful.util.spawn("xscreensaver-command -lock") end),
  awful.key({ modkey, "Shift" }, "d", 
    function() awful.util.spawn("rofi -show run -font 'Ricty 14' -fg '#00ff00' -bg '#000000' -hlfg '#b9ff64' -hlbg '#303030' -opacity 85") end),
  awful.key({ modkey, }, "w",
    function() awful.util.spawn(cmd_rofi_window_selector) end),
  awful.key({ modkey, }, "m",
    function() awful.util.spawn(cmd_rofi_window_selector) end),
  awful.key({ modkey, "Shift" }, "w",
    function() awful.spawn.with_shell("python ~/workspace/wallpaperchanger/wallpaperchanger.py") end))

clientkeys = awful.util.table.join(
  awful.key({ modkey, }, "f",
    function(c) c.fullscreen = not c.fullscreen end,
    { description = "toggle fullscreen", group = "window" }),
  awful.key({ modkey, "Shift" }, "q", 
    function(c) c:kill() end,
    { description = "kill the app", group = "window" }),
  awful.key({ modkey, "Shift" }, "f",
    awful.client.floating.toggle,
    { description = "toggle floating", group = "window" }),
  awful.key({ modkey, }, "space", 
    function(c) c:swap(awful.client.getmaster()) end,
    { description = "set master window", group = "window" }),

  -- screen moving
  awful.key({ modkey, "Shift" }, "[",
    function(c)
      local screen = mouse.screen
      awful.client.movetoscreen(c, screen_id_main)
      awful.screen.focus(screen)
    end,
    { description = "move window to the screen", group = "screen" }),
  awful.key({ modkey, "Shift" }, "]",
    function(c)
      if is_double_screen then
        local screen = mouse.screen
        awful.client.movetoscreen(c, screen_ids.right)
        awful.screen.focus(screen)
      end
    end,
    { description = "move window to the screen", group = "screen" }),
  awful.key({ modkey, }, "n",
    function(c) c.minimized = true end,
    { description = "minimize the window", group = "window" }),
  awful.key({ modkey, }, "t",
    function(c) c.ontop = not c.ontop end,
    { description = "fix the window to the top", group = "window" }),
  awful.key({ modkey, "Shift" }, "m",
    function(c)
      c.maximized_horizontal = not c.maximized_horizontal
      c.maximized_vertical = not c.maximized_vertical
    end,
    { description = "maximize the window", group = "window" }),
  awful.key({ modkey, }, "o",
    function(c)
      c.no_opacity = (not c.no_opacity)
    end,
    { description = "toggle window transparency", group = "screen" }))

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
function gen_tag_key_binds(screen_id, tag_idx, tag_name)
  return awful.util.table.join(-- View tag only.
    awful.key({ modkey }, tag_name,
      function()
        local tag = awful.tag.gettags(screen_id)[tag_idx]
        if tag then
          awful.tag.viewonly(tag)
        end
      end,
      { description = "change tag", group = "tag" }),
    -- Toggle tag.
    awful.key({ modkey, "Control" }, tag_name,
      function()
        local tag = awful.tag.gettags(screen_id)[tag_idx]
        if tag then
          awful.tag.viewtoggle(tag)
        end
      end,
      { description = "toggle tag", group = "tag" }),
    -- Move client to tag.
    awful.key({ modkey, "Shift" }, tag_name,
      function()
        local scr = mouse.screen
        if client.focus then
          local tag = awful.tag.gettags(screen_id)[tag_idx]
          if tag then
            awful.client.movetotag(tag)
          end
        end
        awful.screen.focus(scr)
      end,
      { description = "move window to specified tag", group = "tag" }))
end


for screen_name, tags_data in pairs(tag_names) do
  for i, t in ipairs(tags_data.names) do
    globalkeys = awful.util.table.join(globalkeys,
      gen_tag_key_binds(screen_ids[screen_name], i, t))
  end
end

clientbuttons = awful.util.table.join(
  awful.button({}, 1, function(c) client.focus = c; c:raise() end),
  awful.button({ modkey }, 1, awful.mouse.client.move),
  awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
-- Rules to apply to new clients (through the "manage" signal).
awful.rules.rules = {
  -- All clients will match this rule.
  {
    rule = {},
    properties = {
      --border_width = beautiful.border_width,
      --border_color = beautiful.border_normal,
      placement = awful.placement.under_mouse + awful.placement.no_overlap + awful.placement.no_offscreen,
      focus = awful.client.focus.filter,
      screen = awful.screen.focused,
      raise = true,
      size_hints_honor = false,
      keys = clientkeys,
      no_opacity = false,
      buttons = clientbuttons
    }
  },
  {
    rule = { class = "Spotify" },
    properties = { tag = awful.tag.find_by_name(nil, "7") }
  },
  {
    rule = { role = "browser" },
    properties = { tag = awful.tag.find_by_name(nil, "=") }
  },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
local _start_time = os.time()

client.connect_signal("manage", function(c, startup)
  if not startup then
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- awful.client.setslave(c)

    -- Put windows in a smart way, only if they does not set an initial position.
    if not c.size_hints.user_position and not c.size_hints.program_position then
      awful.placement.no_overlap(c)
      awful.placement.no_offscreen(c)
    end
  end
end)

client.connect_signal("focus", function(c)
  c.border_color = beautiful.border_focus
  c.opacity = 1
end)
client.connect_signal("unfocus", function(c)
  c.border_color = beautiful.border_normal
  if (not c.no_opacity) then
    c.opacity = 0.95
  end
end)
-- }}}


-- {{{
local timer = require("gears.timer")

local function filter_sticky(c)
  return not c.sticky and awful.client.focus.filter(c)
end

--- Give focus when clients appear/disappear.
--
-- @param obj An object that should have a .screen property.
local function check_focus(obj)
  if not obj.screen.valid then return
  end
  -- When no visible client has the focus...
  if not client.focus or not client.focus:isvisible() then
    local c = awful.client.focus.history.get(screen[obj.screen], 0, filter_sticky)
    if not c then
      c = awful.client.focus.history.get(screen[obj.screen], 0, awful.client.focus.filter)
    end
    if c then
      c:emit_signal("request::activate", "autofocus.check_focus",
        { raise = false })
    end
  end
end

--- Check client focus (delayed).
-- @param obj An object that should have a .screen property.
local function check_focus_delayed(obj)
  timer.delayed_call(check_focus, { screen = obj.screen })
end

--- Give focus on tag selection change.
--
-- @param tag A tag object
local function check_focus_tag(t)
  local s = t.screen
  if (not s) or (not s.valid) then return
  end
  s = screen[s]
  check_focus({ screen = s })
  if client.focus and screen[client.focus.screen] ~= s then
    local c = awful.client.focus.history.get(s, 0, filter_sticky)
    if not c then
      c = awful.client.focus.history.get(s, 0, awful.client.focus.filter)
    end
    if c then
      c:emit_signal("request::activate", "autofocus.check_focus_tag",
        { raise = false })
    end
  end
end



tag.connect_signal("property::selected", function(t)
  timer.delayed_call(check_focus_tag, t)
end)
client.connect_signal("unmanage", check_focus_delayed)
client.connect_signal("tagged", check_focus_delayed)
client.connect_signal("untagged", check_focus_delayed)
client.connect_signal("property::hidden", check_focus_delayed)
client.connect_signal("property::minimized", check_focus_delayed)
client.connect_signal("property::sticky", check_focus_delayed)
-- }}}


focus_home_position()
