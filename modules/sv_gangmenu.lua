MySQL.createCommand("nexa/add_id_gang", "INSERT IGNORE INTO nexa_gang_users SET user_id = @user_id")
MySQL.createCommand("nexa/set_gang", "UPDATE nexa_gang_users SET gangname = @gangname WHERE user_id = @user_id")
MySQL.createCommand("nexa/get_gang", "SELECT gangname FROM nexa_gang_users WHERE user_id = @user_id")
MySQL.createCommand("nexa/get_gang_info", "SELECT * FROM nexa_gang_users WHERE gangname = @gangname")

local blockedWords = {"nigger", "nigga", "wog", "coon", "paki","faggot","anal","kys","homosexual","lesbian","suicide","negro","queef","queer","allahu akbar","terrorist","wanker","n1gger","f4ggot","n0nce","d1ck","h0m0","n1gg3r","h0m0s3xual","nazi","hitler"}
local gangWithdraw = {}
AddEventHandler("playerJoining", function()
    local user_id = nexa.getUserId(source)
    MySQL.execute("nexa/add_id_gang", {user_id = user_id})
end)

function manageGangContribution(name, id, date, amount, managetype)
    if managetype == 'Deposited' or managetype == 'Withdrew' then
        MySQL.query("nexa/get_gang", {user_id = id}, function(rows, affected)
            if #rows > 0 then
                local gangName = rows[1].gangname
                local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
                for K,V in pairs(gotGangs) do
                    local array = json.decode(V.gangmembers)
                    if array[tostring(id)].contribution == nil then
                        array[tostring(id)].contribution = {date = date, amount = 0}
                    end
                    if managetype == 'Deposited' then
                        array[tostring(id)].contribution = {date = date, amount = array[tostring(id)].contribution.amount + amount}
                    else
                        array[tostring(id)].contribution = {date = date, amount = array[tostring(id)].contribution.amount - amount}
                    end
                    exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=json.encode(array), gangname = gangName}, function() 
                        TriggerClientEvent('nexa:ForceRefreshData', nexa.getUserSource(id))
                    end)
                end
            end
        end)
    end
end

function addGangLog(name, id, date, action, actionValue)
    MySQL.query("nexa/get_gang", {user_id = id}, function(rows, affected)
        if #rows > 0 then
            local gangName = rows[1].gangname
            local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                for I,L in pairs(array) do
                    if tostring(id) == I then
                        local ganglogs = {}
                        if V.logs == 'NOTHING' then
                            ganglogs = {}
                        else
                            ganglogs = json.decode(V.logs)
                        end
                        local gangname = V.gangname
                        manageGangContribution(name, id, date, actionValue, action)
                        if action == 'Deposited' or action == 'Withdrew' then
                            actionValue = '£'..getMoneyStringFormatted(math.floor(actionValue+0.5))
                        end
                        table.insert(ganglogs, 1, {name, id, date, action, actionValue})
                        ganglogs = json.encode(ganglogs)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET logs = @logs WHERE gangname=@gangname", {logs = ganglogs, gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', nexa.getUserSource(id))
                        end)
                        PerformHttpRequest(V.webhook, function(err, text, headers) 
                        end, "POST", json.encode({username = V.gangname..' Gang Logs', avatar_url = 'https://i.imgur.com/k42kDxH.png', embeds = {
                            {
                                ["color"] = 0xd16feb,
                                ["title"] = action,
                                ["description"] = "Player ID: "..id.."\nPlayer Name: "..name.."\n"..action.." "..actionValue,
                                ["footer"] = {
                                    ["text"] = os.date("%X"),
                                    ["icon_url"] = "",
                                }
                        }
                        }}), { ["Content-Type"] = "application/json" })
                        tnexa.sendWebhook("gang-logs", "nexa Gang Logs", "> Gang Name: **"..gangname.."**\n> Player ID: **"..id.."**\n> Player Name: **"..name.."**\n> Action: **"..action.."**\n> Action Value: **"..actionValue.."**")
                        break
                    end
                end
            end
        end
    end)
end

