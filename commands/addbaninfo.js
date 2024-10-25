const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0] || !parseInt(params[0]) || !params[1]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'addbaninfo [user-id] [info]')
    }
    baninfo = params.join(' ').replace(params[0], '')
    fivemexports.ghmattimysql.execute("UPDATE `nexa_users` SET baninfo = ? WHERE id = ?", [baninfo, params[0]])
    let embed = {
        "title": "Added Baninfo",
        "description": `\nPerm ID: **${params[0]}**\nBan Info: **${baninfo}**\n\nAdmin: <@${message.author.id}>`,
        "color": settingsjson.settings.botColour,
        "footer": {
            "text": ""
        },
        "timestamp": new Date()
    }
    message.channel.send({ embed })
}

exports.conf = {
    name: "addbaninfo",
    perm: 1,
}