local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")

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

graphics.init = function()
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
    char[v].idleoverlay.quad = graphics.charsheet(char[v].idleoverlay.img)
    char[v].runoverlay.img = love.graphics.newImage("char/"..v.."/runoverlay.png")
    char[v].runoverlay.quad = graphics.charsheet(char[v].runoverlay.img)
  end

  local quad = {}
  quad.teamlist1 = love.graphics.newQuad(0, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist2 = love.graphics.newQuad(128, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist3 = love.graphics.newQuad(256, 0, 128, 256, img.teamlist:getDimensions())
  quad.icons1 = love.graphics.newQuad(0, 0, 128, 12, img.menuicons:getDimensions())
  quad.icons2 = love.graphics.newQuad(0, 12, 128, 12, img.menuicons:getDimensions())
  quad.sliderbar = love.graphics.newQuad(0, 0, 124, 12, img.slider:getDimensions())
  quad.slidernode = love.graphics.newQuad(124, 0, 4, 12, img.slider:getDimensions())

  return img, quad, char
end

return graphics
