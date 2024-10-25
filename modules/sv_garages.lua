local lang = nexa.lang
local cfg = module("nexa-vehicles", "garages")
local cfg_inventory = module("nexa-vehicles", "inventory")
local vehicle_groups = cfg.garages
local limit = cfg.limit or 1000000000
MySQL.createCommand("nexa/add_vehicle","INSERT IGNORE INTO nexa_user_vehicles(user_id,vehicle,vehicle_plate,locked) VALUES(@user_id,@vehicle,@registration,@locked)")
MySQL.createCommand("nexa/remove_vehicle","DELETE FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")
MySQL.createCommand("nexa/remove_vehicle_mods","DELETE FROM nexa_vehicle_mods WHERE user_id = @user_id AND spawncode = @vehicle")
MySQL.createCommand("nexa/get_vehicles", "SELECT vehicle, rentedtime, vehicle_plate, fuel_level, impounded FROM nexa_user_vehicles WHERE user_id = @user_id")
MySQL.createCommand("nexa/get_rented_vehicles_in", "SELECT * FROM nexa_user_vehicles WHERE user_id = @user_id AND rented = 1")
MySQL.createCommand("nexa/get_rented_vehicles_out", "SELECT * FROM nexa_user_vehicles WHERE rentedid = @user_id AND rented = 1")
MySQL.createCommand("nexa/get_vehicle","SELECT vehicle FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")
MySQL.createCommand("nexa/get_vehicle_fuellevel","SELECT fuel_level FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")
MySQL.createCommand("nexa/get_vehicle_plate", "SELECT vehicle_plate FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle")
MySQL.createCommand("nexa/check_rented","SELECT * FROM nexa_user_vehicles WHERE user_id = @user_id AND vehicle = @vehicle AND rented = 1")
MySQL.createCommand("nexa/sell_vehicle_player","UPDATE nexa_user_vehicles SET user_id = @user_id, vehicle_plate = @registration WHERE user_id = @oldUser AND vehicle = @vehicle")
MySQL.createCommand("nexa/sell_vehicle_mods_player","UPDATE nexa_vehicle_mods SET user_id = @user_id WHERE user_id = @oldUser AND spawncode = @vehicle")
MySQL.createCommand("nexa/rentedupdate", "UPDATE nexa_user_vehicles SET user_id = @id, rented = @rented, rentedid = @rentedid, rentedtime = @rentedunix WHERE user_id = @user_id AND vehicle = @veh")
MySQL.createCommand("nexa/fetch_rented_vehs", "SELECT * FROM nexa_user_vehicles WHERE rented = 1")
MySQL.createCommand("nexa/get_vehicle_count","SELECT vehicle, locked FROM nexa_user_vehicles WHERE vehicle = @vehicle")

Citizen.CreateThread(function()
    while true do
        Wait(60000)
        MySQL.query('nexa/fetch_rented_vehs', {}, function(pvehicles)
            for i,v in pairs(pvehicles) do 
               if os.time() > tonumber(v.rentedtime) then
                MySQL.execute("nexa/sell_vehicle_mods_player", {user_id = v.rentedid, oldUser = v.user_id, vehicle = v.vehicle})
                  MySQL.execute('nexa/rentedupdate', {id = v.rentedid, rented = 0, rentedid = "", rentedunix = "", user_id = v.user_id, veh = v.vehicle})
                  if nexa.getUserSource(v.rentedid) then
                    nexaclient.notify(nexa.getUserSource(v.rentedid), {"~r~Your rented vehicle has been returned."})
                  end
               end
            end
        end)
    end
end)

RegisterServerEvent("nexa:spawnPersonalVehicle")
AddEventHandler('nexa:spawnPersonalVehicle', function(vehicle)
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(result)
        if result ~= nil then 
            for k,v in pairs(result) do
                if v.vehicle == vehicle then
                    if v.impounded then
                        nexaclient.notify(source, {'~r~This vehicle is currently impounded.'})
                        return
                    else
                        TriggerClientEvent('nexa:spawnPersonalVehicle', source, v.vehicle, nexa.GetMods(v.vehicle,user_id), false, GetEntityCoords(GetPlayerPed(source)), v.vehicle_plate, v.fuel_level)
                        return
                    end
                end
            end
        end
    end)
end)

valetCooldown = {}
RegisterServerEvent("nexa:valetSpawnVehicle")
AddEventHandler('nexa:valetSpawnVehicle', function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.isPlusClub(source,{},function(plusclub)
        nexaclient.isPlatClub(source,{},function(platclub)
            if plusclub or platclub then
                if valetCooldown[source] and not (os.time() > valetCooldown[source]) then
                    return nexaclient.notify(source,{"~r~Please wait before using this again."})
                else
                    valetCooldown[source] = nil
                end
                nexaclient.getPlayerCombatTimer(source, {}, function(combatTimer)
                    if combatTimer ~= 0 then
                        return nexaclient.notify(source,{"~r~You cannot use this feature whilst in combat."})
                    end
                    MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(result)
                        if result ~= nil then 
                            for k,v in pairs(result) do
                                if v.vehicle == spawncode then
                                    TriggerClientEvent('nexa:spawnPersonalVehicle', source, v.vehicle, nexa.GetMods(v.vehicle,user_id), true, GetEntityCoords(GetPlayerPed(source)), v.vehicle_plate, v.fuel_level)
                                    valetCooldown[source] = os.time() + 60
                                    return
                                end
                            end
                        end
                    end)
                end)
            else
                nexaclient.notify(source, {"~y~You need to be a subscriber of nexa Plus or nexa Platinum to use this feature."})
                nexaclient.notify(source, {"~y~Available @ store.nexa.cc"})
            end
        end)
    end)
