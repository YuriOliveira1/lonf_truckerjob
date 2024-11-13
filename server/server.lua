local config = lib.require 'config'

local function generateRandomModel(listLenght)
    return math.random(1, listLenght)
end


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
