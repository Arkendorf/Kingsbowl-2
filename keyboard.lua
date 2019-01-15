local facing_to_dp = {
  function() -- facing 1
    return -1, 0
  end,
  function() -- facing 2
    return 0, 0
  end,
  function() -- facing 3
    return 1, 0
  end,
  function() -- facing 4
    return -0.70710678118, -0.70710678118
  end,
  function() -- facing 5
    return 0, -1
  end,
  function() -- facing 6
    return 0.70710678118, -0.70710678118
  end,
  function() -- facing 7
    return -0.70710678118, 0.70710678118
  end,
  function() -- facing 8
    return 0, 1
  end,
  function() -- facing 9
    return 0.70710678118, 0.70710678118
  end,
}

local direction = function()
  if players[id].dead then
    return 0, 0
  end
  local facing = 2
  if love.keyboard.isDown("w") then
    facing = 5
  elseif love.keyboard.isDown("s") then
    facing = 8
  end
  if love.keyboard.isDown("a") then
    facing = facing - 1
  elseif love.keyboard.isDown("d") then
    facing = facing + 1
  end
  return facing_to_dp[facing]()
end

local target = function()
  players[id].mouse.x = camera.x-players[id].p.x
  players[id].mouse.y = camera.y-players[id].p.y
end

local center = function()
   if love.keyboard.isDown("space") then
      camera.x = players[id].p.x+2 -- +2 to fix player jittering
      camera.y = players[id].p.y
   end
end

return {
  direction = direction,
  target = target,
  center = center
}
