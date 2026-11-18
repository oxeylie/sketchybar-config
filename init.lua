-- Imports
require("helpers")
local icons   = require("helpers/icons")

log("lua-main","$PATH: " .. os.getenv("PATH") .. "")
sbar.exec([[
exe() { lsof -p "$1" -a -d txt -Fn 2>/dev/null | sed -n 's/^n//p' | head -n1; }

pid=$$
printf 'pid:%s ancestor tree\n' "$pid"
while [ -n "$pid" ] && [ "$pid" -gt 0 ]; do
  printf '+--pid: %s\tpath: %s\tcmd: %s\n' "$pid" "$(exe "$pid")" "ps -p $pid -o command="
  pid=$(ps -p "$pid" -o ppid= | tr -d ' ')
done
]], function(result,exit_code)
	log("lua-main", result)
end)

-- Globals
os_version = macOSversion()

local system_menu_host
if tonumber(os_version[1]) >= 27 then 
	system_menu_host = "com.apple.MenuBarAgent"
else 
	system_menu_host = "com.apple.controlcenter"
end

menu_items = {
  clock          = { app = system_menu_host, id = "com.apple.menuextra.clock"},
  sound          = { app = system_menu_host, id = "com.apple.menuextra.sound"},
  video          = { app = system_menu_host, id = "com.apple.menuextra.audiovideo"},
  wifi           = { app = system_menu_host, id = "com.apple.menuextra.wifi" },
  battery        = { app = system_menu_host, id = "com.apple.menuextra.battery" },
  display        = { app = system_menu_host, id = "com.apple.menuextra.display" },
  user_switcher  = { app = system_menu_host, id = "com.apple.menuextra.user" },
  media_player   = { app = system_menu_host, id = "com.apple.menuextra.now-playing" },
  live_player    = { app = system_menu_host, id = "live-activity-pill-com.apple.MediaRemoteUIService" },
	bluetooth      = { app = system_menu_host, id = "com.apple.menuextra.bluetooth", icon = icons.link };
	control_center = { app = system_menu_host, id = "com.apple.menuextra.controlcenter", icon = icons.control_center }
}

-- Fetch config with given defaults
config = fetchConfig(os.getenv("SKETCHYBAR_CONFIG") or "./config.lua", 
                     { -- Look & feel
                       theme        = "rose_pine",
                       transparency = true,
                       bar_look     = "default",
                       font         = "SF Pro",
                       animate      = true,

                       -- Behaviour
                       controls     = { menu_items.bluetooth },
                       theme_file   = "./themes.lua",
                       
                       -- Technical
                       window_manager = "yabai",
                       notch_width    = 180,
                       perfbc         = true, -- Allow command bundling for improved performance
                       git_key        = nil,
                       display_groups = {},
                       execs          = {} -- Overrides for executables
                     }) 

execs = mergeTables({
  menubar       = cmdPath("menubar") or "./helper/menubar",
  ft_haptic     = cmdPath("ft-haptic") or "./helper/ft-haptics",
  media_control = cmdPath("media-control") or log("lua-main","No media-control in path"),
  icon_map      = cmdPath("icon_map.sh") or "./helper/icon_map.sh",
  bd_cli        = cmdPath("betterdisplaycli") or log("lua-main","No betterdisplaycli in path"),
  identify      = cmdPath("identify") or log("lua-main","No imagemagick in path"),
  magick        = cmdPath("magick") or cmdPath("convert") or log("lua-main","No imagemagick in path"),
  yabai         = cmdPath("yabai") or log("lua-main","No yabai in path")
},config.execs)

local palette = require("helpers/colors").getColorPalette(config.theme, config.transparency and 180 or 1000) -- Put a huge alpha value to prevent adjusts

-- Configure bar properties
local bar   = require("bar")   .setup(palette)
local zones = require("zones") .setup(bar, icons, palette)
local items = require("items") .setup(bar, zones, icons, palette)

bar  .load()
items.load(zones,icons,palette)
zones.load(icons)
