local lang = nexa.lang

-- Money module, wallet/bank API
-- The money is managed with direct SQL requests to prevent most potential value corruptions
-- the wallet empty itself when respawning (after death)

MySQL.createCommand("nexa/money_init_user","INSERT IGNORE INTO nexa_user_moneys(user_id,wallet,bank) VALUES(@user_id,@wallet,@bank)")
MySQL.createCommand("nexa/get_money","SELECT wallet,bank FROM nexa_user_moneys WHERE user_id = @user_id")
MySQL.createCommand("nexa/set_money","UPDATE nexa_user_moneys SET wallet = @wallet, bank = @bank WHERE user_id = @user_id")
MySQL.createCommand("nexa/set_wallet","UPDATE nexa_user_moneys SET wallet = @wallet WHERE user_id = @user_id")

-- get money
-- cbreturn nil if error
function nexa.getMoney(user_id)
  local tmp = nexa.getUserTmpTable(user_id)
  if tmp then
    return tmp.wallet or 0
  else
    return 0
  end
end

-- set money
function nexa.setMoney(user_id,value)
  local tmp = nexa.getUserTmpTable(user_id)
  if tmp then
    tmp.wallet = value
  end

  -- update client display
  local source = nexa.getUserSource(user_id)
  if source ~= nil then
    nexaclient.setDivContent(source,{"money",lang.money.display({Comma(nexa.getMoney(user_id))})})
    TriggerClientEvent('nexa:initMoney', source, nexa.getMoney(user_id), nexa.getBankMoney(user_id))
  end
end

-- try a payment
-- return true or false (debited if true)
function nexa.tryPayment(user_id,amount)
  local money = nexa.getMoney(user_id)
  if amount >= 0 and money >= amount then
    nexa.setMoney(user_id,money-amount)
    return true
  else
    return false
  end
end

function nexa.tryBankPayment(user_id,amount)
  local bank = nexa.getBankMoney(user_id)
  if amount >= 0 and bank >= amount then
    nexa.setBankMoney(user_id,bank-amount)
    return true
  else
    return false
  end
end

-- give money
function nexa.giveMoney(user_id,amount)
  local money = nexa.getMoney(user_id)
  nexa.setMoney(user_id,money+amount)
end

-- get bank money
function nexa.getBankMoney(user_id)
  local tmp = nexa.getUserTmpTable(user_id)
  if tmp then
    return tmp.bank or 0
  else
    return 0
  end
end

-- set bank money
function nexa.setBankMoney(user_id,value)
  local tmp = nexa.getUserTmpTable(user_id)
  if tmp then
    tmp.bank = value
  end
  local source = nexa.getUserSource(user_id)
  if source ~= nil then
    nexaclient.setDivContent(source,{"bmoney",lang.money.bdisplay({Comma(nexa.getBankMoney(user_id))})})
    TriggerClientEvent('nexa:initMoney', source, nexa.getMoney(user_id), nexa.getBankMoney(user_id))
    TriggerClientEvent('nexa:setDisplayBankMoney', source, nexa.getBankMoney(user_id))
  end
end

-- give bank money
function nexa.giveBankMoney(user_id,amount)
  if amount > 0 then
    local money = nexa.getBankMoney(user_id)
    nexa.setBankMoney(user_id,money+amount)
  end
end

-- try a withdraw
-- return true or false (withdrawn if true)
function nexa.tryWithdraw(user_id,amount)
  local money = nexa.getBankMoney(user_id)
  if amount > 0 and money >= amount then
    nexa.setBankMoney(user_id,money-amount)
    nexa.giveMoney(user_id,amount)
    return true
  else
    return false
  end
end

-- try a deposit
-- return true or false (deposited if true)
function nexa.tryDeposit(user_id,amount)
  if amount > 0 and nexa.tryPayment(user_id,amount) then
    nexa.giveBankMoney(user_id,amount)
    return true
  else
    return false
  end
end

