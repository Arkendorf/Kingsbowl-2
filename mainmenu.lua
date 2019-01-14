local mainmenu = {}

function mainmenu.draw()
  love.graphics.setFont(font)
  -- draw base
  love.graphics.setColor(1, 1, 1)
  love.graphics.draw(img.field, (win_width-field.w)/2, (win_height-field.h)/2)
  love.graphics.draw(img.mainmenu, (win_width-296)/2, win_height/2+64)
  love.graphics.draw(img.username, (win_width-96)/2, win_height/2+32)
  love.graphics.draw(img.logo, (win_width-256)/2, 0)

  -- draw button base
  love.graphics.setColor(team_info[1].color)
  love.graphics.draw(img.mainmenu_overlay, (win_width-96)/2, win_height/2+64)
  love.graphics.setColor(team_info[2].color)
  love.graphics.draw(img.mainmenu_overlay, (win_width+104)/2, win_height/2+64)

  -- draw button text
  love.graphics.setColor(229/255, 229/255, 229/255)
  love.graphics.print("Host", math.floor((win_width-font:getWidth("Host"))/2), win_height/2+76)
  love.graphics.print("Join", math.floor((win_width+196-font:getWidth("Join"))/2), win_height/2+76)

  -- draw ip text
  love.graphics.setColor(51/255, 51/255, 51/255)
  love.graphics.print(ip.ip, math.floor((win_width-296)/2+10), win_height/2+70)
  love.graphics.print(ip.port, math.floor((win_width-296)/2+10), win_height/2+82)
  love.graphics.print(username[1], math.floor((win_width-font:getWidth(username[1]))/2), win_height/2+36)
end

return mainmenu
