const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0] || !parseInt(params[0]) || !params[1]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'storeredeem [permid] [uuid]')
    }
    let permid = params[0]
    let uuid = params[1]
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_store_data` WHERE uuid = ?", [uuid], async (result) => {
        if (result.length > 0) {
            if (result[0].user_id == permid) {
                fivemexports.ghmattimysql.execute("DELETE FROM `nexa_store_data` WHERE uuid = ?", [uuid], async (deletion) => {
                    let embed = {
                        "title": "Store Redeemed",
                        "description": `\nPerm ID: **${permid}**\nUUID: **${uuid}**\nItem: **${result[0].store_item}**\n\nAdmin: <@${message.author.id}>`,
                        "color": settingsjson.settings.botColour,
                        "footer": {
                            "text": ""
                        },
                        "timestamp": new Date()
                    }
                    message.channel.send({ embed })
                });
            } else {
                message.reply(`${uuid} is not owned by ID: ${permid}`)
            }
        } else {
            message.reply(`${uuid} is not a valid UUID`)
        }
    });
}

exports.conf = {
    name: "storeredeem",
    perm: 3,
}