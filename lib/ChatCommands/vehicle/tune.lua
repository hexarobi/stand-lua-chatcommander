-- Tune

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="tune",
    group="vehicle",
    help="Tune the vehicle with maximum performance options",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            vehicle_utils.set_performance_tuning_max(vehicle)
            cc_utils.help_message(pid, "Tuned vehicle with maximum performance options")
        end
    end
}