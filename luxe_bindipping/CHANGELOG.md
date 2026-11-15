# Changelog

## 1.2.0
- **TMC framework support**: TMC prompts (no target needed), TMC notifications, progress bar and menus, TMC inventory and cash, and rep saved in TMC's built-in reputation (shows in TMC's rep UI under Civilian)
- Item name overrides for TMC (`Config.ItemOverrides.tmc`)

## 1.1.0
- Multi-framework support: Qbox, QBCore and ESX Legacy (auto-detected)
- Inventory support: ox_inventory, qb-inventory (and forks), default ESX inventory
- Target support: ox_target and qb-target
- `Config.ItemOverrides` to rename loot items per framework
- `install/esx_items.sql` for the default ESX inventory
- Server export `GetRep(source)`
- All player-facing text moved to `locales/` (ox_lib locale system)
- Missing items are skipped with a debug message instead of failing

## 1.0.0
- Initial release: bin searching, 5 rep levels, 5 loot tiers
- Needle sticks with configurable effects
- Injury chance, bin and player cooldowns, server-side anti-cheat
- `/binrep` and `/setbinrep`
