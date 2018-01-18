local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
require "globals"
local servergame = {}

-- julians wack movement thing
servergame.input = require("keyboard")

local server_hooks = {
  -- if a client sends move data, do this
  posdif = function(data, client)
    local index = client:getIndex()
    players[index].d = data
    network.host:sendToAllBut(client, "posdif", {index = index, info = data})
  end,
  -- if a ball is thrown, do this
  ballthrow = function(data, client)
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
  -- set game state
  state.game = true
end

servergame.update = function(dt)
  -- update sock server
  network.host:update()

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
    for i, v in pairs(players) do
      for j, w in pairs(players) do
        if i ~= j then -- don't check for collisions with self
          if collision.check_overlap(players[j], players[i]) then
            local p1, p2 = collision.circle_vs_circle(players[j], players[i])
            players[j].p = p1
            players[i].p = p2
          end
        end
      end
    end
    -- send player's position to all
    network.host:sendToAll("pos", {info = v.p, index = i})
  end
  -- reduce server's velocity
  players[id].d = vector.scale(0.9, players[id].d)
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

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
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