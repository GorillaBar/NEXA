fx_version 'cerulean'
games { 'gta5' }

server_only 'yes'

dependency 'yarn'

server_scripts {
    "@nexa/lib/utils.lua",
    "bot.js"
}

server_exports {
    'dmUser',
    'verifyDiscord',
}