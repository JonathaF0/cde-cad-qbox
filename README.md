# CDECAD-Sync for QBox

A comprehensive FiveM resource that automatically syncs QBox character data to your CDECAD system.

## Features

- **Automatic Character Sync**: Characters are automatically synced to CDECAD when created/loaded
- **Discord Account Linking**: Links FiveM characters to users' CAD accounts via Discord ID
- **Discord Role Integration**: Filter syncing based on Discord roles (exclude LEO/EMS characters)
- **Vehicle Registration**: Automatically register vehicles when purchased
- **911 Call System**: Full 911 call integration with coordinates and postal codes
- **NPC Witness Reports**: Automated crime reports when NPCs witness crimes
- **Admin Commands**: Full admin tools for manual syncing and lookups

## Requirements

- [QBox (qbx_core)](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [Badger_Discord_API](https://github.com/JaredScar/Badger_Discord_API) (Optional, recommended)
- [NearestPostal](https://forum.cfx.re/t/release-nearest-postal-script/293511) (Optional, recommended)

## Installation

1. Download and extract to your resources folder as `cdecad-sync-qbox`
2. Configure `shared/config.lua` with your API settings
3. Add `ensure cdecad-sync-qbox` to your server.cfg (after qbx_core and ox_lib)
4. Restart your server

## Configuration

Edit `shared/config.lua`:

```lua
-- API Settings
Config.API_URL = 'https://your-cdecad-instance.com/api'
Config.API_KEY = 'your-fivem-api-key'
Config.COMMUNITY_ID = 'your-discord-guild-id'  -- Your Discord SERVER ID

-- Sync Settings
Config.Sync.OnCharacterLoad = true      -- Sync when player loads character
Config.Sync.OnCharacterCreate = true    -- Sync new characters
Config.Sync.SyncVehicles = true         -- Sync vehicle registrations
```

## Commands

### Player Commands
| Command | Description |
|---------|-------------|
| `/911 [message]` | Send emergency call |
| `/call911` | Interactive 911 call |
| `/911anon [message]` | Anonymous emergency call |
| `/reportstolen` | Report current vehicle stolen |
| `/panic` | Send panic alert (if enabled) |

### Admin Commands
| Command | Description |
|---------|-------------|
| `/cadsync [playerid]` | Force sync a player |
| `/cadsyncall` | Sync all online players |
| `/cadstatus` | Check API connection status |
| `/cadlookup [id/plate]` | Lookup civilian or vehicle |

## QBox Player Data Structure

This resource uses the standard QBox player data:

```lua
exports.qbx_core:GetPlayer(source)
Player.PlayerData.citizenid           -- Unique character ID
Player.PlayerData.charinfo.firstname  -- First name
Player.PlayerData.charinfo.lastname   -- Last name
Player.PlayerData.charinfo.birthdate  -- Date of birth
Player.PlayerData.charinfo.gender     -- 0 = male, 1 = female
Player.PlayerData.charinfo.nationality
Player.PlayerData.charinfo.phone
```

## Exports

```lua
-- Sync a player's character
exports['cdecad-sync-qbox']:SyncCharacter(source)

-- Send a 911 call
exports['cdecad-sync-qbox']:Send911Call(callData)

-- Get synced civilian ID
exports['cdecad-sync-qbox']:GetSyncedCivilianId(citizenid)

-- Force sync
exports['cdecad-sync-qbox']:ForceSync(source)
```

## Troubleshooting

### Characters not syncing
1. Check `Config.API_URL` is correct (no trailing slash)
2. Verify `Config.API_KEY` matches your backend's `FIVEM_API_KEY`
3. Ensure `Config.COMMUNITY_ID` is your Discord Server ID (not a user ID)
4. Check F8 console and server console for errors

### 401 Unauthorized
- Your API key doesn't match. Check both FiveM config and backend `.env` file

### Community not found
- Your `Config.COMMUNITY_ID` doesn't match any community's `guildId` in the database

## Installation

### 1. Download & Extract

1. Download this resource
2. Extract to your `resources` folder as `cdecad-sync`

### 2. Configure server.cfg

Add to your `server.cfg`:

```cfg
ensure ox_lib
ensure qbx_core
ensure Badger_Discord_API  # Optional but recommended
ensure cdecad-sync
```

### 3. Configure the Resource

Edit `shared/config.lua`:

```lua
-- Your CDECAD API URL (no trailing slash)
Config.API_URL = 'https://your-cdecad-instance.com/api'

-- Your CDECAD API Key
Config.API_KEY = 'your-api-key-here'

-- Your Community ID (Discord Guild ID)
Config.COMMUNITY_ID = 'your-discord-guild-id'
```

### 4. Discord Role Configuration (Optional)

If you want to exclude LEO/EMS characters from civilian sync:

```lua
Config.Discord = {
    Enabled = true,
    UseBadgerAPI = true,
    
    -- Roles that should NOT be synced
    ExcludedRoles = {
        'Police',
        'Sheriff',
        'Fire',
        'EMS'
    },
    
    -- Roles that WILL be synced regardless
    ForceSyncRoles = {
        'Civilian',
        'Member'
    }
}
```

## Configuration Options

### Sync Settings

```lua
Config.Sync = {
    OnCharacterLoad = true,      -- Sync when character loads
    OnCharacterCreate = true,    -- Sync when character is created
    OnCharacterUpdate = true,    -- Sync on character updates
    OnCharacterDelete = true,    -- Delete from CAD when deleted
    SyncVehicles = true,         -- Sync vehicle purchases
    SyncVehicleStatus = true,    -- Sync stolen status
    LocationUpdateInterval = 30,  -- Seconds (0 to disable)
    LocationOnDutyOnly = true    -- Only send location if on-duty
}
```

### 911 Call Settings

```lua
Config.Calls = {
    Enabled = true,
    Command = '911',
    AlternateCommand = 'call911',
    SendCoordinates = true,
    SendPostal = true,
    Cooldown = 30,
    AllowAnonymous = true,
    AnonymousCommand = '911anon',
    NotifyOnSuccess = true
}
```

### NPC Reports (Automated)

```lua
Config.NPCReports = {
    Enabled = true,
    
    Gunshots = {
        Enabled = true,
        Cooldown = 60,
        Radius = 200.0
    },
    
    VehicleTheft = {
        Enabled = true,
        Cooldown = 120
    },
    
    Fights = {
        Enabled = true,
        Cooldown = 60
    }
}
```

## Commands

### Player Commands

| Command | Description |
|---------|-------------|
| `/911 [message]` | Make an emergency 911 call |
| `/call911 [message]` | Alternate 911 command |
| `/911anon [message]` | Anonymous 911 call |
| `/reportstolen [description]` | Report current vehicle as stolen |
| `/panic` | Emergency panic button (LEO/EMS) |

### Admin Commands

| Command | Description |
|---------|-------------|
| `/cadsync [playerid]` | Force sync a player to CAD |
| `/cadsyncall` | Sync all online players |
| `/cadstatus` | Check CAD connection status |
| `/cadlookup [id/plate]` | Lookup civilian or vehicle |
| `/cadclearcache` | Clear Discord role cache |

## Exports

### Server-side

```lua
-- Manually sync a player
exports['cdecad-sync']:SyncCharacter(source)

-- Send a 911 call
exports['cdecad-sync']:Send911Call({
    callType = 'Emergency',
    location = 'Main Street',
    callerName = 'John Doe',
    coords = { x = 0, y = 0, z = 0 }
})

-- Get synced civilian CAD ID
local cadId = exports['cdecad-sync']:GetSyncedCivilianId(citizenid)

-- Force full sync
exports['cdecad-sync']:ForceSync(source)
```

### Client-side

```lua
-- Get current location info
local location = exports['cdecad-sync']:GetLocationInfo()
-- Returns: { coords, street, zone, postal }

-- Get current vehicle info
local vehicle = exports['cdecad-sync']:GetCurrentVehicle()
-- Returns: { vehicle, plate, model, color }
```

## Callbacks

```lua
-- Lookup civilian
local civilian = lib.callback.await('cdecad-sync:server:lookupCivilian', false, citizenid)

-- Lookup vehicle
local vehicle = lib.callback.await('cdecad-sync:server:lookupVehicle', false, plate)
```

## Integration with Other Resources

### Vehicle Shop Integration

The resource listens for `qbx_vehicleshop:client:vehiclePurchased` events. If you use a different vehicle shop, trigger:

```lua
-- From your vehicle shop resource
TriggerEvent('cdecad-sync:client:registerVehicle', {
    plate = 'ABC123',
    model = 'Sultan',
    make = 'Karin',
    year = 2024,
    color = 'Red'
})
```

### Custom 911 Calls

```lua
-- From any resource
TriggerServerEvent('cdecad-sync:server:911call', {
    callType = 'Custom Emergency',
    location = 'Grove Street',
    coords = { x = 0, y = 0, z = 0 },
    postal = '123',
    anonymous = false
})
```

## Troubleshooting

### CAD Connection Issues

1. Check your `Config.API_URL` - ensure no trailing slash
2. Verify your `Config.API_KEY` matches your CDECAD settings
3. Run `/cadstatus` to check connection
4. Check server console for error messages

### Characters Not Syncing

1. Ensure `Config.Sync.OnCharacterLoad` is `true`
2. Check Discord role settings if using role filtering
3. Run `/cadsync` to manually sync
4. Check console for API errors

### Discord Roles Not Working

1. Ensure Badger_Discord_API is running
2. Verify bot has proper permissions in Discord
3. Run `/cadclearcache` to clear role cache
4. Check that role names match exactly (case-sensitive)

## API Endpoints Used

This resource communicates with the following CDECAD endpoints:

- `POST /api/civilian` - Create civilian
- `PUT /api/civilian/:id` - Update civilian
- `DELETE /api/civilian/:id` - Delete civilian
- `GET /api/civilian/fivem-civilian/:id` - Lookup civilian
- `GET /api/civilian/fivem-vehicle/:plate` - Lookup vehicle
- `POST /api/civilian/fivem-register-vehicle` - Register vehicle
- `PUT /api/civilian/vehicle/:id/stolen` - Report stolen
- `POST /api/civilian/fivem-911-call` - Send 911 call

## Support

For issues with this resource, please create an issue on the repository.

For CDECAD issues, please contact your CDECAD administrator.

## License

This resource is provided as-is for use with CDECAD.
