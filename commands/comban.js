const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0] || !params[1]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'comban [discord-id] [reason]')
    }
    var reason = params.join(' ').replace(params[0], '')
    var guilds = client.guilds
    Array.from(guilds.keys()).map((key) => { 
        let member = guilds.get(key).members.get(params[0])
        if (member) {
            member.ban({ reason: reason, days: 7 })
        }
    })
    let embed = {
        "description": `> User <@${params[0]}> has been community banned from all nexa related discord servers.`,
        "color": settingsjson.settings.botColour,
    }
    message.channel.send({ embed })
}

exports.conf = {
    name: "comban",
    perm: 3,
}
