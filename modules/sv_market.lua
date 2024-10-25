local marketLocations = {
    {"standard", vector3(128.1410369873, -1286.1120605469, 29.281036376953)},
    {"standard", vector3(-47.522762298584, -1756.85717773438, 29.4210109710693)},
    {"standard", vector3(25.7454013824463, -1345.26232910156, 29.4970207214355)},
    {"standard", vector3(1135.57678222656, -981.78125, 46.4157981872559)},
    {"standard", vector3(1163.53820800781, -323.541320800781, 69.2050552368164)},
    {"standard", vector3(374.190032958984, 327.506713867188, 103.566368103027)},
    {"standard", vector3(2555.35766601563, 382.16845703125, 108.622947692871)},
    {"standard", vector3(2676.76733398438, 3281.57788085938, 55.2411231994629)},
    {"standard", vector3(1960.50793457031, 3741.84008789063, 32.3437385559082)},
    {"standard", vector3(1393.23828125, 3605.171875, 34.9809303283691)},
    {"standard", vector3(1166.18151855469, 2709.35327148438, 38.15771484375)},
    {"standard", vector3(547.987609863281, 2669.7568359375, 42.1565132141113)},
    {"standard", vector3(1698.30737304688, 4924.37939453125, 42.0636749267578)},
    {"standard", vector3(1729.54443359375, 6415.76513671875, 35.0372200012207)},
    {"standard", vector3(-3243.9013671875, 1001.40405273438, 12.8307056427002)},
    {"standard", vector3(-2967.8818359375, 390.78662109375, 15.0433149337769)},
    {"standard", vector3(-3041.17456054688, 585.166198730469, 7.90893363952637)},
    {"standard", vector3(-1820.55725097656, 792.770568847656, 138.113250732422)},
    {"standard", vector3(-1486.76574707031, -379.553985595703, 40.163387298584)},
    {"standard", vector3(-1223.18127441406, -907.385681152344, 12.3263463973999)},
    {"standard", vector3(-707.408996582031, -913.681701660156, 19.2155857086182)},
    {"standard", vector3(153.7199, 6650.347, 31.72023)},
    {"rebel", vector3(4999.479, -5164.681, 2.764392)}
}
local marketInfo = {
    {
        type = "standard", 
        prices = {
            ["Morphine"] = 50000, 
        }, 
        descriptions = {
            ["Morphine"] = {"Morphine", "Morphine", "Recovers a small amount of health"}, 
        }
    },
    {
        type = "rebel", 
        prices = {
            ["Headbag"] = 10000, 
            ["boltcutters"] = 500000
        }, 
        descriptions = {
            ["Headbag"] = {"Headbag", "Headbag", "Blinds a player"}, 
            ["boltcutters"] = {"Boltcutters", "boltcutters", "Cuts through door locks"}
        }
    }
}
local marketPrices = {}
local marketDescriptions = {}
for k,v in pairs(marketInfo) do
    marketPrices[v.type] = v.prices
    marketDescriptions[v.type] = v.descriptions
end
AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent('nexa:buildMarketMenus', source, marketLocations)
        TriggerClientEvent('nexa:buildMarkets', source, marketPrices, marketDescriptions)
    end
end)

RegisterNetEvent("nexa:requestToBuyItem")
AddEventHandler("nexa:requestToBuyItem", function(item, amount)
    local user_id = nexa.getUserId(source)
    for k,v in pairs(marketInfo) do
        for i, p in pairs(v.prices) do
            if item == i then
                local price = p * amount
                if nexa.getInventoryWeight(user_id) + amount <= nexa.getInventoryMaxWeight(user_id) then
                    if nexa.tryFullPayment(user_id, price) then
                        nexa.giveInventoryItem(user_id, item, amount, false)
                        nexaclient.notify(source, {"~g~Paid ".. '£' ..getMoneyStringFormatted(price)..'.'})
                        TriggerClientEvent("nexa:playItemBoughtSound", source)
                    else
                        nexaclient.notify(source, {"~r~Not enough money."})
                    end
                else
                    nexaclient.notify(source,{'~r~Not enough inventory space.'})
                end
            end
        end
    end
end)