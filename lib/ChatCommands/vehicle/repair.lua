-- Repair

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="repair",
    command_aliases={"fix"},
    group="vehicle",
    help="Repair any damage done to your current vehicle",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
            -- Also repair vehicle if its been destroyed by water
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0.0)
            VEHICLE.SET_VEHICLE_UNDRIVEABLE(vehicle, false)
            VEHICLE.SET_VEHICLE_ENGINE_HEALTH(vehicle, 1000.0)
            VEHICLE.SET_VEHICLE_PETROL_TANK_HEALTH(vehicle, 1000.0)
            VEHICLE.SET_VEHICLE_ENGINE_ON(vehicle, true, true, true)
            cc_utils.help_message(pid, "Vehicle repaired")
        end
    end
}