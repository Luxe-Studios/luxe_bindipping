local searching = false

local needleEndsAt = 0

local function damagePed(amount)
    if amount <= 0 then return end
    local health = GetEntityHealth(cache.ped)
    local floor = Config.Needle.minHealth
    if health <= floor then return end
    SetEntityHealth(cache.ped, math.max(floor, health - amount))
end

local function needleStick()
    local cfg = Config.Needle
    local alreadyAffected = needleEndsAt > GetGameTimer()
    needleEndsAt = GetGameTimer() + cfg.duration * 1000

    Bridge.Notify(locale('ouch'), locale('needle_stick'), 'error', 7000)
    damagePed(cfg.damage)

    if cfg.ragdoll then SetPedToRagdoll(cache.ped, 2500, 2500, 0, false, false, false) end
    if alreadyAffected then return end -- effects already running, just extended the timer

    if cfg.screenEffect then AnimpostfxPlay(cfg.screenEffect, 0, true) end
    if cfg.cameraShake > 0 then ShakeGameplayCam('DRUNK_SHAKE', cfg.cameraShake) end
    if cfg.walkStyle then
        lib.requestAnimSet(cfg.walkStyle)
        SetPedMovementClipset(cache.ped, cfg.walkStyle, 1.0)
    end

    CreateThread(function()
        local nextTick = GetGameTimer() + cfg.tickEvery * 1000
        while needleEndsAt > GetGameTimer() do
            if cfg.noSprint then DisableControlAction(0, 21, true) end
            if cfg.walkStyle and IsPedOnFoot(cache.ped) then
                SetPedMovementClipset(cache.ped, cfg.walkStyle, 1.0) -- re-apply after ragdoll
            end
            if cfg.tickDamage > 0 and GetGameTimer() >= nextTick then
                damagePed(cfg.tickDamage)
                nextTick = GetGameTimer() + cfg.tickEvery * 1000
            end
            if IsEntityDead(cache.ped) then break end
            Wait(0)
        end

        needleEndsAt = 0
        if cfg.screenEffect then AnimpostfxStop(cfg.screenEffect) end
        if cfg.cameraShake > 0 then StopGameplayCamShaking(true) end
        if cfg.walkStyle then
            ResetPedMovementClipset(cache.ped, 1.0)
            RemoveAnimSet(cfg.walkStyle)
        end
        Bridge.Notify(locale('title'), locale('needle_worn_off'), 'inform')
    end)
end

-- Admin: /clearneedle ends the effects early (the effect loop sees the timer expired and cleans up)
RegisterNetEvent('luxe_bindipping:client:clearNeedle', function()
    if GetInvokingResource() then return end
    if needleEndsAt > 0 then needleEndsAt = 0 end
end)

local function binId(coords)
    return ('%.1f:%.1f:%.1f'):format(coords.x, coords.y, coords.z)
end

local function searchBin(entity)
    if searching then return end
    local coords = GetEntityCoords(entity)
    local id = binId(coords)

    local ok, reason = lib.callback.await('luxe_bindipping:start', false, id, coords)
    if not ok then
        return Bridge.Notify(locale('title'), locale(reason), 'error')
    end

    searching = true

    if Config.UseSkillCheck and not lib.skillCheck({ 'easy', 'easy' }, { 'e' }) then
        searching = false
        lib.callback.await('luxe_bindipping:cancel', false)
        return Bridge.Notify(locale('title'), locale('fumbled'), 'error')
    end

    TaskTurnPedToFaceEntity(cache.ped, entity, 800)
    Wait(800)

    local done = Bridge.Progress({
        duration = Config.SearchTime,
        label = locale('searching'),
        anim = { dict = 'amb@prop_human_bum_bin@idle_b', clip = 'idle_d', flag = 1 },
    })

    searching = false

    if not done then
        lib.callback.await('luxe_bindipping:cancel', false)
        return Bridge.Notify(locale('title'), locale('stopped'), 'inform')
    end

    local result = lib.callback.await('luxe_bindipping:finish', false)
    if not result then
        return Bridge.Notify(locale('title'), locale('search_failed'), 'error')
    end

    if result.needled then
        needleStick()
    end

    if result.injured then
        SetEntityHealth(cache.ped, GetEntityHealth(cache.ped) - Config.InjuryDamage)
        Bridge.Notify(locale('ouch'), locale('cut_hand'), 'error')
    end

    if #result.found == 0 then
        Bridge.Notify(locale('title'), locale('nothing_found'), 'inform')
    else
        local lines = {}
        for i = 1, #result.found do
            local f = result.found[i]
            lines[i] = ('%dx %s'):format(f.count, f.label)
        end
        Bridge.Notify(locale('you_found'), table.concat(lines, ', '), 'success', 6000)
    end

    Bridge.Notify(locale('title'), locale('rep_gained', result.gained, result.rep), 'success')

    if result.levelUp then
        Bridge.Notify(locale('level_up'), locale('level_up_desc', result.levelLabel), 'success', 7000)
    end
end

Bridge.AddTargetModel(Config.BinModels, {
    name = 'luxe_bindipping:search',
    icon = 'fas fa-dumpster',
    label = locale('search_bin'),
    distance = 1.8,
    canInteract = function() return not searching end,
    onSelect = searchBin,
})

RegisterCommand('binrep', function()
    local rep = lib.callback.await('luxe_bindipping:getRep', false) or 0
    local idx, level = Config.GetLevel(rep)
    local nextLevel = Config.Levels[idx + 1]

    local progress, desc = 100, locale('rep_max')
    if nextLevel then
        progress = math.floor((rep - level.rep) / (nextLevel.rep - level.rep) * 100)
        desc = locale('rep_progress', rep, nextLevel.rep, nextLevel.label)
    end

    Bridge.InfoMenu('luxe_bindipping_rep', locale('rep_menu_title'), {
        { title = locale('rep_level', idx, level.label), description = desc, icon = 'dumpster', progress = progress },
        { title = locale('rep_total', rep), icon = 'star' },
    })
end, false)

TriggerEvent('chat:addSuggestion', '/binrep', locale('cmd_binrep'))

-- Used by luxe_reputation to show this rep in the Reputation menu
exports('GetLevels', function() return Config.Levels end)
