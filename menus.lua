local clientmenu = require "clientmenu"
local servermenu = require "servermenu"


menus = {}

menus[1] = {buttons = {{x = (true_win_width-192)/2, y = true_win_height/2+128, w = 192, h = 64, txt = "Host", func = servermenu.init, args = {}}, {x = (true_win_width+204)/2, y = true_win_height/2+128, w = 192, h = 64, txt = "Join", func = clientmenu.init, args = {}}},
            textboxes = {{x = (true_win_width-192)/2+12, y = true_win_height/2+64, w = 168, h = 32, table = username, index = 1, sampletxt = "Username"}, {x = (true_win_width-592)/2+20, y = true_win_height/2+128, w = 176, h = 32, table = ip, index = "ip", sampletxt = "I.P."}, {x = (true_win_width-592)/2+20, y = true_win_height/2+160, w = 176, h = 32, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {buttons = {{x = 4, y = 4, w = 96, h = 64, txt = "Leave", func = servermenu.back_to_main, args = {}}, {x = 104, y = 4, w = 96, h = 64, txt = "Start", func = servermenu.start_game, args = {}},
           {x = (true_win_width/2) - 84, y = (true_win_height-512)/2, w = 24, h = 24, txt = "P", func = servermenu.swap_menu, args = {0, 1}}, {x = (true_win_width/2) - 56, y = (true_win_height-512)/2, w = 24, h = 24, txt = "S", func = servermenu.swap_menu, args = {1, 1}},
           {x = (true_win_width/2) + 236, y = (true_win_height-512)/2, w = 24, h = 24, txt = "P", func = servermenu.swap_menu, args = {0, 2}}, {x = (true_win_width/2) + 264, y = (true_win_height-512)/2, w = 24, h = 24, txt = "S", func = servermenu.swap_menu, args = {1, 2}}},
            textboxes = {{x = (true_win_width/2) - 288, y = (true_win_height-512)/2, w = 200, h = 24, table = team_info[1], index = "name", sampletxt = ""}, {x = (true_win_width/2) + 32, y = (true_win_height-512)/2, w = 200, h = 24, table = team_info[2], index = "name", sampletxt = ""}}}
menus[3] = {buttons = {{x = 4, y = 4, w = 96, h = 64, txt = "Leave", func = clientmenu.back_to_main, args = {}}}}
menus[4] = {}

return menus
