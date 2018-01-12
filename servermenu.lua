local gui = require "gui"
local state = require "state"
local game = require "game"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
local server = require "server"
require "globals"
local servermenu = {}

--create important variables
players = {}
id = 0
-- set up old team info, so servermenu.update() can check if team info changes
local old_team_info = {{name = team_info[1].name, color = {team_info[1].color[1], team_info[1].color[2], team_info[1].color[3]}}, {name = team_info[2].name, color = {team_info[2].color[1], team_info[2].color[2], team_info[2].color[3]}}}
-- create variable for team's menu state
local menu_mode = {0, 0}


local server_hooks = {
  -- if a player joins, do this:
  playerinfo = function(data, client)
    local index = client:getIndex()
    players[index] = {name = data.name, team = 1}
    network.host:sendToPeer(network.host:getPeerByIndex(index), "allinfo", {id = index, players = players, team_info = team_info})
    network.host:sendToAllBut(network.host:getPeerByIndex(index),"newplayer", {info = players[index], index = index})
    -- update player buttons
    servermenu.update_p_buttons()
  end,
  -- if a player disconnects, do this:
  disconnect = function(data, client)
    local index = client:getIndex()
    players[index] = nil
    network.host:sendToAll("remove", index)
    -- update player buttons
    gui.remove(index+4)
  end,
}

servermenu.init = function()
  -- set up sock networking
  network.mode = "server"
  network.host = sock.newServer("*", tonumber(ip.port))

  -- initialize server hooks
  for k,v in pairs(server_hooks) do
    network.host:on(k, v)
  end

  -- add server to player list, with an ID of 0
  id = 0
  players[0] = {name = username[1], team = math.floor(math.random()+1.5)}

  -- set the base gui for the server menu
  state.gui = gui.new(menus[2])

  -- make first player buttons
  servermenu.update_p_buttons()
end

servermenu.update = function(dt)
  -- update sock server
  network.host:update()

  -- if server has adjusted information for team 1, tell all clients
  if old_team_info[1].name ~= team_info[1].name or old_team_info[1].color[1] ~= team_info[1].color[1] or old_team_info[1].color[2] ~= team_info[1].color[2] or old_team_info[1].color[3] ~= team_info[1].color[3] then
    old_team_info[1].name = team_info[1].name
    old_team_info[1].color[1] = team_info[1].color[1]
    old_team_info[1].color[2] = team_info[1].color[2]
    old_team_info[1].color[3] = team_info[1].color[3]
    network.host:sendToAll("teaminfo", {info = team_info[1], team = 1})
  end
  -- if server has adjusted information for team 2, tell all clients
  if old_team_info[2].name ~= team_info[2].name or old_team_info[2].color[1] ~= team_info[2].color[1] or old_team_info[2].color[2] ~= team_info[2].color[2] or old_team_info[2].color[3] ~= team_info[2].color[3] then
    old_team_info[2].name = team_info[2].name
    old_team_info[2].color[1] = team_info[2].color[1]
    old_team_info[2].color[2] = team_info[2].color[2]
    old_team_info[2].color[3] = team_info[2].color[3]
    network.host:sendToAll("teaminfo", {info = team_info[2], team = 2})
  end
end

