-- hopparch -- Hyprland config (Lua, Hyprland >= 0.55). Reload: SUPER+SHIFT+R

local mod      = "SUPER"
local scripts  = os.getenv("HOME") .. "/.config/scripts"


hl.on("hyprland.start", function()
  -- ~/Vault passphrase prompt. Quiet until the vault exists (~/.cipher).
  hl.exec_cmd(scripts .. "/unlock-vault.sh")
  -- the top bar; its top-left icon shows/hides the mouse bar (waybar/mouse.jsonc)
  hl.exec_cmd("waybar")
  -- notifications (screenshot saved, app messages)
  hl.exec_cmd("mako")
  -- lock before any sleep; laptops sleep after 10 min idle (hypridle.conf)
  hl.exec_cmd("hypridle")
  -- clipboard history for SUPER+CTRL+V: record every copy, text and images.
  -- Wiped first at every login, so nothing copied lasts past a restart.
  hl.exec_cmd("cliphist wipe; wl-paste --type text --watch cliphist store & wl-paste --type image --watch cliphist store")
  -- picture at ~/.config/hopparch/wallpaper, if there is one. Otherwise black.
  hl.exec_cmd(scripts .. "/wallpaper.sh")
  -- Steam's games only under "Games" in SUPER+D, not in the main list
  hl.exec_cmd(scripts .. "/games.sh hide")
  -- Mullvad's app, only when its own "Launch app on start-up" is on (that
  -- writes this autostart file; Hyprland doesn't read autostart by itself).
  -- With "Start minimized" it goes straight to the bar's tray.
  hl.exec_cmd("[ -e ~/.config/autostart/mullvad-vpn.desktop ] && mullvad-vpn")
  -- X11 apps draw at full resolution (xwayland.force_zero_scaling below), so
  -- Steam scales its own UI to the first monitor's scale instead of being
  -- stretched blurry. Read here: monitors exist only once Hyprland runs.
  local p = io.popen("hyprctl monitors -j | jq -r '.[0].scale'")
  local scale = p and tonumber(p:read("*l"))
  if p then p:close() end
  if scale and scale ~= 1 then hl.env("STEAM_FORCE_DESKTOPUI_SCALING", tostring(scale)) end
end)


-- NVIDIA drawing the screen: video decoding and GLX go to NVIDIA. The GPU
-- Hyprland draws on is the one with a laptop's built-in panel, else the
-- firmware's boot GPU (aquamarine's rule). Not on hybrid laptops drawing on
-- the iGPU: there these would break video decoding (VA-API). Checked at every
-- start, so a changed card needs nothing redone.
local function nvidia_draws_the_screen()
  if os.getenv("AQ_DRM_DEVICES") then return false end  -- VM mode / hybrid: Hyprland is on the iGPU
  local p = io.popen("grep -l '^connected$' /sys/class/drm/card*-eDP-*/status /sys/class/drm/card*-LVDS-*/status" ..
                     " /sys/class/drm/card*-DSI-*/status 2>/dev/null; grep -l '^1$' /sys/bus/pci/devices/*/boot_vga 2>/dev/null")
  local first = p and p:read("*l")
  if p then p:close() end
  if not first then return false end
  local card = first:match("^/sys/class/drm/(card%d+)%-")
  local f = io.open(card and ("/sys/class/drm/" .. card .. "/device/vendor") or (first:gsub("boot_vga$", "vendor")))
  local vendor = f and f:read("*l")
  if f then f:close() end
  local drm = io.open("/sys/module/nvidia_drm")
  if drm then drm:close() end
  return vendor == "0x10de" and drm ~= nil
end
if nvidia_draws_the_screen() then
  hl.env("LIBVA_DRIVER_NAME", "nvidia")
  hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
end


-- any monitor: highest refresh rate, automatic scale
hl.monitor({ output = "", mode = "highrr", position = "auto", scale = "auto" })


