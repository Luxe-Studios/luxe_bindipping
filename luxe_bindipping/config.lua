Config = {}

Config.Debug = false -- true = print why a search failed to the server console

-- Framework / inventory / target. Leave on 'auto' to detect automatically.
Config.Framework = 'auto' -- 'auto' | 'qbx' | 'qb' | 'esx'
Config.Inventory = 'auto' -- 'auto' | 'ox' | 'qb' | 'esx'   (qb = qb-inventory / ps / lj, esx = default ESX inventory)
Config.Target    = 'auto' -- 'auto' | 'ox' | 'qb'

-- Rename loot items per framework if your items are called something different.
-- Example: QBCore calls water 'water_bottle'. 'money' is always given as cash.
Config.ItemOverrides = {
    qbx = {},
    qb  = { water = 'water_bottle', sprunk = 'kurkakola' },
    esx = {},
}

-- Props that can be searched
Config.BinModels = {
    `prop_bin_01a`, `prop_bin_03a`, `prop_bin_05a`, `prop_bin_07a`, `prop_bin_07b`,
    `prop_bin_07c`, `prop_bin_07d`, `prop_bin_08a`, `prop_bin_08open`, `prop_bin_14a`,
    `prop_bin_14b`, `prop_dumpster_01a`, `prop_dumpster_02a`, `prop_dumpster_02b`,
    `prop_dumpster_3a`, `prop_dumpster_4a`, `prop_dumpster_4b`, `prop_cs_dumpster_01a`,
}

Config.SearchTime     = 6000   -- ms the progress bar takes
Config.BinCooldown    = 15     -- minutes before the same bin can be searched again
Config.PlayerCooldown = 5      -- seconds between searches for one player
Config.MaxDistance    = 5.0    -- how close the player must be to the bin (from its centre)
Config.UseSkillCheck  = true   -- quick skill check before searching

Config.RepPerSearch   = 5      -- rep gained for every completed search
Config.RepBonus       = { rare = 5, legendary = 15 } -- extra rep for great finds

Config.InjuryChance   = 4      -- % chance to cut yourself on something nasty
Config.InjuryDamage   = 5      -- health lost when that happens

-- Needle stick: chance to get jabbed by a dirty needle while searching
Config.Needle = {
    enabled  = true,
    chance   = 20,      -- % chance per search
    duration = 180,     -- seconds the effects last (180 = 3 minutes)

    damage      = 10,   -- instant health lost (0 to disable)
    tickDamage  = 1,    -- extra health lost every tick while affected (0 to disable)
    tickEvery   = 5,    -- seconds between ticks
    minHealth   = 120,  -- needle damage never takes a player below this (100 = dead in GTA, max 200)

    screenEffect = 'DrugsMichaelAliensFight', -- screen filter (false to disable)
    cameraShake  = 0.8,                       -- drunk camera shake strength (0 to disable)
    walkStyle    = 'move_m@drunk@verydrunk',  -- stumbling walk (false to disable)
    ragdoll      = true,                      -- fall over when jabbed
    noSprint     = true,                      -- can't sprint while affected
    stopsLoot    = false,                     -- true = getting jabbed means you find nothing

    -- Text shown to players is in locales/<language>.json
}

-- Levels: rep needed, how many loot rolls, chance of finding nothing,
-- and the weight of each loot tier (higher = more likely).
Config.Levels = {
    { label = 'Rookie Rummager', rep = 0,    rolls = 1, empty = 35, tiers = { junk = 70, common = 28, uncommon = 2,  rare = 0,  legendary = 0 } },
    { label = 'Trash Panda',     rep = 100,  rolls = 1, empty = 28, tiers = { junk = 50, common = 38, uncommon = 10, rare = 2,  legendary = 0 } },
    { label = 'Skip Diver',      rep = 300,  rolls = 2, empty = 22, tiers = { junk = 35, common = 38, uncommon = 20, rare = 6,  legendary = 1 } },
    { label = 'Bin Baron',       rep = 700,  rolls = 2, empty = 15, tiers = { junk = 20, common = 35, uncommon = 30, rare = 12, legendary = 3 } },
    { label = 'Garbage God',     rep = 1500, rolls = 3, empty = 10, tiers = { junk = 10, common = 30, uncommon = 35, rare = 19, legendary = 6 } },
}

-- Loot per tier. Items must exist in ox_inventory/data/items.lua.
Config.Loot = {
    junk = {
        { item = 'garbage',  min = 1, max = 3 },
        { item = 'paperbag', min = 1, max = 1 },
        { item = 'plastic',  min = 1, max = 3 },
        { item = 'glass',    min = 1, max = 2 },
    },
    common = {
        { item = 'rubber',     min = 1, max = 3 },
        { item = 'metalscrap', min = 1, max = 3 },
        { item = 'aluminum',   min = 1, max = 2 },
        { item = 'copper',     min = 1, max = 2 },
        { item = 'water',      min = 1, max = 1 },
        { item = 'sprunk',     min = 1, max = 1 },
        { item = 'sandwich',   min = 1, max = 1 },
    },
    uncommon = {
        { item = 'lockpick',       min = 1,  max = 1 },
        { item = 'screwdriverset', min = 1,  max = 1 },
        { item = 'iron',           min = 1,  max = 3 },
        { item = 'steel',          min = 1,  max = 3 },
        { item = 'radio',          min = 1,  max = 1 },
        { item = 'money',          min = 50, max = 150 },
    },
    rare = {
        { item = 'goldchain',        min = 1,   max = 1 },
        { item = '10kgoldchain',     min = 1,   max = 1 },
        { item = 'rolex',            min = 1,   max = 1 },
        { item = 'electronickit',    min = 1,   max = 1 },
        { item = 'advancedlockpick', min = 1,   max = 1 },
        { item = 'toaster',          min = 1,   max = 1 },
        { item = 'money',            min = 200, max = 500 },
    },
    legendary = {
        { item = 'diamond_ring', min = 1, max = 1 },
        { item = 'diamond',      min = 1, max = 2 },
        { item = 'goldbar',      min = 1, max = 1 },
        { item = 'small_tv',     min = 1, max = 1 },
    },
}

---Returns level index and data for a rep amount
function Config.GetLevel(rep)
    local idx = 1
    for i = 1, #Config.Levels do
        if rep >= Config.Levels[i].rep then idx = i end
    end
    return idx, Config.Levels[idx]
end
