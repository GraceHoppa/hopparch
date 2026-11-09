-- hopparch defaults. Your own changes go in ~/.config/hopparch/user.lua, which
-- hopparch never writes or syncs. Each entry: { value, type=, min=, max=, label= }
-- (the settings GUI draws a widget from type/min/max/label).
return {
  -- the order the settings GUI lists the palette in (Lua tables have none)
  palette_order = { "bg", "text", "focus", "dim", "sel", "muted", "alert", "accent", "white" },
  look_order = { "gaps_in", "gaps_out", "border_size", "rounding" },
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
