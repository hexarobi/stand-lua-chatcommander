-- Tires

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="tires",
    group="vehicle",
    help="Set the vehicle tires: burst bulletproof drift stock",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            if commands[2] == "burst" then
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, true)
                for wheel = 0,7 do
                    VEHICLE.SET_VEHICLE_TYRE_BURST(vehicle, wheel, true, 1000.0)
                end
                cc_utils.help_message(pid, "Vehicle tires burst ")
                return
            end
            if commands[2] == "bulletproof" then
                VEHICLE.SET_VEHICLE_TYRES_CAN_BURST(vehicle, false)
                cc_utils.help_message(pid, "Vehicle tires bulletproof")
            end
            if commands[2] == "drift" then
                VEHICLE.SET_VEHICLE_REDUCE_GRIP(vehicle, true)
                VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(vehicle, 3)
                cc_utils.help_message(pid, "Vehicle tires drift")
            end
            if commands[2] == "stock" then
                VEHICLE.SET_VEHICLE_REDUCE_GRIP(vehicle, false)
                VEHICLE.SET_VEHICLE_REDUCE_GRIP_LEVEL(vehicle, 1.0)
                cc_utils.help_message(pid, "Vehicle tires stock")
            end
        end
    end
}