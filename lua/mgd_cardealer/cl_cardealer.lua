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



MGD = MGD or {}
MGD.Cardealer = MGD.Cardealer or {}

surface.CreateFont('Cardealer.14', { font = 'Roboto', size = 14, weight = 300, extended = true })
surface.CreateFont('Cardealer.15', { font = 'Roboto', size = 17, weight = 300, extended = true })
surface.CreateFont('Cardealer.18', { font = 'Roboto', size = 18, weight = 300, extended = true })
surface.CreateFont('Cardealer.20', { font = 'Roboto', size = 20, weight = 300, extended = true })
surface.CreateFont('Cardealer.32', { font = 'Roboto', size = 32, weight = 500, extended = true })
surface.CreateFont('Cardealer.64', { font = 'Roboto', size = 64, weight = 500, extended = true })

local cardealerWaypoint

hook.Add('HUDPaint', 'MGD.Cardealer.Waypoint', function()
    local wp = cardealerWaypoint
    if !wp then return end

    local ply = LocalPlayer()
    if CurTime() > wp.expire or (IsValid(ply) and ply:GetPos():Distance(wp.pos) < 200) then
        cardealerWaypoint = nil
        return
    end

    local scr = wp.pos:ToScreen()
    if !scr.visible then return end

    local dist = math.Round(ply:GetPos():Distance(wp.pos) / 52.49) .. ' m'
    draw.SimpleTextOutlined(wp.name, 'Cardealer.20', scr.x, scr.y - 18, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    draw.SimpleTextOutlined(dist, 'Cardealer.14', scr.x, scr.y, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
    surface.SetDrawColor(208, 45, 124, 255)
    surface.DrawRect(scr.x - 3, scr.y + 14, 6, 6)
end)

function MGD.Cardealer.Open(dealerList, cardealerCategories, openUsedCardealer)
    if MGD.Cardealer and IsValid(MGD.Cardealer.main) then
        MGD.Cardealer.main:Remove()
    end

    local cars = dealerList
    local categoryData = cardealerCategories
    local hasCar = false

    for k, v in pairs(cars) do
        if v.bought then
            hasCar = true
        end
    end

    MGD.Cardealer.main = vgui.Create("DPanel")
    MGD.Cardealer.main:SetSize(ScrW(), ScrH())
    MGD.Cardealer.main:SetPos(0, 0)
    MGD.Cardealer.main:MakePopup()
    MGD.Cardealer.main:SetAlpha(0)
    MGD.Cardealer.main:AlphaTo(255, 0.2, 0)
    MGD.Cardealer.main.startTime = SysTime()

    MGD.Cardealer.main.Paint = function(self)
        Derma_DrawBackgroundBlur(self, self.startTime or 0)
    end

    MGD.Cardealer.main.Think = function(self)
        if input.IsKeyDown(KEY_ESCAPE) then
            if self.closing then return end
            self.closing = true
            gui.HideGameUI()

            self:AlphaTo(0, 0.2, 0, function()
                self:SetVisible(false)
                self:Remove()
            end)
        end
    end

    MGD.Cardealer.main.title = vgui.Create("DLabel", MGD.Cardealer.main)
    MGD.Cardealer.main.title:Dock(TOP)
    MGD.Cardealer.main.title:DockMargin(50, 50, 0, 0)
    MGD.Cardealer.main.title:SetText(!openUsedCardealer and "Car Dealership" or 'Used Car Dealership')
    MGD.Cardealer.main.title:SetFont("Cardealer.64")
    MGD.Cardealer.main.title:SizeToContents()
    if ScrW() <= 1366 then
        MGD.Cardealer.main.categoryList = vgui.Create("DScrollPanel2", MGD.Cardealer.main)
        MGD.Cardealer.main.categoryList:Dock(FILL)
        MGD.Cardealer.main.categoryContainer = MGD.Cardealer.main.categoryList:Add("DPanel")
        MGD.Cardealer.main.categoryContainer:Dock(TOP)
        MGD.Cardealer.main.categoryContainer:DockMargin(50, 50, 50, 10)
        MGD.Cardealer.main.categoryContainer:SetHeight(300)
    else
        MGD.Cardealer.main.categoryContainer = vgui.Create("DPanel", MGD.Cardealer.main)
        MGD.Cardealer.main.categoryContainer:Dock(LEFT)
        MGD.Cardealer.main.categoryContainer:DockMargin(50, 50, 0, 150)
    end
    MGD.Cardealer.main.categoryContainer:SetWidth(300)

    MGD.Cardealer.main.categoryContainer.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, w, h)
    end

    MGD.Cardealer.main.categoryContainer.title = vgui.Create("DLabel", MGD.Cardealer.main.categoryContainer)
    MGD.Cardealer.main.categoryContainer.title:Dock(TOP)
    MGD.Cardealer.main.categoryContainer.title:DockMargin(10, 5, 0, 10)
    MGD.Cardealer.main.categoryContainer.title:SetText("Categories")
    MGD.Cardealer.main.categoryContainer.title:SetFont("Cardealer.20")
    MGD.Cardealer.main.categoryContainer.title:SizeToContents()
    MGD.Cardealer.main.categoryContainer.categoryList = vgui.Create("DScrollPanel2", MGD.Cardealer.main.categoryContainer)
    MGD.Cardealer.main.categoryContainer.categoryList:Dock(FILL)
    if ScrW() <= 1366 then

        MGD.Cardealer.main.carsContainer = MGD.Cardealer.main.categoryList:Add("DPanel")
        MGD.Cardealer.main.carsContainer:Dock(TOP)
        MGD.Cardealer.main.carsContainer:DockMargin(50, 0, 50, 0)
        MGD.Cardealer.main.carsContainer:SetHeight(800)
    else
        MGD.Cardealer.main.carsContainer = vgui.Create("DPanel", MGD.Cardealer.main)
        MGD.Cardealer.main.carsContainer:Dock(FILL)
        MGD.Cardealer.main.carsContainer:DockMargin(50, 50, 50, 100)
    end

    MGD.Cardealer.main.carsContainer:DockPadding(0, 0, 0, 10)
    MGD.Cardealer.main.carsContainer:SetWidth(300)
    MGD.Cardealer.main.carsContainer.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, w, h)
    end

    MGD.Cardealer.main.carsContainer.categoryName = vgui.Create("DLabel", MGD.Cardealer.main.carsContainer)
    MGD.Cardealer.main.carsContainer.categoryName:Dock(TOP)
    MGD.Cardealer.main.carsContainer.categoryName:SetFont("Cardealer.20")
    MGD.Cardealer.main.carsContainer.categoryName:SizeToContents()
    MGD.Cardealer.main.carsContainer.categoryName:DockMargin(10, 5, 0, 5)
    MGD.Cardealer.main.carsContainer.carList = vgui.Create("DScrollPanel2", MGD.Cardealer.main.carsContainer)
    MGD.Cardealer.main.carsContainer.carList:Dock(FILL)

    local function FormatFriveType(int)
        if int == 1 then
            return "Front"
        elseif int == -1 then
            return "Rear"
        elseif int == 0 then
            return "All-wheel"
        else
            return "Unknown"
        end
    end

    local function FormatFuelType(int)
        if int == FUELTYPE_DIESEL then
            return "Diesel"
        elseif int == FUELTYPE_ELECTRIC then
            return "Electric"
        elseif int == FUELTYPE_PETROL then
            return "Petrol"
        else
            return "Unknown"
        end
    end

    local carSpecs = {
        {
            ["name"] = "Grip",
            ["id"] = "grip"
        },
        {
            ["name"] = "Engine power",
            ["id"] = "enginePower"
        },
        {
            ["name"] = "Tank volume",
            ["id"] = "fuelVolume"
        },
    }

    function MGD.Cardealer.main.categoryContainer.categoryList.Select(index)
        local children = MGD.Cardealer.main.categoryContainer.categoryList:GetCanvas():GetChildren()
        for k, v in pairs(children) do
            v:SetToggle(false)
        end

        local btn = children[index] or children[1]
        if not IsValid(btn) then return end

        btn:SetToggle(true)
        local catName = btn:GetText()
        MGD.Cardealer.main.carsContainer.categoryName:SetText(catName)
        MGD.Cardealer.main.carsContainer.carList:Clear()

        for x, y in pairs(cars) do
            if y.category == catName then
                if openUsedCardealer and y.category != 'Owned' and y.category != 'Scrap Cars' and y.category != 'Used' then continue end
                if !openUsedCardealer and (y.category == 'Scrap Cars' or y.category == 'Used') then continue end

                local myCar = (openUsedCardealer and y.steamid and y.steamid == LocalPlayer():SteamID64()) and true or false

                local carContainer = vgui.Create("DPanel")
                carContainer:Dock(TOP)
                carContainer:DockMargin(10, 10, 10, 0)
                carContainer:DockPadding(10, 10, 10, 10)
                carContainer:SetHeight(300)
                carContainer.OnHoverV = 0
                carContainer.hover = false

                carContainer.Think = function(self)
                    self.OnHoverV = math.Clamp(self.OnHoverV - RealFrameTime() * 640 * 2, 0, 255)

                    if not self:IsHovered() and not self:IsChildHovered() then
                        self.hover = false

                        return
                    end

                    if not self.hover then
                        surface.PlaySound("btn.wav")
                        self.hover = true
                    end

                    self.OnHoverV = math.Clamp(self.OnHoverV + RealFrameTime() * 640 * 8, 0, 255)
                end

                carContainer.Paint = function(self, w, h)
                    surface.SetDrawColor(0, 0, 0, 164)
                    surface.DrawRect(0, 0, w, h)

                    if self.OnHoverV > 0 then
                        surface.SetDrawColor(208, 45, 123, self.OnHoverV)
                        surface.DrawOutlinedRect(0, 0, w, h, 2)
                    end
                end

                if ScrW() <= 1366 then
                    carContainer.carContainer2 = vgui.Create("DPanel", carContainer)
                    carContainer.carContainer2:Dock(FILL)
                    carContainer.carContainer2.Paint = function(self, w, h)
                    end
                    carContainer.carModel = vgui.Create("DModelPanel", carContainer.carContainer2)
                else
                    carContainer.carModel = vgui.Create("DModelPanel", carContainer)
                end

                carContainer.carModel:Dock(LEFT)
                carContainer.carModel:DockMargin(10, 10, 10, 10)
                carContainer.carModel:SetModel(y.model)
                carContainer.carModel:SetFOV(y.fov or 95)
                carContainer.carModel:SetCamPos(Vector(-100, 90, 40) + (y.camPos or Vector()))
                carContainer.carModel:SetLookAt(carContainer.carModel:GetEntity():GetPos())
                carContainer.carModel:SetAmbientLight(Color(255, 255, 255))
                carContainer.carModel:SetCursor("arrow")
                if ScrW() <= 1366 then
                    carContainer.carModel:SetWidth(100)
                else
                    carContainer.carModel:SetWidth(400)
                end
                carContainer.carModel.Wheels = {}
                carContainer.carModel.Angles = Angle( 0, 180, 0 )

                local vehicle = carContainer.carModel.Entity
                local subMaterial = y.subMaterials

                local col = 231
                local customColor = y.color
                local color = customColor and Color(customColor.r, customColor.g, customColor.b) or Color(col, col, col)

                vehicle:SetProxyColor({color, color, Color(15, 15, 15)})

                local function vehicleSetSubMaterials(submaterials)
                    if !IsValid(vehicle) then return end
                    for k, mat in pairs(submaterials) do
                        vehicle:SetSubMaterial( k, mat )
                    end
                end

                vehicleSetSubMaterials(subMaterial.on_lowbeam.Base)

                timer.Simple(1, function()
                    vehicleSetSubMaterials(subMaterial.off.Base)
                end)

                for k, v in pairs(y.wheels.wheels) do
                    local model = ClientsideModel( y.wheels.model, RENDERGROUP_OTHER )
                    model:SetParent(carContainer.carModel.Entity)
                    model:SetLocalPos(v + Vector(0, 0, -1))

                    model:SetLocalAngles(y.wheels.angleOffset + carContainer.carModel.Angles + Angle(0, string.EndsWith(k, 'r') and 90 or -90, 0))
                    model:SetNoDraw(true)
                    model:Spawn()
                    carContainer.carModel.Wheels[k] = model
                end

                carContainer.carModel.PostDrawModel = function()
                    for k, v in pairs(carContainer.carModel.Wheels) do
                        v:DrawModel()
                    end
                end

                function carContainer.carModel:DragMousePress()
                    self.PressX, self.PressY = gui.MousePos()
                    self.Pressed = true
                end

                function carContainer.carModel:DragMouseRelease() self.Pressed = false end

                function carContainer.carModel:LayoutEntity( ent )
                    if ( self.bAnimated ) then self:RunAnimation() end

                    if ( self.Pressed ) then
                        local mx, my = gui.MousePos()
                        self.Angles = self.Angles - Angle( 0, ( self.PressX or mx ) - mx, 0 )

                        self.PressX, self.PressY = gui.MousePos()
                    end

                    ent:SetAngles( self.Angles )
                end

                function carContainer.carModel:OnRemove()
                    for _, wheel in pairs(carContainer.carModel.Wheels or {}) do
                        if IsValid(wheel) then
                            wheel:Remove()
                        end
                    end
                end

                local oldPaint = carContainer.carModel.Paint

                carContainer.carModel.Paint = function(self, w, h)

                    oldPaint(self, w, h)
                end

                carContainer.topContainer = vgui.Create("DPanel", carContainer)
                carContainer.topContainer:Dock(TOP)
                carContainer.topContainer:SetHeight(50)
                carContainer.topContainer:DockPadding(10, 10, 10, 10)

                carContainer.topContainer.Paint = function(self, w, h)
                    surface.SetDrawColor(Color(0, 0, 0, 0))
                    surface.DrawRect(0, 0, w, h)
                end

                carContainer.topContainer.carName = vgui.Create("DLabel", carContainer.topContainer)
                carContainer.topContainer.carName:Dock(LEFT)
                carContainer.topContainer.carName:SetText(y.name)
                carContainer.topContainer.carName:SetFont("Cardealer.32")
                carContainer.topContainer.carName:SizeToContents()

                if !y.bought then
                    carContainer.topContainer.carPriceContainer = vgui.Create("DPanel", carContainer.topContainer)
                    carContainer.topContainer.carPriceContainer:Dock(RIGHT)

                    carContainer.topContainer.carPriceContainer.Paint = function(self, w, h)
                        surface.SetDrawColor(Color(208, 45, 124))
                        surface.DrawOutlinedRect(0, 0, w, h, 2)
                    end

                    carContainer.topContainer.carPriceContainer.priceText = vgui.Create("DLabel", carContainer.topContainer.carPriceContainer)
                    carContainer.topContainer.carPriceContainer.priceText:Dock(FILL)
                    carContainer.topContainer.carPriceContainer.priceText:SetText(DarkRP.formatMoney(y.price))
                    carContainer.topContainer.carPriceContainer.priceText:SetFont("Cardealer.20")
                    carContainer.topContainer.carPriceContainer.priceText:SizeToContents()
                    carContainer.topContainer.carPriceContainer.priceText:SetContentAlignment(5)
                    carContainer.topContainer.carPriceContainer:SetWidth(carContainer.topContainer.carPriceContainer.priceText:GetWide() + 20)
                end

                local hudmph = GetConVar( "cl_simfphys_hudmph" ):GetBool()
                local speed = y.topSpeed
                local mph = math.Round(speed * 0.0568182,0)
                local kmh = math.Round(speed * 0.09144,0)
                speed = hudmph and mph or kmh

                if ScrW() <= 1366 then
                    carContainer.carSpecList = vgui.Create("DListView", carContainer.carContainer2)
                else
                    carContainer.carSpecList = vgui.Create("DListView", carContainer)
                end
                carContainer.carSpecList.new = true
                carContainer.carSpecList:Dock(LEFT)
                carContainer.carSpecList:SetWidth(250)
                carContainer.carSpecList:SetMultiSelect(false)
                carContainer.carSpecList:SetHideHeaders(true)
                carContainer.carSpecList:AddColumn("Key")
                carContainer.carSpecList:AddColumn("Value")

                if !y.bought and !y.sell then
                    carContainer.carSpecList:AddLine("Mass", y.weight .. " kg")
                    carContainer.carSpecList:AddLine("Drivetrain", FormatFriveType(y.driveType))
                    carContainer.carSpecList:AddLine("Turn angle", y.turnAngle .. "°")
                    carContainer.carSpecList:AddLine("Seats", y.seats)
                    carContainer.carSpecList:AddLine("Engine power", y.enginePower .. " hp")
                    carContainer.carSpecList:AddLine("Top speed", speed .. " " .. (hudmph and 'mi' or 'km') .. "/h")
                    carContainer.carSpecList:AddLine("Fuel", FormatFuelType(y.fuelType))
                    carContainer.carSpecList:AddLine("Tank capacity", y.fuelVolume .. ' L')

                    if y.armored then
                        carContainer.carSpecList:AddLine("Armored", "Yes")
                    end
                    if y.bulletProofTires then
                        carContainer.carSpecList:AddLine("Bulletproof tires", "Yes")
                    end
                else
                    carContainer.carSpecList:AddLine("Condition", math.Round(y.health/y.maxHealth*100) .. " %")
                    carContainer.carSpecList:AddLine("Fuel", math.Round(y.fuel/y.fuelVolume*100) .. " %")
                    carContainer.carSpecList:AddLine("License plate", y.plate)
                end

                carContainer.carSpecList.OnClickLine = function() return false end
                for u, g in pairs(carContainer.carSpecList:GetLines()) do
                    g.new = true
                    for i, d in pairs(g:GetChildren()) do
                        d:SetFont("Cardealer.14")
                    end
                end
                if ScrW() <= 1366 then
                    carContainer.carSpecs = vgui.Create("DPanel", carContainer.carContainer2)
                else
                    carContainer.carSpecs = vgui.Create("DPanel", carContainer)
                end
                carContainer.carSpecs:Dock(LEFT)
                carContainer.carSpecs:SetWidth(250)
                carContainer.carSpecs:DockPadding(10, 0, 10, 0)

                carContainer.carSpecs.Paint = function(self, w, h)
                    surface.SetDrawColor(Color(0, 0, 0, 0))
                    surface.DrawRect(0, 0, w, h)
                end

                for u, g in pairs(carSpecs) do
                    local spec = vgui.Create("DProgress", carContainer.carSpecs)
                    spec.new = true
                    spec:Dock(TOP)
                    spec:SetHeight(20)

                    if #carSpecs >= u + 1 then
                        spec:DockMargin(0, 0, 0, 10)
                    end

                    spec:SetFraction(math.Clamp((tonumber(y[g.id]) or 0) / 250, 0, 1))

                    spec.PaintOver = function(self, w, h)
                        draw.SimpleText(g.name, "Cardealer.14", w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    end
                end

                local spawnedCar = false
                local plVeh = LocalPlayer():GetNWEntity('MGD.SpawnCar')

                if IsValid(plVeh) then
                    if plVeh:GetNWInt('MGD.CarID', 0) == y.id then
                        spawnedCar = true
                    end
                end

                carContainer.bottomContainer = vgui.Create("DPanel", carContainer)
                carContainer.bottomContainer:Dock(BOTTOM)
                carContainer.bottomContainer:SetHeight(50)
                carContainer.bottomContainer.Paint = function(self, w, h)
                    surface.SetDrawColor(Color(0, 0, 0, 0))
                    surface.DrawRect(0, 0, w, h)
                end

                carContainer.bottomContainer.button1 = vgui.Create("DButton", carContainer.bottomContainer)
                carContainer.bottomContainer.button1:Dock(RIGHT)
                carContainer.bottomContainer.button1:SetText(y.bought and (!spawnedCar and "Spawn" or "Store") or (!myCar and "Buy" or "Remove from sale"))
                carContainer.bottomContainer.button1:SetWidth(150)
                carContainer.bottomContainer.button1:SetFont("Cardealer.20")
                carContainer.bottomContainer.button1.Paint = function(self, w, h)
                    surface.SetDrawColor(Color(208, 45, 124, 255))
                    surface.DrawRect(0, 0, w, h)
                end
                carContainer.bottomContainer.button1.DoClick = function()
                    surface.PlaySound("btn2.wav")
                    if !myCar then
                        if !y.bought then
                            MGD.Cardealer.DermaQuery("Are you sure you want to buy this car?", "Purchase Confirmation",
                                "No",
                                function() end,
                                "Yes",
                                function()
                                    if !y.sell then
                                        netstream.Start('MGD.Cardealer.BuyVehicle', y.class)
                                    else
                                        netstream.Start('MGD.Cardealer.BuyVehicleFromPlayer', y.id)
                                    end
                                end
                            )
                        else
                            if !spawnedCar then
                                netstream.Start('MGD.Cardealer.SpawnVehicle', y.id)
                            else
                                netstream.Start('MGD.Cardealer.ReturnVehicle', y.id)
                            end
                        end
                    else
                        netstream.Start('MGD.Cardealer.RemoveFromSale', y.id)
                    end
                end

                if y.bought then
                    carContainer.bottomContainer.button2 = vgui.Create("DButton", carContainer.bottomContainer)
                    carContainer.bottomContainer.button2:Dock(RIGHT)
                    carContainer.bottomContainer.button2:DockMargin(0, 0, 7, 0)
                    carContainer.bottomContainer.button2:SetText(!openUsedCardealer and "Sell" or "List for sale")
                    carContainer.bottomContainer.button2:SetWidth(!openUsedCardealer and 150 or 200)
                    carContainer.bottomContainer.button2:SetFont("Cardealer.20")
                    carContainer.bottomContainer.button2.Paint = function(self, w, h)
                        surface.SetDrawColor(Color(208, 45, 124, 255))
                        surface.DrawRect(0, 0, w, h)
                    end
                    carContainer.bottomContainer.button2.DoClick = function(self)
                        surface.PlaySound("btn2.wav")
                        if !openUsedCardealer then
                            MGD.Cardealer.DermaQuery(string.format("Are you sure you want to sell this car for %s?", DarkRP.formatMoney(y.price/100*75)), "Sale Confirmation",
                                "No",
                                function() end,
                                "Yes",
                                function()
                                    netstream.Start('MGD.Cardealer.SellVehicle', y.id)
                                end
                            )
                        else
                            MGD.Cardealer.EnterTextPanel('Sell car', 'Enter the price you want to list this car for\nListing a car costs $30!', tostring(y.price/100*75),
                                function(price)
                                    netstream.Start('MGD.Cardealer.Used.SellCar', y.id, tonumber(price))
                                end,
                                function() end,
                                'List car', 'Cancel', true, DarkRP.formatMoney(y.price/100*75)
                            )
                        end
                    end
                end

                MGD.Cardealer.main.carsContainer.carList:AddItem(carContainer)
            end
        end
    end

    local indexCategories = {}

    local function addCategory(catName)
        if !catName then return end
        indexCategories[catName] = table.Count(indexCategories) + 1

        local category = vgui.Create("DButton", MGD.Cardealer.main.categoryContainer.categoryList)
        category:Dock(TOP)
        category:SetText(catName)
        category:SetHeight(50)
        category:SetContentAlignment(4)
        category:AlignLeft(10)
        category:SetTextInset(20, 0)
        category:SetFont("Cardealer.15")
        category.OnHoverV = 0
        category.OnActive = 0

        category.OnCursorEntered = function()
            surface.PlaySound("btn.wav")
        end

        category.Think = function(self)
            if not self:IsHovered() then
                self.OnHoverV = math.Clamp(self.OnHoverV - RealFrameTime() * 100 * 2, 0, 52)
            else
                self.OnHoverV = math.Clamp(self.OnHoverV + RealFrameTime() * 100 * 8, 0, 52)
            end

            if not self:GetToggle() then
                self.OnActive = math.Clamp(self.OnActive - RealFrameTime() * 300 * 2, 0, 145)
            else
                self.OnActive = math.Clamp(self.OnActive + RealFrameTime() * 300 * 8, 0, 145)
            end
        end

        category.Paint = function(self, w, h)
            if self.OnActive > 0 then
                surface.SetDrawColor(Color(208, 45, 124, self.OnActive))
                surface.DrawRect(0, 0, w, h)
            elseif self.OnHoverV > 0 then
                surface.SetDrawColor(Color(208, 45, 123, self.OnHoverV))
                surface.DrawRect(0, 0, w, h)
            end
        end

        category.DoClick = function(self)
            surface.PlaySound("btn2.wav")
            MGD.Cardealer.main.categoryContainer.categoryList.Select(indexCategories[catName])
        end
    end

    addCategory('Owned')

    for k, v in SortedPairsByMemberValue(categoryData, 'name') do
        if v.name == 'Owned' then continue end
        if !openUsedCardealer and v.name == 'Scrap Cars' then continue end

        addCategory(v.name)
    end

    MGD.Cardealer.main.categoryContainer.categoryList.Select(hasCar and 1 or 2)
    MGD.Cardealer.main.hintContainer = vgui.Create("DPanel", MGD.Cardealer.main)
    MGD.Cardealer.main.hintContainer:Dock(BOTTOM)
    MGD.Cardealer.main.hintContainer:DockPadding(10, 10, 20, 10)
    MGD.Cardealer.main.hintContainer:SetHeight(50)

    MGD.Cardealer.main.hintContainer.Paint = function(self, w, h)
        surface.SetDrawColor(0, 0, 0, 0)
        surface.DrawRect(0, 0, w, h)
    end

    local hintData = {
        {
            text = "Exit",
            key = "ESC"
        },
    }

    for k, v in pairs(hintData) do
        local hintText = vgui.Create("DLabel", MGD.Cardealer.main.hintContainer)
        hintText:Dock(RIGHT)
        hintText:DockMargin(10, 0, 10, 0)
        hintText:SetText(v.text)
        hintText:SetContentAlignment(5)
        hintText:SetFont("Cardealer.20")
        hintText:SizeToContents()
        local hint = vgui.Create("DPanel", MGD.Cardealer.main.hintContainer)
        hint:Dock(RIGHT)
        hint:SetWidth(50)

        hint.Paint = function(self, w, h)
            surface.SetDrawColor(87, 87, 87, 173)
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        end

        local hintKey = vgui.Create("DLabel", hint)
        hintKey:Dock(FILL)
        hintKey:DockMargin(0, 0, 0, 0)
        hintKey:SetText(v.key)
        hintKey:SetContentAlignment(5)
        hintKey:SetFont("Cardealer.20")
        hintKey:SizeToContents()
    end

    netstream.Hook('MGD.Cardealer.BuyVehicle', function(vehicleList)
        cars = vehicleList
        if IsValid(MGD.Cardealer.main) then
            MGD.Cardealer.main.categoryContainer.categoryList.Select(1)
        end
    end)

    netstream.Hook('MGD.Cardealer.CloseMenu', function()
        if !IsValid(MGD.Cardealer.main) then return end
        MGD.Cardealer.main:AlphaTo(0, 0.2, 0, function()
            MGD.Cardealer.main:SetVisible(false)
            MGD.Cardealer.main:Remove()
        end)
    end)
end

function MGD.OpenCardealerCustomVehiclesEditor(customVehicles)
    if IsValid(MGD.CardealerCustomVehiclesEditor) then
        MGD.CardealerCustomVehiclesEditor:Remove()
    end

    local panel = vgui.Create('DFrame')
    panel:SetSize(600, 400)
    panel:Center()
    panel:MakePopup()
    panel:SetTitle('Custom Vehicles Editor')
    panel:SetSizable(true)
    panel:SetMinWidth( panel:GetWide()/3 )
    panel:SetMinHeight( panel:GetTall()/3 )

    local AppList = vgui.Create( "DListView", panel )
    AppList:Dock( FILL )
    AppList:DockMargin(0, 0, 0, 5)
    AppList:AddColumn( "Category" )
    AppList:AddColumn( "Class" )
    AppList:AddColumn( "Price" )

    local function addVehicle(category, class, price)
        AppList:AddLine(category, class, price)
    end

    for category, vehicles in pairs(customVehicles) do
        for class, vehicleData in pairs(vehicles) do
            addVehicle(category, class, DarkRP.formatMoney(vehicleData.price))
        end
    end

    AppList.OnRowRightClick = function( lst, index, pnl )
        netstream.Start('MGD.Cardealer.RemoveCustomVehicle', pnl:GetValue(1), pnl:GetValue(2))
    end

    local add = vgui.Create( "DButton", panel )
    add:Dock( BOTTOM )
    add:SetText('Add car')

    add.DoClick = function()
        MGD.OpenCardealerVehicleEditor()
    end

    MGD.CardealerCustomVehiclesEditor = panel
end

function MGD.OpenCardealerVehicleEditor()
    if IsValid(MGD.CardealerCustomVehiclesEditor) then
        MGD.CardealerCustomVehiclesEditor:Remove()
    end

    local vehList = list.Get('simfphys_vehicles')
    local vehListLights = list.Get('simfphys_lights')
    local addTable = {}

    local panel = vgui.Create('DFrame')
    panel:SetSize(800, 600)
    panel:Center()
    panel:MakePopup()
    panel:SetTitle('Vehicle Editor')
    panel:SetSizable(true)
    panel:SetMinWidth( panel:GetWide()/3 )
    panel:SetMinHeight( panel:GetTall()/3 )

    local text = vgui.Create( "DLabel", panel )
    text:SetText('Class')
    text:Dock(TOP)
    text:SetFont('Cardealer.18')

    local TextEntry = vgui.Create( "DTextEntry", panel )
    TextEntry:SetPos(5, 50)
    TextEntry:SetSize(300, 25)
    TextEntry.OnChange = function( self )
		panel.UpdateVehicle(self:GetValue(), vehList, vehListLights)
	end

    local text2 = vgui.Create( "DLabel", panel )
    text2:SetPos(5, TextEntry:GetY() + TextEntry:GetTall() + 5)
    text2:SetText('Category')
    text2:SetWide(100)
    text2:SetFont('Cardealer.18')

    local category = vgui.Create( "DTextEntry", panel )
    category:SetPos(5, text2:GetY() + text2:GetTall() + 5)
    category:SetSize(300, 25)
    category.OnChange = function( self )
        addTable.category = self:GetValue()
	end

    local camPos = Vector()
    local sliders = {'x', 'y', 'z'}
    local sliderObjects = {}

    for k, v in pairs(sliders) do
        local prevSlider = sliderObjects[table.Count(sliderObjects)]
        local y

        if IsValid(prevSlider) then
            y = prevSlider:GetY() + prevSlider:GetTall() + 5
        else
            y = category:GetY() + category:GetTall() + 5
        end

        local x = vgui.Create( "DNumSlider", panel )
        x:SetPos(5, y)
        x:SetSize( 300, 20 )
        x:SetText( "Camera " .. string.upper(v) )
        x:SetMin( -100 )
        x:SetMax( 100 )
        x:SetDecimals( 0 )

        x.OnValueChanged = function( self, value )
            camPos[v] = math.Round(value)
            addTable.camPos = camPos
        end

        table.insert(sliderObjects, x)
    end

    local lastSlider = sliderObjects[table.Count(sliderObjects)]

    local text2 = vgui.Create( "DLabel", panel )
    text2:SetPos(5, lastSlider:GetY() + lastSlider:GetTall() + 5)
    text2:SetText('Price')
    text2:SetWide(100)
    text2:SetFont('Cardealer.18')

    local price = vgui.Create( "DNumberWang", panel )
    price:SetPos( 5, text2:GetY() + text2:GetTall() + 5 )
    price:SetMin( 100 )
    price:SetMax( 100000 )
    price:SetValue( 1000 )
    price:HideWang()

    price.OnValueChanged = function(self)
        addTable.price = self:GetValue()
    end

    local checkBoxes = {
        {
            index = 'usedCar',
            name = 'Sold in Used Cars'
        },
    }
    local checkBoxObjects = {}

    for k, v in pairs(checkBoxes) do
        local prevCheckBox = checkBoxObjects[table.Count(checkBoxObjects)]
        local y

        if IsValid(prevCheckBox) then
            y = prevCheckBox:GetY() + prevCheckBox:GetTall() + 5
        else
            y = price:GetY() + price:GetTall() + 5
        end

        local checkBox = vgui.Create( "DCheckBoxLabel", panel )
        checkBox:SetPos( 5, y )
        checkBox:SetText(v.name)
        checkBox:SetValue( false )
        checkBox:SizeToContents()

        addTable.otherParameters = addTable.otherParameters or {}

        checkBox.OnChange = function(self, bool)
            addTable.otherParameters = addTable.otherParameters or {}
            addTable.otherParameters[v.index] = bool or nil
        end

        table.insert(checkBoxObjects, checkBox)
    end

    local vehicle = vgui.Create("DModelPanel", panel)
    vehicle:SetPos(TextEntry:GetX()+TextEntry:GetWide()+45, TextEntry:GetY())
    vehicle:SetSize(400, 250)
    vehicle:SetModel('models/props_borealis/bluebarrel001.mdl')
    vehicle:SetFOV(95)
    vehicle:SetCamPos(Vector(-100, 90, 40) + (camPos))
    vehicle:SetLookAt(vehicle:GetEntity():GetPos())
    vehicle:SetAmbientLight(Color(255, 255, 255))
    vehicle:SetCursor("arrow")
    vehicle.Wheels = {}
    vehicle.Angles = Angle( 0, 180, 0 )

    local oldPaint = vehicle.Paint

    vehicle.Paint = function(self, w, h)
        draw.RoundedBox(5, 0, 0, w, h, Color(0, 0, 0, 100))
        oldPaint(self, w, h)
        vehicle:SetCamPos(Vector(-100, 90, 40) + (camPos))
    end

    local vehicleEnt = vehicle.Entity
    local col = 231
    local color = Color(col, col, col)

    vehicleEnt:SetProxyColor({color, color, Color(15, 15, 15)})

    local function vehicleSetSubMaterials(submaterials)
        if !IsValid(vehicleEnt) then return end
        for k, mat in pairs(submaterials) do
            vehicleEnt:SetSubMaterial( k, mat )
        end
    end

    function vehicle:DragMousePress()
        self.PressX, self.PressY = gui.MousePos()
        self.Pressed = true
    end

    function vehicle:DragMouseRelease() self.Pressed = false end

    function vehicle:LayoutEntity( ent )
        if ( self.bAnimated ) then self:RunAnimation() end

        if ( self.Pressed ) then
            local mx, my = gui.MousePos()
            self.Angles = self.Angles - Angle( 0, ( self.PressX or mx ) - mx, 0 )

            self.PressX, self.PressY = gui.MousePos()
        end

        ent:SetAngles( self.Angles )
    end

    function vehicle:OnRemove()
        for _, wheel in pairs(self.Wheels or {}) do
            if IsValid(wheel) then wheel:Remove() end
        end
    end

    vehicle.PostDrawModel = function()
        for k, v in pairs(vehicle.Wheels) do
            v:DrawModel()
        end
    end

    function panel.UpdateVehicle(class, vehList, vehListLights)
        local vehicleData = vehList[class]
        if !vehicleData then return end
        local vehicleLights = vehListLights[vehicleData.Members.LightsTable]
        if !vehicleLights or !vehicleLights.SubMaterials then return end

        for _, w in pairs(vehicle.Wheels) do
            if IsValid(w) then w:Remove() end
        end
        vehicle.Wheels = {}

        local subMaterial = vehicleLights.SubMaterials
        vehicle:SetModel(vehicleData.Model)

        vehicleSetSubMaterials(subMaterial.on_lowbeam.Base)

        timer.Simple(1, function()
            vehicleSetSubMaterials(subMaterial.off.Base)
        end)

        local wheels = {
            fl = vehicleData.Members.CustomWheelPosFL,
            fr = vehicleData.Members.CustomWheelPosFR,
            rl = vehicleData.Members.CustomWheelPosRL,
            rr = vehicleData.Members.CustomWheelPosRR
        }

        for k, v in pairs(wheels) do
            local model = ClientsideModel( vehicleData.Members.CustomWheelModel, RENDERGROUP_OTHER )
            model:SetParent(vehicle.Entity)
            model:SetLocalPos(v + Vector(0, 0, -1))

            model:SetLocalAngles(vehicleData.Members.CustomWheelAngleOffset + vehicle.Angles + Angle(0, string.EndsWith(k, 'r') and 90 or -90, 0))
            model:SetNoDraw(true)
            model:Spawn()
            vehicle.Wheels[k] = model
        end

        addTable.class = class
    end

    local add = vgui.Create( "DButton", panel )
    add:Dock( BOTTOM )
    add:SetText('Add car')

    add.DoClick = function(self)
        netstream.Start('MGD.Cardealer.AddCustomVehicle', addTable)
    end

    netstream.Hook('MGD.Cardealer.CloseCustomVehicleMenu', function()
        if IsValid(MGD.CardealerCustomVehiclesEditor) then
            MGD.CardealerCustomVehiclesEditor:Remove()
        end
    end)

    MGD.CardealerCustomVehiclesEditor = panel
end

hook.Add('InitPostEntity', 'MGD.InitPostEntity.InitializeCardealerNetwork', function()
    netstream.Hook('MGD.CarDealer.GetList', MGD.Cardealer.Open)
	netstream.Hook('MGD.Cardealer.GetCustomVehicles', MGD.OpenCardealerCustomVehiclesEditor)
    netstream.Hook('MGD.Cardealer.Waypoint', function(pos, name)
        cardealerWaypoint = { pos = pos, name = name, expire = CurTime() + 30 }
    end)
end)
