-- ChatCommander-Compatible ChatCommand

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

-- Based on GiftVehicle by Mr.Robot
local function gift_vehicle_to_player(pid, vehicle)
    --local command_string = "gift " .. players.get_name(pid)
    --menu.trigger_commands(command_string)

    local pid_hash = NETWORK.NETWORK_HASH_FROM_PLAYER_HANDLE(pid)
    local check = memory.script_global(78689)
    memory.write_int(check, 0)

    local bitset = DECORATOR.DECOR_GET_INT(vehicle, "MPBitset")
    bitset = cc_utils.bit_set(bitset, 3)
    bitset = cc_utils.bit_set(bitset, 24)

    DECORATOR.DECOR_SET_INT(vehicle, "MPBitset", bitset)
    DECORATOR.DECOR_SET_INT(vehicle, "Previous_Owner", 0)
    DECORATOR.DECOR_SET_INT(vehicle, "PV_Slot", 0)
    DECORATOR.DECOR_SET_INT(vehicle, "Player_Vehicle", pid_hash)
    DECORATOR.DECOR_SET_INT(vehicle, "Veh_Modded_By_Player", pid_hash)
end

return {
    command="gift",
    group="vehicle",
    help={
        "To keep spawned cars, start with a basic 10 car garage (!tp giftgarage) and fill it with any free car from phone, then use !gift",
    },
    execute=function(pid)
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You must be in a vehicle to use !gift")
        else
            gift_vehicle_to_player(pid, vehicle)
            cc_utils.help_message(pid, "You may now park this car in a full garage and permanently replace another car. For more help say !help gift")
        end
    end
}
