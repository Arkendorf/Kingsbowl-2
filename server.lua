local gui = require "gui"
local state = require "state"
local server = {}
require "globals"

local players = {}
local id = 0

server.init = function()
  state.networking = {}
  state.game = "servermenu"
  state.gui = gui.new(menus[2])
  local networking = state.networking
  networking.host = sock.newServer(ip.ip, tonumber(ip.port))

  -- initial variables
  players[0] = {name = username[1]}

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
    networking.host:sendToPeer(networking.host:getPeerByIndex(index), "currentplayers", players)
    state.networking.host:sendToAll("newplayer", {info = players[index], index = index})
  end)
end

server.update = function(dt)
  state.networking.host:update()
end

server.draw = function()
  love.graphics.print("Players:", 2, 2)
  local j = 1
  for i, v in pairs(players) do
    if i == id then
      love.graphics.rectangle("fill", 1, j*13, font:getWidth(v.name)+1, 12)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(v.name, 2, j*13+2)
      love.graphics.setColor(255, 255, 255)
    else
      love.graphics.print(v.name, 2, j*13+2)
    end
    j = j + 1
  end
end

server.quit = function()
  state.networking.host:sendToAll("disconnect")
  state.networking.host:update()
  state.networking.host:destroy()
end

return server
