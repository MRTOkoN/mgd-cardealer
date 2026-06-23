/*

* Copyright (c) 2026 Mikhail Abramov
*
* Author: Mikhail Abramov
* GitHub: https://github.com/MRTOkoN
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
* ```
  https://www.apache.org/licenses/LICENSE-2.0
  ```
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.

*/



local meta = FindMetaTable('Player')
local meta2 = FindMetaTable('Entity')

local letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
local Hudreal = true
local icl = {
    'physgun_beam',
    'keyframe_rope',
    'stormfox_mapice',
    'phys_spring',
    'prop_dynamic'
}

MGD = MGD or {}
MGD.Cardealer = MGD.Cardealer or {}
MGD.Cardealer.SpawnPoints = {}
MGD.CacheModelMinsMaxs = {}
MGD.BuildVehicleCache = {}
MGD.CarDealerWheels = {}

math.randomseed(os.time())

local function onCooldown(pl, key, seconds, msg)
    if pl[key] and pl[key] > CurTime() then
        if msg then MGD.Cardealer.Notify(pl, msg, 1) end
        return true
    end
    pl[key] = CurTime() + seconds
    return false
end

local function refreshClientList(pl)
    MGD.Cardealer.GetListToPlayer(pl, function(vehicleList)
        netstream.Start(pl, 'MGD.Cardealer.BuyVehicle', vehicleList)
    end)
end

function MGD.Cardealer.Notify(pl, text, typ)
    if IsValid(pl) then
        DarkRP.notify(pl, typ or 0, 4, text)
    end
end

function MGD.Cardealer.SendWaypoint(pl, pos, name)
    netstream.Start(pl, 'MGD.Cardealer.Waypoint', pos, name)
end

MGD.CardealerList = {}

local simfphysCars = list.Get('simfphys_vehicles')
local simfphysLights = list.Get('simfphys_lights')

function MGD.Cardealer.AddCustomVehicle(category, class, price, camPos, usedCar)
    camPos = camPos or Vector()
    MySQLite.query(string.format([[REPLACE INTO mgd_cardealer_custom (class, category, price, camx, camy, camz, usedcar) VALUES (%s, %s, %s, %s, %s, %s, %s)]],
        MySQLite.SQLStr(class), MySQLite.SQLStr(category), MySQLite.SQLStr(price),
        MySQLite.SQLStr(camPos.x), MySQLite.SQLStr(camPos.y), MySQLite.SQLStr(camPos.z),
        usedCar and 1 or 0))
    MGD.Cardealer.LoadCustomVehicles()
end

function MGD.Cardealer.RemoveCustomVehicle(class)
    MySQLite.query(string.format([[DELETE FROM mgd_cardealer_custom WHERE class = %s]], MySQLite.SQLStr(class)))
    MGD.Cardealer.LoadCustomVehicles()
end

function MGD.Cardealer.GetCustomVehicles(callback)
    MySQLite.query([[SELECT * FROM mgd_cardealer_custom]], function(data)
        local result = {}
        for _, row in pairs(data or {}) do
            result[row.category] = result[row.category] or {}
            result[row.category][row.class] = {
                price = tonumber(row.price),
                camPos = Vector(tonumber(row.camx), tonumber(row.camy), tonumber(row.camz)),
                usedCar = tobool(row.usedcar)
            }
        end
        callback(result)
    end)
end

function MGD.Cardealer.LoadCustomVehicles()
    MGD.Cardealer.GetCustomVehicles(function(custom)
        MGD.Cardealer.CreateList(custom)
    end)
end

function meta:OpenCardealerMenu()
    MGD.Cardealer.GetListToPlayer(self, function(vehicleList, categories)
        netstream.Start(self, 'MGD.CarDealer.GetList', vehicleList, categories, nil)
    end)
end

function meta:OpenCardealerUsedMenu()
    if !MGD.Cardealer.Config.UsedDealer.Enabled then return end
    MGD.Cardealer.GetListToPlayer(self, function(vehicleList)
        MGD.Cardealer.GetFormatedSellList(function(sellList)
            for k, v in pairs(sellList) do
                table.insert(vehicleList, v)
            end
            netstream.Start(self, 'MGD.CarDealer.GetList', vehicleList, MGD.UsedCarsCategories, true)
        end)
    end)
end

function meta:GetVehiclesUserFormat(callback)
    self:GetVehicles(function(vehicles)
        MGD.Cardealer.VehiclesToUser(vehicles, function(vehiclesToUser)
            callback(vehiclesToUser)
        end)
    end)
end

function meta:HasCar(id, callback)
    MGD.Cardealer.GetVehicle(id, function(data)
        if !data then callback(false) return end
        callback(data.steamid == self:SteamID64(), data)
    end)
end

function meta:GetVehicles(callback)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer WHERE steamid = %s]], MySQLite.SQLStr(self:SteamID64())), function(data)
        callback(data or {})
    end)
end

function meta:GetNearestCarSpawnPoint(mdl)
    return MGD.Cardealer.GetNearestSpawnPoint(self:GetPos(), mdl)
end

function meta:SetSpawnedCar(ent)
    return self:SetNWEntity('MGD.SpawnCar', ent)
end

function meta:GetSpawnedCar()
    return self:GetNWEntity('MGD.SpawnCar')
end

function meta:DeleteVehicle()
    local vehicle = self:GetSpawnedCar()
    if IsValid(vehicle) then
        vehicle:Remove()
    end
end

