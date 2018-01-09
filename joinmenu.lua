local join_menu = {}

join_menu.imgs = {}
join_menu.imgs.smallbanner = love.graphics.newImage("guiart/smallbanner.png")
join_menu.imgs.teamlist1 = love.graphics.newImage("guiart/teamlist1.png")
join_menu.imgs.teamlist2 = love.graphics.newImage("guiart/teamlist2.png")
join_menu.imgs.playerbuttons = love.graphics.newImage("guiart/playerbuttons.png")


join_menu.update = function(dt)
end

join_menu.draw = function()
  -- leave button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(join_menu.imgs.smallbanner)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Leave", 4, 12)

  -- start button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(join_menu.imgs.smallbanner, 34)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Start", 40, 12)

  -- draw team backgrounds
  love.graphics.setColor(0, 0, 255)
  love.graphics.draw(join_menu.imgs.teamlist1, (win_width/2) - 144, (win_height-256)/2)
  love.graphics.setColor(255, 0, 0)
  love.graphics.draw(join_menu.imgs.teamlist1, (win_width/2) + 16, (win_height-256)/2)

  -- draw team names
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Team 1", (win_width/2) - 144, (win_height-256)/2+2)
  love.graphics.print("Team 2", (win_width/2) + 16, (win_height-256)/2+2)

  -- draw player names
  local team_size = {0, 0}
  for i, v in pairs(players) do
    love.graphics.print(v.name, (win_width/2) + 178 - 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
    love.graphics.draw(join_menu.imgs.playerbuttons, (win_width/2) +278 - 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
    team_size[v.team] = team_size[v.team] + 1
  end
end

return join_menu
