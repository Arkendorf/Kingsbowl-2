local gui = require "gui"
local state = require "state"
local server = {}
require "globals"

server.init = function()
  state.networking = {}
  local networking = state.networking
  state.game = "server"
  networking.host = enet.host_create(ip.ip .. ':' .. ip.port)
  state.gui = gui.new(menus[2])
end

server.update = function(dt)
  local event = state.networking.host:service(100)
  if event and event.type == "receive" then
    print("Got message: ", event.data, event.peer)
    event.peer:send(event.data)
  end
end

return server
