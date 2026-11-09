-- hopparch defaults. Your own changes go in ~/.config/hopparch/user.lua, which
-- hopparch never writes or syncs. Each entry: { value, type=, min=, max=, label= }
-- (the settings GUI draws a widget from type/min/max/label).
return {
  -- the order the settings GUI lists the palette in (Lua tables have none)
  palette_order = { "bg", "text", "focus", "dim", "sel", "muted", "alert", "accent", "white" },
  look_order = { "gaps_in", "gaps_out", "border_size", "rounding" },
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
}
