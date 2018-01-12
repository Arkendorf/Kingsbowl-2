local game = {}
local collision = require "collision"
local state = require "state"
local vector = require "vector"
local network = require "network"

local common_send = function (k, v)
  if network.mode == "server" then
    network.host:sendToAll(k, v)
  elseif network.mode == "client" then
    network.peer:send(k, v)
  end
end

game.init = function ()
  game.input = require("keyboard")
  game.ball = {baller = false, circle = {r = 32, p = {x=0,y=0}}, thrown = false, moving = {}}
  game.down = {num = 1, start = field.w/12*7, goal = field.w/3*2, t = 0, dir = 1}
  game.ball.baller = qb
  state.game = true
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 16
    v.shield = {active = false, d = {x = 0, y = 0}, t = 0}
    v.sword = {active = false, d = {x = 0, y = 0}, t = 0}
    game.set_speed(i)
  end
  game.reset_players()
end

local draw_p_to_game_p = function(x, y)
  return x - win_width/2+players[id].p.x, y - win_height/2+players[id].p.y
  end

game.update = function(dt)
  -- reduce velocity
  players[id].d = vector.scale(0.9, players[id].d)

  game.input.direction()
  mouse.x = love.mouse.getX()-win_width/2
  mouse.y = love.mouse.getY()-win_height/2

  if game.ball.baller == id then
    game.ball.circle.p = vector.sum(mouse, players[id].p)
  end

  if game.ball.moving.circle then
    game.ball.moving.circle.d = vector.scale(dt*60*8, game.ball.moving.velocity)
    game.ball.moving.circle.p = vector.sum(game.ball.moving.circle.p, game.ball.moving.circle.d)
  end

  game.down.t = game.down.t + dt
end

game.draw = function ()
  love.graphics.push()
  love.graphics.translate(math.floor(win_width/2-players[id].p.x), math.floor(win_height/2-players[id].p.y))
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field)
  love.graphics.setColor(255, 0, 0)
  love.graphics.rectangle("fill", game.down.start-2, 0, 4, field.h)

  if game.ball.moving.circle then -- draw ball
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img.arrow, math.floor(game.ball.moving.circle.p.x), math.floor(game.ball.moving.circle.p.y), math.atan2(game.ball.moving.circle.d.y, game.ball.moving.circle.d.x), 1, 1, 16, 16)
  end

  if game.down.goal ~= nil then
    love.graphics.setColor(0, 0, 255)
    love.graphics.rectangle("fill", game.down.goal-2, 0, 4, field.h)
  end

  love.graphics.setColor(255, 255, 255)
  -- draw target
  if game.ball.circle.p.x and (not game.ball.baller or not game.ball.thrown) then
    love.graphics.draw(img.target, math.floor(game.ball.circle.p.x), math.floor(game.ball.circle.p.y), 0, 1, 1, 24, 24)
  end

  for i, v in pairs(players) do
    local char_img = "char"
    if v.dead == true then
      char_img = "char_dead"
    elseif game.ball.baller == i and (i ~= qb or game.ball.thrown == true) then
      char_img = "char_baller"
    elseif game.ball.baller == i then
      char_img = "char_qb"
    end

    --draw base sprite
    love.graphics.setColor(255, 255, 255)
    love.graphics.draw(img[char_img], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw colored overlay
    love.graphics.setColor(team_info[v.team].color)
    love.graphics.draw(img[char_img.."_overlay"], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw username
    love.graphics.print(v.name, math.floor(v.p.x)-math.floor(font:getWidth(v.name)/2), math.floor(v.p.y)-math.floor(v.r+font:getHeight()))

    if v.shield.active == true then -- draw shield
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.shield, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.shield_overlay, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
    end
    if v.sword.active == true then -- draw sword
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.sword, math.floor(v.p.x)+math.floor(v.sword.d.x), math.floor(v.p.y)+math.floor(v.sword.d.y), math.atan2(v.sword.d.y, v.sword.d.x), 1, 1, 10, 10)
      love.graphics.setColor(team_info[v.team].color)
      love.graphics.draw(img.sword_overlay, math.floor(v.p.x)+math.floor(v.sword.d.x), math.floor(v.p.y)+math.floor(v.sword.d.y), math.atan2(v.sword.d.y, v.sword.d.x), 1, 1, 10, 10)
    end
  end

  love.graphics.pop()
  love.graphics.setColor(0, 0, 0, 200)
  love.graphics.rectangle("fill", 0, 0, 112, 28)
  love.graphics.setColor(255, 255, 255)
  if game.down.goal ~= nil then
    love.graphics.print(tostring(game.down.num)..num_suffix[game.down.num].." and "..tostring(math.floor(math.abs(game.down.start-game.down.goal)/field.w*120))..". Time: "..tostring(math.floor(game.down.t*10)/10), 1, 1)
  else
    love.graphics.print(tostring(game.down.num)..num_suffix[game.down.num].." and goal. Time: "..tostring(math.floor(game.down.t*10)/10), 1, 1)
  end
  love.graphics.print("Score: "..tostring(score[1]).." to "..tostring(score[2]), 1, 14)
end

game.mousepressed = function (x, y, button)
  if button == 1 and game.ball.baller == id and game.ball.thrown == false and game.down.t > grace_time then
    game.ball.thrown = true
    common_send("throw", game.ball.thrown)
    players[game.ball.baller].speed = speed_table.offense
    game.ball.moving.circle = {p = {}, r = players[game.ball.baller].r}
    game.ball.moving.circle.p = {x = players[game.ball.baller].p.x, y = players[game.ball.baller].p.y}
    game.ball.moving.velocity = vector.norm(mouse)
    game.ball.baller = false
    common_send("thrown", game.ball.moving)
    common_send("newballer", game.ball.baller)
  end
end

game.shield_pos = function()
  return vector.scale(shield.dist, vector.norm(mouse))
end

game.sword_pos = function()
  return vector.scale(sword.dist, vector.norm(mouse))
end

game.kill = function (i)
  players[i].dead = true
  players[i].sword.active = false
  players[i].shield.active = false
end

game.reset_players = function ()
  game.ball.baller = qb
  game.ball.thrown = false

  local team_pos = {0, 0}
  for i, v in pairs(players) do
    v.sword.active = false
    v.shield.active = false
    game.set_speed(i)
    v.dead = false
    if v.team == 1 then
      v.p.x = game.down.start - 32
    else
      v.p.x = game.down.start + 32
    end
    v.p.y = (field.h-#teams[v.team].members*48)/2+team_pos[v.team]*48
    v.d.x, v.d.y = 0, 0
    team_pos[v.team] = team_pos[v.team] + 1
  end
end

game.set_speed = function (i)
  if i == game.ball.baller then
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

game.collide = function (v)
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

return game
