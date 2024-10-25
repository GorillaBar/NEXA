local f = module("nexa-weapons", "cfg/weapons")
f=f.weapons

local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
local decorName = ''
for i = 1, 20 do
    local randomString = math.random(#charset)
    decorName = decorName .. string.sub(charset, randomString, randomString)
end
AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        nexaclient.setZy(source, {decorName})
    end
end)


local gettingVideo = false

local actypes = {
    {type = 1, desc = 'Noclip'},
    {type = 2, desc = 'Spawning of Weapon(s)'},
    {type = 3, desc = 'Explosion Event'},
    {type = 4, desc = 'Blacklisted Event'},
    {type = 5, desc = 'Removal of Weapon(s)'},
    {type = 6, desc = 'Semi Godmode'},
    {type = 7, desc = 'Mod Menu'},
    {type = 8, desc = 'Misc Modifiers'},
    {type = 9, desc = 'Armour Modifier'},
    {type = 10, desc = 'Health Modifier'},
    {type = 11, desc = 'Server Trigger'},
    {type = 12, desc = 'Vehicle Modifications'},
    {type = 13, desc = 'Night Vision'},
    {type = 14, desc = 'Model Dimensions'},
    {type = 15, desc = 'Godmoding'},
    {type = 16, desc = 'Failed Keep Alive (screenshot-basic)'},
    {type = 17, desc = 'Spawned Ammo'},
    {type = 18, desc = 'Infinite Combat Roll'},
    {type = 19, desc = 'Velocity Limit'},
    {type = 20, desc = 'Vehicle Stats'},
    {type = 21, desc = 'Spectator Mode'},
    {type = 22, desc = 'NUI Dev Tools'},
    {type = 23, desc = 'Resource Stopping'},
    {type = 24, desc = 'Freecam'},
    {type = 25, desc = 'Player Invisible'},
    {type = 26, desc = 'Triggerbot Log'},
}

RegisterNetEvent('nexa:AnticheatBan')
AddEventHandler("nexa:AnticheatBan", function(actype, extra)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local extraText = ""
    extraText = extra
    if actype == 1 then
        if not table.includes(carrying, source) then extraText = (extra and 'Player is in vehicle' or 'Player is not in vehicle') else return end
    elseif actype == 8 then
        if f[extra] ~= nil then
            if f[extra].class == "Melee" then return end
        end
    elseif actype == 17 then
        if f[extra].class == "Melee" or f[extra].policeWeapon then return end
    end
    print("nexa:acBan", user_id, actype, name, source, extraText)
    TriggerEvent("nexa:acBan", user_id, actype, name, source, extraText)
end)

RegisterNetEvent('nexa:AnticheatLog')
AddEventHandler("nexa:AnticheatLog", function(bantype, extra)
    local source = source
    local user_id = nexa.getUserId(source)
    if not user_id then return end
    local name = tnexa.getDiscordName(source)
    if extra == nil then extra = 'None' end
    Wait(500)
    for k,v in pairs(actypes) do
        if bantype == v.type then
            reason = 'Type #'..bantype
            desc = v.desc
        end
    end
    nexaclient.takeClientScreenshotAndUploadAnticheat(source, {tnexa.getWebhook('anticheat')})
    tnexa.sendWebhook('anticheat', 'Anticheat Log', "> Players Name: **"..name.."**\n> Players Perm ID: **"..user_id.."**\n> Reason: **"..reason.."**\n> Type Meaning: **"..desc.."**\n> Extra Info: "..extra)
end)

--0, 4, 25,
local BlockedExplosions = {1, 2, 5, 32, 33, 35, 35, 36, 37, 38, 45}
AddEventHandler('explosionEvent', function(source, ev)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    for k, v in ipairs(BlockedExplosions) do 
        if ev.explosionType == v then
            ev.damagescale = 0.0
            CancelEvent()
            Wait(500)
            TriggerEvent("nexa:acBan", user_id, 3, name, source, 'Explosion Type: '..ev.explosionType)
        end
    end
end)

AddEventHandler("giveWeaponEvent", function(source)
    CancelEvent()
    local source = source
    local user_id = nexa.getUserId(source)
	local name = tnexa.getDiscordName(source)
    Wait(500)
    TriggerEvent("nexa:acBan", user_id, 5, name, source)
end)

AddEventHandler("removeAllWeaponsEvent", function(source)
    CancelEvent()
    local source = source
    local user_id = nexa.getUserId(source)
	local name = tnexa.getDiscordName(source)
    Wait(500)
    TriggerEvent("nexa:acBan", user_id, 5, name, source)
end)

