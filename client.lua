local state = require "state"
local gui = require "gui"
require "globals"
client = {}

local msg = nil

local id = nil

client.init = function(t)
  state.networking = {}
  state.game = "clientmenu"
  local networking = state.networking
  networking.peer = sock.newClient(ip.ip, tonumber(ip.port))

  networking.peer:on("connect", function(data)
    state.gui = gui.new(menus[3])
    msg = "Connected"
    networking.peer:send("playerinfo", {name = "placeholder"})
  end)

  networking.peer:on("disconnect", function(data)
    msg = "Disconnected"
  end)

  networking.peer:on("id", function(data)
    id = data
  end)

  networking.peer:connect()

  msg = "Trying to connect to server"

end

client.update = function(dt)
  state.networking.peer:update()
  if love.keyboard.isDown("e") then
    state.networking.peer:disconnect()
  end
end

client.draw = function()
  love.graphics.print(msg)
end

client.quit = function()
  state.networking.peer:disconnect()
end

return client
