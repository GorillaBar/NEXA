MySQL.createCommand("nexa/add_id_stats", "INSERT IGNORE INTO nexa_stats_data SET user_id = @user_id, monthly_stats = @monthly_stats, total_stats = @total_stats")

local statsTable = {monthly_stats = {},total_stats = {}}

function refreshTable()
    exports["ghmattimysql"]:execute("SELECT * FROM nexa_stats_data", {}, function(rows)
        if #rows > 0 then
            for k,v in pairs(rows) do
                local name = nexa.GetPlayerName(v.user_id)
                statsTable.monthly_stats[k] = {user_id = v.user_id, name = name}
                statsTable.total_stats[k] = {user_id = v.user_id, name = name}
                for a,b in pairs(json.decode(v.monthly_stats)) do statsTable.monthly_stats[k][a] = b end
                for a,b in pairs(json.decode(v.total_stats)) do statsTable.total_stats[k][a] = b end
            end
        end
    end)
end
refreshTable()

RegisterCommand('refreshstats', function(source)
    local user_id = nexa.getUserId(source)
    if user_id == 1 then
        refreshTable()
        TriggerClientEvent("nexaDEATHUI:setStatistics", source, statsTable.monthly_stats, statsTable.total_stats, user_id)
    end
end)

AddEventHandler("playerJoining", function()
    local user_id = nexa.getUserId(source)
    local defaultStats = {arrests = 0,searches = 0,amount_fined = 0,money_seized = 0,revives = 0,bodybagged = 0,kills = 0,deaths = 0,amount_robbed = 0,jailed_time = 0,playtime = tnexa.getPlaytime(user_id)*60,weed_sales = 0,cocaine_sales = 0,meth_sales = 0,heroin_sales = 0,lsd_sales = 0,copper_sales = 0,limestone_sales = 0,gold_sales = 0,diamond_sales = 0}
    defaultStats = json.encode(defaultStats)
    MySQL.execute("nexa/add_id_stats", {user_id = user_id, monthly_stats = defaultStats, total_stats = defaultStats})
end)

RegisterNetEvent("nexa:requestStatistics")
AddEventHandler("nexa:requestStatistics",function()
    local source = source
    local user_id = nexa.getUserId(source)
    TriggerClientEvent("nexaDEATHUI:setStatistics", source, statsTable.monthly_stats, statsTable.total_stats, user_id)
end)

function tnexa.addStat(user_id, statType, amount)
    local userStats = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_stats_data WHERE user_id = @user_id", {user_id = user_id})
    local userMonthlyStats = json.decode(userStats[1].monthly_stats)
    local userTotalStats = json.decode(userStats[1].total_stats)
    userMonthlyStats[statType] = userMonthlyStats[statType] + amount
    userTotalStats[statType] = userTotalStats[statType] + amount
    exports['ghmattimysql']:execute("UPDATE nexa_stats_data SET monthly_stats = @monthly_stats, total_stats = @total_stats WHERE user_id = @user_id", {monthly_stats = json.encode(userMonthlyStats), total_stats = json.encode(userTotalStats), user_id = user_id})
end