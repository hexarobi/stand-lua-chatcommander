-- Shuffle

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="shuffle",
    group="vehicle",
    help="Shuffle your vehicle paint, mods, and wheels",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            vehicle_utils.set_all_mods_to_random(vehicle)
            vehicle_utils.set_performance_tuning_max(vehicle)
            vehicle_utils.apply_random_paint(vehicle)
            vehicle_utils.randomize_wheels(vehicle)
            cc_utils.help_message(pid, "Shuffled your vehicle paint, mods and wheels")
        end
    end
}