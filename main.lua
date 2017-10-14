grease = require("grease.init")

local server, server_update
local client, client_update

function love.load()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.:", 1)
  love.graphics.setFont(font)

  chars = {{speed = 60}}
  players = {{x = 0, y = 0, xV = 0, yV = 0, char = chars[1]}}
  currentPlayer = 1
  qb = {num = 1, target = {x = 0, y = 0}}
  gamestate = "menu"
  menu_update = require("menu")

  gui_update, gui_draw, gui_mousepressed, gui_textinput, gui_keypressed, gui, gui = unpack(require("gui"))
  menus = {}
  menus[1] = {buttons = {{x = 200, y = 275, w = 100, h = 50, txt = "server", func = create_server, args = {}}, {x = 500, y = 275, w = 100, h = 50, txt = "client", func = create_client, args = {}}}}
  menus[2] = {}
  menus[3] = {}

  new_gui(menus[1])
end

function love.update(dt)
  if gamestate == "server" then
    server_update(dt)
  elseif gamestate == "client" then
    client_update(dt)
  elseif gamestate == "menu" then
    menu_update(dt)
  end

  gui_update(dt)
end

function love.draw()
  gui_draw()
end

function love.keypressed(key)
  if key == "1" then
    create_server()
  elseif key == "2" then
    create_client()
  end

  gui_keypressed(key)
end

function love.mousepressed(x, y, button)
  gui_mousepressed(x, y, button)
end

function love.textinput(t)
  gui_textinput(t)
end

create_server = function()
  server, server_update = unpack(require("server"))
  gamestate = "server"
  new_gui(menus[2])
end

create_client = function()
  gamestate = "client"
  client, client_update = unpack(require("client"))
  local success, err = client:connect("127.0.0.1", 25565)
  print(success, err)
  if success then
      new_gui(menus[3])
  end
end
