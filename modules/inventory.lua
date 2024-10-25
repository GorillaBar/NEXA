local lang = nexa.lang
local cfg = module("nexa-vehicles", "inventory")

-- this module define the player inventory (lost after respawn, as wallet)

nexa.items = {}

function nexa.defInventoryItem(idname,name,description,choices,weight)
  if weight == nil then
    weight = 0
  end

  local item = {name=name,description=description,choices=choices,weight=weight}
  nexa.items[idname] = item

  -- build give action
  item.ch_give = function(player,choice)
  end

  -- build trash action
  item.ch_trash = function(player,choice)
    local user_id = nexa.getUserId(player)
    if user_id ~= nil then
      -- prompt number
      nexa.prompt(player,lang.inventory.trash.prompt({nexa.getInventoryItemAmount(user_id,idname)}),"",function(player,amount)
        local amount = parseInt(amount)
        if nexa.tryGetInventoryItem(user_id,idname,amount,false) then
          nexaclient.notify(player,{lang.inventory.trash.done({nexa.getItemName(idname),amount})})
          nexaclient.playAnim(player,{true,{{"pickup_object","pickup_low",1}},false})
        else
          nexaclient.notify(player,{lang.common.invalid_value()})
        end
      end)
    end
  end
end

function giveItem(user_id,nuser_id,player,nplayer,idname)
  nexa.prompt(player,lang.inventory.give.prompt({nexa.getInventoryItemAmount(user_id,idname)}),"",function(player,amount)
    if string.lower(amount) == "all" then
      amount = nexa.getInventoryItemAmount(user_id,idname)
    else
      amount = parseInt(amount)
    end
    -- weight check
    local new_weight = nexa.getInventoryWeight(nuser_id)+nexa.getItemWeight(idname)*amount
    if new_weight <= nexa.getInventoryMaxWeight(nuser_id) then
      if nexa.tryGetInventoryItem(user_id,idname,amount,true) then
        nexa.giveInventoryItem(nuser_id,idname,amount,true)
        TriggerEvent('nexa:RefreshInventory', player)
        TriggerEvent('nexa:RefreshInventory', nplayer)
        nexaclient.playAnim(player,{true,{{"mp_common","givetake1_a",1}},false})
        nexaclient.playAnim(nplayer,{true,{{"mp_common","givetake2_a",1}},false})
      else
        nexaclient.notify(player,{lang.common.invalid_value()})
      end
    else
      nexaclient.notify(player,{'~r~Player does not have enough space!'})
    end
  end)
end

-- give action
function ch_give(idname, player, choice)
  local user_id = nexa.getUserId(player)
  if user_id ~= nil then
    nexaclient.getNearestPlayers(player,{10},function(nplayers) --get nearest players
      usrList = ""
      for k, v in pairs(nplayers) do
        usrList = usrList .. "[" .. k .. "]" .. tnexa.getDiscordName(k) .. " | " --add ids to usrList
      end
      if usrList ~= "" then
        if table.count(nplayers) > 1 then
          nexa.prompt(player,"Players Nearby: " .. usrList .. "","",function(player, nplayer) --ask for id
            nplayer = nplayer
            if nplayer ~= nil and nplayer ~= "" then
              if nplayers[tonumber(nplayer)] then
                local nuser_id = nexa.getUserId(nplayer)
                if nuser_id ~= nil then
                  giveItem(user_id,nuser_id,player,nplayer,idname)
                else
                  nexaclient.notify(player,{'~r~Invalid Temp ID.'})
                end
              else
                nexaclient.notify(player,{'~r~Invalid Temp ID.'})
              end
            else
              nexaclient.notify(player,{lang.common.no_player_near()})
            end
          end)
        else
          nexaclient.getNearestPlayer(player,{5},function(nplayer)
            local nuser_id = nexa.getUserId(nplayer)
            if nuser_id ~= nil then
              giveItem(user_id,nuser_id,player,nplayer,idname)
            end
          end)
        end
      else
        nexaclient.notify(player,{"~r~No players nearby!"}) --no players nearby
      end
    end)
  end
end

