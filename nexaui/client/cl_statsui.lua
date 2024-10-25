local statsOpen = false
local statsLoaded = false
local statsLoading = false
local bIsNewPlayer = false

RegisterNetEvent("nexaDEATHUI:setStatistics", function(stats, statsTotal, userId)
    SendNUIMessage({
        type="SET_STATS",
        info = {
            stats = stats,
            statsTotal=statsTotal,
            userId = userId
        }
    })
    statsLoaded = true
    statsLoading = false
end)

local function toggleStats()
    SendNUIMessage({
        app = statsOpen and "" or "stats",
        type = "APP_TOGGLE",
    })
    if not statsOpen then
        statsOpen = true
    else
        statsOpen = false
    end
    SetNuiFocus(statsOpen, statsOpen)
    SetNuiFocusKeepInput(statsOpen)
end

local function drawSubtitle(message)
	BeginTextCommandPrint("STRING")
	AddTextComponentSubstringPlayerName(message)
	EndTextCommandPrint(1000, true)
end

RegisterCommand("openstats", function()
    if statsLoading or GetEntityHealth(PlayerPedId()) <= 102 then
        return
    end
    if not statsLoaded then
        statsLoading = true
        TriggerServerEvent("nexa:requestStatistics")
        while not statsLoaded do
            drawSubtitle("~b~Downloading statistics...")
            Citizen.Wait(0)
        end
    end
    toggleStats()
end, false)

RegisterNUICallback("closeStatsMenu", function(_, cb)
    toggleStats()
    cb({})
end)

RegisterKeyMapping("openstats", "Open the stats menu", "keyboard", "F9")

local function drawNativeNotification(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, 0, 1, -1)
end

Citizen.CreateThread(function()
    while true do
        if statsOpen then
            DisableAllControlActions(0)
            EnableControlAction(0, 249, true) -- INPUT_PUSH_TO_TALK
            if IsDisabledControlPressed(0, 177) then
                toggleStats()
            end
            if bIsNewPlayer then
                drawNativeNotification("Press ~INPUT_DF5476D8~ to toggle the Statistics Menu.")
            end
        end
        Citizen.Wait(0)
    end
end)

RegisterNetEvent("nexa:setIsNewPlayer", function()
	bIsNewPlayer = true
end)