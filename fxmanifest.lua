fx_version 'cerulean'
games { 'gta5' }
lua54 'yes'

author "Swkeep"
description 'keep-paycheck'
url "https://github.com/swkeep/keep-paycheck"

shared_scripts {
     -- "@ox_lib/init.lua",
     'locale/locale.lua',
     'locale/en.lua',
     'shared.config.lua',
}

client_scripts {
     'client/target.lua',
     'client/client.bridge.lua',
     'client/client.core.lua',
}

server_script {
     '@oxmysql/lib/MySQL.lua',
     'server/server.db.lua',
     'server/server.bridge.lua',
     'server/server.core.lua',
}
