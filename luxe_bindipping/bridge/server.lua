-- Luxe Studios framework bridge (server)
-- Auto-detects Qbox / QBCore / ESX / TMC and ox_inventory / qb-inventory / ESX inventory / TMC inventory.
Bridge = {}

local function started(res) return GetResourceState(res) == 'started' end

local function detectFramework()
    local cfg = Config.Framework
    if cfg ~= 'auto' then return cfg end
    if started('qbx_core') then return 'qbx' end
    if started('qb-core') then return 'qb' end
    if started('es_extended') then return 'esx' end
    if started('core') then
        local ok, core = pcall(function() return exports.core:getCoreObject() end)
        if ok and core and core.Functions then return 'tmc' end
    end
end

local function detectInventory()
    local cfg = Config.Inventory
    if cfg ~= 'auto' then return cfg end
    if started('ox_inventory') then return 'ox' end
    if Bridge.framework == 'qb' then return 'qb' end
    if Bridge.framework == 'esx' then return 'esx' end
    if Bridge.framework == 'tmc' then return 'tmc' end
end

Bridge.framework = detectFramework()
Bridge.inventory = detectInventory()

local QB, ESX, TMC
if Bridge.framework == 'qb' then
    QB = exports['qb-core']:GetCoreObject()
elseif Bridge.framework == 'esx' then
    ESX = exports.es_extended:getSharedObject()
elseif Bridge.framework == 'tmc' then
    TMC = exports.core:getCoreObject()
    -- register our rep type so TMC shows it in its reputation UI
    if TMC.Shared and TMC.Shared.RepConfig and Config.TMC then
        TMC.Shared.RepConfig[Config.TMC.repType] = TMC.Shared.RepConfig[Config.TMC.repType] or { label = locale('title'), category = Config.TMC.repCategory }
    end
end

if not Bridge.framework then
    print('^1[luxe_bindipping] No supported framework found (qbx_core, qb-core, es_extended, TMC core). Set Config.Framework.^7')
else
    print(('^5[luxe_bindipping]^7 Framework: ^2%s^7 | Inventory: ^2%s^7'):format(Bridge.framework, Bridge.inventory or 'none'))
end

-- Item names can differ between frameworks; Config.ItemOverrides lets owners rename them.
function Bridge.ItemName(name)
    local overrides = Config.ItemOverrides[Bridge.framework]
    return overrides and overrides[name] or name
end

---------------------------------------------------------------- reputation
function Bridge.GetRep(src, key)
    local value
    if Bridge.framework == 'qbx' then
        value = exports.qbx_core:GetMetadata(src, key)
    elseif Bridge.framework == 'qb' then
        local player = QB.Functions.GetPlayer(src)
        value = player and player.PlayerData.metadata[key]
    elseif Bridge.framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        value = xPlayer and xPlayer.getMeta(key)
    elseif Bridge.framework == 'tmc' then
        local player = TMC.Functions.GetPlayer(src)
        value = player and player.PlayerData.rep and player.PlayerData.rep[Config.TMC.repType]
    end
    return tonumber(value) or 0
end

function Bridge.SetRep(src, key, value)
    if Bridge.framework == 'qbx' then
        exports.qbx_core:SetMetadata(src, key, value)
    elseif Bridge.framework == 'qb' then
        local player = QB.Functions.GetPlayer(src)
        if player then player.Functions.SetMetaData(key, value) end
    elseif Bridge.framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then xPlayer.setMeta(key, value) end
    elseif Bridge.framework == 'tmc' then
        local player = TMC.Functions.GetPlayer(src)
        if player then player.Functions.SetReputation(Config.TMC.repType, value, true) end
    end
end

---------------------------------------------------------------- inventory
local function isCash(name) return name == 'money' or name == 'cash' end

function Bridge.ItemExists(name)
    if isCash(name) then return true end
    if Bridge.inventory == 'ox' then return exports.ox_inventory:Items(name) ~= nil end
    if Bridge.inventory == 'qb' then return QB.Shared.Items[name] ~= nil end
    if Bridge.inventory == 'esx' then return ESX.GetItemLabel(name) ~= nil end
    if Bridge.inventory == 'tmc' then return TMC.Shared.Items[name] ~= nil end
    return false
end

function Bridge.ItemLabel(name)
    if isCash(name) then return locale('cash') end
    if Bridge.inventory == 'ox' then
        local item = exports.ox_inventory:Items(name)
        return item and item.label or name
    elseif Bridge.inventory == 'qb' then
        local item = QB.Shared.Items[name]
        return item and item.label or name
    elseif Bridge.inventory == 'esx' then
        return ESX.GetItemLabel(name) or name
    elseif Bridge.inventory == 'tmc' then
        local item = TMC.Shared.Items[name]
        return item and item.label or name
    end
    return name
end

function Bridge.CanCarry(src, name, count)
    if isCash(name) and Bridge.inventory ~= 'ox' then return true end
    if Bridge.inventory == 'ox' then
        return exports.ox_inventory:CanCarryItem(src, name, count)
    elseif Bridge.inventory == 'qb' then
        if GetResourceState('qb-inventory') == 'started' then
            local ok, can = pcall(function() return exports['qb-inventory']:CanAddItem(src, name, count) end)
            if ok and can ~= nil then return can end
        end
        return true
    elseif Bridge.inventory == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        return xPlayer and xPlayer.canCarryItem(name, count)
    elseif Bridge.inventory == 'tmc' then
        return true -- TMC drops items at your feet when you're full
    end
    return false
end

function Bridge.AddItem(src, name, count)
    if Bridge.inventory == 'ox' then
        return exports.ox_inventory:AddItem(src, name, count) and true or false
    end

    if Bridge.framework == 'qb' then
        local player = QB.Functions.GetPlayer(src)
        if not player then return false end
        if isCash(name) then return player.Functions.AddMoney('cash', count, 'bin-dipping') end
        local added = player.Functions.AddItem(name, count)
        if added then TriggerClientEvent('qb-inventory:client:ItemBox', src, QB.Shared.Items[name], 'add', count) end
        return added
    elseif Bridge.framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if not xPlayer then return false end
        if isCash(name) then xPlayer.addMoney(count) return true end
        xPlayer.addInventoryItem(name, count)
        return true
    elseif Bridge.framework == 'tmc' then
        local player = TMC.Functions.GetPlayer(src)
        if not player then return false end
        if isCash(name) then player.Functions.AddMoney('cash', count, 'bin-dipping') return true end
        local ok = player.Functions.AddItem(name, count)
        return ok ~= false
    end
    return false
end

---------------------------------------------------------------- notify (shown with the framework's own notifications)
function Bridge.Notify(src, msg, type)
    TriggerClientEvent('luxe_bindipping:notify', src, msg, type or 'inform')
end
