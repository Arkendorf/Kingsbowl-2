local state = require "state"
local gui = require "gui"
require "globals"
client = {}

local players = {}
local id = nil
local status = "Disconnected"

client.init = function(t)
  state.networking = {}
  state.game = "clientmenu"
  state.gui = gui.new(menus[3])
  local networking = state.networking
  networking.peer = sock.newClient(ip.ip, tonumber(ip.port))

  -- initial variables

  -- important functions
  networking.peer:on("connect", function(data)
    status = "Connected"
    networking.peer:send("playerinfo", {name = username[1]})
  end)

  networking.peer:on("disconnect", function(data)
    status = "Disconnected"
  end)

  networking.peer:on("id", function(data)
    id = data
  end)

  networking.peer:on("currentplayers", function(data)
    players = data
  end)

  networking.peer:on("newplayer", function(data)
    players[data.index] = data.info
  end)

  networking.peer:connect()
  status = "Connecting"
end

client.update = function(dt)
  state.networking.peer:update()
end

client.draw = function()
  if status == "Connected" then
    love.graphics.print("Players:", 2, 2)
    local j = 1
    for i, v in pairs(players) do
      if i == id then
        love.graphics.rectangle("fill", 1, j*13, font:getWidth(v.name)+1, 12)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(v.name, 2, j*13+2)
        love.graphics.setColor(255, 255, 255)
      else
        love.graphics.print(v.name, 2, j*13+2)
      end
      j = j + 1
    end
  else
    love.graphics.print(status)
  end
end

client.quit = function()

  state.networking.peer:disconnectNow()
end

return client