function meta2:SetCardealerColor(color, set)
    self:SetProxyColor({color, color, Color(15, 15, 15)})
    if self.cardealerID and !set then
        MGD.Cardealer.UpdateData(self.cardealerID, nil, nil, nil, self:GetCardealerColor())
    end
end

function meta2:GetCardealerColor()
    local color = self:GetProxyColor()[1]
    return Color(color[1]*255, color[2]*255, color[3]*255)
end

function MGD.Cardealer.DatabaseSetup()
    local AUTOINCREMENT = MySQLite.isMySQL() and "AUTO_INCREMENT" or "AUTOINCREMENT"

    MySQLite.query([[
        CREATE TABLE IF NOT EXISTS mgd_cardealer (
            id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
            steamid VARCHAR(20) NOT NULL,
            vehicle VARCHAR(255) NOT NULL,
            plate VARCHAR(50) NOT NULL
        )
    ]])

    MySQLite.query([[
        CREATE TABLE IF NOT EXISTS mgd_cardealer_data (
            id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
            health INTEGER NOT NULL,
            fuel INTEGER NOT NULL,
            colorR INTEGER NOT NULL,
            colorG INTEGER NOT NULL,
            colorB INTEGER NOT NULL,
            wheelFL BOOLEAN,
            wheelFR BOOLEAN,
            wheelRL BOOLEAN,
            wheelRR BOOLEAN
        )
    ]])

    MySQLite.query([[
        CREATE TABLE IF NOT EXISTS mgd_cardealer_usedcarslist (
            id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
            carID INTEGER NOT NULL,
            steamid VARCHAR(20) NOT NULL,
            price INTEGER NOT NULL
        )
    ]])

    MySQLite.query([[
        CREATE TABLE IF NOT EXISTS mgd_cardealer_spawnpoints (
            id INTEGER NOT NULL PRIMARY KEY ]]..AUTOINCREMENT..[[,
            map VARCHAR(64) NOT NULL,
            px REAL, py REAL, pz REAL,
            ax REAL, ay REAL, az REAL
        )
    ]])

    MySQLite.query([[
        CREATE TABLE IF NOT EXISTS mgd_cardealer_custom (
            class VARCHAR(255) NOT NULL PRIMARY KEY,
            category VARCHAR(255) NOT NULL,
            price INTEGER NOT NULL,
            camx REAL, camy REAL, camz REAL,
            usedcar BOOLEAN
        )
    ]])
end

function MGD.Cardealer.GenerateLicensePlate()
    local format = MGD.Cardealer.Config.Plate
    local parts = {}

    for i = 1, format.Letters do
        local index = math.random(1, #letters)
        parts[#parts + 1] = letters:sub(index, index)
    end

    for i = 1, format.Digits do
        parts[#parts + 1] = math.random(0, 9)
    end

    return table.concat(parts)
end

function MGD.Cardealer.WriteData(class)
    local vehicle = simfphysCars[class]
    local health = !vehicle.Members.MaxHealth and math.floor((1000 + vehicle.Members.Mass * 0.75 / 3)) or vehicle.Members.MaxHealth
    MySQLite.query(string.format([[INSERT INTO mgd_cardealer_data (health, fuel, colorR, colorG, colorB, wheelFL, wheelFR, wheelRL, wheelRR) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)]], MySQLite.SQLStr(health), MySQLite.SQLStr(vehicle.Members.FuelTankSize), 255, 255, 255, 'FALSE', 'FALSE', 'FALSE', 'FALSE'))
end

function MGD.Cardealer.WriteCar(steamid, carClass)
    local licensePlate = MGD.Cardealer.GenerateLicensePlate()
    MySQLite.query(string.format([[INSERT INTO mgd_cardealer (steamid, vehicle, plate) VALUES (%s, %s, %s)]], MySQLite.SQLStr(steamid), MySQLite.SQLStr(carClass), MySQLite.SQLStr(licensePlate)))
    MGD.Cardealer.WriteData(carClass)
end

function MGD.Cardealer.UpdateCar(id, steamid, plate)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer WHERE id = %s]], MySQLite.SQLStr(id)), function(data)
        data = data and data[1]
        if !data then return end
        local query = "UPDATE mgd_cardealer SET " ..
            "steamid = " .. MySQLite.SQLStr(steamid or data.steamid) .. "," ..
            "plate = " .. MySQLite.SQLStr(plate or data.plate) ..
            " WHERE id = " .. MySQLite.SQLStr(id)
        MySQLite.query(query)
    end)
end

function MGD.Cardealer.RemoveData(id)
    MySQLite.query(string.format([[DELETE FROM mgd_cardealer_data WHERE id = %s]], MySQLite.SQLStr(id)))
end

function MGD.Cardealer.RemoveCar(id)
    MySQLite.query(string.format([[DELETE FROM mgd_cardealer WHERE id = %s]], MySQLite.SQLStr(id)))
    MGD.Cardealer.RemoveData(id)
    MySQLite.query(string.format([[DELETE FROM mgd_cardealer_usedcarslist WHERE carID = %s]], MySQLite.SQLStr(id)))
end

