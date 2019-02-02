local state = require "state"
local gui = require "gui"
local vector = require "vector"
local network = require "network"
local clientgame = require "clientgame"
require "globals"
local clientmenu = {}

-- creat important variables
id = 0
-- store positions of banners
local banner_pos = {{x = 0, y = 0}, {x = 0, y = 0}}

local client_hooks = {
  -- when client connects to a server, do this:
  connect = function(data)
    network.peer:send("playerinfo", {name = username[1]})
  end,
  -- when client recieves first-time info from the server, do this:
  allinfo = function(data)
    id = data.id
    players = data.players
    team_info = data.team_info
  end,
  -- when a new client is added, do this:
  newplayer = function(data)
    players[data.index] = data.info
  end,
  -- when server tells client to disconnect, do this:
  disconnect = function(data)
    clientmenu.back_to_main()
  end,
  -- when client leaves, do this:
  remove = function(data)
    players[data] = nil
  end,
  -- when client switches teams, do this:
  teamswap = function(data)
    players[data.index].team = data.info
  end,
  -- when team info needs to update, do this:
  teaminfo = function(data)
    team_info[data.team] = data.info
  end,
  startgame = function(data)
    players = data.players
    qb = data.qb
    teams = {{members = {}}, {members = {}}}
    for i, v in pairs(players) do
      teams[v.team].members[#teams[v.team].members+1] = i
    end
    clientgame.init()
  end,
}

clientmenu.init = function(t)
  -- set up sock networking
  network.mode = "client"
  network.peer = sock.newClient(ip.ip, tonumber(ip.port))
  network.peer:connect()

  -- initialize client hooks
  for k,v in pairs(client_hooks) do
    network.peer:on(k, v)
  end

  -- set positions of banners
  banner_pos[1] = {x = (win_width/2)-186, y = (win_height-270)/2}
  banner_pos[2] = {x = (win_width/2)+16, y = (win_height-270)/2}

  -- set up base gui
  local menu = {buttons = {{x = 2*2, y = 2*2, w = 48*2, h = 32*2, txt = "Leave", func = clientmenu.back_to_main, args = {}}}}
  state.gui = gui.new(menu)
end

clientmenu.update = function(dt)
  -- update sock client
  network.peer:update()
end

clientmenu.draw = function()
  love.graphics.setFont(font)
  -- base
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(img.field, (win_width-field.w)/2, (win_height-field.h)/2)

  -- leave button
  love.graphics.draw(img.button, 2, 2)
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.button_overlay, 2, 2)
  love.graphics.setColor(229/255, 229/255, 229/255)
  love.graphics.print("Leave", 13, 14)

  -- draw team menus
  for team = 1, 2 do
    clientmenu.draw_banner(banner_pos[team].x, banner_pos[team].y, team)
  end
end

clientmenu.draw_banner = function(x, y, team)
  love.graphics.setColor(team_info[team].color)
  love.graphics.draw(img.teamlist_overlay, x, y)
  love.graphics.draw(img.menuicons_overlay, quad.icons3, x, y)

  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(img.teamlist, x, y)
  love.graphics.draw(img.menuicons, quad.icons3, x, y)
  -- draw names
  love.graphics.setColor(229/255, 229/255, 229/255)
  local team_size = 0
  for i, v in pairs(players) do
    if v.team == team then
      love.graphics.print(v.name, x+22, y+32+team_size*16)
      team_size = team_size + 1
    end
  end
  -- draw team name
  love.graphics.setColor(51/255, 51/255, 51/255)
  love.graphics.print(team_info[team].name, x+19, y+3)
end

clientmenu.quit = function()
  -- forcibly disconnect from server
  network.peer:disconnectNow()
end

clientmenu.back_to_main = function()
  -- leave server
  clientmenu.quit()
  -- reset game state and gui
  network.mode = nil
  state.gui = gui.new(menus[1])
end

return clientmenu
