-- Mods

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="mods",
    additional_commands={"mod"},
    group="vehicle",
    help="Set the vehicle modifications. Allowed parameters: max, stock",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            if commands[2] == "max" then
                vehicle_utils.set_all_mods_to_max(vehicle)
                cc_utils.help_message(pid, "Set all vehicle modifications to max")
            elseif commands[2] == "stock" then
                vehicle_utils.set_all_mods_to_min(vehicle)
                cc_utils.help_message(pid, "Set all vehicle modifications to stock")
            else
                vehicle_utils.set_all_mods_to_random(vehicle)
                cc_utils.help_message(pid, "Set all vehicle modifications to random")
            end
        end
    end
}