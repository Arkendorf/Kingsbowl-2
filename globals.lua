sock = require "sock"
ip = {ip = "127.0.0.1", port = "25565"}
keydowntable, keyuptable = unpack(require "keytable")
joystick = nil
username = {"Sir Placeholder"}
players = {}
id = nil
qb = nil
win_width, win_height = love.graphics.getDimensions( )
sword = {dist = 26, r = 10, t = .5}
shield = {dist = 16, r = 12}
speed_table = {
  with_ball = 20,
  offense = 34,
  defense = 28,
  shield = 14,
  sword = 4,
}
grace_time = 3
field = {w = 3600, h = 1600}
mouse = {x = 0, y = 0}
score = {0, 0}
num_suffix = {"st", "nd", "rd", "th"}
