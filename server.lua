local gui = require "gui"
local state = require "state"
local game = require "game"
local collision = require "collision"
local vector = require "vector"
require "globals"
local server = {}
local delete_this_later = false
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
        state.networking.host:sendToAll("qb", qb)
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
    state.networking.host:sendToAll("playerleft", index)
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
    game.ball.circle.p = data
  end)

  networking.host:on("newballer", function(data, client)
    if not data then
      players[game.ball.baller].speed = speed_table.offense
    else
      players[data].speed = speed_table.with_ball
    end
    game.ball.baller = data
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

  networking.host:on("thrown", function(data)
    game.ball.moving = data
    state.networking.host:sendToAll("thrown", data)
  end)
  networking.host:on("throw", function(data, client)
    game.ball.thrown = data
  end)
end

server.update = function(dt)
  for i, v in pairs(players) do
    state.networking.host:sendToAll("coords", {info = v.p, index = i})
  end
  if game.ball then
    state.networking.host:sendToAll("ballpos", game.ball.circle.p)
  end
  state.networking.host:update()

  if state.game == true then
    for i, v in pairs(players) do -- move players
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

      -- collide with field edges
      if v.p.x-v.r < 0 then -- x
        v.d.x = 0
        v.p.x = v.r
      elseif v.p.x+v.r > field.w then
        v.d.x = 0
        v.p.x = field.w-v.r
      end
      if v.p.y-v.r < 0 then -- y
        v.d.y = 0
        v.p.y = v.r
      elseif v.p.y+v.r > field.h then
        v.d.y = 0
        v.p.y = field.h-v.r
      end
    end

    --collision between players
    for i, v in pairs(players) do
      for j, w in pairs(players) do
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
      state.networking.host:sendToAll("diff", {info = v.d, index = i})
    end

    -- send ball info
    if game.ball then state.networking.host:sendToAll("ballpos", game.ball.circle.p) end

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
          local shield_pos = {x = 0, y = 0}
          if w.shield.d then
            shield_pos = vector.sum(w.p, w.shield.d)
          end
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
      players[id].shield.d = vector.scale(shield.dist, vector.norm(mouse))
      state.networking.host:sendToAll("shieldpos", {info = players[id].shield.d, index = id})
    end

    if not game.ball.baller then
      for k,v in pairs(players) do
        if game.ball.moving.circle and collision.check_overlap(game.ball.moving.circle, game.ball.circle) then
          delete_this_later = true
          if collision.check_overlap(v, game.ball.circle) then
            game.ball.moving.circle = nil
            state.networking.host:sendToAll("thrown", game.ball.moving)
            game.ball.baller = k
            players[k].speed = speed_table.with_ball
            state.networking.host:sendToAll("newballer", k)
          end
        elseif delete_this_later then
          game.ball.moving.circle = nil
          state.networking.host:sendToAll("thrown", game.ball.moving)
          delete_this_later = false
          server.new_down(game.down.start)
        end
      end
    end

    if game.ball.baller then
      local baller_team = players[game.ball.baller].team
      if baller_team ~= players[qb].team then
        server.turnover()
      end

      if (baller_team == 1 and players[game.ball.baller].p.x > field.w/12*11) or (baller_team == 2 and players[game.ball.baller].p.x < field.w/12) then
        score[baller_team] = score[baller_team] + 7
        server.turnover()
        server.new_down(field.w/12*7)
        state.networking.host:sendToAll("touchdown", baller_team)
      end
    end

    if #teams[1].members <= 0 or #teams[2].members <= 0 then
      server.back_to_main()
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
    if game.ball.baller ~= id and players[id].team == players[qb].team then
      players[id].shield = {active = true, d = game.shield_pos(), t = 0}
      players[id].speed = speed_table.shield
      state.networking.host:sendToAll("shield", {info = {active = players[id].shield.active, d = players[id].shield.d}, index = id})
    elseif players[id].team ~= players[qb].team then
      players[id].sword = {active = true, d = game.sword_pos(), t = 0}
      players[id].speed = speed_table.sword
      state.networking.host:sendToAll("sword", {info = {active = players[id].sword.active, d = players[id].sword.d}, index = id})
    end
  end
end

server.mousereleased = function (x, y, button)
  if button == 1 and state.game == true and players[id].shield.active == true then
    players[id].shield = {active = false, t = 0}
    players[id].speed = speed_table.offense
  state.networking.host:sendToAll("shield", {info = {active = players[id].shield.act}, index = id})
  end
end

server.quit = function()
  state.networking.host:sendToAll("disconnect")
  state.networking.host:update()
  state.networking.host:destroy()
end

server.back_to_main = function()
  state.game = false
  state.network_mode = nil
  state.gui = gui.new(menus[1])
  server.quit()
end

server.start_game = function()
  teams = {{members = {}, qb = 1}, {members = {}, qb = 1}}
  for i, v in pairs(players) do
    teams[v.team].members[#teams[v.team].members+1] = i
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
  down.start = x
  if down.dir == 1 and players[qb].team == 2 then
    down.dir = -1
    down.num = 1
    down.goal = down.start - field.w/12
  elseif down.dir == -1 and players[qb].team == 1 then
    down.dir = 1
    down.num = 1
    down.goal = down.start + field.w/12
  elseif down.goal ~= nil and down.start*down.dir - down.goal*down.dir > 0 then
    down.num = 1
    down.goal = down.start + field.w/12*down.dir
    if down.goal > field.w/12*11 or down.goal < field.w/12 then
      down.goal = nil
    end
  else
    down.num = down.num + 1
    if down.num > 4 then
      game.down.num = 1
      down.goal = down.start - field.w/12*down.dir
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
