local particle = {}

particle.stuckarrow = function(k, v, dt)
  if v.t < 12 then
    v.t = v.t + dt*24
    v.quad = math.floor(v.t % 8)+1
  elseif v.quad > 1 then
    v.quad = 1
  end
  return true
end

particle.shield_spark = function(k, v, dt)
  v.x = players[v.parent].p.x
  v.y = players[v.parent].p.y
  if v.t < 8 then
    v.t = v.t + dt*24
    v.quad = math.floor(v.t)+1
    if v.quad > 8 then
      v.quad = 8
    end
    return true
  else
    return false
  end
end

particle.bloodspurt = function(k, v, dt)
  v.x = players[v.parent].p.x
  v.y = players[v.parent].p.y
  if v.t < 8 then
    v.t = v.t + dt*16
    v.quad = math.floor(v.t)+1
    if v.quad > 8 then
      v.quad = 8
    end
    return true
  else
    return false
  end
end

particle.blood = function(k, v, dt)
  v.x = v.x + v.dx
  v.dx = v.dx * 0.9
  v.y = v.y + v.dy
  v.dy = v.dy * 0.9
  if v.z > 0 then
    v.z = v.z + v.dz
    v.dz = v.dz - dt * 12
  else
    v.z = 0
    v.quad = "puddle"
  end
  return true
end

return particle
