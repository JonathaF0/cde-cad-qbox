--[[
    CDECAD Sync - Main Server Script for QBox
    Handles QBox events and syncs data to CDECAD
]]

-- Store synced civilians (citizenid -> CAD civilian ID)
local syncedCivilians = {}
local syncedVehicles = {}

-- =============================================================================
-- QBOX HELPER FUNCTIONS
-- =============================================================================

local function GetPlayer(source)
    return exports.qbx_core:GetPlayer(source)
end

local function GetPlayerByCitizenId(citizenid)
    return exports.qbx_core:GetPlayerByCitizenId(citizenid)
end

local function GetAllPlayers()
    return exports.qbx_core:GetQBPlayers()
end

-- =============================================================================
-- CHARACTER SYNC FUNCTIONS
-- =============================================================================

-- Build civilian data from player data (works for both frameworks)
local function BuildCivilianData(source, playerData)
    local charinfo = playerData.charinfo
    
    -- Get the player's Discord ID
    local discordId = nil
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, 'discord:') then
            discordId = id:gsub('discord:', '')
            break
        end
    end
    
    return {
        firstName = charinfo.firstname,
        lastName = charinfo.lastname,
        dateOfBirth = charinfo.birthdate,
        gender = Utils.ConvertGender(charinfo.gender),
        nationality = charinfo.nationality or 'American',
        phone = charinfo.phone,
        citizenid = playerData.citizenid,
        ssn = playerData.citizenid, -- Use citizenid as SSN
        discordId = discordId,      -- Link to CAD account
        -- Additional metadata if available
        address = playerData.metadata and playerData.metadata.address,
    }
end

-- Sync a character to CDECAD
local function SyncCharacter(source, playerData, isNew)
    print('[CDECAD-SYNC] SyncCharacter called for source: ' .. tostring(source))
    
    if not playerData then
        print('[CDECAD-SYNC] ERROR: No player data to sync')
        return
    end
    
    print('[CDECAD-SYNC] PlayerData citizenid: ' .. tostring(playerData.citizenid))
    print('[CDECAD-SYNC] PlayerData charinfo: ' .. json.encode(playerData.charinfo or {}))
    
    -- Check Discord role eligibility
    if not CDECAD_Discord.ShouldSyncPlayer(source) then
        print('[CDECAD-SYNC] Player has excluded Discord role, skipping sync')
        return
    end
    
    local civilianData = BuildCivilianData(source, playerData)
    local citizenid = playerData.citizenid
    
    print('[CDECAD-SYNC] Syncing character: ' .. tostring(citizenid) .. ' - ' .. tostring(civilianData.firstName) .. ' ' .. tostring(civilianData.lastName))
    print('[CDECAD-SYNC] Discord ID: ' .. tostring(civilianData.discordId))
    
    -- Check if already synced (we track by citizenid)
    if syncedCivilians[citizenid] and not isNew then
        print('[CDECAD-SYNC] Character already synced, updating...')
        -- Update existing civilian using citizenid (SSN in CAD)
        CDECAD_API.UpdateCivilian(citizenid, civilianData, function(success, data, statusCode)
            if success then
                print('[CDECAD-SYNC] Character updated successfully')
                if Config.Sync.OnCharacterUpdate then
                    TriggerClientEvent('cdecad-sync:client:notify', source, 'success', Config.Locale['sync_success'])
                end
            else
                print('[CDECAD-SYNC] Failed to update character: ' .. tostring(statusCode))
            end
        end)
    else
        print('[CDECAD-SYNC] Creating/syncing civilian in CAD...')
        -- Create new civilian (or update if exists - the endpoint handles both)
        CDECAD_API.CreateCivilian(civilianData, function(success, data, statusCode)
            print('[CDECAD-SYNC] CreateCivilian callback - success: ' .. tostring(success) .. ', statusCode: ' .. tostring(statusCode))
            if data then
                print('[CDECAD-SYNC] Response data: ' .. json.encode(data))
            end
            
            if success and data then
                -- Store that we've synced this character
                if data.civilian then
                    syncedCivilians[citizenid] = data.civilian._id
                elseif data._id then
                    syncedCivilians[citizenid] = data._id
                else
                    syncedCivilians[citizenid] = true
                end
                
                local action = data.action or 'synced'
                print('[CDECAD-SYNC] Character ' .. action .. ' successfully')
                TriggerClientEvent('cdecad-sync:client:notify', source, 'success', Config.Locale['sync_success'])
                
                -- Sync any existing vehicles
                if Config.Sync.SyncVehicles then
                    SyncPlayerVehicles(source, playerData)
                end
            else
                print('[CDECAD-SYNC] Failed to create character: ' .. tostring(statusCode))
                TriggerClientEvent('cdecad-sync:client:notify', source, 'error', Config.Locale['sync_failed'])
            end
        end)
    end
