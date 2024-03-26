-- Teleport

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="teleport",
    additional_commands={"tp"},
    group="player",
    help="Teleport to a stunt jump location.",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if not vehicle then
            cc_utils.help_message(pid, "Please enter a vehicle to use this command.")
        else
            local jump_index = commands[2]
            if jump_index == nil then
                jump_index = math.random(1, #stunt_jumps)
            end
            local stunt_jump = stunt_jumps[tonumber(jump_index)]
            if stunt_jump == nil then
                cc_utils.help_message(pid, "Invalid stunt jump")
            else
                vehicle_utils.teleport_vehicle_to_coords(vehicle, stunt_jump[2])
                cc_utils.help_message(pid, "Teleporting to stunt jump #"..jump_index)
            end
        end
    end
}
