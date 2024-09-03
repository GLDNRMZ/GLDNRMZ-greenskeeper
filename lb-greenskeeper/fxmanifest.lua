fx_version 'cerulean'
game 'gta5'

author 'GLDNRMZ'
description 'Golf Greenskeeper'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'bridge/client/**.lua',
    'cl_greenskeeper.lua'
}

server_scripts {
    'bridge/server/**.lua',
    'sv_config.lua',
    'sv_greenskeeper.lua',
}

lua54 'yes'
