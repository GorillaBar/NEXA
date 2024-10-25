local bans = {
    {id = "offlanguage",name = "Offensive Language/Toxicity",durations = {48,72,168},bandescription = "1st Offense: 48hr\n2nd Offense: 72hr\n3rd Offense: 168hr",itemchecked = false},
    {id = "exploitingstandard",name = "Exploiting (Standard)",durations = {24,72,168},bandescription = "1st Offense: 24hr\n2nd Offense: 72hr\n3rd Offense: 168hr",itemchecked = false},
    {id = "scamming",name = "Scamming",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "advert",name = "Advertising",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "impersonationrule",name = "Impersonation",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "attacks",name = "Malicious Attacks",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false    },
    {id = "doxing",name = "Doxing",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "chargeback",name = "Chargeback",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "discretion",name = "Staff Discretion",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false    },
    {id = "cheating",name = "Cheating",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "banevading",name = "Ban Evading",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "fivemcheats",name = "Withholding/Storing FiveM Cheats",durations = {-1,-1,-1},bandescription = "1st Offense: Permanent\n2nd Offense: N/A\n3rd Offense: N/A",itemchecked = false},
    {id = "pov",name = "Failure to provide POV",durations = {2,-1,-1},bandescription = "1st Offense: 2hr\n2nd Offense: Permanent\n3rd Offense: N/A",itemchecked = false    },
}
local PlayerOffenses = {}
local PlayerBanCachedDuration = {}
local defaultBans = {}

RegisterServerEvent('nexa:OpenSettings')
AddEventHandler('nexa:OpenSettings', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        if nexa.hasPermission(user_id, "admin.tickets") then
            TriggerClientEvent("nexa:OpenAdminMenu", source)
        else
            TriggerClientEvent("nexa:OpenSettingsMenu", source)
        end
    end
end)

local criteriaChecks = {
    ['Mosins'] = function(source, cb)
        nexaclient.hasWeapon(source,{'WEAPON_MOSIN'},function(hasWeapon)
            cb(hasWeapon)
        end)
    end,
    ['POV List'] = function(source, cb)
        local id = nexa.getUserId(source)
        cb(nexa.hasPermission(id, 'pov.list'))
    end,
    ['Cinematic'] = function(source, cb)
        local id = nexa.getUserId(source)
        cb(nexa.hasGroup(id, 'Cinematic'))
    end,
}

RegisterNetEvent("nexa:searchByCriteria")
AddEventHandler("nexa:searchByCriteria", function(criteriaType)
    local source = source
    local user_id = nexa.getUserId(source)
    local plrTable = {}
    if nexa.hasPermission(user_id, 'admin.tickets') then
        local playersDone = 0
        for k, v in pairs(nexa.getUsers({})) do
            criteriaChecks[criteriaType](v, function(success)
                if success then
                    plrTable[k] = {tnexa.getDiscordName(v), v, k, tnexa.getPlaytime(k), nexa.hasPermission(k, 'pov.list')}
                end
                if GetNumPlayerIndices() == playersDone then
                    -- table.sort(plrTable, function(a,b)
                    --     return a[3] < b[3]
                    -- end)
                    TriggerClientEvent("nexa:returnCriteriaSearch", source, plrTable)
                else
                    playersDone = playersDone + 1
                end
            end)
        end
    end
end)

RegisterServerEvent("nexa:GetPlayerData")
AddEventHandler("nexa:GetPlayerData",function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        local players = GetPlayers()
        local players_table = {}
        for k, v in pairs(nexa.getUsers({})) do
            if nexa.getUserId(v) ~= nil then
                local name = tnexa.getDiscordName(v)
                local user_idz = nexa.getUserId(v)
                players_table[user_idz] = {name, v, user_idz, tnexa.getPlaytime(user_idz), nexa.hasPermission(user_idz, 'pov.list')}
            end
        end
        -- table.sort(players_table, function(a,b)
        --     return a[3] < b[3]
        -- end)
        TriggerClientEvent("nexa:getPlayersInfo", source, players_table, bans)
    end
end)

RegisterNetEvent("nexa:GetNearbyPlayers")
AddEventHandler("nexa:GetNearbyPlayers", function(coords, dist)
    local source = source
    local user_id = nexa.getUserId(source)
    local plrTable = {}
    if nexa.hasPermission(user_id, 'admin.tickets') then
        nexaclient.getNearestPlayersFromPosition(source, {coords, dist}, function(nearbyPlayers)
            for k, v in pairs(nearbyPlayers) do
                plrTable[nexa.getUserId(k)] = {tnexa.getDiscordName(k), k, nexa.getUserId(k), tnexa.getPlaytime(nexa.getUserId(k)), nexa.hasPermission(nexa.getUserId(k), 'pov.list')}
            end
            plrTable[user_id] = {tnexa.getDiscordName(source), source, nexa.getUserId(source), tnexa.getPlaytime(user_id)}
            -- table.sort(plrTable, function(a,b)
            --     return a[3] < b[3]
            -- end)
            TriggerClientEvent("nexa:ReturnNearbyPlayers", source, plrTable)
        end)
    end
end)

