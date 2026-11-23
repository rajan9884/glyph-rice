local scheme = require("scheme.demonshot")

hl.config({
    misc = {
        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,

        disable_hyprland_logo        = true,
        force_default_wallpaper      = 0,

        on_focus_under_fullscreen    = 2,
        allow_session_lock_restore   = true,
        middle_click_paste           = false,
        focus_on_activate            = true,
        session_lock_xray            = true,

        mouse_move_enables_dpms      = true,
        key_press_enables_dpms       = true,

        dim_special                  = 0.0,   -- no dimming when special workspace (scratchpad) opens

        background_color             = "rgb(" .. scheme.void .. ")",
    },

    xwayland = {
        enabled = false,
    },

    -- without auto-HDR: Chromium/Electron window in fullscreen switched panel to HDR — modeset (screen flickers, ~1s
    -- compositor waits) and SDR in HDR is darker
    render = {
        cm_auto_hdr = 0,
    },

    debug = {
        error_position = 1
    }
})
