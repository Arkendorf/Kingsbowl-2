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

local direction = function()
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
  if not players[id].dead then
      facing_to_dp[facing]()
  end
end

local target = function()
  players[id].mouse.x = camera.x-players[id].p.x
  players[id].mouse.y = camera.y-players[id].p.y
end

local center = function()
   if love.keyboard.isDown("space") then
      camera.x = players[id].p.x
      camera.y = players[id].p.y
   end
end

return {
  direction = direction,
  target = target,
  center = center
}
