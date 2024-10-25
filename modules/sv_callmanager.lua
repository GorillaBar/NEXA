local tickets = {}
local callID = 0
local cooldown = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for k,v in pairs(cooldown) do
            if cooldown[k].time > 0 then
                cooldown[k].time = cooldown[k].time - 1
            end
        end
    end
end)

RegisterCommand("report", function(source)
    local user_id = nexa.getUserId(source)
    local user_source = nexa.getUserSource(user_id)
    for k,v in pairs(cooldown) do
        if k == user_id and v.time > 0 then
            nexaclient.notify(user_source,{"~r~You have already called an admin, please wait 5 minutes before calling again."})
            return
        end
    end
    nexa.prompt(user_source, "Please enter call reason: ", "", function(player, reason)
        if reason ~= "" then
            if #reason >= 25 then
                callID = callID + 1
                tickets[callID] = {
                    name = tnexa.getDiscordName(user_source),
                    permID = user_id,
                    tempID = user_source,
                    reason = reason,
                    type = 'admin',
                }
                cooldown[user_id] = {time = 5}
                for k, v in pairs(nexa.getUsers({})) do
                    TriggerClientEvent("nexa:addEmergencyCall", v, callID, tnexa.getDiscordName(user_source), user_id, GetEntityCoords(GetPlayerPed(user_source)), reason, 'admin')
                end
                nexaclient.notify(user_source,{"~b~Your request has been sent."})
                nexaclient.notify(user_source,{"~y~If you are reporting a player you can also create a report at www.nexa.cc/forums"})
            else
                nexaclient.notify(user_source,{"~r~Please enter a minimum of 25 characters."})
            end
        else
            nexaclient.notify(user_source,{"~r~Please enter a valid reason."})
        end
    end)
end)

local savedPositions = {}
RegisterCommand("return", function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        nexaclient.isStaffedOn(source, {}, function(staffedOn)
            if staffedOn then
                if savedPositions[user_id] then
                    tnexa.setBucket(source, savedPositions[user_id].bucket)
                    nexaclient.teleport(source, {table.unpack(savedPositions[user_id].coords)})
                    nexaclient.notify(source, {'~g~Returned to position.'})
                    savedPositions[user_id] = nil
                else
                    nexaclient.notify(source, {"~r~Unable to find last location."})
                end
                TriggerClientEvent('nexa:sendTicketInfo', source)
                nexaclient.staffMode(source, {false})
                SetTimeout(1000, function() 
                    nexaclient.setPlayerCombatTimer(source, {0})
                end)
            end
        end)
    end
end)


