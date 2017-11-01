local game = {}
local collision = require "collision"
local state = require "state"
local vector = require "vector"

local common_send = function (k, v)
  if state.network_mode == "server" then
    state.networking.host:sendToAll(k, v)
  elseif state.network_mode == "client" then
    state.networking.peer:send(k, v)
  end
end

game.ball = {baller = false, circle = {r = 32, p = {x=0,y=0}}, thrown = false}

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
  game.down = {num = 1, start = field.w/12*7, goal = field.w/3*2, t = 0}
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

  field.canvas = game.draw_field(field.w, field.h)
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

  game.down.t = game.down.t + dt
end

game.draw = function ()
  love.graphics.push()
  love.graphics.translate( win_width/2-players[id].p.x, win_height/2-players[id].p.y )
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(field.canvas)
  love.graphics.setColor(255, 255, 0)
  love.graphics.rectangle("fill", game.down.start-2, 0, 4, field.h)

  if game.down.goal ~= nil then
    love.graphics.setColor(0, 0, 255)
    love.graphics.rectangle("fill", game.down.goal-2, 0, 4, field.h)
  end

  love.graphics.setColor(255, 255, 255)
  if game.ball.circle.p.x then love.graphics.circle("fill", game.ball.circle.p.x, game.ball.circle.p.y, game.ball.circle.r) end
  for i, v in pairs(players) do
    if game.ball.baller == i then
      love.graphics.setColor(0, 0, 255)
    elseif v.team == 1 then
      love.graphics.setColor(255, 200, 200)
    else
      love.graphics.setColor(200, 200, 255)
      end
    if game.ball.baller == i then
      love.graphics.setColor(0, 0, 255)
    end

    if v.dead == false then
      love.graphics.circle("fill", v.p.x, v.p.y, v.r, 2*math.pi*v.r)
    else
      love.graphics.circle("line", v.p.x, v.p.y, v.r, 2*math.pi*v.r)
    end

    if v.shield.active == true then
      love.graphics.setColor(255, 0, 0)
      love.graphics.circle("fill", v.p.x+v.shield.d.x, v.p.y+v.shield.d.y, shield.r, 20*math.pi*shield.r)
    end
    if v.sword.active == true then
      love.graphics.setColor(255, 0, 0)
      love.graphics.circle("fill", v.p.x+v.sword.d.x, v.p.y+v.sword.d.y, sword.r, 20*math.pi*sword.r)
    end
  end

  love.graphics.pop()
  love.graphics.setColor(255, 255, 255)
  if game.down.goal ~= nil then
    love.graphics.print(tostring(game.down.num).." and "..tostring(math.floor(math.abs(game.down.start-game.down.goal)/field.w*120))..". Time: "..tostring(math.floor(game.down.t*10)/10), 1, 1)
  else
    love.graphics.print(tostring(game.down.num).." and goal. Time: "..tostring(math.floor(game.down.t*10)/10), 1, 1)
  end
  love.graphics.print(tostring(game.ball.thrown), 1, 14)
end

game.mousepressed = function (x, y, button)
  if button == 1 and game.ball.baller == id and game.ball.thrown == false and game.down.t > grace_time then
    game.ball.thrown = true
    common_send("throw", game.ball.thrown)
    players[game.ball.baller].speed = speed_table.offense
    game.ball.baller = false
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
    v.p.y = (field.h-#teams[v.team].members*32)/2+team_pos[v.team]*32
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

game.draw_field = function (w, h)
  local c = love.graphics.newCanvas(w, h)
  local line_w = w/140
  love.graphics.setCanvas(c)
  for i = 0, 12 do
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", (w/12)*i-line_w/2, 0, line_w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring((5-math.abs(i-7))*10), (w/12)*i-line_w/2, 0)
  end
  love.graphics.setCanvas()
  return c
end

return game
