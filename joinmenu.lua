local join_menu = {}
local gui = require "gui"


join_menu.imgs = {}
join_menu.imgs.smallbanner = love.graphics.newImage("guiart/smallbanner.png")
join_menu.imgs.teamlist = love.graphics.newImage("guiart/teamlist.png")
join_menu.imgs.playerbuttons = love.graphics.newImage("guiart/playerbuttons.png")

join_menu.quads = {}
join_menu.quads.teamlist1 = love.graphics.newQuad(0, 0, 128, 256, join_menu.imgs.teamlist:getDimensions())
join_menu.quads.teamlist2 = love.graphics.newQuad(128, 0, 128, 256, join_menu.imgs.teamlist:getDimensions())
join_menu.quads.teamlist3 = love.graphics.newQuad(256, 0, 128, 256, join_menu.imgs.teamlist:getDimensions())

b = {type = 0}

local menu_mode = {0, 0}

join_menu.init = function()
  join_menu.update_p_buttons()
end

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
  if network.mode == "server" then
    love.graphics.setColor(team_info[1].color)
    if menu_mode[1] == 0 then
      love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist1, (win_width/2) - 144, (win_height-256)/2)
    else
      love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist2, (win_width/2) - 144, (win_height-256)/2)
    end
    love.graphics.setColor(team_info[2].color)
    if menu_mode[2] == 0 then
      love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist1, (win_width/2) + 16, (win_height-256)/2)
    else
      love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist2, (win_width/2) + 16, (win_height-256)/2)
    end
  else
    love.graphics.setColor(team_info[1].color)
    love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist3, (win_width/2) - 144, (win_height-256)/2)
    love.graphics.setColor(team_info[2].color)
    love.graphics.draw(join_menu.imgs.teamlist, join_menu.quads.teamlist3, (win_width/2) + 16, (win_height-256)/2)
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

join_menu.mousepressed = function(x, y, button)
end

join_menu.swap_menu = function(mode, menu)
  menu_mode[menu] = mode

  if network.mode == "server" and mode == 1 then
    for i, v in pairs(players) do
      if v.team == menu then
        gui.remove(i+4)
      end
    end
    gui.add({sliders = {{x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+17, alignment = 1, w = 124, h = 12, barw = 12, table = team_info[menu].color, index = 1, numMin = 0, numMax = 255},
            {x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+33, alignment = 1, w = 124, h = 12, barw = 12, table = team_info[menu].color, index = 2, numMin = 0, numMax = 255},
            {x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+49, alignment = 1, w = 124, h = 12, barw = 12, table = team_info[menu].color, index = 3, numMin = 0, numMax = 255}}}, 1+menu)
  elseif network.mode == "server" and mode == 0 then
    gui.remove(1+menu)
    join_menu.update_p_buttons()
  end
end

join_menu.update_p_buttons = function ()
  local team_size = {0, 0}
  for i, v in pairs(players) do
    gui.remove(i+4)
    if menu_mode[v.team] == 0 then
      gui.add({buttons = {{x = (win_width/2) - 202 + 160 * v.team, y = (win_height-256)/2+16+team_size[v.team]*16, w = 12, h = 12, txt = "s", func = join_menu.teamswap, args = {i}}, {x = (win_width/2) - 190 + 160 * v.team, y = (win_height-256)/2+16+team_size[v.team]*16, w = 12, h = 12, txt = "r", func = join_menu.kick, args = {i}}}}, i+4)
      team_size[v.team] = team_size[v.team] + 1
    end
  end
end

join_menu.teamswap = function (i)
  local v = players[i]
  if v.team == 1 then
    v.team = 2
  else
    v.team = 1
  end
  network.host:sendToAll("teamswap", {index = i, info = v.team})
  join_menu.update_p_buttons()
end

join_menu.kick = function (i)
  if i > 0 then
    players[i] = nil
    network.host:sendToPeer(network.host:getPeerByIndex(i), "disconnect")
    network.host:sendToAll("playerleft", i)
    gui.remove(i+4)
  end
end




return join_menu
