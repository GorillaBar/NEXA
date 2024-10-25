RegisterServerEvent('nexa:saveTattoos')
AddEventHandler('nexa:saveTattoos', function(tattooData, price)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.tryFullPayment(user_id, price) then
        nexa.setUData(user_id, "nexa:Tattoo:Data", json.encode(tattooData))
    end
end)

RegisterServerEvent('nexa:getPlayerTattoos')
AddEventHandler('nexa:getPlayerTattoos', function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:Tattoo:Data", function(data)
        if data ~= nil then
            TriggerClientEvent('nexa:setTattoos', source, json.decode(data))
        end
    end)
end)
