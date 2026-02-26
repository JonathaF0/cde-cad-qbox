--[[
    CDECAD Sync - Main Client Script for QBox
    Handles client-side notifications and data gathering
]]

local PlayerData = {}
local isLoggedIn = false

-- =============================================================================
-- PLAYER DATA MANAGEMENT
-- =============================================================================

-- Get player data from QBox
local function GetPlayerData()
    return exports.qbx_core:GetPlayerData()
end

-- Update local player data cache
local function UpdatePlayerData()
    PlayerData = GetPlayerData() or {}
    isLoggedIn = PlayerData.citizenid ~= nil
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

-- Player loaded
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    UpdatePlayerData()
    Utils.Debug('Client: Player loaded')
end)

-- Player unloaded (QBox specific)
RegisterNetEvent('qbx_core:client:playerLoggedOut', function()
    PlayerData = {}
    isLoggedIn = false
    Utils.Debug('Client: Player logged out')
end)

-- Player data updated
RegisterNetEvent('QBCore:Player:SetPlayerData', function(data)
    PlayerData = data
end)

-- =============================================================================
-- NOTIFICATION HANDLER
-- =============================================================================

RegisterNetEvent('cdecad-sync:client:notify', function(type, message)
    if Config.Notifications.UseOxLib then
        lib.notify({
            title = 'CAD System',
            description = message,
            type = type,
            duration = Config.Notifications.Duration,
            position = Config.Notifications.Position
        })
    else
        -- Fallback to QBox notification
        exports.qbx_core:Notify(message, type, Config.Notifications.Duration)
    end
end)

-- =============================================================================
-- LOCATION HELPERS
-- =============================================================================

-- Get current street name
local function GetStreetName()
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    if crossingName and crossingName ~= '' then
        return streetName .. ' / ' .. crossingName
    end
    
    return streetName
end

-- Get current zone name
local function GetZoneName()
    local coords = GetEntityCoords(PlayerPedId())
    return GetNameOfZone(coords.x, coords.y, coords.z)
end

-- Get postal code (requires postal resource)
local function GetPostal()
    if not Config.Calls.SendPostal then return nil end
    
    -- Try different postal exports
    if GetResourceState('nearest-postal') == 'started' then
        local postal = exports['nearest-postal']:getPostal()
        return postal and tostring(postal) or nil
    elseif GetResourceState('postal') == 'started' then
        local postal = exports['postal']:getPostal()
        return postal and tostring(postal) or nil
    end
    
    return nil
end

-- Get player's current vehicle info
local function GetCurrentVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then return nil end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    
    return {
        vehicle = vehicle,
        plate = plate and plate:gsub('%s+', '') or 'UNKNOWN',
        model = displayName or 'Unknown',
        color = 'Unknown' -- Could be expanded to get actual color
    }
end

-- =============================================================================
-- 911 CALL SYSTEM
-- =============================================================================

-- Prepare 911 call with location data
RegisterNetEvent('cdecad-sync:client:prepare911', function(message, anonymous)
    if not isLoggedIn then return end
    
    local coords = GetEntityCoords(PlayerPedId())
    local street = GetStreetName()
    local zone = GetZoneName()
    local postal = GetPostal()
    
    local location = street
    if zone and zone ~= '' then
        location = location .. ', ' .. zone
    end
    
    local callData = {
        callType = 'Emergency Call',
        location = location,
        message = message,
        anonymous = anonymous,
        coords = {
            x = coords.x,
            y = coords.y,
            z = coords.z
        },
        street = street,
        zone = zone,
        postal = postal
    }
    
    -- Determine call type from message
    local lowerMessage = message:lower()
    
    if lowerMessage:find('shot') or lowerMessage:find('gun') or lowerMessage:find('shoot') then
        callData.callType = 'Shots Fired'
    elseif lowerMessage:find('fight') or lowerMessage:find('assault') then
        callData.callType = 'Assault'
    elseif lowerMessage:find('robbery') or lowerMessage:find('rob') then
        callData.callType = 'Robbery'
    elseif lowerMessage:find('accident') or lowerMessage:find('crash') then
        callData.callType = 'Traffic Accident'
    elseif lowerMessage:find('fire') then
        callData.callType = 'Fire'
    elseif lowerMessage:find('medical') or lowerMessage:find('ambulance') or lowerMessage:find('injured') then
        callData.callType = 'Medical Emergency'
    elseif lowerMessage:find('stolen') then
        callData.callType = 'Stolen Vehicle'
    elseif lowerMessage:find('pursuit') or lowerMessage:find('chase') then
        callData.callType = 'Pursuit'
    end
    
    -- Add message to location for more detail
    callData.location = callData.location .. ' - ' .. message
    
    TriggerServerEvent('cdecad-sync:server:911call', callData)
end)

