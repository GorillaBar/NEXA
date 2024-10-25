function nexa.createConsoleCommand(command, callback)
    RegisterCommand(command, function(source, args)
        if source ~= 0 then
            if nexa.getUserId(source) ~= 1 then
                return
            end
        end
        callback(source, args)
    end)
end

nexa.createConsoleCommand('addgroup', function(source, args)
    if tonumber(args[1]) and args[2] then
        local userid = tonumber(args[1])
        local group = args[2]
        nexa.addUserGroup(userid,group)
        print('Added Group: ' .. group .. ' to UserID: ' .. userid)
    else 
        print('Incorrect usage: addgroup [permid] [group]')
    end
end)

nexa.createConsoleCommand('removegroup', function(source, args)
    if tonumber(args[1]) and args[2] then
        local userid = tonumber(args[1])
        local group = args[2]
        nexa.removeUserGroup(userid,group)
        print('Removed Group: ' .. group .. ' from UserID: ' .. userid)
    else 
        print('Incorrect usage: addgroup [permid] [group]')
    end
end)

nexa.createConsoleCommand('ban', function(source, args)
    if tonumber(args[1]) and args[2] then
        local userid = tonumber(args[1])
        local hours = args[2]
        local reason = table.concat(args," ", 3)
        if reason then 
            nexa.banConsole(userid,hours,reason)
        else 
            print('Incorrect usage: ban [permid] [hours] [reason]')
        end 
    else 
        print('Incorrect usage: ban [permid] [hours] [reason]')
    end
end)

nexa.createConsoleCommand('unban', function(source, args)
    if tonumber(args[1])  then
        local userid = tonumber(args[1])
        nexa.setBanned(userid,false)
        print('Unbanned user: ' .. userid )
    else 
        print('Incorrect usage: unban [permid]')
    end
end)

nexa.createConsoleCommand('givemoneytoall', function(source, args)
    if tonumber(args[1])  then
        local amount = tonumber(args[1])
        for k,v in pairs(nexa.getUsers()) do
            nexa.giveBankMoney(k, amount)
        end
        print('Gave all users: £'..getMoneyStringFormatted(amount))
    else 
        print('Incorrect usage: givemoneytoall [amount]')
    end
end)