function MGD.Cardealer.UpdateData(id, health, fuel, color, wheelFL, wheelFR, wheelRL, wheelRR, engineWear)
    color = color or {}

    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer_data WHERE id = %s]], MySQLite.SQLStr(id)), function(data)
        data = data and data[1]
        if !data then return end
        local query = "UPDATE mgd_cardealer_data SET " ..
            "health = " .. MySQLite.SQLStr(health or data.health) .. "," ..
            "fuel = " .. MySQLite.SQLStr(fuel or data.fuel) .. "," ..
            "colorR = " .. MySQLite.SQLStr(color.r or data.colorR) .. "," ..
            "colorG = " .. MySQLite.SQLStr(color.g or data.colorG) .. "," ..
            "colorB = " .. MySQLite.SQLStr(color.b or data.colorB) .. "," ..
            "wheelFL = " .. MySQLite.SQLStr(wheelFL == nil and data.wheelFL or wheelFL) .. "," ..
            "wheelFR = " .. MySQLite.SQLStr(wheelFR == nil and data.wheelFR or wheelFR) .. "," ..
            "wheelRL = " .. MySQLite.SQLStr(wheelRL == nil and data.wheelRL or wheelRL) .. "," ..
            "wheelRR = " .. MySQLite.SQLStr(wheelRR == nil and data.wheelRR or wheelRR) ..
            " WHERE id = " .. MySQLite.SQLStr(id)
        MySQLite.query(query)
    end)
end

function MGD.Cardealer.GetVehicle(id, callback)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer WHERE id = %s]], MySQLite.SQLStr(id)), function(data)
        callback((data or {})[1])
    end)
end

function MGD.Cardealer.GetVehicleData(id, callback)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer_data WHERE id = %s]], MySQLite.SQLStr(id)), function(data)
        callback(((data or {})[1]) or {})
    end)
end

function MGD.Cardealer.AddCarToSell(carID, steamid, price)
    MySQLite.query(string.format([[INSERT INTO mgd_cardealer_usedcarslist (carID, steamid, price) VALUES (%s, %s, %s)]], MySQLite.SQLStr(carID), MySQLite.SQLStr(steamid), MySQLite.SQLStr(price)))
    MGD.Cardealer.UpdateCar(carID, -1)
end

function MGD.Cardealer.RemoveCarFromSell(carID, steamid)
    MySQLite.query(string.format([[DELETE FROM mgd_cardealer_usedcarslist WHERE carID = %s]], MySQLite.SQLStr(carID)), function()
        MGD.Cardealer.UpdateCar(carID, steamid)
    end)
end

function MGD.Cardealer.GetCarOnSell(carID, callback)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer_usedcarslist WHERE carID = %s]], MySQLite.SQLStr(carID)), function(data)
        if !data or !data[1] then callback(false) return end
        callback(true, data[1])
    end)
end

function MGD.Cardealer.GetSellList(callback)
    MySQLite.query([[SELECT * FROM mgd_cardealer_usedcarslist]], function(data)
        callback((data or {}))
    end)
end

function MGD.Cardealer.AddSpawnPoint(position, angles)
    MySQLite.query(string.format([[INSERT INTO mgd_cardealer_spawnpoints (map, px, py, pz, ax, ay, az) VALUES (%s, %s, %s, %s, %s, %s, %s)]],
        MySQLite.SQLStr(game.GetMap()),
        MySQLite.SQLStr(position.x), MySQLite.SQLStr(position.y), MySQLite.SQLStr(position.z),
        MySQLite.SQLStr(angles.p), MySQLite.SQLStr(angles.y), MySQLite.SQLStr(angles.r)))
    MGD.Cardealer.SpawnPointsInit()
end

function MGD.Cardealer.SpawnPointsInit()
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer_spawnpoints WHERE map = %s]], MySQLite.SQLStr(game.GetMap())), function(data)
        local points = {}
        for _, row in pairs(data or {}) do
            points[#points + 1] = {
                pos = Vector(tonumber(row.px), tonumber(row.py), tonumber(row.pz)),
                ang = Angle(tonumber(row.ax), tonumber(row.ay), tonumber(row.az))
            }
        end
        MGD.Cardealer.SpawnPoints = points
    end)
end

function MGD.Cardealer.RemoveNearestSpawnPoint(pos)
    MySQLite.query(string.format([[SELECT * FROM mgd_cardealer_spawnpoints WHERE map = %s]], MySQLite.SQLStr(game.GetMap())), function(data)
        if !data or table.IsEmpty(data) then return end

        local bestID, bestDist
        for _, row in pairs(data) do
            local d = pos:Distance(Vector(tonumber(row.px), tonumber(row.py), tonumber(row.pz)))
            if !bestDist or d < bestDist then
                bestDist = d
                bestID = row.id
            end
        end

        if bestID then
            MySQLite.query(string.format([[DELETE FROM mgd_cardealer_spawnpoints WHERE id = %s]], MySQLite.SQLStr(bestID)))
            MGD.Cardealer.SpawnPointsInit()
        end
    end)
end

