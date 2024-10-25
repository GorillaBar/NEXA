local cfg=module("cfg/cfg_simeons")
local inventory=module("nexa-vehicles", "inventory")


RegisterNetEvent("nexa:refreshSimeonsPermissions")
AddEventHandler("nexa:refreshSimeonsPermissions",function()
    local source=source
    local simeonsCategories={}
    local user_id = nexa.getUserId(source)
    for k,v in pairs(cfg.simeonsCategories) do
        for a,b in pairs(v) do
            if a == "_config" then
                if b.permissionTable[1] ~= nil then
                    if nexa.hasPermission(nexa.getUserId(source),b.permissionTable[1])then
                        for c,d in pairs(v) do
                            if inventory.vehicle_chest_weights[c] then
                                table.insert(v[c],inventory.vehicle_chest_weights[c])
                            else
                                table.insert(v[c],30)
                            end
                        end
                        simeonsCategories[k] = v
                    end
                else
                    for c,d in pairs(v) do
                        if inventory.vehicle_chest_weights[c] then
                            table.insert(v[c],inventory.vehicle_chest_weights[c])
                        else
                            table.insert(v[c],30)
                        end
                    end
                    simeonsCategories[k] = v
                end
            end
        end
    end
    TriggerClientEvent("nexa:gotCarDealerInstances",source,cfg.simeonsInstances)
    TriggerClientEvent("nexa:gotCarDealerCategories",source,simeonsCategories)
end)

RegisterNetEvent('nexa:purchaseCarDealerVehicle')
AddEventHandler('nexa:purchaseCarDealerVehicle', function(vehicleclass, vehicle)
    local source = source
    local user_id = nexa.getUserId(source)
    local playerName = tnexa.getDiscordName(source)   
    for k,v in pairs(cfg.simeonsCategories[vehicleclass]) do
        if k == vehicle then
            local vehicle_name = v[1]
            local vehicle_price = v[2]
            MySQL.query("nexa/get_vehicle", {user_id = user_id, vehicle = vehicle}, function(pvehicle, affected)
                if #pvehicle > 0 then
                    nexaclient.notify(source,{"~r~Vehicle already owned."})
                else
                    if nexa.tryFullPayment(user_id, vehicle_price) then
                        nexaclient.generateUUID(source, {"plate", 5, "alphanumeric"}, function(uuid)
                            local uuid = string.upper(uuid)
                            MySQL.execute("nexa/add_vehicle", {user_id = user_id, vehicle = vehicle, registration = 'P'..uuid})
                            nexaclient.notify(source,{"~g~You paid £"..vehicle_price.." for "..vehicle_name.."."})
                            TriggerClientEvent("nexa:PlaySound", source, "money")
                        end)
                    else
                        nexaclient.notify(source,{"~r~Not enough money."})
                    end
                end
            end)
        end
    end
end)
