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
  end,
  newdown = function(data)
    down = data.down
    qb = data.qb
    -- give ball to quarterback
    ball.owner = qb
    ball.thrown = false
    -- reset players
    for i, v in pairs(players) do
      v.sword.active = false
      v.shield.active = false
      v.dead = false
    end
  end,
  ballpos = function(data)
    ball.p = data
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z = ((dist*dist-ball.height*dist)/512-18)*-1
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
    players[data].dead = true
  end,
  touchdown = function(data)
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
    v.r = 16
    v.shield = {active = true, d = {x = 0, y = 0}, t = 0}
    v.sword = {active = false, d = {x = 0, y = 0}, t = 0}
    v.dead = false
    v.mouse = {x = 0, y = 0}
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
  players[id].mouse.x = love.mouse.getX()-win_width/2
  players[id].mouse.y = love.mouse.getY()-win_height/2
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
          if players[i].shield.active then
            players[j].sticky = true
            print(1)
          end
          if players[j].shield.active then
            print(1)
            players[i].sticky = true
          end
          local p1, p2 = collision.circle_vs_circle(players[j], players[i]) --
          w.p = p1
          v.p = p2
        end
      end
    end
  end
  -- reduce client's velocity
  players[id].d = vector.scale(0.9, players[id].d)
  -- predict ball position
  if ball.thrown then
    -- move the ball
    ball.p = vector.sum(ball.p, vector.scale(dt * 60 * 4, ball.d))
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z = ((dist*dist-ball.height*dist)/512-18)*-1
    ball.angle = math.atan2(ball.d.y-z+ball.z, ball.d.x)
    ball.z = z
    -- if ball hits the ground, stop
    if ball.z <= 0 then
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
end

clientgame.draw = function()
  love.graphics.push()
  love.graphics.translate(math.floor(win_width/2-players[id].p.x), math.floor(win_height/2-players[id].p.y))
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field)
  -- draw line of scrimmage
  love.graphics.setColor(0, 0, 255)
  love.graphics.rectangle("fill", down.scrim-2, 0, 4, field.h)
  -- draw first down line
  if down.goal then
    love.graphics.setColor(255, 0, 0)
    love.graphics.rectangle("fill", down.goal-2, 0, 4, field.h)
  end

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
    love.graphics.draw(img.arrow, math.floor(ball.p.x), math.floor(ball.p.y)-math.floor(ball.z), ball.angle, 1, 1, 16, 16)
  end

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
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

return clientgame
