local Config = lib.require('shared')
local isTimerActive, droppingOff = false
local startTime, elapsedTime = 0, 0
local mainTimer, tempTimer, formattedTime, currentTime, deltaTime, SOUND_ID, EXPORT_VEHICLE, EXPORT_PED, DROP_OFF_ZONE, DROP_OFF_RADIUS, pedInteract, exportPedZone
local activeData = {}
local userInfo = {}

local function missionReset()
    isTimerActive = false
    startTime = 0
    elapsedTime = 0
    EXPORT_VEHICLE, mainTimer, tempTimer, formattedTime, currentTime, deltaTime, SOUND_ID = nil
    table.wipe(activeData)
    if DoesBlipExist(DROP_OFF_BLIP) then
        RemoveBlip(DROP_OFF_BLIP)
    end
    if DoesBlipExist(DROP_OFF_RADIUS) then
        RemoveBlip(DROP_OFF_RADIUS)
    end
    if DROP_OFF_ZONE then DROP_OFF_ZONE:remove() DROP_OFF_ZONE = nil end
end

local function interactContext()
    local data = userInfo 
    if not next(data) then return end

    lib.registerContext({
        id = 'view_rep',
        title = locale('viewrep_context_maintitle'),
        options = {
            {
                title = locale('target_label_work'),
                icon = locale('target_icon_rep'),
                onSelect = function()
                    if IsAnyVehicleNearPoint(Config.VehicleSpawn.x, Config.VehicleSpawn.y, Config.VehicleSpawn.z, 3.0) then 
                        return DoNotification(locale('spawn_blocked'), 'error') 
                    end
                    local canStart, msg = lib.callback.await('randol_exports:server:requestJob', false)
                    if not canStart then
                        DoNotification(msg, 'error')
                    end
                end,
            },
            {
                title = locale('viewrep_context_exptitle'),
                description = ('XP: %s | Tier %s'):format(data.xp, data.tier),
                readOnly = true,
            },
            {
                title = locale('viewrep_context_comptitle'),
                description = tostring(data.completed),
                readOnly = true,
            },
            {
                title = locale('viewrep_context_failtitle'),
                description = tostring(data.failed),
                readOnly = true,
            },
        }
    })

    lib.showContext('view_rep')
end

local function missionPassed(seconds, title, message)
    local scaleform = lib.requestScaleformMovie('MIDSIZED_MESSAGE', 3000)
    BeginScaleformMovieMethod(scaleform, 'SHOW_COND_SHARD_MESSAGE')
    PushScaleformMovieMethodParameterString(title)
    PushScaleformMovieMethodParameterString(message)
    EndScaleformMovieMethod()
    PlaySoundFrontend(-1, 'Mission_Pass_Notify', 'DLC_HEISTS_GENERAL_FRONTEND_SOUNDS', 0)
    AnimpostfxPlay("HeistCelebToast", (seconds+2) * 1000)
    while seconds > 0 do
        Wait(1)
        seconds -= 0.01
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
    end
    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

local function missionFailed(seconds, title, message)
    local scaleform = lib.requestScaleformMovie('MIDSIZED_MESSAGE', 3000)
    BeginScaleformMovieMethod(scaleform, 'SHOW_COND_SHARD_MESSAGE')
    PushScaleformMovieMethodParameterString(title)
    PushScaleformMovieMethodParameterString(message)
    EndScaleformMovieMethod()
    PlaySoundFrontend(-1, 'LOSER', 'HUD_AWARDS', 0)
    AnimpostfxPlay("HeistCelebFail", (seconds+2) * 1000)
    while seconds > 0 do
        Wait(1)
        seconds -= 0.01
        DrawScaleformMovieFullscreen(scaleform, 255, 255, 255, 255)
    end
    SetScaleformMovieAsNoLongerNeeded(scaleform)
end

local function drawTime(text, font, x, y, scale, r, g, b, a)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextOutline()
    SetTextCentre(2)
    SetTextEntry("STRING")
    AddTextComponentString(text)
    DrawText(x, y)
end

local function countdownTimer()
    if isTimerActive then
        SOUND_ID = GetSoundId()
        PlaySoundFrontend(SOUND_ID, 'Timer_10s', 'DLC_HALLOWEEN_FVJ_Sounds', 0)
    end
end

