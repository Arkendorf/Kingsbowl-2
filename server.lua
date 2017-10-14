local server = grease.udpServer()

server.callbacks.connect = function(clientid)
  success = true
end

server.callbacks.recv = function(data, clientid)

end

server.callbacks.disconnect = function(clientid)

end

local server_update = function(dt)
  server:update(dt)
end

return {server, server_update}