RegisterNetEvent("nexa:TakeTicket")
AddEventHandler("nexa:TakeTicket", function(ticketID)
    local user_id = nexa.getUserId(source)
    local admin_source = nexa.getUserSource(user_id)
    if tickets[ticketID] ~= nil then
        for k, v in pairs(tickets) do
            if ticketID == k then
                if nexa.hasPermission(user_id, "admin.tickets") then
                    if nexa.getUserSource(v.permID) ~= nil then
                        if user_id ~= v.permID then
                            local adminbucket = GetPlayerRoutingBucket(admin_source)
                            local playerbucket = GetPlayerRoutingBucket(v.tempID)
                            savedPositions[user_id] = {bucket = adminbucket, coords = GetEntityCoords(GetPlayerPed(admin_source))}
                            if adminbucket ~= playerbucket then
                                tnexa.setBucket(admin_source, playerbucket)
                                nexaclient.notify(admin_source, {'~g~Player was in another bucket, you have been set into their bucket.'})
                            end
                            nexaclient.getPosition(v.tempID, {}, function(coords)
                                nexaclient.staffMode(admin_source, {true})
                                TriggerClientEvent('nexa:sendTicketInfo', admin_source, v.permID, v.name, v.reason)
                                local ticketPay = 10000*grindBoost
                                local ticketData = json.encode({time = os.date("%d/%m/%Y at %X"), reason = v.reason, player = v.permID})
                                exports['ghmattimysql']:execute("SELECT * FROM `nexa_staff_tickets` WHERE user_id = @user_id", {user_id = user_id}, function(result)
                                    if result ~= nil then 
                                        for k,v in pairs(result) do
                                            if v.user_id == user_id then
                                                exports['ghmattimysql']:execute("UPDATE nexa_staff_tickets SET weekly_ticket_count = @weekly_ticket_count, total_ticket_count = @total_ticket_count, username = @username, last_ticket_info = @last_ticket_info  WHERE user_id = @user_id", {user_id = user_id, weekly_ticket_count = v.weekly_ticket_count + 1, total_ticket_count = v.total_ticket_count + 1, username = tnexa.getDiscordName(admin_source), last_ticket_info = ticketData}, function() end)
                                                return
                                            end
                                        end
                                        exports['ghmattimysql']:execute("INSERT INTO nexa_staff_tickets (`user_id`, `weekly_ticket_count`, `total_ticket_count`, `username`, `last_ticket_info`) VALUES (@user_id, @weekly_ticket_count, @total_ticket_count, @username, @last_ticket_info);", {user_id = user_id, weekly_ticket_count = 1, total_ticket_count = 1, username = tnexa.getDiscordName(admin_source), last_ticket_info = ticketData}, function() end) 
                                    end
                                end)
                                nexa.giveBankMoney(user_id, ticketPay)
                                nexaclient.notify(admin_source,{"~g~£"..getMoneyStringFormatted(ticketPay).." earned for being cute. ❤️"})
                                nexaclient.notify(v.tempID,{"~g~An admin has taken your ticket."})
                                TriggerClientEvent('nexa:smallAnnouncement', v.tempID, 'ticket accepted', "Your admin ticket has been accepted by "..tnexa.getDiscordName(admin_source), 33, 10000)
                                tnexa.sendWebhook('ticket-logs',"nexa Ticket Logs", "> Admin Name: **"..tnexa.getDiscordName(admin_source).."**\n> Admin TempID: **"..admin_source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..v.name.."**\n> Player PermID: **"..v.permID.."**\n> Player TempID: **"..v.tempID.."**\n> Reason: **"..v.reason.."**")
                                nexaclient.teleport(admin_source, {table.unpack(coords)})
                                TriggerClientEvent("nexa:removeEmergencyCall", -1, ticketID)
                                tickets[ticketID] = nil
                            end)
                        else
                            nexaclient.notify(admin_source,{"~r~You can't take your own ticket!"})
                        end
                    else
                        nexaclient.notify(admin_source,{"~r~You cannot take a ticket from an offline player."})
                        TriggerClientEvent("nexa:removeEmergencyCall", -1, ticketID)
                    end
                end
            end
        end
    end         
end)

RegisterNetEvent('nexa:getTicketData')
AddEventHandler('nexa:getTicketData', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        exports["ghmattimysql"]:execute("SELECT * FROM nexa_staff_tickets WHERE user_id = @user_id", {user_id = user_id}, function(ticketData)
            if #ticketData > 0 then
                local lastTicketInfo = json.decode(ticketData[1].last_ticket_info)
                ticketInfo = {
                    [1] = 'Your tickets this week ~g~'..ticketData[1].weekly_ticket_count,
                    [2] = 'Your total tickets: ~g~'..ticketData[1].total_ticket_count,
                    [3] = '',
                    [4] = 'Latest Ticket Info:',
                    [5] = 'Perm ID: ~o~'..lastTicketInfo.player,
                    [6] = 'Time: ~o~'..lastTicketInfo.time,
                    [7] = 'Reason: ~o~'..lastTicketInfo.reason,
                }
                TriggerClientEvent('nexa:sendTicketData', source, ticketInfo)
            end
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Trigger Get Ticket Data')
    end
end)

RegisterNetEvent('nexa:getTicketLeadeboard')
AddEventHandler('nexa:getTicketLeadeboard', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        exports["ghmattimysql"]:execute("SELECT * FROM nexa_staff_tickets ORDER BY weekly_ticket_count DESC", {}, function(ticketData)
            if #ticketData > 0 then
                ticketInfo = {}
                for i = 1, 5 do
                    ticketInfo[i] = ticketData[i].username..' - '..ticketData[i].weekly_ticket_count
                end
                TriggerClientEvent('nexa:sendTicketData', source, ticketInfo)
            end
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Trigger Get Ticket Data')
    end
end)