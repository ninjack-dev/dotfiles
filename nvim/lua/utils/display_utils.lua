local M = {}

local ordinal_suffixes = {
  ["1"] = "st",
  ["2"] = "nd",
  ["3"] = "rd",
  ["11"] = "th",
  ["12"] = "th",
  ["13"] = "th",
  ["14"] = "th",
  ["15"] = "th",
  ["16"] = "th",
  ["17"] = "th",
  ["18"] = "th",
  ["19"] = "th",
}

---Returns a number as an ordinal string, e.g. 1st, 23rd
---@param i integer
---@return string
function M.ordinal(i)
  local str = tostring(i)
  local suffix = ordinal_suffixes[str:sub(-2)] or ordinal_suffixes[str:sub(-1)] or "th"
  return str .. suffix
end

return M