function getGangData(source)
    local source = source
    local newarray = nil
    local user_id=nexa.getUserId(source)
    local gangmembers ={}
    local ganglogs = {}
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            local gangName = rows[1].gangname
            local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                if array[tostring(user_id)] then
                    newarray={}
                    newarray["money"] = V.funds
                    isingang = true
                    newarray["id"] = V.gangname
                    ganglogs = json.decode(V.logs)
                    fundslocked = V.lockedfunds
                    local gangpermission = array[tostring(user_id)].gangPermission
                    for U,D in pairs(array) do
                        local U = tonumber(U)
                        local usersTableInfo = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_users WHERE id = @user_id", {user_id = U})
                        local userDataInfo = exports['ghmattimysql']:executeSync("SELECT dvalue FROM nexa_user_data WHERE user_id = @user_id AND dkey = 'nexa:datatable'", {user_id = U})
                        local playtime = json.decode(userDataInfo[1].dvalue).PlayerTime or 0
                        playtime = playtime/60
                        if playtime < 1 then
                            playtime = 0
                        end
                        local online = nil
                        if nexa.getUserSource(U) ~= nil then
                            online = '~g~Online'
                        elseif usersTableInfo[1].banned then
                            online = '~r~Banned'
                        else
                            online = '~y~'..usersTableInfo[1].last_login
                        end
                        if array[tostring(U)].contribution == nil then
                            array[tostring(U)].contribution = {date = 'N/A', amount = '£0'}
                        end
                        array[tostring(U)].contribution.amount = '£'..getMoneyStringFormatted(array[tostring(U)].contribution.amount)
                        table.insert(gangmembers,{
                            usersTableInfo[1].username,
                            tonumber(usersTableInfo[1].id),
                            array[tostring(U)].gangPermission,
                            online,
                            math.ceil(playtime),
                            colour = array[tostring(U)].colour,
                            contributions = array[tostring(U)].contribution,
                        })
                        table.sort(gangmembers, function(a,b)
                            return a[2] < b[2]
                        end)
                    end
                    TriggerClientEvent("nexa:GotGangData", source,newarray,gangmembers,gangpermission,ganglogs,fundslocked,0,false)
                    for X,Y in pairs(array) do
                        local X = tonumber(X)
                        local X_source = nexa.getUserSource(X)
                        if X_source ~= nil and X ~= user_id then
                            TriggerClientEvent('nexa:updateGangMembers', X_source, gangmembers)
                        end
                    end
                end
            end
        end
    end)
end

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
       getGangData(source)
    end
end)

RegisterServerEvent("nexa:GetGangData")
AddEventHandler("nexa:GetGangData", function()
    local source=source
    getGangData(source)
end)

RegisterServerEvent("nexa:CreateGang")
AddEventHandler("nexa:CreateGang", function(gangname)
    local source=source
    local user_id=nexa.getUserId(source)
    local user_name = tnexa.getDiscordName(source)
    local funds = 0 
    local logs = "NOTHING"
    if not nexa.hasGroup(user_id,"Gang") then
        nexaclient.notify(source,{"~r~You do not have a gang license."})
        return
    end
    for word in pairs(blockedWords) do
        if(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(gangname:lower(), "-", ""), ",", ""), "%.", ""), " ", ""), "*", ""), "+", ""):find(blockedWords[word])) then
            nexaclient.notify(source, {"~r~Gang name contains blocked words."})
            return
        end
    end
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if not rows[1].gangname then
            exports['ghmattimysql']:execute('SELECT gangname FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGang)
                if json.encode(gotGang) ~= "[]" and gotGang ~= nil and json.encode(gotGang) ~= nil then
                    nexaclient.notify(source,{"~r~Gang name is already in use."})
                    return
                end
                local gangmembers = {
                    [tostring(user_id)] = {
                        ["rank"] = 4,
                        ["gangPermission"] = 4,
                    },
                }
                MySQL.execute("nexa/set_gang", {user_id = user_id, gangname = gangname})
                gangmembers = json.encode(gangmembers)
                nexaclient.notify(source,{"~g~"..gangname.." created."})
                exports['ghmattimysql']:execute("INSERT INTO nexa_gangs (gangname,gangmembers,funds,logs) VALUES(@gangname,@gangmembers,@funds,@logs)", {gangname=gangname,gangmembers=gangmembers,funds=funds,logs=logs}, function() end)
                TriggerClientEvent('nexa:gangNameNotTaken', source)
                TriggerClientEvent('nexa:ForceRefreshData', source)
            end)
        else
            nexaclient.notify(source, {'~r~You are already in a gang.'})
        end
    end)
