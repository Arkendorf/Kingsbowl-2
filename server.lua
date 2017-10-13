function createServer()
  server = lube.udpServer()
  server:listen(25565)
end

function server_update(dt)
  server:update(dt)
end
