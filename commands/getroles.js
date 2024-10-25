const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

let groups = [
    'Supporter',
    'Premium',
    'Supreme',
    'Kingpin',
    'Rainmaker',
    'Baller',
]
let hours = [
    '1000',
    '2000',
    '3000',
    '4000',
    '5000',
    '6000',
    '7000',
    '8000',
    '9000',
    '10000',
]
exports.runcmd = async(fivemexports, client, message, params) => {
    let rolesCount = 0
    let rolesOwned = []
    let descriptionText = ':white_check_mark: You have received your discord roles:'
    fivemexports.ghmattimysql.execute("SELECT user_id FROM `nexa_verification` WHERE discord_id = ?", [message.author.id], (result) => {
        if (result.length > 0) {
            let user_id = result[0].user_id
            fivemexports.ghmattimysql.execute("SELECT dvalue FROM `nexa_user_data` WHERE user_id = ? AND dkey = 'nexa:datatable'", [user_id], async (data) => {
                let groupsdata = JSON.parse(Object.values(data[0])).groups
                for (const [key, value] of Object.entries(groupsdata)) {
                    for (j = 0; j < groups.length; j++) { 
                        if (groups[j] === key) {
                            let role = message.guild.roles.find(r => r.name === `| ${groups[j]}`)
                            rolesCount += 1
                            rolesOwned.push(`\n${key}`)
                            await message.member.addRole(role.id).then().catch(console.error);
                        }
                    }
                }
                // let playtime = JSON.parse(Object.values(data[0])).PlayerTime/60
                // for (j = 0; j < hours.length; j++) { 
                //     if (playtime >= parseInt(hours[j])) {
                //         let role = message.guild.roles.find(r => r.name === `| ${hours[j]} Hours`)
                //         rolesCount += 1
                //         rolesOwned.push(`\n${hours[j]} Hours`)
                //         await message.member.addRole(role.id).then().catch(console.error);
                //     }
                // }
                if (rolesCount > 0 ){
                    let embed = {
                        "title": "Roles",
                        "description": descriptionText+'```\n'+rolesOwned.join('').replace(',', '')+'```',
                        "color": settingsjson.settings.botColour,
                        "footer": {
                            "text": ""
                        },
                        "timestamp": new Date()
                    }
                    message.channel.send({ embed })
                    return
                }
            });
        } else {
            message.reply('You do not have a Perm ID connected to your discord.')
        }
    });
}

exports.conf = {
    name: "getroles",
    perm: 0,
}