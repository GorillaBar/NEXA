var AsciiTable = require('ascii-table');
const Discord = require('discord.js');
const fs = require('fs');
const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0] || !parseInt(params[0])) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'showf10 [permid]')
    }
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_warnings` WHERE user_id = ?", [params[0]], (result) => {
        fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_bans_offenses` WHERE UserID = ?", [params[0]], (offenses) => {
            var table = new AsciiTable(`F10 Warnings for Perm ID ${[params[0]]}`)
            table.setHeading('Warning ID', 'Warning Type', 'Duration', 'Points', 'Reason', 'Admin', 'Date')
            for (i = 0; i < result.length; i++) {
                var date = new Date(+result[i].warning_date)
                table.addRow(result[i].warning_id, result[i].warning_type, result[i].duration, Math.floor(result[i].duration/24), result[i].reason, result[i].admin, date.toDateString())
            }
            if (result.length == 0){
                return message.reply(`Perm ID ${params[0]} has no warnings!`)
            }
            message.channel.send('```ascii\n' + table.toString() + '\nCurrent F10 Points: '+offenses[0].points+'```').catch(err => {
                fs.writeFile(`${client.path}/warnings_${params[0]}.txt`, table.toString()+ '\nCurrent F10 Points: '+offenses[0].points, function(err) {
                    message.channel.send(`This F10 is too large for Discord, ${message.author}`, { files: [`${client.path}/warnings_${params[0]}.txt`] }).then(ss => {
                        fs.unlinkSync(`${client.path}/warnings_${params[0]}.txt`)
                    })
                });
            })
        })
    });
}

exports.conf = {
    name: "sw",
    perm: 1,
}