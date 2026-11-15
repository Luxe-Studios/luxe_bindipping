-- Each rep script exports GetRep(source) on the server, so this works on any framework.
lib.callback.register('luxe_reputation:getAll', function(src)
    local values = {}
    for _, rep in ipairs(Config.Reps) do
        local value = 0
        if GetResourceState(rep.resource) == 'started' then
            local ok, result = pcall(function() return exports[rep.resource]:GetRep(src) end)
            if ok then value = tonumber(result) or 0 end
        end
        values[rep.metadata] = value
    end
    return values
end)
