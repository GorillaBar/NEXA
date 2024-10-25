const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    let publicCommands = []
    let staffCommands = []
    let managementCommands = []
    client.commands.forEach(c => {
        let command = c.conf
        if (command.perm < 1) {
            publicCommands.push(`${process.env.PREFIX}${command.name}`)
        }
        else if (command.perm > 0 && command.perm < 2) {
            staffCommands.push(`${process.env.PREFIX}${command.name}`)
        }
        else if (command.perm > 1 && command.perm < 3) {
            managementCommands.push(`${process.env.PREFIX}${command.name}`)
        }
    })
    let description = `**Public Commands:** \n${publicCommands.join('\n')}\n\n**Staff Commands:**\n${staffCommands.join('\n')}\n\n**Management Commands:**\n${managementCommands.join('\n')}`
    let embed = {
        "title": "Command Help",
        "description": description,
        "color": settingsjson.settings.botColour,
        "footer": {
            "text": ""
        },
        "timestamp": new Date()
    }
    message.channel.send({ embed })
}

exports.conf = {
    name: "help",
    perm: 0,
}