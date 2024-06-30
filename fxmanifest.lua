fx_version 'cerulean'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_core'
description 'Core functions for MSK Scripts'
version '2.1.4'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/cl_*.lua',
    'shared/shared.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sv_*.lua',
    'shared/shared.lua',
}

ui_page 'html/index.html'

files {
	"html/**/*.*",
    'import.lua'
}

dependencies {
    'oxmysql'
}