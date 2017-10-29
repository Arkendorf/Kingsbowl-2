local game = {}
local collision = require "collision"
local state = require "state"

game.init = function ()
  state.game = true
  for i, v in pairs(players) do
    v.p = {x = i*32, y = i*32}
    v.d = {x = 0, y = 0}
    v.r = 16
  end
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
  facing_to_dp[facing]()

  if joystick ~= nil then
    players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
    players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")
  end

  if state.network_mode == "server" then
    for i, v in pairs(players) do
      players[i].p.x = players[i].p.x + players[i].d.x*dt*60
      players[i].p.y = players[i].p.y + players[i].d.y*dt*60

      if i ~= id then
        if collision.check_overlap(players[id], players[i]) then
          local p1, p2 = collision.circle_vs_circle(players[id], players[i]) --
          players[id].p = p1
          players[i].p = p2
        end
      end
    end
  end
  players[id].d.x = players[id].d.x * 0.9
  players[id].d.y = players[id].d.y * 0.9
end

game.draw = function ()
  love.graphics.translate( win_width/2-players[id].p.x, win_height/2-players[id].p.y )
  for i, v in pairs(players) do
    if v.team == 1 then
      love.graphics.setColor(255, 200, 200)
    else
      love.graphics.setColor(200, 200, 255)
    end
    love.graphics.circle("fill", v.p.x, v.p.y, v.r, 2*math.pi*v.r)
  end
end

return game
