-- Wheels

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="wheels",
    additional_commands={"wheel"},
    group="vehicle",
    help="Set the vehicle wheels",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle then
            local wheels = vehicle_utils.set_wheels(vehicle, commands)
            if wheels then
                cc_utils.help_message(pid, "Set wheels to "..wheels.name.." type "..wheels.kind.." (of "..wheels.max_kinds..")")
            else
                cc_utils.help_message(pid, "Unknown wheel type")
            end
        end
    end
}