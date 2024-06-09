-- ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="paint",
    command_aliases={"color"},
    group="vehicle",
	help="Paint the vehicle. Accepts color names or exact hexcodes. !paint blue, !paint #ff3344",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            vehicle_utils.set_vehicle_paint(pid, vehicle, commands)
        end
    end
}
