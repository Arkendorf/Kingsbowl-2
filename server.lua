local gui = require "gui"
local server = {}

server.init = function()
  state.game = "server"
  state.gui = gui.new(menus[2])
end

server.update = function(dt)
end

return server
