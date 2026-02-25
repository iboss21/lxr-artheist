--[[
    ██╗     ██╗  ██╗██████╗        ██████╗ ██████╗ ██████╗ ███████╗
    ██║     ╚██╗██╔╝██╔══██╗      ██╔════╝██╔═══██╗██╔══██╗██╔════╝
    ██║      ╚███╔╝ ██████╔╝█████╗██║     ██║   ██║██████╔╝█████╗  
    ██║      ██╔██╗ ██╔══██╗╚════╝██║     ██║   ██║██╔══██╗██╔══╝  
    ███████╗██╔╝ ██╗██║  ██║      ╚██████╗╚██████╔╝██║  ██║███████╗
    ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝       ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝

    🐺 LXR Core - Art Heist System | CLIENT UTILS
    © 2026 iBoss21 / The Lux Empire | wolves.land
]]

-- ████████████████████████████████████████████████████████████████████████████████
-- ████████████████████████ CLIENT UTILITIES ██████████████████████████████████████
-- ████████████████████████████████████████████████████████████████████████████████

--- A simple wrapper around SendNUIMessage that you can use to
--- dispatch actions to the React frame.
---
---@param action string The action you wish to target
---@param data any The data you wish to send along with this action


function SendReactMessage(action, data)
  SendNUIMessage({
    action = action,
    data = data
  })
end




function TriggerCallback(name, ...)
  local id = GetRandomIntInRange(0, 999999)
  local eventName = GetCurrentResourceName()..":triggerCallback:" .. id
  local eventHandler
  local promise = promise:new()
  RegisterNetEvent(eventName)
  local eventHandler = AddEventHandler(eventName, function(...)
      promise:resolve(...)
  end)

  SetTimeout(15000, function()
    promise:resolve("timeout")
    RemoveEventHandler(eventHandler)
  end)
  local args = {...}
  TriggerServerEvent(name, id, args)

  local result = Citizen.Await(promise)
  RemoveEventHandler(eventHandler)
  return result
end
