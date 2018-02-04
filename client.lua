local state = require "state"
local gui = require "gui"
local game = require "game"
local vector = require "vector"
local network = require "network"
require "globals"
local client = {}

status = "Disconnected"

client.init = function(t)
  network.mode = "client"
  state.gui = gui.new(menus[3])
  network.peer = sock.newClient(ip.ip, tonumber(ip.port))

  -- initial variables

  -- important functions
end

client.update = function(dt)
  network.peer:update()
  -- get servers direction
  if state.game == true then
    for i, v in pairs(players) do
      game.set_speed(i)
      v.p.x = v.p.x + v.d.x*v.speed*dt
      v.p.y = v.p.y + v.d.y*v.speed*dt
    end
    game.collide(players[id])
    network.peer:send("posdif", players[id].d)
    if players[id].shield.active == true then
      network.peer:send("shieldpos", game.shield_pos())
    end
    if game.ball.baller == id then network.peer:send("ballpos", game.ball.circle.p) end
  end
end

client.mousepressed = function (x, y, button)
  if button == 1 and state.game == true and players[id].dead == false and game.down.t > grace_time then
    if game.ball.baller ~= id and players[id].team == players[qb].team then
      network.peer:send("shield", {active = true, d = game.shield_pos()})
    elseif players[id].team ~= players[qb].team then
      network.peer:send("sword", {active = true, d = game.sword_pos()})
    end
  end
end

client.mousereleased = function (x, y, button)
  if button == 1 and state.game == true and players[id].shield.active == true then
    network.peer:send("shield", {active = false})
  end
end

client.quit = function()
  network.peer:disconnectNow()
end

client.back_to_main = function()
  client.quit()
  network.mode = nil
  state.gui = gui.new(menus[1])
end

return client
