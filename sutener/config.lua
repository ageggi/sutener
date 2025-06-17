Config = {
    -- Системные настройки
    Inventory = 'qb', -- 'ox' или 'qb'
    RequiredItem = 'weapon_knife', -- Точное название предмета
    
    -- Настройки NPC
    NPC = {
        models = {
            'a_f_y_topless_01',
            'a_f_y_vinewood_01',
            'a_f_y_beach_01',
            'a_f_y_femaleagent'
        }, -- Проверенные рабочие модели
        walkSpeed = 1.0, -- Скорость движения NPC
        timeout = 30 -- Секунд между этапами (увеличено для теста)
    },
    
    -- Локации (проверенные координаты)
    Points = {
        pickup = {
            pos = vector4(140.38, -1278.89, 29.33, 296.19),  -- Гетто LS
            blip = {sprite = 280, color = 5, label = "Забрать девушку"}
        },
        dropoff = {
            pos = vector3(177.69, -1334.18, 29.32),  -- Виневуд
            walkTo = vector3(170.86, -1336.55, 29.3),
            blip = {sprite = 480, color = 2, label = "Клиент"}
        },
        base = {
            pos = vector3(143.97, -1276.3, 29.07),  -- Баллас территория
            walkTo = vector3(136.76, -1278.74, 29.36),
            blip = {sprite = 480, color = 1, label = "База"}
        }
    },
    
    -- Награда
    Payment = {
        amount = 2000,
        type = 'cash'
    }
}