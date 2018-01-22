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

local client_hooks = {
  pos = function(data)
    players[data.index].p = data.info
  end,
  posdif = function(data)
    players[data.index].d = data.info
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
    -- set the speed for players
    clientgame.set_speed(i)
  end
  -- set game state
  state.game = true
end

clientgame.update = function(dt)
  -- update sock client
  network.peer:update()

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
end

clientgame.draw = function()
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

clientgame.set_speed = function (i) -- based on player's state, set a speed
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

clientgame.collide = function (v)
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

return clientgame