-- trash action
function ch_trash(idname, player, choice)
  local user_id = nexa.getUserId(player)
  if user_id ~= nil then
    -- prompt number
    if nexa.getInventoryItemAmount(user_id,idname) > 1 then 
      nexa.prompt(player,lang.inventory.trash.prompt({nexa.getInventoryItemAmount(user_id,idname)}),"",function(player,amount)
        if string.lower(amount) == "all" then
          amount = nexa.getInventoryItemAmount(user_id,idname)
        else
          amount = parseInt(amount)
        end
        if nexa.tryGetInventoryItem(user_id,idname,amount,false) then
          TriggerEvent('nexa:RefreshInventory', player)
          nexaclient.notify(player,{lang.inventory.trash.done({nexa.getItemName(idname),amount})})
          nexaclient.playAnim(player,{true,{{"pickup_object","pickup_low",1}},false})
        else
          nexaclient.notify(player,{lang.common.invalid_value()})
        end
      end)
    else
      if nexa.tryGetInventoryItem(user_id,idname,1,false) then
        TriggerEvent('nexa:RefreshInventory', player)
        nexaclient.notify(player,{lang.inventory.trash.done({nexa.getItemName(idname),1})})
        nexaclient.playAnim(player,{true,{{"pickup_object","pickup_low",1}},false})
      else
        nexaclient.notify(player,{lang.common.invalid_value()})
      end
    end
  end
end

function nexa.computeItemName(item,args)
  if type(item.name) == "string" then return item.name
  else return item.name(args) end
end

function nexa.computeItemDescription(item,args)
  if type(item.description) == "string" then return item.description
  else return item.description(args) end
end

function nexa.computeItemChoices(item,args)
  if item.choices ~= nil then
    return item.choices(args)
  else
    return {}
  end
end

function nexa.computeItemWeight(item,args)
  if type(item.weight) == "number" then return item.weight
  else return item.weight(args) end
end


function nexa.parseItem(idname)
  return splitString(idname,"|")
end

-- return name, description, weight
function nexa.getItemDefinition(idname)
  local args = nexa.parseItem(idname)
  local item = nexa.items[args[1]]
  if item ~= nil then
    return nexa.computeItemName(item,args), nexa.computeItemDescription(item,args), nexa.computeItemWeight(item,args)
  end

  return nil,nil,nil
end

function nexa.getItemName(idname)
  local args = nexa.parseItem(idname)
  local item = nexa.items[args[1]]
  if item ~= nil then return nexa.computeItemName(item,args) end
  return args[1]
end

function nexa.getItemDescription(idname)
  local args = nexa.parseItem(idname)
  local item = nexa.items[args[1]]
  if item ~= nil then return nexa.computeItemDescription(item,args) end
  return ""
end

function nexa.getItemChoices(idname)
  local args = nexa.parseItem(idname)
  local item = nexa.items[args[1]]
  local choices = {}
  if item ~= nil then
    -- compute choices
    local cchoices = nexa.computeItemChoices(item,args)
    if cchoices then -- copy computed choices
      for k,v in pairs(cchoices) do
        choices[k] = v
      end
    end

    -- add give/trash choices
    choices[lang.inventory.give.title()] = {function(player,choice) ch_give(idname, player, choice) end, lang.inventory.give.description()}
    choices[lang.inventory.trash.title()] = {function(player, choice) ch_trash(idname, player, choice) end, lang.inventory.trash.description()}
  end

  return choices
end

function nexa.getItemWeight(idname)
  local args = nexa.parseItem(idname)
  local item = nexa.items[args[1]]
  if item ~= nil then return nexa.computeItemWeight(item,args) end
  return 1
end

-- compute weight of a list of items (in inventory/chest format)
function nexa.computeItemsWeight(items)
  local weight = 0

  for k,v in pairs(items) do
    local iweight = nexa.getItemWeight(k)
    if iweight ~= nil then
      weight = weight+iweight*v.amount
    end
  end

  return weight
end

-- add item to a connected user inventory
function nexa.giveInventoryItem(user_id,idname,amount,notify)
  local player = nexa.getUserSource(user_id)
  if notify == nil then notify = true end -- notify by default

  local data = nexa.getUserDataTable(user_id)
  if data and amount > 0 then
    local entry = data.inventory[idname]
    if entry then -- add to entry
      entry.amount = entry.amount+amount
    else -- new entry
      data.inventory[idname] = {amount=amount}
    end

    -- notify
    if notify then
      local player = nexa.getUserSource(user_id)
      if player ~= nil then
        nexaclient.notify(player,{lang.inventory.give.received({nexa.getItemName(idname),amount})})
      end
    end
  end
  TriggerEvent('nexa:RefreshInventory', player)
end


function nexa.RunTrashTask(source, itemName)
    local choices = nexa.getItemChoices(itemName)
    if choices['Trash'] then
        choices['Trash'][1](source)
    else 
        local user_id = nexa.getUserId(source)
        local data = nexa.getUserDataTable(user_id)
        data.inventory[itemName] = nil;
    end
    TriggerEvent('nexa:RefreshInventory', source)
end


function nexa.RunGiveTask(source, itemName)
    local choices = nexa.getItemChoices(itemName)
    if choices['Give'] then
        choices['Give'][1](source)
    end
    TriggerEvent('nexa:RefreshInventory', source)
end

