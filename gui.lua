love.keyboard.setKeyRepeat(true)
local gui = {}
local guis = {}

local item = {gui = 1, type = 0, num = 0, info = {}}

gui.update = function (gui, dt) -- love.update()
  for j, w in pairs(guis) do
    local gui = w
    if item.gui == j and item.type == 3 and item.num > 0 then
      if love.mouse.isDown(1) == false then
        item.type = 0
        item.num = 0
        item.info = {}
      elseif gui.sliders then
        local x, y = love.mouse.getPosition()
        if gui.sliders[item.num].alignment == 2 then
          gui.sliders[item.num].table[gui.sliders[item.num].index] = (y - item.info.offset - gui.sliders[item.num].y)/(gui.sliders[item.num].w-gui.sliders[item.num].barw)*(gui.sliders[item.num].numMax-gui.sliders[item.num].numMin)
        else
          gui.sliders[item.num].table[gui.sliders[item.num].index] = (x - item.info.offset - gui.sliders[item.num].x)/(gui.sliders[item.num].w-gui.sliders[item.num].barw)*(gui.sliders[item.num].numMax-gui.sliders[item.num].numMin)
        end
        if gui.sliders[item.num].table[gui.sliders[item.num].index] > gui.sliders[item.num].numMax then
          gui.sliders[item.num].table[gui.sliders[item.num].index] = gui.sliders[item.num].numMax
        elseif gui.sliders[item.num].table[gui.sliders[item.num].index] < gui.sliders[item.num].numMin then
          gui.sliders[item.num].table[gui.sliders[item.num].index] = gui.sliders[item.num].numMin
        end
      end
    end
  end
end

gui.draw = function (gui) -- love.draw()
  for j, w in pairs(guis) do
    local gui = w
    if gui.buttons ~= nil then
      for i, v in ipairs(gui.buttons) do
        love.graphics.setColor(100, 100, 100)
        love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(v.txt, math.floor(v.x+(v.w-font:getWidth(v.txt))/2), math.floor(v.y+(v.h-font:getHeight())/2))
      end
    end

    if gui.textboxes ~= nil then
      for i, v in ipairs(gui.textboxes) do
        love.graphics.setColor(100, 100, 100)
        love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
        love.graphics.setColor(1, 1, 1)
        if string.len(v.table[v.index]) > 0 then
          love.graphics.print(v.table[v.index], v.x, math.floor(v.y+(v.h-font:getHeight())/2))
        else
          love.graphics.print(v.sampletxt, v.x, math.floor(v.y+(v.h-font:getHeight())/2))
        end
      end
    end

    if gui.sliders ~= nil then
      for i, v in ipairs(gui.sliders) do
        if v.alignment == 2 then
          love.graphics.setColor(100, 100, 100)
          love.graphics.rectangle("fill", v.x, v.y, v.h, v.w)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("fill", v.x, v.y+v.table[v.index]/v.numMax*(v.w-v.barw), v.h, v.barw)
        else
          love.graphics.setColor(100, 100, 100)
          love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
          love.graphics.setColor(1, 1, 1)
          love.graphics.rectangle("fill", v.x+v.table[v.index]/v.numMax*(v.w-v.barw), v.y, v.barw, v.h)
        end
      end
    end

    if gui.dropdowns ~= nil then
      for i, v in ipairs(gui.dropdowns) do
        love.graphics.setColor(100, 100, 100)
        love.graphics.rectangle("fill", v.x, v.y, v.w-v.h, v.h)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("fill", v.x+v.w-v.h, v.y, v.h, v.h)
        love.graphics.print(tostring(v.table[v.index]), v.x, math.floor(v.y+(v.h-font:getHeight())/2))
        love.graphics.setColor(100, 100, 100)
        love.graphics.polygon("fill", v.x+v.w-v.h*.25, v.y+v.h*.25, v.x+v.w-v.h*.25, v.y+v.h*.75, v.x+v.w-v.h*.75, v.y+v.h*.75)
        if item.gui == j and item.type == 4 and item.num == i then
          for j, k in ipairs(v.options) do
            love.graphics.setColor(100, 100, 100)
            love.graphics.rectangle("fill", v.x, v.y+j*v.h, v.w, v.h)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(tostring(k), v.x, math.floor(v.y+j*v.h+(v.h-font:getHeight())/2))
          end
        end
      end
    end
  end
