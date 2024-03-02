fx_version 'cerulean'
game 'gta5'

author 'Randolio'
description 'Vehicle Exporting'

shared_scripts {
    '@ox_lib/init.lua',
    'shared.lua',
}

client_scripts {
    'bridge/client/**.lua',
    'cl_exports.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server/**.lua',
    'sv_config.lua',
    'sv_exports.lua',
}

files {
    'locales/*.json'
}

lua54 'yes'
