MySQL.createCommand("nexa/update_vehicleplate","UPDATE nexa_user_vehicles SET vehicle_plate = @registration WHERE user_id = @user_id AND vehicle = @vehicle")
MySQL.createCommand("nexa/add_numplate","INSERT INTO nexa_owned_plates (user_id, plate_text) VALUES (@user_id, @plate_text)")
MySQL.createCommand("nexa/update_numplate","UPDATE nexa_owned_plates SET vehicle_used_on = @vehicle WHERE user_id = @user_id AND plate_text = @plate_text")


local forbiddenNames = { "%^1", "%^2", "%^3", "%^4", "%^5", "%^6", "%^7", "%^8", "%^9", "%^%*", "%^_", "%^=", "%^%~", "admin", "nigger", "cunt", "faggot", "fuck", "fucker", "fucking", "anal", "stupid", "damn", "cock", "cum", "dick", "dipshit", "dildo", "douchbag", "douch", "kys", "jerk", "jerkoff", "gay", "homosexual", "lesbian", "suicide", "mothafucka", "negro", "pussy", "queef", "queer", "weeb", "retard", "masterbate", "suck", "tard", "allahu akbar", "terrorist", "twat", "vagina", "wank", "whore", "wanker", "n1gger", "f4ggot", "n0nce", "d1ck", "h0m0", "n1gg3r", "h0m0s3xual", "free up mandem", "nazi", "hitler", "cheater", "cheating"}

function getOwnedPlates(user_id)
    local ownedPlates = {}
    local plateSQL = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_owned_plates WHERE user_id = @user_id", {user_id = user_id})
    for k,v in pairs(plateSQL) do
        table.insert(ownedPlates, {license_plate = v.plate_text, vehicle = v.vehicle_used_on})
    end
    return ownedPlates
end

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent('nexa:sendOwnedLicensePlates', source, getOwnedPlates(user_id))
    end
end)

RegisterNetEvent("nexa:checkPlateAvailability")
AddEventHandler("nexa:checkPlateAvailability", function(plate)
	local source = source
    local user_id = nexa.getUserId(source)
    local checkPlate = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_user_vehicles WHERE vehicle_plate = @plate", {plate = plate})
    if #checkPlate > 0 then 
        nexaclient.notify(source, {"~r~The plate "..plate.." is already taken."})
    else
        nexaclient.notify(source, {"~g~The plate "..plate.." is available."})
    end
end)

RegisterNetEvent("nexa:checkPhoneNumberAvailability")
AddEventHandler("nexa:checkPhoneNumberAvailability", function(number)
	local source = source
    local user_id = nexa.getUserId(source)
	local checkNumber = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_user_identities WHERE phone = @number", {number = number})
    if #checkNumber > 0 then 
        nexaclient.notify(source, {"~r~That number is already taken."})
    else
        nexaclient.notify(source, {"~g~That number is available."})
    end
end)

RegisterNetEvent("nexa:setPhoneNumber")
AddEventHandler("nexa:setPhoneNumber", function(number)
	local source = source
    local user_id = nexa.getUserId(source)
    return nexaclient.notify(source, {"~r~This feature is not yet implemented."})
end)

RegisterNetEvent("nexa:startGetLicensePlate")
AddEventHandler("nexa:startGetLicensePlate", function(plate)
	local source = source
    local user_id = nexa.getUserId(source)
    local checkPlate = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_owned_plates WHERE plate_text = @plate", {plate = plate})
    if #checkPlate > 0 then 
        nexaclient.notify(source, {"~r~The plate "..plate.." is already taken."})
    else
        for name in pairs(forbiddenNames) do
            if plate == forbiddenNames[name] then
                nexaclient.notify(source,{"~r~You cannot have this plate."})
                return
            end
        end
        tnexa.getStoreOwned(user_id, function(storeData)
            if storeData == nil then return nexaclient.notify(source,{"~r~You don't have a license plate in your store inventory."}) end
            for k,v in pairs(storeData) do
                if v == "license_plate" then
                    MySQL.execute("nexa/add_numplate", {user_id = user_id, plate_text = plate})
                    TriggerClientEvent("nexa:PlaySound", source, "apple")
                    TriggerClientEvent("nexa:addNewOwnedLicensePlate", source, plate)
                    nexaclient.notify(source, {"~g~Purchased plate "..plate.."."})
                    tnexa.deletePackage(user_id, k, v)
                    Wait(100)
                    tnexa.getStoreOwned(user_id, function(storeOwned)
                        TriggerClientEvent('nexa:sendStoreItems', source, storeOwned)
                    end)
                    return
                end
            end
            return nexaclient.notify(source,{"~r~You don't have a license plate in your store inventory."})
        end)
    end
end)

