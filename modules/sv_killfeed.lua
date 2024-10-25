local f = module("nexa-weapons", "cfg/weapons")
local illegalWeapons = f.illegalNativeWeaponsHashToModels
local nativeWeapons = f.nativeWeaponModelsToNames
local weapons = f.weapons

local function getWeaponClass(weapon)
    for k,v in pairs(weapons) do
        if weapon == 'Fists' then
            return 'Fist'
        elseif weapon == 'Fire' then
            return 'Fire'
        elseif weapon == 'Explosion' then
            return 'Explode'
        elseif weapon == 'Mosin Nagant' then
            return 'Heavy'
        end
        if v.name == weapon then
            return v.class
        end
    end
    return "Unknown"
end

local function getWeaponName(hash)
    for k,v in pairs(weapons) do
        if v.hash == hash then
            return v.name
        end
    end
    return "Unknown (Hash: "..hash..")"
end

local function triggerbotCheck(weaponhash, killer, source)
    local c = getWeaponClass(weaponhash)
    if c ~= 'Fist' and c ~= 'Fire' and c ~= 'Explode' and c ~= 'Melee' and not nexa.isEmergencyService(nexa.getUserId(killer)) and killer ~= source then
        return true
    end
end


RegisterNetEvent('nexa:onPlayerKilled')
AddEventHandler('nexa:onPlayerKilled', function(killtype, killer, weaponhash, suicide, distance)
    local source = source
    local user_id = nexa.getUserId(source)
    local killergroup = 'none'
    local killedgroup = 'none'
    if weaponhash == nil then weaponhash = 'Undefined' end
    if distance ~= nil then
        distance = math.floor(distance) 
    else
        distance = 0
    end
    if killtype == 'killed' then
        tnexa.addStat(user_id, "deaths", 1)
        if killer ~= nil then
            local killerid = nexa.getUserId(killer)
            tnexa.addStat(killerid, "kills", 1)
            tnexa.sendWebhook('kills', 'nexa Kill Logs', "> Killer Name: **"..tnexa.getDiscordName(killer).."**\n> Killer ID: **"..killerid.."**\n> Victim Name: **"..tnexa.getDiscordName(source).."**\n> Victim ID: **"..nexa.getUserId(source).."**\n> Weapon Used: **"..weaponhash.."**\n> Distance: **"..distance.."m**\n> Kill Type: **"..killtype.."**")
            TriggerClientEvent('nexa:newKillFeed', -1, tnexa.getDiscordName(killer), tnexa.getDiscordName(source), getWeaponClass(weaponhash), suicide, distance, killedgroup, killergroup)
            nexaclient.takeClientVideoAndUploadKills(killer, {tnexa.getWebhook('kill-vids')})
            if triggerbotCheck(weaponhash, killer, source) then
                nexaclient.getPlayerCombatTimer(killer, {}, function(currentTimer, isInCombat)
                    if currentTimer < 58 or not isInCombat and not killerid == 1 then
                        tnexa.sendWebhook('anticheat', 'Anticheat Log', "> Players Name: **"..tnexa.getDiscordName(killer).."**\n> Players Perm ID: **"..killerid.."**\n> Reason: **Type #26**\n> Type Meaning: **Triggerbot**\n> Extra Info: None")
                    end
                end)
            end
        else
            TriggerClientEvent('nexa:newKillFeed', -1, tnexa.getDiscordName(source), tnexa.getDiscordName(source), 'suicide', suicide, distance, killedgroup, killergroup)
        end
    elseif killtype == 'finished off' and killer ~= nil then
        tnexa.sendWebhook('kills', 'nexa Finish Logs', "> Killer Name: **"..tnexa.getDiscordName(killer).."**\n> Killer ID: **"..nexa.getUserId(killer).."**\n> Victim Name: **"..tnexa.getDiscordName(source).."**\n> Victim ID: **"..nexa.getUserId(source).."**\n> Weapon Used: **"..weaponhash.."**\n> Distance: **"..distance.."m**\n> Kill Type: **"..killtype.."**")
    end
    TriggerClientEvent('nexa:deathSound', -1, GetEntityCoords(GetPlayerPed(source)))
end)

AddEventHandler('weaponDamageEvent', function(sender, ev)
    local user_id = nexa.getUserId(sender)
    local name = tnexa.getDiscordName(sender)
	if ev.weaponDamage ~= 0 then
        if ev.weaponType == 3218215474 or ev.weaponType == 911657153 then
            TriggerEvent("nexa:acBan", user_id, 8, name, sender, ev.weaponType)
        end
        tnexa.sendWebhook('damage', 'nexa Damage Logs', "> Player Name: **"..name.."**\n> Player Temp ID: **"..sender.."**\n> Player Perm ID: **"..user_id.."**\n> Damage: **"..ev.weaponDamage.."**\n> Weapon Hash: **"..getWeaponName(ev.weaponType).."**")
	end
end)

function tnexa.killProcessed()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.sendWebhook('kill-vids', 'nexa Kill Video Logs', "> Players Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**")
end