local function deliveryFailed(msg)
    isTimerActive = false
    SetEntityVelocity(EXPORT_VEHICLE, 0.0, 0.0, (5 * 1.0))
    NetworkExplodeVehicle(EXPORT_VEHICLE, true, false)
    isCounting = false
    missionFailed(3, locale('sf_failed_title'), msg)
    TriggerServerEvent('randol_exports:server:failedMission', NetworkGetNetworkIdFromEntity(EXPORT_VEHICLE))
    missionReset()
end

local function startExportTimer(timerInSeconds)
    if not isTimerActive then
        startTime = GetGameTimer() - elapsedTime
        isTimerActive = true
        local targetTime = timerInSeconds * 1000

        CreateThread(function()
            while isTimerActive do
                Wait(0)
                currentTime = GetGameTimer()
                deltaTime = currentTime - startTime

                if deltaTime >= targetTime then
                    mainTimer = locale('time_remaining_end')
                    deliveryFailed(locale('sf_failed_msg'))
                else
                    local remainingTime = targetTime - deltaTime
                    formattedTime = string.format("%.2d:%.2d", math.floor((remainingTime % 3600000) / 60000), math.floor((remainingTime % 60000) / 1000) )
                    mainTimer = locale('time_remaining_green'):format(formattedTime)

                    if remainingTime <= 60000 then
                        mainTimer = locale('time_remaining_red'):format(formattedTime)
                    end

                    drawTime(mainTimer, 4, 0.5, 0.88, 0.65, 255, 255, 255, 220)

                    if remainingTime <= 10000 and not isCounting then
                        isCounting = true
                        countdownTimer()
                    end
                end

                local distance = #(GetEntityCoords(cache.ped) - GetEntityCoords(EXPORT_VEHICLE))
                if distance > 85.0 and isTimerActive then
                    deliveryFailed(locale('sf_failed_msg_toofar'))
                end
            end
        end)
    end
end


local function dropoffVehicle()
    local vehicle = cache.vehicle
    
    if vehicle ~= EXPORT_VEHICLE then
        droppingOff = false
        DoNotification(locale('not_export_vehicle'), "error")
        return
    end

    isTimerActive = false
    if SOUND_ID then ReleaseSoundId(SOUND_ID) StopSound(SOUND_ID) SOUND_ID = nil end
    FreezeEntityPosition(vehicle, true)
    SetVehicleDoorsLocked(vehicle, 2)
    TaskLeaveVehicle(cache.ped, vehicle, 1)
    lib.hideTextUI()
    if lib.progressCircle({
        duration = 2000,
        position = 'bottom',
        label = locale('prog_deliv'),
        useWhileDead = true,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true, },
    }) then
        local success = lib.callback.await("randol_exports:server:successMission", false, NetworkGetNetworkIdFromEntity(vehicle))
        if success then
            droppingOff = false
            local label = GetLabelText(GetDisplayNameFromVehicleModel(activeData.vehicle))
            missionPassed(3, locale('sf_success_title'), (locale('sf_success_msg')):format(label, activeData.payout))
            missionReset()
        end
    end
end

local function onEnter()
    lib.showTextUI(locale('textui_label'), { icon = locale('textui_icon'), position = 'left-center', })
end

local function inside()
    if IsControlJustReleased(0, 38) and not droppingOff then
        droppingOff = true
        dropoffVehicle()
    end
end

local function onExit()
    lib.hideTextUI()
end

local function createRadiusBlip(coords)
    blip = AddBlipForRadius(coords.x, coords.y, coords.z, 150.0)
    SetBlipHighDetail(blip, true)
    SetBlipAlpha(blip, Config.BlipInfo.Radius_Alpha)
    SetBlipColour(blip, Config.BlipInfo.Radius_Colour)
    return blip
end

local function createDropOffZone(coords)
    DROP_OFF_BLIP = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(DROP_OFF_BLIP, Config.BlipInfo.Sprite)
    SetBlipScale(DROP_OFF_BLIP, Config.BlipInfo.Scale)
    SetBlipColour(DROP_OFF_BLIP, Config.BlipInfo.Colour)
    SetBlipAlpha(DROP_OFF_BLIP, Config.BlipInfo.Alpha)
    SetBlipDisplay(DROP_OFF_BLIP, 4)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName(Config.BlipInfo.String)
    EndTextCommandSetBlipName(DROP_OFF_BLIP)
    DROP_OFF_RADIUS = createRadiusBlip(coords)
    DROP_OFF_ZONE = lib.zones.box({ coords = coords, size = vec3(8, 8, 8), rotation = 0, debug = Config.Debug, inside = inside, onEnter = onEnter, onExit = onExit })
    startExportTimer(activeData.timer)
