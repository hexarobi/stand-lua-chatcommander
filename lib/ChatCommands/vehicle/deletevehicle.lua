-- DeleteVehicle

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="deletevehicle",
    additional_commands={"dv"},
    group="vehicle",
    help="Delete your current vehicle",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You are not in a vehicle")
        else
            cc_utils.help_message(pid, "Attempting to delete your current vehicle, thanks for keeping the lobby clean")
            entities.delete_by_handle(vehicle)
        end
    end
}