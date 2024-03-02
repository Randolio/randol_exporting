local Config = lib.require('shared')
local Server = lib.require('sv_config')
local activePlys = {}
local cachedPlayers = {}

local function spawnExportVehicle(source, model)
    local vehicle = CreateVehicleServerSetter(joaat(model), 'automobile', Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, Config.VehicleSpawn.w)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(vehicle) do Wait(0) end 

    while GetVehiclePedIsIn(ped, false) ~= vehicle do TaskWarpPedIntoVehicle(ped, vehicle, -1) Wait(0) end

    return vehicle
end

local function generateTier(myTier)
    local random = math.random(100)

    return
        myTier == 'D' and 'D' or
        myTier == 'C' and (random <= 50 and 'D' or 'C') or
        myTier == 'B' and (random <= 67 and 'C' or 'B') or
        myTier == 'A' and (random <= 75 and 'B' or 'A') or
        myTier == 'S' and (random <= 80 and 'A' or 'S')
end


local function vehicleDeletion(vehicle)
    SetTimeout(Server.DeleteVehicleTimer * 60000, function()
        if DoesEntityExist(vehicle) then DeleteEntity(vehicle) end
    end)
end

local function generateVehiclePlate()
    local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local randomString = ""
    
    for i = 1, 5 do
        local rnd = math.random(#chars)
        randomString = randomString .. string.sub(chars, rnd, rnd)
    end
    
    local plate = ('EXP%s'):format(randomString)
    return plate:upper()
end

local function addExportExp(src, cid, amount)
    cachedPlayers[cid].xp += amount
    cachedPlayers[cid].completed += 1
    MySQL.update.await('UPDATE export_xp SET xp = ?, completed = ? WHERE cid = ?', {cachedPlayers[cid].xp, cachedPlayers[cid].completed, cid})
    DoNotification(src, locale('gained_exp'):format(amount), "success")
    TriggerClientEvent('randol_exports:client:cacheRep', src, cachedPlayers[cid])
end

local function getTierFromExp(xp)
    local tempTable = {}
    for tier, data in pairs(Server.Vehicles) do
        tempTable[#tempTable + 1] = {tier = tier, data = data}
    end
    table.sort(tempTable, function(a, b) return a.data.threshold < b.data.threshold end)

    local tier = 'D'

    for _, vehicle in ipairs(tempTable) do
        if xp >= vehicle.data.threshold then
            tier = vehicle.tier
        else
            break
        end
    end

    return tier
end

local function getTierBasedVehicleInfo(class)
    local tier = generateTier(class)
    return Server.Vehicles[tier], tier
end

lib.callback.register('randol_exports:server:requestJob', function(source)
    if activePlys[source] then 
        return false, locale('already_active') 
    end
    
    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)
    local data = cachedPlayers[cid]
    local tier = getTierFromExp(data.xp)
    local data, vehTier = getTierBasedVehicleInfo(tier)
    local model = data.list[math.random(#data.list)]
    local plate = generateVehiclePlate()
    local exportCar = spawnExportVehicle(src, model)

    activePlys[src] = { 
        tier = vehTier, 
        vehicle = model, 
        plate = plate, 
        payout = math.random(data.payout.min, data.payout.max),
        location = data.locations[math.random(#data.locations)], 
        xpReward = math.random(data.xp.min, data.xp.max), 
        timer = data.timer,
        entity = exportCar,
        netid = NetworkGetNetworkIdFromEntity(exportCar),
    }

    TriggerClientEvent('randol_exports:client:startMission', src, activePlys[src])

    if Config.Debug then
        print(json.encode(activePlys[src], {indent = true}))
    end

    return true
end)

RegisterNetEvent('randol_exports:server:failedMission', function(netid)
    if not activePlys[source] or not netid then return end

    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)

    local vehicle = NetworkGetEntityFromNetworkId(netid)

    cachedPlayers[cid].failed += 1
    MySQL.update.await('UPDATE export_xp SET failed = ? WHERE cid = ?', {cachedPlayers[cid].failed, cid})
    if DoesEntityExist(vehicle) then vehicleDeletion(vehicle) end

    activePlys[src] = nil
    TriggerClientEvent('randol_exports:client:cacheRep', src, cachedPlayers[cid])
end)

lib.callback.register('randol_exports:server:successMission', function(source, netid)
    local src = source
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)
    local pos = GetEntityCoords(GetPlayerPed(src))
    local vehicle = NetworkGetEntityFromNetworkId(netid)
    if not activePlys[src] or not DoesEntityExist(vehicle) or vehicle ~= activePlys[src].entity or #(pos - activePlys[src].location) > 10.0 then return false end

    local payout = activePlys[src].payout
    Server.MissionRewards(Player, payout)
    addExportExp(src, cid, activePlys[src].xpReward)

    activePlys[src] = nil
    DeleteEntity(vehicle)
    return true
end)

function PlayerHasLoaded(src)
    local Player = GetPlayer(src)
    local cid = GetPlyIdentifier(Player)

    if not cachedPlayers[cid] then
        local result = MySQL.query.await('SELECT * FROM export_xp WHERE cid = ?', {cid})
        if result[1] then
            cachedPlayers[cid] = { xp = result[1].xp, completed = result[1].completed, failed = result[1].failed, tier = getTierFromExp(result[1].xp) }
        else
            cachedPlayers[cid] = { xp = 0, completed = 0, failed = 0, tier = 'D', }
        end
        TriggerClientEvent('randol_exports:client:cacheRep', src, cachedPlayers[cid])
    end
end

 -- For whatever reason the resource gets restarted live. Could be a more efficient way to do this?
local function handleLiveRestart()
    local players = GetActivePlayers()
    if #players == 0 then return end

    for i = 1, #players do
        local src = players[i]
        local Player = GetPlayer(src)
        if Player then
            local cid = GetPlyIdentifier(Player)
            local result = MySQL.query.await('SELECT * FROM export_xp WHERE cid = ?', {cid})
            if result[1] then
                cachedPlayers[cid] = {xp = result[1].xp, completed = result[1].completed, failed = result[1].failed, tier = getTierFromExp(result[1].xp)}
            else
                cachedPlayers[cid] = {xp = 0, completed = 0, failed = 0, tier = 'D'}
                MySQL.insert.await("INSERT INTO export_xp (cid, xp, completed, failed) VALUES (?, ?, ?, ?)", {cid, 0, 0 ,0})
            end
            TriggerClientEvent('randol_exports:client:cacheRep', src, cachedPlayers[cid])
        end
    end
end

AddEventHandler('onResourceStart', function(resource)
    if resource == GetCurrentResourceName() then
        MySQL.query([=[
            CREATE TABLE IF NOT EXISTS `export_xp` (
            `cid` VARCHAR(255) NOT NULL,
            `xp` int(11) DEFAULT 0,
            `completed` int(11) DEFAULT 0,
            `failed` int(11) DEFAULT 0,
            PRIMARY KEY (`cid`));
        ]=])
        SetTimeout(2000, handleLiveRestart)
    end
end)
