--[[
    CDECAD Sync Configuration for QBox
    Configure your CDECAD API connection and sync settings
]]

Config = {}

-- =============================================================================
-- API CONFIGURATION
-- =============================================================================

-- Your CDECAD API URL (no trailing slash)
Config.API_URL = 'https://your-cdecad-instance.com/api'

-- Your CDECAD API Key (get this from your CDECAD admin panel)
Config.API_KEY = 'fivem-cad-911-key-2024'

-- Your Community ID (Discord Guild ID that matches your CDECAD community)
Config.COMMUNITY_ID = '1234567890123456789'

-- =============================================================================
-- SYNC SETTINGS
-- =============================================================================

Config.Sync = {
    -- Automatically sync character data when player loads
    OnCharacterLoad = true,
    
    -- Automatically sync when character is created
    OnCharacterCreate = true,
    
    -- Sync character updates (appearance, metadata changes)
    OnCharacterUpdate = true,
    
    -- Delete civilian from CAD when character is deleted
    OnCharacterDelete = true,
    
    -- Sync vehicles when purchased/registered
    SyncVehicles = true,
    
    -- Sync vehicle status changes (stolen, etc.)
    SyncVehicleStatus = true,
    
    -- How often to send location updates (in seconds, 0 to disable)
    LocationUpdateInterval = 30,
    
    -- Only send location for on-duty players
    LocationOnDutyOnly = true
}

-- =============================================================================
-- DISCORD ROLE INTEGRATION (Optional)
-- =============================================================================

Config.Discord = {
    -- Enable Discord role checking
    Enabled = true,
    
    -- Use Badger_Discord_API (recommended)
    UseBadgerAPI = true,
    
    -- If not using Badger API, set your Discord Bot Token here
    BotToken = '',
    
    -- Roles that should NOT be synced to civilian CAD
    -- (LEO, Fire, EMS characters are usually handled separately)
    ExcludedRoles = {
        'Police',
        'Sheriff',
        'State Police',
        'Fire',
        'EMS',
        'Dispatch'
    },
    
    -- Role IDs that should NOT be synced (add your actual role IDs)
    ExcludedRoleIds = {
        -- '1234567890123456789', -- Example Police Role ID
        -- '9876543210987654321', -- Example EMS Role ID
    },
    
    -- If player has any of these roles, they WILL be synced regardless
    -- Useful for "Civilian" role that LEO players might also have
    ForceSyncRoles = {
        'Civilian',
        'Member'
    }
}

-- =============================================================================
-- 911 CALL SETTINGS
-- =============================================================================

Config.Calls = {
    -- Enable 911 command
    Enabled = true,
    
    -- Command name for 911 calls
    Command = '911',
    
    -- Also register as /call911
    AlternateCommand = 'call911',
    
    -- Send player coordinates with 911 calls
    SendCoordinates = true,
    
    -- Send postal code (requires postal resource)
    SendPostal = true,
    
    -- Postal export name (common options: 'nearest-postal', 'esx_postal')
    PostalExport = 'nearest-postal',
    
    -- Cooldown between 911 calls (in seconds)
    Cooldown = 30,
    
    -- Allow anonymous 911 calls
    AllowAnonymous = true,
    
    -- Anonymous call command
    AnonymousCommand = '911anon',
    
    -- Notify player when call is received
    NotifyOnSuccess = true,
    
    -- Notify player when call is assigned to unit
    NotifyOnAssignment = true
}

-- =============================================================================
-- NPC REPORTS (Automated crime reports)
-- =============================================================================

Config.NPCReports = {
    -- Enable NPC witness reports
    Enabled = true,
    
    -- Report gunshots heard
    Gunshots = {
        Enabled = true,
        Cooldown = 60, -- Seconds between reports from same area
        Radius = 200.0 -- How close NPCs need to be to "hear" shots
    },
    
    -- Report vehicle theft
    VehicleTheft = {
        Enabled = true,
        Cooldown = 120
    },
    
    -- Report fights/assaults
    Fights = {
        Enabled = true,
        Cooldown = 60
    },
    
    -- Report speeding (requires speed camera setup)
    SpeedCamera = {
        Enabled = false,
        SpeedLimit = 80 -- mph over this triggers report
    }
}

-- =============================================================================
-- FIELD MAPPING
-- =============================================================================

-- Map QBox player data fields to CDECAD civilian fields
Config.FieldMapping = {
    -- QBox charinfo -> CDECAD Civilian
    firstName = 'firstname',      -- charinfo.firstname
    lastName = 'lastname',        -- charinfo.lastname
    dateOfBirth = 'birthdate',    -- charinfo.birthdate
    gender = 'gender',            -- charinfo.gender (0 = male, 1 = female)
    nationality = 'nationality',  -- charinfo.nationality
    phone = 'phone',              -- charinfo.phone
    
    -- Additional fields from metadata or other sources
    -- These will be populated if available
    ssn = 'citizenid',            -- Use citizenid as SSN
}

-- Gender mapping (QBox uses 0/1, CAD might use strings)
Config.GenderMapping = {
    [0] = 'Male',
    [1] = 'Female'
}

-- =============================================================================
-- NOTIFICATIONS
-- =============================================================================

Config.Notifications = {
    -- Use ox_lib notifications
    UseOxLib = true,
    
    -- Notification duration (ms)
    Duration = 5000,
    
    -- Notification position
    Position = 'top-right'
}

-- =============================================================================
-- DEBUG SETTINGS
-- =============================================================================

Config.Debug = {
    -- Enable debug prints
    Enabled = false,
    
    -- Log all API requests
    LogRequests = false,
    
    -- Log all API responses
    LogResponses = false
}

-- =============================================================================
-- LOCALE / MESSAGES
-- =============================================================================

Config.Locale = {
    ['911_sent'] = '911 call sent! Units have been dispatched.',
    ['911_cooldown'] = 'Please wait before making another 911 call.',
    ['911_invalid'] = 'Usage: /911 [message]',
    ['sync_success'] = 'Character synced to CAD.',
    ['sync_failed'] = 'Failed to sync character to CAD.',
    ['vehicle_registered'] = 'Vehicle registered in CAD.',
    ['vehicle_reported_stolen'] = 'Vehicle reported as stolen.',
    ['not_authorized'] = 'You are not authorized for this action.',
    ['cad_offline'] = 'CAD system is currently offline.'
}
