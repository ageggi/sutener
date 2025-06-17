local currentNPC = nil
local missionStage = 0
local blip = nil
local canInteract = false
local QBCore = nil
local isWorking = false

-- Инициализация QBCore с защитой
CreateThread(function()
    while true do
        QBCore = exports['qb-core']:GetCoreObject()
        if QBCore then break end
        Wait(200)
    end
    print('^2[sutener] QBCore готов^0')
end)

-- Проверка предмета с логированием
local function HasRequiredItem()
    local hasItem = false
    if Config.Inventory == 'ox' then
        hasItem = exports.ox_inventory:Search('count', Config.RequiredItem) > 0
    else
        hasItem = QBCore.Functions.HasItem(Config.RequiredItem)
    end
    print('^5[DEBUG] Проверка предмета: '..tostring(hasItem)..'^0')
    return hasItem
end

-- Создание NPC с улучшенной логикой
local function CreateGirl(coords)
    local model = Config.NPC.models[math.random(#Config.NPC.models)]
    print('^5[DEBUG] Загрузка модели: '..model..'^0')

    RequestModel(model)
    local timeout = 5000
    local start = GetGameTimer()

    while not HasModelLoaded(model) and GetGameTimer() - start < timeout do
        Wait(10)
    end

    if not HasModelLoaded(model) then
        print('^1[ERROR] Модель не загрузилась: '..model..'^0')
        return nil
    end

    local _, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z, false)
    if groundZ then coords.z = groundZ + 0.5 end

    local npc = CreatePed(4, model, coords.x, coords.y, coords.z, coords.w or 0.0, false, true)
    if not DoesEntityExist(npc) then
        print('^1[ERROR] Ошибка создания NPC^0')
        return nil
    end

    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedFleeAttributes(npc, 0, false)
    FreezeEntityPosition(npc, true) -- Фиксируем на месте до взаимодействия

    print('^2[SUCCESS] NPC создан: '..npc..'^0')
    return npc
end

-- Обновление маркера
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

-- Основной поток
CreateThread(function()
    while true do
        Wait(0)
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)

        if currentNPC and DoesEntityExist(currentNPC) then
            local npcPos = GetEntityCoords(currentNPC)
            canInteract = #(pos - npcPos) < 3.0 and IsPedInAnyVehicle(ped, false)

            if canInteract and IsControlJustPressed(0, 38) then
                if not HasRequiredItem() then
                    QBCore.Functions.Notify('Нужен нож для работы', 'error', 4500)
                    goto continue
                end

                local veh = GetVehiclePedIsIn(ped, false)
                for i = -1, GetVehicleMaxNumberOfPassengers(veh) do
                    if IsVehicleSeatFree(veh, i) then
                        FreezeEntityPosition(currentNPC, false)
                        TaskEnterVehicle(currentNPC, veh, -1, i, 1.0, 1, 0)
                        
                        if missionStage == 1 then
                            UpdateBlip(Config.Points.dropoff.pos, Config.Points.dropoff.blip)
                            QBCore.Functions.Notify('Вези девушку к клиенту', 'success', 4500)
                            missionStage = 2
                        elseif missionStage == 3 then
                            UpdateBlip(Config.Points.base.pos, Config.Points.base.blip)
                            QBCore.Functions.Notify('Вези девушку на базу', 'success', 4500)
                            missionStage = 4
                        end
                        canInteract = false
                        break
                    end
                end
            end
        end
        ::continue::
    end
end)

-- Логика миссии
CreateThread(function()
    while true do
        Wait(1000)
        if not isWorking then goto continue end

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
                RemoveBlip(blip)
                missionStage = 0
                currentNPC = nil
                isWorking = false
            end
        end
        ::continue::
    end
end)

-- Старт работы
RegisterNetEvent('qb-sutenerjob:startWork', function()
    if isWorking then return end
    print('^5[DEBUG] Запуск работы...^0')

    if not HasRequiredItem() then
        QBCore.Functions.Notify('Нужен нож для работы', 'error', 4500)
        return
    end

    isWorking = true
    missionStage = 1

    if currentNPC and DoesEntityExist(currentNPC) then
        DeleteEntity(currentNPC)
    end

    currentNPC = CreateGirl(Config.Points.pickup.pos)
    if not currentNPC then
        isWorking = false
        QBCore.Functions.Notify('Ошибка при создании NPC', 'error', 4500)
        return
    end

    UpdateBlip(Config.Points.pickup.pos, Config.Points.pickup.blip)
    QBCore.Functions.Notify('Найди девушку и посади в машину', 'primary', 4500)
end)

-- Второй этап
RegisterNetEvent('qb-sutenerjob:secondStage', function()
    if not isWorking then return end
    print('^5[DEBUG] Второй этап...^0')

    missionStage = 3
    currentNPC = CreateGirl(vector4(
        Config.Points.dropoff.pos.x,
        Config.Points.dropoff.pos.y,
        Config.Points.dropoff.pos.z,
        0.0
    ))

    if not currentNPC then
        QBCore.Functions.Notify('Ошибка при создании NPC', 'error', 4500)
        return
    end

    UpdateBlip(Config.Points.base.pos, Config.Points.base.blip)
    QBCore.Functions.Notify('Забери девушку и вези на базу', 'primary', 4500)
end)