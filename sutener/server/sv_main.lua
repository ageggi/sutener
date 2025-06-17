local QBCore = exports['qb-core']:GetCoreObject()

-- Удаление предмета
RegisterNetEvent('qb-sutenerjob:removeItem', function(item, amount)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    if Config.Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(src, item, amount)
    else
        Player.Functions.RemoveItem(item, amount)
        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "remove", amount)
    end
    print(string.format('^5[DEBUG] Удален предмет %s x%d у игрока %s^0', item, amount, Player.PlayerData.name))
end)

-- Выплата награды
RegisterNetEvent('qb-sutenerjob:completeMission', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    Player.Functions.AddMoney(Config.Payment.type, Config.Payment.amount, 'sutener-job')
    print(string.format('^2[SUCCESS] Игрок %s получил $%d^0', Player.PlayerData.name, Config.Payment.amount))
end)

-- Команда для запуска работы
QBCore.Commands.Add("startsutener", "Начать работу сутенера", {}, false, function(source)
    TriggerClientEvent('qb-sutenerjob:startWork', source)
    print('^2[СЕРВЕР] Запрос работы отправлен игроку '..GetPlayerName(source)..'^0')
end)