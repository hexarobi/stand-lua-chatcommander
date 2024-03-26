-- Repair

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="repair",
    group="vehicle",
    help="Repair any damage done to your current vehicle",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle then
            VEHICLE.SET_VEHICLE_FIXED(vehicle)
            cc_utils.help_message(pid, "Vehicle repaired")
        end
    end
}