function MGD.BuildVehicleInfo(class)
    local vehInfo = simfphysCars[class]
    if !vehInfo then return end

    if !MGD.BuildVehicleCache[class] then
        local radius

        if vehInfo.Members.CustomWheelModel then
            local wheel = ents.Create('prop_physics')
            wheel.NotCheckAPG = true
            wheel:SetModel(vehInfo.Members.CustomWheelModel)
            radius = (wheel:OBBMaxs() - wheel:OBBMins())
            table.insert(MGD.CarDealerWheels, wheel)
        end

        local FrontWheelRadius = vehInfo.Members.FrontWheelRadius or (math.max(radius.x, radius.y, radius.z) * 0.5)
        local RearWheelRadius = vehInfo.Members.RearWheelRadius or FrontWheelRadius
        local WheelRad = RearWheelRadius

        local FrontWheelPowered = vehInfo.Members.PowerBias ~= 1

        if FrontWheelPowered and RearWheelRadius then
            WheelRad = math.max(FrontWheelRadius, RearWheelRadius)
        elseif FrontWheelPowered then
            WheelRad = FrontWheelRadius
        end

        local Mass = vehInfo.Members.Mass + 1
        for i = 1, 4 do
            Mass = Mass + vehInfo.Members.Mass / 32
        end

        local data = {}
        data["torque"] = vehInfo.Members.PeakTorque * (WheelRad / 10) * vehInfo.Members.Efficiency * (1 + (vehInfo.Members.Turbocharged and 0.3 or 0) + (vehInfo.Members.Supercharged and 0.48 or 0))
        data["horsepower"] = (data["torque"] * vehInfo.Members.LimitRPM / 9548.8) * 1.34
        data["maxspeed"] = ((vehInfo.Members.LimitRPM * vehInfo.Members.Gears[table.Count(vehInfo.Members.Gears)] * vehInfo.Members.DifferentialGear) * 3.14 * WheelRad * 2) / 52
        data["weight"] = Mass

        local toSize = Hudreal and (1/0.75) or 1

        data["maxspeed"] = math.Round(data["maxspeed"])
        data["horsepower"] = math.Round(data["horsepower"] * toSize)
        data["weight"] = math.Round(data["weight"])
        data["torque"] = math.Round(data["torque"] * toSize)

        MGD.BuildVehicleCache[class] = data
    end

    return MGD.BuildVehicleCache[class]
end

function MGD.Cardealer.GetFormatedSellList(callback)
    MGD.Cardealer.GetSellList(function(data)
        local tableSell = {}
        if !data then return end

        local vehiclesCount = table.Count(data)
        local vehicleList = {}
        local data3All = {}

        if table.IsEmpty(data) then
            callback({})
        end

        for k, v in pairs(data or {}) do
            MGD.Cardealer.GetVehicle(v.carID, function(data2)
                if !data2 then
                    vehiclesCount = vehiclesCount - 1
                    if table.Count(tableSell) == table.Count(data3All) and table.Count(tableSell) == vehiclesCount then
                        if callback then callback(vehicleList) end
                    end
                    return
                end
                tableSell[k] = {veh = data2.vehicle, dataIndex = k, plate = data2.plate}
                MGD.Cardealer.GetVehicleData(v.carID, function(data3)
                    data3All[k] = data3
                    if table.Count(tableSell) == table.Count(data3All) and table.Count(tableSell) == vehiclesCount then
                        for _, carClass in pairs(tableSell) do
                            local dataPage = data[carClass.dataIndex]
                            local vehData = data3All[_]
                            local vehicleData = MGD.Cardealer.GetVehicleInList(carClass.veh)
                            local vehicle = MGD.Cardealer.GetVehicleTable(carClass.veh, 'Used', {})
                            if vehicle then
                                vehicle.sell = true
                                vehicle.price = tonumber(dataPage.price)
                                vehicle.steamid = dataPage.steamid
                                vehicle.id = dataPage.carID
                                vehicle.health = vehData.health
                                vehicle.fuel = vehData.fuel
                                vehicle.plate = carClass.plate
                                vehicle.color = Color(tonumber(vehData.colorR), tonumber(vehData.colorG), tonumber(vehData.colorB))
                                vehicle.camPos = vehicleData and vehicleData.camPos
                                table.insert(vehicleList, vehicle)
                            end
                        end
                        if callback then
                            callback(vehicleList)
                        end
                    end
                end)
            end)
        end
    end)
end

function MGD.Cardealer.VehiclesToUser(vehicles, callback)
    local vehiclesToUser = table.Copy(vehicles)
    local vehiclesCount = 0
    for k, v in pairs(vehicles) do
        MGD.Cardealer.GetVehicleData(v.id, function(data)
            vehiclesToUser[k].health = data.health
            vehiclesToUser[k].fuel = data.fuel
            vehiclesToUser[k].color = Color(tonumber(data.colorR), tonumber(data.colorG), tonumber(data.colorB))
            vehiclesCount = vehiclesCount + 1

            if vehiclesCount == table.Count(vehicles) then
                callback(vehiclesToUser)
            end
        end)
    end
    if table.IsEmpty(vehicles) then
        callback({})
    end
end

function MGD.Cardealer.GetVehicleInList(class)
    for k, v in pairs(MGD.CardealerList) do
        if v.class == class then return v end
    end
end

function MGD.Cardealer.GetModelMinsMaxs(mdl)
    if !MGD.CacheModelMinsMaxs[mdl] then
        local sizeTest = ents.Create('prop_physics')
        sizeTest:SetModel(mdl)

        local mins, maxs = sizeTest:OBBMins(), sizeTest:OBBMaxs()
        sizeTest:Remove()

        MGD.CacheModelMinsMaxs[mdl] = {mins = mins, maxs = maxs}
    end
    return MGD.CacheModelMinsMaxs[mdl].mins, MGD.CacheModelMinsMaxs[mdl].maxs
end

local function spawnPointClear(point, mins, maxs)
    local findMins = LocalToWorld(mins, Angle(), point.pos - Vector(0, 0, 300), point.ang)
    local findMaxs = LocalToWorld(maxs, Angle(), point.pos + Vector(0, 0, 300), point.ang)
    local found = ents.FindInBox(findMins, findMaxs)
    if table.IsEmpty(found) then return true end

    for _, ent in pairs(found) do
        if table.HasValue(icl, ent:GetClass()) then continue end
        if (ent:GetClass() == 'prop_physics' and !ent:CPPIGetOwner()) or ent:GetClass() == 'base_ai' then continue end
        return false
    end

    return true
