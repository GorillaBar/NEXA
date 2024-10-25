const Discord = require('discord.js');
const client = new Discord.Client({
    fetchAllMembers: true
});
const path = require('path')
const resourcePath = global.GetResourcePath ?
    global.GetResourcePath(global.GetCurrentResourceName()) : global.__dirname
require('dotenv').config({ path: path.join(resourcePath, './.env') })
const fs = require('fs');
const settingsjson = require(resourcePath + '/settings.js')
const { Webhook, MessageBuilder } = require('discord-webhook-node');
var statusLeaderboard = require(resourcePath + '/statusleaderboard.json');

function MathRandomised(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min) + min); //The maximum is exclusive and the minimum is inclusive
}

client.path = resourcePath
client.ip = settingsjson.settings.ip

if (process.env.TOKEN == "" || process.env.TOKEN == "TOKEN") {
    console.log(`Error! No Token Provided you forgot to edit the .env`);
    throw new Error('Whoops!')
}

client.on('ready', () => {
    console.log(`Logged in as ${client.user.tag}!`);
    console.log(`Your Prefix Is ${process.env.PREFIX}`)
    init()
});

if (settingsjson.settings.StatusEnabled) {
    let icon = "⚪"
    setInterval(() => {
        if (!client.guilds.get(settingsjson.settings.GuildID)) return console.log(`Status is enabled but not configured correctly and will not work as intended.`)
        let channelid = client.guilds.get(settingsjson.settings.GuildID).channels.find(r => r.name === settingsjson.settings.StatusChannel);
        if (!channelid) return console.log(`Status channel is not available / cannot be found.`)
        let settingsjsons = require(resourcePath + '/params.json')
        client.user.setActivity(`${GetNumPlayerIndices()}/${GetConvarInt("sv_maxclients",60)} players`, { type: 'WATCHING' });
        let onlineStaff = 0
        exports.nexa.getOnline([], function(staff) {
            onlineStaff = staff
        })
        if (icon == "⚪") {
            icon = "⚫"
        } else if (icon == "⚫") {
            icon = "⚪"
        }
        channelid.fetchMessage(settingsjsons.messageid).then(msg => {
            exports.ghmattimysql.execute("SELECT * FROM `nexa_users`", [], (users) => {
                let status = {
                    "color": settingsjson.settings.botColour,
                    "fields": [
                        {
                            "name": "Server Status",
                            "value": `✅ Online`,
                            "inline": true,
                        },
                        {
                            "name": "Average Player Ping",
                            "value": `${MathRandomised(20, 55)}ms`,
                            "inline": true,
                        },
                        {
                            "name": "Ping",
                            "value": `${MathRandomised(3, 10)}ms`,
                            "inline": true,
                        },                                  
                        {
                            "name": "💂 Staff",
                            "value": `${onlineStaff}`,
                            "inline": true,
                        },   
                        {
                            "name": "👫 Players",
                            "value": `${GetNumPlayerIndices()}/${GetConvarInt("sv_maxclients",64)}`,
                            "inline": true,
                        },  
                        {
                            "name": "<:discord:1133203211340218388> Members",
                            "value": `${msg.guild.memberCount}`,
                            "inline": true,
                        },                     
                        {
                            "name": "How do I direct connect?",
                            "value": '``F8 -> connect nexa.cc``',
                        }
                    ],
                    "footer": {
                        "text": `${icon} nexa`,
                    },
                    "author": {
                        "name": "nexa Server #1 Status",
                        "icon_url": settingsjson.settings.imageURL,
                    },
                    "timestamp": new Date()
                }
                msg.edit({ embed: status })
            });
        }).catch(err => {
            channelid.send('nexa Status Starting..').then(id => {
                settingsjsons.messageid = id.id
                fs.writeFile(`${resourcePath}/params.json`, JSON.stringify(settingsjsons), function(err) {});
                return
            })
        })
    }, 15000);
}


client.commands = new Discord.Collection();

const init = async() => {
    fs.readdir(resourcePath + '/commands/', (err, files) => {
        if (err) console.error(err);
        console.log(`Loading a total of ${files.length} commands.`);
        files.forEach(f => {
            let command = require(`${resourcePath}/commands/${f}`);
            client.commands.set(command.conf.name, command);
        });
        if (!statusLeaderboard['leaderboard']) {
            statusLeaderboard['leaderboard'] = {}
        }
        else {
            statusLeaderboard['leaderboard'] = statusLeaderboard['leaderboard']
        }
    });
}

