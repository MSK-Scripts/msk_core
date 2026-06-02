fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

name 'msk_core'
description 'Shared library for MSK Scripts'
author 'Musiker15 - MSK Scripts'
license 'SEE LICENSE IN LICENSE.md'
repository 'https://github.com/MSK-Scripts/msk_core'
version '3.0.0'

shared_scripts {
    'config.lua',
    'bridge/shared.lua',
    'init/shared.lua',
}

client_scripts {
    'init/client.lua',
    'bridge/**/client.lua',
    'inventories/client/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'init/server.lua',
    'bridge/**/server.lua',
    'inventories/server/*.lua',
}

ui_page 'web/dist/index.html'

files {
    'import.lua',
    'aliases.lua',
    'modules/**/shared.lua',
    'modules/**/client.lua',
    'web/dist/**/*',
}

dependencies {
    '/server:7290',
    '/onesync',
    'oxmysql',
}
