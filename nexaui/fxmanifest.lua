fx_version "bodacious"
game "gta5"

loadscreen "html/loadscreen.html"
loadscreen_manual_shutdown "yes"

ui_page "ui/index.html"

-- client scripts
client_scripts{
    "@nexa/lib/utils.lua",
    "client/*.lua",
}

-- client files
files{
    "html/*",
    "ui/*.ttf",
    "ui/*.otf",
    "ui/*.woff",
    "ui/*.woff2",
    "ui/*.css",
    "ui/*.png",
    "ui/main.js",
    "ui/index.html",
}

server_scripts{
    "starter.js",
}