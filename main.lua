require "globals"
local server = require "server"
local client = require "client"
local gui = require "gui"
local menus = require "menus"
local game = require "game"
local state = require "state"

love.load = function()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.:", 1)
  love.graphics.setFont(font)
  state.gui = gui.new(menus[1])
  math.randomseed(os.time())
end

love.update = function(dt)
  if network.mode == "server" then
    server.update(dt)
  elseif network.mode == "client" then
    client.update(dt)
  end
  if state.game == true then
    game.update(dt)
  end
  state.gui:update(dt)
end

love.draw = function()

  state.gui:draw()
  if state.game == true then
    game.draw()
  elseif network.mode == "server" then
    server.draw()
  elseif network.mode == "client" then
    client.draw()
  end
end

love.quit = function()
  if network.mode == "server" then
    server.quit()
  elseif network.mode == "client" then
    client.quit()
  end
end

love.mousepressed = function(x, y, button)
  if network.mode == "server" then
    server.mousepressed(x, y, button)
  elseif network.mode == "client" then
    client.mousepressed(x, y, button)
  end
  if state.game == true then
    game.mousepressed(x, y, button)
  end
  state.gui:mousepressed(x, y, button)
end

love.mousereleased = function(x, y, button)
  if network.mode == "server" then
    server.mousereleased(x, y, button)
  elseif network.mode == "client" then
    client.mousereleased(x, y, button)
  end
end

love.textinput = function(t)
  state.gui:textinput(t)
end

love.keypressed = function(key)
  state.gui:keypressed(key)
end

love.keyreleased = function(key)
end

love.joystickadded = function(x)
  if not joystick and x:isGamepad() then
    joystick = x
  end
end
