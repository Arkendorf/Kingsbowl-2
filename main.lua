local server, server_update
local client, client_update
local gamestate
local keydowntable, keyuptable = unpack(require "keytable")
local menu_update = require "menu"

love.load = function()
  gamestate = "menu"
end

love.update = function(dt)
  if gamestate == "server" then
    server_update(dt)
  elseif gamestate == "client" then
    client_update(dt)
  elseif gamestate == "menu" then
    menu_update(dt)
  end
end

love.draw = function()
end

keydowntable['1'] = function()
  gamestate = "server"
  server, server_update = unpack(require("server"))
  server:listen(25565)
end
keydowntable['2'] = function()
  gamestate = "client"
  client, client_update = unpack(require("client"))
  local success, err = client:connect("127.0.0.1", 25565)
  print(success, err)
end

love.keypressed = function(key)
  keyuptable[key]()
end

love.keyreleased = function(key)
  keydowntable[key]()
end
