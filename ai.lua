local ai = {}

ai.num = {0, 0} -- table that keeps track of desired amount of bots in servermenu

ai.generate_bots = function() -- function that creates AIs
  ai.num[1] = math.floor(ai.num[1])
  ai.num[2] = math.floor(ai.num[2])
  local total_ai = 0
  local start_i = 0
  for i, v in pairs(players) do -- find where player index left off
    if i > start_i then
      start_i = i
    end
  end
  for i = 1, 2 do -- for both teams
    for j = 1, ai.num[i] do
      total_ai = total_ai + 1 -- increase total ai num
      players[start_i+total_ai] = {}
      v = players[start_i+total_ai]
      v.bot = true

      v.team = i
      v.name = bot_names[total_ai]

      network.host:sendToAll("newplayer", {info = v, index = start_i+total_ai})
    end
  end
end

return ai
