-- TireSmoke

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="tiresmoke",
    group="vehicle",
    help="Set the vehicle tiresmoke color",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local color = vehicle_utils.get_command_color(commands[2])
            if not color then
                cc_utils.help_message(pid, "Invalid color")
                return
            end
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 22, true)
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, color[1], color[2], color[3])
            cc_utils.help_message(pid, "Set vehicle tire smoke color to "..commands[2])
        end
    end
}