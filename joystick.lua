local direction = function()
  local x = joystick:getGamepadAxis("leftx")
  local y = joystick:getGamepadAxis("lefty")
  if math.abs(x) <= 0.1 then
    x = 0
  end
  if math.abs(y) > 0.1 then
    y = 0
  end
  return x, y
end

local target = function()
  -- find camera values
  local x = joystick:getGamepadAxis("rightx")
  local y = joystick:getGamepadAxis("righty")
  if math.abs(x) > 0.1 then camera.x = camera.x + x*global_dt*60*4 end
  if math.abs(y) > 0.1 then camera.y = camera.y + y*global_dt*60*4 end

  players[id].mouse_goal.x = camera.x-players[id].p.x
  players[id].mouse_goal.y = camera.y-players[id].p.y
end

local center = function()
   if joystick:isGamepadDown("rightstick", "leftstick") then
     camera.x = players[id].p.x+2 -- +2 to fix player jittering
     camera.y = players[id].p.y
   end
end

return {
  direction = direction,
  target = target,
  center = center
}
