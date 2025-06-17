Config = {
    Inventory = 'ox', -- 'ox' или 'qb'
    RequiredItem = 'weapon_knife',

    NPC = {
        models = {
            'a_f_y_topless_01',
            'a_f_y_vinewood_01',
            'a_f_y_beach_01',
            'a_f_y_femaleagent'
        },
        walkSpeed = 1.0,
        timeout = 30
    },

    Points = {
        pickup = {
            pos = vector4(140.38, -1278.89, 29.33, 296.19),
            blip = {sprite = 280, color = 5, label = "Забрать девушку"}
        },
        dropoff = {
            pos = vector3(177.69, -1334.18, 29.32),
            walkTo = vector3(170.86, -1336.55, 29.3),
            blip = {sprite = 480, color = 2, label = "Клиент"}
        },
        base = {
            pos = vector3(143.97, -1276.3, 29.07),
            walkTo = vector3(136.76, -1278.74, 29.36),
            blip = {sprite = 480, color = 1, label = "База"}
        }
    },

    Payment = {
        amount = 2000,
        type = 'cash'
    }
}