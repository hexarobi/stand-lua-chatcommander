-- Copy

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="copy",
    group="vehicle",
    help="Create a copy of your current vehicle",
    execute=function(pid)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local construct = vehicle_utils.create_construct_from_vehicle(vehicle)
            vehicle_utils.spawn_construct_for_player(pid, construct)
            cc_utils.help_message(pid, "Created a copy of current vehicle")
        end
    end
}
