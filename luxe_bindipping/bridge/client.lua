-- Luxe Studios framework bridge (client): target systems
Bridge = {}

local function detectTarget()
    if Config.Target ~= 'auto' then return Config.Target end
    if GetResourceState('ox_target') == 'started' then return 'ox' end
    if GetResourceState('qb-target') == 'started' then return 'qb' end
end

Bridge.target = detectTarget()

---@param models table
---@param opt { name: string, icon: string, label: string, distance: number, canInteract: function, onSelect: fun(entity: number) }
function Bridge.AddTargetModel(models, opt)
    if Bridge.target == 'ox' then
        exports.ox_target:addModel(models, {
            {
                name = opt.name,
                icon = opt.icon,
                label = opt.label,
                distance = opt.distance,
                canInteract = opt.canInteract,
                onSelect = function(data) opt.onSelect(data.entity) end,
            },
        })
    elseif Bridge.target == 'qb' then
        exports['qb-target']:AddTargetModel(models, {
            options = {
                {
                    icon = opt.icon,
                    label = opt.label,
                    canInteract = opt.canInteract,
                    action = function(entity) opt.onSelect(entity) end,
                },
            },
            distance = opt.distance,
        })
    else
        print('^1[luxe_bindipping] No target system found (ox_target or qb-target). Set Config.Target.^7')
    end
end
