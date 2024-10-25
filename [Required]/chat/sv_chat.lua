local Tunnel = module("nexa", "lib/Tunnel")
local Proxy = module("nexa", "lib/Proxy")
nexa = Proxy.getInterface("nexa")
nexaclient = Tunnel.getInterface("nexa","nexa_CHAT")

RegisterServerEvent('chat:init')
RegisterServerEvent('chat:addTemplate')
RegisterServerEvent('chat:addMessage')
RegisterServerEvent('chat:addSuggestion')
RegisterServerEvent('chat:removeSuggestion')
RegisterServerEvent('_chat:messageEntered')
RegisterServerEvent('chat:clear')
RegisterServerEvent('__cfx_internal:commandFallback')

local blockedWords = {
"nigger", 
"nigga", 
"wog", 
"coon", 
"paki",
"faggot",
"anal",
"kys",
"homosexual",
"lesbian",
"suicide",
"negro",
"queef",
"queer",
"allahu akbar",
"terrorist",
"wanker",
"n1gger",
"f4ggot",
"n0nce",
"d1ck",
"h0m0",
"n1gg3r",
"h0m0s3xual",
"nazi",
"hitler"}
local lastMsg = {}

function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function getMoneyStringFormatted(cashString)
	local i, j, minus, int, fraction = tostring(cashString):find('([-]?)(%d+)([.]?%d*)')
	int = int:reverse():gsub("(%d%d%d)", "%1,")
	return minus .. int:reverse():gsub("^,", "") .. fraction 
end

-- minigame

local charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'
local endString = ''
local moneyPrize = 0
local minigameWon = false
Citizen.CreateThread(function()
    while true do
        endString = ''
        moneyPrize = math.random(15000,25000)
        for i = 1, 6 do
            local randomString = math.random(#charset)
            endString = endString .. string.sub(charset, randomString, randomString)
        end
        Citizen.Wait(3000)
        minigameWon = false
        TriggerClientEvent('chatMessage', -1, "^2[Mini-Event]" , { 128, 128, 128 }, "^2Write the word: ^1"..endString.." ^2to get £"..getMoneyStringFormatted(moneyPrize), "ooc")
        Citizen.Wait(20*60000)
        if not minigameWon then
            TriggerClientEvent('chatMessage', -1, "^2[Mini-Event]" , { 128, 128, 128 }, "^2The mini event is over no one guessed the word", "ooc")
        end
        Citizen.Wait(5*60000)
    end
end)

AddEventHandler('_chat:messageEntered', function(author, color, message)
    local source = source
    if not message or not author then
        return
    end
    local user_id = nexa.getUserId({source})
    local name = nexa.getDiscordName({user_id})
    if author ~= GetPlayerName(source) then
        TriggerEvent("nexa:acBan", user_id, 11, name, source, 'Attempted to spoof chat username')
        return
    end
    if not WasEventCanceled() then
        for word in pairs(blockedWords) do
            if(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(message:lower(), "-", ""), ",", ""), "%.", ""), " ", ""), "*", ""), "+", ""):find(blockedWords[word])) then
                TriggerClientEvent('nexa:chatFilterScaleform', source, 10, 'That word is not allowed.')
                CancelEvent()
                return
            end
        end
        if lastMsg[user_id] == message then
            TriggerClientEvent('chatMessage', source, "^1[nexa]", { 128, 128, 128 }, " Your current message cannot match your last message.", "alert")
        else
            lastMsg[user_id] = message
            TriggerClientEvent('chatMessage', -1, "Twitter @"..name..":",  { 255, 255, 255 }, message, "twt")
            nexa.sendWebhook({'twitter', "nexa Chat Logs", "```"..message.."```".."\n> Player Name: **"..name.."**\n> Player PermID: **"..nexa.getUserId({source}).."**\n> Player TempID: **"..source.."**"})
            if not minigameWon then
                if message:lower() == endString:lower() then
                    nexa.giveMoney({nexa.getUserId({source}), moneyPrize})
                    minigameWon = true
                    TriggerClientEvent('chatMessage', -1, "^^2[Mini-Event]" , { 128, 128, 128 }, "^1"..name.." ^2wrote the word first and won £"..getMoneyStringFormatted(moneyPrize), "ooc")
                end
            end
        end
    end

    print(name .. '^7: ' .. message .. '^7')
end)

AddEventHandler('__cfx_internal:commandFallback', function(command)
    local name = GetPlayerName(source)

    TriggerEvent('chatMessage', source, name, '/' .. command)

    if not WasEventCanceled() then
        TriggerClientEvent('chatMessage', -1, name, { 255, 255, 255 }, '/' .. command) 
    end

    CancelEvent()
end)

-- command suggestions for clients
local function refreshCommands(player)
    if GetRegisteredCommands then
        local registeredCommands = GetRegisteredCommands()

        local suggestions = {}

        for _, command in ipairs(registeredCommands) do
            if IsPlayerAceAllowed(player, ('command.%s'):format(command.name)) then
                table.insert(suggestions, {
                    name = '/' .. command.name,
                    help = ''
                })
            end
        end

        TriggerClientEvent('chat:addSuggestions', player, suggestions)
    end
end

AddEventHandler('chat:init', function()
    refreshCommands(source)
end)

AddEventHandler('onServerResourceStart', function(resName)
    Wait(500)

    for _, player in ipairs(GetPlayers()) do
        refreshCommands(player)
    end
end)

AddEventHandler('chatMessage', function(Source, Name, Msg)
    args = stringsplit(Msg, " ")
    CancelEvent()
    if string.find(args[1], "//") then
        nexa.ooc({Source, args})
    elseif string.find(args[1], "/") then
        local cmd = args[1]
        table.remove(args, 1)
	else
		TriggerClientEvent('chatMessage', -1, Name, { 255, 255, 255 }, Msg)
	end
end)

function stringsplit(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end
