# Changelog

## 1.1.0
- Multi-framework support: Qbox, QBCore, ESX Legacy and TMC v2 (auto-detected)
- Inventory support: ox_inventory, qb-inventory (and forks), default ESX inventory
- Target support: ox_target and qb-target
- `Config.ItemOverrides` to rename loot items per framework
- `install/esx_items.sql` for the default ESX inventory
- Server export `GetRep(source)`
- All player-facing text moved to `locales/` (ox_lib locale system)
- Missing items are skipped with a debug message instead of failing
- `/clearneedle [id]` admin command to remove needle effects

## 1.0.0
- Initial release: bin searching, 5 rep levels, 5 loot tiers
- Needle sticks with configurable effects
- Injury chance, bin and player cooldowns, server-side anti-cheat
- `/binrep` and `/setbinrep`