setInterval(function(){
    promotionDetection();
}, 60*1000);

function promotionDetection(){
  client.users.forEach(user =>{ //iterate over each user
    if(user.presence.status == "online" || user.presence.status == 'dnd' || user.presence.status == 'idle' && !user.bot){ //check if user is online and is not a bot
        if(!statusLeaderboard['leaderboard'][user.id]){ // if user hasn't  created a profile before
            var userProfile = {}; // create new profile
            statusLeaderboard['leaderboard'][user.id] = userProfile; //set profile to object literal
            statusLeaderboard['leaderboard'][user.id] = 0; //set minutes to 0
        }
        if(Object.entries(user.presence.activities).length > 0 && typeof(user.presence.activities[0].state) === 'string' && user.presence.activities[0].state.includes('discord.gg/nexa') ){ //check if they have a status
            statusLeaderboard['leaderboard'][user.id] += 1;
            fs.writeFileSync(`${resourcePath}/statusleaderboard.json`, JSON.stringify(statusLeaderboard), function(err) {});
        }
    }
  })
}

client.getPerms = function(msg) {

    let settings = settingsjson.settings
    let lvl1 = msg.guild.roles.find(r => r.name === settings.Level1Perm);
    let lvl2 = msg.guild.roles.find(r => r.name === settings.Level2Perm);
    let lvl3 = msg.guild.roles.find(r => r.name === settings.Level3Perm);
    if (!lvl1 || !lvl2 || !lvl3) {
        console.log(`Your permissions are not setup correctly and the bot will not function as intended.\nStatus: Please check permission levels are setup correctly.`)
    }

    // hot fix for Discord role caching 
    const guild = client.guilds.get(msg.guild.id);
    if (guild.members.has(msg.author.id)) {
        guild.members.delete(msg.author.id);
    }
    const member = guild.members.get(msg.author.id);
    // hot fix for Discord role caching 

    let level = 0;
    if (msg.member.roles.has(lvl3.id)) {
        level = 3;
    } else if (msg.member.roles.has(lvl2.id)) {
        level = 2;
    } else if (msg.member.roles.has(lvl1.id)) {
        level = 1;
    }
    return level
}

client.on('message', (message) => {
    if (!message.author.bot){
        if (message.channel.name.includes('verify')){
            if (!message.content.includes(`${process.env.PREFIX}verify `)){
                message.delete()
                return
            }
        }
    }
    let client = message.client;
    if (message.author.bot) return;
    if (!message.content.startsWith(process.env.PREFIX)) return;
    let command = message.content.split(' ')[0].slice(process.env.PREFIX.length).toLowerCase();
    let params = message.content.split(' ').slice(1);
    let cmd;
    let permissions = 0
    if (message.guild.id === settingsjson.settings.GuildID) {
        permissions = client.getPerms(message)
    }
    if (client.commands.has(command)) {
        cmd = client.commands.get(command);
    }
    if (cmd) {
        if (!message.channel.name.includes('verify') && cmd.conf.name === 'verify'){
            message.delete()
            message.reply('Please use #verify for this command.').then(msg => {
                msg.delete(5000)
            })
            return
        }else if (!message.channel.name.includes('bot') && !message.channel.name.includes('verify') && cmd.conf.name != 'embed') {
            message.delete()
            message.reply('Please use bot commands for this command.').then(msg => {
                msg.delete(5000)
            })
        }
        else {
            if (permissions < cmd.conf.perm) return;
            try {
                cmd.runcmd(exports, client, message, params, permissions);
                if (cmd.conf.perm > 0 && params) { // being above 0 means won't log commands meant for anyone that isn't staff
                    params = params.join('\n ');
                    if (params != '') {
                        let embed = {
                            "title": `Bot Command Log`,
                            "fields": [
                                {
                                    "name": "Command Used:",
                                    "value": `${cmd.conf.name}`
                                },
                                {
                                    "name": "Parameters:",
                                    "value": `${params}`
                                },
                                {
                                    "name": "Link:",
                                    "value": `https://discord.com/channels/${message.guild.id}/${message.channel.id}/${message.id}`
                                },
                                {
                                    "name": "Admin:",
                                    "value": `${message.author.username} - <@${message.author.id}>`
                                },
                            ],
                            "color": settingsjson.settings.botColour,
                            "footer": {
                                "text": `nexa`,
                            },
                            "timestamp": new Date()
                        }
                        const channel = client.channels.find(channel => channel.name === settingsjson.settings.botLogChannel)
                        channel.send({embed})
                    }
                }
            } catch (err) {
                let embed = {
                    "title": "Error Occured!",
                    "description": "\nAn error occured. Contact <@609044650019258407> about the issue:\n\n```" + err.message + "\n```",
                    "color": 13632027
                }
                message.channel.send({ embed })
            }
        }
    }
});

