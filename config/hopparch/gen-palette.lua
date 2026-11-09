-- usage: luajit gen-palette.lua <tree>
-- Renders every <file>.tmpl under <tree> into <file> (then removes the .tmpl),
-- with the palette from settings.lua + ~/.config/hopparch/user.lua.
-- Token: @name:fmt@ or @name:fmt=aa@ (aa = alpha, two hex digits)
--   hex  -> #rrggbb[aa]     bare -> rrggbb[aa]     rgba -> rgba(rrggbbaa)
local tree = arg[1]
local home = os.getenv("HOME")

-- the same loader as hyprland.lua: user wins key by key, bad values are skipped
local S, warnings = dofile(tree .. "/hopparch/load.lua")(tree .. "/hopparch/", home .. "/.config/hopparch/user.lua")
for _, w in ipairs(warnings) do io.stderr:write(w, "\n") end

local function colour(name, fmt, alpha)
  local c = S.palette[name]
  assert(c, "unknown colour " .. name)
  local h = c[1]
  if fmt == "hex" then return "#" .. h .. (alpha or "")
  elseif fmt == "bare" then return h .. (alpha or "")
  elseif fmt == "rgba" then return "rgba(" .. h .. (alpha or "ff") .. ")" end
  error("unknown format " .. fmt)
end

for path in io.popen('find "' .. tree .. '" -name "*.tmpl"'):lines() do
  local f = assert(io.open(path))
  local t = f:read("a")
  f:close()
  t = t:gsub("@(%w+):(%w+)=?(%x*)@", function(n, fmt, a)
    return colour(n, fmt, a ~= "" and a or nil)
  end)
  local out = assert(io.open((path:gsub("%.tmpl$", "")), "w"))
  out:write(t)
  out:close()
  os.remove(path)
end
