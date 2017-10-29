local client = require "client"
local server = require "server"


menus = {}

menus[1] = {buttons = {{x = 352, y = 275, w = 96, h = 36, txt = "server", func = server.init, args = {}}, {x = 452, y = 275, w = 96, h = 36, txt = "client", func = client.init, args = {}}},
            textboxes = {{x = 252, y = 255, w = 148, h = 16, table = username, index = 1, sampletxt = "Username"}, {x = 252, y = 275, w = 96, h = 16, table = ip, index = "ip", sampletxt = "I.P."}, {x = 252, y = 295, w = 96, h = 16, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {buttons = {{x = 1, y = 1, w = 40, h = 12, txt = "Leave", func = server.back_to_main, args = {}}, {x = 1, y = 13, w = 40, h = 12, txt = "Start", func = server.start_game, args = {}}}}
menus[3] = {buttons = {{x = 1, y = 1, w = 40, h = 16, txt = "Leave", func = client.back_to_main, args = {}}}}
menus[4] = {}

return menus