end

local function removePedSpawned()
    if DoesEntityExist(EXPORT_PED) then 
        DeleteEntity(EXPORT_PED)
        EXPORT_PED = nil
        if Config.UseTarget then
            exports['qb-target']:RemoveTargetEntity(EXPORT_PED, "Interact")
            EXPORT_PED = nil
        else
            if pedInteract then
                pedInteract:remove()
                pedInteract = nil
            end
        end
    end
end

local function spawnPed()
    if DoesEntityExist(EXPORT_PED) then return end

    local model = Config.PedModel
    lib.requestModel(model, 5000)
    EXPORT_PED = CreatePed(0, model, Config.PedCoords, false, false)
    SetEntityAsMissionEntity(EXPORT_PED)
    SetPedFleeAttributes(EXPORT_PED, 0, 0)
    SetBlockingOfNonTemporaryEvents(EXPORT_PED, true)
    SetEntityInvincible(EXPORT_PED, true)
    FreezeEntityPosition(EXPORT_PED, true)
    TaskStartScenarioInPlace(EXPORT_PED, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    SetPedDefaultComponentVariation(EXPORT_PED)
    if Config.UseTarget then
        exports['qb-target']:AddTargetEntity(EXPORT_PED, {
            options = {
                {
                    icon = locale('target_icon_rep'),
                    label = locale('target_label_rep'),
                    action = function()
                        interactContext()
                    end,
                },
            },
            distance = 2.0
        })
    else
        pedInteract = lib.zones.box({
            coords = vec3(Config.PedCoords.x, Config.PedCoords.y, Config.PedCoords.z+0.5), 
            size = vec3(2, 2, 2),
            rotation = GetEntityHeading(EXPORT_PED),
            debug = Config.Debug,
            onEnter = function()
                lib.showTextUI(locale('interact_label'), {position = "left-center"})
            end,
            onExit = function()
                lib.hideTextUI()
            end,
            inside = function()
                if IsControlJustPressed(0, 38) then
                    interactContext()
                end
            end,
        })
    end
end

RegisterNetEvent('randol_exports:client:startMission', function(data)
    if GetInvokingResource() or not data then return end
    activeData = data

    EXPORT_VEHICLE = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(data.netid) then
            return NetToVeh(data.netid)
        end
    end, 'Could not load entity in time and get ownership.', 5000)

    SetVehicleOnGroundProperly(EXPORT_VEHICLE)

    local label = GetLabelText(GetDisplayNameFromVehicleModel(GetEntityModel(EXPORT_VEHICLE)))
    SetVehicleNumberPlateText(EXPORT_VEHICLE, activeData.plate)
    SetEntityAsMissionEntity(EXPORT_VEHICLE, true, true)

    local props = { modEngine = 3, modTransmission = 2, modSuspension = 3, modArmor = 4, modBrakes = 2, modTurbo = true, }
    lib.setVehicleProperties(EXPORT_VEHICLE, props)

    SetVehicleColours(EXPORT_VEHICLE, math.random(160), math.random(160))
    SetVehicleDoorsLocked(EXPORT_VEHICLE, 1)
    handleVehicleKeys(EXPORT_VEHICLE)

    if Config.Fuel.enable then
        exports[Config.Fuel.script]:SetFuel(EXPORT_VEHICLE, 100.0)
    else
        Entity(EXPORT_VEHICLE).state.fuel = 100
    end

    createDropOffZone(activeData.location)
    DoNotification((locale('dropoff_info_notify')):format(label, activeData.tier), 'success')
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
end)

local function createExportStart()
    exportPedZone = lib.points.new({
        coords = Config.PedCoords.xyz,
        distance = 30,
        onEnter = spawnPed,
        onExit = removePedSpawned,
    })
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        createExportStart()
    end
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() == resourceName then
        removePedSpawned()
    end 
end)

AddEventHandler('randol_exports:onLogout', function()
    if exportPedZone then exportPedZone:remove() exportPedZone = nil end
    removePedSpawned()
    table.wipe(userInfo)
end)

AddEventHandler('randol_exports:onLoggedIn', function() 
    createExportStart()
end)

RegisterNetEvent('randol_exports:client:cacheRep', function(info)
    if GetInvokingResource() or not hasPlyLoaded() or not info then return end
    userInfo = info
end)