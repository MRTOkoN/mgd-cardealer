if SERVER then
    include("mgd_cardealer/sv_config.lua")
    include("mgd_cardealer/sv_money.lua")
    include("mgd_cardealer/sv_config_vehicles.lua")
    include("mgd_cardealer/sv_cardealer.lua")

    AddCSLuaFile("mgd_cardealer/cl_panel.lua")
    AddCSLuaFile("mgd_cardealer/cl_cardealer.lua")
else
    include("mgd_cardealer/cl_panel.lua")
    include("mgd_cardealer/cl_cardealer.lua")
end
