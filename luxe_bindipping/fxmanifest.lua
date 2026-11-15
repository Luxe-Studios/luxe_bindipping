fx_version 'cerulean'
game 'gta5'
lua54 'yes'
ox_lib 'locale'

name 'luxe_bindipping'
author 'Luxe Studios'
description 'Bin dipping with a reputation system - more rep, better loot'
version '1.2.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}
client_scripts { 'bridge/client.lua', 'client.lua' }
server_scripts { 'bridge/server.lua', 'server.lua' }

-- Works with Qbox, QBCore, ESX or TMC (auto-detected). ox_lib is always required.
dependencies { 'ox_lib' }

files { 'locales/*.json' }
