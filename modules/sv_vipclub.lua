MySQL.createCommand("subscription/set_plushours","UPDATE nexa_subscriptions SET plushours = @plushours WHERE user_id = @user_id")
MySQL.createCommand("subscription/set_plathours","UPDATE nexa_subscriptions SET plathours = @plathours WHERE user_id = @user_id")
MySQL.createCommand("subscription/set_lastused","UPDATE nexa_subscriptions SET last_used = @last_used WHERE user_id = @user_id")
MySQL.createCommand("subscription/get_subscription","SELECT * FROM nexa_subscriptions WHERE user_id = @user_id")
MySQL.createCommand("subscription/get_all_active_subscriptions","SELECT * FROM nexa_subscriptions WHERE plushours > 0 OR plathours > 0")
MySQL.createCommand("subscription/add_id", "INSERT IGNORE INTO nexa_subscriptions SET user_id = @user_id, plushours = 0, plathours = 0, last_used = ''")

AddEventHandler("playerJoining", function()
    local user_id = nexa.getUserId(source)
    MySQL.execute("subscription/add_id", {user_id = user_id})
end)

function tnexa.getSubscriptions(user_id,cb)
    MySQL.query("subscription/get_subscription", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
           cb(true, rows[1].plushours, rows[1].plathours, rows[1].last_used)
        else
            cb(false)
        end
    end)
end

RegisterNetEvent("nexa:getPlayerSubscription")
AddEventHandler("nexa:getPlayerSubscription", function()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
        if cb then
            TriggerClientEvent('nexa:setVIPClubData', source, plushours, plathours)
        end
    end)
end)

