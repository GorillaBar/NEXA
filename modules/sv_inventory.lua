MySQL = module("modules/MySQL")

local Inventory = module("nexa-vehicles", "inventory")
local Housing = module("nexa", "cfg/cfg_housing")
local backpacks = module("nexa", "cfg/cfg_backpacks")
local InventorySpamTrack = {}
local LootBagEntities = {}
local InventoryCoolDown = {}
local a = module("nexa-weapons", "cfg/weapons")
local houseRobberies = {}
local playersInCombat = {}
local inHouse = {}

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        if not InventorySpamTrack[source] then
            InventorySpamTrack[source] = true
            local user_id = nexa.getUserId(source) 
            local data = nexa.getUserDataTable(user_id)
            if data and data.inventory then
                local FormattedInventoryData = {}
                for i,v in pairs(data.inventory) do
                    FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                end
                TriggerClientEvent('nexa:FetchPersonalInventory', source, FormattedInventoryData, nexa.computeItemsWeight(data.inventory), nexa.getInventoryMaxWeight(user_id))
                InventorySpamTrack[source] = false
           end
        end
    end
end)

RegisterNetEvent('nexa:FetchPersonalInventory')
AddEventHandler('nexa:FetchPersonalInventory', function()
    local source = source
    if not InventorySpamTrack[source] then
        InventorySpamTrack[source] = true
        local user_id = nexa.getUserId(source) 
        local data = nexa.getUserDataTable(user_id)
        if data and data.inventory then
            local FormattedInventoryData = {}
            for i,v in pairs(data.inventory) do
                FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
            end
            TriggerClientEvent('nexa:FetchPersonalInventory', source, FormattedInventoryData, nexa.computeItemsWeight(data.inventory), nexa.getInventoryMaxWeight(user_id))
            InventorySpamTrack[source] = false
        end
    end
end)


AddEventHandler('nexa:RefreshInventory', function(source)
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if data and data.inventory then
        local FormattedInventoryData = {}
        for i,v in pairs(data.inventory) do
            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
        end
        TriggerClientEvent('nexa:FetchPersonalInventory', source, FormattedInventoryData, nexa.computeItemsWeight(data.inventory), nexa.getInventoryMaxWeight(user_id))
    end
    InventoryCoolDown[source] = nil
end)

RegisterNetEvent('nexa:GiveItem')
AddEventHandler('nexa:GiveItem', function(itemId, itemLoc)
    local source = source
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if itemLoc == "Plr" then
        nexa.RunGiveTask(source, itemId)
        TriggerEvent('nexa:RefreshInventory', source)
    else
        nexaclient.notify(source, {'~r~You need to have this item on you to give it.'})
    end
end)

RegisterNetEvent('nexa:TrashItem')
AddEventHandler('nexa:TrashItem', function(itemId, itemLoc)
    local source = source
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if itemLoc == "Plr" then
        nexa.RunTrashTask(source, itemId)
        TriggerEvent('nexa:RefreshInventory', source)
    else
        nexaclient.notify(source, {'~r~You need to have this item on you to drop it.'})
    end
end)

RegisterNetEvent('nexa:FetchTrunkInventory')
AddEventHandler('nexa:FetchTrunkInventory', function(spawnCode)
    local source = source
    local user_id = nexa.getUserId(source)
    if InventoryCoolDown[source] then return nexaclient.notify(source, {'~r~Please wait before moving more items.'}) end
    local carformat = "chest:u1veh_" .. spawnCode .. '|' .. user_id
    nexa.getSData(carformat, function(cdata)
        cdata = json.decode(cdata) or {}
        local FormattedInventoryData = {}
        for i, v in pairs(cdata) do
            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
        end
        local maxVehKg = Inventory.vehicle_chest_weights[spawnCode] or Inventory.default_vehicle_chest_weight
        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
        TriggerEvent('nexa:RefreshInventory', source)
    end)
end)

RegisterNetEvent('nexa:FetchHouseInventory')
AddEventHandler('nexa:FetchHouseInventory', function(nameHouse)
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.getUserByAddress(nameHouse, 1, function(huser_id)
        if huser_id == user_id or houseRobberies[nameHouse] then
            inHouse[user_id] = {name = nameHouse, id = huser_id}
            local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
            nexa.getSData(homeformat, function(cdata)
                cdata = json.decode(cdata) or {}
                local FormattedInventoryData = {}
                for i, v in pairs(cdata) do
                    FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                end
                local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
            end)
        else
            nexaclient.notify(source,{"~r~You do not own this house!"})
        end
    end)
end)

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else copy = orig end
    return copy
end

RegisterNetEvent('nexa:EquipAll')
AddEventHandler('nexa:EquipAll', function()
    local source = source
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if data.inventory == nil then return end
    local inventory = deepcopy(data.inventory)
    local weapons = {}
    local ammo = {}
    for item, _ in pairs(inventory) do
        if string.find(item, "wbody|") then
            table.insert(weapons, item)
        elseif nexaAmmoTypes[item] then
            table.insert(ammo, item)
        end
    end
    for k,v in pairs(weapons) do
        nexa.RunInventoryTask(source, v)
        Wait(350)
    end
    for k,v in pairs(ammo) do
        nexa.LoadAllTask(source, v)
        Wait(350)
    end
end)

