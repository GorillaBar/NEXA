local voteCooldown = 1800
local weatherVoterCooldown = voteCooldown
local weatherVotes = {}
local currentWeather = "CLEAR"

function GetMostVotedWeather()
    local maxVotes = 0
    local mostVotedWeather = ""
    for weatherType, votes in pairs(weatherVotes) do
        if votes > maxVotes then
            maxVotes = votes
            mostVotedWeather = weatherType
        end
    end
    return mostVotedWeather
end

AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
    if first_spawn then
        TriggerClientEvent("nexa:setWeather",source,currentWeather)
    end
end)


RegisterServerEvent("nexa:vote") 
AddEventHandler("nexa:vote", function(weatherType)
    weatherVotes[weatherType] = (weatherVotes[weatherType] or 0) + 1
    TriggerClientEvent("nexa:voteStateChange",-1,weatherType)
end)

RegisterServerEvent("nexa:tryStartWeatherVote") 
AddEventHandler("nexa:tryStartWeatherVote", function()
    if weatherVoterCooldown >= voteCooldown then
        TriggerClientEvent("nexa:startWeatherVote", -1)
        weatherVoterCooldown = 0
        Wait(60000)
        TriggerEvent("nexa:setCurrentWeather")
    else
        TriggerClientEvent("chatMessage", source, "Another vote can be started in " .. tostring(voteCooldown-weatherVoterCooldown) .. " seconds!", {255, 0, 0})
    end
end)

RegisterServerEvent("nexa:setCurrentWeather")
AddEventHandler("nexa:setCurrentWeather", function()
    local mostVotedWeather = GetMostVotedWeather()
    currentWeather = mostVotedWeather
    TriggerClientEvent("nexa:setWeather",-1,mostVotedWeather)
    weatherVotes = {}
end)

Citizen.CreateThread(function()
	while true do
		weatherVoterCooldown = weatherVoterCooldown + 1
		Citizen.Wait(1000)
	end
end)