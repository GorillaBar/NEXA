RegisterServerEvent("nexa:getUserinformation")
AddEventHandler("nexa:getUserinformation",function(id)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getUserSource(id) then
        if nexa.hasPermission(user_id, 'admin.moneymenu') then
            MySQL.query("nexa/get_chips", {user_id = id}, function(rows, affected)
                if #rows > 0 then
                    local chips = rows[1].chips
                    TriggerClientEvent('nexa:receivedUserInformation', source, nexa.getUserSource(id), tnexa.getDiscordName(nexa.getUserSource(id)), math.floor(nexa.getBankMoney(id)), math.floor(nexa.getMoney(id)), chips)
                end
            end)
        end
    else
        nexaclient.notify(source, {'~r~Player is not online.'})
    end
end)

RegisterServerEvent("nexa:ManagePlayerBank")
AddEventHandler("nexa:ManagePlayerBank",function(id, amount, cashtype)
    local amount = tonumber(amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local userstemp = nexa.getUserSource(id)
    if nexa.hasPermission(user_id, 'admin.moneymenu') then
        if cashtype == 'Increase' then
            nexa.giveBankMoney(id, amount)
            nexaclient.notify(source, {'~g~Added £'..getMoneyStringFormatted(amount)..' to players Bank Balance.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **£"..getMoneyStringFormatted(amount).." Bank**\n> Type: **"..cashtype.."**")
        elseif cashtype == 'Decrease' then
            nexa.tryBankPayment(id, amount)
            nexaclient.notify(source, {'~r~Removed £'..getMoneyStringFormatted(amount)..' from players Bank Balance.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **£"..getMoneyStringFormatted(amount).." Bank**\n> Type: **"..cashtype.."**")
        end
        MySQL.query("nexa/get_chips", {user_id = id}, function(rows, affected)
            if #rows > 0 then
                local chips = rows[1].chips
                TriggerClientEvent('nexa:receivedUserInformation', source, nexa.getUserSource(id), tnexa.getDiscordName(nexa.getUserSource(id)), math.floor(nexa.getBankMoney(id)), math.floor(nexa.getMoney(id)), chips)
            end
        end)
    end
end)

RegisterServerEvent("nexa:ManagePlayerCash")
AddEventHandler("nexa:ManagePlayerCash",function(id, amount, cashtype)
    local amount = tonumber(amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local userstemp = nexa.getUserSource(id)
    if nexa.hasPermission(user_id, 'admin.moneymenu') then
        if cashtype == 'Increase' then
            nexa.giveMoney(id, amount)
            nexaclient.notify(source, {'~g~Added £'..getMoneyStringFormatted(amount)..' to players Cash Balance.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **£"..getMoneyStringFormatted(amount).." Cash**\n> Type: **"..cashtype.."**")
        elseif cashtype == 'Decrease' then
            nexa.tryPayment(id, amount)
            nexaclient.notify(source, {'~r~Removed £'..getMoneyStringFormatted(amount)..' from players Cash Balance.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **£"..getMoneyStringFormatted(amount).." Cash**\n> Type: **"..cashtype.."**")
        end
        MySQL.query("nexa/get_chips", {user_id = id}, function(rows, affected)
            if #rows > 0 then
                local chips = rows[1].chips
                TriggerClientEvent('nexa:receivedUserInformation', source, nexa.getUserSource(id), tnexa.getDiscordName(nexa.getUserSource(id)), math.floor(nexa.getBankMoney(id)), math.floor(nexa.getMoney(id)), chips)
            end
        end)
    end
end)

RegisterServerEvent("nexa:ManagePlayerChips")
AddEventHandler("nexa:ManagePlayerChips",function(id, amount, cashtype)
    local amount = tonumber(amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local userstemp = nexa.getUserSource(id)
    if nexa.hasPermission(user_id, 'admin.moneymenu') then
        if cashtype == 'Increase' then
            MySQL.execute("nexa/add_chips", {user_id = id, amount = amount})
            nexaclient.notify(source, {'~g~Added '..getMoneyStringFormatted(amount)..' to players Casino Chips.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **"..getMoneyStringFormatted(amount).." Chips**\n> Type: **"..cashtype.."**")
            MySQL.query("nexa/get_chips", {user_id = id}, function(rows, affected)
                if #rows > 0 then
                    local chips = rows[1].chips
                    TriggerClientEvent('nexa:receivedUserInformation', source, nexa.getUserSource(id), tnexa.getDiscordName(nexa.getUserSource(id)), math.floor(nexa.getBankMoney(id)), math.floor(nexa.getMoney(id)), chips)
                end
            end)
        elseif cashtype == 'Decrease' then
            MySQL.execute("nexa/remove_chips", {user_id = id, amount = amount})
            nexaclient.notify(source, {'~r~Removed '..getMoneyStringFormatted(amount)..' from players Casino Chips.'})
            tnexa.sendWebhook('manage-balance',"nexa Money Menu Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(userstemp).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..userstemp.."**\n> Amount: **"..getMoneyStringFormatted(amount).." Chips**\n> Type: **"..cashtype.."**")
            MySQL.query("nexa/get_chips", {user_id = id}, function(rows, affected)
                if #rows > 0 then
                    local chips = rows[1].chips
                    TriggerClientEvent('nexa:receivedUserInformation', source, nexa.getUserSource(id), tnexa.getDiscordName(nexa.getUserSource(id)), math.floor(nexa.getBankMoney(id)), math.floor(nexa.getMoney(id)), chips)
                end
            end)
        end
    end
end)