RegisterNetEvent('nexa:UseItem')
AddEventHandler('nexa:UseItem', function(itemId, itemLoc)
    local source = source
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if itemLoc == "Plr" then
        tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
            if cb then
                local invcap = 30
                if plathours > 0 then
                    invcap = 50
                elseif plushours > 0 then
                    invcap = 40
                end
                if nexa.getInventoryMaxWeight(user_id) ~= nil then
                    if nexa.getInventoryMaxWeight(user_id) > invcap then
                        return
                    end
                end
                if backpacks.bags[itemId] then
                    for a,b in pairs(backpacks.stores) do
                        for k,v in pairs(backpacks.stores[a]) do
                            if k == backpacks.bags[itemId] then
                                if nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                                    TriggerClientEvent('nexa:boughtBackpack', source, v[1], v[2], v[3], v[4], v[5], backpacks.bags[itemId])
                                    nexa.updateInvCap(user_id, invcap+v[5])
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    return
                                end
                            end
                        end
                    end
                end
                if itemId == "Shaver" and nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                    nexa.ShaveHead(source)
                elseif itemId == "handcuffkeys" and nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                    nexa.handcuffKeys(source)
                elseif itemId == "armour_plate" then
                    if nexa.hasGroup(user_id, 'AdvancedRebel') and nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                        TriggerClientEvent("nexa:playArmourApplyAnim", source)
                        Wait(10000)
                        nexaclient.setArmour(source, {100})
                    else
                        return nexaclient.notify(source, {'~r~You need to have Advanced Rebel License to use this item.'})
                    end
                end
                TriggerEvent('nexa:RefreshInventory', source)
            end
        end)  
    end
    if itemLoc == "Plr" then
        nexa.RunInventoryTask(source, itemId)
        TriggerEvent('nexa:RefreshInventory', source)
    else
        nexaclient.notify(source, {'~r~You need to have this item on you to use it.'})
    end
end)

RegisterNetEvent('nexa:UseAllItem')
AddEventHandler('nexa:UseAllItem', function(itemId, itemLoc)
    local source = source
    local user_id = nexa.getUserId(source) 
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if itemLoc == "Plr" then
        nexa.LoadAllTask(source, itemId)
        TriggerEvent('nexa:RefreshInventory', source)
    else
        nexaclient.notify(source, {'~r~You need to have this item on you to use it.'})
    end
end)


