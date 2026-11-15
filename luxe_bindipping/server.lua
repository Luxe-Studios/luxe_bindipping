local REP_KEY = 'bindipping_rep'
local binCooldowns = {}   -- [binId] = os.time() when it can be searched again
local playerCooldowns = {} -- [src] = os.time() when they can search again
local active = {}         -- [src] = { id, coords, started }

local function dbg(src, msg)
    if Config.Debug then print(('^3[luxe_bindipping]^7 %s (player %s)'):format(msg, src)) end
end

local function getRep(src) return Bridge.GetRep(src, REP_KEY) end
local function setRep(src, rep) Bridge.SetRep(src, REP_KEY, rep) end

exports('GetRep', getRep)
exports('GetLevels', function() return Config.Levels end)

local function weightedPick(weights)
    local total = 0
    for _, w in pairs(weights) do total += w end
    if total <= 0 then return nil end
    local roll = math.random() * total
    for tier, w in pairs(weights) do
        roll -= w
        if roll <= 0 then return tier end
    end
end

lib.callback.register('luxe_bindipping:getRep', function(src)
    return getRep(src)
end)

lib.callback.register('luxe_bindipping:start', function(src, id, coords)
    if type(id) ~= 'string' or type(coords) ~= 'vector3' then return false, 'invalid_bin' end
    local now = os.time()

    if active[src] then return false, 'already_searching' end
    if (playerCooldowns[src] or 0) > now then return false, 'slow_down' end

    local ped = GetPlayerPed(src)
    if #(GetEntityCoords(ped) - coords) > Config.MaxDistance then
        return false, 'too_far'
    end

    if (binCooldowns[id] or 0) > now then
        return false, 'bin_empty_cooldown'
    end

    binCooldowns[id] = now + Config.BinCooldown * 60
    active[src] = { id = id, coords = coords, started = GetGameTimer() }
    return true
end)

lib.callback.register('luxe_bindipping:cancel', function(src)
    local search = active[src]
    if search then binCooldowns[search.id] = nil end
    active[src] = nil
    return true
end)

lib.callback.register('luxe_bindipping:finish', function(src)
    local search = active[src]
    active[src] = nil
    if not search then dbg(src, 'finish called with no active search') return end

    -- Anti-cheat: must have actually taken the full search time and stayed near the bin
    if GetGameTimer() - search.started < Config.SearchTime - 500 then dbg(src, 'finished too fast') return end
    if #(GetEntityCoords(GetPlayerPed(src)) - search.coords) > Config.MaxDistance then dbg(src, 'too far from bin on finish') return end

    playerCooldowns[src] = os.time() + Config.PlayerCooldown

    local rep = getRep(src)
    local oldIdx, level = Config.GetLevel(rep)
    local gained = Config.RepPerSearch
    local found = {}

    local needled = Config.Needle.enabled and math.random(100) <= Config.Needle.chance
    local rolls = (needled and Config.Needle.stopsLoot) and 0 or level.rolls

    for _ = 1, rolls do
        if math.random(100) > level.empty then
            local tier = weightedPick(level.tiers)
            local pool = tier and Config.Loot[tier]
            if pool and #pool > 0 then
                local loot = pool[math.random(#pool)]
                local item = Bridge.ItemName(loot.item)
                local count = math.random(loot.min, loot.max)
                if not Bridge.ItemExists(item) then
                    dbg(src, ('item "%s" does not exist in your inventory - add it or set Config.ItemOverrides'):format(item))
                elseif Bridge.CanCarry(src, item, count) then
                    if Bridge.AddItem(src, item, count) then
                        found[#found + 1] = { label = Bridge.ItemLabel(item), count = count, tier = tier }
                        gained += Config.RepBonus[tier] or 0
                    else
                        dbg(src, ('AddItem failed for %s'):format(item))
                    end
                else
                    Bridge.Notify(src, locale('pockets_full'), 'error')
                end
            end
        end
    end

    rep += gained
    setRep(src, rep)
    local newIdx, newLevel = Config.GetLevel(rep)

    return {
        found = found,
        gained = gained,
        rep = rep,
        needled = needled,
        injured = not needled and math.random(100) <= Config.InjuryChance,
        levelUp = newIdx > oldIdx,
        levelLabel = newLevel.label,
    }
end)

AddEventHandler('playerDropped', function()
    local src = source
    active[src] = nil
    playerCooldowns[src] = nil
end)

-- Admin: /setbinrep [id] [amount]
lib.addCommand('setbinrep', {
    help = locale('cmd_setbinrep'),
    restricted = 'group.admin',
    params = {
        { name = 'target', type = 'playerId', help = locale('cmd_setbinrep_target') },
        { name = 'amount', type = 'number', help = locale('cmd_setbinrep_amount') },
    },
}, function(src, args)
    setRep(args.target, math.max(0, math.floor(args.amount)))
    local _, level = Config.GetLevel(args.amount)
    dbg(src, ('set rep of %s to %s'):format(args.target, args.amount))
    if src > 0 then Bridge.Notify(src, locale('admin_set_rep', args.amount, level.label), 'success') end
end)

-- Admin: /clearneedle [id] - removes needle stick effects (yourself if no id)
lib.addCommand('clearneedle', {
    help = locale('cmd_clearneedle'),
    restricted = 'group.admin',
    params = {
        { name = 'target', type = 'playerId', help = locale('cmd_setbinrep_target'), optional = true },
    },
}, function(src, args)
    local target = args.target or src
    if not target or target <= 0 then return end
    TriggerClientEvent('luxe_bindipping:client:clearNeedle', target)
    if src > 0 then Bridge.Notify(src, locale('admin_cleared_needle'), 'success') end
end)
