local webhooks = {
    -- general
    ['join'] = '',
    ['leave'] = '',
    -- civ
    ['give-cash'] = '',
    ['bank-transfer'] = '',
    ['moneybag-logs'] = '',
    ['search-player'] = '',
    ['purchases'] = '',
    ['weapon-shops'] = '',
    ['kills'] = '',
    ['kill-vids'] = '',
    ['damage'] = '',
    ['gang-logs'] = '',
    -- chat
    ['ooc'] = '',
    ['twitter'] = '',
    ['staff'] = '',
    ['gang'] = '',
    ['anon'] = '',
    ['slash-me'] = '',
    ['announcements'] = '',
    -- admin menu
    ['kick-player'] = '',
    ['ban-player'] = '',
    ['spectate'] = '',
    ['revive'] = '',
    ['tp-player-to-me'] = '',
    ['tp-to-player'] = '',
    ['tp-to-admin-zone'] = '',
    ['tp-back-from-admin-zone'] = '',
    ['tp-to-legion'] = '',
    ['freeze'] = '',
    ['slap'] = '',
    ['force-clock-off'] = '',
    ['screenshot'] = '',
    ['video'] = '',
    ['group'] = '',
    ['unban-player'] = '',
    ['remove-warning'] = '',
    ['add-car'] = '',
    ['manage-balance'] = '',
    ['ticket-logs'] = '',
    ['com-pot'] = '',
    -- vehicles
    ['crush-vehicle'] = '',
    ['rent-vehicle'] = '',
    ['sell-vehicle'] = '',
    -- casino
    ['blackjack-bet'] = '',
    ['blackjack-outcomes'] = '',
    ['coinflip-outcomes'] = '',
    ['purchase-chips'] = '',
    ['sell-chips'] = '',
    ['purchase-highrollers'] = '',
    -- housing
    ['buy-home'] = '',
    ['sell-home'] = '',
    ['rent-home'] = '',
    -- anticheat
    ['anticheat'] = '',
    ['ban-evaders'] = '',
    ['multi-accounting'] = '',
    ['hs-logs'] = '',
    -- dono
    ['donation'] = '',
    ['add-packages'] = '',
    ['redeem-packages'] = '',
    ['sell-packages'] = ''
}

local webhookQueue = {}
Citizen.CreateThread(function()
    while true do
        if next(webhookQueue) then
            for k,v in pairs(webhookQueue) do
                Citizen.Wait(100)
                if webhooks[v.webhook] ~= nil then
                    PerformHttpRequest(webhooks[v.webhook], function(err, text, headers) 
                    end, "POST", json.encode({username = "nexa Logs", avatar_url = 'https://i.imgur.com/onQ6UBz.png', embeds = {
                        {
                            ["color"] = 0xd16feb,
                            ["title"] = v.name,
                            ["description"] = v.message,
                            ["footer"] = {
                                ["text"] = "nexa - "..v.time,
                                ["icon_url"] = "",
                            }
                    }
                    }}), { ["Content-Type"] = "application/json" })
                end
                webhookQueue[k] = nil
            end
        end
        Citizen.Wait(0)
    end
end)
local webhookID = 1
function tnexa.sendWebhook(webhook, name, message)
    webhookID = webhookID + 1
    webhookQueue[webhookID] = {webhook = webhook, name = name, message = message, time = os.date("%c")}
end

function nexa.sendWebhook(webhook, name, message) -- used for other resources to send through webhook logs 
   tnexa.sendWebhook(webhook, name, message)
end

function tnexa.getWebhook(webhook)
    if webhooks[webhook] ~= nil then
        return webhooks[webhook]
    end
end