RegisterServerEvent('chatCommandEntered')
RegisterServerEvent('chatMessageEntered')

AddEventHandler('chatMessageEntered', function(name, color, message)
    if not name or not color or not message or #color ~= 3 then
        return
    end

    TriggerEvent('chatMessage', source, name, message)

    if not WasEventCanceled() then
        TriggerEvent('brv:getPlayerData', source, 'brvchat:sendMessage', {color = color, message = message})
    end
end)

AddEventHandler('brvchat:sendMessage', function(playerData, data)
  TriggerEvent('brv:sendToDiscord', playerData.name, data.message)

  if playerData.admin then
    playerData.name = '^8' .. playerData.name
  end
  TriggerClientEvent('chatMessage', -1, playerData.name, data.color, data.message)
end)

-- say command handler
AddEventHandler('rconCommand', function(commandName, args)
    if commandName == "say" then
        local msg = table.concat(args, ' ')

        TriggerClientEvent('chatMessage', -1, 'console', { 0, 0x99, 255 }, msg)
        RconPrint('console: ' .. msg .. "\n")

        CancelEvent()
    end
end)

-- tell command handler
AddEventHandler('rconCommand', function(commandName, args)
    if commandName == "tell" then
        local target = table.remove(args, 1)
        local msg = table.concat(args, ' ')

        TriggerClientEvent('chatMessage', tonumber(target), 'console', { 0, 0x99, 255 }, msg)
        RconPrint('console: ' .. msg .. "\n")

        CancelEvent()
    end
end)
