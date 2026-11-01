-- hopparch full profile: the minimal look plus a little polish, same 0xyc
-- colours. Loaded at the end of hyprland.lua; the minimal profile has no such file.

hl.config({
  general = {
    -- cream fading to grey on the focused window
    col = { active_border = { colors = { "rgba(e8e4dcff)", "rgba(8a877fff)" }, angle = 45 } },
  },
  decoration = {
    rounding = 6,
    blur   = { enabled = true, size = 6, passes = 2 },
    shadow = { enabled = true, range = 12, render_power = 3, color = "rgba(00000099)" },
  },
  animations = { enabled = true },
})

-- short and calm: windows pop in, workspaces slide
hl.curve("easeOutQuint", { type = "bezier", points = { {0.23, 1}, {0.32, 1} } })
hl.animation({ leaf = "windows",    enabled = true, speed = 4, bezier = "easeOutQuint", style = "popin 90%" })
hl.animation({ leaf = "border",     enabled = true, speed = 5, bezier = "easeOutQuint" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })

-- game space: Steam games open fullscreen on a workspace of their own
-- ("games", SUPER+G goes there, SUPER+SHIFT+G sends a window there).
-- immediate = tearing allowed: a frame goes out the moment it is ready, the
-- lowest input lag. vrr 2 = adaptive sync only for fullscreen windows, so the
-- desktop never flickers. idle_inhibit: the screen stays on while a game is up.
-- SUPER+Q never closes a game (close.sh): games quit from their own menu.
hl.config({
  general = { allow_tearing = true },
  misc    = { vrr = 2 },
})
hl.window_rule({
  name         = "steam-games",
  match        = { class = "^steam_app_[0-9]+$" },
  fullscreen   = true,
  workspace    = "name:games",
  immediate    = true,
  idle_inhibit = "fullscreen",
})
hl.bind("SUPER + G",         hl.dsp.focus({ workspace = "name:games" }), { description = "Go to the game space" })
hl.bind("SUPER + SHIFT + G", hl.dsp.window.move({ workspace = "name:games" }),
        { description = "Send window to the game space" })