client.on("guildMemberAdd", function (member) {
    if (member.guild.id === settingsjson.settings.GuildID){
        try {
            exports.ghmattimysql.execute("SELECT * FROM `nexa_verification` WHERE discord_id = ? AND verified = 1", [member.id], (result) => {
                if (result.length > 0){
                    let role = member.guild.roles.find(r => r.name === 'Verified');
                    member.addRole(role);
                }
            });
        
        } catch (error) {}
    }
});

exports('dmUser', (source, args) => {
    let discordid = args[0].trim()
    let verifycode = args[1]
    let permid = args[2]
    let discord_guild = client.guilds.get(settingsjson.settings.GuildID);
    let discord_member = discord_guild.members.get(discordid);
    try {
        let embed = {
            "title": `Discord Account Link Request`,
            "description": `User ID ${permid} has requested to link this Discord account.\n\nThe code to link is **${verifycode}**\nThis code will expire in 5 minutes.\n\nIf you have not requested this then you can safely ignore the message. Do **NOT** share this message or code with anyone else.`,
            "color": settingsjson.settings.botColour,
            "thumbnail": {
                "url": settingsjson.settings.imageURL,
            },
        }
        discord_member.send({embed})
    } catch (error) {}
});

exports('verifyDiscord', (source, args) => {
    let oldDiscord = args[0].trim()
    let newDiscord = args[1].trim()
    let discord_guild = client.guilds.get(settingsjson.settings.GuildID);
    let oldDiscord_member = discord_guild.members.get(oldDiscord);
    let newDiscord_member = discord_guild.members.get(newDiscord);
    let role = discord_guild.roles.find(r => r.name === 'Verified');
    if (oldDiscord_member.roles.has(role.id)){
        oldDiscord_member.removeRole(role);
    }
    if (!newDiscord_member.roles.has(role.id)){
        newDiscord_member.addRole(role);
    }
});

// Handles github webhooks
const express = require('express');
const bodyParser = require('body-parser');
const app = express();

app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const devUpdatesWebhook = new Webhook(settingsjson.settings.devUpdatesWebhook);

app.post('/receive_github', (req, res) => {
    const embed = new MessageBuilder()
    if (req.body.commits.length > 1) {
        embed.setTitle(`[${req.body.repository.name}:${req.body.ref.split('/')[2]}] ${req.body.commits.length} new commits`)
    } else {
        embed.setTitle(`[${req.body.repository.name}:${req.body.ref.split('/')[2]}] 1 new commit`)
    }
    embed.setAuthor(`${req.body.sender.login}`, `${req.body.sender.avatar_url}`, `${req.body.sender.html_url}`)
    embed.setURL(`${req.body.compare}`)
    embed.setColor('#000001')
    embed.setTimestamp();
    embed.setFooter(`UK's #1 Battle Royale Server`, `${req.body.repository.owner.avatar_url}`)
    let description = ''
    for (let i in req.body.commits) {
        if (req.body.commits[i].message.includes("Merge")) {
            continue;
        } else {
            if (req.body.commits[i].message.includes("(")) {
                description += '[`'+req.body.commits[i].id.substring(0, 7)+'`]('+req.body.commits[i].url+') '+req.body.commits[i].message+'\n'
            }
        }
    }
    if (description != '') {
        embed.setDescription(description)
        devUpdatesWebhook.send(embed);
    }
});

app.listen(settingsjson.settings.server_port, function () {});

client.login(process.env.TOKEN)
