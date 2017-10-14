function connectToServer()
  client = grease.udpClient()
  local success, err = client:connect("127.0.0.1", 25565)
  return success
end

function client.callbacks.recv(data)

end

function client_update(dt)
  client:update(dt)
end
