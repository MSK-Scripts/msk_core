fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_core'
description 'Functions for MSK Scripts'
version '2.7.3'

lua54 'yes'

shared_scripts {
    -- '@ox_core/lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'shared/**/*.*',
    'client/functions/*.lua',
    'client/bridge/*.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'shared/**/*.*',
    'server/versionchecker.lua',
    'server/functions/*.lua',
    'server/inventories/*.lua',
    'server/bridge/*.lua',
}

ui_page 'html/index.html'

files {
	"html/**/*.*",
    'import.lua'
}

dependencies {
    '/server:7290',
    '/onesync',
    'oxmysql'
}