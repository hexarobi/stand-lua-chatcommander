-- Copy

local cc_utils = require("chat_commander/utils")
local vehicle_utils = require("chat_commander/vehicle_utils")

local function require_dependency(path)
    local dep_status, required_dep = pcall(require, path)
    if not dep_status then
        util.log("Could not load "..path..": "..required_dep)
    else
        return required_dep
    end
end

local constructor_lib = require_dependency("constructor/constructor_lib")

return {
    command="copy",
    group="vehicle",
    help="Create a copy of your current vehicle",
    execute=function(pid)
        if not constructor_lib then
            util.log("Copy command relies on constructor_lib. Please install Constructor to use this command")
            return
        end
        local vehicle = vehicle_utils.get_player_vehicle_in_control(pid)
        if vehicle == 0 then
            cc_utils.help_message(pid, "You must be in a vehicle to use this command")
        else
            vehicle_utils.despawn_for_player(pid)
            local construct = constructor_lib.copy_construct_plan(constructor_lib.construct_base)
            construct.type = "VEHICLE"
            construct.handle = vehicle
            constructor_lib.default_entity_attributes(construct)
            constructor_lib.serialize_vehicle_attributes(construct)
            construct.handle = vehicle_utils.spawn_vehicle_for_player(pid, construct.model)
            constructor_lib.deserialize_vehicle_attributes(construct)
            vehicle_utils.spawn_for_player(pid, construct.handle)
            cc_utils.help_message(pid, "Created a copy of current vehicle")
        end
    end
}
