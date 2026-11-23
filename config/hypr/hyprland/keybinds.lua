local vars = require("variables")
local fn   = require("hyprland.functions")

-- shell globals — shell:<name>: registered by whichever shell is alive (demonshot, glyph), silent if missing
-- Launcher opens only on Super+Space (shell:menu). Super tap-to-open removed.

-- ── Universal Keys (Copy / Paste / Cut / Select-All) ──
local function send_shortcut_once(mods, key)
    return function()
        hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
        end, { timeout = 50, type = "oneshot" })
    end
end

local function active_window_is_terminal()
    local window = hl.get_active_window()
    if not window then
        return false
    end
    local class = (window.class or ""):lower()
    if class:find("foot") or class:find("alacritty") or class:find("kitty") or class:find("terminal") then
        return true
    end
    for _, tag in ipairs(window.tags or {}) do
        if tag:gsub("%*$", "") == "terminal" then
            return true
        end
    end
    return false
end

local function universal_clipboard_shortcut(default_mods, default_key, terminal_mods, terminal_key)
    return function()
        if active_window_is_terminal() then
            send_shortcut_once(terminal_mods, terminal_key)()
        else
            send_shortcut_once(default_mods, default_key)()
        end
    end
end

hl.bind("SUPER + A", send_shortcut_once("CTRL", "A"), { description = "Universal select all" })
hl.bind("SUPER + C", universal_clipboard_shortcut("CTRL", "C", "CTRL SHIFT", "C"), { description = "Universal copy" })
hl.bind("SUPER + V", universal_clipboard_shortcut("CTRL", "V", "CTRL SHIFT", "V"), { description = "Universal paste" })
hl.bind("SUPER + X", send_shortcut_once("CTRL", "X"), { description = "Universal cut" })

-- ── Application Launcher, Altar & Cheatsheet ──
hl.bind("SUPER + Space", hl.dsp.global("shell:menu"), { description = "Application Launcher" })
hl.bind(vars.kbAltar, hl.dsp.global("shell:altar"), { description = "Altar bottom dashboard" })
hl.bind("SUPER + K", hl.dsp.global("shell:keys"), { description = "Keybindings cheatsheet" })
hl.bind("SUPER + slash", hl.dsp.global("shell:keys"), { description = "Keybindings cheatsheet" })

