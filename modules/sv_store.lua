local cfg = module("cfg/cfg_store")
local guncfg = module('cfg/gunstores')
MySQL.createCommand("nexa/add_store_item", "INSERT IGNORE INTO nexa_store_data (uuid, user_id, store_item) VALUES (@uuid, @user_id, @store_item)")
MySQL.createCommand("nexa/update_store_item", "UPDATE nexa_store_data SET user_id = @user_id WHERE uuid = @uuid")
MySQL.createCommand("nexa/delete_store_item", "DELETE FROM nexa_store_data WHERE uuid = @uuid")
MySQL.createCommand("nexa/get_item_data", "SELECT * FROM nexa_store_data WHERE uuid = @uuid")
MySQL.createCommand("nexa/get_store_data", "SELECT * FROM nexa_store_data WHERE user_id = @user_id")

function tnexa.generatePackageUUID()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local firstString = ""
    local secondString = ""
    for i = 1, 4 do
        local randomString = math.random(#chars)
        firstString = firstString .. string.sub(chars, randomString, randomString)
    end
    for i = 1, 4 do
        local randomString = math.random(#chars)
        secondString = secondString .. string.sub(chars, randomString, randomString)
    end
    local UUID = firstString..'-'..secondString
    local checkUUID = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_store_data WHERE uuid = @uuid", {uuid = UUID})
    if #checkUUID > 0 then
        tnexa.generatePackageUUID()
    else
        return UUID
    end
end

nexa.createConsoleCommand('addpackage', function(source, args)
    local user_id = tonumber(args[1])
    local package = args[2]
    local uuid = tnexa.generatePackageUUID()
    tnexa.addPackage(user_id,package,uuid)
end)

function tnexa.addPackage(user_id,package)
    local source = nexa.getUserSource(user_id)
    local uuid = tnexa.generatePackageUUID()
    MySQL.execute("nexa/add_store_item", {user_id = user_id, uuid = uuid, store_item = package})
    tnexa.sendWebhook('add-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Added Package: **"..package.."**\n> UUID: **"..uuid.."**")
    Wait(100)
    if source ~= nil then
        tnexa.getStoreOwned(user_id, function(storeOwned)
            TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
        end)
    end
end

function tnexa.deletePackage(user_id, uuid)
    local source = nexa.getUserSource(user_id)
    MySQL.execute("nexa/delete_store_item", {uuid = uuid})
    TriggerClientEvent('nexa:storeDrawEffects', source)
    TriggerClientEvent('nexa:storeCloseMenu', source)
end

function tnexa.getStoreOwned(user_id, cb)
    local ownedItems = {}
    MySQL.query("nexa/get_store_data", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            for k,v in pairs(rows) do
                ownedItems[v.uuid] = v.store_item
            end
            cb(ownedItems)
        end
    end)
end

function tnexa.sellStoreItem(id1, id2, uuid, item, amount, cb)
    local amount = tonumber(amount)
    MySQL.query("nexa/get_item_data", {uuid = uuid}, function(rows, affected)
        if #rows > 0 then
            if rows[1].user_id == id1 then
                if nexa.tryFullPayment(id2, amount) then
                    nexa.giveBankMoney(id1, amount)
                    local source1 = nexa.getUserSource(id1)
                    local source2 = nexa.getUserSource(id2)
                    MySQL.execute("nexa/update_store_item", {user_id = id2, uuid = uuid})
                    TriggerClientEvent('nexa:storeCloseMenu', source1)
                    TriggerClientEvent('nexa:storeCloseMenu', source2)
                    Wait(100)
                    tnexa.getStoreOwned(id1, function(storeOwned)
                        tnexa.getStoreOwned(id2, function(storeOwned2)
                            TriggerClientEvent('nexa:sendStoreItems', source1, storeOwned)
                            TriggerClientEvent('nexa:sendStoreItems', source2, storeOwned2)
                        end)
                    end)
                    tnexa.sendWebhook('sell-packages',"nexa Store Logs", "> Seller ID: **"..id1.."**\n> Buyer ID: **"..id2.."**\n> Package: **"..item.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**")
                    cb(true)
                end
            end
        end
    end)
end

function tnexa.addImportSlots(user_id, storeItem, tableOfItems)
    local ranks = {
        -- Baller
        ['baller'] = 5,
        ['supporter_to_baller'] = 4,
        ['premium_to_baller'] = 4,
        ['supreme_to_baller'] = 4,
        ['kingpin_to_baller'] = 3,
        ['rainmaker_to_baller'] = 1,
        -- Rainmaker
        ['rainmaker'] = 3,
        ['supporter_to_rainmaker'] = 3,
        ['premium_to_rainmaker'] = 3,
        ['supreme_to_rainmaker'] = 3,
        ['kingpin_to_rainmaker'] = 2,
        -- Kingpin
        ['kingpin'] = 1,
        ['supporter_to_kingpin'] = 1,
        ['premium_to_kingpin'] = 1,
        ['supreme_to_kingpin'] = 1,
    }
    local importSlots = ranks[storeItem] or 0
    if importSlots > 0 then
        for k,v in pairs(tableOfItems) do
            if string.match(k, "customCar") then
                importSlots = importSlots - 1
                MySQL.execute("nexa/add_vehicle", {user_id = user_id, vehicle = v, registration = 'P'..math.random(10000,99999)})
            end
        end
        if importSlots >= 0 then
            for i = 1, importSlots do
                tnexa.addPackage(user_id,"import_slot")
                Wait(200)
            end
        end
    end
end

function tnexa.addVipCars(user_id, tableOfItems)
    for k,v in pairs(tableOfItems) do
        if string.match(k, "vipCar") then
            MySQL.execute("nexa/add_vehicle", {user_id = user_id, vehicle = v, registration = 'P'..math.random(10000,99999)})
        end
    end
end

function tnexa.redeemRankMoney(user_id, rank, rank2)
    local source = nexa.getUserSource(user_id)
    local rankMoney = {["Supporter"] = 500000,["Premium"] = 1500000,["Supreme"] = 2500000,["Kingpin"] = 5000000,["Rainmaker"] = 10000000,["Baller"] = 25000000}
    local money = rankMoney[rank]
    if rank2 then
        money = money - rankMoney[rank2]
    end
    nexa.giveBankMoney(user_id, money)
    nexaclient.notify(source, {'~g~Received £'..getMoneyStringFormatted(money)..' for redeeming '..rank..' rank'})
    if rank == "Baller" then
        tnexa.addPackage(user_id, "baller_id")
    end
end

function tnexa.getStoreRankName(user_id)
    local ranks = {[1] = 'Baller',[2] = 'Rainmaker',[3] = 'Kingpin',[4] = 'Supreme',[5] = 'Premium',[6] = 'Supporter'}
    for k,v in ipairs(ranks) do
        if nexa.hasGroup(user_id, v) then
            return v
        end
    end
    return "None"
end

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent('nexa:setStoreRankName', source, tnexa.getStoreRankName(user_id))
        tnexa.getStoreOwned(user_id, function(storeOwned)
            TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
        end)
    end
end)

RegisterNetEvent("nexa:getStoreLockedVehicleCategories")
AddEventHandler("nexa:getStoreLockedVehicleCategories", function()
    local source = source
    local user_id = nexa.getUserId(source)
    local lockedCategories = {}
    for k,v in pairs(cfg.vehicleCategoryToPermissionLookup) do
        if not nexa.hasPermission(user_id, v) then
            lockedCategories[k] = true
        end
        TriggerClientEvent('nexa:setStoreLockedVehicleCategories', source, lockedCategories)
    end
end)


RegisterNetEvent("nexa:redeemStoreItem")
AddEventHandler("nexa:redeemStoreItem", function(d, e)
    local source = source
    local user_id = nexa.getUserId(source)
    d = tostring(d)
    tnexa.getStoreOwned(user_id, function(storeOwned)
        local storeItem = storeOwned[d]
        local manuallyRedeemable = cfg.items[storeItem].manuallyRedeemable
        local itemName = cfg.items[storeItem].name
        if storeItem and manuallyRedeemable then
            if string.match(storeItem, "money_bag") then
                local item = storeItem:gsub("_money_bag", "")
                local amount = tonumber(item)*1000000
                nexa.giveBankMoney(user_id, amount)
                nexaclient.notify(source, {"~g~You have redeemed a £"..getMoneyStringFormatted(amount).." money bag! ❤️"})
                tnexa.deletePackage(user_id, d)
                tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                Wait(100)
                tnexa.getStoreOwned(user_id, function(storeOwned)
                    TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                end)
            elseif string.match(storeItem, "_whitelist") then
                local code = tonumber(e.accessCode)
                local ownedWhitelists = {}
                MySQL.query("nexa/get_weapon_codes", {}, function(weaponCodes)
                    if #weaponCodes > 0 then
                        local spawncode = nil
                        for e,f in pairs(weaponCodes) do
                            if f['user_id'] == user_id and f['weapon_code'] == code then
                                MySQL.query("nexa/get_weapons", {user_id = user_id}, function(weaponWhitelists)
                                    if next(weaponWhitelists) then
                                        ownedWhitelists = json.decode(weaponWhitelists[1]['weapon_info'])
                                    end
                                    for a,b in pairs(guncfg.whitelistedGuns) do
                                        for c,d in pairs(b) do
                                            if c == f['spawncode'] then
                                                spawncode = c
                                                if not ownedWhitelists[a] then
                                                    ownedWhitelists[a] = {}
                                                end
                                                ownedWhitelists[a][c] = d
                                            end
                                        end
                                    end
                                    MySQL.execute("nexa/set_weapons", {user_id = user_id, weapon_info = json.encode(ownedWhitelists)})
                                    MySQL.execute("nexa/remove_weapon_code", {weapon_code = code})
                                    tnexa.deletePackage(user_id, d)
                                    tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**\n> Access Code: **"..code.."**\n> Weapon: **"..spawncode.."**")
                                    TriggerClientEvent("nexa:refreshGunStorePermissions", source)
                                    nexaclient.notify(source, {"~g~Whitelist access granted! ❤️"})
                                    Wait(100)
                                    tnexa.getStoreOwned(user_id, function(storeOwned)
                                        TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                                    end)
                                end)
                            end
                        end
                    end
                end)
            elseif string.match(storeItem, "nexa_") then
                local subscription = storeItem:sub(6)
                tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
                    if cb then
                        if subscription == "plus" then
                            MySQL.execute("subscription/set_plushours", {user_id = user_id, plushours = plushours + 730})
                        elseif subscription == "platinum" then
                            MySQL.execute("subscription/set_plathours", {user_id = user_id, plathours = plathours + 730})
                        end
                        tnexa.deletePackage(user_id, d)
                        tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                        nexaclient.notify(source, {"~g~You have redeemed an "..itemName.." subscription! ❤️"})
                        Wait(100)
                        tnexa.getStoreOwned(user_id, function(storeOwned)
                            TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                        end)
                    end
                end)
            elseif string.match(storeItem, "_to_") then
                local parts = {}
                for part in string.gmatch(storeItem, "([^_]+)") do
                    table.insert(parts, part:sub(1, 1):upper() .. part:sub(2))
                end
                local from = parts[1]
                local to = parts[3]
                if nexa.hasGroup(user_id, from) then
                    if nexa.hasGroup(user_id, to) then
                        nexaclient.notify(source, {"~r~You already have this rank!"})
                        return
                    end
                    nexa.addUserGroup(user_id, to)
                    tnexa.addImportSlots(user_id, storeItem, e)
                    tnexa.addVipCars(user_id, e)
                    nexaclient.notify(source, {"~g~You have upgraded your rank to "..to.."! ❤️"})
                    tnexa.redeemRankMoney(user_id, to, from)
                    tnexa.deletePackage(user_id, d)
                    tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                    Wait(100)
                    tnexa.getStoreOwned(user_id, function(storeOwned)
                        TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                    end)
                else
                    nexaclient.notify(source, {"~r~You do not have the required rank to upgrade!"})
                end
            elseif storeItem == "import_slot" then
                local vehicle = e.customCar
                MySQL.execute("nexa/add_vehicle", {user_id = user_id, vehicle = vehicle, registration = 'P'..math.random(10000,99999)})
                tnexa.deletePackage(user_id, d)
                tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                nexaclient.notify(source, {"~g~The import vehicle is now in your garage! ❤️"})
                Wait(100)
                tnexa.getStoreOwned(user_id, function(storeOwned)
                    TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                end)
            elseif storeItem == "vip_car" then
                tnexa.addVipCars(user_id, e)
                tnexa.deletePackage(user_id, d)
                tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                nexaclient.notify(source, {"~g~The VIP vehicle is now in your garage! ❤️"})
                Wait(100)
                tnexa.getStoreOwned(user_id, function(storeOwned)
                    TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                end)
            else
                local rank = storeItem:sub(1,1):upper()..storeItem:sub(2)
                tnexa.redeemRankMoney(user_id, rank)
                nexa.addUserGroup(user_id, rank)
                tnexa.addImportSlots(user_id, storeItem, e)
                tnexa.addVipCars(user_id, e)
                tnexa.deletePackage(user_id, d)
                tnexa.sendWebhook('redeem-packages',"nexa Store Logs", "> Player PermID: **"..user_id.."**\n> Redeemed Package: **"..itemName.."**\n> UUID: **"..d.."**")
                nexaclient.notify(source, {"~g~You have redeemed a "..itemName.." rank! ❤️"})
                Wait(100)
                tnexa.getStoreOwned(user_id, function(storeOwned)
                    TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                end)
            end
        end
    end)
end)

RegisterNetEvent("nexa:startSellStoreItem")
AddEventHandler("nexa:startSellStoreItem", function(d)
    local source = source
    local user_id = nexa.getUserId(source)
    d = tostring(d)
    tnexa.getStoreOwned(user_id, function(storeOwned)
        local storeItem = storeOwned[d]
        if storeItem then
            local itemName = cfg.items[storeItem].name
            local canTransfer = cfg.items[storeItem].canTransfer
            if canTransfer then
                nexaclient.getNearestPlayers(source,{15},function(nplayers)
                    usrList = ""
                    for k, v in pairs(nplayers) do
                        usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | "
                    end
                    if usrList ~= "" then
                        nexa.prompt(source,"Players Nearby: " .. usrList .. "","",function(source, tempid)
                            local target_id = nexa.getUserId(tonumber(tempid))
                            if target_id ~= nil and target_id ~= "" then 
                                local target = tonumber(tempid)
                                if target ~= nil then
                                    nexa.prompt(source,"Price £: ","",function(source, amount)
                                        if tonumber(amount) and tonumber(amount) >= 0 then
                                            nexa.request(target,tnexa.getDiscordName(source).." wants to sell a " ..itemName.. " for £"..getMoneyStringFormatted(amount), 30, function(target,ok)
                                                if ok then
                                                    tnexa.sellStoreItem(user_id, target_id, d, storeItem, amount, function(itemSold)
                                                        if itemSold then
                                                            nexaclient.notify(source,{"~g~"..tnexa.getDiscordName(target).." has bought a " ..itemName.. " for £"..getMoneyStringFormatted(amount)})
                                                            nexaclient.notify(target,{"~g~You have bought a " ..itemName.. " for £"..getMoneyStringFormatted(amount)})
                                                        end
                                                    end)
                                                else
                                                    nexaclient.notify(source,{"~r~"..tnexa.getDiscordName(target).." has refused to buy a " ..itemName.. " for £"..getMoneyStringFormatted(amount)})
                                                    nexaclient.notify(target,{"~r~You have refused to buy a " ..itemName.. " for £"..getMoneyStringFormatted(amount)})
                                                end
                                            end)
                                        else
                                            nexaclient.notify(source,{"~r~Price of item must be a number."})
                                        end
                                    end)
                                else
                                    nexaclient.notify(source,{"~r~That Perm ID seems to be invalid!"})
                                end
                            else
                                nexaclient.notify(source,{"~r~No Perm ID selected!"})
                            end
                        end)
                    else
                        nexaclient.notify(source,{"~r~No players nearby!"})
                    end
                end)
            end
        end
    end)
end)

RegisterNetEvent("nexa:setInVehicleTestingBucket")
AddEventHandler("nexa:setInVehicleTestingBucket", function(state)
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.getStoreOwned(user_id, function(storeOwned)
        if storeOwned then
            if state then 
                tnexa.setBucket(source, 200)
            else
                tnexa.setBucket(source, 0)
            end
        end
    end)
end)

nexa.createConsoleCommand('addcar', function(source, args)
    if tonumber(args[1]) then
        local userid = tonumber(args[1])
        local car = args[2]
        MySQL.execute("nexa/add_vehicle", {user_id = userid, vehicle = car, registration = 'P'..math.random(10000,99999)})
    else 
        print('Incorrect usage: addcar [permid] [car]')
    end
end)