function nexa.RunInventoryTask(source, itemName)
    local choices = nexa.getItemChoices(itemName)
    if choices['Use'] then 
        choices['Use'][1](source)
    elseif choices['Load'] then
        choices['Load'][1](source)
    elseif choices['Equip'] then 
        choices['Equip'][1](source)
    elseif choices['Take'] then 
        choices['Take'][1](source)
    end
    TriggerEvent('nexa:RefreshInventory', source)
end

function nexa.LoadAllTask(source, itemName)
  local choices = nexa.getItemChoices(itemName)
  choices['LoadAll'][1](source)
  TriggerEvent('nexa:RefreshInventory', source)
end

-- try to get item from a connected user inventory
function nexa.tryGetInventoryItem(user_id,idname,amount,notify)
  if notify == nil then notify = true end -- notify by default
  local player = nexa.getUserSource(user_id)

  local data = nexa.getUserDataTable(user_id)
  if data and amount > 0 then
    local entry = data.inventory[idname]
    if entry and entry.amount >= amount then -- add to entry
      entry.amount = entry.amount-amount

      -- remove entry if <= 0
      if entry.amount <= 0 then
        data.inventory[idname] = nil 
      end

      -- notify
      if notify then
        local player = nexa.getUserSource(user_id)
        if player ~= nil then
          nexaclient.notify(player,{lang.inventory.give.given({nexa.getItemName(idname),amount})})
      
        end
      end
      TriggerEvent('nexa:RefreshInventory', player)
      return true
    else
      -- notify
      if notify then
        local player = nexa.getUserSource(user_id)
        if player ~= nil then
          local entry_amount = 0
          if entry then entry_amount = entry.amount end
          nexaclient.notify(player,{lang.inventory.missing({nexa.getItemName(idname),amount-entry_amount})})
        end
      end
    end
  end

  return false
end

-- get user inventory amount of item
function nexa.getInventoryItemAmount(user_id,idname)
  local data = nexa.getUserDataTable(user_id)
  if data and data.inventory then
    local entry = data.inventory[idname]
    if entry then
      return entry.amount
    end
  end

  return 0
end

-- return user inventory total weight
function nexa.getInventoryWeight(user_id)
  local data = nexa.getUserDataTable(user_id)
  if data and data.inventory then
    return nexa.computeItemsWeight(data.inventory)
  end
  return 0
end

function nexa.getInventoryMaxWeight(user_id)
  local data = nexa.getUserDataTable(user_id)
  if data.invcap ~= nil then
    return data.invcap
  end
  return 30
end


-- clear connected user inventory
function nexa.clearInventory(user_id)
  local data = nexa.getUserDataTable(user_id)
  if data then
    data.inventory = {}
  end
end

function nexa.clearWeapons(user_id)
  local data = nexa.getUserDataTable(user_id)
  if data then
    data.weapons = {}
  end
end


AddEventHandler("nexa:playerJoin", function(user_id,source,name,last_login)
  local data = nexa.getUserDataTable(user_id)
  if data.inventory == nil then
    data.inventory = {}
  end
end)


RegisterCommand("storebackpack", function(source, args)
  local source = source
  local user_id = nexa.getUserId(source)
  local data = nexa.getUserDataTable(user_id)
  tnexa.getSubscriptions(user_id, function(cb, plushours, plathours)
    if cb then
      local invcap = 30
      if plathours > 0 then
        invcap = invcap + 20
      elseif plushours > 0 then
        invcap = invcap + 10
      end
      if invcap == 30 then
        nexaclient.notify(source,{"~r~You do not have a backpack equipped."})
        return
      end
      if data.invcap - 15 == invcap then
        nexa.giveInventoryItem(user_id, "offwhitebag", 1, false)
      elseif data.invcap - 20 == invcap then
        nexa.giveInventoryItem(user_id, "guccibag", 1, false)
      elseif data.invcap - 30 == invcap  then
        nexa.giveInventoryItem(user_id, "nikebag", 1, false)
      elseif data.invcap - 35 == invcap  then
        nexa.giveInventoryItem(user_id, "huntingbackpack", 1, false)
      elseif data.invcap - 40 == invcap  then
        nexa.giveInventoryItem(user_id, "greenhikingbackpack", 1, false)
      elseif data.invcap - 70 == invcap  then
        nexa.giveInventoryItem(user_id, "rebelbackpack", 1, false)
      end
      nexa.updateInvCap(user_id, invcap)
      nexaclient.notify(source,{"~g~Backpack Stored"})
      TriggerClientEvent('nexa:removeBackpack', source)
    else
      if nexa.getInventoryWeight(user_id) + 5 > nexa.getInventoryMaxWeight(user_id) then
        nexaclient.notify(source,{"~r~You do not have enough room to store your backpack"})
      end
    end
  end)
end)