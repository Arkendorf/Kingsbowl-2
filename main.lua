grease = require("grease.init")

local server, server_update
local client, client_update

function love.load()
  chars = {{speed = 60}}
  players = {{x = 0, y = 0, xV = 0, yV = 0, char = chars[1]}}
  currentPlayer = 1
  qb = {num = 1, target = {x = 0, y = 0}}
  gamestate = "neither"
end

function love.update(dt)
  if gamestate == "server" then
    server_update(dt)
  elseif gamestate == "client" then
    client_update(dt)
  elseif gamestate == "menu" then
    menu_update(dt)
  end
end

function love.draw()
end

function love.keypressed(key)
  if key == "1" then
    server, server_update = unpack(require("server"))
    gamestate = "server"
  elseif key == "2" then
    gamestate = "client"
    client, client_update = unpack(require("client"))
    local success, err = client:connect("127.0.0.1", 25565)
    print(success, err)
  end
end
