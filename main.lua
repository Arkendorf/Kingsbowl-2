local server, server_update
local client, client_update
local gamestate
local keydowntable, keyuptable = unpack(require "keytable")
local menu_update = require "menu"
local gui = require "gui"
local menus, current_gui

local create_server = function()
  server, server_update = unpack(require("server"))
  server:listen(25565)
  gamestate = "server"
  current_gui = gui.new(menus[2])
end

local create_client = function()
  gamestate = "client"
  client, client_update = unpack(require("client"))
  local success, err = client:connect("127.0.0.1", 25565)
  print(success, err)
  if success then
      current_gui = gui.new(menus[3])
  end
end

keydowntable['1'] = function()
  create_server()
end
keydowntable['2'] = function()
  create_client()
end

love.load = function()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.:", 1)
  love.graphics.setFont(font)
  gamestate = "menu"

  menus = {}
  menus[1] = {buttons = {{x = 200, y = 275, w = 100, h = 50, txt = "server", func = create_server, args = {}}, {x = 500, y = 275, w = 100, h = 50, txt = "client", func = create_client, args = {}}}}
  menus[2] = {}
  menus[3] = {}

  current_gui = gui.new(menus[1])
end

love.update = function(dt)
  if gamestate == "server" then
    server_update(dt)
  elseif gamestate == "client" then
    client_update(dt)
  elseif gamestate == "menu" then
    --menu.update(dt)
  end
  current_gui:update(dt)
end

love.draw = function()
  current_gui:draw()
end

love.mousepressed = function(x, y, button)
  current_gui:mousepressed(x, y, button)
end

love.textinput = function(t)
  current_gui:textinput(t)
end

love.keypressed = function(key)
  keyuptable[key]()
  current_gui:keypressed(key)
end

love.keyreleased = function(key)
  keydowntable[key]()
end
