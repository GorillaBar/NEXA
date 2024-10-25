const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

function daysBetween(dateString){
    var d1 = new Date(dateString);
    var d2 = new Date();
    return Math.round((d2-d1)/(1000*3600*24));
}

exports.runcmd = async(fivemexports, client, message, params) => {
    message.delete()
    if (!params[0] && !parseInt(params[0])) {
        let embed = {
            "title": "Verify",
            "description": `:x: Invalid command usage \`${process.env.PREFIX}verify [code]\``,
            "color": settingsjson.settings.botColour,
            "footer": {
                "text": ""
            },
            "timestamp": new Date()
        }
        message.channel.send({ embed }).then(msg => {
            msg.delete(10000)
        })
    }
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_verification` WHERE code = ?", [params[0]], (code) => {
        if (code.length > 0) {
           if (code[0].discord_id === null ){
            fivemexports.ghmattimysql.execute("UPDATE `nexa_verification` SET discord_id = ?, verified = 1 WHERE code = ?", [message.author.id, params[0]], async (result) => {
                if (result) {
                    let embed = {
                        "title": "Verify",
                        "description": `:white_check_mark: Great you're verified, head back in game and press Enter nexa.`,
                        "color": settingsjson.settings.botColour,
                        "footer": {
                            "text": ""
                        },
                        "timestamp": new Date()
                    }
                    message.channel.send({ embed }).then(msg => {
                        msg.delete(10000)
                    })
                    var botColour = settingsjson.settings.botColour;
                    if (daysBetween(message.author.createdAt) < 30) {
                        botColour = 16711680;
                    }
                    let embedLog = {
                        "title": `Verify Log`,
                        "fields": [
                            {
                                "name": "Perm ID:",
                                "value": `${code[0].user_id}`
                            },
                            {
                                "name": "Code:",
                                "value": `${params[0]}`
                            },
                            {
                                "name": "Discord:",
                                "value": `${message.author.username}#${message.author.discriminator} - ${message.author}`
                            },
                            {
                                "name": "Discord ID:",
                                "value": `${message.author.id}`
                            },
                            {
                                "name": "Created At:",
                                "value": `${message.author.createdAt}`
                            },
                            {
                                "name": "Account Age:",
                                "value": `${daysBetween(message.author.createdAt)} days`
                            }
                        ],
                        "color": settingsjson.settings.botColour,
                        "footer": {
                            "text": `nexa`,
                        },
                        "timestamp": new Date()
                    }
                    let role = message.member.guild.roles.find(r => r.name === 'Verified');
                    message.member.addRole(role);
                    const channel = client.channels.find(channel => channel.name === settingsjson.settings.verifyLogChannel)
                    channel.send({ embed: embedLog })
                }
            });
           }
           else{
            let embed = {
                "title": "Verify",
                "description": `:x: A discord account is already linked to this Perm ID, please contact Management to reverify.`,
                "color": settingsjson.settings.botColour,
                "footer": {
                    "text": ""
                },
                "timestamp": new Date()
            }
            message.channel.send({ embed }).then(msg => {
                msg.delete(10000)
            })
           }
        }
        else {
            let embed = {
                "title": "Verify",
                "description": `:x: That code was invalid make sure you have a valid code.`,
                "color": settingsjson.settings.botColour,
                "footer": {
                    "text": ""
                },
                "timestamp": new Date()
            }
            message.channel.send({ embed }).then(msg => {
                msg.delete(10000)
            })
        }
    })
}

exports.conf = {
    name: "verify",
    perm: 0,
}