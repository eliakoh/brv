local enabled = false

SetNuiFocus(false)

Citizen.CreateThread(function()
  SetNuiFocus(false)

  while true do
    Wait(0)
    if IsControlJustReleased(0, 190) and not enabled and exports.brv_main:isPlayerInLobby() and not exports.brv_main:isPlayerInSpectatorMode() then -- INPUT_FRONTEND_RIGHT
      if GetVehiclePedIsIn(GetPlayerPed(-1), false) ~= 0 then
        TriggerEvent('brv:showNotification', 'No menu in car !')
      else
        enabled = true
        SendNUIMessage({
          enableui = enabled,
        })
        SetNuiFocus(enabled)
      end
    end

    if enabled then
      exports.brv_main:drawInstructionalButtons({
        {
          button = '~INPUT_FRONTEND_LEFT~',
          label = 'CANCEL',
        },
        {
          button = '~INPUT_FRONTEND_RIGHT~',
          label = 'OK',
        },
        {
          button = '~INPUT_FRONTEND_UP~',
          label = 'UP',
        },
        {
          button = '~INPUT_FRONTEND_DOWN~',
          label = 'DOWN',
        },
      })
    end
  end
end)

RegisterNUICallback('hideMenu', function(data)
    SetNuiFocus(false)
    enabled = false
end)

RegisterNUICallback('callbackMenu', function(data, cb)
  TriggerEvent(data.callback, data.source)
  cb('ok')
end)

RegisterNUICallback('serverCallbackMenu', function(data, cb)
  TriggerServerEvent(data.callback, data.source)
  cb('ok')
end)