-- try full payment (wallet + bank to complete payment)
-- return true or false (debited if true)
function nexa.tryFullPayment(user_id,amount)
  local money = nexa.getMoney(user_id)
  if money >= amount then -- enough, simple payment
    return nexa.tryPayment(user_id, amount)
  else  -- not enough, withdraw -> payment
    if nexa.tryWithdraw(user_id, amount-money) then -- withdraw to complete amount
      return nexa.tryPayment(user_id, amount)
    end
  end

  return false
end

local startingCash = 0
local startingBank = 15000

-- events, init user account if doesn't exist at connection
AddEventHandler("nexa:playerJoin",function(user_id,source,name,last_login)
  MySQL.query("nexa/money_init_user", {user_id = user_id, wallet = startingCash, bank = startingBank}, function(affected)
    local tmp = nexa.getUserTmpTable(user_id)
    if tmp then
      MySQL.query("nexa/get_money", {user_id = user_id}, function(rows, affected)
        if #rows > 0 then
          tmp.bank = rows[1].bank
          tmp.wallet = rows[1].wallet
        end
      end)
    end
  end)
end)

-- save money on leave
AddEventHandler("nexa:playerLeave",function(user_id,source)
  -- (wallet,bank)
  local tmp = nexa.getUserTmpTable(user_id)
  if tmp and tmp.wallet ~= nil and tmp.bank ~= nil then
    MySQL.execute("nexa/set_money", {user_id = user_id, wallet = tmp.wallet, bank = tmp.bank})
  end
end)

-- save money (at same time that save datatables)
AddEventHandler("nexa:save", function()
  for k,v in pairs(nexa.user_tmp_tables) do
    if v.wallet ~= nil and v.bank ~= nil then
      MySQL.execute("nexa/set_money", {user_id = k, wallet = v.wallet, bank = v.bank})
    end
  end
end)