end)

RegisterServerEvent("nexa:getVehicleRarity")
AddEventHandler('nexa:getVehicleRarity', function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_vehicle_count", {vehicle = spawncode}, function(result)
        if result ~= nil then 
            local ballerLocked = false
            for k,v in pairs(result) do
                if v.locked == true then
                    ballerLocked = true
                end
            end
            TriggerClientEvent('nexa:setVehicleRarity', source, spawncode, #result, ballerLocked)
        end
    end)
end)

RegisterServerEvent("nexa:displayVehicleBlip")
AddEventHandler('nexa:displayVehicleBlip', function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    local modsArray = nexa.GetMods(spawncode,user_id)
    nexaclient.getOwnedVehiclePosition(source, {spawncode}, function(x,y,z)
        if modsArray["security_blips"]["11"] then
            if vector3(x,y,z) ~= vector3(0,0,0) then
                local position = {}
                position.x, position.y, position.z = x,y,z
                if next(position) then
                    TriggerClientEvent('nexa:displayVehicleBlip', source, position)
                    nexaclient.notify(source, {"~g~Vehicle blip enabled."})
                    return
                end
            else
                nexaclient.notify(source, {"~r~Can not locate vehicle with the plate "..nexa.GetVehiclesPlate(user_id,spawncode).." in this city."})
            end
        else
            nexaclient.notify(source, {"~r~This vehicle does not have a remote vehicle blip installed."})
        end            
    end)
end)

RegisterServerEvent("nexa:viewRemoteDashcam")
AddEventHandler('nexa:viewRemoteDashcam', function(spawncode)
    local source = source
    local user_id = nexa.getUserId(source)
    local modsArray = nexa.GetMods(spawncode,user_id)
    nexaclient.getOwnedVehiclePosition(source, {spawncode}, function(x,y,z)
        if modsArray["security_dashcam"]["1"] then
            if vector3(x,y,z) ~= vector3(0,0,0) then
                if next(table.pack(x,y,z)) then
                    for k,v in pairs(netObjects) do
                        if math.floor(vector3(x,y,z)) == math.floor(GetEntityCoords(NetworkGetEntityFromNetworkId(k))) then
                            TriggerClientEvent('nexa:viewRemoteDashcam', source, table.pack(x,y,z), k)
                            return
                        end
                    end
                end
            else
                nexaclient.notify(source, {"~r~Can not locate vehicle with the plate "..nexa.GetVehiclesPlate(user_id,spawncode).." in this city."})
            end
        else
            nexaclient.notify(source, {"~r~This vehicle does not have a remote dashcam installed."})
        end
    end)
end)

RegisterServerEvent("nexa:updateFuel")
AddEventHandler('nexa:updateFuel', function(vehicle, fuel_level)
    local source = source
    local user_id = nexa.getUserId(source)
    exports["ghmattimysql"]:execute("UPDATE nexa_user_vehicles SET fuel_level = @fuel_level WHERE user_id = @user_id AND vehicle = @vehicle", {fuel_level = fuel_level, user_id = user_id, vehicle = vehicle}, function() end)
end)

RegisterServerEvent("nexa:getCustomFolders")
AddEventHandler('nexa:getCustomFolders', function()
    local source = source
    local user_id = nexa.getUserId(source)
    exports["ghmattimysql"]:execute("SELECT * from `nexa_custom_garages` WHERE user_id = @user_id", {user_id = user_id}, function(Result)
        if #Result > 0 then
            TriggerClientEvent("nexa:sendFolders", source, json.decode(Result[1].folder))
        end
    end)
end)


RegisterServerEvent("nexa:updateFolders")
AddEventHandler('nexa:updateFolders', function(FolderUpdated)
    local source = source
    local user_id = nexa.getUserId(source)
    exports["ghmattimysql"]:execute("SELECT * from `nexa_custom_garages` WHERE user_id = @user_id", {user_id = user_id}, function(Result)
        if #Result > 0 then
            exports['ghmattimysql']:execute("UPDATE nexa_custom_garages SET folder = @folder WHERE user_id = @user_id", {folder = json.encode(FolderUpdated), user_id = user_id}, function() end)
        else
            exports['ghmattimysql']:execute("INSERT INTO nexa_custom_garages (`user_id`, `folder`) VALUES (@user_id, @folder);", {user_id = user_id, folder = json.encode(FolderUpdated)}, function() end)
        end
    end)
end)