RegisterNetEvent('nexa:MoveItem')
AddEventHandler('nexa:MoveItem', function(inventoryType, itemId, inventoryInfo, Lootbag)
    local source = source
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if InventoryCoolDown[source] then return nexaclient.notify(source, {'~r~Please wait before moving more items.'}) end
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if data and data.inventory then
        if inventoryInfo == nil then return end
        if inventoryType == "CarBoot" then
            InventoryCoolDown[source] = true
            local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
            nexa.getSData(carformat, function(cdata)
                cdata = json.decode(cdata) or {}
                if cdata[itemId] and cdata[itemId].amount >= 1 then
                    local weightCalculation = nexa.getInventoryWeight(user_id)+nexa.getItemWeight(itemId)
                    if weightCalculation == nil then return end
                    if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                        if cdata[itemId].amount > 1 then
                            cdata[itemId].amount = cdata[itemId].amount - 1
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        else 
                            cdata[itemId] = nil
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        end 
                        local FormattedInventoryData = {}
                        for i, v in pairs(cdata) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                        TriggerEvent('nexa:RefreshInventory', source)
                        nexa.setSData(carformat, json.encode(cdata))
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                end
                InventoryCoolDown[source] = nil
            end)
        elseif inventoryType == "LootBag" then  
            if itemId ~= nil then  
                InventoryCoolDown[source] = true
                if not LootBagEntities[inventoryInfo] then return end
                if LootBagEntities[inventoryInfo].Items[itemId] then 
                    local weightCalculation = nexa.getInventoryWeight(user_id)+nexa.getItemWeight(itemId)
                    if weightCalculation == nil then return end
                    if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                        if LootBagEntities[inventoryInfo].Items[itemId] and LootBagEntities[inventoryInfo].Items[itemId].amount > 1 then
                            LootBagEntities[inventoryInfo].Items[itemId].amount = LootBagEntities[inventoryInfo].Items[itemId].amount - 1 
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        else 
                            LootBagEntities[inventoryInfo].Items[itemId] = nil
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        end
                        local FormattedInventoryData = {}
                        for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = 200
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(LootBagEntities[inventoryInfo].Items), maxVehKg)                
                        TriggerEvent('nexa:RefreshInventory', source)
                        if not next(LootBagEntities[inventoryInfo].Items) then
                            CloseInv(source)
                        end
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                end
                InventoryCoolDown[source] = nil
            end
        elseif inventoryType == "Housing" then
            InventoryCoolDown[source] = true
            local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
            nexa.getSData(homeformat, function(cdata)
                cdata = json.decode(cdata) or {}
                if cdata[itemId] and cdata[itemId].amount >= 1 then
                    local weightCalculation = nexa.getInventoryWeight(user_id)+nexa.getItemWeight(itemId)
                    if weightCalculation == nil then return end
                    if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                        if cdata[itemId].amount > 1 then
                            cdata[itemId].amount = cdata[itemId].amount - 1
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        else 
                            cdata[itemId] = nil
                            nexa.giveInventoryItem(user_id, itemId, 1, true)
                        end 
                        local FormattedInventoryData = {}
                        for i, v in pairs(cdata) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                        TriggerEvent('nexa:RefreshInventory', source)
                        nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                end
            end)
            InventoryCoolDown[source] = nil
        elseif inventoryType == "Crate" then
            InventoryCoolDown[source] = true
            if currentCrate.crateLoot[itemId] and currentCrate.crateLoot[itemId].amount >= 1 then
                local weightCalculation = nexa.getInventoryWeight(user_id)+nexa.getItemWeight(itemId)
                if weightCalculation == nil then return end
                if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                    if currentCrate.crateLoot[itemId].amount > 1 then
                        currentCrate.crateLoot[itemId].amount = currentCrate.crateLoot[itemId].amount - 1
                        nexa.giveInventoryItem(user_id, itemId, 1, true)
                    else
                        currentCrate.crateLoot[itemId] = nil
                        nexa.giveInventoryItem(user_id, itemId, 1, true)
                    end
                    local FormattedInventoryData = {}
                    for i, v in pairs(currentCrate.crateLoot) do
                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                    end
                    local maxVehKg = 200
                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(currentCrate.crateLoot), maxVehKg)
                    TriggerEvent('nexa:RefreshInventory', source)
                    if not next(currentCrate.crateLoot) then
                        TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "Crate drop has been looted.", "alert")
                        TriggerClientEvent("nexa:removeLootcrate", -1, currentCrate.crateID)
                        currentCrate = {}
                    end
                else
                    nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                end
            end
            InventoryCoolDown[source] = nil
        elseif inventoryType == "Plr" then
            if not Lootbag then
                if data.inventory[itemId] then
                    if inventoryInfo == "home" then --start of housing intergration (moveitem)
                        local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
                        nexa.getSData(homeformat, function(cdata)
                            cdata = json.decode(cdata) or {}
                            if data.inventory[itemId] and data.inventory[itemId].amount >= 1 then
                                local weightCalculation = nexa.computeItemsWeight(cdata)+nexa.getItemWeight(itemId)
                                if weightCalculation == nil then return end
                                local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                                if weightCalculation <= maxVehKg then
                                    if nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                                        if cdata[itemId] then
                                        cdata[itemId].amount = cdata[itemId].amount + 1
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = 1
                                        end
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                                else 
                                    nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                                end
                            end
                        end)
                    else
                        InventoryCoolDown[source] = true
                        local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
                        nexa.getSData(carformat, function(cdata)
                            cdata = json.decode(cdata) or {}
                            if data.inventory[itemId] and data.inventory[itemId].amount >= 1 then
                                local weightCalculation = nexa.computeItemsWeight(cdata)+nexa.getItemWeight(itemId)
                                if weightCalculation == nil then return end
                                local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                                if weightCalculation <= maxVehKg then
                                    if nexa.tryGetInventoryItem(user_id, itemId, 1, true) then
                                        if cdata[itemId] then
                                        cdata[itemId].amount = cdata[itemId].amount + 1
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = 1
                                        end
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData(carformat, json.encode(cdata))
                                else 
                                    nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                                end
                            end
                            InventoryCoolDown[source] = nil
                        end)
                    end
                else
                    InventoryCoolDown[source] = nil
                end
            end
        end
    else 
        InventoryCoolDown[source] = nil
    end
end)



