fx_version 'cerulean'
game 'gta5'

author 'ageggi'
description 'sutener job (qbcore/ox_inventory ready)'
version '1.0.1'

shared_script 'config.lua'

client_scripts {
    'client/cl_main.lua',
    'client/cl_commands.lua'
}

server_scripts {
    'server/sv_main.lua'
}

lua54 'yes'