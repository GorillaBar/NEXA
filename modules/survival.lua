local cfg = module("cfg/survival")
local lang = nexa.lang


-- handlers

-- init values
AddEventHandler("nexa:playerJoin", function(user_id, source, name, last_login)
    local data = nexa.getUserDataTable(user_id)
end)


---- revive
local revive_seq = {{"nexa@medic@standing@kneel@enter", "enter", 1}, {"nexa@medic@standing@kneel@idle_a", "idle_a", 1},
                    {"nexa@medic@standing@kneel@exit", "exit", 1}}

local choice_revive = {function(player, choice)
    local user_id = nexa.getUserId(player)
    if user_id ~= nil then
        nexaclient.getNearestPlayer(player, {10}, function(nplayer)
            local nuser_id = nexa.getUserId(nplayer)
            if nuser_id ~= nil then
                nexaclient.isInComa(nplayer, {}, function(in_coma)
                    if in_coma then
                        if nexa.tryGetInventoryItem(user_id, "medkit", 1, true) then
                            nexaclient.playAnim(player, {false, revive_seq, false}) -- anim
                            SetTimeout(15000, function()
                                nexaclient.varyHealth(nplayer, {50}) -- heal 50
                            end)
                        end
                    else
                        nexaclient.notify(player, {lang.emergency.menu.revive.not_in_coma()})
                    end
                end)
            else
                nexaclient.notify(player, {lang.common.no_player_near()})
            end
        end)
    end
end, lang.emergency.menu.revive.description()}