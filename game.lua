local game = {}
local collision = require "collision"
local state = require "state"
local vector = require "vector"
local img = require "graphics"

local common_send = function (k, v)
  if state.network_mode == "server" then
    state.networking.host:sendToAll(k, v)
  elseif state.network_mode == "client" then
    state.networking.peer:send(k, v)
  end
end

game.ball = {baller = false, circle = {r = 32, p = {x=0,y=0}}, thrown = false, moving = {}}

local facing_to_dp = {
  function() -- facing 1
    players[id].d.x = players[id].d.x - 1
  end,
  function() end, -- facing 2
  function() -- facing 3
    players[id].d.x = players[id].d.x + 1
  end,
  function() -- facing 4
    players[id].d.x = players[id].d.x - 0.70710678118
    players[id].d.y = players[id].d.y - 0.70710678118
  end,
  function() -- facing 5
    players[id].d.y = players[id].d.y - 1
  end,
  function() -- facing 6
    players[id].d.x = players[id].d.x + 0.70710678118
    players[id].d.y = players[id].d.y - 1
  end,
  function() -- facing 7
    players[id].d.x = players[id].d.x - 0.70710678118
    players[id].d.y = players[id].d.y + 0.70710678118
  end,
  function() -- facing 8
    players[id].d.y = players[id].d.y + 1
  end,
  function() -- facing 9
    players[id].d.x = players[id].d.x + 0.70710678118
    players[id].d.y = players[id].d.y + 0.70710678118
  end,
}

game.init = function ()
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

game.update = function (dt)

  -- reduce velocity
  players[id].d.x = players[id].d.x * 0.9
  players[id].d.y = players[id].d.y * 0.9

  local facing = 2
  if love.keyboard.isDown("w") then
    facing = 5
  elseif love.keyboard.isDown("s") then
    facing = 8
  end
  if love.keyboard.isDown("a") then
    facing = facing - 1
  end
  if love.keyboard.isDown("d") then
    facing = facing + 1
  end

  if players[id].dead == false then
    if not joystick then
      facing_to_dp[facing]()
    else
      players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
      players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")
    end
  end

  mouse.x = love.mouse.getX()-win_width/2
  mouse.y = love.mouse.getY()-win_height/2

  if game.ball.baller == id then
    game.ball.circle.p.x = mouse.x+players[id].p.x
    game.ball.circle.p.y = mouse.y+players[id].p.y
  end

  if game.ball.moving.circle then
    game.ball.moving.circle.p = vector.sum(game.ball.moving.circle.p, game.ball.moving.velocity)
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
  if game.ball.moving.circle then
    love.graphics.circle("fill", game.ball.moving.circle.p.x, game.ball.moving.circle.p.y, game.ball.moving.circle.r)
  end

  if game.down.goal ~= nil then
    love.graphics.setColor(0, 0, 255)
    love.graphics.rectangle("fill", game.down.goal-2, 0, 4, field.h)
  end

  love.graphics.setColor(255, 255, 255)
  -- draw target
  if game.ball.circle.p.x then love.graphics.draw(img.target, math.floor(game.ball.circle.p.x), math.floor(game.ball.circle.p.y), 0, 1, 1, 24, 24) end

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
    if v.team == 1 then love.graphics.setColor(255, 100, 100) else love.graphics.setColor(100, 100, 255) end
    love.graphics.draw(img[char_img.."_overlay"], math.floor(v.p.x), math.floor(v.p.y), 0, 1, 1, 32, 32)

    --draw username
    love.graphics.print(v.name, math.floor(v.p.x)-math.floor(font:getWidth(v.name)/2), math.floor(v.p.y)-math.floor(v.r+font:getHeight()))

    if v.shield.active == true then -- draw shield
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.shield, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
      if v.team == 1 then love.graphics.setColor(255, 100, 100) else love.graphics.setColor(100, 100, 255) end
      love.graphics.draw(img.shield_overlay, math.floor(v.p.x)+math.floor(v.shield.d.x), math.floor(v.p.y)+math.floor(v.shield.d.y), 0, 1, 1, 12, 12)
    end
    if v.sword.active == true then -- draw sword
      love.graphics.setColor(255,  255, 255)
      love.graphics.draw(img.sword, math.floor(v.p.x)+math.floor(v.sword.d.x), math.floor(v.p.y)+math.floor(v.sword.d.y), math.atan2(v.sword.d.y, v.sword.d.x), 1, 1, 10, 10)
      if v.team == 1 then love.graphics.setColor(255, 100, 100) else love.graphics.setColor(100, 100, 255) end
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
    print("logging")
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

return game
