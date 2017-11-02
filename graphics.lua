local img = {}
local files = love.filesystem.getDirectoryItems("images")
for i, v in ipairs(files) do
  img[string.sub(v, 1, -5)] = love.graphics.newImage("images/"..v)
end
return img
