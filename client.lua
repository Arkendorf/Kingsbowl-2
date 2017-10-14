local grease = require("grease.init")

local client = grease.udpClient()

function client.callbacks.recv(data)

end

function client_update(dt)
  client:update(dt)
end

return {client, client_update}
