-- Wheels

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")
local constants = require("chat_commander/constants")

local function set_wheels(vehicle, pid, commands)
    local wheel_type
    local wheel_kind
    if commands and commands[2] == "ghost" then
        commands[2] = "benny"
        commands[3] = "106"
        VEHICLE.SET_VEHICLE_EXTRA_COLOURS(vehicle, 0, 111)
    end
    if commands and commands[2] == "stock" and commands[3] == nil then
        commands[3] = "-1"
    end
    if commands and commands[2] then
        wheel_type = constants.VEHICLE_WHEEL_TYPES[commands[2]:upper()]
        if not wheel_type then
            cc_utils.help_message(pid, "Unknown wheel type")
            return false
        end
    else
        wheel_type = math.random(-1, constants.VEHICLE_MAX_OPTIONS.WHEEL_TYPES)
    end
    local max_wheel_kinds = VEHICLE.GET_NUM_VEHICLE_MODS(vehicle, constants.VEHICLE_MOD_TYPES.MOD_FRONTWHEELS) - 1
    if commands and commands[3] then
        wheel_kind = commands[3]
    else
        wheel_kind = math.random(-1, max_wheel_kinds)
    end
    local name = wheel_type
    for wheel_type_name, wheel_type_number in pairs(constants.VEHICLE_WHEEL_TYPES) do
        if wheel_type_number == tonumber(wheel_type) then
            name = wheel_type_name
        end
    end
    VEHICLE.SET_VEHICLE_WHEEL_TYPE(vehicle, wheel_type)
    entities.set_upgrade_value(vehicle, constants.VEHICLE_MOD_TYPES.MOD_FRONTWHEELS, wheel_kind)
    entities.set_upgrade_value(vehicle, constants.VEHICLE_MOD_TYPES.MOD_BACKWHEELS, wheel_kind)
    cc_utils.help_message(pid, "Set wheels to "..name.." type "..wheel_kind.." (of "..max_wheel_kinds..")")
end

return {
    command="wheels",
    additional_commands={"wheel"},
    group="vehicle",
    help="Set the vehicle wheels",
    execute=function(pid, commands)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle then
            set_wheels(vehicle, pid, commands)
        end
    end
}