RegisterNetEvent('nexa:FetchCars')
AddEventHandler('nexa:FetchCars', function(type)
    local source = source
    local user_id = nexa.getUserId(source)
    local returned_table = {}
    local fuellevels = {}
    local vehicleWeights = {}
    if user_id then
        MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(pvehicles, affected)
            local numVehicles = 0
            for _, veh in pairs(pvehicles) do
                for i, v in pairs(vehicle_groups) do
                    local perms = false
                    local config = vehicle_groups[i]._config
                    if config.type == vehicle_groups[type]._config.type then 
                        local perm = config.permissions or nil
                        if next(perm) then
                            for i, v in pairs(perm) do
                                if nexa.hasPermission(user_id, v) then
                                    perms = true
                                end
                            end
                        else
                            perms = true
                        end
                        if perms then 
                            for a, z in pairs(v) do
                                if a ~= "_config" and veh.vehicle == a then
                                    if not returned_table[i] then 
                                        returned_table[i] = {["_config"] = config}
                                    end
                                    if not returned_table[i].vehicles then 
                                        returned_table[i].vehicles = {}
                                    end
                                    numVehicles = numVehicles + 1
                                    fuellevels[a] = veh.fuel_level
                                    returned_table[i].vehicles[a] = {z[1], z[2], veh.vehicle_plate}
                                    nexa.getSData("chest:u1veh_" .. a .. '|' .. user_id, function(cdata)
                                        cdata = json.decode(cdata) or {}
                                        local currentVehWeight = nexa.computeItemsWeight(cdata) or 0
                                        local maxVehKg = cfg_inventory.vehicle_chest_weights[a] or 30
                                        local weightColour = "~g~"
                                        local weightCalc = currentVehWeight / maxVehKg
                                        if weightCalc >= 0.8 then
                                            weightColour = "~r~"
                                        elseif weightCalc >= 0.5 then
                                            weightColour = "~y~"
                                        end
                                        vehicleWeights[a] =  weightColour.."Boot "..currentVehWeight.."/"..maxVehKg
                                        numVehicles = numVehicles - 1
                                        if numVehicles == 0 then
                                            TriggerClientEvent('nexa:ReturnFetchedCars', source, returned_table, fuellevels, vehicleWeights)
                                        end
                                    end)
                                end
                            end
                        end
                    end
                end
            end
        end)        
    end
end)

RegisterNetEvent('nexa:getAllVehicles')
AddEventHandler('nexa:getAllVehicles', function()
    local source = source
    local user_id = nexa.getUserId(source)
    local returned_table = {}
    if user_id then
        MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(pvehicles, affected)
            for _, veh in pairs(pvehicles) do
                for i, v in pairs(vehicle_groups) do
                    local config = vehicle_groups[i]._config
                    for a, z in pairs(v) do
                        if a ~= "_config" and veh.vehicle == a then
                            if not returned_table.vehicles then 
                                returned_table.vehicles = {}
                            end
                            returned_table.vehicles[a] = {z[1], z[2], veh.vehicle_plate}
                        end
                    end
                end
            end
            TriggerClientEvent('nexa:returnAllVehicles', source, returned_table)
        end)
    end
end)

RegisterNetEvent('nexa:CrushVehicle')
AddEventHandler('nexa:CrushVehicle', function(vehicle)
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id then 
        MySQL.query("nexa/check_rented", {user_id = user_id, vehicle = vehicle}, function(pvehicles)
            MySQL.query("nexa/get_vehicle", {user_id = user_id, vehicle = vehicle}, function(pveh)
                if #pveh < 0 then 
                    nexaclient.notify(source,{"~r~You cannot destroy a vehicle you do not own"})
                    return
                end
                if #pvehicles > 0 then 
                    nexaclient.notify(source,{"~r~You cannot destroy a rented vehicle!"})
                    return
                end
                MySQL.execute('nexa/remove_vehicle', {user_id = user_id, vehicle = vehicle})
                MySQL.execute('nexa/remove_vehicle_mods', {user_id = user_id, vehicle = vehicle})
                tnexa.sendWebhook('crush-vehicle', "nexa Crush Vehicle Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Vehicle: **"..vehicle.."**")
                TriggerClientEvent('nexa:CloseGarage', source)
            end)
        end)
    end
end)