RegisterServerEvent("nexa:sendVelocityLimit")
AddEventHandler("nexa:sendVelocityLimit", function(aF, a6)
    local source = source
    local user_id = nexa.getUserId(source)
	local name = tnexa.getDiscordName(source)
    Wait(500)
    if not nexa.hasPermission(user_id, 'admin.tp2player') then
        local a = #(vector3(3061.135,-4719.28,15.26162) - aF)
        local b = #(vector3(3061.135,-4719.28,15.26162) - a6)
        if a < 100 or b < 100 then
            return
        end
        nexaclient.takeClientScreenshotAndUploadAnticheat(source, {tnexa.getWebhook('anticheat')})
        tnexa.sendWebhook('anticheat', 'Anticheat Log', "> Players Name: **"..name.."**\n> Players Perm ID: **"..user_id.."**\n> Reason: **Type #19**\n> Type Meaning: **Velocity Limit**\n> Extra: Prev Coords:"..aF.."\nNew Coords:"..a6)
    end
end)

RegisterServerEvent("nexa:sendVehicleStats")
AddEventHandler("nexa:sendVehicleStats", function(b8, aL, b9, aM, ba, aN, bb, aO, aY, bc)
    local source = source
    local user_id = nexa.getUserId(source)
	local name = tnexa.getDiscordName(source)
    Wait(500)
    if b9 > aL or ba > aN or bb > aO then
        TriggerEvent("nexa:acBan", user_id, 20, name, source, 'Body Health '..aL..' ➝ '..b8..
        '\n> Engine Health '..aM..' ➝ '..b9..
        '\n> Petrol Tank Health '..aN..' ➝ '..ba..
        '\n> Entity Health '..aO..' ➝ '..bb..
        '\n> Passengers '..json.encode(aY)..
        '\n> Spawncode '..bc)
    end
end)

RegisterServerEvent("nexa:checkCachedId")
AddEventHandler("nexa:checkCachedId", function(cachedID, setID)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    if setID ~= user_id then
        TriggerEvent("nexa:acBan", user_id, 11, name, source, 'Attempted to trigger ID cache check with ID: '..setID)
    end
    nexa.isBanned(cachedID, function(banned)
        if banned then
            nexa.setBanned(user_id,true,"perm",'Ban evading is not permitted.',"nexa")
            tnexa.sendWebhook('ban-evaders', 'nexa Ban Evade Logs', "> Player Name: **"..name.."**\n> Player Current Perm ID: **"..user_id.."**\n> Player Banned PermID: **"..cachedID.."**\n> Info: **User had a cached banned ID**")
            DropPlayer(source, "\n[nexa] Permanent Ban\nYour ID: "..user_id.."\nReason: Ban evading is not permitted.\nAppeal @ discord.gg/nexa") 
        else
            if cachedID ~= user_id and cachedID ~= 0 then
                tnexa.sendWebhook('multi-accounting', 'nexa Multi Account Logs', "> Player Name: **"..name.."**\n> Player Current Perm ID: **"..user_id.."**\n> Player Cached PermID: **"..cachedID.."**\n> Info: **Cached ID does not match Perm ID**")
            end
       end
    end)
end)

AddEventHandler("nexa:acBan",function(user_id, bantype, name, player, extra)
    local desc = ''
    local reason = ''
    if extra == nil then extra = 'None' end
    if user_id == 1 then 
        nexaclient.notify(player, {'~r~Ban Type: ~w~'..bantype..'\n~r~Name: ~w~'..name..'\n~r~Extra: ~w~'..extra})
        return 
    end
    if not gettingVideo then
        for k,v in pairs(actypes) do
            if bantype == v.type then
                reason = 'Type #'..bantype
                desc = v.desc
            end
        end
        nexaclient.takeClientVideoAndUploadAnticheat(player, {tnexa.getWebhook('anticheat')}, function(videoObtained)
            if videoObtained then
                tnexa.sendWebhook('anticheat', 'Anticheat Ban', "> Players Name: **"..name.."**\n> Players Perm ID: **"..user_id.."**\n> Reason: **"..reason.."**\n> Type Meaning: **"..desc.."**\n> Extra Info: "..extra)
                TriggerClientEvent("chatMessage", -1, "^7[nexa]", {180, 0, 0}, name .. " ^7 Was Banned | Reason: Cheating ^3"..reason, "alert")
                nexa.banConsole(user_id,"perm","Cheating "..reason)
                exports['ghmattimysql']:execute("INSERT INTO `nexa_anticheat` (`user_id`, `username`, `reason`, `extra`) VALUES (@user_id, @username, @reason, @extra);", {user_id = user_id, username = name, reason = reason, extra = extra}, function() end) 
            end
        end)
    end
end)

Citizen.CreateThread(function()
    Wait(2500)
    exports['ghmattimysql']:execute([[
    CREATE TABLE IF NOT EXISTS `nexa_anticheat` (
    `ban_id` int(11) NOT NULL AUTO_INCREMENT,
    `user_id` int(11) NOT NULL,
    `username` VARCHAR(100) NOT NULL,
    `reason` VARCHAR(100) NOT NULL,
    `extra` VARCHAR(100) NOT NULL,
    PRIMARY KEY (`ban_id`)
    );]])
end)