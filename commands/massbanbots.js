const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
const settingsjson = require(resourcePath + '/settings.js')

exports.runcmd = (fivemexports, client, message, params) => {
    const discord_guild = client.guilds.get(settingsjson.settings.GuildID);
    if (!params[0] || !params[1]) {
        return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'massban [reason] [list-of-discord-ids]')
    }
    let banReason = params[0];
    let users = params[1].split('\n');
    let bannedUsers = 0
    for (let i = 0; i < users.length; i++) {
        if (!parseInt(users[i])) {
            return message.reply('Invalid args! Correct term is: ' + process.env.PREFIX + 'massban [reason] [list-of-discord-ids]')
        } else {
            const member = discord_guild.members.get(users[i]);
            if (member) {
                member.ban({ reason: banReason })
                bannedUsers++
            }
        }
    }
    message.reply('Banned ' + bannedUsers + ' users. ```' + params.join('\n') + '```')
}

exports.conf = {
    name: "massban",
    perm: 3,
}