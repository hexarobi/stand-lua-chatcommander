-- TireSmoke

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

local window_tint_map = {
    none = -1,
    black = 0,
    dark = 1,
    light = 2,
    stock = 3,
    limo = 4,
    green = 5,
}

return {
    command="windowtint",
    group="vehicle",
    help="Set the vehicle window tint color: none, black, dark, light, stock, limo, green",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local tint_level = tonumber(commands[2])
            local tint_name = commands[2]
            if window_tint_map[tint_name] ~= nil then tint_level = window_tint_map[tint_name] end
            if tint_level < -1 or tint_level > 6 then
                cc_utils.help_message(pid, "Invalid tint")
                return
            end
            VEHICLE.SET_VEHICLE_WINDOW_TINT(vehicle, tint_level)
            cc_utils.help_message(pid, "Window tint "..tint_level)
        end
    end
}