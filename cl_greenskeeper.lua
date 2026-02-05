local Config = lib.require('config')
local Bridge = exports['community_bridge']:Bridge()
local Framework = Bridge.Framework
local Target = Bridge.Target
local Notify = Bridge.Notify
local Fuel = Bridge.Fuel
local VehicleKey = Bridge.VehicleKey

local isHired, activeJob = false
local cityBoss, startZone
local playerLoaded = false

local function hasPlayerLoaded()
    if playerLoaded then return true end
    if not Framework or not Framework.GetPlayerData then return false end
    local ok, data = pcall(Framework.GetPlayerData)
    if not ok or not data then return false end
    return (data.citizenid or data.identifier or data.job) and true or false
end

local function notify(message, nType)
    if Notify and Notify.SendNotify then
        Notify.SendNotify(message, nType)
    end
end

local function giveVehicleKeys(vehicle)
    if not VehicleKey or not VehicleKey.GiveKeys or not DoesEntityExist(vehicle) then return end
    local plate = GetVehicleNumberPlateText(vehicle)
    VehicleKey.GiveKeys(vehicle, plate)
end

local function setFuel(vehicle, amount)
    if Fuel and Fuel.SetFuel then
        Fuel.SetFuel(vehicle, amount)
    else
        SetVehicleFuelLevel(vehicle, amount)
    end
end

local CITY_BLIP = AddBlipForCoord(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
SetBlipSprite(CITY_BLIP, 280)
SetBlipDisplay(CITY_BLIP, 4)
SetBlipScale(CITY_BLIP, 0.5)
SetBlipAsShortRange(CITY_BLIP, true)
SetBlipColour(CITY_BLIP, 2)
BeginTextCommandSetBlipName("STRING")
AddTextComponentSubstringPlayerName("Golf Course Cleaning")
EndTextCommandSetBlipName(CITY_BLIP)

local function resetJob()
    Target.RemoveZone('workBox')
    RemoveBlip(JobBlip)
    isHired = false
    activeJob = false
    if DoesEntityExist(cityBoss) then
        Target.RemoveLocalEntity(cityBoss)
        DeleteEntity(cityBoss)
        cityBoss = nil
    end
    if startZone then startZone:remove() startZone = nil end
end

local function startWork(netid, data)
    local workVehicle = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netid) then
            return NetToVeh(netid)
        end
    end, 'Could not load entity in time.', 3000)

    SetVehicleNumberPlateText(workVehicle, 'CITY'..tostring(math.random(1000, 9999)))
    SetVehicleColours(workVehicle, 111, 111)
    SetVehicleDirtLevel(workVehicle, 1)
    giveVehicleKeys(workVehicle)
    SetVehicleEngineOn(workVehicle, true, true)
    isHired = true
    NextDelivery(data)
    Wait(500)
    setFuel(workVehicle, 100.0)
end

local function finishWork()
    local ped = cache.ped
    local pos = GetEntityCoords(ped)

    local finishspot = vec3(Config.BossCoords.x, Config.BossCoords.y, Config.BossCoords.z)
    if #(pos - finishspot) > 10.0 or not isHired then return end

    local success = lib.callback.await('gldnrmz-greenskeeper:server:clockOut', false)
    if success then
        notify('You ended your shift.', 'success')
        RemoveBlip(JobBlip)
        isHired, activeJob = false
    end
end

local function yeetPed()
    if DoesEntityExist(cityBoss) then
        Target.RemoveLocalEntity(cityBoss)
        DeleteEntity(cityBoss)
        cityBoss = nil
    end
end

local function spawnPed()
    if DoesEntityExist(cityBoss) then return end
    
    lib.requestModel(Config.BossModel, 1000)
    cityBoss = CreatePed(0, Config.BossModel, Config.BossCoords, false, false)
    SetEntityAsMissionEntity(cityBoss)
    SetPedFleeAttributes(cityBoss, 0, 0)
    SetBlockingOfNonTemporaryEvents(cityBoss, true)
    SetEntityInvincible(cityBoss, true)
    FreezeEntityPosition(cityBoss, true)
    TaskStartScenarioInPlace(cityBoss, 'WORLD_HUMAN_CLIPBOARD', 0, true)
    Target.AddLocalEntity(cityBoss, {
        {
            icon = 'fa-solid fa-clipboard-list',
            label = 'Start Work',
            onSelect = function()
                local netid, data = lib.callback.await('gldnrmz-greenskeeper:server:spawnVehicle', false)
                if netid and data then
                    startWork(netid, data)
                end
            end,
            canInteract = function()
                return not isHired
            end,
        },
        {
            icon = 'fa-solid fa-clipboard-check',
            label = 'Finish Work',
            onSelect = function()
                finishWork()
            end,
            canInteract = function()
                return isHired
            end,
        },
    })
