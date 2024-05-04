-- Livery

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local constants = require("chat_commander/constants")

return {
    command="livery",
    group="vehicle",
    help="Set the vehicle livery",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local mod_value = vehicle_utils.set_mod(vehicle, constants.VEHICLE_MOD_TYPES.MOD_LIVERY, commands[2])
            if mod_value then
                cc_utils.help_message(pid, "Set vehicle livery to "..mod_value)
            end
        end
    end
}