-- NeonLights

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="neonlights",
    additional_commands={"underglow"},
    group="vehicle",
    help="Set the vehicle neon color",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) and commands and commands[2] then
            local color = vehicle_utils.get_command_color(commands[2])
            if not color then
                cc_utils.help_message(pid, "Invalid color")
                return
            end
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 0, true)
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 1, true)
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 2, true)
            VEHICLE.SET_VEHICLE_NEON_ENABLED(vehicle, 3, true)
            VEHICLE.SET_VEHICLE_NEON_COLOUR(vehicle, color.r, color.g, color.b)
            --VEHICLE.SET_VEHICLE_NEON_INDEX_COLOUR(vehicle, color.index)
            cc_utils.help_message(pid, "Set vehicle neon lights color to "..color.name.." ("..color.index..")")
        end
    end
}
