sock = require "sock"
ip = {ip = "127.0.0.1", port = "25565"}
joystick = nil
username = {"Sir Placeholder"}
players = {}
id = nil
qb = 0
-- love.window.setFullscreen(true)
true_win_width, true_win_height = love.graphics.getDimensions()
win_width = math.floor(true_win_width/4)*2
win_height = math.floor(true_win_height/4)*2
sword = {dist = 18, r = 6, t = .5}
shield = {dist = 12, r = 12}
speed_table = {
  with_ball = 6,
  offense = 8,
  defense = 8,
  shield = 6,
  sword = 2,
}
grace_time = 3
field = {w = 3600, h = 1600}
mouse = {x = 0, y = 0}
score = {0, 0}
num_suffix = {"st", "nd", "rd", "th"}
team_info = {{name = "Team 1", color = {255, 0, 0}}, {name = "Team 2", color = {0, 0, 255}}}
grace_time = 3
camera = {x = 0, y = 0}
global_dt = 0
ball_speed = 4
ball = {p = {x = 0, y = 0}, z = 0, d = {x = 0, y = 0}, r = 8, owner = nil, thrown = false}
down = {scrim = 0, new_scrim = field.w/2, goal = field.w/12*7, num = 0, dead = false, t = 3}

input = require("keyboard")

local graphics = require "graphics"
img, quad, char = graphics.init()
win_canvas = love.graphics.newCanvas(win_width, win_height)

bot_names = {
  "Lancelot",
  "Gawain",
  "Geraint",
  "Percival",
  "Lamorak",
  "Kay",
  "Gareth",
  "Bedivere",
  "Gaheris",
  "Galahad",
  "Tristan",
  "Palamedes",
  "Aban",
  "Bruenor",
  "Mordred",
  "Yvain"
}
