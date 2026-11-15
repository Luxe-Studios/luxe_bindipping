local function getLevels(resource)
    if GetResourceState(resource) ~= 'started' then return end
    local ok, levels = pcall(function() return exports[resource]:GetLevels() end)
    return ok and levels or nil
end

local function levelFor(levels, rep)
    local idx = 1
    for i = 1, #levels do
        if rep >= levels[i].rep then idx = i end
    end
    return idx, levels[idx], levels[idx + 1]
end

local function openMenu()
    local values = lib.callback.await('luxe_reputation:getAll', false) or {}
    local options = {}

    for _, rep in ipairs(Config.Reps) do
        local amount = values[rep.metadata] or 0
        local levels = getLevels(rep.resource)

        if levels and #levels > 0 then
            local idx, level, nextLevel = levelFor(levels, amount)
            local progress, desc = 100, locale('rep_max', amount)
            if nextLevel then
                progress = math.floor((amount - level.rep) / (nextLevel.rep - level.rep) * 100)
                desc = locale('rep_progress', amount, nextLevel.rep, nextLevel.label)
            end
            options[#options + 1] = {
                title = locale('rep_entry', rep.label, idx, level.label),
                description = desc,
                icon = rep.icon,
                progress = progress,
                colorScheme = 'pink',
                readOnly = true,
            }
        else
            options[#options + 1] = {
                title = rep.label,
                description = locale('rep_only', amount),
                icon = rep.icon,
                readOnly = true,
            }
        end
    end

    if #options == 0 then
        options[1] = { title = locale('no_rep'), readOnly = true }
    end

    lib.registerContext({ id = 'luxe_reputation_menu', title = locale('menu_title'), options = options })
    lib.showContext('luxe_reputation_menu')
end

exports('OpenMenu', openMenu)

lib.addRadialItem({
    id = Config.Radial.id,
    label = Config.Radial.label or locale('radial_label'),
    icon = Config.Radial.icon,
    onSelect = openMenu,
})

if Config.Command then
    RegisterCommand(Config.Command, openMenu, false)
    TriggerEvent('chat:addSuggestion', '/' .. Config.Command, locale('cmd_rep'))
end

AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then lib.removeRadialItem(Config.Radial.id) end
end)