servermenu.draw = function()
  -- leave button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(img.smallbanner)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Leave", 4, 12)

  -- start button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(img.smallbanner, 34)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Start", 40, 12)

  -- draw team menus
  for j = 1, 2 do
    if menu_mode[j] == 0 then
      -- draw banner
      love.graphics.setColor(team_info[j].color)
      love.graphics.draw(img.teamlist, quad.teamlist1, (win_width/2) - 304 + 160 * j, (win_height-256)/2)

      -- draw icons
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(img.menuicons, quad.icons1, (win_width/2) - 304 + 160 * j, (win_height-256)/2)
    else
      -- draw banner
      love.graphics.setColor(team_info[j].color)
      love.graphics.draw(img.teamlist, quad.teamlist2, (win_width/2) - 304 + 160 * j, (win_height-256)/2)

      -- draw icons
      love.graphics.setColor(255, 255, 255)
      love.graphics.draw(img.menuicons, quad.icons2, (win_width/2) - 304 + 160 * j, (win_height-256)/2)

      --draw sliders
      for i = 1, 3 do
        love.graphics.draw(img.slider, quad.sliderbar, (win_width/2) - 302 + 160 * j, (win_height-256)/2+17*i)
        love.graphics.draw(img.slider, quad.slidernode, (win_width/2) - 302 + 160 * j + math.floor(team_info[j].color[i]/255*120), (win_height-256)/2+17*i)
      end
    end
  end

  -- draw team names
  love.graphics.print(team_info[1].name, (win_width/2) - 144, (win_height-256)/2+2)
  love.graphics.print(team_info[2].name, (win_width/2) + 16, (win_height-256)/2+2)

  -- draw player names
  local team_size = {0, 0}
  for i, v in pairs(players) do
    if menu_mode[v.team] == 0 then
      love.graphics.print(v.name, (win_width/2) - 302 + 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
      love.graphics.draw(img.playerbuttons, (win_width/2) - 202 + 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
      team_size[v.team] = team_size[v.team] + 1
    end
  end
end

servermenu.quit = function()
  -- tell all clients to disconnect
  network.host:sendToAll("disconnect")
  -- kill server
  network.host:update()
  network.host:destroy()
end

servermenu.back_to_main = function()
  -- reset game state
  state.game = false
  network.mode = nil
  -- reset gui to main menu
  state.gui = gui.new(menus[1])
  -- kill server
  servermenu.quit()
end

servermenu.start_game = function()
  teams = {{members = {}, qb = 1}, {members = {}, qb = 1}}
  for i, v in pairs(players) do
    teams[v.team].members[#teams[v.team].members+1] = i
  end

  if #teams[1].members > 0 and #teams[2].members > 0 then -- only start game if there is at least one person per team
    state.gui = gui.new(menus[4])
    qb = teams[1].members[1]
    network.host:sendToAll("startgame", {players = players, qb = qb})

    server.init()
    game.init()
    game.ball.baller = qb
  end
end

servermenu.swap_menu = function(mode, menu)
  -- update menu mode
  menu_mode[menu] = mode

  -- adjust gui for new menu mode
  if mode == 1 then
    for i, v in pairs(players) do
      if v.team == menu then
        gui.remove(i+4)
      end
    end
    gui.add({sliders = {{x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+17, alignment = 1, w = 124, h = 12, barw = 4, table = team_info[menu].color, index = 1, numMin = 0, numMax = 255},
            {x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+33, alignment = 1, w = 124, h = 12, barw = 4, table = team_info[menu].color, index = 2, numMin = 0, numMax = 255},
            {x = (win_width/2) - 302 + 160 * menu, y = (win_height-256)/2+49, alignment = 1, w = 124, h = 12, barw = 4, table = team_info[menu].color, index = 3, numMin = 0, numMax = 255}}}, 1+menu)
  elseif mode == 0 then
    gui.remove(1+menu)
    servermenu.update_p_buttons()
  end
end

servermenu.update_p_buttons = function ()
  -- create or delete buttons (swap team and kick) for each player
  local team_size = {0, 0}
  for i, v in pairs(players) do
    gui.remove(i+4)
    if menu_mode[v.team] == 0 then
      gui.add({buttons = {{x = (win_width/2) - 202 + 160 * v.team, y = (win_height-256)/2+16+team_size[v.team]*16, w = 12, h = 12, txt = "s", func = servermenu.teamswap, args = {i}}, {x = (win_width/2) - 190 + 160 * v.team, y = (win_height-256)/2+16+team_size[v.team]*16, w = 12, h = 12, txt = "r", func = servermenu.kick, args = {i}}}}, i+4)
      team_size[v.team] = team_size[v.team] + 1
    end
  end
end

servermenu.teamswap = function (i)
  -- switch the team of a player
  local v = players[i]
  if v.team == 1 then
    v.team = 2
  else
    v.team = 1
  end
  network.host:sendToAll("teamswap", {index = i, info = v.team})
  servermenu.update_p_buttons()
end

servermenu.kick = function (i)
  -- remove a player
  if i > 0 then
    players[i] = nil
    network.host:sendToPeer(network.host:getPeerByIndex(i), "disconnect")
    network.host:sendToAll("remove", i)
    gui.remove(i+4)
  end
end

return servermenu
