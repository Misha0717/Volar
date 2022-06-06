local Keys = {
    ["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
    ["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
    ["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
    ["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
    ["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,["-"] = 84,
    ["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
    ["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
    ["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
    ["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

  
ESX                           = nil
local GUI      = {}
local PlayerData                = {}
local lastVehicle = nil
local lastOpen = false
GUI.Time                      = 0
local vehiclePlate = {}
local arrayWeight = Config.localWeight
local CloseToVehicle = false
local entityWorld = nil
local globalplate = nil
local lastChecked					= 0
local maxDistance = 5.0
DecorRegister('_TRUNK_UNLOCKED', 3)
DecorRegister('_TRUNK_LOCKED', 3)
  
Citizen.CreateThread(function()
    while ESX == nil do 
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    while ESX.GetPlayerData().job == nil do
        Citizen.Wait(10)
    end

    PlayerData = ESX.GetPlayerData()
    jobName = PlayerData.job.name
end)
  
RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    PlayerData = xPlayer
    TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
    lastChecked = GetGameTimer()
end)
  
AddEventHandler('onResourceStart', function()
    PlayerData = xPlayer
    TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
    lastChecked = GetGameTimer()
end)
  
RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    PlayerData.job = job
    JobName = PlayerData.job.name
end)
  
RegisterNetEvent('esx_trunk_inventory:setOwnedVehicule')
AddEventHandler('esx_trunk_inventory:setOwnedVehicule', function(vehicle)
    vehiclePlate = vehicle
end)
  
function IsTrunkUnlocked(vehicle)
    return (GetVehicleDoorLockStatus(vehicle) == 1 and not DecorExistOn(vehicle, "_VEHICLE_LOCKED")) or DecorExistOn(vehicle, "_TRUNK_UNLOCKED")
end
  
function getItemyWeight(item)
    local weight = 0
    local itemWeight = 0
    if item ~= nil then
        itemWeight = Config.DefaultWeight
        if arrayWeight[item] ~= nil then
            itemWeight = arrayWeight[item]
        end
    end
    return itemWeight
end
  
function VehicleInFront()
    local pos = GetEntityCoords(PlayerPedId())
    if not IsAnyVehicleNearPoint(pos, maxDistance) then
        return 0
    end
  
    local closecar, distance = ESX.Game.GetClosestVehicle(pos)
    if distance == -1 or not DoesEntityExist(closecar) then
        return 0
    end
  
    if distance > maxDistance then
      return 0
    else
        local coords
      -- 'wheel_rr', 'wheel_lr', 'boot'
        local bone = GetEntityBoneIndexByName(closecar, 'boot')
        if bone == -1 then
            bone = GetEntityBoneIndexByName(closecar, 'wheel_rr')
            local bone2 = GetEntityBoneIndexByName(closecar, 'wheel_lr')
            if bone == -1 or bone2 == -1 then
                return closecar
            end
            coords = (GetWorldPositionOfEntityBone(closecar, bone) + GetWorldPositionOfEntityBone(closecar, bone)) * 0.5
        else
            coords = GetWorldPositionOfEntityBone(closecar, bone)
        end
        if #(coords - pos) < maxDistance then
            return closecar
        else
            return 0
        end
    end
end
  
function RequestControl(entity, timeout)
    if DoesEntityExist(GetPedInVehicleSeat(entity, -1)) then
        return
    end
    timeout = timeout == nil and 1000 or timeout
    NetworkRequestControlOfEntity(entity)
    local timeExpired = 1
    while not NetworkHasControlOfEntity(entity) and timeExpired < timeout do
        Citizen.Wait(100)
        timeExpired = timeExpired + 100
        NetworkRequestControlOfEntity(entity)
    end
end
  
function PlayTrunkAnimation(entity)
    local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
    ESX.Streaming.RequestAnimDict(dict)
    TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 16, 0.0, false, false, false)
    RemoveAnimDict(dict)
  
    --[[SelectedWeapon = GetSelectedPedWeapon(PlayerPedId())
  
    SetEntityHeading(PlayerPedId(), GetEntityHeading(entity))
    TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
    Citizen.Wait(1000)
    Citizen.CreateThread(function()
        Citizen.Wait(100)
        while GlobalPlate and LastVehicle ~= 0 and LastVehicle ~= nil do
            if not IsPedUsingScenario(PlayerPedId(), "PROP_HUMAN_BUM_BIN") then
                TaskStartScenarioInPlace(PlayerPedId(), "PROP_HUMAN_BUM_BIN", 0, true)
            end
            Citizen.Wait(500)
        end
    end)]]
end
  
local function canReachVehicle(playerPed, vehicle)
    local coords = GetEntityCoords(vehicle)
    local coords2 = GetEntityCoords(playerPed)
    local rayHandle = StartShapeTestRay(coords, coords2, 19, vehicle)
  
    local retval, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
  
    return hit == 0
end
  
function openmenuvehicle()
    local playerPed = GetPlayerPed(-1)
    local coords    = GetEntityCoords(playerPed)
    local vehicle   =VehicleInFront()
    globalplate  = GetVehicleNumberPlateText(vehicle)
  
    if not DoesEntityExist(vehicle) or GetEntitySpeed(vehicle) >= 2.0 or not canReachVehicle(playerPed, vehicle) or IsPedInAnyVehicle(playerPed) then
        ESX.ShowNotification('Geen ~r~voertuig~w~ dichtbij')
        return
    end
  
    RequestControl(vehicle, 1)
  
    if not IsTrunkUnlocked(vehicle) then
        ESX.ShowNotification('Deze kofferbak zit op ~r~slot!')
        ClearPedTasks(playerPed)
        return
    end
    
    myVeh = false
    local thisVeh = VehicleInFront()
    for i=1, #vehiclePlate do
        local vPlate = all_trim(vehiclePlate[i].plate)
        local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
        if vPlate == vFront then
            myVeh = true
        elseif lastChecked < GetGameTimer() - 60000 then
            TriggerServerEvent("esx_trunk_inventory:getOwnedVehicule")
            lastChecked = GetGameTimer()
            Wait(2000)
            for i=1, #vehiclePlate do
                local vPlate = all_trim(vehiclePlate[i].plate)
                local vFront = all_trim(GetVehicleNumberPlateText(thisVeh))
                if vPlate == vFront then
                    myVeh = true
                end
            end
        end
    end
  
    if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
        CloseToVehicle = true
        local vehFront = VehicleInFront()
        local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
        local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 71)

        if vehFront > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= GetPlayerPed(-1) then
            lastVehicle = vehFront
            local model = GetDisplayNameFromVehicleModel(GetEntityModel(closecar))
            local locked = GetVehicleDoorLockStatus(closecar)
            local class = GetVehicleClass(vehFront)
            ESX.UI.Menu.CloseAll()
            local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
            ESX.Streaming.RequestAnimDict(dict)
            TaskPlayAnim(playerPed, dict, anim, 8.0, 8.0, -1, 16, 0.0, false, false, false)
            RemoveAnimDict(dict)

            if ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'inventory') then
                SetVehicleDoorShut(vehFront, 5, false)
            else

                if locked == 1 or class == 15 or class == 16 or class == 14 then
                    SetVehicleDoorOpen(vehFront, 5, false, false)
                    ESX.UI.Menu.CloseAll()

                    if globalplate ~= nil or globalplate ~= "" or globalplate ~= " " then
                        CloseToVehicle = true
                        if inArray(model, Config.VehicleModel) then
                            model = string.lower(model)
                            vehCapacity = Config.VehicleModel[model]
                        else
                            vehCapacity = Config.VehicleLimit[class]
                        end
                        OpenCoffreInventoryMenu(GetVehicleNumberPlateText(vehFront), vehCapacity)
                    end

                else
                    ESX.ShowNotification(_U('trunk_closed'))
                end
            end
        else
            ESX.ShowNotification(_U('no_veh_nearby'))
        end
        lastOpen = true
        GUI.Time  = GetGameTimer()
    end
end



local count = 0 
-- Key controls
Citizen.CreateThread(function()
    while true do
        Wait(0)
        if IsControlPressed(0, Keys["L"]) and (GetGameTimer() - GUI.Time) > 1000  then
            openmenuvehicle()
        elseif lastOpen and IsControlPressed(0, Keys["BACKSPACE"]) and (GetGameTimer() - GUI.Time) > 150 then
            CloseToVehicle = false
            lastOpen = false
            if lastVehicle > 0 then
                SetVehicleDoorShut(lastVehicle, 5, false)
                lastVehicle = 0
            end
            GUI.Time  = GetGameTimer()
        end
    end
end)
  
Citizen.CreateThread(function()
    while true do
        Wait(0)
        local pos = GetEntityCoords(GetPlayerPed(-1))
        if CloseToVehicle then
            local vehicle = GetClosestVehicle(pos['x'], pos['y'], pos['z'], 2.0, 0, 70)
            if DoesEntityExist(vehicle) then
                CloseToVehicle = true
            else
                CloseToVehicle = false
                lastOpen = false
                ESX.UI.Menu.CloseAll()
                SetVehicleDoorShut(lastVehicle, 5, false)
            end
        end
    end
end)
  
function OpenCoffreInventoryMenu(plate,max)
  
    ESX.TriggerServerCallback('esx_trunk:getInventoryV', function(inventory)
        local plate = plate
        local owner= GetPlayerPed(-1)
        local elements = {}
        table.insert(elements, {label = _U('deposit'), type = 'deposer', value = 'deposer'})
        table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})
  
        for i=1, #inventory.items, 1 do
            local item = inventory.items[i]
            if item.count > 0 then
                table.insert(elements, {label = item.label .. ' x' .. item.count..' - ('.. ((getItemyWeight(item.name)*item.count)/1000) ..' '.._U('measurement')..')', type = 'item_standard', value = item.name})
            end 
        end
  
        for i=1, #inventory.weapons, 1 do
            local weapon = inventory.weapons[i]
            table.insert(elements, {
                label = ESX.GetWeaponLabel(weapon.name) .. ' [' .. weapon.ammo .. '] - ('..(getItemyWeight(weapon.name)/1000)..' '.._U('measurement')..')', 
                type = 'item_weapon', 
                value = weapon.name, 
                ammo = weapon.ammo
            })
        end
  
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'car_inventory', {
            title    = plate .. ' - ' .. (inventory.weight/1000) .. " / "..(max/1000).._U('measurement'),
            align    = 'top-right',
            elements = elements,
        }, function(data, menu)
            
  
            if data.current.type == 'item_weapon' then
  
                menu.close()
  
                
                if not HasPedGotWeapon(PlayerPedId(), GetHashKey(data.current.value)) then	
                    local playerPed = GetPlayerPed(-1)
                    local vehicle = VehicleInFront()
                    if not canReachVehicle(playerPed, vehicle) then
                        ESX.ShowNotification("je bent te ver weg gegaan!")
                        return
                    end
                    TriggerServerEvent('esx_trunk:getItem', plate, data.current.type, data.current.value, data.current.ammo)
                else
                    ESX.ShowNotification("Je hebt dit wapen al!")
                end
  
                OpenCoffreInventoryMenu(plate,max)
                ESX.ShowNotification(("Gewicht:~g~ %skg / %skg"):format(inventory.weight/1000, max/1000))
            elseif data.current.type == "deposer" then
                ESX.UI.Menu.CloseAll()
                OpenPlayerInventoryMenu(owner,plate,max,inventory.weight)
            else
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'get_item_count', {
                title = _U('quantity'),
                }, function(data2, menu) 
                    local quantity = tonumber(data2.value)
    
                    if quantity == nil or quantity < 1 then
                        menu2.close()
                        ESX.ShowNotification(_U('invalid_quantity'))
                    else   
                        menu.close()
    
                        local vehFront = VehicleInFront()
                        local x,y,z = table.unpack(GetEntityCoords(GetPlayerPed(-1),true))
                        local closecar = GetClosestVehicle(x, y, z, 4.0, 0, 71)
                
                        if vehFront > 0 and closecar ~= nil and GetPedInVehicleSeat(closecar, -1) ~= GetPlayerPed(-1) then
                            local playerPed = GetPlayerPed(-1)
                            local vehicle = VehicleInFront()
                            if not canReachVehicle(playerPed, vehicle) then
                                ESX.ShowNotification("je bent te ver weg gegaan!")
                                return
                            end
                            TriggerServerEvent('esx_trunk:getItem', plate, data.current.type, data.current.value, quantity)
                        else
                            ESX.ShowNotification("Voertuig is te ver weg gegaan!")
                        end
                        OpenCoffreInventoryMenu(plate,max)
                        ESX.ShowNotification(("Gewicht:~g~ %skg / %skg"):format(inventory.weight/1000, max/1000))
                    end 
                end,function(data2,menu)
                    menu.close()
                end)  
            end  
        end,function(data, menu)
            menu.close()
        end)
    end, plate)
end
  
  
function OpenPlayerInventoryMenu(owner,plate,max,weight)
  
    ESX.TriggerServerCallback('esx_trunk:getPlayerInventory', function(inventory)
  
        local elements = {}
        table.insert(elements, {label = _U('dirty_money') .. inventory.blackMoney, type = 'item_account', value = 'black_money'})
  
        for i=1, #inventory.items, 1 do 
            local item = inventory.items[i]
  
            if item.count > 0 then
                table.insert(elements, {label = item.label .. ' x' .. item.count..' - ('.. ((getItemyWeight(item.name)*item.count)/1000) ..' '.._U('measurement')..')', type = 'item_standard', value = item.name})
            end 
        end
  
        local playerPed  = GetPlayerPed(-1)
        local weaponList = ESX.GetWeaponList()
  
        for i=1, #weaponList, 1 do
  
            local weaponHash = GetHashKey(weaponList[i].name)
  
            if HasPedGotWeapon(playerPed,  weaponHash,  false) and weaponList[i].name ~= 'WEAPON_UNARMED' then
                local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
                table.insert(elements, {label = weaponList[i].label .. ' [' .. ammo .. '] - ('..(getItemyWeight(weaponList[i].name)/1000)..' '.._U('measurement')..')', type = 'item_weapon', value = weaponList[i].name, ammo = ammo})
            end
        end
  
        ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'player_inventory', {
            title    = plate .. ' - ' .. (weight/1000) .. " / "..(max/1000)..' '.._U('measurement'), 
            align    = 'top-right',
            elements = elements,
        },function(data, menu)
  
            if data.current.type == 'item_weapon' then 
                menu.close()
  
                local playerPed = GetPlayerPed(-1)
                local vehicle = VehicleInFront()
                if not canReachVehicle(playerPed, vehicle) then
                    ESX.ShowNotification("je bent te ver weg gegaan!")
                    return
                end
                TriggerServerEvent('esx_trunk:putItem', plate, data.current.type, data.current.value, data.current.ammo, max, myVeh)
                OpenCoffreInventoryMenu(plate, max)
                weight = weight + (getItemyWeight(data.current.value))
                ESX.ShowNotification(("Gewicht:~g~ %skg / %skg"):format(weight/1000, max/1000))
            else
  
                ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'put_item_count', {
                    title = _U('quantity'),
                },function(data2, menu2)
                    local quantity = tonumber(data2.value)
    
                    if quantity == nil or quantity < 1 then
                        ESX.ShowNotification(_U('invalid_quantity'))
                    else
                        menu2.close()
    
                        local playerPed = GetPlayerPed(-1)
                        local vehicle = VehicleInFront()
                        if not canReachVehicle(playerPed, vehicle) then
                            ESX.ShowNotification("je bent te ver weg gegaan!")
                            return
                        end
                        TriggerServerEvent('esx_trunk:putItem', plate, data.current.type, data.current.value, tonumber(data2.value),max, myVeh)
                        weight = weight + (getItemyWeight(data.current.value) * tonumber(data2.value))
                        OpenCoffreInventoryMenu(plate,max)
                        ESX.ShowNotification(("Gewicht:~g~ %skg / %skg"):format(weight/1000, max/1000))
                    end
                end,function(data2,menu2)
                    menu2.close()
                end)  
            end 
        end, function(data, menu)
            menu.close()
            OpenCoffreInventoryMenu(plate, max)
        end)
  
    end)
  
end
  
function all_trim(s)
    if s then
        return s:match"^%s*(.*)":match"(.-)%s*$"
    else
        return 'noTagProvided'
    end
end
  
function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then 
                k = '"'..k..'"' 
            end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
  
  
function inArray(needle, haystack)
    for k,v in pairs(haystack) do
        if string.lower(k) == string.lower(needle) then
            return true
        end
    end
    return false
end
  