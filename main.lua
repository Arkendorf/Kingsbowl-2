require "globals"
local servermenu = require "servermenu"
local servergame = require "servergame"
local clientmenu = require "clientmenu"
local clientgame = require "clientgame"
local mainmenu = require "mainmenu"
local gui = require "gui"
local menus = require "menus"
local state = require "state"

local quit = 2

love.load = function()
  gui.new(menus[1])
  math.randomseed(os.time())
end

love.update = function(dt)
  global_dt = dt
  if state.game == false and network.mode == "server" then
    servermenu.update(dt)
  elseif state.game == false and network.mode == "client" then
    clientmenu.update(dt)
  elseif state.game == true and network.mode == "server" then
    servergame.update(dt)
  elseif state.game == true and network.mode == "client" then
    clientgame.update(dt)
  end
  gui:update(dt)
  if love.keyboard.isDown("escape") then
    quit = quit - dt
    if quit <= 0 then
      love.event.quit()
    end
  elseif quit < 1 then
    quit = 1
  end
end

love.draw = function()
  love.graphics.setCanvas(win_canvas)
  love.graphics.clear()
  if state.game == false and network.mode == "server" then
    servermenu.draw()
  elseif state.game == false and network.mode == "client" then
    clientmenu.draw()
  elseif state.game == true and network.mode == "server" then
    servergame.draw()
  elseif state.game == true and network.mode == "client" then
    clientgame.draw()
  else
    mainmenu.draw()
  end
  love.graphics.setCanvas()
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(win_canvas, 0, 0, 0, 2, 2)
end

love.quit = function()
  if state.game == false and network.mode == "server" then
    servermenu.quit()
  elseif state.game == false and network.mode == "client" then
    clientmenu.quit()
  elseif state.game == true and network.mode == "server" then
    servergame.quit()
  elseif state.game == true and network.mode == "client" then
    clientgame.quit()
  end
end

love.mousepressed = function(x, y, button)
  if not joystick then
    if state.game == true and network.mode == "server" then
      servergame.mousepressed(x, y, button)
    elseif state.game == true and network.mode == "client" then
      clientgame.mousepressed(x, y, button)
    end
  end
  gui:mousepressed(x, y, button)
end

love.mousereleased = function(x, y, button)
  if not joystick then
    if network.mode == "server" then
      servergame.mousereleased(x, y, button)
    elseif network.mode == "client" then
      clientgame.mousereleased(x, y, button)
    end
  end
end

love.mousemoved = function(x, y, dx, dy, istouch)
  if not joystick then
    if state.game == true and network.mode == "server" then
      servergame.mousemoved(x, y, dx, dy, istouch)
    elseif state.game == true and network.mode == "client" then
      clientgame.mousemoved(x, y, dx, dy, istouch)
    end
  end
end

love.gamepadpressed = function(j, button)
  if joystick and button ~= "leftstick" or "rightstick" then
    if state.game == true and network.mode == "server" then
      servergame.mousepressed(0, 0, button)
    elseif state.game == true and network.mode == "client" then
      clientgame.mousepressed(0, 0, button)
    end
  end
end

love.gamepadreleased = function(j, button)
  if joystick and button ~= "leftstick" or "rightstick" then
    if network.mode == "server" then
      servergame.mousereleased(0, 0, button)
    elseif network.mode == "client" then
      clientgame.mousereleased(0, 0, button)
    end
  end
end

love.gamepadaxis = function(j, axis, value)
  if joystick and axis == "triggerright" or axis == "triggerleft" then
    if value >= 0.5 then
      if state.game == true and network.mode == "server" then
        servergame.mousepressed(0, 0, axis)
      elseif state.game == true and network.mode == "client" then
        clientgame.mousepressed(0, 0, axis)
      end
    else
      if network.mode == "server" then
        servergame.mousereleased(0, 0, axis)
      elseif network.mode == "client" then
        clientgame.mousereleased(0, 0, axis)
      end
    end
  end
end

love.textinput = function(t)
  gui:textinput(t)
end

love.keypressed = function(key)
  gui:keypressed(key)
end

love.keyreleased = function(key)
end

love.joystickadded = function(x)
  if not joystick and x:isGamepad() then
    joystick = x
    input = require("joystick")
  end
end