RegisterNetEvent('nexa:MoveItemX')
AddEventHandler('nexa:MoveItemX', function(inventoryType, itemId, inventoryInfo, Lootbag, Quantity)
    local source = source
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if InventoryCoolDown[source] then return nexaclient.notify(source, {'~r~Please wait before moving more items.'}) end
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if data and data.inventory then
        if inventoryInfo == nil then return end
        if inventoryType == "CarBoot" then
            InventoryCoolDown[source] = true
            if Quantity >= 1 then
                local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
                nexa.getSData(carformat, function(cdata)
                    cdata = json.decode(cdata) or {}
                    if cdata[itemId] and Quantity <= cdata[itemId].amount  then
                        local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * Quantity)
                        if weightCalculation == nil then return end
                        if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                            if cdata[itemId].amount > Quantity then
                                cdata[itemId].amount = cdata[itemId].amount - Quantity 
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            else 
                                cdata[itemId] = nil
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            end 
                            local FormattedInventoryData = {}
                            for i, v in pairs(cdata) do
                                FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                            end
                            local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                            TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                            TriggerEvent('nexa:RefreshInventory', source)
                            nexa.setSData(carformat, json.encode(cdata))
                        else 
                            nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                        end
                    else 
                        nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                    end
                    InventoryCoolDown[source] = nil
                end)
            else
                InventoryCoolDown[source] = nil
                nexaclient.notify(source, {'~r~Invalid Amount!'})
            end
        elseif inventoryType == "LootBag" then    
            if not LootBagEntities[inventoryInfo] then return end
            if LootBagEntities[inventoryInfo].Items[itemId] then 
                Quantity = parseInt(Quantity)
                if Quantity then
                    local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * Quantity)
                    if weightCalculation == nil then return end
                    if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                        if Quantity <= LootBagEntities[inventoryInfo].Items[itemId].amount then 
                            if LootBagEntities[inventoryInfo].Items[itemId] and LootBagEntities[inventoryInfo].Items[itemId].amount > Quantity then
                                LootBagEntities[inventoryInfo].Items[itemId].amount = LootBagEntities[inventoryInfo].Items[itemId].amount - Quantity
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            else 
                                LootBagEntities[inventoryInfo].Items[itemId] = nil
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            end
                            local FormattedInventoryData = {}
                            for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                                FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                            end
                            local maxVehKg = 200
                            TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(LootBagEntities[inventoryInfo].Items), maxVehKg)                
                            TriggerEvent('nexa:RefreshInventory', source)
                            if not next(LootBagEntities[inventoryInfo].Items) then
                                CloseInv(source)
                            end
                        else 
                            nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                        end 
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                else 
                    nexaclient.notify(source, {'~r~Invalid input!'})
                end
                InventoryCoolDown[source] = nil
            end
        elseif inventoryType == "Housing" then
            Quantity = parseInt(Quantity)
            if Quantity then
                local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
                nexa.getSData(homeformat, function(cdata)
                    cdata = json.decode(cdata) or {}
                    if cdata[itemId] and Quantity <= cdata[itemId].amount  then
                        local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * Quantity)
                        if weightCalculation == nil then return end
                        if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                            if cdata[itemId].amount > Quantity then
                                cdata[itemId].amount = cdata[itemId].amount - Quantity
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            else 
                                cdata[itemId] = nil
                                nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                            end 
                            local FormattedInventoryData = {}
                            for i, v in pairs(cdata) do
                                FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                            end
                            local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                            TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                            TriggerEvent('nexa:RefreshInventory', source)
                            nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                        else 
                            nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                        end
                    else 
                        nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                    end
                    InventoryCoolDown[source] = nil
                end)
            else 
                nexaclient.notify(source, {'~r~Invalid input!'})
            end
        elseif inventoryType == "Crate" then
            InventoryCoolDown[source] = true
            if currentCrate.crateLoot[itemId] and Quantity <= currentCrate.crateLoot[itemId].amount then
                local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * currentCrate.crateLoot[itemId].amount)
                if weightCalculation == nil then return end
                if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                    if currentCrate.crateLoot[itemId].amount > Quantity then
                        currentCrate.crateLoot[itemId].amount = currentCrate.crateLoot[itemId].amount - Quantity
                        nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                    else
                        currentCrate.crateLoot[itemId] = nil
                        nexa.giveInventoryItem(user_id, itemId, Quantity, true)
                    end
                    local FormattedInventoryData = {}
                    for i, v in pairs(currentCrate.crateLoot) do
                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                    end
                    local maxVehKg = 200
                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(currentCrate.crateLoot), maxVehKg)
                    TriggerEvent('nexa:RefreshInventory', source)
                    if not next(currentCrate.crateLoot) then
                        TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "Crate drop has been looted.", "alert")
                        TriggerClientEvent("nexa:removeLootcrate", -1, currentCrate.crateID)
                        currentCrate = {}
                    end
                else 
                    nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                end
            else
                nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
            end
            InventoryCoolDown[source] = nil
        elseif inventoryType == "Plr" then
            if not Lootbag then
                if data.inventory[itemId] then
                    if inventoryInfo == "home" then
                        Quantity = parseInt(Quantity)
                        if Quantity then
                            local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
                            nexa.getSData(homeformat, function(cdata)
                                cdata = json.decode(cdata) or {}
                                if data.inventory[itemId] and Quantity <= data.inventory[itemId].amount  then
                                    local weightCalculation = nexa.computeItemsWeight(cdata)+(nexa.getItemWeight(itemId) * Quantity)
                                    if weightCalculation == nil then return end
                                    local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                                    if weightCalculation <= maxVehKg then
                                        if nexa.tryGetInventoryItem(user_id, itemId, Quantity, true) then
                                            if cdata[itemId] then
                                                cdata[itemId].amount = cdata[itemId].amount + Quantity
                                            else 
                                                cdata[itemId] = {}
                                                cdata[itemId].amount = Quantity
                                            end
                                        end 
                                        local FormattedInventoryData = {}
                                        for i, v in pairs(cdata) do
                                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                        end
                                        local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                        TriggerEvent('nexa:RefreshInventory', source)
                                        nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                                    else 
                                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                                    end
                                else 
                                    nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                                end
                            end)
                        else 
                            nexaclient.notify(source, {'~r~Invalid input!'})
                        end
                    else
                        InventoryCoolDown[source] = true
                        Quantity = parseInt(Quantity)
                        if Quantity then
                            local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
                            nexa.getSData(carformat, function(cdata)
                                cdata = json.decode(cdata) or {}
                                if data.inventory[itemId] and Quantity <= data.inventory[itemId].amount  then
                                    local weightCalculation = nexa.computeItemsWeight(cdata)+(nexa.getItemWeight(itemId) * Quantity)
                                    if weightCalculation == nil then return end
                                    local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                                    if weightCalculation <= maxVehKg then
                                        if nexa.tryGetInventoryItem(user_id, itemId, Quantity, true) then
                                            if cdata[itemId] then
                                                cdata[itemId].amount = cdata[itemId].amount + Quantity
                                            else 
                                                cdata[itemId] = {}
                                                cdata[itemId].amount = Quantity
                                            end
                                        end 
                                        local FormattedInventoryData = {}
                                        for i, v in pairs(cdata) do
                                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                        end
                                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                        TriggerEvent('nexa:RefreshInventory', source)
                                        nexa.setSData(carformat, json.encode(cdata))
                                    else 
                                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                                    end
                                else 
                                    nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                                end
                            end)
                        else 
                            nexaclient.notify(source, {'~r~Invalid input!'})
                        end
                        InventoryCoolDown[source] = nil
                    end
                end
            end
        end
    end
