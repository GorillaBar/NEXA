local outfitCodes = {}

RegisterNetEvent("nexa:saveWardrobeOutfit")
AddEventHandler("nexa:saveWardrobeOutfit", function(outfitName)
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:home:wardrobe", function(data)
        local sets = json.decode(data)
        if sets == nil then
            sets = {}
        end
        nexaclient.getCustomization(source,{},function(custom)
            sets[outfitName] = custom
            nexa.setUData(user_id,"nexa:home:wardrobe",json.encode(sets))
            nexaclient.notify(source,{"~g~Saved outfit "..outfitName.." to wardrobe!"})
            TriggerClientEvent("nexa:refreshOutfitMenu", source, sets)
        end)
    end)
end)

RegisterNetEvent("nexa:deleteWardrobeOutfit")
AddEventHandler("nexa:deleteWardrobeOutfit", function(outfitName)
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:home:wardrobe", function(data)
        local sets = json.decode(data)
        if sets == nil then
            sets = {}
        end
        sets[outfitName] = nil
        nexa.setUData(user_id,"nexa:home:wardrobe",json.encode(sets))
        nexaclient.notify(source,{"~r~Removed outfit "..outfitName.." from wardrobe!"})
        TriggerClientEvent("nexa:refreshOutfitMenu", source, sets)
    end)
end)

RegisterNetEvent("nexa:equipWardrobeOutfit")
AddEventHandler("nexa:equipWardrobeOutfit", function(outfitName)
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:home:wardrobe", function(data)
        local sets = json.decode(data)
        nexaclient.setCustomization(source, {sets[outfitName]})
        nexaclient.getHairAndTats(source, {})
    end)
end)

RegisterNetEvent("nexa:initWardrobe")
AddEventHandler("nexa:initWardrobe", function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.getUData(user_id, "nexa:home:wardrobe", function(data)
        local sets = json.decode(data)
        if sets == nil then
            sets = {}
        end
        TriggerClientEvent("nexa:refreshOutfitMenu", source, sets)
    end)
end)

RegisterNetEvent("nexa:getCurrentOutfitCode")
AddEventHandler("nexa:getCurrentOutfitCode", function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexaclient.getCustomization(source,{},function(custom)
        nexaclient.generateUUID(source, {"outfitcode", 5, "alphanumeric"}, function(uuid)
            local uuid = string.upper(uuid)
            outfitCodes[uuid] = custom
            nexaclient.CopyToClipboard(source, {uuid})
            nexaclient.notify(source, {"~g~Outfit code copied to clipboard."})
            nexaclient.notify(source, {"The code ~y~"..uuid.."~w~ will persist until restart."})
        end)
    end)
end)

RegisterNetEvent("nexa:applyOutfitCode")
AddEventHandler("nexa:applyOutfitCode", function(outfitCode)
    local source = source
    local user_id = nexa.getUserId(source)
    if outfitCodes[outfitCode] ~= nil then
        nexaclient.setCustomization(source, {outfitCodes[outfitCode]})
        nexaclient.notify(source, {"~g~Outfit code applied."})
        nexaclient.getHairAndTats(source, {})
    else
        nexaclient.notify(source, {"~r~Outfit code not found."})
    end
end)

RegisterCommand('wardrobe', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasGroup(user_id, 'Founder') then
        TriggerClientEvent("nexa:openOutfitMenu", source)
    end
end)

RegisterCommand('copyfit', function(source, args)
    local source = source
    local user_id = nexa.getUserId(source)
    local permid = tonumber(args[1])
    if nexa.hasGroup(user_id, 'Founder') then
        local target = nexa.getUserSource(permid)
        if target ~= nil then
            nexaclient.getCustomization(target,{},function(custom)
                nexaclient.setCustomization(source, {custom})
            end)
        else
            nexaclient.notify(source, {"~r~Player not found."})
        end
    end
end)