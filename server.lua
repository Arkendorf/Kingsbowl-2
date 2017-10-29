local gui = require "gui"
local state = require "state"
local game = require "game"
local server = {}
require "globals"

players = {}
id = 0

server.init = function()
  state.networking = {}
  state.network_mode = "server"
  state.gui = gui.new(menus[2])
  local networking = state.networking
  networking.host = sock.newServer(ip.ip, tonumber(ip.port))

  -- initial variables
  id = 0
  players[0] = {name = username[1], team = math.floor(math.random()+1.5)}

  -- important functions
  networking.host:on("connect", function(data, client)
  end)

  networking.host:on("disconnect", function(data, client)
    local index = client:getIndex()
    players[index] = nil
  end)

  networking.host:on("playerinfo", function(data, client)
    local index = client:getIndex()
    players[index] = {name = data.name, team = math.floor(math.random()+1.5)}
    networking.host:sendToPeer(networking.host:getPeerByIndex(index), "id", index)
    networking.host:sendToPeer(networking.host:getPeerByIndex(index), "currentplayers", players)
    networking.host:sendToAll("newplayer", {info = players[index], index = index})
  end)

  networking.host:on("diff", function(data, client)
    local index = client:getIndex()
    players[index].d = data
  end)
end

server.update = function(dt)
  for i, v in pairs(players) do
    state.networking.host:sendToAll("coords", {info = v.p, index = i})
  end
  state.networking.host:update()
end

server.draw = function()
  love.graphics.print("Players:", 42, 2)
  local j = 1
  for i, v in pairs(players) do
    if v.team == 1 then
      love.graphics.setColor(255, 200, 200)
    else
      love.graphics.setColor(200, 200, 255)
    end
    if i == id then
      love.graphics.rectangle("fill", 41, j*13, font:getWidth(v.name)+1, 12)
      love.graphics.setColor(0, 0, 0)
      love.graphics.print(v.name, 42, j*13+2)
    else
      love.graphics.print(v.name, 42, j*13+2)
    end
    j = j + 1
  end
end

server.mousepressed = function(x, y, button)
  if button == 1 and state.game == false then
    local j = 1
    for i, v in pairs(players) do
      if  x >= 41 and x < 41+font:getWidth(v.name)+1 and y >= j*13 and y <= j*13+12 then
        if v.team == 1 then
          v.team = 2
        else
          v.team = 1
        end
        state.networking.host:sendToAll("teamswap", {index = i, info = v.team})
      end
      j = j + 1
    end
  end
end

server.quit = function()
  state.networking.host:sendToAll("disconnect")
  state.networking.host:update()
  state.networking.host:destroy()
end

server.back_to_main = function()
  server.quit()
  state.network_mode = nil
  state.gui = gui.new(menus[1])
end

server.start_game = function()
  state.gui = gui.new(menus[4])
  state.networking.host:sendToAll("startgame", players)
  game.init()
end

return server
