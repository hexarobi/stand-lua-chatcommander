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

-- Delete any invisible cars that are commonly left over from gifting. Credit to Holy for finding this check
local function clear_invisible_vehicles(pid, range)
    if range == nil then range = 50 end
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1)
    for _, vehicle_handle in entities.get_all_vehicles_as_handles() do
        local entity_pos = ENTITY.GET_ENTITY_COORDS(vehicle_handle, 1)
        local dist = SYSTEM.VDIST(player_pos.x, player_pos.y, player_pos.z, entity_pos.x, entity_pos.y, entity_pos.z)
        if dist <= range then
            if vehicle_handle ~= -1 and not ENTITY.IS_ENTITY_VISIBLE(vehicle_handle) then
                local vehicle_name = VEHICLE.GET_DISPLAY_NAME_FROM_VEHICLE_MODEL(ENTITY.GET_ENTITY_MODEL(vehicle_handle))
                cc_utils.debug_log("Deleting invisible vehicle: "..vehicle_name)
                entities.delete(vehicle_handle)
            end
        end
    end
end

local function get_new_script_host_player_id(gifting_player_id)
    for _, player_id in players.list(false) do
        if player_id ~= gifting_player_id then
            return player_id
        end
    end
    -- If no one else is in session then make gifter the host
    return gifting_player_id
end

local function dont_be_script_host(gifting_player_id)
    -- Being script host when triggering the gift command can cause players to be kicked out of the car
    if players.get_script_host() == players.user() then
        local new_script_host_player_id = get_new_script_host_player_id(gifting_player_id)
        local host_name = players.get_name(new_script_host_player_id)
        util.toast("Giving away script host to "..host_name, TOAST_ALL)
        menu.trigger_commands("givesh"..host_name)
        util.yield(1000)
    end
end

return {
    enabled=false,
    command="gift",
    group="vehicle",
    help={
        "Gifting vehicles has been patched and no longer works. Sorry. :("
        --"To keep spawned cars, start with a basic 10 car garage (!tp giftgarage) and fill it with any free car from phone, then use !gift",
    },
    execute=function(pid)
        cc_utils.help_message(pid, "Unfortunately vehicle gifting has been removed in the latest update and no longer works.")
        --local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        --if vehicle_utils.is_vehicle_command_ready(pid, vehicle) then
        --    clear_invisible_vehicles(pid)
        --    dont_be_script_host()
        --    gift_vehicle_to_player(pid, vehicle)
        --    cc_utils.help_message(pid, "You may now park this car in a full garage and permanently replace another car. For more help say !help gift")
        --end
    end
}
