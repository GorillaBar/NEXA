local verifyCodes = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000)
        for k,v in pairs(verifyCodes) do
            if verifyCodes[k] ~= nil then
                verifyCodes[k] = nil
            end
        end
    end
end)

RegisterServerEvent('nexa:changeLinkedDiscord', function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.prompt(source,"Enter Discord Id:","",function(source,discordid) 
        if discordid ~= nil then
            TriggerClientEvent('nexa:gotDiscord', source)
            nexaclient.generateUUID(source, {"linkcode", 5, "alphanumeric"}, function(code)
                verifyCodes[user_id] = {code = code, discordid = discordid}
                exports['nexa-bot']:dmUser(source, {discordid, code, user_id}, function()end)
            end)
        end
	end)
end)


RegisterServerEvent('nexa:enterDiscordCode', function()
    local source = source
    local user_id = nexa.getUserId(source)
    nexa.prompt(source,"Enter Code:","",function(source,code) 
        if code ~= nil then
            if verifyCodes[user_id].code == code then
                local prevDiscord = exports['ghmattimysql']:executeSync("SELECT * FROM `nexa_verification` WHERE user_id = @user_id", {user_id = user_id})[1].discord_id
                local newDiscord = verifyCodes[user_id].discordid
                exports['ghmattimysql']:execute("UPDATE `nexa_verification` SET discord_id = @discord_id WHERE user_id = @user_id", {user_id = user_id, discord_id = newDiscord}, function() end)
                exports['ghmattimysql']:execute("DELETE FROM `nexa_verification` WHERE discord_id = @discord_id AND user_id != @user_id", {discord_id = newDiscord, user_id = user_id}, function() end)
                nexaclient.notify(source, {'~g~Your discord has been successfully updated please leave and rejoin the discord if needed.'})
                exports['nexa-bot']:verifyDiscord(source, {prevDiscord, newDiscord}, function()end)
            end
        end
	end)
end)
