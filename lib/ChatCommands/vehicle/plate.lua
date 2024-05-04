-- Plate

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="plate",
    group="vehicle",
    help="Set the vehicle plate text",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            if commands[2] == nil then
                vehicle_utils.set_plate_for_player(vehicle, pid)
                cc_utils.help_message(pid, "Vehicle plate text set to name")
            else
                VEHICLE.SET_VEHICLE_NUMBER_PLATE_TEXT(vehicle, commands[2])
                cc_utils.help_message(pid, "Vehicle plate text set")
            end
        end
    end
}