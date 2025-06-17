local QBCore = exports['qb-core']:GetCoreObject()
local currentNPC = nil
local missionStage = 0
local blip = nil

local function CreateGirl(coords)
    local model = Config.NPC.models[math.random(#Config.NPC.models)]
    RequestModel(model)
    local timeout = 5000
    local start = GetGameTimer()
    while not HasModelLoaded(model) and GetGameTimer() - start < timeout do Wait(10) end
    if not HasModelLoaded(model) then QBCore.Functions.Notify('Ошибка загрузки модели', 'error') return nil end
    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    if groundZ then coords.z = groundZ + 0.5 end
    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, false, true)
    if not DoesEntityExist(npc) then QBCore.Functions.Notify('Ошибка создания NPC', 'error') return nil end
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    FreezeEntityPosition(npc, true)
    return npc
end

local function UpdateBlip(coords, settings)
    if blip then RemoveBlip(blip) end
    blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, settings.sprite)
    SetBlipColour(blip, settings.color)
    SetBlipRoute(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(settings.label)
    EndTextCommandSetBlipName(blip)
end

RegisterNetEvent('qb-sutenerjob:missionStart', function()
    missionStage = 1
    if currentNPC and DoesEntityExist(currentNPC) then DeleteEntity(currentNPC) end
    currentNPC = CreateGirl(Config.Points.pickup.pos)
    if not currentNPC then TriggerServerEvent('qb-sutenerjob:fail') return end
    UpdateBlip(Config.Points.pickup.pos, Config.Points.pickup.blip)
    QBCore.Functions.Notify('Найди девушку и посади в машину', 'primary', 4500)
end)

RegisterNetEvent('qb-sutenerjob:secondStage', function()
    missionStage = 3
    currentNPC = CreateGirl(vector4(Config.Points.dropoff.pos.x, Config.Points.dropoff.pos.y, Config.Points.dropoff.pos.z, 0.0))
    if not currentNPC then QBCore.Functions.Notify('Ошибка при создании NPC', 'error', 4500) return end
    UpdateBlip(Config.Points.base.pos, Config.Points.base.blip)
    QBCore.Functions.Notify('Забери девушку и вези на базу', 'primary', 4500)
end)

RegisterNetEvent('qb-sutenerjob:missionEnd', function()
    if blip then RemoveBlip(blip) end
    if currentNPC and DoesEntityExist(currentNPC) then DeleteEntity(currentNPC) end
    missionStage = 0
    currentNPC = nil
    QBCore.Functions.Notify('Миссия завершена!', 'success', 4500)
end)

CreateThread(function()
    while true do
        Wait(0)
        if missionStage == 0 or not currentNPC or not DoesEntityExist(currentNPC) then goto continue end
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local npcPos = GetEntityCoords(currentNPC)
        if #(pos - npcPos) < 3.0 and IsPedInAnyVehicle(ped, false) then
            if IsControlJustPressed(0, 38) then
                TriggerServerEvent('qb-sutenerjob:tryInteract', missionStage)
                Wait(1000)
            end
        end
        ::continue::
    end
end)

RegisterNetEvent('qb-sutenerjob:stageSuccess', function(stage)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    for i = -1, GetVehicleMaxNumberOfPassengers(veh) do
        if IsVehicleSeatFree(veh, i) then
            FreezeEntityPosition(currentNPC, false)
            TaskEnterVehicle(currentNPC, veh, -1, i, 1.0, 1, 0)
            if stage == 1 then
                UpdateBlip(Config.Points.dropoff.pos, Config.Points.dropoff.blip)
                QBCore.Functions.Notify('Вези девушку к клиенту', 'success', 4500)
                missionStage = 2
            elseif stage == 3 then
                UpdateBlip(Config.Points.base.pos, Config.Points.base.blip)
                QBCore.Functions.Notify('Вези девушку на базу', 'success', 4500)
                missionStage = 4
            end
            break
        end
    end
end)

RegisterNetEvent('qb-sutenerjob:noItem', function()
    QBCore.Functions.Notify('У тебя нет ножа!', 'error', 4500)
end)

-- Миссионные этапы
CreateThread(function()
    while true do
        Wait(1000)
        if missionStage == 0 then goto continue end
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local veh = GetVehiclePedIsIn(ped, false)

        if missionStage == 2 and currentNPC and veh and IsPedInVehicle(currentNPC, veh, false) then
            if #(pos - Config.Points.dropoff.pos) < 15.0 then
                TaskLeaveVehicle(currentNPC, veh, 0)
                Wait(3000)
                TaskGoToCoordAnyMeans(currentNPC, Config.Points.dropoff.walkTo.x, Config.Points.dropoff.walkTo.y, Config.Points.dropoff.walkTo.z, Config.NPC.walkSpeed, 0, false, 786603, 0xbf800000)
                QBCore.Functions.Notify('Вернись через '..Config.NPC.timeout..' сек', 'primary', 4500)
                missionStage = 3
                currentNPC = nil
                SetTimeout(Config.NPC.timeout * 1000, function()
                    if missionStage == 3 then
                        TriggerEvent('qb-sutenerjob:secondStage')
                    end
                end)
            end
        elseif missionStage == 4 and currentNPC and veh and IsPedInVehicle(currentNPC, veh, false) then
            if #(pos - Config.Points.base.pos) < 15.0 then
                TaskLeaveVehicle(currentNPC, veh, 0)
                Wait(3000)
                TaskGoToCoordAnyMeans(currentNPC, Config.Points.base.walkTo.x, Config.Points.base.walkTo.y, Config.Points.base.walkTo.z, Config.NPC.walkSpeed, 0, false, 786603, 0xbf800000)
                TriggerServerEvent('qb-sutenerjob:completeMission')
                QBCore.Functions.Notify('Миссия завершена!', 'success', 4500)
                if blip then RemoveBlip(blip) end
                missionStage = 0
                currentNPC = nil
            end
        end
        ::continue::
    end
end)