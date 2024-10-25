local cfg = module("cfg/cfg_lscustoms")
local lockedGarages = {}

function nexa.GetVehiclesNitro(user_id,spawncode)
    local nitro = 0
    local data = exports['ghmattimysql']:executeSync('SELECT * FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @spawncode', {user_id = user_id, spawncode = spawncode})
    if data[1] ~= nil then
        nitro = tonumber(data[1].nitro)
    end
    return nitro
end

function nexa.GetVehiclesFuel(user_id,spawncode)
    local fuel_level = exports['ghmattimysql']:executeSync("SELECT fuel_level FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @spawncode", {user_id = user_id, spawncode = spawncode})[1].fuel_level
    return fuel_level or 100
end

function nexa.GetVehiclesPlate(user_id,spawncode)
    local plate = exports['ghmattimysql']:executeSync("SELECT vehicle_plate FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @spawncode", {user_id = user_id, spawncode = spawncode})[1].vehicle_plate
    return plate or "Unknown"
end

RegisterServerEvent("nexa:setCustomsGarageStatus", function(garage,bool)
    local source = source
    local user_id = nexa.getUserId(source)
    if not bool then
        lockedGarages[garage] = nil
    else
        lockedGarages[garage] = {
            locked = true,
            player = source
        }
    end
    TriggerClientEvent('nexa:setCustomsGarageStatus', -1,garage,bool)
end)

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent('nexa:syncCustomsGarageStatus', source,lockedGarages)
    end
end)

AddEventHandler('playerDropped', function(reason)
    local source = source
    for L,O in pairs(lockedGarages)do
        if O.player == source then
            TriggerClientEvent('nexa:setCustomsGarageStatus', -1,L,false)
            lockedGarages[L] = nil
            return
        end
    end
end)

MySQL.createCommand("nexa/GetUsersVehicleMods","SELECT * FROM nexa_vehicle_mods WHERE user_id = @user_id AND spawncode = @spawncode")

MySQL.createCommand("nexa/GetUsersVehicleMod","SELECT * FROM nexa_vehicle_mods WHERE user_id = @user_id AND spawncode = @spawncode AND savekey = @savekey")
MySQL.createCommand("nexa/GetUsersSpecificVehicleMod","SELECT * FROM nexa_vehicle_mods WHERE user_id = @user_id AND spawncode = @spawncode AND savekey = @savekey AND `mod` = @mod")
MySQL.createCommand("nexa/InsertNewVehicleMod","INSERT INTO nexa_vehicle_mods (user_id,spawncode,savekey,`mod`) VALUES (@user_id,@spawncode,@savekey,@mod)")
MySQL.createCommand("nexa/UpdateVehicleMod","UPDATE nexa_vehicle_mods SET `mod` = @mod WHERE user_id = @user_id AND spawncode = @spawncode AND savekey = @savekey")

MySQL.createCommand("nexa/SetModEnabled","UPDATE nexa_vehicle_mods SET enabled = @enabled WHERE user_id = @user_id AND spawncode = @spawncode AND savekey = @savekey AND `mod` = @mod")

MySQL.createCommand("nexa/SetNewModValue","UPDATE nexa_vehicle_mods SET `mod` = @mod WHERE user_id = @user_id AND spawncode = @spawncode AND savekey = @savekey AND `mod` = @oldmod")

MySQL.createCommand("nexa/GetVehicleStancerMods","SELECT * FROM nexa_vehicle_stancer WHERE user_id = @user_id AND spawncode = @spawncode")
MySQL.createCommand("nexa/InsertNewVehicleStancerMod","INSERT INTO nexa_vehicle_stancer (user_id,spawncode,`mod`) VALUES (@user_id,@spawncode,@mod)")
MySQL.createCommand("nexa/UpdateVehicleStancerMod","UPDATE nexa_vehicle_stancer SET `value` = @value WHERE user_id = @user_id AND spawncode = @spawncode AND `mod` = @mod")

