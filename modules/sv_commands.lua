RegisterCommand("getmyid", function(source)
    TriggerClientEvent('chatMessage', source, "^1[nexa]^1", {255, 255, 255}, " Perm ID: " .. nexa.getUserId(source) , "alert")
    nexaclient.CopyToClipboard(source, {nexa.getUserId(source)})
    nexaclient.notify(source, {'~g~Perm ID copied to clipboard.'})
end)

RegisterCommand("getmytempid", function(source)
	TriggerClientEvent('chatMessage', source, "^1[nexa]^1", {255, 255, 255}, " Temp ID: " .. source, "alert")
    nexaclient.CopyToClipboard(source, {source})
    nexaclient.notify(source, {'~g~Temp ID copied to clipboard.'})
end)

RegisterCommand("a", function(source,args, rawCommand)
    if #args <= 0 then return end
	local name = tnexa.getDiscordName(source)
    local message = table.concat(args, " ")
    local user_id = nexa.getUserId(source)
    if nexa.hasPermission(user_id, "admin.tickets") then
        tnexa.sendWebhook('staff', "nexa Chat Logs", "```"..message.."```".."\n> Admin Name: **"..name.."**\n> Admin PermID: **"..user_id.."**\n> Admin TempID: **"..source.."**")
        for k,v in pairs(nexa.getUsersByPermission('admin.tickets')) do
            TriggerClientEvent('chatMessage', nexa.getUserSource(v), "^3Admin Chat | " .. name..": " , { 128, 128, 128 }, message, "ooc")
        end
    end
end)

RegisterCommand("g", function(source,args, rawCommand)
    local source = source
    local user_id = nexa.getUserId(source)   
    local peoplesids = {}
    local gangmembers = {}
    local msg = rawCommand:sub(2)
    MySQL.query("nexa/get_gang", {user_id = user_id}, function(rows, affected)
		if #rows > 0 then
			local gangName = rows[1].gangname
			local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
            local playerName = string.format("^2[%s] %s: ", gangName, tnexa.getDiscordName(source))
			for K,V in pairs(gotGangs) do
				for I,L in pairs(json.decode(V.gangmembers)) do
					local player = nexa.getUserSource(tonumber(I))
                    if player ~= nil then
                        TriggerClientEvent('chatMessage', player, playerName , { 128, 128, 128 }, msg, "ooc")
                        tnexa.sendWebhook('gang', "nexa Chat Logs", "```"..msg.."```".."\n> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Player TempID: **"..source.."**")
                    end
				end
			end
		end
	end)
end)

RegisterCommand('cinematicmenu', function(source)
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.hasGroup(user_id, 'Cinematic') then
        TriggerClientEvent('nexa:openCinematicMenu', source)
    end
end)

RegisterCommand("me", function(source, args)
    local text = table.concat(args, " ")
    local user_id = nexa.getUserId(source)
    tnexa.sendWebhook('slash-me',"nexa Slash Me Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player TempID: **"..source.."**\n> Player PermID: **"..user_id.."**\n> Message: **"..text.."**")
    TriggerClientEvent('nexa:sendLocalChat', -1, source, tnexa.getDiscordName(source), text)
end)

RegisterServerEvent("nexa:unstuckSuccessful")
AddEventHandler("nexa:unstuckSuccessful", function(d, e)
    local source = source
    local user_id = nexa.getUserId(source)
    print('Unstuck Successful: ' .. user_id .. ' | ' .. source .. ' | ' .. d .. ' | ' .. e)
end)