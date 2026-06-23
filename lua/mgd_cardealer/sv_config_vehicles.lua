local vehList = {
    -- ['Sedans'] = {
    --     sim_fphys_gta4_dilettante = {
    --         price = 4000,
    --     },
    -- },
    -- ['Minivans'] = {
    --     sim_fphys_gta4_minivan = {
    --         price = 11000,
    --         camPos = Vector(-25, 0, -10)
    --     },
    -- },
    -- ['SUVs'] = {
    --     sim_fphys_gta4_huntley = {
    --         price = 25000,
    --         camPos = Vector(-20, 0, 0)
    --     },
    -- },
    -- ['Wagons'] = {
    --     sim_fphys_gta4_habanero = {
    --         price = 15000,
    --         camPos = Vector(-20, 0, 0)
    --     },
    -- },
    -- ['Coupes'] = {
    --     sim_fphys_gta4_uranus = {
    --         price = 15000,
    --         camPos = Vector(-5, 0, -10)
    --     },
    -- },
    -- ['Sports'] = {
    --     sim_fphys_gta4_comet = {
    --         price = 37500,
    --         camPos = Vector(-5, 0, -10)
    --     },
    -- },
    -- ['Scrap Cars'] = {
    --     sim_fphys_gta4_emperor2 = {
    --         price = 1100,
    --         camPos = Vector(-5, 0, -10),
    --         usedCar = true
    --     },
    -- },
}

function MGD.Cardealer.CreateList(custom)
    custom = custom or {}

    local combined = table.Copy(vehList)
    for category, vehicles in pairs(custom) do
        combined[category] = combined[category] or {}
        for class, vehicleData in pairs(vehicles) do
            combined[category][class] = vehicleData
        end
    end

    MGD.CardealerList = {}
    MGD.CardealerCategories = {
        {
            ["name"] = "Owned",
            ["acquired"] = true
        },
    }

    MGD.UsedCarsCategories = {
        {
            ["name"] = "Owned",
            ["acquired"] = true
        },
        {
            ["name"] = "Scrap Cars"
        },
        {
            ["name"] = "Used"
        },
    }

    for categoryName, vehicles in pairs(combined) do
        for class, vehicleData in pairs(vehicles) do
            local vehTable = MGD.Cardealer.GetVehicleTable(class, categoryName, vehicleData)
            if vehTable then
                table.insert(MGD.CardealerList, vehTable)
            end
        end
    end

    for k, v in pairs(MGD.CardealerList) do
        local hasCategory = false

        for _, category in pairs(MGD.CardealerCategories) do
            if category.name == v.category then
                hasCategory = true
            end
        end

        if hasCategory then continue end

        table.insert(MGD.CardealerCategories, {name = v.category})
    end

    timer.Create('MGD.CardealerWheels.Clear', 1, 1, function()
        for k, v in pairs(MGD.CarDealerWheels) do
            if IsValid(v) then
                v:Remove()
                MGD.CarDealerWheels[k] = nil
            end
        end
    end)
end