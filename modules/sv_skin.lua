RegisterNetEvent("nexa:saveFaceData")
AddEventHandler("nexa:saveFaceData", function(faceSaveData)
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.setUData(user_id, "nexa:Face:Data", json.encode(faceSaveData))
end)

RegisterNetEvent("nexa:saveClothingHairData") -- this updates hair from clothing stores
AddEventHandler("nexa:saveClothingHairData", function(hairtype, haircolour)
    local source = source
    local user_id = nexa.getUserId(source)
    local facesavedata = {}
    nexa.getUData(user_id, "nexa:Face:Data", function(data)
        if data ~= nil and data ~= 0 and hairtype ~= nil and haircolour ~= nil then
            facesavedata = json.decode(data)
            if facesavedata == nil then
                facesavedata = {}
            end
            facesavedata["hair"] = hairtype
            facesavedata["haircolor"] = haircolour
            nexa.setUData(user_id, "nexa:Face:Data", json.encode(facesavedata))
        end
    end)
end)

RegisterNetEvent("nexa:getPlayerHairstyle")
AddEventHandler("nexa:getPlayerHairstyle", function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:Face:Data", function(data)
        if data ~= nil and data ~= 0 then
            TriggerClientEvent("nexa:setHairstyle", source, json.decode(data))
        end
    end)
end)

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    SetTimeout(1000, function() 
        local source = source
        local user_id = nexa.getUserId(source)
        nexa.getUData(user_id, "nexa:Face:Data", function(data)
            if data ~= nil and data ~= 0 then
                TriggerClientEvent("nexa:setHairstyle", source, json.decode(data))
            end
        end)
    end)
end)