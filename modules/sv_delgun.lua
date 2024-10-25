netObjects = {}

RegisterServerEvent("nexa:spawnVehicleCallback")
AddEventHandler('nexa:spawnVehicleCallback', function(a, b)
    netObjects[b] = {source = nexa.getUserSource(a), id = a, name = tnexa.getDiscordName(nexa.getUserSource(a))}
end)

RegisterServerEvent("nexa:delGunDelete")
AddEventHandler("nexa:delGunDelete", function(object)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        TriggerClientEvent("nexa:deletePropClient", -1, object)
        if netObjects[object] then
            TriggerClientEvent("nexa:returnObjectDeleted", source, 'This object was created by ~b~'..netObjects[object].name..'~w~. Temp ID: ~b~'..netObjects[object].source..'~w~.\nPerm ID: ~b~'..netObjects[object].id..'~w~.')
        end
    end
end)