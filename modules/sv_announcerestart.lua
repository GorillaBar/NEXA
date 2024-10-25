closeToRestart = false
RegisterCommand('restartserver', function(source, args)
    local source = source
    if source == 0 then
        if args[1] ~= nil then
            timeLeft = args[1]
            TriggerClientEvent('nexa:announceRestart', -1, tonumber(timeLeft), false)
            TriggerEvent('nexa:restartTime', timeLeft)
            TriggerClientEvent('nexa:closeToRestart', -1)
            closeToRestart = true
        end
    else
        local user_id = nexa.getUserId(source)
        if nexa.hasGroup(user_id, 'Founder') then
            if args[1] ~= nil then
                timeLeft = args[1]
                TriggerClientEvent('nexa:announceRestart', -1, tonumber(timeLeft), false)
                TriggerEvent('nexa:restartTime', timeLeft)
                TriggerClientEvent('nexa:closeToRestart', -1)
                closeToRestart = true
            end
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        local time = os.date("*t") -- 0-23 (24 hour format)
        local hour = tonumber(time["hour"])
        if hour == 10 then
            if tonumber(time["min"]) == 0 and tonumber(time["sec"]) == 0 then
                TriggerClientEvent('nexa:announceRestart', -1, 60, true)
                TriggerEvent('nexa:restartTime', 60)
                TriggerClientEvent('nexa:closeToRestart', -1)
                closeToRestart = true
                if os.date('%A') == 'Monday' then
                    exports['ghmattimysql']:execute("UPDATE nexa_police_hours SET weekly_hours = 0, weekly_players_fined = 0, weekly_players_jailed = 0")
                    exports['ghmattimysql']:execute("UPDATE nexa_nhs_hours SET weekly_hours = 0, weekly_players_revived = 0")
                    exports['ghmattimysql']:execute("UPDATE nexa_staff_tickets SET weekly_ticket_count = 0")
                end
                exports['ghmattimysql']:execute("UPDATE nexa_nhs_hours SET daily_players_revived = 0")
            end
        end
    end
end)

RegisterServerEvent("nexa:restartTime")
AddEventHandler("nexa:restartTime", function(time)
    time = tonumber(time)
    if source ~= '' then return end
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(1000)
            time = time - 1
            if time == 0 then
                for k,v in pairs(nexa.getUsers({})) do
                    DropPlayer(v, "Server restarting, please join back in a few minutes.")
                end
                os.exit()
            end
        end
    end)
end)
