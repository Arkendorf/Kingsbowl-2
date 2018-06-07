local vector = require "vector"
local collision = require "collision"

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

ai.run = function(i, v, dt)
  local set_speed = false

  v.d = vector.scale(0.9, v.d)
  if down.t <= 0 then -- make sure down has started
    if (ball.owner and players[ball.owner].team == v.team) or (not ball.owner and players[qb].team == v.team) then -- offense
      if ball.owner and ball.owner == i then -- try to score
        local d = {x = -(v.team-1.5)*2, y = 0}
        for j, w in pairs(players) do -- influence bot direction
          if v.team ~= w.team then
            local angle = math.atan2(w.p.y-v.p.y, w.p.x-v.p.x)
            local dist = math.sqrt(vector.mag_sq(collision.get_distance(v.p, w.p)))
            d.x = d.x - math.cos(angle)/(dist*dist)
            d.y = d.y - math.sin(angle)/(dist*dist)
          end
        end
        -- move
        d = vector.norm(d)
        v.d.x = v.d.x + d.x
        v.d.y = v.d.y + d.y

        -- look
        v.mouse.x = d.x
        v.mouse.y = d.y
      elseif ball.owner and ball.owner ~= qb then -- go to nearest enemy
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
        local angle = math.atan2(players[nearest.i].p.y-v.p.y, players[nearest.i].p.x-v.p.x) -- find direction to nearest enemy
        local d = {x = math.cos(angle), y = math.sin(angle)}
        -- dodge around ball carrier
        local baller_angle = math.atan2(players[ball.owner].p.y-v.p.y, players[ball.owner].p.x-v.p.x)
        local baller_dist = math.sqrt(vector.mag_sq(collision.get_distance(v.p, players[ball.owner].p)))
        d.x = d.x - math.cos(baller_angle)/(baller_dist*baller_dist)
        d.y = d.y - math.sin(baller_angle)/(baller_dist*baller_dist)
        d = vector.norm(d)

        -- move
        v.d.x = v.d.x + d.x
        v.d.y = v.d.y + d.y

        -- look
        v.mouse.x = math.cos(angle)
        v.mouse.y = math.sin(angle)
      elseif ball.thrown then -- go to ball's destination
        -- move
        local angle = math.atan2(ball.goal.y-v.p.y, ball.goal.x-v.p.x)
        v.d.x = v.d.x + math.cos(angle)
        v.d.y = v.d.y + math.sin(angle)

        -- look
        v.mouse.x = math.cos(angle)
        v.mouse.y = math.sin(angle)
      else -- go long!
        -- move
        v.d.x = v.d.x - (v.team-1.5)*2

        -- look
        v.mouse.x = 1
        v.mouse.y = 0
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
                local angle = math.atan2(w.p.y-v.p.y, w.p.x-v.p.x) -- set up angle
                v.mouse.x = math.cos(angle)
                v.mouse.y = math.sin(angle)

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
      if ball.owner then -- try to tackle baller
        -- move
        local angle = math.atan2(players[ball.owner].p.y-v.p.y, players[ball.owner].p.x-v.p.x)
        v.d.x = v.d.x + math.cos(angle)
        v.d.y = v.d.y + math.sin(angle)

        -- look
        v.mouse.x = math.cos(angle)
        v.mouse.y = math.sin(angle)

        -- attack
        if math.sqrt(vector.mag_sq(collision.get_distance(v.p, players[ball.owner].p))) < sword.dist+sword.r then
          v.sword.active = true
          v.sword.d = vector.scale(sword.dist, vector.norm(v.mouse))
          v.sword.t = sword.t
          network.host:sendToAll("sword", {index = i, active = true, mouse = v.mouse})
          set_speed = true
        end
      elseif not ball.owner then -- try to intercept
        -- move
        local angle = math.atan2(ball.goal.y-v.p.y, ball.goal.x-v.p.x)
        v.d.x = v.d.x + math.cos(angle)
        v.d.y = v.d.y + math.sin(angle)

        -- look
        v.mouse.x = math.cos(angle)
        v.mouse.y = math.sin(angle)
      end
    end
  end

  return set_speed
end

return ai
