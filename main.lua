require "globals"
local state = require "state"
local server = require "server"
local client = require "client"
local gui = require "gui"
local menus = require "menus"
local game = require "game"

keydowntable['1'] = server.init
keydowntable['2'] = client.init

love.load = function()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.:", 1)
  love.graphics.setFont(font)
  state.game = "menu"
  state.gui = gui.new(menus[1])
  game.load()
end

love.update = function(dt)
  if state.game == "servermenu" or state.game == "server" then
    server.update(dt)
  elseif state.game == "clientmenu" or state.game == "client" then
    client.update(dt)
  elseif state.game == "menu" then
  end
  if state.game == "server" or state.game == "client" then
    game.update(dt)
  end
  state.gui:update(dt)
end

love.draw = function()
  if state.game == "client" or state.game == "server" then
    game.draw()
  elseif state.game == "servermenu" then
    server.draw()
  elseif state.game == "clientmenu" then
    client.draw()
  end
  state.gui:draw()
end

love.quit = function()
  if state.game == "servermenu" or state.game == "server" then
    server.quit()
  elseif state.game == "clientmenu" or state.game == "client" then
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
