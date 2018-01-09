
local state = require "state"
local game = require "game"

local server_hooks = {}

server_hooks.connect = function(data, client)
end
server_hooks.disconnect = function(data, client)
  if state.game == true then
    local index = client:getIndex()
    local team = players[index].team
    for i, v in ipairs(teams[team].members) do
      if v == index then
        table.remove(teams[team].members, i)
        break
      end
    end
    if index == qb then
      qb = teams[team].qb
      teams[team].qb = teams[team].qb + 1
      if teams[team].qb > #teams[team].members then
        teams[team].qb = 1
      end
      network.host:sendToAll("qb", qb)
    end
    if index == game.ball.baller then
      game.ball.baller = false
      if #teams[players[index].team].members > 0 then
        server.new_down(players[index].p.x)
      end
    end
  end
  if players[index] then
    players[index] = nil
  end
  network.host:sendToAll("playerleft", index)
end
server_hooks.playerinfo = function(data, client)
  local index = client:getIndex()
  if state.game == true then
    network.host:sendToPeer(network.host:getPeerByIndex(index), "disconnect")
  else
    players[index] = {name = data.name, team = math.floor(math.random()+1.5)}
    network.host:sendToPeer(network.host:getPeerByIndex(index), "id", index)
    network.host:sendToPeer(network.host:getPeerByIndex(index), "currentplayers", players)
    network.host:sendToAll("newplayer", {info = players[index], index = index})
  end
end
server_hooks.diff = function(data, client)
  local index = client:getIndex()
  players[index].d = data
end
server_hooks.ballpos = function(data, client)
  game.ball.circle.p = data
end
server_hooks.newballer = function(data, client)
  if not data then
    players[game.ball.baller].speed = speed_table.offense
  else
    players[data].speed = speed_table.with_ball
  end
  game.ball.baller = data
end
server_hooks.sword = function(data, client)
  local index = client:getIndex()
  players[index].sword = {active = data.active, d = data.d, t = 0}
  game.set_speed(index)
  network.host:sendToAll("sword", {info = data, index = index})
end
server_hooks.shield = function(data, client)
  local index = client:getIndex()
  players[index].shield = {active = data.active, d = data.d, t = 0}
  game.set_speed(index)
  network.host:sendToAll("shield", {info = data, index = index})
end
server_hooks.shieldpos = function(data, client)
  local index = client:getIndex()
  players[index].shield.d = data
  network.host:sendToAll("shieldpos", {info = data, index = index})
end
server_hooks.thrown = function(data)
  game.ball.moving = data
  network.host:sendToAll("thrown", data)
end
server_hooks.throw = function(data, client)
  game.ball.thrown = data
end
return server_hooks