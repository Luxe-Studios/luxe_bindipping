Config = {}

Config.Radial = { id = 'luxe_reputation', icon = 'star' } -- label comes from locales/
Config.Command = 'rep' -- /rep also opens the menu (set to false to disable)

-- Every rep shown in the menu.
--   metadata = the player metadata key the rep is saved under
--   resource = the script that owns it (exports GetLevels on the client and GetRep on the server)
-- Add a new line here whenever we make a new rep-based script.
Config.Reps = {
    { label = 'Bin Dipping', icon = 'dumpster', metadata = 'bindipping_rep', resource = 'luxe_bindipping' },
}
