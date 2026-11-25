local vars = require("variables")

local function wsaction(action, range, i)
    return function()
        local activews = hl.get_active_workspace()
        if activews then
            local id = activews.id
            local s  = (i - 1) * 10 + (id % 10)
            local t  = math.floor((id - 1) / 10) * 10 + i
            local z  = (range == "group") and s or t

            if action == "move" then
                return hl.dispatch(hl.dsp.window.move({ workspace = z }))
            else
                return hl.dispatch(hl.dsp.focus({ workspace = z }))
            end
        end
    end
end

local function resize_by_screen(x, y)
    local screen = hl.get_active_monitor()
    if screen and type(screen.width) == "number" and type(screen.height) == "number" then
        if not (x == 0 and y == 0) then
            local w = (x and x > 0) and math.floor(screen.width * x / 100) or screen.width
            local h = (y and y > 0) and math.floor(screen.height * y / 100) or screen.height
            return { x = w, y = h, relative = false }
        end
    end
end

local function resize_active_window(x, y)
    local win = hl.get_active_window()
    if win and win.size then
        local w = (win.size.x * (x / 100)) or 800
        local h = (win.size.y * (y / 100)) or 600

        return { x = w, y = h, relative = true }
    end
end

local function resizer(window, pattern, x_percent, y_percent, actions, exact)
    if (window and window.title) and string.find(window.title, pattern, 1, exact) then
        local disp = (type(actions) == "table") and actions or { actions }
        for _, x in ipairs(disp) do
            hl.dispatch(x)
        end

        hl.dispatch(hl.dsp.window.resize(resize_by_screen(x_percent, y_percent)))
        hl.dispatch(hl.dsp.window.set_prop({ prop = "keep_aspect_ratio", value = "true" }))
    end
end

local function move_actions(win)
    local screen = hl.get_active_monitor()

    if screen and screen.width and screen.height and win and win.size then
        local monitor_height = screen.height / screen.scale
        local monitor_width  = screen.width / screen.scale

        local scale_factor   = (monitor_height / 4) / win.size.y

        local target_width   = win.size.x * scale_factor
        local target_height  = win.size.y * scale_factor

        local x_resize       = math.floor(math.max(200, target_width))
        local y_resize       = math.floor(math.max(150, target_height))

        local offset         = math.min(monitor_width, monitor_height) * 0.03

        local move_x         = math.floor(screen.x + monitor_width - x_resize - offset)
        local move_y         = math.floor(screen.y + monitor_height - y_resize - offset)

        return {
            hl.dsp.window.resize({ x = x_resize, y = y_resize, window = win }),
            hl.dsp.window.move({ x = move_x, y = move_y, relative = false, window = win }),
        }
    end
end

-- special ws: open/close, and if empty — launch its app from vars.apps (caelestia toggle replacement).
-- apps read on press, not on load: user.lua loads after binds and changes them there
local function toggle_special(name)
    return function()
        local cmd = vars.apps[name]
        local has_windows = false
        for _, ws in ipairs(hl.get_workspaces()) do
            if ws.name == "special:" .. name and ws.windows > 0 then
                has_windows = true
                cmd = nil
            end
        end
        -- dim screen when scratchpad is empty (only for "special" workspace)
        -- use hl.config() for synchronous immediate effect instead of async hyprctl eval
        if name == "special" then
            local dim = has_windows and 0.0 or 0.3
            hl.config({ decoration = { dim_special = dim } })
        end
-- show first, then launch: hypr opens window where focus was at launch time,
-- and reverse order hid the workspace as soon as window appears
        hl.dispatch(hl.dsp.workspace.toggle_special(name))
        if cmd then hl.exec_cmd(cmd) end
    end
end

-- screen recording via gsr-record wrapper script (handles stop/start, region slurp, audio)
-- Same bind pressed again while recording → stops it
local function record(region, sound)
    return function()
        local args = ""
        if region then args = args .. " --region" end
        if sound  then args = args .. " --sound"  end
        hl.exec_cmd("bash -c 'gsr-record" .. args .. "'")
    end
end

-- Cycle focus between open (occupied) application windows across workspaces
local function cycle_windows(reverse)
    return function()
        local windows = hl.get_windows()
        if not windows or #windows == 0 then return end

        local normal_wins = {}
        for _, w in ipairs(windows) do
            if w.workspace and w.workspace.id and w.workspace.id > 0 and w.mapped ~= false and not w.hidden then
                table.insert(normal_wins, w)
            end
        end

        if #normal_wins == 0 then return end
        if #normal_wins == 1 then
            hl.dispatch(hl.dsp.focus({ window = "address:" .. normal_wins[1].address }))
            return
        end

        table.sort(normal_wins, function(a, b)
            if a.workspace.id ~= b.workspace.id then
                return a.workspace.id < b.workspace.id
            end
            return a.address < b.address
        end)

        local active = hl.get_active_window()
        local current_idx = nil
        if active then
            for idx, w in ipairs(normal_wins) do
                if w.address == active.address then
                    current_idx = idx
                    break
                end
            end
        end

        local next_idx = 1
        if current_idx then
            if reverse then
                next_idx = current_idx - 1
                if next_idx < 1 then next_idx = #normal_wins end
            else
                next_idx = current_idx + 1
                if next_idx > #normal_wins then next_idx = 1 end
            end
        else
            next_idx = reverse and #normal_wins or 1
        end

        local target = normal_wins[next_idx]
        hl.dispatch(hl.dsp.focus({ window = "address:" .. target.address }))
    end
end

-- Toggle active window between tiling and centered floating
local function toggle_floating_centered()
    local win = hl.get_active_window()
    if not win then return end
    if win.floating then
        hl.dispatch(hl.dsp.window.float({ action = "off" }))
    else
        if win.fullscreen and win.fullscreen ~= 0 then
            hl.dispatch(hl.dsp.window.fullscreen({ mode = "none" }))
        end
        hl.dispatch(hl.dsp.window.float({ action = "on" }))
        local screen = hl.get_active_monitor()
        local mon_w = (screen and screen.width) and (screen.width / (screen.scale or 1)) or 1920
        local mon_h = (screen and screen.height) and (screen.height / (screen.scale or 1)) or 1080
        local target_w = math.floor(math.min(960, mon_w * 0.75))
        local target_h = math.floor(math.min(620, mon_h * 0.75))
        hl.dispatch(hl.dsp.window.resize({ x = target_w, y = target_h, relative = false }))
        hl.dispatch(hl.dsp.window.center())
    end
end

return {
    toggle_special           = toggle_special,
    record                   = record,
    cycle_windows            = cycle_windows,
    resizer                  = resizer,
    resize_by_screen         = resize_by_screen,
    resize_active_window     = resize_active_window,
    wsaction                 = wsaction,
    move_actions             = move_actions,
    toggle_floating_centered = toggle_floating_centered,
}
