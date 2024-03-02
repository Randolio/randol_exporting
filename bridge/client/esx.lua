if GetResourceState('es_extended') ~= 'started' then return end

local ESX = exports['es_extended']:getSharedObject()

RegisterNetEvent('esx:playerLoaded', function(xPlayer)
    ESX.PlayerLoaded = true
    TriggerEvent('randol_exports:onLoggedIn')
end)

RegisterNetEvent('esx:onPlayerLogout', function()
    ESX.PlayerLoaded = false
    TriggerEvent('randol_exports:onLogout')
end)

function handleVehicleKeys(veh)
    local plate = GetVehicleNumberPlateText(veh)
    -- handle your keys here
end

function hasPlyLoaded()
    return ESX.PlayerLoaded
end

function DoNotification(text, nType)
    ESX.ShowNotification(text, nType)
end
