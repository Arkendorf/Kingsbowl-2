local state = require "state"
local gui = require "gui"
local game = require "game"
local client_hooks = {}

client_hooks.connect = function(data)
  status = "Connected"
  print(state.gui)
  network.peer:send("playerinfo", {name = username[1]})
end
client_hooks.disconnect = function(data)
  network.peer:disconnectNow()
  status = "Disconnected"
  state.game = false
  state.gui = gui.new(menus[3])
end
client_hooks.playerleft = function(data)
  if state.game == true then
    for i, v in ipairs(teams[players[data].team].members) do
      if v == data then
        table.remove(teams[players[data].team].members, i)
        break
      end
    end
  end
  players[data] = nil
end
client_hooks.id = function(data)
  id = data
end
client_hooks.currentplayers = function(data)
  players = data
end
client_hooks.newplayer = function(data)
  players[data.index] = data.info
end
client_hooks.teamswap = function(data)
  players[data.index].team = data.info
end
client_hooks.startgame = function(data)
  print(1)
  state.gui = gui.new(menus[4])
  players = data
  teams = {{members = {}}, {members = {}}}
  for i, v in pairs(players) do
    teams[v.team].members[#teams[v.team].members+1] = i
  end
  game.init()
end
client_hooks.coords = function(data)
  players[data.index].p = data.info
end
client_hooks.diff = function(data)
  if data.index ~= id then
    players[data.index].p = data.info
  end
end
client_hooks.qb = function(data)
  qb = data
  for i, v in pairs(players) do
    if v.sword and v.shield and qb then
      v.sword.active = false
      v.shield.active = false
      game.set_speed(i)
    end
  end
end
client_hooks.ballpos = function(data, client)
  if data and not (game.ball.baller == id) then game.ball.circle.p = {x = data.x, y = data.y} end
end
client_hooks.newballer = function(data, client)
  if not data then
    players[game.ball.baller].speed = speed_table.offense
  else
    players[data].speed = speed_table.with_ball
  end
  game.ball.baller = data
end
client_hooks.sword = function(data)
  players[data.index].sword = {active = data.info.active, d = data.info.d, t = 0}
end
client_hooks.sheild = function(data)
  players[data.index].shield = {active = data.info.active, d = data.info.d, t = 0}
end
client_hooks.sheildpos = function(data)
  players[data.index].shield.d = data.info
end
client_hooks.dead = function(data)
  game.kill(data)
end
client_hooks.newdown = function(data)
  game.down = data
  game.reset_players()
end
client_hooks.thrown = function(data)
  game.ball.moving = data
end
client_hooks.throw = function(data)
  game.ball.thrown = data
end
client_hooks.touchdown = function(data)
  score[data] = score[data] + 7
end

return client_hooks