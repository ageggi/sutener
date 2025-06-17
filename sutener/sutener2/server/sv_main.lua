local QBCore = exports['qb-core']:GetCoreObject()

local function PlayerHasKnife(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    if Config.Inventory == 'ox' then
        return exports.ox_inventory:Search(src, 'count', Config.RequiredItem) > 0
    else
        return Player.Functions.GetItemByName(Config.RequiredItem) ~= nil
    end
end

RegisterNetEvent('qb-sutenerjob:startWork', function()
    local src = source
    if not PlayerHasKnife(src) then
        TriggerClientEvent('qb-sutenerjob:noItem', src)
        return
    end
    TriggerClientEvent('qb-sutenerjob:missionStart', src)
end)

RegisterNetEvent('qb-sutenerjob:tryInteract', function(stage)
    local src = source
    if not PlayerHasKnife(src) then
        TriggerClientEvent('qb-sutenerjob:noItem', src)
        return
    end
    TriggerClientEvent('qb-sutenerjob:stageSuccess', src, stage)
end)

RegisterNetEvent('qb-sutenerjob:completeMission', function()
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.AddMoney(Config.Payment.type, Config.Payment.amount, "sutener-mission")
    TriggerClientEvent('qb-sutenerjob:missionEnd', src)
end)