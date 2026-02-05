fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'City Worker Job'
version '1.0.0'

shared_scripts {
    'config.lua',
    '@ox_lib/init.lua',
}

client_scripts {
    'cl_greenskeeper.lua'
}

server_scripts {
    'sv_config.lua',
    'sv_greenskeeper.lua',
}

dependency 'community_bridge'

lua54 'yes'
