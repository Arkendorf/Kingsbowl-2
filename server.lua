local gui = require "gui"
local state = require "state"
local server = {}
require "globals"

local players = {}

server.init = function()
  state.networking = {}
  local networking = state.networking
  state.game = "servermenu"
  networking.host = sock.newServer(ip.ip, tonumber(ip.port))
  state.gui = gui.new(menus[2])

  -- important functions
  networking.host:on("connect", function(data, client)
  end)

  networking.host:on("disconnect", function(data, client)
    local index = client:getIndex()
    players[index] = nil
  end)

  networking.host:on("playerinfo", function(data, client)
    local index = client:getIndex()
    players[index] = {name = data.name}
    networking.host:sendToPeer(networking.host:getPeerByIndex(index), "id", index)
  end)
end

server.update = function(dt)
  state.networking.host:update()
end

server.draw = function()
  love.graphics.print("Players:", 1, 0)
  for i, v in pairs(players) do
    love.graphics.print(v.name, 1, i*16)
  end
end

server.quit = function()
  state.networking.host:sendToAll("disconnect", "")
  state.networking.host:update()
  state.networking.host:destroy()
end

return server
