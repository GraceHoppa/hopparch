-- hopparch settings loader, the one place settings are merged. Used by
-- hyprland.lua (at every start) and gen-palette.lua (at every sync).
--   local S, warnings = dofile(dir .. "load.lua")(dir, user_file)
-- S = the shipped defaults (<dir>/settings.lua) with your user.lua laid on
-- top, key by key. `.user = true` marks a value you set yourself.
-- user.lua can never stop the caller: a missing file means plain defaults; a
-- broken file, an unknown key or a bad value is skipped and described in
-- `warnings` (a list of strings), and that setting keeps its default.
-- Only entries with a `type` are settings; the lists the GUI reads
-- (palette_order, schemes, ...) can't be overridden.

-- nil = fine, else what is wrong with value v for the setting `entry`
local function bad(entry, v)
  if entry.type == "color" then
    if type(v) ~= "string" or not v:match("^%x%x%x%x%x%x$") then
      return "a colour is six hex digits, like \"e8e4dc\""
    end
  elseif entry.type == "int" then
    if type(v) ~= "number" or v % 1 ~= 0 then return "must be a whole number" end
    if (entry.min and v < entry.min) or (entry.max and v > entry.max) then
      return "must be " .. tostring(entry.min) .. " to " .. tostring(entry.max)
    end
  end
end

local function is_setting(entry) return type(entry) == "table" and entry.type ~= nil end
-- a table of settings (palette), not a setting itself and not a GUI list
local function is_group(entry)
  if type(entry) ~= "table" or entry.type ~= nil then return false end
  for _, e in pairs(entry) do
    if not is_setting(e) then return false end
  end
  return next(entry) ~= nil
end

return function(dir, user_file)
  local S = dofile(dir .. "settings.lua")
  local warnings = {}
  local function warn(key, why) warnings[#warnings + 1] = "user.lua: " .. key .. ": " .. why end
  local function set(entry, key, v)
    local why = bad(entry, v)
    if why then return warn(key, why .. " (default kept)") end
    entry[1] = v
    entry.user = true
  end

  local f = io.open(user_file)
  if not f then return S, warnings end
  f:close()
  local ok, U = pcall(dofile, user_file)
  if not ok then
    warnings[1] = "user.lua is broken, defaults used: " .. tostring(U)
    return S, warnings
  end
  if type(U) ~= "table" then
    warnings[1] = "user.lua must return a table, defaults used"
    return S, warnings
  end

  for k, v in pairs(U) do
    local entry = S[k]
    if is_setting(entry) then
      set(entry, tostring(k), v)
    elseif is_group(entry) and type(v) == "table" then
      for k2, v2 in pairs(v) do
        if is_setting(entry[k2]) then
          set(entry[k2], k .. "." .. tostring(k2), v2)
        else
          warn(k .. "." .. tostring(k2), "no such setting (a typo?)")
        end
      end
    else
      warn(tostring(k), "no such setting (a typo?)")
    end
  end
  table.sort(warnings)
  return S, warnings
end
