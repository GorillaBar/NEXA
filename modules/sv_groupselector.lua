local cfg=module("cfg/cfg_groupselector")

function nexa.getJobSelectors(source)
    local source=source
    local jobSelectors={}
    local user_id = nexa.getUserId(source)
    for k,v in pairs(cfg.selectors) do
        for i,j in pairs(cfg.selectorTypes) do
            if v.type == i then
                v['_config'] = j._config
                v['jobs'] = j.jobs
                jobSelectors[k] = v
            end
        end
    end
    TriggerClientEvent("nexa:gotJobSelectors",source,jobSelectors)
end

RegisterNetEvent("nexa:getJobSelectors")
AddEventHandler("nexa:getJobSelectors",function()
    local source = source
    nexa.getJobSelectors(source)
end)