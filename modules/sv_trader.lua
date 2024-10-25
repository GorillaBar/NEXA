grindBoost = 1.0

local function generatePrices(grindBoost)
    local prices = {
        ["Weed"] = math.floor(1500*grindBoost),
        ["Cocaine"] = math.floor(2500*grindBoost),
        ["Meth"] = math.floor(3000*grindBoost),
        ["Heroin"] = math.floor(10000*grindBoost),
        ["LSDNorth"] = math.floor(18000*grindBoost),
        ["LSDSouth"] = math.floor(18000*grindBoost),
        ["Copper"] = math.floor(1000*grindBoost),
        ["Limestone"] = math.floor(2000*grindBoost),
        ["Gold"] = math.floor(4000*grindBoost),
        ["Diamond"] = math.floor(7000*grindBoost),
    }
    return prices
end

local defaultPrices = generatePrices(grindBoost)

function nexa.getCommissionPrice(drugtype)
    for k,v in pairs(turfData) do
        if v.name == drugtype then
            if v.commission == nil then
                v.commission = 0
            end
            if v.commission == 0 then
                return defaultPrices[drugtype]
            else
                return defaultPrices[drugtype]-defaultPrices[drugtype]*v.commission/100
            end
        end
    end
end

function nexa.getCommission(drugtype)
    for k,v in pairs(turfData) do
        if v.name == drugtype then
            return v.commission
        end
    end
end

function nexa.updateTraderInfo()
    TriggerClientEvent('nexa:updateTraderCommissions', -1, 
    nexa.getCommission('Weed'),
    nexa.getCommission('Cocaine'),
    nexa.getCommission('Meth'),
    nexa.getCommission('Heroin'),
    nexa.getCommission('LargeArms'),
    nexa.getCommission('LSDNorth'),
    nexa.getCommission('LSDSouth'))
    TriggerClientEvent('nexa:updateTraderPrices', -1, 
    nexa.getCommissionPrice('Weed'), 
    nexa.getCommissionPrice('Cocaine'),
    nexa.getCommissionPrice('Meth'),
    nexa.getCommissionPrice('Heroin'),
    nexa.getCommissionPrice('LSDNorth'),
    nexa.getCommissionPrice('LSDSouth'),
    defaultPrices['Copper'],
    defaultPrices['Limestone'],
    defaultPrices['Gold'],
    defaultPrices['Diamond'])
end

RegisterNetEvent('nexa:requestDrugPriceUpdate')
AddEventHandler('nexa:requestDrugPriceUpdate', function()
    local source = source
	local user_id = nexa.getUserId(source)
    nexa.updateTraderInfo()
end)

RegisterNetEvent('nexa:sellCopper')
AddEventHandler('nexa:sellCopper', function()
    local source = source
	local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Copper') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Copper', 1, false)
        nexa.notify(source, {'~g~Sold Copper for £'..getMoneyStringFormatted(defaultPrices['Copper'])})
        nexa.giveBankMoney(user_id, defaultPrices['Copper'])
        nexa.addStat(user_id, "copper_sales", defaultPrices['Copper'])
    else
        nexa.notify(source, {'~r~You do not have Copper.'})
    end
end)

RegisterNetEvent('nexa:sellLimestone')
AddEventHandler('nexa:sellLimestone', function()
    local source = source
	local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Limestone') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Limestone', 1, false)
        nexa.notify(source, {'~g~Sold Limestone for £'..getMoneyStringFormatted(defaultPrices['Limestone'])})
        nexa.giveBankMoney(user_id, defaultPrices['Limestone'])
        nexa.addStat(user_id, "limestone_sales", defaultPrices['Limestone'])
    else
        nexa.notify(source, {'~r~You do not have Limestone.'})
    end
end)

RegisterNetEvent('nexa:sellGold')
AddEventHandler('nexa:sellGold', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Gold') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Gold', 1, false)
        nexa.notify(source, {'~g~Sold Gold for £'..getMoneyStringFormatted(defaultPrices['Gold'])})
        nexa.giveBankMoney(user_id, defaultPrices['Gold'])
        nexa.addStat(user_id, "gold_sales", defaultPrices['Gold'])
    else
        nexa.notify(source, {'~r~You do not have Gold.'})
    end
end)

RegisterNetEvent('nexa:sellDiamond')
AddEventHandler('nexa:sellDiamond', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Diamonds') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Diamonds', 1, false)
        nexa.notify(source, {'~g~Sold Diamonds for £'..getMoneyStringFormatted(defaultPrices['Diamond'])})
        nexa.giveBankMoney(user_id, defaultPrices['Diamond'])
        nexa.addStat(user_id, "diamond_sales", defaultPrices['Diamond'])
    else
        nexa.notify(source, {'~r~You do not have Diamond.'})
    end
end)

