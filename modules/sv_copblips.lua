local u = {
  ["White"] = {hud = 0, blip = 0},
  ["Red"] = {hud = 6, blip = 1},
  ["Green"] = {hud = 18, blip = 2},
  ["Blue"] = {hud = 9, blip = 3},
  ["Yellow"] = {hud = 12, blip = 5},
  ["Violet"] = {hud = 21, blip = 7},
  ["Pink"] = {hud = 24, blip = 8},
  ["Orange"] = {hud = 15, blip = 17},
  ["Cyan"] = {hud = 52, blip = 30},
  ["Black"] = {hud = 2, blip = 40},
  ["Baby Pink"] = {hud = 193, blip = 34},
}

Citizen.CreateThread(function()
  while true do
      for k,v in pairs(nexa.getUsers()) do
        if nexa.hasGroup(k, 'polblips') then
          nexaclient.hasGangBlipsEnabled(v, {}, function(gangBlipsEnabled)
            if gangBlipsEnabled then
              local gangblips = {}
              MySQL.query("nexa/get_gang", {user_id = k}, function(rows, affected)
                if #rows > 0 then
                  local gangName = rows[1].gangname
                  local gotGangs = exports['ghmattimysql']:executeSync("SELECT * FROM nexa_gangs WHERE gangname = @gangname", {gangname = gangName})
                  for K,V in pairs(gotGangs) do
                      local array = json.decode(V.gangmembers)
                      if array[tostring(k)] then
                        for k,v in pairs(array) do
                          local k = tonumber(k)
                          local player = nexa.getUserSource(k)
                          if player ~= nil then
                            local dead = 0
                            local health = GetEntityHealth(GetPlayerPed(player))
                            local colour = nil
                            if v.colour ~= nil then colour = u[v.colour].blip else colour = 1 end
                            if health > 102 then dead = 0 else dead = 1 end
                            table.insert(gangblips, {source = player, position = GetEntityCoords(GetPlayerPed(player)), dead = dead, colour = colour, bucket = GetPlayerRoutingBucket(player)})
                          end
                        end
                      end
                  end
                  TriggerClientEvent('nexa:sendFarBlips', v, gangblips)
                end
              end)
            end
          end)
        end
      end
      Citizen.Wait(10000)
  end
end)
