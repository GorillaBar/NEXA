const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (params[0] && parseInt(params[0])) {
        let user = params[0]
        fivemexports.ghmattimysql.execute("SELECT user_id FROM `nexa_verification` WHERE discord_id = ?", [params[0]], (result) => {
            if (result.length > 0) {
                let embed = {
                    "title": "Discord ID to Perm ID",
                    "description": `\n**Perm ID: **${result[0].user_id}**\nDiscord ID: **${[params[0]]}`,
                    "color": settingsjson.settings.botColour,
                    "footer": {
                        "text": ""
                    },
                    "timestamp": new Date()
                }
                message.channel.send({ embed })
            } else {
                message.reply('No account is linked for this user.')
            }
        });
    } else {
        message.reply('You need to specify a discord ID!')
    }
}

exports.conf = {
    name: "did2p",
    perm: 1,
}