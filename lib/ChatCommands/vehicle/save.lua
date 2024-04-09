-- Save

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local user_db = require("chat_commander/user_database")

return {
    command="save",
    additional_commands={"favsave", "favesave"},
    group="vehicle",
    help="Save your current vehicle as the model for future spawns",
    execute=function(pid)
        local constructor_lib = cc_utils.require_constructor_lib()
        if not constructor_lib then return end
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You must be in a vehicle to use this command")
        else
            local construct = vehicle_utils.create_construct_from_vehicle(vehicle)
            user_db.set_user_vehicle(pid, construct)
            cc_utils.help_message(pid, "Saved current vehicle as favorite. Spawn with !fav or Re-paint vehicle with !favpaint")
        end
    end
}
