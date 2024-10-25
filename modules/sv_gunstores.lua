local cfg = module('cfg/gunstores')
local weapons = module('nexa-weapons', 'cfg/weapons')
weapons = weapons.weapons

MySQL.createCommand("nexa/get_weapons", "SELECT weapon_info FROM nexa_weapon_whitelists WHERE user_id = @user_id")
MySQL.createCommand("nexa/set_weapons", "UPDATE nexa_weapon_whitelists SET weapon_info = @weapon_info WHERE user_id = @user_id")
MySQL.createCommand("nexa/add_user", "INSERT IGNORE INTO nexa_weapon_whitelists SET user_id = @user_id")
MySQL.createCommand("nexa/get_all_weapons", "SELECT * FROM nexa_weapon_whitelists")
MySQL.createCommand("nexa/create_weapon_code", "INSERT IGNORE INTO nexa_weapon_codes SET user_id = @user_id, spawncode = @spawncode, weapon_code = @weapon_code")
MySQL.createCommand("nexa/remove_weapon_code", "DELETE FROM nexa_weapon_codes WHERE weapon_code = @weapon_code")
MySQL.createCommand("nexa/get_weapon_codes", "SELECT * FROM nexa_weapon_codes")

AddEventHandler("playerJoining", function()
    local user_id = nexa.getUserId(source)
    MySQL.execute("nexa/add_user", {user_id = user_id})
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

RegisterNetEvent("nexa:getCustomWeaponsOwned")
AddEventHandler("nexa:getCustomWeaponsOwned",function()
    local source = source
    local user_id = nexa.getUserId(source)
    local ownedWhitelists = {}
    MySQL.query("nexa/get_weapons", {user_id = user_id}, function(weaponWhitelists)
        if weaponWhitelists[1]['weapon_info'] ~= nil then
            data = json.decode(weaponWhitelists[1]['weapon_info'])
            for k,v in pairs(data) do
                for a,b in pairs(v) do
                    for c,d in pairs(cfg.whitelistedGuns) do
                        for e,f in pairs(d) do
                            if e == a and f[6] == user_id then
                                ownedWhitelists[a] = b[1]
                            end
                        end
                    end
                end
            end
            TriggerClientEvent('nexa:gotCustomWeaponsOwned', source, ownedWhitelists)
        end
    end)
end)

RegisterNetEvent("nexa:requestWhitelistedUsers")
AddEventHandler("nexa:requestWhitelistedUsers",function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    local whitelistOwners = {}
    MySQL.query("nexa/get_all_weapons", {}, function(weaponWhitelists)
        for k,v in pairs(weaponWhitelists) do
            if v['weapon_info'] ~= nil then
                data = json.decode(v['weapon_info'])
                for a,b in pairs(data) do
                    if b[spawncode] then
                        whitelistOwners[v['user_id']] = (exports['ghmattimysql']:executeSync("SELECT username FROM nexa_users WHERE id = @user_id", {user_id = v['user_id']})[1]).username
                    end
                end
            end
        end
        TriggerClientEvent('nexa:getWhitelistedUsers', source, whitelistOwners)
    end)
end)

RegisterNetEvent("nexa:generateWeaponAccessCode")
AddEventHandler("nexa:generateWeaponAccessCode",function(spawncode, id)
    local source = source
    local user_id = nexa.getUserId(source)
    local code = math.random(100000,999999)
    for a,b in pairs(cfg.whitelistedGuns) do
        for c,d in pairs(b) do
            if b[spawncode] and d[6]== user_id then
                MySQL.execute("nexa/create_weapon_code", {user_id = id, spawncode = spawncode, weapon_code = code})
                TriggerClientEvent('nexa:generatedAccessCode', source, code)
            end
        end
    end
end)

RegisterNetEvent("nexa:requestNewGunshopData")
AddEventHandler("nexa:requestNewGunshopData",function()
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_weapons", {user_id = user_id}, function(weaponWhitelists)
        local gunstoreData = deepcopy(cfg.GunStores)
        if weaponWhitelists[1]['weapon_info'] ~= nil then
            local data = json.decode(weaponWhitelists[1]['weapon_info'])
            for a,b in pairs(gunstoreData) do
                for c,d in pairs(data) do
                    if a == c then
                        for e,f in pairs(data[a]) do
                            gunstoreData[a][e] = f
                        end
                    end
                end
            end
        end
        tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
            if cb then
                if plathours > 0 and nexa.hasPermission(user_id, "vip.gunstore") then
                    for k,v in pairs(cfg.VIPWithPlat) do
                        gunstoreData["VIP"][k] = v
                    end
                end
            end
            if nexa.hasPermission(user_id, 'advancedrebel.license') then
                for k,v in pairs(cfg.RebelWithAdvanced) do
                    gunstoreData["Rebel"][k] = v
                end
            end
            TriggerClientEvent('nexa:receiveFilteredGunStoreData', source, gunstoreData)
            TriggerClientEvent('nexa:recalculateLargeArms', source, turfData[5].commission)
        end)
    end)
