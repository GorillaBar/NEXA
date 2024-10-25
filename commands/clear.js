exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'clear [amount]')
    }
    if (params[0] > 100) {
        return message.reply("You can't clear more than 100 messages!")
    }
    else {
        message.channel.bulkDelete(parseInt(params[0]), true).then((_message) => {
            let embed = {
                "title": "Cleared Messages",
                "description": `\nAmount: **${params[0]}**\n\nAdmin: <@${message.author.id}>`,
                "color": settingsjson.settings.botColour,
                "footer": {
                    "text": ``
                },
                "timestamp": new Date()
            }
            message.channel.send({embed}).then(function (message) {
                setTimeout(function () {
                    message.delete();
                }, 3000);
            })
        })
    }
}

exports.conf = {
    name: "clear",
    perm: 2,
}