end)


RegisterNetEvent('nexa:MoveItemAll')
AddEventHandler('nexa:MoveItemAll', function(inventoryType, itemId, inventoryInfo, vehid)
    local source = source
    local user_id = nexa.getUserId(source) 
    local data = nexa.getUserDataTable(user_id)
    if not itemId then return nexaclient.notify(source, {'~r~You need to select an item, first!'}) end
    if InventoryCoolDown[source] then return nexaclient.notify(source, {'~r~Please wait before moving more items.'}) end
    if data and data.inventory then
        if inventoryInfo == nil then return end
        if inventoryType == "CarBoot" then
            InventoryCoolDown[source] = true
            local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
            nexa.getSData(carformat, function(cdata)
                cdata = json.decode(cdata) or {}
                if cdata[itemId] and cdata[itemId].amount <= cdata[itemId].amount  then
                    local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * cdata[itemId].amount)
                    if weightCalculation == nil then return end
                    local amount = cdata[itemId].amount
                    if weightCalculation > nexa.getInventoryMaxWeight(user_id) and nexa.getInventoryWeight(user_id) ~= nexa.getInventoryMaxWeight(user_id) then
                        amount = math.floor((nexa.getInventoryMaxWeight(user_id)-nexa.getInventoryWeight(user_id)) / nexa.getItemWeight(itemId))
                    end
                    if math.floor(amount) > 0 or (weightCalculation <= nexa.getInventoryMaxWeight(user_id)) then
                        nexa.giveInventoryItem(user_id, itemId, amount, true)
                        local FormattedInventoryData = {}
                        if (cdata[itemId].amount - amount) > 0 then
                            cdata[itemId].amount = cdata[itemId].amount - amount
                        else
                            cdata[itemId] = nil
                        end
                        for i, v in pairs(cdata) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                        TriggerEvent('nexa:RefreshInventory', source)
                        nexa.setSData(carformat, json.encode(cdata))
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                else 
                    nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                end
                InventoryCoolDown[source] = nil
            end)
        elseif inventoryType == "LootBag" then
            if itemId ~= nil then 
                if LootBagEntities[inventoryInfo] then   
                    if LootBagEntities[inventoryInfo].Items[itemId] then 
                        local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) *  LootBagEntities[inventoryInfo].Items[itemId].amount)
                        if weightCalculation == nil then return end
                        if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                            if  LootBagEntities[inventoryInfo].Items[itemId].amount <= LootBagEntities[inventoryInfo].Items[itemId].amount then 
                                nexa.giveInventoryItem(user_id, itemId, LootBagEntities[inventoryInfo].Items[itemId].amount, true)
                                LootBagEntities[inventoryInfo].Items[itemId] = nil
                                local FormattedInventoryData = {}
                                for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                                    FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                end
                                local maxVehKg = 200
                                TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(LootBagEntities[inventoryInfo].Items), maxVehKg)                
                                TriggerEvent('nexa:RefreshInventory', source)
                                if not next(LootBagEntities[inventoryInfo].Items) then
                                    CloseInv(source)
                                end
                            else 
                                nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                            end 
                        else 
                            nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                        end
                    end
                end
            end
        elseif inventoryType == "Housing" then
            local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
            nexa.getSData(homeformat, function(cdata)
                cdata = json.decode(cdata) or {}
                if cdata[itemId] and cdata[itemId].amount <= cdata[itemId].amount  then
                    local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * cdata[itemId].amount)
                    if weightCalculation == nil then return end
                    local amount = cdata[itemId].amount
                    if weightCalculation > nexa.getInventoryMaxWeight(user_id) and nexa.getInventoryWeight(user_id) ~= nexa.getInventoryMaxWeight(user_id) then
                        amount = math.floor((nexa.getInventoryMaxWeight(user_id)-nexa.getInventoryWeight(user_id)) / nexa.getItemWeight(itemId))
                    end
                    if math.floor(amount) > 0 or (weightCalculation <= nexa.getInventoryMaxWeight(user_id)) then
                        nexa.giveInventoryItem(user_id, itemId, amount, true)
                        local FormattedInventoryData = {}
                        if (cdata[itemId].amount - amount) > 0 then
                            cdata[itemId].amount = cdata[itemId].amount - amount
                        else
                            cdata[itemId] = nil
                        end
                        for i, v in pairs(cdata) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                        TriggerEvent('nexa:RefreshInventory', source)
                        nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                    else 
                        nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                    end
                else 
                    nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                end
            end)
        elseif inventoryType == "Crate" then
            local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * currentCrate.crateLoot[itemId].amount)
            if weightCalculation == nil then return end
            if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                if currentCrate.crateLoot[itemId] then
                    nexa.giveInventoryItem(user_id, itemId, currentCrate.crateLoot[itemId].amount, true)
                    currentCrate.crateLoot[itemId] = nil
                    local FormattedInventoryData = {}
                    for i, v in pairs(currentCrate.crateLoot) do
                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                    end
                    local maxVehKg = 200
                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(currentCrate.crateLoot), maxVehKg)
                    TriggerEvent('nexa:RefreshInventory', source)
                    if not next(currentCrate.crateLoot) then
                        CloseInv(source)
                        TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "Crate drop has been looted.", "alert")
                        TriggerClientEvent("nexa:removeLootcrate", -1, currentCrate.crateID)
                        currentCrate = {}
                    end
                end
            else 
                nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
            end
        elseif inventoryType == "Plr" then
            if not Lootbag then
                if data.inventory[itemId] then
                    if inventoryInfo == "home" then
                        local homeformat = "chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name
                        nexa.getSData(homeformat, function(cdata)
                            cdata = json.decode(cdata) or {}
                            if data.inventory[itemId] and data.inventory[itemId].amount <= data.inventory[itemId].amount  then
                                local itemAmount = data.inventory[itemId].amount
                                local weightCalculation = nexa.computeItemsWeight(cdata)+(nexa.getItemWeight(itemId) * itemAmount)
                                local maxVehKg = Housing.chestsize[inHouse[user_id].name] or 500
                                if weightCalculation == nil then 
                                    return
                                elseif weightCalculation <= maxVehKg then
                                    if nexa.tryGetInventoryItem(user_id, itemId, itemAmount, true) then
                                        if cdata[itemId] then
                                            cdata[itemId].amount = cdata[itemId].amount + itemAmount
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = itemAmount
                                        end 
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                                else 
                                    itemAmount = math.floor((maxVehKg - nexa.computeItemsWeight(cdata)) / nexa.getItemWeight(itemId))
                                    if nexa.tryGetInventoryItem(user_id, itemId, itemAmount, true) then
                                        if cdata[itemId] then
                                            cdata[itemId].amount = cdata[itemId].amount + itemAmount
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = itemAmount
                                        end 
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData("chest:u" .. inHouse[user_id].id .. "home" ..inHouse[user_id].name, json.encode(cdata))
                                end
                            else 
                                nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                            end
                        end)
                    elseif inventoryType == "Crate" then
                        if currentCrate[inventoryInfo] then
                            if currentCrate[inventoryInfo].Items[itemId] then
                                local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(itemId) * currentCrate[inventoryInfo].Items[itemId].amount)
                                if weightCalculation == nil then return end
                                if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                                    if currentCrate[inventoryInfo].Items[itemId].amount <= currentCrate[inventoryInfo].Items[itemId].amount then
                                        nexa.giveInventoryItem(user_id, itemId, currentCrate[inventoryInfo].Items[itemId].amount, true)
                                        currentCrate[inventoryInfo].Items[itemId] = nil
                                        local FormattedInventoryData = {}
                                        for i, v in pairs(currentCrate[inventoryInfo].Items) do
                                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                        end
                                        local maxVehKg = 200
                                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(currentCrate[inventoryInfo].Items), maxVehKg)
                                        TriggerEvent('nexa:RefreshInventory', source)
                                        if not next(currentCrate[inventoryInfo].Items) then
                                            CloseInv(source)
                                        end
                                    else 
                                        nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                                    end
                                else 
                                    nexaclient.notify(source, {'~r~You do not have enough inventory space.'})
                                end
                            end
                        end
                    else 
                        InventoryCoolDown[source] = true
                        local carformat = "chest:u1veh_" .. inventoryInfo .. '|' .. user_id
                        nexa.getSData(carformat, function(cdata)
                            cdata = json.decode(cdata) or {}
                            if data.inventory[itemId] and data.inventory[itemId].amount <= data.inventory[itemId].amount  then
                                local itemAmount = data.inventory[itemId].amount
                                local weightCalculation = nexa.computeItemsWeight(cdata)+(nexa.getItemWeight(itemId) * itemAmount)
                                local maxVehKg = Inventory.vehicle_chest_weights[inventoryInfo] or Inventory.default_vehicle_chest_weight
                                if weightCalculation == nil then 
                                    return 
                                elseif weightCalculation <= maxVehKg then
                                    if nexa.tryGetInventoryItem(user_id, itemId, itemAmount, true) then
                                        if cdata[itemId] then
                                            cdata[itemId].amount = cdata[itemId].amount + itemAmount
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = itemAmount
                                        end
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData(carformat, json.encode(cdata))
                                else 
                                    itemAmount = math.floor((maxVehKg - nexa.computeItemsWeight(cdata)) / nexa.getItemWeight(itemId))
                                    if nexa.tryGetInventoryItem(user_id, itemId, itemAmount, true) then
                                        if cdata[itemId] then
                                            cdata[itemId].amount = cdata[itemId].amount + itemAmount
                                        else 
                                            cdata[itemId] = {}
                                            cdata[itemId].amount = itemAmount
                                        end
                                    end 
                                    local FormattedInventoryData = {}
                                    for i, v in pairs(cdata) do
                                        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                                    end
                                    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(cdata), maxVehKg)
                                    TriggerEvent('nexa:RefreshInventory', source)
                                    nexa.setSData(carformat, json.encode(cdata))
                                end
                            else 
                                nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                            end
                            InventoryCoolDown[source] = nil
                        end)
                    end
                else
                    InventoryCoolDown[source] = nil
                end
            end
        end
    else 
        InventoryCoolDown[source] = nil
    end
