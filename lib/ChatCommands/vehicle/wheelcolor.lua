-- WheelColor

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="wheelcolor",
    group="vehicle",
    help="Set the vehicle wheel color",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local color = vehicle_utils.get_vehicle_color_from_command(commands[2])
            if color then
                vehicle_utils.set_extra_color(vehicle, nil, color)
                cc_utils.help_message(pid, "Set vehicle wheel color to "..color.name.." ("..color.index..")")
            else
                cc_utils.help_message(pid, "Invalid color")
            end
        end
    end
}