end)

local function gunStoreLogs(weaponshop, webhook, title, text)
    if weaponshop == 'policeLargeArms' or weaponshop == 'policeSmallArms' then
        tnexa.sendWebhook('pd-armoury', 'nexa Police Armoury Logs', text)
    elseif weaponshop == 'NHS' then
        tnexa.sendWebhook('nhs-armoury', 'nexa NHS Armoury Logs', text)
    elseif weaponshop == 'prisonArmoury' then
        tnexa.sendWebhook('hmp-armoury', 'nexa HMP Armoury Logs', text)
    elseif weaponshop == 'LFB' then
        tnexa.sendWebhook('lfb-armoury', 'nexa LFB Armoury Logs', text)
    end
    tnexa.sendWebhook(webhook,title,text)
end

local function gunstorePurchase(user_id, price, weaponshop, vipstore)
    if nexa.tryPayment(user_id,price) then
        return true
    elseif vipstore and nexa.tryFullPayment(user_id, price) then
        return true
    elseif weaponshop == 'VIP' and nexa.tryFullPayment(user_id, price) then
        return true
    end
    return false
end

RegisterNetEvent("nexa:buyWeapon")
AddEventHandler("nexa:buyWeapon",function(spawncode, price, name, weaponshop, purchasetype, vipstore)
    local source = source
    local user_id = nexa.getUserId(source)
    local hasPerm = false
    local gunstoreData = deepcopy(cfg.GunStores)
    if GetEntityHealth(GetPlayerPed(source)) <= 102 then return nexaclient.notify(source, {"~r~Can't buy a weapon whilst dead silly."}) end
    if GetPlayerRoutingBucket(source) ~= 0 then return nexaclient.notify(source, {"~r~You cannot buy weapons in this dimension."}) end
    MySQL.query("nexa/get_weapons", {user_id = user_id}, function(weaponWhitelists)
        local gunstoreData = deepcopy(cfg.GunStores)
        if weaponWhitelists[1]['weapon_info'] ~= nil then
            local data = json.decode(weaponWhitelists[1]['weapon_info'])
            for a,b in pairs(gunstoreData) do
                for c,d in pairs(data) do
                    if a == c then
                        for e,f in pairs(data[a]) do
                            gunstoreData[a][e] = f
                        end
                    end
                end
            end
        end
        for k,v in pairs(gunstoreData[weaponshop]) do
            if k == '_config' then
                local withinRadius = false
                for a,b in pairs(v[1]) do
                    if #(GetEntityCoords(GetPlayerPed(source)) - b) < 10 then
                        withinRadius = true
                    end
                end
                if vipstore then
                    if #(GetEntityCoords(GetPlayerPed(source)) - gunstoreData["VIP"]['_config'][1][1] ) < 10 then
                        withinRadius = true
                    end
                end
                if not withinRadius then return end
                if json.encode(v[5]) ~= '[""]' then
                    local hasPermissions = 0
                    for a,b in pairs(v[5]) do
                        if nexa.hasPermission(user_id, b) then
                            hasPermissions = hasPermissions + 1
                        end
                    end
                    if hasPermissions == #v[5] then
                        hasPerm = true
                    end
                else
                    hasPerm = true
                end
                tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
                    if cb then
                        if plathours > 0 and nexa.hasPermission(user_id, "vip.gunstore") then
                            for k,v in pairs(cfg.VIPWithPlat) do
                                gunstoreData["VIP"][k] = v
                            end
                        end
                    end
                    if nexa.hasPermission(user_id, 'advancedrebel.license') then
                        for k,v in pairs(cfg.RebelWithAdvanced) do
                            gunstoreData["Rebel"][k] = v
                        end
                    end
                    for c,d in pairs(gunstoreData[weaponshop]) do
                        if c ~= '_config' then
                            if hasPerm then
                                if c == spawncode then
                                    if name == d[1] then
                                        if purchasetype == 'armour' then
                                            for k,v in pairs(cfg.items) do
                                                if string.find(spawncode, v.item) then
                                                    if nexa.getInventoryWeight(user_id)+v.weight <= nexa.getInventoryMaxWeight(user_id) then
                                                        if gunstorePurchase(user_id, price, weaponshop, vipstore) then
                                                            nexaclient.notify(source, {'~g~You bought '..name..' for £'..getMoneyStringFormatted(price)..'.'})
                                                            nexa.giveInventoryItem(user_id,v.item,1,true)
                                                            TriggerClientEvent("nexa:PlaySound", source, "money")
                                                            gunStoreLogs(weaponshop, 'weapon-shops',"nexa Weapon Shop Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**\n> Price: **£"..getMoneyStringFormatted(price).."**\n> Weapon Shop: **"..weaponshop.."**\n> Purchase Type: **"..purchasetype.."**")
                                                            return
                                                        end
                                                    else
                                                        return nexaclient.notify(source, {'~r~You do not have enough space in your inventory.'})
                                                    end
                                                end
                                            end
                                            if cfg.freeArmour then nexaclient.setArmour(source, {100, true}) return nexaclient.notify(source, {'~g~You have been granted 100% armour due to a special event.'}) end
                                            if string.find(spawncode, "fillUp") then
                                                price = (100 - GetPedArmour(GetPlayerPed(source))) * 1000
                                                if gunstorePurchase(user_id, price, weaponshop, vipstore) then
                                                    nexaclient.notify(source, {'~g~You bought '..name..' for £'..getMoneyStringFormatted(price)..'.'})
                                                    nexaclient.setArmour(source, {100, true})
                                                    gunStoreLogs(weaponshop, 'weapon-shops',"nexa Weapon Shop Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**\n> Price: **£"..getMoneyStringFormatted(price).."**\n> Weapon Shop: **"..weaponshop.."**\n> Purchase Type: **"..purchasetype.."**")
                                                    return
                                                end
                                            elseif GetPedArmour(GetPlayerPed(source)) >= (price/1000) then
                                                nexaclient.notify(source, {'~r~You already have '..GetPedArmour(GetPlayerPed(source))..'% armour.'})
                                                return
                                            end
                                            if gunstorePurchase(user_id, price, weaponshop, vipstore) then
                                                nexaclient.notify(source, {'~g~You bought '..name..' for £'..getMoneyStringFormatted(price)..'.'})
                                                gunStoreLogs(weaponshop, 'weapon-shops',"nexa Weapon Shop Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**\n> Price: **£"..getMoneyStringFormatted(price).."**\n> Weapon Shop: **"..weaponshop.."**\n> Purchase Type: **"..purchasetype.."**")
                                                if weaponshop == 'LargeArmsDealer' then
                                                    nexaclient.setArmour(source, {d[7]/1000, true})
                                                    nexa.turfSaleToGangFunds(d[7], 'LargeArms')
                                                else
                                                    nexaclient.setArmour(source, {price/1000, true})
                                                end
                                                return
                                            else
                                                nexaclient.notify(source, {'~r~You do not have enough money for this purchase.'})
                                            end
                                        elseif purchasetype == 'weapon' then
                                            nexaclient.hasWeapon(source, {spawncode}, function(hasWeapon)
                                                if hasWeapon then
                                                    nexaclient.notify(source, {'~r~You must store your current '..name..' before purchasing another.'})
                                                else
                                                    nexaclient.getWeapons(source, {}, function(uweapons)
                                                        if not uweapons then return end
                                                        for k,v in pairs(uweapons) do
                                                            if weapons[k].class == weapons[spawncode].class and weapons[k].class ~= "Melee" then
                                                                return nexaclient.notify(source, {'~r~You already have a weapon of this class equipped.'})
                                                            end
                                                        end
                                                        if gunstorePurchase(user_id, price, weaponshop, vipstore) then
                                                            if price > 0 then
                                                                nexaclient.notify(source, {'~g~You bought a '..name..' for £'..getMoneyStringFormatted(price)..'.'})
                                                                if weaponshop == 'LargeArmsDealer' then
                                                                    nexa.turfSaleToGangFunds(d[7], 'LargeArms')
                                                                end
                                                            else
                                                                nexaclient.notify(source, {'~g~'..name..' purchased.'})
                                                            end
                                                            TriggerClientEvent("nexa:PlaySound", source, "money")
                                                            isStoring[source] = true
                                                            nexaclient.giveWeapons(source, {{[spawncode] = {ammo = 250}}})
                                                            Wait(1500)
                                                            isStoring[source] = nil
                                                            gunStoreLogs(weaponshop, 'weapon-shops',"nexa Weapon Shop Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**\n> Price: **£"..getMoneyStringFormatted(price).."**\n> Weapon Shop: **"..weaponshop.."**\n> Purchase Type: **"..purchasetype.."**")
                                                        else
                                                            nexaclient.notify(source, {'~r~You do not have enough money for this purchase.'})
                                                        end
                                                        return
                                                    end)
                                                end
                                            end)
                                        elseif purchasetype == 'ammo' then
                                            price = price/2
                                            if gunstorePurchase(user_id, price, weaponshop, vipstore) then
                                                if price > 0 then
                                                    nexaclient.notify(source, {'~g~You bought 250x Ammo for £'..getMoneyStringFormatted(price)..'.'})
                                                    if weaponshop == 'LargeArmsDealer' then
                                                        nexa.turfSaleToGangFunds(d[7], 'LargeArms')
                                                    end
                                                else
                                                    nexaclient.notify(source, {'~g~250x Ammo purchased.'})
                                                end
                                                TriggerClientEvent("nexa:PlaySound", source, "money")
                                                nexaclient.giveWeapons(source, {{[spawncode] = {ammo = 250}}})
                                                gunStoreLogs(weaponshop, 'weapon-shops',"nexa Weapon Shop Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**\n> Price: **£"..getMoneyStringFormatted(price).."**\n> Weapon Shop: **"..weaponshop.."**\n> Purchase Type: **"..purchasetype.."**")
                                            else
                                                nexaclient.notify(source, {'~r~You do not have enough money for this purchase.'})
                                            end
                                        end
                                    end
                                end
                            else
                                if weaponshop == 'policeLargeArms' or weaponshop == 'policeSmallArms' then
                                    nexaclient.notify(source, {"~r~You shouldn't be in here, ALARM TRIGGERED!!!"})
                                else
                                    nexaclient.notify(source, {"~r~You do not have permission to access this store."})
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)
end)