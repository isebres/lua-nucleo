-- ensure.lua: tools to ensure correct code behaviour
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)

local error, tostring, pcall, type =
      error, tostring, pcall, type

local math_min = math.min
local string_char = string.char

local tdeepequals, tstr = import 'lua-nucleo/table.lua' { 'tdeepequals', 'tstr' }

-- TODO: Write tests for this one
local ensure = function(msg, value, ...)
  return value
    or error(
        "ensure failed: " .. msg
        .. ((...) and (": " .. (tostring(...) or "?")) or ""),
        2
      )
end

-- TODO: Write tests for this one
local ensure_equals = function(msg, actual, expected)
  return
      (actual ~= expected)
      and error(
          "ensure_equals failed: " .. msg
          .. ": actual `" .. tostring(actual)
          .. "', expected `" .. tostring(expected)
          .. "'",
          2
        )
      or actual -- NOTE: Should be last to allow false and nil values.
end

-- TODO: Write tests for this one
local ensure_tequals = function(msg, actual, expected)
  if type(expected) ~= "table" then
    error(
        "ensure_tequals failed: " .. msg
        .. ": bad expected type, must be `table', got `"
        .. type(expected) .. "'",
        2
      )
  end

  if type(actual) ~= "table" then
    error(
        "ensure_tequals failed: " .. msg
        .. ": bad actual type, expected `table', got `"
        .. type(actual) .. "'",
        2
      )
  end

  -- TODO: Employ tdiff() (when it would be written)

  -- TODO: Use checker to get info on all bad keys!
  for k, expected_v in pairs(expected) do
    local actual_v = actual[k]
    if actual_v ~= expected_v then
      error(
          "ensure_tequals failed: " .. msg
          .. ": bad actual value at key `" .. tostring(k)
          .. "': got `" .. tostring(actual_v)
          .. "', expected `" .. tostring(expected_v)
          .. "'",
          2
        )
    end
  end

  for k, actual_v in pairs(actual) do
    if expected[k] == nil then
      error(
          "ensure_tequals failed: " .. msg
          .. ": unexpected actual value at key `" .. tostring(k)
          .. "': got `" .. tostring(actual_v)
          .. "', should be nil",
          2
        )
    end
  end

  return actual
end

local ensure_tdeepequals = function(msg, actual, expected)
  -- Heavy! Use ensure_tequals if possible
  if not tdeepequals(actual, expected) then
    -- TODO: Bad! Improve error reporting (use tdiff)
    error(
        "ensure_tdeepequals failed: " .. msg .. ":"
        .. "\n  actual: " .. tstr(actual)
        .. "\nexpected: " .. tstr(expected),
        2
      )
  end
end

-- TODO: ?! Improve and generalize!
local strdiff_msg
do
  -- TODO: Generalize?
  local string_window = function(str, pos, window_radius)
    return str:sub(
        math.max(1, pos - window_radius),
        math.min(pos + window_radius, #str)
      )
  end

-- TODO: Uncomment and move to proper tests
--[=[
  assert(string_window("abCde", 3, 0) == [[C]])
  assert(string_window("abCde", 3, 1) == [[bCd]])
  assert(string_window("abCde", 3, 2) == [[abCde]])
  assert(string_window("abCde", 3, 3) == [[abCde]])
--]=]

  local nl_byte = ("\n"):byte()
  strdiff_msg = function(actual, expected, window_radius)
    window_radius = window_radius or 10

    local result = false

    --print(("%q"):format(expected))
    --print(("%q"):format(actual))

    if type(actual) ~= "string" or type(expected) ~= "string" then
      result = "(bad input)"
    else
      local nactual, nexpected = #actual, #expected
      local len = math_min(nactual, nexpected)

      local lineno, lineb = 1, 1
      for i = 1, len do
        local ab, eb = expected:byte(i), actual:byte(i)
        --print(string_char(eb), string_char(ab))
        if ab ~= eb then
          -- TODO: Do not want to have \n-s here. Too low level?!
          result = "different at byte " .. i .. " (line " .. lineno .. ", offset " .. lineb .. "):\n\n  expected   |"
                .. string_window(expected, i, window_radius)
                .. "|\nvs. actual   |"
                .. string_window(actual, i, window_radius)
                .. "|\n\n"
          break
        end
        if eb == nl_byte then
          lineno, lineb = lineno + 1, 1
        end
      end

      if nactual > nexpected then
        result = (result or "different: ") .. "actual has " .. (nactual - nexpected) .. " extra characters"
      elseif nactual < nexpected then
        result = (result or "different:" ) .. "expected has " .. (nexpected - nactual) .. " extra characters"
      end
    end

    return result or "(identical)"
  end
end

local ensure_strequals = function(msg, actual, expected, ...)
  if actual == expected then
    return actual, expected, ...
  end

  error(
      "ensure_strequals: " .. msg .. ":\n"
      .. strdiff_msg(actual, expected)
      .. "\nactual:\n" .. actual
      .. "\nexpected:\n" .. expected
    )
end

local ensure_error = function(msg, expected_message, res, actual_message, ...)
  if res ~= nil then
    error(
        "ensure_error failed: " .. msg .. ": failure expected, got non-nil result: `" .. tostring(res) .. "'",
        2
      )
  end

  -- TODO: Improve error reporting
  ensure_strequals(msg, actual_message, expected_message)

  if select("#", ...) ~= 0 then
    error(
        "ensure_error failed: " .. msg .. ": got extra arguments",
        2
      )
  end
end

-- TODO: Uncomment and move to proper tests
--[[
ensure_error("ok", "a", nil, "a")
ensure_error("bad1", "a", nil, "a", nil)
ensure_error("bad2", "a", nil, "b")
ensure_error("bad3", "a", true, "a")
--]]

-- TODO: Write tests for this one
local ensure_fails_with_substring = function(msg, fn, substring)
  local res, err = pcall(fn)

  if res ~= false then
    error("ensure_fails_with_substring failed: " .. msg .. ": call was expected to fail, but did not")
  end

  if type(err) ~= "string" then
    error("ensure_fails_with_substring failed: " .. msg .. ": call failed with non-string error")
  end

  if not err:find(substring) then
    error(
        "ensure_fails_with_substring failed: " .. msg
        .. ": can't find expected substring `" .. tostring(substring)
        .. "' in error message:\n" .. err
      )
  end
end

return
{
  ensure = ensure;
  ensure_equals = ensure_equals;
  ensure_tequals = ensure_tequals;
  ensure_tdeepequals = ensure_tdeepequals;
  ensure_strequals = ensure_strequals;
  ensure_error = ensure_error;
  ensure_fails_with_substring = ensure_fails_with_substring;
}
