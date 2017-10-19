local sum = function(v1, v2)
  local result = {}
  for k,v1_k in pairs(v1) do
    result[k] = v1_k + v2[k]
  end
  return result
end

local scale = function(s, v)
  local result = {}
  for k,v_k in pairs(v) do
    result[k] = s*v_k
  end
  return result
end

local dot = function(v1, v2)
  local result = 0
  for k,v1_k in pairs(v1) do
    result = result + v1_k * v2[k]
  end
  return dot
end

return {
  sum = sum,
  scale = scale,
  dot = dot
}
