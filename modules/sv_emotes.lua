RegisterNetEvent('nexa:sendSharedEmoteRequest')
AddEventHandler('nexa:sendSharedEmoteRequest', function(playersrc, emote)
    local source = source
    nexaclient.getNearestPlayers(source,{10},function(nplayers)
        if nplayers[playersrc] then
            TriggerClientEvent('nexa:sendSharedEmoteRequest', playersrc, source, emote)
        end
    end)
end)

RegisterNetEvent('nexa:receiveSharedEmoteRequest')
AddEventHandler('nexa:receiveSharedEmoteRequest', function(i, a)
    local source = source
    nexaclient.getNearestPlayers(source,{10},function(nplayers)
        if nplayers[i] then
            TriggerClientEvent('nexa:receiveSharedEmoteRequestSource', i)
            TriggerClientEvent('nexa:receiveSharedEmoteRequest', source, a)
        end
    end)
end)

local shavedPlayers = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for k,v in pairs(shavedPlayers) do
            if shavedPlayers[k] then
                if shavedPlayers[k].cooldown > 0 then
                    shavedPlayers[k].cooldown = shavedPlayers[k].cooldown - 1
                else
                    shavedPlayers[k] = nil
                end
            end
        end
    end
end)

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    SetTimeout(1000, function() 
        local source = source
        local user_id = nexa.getUserId(source)
        if first_spawn and shavedPlayers[user_id] then
            TriggerClientEvent('nexa:setAsShaved', source, (shavedPlayers[user_id].cooldown*60*1000))
        end
    end)
end)

function nexa.ShaveHead(source)
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.getNearestPlayer(source,{4},function(nplayer)
        if nplayer then
            nexaclient.isPlayerSurrenderedNoProgressBar(nplayer,{},function(surrendering)
                if surrendering then
                    nexa.tryGetInventoryItem(user_id, 'Shaver', 1)
                    TriggerClientEvent('nexa:startShavingPlayer', source, nplayer)
                    TriggerClientEvent('nexa:startBeingShaved', nplayer, source)
                    TriggerClientEvent('nexa:playDelayedShave', -1, source)
                    shavedPlayers[nexa.getUserId(nplayer)] = {
                        cooldown = 30,
                    }
                else
                    nexaclient.notify(source,{'~r~This player is not on their knees.'})
                end
            end)
        else
            nexaclient.notify(source, {"~r~No one nearby."})
        end
    end)
end

RegisterNetEvent('nexa:playNuiSound')
AddEventHandler('nexa:playNuiSound', function(sound, radius)
    local source = source
    local coords = GetEntityCoords(GetPlayerPed(source))
    TriggerClientEvent('nexa:playClientNuiSound', -1, coords, sound, radius)
end)