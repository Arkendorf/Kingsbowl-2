local client = require "client"
local server = require "server"

menus = {}

menus[1] = {buttons = {{x = 352, y = 275, w = 96, h = 36, txt = "server", func = server.init, args = {}}, {x = 452, y = 275, w = 96, h = 36, txt = "client", func = client.init, args = {}}},
            textboxes = {{x = 252, y = 275, w = 96, h = 16, table = ip, index = "ip", sampletxt = "I.P."}, {x = 252, y = 295, w = 96, h = 16, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {buttons = {}}
menus[3] = {}

return menus