end

function MGD.Cardealer.GetNearestSpawnPoint(pos, mdl)
    local points = MGD.Cardealer.SpawnPoints
    if table.IsEmpty(points) then return end

    local nearestPoint
    local mins, maxs = MGD.Cardealer.GetModelMinsMaxs(mdl)

    for _, point in pairs(points) do
        local closer = !nearestPoint or nearestPoint.pos:Distance(pos) > point.pos:Distance(pos)
        if closer and spawnPointClear(point, mins, maxs) then
            nearestPoint = table.Copy(point)
        end
    end

    return nearestPoint
end

function MGD.Cardealer.GetNearestReturnPoint(pos)
    local points = MGD.Cardealer.SpawnPoints
    if table.IsEmpty(points) then return end

    local nearestPoint

    for _, point in pairs(points) do
        if !nearestPoint or nearestPoint.pos:Distance(pos) > point.pos:Distance(pos) then
            nearestPoint = table.Copy(point)
        end
    end

    return nearestPoint
end

function MGD.Cardealer.SpawnVehicle(pl, vehicleTable, vehicleData)
    if IsValid(pl:GetSpawnedCar()) then
        MGD.Cardealer.Notify(pl, 'Store your car first!', 1)
        return
    end

    local simfTable = simfphysCars[vehicleTable.vehicle]

    local spawnPoint = pl:GetNearestCarSpawnPoint(simfTable.Model)
    if !spawnPoint then
        MGD.Cardealer.Notify(pl, 'Nowhere to spawn the car right now, try again later!', 1)
        return
    end

    local spawnedVehicle = simfphys.SpawnVehicle(nil, spawnPoint.pos, spawnPoint.ang, simfTable.Model, vehicleTable.vehicle, vehicleTable.vehicle, simfTable, true)
    if !IsValid(spawnedVehicle) then return end

    pl:SetSpawnedCar(spawnedVehicle)
    spawnedVehicle:SetNWString('MGD.LicensePlate', vehicleTable.plate)
    spawnedVehicle:SetNWInt('MGD.CarID', vehicleTable.id)
    spawnedVehicle.cardealerID = vehicleTable.id
    spawnedVehicle.ownerSteamID = vehicleTable.steamid
    spawnedVehicle.engineWear = tonumber(vehicleData.engineWear)
    spawnedVehicle.spawnOwner = pl

    local function saveVehicleData(veh)
        if !IsValid(veh) then return end

        local fuel, health = veh:GetFuel(), veh:GetCurHealth()

        MGD.Cardealer.UpdateData(vehicleTable.id, health, fuel, nil, veh.Wheels[1]:GetDamaged(), veh.Wheels[2]:GetDamaged(), veh.Wheels[3]:GetDamaged(), veh.Wheels[4]:GetDamaged(), veh.engineWear)
    end

    spawnedVehicle:CallOnRemove('MGD.CallOnRemove.CardealerVehicleSpawned', function(vehicle)
        local vehicleOwner = spawnedVehicle.spawnOwner
        if IsValid(vehicleOwner) then
            vehicleOwner:SetSpawnedCar()
            saveVehicleData(vehicle)
        end
    end)

    timer.Simple(0.7, function()
        spawnedVehicle:SetCardealerColor(Color(tonumber(vehicleData.colorR), tonumber(vehicleData.colorG), tonumber(vehicleData.colorB)), true)
        spawnedVehicle:SetCurHealth(tonumber(vehicleData.health))
        spawnedVehicle:SetFuel(tonumber(vehicleData.fuel))
        spawnedVehicle:SetSkin(0)
        spawnedVehicle:SetBodyGroups('000000000000')

        spawnedVehicle.Wheels[1]:SetDamaged(tobool(vehicleData.wheelFL))
        spawnedVehicle.Wheels[2]:SetDamaged(tobool(vehicleData.wheelFR))
        spawnedVehicle.Wheels[3]:SetDamaged(tobool(vehicleData.wheelRL))
        spawnedVehicle.Wheels[4]:SetDamaged(tobool(vehicleData.wheelRR))
    end)

    local timerName = 'MGD.Cardealer.SaveVehicle.' .. spawnedVehicle:EntIndex() .. '.' .. vehicleTable.id

    timer.Create(timerName, 30, 0, function()
        if IsValid(spawnedVehicle) then
            saveVehicleData(spawnedVehicle)
        else
            timer.Remove(timerName)
        end
    end)

    MGD.Cardealer.SendWaypoint(pl, spawnPoint.pos, simfTable.Name)
    netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
end

