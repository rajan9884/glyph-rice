-- Monitor: scale decided by hypr (then set by shell's Rules.monitor)
hl.monitor({ output = "", mode = "highres", position = "auto", scale = "auto" })

-- XWayland scales via hypr: blurry on HiDPI, but correct size at any scale. Sharp at whole scale — in user.lua:
--   hl.config({ xwayland = { force_zero_scaling = true } }); hl.env("GDK_SCALE", "2")

-- Configs
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- own binds and fixes on top of rice: hypr/user.lua (in .gitignore, repo updates don't touch it)
local user = io.open(os.getenv("HOME") .. "/.config/hypr/user.lua")
if user then user:close(); require("user") end
