local grease = require "grease.init"
local gui = require "gui"
local server = {}

server.init = function()
  server.grease = grease.udpServer()
  server.grease:listen(25565)
  state.gui = gui.new(menus[2])
end

server.update = function(dt)
  server:update(dt)
end

return server
