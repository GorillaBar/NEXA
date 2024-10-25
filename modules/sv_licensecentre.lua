
local cfg = module("cfg/cfg_licensecentre")

RegisterServerEvent("nexa:buyLicense")
AddEventHandler('nexa:buyLicense', function(job, name)
    local source = source
    local user_id = nexa.getUserId(source)
    local coords = cfg.location
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    if not nexa.hasGroup(user_id, "Rebel") and job == "AdvancedRebel" then
        nexaclient.notify(source, {"~r~You need to have Rebel License."})
        return
    end
    if #(playerCoords - coords) <= 15.0 then
        if nexa.hasGroup(user_id, job) then 
            nexaclient.notify(source, {"~o~You have already purchased this license!"})
            TriggerClientEvent("nexa:PlaySound", source, 2)
        else
            for k,v in pairs(cfg.licenses) do
                if v.group == job then
                    if nexa.tryFullPayment(user_id, v.price) then
                        nexa.addUserGroup(user_id,job)
                        nexaclient.notify(source, {"~g~Purchased " .. name .. " for ".. '£' ..tostring(getMoneyStringFormatted(v.price)) .. " ❤️"})
                        tnexa.sendWebhook('purchases',"nexa License Centre Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Purchased: **"..name.."**")
                        TriggerClientEvent("nexa:PlaySound", source, "money")
                        TriggerClientEvent("nexa:gotOwnedLicenses", source, getLicenses(user_id))
                        TriggerClientEvent("nexa:refreshGunStorePermissions", source)
                    else 
                        nexaclient.notify(source, {"~r~You do not have enough money to purchase this license!"})
                        TriggerClientEvent("nexa:PlaySound", source, 2)
                    end
                end
            end
        end
    else 
        TriggerEvent("nexa:acBan", userid, 11, tnexa.getDiscordName(source), source, 'Trigger License Menu Purchase')
    end
end)

RegisterServerEvent("nexa:refundLicense")
AddEventHandler('nexa:refundLicense', function(job, name)
    local source = source
    local user_id = nexa.getUserId(source)
    local coords = cfg.location
    local ped = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(ped)
    if #(playerCoords - coords) <= 15.0 then
        if not nexa.hasGroup(user_id, job) then 
            nexaclient.notify(source, {"~o~You have already purchased this license!"})
            TriggerClientEvent("nexa:PlaySound", source, 2)
        else
            for k,v in pairs(cfg.licenses) do
                if v.group == job then
                    nexa.giveBankMoney(user_id, v.price*0.2)
                    nexa.removeUserGroup(user_id,job)
                    nexaclient.notify(source, {"~g~Refunded " .. name .. " for ".. '£' ..tostring(getMoneyStringFormatted(v.price*0.2)) .. " ❤️"})
                    tnexa.sendWebhook('purchases',"nexa License Centre Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Refunded: **"..name.."**")
                    TriggerClientEvent("nexa:PlaySound", source, "money")
                    TriggerClientEvent("nexa:gotOwnedLicenses", source, getLicenses(user_id))
                    TriggerClientEvent("nexa:refreshGunStorePermissions", source)
                end
            end
        end
    else 
        TriggerEvent("nexa:acBan", userid, 11, tnexa.getDiscordName(source), source, 'Trigger License Menu Purchase')
    end
end)

function getLicenses(user_id)
    local licenses = {}
    if user_id ~= nil then
        for k, v in pairs(cfg.licenses) do
            if nexa.hasGroup(user_id, v.group) then
                licenses[v.name] = true
            end
        end
        return licenses
    end
end

RegisterNetEvent("nexa:GetLicenses")
AddEventHandler("nexa:GetLicenses", function()
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        TriggerClientEvent("nexa:ReceivedLicenses", source, getLicenses(user_id))
    end
end)

RegisterNetEvent("nexa:getOwnedLicenses")
AddEventHandler("nexa:getOwnedLicenses", function()
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil then
        TriggerClientEvent("nexa:gotOwnedLicenses", source, getLicenses(user_id))
    end
end)