local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
local q = require "queue"
require "globals"
local clientgame = {}

local difflog = {}
difflog.p = {}
difflog.tail = difflog.head

-- julians wack movement thing
clientgame.input = require("keyboard")

-- set up variables
local ball = {p = {x = 0, y = 0}, z = 0, d = {x = 0, y = 0}, r = 8, owner = nil, thrown = false}
local down = {scrim = 0, goal = 0, num = 0, dead = false, t = 3}

local effects = {}
local alerts = {}

local client_hooks = {
  pos = function(data)
    players[data.index].p = data.info
  end,
  posdif = function(data)
    players[data.index].d = data.info
  end,
  throw = function(data)
    ball = data
  end,
  catch = function(data)
    ball.owner = data
    -- add alert
    if players[ball.owner].team ~= players[qb].team then
      alerts[#alerts+1] = {txt = players[ball.owner].name.." has intecepted the ball", team = players[ball.owner].team}
    else
      alerts[#alerts+1] = {txt = players[ball.owner].name.." has caught the ball", team = players[ball.owner].team}
    end
  end,
  newdown = function(data)
    down = data.down
    qb = data.qb
    -- give ball to quarterback
    ball.owner = qb
    ball.thrown = false
    -- reset players
    for i, v in pairs(players) do
      clientgame.set_speed(i)
      v.sword.active = false
      v.shield.active = false
      v.dead = false
    end
    -- reset target
    camera.x = players[id].p.x
    camera.y = players[id].p.y
    -- clear effects
    effects = {}
  end,
  ballpos = function(data)
    ball.p = data
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z = (dist*dist-ball.height*dist)/512*-1
    ball.angle = math.atan2(ball.d.y+z-ball.z, ball.d.x)
    ball.z = z
  end,
  downdead = function(data)
    down.dead = true
    down.t = 3
    ball.thrown = false
  end,
  sword = function(data)
    players[data.index].sword.active = data.active
    players[data.index].sword.d = vector.scale(sword.dist, vector.norm(data.mouse))
    players[data.index].sword.t = sword.t
    -- adjust speed
    clientgame.set_speed(data.index)
  end,
  shieldstate = function(data)
    players[data.index].shield.active = data.info
    -- adjust speed
    clientgame.set_speed(data.index)
  end,
  mousepos = function(data, client)
    players[data.index].mouse = data.info
    if players[data.index].shield.active then
      players[data.index].shield.d = vector.scale(shield.dist, vector.norm(data.info))
    end
  end,
  dead = function(data)
    -- add alert
    alerts[#alerts+1] = {txt = players[data.killer].name.." has tackled "..players[data.victim].name, team = players[data.killer].team}
    players[data.victim].dead = true
    -- blood spurt
    for j = 1, 4 do
      effects[#effects+1] = {img = "blood", quad = "drop", x = players[data.victim].p.x, y = players[data.victim].p.y, z = 18, ox = 8, oy = 8, dx = math.random(-2, 2), dy = math.random(-2, 2), dz = 2}
    end
  end,
  touchdown = function(data)
    -- add alert
    alerts[#alerts+1] = {txt = players[ball.owner].name.." has scored a touchdown for "..team_info[data].name, team = data}
    -- do stuff
    score[data] = score[data] + 7
    down.dead = true
    down.t = 3
    ball.thrown = false
  end,
  disconnect = function(data)
    love.event.quit()
  end,
}

clientgame.init = function()
  love.mouse.setRelativeMode(true)
  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    network.peer:on(k, v)
  end
  -- set the base gui for the client menu
  state.gui = gui.new({})
  -- set up initial variables for players
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 10
    v.shield = {active = false, d = {x = 0, y = 0}, t = 0, canvas = love.graphics.newCanvas(32, 32)}
    v.sword = {active = false, d = {x = 0, y = 0}, t = 0, canvas = love.graphics.newCanvas(32, 32)}
    v.dead = false
    v.mouse = {x = 0, y = 0}
    v.art = {state = "base", anim = "idle", dir = 1, frame = 1, canvas = love.graphics.newCanvas(32, 48)}
    -- set the speed for players
    clientgame.set_speed(i)
  end
  -- set game state
  state.game = true
end

clientgame.update = function(dt)
  -- update sock client
  network.peer:update()

  -- get server mouse positions
  players[id].mouse.x = camera.x-players[id].p.x
  players[id].mouse.y = camera.y-players[id].p.y
  -- send client mouse position to server
  network.peer:send("mousepos", players[id].mouse)
  -- get client's direction
  clientgame.input.direction()
  -- send client's difference in position

  network.peer:send("posdif", players[id].d)
  local oldp = players[id].p
  for i, v in pairs(players) do
    -- move player based on their diff
    v.p = vector.sum(v.p, vector.scale(v.speed*dt, v.d))
    -- apply collision to player
    clientgame.collide(v)
    --apply collision between players
    for j, w in pairs(players) do
      if i ~= j then
        if collision.check_overlap(players[j], players[i]) then
          local p1, p2 = collision.circle_vs_circle(players[j], players[i]) --
          w.p = p1
          v.p = p2
        end
      end
    end
    -- do art stuff
    clientgame.animate(i, v, dt)
  end
  -- reduce client's velocity
  players[id].d = vector.scale(0.9, players[id].d)
  -- predict ball position
  if ball.thrown then
    -- move the ball
    ball.p = vector.sum(ball.p, vector.scale(dt * 60 * ball_speed, ball.d))
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z = (dist*dist-ball.height*dist)/512*-1
    ball.angle = math.atan2(ball.d.y-z+ball.z, ball.d.x)
    ball.z = z
    -- if ball hits the ground, stop
    if ball.z <= 0 then
      effects[#effects+1] = {img = "stuckarrow", x = ball.p.x, y = ball.p.y, z = 0, ox = 16, oy = 16}
      ball.thrown = false
    end
  end
  -- adjust shield pos
  if players[id].shield.active == true then
    players[id].shield.d = vector.scale(shield.dist, vector.norm(players[id].mouse))
  end
  -- advance play clock
  if down.t > 0 then
    down.t = down.t - dt
  end
  -- update effects
  for i, v in pairs(effects) do
    if v.dx then
      v.x = v.x + v.dx
      v.dx = v.dx * 0.9
    end
    if v.dy then
      v.y = v.y + v.dy
      v.dy = v.dy * 0.9
    end
    if v.dz then
      if v.z > 0 then
        v.z = v.z + v.dz
        v.dz = v.dz - dt * 12
      else
        v.z = 0
        v.quad = "puddle"
      end
    end
  end
  --update alerts
  if #alerts > 0 then
    if alerts[1].t then
      alerts[1].t = alerts[1].t - dt
      if alerts[1].t <= 0 then
        table.remove(alerts, 1)
      end
    else
      alerts[1].t = 2
    end
  end
end

clientgame.draw = function()
  local queue = {}

  for i, v in pairs(players) do
    love.graphics.setCanvas(v.art.canvas)
    love.graphics.clear()
    love.graphics.setColor(255, 255, 255)
    --draw base sprite
    love.graphics.draw(char[v.art.state][v.art.anim].img, char[v.art.state][v.art.anim].quad[v.art.dir][math.floor(v.art.frame)])

    --draw colored overlay
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.draw(char[v.art.state][v.art.anim.."overlay"].img, char[v.art.state][v.art.anim].quad[v.art.dir][math.floor(v.art.frame)])

    love.graphics.setCanvas()
    queue[#queue+1] = {img = v.art.canvas, x = math.floor(v.p.x), y = math.floor(v.p.y), ox = 16, oy = 48}

     -- draw shield
    if v.shield.active == true then
      love.graphics.setCanvas(v.shield.canvas)
      love.graphics.clear()

      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.shield, quad.shield[v.art.dir])
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.shield_overlay, quad.shield[v.art.dir])

      love.graphics.setCanvas()
      queue[#queue+1] = {img = v.shield.canvas, x = math.floor(v.p.x)+math.floor(v.shield.d.x), y = math.floor(v.p.y)+math.floor(v.shield.d.y*.75), z = 18, ox = 16, oy = 16}
    end

     -- draw sword
    if v.sword.active == true then
      love.graphics.setCanvas(v.sword.canvas)
      love.graphics.clear()

      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(img.sword)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.sword_overlay)

      love.graphics.setCanvas()
      queue[#queue+1] = {img = v.sword.canvas, x = math.floor(v.p.x)+math.floor(v.sword.d.x), y = math.floor(v.p.y)+math.floor(v.sword.d.y*.75), z = 18, r = math.atan2(v.sword.d.y, v.sword.d.x), ox = 16, oy = 16}
    end

    --queue username
    queue[#queue+1] = {txt = v.name, x = math.floor(v.p.x)-math.floor(font:getWidth(v.name)/2), y = math.floor(v.p.y), z = math.floor(48+font:getHeight()), color = team_info[v.team].color}
  end

  -- set up camera
  love.graphics.push()
  love.graphics.translate(win_width/2-math.floor(camera.x), win_height/2-math.floor(camera.y))
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field)
  -- draw line of scrimmage
  love.graphics.setColor(255, 0, 0)
  love.graphics.rectangle("fill", down.scrim-2, 0, 4, field.h)
  -- draw first down line
  if down.goal then
    love.graphics.setColor(255, 225, 0)
    love.graphics.rectangle("fill", down.goal-2, 0, 4, field.h)
  end

  -- draw flat player things (e.g. shadows)
  for i, v in pairs(players) do
    -- draw shadow
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img.shadow, math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 8, 10)
    -- draw target prediction
    if id == qb and ball.owner == id and v.team == players[qb].team and i ~= qb then
      local dist = math.sqrt((players[qb].p.x-v.p.x)*(players[qb].p.x-v.p.x)+(players[qb].p.y-v.p.y)*(players[qb].p.y-v.p.y))
      local adj_d = vector.scale(v.speed/60, v.d)
      local p = vector.sum(vector.scale(- dist / (math.sqrt(vector.mag_sq(adj_d)) - ball_speed), adj_d), v.p)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.line(v.p.x, v.p.y, p.x, p.y)
      love.graphics.draw(img.charnode, math.floor(p.x), math.floor(p.y), 0, 1, 1, 16, 16)
    end
  end

  -- draw effects (blood, etc.)
  love.graphics.setColor(255, 255, 255)
  for i, v in ipairs(effects) do
    if not v.ox then v.ox = 0 end
    if not v.oy then v.oy = 0 end
    if v.quad then
      love.graphics.draw(img[v.img], quad[v.quad], math.floor(v.x), math.floor(v.y-v.z), 0, 1, 1, v.ox, v.oy)
    else
      love.graphics.draw(img[v.img], math.floor(v.x), math.floor(v.y-v.z), 0, 1, 1, v.ox, v.oy)
    end
  end

  --draw qb cursor
  love.graphics.setColor(team_info[players[qb].team].color)
  if ball.thrown and not ball.owner then
    love.graphics.draw(img.balltarget, math.floor(ball.goal.x), math.floor(ball.goal.y), 0, 1, 1, 16, 16)
  elseif id ~= qb and ball.owner and ball.owner == qb then
    love.graphics.draw(img.qbtarget, math.floor(players[qb].p.x+players[qb].mouse.x), math.floor(players[qb].p.y+players[qb].mouse.y), 0, 1, 1, 16, 16)
  end

  -- draw personal cursor
  love.graphics.setColor(team_info[players[id].team].color)
  if id ~= qb or id ~= ball.owner then
    love.graphics.draw(img.target, math.floor(camera.x), math.floor(camera.y), 0, 1, 1, 16, 16)
  elseif id == qb and ball.owner and ball.owner == qb then
    love.graphics.draw(img.qbtarget, math.floor(camera.x), math.floor(camera.y), 0, 1, 1, 16, 16)
  end


  -- draw ball
  if ball.thrown then
    love.graphics.setColor(255, 255, 255)
    -- shadow
    love.graphics.draw(img.shadow, math.floor(ball.p.x), math.floor(ball.p.y), 0, 1, 1, 8, 8)
    -- ball
    queue[#queue+1] = {img = img.arrow, x = math.floor(ball.p.x), y = math.floor(ball.p.y), z = math.floor(ball.z), r = ball.angle, ox = 8, oy = 8}
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
        love.graphics.draw(v.img, v.quad, v.x, v.y-v.z, v.r, 1, 1, v.ox, v.oy)
      else
        love.graphics.draw(v.img, v.x, v.y-v.z, v.r, 1, 1, v.ox, v.oy)
      end
    elseif v.txt then
      love.graphics.setColor(v.color)
      love.graphics.print(v.txt, v.x, v.y-v.z)
    end
  end

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
  -- draw scoreboard
  love.graphics.draw(img.scoreboard, (win_width-160)/2, 0)
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.scoreboard_overlay, (win_width-160)/2, 0)
  love.graphics.setColor(team_info[2].color)
  love.graphics.draw(img.scoreboard_overlay, (win_width)/2, 0)
  love.graphics.setColor(229, 229, 229)
  love.graphics.print(team_info[1].name, math.floor((win_width-80-font:getWidth(team_info[1].name))/2), 8)
  love.graphics.print(score[1], math.floor((win_width-80-font:getWidth(tostring(score[1])))/2), 24)
  love.graphics.print(team_info[2].name, math.floor((win_width+80-font:getWidth(team_info[1].name))/2), 8)
  love.graphics.print(score[2], math.floor((win_width+80-font:getWidth(tostring(score[2])))/2), 24)
  love.graphics.print(tostring(down.num)..num_suffix[down.num].." and "..tostring(math.ceil(math.abs(down.goal - down.scrim)/field.w*120)), (win_width-160)/2+4, 52)
  love.graphics.setColor(51, 51, 51)
  if down.dead then
    love.graphics.printf(math.ceil(down.t+grace_time), (win_width+160)/2-32, 52, 32, "center")
  else
    love.graphics.printf(math.ceil(down.t), (win_width+160)/2-32, 52, 32, "center")
  end

  -- draw alerts
  if #alerts > 0 then
    love.graphics.setColor(team_info[alerts[1].team].color)
    love.graphics.print(alerts[1].txt, math.floor((win_width-font:getWidth(alerts[1].txt))/2), win_height/2+32)
  end
end

clientgame.mousepressed = function(x, y, button)
  if button == 1 and down.dead == false and down.t <= 0 and players[id].dead == false then
    if ball.owner == id and qb == id then
      network.peer:send("throw", players[id].mouse)
    elseif ball.owner ~= id and ((ball.owner and players[ball.owner].team == players[id].team) or (not ball.owner and players[qb].team == players[id].team)) then
      players[id].shield.active = true
      network.peer:send("shieldstate", true)
    elseif ball.owner ~= id and ((ball.owner and players[ball.owner].team ~= players[id].team) or (not ball.owner and players[qb].team ~= players[id].team)) then
      players[id].sword.active = true
      players[id].sword.d = vector.scale(sword.dist, vector.norm(players[id].mouse))
      players[id].sword.t = sword.t
      network.peer:send("sword", players[id].mouse)
    end
  end
end

clientgame.mousereleased = function(x, y, button)
  if button == 1 and down.t <= 0 and players[id].dead == false then
    if players[id].shield.active == true then
      players[id].shield.active = false
      network.peer:send("shieldstate", false)
    end
  end
end

clientgame.mousemoved = function(x, y, dx, dy, istouch)
  -- find camera values
  camera.x = camera.x + dx*global_dt*30
  camera.y = camera.y + dy*global_dt*30
end

clientgame.quit = function()
  network.peer:disconnectNow()
end

clientgame.back_to_main = function()
  clientgame.quit()
  network.mode = nil
  state.gui = gui.new(menus[1])
end

clientgame.set_speed = function (i) -- based on player's state, set a speed
  if i == ball.owner then
    players[i].speed = speed_table.with_ball
  elseif players[i].shield.active then
    print("oops")
    players[i].speed = speed_table.shield
  elseif players[i].sword.active then
    players[i].speed = speed_table.sword
  elseif players[i].team == players[qb].team then
    players[i].speed = speed_table.offense
  else
    players[i].speed = speed_table.defense
  end
  print(ball.owner, i, players[i].team == players[qb].team, players[i].shield.active, players[i].speed)
end

clientgame.collide = function (v)
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

clientgame.animate = function(i, v, dt)
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
  if v.sword.active then
    dir = v.sword.d
  elseif v.shield.active then
    dir = v.shield.d
  end
  -- get direction
  if dir.y < 0 then
    v.art.dir = 8+math.floor(math.atan2(dir.y, dir.x)/math.pi*4+1.5)
  else
    v.art.dir = math.floor(math.atan2(dir.y, dir.x)/math.pi*4+1.5)
  end
  -- make sure direction is in bounds (1-8)
  if v.art.dir > 8 then
    v.art.dir = 1
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

return clientgame
