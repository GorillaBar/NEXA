RegisterServerEvent('nexa:setCarDevMode')
AddEventHandler('nexa:setCarDevMode', function(status)
    local source = source
    local user_id = nexa.getUserId(source)
    if user_id ~= nil and nexa.hasPermission(user_id, "cardev.menu") then 
      if status then
        tnexa.setBucket(source, 333)
      else
        tnexa.setBucket(source, 0)
      end
    else
      TriggerEvent("nexa:acBan", user_id, 11, tnexa.getDiscordName(source), source, 'Attempted to Teleport to Car Dev Universe')
    end
end)