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

-- the modifier names a key combo may use, and the one each stands for
local MODS = { SUPER = "SUPER", SHIFT = "SHIFT", CTRL = "CTRL", CONTROL = "CTRL", ALT = "ALT" }

-- "super+ shift + s" -> "SHIFT+SUPER+S": the same combo however it is written
local function norm(combo)
  local mods, key = {}, ""
  -- (Hyprland's Lua: a for-loop variable can't be assigned, hence `w`)
  for part in combo:gmatch("[^+]+") do
    local w = part:match("^%s*(.-)%s*$"):upper()
    if MODS[w] then mods[#mods + 1] = MODS[w] else key = w end
  end
  table.sort(mods)
  return table.concat(mods, "+") .. "+" .. key
end

-- every combo a bind takes: one, or its modifiers with each of its keys
local function combos(entry)
  if not entry[1] then return {} end
  if entry.type == "bind" then return { entry[1] } end
  local out = {}
  for _, k in ipairs(entry.keys) do out[#out + 1] = entry[1] .. " + " .. k end
  return out
end

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
  elseif entry.type == "choice" then
    if type(v) ~= "string" or not entry.options[v] then
      return "must be one of: " .. table.concat(entry.option_order, ", ")
    end
  elseif entry.type == "bind" or entry.type == "mods" then
    if v == false then return end                -- off
    if type(v) ~= "string" then return "a key combo like \"SUPER + T\", or false (off)" end
    local mods, key = 0, 0
    for t in v:gmatch("[^+]+") do
      if MODS[t:match("^%s*(.-)%s*$"):upper()] then mods = mods + 1 else key = key + 1 end
    end
    if entry.type == "mods" and (key > 0 or mods == 0) then
      return "only modifiers here (SUPER, SHIFT, CTRL, ALT), like \"SUPER + SHIFT\""
    end
    if entry.type == "bind" and key ~= 1 then
      return "one key plus modifiers, like \"SUPER + T\""
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
        elseif k == "binds" and type(k2) == "string" and type(v2) == "table" then
          -- one of your own: { "SUPER + O", exec = "obs", label = "OBS" }
          local b = { false, type = "bind", label = v2.label or v2.exec, exec = v2.exec, custom = true }
          if type(v2.exec) ~= "string" or v2.exec == "" then
            warn("binds." .. k2, "your own bind needs exec = \"the command\" (left out)")
          else
            set(b, "binds." .. k2, v2[1])
            if b[1] then entry[k2] = b end
          end
        else
          warn(k .. "." .. tostring(k2), "no such setting (a typo?)")
        end
      end
    else
      warn(tostring(k), "no such setting (a typo?)")
    end
  end

  -- one combo, one bind: the first in bind_order (then your own, by name) keeps
  -- it, a later one is turned off
  local order, mine = {}, {}
  for _, id in ipairs(S.bind_order) do order[#order + 1] = id end
  for id, b in pairs(S.binds) do if b.custom then mine[#mine + 1] = id end end
  table.sort(mine)
  for _, id in ipairs(mine) do order[#order + 1] = id end
  local taken = {}
  for _, id in ipairs(order) do
    local b, clash = S.binds[id], nil
    for _, c in ipairs(combos(b)) do clash = clash or taken[norm(c)] end
    if clash then
      warn("binds." .. id, b[1] .. " is already " .. clash .. " (this one is off)")
      b[1] = false
    else
      for _, c in ipairs(combos(b)) do taken[norm(c)] = S.binds[id].label end
    end
  end
  table.sort(warnings)
  return S, warnings
end
