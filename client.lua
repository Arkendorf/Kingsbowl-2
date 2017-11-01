local state = require "state"
local gui = require "gui"
local game = require "game"
require "globals"
client = {}

local status = "Disconnected"

client.init = function(t)
  state.networking = {}
  state.network_mode = "client"
  state.gui = gui.new(menus[3])
  local networking = state.networking
  networking.peer = sock.newClient(ip.ip, tonumber(ip.port))

  -- initial variables

  -- important functions
  networking.peer:on("connect", function(data)
    status = "Connected"
    networking.peer:send("playerinfo", {name = username[1]})
  end)

  networking.peer:on("disconnect", function(data)
    state.networking.peer:disconnectNow()
    status = "Disconnected"
    state.game = false
    state.gui = gui.new(menus[3])
  end)

  networking.peer:on("id", function(data)
    id = data
  end)

  networking.peer:on("currentplayers", function(data)
    players = data
  end)

  networking.peer:on("newplayer", function(data)
    players[data.index] = data.info
  end)

  networking.peer:on("teamswap", function(data)
    players[data.index].team = data.info
  end)

  networking.peer:on("startgame", function(data)
    state.gui = gui.new(menus[4])
    players = data
    game.init()
  end)

  networking.peer:on("coords", function(data)
    players[data.index].p = data.info
  end)

  networking.peer:on("qb", function(data)
    qb = data
  end)

  networking.peer:on("ballpos", function(data, client)
    if data and not (game.ball.baller == id) then game.ball.circle.p = {x = data.x, y = data.y} end
  end)

  networking.peer:on("newballer", function(data, client)
    if data then
      game.ball.baller = data
    end
  end)

  networking.peer:connect()
  status = "Connecting"
end

client.update = function(dt)
  state.networking.peer:update()
  if state.game == true then
    state.networking.peer:send("diff", players[id].d)
    if game.ball.baller == id then state.networking.peer:send("ballpos", game.ball.circle.p) end
  end
end

client.draw = function()
  if status == "Connected" then
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
  else
    love.graphics.print(status, 41, 2)
  end
end

client.quit = function()
  state.networking.peer:disconnectNow()
end

client.back_to_main = function()
  client.quit()
  state.network_mode = nil
  state.gui = gui.new(menus[1])
end

return client
