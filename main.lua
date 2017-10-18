require "globals"
local state = require "state"
local server = require "server"
local client = require "client"
local keydowntable, keyuptable = unpack(require "keytable")
local menu_update = require "menu"
local gui = require "gui"
local menus = require "menus"

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
end

love.update = function(dt)
  if state.game == "server" then
    server.update(dt)
  elseif state.game == "client" then
    client.update(dt)
  elseif state.game == "menu" then
    --menu.update(dt)
  end
  state.gui:update(dt)
end

love.draw = function()
  state.gui:draw()
  love.graphics.print(ip.ip..":"..ip.port)
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
