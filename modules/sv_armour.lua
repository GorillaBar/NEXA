RegisterNetEvent("nexa:getArmour")
AddEventHandler("nexa:getArmour",function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "police.armoury") or nexa.hasPermission(user_id, "prisonguard.onduty.permission") then
        if nexa.hasPermission(user_id, "police.maxarmour") then
            nexaclient.setArmour(source, {100, true})
        elseif nexa.hasPermission(user_id, "police.armour75") then
            nexaclient.setArmour(source, {75, true})
        elseif nexa.hasPermission(user_id, "police.armour50") then
            nexaclient.setArmour(source, {50, true})
        elseif nexa.hasPermission(user_id, "police.armour25") then
            nexaclient.setArmour(source, {25, true})
        end
        nexaclient.notify(source, {"~g~You have received your armour."})
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to use pd armour trigger')
    end
end)