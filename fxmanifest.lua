fx_version 'cerulean'
game 'gta5'

name 'cdecad-sync-qbox'
description 'Sync QBox characters to CDECAD - Character, Vehicle, and 911 integration'
author 'CDECAD'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/utils.lua'
}

server_scripts {
    'server/api.lua',
    'server/discord.lua',
    'server/main.lua',
    'server/commands.lua'
}

client_scripts {
    'client/main.lua',
    'client/911.lua'
}

dependencies {
    'qbx_core',
    'ox_lib'
}

-- Optional dependencies (will use if available)
-- 'Badger_Discord_API' - For Discord role checking
