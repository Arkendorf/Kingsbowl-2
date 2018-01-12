local graphics = {}

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

  return img, quad
end

return graphics
