local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
local ai = require "ai"
local commonfunc = require "commonfunc"
local particle = require "particle"
local audio = require "audio"
require "globals"
local servergame = {}

-- set up variables
local td = false
local quit = false

effects = {}
local alerts = {}

local server_hooks = {
  connect = function(data, client)
  end,
  -- if a client sends move data, do this
  posdif = function(data, client)
    local index = client:getIndex()
    players[index].d = data
    network.host:sendToAllBut(client, "posdif", {index = index, info = data})
  end,
  accel = function(data, client)
    local index = client:getIndex()
    players[index].a = data
    network.host:sendToAllBut(client, "accel", {index = index, info = data})
  end,
  -- if a ball is thrown by client, do this
  throw = function(data, client)
    local index = client:getIndex()
    servergame.throw(index, data)
  end,
  -- if client is attacking, do this
  sword = function(data, client)
    local index = client:getIndex()
    players[index].sword.active = true
    players[index].sword.d = vector.scale(sword.dist, vector.norm(data))
    players[index].sword.t = sword.t
    network.host:sendToAll("sword", {index = index, active = true, mouse = data})
    commonfunc.check_for_block(index, players[index])
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
  mousepos = function(data, client)
    local index = client:getIndex()
    players[index].mouse = data
    if players[index].shield.active then
      players[index].shield.d = vector.scale(shield.dist, vector.norm(data))
    end
    network.host:sendToAll("mousepos", {index = index, info = data})
  end,
  disconnect = function(data, client)
    local index = client:getIndex()
    ball.owner = 0
    if players[index] then
      quit = true
    end
  end,
}

servergame.init = function()
  love.mouse.setRelativeMode(true)
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
    v.a = {x = 0, y = 0}
    v.r = 10
    v.shield = {active = false, d = {x = 0, y = 0}, t = 0, canvas = love.graphics.newCanvas(32, 32)}
    v.sword = {active = false, d = {x = 0, y = 0}, t = 0, canvas = love.graphics.newCanvas(32, 32)}
    v.dead = false
    v.mouse = {x = 0, y = 0}
    v.mouse_goal = {x = 0, y = 0}
    v.polar = {mag = 0, angle = 0}
    v.art = {state = "base", anim = "idle", dir = 1, frame = 1, canvas = love.graphics.newCanvas(32, 48)}
  end
  -- set up initial down
  servergame.new_down()
  -- set game state
  state.game = true
  -- start music
  audio.start_background_music()
end

