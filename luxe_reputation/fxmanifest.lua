fx_version 'cerulean'
game 'gta5'
lua54 'yes'
ox_lib 'locale'

name 'luxe_reputation'
author 'Luxe Studios'
description 'Reputation menu on the radial menu - shows every Luxe rep in one place'
version '1.1.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
}
client_scripts { 'client.lua' }
server_scripts { 'server.lua' }

-- Works with Qbox, QBCore or ESX. ox_lib is always required.
dependencies { 'ox_lib' }

files { 'locales/*.json' }
