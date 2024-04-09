-- FavPaint

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local user_db = require("chat_commander/user_database")

return {
    command="favpaint",
    additional_commands={"favskin"},
    group="vehicle",
    help="Applys your favorite vehicle paint and mods to current vehicle",
    execute=function(pid, commands)

        -- Allow setting user preference for new spawns with on/off command
        if commands and commands[2] == "on" or commands[2] == "off" then
            user_db.set_pref_spawn_with_fav_paint(pid, commands[2] == "on")
            cc_utils.help_message(pid, "Set spawn vehicles with favorite paint: "..commands[2])
            return
        end

        -- If no on/off then apply to current vehicle
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You must be in a vehicle to apply your favorite paint")
        else
            if vehicle_utils.apply_favorite_to_current_vehicle(pid, vehicle) then
                cc_utils.help_message(pid, "Applying favorite vehicle paint to current vehicle")
            end
        end
    end
}
