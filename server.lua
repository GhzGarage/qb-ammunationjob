local QBCore = exports['qb-core']:GetCoreObject()

local supplies = {
    ['ammuone'] = {},
    ['ammutwo'] = {},
    ['ammuthree'] = {},
    ['ammufour'] = {},
    ['ammufive'] = {},
    ['ammusix'] = {},
    ['ammuseven'] = {},
    ['ammueight'] = {},
    ['ammunine'] = {},
    ['ammuten'] = {},
    ['ammuelev'] = {},
}

local weapons = {
    ['ammuone'] = {},
    ['ammutwo'] = {},
    ['ammuthree'] = {},
    ['ammufour'] = {},
    ['ammufive'] = {},
    ['ammusix'] = {},
    ['ammuseven'] = {},
    ['ammueight'] = {},
    ['ammunine'] = {},
    ['ammuten'] = {},
    ['ammuelev'] = {},
}

local function isAvailable(weapon, job)
    for k,v in pairs(weapons) do
        if k == job then
            if v[weapon] > 0 then return true end
        end
    end
    return false
end

local function removeWeapon(weapon, job)
    for k,v in pairs(weapons) do
        if k == job then
            if v[weapon] then
                v[weapon] = v[weapon] - 1
            end
        end
    end
end

RegisterNetEvent('qb-ammunation:server:grabSupplies', function(job, type)
    local src = source
    local playerJob = QBCore.Functions.GetPlayer(src).PlayerData.job.name
    if playerJob ~= job then return end
    for k,v in pairs(supplies) do
        if k == job then
            if v[type] then
                v[type] = v[type] + 1
            else
                v[type] = 1
            end
        end
    end
end)

RegisterNetEvent('qb-ammunation:server:craftWeapon', function(job, weapon)
    local src = source
    local playerJob = QBCore.Functions.GetPlayer(src).PlayerData.job.name
    if playerJob ~= job then return end
    for k,v in pairs(weapons) do
        if k == job then
            if v[weapon] then
                v[weapon] = v[weapon] + 1
            else
                v[weapon] = 1
            end
        end
    end
end)

RegisterNetEvent('qb-ammunation:server:buyWeapon', function(buyerId, weapon, coords, job)
    local src = source
    local ped = GetPlayerPed(src)
    local tped = GetPlayerPed(buyerId)
    local pcoords = GetEntityCoords(ped)
    local tcoords = GetEntityCoords(tped)
    --local acoords = vector3(coords.x, coords.y, coords.z)
    local buyer = QBCore.Functions.GetPlayer(tonumber(buyerId))
    if buyer then
        if #(pcoords - tcoords) < 5.0 then
            if not isAvailable(weapon, job) then return end
            buyer.Functions.AddItem(weapon, 1)
            removeWeapon(weapon, job)
            TriggerClientEvent('QBCore:Notify', buyerId, "You received a " .. QBCore.Shared.Items[weapon].label)
        else
            TriggerClientEvent('QBCore:Notify', src, "You are too far away from the buyer")
        end
    end
end)

QBCore.Functions.CreateCallback('qb-ammunation:server:getCraftSupplies', function(source, cb, job)
    cb(supplies[job])
end)

QBCore.Functions.CreateCallback('qb-ammunation:server:getCraftedWeapons', function(source, cb, job)
    cb(weapons[job])
end)