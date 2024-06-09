-- Fast

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

return {
    command="fast",
    group="vehicle",
    help="Makes your car super fast. Toggle with !fast on/off",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
            local fast_percent = tonumber(commands[2])
            --local enabled_string = get_on_off_string(commands[2])
            --local enabled = (enabled_string == "ON")
            if fast_percent then
                if fast_percent <= 0 then
                    fast_percent = 1
                end
                if fast_percent > 100 then
                    fast_percent = 100
                end
                -- help_message(pid, "Applying " .. fast_percent .. " percent fast to your vehicle")
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(vehicle, math.ceil(10000 * (fast_percent / 100)))
                ENTITY.SET_ENTITY_MAX_SPEED(vehicle, math.ceil(10000 * (fast_percent / 100)))
                entities.set_gravity_multiplier(entities.handle_to_pointer(vehicle), math.ceil(40 * (fast_percent / 100)) + 10)
                menu.trigger_commands("givepower " .. players.get_name(pid) .. " " .. math.ceil(20 * (fast_percent / 100)))
                cc_utils.help_message(pid, "Vehicle fast speed set to "..tostring(fast_percent).."%")
            elseif commands[2] == "off" then
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(vehicle, 100)
                ENTITY.SET_ENTITY_MAX_SPEED(vehicle, 100)
                entities.set_gravity_multiplier(entities.handle_to_pointer(vehicle), 10)
                menu.trigger_commands("givepower " .. players.get_name(pid) .. " 1")
                cc_utils.help_message(pid, "Vehicle fast speed is off")
            else
                VEHICLE.MODIFY_VEHICLE_TOP_SPEED(vehicle, 10000)
                ENTITY.SET_ENTITY_MAX_SPEED(vehicle, 10000)
                entities.set_gravity_multiplier(entities.handle_to_pointer(vehicle), 50)
                menu.trigger_commands("givepower " .. players.get_name(pid) .. " 20")
                cc_utils.help_message(pid, "Vehicle fast speed is on")
            end
        end
    end
}
