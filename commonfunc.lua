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

return commonfunc
