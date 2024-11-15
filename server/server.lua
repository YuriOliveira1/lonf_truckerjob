local config = lib.require 'config'
local truckDrivers = {}
local function generateRandomModel(listLenght)
    return math.random(1, listLenght)
end

local function payment()
    
end

lib.callback.register('lonf:trucker:clockOut', function (source)

    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    local pos = GetEntityCoords(GetPlayerPed(src))

    if truckDrivers[src].delivered then
        print("Entrega os items")
    else
        print("Não entrega os items e excloi os veiculos")
    end 


    if not Player and #(pos - config.coords) > 5 then 
        print("TOMA BAN")
        return true 
    else
        print("NAO TOMA BAN")
        return false
    end
end)

lib.callback.register('lonf:trucker:clockIn', function (source)
    local src = source

    truckDrivers[src] = {
        delivered = true
    }

    return truckDrivers[src].delivered
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