function MGD.Cardealer.GetVehicleTable(class, categoryName, vehicleData)
    vehicleData = vehicleData or {}
    local simfphysCar = simfphysCars[class]
    if !simfphysCar then return end

    local simfphysCarLights = simfphysLights[simfphysCar.Members.LightsTable] or {}
    local vehInfo = MGD.BuildVehicleInfo(class) or {}
    local vehData = {
        ["name"] = simfphysCar.Name,
        ["price"] = vehicleData.price,
        ["category"] = categoryName,
        ["acquired"] = false,
        ["weight"] = simfphysCar.Members.Mass or 500,
        ["driveType"] = simfphysCar.Members.PowerBias or 0,
        ["turnAngle"] = simfphysCar.Members.CustomSteerAngle or 30,
        ["seats"] = #(simfphysCar.Members.PassengerSeats or {}) + 1,
        ["enginePower"] = vehInfo.horsepower or 50,
        ["fuelType"] = simfphysCar.Members.FuelType or 0,
        ["fuelVolume"] = simfphysCar.Members.FuelTankSize or 50,
        ["grip"] = simfphysCar.Members.MaxGrip or 0,
        ["model"] = simfphysCar.Model,
        ['topSpeed'] = vehInfo.maxspeed,
        ['wheels'] = {
            model = simfphysCar.Members.CustomWheelModel,
            angleOffset = simfphysCar.Members.CustomWheelAngleOffset,
            wheels = {
                fl = simfphysCar.Members.CustomWheelPosFL,
                fr = simfphysCar.Members.CustomWheelPosFR,
                rl = simfphysCar.Members.CustomWheelPosRL,
                rr = simfphysCar.Members.CustomWheelPosRR
            }
        },
        ['camPos'] = vehicleData.camPos,
        ['subMaterials'] = simfphysCarLights.SubMaterials,
        ['maxHealth'] = simfphysCar.Members.MaxHealth or math.floor(1000 + simfphysCar.Members.Mass * 0.75 / 3),
        ['class'] = class,
        ["usedCar"] = vehicleData.usedCar,
        ['armored'] = simfphysCar.Members.IsArmored,
        ['bulletProofTires'] = simfphysCar.Members.BulletProofTires
    }
    return vehData
end

function MGD.Cardealer.SpawnUsedCarsDealer(pos, ang, mdl)
    if IsValid(MGD.CardealerUsedCarsDealerNPC) then
        MGD.CardealerUsedCarsDealerNPC:Remove()
    end

    local dealer = ents.Create("base_ai")
    dealer:SetPos(pos + Vector(0, 0, 10))
    dealer:SetAngles(ang)
    dealer:SetHullType(HULL_HUMAN)
    dealer:SetHullSizeNormal()
    dealer:SetNPCState(NPC_STATE_SCRIPT)
    dealer:SetSolid(SOLID_BBOX)
    dealer:CapabilitiesAdd(bit.bor(CAP_ANIMATEDFACE, CAP_TURN_HEAD))
    dealer:SetUseType(SIMPLE_USE)
    dealer:Spawn()
    dealer:DropToFloor()
    timer.Simple(0, function()
        dealer:SetModel(mdl)
    end)

    function dealer:AcceptInput(name, activator, caller)
        if name == "Use" and IsValid(caller) then
            caller:OpenCardealerUsedMenu()
        end
    end

    MGD.CardealerUsedCarsDealerNPC = dealer
end

function MGD.Cardealer.GetListToPlayer(pl, callback)
    pl:GetVehiclesUserFormat(function(vehicles)
        local vehicleList = table.Copy(MGD.CardealerList)
        local categories = table.Copy(MGD.CardealerCategories)

        for k, v in pairs(vehicles) do
            local vehicleData = MGD.Cardealer.GetVehicleInList(v.vehicle)
            if !vehicleData then continue end
            local vehTable = MGD.Cardealer.GetVehicleTable(v.vehicle, 'Owned')
            if !vehTable then continue end
            for index, vehicleValue in pairs(v) do
                if index == 'steamid' then continue end
                vehTable[index] = vehicleValue
            end
            vehTable.camPos = vehicleData.camPos
            vehTable.price = vehicleData.price
            vehTable.armored = vehicleData.armored
            vehTable.bulletProofTires = vehicleData.bulletProofTires
            vehTable.bought = true

            table.insert(vehicleList, vehTable)
        end

        callback(vehicleList, categories)
    end)
end

function MGD.Cardealer.DeleteAllVehicles()
    for _, pl in ipairs(player.GetAll()) do
        pl:DeleteVehicle()
    end
end

function MGD.Cardealer.SpawnUsedCars()
    local cfg = MGD.Cardealer.Config.UsedDealer
    if !cfg.Enabled then return end
    MGD.Cardealer.SpawnUsedCarsDealer(cfg.Pos, cfg.Ang, cfg.Model)
end

