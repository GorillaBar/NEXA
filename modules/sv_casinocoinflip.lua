local coinflipTables = {
    [1] = false,
    [2] = false,
    [5] = false,
    [6] = false,
}

local linkedTables = {
    [1] = 2,
    [2] = 1,
    [5] = 6,
    [6] = 5,
}

local coinflipGameInProgress = {}
local coinflipGameData = {}

local betId = 0

function giveChips(source,amount)
    local user_id = nexa.getUserId(source)
    MySQL.execute("nexa/add_chips", {user_id = user_id, amount = amount})
    TriggerClientEvent('nexa:chipsUpdated', source)
end

AddEventHandler('playerDropped', function (reason)
    local source = source
    for k,v in pairs(coinflipTables) do
        if v == source then
            coinflipTables[k] = false
            coinflipGameData[k] = nil
        end
    end
end)

RegisterNetEvent("nexa:requestCoinflipTableData")
AddEventHandler("nexa:requestCoinflipTableData", function()   
    local source = source
    TriggerClientEvent("nexa:sendCoinflipTableData",source,coinflipTables)
end)

RegisterNetEvent("nexa:requestSitAtCoinflipTable")
AddEventHandler("nexa:requestSitAtCoinflipTable", function(chairId)
    local source = source
    if source ~= nil then
        for k,v in pairs(coinflipTables) do
            if v == source then
                coinflipTables[k] = false
                return
            end
        end
        coinflipTables[chairId] = source
        local currentBetForThatTable = coinflipGameData[chairId]
        TriggerClientEvent("nexa:sendCoinflipTableData",-1,coinflipTables)
        TriggerClientEvent("nexa:sitAtCoinflipTable",source,chairId,currentBetForThatTable)
    end
end)

RegisterNetEvent("nexa:leaveCoinflipTable")
AddEventHandler("nexa:leaveCoinflipTable", function(chairId)
    local source = source
    if source ~= nil then 
        for k,v in pairs(coinflipTables) do 
            if v == source then 
                coinflipTables[k] = false
                coinflipGameData[k] = nil
            end
        end
        TriggerClientEvent("nexa:sendCoinflipTableData",-1,coinflipTables)
    end
end)

RegisterNetEvent("nexa:proposeCoinflip")
AddEventHandler("nexa:proposeCoinflip",function(betAmount)
    local source = source
    local user_id = nexa.getUserId(source)
    betId = betId+1
    if betAmount ~= nil then 
        if coinflipGameData[betId] == nil then
            coinflipGameData[betId] = {}
        end
        if not coinflipGameInProgress[betId] then
            if tonumber(betAmount) then
                betAmount = tonumber(betAmount)
                if betAmount >= 100000 then
                    MySQL.query("nexa/get_chips", {user_id = user_id}, function(rows, affected)
                        chips = rows[1].chips
                        if chips >= betAmount then
                            TriggerClientEvent('nexa:chipsUpdated', source)
                            if coinflipGameData[betId][source] == nil then
                                coinflipGameData[betId][source] = {}
                            end
                            coinflipGameData[betId] = {betId = betId, betAmount = betAmount, user_id = user_id}
                            for k,v in pairs(coinflipTables) do
                                if v == source then
                                    TriggerClientEvent('nexa:addCoinflipProposal', source, betId, {betId = betId, betAmount = betAmount, user_id = user_id})
                                    if coinflipTables[linkedTables[k]] then
                                        TriggerClientEvent('nexa:addCoinflipProposal', coinflipTables[linkedTables[k]], betId, {betId = betId, betAmount = betAmount, user_id = user_id})
                                    end
                                end
                            end
                            nexaclient.notify(source,{"~g~Bet placed: " .. getMoneyStringFormatted(betAmount) .. " chips."})
                        else 
                            nexaclient.notify(source,{"~r~Not enough chips!"})
                        end
                    end)
                else
                    nexaclient.notify(source,{'~r~Minimum bet at this table is £100,000.'})
                    return
                end
            end
        end
    else
       nexaclient.notify(source,{"~r~Error betting!"})
    end
end)

RegisterNetEvent("nexa:requestCoinflipTableData")
AddEventHandler("nexa:requestCoinflipTableData", function()   
    local source = source
    TriggerClientEvent("nexa:sendCoinflipTableData",source,coinflipTables)
end)

RegisterNetEvent("nexa:cancelCoinflip")
AddEventHandler("nexa:cancelCoinflip", function()   
    local source = source
    local user_id = nexa.getUserId(source)
    for k,v in pairs(coinflipGameData) do
        if v.user_id == user_id then
            coinflipGameData[k] = nil
            TriggerClientEvent("nexa:cancelCoinflipBet",-1,k)
        end
    end
end)