local function DisableOtherMods(spawncode,user_id,cat)
    local savekey = cat.saveKey
    local othersInCat = MySQL.asyncQuery("nexa/GetUsersVehicleMod",{user_id = user_id, spawncode = spawncode, savekey = savekey})
    local enabledTable = {}
    for k,v in pairs(othersInCat) do
        MySQL.execute("nexa/SetModEnabled",{user_id = user_id, spawncode = spawncode, savekey = savekey, mod = v.mod, enabled = 0})
        enabledTable[tostring(v.mod)] = false
    end
    local unapplyList = cat.unapply
    if unapplyList then
        unapplyList = string.gsub(unapplyList, " ", "")
        unapplyList = stringsplit(unapplyList, ",")
        local vehicleMods = MySQL.asyncQuery("nexa/GetUsersVehicleMods",{user_id = user_id, spawncode = spawncode})
        for k,v in pairs(vehicleMods) do
            if table.find(unapplyList,v.savekey)~=nil and table.find(unapplyList,v.savekey)~=false then
                MySQL.execute("nexa/SetModEnabled",{user_id = user_id, spawncode = spawncode, savekey = v.savekey, mod = v.mod, enabled = 0})
                enabledTable[tostring(v.mod)] = false
            end
        end
    end
    return enabledTable
end

local function SetModEnabled(spawncode,user_id,cat,mod)
    local savekey = cat.saveKey
    local enabledTable = DisableOtherMods(spawncode,user_id,cat)
    MySQL.asyncQuery("nexa/SetModEnabled",{user_id = user_id, spawncode = spawncode, savekey = savekey, mod = mod, enabled = 1})
    enabledTable[tostring(mod)] = true
    local source = nexa.getUserSource(user_id)
    if source then
        TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,savekey,enabledTable)
    end
end

local function UpdateVehicleMod(spawncode,user_id,cat,mod)
    local savekey = cat.saveKey
    local enabledTable = DisableOtherMods(spawncode,user_id,cat)
    enabledTable[tostring(mod)] = true
    local previousMod = MySQL.asyncQuery("nexa/GetUsersSpecificVehicleMod",{user_id = user_id, spawncode = spawncode, savekey = savekey, mod = mod})
    if previousMod and previousMod[1] then
        MySQL.asyncQuery("nexa/SetModEnabled",{user_id = user_id, spawncode = spawncode, savekey = savekey, mod = mod, enabled = 1})
    else
        MySQL.asyncQuery("nexa/InsertNewVehicleMod",{user_id = user_id, spawncode = spawncode, savekey = savekey, mod = mod})
    end
    local source = nexa.getUserSource(user_id)
    if source then
        TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,savekey,enabledTable)
    end
end

--Mods

function nexa.GetDefaultMods(array)
    if not array then
        array = cfg.category.categories
    end
    local returnArray = {}
    for k,v in pairs(array) do
        if v.categories then
            for i,d in pairs(nexa.GetDefaultMods(v.categories))do
                returnArray[i] = {}
            end
        end
        if v.saveKey then
            returnArray[v.saveKey] = {}
        end
    end
    returnArray.plate_colour = {}
    returnArray.vehicle_plate = "N/A"
    returnArray.nitro = 0
    returnArray.fuel = 100
    return returnArray
end

function nexa.GetMods(spawncode,user_id)
    local mods = nexa.GetDefaultMods()
    local data = MySQL.asyncQuery("nexa/GetUsersVehicleMods",{user_id = user_id, spawncode = spawncode})
    for k,v in pairs(data) do
        if not mods[v.savekey] then
            mods[v.savekey] = {}
        end
        mods[v.savekey][v.mod] = tobool(v.enabled)
    end
    local nitro = nexa.GetVehiclesNitro(user_id,spawncode)
    local fuel = nexa.GetVehiclesFuel(user_id,spawncode)
    local plate = nexa.GetVehiclesPlate(user_id,spawncode)
    mods.nitro = nitro
    mods.fuel = fuel
    mods.vehicle_plate = plate
    if mods.biometric_users then
        for k,v in pairs(mods.biometric_users) do
            mods.biometric_users[k] = nexa.GetPlayerName(tonumber(k))
        end
    end
    mods.stancer = nexa.GetVehiclesStancerMods(user_id,spawncode)
    return mods
end

function nexa.GetVehiclesStancerMods(user_id,spawncode)
    local data = MySQL.asyncQuery("nexa/GetVehicleStancerMods",{user_id = user_id, spawncode = spawncode})
    local returnArray = {}
    for k,v in pairs(data) do
        returnArray[v.mod] = {
            [v.value] = true
        }
    end
    return returnArray
end

