local time = require("kubectl.utils.time")

local M = {}

local function getPorts(ports)
  local string_ports = ""
  if ports then
    for index, value in ipairs(ports) do
      string_ports = string_ports .. value.containerPort .. "/" .. value.protocol

      if index < #ports then
        string_ports = string_ports .. ","
      end
    end
  end
  return string_ports
end
local function getContainerState(state)
  for key, _ in pairs(state) do
    return key
  end
end

function M.processContainerRow(row)
  local data = {}

  for _, container in pairs(row.spec.containers) do
    for _, status in ipairs(row.status.containerStatuses) do
      if status.name == container.name then
        local result = {
          name = container.name,
          image = container.image,
          ready = status.ready,
          state = getContainerState(status.state),
          init = false,
          restarts = status.restartCount,
          ports = getPorts(container.ports),
          age = time.since(row.metadata.creationTimestamp),
        }

        table.insert(data, result)
      end
    end
  end
  return data
end

function M.getContainerHeaders()
  local headers = {
    "NAME",
    "IMAGE",
    "READY",
    "STATE",
    "INIT",
    "RESTARTS",
    "PORTS",
    "AGE",
  }

  return headers
end

return M