RegisterNetEvent("nexa:beginSellSubscriptionToPlayer")
AddEventHandler("nexa:beginSellSubscriptionToPlayer", function(subtype)
    local user_id = nexa.getUserId(source)
    local player = nexa.getUserSource(user_id)
    nexaclient.getNearestPlayers(player,{15},function(nplayers) --get nearest players
        usrList = ""
        for k, v in pairs(nplayers) do
            usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | " --add ids to usrList
        end
        if usrList ~= "" then
            nexa.prompt(player,"Players Nearby: " .. usrList .. "","",function(player, tempid) --ask for id
                local target_id = nexa.getUserId(tonumber(tempid))
                if target_id ~= nil and target_id ~= "" then --validation
                    local target = nexa.getUserSource(tonumber(target_id)) --get source of the new owner id
                    if target ~= nil then
                        nexa.prompt(player,"Number of days ","",function(player, hours) -- ask for number of hours
                            if tonumber(hours) and tonumber(hours) > 0 then
                                MySQL.query("subscription/get_subscription", {user_id = user_id}, function(rows, affected)
                                    local lastUsed = rows[1].last_used
                                    sellerplushours = rows[1].plushours
                                    sellerplathours = rows[1].plathours
                                    if lastUsed == '' or (os.time() >= tonumber(lastUsed+24*60*60*7)) -- If kit not used or over 7 days ago 
                                    or (subtype == 'Plus' and sellerplushours >= 168) -- If selling plus and more than 7 days left
                                    or (subtype == 'Platinum' and sellerplathours >= 168) then -- If selling platinum and more than 7 days left
                                        if (subtype == 'Plus' and sellerplushours >= tonumber(hours)*24) or (subtype == 'Platinum' and sellerplathours >= tonumber(hours)*24) then
                                            nexa.prompt(player,"Price £: ","",function(player, amount) --ask for price
                                                if tonumber(amount) and tonumber(amount) >= 0 then
                                                    nexa.request(target,tnexa.getDiscordName(player).." wants to sell: " ..hours.. " days of "..subtype.." subscription for £"..getMoneyStringFormatted(amount), 30, function(target,ok) --request player if they want to buy sub
                                                        if ok then --bought
                                                            MySQL.query("subscription/get_subscription", {user_id = nexa.getUserId(target)}, function(rows, affected)
                                                                if subtype == "Plus" then
                                                                    if nexa.tryFullPayment(nexa.getUserId(target),tonumber(amount)) then
                                                                        MySQL.execute("subscription/set_plushours", {user_id = nexa.getUserId(target), plushours = rows[1].plushours + tonumber(hours)*24})
                                                                        MySQL.execute("subscription/set_plushours", {user_id = user_id, plushours = sellerplushours - tonumber(hours)*24})
                                                                        nexaclient.notify(player,{'~g~You have sold '..hours..' days of '..subtype..' subscription to '..tnexa.getDiscordName(target)..' for £'..getMoneyStringFormatted(amount)})
                                                                        nexaclient.notify(target, {'~g~'..tnexa.getDiscordName(player)..' has sold '..hours..' days of '..subtype..' subscription to you for £'..getMoneyStringFormatted(amount)})
                                                                        nexa.giveBankMoney(user_id,tonumber(amount))
                                                                        nexa.updateInvCap(nexa.getUserId(target), 40)
                                                                    else
                                                                        nexaclient.notify(player,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"}) --notify original owner
                                                                        nexaclient.notify(target,{"~r~You don't have enough money!"}) --notify new owner
                                                                    end
                                                                elseif subtype == "Platinum" then
                                                                    if nexa.tryFullPayment(nexa.getUserId(target),tonumber(amount)) then
                                                                        MySQL.execute("subscription/set_plathours", {user_id = nexa.getUserId(target), plathours = rows[1].plathours + tonumber(hours)*24})
                                                                        MySQL.execute("subscription/set_plathours", {user_id = user_id, plathours = sellerplathours - tonumber(hours)*24})
                                                                        nexaclient.notify(player,{'~g~You have sold '..hours..' days of '..subtype..' subscription to '..tnexa.getDiscordName(target)..' for £'..getMoneyStringFormatted(amount)})
                                                                        nexaclient.notify(target, {'~g~'..tnexa.getDiscordName(player)..' has sold '..hours..' days of '..subtype..' subscription to you for £'..getMoneyStringFormatted(amount)})
                                                                        nexa.giveBankMoney(user_id,tonumber(amount))
                                                                        nexa.updateInvCap(nexa.getUserId(target), 50)
                                                                        TriggerClientEvent('nexa:refreshGunStorePermissions', target)
                                                                    else
                                                                        nexaclient.notify(player,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"}) --notify original owner
                                                                        nexaclient.notify(target,{"~r~You don't have enough money!"}) --notify new owner
                                                                    end
                                                                end
                                                            end)
                                                        else
                                                            nexaclient.notify(player,{"~r~"..tnexa.getDiscordName(target).." has refused to buy " ..hours.. " days of "..subtype.." subscription for £"..getMoneyStringFormatted(amount)}) --notify owner that refused
                                                            nexaclient.notify(target,{"~r~You have refused to buy " ..hours.. " days of "..subtype.." subscription for £"..getMoneyStringFormatted(amount)}) --notify new owner that refused
                                                        end
                                                    end)
                                                else
                                                    nexaclient.notify(player,{"~r~Price of subscription must be a number."})
                                                end
                                            end)
                                        else
                                            nexaclient.notify(player,{"~r~You do not have "..hours.." days of "..subtype.."."})
                                        end
                                    else
                                        nexaclient.notify(player,{"~r~You are required to have at least 7 days if you have used a kit."})
                                    end
                                end)
                            else
                                nexaclient.notify(player,{"~r~Number of days must be a number."})
                            end
                        end)
                    else
                        nexaclient.notify(player,{"~r~That Temp ID seems to be invalid!"}) --couldnt find Temp ID
                    end
                else
                    nexaclient.notify(player,{"~r~No Temp ID selected!"}) --no Temp ID selected
                end
            end)
        else
            nexaclient.notify(player,{"~r~No players nearby!"}) --no players nearby
        end
    end)
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        MySQL.query("subscription/get_all_active_subscriptions", {}, function(rows, affected)
            if #rows > 0 then
                for k,v in pairs(rows) do
                    local plushours = v.plushours
                    local plathours = v.plathours
                    local user_id = v.user_id
                    local user = nexa.getUserSource(user_id)
                    if plushours >= 1/60 then
                        MySQL.execute("subscription/set_plushours", {user_id = user_id, plushours = plushours-1/60})
                    else
                        MySQL.execute("subscription/set_plushours", {user_id = user_id, plushours = 0})
                    end
                    if plathours >= 1/60 then
                        MySQL.execute("subscription/set_plathours", {user_id = user_id, plathours = plathours-1/60})
                    else
                        MySQL.execute("subscription/set_plathours", {user_id = user_id, plathours = 0})
                    end
                    if user ~= nil then
                        TriggerClientEvent('nexa:setVIPClubData', user, plushours, plathours)
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent("nexa:claimWeeklyKit")
AddEventHandler("nexa:claimWeeklyKit", function()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.getSubscriptions(user_id, function(cb, plushours, plathours, last_used)
        if cb then
            if plathours >= 168 or plushours >= 168 then
                if last_used == '' or (os.time() >= tonumber(last_used+24*60*60*7)) then
                    if plathours >= 168 then
                        if nexa.getInventoryWeight(user_id) + 50 <= nexa.getInventoryMaxWeight(user_id) then
                            nexa.giveInventoryItem(user_id, "Morphine", 5, true)
                            nexa.giveInventoryItem(user_id, "Taco", 5, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_M1911", 1, true)
                            nexa.giveInventoryItem(user_id, "9mm Bullets", 250, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_OLYMPIA", 1, true)
                            nexa.giveInventoryItem(user_id, "12 Gauge Bullets", 250, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_UMP45", 1, true)
                            nexa.giveInventoryItem(user_id, "9mm Bullets", 250, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_AK200", 1, true)
                            nexa.giveInventoryItem(user_id, "7.62mm Bullets", 250, true)
                            nexaclient.setArmour(source, {100, true})
                            MySQL.execute("subscription/set_lastused", {user_id = user_id, last_used = os.time()})
                        else
                            nexaclient.notify(source,{"~r~You do not have enough space to redeem your kit."})
                        end
                    elseif plushours >= 168 then
                        if nexa.getInventoryWeight(user_id) + 27.5 <= nexa.getInventoryMaxWeight(user_id) then
                            nexa.giveInventoryItem(user_id, "Morphine", 5, true)
                            nexa.giveInventoryItem(user_id, "Taco", 5, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_M1911", 1, true)
                            nexa.giveInventoryItem(user_id, "9mm Bullets", 250, true)
                            nexa.giveInventoryItem(user_id, "wbody|WEAPON_UMP45", 1, true)
                            nexa.giveInventoryItem(user_id, "9mm Bullets", 250, true)
                            nexaclient.setArmour(source, {100, true})
                            MySQL.execute("subscription/set_lastused", {user_id = user_id, last_used = os.time()})
                        else
                            nexaclient.notify(source,{"~r~You do not have enough space to redeem your kit."})
                        end
                    else
                        nexaclient.notify(source,{"~r~You need at least 1 week of subscription to redeem the kit."})
                    end
                else
                    nexaclient.notify(source,{"~r~You can only claim your weekly kit once a week."})
                end
            else
                nexaclient.notify(source,{"~r~You require at least 1 week of a subscription to claim a kit."})
            end
        end
    end)
end)

RegisterNetEvent("nexa:fuelAllVehicles")
AddEventHandler("nexa:fuelAllVehicles", function()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
        if cb then
            if plushours > 0 or plathours > 0 then
                if nexa.tryFullPayment(user_id,25000) then
                    exports["ghmattimysql"]:execute("UPDATE nexa_user_vehicles SET fuel_level = 100 WHERE user_id = @user_id", {user_id = user_id}, function() end)
                    TriggerClientEvent("nexa:PlaySound", source, "money")
                    nexaclient.notify(source,{"~g~All vehicle fuel tanks have been refilled."})
                end
            else
                nexaclient.notify(source, {"~g~You need to a subscriber of nexa Platinum or nexa Plus."})
            end
        end
    end)
end)

RegisterCommand('redeem', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if tnexa.checkForRole(user_id, '1291080110065188866') then
        MySQL.query("subscription/get_subscription", {user_id = user_id}, function(rows, affected)
            if #rows > 0 then
                local redeemed = rows[1].redeemed
                if not redeemed then
                    exports["ghmattimysql"]:execute("UPDATE nexa_subscriptions SET redeemed = 1 WHERE user_id = @user_id", {user_id = user_id}, function() end)
                    nexa.giveBankMoney(user_id, 150000)
                    nexaclient.notify(source, {'~g~You have redeemed your perks of £150,000 and 1 Week of Platinum Subscription.'})
                    MySQL.execute("subscription/set_plathours", {user_id = user_id, plathours = rows[1].plathours + 170})
                else
                    nexaclient.notify(source, {'~r~You have already redeemed your subscription.'})
                end
            end
        end)
    end
end)