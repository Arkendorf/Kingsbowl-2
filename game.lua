local game = {}
local collision = require "collision"
local state = require "state"
local vector = require "vector"

local sword_dist, shield_dist = 10, 5
local field_canvas = nil
local mouse = {x = 0, y = 0}
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
  game.ball = {baller = nil, circle = {r = 32, p = {}}, thrown = false}
  state.game = true
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 16
    v.speed = 30
    v.shield = {active = false, p = {1, 0}, t = 0}
    v.sword = {active = false, p = {1, 0}, t = 0}
  end

  field_canvas = game.draw_field(2000, 1000)
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

  if joystick == nil then
    facing_to_dp[facing]()
  else
    players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
    players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")
  end

  mouse.x = love.mouse.getX()-win_width/2
  mouse.y = love.mouse.getY()-win_height/2

  if not game.ball.baller then
    for k,v in pairs(players) do
      if collision.check_overlap(v, game.ball.circle) then
        game.ball.baller = k
      end
    end
  elseif game.ball.baller == id then
    game.ball.circle.p.x = mouse.x+players[id].p.x
    game.ball.circle.p.y = mouse.y+players[id].p.y
  end

  for i, v in pairs(players) do
    if v.shield.active == true then v.shield.t = v.shield.t + dt end
    if v.sword.active == true then v.sword.t = v.sword.t + dt end
    if v.sword.t > 1 then
      v.sword.active = false
      v.sword.t = 0
      v.speed = 30
      if state.network_mode == "server" then
        state.networking.host:sendToAll("sword", {info = {active = false}, index = i})
      end
    end
  end

  if players[id].shield.active == true then
    if state.network_mode == "client" then
      state.networking.peer:send("shieldpos", vector.scale(shield_dist, vector.norm(mouse)))
    else
      players[id].shield.d = vector.scale(shield_dist, vector.norm(mouse))
    end
  end
end

game.draw = function ()
  love.graphics.translate( win_width/2-players[id].p.x, win_height/2-players[id].p.y )
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(field_canvas)

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
    love.graphics.circle("fill", v.p.x, v.p.y, v.r, 2*math.pi*v.r)
    if v.shield.active == true then
      love.graphics.setColor(255, 0, 0)
      love.graphics.circle("fill", v.p.x+v.shield.d.x, v.p.y+v.shield.d.y, 10, 20*math.pi)
    end
    if v.sword.active == true then
      love.graphics.setColor(255, 0, 0)
      love.graphics.circle("fill", v.p.x+v.sword.d.x, v.p.y+v.sword.d.y, 10, 20*math.pi)
    end
  end
end

game.mousepressed = function (x, y, button)
  if button == 1 and game.ball.baller == id and game.ball.thrown == false then
    game.ball.thrown = true
    game.ball.baller = nil
  elseif button == 1 and game.ball.baller ~= id and players[id].team == players[game.ball.baller].team then
    if state.network_mode == "client" then
      state.networking.peer:send("shield", {active = true, d = vector.scale(shield_dist, vector.norm(mouse))})
    else
      players[id].shield = {active = true, d = vector.scale(shield_dist, vector.norm(mouse)), t = 0}
      players[id].speed = 26
    end
  elseif button == 1 and players[id].team ~= players[game.ball.baller].team then
    if state.network_mode == "client" then
      state.networking.peer:send("sword", {active = true, d = vector.scale(sword_dist, vector.norm(mouse))})
    else
      players[id].sword = {active = true, d = vector.scale(sword_dist, vector.norm(mouse)), t = 0}
      players[id].speed = 0
    end
  end
end

game.mousereleased = function (x, y, button)
  if button == 1 and players[id].shield.active == true then
    if state.network_mode == "client" then
      state.networking.peer:send("shield", {active = false})
    else
      players[id].shield = {active = false, t = 0}
      players[id].speed = 30
    end
  end
end

game.draw_field = function (w, h)
  local c = love.graphics.newCanvas(w, h)
  local line_w = w/140
  love.graphics.setCanvas(c)
  love.graphics.rectangle("fill", -line_w/2, 0, line_w, h)
  love.graphics.rectangle("fill", w-line_w/2, 0, line_w, h)
  for i = 2, 12 do
    love.graphics.setColor(255, 255, 255)
    love.graphics.rectangle("fill", (w/14)*i-line_w/2, 0, line_w, h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring((5-math.abs(i-7))*10), (w/14)*i-line_w/2, 0)
  end
  love.graphics.setCanvas()
  return c
end

return game
