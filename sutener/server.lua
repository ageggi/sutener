local QBCore = exports['qb-core']:GetCoreObject()
local missionActive = false
local leader = nil
local currentModel = nil
local respawnWaiting = false
local respawnPos = nil
local respawnConfirm = {}
local npcModels = {'a_f_y_beach_01','a_f_y_vinewood_01','a_f_y_femaleagent','a_f_y_tourist_01','a_f_y_clubcust_01'}
local baseCoords = vector4(140.38, -1278.89, 29.33, 296.19)

RegisterNetEvent('sutener:tryStart', function()
    local src = source
    if missionActive then
        TriggerClientEvent('sutener:msg', src, "Миссия уже занята!")
        return
    end
    missionActive = true
    leader = src
    currentModel = npcModels[math.random(#npcModels)]
    TriggerClientEvent('sutener:spawnNPC', -1, {x=baseCoords.x, y=baseCoords.y, z=baseCoords.z, w=baseCoords.w}, currentModel, leader)
    TriggerClientEvent('sutener:setStage', src, 1)
    TriggerClientEvent('sutener:msg', src, "Миссия начата! Заберите девушку на базе.")
end)

RegisterNetEvent('sutener:removeNPC', function()
    if missionActive then
        TriggerClientEvent('sutener:removeNPC', -1)
    end
end)

RegisterNetEvent('sutener:respawnAfterClient', function(pos)
    if not missionActive or source ~= leader or respawnWaiting then return end
    respawnWaiting = true
    respawnPos = pos
    respawnConfirm = {}
    TriggerClientEvent('sutener:removeNPC', -1)
    TriggerClientEvent('sutener:reqConfirm', -1)
    -- Таймер-страховка: если не все клиенты ответили, спавним всё равно, НО только если спавн ещё не запускался
    SetTimeout(2000, function()
        if respawnWaiting then
            TriggerClientEvent('sutener:spawnNPC', -1, respawnPos, currentModel, leader)
            respawnWaiting = false
            respawnPos = nil
            respawnConfirm = {}
        end
    end)
end)

RegisterNetEvent('sutener:confirmNpcRemoved', function()
    if not respawnWaiting then return end
    respawnConfirm[source] = true
    local players = GetPlayers()
    for _, id in ipairs(players) do
        if not respawnConfirm[tonumber(id)] then return end
    end
    -- Все подтвердили — спавним сразу (и только если ещё не заспавнили по таймеру)
    if respawnWaiting then
        TriggerClientEvent('sutener:spawnNPC', -1, respawnPos, currentModel, leader)
        respawnWaiting = false
        respawnPos = nil
        respawnConfirm = {}
    end
end)

RegisterNetEvent('sutener:setStage', function(newStage)
    local src = source
    if leader == src and missionActive then
        TriggerClientEvent('sutener:setStage', src, newStage)
    end
end)

RegisterNetEvent('sutener:msg', function(text)
    local src = source
    if leader == src and missionActive then
        TriggerClientEvent('sutener:msg', src, text)
    end
end)

RegisterNetEvent('sutener:complete', function()
    local src = source
    if leader ~= src or not missionActive then return end
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        Player.Functions.AddMoney('cash', 200, "sutener-mission")
    end
    TriggerClientEvent('sutener:removeNPC', -1)
    TriggerClientEvent('sutener:msg', src, "Миссия завершена!")
    missionActive = false
    leader = nil
    currentModel = nil
end)