local function ConvertModTable(mod)
    if type(mod) == "table" then
        return json.encode(mod)
    else
        return mod
    end
end

RegisterServerEvent("nexa:getBoughtUpgrades", function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    local array = nexa.GetMods(spawncode,user_id)
    TriggerClientEvent('nexa:gotBoughtUpgrades', source,array)
end)

--Repair

RegisterServerEvent("nexa:lscustomsRepairVehicle", function()
    local source = source
    local user_id = nexa.getUserId(source)
    if not nexa.tryFullPayment(user_id, 1000) then
        nexa.notify(source, "~r~You don't have enough money to repair your vehicle")
        return
    end
    TriggerClientEvent('nexa:lscustomsRepairVehicle', source)
end)

RegisterServerEvent("nexa:setActiveStaticList",function(spawncode,cat,item)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local saveValue = cat.saveValue
    local mod = ConvertModTable(cat.items[item][saveValue])
    SetModEnabled(spawncode,user_id,cat,mod)
end)

RegisterServerEvent("nexa:purchaseStaticList",function(spawncode,cat,item)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local price = cat.items[item].price
    if not price then
        price = cat.price
    end
    if not nexa.tryFullPayment(user_id, price) then
        nexa.notify(source, "~r~You don't have enough money to purchase this upgrade")
        return
    end
    local upgradeName = cat.items[item].name
    nexa.notify(source, "~g~You have purchased the ~w~"..upgradeName.." ~g~upgrade for £"..getMoneyStringFormatted(price))
    local saveValue = cat.saveValue
    local mod = ConvertModTable(cat.items[item][saveValue])
    UpdateVehicleMod(spawncode,user_id,cat,mod)
end)

RegisterServerEvent("nexa:setActiveModList",function(spawncode,cat,mod)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    SetModEnabled(spawncode,user_id,cat,mod)
end)

RegisterServerEvent("nexa:purchaseModList",function(spawncode,cat,mod)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local price = cat.price
    if not price then
        price = 1000
    end
    if not nexa.tryFullPayment(user_id, price) then
        nexa.notify(source, "~r~You don't have enough money to purchase this upgrade")
        return
    end
    local upgradeName = cat.name
    nexa.notify(source, "~g~You have purchased the ~w~"..upgradeName.." ~g~upgrade for £"..getMoneyStringFormatted(price))
    local saveValue = cat.saveValue
    UpdateVehicleMod(spawncode,user_id,cat,mod)
end)

RegisterServerEvent("nexa:purchaseStaticValueList",function(spawncode,cat,item)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local price = cat.items[item].price
    if not price then
        price = cat.price
    end
    if not nexa.tryFullPayment(user_id, price) then
        nexa.notify(source, "~r~You don't have enough money to purchase this upgrade")
        return
    end
    local upgradeName = cat.items[item].name
    nexa.notify(source, "~g~You have purchased the ~w~"..upgradeName.." ~g~upgrade for £"..getMoneyStringFormatted(price))
    local savekey = cat.saveKey
    local saveValue = cat.saveValue
    local mod = ConvertModTable(cat.items[item][saveValue])
    if cat.name=="Nitro" then
        exports['ghmattimysql']:execute("UPDATE nexa_user_vehicles SET nitro = @nitro WHERE user_id = @user_id AND vehicle = @spawncode", {spawncode = spawncode,nitro = mod, user_id = user_id}, function() 
        end)
    end
    TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,savekey,mod)
end)

RegisterServerEvent("nexa:purchaseValueInputList",function(spawncode,cat)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local price = cat.price
    if not price then
        price = cat.price
    end
    if not nexa.tryFullPayment(user_id, price) then
        nexa.notify(source, "~r~You don't have enough money to purchase this upgrade")
        return
    end
    local upgradeName = cat.name
    local saveValue = cat.indexPrefix
    local savekey = cat.saveKey
    nexa.notify(source, "~g~You have purchased the ~w~"..upgradeName.." ~g~upgrade for £"..getMoneyStringFormatted(price))
    local oldmods = MySQL.asyncQuery("nexa/GetUsersVehicleMod", {user_id = user_id, spawncode = spawncode, savekey = savekey})
    local mod = "Unused #"..tostring(table.count(oldmods) + 1)
    local enabledTable = {}
    for k,data in pairs(oldmods) do
        enabledTable[tostring(data.mod)] = nexa.GetPlayerName(data.mod)
    end
    MySQL.asyncQuery("nexa/InsertNewVehicleMod",{user_id = user_id, spawncode = spawncode, savekey = savekey, savevalue = savevalue, mod = mod})
    enabledTable[mod] = "Unknown"
    TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,savekey,enabledTable)