-- =============================================================================
-- VEHICLE REPORTING
-- =============================================================================

-- Report current vehicle as stolen
RegisterNetEvent('cdecad-sync:client:reportStolenVehicle', function(description)
    local vehicleInfo = GetCurrentVehicle()
    
    if not vehicleInfo then
        lib.notify({
            title = 'CAD System',
            description = 'You are not in a vehicle',
            type = 'error'
        })
        return
    end
    
    local coords = GetEntityCoords(PlayerPedId())
    local street = GetStreetName()
    
    TriggerServerEvent('cdecad-sync:server:reportStolen', vehicleInfo.plate, description or street)
end)

-- =============================================================================
-- VEHICLE REGISTRATION SYNC
-- =============================================================================

-- Hook into vehicle purchase events
-- This depends on your vehicle shop resource

-- For qbx_vehicleshop
RegisterNetEvent('qbx_vehicleshop:client:vehiclePurchased', function(vehicleData)
    if not Config.Sync.SyncVehicles then return end
    
    Wait(2000) -- Wait for server to process
    
    local vehicle = GetCurrentVehicle()
    if vehicle then
        TriggerServerEvent('cdecad-sync:server:registerVehicle', {
            plate = vehicle.plate,
            model = vehicle.model,
            make = vehicleData.brand or 'Unknown',
            year = vehicleData.year or os.date('%Y'),
            color = vehicle.color
        })
    end
end)

-- Generic vehicle registration (can be called by other resources)
RegisterNetEvent('cdecad-sync:client:registerVehicle', function(vehicleData)
    if not Config.Sync.SyncVehicles then return end
    TriggerServerEvent('cdecad-sync:server:registerVehicle', vehicleData)
end)

-- =============================================================================
-- LOCATION UPDATES (Optional real-time tracking)
-- =============================================================================

if Config.Sync.LocationUpdateInterval > 0 then
    CreateThread(function()
        while true do
            Wait(Config.Sync.LocationUpdateInterval * 1000)
            
            if isLoggedIn then
                -- Check if on-duty requirement
                if Config.Sync.LocationOnDutyOnly then
                    local job = PlayerData.job
                    if not job or not job.onduty then
                        goto continue
                    end
                end
                
                local coords = GetEntityCoords(PlayerPedId())
                local street = GetStreetName()
                
                TriggerServerEvent('cdecad-sync:server:locationUpdate', {
                    coords = { x = coords.x, y = coords.y, z = coords.z },
                    street = street,
                    heading = GetEntityHeading(PlayerPedId())
                })
            end
            
            ::continue::
        end
    end)
end

-- =============================================================================
-- EXPORTS
-- =============================================================================

-- Get current location info
exports('GetLocationInfo', function()
    local coords = GetEntityCoords(PlayerPedId())
    return {
        coords = coords,
        street = GetStreetName(),
        zone = GetZoneName(),
        postal = GetPostal()
    }
end)

-- Get current vehicle info
exports('GetCurrentVehicle', GetCurrentVehicle)

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

CreateThread(function()
    -- Wait for QBox player to be fully loaded
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    
    UpdatePlayerData()
    Utils.Debug('Client: Initialized (QBox)')
end)

print('[CDECAD-SYNC] Client script loaded (QBox)')
