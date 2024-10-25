local shotTable = {}

RegisterNetEvent("nexa:syncEntityDamage")
AddEventHandler("nexa:syncEntityDamage",function(u, v, t, s, m, n)
    local source=source
    local user_id=nexa.getUserId(source)
    local headshot = s
    local their_source = t
    if shotTable[their_source] == nil then shotTable[their_source] = {totalShots = 0, totalHeadshots = 0} end
    shotTable[their_source].totalShots = shotTable[their_source].totalShots + 1
    if headshot then
        shotTable[their_source].totalHeadshots = shotTable[their_source].totalHeadshots + 1
    end
    TriggerClientEvent('nexa:onEntityHealthChange', t, GetPlayerPed(source), u, v, s)
    nexaclient.isPlayerInRedZone(source, {}, function(victimInRedzone)
        nexaclient.isPlayerInRedZone(t, {}, function(shooterInRedzone)
            if victimInRedzone and not shooterInRedzone then
                TriggerClientEvent('nexa:chatFilterScaleform', t, 1, 'Do not shoot at players from outside a redzone!')
            elseif shooterInRedzone and not victimInRedzone then
                TriggerClientEvent('nexa:chatFilterScaleform', t, 1, 'Do not shoot at players from inside a redzone!')
            end
        end)
    end)
end)

AddEventHandler("playerDropped",function(reason)
    local user_id = baseplayers[source]
    if shotTable[source] == nil then return end
    tnexa.sendWebhook('hs-logs', "nexa HS % Logs", "> Players Perm ID: **"..user_id.."**\n> Total Shots Hit: **"..shotTable[source].totalShots.."**\n> Total Headshots: **"..shotTable[source].totalHeadshots.."**\n> Total Headshot Percentage: **"..math.floor((shotTable[source].totalHeadshots / shotTable[source].totalShots) * 100).."%**\n> *Please keep in mind that these are logs. Please investigate further into high headshot percentages.*")
    shotTable[source] = nil
end)