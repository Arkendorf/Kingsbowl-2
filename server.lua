local createServer = function()
  server = grease.udpServer()
  server:listen(25565)
end

local server = createServer()

function server.callbacks.connect(clientid)
  success = true
end

function server.callbacks.recv(data, clientid)

end

function server.callbacks.disconnect(clientid)

end

function client.callbacks.recv(data)

end

local server_update = function(dt)
  server:update(dt)
end

return {server, server_update}
