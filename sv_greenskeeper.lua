local Server = lib.require('sv_config')
local Bridge = exports['community_bridge']:Bridge()
local Framework = Bridge.Framework
local Notify = Bridge.Notify

local players = {}

local function handleExploit(id, reason)
    DropPlayer(id, 'You were dropped from the server.')
    print(('[^3WARNING^7] Player: ^5%s^7 %s'):format(id, reason or 'Exploiting.'))
end

local function createWorkVehicle(source)
    local veh = CreateVehicle(Server.Vehicle, Server.VehicleSpawn.x, Server.VehicleSpawn.y, Server.VehicleSpawn.z, Server.VehicleSpawn.w, true, true)
    local ped = GetPlayerPed(source)

    while not DoesEntityExist(veh) do Wait(10) end 

    -- while GetVehiclePedIsIn(ped, false) ~= veh do TaskWarpPedIntoVehicle(ped, veh, -1) Wait(0) end

    return NetworkGetNetworkIdFromEntity(veh)
end

lib.callback.register('gldnrmz-greenskeeper:server:spawnVehicle', function(source)
    if players[source] then return false end

    local src = source
    local netid = createWorkVehicle(src)

    local newDelivery = Server.Locations[math.random(#Server.Locations)]
    local payout = math.random(Server.Payout.min, Server.Payout.max)

    players[src] = {
        entity = NetworkGetEntityFromNetworkId(netid),
        location = newDelivery,
        payment = payout,
    }

    return netid, players[src]
end)

lib.callback.register('gldnrmz-greenskeeper:server:clockOut', function(source)
    local src = source
    if players[src] then
        local ent = players[src].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[src] = nil
        return true
    end
    return false
end)

lib.callback.register('gldnrmz-greenskeeper:server:Payment', function(source)
    local src = source
    local pos = GetEntityCoords(GetPlayerPed(src))

    if not players[src] or #(pos - players[src].location) > 10.0 then
        handleExploit(src, 'Exploiting.')
        return false
    end

    if not Framework or not Framework.AddAccountBalance then return false end
    Framework.AddAccountBalance(src, Server.Account, players[src].payment)
    if Notify and Notify.SendNotify then
        Notify.SendNotify(src, ('You received $%s. Please wait for your next delivery!'):format(players[src].payment), "success")
    end

    CreateThread(function()
        local vehicle = players[src].entity
        players[src] = nil

        Wait(Server.Timeout)

        local newDelivery = Server.Locations[math.random(#Server.Locations)]
        local payout = math.random(Server.Payout.min, Server.Payout.max)

        players[src] = {
            entity = vehicle,
            location = newDelivery,
            payment = payout,
        }

        TriggerClientEvent("gldnrmz-greenskeeper:client:generatedLocation", src, players[src])
    end)

    return true
end)

AddEventHandler("playerDropped", function()
    local src = source
    if players[src] then
        local ent = players[src].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[src] = nil
    end
end)

function ServerOnLogout(source)
    if players[source] then
        local ent = players[source].entity
        if DoesEntityExist(ent) then
            DeleteEntity(ent)
        end
        players[source] = nil
    end
end

AddEventHandler('community_bridge:Server:OnPlayerUnload', function(src)
    ServerOnLogout(src)
end)

local function CheckVersion()
	PerformHttpRequest('https://raw.githubusercontent.com/GLDNRMZ/'..GetCurrentResourceName()..'/main/version.txt', function(err, text, headers)
		local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version')
		if not text then 
			print('^1[GLDNRMZ] Unable to check version for '..GetCurrentResourceName()..'^0')
			return 
		end
		local result = text:gsub("\r", ""):gsub("\n", "")
		if result ~= currentVersion then
			print('^1[GLDNRMZ] '..GetCurrentResourceName()..' is out of date! Latest: '..result..' | Current: '..currentVersion..'^0')
		else
			print('^2[GLDNRMZ] '..GetCurrentResourceName()..' is up to date! ('..currentVersion..')^0')
		end
	end)
end

Citizen.CreateThread(function()
	CheckVersion()
end)