local audio = {}

local track = 1

audio.init = function()
  local sfx = {}
  local files = love.filesystem.getDirectoryItems("sound/sfx")
  for i, v in ipairs(files) do
    sfx[string.sub(v, 1, -5)] = love.audio.newSource("sound/sfx/"..v, "static")
  end
  local music = {}
  local files = love.filesystem.getDirectoryItems("sound/music")
  for i, v in ipairs(files) do
    music[string.sub(v, 1, -5)] = love.audio.newSource("sound/music/"..v, "stream")
    music[string.sub(v, 1, -5)]:setVolume(.4)
  end
  return sfx, music
end

audio.play_sfx = function(effect)
  sfx[effect]:seek(0)
  sfx[effect]:setPitch(math.random(75, 150)/100)
  sfx[effect]:play()
end

audio.play_music = function(track, loop)
  music[track]:setLooping(loop or false)
  music[track]:seek(0)
  music[track]:play()
end

audio.start_background_music = function()
  love.audio.stop()
  track = 1
  music["game1"]:seek(0)
  music["game1"]:play()
end

audio.update_music = function()
  if not music["game"..tostring(track)]:isPlaying() then
    track = track + 1
    if track > 3 then
      track = 1
    end
    local file = music["game"..tostring(track)]
    file:seek(0)
    file:play()
  end
end

return audio
