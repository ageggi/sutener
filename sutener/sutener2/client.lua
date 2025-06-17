local QBCore = exports['qb-core']:GetCoreObject()
local npc = nil
local npcModel = nil
local isLeader = false
local isMyNPC = false
local stage = 0
local Blip = nil

local baseCoords = vector4(140.38, -1278.89, 29.33, 296.19)
local clientArrive = vector3(177.69, -1334.18, 29.32)
local clientWalkTo = vector3(183.0, -1332.0, 29.32)
local npcReturnTo = clientArrive

local function msg(text, type) QBCore.Functions.Notify(text, type or 'primary', 5000) end

local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(true)
        AddTextComponentString(text)
        DrawText(_x, _y)
        local factor = (string.len(text)) / 370
        DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 41, 11, 41, 68)
    end
end

local function getGroundZ(x, y, z)
    local success, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
    if success then return groundZ end
    for i = z, z - 20, -1 do
        success, groundZ = GetGroundZFor_3dCoord(x, y, i, false)
        if success then return groundZ end
    end
    return z
end

local function MakeMeOwner(entity)
    local timeout = 0
    while not NetworkHasControlOfEntity(entity) and timeout < 100 do
        NetworkRequestControlOfEntity(entity)
        Wait(100)
        timeout = timeout + 1
    end
end

local function createNPC(pos, model)
    RequestModel(model) while not HasModelLoaded(model) do Wait(10) end
    local groundZ = getGroundZ(pos.x, pos.y, pos.z)
    local ped = CreatePed(4, model, pos.x, pos.y, groundZ, pos.w or 0.0, true, true)
    SetEntityInvincible(ped, false)
    SetBlockingOfNonTemporaryEvents(ped, false)
    FreezeEntityPosition(ped, false)
    SetPedCanRagdoll(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, true)
    SetPedSuffersCriticalHits(ped, true)
    SetPedDiesWhenInjured(ped, true)
    SetPedConfigFlag(ped, 281, false)
    return ped
end

local function setBlip(coords, text)
    if DoesBlipExist(Blip) then RemoveBlip(Blip) end
    Blip = AddBlipForCoord(coords.x, coords.y, coords.z or coords.z)
    SetBlipSprite(Blip, 280)
    SetBlipColour(Blip, 5)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(text)
    EndTextCommandSetBlipName(Blip)
    SetBlipRoute(Blip, true)
end

RegisterCommand('sutener', function()
    TriggerServerEvent('sutener:tryStart')
end)

RegisterNetEvent('sutener:msg', function(text, type)
    msg(text, type)
end)

RegisterNetEvent('sutener:setStage', function(newStage)
    isLeader = true
    stage = newStage
    if DoesBlipExist(Blip) then RemoveBlip(Blip) end
    if stage == 1 or stage == 6 then setBlip(baseCoords, "База") end
    if stage == 2 or stage == 5 then setBlip(clientArrive, "Клиент") end
    if stage == 3 or stage == 4 then setBlip(clientWalkTo, "Клиент (пешком)") end
end)

RegisterNetEvent('sutener:spawnNPC', function(pos, model, ownerSrc)
    if npc and DoesEntityExist(npc) then DeleteEntity(npc) npc = nil end
    npc = createNPC(pos, model)
    npcModel = model
    if GetPlayerServerId(PlayerId()) == ownerSrc then
        MakeMeOwner(npc)
        isMyNPC = true
    else
        isMyNPC = false
    end
end)

RegisterNetEvent('sutener:removeNPC', function()
    if npc and DoesEntityExist(npc) then DeleteEntity(npc) npc = nil end
    isMyNPC = false
end)

RegisterNetEvent('sutener:reqConfirm', function()
    if npc and DoesEntityExist(npc) then DeleteEntity(npc) npc = nil end
    isMyNPC = false
    TriggerServerEvent('sutener:confirmNpcRemoved')
end)

