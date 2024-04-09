-- Copy

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="copy",
    group="vehicle",
    help="Create a copy of your current vehicle",
    execute=function(pid)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You must be in a vehicle to use this command")
        else
            local construct = vehicle_utils.create_construct_from_vehicle(vehicle)
            vehicle_utils.spawn_construct_for_player(pid, construct)
            cc_utils.help_message(pid, "Created a copy of current vehicle")
        end
    end
}
