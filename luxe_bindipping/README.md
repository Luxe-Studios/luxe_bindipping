# Luxe Bin Dipping

**by Luxe Studios** · works with **Qbox**, **QBCore** and **ESX**, detected automatically

Players search bins and dumpsters around the city for loot. Every search earns **reputation**. The more rep a player has, the higher their level, and the better their loot: more items per bin, fewer empty bins, and access to rare and legendary finds. There's also a configurable chance of being stabbed by a dirty needle, with drug-style effects.

---

## Features

- **Search any bin or dumpster** with the third eye (ox_target): skill check, rummaging animation, progress bar
- **5 rep levels**, from *Rookie Rummager* to *Garbage God*, each with better loot odds
- **5 loot tiers** (junk → common → uncommon → rare → legendary)
- **Needle sticks**: damage, trippy screen, camera shake, drunk walk, no sprinting, all configurable
- **Small injury chance** (cut hand) for extra realism
- **Per-bin cooldowns**, so the same bin can't be farmed
- **Server-side loot and rep** with distance and timing checks, so the client can't spawn items
- **Rep is saved to the character** and survives restarts and relogs
- **`/binrep` menu** with a progress bar to the next level
- Works with **luxe_reputation** to show rep in the radial menu
- **Multi-framework**: auto-detects Qbox, QBCore or ESX, ox_inventory / qb-inventory / ESX inventory, and ox_target / qb-target
- Uses only items that **already exist in a default Qbox / ox_inventory install** (SQL included for ESX)

---

## Requirements

