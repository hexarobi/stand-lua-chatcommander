-- Headlights

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local constants = require("chat_commander/constants")

return {
    command="headlights",
    group="vehicle",
    help="Set the vehicle headlights color",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local color_number = tonumber(commands[2])
            local color_name = commands[2]
            if constants.headlight_color_name_map[color_name] ~= nil then
                color_number = constants.headlight_color_name_map[color_name]
            end
            if color_number == nil or color_number < -1 or color_number > 12 then
                cc_utils.help_message(pid, "Invalid color")
                return
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, constants.VEHICLE_MOD_TYPES.MOD_XENONLIGHTS, true)
            VEHICLE.SET_VEHICLE_XENON_LIGHT_COLOR_INDEX(vehicle, color_number)
            cc_utils.help_message(pid, "Setting vehicle headlight color to "..color_name)
        end
    end
}