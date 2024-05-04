-- Mods

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="modsmax",
    additional_commands={"maxmods"},
    group="vehicle",
    help="Set the vehicle to maximum modifications.",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            vehicle_utils.set_all_mods_to_max(vehicle)
            cc_utils.help_message(pid, "Set all vehicle modifications to max")
        end
    end
}