-- Если NPC умерла — удаляем и сообщаем о провале
CreateThread(function()
    while true do
        Wait(500)
        if npc and DoesEntityExist(npc) and IsPedDeadOrDying(npc, true) then
            TriggerServerEvent('sutener:removeNPC')
            if isLeader then
                TriggerServerEvent('sutener:msg', "Девушка погибла! Миссия провалена.")
                isLeader = false
                stage = 0
                isMyNPC = false
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if not isLeader or not npc or not DoesEntityExist(npc) or not isMyNPC then goto continue end
        local ped = PlayerPedId()
        local ppos = GetEntityCoords(ped)
        local npos = GetEntityCoords(npc)

        if stage == 1 and #(ppos - npos) < 3.0 then
            DrawText3D(npos.x, npos.y, npos.z+1.0, "[E] Позвать девушку")
            if IsControlJustPressed(0, 38) then
                FreezeEntityPosition(npc, false)
                TaskGoToEntity(npc, ped, -1, 1.0, 2.0, 1073741824, 0)
                Wait(1800)
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then
                    TaskEnterVehicle(npc, veh, -1, 1, 1.0, 1, 0)
                end
                TriggerServerEvent('sutener:setStage', 2)
                TriggerServerEvent('sutener:msg', "Везите девушку к клиенту.")
            end
        end

        if stage == 2 and IsPedInVehicle(npc, GetVehiclePedIsIn(ped, false), false) and #(ppos - clientArrive) < 10.0 then
            TaskLeaveVehicle(npc, GetVehiclePedIsIn(ped, false), 0)
            Wait(1200)
            FreezeEntityPosition(npc, false)
            TaskGoStraightToCoord(npc, clientWalkTo.x, clientWalkTo.y, clientWalkTo.z, 1.0, -1, 0.0, 0.0)
            TriggerServerEvent('sutener:setStage', 3)
            TriggerServerEvent('sutener:msg', "Высадите девушку, она пойдет к клиенту.")
        end

        if stage == 3 and #(GetEntityCoords(npc) - clientWalkTo) < 1.5 then
            local lastPos = GetEntityCoords(npc)
            TriggerServerEvent('sutener:setStage', 4)
            TriggerServerEvent('sutener:msg', "Девушка обслуживает клиента... Ждите.")
            TriggerServerEvent('sutener:removeNPC')
            isMyNPC = false
            npc = nil
            SetTimeout(10000, function()
                TriggerServerEvent('sutener:respawnAfterClient', lastPos)
                Wait(200)
                TriggerServerEvent('sutener:setStage', 5)
                TriggerServerEvent('sutener:msg', "Девушка возвращается, заберите ее.")
            end)
        end

        if stage == 5 and npc and #(GetEntityCoords(npc) - npcReturnTo) < 2.0 then
            FreezeEntityPosition(npc, true)
            DrawText3D(npos.x, npos.y, npos.z + 1.0, "[E] Позвать девушку обратно")
            if IsControlJustPressed(0, 38) then
                FreezeEntityPosition(npc, false)
                TaskGoToEntity(npc, ped, -1, 1.0, 2.0, 1073741824, 0)
                Wait(1800)
                local veh = GetVehiclePedIsIn(ped, false)
                if veh ~= 0 then
                    TaskEnterVehicle(npc, veh, -1, 1, 1.0, 1, 0)
                end
                TriggerServerEvent('sutener:setStage', 6)
                TriggerServerEvent('sutener:msg', "Отвезите девушку обратно на базу.")
            end
        end

        if stage == 6 and IsPedInVehicle(npc, GetVehiclePedIsIn(ped, false), false) and #(ppos - vector3(baseCoords.x, baseCoords.y, baseCoords.z)) < 10.0 then
            TaskLeaveVehicle(npc, GetVehiclePedIsIn(ped, false), 0)
            Wait(1200)
            TriggerServerEvent('sutener:complete')
            isLeader = false
            stage = 0
            isMyNPC = false
        end
        ::continue::
    end
end)