local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
require "globals"
local server = {}
local delete_this_later = false

server.update___= function(dt)
  for i, v in pairs(players) do
    network.host:sendToAll("coords", {info = v.p, index = i})
  end
  if game.ball then
    network.host:sendToAll("ballpos", game.ball.circle.p)
  end
  network.host:update()

  if state.game then
    for i, v in pairs(players) do -- move players
      v.p.x = v.p.x + v.d.x*v.speed*dt
      v.p.y = v.p.y + v.d.y*v.speed*dt
      game.collide(v)
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
      network.host:sendToAll("coords", {info = v.p, index = i})
      network.host:sendToAll("diff", {info = v.d, index = i})
    end

    -- send ball info
    if game.ball then network.host:sendToAll("ballpos", game.ball.circle.p) end

    -- adjust sword and shield info
    for i, v in pairs(players) do
      if v.shield.active == true then v.shield.t = v.shield.t + dt end
      if v.sword.active == true then
        v.sword.t = v.sword.t + dt
        if v.sword.t > sword.t then
          v.sword.active = false
          v.sword.t = 0
          v.speed = speed_table.defense
          network.host:sendToAll("sword", {info = {active = false}, index = i})
        end

        local strike = true
        local sword_pos = vector.sum(v.p, v.sword.d)
        for j, w in pairs(players) do -- check if sword hits shield
          local shield_pos = {x = 0, y = 0}
          if w.shield.d then
            shield_pos = vector.sum(w.p, w.shield.d)
          end
          if j ~= i and w.shield.active == true and w.dead == false and vector.mag_sq(vetor.sub(v.p, w.p)) > vector.mag_sq(vector.sub(v.p, shield_pos)) and collision.check_overlap({r = shield.r, p = shield_pos}, {r = sword.r, p = sword_pos}) then
            strike = false
          end
        end

        if strike == true then -- if sword didn't hit shield, check if it hit people
          for j, w in pairs(players) do
            if j ~= i and w.dead == false and collision.check_overlap({r = sword.r, p = sword_pos}, w) then
              network.host:sendToAll("dead", j)
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
      network.host:sendToAll("shieldpos", {info = players[id].shield.d, index = id})
    end

    if not game.ball.baller then
      for k,v in pairs(players) do
        if game.ball.moving.circle and collision.check_overlap(game.ball.moving.circle, game.ball.circle) then
          delete_this_later = true
          if collision.check_overlap(v, game.ball.circle) then
            game.ball.moving.circle = nil
            network.host:sendToAll("thrown", game.ball.moving)
            game.ball.baller = k
            players[k].speed = speed_table.with_ball
            network.host:sendToAll("newballer", k)
            delete_this_later = false
          end
        elseif delete_this_later then
          game.ball.moving.circle = nil
          network.host:sendToAll("thrown", game.ball.moving)
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
        network.host:sendToAll("touchdown", baller_team)
      end
    end

    if #teams[1].members <= 0 or #teams[2].members <= 0 then
      server.back_to_main()
    end
  end
end

server.mousepressed = function(x, y, button)
  if button == 1 and state.game == true and players[id].dead == false and game.down.t > grace_time then
    if game.ball.baller ~= id and players[id].team == players[qb].team then
      players[id].shield = {active = true, d = game.shield_pos(), t = 0}
      players[id].speed = speed_table.shield
      network.host:sendToAll("shield", {info = {active = players[id].shield.active, d = players[id].shield.d}, index = id})
    elseif players[id].team ~= players[qb].team then
      players[id].sword = {active = true, d = game.sword_pos(), t = 0}
      players[id].speed = speed_table.sword
      network.host:sendToAll("sword", {info = {active = players[id].sword.active, d = players[id].sword.d}, index = id})
    end
  end
end

server.mousereleased = function (x, y, button)
  if button == 1 and state.game == true and players[id].shield.active == true then
    players[id].shield = {active = false, t = 0}
    --players[id].speed = speed_table.offense
  network.host:sendToAll("shield", {info = {active = players[id].shield.act}, index = id})
  end
end

server.disconnect = function(index)
  network.host:sendToPeer(network.host:getPeerByIndex(index), "disconnect")
  if state.game == true then
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

server.quit = function()
  network.host:sendToAll("disconnect")
  network.host:update()
  network.host:destroy()
end

server.back_to_main = function()
  state.game = false
  network.mode = nil
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
    network.host:sendToAll("qb", qb)
    network.host:sendToAll("startgame", players)
    game.init()
    game.ball.baller = qb
  end
end

server.new_down = function (x)
  delete_this_later = false
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
  network.host:sendToAll("newdown", game.down)
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
  network.host:sendToAll("qb", qb)
  for i, v in pairs(players) do
    v.sword.active = false
    v.shield.active = false
    game.set_speed(i)
  end
end

return server
