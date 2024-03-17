-- ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    name="spawn",
    command="spawn",
    group="vehicle",
    help="Spawn a performance tuned vehicle with random mods, wheels, and paint. Ex: !spawn deluxo",
    execute=function(pid, commands)
        local spawn_name = cc_utils.combine_remaining_commands(commands, 2)
        vehicle_utils.spawn_shuffled_vehicle_for_player(pid, spawn_name)
    end
}
