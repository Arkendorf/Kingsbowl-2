local state = require "state"
local gui = require "gui"
require "globals"
client = {}

client.init = function(t)
  state.networking = {}
  local networking = state.networking
  state.game = "client"
  networking.host = enet.host_create()
  networking.server = networking.host:connect(ip.ip .. ':' .. ip.port)
  state.gui = gui.new(menus[3])
end

client.update = function(dt)
  local event = state.networking.host:service(100)
  if event then
      if event.type == "connect" then
        print("Connected to", event.peer)
    end
  end
end

client.disconnect = function()
  state.networking.server:disconnect()
  state.networking.host:flush()
end

return client
