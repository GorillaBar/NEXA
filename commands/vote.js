exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'vote [vote contents]')
    }
    const resourcePath = global.GetResourcePath ?
        global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
    require('dotenv').config({ path: path.join(resourcePath, './.env') })
    const settingsjson = require(resourcePath + '/settings.js')

    const vote = params.slice(0).join(' ');

    let embed = {
        "title": "Community Vote",
        "description": `\n${vote}`,
        "color": settingsjson.settings.botColour,
        "footer": {
            "text": `Please vote to make an impact on the server.`
        },
        "timestamp": new Date()
    }
    const channel = client.channels.find(channel => channel.name === settingsjson.settings.VoteChannel)
    channel.send({embed}).then(function (message) {
        message.react("👍")
        message.react("👎")
    })
    channel.send(`||@everyone||`)
    message.channel.send(`Started community vote in ${channel}`)
}

exports.conf = {
    name: "vote",
    perm: 2,
}