
exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'notes [permid]')
    }
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_user_notes` WHERE user_id = ?", [params[0]], (result) => {
        let notes = ''
        if (result.length > 0) {
            if (result[0].info) {
                let noteInfo = JSON.parse(result[0].info)
                for (i = 0; i < noteInfo.length; i++) { 
                    notes = notes + `\nID: ${noteInfo[i].id} ${noteInfo[i].note} (${noteInfo[i].author})`
                }
                let embed = {
                    "title": `**Player Notes**`,
                    "description": `**Success**! Notes have been fetched for User ID: ***${params[0]}***`,
                    "color": settingsjson.settings.botColour,
                    "fields": [
                        {
                            name: '**Notes:**',
                            value: notes,
                        }
                    ],
                    "footer": {
                        "text": ""
                    },
                    "timestamp": new Date()
                }
                message.channel.send({ embed })
            }
            else {
                message.reply('User has no notes.')
            }
        }
        else {
            message.reply(`Unable to fetch notes for ID: ${params[0]}.`)
        }
    });
}

exports.conf = {
    name: "notes",
    perm: 1,
}