RegisterServerEvent("nexa:requestAccountInfosv")
AddEventHandler("nexa:requestAccountInfosv",function(permid)
    adminrequest = source
    adminrequest_id = nexa.getUserId(adminrequest)
    requesteduser = permid
    requestedusersource = nexa.getUserSource(requesteduser)
    if nexa.hasPermission(adminrequest_id, 'group.remove') then
        TriggerClientEvent('nexa:requestAccountInfo', nexa.getUserSource(permid))
    end
end)

RegisterServerEvent("nexa:GetGroups")
AddEventHandler("nexa:GetGroups",function(perm)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        TriggerClientEvent("nexa:GotGroups", source, nexa.getUserGroups(perm))
    end
end)

RegisterServerEvent("nexa:CheckPov")
AddEventHandler("nexa:CheckPov",function(userperm)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        if nexa.hasPermission(userperm, 'pov.list') then
            TriggerClientEvent('nexa:ReturnPov', source, true)
        else
            TriggerClientEvent('nexa:ReturnPov', source, false)
        end
    end
end)

local spectatingPositions = {}
RegisterServerEvent("nexa:spectatePlayer")
AddEventHandler("nexa:spectatePlayer", function(id)
    local playerssource = nexa.getUserSource(id)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.spectate") then
        if playerssource ~= nil then
            spectatingPositions[user_id] = {coords = GetEntityCoords(GetPlayerPed(source)), bucket = GetPlayerRoutingBucket(source)}
            tnexa.setBucket(source, GetPlayerRoutingBucket(playerssource))
            TriggerClientEvent("nexa:spectatePlayer",source, playerssource, GetEntityCoords(GetPlayerPed(playerssource)))
            tnexa.sendWebhook('spectate',"nexa Spectate Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(playerssource).."**\n> Player PermID: **"..id.."**\n> Player TempID: **"..playerssource.."**")
        else
            nexaclient.notify(source, {"~r~You can't spectate an offline player."})
        end
    end
end)

RegisterServerEvent("nexa:stopSpectatePlayer")
AddEventHandler("nexa:stopSpectatePlayer", function()
    local source = source
    if nexa.hasPermission(nexa.getUserId(source), "admin.spectate") then
        TriggerClientEvent("nexa:stopSpectatePlayer",source)
        for k,v in pairs(spectatingPositions) do
            if k == nexa.getUserId(source) then
                TriggerClientEvent("nexa:stopSpectatePlayer",source,v.coords,v.bucket)
                SetEntityCoords(GetPlayerPed(source),v.coords)
                tnexa.setBucket(source, v.bucket)
                spectatingPositions[k] = nil
            end
        end
    end
end)

RegisterServerEvent("nexa:ForceClockOff")
AddEventHandler("nexa:ForceClockOff", function(player_temp)
    local source = source
    local user_id = nexa.getUserId(source)
    local name = tnexa.getDiscordName(source)
    local player_perm = nexa.getUserId(player_temp)
    if nexa.hasPermission(user_id,"admin.tp2waypoint") then
        nexa.removeAllJobs(player_perm)
        nexaclient.notify(source,{'~g~User clocked off'})
        nexaclient.notify(player_temp,{'~r~You have been force clocked off.'})
        tnexa.sendWebhook('force-clock-off',"nexa Faction Logs", "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Players Name: **"..tnexa.getDiscordName(player_temp).."**\n> Players TempID: **"..player_temp.."**\n> Players PermID: **"..player_perm.."**")
        nexa.updateCurrentPlayerInfo()
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Force Clock Off')
    end
end)

RegisterServerEvent("nexa:AddGroup")
AddEventHandler("nexa:AddGroup",function(perm, selgroup)
    local source = source
    local admin_temp = source
    local user_id = nexa.getUserId(source)
    local permsource = nexa.getUserSource(perm)
    local playerName = tnexa.getDiscordName(source)
    local povName = tnexa.getDiscordName(permsource)
    if nexa.hasPermission(user_id, "group.add") then
        if selgroup == "Founder" and not nexa.hasPermission(user_id, "group.add.founder") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "Management" and not nexa.hasPermission(user_id, "group.add.management") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "Staff" and not nexa.hasPermission(user_id, "group.add.staff") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "pov" and not nexa.hasPermission(user_id, "group.add.pov") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"})
        else
            nexa.addUserGroup(perm, selgroup)
            local user_groups = nexa.getUserGroups(perm)
            TriggerClientEvent("nexa:GotGroups", source, user_groups)
            tnexa.sendWebhook('group',"nexa Group Logs", "> Admin Name: **"..playerName.."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Players Name: **"..tnexa.getDiscordName(permsource).."**\n> Players TempID: **"..permsource.."**\n> Players PermID: **"..perm.."**\n> Group: **"..selgroup.."**\n> Type: **Added**")
        end
    end
end)

RegisterServerEvent("nexa:RemoveGroup")
AddEventHandler("nexa:RemoveGroup",function(perm, selgroup)
    local source = source
    local user_id = nexa.getUserId(source)
    local admin_temp = source
    local permsource = nexa.getUserSource(perm)
    local playerName = tnexa.getDiscordName(source)
    local povName = tnexa.getDiscordName(permsource)
    if nexa.hasPermission(user_id, "group.remove") then
        if selgroup == "Founder" and not nexa.hasPermission(user_id, "group.remove.founder") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "Management" and not nexa.hasPermission(user_id, "group.remove.management") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "Staff" and not nexa.hasPermission(user_id, "group.remove.staff") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"}) 
        elseif selgroup == "pov" and not nexa.hasPermission(user_id, "group.remove.pov") then
            nexaclient.notify(admin_temp, {"~r~You don't have permission to do that"})
        else
            nexa.removeUserGroup(perm, selgroup)
            local user_groups = nexa.getUserGroups(perm)
            TriggerClientEvent("nexa:GotGroups", source, user_groups)
            tnexa.sendWebhook('group',"nexa Group Logs", "> Admin Name: **"..playerName.."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Players Name: **"..tnexa.getDiscordName(permsource).."**\n> Players TempID: **"..permsource.."**\n> Players PermID: **"..perm.."**\n> Group: **"..selgroup.."**\n> Type: **Removed**")
        end
    end
end)

RegisterServerEvent("nexa:GenerateBan")
AddEventHandler("nexa:GenerateBan", function(PlayerID, RulesBroken)
    local source = source
    local PlayerCacheBanMessage = {}
    local PermOffense = false
    local separatormsg = {}
    local points = 0
    PlayerBanCachedDuration[PlayerID] = 0
    PlayerOffenses[PlayerID] = {}
    if nexa.hasPermission(nexa.getUserId(source), "admin.tickets") then
        exports['ghmattimysql']:execute("SELECT * FROM nexa_bans_offenses WHERE UserID = @UserID", {UserID = PlayerID}, function(result)
            if #result > 0 then
                points = result[1].points
                PlayerOffenses[PlayerID] = json.decode(result[1].Rules)
                for k,v in pairs(RulesBroken) do
                    for a,b in pairs(bans) do
                        if b.id == k then
                            PlayerOffenses[PlayerID][k] = PlayerOffenses[PlayerID][k] + 1
                            if PlayerOffenses[PlayerID][k] > 3 then
                                PlayerOffenses[PlayerID][k] = 3
                            end
                            PlayerBanCachedDuration[PlayerID] = PlayerBanCachedDuration[PlayerID] + bans[a].durations[PlayerOffenses[PlayerID][k]]
                            if bans[a].durations[PlayerOffenses[PlayerID][k]] ~= -1 then
                                points = points + bans[a].durations[PlayerOffenses[PlayerID][k]]/24
                            end
                            table.insert(PlayerCacheBanMessage, bans[a].name)
                            if bans[a].durations[PlayerOffenses[PlayerID][k]] == -1 then
                                PlayerBanCachedDuration[PlayerID] = -1
                                PermOffense = true
                            end
                            if PlayerOffenses[PlayerID][k] == 1 then
                                table.insert(separatormsg, bans[a].name ..' ~y~| ~w~1st Offense ~y~| ~w~'..(PermOffense and "Permanent" or bans[a].durations[PlayerOffenses[PlayerID][k]] .." hrs"))
                            elseif PlayerOffenses[PlayerID][k] == 2 then
                                table.insert(separatormsg, bans[a].name ..' ~y~| ~w~2nd Offense ~y~| ~w~'..(PermOffense and "Permanent" or bans[a].durations[PlayerOffenses[PlayerID][k]] .." hrs"))
                            elseif PlayerOffenses[PlayerID][k] >= 3 then
                                table.insert(separatormsg, bans[a].name ..' ~y~| ~w~3rd Offense ~y~| ~w~'..(PermOffense and "Permanent" or bans[a].durations[PlayerOffenses[PlayerID][k]] .." hrs"))
                            end
                        end
                    end
                end
                if PermOffense then 
                    PlayerBanCachedDuration[PlayerID] = -1
                end
                Wait(100)
                TriggerClientEvent("nexa:ReceiveBanPlayerData", source, PlayerBanCachedDuration[PlayerID], table.concat(PlayerCacheBanMessage, ", "), separatormsg, math.floor(points))
            end
        end)
    end
end)

AddEventHandler("playerJoining", function()
    local source = source
    local user_id = nexa.getUserId(source)
    for k,v in pairs(bans) do
        defaultBans[v.id] = 0
    end
    exports["ghmattimysql"]:executeSync("INSERT IGNORE INTO nexa_bans_offenses(UserID,Rules) VALUES(@UserID, @Rules)", {UserID = user_id, Rules = json.encode(defaultBans)})
    exports["ghmattimysql"]:executeSync("INSERT IGNORE INTO nexa_user_notes(user_id) VALUES(@user_id)", {user_id = user_id})
end)

RegisterServerEvent("nexa:BanPlayer")
AddEventHandler("nexa:BanPlayer", function(PlayerID, Duration, BanMessage, BanPoints)
    local source = source
    local AdminPermID = nexa.getUserId(source)
    local AdminName = tnexa.getDiscordName(source)
    local CurrentTime = os.time()
    local PlayerDiscordID = 0
    nexa.prompt(source, "Extra Hidden Information (Enter 'no' or 'cancel' to exit)","",function(player, Evidence)
        if nexa.hasPermission(AdminPermID, "admin.tickets") then
            if string.lower(Evidence) == "no" or string.lower(Evidence) == "cancel" then
                return
            elseif Evidence == "" then
                nexaclient.notify(source, {"~r~Evidence field was left empty, please fill this in via Discord."})
            end
            if Duration == -1 then
                banDuration = "perm"
                BanPoints = 0
            else
                banDuration = CurrentTime + (60 * 60 * tonumber(Duration))
            end
            tnexa.sendWebhook('ban-player', AdminName.. " banned "..PlayerID, "> Admin Name: **"..AdminName.."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..AdminPermID.."**\n> Players PermID: **"..PlayerID.."**\n> Ban Duration: **"..Duration.."**\n> Reason(s): **"..BanMessage.."**")
            nexa.ban(source,PlayerID,banDuration,BanMessage,Evidence)
            f10Ban(PlayerID, AdminName, BanMessage, Duration)
            exports['ghmattimysql']:execute("UPDATE nexa_bans_offenses SET Rules = @Rules, points = @points WHERE UserID = @UserID", {Rules = json.encode(PlayerOffenses[PlayerID]), UserID = PlayerID, points = BanPoints}, function() end)
            if BanPoints > 10 then
                nexa.banConsole(PlayerID,2160,"You have reached more than 10 points and have received a 3 month ban.")
            end
        end
    end)
end)

local mediaBeingProcessed = {}

RegisterServerEvent('nexa:RequestScreenshot')
AddEventHandler('nexa:RequestScreenshot', function(target)
    local source = source
    local admin = source
    local target_id = nexa.getUserId(target)
    local target_name = tnexa.getDiscordName(target)
    local admin_id = nexa.getUserId(admin)
    local admin_name = tnexa.getDiscordName(source)
    if nexa.hasPermission(admin_id, 'admin.screenshot') then
        nexaclient.takeClientScreenshotAndUpload(target, {tnexa.getWebhook('screenshot')})
        mediaBeingProcessed[target_id] = admin_id
    else
        local player = nexa.getUserSource(admin_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Request Screenshot')
    end   
end)

RegisterServerEvent('nexa:RequestVideo')
AddEventHandler('nexa:RequestVideo', function(target)
    local source = source
    local target_id = nexa.getUserId(target)
    local target_name = tnexa.getDiscordName(target)
    local admin_id = nexa.getUserId(source)
    local admin_name = tnexa.getDiscordName(source)
    if nexa.hasPermission(admin_id, 'admin.screenshot') then
        nexaclient.takeClientVideoAndUpload(target, {tnexa.getWebhook('video')})
        mediaBeingProcessed[target_id] = {id = admin_id, temp = source, name = admin_name}
    else
        local player = nexa.getUserSource(admin_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Request Video')
    end   
end)

function tnexa.mediaProcessed(mediaType)
    local target = source
    local target_id = nexa.getUserId(target)
    local admin_id = mediaBeingProcessed[target_id].id
    local admin_source = mediaBeingProcessed[target_id].temp
    local admin_name = mediaBeingProcessed[target_id].name
    if mediaType == 'screenshot' then
        tnexa.sendWebhook('screenshot', 'nexa Screenshot Logs', "> Players Name: **"..tnexa.getDiscordName(target).."**\n> Player TempID: **"..target.."**\n> Player PermID: **"..target_id.."**\n> Admin Name: **"..admin_name.."**\n> Admin TempID: **"..admin_source.."**\n> Admin PermID: **"..admin_id.."**")
        mediaBeingProcessed[target_id] = nil
    elseif mediaType == 'video' then
        tnexa.sendWebhook('video', 'nexa Video Logs', "> Players Name: **"..tnexa.getDiscordName(target).."**\n> Player TempID: **"..target.."**\n> Player PermID: **"..target_id.."**\n> Admin Name: **"..admin_name.."**\n> Admin TempID: **"..admin_source.."**\n> Admin PermID: **"..admin_id.."**")
        mediaBeingProcessed[target_id] = nil
    end
end


RegisterServerEvent('nexa:KickPlayer')
AddEventHandler('nexa:KickPlayer', function(target)
    local source = source
    local user_id = nexa.getUserId(source)
    local target_id = nexa.getUserSource(target)
    local playerOtherName = tnexa.getDiscordName(target_id)
    if nexa.hasPermission(user_id, 'admin.kick') then
        nexa.prompt(source,"Reason:","",function(source,Reason) 
            if Reason == "" then return end
            tnexa.sendWebhook('kick-player', 'nexa Kick Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..playerOtherName.."**\n> Player TempID: **"..target_id.."**\n> Player PermID: **"..target.."**\n> Kick Reason: **"..Reason.."**")
            nexa.kick(target_id, "nexa You have been kicked | Your ID is: "..target.." | Reason: " ..Reason.." | Kicked by "..tnexa.getDiscordName(source))
            nexaclient.notify(source, {'~g~Kicked Player.'})
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Kick Someone')
    end
end)


RegisterServerEvent('nexa:RemoveWarning')
AddEventHandler('nexa:RemoveWarning', function(warningid)
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        if nexa.hasPermission(user_id, "admin.removewarn") then 
            exports['ghmattimysql']:execute("SELECT * FROM nexa_warnings WHERE warning_id = @warning_id", {warning_id = tonumber(warningid)}, function(result) 
                if result ~= nil then
                    for k,v in pairs(result) do
                        if v.warning_id == tonumber(warningid) then
                            exports['ghmattimysql']:execute("DELETE FROM nexa_warnings WHERE warning_id = @warning_id", {warning_id = v.warning_id})
                            exports['ghmattimysql']:execute("UPDATE nexa_bans_offenses SET points = CASE WHEN ((points-@removepoints)>0) THEN (points-@removepoints) ELSE 0 END WHERE UserID = @UserID", {UserID = v.user_id, removepoints = (v.duration/24)}, function() end)
                            nexaclient.notify(source, {'~g~Removed F10 Warning #'..warningid..' ('..(v.duration/24)..' points) from ID: '..v.user_id})
                            tnexa.sendWebhook('remove-warning', 'nexa Remove Warning Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Warning ID: **"..warningid.."**")
                        end
                    end
                end
            end)
        else
            local player = nexa.getUserSource(admin_id)
            local name = tnexa.getDiscordName(source)
            Wait(500)
            TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Remove Warning')
        end
    end
end)

RegisterServerEvent("nexa:Unban")
AddEventHandler("nexa:Unban",function()
    local source = source
    local admin_id = nexa.getUserId(source)
    playerName = tnexa.getDiscordName(source)
    if nexa.hasPermission(admin_id, 'admin.unban') then
        nexa.prompt(source,"Perm ID:","",function(source,permid) 
            if permid == '' then return end
            if tonumber(permid) then
                permid = tonumber(permid)
                nexaclient.notify(source,{'~g~Unbanned ID: ' .. permid})
                tnexa.sendWebhook('unban-player', 'nexa Unban Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..admin_id.."**\n> Player PermID: **"..permid.."**")
                nexa.setBanned(permid,false)
            else
                nexaclient.notify(source,{'~r~Invalid ID'})
            end
        end)
    else
        local player = nexa.getUserSource(admin_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Unban Someone')
    end
end)


RegisterServerEvent("nexa:getNotes")
AddEventHandler("nexa:getNotes",function(player)
    local source = source
    local admin_id = nexa.getUserId(source)
    if nexa.hasPermission(admin_id, 'admin.tickets') then
        exports['ghmattimysql']:execute("SELECT * FROM nexa_user_notes WHERE user_id = @user_id", {user_id = player}, function(result) 
            if result ~= nil then
                TriggerClientEvent('nexa:sendNotes', source, result[1].info)
            end
        end)
    end
end)

RegisterServerEvent("nexa:updatePlayerNotes")
AddEventHandler("nexa:updatePlayerNotes",function(player, notes)
    local source = source
    local admin_id = nexa.getUserId(source)
    if nexa.hasPermission(admin_id, 'admin.tickets') then
        exports['ghmattimysql']:execute("SELECT * FROM nexa_user_notes WHERE user_id = @user_id", {user_id = player}, function(result) 
            if result ~= nil then
                exports['ghmattimysql']:execute("UPDATE nexa_user_notes SET info = @info WHERE user_id = @user_id", {user_id = player, info = json.encode(notes)})
                nexaclient.notify(source, {'~g~Successfully updated.'})
            end
        end)
    end
end)

RegisterServerEvent('nexa:SlapPlayer')
AddEventHandler('nexa:SlapPlayer', function(target)
    local source = source
    local admin = source
    local admin_id = nexa.getUserId(admin)
    local player_id = nexa.getUserId(target)
    if nexa.hasPermission(admin_id, "admin.slap") then
        local playerName = tnexa.getDiscordName(source)
        local playerOtherName = tnexa.getDiscordName(target)
        tnexa.sendWebhook('slap', 'nexa Slap Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..admin.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..tnexa.getDiscordName(target).."**\n> Player TempID: **"..target.."**\n> Player PermID: **"..player_id.."**")
        TriggerClientEvent('nexa:SlapPlayer', target)
        nexaclient.notify(admin, {'~g~Slapped Player.'})
    else
        local player = nexa.getUserSource(admin_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Slap Someone')
    end
end)

RegisterServerEvent('nexa:RevivePlayer')
AddEventHandler('nexa:RevivePlayer', function(targetid, reviveall)
    local source = source
    local admin = source
    local admin_id = nexa.getUserId(admin)
    local player_id = targetid
    local target = nexa.getUserSource(player_id)
    if target ~= nil then
        if nexa.hasPermission(admin_id, "admin.revive") then
            nexaclient.RevivePlayer(target, {})
            nexaclient.setPlayerCombatTimer(target, {0})
            if not reviveall then
                local playerName = tnexa.getDiscordName(source)
                local playerOtherName = tnexa.getDiscordName(target)
                tnexa.sendWebhook('revive', 'nexa Revive Logs', "> Admin Name: **"..tnexa.getDiscordName(admin).."**\n> Admin TempID: **"..admin.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..tnexa.getDiscordName(target).."**\n> Player TempID: **"..target.."**\n> Player PermID: **"..player_id.."**")
                nexaclient.notify(admin, {'~g~Revived Player.'})
                return
            end
            nexaclient.notify(admin, {'~g~Revived all Nearby.'})
        else
            local player = nexa.getUserSource(admin_id)
            local name = tnexa.getDiscordName(source)
            Wait(500)
            TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Revive Someone')
        end
    end
end)

local frozenplayers = {}
RegisterServerEvent('nexa:FreezeSV')
AddEventHandler('nexa:FreezeSV', function(newtarget)
    local source = source
    local admin = source
    local admin_id = nexa.getUserId(admin)
    local player_id = nexa.getUserId(newtarget)
    if nexa.hasPermission(admin_id, 'admin.freeze') then
        local playerName = tnexa.getDiscordName(source)
        local playerOtherName = tnexa.getDiscordName(newtarget)
        if frozenplayers[player_id] then
            tnexa.sendWebhook('freeze', 'nexa Freeze Logs', "> Admin Name: **"..tnexa.getDiscordName(admin).."**\n> Admin TempID: **"..admin.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..tnexa.getDiscordName(newtarget).."**\n> Player TempID: **"..newtarget.."**\n> Player PermID: **"..player_id.."**\n> Type: **Unfrozen**")
            nexaclient.notify(admin, {'~g~Unfrozen Player.'})
            nexaclient.notify(newtarget, {'~g~You have been unfrozen.'})
            frozenplayers[player_id] = nil
        else
            tnexa.sendWebhook('freeze', 'nexa Freeze Logs', "> Admin Name: **"..tnexa.getDiscordName(admin).."**\n> Admin TempID: **"..admin.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..tnexa.getDiscordName(newtarget).."**\n> Player TempID: **"..newtarget.."**\n> Player PermID: **"..player_id.."**\n> Type: **Frozen**")
            nexaclient.notify(admin, {'~g~Froze Player.'})
            frozenplayers[player_id] = true
            nexaclient.notify(newtarget, {'~g~You have been frozen.'})
        end
        TriggerClientEvent('nexa:Freeze', newtarget, frozenplayers[player_id])
    else
        local player = nexa.getUserSource(admin_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Freeze Someone')
    end
end)

RegisterServerEvent('nexa:TeleportToPlayer')
AddEventHandler('nexa:TeleportToPlayer', function(source, newtarget)
    local source = source
    local coords = GetEntityCoords(GetPlayerPed(newtarget))
    local user_id = nexa.getUserId(source)
    local player_id = nexa.getUserId(newtarget)
    if nexa.hasPermission(user_id, 'admin.tp2player') then
        local playerName = tnexa.getDiscordName(source)
        local playerOtherName = tnexa.getDiscordName(newtarget)
        local adminbucket = GetPlayerRoutingBucket(source)
        local playerbucket = GetPlayerRoutingBucket(newtarget)
        if adminbucket ~= playerbucket then
            tnexa.setBucket(source, playerbucket)
            nexaclient.notify(source, {'~g~Player was in another bucket, you have been set into their bucket.'})
        end
        nexaclient.teleport(source, coords)
        nexaclient.notify(newtarget, {'~g~An admin has teleported to you.'})
        tnexa.sendWebhook('tp-to-player', 'nexa Teleport To Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(newtarget).."**\n> Player TempID: **"..newtarget.."**\n> Player PermID: **"..player_id.."**")
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Teleport to Someone')
    end
end)

RegisterServerEvent('nexa:Teleport2Legion')
AddEventHandler('nexa:Teleport2Legion', function(newtarget)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tp2player') then
        nexaclient.teleport(newtarget, vector3(152.66354370117,-1035.9771728516,29.337995529175))
        nexaclient.notify(newtarget, {'~g~You have been teleported to Legion by an admin.'})
        nexaclient.setPlayerCombatTimer(newtarget, {0})
        tnexa.sendWebhook('tp-to-legion', 'nexa Teleport Legion Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(newtarget).."**\n> Player TempID: **"..newtarget.."**\n> Player PermID: **"..nexa.getUserId(newtarget).."**")
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Teleport someone to Legion')
    end
end)

RegisterNetEvent('nexa:BringPlayer')
AddEventHandler('nexa:BringPlayer', function(id)
    local source = source 
    local SelectedPlrSource = nexa.getUserSource(id) 
    local user_id = nexa.getUserId(source)
    local source = source 
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tp2player') then
        if id then  
            local ped = GetPlayerPed(source)
            local pedCoords = GetEntityCoords(ped)
            nexaclient.teleport(id, pedCoords)
            local adminbucket = GetPlayerRoutingBucket(source)
            local playerbucket = GetPlayerRoutingBucket(id)
            if adminbucket ~= playerbucket then
                tnexa.setBucket(id, adminbucket)
                nexaclient.notify(source, {'~g~Player was in another bucket, they have been set into your bucket.'})
            end
            nexaclient.setPlayerCombatTimer(id, {0})
            tnexa.sendWebhook('tp-player-to-me', 'nexa Bring Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..user_id.."**\n> Player Name: **"..tnexa.getDiscordName(id).."**\n> Player TempID: **"..id.."**\n> Player PermID: **"..nexa.getUserId(id).."**")
        else 
            nexaclient.notify(source,{"~r~This player may have left the game."})
        end
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Teleport Someone to Them')
    end
end)

RegisterNetEvent('nexa:GetCoords')
AddEventHandler('nexa:GetCoords', function()
    local source = source 
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        nexaclient.getPosition(source,{},function(coords)
            local x,y,z = table.unpack(coords)
            nexa.prompt(source,"Copy the coordinates using Ctrl-A Ctrl-C",x..","..y..","..z,function(player,choice) 
            end)
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Get Coords')
    end
end)

RegisterNetEvent('nexa:getVector4')
AddEventHandler('nexa:getVector4', function()
    local source = source 
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        nexaclient.getPosition(source,{},function(coords)
            local x,y,z = table.unpack(coords)
            local h = GetEntityHeading(GetPlayerPed(source))
            nexa.prompt(source,"Copy the coordinates using Ctrl-A Ctrl-C", string.format("%s,%s,%s,%s",x,y,z,h), function(player,choice) 
            end)
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Get Coords')
    end
end)

RegisterServerEvent('nexa:Tp2Coords')
AddEventHandler('nexa:Tp2Coords', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tp2coords") then
        nexa.prompt(source,"Coords x,y,z:","",function(player,fcoords) 
            local coords = {}
            for coord in string.gmatch(fcoords or "0,0,0","[^,]+") do
            table.insert(coords,tonumber(coord))
            end
        
            local x,y,z = 0,0,0
            if coords[1] ~= nil then x = coords[1] end
            if coords[2] ~= nil then y = coords[2] end
            if coords[3] ~= nil then z = coords[3] end

            if x and y and z == 0 then
                nexaclient.notify(source, {"~r~We couldn't find those coords, try again!"})
            else
                nexaclient.teleport(player,{x,y,z})
            end 
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Teleport to Coords')
    end
end)

local adminIslandLocations = {}

RegisterServerEvent("nexa:Teleport2AdminIsland")
AddEventHandler("nexa:Teleport2AdminIsland",function(id)
    local source = source
    local admin = source
    if id ~= nil then
        local admin_id = nexa.getUserId(admin)
        local admin_name = tnexa.getDiscordName(admin)
        local player_id = nexa.getUserId(id)
        local player_name = tnexa.getDiscordName(id)
        if nexa.hasPermission(admin_id, 'admin.tp2player') then
            local playerName = tnexa.getDiscordName(source)
            local playerOtherName = tnexa.getDiscordName(id)
            tnexa.sendWebhook('tp-to-admin-zone', 'nexa Teleport Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..player_name.."**\n> Player TempID: **"..id.."**\n> Player PermID: **"..player_id.."**")
            local ped = GetPlayerPed(source)
            local ped2 = GetPlayerPed(id)
            adminIslandLocations[player_id] = GetEntityCoords(ped2)
            SetEntityCoords(ped2, 3061.135, -4719.28, 15.26162)
            tnexa.setBucket(id, 0)
            nexaclient.notify(nexa.getUserSource(player_id),{'~g~You are now in an admin situation, do not leave the game.'})
            nexaclient.setPlayerCombatTimer(id, {0})
        else
            local player = nexa.getUserSource(admin_id)
            local name = tnexa.getDiscordName(source)
            Wait(500)
            TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Teleport Someone to Admin Island')
        end
    end
end)

RegisterServerEvent("nexa:TeleportBackFromAdminZone")
AddEventHandler("nexa:TeleportBackFromAdminZone",function(id)
    local source = source
    local admin = source
    local admin_id = nexa.getUserId(admin)
    local player_id = nexa.getUserId(id)
    if id ~= nil then
        if nexa.hasPermission(admin_id, 'admin.tp2player') then
            local ped = GetPlayerPed(id)
            SetEntityCoords(ped, adminIslandLocations[player_id].x, adminIslandLocations[player_id].y, adminIslandLocations[player_id].z)
            tnexa.sendWebhook('tp-back-from-admin-zone', 'nexa Teleport Logs', "> Admin Name: **"..tnexa.getDiscordName(source).."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..admin_id.."**\n> Player Name: **"..tnexa.getDiscordName(id).."**\n> Player TempID: **"..id.."**\n> Player PermID: **"..nexa.getUserId(id).."**")
        else
            local player = nexa.getUserSource(admin_id)
            local name = tnexa.getDiscordName(source)
            Wait(500)
            TriggerEvent("nexa:acBan", admin_id, 11, name, player, 'Attempted to Teleport Someone Back from Admin Zone')
        end
    end
end)

RegisterServerEvent("nexa:tpToWaypoint")
AddEventHandler("nexa:tpToWaypoint",function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tp2waypoint') then
        TriggerClientEvent('nexa:tpToWaypoint', source)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Teleport to Waypoint')
    end
end)

RegisterNetEvent('nexa:AddCar')
AddEventHandler('nexa:AddCar', function()
    local source = source
    local admin_id = nexa.getUserId(source)
    local admin_name = tnexa.getDiscordName(source)
    if nexa.hasPermission(admin_id, 'admin.addcar') then
        nexa.prompt(source,"Add to Perm ID:","",function(source, permid)
            if permid == "" then return end
            permid = tonumber(permid)
            nexa.prompt(source,"Car Spawncode:","",function(source, car) 
                if car == "" then return end
                local car = car
                nexa.prompt(source,"Locked:","",function(source, locked) 
                    if locked == '0' or locked == '1' then
                        if permid and car ~= "" then  
                            nexaclient.generateUUID(source, {"plate", 5, "alphanumeric"}, function(uuid)
                                local uuid = string.upper(uuid)
                                exports['ghmattimysql']:execute("SELECT * FROM `nexa_user_vehicles` WHERE vehicle_plate = @plate", {plate = uuid}, function(result)
                                    if #result > 0 then
                                        nexaclient.notify(source, {'~r~Error adding car, please try again.'})
                                        return
                                    else
                                        MySQL.execute("nexa/add_vehicle", {user_id = permid, vehicle = car, registration = uuid, locked = locked})
                                        nexaclient.notify(source,{'~g~Successfully added Player\'s car'})
                                        tnexa.sendWebhook('add-car', 'nexa Add Car To Player Logs', "> Admin Name: **"..admin_name.."**\n> Admin TempID: **"..source.."**\n> Admin PermID: **"..admin_id.."**\n> Player PermID: **"..permid.."**\n> Spawncode: **"..car.."**")
                                    end
                                end)
                            end)
                        else 
                            nexaclient.notify(source,{'~r~Failed to add Player\'s car'})
                        end
                    else
                        nexaclient.notify(source,{'~g~Locked must be either 1 or 0'}) 
                    end
                end)
            end)
        end)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Add Car')
    end
end)

RegisterCommand('cleanup', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.noclip') then
        for i,v in pairs(GetAllVehicles()) do 
            DeleteEntity(v)
        end
        for i,v in pairs(GetAllPeds()) do 
            DeleteEntity(v)
        end
        for i,v in pairs(GetAllObjects()) do
            DeleteEntity(v)
        end
    end
end)

RegisterNetEvent('nexa:noClip')
AddEventHandler('nexa:noClip', function()
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.noclip') then 
        nexaclient.toggleNoclip(source,{})
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Trigger Noclip')
    end
end)


RegisterCommand("staffon", function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        nexaclient.staffMode(source, {true})
    end
end)

RegisterCommand("staffoff", function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        nexaclient.staffMode(source, {false})
    end
end)

function tnexa.getStaffLevel(user_id)
    local table = {
        ["Founder"] = 12,
        --["Developer"] = 11,
        ["Community Manager"] = 9,
        ["Staff Manager"] = 8,
        ["Head Admin"] = 7,
        ["Senior Admin"] = 6,
        ["Admin"] = 5,
        ["Senior Mod"] = 4,
        ["Moderator"] = 3,
        ["Support Team"] = 2,
        ["Trial Staff"] = 1,
    }
    for k,v in pairs(table) do
        if nexa.hasGroup(user_id, k) then
            return v
        end
    end
    return 0
end

RegisterServerEvent('nexa:getAdminLevel')
AddEventHandler('nexa:getAdminLevel', function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.setStaffLevel(source, {tnexa.getStaffLevel(user_id)})
end)


RegisterNetEvent('nexa:zapPlayer')
AddEventHandler('nexa:zapPlayer', function(A)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasGroup(user_id, 'Founder') then
        TriggerClientEvent("nexa:useTheForceTarget", A)
        for k,v in pairs(nexa.getUsers()) do
            TriggerClientEvent("nexa:useTheForceSync", v, GetEntityCoords(GetPlayerPed(A)), GetEntityCoords(GetPlayerPed(v)))
        end
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Trigger Zap Player')
    end
end)

RegisterNetEvent('nexa:theForceSync')
AddEventHandler('nexa:theForceSync', function(A, q, r, s)
    local source = source
    if nexa.getUserId(source) == 1 then
        TriggerClientEvent("nexa:useTheForceSync", A, q, r, s)
        TriggerClientEvent("nexa:useTheForceTarget", A)
    else
        local player = nexa.getUserSource(user_id)
        local name = tnexa.getDiscordName(source)
        Wait(500)
        TriggerEvent("nexa:acBan", user_id, 11, name, player, 'Attempted to Trigger Force Sync')
    end
end)

RegisterCommand("cleararea", function(source, args) -- these events are gonna be used for vehicle cleanup in future also
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.noclip') then
        TriggerClientEvent('nexa:clearVehicles', -1)
        TriggerClientEvent('nexa:clearBrokenVehicles', -1)
    end 
end)

Citizen.CreateThread(function()
	while true do
        Citizen.Wait(590000)
        TriggerClientEvent('chatMessage', -1, 'Announcement │ ', {255, 255, 255}, "^0Vehicle cleanup in 10 seconds! All unoccupied vehicles will be deleted.", "alert")
        Citizen.Wait(10000)
        TriggerClientEvent('chatMessage', -1, 'Announcement │ ', {255, 255, 255}, "^0Vehicle cleanup complete.", "alert")
        TriggerClientEvent('nexa:clearVehicles', -1)
        TriggerClientEvent('nexa:clearBrokenVehicles', -1)
	end
end)

RegisterCommand("getbucket", function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.notify(source, {'~g~You are currently in Bucket: '..GetPlayerRoutingBucket(source)})
end)

RegisterCommand("setbucket", function(source, args)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.managecommunitypot') then
        tnexa.setBucket(source, tonumber(args[1]))
        nexaclient.notify(source, {'~g~You are now in Bucket: '..GetPlayerRoutingBucket(source)})
    end 
end)

RegisterCommand("openurl", function(source, args)
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id == 1 then
        local permid = tonumber(args[1])
        local data = args[2]
        nexaclient.OpenUrl(nexa.getUserSource(permid), {data})
    end 
end)

RegisterCommand("clipboard", function(source, args)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'group.remove') then
        local permid = tonumber(args[1])
        table.remove(args, 1)
        local msg = table.concat(args, " ")
        nexaclient.CopyToClipboard(nexa.getUserSource(permid), {msg})
    end 
end)

RegisterCommand("staffmsg", function(source, args)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.tickets') then
        local permid = tonumber(args[1])
        local playersource = nexa.getUserSource(permid)
        table.remove(args, 1)
        local msg = table.concat(args, " ")
        if playersource then
            TriggerClientEvent('nexa:smallAnnouncement', playersource, 'Staff Message from '..tnexa.getDiscordName(source), msg, 6, 10000)
            nexaclient.notify(source, {'~g~Message sent.'})
        else
            nexaclient.notify(source, {'~r~That player is not online.'})
        end
    end 
end)