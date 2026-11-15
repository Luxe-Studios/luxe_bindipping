-- Luxe Studios framework bridge (client): target / prompts, notifications, progress bar, menus
-- Qbox / QBCore / ESX use ox_lib + ox_target / qb-target. TMC uses its own prompts and UI.
Bridge = {}

local function started(res) return GetResourceState(res) == 'started' end

local function detectFramework()
    if Config.Framework ~= 'auto' then return Config.Framework end
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    if started('core') then
        local ok, core = pcall(function() return exports.core:getCoreObject() end)
        if ok and core and core.Functions then return 'tmc' end
    end
end

Bridge.framework = detectFramework()
local TMC = Bridge.framework == 'tmc' and exports.core:getCoreObject() or nil

local function detectTarget()
    if Config.Target ~= 'auto' then return Config.Target end
    if TMC then return 'tmc' end
    if started('ox_target') then return 'ox' end
    if started('qb-target') then return 'qb' end
end

Bridge.target = detectTarget()

-- TMC: show our rep in TMC's reputation UI
if TMC and TMC.Shared and TMC.Shared.RepConfig and Config.TMC then
    TMC.Shared.RepConfig[Config.TMC.repType] = TMC.Shared.RepConfig[Config.TMC.repType] or { label = locale('title'), category = Config.TMC.repCategory }
end

---------------------------------------------------------------- notifications
local TMC_TYPES = { inform = 'info', success = 'success', error = 'error', warning = 'warning' }

---@param title string
---@param msg string
---@param kind? 'inform'|'success'|'error'|'warning'
---@param duration? number
function Bridge.Notify(title, msg, kind, duration)
    if TMC then
        TMC.Functions.Notify({ message = msg, notifType = TMC_TYPES[kind or 'inform'] or 'info', length = duration })
    else
        lib.notify({ title = title, description = msg, type = kind or 'inform', duration = duration })
    end
end

RegisterNetEvent('luxe_bindipping:notify', function(msg, kind)
    if GetInvokingResource() then return end
    Bridge.Notify(locale('title'), msg, kind)
end)

---------------------------------------------------------------- progress bar
---@param o { duration: number, label: string, anim: { dict: string, clip: string, flag: number } }
---@return boolean completed
function Bridge.Progress(o)
    if not TMC then
        return lib.progressBar({
            duration = o.duration, label = o.label, useWhileDead = false, canCancel = true,
            disable = { move = true, car = true, combat = true },
            anim = o.anim,
        })
    end
    lib.requestAnimDict(o.anim.dict)
    TaskPlayAnim(cache.ped, o.anim.dict, o.anim.clip, 3.0, 3.0, -1, o.anim.flag or 1, 0, false, false, false)
    local p = promise.new()
    TMC.Functions.ProgressBar(function(complete) p:resolve(complete and true or false) end, o.duration, locale('title'), o.label, { canCancel = true })
    local done = Citizen.Await(p)
    StopAnimTask(cache.ped, o.anim.dict, o.anim.clip, 1.0)
    RemoveAnimDict(o.anim.dict)
    return done
end

---------------------------------------------------------------- menus (read-only info)
---@param id string
---@param title string
---@param rows { title: string, description?: string, icon?: string, progress?: number }[]
function Bridge.InfoMenu(id, title, rows)
    if TMC then
        local elements = {}
        for i, r in ipairs(rows) do
            elements[#elements + 1] = { type = 'button', name = ('row%d'):format(i), label = r.title, description = r.description, icon = r.icon and ('fa-solid fa-' .. r.icon) or nil }
        end
        TMC.Functions.OpenMenu({ namespace = id, title = title }, elements, function() end, function() end, function() TMC.Functions.CloseMenu() end)
        return
    end
    local options = {}
    for _, r in ipairs(rows) do
        options[#options + 1] = { title = r.title, description = r.description, icon = r.icon, progress = r.progress, colorScheme = 'pink', readOnly = true }
    end
    lib.registerContext({ id = id, title = title, options = options })
    lib.showContext(id)
end

---------------------------------------------------------------- target / prompt
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
    elseif Bridge.target == 'tmc' then
        -- TMC: show a prompt while standing next to one of the models
        local nearest
        local group = TMC.Functions.CreatePromptGroup({ {
            Id = opt.name,
            Title = opt.label,
            Description = locale('title'),
            Icon = 'fa-solid fa-dumpster',
            AutoComplete = false,
            Complete = function()
                local ent = nearest
                if ent and DoesEntityExist(ent) and (not opt.canInteract or opt.canInteract(ent)) then opt.onSelect(ent) end
            end,
        } })
        CreateThread(function()
            while true do
                local sleep = 600
                nearest = nil
                if not IsPedInAnyVehicle(cache.ped, false) and not IsEntityDead(cache.ped) then
                    local pos = GetEntityCoords(cache.ped)
                    local best = opt.distance + 0.01
                    for i = 1, #models do
                        local obj = GetClosestObjectOfType(pos.x, pos.y, pos.z, opt.distance + 1.0, models[i], false, false, false)
                        if obj ~= 0 then
                            local d = #(pos - GetEntityCoords(obj))
                            if d < best then best, nearest = d, obj end
                        end
                    end
                end
                if nearest and (not opt.canInteract or opt.canInteract(nearest)) then
                    TMC.Functions.ShowPromptGroup(group)
                    sleep = 250
                elseif TMC.Functions.IsPromptGroupVisible(group) then
                    TMC.Functions.HidePromptGroup(group)
                end
                Wait(sleep)
            end
        end)
        AddEventHandler('onResourceStop', function(res)
            if res == GetCurrentResourceName() then TMC.Functions.DeletePromptGroup(group) end
        end)
    else
        print('^1[luxe_bindipping] No target system found (ox_target, qb-target or TMC). Set Config.Target.^7')
    end
end
