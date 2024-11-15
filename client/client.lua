local config = lib.require 'config'
local hiredTrucks = false
local trailerNetId, truckerNetId
local truckDrivers = {}

local blipTruck = AddBlipForCoord(vec3(1241.65, -3257.28, 6.03))
SetBlipSprite(blipTruck, 632)
SetBlipScale(blipTruck, 0.8)
SetBlipColour(blipTruck, 0)
SetBlipAsShortRange(blipTruck, true)
BeginTextCommandSetBlipName('STRING')
AddTextComponentSubstringPlayerName('Trucker Job')
EndTextCommandSetBlipName(blipTruck)

-- Todo:
-- Fazer a box zones dos locais (fazer a checagem de dentro da area se tem o trailer)
-- Após desaclopar marcar o retorno para a base (Provavel ter que fazer alguma variavel para verificar, tem no forum lá do cfx)
-- Assim que retorna e marcar como Finish Work (Outra variavel para checar caso esteja terminado o serviço ou está querendo exluir o veiculo)
-- Deletar o caminhão
-- Player Recebe os itens
-- Timer começa a contar até a proxima entrega (Fazer isso nos server side com um array)
-- Fazer alguma forma de o timer contar no servidor

local function generateRandomRoute()
    
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

local function createDeliveryZone()
    local sphere = lib.zones.sphere({
        coords = vec3(1276.07, -3231.75, 5.9),
        radius = 10,
        debug = true,
        inside = function()
            if IsControlJustPressed(0, 46) and isTrailerAttached(truckerNetId) then 
                local sucess = lib.callback.await('lonf:trucker:deleteEntity', false, trailerNetId)
                if sucess then 
                    delivered = true
                end
            end
        end,
        onEnter = onEnter,
        onExit = onExit
    })
end

local function routeDelivery()
    RouteBlip = AddBlipForCoord(1258.38, -3101.29, 5.26)
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
end

local function hireTruck(netId)
    truck = lib.waitFor(function()
        if NetworkDoesEntityExistWithNetworkId(netId) then
            return NetToVeh(truck)
        end
    end, "error bro", 1000)
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
                            title = 'Notification title',
                            description = 'Notification description',
                            type = 'success'
                        })
                        return
                    end

                    truckerNetId = lib.callback.await('lonf:trucker:spawnTruck', false)
                    hireTruck(truckerNetId)

                    trailerNetId = lib.callback.await('lonf:trucker:spawnTrailer', false)
                    hireTruck(trailerNetId)

                    hiredTrucks = true

                    delivered = lib.callback.await('lonf:trucker:clockIn', false)
                    print(delivered)

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
                    print("Finish Work")
                    local sucess = lib.callback.await('lonf:trucker:clockOut', false)
                    if sucess then
                        print("TOMA BAN")
                        print(truckDrivers)
                    else
                        print("NAO TOMA BAN")
                        print(truckDrivers)
                    end
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

CreateThread(function()

end)
