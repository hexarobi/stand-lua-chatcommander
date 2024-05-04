-- PlateType

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="platetype",
    group="vehicle",
    help="Set the vehicle plate type",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local plate_type
            if commands[2] then plate_type = commands[2] end
            local plate_type_name = vehicle_utils.set_plate_type(pid, vehicle, plate_type)
            cc_utils.help_message(pid, "Plate type set to " .. plate_type_name)
        end
    end
}