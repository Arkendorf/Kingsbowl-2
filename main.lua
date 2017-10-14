-- require("middleclass")
-- require("middleclass-commons")

grease = require("grease.init")
require("grease.core")
require("grease.enet")
require("grease.lightning")
require("grease.protocol")
require("grease.tcp")
require("grease.udp")

local server, server_update
require("client")

function love.load()
  chars = {{speed = 60}}
  players = {{x = 0, y = 0, xV = 0, yV = 0, char = chars[1]}}
  currentPlayer = 1
  qb = {num = 1, target = {x = 0, y = 0}}
  success = false
  gamestate = "neither"
end

function love.update(dt)
  if gamestate == "server" then
    server_update(dt)
  elseif gamestate == "client" then
    client_update(dt)
  end

  -- take movement input
  if love.keyboard.isDown("a") then
    players[currentPlayer].xV = players[currentPlayer].xV - dt * players[currentPlayer].char.speed
  end
  if love.keyboard.isDown("d") then
    players[currentPlayer].xV = players[currentPlayer].xV + dt * players[currentPlayer].char.speed
  end
  if love.keyboard.isDown("w") then
    players[currentPlayer].yV = players[currentPlayer].yV - dt * players[currentPlayer].char.speed
  end
  if love.keyboard.isDown("s") then
    players[currentPlayer].yV = players[currentPlayer].yV + dt * players[currentPlayer].char.speed
  end

  -- move player
  players[currentPlayer].x = players[currentPlayer].x + players[currentPlayer].xV
  players[currentPlayer].y = players[currentPlayer].y + players[currentPlayer].yV
  players[currentPlayer].xV = players[currentPlayer].xV * 0.9
  players[currentPlayer].yV = players[currentPlayer].yV * 0.9

  if currentPlayer == qb.num then
    qb.target.x, qb.target.y = love.mouse.getPosition()
  end

end

function love.draw()
  -- draw players
  for i, v in ipairs(players) do
    love.graphics.circle("fill", v.x, v.y, 10, 20)
  end

  -- draw target
  love.graphics.circle("fill", qb.target.x, qb.target.y, 5, 10)
  love.graphics.print(gamestate.." "..tostring(success))
end

function love.keypressed(key)
  if key == "1" then
    server, server_update = unpack(require("server"))
    gamestate = "server"
  elseif key == "2" then
    gamestate = "client"
    success = connectToServer()
  end
end
