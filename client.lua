local grease = require("grease.init")
local state = require "state"
local gui = require "gui"
local client = {}

client.init = function(t)
  state.game = "client"
  client.grease = grease.udpClient()
  local success, err = client.grease:connect("127.0.0.1", 25565)
  print(success, err)
  if success then
      state.gui = gui.new(menus[3])
  end
end

function client.update(dt)
  client.grease:update(dt)
end

return client