end)
RegisterServerEvent("nexa:addUserToGang")
AddEventHandler("nexa:addUserToGang", function(ganginvite)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = ganginvite}, function(G)
        if json.encode(G) == "[]" and G == nil and json.encode(G) == nil then
            nexaclient.notify(source,{"~r~Gang no longer exists."})
            return
        end
        MySQL.execute("nexa/set_gang", {user_id = user_id, gangname = ganginvite})
        for K,V in pairs(G) do
            local array = json.decode(V.gangmembers)
            array[tostring(user_id)] = {["rank"] = 1,["gangPermission"] = 1}
            exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers = json.encode(array), gangname = ganginvite}, function()
                TriggerEvent('nexa:clockedOffRemoveRadio', source)
                for k,v in pairs(array) do
                    local id = tonumber(k)
                    if nexa.getUserSource(id) then
                        TriggerClientEvent('nexa:ForceRefreshData', nexa.getUserSource(id))
                    end
                end
            end)
        end
    end)
end)
RegisterServerEvent("nexa:depositGangBalance")
AddEventHandler("nexa:depositGangBalance", function(gangname, amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    if not amount then return end
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    local funds = V.funds
                    local gangname = V.gangname
                    if tonumber(amount) < 0 then
                        nexaclient.notify(source,{"~r~Invalid Amount"})
                        return
                    end
                    if tonumber(nexa.getBankMoney(user_id)) < tonumber(amount) then
                        nexaclient.notify(source,{"~r~Not enough money in bank."})
                    else
                        local tax = tonumber(amount)*0.01
                        nexa.setBankMoney(user_id, (nexa.getBankMoney(user_id)-tonumber(amount)))
                        nexaclient.notify(source,{"~g~Deposited £"..getMoneyStringFormatted(amount-tax).." 1% deposit fee paid."})
                        local newamount = tonumber(amount)+tonumber(funds)
                        TriggerEvent('nexa:addToCommunityPot', math.floor(tax))
                        addGangLog(name, user_id, date, 'Deposited', amount)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET funds = @funds WHERE gangname=@gangname", {funds = tostring(newamount)-tostring(tax), gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                        end)
                    end
                end
            end
        end
    end)
end)
RegisterServerEvent("nexa:depositAllGangBalance")
AddEventHandler("nexa:depositAllGangBalance", function(gangname)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    local amount = nexa.getBankMoney(user_id)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    local funds = V.funds
                    local gangname = V.gangname
                    if tonumber(amount) < 0 then
                        nexaclient.notify(source,{"~r~Invalid Amount"})
                        return
                    end
                    local tax = tonumber(amount)*0.01
                    nexa.setBankMoney(user_id, (nexa.getBankMoney(user_id)-amount))
                    nexaclient.notify(source,{"~g~Deposited £"..getMoneyStringFormatted(amount-tax).." 1% deposit fee paid."})
                    local newamount = tonumber(amount)+tonumber(funds)
                    TriggerEvent('nexa:addToCommunityPot', math.floor(tax))
                    addGangLog(name, user_id, date, 'Deposited', amount)
                    exports['ghmattimysql']:execute("UPDATE nexa_gangs SET funds = @funds WHERE gangname=@gangname", {funds = tostring(newamount)-tostring(tax), gangname = gangname}, function()
                        TriggerClientEvent('nexa:ForceRefreshData', source)
                    end)
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:withdrawGangBalance")
AddEventHandler("nexa:withdrawGangBalance", function(gangname, amount)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    if not amount then return end
    if not gangWithdraw[gangname] then
        gangWithdraw[gangname] = true
        exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                for I,L in pairs(array) do
                    if tostring(user_id) == I then
                        if L.rank >= 3 then
                            local funds = V.funds
                            if V.lockedfunds then
                                nexaclient.notify(source, {'~r~Gang funds are locked currently.'})
                            else
                                if tonumber(amount) < 0 then
                                    nexaclient.notify(source,{"~r~Invalid Amount"})
                                end
                                if tonumber(funds) < tonumber(amount) then
                                    nexaclient.notify(source,{"~r~Invalid Amount."})
                                else
                                    nexa.setBankMoney(user_id, (nexa.getBankMoney(user_id)+tonumber(amount)))
                                    nexaclient.notify(source,{"~g~Withdrawn £"..getMoneyStringFormatted(amount)})
                                    local newamount = tonumber(funds)-tonumber(amount)
                                    addGangLog(name, user_id, date, 'Withdrew', amount)
                                    exports['ghmattimysql']:execute("UPDATE nexa_gangs SET funds = @funds WHERE gangname=@gangname", {funds = tostring(newamount), gangname = gangname}, function()
                                        TriggerClientEvent('nexa:ForceRefreshData', source)
                                    end)
                                end
                            end
                        else
                            nexaclient.notify(source,{"~r~You do not have permission."})
                        end
                    end
                end
            end
        end)
        Wait(3000)
        gangWithdraw[gangname] = nil
    end
end)
RegisterServerEvent("nexa:withdrawAllGangBalance")
AddEventHandler("nexa:withdrawAllGangBalance", function(gangname)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    if not gangWithdraw[gangname] then
        gangWithdraw[gangname] = true
        exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                for I,L in pairs(array) do
                    if tostring(user_id) == I then
                        if L.rank >= 3 then
                            local funds = V.funds
                            local amount = V.funds
                            if V.lockedfunds then
                                nexaclient.notify(source, {'~r~Gang funds are locked currently.'})
                            else
                                if tonumber(funds) < 1 then
                                    nexaclient.notify(source,{"~r~Invalid Amount."})
                                else
                                    nexa.setBankMoney(user_id, (nexa.getBankMoney(user_id)+amount))
                                    nexaclient.notify(source,{"~g~Withdrawn £"..getMoneyStringFormatted(amount)})
                                    addGangLog(name, user_id, date, 'Withdrew', amount)
                                    exports['ghmattimysql']:execute("UPDATE nexa_gangs SET funds = @funds WHERE gangname=@gangname", {funds = tostring(newamount), gangname = gangname}, function()
                                        TriggerClientEvent('nexa:ForceRefreshData', source)
                                    end)
                                end
                            end
                        else
                            nexaclient.notify(source,{"~r~You do not have permission."})
                        end
                    end
                end
            end
        end)
        Wait(3000)
        gangWithdraw[gangname] = nil
    end
