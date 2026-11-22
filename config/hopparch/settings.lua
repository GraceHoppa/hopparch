-- hopparch defaults. Your own changes go in ~/.config/hopparch/user.lua, which
-- hopparch never writes or syncs. Each entry: { value, type=, min=, max=, label= }
-- (the settings GUI draws a widget from type/min/max/label).
return {
  -- the order the settings GUI lists the palette in (Lua tables have none)
  palette_order = { "bg", "text", "focus", "dim", "sel", "muted", "alert", "accent", "white" },
  look_order = { "gaps_in", "gaps_out", "border_size", "rounding" },
  apps_order = { "terminal", "browser", "files", "layout" },
  -- whole-palette presets the GUI offers; picking one fills all palette colours
  scheme_order = { "0xyc", "paper", "amber", "nord", "gruvbox", "mono" },
  schemes = {
    ["0xyc"] = { label = "0xyc (default)", bg = "000000", text = "e8e4dc", focus = "e8e4dc", dim = "3a3a38", sel = "2a2a28", muted = "8a877f", alert = "c23d3d", accent = "d0a050", white = "ffffff" },
    paper    = { label = "Paper (light)",  bg = "f4f1ea", text = "22201c", focus = "22201c", dim = "c9c4b8", sel = "e2ddd0", muted = "7a756a", alert = "b3261e", accent = "b5651d", white = "000000" },
    amber    = { label = "Amber",          bg = "0c0a06", text = "f0d9a0", focus = "ffb000", dim = "3d3217", sel = "261e0d", muted = "9a8350", alert = "e5533d", accent = "ffb000", white = "fff3d6" },
    nord     = { label = "Nord-ish",       bg = "2e3440", text = "d8dee9", focus = "88c0d0", dim = "4c566a", sel = "3b4252", muted = "7b88a1", alert = "bf616a", accent = "ebcb8b", white = "eceff4" },
    gruvbox  = { label = "Gruvbox-ish",    bg = "1d2021", text = "ebdbb2", focus = "fabd2f", dim = "504945", sel = "3c3836", muted = "928374", alert = "fb4934", accent = "fe8019", white = "fbf1c7" },
    mono     = { label = "Mono",           bg = "0a0a0a", text = "cfcfcf", focus = "ffffff", dim = "3a3a3a", sel = "222222", muted = "7a7a7a", alert = "c23d3d", accent = "8a8a8a", white = "ffffff" },
  },
  palette = {
    bg    = { "000000", type = "color", label = "Background" },
    focus = { "e8e4dc", type = "color", label = "Focused border" },
    dim   = { "3a3a38", type = "color", label = "Other borders" },
    text   = { "e8e4dc", type = "color", label = "Text" },
    sel    = { "2a2a28", type = "color", label = "Selection" },
    muted  = { "8a877f", type = "color", label = "Muted" },
    alert  = { "c23d3d", type = "color", label = "Alert" },
    accent = { "d0a050", type = "color", label = "Accent" },
    white  = { "ffffff", type = "color", label = "Bright match" },
  },
  gaps_in     = { 4, type = "int", min = 0, max = 40, label = "Gap between windows" },
  gaps_out    = { 8, type = "int", min = 0, max = 80, label = "Gap to screen edge" },
  border_size = { 2, type = "int", min = 0, max = 10, label = "Border width" },
  -- 0 in the minimal profile; `full` is the full profile's default (user.lua wins)
  rounding    = { 0, full = 6, type = "int", min = 0, max = 30, label = "Corner rounding" },

  -- choice: the value is one key of `options`; `option_order` is the GUI's order.
  -- The GUI lists only the apps that are installed (the first word of cmd).
  -- scratch = the terminal started in the scratchpad (SUPER+S), with the window
  -- class "scratchpad": each terminal sets it with its own flag. Only kitty is
  -- tested; the others are from their docs.
  terminal = { "kitty", type = "choice", label = "Terminal",
    option_order = { "kitty", "foot", "alacritty", "wezterm", "ghostty" },
    options = {
      -- -1 = one kitty process for all windows: ~15 MB per extra window instead of ~160
      kitty     = { label = "kitty",     cmd = "kitty -1",  scratch = "kitty -1 --class scratchpad" },
      foot      = { label = "foot",      cmd = "foot",      scratch = "foot --app-id scratchpad" },
      alacritty = { label = "Alacritty", cmd = "alacritty", scratch = "alacritty --class scratchpad" },
      wezterm   = { label = "WezTerm",   cmd = "wezterm",   scratch = "wezterm start --class scratchpad" },
      ghostty   = { label = "Ghostty",   cmd = "ghostty",   scratch = "ghostty --class=scratchpad" },
    } },
  browser = { "firefox", type = "choice", label = "Browser",
    option_order = { "firefox", "chromium", "librewolf", "brave" },
    options = {
      firefox   = { label = "Firefox",   cmd = "firefox" },
      chromium  = { label = "Chromium",  cmd = "chromium" },
      librewolf = { label = "LibreWolf", cmd = "librewolf" },
      brave     = { label = "Brave",     cmd = "brave" },
    } },
  files = { "thunar", type = "choice", label = "File manager",
    option_order = { "thunar", "nautilus", "dolphin", "pcmanfm", "nemo" },
    options = {
      thunar   = { label = "Thunar",   cmd = "thunar" },
      nautilus = { label = "Nautilus", cmd = "nautilus" },
      dolphin  = { label = "Dolphin",  cmd = "dolphin" },
      pcmanfm  = { label = "PCManFM",  cmd = "pcmanfm" },
      nemo     = { label = "Nemo",     cmd = "nemo" },
    } },
  -- Key binds: the combo in Hyprland's own form ("SUPER + SHIFT + S"); what each
  -- one does is in hyprland.lua under the same id. `mods` = only the modifiers
  -- of binds made in a loop (the keys are fixed: `keys`). In user.lua:
  --   binds = { terminal = "SUPER + T",          -- another combo
  --             shot_full = false,               -- off
  --             my_obs = { "SUPER + O", exec = "obs", label = "OBS" } }  -- your own
  -- Two binds on one combo: the first in bind_order keeps it, the other is off
  -- (and reported). Volume, brightness and mute keys stay fixed in hyprland.lua.
  bind_order = { "terminal", "launcher", "browser", "files", "close", "fullscreen",
                 "windows", "scratch", "scratch_send", "focus_dir", "move_dir",
                 "resize_dir", "drag", "ws_go", "ws_send", "shot_full", "shot_region",
                 "clipboard", "kaomoji", "volume_down", "volume_up", "btop", "lock",
                 "power_menu", "reload", "cheatsheet" },
  binds = {
    terminal     = { "SUPER + Return",        type = "bind", label = "Terminal" },
    launcher     = { "SUPER + D",             type = "bind", label = "Launcher (apps, settings, games)" },
    browser      = { "SUPER + B",             type = "bind", label = "Browser" },
    files        = { "SUPER + F",             type = "bind", label = "File manager" },
    close        = { "SUPER + Q",             type = "bind", label = "Close window (not a game)" },
    fullscreen   = { "SUPER + M",             type = "bind", label = "Fullscreen" },
    windows      = { "SUPER + Tab",           type = "bind", label = "Windows list" },
    scratch      = { "SUPER + S",             type = "bind", label = "Scratchpad show/hide" },
    scratch_send = { "SUPER + CTRL + S",      type = "bind", label = "Send window to the scratchpad" },
    focus_dir    = { "SUPER",                 type = "mods", keys = { "H", "J", "K", "L" }, label = "Focus window (+ h j k l)" },
    move_dir     = { "SUPER + SHIFT",         type = "mods", keys = { "H", "J", "K", "L" }, label = "Move window (+ h j k l)" },
    resize_dir   = { "SUPER + CTRL",          type = "mods", keys = { "H", "J", "K", "L" }, label = "Resize window, hold (+ h j k l)" },
    drag         = { "SUPER",                 type = "mods", keys = { "mouse:272", "mouse:273" }, label = "Move / resize window (+ left / right drag)" },
    ws_go        = { "SUPER",                 type = "mods", keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, label = "Go to workspace (+ 1-9)" },
    ws_send      = { "SUPER + SHIFT",         type = "mods", keys = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, label = "Send window to workspace (+ 1-9)" },
    shot_full    = { "SUPER + SHIFT + P",     type = "bind", label = "Screenshot: whole screen" },
    shot_region  = { "SUPER + SHIFT + S",     type = "bind", label = "Screenshot: region" },
    clipboard    = { "SUPER + CTRL + V",      type = "bind", label = "Clipboard history" },
    kaomoji      = { "CTRL + SUPER + period", type = "bind", label = "Kaomoji" },
    volume_down  = { "SUPER + F9",            type = "bind", label = "Volume down" },
    volume_up    = { "SUPER + F10",           type = "bind", label = "Volume up, up to 150%" },
    btop         = { "CTRL + ALT + Delete",   type = "bind", label = "System monitor (btop)" },
    lock         = { "SUPER + SHIFT + Escape", type = "bind", label = "Lock screen" },
    power_menu   = { "SUPER + SHIFT + E",     type = "bind", label = "Power menu" },
    reload       = { "SUPER + SHIFT + R",     type = "bind", label = "Reload Hyprland config" },
    cheatsheet   = { "SUPER + SHIFT + slash", type = "bind", label = "This cheatsheet" },
  },

  -- Hyprland's own tiling layouts (general.layout); no cmd, always offered
  layout = { "dwindle", type = "choice", label = "Window layout",
    option_order = { "dwindle", "master", "scrolling", "monocle" },
    options = {
      dwindle   = { label = "Dwindle (each new window splits the last)" },
      master    = { label = "Master (one big window + a stack)" },
      scrolling = { label = "Scrolling (a row of columns)" },
      monocle   = { label = "Monocle (one window at a time)" },
    } },
}
