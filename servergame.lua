local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
require "globals"
local servergame = {}

-- julians wack movement thing
servergame.input = require("keyboard")
-- set up variables
local ball = {p = {x = 0, y = 0}, z = 0, d = {x = 0, y = 0}, r = 8, owner = nil, thrown = false}
local down = {scrim = 0, new_scrim = field.w/2, goal = field.w/12*7, num = 0, dead = false, t = 3}
local quit = false

local server_hooks = {
  -- if a client sends move data, do this
  posdif = function(data, client)
    local index = client:getIndex()
    players[index].d = data
    network.host:sendToAllBut(client, "posdif", {index = index, info = data})
  end,
  -- if a ball is thrown by client, do this
  throw = function(data, client)
    local index = client:getIndex()
    servergame.throw(index, data)
  end,
  -- if client is attacking, do this
  sword = function(data, client)
    local index = client:getIndex()
    players[index].sword = {active = true, d = vector.scale(sword.dist, vector.norm(data)), t = sword.t}
    network.host:sendToAll("sword", {index = index, active = true, mouse = data})
    -- adjust speed
    servergame.set_speed(index)
  end,
  -- if client dons or doffs shield, do this
  shieldstate = function(data, client)
    local index = client:getIndex()
    players[index].shield.active = data
    network.host:sendToAll("shieldstate", {index = index, info = data})
    -- adjust speed
    servergame.set_speed(index)
  end,
  -- if client moves shield, do this
  shieldpos = function(data, client)
    local index = client:getIndex()
    players[index].shield.d = data
    network.host:sendToAll("shieldpos", {index = index, info = data})
  end,
  disconnect = function(data, client)
    quit = true
  end
}

servergame.init = function()
  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    network.host:on(k, v)
  end
  -- set the base gui for the server menu (none)
  state.gui = gui.new({})

  -- set up initial variables for players
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 16
    v.shield = {active = false, d = {x = 0, y = 0}, t = 0}
    v.sword = {active = false, d = {x = 0, y = 0}, t = 0}
    v.dead = false
    -- set the speed for players
    servergame.set_speed(i)
  end
  -- set up initial down
  servergame.new_down()
  -- set game state
  state.game = true
end

servergame.update = function(dt)
  -- update sock server
  network.host:update()

  -- get server mouse positions
  mouse.x = love.mouse.getX()-win_width/2
  mouse.y = love.mouse.getY()-win_height/2
  -- get servers direction
  servergame.input.direction()
  -- send players position difference to all
  network.host:sendToAll("posdif", {info = players[id].d, index = id})

  for i, v in pairs(players) do
    -- move player based on their diff
    v.p.x = v.p.x + v.d.x*v.speed*dt
    v.p.y = v.p.y + v.d.y*v.speed*dt
    -- apply collision to player
    servergame.collide(v)
    --apply collision between players
    for j, w in pairs(players) do
      if i ~= j then -- don't check for collisions with self
        if collision.check_overlap(players[j], players[i]) then
          local p1, p2 = collision.circle_vs_circle(players[j], players[i])
          w.p = p1
          v.p = p2
        end
      end
    end
    -- send player's position to all
    network.host:sendToAll("pos", {info = v.p, index = i})
    -- do combat stuff
    if v.sword.active then
      --update player's attack (if at all)
      v.sword.t = v.sword.t - dt
      if v.sword.t <= 0 then
        v.sword.active = false
        -- reset speed
        servergame.set_speed(i)
        network.host:sendToAll("sword", {index = i, active = false, mouse = {x = 0, y = 0}})
      end

      -- check for sword attacks
      local strike = true
      local sword_pos = vector.sum(v.p, v.sword.d)
       -- check if sword hits shield
      for j, w in pairs(players) do
        if j ~= i and w.dead == false and w.shield.active == true then
          shield_pos = vector.sum(w.p, w.shield.d)
          if vector.mag_sq(vector.sub(v.p, w.p)) > vector.mag_sq(vector.sub(v.p, shield_pos)) and collision.check_overlap({r = shield.r, p = shield_pos}, {r = sword.r, p = sword_pos}) then -- prevents blocks through body
            strike = false
          end
        end
      end
       -- if sword didn't hit shield, check if it hit people
      if strike == true then
        for j, w in pairs(players) do
          if j ~= i and w.team ~= v.team and w.dead == false and collision.check_overlap({r = sword.r, p = sword_pos}, w) then
            -- kill player
            servergame.kill(j)
            network.host:sendToAll("dead", j)
            -- if player with ball is tackled
            if j == ball.owner then
              down.dead = true
              down.new_scrim = w.p.x
              down.t = grace_time
              network.host:sendToAll("downdead")
            end
          end
        end
      end
    end
  end
  -- reduce server's velocity
  players[id].d = vector.scale(0.9, players[id].d)

  -- move the ball
  if ball.thrown then
    -- move the ball
    ball.p = vector.sum(ball.p, vector.scale(dt * 60 * 4, ball.d))
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z  = (dist*dist-ball.height*dist)/512
    ball.angle = math.atan2(ball.d.y+z-ball.z, ball.d.x)
    ball.z = z
    -- if ball hits the ground, reset
    if ball.z >= 0 then
      down.dead = true
      down.t = grace_time
      ball.thrown = false
      network.host:sendToAll("downdead")
    end

    -- send new ball position
    network.host:sendToAll("ballpos", ball.p)
  end
  -- catch the ball
  if ball.z < 16 and ball.thrown then
    for i, v in pairs(players) do
      if i ~= qb and v.dead == false and collision.check_overlap(v, ball) then -- makes sure catcher isn't qb to prevent immediate catches after throwing, and not dead
        ball.thrown = false
        ball.owner = i
        network.host:sendToAll("catch", i)
        break
      end
    end
  end
  -- adjust shield pos
  if players[id].shield.active == true then
    players[id].shield.d = vector.scale(shield.dist, vector.norm(mouse))
    network.host:sendToAll("shieldpos", {info = players[id].shield.d, index = id})
  end
  if down.dead == false and ball.owner ~= nil then
    -- find team to check
    local team = players[ball.owner].team
    if (team == 1 and players[ball.owner].p.x > field.w/12*11) or (team == 2 and players[ball.owner].p.x < field.w/12) then
      score[team] = score[team] + 7
      down.dead = true
      down.new_scrim = field.w/12*7
      down.t = grace_time
      network.host:sendToAll("touchdown", team)
    end
  end
  -- advance play clock
  if down.t > 0 then
    down.t = down.t - dt
  elseif down.dead == true then
    servergame.new_down()
  end
  -- quit if necessary
  if quit then
    servergame.back_to_main()
  end
