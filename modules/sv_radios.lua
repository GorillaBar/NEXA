local cfg = module("cfg/cfg_radios")
local radioChannels = {}
local gangChannels = 5

function createRadio(source)
    local source = source
    local user_id = nexa.getUserId(source)
    Wait(1000)
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            if not rows[1].gangname then return end
            local gangName = rows[1].gangname
            if radioChannels[gangName] == nil then
                gangChannels = gangChannels + 1
                radioChannels[gangName] = {
                    name = gangName,
                    players = {},
                    channel = gangChannels,
                }
            end
            if not radioChannels[gangName]['players'][source] then
                radioChannels[gangName]['players'][source] = {name = tnexa.getDiscordName(source), sortOrder = 1, permID = user_id}
                TriggerClientEvent('nexa:radiosCreateChannel', source, radioChannels[gangName].channel, radioChannels[gangName].name, radioChannels[gangName].players, true)
                TriggerClientEvent('nexa:radiosAddPlayer', -1, radioChannels[gangName].channel, source, {name = tnexa.getDiscordName(source), sortOrder = 1, permID = user_id})
            end
        end
    end)
end

function removeRadio(source)
    for a,b in pairs(radioChannels) do
        if radioChannels[a]['players'][source] then
            TriggerClientEvent('nexa:radiosDeleteChannel', source, radioChannels[a].channel)
            TriggerClientEvent('nexa:radiosRemovePlayer', -1, radioChannels[a].channel, source)
            radioChannels[a]['players'][source] = nil
        end
    end
end

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    local source = source
    if first_spawn then
        createRadio(source)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    removeRadio(source)
end)

RegisterServerEvent("nexa:radiosSetIsMuted")
AddEventHandler("nexa:radiosSetIsMuted", function(mutedState)
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            if not rows[1].gangname then return end
            local gangName = rows[1].gangname
            if radioChannels[gangName] == nil then
                return
            end
            TriggerClientEvent('nexa:radiosSetPlayerIsMuted', -1, radioChannels[gangName].channel, source, mutedState)
        end
    end)
end)