end

-- Sync player's vehicles
local function SyncPlayerVehicles(source, playerData)
    local citizenid = playerData.citizenid
    
    -- Get vehicles from database
    -- This depends on your vehicle system (qbx_vehicles, etc.)
    -- For now, we'll rely on the vehicle purchase event
    Utils.Debug('Vehicle sync placeholder for:', citizenid)
end

-- =============================================================================
-- QBCORE/QBOX EVENT HANDLERS
-- =============================================================================

-- Player loaded (selected character) - QBCore style event (works for both)
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    print('[CDECAD-SYNC] QBCore:Server:OnPlayerLoaded triggered for source: ' .. tostring(source))
    
    local Player = GetPlayer(source)
    
    if not Player then 
        print('[CDECAD-SYNC] ERROR: Could not get player for source: ' .. tostring(source))
        return 
    end
    
    print('[CDECAD-SYNC] Player found: ' .. tostring(Player.PlayerData.citizenid))
    
    if Config.Sync.OnCharacterLoad then
        -- Small delay to ensure everything is loaded
        SetTimeout(2000, function()
            local p = GetPlayer(source)
            if p then
                SyncCharacter(source, p.PlayerData, false)
            end
        end)
    end
end)

-- Also listen to the AddEventHandler version (non-networked)
AddEventHandler('QBCore:Server:OnPlayerLoaded', function()
    local source = source
    print('[CDECAD-SYNC] AddEventHandler OnPlayerLoaded triggered for source: ' .. tostring(source))
    
    local Player = GetPlayer(source)
    
    if not Player then 
        print('[CDECAD-SYNC] ERROR: Could not get player for source: ' .. tostring(source))
        return 
    end
    
    print('[CDECAD-SYNC] Player found: ' .. tostring(Player.PlayerData.citizenid))
    
    if Config.Sync.OnCharacterLoad then
        SetTimeout(2000, function()
            local p = GetPlayer(source)
            if p then
                SyncCharacter(source, p.PlayerData, false)
            end
        end)
    end
end)

-- Player unloaded (logged out)
AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    Utils.Debug('Player unloaded:', source)
    CDECAD_Discord.ClearCache(source)
end)

-- Character deleted (QBox specific)
RegisterNetEvent('qbx_core:server:deleteCharacter', function(citizenid)
    if not Config.Sync.OnCharacterDelete then return end
    
    Utils.Debug('Character deleted:', citizenid)
    
    if syncedCivilians[citizenid] then
        CDECAD_API.DeleteCivilian(syncedCivilians[citizenid], function(success)
            if success then
                Utils.Debug('Civilian deleted from CAD')
                syncedCivilians[citizenid] = nil
            end
        end)
    end
end)

-- Job update (works for both frameworks)
AddEventHandler('QBCore:Server:OnJobUpdate', function(source, job)
    Utils.Debug('Job update for:', source, job.name)
    
    -- If player changed to an "excluded" job, we might want to handle differently
    -- For now, civilians remain synced regardless of job
end)