end)

RegisterNetEvent('nexa:LootItemAll')
AddEventHandler('nexa:LootItemAll', function(inventoryInfo)
    local source = source
    local user_id = nexa.getUserId(source)
    if LootBagEntities[inventoryInfo] then   
        if LootBagEntities[inventoryInfo].Items then 
            for item, _ in pairs(LootBagEntities[inventoryInfo].Items) do
                local weightCalculation = nexa.getInventoryWeight(user_id)+(nexa.getItemWeight(item) *  LootBagEntities[inventoryInfo].Items[item].amount)
                if weightCalculation == nil then return end
                if weightCalculation <= nexa.getInventoryMaxWeight(user_id) then
                    if  LootBagEntities[inventoryInfo].Items[item].amount <= LootBagEntities[inventoryInfo].Items[item].amount then 
                        nexa.giveInventoryItem(user_id, item, LootBagEntities[inventoryInfo].Items[item].amount, true)
                        LootBagEntities[inventoryInfo].Items[item] = nil
                        local FormattedInventoryData = {}
                        for i, v in pairs(LootBagEntities[inventoryInfo].Items) do
                            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
                        end
                        local maxVehKg = 200
                        TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(LootBagEntities[inventoryInfo].Items), maxVehKg)                
                        TriggerEvent('nexa:RefreshInventory', source)
                        if not next(LootBagEntities[inventoryInfo].Items) then
                            CloseInv(source)
                        end
                    else 
                        nexaclient.notify(source, {'~r~You are trying to move more then there actually is!'})
                    end 
                else
                    break
                end
                Wait(500)
            end
        end
    end
