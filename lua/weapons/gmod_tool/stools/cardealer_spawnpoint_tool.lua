AddCSLuaFile()

MGD = MGD or {}
MGD.Cardealer = MGD.Cardealer or {}
MGD.Cardealer.SpawnPoints = MGD.Cardealer.SpawnPoints or {}

TOOL.Category = "MGD Cardealer"
TOOL.Name = "Parking spots"
TOOL.Author = ""

if CLIENT then
    TOOL.Information = {
        { name = "left" },
        { name = "right" }
    }
    language.Add("tool.cardealer_spawnpoint_tool.name", "Parking spots")
    language.Add("tool.cardealer_spawnpoint_tool.desc", "Spawn points for cars in the car dealership")
    language.Add("tool.cardealer_spawnpoint_tool.left", "Place parking spot")
    language.Add("tool.cardealer_spawnpoint_tool.right", "Remove nearest parking spot")
end

local boxMins = Vector(-118.760902, -41.794949, -24.506876)
local boxMaxs = Vector(107.529762, 41.794895, 38.351627)

local function canUse(ply)
    return IsValid(ply) and ply:IsSuperAdmin()
end

local function spawnPointFromTrace(tr, eyeYaw)
    local angle = Angle()
    local pos = tr.HitPos + Vector(0, 0, 50) + tr.HitNormal * 1.3
    angle:RotateAroundAxis(angle:Up(), eyeYaw + 90)
    return pos, angle
end

local function syncToOwner(owner)
    if SERVER and IsValid(owner) then
        netstream.Start(owner, 'MGD.Cardealer.SpawnPoints', MGD.Cardealer.SpawnPoints)
    end
end

function TOOL:Deploy()
    local owner = self:GetOwner()
    if !canUse(owner) then return end

    CarSpawnPointActive = true
    syncToOwner(owner)
end

function TOOL:Holster()
    CarSpawnPointActive = false
end

function TOOL:LeftClick()
    local owner = self:GetOwner()
    if !canUse(owner) then return false end
    if CLIENT then return true end

    local tr = owner:GetEyeTrace()
    local pos, angle = spawnPointFromTrace(tr, owner:EyeAngles().y)

    MGD.Cardealer.AddSpawnPoint(pos, angle)
    MGD.Cardealer.Notify(owner, 'Parking spot added!', 4)

    timer.Simple(0.15, function()
        syncToOwner(owner)
    end)

    return true
end

function TOOL:RightClick()
    local owner = self:GetOwner()
    if !canUse(owner) then return false end
    if CLIENT then return true end

    MGD.Cardealer.RemoveNearestSpawnPoint(owner:GetEyeTrace().HitPos)
    MGD.Cardealer.Notify(owner, 'Parking spot removed!', 4)

    timer.Simple(0.15, function()
        syncToOwner(owner)
    end)

    return true
end

if CLIENT then
    netstream.Hook('MGD.Cardealer.SpawnPoints', function(spawnpoints)
        MGD.Cardealer.SpawnPoints = spawnpoints or {}
    end)

    local boxColor = Color(0, 255, 0)

    hook.Add("PostDrawTranslucentRenderables", "MGD.Cardealer.DrawSpawnPoints", function()
        if !CarSpawnPointActive then return end

        local ply = LocalPlayer()
        local pos, angle = spawnPointFromTrace(ply:GetEyeTrace(), ply:EyeAngles().y)
        render.DrawWireframeBox(pos, angle, boxMins, boxMaxs, boxColor, true)

        for _, v in pairs(MGD.Cardealer.SpawnPoints or {}) do
            render.DrawWireframeBox(v.pos, v.ang, boxMins, boxMaxs, boxColor, true)
        end
    end)
end
