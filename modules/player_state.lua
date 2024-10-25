local cfg = module("cfg/player_state")
local a = module("nexa-weapons", "cfg/weapons")
local lang = nexa.lang

baseplayers = {}

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    Debug.pbegin("playerSpawned_player_state")
    local player = source
    tnexa.getFactionGroups(source)
    local data = nexa.getUserDataTable(user_id)
    local tmpdata = nexa.getUserTmpTable(user_id)
    if first_spawn then
        TriggerClientEvent('nexa:requestAccountInfo', source)
        if user_id == 1 then
            nexa.addUserGroup(user_id, 'Founder')
            nexa.addUserGroup(user_id, 'Cinematic')
            nexa.addUserGroup(user_id, 'DJ')
        end
        if data.customization == nil then
            data.customization = cfg.default_customization
        end
        if data.invcap == nil then
            data.invcap = 30
        end
        tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
            if cb then
                local invcap = data.invcap
                if plathours > 0 and invcap <= 50 then
                    invcap = 50
                elseif plushours > 0 and invcap <= 40 then
                    invcap = 40
                else
                    invcap = 30
                end
                nexa.updateInvCap(user_id, invcap)
            end
        end)  
        if data.position == nil and cfg.spawn_enabled then
            local x = cfg.spawn_position[1] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            local y = cfg.spawn_position[2] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            local z = cfg.spawn_position[3] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            data.position = {
                x = x,
                y = y,
                z = z
            }
        end
        if data.customization ~= nil then
            nexaclient.spawnAnim(source, {data.position})
            if data.weapons ~= nil then
                nexaclient.giveWeapons(source, {data.weapons, true})
            end
            TriggerClientEvent('nexa:setUserId', source, user_id)

            if nexa.hasGroup(user_id, 'Founder') then
                nexaclient.setDev(source, {})
            end
            if nexa.hasPermission(user_id, 'cardev.menu') then
                TriggerClientEvent('nexa:setCarDev', source)
            end                
            nexaclient.setStaffLevel(source, {tnexa.getStaffLevel(user_id)})

            TriggerClientEvent('nexa:sendGarageSettings', source)
            players = nexa.getUsers({})
            for k,v in pairs(players) do
                baseplayers[v] = nexa.getUserId(v)
            end
            nexaclient.setBasePlayers(source, {baseplayers})
        else
            if data.weapons ~= nil then -- load saved weapons
                nexaclient.giveWeapons(source, {data.weapons, true})
            end

            if data.health ~= nil then
                nexaclient.setHealth(source, {data.health})
            end
        end
        SetTimeout(25000, function()
            if nexa.hasPermission(user_id, 'pov.list') then
                nexaclient.notify(source, {'~y~Reminder: You are on pov list.'})
                nexaclient.notify(source, {'~y~This is a requirement of at least 5 minute clips at all times.'})
            end
        end)

    else -- not first spawn (player died), don't load weapons, empty wallet, empty inventory
        nexa.clearInventory(user_id) 
        nexa.setMoney(user_id, 0)
        TriggerClientEvent('nexa:toggleHandcuffs', player, false)

        if cfg.spawn_enabled then -- respawn (CREATED SPAWN_DEATH)
            local x = cfg.spawn_death[1] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            local y = cfg.spawn_death[2] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            local z = cfg.spawn_death[3] + math.random() * cfg.spawn_radius * 2 - cfg.spawn_radius
            data.position = {
                x = x,
                y = y,
                z = z
            }
            nexaclient.teleport(source, {x, y, z})
        end
    end
    Debug.pend()
end)

function tnexa.updateWeapons(weapons)
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        local data = nexa.getUserDataTable(user_id)
        if data ~= nil then
            data.weapons = weapons
        end
    end
end

function tnexa.UpdatePlayTime()
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        local data = nexa.getUserDataTable(user_id)
        if data ~= nil then
            if data.PlayerTime ~= nil then
                local newPlaytime = tonumber(data.PlayerTime) + 1
                data.PlayerTime = newPlaytime
            else
                data.PlayerTime = 1
            end
        end
        tnexa.addStat(user_id, "playtime", 1)
    end
end

function nexa.updateInvCap(user_id, invcap)
    if user_id ~= nil then
        local data = nexa.getUserDataTable(user_id)
        if data ~= nil then
            if data.invcap ~= nil then
                data.invcap = invcap
            else
                data.invcap = 30
            end
        end
    end
end

function tnexa.setBucket(source, bucket)
    local source = source
    local user_id = nexa.getUserId(source)
    SetPlayerRoutingBucket(source, bucket)
    TriggerClientEvent('nexa:setBucket', source, bucket)
end

function tnexa.getPlaytime(user_id)
    local data = nexa.getUserDataTable(user_id)
    local playtime = data.PlayerTime or 0
    local PlayerTimeInHours = playtime/60
    if PlayerTimeInHours < 1 then
        PlayerTimeInHours = 0
    end
    return math.ceil(PlayerTimeInHours)
end

RegisterNetEvent('nexa:forceStoreWeapons')
AddEventHandler('nexa:forceStoreWeapons', function()
    local source = source 
    local user_id = nexa.getUserId(source)
    local data = nexa.getUserDataTable(user_id)
    Wait(3000)
    nexaclient.isStaffedOn(source, {}, function(staffedOn)
        if data ~= nil and not staffedOn then
            data.inventory = {}
        end
        tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
            if cb then
                local invcap = 30
                if plathours > 0 then
                    invcap = invcap + 20
                elseif plushours > 0 then
                    invcap = invcap + 10
                end
                if invcap == 30 then
                return
                end
                if data.invcap - 15 == invcap then
                nexa.giveInventoryItem(user_id, "offwhitebag", 1, false)
                elseif data.invcap - 20 == invcap then
                nexa.giveInventoryItem(user_id, "guccibag", 1, false)
                elseif data.invcap - 30 == invcap  then
                nexa.giveInventoryItem(user_id, "nikebag", 1, false)
                elseif data.invcap - 35 == invcap  then
                nexa.giveInventoryItem(user_id, "huntingbackpack", 1, false)
                elseif data.invcap - 40 == invcap  then
                nexa.giveInventoryItem(user_id, "greenhikingbackpack", 1, false)
                elseif data.invcap - 70 == invcap  then
                nexa.giveInventoryItem(user_id, "rebelbackpack", 1, false)
                end
                nexa.updateInvCap(user_id, invcap)
            end
        end)
    end)
end)
