local join_menu = {}

join_menu.imgs = {}
join_menu.imgs.smallbanner = love.graphics.newImage("guiart/smallbanner.png")
join_menu.imgs.teamlist1 = love.graphics.newImage("guiart/teamlist1.png")
join_menu.imgs.teamlist2 = love.graphics.newImage("guiart/teamlist2.png")
join_menu.imgs.playerbuttons = love.graphics.newImage("guiart/playerbuttons.png")

local menu_mode = {0, 0}

join_menu.update = function(dt)
end

join_menu.draw = function()
  -- leave button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(join_menu.imgs.smallbanner)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Leave", 4, 12)

  if network.mode == "server" then
    -- start button
    love.graphics.setColor(0, 212, 0)
    love.graphics.draw(join_menu.imgs.smallbanner, 34)
    love.graphics.setColor(255, 255, 255)
    love.graphics.print("Start", 40, 12)
  end

  -- draw team backgrounds
  love.graphics.setColor(team_info[1].color)
  if menu_mode[1] == 0 then
    love.graphics.draw(join_menu.imgs.teamlist1, (win_width/2) - 144, (win_height-256)/2)
  else
    love.graphics.draw(join_menu.imgs.teamlist2, (win_width/2) - 144, (win_height-256)/2)
  end
  love.graphics.setColor(team_info[2].color)
  if menu_mode[2] == 0 then
    love.graphics.draw(join_menu.imgs.teamlist1, (win_width/2) + 16, (win_height-256)/2)
  else
    love.graphics.draw(join_menu.imgs.teamlist2, (win_width/2) + 16, (win_height-256)/2)
  end

  -- draw team names
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(team_info[1].name, (win_width/2) - 144, (win_height-256)/2+2)
  love.graphics.print(team_info[2].name, (win_width/2) + 16, (win_height-256)/2+2)

  -- draw player names
  local team_size = {0, 0}
  for i, v in pairs(players) do
    if menu_mode[v.team] == 0 then
      love.graphics.print(v.name, (win_width/2) - 302 + 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
      if network.mode == "server" then
        love.graphics.draw(join_menu.imgs.playerbuttons, (win_width/2) - 202 + 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
      end
      team_size[v.team] = team_size[v.team] + 1
    end
  end
end

join_menu.swap_menu = function(mode, menu)
  menu_mode[menu] = mode

end
return join_menu
