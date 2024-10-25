
exports.runcmd = (fivemexports, client, message, params) => {
    let bannedPlayers = 0
    let totalACBans = 0
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_users WHERE banned = 1 and bantime = 'perm' ", (bannedPlayersPerm) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_users WHERE banned = 1", (bannedPlayers) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM nexa_anticheat", (totalACBans) => {
    fivemexports.ghmattimysql.execute("SELECT * FROM `nexa_users` WHERE banreason LIKE '%cheating%'", (cheatingRelated) => {
    let embed = {
        "title": "Punishment Statistics",
        "description": `Currently Banned:\n - Anticheat Banned: **${totalACBans.length}** \n - Staff Banned: **${bannedPlayers.length-totalACBans.length}** \n - Total Banned: **${bannedPlayers.length}** (${bannedPlayersPerm.length} of which are permanent and ${cheatingRelated.length} are related to cheating)\n\nAdmin: <@${message.author.id}>`,        
        "color": settingsjson.settings.botColour,
        "footer": {
            "text": ""
        },
        "timestamp": new Date()
    }
    message.channel.send({ embed })
    }) }) }) })
}

exports.conf = {
    name: "punishments",
    perm: 2,
}