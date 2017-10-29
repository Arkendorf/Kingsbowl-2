require "globals"
local server = require "server"
local client = require "client"
local gui = require "gui"
local menus = require "menus"
local game = require "game"
local state = require "state"

keydowntable['1'] = server.init
keydowntable['2'] = client.init

love.load = function()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.:", 1)
  love.graphics.setFont(font)
  state.gui = gui.new(menus[1])
end

love.update = function(dt)
  if state.network_mode == "server" then
    server.update(dt)
  elseif state.network_mode == "client" then
    client.update(dt)
  end
  if state.game == true then
    game.update(dt)
  end
  state.gui:update(dt)
end

love.draw = function()
  if state.game == true then
    game.draw()
  elseif state.network_mode == "server" then
    server.draw()
  elseif state.network_mode == "client" then
    client.draw()
  end
  state.gui:draw()
end

love.quit = function()
  if state.network_mode == "server" then
    server.quit()
  elseif state.network_mode == "client" then
    client.quit()
  end
end

love.mousepressed = function(x, y, button)
  state.gui:mousepressed(x, y, button)
end

love.textinput = function(t)
  state.gui:textinput(t)
end

love.keypressed = function(key)
  keyuptable[key]()
  state.gui:keypressed(key)
end

love.keyreleased = function(key)
  keydowntable[key]()
end

love.joystickadded = function(x)
  if joystick == nil and joystick:isGamepad() then
    joystick = x
  end
end
