local state = require "state"
local gui = require "gui"
local game = require "game"
local vector = require "vector"
local network = require "network"
require "globals"
local client = {}

local client_hooks = {
  connect = function(data)
    network.peer:send("playerinfo", {name = username[1]})
  end,
  disconnect = function(data)
    state.game = false
    client.back_to_main()
  end,
  playerleft = function(data)
    if state.game == true then
      for i, v in ipairs(teams[players[data].team].members) do
        if v == data then
          table.remove(teams[players[data].team].members, i)
          break
        end
      end
    end
    players[data] = nil
  end,
  coords = function(data)
    players[data.index].p = data.info
  end,
  diff = function(data)
    if data.index ~= id then
      players[data.index].p = data.info
    end
  end,
  qb = function(data)
    qb = data
    for i, v in pairs(players) do
      if v.sword and v.shield and qb then
        v.sword.active = false
        v.shield.active = false
        game.set_speed(i)
      end
    end
  end,
  ballpos = function(data, client)
    if data and not (game.ball.baller == id) then game.ball.circle.p = {x = data.x, y = data.y} end
  end,
  newballer = function(data, client)
    if not data then
      players[game.ball.baller].speed = speed_table.offense
    else
      players[data].speed = speed_table.with_ball
    end
    game.ball.baller = data
  end,
  sword = function(data)
    players[data.index].sword = {active = data.info.active, d = data.info.d, t = 0}
  end,
  sheild = function(data)
    players[data.index].shield = {active = data.info.active, d = data.info.d, t = 0}
  end,
  sheildpos = function(data)
    players[data.index].shield.d = data.info
  end,
  dead = function(data)
    game.kill(data)
  end,
  newdown = function(data)
    game.down = data
    game.reset_players()
  end,
  thrown = function(data)
    game.ball.moving = data
  end,
  throw = function(data)
    game.ball.thrown = data
  end,
  touchdown = function(data)
    score[data] = score[data] + 7
  end
}


client.init = function(t)
  for k,v in pairs(client_hooks) do
    network.peer:on(k, v)
  end
end

client.update = function(dt)
  network.peer:update()
  if state.game == true then
    for i, v in pairs(players) do
      game.set_speed(i)
      v.p.x = v.p.x + v.d.x*v.speed*dt
      v.p.y = v.p.y + v.d.y*v.speed*dt
    end
    game.collide(players[id])
    network.peer:send("diff", players[id].d)
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