RegisterNetEvent('nexa:SellVehicle')
AddEventHandler('nexa:SellVehicle', function(veh)
    local name = veh
    local player = source 
    local playerID = nexa.getUserId(source)
    if playerID ~= nil then
		nexaclient.getNearestPlayers(player,{15},function(nplayers)
			usrList = ""
			for k,v in pairs(nplayers) do
				usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | "
			end
			if usrList ~= "" then
				nexa.prompt(player,"Players Nearby: " .. usrList .. "","",function(player,tempid) 
					local user_id = nexa.getUserId(tonumber(tempid))
					if user_id ~= nil and user_id ~= "" then 
						local target = nexa.getUserSource(user_id)
						if target ~= nil then
							nexa.prompt(player,"Price £: ","",function(player,amount)
								if tonumber(amount) and tonumber(amount) >= 0 and tonumber(amount) <= limit then
									MySQL.query("nexa/get_vehicle", {user_id = user_id, vehicle = name}, function(pvehicle, affected)
										if #pvehicle > 0 then
											nexaclient.notify(player,{"~r~The player already has this vehicle type."})
										else
											MySQL.query("nexa/check_rented", {user_id = playerID, vehicle = veh}, function(pvehicles)
                                                if #pvehicles > 0 then 
                                                    nexaclient.notify(player,{"~r~You cannot sell a rented vehicle!"})
                                                    return
                                                else
                                                    nexa.request(target,tnexa.getDiscordName(player).." wants to sell: " ..name.. " Price: £"..getMoneyStringFormatted(amount), 10, function(target,ok)
                                                        if ok then
                                                            local pID = nexa.getUserId(target)
                                                            amount = tonumber(amount)
                                                            if nexa.tryFullPayment(pID,amount) then
                                                                nexaclient.despawnGarageVehicle(player,{'car',15}) 
                                                                nexa.getUserIdentity(pID, function(identity)
                                                                    MySQL.execute("nexa/sell_vehicle_player", {user_id = user_id, registration = "P "..identity.registration, oldUser = playerID, vehicle = name})
                                                                    MySQL.execute("nexa/sell_vehicle_mods_player", {user_id = user_id, oldUser = playerID, vehicle = name})
                                                                end)
                                                                nexa.giveBankMoney(playerID, amount)
                                                                nexaclient.notify(player,{"~g~You have successfully sold the vehicle to ".. tnexa.getDiscordName(target)})
                                                                nexaclient.notify(target,{"~g~"..tnexa.getDiscordName(player).." has successfully sold you the car for £"..getMoneyStringFormatted(amount)})
                                                                tnexa.sendWebhook('sell-vehicle', "nexa Sell Vehicle Logs", "> Seller Name: **"..tnexa.getDiscordName(player).."**\n> Seller TempID: **"..player.."**\n> Seller PermID: **"..playerID.."**\n> Buyer Name: **"..tnexa.getDiscordName(target).."**\n> Buyer TempID: **"..target.."**\n> Buyer PermID: **"..user_id.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**\n> Vehicle: **"..name.."**")
                                                                TriggerClientEvent('nexa:CloseGarage', player)
                                                            else
                                                                nexaclient.notify(player,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"})
                                                                nexaclient.notify(target,{"~r~You don't have enough money!"})
                                                            end
                                                        else
                                                            nexaclient.notify(player,{"~r~"..tnexa.getDiscordName(target).." has refused to buy the car."})
                                                            nexaclient.notify(target,{"~r~You have refused to buy "..tnexa.getDiscordName(player).."'s car."})
                                                        end
                                                    end)
                                                end
                                            end)
										end
									end) 
								else
									nexaclient.notify(player,{"~r~The price of the car has to be a number."})
								end
							end)
						else
							nexaclient.notify(player,{"~r~That ID seems invalid."})
						end
					else
						nexaclient.notify(player,{"~r~No player ID selected."})
					end
				end)
			else
				nexaclient.notify(player,{"~r~No players nearby."})
			end
		end)
    end
end)


RegisterNetEvent('nexa:RentVehicle')
AddEventHandler('nexa:RentVehicle', function(veh)
    local name = veh
    local player = source 
    local playerID = nexa.getUserId(source)
    if playerID ~= nil then
		nexaclient.getNearestPlayers(player,{15},function(nplayers)
			usrList = ""
			for k,v in pairs(nplayers) do
				usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | "
			end
			if usrList ~= "" then
				nexa.prompt(player,"Players Nearby: " .. usrList .. "","",function(player,tempid) 
					local user_id = nexa.getUserId(tonumber(tempid))
					if user_id ~= nil and user_id ~= "" then 
						local target = nexa.getUserSource(user_id)
						if target ~= nil then
							nexa.prompt(player,"Price £: ","",function(player,amount)
                                nexa.prompt(player,"Rent time (in hours): ","",function(player,rent)
                                    if tonumber(rent) and tonumber(rent) >  0 then 
                                        if tonumber(amount) and tonumber(amount) >= 0 and tonumber(amount) <= limit then
                                            MySQL.query("nexa/get_vehicle", {user_id = user_id, vehicle = name}, function(pvehicle, affected)
                                                if #pvehicle > 0 then
                                                    nexaclient.notify(player,{"~r~The player already has this vehicle."})
                                                else
                                                    MySQL.query("nexa/check_rented", {user_id = playerID, vehicle = veh}, function(pvehicles)
                                                        if #pvehicles > 0 then 
                                                            return
                                                        else
                                                            nexa.prompt(player, "Please replace text with YES or NO to confirm", "Rent Details:\nVehicle: "..name.."\nRent Cost: £"..getMoneyStringFormatted(amount).."\nDuration: "..rent.." hours\nRenting to player: "..tnexa.getDiscordName(target).."("..nexa.getUserId(target)..")",function(player,details)
                                                                if string.upper(details) == 'YES' then
                                                                    nexaclient.notify(player, {'~g~Rent offer sent!'})
                                                                    nexa.request(target,tnexa.getDiscordName(player).." wants to rent: " ..name.. " Price: £"..getMoneyStringFormatted(amount) .. ' | for: ' .. rent .. 'hours', 10, function(target,ok)
                                                                        if ok then
                                                                            local pID = nexa.getUserId(target)
                                                                            amount = tonumber(amount)
                                                                            if nexa.tryFullPayment(pID,amount) then
                                                                                nexaclient.despawnGarageVehicle(player,{'car',15}) 
                                                                                nexa.getUserIdentity(pID, function(identity)
                                                                                    local rentedTime = os.time()
                                                                                    rentedTime = rentedTime  + (60 * 60 * tonumber(rent)) 
                                                                                    MySQL.execute("nexa/sell_vehicle_mods_player", {user_id = pID, oldUser = playerID, vehicle = name})
                                                                                    MySQL.execute("nexa/rentedupdate", {user_id = playerID, veh = name, id = pID, rented = 1, rentedid = playerID, rentedunix =  rentedTime }) 
                                                                                end)
                                                                                nexa.giveBankMoney(playerID, amount)
                                                                                nexaclient.notify(player,{"~g~You have successfully rented the vehicle to "..tnexa.getDiscordName(target)})
                                                                                nexaclient.notify(target,{"~g~"..tnexa.getDiscordName(player).." has successfully rented you the vehicle."})
                                                                                tnexa.sendWebhook('rent-vehicle', "nexa Rent Vehicle Logs", "> Renter Name: **"..tnexa.getDiscordName(player).."**\n> Renter TempID: **"..player.."**\n> Renter PermID: **"..playerID.."**\n> Rentee Name: **"..tnexa.getDiscordName(target).."**\n> Rentee TempID: **"..target.."**\n> Rentee PermID: **"..pID.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**\n> Duration: **"..rent.." hours**\n> Vehicle: **"..veh.."**")
                                                                            else
                                                                                nexaclient.notify(player,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"})
                                                                                nexaclient.notify(target,{"~r~You don't have enough money!"})
                                                                            end
                                                                        else
                                                                            nexaclient.notify(player,{"~r~"..tnexa.getDiscordName(target).." has refused to rent the car."})
                                                                            nexaclient.notify(target,{"~r~You have refused to rent "..tnexa.getDiscordName(player).."'s car."})
                                                                        end
                                                                    end)
                                                                else
                                                                    nexaclient.notify(player, {'~r~Rent offer cancelled!'})
                                                                end
                                                            end)
                                                        end
                                                    end)
                                                end
                                            end) 
                                        else
                                            nexaclient.notify(player,{"~r~The price of the car has to be a number."})
                                        end
                                    else 
                                        nexaclient.notify(player,{"~r~The rent time of the car has to be in hours and a number."})
                                    end
                                end)
							end)
						else
							nexaclient.notify(player,{"~r~That ID seems invalid."})
						end
					else
						nexaclient.notify(player,{"~r~No player ID selected."})
					end
				end)
			else
				nexaclient.notify(player,{"~r~No players nearby."})
			end
		end)
    end
end)

RegisterNetEvent('nexa:RentMultipleVehicles')
AddEventHandler('nexa:RentMultipleVehicles', function(vehiclesTable)
    local player = source 
    local playerID = nexa.getUserId(source)
    local totalVehicles = 0 
    for k,v in pairs(vehiclesTable) do
        totalVehicles = totalVehicles + 1
    end
    if playerID ~= nil then
		nexaclient.getNearestPlayers(player,{15},function(nplayers)
			usrList = ""
			for k,v in pairs(nplayers) do
				usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | "
			end
			if usrList ~= "" then
				nexa.prompt(player,"Players Nearby: " .. usrList .. "","",function(player,tempid) 
					local user_id = nexa.getUserId(tonumber(tempid))
					if user_id ~= nil and user_id ~= "" then 
						local target = nexa.getUserSource(user_id)
						if target ~= nil then
							nexa.prompt(player,"Price per vehicle £: ","",function(player,amount)
                                nexa.prompt(player,"Rent time per vehicle (in hours): ","",function(player,rent)
                                    if tonumber(rent) and tonumber(rent) >  0 then 
                                        if tonumber(amount) and tonumber(amount) >= 0 and tonumber(amount) <= limit then
                                            local currentVehicleNum = 0
                                            for k,v in pairs(vehiclesTable) do
                                                MySQL.query("nexa/get_vehicle", {user_id = user_id, vehicle = k}, function(pvehicle, affected)
                                                    if #pvehicle > 0 then
                                                        nexaclient.notify(player,{"~r~The player already has "..k.."."})
                                                    else
                                                        MySQL.query("nexa/check_rented", {user_id = playerID, vehicle = k}, function(pvehicles)
                                                            if #pvehicles > 0 then 
                                                                return
                                                            else
                                                                currentVehicleNum = currentVehicleNum + 1
                                                                if currentVehicleNum == totalVehicles then
                                                                    nexa.prompt(player, "Please replace text with YES or NO to confirm", "Rent Cost: £"..getMoneyStringFormatted(amount*totalVehicles).."\nDuration: "..rent.." hours\nRenting to player: "..tnexa.getDiscordName(target).."("..nexa.getUserId(target)..")",function(player,details)
                                                                        if string.upper(details) == 'YES' then
                                                                            nexaclient.notify(player, {'~g~Rent offer sent!'})
                                                                            nexa.request(target,tnexa.getDiscordName(player).." wants to rent: " ..totalVehicles.. " vehicles Price: £"..getMoneyStringFormatted(amount*totalVehicles) .. ' | for: ' .. rent .. 'hours', 10, function(target,ok)
                                                                                if ok then
                                                                                    local pID = nexa.getUserId(target)
                                                                                    amount = totalVehicles*tonumber(amount)
                                                                                    if nexa.tryFullPayment(pID,amount) then
                                                                                        nexaclient.despawnGarageVehicle(player,{'car',15}) 
                                                                                        for a,b in pairs(vehiclesTable) do
                                                                                            nexa.getUserIdentity(pID, function(identity)
                                                                                                local rentedTime = os.time()
                                                                                                rentedTime = rentedTime  + (60 * 60 * tonumber(rent))
                                                                                                MySQL.execute("nexa/sell_vehicle_mods_player", {user_id = pID, oldUser = playerID, vehicle = a}) 
                                                                                                MySQL.execute("nexa/rentedupdate", {user_id = playerID, veh = a, id = pID, rented = 1, rentedid = playerID, rentedunix =  rentedTime }) 
                                                                                            end)
                                                                                            tnexa.sendWebhook('rent-vehicle', "nexa Rent Vehicle Logs", "> Renter Name: **"..tnexa.getDiscordName(player).."**\n> Renter TempID: **"..player.."**\n> Renter PermID: **"..playerID.."**\n> Rentee Name: **"..tnexa.getDiscordName(target).."**\n> Rentee TempID: **"..target.."**\n> Rentee PermID: **"..pID.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**\n> Duration: **"..rent.." hours**\n> Vehicle: **"..a.."**")
                                                                                        end
                                                                                        nexaclient.notify(player,{"~g~You have successfully rented multiple vehicles to "..tnexa.getDiscordName(target).." for £"..getMoneyStringFormatted(amount)..' for '..rent..' hours'})
                                                                                        nexaclient.notify(target,{"~g~"..tnexa.getDiscordName(player).." has successfully rented you multiple vehicles for £"..getMoneyStringFormatted(amount)..' for '..rent..' hours'})
                                                                                        nexa.giveBankMoney(playerID, amount)
                                                                                    else
                                                                                        nexaclient.notify(player,{"~r~".. tnexa.getDiscordName(target).." doesn't have enough money!"})
                                                                                        nexaclient.notify(target,{"~r~You don't have enough money!"})
                                                                                    end
                                                                                else
                                                                                    nexaclient.notify(player,{"~r~"..tnexa.getDiscordName(target).." has refused to rent multiple vehicles."})
                                                                                    nexaclient.notify(target,{"~r~You have refused to rent "..tnexa.getDiscordName(player).."'s multiple vehicles."})
                                                                                end
                                                                            end)
                                                                        else
                                                                            nexaclient.notify(player, {'~r~Rent offer cancelled!'})
                                                                        end
                                                                    end)
                                                                end
                                                            end
                                                        end)
                                                    end
                                                end)
                                            end 
                                        else
                                            nexaclient.notify(player,{"~r~The price of the car has to be a number."})
                                        end
                                    else 
                                        nexaclient.notify(player,{"~r~The rent time of the car has to be in hours and a number."})
                                    end
                                end)
							end)
						else
							nexaclient.notify(player,{"~r~That ID seems invalid."})
						end
					else
						nexaclient.notify(player,{"~r~No player ID selected."})
					end
				end)
			else
				nexaclient.notify(player,{"~r~No players nearby."})
			end
		end)
    end
end)


RegisterNetEvent('nexa:FetchRented')
AddEventHandler('nexa:FetchRented', function()
    local rentedin = {}
    local rentedout = {}
    local source = source
    local user_id = nexa.getUserId(source)
    MySQL.query("nexa/get_rented_vehicles_in", {user_id = user_id}, function(pvehicles, affected)
        for _, veh in pairs(pvehicles) do
            for i, v in pairs(vehicle_groups) do
                local config = vehicle_groups[i]._config
                local perm = config.permissions or nil
                if perm then
                    for i, v in pairs(perm) do
                        if not nexa.hasPermission(user_id, v) then
                            break
                        end
                    end
                end
                for a, z in pairs(v) do
                    if a ~= "_config" and veh.vehicle == a then
                        if not rentedin.vehicles then 
                            rentedin.vehicles = {}
                        end
                        local hoursLeft = ((tonumber(veh.rentedtime)-os.time()))/3600
                        local minutesLeft = nil
                        if hoursLeft < 1 then
                            minutesLeft = hoursLeft * 60
                            minutesLeft = string.format("%." .. (0) .. "f", minutesLeft)
                            datetime = minutesLeft .. " mins" 
                        else
                            hoursLeft = string.format("%." .. (0) .. "f", hoursLeft)
                            datetime = hoursLeft .. " hours" 
                        end
                        rentedin.vehicles[a] = {z[1], datetime, veh.rentedid, a}
                    end
                end
            end
        end
        MySQL.query("nexa/get_rented_vehicles_out", {user_id = user_id}, function(pvehicles, affected)
            for _, veh in pairs(pvehicles) do
                for i, v in pairs(vehicle_groups) do
                    local config = vehicle_groups[i]._config
                    local perm = config.permissions or nil
                    if perm then
                        for i, v in pairs(perm) do
                            if not nexa.hasPermission(user_id, v) then
                                break
                            end
                        end
                    end
                    for a, z in pairs(v) do
                        if a ~= "_config" and veh.vehicle == a then
                            if not rentedout.vehicles then 
                                rentedout.vehicles = {}
                            end
                            local hoursLeft = ((tonumber(veh.rentedtime)-os.time()))/3600
                            local minutesLeft = nil
                            if hoursLeft < 1 then
                                minutesLeft = hoursLeft * 60
                                minutesLeft = string.format("%." .. (0) .. "f", minutesLeft)
                                datetime = minutesLeft .. " mins" 
                            else
                                hoursLeft = string.format("%." .. (0) .. "f", hoursLeft)
                                datetime = hoursLeft .. " hours" 
                            end
                            rentedout.vehicles[a] = {z[1], datetime, veh.user_id, a}
                        end
                    end
                end
            end
            TriggerClientEvent('nexa:ReturnedRentedCars', source, rentedin, rentedout)
        end)
    end)
end)

RegisterNetEvent('nexa:CancelRent')
AddEventHandler('nexa:CancelRent', function(spawncode, VehicleName, a)
    local source = source
    local user_id = nexa.getUserId(source)
    if a == 'owner' then
        exports['ghmattimysql']:execute("SELECT * FROM nexa_user_vehicles WHERE rentedid = @id", {id = user_id}, function(result)
            if #result > 0 then 
                for i = 1, #result do 
                    if result[i].vehicle == spawncode and result[i].rented then
                        local target = nexa.getUserSource(result[i].user_id)
                        if target ~= nil then
                            nexaclient.notify(source, {"~g~Request sent."})
                            nexa.request(target,tnexa.getDiscordName(source).." would like to cancel the rent on the vehicle: ", 10, function(target,ok)
                                if ok then
                                    MySQL.execute('nexa/sell_vehicle_mods_player', {user_id = user_id, oldUser = result[i].user_id, vehicle = spawncode})
                                    MySQL.execute('nexa/rentedupdate', {id = user_id, rented = 0, rentedid = "", rentedunix = "", user_id = result[i].user_id, veh = spawncode})
                                    nexaclient.notify(target, {"~r~" ..VehicleName.." has been returned to the vehicle owner."})
                                    nexaclient.notify(source, {"~r~" ..VehicleName.." has been returned to your garage."})
                                else
                                    nexaclient.notify(source, {"~r~User has declined the request to cancel the rental of vehicle: " ..VehicleName})
                                end
                            end)
                        else
                            nexaclient.notify(source, {"~r~The player is not online."})
                        end
                    end
                end
            end
        end)
    elseif a == 'renter' then
        exports['ghmattimysql']:execute("SELECT * FROM nexa_user_vehicles WHERE user_id = @id", {id = user_id}, function(result)
            if #result > 0 then 
                for i = 1, #result do 
                    if result[i].vehicle == spawncode and result[i].rented then
                        local rentedid = tonumber(result[i].rentedid)
                        local target = nexa.getUserSource(rentedid)
                        if target ~= nil then
                            nexa.request(target,tnexa.getDiscordName(source).." would like to cancel the rent on the vehicle: ", 10, function(target,ok)
                                if ok then
                                    MySQL.execute('nexa/sell_vehicle_mods_player', {user_id = rentedid, oldUser = user_id, vehicle = spawncode})
                                    MySQL.execute('nexa/rentedupdate', {id = rentedid, rented = 0, rentedid = "", rentedunix = "", user_id = user_id, veh = spawncode})
                                    nexaclient.notify(source, {"~r~" ..VehicleName.." has been returned to the vehicle owner."})
                                    nexaclient.notify(target, {"~r~" ..VehicleName.." has been returned to your garage."})
                                else
                                    nexaclient.notify(source, {"~r~User has declined the request to cancel the rental of vehicle: " ..VehicleName})
                                end
                            end)
                        else
                            nexaclient.notify(source, {"~r~The player is not online."})
                        end
                    end
                end
            end
        end)
    end
end)

RegisterNetEvent('nexa:ExtendRent')
AddEventHandler('nexa:ExtendRent', function(spawncode, VehicleName)
    local source = source
    local user_id = nexa.getUserId(source)
    exports['ghmattimysql']:execute("SELECT * FROM nexa_user_vehicles WHERE rentedid = @id", {id = user_id}, function(result)
        if #result > 0 then 
            for i = 1, #result do 
                if result[i].vehicle == spawncode and result[i].rented then
                    nexa.prompt(source,"Extend time (hours):","",function(source,extendRentTime) 
                        extendRentTime = tonumber(extendRentTime)
                        if extendRentTime > 0 then
                            exports["ghmattimysql"]:executeSync("UPDATE nexa_user_vehicles SET rentedtime = @extendRentTime WHERE user_id = @user_id AND vehicle = @veh", {extendRentTime = extendRentTime*3600+result[i].rentedtime, user_id = result[i].user_id, veh = spawncode})
                            nexaclient.notify(source, {"~g~Extended rent time of "..VehicleName.." by "..extendRentTime.." hours."})
                        else
                            nexaclient.notify(source, {"~r~Invalid time."})
                            return
                        end
                    end)
                end
            end
        end
    end)
end)

RegisterNetEvent('nexa:attemptRepairVehicle')
AddEventHandler('nexa:attemptRepairVehicle', function(a, b)
    local user_id = nexa.getUserId(source)
    if nexa.tryGetInventoryItem(user_id,"repairkit",1,true) then
        nexaclient.repairVehicleDIY(source, {a})
    end
end)

RegisterNetEvent("nexa:PayVehicleTax")
AddEventHandler("nexa:PayVehicleTax", function()
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        local bank = nexa.getBankMoney(user_id)
        local payment = bank / 10000
        if nexa.tryBankPayment(user_id, payment) then
            nexaclient.notify(source,{"~g~Paid £"..getMoneyStringFormatted(math.floor(payment)).." vehicle tax."})
            TriggerEvent('nexa:addToCommunityPot', math.floor(payment))
        else
            nexaclient.notify(source,{"~r~Its fine... Tax payers will pay your vehicle tax instead."})
        end
    end
end)

RegisterNetEvent("nexa:refreshGaragePermissions")
AddEventHandler("nexa:refreshGaragePermissions",function()
    local source=source
    local garageTable={}
    local user_id = nexa.getUserId(source)
    for k,v in pairs(cfg.garages) do
        for a,b in pairs(v) do
            if a == "_config" then
                if json.encode(b.permissions) ~= '[""]' then
                    local hasPermissions = 0
                    for c,d in pairs(b.permissions) do
                        if nexa.hasPermission(user_id, d) then
                            hasPermissions = hasPermissions + 1
                        end
                    end
                    if hasPermissions == #b.permissions then
                        table.insert(garageTable, k)
                    end
                else
                    table.insert(garageTable, k)
                end
            end
        end
    end
    local ownedVehicles = {}
    if user_id then
        MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(pvehicles, affected)
            for k,v in pairs(pvehicles) do
                ownedVehicles[v.vehicle] = true
            end
            TriggerClientEvent('nexa:updateOwnedVehicles', source, ownedVehicles)
        end)
    end
    TriggerClientEvent("nexa:receiveRefreshedGaragePermissions",source,garageTable)
end)


RegisterNetEvent("nexa:getGarageFolders")
AddEventHandler("nexa:getGarageFolders",function()
    local source = source
    local user_id = nexa.getUserId(source)
    local garageFolders = {}
    local addedFolders = {}
    MySQL.query("nexa/get_vehicles", {user_id = user_id}, function(result)
        if result ~= nil then 
            for k,v in pairs(result) do
                local spawncode = v.vehicle 
                for a,b in pairs(vehicle_groups) do
                    if b._config.type == "vehicle" then
                        local hasPerm = true
                        if next(b._config.permissions) then
                            if not nexa.hasPermission(user_id, b._config.permissions[1]) then
                                hasPerm = false
                            end
                        end
                        if hasPerm then
                            for c,d in pairs(b) do
                                if c == spawncode and not v.impounded then
                                    if not addedFolders[a] then
                                        table.insert(garageFolders, {display = a})
                                        addedFolders[a] = true
                                    end
                                    for e,f in pairs (garageFolders) do
                                        if f.display == a then
                                            if f.vehicles == nil then
                                                f.vehicles = {}
                                            end
                                            table.insert(f.vehicles, {display = d[1], spawncode = spawncode})
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            -- local folderInfo = exports["ghmattimysql"]:executeSync("SELECT * from `nexa_custom_garages` WHERE user_id = @user_id", {user_id = user_id})
            -- if #folderInfo > 0 then
            --     local customFolders = json.decode(folderInfo[1].folder)
            --     for k,v in pairs(customFolders) do
            --         for k2, v2 in pairs(v) do
            --             for a,b in pairs(vehicle_groups) do
            --                 if b._config.type == "vehicle" then
            --                     for c,d in pairs(b) do
            --                         if c == v2 then
            --                             if not addedFolders[k] then
            --                                 table.insert(garageFolders, {display = k})
            --                                 addedFolders[k] = true
            --                             end
            --                             for e,f in pairs(garageFolders) do
            --                                 if f.display == k then
            --                                     if f.vehicles == nil then
            --                                         f.vehicles = {}
            --                                     end
            --                                     table.insert(f.vehicles, {display = d[1], spawncode = v2})
            --                                 end
            --                             end
            --                         end
            --                     end
            --                 end
            --             end
            --         end
            --     end
            -- end
            for k,v in pairs(garageFolders) do
                table.sort(v.vehicles, function(a,b) return a.display < b.display end)
            end
            TriggerClientEvent('nexa:setVehicleFolders', source, garageFolders)
        end
    end)
end)

Citizen.CreateThread(function()
    Wait(1500)
    exports['ghmattimysql']:execute([[
        CREATE TABLE IF NOT EXISTS `nexa_custom_garages` (
            `user_id` INT(11) NOT NULL AUTO_INCREMENT,
            `folder` TEXT NULL DEFAULT NULL COLLATE 'utf8mb4_general_ci',
            PRIMARY KEY (`user_id`) USING BTREE
        );
    ]])
end)
