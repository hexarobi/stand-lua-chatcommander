-- CleanUp

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

local function get_player_vehicle_handles()
    local player_vehicle_handles = {}
    for _, pid in pairs(players.list()) do
        local player_ped = PLAYER.GET_PLAYER_PED(pid)
        local veh = PED.GET_VEHICLE_PED_IS_IN(player_ped, false)
        if not ENTITY.IS_ENTITY_A_VEHICLE(veh) then
            veh = PED.GET_VEHICLE_PED_IS_IN(player_ped, true)
        end
        if not ENTITY.IS_ENTITY_A_VEHICLE(veh) then
            veh = 0
        end
        if veh then
            player_vehicle_handles[pid] = veh
        end
    end
    return player_vehicle_handles
end

local function is_entity_occupied(entity, type, player_vehicle_handles)
    if type == "VEHICLE" then
        for _, vehicle_handle in pairs(player_vehicle_handles) do
            if entity == vehicle_handle then
                return true
            end
        end
    end
    return false
end

local function delete_entities_by_range(my_entities, range, type, pid)
    local player_vehicle_handles = get_player_vehicle_handles()
    local player_pos = ENTITY.GET_ENTITY_COORDS(PLAYER.GET_PLAYER_PED_SCRIPT_INDEX(pid), 1)
    local count = 0
    for _, entity in ipairs(my_entities) do
        local entity_pos = ENTITY.GET_ENTITY_COORDS(entity, 1)
        local dist = SYSTEM.VDIST(player_pos.x, player_pos.y, player_pos.z, entity_pos.x, entity_pos.y, entity_pos.z)
        if dist <= range then
            if not is_entity_occupied(entity, type, player_vehicle_handles) then
                entities.delete_by_handle(entity)
                count = count + 1
            end
        end
    end
    return count
end

return {
    command="cleanup",
    group="player",
    help="Deletes nearby vehicles and objects.",
    execute=function(pid, commands)
        -- Spectate command issuer for cleanup to work
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid, {loops=10})
        local num_deleted = delete_entities_by_range(entities.get_all_vehicles_as_handles(), 100, "VEHICLE", pid)
        local num_deleted_objects = delete_entities_by_range(entities.get_all_objects_as_handles(), 100, "OBJECT", pid)
        cc_utils.help_message(pid, "Deleted "..num_deleted.." nearby vehicles and "..num_deleted_objects.." objects")
    end
}