end)

RegisterServerEvent("nexa:setValueInputList",function(spawncode,cat,oldmod,newvalue)
    local source = source
    local user_id = nexa.getUserId(source)
    cat = cfg.identifierToCategory[cat]
    local saveValue = cat.indexPrefix
    local savekey = cat.saveKey
    local oldmods = MySQL.asyncQuery("nexa/GetUsersVehicleMod", {user_id = user_id, spawncode = spawncode, savekey = savekey})
    local enabledTable = {}
    for k,data in pairs(oldmods) do
        if data.mod == tostring(newvalue) then
            nexa.notify(source, "~r~You can't set the same value as a previous one")
            return
        end
        enabledTable[tostring(data.mod)] = nexa.GetPlayerName(data.mod)
    end
    enabledTable[tostring(oldmod)] = nil
    enabledTable[tostring(newvalue)] = nexa.GetPlayerName(newvalue)
    MySQL.execute("nexa/SetNewModValue", {user_id = user_id, spawncode = spawncode, savekey = savekey, mod = newvalue, oldmod = oldmod})
    TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,savekey,enabledTable)
end)

RegisterServerEvent("nexa:stancerBuyMod", function(spawncode,mod)
    local source = source
    local user_id = nexa.getUserId(source)
    local price = cfg.stancerPrices[mod]
    if not price then
        price = 1000
    end
    if not nexa.tryFullPayment(user_id, price) then
        nexa.notify(source, "~r~You don't have enough money to purchase this upgrade")
        return
    end
    local upgradeName = mod
    nexa.notify(source, "~g~You have purchased the ~w~"..upgradeName.." ~g~upgrade for £"..getMoneyStringFormatted(price))
    MySQL.asyncQuery("nexa/InsertNewVehicleStancerMod",{user_id = user_id, spawncode = spawncode, mod = mod})
    local enabledTable = nexa.GetVehiclesStancerMods(user_id,spawncode)
    TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,"stancer",enabledTable)
end)

RegisterServerEvent("nexa:stancerSetModIndex", function(spawncode,cat,value)
    local source = source
    local user_id = nexa.getUserId(source)
    local oldmods = nexa.GetVehiclesStancerMods(user_id,spawncode)
    MySQL.asyncQuery("nexa/UpdateVehicleStancerMod",{user_id = user_id, spawncode = spawncode, mod = cat, value = value})
    local enabledTable = nexa.GetVehiclesStancerMods(user_id,spawncode)
    TriggerClientEvent('nexa:setSpecificOwnedUpgrade', source,"stancer",enabledTable)
end)

RegisterServerEvent("nexa:setBiometricUsersState")
AddEventHandler("nexa:setBiometricUsersState", function(vehNetId,table)
	local source = source
	local user_id = nexa.getUserId(source)
    local playersCurrentVehicle = NetworkGetEntityFromNetworkId(vehNetId)
    Entity(playersCurrentVehicle).state:set("biometricUsers",table,true)
end)

RegisterServerEvent("nexa:stancerSetState")
AddEventHandler("nexa:stancerSetState", function(vehNetId,stancerTable)
    local source = source
    local user_id = nexa.getUserId(source)
    local playersCurrentVehicle = NetworkGetEntityFromNetworkId(vehNetId)
    Entity(playersCurrentVehicle).state:set("stancer",stancerTable,true)
end)

RegisterServerEvent("nexa:updateNitro", function(spawncode,amount)
    local source = source
    local user_id = nexa.getUserId(source)
    exports['ghmattimysql']:execute("SELECT * FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @spawncode", {user_id = user_id, spawncode = spawncode}, function(result)
        if result ~= nil then 
            if amount < 0 then
                amount = 0
            end
            local nitro = amount
            exports['ghmattimysql']:execute("UPDATE nexa_user_vehicles SET nitro = @nitro WHERE user_id = @user_id AND vehicle = @spawncode", {spawncode = spawncode,nitro = nitro, user_id = user_id}, function() 
            end)
        end
    end)
end)