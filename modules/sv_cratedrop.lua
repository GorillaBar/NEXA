currentCrate = {}
local crateID = 0
local spawnTime = 20*60
local rigActive = false
local crateShit = {
    normal = {
        vector3(375.0662, 6852.992, 5.083869), -- Paleto beach
        vector3(-880.6389, 4414.064, 21.36799), -- Large arms bridge
        vector3(-3032.489, 3402.802, 9.417397), -- mil base beach
        vector3(-2466.4360, 2659.6577, 1.6662), -- mil base by lsd process
        vector3(-119.2925, 3022.1, 33.18053), -- diamond mine river
        vector3(36.50002, 4344.443, 42.47789), -- Island by large tunnel / north lsd
        vector3(-1518.191, 2140.92, 56.53791), -- wine mansion
        vector3(-191.0104, 1477.419, 289.4325), -- Vinewood 1
        vector3(828.4253, 1300.878, 364.6823), -- Vinewood sign
        vector3(2348.622, 2138.061, 105.3607), -- wind turbines
        vector3(1877.604, 352.0831, 163.9319), -- The dam by casino
        vector3(2836.016, -1447.626, 11.45845), -- island near lsd
        vector3(2543.626, 3615.884, 98.10089), -- Youtool hill
        vector3(2856.744, 4631.319, 49.39237), -- H Bunker
        vector3(4784.917, -5530.945, 20.46264), -- Cayo Perico
        vector3(254.3428, 3583.882, 34.73079), -- Biker city
        vector3(1079.236, 3014.627, 41.77089), -- sandy airfield
        vector3(2540.845, -382.251, 93.49357), -- lsd
        vector3(3551.443, 3722.43, 37.85273), -- heroin gardens
        vector3(2065.76, 4777.352, 41.56038), -- grapeseed
        vector3(-1880.101, 3052.17, 33.31055), -- mil base by hangar
    },
    rig = vector3(-1708.557, 8879.044, 31.0289),
    weapons = {
        {"wbody|WEAPON_UMP45", 1},
        {"wbody|WEAPON_MPX", 1},
        {"wbody|WEAPON_UZI", 1},
        {"wbody|WEAPON_MOSIN", 1},
        {"wbody|WEAPON_AK200", 1},
        {"wbody|WEAPON_AKM", 1},
        {"wbody|WEAPON_GOLDAK", 1},
        {"wbody|WEAPON_MXM", 1},
        {"wbody|WEAPON_SPAR16", 1},
    },
    ammo = {
        {"9mm Bullets", 250},
        {"9mm Bullets", 250},
        {"5.56mm NATO", 250},
        {"5.56mm NATO", 250},
        {"7.62mm Bullets", 250},
        {"7.62mm Bullets", 250},
    },
}

local function rigLoot(lootTable)
    local randomSniper = math.random(1,2)
    if randomSniper == 1 then
        lootTable["wbody|WEAPON_SVD"] = {ItemName = nexa.getItemName("wbody|WEAPON_SVD"), Weight = nexa.getItemWeight("wbody|WEAPON_SVD"), amount = 1}
    else
        lootTable["wbody|WEAPON_MK14"] = {ItemName = nexa.getItemName("wbody|WEAPON_MK14"), Weight = nexa.getItemWeight("wbody|WEAPON_MK14"), amount = 1}
    end
    lootTable[".308 Sniper Rounds"] = {ItemName = nexa.getItemName(".308 Sniper Rounds"), Weight = nexa.getItemWeight(".308 Sniper Rounds"), amount = 150}
    lootTable["sapphire"] = {ItemName = nexa.getItemName("sapphire"), Weight = nexa.getItemWeight("sapphire"), amount = math.random(15, 20)}
    return lootTable
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(1000)
        if next(currentCrate) then
            if currentCrate.timeTillOpen > 0 then
                currentCrate.timeTillOpen = currentCrate.timeTillOpen - 1
            end
        end
    end
end)


AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        if next(currentCrate) then
            TriggerClientEvent('nexa:addCrateDropRedzone', source, currentCrate.crateID, currentCrate.crateCoords)
        end
    end
