-- TireSmoke

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local inspect = require("inspect")

return {
    command="tiresmoke",
    group="vehicle",
    help="Set the vehicle tiresmoke color",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local color
            if commands[2] == "patriot" then
                color = {name="Patriot", r=0, g=0, b=0}
            else
                color = vehicle_utils.get_command_color(commands[2])
            end
            if not color then
                cc_utils.help_message(pid, "Invalid color")
                return
            end
            util.log("Loading color "..inspect(color))
            VEHICLE.SET_VEHICLE_MOD_KIT(vehicle, 0)
            VEHICLE.TOGGLE_VEHICLE_MOD(vehicle, 22, true)
            VEHICLE.SET_VEHICLE_TYRE_SMOKE_COLOR(vehicle, color.r, color.g, color.b)
            cc_utils.help_message(pid, "Set vehicle tire smoke color to "..commands[2])
        end
    end
}