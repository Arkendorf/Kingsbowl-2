local client = require "client"
local server = require "server"

menus = {}

menus[1] = {buttons = {{x = 352, y = 275, w = 96, h = 36, txt = "server", func = create_server, args = {}}, {x = 452, y = 275, w = 96, h = 36, txt = "client", func = create_client, args = {}}},
            textboxes = {{x = 252, y = 275, w = 96, h = 16, table = ip, index = "ip", sampletxt = "I.P."}, {x = 252, y = 295, w = 96, h = 16, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {}
menus[3] = {}

return menus
