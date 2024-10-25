local staffGroups = {
    ['Founder'] = true,
    --['Developer'] = true,
    ['Staff Manager'] = true,
    ['Community Manager'] = true,
    ['Head Admin'] = true,
    ['Senior Admin'] = true,
    ['Admin'] = true,
    ['Senior Mod'] = true,
    ['Moderator'] = true,
    ['Support Team'] = true,
    ['Trial Staff'] = true,
}
local donatorGroups = {
    -- temp donator
    ["Baller"] = true,
    ["Rainmaker"] = true,
    ["Kingpin"] = true,
    ["Supreme"] = true,
    ["Premium"] = true,
    ["Supporter"] = true,
}
function getGroupInGroups(id, type)
    if type == 'Staff' then
        for k,v in pairs(nexa.getUserGroups(id)) do
            if staffGroups[k] then 
                return k
            end 
        end
    elseif type == 'Donator' then
        for k,v in ipairs(nexa.getUserGroups(id)) do
            if donatorGroups[k] then 
                return k
            end 
        end
        return "Unemployed"
    end
    return ""
end

local hiddenUsers = {}
RegisterNetEvent("nexa:setUserHidden")
AddEventHandler("nexa:setUserHidden",function(state)
    local source=source
    local user_id=nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.sethidden') then
        if state then
            hiddenUsers[user_id] = true
        else
            hiddenUsers[user_id] = nil
        end
    end
    TriggerClientEvent('nexa:setHiddenUsers', -1, hiddenUsers)
end)

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent('nexa:setHiddenUsers', source, hiddenUsers)
    end
end)

local uptime = 0
local function playerListMetaUpdates()
    local uptimemessage = ''
    if uptime < 60 then
        uptimemessage = math.floor(uptime) .. ' seconds'
    elseif uptime >= 60 and uptime < 3600 then
        uptimemessage = math.floor(uptime/60) .. ' minutes and ' .. math.floor(uptime%60) .. ' seconds'
    elseif uptime >= 3600 then
        uptimemessage = math.floor(uptime/3600) .. ' hours and ' .. math.floor((uptime%3600)/60) .. ' minutes and ' .. math.floor(uptime%60) .. ' seconds'
    end
    return {uptimemessage, #GetPlayers(), GetConvarInt("sv_maxclients",64)}
end

Citizen.CreateThread(function()
    while true do
        local time = os.date("*t")
        uptime = uptime + 1
        TriggerClientEvent('nexa:playerListMetaUpdate', -1, playerListMetaUpdates())
        Citizen.Wait(1000)
    end
end)

RegisterNetEvent('nexa:getPlayerListData')
AddEventHandler('nexa:getPlayerListData', function()
    local source = source
    local user_id = nexa.getUserId(source)
    local staff = {}
    local civillians = {}
    for k,v in pairs(nexa.getUsers()) do
        if not hiddenUsers[k] then
            local name = tnexa.getDiscordName(v)
            if name ~= nil then
                local minutesPlayed = nexa.getUserDataTable(k).PlayerTime or 0
                local hours = math.floor(minutesPlayed/60)
                if nexa.hasPermission(k, 'admin.tickets') then
                    staff[k] = {name = name, rank = getGroupInGroups(k, 'Staff'), hours = hours}
                end
                civillians[k] = {name = name, rank = getGroupInGroups(k, 'Donator'), hours = hours}
            end
        end
    end
    TriggerClientEvent('nexa:gotFullPlayerListData', source, staff, civillians)
end)