**Always required:** [`ox_lib`](https://github.com/overextended/ox_lib)

Plus **one** of each (the script detects which you have):

| Type | Supported |
|---|---|
| Framework | `qbx_core` (Qbox), `qb-core` (QBCore), `es_extended` (ESX Legacy **1.9+**) |
| Inventory | `ox_inventory` (any framework), `qb-inventory` (and forks like ps / lj), default ESX inventory |
| Target | `ox_target`, `qb-target` |

When the resource starts, the server console prints what it detected, for example:
```
[luxe_bindipping] Framework: qb | Inventory: qb
```

---

## Installation

1. Drop the `luxe_bindipping` folder into your `resources` folder.
2. Add it to your `server.cfg` **after** your framework, inventory, target and ox_lib:
   ```
   ensure luxe_bindipping
   ```
3. **Make sure the loot items exist** in your inventory:
   - **ox_inventory (Qbox / QBCore / ESX):** they're all in a default Qbox install. On other setups, add any missing ones to `ox_inventory/data/items.lua`.
   - **qb-inventory:** most exist in `qb-core/shared/items.lua`. `water` and `sprunk` are renamed to `water_bottle` and `kurkakola` by default via `Config.ItemOverrides.qb`.
   - **ESX default inventory:** run `install/esx_items.sql` on your database.

   Any loot item that doesn't exist is skipped, and (with `Config.Debug = true`) the console tells you which one.
4. **ox_inventory users: disable the default dumpster search** (recommended). Without this, dumpsters show two options: ours, and ox_inventory's "Search Dumpster", which opens an empty bin inventory.

   In `ox_inventory/modules/inventory/client.lua`, find this block and comment it out:
   ```lua
   exports.ox_target:addModel(Inventory.Dumpsters, {
       icon = 'fas fa-dumpster',
       label = locale('search_dumpster'),
       onSelect = function(data) return Inventory.OpenDumpster(data.entity) end,
       distance = 2
   })
   ```
   > ⚠️ Updating ox_inventory will undo this change, so re-apply it after every update.
5. Restart your server.

No SQL is needed for rep. It's stored in the player's existing metadata (Qbox / QBCore metadata, ESX `getMeta`).

---

## Commands

| Command | Who | What it does |
|---|---|---|
| `/binrep` | Everyone | Shows your level, total rep and progress to the next level |
| `/setbinrep [id] [amount]` | `group.admin` | Sets a player's rep (useful for testing levels) |
| `/clearneedle [id]` | `group.admin` | Removes needle stick effects straight away (yourself if no ID) |
| `/rep` | Everyone | Opens the full Reputation menu (needs **luxe_reputation**) |

---

## Configuration (`config.lua`)

### General
| Option | Default | Description |
|---|---|---|
| `Config.Debug` | `false` | Set to `true` to print why a search failed to the server console. |
| `Config.Framework` | `'auto'` | `'auto'`, `'qbx'`, `'qb'` or `'esx'` |
| `Config.Inventory` | `'auto'` | `'auto'`, `'ox'`, `'qb'` (qb-inventory and forks) or `'esx'` (default ESX inventory) |
| `Config.Target` | `'auto'` | `'auto'`, `'ox'` or `'qb'` |
| `Config.ItemOverrides` | qb: water, sprunk | Rename loot items per framework, e.g. `qb = { water = 'water_bottle' }` |
| `Config.BinModels` | 18 props | Which bin and dumpster props can be searched. Add any prop name here. |
| `Config.SearchTime` | `6000` | How long the search takes (milliseconds) |
| `Config.BinCooldown` | `15` | Minutes before the same bin can be searched again |
| `Config.PlayerCooldown` | `5` | Seconds a player must wait between searches |
| `Config.MaxDistance` | `5.0` | Max distance from the bin's centre (anti-cheat) |
| `Config.UseSkillCheck` | `true` | Show a skill check before searching |

### Reputation
| Option | Default | Description |
|---|---|---|
| `Config.RepPerSearch` | `5` | Rep for every completed search |
| `Config.RepBonus` | `rare = 5, legendary = 15` | Extra rep for finding items from these tiers |

### Injury (cut hand)
| Option | Default | Description |
|---|---|---|
| `Config.InjuryChance` | `4` | % chance per search |
| `Config.InjuryDamage` | `5` | Health lost |

### Needle stick (`Config.Needle`)
| Option | Default | Description |
|---|---|---|
| `enabled` | `true` | Turn needle sticks on or off |
| `chance` | `20` | % chance per search |
| `duration` | `180` | How long effects last (seconds). Getting jabbed again resets the timer. |
| `damage` | `10` | Instant health lost (`0` = off) |
| `tickDamage` | `1` | Health lost every tick while affected (`0` = off) |
| `tickEvery` | `5` | Seconds between ticks |
| `minHealth` | `120` | Needle damage never takes a player below this, so it **can't kill** (GTA: 100 = dead, 200 = full) |
| `screenEffect` | `'DrugsMichaelAliensFight'` | Screen filter (`false` = off). Any GTA `AnimpostfxPlay` effect works. |
| `cameraShake` | `0.8` | Drunk camera shake strength (`0` = off) |
| `walkStyle` | `'move_m@drunk@verydrunk'` | Stumbling walk (`false` = off) |
| `ragdoll` | `true` | Player falls over when jabbed |
| `noSprint` | `true` | Player can't sprint while affected |
| `stopsLoot` | `false` | `true` = getting jabbed means that search finds nothing |

### Levels (`Config.Levels`)
Each level has:
- `label`: level name
- `rep`: rep needed to reach it
- `rolls`: how many loot rolls per search
- `empty`: % chance each roll finds nothing
- `tiers`: weight of each loot tier (higher = more likely; they don't need to add up to 100)

**Default levels**

| Level | Rep | Rolls | Empty | Junk | Common | Uncommon | Rare | Legendary |
|---|---|---|---|---|---|---|---|---|
| Rookie Rummager | 0 | 1 | 35% | 70 | 28 | 2 | 0 | 0 |
| Trash Panda | 100 | 1 | 28% | 50 | 38 | 10 | 2 | 0 |
| Skip Diver | 300 | 2 | 22% | 35 | 38 | 20 | 6 | 1 |
| Bin Baron | 700 | 2 | 15% | 20 | 35 | 30 | 12 | 3 |
| Garbage God | 1500 | 3 | 10% | 10 | 30 | 35 | 19 | 6 |

You can add, remove or rename levels freely. Keep them in order from lowest to highest rep.

### Loot (`Config.Loot`)
Each tier is a list of `{ item = 'name', min = 1, max = 3 }`. One item is picked at random from the tier, with a random amount between `min` and `max`.

**Default loot**

| Tier | Items |
|---|---|
| Junk | garbage, paperbag, plastic, glass |
| Common | rubber, metalscrap, aluminum, copper, water, sprunk, sandwich |
| Uncommon | lockpick, screwdriverset, iron, steel, radio, cash ($50–150) |
| Rare | goldchain, 10kgoldchain, rolex, electronickit, advancedlockpick, toaster, cash ($200–500) |
| Legendary | diamond_ring, diamond, goldbar, small_tv |

> Every item must exist in your inventory (`ox_inventory/data/items.lua`, `qb-core/shared/items.lua`, or the ESX `items` table). `money` is always paid as **cash** (an item on ox_inventory, cash balance on QBCore / ESX).

---

## Translations

All player-facing text is in `locales/en.json`. To translate:
1. Copy `locales/en.json` to e.g. `locales/de.json` and translate the values (keep the keys and any `%s` / `%d`).
2. Set the language in your `server.cfg`:
   ```
   setr ox:locale "de"
   ```
Missing files fall back to English. Pull requests with new languages are welcome!

---

## Rep storage

Rep is saved in the player's character data under the key **`bindipping_rep`**:
- **Qbox / QBCore:** player metadata
- **ESX:** `xPlayer.getMeta` / `setMeta` (ESX Legacy 1.9+)

Other scripts can read it on any framework with the server export below.

## Exports

| Side | Export | Returns |
|---|---|---|
| Server | `exports.luxe_bindipping:GetRep(source)` | The player's rep (number) |
| Client | `exports.luxe_bindipping:GetLevels()` | The `Config.Levels` table (used by luxe_reputation) |

---

## Troubleshooting

| Problem | Fix |
|---|---|
| "Search failed, try again" | Set `Config.Debug = true` and check the server console for a yellow `[luxe_bindipping]` line. It will tell you why. |
| Dumpster opens an empty inventory | That's ox_inventory's default option. See step 3 of Installation. |
| "Your pockets are full" | The player's inventory is too heavy or full for that item. |
| "This bin has already been picked clean" | That bin is on cooldown (`Config.BinCooldown`). |
| No "Search Bin" option on a bin | That prop isn't in `Config.BinModels`. Add it. |
| Item doesn't appear | Check the console for `item "x" does not exist`, then add the item or rename it in `Config.ItemOverrides`. |
| "No supported framework found" | Make sure `luxe_bindipping` starts **after** your framework, or set `Config.Framework` manually. |
| No target option on ESX | Install `ox_target` (or `qb-target`), or set `Config.Target`. |
| ESX: `attempt to call a nil value (field 'getMeta')` | Your ESX is too old. Update to ESX Legacy 1.9 or newer. |

---

## License

Free and open source under the **GNU GPL v3** (see `LICENSE`). You can use, modify and share it, but modified versions must stay open source under the same license, and it may **not be sold or escrowed**. Please keep the credit to Luxe Studios.

**Luxe Studios** · [luxestudios.shop](https://luxestudios.shop)