-- =============================================================================
-- VEHICLE EVENT HANDLERS
-- =============================================================================

-- Vehicle purchased/registered
-- This event name depends on your vehicle shop resource
-- Common events: qb-vehicleshop:server:buyVehicle, qbx_vehicleshop:server:bought

RegisterNetEvent('cdecad-sync:server:registerVehicle', function(vehicleData)
    local source = source
    local Player = GetPlayer(source)
    
    if not Player or not Config.Sync.SyncVehicles then return end
    
    local citizenid = Player.PlayerData.citizenid
    
    Utils.Debug('Registering vehicle:', vehicleData.plate)
    
    local cadVehicleData = {
        plate = vehicleData.plate,
        ownerId = citizenid, -- Use citizenid for lookup
        make = vehicleData.make or vehicleData.brand,
        model = vehicleData.model,
        color = vehicleData.color,
        year = vehicleData.year or os.date('%Y')
    }
    
    CDECAD_API.RegisterVehicle(cadVehicleData, function(success, data)
        if success then
            Utils.Debug('Vehicle registered in CAD')
            syncedVehicles[vehicleData.plate] = data.vehicleId
            TriggerClientEvent('cdecad-sync:client:notify', source, 'success', Config.Locale['vehicle_registered'])
        else
            Utils.Debug('Failed to register vehicle in CAD')
        end
    end)
end)

-- Vehicle reported stolen
RegisterNetEvent('cdecad-sync:server:reportStolen', function(plate, description)
    local source = source
    local Player = GetPlayer(source)
    
    if not Player or not Config.Sync.SyncVehicleStatus then return end
    
    Utils.Debug('Reporting vehicle stolen:', plate)
    
    -- First get the vehicle from CAD
    CDECAD_API.GetVehicle(plate, function(success, vehicleData)
        if success and vehicleData then
            CDECAD_API.ReportVehicleStolen(vehicleData.id, true, description, function(stealSuccess)
                if stealSuccess then
                    TriggerClientEvent('cdecad-sync:client:notify', source, 'success', Config.Locale['vehicle_reported_stolen'])
                end
            end)
        end
    end)
end)

-- =============================================================================
-- 911 CALL HANDLER
-- =============================================================================

RegisterNetEvent('cdecad-sync:server:911call', function(callData)
    local source = source
    local Player = GetPlayer(source)
    
    if not Config.Calls.Enabled then return end
    
    -- Rate limiting
    local canCall, remaining = Utils.CheckRateLimit('911_' .. source, Config.Calls.Cooldown)
    if not canCall then
        TriggerClientEvent('cdecad-sync:client:notify', source, 'error', 
            Config.Locale['911_cooldown']:gsub('{time}', tostring(remaining)))
        return
    end
    
    local callerName = 'Anonymous'
    if Player and not callData.anonymous then
        local charinfo = Player.PlayerData.charinfo
        callerName = charinfo.firstname .. ' ' .. charinfo.lastname
    end
    
    local cadCallData = {
        callType = callData.callType or 'Emergency Call',
        location = callData.location or callData.street or 'Unknown',
        callerName = callerName,
        coords = callData.coords,
        x = callData.coords and callData.coords.x,
        y = callData.coords and callData.coords.y,
        z = callData.coords and callData.coords.z,
        postal = callData.postal,
        isAnonymous = callData.anonymous,
        isNPC = false,
        reportType = 'Player'
    }
    
    CDECAD_API.Send911Call(cadCallData, function(success, data)
        if success then
            Utils.Debug('911 call sent successfully')
            if Config.Calls.NotifyOnSuccess then
                TriggerClientEvent('cdecad-sync:client:notify', source, 'success', Config.Locale['911_sent'])
            end
        else
            Utils.Debug('Failed to send 911 call')
            TriggerClientEvent('cdecad-sync:client:notify', source, 'error', Config.Locale['cad_offline'])
        end
    end)
end)

