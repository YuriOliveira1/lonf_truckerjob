local config = lib.require 'config'
local truckDrivers = {}
items = {
    "rubber",
    "copper",
    "plastic",
    "glass",
    "steel",
    "iron",
    "rubber"
}

local function generateRandomModel(listLenght)
    return math.random(1, listLenght)
end

local function payment(src)
    for _, item in pairs(items) do
        local quantityReward = math.random(config.minReward, config.maxReward)

        exports.ox_inventory:AddItem(src, item, quantityReward)
    end
end

lib.callback.register('lonf:trucker:getStatus', function(source)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    truckDrivers[identifier] = {
        inRoute = truckDrivers[identifier].inRoute,
        delivered = truckDrivers[identifier].delivered,
        getReward = truckDrivers[identifier].getReward
    }

    return truckDrivers[identifier].inRoute, truckDrivers[identifier].delivered, truckDrivers[identifier].getReward
end)

lib.callback.register('lonf:trucker:delivered', function (source) -- Add coords for check
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    truckDrivers[identifier] = {
        delivered = true,
        inRoute = inRoute,
        getReward = false
    }

    print(tostring(truckDrivers[identifier].getReward) .. " delivered")
    
    return truckDrivers[identifier].delivered, truckDrivers[identifier].getReward
end)

lib.callback.register('lonf:trucker:clockOut', function (source, isSame)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)
    local Player = exports.qbx_core:GetPlayer(src)
    local ped = GetPlayerPed(src)
    local pos = GetEntityCoords(ped)
    print(isSame)

    truckDrivers[identifier] = {
        inRoute = false,
        delivered = truckDrivers[identifier].delivered or false,
        getReward = false
    }

    print(truckDrivers[identifier].getReward)

    if not Player and #(pos - config.coords) > 5 then 
        print("TOMA BAN VAGABUNDA")
    else
        if truckDrivers[identifier].delivered and isSame then
            payment(src)
            truckDrivers[identifier].getReward = true
        end
    end

    print(tostring(truckDrivers[identifier].getReward) .. " ClockOut")

    return truckDrivers[identifier].inRoute, truckDrivers[identifier].getReward
end)

lib.callback.register('lonf:trucker:clockIn', function (source, nameVeh)
    local src = source
    local identifier = GetPlayerIdentifier(src, 0)

    truckDrivers[identifier] = {
        inRoute = true,
        delivered = false,
        getReward = false
    }

    print(tostring(truckDrivers[identifier].getReward) .. " clockIn")

    return truckDrivers[identifier].inRoute, truckDrivers[identifier].delivered , truckDrivers[identifier].getReward
end)

lib.callback.register('lonf:trucker:deleteEntity', function(source, netId)
    local entity = NetworkGetEntityFromNetworkId(netId)
    if DoesEntityExist(entity) then
        DeleteEntity(entity)
        return true
    end

    return false
end)

lib.callback.register('lonf:trucker:spawnTrailer', function(source)
    local index = generateRandomModel(#config.trailers)

    local netId = qbx.spawnVehicle({
        model = config.trailers[index],
        spawnSource = config.trailerSpawn,
        warp = false
    })
    if not netId or netId == 0 then
        return
    end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then
        return
    end

    local plate = "FOD" .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)

    return netId
end)

lib.callback.register('lonf:trucker:spawnTruck', function(source)
    local index = generateRandomModel(#config.trucks)

    local netId = qbx.spawnVehicle({ model = config.trucks[index], spawnSource = config.truckSpawn, warp = false })
    if not netId or netId == 0 then
        return
    end

    local veh = NetworkGetEntityFromNetworkId(netId)
    if not veh or veh == 0 then
        return
    end

    local plate = "FOD" .. tostring(math.random(1000, 9999))
    SetVehicleNumberPlateText(veh, plate)
    TriggerClientEvent('vehiclekeys:client:SetOwner', source, plate)

    return netId
end)

