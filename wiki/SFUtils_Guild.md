Guild helper functions

## SafeGetGuildName(index)
`function sfutil.SafeGetGuildName(index)`

    where index is 1..5

 returns: 

     guild name, guild Id
     or  "Invalid guild x", nil if no such guild

 does not return nil for name! - if bad then return nil for guildId

## GetActiveGuildNames()
`function sfutil.GetActiveGuildNames()`

Get list of all active guild names in index order (1..5)

## GetActiveGuildIds()
`function sfutil.GetActiveGuildIds()`

Get list of all active guild ids in index order (1..5)