RegisterNetEvent('nexa:sellWeed')
AddEventHandler('nexa:sellWeed', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Weed') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Weed', 1, false)
        nexa.notify(source, {'~g~Sold Weed for £'..getMoneyStringFormatted(nexa.getCommissionPrice('Weed'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('Weed'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('Weed'), 'Weed')
        nexa.addStat(user_id, "weed_sales", nexa.getCommissionPrice('Weed'))
    else
        nexa.notify(source, {'~r~You do not have Weed.'})
    end
end)

RegisterNetEvent('nexa:sellCocaine')
AddEventHandler('nexa:sellCocaine', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Cocaine') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Cocaine', 1, false)
        nexa.notify(source, {'~g~Sold Cocaine for £'..getMoneyStringFormatted(nexa.getCommissionPrice('Cocaine'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('Cocaine'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('Cocaine'), 'Cocaine')
        nexa.addStat(user_id, "cocaine_sales", nexa.getCommissionPrice('Cocaine'))
    else
        nexa.notify(source, {'~r~You do not have Cocaine.'})
    end
end)

RegisterNetEvent('nexa:sellMeth')
AddEventHandler('nexa:sellMeth', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Meth') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Meth', 1, false)
        nexa.notify(source, {'~g~Sold Meth for £'..getMoneyStringFormatted(nexa.getCommissionPrice('Meth'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('Meth'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('Meth'), 'Meth')
        nexa.addStat(user_id, "meth_sales", nexa.getCommissionPrice('Meth'))
    else
        nexa.notify(source, {'~r~You do not have Meth.'})
    end
end)

RegisterNetEvent('nexa:sellHeroin')
AddEventHandler('nexa:sellHeroin', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'Heroin') > 0 then
        nexa.tryGetInventoryItem(user_id, 'Heroin', 1, false)
        nexa.notify(source, {'~g~Sold Heroin for £'..getMoneyStringFormatted(nexa.getCommissionPrice('Heroin'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('Heroin'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('Heroin'), 'Heroin')
        nexa.addStat(user_id, "heroin_sales", nexa.getCommissionPrice('Heroin'))
    else
        nexa.notify(source, {'~r~You do not have Heroin.'})
    end
end)

RegisterNetEvent('nexa:sellLSDNorth')
AddEventHandler('nexa:sellLSDNorth', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'LSD') > 0 then
        nexa.tryGetInventoryItem(user_id, 'LSD', 1, false)
        nexa.notify(source, {'~g~Sold LSD for £'..getMoneyStringFormatted(nexa.getCommissionPrice('LSDNorth'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('LSDNorth'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('LSDNorth'), 'LSDNorth')
        nexa.addStat(user_id, "lsd_sales", nexa.getCommissionPrice('LSDNorth'))
    else
        nexa.notify(source, {'~r~You do not have LSD.'})
    end
end)

RegisterNetEvent('nexa:sellLSDSouth')
AddEventHandler('nexa:sellLSDSouth', function()
    local source = source
    local user_id = nexa.getUserId(source)
    if nexa.getInventoryItemAmount(user_id, 'LSD') > 0 then
        nexa.tryGetInventoryItem(user_id, 'LSD', 1, false)
        nexa.notify(source, {'~g~Sold LSD for £'..getMoneyStringFormatted(nexa.getCommissionPrice('LSDSouth'))})
        nexa.giveDirtyMoney(user_id, nexa.getCommissionPrice('LSDSouth'))
        nexa.turfSaleToGangFunds(nexa.getCommissionPrice('LSDSouth'), 'LSDSouth')
        nexa.addStat(user_id, "lsd_sales", nexa.getCommissionPrice('LSDSouth'))
    else
        nexa.notify(source, {'~r~You do not have LSD.'})
    end
end)

RegisterNetEvent('nexa:sellAll')
AddEventHandler('nexa:sellAll', function()
    local source = source
    local user_id = nexa.getUserId(source)
    for k,v in pairs(defaultPrices) do
        if k == 'Copper' or k == 'Limestone' or k == 'Gold' then
            if nexa.getInventoryItemAmount(user_id, k) > 0 then
                local amount = nexa.getInventoryItemAmount(user_id, k)
                nexa.tryGetInventoryItem(user_id, k, amount, false)
                nexa.notify(source, {'~g~Sold '..amount..'x '..k..' for £'..getMoneyStringFormatted(defaultPrices[k]*amount)})
                nexa.giveBankMoney(user_id, defaultPrices[k]*amount)
                nexa.addStat(user_id, string.lower(k).."_sales", defaultPrices[k]*amount)
            end
        elseif k == 'Diamond' then
            if nexa.getInventoryItemAmount(user_id, 'Diamonds') > 0 then
                local amount = nexa.getInventoryItemAmount(user_id, 'Diamonds')
                nexa.tryGetInventoryItem(user_id, 'Diamonds', amount, false)
                nexa.notify(source, {'~g~Sold '..amount..'x Diamonds for £'..getMoneyStringFormatted(defaultPrices[k]*amount)})
                nexa.giveBankMoney(user_id, defaultPrices[k]*amount)
                nexa.addStat(user_id, "diamond_sales", defaultPrices[k]*amount)
            end
        end
    end
end)
