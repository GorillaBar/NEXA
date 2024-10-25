RegisterNetEvent('nexa:purchaseHighRollersMembership')
AddEventHandler('nexa:purchaseHighRollersMembership', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if not nexa.hasGroup(user_id, 'Highroller') then
        if nexa.tryFullPayment(user_id,10000000) then
            nexa.addUserGroup(user_id, 'Highroller')
            nexaclient.notify(source, {'~g~You have purchased the High Rollers membership.'})
            tnexa.sendWebhook('purchase-highrollers',"nexa Purchased Highrollers Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**")
        else
            nexaclient.notify(source, {'~r~You do not have enough money to purchase this membership.'})
        end
    else
        nexaclient.notify(source, {"~r~You already have High Roller's License."})
    end
end)

RegisterNetEvent('nexa:removeHighRollersMembership')
AddEventHandler('nexa:removeHighRollersMembership', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasGroup(user_id, 'Highroller') then
        nexa.removeUserGroup(user_id, 'Highroller')
        nexaclient.notify(source, {'~g~You have removed the High Rollers membership.'})
    else
        nexaclient.notify(source, {"~r~You do not have High Roller's License."})
    end
end)

RegisterCommand('casinounban', function(source,args)
    local source = source
    local user_id = nexa.getUserId(source)
    local theirSource = nexa.getUserSource(tonumber(args[1]))
    if user_id == 1 then
        if theirSource ~= nil then
            nexaclient.casinoBan(theirSource, {})
            nexaclient.notify(source, {'~g~Successfully unbanned ID: '..args[1]..' from the casino.'})
        else
            nexaclient.notify(source, {'~r~This player is not online.'})
        end
    end
end)

RegisterNetEvent('nexa:getCasinoStats')
AddEventHandler('nexa:getCasinoStats', function()
    local source = source
    local user_id = nexa.getUserId(source)
    local data = json.decode(exports['ghmattimysql']:executeSync("SELECT * FROM nexa_casino_chips WHERE user_id = @user_id", {user_id = user_id})[1].casino_stats)
    if data == nil then
        data = {total_bets = 0,total_bets_won = 0,total_bets_lost = 0,total_chips_won = 0,total_chips_lost = 0}
    end
    local function formatProfit(a,b)
        if a > b then
            return '~b~£'..getMoneyStringFormatted(a-b)
        else
            return '~b~-£'..getMoneyStringFormatted(b-a)
        end
    end
    local casinoStats = {
        [1] = 'Total Bets ~b~'..getMoneyStringFormatted(data.total_bets),
        [2] = 'Wins ~b~'..getMoneyStringFormatted(data.total_bets_won),
        [3] = 'Losses ~b~'..getMoneyStringFormatted(data.total_bets_lost),
        [4] = '',
        [5] = 'Won ~b~£'..getMoneyStringFormatted(data.total_chips_won),
        [6] = 'Lost ~b~£'..getMoneyStringFormatted(data.total_chips_lost),
        [7] = 'Casino Profit '..formatProfit(data.total_chips_won,data.total_chips_lost)
    }
    TriggerClientEvent('nexa:setCasinoStats', source, casinoStats)
end)

function tnexa.updateCasinoStats(user_id, amount, won)
    local data = json.decode(exports['ghmattimysql']:executeSync("SELECT * FROM nexa_casino_chips WHERE user_id = @user_id", {user_id = user_id})[1].casino_stats)
    if data == nil then
        data = {total_bets = 0,total_bets_won = 0,total_bets_lost = 0,total_chips_won = 0,total_chips_lost = 0}
    end
    if won then
        data.total_bets_won = data.total_bets_won + 1
        data.total_chips_won = data.total_chips_won + amount
    else
        data.total_bets_lost = data.total_bets_lost + 1
        data.total_chips_lost = data.total_chips_lost + amount
    end
    data.total_bets = data.total_bets + 1
    exports['ghmattimysql']:execute("UPDATE nexa_casino_chips SET casino_stats = @casino_stats WHERE user_id = @user_id", {casino_stats = json.encode(data), user_id = user_id})
end