local lang = nexa.lang
local a = module("nexa-weapons", "cfg/weapons")


isStoring = {}
RegisterCommand('storeallweapons', function(player)
  local user_id = nexa.getUserId(player)
  local data = nexa.getUserDataTable(user_id)
  nexaclient.getWeapons(player,{},function(weapons)
    if not isStoring[player] then
      local new_weight = nexa.getInventoryWeight(user_id)
      for k,v in pairs(weapons) do
        new_weight = new_weight + v.ammo * 0.01
        new_weight = new_weight + nexa.getItemWeight("wbody|"..k)
      end
      if new_weight > nexa.getInventoryMaxWeight(user_id) and GetEntityHealth(GetPlayerPed(player)) > 102 then nexaclient.notify(player,{'~r~You do not have enough space to store all weapons.'}) return end
      isStoring[player] = true
      nexaclient.getAllowedWeapons(player,{},function(allowed)
        for k,v in pairs(weapons) do
          nexaclient.giveWeapons(player,{{},true}, function(removedwep)
            if allowed[k] then
              if k ~= 'GADGET_PARACHUTE' and k ~= 'WEAPON_STAFFGUN' and k~= 'WEAPON_SMOKEGRENADE' and k~= 'WEAPON_FLASHBANG' then
                nexa.giveInventoryItem(user_id, "wbody|"..k, 1, true)
                if v.ammo > 0 then
                  for i,c in pairs(a.weapons) do
                    if i == k and c.class ~= 'Melee' and c.ammo ~= "modelammo" then
                      if v.ammo > 250 then
                        v.ammo = 250
                      end
                      nexa.giveInventoryItem(user_id, c.ammo, v.ammo, true)
                    end   
                  end
                end
                nexaclient.removeWeapon(player,{k})
              end
            end
          end)
        end
        nexaclient.notify(player,{"~g~Weapons Stored"})
        TriggerEvent('nexa:RefreshInventory', player)
        data.weapons = {}
        SetTimeout(1000,function()
          isStoring[player] = nil 
        end)
      end)
    end 
  end)
end)

RegisterServerEvent("nexa:forceStoreSingleWeapon")
AddEventHandler("nexa:forceStoreSingleWeapon",function(model)
    local source = source
    local user_id = nexa.getUserId(source)
    if model ~= nil then
      nexaclient.getWeapons(source,{},function(weapons)
        for k,v in pairs(weapons) do
          if k == model then
            local new_weight = nexa.getInventoryWeight(user_id)+nexa.getItemWeight("wbody|"..model)+v.ammo*0.01
            if new_weight <= nexa.getInventoryMaxWeight(user_id) then
              RemoveWeaponFromPed(GetPlayerPed(source), k)
              nexaclient.getAllowedWeapons(source, {}, function(allowed)
                if allowed[k] then
                  nexa.giveInventoryItem(user_id, "wbody|"..k, 1, true)
                  nexaclient.removeWeapon(source,{k})
                  if v.ammo > 0 then
                    if a.weapons[model] ~= nil then
                      if a.weapons[model].class ~= 'Melee' and a.weapons[model].ammo ~= "modelammo" then
                        if v.ammo > 250 then v.ammo = 250 end
                        nexa.giveInventoryItem(user_id, a.weapons[model].ammo, v.ammo, true)
                        nexaclient.setWeaponAmmo(source,{k,0})
                      end
                    end
                  end
                end
              end)
            else
              nexaclient.notify(source,{"~r~You do not have enough space to store this weapon."})
            end
          end
        end
      end)
    end
end)