RegisterNetEvent("nexa:acceptCoinflip")
AddEventHandler("nexa:acceptCoinflip", function(gameid)   
    local source = source
    local user_id = nexa.getUserId(source)
    for k,v in pairs(coinflipGameData) do
        if v.betId == gameid then
            MySQL.query("nexa/get_chips", {user_id = user_id}, function(rows, affected)
                chips = rows[1].chips
                if chips >= v.betAmount then
                    MySQL.execute("nexa/remove_chips", {user_id = user_id, amount = v.betAmount})
                    TriggerClientEvent('nexa:chipsUpdated', source)
                    MySQL.execute("nexa/remove_chips", {user_id = v.user_id, amount = v.betAmount})
                    TriggerClientEvent('nexa:chipsUpdated', nexa.getUserSource(v.user_id))
                    local coinFlipOutcome = math.random(0,1)
                    if coinFlipOutcome == 0 then
                        local game = {amount = v.betAmount, winner = tnexa.getDiscordName(source), loser = tnexa.getDiscordName(nexa.getUserSource(v.user_id))}
                        TriggerClientEvent('nexa:coinflipOutcome', source, true, game)
                        TriggerClientEvent('nexa:coinflipOutcome', nexa.getUserSource(v.user_id), false, game)
                        Wait(10000)
                        MySQL.execute("nexa/add_chips", {user_id = user_id, amount = v.betAmount*2})
                        TriggerClientEvent('nexa:chipsUpdated', source)
                        tnexa.sendWebhook('coinflip-outcomes',"nexa Coinflip Logs", "> Winner Name: **"..tnexa.getDiscordName(source).."**\n> Winner TempID: **"..source.."**\n> Winner PermID: **"..user_id.."**\n> Loser Name: **"..tnexa.getDiscordName(nexa.getUserSource(v.user_id)).."**\n> Loser TempID: **"..nexa.getUserSource(v.user_id).."**\n> Loser PermID: **"..v.user_id.."**\n> Amount: **"..getMoneyStringFormatted(v.betAmount).."**")
                        TriggerClientEvent('chatMessage', -1, "^7Diamond Casino Coinflip |", { 128, 128, 128 }, ""..tnexa.getDiscordName(source).." has WON "..getMoneyStringFormatted(v.betAmount).." from "..tnexa.getDiscordName(nexa.getUserSource(v.user_id)), "alert")
                        tnexa.updateCasinoStats(user_id, v.betAmount, true)
                        tnexa.updateCasinoStats(v.user_id, v.betAmount, false)
                    else
                        local game = {amount = v.betAmount, winner = tnexa.getDiscordName(nexa.getUserSource(v.user_id)), loser = tnexa.getDiscordName(source)}
                        TriggerClientEvent('nexa:coinflipOutcome', source, false, game)
                        TriggerClientEvent('nexa:coinflipOutcome', nexa.getUserSource(v.user_id), true, game)
                        Wait(10000)
                        MySQL.execute("nexa/add_chips", {user_id = v.user_id, amount = v.betAmount*2})
                        TriggerClientEvent('nexa:chipsUpdated', nexa.getUserSource(v.user_id))
                        tnexa.sendWebhook('coinflip-outcomes',"nexa Coinflip Logs", "> Winner Name: **"..tnexa.getDiscordName(nexa.getUserSource(v.user_id)).."**\n> Winner TempID: **"..nexa.getUserSource(v.user_id).."**\n> Winner PermID: **"..v.user_id.."**\n> Loser Name: **"..tnexa.getDiscordName(source).."**\n> Loser TempID: **"..source.."**\n> Loser PermID: **"..user_id.."**\n> Amount: **"..getMoneyStringFormatted(v.betAmount).."**")
                        TriggerClientEvent('chatMessage', -1, "^7Diamond Casino Coinflip |", { 128, 128, 128 }, ""..tnexa.getDiscordName(nexa.getUserSource(v.user_id)).." has WON "..getMoneyStringFormatted(v.betAmount).." from "..tnexa.getDiscordName(source), "alert")
                        tnexa.updateCasinoStats(user_id, v.betAmount, false)
                        tnexa.updateCasinoStats(v.user_id, v.betAmount, true)
                    end
                else 
                    nexaclient.notify(source,{"~r~Not enough chips!"})
                end
            end)
        end
    end
end)

RegisterCommand('tables', function(source)
    print(json.encode(coinflipTables))
end)