end)

local storeWhenDead = {}
local function storeWeaponsRequest(player)
    local user_id = nexa.getUserId(player)
	nexaclient.getWeapons(player,{},function(weapons)
        if not storeWhenDead[player] then
            storeWhenDead[player] = true
            nexaclient.giveWeapons(player,{{},true}, function(removedwep)
                for k,v in pairs(weapons) do
                    if v.ammo > 0 and v.ammo ~= "modelammo" then
                        for i,c in pairs(a.weapons) do
                            if i == k then
                                nexa.giveInventoryItem(user_id, "wbody|"..k, 1, true)
                            end   
                        end
                    end
                end
                nexaclient.notify(player,{"~g~Weapons Stored"})
                SetTimeout(3000,function()
                    storeWhenDead[player] = nil 
                end)
            end)
        end
    end)
end

RegisterNetEvent('nexa:InComa')
AddEventHandler('nexa:InComa', function()
    local source = source
    local user_id = nexa.getUserId(source)
    local getPlayerBucket = GetPlayerRoutingBucket(source) or 0
    nexaclient.isInComa(source, {}, function(in_coma) 
        if in_coma then
            Wait(1500)
            local weight = nexa.getInventoryWeight(user_id)
            if weight == 0 then return end
            local model = `xs_prop_arena_bag_01`
            local name1 = tnexa.getDiscordName(source)
            local lootbag = CreateObjectNoOffset(model, GetEntityCoords(GetPlayerPed(source)) + 0.5, true, true, false)
            local lootbagnetid = NetworkGetNetworkIdFromEntity(lootbag)
            TriggerClientEvent('nexa:floatInvBag', -1, lootbagnetid)
            SetEntityRoutingBucket(lootbag, getPlayerBucket)
            local ndata = nexa.getUserDataTable(user_id)
            local stored_inventory = nil
            storeWeaponsRequest(source)
            LootBagEntities[lootbagnetid] = {lootbag, lootbag, false, source, expire_time = os.time()}
            LootBagEntities[lootbagnetid].Items = {}
            LootBagEntities[lootbagnetid].name = name1 
            if ndata ~= nil and ndata.inventory ~= nil then
                stored_inventory = ndata.inventory
                nexa.clearInventory(user_id)
                for k, v in pairs(stored_inventory) do
                    LootBagEntities[lootbagnetid].Items[k] = {amount = v.amount}
                end
            end
        end
    end)
end)

RegisterNetEvent('nexa:LootBag')
AddEventHandler('nexa:LootBag', function(netid)
    local source = source
    nexaclient.isInComa(source, {}, function(in_coma) 
        if not in_coma then
            if LootBagEntities[netid] then
                LootBagEntities[netid][3] = true
                local user_id = nexa.getUserId(source)
                if user_id ~= nil then
                    TriggerClientEvent("nexa:playZipperSound", -1, GetEntityCoords(GetPlayerPed(source)))
                    LootBagEntities[netid][5] = source
                    OpenInv(source, netid, LootBagEntities[netid].Items)
                end
            else
                local bagEntity = NetworkGetEntityFromNetworkId(netid)
                if DoesEntityExist(bagEntity) then
                    DeleteEntity(bagEntity)
                    LootBagEntities[netid] = nil
                end
            end
        else 
            nexaclient.notify(source, {'~r~You cannot open this while dead silly.'})
        end
    end)
end)

