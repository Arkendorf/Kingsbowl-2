players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")

local direction = function()
  players[id].d.x = players[id].d.x + joystick:getGamepadAxis("leftx")
  players[id].d.y = players[id].d.y + joystick:getGamepadAxis("lefty")
end

local 

return {
  direction = direction
}
