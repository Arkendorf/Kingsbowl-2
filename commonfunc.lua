local collision = require "collision"
local vector = require "vector"

local commonfunc = {}

commonfunc.adjust_target = function(id, dt)
  -- adjust angle to approach angle goal
  if not players[id].sword.active then
    local angle_goal = math.atan2(players[id].mouse_goal.y, players[id].mouse_goal.x)
    if angle_goal < 0 then
      angle_goal = angle_goal + math.pi*2
    end
    local dif = angle_goal-players[id].polar.angle
    if dif > (math.pi*2-math.abs(dif))*dif/math.abs(dif) then
      if math.abs(dif) < turn_speed*dt or math.pi*2-math.abs(dif) < turn_speed*dt then
        players[id].polar.angle = angle_goal
      else
        players[id].polar.angle = players[id].polar.angle - turn_speed*dt
      end
    else
      if math.abs(dif) < turn_speed*dt or math.pi*2-math.abs(dif) < turn_speed*dt then
        players[id].polar.angle = angle_goal
      else
        players[id].polar.angle = players[id].polar.angle + turn_speed*dt
      end
    end
  end
  -- make angle within range
  if players[id].polar.angle > math.pi*2 then
    players[id].polar.angle = players[id].polar.angle - math.pi*2
  elseif players[id].polar.angle < 0 then
    players[id].polar.angle = players[id].polar.angle + math.pi*2
  end
  -- adjust magnitude to approach magnitude goal
  local mag_goal = math.sqrt(players[id].mouse_goal.y*players[id].mouse_goal.y+players[id].mouse_goal.x*players[id].mouse_goal.x)
  if math.abs(mag_goal-players[id].polar.mag) < mag_speed*60*dt then
    players[id].polar.mag = mag_goal
  elseif mag_goal > players[id].polar.mag then
    players[id].polar.mag = players[id].polar.mag + mag_speed*60*dt
  else
    players[id].polar.mag = players[id].polar.mag - mag_speed*60*dt
  end
  -- adjust actual cursor pos
  players[id].mouse.x = players[id].polar.mag*math.cos(players[id].polar.angle)
  players[id].mouse.y = players[id].polar.mag*math.sin(players[id].polar.angle)
end

commonfunc.draw_scoreboard = function(x, y)
  -- draw scoreboard
  love.graphics.draw(img.scoreboard, x, y)
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.scoreboard_overlay, x+10, y)
  love.graphics.setColor(team_info[2].color)
  love.graphics.draw(img.scoreboard_overlay, x+38, y)
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(font)
  for team = 1, 2 do
    for i = string.len(tostring(score[team])), 1, -1 do
      love.graphics.print(string.sub(tostring(score[team]), i, i), x+team*28-8+i*7, y+3)
    end
  end
  love.graphics.setColor(51/255, 51/255, 51/255)
  if down.goal then
    love.graphics.print(tostring(down.num)..num_suffix[down.num].." and "..tostring(math.ceil(math.abs(down.goal - down.scrim)/field.w*120)), x+66, y+3)
  else
    love.graphics.print(tostring(down.num)..num_suffix[down.num].." and goal", x+66, y+3)
  end
  if down.dead then
    love.graphics.print(math.ceil(down.t+grace_time), x+2, y+3)
  else
    love.graphics.print(math.ceil(down.t), x+2, y+3)
  end
end

commonfunc.block = function(i, v)
  local sword_pos = vector.sum(v.p, v.sword.d)
   -- check if sword hits shield
  for j, w in pairs(players) do
    if j ~= i and w.dead == false and w.shield.active == true then
      local shield_pos = vector.sum(w.p, w.shield.d)
      if vector.mag_sq(vector.sub(v.p, w.p)) > vector.mag_sq(vector.sub(v.p, shield_pos)) and collision.check_overlap({r = shield.r, p = shield_pos}, {r = sword.r, p = sword_pos}) then -- prevents blocks through body
        return true
      end
    end
  end
  return false
end

commonfunc.draw_effects = function(effects, top)
  -- draw effects (blood, etc.)
  love.graphics.setColor(1, 1, 1)
  for i, v in ipairs(effects) do
    if v.top == top then
      if not v.ox then v.ox = 0 end
      if not v.oy then v.oy = 0 end
      if v.quad then
        love.graphics.draw(img[v.img], quad[v.quad], math.floor(v.x), math.floor(v.y-v.z), 0, 1, 1, v.ox, v.oy)
      else
        love.graphics.draw(img[v.img], math.floor(v.x), math.floor(v.y-v.z), 0, 1, 1, v.ox, v.oy)
      end
    end
  end
end

return commonfunc