Citizen.CreateThread(function()
    while true do 
        Wait(250)
        for i,v in pairs(LootBagEntities) do 
            if v[5] then 
                local coords = GetEntityCoords(GetPlayerPed(v[5]))
                local objectcoords = GetEntityCoords(v[1])
                if #(objectcoords - coords) > 5.0 then
                    CloseInv(v[5])
                    Wait(3000)
                    v[3] = false
                    v[5] = nil
                end
            end
        end
    end
end)

-- Garabge collector for empty lootbags.
Citizen.CreateThread(function()
    while true do 
        Wait(500)
        for i,v in pairs(LootBagEntities) do 
            local itemCount = 0
            for a,b in pairs(v.Items) do
                itemCount = itemCount + 1
            end
            if itemCount == 0 or os.time() > v.expire_time + 600 then
                if DoesEntityExist(v[1]) then 
                    DeleteEntity(v[1])
                    LootBagEntities[i] = nil
                end
            end
        end
    end
end)

function CloseInv(source)
    TriggerClientEvent('nexa:InventoryOpen', source, false, false)
    TriggerClientEvent('nexa:closeSecondInventory', source)
end

function OpenInv(source, netid, LootBagItems)
    local user_id = nexa.getUserId(source)
    local data = nexa.getUserDataTable(user_id)
    if data and data.inventory then
        local FormattedInventoryData = {}
        for i,v in pairs(data.inventory) do
            FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
        end
        TriggerClientEvent('nexa:FetchPersonalInventory', source, FormattedInventoryData, nexa.computeItemsWeight(data.inventory), nexa.getInventoryMaxWeight(user_id))
        InventorySpamTrack[source] = false
    end
    TriggerClientEvent('nexa:InventoryOpen', source, true, true, netid)
    local FormattedInventoryData = {}
    for i, v in pairs(LootBagItems) do
        FormattedInventoryData[i] = {amount = v.amount, ItemName = nexa.getItemName(i), Weight = nexa.getItemWeight(i)}
    end
    local maxVehKg = 200
    TriggerClientEvent('nexa:SendSecondaryInventoryData', source, FormattedInventoryData, nexa.computeItemsWeight(LootBagItems), maxVehKg)
end

RegisterNetEvent('nexa:setCombatTimer')
AddEventHandler('nexa:setCombatTimer', function(timer)
    local source = source
    local user_id = nexa.getUserId(source)
    playersInCombat[source] = {time = timer}
end)

AddEventHandler("playerDropped",function(reason)
    local source = source
    local user_id = baseplayers[source]
    if user_id ~= nil then
        local coords = GetEntityCoords(GetPlayerPed(source))
        local bucket = GetPlayerRoutingBucket(source)
        local ndata = nexa.getUserDataTable(user_id)
        local money = nexa.getMoney(user_id)
        if playersInCombat[source] ~= nil then
            if playersInCombat[source].time > 0 and ndata ~= nil and not closeToRestart then
                if money > 0 then
                    local model = GetHashKey('prop_poly_bag_money')
                    local name1 = tnexa.getDiscordName(source)
                    local moneydrop = CreateObjectNoOffset(model, coords + 0.5, true, true, false)
                    local moneydropnetid = NetworkGetNetworkIdFromEntity(moneydrop)
                    SetEntityRoutingBucket(moneydrop, bucket)
                    MoneydropEntities[moneydropnetid] = {moneydrop, moneydrop, false, source}
                    MoneydropEntities[moneydropnetid].Money = money
                    MySQL.execute("nexa/set_wallet", {user_id = user_id, wallet = 0})
                end
                if ndata.weapons ~= nil or ndata.inventory ~= nil then
                    local model = `xs_prop_arena_bag_01`
                    local name1 = tnexa.getDiscordName(source)
                    local lootbag = CreateObjectNoOffset(model, coords + 0.5, true, true, false)
                    local lootbagnetid = NetworkGetNetworkIdFromEntity(lootbag)
                    TriggerClientEvent('nexa:floatInvBag', -1, lootbagnetid)
                    SetEntityRoutingBucket(lootbag, bucket)
                    local stored_inventory = nil
                    LootBagEntities[lootbagnetid] = {lootbag, lootbag, false, source, expire_time = os.time()}
                    LootBagEntities[lootbagnetid].Items = {}
                    LootBagEntities[lootbagnetid].name = name1 
                    if ndata ~= nil then
                        stored_inventory = ndata.inventory
                        stored_weapons = ndata.weapons
                        nexa.clearInventory(user_id)
                        nexa.clearWeapons(user_id)
                        if stored_inventory ~= nil then
                            for k, v in pairs(stored_inventory) do
                                LootBagEntities[lootbagnetid].Items[k] = {amount = v.amount}
                            end
                        end
                        if stored_weapons ~= nil then
                            for k, v in pairs(stored_weapons) do
                                if k ~= 'GADGET_PARACHUTE' then
                                    LootBagEntities[lootbagnetid].Items['wbody|'..k] = {}
                                    LootBagEntities[lootbagnetid].Items['wbody|'..k].amount = 1
                                    for c,d in pairs(a.weapons) do
                                        if k == c then
                                            LootBagEntities[lootbagnetid].Items[d.ammo] = {amount = v.ammo}
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end)