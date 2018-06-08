local gui = require "gui"
local state = require "state"
local collision = require "collision"
local vector = require "vector"
local network = require "network"
local servergame = require "servergame"
local ai = require "ai"
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
    if state.game == false then
      players[index] = {name = data.name, team = 2}
      network.host:sendToPeer(network.host:getPeerByIndex(index), "allinfo", {id = index, players = players, team_info = team_info})
      network.host:sendToAllBut(network.host:getPeerByIndex(index),"newplayer", {info = players[index], index = index})
      -- update player buttons
      servermenu.update_p_buttons()
    else
      network.host:sendToPeer(network.host:getPeerByIndex(index), "disconnect")
    end
  end,
  -- if a player disconnects, do this:
  disconnect = function(data, client)
    local index = client:getIndex()
    if state.game == false then
      players[index] = nil
      network.host:sendToAll("remove", index)
      -- update player buttons
      gui.remove(index+4)
    end
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
  players[0] = {name = username[1], team = 1}

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
  -- base
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.field, (win_width-field.w)/2, (win_height-field.h)/2)

  -- leave button
  love.graphics.draw(img.button, 2, 2)
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.button_overlay, 2, 2)
  love.graphics.setColor(229, 229, 229)
  love.graphics.print("Leave", 13, 14)

  -- start button
  love.graphics.setColor(255, 255, 255)
  love.graphics.draw(img.button, 52, 2)
  love.graphics.setColor(team_info[2].color)
  love.graphics.draw(img.button_overlay, 52, 2)
  love.graphics.setColor(229, 229, 229)
  love.graphics.print("Start", 63, 14)

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

      -- draw text
      love.graphics.print("Color:", (win_width/2) - 302 + 160 * j, (win_height-256)/2+17)
      love.graphics.print("Linesmen: "..tostring(math.floor(ai.num[j][1])), (win_width/2) - 302 + 160 * j, (win_height-256)/2+78)
      love.graphics.print("Receivers: "..tostring(math.floor(ai.num[j][2])), (win_width/2) - 302 + 160 * j, (win_height-256)/2+105)
      --draw color sliders
      for i = 1, 3 do
        love.graphics.draw(img.slider, quad.sliderbar, (win_width/2) - 302 + 160 * j, (win_height-256)/2+10+17*i)
        love.graphics.draw(img.slider, quad.slidernode, (win_width/2) - 302 + 160 * j + math.floor(team_info[j].color[i]/255*120), (win_height-256)/2+10+17*i)
      end
      --draw bot sliders
      for i = 1, 2 do
        love.graphics.draw(img.slider, quad.sliderbar, (win_width/2) - 302 + 160 * j, (win_height-256)/2+61+27*i)
        love.graphics.draw(img.slider, quad.slidernode, (win_width/2) - 302 + 160 * j + math.floor(ai.num[j][i]/4*120), (win_height-256)/2+61+27*i)
      end
    end
  end

  -- draw team names
  love.graphics.setColor(51, 51, 51)
  love.graphics.print(team_info[1].name, (win_width/2) - 138, (win_height-256)/2+2)
  love.graphics.print(team_info[2].name, (win_width/2) + 22, (win_height-256)/2+2)

  -- draw player names
  love.graphics.setColor(229, 229, 229)
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
    qb = teams[1].members[1]

    ai.generate_bots() -- create "players" for bots

    network.host:sendToAll("startgame", {players = players, qb = qb})

    servergame.init()
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
    gui.add({sliders = {{x = (true_win_width/2) - 604 + 320 * menu, y = (true_win_height-512)/2+44, alignment = 1, w = 248, h = 24, barw = 8, table = team_info[menu].color, index = 1, numMin = 0, numMax = 255},
                        {x = (true_win_width/2) - 604 + 320 * menu, y = (true_win_height-512)/2+76, alignment = 1, w = 248, h = 24, barw = 8, table = team_info[menu].color, index = 2, numMin = 0, numMax = 255},
                        {x = (true_win_width/2) - 604 + 320 * menu, y = (true_win_height-512)/2+108, alignment = 1, w = 248, h = 24, barw = 8, table = team_info[menu].color, index = 3, numMin = 0, numMax = 255},
                        {x = (true_win_width/2) - 604 + 320 * menu, y = (true_win_height-512)/2+178, alignment = 1, w = 248, h = 24, barw = 8, table = ai.num[menu], index = 1, numMin = 0, numMax = 4},
                        {x = (true_win_width/2) - 604 + 320 * menu, y = (true_win_height-512)/2+222, alignment = 1, w = 248, h = 24, barw = 8, table = ai.num[menu], index = 2, numMin = 0, numMax = 4}}}, 1+menu)
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
      gui.add({buttons = {{x = (true_win_width/2) - 404 + 320 * v.team, y = (true_win_height-512)/2+32+team_size[v.team]*32, w = 24, h = 24, txt = "s", func = servermenu.teamswap, args = {i}}, {x = (true_win_width/2) - 380 + 320 * v.team, y = (true_win_height-512)/2+32+team_size[v.team]*32, w = 24, h = 24, txt = "r", func = servermenu.kick, args = {i}}}}, i+4)
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
