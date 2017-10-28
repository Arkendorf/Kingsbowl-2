local state = require "state"
local gui = require "gui"
local client = {}

client.init = function(t)
  state.game = "client"
  state.gui = gui.new(menus[3])
end

function client.update(dt)
end

return client
