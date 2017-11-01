sock = require "sock"
ip = {ip = "127.0.0.1", port = "25565"}
keydowntable, keyuptable = unpack(require "keytable")
joystick = nil
username = {"Sir Placeholder"}
players = {}
id = nil
qb = nil
win_width, win_height = love.graphics.getDimensions( )
sword = {dist = 10, r = 10, t = .5}
shield = {dist = 10, r = 12}
speed_table = {
  with_ball = 24,
  offense = 32,
  defense = 30,
  shield = 20,
  sword = 4,
}
grace_time = 3
