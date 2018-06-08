local vector = require "vector"
local collision = require "collision"

local ai = {}

ai.num = {{0, 0}, {0, 0}} -- table that keeps track of desired amount of bots in servermenu

-- receiver AI
ai.receiver = {own = "score",
               team_ball = "block",
               team_pass = "catch",
               qb = "run",
               enemy_qb = "block",
               enemy_ball = "sack",
               enemy_pass = "catch"}

 -- linesmen AI
ai.linesmen = {own = "score",
              team_ball = "block",
              team_pass = "block",
              qb = "block",
              enemy_qb = "sack",
              enemy_ball = "sack",
              enemy_pass = "catch"}

ai.generate_bots = function() -- function that creates AIs
  ai.num[1] = {math.floor(ai.num[1][1]), math.floor(ai.num[1][2])}
  ai.num[2] = {math.floor(ai.num[2][1]), math.floor(ai.num[2][2])}
  local total_ai = 0
  local start_i = 0
  for i, v in pairs(players) do -- find where player index left off
    if i > start_i then
      start_i = i
    end
  end
  for i = 1, 2 do -- for both teams
    for j = 1, ai.num[i][1] do -- linesmen
      total_ai = total_ai + 1 -- increase total ai num
      players[start_i+total_ai] = {}
      v = players[start_i+total_ai]

      v.bot = true
      v.type = "linesmen"

      v.team = i
      v.name = bot_names[total_ai]

      network.host:sendToAll("newplayer", {info = v, index = start_i+total_ai})
    end
    for j = 1, ai.num[i][2] do -- receivers
      total_ai = total_ai + 1 -- increase total ai num
      players[start_i+total_ai] = {}
      v = players[start_i+total_ai]

      v.type = "receiver"
      v.bot = true
      
      v.team = i
      v.name = bot_names[total_ai]

      network.host:sendToAll("newplayer", {info = v, index = start_i+total_ai})
    end
  end
end

ai.process = function(i, v, dt)
  local set_speed = false

  v.d = vector.scale(0.9, v.d)
  if not v.dead and down.t <= 0 then -- make sure down has started
    if (ball.owner and players[ball.owner].team == v.team) or (not ball.owner and players[qb].team == v.team) then -- offense
      if ball.owner and ball.owner == i then -- has ball
        ai[ai[v.type].own](i, v, dt)
      elseif ball.owner and ball.owner ~= qb then -- team has ball
        ai[ai[v.type].team_ball](i, v, dt)
      elseif ball.thrown then -- ball in air
        ai[ai[v.type].team_pass](i, v, dt)
      else -- go long!
        ai[ai[v.type].qb](i, v, dt)
      end
      local active = false
      if not ball.owner or ball.owner ~= i then -- can't shield if with ball
        for j, w in pairs(players) do -- check if bot needs to shield
          if v.team ~= w.team then
            if math.sqrt(vector.mag_sq(collision.get_distance(v.p, w.p))) < sword.dist+sword.r then -- check if bot is within attack distance of another player
              active = true
              if not v.shield.active then
                v.shield.active = true
                network.host:sendToAll("shieldstate", {index = i, info = true})
                set_speed = true
              else
                -- face blockee
                local follow = ai.follow(v.p, w.p)
                v.mouse = follow

                v.shield.d = vector.scale(shield.dist, v.mouse)
                network.host:sendToAll("shieldpos", {info = v.shield.d, index = i})
              end
            end
          end
        end
      end
      if (v.shield.active and active == false) or (ball.owner and ball.owner == i) then -- deactivate shield if not necessary or impossible
        v.shield.active = false
        network.host:sendToAll("shieldstate", {index = i, info = false})
        set_speed = true
      end
    else -- defense
      if ball.owner and ball.owner == qb then -- enemy has ball
        ai[ai[v.type].enemy_qb](i, v, dt)
      elseif ball.owner then
        ai[ai[v.type].enemy_ball](i, v, dt)
      elseif not ball.owner then -- enemy throw
        ai[ai[v.type].enemy_pass](i, v, dt)
      end
    end
  end

  return set_speed
end

ai.score = function(i, v, dt)
  local d = {x = -(v.team-1.5)*2, y = 0}
  for j, w in pairs(players) do -- influence bot direction
    if v.team ~= w.team then
      d.y = d.y + ai.avoid(v.p, w.p, 64).y
    end
  end
  -- move
  d = vector.norm(d)
  v.d = vector.sum(v.d, d)

  -- look
  v.mouse = d
end

ai.block = function(i, v, dt)
  local nearest = {dist = math.huge, i = 0}
  for j, w in pairs(players) do -- find closest enemy
    if v.team ~= w.team then -- make sure it is an enemy
      local dist = math.sqrt(vector.mag_sq(collision.get_distance(v.p, w.p)))
      if dist < nearest.dist then -- find smallest distance
        nearest.dist = dist
        nearest.i = j
      end
    end
  end
  local d = ai.follow(v.p, players[nearest.i].p) -- find direction to nearest enemy
  if ball.owner then -- dodge around ball carrier
    local avoid = ai.avoid(v.p, players[ball.owner].p, 20)
    d = vector.norm(vector.sum(d, avoid))
  end

  -- move
  v.d = vector.sum(v.d, d)

  -- look
  v.mouse = d
end

ai.sack = function(i, v, dt)
  local follow = ai.follow(v.p, players[ball.owner].p)
  -- move
  v.d = vector.sum(v.d, follow)

  -- look
  v.mouse = follow

  -- attack
  if math.sqrt(vector.mag_sq(collision.get_distance(v.p, players[ball.owner].p))) < sword.dist+sword.r then
    v.sword.active = true
    v.sword.d = vector.scale(sword.dist, vector.norm(v.mouse))
    v.sword.t = sword.t
    network.host:sendToAll("sword", {index = i, active = true, mouse = v.mouse})
    set_speed = true
  end
end

ai.run = function(i, v, dt)
  -- move
  local d = 0
  if ball.owner then
    d = -(players[ball.owner].team-1.5)*2
  else
    d = -(players[qb].team-1.5)*2
  end
  v.d.x = v.d.x + d

  -- look
  v.mouse.x = d
  v.mouse.y = 0
end

ai.catch = function(i, v, dt)
  local follow = ai.follow(v.p, ball.goal)
  -- move
  v.d = vector.sum(v.d, follow)

  -- look
  v.mouse = follow
end

ai.follow = function(p1, p2)
  local angle = math.atan2(p2.y-p1.y, p2.x-p1.x)
  return {x = math.cos(angle), y = math.sin(angle)}
end

ai.avoid = function(p1, p2, r)
  local angle = math.atan2(p2.y-p1.y, p2.x-p1.x)
  local dist = math.sqrt(vector.mag_sq(collision.get_distance(p1, p2)))
  return {x = -math.cos(angle)*(r*r)/(dist*dist), y = -math.sin(angle)*(r*r)/(dist*dist)}
end

return ai
