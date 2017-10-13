function connectToServer()
  client = lube.udpClient()
  success, err = client:connect("127.0.0.1", 25565)
  return success
end

function client_update(dt)
  client:update(dt)
end
