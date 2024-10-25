local c = {}
RegisterCommand("djmenu", function(source, args, rawCommand)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasGroup(user_id,"DJ") then
        TriggerClientEvent('nexa:toggleDjMenu', source)
    end
end)
RegisterCommand("djadmin", function(source, args, rawCommand)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id,"admin.noclip") then
        TriggerClientEvent('nexa:toggleDjAdminMenu', source, c)
    end
end)
RegisterCommand("play",function(source,args,rawCommand)
    local source = source
    local user_id = nexa.getUserId(source)
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local name = tnexa.getDiscordName(source)
    if nexa.hasGroup(user_id,"DJ") then
        if #args > 0 then
            TriggerClientEvent('nexa:finaliseSong', source,args[1])
        end
    end
end)
RegisterServerEvent("nexa:adminStopSong")
AddEventHandler("nexa:adminStopSong", function(PARAM)
    local source = source
    for k,v in pairs(c) do
        if v[1] == PARAM then
            TriggerClientEvent('nexa:stopSong', -1,v[2])
            c[tostring(k)] = nil
            TriggerClientEvent('nexa:toggleDjAdminMenu', source, c)
        end
    end
end)
RegisterServerEvent("nexa:playDjSongServer")
AddEventHandler("nexa:playDjSongServer", function(PARAM,coords)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    c[tostring(source)] = {PARAM,coords,user_id,name,"true"}
    TriggerClientEvent('nexa:playDjSong', -1,PARAM,coords,user_id,name)
end)
RegisterServerEvent("nexa:skipServer")
AddEventHandler("nexa:skipServer", function(coords,param)
    local source = source
    TriggerClientEvent('nexa:skipDj', -1,coords,param)
end)
RegisterServerEvent("nexa:stopSongServer")
AddEventHandler("nexa:stopSongServer", function(coords)
    local source = source
    c[tostring(source)] = nil
    TriggerClientEvent('nexa:stopSong', -1,coords)
end)
RegisterServerEvent("nexa:updateVolumeServer")
AddEventHandler("nexa:updateVolumeServer", function(coords,volume)
    local source = source
    TriggerClientEvent('nexa:updateDjVolume', -1,coords,volume)
end)


RegisterServerEvent("nexa:requestCurrentProgressServer") -- doing this will fix the issue of the song not playing when you leave and re enter the area
AddEventHandler("nexa:requestCurrentProgressServer", function(a,b)
    TriggerClientEvent('nexa:requestCurrentProgress', -1, a, b)
end)

RegisterServerEvent("nexa:returnProgressServer") -- doing this will fix the issue of the song not playing when you leave and re enter the area
AddEventHandler("nexa:returnProgressServer", function(x,y,z)
    for k,v in pairs(c) do
        if tonumber(k) == nexa.getUserSource(x) then
            TriggerClientEvent('nexa:returnProgress', -1, x, y, z, v[1])
        end
    end
end)
