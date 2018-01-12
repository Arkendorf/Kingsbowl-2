local clientmenu = require "clientmenu"
local servermenu = require "servermenu"


menus = {}

menus[1] = {buttons = {{x = 352, y = 275, w = 96, h = 36, txt = "server", func = servermenu.init, args = {}}, {x = 452, y = 275, w = 96, h = 36, txt = "client", func = clientmenu.init, args = {}}},
            textboxes = {{x = 252, y = 255, w = 148, h = 16, table = username, index = 1, sampletxt = "Username"}, {x = 252, y = 275, w = 96, h = 16, table = ip, index = "ip", sampletxt = "I.P."}, {x = 252, y = 295, w = 96, h = 16, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {buttons = {{x = 0, y = 0, w = 32, h = 48, txt = "Leave", func = servermenu.back_to_main, args = {}}, {x = 34, y = 0, w = 32, h = 48, txt = "Start", func = servermenu.start_game, args = {}},
           {x = (win_width/2) - 42, y = (win_height-256)/2, w = 12, h = 12, txt = "P", func = servermenu.swap_menu, args = {0, 1}}, {x = (win_width/2) - 28, y = (win_height-256)/2, w = 12, h = 12, txt = "S", func = servermenu.swap_menu, args = {1, 1}},
           {x = (win_width/2) + 118, y = (win_height-256)/2, w = 12, h = 12, txt = "P", func = servermenu.swap_menu, args = {0, 2}}, {x = (win_width/2) + 132, y = (win_height-256)/2, w = 12, h = 12, txt = "S", func = servermenu.swap_menu, args = {1, 2}}},
            textboxes = {{x = (win_width/2) - 144, y = (win_height-256)/2, w = 100, h = 12, table = team_info[1], index = "name", sampletxt = ""}, {x = (win_width/2) + 16, y = (win_height-256)/2, w = 100, h = 12, table = team_info[2], index = "name", sampletxt = ""}}}
menus[3] = {buttons = {{x = 0, y = 0, w = 32, h = 48, txt = "Leave", func = clientmenu.back_to_main, args = {}}}}
menus[4] = {}

return menus
