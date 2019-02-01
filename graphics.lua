local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")
love.graphics.setLineStyle("rough")

graphics.charsheet = function(img)
  local quad = {}
  local h = math.floor(img:getHeight()/48)
  for i = 1, 8 do
    quad[i] = {}
    for j = 1, h do
      quad[i][j] = love.graphics.newQuad((i-1)*32, (j-1)*48, 32, 48, img:getDimensions())
    end
  end
  return quad
end

graphics.spritesheet = function(tw, th, img)
  local quad = {}
  local w = math.floor(img:getWidth()/tw)
  local h = math.floor(img:getHeight()/th)
  for i = 0, h - 1 do
    for j = 0, w - 1 do
      quad[i*h+j+1] = love.graphics.newQuad(j*tw, i*th, tw, th, img:getDimensions())
    end
  end
  return quad
end

graphics.init = function()
  font = love.graphics.newImageFont("font.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.,:", 1)
  fontcontrast = love.graphics.newImageFont("fontcontrast.png",
    " ABCDEFGHIJKLMNOPQRSTUVWXYZ" ..
    "abcdefghijklmnopqrstuvwxyz" ..
    "0123456789!?.,:", 0)
  love.graphics.setFont(font)
  love.graphics.setBackgroundColor(60/255, 152/255, 70/255)

  local img = {}
  local files = love.filesystem.getDirectoryItems("images")
  for i, v in ipairs(files) do
    img[string.sub(v, 1, -5)] = love.graphics.newImage("images/"..v)
  end

  local char = {}
  local files = love.filesystem.getDirectoryItems("char")
  for i, v in ipairs(files) do
    char[v] = {idle = {}, run = {}, idleoverlay = {}, runoverlay = {}}
    -- base images
    char[v].idle.img = love.graphics.newImage("char/"..v.."/idle.png")
    char[v].idle.quad = graphics.charsheet(char[v].idle.img)
    char[v].run.img = love.graphics.newImage("char/"..v.."/run.png")
    char[v].run.quad = graphics.charsheet(char[v].run.img)
    -- overlays
    char[v].idleoverlay.img = love.graphics.newImage("char/"..v.."/idleoverlay.png")
    char[v].runoverlay.img = love.graphics.newImage("char/"..v.."/runoverlay.png")
  end

  local quad = {}
  quad.teamlist1 = love.graphics.newQuad(0, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist2 = love.graphics.newQuad(128, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist3 = love.graphics.newQuad(256, 0, 128, 256, img.teamlist:getDimensions())
  quad.icons1 = love.graphics.newQuad(0, 0, 128, 12, img.menuicons:getDimensions())
  quad.icons2 = love.graphics.newQuad(0, 12, 128, 12, img.menuicons:getDimensions())
  quad.sliderbar = love.graphics.newQuad(0, 0, 124, 12, img.slider:getDimensions())
  quad.slidernode = love.graphics.newQuad(124, 0, 4, 12, img.slider:getDimensions())
  quad.shield = graphics.spritesheet(32, 32, img.shield)
  quad.drop = love.graphics.newQuad(0, 0, 16, 16, img.blood:getDimensions())
  quad.puddle = love.graphics.newQuad(16, 0, 16, 16, img.blood:getDimensions())
  for i = 1, 8 do
    quad[i] = love.graphics.newQuad((i-1)*32, 0, 32, 32, img.shield_spark:getDimensions())
  end

  return img, quad, char
end

return graphics
