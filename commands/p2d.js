const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (params[0] && parseInt(params[0])) {
        fivemexports.ghmattimysql.execute("SELECT discord_id FROM `nexa_verification` WHERE user_id = ?", [params[0]], (result) => {
            if (result.length > 0) {
                let embed = {
                    "title": "Perm ID to Discord",
                    "description": `\n**Perm ID: **${[params[0]]}**\nDiscord**: <@${result[0].discord_id}>\n**Discord Profile**: https://lookup.guru/${result[0].discord_id}`,
                    "color": settingsjson.settings.botColour,
                    "footer": {
                        "text": ''
                    },
                    "timestamp": new Date()
                }
                message.channel.send({ embed })
            } else {
                let embed = {
                    "title": "Perm ID to Discord",
                    "description": `\nFailed! There is no Discord linked to this Perm ID!`,
                    "color": settingsjson.settings.botColour,
                    "footer": {
                        "text": ""
                    },
                    "timestamp": new Date()
                }
                message.channel.send({ embed })
            }
        });
    } else {
        let embed = {
            "title": "Perm ID to Discord",
            "description": `\nFailed! You need to enter a valid Perm ID!`,
            "color": settingsjson.settings.botColour,
            "footer": {
                "text": ""
            },
            "timestamp": new Date()
        }
        message.channel.send({ embed })
    }
}

exports.conf = {
    name: "p2d",
    perm: 1,
}