end)

RegisterServerEvent('nexa:openCrate', function(id)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.isEmergencyService(user_id) then
        nexaclient.notify(source, {'~r~You cannot open this crate whilst clocked on.'})
        return
    end
    if crateID ~= id then return end
    if next(currentCrate) then
        if currentCrate.timeTillOpen > 0 then
            nexaclient.notify(source, {'~r~Loot crate unlocking in '..currentCrate.timeTillOpen..' seconds.'})
            return
        else
            if #(GetEntityCoords(GetPlayerPed(source)) - currentCrate.crateCoords) > 5.0 then
                return
            end
            TriggerClientEvent('nexa:SendSecondaryInventoryData', source, currentCrate.crateLoot, nexa.computeItemsWeight(currentCrate.crateLoot), 200)
        end
    end
end)

Citizen.CreateThread(function()
    while true do
        if next(currentCrate) and not rigActive then
            TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "The airdrop has disappeared.", "alert")
            TriggerClientEvent("nexa:removeLootcrate", -1, currentCrate.crateID)
            currentCrate = {}
        end
        Wait(3*60*1000)
        if not rigActive and #GetPlayers() > 10 then
            crateID = crateID + 1
            local randomCoords = crateShit.normal[math.random(1, #crateShit.normal)]
            local crateCoords = randomCoords
            TriggerClientEvent('nexa:crateDrop', -1, crateCoords, crateID, false)
            local loot = {}
            for i=1, 6 do
                local randomWeapon = math.random(1, #crateShit.weapons)
                local randomAmmo = math.random(1, #crateShit.ammo)
                for k,v in pairs(crateShit.weapons) do
                    if k == randomWeapon then loot[v[1]] = {ItemName = nexa.getItemName(v[1]), Weight = nexa.getItemWeight(v[1]), amount = v[2]} end
                end
                for k,v in pairs(crateShit.ammo) do
                    if k == randomAmmo then loot[v[1]] = {ItemName = nexa.getItemName(v[1]), Weight = nexa.getItemWeight(v[1]), amount = v[2]} end
                end
            end
            currentCrate = {oilrig = false, timeTillOpen = 300, crateLoot = loot, crateCoords = crateCoords, crateID = crateID}
            TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "A cartel plane carrying supplies has had to bail and is parachuting to the ground! Get to it quick, check your GPS!", "alert")
        end
        Wait(30*60*1000)
    end
end)

Citizen.CreateThread(function()
    while true do
        rigActive = false
        if next(currentCrate) then
            TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "The airdrop has disappeared.", "alert")
            TriggerClientEvent("nexa:removeLootcrate", -1, currentCrate.crateID)
            currentCrate = {}
        end
        Wait(2*60*60*1000)
        rigActive = true
        if rigActive and #GetPlayers() > 30 then
            crateID = crateID + 1
            local crateCoords = crateShit.rig
            TriggerClientEvent('nexa:crateDrop', -1, crateCoords, crateID, true)
            local loot = {}
            for i=1, 12 do
                local randomWeapon = math.random(1, #crateShit.weapons)
                local randomAmmo = math.random(1, #crateShit.ammo)
                for k,v in pairs(crateShit.weapons) do
                    if k == randomWeapon then loot[v[1]] = {ItemName = nexa.getItemName(v[1]), Weight = nexa.getItemWeight(v[1]), amount = v[2]} end
                end
                for k,v in pairs(crateShit.ammo) do
                    if k == randomAmmo then loot[v[1]] = {ItemName = nexa.getItemName(v[1]), Weight = nexa.getItemWeight(v[1]), amount = v[2]} end
                end
            end
            loot = rigLoot(loot)
            currentCrate = {oilrig = true, timeTillOpen = 600, crateLoot = loot, crateCoords = crateCoords, crateID = crateID}
            TriggerClientEvent('chatMessage', -1, "^0EVENT | ", {66, 72, 245}, "A cartel plane carrying supplies has had to bail and is parachuting to the ground! Get to it quick, check your GPS!", "alert")
        end
        Wait(60*60*1000)
    end
end)
