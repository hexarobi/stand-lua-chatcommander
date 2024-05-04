-- Fav

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local user_db = require("chat_commander/user_database")

local help = (
    "To set your favorite vehicle, use !fav save "
    .."To spawn it again use !fav spawn or to paint your current vehicle use !fav paint "
    .."To paint ALL spawns with your fav paint use !fav all on/off"
)

return {
    command="fav",
    additional_commands={"fave"},
    group="vehicle",
    help=help,
    execute=function(pid, commands)
        local constructor_lib = cc_utils.require_constructor_lib()
        if not constructor_lib then return end
        local fav_vehicle = user_db.get_user_vehicle(pid)
        if commands[2] == "save" or commands[2] == "set" then
            local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
            if vehicle == 0 then
                cc_utils.help_message(pid, "You must be in a vehicle to set your new favorite vehicle")
            else
                local construct = vehicle_utils.create_construct_from_vehicle(vehicle)
                user_db.set_user_vehicle(pid, construct)
                cc_utils.help_message(pid, "Saved current vehicle as favorite. Spawn with !fav or paint other vehicles with !fav paint")
            end
        elseif commands[2] == "paint" then
            local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
            if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
                if vehicle_utils.apply_favorite_to_current_vehicle(pid, vehicle) then
                    cc_utils.help_message(pid, "Applying fav vehicle paint to current vehicle")
                end
            end
        elseif commands[2] == "all" then
            -- Allow setting user preference for new spawns with on/off command
            if commands and commands[2] == "on" or commands[2] == "off" then
                user_db.set_pref_spawn_with_fav_paint(pid, commands[2] == "on")
                cc_utils.help_message(pid, "Set spawn vehicles with favorite paint: "..commands[2])
                return
            end
        elseif fav_vehicle and (#commands == 1 or commands[2] == "spawn") then
            vehicle_utils.spawn_construct_for_player(pid, fav_vehicle)
            cc_utils.help_message(pid, "Spawning favorite vehicle "..fav_vehicle.model.." To save a new fav use !fav save")
        else
            cc_utils.help_message(pid, help)
        end
    end
}