function MGD.Cardealer.InitNetworkHooks()
    local Cfg = MGD.Cardealer.Config
    local Money = MGD.Cardealer.Money

    netstream.Hook('MGD.Cardealer.BuyVehicle', function(pl, vehicle)
        if onCooldown(pl, 'MCBVCD', Cfg.Cooldowns.Buy, 'Not so fast!') then return end
        if !simfphysCars[vehicle] then return end

        local vehicleTable = MGD.Cardealer.GetVehicleInList(vehicle)
        if !vehicleTable then return end

        if vehicleTable.usedCar then
            if !Cfg.UsedDealer.Enabled or !IsValid(MGD.CardealerUsedCarsDealerNPC) then return end
            if pl:GetPos():Distance(MGD.CardealerUsedCarsDealerNPC:GetPos()) > 500 then
                netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
                MGD.Cardealer.Notify(pl, 'This car is only sold at the used car dealership.', 1)
                return
            end
        end

        Money.Take(pl, vehicleTable.price, string.format('Car purchase %s', vehicleTable.name), function(ok, err)
            if !ok then MGD.Cardealer.Notify(pl, err or 'Failed to pay for the car!', 0) return end

            MGD.Cardealer.WriteCar(pl:SteamID64(), vehicle)
            refreshClientList(pl)
            MGD.Cardealer.Notify(pl, string.format('Congratulations! You bought the "%s" car!', vehicleTable.name), 4)
        end)
    end)

    netstream.Hook('MGD.Cardealer.SellVehicle', function(pl, vehicle)
        if onCooldown(pl, 'MCBVCD', Cfg.Cooldowns.Buy, 'Not so fast!') then return end

        local spawnedVehicle = pl:GetSpawnedCar()
        if IsValid(spawnedVehicle) then
            local carID = spawnedVehicle.cardealerID
            if carID and carID == vehicle then
                MGD.Cardealer.Notify(pl, 'Store the car first!', 1)
                return
            end
        end

        pl:HasCar(vehicle, function(hasCar, vehicleInfo)
            if !hasCar then MGD.Cardealer.Notify(pl, 'You do not own this car!', 1) return end

            local cardealerVehicleData = MGD.Cardealer.GetVehicleInList(vehicleInfo.vehicle)
            if !cardealerVehicleData then return end

            local sellPrice = math.Round(cardealerVehicleData.price / 100 * Cfg.Economy.SellBackPercent)
            Money.Give(pl, sellPrice, string.format('Car sale %s', cardealerVehicleData.name), function(ok, err)
                if !ok then MGD.Cardealer.Notify(pl, err or 'Failed to sell the car!', 0) return end

                MGD.Cardealer.RemoveCar(vehicle)
                refreshClientList(pl)
                MGD.Cardealer.Notify(pl, string.format('You sold the "%s" car for %s!', cardealerVehicleData.name, DarkRP.formatMoney(sellPrice)), 4)
            end)
        end)
    end)

    netstream.Hook('MGD.CarDealer.GetList', function(pl)
        if onCooldown(pl, 'MCDGLCD', Cfg.Cooldowns.GetList) then return end
        pl:OpenCardealerMenu()
    end)

    netstream.Hook('MGD.Cardealer.SpawnVehicle', function(pl, vehicleID)
        if !vehicleID or !tonumber(vehicleID) then return end
        if onCooldown(pl, 'MCSVCD', Cfg.Cooldowns.Spawn) then return end
        MGD.Cardealer.GetVehicle(vehicleID, function(data)
            if !data then return end
            pl:HasCar(vehicleID, function(hasCar, vehicleInfo)
                if hasCar then
                    MGD.Cardealer.GetVehicleData(vehicleID, function(data2)
                        MGD.Cardealer.SpawnVehicle(pl, data, data2)
                    end)
                end
            end)
        end)
    end)

    netstream.Hook('MGD.Cardealer.ReturnVehicle', function(pl, vehicleID)
        if !vehicleID or !tonumber(vehicleID) then return end
        if onCooldown(pl, 'MCSVCD', Cfg.Cooldowns.Spawn) then return end
        pl:HasCar(vehicleID, function(hasCar, vehicleInfo)
            if !hasCar then return end

            local spawnedVehicle = pl:GetSpawnedCar()
            if IsValid(spawnedVehicle) and spawnedVehicle.cardealerID and spawnedVehicle.cardealerID == vehicleID then
                local nearestReturnPoint = MGD.Cardealer.GetNearestReturnPoint(spawnedVehicle:GetPos())
                if !nearestReturnPoint then return end
                nearestReturnPoint = nearestReturnPoint.pos

                if nearestReturnPoint:Distance(spawnedVehicle:GetPos()) < 300 then
                    spawnedVehicle:Remove()
                    MGD.Cardealer.Notify(pl, 'You stored the car.', 4)
                else
                    MGD.Cardealer.SendWaypoint(pl, nearestReturnPoint, 'Parking spot')
                    MGD.Cardealer.Notify(pl, 'Drive the car to the nearest parking spot and try again.', 1)
                end

                netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
            end
        end)
    end)

    netstream.Hook('MGD.Cardealer.Used.SellCar', function(pl, vehicle, price)
        if !Cfg.UsedDealer.Enabled then return end
        if onCooldown(pl, 'MCBVCD', Cfg.Cooldowns.Buy, 'Not so fast!') then return end
        if !vehicle or !tonumber(vehicle) then return end

        price = math.floor(tonumber(price) or 0)
        if price < 1 or price > Cfg.Economy.MaxUsedPrice then
            MGD.Cardealer.Notify(pl, 'Invalid price!', 1)
            return
        end

        local spawnedVehicle = pl:GetSpawnedCar()
        if IsValid(spawnedVehicle) then
            local carID = spawnedVehicle.cardealerID
            if carID and carID == vehicle then
                MGD.Cardealer.Notify(pl, 'Store the car first!', 1)
                return
            end
        end

        MGD.Cardealer.GetVehicle(vehicle, function(vehicleData)
            if !vehicleData then return end
            pl:HasCar(vehicle, function(hasCar, vehicleInfo)
                if !hasCar then return end

                local vehicleTable = MGD.Cardealer.GetVehicleInList(vehicleData.vehicle)
                if !vehicleTable then return end

                Money.Take(pl, Cfg.Economy.UsedListingFee, string.format('Listing "%s" for sale (%s)', vehicleTable.name, vehicleData.plate), function(ok, err)
                    if ok then
                        MGD.Cardealer.AddCarToSell(vehicle, pl:SteamID64(), price)
                        MGD.Cardealer.Notify(pl, string.format('Car listed for sale for %s', DarkRP.formatMoney(price)), 0)
                    else
                        MGD.Cardealer.Notify(pl, err or 'There was a problem paying the fee!', 0)
                    end
                    netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
                end)
            end)
        end)
    end)

    netstream.Hook('MGD.Cardealer.RemoveFromSale', function(pl, vehicle)
        if !Cfg.UsedDealer.Enabled then return end
        if onCooldown(pl, 'MCBVCD', Cfg.Cooldowns.Buy, 'Not so fast!') then return end
        if !vehicle or !tonumber(vehicle) then return end

        MGD.Cardealer.GetCarOnSell(vehicle, function(carOnSell, data)
            if carOnSell and data.steamid == pl:SteamID64() then
                MGD.Cardealer.RemoveCarFromSell(vehicle, data.steamid)
                netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
                MGD.Cardealer.Notify(pl, 'Car removed from sale!', 0)
            end
        end)
    end)

    netstream.Hook('MGD.Cardealer.BuyVehicleFromPlayer', function(pl, vehicle)
        if !Cfg.UsedDealer.Enabled then return end
        if onCooldown(pl, 'MCBVCD', Cfg.Cooldowns.Used, 'Not so fast!') then return end
        if !vehicle or !tonumber(vehicle) then return end

        MGD.Cardealer.GetVehicle(vehicle, function(vehicleData)
            if !vehicleData then return end
            MGD.Cardealer.GetCarOnSell(vehicle, function(carOnSell, data)
                if !carOnSell then return end

                local buyerSteamID = pl:SteamID64()
                local ownerSteamID = data.steamid
                local vehicleTable = MGD.Cardealer.GetVehicleInList(vehicleData.vehicle)
                if !vehicleTable then return end
                if buyerSteamID == ownerSteamID then return end

                local amount = math.floor(tonumber(data.price) or 0)
                if amount < 1 then return end

                Money.UsedTransfer(pl, ownerSteamID, amount, string.format('Used car purchase "%s" (%s)', vehicleTable.name, vehicleData.plate), function(ok, err)
                    if !ok then MGD.Cardealer.Notify(pl, err or 'Payment error!', 0) return end

                    MGD.Cardealer.RemoveCarFromSell(vehicle, buyerSteamID)
                    refreshClientList(pl)
                    MGD.Cardealer.Notify(pl, string.format('Congratulations! You bought the "%s" car!', vehicleTable.name), 4)
                end)

                netstream.Start(pl, 'MGD.Cardealer.CloseMenu')
            end)
        end)
    end)

    netstream.Hook('MGD.Cardealer.GetCustomVehicles', function(pl)
        if onCooldown(pl, 'MCGCVCD', Cfg.Cooldowns.Admin) then return end
        if !pl:IsSuperAdmin() then return end
        MGD.Cardealer.GetCustomVehicles(function(custom)
            netstream.Start(pl, 'MGD.Cardealer.GetCustomVehicles', custom)
        end)
    end)

    netstream.Hook('MGD.Cardealer.AddCustomVehicle', function(pl, vehicleTable)
        if onCooldown(pl, 'MCGCVCD', Cfg.Cooldowns.Admin) then return end
        if !pl:IsSuperAdmin() then return end
        if !istable(vehicleTable) then return end
        if !isstring(vehicleTable.class) or !isstring(vehicleTable.category) then return end

        local price = tonumber(vehicleTable.price)
        if !price or price < 0 then return end

        local op = istable(vehicleTable.otherParameters) and vehicleTable.otherParameters or {}

        MGD.Cardealer.AddCustomVehicle(vehicleTable.category, vehicleTable.class, price, vehicleTable.camPos, op.usedCar and true or false)
        MGD.Cardealer.Notify(pl, 'Car added!', 4)
        netstream.Start(pl, 'MGD.Cardealer.CloseCustomVehicleMenu')
    end)

    netstream.Hook('MGD.Cardealer.RemoveCustomVehicle', function(pl, category, class)
        if onCooldown(pl, 'MCGCVCD', Cfg.Cooldowns.Admin) then return end
        if !pl:IsSuperAdmin() then return end
        if !isstring(class) then return end

        MGD.Cardealer.RemoveCustomVehicle(class)
        MGD.Cardealer.Notify(pl, string.format('Car "%s" removed!', class), 4)
        MGD.Cardealer.GetCustomVehicles(function(custom)
            netstream.Start(pl, 'MGD.Cardealer.GetCustomVehicles', custom)
        end)
    end)
end

hook.Add('InitPostEntity', 'MGD.InitPostEntity.LoadCardealer', function()
    MGD.Cardealer.SpawnUsedCars()
    MGD.Cardealer.SpawnPointsInit()
    MGD.Cardealer.InitNetworkHooks()
    MGD.Cardealer.LoadCustomVehicles()
end)

hook.Add('PlayerDisconnected', 'MGD.PlayerDisconnected.DeleteVehicle', function(pl)
    pl:DeleteVehicle()
end)

hook.Add('ShutDown', 'MGD.ShutDown.DeleteVehicles', MGD.Cardealer.DeleteAllVehicles)
hook.Add('PreCleanupMap', 'MGD.PreCleanupMap.DeleteVehicles', MGD.Cardealer.DeleteAllVehicles)
hook.Add('PostCleanupMap', 'MGD.PostCleanupMap.SpawnUsedCars', MGD.Cardealer.SpawnUsedCars)
hook.Add("DarkRPDBInitialized", "MGD.Cardealer.DatabaseSetup", MGD.Cardealer.DatabaseSetup)
