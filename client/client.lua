local config = lib.require 'config'
local hiredTrucks = false
local trailerNetId, truckerNetId
local statusReward

local blipTruck = AddBlipForCoord(vec3(1241.65, -3257.28, 6.03))
SetBlipSprite(blipTruck, 632)
SetBlipScale(blipTruck, 0.8)
SetBlipColour(blipTruck, 0)
SetBlipAsShortRange(blipTruck, true)
BeginTextCommandSetBlipName('STRING')
AddTextComponentSubstringPlayerName('Trucker Job')
EndTextCommandSetBlipName(blipTruck)

local function isSameVehicle()
    local playerPed = PlayerPedId()

    local spawnVeh = GetEntityModel(NetToVeh(truckerNetId))
    local vehicle = GetEntityModel(GetVehiclePedIsIn(playerPed, true))

    local nameSpawnTruck = GetDisplayNameFromVehicleModel(spawnVeh)
    local nameLastTruck = GetDisplayNameFromVehicleModel(vehicle)

    return nameSpawnTruck == nameLastTruck
end

local function isTrailerAttached(netId)
    local Truck = NetToVeh(netId)
    local _, isTrailerAttached = GetVehicleTrailerVehicle(Truck)
    if isTrailerAttached > 1 then
        return true
    else
        return false
    end
end

local function generateRandomRoute()
    return math.random(1, #config.locations)
end

local function generateCoords(route)
    return config.locations[route]
end

local function createDeliveryZone()
    local index = generateRandomRoute()
    local selectedRoute = generateCoords(index)
    local blipRoute = routeDelivery(selectedRoute)
    local sphere

    sphere = lib.zones.sphere({
        coords = selectedRoute,
        radius = 8,
        debug = false,
        inside = function()
            if IsControlJustPressed(0, 46) and isTrailerAttached(truckerNetId) then
                local sucess = lib.callback.await('lonf:trucker:deleteEntity', false, trailerNetId)
                if sucess then
                    delivered, statusReward = lib.callback.await('lonf:trucker:delivered', false)
                    blipBase = routeDelivery(config.coords)
                end
            end
        end,
        onEnter = function()
            RemoveBlip(blipRoute)
        end,
        onExit = function()
            sphere:remove()
        end
    })
end

function routeDelivery(selectedRoute)
    if not selectedRoute or not selectedRoute.x or not selectedRoute.y or not selectedRoute.z then return 0 end
    local RouteBlip = AddBlipForCoord(selectedRoute.x, selectedRoute.y, selectedRoute.z)
    SetBlipSprite(RouteBlip, 1)
    SetBlipDisplay(RouteBlip, 4)
    SetBlipScale(RouteBlip, 0.8)
    SetBlipFlashes(RouteBlip, true)
    SetBlipAsShortRange(RouteBlip, true)
    SetBlipColour(RouteBlip, 3)
    SetBlipRoute(RouteBlip, true)
    SetBlipRouteColour(RouteBlip, 3)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName('Next Customer')
    EndTextCommandSetBlipName(RouteBlip)
    return RouteBlip
end

local function hireTruck(netId)
    truck = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(truck)
        end
    end, "error bro", 1500)
end

local function updateOptions()
    exports.ox_target:removeModel(config.model)

    if not hiredTrucks then
        exports.ox_target:addModel(config.model, {
            {
                icon = 'fa-solid fa-check',
                label = 'Start Work',
                onSelect = function()
                    local isTruckNear = IsAnyVehicleNearPoint(config.truckSpawn.x, config.truckSpawn.y,
                        config.truckSpawn.z, 2.5)
                    local isTrailerNear = IsAnyVehicleNearPoint(config.trailerSpawn.x, config.trailerSpawn.y,
                        config.trailerSpawn.z, 5.0)

                    if isTruckNear or isTrailerNear then
                        lib.notify({
                            title = 'Veiculo Alugado Com Sucesso',
                            type = 'success'
                        })
                        return
                    end

                    truckerNetId = lib.callback.await('lonf:trucker:spawnTruck', false)
                    hireTruck(truckerNetId)

                    trailerNetId = lib.callback.await('lonf:trucker:spawnTrailer', false)
                    hireTruck(trailerNetId)

                    hiredTrucks = true

                    inRoute, delivered, statusReward = lib.callback.await('lonf:trucker:clockIn', false)
                    
                    routeDelivery()
                    createDeliveryZone()
                    updateOptions()
                end,
                distance = 1.5,
            }
        })
    else
        exports.ox_target:addModel(config.model, {
            {
                icon = 'fa-solid fa-check',
                label = 'Finish Work',
                onSelect = function()
                    if not statusReward then
                        local isSame = isSameVehicle()
                        local inRoute, newStatusReward = lib.callback.await('lonf:trucker:clockOut', false, isSame)
                        statusReward = newStatusReward

                        if statusReward then
                            RemoveBlip(blipBase)
                            local sucess = lib.callback.await('lonf:trucker:deleteEntity', false, truckerNetId)
                            if sucess then
                                print("Recompensa recebida!")
                            end
                        else
                            print("Algo deu errado ao tentar pegar a recompensa.")
                        end

                        updateOptions()
                    else
                        print("Você já recebeu sua recompensa.")
                    end

                    hiredTrucks = false
                    updateOptions()
                end,
                distance = 1.5,
            }
        })
    end
end

local function spawnPeds()
    local model = GetHashKey(config.model)

    RequestModel(model)

    while not HasModelLoaded(model) do
        Wait(1)
    end

    local pedModel = CreatePed(0, model, config.coords.x, config.coords.y, config.coords.z, config.coords.w, false, false)
    SetEntityInvincible(pedModel, true)
    FreezeEntityPosition(pedModel, true)
    SetBlockingOfNonTemporaryEvents(pedModel, true)
    SetModelAsNoLongerNeeded(pedModel)
    updateOptions()
end


RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    spawnPeds()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        spawnPeds()
    end
end)
