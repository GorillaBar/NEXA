const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

function formatMoney(number, decPlaces, decSep, thouSep) {
    decPlaces = isNaN(decPlaces = Math.abs(decPlaces)) ? 2 : decPlaces,
    decSep = typeof decSep === "undefined" ? "." : decSep;
    thouSep = typeof thouSep === "undefined" ? "," : thouSep;
    var sign = number < 0 ? "-" : "";
    var i = String(parseInt(number = Math.abs(Number(number) || 0).toFixed(decPlaces)));
    var j = (j = i.length) > 3 ? j % 3 : 0;

    return sign +
        (j ? i.substr(0, j) + thouSep : "") +
        i.substr(j).replace(/(\decSep{3})(?=\decSep)/g, "$1" + thouSep) +
        (decPlaces ? decSep + Math.abs(number - i).toFixed(decPlaces).slice(2) : "");
}

var userConnected = ''
var banned = false
var discord = 'None'
var gangname = 'User is not in a gang.'
exports.runcmd = (fivemexports, client, message, params) => {
    if (!params[0]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'profile [permid]')
    }
    fivemexports.nexa.getConnected([parseInt(params[0])], function(connected) {
        userConnected = connected
    })
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_user_vehicles` WHERE user_id = ?", [params[0]], (cars) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_user_data` WHERE user_id = ?", [params[0]], (userdata) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_warnings WHERE user_id = ?", [params[0]], (warnings) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_user_moneys WHERE user_id = ?", [params[0]], (money) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_casino_chips WHERE user_id = ?", [params[0]], (chips) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_users` WHERE id = ?", [params[0]], (users) => {
    fivemexports.ghmattimysql.execute("SELECT discord_id FROM `nexa_verification` WHERE user_id = ?", [params[0]], (discordid) => {
    fivemexports.ghmattimysql.execute("SELECT gangname FROM `nexa_gang_users` WHERE user_id = ?", [params[0]], (gang) => {
        if (gang[0] && gang[0].gangname !== null) {
            gangname = `User is in gang ${gang[0].gangname}.`
        } else {
            gangname = 'User is not in a gang.'
        }
        discord = `<@${discordid[0].discord_id}>`
        hours = JSON.stringify(JSON.parse(userdata[0].dvalue).PlayerTime/60)
        obj = JSON.parse(userdata[0].dvalue).groups
        lastlogin = users[0].last_login
        if (users[0].banned == 1) {
            banned = 'Yes'
        }
        else {
            banned = 'No'
        }
        let embed = {
            "title": `**User Profile**`,
            "description": `Perm ID: ***${params[0]}***`,
            "color": settingsjson.settings.botColour,
            "fields": [
                {
                    name: '**Last Known Username:**',
                    value: `${users[0].username}`,
                    inline: true,
                },
                {
                    name: '**Associated Discord:**',
                    value: `${discord}`,
                    inline: true,
                },
                {
                    name: '**Balance:**',
                    value: `Wallet: £${money[0].wallet.toLocaleString()}\nBank: £${money[0].bank.toLocaleString()}\nChips: ${chips[0].chips.toLocaleString()}`,
                    inline: true,
                }, 
                {
                    name: '**Connected:**',
                    value: `User is ${userConnected}.`,
                    inline: true,
                },
                {
                    name: '**Last Logged In:**',
                    value: `${lastlogin}`,
                    inline: true,
                },
                {
                    name: '**Hours:**',
                    value: `User has a total of ${Math.round(hours)} hours.`,
                    inline: true,
                },
                {
                    name: '**Gang:**',
                    value: `${gangname}`,
                    inline: true,
                },
                {
                    name: '**Garage:**',
                    value: `User has a total of ${cars.length} vehicles in their garage.`,
                    inline: true,
                },
                {
                    name: '**F10:**',
                    value: `User has a total of ${warnings.length} warnings.`,
                    inline: true,
                },
                {
                    name: '**Groups:**',
                    value: `${(JSON.stringify(Object.keys(obj)).replace(/"/g, '').replace('[', '').replace(']', '')).replace(/,/g, ', ')}`,
                    inline: true,
                },
                {
                    name: '**Banned:**',
                    value: `${banned}`,
                    inline: true,
                }, 
            ],
            "footer": {
                "text": `nexa | nexa.cc`
            },
            "timestamp": new Date()
        }
        message.channel.send({ embed })
    });
    });
    });
    });
    });
    });
    });
    });
}

exports.conf = {
    name: "profile",
    perm: 1,
}