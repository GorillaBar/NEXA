local lang = nexa.lang
local cfg = module("cfg/atms")

RegisterNetEvent('nexa:Withdraw')
AddEventHandler('nexa:Withdraw', function(amount)
    local source = source
    local amount = parseInt(amount)
    if amount > 0 then
        local user_id = nexa.getUserId(source)
        if user_id ~= nil then
            if nexa.tryWithdraw(user_id, amount) then
                nexaclient.notify(source, {lang.atm.withdraw.withdrawn({getMoneyStringFormatted(amount)})})
            else
                nexaclient.notify(source, {lang.atm.withdraw.not_enough()})
            end
        end
    else
        nexaclient.notify(source, {lang.common.invalid_value()})
    end
end)


RegisterNetEvent('nexa:Deposit')
AddEventHandler('nexa:Deposit', function(amount)
    local source = source
    local amount = parseInt(amount)
    if amount > 0 then
        local user_id = nexa.getUserId(source)
        if user_id ~= nil then
            if nexa.tryDeposit(user_id, amount) then
                nexaclient.notify(source, {lang.atm.deposit.deposited({getMoneyStringFormatted(amount)})})
            else
                nexaclient.notify(source, {lang.money.not_enough()})
            end
        end
    else
        nexaclient.notify(source, {lang.common.invalid_value()})
    end
end)

RegisterNetEvent('nexa:WithdrawAll')
AddEventHandler('nexa:WithdrawAll', function()
    local source = source
    local amount = nexa.getBankMoney(nexa.getUserId(source))
    if amount > 0 then
        local user_id = nexa.getUserId(source)
        if user_id ~= nil then
            if nexa.tryWithdraw(user_id, amount) then
                nexaclient.notify(source, {lang.atm.withdraw.withdrawn({getMoneyStringFormatted(amount)})})
            else
                nexaclient.notify(source, {lang.atm.withdraw.not_enough()})
            end
        end
    else
        nexaclient.notify(source, {lang.common.invalid_value()})
    end
end)


RegisterNetEvent('nexa:DepositAll')
AddEventHandler('nexa:DepositAll', function()
    local source = source
    local amount = nexa.getMoney(nexa.getUserId(source))
    if amount > 0 then
        local user_id = nexa.getUserId(source)
        if user_id ~= nil then
            if nexa.tryDeposit(user_id, amount) then
                nexaclient.notify(source, {lang.atm.deposit.deposited({getMoneyStringFormatted(amount)})})
            else
                nexaclient.notify(source, {lang.money.not_enough()})
            end
        end
    else
        nexaclient.notify(source, {lang.common.invalid_value()})
    end
end)