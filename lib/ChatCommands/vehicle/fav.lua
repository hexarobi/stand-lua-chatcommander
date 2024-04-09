-- Fav

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local user_db = require("chat_commander/user_database")

return {
    command="spawnfav",
    additional_commands={"fav", "fave", "spawnfave"},
    group="vehicle",
    help="Spawn your saved favorite vehicle",
    execute=function(pid)
        local constructor_lib = cc_utils.require_constructor_lib()
        if not constructor_lib then return end
        local vehicle = user_db.get_user_vehicle(pid)
        if vehicle then
            vehicle_utils.spawn_construct_for_player(pid, vehicle)
            cc_utils.help_message(pid, "Spawning favorite vehicle "..vehicle.model)
        end
    end
}