-- A problem in a file that is yours or optional must never take the config
-- down: it is shown on screen (Hyprland's own notification, no mako needed)
-- and kept with the time in ~/.local/state/hopparch/hyprland-errors.log.
local function report(text)
  local log = io.open(os.getenv("HOME") .. "/.local/state/hopparch/hyprland-errors.log", "a")
  if log then
    log:write(os.date("%Y-%m-%d %H:%M:%S"), "  ", text, "\n")
    log:close()
  end
  if hl.notification then
    pcall(hl.notification.create, { text = text, timeout = 20000, icon = 3 })
  end
end

-- settings: shipped defaults (~/.config/hopparch/settings.lua), then your own
-- ~/.config/hopparch/user.lua on top, key by key (load.lua, shared with the
-- palette generator). A missing or broken user.lua means plain defaults; a
-- typo or a bad value in it is reported and that setting keeps its default.
-- Global, so profile.lua can read it too. `.user` marks a value you set yourself.
local settings_dir = os.getenv("HOME") .. "/.config/hopparch/"
local warnings
hopparch, warnings = dofile(settings_dir .. "load.lua")(settings_dir, settings_dir .. "user.lua")
for _, w in ipairs(warnings) do report(w) end
local cfg = hopparch

-- the default apps (settings.lua; HoppCong's Apps page). Global, so the mouse
-- bar's buttons run the same ones: hyprctl dispatch 'hl.dsp.exec_cmd(apps.browser)'
local function app(name) return cfg[name].options[cfg[name][1]] end
apps = {
  terminal = app("terminal").cmd,
  scratch  = app("terminal").scratch,   -- the same terminal, window class "scratchpad"
  browser  = app("browser").cmd,
  files    = app("files").cmd,
}
local terminal, browser, files = apps.terminal, apps.browser, apps.files

-- plain look: nothing that costs GPU time
hl.config({
  general = {
    gaps_in = cfg.gaps_in[1],
    gaps_out = cfg.gaps_out[1],
    border_size = cfg.border_size[1],
    layout = cfg.layout[1],
    col = {
      -- 0xyc: cream = focused, dark grey = the rest
      active_border   = "rgba(" .. cfg.palette.focus[1] .. "ff)",
      inactive_border = "rgba(" .. cfg.palette.dim[1] .. "ff)",
    },
  },
  decoration = {
    rounding = cfg.rounding[1],
    blur   = { enabled = false },
    shadow = { enabled = false },
  },
  animations = { enabled = false },
  input = {
    -- us first; ua is second and is switched only from the mouse bar (no key bind)
    kb_layout = "us,ua",
    -- held keys repeat after 0.3 s, 50x per second (defaults: 0.6 s, 25x)
    repeat_delay = 300,
    repeat_rate = 50,
    -- focus follows clicks and keys only, never the mouse passing by
    follow_mouse = 0,
  },
  -- X11 apps (Steam, games) at the screen's real resolution, not drawn small
  -- and stretched by the monitor scale. Steam's own scale: see hyprland.start.
  xwayland = { force_zero_scaling = true },
  -- no "Hyprland updated" news window, no donation reminder
  ecosystem = {
    no_update_news = true,
    no_donation_nag = true,
  },
  misc = {
    disable_hyprland_logo = true,
    -- the built-in jokes ("Hyper".replace...) are a fixed list inside Hyprland.
    -- there is no custom phrase. This turns that line off.
    disable_splash_rendering = true,
    force_default_wallpaper = 0,
    background_color = "rgba(" .. cfg.palette.bg[1] .. "ff)",
  },
})


-- volume keys: 5% steps up to 100%; with SUPER held up to 150% (software
-- boost, can distort). locked = also work on the lock screen
local vol = "wpctl set-volume "
local sink = " @DEFAULT_AUDIO_SINK@ "
local function media(d) return { locked = true, repeating = true, description = d } end

-- Key binds. The keys are settings (settings.lua `binds`, yours in user.lua,
-- HoppCong's Keybinds page); this is what each one does, by the same id.
-- A bind set to false is off; one of your own runs its `exec`.
local act = {
  terminal     = { hl.dsp.exec_cmd(terminal) },
  launcher     = { hl.dsp.exec_cmd(scripts .. "/launcher.sh") },
  browser      = { hl.dsp.exec_cmd(browser) },
  files        = { hl.dsp.exec_cmd(files) },
  -- btop, almost the whole screen. btop.sh picks the cell count from this monitor.
  btop         = { hl.dsp.exec_cmd(scripts .. "/btop.sh") },
  -- close.sh: closes the focused window, but never a game (full profile)
  close        = { hl.dsp.exec_cmd(scripts .. "/close.sh") },
  fullscreen   = { hl.dsp.window.fullscreen({ mode = "fullscreen" }) },
  reload       = { hl.dsp.exec_cmd("hyprctl reload") },
  -- power menu from the keyboard (the bar's power icon opens the same one)
  power_menu   = { hl.dsp.exec_cmd(scripts .. "/power-menu.sh") },
  -- lock the screen (hyprlock.conf: black, one line of text, password)
  lock         = { hl.dsp.exec_cmd("pidof hyprlock || hyprlock") },
  -- screenshots: path of the saved file is copied (screenshot.sh)
  shot_full    = { hl.dsp.exec_cmd(scripts .. "/screenshot.sh full") },
  shot_region  = { hl.dsp.exec_cmd(scripts .. "/screenshot.sh region") },
  clipboard    = { hl.dsp.exec_cmd(scripts .. "/clipboard.sh") },
  -- kaomoji: copied (paste with Ctrl+V); your own list first, folders, + add
  kaomoji      = { hl.dsp.exec_cmd(scripts .. "/kaomoji.sh") },
  -- volume without volume keys (default SUPER+F9 down, SUPER+F10 up to 150%)
  volume_down  = { hl.dsp.exec_cmd(vol .. sink .. "5%-"), media() },
  volume_up    = { hl.dsp.exec_cmd(vol .. "-l 1.5" .. sink .. "5%+"), media() },
  -- every open window in a list, the last used first: pick one to go there
  -- (the mouse bar's window button opens the same list)
  windows      = { hl.dsp.exec_cmd(scripts .. "/windows.sh") },
  -- scratchpad (see below): show/hide it, send the focused window there
  scratch      = { hl.dsp.workspace.toggle_special("scratch") },
  scratch_send = { hl.dsp.window.move({ workspace = "special:scratch", follow = false }) },
  -- cheatsheet: every bind with its description, the nvim keys, fish aliases
  cheatsheet   = { hl.dsp.exec_cmd(scripts .. "/cheatsheet.sh") },
}
local B = cfg.binds
for id, b in pairs(B) do
  local a = act[id] or (b.exec and { hl.dsp.exec_cmd(b.exec) })
  if b.type == "bind" and b[1] and a then
    local opts = {}
    for k, v in pairs(a[2] or {}) do opts[k] = v end
    opts.description = b.label
    hl.bind(b[1], a[1], opts)
  end
end
-- the binds made in loops: their modifiers are settings ("mods"), the keys are not
local function with(id, key) return B[id][1] and (B[id][1] .. " + " .. key) end

-- HoppCong records a key combo in an empty submap: no bind runs, every key
-- reaches HoppCong. It leaves the submap itself (at most 10 s); SUPER+Escape
-- always gets you out too.
hl.define_submap("hoppcong-keys", function()
  hl.bind("SUPER + Escape", hl.dsp.submap("reset"))
end)

hl.bind("XF86AudioRaiseVolume",            hl.dsp.exec_cmd(vol .. "-l 1.0" .. sink .. "5%+"), media("Volume up"))
hl.bind(mod .. " + XF86AudioRaiseVolume",  hl.dsp.exec_cmd(vol .. "-l 1.5" .. sink .. "5%+"), media("Volume up, up to 150%"))
hl.bind("XF86AudioLowerVolume",            hl.dsp.exec_cmd(vol .. sink .. "5%-"), media("Volume down"))
hl.bind(mod .. " + XF86AudioLowerVolume",  hl.dsp.exec_cmd(vol .. sink .. "5%-"), media("Volume down"))
hl.bind("XF86AudioMute",    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),   { locked = true, description = "Mute" })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, description = "Mute microphone" })
-- brightness keys: 5% steps, never below 1% (0 = a black screen on some laptops).
-- brightness.sh picks the device that is wired to the panel.
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(scripts .. "/brightness.sh up"), media("Brightness up"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(scripts .. "/brightness.sh down"), media("Brightness down"))

-- apps asking to maximize themselves (firefox does) are ignored; otherwise
-- every window opened after them inherits "maximized" and covers the rest
hl.window_rule({
  name  = "no-self-maximize",
  match = { class = ".*" },
  suppress_event = "maximize",
})

-- btop floats above everything, on every workspace, in the middle
hl.window_rule({
  name   = "btop",
  match  = { class = "^(btop)$" },
  float  = true,
  pin    = true,
  center = true,
})

-- HoppCong (the settings GUI) floats in the middle, like btop
hl.window_rule({
  name   = "hoppcong",
  match  = { class = "^dev\\.hopparch\\.hoppcong$" },
  float  = true,
  center = true,
})


-- windows: hjkl = focus, +SHIFT = move, +CTRL = resize (hold)
local step = 40
for _, d in ipairs({
  { "H", "left",  -step, 0 },
  { "J", "down",  0,  step },
  { "K", "up",    0, -step },
  { "L", "right", step,  0 },
}) do
  local key, dir, rx, ry = d[1], d[2], d[3], d[4]
  if B.focus_dir[1] then
    hl.bind(with("focus_dir", key), hl.dsp.focus({ direction = dir }),
            { description = "Focus " .. dir })
  end
  if B.move_dir[1] then
    hl.bind(with("move_dir", key), hl.dsp.window.move({ direction = dir }),
            { description = "Move window " .. dir })
  end
  if B.resize_dir[1] then
    hl.bind(with("resize_dir", key), hl.dsp.window.resize({ x = rx, y = ry, relative = true }),
            { repeating = true, description = "Resize window " .. dir .. " (hold)" })
  end
end

-- mouse: SUPER + left drag moves, SUPER + right drag resizes
if B.drag[1] then
  hl.bind(with("drag", "mouse:272"), hl.dsp.window.drag(),   { mouse = true, description = "Move window (drag)" })
  hl.bind(with("drag", "mouse:273"), hl.dsp.window.resize(), { mouse = true, description = "Resize window (drag)" })
end


-- workspaces 1-9: go there, +SHIFT sends the window there
for i = 1, 9 do
  if B.ws_go[1] then
    hl.bind(with("ws_go", i), hl.dsp.focus({ workspace = i }),
            { description = "Go to workspace " .. i })
  end
  if B.ws_send[1] then
    hl.bind(with("ws_send", i), hl.dsp.window.move({ workspace = i }),
            { description = "Send window to workspace " .. i })
  end
end

-- scratchpad: a hidden workspace shown over the current one. SUPER+S
-- shows/hides it; whenever it is empty, showing it opens a terminal in it.
-- SUPER+CTRL+S puts the focused window there (SUPER+SHIFT+1-9 takes it back).
-- The terminal is found by its class: with kitty -1 the window belongs to the
-- kitty already running, so Hyprland can't tell it was started for here.
hl.on("workspace.created", function(ws)
  if ws.name == "special:scratch" and ws.is_empty then
    hl.exec_cmd(apps.scratch)
  end
end)
hl.window_rule({
  name      = "scratchpad",
  match     = { class = "^(scratchpad)$" },
  workspace = "special:scratch silent",
})


-- Optional extra files, loaded through pcall: a broken one must never take the
-- rest of the config down. Its error is reported (see report() above).
local function load_optional(path, what)
  local f = io.open(path)
  if not f then return end
  f:close()
  local ok, err = pcall(dofile, path)
  if not ok then report(what .. " failed: " .. tostring(err)) end
end

local hypr = os.getenv("HOME") .. "/.config/hypr/"
-- what the profile adds (full: animations, blur, rounding, Steam rule). Lives in
-- profiles/full/config/hypr/profile.lua; minimal has no such file, so this
-- config alone is the minimal look.
load_optional(hypr .. "profile.lua", "profile.lua (the profile look is off)")
-- your own binds and settings: hopparch never ships or syncs a local.lua, so it
-- survives every update. Loaded last, so it can override anything above.
load_optional(hypr .. "local.lua", "local.lua (your own settings are off)")
