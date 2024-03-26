-- Wash

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="wash",
    group="vehicle",
    help="Remove any dirt from your current vehicle",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle then
            VEHICLE.SET_VEHICLE_DIRT_LEVEL(vehicle, 0)
            cc_utils.help_message(pid, "Vehicle washed and any dirt removed")
        end
    end
}