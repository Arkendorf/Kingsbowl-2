sock = require "sock"
ip = {ip = "127.0.0.1", port = "25565"}
joystick = nil
username = {"Sir Placeholder"}
players = {}
id = nil
qb = nil
win_width, win_height = love.graphics.getDimensions( )
sword = {dist = 26, r = 10, t = .5}
shield = {dist = 16, r = 12}
speed_table = {
  with_ball = 10,
  offense = 16,
  defense = 14,
  shield = 8,
  sword = 2,
}
grace_time = 3
field = {w = 3600, h = 1600}
mouse = {x = 0, y = 0}
score = {0, 0}
-- num_suffix = {"st", "nd", "rd", "th"}
team_info = {{name = "Team 1", color = {255, 0, 0}}, {name = "Team 2", color = {0, 0, 255}}}
grace_time = 3
camera = {x = 0, y = 0}
global_dt = 0
ball_speed = 4


local graphics = require "graphics"
img, quad, char = graphics.init()