-- =============================================================================
-- NPC REPORTS (Automated witness reports)
-- =============================================================================

RegisterNetEvent('cdecad-sync:server:npcReport', function(reportData)
    local source = source
    
    if not Config.NPCReports.Enabled then return end
    
    -- Rate limiting based on location
    local locationKey = 'npc_' .. reportData.reportType .. '_' .. 
        math.floor(reportData.coords.x / 100) .. '_' .. 
        math.floor(reportData.coords.y / 100)
    
    local cooldown = Config.NPCReports[reportData.reportType] and 
        Config.NPCReports[reportData.reportType].Cooldown or 60
    
    local canReport = Utils.CheckRateLimit(locationKey, cooldown)
    if not canReport then return end
    
    local cadCallData = {
        callType = reportData.callType or 'Suspicious Activity',
        location = reportData.location or reportData.street or 'Unknown',
        callerName = 'Anonymous Witness',
        coords = reportData.coords,
        x = reportData.coords.x,
        y = reportData.coords.y,
        z = reportData.coords.z,
        postal = reportData.postal,
        isAnonymous = true,
        isNPC = true,
        reportType = reportData.reportType or 'NPC'
    }
    
    CDECAD_API.Send911Call(cadCallData, function(success)
        if success then
            Utils.Debug('NPC report sent:', reportData.reportType)
        end
    end)
end)

-- =============================================================================
-- LOOKUP CALLBACKS
-- =============================================================================

-- Civilian lookup (for MDT integration)
lib.callback.register('cdecad-sync:server:lookupCivilian', function(source, citizenid)
    local result = nil
    local completed = false
    
    CDECAD_API.GetCivilianBySSN(citizenid, function(success, data)
        result = success and data or nil
        completed = true
    end)
    
    -- Wait for result
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- Vehicle lookup
lib.callback.register('cdecad-sync:server:lookupVehicle', function(source, plate)
    local result = nil
    local completed = false
    
    CDECAD_API.GetVehicle(plate, function(success, data)
        result = success and data or nil
        completed = true
    end)
    
    while not completed do
        Wait(10)
    end
    
    return result
end)

-- =============================================================================
-- EXPORTS
-- =============================================================================

-- Allow other resources to sync characters
exports('SyncCharacter', function(source)
    local Player = GetPlayer(source)
    if Player then
        SyncCharacter(source, Player.PlayerData, false)
        return true
    end
    return false
end)

-- Allow other resources to send 911 calls
exports('Send911Call', function(callData)
    CDECAD_API.Send911Call(callData, function(success)
        Utils.Debug('Export 911 call result:', success)
    end)
end)

-- Get synced civilian ID
exports('GetSyncedCivilianId', function(citizenid)
    return syncedCivilians[citizenid]
end)

-- Manual sync trigger
exports('ForceSync', function(source)
    local Player = GetPlayer(source)
    if Player then
        SyncCharacter(source, Player.PlayerData, true)
        return true
    end
    return false
end)

-- Get current framework
exports('GetFramework', function()
    return Framework
end)

-- =============================================================================
-- STARTUP
-- =============================================================================

CreateThread(function()
    -- Wait for other resources
    Wait(5000)
    
    print('[CDECAD-SYNC] Using QBox framework')
    
    -- Health check
    CDECAD_API.HealthCheck(function(online, statusCode)
        if online then
            print('[CDECAD-SYNC] Connected to CDECAD API')
        else
            print('[CDECAD-SYNC] WARNING: Unable to connect to CDECAD API (Status: ' .. tostring(statusCode) .. ')')
        end
    end)
    
    -- Sync any already-online players
    if Config.Sync.OnCharacterLoad then
        local players = GetAllPlayers()
        for _, player in pairs(players) do
            if player and player.PlayerData then
                SyncCharacter(player.PlayerData.source, player.PlayerData, false)
            end
        end
    end
end)

print('[CDECAD-SYNC] Server script loaded (QBox)')
