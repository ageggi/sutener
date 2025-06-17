fx_version 'cerulean'
game 'gta5'

author 'Ваше имя'
description 'Работа сутенера для QBCore'
version '1.0.0'

dependencies {
    'qb-core' -- Зависимость от QBCore
}

client_scripts {
    '@qb-core/import.lua', -- Импорт QBCore первым!
    'config.lua',
    'client/cl_commands.lua',
    'client/cl_main.lua'
}

server_scripts {
    '@qb-core/import.lua', -- Импорт QBCore для сервера
    'config.lua',
    'server/sv_main.lua'
}