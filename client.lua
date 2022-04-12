local QBCore = exports['qb-core']:GetCoreObject()
local PlayerData = QBCore.Functions.GetPlayerData()
local supplyType = nil

-- Handlers

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function ()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterNetEvent('QBCore:Client:OnJobUpdate', function(JobInfo)
    PlayerData.job = JobInfo
end)

-- Functions

local function OpenSuppliesMenu()
    exports['qb-menu']:openMenu({
        { header = 'Weapon Supplies', isMenuHeader = true},
        { header = 'Standard Pistol',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'pistol'
                }
            }
        },
        { header = 'Ceramic Pistol',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'ceramic'
                }
            }
        },
        { header = 'Combat Pistol',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'combat'
                }
            }
        },
        { header = 'SNS Pistol',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'sns'
                }
            }
        },
        { header = 'Pump Shotgun',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'pump'
                }
            }
        },
        { header = 'Marksman Rifle',
            params = {
                event = 'qb-ammunation:client:grabSupplies',
                args = {
                    type = 'marksman'
                }
            }
        },
    })
end

local function CraftWeapon()
    if not supplyType then return QBCore.Functions.Notify('You have no supplies', 'error') end
    TriggerEvent('animations:client:EmoteCommandStart', {"c"})
    QBCore.Functions.Progressbar('crafting_weapon', 'Crafting '..Config.WeaponLabels[supplyType], 5000, false, false, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {
        animDict = "mini@repair",
        anim = "fixing_a_ped",
        }, {}, {}, function() -- Success
        QBCore.Functions.Notify("Crafted "..Config.WeaponLabels[supplyType], 'success')
        TriggerServerEvent('qb-ammunation:server:craftWeapon', PlayerData.job.name, Config.Weapons[supplyType])
        supplyType = nil
        ClearPedTasks(PlayerPedId())
    end, function() -- Cancel
        ClearPedTasks(PlayerPedId())
        QBCore.Functions.Notify('You have cancelled the crafting process', 'error')
    end)
end

local function OpenGunMenu()
    QBCore.Functions.TriggerCallback('qb-ammunation:server:getCraftedWeapons', function(weapons)
        local availableWeapons = {{header = 'Available Weapons', isMenuHeader = true}}
        for k,v in pairs(weapons) do
            availableWeapons[#availableWeapons + 1] = {
                header = QBCore.Shared.Items[k].label,
                txt = 'Amount: ' ..v,
                params = {
                    event = 'qb-ammunation:client:showcaseWeapon',
                    args = {
                        weapon = k
                    }
                }
            }
        end
        exports['qb-menu']:openMenu(availableWeapons)
    end, PlayerData.job.name)
end

local function SellWeapon(zoneName, entity, weapon, coords, job)
    local dialog = exports['qb-input']:ShowInput({
        header = 'State ID',
        submitText = 'Sell Weapon',
        inputs = {
            {
                type = 'number',
                isRequired = true,
                name = 'stateId',
                text = 'State ID (#)'
            }
        }
    })
    if dialog then
        if not dialog.stateId then return end
        exports['qb-target']:RemoveZone(zoneName)
        DeleteEntity(entity)
        TriggerServerEvent('qb-ammunation:server:buyWeapon', dialog.stateId, weapon, coords, job)
    end
end

-- Events

RegisterNetEvent('qb-ammunation:client:grabSupplies', function(data)
    if supplyType then return QBCore.Functions.Notify('You already have supplies', 'error') end
    supplyType = data.type
    TriggerServerEvent('qb-ammunation:server:grabSupplies', PlayerData.job.name, data.type)
    TriggerEvent('animations:client:EmoteCommandStart', {"box"})
end)

RegisterNetEvent('qb-ammunation:client:showcaseWeapon', function(data)
    local weaponModel = Config.WeaponModels[data.weapon]
    RequestModel(weaponModel)
    while not HasModelLoaded(weaponModel) do
        Wait(0)
    end
    local showcaseWeapon = CreateObject(GetHashKey(weaponModel), Config.Shops[PlayerData.job.name]['showcase'].x, Config.Shops[PlayerData.job.name]['showcase'].y, Config.Shops[PlayerData.job.name]['showcase'].z, true, true, true)
    SetEntityHeading(showcaseWeapon, Config.Shops[PlayerData.job.name]['showcase'].w)
    local zoneName = PlayerData.job.name..' '..data.weapon
    local coords = Config.Shops[PlayerData.job.name].showcase
    exports['qb-target']:AddEntityZone(zoneName, showcaseWeapon, {
        name = zoneName,
        debugPoly = false
    }, {
        options = {
            {
                icon = 'fa-solid fa-basket-shopping',
                label = 'Sell Weapon',
                action = function()
                    SellWeapon(zoneName, showcaseWeapon, data.weapon, coords, PlayerData.job.name)
                end
            },
            {
                icon = 'fa-solid fa-ban',
                label = 'Remove Weapon',
                action = function()
                    exports['qb-target']:RemoveZone(zoneName)
                    DeleteEntity(showcaseWeapon)
                end
            }
        },
        distance = 2.0,
    })
end)

-- Threads

CreateThread(function()
    for k,v in pairs(Config.Shops) do
        exports['qb-target']:AddBoxZone(v.menu.name, v.menu.loc, v.menu.length, v.menu.width, {
            name = v.menu.name,
            heading = v.menu.heading,
            debug = v.menu.debugPoly,
            minZ = v.menu.minZ,
            maxZ = v.menu.maxZ
        }, {
            options = {
                {
                    icon = 'fa-solid fa-gun',
                    label = 'View available guns',
                    job = k,
                    action = function()
                        OpenGunMenu()
                    end,
                },
            },
            distance = 1.5
        })
        exports['qb-target']:AddBoxZone(v.supplies.name, v.supplies.loc, v.supplies.length, v.supplies.width, {
            name = v.supplies.name,
            heading = v.supplies.heading,
            debug = v.supplies.debugPoly,
            minZ = v.supplies.minZ,
            maxZ = v.supplies.maxZ
        }, {
            options = {
                {
                    icon = 'fa-solid fa-box',
                    label = 'Get supplies',
                    job = k,
                    action = function()
                        OpenSuppliesMenu()
                    end,
                },
            },
            distance = 1.5
        })
        exports['qb-target']:AddBoxZone(v.craft.name, v.craft.loc, v.craft.length, v.craft.width, {
            name = v.craft.name,
            heading = v.craft.heading,
            debug = v.craft.debugPoly,
            minZ = v.craft.minZ,
            maxZ = v.craft.maxZ
        }, {
            options = {
                {
                    icon = 'fa-solid fa-wrench',
                    label = 'Craft weapon',
                    job = k,
                    action = function()
                        CraftWeapon()
                    end,
                },
            },
            distance = 1.5
        })
    end
end)