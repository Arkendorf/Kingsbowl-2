local client = require "client"
local server = require "server"

menus = {}

menus[1] = {buttons = {{x = 200, y = 275, w = 100, h = 50, txt = "server", func = server.init, args = {}}, {x = 500, y = 275, w = 100, h = 50, txt = "client", func = client.init, args = {}}}}
menus[2] = {}
menus[3] = {}

return menus