end

local props = {
    'proc_litter_01',
}

local function repairSpot()
    if not isHired then return end
    Target.RemoveZone('workBox')
    
    -- Randomly select a scenario from the Config
    local selectedScenario = Config.Scenario[math.random(#Config.Scenario)]
    TaskStartScenarioInPlace(cache.ped, selectedScenario, 0, true)
    
    if lib.progressBar({
        duration = 10000,
        position = 'bottom',
        label = 'Completing the task..',
        useWhileDead = false,
        canCancel = false,
        disable = { move = true, car = true, mouse = false, combat = true },
    }) then
        ClearPedTasksImmediately(cache.ped)
        local success = lib.callback.await('gldnrmz-greenskeeper:server:Payment', false)
        if success then
            RemoveBlip(JobBlip)
            activeJob = false
            notify('Job complete. Wait for your next task.', 'success')
            
            -- Delete the prop after task completion
            if prop then
                DeleteObject(prop)
                prop = nil
            end
        end
    end
end

function NextDelivery(data)
    if activeJob then return end

    currentLoc = data.location
    JobBlip = AddBlipForCoord(currentLoc.x, currentLoc.y, currentLoc.z)
    SetBlipSprite(JobBlip, 274)
    SetBlipDisplay(JobBlip, 4)
    SetBlipScale(JobBlip, 0.6)
    SetBlipAsShortRange(JobBlip, true)
    SetBlipColour(JobBlip, 3)
    SetBlipRoute(JobBlip, true)
    SetBlipRouteColour(JobBlip, 3)
    SetBlipFlashes(JobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Cleaning Task")
    EndTextCommandSetBlipName(JobBlip)

    Target.AddBoxZone('workBox', vec3(currentLoc.x, currentLoc.y, currentLoc.z), vec3(2.6, 2.6, 2.0), 0.0, {
        {
            icon = 'fa-solid fa-hammer',
            label = 'Clean',
            onSelect = function()
                repairSpot()
            end,
        },
    }, false)

    -- Randomly select a prop from the list
    local selectedProp = props[math.random(#props)]

    -- Add prop at the location
    prop = CreateObject(GetHashKey(selectedProp), currentLoc.x, currentLoc.y, currentLoc.z, true, true, true)
    SetEntityAsMissionEntity(prop, true, true)
    PlaceObjectOnGroundProperly(prop)

    activeJob = true
    notify('You have been assigned a new task.', 'success')
    PlaySoundFrontend(-1, "Text_Arrive_Tone", "Phone_SoundSet_Default", 1)
end



local function startJobPoint()
    startZone = lib.points.new({
        coords = Config.BossCoords.xyz,
        distance = 50,
        onEnter = spawnPed,
        onExit = yeetPed,
    })
end

function OnPlayerLoaded()
    startJobPoint()
end

function OnPlayerUnload()
    resetJob()
end

RegisterNetEvent('gldnrmz-greenskeeper:client:generatedLocation', function(data)
    if GetInvokingResource() or not data then return end
    NextDelivery(data)
end)

AddEventHandler('community_bridge:Client:OnPlayerLoaded', function()
    playerLoaded = true
    OnPlayerLoaded()
end)

AddEventHandler('community_bridge:Client:OnPlayerUnload', function()
    playerLoaded = false
    OnPlayerUnload()
end)

AddEventHandler('onResourceStart', function(resource)
    if GetCurrentResourceName() ~= resource or not hasPlayerLoaded() then return end
    playerLoaded = true
    startJobPoint()
end)

AddEventHandler('onResourceStop', function(resourceName) 
    if GetCurrentResourceName() ~= resourceName then return end
    resetJob()
end)