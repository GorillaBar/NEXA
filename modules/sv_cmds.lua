local chatCooldown = {}
local lastMsg = {}
local blockedWords = {
	"nigger", 
	"nigga", 
	"wog", 
	"coon", 
	"paki",
	"faggot",
	"kys",
	"negro",
	"n1gger",
	"f4ggot",
	"n0nce",
	"n1gg3r",
}

local emojis = {
	[":joy:"] = "😃",
	[":sob:"] = "😭",
	[":heart:"] = "❤️",
	[":thumbsup:"] = "👍",
	[":thumbsdown:"] = "👎",
	[":fire:"] = "🔥",
	[":star:"] = "⭐️",
	[":smile:"] = "😊",
	[":laugh:"] = "😄",
	[":wink:"] = "😉",
	[":grin:"] = "😁",
	[":sad:"] = "😔",
	[":angry:"] = "😠",
	[":cry:"] = "😢",
	[":confused:"] = "😕",
	[":surprised:"] = "😮",
	[":sleeping:"] = "😴",
	[":neutral:"] = "😐",
	[":rose:"] = "🌹",
	[":birthday:"] = "🎂",
	[":emo:"] = "🖤",
}

local function checkEmojis(message)
	for k,v in pairs(emojis) do
		message = string.gsub(message, k, v)
	end
	return message
end

local function checkBlacklistedWords(message, source)
	for word in pairs(blockedWords) do
		if(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(string.gsub(message:lower(), "-", ""), ",", ""), "%.", ""), " ", ""), "*", ""), "+", ""):find(blockedWords[word])) then
			TriggerClientEvent('nexa:chatFilterScaleform', source, 10, 'That word is not allowed.')
			CancelEvent()
			return false
		end
	end
	return true
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(3000)
		for k,v in pairs(chatCooldown) do
			chatCooldown[k] = nil
		end
	end
end)

--Dispatch Message
RegisterCommand("anon", function(source, args, raw)
    if #args <= 0 then 
		return 
	end
	local source = source
	local name = tnexa.getDiscordName(source)
    local message = table.concat(args, " ")
	local user_id = nexa.getUserId(source)
	if not chatCooldown[source] then 
		if checkBlacklistedWords(message, source) then
			if lastMsg[user_id] == message then
				TriggerClientEvent('chatMessage', source, "^1[nexa]", { 128, 128, 128 }, " Your current message cannot match your last message.", "alert")
			else
				message = checkEmojis(message)
				lastMsg[user_id] = message
				tnexa.sendWebhook('anon', "nexa Chat Logs", "```"..message.."```".."\n> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Player TempID: **"..source.."**")
				TriggerClientEvent('chatMessage', -1, "^4Twitter @^1Anonymous: ", { 128, 128, 128 }, message, "ooc")
				chatCooldown[source] = true
			end
		end
	end
end)
  

function tnexa.ooc(source, args, raw)
	if #args <= 0 then 
		return 
	end
	local source = source
	local name = tnexa.getDiscordName(source)
	local message = table.concat(args, " ")
	local user_id = nexa.getUserId(source)
	if not chatCooldown[source] then 
		if checkBlacklistedWords(message, source) then
			if lastMsg[user_id] == message then
				TriggerClientEvent('chatMessage', source, "^1[nexa]", { 128, 128, 128 }, " Your current message cannot match your last message.", "alert")
			else
				message = checkEmojis(message)
				lastMsg[user_id] = message
				if nexa.hasGroup(user_id, "Founder") then
					TriggerClientEvent('chatMessage', -1, "^7OOC |^8 Founder ^7"..tnexa.getDiscordName(source)..":", { 128, 128, 128 }, message, "ooc")
				elseif nexa.hasGroup(user_id, "Management") then
					TriggerClientEvent('chatMessage', -1, "^7OOC |^6 Management ^7"..tnexa.getDiscordName(source)..":", { 128, 128, 128 }, message, "ooc")
					chatCooldown[source] = true
				elseif nexa.hasGroup(user_id, "Staff") then
					TriggerClientEvent('chatMessage', -1, "^7OOC |^2 Staff ^7"..tnexa.getDiscordName(source)..":", { 128, 128, 128 }, message, "ooc")				
					chatCooldown[source] = true
				elseif nexa.hasGroup(user_id, "Supporter") then
					TriggerClientEvent('chatMessage', -1, "^7OOC | ^2"..tnexa.getDiscordName(source)..":", { 128, 128, 128 }, message, "ooc")
					chatCooldown[source] = true
				else
					TriggerClientEvent('chatMessage', -1, "^7OOC | ^7"..tnexa.getDiscordName(source)..":", { 128, 128, 128 }, message, "ooc")
					chatCooldown[source] = true
				end
				tnexa.sendWebhook('ooc', "nexa Chat Logs", "```"..message.."```".."\n> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Player TempID: **"..source.."**")
			end
		end
	else
		TriggerClientEvent('chatMessage', source, "^1[nexa]", { 128, 128, 128 }, " Chat Spam | Retry in 3 Seconds", "alert")
		chatCooldown[source] = true
	end
end

RegisterCommand("ooc", function(source, args, raw)
    tnexa.ooc(source, args, raw)
end)

RegisterCommand("/", function(source, args, raw)
    tnexa.ooc(source, args, raw)
end)

function nexa.ooc(source, args) -- ooc from chat with //
	args[1] = args[1]:sub(3)
	tnexa.ooc(source, args)
end


RegisterCommand('cc', function(source, args, rawCommand)
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, 'admin.ban') then
        TriggerClientEvent('chat:clear',-1)             
    end
end, false)


--Function
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