end

servergame.draw = function()
  love.graphics.push()
  love.graphics.translate(math.floor(win_width/2-players[id].p.x), math.floor(win_height/2-players[id].p.y))
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field)
  -- draw line of scrimmage
  love.graphics.setColor(0, 0, 255)
  love.graphics.rectangle("fill", down.scrim-2, 0, 4, field.h)
  -- draw first down line
  love.graphics.setColor(255, 0, 0)
  love.graphics.rectangle("fill", down.goal-2, 0, 4, field.h)

  for i, v in pairs(players) do
    local char_img = "char"
    if v.dead == true then
      char_img = "char_dead"
    elseif ball.owner and ball.owner == i and i ~= qb then
      char_img = "char_baller"
    elseif ball.owner == i and down.dead == false then
      char_img = "char_qb"
    end

    --draw base sprite
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img[char_img], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw colored overlay
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.draw(img[char_img.."_overlay"], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

     -- draw shield
    if v.shield.active == true then
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.shield, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.shield_overlay, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
    end

     -- draw sword
    if v.sword.active == true then
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.sword, math.floor(v.p.x)+math.floor(v.sword.d.x), math.floor(v.p.y)+math.floor(v.sword.d.y), math.atan2(v.sword.d.y, v.sword.d.x), 1, 1, 10, 10)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.sword_overlay, math.floor(v.p.x)+math.floor(v.sword.d.x), math.floor(v.p.y)+math.floor(v.sword.d.y), math.atan2(v.sword.d.y, v.sword.d.x), 1, 1, 10, 10)
    end

    --draw username
    love.graphics.print(v.name, math.floor(v.p.x)-math.floor(font:getWidth(v.name)/2), math.floor(v.p.y)-math.floor(v.r+font:getHeight()))
  end

  -- draw ball
  if ball.thrown then
    love.graphics.setColor(255, 255, 255)
    -- shadow
    love.graphics.draw(img.shadow, math.floor(ball.p.x), math.floor(ball.p.y), 0, 1, 1, 8, 8)
    -- ball
    love.graphics.draw(img.arrow, math.floor(ball.p.x), math.floor(ball.p.y)+math.floor(ball.z), ball.angle, 1, 1, 16, 16)
  end

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
end

