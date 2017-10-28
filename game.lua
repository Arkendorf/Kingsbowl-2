local game = {}
local players = {{p = {x = 0, y = 0}, d = {x = 0, y = 0}, r = 10}, {p = {x = 100, y = 100}, d = {x = 0, y = 0}, r = 50}}
local char = 1
local collision = require "collision"

game.load = function ()
end
game.update = function (dt)
  if love.keyboard.isDown("w") then
    players[char].d.y = players[char].d.y - 1
  end
  if love.keyboard.isDown("s") then
    players[char].d.y = players[char].d.y + 1
  end
  if love.keyboard.isDown("a") then
    players[char].d.x = players[char].d.x - 1
  end
  if love.keyboard.isDown("d") then
    players[char].d.x = players[char].d.x + 1
  end

  if joystick ~= nil then
    players[char].d.x = players[char].d.x + joystick:getGamepadAxis("leftx")
    players[char].d.y = players[char].d.y + joystick:getGamepadAxis("leftx")
  end

  players[char].p.x = players[char].p.x + players[char].d.x*dt*60
  players[char].d.x = players[char].d.x * 0.9
  players[char].p.y = players[char].p.y + players[char].d.y*dt*60
  players[char].d.y = players[char].d.y * 0.9

  for i, v in ipairs(players) do
    if i ~= char then
      if collision.check_overlap(players[char], players[i]) then
        local p1, p2 = collision.circle_vs_circle(players[char], players[i]) --
        players[char].p = p1
        players[i].p = p2
      end
    end
  end
end

game.draw = function ()
  for i, v in ipairs(players) do
    love.graphics.circle("fill", v.p.x, v.p.y, v.r, 2*math.pi*v.r)
  end
  love.graphics.print(tostring(collision.check_overlap(players[1], players[2])))
end

return game