RegisterNetEvent('nexa:giveCashToPlayer')
AddEventHandler('nexa:giveCashToPlayer', function(nplayer)
  local source = source
  local user_id = nexa.getUserId(source)
  if user_id ~= nil then
    if nplayer ~= nil then
      local nuser_id = nexa.getUserId(nplayer)
      if nuser_id ~= nil then
        nexa.prompt(source,lang.money.give.prompt(),"",function(source,amount)
          local amount = parseInt(amount)
          if amount > 0 and nexa.tryPayment(user_id,amount) then
            nexa.giveMoney(nuser_id,amount)
            nexaclient.notify(source,{lang.money.given({getMoneyStringFormatted(math.floor(amount))})})
            nexaclient.notify(nplayer,{lang.money.received({getMoneyStringFormatted(math.floor(amount))})})
            tnexa.sendWebhook('give-cash', "nexa Give Cash Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Target Name: **"..tnexa.getDiscordName(nplayer).."**\n> Target PermID: **"..nuser_id.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**")
          else
            nexaclient.notify(source,{lang.money.not_enough()})
          end
        end)
      else
        nexaclient.notify(source,{lang.common.no_player_near()})
      end
    else
      nexaclient.notify(source,{lang.common.no_player_near()})
    end
  end
end)


function Comma(amount)
  local formatted = amount
  while true do  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    if (k==0) then
      break
    end
  end
  return formatted
end

RegisterServerEvent("nexa:takeAmount")
AddEventHandler("nexa:takeAmount", function(amount)
  local source = source
  local user_id = nexa.getUserId(source)
  if nexa.tryFullPayment(user_id,amount) then
    nexaclient.notify(source,{'~g~Paid £'..getMoneyStringFormatted(amount)..'.'})
    return
  end
end)

RegisterServerEvent("nexa:bankTransfer")
AddEventHandler("nexa:bankTransfer", function(id, amount)
  local source = source
  local user_id = nexa.getUserId(source)
  local id = tonumber(id)
  local amount = tonumber(amount)
  if nexa.getUserSource(id) then
    if nexa.tryBankPayment(user_id,amount) then
      nexaclient.notify(nexa.getUserSource(id),{'~g~Received £'..getMoneyStringFormatted(amount)..' from ID: '..user_id})
      nexaclient.notify(source,{'~g~Transferred £'..getMoneyStringFormatted(amount)..' to ID: '..id})
      TriggerClientEvent("nexa:PlaySound", source, "apple")
      TriggerClientEvent("nexa:PlaySound", nexa.getUserSource(id), "apple")
      nexa.giveBankMoney(id, amount)
      tnexa.sendWebhook('bank-transfer', "nexa Bank Transfer Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Target PermID: **"..id.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**")
    else
      nexaclient.notify(source,{'~r~You do not have enough money.'})
    end
  else
    nexa.prompt(source, "Please replace text with YES or NO to confirm", "Player is offline, please confirm you would like transfer £"..getMoneyStringFormatted(amount).." to ID: "..id,function(source,confirm)
      if string.upper(confirm) == 'YES' then
        if nexa.tryBankPayment(user_id,amount) then
          nexaclient.notify(source,{'~g~Transferred £'..getMoneyStringFormatted(amount)..' to ID: '..id})
          TriggerClientEvent("nexa:PlaySound", source, "apple")
          exports["ghmattimysql"]:executeSync("UPDATE nexa_user_moneys SET bank = (bank+@amount) WHERE user_id = @user_id", {user_id = id, amount = amount})
          tnexa.sendWebhook('bank-transfer', "nexa Bank Transfer Logs", "> Player Name: **"..tnexa.getDiscordName(source).."**\n> Player PermID: **"..user_id.."**\n> Target PermID: **"..id.."**\n> Amount: **£"..getMoneyStringFormatted(amount).."**")
        else
          nexaclient.notify(source,{'~r~You do not have enough money.'})
        end
      end
    end)    
  end
end)

local cfg = module("cfg/discordroles")
RegisterServerEvent('nexa:requestPlayerBankBalance')
AddEventHandler('nexa:requestPlayerBankBalance', function()
  local source = source
  local user_id = nexa.getUserId(source)
  local bank = nexa.getBankMoney(user_id)
  local wallet = nexa.getMoney(user_id)
  local profilePictures = {
    ["Steam"] = "None",
    ["Discord"] = "None",
    ["None"] = "None",
  }
  TriggerClientEvent('nexa:setDisplayMoney', source, wallet)
  TriggerClientEvent('nexa:setDisplayBankMoney', source, bank)
  TriggerClientEvent('nexa:initMoney', source, wallet, bank)
  PerformHttpRequest('http://steamcommunity.com/profiles/' .. tostring(tonumber(GetPlayerIdentifiers(source)[1]:sub(7), 16)) .. '/?xml=1', function(Error, Content, Head)
    local SteamProfileSplitted = stringsplit(Content, '\n')
    if SteamProfileSplitted ~= nil and next(SteamProfileSplitted) ~= nil then
      for i, Line in ipairs(SteamProfileSplitted) do
        if Line:find('<avatarFull>') then
          steamPictureURL = Line:gsub('	<avatarFull><!%[CDATA%[', ''):gsub(']]></avatarFull>', '')
          if steamPictureURL == nil or steamPictureURL == "" then
          else
            profilePictures["Steam"] = steamPictureURL
            break
          end
        end
      end
    end
    PerformHttpRequest("https://discord.com/api/v9/users/" .. nexa.getDiscordIdFromSource(source), function(errorCode, resultData, resultHeaders)
      local userData = json.decode(resultData)
      if userData and userData.avatar then
        local avatarUrl = string.format('https://cdn.discordapp.com/avatars/%s/%s.%s', userData.id, userData.avatar, userData.avatar:sub(1, 2) == "a_" and "gif" or "png")
        profilePictures.Discord = avatarUrl
      end
      TriggerClientEvent('nexa:setProfilePictures', source, profilePictures)
    end, 'GET', '', { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bot ' .. cfg.Bot_Token })
  end)
end)