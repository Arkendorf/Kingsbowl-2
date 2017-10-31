sock = require "sock"
ip = {ip = "127.0.0.1", port = "25565"}
keydowntable, keyuptable = unpack(require "keytable")
joystick = nil
username = {"Sir Placeholder"}
players = {}
id = nil
qb = nil
win_width, win_height = love.graphics.getDimensions( )
sword = {dist = 10, r = 10}
shield = {dist = 10, r = 12}
