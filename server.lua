local gui = require "gui"
local state = require "state"
local game = require "game"
local collision = require "collision"
local vector = require "vector"
require "globals"
local server = {}

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
    game.set_speed(index)
    networking.host:sendToAll("sword", {info = data, index = index})
  end)

  networking.host:on("shield", function(data, client)
    local index = client:getIndex()
    players[index].shield = {active = data.active, d = data.d, t = 0}
    game.set_speed(index)
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
      v.p.x = v.p.x + v.d.x*v.speed*dt
      v.p.y = v.p.y + v.d.y*v.speed*dt

      -- collide with line of scrimmage if down has hardly started
      if game.down.t <= grace_time and v.team == 1 and v.p.x+v.r > game.down.start then
        v.d.x = 0
        v.p.x = game.down.start-v.r
      elseif game.down.t <= grace_time and v.team == 2 and v.p.x-v.r < game.down.start then
        v.d.x = 0
        v.p.x = game.down.start+v.r
      end

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

    -- adjust sword and shield info
    for i, v in pairs(players) do
      if v.shield.active == true then v.shield.t = v.shield.t + dt end
      if v.sword.active == true then
        v.sword.t = v.sword.t + dt
        if v.sword.t > sword.t then
          v.sword.active = false
          v.sword.t = 0
          v.speed = speed_table.defense
          state.networking.host:sendToAll("sword", {info = {active = false}, index = i})
        end

        local strike = true
        local sword_pos = vector.sum(v.p, v.sword.d)
        for j, w in pairs(players) do -- check if sword hits shield
          local shield_pos = vector.sum(w.p, w.shield.d)
          if j ~= i and w.shield.active == true and w.dead == false and vector.mag_sq(collision.get_distance(v.p, w.p)) > vector.mag_sq(collision.get_distance(v.p, shield_pos)) and collision.check_overlap({r = shield.r, p = shield_pos}, {r = sword.r, p = sword_pos}) then
            strike = false
          end
        end

        if strike == true then -- if sword didn't hit shield, check if it hit people
          for j, w in pairs(players) do
            if j ~= i and w.dead == false and collision.check_overlap({r = sword.r, p = sword_pos}, w) then
              state.networking.host:sendToAll("dead", j)
              game.kill(j)
              if j == game.ball.baller then
                server.new_down(players[j].p.x)
              end
            end
          end
        end
      end
    end

    -- adjust shield pos
    if players[id].shield.active == true then
      players[id].shield.d = vector.scale(shield_dist, vector.norm(mouse))
    end
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
  elseif button == 1 and state.game == true and players[id].dead == false and game.down.t > grace_time then
    if qb ~= id and players[id].team == players[qb].team then
      players[id].shield = {active = true, d = game.shield_pos(), t = 0}
      players[id].speed = speed_table.shield
    elseif players[id].team ~= players[qb].team then
      players[id].sword = {active = true, d = game.sword_pos(), t = 0}
      players[id].speed = speed_table.sword
    end
  end
end

server.mousereleased = function (x, y, button)
  if button == 1 and state.game == true and players[id].shield.active == true then
    players[id].shield = {active = false, t = 0}
    players[id].speed = speed_table.offense
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
  teams = {{members = {}, qb = 1}, {members = {}, qb = 1}}
  for i, v in pairs(players) do
    teams[v.team].members[#teams[v.team]+1] = i
  end

  if #teams[1].members > 0 and #teams[2].members > 0 then -- only start game if there is at least one person per team
    state.gui = gui.new(menus[4])
    qb = teams[1].members[1]
    state.networking.host:sendToAll("qb", qb)
    state.networking.host:sendToAll("startgame", players)
    game.init()
    game.ball.baller = qb
  end
end

server.new_down = function (x)
  local down = game.down
  local dir = 1
  if down.goal ~= nil and down.goal - down.start > 0 then dir = 1
  else dir = -1 end
  down.start = x
  if down.goal ~= nil and down.start*dir - down.goal*dir > 0 then
    down.num = 1
    down.goal = down.start + field.w/12*dir
    if down.goal > field.w/12*11 or down.goal < field.w/12 then
      down.goal = nil
    end
  else
    down.num = down.num + 1
    if down.num > 4 then
      game.down.num = 1
      server.turnover()
    end
  end
  down.t = 0
  state.networking.host:sendToAll("newdown", game.down)
  game.reset_players()
end

server.turnover = function ()
  local new_team = 1
  if players[qb].team == 1 then
    new_team = 2
  end
  qb = teams[new_team].members[teams[new_team].qb]
  teams[new_team].qb = teams[new_team].qb + 1
  if teams[new_team].qb > #teams[new_team].members then
    teams[new_team].qb = 1
  end
  state.networking.host:sendToAll("qb", qb)
  for i, v in pairs(players) do
    v.sword.active = false
    v.shield.active = false
    game.set_speed(i)
  end
end

return server
