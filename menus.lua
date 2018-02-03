local clientmenu = require "clientmenu"
local servermenu = require "servermenu"


menus = {}

menus[1] = {buttons = {{x = (win_width-96)/2, y = win_height/2+64, w = 96, h = 32, txt = "Host", func = servermenu.init, args = {}}, {x = (win_width+104)/2, y = win_height/2+64, w = 96, h = 32, txt = "Join", func = clientmenu.init, args = {}}},
            textboxes = {{x = (win_width-96)/2+6, y = win_height/2+32, w = 84, h = 16, table = username, index = 1, sampletxt = "Username"}, {x = (win_width-296)/2+10, y = win_height/2+64, w = 88, h = 16, table = ip, index = "ip", sampletxt = "I.P."}, {x = (win_width-296)/2+10, y = win_height/2+80, w = 88, h = 16, table = ip, index = "port", sampletxt = "Port", num = true}}}
menus[2] = {buttons = {{x = 2, y = 2, w = 48, h = 32, txt = "Leave", func = servermenu.back_to_main, args = {}}, {x = 52, y = 2, w = 48, h = 32, txt = "Start", func = servermenu.start_game, args = {}},
           {x = (win_width/2) - 42, y = (win_height-256)/2, w = 12, h = 12, txt = "P", func = servermenu.swap_menu, args = {0, 1}}, {x = (win_width/2) - 28, y = (win_height-256)/2, w = 12, h = 12, txt = "S", func = servermenu.swap_menu, args = {1, 1}},
           {x = (win_width/2) + 118, y = (win_height-256)/2, w = 12, h = 12, txt = "P", func = servermenu.swap_menu, args = {0, 2}}, {x = (win_width/2) + 132, y = (win_height-256)/2, w = 12, h = 12, txt = "S", func = servermenu.swap_menu, args = {1, 2}}},
            textboxes = {{x = (win_width/2) - 144, y = (win_height-256)/2, w = 100, h = 12, table = team_info[1], index = "name", sampletxt = ""}, {x = (win_width/2) + 16, y = (win_height-256)/2, w = 100, h = 12, table = team_info[2], index = "name", sampletxt = ""}}}
menus[3] = {buttons = {{x = 2, y = 2, w = 48, h = 32, txt = "Leave", func = clientmenu.back_to_main, args = {}}}}
menus[4] = {}

return menus
