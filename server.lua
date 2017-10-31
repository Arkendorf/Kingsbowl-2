local gui = require "gui"
local state = require "state"
local game = require "game"
local collision = require "collision"
local server = {}
require "globals"

players = {}
id = 0

server.init = function()
  state.networking = {}
  state.network_mode = "server"
  state.gui = gui.new(menus[2])
  local networking = state.networking
  networking.host = sock.newServer("*", tonumber(ip.port))

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
    if state.game == true then
      networking.host:sendToPeer(networking.host:getPeerByIndex(index), "disconnect")
    else
      players[index] = {name = data.name, team = math.floor(math.random()+1.5)}
      networking.host:sendToPeer(networking.host:getPeerByIndex(index), "id", index)
      networking.host:sendToPeer(networking.host:getPeerByIndex(index), "currentplayers", players)
      networking.host:sendToAll("newplayer", {info = players[index], index = index})
    end
  end)

  networking.host:on("diff", function(data, client)
    local index = client:getIndex()
    players[index].d = data
  end)

  networking.host:on("ballpos", function(data, client)
    game.ball.pos = {x = data.x, y = data.y}
  end)

  networking.host:on("sword", function(data, client)
    local index = client:getIndex()
    players[index].sword = {active = data.active, d = data.d, t = 0}
    if data.active == true then
      players[index].speed = 0
    else
      players[index].speed = 30
    end
    networking.host:sendToAll("sword", {info = data, index = index})
  end)

  networking.host:on("shield", function(data, client)
    local index = client:getIndex()
    players[index].shield = {active = data.active, d = data.d, t = 0}
    if data.active == true then
      players[index].speed = 26
    else
      players[index].speed = 30
    end
    networking.host:sendToAll("shield", {info = data, index = index})
  end)

  networking.host:on("shieldpos", function(data, client)
    local index = client:getIndex()
    players[index].shield.d = data
    networking.host:sendToAll("shieldpos", {info = data, index = index})
  end)
end

server.update = function(dt)
  state.networking.host:update()

  if state.game == true then
    -- collide players
    for i, v in pairs(players) do
      players[i].p.x = players[i].p.x + players[i].d.x*players[i].speed*dt
      players[i].p.y = players[i].p.y + players[i].d.y*players[i].speed*dt
      for j, w in ipairs(players) do
        if i ~= j then
          if collision.check_overlap(players[j], players[i]) then
            local p1, p2 = collision.circle_vs_circle(players[j], players[i]) --
            players[j].p = p1
            players[i].p = p2
          end
        end
      end
    end

    -- send positions
    for i, v in pairs(players) do
      state.networking.host:sendToAll("coords", {info = v.p, index = i})
    end

    -- send ball info
    if game.ball then state.networking.host:sendToAll("ballpos", game.ball.circle.p) end
    if game.ball then state.networking.host:sendToAll("baller", game.ball.baller) end
  end
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
  teams = {{}, {}}
  for i, v in pairs(players) do
    teams[v.team][#teams[v.team]+1] = i
  end

  if #teams[1] > 0 and #teams[2] > 0 then -- only start game if there is at least one person per team
    state.gui = gui.new(menus[4])
    state.networking.host:sendToAll("startgame", players)
    state.networking.host:sendToAll("qb", teams[1][1])
    qb = teams[1][1]
    game.init()
    game.ball.baller = qb
  end
end

return server