end)
RegisterServerEvent("nexa:PromoteUser")
AddEventHandler("nexa:PromoteUser", function(gangname,memberid)
    local source = source
    local user_id=nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank >= 4 then
                        local rank = array[tostring(memberid)].rank
                        local gangpermission = array[tostring(memberid)].gangPermission
                        if rank < 4 and gangpermission < 4 and tostring(user_id) ~= I then
                            nexaclient.notify(source,{"~r~Only the Gang Leader can promote."})
                            return
                        end
                        -- if array[tostring(memberid)].rank == 3 and gangpermission == 3 and tostring(user_id) == I then
                        --     nexaclient.notify(source,{"~r~There can only be 1 leader in each gang."})
                        --     return
                        -- end
                        if tonumber(memberid) == tonumber(user_id) and rank == 4 and gangpermission == 4 then
                            nexaclient.notify(source,{"~r~You are the highest rank."})
                            return
                        end 
                        array[tostring(memberid)].gangPermission = tonumber(gangpermission)+1
                        array[tostring(memberid)].rank = tonumber(rank)+1
                        array = json.encode(array)
                        addGangLog(name, user_id, date, 'Promoted', 'ID: '..memberid)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=array, gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                        end)
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)
RegisterServerEvent("nexa:DemoteUser")
AddEventHandler("nexa:DemoteUser", function(gangname,memberid)
    local source = source
    local user_id=nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank >= 4 then
                        local rank = array[tostring(memberid)].rank
                        local gangpermission = array[tostring(memberid)].gangPermission
                        -- if rank == 4 or gangpermission == 4 then
                        --     nexaclient.notify(source,{"~r~Cannot demote the leader"})
                        --     return
                        -- end
                        if rank == 1 and gangpermission == 1 then
                            nexaclient.notify(source,{"~r~Member is already the lowest rank."})
                            return
                        end
                        array[tostring(memberid)].rank = tonumber(rank)-1
                        array[tostring(memberid)].gangPermission = tonumber(gangpermission)-1
                        array = json.encode(array)
                        addGangLog(name, user_id, date, 'Demoted', 'ID: '..memberid)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=array, gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                        end)
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)
RegisterServerEvent("nexa:kickMemberFromGang")
AddEventHandler("nexa:kickMemberFromGang", function(gangname,member)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    local membersource = nexa.getUserSource(member)
    if membersource == nil then
        membersource = 0
    end
    local membergang = ""
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    local memberrank = array[tostring(member)].rank
                    local rank = array[tostring(user_id)].rank
                    if L.rank >= 3 then
                        if tonumber(member) == tonumber(user_id) then
                            nexaclient.notify(source,{"~r~You cannot kick yourself."})
                            return
                        end
                        if tonumber(memberrank) >= rank then
                            nexaclient.notify(source,{"~r~You do not have permission to kick this member from the gang."})
                            return
                        end
                        array[tostring(member)] = nil
                        array = json.encode(array)
                        nexaclient.notify(source,{"~r~Successfully kicked member from gang."})
                        addGangLog(name, user_id, date, 'Kicked', 'ID: '..member)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=array, gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                            MySQL.execute("nexa/set_gang", {user_id = member, gangname = nil})
                            if tonumber(membersource) > 0 then
                                nexaclient.notify(membersource,{"~r~You have been kicked from the gang."})
                                TriggerEvent('nexa:clockedOffRemoveRadio', membersource)
                                TriggerClientEvent('nexa:disbandedGang', membersource)
                            end
                        end)
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)
RegisterServerEvent("nexa:memberLeaveGang")
AddEventHandler("nexa:memberLeaveGang", function(gangname)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    local memberrank = array[tostring(user_id)].rank
                    local rank = array[tostring(user_id)].rank
                    if rank == 4 then
                        nexaclient.notify(source,{"~r~You cannot leave the gang because you are the leader!"})
                        return
                    else
                        array[tostring(user_id)] = nil
                        array = json.encode(array)
                        addGangLog(name, user_id, date, 'Left', 'ID: '..user_id)
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=array, gangname = gangname}, function()
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                            nexaclient.notify(source,{"~g~Successfully left gang."})
                            TriggerClientEvent('nexa:disbandedGang', source)
                            MySQL.execute("nexa/set_gang", {user_id = user_id, gangname = nil})
                            TriggerEvent('nexa:clockedOffRemoveRadio', source)
                            for k,v in pairs(json.decode(V.gangmembers)) do
                                local id = tonumber(k)
                                if nexa.getUserSource(id) then
                                    TriggerClientEvent('nexa:ForceRefreshData', nexa.getUserSource(id))
                                end
                            end
                        end)
                    end
                end
            end
        end
    end)
