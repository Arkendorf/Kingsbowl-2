local keytable_mt = {
  __index = function()
    return function() end
  end
}
local down = setmetatable({},keytable_mt)
local up = setmetatable({},keytable_mt)

return {
  down,
  up
}
