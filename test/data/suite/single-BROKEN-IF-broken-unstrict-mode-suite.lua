--------------------------------------------------------------------------------
-- single-BROKEN-strict-mode-suite.lua: suite used for full suite tests
-- This file is a part of lua-nucleo library
-- Copyright (c) lua-nucleo authors (see file `COPYRIGHT` for the license)
--------------------------------------------------------------------------------

local make_suite = select(1, ...)
local test = make_suite(
    "single-BROKEN-IF-broken-unstrict-mode-suite",
    {
      intentionally_broken_test2 = true;
      intentionally_broken_test3 = true;
    }
  )
test:set_strict_mode(false)
test:BROKEN_IF(true) "intentionally_broken_test1" (function()
  suite_tests_results = suite_tests_results + 1
end)
test:BROKEN_IF(true):test_for "intentionally_broken_test2" (function()
  suite_tests_results = suite_tests_results + 1
end)
test:test_for("intentionally_broken_test3"):BROKEN_IF(true) (function()
  suite_tests_results = suite_tests_results + 1
end)
