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
-- NOTIFICATIONS
-- =============================================================================

RegisterNetEvent('cdecad-sync:client:notify', function(type, message)
    if Config.Notifications.UseOxLib then
        lib.notify({
            title = 'CDECAD',
            description = message,
            type = type,
            duration = Config.Notifications.Duration,
            position = Config.Notifications.Position
        })
    else
        -- Fallback to chat
        TriggerEvent('chat:addMessage', {
            color = type == 'success' and {0, 255, 0} or type == 'error' and {255, 0, 0} or {255, 255, 255},
            args = {'[CDECAD]', message}
        })
    end
end)

-- =============================================================================
-- POSTAL CODE FUNCTIONS
-- =============================================================================

-- Get postal code from configured resource
function GetPostalCode()
    -- Check if postal is enabled
    if not Config.Postal or not Config.Postal.Enabled then
        return nil
    end
    
    local postal = nil
    local resource = Config.Postal.Resource or 'nearest-postal'
    
    -- Try to get postal based on configured resource
    if resource == 'nearest-postal' then
        -- Standard nearest-postal export
        local success, result = pcall(function()
            return exports['nearest-postal']:getPostal()
        end)
        if success and result then
            postal = result
        end
    elseif resource == 'npostal' then
        -- Custom npostal export (requires modification to nearest-postal)
        local success, result = pcall(function()
            return exports.npostal:npostal()
        end)
        if success and result then
            postal = result
        end
    elseif resource == 'qb-postal' then
        -- QBCore postal
        local success, result = pcall(function()
            return exports['qb-postal']:getPostal()
        end)
        if success and result then
            postal = result
        end
    elseif resource == 'custom' then
        -- Custom export
        local exportName = Config.Postal.CustomExport
        local funcName = Config.Postal.CustomFunction or 'getPostal'
        
        if exportName then
            local success, result = pcall(function()
                return exports[exportName][funcName]()
            end)
            if success and result then
                postal = result
            end
        end
    end
    
    -- Return postal or fallback
    if postal then
        Utils.Debug('Got postal code:', postal)
        return tostring(postal)
    else
        Utils.Debug('No postal code available')
        return Config.Postal.FallbackText
    end
end

-- =============================================================================
-- LOCATION HELPERS
-- =============================================================================

-- Get current street name
function GetCurrentStreetName()
    local coords = GetEntityCoords(PlayerPedId())
    local streetHash, crossingHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local crossingName = GetStreetNameFromHashKey(crossingHash)
    
    if crossingName and crossingName ~= '' then
        return streetName .. ' & ' .. crossingName
    end
    return streetName
end

-- Get current zone name
function GetCurrentZoneName()
    local coords = GetEntityCoords(PlayerPedId())
    return GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))
end

-- Format location string with postal
function FormatLocationString(street, zone, postal)
    local format
    
    if postal and Config.Postal.IncludeInLocation then
        format = Config.Postal.LocationFormat or '{street}, {zone} (Postal: {postal})'
        format = format:gsub('{street}', street or 'Unknown')
        format = format:gsub('{zone}', zone or 'Unknown')
        format = format:gsub('{postal}', postal)
    else
        format = Config.Postal.LocationFormatNoPostal or '{street}, {zone}'
        format = format:gsub('{street}', street or 'Unknown')
        format = format:gsub('{zone}', zone or 'Unknown')
    end
    
    return format
end

-- Get location info for 911 calls
function GetLocationInfo()
    local coords = GetEntityCoords(PlayerPedId())
    local street = GetCurrentStreetName()
    local zone = GetCurrentZoneName()
    local postal = GetPostalCode()
    
    -- Format the full location string
    local locationString = FormatLocationString(street, zone, postal)
    
    return {
        street = street,
        zone = zone,
        postal = postal,
        location = locationString,
        coords = coords,
        x = coords.x,
        y = coords.y,
        z = coords.z
    }
end

-- Get current vehicle info
function GetCurrentVehicle()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    
    if vehicle == 0 then
        return nil
    end
    
    local plate = GetVehicleNumberPlateText(vehicle)
    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    
    return {
        vehicle = vehicle,
        plate = plate:gsub('%s+', ''),
        model = displayName,
        class = GetVehicleClass(vehicle)
    }
end

-- =============================================================================
-- 911 CALL PREPARATION
-- =============================================================================

-- Prepare 911 call data
function Prepare911CallData(callType, anonymous)
    local location = GetLocationInfo()
    
    return {
        callType = callType,
        location = location.location,  -- Use formatted location string
        street = location.street,
        zone = location.zone,
        postal = location.postal,
        coords = location.coords,
        anonymous = anonymous or false
    }
end

-- =============================================================================
-- EXPORTS
-- =============================================================================

exports('GetLocationInfo', GetLocationInfo)
exports('GetCurrentVehicle', GetCurrentVehicle)
exports('Prepare911CallData', Prepare911CallData)
exports('GetPostalCode', GetPostalCode)

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

CreateThread(function()
    -- Wait for QBox player to be fully loaded
    while not LocalPlayer.state.isLoggedIn do
        Wait(500)
    end
    
    UpdatePlayerData()
    
    -- Test postal on load
    if Config.Postal and Config.Postal.Enabled then
        Wait(2000) -- Give postal resource time to initialize
        local testPostal = GetPostalCode()
        if testPostal then
            Utils.Debug('Postal integration working. Current postal:', testPostal)
        else
            Utils.Debug('Postal integration enabled but no postal returned. Check Config.Postal.Resource setting.')
        end
    end
    
    Utils.Debug('Client: Initialized (QBox)')
end)

print('[CDECAD-SYNC] Client script loaded (QBox)')
