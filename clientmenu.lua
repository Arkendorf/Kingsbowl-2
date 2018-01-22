local state = require "state"
local gui = require "gui"
local game = require "game"
local vector = require "vector"
local network = require "network"
local clientgame = require "clientgame"
require "globals"
local clientmenu = {}

-- creat important variables
id = 0
--players = {}

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

  -- set up base gui
  state.gui = gui.new(menus[3])
end

clientmenu.update = function(dt)
  -- update sock client
  network.peer:update()
end

clientmenu.draw = function()
  -- leave button
  love.graphics.setColor(0, 212, 0)
  love.graphics.draw(img.smallbanner)
  love.graphics.setColor(255, 255, 255)
  love.graphics.print("Leave", 4, 12)

  -- draw team backgrounds
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.teamlist, quad.teamlist3, (win_width/2) - 144, (win_height-256)/2)
  love.graphics.setColor(team_info[2].color)
  love.graphics.draw(img.teamlist, quad.teamlist3, (win_width/2) + 16, (win_height-256)/2)

  -- draw team names
  love.graphics.setColor(255, 255, 255)
  love.graphics.print(team_info[1].name, (win_width/2) - 144, (win_height-256)/2+2)
  love.graphics.print(team_info[2].name, (win_width/2) + 16, (win_height-256)/2+2)

  -- draw player names
  local team_size = {0, 0}
  for i, v in pairs(players) do
    love.graphics.print(v.name, (win_width/2) - 302 + 160 * v.team, (win_height-256)/2+16+team_size[v.team]*16)
    team_size[v.team] = team_size[v.team] + 1
  end
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
