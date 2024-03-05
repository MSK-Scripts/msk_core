fx_version 'adamant'
games { 'gta5' }

author 'Musiker15 - MSK Scripts'
name 'msk_core'
description 'Core functions for MSK Scripts'
version '1.9.7'

lua54 'yes'

shared_scripts {
    'config.lua'
}

client_scripts {
    'client/main.lua',
    'client/cl_*.lua',
    'common/common.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/sv_*.lua',
    'common/common.lua',
}

ui_page 'html/index.html'

files {
	"html/**/*.*",
    'import.lua'
}

dependencies {
    'oxmysql'
}