servergame.mousepressed = function(x, y, button)
  if button == 1 and down.dead == false and down.t <= 0 and players[id].dead == false then
    if ball.owner == id and qb == id then -- qb who still has ball
      servergame.throw(id, mouse)
    elseif ball.owner ~= id and players[id].team == players[qb].team then -- team with ball, but does not have ball
      players[id].shield.active = true
      network.host:sendToAll("shieldstate", {index = id, info = true})
    elseif ball.owner ~= id and players[id].team ~= players[qb].team then -- team without ball
      players[id].sword = {active = true, d = vector.scale(sword.dist, vector.norm(mouse)), t = sword.t}
      network.host:sendToAll("sword", {index = id, active = true, mouse = mouse})
    end
  end
end

servergame.mousereleased = function(x, y, button)
  if button == 1 and down.dead == false and down.t <= 0 and players[id].dead == false then
    if players[id].shield.active == true then
      players[id].shield.active = false
      network.host:sendToAll("shieldstate", {index = id, info = false})
    end
  end
end

servergame.quit = function()
  network.host:sendToAll("disconnect")
  network.host:update()
  network.host:destroy()
end

servergame.back_to_main = function()
  state.game = false
  network.mode = nil
  state.gui = gui.new(menus[1])
  servergame.quit()
end

servergame.throw = function(i, mouse)
  -- ball is thrown
  ball.owner = nil
  ball.thrown = true
  -- set initial position
  ball.p.x = players[i].p.x
  ball.p.y = players[i].p.y
  ball.z = 0
  -- set direction
  ball.d = vector.norm({x = mouse.x, y = mouse.y})
  ball.goal = vector.sum({x = mouse.x, y = mouse.y}, {x = players[i].p.x, y = players[i].p.y})
  ball.start = {x = players[i].p.x, y = players[i].p.y}
  ball.height = math.sqrt((ball.goal.x-ball.p.x)*(ball.goal.x-ball.p.x)+(ball.goal.y-ball.p.y)*(ball.goal.y-ball.p.y))

  network.host:sendToAll("throw", ball)
end

servergame.new_down = function()
  -- progress down number
  down.num = down.num + 1
  -- adjust line of scrimmage / goal
  down.scrim = down.new_scrim
  if players[qb].team == 1 and down.scrim >= down.goal then
    down.goal = down.scrim + field.w/12
    down.num = 1
  elseif players[qb].team == 2 and down.scrim <= down.goal then
    down.goal = down.scrim - field.w/12
    down.num = 1
  end

  -- check if there is a turnover
  if down.num > 4 or (ball.owner and players[ball.owner].team ~= players[qb].team) then
    servergame.turnover()
  end

  down.dead = false
  down.t = grace_time
  -- reset player positions
  local team_pos = {0, 0}
  for i, v in pairs(players) do
    if v.team == 1 then
      v.p.x = down.scrim - 32
    else
      v.p.x = down.scrim + 32
    end
    v.p.y = (field.h-#teams[v.team].members*48)/2+team_pos[v.team]*48
    v.d.x, v.d.y = 0, 0
    team_pos[v.team] = team_pos[v.team] + 1
    -- reset players
    v.sword.active = false
    v.shield.active = false
    v.dead = false
  end
  -- give ball to quarterback
  ball.owner = qb
  ball.thrown = false
  network.host:sendToAll("newdown", {down = down, qb = qb})
end

servergame.turnover = function()
  -- team that just got the ball
  local team = 1
  if players[qb].team == 1 then
    team = 2
  end

  -- set new qb
  qb = teams[team].members[teams[team].qb]
  -- determine who the next qb will be
  teams[team].qb = teams[team].qb + 1
  -- reset if next qb doesn't exist
  if teams[team].qb > #teams[team].members then
    teams[team].qb = 1
  end
  -- reset down
  if team == 1 then
    down.goal = down.scrim + field.w/12
  elseif team == 2 then
    down.goal = down.scrim - field.w/12
  end
  down.num = 1
end

servergame.kill = function(i)
  players[i].dead = true
  players[i].sword.active = false
  players[i].shield.active = false
end

servergame.set_speed = function (i) -- based on player's state, set a speed
  if i == ball.owner then
    players[i].speed = speed_table.with_ball
  elseif players[i].shield.active == true then
    players[i].speed = speed_table.shield
  elseif players[i].sword.active == true then
    players[i].speed = speed_table.sword
  elseif players[i].team == players[qb].team then
    players[i].speed = speed_table.offense
  else
    players[i].speed = speed_table.defense
  end
end

servergame.collide = function (v)
  -- collide with line of scrimmage if down has hardly started
  if down.t > 0 and down.dead == false then
    if v.team == 1 and v.p.x+v.r > down.scrim then
      v.d.x = 0
      v.p.x = down.scrim-v.r
    elseif v.team == 2 and v.p.x-v.r < down.scrim then
      v.d.x = 0
      v.p.x = down.scrim+v.r
    end
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

return servergame
