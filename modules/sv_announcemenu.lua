local announceTables = {
    {permission = 'admin.managecommunitypot', info = {name = "Server Announcement", desc = "Announce something to the server", price = 0}, image = 'https://i.imgur.com/FZMys0F.png'},
    {permission = 'police.announce', info = {name = "PD Announcement", desc = "Announce something to the server", price = 10000}, image = 'https://i.imgur.com/I7c5LsN.png'},
    {permission = 'nhs.announce', info = {name = "NHS Announcement", desc = "Announce something to the server", price = 10000}, image = 'https://i.imgur.com/SypLbMo.png'},
    {permission = 'lfb.announce', info = {name = "LFB Announcement", desc = "Announce something to the server", price = 10000}, image = 'https://i.imgur.com/AFqPgYk.png'},
    {permission = 'hmp.announce', info = {name = "HMP Announcement", desc = "Announce something to the server", price = 10000}, image = 'https://i.imgur.com/rPF5FgQ.png'},
}

RegisterServerEvent("nexa:getAnnounceMenu")
AddEventHandler("nexa:getAnnounceMenu", function()
    local source = source
    local user_id = nexa.getUserId(source)
    local hasPermsFor = {}
    for k,v in pairs(announceTables) do
        if nexa.hasPermission(user_id, v.permission) or nexa.hasGroup(user_id, 'Founder') then
            table.insert(hasPermsFor, v.info)
        end
    end
    if #hasPermsFor > 0 then
        TriggerClientEvent("nexa:buildAnnounceMenu", source, hasPermsFor)
    end
end)

RegisterServerEvent("nexa:serviceAnnounce")
AddEventHandler("nexa:serviceAnnounce", function(announceType)
    local source = source
    local user_id = nexa.getUserId(source)
    for k,v in pairs(announceTables) do
        if v.info.name == announceType then
            if nexa.hasPermission(user_id, v.permission) or nexa.hasGroup(user_id, 'Founder') then
                if nexa.tryFullPayment(user_id, v.info.price) then
                    nexa.prompt(source,"Input text to announce","",function(source,data) 
                        if data == "" then return end
                        TriggerClientEvent('nexa:serviceAnnounceCl', -1, v.image, data)
                        if v.info.price > 0 then
                            nexaclient.notify(source, {"~g~Purchased a "..v.info.name.." for £"..v.info.price.." with content ~b~"..data})
                        else
                            nexaclient.notify(source, {"~g~Sending a "..v.info.name.." with content ~b~"..data})
                        end
                        tnexa.sendWebhook('announcements',"nexa Announcement Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Type: **"..announceType.."**\n> Message: **"..data.."**")
                    end)
                else
                    nexaclient.notify(source, {"~r~You do not have enough money to do this."})
                end
            else
                TriggerEvent("nexa:acBan", user_id, 11, tnexa.getDiscordName(source), source, 'Attempted to Trigger an announcement')
            end
        end
    end
end)