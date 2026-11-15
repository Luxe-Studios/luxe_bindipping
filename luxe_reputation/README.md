# luxe_reputation

Adds a **Reputation** button to the radial menu (and `/rep`) that opens one menu showing every Luxe rep with level and progress bar.

Works with **Qbox, QBCore and ESX**. Requires **ox_lib** (the button uses the ox_lib radial menu, which Qbox uses by default).

## Adding a new rep script
1. In that script's server, export the player's rep: `exports('GetRep', function(src) return rep end)`
2. In that script's client, export its levels: `exports('GetLevels', function() return Config.Levels end)`
   (each level: `{ label = 'Name', rep = 0 }`).
3. Add a line to `Config.Reps` in this resource's `config.lua`.

## Translations
Text is in `locales/en.json`. Copy it to e.g. `locales/de.json`, translate it, and set `setr ox:locale "de"`.

## License
Free and open source under the **GNU GPL v3** (see `LICENSE`). By **Luxe Studios** · [luxestudios.shop](https://luxestudios.shop)
