local server, server_update
local client, client_update
local gamestate

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

function love.keypressed(key)
  if key == "1" then
    gamestate = "server"
    server, server_update = unpack(require("server"))
    server:listen(25565)
  elseif key == "2" then
    gamestate = "client"
    client, client_update = unpack(require("client"))
    local success, err = client:connect("127.0.0.1", 25565)
    print(success, err)
  end
end