servergame.update = function(dt)
  audio.update_music()

  input.center()

  -- update sock server
  network.host:update()

  --get server mouse positions
  input.target()
  commonfunc.adjust_target(id, dt)

  -- send server mouse position to clients
  network.host:sendToAll("mousepos", {info = players[id].mouse, index = id})
  -- get servers direction
  local x, y = input.direction()
  players[id].a.x = x
  players[id].a.y = y

  -- send players acceleration
  network.host:sendToAll("accel", {info = players[id].a, index = id})

  for i, v in pairs(players) do
    if v.bot then -- run AI for bots
      if ai.process(i, v, dt) then
        servergame.set_speed(i)
      end
      network.host:sendToAll("mousepos", {info = v.mouse, index = i})
      network.host:sendToAll("accel", {info = v.a, index = i})
    end
    -- get servers direction, add acceleration, cap speed
    -- add acceleration to velocity
    v.d = vector.sum(v.d, vector.scale(acceleration, v.a))
    -- cap velocity due to user input
    if vector.mag_sq(v.d) > v.speed*v.speed then
      v.d = vector.scale(v.speed, vector.norm(v.d))
    end
    -- move player based on their velocity
    if v.sticky then -- if hitting shield, reduce velocity
      v.p = vector.sum(v.p, vector.scale(dt*shield_slow, v.d))
    else
      v.p = vector.sum(v.p, vector.scale(dt, v.d))
    end
    --reset sticky
    v.sticky = false
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
    -- send player's position and velocity to all
    network.host:sendToAll("pos", {info = v.p, index = i})
    network.host:sendToAll("posdif", {info = v.d, index = i})
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
      if commonfunc.block(i, v) then
        strike = false
      end
       -- if sword didn't hit shield, check if it hit people
      if strike == true then
        for j, w in pairs(players) do
          if j ~= i and w.team ~= v.team and w.dead == false and collision.check_overlap({r = sword.r, p = sword_pos}, w) then
            -- add alert
            if j == qb then
              audio.play_sfx("cheer")
              alerts[#alerts+1] = {txt = v.name.." has sacked "..w.name, team = v.team}
            else
              alerts[#alerts+1] = {txt = v.name.." has tackled "..w.name, team = v.team}
            end
            -- kill player
            servergame.kill(j)
            network.host:sendToAll("dead", {killer = i, victim = j})
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
    for j,w in pairs(players) do
      local shield_pos = vector.sum(w.p, w.shield.d)
      if collision.check_overlap(players[i],  {r = shield.r, p = shield_pos}) and v.team ~= w.team and w.shield.active then
        v.sticky = true
      end
    end
    -- friction / linear deceleration, for a more "tagpro-y" feel
    if vector.mag_sq(v.d) > friction*friction then
      v.d = vector.sub(v.d, vector.scale(friction, vector.norm(v.d)))
    else
      v.d.x = 0
      v.d.y = 0
    end
    -- do art stuff
    servergame.animate(i, v, dt)
  end

  -- move the ball
  if ball.thrown then
    -- move the ball
    ball.p = vector.sum(ball.p, vector.scale(dt * 60 * ball_speed, ball.d))
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z = (dist*dist-ball.height*dist)/512*-1
    ball.angle = math.atan2(ball.d.y-z+ball.z, ball.d.x)
    ball.z = z
    -- if ball hits the ground, reset
    if ball.z <= 0 then
      alerts[#alerts+1] = {txt = players[qb].name.." has thrown an incomplete pass", team = players[qb].team}
      effects[#effects+1] = {img = "stuckarrow", x = ball.p.x, y = ball.p.y, z = 0, ox = 16, oy = 16, t = 0}
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
        -- reset receiver's sword and shields
        v.shield.active = false
        v.sword.active = false

        ball.thrown = false
        ball.owner = i
        for j, w in pairs(players) do
          servergame.set_speed(j)
        end
        effects[#effects+1] = {img = "catch", quad = 1, x = v.p.x, y = v.p.y, z = 18, ox = 16, oy = 16, parent = i, t = 0, top = true} -- catch particle
        audio.play_sfx("thud") -- catch sound
        -- interception
        if players[ball.owner].team ~= players[qb].team then
          effects[#effects+1] = {img = "intercept", quad = 1, x = v.p.x, y = v.p.y, z = 18, ox = 16, oy = 16, parent = i, t = -1/3, top = true, color = team_info[players[ball.owner].team].color} -- intercept particle
          -- add alert
          alerts[#alerts+1] = {txt = players[ball.owner].name.." has intercepted the ball", team = players[ball.owner].team}
          -- reset swords and shields
          for i, v in pairs(players) do
            if v.shield.active == true then
              v.shield.active = false
              network.host:sendToAll("shieldstate", {index = i, active = false, mouse = {x = 0, y = 0}})
            end
            if v.sword.active == true then
              v.sword.active = false
              v.sword.t = 0
              network.host:sendToAll("sword", {index = i, active = false, mouse = {x = 0, y = 0}})
            end
            -- set the speed for players
            servergame.set_speed(i)
          end
          audio.play_sfx("cheer")
        else
          -- add alert
          alerts[#alerts+1] = {txt = players[ball.owner].name.." has caught the ball", team = players[ball.owner].team}
        end
        network.host:sendToAll("catch", i)
        break
      end
    end
  end
  -- adjust shield pos
  if players[id].shield.active == true then
    players[id].shield.d = vector.scale(shield.dist, vector.norm(players[id].mouse))
    network.host:sendToAll("shieldpos", {info = players[id].shield.d, index = id})
  end
  if down.dead == false and ball.owner ~= nil then
    -- find team to check
    local team = players[ball.owner].team
    if (team == 1 and players[ball.owner].p.x > field.w/12*11) or (team == 2 and players[ball.owner].p.x < field.w/12) then
      -- add alert
      alerts[#alerts+1] = {txt = players[ball.owner].name.." has scored a touchdown for "..team_info[team].name, team = team}
      -- do stuff
      score[team] = score[team] + 7
      down.dead = true
      down.new_scrim = field.w/12*6
      down.t = grace_time
      td = true
      network.host:sendToAll("touchdown", team)
      for j = 1, 8 do
        effects[#effects+1] = {img = "confetti", quad = 1, x =  players[ball.owner].p.x, y =  players[ball.owner].p.y, z = 18, ox = 8, oy = 8, dx = math.random(-200, 200)/100, dy = math.random(-200, 200)/100, dz = 1, t = math.random(0, 7), color = team_info[team].color}
      end
      audio.play_sfx("longcheer")
    end
  end
  -- advance play clock
  if down.t > 0 then
    down.t = down.t - dt
  elseif down.dead == true then
    servergame.new_down()
  end
  -- update effects
  for k, v in pairs(effects) do
    if not particle[v.img](k, v, dt) then
      table.remove(effects, k)
    end
  end
  --update alerts
  for i, v in ipairs(alerts) do
    if v.t then
      v.t = v.t - dt
      if v.t <= 0 then
        table.remove(alerts, i)
      end
    else
      v.t = alert_time
    end
  end
  -- quit if necessary
  if quit then
    love.event.quit()
  end
end

servergame.draw = function()
  local queue = {}

  for i, v in pairs(players) do
    love.graphics.setCanvas(v.art.canvas)
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    --draw base sprite
    love.graphics.draw(char[v.art.state][v.art.anim].img, char[v.art.state][v.art.anim].quad[v.art.dir][math.floor(v.art.frame)])

    --draw colored overlay
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.draw(char[v.art.state][v.art.anim.."overlay"].img, char[v.art.state][v.art.anim].quad[v.art.dir][math.floor(v.art.frame)])

    love.graphics.setCanvas(win_canvas)
    queue[#queue+1] = {img = v.art.canvas, x = math.floor(v.p.x), y = math.floor(v.p.y), ox = 16, oy = 48}

     -- draw shield
    if v.shield.active == true then
      love.graphics.setCanvas(v.shield.canvas)
      love.graphics.clear()

      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(img.shield, quad.shield[v.art.dir])
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.shield_overlay, quad.shield[v.art.dir])

      love.graphics.setCanvas(win_canvas)
      queue[#queue+1] = {img = v.shield.canvas, x = math.floor(v.p.x)+math.floor(v.shield.d.x), y = math.floor(v.p.y)+math.floor(v.shield.d.y*.75), z = 18, ox = 16, oy = 16}
    end

     -- draw sword
    if v.sword.active == true then
      love.graphics.setCanvas(v.sword.canvas)
      love.graphics.clear()

      love.graphics.setColor(1, 1, 1)
      love.graphics.draw(img.sword)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.sword_overlay)

      love.graphics.setCanvas(win_canvas)
      queue[#queue+1] = {img = v.sword.canvas, x = math.floor(v.p.x)+math.floor(v.sword.d.x), y = math.floor(v.p.y)+math.floor(v.sword.d.y*.75), z = 18, r = math.atan2(v.sword.d.y, v.sword.d.x), ox = 16, oy = 16}
    end

    --queue username
    queue[#queue+1] = {txt = v.name, x = math.floor(v.p.x)-math.floor(fontcontrast:getWidth(v.name)/2), y = math.floor(v.p.y), z = math.floor(48+fontcontrast:getHeight()), color = team_info[v.team].color}
  end

  -- set up camera
  love.graphics.push()
  love.graphics.translate(win_width/2-math.floor(camera.x), win_height/2-math.floor(camera.y))
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(img.field)
  -- draw line of scrimmage
  love.graphics.setColor(1, 0, 0)
  love.graphics.rectangle("fill", down.scrim-2, 0, 4, field.h)
  -- draw first down line
  if down.goal then
    love.graphics.setColor(1, 1, 0)
    love.graphics.rectangle("fill", down.goal-2, 0, 4, field.h)
  end

  -- draw flat player things (e.g. shadows)
  for i, v in pairs(players) do
    -- draw shadow
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(img.shadow, math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 8, 10)
    -- draw target prediction
    if id == qb and ball.owner == id and v.team == players[qb].team and i ~= qb then
      local dist = math.sqrt((players[qb].p.x-v.p.x)*(players[qb].p.x-v.p.x)+(players[qb].p.y-v.p.y)*(players[qb].p.y-v.p.y))
      local adj_d = vector.scale(1/60, v.d)
      local p = vector.sum(vector.scale(- dist / (math.sqrt(vector.mag_sq(adj_d)) - ball_speed), adj_d), v.p)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.line(v.p.x, v.p.y, p.x, p.y)
      love.graphics.draw(img.charnode, math.floor(p.x), math.floor(p.y), 0, 1, 1, 16, 16)
    end
  end

  -- draw bottom effects (blood, etc.)
  commonfunc.draw_effects(effects)

  --draw qb cursor
  love.graphics.setColor(team_info[players[qb].team].color)
  if ball.thrown and not ball.owner then
    love.graphics.draw(img.balltarget, math.floor(ball.goal.x), math.floor(ball.goal.y), 0, 1, 1, 16, 16)
  elseif ball.owner and ball.owner == qb then
    love.graphics.draw(img.balltarget, math.floor(players[qb].p.x+players[qb].mouse.x), math.floor(players[qb].p.y+players[qb].mouse.y), 0, 1, 1, 16, 16)
  end

  -- draw personal cursor
  if players[id].dead then -- make cursor transparent if player is dead
    love.graphics.setColor(team_info[players[id].team].color[1], team_info[players[id].team].color[2], team_info[players[id].team].color[3], .5)
  else
    love.graphics.setColor(team_info[players[id].team].color)
  end
  love.graphics.draw(img.target, math.floor(camera.x), math.floor(camera.y), 0, 1, 1, 16, 16)
  -- draw direction arrow
  love.graphics.draw(img.pointer, math.floor(players[id].p.x), math.floor(players[id].p.y), players[id].polar.angle, 1, 1, 16, 16)

  -- draw ball
  if ball.thrown then
    love.graphics.setColor(1, 1, 1)
    -- shadow
    love.graphics.draw(img.smallshadow, math.floor(ball.p.x), math.floor(ball.p.y), 0, 1, 1, 8, 8)
    -- ball
    queue[#queue+1] = {img = img.arrow, x = math.floor(ball.p.x), y = math.floor(ball.p.y), z = math.floor(ball.z)+18, r = ball.angle, ox = 8, oy = 8}
  end

  -- draw items in queue
  table.sort(queue, function(a, b) return a.y < b.y end)
  for i, v in ipairs(queue) do
    if not v.z then v.z = 0 end
    if not v.color then v.color = {255, 255, 255} end
    if v.img then
      if not v.r then v.r = 0 end
      if not v.ox then v.ox = 0 end
      if not v.oy then v.oy = 0 end
      love.graphics.setColor(v.color)
      if v.quad then
        love.graphics.draw(v.img, v.quad, math.floor(v.x), math.floor(v.y-v.z), v.r, 1, 1, math.floor(v.ox), math.floor(v.oy))
      else
        love.graphics.draw(v.img, math.floor(v.x), math.floor(v.y-v.z), v.r, 1, 1, math.floor(v.ox), math.floor(v.oy))
      end
    elseif v.txt then
      love.graphics.setColor(v.color)
      love.graphics.setFont(fontcontrast)
      love.graphics.print(v.txt, math.floor(v.x), math.floor(v.y-v.z))
    end
  end

  -- draw top effects (shield spark, etc.)
  commonfunc.draw_effects(effects, true)

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1)
  -- draw scoreboard
  commonfunc.draw_scoreboard((win_width-126)/2, 2)

  -- draw alerts
  love.graphics.setFont(fontcontrast)
  for i, v in ipairs(alerts) do
    if v.t then
      love.graphics.setColor(team_info[v.team].color[1], team_info[v.team].color[2], team_info[v.team].color[3], v.t/alert_time)
    else
      love.graphics.setColor(team_info[v.team].color)
    end
    love.graphics.print(v.txt, 2, win_height-(#alerts-i+1)*12)
  end
end

servergame.mousepressed = function(x, y, button)
  if down.dead == false and down.t <= 0 and players[id].dead == false then
    if ball.owner == id and qb == id then -- qb who still has ball
      servergame.throw(id, players[id].mouse)
    elseif ball.owner ~= id and ((ball.owner and players[ball.owner].team == players[id].team) or (not ball.owner and players[qb].team == players[id].team)) then -- team with ball, but does not have ball
      players[id].shield.active = true
      network.host:sendToAll("shieldstate", {index = id, info = true})
    elseif ball.owner ~= id and ((ball.owner and players[ball.owner].team ~= players[id].team) or (not ball.owner and players[qb].team ~= players[id].team)) then -- team without ball
      players[id].sword.active = true
      players[id].sword.d = vector.scale(sword.dist, vector.norm(players[id].mouse))
      players[id].sword.t = sword.t
      network.host:sendToAll("sword", {index = id, active = true, mouse = players[id].mouse})
      commonfunc.check_for_block(id, players[id])
    end
    servergame.set_speed(id)
  end
end

servergame.mousereleased = function(x, y, button)
  if down.t <= 0 and players[id].dead == false then
    if players[id].shield.active == true then
      players[id].shield.active = false
      network.host:sendToAll("shieldstate", {index = id, info = false})
    end
    servergame.set_speed(id)
  end
end

servergame.mousemoved = function(x, y, dx, dy, istouch)
  -- find camera values
  camera.x = camera.x + dx*global_dt*30
  camera.y = camera.y + dy*global_dt*30
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
  --adjust line of scrimmage
  down.scrim = down.new_scrim
  if down.scrim < field.w/12 then
    down.scrim = field.w/12
  elseif down.scrim > field.w/12*11 then
    down.scrim = field.w/12*11
  end
  -- adjust goal line
  if down.goal then -- if goal isn't end zone
    if players[qb].team == 1 and down.scrim >= down.goal then
      down.goal = down.scrim + field.w/12
      down.num = 1
    elseif players[qb].team == 2 and down.scrim <= down.goal then
      down.goal = down.scrim - field.w/12
      down.num = 1
    end
    if down.goal <= field.w/12 or down.goal >= field.w/12*11 then -- if goal is in end zone, remove it
      down.goal = nil
    end
  end

  -- check if there is a turnover
  if down.num > 4 or (ball.owner and players[ball.owner].team ~= players[qb].team) or td == true then
    servergame.turnover()
  end
  td = false

  down.dead = false
  down.t = grace_time
  -- reset player positions
  ball.owner = qb
  local team_pos = {{0, 0, 0}, {0, 0, 0}}       -- set up players
  for i, v in pairs(players) do
    -- reset position
    if v.bot and v.type == "linesmen" then
      v.p.y = (field.h-ai.num[v.team][1]*48)/2+team_pos[v.team][1]*48+32
      team_pos[v.team][1] = team_pos[v.team][1] + 1
      v.p.x = down.scrim + (v.team-1.5)*64
    elseif v.bot and v.type == "receiver" then
      local half = math.floor(ai.num[v.team][2]/2)
      if team_pos[v.team][2] < half then
        v.p.y = (field.h-#teams[v.team].members*48)/2-half*48+team_pos[v.team][2]*48+32
      else
        v.p.y = (field.h+#teams[v.team].members*48)/2+(team_pos[v.team][2]-half)*48+32
      end
      team_pos[v.team][2] = team_pos[v.team][2] + 1
      v.p.x = down.scrim + (v.team-1.5)*128
    else
      v.p.y = (field.h-#teams[v.team].members*48)/2+team_pos[v.team][3]*48+32
      team_pos[v.team][3] = team_pos[v.team][3] + 1
      v.p.x = down.scrim + (v.team-1.5)*128
    end
    v.d.x, v.d.y = 0, 0

    -- reset players
    v.sword.active = false
    v.shield.active = false
    v.dead = false
    -- send reset position
    network.host:sendToAll("pos", {info = v.p, index = i})
    servergame.set_speed(i)
  end
  -- give ball to quarterback
  ball.thrown = false

  -- reset target
  camera.x = players[id].p.x
  camera.y = players[id].p.y
  players[id].polar.mag = 0
  players[id].polar.angle = 0

  -- clear effects
  effects = {}

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
  if down.goal <= field.w/12 or down.goal >= field.w/12*11 then -- if goal is in end zone, remove it
    down.goal = nil
  end
  down.num = 1
end

servergame.kill = function(i)
  players[i].dead = true
  players[i].sword.active = false
  players[i].shield.active = false
  servergame.set_speed(i)
  -- blood spurt
  effects[#effects+1] = {img = "bloodspurt", quad = 1, x = players[i].p.x, y = players[i].p.y, z = 18, ox = 16, oy = 16, parent = i, t = 0, top = true}
  for j = 1, 4 do
    effects[#effects+1] = {img = "blood", quad = "drop", x = players[i].p.x, y = players[i].p.y, z = 18, ox = 8, oy = 8, dx = math.random(-200, 200)/100, dy = math.random(-200, 200)/100, dz = 2}
  end
  audio.play_sfx("squish")
end

servergame.set_speed = function (i) -- based on player's state, set a speed
  if players[i].dead then
    players[i].speed = 0
  elseif i == ball.owner then
    players[i].speed = speed_table.with_ball
  elseif players[i].shield.active then
    players[i].speed = speed_table.shield
  elseif players[i].sword.active then
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

servergame.animate = function(i, v, dt)
  -- get state
  if v.dead == true then
    v.art.state = "dead"
  elseif ball.owner and ball.owner == i and qb == i then
    v.art.state = "qb"
  elseif ball.owner and ball.owner == i then
    v.art.state = "owner"
  elseif v.sword.active then
    v.art.state = "sword"
  elseif v.shield.active then
    v.art.state = "shield"
  else
    v.art.state = "base"
  end
  -- get what determines direction
  local dir = v.mouse

  -- get direction
  if dir.y < 0 then
    v.art.dir = 8+math.floor(math.atan2(dir.y, dir.x)/math.pi*4+1.5)
  else
    v.art.dir = math.floor(math.atan2(dir.y, dir.x)/math.pi*4+1.5)
  end
  -- make sure direction is in bounds (1-8)
  if v.art.dir > 8 then
    v.art.dir = 1
  elseif v.art.dir < 1 then
    v.art.dir = 8
  end
  -- get anim (run or idle)
  if vector.mag_sq(v.d) > 0.5 then
    v.art.anim = "run"
  else
    v.art.anim = "idle"
  end
  -- add or subtract frame based on direction
  local mouse = vector.norm(v.mouse)
  local d = vector.norm(v.d)
  if (mouse.x-d.x)*(mouse.x-d.x)+(mouse.y-d.y)*(mouse.y-d.y) <= 2 then
    v.art.frame = v.art.frame + dt * 12
  else
    v.art.frame = v.art.frame - dt * 12
  end
  if v.art.frame >= #char[v.art.state][v.art.anim].quad[v.art.dir] + 1 then
    v.art.frame = 1.1
  end
  if v.art.frame < 1 then
    v.art.frame = #char[v.art.state][v.art.anim].quad[v.art.dir] + .9
  end
end

return servergame
