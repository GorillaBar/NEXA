RegisterCommand('craftbmx', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        TriggerClientEvent("nexa:spawnNitroBMX", source)
    else
        if tnexa.checkForRole(user_id, '1291080110065188866') then
            TriggerClientEvent("nexa:spawnNitroBMX", source)
        else
            nexaclient.notify(source, {'~r~You need to be nitro boosting the nexa discord (discord.gg/nexa) in order to unlock this feature.'})
        end
    end
end)

RegisterCommand('craftmoped', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.isPlatClub(source, {}, function(isPlatClub)
        if isPlatClub then
            TriggerClientEvent("nexa:spawnMoped", source)
        end
    end)
end)