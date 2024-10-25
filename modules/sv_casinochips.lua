MySQL.createCommand("nexa/add_id_chips", "INSERT IGNORE INTO nexa_casino_chips SET user_id = @user_id")
MySQL.createCommand("nexa/get_chips","SELECT * FROM nexa_casino_chips WHERE user_id = @user_id")
MySQL.createCommand("nexa/add_chips", "UPDATE nexa_casino_chips SET chips = (chips + @amount) WHERE user_id = @user_id")
MySQL.createCommand("nexa/remove_chips", "UPDATE nexa_casino_chips SET chips = CASE WHEN ((chips - @amount)>0) THEN (chips - @amount) ELSE 0 END WHERE user_id = @user_id")


AddEventHandler("playerJoining", function()
    local user_id = nexa.getUserId(source)
    MySQL.execute("nexa/add_id_chips", {user_id = user_id})
end)

RegisterNetEvent("nexa:enterDiamondCasino")
AddEventHandler("nexa:enterDiamondCasino", function()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.setBucket(source, 777)
    MySQL.query("nexa/get_chips", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            TriggerClientEvent('nexa:setDisplayChips', source, rows[1].chips)
            return
        end
    end)
end)

RegisterNetEvent("nexa:exitDiamondCasino")
AddEventHandler("nexa:exitDiamondCasino", function()
    local source = source
    local user_id = nexa.getUserId(source)
    tnexa.setBucket(source, 0)
end)

RegisterNetEvent("nexa:getChips")
AddEventHandler("nexa:getChips", function()
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_chips", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            TriggerClientEvent('nexa:setDisplayChips', source, rows[1].chips)
            return
        end
    end)
end)

RegisterNetEvent("nexa:buyChips")
AddEventHandler("nexa:buyChips", function(amount)
    local source = source
    local user_id = nexa.getUserId(source)
    if not amount then amount = nexa.getMoney(user_id) end
    if not closeToRestart then
        if nexa.tryPayment(user_id, amount) then
            MySQL.execute("nexa/add_chips", {user_id = user_id, amount = amount})
            TriggerClientEvent('nexa:chipsUpdated', source)
            tnexa.sendWebhook('purchase-chips',"nexa Chip Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Amount: **"..getMoneyStringFormatted(amount).."**")
            return
        else
            nexaclient.notify(source,{"~r~You don't have enough money."})
            return
        end
    else
        nexaclient.notify(source,{"~r~You can't buy chips just before restart."})
        return
    end
end)

local sellingChips = {}
RegisterNetEvent("nexa:sellChips")
AddEventHandler("nexa:sellChips", function(amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local chips = nil
    if not closeToRestart then
        if not sellingChips[source] then
            sellingChips[source] = true
            MySQL.query("nexa/get_chips", {user_id = user_id}, function(rows, affected)
                if #rows > 0 then
                    local chips = rows[1].chips
                    if not amount then amount = chips end
                    if amount > 0 and chips > 0 and chips >= amount then
                        MySQL.execute("nexa/remove_chips", {user_id = user_id, amount = amount})
                        TriggerClientEvent('nexa:chipsUpdated', source)
                        tnexa.sendWebhook('sell-chips',"nexa Chip Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Amount: **"..getMoneyStringFormatted(amount).."**")
                        nexa.giveMoney(user_id, amount)
                    else
                        nexaclient.notify(source,{"~r~You don't have enough chips."})
                    end
                    sellingChips[source] = nil
                end
            end)
        end
    else
        nexaclient.notify(source,{"~r~You can't sell chips just before restart."})
        return
    end
end)