local cfg=module("cfg/cfg_respawn")


RegisterNetEvent("nexa:SendSpawnMenu")
AddEventHandler("nexa:SendSpawnMenu",function()
    local source = source
    local user_id = nexa.getUserId(source)
    local spawnTable={}
    for k,v in pairs(cfg.spawnLocations)do
        if v.permission[1] ~= nil then
            if nexa.hasPermission(nexa.getUserId(source),v.permission[1])then
                table.insert(spawnTable, k)
            end
        else
            table.insert(spawnTable, k)
        end
    end
    exports['ghmattimysql']:execute("SELECT * FROM `nexa_user_homes` WHERE user_id = @user_id", {user_id = user_id}, function(result)
        if result ~= nil then 
            for a,b in pairs(result) do
                table.insert(spawnTable, b.home)
            end
        end
        TriggerClientEvent("nexa:OpenSpawnMenu",source,spawnTable)
        nexa.clearInventory(user_id) 
        nexaclient.setPlayerCombatTimer(source, {0})
    end)
end)