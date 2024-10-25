const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_anticheat", (result) => {
        if (result) {
            for (i = 0; i < result.length; i++) {
                let newval = fivemexports.nexa.nexabot('setBanned', [parseInt(result[i].user_id), false])
            }
            let embed = {
                "title": "AC Ban Database Cleared",
                "description": `Number of Bans removed: ${result.length}\n\nAdmin: <@${message.author.id}>`,
                "color": settingsjson.settings.botColour,
                "footer": {
                    "text": ""
                },
                "timestamp": new Date()
            }
            message.channel.send({ embed })
        }
    })
}

exports.conf = {
    name: "clearacbans",
    perm: 3,
}