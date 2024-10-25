function rank(_, arg)
    if _ ~= 0 then return end
	local user_id = tonumber(arg[1])
    local rank = arg[2]
    print(user_id.." has bought "..rank.."! ^7")
    if nexa.getUserSource(user_id) ~= nil then
        nexa.addUserGroup(user_id,rank)  
    else
        exports['ghmattimysql']:execute("SELECT * FROM nexa_user_data WHERE user_id = @user_id", {user_id = user_id}, function(result) 
            if #result > 0 then
                local dvalue = json.decode(result[1].dvalue)
                local groups = dvalue.groups
                groups[rank] = true
                exports['ghmattimysql']:execute("UPDATE nexa_user_data SET dvalue = @dvalue WHERE user_id = @user_id", {dvalue = json.encode(dvalue), user_id = user_id}, function() end)
            end
        end)
    end  
    tnexa.sendWebhook('donation',"nexa Donation Logs", "> Player PermID: **"..user_id.."**\n> Package: **"..rank.."**")
end

function moneybag(_, arg)
    if _ ~= 0 then return end
    local user_id = tonumber(arg[1])
    local amount = tonumber(arg[2])
    if nexa.getUserSource(user_id) ~= nil then
        nexa.giveBankMoney(user_id, amount)
    else
        exports['ghmattimysql']:execute("UPDATE nexa_user_moneys SET bank = bank + @amount WHERE user_id = @user_id", {amount = amount, user_id = user_id}, function() end)
    end
    tnexa.sendWebhook('donation',"nexa Donation Logs", "> Player PermID: **"..user_id.."**\n> Package: **£"..getMoneyStringFormatted(amount).." money bag**")
end

function setphonenumber(_, arg)
    if _ ~= 0 then return end
    local user_id = tonumber(arg[1])
    local phone_number = tonumber(arg[2])
    MySQL.query("nexa/get_userbyphone", {phone_number}, function(phoneNumberTaken)
        if #phoneNumberTaken > 0 then
        else
            MySQL.execute("nexa/update_user_phone", {phone = phone_number, user_id = user_id})
            tnexa.sendWebhook('donation',"nexa Donation Logs", "> Player PermID: **"..user_id.."**\n> Package: **Phone Number: "..phone_number.."**")
        end
    end)
end

function vipcar(_, arg)
    if _ ~= 0 then return end
    local user_id = tonumber(arg[1])
    local spawncode = arg[2]
    MySQL.execute("nexa/add_vehicle", {user_id = user_id, vehicle = spawncode, registration = 'P'..math.random(10000,99999)})
    tnexa.sendWebhook('donation',"nexa Donation Logs", "> Player PermID: **"..user_id.."**\n> Package: **VIP Car: "..spawncode.."**")
end

RegisterCommand("rank", rank, true)
RegisterCommand("moneybag", moneybag, true)
RegisterCommand("setphonenumber", setphonenumber, true)
RegisterCommand("vipcar", vipcar, true)