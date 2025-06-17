local QBCore = exports['qb-core']:GetCoreObject()
local missionActive = false
local leader = nil
local npcModel = nil
local baseCoords = vector4(140.38, -1278.89, 29.33, 296.19)
local npcModels = {
    'a_f_y_beach_01',
    'a_f_y_vinewood_01',
    'a_f_y_femaleagent',
    'a_f_y_tourist_01',
    'a_f_y_clubcust_01'
}

local function spawnNPCAll(pos)
    TriggerClientEvent('sutener:fullNPCReset', -1, pos, npcModel, leader)
end

RegisterNetEvent('sutener:tryStart', function()
    local src = source
    if missionActive then
        TriggerClientEvent('sutener:msg', src, "Миссия уже занята!")
        return
    end
    missionActive = true
    leader = src
    npcModel = npcModels[math.random(#npcModels)]
    spawnNPCAll({x=baseCoords.x, y=baseCoords.y, z=baseCoords.z, w=baseCoords.w})
    TriggerClientEvent('sutener:setStage', src, 1)
    TriggerClientEvent('sutener:msg', src, "Миссия начата! Заберите девушку на базе.")
end)

RegisterNetEvent('sutener:resetNPC', function(pos)
    if not missionActive then return end
    spawnNPCAll(pos)
end)

RegisterNetEvent('sutener:setStage', function(newStage)
    if leader == source and missionActive then
        TriggerClientEvent('sutener:setStage', source, newStage)
    end
end)

RegisterNetEvent('sutener:msg', function(text)
    if leader == source and missionActive then
        TriggerClientEvent('sutener:msg', source, text)
    end
end)

RegisterNetEvent('sutener:complete', function()
    if leader ~= source or not missionActive then return end
    local Player = QBCore.Functions.GetPlayer(source)
    if Player then
        Player.Functions.AddMoney('cash', 200, "sutener-mission")
    end
    TriggerClientEvent('sutener:fullNPCReset', -1, {x=baseCoords.x, y=baseCoords.y, z=-100.0, w=baseCoords.w}, npcModel)
    TriggerClientEvent('sutener:msg', source, "Миссия завершена!")
    missionActive = false
    leader = nil
    npcModel = nil
end)