RegisterNetEvent("nexa:applyLicensePlate")
AddEventHandler("nexa:applyLicensePlate", function(vehicle, plate)
	local source = source
    local user_id = nexa.getUserId(source)
    local checkOwnsPlate = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_owned_plates WHERE plate_text = @plate and user_id = @user_id", {plate = plate, user_id = user_id})
    local checkIfVehicleHasPlate = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_owned_plates WHERE vehicle_used_on = @vehicle and user_id = @user_id", {vehicle = vehicle, user_id = user_id})
    if #checkOwnsPlate > 0 then
        if #checkIfVehicleHasPlate > 0 then
            if checkIfVehicleHasPlate[1].plate_text ~= '' then
                MySQL.execute("nexa/update_numplate", {user_id = user_id, plate_text = checkIfVehicleHasPlate[1].plate_text, vehicle = ''})
            end
        end
        nexaclient.notify(source,{"~g~Changed plate of "..vehicle.." to "..plate})
        MySQL.execute("nexa/update_vehicleplate", {user_id = user_id, registration = plate, vehicle = vehicle})
        MySQL.execute("nexa/update_numplate", {user_id = user_id, plate_text = plate, vehicle = vehicle})
        TriggerClientEvent("nexa:PlaySound", source, "apple")
        Wait(50)
        TriggerClientEvent('nexa:sendOwnedLicensePlates', source, getOwnedPlates(user_id))
    end
end)

RegisterNetEvent("nexa:beginSellLicenseToPlayer")
AddEventHandler("nexa:beginSellLicenseToPlayer", function(plate)
	local source = source
    local user_id = nexa.getUserId(source)
    local checkOwnsPlate = exports["ghmattimysql"]:executeSync("SELECT * FROM nexa_owned_plates WHERE plate_text = @plate and user_id = @user_id", {plate = plate, user_id = user_id})
    if #checkOwnsPlate > 0 then
        nexaclient.getNearestPlayers(source,{10},function(nplayers)
            usrList = ""
            for k, v in pairs(nplayers) do
                usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | "
            end
            if usrList ~= "" then
                nexa.prompt(source,"Players Nearby: " .. usrList .. "","",function(source, tempid)
                    local target_id = nexa.getUserId(tonumber(tempid))
                    if target_id ~= nil and target_id ~= "" then
                        local target = nexa.getUserSource(tonumber(target_id))
                        if target ~= nil then
                            nexa.prompt(source,"Price £: ","",function(source, amount)
                                if tonumber(amount) and tonumber(amount) > 0 then
                                    nexa.request(target,tnexa.getDiscordName(source).." wants to sell the plate: " ..plate.. " for £"..getMoneyStringFormatted(amount), 30, function(target,ok)
                                        if ok then
                                            if nexa.tryFullPayment(nexa.getUserId(target),tonumber(amount)) then
                                                nexaclient.notify(source, {"~g~Successfully sold plate."})
                                                nexaclient.notify(target, {"~g~Successfully bought plate."})
                                                nexa.giveBankMoney(user_id,tonumber(amount))
                                                MySQL.execute("nexa/update_numplate", {user_id = nexa.getUserId(target), plate_text = plate, vehicle = ''})
                                                Wait(50)
                                                TriggerClientEvent('nexa:sendOwnedLicensePlates', source, getOwnedPlates(user_id))
                                                TriggerClientEvent('nexa:sendOwnedLicensePlates', target, getOwnedPlates(nexa.getUserId(target)))
                                            else
                                                nexaclient.notify(source,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"})
                                                nexaclient.notify(target,{"~r~You don't have enough money!"})
                                            end
                                        else
                                            nexaclient.notify(source,{"~r~"..tnexa.getDiscordName(target).." has refused to buy the plate."})
                                            nexaclient.notify(target,{"~r~You have refused to buy the plate."})
                                        end
                                    end)
                                else
                                    nexaclient.notify(source,{"~r~Price of subscription must be a number."})
                                end
                            end)
                        end
                    end
                end)
            end
        end)
    end
end)