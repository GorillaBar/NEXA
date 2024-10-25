function nexa.updateCurrentPlayerInfo()
  local currentPlayersInformation = {}
  local playersJobs = {}
  currentPlayersInformation['currentStaff'] = nexa.getUsersByPermission('admin.tickets')
  TriggerClientEvent("nexa:receiveCurrentPlayerInfo", -1, currentPlayersInformation)
end


AddEventHandler("nexa:playerSpawn", function(user_id, source, first_spawn)
  if first_spawn then
    nexa.updateCurrentPlayerInfo()
  end
end)