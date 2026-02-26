--[[
    CDECAD Sync - Server Commands
    Admin and player commands for CAD integration
]]

-- =============================================================================
-- PLAYER COMMANDS
-- =============================================================================

-- 911 Emergency Call
if Config.Calls.Enabled then
    RegisterCommand(Config.Calls.Command, function(source, args)
        if source == 0 then return end -- Console
        
        local message = table.concat(args, ' ')
        if message == '' then
            TriggerClientEvent('cdecad-sync:client:notify', source, 'error', Config.Locale['911_invalid'])
            return
        end
        
        TriggerClientEvent('cdecad-sync:client:prepare911', source, message, false)
    end, false)
    
    -- Alternate command
    if Config.Calls.AlternateCommand then
        RegisterCommand(Config.Calls.AlternateCommand, function(source, args)
            if source == 0 then return end
            
            local message = table.concat(args, ' ')
            if message == '' then
                TriggerClientEvent('cdecad-sync:client:notify', source, 'error', Config.Locale['911_invalid'])
                return
            end
            
            TriggerClientEvent('cdecad-sync:client:prepare911', source, message, false)
        end, false)
    end
    
    -- Anonymous 911
    if Config.Calls.AllowAnonymous then
        RegisterCommand(Config.Calls.AnonymousCommand, function(source, args)
            if source == 0 then return end
            
            local message = table.concat(args, ' ')
            if message == '' then
                TriggerClientEvent('cdecad-sync:client:notify', source, 'error', Config.Locale['911_invalid'])
                return
            end
            
            TriggerClientEvent('cdecad-sync:client:prepare911', source, message, true)
        end, false)
    end
end

-- Report stolen vehicle
RegisterCommand('reportstolen', function(source, args)
    if source == 0 then return end
    
    local Player = exports.qbx_core:GetPlayer(source)
    if not Player then return end
    
    local description = table.concat(args, ' ')
    
    TriggerClientEvent('cdecad-sync:client:reportStolenVehicle', source, description)
end, false)

-- =============================================================================
-- ADMIN COMMANDS
-- =============================================================================

-- Force sync a player's character
RegisterCommand('cadsync', function(source, args)
    local targetSource = source
    
    -- If admin with target ID
    if args[1] then
        targetSource = tonumber(args[1])
    end
    
    if targetSource == 0 then
        print('[CDECAD-SYNC] Cannot sync console')
        return
    end
    
    local Player = exports.qbx_core:GetPlayer(targetSource)
    if not Player then
        if source > 0 then
            TriggerClientEvent('cdecad-sync:client:notify', source, 'error', 'Player not found')
        else
            print('[CDECAD-SYNC] Player not found: ' .. tostring(targetSource))
        end
        return
    end
    
    exports['cdecad-sync']:ForceSync(targetSource)
    
    if source > 0 then
        TriggerClientEvent('cdecad-sync:client:notify', source, 'success', 'Syncing player to CAD...')
    else
        print('[CDECAD-SYNC] Syncing player ' .. targetSource .. ' to CAD')
    end
end, true) -- Restricted to admins

-- Check CAD connection status
RegisterCommand('cadstatus', function(source, args)
    CDECAD_API.HealthCheck(function(online, statusCode)
        local message = online 
            and 'CAD is online (Status: ' .. tostring(statusCode) .. ')'
            or 'CAD is offline (Status: ' .. tostring(statusCode) .. ')'
        
        if source > 0 then
            TriggerClientEvent('cdecad-sync:client:notify', source, online and 'success' or 'error', message)
        else
            print('[CDECAD-SYNC] ' .. message)
        end
    end)
end, true)

-- Lookup civilian in CAD
RegisterCommand('cadlookup', function(source, args)
    if not args[1] then
        if source > 0 then
            TriggerClientEvent('cdecad-sync:client:notify', source, 'error', 'Usage: /cadlookup [citizenid or plate]')
        else
            print('[CDECAD-SYNC] Usage: /cadlookup [citizenid or plate]')
        end
        return
    end
    
    local searchTerm = args[1]:upper()
    
    -- Try vehicle lookup first (if it looks like a plate)
    if #searchTerm <= 8 then
        CDECAD_API.GetVehicle(searchTerm, function(success, data)
            if success and data then
                local info = string.format('Vehicle: %s %s %s | Owner: %s | Stolen: %s',
                    data.year or '?',
                    data.color or '?',
                    data.model or '?',
                    data.owner or 'Unknown',
                    data.stolen and 'YES' or 'No'
                )
                
                if source > 0 then
                    TriggerClientEvent('cdecad-sync:client:notify', source, 'info', info)
                else
                    print('[CDECAD-SYNC] ' .. info)
                end
            else
                -- Try civilian lookup
                CDECAD_API.GetCivilianBySSN(searchTerm, function(civSuccess, civData)
                    if civSuccess and civData then
                        local info = string.format('Civilian: %s | DOB: %s | Phone: %s',
                            civData.name or 'Unknown',
                            civData.dob or '?',
                            civData.phone or '?'
                        )
                        
                        if source > 0 then
                            TriggerClientEvent('cdecad-sync:client:notify', source, 'info', info)
                        else
                            print('[CDECAD-SYNC] ' .. info)
                        end
                    else
                        if source > 0 then
                            TriggerClientEvent('cdecad-sync:client:notify', source, 'error', 'No records found')
                        else
                            print('[CDECAD-SYNC] No records found for: ' .. searchTerm)
                        end
                    end
                end)
            end
        end)
    end
end, true)

-- Sync all online players
RegisterCommand('cadsyncall', function(source, args)
    local players = exports.qbx_core:GetQBPlayers()
    local count = 0
    
    for _, player in pairs(players) do
        if player and player.PlayerData then
            exports['cdecad-sync']:ForceSync(player.PlayerData.source)
            count = count + 1
        end
    end
    
    local message = 'Syncing ' .. count .. ' players to CAD...'
    
    if source > 0 then
        TriggerClientEvent('cdecad-sync:client:notify', source, 'success', message)
    else
        print('[CDECAD-SYNC] ' .. message)
    end
end, true)

-- Clear Discord role cache
RegisterCommand('cadclearcache', function(source, args)
    CDECAD_Discord.ClearAllCache()
    
    local message = 'Discord role cache cleared'
    
    if source > 0 then
        TriggerClientEvent('cdecad-sync:client:notify', source, 'success', message)
    else
        print('[CDECAD-SYNC] ' .. message)
    end
end, true)

-- =============================================================================
-- SUGGESTIONS (Tab completion)
-- =============================================================================

if Config.Calls.Enabled then
    TriggerEvent('chat:addSuggestion', '/' .. Config.Calls.Command, '911 Emergency Call', {
        { name = 'message', help = 'Describe your emergency' }
    })
    
    if Config.Calls.AllowAnonymous then
        TriggerEvent('chat:addSuggestion', '/' .. Config.Calls.AnonymousCommand, 'Anonymous 911 Call', {
            { name = 'message', help = 'Describe your emergency (anonymous)' }
        })
    end
end

TriggerEvent('chat:addSuggestion', '/reportstolen', 'Report your vehicle as stolen', {
    { name = 'description', help = 'Where/when was it stolen?' }
})

print('[CDECAD-SYNC] Commands registered')