end)
RegisterServerEvent("nexa:InviteUserToGang")
AddEventHandler("nexa:InviteUserToGang", function(gangid,playerid)
    local source = source
    local playerid = tonumber(playerid)
    local user_id=nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local date = os.date("%d/%m/%Y at %X")
    local message = "~g~Gang invite received from "..name
    local playersource = nexa.getUserSource(playerid)
    if playersource == nil then
        nexaclient.notify(source,{"~r~Player is not online."})
        return
    else
        exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
            for K,V in pairs(G) do
                local array = json.decode(V.gangmembers)
                for I,L in pairs(array) do
                    if tostring(user_id) == I then
                        if L.rank >= 2 then
                            local playername = tnexa.getDiscordName(playersource)
                            addGangLog(name, user_id, date, 'Invited', 'ID: '..playerid)
                            TriggerClientEvent('nexa:InviteReceived', playersource,message,gangid)
                            nexaclient.notify(source,{"~g~Successfully invited "..playername.." to the gang."})
                        else
                            nexaclient.notify(source,{"~r~You do not have permission."})
                        end
                    end
                end
            end
        end)
    end
end)
RegisterServerEvent("nexa:DeleteGang")
AddEventHandler("nexa:DeleteGang", function(gangid)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
        for K,V in pairs(G) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank == 4 then
                        exports['ghmattimysql']:execute("DELETE FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangid}, function() end)
                        nexaclient.notify(source,{"~g~Disbanded "..gangid})
                        TriggerClientEvent('nexa:disbandedGang', source)
                        MySQL.execute("nexa/set_gang", {user_id = user_id, gangname = nil})
                        for k,v in pairs(array) do
                            local id = tonumber(k)
                            MySQL.execute("nexa/set_gang", {user_id = id, gangname = nil})
                            if nexa.getUserSource(id) then
                                TriggerEvent('nexa:clockedOffRemoveRadio', nexa.getUserSource(id))
                                TriggerClientEvent('nexa:disbandedGang', nexa.getUserSource(id))
                            end
                        end
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)


RegisterServerEvent("nexa:RenameGang")
AddEventHandler("nexa:RenameGang", function(gangid, newname)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT gangname FROM nexa_gangs WHERE gangname = @gangname', {gangname = newname}, function(gotGang)
        if json.encode(gotGang) ~= "[]" and gotGang ~= nil and json.encode(gotGang) ~= nil then
            nexaclient.notify(source,{"~r~Gang name is already in use."})
            return
        end
        exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
            for K,V in pairs(G) do
                local array = json.decode(V.gangmembers)
                for I,L in pairs(array) do
                    local id = tonumber(I)
                    MySQL.execute("nexa/set_gang", {user_id = id, gangname = newname})
                    if tostring(user_id) == I then
                        if L.rank == 4 then
                            exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangname = @newname WHERE gangname = @gangname", {gangname = gangid, newname = newname}, function() end)
                            nexaclient.notify(source,{"~g~Renamed gang to "..newname})
                            TriggerClientEvent('nexa:ForceRefreshData', source)
                        else
                            nexaclient.notify(source,{"~r~You do not have permission."})
                        end
                    end
                end
            end
        end)
    end)
