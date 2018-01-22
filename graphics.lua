local graphics = {}

love.graphics.setDefaultFilter("nearest", "nearest")

graphics.init = function()
  local img = {}
  local files = love.filesystem.getDirectoryItems("images")
  for i, v in ipairs(files) do
    img[string.sub(v, 1, -5)] = love.graphics.newImage("images/"..v)
  end

  local quad = {}
  quad.teamlist1 = love.graphics.newQuad(0, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist2 = love.graphics.newQuad(128, 0, 128, 256, img.teamlist:getDimensions())
  quad.teamlist3 = love.graphics.newQuad(256, 0, 128, 256, img.teamlist:getDimensions())
  quad.icons1 = love.graphics.newQuad(0, 0, 128, 12, img.menuicons:getDimensions())
  quad.icons2 = love.graphics.newQuad(0, 12, 128, 12, img.menuicons:getDimensions())
  quad.sliderbar = love.graphics.newQuad(0, 0, 124, 12, img.slider:getDimensions())
  quad.slidernode = love.graphics.newQuad(124, 0, 4, 12, img.slider:getDimensions())

  return img, quad
end

return graphics
