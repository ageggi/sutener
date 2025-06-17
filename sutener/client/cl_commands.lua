local isWorking = false

CreateThread(function()
    while not exports['qb-core'] do Wait(100) end
    local QBCore = exports['qb-core']:GetCoreObject()

    RegisterCommand('sutener', function()
        if isWorking then
            QBCore.Functions.Notify('Ты уже в работе!', 'error')
            return
        end

        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            QBCore.Functions.Notify('Нужно быть в машине!', 'error')
            return
        end

        isWorking = true
        TriggerServerEvent('qb-sutenerjob:startWork')
        print('^2[СЕРВЕР] Запрос работы отправлен^0')
    end)
end)