end)

RegisterServerEvent("nexa:SetGangWebhook")
AddEventHandler("nexa:SetGangWebhook", function(gangid)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
        for K,V in pairs(G) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank >= 3 then
                        nexa.prompt(source,"Webhook (discord.com/api/webhooks/???): ","",function(source,webhook)
                            if webhook ~= nil and string.find(webhook, "https://discord.com/api/webhooks/") then
                                exports['ghmattimysql']:execute("UPDATE nexa_gangs SET webhook = @webhook WHERE gangname = @gangname", {gangname = gangid, webhook = webhook}, function() end)
                                nexaclient.notify(source,{"~g~Webhook set."})
                            else
                                nexaclient.notify(source,{"~r~Invalid value."})
                            end
                        end) 
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:LockGangFunds")
AddEventHandler("nexa:LockGangFunds", function(gangid)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
        for K,V in pairs(G) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank == 4 then
                        local fundsLocked = not V.lockedfunds
                        exports['ghmattimysql']:execute("UPDATE nexa_gangs SET lockedfunds = @lockedfunds WHERE gangname = @gangname", {gangname = gangid, lockedfunds = fundsLocked}, function() end)
                        nexaclient.notify(source,{"~g~Funds status changed."})
                        TriggerClientEvent('nexa:ForceRefreshData', source)
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:sendGangMarker")
AddEventHandler("nexa:sendGangMarker", function(gangname, coords)
    local source = source
    local user_id = nexa.getUserId(source)
    local markerCreator = tnexa.getDiscordName(source)
    local peoplesids = {}
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    for U,D in pairs(array) do
                        peoplesids[tostring(U)] = tostring(D.gangPermission)
                    end
                    exports['ghmattimysql']:execute('SELECT * FROM nexa_users', function(gotUser)
                        for J,G in pairs(gotUser) do
                            if peoplesids[tostring(G.id)] ~= nil then
                                local player = nexa.getUserSource(tonumber(G.id))
                                if player ~= nil then
                                    TriggerClientEvent('nexa:drawGangMarker', player, markerCreator, coords)
                                end
                            end
                        end
                    end)
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:applyGangFit")
AddEventHandler("nexa:applyGangFit", function(gangname)
    local source = source
    local user_id = nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname', {gangname = gangname}, function(gotGangs)
        for K,V in pairs(gotGangs) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if V.gangfit ~= nil then
                        nexaclient.setCustomization(source, {json.decode(V.gangfit), false, true})
                    else
                        nexaclient.notify(source,{"~r~Gang does not have an outfit set."})
                    end
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:setGangFit")
AddEventHandler("nexa:setGangFit", function(gangid)
    local source=source
    local user_id=nexa.getUserId(source)
    exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = gangid}, function(G)
        for K,V in pairs(G) do
            local array = json.decode(V.gangmembers)
            for I,L in pairs(array) do
                if tostring(user_id) == I then
                    if L.rank == 4 then
                        nexaclient.getCustomization(source,{},function(gangfit)
                            gangfit = json.encode(gangfit)
                            exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangfit = @gangfit WHERE gangname = @gangname", {gangname = gangid, gangfit = gangfit}, function() end)
                            nexaclient.notify(source,{"~g~Gang outfit set."})
                        end)
                    else
                        nexaclient.notify(source,{"~r~You do not have permission."})
                    end
                end
            end
        end
    end)
end)

local gangHealthEnabled = {}
RegisterServerEvent("nexa:getGangHealthTable")
AddEventHandler("nexa:getGangHealthTable", function(gangid)
    local source=source
    local user_id=nexa.getUserId(source)
    if gangid then
        gangHealthEnabled[user_id] = gangid
    else
        gangHealthEnabled[user_id] = nil
    end
end)

Citizen.CreateThread(function()
    while true do
        for E,F in pairs(gangHealthEnabled) do
            exports['ghmattimysql']:execute('SELECT * FROM nexa_gangs WHERE gangname = @gangname',{gangname = F}, function(gangInfo)
                local healthTable = {}
                for K,V in pairs(gangInfo) do
                    local array = json.decode(V.gangmembers)
                    for I,L in pairs(array) do
                        local permid = tonumber(I)
                        local tempId = nexa.getUserSource(permid)
                        if tempId ~= nil then
                            local playerPed = GetPlayerPed(tempId)
                            healthTable[permid] = {health = GetEntityHealth(playerPed), armour = GetPedArmour(playerPed)}
                        end
                    end
                end
                if nexa.getUserSource(E) ~= nil then
                    TriggerClientEvent('nexa:sendGangHPStats', nexa.getUserSource(E), healthTable)
                end
            end)
        end
        Citizen.Wait(20000)
    end
end)

RegisterServerEvent("nexa:newGangPanic")
AddEventHandler("nexa:newGangPanic", function(f)
    local source=source
    local user_id=nexa.getUserId(source)
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            local gangName = rows[1].gangname
            local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                for a,b in pairs(array) do
                    local player = nexa.getUserSource(tonumber(a))
                    if player ~= nil then
                        TriggerClientEvent('nexa:returnPanic', player, nil, f, 6)
                    end
                end
            end
        end
    end)
end)

RegisterServerEvent("nexa:setPersonalGangBlipColour")
AddEventHandler("nexa:setPersonalGangBlipColour", function(colour)
    local source=source
    local user_id=nexa.getUserId(source)
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
            local gangName = rows[1].gangname
            local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
            for K,V in pairs(gotGangs) do
                local array = json.decode(V.gangmembers)
                array[tostring(user_id)].colour = colour
                exports['ghmattimysql']:execute("UPDATE nexa_gangs SET gangmembers = @gangmembers WHERE gangname=@gangname", {gangmembers=json.encode(array), gangname = gangName}, function() end)
                for k,v in pairs(array) do
                    local k = tonumber(k)
                    local player = nexa.getUserSource(k)
                    if player ~= nil then
                        TriggerClientEvent('nexa:setGangMemberColour', player, user_id, colour)
                    end
                end
            end
        end
    end)
end)
