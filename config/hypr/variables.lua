local scheme = require("scheme.demonshot")
local home   = os.getenv("HOME")

-- DEMONSHOT_NESTED=1 Hyprland -c …/rice/config/hypr/hyprland.lua — nested session for debugging:
-- system daemons already run outside
local nested = os.getenv("DEMONSHOT_NESTED") ~= nil
-- which shell is alive (demonshot, glyph…), decided by rice: `rice switch <name>` or Rice app
-- full path: ~/.local/bin not in hypr's PATH
local rice   = home .. "/.config/quickshell/rice/rice"

return {
    ------------------
    ---- HYPRLAND ----
    ------------------

    nested                     = nested,

    -- Shell
    rice                       = rice,
    lockCmd                    = rice .. " lock", -- lock current shell; second one won't start

    -- Apps
    terminal                   = "kitty", -- not -1: shared process, broke GL after sleep (AMD and Intel), whitened all new windows until reboot (#12); cost — ~230ms vs ~20
    browser                    = "zen-browser",
    fileExplorer               = "thunar",
    audioSettings              = "pavucontrol",
    -- special workspace apps (launch if empty) and editor. Binds read them on press,
    -- so custom ones go in user.lua: require("variables").apps.editor = "codium". Not set — opens empty workspace.
    -- telegram and spotify installed by install.sh --with
    apps                       = {
        sysmon        = "kitty --class btop -T btop btop",
        music         = "spotify-launcher",
        communication = "Telegram",
    },

    -- Touchpad
    touchpadDisableTyping      = false,
    touchpadScrollFactor       = 0.3,
    gestureFingers             = 4,
    workspaceSwipeFingers      = 3,
    gestureFingersMore         = 5,

    -- Blur
    blurEnabled                = true,
    blurSpecialWs              = false,
    blurPopups                 = true,
    blurInputMethods           = true,
    blurSize                   = 8,
    blurPasses                 = 2,
    blurXray                   = false,

    -- Shadow
    -- soft red glow on focus
    shadowEnabled              = true,
    shadowRange                = 10,
    shadowRenderPower          = 4,
    shadowColour               = "rgba(" .. scheme.crimson .. "20)",

    -- Gaps
    workspaceGaps              = 15,
    windowGapsIn               = 6,
    windowGapsOut              = 14,

    -- Window styling
    windowOpacity              = 1,
    windowRounding             = 0,
    windowBorderSize           = 2,
    activeWindowBorderColour   = {
        colors = { "rgb(" .. scheme.crimson .. ")", "rgb(" .. scheme.rose .. ")", "rgb(" .. scheme.crimson .. ")" },
        angle = 135,
    },
    inactiveWindowBorderColour = "rgb(" .. scheme.wine .. ")",

    -- Misc
    volumeStep                 = 5,
    volumeMax                  = 100,
    cursorTheme                = "Bibata-Modern-Classic",
    cursorSize                 = 23,
    sleepGestureCmd            = "systemctl suspend-then-hibernate || systemctl suspend", -- no hibernation — regular sleep

    ------------------
    ---- KEYBINDS ----
    ------------------

    -- Workspaces
    kbMoveWinToWs              = "SUPER + ALT",
    kbMoveWinToWsGroup         = "CTRL + SUPER + ALT",
    kbGoToWs                   = "SUPER",
    kbGoToWsGroup              = "CTRL + SUPER",
    kbNextWs                   = "CTRL + SUPER + Right",
    kbPrevWs                   = "CTRL + SUPER + Left",

    -- Window Group
    kbWindowGroupCycleNext     = "ALT + TAB",
    kbWindowGroupCyclePrev     = "SHIFT + ALT + TAB",
    kbUngroup                  = "SUPER + U",
    kbToggleGroup              = "SUPER + Comma",

    -- Window Action
    kbMoveWindow               = "SUPER + Z",
    kbResizeWindow             = "SUPER + X",
    kbWindowPip                = "SUPER + ALT + backslash",
    kbPinWindow                = "SUPER + SHIFT + P", -- Super+P — VPN agreement
    kbWindowFullscreen         = "SUPER + F",
    kbWindowBorderedFullscreen = "SUPER + ALT + F",
    kbToggleWindowFloating     = "SUPER + ALT + space",
    kbCloseWindow              = "SUPER + C",

    -- Special workspaces toggles
    kbSpecialWs                = "SUPER + S",
    kbSystemMonitorWs          = "CTRL + SHIFT + Escape",
    kbMusicWs                  = "SUPER + M",
    kbCommunicationWs          = "SUPER + D",
    kbTodoWs                   = "SUPER + R",

    -- Apps
    kbTerminal                 = "SUPER + Q",
    kbBrowser                  = "SUPER + W",
    kbEditor                   = "SUPER + SHIFT + K",
    kbFileExplorer             = "SUPER + E",

    -- Misc
    kbSession                  = "CTRL + ALT + Delete",
    kbPower                    = "SUPER + Escape",
    kbAltar                    = "SUPER + Space",
    kbLock                     = "SUPER + L",
    kbRestoreLock              = "SUPER + ALT + L",
}
