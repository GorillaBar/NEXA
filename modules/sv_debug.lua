local debugCommands = {
    -- ['command'] = variable to toggle
    ['debug'] = false,
    ['debugargs'] = false,
}
for k,v in pairs(debugCommands) do
    RegisterCommand(k, function(source, args)
        local source = source
        if source == 0 then
            debugCommands[k] = not debugCommands[k]
            print(k..': '..tostring(debugCommands[k]))
        end
    end)
end
local origTriggerClientEvent = TriggerClientEvent
TriggerClientEvent = function(name, ...)
    if debugCommands['debug'] then
        print('^3TriggerClientEvent: ^6'..name..'^0')
        if debugCommands['debugargs'] then
            print('^3Args: ^6'..json.encode({...})..'^0')
        end
    end
    origTriggerClientEvent(name, ...)
end