-- ── Quickshell Panels & Controls ──
hl.bind("SUPER + CTRL + A", hl.dsp.global("shell:quick"), { description = "Glyph quick settings" })
hl.bind("SUPER + CTRL + S", hl.dsp.global("shell:quick"), { description = "Glyph quick settings" })
hl.bind("SUPER + CTRL + V", hl.dsp.global("shell:clip"), { description = "Clipboard manager" })
hl.bind("SUPER + SHIFT + D", hl.dsp.exec_cmd("cliphist wipe"), { description = "Clear clipboard" })
hl.bind("SUPER + I", hl.dsp.global("shell:settings"))
hl.bind("SUPER + N", hl.dsp.global("shell:ward"))
hl.bind("SUPER + P", hl.dsp.global("shell:pact"))
hl.bind("SUPER + SHIFT + W", hl.dsp.global("shell:wall")) -- glyph wallpaper
hl.bind(vars.kbSession, hl.dsp.global("shell:power"))
hl.bind(vars.kbPower, hl.dsp.global("shell:power"))
hl.bind(vars.kbLock, hl.dsp.exec_cmd(vars.lockCmd))
hl.bind("SUPER + L", hl.dsp.exec_cmd(vars.lockCmd))
hl.bind(vars.kbRestoreLock, hl.dsp.exec_cmd(vars.lockCmd), { locked = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.global("shell:briUp"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.global("shell:briDown"), { locked = true, repeating = true })

-- Media
hl.bind("CTRL + SUPER + Space", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("CTRL + SUPER + Equal", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("CTRL + SUPER + Minus", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioStop", hl.dsp.exec_cmd("playerctl stop"), { locked = true })

-- Kill/restart
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd(vars.rice .. " kill"), { release = true })
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd(vars.rice .. " restart"), { release = true })

-- ── Workspaces 1-10 ──
for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(vars.kbGoToWs .. " + " .. key, fn.wsaction("focus", "", i))
    hl.bind(vars.kbMoveWinToWs .. " + " .. key, fn.wsaction("move", "", i))
    hl.bind("SUPER + ALT + " .. key, fn.wsaction("move", "", i))
    hl.bind("SUPER + SHIFT + ALT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind(vars.kbGoToWsGroup .. " + " .. key, fn.wsaction("focus", "group", i))
    hl.bind(vars.kbMoveWinToWsGroup .. " + " .. key, fn.wsaction("move", "group", i))
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(vars.kbPrevWs, hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind(vars.kbNextWs, hl.dsp.focus({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + Page_down", hl.dsp.focus({ workspace = "+1" }), { repeating = true })

-- Go to workspace group -1/+1
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), { repeating = true })
hl.bind("CTRL + SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), { repeating = true })

-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

-- Window groups & app cycling
hl.bind("SUPER + Tab", fn.cycle_windows(false), { repeating = true, description = "Cycle open apps" })
hl.bind("SUPER + SHIFT + Tab", fn.cycle_windows(true), { repeating = true, description = "Cycle open apps (backward)" })
hl.bind(vars.kbWindowGroupCycleNext, hl.dsp.window.cycle_next(), { repeating = true })
hl.bind(vars.kbWindowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), { repeating = true })
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), { repeating = true })
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), { repeating = true })
hl.bind(vars.kbToggleGroup, hl.dsp.group.toggle())
hl.bind(vars.kbUngroup, hl.dsp.window.move({ out_of_group = true }))
local kbLockGroup = hl.version():match("^0%.5[0-6]%.") and hl.dsp.group.lock_active() or hl.dsp.group.lock()
hl.bind("SUPER + SHIFT + Comma", kbLockGroup)

-- Window focus navigation
hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.move({ direction = "down" }))

-- ── Window Resizing (Omavoid pixel steps) ──
hl.bind("SUPER + Minus", hl.dsp.window.resize({ x = -100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + Equal", hl.dsp.window.resize({ x = 100, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + Minus", hl.dsp.window.resize({ x = 0, y = -100, relative = true }), { repeating = true })
hl.bind("SUPER + SHIFT + Equal", hl.dsp.window.resize({ x = 0, y = 100, relative = true }), { repeating = true })
hl.bind("SUPER + ALT + Minus", hl.dsp.window.resize({ x = -25, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + ALT + Equal", hl.dsp.window.resize({ x = 25, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + Minus", hl.dsp.window.resize({ x = -300, y = 0, relative = true }), { repeating = true })
hl.bind("SUPER + CTRL + Equal", hl.dsp.window.resize({ x = 300, y = 0, relative = true }), { repeating = true })

-- Fine arrow resize fallback
hl.bind("SUPER + ALT + left", hl.dsp.window.resize(fn.resize_active_window(-10, 0)), { repeating = true })
hl.bind("SUPER + ALT + right", hl.dsp.window.resize(fn.resize_active_window(10, 0)), { repeating = true })
hl.bind("SUPER + ALT + up", hl.dsp.window.resize(fn.resize_active_window(0, -10)), { repeating = true })
hl.bind("SUPER + ALT + down", hl.dsp.window.resize(fn.resize_active_window(0, 10)), { repeating = true })

-- Mouse window actions
hl.bind("SUPER + SHIFT + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(vars.kbMoveWindow, hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:272", hl.dsp.window.resize(), { mouse = true })
hl.bind(vars.kbResizeWindow, hl.dsp.window.resize(), { mouse = true })

-- Window layouts & sizing
hl.bind("SUPER + J", hl.dsp.layout("togglesplit"), { description = "Toggle layout split" })
hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.resize(fn.resize_by_screen(55, 70)))
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.center())
hl.bind(vars.kbWindowPip, function()
    local a = hl.get_active_window()
    if a then
        local pip = fn.move_actions(a) or {}
        if not a.floating then table.insert(pip, 1, hl.dsp.window.float()) end
        table.insert(pip, hl.dsp.window.pin({ action = "on", window = "address:" .. a.address }))

        for _, x in ipairs(pip) do
            hl.dispatch(x)
        end
    end
end)
hl.bind(vars.kbPinWindow, hl.dsp.window.pin())
hl.bind(vars.kbWindowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(vars.kbWindowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(vars.kbToggleWindowFloating, fn.toggle_floating_centered, { description = "Toggle floating centered" })
hl.bind(vars.kbCloseWindow, hl.dsp.window.close(), { description = "Close window" })

-- Special workspace toggles
hl.bind(vars.kbSpecialWs, fn.toggle_special("special"))
hl.bind(vars.kbSystemMonitorWs, fn.toggle_special("sysmon"))
hl.bind(vars.kbMusicWs, fn.toggle_special("music"))
hl.bind(vars.kbCommunicationWs, fn.toggle_special("communication"))
hl.bind(vars.kbTodoWs, fn.toggle_special("todo"))

-- Apps
hl.bind(vars.kbTerminal, function() hl.exec_cmd(vars.terminal) end) -- SUPER + Return
hl.bind("SUPER + Q", function() hl.exec_cmd(vars.terminal) end) -- fallback terminal
hl.bind(vars.kbBrowser, hl.dsp.exec_cmd(vars.browser)) -- SUPER + SHIFT + B
hl.bind("SUPER + SHIFT + ALT + B", hl.dsp.exec_cmd(vars.browser .. " --incognito"))
hl.bind("SUPER + B", hl.dsp.exec_cmd("kitty -e btop"))
hl.bind(vars.kbEditor, function() if vars.apps.editor then hl.exec_cmd(vars.apps.editor) end end)
hl.bind(vars.kbFileExplorer, hl.dsp.exec_cmd(vars.fileExplorer)) -- SUPER + E
hl.bind("SUPER + SHIFT + F", hl.dsp.exec_cmd("strata"))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd(vars.audioSettings))

-- Utilities
hl.bind("Print", hl.dsp.global("shell:shot"))
hl.bind("SUPER + SHIFT + S", hl.dsp.global("shell:shot"))
hl.bind("SUPER + CTRL + Print", hl.dsp.exec_cmd("ocr-extract"), { description = "OCR text extraction" })
hl.bind("SUPER + ALT + R",       hl.dsp.global("shell:rec"),       { description = "Record screen + audio (toggle)" })
hl.bind("CTRL + ALT + R",        hl.dsp.global("shell:recSilent"), { description = "Record screen, no audio (toggle)" })
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.global("shell:recRegion"), { description = "Record region, no audio (toggle)" })
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"))
hl.bind("SUPER + SHIFT + U", hl.dsp.exec_cmd("hyprctl kill"))

-- Volume
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("F4", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l " ..
        (vars.volumeMax / 100) .. " @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%+"
    ),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd(
        "wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. vars.volumeStep .. "%-"
    ),
    { locked = true, repeating = true }
)

-- Sleep
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd(vars.sleepGestureCmd), { locked = true })

-- Extra utilities
hl.bind("SUPER + Period", hl.dsp.global("shell:charms"))
hl.bind(
    "CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd('sleep 0.5s && printf %s "$(cliphist list | head -1 | cliphist decode)" | ydotool type -d 1 -f -')
)

-- Testing
hl.bind(
    "SUPER + ALT + F12",
    hl.dsp.exec_cmd(
        "notify-send -u low -i dialog-information-symbolic 'Test notification' " ..
        [["Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!"]] ..
        " -a 'Shell' -A 'Test1=I got it!' -A 'Test2=Another action'"
    )
)
