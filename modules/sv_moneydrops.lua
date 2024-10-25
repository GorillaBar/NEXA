local lang = nexa.lang
MoneydropEntities = {}

function tnexa.MoneyDrop()
    local source = source
    Wait(100) -- wait delay for death.
    local user_id = nexa.getUserId(source)
    local money = nexa.getMoney(user_id)
    if money > 0 then
        local model = GetHashKey('prop_poly_bag_money')
        local name1 = tnexa.getDiscordName(source)
        local moneydrop = CreateObjectNoOffset(model, GetEntityCoords(GetPlayerPed(source)) + 0.5, true, true, false)
        local moneydropnetid = NetworkGetNetworkIdFromEntity(moneydrop)
        SetEntityRoutingBucket(moneydrop, GetPlayerRoutingBucket(source))
        MoneydropEntities[moneydropnetid] = {moneydrop, moneydrop, false, source}
        MoneydropEntities[moneydropnetid].Money = {}
        local ndata = nexa.getUserDataTable(user_id)
        local stored_inventory = nil;
        if nexa.tryPayment(user_id,money) then
            MoneydropEntities[moneydropnetid].Money = money
        end
    end
end

RegisterNetEvent('nexa:Moneydrop')
AddEventHandler('nexa:Moneydrop', function(netid)
    local source = source
    if MoneydropEntities[netid] and not MoneydropEntities[netid][3] and #(GetEntityCoords(MoneydropEntities[netid][1]) - GetEntityCoords(GetPlayerPed(source))) < 10.0 then
        MoneydropEntities[netid][3] = true;
        local user_id = nexa.getUserId(source)
        if user_id ~= nil then
            if MoneydropEntities[netid].Money ~= 0 then
                nexa.giveMoney(user_id,MoneydropEntities[netid].Money)
                nexaclient.notify(source,{"~g~You have taken £"..tonumber(MoneydropEntities[netid].Money)})
                tnexa.sendWebhook('moneybag-logs', 'nexa Money Bag Logs', "> Players Name: **"..tnexa.getDiscordName(source).."**\n> Players Perm ID: **"..nexa.getUserId(source).."**\n> Amount picked up: **£"..getMoneyStringFormatted(MoneydropEntities[netid].Money).."**")
                MoneydropEntities[netid].Money = 0
            end
        else
            nexaclient.notify(source,{"~r~The money drop is already being taken"})

        end
    end
end)

Citizen.CreateThread(function()
    while true do 
        Wait(100)
        for i,v in pairs(MoneydropEntities) do 
            if v.Money == 0 then
                if DoesEntityExist(v[1]) then 
                    DeleteEntity(v[1])
                    MoneydropEntities[i] = nil;
                end
            end
        end
    end
end)