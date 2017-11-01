local game = {}
local collision = require "collision"
local state = require "state"
local field_canvas = nil

local common_send = function (k, v)
  if state.network_mode == "server" then
    state.networking.host:sendToAll(k, v)
  elseif state.network_mode == "client" then
    state.networking.peer:send(k, v)
  end
end

game.ball = {baller = qb, circle = {r = 32, p = {x=0,y=0}}}

game.init = function ()
  state.game = true
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 16
    v.speed = 30
  end

  field_canvas = game.draw_field(2000, 1000)
end

local draw_p_to_game_p = function(x, y)
  return x - win_width/2+players[id].p.x, y - win_height/2+players[id].p.y
end

game.update = function (dt)
  local facing = 2
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
  if game.ball.baller == id and love.keyboard.isDown("space") then
    game.ball.baller = nil
    common_send("newballer", game.ball.baller)
  end
  facing_to_dp[facing]()

  if joystick ~= nil then
    players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
    players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")
  end

  if state.network_mode == "server" then
    players[id].d.x = players[id].d.x * 0.9
    players[id].d.y = players[id].d.y * 0.9
    for i, v in pairs(players) do
      players[i].p.x = players[i].p.x + players[i].d.x*players[i].speed*dt
      players[i].p.y = players[i].p.y + players[i].d.y*players[i].speed*dt
      if i ~= id then
        if collision.check_overlap(players[id], players[i]) then
          local p1, p2 = collision.circle_vs_circle(players[id], players[i]) --
          players[id].p = p1
          players[i].p = p2
        end
      end
    end
  else
    players[id].d.x = players[id].d.x * 0.9
    players[id].d.y = players[id].d.y * 0.9
  end

  players[id].d.x = players[id].d.x * 0.9
  players[id].d.y = players[id].d.y * 0.9
  if not game.ball.baller then
    for k,v in pairs(players) do
      if collision.check_overlap(v, game.ball.circle) then
        game.ball.baller = k
        common_send("newballer", k)
      end
    end
  elseif game.ball.baller == id then
    game.ball.circle.p.x, game.ball.circle.p.y = draw_p_to_game_p(love.mouse.getPosition())
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
