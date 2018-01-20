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
local ball = {p = {x = 0, y = 0}, z = 0, d = {x = 0, y = 0}, r = 8, owner = nil}
local down = {scrim = 50, goal = 10, num = 0}

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
    -- ball is thrown
    ball.owner = nil
    -- set initial position
    ball.p.x = players[index].p.x
    ball.p.y = players[index].p.y
    ball.z = 0
    -- set direction
    ball.d = vector.norm(data.p)
    ball.goal = vector.sum(data.p, {x = players[index].p.x, y = players[index].p.y})
    ball.start = {x = players[index].p.x, y = players[index].p.y}
    ball.height = math.sqrt((ball.goal.x-ball.p.x)*(ball.goal.x-ball.p.x)+(ball.goal.y-ball.p.y)*(ball.goal.y-ball.p.y))

    network.host:sendToAll("throw", ball)
  end,
  -- if client is attacking, do this
  attack = function(data, client)
  end,
  -- if client puts up shield, do this
  startdefend = function(data, client)
  end,
  -- if clients drops shield, do this
  stopdefend = function (data, client)
  end,
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
    -- set the speed for players
    servergame.set_speed(i)
  end
  -- set up initial down
  servergame.newdown()
  -- set game state
  state.game = true
end

servergame.update = function(dt)
  -- update sock server
  network.host:update()

  -- get server mouse positions
  mouse.p.x = love.mouse.getX()-win_width/2
  mouse.p.y = love.mouse.getY()-win_height/2
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
  end
  -- reduce server's velocity
  players[id].d = vector.scale(0.9, players[id].d)

  -- move the ball
  if not ball.owner then
    -- move the ball
    ball.p = vector.sum(ball.p, vector.scale(dt * 60 * 4, ball.d))
    -- change ball's height / angle
    local dist = math.sqrt((ball.start.x-ball.p.x)*(ball.start.x-ball.p.x)+(ball.start.y-ball.p.y)*(ball.start.y-ball.p.y))
    local z  = (dist*dist-ball.height*dist)/512
    ball.angle = math.atan2(ball.d.y+z-ball.z, ball.d.x)
    ball.z = z
    -- if ball hits the ground, stop
    if ball.z >= 0 then
      ball.owner = qb
    end

    -- send new ball position
    network.host:sendToAll("ballpos", ball.p)
  end
  -- catch the ball
  if ball.z < 16 and not ball.owner then
    for i, v in pairs(players) do
      if i ~= qb and collision.check_overlap(v, ball) then -- makes sure catcher isn't qb to prevent immediate catches after throwing
        ball.owner = i
        network.host:sendToAll("catch", i)
        break
      end
    end
  end
end

servergame.draw = function()
  love.graphics.push()
  love.graphics.translate(math.floor(win_width/2-players[id].p.x), math.floor(win_height/2-players[id].p.y))
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field)

  for i, v in pairs(players) do
    local char_img = "char"
    if v.dead == true then
      char_img = "char_dead"
    -- elseif game.ball.baller == i and (i ~= qb or game.ball.thrown == true) then
    --   char_img = "char_baller"
    -- elseif game.ball.baller == i then
    --   char_img = "char_qb"
    end

    --draw base sprite
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img[char_img], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw colored overlay
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.draw(img[char_img.."_overlay"], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw username
    love.graphics.print(v.name, math.floor(v.p.x)-math.floor(font:getWidth(v.name)/2), math.floor(v.p.y)-math.floor(v.r+font:getHeight()))
  end

  -- draw ball
  if not ball.owner then
    love.graphics.setColor(255, 255, 255)
    -- shadow
    love.graphics.draw(img.shadow, math.floor(ball.p.x), math.floor(ball.p.y), 0, 1/(ball.z*0.04-1), 1/(ball.z*0.04-1), 16, 16)
    -- ball
    love.graphics.draw(img.arrow, math.floor(ball.p.x), math.floor(ball.p.y)+math.floor(ball.z), ball.angle, 1, 1, 16, 16)
  end

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
end

servergame.mousepressed = function(x, y, button)
  if button == 1 then
    if ball.owner == id then
      -- ball is thrown
      ball.owner = nil
      -- set initial position
      ball.p.x = players[id].p.x
      ball.p.y = players[id].p.y
      ball.z = 0
      -- set direction
      ball.d = vector.norm({x = mouse.p.x, y = mouse.p.y})
      ball.goal = vector.sum({x = mouse.p.x, y = mouse.p.y}, {x = players[id].p.x, y = players[id].p.y})
      ball.start = {x = players[id].p.x, y = players[id].p.y}
      ball.height = math.sqrt((ball.goal.x-ball.p.x)*(ball.goal.x-ball.p.x)+(ball.goal.y-ball.p.y)*(ball.goal.y-ball.p.y))

      network.host:sendToAll("throw", ball)
    end
  end
end

servergame.newdown = function()
  -- progress down number
  down.num = down.num + 1
  if down.num > 4 then
    -- swap possession
  end
  -- give ball to quaterback
  ball.owner = qb
  network.host:sendToAll("newdown", down)
end

servergame.set_speed = function (i) -- based on player's state, set a speed
  -- if i == game.ball.baller then
  --   players[i].speed = speed_table.with_ball
  -- elseif players[i].shield.active == true then
  --   players[i].speed = speed_table.shield
  -- elseif players[i].sword.active == true then
  --   players[i].speed = speed_table.sword
  -- elseif players[i].team == players[qb].team then
  --   players[i].speed = speed_table.offense
  -- else
  --   players[i].speed = speed_table.defense
  -- end
  players[i].speed = 16
end

servergame.collide = function (v)
  -- -- collide with line of scrimmage if down has hardly started
  -- if game.down.t <= grace_time and v.team == 1 and v.p.x+v.r > game.down.start then
  --   v.d.x = 0
  --   v.p.x = game.down.start-v.r
  -- elseif game.down.t <= grace_time and v.team == 2 and v.p.x-v.r < game.down.start then
  --   v.d.x = 0
  --   v.p.x = game.down.start+v.r
  -- end

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
