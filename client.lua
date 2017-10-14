function connectToServer()
  client = grease.udpClient()
  local success, err = client:connect("127.0.0.1", 25565)
  return (success and client or err)
end

local client = connectToServer()

function client.callbacks.recv(data)

end

function client_update(dt)
  client:update(dt)
end

return {client, client_update}
