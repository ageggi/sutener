CreateThread(function()
    RegisterCommand('sutener', function()
        if not IsPedInAnyVehicle(PlayerPedId(), false) then
            exports['qb-core']:GetCoreObject().Functions.Notify('Нужно быть в машине!', 'error')
            return
        end
        TriggerServerEvent('qb-sutenerjob:startWork')
    end)
end)