end

gui.mousepressed = function (gui, x, y, button) -- love.mousepressed
  local guiClick = false
  for j, w in pairs(guis) do
    local gui = w
    local clickUsed = false
    if gui.buttons ~= nil then
      for i, v in ipairs(gui.buttons) do
        if button == 1 and x >= v.x and x <= v.x+v.w and y >= v.y and y <= v.y+v.h then
          item.type = 2
          item.num = i
          clickUsed = true
          v.func(unpack(v.args))
        end
      end
    end

    if clickUsed == false and gui.textboxes ~= nil then
      for i, v in ipairs(gui.textboxes) do
        if button == 1 and x >= v.x and x <= v.x+v.w and y >= v.y and y <= v.y+v.h then
          item.type = 2
          item.num = i
          clickUsed = true
          break
        end
      end
    end

    if clickUsed == false and gui.sliders ~= nil then
      for i, v in ipairs(gui.sliders) do
        if v.alignment == 2 and button == 1 and x >= v.x and x <= v.x+v.h and y >= v.y+v.table[v.index]/v.numMax*(v.w-v.barw) and y <= v.y+v.table[v.index]/v.numMax*(v.w-v.barw)+v.barw then
          item.type = 3
          item.num = i
          item.info.offset = y-(v.y+v.table[v.index]/v.numMax*(v.w-v.barw))
          clickUsed = true
          break
        elseif button == 1 and x >= v.x+v.table[v.index]/v.numMax*(v.w-v.barw) and x <= v.x+v.table[v.index]/v.numMax*(v.w-v.barw)+v.barw and y >= v.y and y <= v.y+v.h then
          item.type = 3
          item.num = i
          item.info.offset = x-(v.x+v.table[v.index]/v.numMax*(v.w-v.barw))
          clickUsed = true
          break
        end
      end
    end

    if clickUsed == false and gui.dropdowns ~= nil then
      for i, v in ipairs(gui.dropdowns) do
        if (item.gui ~= j or item.type ~= 4 or item.num ~= i) and button == 1 and x >= v.x+v.w-v.h and x <= v.x+v.w and y >= v.y and y <= v.y+v.h then
          item.type = 4
          item.num = i
          clickUsed = true
          break
        elseif item.type == 4 and item.num == i and button == 1 then
          for j = 1, #v.options do
            if x >= v.x and x <= v.x+v.w and y >= v.y+j*v.h and y <= v.y+(j+1)*v.h then
              v.table[v.index] = v.options[j]
              item.type = 0
              item.num = 0
              clickUsed = true
              break
            end
          end
        end
      end
    end


    if clickUsed == true then
      guiClick = true
      item.gui = j
      break
    end
  end
  if guiClick == false then
    item.type = 0
    item.num = 0
    item.info = {}
  end
end

gui.textinput = function (gui, t) -- love.textinput
  for j, w in pairs(guis) do
    local gui = w
    if gui.textboxes ~= nil and item.gui == j and item.type == 2 and item.num > 0 and font:getWidth(gui.textboxes[item.num].table[gui.textboxes[item.num].index]..t) <= gui.textboxes[item.num].w/2 and (gui.textboxes[item.num].num == nil or gui.textboxes[item.num].num == false or (gui.textboxes[item.num].num == true and string.find("0123456789.", t) ~= nil)) then
      gui.textboxes[item.num].table[gui.textboxes[item.num].index] = gui.textboxes[item.num].table[gui.textboxes[item.num].index]..t
    end
  end
end

gui.keypressed = function (gui, key) -- love.keypressed
  for j, w in pairs(guis) do
    local gui = w
    if gui.textboxes ~= nil and item.gui == j and item.type == 2 and item.num > 0 and key == "backspace" then
      gui.textboxes[item.num].table[gui.textboxes[item.num].index] = string.sub(gui.textboxes[item.num].table[gui.textboxes[item.num].index], 1, -2)
    end
  end
end

gui.new = function(t)
  guis = {t}
end

gui.add = function(t, i)
  if i then
    guis[i] = t
  else
    guis[#guis+1] = t
  end
end

gui.remove = function(i)
  guis[i] = nil
end


return gui
